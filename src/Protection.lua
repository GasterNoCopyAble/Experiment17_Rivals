-- Experiment 17 | Rivals | Protection.lua
-- Physical logical module. Loaded in the shared Loader.lua environment.

--==================================================
-- SOURCE-INSPIRED CLIENT PROTECTIONS / ROOM 50
--==================================================

RenamedClientModules = {}
OriginalShadeResult = nil
FakeShadeResult = nil
AntiTouchOriginal = setmetatable({}, { __mode = "k" })
FigureRemoteAccumulator = 0
EyesAccumulator = 0
Room50Accumulator = 0
Room50LastCode = ""

Room50ShapeByOffset = {
    [0] = "pentagon",
    [50] = "triangle",
    [100] = "square",
    [150] = "star",
    [200] = "cross",
    [250] = "hexagon",
    [300] = "diamond",
    [350] = "circle",
}

function CR4.GetRemoteListenerModules()
    local PG = LocalPlayer:FindFirstChild("PlayerGui")
    local MainUI = PG and PG:FindFirstChild("MainUI")
    if not MainUI then return nil end
    local Initiator = MainUI:FindFirstChild("Initiator")
    local MainGame = Initiator and Initiator:FindFirstChild("Main_Game")
    local RemoteListener = MainGame and MainGame:FindFirstChild("RemoteListener")
    return RemoteListener and RemoteListener:FindFirstChild("Modules")
end

function CR4.SetClientModuleDisabled(ModuleName, Disabled)
    local Modules = CR4.GetRemoteListenerModules()
    if not Modules then return false end

    local Normal = Modules:FindFirstChild(ModuleName)
    local DisabledName = ModuleName .. "X"
    local DisabledModule = Modules:FindFirstChild(DisabledName)


    if Disabled then
        if Normal then
            RenamedClientModules[ModuleName] = Normal
            pcall(function() Normal.Name = DisabledName end)
            return true
        end
        return DisabledModule ~= nil
    else
        local Module = DisabledModule or RenamedClientModules[ModuleName]
        if Module and Module.Parent then
            pcall(function() Module.Name = ModuleName end)
            RenamedClientModules[ModuleName] = nil
            return true
        end
    end
    return false
end

function CR4.ApplyAntiHalt()
    local Remotes = ReplicatedStorage:FindFirstChild("RemotesFolder")
    if not Remotes then return end

    if State.AntiHalt then
        if not OriginalShadeResult or not OriginalShadeResult.Parent then
            local Real = Remotes:FindFirstChild("ShadeResult")
            if Real and Real ~= FakeShadeResult then OriginalShadeResult = Real end
        end

        if OriginalShadeResult and OriginalShadeResult.Parent == Remotes then
            pcall(function() OriginalShadeResult.Parent = ReplicatedStorage end)
        end

        if not FakeShadeResult or not FakeShadeResult.Parent then
            FakeShadeResult = Instance.new("RemoteEvent")
            FakeShadeResult.Name = "ShadeResult"
            FakeShadeResult.Parent = Remotes
        elseif FakeShadeResult.Parent ~= Remotes then
            FakeShadeResult.Name = "ShadeResult"
            FakeShadeResult.Parent = Remotes
        end
    else
        if FakeShadeResult then CR4.SafeDestroy(FakeShadeResult); FakeShadeResult = nil end
        if OriginalShadeResult and OriginalShadeResult.Parent then
            pcall(function()
                OriginalShadeResult.Name = "ShadeResult"
                OriginalShadeResult.Parent = Remotes
            end)
        end
    end
end

function CR4.RemoveDupeObject(Object)
    if not State.AntiDupe or not Object or not Object.Parent then return end
    if Object.Name == "SideroomDupe" or Object.Name == "DupeRoom" then
        task.defer(function()
            if State.AntiDupe and Object and Object.Parent then CR4.SafeDestroy(Object) end
        end)
    end
end

function CR4.ScanAntiDupe()
    if not State.AntiDupe then return end
    for _, Room in ipairs(CurrentRooms:GetChildren()) do
        CR4.RemoveDupeObject(Room)
        local Dupe = Room:FindFirstChild("SideroomDupe") or Room:FindFirstChild("DupeRoom")
        if Dupe then CR4.RemoveDupeObject(Dupe) end
    end
    for _, Object in ipairs(workspace:GetChildren()) do CR4.RemoveDupeObject(Object) end
