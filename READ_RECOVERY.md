# Read recovery and committed edits — 4.6.14+28

The retry callbacks on weight history, saved meals and weekly summary returned
their newly assigned Future from `setState`. Flutter requires a synchronous
callback with no Future result. A committed weight edit used the same pattern;
saved-meal deletion called that reload inside its error handler. In debug/widget
execution this can reject an already committed action, leave the dialog open or
report a false deletion failure. This is a reproduced framework-contract bug,
not an observed release crash: the Flutter assertion is disabled in release.

Use synchronous void blocks for state changes. Start each read with
`Future.sync`, attach an early error observer, and still give the original
Future to `FutureBuilder`. This handles immediate read errors before the next
build without converting failures into success or empty data. Weight/library
reads retain their existing 15-second timeout. The repository queue, write
semantics, recovery backups and stored formats are unchanged. Retrying only
reads data; no automatic write or provider request is introduced.

Five widget regressions cover:

- Weight and saved-meal reads failing twice, then recovering on the third
  attempt, with the retry button retained after the second failure and the
  original stored value unchanged.
- Weekly reads with the same repeated-failure recovery and unchanged diary;
  missing days remain explicitly different from zero intake.
- A committed weight edit from 83.5 to exactly 82.75, displayed as 82.8:
  one repository save, closed dialog and updated visible history.
- A committed template deletion: one deletion, refreshed library, no false
  failure and unchanged diary entries.

The three read retries and committed weight edit were observed failing on the
previous implementation before applying the fix. After the fix the full local
suite passes: 241 Flutter tests, 28 Python harness tests, clean analysis and
actionlint. Signing and application ID remain unchanged.

Native release acceptance passed on the existing Android 15 AVD without a data
reset or AI call: upgrade 4.6.13 -> 4.6.14 retained all 19 entries across four
regular/encrypted preference files. Editing an existing measurement stored
exactly 82.75 (displayed 82.8), closed the dialog and survived a cold launch.
The original 83.5 fixture was restored through the UI; the regular preferences
then exactly matched their pre-edit contents, including the diary. Weekly view
through Progress and the saved-meal library loaded without changing those data.
Read failures are injected in widget tests, not on the native emulator.
The local APK is built from these app sources; later harness merges do not
change lib/assets/android/pubspec files. Final GitHub CI remains a separate gate.
The final rebuild after the harness merge produced the same APK SHA256.

APK SHA256: c64cab537d5a20086742eff5390644d146ddca73698143fb16c2a96e9dfddf46.
Certificate SHA256: 190fa5f38b0b27b3c197459b60e34dbaa2964a38682bdb655363e2ca6386b431.

The original Codex checkout and its 75-file snapshot remain preserved. There
are no data migrations, dependency updates or new server/API costs in this patch.
