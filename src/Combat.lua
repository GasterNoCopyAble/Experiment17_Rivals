-- Experiment 17 | Rivals | Combat.lua
-- Physical logical module; compiled independently by Loader.lua.

--========================================================
-- AIMBOT
--========================================================

function GetAimPart(player)
    local char = player.Character

    if not char then
        return nil
    end

    local selected = Options.AimPart and Options.AimPart.Value or "Head"

    return char:FindFirstChild(selected)
        or char:FindFirstChild("Head")
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("HumanoidRootPart")
end

function ValidTarget(player, locked)
    if player == LP or not Alive(player) then
        return false
    end

    if Toggles.TeamCheck.Value and IsTeammate(player) then
        return false
    end

    if Toggles.IgnoreFriends.Value and IsFriend(player) then
        return false
    end

    if GetDistance(player) > Options.MaxAimDistance.Value then
        return false
    end

    local part = GetAimPart(player)

    if not part then
        return false
    end

    local screen, onScreen = Camera:WorldToViewportPoint(part.Position)

    if not onScreen or screen.Z <= 0 then
        return false
    end

    local center = Camera.ViewportSize / 2
    local screenDistance = (
        Vector2.new(screen.X, screen.Y)
        - center
    ).Magnitude

    if Toggles.UseFOV.Value then
        local allowed = Options.AimFOV.Value

        if locked then
            allowed *= 1.4
        end

        if screenDistance > allowed then
            return false
        end
    end

    if Toggles.WallCheck.Value and not RayVisible(player, part) then
        return false
    end

    return true, screenDistance
end

function FindTarget()
    local best = nil
    local bestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            local valid, distance = ValidTarget(player, false)

            if valid and distance < bestDistance then
                best = player
                bestDistance = distance
            end
        end
    end

    return best
end

--========================================================
-- FOV GUI
--========================================================

FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "Experiment17FOV"
FOVGui.ResetOnSpawn = false
FOVGui.IgnoreGuiInset = true
FOVGui.Parent = LP:WaitForChild("PlayerGui")

FOVCircle = Instance.new("Frame")
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Visible = false
FOVCircle.Parent = FOVGui

FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVCircle

FOVStroke = Instance.new("UIStroke")
FOVStroke.Thickness = 1
FOVStroke.Parent = FOVCircle


--========================================================
-- THIRD PERSON INPUT
--========================================================

Connections.InputBegan = UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton2
        and Toggles.ThirdPerson.Value then

        ThirdDragging = true
        UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
    end
end)

Connections.InputEnded = UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        ThirdDragging = false

        if Toggles.ThirdPerson.Value then
            UIS.MouseBehavior = Enum.MouseBehavior.Default
        end
    end
end)

Connections.CameraMouse = UIS.InputChanged:Connect(function(input)
    if not Toggles.ThirdPerson.Value or not ThirdDragging then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.MouseMovement then
        return
    end

    local sensitivity = Options.ThirdSensitivity.Value

    ThirdYaw -= math.rad(input.Delta.X * sensitivity)
    ThirdPitch -= math.rad(input.Delta.Y * sensitivity)

    ThirdPitch = math.clamp(
        ThirdPitch,
        math.rad(-80),
        math.rad(80)
    )
end)

Toggles.ThirdPerson:OnChanged(function()
    Camera = Workspace.CurrentCamera

    if Toggles.ThirdPerson.Value then
        local x, y = Camera.CFrame:ToOrientation()

        ThirdPitch = x
        ThirdYaw = y

        Camera.CameraType = Enum.CameraType.Scriptable
        LP.CameraMode = Enum.CameraMode.Classic
        ThirdDragging = false
        UIS.MouseBehavior = Enum.MouseBehavior.Default
    else
        ThirdDragging = false
        UIS.MouseBehavior = Enum.MouseBehavior.Default

        Camera.CameraType = OriginalCamera.Type
        Camera.CameraSubject = GetHumanoid() or OriginalCamera.Subject
        LP.CameraMode = OriginalCamera.Mode
    end
end)

--========================================================
-- AIM / THIRD PERSON / ANTI AIM RENDER
--========================================================

AimScanAccumulator = 0

