# Local meal ideas — first Chef stage

Three bundled examples: vegetables/cottage cheese/bread, prepared grilled
chicken/boiled basmati/vegetables, and boiled red lentils/vegetables/bread.
Available from Today and Profile. There is no AI call, network dependency,
quota reservation or generated nutrition in this mode. AI Chef remains a
separate subsequent stage, using existing source/confirmation requirements.

Each ingredient references an exact CoFID 2021 code already in the bundled
catalogue (COFID_CATALOGUE.md), with edible mass in the source's stated state.
Raw foods are never substituted for cooked foods; no cooking-yield conversion
is guessed. Recipes are simple assembly examples using already prepared foods,
not a cooking-temperature guide or personalised nutrition prescription.
Milk/wheat ingredients are identified, and users are asked to check package
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

Cottage example: 120 g code 12-550, 150 g 13-517, 100 g 13-523,
50 g 11-981; P19.17/F3.8/C30.66/fibre5.7 g. Half is 210 g / 112.55 kcal
(113 displayed), not a separately guessed recipe. All coefficients come from
the source profiles, not a macro-to-energy formula.

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
