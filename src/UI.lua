-- Experiment 17 | Rivals | UI.lua
-- Physical logical module. Loaded in the shared Loader.lua environment.

--==================================================
-- GUI: MAIN
--==================================================
do

PromptGroup = Tabs.Main:AddLeftGroupbox("Prompts")
PromptTimeGroupA = Tabs.Main:AddRightGroupbox("Prompt Times 1")
PromptTimeGroupB = Tabs.Main:AddRightGroupbox("Prompt Times 2")

PromptGroup:AddToggle("PromptExpander", { Text = "Prompt Expander", Default = false })
PromptGroup:AddToggle("FastPrompts", { Text = "Fast Prompts", Default = false })
PromptGroup:AddToggle("PromptThroughWalls", { Text = "Prompts Through Walls", Default = false })
PromptGroup:AddToggle("RemovePaintingPrompts", { Text = "Remove Painting Prompts", Default = false })
PromptGroup:AddButton({ Text = "Rescan Prompts", Func = function() task.spawn(CR4.ScanPrompts, CurrentRooms) end, DoubleClick = false })

function CR4.AddPromptTimeSlider(Group, Id, Text, Key)
    Group:AddSlider(Id, { Text = Text, Default = PromptTimes[Key], Min = 0.00, Max = 2.0, Rounding = 2, Suffix = " sec" })
end

CR4.AddPromptTimeSlider(PromptTimeGroupA, "PromptTimeDoor", "Doors", "Door")
CR4.AddPromptTimeSlider(PromptTimeGroupA, "PromptTimeHide", "Hide", "Hide")
CR4.AddPromptTimeSlider(PromptTimeGroupA, "PromptTimeGold", "Gold", "Gold")
CR4.AddPromptTimeSlider(PromptTimeGroupA, "PromptTimeKey", "Keys", "Key")
CR4.AddPromptTimeSlider(PromptTimeGroupA, "PromptTimeLockpick", "Lockpicks", "Lockpick")
CR4.AddPromptTimeSlider(PromptTimeGroupB, "PromptTimeItem", "Items", "Item")
CR4.AddPromptTimeSlider(PromptTimeGroupB, "PromptTimeChest", "Chests", "Chest")
CR4.AddPromptTimeSlider(PromptTimeGroupB, "PromptTimeDrawer", "Drawers / Lootables", "Drawer")
CR4.AddPromptTimeSlider(PromptTimeGroupB, "PromptTimeObjective", "Objectives", "Objective")
CR4.AddPromptTimeSlider(PromptTimeGroupB, "PromptTimeOther", "Other", "Other")

end
--==================================================
-- GUI: ESP
--==================================================
do

ObjectESPGroupA = Tabs.ESP:AddLeftGroupbox("Objects 1")
ObjectESPGroupB = Tabs.ESP:AddRightGroupbox("Objects 2")
ObjectESPGroupC = Tabs.ESP:AddLeftGroupbox("Objects 3")
ObjectESPGroupD = Tabs.ESP:AddRightGroupbox("Objects 4")
MonsterESPGroupA = Tabs.ESP:AddRightGroupbox("Monsters 1")
MonsterESPGroupB = Tabs.ESP:AddLeftGroupbox("Monsters 2")
MonsterESPGroupC = Tabs.ESP:AddRightGroupbox("Monsters 3")
ESPRenderGroup = Tabs.ESP:AddLeftGroupbox("Renderer")

