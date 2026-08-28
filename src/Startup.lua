-- Experiment 17 | Rivals | Startup.lua
-- Physical logical module. Loaded in the shared Loader.lua environment.

--==================================================
-- THEME / SAVE
--==================================================

-- Legacy v22 owns themes, gradients and config UI. The compatibility objects
-- below route old calls to the native library without loading Linoria addons.
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("Experiment17")
SaveManager:SetFolder("Experiment17/configs")

pcall(function() SaveManager:BuildConfigSection(Tabs["UI Settings"]) end)
pcall(function() ThemeManager:ApplyToTab(Tabs["UI Settings"]) end)
pcall(function() SaveManager:LoadAutoloadConfig() end)

--==================================================
-- INITIAL SCANS
--==================================================


task.spawn(function()
    local Drops = workspace:FindFirstChild("Drops")
    if Drops then CR4.ScanESPContainer(Drops, 120) end
    for _, Object in ipairs(workspace:GetChildren()) do
        local Name = Object.Name
        if Name == "RushMoving" or Name == "AmbushMoving" or Name == "SeekMovingNewClone"
            or Name == "Dread" or Name == "Screech" or Name == "A60" or Name == "A120"
            or Name == "BackdoorLookman" or Name == "BackdoorRush" or Name == "GlitchAmbush" or OtherMonsterNames[Name] then
            CR4.ScanESPContainer(Object, 100)
        end
    end
    CR4.BuildTextureTargetList()
end)
CR4.EnforceVisualState()

pcall(function()
    RunService:BindToRenderStep("LinoriaVisualEnforce", Enum.RenderPriority.Camera.Value + 1000, function()
        if IsUnloading then return end
        if State.Fullbright or State.NoFog or State.NoPostEffects or State.NoShadows
            or State.LowGFX or State.VisualStyle ~= "Off" then
            CR4.EnforceVisualState()
        end
    end)
end)

--==================================================
-- UNLOAD
--==================================================

Library:OnUnload(function()
    if IsUnloading then return end
    IsUnloading = true

    pcall(function() RunService:UnbindFromRenderStep("LinoriaVisualEnforce") end)
    pcall(function() RunService:UnbindFromRenderStep("Experiment17CameraPre") end)
    pcall(function() RunService:UnbindFromRenderStep("Experiment17CameraEnforce") end)
    pcall(function() RunService:UnbindFromRenderStep(AntiScreechBindName) end)

    if A90Active then CR4.EndA90Lock() end
    if ThreatEvadeActive then CR4.ResetThreatEvade() end
    State.AntiTeleport = false
    State.AntiRush = false
    State.AntiAmbush = false
    State.AntiA60 = false
    State.AntiA120 = false
    State.AntiBackdoorRush = false
    State.AntiGlitchAmbush = false
    State.AntiEntityTP = false
    State.AntiScreechDisable = false
    State.AntiDread = false
    State.AntiEyes = false
    State.AntiHalt = false
    State.AntiDupe = false
    State.AntiSnare = false
    State.AntiSeekObstacles = false
    State.Room50AutoCode = false
    CR4.SetClientModuleDisabled("Screech", false)
    CR4.SetClientModuleDisabled("Dread", false)
    CR4.ApplyAntiHalt()
    CR4.ResetFigureProtection()
    CR4.RestoreAntiTouch()
    CR4.StopCharacterSpin()

    CR4.RestorePrompts()
    CR4.RestoreXRay()
    CR4.RestoreVisuals()
    CR4.RestoreWalkSpeed()
    CR4.RestoreJumpSettings()
    CR4.RestoreCameraOptions()
    CR4.RestoreAllTextures()
    CR4.StopSpectate()
    CR4.ClearPathVisual()

    CR4.DisconnectConnection(HumanoidStateConnection)
    CR4.DisconnectConnection(DropsConnection)
    CR4.DisconnectConnection(CameraDescendantConnection)
    for Room, Connection in pairs(RoomConnections) do
        CR4.DisconnectConnection(Connection)
        RoomConnections[Room] = nil
    end
    for Prompt, Connections in pairs(PromptWatchers) do
        for _, Connection in ipairs(Connections) do CR4.DisconnectConnection(Connection) end
        PromptWatchers[Prompt] = nil
    end

    for Target in pairs(ESPEntries) do CR4.DestroyESPEntry(Target) end

    CR4.DisconnectAllConnections()
    CR4.SafeDestroy(ClickSound)
    CR4.SafeDestroy(NotificationSound)
    CR4.SafeDestroy(BackdoorsTimerLabel)
    CR4.SafeDestroy(ExperimentInfoLabel)
    for _,Gui in pairs(MonsterQuestionMarks) do CR4.SafeDestroy(Gui) end
    CR4.SafeDestroy(PathFolder)
    CR4.SafeDestroy(HighlightFolder)
    CR4.SafeDestroy(ESPOverlay)
    CR4.SafeDestroy(FloatingButton)
end)
