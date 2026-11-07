"""Exercise Android Camera2 capture/cancel in a virtual-camera emulator; no AI."""
import argparse
import os
import re
import time

from android_photo_smoke import PHOTO_ACTION, PhotoSmoke


CAMERA_PACKAGE = 'com.android.camera2'


def enabled_button(node):
    bounds = [int(value) for value in re.findall(r'\d+', node.get('bounds', ''))]
    return (node.get('enabled') == 'true' and node.get('clickable') == 'true'
            and len(bounds) == 4 and bounds[0] < bounds[2] and bounds[1] < bounds[3])


def capture_launcher(nodes):
    # The page title and bottom navigation tab also say "Камера". Only the
    # actual capture button may open the system activity.
    matches = [node for node in nodes
               if node.get('package') == 'com.example.fitlife'
               and node.get('class') == 'android.widget.Button'
               and PhotoSmoke.label(node).strip() == 'Камера'
               and enabled_button(node)]
    if len(matches) > 1:
        raise AssertionError('Ambiguous FitLife camera capture button')
    return matches[0] if matches else None


def camera_control(nodes, identifier):
    matches = [node for node in nodes
               if node.get('package') == CAMERA_PACKAGE
               and node.get('resource-id') == CAMERA_PACKAGE + ':id/' + identifier
               and enabled_button(node)]
    if len(matches) > 1:
        raise AssertionError('Ambiguous system camera control')
    return matches[0] if matches else None


class CameraSmoke(PhotoSmoke):
    def wait_control(self, identifier):
        deadline = time.monotonic() + 35
        while time.monotonic() < deadline:
            target = camera_control(self.read_screen(), identifier)
            if target is not None:
                return target
            time.sleep(.25)
        raise AssertionError('System camera control not ready: ' + identifier)

    def open_system_camera(self):
        nodes = self.wait_for('Фото блюда')
        target = capture_launcher(nodes)
        if target is None:
            raise AssertionError('No enabled FitLife capture button')
        self.tap_node(target)
        return self.wait_control('shutter_button')

    def run_camera(self):
        # ReleaseSmoke already rejects physical-device serials. The workflow
        # additionally pins -camera-back emulated -camera-front none: no webcam.
        if self.adb('shell', 'getprop', 'ro.kernel.qemu').strip() != '1':
            raise AssertionError('Camera acceptance requires an Android emulator')
        try:
            self.open_photo()
            self.open_system_camera()
            self.capture('camera-system-open')
            self.adb('shell', 'input', 'keyevent', '4')
            nodes = self.wait_for('Фото блюда', 'Галерея')
            if any('Фото готово к анализу' in self.label(n) for n in nodes):
                raise AssertionError('Cancelled initial capture unexpectedly supplied a photo')
            self.capture('camera-initial-cancel')

            shutter = self.open_system_camera()
            self.tap_node(shutter)
            done = self.wait_control('done_button')
            self.capture('camera-capture-confirmation')
            self.tap_node(done)
            self.wait_for('Фото готово к анализу', PHOTO_ACTION)
            self.capture('camera-native-prepared')

            self.open_system_camera()
            self.adb('shell', 'input', 'keyevent', '4')
            self.wait_for('Фото готово к анализу', PHOTO_ACTION)
            self.capture('camera-replacement-cancel-retained')
            # No recognition/consent/save action is invoked. The diary and
            # stored server connection are not touched by this scenario.
            self.launch()
            self.wait_for('Добавить еду', 'Прогресс')
            print('PASS: system Camera2 launch, initial cancellation, virtual capture confirmation, native photo preparation and replacement cancellation; no AI request')
        except Exception:
            try:
                self.capture('camera-native-failure')
            except Exception:
                # A dead app process can prevent log collection. Keep the
                # original scenario failure instead of masking it with pidof.
                print('Camera failure diagnostics incomplete; original failure follows')
            raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--adb', default='adb')
    parser.add_argument('--serial', default=os.environ.get('ANDROID_SERIAL', 'emulator-5554'))
    parser.add_argument('--output', default='build/release-smoke/camera-native')
    args = parser.parse_args()
    CameraSmoke(args.adb, args.serial, args.output).run_camera()


if __name__ == '__main__':
    main()
