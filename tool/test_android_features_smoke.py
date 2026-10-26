import unittest
import xml.etree.ElementTree as ET
from android_features_smoke import FeaturesSmoke


def control(label, bounds, clickable="true"):
    return ET.Element("node", {"content-desc": label, "bounds": bounds,
                              "clickable": clickable, "enabled": "true"})


class ScrollTargetTest(unittest.TestCase):
    def test_ignores_parent_labels_and_controls_under_floating_button(self):
        class Smoke(FeaturesSmoke):
            def __init__(self):
                self.screens = iter([
                    [control("Meal Save", "[0,100][300,400]"),
                     control("Save", "[200,850][300,910]")],
                    [control("Save", "[200,400][300,460]")]])
                self.swipes = 0
                self.target = None

            def read_screen(self):
                return next(self.screens)

            def adb(self, *args):
                if args == ("shell", "wm", "size"):
                    return "Physical size: 400x1000"
                if "swipe" in args:
                    self.swipes += 1
                return ""

            def tap_node(self, node):
                self.target = node

        smoke = Smoke()
        smoke.tap_scrolled_exact("Save")
        self.assertEqual(smoke.swipes, 1)
        self.assertEqual(smoke.target.get("bounds"), "[200,400][300,460]")


if __name__ == "__main__":
    unittest.main()
