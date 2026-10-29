"""Check Today guidance and its real diary action in the signed release.

Run after release and feature smoke, on the same disposable emulator only.
"""
import argparse
import os
import re
from android_features_smoke import FeaturesSmoke


class TodaySmoke(FeaturesSmoke):
    def tap_food_editor(self, name):
        width, height = map(int, re.findall(r'(\d+)x(\d+)', self.adb('shell', 'wm', 'size'))[-1])
        label = 'Источник состава: ' + name
        for _ in range(2):
            nodes = self.scroll_to(label)
            sources = [n for n in nodes if self.label(n).strip() == label
                       and n.get('enabled') == 'true' and n.get('clickable') == 'true']
            if len(sources) != 1:
                raise AssertionError('Expected one named fixture source action')
            bounds = list(map(int, re.findall(r'\d+', sources[0].get('bounds', ''))))
            if len(bounds) != 4:
                raise AssertionError('Food action bounds unavailable')
            center = (bounds[1] + bounds[3]) / 2
            edits = []
            for node in nodes:
                b = list(map(int, re.findall(r'\d+', node.get('bounds', ''))))
                if (self.label(node).strip() == 'Изменить порцию'
                        and node.get('enabled') == 'true' and node.get('clickable') == 'true'
                        and len(b) == 4 and b[0] >= bounds[2]
                        and abs((b[1] + b[3]) / 2 - center) <= 2):
                    edits.append((node, b))
            if len(edits) != 1:
                raise AssertionError('Expected one edit action in the named food row')
            node, b = edits[0]
            if height * .1 <= b[1] < b[3] <= height * .84:
                self.tap_node(node)
                return
            # Move the exact row above the floating Add/bottom navigation, then
            # re-resolve its sibling: never reuse pre-swipe coordinates.
            self.adb('shell', 'input', 'swipe', str(width // 2), str(height * 2 // 3),
                     str(width // 2), str(height // 3), '350')
        raise AssertionError('Named food edit is not uniquely unobscured')

    def check_meal_correction(self):
        self.tap_food_editor('Куриная грудка')
        self.wait_for('Куриная грудка', '100.0', 'Завтрак')
        self.tap('Приём пищи')
        self.tap_exact('Ужин')
        self.tap_exact('Сохранить')
        self.wait_for('Добавить еду', 'Прогресс')
        self.launch()
        self.tap('Питание')
        self.tap_food_editor('Куриная грудка')
        self.wait_for('Куриная грудка', '100.0', 'Ужин')
        self.capture('today-meal-corrected-relaunch')
        # Restore only this fixture's group before the remaining sourced cases.
        self.tap('Приём пищи')
        self.tap_exact('Завтрак')
        self.tap_exact('Сохранить')
        self.wait_for('Добавить еду', 'Прогресс')
        self.launch()
        self.tap('Питание')
        self.tap_food_editor('Куриная грудка')
        self.wait_for('100.0', 'Завтрак')
        self.tap_exact('Отмена')

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
            self.tap_exact("Последние")
            self.wait_for("Яйцо")
            self.capture("today-recent-picker")
            self.tap_exact("Все")
            self.tap("Куриная грудка")
            self.wait_for("Выбрано: Куриная грудка")
            self.select_fixture_breakfast()
            self.tap_exact("Добавить")
            self.launch()
            self.tap("Питание")
            # The same name also appears in the recent-food chip. Verify the
            # persisted diary row, including its portion, below that section.
            self.scroll_to("100 г · 120 ккал")
            self.wait_for("Куриная грудка", "100 г · 120 ккал")
            self.capture("today-action-relaunch")
            self.check_meal_correction()
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
