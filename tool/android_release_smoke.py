"""Exercise the installed release APK, including real JNI-backed preferences.

Only a disposable Android emulator is accepted. No app data is cleared.
"""

import argparse
import os
from pathlib import Path
import re
import subprocess
import time
import xml.etree.ElementTree as ET


PACKAGE = "com.example.fitlife"
HOME = "FITLIFE"
ADD_FOOD = "\u0414\u043e\u0431\u0430\u0432\u0438\u0442\u044c \u0435\u0434\u0443"
WATER = "\u0412\u043e\u0434\u0430"
SAVED_WATER = "0.25 \u043b"
CAMERA = "\u041a\u0430\u043c\u0435\u0440\u0430"
CONNECT = "\u041f\u043e\u0434\u043a\u043b\u044e\u0447\u0438\u0442\u044c \u0441\u0435\u0440\u0432\u0435\u0440 \u0440\u0430\u0441\u043f\u043e\u0437\u043d\u0430\u0432\u0430\u043d\u0438\u044f"
SERVER_ADDRESS = "\u0410\u0434\u0440\u0435\u0441 \u0441\u0435\u0440\u0432\u0435\u0440\u0430 HTTPS"
ACCESS_CODE = "\u041b\u0438\u0447\u043d\u044b\u0439 \u043a\u043e\u0434 \u0434\u043e\u0441\u0442\u0443\u043f\u0430"
SAVE_CONNECTION = "\u0421\u043e\u0445\u0440\u0430\u043d\u0438\u0442\u044c \u043f\u043e\u0434\u043a\u043b\u044e\u0447\u0435\u043d\u0438\u0435"
REMOVE_CONNECTION = "\u0423\u0434\u0430\u043b\u0438\u0442\u044c \u043f\u043e\u0434\u043a\u043b\u044e\u0447\u0435\u043d\u0438\u0435"
PHOTO_TITLE = "\u0424\u043e\u0442\u043e \u0431\u043b\u044e\u0434\u0430"


