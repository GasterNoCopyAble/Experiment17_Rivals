-- Experiment 17 | Rivals | UI.lua
-- Physical logical module; compiled independently by Loader.lua.

--========================================================
-- COMBAT UI
--========================================================

AimBox = Tabs.Combat:AddLeftGroupbox("Aimbot")

AimBox:AddToggle(
    "AimEnabled",
    {
        Text = "Aimbot",
        Default = false
    }
):AddKeyPicker(
    "AimKey",
    {
        Default = "Q",
        Mode = "Toggle",
        SyncToggleState = true,
        Text = "Aimbot",
        NoUI = false
    }
)

AimBox:AddToggle(
    "TargetLock",
    {
        Text = "Target Lock",
        Default = true
    }
)

AimBox:AddDropdown(
    "AimPart",
    {
        Text = "Target Part",
        Values = {
            "Head",
            "HumanoidRootPart",
            "UpperTorso",
            "Torso"
        },
        Default = 1,
        Multi = false
    }
)

AimBox:AddSlider(
    "MaxAimDistance",
    {
        Text = "Max Aim Distance",
        Default = 500,
        Min = 25,
        Max = 5000,
        Rounding = 0,
        Suffix = " studs"
    }
)

AimChecks = Tabs.Combat:AddRightGroupbox("Checks")

AimChecks:AddToggle(
    "TeamCheck",
    {
        Text = "Ignore Teammates",
        Default = true
    }
)

AimChecks:AddToggle(
    "IgnoreFriends",
    {
        Text = "Ignore Friends",
        Default = true
    }
)

AimChecks:AddToggle(
    "WallCheck",
    {
        Text = "Wall Check",
        Default = true
    }
)

AimChecks:AddToggle(
    "UseFOV",
    {
        Text = "Use FOV",
        Default = true
    }
)

AimChecks:AddToggle(
    "ShowFOV",
    {
        Text = "Show FOV",
        Default = false
    }
)

AimChecks:AddSlider(
    "AimFOV",
    {
        Text = "FOV",
        Default = 300,
        Min = 20,
        Max = 1500,
        Rounding = 0
    }
)

DodgeBox = Tabs.Combat:AddRightGroupbox("Gaze Dodge")

DodgeBox:AddToggle(
    "GazeDodge",
    {
        Text = "Dodge Enemy Gaze",
        Default = false
    }
)

DodgeBox:AddSlider(
    "GazeDistance",
    {
        Text = "Max Distance",
        Default = 800,
        Min = 50,
        Max = 1500,
        Rounding = 0,
        Suffix = " studs"
    }
)

DodgeBox:AddSlider(
    "GazeAngle",
    {
        Text = "Detection Angle",
        Default = 7,
        Min = 1,
        Max = 30,
        Rounding = 0,
        Suffix = " deg"
    }
)

DodgeBox:AddSlider(
    "DodgeDistance",
    {
        Text = "Side Dodge",
        Default = 4,
        Min = 1,
        Max = 20,
        Rounding = 1,
        Suffix = " studs"
    }
)

DodgeBox:AddSlider(
    "DodgeCooldown",
    {
        Text = "Cooldown",
        Default = 0.25,
        Min = 0.05,
        Max = 2,
        Rounding = 2,
        Suffix = " s"
    }
)

--========================================================
-- VISUALS UI
--========================================================

ESPBox = Tabs.Visuals:AddLeftGroupbox("Expanded ESP")

ESPBox:AddToggle(
    "HighlightESP",
    {
        Text = "Highlight",
        Default = false
    }
)

ESPBox:AddToggle(
    "BoxESP",
    {
        Text = "Boxes",
        Default = false
    }
)

ESPBox:AddToggle(
    "TracerESP",
    {
        Text = "Tracers",
        Default = false
    }
)

ESPBox:AddToggle(
    "ESPName",
    {
        Text = "Names",
        Default = true
    }
)

ESPBox:AddToggle(
    "ESPHealth",
    {
        Text = "HP Text",
        Default = true
    }
)

