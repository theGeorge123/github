# Three-hour return: private playtest gate

Automated CI proves source syntax, pure regression behavior, Rojo packaging and exact script inclusion. It does not prove Roblox runtime behavior, device layout, publishing, moderation or live services.

## 1. Get the reviewed builds

Review and merge only green PRs in this order:

1. Private tester access and world boundary.
2. Mobile-first HUD and keyboard polish.
3. Later onboarding/accessibility PRs only after their own checks pass.

Download the newest `BeatTheBot-v0.4-builds` artifact from the merged main CI run. Never publish `BeatTheBotSmoke.rbxlx`.

## 2. Studio smoke gate

Open `BeatTheBotSmoke.rbxlx` in Roblox Studio and press Play. The Output window must print:

    BEAT_THE_BOT_SMOKE_PASS

Any red error, infinite yield, world-build warning or missing pass marker blocks release.

## 3. Private playable build

Open `BeatTheBot.rbxlx` in Studio. Use phone portrait, phone landscape and desktop emulation.

For account `paggaking321` (UserId `1753929845`), verify:

- Central Plaza loads and the goal is understandable without outside instructions.
- Great Gate, Customs Quarter and Watch District matches all start despite the tester's ELO.
- Royal Court and Oracle Spire remain visual teasers, not playable bypasses.
- A different test account at 1000 ELO is still blocked from Customs and Watch.
- Trust and Suspicion changes are visible after every move.
- Suggestions and free text both work; text filtering failure does not consume a turn.
- Win, loss, rematch, timeout, reset and disconnect release the arena.
- Daily Trial allows one official result and later practice does not change ELO.

## 4. Mobile gate

On a real phone if possible, not only Studio emulation:

- All touch targets are easy to hit without overlap.
- The software keyboard does not cover the input, Send button or latest reply.
- Long opponent replies wrap and scroll; the result screen remains reachable.
- Trust, Suspicion, moves and time remain readable in portrait and landscape.
- No visible clipping occurs around safe areas or the top bar.
- Frame rate and input remain responsive while the generated world is visible.

Capture screenshots of the match screen in phone portrait, phone landscape and desktop. A visual reviewer should approve the actual pixels before public release.

## 5. Private-experience gate

Use a separate private experience and test DataStore configuration. With at least two accounts, verify real filtering, TextGenerator behavior, persistence, reconnect/server hop, spectator privacy and session locks. Do not use production player data for this gate.

## 6. Release blockers

Do not call the game public-release ready until all are true:

- Studio smoke and manual gameplay gates pass.
- Phone pixels and keyboard behavior are visually checked.
- Real filtering, generated dialogue and persistence pass in a private experience.
- Experience name, icon, thumbnail, description, age guidance, disclosure and moderation settings are reviewed in Creator Dashboard.
- Monetization remains off until product IDs, pricing and entitlement checks have separate approval and tests.

## After the playable gate

Sequence larger work behind the stable build: onboarding polish, accessibility and low-effects settings, then friend challenges and shareable results. Keep each change reviewable and green rather than combining the release surface with untested social features.
