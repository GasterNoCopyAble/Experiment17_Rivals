-- Experiment 17 | Rivals | Player.lua
-- Physical logical module. Loaded in the shared Loader.lua environment.

--==================================================
-- PLAYER MOVEMENT
--==================================================

OriginalWalkSpeeds = setmetatable({}, { __mode = "k" })
OriginalJumpSettings = setmetatable({}, { __mode = "k" })
BunnyHopBonus = 0
BunnyHopLastJump = 0
HumanoidStateConnection = nil
SpeedBodyVelocity = nil
FlyBodyVelocity = nil
FlyBodyGyro = nil
FlyLinearVelocity = nil
FlyAttachment = nil
MicroTPAccumulator = 0
OriginalPlayerCamera = { CameraMode=LocalPlayer.CameraMode, MinZoom=LocalPlayer.CameraMinZoomDistance, MaxZoom=LocalPlayer.CameraMaxZoomDistance }
OriginalFOV = Camera and Camera.FieldOfView or 70
CachedLatestRoom, CachedLatestRoomNumber, CachedLatestRoomSeek = nil, -1, false
PlayerControls = nil
FlyVerticalPulseUntil = 0
SpinBodyAngularVelocity = nil
SpinOldAutoRotate = nil

pcall(function()
    local PS = LocalPlayer:FindFirstChild("PlayerScripts") or LocalPlayer:WaitForChild("PlayerScripts", 10)
    local PlayerModuleScript = PS and PS:FindFirstChild("PlayerModule")
    if PlayerModuleScript then
        local PlayerModule = require(PlayerModuleScript)
        PlayerControls = PlayerModule:GetControls()
    end
end)

function CR4.GetCameraMoveVector()
    Camera = workspace.CurrentCamera or Camera
    if not Camera then return Vector3.zero end
    local Raw = nil
    if PlayerControls then pcall(function() Raw = PlayerControls:GetMoveVector() end) end
    if typeof(Raw) == "Vector3" then
        local Look = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z)
        local Right = Vector3.new(Camera.CFrame.RightVector.X, 0, Camera.CFrame.RightVector.Z)
        if Look.Magnitude > 0.01 then Look = Look.Unit end
        if Right.Magnitude > 0.01 then Right = Right.Unit end
        local World = Right * Raw.X + Look * (-Raw.Z)
        if World.Magnitude > 1 then World = World.Unit end
        return World
    end
    local _, Humanoid = CR4.GetCharacter()
    return Humanoid and Humanoid.MoveDirection or Vector3.zero
end

function CR4.GetFlyCameraMoveVector()
    Camera = workspace.CurrentCamera or Camera
    if not Camera then return Vector3.zero end

    local Forward = Camera.CFrame.LookVector
    local Right = Camera.CFrame.RightVector
    local Move = Vector3.zero

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then Move += Forward end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then Move -= Forward end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then Move += Right end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then Move -= Right end

    if Move.Magnitude > 0.01 then return Move.Unit end

    local _, Humanoid = CR4.GetCharacter()
    local Fallback = Humanoid and Humanoid.MoveDirection or Vector3.zero
    if Fallback.Magnitude > 1 then Fallback = Fallback.Unit end
    return Fallback
end

function CR4.RefreshLatestRoomCache()
    local BestNumber, BestRoom = -1, nil
    for _, Room in ipairs(CurrentRooms:GetChildren()) do
        local Number = tonumber(Room.Name)
        if Number and Number > BestNumber then BestNumber = Number; BestRoom = Room end
    end
    CachedLatestRoom, CachedLatestRoomNumber = BestRoom, BestNumber
    CachedLatestRoomSeek = BestRoom and BestRoom:FindFirstChild("TriggerSeek", true) ~= nil or false
end

function CR4.IsSeekActive()
    if workspace:FindFirstChild("SeekMovingNewClone") then return true end
    return CachedLatestRoom and CachedLatestRoom.Parent and CachedLatestRoomSeek or false
end

function CR4.GetMovementSpeed()
    if State.SeekSpeedhack and CR4.IsSeekActive() then return math.clamp(State.SeekSpeed, 22, 28) end
    return math.clamp(State.WalkSpeed + (State.BunnyHop and BunnyHopBonus or 0), 0, 21 + State.BunnyHopMaxBonus)
end

function CR4.DestroySpeedBodyVelocity() CR4.SafeDestroy(SpeedBodyVelocity); SpeedBodyVelocity=nil end

