# Correct nutrition sources in existing diary entries (4.6.6+20)

An entry's “Источник состава” action opens the existing catalogue/label source
editor. The person confirms the product, cooking state, source and portion.
Legacy AI numbers never prefill label nutrient fields or become a source
automatically. An exact name match still requires explicit selection.

The editor commits through the shared controller/repository queue and replaces
only the existing diary entry. Its ID, date, meal and time are retained; the
original food's local ID is retained while catalogue provenance has its own
record ID/URL. Other entries, global custom foods, templates and old hunger
snapshots are unchanged. Deleted/missing entries cannot be resurrected by a
stale editor. Source confirmation cannot delete an entry; the existing portion
editor retains the separate delete action.

On native write failure, the source, portion and draft stay on screen for
retry. Pending saves block duplicate submission, navigation back and edits.
Only a successful save closes the editor. The callback is optional so camera
review still selects a source first and saves the whole meal in its existing
confirmation step. No server request, migration, dependency or new key is added.

Source entry now accepts 0.1-g and larger portions, matching the existing diary
portion editor. Stored precision remains unchanged; diary mass displays up to
three decimals instead of rounding 0.5 g to 1 g. Calories retain the existing
rounded display while calculations use full source/portion precision. The
offline review heading is “СОСТАВ ПРОДУКТОВ”, since its user may choose either a
catalogue record or a label after entering from the offline label action.

After confirming all ingredients of a meal, its Smart Satiety page can evaluate
the sourced composition. A source correction is never retroactive verification
of the old estimate or a promise of accurate personal satiety.

Tests cover cancellation without mutation, a failed native write and retry,
unchanged IDs/date/time and other meals, cold app restart, the actual satiety
navigation, a 0.5-g portion, pending-write back/submit protection and readable
fractional mass. The release smoke enters food normally, selects a catalogue
source, confirms 150.5 g / 78 kcal and restores that source after cold launch.
These are implementation/persistence checks; catalogue coverage, matching and
food-recognition accuracy still require further evaluation.