end

function CR4.SetAntiTouchPart(Part, Disabled)
    if not Part or not Part:IsA("BasePart") then return end
    if Disabled then
        if AntiTouchOriginal[Part] == nil then AntiTouchOriginal[Part] = Part.CanTouch end
        Part.CanTouch = false
    elseif AntiTouchOriginal[Part] ~= nil then
        if Part.Parent then Part.CanTouch = AntiTouchOriginal[Part] end
        AntiTouchOriginal[Part] = nil
    end
end

function CR4.IsInsideSnare(Object)
    local Current = Object
    while Current and Current ~= CurrentRooms do
        if Current.Name == "Snare" then return true end
        Current = Current.Parent
    end
    return false
end

function CR4.HasSeekTrigger()
    return CurrentRooms:FindFirstChild("TriggerSeek", true) ~= nil
end

function CR4.ProcessAntiTouchObject(Object)
    if not Object or not Object.Parent then return end

    if State.AntiSnare then
        if Object.Name == "Snare" then
            local Hitbox = Object:FindFirstChild("Hitbox", true)
            if Hitbox and Hitbox:IsA("BasePart") then CR4.SetAntiTouchPart(Hitbox, true) end
        elseif Object:IsA("BasePart") and Object.Name == "Hitbox" and CR4.IsInsideSnare(Object) then
            CR4.SetAntiTouchPart(Object, true)
        end
    end

    if State.AntiSeekObstacles and Object:IsA("BasePart") and Object.Name == "HurtPart" then
        if CR4.HasSeekTrigger() then CR4.SetAntiTouchPart(Object, true) end
    end
end

function CR4.ScanAntiTouch()
    if not State.AntiSnare and not State.AntiSeekObstacles then return end
    task.spawn(function()
        local Desc = CurrentRooms:GetDescendants()
        for Index, Object in ipairs(Desc) do
            if IsUnloading then return end
            CR4.ProcessAntiTouchObject(Object)
            if Index % 120 == 0 then task.wait() end
        end
    end)
end

function CR4.RestoreAntiTouch()
    for Part, Original in pairs(AntiTouchOriginal) do
        if Part and Part.Parent then pcall(function() Part.CanTouch = Original end) end
        AntiTouchOriginal[Part] = nil
    end
end

function CR4.UpdateFigureProtection(DeltaTime)
    if not State.AntiFigure then FigureRemoteAccumulator = 0; return end
    FigureRemoteAccumulator += DeltaTime
    if FigureRemoteAccumulator < 0.08 then return end
    FigureRemoteAccumulator = 0

    local Remotes = ReplicatedStorage:FindFirstChild("RemotesFolder")
    local Crouch = Remotes and Remotes:FindFirstChild("Crouch")
    if Crouch and Crouch:IsA("RemoteEvent") then pcall(function() Crouch:FireServer(true) end) end
end

function CR4.ResetFigureProtection()
    FigureRemoteAccumulator = 0
    task.spawn(function()
        local Remotes = ReplicatedStorage:FindFirstChild("RemotesFolder")
        local Crouch = Remotes and Remotes:FindFirstChild("Crouch")
        if not Crouch or not Crouch:IsA("RemoteEvent") then return end
        for _ = 1, 5 do
            pcall(function() Crouch:FireServer(false) end)
            task.wait(0.05)
        end
    end)
end

function CR4.UpdateEyesProtection(DeltaTime)
    if not State.AntiEyes then EyesAccumulator = 0; return end
    if not workspace:FindFirstChild("Eyes") then return end

    EyesAccumulator += DeltaTime
    if EyesAccumulator < 0.08 then return end
    EyesAccumulator = 0

    local Remotes = ReplicatedStorage:FindFirstChild("RemotesFolder")
    local Motor = Remotes and Remotes:FindFirstChild("MotorReplication")
    if Motor and Motor:IsA("RemoteEvent") then pcall(function() Motor:FireServer(-760) end) end
end

