#!/usr/bin/env python3
"""Import explicitly selected health-diet.ru product cards into JSON.

Usage:
  python tool/health_diet_importer.py urls.txt build/nutrition_seed.json

The importer intentionally works from an explicit URL list instead of
blindly crawling the whole site. Check the site's current terms/permissions
before distributing a generated database. The source URL is retained in each
record for provenance.
"""
from __future__ import annotations

import json
import re
import sys
import time
from html.parser import HTMLParser
from urllib.parse import urlparse
from urllib.request import Request, urlopen


class TableParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.rows: list[list[str]] = []
        self._row: list[str] | None = None
        self._cell: list[str] | None = None

    def handle_starttag(self, tag: str, attrs) -> None:
        if tag == 'tr':
            self._row = []
        elif tag in ('td', 'th') and self._row is not None:
            self._cell = []

    def handle_endtag(self, tag: str) -> None:
        if tag in ('td', 'th') and self._row is not None and self._cell is not None:
            text = re.sub(r'\s+', ' ', ''.join(self._cell)).strip()
            self._row.append(text)
            self._cell = None
        elif tag == 'tr' and self._row is not None:
            if self._row:
                self.rows.append(self._row)
            self._row = None

    def handle_data(self, data: str) -> None:
        if self._cell is not None:
            self._cell.append(data)


def number(text: str) -> float | None:
    match = re.search(r'[-+]?\d+(?:[.,]\d+)?', text.replace(' ', ''))
    return float(match.group(0).replace(',', '.')) if match else None


def fetch(url: str) -> str:
    request = Request(url, headers={'User-Agent': 'FitLife nutrition importer/1.0'})
    with urlopen(request, timeout=20) as response:
        return response.read().decode('utf-8', errors='replace')


def parse(url: str) -> dict:
    html = fetch(url)
    parser = TableParser()
    parser.feed(html)
    rows = parser.rows

    title_match = re.search(r'<h1[^>]*>(.*?)</h1>', html, re.I | re.S)
    title = re.sub(r'<[^>]+>', '', title_match.group(1)).strip() if title_match else url
    title = re.sub(r'\s+', ' ', title)

    nutrients: dict[str, float] = {}
    for row in rows:
        if len(row) >= 2:
            value = number(row[1])
            if value is not None:
                nutrients[row[0]] = value

    return {
        'id': 'healthdiet_' + url.rstrip('/').split('/')[-1].split('.')[0],
        'name': title,
        'source': 'health-diet.ru',
        'sourceUrl': url,
        'nutrients': nutrients,
    }


def main() -> int:
    if len(sys.argv) != 3:
        print('usage: health_diet_importer.py urls.txt output.json')
        return 2

    input_path, output_path = sys.argv[1:]
    with open(input_path, encoding='utf-8') as handle:
        urls = [line.strip() for line in handle if line.strip() and not line.startswith('#')]

    records = []
    for url in urls:
        parsed = urlparse(url)
        if parsed.netloc not in {'health-diet.ru', 'www.health-diet.ru'}:
            raise ValueError(f'unsupported host: {parsed.netloc}')
        records.append(parse(url))
        time.sleep(1.0)

    with open(output_path, 'w', encoding='utf-8') as handle:
        json.dump(records, handle, ensure_ascii=False, indent=2)

    print(f'Imported {len(records)} product cards to {output_path}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
