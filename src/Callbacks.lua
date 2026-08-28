-- Experiment 17 | Rivals | Callbacks.lua
-- Physical logical module. Loaded in the shared Loader.lua environment.

--==================================================
-- CALLBACKS
--==================================================

function CR4.RefreshTrackedPrompts()
    for Prompt in pairs(PromptRegistry) do
        if Prompt and Prompt.Parent then CR4.UpdatePrompt(Prompt) end
    end
end

Toggles.PromptExpander:OnChanged(function()
    State.PromptExpander = Toggles.PromptExpander.Value
    CR4.RefreshTrackedPrompts()
end)

Toggles.FastPrompts:OnChanged(function()
    State.FastPrompts = Toggles.FastPrompts.Value
    CR4.RefreshTrackedPrompts()
end)

Toggles.PromptThroughWalls:OnChanged(function()
    State.PromptThroughWalls = Toggles.PromptThroughWalls.Value
    CR4.RefreshTrackedPrompts()
end)
Toggles.RemovePaintingPrompts:OnChanged(function()
    State.RemovePaintingPrompts = Toggles.RemovePaintingPrompts.Value
    CR4.RefreshTrackedPrompts()
end)

PromptSliderMap = {
    PromptTimeDoor = "Door", PromptTimeHide = "Hide", PromptTimeGold = "Gold", PromptTimeKey = "Key",
    PromptTimeLockpick = "Lockpick", PromptTimeItem = "Item", PromptTimeChest = "Chest",
    PromptTimeDrawer = "Drawer", PromptTimeObjective = "Objective", PromptTimeOther = "Other",
}
for OptionName, Key in pairs(PromptSliderMap) do
    Options[OptionName]:OnChanged(function()
        PromptTimes[Key] = Options[OptionName].Value
        if State.FastPrompts then CR4.RefreshTrackedPrompts() end
    end)
end

Toggles.ESPNames:OnChanged(function() State.ESPNames = Toggles.ESPNames.Value end)
Toggles.ESPDistance:OnChanged(function() State.ESPDistance = Toggles.ESPDistance.Value end)
Options.TracerOrigin:OnChanged(function() State.TracerOrigin = Options.TracerOrigin.Value end)
Options.ESPMaxDistance:OnChanged(function() State.ESPMaxDistance = Options.ESPMaxDistance.Value end)
Options.ESPThickness:OnChanged(function() State.ESPThickness = Options.ESPThickness.Value end)
Options.ESPVerticalOffset:OnChanged(function() State.ESPVerticalOffset = Options.ESPVerticalOffset.Value end)
Options.ESPFPS:OnChanged(function() State.ESPFPS = Options.ESPFPS.Value end)
Options.ESPFillTransparency:OnChanged(function()
    State.ESPFillTransparency = math.clamp(Options.ESPFillTransparency.Value / 100, 0, 1)
    CR4.RefreshESPEntries()
end)

Toggles.XRay:OnChanged(function()
    State.XRay = Toggles.XRay.Value
    RefreshXRay()
end)
Options.XRayMode:OnChanged(function() State.XRayMode = Options.XRayMode.Value; RefreshXRay() end)
Options.XRayTransparency:OnChanged(function()
    State.XRayTransparency = math.clamp(Options.XRayTransparency.Value / 100, 0, 1)
    RefreshXRay()
end)

Toggles.LowGFX:OnChanged(function()
    State.LowGFX = Toggles.LowGFX.Value
    StyleDirty = true
    if State.LowGFX then CR4.ApplyLowGFXGlobal() else CR4.RestoreLowGFX() end
    CR4.EnforceVisualState()
end)
Toggles.Fullbright:OnChanged(function()
    State.Fullbright = Toggles.Fullbright.Value
    StyleDirty = true
    if not State.Fullbright and State.VisualStyle == "Off" then
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.Ambient = OriginalLighting.Ambient
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.ExposureCompensation = OriginalLighting.ExposureCompensation
    end
    CR4.EnforceVisualState()
end)
Toggles.NoFog:OnChanged(function()
    State.NoFog = Toggles.NoFog.Value
    StyleDirty = true
    if not State.NoFog then
        Lighting.FogStart = OriginalLighting.FogStart
        Lighting.FogEnd = OriginalLighting.FogEnd
        CR4.RestoreAtmosphere()
    end
    CR4.EnforceVisualState()
end)
Toggles.NoPostEffects:OnChanged(function()
    State.NoPostEffects = Toggles.NoPostEffects.Value
    StyleDirty = true
    if not State.NoPostEffects and not State.LowGFX then CR4.RestorePostEffects() end
    CR4.EnforceVisualState()
end)
Toggles.NoShadows:OnChanged(function()
    State.NoShadows = Toggles.NoShadows.Value
    if State.NoShadows then CR4.ScanVisualObjectsAsync() else CR4.RestoreShadows() end
    CR4.EnforceVisualState()
end)
Options.VisualStyle:OnChanged(function()
    State.VisualStyle = Options.VisualStyle.Value
    StyleDirty = true
    if State.VisualStyle == "Off" then CR4.ClearStyleEffects() end
    CR4.EnforceVisualState()
end)

