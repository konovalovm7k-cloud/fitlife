"""Correct an existing manually logged meal's nutrition source in release."""
import argparse
import os
import re
from android_source_smoke import SourceSmoke


class DiarySourceSmoke(SourceSmoke):
    def choose_manual_food(self, name):
        # The food picker contains a short nested list. A full-screen swipe
        # flings past rows on CI; move by half of this list's actual viewport.
        width, height = map(int, re.findall(r'(\d+)x(\d+)', self.adb('shell', 'wm', 'size'))[-1])
        for _ in range(40):
            nodes = self.read_screen()
            candidates = []
            for node in nodes:
                bounds = list(map(int, re.findall(r'\d+', node.get('bounds', ''))))
                if (node.get('scrollable') == 'true' and len(bounds) == 4
                        and 100 < bounds[3] - bounds[1] < height * .5
                        and bounds[2] - bounds[0] > width * .5):
                    candidates.append(bounds)
            if not candidates:
                raise AssertionError('No nested food list viewport')
            left, top, right, bottom = min(candidates, key=lambda b: b[3] - b[1])
            for node in nodes:
                if (node.get('clickable') != 'true' or node.get('enabled') != 'true'
                        or self.label(node).strip().split('\n', 1)[0].strip() != name):
                    continue
                bounds = list(map(int, re.findall(r'\d+', node.get('bounds', ''))))
                if len(bounds) == 4 and top <= bounds[1] < bounds[3] <= bottom and bounds[3] - bounds[1] >= 80:
                    self.tap_node(node)
                    return
            extent = bottom - top
            self.adb('shell', 'input', 'swipe', str((left + right) // 2), str(top + extent * 3 // 4),
                     str((left + right) // 2), str(top + extent // 4), '450')
        raise AssertionError(f'No manual food row: {name}')

    def choose_catalogue(self, name):
        width, height = map(int, re.findall(r'(\d+)x(\d+)', self.adb('shell', 'wm', 'size'))[-1])
        for _ in range(10):
            for node in self.read_screen():
                if (node.get('clickable') != 'true' or node.get('enabled') != 'true'
                        or node.get('class') == 'android.widget.EditText'
                        or self.label(node).strip().split('\n', 1)[0].strip() != name):
                    continue
                bounds = list(map(int, re.findall(r'\d+', node.get('bounds', ''))))
                if len(bounds) == 4 and height * .1 <= bounds[1] < bounds[3] <= height * .9:
                    self.tap_node(node)
                    return
            self.adb('shell', 'input', 'swipe', str(width // 2), str(height * 2 // 3),
                     str(width // 2), str(height // 3), '350')
        raise AssertionError(f'No catalogue row: {name}')

    def run_correction(self):
        try:
            self.launch()
            self.tap('Питание')
            self.tap('Добавить еду')
            self.choose_manual_food('Яблоко')
            self.wait_for('Выбрано: Яблоко')
            self.tap_exact('Добавить')
            self.tap_scrolled_exact('Источник состава: Яблоко', max_height=.8)
            self.wait_for('Продукт и источник', 'В дневнике: Яблоко')
            self.field('source-grams', '150.5')
            self.choose_catalogue('Яблоко')
            # Flutter exposes the selected card's SelectableText URL to native
            # accessibility. This uniquely identifies selection, unlike the
            # same product name also present in the search field/result row.
            selected_url = 'https://health-diet.ru/base_of_food/sostav/15983.php'
            self.scroll_to(selected_url)
            self.wait_for(selected_url, '52.0 ккал на 100 г')
            self.capture('diary-source-selection')
            self.tap_scrolled_exact('Подтвердить источник и порцию', max_height=.9)
            self.wait_for('Добавить еду')
            self.launch()
            self.tap('Питание')
            self.scroll_to('150,5 г · 78 ккал')
            self.wait_for('Яблоко', 'Состав: health-diet.ru', '150,5 г · 78 ккал')
            self.capture('diary-source-relaunch')
            self.tap_scrolled_exact('Источник состава: Яблоко', max_height=.8)
            self.scroll_to(selected_url)
            self.wait_for(selected_url, '52.0 ккал на 100 г')
            self.capture('diary-source-restored')
            print('PASS: manual diary entry source correction, 150.5 g / 78 kcal and selected catalogue source survive cold launch')
        except Exception:
            self.capture('diary-source-failure')
            raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--adb', default='adb')
    parser.add_argument('--serial', default=os.environ.get('ANDROID_SERIAL', 'emulator-5554'))
    parser.add_argument('--output', default='build/release-smoke/diary-source')
    args = parser.parse_args()
    DiarySourceSmoke(args.adb, args.serial, args.output).run_correction()


if __name__ == '__main__':
    main()
