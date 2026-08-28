-- Experiment 17 | Rivals | ESP.lua
-- Physical logical module. Loaded in the shared Loader.lua environment.

--==================================================
-- ESP
--==================================================

ESPCategories = {
    Doors = { Label = "Doors", Color = Color3.fromRGB(85, 170, 255), Enabled = false, Boxes = false, Tracers = false },
    Chapter = { Label = "Chapter", Color = Color3.fromRGB(80, 220, 255), Enabled = false, Boxes = false, Tracers = false },
    Gold = { Label = "Gold", Color = Color3.fromRGB(255, 210, 45), Enabled = false, Boxes = false, Tracers = false },
    Keys = { Label = "Keys", Color = Color3.fromRGB(255, 245, 125), Enabled = false, Boxes = false, Tracers = false },
    Lockpicks = { Label = "Lockpicks", Color = Color3.fromRGB(220, 190, 100), Enabled = false, Boxes = false, Tracers = false },
    Wardrobes = { Label = "Wardrobes", Color = Color3.fromRGB(125, 210, 255), Enabled = false, Boxes = false, Tracers = false },
    Chests = { Label = "Chests", Color = Color3.fromRGB(200, 125, 70), Enabled = false, Boxes = false, Tracers = false },
    Lootables = { Label = "Lootables", Color = Color3.fromRGB(165, 115, 70), Enabled = false, Boxes = false, Tracers = false },
    Lights = { Label = "Lights", Color = Color3.fromRGB(255, 235, 130), Enabled = false, Boxes = false, Tracers = false },
    Crucifix = { Label = "Crucifix", Color = Color3.fromRGB(120, 190, 255), Enabled = false, Boxes = false, Tracers = false },
    Items = { Label = "Items", Color = Color3.fromRGB(100, 255, 145), Enabled = false, Boxes = false, Tracers = false },
    Objectives = { Label = "Objectives", Color = Color3.fromRGB(180, 95, 255), Enabled = false, Boxes = false, Tracers = false },
    Books = { Label = "Books / Hints", Color = Color3.fromRGB(255, 135, 210), Enabled = false, Boxes = false, Tracers = false },
    Breakers = { Label = "Breakers", Color = Color3.fromRGB(255, 145, 45), Enabled = false, Boxes = false, Tracers = false },
    Rift = { Label = "Rift", Color = Color3.fromRGB(130, 80, 255), Enabled = false, Boxes = false, Tracers = false },
    Levers = { Label = "Levers", Color = Color3.fromRGB(255, 120, 35), Enabled = false, Boxes = false, Tracers = false },
    Mines = { Label = "Mines", Color = Color3.fromRGB(85, 255, 190), Enabled = false, Boxes = false, Tracers = false },
    Backdoors = { Label = "Backdoors", Color = Color3.fromRGB(255, 75, 185), Enabled = false, Boxes = false, Tracers = false },
    Fuses = { Label = "Fuses", Color = Color3.fromRGB(255, 235, 80), Enabled = false, Boxes = false, Tracers = false },
    DangerDoor = { Label = "Danger Door", Color = Color3.fromRGB(255, 45, 45), Enabled = true, Boxes = false, Tracers = false },

    Rush = { Label = "Rush", Color = Color3.fromRGB(255, 70, 70), Enabled = false, Boxes = false, Tracers = false },
    Ambush = { Label = "Ambush", Color = Color3.fromRGB(80, 255, 105), Enabled = false, Boxes = false, Tracers = false },
    Seek = { Label = "Seek", Color = Color3.fromRGB(25, 25, 25), Enabled = false, Boxes = false, Tracers = false },
    Figure = { Label = "Figure", Color = Color3.fromRGB(255, 120, 35), Enabled = false, Boxes = false, Tracers = false },
    Dupe = { Label = "Dupe", Color = Color3.fromRGB(210, 55, 255), Enabled = false, Boxes = false, Tracers = false },
    Screech = { Label = "Screech", Color = Color3.fromRGB(210, 210, 255), Enabled = false, Boxes = false, Tracers = false },
    Dread = { Label = "Dread", Color = Color3.fromRGB(115, 50, 155), Enabled = false, Boxes = false, Tracers = false },
    Snare = { Label = "Snare", Color = Color3.fromRGB(130, 190, 65), Enabled = false, Boxes = false, Tracers = false },
    OtherMonsters = { Label = "Other Monsters", Color = Color3.fromRGB(255, 55, 155), Enabled = false, Boxes = false, Tracers = false },
    A60 = { Label = "A-60", Color = Color3.fromRGB(255, 35, 35), Enabled = false, Boxes = false, Tracers = false },
    A120 = { Label = "A-120", Color = Color3.fromRGB(235, 235, 235), Enabled = false, Boxes = false, Tracers = false },
    BackdoorRush = { Label = "Backdoor Rush", Color = Color3.fromRGB(255, 80, 160), Enabled = false, Boxes = false, Tracers = false },
    Lookman = { Label = "Lookman", Color = Color3.fromRGB(120, 90, 255), Enabled = false, Boxes = false, Tracers = false },
    GlitchAmbush = { Label = "Glitch Ambush", Color = Color3.fromRGB(55, 255, 220), Enabled = false, Boxes = false, Tracers = false },
}

ObjectCategoryOrder = {
    "Doors", "Chapter", "Gold", "Keys", "Lockpicks", "Wardrobes", "Chests", "Lootables",
    "Lights", "Crucifix", "Items", "Objectives", "Books", "Breakers", "Rift",
    "Levers", "Mines", "Backdoors", "Fuses", "DangerDoor",
}

