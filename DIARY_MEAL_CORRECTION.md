# Correct an entry's meal — 4.6.20+34

The existing diary pencil action previously edited grams only. If a person
selected the wrong meal while logging, correcting it required deleting and
re-entering food. The same editor now also selects the meal. Save replaces the
same ID in the same day's existing serialized write queue; date, time, food,
source, unknown fiber and other entries stay unchanged unless grams are edited.
No new keys, migrations, nutrient facts, targets or API calls are introduced.

The optional choice field in ValueEditorDialog is absent from other editors.
During a pending save it is disabled, alongside the existing numeric/back/cancel
guards. Failed writes retain the draft and support retry; cancel writes nothing.
An existing nonstandard meal is retained as an option instead of being silently
renamed. This does not add new custom meal groups to the diary UI.

Two widget scenarios (including 320x700 / text 1.8) cover cancel with every key unchanged, failed-save/retry,
in-place source/ID/date/time/150.5 g preservation, other entries/days/settings,
cold launch, disabled choice/back during a delayed native write and exactly one
completed write. The existing Today native CI case moves its named chicken
fixture Breakfast -> Dinner -> cold launch -> Breakfast, keeping its amount.
Its selector rejects a missing/ambiguous row instead of editing the first other
food. All 12 native scenarios remain required.

Local analysis, all 258 Flutter-/46 Python-tests and actionlint pass. Signed APK
4.6.20+34 passes the actual applicationId/version/existing release-certificate
verifier. SHA256:
d50074fdfb7802e84e9b63a95daec06f3954336b58767f769a930d9de3479be2.

Actual Android 15 update 4.6.19+33 -> 4.6.20+34 preserved every serialized
preference entry. A uniquely named existing sourced entry was opened, its meal
changed and cancelled without a write, then explicitly saved. Only that entry's
meal changed: ID/day/time/grams/food/source and every other entry/key stayed
unchanged. The new meal survived cold launch. Its original meal was restored
through the UI, followed by another cold launch; every serialized entry in four
ordinary/encrypted preference files matched the original. No AI calls were made.

Full CI with all 12 native scenarios is still required before merge. Physical
phone and native iOS are not tested.
