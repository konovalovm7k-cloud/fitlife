"""Check offline meal idea -> explicit review -> sourced diary after relaunch."""
import argparse
import os
import re
from android_features_smoke import FeaturesSmoke


class MealIdeasSmoke(FeaturesSmoke):
    def preview_review_properties(self):
        self.tap_scrolled_exact('Свойства порции блюда', max_height=.96)
        self.wait_for('Свойства порции блюда')
        self.tap('Нужно жевать', scroll=True)
        self.scroll_to('Ориентир свойств порции')
        width, height = map(int, re.findall(r'(\d+)x(\d+)', self.adb('shell', 'wm', 'size'))[-1])
        for _ in range(12):
            visible = False
            for node in self.read_screen():
                label = self.label(node)
                assert 'Отметить голод сейчас' not in label, 'Uneaten draft offered a hunger observation'
                score = re.search(r'(?<!\d)(\d{1,2})(?:–(\d{1,2}))? из 10', label)
                bounds = list(map(int, re.findall(r'\d+', node.get('bounds', ''))))
                if score and len(bounds) == 4 and height*.1 <= bounds[1] < bounds[3] <= height*.92:
                    assert 1 <= int(score[1]) <= int(score[2] or score[1]) <= 10
                    visible = True
            if visible:
                break
            self.adb('shell', 'input', 'swipe', str(width//2), str(height*2//3), str(width//2), str(height//3), '350')
        else:
            raise AssertionError('No fully visible whole-draft score')
        self.scroll_to('Масса 210.0 г')
        self.wait_for('Масса 210.0 г · 113 ккал')
        self.capture('meal-review-properties')
        self.adb('shell', 'input', 'keyevent', '4')
        self.wait_for('Проверьте блюдо')
        for _ in range(10):
            if any('СОСТАВ ПРОДУКТОВ' in self.label(n) for n in self.read_screen()):
                break
            self.adb('shell', 'input', 'swipe', str(width//2), str(height//3), str(width//2), str(height*3//4), '350')
        self.wait_for('СОСТАВ ПРОДУКТОВ', '113 ккал', 'Клетчатка 3 г')
        self.capture('meal-review-properties-return')

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
            self.preview_review_properties()
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
            print('PASS: offline 210 g / 113 kcal idea, read-only whole-draft properties and return, explicit review, known fibre, exact sources and portions survive cold launch; Profile entry works')
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
