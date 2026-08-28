-- Experiment 17 | Rivals | Music.lua
-- Physical logical module; compiled independently by Loader.lua.

--========================================================
-- MUSIC CORE
--========================================================

MusicSound = Instance.new("Sound")
MusicSound.Name = "Experiment17Music"
MusicSound.Volume = 0.5
MusicSound.Looped = false
MusicSound.Parent = SoundService

Playlist = {}
CurrentTrack = 0
MusicWasPlayingBeforeDisable = false

-- Forward-declared because PlayTrack also respects round-only playback.
RoundActive = false

function FormatTime(seconds)
    seconds = tonumber(seconds) or 0

    if seconds ~= seconds or seconds == math.huge then
        seconds = 0
    end

    seconds = math.max(0, math.floor(seconds + 0.5))

    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60

    return string.format("%d:%02d", minutes, secs)
end

function TrackKey(track)
    return tostring(track.kind) .. "|" .. tostring(track.source)
end

function HasTrack(kind, source)
    local key = tostring(kind) .. "|" .. tostring(source)

    for _, track in ipairs(Playlist) do
        if TrackKey(track) == key then
            return true
        end
    end

    return false
end

function SavePlaylist()
    if not FileAPI then
        return
    end

    local serializable = {}

    for _, track in ipairs(Playlist) do
        table.insert(serializable, {
            name = track.name,
            kind = track.kind,
            source = track.source
        })
    end

    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(serializable)
    end)

    if ok then
        pcall(writefile, PlaylistFile, encoded)
    end
end

function NormalizeAssetId(value)
    local text = tostring(value or "")
    local id = text:match("(%d+)")

    if not id then
        return nil
    end

    return id, "rbxassetid://" .. id
end

function TrimMusicPath(path)
    path = tostring(path or "")
    path = path:gsub("^%s+", ""):gsub("%s+$", "")
    path = path:gsub('^"(.*)"$', "%1")
    return path
end

function MusicPathVariants(path)
    path = TrimMusicPath(path)

    local result = {}
    local seen = {}

    local function Add(value)
        value = TrimMusicPath(value)

        if value ~= "" and not seen[value] then
            seen[value] = true
            table.insert(result, value)
        end
    end

    Add(path)

    -- IMPORTANT:
    -- The exact string is always tried first. Only after that do we
    -- try alternate slash styles because executors differ here.
    if path:find("\\", 1, true) then
        Add(path:gsub("\\", "/"))
    end

    if path:find("/", 1, true) then
        Add(path:gsub("/", "\\"))
    end

    local stripped = path
        :gsub("^[Ww]orkspace[/\\]", "")
        :gsub("^%.[/\\]", "")

    Add(stripped)

    if stripped ~= "" then
        Add("workspace/" .. stripped)
        Add("workspace\\" .. stripped)
        Add("Workspace/" .. stripped)
        Add("Workspace\\" .. stripped)
    end

    return result
end

function IsAbsoluteMusicPath(path)
    path = TrimMusicPath(path)

    return path:match("^%a:[/\\]") ~= nil
        or path:sub(1, 1) == "/"
        or path:sub(1, 2) == "\\\\"
end

