"""Convert an authorized CSV export into FitLife's offline catalogue.

This tool has no network access and does not scrape health-diet.ru.
Required columns: id,name,kcal,protein,fat,carbs,source_url.
Values must be per 100 g; delimiter may be comma, semicolon or tab.
"""
import argparse
import csv
import io
import json
import math
from pathlib import Path
from urllib.parse import urlsplit


def convert(text, source):
    dialect = csv.Sniffer().sniff(text[:8192], delimiters=',;\t')
    reader = csv.DictReader(io.StringIO(text.lstrip('\ufeff')), dialect=dialect)
    required = {'id', 'name', 'kcal', 'protein', 'fat', 'carbs', 'source_url'}
    if not required.issubset(reader.fieldnames or []):
        raise ValueError('Missing required CSV columns')
    result = []
    seen = set()
    for line, row in enumerate(reader, 2):
        record = {key: row[key].strip() for key in ['id', 'name', 'source_url']}
        if not record['id'] or not record['name'] or record['id'] in seen:
            raise ValueError(f'Line {line}: empty or duplicate identity')
        parsed = urlsplit(record['source_url'])
        if parsed.scheme != 'https' or not parsed.hostname or parsed.username or parsed.password:
            raise ValueError(f'Line {line}: expected a public HTTPS source URL')
        for key in ['kcal', 'protein', 'fat', 'carbs']:
            value = float(row[key].replace(',', '.'))
            if not math.isfinite(value) or value < 0 or value > (950 if key == 'kcal' else 100):
                raise ValueError(f'Line {line}: invalid {key} per 100 g')
            record[key] = value
        if sum(record[key] for key in ['protein', 'fat', 'carbs']) > 105:
            raise ValueError(f'Line {line}: macros exceed product mass')
        if record['kcal'] == 0 and any(record[key] > 0 for key in ['protein', 'fat', 'carbs']):
            raise ValueError(f'Line {line}: zero energy with nonzero macros requires review')
        seen.add(record['id'])
        result.append(record)
    if not result:
        raise ValueError('Empty catalogue')
    return {'schema': 1, 'basis_grams': 100, 'source': source, 'foods': result}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--source', required=True)
    args = parser.parse_args()
    result = convert(args.input.read_text(encoding='utf-8-sig'), args.source)
    # Validate the entire file before replacing any output.
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f'Validated {len(result["foods"])} records per 100 g')


if __name__ == '__main__':
    main()
