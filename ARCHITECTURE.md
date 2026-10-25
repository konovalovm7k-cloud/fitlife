# FitLife architecture

## Active application

`lib/main.dart` is the production entry point. `FitLifeAppFrame` owns the single
MaterialApp configuration (theme, Russian locale and delegates). The retained
`ModernFitLifeApp` compatibility root delegates to the same frame.
`lib/modern_app.dart` contains the active five-tab UI, navigation and dialogs.
It reads a `FitLifeState` snapshot and forwards actions to `FitLifeController`;
it does not access preference keys or perform persisted mutations.
Food/diary models live in `lib/core/models/diary_item.dart`,
re-exported by the shell for compatibility. Existing SharedPreferences
keys are retained so installed users keep their diary, foods and favourites.
`lib/app/fitlife_theme.dart` and `lib/app/widgets/` contain the shared theme,
nutrition summary, companion drawing and validated input dialogs.
`lib/data/repositories/diary_preferences.dart` recovers valid records from
partially damaged JSON and preserves the originals under recovery keys.
`lib/app/bootstrap.dart` composes the controller with `LocalFitLifeRepository`.
The `FitLifeRepository` interface uses dates and domain models; its local adapter
owns preference-key mapping and bridges the existing diary, settings and photo
repositories. The controller accepts a repository and clock for deterministic
tests. Snapshots defensively copy their lists and expose read-only views; totals
are computed from the same diary snapshot without intermediate rounding.

Loading has explicit loading/ready/failed states and a finite timeout. Attempt
tokens discard late results after date changes, retry or disposal. A completed
write increments the data revision; an older concurrent load re-reads instead
of replacing confirmed state, including when that old load fails. Each save
keeps its captured target date; completing an old-day save does not overwrite
the currently displayed day. In-flight persistence may finish after disposal,
but cannot publish state or notify disposed listeners. Resume follows midnight
only when the user was viewing today, preserving a selected historical date.
The home screen disposes its own controller and only detaches from a borrowed
controller. Existing preferences-loader injection remains supported through
bootstrap for compatibility; replacing it invalidates the old controller.
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
the same entries and writes additions through a callback to the controller.
It opens as a Navigator route with normal Android back behaviour.

`ValueEditorDialog.onSave` keeps portion, goal, custom food and weight drafts open until
the repository confirms persistence. It disables duplicate submit/cancel and
system back during a save. Failed saves retain editable drafts. Favorites show
the confirmed state and a recoverable error. Recent-food failures report that
the diary meal was saved, without asking the user to submit it again. A failed
portion edit or deletion retains the dialog for retry. Editing a deleted entry
fails explicitly rather than resurrecting it.

`lib/core/models/nutrition_profile.dart` and `lib/core/nutrition/` implement
portion scaling, daily aggregation, source-linked nutrient data, reference
targets and the product catalogue. The calculations have no UI dependencies.
`NutritionGoalSettings` is also the calculator result model (`NutritionGoals`
is a compatibility alias). It owns limits, validation and the 4/9/4 energy
budget. Carbs are the unrounded remaining energy divided by four; there is no
independent minimum or stored carb target. A 1e-8 kcal tolerance accounts for
binary floating-point noise only. UI preview, controller and repository use
the same validation; version 1 storage remains unchanged. Goal display uses
up to two decimals, while calculations and persistence keep full precision.
The retained calculator validates measurements and fails on an incompatible
energy budget instead of silently forcing extra carbohydrate energy. Its
existing calorie/protein/fat allocation policy remains documented in
`P0_NUTRITION_VERIFICATION.md`; automatic personalization is still a P1 task.
Table-sourced food calories are not reconstructed from this target budget.
`lib/pet_engine.dart` contains the independent, tested companion progression
rules.

## Earlier implementation

`lib/app/app.dart` is an earlier interface, currently not used by main.dart.
Its calculator and storage dependencies are retained. `tool/apply_design.py`
only targets that earlier interface and must not run as part of a build.
Invalid saved profile inputs show explicit fallback goals and a correction
message in the earlier profile screen. Its profile dialog validates with the
same calculator and releases controllers after `DialogRoute.completed`, once
the reverse transition has removed the dialog from the overlay.

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
