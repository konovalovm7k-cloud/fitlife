"""One explicitly enabled, synthetic Chef request; never used by CI.

Credentials stay in memory. Errors must not expose headers or configuration.
"""
import argparse
import json
import re
from pathlib import Path
import urllib.error
import urllib.request
import uuid


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--private-config', type=Path, required=True)
    parser.add_argument('--allow-live-request', action='store_true', required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    try:
        config = json.loads(args.private_config.read_text(encoding='utf-8-sig'))
        endpoint = config['FITLIFE_PHOTO_SERVER'].rstrip('/')
        token = config['FITLIFE_PHOTO_TOKEN']
        if endpoint != 'https://fitlife-photo.konovalov-m7k.workers.dev' or not re.fullmatch(r'[A-Za-z0-9_-]{43}', token):
            raise ValueError()
    except Exception:
        raise SystemExit('Invalid private configuration; no request sent') from None
    nonce = uuid.uuid4().hex
    body = json.dumps({'text': 'Ready grilled chicken breast 120 g, boiled basmati rice 150 g, raw cucumber with peel 100 g, raw tomato 150 g. Suggest an assembly using only these foods and masses.'}).encode()
    request = urllib.request.Request(endpoint + '/v2/chef', data=body, headers={
        'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token,
        'X-Request-Id': nonce,
        'User-Agent': 'FitLifeManualCheck/1.0',
    })
    try:
        with urllib.request.build_opener(NoRedirect()).open(request, timeout=55) as response:
            status = response.status
            raw = response.read(65537)
    except urllib.error.HTTPError as error:
        raise SystemExit(f'Chef HTTP {error.code}; no retry attempted') from None
    except Exception:
        raise SystemExit('Chef transport failed; no retry attempted') from None
    if len(raw) > 65536:
        raise SystemExit('Oversized response')
    try:
        result = json.loads(raw)
        catalogue = json.loads((Path(__file__).resolve().parents[1] / 'shared/chef_catalogue.json').read_text(encoding='utf-8'))
        allowed = {food['recordId'] for food in catalogue['foods']}
        assert set(result) == {'version', 'kind', 'requestId', 'catalogueVersion', 'items', 'warnings'}
        assert result['version'] == 1 and result['kind'] == 'chef'
        assert result['requestId'] == nonce and result['catalogueVersion'] == catalogue['version']
        items, warnings = result['items'], result['warnings']
        assert isinstance(items, list) and len(items) <= 12
        assert isinstance(warnings, list) and len(warnings) <= 4 and len(set(warnings)) == len(warnings)
        assert set(warnings) <= {'check_portions', 'check_labels', 'no_match', 'pantry_unclear'}
        assert (items and 'no_match' not in warnings) or (not items and {'no_match', 'pantry_unclear'} & set(warnings))
        assert len({item['recordId'] for item in items}) == len(items)
        for item in items:
            assert set(item) == {'recordId', 'grams'} and item['recordId'] in allowed
            assert type(item['grams']) in (float, int) and 1 <= item['grams'] <= 3000
        assert sum(item['grams'] for item in items) <= 3000
    except Exception:
        raise SystemExit('Chef response failed contract checks; no retry attempted') from None
    args.output.write_text(json.dumps({'status': status, 'response': result}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'PASS: live Chef HTTP {status}; {len(items)} sourced identities, no generated nutrient fields; one request')


if __name__ == '__main__':
    main()
