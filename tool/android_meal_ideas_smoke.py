"""Check offline meal idea -> explicit review -> sourced diary after relaunch."""
import argparse
import os
import re
from android_features_smoke import FeaturesSmoke


class MealIdeasSmoke(FeaturesSmoke):
    def tap_first_idea(self):
        width, height = map(int, re.findall(r'(\d+)x(\d+)', self.adb('shell', 'wm', 'size'))[-1])
        for _ in range(12):
            for node in self.read_screen():
                if not node.get('resource-id', '').endswith('idea-review-cottage_vegetables_v1'):
                    continue
                bounds = list(map(int, re.findall(r'\d+', node.get('bounds', ''))))
                if (node.get('enabled') == 'true' and len(bounds) == 4
                        and height * .1 <= bounds[1] < bounds[3] <= height * .9):
                    self.tap_node(node)
                    return
            self.adb('shell', 'input', 'swipe', str(width // 2), str(height * 2 // 3),
                     str(width // 2), str(height // 3), '350')
        raise AssertionError('No fully visible first meal idea review button')

    def run_ideas(self):
        try:
            self.launch()
            self.tap_scrolled_exact('Открыть идеи блюд', max_height=.9)
            self.wait_for('Простые варианты без запроса AI')
            self.tap_exact('½ порции')
            self.wait_for('210 г · 113 ккал')
            self.capture('meal-ideas-half')
            self.tap_first_idea()
            self.wait_for('СОСТАВ ПРОДУКТОВ', '113 ккал', 'Клетчатка 3 г')
            self.capture('meal-ideas-review')
            self.tap('Приём пищи')
            self.tap_exact('Перекус')
            self.tap('Подтвердить и сохранить', scroll=True)
            self.wait_for('Питание', 'Профиль')
            self.launch()
            self.tap('Питание')
            self.scroll_to('CoFID 2021 / 12-550')
            self.wait_for('60 г · 41 ккал', 'Зернёный творог')
            self.capture('meal-ideas-cottage-relaunch')
            self.scroll_to('CoFID 2021 / 11-981')
            self.wait_for('25 г · 54 ккал', 'Хлеб цельнозерновой')
            self.capture('meal-ideas-bread-relaunch')
            self.launch()
            self.tap('Профиль')
            self.tap_scrolled_exact('Идеи блюд', max_height=.96)
            self.wait_for('Простые варианты без запроса AI')
            self.capture('meal-ideas-profile')
            print('PASS: offline 210 g / 113 kcal idea, explicit review, known fibre, exact sources and portions survive cold launch; Profile entry works')
        except Exception:
            self.capture('meal-ideas-failure')
            raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--adb', default='adb')
    parser.add_argument('--serial', default=os.environ.get('ANDROID_SERIAL', 'emulator-5554'))
    parser.add_argument('--output', default='build/release-smoke/meal-ideas')
    args = parser.parse_args()
    MealIdeasSmoke(args.adb, args.serial, args.output).run_ideas()


if __name__ == '__main__':
    main()
