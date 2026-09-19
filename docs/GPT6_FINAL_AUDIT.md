# Beat the Bot v0.4 — Final 20% Production Audit

Act as the final senior Roblox engineer, security reviewer, systems architect, QA lead and release-readiness owner for Beat the Bot.

Approximately 80% of v0.4 AI Citadel has already been implemented. Do not reinvent the product. Locate and fix the difficult final 20%: correctness, race conditions, exploit surfaces, Roblox API mistakes, migration bugs, persistence failures, AI edge cases, world-performance issues, mobile/UI failures and missing test coverage.

Start by reading the entire repository and mapping the architecture before editing. Pay particular attention to ProfileStore, MatchService, RewardService, DailyTrialService, EntitlementService, FastTravelService, CosmeticService, WorldService, the AI adapters/parser, the client HUD, tests/run.luau and StudioSmoke.server.lua.

## Non-negotiable product rules

1. AI never directly controls Trust, Suspicion, wins, losses, ELO, Insight, mastery, rewards, entitlements or district access.
2. ELO is skill progression and cannot be purchased.
3. VIP cannot provide ranked competitive advantage.
4. The official Daily Trial cannot gain paid additional scored attempts.
5. Raw AI conversation history is bounded to the current eight-message match and is not persisted.
6. Spectators never receive raw private dialogue.
7. Every competitive/economic write is server authoritative.
8. All RemoteEvent arguments are untrusted.
9. Reward and persistence operations must be idempotent.
10. Never claim a test passed unless you actually executed it.

## Architecture

Find circular dependencies, duplicated state, giant/unrelated modules, unsafe shared mutable state, lifecycle bugs, cleanup/event leaks and test-hostile dependencies. Refactor only when correctness or maintainability improves.

## AI

Test malformed TextGenerator format, capitalization, markdown wrappers, missing fields, unknown tactics, invalid strengths, long replies, Unicode, prompt injection, attempts to award ELO/currency, attempts to override instructions, generation timeout/failure, filtering failure, late response after match end, duplicate response, full eight-turn context and contradiction handling.

Malformed generation must never grant competitive state.

## Match state

Attempt forged match IDs, stale/future turns, replayed submissions, double Finish, disconnect during save, disconnect during generation, generation timeout, character reset, arena reuse race and rematch spam.

## Persistence

Verify schema-1 migration, unknown-schema rejection, leases, stale session handling, crash/reconnect, abandoned-match loss, duplicate result writes, mastery idempotency, Insight idempotency, inventory consistency, equipped-item validity, Daily Trial idempotency and streak correctness across UTC day boundaries. Test ambiguous UpdateAsync retries.

## Daily Trial

Prove one official scored attempt per UTC day; reconnect, server hop and repeated activation do not reset it; practice never overwrites official score; result is server-generated and leaderboard-ready; date calculations are deterministic/documented. Never add a paid official retry.

## Economy/rewards

Attempt to forge Insight, mastery XP, ownership, milestone claims, equipped cosmetics, VIP and Founder. Client cannot manufacture any. Confirm VIP 25% multiplier affects cosmetic Insight only.

## ELO/world gates

Attempt local teleport, walking around visual barriers, respawning deeper, VIP travel to locked districts, forged destination IDs and stale ELO. Physical presence must never make a locked ranked start valid.

## VIP

Verify server-side entitlement, non-VIP Observatory rejection, unranked practice, travel only to already-unlocked districts, cosmetic ownership checks and Founder placeholder. No VIP path may influence ELO, Trust, Suspicion, AI difficulty, ranked messages or official Daily attempts. Do not create a live Marketplace product.

## World/performance

Audit part count, collisions, anchoring, transparent parts, lighting, particles, loops, Heartbeat/RenderStepped work, generation cost, duplicate Instances, TextGenerator lifecycle, memory leaks, streaming suitability, spawn safety and void risks. Optimize without destroying the Citadel visual identity.

## UI

Test 16:9 desktop, narrow desktop, phone portrait, phone landscape and tablet. Chat stays dominant; only conversation scrolls in normal play; input/suggestions remain reachable; status/profile UI and result overlay do not hide required controls; long replies must not break layout.

## Tests

Expand regression coverage for opponents, AI parser/fallback, eight-turn memory, ELO, ranks, gates, mastery, Insight, rewards, inventory, Daily Trial, streaks, entitlements, VIP, travel, migration, locks, rematch, forged protocol requests and world initialization.

Run every available automated test.

Build build/BeatTheBot.rbxlx and build/BeatTheBotSmoke.rbxlx. Run Studio smoke checks only if a real Roblox Studio runtime is available. Do not replace runtime verification with assumptions.

## Final deliverable

Fix every reasonable issue found, then report final commit SHA, exact tests executed, pass/fail counts, production build result, smoke build result, unresolved issues, remaining manual Studio tests, security assumptions, known performance risks, launch blockers, and evidence-based suitability for internal testing, 10 external testers, 100 external testers and public release.

Do not give a readiness level without repository/test evidence. Do not count a Rojo build as a Studio runtime test.
