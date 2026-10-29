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
            if identifier == 'catalog-search':
                # This field starts at the top of a newly opened route. Wait
                # for its semantics instead of scrolling the still-opening page
                # and then permanently searching below the input.
                time.sleep(.25)
            else:
                self.adb('shell', 'input', 'swipe', str(width // 2), str(height * 2 // 3),
                         str(width // 2), str(height // 3), '350')
        raise AssertionError(f'No editable source field: {identifier}')

    def catalogue_preview(self, *, code='14-318', name='Банан, мякоть (CoFID)', kcal='122', fiber='2.1'):
        self.launch()
        self.tap('База продуктов')
        self.field('catalog-search', code)
        self.wait_for(name)
        self.tap_scrolled_exact('Добавить в дневник', max_height=.96)
        self.field('value-editor-number-0', '150.5')
        self.wait_for(kcal + ' ккал', 'Клетчатка: ' + fiber + ' г')
        self.tap('Свойства порции')
        self.wait_for(name, 'CoFID 2021 / ' + code)
        self.tap('Нужно жевать', scroll=True)
        self.scroll_to('Ориентир свойств порции')
        self.wait_for('из 10')
        prefix = 'catalogue' if code == '14-318' else 'catalogue-' + code
        self.capture(prefix + '-product-satiety-preview')
        self.adb('shell', 'input', 'keyevent', '4')
        nodes = self.wait_for('Отмена', 'Добавить')
        field = next(n for n in nodes if n.get('resource-id', '').endswith('value-editor-number-0'))
        editable = next((n for n in field.iter('node') if n.get('class') == 'android.widget.EditText'), field)
        if editable.get('text') != '150.5':
            raise AssertionError('Catalogue preview changed the portion draft')
        if 'mInputShown=true' in self.adb('shell', 'dumpsys', 'input_method'):
            raise AssertionError('Catalogue keyboard reopened after preview')
        self.capture(prefix + '-portion-draft-return')
        self.tap_exact('Отмена')
        self.wait_for('База продуктов')
        if 'mInputShown=true' in self.adb('shell', 'dumpsys', 'input_method'):
            raise AssertionError('Catalogue search keyboard reopened after cancel')
        self.adb('shell', 'input', 'keyevent', '4')
        self.wait_for('Добавить еду', 'Прогресс')

    def run_source(self):
        try:
            self.catalogue_preview()
            self.catalogue_preview(code='11-869', name='Рис бурый, цельнозерновой, варёный без соли (CoFID)', kcal='199', fiber='2.3')
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
            self.tap('Оценить свойства порции', scroll=True)
            self.wait_for('Свойства порции')
            self.tap('Нужно жевать', scroll=True)
            self.scroll_to('Ориентир свойств порции')
            self.wait_for('из 10', 'Неизвестно:')
            self.capture('source-product-satiety-preview')
            self.adb('shell', 'input', 'keyevent', '4')
            self.wait_for('Продукт и источник')
            if 'mInputShown=true' in self.adb('shell', 'dumpsys', 'input_method'):
                raise AssertionError('Source keyboard reopened after portion preview')
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
