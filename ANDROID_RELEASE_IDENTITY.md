# Verify the APK before distribution

After the release build and before checksum recording/upload, CI runs
tool/verify_android_release.py against the actual APK. Android apksigner first
verifies the APK signature, then aapt reads the compiled package metadata.
The verifier requires:

- applicationId com.example.fitlife, used by the installed FitLife APK.
- Version name and positive build number matching the committed pubspec.yaml.
- One signer with the existing release certificate SHA256
  190fa5f38b0b27b3c197459b60e34dbaa2964a38682bdb655363e2ca6386b431.
- No application-debuggable flag.

It prints public identity fields and the APK's SHA256. It needs Android
build-tools/Java and reads neither the keystore nor its passwords. Stable
installed build-tools are selected by numeric version on Windows and Linux.
The script can also be run locally with --android-sdk and --pubspec.

Gradle's local development fallback is unchanged. An APK signed with another
key, including an automatic debug-key fallback when CI signing secrets are
unavailable, fails this release gate before upload. No incompatible release
artifact is silently offered as an update. The existing checksum and twelve
native Android cases remain required; no tests or signing settings are removed.

Five unit tests reject changed/missing/multiple signers, another applicationId,
stale version metadata, a debuggable APK, malformed package output and missing
or ambiguous pubspec versions. Prerelease version names remain supported.
Local combined harness: 38 passing tests; actionlint passes.

Actual APK controls on 28 October 2026:

- Local signed 4.6.15+29 passes with SHA256
  813fad7a4c5737c1c99ed3044c51d367d1c283198dd6ffcca99d7c983df8468b.
- APK downloaded from successful CI 40735777980 / artifact 12837107743 passes
  against its main 4.6.14+28 pubspec, with the same release certificate and SHA256
  6e5d1f83771bd6b959c944ead90f03a0c3fba21da112be5adfbdaa32c251e06f.
  Its archive digest and recorded build checksum were verified independently.
- That real 4.6.14 APK is rejected against 4.6.15 pubspec as a negative control.

This patch changes tools/workflow/documentation only; app version, APK sources,
storage and signing configuration do not change. The underlying app's local
245 Flutter tests, signed build and native update/task checks remain applicable.
The new Linux CI gate must pass separately before this patch is integrated.

CI 40744181013 used build-tools 37.0.0 and printed the correct certificate as
"V2 Signer: certificate SHA-256 digest: ...". The previous parser expected
the build-tools 36 "Signer #1" prefix and rejected this valid format. The
parser now checks every certificate record across recognized signature schemes.
Each scheme must still have one signer with the exact existing fingerprint;
wrong keys, extra signers, duplicated roles and unknown certificate roles fail.
Two regressions include the captured SDK 37 line and mixed-scheme negative cases.
The expected certificate and the actual cryptographic verification are unchanged.
