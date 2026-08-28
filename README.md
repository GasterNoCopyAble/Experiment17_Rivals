# Experiment17_Rivals

Experiment 17 using `Experiment17_GuiLib` Legacy v22.

## Loader

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/GasterNoCopyAble/Experiment17_Rivals/main/Loader.lua"))()
```

## Logical modules

The loader no longer concatenates the complete script into one Luau prototype. Every logical module is compiled separately inside one isolated shared environment.

- `src/Core.lua` — GUI compatibility, services, shared state and helpers
- `src/Prompts.lua` — proximity prompts
- `src/ESP.lua` — ESP detection, highlights, boxes and tracers
- `src/XRay.lua` — X-Ray
- `src/Visuals.lua` — lighting, graphics styles and Smart Path
- `src/Player.lua` — movement, jump, fly, third person and spectate
- `src/Automation.lua` — automatic pickup
- `src/Protection.lua` — entity/client protections, Anti TP and Room 50 helpers
- `src/Fun.lua` — custom textures, sounds and notifications
- `src/World.lua` — room/world watchers and update loops
- `src/UI.lua` — feature controls
- `src/Callbacks.lua` — GUI control callbacks and state synchronization
- `src/Startup.lua` — config startup, initial scans and unload cleanup
- `src/Source.lua` — shared source-section runtime

`src/chunks/` is now only the backing source store. It is downloaded once by `Source.lua`; each logical module extracts and compiles only its own section. The full source is never joined and compiled as a single function, avoiding the old `Out of local registers ... exceeded limit 200` failure.

GUI backend: `GasterNoCopyAble/Experiment17_GuiLib` → Legacy v22.