function CR4.ApplyWalkSpeed()
    local _, Humanoid, Root = CR4.GetCharacter(); if not Humanoid or not Root then return end
    if OriginalWalkSpeeds[Humanoid] == nil then OriginalWalkSpeeds[Humanoid] = Humanoid.WalkSpeed end
    local Speed = CR4.GetMovementSpeed()
    if not State.WalkSpeedEnabled and not State.BunnyHop then CR4.DestroySpeedBodyVelocity(); return end
    if State.SpeedMethod == "WalkSpeed" then
        CR4.DestroySpeedBodyVelocity(); Humanoid.WalkSpeed = Speed
    elseif State.SpeedMethod == "BodyVelocity" then
        Humanoid.WalkSpeed = math.min(20, OriginalWalkSpeeds[Humanoid] or 16)
        if not SpeedBodyVelocity or SpeedBodyVelocity.Parent ~= Root then
            CR4.DestroySpeedBodyVelocity()
            SpeedBodyVelocity = Instance.new("BodyVelocity")
            SpeedBodyVelocity.Name = "Experiment17Speed"
            SpeedBodyVelocity.MaxForce = Vector3.new(State.BodyVelocityForce,0,State.BodyVelocityForce)
            SpeedBodyVelocity.P = 2500
            SpeedBodyVelocity.Parent = Root
        end
        local Dir = Humanoid.MoveDirection
        SpeedBodyVelocity.Velocity = Vector3.new(Dir.X*Speed, Root.AssemblyLinearVelocity.Y, Dir.Z*Speed)
    else
        CR4.DestroySpeedBodyVelocity()
        Humanoid.WalkSpeed = math.min(20, OriginalWalkSpeeds[Humanoid] or 16)
    end
end

function CR4.ApplyCFrameSpeed(dt)
    if not State.WalkSpeedEnabled or State.SpeedMethod ~= "CFrame" or State.FlyEnabled then return end
    local Character, Humanoid, Root = CR4.GetCharacter(); if not Character or not Humanoid or not Root or Humanoid.Health <= 0 then return end
    local Dir = Humanoid.MoveDirection
    if Dir.Magnitude > 0.05 then
        local Extra = CR4.GetMovementSpeed()
        local Delta = Dir.Unit * Extra * dt
        local Params = RaycastParams.new(); Params.FilterType = Enum.RaycastFilterType.Exclude; Params.FilterDescendantsInstances = {Character}; Params.IgnoreWater = true
        local Hit = workspace:Raycast(Root.Position, Delta, Params)
        if not Hit then Root.CFrame = Root.CFrame + Delta end
    end
end

function CR4.RestoreWalkSpeed()
    CR4.DestroySpeedBodyVelocity()
    local _, Humanoid = CR4.GetCharacter()
    if Humanoid and OriginalWalkSpeeds[Humanoid] ~= nil then Humanoid.WalkSpeed = OriginalWalkSpeeds[Humanoid]; OriginalWalkSpeeds[Humanoid] = nil end
    BunnyHopBonus = 0
end

LastForcedJump = 0

function CR4.ApplyJumpSettings()
    local _, Humanoid = CR4.GetCharacter(); if not Humanoid then return end
    if not OriginalJumpSettings[Humanoid] then
        OriginalJumpSettings[Humanoid] = { UseJumpPower=Humanoid.UseJumpPower, JumpPower=Humanoid.JumpPower, JumpHeight=Humanoid.JumpHeight }
    end
    if State.JumpEnabled or State.BunnyHop then
        pcall(function() Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end)
        Humanoid.UseJumpPower = true
        Humanoid.JumpPower = 0
        Humanoid.JumpHeight = 0
    end
end

function CR4.CanForceJump()
    local _, Humanoid = CR4.GetCharacter()
    if not Humanoid or Humanoid.Health <= 0 then return false end
    local StateType = Humanoid:GetState()
    return Humanoid.FloorMaterial ~= Enum.Material.Air
        or StateType == Enum.HumanoidStateType.Landed
        or StateType == Enum.HumanoidStateType.Running
        or StateType == Enum.HumanoidStateType.RunningNoPhysics
end

