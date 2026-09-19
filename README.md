# Beat the Bot v0.4 — AI Citadel

Beat the Bot is a Roblox persuasion game in which the player challenges AI characters in a shared medieval citadel. The server owns competitive state; generated dialogue can classify a tactic and reply in character, but it cannot award wins, Trust, Suspicion, ELO, Insight, mastery, cosmetics, entitlements, Daily Trial results, streaks, or district access.

## Core loop

Challenge an AI opponent → persuade successfully → gain ELO, mastery and cosmetic Insight → unlock deeper districts → face harder opponents → return for the Daily Trial and progression.

## AI Citadel

The runtime-generated world is a single route:

Central Plaza → Great Gate → Customs Quarter → Watch District → Royal Court teaser → Oracle Spire teaser.

| District | Access | Status |
| --- | ---: | --- |
| Central Plaza | 0 ELO | Spawn, Daily Trial, status/leaderboards, VIP entry |
| Great Gate | Immediate | Ranked |
| Customs Quarter | 1100 ELO | Ranked |
| Watch District | 1250 ELO | Ranked |
| Royal Court | 1500 ELO | Visual teaser |
| Oracle Spire | 1800 ELO | Visual teaser |

Ranked access is revalidated on the server when a match starts. Teleporting a local character into a locked area does not unlock its ranked challenge.

## Opponents

Great Gate: Sir Aldric, Captain Brann, Warden Elowen.

Customs Quarter: Officer Vale, Clerk Mirelle, Guildmaster Orren.

Watch District: Detective Sera, Inspector Cael, Captain Nyra.

Opponent definitions are data-driven and include district, ELO, unlock requirement, persona, speaking style, hidden concerns, deterministic scoring reactions, objective and visual configuration. Missions include authorization, customs declarations, cooperation and interrogation rather than only opening a gate.

## Progression

Rank titles are data-driven: Outsider, Courier, Envoy, Investigator, Diplomat, Mastermind and AI Breaker.

Each opponent persists attempts, wins, losses, mastery XP, mastery level and best successful message count. Milestones can award profile frames, titles, victory effects and auras.

Insight is a server-owned cosmetic currency. Match completion, wins, first win of the day, Daily Trial and streak/milestone progression can award it. Placeholder VIP receives a 25% Insight multiplier only; it never receives a ranked modifier.

## Daily Trial

The Central Plaza Daily Trial uses a deterministic UTC day key and scenario. One official attempt is reserved server-side per player per UTC day. Reconnects and server hopping cannot create another official attempt. Later runs are practice and cannot overwrite the official result or alter ELO.

Stored official results are leaderboard-ready: result, message count, completion time, final Trust, final Suspicion, opponent and day key. Daily streaks and rewards are idempotent.

## VIP and Founder placeholders

v0.4 deliberately creates no live Marketplace product and charges no Robux.

Server-side placeholder entitlements support the visible VIP Observatory, VIP cosmetics, +25% cosmetic Insight and fast travel to districts the player already unlocked through ELO. Founder implies VIP and can grant a Founder title. VIP cannot alter ELO, Trust, Suspicion, ranked AI difficulty, message limits, official Daily attempts or district progression.

Placeholder user IDs live in Config.Entitlements. Replace that source only after a real entitlement design is reviewed.

## AI and privacy boundary

A match keeps at most eight player/opponent exchanges in memory. Raw history is supplied only to the current AI turn and discarded with the match. It is never stored in the profile and never sent to spectator boards.

Roblox TextGenerator output is constrained to tactic, strength and reply. The parser validates the tactic/strength vocabulary, safely truncates UTF-8 replies and rejects malformed generations. The deterministic Rules module alone changes Trust/Suspicion and determines terminal match state. Generation failures fall back to the deterministic local classifier or consume no move.

## Persistence and authority

The profile store stays on BeatTheBot_Profiles_v1 and migrates schema 1 → schema 2 in place. Unknown/newer schemas are rejected rather than overwritten.

Schema 2 adds Insight, mastery, cosmetic ownership/equipped state, Daily Trial/streak state and reward claims while preserving UpdateAsync, session leases, abandoned-match recovery and idempotent results.

Client RemoteEvents are untrusted. The client has no remote that accepts an ELO, Insight, mastery XP, reward, entitlement, Daily result, streak or district unlock amount.

## Architecture

See docs/ARCHITECTURE.md.

Key modules:

- Core definitions: DistrictDefinitions, OpponentDefinitions, RankDefinitions, RewardDefinitions, CosmeticDefinitions, DailyTrialDefinitions.
- Competitive core: Rules, Protocol, ProfileStore, History.
- Services: ProgressionService, RewardService, MasteryService, DailyTrialService, EntitlementService, FastTravelService, CosmeticService, MatchService, DataService, WorldService.
- AI: Adapter, RobloxAdapter, LocalAdapter, ResponseParser.

## Verification

Pure regression suite:

    luau tests/run.luau

Production build:

    mkdir -p build
    rojo build default.project.json -o build/BeatTheBot.rbxlx
    python3 scripts/verify_build.py build/BeatTheBot.rbxlx

Studio smoke build:

    rojo build test.project.json -o build/BeatTheBotSmoke.rbxlx

CI also syntax-checks every Luau source with the installed Luau runtime and uploads both Rojo place files as the BeatTheBot-v0.4-builds artifact.

Roblox-runtime behavior still requires Studio/private-experience validation. The exact checklist is maintained in docs/TESTING.md; automated CI is not treated as proof of Roblox runtime behavior.

## Release boundary

v0.4 intentionally does not activate Robux monetization, a global/friends leaderboard, or paid extra Daily attempts. It also does not persist raw conversation history. These are deliberate product/security boundaries rather than missing shortcuts.

The senior final audit prompt is in docs/GPT6_FINAL_AUDIT.md.