MonsterCategoryOrder = {
    "Rush", "Ambush", "Seek", "Figure", "Dupe", "Screech", "Dread", "Snare", "OtherMonsters",
    "A60", "A120", "BackdoorRush", "Lookman", "GlitchAmbush",
}

MonsterCategorySet = {}
for _, Key in ipairs(MonsterCategoryOrder) do MonsterCategorySet[Key] = true end

RefreshXRay = nil
RestoreXRayForTarget = nil

ESPOverlay = Instance.new("Frame")
ESPOverlay.Name = "LinoriaESPOverlay"
ESPOverlay.BackgroundTransparency = 1
ESPOverlay.BorderSizePixel = 0
ESPOverlay.Position = UDim2.fromScale(0, 0)
ESPOverlay.Size = UDim2.fromScale(1, 1)
ESPOverlay.Active = false
ESPOverlay.ZIndex = 900
ESPOverlay.Parent = Library.ScreenGui

HighlightFolder = Instance.new("Folder")
HighlightFolder.Name = "LinoriaCurrentRoomsHighlights"
HighlightFolder.Parent = workspace

ESPEntries = setmetatable({}, { __mode = "k" })
ProtectedESPParts = setmetatable({}, { __mode = "k" })
DoorTargets = setmetatable({}, { __mode = "k" })
MonsterProxyEntries = setmetatable({}, { __mode = "k" })

function CR4.GetHighlightAdornee(Target, Category)
    if not Target or not Target.Parent then return nil end
    if Target:IsA("BasePart") then
        if Target.Transparency >= 0.98 and Category ~= "Doors" and Category ~= "DangerDoor" and Category ~= "Chapter" then
            local ParentModel = Target:FindFirstAncestorOfClass("Model")
            if ParentModel then
                for _, Part in ipairs(ParentModel:GetDescendants()) do
                    if Part:IsA("BasePart") and Part.Transparency < 0.98 then return ParentModel end
                end
            end
        end
        return Target
    end
    if Target:IsA("Model") then
        local AnyPart = nil
        local HasVisible = false
        for _, Object in ipairs(Target:GetDescendants()) do
            if Object:IsA("BasePart") then
                AnyPart = AnyPart or Object
                if Object.Transparency < 0.98 and Object.Size.Magnitude > 0.05 then HasVisible = true; break end
            end
        end
        if HasVisible then return Target end
        return AnyPart
    end
    return Target:FindFirstChildWhichIsA("BasePart", true)
end

function CR4.IsDoorVisualPart(Part)
    if not Part or not Part:IsA("BasePart") or Part.Transparency >= 0.95 or Part.Size.Magnitude < 0.05 then return false end
    local N = string.lower(Part.Name)
    if string.find(N, "hidden", 1, true) or string.find(N, "hitbox", 1, true) or string.find(N, "collision", 1, true)
        or string.find(N, "trigger", 1, true) or string.find(N, "occlusion", 1, true) or string.find(N, "blocker", 1, true) then return false end
    return true
end

function CR4.ConfigureDoorHighlights(Entry, Config)
    Entry.PartHighlights = Entry.PartHighlights or setmetatable({}, { __mode = "k" })
    local Seen = setmetatable({}, { __mode = "k" })
    local function AddPart(Part)
        if not CR4.IsDoorVisualPart(Part) then return end
        Seen[Part] = true
        local H = Entry.PartHighlights[Part]
        if not H or not H.Parent then
            H = Instance.new("Highlight")
            H.Name = "LinoriaDoorPartHighlight"
            H.Adornee = Part
            H.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            H.Parent = HighlightFolder
            Entry.PartHighlights[Part] = H
        end
        H.FillColor = Config.Color; H.OutlineColor = Config.Color; H.FillTransparency = State.ESPFillTransparency; H.OutlineTransparency = 0; H.Enabled = Config.Enabled
    end
    if Entry.Target:IsA("BasePart") then AddPart(Entry.Target)
    else
        local Count = 0
        for _, Part in ipairs(Entry.Target:GetDescendants()) do
            if Part:IsA("BasePart") then
                AddPart(Part); Count += 1
                if Count >= 24 then break end
            end
        end
    end
    for Part, H in pairs(Entry.PartHighlights) do
        if not Part or not Part.Parent or not Seen[Part] then CR4.SafeDestroy(H); Entry.PartHighlights[Part] = nil end
    end
    Entry.Highlight.Enabled = false
end

function CR4.CreateMonsterProxy(Target, Category)
    if Category ~= "Rush" and Category ~= "Ambush" then return nil end
    local Model = Instance.new("Model")
    Model.Name = "Experiment17_" .. Category .. "HeadProxy"

    local Head = nil
    local Character = LocalPlayer.Character
    local SourceHead = Character and Character:FindFirstChild("Head")
    if SourceHead and SourceHead:IsA("BasePart") then
        local Ok, Clone = pcall(function() return SourceHead:Clone() end)
        if Ok and Clone and Clone:IsA("BasePart") then
            Head = Clone
            for _, Child in ipairs(Head:GetChildren()) do
                if not Child:IsA("SpecialMesh") then CR4.SafeDestroy(Child) end
            end

        end
    end
    if not Head then
        Head = Instance.new("Part")
        Head.Size = Vector3.new(2, 1, 1)
    end

    Head.Name = "Head"
    Head.Anchored = true
    Head.CanCollide = false
    Head.CanTouch = false
    Head.CanQuery = false
    Head.CastShadow = false
    Head.Material = Enum.Material.SmoothPlastic
    Head.Transparency = 0.82
    Head.Parent = Model
    Model.PrimaryPart = Head
    Model.Parent = HighlightFolder
    MonsterProxyEntries[Target] = Model
    return Model
