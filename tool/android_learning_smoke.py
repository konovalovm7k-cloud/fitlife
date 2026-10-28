"""Check offline lessons, actual portion calculation and persistent progress."""
import argparse
import os
from android_features_smoke import FeaturesSmoke


class LearningSmoke(FeaturesSmoke):
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
            print('PASS: offline FDA portion example, persistent lesson progress and actual lesson-to-diary navigation')
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
