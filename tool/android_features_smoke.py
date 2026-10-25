"""Verify saved meals and dated weight in the already-installed release APK.

Runs after android_release_smoke.py on the same disposable emulator. No network
requests, real invitations, data resets or physical-device access are used.
"""

import argparse
import os
from android_release_smoke import ReleaseSmoke


class FeaturesSmoke(ReleaseSmoke):
    def set_number(self, value):
        fields = [n for n in self.read_screen()
                  if n.get("class") == "android.widget.EditText"]
        if len(fields) != 1 or fields[0].get("enabled") != "true":
            raise AssertionError("Expected one editable weight field")
        self.tap_node(fields[0])
        self.adb("shell", "input", "keyevent", "123")
        self.adb("shell", "input", "keyevent", *(["67"] * 12))
        self.adb("shell", "input", "text", value)
        self.adb("shell", "input", "keyevent", "111")

    def run_features(self):
        try:
            self.launch()
            self.tap("Профиль")
            self.tap("Обновить вес")
            self.set_number("83.5")
            self.tap_exact("Сохранить")
            self.wait_for("83.5 кг")
            self.launch()
            self.tap("Профиль")
            self.wait_for("83.5 кг")
            self.tap("История веса")
            self.wait_for("Последнее измерение", "83.5 кг")
            self.capture("weight-history-relaunch")

            self.launch()
            self.tap("Питание")
            self.tap("Сохранить блюдо", scroll=True)
            self.wait_for("Порций во всём составе")
            self.tap("Сохранить в мои блюда", scroll=True)
            self.launch()
            self.tap("Питание")
            self.tap("Мои блюда и повтор еды", scroll=True)
            self.wait_for("157 ккал", "Яйцо")
            self.capture("saved-meals-relaunch")
            self.tap("Выбрать порцию", scroll=True)
            self.wait_for("Количество порций")
            self.tap("0.5×")
            self.wait_for("79 ккал")
            self.tap("Добавить блюдо в дневник", scroll=True)
            self.launch()
            self.tap("Питание")
            self.wait_for("236 ккал")
            self.capture("saved-meal-half-portion-relaunch")
            print("PASS: native saved-meal template, half portion and dated weight survive cold relaunch")
        except Exception:
            try:
                self.capture("features-failure")
            except Exception as error:
                print(f"Diagnostic capture: {error}")
            raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--serial", default=os.environ.get("ANDROID_SERIAL", "emulator-5554"))
    parser.add_argument("--output", default="build/release-smoke/features")
    args = parser.parse_args()
    FeaturesSmoke(args.adb, args.serial, args.output).run_features()


if __name__ == "__main__":
    main()