function CR4.AddCategoryControls(Group, Key)
    local Config = ESPCategories[Key]
    local Prefix = "ESP_" .. Key
    Group:AddToggle(Prefix, { Text = Config.Label, Default = Config.Enabled })
    Group:AddToggle(Prefix .. "_Boxes", { Text = Config.Label .. " Boxes", Default = Config.Boxes })
    Group:AddToggle(Prefix .. "_Tracers", { Text = Config.Label .. " Tracers", Default = Config.Tracers })
    Group:AddLabel(Config.Label .. " Color"):AddColorPicker(Prefix .. "_Color", { Default = Config.Color, Title = Config.Label })

    Toggles[Prefix]:OnChanged(function()
        Config.Enabled = Toggles[Prefix].Value
        CR4.RefreshESPEntries()
        if State.XRay and RefreshXRay then task.defer(RefreshXRay) end
    end)
    Toggles[Prefix .. "_Boxes"]:OnChanged(function() Config.Boxes = Toggles[Prefix .. "_Boxes"].Value end)
    Toggles[Prefix .. "_Tracers"]:OnChanged(function() Config.Tracers = Toggles[Prefix .. "_Tracers"].Value end)
    Options[Prefix .. "_Color"]:OnChanged(function()
        Config.Color = Options[Prefix .. "_Color"].Value
        CR4.RefreshESPEntries()
    end)
end

for _, Key in ipairs({ "Doors", "Chapter", "Gold", "Keys", "Lockpicks" }) do CR4.AddCategoryControls(ObjectESPGroupA, Key) end
for _, Key in ipairs({ "Wardrobes", "Chests", "Lootables", "Lights", "Crucifix" }) do CR4.AddCategoryControls(ObjectESPGroupB, Key) end
for _, Key in ipairs({ "Items", "Objectives", "Books", "Breakers", "Rift" }) do CR4.AddCategoryControls(ObjectESPGroupC, Key) end
for _, Key in ipairs({ "Levers", "Mines", "Backdoors", "Fuses", "DangerDoor" }) do CR4.AddCategoryControls(ObjectESPGroupD, Key) end
for _, Key in ipairs({ "Rush", "Ambush", "Seek", "Figure", "Dupe" }) do CR4.AddCategoryControls(MonsterESPGroupA, Key) end
for _, Key in ipairs({ "Screech", "Dread", "Snare", "OtherMonsters", "A60" }) do CR4.AddCategoryControls(MonsterESPGroupB, Key) end
for _, Key in ipairs({ "A120", "BackdoorRush", "Lookman", "GlitchAmbush" }) do CR4.AddCategoryControls(MonsterESPGroupC, Key) end

ESPRenderGroup:AddToggle("ESPNames", { Text = "Names", Default = State.ESPNames })
ESPRenderGroup:AddToggle("ESPDistance", { Text = "Distance", Default = State.ESPDistance })
ESPRenderGroup:AddDropdown("TracerOrigin", { Values = { "Bottom", "Center", "Top" }, Default = State.TracerOrigin, Multi = false, Text = "Tracer Origin" })
ESPRenderGroup:AddSlider("ESPMaxDistance", { Text = "Max Distance", Default = State.ESPMaxDistance, Min = 50, Max = 5000, Rounding = 0, Suffix = " studs" })
ESPRenderGroup:AddSlider("ESPThickness", { Text = "Line Thickness", Default = State.ESPThickness, Min = 1, Max = 5, Rounding = 0 })
ESPRenderGroup:AddSlider("ESPVerticalOffset", { Text = "Box / Tracer Height", Default = State.ESPVerticalOffset, Min = -120, Max = 120, Rounding = 0, Suffix = " px" })
ESPRenderGroup:AddSlider("ESPFPS", { Text = "ESP Update FPS", Default = State.ESPFPS, Min = 10, Max = 60, Rounding = 0 })
ESPRenderGroup:AddSlider("ESPFillTransparency", { Text = "Highlight Transparency", Default = math.floor(State.ESPFillTransparency * 100), Min = 0, Max = 100, Rounding = 0, Suffix = "%" })
ESPRenderGroup:AddButton({ Text = "Rescan ESP", Func = function() CR4.ScanESP(); task.defer(CR4.BuildTextureTargetList) end, DoubleClick = false })

end
--==================================================
-- GUI: VISUAL
--==================================================
do

XRayGroup = Tabs.Visual:AddLeftGroupbox("X-Ray")
VisualGroup = Tabs.Visual:AddRightGroupbox("World Visuals")
StyleGroup = Tabs.Visual:AddLeftGroupbox("Graphics Style")
PathGroup = Tabs.Visual:AddRightGroupbox("Smart Path")

