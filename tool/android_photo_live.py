"""Opt-in public gallery -> live V2 -> sourced save. Never run by CI."""
import argparse
import json
from pathlib import Path
import re
import time
from android_chef_live import LiveChefSmoke
from android_diary_source_smoke import DiarySourceSmoke
from android_photo_smoke import PhotoSmoke, PHOTO_ACTION, PUBLIC_PHOTO
from android_release_smoke import CONNECT, SAVE_CONNECTION


class PhotoLiveSmoke(PhotoSmoke, DiarySourceSmoke):
    secret_input = LiveChefSmoke.secret_input
    hide_keyboard = LiveChefSmoke.hide_keyboard

    def choose_review_source(self):
        width, height = map(int, re.findall(r'(\d+)x(\d+)', self.adb('shell', 'wm', 'size'))[-1])
        for _ in range(8):
            for node in self.read_screen():
                bounds = list(map(int, re.findall(r'\d+', node.get('bounds', ''))))
                if (self.label(node).strip() == 'Выбрать источник'
                        and node.get('clickable') == 'true' and node.get('enabled') == 'true'
                        and len(bounds) == 4 and height * .1 <= bounds[1] < bounds[3] <= height * .9):
                    self.tap_node(node)
                    return
            self.adb('shell', 'input', 'swipe', str(width // 2), str(height // 3), str(width // 2), str(height * 3 // 4), '350')
        raise AssertionError('No visible source action in photo review')

    def run_live(self, image_path, config_path):
        try:
            config = json.loads(config_path.read_text(encoding='utf-8-sig'))
            address, token = config['FITLIFE_PHOTO_SERVER'].rstrip('/'), config['FITLIFE_PHOTO_TOKEN']
            assert address == 'https://fitlife-photo.konovalov-m7k.workers.dev'
            assert re.fullmatch(r'[A-Za-z0-9_-]{43}', token)
        except Exception:
            raise AssertionError('Invalid private config; no request sent') from None
        touched = False
        try:
            self.pick_public_photo(image_path)
            self.tap_scrolled_exact(CONNECT, max_height=.96)
            self.wait_for('Подключение к FitLife', SAVE_CONNECTION)
            fields = [n for n in self.read_screen() if n.get('class') == 'android.widget.EditText']
            assert len(fields) == 2 and all(not n.get('text') for n in fields), 'Requires an initially empty connection'
            touched = True
            self.tap_field(0)
            self.secret_input(address)
            self.tap_field(1)
            self.secret_input(token)
            self.hide_keyboard()
            self.tap(SAVE_CONNECTION)
            self.wait_for('Фото готово к анализу')
            self.tap_scrolled_exact(PHOTO_ACTION, max_height=.96)
            self.wait_for('Отправить фото на анализ?')
            self.capture('photo-live-consent')
            self.tap_exact('Отправить')
            deadline = time.monotonic() + 75
            while time.monotonic() < deadline:
                if any('ПРОДУКТЫ НА ФОТО' in self.label(n) for n in self.read_screen()):
                    break
                time.sleep(1)
            else:
                self.capture('photo-live-no-review')
                raise AssertionError('Photo did not reach review; no second request attempted')
            self.wait_for('Нужен источник состава')
            assert any('яблок' in self.label(n).lower() for n in self.read_screen()), 'Public apple was not identified'
            self.capture('photo-source-required')
            buttons = self.scroll_to('Подтвердить и сохранить')
            save = [n for n in buttons if self.label(n).strip() == 'Подтвердить и сохранить']
            assert len(save) == 1 and save[0].get('enabled') == 'false', 'Unsourced photo must not save'
            self.choose_review_source()
            self.wait_for('Продукт и источник')
            self.field('source-grams', '150.5')
            node = next(n for n in self.read_screen() if n.get('resource-id', '') == 'source-search')
            self.tap_node(node)
            self.adb('shell', 'input', 'keyevent', '123')
            self.adb('shell', 'input', 'keyevent', *(['67'] * 100))
            self.adb('shell', 'input', 'text', '14-319')
            self.hide_keyboard()
            self.choose_catalogue('Яблоко с кожурой, сырое (CoFID)')
            self.tap_scrolled_exact('Подтвердить источник и порцию', max_height=.96)
            self.wait_for('ПРОДУКТЫ НА ФОТО', '77 ккал', 'Клетчатка 2 г')
            self.capture('photo-sourced-review')
            self.tap('Приём пищи')
            self.tap_exact('Перекус')
            self.tap('Подтвердить и сохранить', scroll=True)
            self.wait_for('Фото блюда')
            self.launch()
            self.tap('Питание')
            self.scroll_to('CoFID 2021 / 14-319')
            self.wait_for('150,5 г · 77 ккал', 'Яблоко с кожурой, сырое (CoFID)')
            self.capture('photo-sourced-diary-relaunch')
            print('PASS: real system gallery, one consented V2 request, unsourced save disabled, user-selected source and 150.5 g / 77 kcal persist after cold launch')
        finally:
            if touched:
                self.clear_connection()
                print('PASS: temporary photo connection removed')


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--adb', default='adb')
    p.add_argument('--serial', required=True)
    p.add_argument('--output', default='build/release-smoke/photo-live')
    p.add_argument('--image', type=Path, default=PUBLIC_PHOTO)
    p.add_argument('--private-config', type=Path, required=True)
    p.add_argument('--allow-live-request', action='store_true', required=True)
    a = p.parse_args()
    PhotoLiveSmoke(a.adb, a.serial, a.output).run_live(a.image, a.private_config)


if __name__ == '__main__':
    main()