function JoinMusicPathRaw(folder, entry)
    folder = TrimMusicPath(folder)
    entry = TrimMusicPath(entry)

    if entry == "" then
        return folder
    end

    if folder == "" then
        return entry
    end

    if IsAbsoluteMusicPath(entry) then
        return entry
    end

    local lowerFolder = string.lower(folder)
    local lowerEntry = string.lower(entry)

    -- listfiles() may already return "folder/file.ext".
    if lowerEntry == lowerFolder
        or lowerEntry:sub(1, #lowerFolder + 1) == lowerFolder .. "/"
        or lowerEntry:sub(1, #lowerFolder + 1) == lowerFolder .. "\\" then

        return entry
    end

    -- Keep the separator style of the folder where possible.
    local separator =
        folder:find("\\", 1, true)
        and "\\"
        or "/"

    if folder:sub(-1) == "/"
        or folder:sub(-1) == "\\" then

        return folder .. entry
    end

    return folder .. separator .. entry
end

SupportedAudio = {
    mp3 = true,
    ogg = true,
    wav = true,
    flac = true,
    m4a = true,
    aac = true,
    opus = true
}

function IsSupportedAudioPath(path)
    path = string.lower(TrimMusicPath(path))

    -- Query strings are not expected from listfiles, but strip them
    -- anyway so extension detection stays predictable.
    path = path:gsub("%?.*$", "")

    local ext = path:match("%.([%w]+)$")

    return ext ~= nil
        and SupportedAudio[ext] == true
end

function TryIsFileExact(path)
    if type(isfile) ~= "function" then
        return false
    end

    local ok, result = pcall(isfile, path)

    return ok and result == true
end

function TryIsFolderExact(path)
    if type(isfolder) ~= "function" then
        return false
    end

    local ok, result = pcall(isfolder, path)

    return ok and result == true
end

function ListFilesExact(path)
    if type(listfiles) ~= "function" then
        return nil, "listfiles unavailable"
    end

    local ok, result = pcall(listfiles, path)

    if ok and type(result) == "table" then
        return result, nil
    end

    return nil, ok and "listfiles returned non-table" or tostring(result)
end

function SafeListFiles(folder)
    local errors = {}

    for _, candidate in ipairs(MusicPathVariants(folder)) do
        local entries, err = ListFilesExact(candidate)

        if type(entries) == "table" then
            return entries, candidate, nil
        end

        table.insert(
            errors,
            tostring(candidate) .. " => " .. tostring(err)
        )
    end

    return nil, nil, table.concat(errors, " | ")
end

function ResolveLocalTrack(path)
    if not CustomAsset then
        return nil
    end

    -- Exact listfiles path first.
    for _, candidate in ipairs(MusicPathVariants(path)) do
        local ok, asset = pcall(CustomAsset, candidate)

        if ok and type(asset) == "string" and asset ~= "" then
            return asset
        end
    end

    return nil
end

RefreshMusicHUD = nil

function AddAssetTrack(value)
    local id, soundId = NormalizeAssetId(value)

    if not id then
        Library:Notify("Invalid music asset ID", 3)
        return false
    end

    if HasTrack("asset", id) then
        Library:Notify("Track already exists", 2)
        return false
    end

    table.insert(Playlist, {
        name = "Asset " .. id,
        kind = "asset",
        source = id,
        soundId = soundId
    })

    SavePlaylist()

    if RefreshMusicHUD then
        RefreshMusicHUD()
    end

    return true
end

function AddLocalDiscoveredTrack(path)
    path = TrimMusicPath(path)

    if path == "" or not IsSupportedAudioPath(path) then
        return false, false
    end

    if HasTrack("local", path) then
        return false, false
    end

    local name =
        path:match("[^/\\]+$")
        or path

    -- Do NOT require getcustomasset here.
    local customAsset = ResolveLocalTrack(path)

    table.insert(Playlist, {
        name = name,
        kind = "local",
        source = path,
        soundId = customAsset
    })

    return true, customAsset ~= nil
end


function FilesystemSelfTest()
    local report = {
        makefolder = false,
        writefile = false,
        isfile = false,
        listfiles = false,
        getcustomasset = false,
        listedCount = 0,
        error = nil
    }
    }

    local probeFolder = "Experiment17_FS_TEST"
    local probeFile = probeFolder .. "/probe.txt"

    local okFolder, errFolder = pcall(function()
        if type(isfolder) == "function"
            and not isfolder(probeFolder) then

            makefolder(probeFolder)
        end
    end)

    report.makefolder = okFolder

    local okWrite, errWrite = pcall(function()
        writefile(probeFile, "experiment17")
    end)

    report.writefile = okWrite

    if type(isfile) == "function" then
        local okIsFile, isFileResult = pcall(isfile, probeFile)

        report.isfile =
            okIsFile
            and isFileResult == true
    end

    if type(listfiles) == "function" then
        local okList, result = pcall(listfiles, probeFolder)

        if okList and type(result) == "table" then
            report.listfiles = true
            report.listedCount = #result

            print(
                "[Experiment17 FS TEST] listfiles OK | folder="
                .. probeFolder
                .. " | count="
                .. tostring(#result)
            )

            for i, item in ipairs(result) do
                if i > 20 then
                    break
                end

                print(
                    "[Experiment17 FS TEST] entry "
                    .. tostring(i)
                    .. " = "
                    .. tostring(item)
                )
            end
        else
            report.error =
                "listfiles("
                .. probeFolder
                .. ") => "
                .. tostring(result)

            warn(
                "[Experiment17 FS TEST] "
                .. report.error
            )
        end
    end

    if CustomAsset and report.writefile then
        local okAsset, asset = pcall(
            CustomAsset,
            probeFile
        )

        report.getcustomasset =
            okAsset
            and type(asset) == "string"
            and asset ~= ""

        if not report.getcustomasset then
            print(
                "[Experiment17 FS TEST] getcustomasset probe did not resolve text file; "
                .. "this does not necessarily mean audio files will fail."
            )
        end
    end

    print("========== Experiment17 FS SELF TEST ==========")
    print("makefolder:", report.makefolder)
    print("writefile:", report.writefile)
    print("isfile:", report.isfile)
    print("listfiles:", report.listfiles)
    print("list count:", report.listedCount)
    print("getcustomasset callable:", CustomAsset ~= nil)
    print("getcustomasset probe:", report.getcustomasset)
    print("error:", report.error or "none")
    print("================================================")

    if report.listfiles then
        Library:Notify(
            "Filesystem test: listfiles WORKS. "
            .. "Your selected music-folder path is the next thing to fix.",
            7
        )
    else
        Library:Notify(
            "Filesystem test: listfiles FAILED even on a folder created by the script. "
            .. "Folder scanning cannot work with this executor API. "
            .. "Use Local Track Path instead.",
            10
        )
    end

    return report
end

function AddLocalTrackByPath(path)
    path = TrimMusicPath(path)

    if path == "" then
        Library:Notify("Enter a local audio path first", 3)
        return false
    end

    if not IsSupportedAudioPath(path) then
        Library:Notify(
            "Unsupported extension. Use mp3/ogg/wav/flac/m4a/aac/opus",
            5
        )
        return false
    end

    local resolvedPath = path

    -- If isfile works, prefer whichever exact variant it accepts.
    if type(isfile) == "function" then
        for _, candidate in ipairs(MusicPathVariants(path)) do
            local ok, exists = pcall(isfile, candidate)

            if ok and exists == true then
                resolvedPath = candidate
                break
            end
        end
    end

    if HasTrack("local", resolvedPath) then
        Library:Notify("Track already exists", 2)
        return false
    end

    local soundId = ResolveLocalTrack(resolvedPath)

    if not soundId then
        Library:Notify(
            "getcustomasset could not resolve this path: "
            .. tostring(resolvedPath),
            7
        )
        return false
    end

    local name =
        resolvedPath:match("[^/\\\\]+$")
        or resolvedPath

    table.insert(Playlist, {
        name = name,
        kind = "local",
        source = resolvedPath,
        soundId = soundId
    })

    SavePlaylist()

    if RefreshMusicHUD then
        RefreshMusicHUD()
    end

    Library:Notify(
        "Local track added: " .. tostring(name),
        4
    )

    return true
end

function DebugMusicFolder(folder)
    if type(listfiles) ~= "function" then
        Library:Notify("listfiles() is unavailable", 5)
        return
    end

    folder = TrimMusicPath(folder)

    if folder == "" then
        folder = "Experiment17Music"
    end

    print("========== Experiment17 MUSIC DEBUG ==========")
    print("Requested folder:", folder)

    local anySuccess = false

    for _, candidate in ipairs(MusicPathVariants(folder)) do
        local entries, err = ListFilesExact(candidate)

        if type(entries) == "table" then
            anySuccess = true

            print(
                "[LISTFILES OK]",
                candidate,
                "entries=",
                #entries
            )

            for index, entry in ipairs(entries) do
                if index > 100 then
                    print("... output capped at 100 entries")
                    break
                end

                print(
                    index,
                    "[RAW]",
                    tostring(entry),
                    "[AUDIO]",
                    IsSupportedAudioPath(entry),
                    "[ISFILE]",
                    TryIsFileExact(entry),
                    "[ISFOLDER]",
                    TryIsFolderExact(entry)
                )
            end
        else
            print(
                "[LISTFILES FAIL]",
                candidate,
                tostring(err)
            )
        end
    end

    print("==============================================")

    if anySuccess then
        Library:Notify(
            "Music debug printed raw listfiles() output to console",
            5
        )
    else
        Library:Notify(
            "None of the folder path variants can be opened. Check console.",
            6
        )
    end
end

function ScanMusicFolder(folder)
    if type(listfiles) ~= "function" then
        Library:Notify("listfiles() unavailable", 5)
        return
    end

    folder = TrimMusicPath(folder)

    if folder == "" then
        folder = "Experiment17Music"
    end

    local discovered = {}
    local discoveredSet = {}
    local visited = {}

    local stats = {
        folders = 0,
        entries = 0,
        audio = 0,
        failed = 0,
        added = 0,
        ready = 0,
        unresolved = 0
    }

    local MAX_DEPTH = 10
    local MAX_ENTRIES = 5000

    local function RememberAudio(rawPath)
        rawPath = TrimMusicPath(rawPath)

        if rawPath == ""
            or not IsSupportedAudioPath(rawPath)
            or discoveredSet[rawPath] then

            return
        end

        discoveredSet[rawPath] = true
        table.insert(discovered, rawPath)
        stats.audio += 1
    end

    local function Walk(currentFolder, depth)
        if depth > MAX_DEPTH
            or stats.entries >= MAX_ENTRIES then

            return
        end

        currentFolder = TrimMusicPath(currentFolder)

        if visited[currentFolder] then
            return
        end

        local entries, resolvedFolder, listError =
            SafeListFiles(currentFolder)

        if type(entries) ~= "table" then
            stats.failed += 1

            local failKey =
                tostring(currentFolder)
                .. "|"
                .. tostring(listError or "")

            if not visited["__FAIL__" .. failKey] then
                visited["__FAIL__" .. failKey] = true

                warn(
                    "[Experiment17 MusicScan] listfiles failed | path="
                    .. tostring(currentFolder)
                    .. " | error="
                    .. tostring(listError or "unknown")
                )
            end

            return
        end

        resolvedFolder =
            TrimMusicPath(
                resolvedFolder or currentFolder
            )

        if visited[resolvedFolder] then
            return
        end

        visited[currentFolder] = true
        visited[resolvedFolder] = true
        stats.folders += 1
        stats.entries += #entries

        for _, rawValue in ipairs(entries) do
            if stats.entries >= MAX_ENTRIES then
                break
            end

            local rawEntry = TrimMusicPath(rawValue)

            if rawEntry ~= "" then
                -- Most important rule: trust the exact raw path returned
                -- by listfiles() before constructing anything ourselves.
                local exactFolder =
                    TryIsFolderExact(rawEntry)

                local exactFile =
                    TryIsFileExact(rawEntry)

                if exactFolder then
                    Walk(rawEntry, depth + 1)
                elseif exactFile then
                    RememberAudio(rawEntry)
                elseif IsSupportedAudioPath(rawEntry) then
                    -- Some executors have working listfiles() but flaky
                    -- isfile(). If listfiles returned an audio-looking entry,
                    -- still accept it.
                    RememberAudio(rawEntry)
                else
                    -- Bare filename/folder fallback.
                    local joined =
                        JoinMusicPathRaw(
                            resolvedFolder,
                            rawEntry
                        )

                    if TryIsFolderExact(joined) then
                        Walk(joined, depth + 1)
                    elseif TryIsFileExact(joined) then
                        RememberAudio(joined)
                    elseif IsSupportedAudioPath(joined) then
                        RememberAudio(joined)
                    end
                end
            end
        end
    end

    -- 1) Requested folder.
    Walk(folder, 0)

    -- 2) If that folder opened but contains no audio, or couldn't be
    -- opened at all, search common executor workspace roots.
    if #discovered == 0 then
        local roots = {
            "",
            ".",
            "workspace",
            "Workspace"
        }

        for _, root in ipairs(roots) do
            if stats.entries >= MAX_ENTRIES then
                break
            end

            local entries = select(1, ListFilesExact(root))

            if type(entries) == "table" then
                Walk(root, 0)
            end
        end
    end

    table.sort(discovered, function(a, b)
        return string.lower(a) < string.lower(b)
    end)

    for _, rawPath in ipairs(discovered) do
        local added, ready =
            AddLocalDiscoveredTrack(rawPath)

        if added then
            stats.added += 1

            if ready then
                stats.ready += 1
            else
                stats.unresolved += 1
            end
        end
    end

    SavePlaylist()

    if RefreshMusicHUD then
        RefreshMusicHUD()
    end

    print("========== Experiment17 MUSIC SCAN ==========")
    print("Requested:", folder)
    print("Folders:", stats.folders)
    print("Raw entries:", stats.entries)
    print("Audio discovered:", #discovered)
    print("Added:", stats.added)
    print("getcustomasset ready:", stats.ready)
    print("Retry on play:", stats.unresolved)
    print("Failed folders:", stats.failed)

    for i, rawPath in ipairs(discovered) do
        if i > 100 then
            print("... discovered list capped at 100")
            break
        end

        print("[AUDIO]", rawPath)
    end

    print("=============================================")

    if #discovered == 0 then
        Library:Notify(
            "0 audio found. The script also searched common workspace roots. "
            .. "Press Debug Music Folder and check console for RAW listfiles output.",
            8
        )
    elseif stats.added == 0 then
        Library:Notify(
            "Found "
            .. tostring(#discovered)
            .. " audio file(s), but they are already in the playlist",
            5
        )
    else
        local suffix

        if CustomAsset then
            suffix =
                tostring(stats.ready)
                .. " ready / "
                .. tostring(stats.unresolved)
                .. " retry on play"
        else
            suffix =
                "getcustomasset unavailable; discovery works but playback cannot"
        end

        Library:Notify(
            "Found "
            .. tostring(#discovered)
            .. " | added "
            .. tostring(stats.added)
            .. " | "
            .. suffix,
            8
        )
    end
end

function LoadSavedPlaylist()
    if not FileAPI or not isfile(PlaylistFile) then
        return
    end

    local okRead, raw = pcall(readfile, PlaylistFile)

    if not okRead or type(raw) ~= "string" then
        return
    end

    local okDecode, decoded = pcall(function()
        return HttpService:JSONDecode(raw)
    end)

    if not okDecode or type(decoded) ~= "table" then
        return
    end

    for _, entry in ipairs(decoded) do
        if type(entry) == "table"
            and type(entry.kind) == "string"
            and type(entry.source) == "string" then

            if entry.kind == "asset" then
                local id, soundId = NormalizeAssetId(entry.source)

                if id and not HasTrack("asset", id) then
                    table.insert(Playlist, {
                        name = entry.name or ("Asset " .. id),
                        kind = "asset",
                        source = id,
                        soundId = soundId
                    })
                end
            elseif entry.kind == "local" and CustomAsset then
                if not HasTrack("local", entry.source) then
                    local soundId = ResolveLocalTrack(entry.source)

                    table.insert(Playlist, {
                        name = entry.name or (entry.source:match("[^/\\]+$") or entry.source),
                        kind = "local",
                        source = entry.source,
                        soundId = soundId
                    })
                end
            end
        end
    end
end

function PlayTrack(index)
    if #Playlist == 0 then
        MusicSound:Stop()
        CurrentTrack = 0

        if RefreshMusicHUD then
            RefreshMusicHUD()
        end

        return
    end

    index = math.clamp(index, 1, #Playlist)

    local track = Playlist[index]

    if track.kind == "local" then
        -- Local custom asset URLs can be session-specific, so resolve again
        -- when needed instead of trusting an old cached URL forever.
        if not track.soundId or track.soundId == "" then
            track.soundId = ResolveLocalTrack(track.source)
        end
    end

    if not track.soundId or track.soundId == "" then
        Library:Notify(
            "Track could not be loaded: " .. tostring(track.name),
            4
        )
        return
    end

    CurrentTrack = index

    MusicSound:Stop()
    MusicSound.SoundId = track.soundId
    MusicSound.TimePosition = 0
    MusicSound.Looped = Toggles.MusicLoop and Toggles.MusicLoop.Value or false
    MusicSound.Volume = Options.MusicVolume and Options.MusicVolume.Value or 0.5

    local roundAllowsPlayback =
        (not Toggles.RoundMusic)
        or (not Toggles.RoundMusic.Value)
        or RoundActive

    if Toggles.MusicEnabled
        and Toggles.MusicEnabled.Value
        and roundAllowsPlayback then

        MusicSound:Play()
    end

    if RefreshMusicHUD then
        RefreshMusicHUD()
    end
end

function NextTrack()
    if #Playlist == 0 then
        return
    end

    local nextIndex = CurrentTrack + 1

    if CurrentTrack <= 0 or nextIndex > #Playlist then
        nextIndex = 1
    end

    PlayTrack(nextIndex)
end

function PreviousTrack()
    if #Playlist == 0 then
        return
    end

    local prevIndex = CurrentTrack - 1

    if CurrentTrack <= 0 then
        prevIndex = #Playlist
    elseif prevIndex < 1 then
        prevIndex = #Playlist
    end

    PlayTrack(prevIndex)
end

function DeleteTrack(index)
    if index < 1 or index > #Playlist then
        return
    end

    local deletingCurrent = index == CurrentTrack

    table.remove(Playlist, index)

    if #Playlist == 0 then
        MusicSound:Stop()
        CurrentTrack = 0
    elseif deletingCurrent then
        local replacement = math.clamp(index, 1, #Playlist)
        PlayTrack(replacement)
    elseif index < CurrentTrack then
        CurrentTrack -= 1
    end

    SavePlaylist()

    if RefreshMusicHUD then
        RefreshMusicHUD()
    end
end

--========================================================
-- MUSIC HUD - LINORIA WINDOW STYLE
--
-- This is intentionally drawn like a small Linoria window:
-- square outlines, accent strip, groupbox-like sections,
-- flat buttons, no rounded "mobile card" styling.
--========================================================

MusicGui = Instance.new("ScreenGui")
MusicGui.Name = "Experiment17MusicHUD"
MusicGui.ResetOnSpawn = false
MusicGui.IgnoreGuiInset = true
MusicGui.DisplayOrder = 999999
MusicGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MusicGui.Enabled = true
MusicGui.Parent = LP:WaitForChild("PlayerGui")

function ThemeObject(object, map)
    pcall(function()
        Library:AddToRegistry(object, map, true)
    end)
end

function MakeOutline(parent, size, position, zindex)
    local outline = Instance.new("Frame")
    outline.Size = size
    outline.Position = position
    outline.BackgroundColor3 = Library.OutlineColor
    outline.BorderSizePixel = 0
    outline.ZIndex = zindex or 2
    outline.Parent = parent

    ThemeObject(outline, {
        BackgroundColor3 = "OutlineColor"
    })

    local inner = Instance.new("Frame")
    inner.Size = UDim2.new(1, -2, 1, -2)
    inner.Position = UDim2.fromOffset(1, 1)
    inner.BackgroundColor3 = Library.MainColor
    inner.BorderSizePixel = 0
    inner.ZIndex = (zindex or 2) + 1
    inner.Parent = outline

    ThemeObject(inner, {
        BackgroundColor3 = "MainColor"
    })

    return outline, inner
end

function MakeGroupbox(parent, title, size, position)
    local outer = Instance.new("Frame")
    outer.Size = size
    outer.Position = position
    outer.BackgroundColor3 = Library.OutlineColor
    outer.BorderSizePixel = 0
    outer.ZIndex = 3
    outer.Parent = parent

    ThemeObject(outer, {
        BackgroundColor3 = "OutlineColor"
    })

    local body = Instance.new("Frame")
    body.Size = UDim2.new(1, -2, 1, -2)
    body.Position = UDim2.fromOffset(1, 1)
    body.BackgroundColor3 = Library.BackgroundColor
    body.BorderSizePixel = 0
    body.ZIndex = 4
    body.Parent = outer

    ThemeObject(body, {
        BackgroundColor3 = "BackgroundColor"
    })

    local titleBack = Instance.new("Frame")
    titleBack.AutomaticSize = Enum.AutomaticSize.X
    titleBack.Size = UDim2.fromOffset(12, 14)
    titleBack.Position = UDim2.fromOffset(7, -6)
    titleBack.BackgroundColor3 = Library.BackgroundColor
    titleBack.BorderSizePixel = 0
    titleBack.ZIndex = 6
    titleBack.Parent = outer

    ThemeObject(titleBack, {
        BackgroundColor3 = "BackgroundColor"
    })

    local titleLabel = Instance.new("TextLabel")
    titleLabel.AutomaticSize = Enum.AutomaticSize.X
    titleLabel.Size = UDim2.fromOffset(0, 14)
    titleLabel.Position = UDim2.fromOffset(3, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Library.Font
    titleLabel.TextSize = 12
    titleLabel.TextColor3 = Library.FontColor
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = title
    titleLabel.ZIndex = 7
    titleLabel.Parent = titleBack

    ThemeObject(titleLabel, {
        TextColor3 = "FontColor"
    })

    return outer, body
end

-- Outer window frame.
MusicOuter = Instance.new("Frame")
MusicOuter.Name = "LinoriaMusicWindow"
MusicOuter.Size = UDim2.fromOffset(430, 318)
MusicOuter.Position = UDim2.new(1, -450, 0, 45)
MusicOuter.BackgroundColor3 = Library.OutlineColor
MusicOuter.BorderSizePixel = 0
MusicOuter.Active = true
MusicOuter.Visible = true
MusicOuter.ZIndex = 1
MusicOuter.Parent = MusicGui

ThemeObject(MusicOuter, {
    BackgroundColor3 = "OutlineColor"
})

MusicFrame = Instance.new("Frame")
MusicFrame.Name = "Background"
MusicFrame.Size = UDim2.new(1, -2, 1, -2)
MusicFrame.Position = UDim2.fromOffset(1, 1)
MusicFrame.BackgroundColor3 = Library.BackgroundColor
MusicFrame.BorderSizePixel = 0
MusicFrame.Active = true
MusicFrame.Visible = true
MusicFrame.ZIndex = 2
MusicFrame.Parent = MusicOuter

ThemeObject(MusicFrame, {
    BackgroundColor3 = "BackgroundColor"
})

-- Accent strip identical in spirit to Linoria windows.
MusicAccent = Instance.new("Frame")
MusicAccent.Size = UDim2.new(1, 0, 0, 2)
MusicAccent.Position = UDim2.fromOffset(0, 0)
MusicAccent.BackgroundColor3 = Library.AccentColor
MusicAccent.BorderSizePixel = 0
MusicAccent.ZIndex = 10
MusicAccent.Parent = MusicFrame

ThemeObject(MusicAccent, {
    BackgroundColor3 = "AccentColor"
})

-- Compact top bar, used for dragging.
Header = Instance.new("Frame")
Header.Size = UDim2.new(1, -8, 0, 24)
Header.Position = UDim2.fromOffset(4, 5)
Header.BackgroundTransparency = 1
Header.Active = true
Header.ZIndex = 5
Header.Parent = MusicFrame

MusicTitle = Instance.new("TextLabel")
MusicTitle.Size = UDim2.new(1, -8, 1, 0)
MusicTitle.Position = UDim2.fromOffset(4, 0)
MusicTitle.BackgroundTransparency = 1
MusicTitle.Font = Library.Font
MusicTitle.TextSize = 13
MusicTitle.TextColor3 = Library.FontColor
MusicTitle.TextXAlignment = Enum.TextXAlignment.Left
MusicTitle.Text = "Experiment 17  |  Music"
MusicTitle.ZIndex = 6
MusicTitle.Parent = Header

ThemeObject(MusicTitle, {
    TextColor3 = "FontColor"
})

-- NOW PLAYING group.
_, NowPlaying = MakeGroupbox(
    MusicFrame,
    "Now Playing",
    UDim2.new(1, -10, 0, 120),
    UDim2.fromOffset(5, 35)
)

CurrentTrackLabel = Instance.new("TextLabel")
CurrentTrackLabel.Size = UDim2.new(1, -12, 0, 20)
CurrentTrackLabel.Position = UDim2.fromOffset(6, 9)
CurrentTrackLabel.BackgroundTransparency = 1
CurrentTrackLabel.Font = Library.Font
CurrentTrackLabel.TextSize = 12
CurrentTrackLabel.TextColor3 = Library.FontColor
CurrentTrackLabel.TextXAlignment = Enum.TextXAlignment.Left
CurrentTrackLabel.TextTruncate = Enum.TextTruncate.AtEnd
CurrentTrackLabel.Text = "No track"
CurrentTrackLabel.ZIndex = 7
CurrentTrackLabel.Parent = NowPlaying

ThemeObject(CurrentTrackLabel, {
    TextColor3 = "FontColor"
})

Controls = Instance.new("Frame")
Controls.Size = UDim2.new(1, -12, 0, 24)
Controls.Position = UDim2.fromOffset(6, 34)
Controls.BackgroundTransparency = 1
Controls.ZIndex = 7
Controls.Parent = NowPlaying

function MakeMusicButton(textValue, x, width)
    local outline = Instance.new("Frame")
    outline.Size = UDim2.fromOffset(width, 22)
    outline.Position = UDim2.fromOffset(x, 1)
    outline.BackgroundColor3 = Library.OutlineColor
    outline.BorderSizePixel = 0
    outline.ZIndex = 7
    outline.Parent = Controls

    ThemeObject(outline, {
        BackgroundColor3 = "OutlineColor"
    })

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -2, 1, -2)
    button.Position = UDim2.fromOffset(1, 1)
    button.BackgroundColor3 = Library.MainColor
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Font = Library.Font
    button.TextSize = 11
    button.TextColor3 = Library.FontColor
    button.Text = textValue
    button.ZIndex = 8
    button.Parent = outline

    ThemeObject(button, {
        BackgroundColor3 = "MainColor",
        TextColor3 = "FontColor"
    })

    pcall(function()
        Library:OnHighlight(
            button,
            button,
            {TextColor3 = "AccentColor"},
            {TextColor3 = "FontColor"}
        )
    end)

    return button
end

PrevButton = MakeMusicButton("<", 0, 44)
PlayButton = MakeMusicButton("Play", 49, 58)
NextButton = MakeMusicButton(">", 112, 44)
LoopButton = MakeMusicButton("Loop", 161, 65)
DeleteButton = MakeMusicButton("Delete", 231, 70)

ProgressOutline, Progress = MakeOutline(
    NowPlaying,
    UDim2.new(1, -12, 0, 8),
    UDim2.fromOffset(6, 65),
    7
)

Progress.Active = true

ProgressFill = Instance.new("Frame")
ProgressFill.Size = UDim2.fromScale(0, 1)
ProgressFill.BackgroundColor3 = Library.AccentColor
ProgressFill.BorderSizePixel = 0
ProgressFill.ZIndex = 9
ProgressFill.Parent = Progress

ThemeObject(ProgressFill, {
    BackgroundColor3 = "AccentColor"
})

ElapsedLabel = Instance.new("TextLabel")
ElapsedLabel.Size = UDim2.fromOffset(75, 16)
ElapsedLabel.Position = UDim2.fromOffset(6, 77)
ElapsedLabel.BackgroundTransparency = 1
ElapsedLabel.Font = Library.Font
ElapsedLabel.TextSize = 11
ElapsedLabel.TextColor3 = Library.FontColor
ElapsedLabel.TextXAlignment = Enum.TextXAlignment.Left
ElapsedLabel.Text = "0:00"
ElapsedLabel.ZIndex = 7
ElapsedLabel.Parent = NowPlaying

ThemeObject(ElapsedLabel, {
    TextColor3 = "FontColor"
})

RemainingLabel = Instance.new("TextLabel")
RemainingLabel.AnchorPoint = Vector2.new(1, 0)
RemainingLabel.Size = UDim2.fromOffset(75, 16)
RemainingLabel.Position = UDim2.new(1, -6, 0, 77)
RemainingLabel.BackgroundTransparency = 1
RemainingLabel.Font = Library.Font
RemainingLabel.TextSize = 11
RemainingLabel.TextColor3 = Library.FontColor
RemainingLabel.TextXAlignment = Enum.TextXAlignment.Right
RemainingLabel.Text = "-0:00"
RemainingLabel.ZIndex = 7
RemainingLabel.Parent = NowPlaying

ThemeObject(RemainingLabel, {
    TextColor3 = "FontColor"
})

RoundStatusLabel = Instance.new("TextLabel")
RoundStatusLabel.AnchorPoint = Vector2.new(0.5, 0)
RoundStatusLabel.Size = UDim2.fromOffset(235, 16)
RoundStatusLabel.Position = UDim2.new(0.5, 0, 0, 96)
RoundStatusLabel.BackgroundTransparency = 1
RoundStatusLabel.Font = Library.Font
RoundStatusLabel.TextSize = 11
RoundStatusLabel.TextColor3 = Library.AccentColor
RoundStatusLabel.Text = "ROUND SYNC: OFF | manual / continuous"
RoundStatusLabel.ZIndex = 7
RoundStatusLabel.Parent = NowPlaying

ThemeObject(RoundStatusLabel, {
    TextColor3 = "AccentColor"
})

-- PLAYLIST group.
_, PlaylistBody = MakeGroupbox(
    MusicFrame,
    "Playlist",
    UDim2.new(1, -10, 0, 148),
    UDim2.fromOffset(5, 164)
)

PlaylistScroll = Instance.new("ScrollingFrame")
PlaylistScroll.Size = UDim2.new(1, -10, 1, -10)
PlaylistScroll.Position = UDim2.fromOffset(5, 5)
PlaylistScroll.BackgroundColor3 = Library.BackgroundColor
PlaylistScroll.BorderSizePixel = 0
PlaylistScroll.ScrollBarThickness = 3
PlaylistScroll.ScrollBarImageColor3 = Library.AccentColor
PlaylistScroll.CanvasSize = UDim2.fromOffset(0, 0)
PlaylistScroll.ZIndex = 6
PlaylistScroll.Parent = PlaylistBody

ThemeObject(PlaylistScroll, {
    BackgroundColor3 = "BackgroundColor",
    ScrollBarImageColor3 = "AccentColor"
})

PlaylistLayout = Instance.new("UIListLayout")
PlaylistLayout.Padding = UDim.new(0, 2)
PlaylistLayout.Parent = PlaylistScroll

PlaylistPadding = Instance.new("UIPadding")
PlaylistPadding.PaddingTop = UDim.new(0, 2)
PlaylistPadding.PaddingBottom = UDim.new(0, 2)
PlaylistPadding.PaddingLeft = UDim.new(0, 2)
PlaylistPadding.PaddingRight = UDim.new(0, 2)
PlaylistPadding.Parent = PlaylistScroll

-- Drag window from the title bar only.
MusicDragging = false
MusicDragStart = nil
MusicStartPosition = nil
SeekDragging = false

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        MusicDragging = true
        MusicDragStart = input.Position
        MusicStartPosition = MusicOuter.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if MusicDragging
        and input.UserInputType == Enum.UserInputType.MouseMovement then

        local delta = input.Position - MusicDragStart

        MusicOuter.Position = UDim2.new(
            MusicStartPosition.X.Scale,
            MusicStartPosition.X.Offset + delta.X,
            MusicStartPosition.Y.Scale,
            MusicStartPosition.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        MusicDragging = false
        SeekDragging = false
    end
end)

function SeekToScreenX(screenX)
    local length = MusicSound.TimeLength

    if not length or length <= 0 then
        return
    end

    local left = Progress.AbsolutePosition.X
    local width = Progress.AbsoluteSize.X

    if width <= 0 then
        return
    end

    local ratio = math.clamp(
        (screenX - left) / width,
        0,
        1
    )

    pcall(function()
        MusicSound.TimePosition = ratio * length
    end)
end

Progress.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        SeekDragging = true
        SeekToScreenX(input.Position.X)
    end
end)

UIS.InputChanged:Connect(function(input)
    if SeekDragging
        and input.UserInputType == Enum.UserInputType.MouseMovement then

        SeekToScreenX(input.Position.X)
    end
end)

PrevButton.MouseButton1Click:Connect(PreviousTrack)
NextButton.MouseButton1Click:Connect(NextTrack)

PlayButton.MouseButton1Click:Connect(function()
    if #Playlist == 0 then
        return
    end

    -- Round Music is optional. Outside that mode, this is a normal player.
    if Toggles.RoundMusic
        and Toggles.RoundMusic.Value
        and not RoundActive then

        Library:Notify(
            "Round Music is ON: waiting for the next round",
            3
        )
        return
    end

    if CurrentTrack <= 0 then
        PlayTrack(1)
        return
    end

    if MusicSound.IsPlaying then
        MusicSound:Pause()
    else
        local ok = pcall(function()
            MusicSound:Resume()
        end)

        if not ok then
            MusicSound:Play()
        end
    end
end)

LoopButton.MouseButton1Click:Connect(function()
    if Toggles.MusicLoop then
        Toggles.MusicLoop:SetValue(
            not Toggles.MusicLoop.Value
        )
    end
end)

DeleteButton.MouseButton1Click:Connect(function()
    if CurrentTrack > 0 then
        DeleteTrack(CurrentTrack)
    end
end)

function ClearPlaylistRows()
    for _, child in ipairs(PlaylistScroll:GetChildren()) do
        if child:IsA("Frame")
            and child.Name == "TrackRow" then

            child:Destroy()
        end
    end
end

RefreshMusicHUD = function()
    ClearPlaylistRows()

    for index, track in ipairs(Playlist) do
        local rowOutline = Instance.new("Frame")
        rowOutline.Name = "TrackRow"
        rowOutline.Size = UDim2.new(1, -4, 0, 23)
        rowOutline.BackgroundColor3 = Library.OutlineColor
        rowOutline.BorderSizePixel = 0
        rowOutline.LayoutOrder = index
        rowOutline.ZIndex = 7
        rowOutline.Parent = PlaylistScroll

        ThemeObject(rowOutline, {
            BackgroundColor3 = "OutlineColor"
        })

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -2, 1, -2)
        row.Position = UDim2.fromOffset(1, 1)
        row.BackgroundColor3 = Library.MainColor
        row.BorderSizePixel = 0
        row.ZIndex = 8
        row.Parent = rowOutline

        ThemeObject(row, {
            BackgroundColor3 = "MainColor"
        })

        local selected = Instance.new("Frame")
        selected.Size = UDim2.fromOffset(2, 21)
        selected.BackgroundColor3 = Library.AccentColor
        selected.BorderSizePixel = 0
        selected.Visible = index == CurrentTrack
        selected.ZIndex = 9
        selected.Parent = row

        ThemeObject(selected, {
            BackgroundColor3 = "AccentColor"
        })

        local selectButton = Instance.new("TextButton")
        selectButton.Size = UDim2.new(1, -31, 1, 0)
        selectButton.Position = UDim2.fromOffset(5, 0)
        selectButton.BackgroundTransparency = 1
        selectButton.Font = Library.Font
        selectButton.TextSize = 11
        selectButton.TextColor3 =
            index == CurrentTrack
            and Library.AccentColor
            or Library.FontColor
        selectButton.TextXAlignment = Enum.TextXAlignment.Left
        selectButton.TextTruncate = Enum.TextTruncate.AtEnd
        selectButton.Text =
            string.format(
                "%02d  %s",
                index,
                track.name
            )
        selectButton.ZIndex = 9
        selectButton.Parent = row

        ThemeObject(selectButton, {
            TextColor3 =
                index == CurrentTrack
                and "AccentColor"
                or "FontColor"
        })

        local delete = Instance.new("TextButton")
        delete.AnchorPoint = Vector2.new(1, 0.5)
        delete.Size = UDim2.fromOffset(20, 17)
        delete.Position = UDim2.new(1, -2, 0.5, 0)
        delete.BackgroundColor3 = Library.BackgroundColor
        delete.BorderSizePixel = 0
        delete.AutoButtonColor = false
        delete.Font = Library.Font
        delete.TextSize = 11
        delete.TextColor3 = Library.FontColor
        delete.Text = "x"
        delete.ZIndex = 10
        delete.Parent = row

        ThemeObject(delete, {
            BackgroundColor3 = "BackgroundColor",
            TextColor3 = "FontColor"
        })

        selectButton.MouseButton1Click:Connect(function()
            PlayTrack(index)
        end)

        delete.MouseButton1Click:Connect(function()
            DeleteTrack(index)
        end)
    end

    PlaylistScroll.CanvasSize = UDim2.fromOffset(
        0,
        math.max(0, #Playlist * 25 + 4)
    )

    if CurrentTrack > 0 and Playlist[CurrentTrack] then
        CurrentTrackLabel.Text =
            string.format(
                "%02d/%02d  %s",
                CurrentTrack,
                #Playlist,
                Playlist[CurrentTrack].name
            )
    else
        CurrentTrackLabel.Text =
            #Playlist > 0
            and ("Playlist loaded: " .. tostring(#Playlist) .. " tracks")
            or "No track"
    end

    LoopButton.Text =
        (Toggles.MusicLoop and Toggles.MusicLoop.Value)
        and "Loop [ON]"
        or "Loop"

    MusicGui.Enabled = true

    MusicOuter.Visible =
        not Unloaded
        and (
            not Toggles.ShowMusicHUD
            or Toggles.ShowMusicHUD.Value
        )

    MusicFrame.Visible = true
end

MusicSound.Ended:Connect(function()
    if not MusicSound.Looped then
        NextTrack()
    end
end)

--========================================================
-- ROUND MUSIC DETECTOR - EXACT PATH
--
-- PlayerGui.MainGui.MainFrame.DuelInterfaces.DuelInterface
-- .Top.Timer.Numbers.Full.Value
--
-- Value is expected to be the TextLabel whose Text changes during a round.
-- First text change = round start.
-- No text changes for Round End Delay = round end.
--========================================================

RoundTimerObject = nil
RoundTimerProperty = nil
RoundTimerConnection = nil
RoundActive = false
LastRoundTimerChange = 0
LastRoundTimerValue = nil
LastRoundResolve = 0

function ReadRoundTimerValue(object)
    if not object then
        return nil, nil
    end

    if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
        return tostring(object.Text), "Text"
    end

    if object:IsA("StringValue")
        or object:IsA("IntValue")
        or object:IsA("NumberValue") then

        return tostring(object.Value), "Value"
    end

    local okText, textValue = pcall(function()
        return object.Text
    end)

    if okText then
        return tostring(textValue), "Text"
    end

    local okValue, value = pcall(function()
        return object.Value
    end)

    if okValue then
        return tostring(value), "Value"
    end

    return nil, nil
end

function UpdateRoundHUD()
    if not RoundStatusLabel then
        return
    end

    if not Toggles.RoundMusic or not Toggles.RoundMusic.Value then
        RoundStatusLabel.Text = "ROUND SYNC: OFF | manual / continuous"
        return
    end

    if not RoundTimerObject then
        RoundStatusLabel.Text = "ROUND SYNC: ON | timer not found"
        return
    end

    RoundStatusLabel.Text =
        RoundActive
        and "ROUND SYNC: ACTIVE | playing"
        or "ROUND SYNC: WAITING | paused"
end

function SetRoundActive(active)
    if RoundActive == active then
        UpdateRoundHUD()
        return
    end

    RoundActive = active
    UpdateRoundHUD()

    if not Toggles.RoundMusic or not Toggles.RoundMusic.Value then
        return
    end

    if active then
        if not Toggles.MusicEnabled.Value or #Playlist == 0 then
            return
        end

        if CurrentTrack <= 0 then
            PlayTrack(1)
        elseif not MusicSound.IsPlaying then
            local ok = pcall(function()
                MusicSound:Resume()
            end)

            if not ok then
                MusicSound:Play()
            end
        end
    else
        if MusicSound.IsPlaying then
            MusicSound:Pause()
        end
    end
end

function ResolveRoundTimer()
    local playerGui = LP:FindFirstChild("PlayerGui")
    if not playerGui then return nil end

    local mainGui = playerGui:FindFirstChild("MainGui")
    local mainFrame = mainGui and mainGui:FindFirstChild("MainFrame")
    local duelInterfaces = mainFrame and mainFrame:FindFirstChild("DuelInterfaces")
    local duelInterface = duelInterfaces and duelInterfaces:FindFirstChild("DuelInterface")
    local top = duelInterface and duelInterface:FindFirstChild("Top")
    local timer = top and top:FindFirstChild("Timer")
    local numbers = timer and timer:FindFirstChild("Numbers")
    local full = numbers and numbers:FindFirstChild("Full")

    if not full then
        return nil
    end

    -- Exact object from the user-provided path: Full.Value.
    return full:FindFirstChild("Value") or full
end

function AttachRoundTimer(object)
    if RoundTimerConnection then
        RoundTimerConnection:Disconnect()
        RoundTimerConnection = nil
    end

    RoundTimerObject = object
    RoundTimerProperty = nil
    LastRoundTimerValue = nil
    LastRoundTimerChange = 0
    RoundActive = false

    if not object then
        UpdateRoundHUD()
        return
    end

    local currentValue, property = ReadRoundTimerValue(object)

    if not property then
        RoundTimerObject = nil
        UpdateRoundHUD()
        return
    end

    RoundTimerProperty = property
    LastRoundTimerValue = currentValue

    local signal = object:GetPropertyChangedSignal(property)

    RoundTimerConnection = signal:Connect(function()
        local newValue = select(1, ReadRoundTimerValue(object))

        if newValue == nil or newValue == LastRoundTimerValue then
            return
        end

        LastRoundTimerValue = newValue
        LastRoundTimerChange = os.clock()
        SetRoundActive(true)
    end)

    UpdateRoundHUD()
end

function EnsureRoundTimer()
    local playerGui = LP:FindFirstChild("PlayerGui")

    if RoundTimerObject
        and RoundTimerObject.Parent
        and playerGui
        and RoundTimerObject:IsDescendantOf(playerGui) then

        return
    end

    AttachRoundTimer(ResolveRoundTimer())
end

-- Low-frequency task instead of a Heartbeat player-tree search every frame.
task.spawn(function()
    while not Unloaded do
        task.wait(0.20)

        local now = os.clock()

        if now - LastRoundResolve >= 2 then
            LastRoundResolve = now
            EnsureRoundTimer()
        end

        if RoundActive and LastRoundTimerChange > 0 then
            local delay =
                (Options.RoundStopDelay and Options.RoundStopDelay.Value)
                or 2.25

            if now - LastRoundTimerChange >= delay then
                SetRoundActive(false)
            end
        end
    end
end)
