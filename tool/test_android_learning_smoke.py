import unittest
from unittest.mock import Mock
import xml.etree.ElementTree as ET
from android_learning_smoke import LearningSmoke


class TodayTaskNavigationTest(unittest.TestCase):
    def test_merged_card_text_can_identify_and_reveal_loaded_step(self):
        for top in (1200, 2200):
            with self.subTest(top=top):
                card = ET.Element('node', {
                    'content-desc': 'Один небольшой шаг\nПонятно: 1 из 3\nЗачем нужны нутриенты',
                    'bounds': f'[70,{top}][1370,{top + 400}]',
                    'clickable': 'false',
                })
                smoke = object.__new__(LearningSmoke)
                smoke.launch = Mock()
                smoke.scroll_to = Mock(return_value=[card])
                smoke.wait_for = Mock()
                smoke.adb = Mock(return_value='Physical size: 1440x3120')
                smoke.open_today_step('Зачем нужны нутриенты', 1)
                smoke.wait_for.assert_called_once_with('Зачем нужны нутриенты', 'Понятно: 1 из 3')
                swipes = [c.args for c in smoke.adb.call_args_list
                          if c.args[:3] == ('shell', 'input', 'swipe')]
                self.assertEqual(len(swipes), int(top > 3120 * .6))
                if swipes:
                    self.assertGreater(top - (int(swipes[0][4]) - int(swipes[0][6])), 312)


if __name__ == '__main__':
    unittest.main()
