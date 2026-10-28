import unittest
from unittest.mock import Mock, call, patch
import xml.etree.ElementTree as ET
from android_chef_smoke import ChefSmoke


class ChefNavigationTest(unittest.TestCase):
    def smoke(self, enabled='true'):
        smoke = object.__new__(ChefSmoke)
        smoke.launch = Mock()
        smoke.tap_scrolled_exact = Mock()
        smoke.wait_for = Mock(return_value=[ET.Element('node', {
            'class': 'android.widget.EditText', 'resource-id': 'chef-pantry',
            'enabled': enabled, 'text': '', 'content-desc': '',
        })])
        return smoke

    def test_empty_pantry_field_without_accessibility_label_is_ready(self):
        smoke = self.smoke()
        smoke.open_chef()
        self.assertEqual(smoke.wait_for.call_args_list, [
            call('Простые варианты без запроса AI',
                 'AI Chef: подобрать из моих продуктов'),
            call('Что есть под рукой?'),
        ])
        self.assertEqual(smoke.tap_scrolled_exact.call_count, 2)

    def test_disabled_pantry_field_fails_readiness(self):
        with self.assertRaisesRegex(AssertionError, 'not ready'):
            self.smoke('false').open_chef()

    def test_delayed_catalogue_is_waited_for_without_scrolling_past_chef(self):
        # Reproduce the CI failure: a swipe during loading carries the newly
        # loaded list past its top entry; further downward searches cannot find
        # Chef. Exercise the real polling and viewport/tap helpers.
        smoke = object.__new__(ChefSmoke)
        smoke.launch = Mock()
        smoke.dismiss_emulator_launcher_anr = Mock(return_value=False)
        state = {'page': 'today', 'loading_reads': 0, 'past_chef': False}

        def node(text, *, field=False):
            return ET.Element('node', {
                'text': text, 'enabled': 'true', 'clickable': 'true',
                'bounds': '[100,300][900,450]',
                'class': 'android.widget.EditText' if field else 'android.widget.Button',
                'resource-id': 'chef-pantry' if field else '',
            })

        def read_screen():
            if state['page'] == 'today':
                return [node('Открыть идеи блюд')]
            if state['page'] == 'chef':
                return [node('Что есть под рукой?'), node('', field=True)]
            state['loading_reads'] += 1
            if state['past_chef']:
                return [node('Последняя идея в списке')]
            if state['loading_reads'] <= 2:
                return [node('Идеи блюд')]
            return [node('Простые варианты без запроса AI'),
                    node('AI Chef: подобрать из моих продуктов')]

        def adb(*args):
            if args == ('shell', 'wm', 'size'):
                return 'Physical size: 1080x2400'
            if args[:3] == ('shell', 'input', 'swipe'):
                state['past_chef'] = True
                return ''
            self.fail(f'Unexpected adb command: {args}')

        def tap_node(control):
            state['page'] = ('ideas' if control.get('text') == 'Открыть идеи блюд'
                             else 'chef')

        smoke.read_screen = Mock(side_effect=read_screen)
        smoke.adb = Mock(side_effect=adb)
        smoke.tap_node = Mock(side_effect=tap_node)
        with patch('android_release_smoke.time.sleep'):
            smoke.open_chef()
        self.assertFalse(state['past_chef'])
        self.assertEqual(state['page'], 'chef')
        self.assertEqual(smoke.tap_node.call_count, 2)


if __name__ == '__main__':
    unittest.main()
