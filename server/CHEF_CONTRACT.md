# Chef: source identities, never generated nutrition

`POST /v2/chef` accepts UTF-8 JSON `{"text":"Готовый рис, курица и огурец"}`
under the existing bearer token and 32-lowercase-hex `X-Request-Id`.
Input gates match text identification: exactly one text field, 1–2000 UTF-16
code units, valid UTF-8, at most 16 KiB, no forbidden controls. Invalid input is
rejected before quota/provider access. One accepted request uses the same atomic
D1 reservation as V1/V2 camera/text. No new credentials, database migration,
provider, quota increase, automatic retry or server-side pantry storage.

The initial mode proposes a combination of ready-to-assemble foods from the
curated CoFID subset, not arbitrary cooking instructions or medical diets.
Dry rice/oats and the legacy raw fish/fat catalogue are excluded. Cooked weights
are already cooked edible food; no yield conversion is guessed. The person must
check source/state, portion, package allergens and unlisted oil/sauce before
saving. This endpoint alone does not implement the client Chef interface.

## Response

```
{
  "version": 1,
  "kind": "chef",
  "requestId": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  "catalogueVersion": "cofid-2021-ready-v1",
  "items": [{"recordId":"imported_cofid_2021_11-858","grams":150}],
  "warnings": ["check_portions", "check_labels"]
}
```

`recordId` must match one of 18 curated identities in
`shared/chef_catalogue.json` / generated `src/chef_catalogue.mjs`. Only those IDs
and proposed grams reach the response. The model cannot supply names, titles,
instructions, links, nutrition facts, sources or hours of satiety: unsolicited
fields are stripped, IDs are checked against the fixed allowlist and warnings
against `check_portions`, `check_labels`, `no_match`, `pantry_unclear`.
Invented/dry IDs, duplicates, malformed mass, >12 items or >3000 g total reject
the provider response. Empty results require no_match or pantry_unclear; a
no_match warning cannot accompany nonempty items. Invalid output returns
sanitized 502/invalid_result, never guessed fallback food.

Model input contains pantry text and public source names/IDs. The application
does not attach calories/macros, body measurements, goals, hunger history or
diary export; user-entered pantry text is sent only with consent. Model output
is capped at 1024 tokens, using the existing model and low thinking setting.
No generated nutrient fact can enter through a free-text response field.
Nutrition Engine must resolve local per-100-g facts and the client must require
explicit review/confirmation; the endpoint does not save diary records.

Regenerate metadata without network:
`python tool/generate_chef_catalogue.py` from repository root. A deliberate exact
code allowlist prevents later catalogue additions from becoming eligible by
accident. Tests compare generated JS, shared metadata and sourced food identities.
Existing CoFID attribution/licence applies; see COFID_CATALOGUE.md.

Validation includes Node/SQLite request gates and mixed-mode quotas, forged
output filtering, unknown/dry/duplicate IDs, empty results/provider failures and
real Workers/D1 runtime with mock Gemini. Existing V1 and V2 contracts remain.
Deployment and live-provider status are recorded separately; passing mocks is
not a claim that the server has been deployed or a live recipe was generated.

On 2026-10-28 production version `d96a2920-f651-4193-bf5e-6c3809aae3ed`
was deployed after verifying the prior production version. One explicitly enabled
synthetic request returned HTTP 200 with four allowlisted IDs and masses; no
generated nutrient fields. This checks connectivity and the contract, not broad
recommendation quality. See DEPLOYMENT.md and manual tool/check_chef_live.py.
