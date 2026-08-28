from pathlib import Path
import re
import shutil
import subprocess

PARTS = [Path(f"migration/source/{i:03d}.txt") for i in range(1, 9)]
missing = [str(p) for p in PARTS if not p.exists()]
if missing:
    raise RuntimeError("missing source parts: " + ", ".join(missing))

source = "".join(p.read_text(encoding="utf-8") for p in PARTS)


def marker(title: str) -> str:
    return "--========================================================\n-- " + title + "\n--========================================================"


def section(start_title: str, end_title: str | None = None) -> str:
    start_marker = marker(start_title)
    start = source.find(start_marker)
    if start < 0:
        raise RuntimeError("start marker not found: " + start_title)
    if end_title is None:
        return source[start:]
    end_marker = marker(end_title)
    end = source.find(end_marker, start + len(start_marker))
    if end < 0:
        raise RuntimeError("end marker not found: " + end_title)
    return source[start:end]


def export_top_locals(text: str) -> str:
    out: list[str] = []
    for line in text.splitlines():
        if line.startswith("local function "):
            line = "function " + line[len("local function "):]
        elif line.startswith("local "):
            decl = line[len("local "):]
            if re.match(r"^[A-Za-z_]\w*", decl):
                if "=" not in decl:
                    line = decl + " = nil"
                else:
                    line = decl
        out.append(line)
    return "\n".join(out).rstrip() + "\n"


# Reuse the already-tested Legacy v22 Linoria compatibility layer that was
# present immediately before the actual Rivals source replacement.
old_core = subprocess.check_output(
    [
        "git",
        "show",
        "ce1971850489c7d24ef704a12c298c5047156278^:src/Core.lua",
    ],
    text=True,
)
bridge_start = old_core.index(
    "--==================================================\n"
    "-- EXPERIMENT17 GUI LIB v22 / LINORIA COMPATIBILITY"
)
bridge_end = old_core.index(
    "--==================================================\n-- SERVICES / OBJECTS",
    bridge_start,
)
bridge = old_core[bridge_start:bridge_end]
bridge = bridge.replace(
    "Environment = getgenv()",
    "Environment = (getgenv and getgenv()) or _G",
)

# In Linoria, numeric dropdown defaults are 1-based indices. Legacy v22 uses
# the actual string value.
bridge = bridge.replace(
    "local DefaultValue = Config.Default\n"
    "        if IsPlayer and DefaultValue == nil then",
    "local DefaultValue = Config.Default\n"
    "        if type(DefaultValue) == \"number\" then\n"
    "            DefaultValue = Values[DefaultValue]\n"
    "        end\n"
    "        if IsPlayer and DefaultValue == nil then",
)

# Actual Rivals uses Finished input callbacks for music IDs and explicit paths.
bridge = bridge.replace(
    "Wrapper = registerCompatControl(Options, Id, NativeControl, DefaultValue, {\n"
    "        Kind = \"Input\",\n"
    "        Section = self,\n"
    "    })\n\n"
    "    return Wrapper",
    "Wrapper = registerCompatControl(Options, Id, NativeControl, DefaultValue, {\n"
    "        Kind = \"Input\",\n"
    "        Section = self,\n"
    "    })\n\n"
    "    if type(Config.Callback) == \"function\" then\n"
    "        Wrapper:OnChanged(Config.Callback)\n"
    "    end\n\n"
    "    return Wrapper",
)

bridge += r'''

-- Rivals custom music HUD references this small Linoria theme surface.
Library.Font = Enum.Font.Code
Library.FontColor = Color3.fromRGB(235, 235, 235)
Library.AccentColor = Color3.fromRGB(0, 170, 255)
Library.OutlineColor = Color3.fromRGB(5, 5, 5)
Library.BackgroundColor = Color3.fromRGB(18, 18, 18)
Library.MainColor = Color3.fromRGB(28, 28, 28)
Library.KeybindFrame = Library.KeybindFrame or { Visible = true }

function Library:AddToRegistry(Object, Map)
    if not Object or type(Map) ~= "table" then
        return
    end
    for Property, ThemeKey in pairs(Map) do
        local Value = self[ThemeKey]
        if Value ~= nil then
            pcall(function()
                Object[Property] = Value
            end)
        end
    end
end

function Library:OnHighlight(Sensor, Target, EnterMap, LeaveMap)
    Sensor = Sensor or Target
    Target = Target or Sensor
    if not Sensor or not Target then
        return
    end

    local function Apply(Map)
        for Property, ThemeKey in pairs(Map or {}) do
            local Value = self[ThemeKey]
            if Value ~= nil then
                pcall(function()
                    Target[Property] = Value
                end)
            end
        end
    end

    trackCompat(Sensor.MouseEnter:Connect(function()
        Apply(EnterMap)
    end))
    trackCompat(Sensor.MouseLeave:Connect(function()
        Apply(LeaveMap)
    end))
end

CompatWatermark = nil

function Library:SetWatermark(Text)
    if type(NativeLibrary.SetWatermark) == "function" then
        pcall(function()
            NativeLibrary:SetWatermark(Text)
        end)
        return
    end

    if not CompatWatermark or not CompatWatermark.Parent then
        CompatWatermark = Instance.new("TextLabel")
        CompatWatermark.Name = "Experiment17RivalsWatermark"
        CompatWatermark.AutomaticSize = Enum.AutomaticSize.XY
        CompatWatermark.Position = UDim2.fromOffset(8, 8)
        CompatWatermark.BackgroundColor3 = self.BackgroundColor
        CompatWatermark.BackgroundTransparency = 0.15
        CompatWatermark.BorderSizePixel = 0
        CompatWatermark.Font = self.Font
        CompatWatermark.TextSize = 12
        CompatWatermark.TextColor3 = self.FontColor
        CompatWatermark.ZIndex = 100000
        CompatWatermark.Parent = NativeLibrary.Root
    end

    CompatWatermark.Text = "  " .. tostring(Text) .. "  "
end

function Library:SetWatermarkVisibility(Visible)
    if type(NativeLibrary.SetWatermarkVisibility) == "function" then
        pcall(function()
            NativeLibrary:SetWatermarkVisibility(Visible)
        end)
    elseif CompatWatermark then
        CompatWatermark.Visible = Visible == true
    end
end
'''

