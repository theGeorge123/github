# PR #17 visual capture gate

This is the Stage 0 evidence contract for the visually unverified candidate at commit `89c827d` (`theGeorge123-patch-10`). It does not change runtime code and it does not mark any visual or Roblox-runtime check as passed.

## Candidate identity

- Stack: PR #15 -> PR #16 -> PR #17
- Lifecycle base: PR #16, including server-owned challenge exit and 58 x 48 arena floor
- Capture candidate: PR #17 head `89c827d`
- Green CI run: <https://github.com/theGeorge123/github/actions/runs/35464288161>
- CI artifact: `BeatTheBot-v0.4-builds`, 86.1 KB
- Artifact SHA-256 reported by GitHub: `85b17f2cb287ac625beebb34d805922171a6c06357e7fd6c6acb2adc04da0e31`

Do not capture a different branch or commit and label it as this baseline. Record the Studio place source and confirm the running client Output contains the expected startup lines before capturing.

## One-time setup

1. Check out `theGeorge123-patch-10` at `89c827d`, or download the named artifact from the CI run above.
2. For the production place, build or open `BeatTheBot.rbxlx`. For the smoke test, open `BeatTheBotSmoke.rbxlx`. Never publish the smoke place.
3. Use a clean Play client. Close Output, Explorer, Properties, notifications, and other Studio panels for visual captures. Output may be opened separately for runtime evidence.
4. Use the private tester account only where the test requires it. Do not alter public progression, rewards, entitlements, or production data to create a screenshot.
5. Disable camera-modifying plugins. Leave the game's own camera and controls unchanged.
6. Capture the natural spawn view before manually rotating the camera.

## Manifest

Copy this block into the PR comment or test report and fill every value. Use `PENDING` when evidence is unavailable. Never infer a PASS.

```text
Candidate SHA: 89c827d
Place source: [local production build / CI artifact]
Artifact digest checked: [PASS/PENDING]
Studio version:
OS:
Desktop viewport (pixels):
Desktop FOV:
Desktop graphics qualities: 1, 5, 10
Phone emulator model:
Phone landscape viewport (pixels):
Phone safe area/insets:
Physical phone model:
Physical phone OS:
Physical phone graphics setting:
Test account UserId:
Profile mode: [session-only/private test data]
Capture date/time/timezone:
Tester:
Known deviations:
```

For every hand-positioned view, record:

```text
View ID:
Player HumanoidRootPart CFrame:
CurrentCamera CFrame:
CurrentCamera FieldOfView:
Graphics quality:
Viewport/device:
UI state:
Match state:
Result: [PASS/FAIL/PENDING]
Failure notes:
Screenshot/video filename:
```

Camera and player transforms must come from the running Studio session. Do not copy guessed coordinates from a photograph or this guide.

## Fixed capture matrix

Run every applicable visual row at desktop graphics quality 1, 5, and 10, plus small landscape phone emulation. The natural-spawn row is not hand-positioned. Once a fixed view is recorded, reuse its exact player position, camera transform, FOV, UI state, viewport, and graphics quality for later comparisons.