function CR4.GetRoom50Paper()
    local Character = LocalPlayer.Character
    local Backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local Room50 = CurrentRooms:FindFirstChild("50")
    return (Character and Character:FindFirstChild("LibraryHintPaper"))
        or (Backpack and Backpack:FindFirstChild("LibraryHintPaper"))
        or (Room50 and Room50:FindFirstChild("LibraryHintPaper", true))
end

function CR4.DecodeRoom50Code()
    local PG = LocalPlayer:FindFirstChild("PlayerGui")
    local PermUI = PG and PG:FindFirstChild("PermUI")
    local Hints = PermUI and PermUI:FindFirstChild("Hints")
    local Paper = CR4.GetRoom50Paper()
    local PaperUI = Paper and Paper:FindFirstChild("UI", true)

    if not Hints or not PaperUI then return nil, false, "Need collected hints and LibraryHintPaper" end

    local Values = {}
    for _, Item in ipairs(Hints:GetChildren()) do
        if Item:IsA("ImageLabel") and Item.Visible then
            local Shape = Room50ShapeByOffset[math.round(Item.ImageRectOffset.X)]
            local TextLabel = Item:FindFirstChild("TextLabel", true)
            local Number = TextLabel and tonumber(TextLabel.Text)
            if Shape and Number then Values[Shape] = Number end
        end
    end

    local Code = ""
    local Complete = true
    for Index = 1, 5 do
        local Slot = PaperUI:FindFirstChild(tostring(Index))
        if Slot and Slot:IsA("ImageLabel") then
            local Shape = Room50ShapeByOffset[math.round(Slot.ImageRectOffset.X)]
            local Number = Shape and Values[Shape]
            if Number ~= nil then Code ..= tostring(Number) else Code ..= "_"; Complete = false end
        else
            Code ..= "?"
            Complete = false
        end
    end

    return Code, Complete
end

function CR4.ShowRoom50Code(Force)
    local Code, Complete, ErrorText = CR4.DecodeRoom50Code()
    if not Code then
        if Force then CR4.Notify("Room 50: " .. tostring(ErrorText or "code unavailable")) end
        return nil, false
    end
    if Force or Code ~= Room50LastCode then
        Room50LastCode = Code
        CR4.Notify("Room 50 code: " .. Code, 5)
    end
    return Code, Complete
end

function CR4.OpenRoom50Door()
    local Code, Complete = CR4.ShowRoom50Code(true)
    if not Code or not Complete then CR4.Notify("Room 50 code is incomplete"); return end
    local Remotes = ReplicatedStorage:FindFirstChild("RemotesFolder")
    local PL = Remotes and Remotes:FindFirstChild("PL")
    if PL and PL:IsA("RemoteEvent") then
        pcall(function() PL:FireServer(Code) end)
        CR4.Notify("Room 50 code sent: " .. Code)
    else
        CR4.Notify("PL remote was not found")
    end
end

function CR4.RevivePlayer()
    local Remotes = ReplicatedStorage:FindFirstChild("RemotesFolder")
    local Revive = Remotes and Remotes:FindFirstChild("Revive")
    if Revive and Revive:IsA("RemoteEvent") then pcall(function() Revive:FireServer() end)
    else CR4.Notify("Revive remote was not found") end
end

--==================================================
-- ANTI SCREECH
--==================================================

AntiScreechBindName = "LinoriaAntiScreechTurn"

function CR4.IsScreechObject(Object)
    return Object and (Object.Name == "Screech" or Object.Name == "ScreechRetro" or Object.Name == "ScreechRushMode")
end

function CR4.GetScreechTarget(Object)
    local Current = Object
    while Current and Current ~= workspace do
        if CR4.IsScreechObject(Current) then return Current end
        Current = Current.Parent
    end
    return CR4.IsScreechObject(Object) and Object or nil
end

function CR4.GetScreechWorldPosition(Screech)
    if not Screech or not Screech.Parent then return nil end
    for _, Name in ipairs({ "Core", "Hitbox", "Root", "Head" }) do
        local Part = Screech:FindFirstChild(Name, true)
        if Part and Part:IsA("BasePart") then return Part.Position end
    end
    return CR4.GetWorldPosition(Screech)
end