function CR4.ForceJump()
    if A90Active or (not State.JumpEnabled and not State.BunnyHop) then return end
    local _, Humanoid, Root = CR4.GetCharacter()
    if not Humanoid or Humanoid.Health <= 0 or not Root then return end
    if os.clock() - LastForcedJump < 0.12 or not CR4.CanForceJump() then return end
    LastForcedJump = os.clock()
    pcall(function() Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end)
    pcall(function() Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
    local JumpVelocity = math.clamp(State.JumpPower, 10, 50)
    Root.AssemblyLinearVelocity = Vector3.new(Root.AssemblyLinearVelocity.X, JumpVelocity, Root.AssemblyLinearVelocity.Z)
end

function CR4.RestoreJumpSettings()
    local _, Humanoid = CR4.GetCharacter(); local O = Humanoid and OriginalJumpSettings[Humanoid]
    if Humanoid and O then Humanoid.UseJumpPower=O.UseJumpPower; Humanoid.JumpPower=O.JumpPower; Humanoid.JumpHeight=O.JumpHeight; OriginalJumpSettings[Humanoid]=nil end
end

function CR4.BindHumanoidState()
    CR4.DisconnectConnection(HumanoidStateConnection); HumanoidStateConnection=nil
    local _, Humanoid = CR4.GetCharacter(); if not Humanoid then return end
    HumanoidStateConnection = Humanoid.StateChanged:Connect(function(_, NewState)
        if NewState == Enum.HumanoidStateType.Jumping and State.BunnyHop then
            BunnyHopLastJump = os.clock()
            BunnyHopBonus = math.min(State.BunnyHopMaxBonus, BunnyHopBonus + State.BunnyHopStep)
            CR4.ApplyWalkSpeed()
        end
    end)
end

CR4.TrackConnection(UserInputService.JumpRequest:Connect(function()
    FlyVerticalPulseUntil = os.clock() + 0.18
    if not State.FlyEnabled then CR4.ForceJump() end
end))

function CR4.MicroTPForward()
    local Character, Humanoid, Root = CR4.GetCharacter(); if not Character or not Humanoid or Humanoid.Health <= 0 or not Root then return end
    if Humanoid.MoveDirection.Magnitude < 0.05 then return end
    local Distance = math.clamp(State.MicroTPDistance, 0.1, 4)
    local Direction = Root.CFrame.LookVector * Distance
    local Params = RaycastParams.new(); Params.FilterType = Enum.RaycastFilterType.Exclude; Params.FilterDescendantsInstances = {Character}; Params.IgnoreWater = true
    local Result = workspace:Raycast(Root.Position, Direction, Params)
    if not Result then Root.CFrame = Root.CFrame + Direction end

end

function CR4.DestroyFlyObjects()
    CR4.SafeDestroy(FlyBodyVelocity); CR4.SafeDestroy(FlyBodyGyro); CR4.SafeDestroy(FlyLinearVelocity); CR4.SafeDestroy(FlyAttachment)
    FlyBodyVelocity=nil; FlyBodyGyro=nil; FlyLinearVelocity=nil; FlyAttachment=nil
end

function CR4.UpdateFly(dt)
    if not State.FlyEnabled then CR4.DestroyFlyObjects(); return end
    Camera = workspace.CurrentCamera or Camera
    local _, Humanoid, Root = CR4.GetCharacter(); if not Camera or not Humanoid or not Root or Humanoid.Health <= 0 then return end
    local Speed = (State.SeekSpeedhack and CR4.IsSeekActive()) and math.clamp(State.SeekSpeed,22,28) or math.clamp(State.FlySpeed,1,20)
    local Move = CR4.GetFlyCameraMoveVector()
    local Vertical = 0
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) or os.clock() < FlyVerticalPulseUntil then Vertical += 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C) then Vertical -= 1 end
    local Velocity = Move*Speed + Vector3.new(0,Vertical*Speed,0)
    if State.FlyMethod == "BodyVelocity" then
        if not FlyBodyVelocity or FlyBodyVelocity.Parent ~= Root then
            CR4.DestroyFlyObjects()
            FlyBodyVelocity = Instance.new("BodyVelocity"); FlyBodyVelocity.Name="Experiment17Fly"; FlyBodyVelocity.MaxForce=Vector3.new(1e9,1e9,1e9); FlyBodyVelocity.P=25000; FlyBodyVelocity.Velocity=Vector3.zero; FlyBodyVelocity.Parent=Root
        end
        FlyBodyVelocity.MaxForce = Vector3.new(1e9,1e9,1e9)
        FlyBodyVelocity.Velocity = Velocity
        Root.AssemblyLinearVelocity = Velocity
    elseif State.FlyMethod == "LinearVelocity" then
        if not FlyLinearVelocity or FlyLinearVelocity.Parent ~= Root then
            CR4.DestroyFlyObjects()
            FlyAttachment=Instance.new("Attachment"); FlyAttachment.Name="Experiment17FlyAttachment"; FlyAttachment.Parent=Root
            FlyLinearVelocity=Instance.new("LinearVelocity"); FlyLinearVelocity.Name="Experiment17LinearFly"; FlyLinearVelocity.Attachment0=FlyAttachment; FlyLinearVelocity.RelativeTo=Enum.ActuatorRelativeTo.World; FlyLinearVelocity.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector; FlyLinearVelocity.ForceLimitsEnabled=false; FlyLinearVelocity.Parent=Root
        end
        FlyLinearVelocity.VectorVelocity = Velocity
        Root.AssemblyLinearVelocity = Velocity
    else
        CR4.DestroyFlyObjects(); Root.AssemblyLinearVelocity = Vector3.zero
        local Delta = Velocity*dt; if Delta.Magnitude > 0 then Root.CFrame = Root.CFrame + Delta end
    end
