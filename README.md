# Beat the Bot — v0.2 vertical slice

**Eight moves. One stubborn guard. Convince him to open the gate.**

This repository contains a code-first Roblox vertical slice focused on one polished competitive conversation encounter. The current opponent is deliberately **deterministic local logic, not a live LLM**. That lets us validate the game loop, arena presentation, ranking feedback, rematch behavior, spectator readability, and persistence before introducing model latency and variability.

## What v0.2 adds

- Medieval gatehouse arenas instead of greybox stages.
- Realistic dusk lighting, atmosphere, bloom, torches, local lights, stone/metal/fabric materials.
- Humanoid Castle Guard with a fallback stylized model if avatar creation is unavailable.
- Animated portcullis victory reveal and guard-state highlighting.
- Boss-style HUD with animated Trust and Suspicion meters.
- Strong victory/defeat overlay with ELO change.
- One-click server-authoritative rematch.
- Improved plaza, Humans vs AI board, leaderboard, and champion pedestal.
- The existing server-owned match rules, anti-forgery checks, safe spectator summaries, and persistent profile architecture remain intact.

## Play in Roblox Studio

1. Install Roblox Studio and Rojo 7.7.0. `aftman.toml` pins Rojo.
2. Run:

```sh
mkdir -p build
rojo build default.project.json -o build/BeatTheBot.rbxlx
```

3. Open `build/BeatTheBot.rbxlx` in Roblox Studio.
4. Press **Play**, walk to a glowing console, and activate **Challenge Guard**.
5. Try to beat the Guard, then use the result card to rematch immediately.

The world is generated at runtime. Use a new empty place when serving through Rojo so unrelated template scripts do not interfere.

## Current rules

- You are a courier carrying a sealed delivery permit.
- Establish the entry requirements, present the permit, offer verification, then accept an escort.
- Each correct step earns 25% Trust. **100% Trust wins**, including on move eight.
- Eight unsuccessful moves, 100% Suspicion, 180 seconds, character reset, or leaving mid-match loses.
- Bribes add 25 Suspicion; threats add 40.
- Starting ELO is 1,000; Guard ELO is fixed at 1,000; K=32; floor=100.
- The server owns turns, timers, outcomes, ratings, stats, arena ownership, and rematches.

The fixed puzzle is intentionally learnable. Its ELO is a prototype progression score, not yet a calibrated measure of persuasion skill.

## AI architecture

`AI/LocalAdapter.lua` currently performs bounded intent classification. `AI/Adapter.lua` validates the result against an allowlist. `Core/Rules.lua` alone decides Trust, Suspicion, turns, wins, and losses.

The next AI version should preserve that separation:

```text
player text
   ↓
AI provider interprets intent / tactic
   ↓
validated structured output
   ↓
server Rules scores the move
   ↓
Trust / Suspicion / result
```

The model should never directly award ELO, currency, or victory.

## Saving

Production uses Roblox `DataStoreService`, store `BeatTheBot_Profiles_v1`, keyed by `Player.UserId`. Studio defaults to session-only profiles via `StudioPersistence = false`, so local playtesting cannot accidentally modify production data.

Stored data includes ELO, best ELO, wins, losses, a bounded last-match result, an active-match marker, and a session lease. Raw conversations are not persisted.

## Safety

Typed input is validated and filtered before classification. Raw player text is never broadcast to spectators, stored, logged, or echoed into arena boards. Spectators only see predefined safe move summaries plus developer-authored Guard replies.

No generated model output is enabled yet. Any future AI provider must pass moderation, privacy, latency, cost, abuse, and content-maturity checks before public release.

## Verification

With Luau/Rojo installed:

```sh
luau tests/run.luau
find src -name '*.lua' -exec luau-compile --null '{}' +
mkdir -p build
rojo build default.project.json -o build/BeatTheBot.rbxlx
python3 scripts/verify_build.py build/BeatTheBot.rbxlx
git diff --check
```

For the Roblox-engine smoke test:

```sh
rojo build test.project.json -o build/BeatTheBotSmoke.rbxlx
```

Open that file in Studio and press Play. A successful run prints:

`BEAT_THE_BOT_SMOKE_PASS`

The previous Crystal Rush implementation remains available in Git history at commit `478889db19750074773ec8575debcabf674e21ef`.
