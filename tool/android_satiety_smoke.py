"""Inspect the local satiety screen after the offline source smoke."""
import argparse
import os
from android_features_smoke import FeaturesSmoke


class SatietySmoke(FeaturesSmoke):
    def run_satiety(self):
        try:
            self.launch()
            self.tap('Питание')
            # The last meal cannot scroll above 70% of a Pixel 7 Pro screen,
            # but its entire button remains above the floating add-food button.
            self.tap_scrolled_exact('Умная сытость · Перекус', max_height=.8)
            self.wait_for('Умная сытость', 'Экспериментальная оценка', 'SmokeLabel')
            self.tap('Нужно жевать', scroll=True)
            self.scroll_to('из 10')
            self.wait_for('из 10', 'Неизвестно: клетчатка, вода в продукте.')
            self.capture('satiety-partial')
            self.scroll_to('Энергоёмкость')
            self.wait_for('Клетчатка: неизвестно', 'Вода в составе: неизвестно')
            self.capture('satiety-factors')
            self.launch()
            self.tap('Питание')
            self.scroll_to('Состав: SmokeLabel')
            self.wait_for('SourceRice', '196 ккал')
            self.capture('satiety-diary-unchanged')
            print('PASS: local satiety navigation, explicit unknown factors and unchanged source meal after cold launch')
        except Exception:
            self.capture('satiety-failure')
            raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--adb', default='adb')
    parser.add_argument('--serial', default=os.environ.get('ANDROID_SERIAL', 'emulator-5554'))
    parser.add_argument('--output', default='build/release-smoke/satiety')
    args = parser.parse_args()
    SatietySmoke(args.adb, args.serial, args.output).run_satiety()


if __name__ == '__main__':
    main()
