"""Pinned public-photo acceptance. Dry-run by default; never called live by CI."""
import argparse
from datetime import datetime, timezone
import hashlib
import http.client
import json
import math
from pathlib import Path
import re
import time
import uuid


FIXTURES = Path(__file__).resolve().parent / 'fixtures'
HOST = 'fitlife-photo.konovalov-m7k.workers.dev'
MAX_REQUESTS = 2
MAX_IMAGE_BYTES = 512 * 1024
MAX_RESPONSE_BYTES = 65536
WARNINGS = {'uncertain_portion', 'hidden_ingredients', 'ambiguous_food',
            'preparation_unknown', 'no_food'}
CASES = {
    'apple': ('apple-public.jpg',
              'd2d272766c08cffc97784d3c0e6d60f813c9b783af76fd282f17b7f1c5d7ff52',
              (('яблок', 'apple'),)),
    'banana': ('banana-public.jpg',
               '927fcf129b0dfc1e5925d861b9c5a60f99af86c274792c489dde5e76a66c4bd9',
               (('банан', 'banana'),)),
    'mixed-rice-beans': ('rice-beans-public.jpg',
                         'e9de7646d63bd15d1172005400bf679478622ae601b95e697542c5ae59154878',
                         (('рис', 'rice'), ('фасол', 'боб', 'bean'))),
}


class PhotoCaseFailure(Exception):
    def __init__(self, code, http_status=None):
        super().__init__(code)
        self.code = code
        self.http_status = http_status


def prepared_jpeg(data):
    """Check JPEG framing and reject EXIF/ICC segments before compressed pixels."""
    if not 4 <= len(data) <= MAX_IMAGE_BYTES or not data.startswith(b'\xff\xd8') or not data.endswith(b'\xff\xd9'):
        raise PhotoCaseFailure('invalid_fixture')
    offset = 2
    while offset + 4 <= len(data):
        if data[offset] != 255:
            raise PhotoCaseFailure('invalid_fixture')
        marker = data[offset + 1]
        length = int.from_bytes(data[offset + 2:offset + 4], 'big')
        if length < 2 or offset + 2 + length > len(data) or marker in (0xe1, 0xe2):
            raise PhotoCaseFailure('invalid_fixture')
        if marker == 0xda:
            return
        offset += 2 + length
    raise PhotoCaseFailure('invalid_fixture')


def fixtures(case_ids):
    if not case_ids or len(set(case_ids)) != len(case_ids) or any(c not in CASES for c in case_ids):
        raise PhotoCaseFailure('invalid_selection')
    result = []
    for case_id in case_ids:
        filename, expected_hash, _ = CASES[case_id]
        try:
            path = FIXTURES / filename
            if path.stat().st_size > MAX_IMAGE_BYTES:
                raise PhotoCaseFailure('invalid_fixture')
            data = path.read_bytes()
        except OSError:
            raise PhotoCaseFailure('invalid_fixture') from None
        if hashlib.sha256(data).hexdigest() != expected_hash:
            raise PhotoCaseFailure('fixture_hash_mismatch')
        prepared_jpeg(data)
        result.append((case_id, data))
    return result


def load_private_config(path):
    try:
        if path is None or path.stat().st_size > 16384:
            raise ValueError()
        config = json.loads(path.read_text(encoding='utf-8-sig'))
        endpoint = config['FITLIFE_PHOTO_SERVER'].rstrip('/')
        token = config['FITLIFE_PHOTO_TOKEN']
        if endpoint != 'https://' + HOST or not isinstance(token, str) or not re.fullmatch(r'[A-Za-z0-9_-]{43}', token):
            raise ValueError()
        return token
    except (OSError, ValueError, TypeError, KeyError, AttributeError):
        raise PhotoCaseFailure('invalid_private_config') from None


def request_identification(data, token, request_id):
    # http.client does not follow redirects or retry. The host/path are fixed;
    # credentials cannot be forwarded to a provider/redirect target.
    connection = http.client.HTTPSConnection(HOST, timeout=45)
    try:
        connection.request('POST', '/v2/identify', body=data, headers={
            'Authorization': 'Bearer ' + token, 'Content-Type': 'image/jpeg',
            'X-Request-Id': request_id,
        })
        response = connection.getresponse()
        if response.status != 200:
            raise PhotoCaseFailure('http_error', response.status)
        raw = response.read(MAX_RESPONSE_BYTES + 1)
        if len(raw) > MAX_RESPONSE_BYTES:
            raise PhotoCaseFailure('response_too_large')
        return raw
    except (OSError, http.client.HTTPException):
        raise PhotoCaseFailure('transport_error') from None
    finally:
        connection.close()


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError()
        result[key] = value
    return result