XRayGroup:AddToggle("XRay", { Text = "Enable X-Ray", Default = State.XRay })
XRayGroup:AddDropdown("XRayMode", { Values = { "Decor Only", "Whole Map" }, Default = State.XRayMode, Multi = false, Text = "X-Ray Mode" })
XRayGroup:AddSlider("XRayTransparency", { Text = "Transparency", Default = math.floor(State.XRayTransparency * 100), Min = 0, Max = 100, Rounding = 0, Suffix = "%" })

VisualGroup:AddToggle("LowGFX", { Text = "Low GFX", Default = State.LowGFX })
VisualGroup:AddToggle("Fullbright", { Text = "Fullbright", Default = State.Fullbright })
VisualGroup:AddToggle("NoFog", { Text = "No Fog / Atmosphere", Default = State.NoFog })
VisualGroup:AddToggle("NoPostEffects", { Text = "Disable Post Effects", Default = State.NoPostEffects })
VisualGroup:AddToggle("NoShadows", { Text = "No Shadows", Default = State.NoShadows })

StyleGroup:AddDropdown("VisualStyle", {
    Values = { "Off", "Beautiful", "Fantasy", "Horror", "Realistic", "Retro", "Cinematic", "Dream", "Cold", "Warm", "Noir" },
    Default = State.VisualStyle, Multi = false, Text = "Style",

})

PathGroup:AddToggle("SmartPath", { Text = "Smart Path", Default = State.SmartPath })
PathGroup:AddDropdown("PathTargetMode", { Values = { "Progress Door", "Lever", "Key / Lockpick", "Gold", "Wardrobe", "Fuse / Breaker", "Objective", "Loot", "Nearest ESP" }, Default = State.PathTargetMode, Multi = false, Text = "Target" })
PathGroup:AddSlider("PathRecompute", { Text = "Recompute", Default = State.PathRecompute, Min = 0.1, Max = 2.0, Rounding = 1, Suffix = " sec" })
PathGroup:AddSlider("PathMaxDistance", { Text = "Max Distance", Default = State.PathMaxDistance, Min = 50, Max = 800, Rounding = 0, Suffix = " studs" })
PathGroup:AddLabel("Path Color"):AddColorPicker("PathColor", { Default = State.PathColor, Title = "Path Color" })

end
--==================================================
-- GUI: PLAYER
--==================================================
do

MovementGroup=Tabs.Player:AddLeftGroupbox("Movement")
JumpGroup=Tabs.Player:AddRightGroupbox("Jump / Bunnyhop")
FlyGroup=Tabs.Player:AddLeftGroupbox("Fly")
CameraGroup=Tabs.Player:AddRightGroupbox("Camera")
SpectateGroup=Tabs.Player:AddLeftGroupbox("Spectate")

MovementGroup:AddToggle("WalkSpeedEnabled",{Text="Speed",Default=State.WalkSpeedEnabled})
MovementGroup:AddDropdown("SpeedMethod",{Values={"WalkSpeed","CFrame","BodyVelocity"},Default=State.SpeedMethod,Multi=false,Text="Speed Method"})
MovementGroup:AddSlider("WalkSpeedValue",{Text="Speed",Default=State.WalkSpeed,Min=0,Max=21,Rounding=0})
MovementGroup:AddToggle("SeekSpeedhack",{Text="Seek Speedhack",Default=State.SeekSpeedhack})
MovementGroup:AddSlider("SeekSpeedValue",{Text="Seek Speed",Default=State.SeekSpeed,Min=22,Max=28,Rounding=0})
MovementGroup:AddToggle("MicroTPEnabled",{Text="Continuous Micro TP",Default=State.MicroTPEnabled})
MovementGroup:AddSlider("MicroTPDistance",{Text="Micro TP Step",Default=State.MicroTPDistance,Min=0.2,Max=4,Rounding=1,Suffix=" studs"})
MovementGroup:AddSlider("MicroTPInterval",{Text="Micro TP Interval",Default=State.MicroTPInterval,Min=0.03,Max=0.3,Rounding=2,Suffix=" sec"})

