# FitLife architecture

## Active application

`lib/main.dart` is the production entry point. It creates a single MaterialApp.
`lib/modern_app.dart` contains the active five-tab application and persistence
orchestration. Food/diary models now live in `lib/core/models/diary_item.dart`,
re-exported by the shell for compatibility. Existing SharedPreferences
keys are retained so installed users keep their diary, foods and favourites.
`lib/app/fitlife_theme.dart` and `lib/app/widgets/` contain the shared theme,
nutrition summary, companion drawing and validated input dialogs.
`lib/data/repositories/diary_preferences.dart` recovers valid records from
partially damaged JSON and preserves the originals under recovery keys.
`preferences_queue.dart` orders all diary and settings read/modify/write
operations in the app isolate, reloads preferences at entry and after failure,
and rejects native writes returning false. `settings_repository.dart` owns
startup migration, favorites, recent foods, custom foods, water and weight.
Related nutrition goals use a single versioned `nutrition_goals_v1` snapshot;
legacy goal keys are migrated once and retained unchanged. Snapshot reads take
precedence thereafter. Damaged snapshots are backed up before using defaults;
each distinct damaged source gets a separate recovery key. Legacy non-finite
numbers are preserved as explicit diagnostic values in JSON recovery data.
Water migration writes today's value before its completion marker and is safe
to retry if either write fails. It never moves an undated legacy value to a
historical selected date. This queue is not a database transaction across
multiple keys or processes and does not provide power-loss guarantees.
Diary and hydration keys include the selected date. The catalogue receives
the same entries and writes additions through a callback to the shell.
It opens as a Navigator route with normal Android back behaviour.

`ValueEditorDialog.onSave` keeps goal, custom food and weight drafts open until
the repository confirms persistence. It disables duplicate submit/cancel and
system back during a save. Failed saves retain editable drafts. Favorites show
the confirmed state and a recoverable error. Recent-food failures report that
the diary meal was saved, without asking the user to submit it again.

`lib/core/models/nutrition_profile.dart` and `lib/core/nutrition/` implement
portion scaling, daily aggregation, source-linked nutrient data, reference
targets and the product catalogue. The calculations have no UI dependencies.
`lib/pet_engine.dart` contains the independent, tested companion progression
rules.

## Earlier implementation

`lib/app/app.dart` is an earlier interface, currently not used by main.dart.
Its calculator and storage dependencies are retained. `tool/apply_design.py`
only targets that earlier interface and must not run as part of a build.

## Build contract

Flutter is pinned to 3.44.7, Dart to the SDK bundled with that release, and
Android uses Java 17. Android project files and pubspec.lock belong in Git.
CI uses Ubuntu 24.04 and Node 24-compatible GitHub actions with pinned release
versions. It builds the committed application without generating or rewriting source
files and runs every test, including widget tests.

Run from the repository root:

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter build apk --release --no-pub
```

## Photo Analysis

`lib/features/photo_analysis/` contains image preparation (resize, orientation,
EXIF removal in an isolate), the HTTPS client, encrypted connection settings,
the camera page, and editable review. Network/storage waits have finite timeouts.
No network request occurs without a user action and upload consent. The diary
stays offline; only the selected photo goes to the configured server.

`photo_diary.dart` persists a confirmed batch in a single existing diary key,
with stable IDs, an immutable target date, and an estimate marker. Retrying
replaces that batch, preserving unrelated entries and applying later edits.
Photo-derived foods are embedded in entries, not silently added to the catalogue.

`server/src/entry.mjs` is the Cloudflare Worker entry point; `worker.mjs` handles
authenticated uploads, strict input/output validation and Gemini structured output.
`server/migrations/` defines D1 users and request reservations. A single conditional
SQL INSERT enforces per-user and global quotas across concurrent isolates. User
tokens are random 256-bit values; D1 stores their hashes. Gemini credentials are
Worker Secrets. No photos/results are persisted or logged. Reservations expire
after 30 days via scheduled cleanup. Read replication is not enabled.

The server is intended for an invited small group. Runtime tests use real
workerd/D1 with a mock provider; real Gemini activation requires the owner's
accounts, key and HTTPS deployment. See `server/SETUP_RU.md`.