def validate_result(raw, request_id, token):
    try:
        if len(raw) > MAX_RESPONSE_BYTES:
            raise ValueError()
        value = json.loads(raw.decode('utf-8'), object_pairs_hook=unique_object,
                           parse_constant=lambda _: None)
        if (not isinstance(value, dict) or set(value) != {'version', 'requestId', 'items', 'warnings'}
                or type(value['version']) is not int or value['version'] != 2
                or value['requestId'] != request_id or not isinstance(value['items'], list)
                or len(value['items']) > 12 or not isinstance(value['warnings'], list)
                or len(value['warnings']) > 5
                or any(not isinstance(w, str) or w not in WARNINGS for w in value['warnings'])):
            raise ValueError()
        for item in value['items']:
            if (not isinstance(item, dict) or set(item) != {'name', 'grams', 'confidence'}
                    or not isinstance(item['name'], str) or not item['name'].strip()
                    or len(item['name']) > 80 or re.search(r'[\x00-\x1f\x7f]', item['name'])
                    or token in item['name'] or item['confidence'] not in ('low', 'medium', 'high')
                    or type(item['grams']) not in (int, float)
                    or not 1 <= item['grams'] <= 3000 or not math.isfinite(item['grams'])):
                raise ValueError()
        return {'items': value['items'], 'warnings': value['warnings']}
    except (ValueError, TypeError, KeyError, UnicodeError, RecursionError):
        # Never include a raw provider body, exception text or credentials.
        raise PhotoCaseFailure('invalid_response') from None


def identity_matches(case_id, items):
    names = ' '.join(item['name'].casefold() for item in items)
    return all(any(stem in names for stem in synonyms) for synonyms in CASES[case_id][2])


def run_cases(case_ids, *, allow_live=False, private_config=None):
    if allow_live and len(case_ids) > MAX_REQUESTS:
        raise PhotoCaseFailure('request_cap_exceeded')
    selected = fixtures(case_ids)  # Verify every image before reading secrets/calling HTTP.
    report = {'schemaVersion': 1, 'createdAt': datetime.now(timezone.utc).isoformat(),
              'mode': 'live' if allow_live else 'dry-run', 'requestAttempts': 0,
              'selectedCases': case_ids, 'results': [],
              'scope': 'identity only; estimated grams are not measured ground truth'}
    if not allow_live:
        report['results'] = [{'case': c, 'sha256': CASES[c][1], 'bytes': len(data),
                              'status': 'fixture-verified'} for c, data in selected]
        report['passed'] = True
        return report
    token = load_private_config(private_config)
    for case_id, data in selected:
        started = time.monotonic()
        entry = {'case': case_id, 'sha256': CASES[case_id][1], 'status': 'failed'}
        report['requestAttempts'] += 1
        try:
            request_id = uuid.uuid4().hex
            raw = request_identification(data, token, request_id)
            result = validate_result(raw, request_id, token)
            entry.update(result)
            if not identity_matches(case_id, result['items']):
                raise PhotoCaseFailure('identity_mismatch')
            entry['status'] = 'passed'
        except PhotoCaseFailure as error:
            entry['error'] = error.code
            if error.http_status is not None:
                entry['httpStatus'] = error.http_status
        entry['durationSeconds'] = round(time.monotonic() - started, 2)
        report['results'].append(entry)
        if entry['status'] != 'passed':
            break  # Even provider/quota/identity failures consume a slot; no retry.
    report['passed'] = len(report['results']) == len(selected) and all(r['status'] == 'passed' for r in report['results'])
    return report


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--case', action='append', choices=tuple(CASES), dest='cases')
    parser.add_argument('--allow-live-request', action='store_true')
    parser.add_argument('--private-config', type=Path)
    parser.add_argument('--report', type=Path)
    args = parser.parse_args(argv)
    try:
        if args.allow_live_request and (not args.cases or args.private_config is None):
            raise PhotoCaseFailure('live_requires_explicit_cases_and_config')
        report = run_cases(args.cases or list(CASES), allow_live=args.allow_live_request,
                           private_config=args.private_config)
        encoded = json.dumps(report, ensure_ascii=False, indent=2) + '\n'
        if args.report:
            args.report.parent.mkdir(parents=True, exist_ok=True)
            args.report.write_text(encoded, encoding='utf-8')
        print(encoded, end='')
        return 0 if report['passed'] else 1
    except PhotoCaseFailure as error:
        print(json.dumps({'passed': False, 'error': error.code}))
        return 1
    except Exception:
        print(json.dumps({'passed': False, 'error': 'local_error'}))
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
