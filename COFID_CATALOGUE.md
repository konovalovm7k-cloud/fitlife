# CoFID 2021: local curated catalogue

20 additional common foods, bundled locally; no runtime download or API charge.
The original eight source-linked records and all installed diary data remain.
Russian names distinguish raw/dry/cooked state, edible portion and drained fish.
These UK generic foods are reference compositions, not a claim about a specific
Russian brand. Select the matching food/state or enter its package label.

## Source and licence

Public Health England, McCance and Widdowson's Composition of Foods Integrated
Dataset 2021, `1.3 Proximates`, per 100 g edible food. Source checked 27 Oct 2026:
https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid

Official workbook:
https://assets.publishing.service.gov.uk/media/60538b91e90e07527df82ae4/McCance_Widdowsons_Composition_of_Foods_Integrated_Dataset_2021..xlsx

SHA256: `436e9445ef2adb2a75f3d7edd51302de3adad25385f9795fc94ba58bd030e97d`.
The separately published old-foods dataset is not used.

© Crown copyright 2021. Contains public sector information licensed under the
Open Government Licence v3.0.
https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/
No logos or third-party illustrations are included. Licence authority: official
2021 user guide, copyright page:
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

The import adds known fibre independently of micronutrient availability. Existing
macro-only imports remain compatible. CoFID micronutrients are not imported and
their absence is stated. Mixed daily fibre totals are lower bounds. The current
satiety heuristic still treats zero/missing food water conservatively as unknown;
water values are never inferred from mass balance. No hours of satiety predicted.

No database migration, applicationId/signing change, AI request or deployment.
Portions are scaled by Nutrition Engine after explicit source/user confirmation.
Existing saved records are snapshots and are never silently replaced by updates.