ESPBox:AddToggle(
    "ESPHealthBar",
    {
        Text = "HP Bar",
        Default = true
    }
)

ESPBox:AddToggle(
    "ESPDistance",
    {
        Text = "Distance",
        Default = true
    }
)

ESPBox:AddToggle(
    "TeamESP",
    {
        Text = "Team ESP",
        Default = true
    }
)

ESPBox:AddToggle(
    "ESPFriendCheck",
    {
        Text = "Hide Friends",
        Default = false
    }
)

ESPBox:AddToggle(
    "ESPVisibleOnly",
    {
        Text = "Visible Only",
        Default = false
    }
)

ESPBox:AddSlider(
    "ESPMaxDistance",
    {
        Text = "ESP Max Distance",
        Default = 2500,
        Min = 50,
        Max = 10000,
        Rounding = 0,
        Suffix = " studs"
    }
)

ESPBox:AddSlider(
    "ESPUpdateRate",
    {
        Text = "ESP Update Rate",
        Default = 20,
        Min = 5,
        Max = 60,
        Rounding = 0,
        Suffix = " Hz"
    }
)

ESPBox:AddLabel("Enemy Color"):AddColorPicker(
    "EnemyColor",
    {
        Default = Color3.fromRGB(255, 70, 70)
    }
)

ESPBox:AddLabel("Team Color"):AddColorPicker(
    "TeamColor",
    {
        Default = Color3.fromRGB(80, 150, 255)
    }
)

ESPBox:AddToggle(
    "BoxFill",
    {
        Text = "Box Fill",
        Default = false
    }
)

ESPBox:AddSlider(
    "FillTransparency",
    {
        Text = "Fill Transparency",
        Default = 0.82,
        Min = 0,
        Max = 1,
        Rounding = 2
    }
)

ESPBox:AddSlider(
    "BoxRoundness",
    {
        Text = "Roundness",
        Default = 0,
        Min = 0,
        Max = 30,
        Rounding = 0
    }
)

ESPBox:AddSlider(
    "BoxThickness",
    {
        Text = "Box Thickness",
        Default = 2,
        Min = 1,
        Max = 5,
        Rounding = 0
    }
)

ESPBox:AddSlider(
    "ESPTextSize",
    {
        Text = "Text Size",
        Default = 14,
        Min = 10,
        Max = 22,
        Rounding = 0
    }
)

ESPBox:AddDropdown(
    "TracerOrigin",
    {
        Text = "Tracer Origin",
        Values = {
            "Bottom",
            "Center",
            "Top"
        },
        Default = 1,
        Multi = false
    }
)

ParticleBox = Tabs.Visuals:AddLeftGroupbox("Player Particles")

ParticleBox:AddToggle(
    "Particles",
    {
        Text = "Particles",
        Default = false
    }
)

ParticleBox:AddDropdown(
    "ParticleType",
    {
        Text = "Type",
        Values = {
            "Sparkles",
            "Smoke",
            "Soft",
            "Fireflies",
            "Custom"
        },
        Default = 1,
        Multi = false
    }
)

ParticleBox:AddDropdown(
    "ParticleRegion",
    {
        Text = "Sphere Region",
        Values = {
            "Surface",
            "Volume"
        },
        Default = 1,
        Multi = false
    }
)

ParticleBox:AddSlider(
    "ParticleRadius",
    {
        Text = "Sphere Radius",
        Default = 4,
        Min = 1,
        Max = 15,
        Rounding = 1
    }
)

ParticleBox:AddSlider(
    "ParticleAmount",
    {
        Text = "Amount",
        Default = 40,
        Min = 1,
        Max = 500,
        Rounding = 0
    }
)

ParticleBox:AddLabel("Color"):AddColorPicker(
    "ParticleColor",
    {
        Default = Color3.fromRGB(130, 170, 255)
    }
)

ParticleBox:AddInput(
    "ParticleTexture",
    {
        Text = "Custom Texture",
        Default = "rbxasset://textures/particles/sparkles_main.dds",
        Numeric = false,
        Finished = true
    }
)