Toggles.SmartPath:OnChanged(function()
    State.SmartPath = Toggles.SmartPath.Value
    if State.SmartPath then CR4.UpdateSmartPath(true) else CR4.ClearPathVisual() end
end)
Options.PathTargetMode:OnChanged(function() State.PathTargetMode = Options.PathTargetMode.Value; if State.SmartPath then CR4.UpdateSmartPath(true) end end)
Options.PathRecompute:OnChanged(function() State.PathRecompute = Options.PathRecompute.Value end)
Options.PathMaxDistance:OnChanged(function() State.PathMaxDistance = Options.PathMaxDistance.Value; if State.SmartPath then CR4.UpdateSmartPath(true) end end)
Options.PathColor:OnChanged(function()

    State.PathColor = Options.PathColor.Value
    for _, Object in ipairs(PathFolder:GetChildren()) do if Object:IsA("BasePart") then Object.Color = State.PathColor end end
end)

Toggles.WalkSpeedEnabled:OnChanged(function()
    State.WalkSpeedEnabled=Toggles.WalkSpeedEnabled.Value
    if not State.WalkSpeedEnabled and not State.BunnyHop then CR4.RestoreWalkSpeed() else CR4.ApplyWalkSpeed() end
end)
Options.SpeedMethod:OnChanged(function() State.SpeedMethod=Options.SpeedMethod.Value; CR4.DestroySpeedBodyVelocity(); CR4.ApplyWalkSpeed() end)
Options.WalkSpeedValue:OnChanged(function() State.WalkSpeed=math.clamp(Options.WalkSpeedValue.Value,0,21); CR4.ApplyWalkSpeed() end)
Toggles.SeekSpeedhack:OnChanged(function() State.SeekSpeedhack=Toggles.SeekSpeedhack.Value; CR4.ApplyWalkSpeed() end)
Options.SeekSpeedValue:OnChanged(function() State.SeekSpeed=math.clamp(Options.SeekSpeedValue.Value,22,28); CR4.ApplyWalkSpeed() end)
Toggles.MicroTPEnabled:OnChanged(function() State.MicroTPEnabled=Toggles.MicroTPEnabled.Value end)
Options.MicroTPDistance:OnChanged(function() State.MicroTPDistance=Options.MicroTPDistance.Value end)
Options.MicroTPInterval:OnChanged(function() State.MicroTPInterval=Options.MicroTPInterval.Value end)
Toggles.FlyEnabled:OnChanged(function() State.FlyEnabled=Toggles.FlyEnabled.Value; if not State.FlyEnabled then CR4.DestroyFlyObjects() end end)
Options.FlyMethod:OnChanged(function() State.FlyMethod=Options.FlyMethod.Value; CR4.DestroyFlyObjects() end)
Options.FlySpeed:OnChanged(function() State.FlySpeed=Options.FlySpeed.Value end)

Toggles.JumpEnabled:OnChanged(function() State.JumpEnabled=Toggles.JumpEnabled.Value; if State.JumpEnabled then CR4.ApplyJumpSettings() else CR4.RestoreJumpSettings() end end)
Options.JumpPower:OnChanged(function() State.JumpPower=Options.JumpPower.Value; CR4.ApplyJumpSettings() end)
Toggles.BunnyHop:OnChanged(function() State.BunnyHop=Toggles.BunnyHop.Value; if not State.BunnyHop then BunnyHopBonus=0; CR4.ApplyWalkSpeed() end end)
Options.BunnyHopStep:OnChanged(function() State.BunnyHopStep=Options.BunnyHopStep.Value end)
Options.BunnyHopMaxBonus:OnChanged(function() State.BunnyHopMaxBonus=Options.BunnyHopMaxBonus.Value; BunnyHopBonus=math.min(BunnyHopBonus,State.BunnyHopMaxBonus) end)

