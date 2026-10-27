"""Exercise voluntary hunger observation, cold launch and deletion in release."""
import argparse
import os
from android_features_smoke import FeaturesSmoke


class HungerSmoke(FeaturesSmoke):
    def open_history(self):
        self.launch()
        self.tap('Профиль')
        self.tap_scrolled_exact('Наблюдения голода', max_height=.9)
        self.wait_for('Наблюдения голода')

    def run_hunger(self):
        try:
            # A disposable emulator only; make time entry deterministic while
            # leaving the device date/time and the app's saved data untouched.
            self.adb('shell', 'settings', 'put', 'system', 'time_12_24', '24')
            self.launch()
            self.tap('Питание')
            self.tap_scrolled_exact('Умная сытость · Перекус', max_height=.8)
            self.tap_scrolled_exact('Отметить голод сейчас', max_height=.9)
            self.wait_for('Отметить голод', 'Добровольное наблюдение')
            self.tap('Когда закончили есть?', scroll=True)
            fields = [n for n in self.read_screen() if n.get('class') == 'android.widget.EditText']
            if len(fields) != 2:
                raise AssertionError('Expected hour and minute input fields')
            hour, minute = map(int, self.adb('shell', 'date', '+%H:%M').strip().split(':'))
            # A synthetic recent meal gives readable elapsed-time evidence;
            # near midnight use today's start rather than a future timestamp.
            entered = (max(0, hour - 2), minute if hour >= 2 else 0)
            for index in range(2):
                fields = [n for n in self.read_screen() if n.get('class') == 'android.widget.EditText']
                self.tap_node(fields[index])
                self.adb('shell', 'input', 'keyevent', '123')
                self.adb('shell', 'input', 'keyevent', *(['67'] * 4))
                self.adb('shell', 'input', 'text', f'{entered[index]:02d}')
                if 'mInputShown=true' in self.adb('shell', 'dumpsys', 'input_method'):
                    self.adb('shell', 'input', 'keyevent', '4')
            nodes = self.read_screen()
            ok = next((n for n in nodes if self.label(n).strip() in ('OK', 'ОК', 'Ок')
                       and n.get('clickable') == 'true'), None)
            if ok is None:
                raise AssertionError('No enabled time confirmation button')
            self.tap_node(ok)
            self.tap_scrolled_exact('Умеренный голод', max_height=.9)
            self.tap_scrolled_exact('Нет', max_height=.9)
            self.capture('hunger-draft')
            self.tap_scrolled_exact('Сохранить наблюдение', max_height=.9)
            self.wait_for('Умная сытость')
            self.open_history()
            self.wait_for('Умеренный голод', 'Ели после: Нет', 'SourceRice')
            self.capture('hunger-history-relaunch')
            self.tap_scrolled_exact('Удалить запись', max_height=.9)
            self.wait_for('Удалить наблюдение?')
            self.tap_exact('Удалить')
            self.wait_for('Наблюдений пока нет')
            self.open_history()
            self.wait_for('Наблюдений пока нет')
            self.capture('hunger-deleted-relaunch')
            print('PASS: voluntary hunger rating, timestamp/meal context, native persistence and confirmed deletion survive cold launch')
        except Exception:
            self.capture('hunger-failure')
            raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--adb', default='adb')
    parser.add_argument('--serial', default=os.environ.get('ANDROID_SERIAL', 'emulator-5554'))
    parser.add_argument('--output', default='build/release-smoke/hunger')
    args = parser.parse_args()
    HungerSmoke(args.adb, args.serial, args.output).run_hunger()


if __name__ == '__main__':
    main()
