# Today source shortcut — 4.6.16+30

The missing-fibre guidance now names the first explicitly incomplete diary entry
and opens its existing source editor directly, instead of the general catalogue.
Known entries are skipped. Historical-day and above-goal guidance are unchanged.
The existing explicit confirmation preserves ID, day, meal, time and portion;
opening or cancelling never writes food. Unknown fibre is not converted to zero.
No data format, signing configuration, server or AI requests change.

Two widget cases verify target selection after a known entry, cancellation with
all preferences unchanged, and confirmed source replacement in place with the
other record/keys unchanged and persistence after restart. Large-text coverage
now follows this direct route. Analyze, 247 Flutter-/36 Python-tests, actionlint
and a signed release APK passed locally.

Android 15 update 4.6.15 -> 4.6.16 preserved all preference entries in four files.
The real Today action opened the actual first incomplete record and exact grams;
cancel and cold relaunch retained every preference entry. No AI calls were made.
APK SHA256: b21458e69058a87a10352a449c62a4b5e6c05448b06d8d9e87ee48fe2debc034.
Full CI remains required; inherited PR27 Linux certificate diagnostics are pending.
The expected release certificate is not changed or weakened.
