# FitLife architecture

## Active application

`lib/main.dart` is the production entry point. It creates a single MaterialApp.
`lib/modern_app.dart` contains the active five-tab application, food and diary
models, camera integration, and persistence orchestration. Existing SharedPreferences
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
CI builds the committed application without generating or rewriting source
files and runs every test, including widget tests.

Run from the repository root:

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter build apk --release --no-pub
```

The application is an offline diary. The camera provides a photo followed by
manual product confirmation. No remote AI recognition or medical document
analysis service is configured in this repository.
