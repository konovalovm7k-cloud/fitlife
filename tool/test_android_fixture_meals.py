import contextlib
import io
import unittest
from unittest.mock import Mock
import xml.etree.ElementTree as ET
from android_release_smoke import ReleaseSmoke
from android_features_smoke import FeaturesSmoke
from android_today_smoke import TodaySmoke


class FixtureMealTest(unittest.TestCase):
    def smoke(self, kind):
        smoke = object.__new__(kind)
        state = {'meal': 'Перекус', 'saved': 0}

        def tap(label, **_):
            if label == 'Выбрать порцию':
                state['meal'] = 'Перекус'
            elif label == 'Завтрак':
                state['meal'] = label
            elif label in ('Добавить', 'Добавить блюдо в дневник'):
                self.assertEqual(state['meal'], 'Завтрак',
                                 'Night-time defaults must not contaminate the sourced snack fixture')
                state['saved'] += 1

        smoke.tap = Mock(side_effect=tap)
        smoke.tap_exact = Mock(side_effect=tap)
        smoke.tap_scrolled_exact = Mock(side_effect=tap)
        smoke.launch = Mock()
        smoke.capture = Mock()
        smoke.wait_for = Mock(return_value=[])
        smoke.scroll_to = Mock(return_value=[])
        smoke.set_number = Mock()
        smoke.read_screen = Mock(return_value=[])
        smoke.check_meal_correction = Mock()
        smoke.preview_saved_portion = Mock()
        return smoke, state

    def test_manual_egg_chooses_fixed_breakfast_from_night_default(self):
        smoke, state = self.smoke(ReleaseSmoke)
        smoke.read_screen.return_value = [ET.Element('node', {'content-desc': '0 ккал\nПустой день'})]
        smoke.ensure_manual_egg()
        self.assertEqual(state['saved'], 1)

    def test_repeated_half_template_chooses_fixed_breakfast_from_night_default(self):
        smoke, state = self.smoke(FeaturesSmoke)
        with contextlib.redirect_stdout(io.StringIO()):
            smoke.run_features()
        self.assertEqual(state['saved'], 1)

    def test_today_chicken_chooses_fixed_breakfast_from_night_default(self):
        smoke, state = self.smoke(TodaySmoke)
        with contextlib.redirect_stdout(io.StringIO()):
            smoke.run_today()
        self.assertEqual(state['saved'], 1)

    def test_midnight_empty_day_seed_and_half_template_both_use_breakfast(self):
        smoke, state = self.smoke(FeaturesSmoke)
        smoke.read_screen.return_value = [ET.Element('node', {'content-desc': '0 ккал\nНовый день'})]
        with contextlib.redirect_stdout(io.StringIO()):
            smoke.run_features()
        self.assertEqual(state['saved'], 2)


if __name__ == '__main__':
    unittest.main()
