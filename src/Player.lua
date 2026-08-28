-- Experiment 17 | Rivals | Player.lua
-- Physical logical module; compiled independently by Loader.lua.

--========================================================
-- MOVEMENT: SPEED / JUMP / BHOP / STRAFE / FLY
--========================================================

Connections.Movement = RunService.Heartbeat:Connect(function()
    if Unloaded then
        return
    end

    local hum = GetHumanoid()
    local root = GetRoot()

    if not hum or not root or hum.Health <= 0 then
        return
    end

    local grounded =
        hum.FloorMaterial ~= Enum.Material.Air

    local moveDirection = hum.MoveDirection
    local moving = moveDirection.Magnitude > 0.05

    -- WALK SPEED
    if Toggles.SpeedHack.Value
        and not Toggles.Fly.Value
        and not Toggles.BunnyHop.Value then

        local speed = Options.WalkSpeed.Value
        hum.WalkSpeed = speed

        if moving and grounded then
            local velocity = root.AssemblyLinearVelocity
            local flat = Vector3.new(
                moveDirection.X,
                0,
                moveDirection.Z
            )

            if flat.Magnitude > 0 then
                flat = flat.Unit

                root.AssemblyLinearVelocity = Vector3.new(
                    flat.X * speed,
                    velocity.Y,
                    flat.Z * speed
                )
            end
        end
    end

    -- JUMP POWER
    if Toggles.JumpHack.Value then
        local jumpPower = Options.JumpPower.Value

        hum.UseJumpPower = true
        hum.JumpPower = jumpPower

        local gravity = math.max(Workspace.Gravity, 1)
        hum.JumpHeight = (jumpPower * jumpPower) / (2 * gravity)
    end

    -- BHOP
    if Toggles.BunnyHop.Value and not Toggles.Fly.Value then
        local startSpeed = Options.BHopStartSpeed.Value

        if BHopSpeed <= 0 then
            BHopSpeed = startSpeed
        end

        -- Reset gained speed when the player stops moving.
        if not moving then
            BHopSpeed = startSpeed
            JumpLatch = false
        end

        local holdingSpace = UIS:IsKeyDown(Enum.KeyCode.Space)

        if holdingSpace and grounded and moving and not JumpLatch then
            JumpLatch = true

            BHopSpeed += Options.BHopGain.Value

            hum.Jump = true
            hum:ChangeState(Enum.HumanoidStateType.Jumping)

            local velocity = root.AssemblyLinearVelocity
            local jumpY =
                Toggles.JumpHack.Value
                and Options.JumpPower.Value
                or math.max(50, velocity.Y)

            root.AssemblyLinearVelocity = Vector3.new(
                moveDirection.Unit.X * BHopSpeed,
                jumpY,
                moveDirection.Unit.Z * BHopSpeed
            )
        end

        if not grounded or not holdingSpace then
            JumpLatch = false
        end

        if moving then
            local velocity = root.AssemblyLinearVelocity

            root.AssemblyLinearVelocity = Vector3.new(
                moveDirection.Unit.X * BHopSpeed,
                velocity.Y,
                moveDirection.Unit.Z * BHopSpeed
            )
        end
    else
        BHopSpeed = 0
        JumpLatch = false
    end

    -- AUTO STRAFE
    if Toggles.AutoStrafe.Value
        and not Toggles.Fly.Value
        and hum.FloorMaterial == Enum.Material.Air then

        Camera = Workspace.CurrentCamera

        local forward = Camera.CFrame.LookVector
        local right = Camera.CFrame.RightVector

        forward = Vector3.new(forward.X, 0, forward.Z)
        right = Vector3.new(right.X, 0, right.Z)

        if forward.Magnitude > 0 then
            forward = forward.Unit
        end

        if right.Magnitude > 0 then
            right = right.Unit
        end

        local wish = Vector3.zero

        if UIS:IsKeyDown(Enum.KeyCode.W) then
            wish += forward
        end

        if UIS:IsKeyDown(Enum.KeyCode.S) then
            wish -= forward
        end

        if UIS:IsKeyDown(Enum.KeyCode.A) then
            wish -= right
        end

        if UIS:IsKeyDown(Enum.KeyCode.D) then
            wish += right
        end

        if wish.Magnitude > 0 then
            wish = wish.Unit

            local targetSpeed = Options.StrafeSpeed.Value

            if Toggles.BunnyHop.Value then
                targetSpeed = math.max(targetSpeed, BHopSpeed)
            end

            local velocity = root.AssemblyLinearVelocity

            root.AssemblyLinearVelocity = Vector3.new(
                wish.X * targetSpeed,
                velocity.Y,
                wish.Z * targetSpeed
            )
        end
    end

    -- FLY
    if Toggles.Fly.Value then
        Camera = Workspace.CurrentCamera

        local move = Vector3.zero
        local forward = Camera.CFrame.LookVector
        local right = Camera.CFrame.RightVector

        if UIS:IsKeyDown(Enum.KeyCode.W) then
            move += forward
        end

        if UIS:IsKeyDown(Enum.KeyCode.S) then
            move -= forward
        end

        if UIS:IsKeyDown(Enum.KeyCode.A) then
            move -= right
        end

        if UIS:IsKeyDown(Enum.KeyCode.D) then
            move += right
        end

        if UIS:IsKeyDown(Enum.KeyCode.Space) then
            move += Vector3.yAxis
        end

        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
            move -= Vector3.yAxis
        end

        if move.Magnitude > 0 then
            move = move.Unit
        end

        root.AssemblyLinearVelocity =
            move * Options.FlySpeed.Value

        hum.PlatformStand = false
    end
end)

-- Strong jump request
Connections.JumpRequest = UIS.JumpRequest:Connect(function()
    if Unloaded or not Toggles.JumpHack.Value or Toggles.Fly.Value then
        return
    end

    local hum = GetHumanoid()
    local root = GetRoot()

    if not hum or not root or hum.Health <= 0 then
        return
    end

    if hum.FloorMaterial == Enum.Material.Air then
        return
    end

    local power = Options.JumpPower.Value

    hum.UseJumpPower = true
    hum.JumpPower = power
    hum.Jump = true
    hum:ChangeState(Enum.HumanoidStateType.Jumping)

    task.defer(function()
        if not root.Parent then
            return
        end

        local velocity = root.AssemblyLinearVelocity

        root.AssemblyLinearVelocity = Vector3.new(
            velocity.X,
            power,
            velocity.Z
        )
    end)
end)
