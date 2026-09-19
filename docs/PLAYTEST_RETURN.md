# Three-hour return: private playtest gate

Automated CI proves source syntax, pure regression behavior, Rojo packaging and exact script inclusion. It does not prove Roblox runtime behavior, device layout, publishing, moderation or live services.

## 1. Get the reviewed builds

PR #12 is the conflict-free integrated candidate. It supersedes the overlapping feature PRs #2-#6 and #8-#11; do not merge those separately after choosing #12.

Before merge, test the exact green PR #12 artifact from its latest CI run. After merge, test the newest `BeatTheBot-v0.4-builds` artifact from the resulting `main` run as the final release candidate. Never publish `BeatTheBotSmoke.rbxlx`.

Record the tested commit SHA and CI run URL with the screenshots so later commits cannot be mistaken for the build that passed.

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

Fix failures found by the gate before widening scope. Treat onboarding, mobile layout, and reduced-motion behavior as included but unverified until their Studio/device checks pass. Friend challenges, shareable results, multiplayer, monetization, and later worlds remain separate releases.
