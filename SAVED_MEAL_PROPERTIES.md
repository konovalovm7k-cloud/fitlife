# Saved dish portion properties

The existing saved/repeat-meal portion page now shows known fiber or explicit
incomplete composition. A valid portion count can open the existing SatietyPage
in a read-only preview mode. Ingredient masses scale by chosen portions divided
by recipe servings. Existing ingredient IDs/source snapshots/time are retained
for calculation; no new diary IDs or writes are created by opening the preview.

SatietyEstimate.calculate aggregates mass and source nutrients for the complete
dish before scoring. Formula version 1, weights, gates and missing-factor ranges
are unchanged; ingredient scores are never added. Legacy/unconfirmed ingredients
remain readable but do not produce an invented score. No precise hours or health
quality judgement is added.

The preview has no hunger-entry/history actions; the ordinary diary SatietyPage
retains them. It receives the selected diary day only as existing context and
does not treat the planned food as eaten. Back retains the exact typed portion
count. The existing explicit Add, stable operation ID, locks and writer remain.
Invalid counts show an instruction rather than fabricated zero kcal/grams.
Input/search focus is removed before navigation to avoid Android IME restoration.
In preview, the complete source list is expandable so a multi-ingredient dish
does not bury the score below many screens. The diary view keeps its source list.

Three widget scenarios cover a two-ingredient recipe with recipe servings and
fractional chosen portions, source/ID/time retention, aggregate score/structure,
320×700/text1.8, back/cancel/no writes or hunger records; legacy/unknown fiber,
no score and explicit scaled Add preserving the prior diary; invalid/NaN/large
counts without preview, fabricated zero nutrition or writes. Existing native
saved-meal CI checks its unsourced template preview before logging the same half
portion. No APIs or persistence keys are added.

Full analysis, tests, signed release build and real Android verification are
required before completion. Full CI and dependency checks are required to merge.

Local analysis, all 271 Flutter-/46 Python-tests, actionlint and signed release
APK 4.6.24+38 pass. Actual package/version and the existing release certificate
are verified. Final APK SHA256:
a934786b2be9ac151dad102339c37fce16cddeb2567d725fef939c02ea567670.

On Android 15, update 37 -> 38 preserved every serialized entry in four ordinary/
encrypted preference files. The existing unsourced template correctly shows no
score; an actual historical meal with 15 attributed ingredients opens via Repeat
at 0.5 portions, with 695.75 g aggregate mass, explicit structure, score and
unknown factors. No food/template was seeded. After improving the source-list
layout, corrected 38 -> 38 install and both complete paths were checked again.
The native harness requires the 1–10 bounded score to be fully in the viewport,
then verifies the exact fraction on back, no restored IME, cancel/cold launch and
every preference entry unchanged. No API calls or hunger records were created.
The source expansion and exact source text are also checked at320×700/text1.8.

Full GitHub CI with all12 native scenarios remains required before merge.
Physical Android and native iOS remain untested.
