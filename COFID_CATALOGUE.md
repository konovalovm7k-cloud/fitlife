# CoFID 2021: local curated catalogue

40 additional common foods, bundled locally; no runtime download or API charge.
The original eight source-linked records and all installed diary data remain.
The 4.6.25 expansion appends 20 foods while preserving every field of the first
20 published records. IDs, source references, names and nutrient values are
compatibility data. Curated Chef identities remain unchanged; the expansion
does not add server/model foods or API requests.
Russian names distinguish raw/dry/cooked state, edible portion and drained fish.
These UK generic foods are reference compositions, not a claim about a specific
Russian brand. Select the matching food/state or enter its package label.

## 4.6.25 verification

All40 imported records (48 including the unchanged original catalogue) pass
Nutrition Engine validation. The first20 published records have a frozen
compatibility digest; the curated Chef metadata is identical. Re-importing the
pinned official workbook reproduces the asset byte for byte. Unknown AOAC fibre
remains missing, while measured milk fibre zero remains known zero.

Three additional Flutter scenarios cover engine compatibility and cooking-state
search; real repository save/reload of fractional brown rice, milk and unknown-
fibre grain without rewriting the prior rice; and Russian search -> exact portion
calculation -> source-preserving satiety preview -> back/cancel without a write.
The existing ambiguous cooked-rice search now explicitly returns both white and
brown rice and still requires a user selection. All274 Flutter-/49 Python-tests,
analysis, actionlint and signed APK4.6.25+39 pass. Actual package/version and the
existing release certificate are verified. APK SHA256:
73f9293997c5bb36d5bb38eacbba67c810527f34a45e2a390190f82ea298e9b1.

The packaged asset exactly matches all40 source rows and the unchanged first20.
On Android15, update38->39 and both native catalogue previews pass: existing
banana and newly imported brown rice at150.5g,122/199kcal, known fibre, explicit
structure/score, exact draft on back, cancel/cold. Every serialized entry in four
ordinary/encrypted preference files remains unchanged. No food was created and
there were no API requests. Native CI uses the same old+new catalogue paths;
all12 scenarios and full dependency/merge checks remain required before merge.
Physical Android and native iOS remain untested.

## Source and licence

Public Health England, McCance and Widdowson's Composition of Foods Integrated
Dataset 2021, `1.3 Proximates`, per 100 g edible food. Source rechecked 29 Oct 2026:
https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid

Official workbook:
https://assets.publishing.service.gov.uk/media/60538b91e90e07527df82ae4/McCance_Widdowsons_Composition_of_Foods_Integrated_Dataset_2021..xlsx

SHA256: `436e9445ef2adb2a75f3d7edd51302de3adad25385f9795fc94ba58bd030e97d`.
The separately published old-foods dataset is not used.

© Crown copyright 2021. Contains public sector information licensed under the
Open Government Licence v3.0.
https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/
No logos or third-party illustrations are included. The GOV.UK publication page
links the Open Government Licence; the official 2021 user guide identifies
Crown copyright on its final page:
https://assets.publishing.service.gov.uk/media/60538e66d3bf7f03249bac58/McCance_and_Widdowsons_Composition_of_Foods_integrated_dataset_2021.pdf

## Reproduction and missingness

`tool/cofid_selection.json` contains exact original English names, codes and
Russian display names. Each bundled record retains its English name, code,
source reference and source URL. To reproduce with Python + openpyxl:

```
python tool/import_cofid.py /path/to/CoFID-2021.xlsx assets/data/food_catalog.json
```

The importer checks the exact workbook hash, column IDs and unambiguous selected
code/name before replacing the asset. The original workbook contains a duplicate
code 13-669 for two unselected foods; either would be rejected if selected.

Kcal comes directly from KCALS, never reconstructed from macros. Protein/fat/
carbohydrate use PROT/FAT/CHO; AOACFIB is fibre (not NSP/ENGFIB), WATER is water.
CoFID carbohydrate definitions are retained; no attempt to force a 4/4/9 match.
Numeric zero remains known zero. `Tr`, `N` and blanks never become measured zero:
required nonnumeric macros reject a selection; optional fibre/water are omitted.
For example low-fat plain yogurt 12-379 has AOAC fibre `N`, so fibre is unknown.
Eggs and olive oil have trace required macros and are excluded from this subset.
In the expansion, milk has measured numeric zero fibre; buckwheat groats, green
pepper and walnut kernels have no reliable AOAC fibre value and remain unknown.
Edible flesh/kernels and preparation state are retained; with-waste/core/shell
rows and salted/sweetened/filled alternatives are not silently substituted.

The import adds known fibre independently of micronutrient availability. Existing
macro-only imports remain compatible. CoFID micronutrients are not imported and
their absence is stated. Mixed daily fibre totals are lower bounds. The current
satiety heuristic still treats zero/missing food water conservatively as unknown;
water values are never inferred from mass balance. No hours of satiety predicted.

No database migration, applicationId/signing change, AI request or deployment.
Portions are scaled by Nutrition Engine after explicit source/user confirmation.
Existing saved records are snapshots and are never silently replaced by updates.
