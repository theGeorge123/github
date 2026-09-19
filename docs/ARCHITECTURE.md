# Beat the Bot v0.4 architecture

## Trust boundary

The server is authoritative for every competitive or economic write. TextGenerator can return only a conversational tactic, strength and reply. Rules maps an accepted tactic to deterministic Trust/Suspicion and win/loss state. ProfileStore is the persistence boundary for ELO, Insight, mastery, cosmetics and Daily state.

The client is hostile by default. It may submit text/choice for the exact next turn, request a rematch, or request that an item ID be equipped. It never supplies award amounts, ownership, ELO, entitlement state or a Daily score.

## Layer map

Data/configuration:
- DistrictDefinitions: Citadel order, ELO thresholds, ranked arena mapping and travel eligibility.
- OpponentDefinitions: nine opponents with rating, district, unlock, persona, hidden concerns, objective, scoring reactions and visual hints.
- RankDefinitions: ELO to title.
- RewardDefinitions: Insight, mastery and streak rewards.
- CosmeticDefinitions: static and generated mastery cosmetics.
- DailyTrialDefinitions: deterministic day key to scenario.
- EntitlementPolicy: pure no-pay-to-win checks.

Competitive core:
- Protocol validates match ID, next turn, kind, byte bound, UTF-8 and controls.
- Rules owns deterministic Trust/Suspicion/state transitions and ELO.
- History owns current-match-only eight-turn memory.
- ProfileStore owns schema migration, UpdateAsync leases, active-match marker and idempotent reward/result writes.

Runtime:
- DataService serializes profile writes and publishes safe status values.
- MatchService owns lifecycle, filtering, AI calls, arena slots, ranked district validation and Daily modes.
- RewardService is the single match reward calculator.
- MasteryService projects mastery levels and milestone cosmetics.
- DailyTrialService creates UTC day key/ordinal and official-vs-practice mode.
- ProgressionService maps profile state to ranks/district access.
- EntitlementService owns placeholder VIP/Founder checks.
- FastTravelService validates VIP plus normal ELO before moving a character.
- CosmeticService resolves item category server-side and validates ownership before equip.
- WorldService builds the Citadel, challenge spaces and spectator-safe boards.
- TelemetryService emits non-sensitive gameplay telemetry.

## Remote protocol

State is server to client only for match/status notices.

Submit accepts MatchId, exact next Turn, Kind and Value; Protocol validates it before processing.

Rematch carries no result; server state decides what restarts.

EquipCosmetic accepts only an item ID. Server definitions resolve category and profile ownership before persistence.

Daily Trial and fast travel originate from server-owned ProximityPrompt callbacks. No client remote can select reward amounts, set a Daily result or teleport to arbitrary coordinates.

## AI and memory

MatchService owns in-memory History. History.Push clamps it to Config.MaxTurns, eight messages/exchanges. The table is passed only to the current AI match and disappears with the match object.

The AI prompt treats player/history text as untrusted, bans nonexistent physical-item requests, includes scenario/objective/hidden concern and prohibits generated competitive decisions. ResponseParser admits only allowed tactic and strength values and safely truncates UTF-8 replies.

Generated text is filtered for the participant before display. Spectator boards receive deterministic summaries/fallback text, never raw private dialogue.

## Ranked transaction

1. Server prompt calls MatchService.Start.
2. ProgressionService validates profile ELO against arena district even if a client moved the character locally.
3. Server selects an eligible district opponent.
4. ProfileStore writes ActiveMatch before gameplay opens.
5. Each turn is filtered/validated; AI classifies; Rules advances.
6. RewardService derives rewards from server match state.
7. ProfileStore applies result/rewards once under match:<id>.
8. Arena releases after result display.
9. A later session recovers an abandoned active marker as exactly one loss.

## Daily Trial transaction

DailyTrialService derives UTC day key and ordinal. A player with no reservation for that day gets mode Daily; otherwise DailyPractice.

The Begin UpdateAsync transaction reserves OfficialDay and OfficialMatchId before official gameplay. Reconnect/server-hop/repeated activation converges on that stored reservation.

Official finish writes result, messages, completion time, final Trust/Suspicion, opponent and day, then advances streak. Practice is unranked and never overwrites DailyTrial.Result. There is no paid extra official attempt.

## Profile schema 2

Schema 2 preserves schema-1 ELO/history fields and adds Insight, per-opponent Mastery, Inventory.Owned, Equipped, DailyTrial and RewardClaims.

Migration accepts schema 1 or current schema only. Unknown/newer schemas return nil and are never replaced with defaults.

## VIP boundary

v0.4 has no Marketplace purchase. Placeholder VIP/Founder IDs are configured server-side and exposed only as presentation attributes.

VIP supports Observatory entry, cosmetics, a 25% cosmetic Insight multiplier and fast travel to already ELO-unlocked districts. VIP does not alter Rules, ELO calculation, Trust/Suspicion, AI difficulty, message count, official Daily reservation or district requirements.

## World/performance shape

Reusable towers, walls, gates, paths, banners, torches, lanterns, market/cargo and Watch structures create district silhouettes instead of arbitrary part multiplication. Royal Court and Oracle Spire are visual teasers. Ambient/VFX hook folders are present; Watch rain is a hook rather than an always-on particle storm.

No per-frame world server loop is needed. Match timeout checks run once per second and the leaderboard refreshes every five seconds. The HUD uses Heartbeat only for local countdown display.

## Deferred interfaces

The status card is structured around a snapshot so a future inspected-player transport can reuse it, but v0.4 does not expose an other-player profile request protocol.

Global/friends Daily leaderboards, a VIP unlocked-opponent practice selector, production audio/rain assets and live Robux lookup are intentionally deferred. Their trust/data boundaries exist without pretending Studio runtime verification has occurred.
