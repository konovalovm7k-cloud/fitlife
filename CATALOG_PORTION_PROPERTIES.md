# Catalogue portion properties

The existing catalogue portion dialog now calculates the entered mass through
Nutrition Engine and the selected catalogue source. It shows kcal, protein, fat,
carbs and known fiber (unknown remains explicitly unknown). Valid masses up to
3000 g can open the existing read-only portion-properties page before logging.
The score model, formula version 1, source validation and scope are unchanged.
The old logging range 0.1–10000 g stays available; larger portions simply cannot
open the experimental score. No precise hours or health-quality claims are added.

Returning retains the exact typed mass, including comma decimals. Opening the
preview removes input focus so Android does not restore the keyboard over the
dialog. Cancel never invokes the diary write callback. Explicit Add uses the
existing pending entry and stable retry ID; the existing day's totals remain.
No persistence keys, targets, pet rewards, APIs or server calls are added.

ValueEditorDialog gains an optional valid-values details builder and stable
numeric-field semantics for the native Android checks. Existing save validation,
pending-operation locks and error handling are retained.

Three widget tests cover 320×700/text1.8, exact source/mass, back/cancel/no write,
explicit Add, failed-write retry with the same ID and retained day total, invalid
mass, and the unchanged larger logging range. The source Android CI scenario also
opens an actual catalogue source, previews 150.5 g / 122 kcal, selects structure,
returns to the exact draft and cancels before continuing its existing checks.

Full analysis, all tests, release build/identity/signature and actual Android
update/cancel/cold verification are required before publishing completion.

Local analysis, all 268 Flutter-/46 Python-tests, actionlint and the signed
4.6.23+37 release build pass. Actual package/version and the existing release
certificate are verified. APK SHA256:
b12cf89195d199204674694109f4eb7b0c9b1c7e2d8649cb6b11cda69edd4e5d.

On Android 15 the initial 36 -> 37 install preserved all serialized preference
entries, but the full path exposed restored search focus after dialog cancel.
The catalogue now unfocuses search before opening the portion dialog as well.
On the corrected 37 -> 37 install the exact CI catalogue method passes: real
CoFID banana, 150.5 g / 122 kcal / 2.1 g fiber, explicit structure/score, exact
draft on back, no restored numeric/search IME, cancel and cold launch. Every
serialized entry in all four ordinary/encrypted preference files is unchanged.
No food or hunger record was created and there were no API calls.

Full GitHub CI and dependency/merge checks remain required before integration.
Physical Android and native iOS remain untested.
