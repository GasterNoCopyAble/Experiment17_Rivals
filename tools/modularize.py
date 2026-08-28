from pathlib import Path
import re
import shutil
import textwrap

CHUNKS = [
    "001.lua.txt", "002.lua.txt", "003.lua.txt", "004.lua.txt", "005.lua.txt", "006.lua.txt",
    "007-008.lua.txt", "009-010.lua.txt", "011-012.lua.txt", "013-014.lua.txt",
    "015-016.lua.txt", "017-018.lua.txt", "019-020.lua.txt", "021-022.lua.txt",
    "023.lua.txt", "024.lua.txt", "025.lua.txt", "026.lua.txt", "027.lua.txt",
]

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
CHUNK_DIR = SRC / "chunks"
source = "\n".join((CHUNK_DIR / name).read_text(encoding="utf-8") for name in CHUNKS)


def marker(title: str) -> str:
    return "--==================================================\n-- " + title + "\n--=================================================="


SECTIONS = [
    ("Core.lua", None, marker("PROXIMITY PROMPTS")),
    ("Prompts.lua", marker("PROXIMITY PROMPTS"), marker("ESP")),
    ("ESP.lua", marker("ESP"), marker("X-RAY")),
    ("XRay.lua", marker("X-RAY"), marker("VISUALS / GRAPHICS / PATH")),
    ("Visuals.lua", marker("VISUALS / GRAPHICS / PATH"), marker("PLAYER MOVEMENT")),
    ("Player.lua", marker("PLAYER MOVEMENT"), marker("AUTO PICKUP")),
    ("Automation.lua", marker("AUTO PICKUP"), marker("SOURCE-INSPIRED CLIENT PROTECTIONS / ROOM 50")),
    ("Protection.lua", marker("SOURCE-INSPIRED CLIENT PROTECTIONS / ROOM 50"), marker("CUSTOM TEXTURES")),
    ("Fun.lua", marker("CUSTOM TEXTURES"), marker("WORLD WATCHERS / BATCHED ROOM PROCESSING")),
    ("World.lua", marker("WORLD WATCHERS / BATCHED ROOM PROCESSING"), marker("GUI: MAIN")),
    ("UI.lua", marker("GUI: MAIN"), marker("CALLBACKS")),
    ("Callbacks.lua", marker("CALLBACKS"), marker("THEME / SAVE")),
    ("Startup.lua", marker("THEME / SAVE"), None),
]


def get_section(start_marker, end_marker):
    start = 0 if start_marker is None else source.find(start_marker)
    if start < 0:
        raise RuntimeError(f"start marker not found: {start_marker}")

    end = len(source) if end_marker is None else source.find(end_marker, start + 1)
    if end < 0:
        raise RuntimeError(f"end marker not found: {end_marker}")

    return source[start:end]


def export_module_locals(text: str) -> str:
    output = []
    for line in text.splitlines():
        if line.startswith("local function "):
            line = "function " + line[len("local function "):]
        elif line.startswith("local "):
            declaration = line[len("local "):]
            if re.match(r"^[A-Za-z_]\w*", declaration):
                line = declaration if "=" in declaration else declaration + " = nil"
        output.append(line)
    return "\n".join(output).rstrip() + "\n"


for filename, start_marker, end_marker in SECTIONS:
    body = export_module_locals(get_section(start_marker, end_marker))
    (SRC / filename).write_text(
        f"-- Experiment 17 | Rivals | {filename}\n"
        "-- Physical logical module. Loaded in the shared Loader.lua environment.\n\n"
        + body,
        encoding="utf-8",
    )

loader = textwrap.dedent(r'''\
-- Experiment 17 | Rivals
-- Physical logical module loader. Each feature is compiled separately.

local BASE = "https://raw.githubusercontent.com/GasterNoCopyAble/Experiment17_Rivals/main/src/"
local MODULES = {
    "Core.lua",
    "Prompts.lua",
    "ESP.lua",
    "XRay.lua",
    "Visuals.lua",
    "Player.lua",
    "Automation.lua",
    "Protection.lua",
    "Fun.lua",
    "World.lua",
    "UI.lua",
    "Callbacks.lua",
    "Startup.lua",
}

local baseEnv = (getgenv and getgenv()) or _G
local previous = rawget(baseEnv, "__Experiment17RivalsContext")
if previous and previous.Library and type(previous.Library.Unload) == "function" then
    pcall(function() previous.Library:Unload() end)
end

local canSetEnv = type(setfenv) == "function"
local Context
if canSetEnv then
    Context = setmetatable({
        __Experiment17Rivals = true,
        __LoadedModules = {},
    }, {
        __index = baseEnv,
        __newindex = rawset,
    })
else
    Context = baseEnv
    Context.__Experiment17Rivals = true
    Context.__LoadedModules = {}
end
baseEnv.__Experiment17RivalsContext = Context

local function loadModule(name)
    local okHttp, body = pcall(game.HttpGet, game, BASE .. name)
    if not okHttp then
        error(("Experiment17_Rivals: failed to download %s: %s"):format(name, tostring(body)))
    end

    local chunk, compileError = loadstring(body)
    if not chunk then
        error(("Experiment17_Rivals: compile error in %s: %s"):format(name, tostring(compileError)))
    end

    if canSetEnv then
        setfenv(chunk, Context)
    end

    local okRun, runtimeError = pcall(chunk)
    if not okRun then
        error(("Experiment17_Rivals: runtime error in %s: %s"):format(name, tostring(runtimeError)))
    end

    Context.__LoadedModules[#Context.__LoadedModules + 1] = name
end

for _, moduleName in ipairs(MODULES) do
    loadModule(moduleName)
end

return Context
''')
(ROOT / "Loader.lua").write_text(loader, encoding="utf-8")

readme = textwrap.dedent(r'''\
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
''')
(ROOT / "README.md").write_text(readme, encoding="utf-8")

source_runtime = SRC / "Source.lua"
if source_runtime.exists():
    source_runtime.unlink()
if CHUNK_DIR.exists():
    shutil.rmtree(CHUNK_DIR)

print("Generated modules:")
for filename, _, _ in SECTIONS:
    path = SRC / filename
    print(f"  {filename}: {path.stat().st_size} bytes")
