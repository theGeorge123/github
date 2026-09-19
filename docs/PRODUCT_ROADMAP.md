# Beat the Bot product roadmap

This roadmap extends the game without widening the v0.4 release gate. The current build stays focused on making the Citadel's opening route understandable, playable, and worth replaying. It does not activate monetization or ship multiplayer.

## v0.4: finish the Citadel opening

The first session should establish a clear fantasy and route:

1. Arrive at an appealing Central Plaza base.
2. See where progression leads and why the Great Gate matters.
3. Learn Trust, Suspicion, and move limits without leaving the conversation.
4. Meet a memorable first guard with a readable motive and personality.
5. Finish or fail quickly, understand why, and want a different rematch.

Great Gate rematches should rotate among eligible opponents when possible. Different opponents must reward different approaches; replay value must not come from merely changing a name or portrait.

The current release gate remains the automated suite plus direct Studio and device checks in `docs/PLAYTEST_RETURN.md`. A green build does not prove visual quality, navigation, mobile usability, or Roblox-runtime behavior.

## Character contract

Every authored character, in every world, needs an explicit gameplay identity:

- personality and worldview;
- a distinct voice and speech rhythm;
- an immediate goal;
- a fear or cost they are trying to avoid;
- a vulnerability or contradiction the player can discover;
- persuasion triggers that build Trust;
- taboos or tactics that raise Suspicion;
- an objective tied to the character's job in the hierarchy;
- visible or environmental cues that support, but do not give away, the solution.

These fields must affect scoring reactions and dialogue. No single tactic should be optimal against every character. New characters should be added through data definitions and regression cases before bespoke service logic is considered.

## World structure

Each level is a complete themed world with its own social hierarchy, starting base, route, escalating access, characters, and final authority figure. A world is not just a reskin or one conversation.

### World 1: AI Citadel

Guard / gate staff -> servants and officials -> princess or royal court -> king.

The existing Great Gate, Customs Quarter, Watch District, Royal Court, and Oracle route can grow into this hierarchy while preserving public ELO gates and the current competitive loop.

### World 2: Hospital

Reception and security -> nurses and specialists -> senior physician or administrator -> hospital director. Challenges should center on triage, policy, evidence, consent, and competing duties rather than copying Citadel dialogue.

### World 3: Politics

Staff and local officials -> advisers and ministers -> party leadership -> head of government. Challenges should center on coalitions, public commitments, policy tradeoffs, and reputation. Avoid real-person imitation and current-campaign claims by default.

### World 4: Business

Front desk and team leads -> managers and directors -> executive suite -> chief executive or owner. Challenges should center on incentives, risk, negotiation, proof, and organizational politics.

### Later worlds: AI and mythology

AI and mythology can support stranger rules and higher-stakes persuasion after the core world template has proven it can retain players. Their mechanics should be specified separately rather than folded into the first release.

## Later: two-player persuasion and deception

Competitive multiplayer is a separate release. Before implementation, define:

- who speaks first and how turn order stays fair;
- hidden information and what each player may disclose or bluff about;
- scoring, draws, forfeits, reconnects, and race prevention;
- privacy and spectator boundaries;
- text filtering, moderation, reports, and abuse handling;
- whether ELO is shared with solo play or isolated;
- mobile timing and accessibility.

Do not bolt player-versus-player text onto the solo match service until these rules and threat boundaries have tests.

## Sequencing

1. Validate the v0.4 Citadel opening in Studio and on real phone layouts.
2. Fix visual, navigation, onboarding, and first-guard friction found there.
3. Measure first-match completion and immediate rematch behavior with a private tester group.
4. Deepen Citadel hierarchy and character-specific counterplay.
5. Prove a reusable world template with the Hospital world.
6. Design multiplayer as its own tested mode.
7. Consider monetization only after pricing, entitlements, failures, and competitive fairness receive a separate review.
