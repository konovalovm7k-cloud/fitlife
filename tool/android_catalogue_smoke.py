"""Verify a bundled CoFID food, precise portion and native source persistence."""
import argparse
import os
from android_diary_source_smoke import DiarySourceSmoke


class CatalogueSmoke(DiarySourceSmoke):
    def run_catalogue(self):
        try:
            name = 'Банан, мякоть (CoFID)'
            reference = 'CoFID 2021 / 14-318 / Bananas, flesh only'
            source_url = 'https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid'
            self.launch()
            self.tap('Камера')
            self.tap('Ввести состав с этикетки', scroll=True)
            self.field('source-grams', '150.5')
            self.tap('Из каталога')
            self.choose_catalogue(name)
            # The final button is fully above Android's navigation area, but
            # below 90% when the enlarged catalogue reaches its scroll extent.
            self.tap_scrolled_exact('Подтвердить источник и порцию', max_height=.96)
            # The SelectableText URL is exposed by native accessibility;
            # Flutter omits adjacent card text. Check the exact reference in
            # the persisted diary below, not by relying on omitted semantics.
            self.wait_for('СОСТАВ ПРОДУКТОВ', '122 ккал', 'Клетчатка 2 г', source_url)
            self.capture('catalogue-review')
            self.tap('Приём пищи')
            self.tap_exact('Перекус')
            self.tap('Подтвердить и сохранить', scroll=True)
            self.wait_for('Фото блюда')
            self.launch()
            self.tap('Питание')
            self.scroll_to(f'Состав: {reference}')
            self.wait_for(name, '150,5 г · 122 ккал', 'Кл 2 г')
            self.capture('catalogue-diary-relaunch')
            self.tap_scrolled_exact(f'Источник состава: {name}', max_height=.8)
            self.scroll_to(source_url)
            self.wait_for(source_url, '81.0 ккал на 100 г')
            self.capture('catalogue-source-restored')
            print('PASS: offline CoFID banana, 150.5 g / 122 kcal, known fibre and exact source survive cold launch')
        except Exception:
            self.capture('catalogue-failure')
            raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--adb', default='adb')
    parser.add_argument('--serial', default=os.environ.get('ANDROID_SERIAL', 'emulator-5554'))
    parser.add_argument('--output', default='build/release-smoke/catalogue')
    args = parser.parse_args()
    CatalogueSmoke(args.adb, args.serial, args.output).run_catalogue()


if __name__ == '__main__':
    main()
