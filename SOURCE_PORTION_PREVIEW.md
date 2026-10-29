# Portion facts before source confirmation — 4.6.21+35

The source editor showed attributed facts per 100 g but no calculated portion
before its confirmation could update an existing diary entry. A read-only card
now shows the selected source/name, exact displayed portion, rounded kcal and
one-decimal macros/fiber before confirmation. All calculations use the same
Nutrition Engine as save. The shared draft-source adapter preserves the existing
full form validation and exact saved values; displayed rounding is never saved.

The card updates from grams and manual-label controllers. Missing/invalid mass,
incomplete label/reference or invalid nutrition removes calculated facts instead
of displaying zero or the previous valid result. Empty fiber remains explicitly
unknown. Catalogue sources require explicit selection. Recognition JSON does not
populate nutrients. Preview, edits and cancellation do not call onSave; only the
existing confirmation does. No new keys, migrations, network calls or targets.

Three widget scenarios cover 150.5 g/196 kcal, 200.25 g/260 displayed vs 260.325
saved, invalid/NaN/infinite/oversized/empty mass, unknown/known fiber, inconsistent
BJU, missing reference, ignored AI numbers, explicit catalogue selection and
source scaling, cancel and exactly one confirmation. Large text is included.

Local analysis, 261 Flutter-/46 Python-tests, actionlint and signed APK pass.
Actual Android update 4.6.20+34 -> 4.6.21+35, attributed preview, changed 100.25 g,
invalid mass, cancel and cold launch pass; every serialized preference entry in
four ordinary/encrypted files stayed unchanged. No AI calls. Existing ID/version
and release certificate are verified. APK SHA256:
aefdc5bbf1f5183ee6b6a7b499c94eb5d452228b93a8055147f9585dacc598e6.

Full GitHub CI with all 12 native cases is still required. Physical phone and
native iOS are not tested.
