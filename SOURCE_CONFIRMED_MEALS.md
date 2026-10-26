# Source-confirmed meals (4.6.3+17)

Camera and text recognition now use the additive V2 identity contract. The model
may suggest a name, edible portion mass and identification confidence. Its
nutrient values, source IDs and URLs are ignored, including unsolicited fields.
There is no fallback to V1 estimates when an older server returns 404.

## Confirmation and calculation

Every recognized item needs a person-selected catalogue record or a manually
entered package label before the review can be saved. Catalogue selection is
explicit: a similar name is not proof of the correct product or cooking state.
The catalogue is intentionally limited; extra locally imported records can be
used. Missing matches require another query or a label, not invented values.

`NutritionEngine.portion` validates the source and scales per-100-g values once
by the confirmed edible mass. It neither calls AI nor infers absent nutrients
from calorie formulas. Label entry requires a product name, source description,
calories, protein, fat and carbohydrate. Fiber is optional and its unknown state
survives storage, templates, retries and relaunch. Partial fiber totals display
as incomplete; zero is not presented as a measured missing value.

Both camera and text screens offer offline label entry. It uses the same review
and serialized diary save, with no server request or recognition quota use.
The source kind/reference and catalogue ID/URL persist on each new diary item.
Legacy entries remain readable and are not retroactively assigned a source.
Existing application ID, signing key, preference keys and connection storage
are unchanged. Server V1 remains available for older installed apps.

## Verification scope

- Flutter analyze and 172 tests pass, including a full offline label UI flow,
  restart, unknown fiber, stable retry IDs, forged model fields and old diaries.
- Signed release 4.6.3+17 builds; Android upgrade smoke passes on API 35.
- `tool/android_source_smoke.py` exercises the installed release with a
  synthetic 150.5-g label, calculated 196 kcal and unknown fiber after relaunch.
  CI runs it after the existing upgrade, template/weight and Today scenarios.
- Tests verify calculation and storage behavior, not the accuracy of a photo,
  label transcription, cooking-state choice or physical-phone behavior.

No satiety score, predicted hours, food-restriction rewards or medical advice
are introduced here. Full-catalogue coverage and recognition quality evaluation
remain separate work.