JumpGroup:AddToggle("JumpEnabled",{Text="Custom Jump",Default=State.JumpEnabled})
JumpGroup:AddSlider("JumpPower",{Text="Jump Power",Default=State.JumpPower,Min=10,Max=50,Rounding=0})
JumpGroup:AddToggle("BunnyHop",{Text="Bunnyhop Acceleration",Default=State.BunnyHop})
JumpGroup:AddSlider("BunnyHopStep",{Text="Speed Per Jump",Default=State.BunnyHopStep,Min=0.5,Max=5,Rounding=1})
JumpGroup:AddSlider("BunnyHopMaxBonus",{Text="Max Bonus",Default=State.BunnyHopMaxBonus,Min=1,Max=20,Rounding=0})

FlyGroup:AddToggle("FlyEnabled",{Text="Fly",Default=State.FlyEnabled})
FlyGroup:AddDropdown("FlyMethod",{Values={"BodyVelocity","LinearVelocity","CFrame"},Default=State.FlyMethod,Multi=false,Text="Fly Method"})
FlyGroup:AddSlider("FlySpeed",{Text="Fly Speed",Default=State.FlySpeed,Min=1,Max=20,Rounding=0})

CameraGroup:AddToggle("ThirdPerson",{Text="Third Person",Default=State.ThirdPerson})
CameraGroup:AddSlider("ThirdPersonOffsetX",{Text="Third Person X",Default=State.ThirdPersonOffsetX,Min=-20,Max=20,Rounding=1})
CameraGroup:AddSlider("ThirdPersonOffsetY",{Text="Third Person Y",Default=State.ThirdPersonOffsetY,Min=-5,Max=20,Rounding=1})
CameraGroup:AddSlider("ThirdPersonOffsetZ",{Text="Third Person Z",Default=State.ThirdPersonOffsetZ,Min=2,Max=35,Rounding=1})
CameraGroup:AddSlider("ThirdPersonSmooth",{Text="Third Person Smooth",Default=State.ThirdPersonSmooth,Min=0,Max=1,Rounding=2})
CameraGroup:AddToggle("MouseUnlock",{Text="Unlock Mouse",Default=State.MouseUnlock})
Toggles.MouseUnlock:AddKeyPicker("MouseUnlockKey",{Default="LeftAlt",SyncToggleState=true,Mode="Toggle",NoUI=false,Text="Unlock Mouse"})
CameraGroup:AddToggle("FOVOverride",{Text="FOV Override",Default=State.FOVOverride})
CameraGroup:AddSlider("FOVValue",{Text="FOV",Default=State.FOV,Min=50,Max=120,Rounding=0})

SpectateGroup:AddDropdown("SpectatePlayer",{SpecialType="Player",Text="Player",Multi=false})
SpectateGroup:AddToggle("SpectateEnabled",{Text="Spectate",Default=false})

end
--==================================================
-- GUI: AUTOMATION
--==================================================
do

LootGroup = Tabs.Automation:AddLeftGroupbox("Auto Pickup")
ProtectionGroup = Tabs.Automation:AddRightGroupbox("Protection")

LootGroup:AddToggle("AutoGold", { Text = "Auto Gold", Default = State.AutoGold })
LootGroup:AddToggle("AutoKeys", { Text = "Auto Keys / Lockpicks", Default = State.AutoKeys })
LootGroup:AddToggle("AutoLoot", { Text = "Auto Loot", Default = State.AutoLoot })
LootGroup:AddSlider("AutoLootDistance", { Text = "Pickup Distance", Default = State.AutoLootDistance, Min = 3, Max = 40, Rounding = 0, Suffix = " studs" })

