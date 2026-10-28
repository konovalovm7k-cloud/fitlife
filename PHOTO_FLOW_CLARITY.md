# Photo flow: recognition first, source-backed nutrition second

The action is now **Распознать продукты**, replacing **Оценить калорийность**.
The photo page explains that recognition proposes foods/portions and calories
and nutrients are calculated from the selected source. The V2 contract and
Nutrition Engine are unchanged; no model nutrition or new API call is added.

## Repeatable Android acceptance

`tool/android_photo_smoke.py` uses the genuine Android system photo picker,
native image preparation, the unconfigured-connection path and consent refusal.
The selected image survives the settings round-trip and refusal. A fake
example.com connection is cleared in finally. It never accepts the send dialog,
so CI never calls the provider. It runs after the eleven existing scenarios;
none of those are removed. The tested system is an English-language Android 15
disposable emulator with the Russian FitLife UI.

The only fixture is an attributed public apple (tool/fixtures/README.md).
The helper checks its exact SHA256, then waits for MediaStore indexing and
requires the sole indexed image to have the exact fixture name/directory before
opening the picker. Unit tests cover indexing delay, the known fixture and
rejection of other/multiple images, without exposing their names. The test
image and tools are not packaged in the APK.

`tool/android_photo_live.py` is a separate opt-in manual acceptance, requiring
--allow-live-request and a private configuration. It performs at most one send,
checks that saving is disabled before source selection, chooses CoFID apple
14-319 with a user-entered 150.5 g portion, verifies 77 kcal / 2 g fibre, saves
explicitly and checks the diary after cold launch. Temporary connection cleanup
runs in finally. No automated retry or quota increase is provided. Do not add
this live tool to CI.

## Evidence and scope

The full live gallery -> V2 -> confirmed source -> diary case passed on the
signed 4.6.12 APK on 2026-10-28, before the copy update. This was one public image
and an emulator, not physical-camera acceptance or general model accuracy.
The new manual tool reuses that procedure with the current action label;
a fresh live request on 4.6.13 is not claimed. Five successful live requests
were made across that day's previous Chef/photo acceptance; no further live
request is needed for this copy/offline-acceptance change.

For 4.6.13+27: analyze, all 236 Flutter tests, 27 Python tests, actionlint and
signed APK build passed. ApplicationId and certificate are retained.
Local APK SHA256: `9e6ea05601ac9b6440853b9d16212bd5a3cae3829beb8e0c6b99ff70be081277`.
Native Android 15 update from 4.6.12 to 4.6.13 passed without clearing data:
diary, water, fractional goals and encrypted connection behavior survived.
The new offline photo smoke passed the actual system picker, native preparation,
missing-connection path, settings round-trip, declined consent and fixture
connection cleanup. No live request was made for this acceptance.
Final GitHub CI is reported separately in the PR; local native acceptance does
not infer its result.
