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

Local full analysis, 249 Flutter-/39 Python-tests passed. Signed APK and native
upgrade/persistence checks are separate gates whose actual results must be
recorded before integration. The timeout is injected in widget tests, not by
stalling or corrupting a physical device's storage.
