# Beat the Bot — first playable MVP

**Eight moves. One stubborn guard. Convince him to open the gate.**

A code-first Roblox game with four simultaneous arenas, spectator boards, a server champion avatar, persistent Elo/wins/losses, and returning-player greetings. The opponent is explicitly **deterministic local logic, not a live LLM**. No API key, paid backend, external models, or paid purchases are required.

## Play in Roblox Studio

1. Install [Roblox Studio](https://create.roblox.com/) and [Rojo 7.7.0](https://rojo.space/). `aftman.toml` pins the build tool.
2. Run `rojo build default.project.json -o build/BeatTheBot.rbxlx` (create `build/` first), then open that file in Studio. Alternatively, run `rojo serve` and connect the Rojo Studio plugin to a **new empty place**.
3. Press **Play**, walk to a cyan console, and activate **Challenge Guard**. Four consoles allow four independent matches against the same opponent.
4. Choose quick dialogue moves or type a short English argument. Use **MATCH** to hide/reopen the scrollable panel; hiding does not pause the clock.
5. Watch other matches on their arena boards. The plaza leaderboard ranks connected players; the champion pedestal displays the current leader's avatar when Roblox's avatar service is available.

The world is created at runtime. A new empty place avoids unrelated template scripts/spawns. Nothing is published automatically.

## Rules

- You are a courier carrying a sealed delivery permit. Establish the entry requirements, present the permit, offer verification, then accept an escort.
- Each correct step earns 25% trust. **100% trust wins**, including on move eight.
- **Eight unsuccessful moves, 100% suspicion, 180 seconds, character reset, or leaving mid-match loses.** Bribes add 25 suspicion; threats add 40. Repeated/out-of-order arguments consume moves without adding trust.
- Free-text classification recognizes a small documented English vocabulary, not general meaning. Quick moves are the accessible/reliable alternative. Filtering failures do not consume moves.
- Starting Elo is 1,000; Guard Elo is fixed at 1,000; K=32; floor=100. An even-rating win gives +16; loss gives -16. Rounded gains eventually diminish to zero against this one opponent.
- The server owns turns, timers, outcomes, ratings, stats, and arena ownership. The client cannot submit a score or a victory.
- There are no paid boosts, products, or monetization in this build.

This fixed puzzle is deliberately learnable. Its rating is a prototype progression score, **not a calibrated measure of intelligence or persuasion skill**. Repeated known solutions can inflate it; varied opponents/challenges and ranking calibration are launch follow-ups.

## Saving and memory

Production uses Roblox `DataStoreService`, store `BeatTheBot_Profiles_v1`, keyed by `tostring(Player.UserId)`. Username changes do not lose progress. Stored fields include Elo, peak Elo, wins, losses, a bounded last-match record, an active-match marker, and a session lease. No raw conversations are persisted.

`StudioPersistence = false` makes Studio use clearly labelled **TEST ONLY**, in-memory profiles. These disappear when the Studio server stops. Production never silently falls back to temporary profiles after a storage failure.

To test real persistence, publish a **separate private test experience**, change the store name to a test-specific name, set `StudioPersistence = true`, and enable Studio API access there. Do not point Studio at live player data. Published servers use persistent storage regardless of the Studio flag.

Profile updates use `UpdateAsync`, per-player operation serialization, three request attempts, a 180-second session lease renewed every 45 seconds, and a match ID to prevent duplicate outcomes. Matches are recorded before play begins; a surviving unfinished marker becomes one loss on next successful session acquisition. Shutdown attempts to forfeit and release all sessions within 25 seconds. A hard crash may require waiting up to the lease expiry before rejoining. Prolonged outages may prevent a just-finished result from being saved; the UI never claims confirmation without a successful write, and the documented unfinished-match rule applies.

The Guard remembers aggregate win/loss history and greets returning players; it does **not** remember personal details or arbitrary conversations. See [identity and marketing plan](docs/LAUNCH_AND_IDENTITY.md) for cross-game recognition.

## Safety and spectators

Typed input is server-validated (type, match ID, expected turn, cooldown, UTF-8, 240-byte limit) and passed through Roblox text filtering before classification. Raw player messages are never broadcast, stored, logged, or echoed into a conversation feed. Only predefined move summaries and developer-authored Guard replies reach spectators. The ordinary Roblox chat remains separate.

All rich text is disabled on game text surfaces. No external generated output is enabled. A future model integration requires its own moderation, disclosure, privacy, latency, and abuse checks; see [adapter contract](docs/AI_ADAPTER.md).

## Structure

```text
default.project.json
src/ReplicatedStorage/Shared/Config.lua
src/ServerScriptService/Bootstrap.server.lua
src/ServerScriptService/AI/{Adapter,LocalAdapter}.lua
src/ServerScriptService/Core/{Rules,Protocol,ProfileStore}.lua
src/ServerScriptService/Services/{DataService,MatchService,WorldService}.lua
src/StarterPlayer/StarterPlayerScripts/Client.client.lua
tests/run.luau
tests/StudioSmoke.server.lua
test.project.json
docs/{AI_ADAPTER,TESTING,LAUNCH_AND_IDENTITY}.md
```

The earlier Crystal Rush implementation remains available in Git history at `478889db19750074773ec8575debcabf674e21ef`; its old DataStore is not read, modified, or migrated. Old gameplay modules are removed from the active tree so two games cannot run together.

## Verification

With the official [Luau CLI](https://github.com/luau-lang/luau/releases) installed:

```sh
luau tests/run.luau
find src -name '*.lua' -exec luau-compile --null '{}' +
mkdir -p build
rojo build default.project.json -o build/BeatTheBot.rbxlx
python3 scripts/verify_build.py build/BeatTheBot.rbxlx
git diff --check
```

See [testing checklist](docs/TESTING.md) for Roblox-engine, multiplayer, mobile, and live-saving verification. Command-line tests cannot prove engine/UI behavior or live Roblox storage availability.
