import unittest
from unittest.mock import Mock
import xml.etree.ElementTree as ET
from android_today_smoke import TodaySmoke


def node(label, bounds):
    return ET.Element('node', {'content-desc': label, 'bounds': bounds,
                              'clickable': 'true', 'enabled': 'true'})


class MealEditTargetTest(unittest.TestCase):
    def test_editor_is_in_the_named_chicken_row_not_the_first_other_entry(self):
        smoke = object.__new__(TodaySmoke)
        other = node('Изменить порцию', '[900,200][1000,300]')
        source = node('Источник состава: Куриная грудка', '[800,600][900,700]')
        correct = node('Изменить порцию', '[900,600][1000,700]')
        smoke.scroll_to = Mock(return_value=[other, source, correct])
        smoke.adb = Mock(return_value='Physical size: 1440x3120')
        smoke.tap_node = Mock()
        smoke.tap_food_editor('Куриная грудка')
        smoke.tap_node.assert_called_once_with(correct)

    def test_missing_or_ambiguous_editor_cannot_mutate_another_entry(self):
        source = node('Источник состава: Куриная грудка', '[800,600][900,700]')
        for edits in ([], [node('Изменить порцию', '[900,200][1000,300]')],
                      [node('Изменить порцию', '[900,600][1000,700]')] * 2):
            with self.subTest(edits=len(edits)):
                smoke = object.__new__(TodaySmoke)
                smoke.scroll_to = Mock(return_value=[source, *edits])
                smoke.adb = Mock(return_value='Physical size: 1440x3120')
                smoke.tap_node = Mock()
                with self.assertRaises(AssertionError):
                    smoke.tap_food_editor('Куриная грудка')
                smoke.tap_node.assert_not_called()

    def test_editor_is_resolved_again_after_scrolling_above_navigation(self):
        smoke = object.__new__(TodaySmoke)
        low = [node('Источник состава: Куриная грудка', '[800,2900][900,3000]'),
               node('Изменить порцию', '[900,2900][1000,3000]')]
        source = node('Источник состава: Куриная грудка', '[800,700][900,800]')
        correct = node('Изменить порцию', '[900,700][1000,800]')
        smoke.scroll_to = Mock(side_effect=[low, [source, correct]])
        smoke.adb = Mock(return_value='Physical size: 1440x3120')
        smoke.tap_node = Mock()
        smoke.tap_food_editor('Куриная грудка')
        smoke.tap_node.assert_called_once_with(correct)


if __name__ == '__main__':
    unittest.main()
