import unittest
import xml.etree.ElementTree as ET
from android_source_smoke import SourceSmoke


class SourceFieldTest(unittest.TestCase):
    def smoke(self, keyboard):
        class Smoke(SourceSmoke):
            def __init__(self):
                self.commands = []
                self.target = None

            def read_screen(self):
                # Last required field at the bottom of a fully scrolled form
                # (one pixel below 80% on the API 35 Pixel 7 Pro).
                return [ET.Element('node', {
                    'resource-id': 'source-nutrient-3',
                    'class': 'android.widget.EditText',
                    'bounds': '[70,2301][1370,2497]',
                })]

            def adb(self, *args):
                self.commands.append(args)
                if args == ('shell', 'wm', 'size'):
                    return 'Physical size: 1440x3120'
                if args == ('shell', 'dumpsys', 'input_method'):
                    return f'mInputShown={str(keyboard).lower()}'
                return ''

            def tap_node(self, node):
                self.target = node

        return Smoke()

    def test_bottom_field_and_numeric_keyboard(self):
        smoke = self.smoke(True)
        smoke.field('source-nutrient-3', '28')
        self.assertIsNotNone(smoke.target)
        self.assertIn(('shell', 'input', 'text', '28'), smoke.commands)
        self.assertIn(('shell', 'input', 'keyevent', '4'), smoke.commands)
        self.assertFalse(any('swipe' in command for command in smoke.commands))

    def test_no_back_navigation_when_keyboard_is_hidden(self):
        smoke = self.smoke(False)
        smoke.field('source-nutrient-3', '28')
        self.assertNotIn(('shell', 'input', 'keyevent', '4'), smoke.commands)


if __name__ == '__main__':
    unittest.main()
