-- Experiment 17 | Rivals | Callbacks.lua
-- Physical logical module; compiled independently by Loader.lua.

--========================================================
-- CALLBACKS
--========================================================

function ResetTarget()
    CurrentTarget = nil
end

Toggles.TeamCheck:OnChanged(ResetTarget)
Toggles.IgnoreFriends:OnChanged(ResetTarget)
Toggles.WallCheck:OnChanged(ResetTarget)
Options.AimPart:OnChanged(ResetTarget)
Options.MaxAimDistance:OnChanged(ResetTarget)

Toggles.Particles:OnChanged(UpdateParticles)
Options.ParticleType:OnChanged(UpdateParticles)
Options.ParticleRegion:OnChanged(UpdateParticles)
Options.ParticleRadius:OnChanged(UpdateParticles)
Options.ParticleAmount:OnChanged(UpdateParticles)
Options.ParticleColor:OnChanged(UpdateParticles)
Options.ParticleTexture:OnChanged(UpdateParticles)
Options.ParticleSize:OnChanged(UpdateParticles)
Options.ParticleSpeed:OnChanged(UpdateParticles)
Options.ParticleLifetime:OnChanged(UpdateParticles)

Toggles.XRay:OnChanged(function()
    if Toggles.XRay.Value then
        EnableXRay()
    else
        DisableXRay()
    end
end)

Options.XRayTransparency:OnChanged(function()
    if Toggles.XRay.Value then
        EnableXRay()
    end
end)

Options.GraphicsPreset:OnChanged(ApplyGraphics)

Toggles.FPSBoost:OnChanged(function()
    if Toggles.FPSBoost.Value then
        EnableFPS()
    else
        DisableFPS()
    end
end)

Options.FPSMode:OnChanged(function()
    if Toggles.FPSBoost.Value then
        DisableFPS()
        EnableFPS()
    end
end)

Toggles.SpeedHack:OnChanged(function()
    if not Toggles.SpeedHack.Value then
        local hum = GetHumanoid()

        if hum then
            hum.WalkSpeed = MovementDefaults.WalkSpeed
        end
    end
end)

Toggles.JumpHack:OnChanged(function()
    if not Toggles.JumpHack.Value then
        local hum = GetHumanoid()

        if hum then
            hum.JumpPower = MovementDefaults.JumpPower
            hum.JumpHeight = MovementDefaults.JumpHeight
            hum.UseJumpPower = MovementDefaults.UseJumpPower
        end
    end
end)

Toggles.BunnyHop:OnChanged(function()
    if not Toggles.BunnyHop.Value then
        BHopSpeed = 0
        JumpLatch = false
    end
end)

Toggles.Fly:OnChanged(function()
    if not Toggles.Fly.Value then
        local root = GetRoot()

        if root then
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end
end)

Toggles.MusicEnabled:OnChanged(function()
    if not Toggles.MusicEnabled.Value then
        MusicWasPlayingBeforeDisable = MusicSound.IsPlaying

        if MusicSound.IsPlaying then
            MusicSound:Pause()
        end

        return
    end

    local roundMode =
        Toggles.RoundMusic
        and Toggles.RoundMusic.Value

    -- Round mode ON: only play while the detector says the round is active.
    if roundMode and not RoundActive then
        return
    end

    -- Normal mode (Round Music OFF) behaves like a regular always-available player.
    if CurrentTrack <= 0 then
        if #Playlist > 0 then
            PlayTrack(1)
        end
    else
        local ok = pcall(function()
            MusicSound:Resume()
        end)

        if not ok then
            MusicSound:Play()
        end
    end
end)

Toggles.ShowMusicHUD:OnChanged(function()
    MusicGui.Enabled = true
    MusicOuter.Visible = Toggles.ShowMusicHUD.Value
    MusicFrame.Visible = true
end)

Toggles.MusicLoop:OnChanged(function()
    MusicSound.Looped = Toggles.MusicLoop.Value
    RefreshMusicHUD()
end)

Toggles.RoundMusic:OnChanged(function()
    UpdateRoundHUD()

    if Toggles.RoundMusic.Value then
        -- Auto-round mode enabled.
        EnsureRoundTimer()

        if RoundActive then
            if Toggles.MusicEnabled.Value then
                if CurrentTrack <= 0 and #Playlist > 0 then
                    PlayTrack(1)
                elseif CurrentTrack > 0 and not MusicSound.IsPlaying then
                    local ok = pcall(function()
                        MusicSound:Resume()
                    end)

                    if not ok then
                        MusicSound:Play()
                    end
                end
            end
        elseif MusicSound.IsPlaying then
            MusicSound:Pause()
        end

        return
    end

    -- Auto-round mode disabled: immediately return to a normal player.
    -- Nothing watches the round state for playback anymore.
    if Toggles.MusicEnabled.Value then
        if CurrentTrack <= 0 then
            if #Playlist > 0 then
                PlayTrack(1)
            end
        elseif not MusicSound.IsPlaying then
            local ok = pcall(function()
                MusicSound:Resume()
            end)

            if not ok then
                MusicSound:Play()
            end
        end
    end
end)

Options.MusicVolume:OnChanged(function()
    MusicSound.Volume = Options.MusicVolume.Value
end)
