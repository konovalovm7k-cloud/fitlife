"""Exercise offline source confirmation in the installed production APK."""
import argparse
import os
import re
import time
from android_features_smoke import FeaturesSmoke

class SourceSmoke(FeaturesSmoke):
    def field(self, identifier, value):
        width, height = map(int, re.findall(r'(\d+)x(\d+)', self.adb('shell', 'wm', 'size'))[-1])
        for _ in range(12):
            nodes = self.read_screen()
            target = next((n for n in nodes if n.get('resource-id', '').endswith(identifier)), None)
            if target is not None:
                editable = next((n for n in target.iter('node') if n.get('class') == 'android.widget.EditText'), target)
                bounds = list(map(int, re.findall(r'\d+', editable.get('bounds', ''))))
                if len(bounds) == 4 and height * .1 <= bounds[1] < bounds[3] <= height * .9:
                    self.tap_node(editable)
                    self.adb('shell', 'input', 'keyevent', '123')
                    self.adb('shell', 'input', 'keyevent', *(['67'] * 20))
                    self.adb('shell', 'input', 'text', value)
                    # ESC is ignored by the API 35 numeric IME. Send Back only
                    # while it is shown, so a hardware-keyboard run cannot pop
                    # the source page instead.
                    if 'mInputShown=true' in self.adb('shell', 'dumpsys', 'input_method'):
                        self.adb('shell', 'input', 'keyevent', '4')
                    return
            self.adb('shell', 'input', 'swipe', str(width // 2), str(height * 2 // 3),
                     str(width // 2), str(height // 3), '350')
        raise AssertionError(f'No editable source field: {identifier}')

    def run_source(self):
        try:
            self.launch()
            self.tap('Камера')
            self.tap('Ввести состав с этикетки', scroll=True)
            self.wait_for('Продукт и источник')
            reference = f'SmokeLabel_{time.time_ns():x}'
            for key, value in [('source-grams', '150.5'), ('source-name', 'SourceRice'),
                               ('source-reference', reference), ('source-nutrient-0', '130'),
                               ('source-nutrient-1', '2.7'), ('source-nutrient-2', '0.3'),
                               ('source-nutrient-3', '28')]:
                self.field(key, value)
            self.scroll_to('Запись изменится только после подтверждения.')
            self.wait_for('Для вашей порции', '196 ккал', 'Клетчатка не указана в источнике.')
            self.capture('source-portion-preview-before-confirm')
            self.tap('Подтвердить источник и порцию', scroll=True)
            self.wait_for('СОСТАВ ПРОДУКТОВ', '196 ккал', 'Клетчатка: состав неполный')
            # Keep this fixture separate from the legacy breakfast used by the
            # upgrade harness, independent of the runner's current hour.
            self.tap('Приём пищи')
            self.tap_exact('Перекус')
            self.capture('source-review')
            self.tap('Подтвердить и сохранить', scroll=True)
            self.wait_for('Фото блюда')
            self.launch()
            self.tap('Питание')
            self.scroll_to(f'Состав: {reference}')
            self.wait_for('SourceRice', '196 ккал', 'Клетчатка не указана')
            self.capture('source-diary-relaunch')
            self.launch()
            self.scroll_to('Состав неполный')
            self.capture('source-fiber-today')
            print('PASS: offline label source, 150.5 g portion, calculated 196 kcal and missing fiber survive cold launch')
        except Exception:
            self.capture('source-failure')
            raise

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--adb', default='adb')
    parser.add_argument('--serial', default=os.environ.get('ANDROID_SERIAL', 'emulator-5554'))
    parser.add_argument('--output', default='build/release-smoke/source')
    args = parser.parse_args()
    SourceSmoke(args.adb, args.serial, args.output).run_source()

if __name__ == '__main__':
    main()
