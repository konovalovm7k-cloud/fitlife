import unittest
from unittest.mock import Mock
import xml.etree.ElementTree as ET
from android_chef_smoke import ChefSmoke


class ChefNavigationTest(unittest.TestCase):
    def smoke(self, enabled='true'):
        smoke = object.__new__(ChefSmoke)
        smoke.launch = Mock()
        smoke.tap_scrolled_exact = Mock()
        smoke.wait_for = Mock(return_value=[ET.Element('node', {
            'class': 'android.widget.EditText', 'resource-id': 'chef-pantry',
            'enabled': enabled, 'text': '', 'content-desc': '',
        })])
        return smoke

    def test_empty_pantry_field_without_accessibility_label_is_ready(self):
        smoke = self.smoke()
        smoke.open_chef()
        smoke.wait_for.assert_called_once_with('Что есть под рукой?')
        self.assertEqual(smoke.tap_scrolled_exact.call_count, 2)

    def test_disabled_pantry_field_fails_readiness(self):
        with self.assertRaisesRegex(AssertionError, 'not ready'):
            self.smoke('false').open_chef()


if __name__ == '__main__':
    unittest.main()
