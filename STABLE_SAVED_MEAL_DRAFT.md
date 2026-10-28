# Stable saved-meal draft identity — 4.6.17+31

The home diary's template action created its SavedMeal ID inside the route
builder. Rebuilding the route could supply an existing editor state with a new
initial ID. If a native write exceeded the editor's 15-second timeout, completed
later, and the user retried after a rebuild, both writes stored different IDs:
one intended template could become two.

Allocate the immutable initial SavedMeal once per opened editor, outside its
route builder. All retries of that draft then use the same ID and the existing
repository upsert replaces its own record. A separately opened draft still gets
a fresh ID. No stored IDs, schemas, queue behavior, limits or save semantics
are changed. Ingredient snapshots and all other diary records are preserved.

Two regressions failed on the previous code and pass after the fix:

- A route rebuild preserves draft identity and typed name. Cancelling writes
  nothing; opening a separate draft creates a different ID.
- A paused native write times out; the route is rebuilt and Save is retried
  before the first write completes. Both actual test-store writes then finish.
  The library contains exactly the original kept template and one new template,
  with the initial draft ID and unchanged ingredients/diary/other keys. Before
  the fix it contained three records, including two duplicate user templates.

Local full analysis, 249 Flutter-/43 Python-tests passed. The merged night-fixture
fix changes no app sources; its complete harness suite passes. Signed APK
4.6.17+31 passes the real applicationId/version/certificate verifier, with the
existing release key. SHA256:
3232a98118aad5bb9e20495cd1ff9692aa2d3ed3e953d3f710e0d54193da6106.

Android 15 update 4.6.16+30 -> 4.6.17+31 and cold launch preserved every
serialized preference entry, including numeric attributes, in four ordinary
and encrypted preference files. A real uniquely named template was saved,
confirmed after cold launch, and deleted through its filtered UI action;
every preference entry then matched the original. No AI calls were made.

The timeout is injected in widget tests, not by stalling or corrupting a
physical device's storage. Physical phone and native iOS are not tested. Full
GitHub CI, including all 12 Android scenarios, remains required before merge.
