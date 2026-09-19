# AI release gate

Beat the Bot uses Roblox-native `TextGenerator` for typed free-form persuasion. The model interprets the player's tactic and writes an in-character reply, but it **never owns the score**.

## Server authority

The generation layer may only return:

- an allowed tactic enum;
- `weak`, `normal`, or `strong`;
- one short roleplay reply.

`Core/Rules.lua` owns Trust, Suspicion, objectives, turn limits, wins, and losses. `ProfileStore.lua` owns ELO changes. Invalid or malformed model output consumes no move.

## Safety and audience

The current game intentionally keeps AI interaction bounded to eight moves / three minutes. During a match, the Guard may receive the full prior match transcript (up to eight turns) for continuity and contradiction detection. That raw conversation context is discarded with the match and is not persisted across matches or sessions.

The UI visibly discloses that the opponent is AI-powered and may make mistakes. Player input is filtered before generation. Model replies are filtered again before they are shown to the interacting player. Spectator boards receive only server-authored summaries/replies, not raw player text or generated free-form dialogue.

Before any public release:

1. Re-check Roblox's current generative-AI and content-maturity requirements.
2. Complete the Creator Hub content-maturity questionnaire accurately.
3. Run the Studio smoke place and confirm `BEAT_THE_BOT_SMOKE_PASS`.
4. Test typed AI turns with multiple real accounts and age settings.
5. Confirm generated text filtering failures degrade safely without consuming turns.
6. Confirm no raw user conversation is written to DataStore, analytics, logs, or spectator boards.
7. Confirm ELO cannot be changed by client payloads or model output.
8. Review AI win rates per Guard before calling the ranking calibrated.

## Automated checks

Every push to `main` runs GitHub Actions:

- pure Luau regression tests;
- production Rojo build;
- exact-source verification of the built place;
- smoke-place build;
- whitespace validation.

A green CI check does **not** replace Studio runtime testing. Roblox-engine APIs such as `TextGenerator`, filtering, avatars, DataStore, lighting, and GUI behavior must still be tested inside Studio / a private published experience.
