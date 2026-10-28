"""Opt-in synthetic live Chef acceptance on a disposable emulator, never CI.

Starts with no AI connection and removes the temporary connection in finally.
One user-consented request only; no automatic retries or secret diagnostics.
"""
import argparse
import json
from pathlib import Path
import re
import subprocess
import time
from android_chef_smoke import ChefSmoke
from android_release_smoke import SAVE_CONNECTION, REMOVE_CONNECTION


class LiveChefSmoke(ChefSmoke):
    def secret_input(self, value):
        try:
            result = subprocess.run(self.command + ['shell', 'input', 'text', value],
                                    capture_output=True, timeout=40, check=False)
            if result.returncode:
                raise ValueError()
        except Exception:
            raise AssertionError('Private input failed; command details suppressed') from None

    def hide_keyboard(self):
        if 'mInputShown=true' in self.adb('shell', 'dumpsys', 'input_method'):
            self.adb('shell', 'input', 'keyevent', '4')

    def run_live(self, config_path):
        try:
            config = json.loads(config_path.read_text(encoding='utf-8-sig'))
            address, token = config['FITLIFE_PHOTO_SERVER'].rstrip('/'), config['FITLIFE_PHOTO_TOKEN']
            assert address == 'https://fitlife-photo.konovalov-m7k.workers.dev'
            assert re.fullmatch(r'[A-Za-z0-9_-]{43}', token)
        except Exception:
            raise AssertionError('Invalid private configuration; no request sent') from None
        touched = False
        try:
            self.open_chef()
            self.tap_scrolled_exact('Подключение AI', max_height=.96)
            self.wait_for('Подключение к FitLife', SAVE_CONNECTION)
            fields = [n for n in self.read_screen() if n.get('class') == 'android.widget.EditText']
            if len(fields) != 2 or any(n.get('text') for n in fields):
                raise AssertionError('Live acceptance requires an initially empty connection')
            touched = True
            self.tap_field(0)
            self.secret_input(address)
            self.tap_field(1)
            self.secret_input(token)
            self.hide_keyboard()
            self.tap(SAVE_CONNECTION)
            self.wait_for('Что есть под рукой?')
            self.field('chef-pantry', 'Ready%schicken%s120%sg,%sboiled%sbasmati%srice%s150%sg,%scucumber%s100%sg,%stomato%s150%sg.%sOnly%sthese%sfoods%sand%smasses.')
            self.tap_scrolled_exact('Подобрать с AI', max_height=.96)
            self.wait_for('Отправить список продуктов?')
            self.capture('chef-live-consent')
            self.tap_exact('Отправить')
            deadline = time.monotonic() + 75
            while time.monotonic() < deadline:
                if any('ИДЕЯ AI · ИСТОЧНИКИ СОСТАВА' in self.label(n) for n in self.read_screen()):
                    break
                time.sleep(1)
            else:
                self.capture('chef-live-no-review')
                raise AssertionError('Live Chef did not reach source review; no retry attempted')
            self.capture('chef-live-review')
            self.tap('Приём пищи')
            self.tap_exact('Перекус')
            self.tap('Подтвердить и сохранить', scroll=True)
            self.wait_for('Питание', 'Профиль')
            self.launch()
            self.tap('Питание')
            self.scroll_to('Идея AI · Состав: CoFID 2021 /')
            self.capture('chef-live-diary-relaunch')
            root = Path(__file__).resolve().parents[1]
            foods = json.loads((root / 'assets/data/food_catalog.json').read_text(encoding='utf-8'))
            by_code = {food['food_code']: food for food in foods['foods']}
            verified = []
            for node in self.read_screen():
                text = self.label(node)
                if 'Идея AI · Состав: CoFID 2021 /' not in text:
                    continue
                code = re.search(r'CoFID 2021 / (\d{2}-\d{3})', text)
                mass = re.search(r'(\d+(?:[.,]\d+)?) г · (\d+) ккал', text)
                if code and mass:
                    food = by_code[code[1]]
                    expected = food['kcal'] * float(mass[1].replace(',', '.')) / 100
                    assert abs(expected - int(mass[2])) <= .500001
                    verified.append(code[1])
            assert verified, 'No persisted Chef source/portion/calorie row verified'
            print(f'PASS: one consented live Chef request, source review, explicit diary save and local-source calories after cold launch ({len(set(verified))} visible sources)')
        finally:
            if touched:
                self.open_chef()
                self.tap_scrolled_exact('Подключение AI', max_height=.96)
                self.wait_for('Подключение к FitLife', REMOVE_CONNECTION)
                self.tap(REMOVE_CONNECTION)
                time.sleep(1)
                fields = [n for n in self.read_screen() if n.get('class') == 'android.widget.EditText']
                assert len(fields) == 2 and all(not n.get('text') for n in fields), 'Temporary AI connection was not cleared'
                print('PASS: temporary secure AI connection removed')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--adb', default='adb')
    parser.add_argument('--serial', required=True)
    parser.add_argument('--output', required=True)
    parser.add_argument('--private-config', type=Path, required=True)
    parser.add_argument('--allow-live-request', action='store_true', required=True)
    args = parser.parse_args()
    LiveChefSmoke(args.adb, args.serial, args.output).run_live(args.private_config)


if __name__ == '__main__':
    main()