ParticleBox:AddSlider(
    "ParticleSize",
    {
        Text = "Size",
        Default = 0.5,
        Min = 0.05,
        Max = 6,
        Rounding = 2
    }
)

ParticleBox:AddSlider(
    "ParticleSpeed",
    {
        Text = "Speed",
        Default = 4,
        Min = 0,
        Max = 50,
        Rounding = 1
    }
)

ParticleBox:AddSlider(
    "ParticleLifetime",
    {
        Text = "Lifetime",
        Default = 2,
        Min = 0.1,
        Max = 10,
        Rounding = 1,
        Suffix = " s"
    }
)

WorldBox = Tabs.Visuals:AddRightGroupbox("World")

WorldBox:AddToggle(
    "XRay",
    {
        Text = "X-Ray",
        Default = false
    }
)

WorldBox:AddSlider(
    "XRayTransparency",
    {
        Text = "X-Ray Transparency",
        Default = 0.7,
        Min = 0.1,
        Max = 0.95,
        Rounding = 2
    }
)

WorldBox:AddDropdown(
    "GraphicsPreset",
    {
        Text = "Graphics Preset",
        Values = {
            "Default",
            "Realistic",
            "Horror",
            "Surreal",
            "Dream",
            "Neon Night"
        },
        Default = 1,
        Multi = false
    }
)

WorldBox:AddToggle(
    "FPSBoost",
    {
        Text = "FPS Boost",
        Default = false
    }
)

WorldBox:AddDropdown(
    "FPSMode",
    {
        Text = "FPS Mode",
        Values = {
            "Light",
            "Aggressive"
        },
        Default = 1,
        Multi = false
    }
)

--========================================================
-- PLAYER UI
--========================================================

MovementBox = Tabs.Player:AddLeftGroupbox("Movement")

MovementBox:AddToggle(
    "SpeedHack",
    {
        Text = "Walk Speed",
        Default = false
    }
)

MovementBox:AddSlider(
    "WalkSpeed",
    {
        Text = "Walk Speed",
        Default = 32,
        Min = 16,
        Max = 300,
        Rounding = 0
    }
)

MovementBox:AddToggle(
    "JumpHack",
    {
        Text = "Jump Hack",
        Default = false
    }
)

MovementBox:AddSlider(
    "JumpPower",
    {
        Text = "Jump Power",
        Default = 80,
        Min = 50,
        Max = 300,
        Rounding = 0
    }
)

BHopBox = Tabs.Player:AddLeftGroupbox("Bunny Hop / Strafe")

BHopBox:AddToggle(
    "BunnyHop",
    {
        Text = "Bunny Hop",
        Default = false
    }
)

BHopBox:AddSlider(
    "BHopStartSpeed",
    {
        Text = "Starting Speed",
        Default = 25,
        Min = 10,
        Max = 100,
        Rounding = 0
    }
)

BHopBox:AddSlider(
    "BHopGain",
    {
        Text = "Speed Per Jump",
        Default = 5,
        Min = 1,
        Max = 100,
        Rounding = 0
    }
)

BHopBox:AddToggle(
    "AutoStrafe",
    {
        Text = "Auto Strafe",
        Default = false
    }
)

BHopBox:AddSlider(
    "StrafeSpeed",
    {
        Text = "Air Strafe Speed",
        Default = 40,
        Min = 10,
        Max = 300,
        Rounding = 0
    }
)

FlyBox = Tabs.Player:AddLeftGroupbox("Fly")

FlyBox:AddToggle(
    "Fly",
    {
        Text = "Fly",
        Default = false
    }
):AddKeyPicker(
    "FlyKey",
    {
        Default = "F",
        Mode = "Toggle",
        SyncToggleState = true,
        Text = "Fly",
        NoUI = false
    }
)

FlyBox:AddSlider(
    "FlySpeed",
    {
        Text = "Fly Speed",
        Default = 70,
        Min = 10,
        Max = 500,
        Rounding = 0
    }
)

