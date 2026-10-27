import unittest
from import_cofid import convert, numeric


class CoFIDImportTest(unittest.TestCase):
    def test_trace_and_unreliable_quantities_are_not_zero(self):
        for value in ('Tr', 'N', '', None):
            self.assertIsNone(numeric(value))
        self.assertEqual(numeric('0.0'), 0)
        for value in ('nan', 'inf', '-1', True):
            with self.assertRaises(ValueError):
                numeric(value)

    def test_exact_identity_optional_fiber_and_required_macros(self):
        rows = [('Food Code', 'Food Name'),
                (None, None, 'KCALS', 'PROT', 'FAT', 'CHO', 'AOACFIB', 'WATER'),
                (), ('x', 'Raw test food', '57', '4.8', '1', '7.8', 'N', '87.2'),
                (None, None)]
        selection = [('x', 'Raw test food', 'Тест')]
        food = convert(rows, selection)['foods'][0]
        self.assertNotIn('fiber', food)
        self.assertEqual(food['water'], 87.2)
        with self.assertRaises(ValueError):
            convert(rows, [('x', 'Cooked test food', 'Тест')])
        rows[3] = ('x', 'Raw test food', '57', 'Tr', '1', '7.8', 'N', '87.2')
        with self.assertRaises(ValueError):
            convert(rows, selection)


if __name__ == '__main__':
    unittest.main()
