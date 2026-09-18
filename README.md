# Crystal Rush

A complete code-first Roblox game built for this repository.

## Game loop

Players enter a floating neon arena, collect crystals for Coins and XP, avoid the rising hazard, and spend Coins on permanent upgrades between rounds.

### Included systems

- Round/intermission loop
- Procedurally generated arena
- Crystal spawning and collection
- Rising hazard / elimination pressure
- Persistent Coins, XP, Wins, and upgrades
- Speed, Jump, and Magnet upgrades
- Server-authoritative purchases and rewards
- Leaderstats
- Responsive HUD and shop UI
- Keyboard/mobile-friendly interaction
- Rojo project configuration
- No external models required for the playable MVP

## Run locally

1. Install Roblox Studio.
2. Install [Rojo](https://rojo.space/) (Rojo 7.x).
3. Clone this repository.
4. In the repository folder run:
   ```bash
   rojo serve
   ```
5. Open a new Baseplate in Roblox Studio.
6. Connect the Rojo Studio plugin to the local server and sync.
7. Press **Play**.

The game world is generated at runtime by the server.

## Roblox Studio settings

For DataStore testing in Studio:

- Publish the experience once.
- In **Game Settings → Security**, enable **Studio Access to API Services**.

If API access is unavailable, the game falls back to a session-only profile so gameplay can still be tested.

## Controls

- Move/jump: standard Roblox controls.
- Walk over crystals to collect them.
- Use the **Upgrades** button in the HUD between or during rounds.
- Upgrade Speed, Jump, or Magnet using Coins.

## Project structure

```text
src/
├── ReplicatedStorage/
│   └── Shared/
│       └── Config.lua
├── ServerScriptService/
│   ├── Bootstrap.server.lua
│   └── Services/
│       ├── CrystalService.lua
│       ├── DataService.lua
│       ├── RoundService.lua
│       ├── UpgradeService.lua
│       └── WorldService.lua
└── StarterPlayer/
    └── StarterPlayerScripts/
        └── Client.client.lua
```

## First release target

This repository is structured as a playable MVP first. The next sensible release layer is content: additional arenas, cosmetic trails, quests, sound/music, badges, game passes, analytics, thumbnails, and live balancing.
