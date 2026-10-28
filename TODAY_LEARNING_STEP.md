# Today: one optional learning step — 4.6.15+29

Today previously linked to the lesson list without showing which topic remained.
It now shows the first known topic not marked as understood, its existing small
task, and a direct route into that lesson. The original all-topics route and the
Profile lesson list remain available. Once all topics are marked, Today offers
to revisit them rather than inventing another task or demanding daily activity.

Reuse `LearningRepository` and `learning_completed_v1`; there is no second
completion system, date-based reset, streak, reward or new storage key. The
existing lesson mark is voluntary and reversible. It does not imply that a
meal was eaten or that a suggested task was performed. Viewing a topic or
opening the diary never inserts a teaching example or marks progress itself.
There are no changes to nutrients, goals, hunger observations or companion mood.
No new medical claims or course content are introduced.

The step reloads after a direct lesson/all-topics return and after marks change
through Profile, including while Today stays mounted in its IndexedStack.
Unknown later-version IDs remain in storage and do not inflate the known-topic
count. Local read failures have a separate retry; they do not present zero
progress as a successful read or prevent diary use. Fast synchronous errors
are observed before the next FutureBuilder frame. All operations are local.

Four additional widget tests exercise:

- A failed mark retaining the same topic, a successful mark advancing it,
  cold launch retaining it, and Profile undo refreshing the mounted Today card.
- The direct task-to-diary route with no food, mark or settings writes.
- All known topics completed, optional review and preservation of a future ID.
- Two synchronous read failures followed by successful retry on a 320x700
  screen with 1.8 text scale, with stored marks unchanged.

Local analysis and the complete suite passed: 245 Flutter and 31 Python tests,
actionlint and a signed release APK. Application ID and release certificate are
unchanged. Native acceptance passed on the preserved Android 15 AVD: update
4.6.14 -> 4.6.15 retained all 19 entries in four regular/encrypted preference
files. The real task opened the next topic, a mark advanced the topic across
cold launch, and undo restored the original topic. All preference entries and
original marks matched their pre-run contents afterward. No AI calls were made.
Final GitHub CI remains a separate gate. The existing native learning case
is extended to cover the direct task, next topic after cold launch and undo;
all twelve native cases remain in the workflow, with no AI calls.

Android merges the card's non-interactive text into one accessibility node;
actions remain separate. The native helper identifies the heading by its first
line, checks its bounds, then waits for loaded progress before tapping the exact
action. A harness regression covers that actual merged-node shape and a low
heading that needs a small bounded swipe. The Chef keyboard guard from #24 is
also included; it changes only the harness. No app code changed after APK build.

APK SHA256: 813fad7a4c5737c1c99ed3044c51d367d1c283198dd6ffcca99d7c983df8468b.

## Template native write acknowledgement

CI 40740610327 passed release startup but found an empty template library after
its next cold launch. The script immediately force-stopped after tapping Save,
without waiting for SavedMealEditor to await repository.save and pop. It now
uses the exact fully visible enabled Save button and waits for the stable home
FAB/navigation before force-stop. It does not rely on a transient snack-bar or
sleep. The delayed-write harness regression fails on the old premature stop and
passes after acknowledgement (32 combined harness tests). The actual failure
artifact establishes an empty library; an interrupted pending write is the race
removed by this change, not a separately observed production storage error.
App/repository sources and the signed APK are unchanged. A fresh full CI remains
required before integration; the failed run is not treated as passed.
