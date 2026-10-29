import unittest
from unittest.mock import Mock
import xml.etree.ElementTree as ET
from android_meal_ideas_smoke import MealIdeasSmoke


class MealIdeaVisibilityTest(unittest.TestCase):
    def smoke(self, bounds):
        target = ET.Element('node', {
            'resource-id': 'idea-review-yogurt_pear_almonds_v1',
            'bounds': bounds, 'enabled': 'true',
        })
        other = ET.Element('node', {
            'resource-id': 'idea-review-rice_beans_broccoli_v1',
            'bounds': '[126,975][903,1150]', 'enabled': 'true',
        })
        smoke = object.__new__(MealIdeasSmoke)
        smoke.adb = Mock(return_value='Physical size: 1440x3120')
        smoke.read_screen = Mock(return_value=[other, target])
        smoke.tap_node = Mock()
        return smoke, target

    def test_last_button_fully_above_gesture_area_can_be_tapped_without_more_swipes(self):
        # Actual native XML: complete button ends at94.2%; the gesture area is below.
        smoke, target = self.smoke('[126,2763][903,2938]')
        smoke.tap_idea('yogurt_pear_almonds_v1')
        smoke.tap_node.assert_called_once_with(target)
        self.assertEqual(smoke.adb.call_count, 1)  # Read dimensions, no pointless swipe.

    def test_clipped_last_button_never_taps_it_or_a_different_visible_idea(self):
        smoke, _ = self.smoke('[126,2980][903,3120]')
        with self.assertRaisesRegex(AssertionError, '^No fully visible meal idea review button$'):
            smoke.tap_idea('yogurt_pear_almonds_v1')
        smoke.tap_node.assert_not_called()


if __name__ == '__main__':
    unittest.main()