ProtectionGroup:AddToggle("AntiScreech", { Text = "Anti Screech Auto Look", Default = State.AntiScreech })
ProtectionGroup:AddSlider("AntiScreechTurnTime", { Text = "Turn / Return Time", Default = State.AntiScreechTurnTime, Min = 0.01, Max = 1.5, Rounding = 2, Suffix = " sec" })
ProtectionGroup:AddToggle("AntiScreechDisable", { Text = "Anti Screech Disable", Default = State.AntiScreechDisable })
ProtectionGroup:AddToggle("AntiA90", { Text = "Anti A90", Default = State.AntiA90 })
ProtectionGroup:AddToggle("AntiFigure", { Text = "Anti Figure", Default = State.AntiFigure })
ProtectionGroup:AddToggle("AntiStun", { Text = "Anti Stun", Default = State.AntiStun })
ProtectionGroup:AddToggle("AntiDread", { Text = "Anti Dread", Default = State.AntiDread })
ProtectionGroup:AddToggle("AntiEyes", { Text = "Anti Eyes", Default = State.AntiEyes })
ProtectionGroup:AddToggle("AntiHalt", { Text = "Anti Halt", Default = State.AntiHalt })
ProtectionGroup:AddToggle("AntiDupe", { Text = "Anti Dupe", Default = State.AntiDupe })
ProtectionGroup:AddToggle("AntiSnare", { Text = "Anti Snare", Default = State.AntiSnare })
ProtectionGroup:AddToggle("AntiSeekObstacles", { Text = "Anti Seek Obstacles", Default = State.AntiSeekObstacles })
ProtectionGroup:AddToggle("AntiRush", { Text = "Anti Rush", Default = State.AntiRush })
ProtectionGroup:AddToggle("AntiAmbush", { Text = "Anti Ambush", Default = State.AntiAmbush })
ProtectionGroup:AddToggle("AntiA60", { Text = "Anti A60", Default = State.AntiA60 })
ProtectionGroup:AddToggle("AntiA120", { Text = "Anti A120", Default = State.AntiA120 })
ProtectionGroup:AddToggle("AntiBackdoorRush", { Text = "Anti Backdoor Rush", Default = State.AntiBackdoorRush })
ProtectionGroup:AddToggle("AntiGlitchAmbush", { Text = "Anti Glitch Ambush", Default = State.AntiGlitchAmbush })
ProtectionGroup:AddToggle("AntiEntityTP", { Text = "Anti Entity TP", Default = State.AntiEntityTP })
ProtectionGroup:AddSlider("ThreatEvadeHeight", { Text = "Entity TP Height", Default = State.ThreatEvadeHeight, Min = 100, Max = 1500, Rounding = 0, Suffix = " studs" })
ProtectionGroup:AddToggle("AntiTeleport", { Text = "Anti TP", Default = State.AntiTeleport })
ProtectionGroup:AddSlider("AntiTeleportThreshold", { Text = "TP Threshold", Default = State.AntiTeleportThreshold, Min = 5, Max = 100, Rounding = 0, Suffix = " studs" })
ProtectionGroup:AddButton({ Text = "Reset Safe Position", Func = CR4.SetAntiTeleportPosition, DoubleClick = false })

Room50GameGroup = Tabs.Automation:AddLeftGroupbox("Room 50 / Game")
Room50GameGroup:AddToggle("Room50AutoCode", { Text = "Room 50 Auto Code", Default = State.Room50AutoCode })
Room50GameGroup:AddButton({ Text = "Solve Room 50 Code", Func = function() CR4.ShowRoom50Code(true) end, DoubleClick = false })
Room50GameGroup:AddButton({ Text = "Open Room 50", Func = CR4.OpenRoom50Door, DoubleClick = false })
Room50GameGroup:AddButton({ Text = "Revive", Func = CR4.RevivePlayer, DoubleClick = false })

end
--==================================================
-- GUI: FUN
--==================================================
do

TextureGroup = Tabs.Fun:AddLeftGroupbox("Custom Texture")
TextureSelectGroup = Tabs.Fun:AddRightGroupbox("Texture Targets")
FunCameraGroup = Tabs.Fun:AddLeftGroupbox("Character Spin")

