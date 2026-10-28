import unittest
import xml.etree.ElementTree as ET
from android_release_smoke import ReleaseSmoke, WATER, ADD_FOOD


def dialog(title, *, package="android", close=True):
    nodes = [ET.Element("node", {"package": package, "resource-id": "android:id/alertTitle", "text": title})]
    if close:
        nodes.append(ET.Element("node", {"package": "android", "resource-id": "android:id/aerr_close"}))
    return nodes


class FakeSmoke(ReleaseSmoke):
    def __init__(self):
        self.launcher_dismissals = 0
        self.captures = []
        self.taps = []

    def capture(self, name):
        self.captures.append(name)

    def tap_node(self, node):
        self.taps.append(node.get("resource-id"))


class LauncherAnrTest(unittest.TestCase):
    def test_records_before_closing_only_known_system_launcher(self):
        smoke = FakeSmoke()
        self.assertTrue(smoke.dismiss_emulator_launcher_anr(dialog("Pixel Launcher isn't responding")))
        self.assertEqual(smoke.captures, ["emulator-launcher-anr"])
        self.assertEqual(smoke.taps, ["android:id/aerr_close"])

    def test_never_dismisses_fitlife_or_other_apps(self):
        for title in ["FitLife isn't responding", "System UI isn't responding", "Pixel Launcher keeps stopping"]:
            smoke = FakeSmoke()
            self.assertFalse(smoke.dismiss_emulator_launcher_anr(dialog(title)))
            self.assertEqual(smoke.taps, [])

    def test_requires_verified_system_package_and_close_button(self):
        smoke = FakeSmoke()
        self.assertFalse(smoke.dismiss_emulator_launcher_anr(dialog("Pixel Launcher isn't responding", package="com.example.fitlife")))
        with self.assertRaisesRegex(AssertionError, "verified close"):
            smoke.dismiss_emulator_launcher_anr(dialog("Pixel Launcher isn't responding", close=False))

    def test_repeated_launcher_anr_fails_instead_of_silently_retrying(self):
        smoke = FakeSmoke()
        smoke.dismiss_emulator_launcher_anr(dialog("Pixel Launcher isn't responding"))
        with self.assertRaisesRegex(AssertionError, "unhealthy"):
            smoke.dismiss_emulator_launcher_anr(dialog("Pixel Launcher isn't responding"))
        self.assertEqual(len(smoke.taps), 1)

    def test_normal_app_screen_is_unchanged(self):
        smoke = FakeSmoke()
        self.assertFalse(smoke.dismiss_emulator_launcher_anr([]))
        self.assertEqual(smoke.taps, [])

    def test_scrolled_tap_restores_viewport_after_launcher_dialog(self):
        water = ET.Element("node", {"text": WATER, "resource-id": "water"})
        class ScrollingSmoke(FakeSmoke):
            def __init__(self):
                super().__init__()
                self.screens = iter([dialog("Pixel Launcher isn't responding"), [], [water]])
                self.swipes = 0
            def read_screen(self):
                return next(self.screens)
            def adb(self, *args):
                if args == ("shell", "wm", "size"):
                    return "Physical size: 1440x3120"
                if "swipe" in args:
                    self.swipes += 1
                return ""
        smoke = ScrollingSmoke()
        smoke.tap(WATER, scroll=True)
        self.assertEqual(smoke.taps, ["android:id/aerr_close", "water"])
        self.assertEqual(smoke.swipes, 1)


class DiaryFixtureTest(unittest.TestCase):
    def smoke(self, *, empty=False, scroll_error=None):
        class Smoke(ReleaseSmoke):
            def __init__(self):
                self.actions = []
            def read_screen(self):
                return [ET.Element('node', {'content-desc': ('0' if empty else '235') + ' ккал\nОсталось'})]
            def scroll_to(self, label):
                self.actions.append(('scroll', label))
                if scroll_error:
                    raise AssertionError(scroll_error)
                return []
            def tap(self, label):
                self.actions.append(('tap', label))
            def tap_exact(self, label):
                self.actions.append(('tap_exact', label))
            def wait_for(self, *labels):
                self.actions.append(('wait', labels))
        return Smoke()

    def test_occupied_diary_seeks_real_entry_without_adding_another(self):
        smoke = self.smoke()
        smoke.ensure_manual_egg()
        self.assertEqual(smoke.actions, [('scroll', '100 г · 157 ккал'),
                                         ('wait', ('100 г · 157 ккал', 'Яйцо'))])

    def test_empty_diary_adds_fixture_then_checks_entry_not_daily_total(self):
        smoke = self.smoke(empty=True)
        smoke.ensure_manual_egg()
        self.assertEqual(smoke.actions[0], ('tap', ADD_FOOD))
        self.assertEqual(smoke.actions[-2:], [('scroll', '100 г · 157 ккал'),
                                             ('wait', ('100 г · 157 ккал', 'Яйцо'))])

    def test_unhealthy_emulator_is_not_treated_as_missing_fixture(self):
        smoke = self.smoke(scroll_error='Repeated Pixel Launcher ANR: emulator is unhealthy')
        with self.assertRaisesRegex(AssertionError, 'unhealthy'):
            smoke.ensure_manual_egg()
        self.assertFalse(any(a[0] == 'tap' for a in smoke.actions))


if __name__ == "__main__":
    unittest.main()