CameraBox = Tabs.Player:AddRightGroupbox("Third Person")

CameraBox:AddToggle(
    "ThirdPerson",
    {
        Text = "Coordinate Third Person",
        Default = false
    }
)

CameraBox:AddSlider(
    "ThirdDistance",
    {
        Text = "Distance",
        Default = 10,
        Min = 2,
        Max = 40,
        Rounding = 1
    }
)

CameraBox:AddSlider(
    "ThirdHeight",
    {
        Text = "Height",
        Default = 2,
        Min = -5,
        Max = 10,
        Rounding = 1
    }
)

CameraBox:AddSlider(
    "ThirdSide",
    {
        Text = "Side Offset",
        Default = 0,
        Min = -10,
        Max = 10,
        Rounding = 1
    }
)

CameraBox:AddSlider(
    "ThirdSensitivity",
    {
        Text = "RMB Sensitivity",
        Default = 0.18,
        Min = 0.03,
        Max = 1,
        Rounding = 2
    }
)

AABox = Tabs.Player:AddRightGroupbox("Anti Aim")

AABox:AddToggle(
    "AntiAim",
    {
        Text = "Anti Aim",
        Default = false
    }
)

AABox:AddToggle(
    "HideHead",
    {
        Text = "Hide Head",
        Default = true
    }
)

AABox:AddDropdown(
    "AntiAimMode",
    {
        Text = "Mode",
        Values = {
            "Spin",
            "Left/Right",
            "Up/Down"
        },
        Default = 1,
        Multi = false
    }
)

AABox:AddSlider(
    "AntiAimSpeed",
    {
        Text = "Speed",
        Default = 720,
        Min = 90,
        Max = 2880,
        Rounding = 0,
        Suffix = " deg/s"
    }
)

AABox:AddSlider(
    "HeadHideAmount",
    {
        Text = "Head Hide",
        Default = 0.7,
        Min = 0,
        Max = 1.5,
        Rounding = 2
    }
)

--========================================================
-- MUSIC TAB
--========================================================

MusicMain = Tabs.Music:AddLeftGroupbox("Music Player")

MusicMain:AddToggle(
    "MusicEnabled",
    {
        Text = "Music Enabled",
        Default = true
    }
):AddKeyPicker(
    "MusicToggleKey",
    {
        Default = "M",
        Mode = "Toggle",
        SyncToggleState = true,
        Text = "Music",
        NoUI = false
    }
)

MusicMain:AddToggle(
    "ShowMusicHUD",
    {
        Text = "Show Linoria Music Player",
        Default = true
    }
)

MusicMain:AddToggle(
    "MusicLoop",
    {
        Text = "Loop Current Track",
        Default = false
    }
)

MusicMain:AddSlider(
    "MusicVolume",
    {
        Text = "Volume",
        Default = 0.5,
        Min = 0,
        Max = 1,
        Rounding = 2
    }
)

MusicMain:AddButton({
    Text = "Force Show Player HUD",
    Func = function()
        Toggles.ShowMusicHUD:SetValue(true)
        MusicGui.Enabled = true
        MusicOuter.Visible = true
        MusicFrame.Visible = true
        RefreshMusicHUD()
    end
})

-- Requested round music function is intentionally a separate visible block.
RoundMusicBox = Tabs.Music:AddLeftGroupbox("Round Music")

RoundMusicBox:AddToggle(
    "RoundMusic",
    {
        Text = "Auto Music With Rounds",
        Default = false
    }
)

RoundMusicBox:AddSlider(
    "RoundStopDelay",
    {
        Text = "Round End Delay",
        Default = 2.25,
        Min = 0.75,
        Max = 5,
        Rounding = 2,
        Suffix = " s"
    }
)

RoundMusicBox:AddLabel(
    "OFF = normal music player; music can play constantly.\n"
    .. "ON = automatic round mode.\n\n"
    .. "Detector:\n"
    .. "MainGui > MainFrame > DuelInterfaces > DuelInterface\n"
    .. "> Top > Timer > Numbers > Full > Value\n\n"
    .. "Value.Text changes = round starts.\n"
    .. "After Text stops changing for the delay, music pauses.\n"
    .. "The next round resumes from the same position.",
    true
)