| ID | State and view | Required evidence | Pass condition |
| --- | --- | --- | --- |
| V01 | Natural spawn, tutorial open | First untouched client frame | Full tutorial and acknowledgement fit inside the safe area; no essential control is clipped |
| V02 | Natural spawn, tutorial dismissed | Same unrotated camera | Connected ground and the first destination or its physical identifier are visible; HUD does not cover it |
| V03 | Arrival terrace, reverse and side | Fixed side and reverse views | The 30 x 26 terrace connects to safe continuous ground; no exposed void on the intended route |
| V04 | Mid-route | Fixed route midpoint facing forward | Floor and boundaries remain distinct; no obstruction, flicker, or competing glow hides the destination |
| V05 | Plaza wide | Fixed wide view | Daily, leaderboard, VIP/travel, and main route have a clear hierarchy; no essential sign is cropped |
| V06 | Plaza sign reading positions | One intended standing position per sign | Accurate essential text fits without zoom; sign has physical support and does not obstruct circulation |
| V07 | Opponent A near and beyond range | Comparable near/far views | Near identity is readable; label is absent beyond configured range and does not show through walls |
| V08 | Opponent B near and beyond range | Same relative distances as V07 | Same conditions as V07 |
| V09 | Opponent C near and beyond range | Same relative distances as V07 | Same conditions as V07 |
| V10 | Three opponents together | Fixed close and medium view | No label pileup or HUD overlap; bodies remain distinguishable from the floor |
| V11 | Long route start/midpoint/threshold | Three fixed views | The next landmark and route remain readable before distant text is legible |
| V12 | Darkest playable surface | Fixed low-contrast location | Floor, boundary, opening, and sky remain separable at graphics quality 1 |
| V13 | Arena overview | Fixed overview plus Studio measurement | The full 58 x 48 floor remains usable; decoration does not reduce the playable footprint |
| V14 | Challenge entered | Normal player camera | Correct arena and match UI appear once; movement/camera are not trapped |
| V15 | Phone keyboard closed/open | Long supported reply in match | Current reply, input, Send, and Exit remain reachable; keyboard dismissal restores layout |

Use PNG or Roblox/OS screenshots rather than a photograph of the monitor when possible. A monitor photograph can document a defect but cannot establish precise exposure, colour, viewport, or safe-area acceptance.

## Protected lifecycle matrix

These are functional Roblox-runtime checks. A screenshot alone is insufficient. Record a short video or step log and the final reusable-arena state.

| ID | Path | Required result | Status |
| --- | --- | --- | --- |
| L01 | Enter -> win -> Back to Plaza -> enter another challenge | Result saves once, character returns, UI clears, slot/console is reusable | PENDING |
| L02 | Enter -> loss -> Back to Plaza -> enter another challenge | Same; closed gate never traps the player | PENDING |
| L03 | Enter -> Exit mid-match -> enter another challenge | Existing server-owned loss/forfeit path runs, persistence finishes, return succeeds, slot is reusable | PENDING |
| L04 | Character reset/disconnect during match | Existing cleanup runs once; no stranded arena or duplicate result | PENDING |
| L05 | Repeated Exit/Back/console input | No duplicate result, teleport, UI, or active-match state | PENDING |

Do not change the lifecycle behavior while performing this capture stage. Any failure blocks visual Stage 1 and belongs in a focused functional fix.

## Performance evidence

After warm-up, run the same 60-second route three times and complete three challenge entry/exit cycles.

Record for desktop and the physical target phone when available:

```text
Run IDs:
Graphics setting:
Median frame time:
p95 frame time:
Memory before/after:
Workspace instance count before/after:
PlayerGui descendant count before/after:
OpponentName BillboardGui count before/after:
Highlight count before/after:
Observed stutter/loading gaps:
Result: [PASS/FAIL/PENDING]
```

Provisional comparison gate for later changes: no repeatable regression greater than 10% in median or p95 frame time versus this exact PR #17 baseline, and no accumulating instances after challenge cycles. This does not make an already inadequate baseline acceptable.

## Stop/go decision

Stage 1 may begin only when all of the following are true:

- the exact `89c827d` production build is identified;
- V01-V15 have evidence or an explicit, justified `PENDING` for unavailable physical-device rows;
- L01-L05 pass in Studio/private testing;
- remaining arrival/HUD defects are named from the new pixels, not from the old monitor photographs;
- no arena-clearance, persistence, progression, entitlement, or exit regression is present.

Stop instead when the build identity is stale or uncertain, a baseline lifecycle check fails, or fixed views cannot be reproduced. If physical-device access is unavailable, finish Studio preparation, keep device rows `PENDING`, and do not claim device verification.

## Non-negotiable boundaries

- Preserve PR #16's server-owned challenge exit lifecycle and 58 x 48 usable arena floor.
- Preserve gameplay anchors, ELO, Daily Trial, rewards, entitlements, private tester policy, and server authority.
- No monetization or Robux changes.
- No publish or merge from this checklist.
- Green CI is code/build evidence, not Studio, device, visual, or performance evidence.
