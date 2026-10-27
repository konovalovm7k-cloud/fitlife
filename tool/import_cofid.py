"""Reproduce the curated offline asset from the official CoFID 2021 workbook.

One-off developer tool: requires openpyxl, never performs network requests.
Only the pinned workbook and exact selected food names are accepted.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path

WORKBOOK_SHA256 = '436e9445ef2adb2a75f3d7edd51302de3adad25385f9795fc94ba58bd030e97d'
SOURCE_URL = 'https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid'
ATTRIBUTION = 'Contains public sector information licensed under the Open Government Licence v3.0.'
FIELDS = {'kcal': 'KCALS', 'protein': 'PROT', 'fat': 'FAT', 'carbs': 'CHO',
          'fiber': 'AOACFIB', 'water': 'WATER'}


def numeric(value):
    # Tr (trace), N (unreliable quantity) and blank are not numeric zero.
    if isinstance(value, bool):
        raise ValueError('Boolean nutrient')
    if value is None or str(value).strip() in {'', 'Tr', 'N'}:
        return None
    number = float(value)
    if not math.isfinite(number) or number < 0:
        raise ValueError('Invalid nutrient')
    return number


def convert(rows, selection):
    columns = {value: index for index, value in enumerate(rows[1]) if value}
    if not set(FIELDS.values()).issubset(columns):
        raise ValueError('Unexpected nutrient columns')
    by_code = {}
    for row in rows[3:]:
        if not row[0]:
            continue
        by_code.setdefault(row[0], []).append(row)
    foods = []
    for code, english, russian in selection:
        matches = by_code[code]
        if len(matches) != 1:
            raise ValueError(f'Ambiguous selected food code: {code}')
        row = matches[0]
        if row[1] != english:
            raise ValueError(f'Food identity changed: {code}')
        values = {key: numeric(row[columns[column]]) for key, column in FIELDS.items()}
        if any(values[key] is None for key in ('kcal', 'protein', 'fat', 'carbs')):
            raise ValueError(f'Non-numeric required nutrient: {code}')
        if any(v > (950 if k == 'kcal' else 100) for k, v in values.items() if v is not None):
            raise ValueError(f'Out-of-range nutrient: {code}')
        foods.append({'id': f'cofid_2021_{code}', 'name': russian,
                      'original_name': english, 'food_code': code,
                      'source_url': SOURCE_URL,
                      'source_reference': f'CoFID 2021 / {code} / {english}',
                      **{k: v for k, v in values.items() if v is not None}})
    if len({f['id'] for f in foods}) != len(foods):
        raise ValueError('Duplicate selection')
    return {'schema': 1, 'basis_grams': 100, 'source': 'CoFID 2021 / Public Health England',
            'attribution': ATTRIBUTION,
            'licence_url': 'https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/',
            'workbook_sha256': WORKBOOK_SHA256, 'foods': foods}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('workbook', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    if hashlib.sha256(args.workbook.read_bytes()).hexdigest() != WORKBOOK_SHA256:
        raise ValueError('Workbook checksum differs; review the source before import')
    import openpyxl
    workbook = openpyxl.load_workbook(args.workbook, read_only=True, data_only=True)
    try:
        selection = json.loads(Path(__file__).with_name('cofid_selection.json').read_text(encoding='utf-8'))
        result = convert(list(workbook['1.3 Proximates'].values), selection)
    finally:
        workbook.close()
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'Validated {len(result["foods"])} source-linked foods per 100 g')


if __name__ == '__main__':
    main()
