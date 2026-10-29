import unittest
import contextlib
import io
from unittest.mock import Mock
import xml.etree.ElementTree as ET
from android_features_smoke import FeaturesSmoke


def control(label, bounds, clickable="true"):
    return ET.Element("node", {"content-desc": label, "bounds": bounds,
                              "clickable": clickable, "enabled": "true"})


class ScrollTargetTest(unittest.TestCase):
    def test_pending_template_write_is_acknowledged_before_force_stop(self):
        smoke = object.__new__(FeaturesSmoke)
        pending = False
        acknowledged = False

        def launch():
            if pending:
                raise AssertionError('Force-stop before committed template acknowledgement')

        def tap(label, **_):
            nonlocal pending
            if label == 'Сохранить в мои блюда':
                pending = True

        def wait_for(*labels):
            nonlocal pending, acknowledged
            # This home/FAB screen returns only after the editor has awaited
            # repository.save and popped. All other mocked reads cannot commit.
            if labels == ('Добавить еду', 'Прогресс') and pending:
                pending = False
                acknowledged = True
            return []

        smoke.launch = Mock(side_effect=launch)
        smoke.tap = Mock(side_effect=tap)
        smoke.tap_scrolled_exact = Mock(side_effect=tap)
        smoke.tap_exact = Mock()
        smoke.set_number = Mock()
        smoke.preview_saved_portion = Mock()
        smoke.read_screen = Mock(return_value=[])
        smoke.wait_for = Mock(side_effect=wait_for)
        smoke.capture = Mock()
        with contextlib.redirect_stdout(io.StringIO()):
            smoke.run_features()
        self.assertTrue(acknowledged)
        self.assertFalse(pending)

    def test_source_confirm_button_at_ci_scroll_extent_is_fully_available(self):
        button = control('Подтвердить источник и порцию', '[70,2661][1370,2836]')

        class Smoke(FeaturesSmoke):
            def __init__(self):
                self.target = None

            def read_screen(self):
                return [button]

            def adb(self, *args):
                if args == ('shell', 'wm', 'size'):
                    return 'Physical size: 1440x3120'
                raise AssertionError('At scroll extent; no swipe can move this button higher')

            def tap_node(self, node):
                self.target = node

        smoke = Smoke()
        smoke.tap_scrolled_exact('Подтвердить источник и порцию', max_height=.96)
        self.assertIs(smoke.target, button)

    def test_last_meal_button_above_fab_can_use_explicit_viewport(self):
        class Smoke(FeaturesSmoke):
            def __init__(self):
                self.target = None

            def read_screen(self):
                return [control("Satiety", "[130,2123][909,2291]")]

            def adb(self, *args):
                if args == ("shell", "wm", "size"):
                    return "Physical size: 1440x3120"
                raise AssertionError("Already at bottom; scrolling cannot help")

            def tap_node(self, node):
                self.target = node

        smoke = Smoke()
        smoke.tap_scrolled_exact("Satiety", max_height=.8)
        self.assertEqual(smoke.target.get("bounds"), "[130,2123][909,2291]")

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
