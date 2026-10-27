import unittest
import xml.etree.ElementTree as ET
from android_diary_source_smoke import DiarySourceSmoke


class NestedFoodListTest(unittest.TestCase):
    def test_scroll_stays_inside_short_food_list_and_does_not_skip_rows(self):
        viewport = ET.Element('node', {'scrollable': 'true', 'bounds': '[70,1808][1370,2588]'})
        apple = ET.Element('node', {'content-desc': 'Apple\n52 kcal', 'clickable': 'true',
                                   'enabled': 'true', 'bounds': '[70,2000][1370,2250]'})

        class Smoke(DiarySourceSmoke):
            def __init__(self):
                self.screens = iter([[viewport], [viewport, apple]])
                self.swipes = []
                self.target = None

            def read_screen(self):
                return next(self.screens)

            def adb(self, *args):
                if args == ('shell', 'wm', 'size'):
                    return 'Physical size: 1440x3120'
                if 'swipe' in args:
                    self.swipes.append(args)
                return ''

            def tap_node(self, node):
                self.target = node

        smoke = Smoke()
        smoke.choose_manual_food('Apple')
        self.assertIs(smoke.target, apple)
        self.assertEqual(len(smoke.swipes), 1)
        swipe = smoke.swipes[0]
        y_start, y_end = int(swipe[4]), int(swipe[6])
        self.assertTrue(1808 < y_end < y_start < 2588)
        self.assertLessEqual(y_start - y_end, (2588 - 1808) // 2)


if __name__ == '__main__':
    unittest.main()
