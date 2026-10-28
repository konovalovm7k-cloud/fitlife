"""Check offline lessons, actual portion calculation and persistent progress."""
import argparse
import os
import re
from android_features_smoke import FeaturesSmoke


class LearningSmoke(FeaturesSmoke):
    def open_today_step(self, topic, count):
        self.launch()
        nodes = self.scroll_to('Один небольшой шаг')
        # Android merges the card's non-interactive text into one node. Its
        # first line identifies the step; enabled actions remain separate nodes.
        heading = next(n for n in nodes
                       if self.label(n).strip().splitlines()[0:1] == ['Один небольшой шаг'])
        width, height = map(int, re.findall(r'(\d+)x(\d+)', self.adb('shell', 'wm', 'size'))[-1])
        bounds = list(map(int, re.findall(r'\d+', heading.get('bounds', ''))))
        assert len(bounds) == 4, 'Learning step heading has no bounds'
        # Bring a low heading into view before waiting for the asynchronous
        # local marks. A small slow swipe cannot carry this heading past the top.
        if bounds[1] > height * .6:
            self.adb('shell', 'input', 'swipe', str(width // 2), str(height * 3 // 4),
                     str(width // 2), str(height * 11 // 20), '450')
        self.wait_for(topic, f'Понятно: {count} из 3')

    def run_learning(self):
        try:
            self.launch()
            self.tap_scrolled_exact('Открыть короткие уроки', max_height=.9)
            self.wait_for('Короткие уроки', 'Понятно:')
            self.tap('Порция и состав')
            self.tap_scrolled_exact('2 порции', max_height=.9)
            self.scroll_to('454 г · 560 ккал')
            self.wait_for('454 г · 560 ккал', 'Б 30 г · Ж 18 г · У 68 г')
            self.capture('learning-portion')
            nodes = self.scroll_to('отмет')
            if any('Отменить отметку' in self.label(n) for n in nodes):
                self.tap_scrolled_exact('Отменить отметку', max_height=.9)
                self.wait_for('Понятно, отметить')
            self.tap_scrolled_exact('Понятно, отметить', max_height=.9)
            self.wait_for('Отменить отметку')
            self.scroll_to('www.fda.gov')
            self.capture('learning-source')
            self.adb('shell', 'input', 'keyevent', '4')
            self.wait_for('Понятно: 1 из 3')
            self.launch()
            self.tap('Профиль')
            self.tap_scrolled_exact('Короткие уроки', max_height=.9)
            self.wait_for('Понятно: 1 из 3', 'Отмечено как понятное')
            self.capture('learning-progress-relaunch')
            self.tap('Что известно о составе')
            self.tap_scrolled_exact('Открыть дневник', max_height=.9)
            self.wait_for('Добавить еду', 'Питание')
            self.capture('learning-diary-action')
            self.open_today_step('Зачем нужны нутриенты', 1)
            self.tap_scrolled_exact('Открыть задание', max_height=.9)
            self.wait_for('Зачем нужны нутриенты', 'Попробуйте, если удобно')
            self.tap_scrolled_exact('Понятно, отметить', max_height=.9)
            self.wait_for('Отменить отметку')
            self.adb('shell', 'input', 'keyevent', '4')
            self.open_today_step('Что известно о составе', 2)
            self.capture('learning-next-task-relaunch')
            self.tap_scrolled_exact('Открыть короткие уроки', max_height=.9)
            self.wait_for('Понятно: 2 из 3')
            self.tap('Зачем нужны нутриенты')
            self.tap_scrolled_exact('Отменить отметку', max_height=.9)
            self.wait_for('Понятно, отметить')
            self.adb('shell', 'input', 'keyevent', '4')
            self.wait_for('Понятно: 1 из 3')
            self.adb('shell', 'input', 'keyevent', '4')
            self.open_today_step('Зачем нужны нутриенты', 1)
            self.capture('learning-task-undo-relaunch')
            print('PASS: offline FDA portion, persistent progress, lesson-to-diary navigation, direct Today task, next topic after cold launch and undo; no AI request')
        except Exception:
            self.capture('learning-failure')
            raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--adb', default='adb')
    parser.add_argument('--serial', default=os.environ.get('ANDROID_SERIAL', 'emulator-5554'))
    parser.add_argument('--output', default='build/release-smoke/learning')
    args = parser.parse_args()
    LearningSmoke(args.adb, args.serial, args.output).run_learning()


if __name__ == '__main__':
    main()
