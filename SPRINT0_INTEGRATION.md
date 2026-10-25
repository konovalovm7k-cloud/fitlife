# Sprint 0: integration of the two FitLife development lines

## Sources checked on 2026-10-25

All five PRs are open. `main` is `2e0e210`. PR #2 now points to
`bbe7239`, whereas #3 originally branched from `55a8fea`. GitHub reports #3
conflicting with #2. #4, #5 and #6 are clean against their own stacked bases;
that does not establish compatibility with the newer #2.

`codex/sprint0-integration` starts at #6 (`e1fef03`) and merges the newer #2.
The original branches and PRs are retained. No remote PR has been merged.
This branch contains both histories so later integration can retain ancestry.
The proposed PR targets #2 and includes the previously reviewed P0 series.
Once this branch is reviewed and integrated, #3–#6 can be reconciled with that
result; do not merge their old conflict resolutions over this result.

## Conflict decisions

- Retain P0's controller, dated repository adapter, shared preferences queue,
  versioned goal snapshot, fractional targets, and distinct recovery backups.
- Keep #2's text/photo model flags, recognition routes, private connection
  support, quick actions, seven-day report and server/quota changes.
- Connect text/photo save to the controller rather than a second screen state.
- Catalogue retries carry their original operation ID into the controller.
  Validate caller-built records before replacing a persisted diary day.
- Read weekly reports inside the shared queue, including recovery backup writes.
- Preserve both storage test suites. Adapt #2's UI assertions to the versioned
  goal snapshot and P0's contract: a committed meal closes even when optional
  recent-food bookkeeping fails, with a specific notice.
- Preserve #2's narrowly scoped emulator launcher-ANR handling and P0's native
  fractional-goal/manual-diary smoke coverage.
- Keep `com.example.fitlife`, signing configuration and all existing data keys.
  Release version `4.5.2+14` is newer than both published development lines.

## Validation

- Flutter 3.44.7: static analysis passed; all 138 Flutter tests passed.
- New upgrade regression migrates a mixed manual/photo/text 4.5 fixture twice,
  preserves original diary and legacy goal keys, retains fractional goals,
  water, weight and lists, and reconciles controller totals with weekly totals.
- All 17 backend tests and six Python smoke-harness tests passed.
- Signed universal Android release APK built locally (56.3 MB). The local build
  uses `kotlin.incremental=false` solely for the SDK/project cross-drive setup.
- APK metadata: `com.example.fitlife`, version 4.5.2, code 14, min SDK 24.
  Signature v2 valid; certificate SHA-256:
  `190fa5f38b0b27b3c197459b60e34dbaa2964a38682bdb655363e2ca6386b431`.
- APK SHA-256:
  `bc0eba48933f48cfe06b5c9b02cd7bcfe99857ffae3ee83fd8d9294e06e43683`.
- Android smoke and CI results are appended after execution; a successful build
  alone does not establish a successful installed-device flow.

## Additional local Codex work

The idle chat `FitLife и обновить UI` has uncommitted 4.6 changes in
`E:\SAVE\CODEX\Fitnes Life`: saved meals/repeat entry, dated weight history,
catalogue import, missing-fiber metadata, iOS sources and tests. On 2026-10-25,
76 files (394384 bytes including the manifest) were copied to the current chat's
private `work/codex-4.6-snapshot`, and a binary-capable tracked-file patch was
saved. The source checkout was not modified. Private server configs, keys and
personal APKs are excluded from that snapshot and from Git.

These additions are a separate continuation of Sprint 0, not discarded work.
They must be adapted to the shared controller/queue and verified before release.
The 4.6 asset currently contains no extra foods; imported catalogue size must
not be represented as a completed USDA database. iOS publication is deferred.

## Boundaries

SharedPreferences is not a multi-process or multi-key ACID database. This queue
protects operations in one isolate and retains ordering after caller timeouts.
No data reset, package rename, signing replacement, live Gemini request, Worker
deployment or quota change is part of this integration.

Existing AI-generated nutrient estimates are carried forward and labelled, not
newly certified as source-backed. The next nutrition stage must resolve food
identity against attributed data and calculate using Nutrition Engine before
confirmation; current Gemini validation alone does not prove nutrient accuracy.
Do not claim AI-source grounding, Smart Satiety, a completed Today redesign or
medical features from this integration.
