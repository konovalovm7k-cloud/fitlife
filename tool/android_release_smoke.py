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


class ReleaseSmoke:
    def __init__(self, adb, serial, output):
        if not serial.startswith("emulator-"):
            raise ValueError("Smoke tests must only run on a disposable emulator")
        self.command = [adb, "-s", serial]
        self.output = Path(output)
        self.output.mkdir(parents=True, exist_ok=True)
        self.screen = ""

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
            if all(any(label in self.label(n) for n in nodes) for label in labels):
                return nodes
            time.sleep(1)
        raise AssertionError(f"Release screen did not show {labels!r} within 35s")

    def tap(self, label):
        nodes = self.wait_for(label)
        node = next(n for n in nodes if label in self.label(n))
        bounds = [int(value) for value in re.findall(r"\d+", node.get("bounds", ""))]
        if len(bounds) != 4:
            raise AssertionError(f"No tappable bounds for {label!r}")
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

    def run(self, apk):
        self.adb("install", "-r", str(Path(apk).resolve()))
        try:
            self.launch()
            self.capture("first-launch")
            self.wait_for(WATER)
            # Use an increment that remains deterministic if re-run on this AVD.
            nodes = self.read_screen()
            if not any(SAVED_WATER in self.label(node) for node in nodes):
                self.tap(WATER)
            self.wait_for(SAVED_WATER)
            time.sleep(1)
            self.capture("saved-water")
            self.launch()
            self.wait_for(SAVED_WATER)
            self.capture("cold-relaunch")
            self.adb("install", "-r", str(Path(apk).resolve()))
            self.launch()
            self.wait_for(SAVED_WATER)
            self.capture("update-relaunch")
            print("PASS: release startup, native preferences, cold relaunch, in-place update")
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
    args = parser.parse_args()
    ReleaseSmoke(args.adb, args.serial, args.output).run(args.apk)


if __name__ == "__main__":
    main()