end

ThirdPersonCurrentCF = nil
ThirdPersonVisibleParts = {}
ThirdPersonCharacter = nil

function CR4.RefreshThirdPersonParts(Character)
    ThirdPersonCharacter = Character
    table.clear(ThirdPersonVisibleParts)
    if not Character then return end
    for _, Object in ipairs(Character:GetDescendants()) do
        if Object:IsA("BasePart") or Object:IsA("Decal") then table.insert(ThirdPersonVisibleParts, Object) end
    end
end

function CR4.EnforceThirdPersonVisibility()
    local Character = LocalPlayer.Character
    if Character ~= ThirdPersonCharacter then CR4.RefreshThirdPersonParts(Character) end
    for Index = #ThirdPersonVisibleParts, 1, -1 do
        local Object = ThirdPersonVisibleParts[Index]
        if not Object or not Object.Parent then
            table.remove(ThirdPersonVisibleParts, Index)
        elseif Object:IsA("BasePart") then
            Object.LocalTransparencyModifier = 0
        elseif Object:IsA("Decal") and Object.Name:lower() == "face" then
            Object.Transparency = 0
        end
    end
end

function CR4.ApplyThirdPerson()
    Camera = workspace.CurrentCamera or Camera
    if State.ThirdPerson then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMinZoomDistance = 0.5
        LocalPlayer.CameraMaxZoomDistance = math.max(2, State.ThirdPersonOffsetZ + 4)
        if Camera then Camera.CameraType = Enum.CameraType.Scriptable end
        CR4.RefreshThirdPersonParts(LocalPlayer.Character)
    else
        ThirdPersonCurrentCF = nil
        LocalPlayer.CameraMode = OriginalPlayerCamera.CameraMode
        LocalPlayer.CameraMinZoomDistance = OriginalPlayerCamera.MinZoom
        LocalPlayer.CameraMaxZoomDistance = OriginalPlayerCamera.MaxZoom

        local RuntimeT = CR4.GetRuntimeStateTable()
        if Camera then Camera.CameraType = Enum.CameraType.Scriptable end
        if RuntimeT and type(RuntimeT.update) == "function" then pcall(RuntimeT.update) end
    end
end

function CR4.UpdateThirdPersonCamera(DeltaTime)
    if not State.ThirdPerson or State.SpectateEnabled or A90Active or AntiScreechBusy then
        ThirdPersonCurrentCF = nil
        return
    end

    Camera = workspace.CurrentCamera or Camera
    if not Camera then return end

    local Character, Humanoid, Root = CR4.GetCharacter()
    if not Character or not Humanoid or Humanoid.Health <= 0 or not Root then return end

    local RuntimeT = CR4.GetRuntimeStateTable()
    local BaseCF = RuntimeT and RuntimeT.finalCamCFrame
    if typeof(BaseCF) ~= "CFrame" then BaseCF = Camera.CFrame end

    local X = math.clamp(State.ThirdPersonOffsetX or 0, -20, 20)
    local Y = math.clamp(State.ThirdPersonOffsetY or 3, -5, 20)
    local Z = math.clamp(State.ThirdPersonOffsetZ or State.ThirdPersonDistance or 10, 2, 35)

    local Origin = BaseCF.Position
    local DesiredPosition = Origin + BaseCF.RightVector * X + BaseCF.UpVector * Y - BaseCF.LookVector * Z

    local Ray = DesiredPosition - Origin
    if Ray.Magnitude > 0.01 then
        local Params = RaycastParams.new()
        Params.FilterType = Enum.RaycastFilterType.Exclude
        Params.FilterDescendantsInstances = { Character }
        Params.IgnoreWater = true

        local Hit = workspace:Raycast(Origin, Ray, Params)
        if Hit then
            local SafeDistance = math.max(0.6, (Hit.Position - Origin).Magnitude - 0.35)
            DesiredPosition = Origin + Ray.Unit * SafeDistance
        end
    end

    local TargetCF = CFrame.lookAlong(DesiredPosition, BaseCF.LookVector, BaseCF.UpVector)
    local Smooth = math.clamp(State.ThirdPersonSmooth or 0.22, 0, 1)
    if not ThirdPersonCurrentCF then
        ThirdPersonCurrentCF = TargetCF
    elseif Smooth <= 0.01 then
        ThirdPersonCurrentCF = TargetCF
    else
        local dt = tonumber(DeltaTime) or (1 / 60)
        local Alpha = 1 - math.exp(-dt * (6 + Smooth * 28))
        ThirdPersonCurrentCF = ThirdPersonCurrentCF:Lerp(TargetCF, math.clamp(Alpha, 0.05, 1))
    end

    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = ThirdPersonCurrentCF
    Camera.Focus = CFrame.new(Origin)
    CR4.EnforceThirdPersonVisibility()
