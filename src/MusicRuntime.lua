-- Experiment 17 | Rivals | MusicRuntime.lua
-- Physical logical module; compiled independently by Loader.lua.

--========================================================
-- MUSIC UPDATE LOOP
--========================================================

MusicUpdateAccumulator = 0

Connections.MusicUpdate = RunService.RenderStepped:Connect(function(dt)
    MusicUpdateAccumulator += dt

    if MusicUpdateAccumulator < 0.10 then
        return
    end

    MusicUpdateAccumulator = 0

    if Unloaded then
        return
    end

    local length = MusicSound.TimeLength or 0
    local position = MusicSound.TimePosition or 0

    if length > 0 then
        local ratio = math.clamp(position / length, 0, 1)
        ProgressFill.Size = UDim2.fromScale(ratio, 1)
    else
        ProgressFill.Size = UDim2.fromScale(0, 1)
    end

    ElapsedLabel.Text = FormatTime(position)
    RemainingLabel.Text = "-" .. FormatTime(math.max(0, length - position))

    PlayButton.Text =
        MusicSound.IsPlaying
        and "Pause"
        or "Play"

    LoopButton.Text =
        Toggles.MusicLoop.Value
        and "Loop ON"
        or "Loop"

    MusicOuter.Visible =
        Toggles.ShowMusicHUD.Value
        and not Unloaded

    MusicFrame.Visible = true
end)