Toggles.ThirdPerson:OnChanged(function() State.ThirdPerson=Toggles.ThirdPerson.Value; ThirdPersonCurrentCF=nil; CR4.ApplyThirdPerson() end)
Options.ThirdPersonOffsetX:OnChanged(function() State.ThirdPersonOffsetX=Options.ThirdPersonOffsetX.Value; ThirdPersonCurrentCF=nil end)
Options.ThirdPersonOffsetY:OnChanged(function() State.ThirdPersonOffsetY=Options.ThirdPersonOffsetY.Value; ThirdPersonCurrentCF=nil end)
Options.ThirdPersonOffsetZ:OnChanged(function() State.ThirdPersonOffsetZ=Options.ThirdPersonOffsetZ.Value; State.ThirdPersonDistance=State.ThirdPersonOffsetZ; ThirdPersonCurrentCF=nil; CR4.ApplyThirdPerson() end)
Options.ThirdPersonSmooth:OnChanged(function() State.ThirdPersonSmooth=Options.ThirdPersonSmooth.Value end)
Toggles.MouseUnlock:OnChanged(function() State.MouseUnlock=Toggles.MouseUnlock.Value end)
Toggles.FOVOverride:OnChanged(function() State.FOVOverride=Toggles.FOVOverride.Value; if not State.FOVOverride and Camera then Camera.FieldOfView=OriginalFOV end end)
Options.FOVValue:OnChanged(function() State.FOV=Options.FOVValue.Value; CR4.ApplyCameraOptions() end)

Options.SpectatePlayer:OnChanged(function() State.SpectatePlayerName = Options.SpectatePlayer.Value; CR4.UpdateSpectate() end)
Toggles.SpectateEnabled:OnChanged(function()
    State.SpectateEnabled = Toggles.SpectateEnabled.Value
    if State.SpectateEnabled then CR4.UpdateSpectate() else CR4.StopSpectate() end
end)

Toggles.AutoGold:OnChanged(function() State.AutoGold = Toggles.AutoGold.Value end)
Toggles.AutoKeys:OnChanged(function() State.AutoKeys = Toggles.AutoKeys.Value end)
Toggles.AutoLoot:OnChanged(function() State.AutoLoot = Toggles.AutoLoot.Value end)
Options.AutoLootDistance:OnChanged(function() State.AutoLootDistance = Options.AutoLootDistance.Value end)

Toggles.AntiScreech:OnChanged(function()
    State.AntiScreech = Toggles.AntiScreech.Value
    if State.AntiScreech then
        local Existing = workspace:FindFirstChild("Screech", true) or workspace:FindFirstChild("ScreechRetro", true) or workspace:FindFirstChild("ScreechRushMode", true)
        if Existing then task.defer(CR4.FaceScreechAndRestore, Existing) end
    end
end)
Options.AntiScreechTurnTime:OnChanged(function() State.AntiScreechTurnTime = Options.AntiScreechTurnTime.Value end)
Toggles.AntiScreechDisable:OnChanged(function()
    State.AntiScreechDisable = Toggles.AntiScreechDisable.Value
    CR4.SetClientModuleDisabled("Screech", State.AntiScreechDisable)
end)

Toggles.AntiA90:OnChanged(function()
    State.AntiA90 = Toggles.AntiA90.Value
    if not State.AntiA90 then CR4.EndA90Lock() end
end)
Toggles.AntiFigure:OnChanged(function()
    State.AntiFigure = Toggles.AntiFigure.Value
    if not State.AntiFigure then CR4.ResetFigureProtection() end
end)
Toggles.AntiStun:OnChanged(function() State.AntiStun = Toggles.AntiStun.Value end)
Toggles.AntiDread:OnChanged(function()
    State.AntiDread = Toggles.AntiDread.Value
    CR4.SetClientModuleDisabled("Dread", State.AntiDread)
    if State.AntiDread then
        local Existing = workspace:FindFirstChild("Dread")
        if Existing then CR4.SafeDestroy(Existing) end
    end
end)
Toggles.AntiEyes:OnChanged(function() State.AntiEyes = Toggles.AntiEyes.Value end)
Toggles.AntiHalt:OnChanged(function() State.AntiHalt = Toggles.AntiHalt.Value; CR4.ApplyAntiHalt() end)
Toggles.AntiDupe:OnChanged(function()
    State.AntiDupe = Toggles.AntiDupe.Value
    if State.AntiDupe then CR4.ScanAntiDupe() end
end)
Toggles.AntiSnare:OnChanged(function()
    State.AntiSnare = Toggles.AntiSnare.Value
    if State.AntiSnare then CR4.ScanAntiTouch() else CR4.RestoreAntiTouch(); if State.AntiSeekObstacles then CR4.ScanAntiTouch() end end
end)
Toggles.AntiSeekObstacles:OnChanged(function()
    State.AntiSeekObstacles = Toggles.AntiSeekObstacles.Value
    if State.AntiSeekObstacles then CR4.ScanAntiTouch() else CR4.RestoreAntiTouch(); if State.AntiSnare then CR4.ScanAntiTouch() end end
end)
Toggles.Room50AutoCode:OnChanged(function()
    State.Room50AutoCode = Toggles.Room50AutoCode.Value
    Room50LastCode = ""
    if State.Room50AutoCode then CR4.ShowRoom50Code(true) end
end)

