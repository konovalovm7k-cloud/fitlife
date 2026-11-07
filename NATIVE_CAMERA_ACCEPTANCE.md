# Android system-camera acceptance

`tool/android_camera_smoke.py` exercises the installed signed release APK on
the API 35 Google APIs emulator using Android's Camera2 capture activity:

1. Open the actual capture button (not the page heading or navigation tab).
2. Cancel before taking a photo; FitLife must return without a prepared image.
3. Capture a virtual scene, confirm it in Camera2 and return to FitLife's
   prepared-photo preview through the real image_picker/native preparation path.
4. Open the camera again and cancel; the prepared-photo state must remain.
5. Cold-launch FitLife and check navigation is available.

No recognition, consent acceptance, diary save or connection-setting action is
performed. The scene is synthetic, not a food-recognition accuracy fixture.
The test rejects physical-device serials and verifies Android's emulator flag.
Run only with a virtual camera, as explicitly configured in the workflow:
`-camera-back emulated -camera-front none`. Do not select a host webcam.

The existing gallery, consent-refusal and missing-connection scenario remains
unchanged and runs before this test. The Android job timeout is 35 minutes:
the previous complete run took about 28 minutes; the new native capture path
needs additional time. No scenario is skipped to fit the previous timeout.

```sh
python3 tool/android_camera_smoke.py --serial emulator-5554
```

Screenshots/XML and failure diagnostics use `build/release-smoke/camera-native`
and are uploaded by the existing workflow. A missing/unhealthy camera or
unexpected system UI fails the check rather than skipping it. This deliberately
targets the pinned emulator's Camera2 package; OEM-camera support requires
physical-device acceptance. It does not prove hardware image quality, recovery
after Android kills the activity, recognition accuracy or portion mass.

This change adds acceptance coverage only. Application code, version,
applicationId, signing, storage schema, sources and server quotas are unchanged.
