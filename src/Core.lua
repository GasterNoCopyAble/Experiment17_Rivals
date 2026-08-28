-- Experiment 17 | Rivals | Core.lua
-- Physical logical module; compiled independently by Loader.lua.

--========================================================
-- SERVICES
--========================================================

Players = game:GetService("Players")
RunService = game:GetService("RunService")
UIS = game:GetService("UserInputService")
Workspace = game:GetService("Workspace")
Lighting = game:GetService("Lighting")
SoundService = game:GetService("SoundService")
HttpService = game:GetService("HttpService")

LP = Players.LocalPlayer
Camera = Workspace.CurrentCamera


Window = Library:CreateWindow({
    Title = "Experiment 17",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

--========================================================
-- TABS
--========================================================

Tabs = {
    Combat = Window:AddTab("Combat"),
    Visuals = Window:AddTab("Visuals"),
    Player = Window:AddTab("Player"),
    Music = Window:AddTab("Music"),
    Settings = Window:AddTab("Settings")
}

--========================================================
-- GENERAL STATE
--========================================================

Connections = {}
Unloaded = false

CurrentTarget = nil
FriendCache = {}

ESPObjects = {}
Highlights = {}

BHopSpeed = 0
JumpLatch = false

DodgeSide = 1
LastDodge = 0

AntiAimAngle = 0
AntiAimTimer = 0

ThirdYaw = 0
ThirdPitch = math.rad(-10)
ThirdDragging = false

ParticleSphere = nil
ParticleEmitter = nil

XRayCache = {}
FPSCache = {}
VisualEffects = {}

--========================================================
-- FILE API
--========================================================

FileAPI =
    type(writefile) == "function"
    and type(readfile) == "function"
    and type(isfile) == "function"
    and type(isfolder) == "function"
    and type(makefolder) == "function"
    and type(listfiles) == "function"

CustomAsset =
    (type(getcustomasset) == "function" and getcustomasset)
    or (type(getsynasset) == "function" and getsynasset)
    or nil

RootFolder = "Experiment17"
PlaylistFile = RootFolder .. "/music_playlist.json"

if FileAPI and not isfolder(RootFolder) then
    pcall(makefolder, RootFolder)
end

--========================================================
-- ORIGINAL SETTINGS
--========================================================

MovementDefaults = {
    WalkSpeed = 16,
    JumpPower = 50,
    JumpHeight = 7.2,
    UseJumpPower = true
}

OriginalCamera = {
    Type = Camera.CameraType,
    Subject = Camera.CameraSubject,
    MinZoom = LP.CameraMinZoomDistance,
    MaxZoom = LP.CameraMaxZoomDistance,
    Mode = LP.CameraMode
}

OriginalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    Exposure = Lighting.ExposureCompensation,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogColor = Lighting.FogColor,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    Shadows = Lighting.GlobalShadows,
    ShadowSoftness = Lighting.ShadowSoftness
}

--========================================================
-- CHARACTER HELPERS
--========================================================

function GetCharacter()
    return LP.Character
end

function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

function GetRoot()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

function GetNeck()
    local char = GetCharacter()

    if not char then
        return nil
    end

    return char:FindFirstChild("Neck", true)
end

function SaveMovementDefaults()
    local hum = GetHumanoid()

    if not hum then
        return
    end

    MovementDefaults.WalkSpeed = hum.WalkSpeed
    MovementDefaults.JumpPower = hum.JumpPower
    MovementDefaults.JumpHeight = hum.JumpHeight
    MovementDefaults.UseJumpPower = hum.UseJumpPower
end

function RestoreMovement()
    local hum = GetHumanoid()

    if not hum then
        return
    end

    hum.WalkSpeed = MovementDefaults.WalkSpeed
    hum.JumpPower = MovementDefaults.JumpPower
    hum.JumpHeight = MovementDefaults.JumpHeight
    hum.UseJumpPower = MovementDefaults.UseJumpPower
    hum.AutoRotate = true
end

function Alive(player)
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    return hum and hum.Health > 0
end

if LP.Character then
    task.defer(SaveMovementDefaults)
end

--========================================================
-- TEAM / FRIEND
--========================================================

function IsTeammate(player)
    if not player or player == LP then
        return false
    end

    if LP.Team == nil or player.Team == nil then
        return false
    end

    return LP.Team == player.Team
end

function LoadFriend(player)
    if player == LP then
        return
    end

    FriendCache[player.UserId] = nil

    task.spawn(function()
        local ok, result = pcall(function()
            return LP:IsFriendsWith(player.UserId)
        end)

        if ok then
            FriendCache[player.UserId] = result == true
        else
            -- Do not target while relationship is unknown.
            FriendCache[player.UserId] = true
        end
    end)
end

function IsFriend(player)
    local value = FriendCache[player.UserId]

    if value == nil then
        return true
    end

    return value
end

--========================================================
-- DISTANCE / VISIBILITY
--========================================================

function GetDistance(player)
    local myRoot = GetRoot()
    local targetRoot =
        player.Character
        and player.Character:FindFirstChild("HumanoidRootPart")

    if not myRoot or not targetRoot then
        return math.huge
    end

    return (targetRoot.Position - myRoot.Position).Magnitude
end

function RayVisible(player, part)
    local char = GetCharacter()

    if not char then
        return false
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char}
    params.IgnoreWater = true

    local origin = Camera.CFrame.Position
    local result = Workspace:Raycast(
        origin,
        part.Position - origin,
        params
    )

    if not result then
        return true
    end

    return result.Instance:IsDescendantOf(player.Character)
end
