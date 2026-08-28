-- Experiment 17 | Rivals | World.lua
-- Physical logical module. Loaded in the shared Loader.lua environment.

--==================================================
-- WORLD WATCHERS / BATCHED ROOM PROCESSING
--==================================================

RoomConnections = setmetatable({}, { __mode = "k" })
RoomBatching = setmetatable({}, { __mode = "k" })
RoomDirty = setmetatable({}, { __mode = "k" })
DropsConnection = nil

function CR4.ProcessWorldObject(Object)
    if IsUnloading or not Object or not Object.Parent then return end

    if Object:IsA("ProximityPrompt") then
        CR4.TrackPrompt(Object)
        local function RecheckAncestors()
            if not Object or not Object.Parent then return end
            local A=Object.Parent
            for _=1,8 do
                if not A or A==workspace then break end
                CR4.ProcessESPObject(A)
                A=A.Parent
            end
        end
        RecheckAncestors()
        task.delay(0.12, RecheckAncestors)
        task.delay(0.45, RecheckAncestors)
    end
    CR4.ProcessESPObject(Object)
    CR4.ProcessXRayObject(Object)
    if State.LowGFX then CR4.ApplyLowGFXObject(Object) end
    if State.NoShadows then CR4.ApplyNoShadowObject(Object) end

    if Object.Name == "TriggerSeek" and CachedLatestRoom and Object:IsDescendantOf(CachedLatestRoom) then CachedLatestRoomSeek = true end

    if Object.Name == "PathfindNodes" then
        local Room=Object.Parent
        while Room and Room.Parent~=CurrentRooms do Room=Room.Parent end
        local N=Room and tonumber(Room.Name)
        if N then
            local Prev=CurrentRooms:FindFirstChild(tostring(N-1))
            if Prev then
                local D=Prev:FindFirstChild("Door",true) or Prev:FindFirstChild("DoorNormal",true)
                local T=D and CR4.GetDoorTarget(D)
                if T then CR4.RegisterESP(T,"DangerDoor") end
            end
        end
    end

    if State.CustomTexture and State.CustomTextureMode == "Whole Map" and not CR4.IsPlayerCharacterObject(Object) then
        local Id = CR4.NormalizeAssetId(State.CustomTextureID)
        if Id then CR4.ApplyTextureObject(Object, Id) end
    end
end

function CR4.ConnectRoom(Room)
    if not Room or not Room.Parent or RoomConnections[Room] then return end
    RoomBatching[Room] = true
    local Pending = {}
    local Seen = setmetatable({}, { __mode = "k" })

    local WorkerRunning = false

    local function Queue(Object)
        if Object and Object.Parent and not Seen[Object] then
            Seen[Object] = true
            table.insert(Pending, Object)
        end
    end

    local function StartWorker()
        if WorkerRunning or IsUnloading then return end
        WorkerRunning = true
        task.spawn(function()
            local Index = 1
            while Index <= #Pending and Room.Parent and not IsUnloading do
                local Budget = 8
                while Budget > 0 and Index <= #Pending do
                    local Object = Pending[Index]
                    Index += 1
                    Budget -= 1
                    if Object and Object.Parent then
                        CR4.ProcessWorldObject(Object)
                        if not Object:IsA("BasePart") and not Object:IsA("ProximityPrompt") then
                            local Children = Object:GetChildren()
                            for _, Child in ipairs(Children) do Queue(Child) end
                        end
                    end
                end
                RunService.Heartbeat:Wait()
            end
            Pending = {}
            Seen = setmetatable({}, { __mode = "k" })
            WorkerRunning = false
            RoomBatching[Room] = false
            if tonumber(Room.Name) and tonumber(Room.Name) >= CachedLatestRoomNumber then CR4.RefreshLatestRoomCache() end
            if State.SmartPath then task.defer(CR4.UpdateSmartPath, true) end
        end)
    end

    RoomConnections[Room] = Room.DescendantAdded:Connect(function(Object)
        Queue(Object)
        StartWorker()
    end)

    Queue(Room)
    for _, Child in ipairs(Room:GetChildren()) do Queue(Child) end
    StartWorker()
end

function CR4.ConnectDrops(Drops)
    CR4.DisconnectConnection(DropsConnection)
    DropsConnection = nil
    if not Drops then return end
    task.spawn(function() CR4.ScanESPContainer(Drops, 120); CR4.BuildTextureTargetList() end)
    DropsConnection = Drops.DescendantAdded:Connect(function(Object)
        task.defer(CR4.ProcessWorldObject, Object)
        task.defer(CR4.BuildTextureTargetList)
    end)
end