end

function CR4.ApplyCameraOptions()
    Camera = workspace.CurrentCamera or Camera; if not Camera then return end
    if State.ThirdPerson then CR4.ApplyThirdPerson() end
    if State.MouseUnlock then UserInputService.MouseBehavior=Enum.MouseBehavior.Default; UserInputService.MouseIconEnabled=true end
    if State.FOVOverride then Camera.FieldOfView=State.FOV end
end

function CR4.RestoreCameraOptions()
    State.MouseUnlock=false; if Camera then Camera.FieldOfView=OriginalFOV end
    State.ThirdPerson=false; CR4.ApplyThirdPerson(); CR4.DestroyFlyObjects()
end

function CR4.StopCharacterSpin()
    CR4.SafeDestroy(SpinBodyAngularVelocity); SpinBodyAngularVelocity=nil
    local _,Humanoid=CR4.GetCharacter(); if Humanoid and SpinOldAutoRotate~=nil then Humanoid.AutoRotate=SpinOldAutoRotate end
    SpinOldAutoRotate=nil
end

function CR4.UpdateCharacterSpin()
    if not State.FunCameraSpin then CR4.StopCharacterSpin(); return end
    local _,Humanoid,Root=CR4.GetCharacter(); if not Humanoid or not Root or Humanoid.Health<=0 then return end
    if SpinOldAutoRotate==nil then SpinOldAutoRotate=Humanoid.AutoRotate end
    Humanoid.AutoRotate=false
    if not SpinBodyAngularVelocity or SpinBodyAngularVelocity.Parent~=Root then
        CR4.SafeDestroy(SpinBodyAngularVelocity)
        SpinBodyAngularVelocity=Instance.new("BodyAngularVelocity"); SpinBodyAngularVelocity.Name="Experiment17CharacterSpin"; SpinBodyAngularVelocity.MaxTorque=Vector3.new(0,1e9,0); SpinBodyAngularVelocity.P=15000; SpinBodyAngularVelocity.Parent=Root
    end
    SpinBodyAngularVelocity.AngularVelocity=Vector3.new(0,math.rad(State.FunCameraSpinSpeed),0)
end

--==================================================
-- SPECTATE
--==================================================

function CR4.StopSpectate()
    State.SpectateEnabled = false
    Camera = workspace.CurrentCamera
    local _, Humanoid = CR4.GetCharacter()
    if Camera and Humanoid then
        Camera.CameraSubject = Humanoid
        Camera.CameraType = Enum.CameraType.Custom
    end
end

function CR4.UpdateSpectate()
    if not State.SpectateEnabled then return end
    Camera = workspace.CurrentCamera
    local TargetPlayer = State.SpectatePlayerName and Players:FindFirstChild(State.SpectatePlayerName)
    local TargetCharacter = TargetPlayer and TargetPlayer.Character
    local TargetHumanoid = TargetCharacter and TargetCharacter:FindFirstChildOfClass("Humanoid")

    if Camera and TargetHumanoid and TargetHumanoid.Health > 0 then
        Camera.CameraSubject = TargetHumanoid
        Camera.CameraType = Enum.CameraType.Custom
    else
        CR4.StopSpectate()
        if Toggles.SpectateEnabled then Toggles.SpectateEnabled:SetValue(false) end
    end
end
