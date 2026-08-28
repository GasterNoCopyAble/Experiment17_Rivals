# Experiment17_Rivals

Experiment 17 using `Experiment17_GuiLib` Legacy v22.

## Loader

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/GasterNoCopyAble/Experiment17_Rivals/main/Loader.lua"))()
```

## Physical logical modules

- `src/Core.lua` — Legacy v22 bridge, services, common state and helpers
- `src/Prompts.lua` — proximity prompts
- `src/ESP.lua` — ESP, highlights, boxes and tracers
- `src/XRay.lua` — X-Ray
- `src/Visuals.lua` — lighting, graphics styles and Smart Path
- `src/Player.lua` — speed, jump, fly, third person and spectate
- `src/Automation.lua` — automatic pickup
- `src/Protection.lua` — protections, anti-TP and Room 50
- `src/Fun.lua` — textures, sounds and notifications
- `src/World.lua` — room/world watchers and update loops
- `src/UI.lua` — feature UI
- `src/Callbacks.lua` — UI callbacks/state synchronization
- `src/Startup.lua` — config startup, scans and unload cleanup

Every module contains its actual code and is downloaded/compiled separately inside one shared environment. The old monolithic `Out of local registers ... exceeded limit 200` problem is therefore not shared across the whole script.
