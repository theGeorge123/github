# Verification and release checklist

## Automated local checks

Run `luau tests/run.luau` using Luau 0.739. Tests exercise ordered wins, turn-eight boundary wins, losses, repeat/out-of-order moves, suspicion, Elo, vocabulary, payload validation, duplicate results, retry ambiguity, locks, abandoned-match recovery, release/rejoin memory, and storage failures. The fake storage runs transaction callbacks twice to catch callback side effects.

Compile every script with `luau-compile --null`, build with Rojo 7.7.0, and run `git diff --check`. These checks do not execute Roblox services.

## Opt-in Studio smoke place

`rojo build test.project.json -o build/BeatTheBotSmoke.rbxlx` builds an isolated test place. Open it in Studio and press Play. `tests/StudioSmoke.server.lua` exercises a win, invalid submissions, and a forfeit using the actual server modules, then prints `BEAT_THE_BOT_SMOKE_PASS`. It runs only in Studio with session-only data. Never publish the smoke place.

The normal `default.project.json` does not include this test script. Smoke actions intentionally move the test player's character and play a match, so use only this separate place.

## Manual Studio checklist

- Start in a fresh place: one world, one HUD, correct spawn, no legacy Crystal Rush scripts.
- Walk to each console and start a match. After a five-second result display it becomes available again.
- Win with requirements → permit → verify → escort; expect 1,016 Elo, one win, open gate, changed leaderboard, and champion avatar if avatar services are available.
- Make eight ineffective moves; expect one loss and a closed gate. Test a last-turn win separately.
- Bribe four times or threaten three times; expect an early loss. Repeated correct moves should not give extra trust.
- Try blank, too-long, and blocked input. Filter failure should use no turn and leave quick choices available; no raw message should appear on a board.
- Start a second match: greeting refers to prior wins/losses without changing the rules.
- Reset, disconnect, and allow the timer to expire; each active match should resolve only once as a loss.
- Hide/reopen the panel while a match runs. Timer continues. Long dialogue remains scrollable.
- Test phone portrait, landscape, touch prompts, small-screen text, keyboard submission, and safe-area insets.
- Use Studio's server/multi-client test with at least two players. They must occupy different arenas; spectator text is authored summaries only. Busy arenas reject extra players. Submissions cannot target someone else's match or replay an old turn.
- Departing champion is replaced; an avatar service error must not block matches or the leaderboard.

## Published private test checklist

- Use a separate private experience and test store. Verify UserId-keyed data survives leaving and rejoining a different server.
- Change display name only if independently desired; confirm code keys are UserId-based without needing a real account rename.
- Confirm ordinary Studio's TEST ONLY mode never writes production data.
- Simulate profile acquisition failure and confirm the game refuses to play rather than overwriting with defaults.
- Test quick reconnect while a lease is held; confirm no two servers can update a profile concurrently.
- Crash with an active marker; after the lease expires, rejoin and verify exactly one recovery loss.
- Confirm successful result retries do not duplicate Elo or wins/losses.
- Confirm text filtering works for real users. Keep normal chat in Roblox's own chat system.
- Review Roblox's current content/maturity/disclosure requirements before publishing publicly, especially before enabling any generated dialogue.

## Known MVP limits

One fixed English puzzle; no semantic LLM, global leaderboard, cross-experience memory, monetization, matchmaking calibration, custom analytics funnel, or multi-place teleport handoff. Session leaderboard and human/Guard totals are labelled as server-only. Crash-recovery losses are reflected in personal data but not retroactively added to another server's match counter.

Storage failures can prevent a terminal result from being confirmed. The game kicks rather than continuing with unprotected data; the next session recovers any remaining active match as a loss. This intentionally prevents disconnect-to-avoid-loss but is not a guarantee against every outage-related loss. Resolve that product trade-off before a serious ranked launch.
