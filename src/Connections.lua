-- Experiment 17 | Rivals | Connections.lua
-- Physical logical module; compiled independently by Loader.lua.

--========================================================
-- PLAYER CONNECTIONS
--========================================================

function SetupPlayer(player)
    if player == LP then
        return
    end

    LoadFriend(player)

    player.CharacterAdded:Connect(function()
        task.wait(0.15)

        if CurrentTarget == player then
            CurrentTarget = nil
        end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    SetupPlayer(player)
end

Connections.PlayerAdded =
    Players.PlayerAdded:Connect(SetupPlayer)

Connections.PlayerRemoving =
    Players.PlayerRemoving:Connect(function(player)
        DestroyESP(player)

        if Highlights[player] then
            Highlights[player]:Destroy()
            Highlights[player] = nil
        end

        FriendCache[player.UserId] = nil

        if CurrentTarget == player then
            CurrentTarget = nil
        end
    end)

Connections.Respawn =
    LP.CharacterAdded:Connect(function(character)
        local hum =
            character:WaitForChild(
                "Humanoid",
                10
            )

        if hum then
            task.wait(0.2)
            SaveMovementDefaults()
        end

        BHopSpeed = 0
        JumpLatch = false
        CurrentTarget = nil

        DestroyParticles()

        task.wait(0.25)
        UpdateParticles()
    end)

Connections.NewWorldObject =
    Workspace.DescendantAdded:Connect(function(object)
        if Toggles.XRay.Value and object:IsA("BasePart") then
            task.defer(ApplyXRayPart, object)
        end

        if Toggles.FPSBoost.Value then
            task.defer(ApplyFPSObject, object)
        end
    end)
