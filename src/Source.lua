-- Experiment 17 | Rivals
-- Shared source runtime for logical modules.
-- The old chunks are only a backing source store; feature sections are compiled separately.

local CHUNK_BASE = "https://raw.githubusercontent.com/GasterNoCopyAble/Experiment17_Rivals/main/src/chunks/"
local CHUNKS = {
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

local function getLegacySource()
    if __Experiment17LegacySource then
        return __Experiment17LegacySource
    end

    local parts = table.create(#CHUNKS)
    for i, fileName in ipairs(CHUNKS) do
        local ok, body = pcall(game.HttpGet, game, CHUNK_BASE .. fileName)
        if not ok then
            error(("Experiment17_Rivals: failed to download source chunk %s: %s"):format(fileName, tostring(body)))
        end
        parts[i] = body
    end

    __Experiment17LegacySource = table.concat(parts, "\n")
    return __Experiment17LegacySource
end

local function exportModuleLocals(source)
    local output = table.create(512)
    local index = 0

    for line in (source .. "\n"):gmatch("(.-)\n") do
        if line:sub(1, 15) == "local function " then
            line = "function " .. line:sub(16)
        elseif line:sub(1, 6) == "local " then
            local declaration = line:sub(7)

            -- Only export declarations that actually begin at column zero.
            -- Locals inside normal function bodies remain indented and therefore local.
            if declaration:match("^[%a_][%w_]*") then
                if declaration:find("=", 1, true) then
                    line = declaration
                else
                    -- `local PathFolder` / `local A, B` would become an invalid
                    -- bare expression if we only removed the `local` keyword.
                    line = declaration .. " = nil"
                end
            end
        end

        index += 1
        output[index] = line
    end

    return table.concat(output, "\n")
end

local function findSection(source, startMarker, endMarker)
    local startIndex = 1
    if startMarker then
        startIndex = source:find(startMarker, 1, true)
        if not startIndex then
            error("Experiment17_Rivals: section start marker not found: " .. tostring(startMarker))
        end
    end

    local endIndex = #source + 1
    if endMarker then
        endIndex = source:find(endMarker, startIndex + 1, true)
        if not endIndex then
            error("Experiment17_Rivals: section end marker not found: " .. tostring(endMarker))
        end
    end

    return source:sub(startIndex, endIndex - 1)
end

function CompileLegacySection(moduleName, startMarker, endMarker)
    local source = findSection(getLegacySource(), startMarker, endMarker)
    source = exportModuleLocals(source)

    local chunk, compileError = loadstring(source, "@Experiment17_Rivals/" .. tostring(moduleName))
    if not chunk then
        error(("Experiment17_Rivals: compile error in %s: %s"):format(tostring(moduleName), tostring(compileError)))
    end

    setfenv(chunk, getfenv(1))
    local ok, runtimeError = pcall(chunk)
    if not ok then
        error(("Experiment17_Rivals: runtime error in %s: %s"):format(tostring(moduleName), tostring(runtimeError)))
    end
end