for _, Room in ipairs(CurrentRooms:GetChildren()) do CR4.ConnectRoom(Room) end
CR4.RefreshLatestRoomCache()
CR4.ConnectDrops(workspace:FindFirstChild("Drops"))

CR4.TrackConnection(CurrentRooms.ChildAdded:Connect(function(Room)
    if tonumber(Room.Name) then CR4.RefreshLatestRoomCache() end
    task.delay(0.12, function()
        if Room and Room.Parent == CurrentRooms and not IsUnloading then CR4.ConnectRoom(Room) end
    end)
end))

CR4.TrackConnection(CurrentRooms.ChildRemoved:Connect(function(Room)
    if Room == CachedLatestRoom then CR4.RefreshLatestRoomCache() end
end))

CR4.TrackConnection(workspace.ChildAdded:Connect(function(Object)
    task.defer(function()
        if IsUnloading or not Object.Parent then return end
        if Object.Name == "Drops" then CR4.ConnectDrops(Object); return end

        local Name = Object.Name
        if Name == "RushMoving" or Name == "AmbushMoving" or Name == "SeekMovingNewClone"
            or Name == "Dread" or Name == "Screech" or OtherMonsterNames[Name]
            or Name == "A60" or Name == "A120" or Name == "BackdoorLookman" or Name == "BackdoorRush"
            or Name == "GlitchAmbush" or Name == "EntityModel" or Name == "NDA5OiBDT05GTElDVA=="
            or Name == "GlitchFragment" or Name == "Glitch Fragment" or Name == "YellowLight"
            or Name == "Glowstick" or Name == "Glowsticks" or Name == "Lighter" or Name == "Crucifix"
            or Name == "RiftCandle" or Name == "StarVial" or Name == "Shears"
            or Name == "Bulklight" or Name == "BandagePack" or Name == "Straplight" then
            CR4.ScanESPContainer(Object, 100)
            local Screech = CR4.GetScreechTarget(Object)
            if Screech then CR4.FaceScreechAndRestore(Screech) end
        end

        if State.CustomTexture and State.CustomTextureMode == "Whole Map" and not Players:GetPlayerFromCharacter(Object) then
            local Id = CR4.NormalizeAssetId(State.CustomTextureID)
            if Id then CR4.ApplyTextureRoot(Object, Id) end
        end
    end)
end))

CR4.TrackConnection(workspace.DescendantAdded:Connect(function(Object)
    CR4.RemoveDupeObject(Object)
    CR4.ProcessAntiTouchObject(Object)
    if State.LowGFX and not CR4.IsPlayerCharacterObject(Object) then CR4.ApplyLowGFXObject(Object) end
    if State.NoShadows and not CR4.IsPlayerCharacterObject(Object) then CR4.ApplyNoShadowObject(Object) end
    if CR4.ShouldProcessESPObject(Object) and not Object:IsDescendantOf(CurrentRooms) then task.defer(CR4.ProcessESPObject, Object) end
    local ScreechTarget=CR4.GetScreechTarget(Object)
    if ScreechTarget then task.defer(function() task.wait(0.03); CR4.FaceScreechAndRestore(ScreechTarget) end) end
end))

CR4.TrackConnection(Lighting.DescendantAdded:Connect(function(Object)
    CR4.RegisterLightingObject(Object)
    task.defer(CR4.EnforceVisualState)
end))

CameraDescendantConnection = nil
function CR4.ConnectCameraVisualWatcher(NewCamera)
    CR4.DisconnectConnection(CameraDescendantConnection)
    CameraDescendantConnection = nil
    Camera = NewCamera or workspace.CurrentCamera or Camera
    if not Camera then return end
    for _, Object in ipairs(Camera:GetDescendants()) do CR4.RegisterLightingObject(Object) end
    CameraDescendantConnection = Camera.DescendantAdded:Connect(function(Object)
        CR4.RegisterLightingObject(Object)
        task.defer(CR4.EnforceVisualState)
    end)
end
CR4.ConnectCameraVisualWatcher(workspace.CurrentCamera)
CR4.TrackConnection(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    CR4.ConnectCameraVisualWatcher(workspace.CurrentCamera)
end))

pcall(function()
    RunService:BindToRenderStep("Experiment17CameraPre", Enum.RenderPriority.Camera.Value - 10, function()
        if IsUnloading or A90Active or not State.ThirdPerson or State.SpectateEnabled then return end
        CR4.ApplyThirdPerson()
    end)
end)