end

function CR4.UpdateMonsterProxy(Entry)
    if not Entry or not Entry.Proxy or not Entry.Proxy.Parent then return end
    local Head = Entry.Proxy:FindFirstChild("Head")
    if not Head then return end
    local CF, Size = CR4.GetTargetBoundingBox(Entry.Target)
    local Pos = CF and CF.Position or CR4.GetWorldPosition(Entry.Target)
    if Pos then Head.CFrame = CFrame.new(Pos + Vector3.new(0, math.max(0.5, (Size and Size.Y or 2) * 0.15), 0)) end
    local Config = ESPCategories[Entry.Category]
    if Config then Head.Color = Config.Color; Head.Transparency = Config.Enabled and 0.82 or 1 end
end

ObjectDisplayNames = {
    GoldPile = "Gold", KeyObtain = "Key", ElectricalKeyObtain = "Electrical Key", Lockpick = "Lockpick",
    SkeletonKey = "Skeleton Key", Wardrobe = "Wardrobe", Toolshed = "Toolshed", Bed = "Bed",
    ChestBox = "Chest", ChestBoxLocked = "Locked Chest", Toolshed_Small = "Toolshed Loot",
    Vitamins = "Vitamins", Battery = "Battery", Bandage = "Bandage", Candle = "Candle",
    Flashlight = "Flashlight", Lighter = "Lighter", YellowLight = "Yellow Light", Glowstick = "Glowstick",
    Crucifix = "Crucifix", CrucifixOnTheWall = "Crucifix", AlarmClock = "Alarm Clock", Smoothie = "Smoothie",
    Green_Herb = "Green Herb", LeverForGate = "Lever", ThingToOpen = "Gate", CuttableVines = "Vines",
    LiveHintBook = "Library Book", LibraryHintPaper = "Hint Paper", LiveBreakerPolePickup = "Breaker Pole",
    ElevatorBreakerEmpty = "Breaker", RiftSpawn = "Rift", GlitchFragment = "Glitch Fragment",
    ["Glitch Fragment"] = "Glitch Fragment", FuseObtain = "Fuse", GeneratorMain = "Generator",
    Locker_Large = "Large Locker", Locker_Small = "Small Locker", Locker_Small_Locked = "Locked Locker",
    MinecartMoving = "Minecart", TrackLever = "Track Lever", CircularVent = "Vent", Ladder = "Ladder",
    Toolbox = "Toolbox", Shakelight = "Shakelight", TimerLever = "Timer Lever", StarVial = "Star Vial",
    StarBottle = "Star Bottle", Backdoors_Exit = "Backdoors Exit", Shears = "Shears", GlitchCube = "Glitch Cube",
    MinesGateButton = "Gate Button", Rooms_Locker = "Locker", Rooms_BrokenLocker = "Broken Locker",
    Rooms_Locker_Fridge = "Fridge Locker", Backdoor_Wardrobe = "Backdoor Wardrobe", Toolbox_Locked = "Locked Toolbox",
    Details = "Generator Details", Bulklight = "Bulklight", BandagePack = "Bandage Pack", Straplight = "Straplight",
}

function CR4.SpatialRoot(Root)
    if not Root then return nil end
    if Root:IsA("Model") or Root:IsA("BasePart") then return Root end
    local Model = Root:FindFirstChildWhichIsA("Model")
    if Model then return Model end
    return Root:FindFirstChildWhichIsA("BasePart", true)
end

function CR4.FindNamedAncestor(Object, Names, StopAt)
    local Current = Object
    while Current and Current ~= StopAt do
        if Names[Current.Name] then return Current end
        Current = Current.Parent
    end
    return nil
end

function CR4.FindCrucifixRoot(Object)
    local Current = Object
    while Current and Current ~= workspace do
        if Current.Name == "Crucifix" or Current.Name == "CrucifixOnTheWall" then
            local Handle = Current:FindFirstChild("Handle", true)
            if Handle and Handle:IsA("BasePart") then return CR4.SpatialRoot(Current), Handle end
            return nil, nil
        end
        Current = Current.Parent
    end
    return nil, nil
end

function CR4.GetDoorTarget(Object)
    if CR4.HasAncestorNamed(Object, "SideroomDupe", workspace) then return nil end
    local Current = Object
    while Current and Current ~= CurrentRooms do
        if Current.Name == "Door" then
            local Inner = Current:FindFirstChild("Door")
            if Inner and Inner ~= Current then return CR4.SpatialRoot(Inner) end
            if Current.Parent and (Current.Parent.Name == "Door" or Current.Parent.Name == "DoorNormal"
                or Current.Parent.Name == "_RoomsDoorEntrance" or Current.Parent.Name == "Wax_Door" or Current.Parent.Name == "ElectricalDoor") then
                return CR4.SpatialRoot(Current)
            end
            if Current.Parent and tonumber(Current.Parent.Name) then return CR4.SpatialRoot(Current) end
        end
        if Current.Name == "DoorNormal" or Current.Name == "_RoomsDoorEntrance" or Current.Name == "Wax_Door" or Current.Name == "ElectricalDoor" then
            local Visible = Current:FindFirstChild("Door")
            if Visible then return CR4.SpatialRoot(Visible) end
        end
        Current = Current.Parent
    end
    return nil
end