window = '''Window = Library:CreateWindow({
    Title = "Experiment 17",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

'''

modules: dict[str, str] = {
    "UICompat.lua": bridge,
    "Core.lua": section("SERVICES", "LINORIA") + "\n" + window + section("TABS", "AIMBOT"),
    "Music.lua": section("MUSIC CORE", "COMBAT UI"),
    "Visuals.lua": section("SPHERICAL PARTICLES", "MUSIC CORE"),
    "UI.lua": section("COMBAT UI", "THIRD PERSON INPUT"),
    "Combat.lua": (
        section("AIMBOT", "ESP GUI")
        + "\n"
        + section("THIRD PERSON INPUT", "MOVEMENT: SPEED / JUMP / BHOP / STRAFE / FLY")
        + "\n"
        + section("GAZE DODGE", "ESP LOOP")
    ),
    "ESP.lua": section("ESP GUI", "SPHERICAL PARTICLES")
    + "\n"
    + section("ESP LOOP", "MUSIC UPDATE LOOP"),
    "Player.lua": section("MOVEMENT: SPEED / JUMP / BHOP / STRAFE / FLY", "GAZE DODGE"),
    "MusicRuntime.lua": section("MUSIC UPDATE LOOP", "CALLBACKS"),
    "Callbacks.lua": section("CALLBACKS", "PLAYER CONNECTIONS"),
    "Connections.lua": section("PLAYER CONNECTIONS", "LOAD PLAYLIST BEFORE CONFIG APPLY"),
    "Config.lua": section("LOAD PLAYLIST BEFORE CONFIG APPLY", "UNLOAD"),
    "Unload.lua": section("UNLOAD"),
}

src = Path("src")
src.mkdir(exist_ok=True)
for name, body in modules.items():
    if name != "UICompat.lua":
        body = export_top_locals(body)
    header = (
        "-- Experiment 17 | Rivals | "
        + name
        + "\n-- Physical logical module; compiled independently by Loader.lua.\n\n"
    )
    (src / name).write_text(header + body, encoding="utf-8")

loader = r'''-- Experiment 17 | Rivals
-- Every logical module is downloaded and compiled separately, avoiding Luau's
-- per-prototype local-register limit from the old 5,000+ line monolith.

local BASE = "https://raw.githubusercontent.com/GasterNoCopyAble/Experiment17_Rivals/main/src/"
local MODULES = {
    "UICompat.lua",
    "Core.lua",
    "Music.lua",
    "Visuals.lua",
    "UI.lua",
    "Combat.lua",
    "ESP.lua",
    "Player.lua",
    "MusicRuntime.lua",
    "Callbacks.lua",
    "Connections.lua",
    "Config.lua",
    "Unload.lua",
}

local baseEnv = (getgenv and getgenv()) or _G
local previous = rawget(baseEnv, "__Experiment17RivalsContext")
if previous and previous.Library and type(previous.Library.Unload) == "function" then
    pcall(function()
        previous.Library:Unload()
    end)
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

local function LoadModule(Name)
    local okHttp, Source = pcall(game.HttpGet, game, BASE .. Name)
    if not okHttp then
        error(("Experiment17_Rivals: failed to download %s: %s"):format(Name, tostring(Source)))
    end

    local Chunk, CompileError = loadstring(Source)
    if not Chunk then
        error(("Experiment17_Rivals: compile error in %s: %s"):format(Name, tostring(CompileError)))
    end

    if canSetEnv then
        setfenv(Chunk, Context)
    end

    local okRun, RuntimeError = pcall(Chunk)
    if not okRun then
        error(("Experiment17_Rivals: runtime error in %s: %s"):format(Name, tostring(RuntimeError)))
    end

    Context.__LoadedModules[#Context.__LoadedModules + 1] = Name
end

for _, Name in ipairs(MODULES) do
    LoadModule(Name)
end

return Context
'''
Path("Loader.lua").write_text(loader, encoding="utf-8")

readme = '''# Experiment17_Rivals

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
'''
Path("README.md").write_text(readme, encoding="utf-8")

final_names = set(modules)
for old in [
    "Automation.lua",
    "Fun.lua",
    "Prompts.lua",
    "Protection.lua",
    "Startup.lua",
    "World.lua",
    "XRay.lua",
    "Source.lua",
]:
    p = src / old
    if p.exists() and old not in final_names:
        p.unlink()

chunks = src / "chunks"
if chunks.exists():
    shutil.rmtree(chunks)

migration = Path("migration")
if migration.exists():
    shutil.rmtree(migration)

workflow = Path(".github/workflows/migrate-rivals.yml")
if workflow.exists():
    workflow.unlink()
