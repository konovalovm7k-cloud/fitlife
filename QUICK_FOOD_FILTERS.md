# Quick food filters — 4.6.18+32

Today's add-food sheet previously showed only the complete product list.
Existing recent/favorite shortcuts were reachable through the nutrition tab.
The same sheet now offers All, Recent and Favorites, with the existing search
applied inside the selected list. Recent products retain their stored order;
unknown IDs and duplicate recent IDs do not produce phantom or duplicate rows.
All remains the default. Empty recent/favorite lists explain how to populate
them and leave the All chip accessible.

These are local views of the same existing FoodItem objects and confirmed
favorite state. They do not create new storage keys or migration, alter sources,
fill unknown fiber, change calorie targets, or send network requests. Switching
filters/search preserves the selected product and typed grams; only Add writes
the diary. Failed favorite changes keep the confirmed state and can be retried.

Three widget scenarios cover 320x700 at 1.8 text scale with actual list scrolling,
ordered/deduplicated persisted recents, unknown IDs, normalized search including
е/ё, cancel with no writes, selected draft and precise 150.5 g across filters,
failed diary write and one successful retry with source/unknown fiber intact,
cold-launch recent order, favorite write failure/retry and the empty state.
All three fail before implementation and pass after it.

Local analysis, all 252 Flutter-/43 Python-tests and actionlint pass. Signed APK
4.6.18+32 passes the real applicationId/version/certificate verifier with the
existing release key. SHA256:
79ff72f8a0cf0db723833918a00d04a898e27876bc669258467e4aadab62cdb0.

Android 15 update 4.6.17+31 -> 4.6.18+32, real recent selection, favorite empty
state, search, 150.5 g draft retained across filters, cancel and cold launch all
pass. Every serialized preference entry in four ordinary/encrypted files is
unchanged. No AI calls were made. The existing Today CI case additionally opens
Recent and verifies its persisted egg, then returns to All before its existing
chicken -> diary -> cold-launch save check. All 12 CI scenarios remain required.

The full GitHub CI of this PR is still required before merge. Physical phone
and native iOS are not tested.
