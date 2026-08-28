-- Experiment 17 | Rivals | Unload.lua
-- Physical logical module; compiled independently by Loader.lua.

--========================================================
-- UNLOAD
--========================================================

Library:OnUnload(function()
    Unloaded = true
    CurrentTarget = nil

    SavePlaylist()

    for _, connection in pairs(Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    if RoundTimerConnection then
        pcall(function()
            RoundTimerConnection:Disconnect()
        end)

        RoundTimerConnection = nil
    end

    MusicSound:Stop()

    DestroyParticles()
    DisableXRay()
    DisableFPS()
    RestoreGraphics()
    RestoreMovement()

    for player in pairs(ESPObjects) do
        DestroyESP(player)
    end

    for player, highlight in pairs(Highlights) do
        if highlight then
            highlight:Destroy()
        end

        Highlights[player] = nil
    end

    local neck = GetNeck()

    if neck then
        neck.Transform = CFrame.new()
    end

    Camera = Workspace.CurrentCamera

    Camera.CameraType = OriginalCamera.Type
    Camera.CameraSubject = GetHumanoid() or OriginalCamera.Subject

    LP.CameraMode = OriginalCamera.Mode
    LP.CameraMinZoomDistance = OriginalCamera.MinZoom
    LP.CameraMaxZoomDistance = OriginalCamera.MaxZoom

    UIS.MouseBehavior = Enum.MouseBehavior.Default

    if FOVGui then
        FOVGui:Destroy()
    end

    if ESPGui then
        ESPGui:Destroy()
    end

    if MusicGui then
        MusicGui:Destroy()
    end

    if MusicSound then
        MusicSound:Destroy()
    end
end)

--========================================================
-- WATERMARK
--========================================================

Library:SetWatermarkVisibility(true)
Library:SetWatermark(
    "Experiment 17 OPT | RightShift | Q Aim | F Fly | M Music"
)

print("==============================================")
print("Experiment 17 optimized loaded")
print("RightShift = Menu")
print("Q = Aimbot")
print("F = Fly")
print("M = Music enable/disable")
print("Music playlist HUD = screen overlay")
print("Local music API:", CustomAsset ~= nil)
print("File API:", FileAPI)
print("==============================================")

print("[Experiment 17 BUILD E17-20260816-1917]")

print("[Experiment 17 BUILD E17-20260816-1924-MUSIC-FOLDER-FIX]")

print("[Experiment 17 BUILD E17-20260816-1935-RAW-PATH-SCANNER]")

print("[Experiment 17 BUILD E17-20260816-1942-FS-SELFTEST]")
