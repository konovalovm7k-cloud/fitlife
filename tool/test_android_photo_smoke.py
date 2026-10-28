import unittest
from android_photo_smoke import public_gallery_ready


class PublicGalleryTest(unittest.TestCase):
    row = 'Row: 0 _id=1000000020, _display_name=apple-fitlife-public.jpg, relative_path=Pictures/FitLifeAcceptance/'

    def test_waits_for_android_indexing(self):
        self.assertFalse(public_gallery_ready('No result found.'))

    def test_accepts_only_the_known_fixture(self):
        self.assertTrue(public_gallery_ready(self.row + '\n'))

    def test_rejects_other_files_without_exposing_their_names(self):
        for output in [self.row.replace('apple-fitlife-public.jpg', 'private-photo.jpg'),
                       self.row.replace('Pictures/FitLifeAcceptance/', 'DCIM/Camera/'),
                       self.row.replace('Pictures/FitLifeAcceptance/', 'Pictures/FitLifeAcceptance/foreign/')]:
            with self.assertRaisesRegex(AssertionError, '^Disposable gallery contains an image outside the public fixture$'):
                public_gallery_ready(output)

    def test_rejects_multiple_images_before_opening_the_picker(self):
        with self.assertRaises(AssertionError):
            public_gallery_ready(self.row + '\n' + self.row.replace('Row: 0', 'Row: 1'))


if __name__ == '__main__':
    unittest.main()
