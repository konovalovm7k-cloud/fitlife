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
now follows this direct route. Analyze, 247 Flutter-/39 Python-tests, actionlint
and a signed release APK passed locally.

Android 15 update 4.6.15 -> 4.6.16 preserved all preference entries in four files.
The real Today action opened the actual first incomplete record and exact grams;
cancel and cold relaunch retained every preference entry. No AI calls were made.
APK SHA256: b21458e69058a87a10352a449c62a4b5e6c05448b06d8d9e87ee48fe2debc034.
The inherited release verifier now supports the observed build-tools 37
scheme-labelled certificate format without changing the expected fingerprint;
the new Linux gate passed in build job 123088150198. A saved-template harness
write-acknowledgement fix from #26 is also included. A separate native check on
the installed APK saved a uniquely named template, waited for the committed
editor return, confirmed it after cold launch, and deleted only that fixture
through the UI. Every serialized preference entry across four files then
matched the original, including encrypted settings and the unchanged diary.
These later changes do not alter app sources or the verified APK. The final full
CI of the latest head remains required before integration.

## Explicit native fixture meals

Run 40766723585 passed release, library, Today and source cases, then correctly
showed insufficient confirmed sources in Satiety. Its captured meal contains
legacy egg/half-egg/chicken plus the sourced rice: after 21:00 the default meal
is snack, so old test records contaminated the fixture that expected only
sourced food. The application correctly refused to produce a score.

Legacy egg, repeated half-template and Today chicken now explicitly select
breakfast; SourceSmoke still selects snack. Empty-day seeding after midnight
uses the same explicit breakfast. Production meal suggestions and Satiety's
source requirements do not change. Four night/midnight harness cases pass
(43 combined tests); the first three failed before the fixture fix. Actual
Android selection at night was verified and cancelled without a food write;
every serialized preference entry in four files stayed unchanged.
The fresh full CI must pass; no failed scenario is skipped or weakened.
