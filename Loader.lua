-- Experiment 17 | Rivals
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