function CR4.ResolveObjectESP(Object)
    if not Object or not Object.Parent then return nil, nil end

    local Drops = workspace:FindFirstChild("Drops")
    local InRooms = Object:IsDescendantOf(CurrentRooms)
    local InDrops = Drops and Object:IsDescendantOf(Drops)
    local StandaloneNames = {
        Lighter=true, YellowLight=true, Glowstick=true, Glowsticks=true, Crucifix=true,
        Bulklight=true, BandagePack=true, Straplight=true,
        GlitchFragment=true, ["Glitch Fragment"]=true, RiftCandle=true, StarVial=true, Shears=true,
    }
    local StandaloneRoot = CR4.FindNamedAncestor(Object, StandaloneNames, workspace)
    if not InRooms and not InDrops and not StandaloneRoot then return nil, nil end

    local CrucifixRoot = CR4.FindCrucifixRoot(Object)
    if CrucifixRoot then return CrucifixRoot, "Crucifix" end

    local GoldRoot = select(2, CR4.HasAncestorNamed(Object, "GoldPile", CurrentRooms))
    if GoldRoot then return CR4.SpatialRoot(GoldRoot), "Gold" end

    local LockpickRoot = select(2, CR4.HasAncestorNamed(Object, "Lockpick", CurrentRooms))
    if LockpickRoot then return CR4.SpatialRoot(LockpickRoot), "Lockpicks" end

    local KeyRoot = CR4.FindNamedAncestor(Object, { KeyObtain=true, SkeletonKey=true, ElectricalKeyObtain=true }, CurrentRooms)
    if KeyRoot then return CR4.SpatialRoot(KeyRoot), "Keys" end

    local FuseRoot = CR4.FindNamedAncestor(Object, { FuseObtain=true }, CurrentRooms)
    if FuseRoot then return CR4.SpatialRoot(FuseRoot), "Fuses" end

    local BackdoorRoot = CR4.FindNamedAncestor(Object, {
        Backdoors_Exit=true, Backdoor_Wardrobe=true, StarBottle=true,
    }, CurrentRooms) or CR4.FindNamedAncestor(Object, { StarVial=true }, workspace)
    if BackdoorRoot then return CR4.SpatialRoot(BackdoorRoot), "Backdoors" end

    local MineRoot = CR4.FindNamedAncestor(Object, {
        GeneratorMain=true, Details=true, MinecartMoving=true, CircularVent=true, Ladder=true, Toolbox=true, Toolbox_Locked=true,
        Shakelight=true, Glowsticks=true, Rooms_Locker=true, Rooms_BrokenLocker=true, Rooms_Locker_Fridge=true,
        Locker_Large=true, Locker_Small=true, Locker_Small_Locked=true, Mines_SideroomLadder1=true,
        Mines_SideroomLockers1=true, MinecartSet=true,
    }, CurrentRooms)
    if MineRoot then return CR4.SpatialRoot(MineRoot), "Mines" end

    local LeverRoot = CR4.FindNamedAncestor(Object, {
        LeverForGate=true, TrackLever=true, MinesGateButton=true, TimerLever=true, ThingToOpen=true,
    }, CurrentRooms)
    if LeverRoot then return CR4.SpatialRoot(LeverRoot), "Levers" end

    local ChapterRoot = CR4.FindNamedAncestor(Object, {
        _RoomsGate=true, _RoomsDoorEntrance=true, Cellar=true, CuttableVines=true, Backdoors_Exit=true,
    }, CurrentRooms)
    if ChapterRoot then return CR4.SpatialRoot(ChapterRoot), "Chapter" end

    local WardrobeRoot = CR4.FindNamedAncestor(Object, {
        Wardrobe=true, Bed=true, Toolshed=true, Locker_Large=true, Locker_Small=true,
        Locker_Small_Locked=true, Rooms_Locker=true, Rooms_BrokenLocker=true, Rooms_Locker_Fridge=true, Backdoor_Wardrobe=true,
    }, CurrentRooms)
    if WardrobeRoot then return CR4.SpatialRoot(WardrobeRoot), "Wardrobes" end

    local ChestRoot = CR4.FindNamedAncestor(Object, { ChestBox=true, ChestBoxLocked=true }, CurrentRooms)
    if ChestRoot then return CR4.SpatialRoot(ChestRoot), "Chests" end

    local LootRoot = CR4.FindNamedAncestor(Object, { Toolshed_Small=true, DrawerContainer=true, Toolbox=true, RoomsLootItem=true }, CurrentRooms)
    if LootRoot then return CR4.SpatialRoot(LootRoot), "Lootables" end

    local LightRoot = CR4.FindNamedAncestor(Object, { Candle=true, Flashlight=true, Lighter=true, YellowLight=true, Glowstick=true, Glowsticks=true, RiftCandle=true, Shakelight=true, Bulklight=true, Straplight=true }, workspace)
    if LightRoot then return CR4.SpatialRoot(LightRoot), "Lights" end

    local BookRoot = CR4.FindNamedAncestor(Object, { LiveHintBook=true, LibraryHintPaper=true }, CurrentRooms)
    if BookRoot then return CR4.SpatialRoot(BookRoot), "Books" end

    local BreakerRoot = CR4.FindNamedAncestor(Object, { LiveBreakerPolePickup=true, ElevatorBreakerEmpty=true }, CurrentRooms)
    if BreakerRoot then return CR4.SpatialRoot(BreakerRoot), "Breakers" end

    local RiftRoot = select(2, CR4.HasAncestorNamed(Object, "RiftSpawn", CurrentRooms))
    if RiftRoot then return CR4.SpatialRoot(RiftRoot), "Rift" end

    local ObjectiveRoot = CR4.FindNamedAncestor(Object, { LeverForGate=true, Gate=true, ThingToOpen=true, GeneratorMain=true, MinesGateButton=true }, CurrentRooms)
    if ObjectiveRoot then return CR4.SpatialRoot(ObjectiveRoot), "Objectives" end

    local ItemRoot = CR4.FindNamedAncestor(Object, {
        Vitamins=true, Battery=true, Bandage=true, AlarmClock=true, Smoothie=true, Green_Herb=true,
        GlitchFragment=true, ["Glitch Fragment"]=true, GlitchCube=true, StarVial=true, StarBottle=true, Shears=true,
        Shakelight=true, RiftCandle=true, Glowsticks=true, Bulklight=true, BandagePack=true, Straplight=true, Toolbox_Locked=true,
    }, workspace)
    if ItemRoot then return CR4.SpatialRoot(ItemRoot), "Items" end

    local DoorTarget = CR4.GetDoorTarget(Object)
    if DoorTarget then return DoorTarget, "Doors" end
    return nil, nil