function CR4.FaceScreechAndRestore(Screech)
    if A90Active or not State.AntiScreech or AntiScreechBusy or not Screech or not Screech.Parent then return end
    Camera = workspace.CurrentCamera or Camera
    local _,Humanoid,Root=CR4.GetCharacter()
    local InitialTarget=CR4.GetScreechWorldPosition(Screech)
    if not Camera or not Humanoid or Humanoid.Health<=0 or not Root or not InitialTarget then return end

    AntiScreechBusy=true
    local SavedLook=Camera.CFrame.LookVector
    local T=math.max(0.01,State.AntiScreechTurnTime)
    local Hold=0.03
    local Started=os.clock()
    pcall(function() RunService:UnbindFromRenderStep(AntiScreechBindName) end)
    RunService:BindToRenderStep(AntiScreechBindName,Enum.RenderPriority.Camera.Value+2000,function()
        if A90Active then
            pcall(function() RunService:UnbindFromRenderStep(AntiScreechBindName) end)
            AntiScreechBusy=false
            return
        end
        Camera=workspace.CurrentCamera or Camera
        if not Camera then return end
        local Elapsed=os.clock()-Started
        local CamPos=Camera.CFrame.Position
        local TargetPos=(Screech and Screech.Parent and CR4.GetScreechWorldPosition(Screech)) or InitialTarget
        local Toward=CFrame.lookAt(CamPos,TargetPos)
        local Back=CFrame.lookAt(CamPos,CamPos+SavedLook)
        if Elapsed<T then
            local A=math.clamp(Elapsed/T,0,1)
            Camera.CFrame=CFrame.lookAt(CamPos,CamPos+SavedLook):Lerp(Toward,A)
        elseif Elapsed<T+Hold then
            Camera.CFrame=Toward
        elseif Elapsed<T+Hold+T then
            local A=math.clamp((Elapsed-T-Hold)/T,0,1)
            Camera.CFrame=Toward:Lerp(Back,A)
        else
            Camera.CFrame=Back
            pcall(function() RunService:UnbindFromRenderStep(AntiScreechBindName) end)
            AntiScreechBusy=false
        end
    end)
end

--==================================================
-- A90 / RUNTIME STATE PROTECTION
--==================================================

A90Face = nil
A90StopIcon = nil
A90Saved = nil
A90LastLookup = 0

function CR4.GetRuntimeStateTable()
    if CR4.MainGameState and type(CR4.MainGameState) == "table" then return CR4.MainGameState end

    local Ok, Result = pcall(function()
        local PG = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)
        local MainUI = PG and (PG:FindFirstChild("MainUI") or PG:WaitForChild("MainUI", 10))
        local Initiator = MainUI and (MainUI:FindFirstChild("Initiator") or MainUI:WaitForChild("Initiator", 10))
        local MainGameModule = Initiator and (Initiator:FindFirstChild("Main_Game") or Initiator:WaitForChild("Main_Game", 10))
        if MainGameModule and MainGameModule:IsA("ModuleScript") then return require(MainGameModule) end
    end)

    if Ok and type(Result) == "table" then CR4.MainGameState = Result; return Result end

    local G = getgenv and getgenv() or nil
    if G then
        if type(G.t) == "table" then return G.t end
        if type(G.env) == "table" and type(G.env.t) == "table" then return G.env.t end
    end
    return nil
end

function CR4.RefreshA90GuiRefs()
    local PG = LocalPlayer:FindFirstChild("PlayerGui")
    local MainUI = PG and PG:FindFirstChild("MainUI")
    local Jumpscare = MainUI and MainUI:FindFirstChild("Jumpscare")
    local A90 = Jumpscare and Jumpscare:FindFirstChild("Jumpscare_A90")
    A90Face = A90 and A90:FindFirstChild("Face") or nil
    A90StopIcon = A90 and A90:FindFirstChild("StopIcon") or nil
end

function CR4.IsA90Visible()
    if os.clock() - A90LastLookup > 0.05 or not A90Face or not A90Face.Parent then
        A90LastLookup = os.clock()
        CR4.RefreshA90GuiRefs()
    end

    local FaceVisible = A90Face and pcall(function() return A90Face.Visible end) and A90Face.Visible
    local StopVisible = A90StopIcon and pcall(function() return A90StopIcon.Visible end) and A90StopIcon.Visible
    return FaceVisible or StopVisible
