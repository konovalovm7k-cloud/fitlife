"""Check real system picker, native preparation and declined consent; no AI call."""
import argparse
import hashlib
import os
from pathlib import Path
import time
from android_source_smoke import SourceSmoke
from android_release_smoke import CONNECT, SAVE_CONNECTION, REMOVE_CONNECTION


PUBLIC_PHOTO = Path(__file__).resolve().parent / 'fixtures/apple-public.jpg'
PUBLIC_PHOTO_SHA256 = 'd2d272766c08cffc97784d3c0e6d60f813c9b783af76fd282f17b7f1c5d7ff52'
PHOTO_ACTION = 'Распознать продукты'


def public_gallery_ready(output):
    rows = [line for line in output.splitlines() if line.startswith('Row:')]
    if not rows:
        return False
    fields = dict(part.split('=', 1) for part in rows[0].split(' ', 2)[-1].split(', ') if '=' in part)
    if len(rows) != 1 or fields.get('_display_name') != 'apple-fitlife-public.jpg' or fields.get('relative_path') != 'Pictures/FitLifeAcceptance/':
        raise AssertionError('Disposable gallery contains an image outside the public fixture')
    return True


class PhotoSmoke(SourceSmoke):
    def open_photo(self):
        self.launch()
        self.tap('Камера')
        self.wait_for('Фото блюда')

    def pick_public_photo(self, image_path=PUBLIC_PHOTO):
        assert hashlib.sha256(image_path.read_bytes()).hexdigest() == PUBLIC_PHOTO_SHA256, 'Unknown acceptance image'
        remote = '/sdcard/Pictures/FitLifeAcceptance/apple-fitlife-public.jpg'
        self.adb('shell', 'mkdir', '-p', '/sdcard/Pictures/FitLifeAcceptance')
        self.adb('push', str(image_path), remote)
        self.adb('shell', 'am', 'broadcast', '-a', 'android.intent.action.MEDIA_SCANNER_SCAN_FILE', '-d', 'file://' + remote)
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline:
            indexed = self.adb('shell', 'content', 'query', '--uri', 'content://media/external/images/media', '--projection', '_id:_display_name:relative_path')
            if public_gallery_ready(indexed):
                break
            time.sleep(1)
        else:
            raise AssertionError('Public fixture was not indexed by Android')
        self.open_photo()
        self.tap('Галерея')
        nodes = self.wait_for('This app can only access the photos you select', 'Photo taken on')
        photos = [n for n in nodes if n.get('content-desc', '').startswith('Photo taken on')]
        assert len(photos) == 1, 'Disposable gallery must contain only the public acceptance image'
        self.capture('photo-system-picker')
        self.tap_node(photos[0])
        self.wait_for('Фото готово к анализу', PHOTO_ACTION)
        self.capture('photo-native-prepared')

    def clear_connection(self):
        self.open_photo()
        self.tap_scrolled_exact(CONNECT, max_height=.96)
        self.wait_for('Подключение к FitLife', REMOVE_CONNECTION)
        self.tap(REMOVE_CONNECTION)
        time.sleep(1)
        fields = [n for n in self.read_screen() if n.get('class') == 'android.widget.EditText']
        assert len(fields) == 2 and all(not n.get('text') for n in fields), 'Temporary connection was not cleared'

    def run_photo(self):
        touched = False
        try:
            self.pick_public_photo()
            self.tap_scrolled_exact(PHOTO_ACTION, max_height=.96)
            self.wait_for('Подключите сервер распознавания:', 'Фото готово к анализу')
            self.capture('photo-unconfigured-retained')
            self.tap_scrolled_exact(CONNECT, max_height=.96)
            self.wait_for('Подключение к FitLife', SAVE_CONNECTION)
            fields = [n for n in self.read_screen() if n.get('class') == 'android.widget.EditText']
            assert len(fields) == 2 and all(not n.get('text') for n in fields), 'Requires an initially empty connection'
            touched = True
            self.tap_field(0)
            self.adb('shell', 'input', 'text', 'https://fitlife-smoke.example.com')
            self.tap_field(1)
            self.adb('shell', 'input', 'text', 'a' * 43)
            if 'mInputShown=true' in self.adb('shell', 'dumpsys', 'input_method'):
                self.adb('shell', 'input', 'keyevent', '4')
            self.tap(SAVE_CONNECTION)
            self.wait_for('Фото готово к анализу')
            self.tap_scrolled_exact(PHOTO_ACTION, max_height=.96)
            self.wait_for('Отправить фото на анализ?')
            self.tap_exact('Отмена')
            self.wait_for('Фото готово к анализу', PHOTO_ACTION)
            self.capture('photo-declined-retained')
            assert not any('ПРОДУКТЫ НА ФОТО' in self.label(n) for n in self.read_screen()), 'Decline must not open analysis review'
            print('PASS: genuine system gallery, native photo preparation, missing-connection retention and consent refusal; no AI request')
        except Exception:
            self.capture('photo-offline-failure')
            raise
        finally:
            if touched:
                self.clear_connection()
                print('PASS: temporary offline fixture connection removed')


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--adb', default='adb')
    p.add_argument('--serial', default=os.environ.get('ANDROID_SERIAL', 'emulator-5554'))
    p.add_argument('--output', default='build/release-smoke/photo-offline')
    a = p.parse_args()
    PhotoSmoke(a.adb, a.serial, a.output).run_photo()


if __name__ == '__main__':
    main()