end

OtherMonsterNames = {
    Glitch = true, Spider = true, ScreechRetro = true, ScreechRushMode = true,
    DreadRushMode = true, SpiderRushMode = true, Shade = true, ShadeRushMode = true,
    SideroomSpace = true, EntityModel = true, ["NDA5OiBDT05GTElDVA=="] = true,
}

function CR4.FindOutermostNamedAncestor(Object, Name, StopAt)
    local Current, Found = Object, nil
    while Current and Current ~= StopAt do
        if Current.Name == Name then Found = Current end
        Current = Current.Parent
    end
    return Found
end

function CR4.ResolveMonsterESP(Object)
    if not Object or not Object:IsDescendantOf(workspace) then return nil, nil end

    local A60 = select(2, CR4.HasAncestorNamed(Object, "A60", workspace))
    if A60 then return CR4.SpatialRoot(A60), "A60" end
    local A120 = select(2, CR4.HasAncestorNamed(Object, "A120", workspace))
    if A120 then return CR4.SpatialRoot(A120), "A120" end
    local BDRush = select(2, CR4.HasAncestorNamed(Object, "BackdoorRush", workspace))
    if BDRush then return CR4.SpatialRoot(BDRush), "BackdoorRush" end
    local Lookman = select(2, CR4.HasAncestorNamed(Object, "BackdoorLookman", workspace))
    if Lookman then return CR4.SpatialRoot(Lookman), "Lookman" end
    local GAmbush = select(2, CR4.HasAncestorNamed(Object, "GlitchAmbush", workspace))
    if GAmbush then return CR4.SpatialRoot(GAmbush), "GlitchAmbush" end

    local Rush = select(2, CR4.HasAncestorNamed(Object, "RushMoving", workspace))
    if Rush then return CR4.SpatialRoot(Rush), "Rush" end

    local Ambush = select(2, CR4.HasAncestorNamed(Object, "AmbushMoving", workspace))
    if Ambush then return CR4.SpatialRoot(Ambush), "Ambush" end

    local Seek = select(2, CR4.HasAncestorNamed(Object, "SeekMovingNewClone", workspace))
    if Seek then
        local Figure = Seek:FindFirstChild("Figure", true)
        return CR4.SpatialRoot(Figure or Seek), "Seek"
    end

    local Figure = select(2, CR4.HasAncestorNamed(Object, "FigureRig", workspace))
    if Figure then return CR4.SpatialRoot(Figure), "Figure" end

    local Dupe = select(2, CR4.HasAncestorNamed(Object, "SideroomDupe", workspace))
    if Dupe then
        local DoorFake = Dupe:FindFirstChild("DoorFake", true)
        return CR4.SpatialRoot(DoorFake or Dupe), "Dupe"
    end

    local Snare = CR4.FindOutermostNamedAncestor(Object, "Snare", CurrentRooms)
    if Snare then return CR4.SpatialRoot(Snare), "Snare" end

    local Dread = select(2, CR4.HasAncestorNamed(Object, "Dread", workspace))
    if Dread then return CR4.SpatialRoot(Dread), "Dread" end

    local Current = Object
    while Current and Current ~= workspace do
        if Current.Name == "Screech" then return CR4.SpatialRoot(Current), "Screech" end
        if OtherMonsterNames[Current.Name] then return CR4.SpatialRoot(Current), "OtherMonsters" end
        Current = Current.Parent
    end

    return nil, nil
end

function CR4.GetTargetBoundingBox(Target)
    if not Target or not Target.Parent then return nil, nil end
    if Target:IsA("BasePart") then return Target.CFrame, Target.Size end
    if Target:IsA("Model") then
        local Success, BoxCFrame, BoxSize = pcall(function() return Target:GetBoundingBox() end)
        if Success then return BoxCFrame, BoxSize end
    end
    return nil, nil
end

function CR4.GetDisplayName(Target, Category)
    if MonsterCategorySet[Category] then return ESPCategories[Category].Label end
    local Current = Target
    while Current and Current ~= workspace do
        if ObjectDisplayNames[Current.Name] then return ObjectDisplayNames[Current.Name] end
        Current = Current.Parent
    end
    return ESPCategories[Category] and ESPCategories[Category].Label or Target.Name
end