end

function CR4.BeginA90Lock()
    if A90Active then return end
    Camera = workspace.CurrentCamera or Camera
    local _, Humanoid, Root = CR4.GetCharacter()
    local RuntimeT = CR4.GetRuntimeStateTable()
    A90Saved = {
        CameraCFrame = Camera and Camera.CFrame or nil,
        CameraType = Camera and Camera.CameraType or nil,
        WalkSpeed = Humanoid and Humanoid.WalkSpeed or nil,
        JumpPower = Humanoid and Humanoid.JumpPower or nil,
        JumpHeight = Humanoid and Humanoid.JumpHeight or nil,
        DisableMovement = RuntimeT and RuntimeT.disableMovement or nil,
        Sprinting = RuntimeT and RuntimeT.sprinting or nil,
    }
    if PlayerControls then pcall(function() PlayerControls:Disable() end) end
    if RuntimeT then RuntimeT.disableMovement = true; RuntimeT.sprinting = false end
    if Humanoid then Humanoid.WalkSpeed = 0; Humanoid.JumpPower = 0; Humanoid.JumpHeight = 0 end
    if Root then Root.AssemblyLinearVelocity = Vector3.zero; Root.AssemblyAngularVelocity = Vector3.zero end
    if Camera then Camera.CameraType = Enum.CameraType.Scriptable end
    A90Active = true
end

function CR4.EndA90Lock()
    if not A90Active then return end
    Camera = workspace.CurrentCamera or Camera
    local _, Humanoid = CR4.GetCharacter()
    local RuntimeT = CR4.GetRuntimeStateTable()
    if RuntimeT and A90Saved then
        if A90Saved.DisableMovement ~= nil then RuntimeT.disableMovement = A90Saved.DisableMovement else RuntimeT.disableMovement = false end
        if A90Saved.Sprinting ~= nil then RuntimeT.sprinting = A90Saved.Sprinting end
    end
    if PlayerControls then pcall(function() PlayerControls:Enable() end) end
    if Humanoid and A90Saved then
        if A90Saved.WalkSpeed ~= nil then Humanoid.WalkSpeed = A90Saved.WalkSpeed end
        if A90Saved.JumpPower ~= nil then Humanoid.JumpPower = A90Saved.JumpPower end
        if A90Saved.JumpHeight ~= nil then Humanoid.JumpHeight = A90Saved.JumpHeight end
    end
    if Camera and A90Saved then
        if A90Saved.CameraType then Camera.CameraType = A90Saved.CameraType end
        if A90Saved.CameraCFrame then Camera.CFrame = A90Saved.CameraCFrame end
    end
    A90Active = false
    A90Saved = nil
    if State.JumpEnabled or State.BunnyHop then CR4.ApplyJumpSettings() end
    if State.WalkSpeedEnabled or State.BunnyHop then CR4.ApplyWalkSpeed() end
    if State.ThirdPerson then CR4.ApplyThirdPerson() end
end

function CR4.UpdateA90Protection()
    if not State.AntiA90 then
        if A90Active then CR4.EndA90Lock() end
        return false
    end
    if CR4.IsA90Visible() then
        CR4.BeginA90Lock()
        Camera = workspace.CurrentCamera or Camera
        local _, Humanoid, Root = CR4.GetCharacter()
        local RuntimeT = CR4.GetRuntimeStateTable()
        if RuntimeT then RuntimeT.disableMovement = true; RuntimeT.sprinting = false end
        if Humanoid then Humanoid.WalkSpeed = 0; Humanoid.JumpPower = 0; Humanoid.JumpHeight = 0 end
        if Root then Root.AssemblyLinearVelocity = Vector3.zero; Root.AssemblyAngularVelocity = Vector3.zero end
        if Camera and A90Saved and A90Saved.CameraCFrame then Camera.CameraType = Enum.CameraType.Scriptable; Camera.CFrame = A90Saved.CameraCFrame end
        return true
    end
    if A90Active then CR4.EndA90Lock() end
    return false
end

