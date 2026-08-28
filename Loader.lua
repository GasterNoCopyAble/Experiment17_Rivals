-- Experiment 17 | Rivals
-- Logical module loader. Each feature is compiled separately, so the old
-- monolithic Luau register limit is not shared across the whole script.

local BASE = "https://raw.githubusercontent.com/GasterNoCopyAble/Experiment17_Rivals/main/src/"
local MODULES = {
    "Source.lua",
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
    pcall(function()
        previous.Library:Unload()
    end)
end

if type(setfenv) ~= "function" then
    error("Experiment17_Rivals: executor does not provide setfenv; logical module environment cannot be created")
end

local Context = setmetatable({
    __Experiment17Rivals = true,
    __LoadedModules = {},
}, {
    __index = baseEnv,
    __newindex = rawset,
})

baseEnv.__Experiment17RivalsContext = Context

local function loadModule(name)
    local okHttp, source = pcall(game.HttpGet, game, BASE .. name)
    if not okHttp then
        error(("Experiment17_Rivals: failed to download %s: %s"):format(name, tostring(source)))
    end

    local chunk, compileError = loadstring(source, "@Experiment17_Rivals/" .. name)
    if not chunk then
        error(("Experiment17_Rivals: compile error in %s: %s"):format(name, tostring(compileError)))
    end

    setfenv(chunk, Context)

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