TextureGroup:AddToggle("CustomTexture", { Text = "Custom Texture", Default = State.CustomTexture })
TextureGroup:AddDropdown("CustomTextureMode", { Values = { "Whole Map", "Object Types", "Selected Objects" }, Default = State.CustomTextureMode, Multi = false, Text = "Mode" })
TextureGroup:AddInput("CustomTextureID", { Default = "", Numeric = false, Finished = false, Text = "Image / Texture ID", Placeholder = "rbxassetid:// or ID" })
TextureGroup:AddButton({ Text = "Apply Texture Mode", Func = CR4.ApplyCustomTextureMode, DoubleClick = false })
TextureGroup:AddButton({ Text = "Restore Textures", Func = CR4.RestoreAllTextures, DoubleClick = false })

TextureSelectGroup:AddDropdown("TextureObjectTypes", { Values = ObjectCategoryOrder, Default = {}, Multi = true, Text = "Object Types" })
TextureSelectGroup:AddDropdown("TextureSelectedTarget", { Values = {}, AllowNull = true, Multi = false, Text = "Selected Object" })
TextureSelectGroup:AddButton({ Text = "Refresh Objects", Func = CR4.BuildTextureTargetList, DoubleClick = false })
TextureSelectGroup:AddButton({
    Text = "Apply ID To Selected",
    Func = function()
        local Target = TextureTargetMap[Options.TextureSelectedTarget.Value]
        if not Target then return end
        local Id = CR4.NormalizeAssetId(Options.CustomTextureID.Value)
        if Id then
            SelectedTextureOverrides[Target] = Id
            if State.CustomTexture and State.CustomTextureMode == "Selected Objects" then task.spawn(CR4.ApplyTextureRoot, Target, Id) end
        else
            SelectedTextureOverrides[Target] = nil
            CR4.RestoreTextureRoot(Target)
        end
    end,
    DoubleClick = false,
})
FunCameraGroup:AddToggle("FunCameraSpin", { Text = "Character Spin", Default = State.FunCameraSpin })
FunCameraGroup:AddSlider("FunCameraSpinSpeed", { Text = "Spin Speed", Default = State.FunCameraSpinSpeed, Min = 10, Max = 360, Rounding = 0, Suffix = " deg/s" })

TextureSelectGroup:AddButton({
    Text = "Clear Selected Override",
    Func = function()
        local Target = TextureTargetMap[Options.TextureSelectedTarget.Value]
        if Target then SelectedTextureOverrides[Target] = nil; CR4.RestoreTextureRoot(Target) end
    end,
    DoubleClick = false,
})

end
--==================================================
-- GUI: NOTIFICATION
--==================================================
do

NotifyGroup=Tabs.Notification:AddLeftGroupbox("Monster Alerts")
NotifySoundGroup=Tabs.Notification:AddRightGroupbox("Sound")
TimerGroup=Tabs.Notification:AddLeftGroupbox("Backdoors")
NotifyGroup:AddToggle("MonsterNotifications",{Text="Monster Notifications",Default=State.MonsterNotifications})
NotifyGroup:AddToggle("MonsterQuestionMark",{Text="Wardrobe ? Mark",Default=State.MonsterQuestionMark})
NotifySlots={} for i=1,10 do table.insert(NotifySlots,"Notify "..i) end
NotifySoundGroup:AddToggle("NotificationSounds",{Text="Notification Sounds",Default=State.NotificationSounds})
NotifySoundGroup:AddDropdown("NotificationSoundSlot",{Values=NotifySlots,Default=State.NotificationSoundSlot,Multi=false,Text="Sound Slot"})
NotifySoundGroup:AddSlider("NotificationSoundVolume",{Text="Volume",Default=State.NotificationSoundVolume,Min=0,Max=1,Rounding=2})
NotifySoundGroup:AddButton({Text="Test Notification",Func=function() CR4.Notify("Experiment 17 test",3); CR4.PlayNotificationSound() end,DoubleClick=false})
TimerGroup:AddToggle("ShowBackdoorsTimer",{Text="Backdoors Timer",Default=State.ShowBackdoorsTimer})

