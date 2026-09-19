# Replaceable opponent adapter

## Current implementation

`AI/LocalAdapter.lua` is a pure function: `Decide(context) -> { Intent = string }`.

Input contains filtered `Message`, a read-only match state, and only aggregate `Memory = { Wins, Losses }`. It contains no player name, user ID, secrets, or historical raw messages. Matching uses case-insensitive, word-bounded English phrases and selects at most one intent per turn. Negation, sarcasm, multilingual text, and semantic reasoning are not supported. Quick moves bypass classification through a server-owned allowlist, not through client-provided rewards.

Allowed intents:

`requirements`, `permit`, `verify`, `escort`, `joke`, `bribe`, `threat`, `unknown`.

`AI/Adapter.lua` validates that enum. `Core/Rules.lua` alone determines progress, suspicion, turns, results, and authored dialogue. `Core/ProfileStore.lua` alone applies rating changes. An adapter must never write a profile, call a remote, grant currency, create instances, or return executable code.

`Config.AIProvider` currently accepts only `Local`. Unsupported values fail loudly; there are no pretending-to-work TextGenerator or HTTP placeholders.

## Later: native generation or external model

Add a provider behind the same `Decide` interface after verifying that provider's actual availability, permissions, APIs, costs, and content requirements for the experience. No native TextGenerator access is assumed in this MVP.

Keep these boundaries:

1. Use generation to classify intent or propose roleplay dialogue, not to award a win. Restrict output to a validated schema/enum and bounded lengths.
2. Treat player text and generated responses as untrusted. Ignore instructions to alter rules, reveal secrets, grant rewards, or run tools.
3. Keep secret credentials on a trusted backend or in Roblox server-side secret storage, never in replicated scripts or the public repository. An external gateway should authenticate requests, enforce game allowlists, rate limits, per-user quotas, and a spending ceiling.
4. Limit concurrent requests; set a short generation deadline; discard late replies using match ID and expected turn. The current service already discards work after termination and checks the match deadline after a yielding call, but it is not a complete external-request timeout/circuit-breaker implementation.
5. Preserve free quick moves as the degraded mode. Provider failures must not consume a turn or silently change ranked difficulty.
6. If generated text becomes visible, moderate it before display. Do not turn spectator boards into unrestricted player chat. Verify Roblox's current communication and generative-AI requirements before release.
7. Keep memory small and game-related. Do not upload identifying data or full conversation histories by default. Provide deletion procedures for any additional persistent data.
8. Version opponent rules/provider settings and test them against a fixed evaluation corpus. Model upgrades can change effective difficulty; do not silently mix incomparable ratings in a competitive season.

## Acceptance tests for a new provider

- Equivalent arguments classify consistently; hostile instructions cannot produce an invalid intent or reward.
- One response per turn; retries and delayed responses never double-apply an action.
- Provider outage, timeout, invalid JSON, unsupported enum, and blocked content leave the current turn unconsumed.
- Player disconnect/reset/timeout while generation is in flight cannot revive a finished match.
- No unmoderated output or private data appears in spectators' feeds.
- Evaluate a substantial collection of child-friendly language, misspellings, negation, multiple tactics, and non-English inputs before advertising open-ended AI understanding.