function CR4.UpdateRuntimeProtectionStates()
    local T = CR4.GetRuntimeStateTable()
    if not T then return end
    if State.AntiStun then T.stunned = false end
    if State.AntiFigure then T.crouching = false end
    if State.AntiRush or State.AntiAmbush or State.AntiA60 or State.AntiA120 or State.AntiBackdoorRush or State.AntiGlitchAmbush then
        T.hiding = false
    end
end

AntiTeleportLastSafeCFrame = nil
ThreatEvadeActive = false
ThreatEvadeLockCFrame = nil
ThreatReturnCFrame = nil
ThreatEvadeName = nil

ThreatProtectionMap = {
    RushMoving = "AntiRush",
    AmbushMoving = "AntiAmbush",
    A60 = "AntiA60",
    A120 = "AntiA120",
    BackdoorRush = "AntiBackdoorRush",
    GlitchAmbush = "AntiGlitchAmbush",
}

EntityTPThreatNames = { "RushMoving", "AmbushMoving", "A60", "A120", "BackdoorRush", "GlitchAmbush" }

function CR4.AnyThreatProtectionEnabled()
    for _, StateKey in pairs(ThreatProtectionMap) do if State[StateKey] then return true end end
    return false
end

function CR4.GetActiveThreat()
    for Name, StateKey in pairs(ThreatProtectionMap) do
        if State[StateKey] then
            local Object = workspace:FindFirstChild(Name)
            if Object then return Object, Name, StateKey end
        end
    end
    return nil, nil, nil
end

function CR4.GetActiveEntityTPThreat()
    if not State.AntiEntityTP then return nil, nil end
    for _, Name in ipairs(EntityTPThreatNames) do
        local Object = workspace:FindFirstChild(Name)
        if Object then return Object, Name end
    end
    return nil, nil
end

function CR4.ResetThreatEvade()
    if not ThreatEvadeActive then return end
    local _, _, Root = CR4.GetCharacter()
    if Root and ThreatReturnCFrame then
        Root.CFrame = ThreatReturnCFrame
        AntiTeleportLastSafeCFrame = ThreatReturnCFrame
    end
    ThreatEvadeActive = false
    ThreatEvadeLockCFrame = nil
    ThreatReturnCFrame = nil
    ThreatEvadeName = nil
end

function CR4.UpdatePositionProtection()
    if A90Active then return end
    local _, Humanoid, Root = CR4.GetCharacter()
    if not Humanoid or Humanoid.Health <= 0 or not Root then return end

    local Threat, ThreatName = CR4.GetActiveEntityTPThreat()
    if State.AntiEntityTP and Threat then
        if not ThreatEvadeActive then
            ThreatEvadeActive = true
            ThreatEvadeName = ThreatName
            ThreatReturnCFrame = Root.CFrame
            ThreatEvadeLockCFrame = Root.CFrame + Vector3.new(0, math.max(100, State.ThreatEvadeHeight), 0)
        elseif ThreatEvadeName ~= ThreatName then
            ThreatEvadeName = ThreatName
        end

        Root.CFrame = ThreatEvadeLockCFrame
        Root.AssemblyLinearVelocity = Vector3.zero
        Root.AssemblyAngularVelocity = Vector3.zero
        return
    elseif ThreatEvadeActive then
        CR4.ResetThreatEvade()
    end

    if State.AntiTeleport then
        if not AntiTeleportLastSafeCFrame then
            AntiTeleportLastSafeCFrame = Root.CFrame
        else
            local Delta = (Root.Position - AntiTeleportLastSafeCFrame.Position).Magnitude
            if Delta > math.max(5, State.AntiTeleportThreshold) then
                Root.CFrame = AntiTeleportLastSafeCFrame
                Root.AssemblyLinearVelocity = Vector3.zero
                Root.AssemblyAngularVelocity = Vector3.zero
            else
                AntiTeleportLastSafeCFrame = Root.CFrame
            end
        end
    else
        AntiTeleportLastSafeCFrame = nil
    end
end

function CR4.SetAntiTeleportPosition()
    local _,_,Root = CR4.GetCharacter()
    if Root then AntiTeleportLastSafeCFrame = Root.CFrame end
end
