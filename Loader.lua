-- Experiment 17 | Rivals
-- Loads the fixed Legacy v22 build from chunked sources.

local BASE = "https://raw.githubusercontent.com/GasterNoCopyAble/Experiment17_Rivals/main/src/chunks/"
local PARTS = {
    "001.lua.txt",
    "002.lua.txt",
    "003.lua.txt",
    "004.lua.txt",
    "005.lua.txt",
    "006.lua.txt",
    "007.lua.txt",
    "008.lua.txt",
}

local source = table.create(#PARTS)
for i, name in ipairs(PARTS) do
    source[i] = game:HttpGet(BASE .. name)
end

local fn, err = loadstring(table.concat(source, "\n"))
if not fn then
    error("Experiment17_Rivals compile error: " .. tostring(err))
end

return fn()
