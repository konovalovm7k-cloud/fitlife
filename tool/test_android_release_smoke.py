import unittest
import xml.etree.ElementTree as ET
from android_release_smoke import ReleaseSmoke


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


if __name__ == "__main__":
    unittest.main()
