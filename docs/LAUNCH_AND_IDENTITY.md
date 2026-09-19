# Player identity and a small launch plan

## Do we need Supabase?

**Not for this first game.** Roblox persistent storage survives individual game servers, and `Player.UserId` is the identity key rather than a changeable username. Different places within the **same experience** can share the same DataStore. Separately published experiences do not automatically share it. Sources: [Data stores](https://create.roblox.com/docs/cloud-services/data-stores), [Player.UserId](https://create.roblox.com/docs/reference/engine/classes/Player#UserId).

For a connected hub with several mini-games in one experience, stay entirely on Roblox. Coordinate session ownership carefully during teleports; this MVP's single-profile lock may require the old server to release it before the new place can acquire it. Seamless teleport handoff is not implemented here.

For independently published studio games, introduce a shared studio-memory service later. Supabase is one reasonable database option, but not mandatory. Another option is a backend using authorized Roblox Open Cloud DataStore access. Neither makes cross-game sharing automatic.

Suggested future architecture:

```text
Roblox server for Game A ─┐
                         ├─ authenticated studio API ─ shared memory database
Roblox server for Game B ─┘
```

The Roblox server supplies the real `Player.UserId`; never accept a client-asserted identity. Authenticate and authorize each server-side caller, allowlist games, and keep privileged database access behind the API. Supabase secret/service-role keys must never reach a player's client; [Supabase API-key guidance](https://supabase.com/docs/guides/getting-started/api-keys) explains their privileged access.

Keep game-specific competitive stats local to each game's ruleset. Share only bounded studio-level facts, for example:

```text
roblox_user_id: stable ID
visited_games: [beat_the_bot, ai_detective]
achievements: [beat_castle_guard]
last_seen_at: timestamp
memory_schema: 1
```

Game B can then truthfully say: “Welcome back! You beat the Castle Guard in Beat the Bot.” Fetch the player's current display name from Roblox for presentation, not as the database key. No extra player login is needed for this server-to-server design. Do not infer memories from a name or claim achievements without a recorded event.

Do not store personal secrets, emails, ages, voice, or raw conversations for this greeting feature. Before adding a shared service, design retention, account/data deletion, user-facing disclosure, failure fallbacks, and server authentication. This MVP creates no Supabase project and sends no player data externally.

## Is the concept worth testing?

Yes, as a small experiment. The advantage is a clear, watchable challenge with a visible result. The uncertainty is whether players enjoy repeat matches rather than just solving a single puzzle. The first Guard is intentionally simple; do not mistake replaying one known solution for durable retention or calibrated competitive skill.

Recommendation: prove the game loop first, then add varied opponents with distinct evidence/rules, daily seeded challenges, and cosmetic achievement rewards. Only then invest significantly in generation costs, paid acquisition, and studio-wide infrastructure.

## Roblox launch

1. **Private pilot:** invite roughly 20–50 testers as a suggested sample, not an industry benchmark. Observe phone and desktop play. Can they find a console, understand the goal, complete a match, and want another without coaching?
2. **Measure:** first-match starts/completions, second-match rate, time to first move, error rate, D1 returns, and acquisition source. Use Roblox's available dashboards; custom funnel events are a follow-up, not implemented in this build. Segment first-time players from testers and returning players.
3. **Packaging:** clear title, an accurate guard-vs-player thumbnail, readable eight-move counter, and footage of actual gameplay. Do not claim advanced AI understanding, fabricated win rates, free Robux, or features not present.
4. **Organic tests:** invite small Roblox creators to compete in a shared server. Offer a private test session, not a promise of money or endorsement. Disclose paid sponsorships when applicable.
5. **Small paid test only after fixes:** choose a fixed affordable loss limit before launching Sponsored Ads. Test genuinely different creative hooks, then evaluate retained players and repeat matches—not clicks alone. No ads or budgets are created by this repository.
6. **Updates with a reason to return:** a new opponent or fair daily challenge is a better message than “please come back.” Keep assisted practice out of ranked scoring.

Roblox describes engagement, repeat play, and intentional social play among discovery signals. It recommends optimizing retention before scaling acquisition; ads are an experiment, not a guarantee of recommendation traffic. Sources: [Discovery](https://create.roblox.com/docs/production/promotion/discovery), [Analytics](https://create.roblox.com/docs/production/analytics), [Advertising](https://create.roblox.com/docs/production/promotion/advertise).

## TikTok, Shorts, and creator clips

Start with organic videos rather than paid TikTok campaigns. Suggested format: vertical, 15–30 seconds, large captions, one challenge, one payoff. This duration is a creative hypothesis to test, not a guaranteed best practice. Hook within the first few seconds, consistent with [TikTok gaming creative guidance](https://ads.tiktok.com/business/creativecenter/quicktok/online/tiktok-hyper-casual-game-creative-tips/pc/en).

Test three angles:

- **The challenge:** “Eight moves to get past this guard. What would you try?” Show the actual objective, a move, and the result.
- **The rivalry:** “He remembered my last defeat.” Only show the aggregate memory this game really implements.
- **The spectator moment:** show someone winning while friends watch, then the champion display changing. Avoid presenting a staged reaction as spontaneous.

Suggested first two weeks: publish a manageable set of clips (for example 6–10), vary the opening and payoff, and reuse the best footage for YouTube Shorts. Keep music rights and platform rules in mind. Avoid revealing the only winning sequence in every clip; add challenge variety before a larger push.

Assess completion rate, meaningful comments, profile/link interest, and actual Roblox joins/retention where attribution is available. Views alone do not validate the game. Do not promise precise view-to-player attribution without a working measurement setup.

Use age-appropriate marketing. Do not require children to join external platforms, reveal personal information, or make purchases to compete. If community spaces are added, moderation and platform eligibility rules come before growth hacks.

## What to build after testing

Priority order: fix onboarding and mobile friction; add meaningful challenge variation; add reliable funnel measurement; test moderated generation if it improves the game; add cosmetics; add cross-game recognition when a second game exists. No rating sales or paid ranked wins. A practice coach can be a later feature, but its assistance should not contaminate ranked results.
