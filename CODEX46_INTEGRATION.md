# Sprint 0B: preserve and integrate the local Codex 4.6 work

## Provenance and scope

Recovered the uncommitted work from the idle chat `FitLife и обновить UI`,
checkout `E:\SAVE\CODEX\Fitnes Life`, HEAD `bbe7239`. Before changing the
integration copy, saved its 15 tracked-file changes as a binary patch and
its untracked deliverable sources in a separate snapshot. The original checkout
and its private files remain unchanged. This PR is based on Sprint 0 PR #7.

Preserved saved meals, portion scaling, repeat of yesterday's meals, dated
weight history, missing-fiber flags, expanded source-linked catalogue search,
the local CSV/JSON import pipeline and tests, iOS sources, simulator integration
and packaging instructions. Imported food assets currently contain zero extra
records. A downloaded USDA source is not yet a validated imported database.

## Integration decisions

- Feature repositories use `DiaryRepository.withLoader` and its `run` bridge
  through P0's shared `PreferencesQueue`. No independent write queue is restored.
  Existing positional repository consumers remain compatible.
- The shell keeps the P0 controller. Returning from the meal/weight routes
  reloads the controller; catalogue additions retain stable operation IDs.
- Read `WeightHistory` in the queued settings snapshot; no invented weight on
  first install. Previously saved undated weight remains an undated fallback
  until history is written. Deleting history does not resurrect that fallback.
- Keep goal snapshots, fractional carb preview and recovery rules from #7.
  Do not restore the local 4.6 screen's older individual goal-key writes.
- Preserve missing-fiber metadata when adding catalogue food to the controller,
  and when constructing the NutritionDay used by the catalogue.
- Adapt both sets of tests to the final storage contracts. Test persisted
  dated-weight failures against `weight_history_v1`, with a real legacy-weight
  fixture, instead of asserting a fictitious default measurement.
- Release `4.6.1+15` updates both development lines and #7 without changing
  `com.example.fitlife` or the existing signing certificate.
- Retain iOS build/simulator jobs behind an explicit manual `verify_ios` input.
  This Android-first integration does not spend macOS minutes on every PR.
  Native iOS build, signing and App Store publication are not claimed verified.

## Validation

- Flutter analyze: no issues. All 157 Flutter tests passed.
- Four Python catalogue-import tests passed. Six existing Android harness tests
  passed on #7; CI now runs all `test_*.py` tool tests.
- No backend changes relative to #7: all 17 backend tests passed there.
- Signed universal release APK built (56.9 MB), version 4.6.1, code 15.
  v2 signature valid, certificate SHA-256
  `190fa5f38b0b27b3c197459b60e34dbaa2964a38682bdb655363e2ca6386b431`.
- APK SHA-256
  `c95dca6e3bf27ddc5472d1a0e6c37fd25d07946eeef363881332f5f0409da749`.
- Native Android 15 upgrade 4.5.2 → 4.6.1 passed without clearing data.
  Dated weight 83.5 kg, template of 100 g egg, half portion 50 g / 79 kcal,
  total 236 kcal and cold relaunch passed on the signed release APK.
  The harness scrolls exact controls clear of the floating add button and
  checks accessible text instead of field labels Android does not expose.
  A current-day empty diary is seeded if the two scripts cross midnight.
  All 11 Python tool tests pass, including the obscured-control regression.
  `tool/android_features_smoke.py` follows the existing native
  release smoke in CI, checking dated weight, saved template, half portion and
  cold relaunch. All smoke runs use a separate disposable emulator.

## Remaining work

Today needs clearer fiber visibility, honest empty states, one actionable local
recommendation and supportive companion states. The camera still uses the
existing selection/analysis flow. AI nutrient-source grounding, experimental
Smart Satiety, voluntary hunger feedback, learning and AI Chef are later steps
in DEVELOPMENT_STEPS.md. Physical phone acceptance and iOS native verification
remain separate gates.
