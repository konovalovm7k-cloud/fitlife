# Offline nutrition lessons and small tasks (4.6.7+21)

Today offers one optional learning step. Profile always exposes the same lesson
list. Three short Russian lessons cover portions, nutrient roles, and nutrition
sources/missingness. Each includes a small real-world task, a direct action to
open the actual diary, and cited public sources. Opening the diary does not
insert the teaching example or otherwise modify food records.

## Evidence and calculation

Content was checked on 27 October 2026 using these primary public-health sources:

- [FDA: label interpretation and serving example](https://www.fda.gov/food/nutrition-facts-label/how-understand-and-use-nutrition-facts-label)
- [MedlinePlus: protein in diet](https://medlineplus.gov/ency/article/002467.htm)
- [MedlinePlus: carbohydrates](https://medlineplus.gov/carbohydrates.html)
- [MedlinePlus: dietary fats](https://medlineplus.gov/ency/patientinstructions/000104.htm)

The interactive example is the FDA teaching label: 227 g, 280 kcal, 15 g protein,
9 g fat, 34 g carbohydrate and 4 g fiber per serving. Convert the declared values
to per 100 g, then use the existing Nutrition Engine for 0.5/1/2 servings.
Two servings are 454 g / 560 kcal; no AI-generated nutrient facts or separate
calorie reconstruction formula is used. The displayed per-100-g calorie value
is rounded; calculation retains full precision. The app clearly labels the
example as educational, never a personal meal or a recommended serving size.

The FDA example illustrates one US label format. It does not imply that every
country/product uses the same label basis. Users are told to check 100 g,
serving or package amounts before entering per-100-g values in FitLife.
Nutrient roles are general education, without assigning new personal targets,
forbidden foods, supplements, disease management or medical recommendations.
The sources lesson distinguishes verified composition from absent facts and
an experimental satiety estimate from a subjective hunger observation.

## Progress and support

The person may mark a lesson understood or undo that mark. This is self-reported
learning progress, not proof a real-world food task was performed. No lesson
mark depends on calories, weight loss, hunger suppression or meal timing. No
goals, rewards, pet state, diary, weight, water or hunger observations change.
There are no streak resets, notifications, background tasks or AI requests.

`learning_completed_v1` stores versioned lesson IDs through the existing shared
preferences queue. Concurrent marks keep other lessons and unknown future IDs.
False/throw native writes remain visible, preserving the interactive draft for
retry. Malformed progress uses the existing non-private recovery mechanism;
it does not touch nutrition/history keys. The content is bundled locally, so
lessons/calculation/progress work offline. Public source links are selectable
text; reading the linked websites requires the user's browser/internet.

## Verification scope

Tests cover the actual Nutrition Engine example, concurrency, retry, undo,
future lesson IDs, damaged progress, Today and Profile navigation, cold root
restart, source/large-text layout and the task's real diary action. A storage
snapshot check proves teaching interactions change only the progress key.
`tool/android_learning_smoke.py` exercises the installed signed APK's example,
source display, native persistence/relaunch and navigation to the diary.
These tests do not establish learning effectiveness or clinical outcomes.
