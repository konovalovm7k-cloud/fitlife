import unittest
from import_food_catalog import convert


class FoodImportTest(unittest.TestCase):
    header = 'id;name;kcal;protein;fat;carbs;source_url\n'
    row = 'one;Продукт;120,5;10;5;8;https://example.com/food/one\n'

    def test_decimal_comma_and_source(self):
        result = convert(self.header + self.row, 'Authorized export')
        self.assertEqual(result['basis_grams'], 100)
        self.assertEqual(result['foods'][0]['kcal'], 120.5)
        self.assertNotIn('fiber', result['foods'][0])

    def test_duplicate_ids_are_not_silently_merged(self):
        with self.assertRaises(ValueError):
            convert(self.header + self.row + self.row, 'source')

    def test_invalid_numbers_and_sources_fail_before_output(self):
        for replacement in ['NaN', '-1', '1001']:
            with self.assertRaises(ValueError):
                convert(self.header + self.row.replace('120,5', replacement), 'source')
        with self.assertRaises(ValueError):
            convert(self.header + self.row.replace('https://', 'http://'), 'source')

    def test_missing_columns_and_excess_mass(self):
        with self.assertRaises(ValueError):
            convert('name;kcal\nTest;20\n', 'source')
        with self.assertRaises(ValueError):
            convert(self.header + self.row.replace(';10;5;8;', ';80;80;8;'), 'source')


if __name__ == '__main__':
    unittest.main()
