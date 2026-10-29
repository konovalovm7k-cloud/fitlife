# Local meal ideas — first Chef stage

Five bundled examples: vegetables/cottage cheese/bread, prepared grilled
chicken/boiled basmati/vegetables, boiled red lentils/vegetables/bread,
prepared brown rice/canned kidney beans/boiled broccoli, and whole-milk plain
yogurt/raw pear with skin/almond kernels. The first three IDs and compositions
are unchanged; 4.6.27 appends two ideas from the existing catalogue.
Available from Today and Profile. There is no AI call, network dependency,
quota reservation or generated nutrition in this mode. AI Chef is a separate
mode using existing source/confirmation requirements and its unchanged curated
identities/quotas; these additions do not change the server's Chef catalogue.

Each ingredient references an exact CoFID 2021 code already in the bundled
catalogue (COFID_CATALOGUE.md), with edible mass in the source's stated state.
Raw foods are never substituted for cooked foods; no cooking-yield conversion
is guessed. Recipes are simple assembly examples using already prepared foods,
not a cooking-temperature guide or personalised nutrition prescription.
Milk/wheat/almond ingredients are identified, and users are asked to check package
allergens and add unlisted oil/sauce. No allergy-free claim is made.

Nutrition Engine scales each per-100-g source once, then totals are summed.
Presets are half/one/two example portions; sources/masses can be changed in the
existing review screen before explicit diary confirmation. Missing/ambiguous
required source disables that idea, not an estimate of zero. Unknown fibre is
kept unknown. Invalid catalogue reads expose retry; no diary writes occur until
confirmation. Opening review is guarded against duplicate routes.

Independent numeric checks for one example portion:

| Idea | Edible mass | Source energy |
|---|---:|---:|
| Cottage/vegetables/bread | 420 g | 225.1 kcal |
| Chicken/rice/vegetables | 520 g | 388.1 kcal |
| Lentils/vegetables/bread | 375 g | 301 kcal |
| Brown rice/kidney beans/broccoli | 420 g | 360 kcal |
| Yogurt/pear/almonds | 365 g | 305.6 kcal |

Cottage example: 120 g code 12-550, 150 g 13-517, 100 g 13-523,
50 g 11-981; P19.17/F3.8/C30.66/fibre5.7 g. Half is 210 g / 112.55 kcal
(113 displayed), not a separately guessed recipe. All coefficients come from
the source profiles, not a macro-to-energy formula.

Brown rice example: 150g11-869 already boiled without salt,120g13-660 canned
in water/reheated/drained kidney beans,150g13-503 already boiled unsalted broccoli;
P20.67/F3.3/C66.12/fibre14.61g. Canned beans are not substituted with raw or dry
beans; the example does not provide cooking instructions for raw kidney beans.
Yogurt example:200g12-184 whole-milk plain yogurt,150g14-321 edible raw pear
with skin,15g14-896 whole almond kernels; P15.03/F13.635/C32.745/fibre5.925g.
Measured yogurt fibre zero stays known zero. These are assembly examples,
not prescribed meal sizes, food targets or allergy-free recommendations.

At half portion, the new ideas are210g/180kcal and182.5g/152.8kcal(153displayed).
The existing whole-draft properties preview uses the same selected source
snapshots and masses before explicit confirmation. Native smoke previews both
new ideas and cancels them; the original dairy/bread save/relaunch case remains.

Saving reuses PhotoReviewPage/manual -> shared controller -> existing serialized
diary repository with stable-ID batch replacement. Failed writes retain the
draft and retry ID. Each ingredient/source snapshot persists in the diary,
remaining compatible with saved meals and whole-meal satiety. No new storage
key, migration, applicationId, signature, goal/pet/hunger policy or backend change.

The draft ID is allocated outside route builders in both meal ideas and the
existing offline label flow. Tests first reproduced ID changes on app/route
rebuilds, then verified stable IDs across failed saves and retry after rebuild.

Tests cover calculation/portion scaling, missing and duplicate sources, cancel,
failed write/retry without duplicates, reload with provenance, read retry and
Today/Profile navigation. Android smoke exercises half-portion explicit review
and sourced dairy/bread after cold launch. AI recipe generation, pantry filters,
medical diets and individual recommendations are not part of this local stage.

## 4.6.27 acceptance

Local analysis,278Flutter-tests,64Python-tests,actionlint, signed release build
and actual ID/version/certificate verification pass. The two new example dishes
are tested through half-portion review/properties/explicit save/reload with exact
source IDs and masses, keeping the prior saved dish. No new API call is made.

The first native40->41 installation succeeded and the rice case passed, but
the helper incorrectly rejected the last fully visible idea button because its
bottom was below90%of the display. That attempt is not counted as passed.
The actual screenshot/XML showed the full button ending at94.2%, above the
gesture area. Two regression tests reproduce the old failure and still reject
clipped buttons/other ideas. The list has no floating action covering this area;
the helper now accepts a complete target above96%, like the existing controls.

The final native41->41 repeat passes both new half-portion ideas, their visible
whole-draft score/mass/calories, back/cancel and cold launch. All serialized
entries in four ordinary/encrypted prefs-files match before/after this repeat;
no food or hunger observation was added. Baseline digests were recorded before
the repeat. A full four-file comparison across the first40->41 installation is
not claimed. Physical-phone acceptance and the PR's full CI remain separate.
