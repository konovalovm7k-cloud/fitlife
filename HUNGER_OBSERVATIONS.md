# Voluntary hunger observations (4.6.5+19)

Open a diary meal's Smart Satiety page, then choose “Отметить голод сейчас”.
This works even when the meal lacks enough confirmed sources for a satiety
score. No observation is created automatically. Skipping or navigating away
before saving writes nothing. There are no reminders, background timers,
notifications, streaks, rewards, hunger targets or AI/server requests.

## Recorded context

The person explicitly confirms the time they finished eating on the selected
diary date, chooses one of five subjective hunger descriptions (no default),
and states whether they ate afterwards (yes/no/unknown). The observation time
is captured when the rating is chosen. A failed write and retry retain that
time and the stable record ID. Times persist as canonical UTC ISO strings;
display uses the device's local timezone. Future observations and meal times
at/after the observation are rejected. The displayed elapsed minutes describe
the entered timestamps, never a prediction of future hunger or hours of satiety.

Each record snapshots the meal's items, gram portions, nutrition provenance,
unknown fiber and chosen structure, if any. Later diary edits do not rewrite
that snapshot. Unconfirmed legacy nutrition is retained as unconfirmed, never
promoted to evidence. The information is subjective, may be recalled late or
inaccurately, and can be affected by later meals, sleep, activity and other
unrecorded context. An association cannot establish that this meal caused the
reported hunger. No personal coefficients or prediction hours are inferred.

## Storage and deletion

`hunger_observations_v1` is a new local SharedPreferences key. Existing diary,
settings, application ID, signing and encrypted connection storage are unchanged.
All read/modify/write operations use the existing shared `PreferencesQueue`
through `DiaryRepository.run`; stable IDs replace their own retry/edit only.
Native false/throw write results surface in the UI and retain the draft.

The history permits correction and confirmed deletion of one or all records.
It is also reachable from Profile with an empty diary, including after deleting
the original meal; observations never become inaccessible through diary edits.
Corrections preserve the original observation timestamp; delete/recreate if a
different observation moment is needed. Normal deletion affects only hunger
observations, not meals. The app does not create hidden recovery copies of
these private observations. If the stored list or a record is malformed,
loading and normal writes fail while preserving the original bytes. The
history offers retry or an explicit confirmed clear-all; only that action can
discard malformed observations. This policy avoids silently dropping records
or retaining deleted observations in automatic recovery keys. It does not
promise physical secure erasure or control operating-system/device backups.

The app does not send observations to AI or the food-recognition Worker. No new
permissions, provider, server, dependency, quota or migration are required.

## Verification

Storage tests exercise concurrent repository instances, native write failure,
stable retry/edit IDs, context snapshots, unknown fiber, UTC/elapsed time,
future/reversed/normalized dates, corruption preservation and explicit clearing.
Widget tests exercise voluntary cancellation, no default rating, real time
entry, failure/retry with a frozen observation time, editing and confirmed
deletion. The diary navigation test reaches the actual observation form.
`tool/android_hunger_smoke.py` covers the signed APK's native save, cold launch
and deletion on a disposable emulator using synthetic meal/rating data.

These checks verify implementation and persistence. They do not validate
subjective hunger as a clinical measure or the experimental satiety formula.