function BindThreatToggle(ToggleName, StateKey)
    Toggles[ToggleName]:OnChanged(function()
        State[StateKey] = Toggles[ToggleName].Value
    end)
end

BindThreatToggle("AntiRush", "AntiRush")
BindThreatToggle("AntiAmbush", "AntiAmbush")
BindThreatToggle("AntiA60", "AntiA60")
BindThreatToggle("AntiA120", "AntiA120")
BindThreatToggle("AntiBackdoorRush", "AntiBackdoorRush")
BindThreatToggle("AntiGlitchAmbush", "AntiGlitchAmbush")
Toggles.AntiEntityTP:OnChanged(function()
    State.AntiEntityTP = Toggles.AntiEntityTP.Value
    if not State.AntiEntityTP and ThreatEvadeActive then CR4.ResetThreatEvade() end
end)
Options.ThreatEvadeHeight:OnChanged(function() State.ThreatEvadeHeight = Options.ThreatEvadeHeight.Value end)
Toggles.AntiTeleport:OnChanged(function() State.AntiTeleport = Toggles.AntiTeleport.Value; if State.AntiTeleport then CR4.SetAntiTeleportPosition() else AntiTeleportLastSafeCFrame=nil end end)
Options.AntiTeleportThreshold:OnChanged(function() State.AntiTeleportThreshold = Options.AntiTeleportThreshold.Value end)

Toggles.CustomTexture:OnChanged(function() State.CustomTexture = Toggles.CustomTexture.Value; CR4.ApplyCustomTextureMode() end)
Options.CustomTextureMode:OnChanged(function() State.CustomTextureMode = Options.CustomTextureMode.Value; CR4.ApplyCustomTextureMode() end)
Options.CustomTextureID:OnChanged(function()
    State.CustomTextureID = Options.CustomTextureID.Value
    local Parsed = CR4.NormalizeAssetId(State.CustomTextureID)
    if State.CustomTextureMode == "Selected Objects" then
        local Target = TextureTargetMap[Options.TextureSelectedTarget.Value]
        if Target and not Parsed then
            SelectedTextureOverrides[Target] = nil
            CR4.RestoreTextureRoot(Target)
        end
    elseif State.CustomTexture then
        if not Parsed then CR4.RestoreAllTextures() else CR4.ApplyCustomTextureMode() end
    end
end)
Options.TextureObjectTypes:OnChanged(function()
    TextureSelectedCategories = {}
    for Key, Enabled in pairs(Options.TextureObjectTypes.Value) do if Enabled then TextureSelectedCategories[Key] = true end end
    if State.CustomTexture and State.CustomTextureMode == "Object Types" then CR4.ApplyCustomTextureMode() end
end)

Toggles.FunCameraSpin:OnChanged(function() State.FunCameraSpin=Toggles.FunCameraSpin.Value end)
Options.FunCameraSpinSpeed:OnChanged(function() State.FunCameraSpinSpeed=Options.FunCameraSpinSpeed.Value end)
Toggles.MonsterNotifications:OnChanged(function() State.MonsterNotifications=Toggles.MonsterNotifications.Value end)
Toggles.MonsterQuestionMark:OnChanged(function() State.MonsterQuestionMark=Toggles.MonsterQuestionMark.Value end)
Toggles.NotificationSounds:OnChanged(function() State.NotificationSounds=Toggles.NotificationSounds.Value end)
Options.NotificationSoundSlot:OnChanged(function() State.NotificationSoundSlot=Options.NotificationSoundSlot.Value end)
Options.NotificationSoundVolume:OnChanged(function() State.NotificationSoundVolume=Options.NotificationSoundVolume.Value; NotificationSound.Volume=State.NotificationSoundVolume end)
Toggles.ShowBackdoorsTimer:OnChanged(function() State.ShowBackdoorsTimer=Toggles.ShowBackdoorsTimer.Value; CR4.UpdateBackdoorsTimer() end)

Options.DPIScale:OnChanged(function()
    State.DPIScale = math.clamp(Options.DPIScale.Value, 50, 175)
    -- The compatibility bridge forwards this directly into Legacy v22 DPI settings.
end)
Toggles.FloatingGUIButton:OnChanged(function()
    State.FloatingButtonVisible = Toggles.FloatingGUIButton.Value
end)
Options.FloatingGUIButtonSize:OnChanged(function()
    State.FloatingButtonSize = Options.FloatingGUIButtonSize.Value
end)
Toggles.ClickSounds:OnChanged(function() State.ClickSounds = Toggles.ClickSounds.Value end)
Options.ClickSoundSlot:OnChanged(function() State.ClickSoundSlot = Options.ClickSoundSlot.Value end)
Options.ClickSoundVolume:OnChanged(function() State.ClickSoundVolume = Options.ClickSoundVolume.Value; ClickSound.Volume = State.ClickSoundVolume end)
