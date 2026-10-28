# AI Chef client: source-grounded assembly suggestions

Entry: Today/Profile -> Ideas -> AI Chef. Nothing is sent on page open. The
person enters a pantry list and confirms a dialog identifying their server and
Google Gemini; no automatic diary/profile/hunger export. The same encrypted
connection and quota used by camera/text are reused. Each explicit attempt is
one request, no automatic retries or V1 fallback. Pantry text is not persisted;
errors/cancel keep the current form. Late results cannot open/close a newer draft.

Initial scope is combinations of 18 curated ready-to-assemble CoFID foods,
including already cooked rice/chicken and raw edible vegetables; it does not
invent cooking yields, arbitrary recipes or medical diets. The server supplies
only approved recordId/grams/warning codes. Client checks request ID, contract
and catalogue versions, source existence/name, unique IDs, counts and total mass.
Unknown/dry IDs, malformed responses and arbitrary advice warnings are rejected.
Unsolicited names, nutrients, titles, source links or hours are never read.

`ChefCatalogue` resolves local NutritionSource profiles, `NutritionEngine` scales
each once and `PhotoReviewPage` displays sources/portions for explicit editing
and confirmation. Unknown fibre remains unknown. Source-verified facts are not
model estimates. Diary items keep an optional chefSuggestion origin marker and
stable chef_<requestId>_<index> IDs; failed-save retry and route rebuild keep the
same batch. Source edits preserve origin and entry ID. Existing records lacking
the marker remain compatible, with no data migration/new preferences key.

Offline/unconfigured Chef retains input and links to shared settings and the
working local recipes. No-match results do not create a diary entry. Consent
refusal does not create a service/request. Closing/cancelling waits closes the
client and rejects stale results; accepted server requests can still use quota.

Consent disclosure was checked against the official Gemini API terms on
28 Oct 2026: adult use and unpaid-service content handling. No medical data is
requested. Current Gemini service must not be used for a future clinical module.
Source: https://ai.google.dev/gemini-api/terms

Tests cover forged nutrition ignoring, strict source/contract identity, request
shape, errors/size/timeout without retry, source/unknown fibre/origin persistence,
consent, cancelled/stale requests, missing settings, no-match/local read failure,
explicit save retry after route rebuild, offline return and source correction.
CI's Android Chef smoke makes no provider request; live-owner testing is separate
and must be reported explicitly. Passing mocks does not establish live accuracy.

## Acceptance on 2026-10-28

230 Flutter tests, analyze, 23 Python harness tests and actionlint passed.
Release APK 4.6.11+25 retains com.example.fitlife and the existing certificate
SHA256 190fa5f38b0b27b3c197459b60e34dbaa2964a38682bdb655363e2ca6386b431.
APK SHA256: 3da5e972d5981143b4d11c287d2b0d9d5020c38c10c8873f4f8de6464430b534.
The bundled shared metadata was inspected: the expected version and 18 identities.
Android 15 emulator update without clearing data passed: diary, water, fractional
goals and encrypted connection save/read/delete. Offline Chef retained input,
opened shared settings and returned to a real 210 g / 113 kcal local half-portion.

One separately enabled live Android request passed consent -> source review
(388 kcal) -> explicit save -> cold launch. Visible chicken 120 g / 178 kcal and
rice 150 g / 176 kcal entries retained CoFID references and the AI-idea origin;
the manual checker compared visible calories with local source values. The
temporary secure connection was removed in finally. One additional synthetic
server request independently verified all four IDs/masses. Neither call tests
broad recommendation accuracy. No physical phone or iOS acceptance is implied.

Manual tool `tool/android_chef_live.py` requires --allow-live-request and a private
config, only accepts emulator serials, refuses a nonempty initial connection,
suppresses private input command errors and never automatically retries.
Do not add it to CI or capture diagnostics while entering credentials.
The offline CI tool uses the actual pantry EditText identifier: Android omits
the visible empty field label from its accessibility text. Regression tests
cover the observed empty-field representation and disabled-input rejection.
