import unittest
from unittest.mock import Mock
import xml.etree.ElementTree as ET

from android_camera_smoke import CameraSmoke, capture_launcher, camera_control


def node(**attributes):
    return ET.Element('node', {
        'package': 'com.example.fitlife', 'class': 'android.widget.Button',
        'text': '', 'content-desc': 'Камера', 'clickable': 'true',
        'enabled': 'true', 'bounds': '[285,1439][700,1614]', **attributes,
    })


class CameraSelectorTest(unittest.TestCase):
    def test_diagnostic_failure_does_not_hide_original_scenario_failure(self):
        smoke = object.__new__(CameraSmoke)
        smoke.adb = Mock(return_value='1')
        smoke.open_photo = Mock(side_effect=AssertionError('original scenario failed'))
        smoke.capture = Mock(side_effect=RuntimeError('pid unavailable'))
        with self.assertRaisesRegex(AssertionError, '^original scenario failed$'):
            smoke.run_camera()

    def test_capture_does_not_tap_same_named_heading_or_navigation_tab(self):
        heading = node(**{'class': 'android.view.View', 'clickable': 'false'})
        tab = node(**{'content-desc': 'Камера\nВкладка\xa03 из\xa05'})
        capture = node()
        self.assertIs(capture_launcher([heading, tab, capture]), capture)
        self.assertIsNone(capture_launcher([heading, tab]))

    def test_disabled_empty_bounds_or_foreign_buttons_are_not_tapped(self):
        for attributes in ({'enabled': 'false'}, {'bounds': '[0,0][0,0]'},
                           {'package': 'other.app'}, {'clickable': 'false'}):
            with self.subTest(attributes=attributes):
                self.assertIsNone(capture_launcher([node(**attributes)]))

    def test_ambiguous_capture_is_an_error(self):
        with self.assertRaisesRegex(AssertionError, 'Ambiguous'):
            capture_launcher([node(), node()])

    def test_system_control_requires_camera_package_id_and_readiness(self):
        done = node(**{'package': 'com.android.camera2',
                       'resource-id': 'com.android.camera2:id/done_button',
                       'content-desc': 'Done'})
        unrelated = node(**{'content-desc': 'Done'})
        self.assertIs(camera_control([unrelated, done], 'done_button'), done)
        self.assertIsNone(camera_control([unrelated], 'done_button'))
        self.assertIsNone(camera_control([done], 'shutter_button'))
        done.set('enabled', 'false')
        self.assertIsNone(camera_control([done], 'done_button'))


if __name__ == '__main__':
    unittest.main()
