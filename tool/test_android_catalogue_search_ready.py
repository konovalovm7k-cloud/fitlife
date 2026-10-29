import unittest
from unittest.mock import Mock, patch
import xml.etree.ElementTree as ET
from android_source_smoke import SourceSmoke


class CatalogueSearchReadyTest(unittest.TestCase):
    def test_opening_catalogue_cannot_scroll_search_away_before_semantics_are_ready(self):
        smoke = object.__new__(SourceSmoke)
        field = ET.Element('node', {'resource-id': 'catalog-search',
            'class': 'android.widget.EditText', 'bounds': '[42,340][1398,600]'})
        smoke.read_screen = Mock(side_effect=[[], [field]])
        smoke.tap_node = Mock()
        smoke.adb = Mock(side_effect=lambda *a: 'Physical size: 1440x3120'
                         if a == ('shell', 'wm', 'size') else '')
        with patch('android_source_smoke.time.sleep'):
            smoke.field('catalog-search', '14-318')
        smoke.tap_node.assert_called_once_with(field)
        self.assertFalse(any('swipe' in c.args for c in smoke.adb.call_args_list))
        self.assertIn(('shell', 'input', 'text', '14-318'),
                      [c.args for c in smoke.adb.call_args_list])

    def test_missing_catalogue_input_times_out_without_typing_into_other_fields(self):
        smoke = object.__new__(SourceSmoke)
        other = ET.Element('node', {'resource-id': 'source-grams',
            'class': 'android.widget.EditText', 'bounds': '[42,340][1398,600]'})
        smoke.read_screen = Mock(return_value=[other])
        smoke.tap_node = Mock()
        smoke.adb = Mock(return_value='Physical size: 1440x3120')
        with patch('android_source_smoke.time.sleep'):
            with self.assertRaisesRegex(AssertionError, 'No editable source field: catalog-search'):
                smoke.field('catalog-search', '14-318')
        smoke.tap_node.assert_not_called()
        self.assertEqual(smoke.adb.call_args_list, [unittest.mock.call('shell', 'wm', 'size')])


if __name__ == '__main__':
    unittest.main()
