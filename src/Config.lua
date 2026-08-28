-- Experiment 17 | Rivals | Config.lua
-- Physical logical module; compiled independently by Loader.lua.

--========================================================
-- LOAD PLAYLIST BEFORE CONFIG APPLY
--========================================================

LoadSavedPlaylist()
RefreshMusicHUD()

--========================================================
-- CONFIGS
--========================================================

if FileAPI then
    local ok, err = pcall(function()
        ThemeManager:SetLibrary(Library)
        SaveManager:SetLibrary(Library)

        SaveManager:IgnoreThemeSettings()

        SaveManager:SetIgnoreIndexes({
            "MenuKeybind",
            "MusicIdInput",
            "LocalTrackPath",
            "ShowMusicHUD"
        })

        ThemeManager:SetFolder("Experiment17")
        SaveManager:SetFolder("Experiment17/Main")

        SaveManager:BuildConfigSection(Tabs.Settings)
        ThemeManager:ApplyToTab(Tabs.Settings)

        SaveManager:LoadAutoloadConfig()
    end)

    if not ok then
        warn("[Experiment 17 Config Error]", err)
        Library:Notify("Config error - check console", 5)
    end
else
    local ConfigBox =
        Tabs.Settings:AddRightGroupbox(
            "Config Status"
        )

    ConfigBox:AddLabel(
        "File API unavailable.\n"
        .. "Linoria configs and playlist persistence cannot survive restarts.",
        true
    )
end

--========================================================
-- APPLY AUTOLOADED VALUES
--========================================================

task.defer(function()
    task.wait(0.3)

    ApplyGraphics()
    UpdateParticles()

    MusicSound.Volume = Options.MusicVolume.Value
    MusicSound.Looped = Toggles.MusicLoop.Value

    -- Old configs could contain ShowMusicHUD=false. Do not let an old
    -- config make the player disappear after an update.
    pcall(function()
        Toggles.ShowMusicHUD:SetValue(true)
    end)

    MusicGui.Enabled = true
    MusicOuter.Visible = true
    MusicFrame.Visible = true

    EnsureRoundTimer()
    UpdateRoundHUD()

    if Toggles.XRay.Value then
        EnableXRay()
    end

    if Toggles.FPSBoost.Value then
        EnableFPS()
    end

    RefreshMusicHUD()
end)
