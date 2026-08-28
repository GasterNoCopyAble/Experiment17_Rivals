# Experiment17_Rivals

Actual Rivals build converted from the supplied E17-20260816-1942 script to `Experiment17_GuiLib` Legacy v22.

## Loader

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/GasterNoCopyAble/Experiment17_Rivals/main/Loader.lua"))()
```

## Logical modules

- `src/UICompat.lua` — Legacy v22 compatibility surface
- `src/Core.lua` — services, state, character/team helpers
- `src/Combat.lua` — aimbot, FOV, gaze dodge, camera/anti-aim render
- `src/ESP.lua` — ESP objects and update loop
- `src/Visuals.lua` — particles, X-Ray, graphics presets, FPS boost
- `src/Player.lua` — speed, jump, bunnyhop, strafe, fly
- `src/Music.lua` — playlist, local tracks, HUD and round detector
- `src/UI.lua` — all feature tabs/controls
- `src/MusicRuntime.lua` — music update loop
- `src/Callbacks.lua` — UI state callbacks
- `src/Connections.lua` — player/respawn/world connections
- `src/Config.lua` — config/autoload startup
- `src/Unload.lua` — cleanup and watermark

Each module is a separate Luau prototype; the old `exceeded limit 200` local-register problem is no longer shared across the whole script.
