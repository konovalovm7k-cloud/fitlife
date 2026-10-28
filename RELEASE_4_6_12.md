# FitLife 4.6.12+26: integration release

Prepared on 2026-10-28 from the verified application commit
`627c591d56672c1a3c6c959effc4888c57fd43cc`. The release branch changes only
documentation beyond that commit. It preserves all 55 commits ahead of the
previous main `2e0e2104a856863d5bbfe02bd7c2f5d94fe7c119`, including the heads
of PRs #2–#21. The original PR branches are retained. Integration into main
and the subsequent main build are separate checks recorded in the release PR.

## Included work

- #7 reconciles #2–#6: migrations, serialized preferences/diary writes,
  recovery copies, stable operation IDs, shared controller/settings and exact
  nutrition goals alongside photo/text/weekly flows. The old #3 conflict was
  resolved here; do not reapply its earlier conflict resolution over this tree.
- #8 preserves the original local Codex 4.6 saved meals, repeat entry, portion
  scaling, weight history, import pipeline and iOS sources. The source checkout
  was not reset. A fresh check found the same original HEAD and all 75 changed
  or untracked files matching the saved snapshot, with no new unaccounted paths.
- #9 provides Today, real measured data, next actions and supportive pet states.
- #10–#11/#14 require sourced nutrition and explicit confirmation; existing
  diary sources can be corrected without replacing entry IDs/dates/times.
- #12–#13 provide an explicitly experimental local whole-meal satiety score
  and voluntary hunger observations, with editing/deletion. No precise hours,
  starvation rewards or pet punishment are added.
- #15 adds three local nutrient/portion/source lessons and persistent progress.
- #16–#18 add 20 CoFID foods (28 attributed records total), faster source
  confirmation and three offline meal ideas with editable portions/sources.
- #19–#20 add opt-in Chef assembly suggestions. The model supplies only curated
  IDs/masses; Nutrition Engine resolves facts locally and the person confirms
  the diary save. Existing Cloudflare/D1 connection and limits are reused.
- #21 unifies local source search and provides a no-match catalogue escape.

## Evidence before main integration

Application PR #21: CI `40686408943` passed analyze, all 236 Flutter tests,
23 Python harness tests, APK build, 33 backend tests and all eleven native
Android acceptance scenarios. Earlier PRs #7–#20 also passed their final CI.
The optional native iOS job was intentionally skipped; it is not verified.

The independent local signed APK has:

| Property | Verified value |
| --- | --- |
| Application ID | `com.example.fitlife` |
| Version | `4.6.12`, code `26` |
| Minimum Android | API 24 / Android 7.0 |
| Architectures | arm64-v8a, armeabi-v7a, x86_64 |
| APK SHA256 | `7e90f348e2ea50698ec39cd82449048ea39213953148b393041b31c7d30712de` |
| Certificate SHA256 | `190fa5f38b0b27b3c197459b60e34dbaa2964a38682bdb655363e2ca6386b431` |

Local Android 15 acceptance updated 4.6.11 to 4.6.12 without clearing data,
retaining diary, water, fractional goals and encrypted connection behavior.
Extended catalogue acceptance passed no-match escape, reordered English source
search, explicit banana selection, 150.5 g / 122 kcal and source restoration
after cold launch. Both food and Chef catalogues were inspected inside the APK.
CI builds its own artifact from the checked commit; the hash above identifies
the independently tested local APK, not an assertion of byte equality with CI.

One opt-in live Android Chef request passed consent -> source review (388 kcal)
-> explicit save -> cold launch, with visible source/calorie verification;
the temporary connection was removed. A separate server Chef request verified
four curated identities. Two V2 photo controls returned an apple identity with
uncertain portion and no food for a blank image. These four synthetic/public
acceptance requests did not increase quotas or enable automatic retries.
They establish those cases and connectivity, not general model accuracy.

The deployed Worker is `d96a2920-f651-4193-bf5e-6c3809aae3ed`; existing V1/V2,
D1 and 5/user/day, 20/global/day, 4/global/minute limits remain. No automatic
Worker deployment or store publication occurs on merging this release.

## Remaining work

Physical-device camera/gallery acceptance and broader food recognition quality,
personal satiety calibration, Chef beyond the curated ready-food assembly,
native iOS acceptance and publication remain separate stages. The satiety
heuristic has not been clinically validated. A future clinical module needs
its own requirements, privacy design and specialist validation; the present
Gemini flow does not provide medical diets or clinical advice.
