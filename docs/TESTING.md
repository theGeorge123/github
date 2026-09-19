# Beat the Bot v0.4 verification and release checklist

## Automated CI

The GitHub workflow must execute all of the following on the exact release commit:

1. luau tests/run.luau
2. Compile every Lua/Luau source under src/ and tests/ with luau-compile --null.
3. rojo build default.project.json -o build/BeatTheBot.rbxlx
4. python3 scripts/verify_build.py build/BeatTheBot.rbxlx
5. rojo build test.project.json -o build/BeatTheBotSmoke.rbxlx
6. git diff --check
7. Upload both builds as the BeatTheBot-v0.4-builds artifact.

The pure suite covers rank mapping, ELO district gates, opponent definitions, deterministic match rules, malformed AI decisions, response parsing, prompt-injection-like input, protocol forgery, eight-turn history, profile migration, unknown schema rejection, session locks, ranked rewards, Insight forgery rejection, mastery, cosmetics, Daily Trial reservation, Daily practice isolation, streaks, duplicate-result protection and abandoned-match recovery.

## Studio smoke place

Build test.project.json, open build/BeatTheBotSmoke.rbxlx in Roblox Studio and press Play in a session-only test environment. A successful run prints BEAT_THE_BOT_SMOKE_PASS.

The smoke script exercises the real Roblox services and checks the Citadel build, four ranked spaces plus Daily, future landmarks, VIP Observatory, ranked Great Gate match, forged match-id rejection, deterministic win path, dynamic ELO, Insight/mastery award, duplicate-finish idempotency, Watch ELO rejection, rematch/forfeit, official Daily reservation, Daily ELO isolation, streak write, second-run practice mode and official-result isolation.

Never publish the smoke place.

## Required manual Studio validation

- World/navigation: spawn in Central Plaza; inspect Great Gate, Customs, Watch, Royal Court and Oracle approaches. Check spawn safety, collisions, return paths and void/fall risks.
- District security: below 1100 ELO locally teleport into Customs and attempt ranked play; reject. Repeat Watch below 1250. At each threshold, allow the ranked challenge.
- AI runtime: test capitalization, Unicode, markdown-like output, malformed/missing fields, unknown tactics/strengths, generation failure, filtering failure, prompt injection, contradictory claims, all eight turns and a late response after terminal state. No generation may manufacture competitive state.
- Privacy: multi-client Studio test. Spectators see authored summaries/status only, never raw player messages or private generated replies.
- Match races: replay old submissions, future turns, double submit, double Finish, character reset, disconnect during generation/save, generation timeout, match timeout, arena reuse and rematch spam.
- Persistence: private test place with API access. Migrate a schema-1 fixture, renew leases, reconnect after lease expiry, recover abandonment once, retry an ambiguous successful write and confirm unknown schema data remains untouched.
- Daily Trial: verify UTC rollover, reconnect/server hop after reservation, repeated prompt activation and practice. Official match ID/result remains fixed for the day.
- VIP: non-VIP rejected from Observatory and VIP travel. Placeholder VIP reaches only ELO-unlocked travel destinations. 25% bonus affects Insight only.
- Cosmetics: forged/non-owned equip is rejected; an owned item can be equipped; ownership remains separate from equipped state.
- Desktop UI: 16:9 and narrow desktop. Conversation stays dominant; input/suggestions/result controls remain reachable; long replies wrap and scroll.
- Mobile/tablet UI: phone portrait, landscape and tablet. Test touch prompts, software keyboard, safe area, long text and profile card.
- Performance: inspect part count, rendering, collisions, lighting, particles, memory, script activity and streaming. Confirm no unbounded per-frame server work or accumulating TextGenerator instances/connections.
- Effects: review torch/lantern density, Atmosphere/fog and Watch rain/VFX hooks before adding production particles/audio.
- Shutdown/data: BindToClose releases sessions within budget; persistence failure fails closed rather than continuing with unprotected competitive state.

## Private published-experience checks

Before public release, use a separate private experience/test DataStore configuration and at least two accounts. Verify UserId storage across servers, real Roblox text filtering, TextGenerator runtime behavior, streaming, device UI and current Roblox policy/disclosure requirements for generated dialogue.

## Deliberately deferred

v0.4 does not create a live Robux product, paid Daily retry, global/friends leaderboard, persistent raw chat history or cross-place teleport system. VIP entitlement lookup remains placeholder configuration until monetization is intentionally activated.
