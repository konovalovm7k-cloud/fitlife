"""Published food identities and curated Chef metadata are compatibility data."""
import hashlib
import json
from pathlib import Path
import unittest
from generate_chef_catalogue import metadata


class CatalogueCompatibilityTest(unittest.TestCase):
    def test_published_twenty_records_and_existing_chef_identities_do_not_change(self):
        root = Path(__file__).resolve().parents[1]
        data = json.loads((root / 'assets/data/food_catalog.json').read_text(encoding='utf-8'))
        published = json.dumps(data['foods'][:20], sort_keys=True,
                               ensure_ascii=False, separators=(',', ':')).encode('utf-8')
        # Frozen from shipped 4.6.24, including IDs, names, source and all facts.
        self.assertEqual(hashlib.sha256(published).hexdigest(),
                         '16258bcdccc0d7f28053912f122ff1c5fc268919adb87983026b7c0aeb27a69a')
        self.assertEqual(len(data['foods']), 40)
        self.assertEqual(len({x['id'] for x in data['foods']}), 40)
        self.assertEqual(metadata(data), json.loads(
            (root / 'shared/chef_catalogue.json').read_text(encoding='utf-8')))


if __name__ == '__main__':
    unittest.main()