Connections.Render = RunService.RenderStepped:Connect(function(dt)
    if Unloaded then
        return
    end

    Camera = Workspace.CurrentCamera

    local root = GetRoot()
    local humanoid = GetHumanoid()

    AimScanAccumulator += dt

    -- THIRD PERSON
    if Toggles.ThirdPerson.Value and root then
        Camera.CameraType = Enum.CameraType.Scriptable
        LP.CameraMode = Enum.CameraMode.Classic

        local rotation = CFrame.fromOrientation(
            ThirdPitch,
            ThirdYaw,
            0
        )

        local focus = root.Position + Vector3.new(
            0,
            Options.ThirdHeight.Value,
            0
        )

        local position =
            focus
            - rotation.LookVector * Options.ThirdDistance.Value
            + rotation.RightVector * Options.ThirdSide.Value

        Camera.CFrame = CFrame.lookAt(
            position,
            focus + rotation.LookVector * 6
        )
    end

    -- FOV
    local fov = Options.AimFOV.Value

    FOVCircle.Size = UDim2.fromOffset(fov * 2, fov * 2)
    FOVCircle.Position = UDim2.fromOffset(
        Camera.ViewportSize.X / 2,
        Camera.ViewportSize.Y / 2
    )
    FOVStroke.Color = Options.EnemyColor.Value

    FOVCircle.Visible =
        Toggles.AimEnabled.Value
        and Toggles.UseFOV.Value
        and Toggles.ShowFOV.Value

    -- AIMBOT
    if Toggles.AimEnabled.Value then
        -- Expensive target checks/raycasts are capped at 20 Hz.
        -- Camera still points at an already-valid target every rendered frame.
        if AimScanAccumulator >= 0.05 then
            AimScanAccumulator = 0

            if CurrentTarget and Toggles.TargetLock.Value then
                local valid = ValidTarget(CurrentTarget, true)

                if not valid then
                    CurrentTarget = nil
                end
            elseif not Toggles.TargetLock.Value then
                CurrentTarget = nil
            end

            if not CurrentTarget then
                CurrentTarget = FindTarget()
            end
        end

        if CurrentTarget then
            local part = GetAimPart(CurrentTarget)

            if part and part.Parent then
                Camera.CFrame = CFrame.lookAt(
                    Camera.CFrame.Position,
                    part.Position
                )
            else
                CurrentTarget = nil
            end
        end
    else
        CurrentTarget = nil
        AimScanAccumulator = 0
    end

    -- ANTI AIM
    if Toggles.AntiAim.Value and root and humanoid then
        humanoid.AutoRotate = false

        local mode = Options.AntiAimMode.Value
        local speed = Options.AntiAimSpeed.Value
        local neck = GetNeck()

        AntiAimTimer += dt

        local hideOffset =
            Toggles.HideHead.Value
            and Options.HeadHideAmount.Value
            or 0

        if mode == "Spin" then
            AntiAimAngle += math.rad(speed) * dt

            root.CFrame =
                CFrame.new(root.Position)
                * CFrame.Angles(
                    0,
                    AntiAimAngle,
                    0
                )

            if neck then
                neck.Transform = CFrame.new(0, -hideOffset, 0)
            end
        elseif mode == "Left/Right" then
            local switch =
                math.sin(
                    AntiAimTimer
                    * speed
                    / 90
                )

            local yaw =
                switch >= 0
                and math.rad(90)
                or math.rad(-90)

            local look = Camera.CFrame.LookVector
            local flat = Vector3.new(look.X, 0, look.Z)

            if flat.Magnitude > 0 then
                root.CFrame =
                    CFrame.lookAt(
                        root.Position,
                        root.Position + flat.Unit
                    )
                    * CFrame.Angles(
                        0,
                        yaw,
                        0
                    )
            end

            if neck then
                neck.Transform = CFrame.new(0, -hideOffset, 0)
            end
        elseif mode == "Up/Down" then
            local switch =
                math.sin(
                    AntiAimTimer
                    * speed
                    / 90
                )

            local pitch =
                switch >= 0
                and math.rad(80)
                or math.rad(-80)

            if neck then
                neck.Transform =
                    CFrame.new(0, -hideOffset, 0)
                    * CFrame.Angles(
                        pitch,
                        0,
                        0
                    )
            end
        end
    elseif humanoid then
        humanoid.AutoRotate = true

        local neck = GetNeck()

        if neck then
            neck.Transform = CFrame.new()
        end
    end
end)


--========================================================
-- GAZE DODGE
--========================================================

GazeAccumulator = 0

Connections.Gaze = RunService.Heartbeat:Connect(function(dt)
    GazeAccumulator += dt

    if GazeAccumulator < 0.10 then
        return
    end

    GazeAccumulator = 0

    if Unloaded or not Toggles.GazeDodge.Value then
        return
    end

    local myRoot = GetRoot()

    if not myRoot then
        return
    end

    local now = os.clock()

    if now - LastDodge < Options.DodgeCooldown.Value then
        return
    end

    local maxDistance = Options.GazeDistance.Value
    local threshold =
        math.cos(
            math.rad(
                Options.GazeAngle.Value
            )
        )

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LP or not Alive(player) then
            continue
        end

        if Toggles.TeamCheck.Value and IsTeammate(player) then
            continue
        end

        if Toggles.IgnoreFriends.Value and IsFriend(player) then
            continue
        end

        local char = player.Character
        local enemyHead =
            char
            and char:FindFirstChild("Head")

        if not enemyHead then
            continue
        end

        local delta =
            myRoot.Position
            - enemyHead.Position

        local distance = delta.Magnitude

        if distance > maxDistance or distance <= 0 then
            continue
        end

        local toMe = delta.Unit
        local dot =
            enemyHead.CFrame.LookVector:Dot(toMe)

        if dot >= threshold then
            local side =
                enemyHead.CFrame.RightVector
                * DodgeSide
                * Options.DodgeDistance.Value

            local destination =
                myRoot.Position + side

            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {GetCharacter()}

            local hit =
                Workspace:Raycast(
                    myRoot.Position,
                    side,
                    params
                )

            if hit then
                DodgeSide *= -1

                side =
                    enemyHead.CFrame.RightVector
                    * DodgeSide
                    * Options.DodgeDistance.Value

                destination =
                    myRoot.Position + side
            end

            local rotation = myRoot.CFrame.Rotation

            myRoot.CFrame =
                CFrame.new(destination)
                * rotation

            DodgeSide *= -1
            LastDodge = now
            break
        end
    end
end)
