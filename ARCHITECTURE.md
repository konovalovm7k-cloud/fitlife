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
Diary and hydration keys include the selected date. The catalogue receives
the same entries and writes additions through a callback to the shell.
It opens as a Navigator route with normal Android back behaviour.

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

## Text Meals And Weekly Overview (4.5)

`text_meal_page.dart` sends only the explicitly consented description through
`POST /v1/analyze-text`. It shares photo authentication, quota reservations,
validated per-100g output, editable review and batch persistence. Additive
`textEstimate` metadata distinguishes text estimates without migrating old keys.
No diary, weight or profile is uploaded. A disconnected or offline user can still
use the existing local catalogue and diary.

`PhotoConnectionStore` optionally bootstraps a private build-time connection into
encrypted Android storage. Public builds have no defaults. Explicit disconnect
persists across relaunches; restoration is a separate user action. This is an
extractable personal FitLife invitation, not a way to hide a provider key in APK.
Personal builds and their define files must never be published in Actions/Git.

`lib/features/progress/` reads seven existing local calendar-date diary/water keys.
Missing or damaged food days are excluded from averages and clearly identified.
Historical days are not compared against today's goals. The report is generated
locally and copied only on request. See `JOURNABLE_UX_REVIEW.md` for product scope.

## Save Integrity (4.5.1)

`diary_repository.dart` serializes active-app writes within the Flutter isolate.
Manual additions, catalogue additions and AI batches read the current stored day
before applying an ID-based change; they no longer write a stale screen snapshot.
The queue is not released merely because a UI timeout expires. A late native write
finishes before a retry, whose stable operation ID prevents duplicate entries.

Native write failures (false or exception) propagate; the cache is reloaded after
failure. Damaged originals must be backed up successfully before replacement.
Entry editing/deletion applies to the immutable target day and current stored ID.
Save dialogs retain entered values until confirmation from storage, and water is
incremented from the persisted value rather than an optimistic screen counter.

This remains local SharedPreferences, not a multi-process database or a multi-key
ACID transaction. A meal is embedded in its day even if updating recent products
fails; retrying that same screen repairs the secondary list without duplicating
the meal. Legacy goal keys are written sequentially; an interrupted multi-key save
can be partial and must be retried. No storage format migration is required.
