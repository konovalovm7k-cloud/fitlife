# Identification V2: no model-generated nutrition

This is the server contract for the next source-grounded camera/text flow.
It is additive: existing `/v1/analyze` and `/v1/analyze-text` clients retain
their current contract. V1 still returns model estimates; V2 does not make
the current APK source-grounded by itself. Do not describe that UI work as done.

## Request

`POST /v2/identify` accepts the same prepared JPEG (maximum 512 KiB) as V1.
`POST /v2/identify-text` accepts UTF-8 JSON `{"text":"Яблоко 180 г"}` with
1–2000 characters and at most 16 KiB body. Both require the existing bearer
token and a unique 32-character lowercase hex `X-Request-Id`.

No new provider, database, credential, migration, dependency or request is
introduced. All four endpoints share the same atomic D1 quotas and duplicate
request protection. Reusing an ID across endpoints cannot spend twice.
There are no automatic provider retries or guessed fallback foods.

## Response

```json
{
  "version": 2,
  "requestId": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  "items": [{"name":"Яблоко", "grams":180, "confidence":"high"}],
  "warnings": ["uncertain_portion"]
}
```

Names include preparation state where known, and grams are an estimate of
edible mass. Confidence concerns identification only. It does not establish
the accuracy of nutrients, portion mass or a database match.

Only these warning codes are accepted:

| Code | Meaning for the client |
|---|---|
| `uncertain_portion` | Ask the user to check the portion |
| `hidden_ingredients` | Ask about sauces/oil/ingredients not visible |
| `ambiguous_food` | The identity requires a choice |
| `preparation_unknown` | Raw/cooked state needs confirmation |
| `no_food` | No food was identified; offer manual entry |

Unsolicited calories, macros, fiber, water, satiety, source links and IDs are
discarded by an output whitelist, even when the provider violates its schema.
Free-text warnings are rejected, so generated nutrition advice cannot enter
the warning UI. Food names remain untrusted display text, never instructions.

The client must select a real catalogue/label source, retain its provenance,
calculate the portion through Nutrition Engine, and require user confirmation
before saving. Unknown nutrients must remain unknown, not silently become zero.
Do not automatically match a composite dish to a similar raw ingredient.

## Verification and rollout

24 backend tests pass, including real local Workers + D1 execution with mocked
Gemini for V1 and V2. Covered: photo/text schema, stripped forged nutrients and
sources, warning allowlist, invalid input before reservation, shared quotas,
duplicate IDs, no-food results and sanitized provider errors without retries.
These tests do not establish live recognition quality or nutritional accuracy.
Wrangler dry-run bundle succeeds (13.97 KiB, gzip 4.85 KiB); no upload occurs.
Flutter analyze and all 163 Flutter tests still pass. Flutter/Android sources
are unchanged from the verified signed 4.6.2+16 APK in #9.

No deployment is part of this commit. Deploy the additive server before
switching the app to V2. The next client change must present an explicit update
or manual-entry fallback on an older server's 404; it must not silently fall
back to V1 nutrient estimates. Existing saved diary entries remain readable.
