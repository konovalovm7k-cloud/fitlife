"""Verify saved meals and dated weight in the already-installed release APK.

Runs after android_release_smoke.py on the same disposable emulator. No network
requests, real invitations, data resets or physical-device access are used.
"""

import argparse
import os
import re
from android_release_smoke import ReleaseSmoke


class FeaturesSmoke(ReleaseSmoke):
    def tap_scrolled_exact(self, label, *, max_height=.7):
        # Flutter may expose a partially visible item under the floating add
        # button. Bring the exact enabled control into the unobscured viewport.
        width, height = map(int, re.findall(
            r"(\d+)x(\d+)", self.adb("shell", "wm", "size"))[-1])
        for _ in range(12):
            for node in self.read_screen():
                if (self.label(node).strip() != label
                        or node.get("enabled") != "true"
                        or node.get("clickable") != "true"):
                    continue
                bounds = list(map(int, re.findall(r"\d+", node.get("bounds", ""))))
                if len(bounds) == 4 and height * .1 <= bounds[1] < bounds[3] <= height * max_height:
                    self.tap_node(node)
                    return
            self.adb("shell", "input", "swipe", str(width // 2), str(height * 2 // 3),
                     str(width // 2), str(height // 3), "350")
        raise AssertionError(f"No unobscured enabled control: {label!r}")

    def preview_saved_portion(self, *, expected_count, available):
        self.tap_scrolled_exact('Свойства порции блюда', max_height=.96)
        self.wait_for('Свойства порции блюда')
        if available:
            self.tap('Нужно жевать', scroll=True)
            self.scroll_to('Ориентир свойств порции')
            self.wait_for('из 10')
            width, height = map(int, re.findall(r'(\d+)x(\d+)', self.adb('shell', 'wm', 'size'))[-1])
            for _ in range(12):
                visible = False
                for node in self.read_screen():
                    score = re.search(r'(?<!\d)(\d{1,2})(?:–(\d{1,2}))? из 10', self.label(node))
                    bounds = list(map(int, re.findall(r'\d+', node.get('bounds', ''))))
                    if score and len(bounds) == 4 and height*.1 <= bounds[1] < bounds[3] <= height*.92:
                        assert 1 <= int(score[1]) <= int(score[2] or score[1]) <= 10
                        visible = True
                if visible:
                    break
                self.adb('shell', 'input', 'swipe', str(width//2), str(height*2//3), str(width//2), str(height//3), '350')
            else:
                raise AssertionError('No fully visible bounded whole-dish score')
        else:
            self.scroll_to('Пока недостаточно подтверждённых данных.')
        self.capture('saved-portion-properties' if available else 'saved-portion-unconfirmed')
        self.adb('shell', 'input', 'keyevent', '4')
        self.wait_for('Порция блюда')
        if 'mInputShown=true' in self.adb('shell', 'dumpsys', 'input_method'):
            raise AssertionError('Portion keyboard reopened after dish preview')
        width, height = map(int, re.findall(r'(\d+)x(\d+)', self.adb('shell', 'wm', 'size'))[-1])
        for _ in range(10):
            target = next((n for n in self.read_screen() if n.get('resource-id', '').endswith('saved-meal-portions')), None)
            if target is not None:
                field = next((n for n in target.iter('node') if n.get('class') == 'android.widget.EditText'), target)
                if field.get('text') != expected_count:
                    raise AssertionError('Dish preview changed the portion draft')
                return
            self.adb('shell', 'input', 'swipe', str(width//2), str(height//3), str(width//2), str(height*3//4), '350')
        raise AssertionError('No saved-meal portion draft after preview return')

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
            # The local upgrade run may cross midnight between the two scripts.
            # Seed only an empty current day, without clearing any saved data.
            nodes = self.read_screen()
            if any(self.label(n).strip().startswith("0 ккал\n") for n in nodes):
                self.tap("Добавить еду")
                self.tap("Яйцо")
                self.wait_for("Выбрано: Яйцо")
                self.select_fixture_breakfast()
                self.tap_exact("Добавить")
            self.wait_for("157 ккал")
            self.tap_scrolled_exact("Сохранить блюдо")
            self.wait_for("157 ккал на порцию", "Изменить ингредиент")
            self.tap_scrolled_exact("Сохранить в мои блюда", max_height=.96)
            # SavedMealEditor returns to the home/FAB only after awaiting save.
            # Do not force-stop the process while its native write is pending.
            self.wait_for("Добавить еду", "Прогресс")
            self.launch()
            self.tap("Питание")
            self.tap("Мои блюда и повтор еды", scroll=True)
            self.wait_for("157 ккал", "Яйцо")
            self.capture("saved-meals-relaunch")
            self.tap("Выбрать порцию", scroll=True)
            self.wait_for("Добавить блюдо в дневник")
            self.tap("0.5×")
            self.wait_for("79 ккал")
            self.preview_saved_portion(expected_count='0.5', available=False)
            self.select_fixture_breakfast()
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
