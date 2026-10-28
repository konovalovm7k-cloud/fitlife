import unittest
from verify_android_release import CERTIFICATE_SHA256, pubspec_version, verify_identity


PACKAGE = "package: name='com.example.fitlife' versionCode='29' versionName='4.6.15' platformBuildVersionCode='36'\nsdkVersion:'24'\n"
CERTIFICATE = f'Signer #1 certificate SHA-256 digest: {CERTIFICATE_SHA256}\n'


class ReleaseIdentityTest(unittest.TestCase):
    def test_build_tools_37_observed_scheme_record_keeps_expected_certificate(self):
        # Exact public line captured by failed CI 40744181013, build-tools 37.
        record = f'V2 Signer: certificate SHA-256 digest: {CERTIFICATE_SHA256}\n'
        self.assertEqual(verify_identity(PACKAGE, record, ('4.6.15', '29'))['certificateSha256'],
                         CERTIFICATE_SHA256)
        same_key_schemes = record + record.replace('V2 Signer', 'V3.1 Signer')
        self.assertEqual(verify_identity(PACKAGE, same_key_schemes, ('4.6.15', '29'))['versionCode'], 29)

    def test_scheme_records_cannot_hide_wrong_keys_unknown_roles_or_extra_signers(self):
        record = f'V2 Signer: certificate SHA-256 digest: {CERTIFICATE_SHA256}\n'
        for invalid in (
                record.replace(CERTIFICATE_SHA256, 'a' * 64),
                record + record.replace('V2 Signer', 'V3 Signer').replace(CERTIFICATE_SHA256, 'a' * 64),
                record + CERTIFICATE.replace('#1', '#2'),
                record + record,
                record + record.replace('V2 Signer', 'Unrecognized Signer'),
                record + record.replace('V2 Signer', 'V2 Signer #2')):
            with self.subTest(record=invalid), self.assertRaises(ValueError):
                verify_identity(PACKAGE, invalid, ('4.6.15', '29'))

    def test_expected_release_identity_is_accepted(self):
        result = verify_identity(PACKAGE, CERTIFICATE, ('4.6.15', '29'))
        self.assertEqual(result['versionCode'], 29)
        self.assertEqual(result['certificateSha256'], CERTIFICATE_SHA256)

    def test_different_app_or_stale_version_is_rejected(self):
        for text in (PACKAGE.replace('com.example.fitlife', 'com.example.demo'),
                     PACKAGE.replace("versionCode='29'", "versionCode='28'"),
                     PACKAGE.replace("versionName='4.6.15'", "versionName='4.6.14'")):
            with self.subTest(text=text), self.assertRaises(ValueError):
                verify_identity(text, CERTIFICATE, ('4.6.15', '29'))

    def test_missing_changed_or_multiple_signers_are_rejected(self):
        for certificate in ('', CERTIFICATE.replace(CERTIFICATE_SHA256, 'a' * 64),
                            CERTIFICATE + CERTIFICATE.replace('#1', '#2')):
            with self.subTest(certificate=certificate), self.assertRaises(ValueError):
                verify_identity(PACKAGE, certificate, ('4.6.15', '29'))

    def test_expected_key_cannot_make_a_debuggable_or_invalid_package_acceptable(self):
        for text in ('', PACKAGE + PACKAGE, PACKAGE + 'application-debuggable\n'):
            with self.subTest(text=text), self.assertRaises(ValueError):
                verify_identity(text, CERTIFICATE, ('4.6.15', '29'))

    def test_pubspec_build_number_is_required_and_prerelease_name_is_preserved(self):
        self.assertEqual(pubspec_version('name: fitlife\nversion: 4.7.0-beta.1+30\n'), ('4.7.0-beta.1', '30'))
        for source in ('name: fitlife', 'version: 4.6.15', 'version: 4.6.15+0',
                       'version: 4.6.15+29\nversion: 4.6.15+30'):
            with self.subTest(source=source), self.assertRaises(ValueError):
                pubspec_version(source)


if __name__ == '__main__':
    unittest.main()
