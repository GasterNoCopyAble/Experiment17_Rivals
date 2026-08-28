-- Experiment 17 | Rivals
-- Legacy v22 build loader.

local BASE = "https://raw.githubusercontent.com/GasterNoCopyAble/Experiment17_Rivals/main/src/chunks/"
local PARTS = {
    "001.lua.txt",
    "002.lua.txt",
    "003.lua.txt",
    "004.lua.txt",
    "005.lua.txt",
    "006.lua.txt",
    "007-008.lua.txt",
    "009-010.lua.txt",
    "011-012.lua.txt",
    "013-014.lua.txt",
    "015-016.lua.txt",
    "017-018.lua.txt",
    "019-020.lua.txt",
    "021-022.lua.txt",
    "023.lua.txt",
    "024.lua.txt",
    "025.lua.txt",
    "026.lua.txt",
    "027.lua.txt",
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
