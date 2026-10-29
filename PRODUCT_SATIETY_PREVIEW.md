# Product portion properties before diary save — 4.6.22+36

The experimental score was available only for a saved diary meal. A valid
attributed portion in the source editor now offers an optional read-only screen
before confirmation. It uses the same local formula v1, scale 1–10, factor
weights, energy gate and scope as the diary meal; none of these are recalibrated.

The screen shows product/source/mass, allows explicit food-structure choice,
displays the score or range with missing factors, and retains the existing
limitations. It predicts no hours, does not measure hunger or food quality,
does not alter targets/rewards/pet state, and never sums ingredient scores.
Zero-energy/out-of-scope portions receive no fallback score. It makes no API call.

SatietyEstimate.fromPortions accepts attributed source/mass records directly;
the diary calculate adapter uses it as well. No fake diary IDs/timestamps are
created for previews. Nutrients are scaled by Nutrition Engine, then aggregated
before the unchanged formula. Legacy unsourced diary entries still cannot score.
Structure labels and the existing explanation are shared with the meal page.

The preview owns no storage repository or write callback. Hunger observation
actions remain on actual diary meals, where a meal/time context exists. Returning
to the editor preserves source/grams; only its existing confirmation may write.

Four new tests cover source/diary equivalence across masses/structures, unchanged
formula version and unknown flags; invalid/zero-energy/out-of-scope sources;
320x700/text1.8 source -> preview -> structure -> back -> invalid draft -> cancel
with no onSave or preference changes; and an unavailable zero-energy page with
no score or structure reward. Existing splitting/bounds/legacy tests stay in place.

Local analysis, all 265 Flutter-/46 Python-tests, actionlint and signed APK pass.
The actual applicationId/version and existing release certificate are verified.
APK 4.6.22+36 SHA256:
159a6a844122898733257b81925b557ab1e17ccc3f91ef24a40d33fc2d5a886a.

Actual Android 15 update 4.6.21+35 -> 4.6.22+36 preserved every serialized entry
in four ordinary/encrypted preference files. An existing attributed product was
opened from a historical diary day through the real calendar, with no invented
food seeded after the UTC day changed. Its visible 1–10 score and explicit solid
vs liquid structure were checked; returning retained the exact source grams.
Back/cancel/cold launch left every preference entry unchanged. No AI calls.

Full GitHub CI with all 12 native scenarios is still required before merge.
Physical phone and native iOS are not tested.

### Android keyboard return correction

CI 40823586219 built and verified the release, but the source scenario failed
after returning from the preview. Its screenshot showed the numeric IME restored
over the source form. This was reproduced on the installed original release APK
without saving food. The preview action now unfocuses the editor before opening
the route; native CI explicitly rejects a restored IME before confirming.

The corrected signed 4.6.22+36 APK has SHA256
0dfcb634b68dde119f1f0e0825bd48fc74bdf485f9e1727521aed039866e4007.
Analysis, 265 Flutter-/46 Python-tests and the release identity/signature gate
pass. On the actual Android emulator the same flow returns with no reopened IME,
reaches confirmation with 150.5 g / 196 kcal / unknown fiber, and cancel/cold launch
preserves every serialized entry in all four preference files. The physical
phone and full repeated GitHub CI remain separate required checks.