pcall(function()
    RunService:BindToRenderStep("Experiment17CameraEnforce", 10000, function(DeltaTime)
        if IsUnloading or A90Active or AntiScreechBusy then return end
        Camera = workspace.CurrentCamera or Camera
        if not Camera then return end
        if State.ThirdPerson and not State.SpectateEnabled then CR4.UpdateThirdPersonCamera(DeltaTime) end
        if State.MouseUnlock then UserInputService.MouseBehavior = Enum.MouseBehavior.Default; UserInputService.MouseIconEnabled = true end
        if State.FOVOverride then Camera.FieldOfView = State.FOV end
    end)
end)

--==================================================
-- UPDATE LOOPS
--==================================================

BunnyAccumulator = 0
ESPReconcileAccumulator = 0
TimerAccumulator = 0

CR4.TrackConnection(RunService.RenderStepped:Connect(function(DeltaTime)
    if IsUnloading then return end

    local A90Locked = CR4.UpdateA90Protection()
    if not A90Locked then
        if State.WalkSpeedEnabled or State.BunnyHop then CR4.ApplyWalkSpeed() else CR4.DestroySpeedBodyVelocity() end
        CR4.ApplyCFrameSpeed(DeltaTime)
        CR4.UpdateFly(DeltaTime)
        if State.JumpEnabled or State.BunnyHop then
            CR4.ApplyJumpSettings()
            if not State.FlyEnabled and UserInputService:IsKeyDown(Enum.KeyCode.Space) then CR4.ForceJump() end
        end
        CR4.ApplyCameraOptions()
        CR4.UpdateSpectate()

        if State.MicroTPEnabled then
            MicroTPAccumulator += DeltaTime
            if MicroTPAccumulator >= State.MicroTPInterval then MicroTPAccumulator=0; CR4.MicroTPForward() end
        else MicroTPAccumulator=0 end

        if not AntiScreechBusy then CR4.UpdateCharacterSpin() end

        if State.AntiTeleport or State.AntiEntityTP or ThreatEvadeActive then CR4.UpdatePositionProtection() end
    else
        CR4.DestroySpeedBodyVelocity()
        CR4.DestroyFlyObjects()
        CR4.StopCharacterSpin()
        MicroTPAccumulator = 0
    end

    TimerAccumulator += DeltaTime
    if TimerAccumulator >= 0.1 then TimerAccumulator=0; CR4.UpdateBackdoorsTimer() end

    BunnyAccumulator += DeltaTime
    if BunnyAccumulator >= 0.25 then
        BunnyAccumulator = 0
        if State.BunnyHop and BunnyHopBonus > 0 and os.clock() - BunnyHopLastJump > 1.2 then
            BunnyHopBonus = 0
            if State.WalkSpeedEnabled then CR4.ApplyWalkSpeed() else CR4.RestoreWalkSpeed() end
        end
    end
end))

CR4.TrackConnection(RunService.Heartbeat:Connect(function(DeltaTime)
    if IsUnloading then return end

    AutoLootAccumulator += DeltaTime
    if AutoLootAccumulator >= 0.12 then AutoLootAccumulator = 0; CR4.ScanAutoLootRegistry() end

    CR4.UpdateRuntimeProtectionStates()
    CR4.UpdateFigureProtection(DeltaTime)
    CR4.UpdateEyesProtection(DeltaTime)
    CR4.UpdatePositionProtection()

    if State.Room50AutoCode and CurrentRooms:FindFirstChild("50") then
        Room50Accumulator += DeltaTime
        if Room50Accumulator >= 0.3 then Room50Accumulator = 0; CR4.ShowRoom50Code(false) end
    else
        Room50Accumulator = 0
    end

    ESPReconcileAccumulator += DeltaTime
    if ESPReconcileAccumulator >= 8.0 then
        ESPReconcileAccumulator = 0
        for Target, Entry in pairs(ESPEntries) do
            if not Target or not Target.Parent then CR4.DestroyESPEntry(Target)
            elseif ESPCategories[Entry.Category] and ESPCategories[Entry.Category].Enabled then CR4.ConfigureESPEntry(Entry) end
        end
    end

    if State.SmartPath then CR4.UpdateSmartPath(false) end
end))

CR4.TrackConnection(LocalPlayer.CharacterAdded:Connect(function(Character)
    task.spawn(function()
        Character:WaitForChild("Humanoid", 10)
        Character:WaitForChild("HumanoidRootPart", 10)
        task.wait(0.2)
        CR4.BindHumanoidState()
        CR4.ApplyJumpSettings()
        CR4.ApplyWalkSpeed()
        CR4.RefreshThirdPersonParts(Character)
    end)
end))

CR4.BindHumanoidState()

CR4.TrackConnection(Players.PlayerRemoving:Connect(function(Player)
    if State.SpectatePlayerName == Player.Name then
        CR4.StopSpectate()
        if Toggles.SpectateEnabled then Toggles.SpectateEnabled:SetValue(false) end
    end
end))
