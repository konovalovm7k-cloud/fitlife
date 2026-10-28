"""Check the built APK's identity before distributing an update."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess


APPLICATION_ID = 'com.example.fitlife'
CERTIFICATE_SHA256 = '190fa5f38b0b27b3c197459b60e34dbaa2964a38682bdb655363e2ca6386b431'


def pubspec_version(source):
    versions = re.findall(r'^version:\s*([^\s#]+)\s*(?:#.*)?$', source, re.M)
    if len(versions) != 1:
        raise ValueError('Expected one pubspec version')
    match = re.fullmatch(r'([0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?)\+([1-9][0-9]*)', versions[0])
    if not match:
        raise ValueError('Expected a version name and positive build number')
    return match.group(1), match.group(2)


def verify_identity(badging, certificates, expected_version):
    packages = re.findall(r'^package: (.+)$', badging, re.M)
    if len(packages) != 1:
        raise ValueError('Expected one APK package record')
    package = dict(re.findall(r"([A-Za-z]+)='([^']*)'", packages[0]))
    if package.get('name') != APPLICATION_ID:
        raise ValueError('APK applicationId differs from installed FitLife')
    actual_version = package.get('versionName'), package.get('versionCode')
    if actual_version != expected_version:
        raise ValueError('APK version differs from pubspec')
    if re.search(r'^application-debuggable(?:\s|$)', badging, re.M):
        raise ValueError('APK is debuggable')
    # build-tools 36 reports "Signer #1", while the observed Linux 37 output
    # identifies the signature scheme as "V2 Signer". Check every certificate
    # record, not just the first matching line or a substring containing our key.
    certificate_lines = [line.strip() for line in certificates.splitlines()
                         if 'certificate SHA-256 digest:' in line]
    records = []
    for line in certificate_lines:
        match = re.fullmatch(
            r'(?:(Signer #([0-9]+)) |(V[1-4](?:\.[0-9]+)? Signer(?: #([0-9]+))?): )'
            r'certificate SHA-256 digest: ([0-9a-fA-F:]+)', line)
        if not match or match[2] not in (None, '1') or match[4] not in (None, '1'):
            records = []
            break
        role = 'legacy' if match[1] else match[3].split()[0]
        records.append((role, match[5].replace(':', '').lower()))
    if (not records or len({role for role, _ in records}) != len(records)
            or any(digest != CERTIFICATE_SHA256 for _, digest in records)):
        # These are public certificate fingerprints, never keystore contents or
        # passwords. Preserve evidence if a build-tools format or signer differs.
        reported = [line[:256] for line in certificates.splitlines()
                    if 'certificate' in line.lower() and 'sha-256' in line.lower()]
        raise ValueError('APK certificate differs from the existing release signature; '
                         f'public certificate records: {reported[:8]!r}')
    return {'applicationId': package['name'], 'versionName': actual_version[0],
            'versionCode': int(actual_version[1]), 'certificateSha256': CERTIFICATE_SHA256}


def build_tools(sdk):
    suffixes = ('aapt.exe', 'apksigner.bat') if os.name == 'nt' else ('aapt', 'apksigner')
    root = Path(sdk) / 'build-tools'
    versions = sorted(
        (p for p in root.iterdir() if p.is_dir() and re.fullmatch(r'[0-9]+(?:\.[0-9]+)+', p.name)),
        key=lambda p: tuple(map(int, p.name.split('.'))), reverse=True)
    for version in versions:
        paths = tuple(version / name for name in suffixes)
        if all(path.is_file() for path in paths):
            return paths
    raise ValueError('Android build-tools with aapt and apksigner were not found')


def run_tool(command):
    return subprocess.run([str(part) for part in command], check=True,
                          capture_output=True, encoding='utf-8', errors='replace',
                          timeout=60).stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path)
    parser.add_argument('--pubspec', type=Path, default=Path(__file__).resolve().parents[1] / 'pubspec.yaml')
    parser.add_argument('--android-sdk', default=os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT'))
    args = parser.parse_args()
    tool_version = 'unresolved'
    try:
        if not args.android_sdk:
            raise ValueError('Set ANDROID_HOME or pass --android-sdk')
        aapt, apksigner = build_tools(args.android_sdk)
        tool_version = aapt.parent.name
        # apksigner first verifies the actual APK signature, not just a printed
        # certificate. Neither command needs the keystore or its passwords.
        certificates = run_tool([apksigner, 'verify', '--print-certs', args.apk.resolve()])
        badging = run_tool([aapt, 'dump', 'badging', args.apk.resolve()])
        identity = verify_identity(badging, certificates, pubspec_version(args.pubspec.read_text(encoding='utf-8-sig')))
        with args.apk.open('rb') as source:
            identity['apkSha256'] = hashlib.file_digest(source, 'sha256').hexdigest()
        print(json.dumps(identity, ensure_ascii=False, indent=2))
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        raise SystemExit(f'Android release verification failed [build-tools {tool_version}]: {error}') from None


if __name__ == '__main__':
    main()
