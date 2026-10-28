"""Verify Chef's no-connection path and working offline fallback; no AI calls."""
import argparse
import os
from android_source_smoke import SourceSmoke
from android_release_smoke import SAVE_CONNECTION


class ChefSmoke(SourceSmoke):
    def open_chef(self):
        self.launch()
        self.tap_scrolled_exact('Открыть идеи блюд', max_height=.9)
        # The catalogue loads asynchronously. Scrolling while its loading
        # indicator is visible can carry the arriving list past Chef at the top;
        # the downward-only search then runs to the bottom without finding it.
        self.wait_for('Простые варианты без запроса AI',
                      'AI Chef: подобрать из моих продуктов')
        self.tap_scrolled_exact('AI Chef: подобрать из моих продуктов', max_height=.9)
        # Flutter's Android semantics expose the empty pantry EditText by its
        # identifier, but do not expose the visible label as separate text.
        nodes = self.wait_for('Что есть под рукой?')
        if not any(n.get('resource-id', '').endswith('chef-pantry')
                   and n.get('class') == 'android.widget.EditText'
                   and n.get('enabled') == 'true' for n in nodes):
            raise AssertionError('Chef pantry input is not ready')

    def run_chef(self):
        try:
            self.open_chef()
            self.field('chef-pantry', 'ready%srice,%scucumber')
            self.tap_scrolled_exact('Подобрать с AI', max_height=.96)
            self.wait_for('Подключение AI не настроено', 'ready rice, cucumber')
            self.capture('chef-offline-input')
            self.tap_scrolled_exact('Подключение AI', max_height=.96)
            self.wait_for('Подключение к FitLife', SAVE_CONNECTION)
            self.capture('chef-shared-settings')
            self.adb('shell', 'input', 'keyevent', '4')
            self.wait_for('ready rice, cucumber')
            self.tap_scrolled_exact('Вернуться к локальным идеям', max_height=.96)
            self.wait_for('Простые варианты без запроса AI')
            self.tap_exact('½ порции')
            self.wait_for('210 г · 113 ккал')
            self.capture('chef-local-fallback')
            print('PASS: Chef no-connection input retention, shared settings and actual local half-portion fallback; no AI request')
        except Exception:
            self.capture('chef-offline-failure')
            raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--adb', default='adb')
    parser.add_argument('--serial', default=os.environ.get('ANDROID_SERIAL', 'emulator-5554'))
    parser.add_argument('--output', default='build/release-smoke/chef')
    args = parser.parse_args()
    ChefSmoke(args.adb, args.serial, args.output).run_chef()


if __name__ == '__main__':
    main()
