import contextlib
import copy
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import Mock, patch

import check_photo_cases as photo


TOKEN = 'x' * 43  # Deliberately synthetic, never a production credential.
REQUEST_ID = 'a' * 32


def answer(request_id=REQUEST_ID, names=('Банан, сырой',)):
    return {'version': 2, 'requestId': request_id,
            'items': [{'name': name, 'grams': 125, 'confidence': 'high'} for name in names],
            'warnings': ['uncertain_portion']}


def encoded(value):
    return json.dumps(value, ensure_ascii=False).encode('utf-8')


class PhotoCasesTest(unittest.TestCase):
    def test_all_pinned_photos_are_prepared_but_dry_run_never_reads_config_or_calls_http(self):
        with patch.object(photo, 'load_private_config') as config, patch.object(photo, 'request_identification') as request:
            result = photo.run_cases(list(photo.CASES), private_config=Path('must-not-be-read.json'))
        self.assertTrue(result['passed'])
        self.assertEqual(result['requestAttempts'], 0)
        self.assertEqual(len(result['results']), 3)
        self.assertEqual([r['status'] for r in result['results']], ['fixture-verified'] * 3)
        config.assert_not_called()
        request.assert_not_called()

    def test_cli_live_requires_explicit_cases_and_config(self):
        for args in (['--allow-live-request'], ['--allow-live-request', '--case', 'banana'],
                     ['--allow-live-request', '--private-config', 'private.json']):
            with self.subTest(args=args), patch.object(photo, 'run_cases') as run, contextlib.redirect_stdout(io.StringIO()) as output:
                self.assertEqual(photo.main(args), 1)
                self.assertEqual(json.loads(output.getvalue())['error'], 'live_requires_explicit_cases_and_config')
                run.assert_not_called()

    def test_cap_duplicates_unknown_case_rejected_before_credentials_or_requests(self):
        for cases, error in [(list(photo.CASES), 'request_cap_exceeded'),
                             (['banana', 'banana'], 'invalid_selection'),
                             (['../private'], 'invalid_selection')]:
            with self.subTest(cases=cases), patch.object(photo, 'load_private_config') as config, patch.object(photo, 'request_identification') as request:
                with self.assertRaisesRegex(photo.PhotoCaseFailure, '^' + error + '$'):
                    photo.run_cases(cases, allow_live=True)
                config.assert_not_called()
                request.assert_not_called()

    def test_tampered_second_fixture_blocks_entire_batch_before_first_request(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            for case in ('banana', 'mixed-rice-beans'):
                name = photo.CASES[case][0]
                (root / name).write_bytes((photo.FIXTURES / name).read_bytes())
            (root / photo.CASES['mixed-rice-beans'][0]).write_bytes(b'not-a-public-photo')
            with patch.object(photo, 'FIXTURES', root), patch.object(photo, 'load_private_config') as config, patch.object(photo, 'request_identification') as request:
                with self.assertRaisesRegex(photo.PhotoCaseFailure, '^fixture_hash_mismatch$'):
                    photo.run_cases(['banana', 'mixed-rice-beans'], allow_live=True)
                config.assert_not_called()
                request.assert_not_called()

    def test_exif_icc_and_broken_jpeg_are_rejected(self):
        for data in (b'not jpeg', b'\xff\xd8\xff\xe1\x00\x02\xff\xd9',
                     b'\xff\xd8\xff\xe2\x00\x02\xff\xd9',
                     b'\xff\xd8\xff\xda\x00\xff\xff\xd9'):
            with self.subTest(data=data), self.assertRaises(photo.PhotoCaseFailure):
                photo.prepared_jpeg(data)

    def test_two_successes_accept_composite_rice_and_beans_but_do_not_claim_mass_accuracy(self):
        names = iter([('Банан, сырой',), ('Рис с фасолью, готовое блюдо', 'Курица')])
        def respond(data, token, request_id):
            self.assertEqual(token, TOKEN)
            self.assertRegex(request_id, r'^[a-f0-9]{32}$')
            return encoded(answer(request_id, next(names)))
        with patch.object(photo, 'load_private_config', return_value=TOKEN), patch.object(photo, 'request_identification', side_effect=respond) as request:
            result = photo.run_cases(['banana', 'mixed-rice-beans'], allow_live=True)
        self.assertTrue(result['passed'])
        self.assertEqual(result['requestAttempts'], 2)
        self.assertEqual(request.call_count, 2)
        self.assertIn('not measured ground truth', result['scope'])
        self.assertNotIn(TOKEN, json.dumps(result))
        self.assertNotIn('kcal', json.dumps(result))

    def test_provider_failure_invalid_contract_and_wrong_food_stop_without_retry(self):
        for outcome, error in [(photo.PhotoCaseFailure('http_error', 429), 'http_error'),
                               (b'private provider text ' + TOKEN.encode(), 'invalid_response'),
                               (encoded(answer(names=('Яблоко',))), 'identity_mismatch')]:
            with self.subTest(error=error), patch.object(photo, 'load_private_config', return_value=TOKEN), patch.object(photo.uuid, 'uuid4', return_value=Mock(hex=REQUEST_ID)), patch.object(photo, 'request_identification', side_effect=outcome if isinstance(outcome, Exception) else None, return_value=outcome) as request:
                result = photo.run_cases(['banana', 'mixed-rice-beans'], allow_live=True)
                self.assertFalse(result['passed'])
                self.assertEqual(result['requestAttempts'], 1)
                self.assertEqual(result['results'][0]['error'], error)
                self.assertEqual(len(result['results']), 1)
                request.assert_called_once()
                self.assertNotIn(TOKEN, json.dumps(result))
                self.assertNotIn('private provider', json.dumps(result))

    def test_strict_v2_does_not_accept_model_nutrients_forged_sources_or_bad_numbers(self):
        valid = answer()
        invalid = []
        for key, value in [('kcal', 100), ('source', 'USDA'), ('confidence', 'certain'),
                           ('grams', True), ('grams', 0), ('grams', 3001), ('grams', 10 ** 1000), ('grams', float('nan')),
                           ('name', 'food\n' + TOKEN), ('name', TOKEN)]:
            candidate = copy.deepcopy(valid)
            candidate['items'][0][key] = value
            invalid.append(candidate)
        for key, value in [('version', 1), ('version', True), ('requestId', 'forged'),
                           ('warnings', ['free form']), ('items', [valid['items'][0]] * 13),
                           ('kcal', 999)]:
            candidate = copy.deepcopy(valid)
            candidate[key] = value
            invalid.append(candidate)
        for candidate in invalid:
            with self.subTest(candidate=candidate), self.assertRaisesRegex(photo.PhotoCaseFailure, '^invalid_response$'):
                photo.validate_result(encoded(candidate), REQUEST_ID, TOKEN)
        self.assertEqual(photo.validate_result(encoded(valid), REQUEST_ID, TOKEN)['items'], valid['items'])

    def test_duplicate_json_keys_invalid_utf8_deep_or_oversized_body_do_not_leak(self):
        for raw in (b'{"items":[],"items":[]}', b'\xff', b'[' * 1100,
                    b'x' * (photo.MAX_RESPONSE_BYTES + 1)):
            with self.subTest(length=len(raw)), self.assertRaisesRegex(photo.PhotoCaseFailure, '^invalid_response$'):
                photo.validate_result(raw, REQUEST_ID, TOKEN)

    def test_redirect_is_not_followed_or_body_logged_and_request_is_sent_once(self):
        connection = Mock()
        connection.getresponse.return_value.status = 302
        with patch.object(photo.http.client, 'HTTPSConnection', return_value=connection) as factory:
            with self.assertRaises(photo.PhotoCaseFailure) as raised:
                photo.request_identification(b'public image', TOKEN, REQUEST_ID)
        self.assertEqual(raised.exception.http_status, 302)
        factory.assert_called_once_with(photo.HOST, timeout=45)
        connection.request.assert_called_once_with('POST', '/v2/identify', body=b'public image', headers={
            'Authorization': 'Bearer ' + TOKEN, 'Content-Type': 'image/jpeg', 'X-Request-Id': REQUEST_ID})
        connection.getresponse.return_value.read.assert_not_called()
        connection.close.assert_called_once()

    def test_transport_failure_closes_and_never_retries_or_exposes_error(self):
        connection = Mock()
        connection.request.side_effect = OSError('private ' + TOKEN)
        with patch.object(photo.http.client, 'HTTPSConnection', return_value=connection), self.assertRaisesRegex(photo.PhotoCaseFailure, '^transport_error$'):
            photo.request_identification(b'public image', TOKEN, REQUEST_ID)
        connection.request.assert_called_once()
        connection.close.assert_called_once()

    def test_response_read_is_bounded_and_oversize_rejected(self):
        connection = Mock()
        response = connection.getresponse.return_value
        response.status = 200
        response.read.return_value = b'x' * (photo.MAX_RESPONSE_BYTES + 1)
        with patch.object(photo.http.client, 'HTTPSConnection', return_value=connection), self.assertRaisesRegex(photo.PhotoCaseFailure, '^response_too_large$'):
            photo.request_identification(b'public image', TOKEN, REQUEST_ID)
        response.read.assert_called_once_with(photo.MAX_RESPONSE_BYTES + 1)
        connection.close.assert_called_once()

    def test_private_config_is_fixed_host_and_error_does_not_echo_credentials(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'config.json'
            for endpoint, token in [('https://' + photo.HOST + '.foreign.test', TOKEN),
                                    ('http://' + photo.HOST, TOKEN),
                                    ('https://' + photo.HOST, 'private\n' + TOKEN)]:
                path.write_text(json.dumps({'FITLIFE_PHOTO_SERVER': endpoint, 'FITLIFE_PHOTO_TOKEN': token}))
                with self.assertRaisesRegex(photo.PhotoCaseFailure, '^invalid_private_config$'):
                    photo.load_private_config(path)
            path.write_text(json.dumps({'FITLIFE_PHOTO_SERVER': 'https://' + photo.HOST, 'FITLIFE_PHOTO_TOKEN': TOKEN}))
            self.assertEqual(photo.load_private_config(path), TOKEN)


if __name__ == '__main__':
    unittest.main()