class ReleaseSmoke:
    def __init__(self, adb, serial, output):
        if not serial.startswith("emulator-"):
            raise ValueError("Smoke tests must only run on a disposable emulator")
        self.command = [adb, "-s", serial]
        self.output = Path(output)
        self.output.mkdir(parents=True, exist_ok=True)
        self.screen = ""
        self.launcher_dismissals = 0

    def adb(self, *args, binary=False):
        result = subprocess.run(
            self.command + list(args),
            capture_output=True,
            timeout=40,
            check=True,
        ).stdout
        return result if binary else result.decode("utf-8", errors="replace")

    def read_screen(self):
        self.adb("shell", "uiautomator", "dump", "/sdcard/fitlife-smoke.xml")
        self.screen = self.adb("shell", "cat", "/sdcard/fitlife-smoke.xml")
        root = ET.fromstring(self.screen)
        return list(root.iter("node"))

    @staticmethod
    def label(node):
        return node.get("text", "") + " " + node.get("content-desc", "")

    def wait_for(self, *labels):
        deadline = time.monotonic() + 35
        while time.monotonic() < deadline:
            nodes = self.read_screen()
            if self.dismiss_emulator_launcher_anr(nodes):
                continue
            if all(any(label in self.label(n) for n in nodes) for label in labels):
                return nodes
            time.sleep(1)
        raise AssertionError(f"Release screen did not show {labels!r} within 35s")

    def dismiss_emulator_launcher_anr(self, nodes):
        # A fresh overloaded CI image can show a launcher ANR over the running app.
        # Never dismiss FitLife/unknown ANRs or disable Android's ANR reporting.
        title = next((n for n in nodes if n.get("package") == "android"
                      and n.get("resource-id") == "android:id/alertTitle"), None)
        if title is None or title.get("text") != "Pixel Launcher isn't responding":
            return False
        if self.launcher_dismissals:
            raise AssertionError("Repeated Pixel Launcher ANR: emulator is unhealthy")
        close = next((n for n in nodes if n.get("package") == "android"
                      and n.get("resource-id") == "android:id/aerr_close"), None)
        if close is None:
            raise AssertionError("Launcher ANR has no verified close button")
        self.capture("emulator-launcher-anr")
        self.launcher_dismissals += 1
        self.tap_node(close)
        print("Recorded and closed one Pixel Launcher ANR; FitLife checks remain required")
        return True

    def tap(self, label, *, scroll=False):
        nodes = self.scroll_to(label) if scroll else self.wait_for(label)
        node = next(n for n in nodes if label in self.label(n))
        self.tap_node(node)

    def scroll_to(self, label):
        sizes = re.findall(r"(\d+)x(\d+)", self.adb("shell", "wm", "size"))
        if not sizes:
            raise AssertionError("Cannot determine emulator screen size")
        width, height = map(int, sizes[-1])
        for _ in range(10):
            nodes = self.read_screen()
            if self.dismiss_emulator_launcher_anr(nodes):
                continue
            if any(label in self.label(node) for node in nodes):
                return nodes
            self.adb("shell", "input", "swipe", str(width // 2), str(height * 3 // 4),
                     str(width // 2), str(height // 3), "350")
        raise AssertionError(f"Could not scroll to {label!r}")

    def tap_field(self, index):
        fields = [n for n in self.read_screen() if n.get("class") == "android.widget.EditText"]
        if len(fields) != 2 or fields[index].get("enabled") != "true":
            raise AssertionError("Connection fields are not ready")
        self.tap_node(fields[index])

    def tap_exact(self, label):
        deadline = time.monotonic() + 35
        while time.monotonic() < deadline:
            for node in self.read_screen():
                if self.label(node).strip() == label and node.get("enabled") == "true":
                    self.tap_node(node)
                    return
            time.sleep(1)
        raise AssertionError(f"No enabled exact button: {label!r}")

    def set_goal_field(self, index, value):
        fields = [n for n in self.read_screen() if n.get("class") == "android.widget.EditText"]
        if len(fields) != 4 or fields[index].get("enabled") != "true":
            raise AssertionError("Goal fields are not ready")
        self.tap_node(fields[index])
        self.adb("shell", "input", "keyevent", "123")  # Move to end.
        self.adb("shell", "input", "keyevent", *(["67"] * 12))
        self.adb("shell", "input", "text", value)
        self.adb("shell", "input", "keyevent", "111")  # Hide keyboard.

    def tap_node(self, node):
        bounds = [int(value) for value in re.findall(r"\d+", node.get("bounds", ""))]
        if len(bounds) != 4:
            raise AssertionError("No tappable bounds")
        left, top, right, bottom = bounds
        self.adb("shell", "input", "tap", str((left + right) // 2), str((top + bottom) // 2))

    def launch(self):
        self.adb("shell", "am", "force-stop", PACKAGE)
        self.adb("shell", "am", "start", "-W", "-n", f"{PACKAGE}/.MainActivity")
        self.wait_for(HOME, ADD_FOOD)

    def capture(self, name):
        (self.output / f"{name}.xml").write_text(self.screen, encoding="utf-8")
        (self.output / f"{name}.png").write_bytes(
            self.adb("exec-out", "screencap", "-p", binary=True)
        )
        pid = self.adb("shell", "pidof", PACKAGE).strip()
        if pid:
            logs = self.adb("logcat", "-d", f"--pid={pid}")
            (self.output / f"{name}-logcat.txt").write_text(logs, encoding="utf-8")
            failures = ("Unhandled Exception", "FATAL EXCEPTION", "storage initialization failed")
            if any(message in logs for message in failures):
                raise AssertionError(f"Native/release error detected; see {name}-logcat.txt")

    def ensure_manual_egg(self):
        fixture = '100 г · 157 ккал'
        # On an upgrade AVD the daily total need not equal this one fixture.
        # Seek the actual entry before adding, retaining all other diary data.
        empty = any(self.label(n).strip().startswith('0 ккал\n') for n in self.read_screen())
        found = False
        if not empty:
            try:
                self.scroll_to(fixture)
                found = True
            except AssertionError as error:
                if str(error) != f'Could not scroll to {fixture!r}':
                    raise  # Do not hide an unhealthy emulator/other failure.
        if not found:
            self.tap(ADD_FOOD)
            self.tap('Яйцо')
            self.wait_for('Выбрано: Яйцо')
            self.select_fixture_breakfast()
            self.tap_exact('Добавить')
            self.scroll_to(fixture)
        self.wait_for(fixture, 'Яйцо')

    def select_fixture_breakfast(self):
        # Keep unconfirmed legacy fixtures out of SourceSmoke's sourced snack,
        # including when the runner's default meal becomes snack after 21:00.
        self.tap('Приём пищи')
        self.tap_exact('Завтрак')

    def run(self, apk, expect_auto_connection=False):
        self.adb("install", "-r", str(Path(apk).resolve()))
        try:
            self.launch()
            self.capture("first-launch")
            if expect_auto_connection:
                self.tap(CAMERA)
                self.tap(CONNECT)
                self.wait_for("https://fitlife-photo.konovalov-m7k.workers.dev")
                self.capture("automatic-connection")
                self.adb("shell", "input", "keyevent", "4")
                self.tap("\u0421\u0435\u0433\u043e\u0434\u043d\u044f")
            self.scroll_to(WATER)
            # Use an increment that remains deterministic if re-run on this AVD.
            nodes = self.read_screen()
            if not any(SAVED_WATER in self.label(node) for node in nodes):
                self.tap(WATER, scroll=True)
            self.scroll_to(SAVED_WATER)
            time.sleep(1)
            self.capture("saved-water")
            self.launch()
            self.scroll_to(SAVED_WATER)
            self.capture("cold-relaunch")
            self.adb("install", "-r", str(Path(apk).resolve()))
            self.launch()
            self.scroll_to(SAVED_WATER)
            self.capture("update-relaunch")
            self.tap("Профиль")
            self.tap("Настроить цели")
            self.wait_for("Цели питания", "Сохранить")
            for index, value in enumerate(("2400", "160", "70", "35")):
                self.set_goal_field(index, value)
            self.wait_for("Углеводы: 282,5 г.")
            self.tap("Сохранить")
            self.wait_for("2400 ккал", "160 г", "70 г", "282,5 г", "35 г")
            self.launch()
            self.tap("Профиль")
            self.wait_for("2400 ккал", "160 г", "70 г", "282,5 г", "35 г")
            self.tap("Настроить цели")
            for index, value in enumerate(("2400.5", "160.25", "70.5", "35.25")):
                self.set_goal_field(index, value)
            self.wait_for("Углеводы: 281,25 г.")
            self.tap("Сохранить")
            self.wait_for("2400,5 ккал", "160,25 г", "70,5 г", "281,25 г", "35,25 г")
            self.launch()
            self.tap("Профиль")
            self.wait_for("2400,5 ккал", "160,25 г", "70,5 г", "281,25 г", "35,25 г")
            self.capture("nutrition-goals-relaunch")
            # Exercise the controller -> diary adapter -> JNI preferences path.
            # The disposable CI AVD starts with no diary; no data is cleared.
            self.tap("Питание")
            self.ensure_manual_egg()
            self.launch()
            self.tap("Питание")
            self.scroll_to('100 г · 157 ккал')
            self.wait_for('100 г · 157 ккал', 'Яйцо')
            self.capture("manual-diary-relaunch")
            self.tap(CAMERA)
            self.tap(CONNECT)
            self.wait_for(SAVE_CONNECTION)
            self.tap(REMOVE_CONNECTION)
            time.sleep(1)
            self.tap_field(0)
            self.adb("shell", "input", "text", "https://fitlife-smoke.example.com")
            self.tap_field(1)
            self.adb("shell", "input", "text", "a" * 43)
            self.adb("shell", "input", "keyevent", "111")
            self.tap(SAVE_CONNECTION)
            self.wait_for(PHOTO_TITLE)
            self.launch()
            self.tap(CAMERA)
            self.tap(CONNECT)
            self.wait_for("https://fitlife-smoke.example.com")
            self.capture("secure-connection-relaunch")
            self.tap(REMOVE_CONNECTION)
            time.sleep(1)
            nodes = self.read_screen()
            if any("https://fitlife-smoke.example.com" in self.label(n) for n in nodes):
                raise AssertionError("Secure connection was not removed")
            print("PASS: release startup, native preferences, relaunch, update, fractional nutrition goals and derived carbs, manual diary, encrypted connection save/read/delete")
        except Exception:
            try:
                self.capture("failure")
            except Exception as diagnostic_error:
                print(f"Diagnostic capture: {diagnostic_error}")
            raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk")
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--serial", default=os.environ.get("ANDROID_SERIAL", "emulator-5554"))
    parser.add_argument("--output", default="build/release-smoke")
    parser.add_argument("--expect-auto-connection", action="store_true")
    args = parser.parse_args()
    ReleaseSmoke(args.adb, args.serial, args.output).run(args.apk, args.expect_auto_connection)


if __name__ == "__main__":
    main()
