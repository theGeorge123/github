# Open the private debate prototype

This branch has a separate Rojo project entry point so it cannot be confused with the Citadel build.

```bash
git fetch origin pull/20/head:debate-prototype
git switch debate-prototype
rojo build debate.project.json -o build/BeatTheBotDebatePrototype.rbxlx
open build/BeatTheBotDebatePrototype.rbxlx
```

If Studio does not open from `open`, open Roblox Studio and use **File > Open from File**, then choose `build/BeatTheBotDebatePrototype.rbxlx`.

Expected proof on launch:
- a 24x20 debate stage, table, backdrop, and Rivet/Pip/Moss;
- compact right-side Play, Chairs, Titles, and Profile menu;
- `PRIVATE • UNRANKED • SESSION ONLY` at top-left;
- scripted rounds permanently labeled `SCRIPTED PRACTICE — NO WINNER OR SCORE`.

This build does not prove live TextGenerator access. The private live probe is still a separate run gate.