function CR4.CreateESPEntry(Target, Category)
    local Box = Instance.new("Frame")
    Box.Name = "ESPBox"; Box.BackgroundTransparency = 1; Box.BorderSizePixel = 0; Box.Visible = false; Box.ZIndex = 902; Box.Parent = ESPOverlay
    local Stroke = Instance.new("UIStroke")
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; Stroke.LineJoinMode = Enum.LineJoinMode.Miter; Stroke.Thickness = State.ESPThickness; Stroke.Parent = Box
    local Tracer = Instance.new("Frame")
    Tracer.Name = "ESPTracer"; Tracer.AnchorPoint = Vector2.new(0.5, 0.5); Tracer.BorderSizePixel = 0; Tracer.Visible = false; Tracer.ZIndex = 901; Tracer.Parent = ESPOverlay
    local Label = Instance.new("TextLabel")
    Label.Name = "ESPLabel"; Label.AnchorPoint = Vector2.new(0.5, 1); Label.BackgroundTransparency = 1; Label.BorderSizePixel = 0; Label.Font = Enum.Font.Code
    Label.TextSize = 13; Label.TextStrokeColor3 = Color3.new(0,0,0); Label.TextStrokeTransparency = 0; Label.TextXAlignment = Enum.TextXAlignment.Center; Label.Visible = false; Label.ZIndex = 903; Label.Parent = ESPOverlay
    local Proxy = CR4.CreateMonsterProxy(Target, Category)
    local Highlight = Instance.new("Highlight")
    Highlight.Name = "LinoriaESPHighlight"; Highlight.Adornee = Proxy or CR4.GetHighlightAdornee(Target, Category); Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Highlight.OutlineTransparency = 0; Highlight.Enabled = false; Highlight.Parent = HighlightFolder
    local Entry = { Target=Target, Category=Category, Box=Box, Stroke=Stroke, Tracer=Tracer, Label=Label, Highlight=Highlight, Proxy=Proxy }
    ESPEntries[Target] = Entry
    return Entry
end

function CR4.DestroyESPEntry(Target)
    local Entry = ESPEntries[Target]
    if not Entry then return end
    CR4.SafeDestroy(Entry.Box)
    CR4.SafeDestroy(Entry.Tracer)
    CR4.SafeDestroy(Entry.Label)
    CR4.SafeDestroy(Entry.Highlight)
    if Entry.PartHighlights then for _, H in pairs(Entry.PartHighlights) do CR4.SafeDestroy(H) end end
    CR4.SafeDestroy(Entry.Proxy)
    MonsterProxyEntries[Target] = nil
    ESPEntries[Target] = nil
    DoorTargets[Target] = nil
end

function CR4.AddProtectedTarget(Target)
    if not Target or not Target.Parent then return end
    if Target:IsA("BasePart") then ProtectedESPParts[Target] = true end
    for _, Object in ipairs(Target:GetDescendants()) do
        if Object:IsA("BasePart") then ProtectedESPParts[Object] = true end
    end
end

function CR4.RebuildProtectedESPParts()
    ProtectedESPParts = setmetatable({}, { __mode = "k" })
    for Target, Entry in pairs(ESPEntries) do
        local Config = ESPCategories[Entry.Category]
        if Target and Target.Parent and Config and Config.Enabled then CR4.AddProtectedTarget(Target) end
    end
end

function CR4.ConfigureESPEntry(Entry)
    local Config = ESPCategories[Entry.Category]
    if not Config then return end
    if Entry.Category == "Doors" or Entry.Category == "DangerDoor" then
        CR4.ConfigureDoorHighlights(Entry, Config)
        return
    end
    if (Entry.Category == "Rush" or Entry.Category == "Ambush") and not Entry.Proxy then Entry.Proxy = CR4.CreateMonsterProxy(Entry.Target, Entry.Category) end
    if Entry.Proxy then
        Entry.Highlight.Adornee = Entry.Proxy
        CR4.UpdateMonsterProxy(Entry)
    else
        local Adornee = CR4.GetHighlightAdornee(Entry.Target, Entry.Category)
        if Adornee then Entry.Highlight.Adornee = Adornee end
    end
    Entry.Highlight.FillColor = Config.Color
    Entry.Highlight.OutlineColor = Config.Color
    Entry.Highlight.FillTransparency = State.ESPFillTransparency
    Entry.Highlight.OutlineTransparency = 0
    Entry.Highlight.Enabled = Config.Enabled and Entry.Highlight.Adornee ~= nil
end

function CR4.RegisterESP(Target, Category)
    if not CR4.IsSpatialTarget(Target) or not Target.Parent or not ESPCategories[Category] then return end

    if MonsterCategorySet[Category] then
        local Remove = {}
        for Existing, ExistingEntry in pairs(ESPEntries) do
            if Existing ~= Target and Existing and Existing.Parent and ExistingEntry.Category == Category then

                if Target:IsDescendantOf(Existing) then
                    table.insert(Remove, Existing)
                elseif Existing:IsDescendantOf(Target) then
                    return
                end
            end
        end
        for _, Existing in ipairs(Remove) do CR4.DestroyESPEntry(Existing) end
    end

    if Category == "Doors" then
        local Remove = {}
        for Existing, E in pairs(ESPEntries) do
            if Existing ~= Target and Existing and Existing.Parent and E.Category == "Doors" then
                if Target:IsDescendantOf(Existing) then table.insert(Remove, Existing)
                elseif Existing:IsDescendantOf(Target) then return end
            end
        end
        for _, Existing in ipairs(Remove) do CR4.DestroyESPEntry(Existing) end
    end

    local Entry = ESPEntries[Target]
    if not Entry then
        Entry = CR4.CreateESPEntry(Target, Category)
    else
        Entry.Category = Category
        Entry.Highlight.Adornee = Target
    end

    CR4.ConfigureESPEntry(Entry)
    if Category == "Doors" or Category == "Chapter" then DoorTargets[Target] = true end

    if ESPCategories[Category].Enabled then
        CR4.AddProtectedTarget(Target)
        if RestoreXRayForTarget then RestoreXRayForTarget(Target) end
    end
