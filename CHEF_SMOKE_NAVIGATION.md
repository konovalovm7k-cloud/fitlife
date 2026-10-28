# Chef Android smoke: wait for the catalogue

The post-integration main run 40722460141 and PR #23 run 40723134489 passed
their build/server jobs and the first ten native cases, then failed to find
the Chef entry. The saved failure screenshot/XML shows the meal-ideas list at
the bottom; the entry is at its top. There is no application crash in that
screen. This is separate from the fully successful release PR #22 CI.

`MealIdeasPage` first displays a loading indicator while its local catalogue
future completes. `open_chef` previously started a downward-only search
immediately after navigation. A swipe during that transition can scroll the
arriving list beyond Chef; subsequent downward swipes cannot recover it.

Wait for the loaded page's heading and Chef entry before searching for the
exact enabled, clickable, fully visible button. Keep the existing viewport
bounds, bounded searches, all eleven native cases and the final pantry-input
readiness assertion. No new delays, weakened checks or AI requests are added.

The regression uses the real polling and viewport helpers against a delayed
catalogue screen: an early swipe loses the entry exactly as in the CI artifact.
It fails on the previous harness and passes after the fix without any swipe on
the loading page. The disabled-input test continues to reject an unusable Chef.

Local verification on 28 October 2026: 236 Flutter tests, 24 harness tests,
clean Flutter analysis/actionlint and a signed main 4.6.12 release APK build.
The actual no-connection Chef scenario
also passed on the preserved Android 15 emulator with installed signed 4.6.13:
input retention, shared settings and the 210 g / 113 kcal local half-portion
fallback. No app sources, storage format, version or signing configuration
change in this patch. CI rebuilds and exercises the main 4.6.12 APK; its result
must be recorded separately before integration.

## Restored keyboard on return from settings

Run 40733974203 passed the previously failing Chef entry and reached the later
fallback action after settings. Its failure screenshot shows the pantry keyboard
restored by focus. The list is above the keyboard, but the generic swipe starts
at two-thirds of the full display height, inside the keyboard. It therefore
cannot reveal the fallback button below the form. This is a different failure
from the initial catalogue-loading race; the full run still failed.

After returning from settings and verifying the retained pantry text, inspect
Android's `mInputShown` state. Send Back only if the IME is actually shown, then
perform the existing exact visible-button check. With a hidden IME, no Back is
sent, so the Chef route cannot accidentally be popped. Two additional harness
tests cover both cases (26 total). No app-source or viewport changes are needed.