RoundMusicBox:AddButton({
    Text = "Reattach Round Timer",
    Func = function()
        AttachRoundTimer(ResolveRoundTimer())

        Library:Notify(
            RoundTimerObject
                and "Round timer Value found"
                or "Round timer Value not found",
            3
        )
    end
})

MusicAdd = Tabs.Music:AddRightGroupbox("Add Tracks")

function SubmitMusicId(value)
    value = tostring(value or "")

    if value == "" then
        return
    end

    if AddAssetTrack(value) then
        Library:Notify("Track added: " .. value, 2)

        task.defer(function()
            pcall(function()
                Options.MusicIdInput:SetValue("")
            end)
        end)
    end
end

MusicAdd:AddInput(
    "MusicIdInput",
    {
        Text = "Music Asset ID",
        Default = "",
        Numeric = false,
        Finished = true,
        Placeholder = "Paste ID and press Enter",
        Callback = SubmitMusicId
    }
)

-- Button fallback for executors/Linoria forks where Finished callbacks are unreliable.
MusicAdd:AddButton({
    Text = "Add ID To Playlist",
    Func = function()
        SubmitMusicId(Options.MusicIdInput.Value)
    end
})

MusicAdd:AddInput(
    "MusicFolder",
    {
        Text = "Local Music Folder",
        Default = "Experiment17Music",
        Numeric = false,
        Finished = true,
        Placeholder = "Executor workspace folder"
    }
)

MusicAdd:AddInput(
    "LocalTrackPath",
    {
        Text = "Local Track Path",
        Default = "",
        Numeric = false,
        Finished = true,
        Placeholder = "Experiment17Music/song.mp3",
        Callback = function(value)
            value = tostring(value or "")

            if value == "" then
                return
            end

            if AddLocalTrackByPath(value) then
                pcall(function()
                    Options.LocalTrackPath:SetValue("")
                end)
            end
        end
    }
)


MusicAdd:AddButton({
    Text = "Load Local Folder",
    Func = function()
        ScanMusicFolder(Options.MusicFolder.Value)
    end
})

MusicAdd:AddButton({
    Text = "Filesystem Self Test",
    Func = function()
        FilesystemSelfTest()
    end
})

MusicAdd:AddButton({
    Text = "Debug Music Folder",
    Func = function()
        DebugMusicFolder(Options.MusicFolder.Value)
    end
})

MusicAdd:AddButton({
    Text = "Save Playlist Now",
    Func = function()
        SavePlaylist()
        Library:Notify("Playlist saved", 2)
    end
})

MusicAdd:AddButton({
    Text = "Clear Playlist",
    Func = function()
        MusicSound:Stop()
        table.clear(Playlist)
        CurrentTrack = 0
        SavePlaylist()
        RefreshMusicHUD()
    end
})

MusicInfo = Tabs.Music:AddRightGroupbox("Local Files")

MusicInfo:AddLabel(
    "If Load Local Folder fails, press Filesystem Self Test.\n"
    .. "If listfiles fails even on Experiment17_FS_TEST, the executor's\n"
    .. "folder API is the blocker. You can still use Local Track Path,\n"
    .. "which sends one exact audio-file path directly to getcustomasset.",
    true
)

--========================================================
-- SETTINGS
--========================================================

MenuBox = Tabs.Settings:AddLeftGroupbox("Menu")

MenuBox:AddLabel("Menu: RightShift"):AddKeyPicker(
    "MenuKeybind",
    {
        Default = "RightShift",
        Mode = "Toggle",
        NoUI = true,
        Text = "Menu"
    }
)

Library.ToggleKeybind = Options.MenuKeybind
Library.KeybindFrame.Visible = true

MenuBox:AddButton({
    Text = "Unload",
    Func = function()
        Library:Unload()
    end
})