end
--==================================================
-- GUI: CONTACT
--==================================================
do

ContactGroup=Tabs.Contact:AddLeftGroupbox("Links")
ContactGroup:AddButton({Text="Copy Discord",Func=function() CR4.CopyContact("Discord") end,DoubleClick=false})
ContactGroup:AddButton({Text="Copy Telegram",Func=function() CR4.CopyContact("Telegram") end,DoubleClick=false})

end
--==================================================
-- GUI: DEBUG
--==================================================
do

DebugLoadstringsGroup = Tabs.Debug:AddLeftGroupbox("Debug Loadstrings")
DebugToolsGroup = Tabs.Debug:AddRightGroupbox("Tools")

function CR4.RunDebugLoadstring(Index)
    local URL = DEBUG_LOADSTRING_URLS[Index]
    if type(URL) ~= "string" or URL == "" then CR4.Notify("Debug URL slot " .. Index .. " is empty", 3); return end
    local Success, Result = pcall(function() return loadstring(game:HttpGet(URL))() end)
    if not Success then CR4.Notify("Loadstring error: " .. tostring(Result), 5) end
end

for Index = 1, 4 do
    local I = Index
    DebugLoadstringsGroup:AddButton({ Text = "Run Loadstring " .. I, Func = function() CR4.RunDebugLoadstring(I) end, DoubleClick = true })
end

DebugToolsGroup:AddButton({
    Text = "Full Rescan",
    Func = function()
        task.spawn(CR4.ScanPrompts, CurrentRooms)
        CR4.ScanESP()
        RefreshXRay()
        CR4.ScanVisualObjectsAsync()
        CR4.BuildTextureTargetList()
    end,
    DoubleClick = false,
})
DebugToolsGroup:AddButton({
    Text = "Restore World Values",
    Func = function()
        CR4.RestorePrompts()
        CR4.RestoreXRay()
        CR4.RestoreVisuals()
        CR4.RestoreWalkSpeed()
        CR4.RestoreJumpSettings()
        CR4.RestoreAllTextures()
    end,
    DoubleClick = true,
})
DebugToolsGroup:AddButton({ Text = "Unload", Func = function() Library:Unload() end, DoubleClick = true })

end
--==================================================
-- GUI: SETTINGS (Legacy v22 native Settings tab)
--==================================================
do

MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Experiment 17")
SoundGroup = Tabs["UI Settings"]:AddRightGroupbox("Click Sound")

-- These controls are compatibility shortcuts. Legacy v22 also exposes its own
-- complete Interface / Mobile / Theme / Gradient / Config sections in Settings.
MenuGroup:AddSlider("DPIScale", { Text = "DPI Scale", Default = State.DPIScale, Min = 50, Max = 175, Rounding = 0, Suffix = "%" })
MenuGroup:AddToggle("FloatingGUIButton", { Text = "Floating GUI Button", Default = State.FloatingButtonVisible })
MenuGroup:AddSlider("FloatingGUIButtonSize", { Text = "Floating Button Size", Default = State.FloatingButtonSize, Min = 36, Max = 96, Rounding = 0, Suffix = " px" })
MenuGroup:AddButton({ Text = "Close / Open GUI", Func = function() Library:Toggle() end, DoubleClick = false })
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
Library.ToggleKeybind = Options.MenuKeybind

ClickSlots = {}
for Index = 1, 10 do table.insert(ClickSlots, "Sound " .. Index) end
SoundGroup:AddToggle("ClickSounds", { Text = "Click Sounds", Default = State.ClickSounds })
SoundGroup:AddDropdown("ClickSoundSlot", { Values = ClickSlots, Default = State.ClickSoundSlot, Multi = false, Text = "Sound Slot" })
SoundGroup:AddSlider("ClickSoundVolume", { Text = "Volume", Default = State.ClickSoundVolume, Min = 0, Max = 1, Rounding = 2 })
SoundGroup:AddButton({ Text = "Test Click Sound", Func = CR4.PlayClickSound, DoubleClick = false })

end