end

ESPCandidateNames = {
    Door = true, DoorNormal = true, _RoomsDoorEntrance = true, Wax_Door = true, ElectricalDoor = true,
    Crucifix = true, CrucifixOnTheWall = true, GoldPile = true, Lockpick = true, KeyObtain = true,
    SkeletonKey = true, ElectricalKeyObtain = true, _RoomsGate = true, Cellar = true, CuttableVines = true,
    Wardrobe = true, Bed = true, Toolshed = true, ChestBox = true, ChestBoxLocked = true,
    Toolshed_Small = true, DrawerContainer = true, Candle = true, Flashlight = true, Lighter = true,
    YellowLight = true, Glowstick = true, LiveHintBook = true, LibraryHintPaper = true,
    LiveBreakerPolePickup = true, ElevatorBreakerEmpty = true, RiftSpawn = true, LeverForGate = true,
    Gate = true, ThingToOpen = true, Vitamins = true, Battery = true, Bandage = true, AlarmClock = true,
    Smoothie = true, Green_Herb = true, GlitchFragment = true, ["Glitch Fragment"] = true,
    RushMoving = true, AmbushMoving = true, SeekMovingNewClone = true, FigureRig = true,
    SideroomDupe = true, Snare = true, Dread = true, Screech = true,
    FuseObtain=true, GeneratorMain=true, Locker_Large=true, Locker_Small=true, Locker_Small_Locked=true,
    MinecartMoving=true, TrackLever=true, CircularVent=true, Ladder=true, Toolbox=true, Shakelight=true,
    Glowsticks=true, Rooms_Locker=true, Rooms_BrokenLocker=true, Rooms_Locker_Fridge=true, Backdoor_Wardrobe=true,
    TimerLever=true, StarVial=true, StarBottle=true, Backdoors_Exit=true, Shears=true, GlitchCube=true,
    MinesGateButton=true, RiftCandle=true, Toolbox_Locked=true, Details=true, Bulklight=true, BandagePack=true, Straplight=true,
    A60=true, A120=true, BackdoorLookman=true, BackdoorRush=true,
    SideroomSpace=true, EntityModel=true, ["NDA5OiBDT05GTElDVA=="]=true, GlitchAmbush=true,
    PathfindNodes=true,
}
for Name in pairs(OtherMonsterNames) do ESPCandidateNames[Name] = true end

function CR4.ShouldProcessESPObject(Object)
    if not Object then return false end
    if ESPCandidateNames[Object.Name] then return true end
    if Object.Name == "Handle" or Object.Name == "Main" or Object.Name == "Base"
        or Object.Name == "Hitbox" or Object.Name == "Clock" then
        local Current = Object.Parent
        while Current and Current ~= workspace do
            if ESPCandidateNames[Current.Name] then return true end
            Current = Current.Parent
        end
    end
    return false
end

function CR4.ProcessESPObject(Object)
    if not CR4.ShouldProcessESPObject(Object) then return end
    local Target, Category = CR4.ResolveObjectESP(Object)
    if Target and Category then CR4.RegisterESP(Target, Category) end
    local MonsterTarget, MonsterCategory = CR4.ResolveMonsterESP(Object)
    if MonsterTarget and MonsterCategory then CR4.RegisterESP(MonsterTarget, MonsterCategory) end
end

function CR4.ScanESPContainer(Container, YieldEvery)
    YieldEvery = YieldEvery or 180
    CR4.ProcessESPObject(Container)
    local Descendants = Container:GetDescendants()
    for Index, Object in ipairs(Descendants) do
        CR4.ProcessESPObject(Object)
        if Index % YieldEvery == 0 then task.wait() end
    end
end

function CR4.ScanESP()
    task.spawn(function()
        for _, Room in ipairs(CurrentRooms:GetChildren()) do CR4.ScanESPContainer(Room, 180) end
        local Drops = workspace:FindFirstChild("Drops")
        if Drops then CR4.ScanESPContainer(Drops, 120) end
        for _, Object in ipairs(workspace:GetChildren()) do
            if Object ~= CurrentRooms and Object ~= Drops and Object ~= HighlightFolder then
                local Name = Object.Name
                if Name == "RushMoving" or Name == "AmbushMoving" or Name == "SeekMovingNewClone"
                    or Name == "Dread" or Name == "Screech" or OtherMonsterNames[Name] then
                    CR4.ScanESPContainer(Object, 120)
                end
            end
        end
    end)
end

function CR4.RefreshESPEntries()
    for Target, Entry in pairs(ESPEntries) do
        if Target and Target.Parent then CR4.ConfigureESPEntry(Entry) else CR4.DestroyESPEntry(Target) end
    end
    CR4.RebuildProtectedESPParts()
    if State.XRay then
        for Part in pairs(ProtectedESPParts) do
            if RestoreXRayForTarget then RestoreXRayForTarget(Part) end
        end
    end
end

