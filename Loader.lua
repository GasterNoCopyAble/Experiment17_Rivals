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
