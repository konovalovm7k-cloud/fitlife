"""Check Today guidance and its real diary action in the signed release.

Run after release and feature smoke, on the same disposable emulator only.
"""
import argparse
import os
from android_features_smoke import FeaturesSmoke


class TodaySmoke(FeaturesSmoke):
    def run_today(self):
        try:
            self.launch()
            self.capture("today-top")
            self.scroll_to("Клетчатка")
            self.capture("today-nutrients")
            self.scroll_to("Твой помощник")
            self.wait_for("83.5 кг")
            self.capture("today-companion")
            self.tap_scrolled_exact("Выбрать продукт")
            self.wait_for("Что было на тарелке?")
            self.tap("Куриная грудка")
            self.wait_for("Выбрано: Куриная грудка")
            self.tap_exact("Добавить")
            self.launch()
            self.tap("Питание")
            # The same name also appears in the recent-food chip. Verify the
            # persisted diary row, including its portion, below that section.
            self.scroll_to("100 г · 120 ккал")
            self.wait_for("Куриная грудка", "100 г · 120 ккал")
            self.capture("today-action-relaunch")
            print("PASS: Today nutrients, real weight, supportive companion and guidance-to-diary save survive relaunch")
        except Exception:
            self.capture("today-failure")
            raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--serial", default=os.environ.get("ANDROID_SERIAL", "emulator-5554"))
    parser.add_argument("--output", default="build/release-smoke/today")
    args = parser.parse_args()
    TodaySmoke(args.adb, args.serial, args.output).run_today()


if __name__ == "__main__":
    main()