function CR4.GetScreenBounds(BoxCFrame, BoxSize)
    if not Camera then return nil, nil end
    local Half = BoxSize * 0.5
    local MinX, MinY = math.huge, math.huge
    local MaxX, MaxY = -math.huge, -math.huge
    local VisiblePoints = 0

    for X = -1, 1, 2 do
        for Y = -1, 1, 2 do
            for Z = -1, 1, 2 do
                local Point = BoxCFrame:PointToWorldSpace(Vector3.new(Half.X * X, Half.Y * Y, Half.Z * Z))
                local ScreenPoint = Camera:WorldToViewportPoint(Point)
                if ScreenPoint.Z > 0 then
                    VisiblePoints += 1
                    MinX = math.min(MinX, ScreenPoint.X)
                    MinY = math.min(MinY, ScreenPoint.Y)
                    MaxX = math.max(MaxX, ScreenPoint.X)
                    MaxY = math.max(MaxY, ScreenPoint.Y)
                end
            end
        end
    end

    if VisiblePoints == 0 then return nil, nil end
    local Viewport = Camera.ViewportSize
    MinX = math.clamp(MinX, 0, Viewport.X)
    MinY = math.clamp(MinY, 0, Viewport.Y)
    MaxX = math.clamp(MaxX, 0, Viewport.X)
    MaxY = math.clamp(MaxY, 0, Viewport.Y)
    if MaxX - MinX < 2 or MaxY - MinY < 2 then return nil, nil end
    return Vector2.new(MinX, MinY), Vector2.new(MaxX, MaxY)
end

function CR4.GetTracerOrigin()
    local Viewport = Camera and Camera.ViewportSize or Vector2.new(1, 1)
    local Offset = State.ESPVerticalOffset
    if State.TracerOrigin == "Center" then
        return Vector2.new(Viewport.X * 0.5, Viewport.Y * 0.5 + Offset)
    elseif State.TracerOrigin == "Top" then
        return Vector2.new(Viewport.X * 0.5, math.max(1, 1 + Offset))
    end
    return Vector2.new(Viewport.X * 0.5, math.clamp(Viewport.Y - 2 + Offset, 1, Viewport.Y - 1))
end

function CR4.SetTracerLine(Line, From, To, Thickness)
    local Delta = To - From
    local Length = Delta.Magnitude
    if Length < 1 then Line.Visible = false return end
    Line.Position = UDim2.fromOffset((From.X + To.X) * 0.5, (From.Y + To.Y) * 0.5)
    Line.Size = UDim2.fromOffset(Length, math.max(1, Thickness))
    Line.Rotation = math.deg(math.atan2(Delta.Y, Delta.X))
end

function CR4.HideESPEntry(Entry)
    Entry.Box.Visible = false
    Entry.Tracer.Visible = false
    Entry.Label.Visible = false
end

ESPRenderAccumulator = 0
function CR4.UpdateESPOverlay(DeltaTime)
    ESPRenderAccumulator += DeltaTime
    if ESPRenderAccumulator < (1 / math.max(10, State.ESPFPS)) then return end
    ESPRenderAccumulator = 0

    Camera = workspace.CurrentCamera or Camera
    if not Camera then return end
    local CameraPosition = Camera.CFrame.Position
    local DeadTargets = {}

    for Target, Entry in pairs(ESPEntries) do
        local Config = ESPCategories[Entry.Category]
        if not Target or not Target.Parent or not Config then
            table.insert(DeadTargets, Target)
        elseif not Config.Enabled then
            Entry.Highlight.Enabled = false
            CR4.HideESPEntry(Entry)
        else
            CR4.ConfigureESPEntry(Entry)
            if not Config.Boxes and not Config.Tracers and not State.ESPNames and not State.ESPDistance then
                CR4.HideESPEntry(Entry)
            else
                local BoxCFrame, BoxSize = CR4.GetTargetBoundingBox(Target)
                if not BoxCFrame then
                    CR4.HideESPEntry(Entry)
                else
                    local Distance = (BoxCFrame.Position - CameraPosition).Magnitude
                    if Distance > State.ESPMaxDistance then
                        CR4.HideESPEntry(Entry)
                    else
                        local TopLeft, BottomRight = CR4.GetScreenBounds(BoxCFrame, BoxSize)
                        if not TopLeft then
                            CR4.HideESPEntry(Entry)
                        else
                            local Offset = Vector2.new(0, State.ESPVerticalOffset)
                            TopLeft += Offset
                            BottomRight += Offset
                            local Width = BottomRight.X - TopLeft.X
                            local Height = BottomRight.Y - TopLeft.Y
                            local BottomCenter = Vector2.new(TopLeft.X + Width * 0.5, BottomRight.Y)

                            Entry.Stroke.Color = Config.Color
                            Entry.Stroke.Thickness = State.ESPThickness
                            Entry.Box.Position = UDim2.fromOffset(TopLeft.X, TopLeft.Y)
                            Entry.Box.Size = UDim2.fromOffset(Width, Height)
                            Entry.Box.Visible = Config.Boxes

                            Entry.Tracer.BackgroundColor3 = Config.Color
                            CR4.SetTracerLine(Entry.Tracer, CR4.GetTracerOrigin(), BottomCenter, State.ESPThickness)
                            Entry.Tracer.Visible = Config.Tracers

                            local LabelParts = {}
                            if State.ESPNames then table.insert(LabelParts, CR4.GetDisplayName(Target, Entry.Category)) end
                            if State.ESPDistance then table.insert(LabelParts, string.format("%d studs", math.floor(Distance + 0.5))) end
                            Entry.Label.TextColor3 = Config.Color
                            Entry.Label.Text = table.concat(LabelParts, " | ")
                            Entry.Label.Position = UDim2.fromOffset(TopLeft.X + Width * 0.5, TopLeft.Y - 2)
                            Entry.Label.Size = UDim2.fromOffset(math.max(120, Width + 40), 18)
                            Entry.Label.Visible = #LabelParts > 0
                        end
                    end
                end
            end
        end
    end

    for _, Target in ipairs(DeadTargets) do CR4.DestroyESPEntry(Target) end
end

CR4.TrackConnection(RunService.RenderStepped:Connect(CR4.UpdateESPOverlay))
