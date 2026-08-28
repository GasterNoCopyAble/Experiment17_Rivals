-- Experiment 17 | Rivals | Fun.lua
-- Physical logical module. Loaded in the shared Loader.lua environment.

--==================================================
-- CUSTOM TEXTURES
--==================================================

OriginalTextureProperties = setmetatable({}, { __mode = "k" })
SelectedTextureOverrides = setmetatable({}, { __mode = "k" })
TextureTargetMap = {}
TextureSelectedCategories = {}

function CR4.NormalizeAssetId(Value)
    if type(Value) ~= "string" then return nil end
    Value = Value:gsub("%s+", "")
    if Value == "" then return nil end
    local Digits = Value:match("(%d+)")
    if not Digits then return nil end
    return "rbxassetid://" .. Digits
end

function CR4.RememberTextureProperty(Object, Property)
    local Data = OriginalTextureProperties[Object]
    if not Data then Data = {}; OriginalTextureProperties[Object] = Data end
    if Data[Property] == nil then
        local Success, Value = pcall(function() return Object[Property] end)
        if Success then Data[Property] = Value end
    end
end

function CR4.SetTextureProperty(Object, Property, AssetId)
    CR4.RememberTextureProperty(Object, Property)
    pcall(function() Object[Property] = AssetId end)
end

function CR4.ApplyTextureObject(Object, AssetId)
    if not Object or not Object.Parent or not AssetId then return end
    if Object:IsA("MeshPart") then
        CR4.SetTextureProperty(Object, "TextureID", AssetId)
    elseif Object:IsA("SpecialMesh") then
        CR4.SetTextureProperty(Object, "TextureId", AssetId)
    elseif Object:IsA("Decal") or Object:IsA("Texture") then
        CR4.SetTextureProperty(Object, "Texture", AssetId)
    elseif Object:IsA("SurfaceAppearance") then
        CR4.SetTextureProperty(Object, "ColorMap", AssetId)
    end
end

function CR4.ApplyTextureRoot(Root, AssetId)
    if not Root or not Root.Parent or not AssetId then return end
    CR4.ApplyTextureObject(Root, AssetId)
    local Descendants = Root:GetDescendants()
    for Index, Object in ipairs(Descendants) do
        CR4.ApplyTextureObject(Object, AssetId)
        if Index % 250 == 0 then task.wait() end
    end
end

function CR4.RestoreTextureRoot(Root)
    if not Root then return end
    local function RestoreOne(Object)
        local Data = OriginalTextureProperties[Object]
        if Data and Object and Object.Parent then
            for Property, Value in pairs(Data) do pcall(function() Object[Property] = Value end) end
            OriginalTextureProperties[Object] = nil
        end
    end
    RestoreOne(Root)
    for _, Object in ipairs(Root:GetDescendants()) do RestoreOne(Object) end
end

function CR4.RestoreAllTextures()
    for Object, Data in pairs(OriginalTextureProperties) do
        if Object and Object.Parent then
            for Property, Value in pairs(Data) do pcall(function() Object[Property] = Value end) end
        end
        OriginalTextureProperties[Object] = nil
    end
end

function CR4.BuildTextureTargetList()
    local Values = {}
    TextureTargetMap = {}
    local Counter = 0
    for Target, Entry in pairs(ESPEntries) do
        if Target and Target.Parent and not MonsterCategorySet[Entry.Category] then
            Counter += 1
            local Room = CR4.GetRoomNumberFromObject and CR4.GetRoomNumberFromObject(Target) or nil
            local Name = string.format("%s | %s%s | %d", Entry.Category, CR4.GetDisplayName(Target, Entry.Category), Room and (" | R" .. Room) or "", Counter)
            TextureTargetMap[Name] = Target
            table.insert(Values, Name)
        end
    end
    table.sort(Values)
    if Options.TextureSelectedTarget then
        Options.TextureSelectedTarget:SetValues(Values)
        if #Values > 0 and not Options.TextureSelectedTarget.Value then Options.TextureSelectedTarget:SetValue(Values[1]) end
    end
end

function CR4.IsPlayerCharacterObject(Object)
    local Current = Object
    while Current and Current ~= workspace do
        if Current:IsA("Model") and Players:GetPlayerFromCharacter(Current) then return true end
        Current = Current.Parent
    end
    return false
end

CustomTextureGeneration = 0
function CR4.ApplyCustomTextureMode()
    CustomTextureGeneration += 1
    local Generation = CustomTextureGeneration
    CR4.RestoreAllTextures()
    if not State.CustomTexture then return end

    if State.CustomTextureMode == "Selected Objects" then
        task.spawn(function()
            for Target, Id in pairs(SelectedTextureOverrides) do
                if Generation ~= CustomTextureGeneration then return end
                if Target and Target.Parent and Id then CR4.ApplyTextureRoot(Target, Id) end
            end
        end)
        return
    end

    local AssetId = CR4.NormalizeAssetId(State.CustomTextureID)
    if not AssetId then return end

    if State.CustomTextureMode == "Object Types" then
        task.spawn(function()
            for Target, Entry in pairs(ESPEntries) do
                if Generation ~= CustomTextureGeneration then return end
                if Target and Target.Parent and TextureSelectedCategories[Entry.Category] then
                    CR4.ApplyTextureRoot(Target, AssetId)
                    task.wait()
                end
            end
        end)
        return
    end

    task.spawn(function()
        local Objects = workspace:GetDescendants()
        for Index, Object in ipairs(Objects) do
            if Generation ~= CustomTextureGeneration then return end
            if not CR4.IsPlayerCharacterObject(Object)
                and not Object:IsDescendantOf(HighlightFolder)
                and not Object:IsDescendantOf(PathFolder) then
                CR4.ApplyTextureObject(Object, AssetId)
            end
            if Index % 250 == 0 then task.wait() end
        end
    end)
end

--==================================================
-- UI CLICK SOUND
--==================================================

ClickSound = Instance.new("Sound")
ClickSound.Name = "LinoriaClickSound"
ClickSound.Volume = State.ClickSoundVolume
ClickSound.Parent = SoundService

function CR4.GetClickSoundId()
    local Index = tonumber((State.ClickSoundSlot or ""):match("(%d+)")) or 1
    return CR4.NormalizeAssetId(CLICK_SOUND_IDS[Index] or "")
end

function CR4.PointInsideFrame(Frame, Point)
    if not Frame or not Frame.Visible then return false end
    local Pos, Size = Frame.AbsolutePosition, Frame.AbsoluteSize
    return Point.X >= Pos.X and Point.X <= Pos.X + Size.X and Point.Y >= Pos.Y and Point.Y <= Pos.Y + Size.Y
end

function CR4.IsPointInLinoriaUI(Point)
    -- Compatibility name: this now checks the Legacy v22 root/menu.
    local NativeMain = Library.Native and Library.Native.Main

    if NativeMain and CR4.PointInsideFrame(NativeMain, Point) then return true end
    return false
end

function CR4.PlayClickSound()
    if not State.ClickSounds then return end
    local Id = CR4.GetClickSoundId()
    if not Id then return end
    ClickSound.SoundId = Id
    ClickSound.Volume = State.ClickSoundVolume
    pcall(function()
        ClickSound.TimePosition = 0
        ClickSound:Play()
    end)
end

CR4.TrackConnection(UserInputService.InputBegan:Connect(function(Input)
    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return end
    local Point = Input.UserInputType == Enum.UserInputType.Touch and Vector2.new(Input.Position.X, Input.Position.Y) or UserInputService:GetMouseLocation()
    if CR4.IsPointInLinoriaUI(Point) then CR4.PlayClickSound() end
end))

--==================================================
-- NOTIFICATIONS / BACKDOORS TIMER / CONTACT
--==================================================

NotificationSound = Instance.new("Sound")
NotificationSound.Name = "Experiment17NotifySound"
NotificationSound.Volume = State.NotificationSoundVolume
NotificationSound.Parent = SoundService
MonsterQuestionMarks = setmetatable({}, {__mode="k"})

BackdoorsTimerLabel = Instance.new("TextLabel")
BackdoorsTimerLabel.Name = "Experiment17BackdoorsTimer"
BackdoorsTimerLabel.AnchorPoint = Vector2.new(0.5,0)
BackdoorsTimerLabel.Position = UDim2.new(0.5,0,0,12)
BackdoorsTimerLabel.Size = UDim2.fromOffset(240,34)
BackdoorsTimerLabel.BackgroundColor3 = Color3.fromRGB(15,15,18)
BackdoorsTimerLabel.BackgroundTransparency = 0.25
BackdoorsTimerLabel.BorderSizePixel = 0
BackdoorsTimerLabel.Font = Enum.Font.Code
BackdoorsTimerLabel.TextColor3 = Color3.new(1,1,1)
BackdoorsTimerLabel.TextStrokeTransparency = 0
BackdoorsTimerLabel.TextSize = 18
BackdoorsTimerLabel.Visible = false
BackdoorsTimerLabel.ZIndex = 950
BackdoorsTimerLabel.Parent = Library.ScreenGui
BTLCorner = Instance.new("UICorner"); BTLCorner.CornerRadius = UDim.new(0,8); BTLCorner.Parent = BackdoorsTimerLabel

function CR4.PlayNotificationSound()
    if not State.NotificationSounds then return end
    local Index = tonumber(string.match(State.NotificationSoundSlot or "","%d+")) or 1
    local Id = NOTIFICATION_SOUND_IDS[Index]
    if type(Id) ~= "string" or Id == "" then return end
    if not string.find(Id,"rbxassetid://",1,true) then Id = "rbxassetid://" .. Id end
    NotificationSound.SoundId = Id; NotificationSound.Volume = State.NotificationSoundVolume; NotificationSound.TimePosition = 0; NotificationSound:Play()
end

function CR4.GetNearestWardrobe(Position)
    local Best,BestD = nil,math.huge
    for Target,Entry in pairs(ESPEntries) do
        if Target and Target.Parent and Entry.Category == "Wardrobes" then
            local P = CR4.GetWorldPosition(Target)
            if P then local D=(P-Position).Magnitude; if D<BestD then Best,BestD=Target,D end end
        end
    end
    return Best
end

WardrobeThreatCategories = { Rush=true, Ambush=true, A60=true, A120=true, BackdoorRush=true }
function CR4.MarkWardrobeDanger(Monster, Category)
    if not State.MonsterQuestionMark or not WardrobeThreatCategories[Category] then return end
    local P=CR4.GetWorldPosition(Monster); if not P then return end
    local W=CR4.GetNearestWardrobe(P); if not W then return end
    local Adornee=W:IsA("BasePart") and W or W:FindFirstChildWhichIsA("BasePart",true); if not Adornee then return end
    local Existing=MonsterQuestionMarks[W]; if Existing then Existing:Destroy() end
    local Gui=Instance.new("BillboardGui"); Gui.Name="Experiment17Danger"; Gui.Adornee=Adornee; Gui.AlwaysOnTop=true; Gui.Size=UDim2.fromOffset(70,70); Gui.StudsOffset=Vector3.new(0,4,0); Gui.Parent=Library.ScreenGui
    local L=Instance.new("TextLabel"); L.BackgroundTransparency=1; L.Size=UDim2.fromScale(1,1); L.Text="?"; L.TextColor3=Color3.fromRGB(255,30,30); L.TextStrokeTransparency=0; L.TextScaled=true; L.Font=Enum.Font.GothamBlack; L.Parent=Gui
    MonsterQuestionMarks[W]=Gui
    task.delay(12,function() if Gui and Gui.Parent then Gui:Destroy() end if MonsterQuestionMarks[W]==Gui then MonsterQuestionMarks[W]=nil end end)
end

function CR4.OnMonsterSpawned(Target,Category)
    if not MonsterCategorySet[Category] then return end
    local Display=(Category=="OtherMonsters" and Target.Name) or (ESPCategories[Category] and ESPCategories[Category].Label) or Category
    if State.MonsterNotifications then CR4.Notify(Display.." spawned",4) end
    CR4.PlayNotificationSound()
    CR4.MarkWardrobeDanger(Target,Category)
end

LastMonsterNotified=setmetatable({}, {__mode="k"})
OldRegisterESP=CR4.RegisterESP
function CR4.RegisterESP(Target,Category)
    local Was=ESPEntries[Target]~=nil
    OldRegisterESP(Target,Category)
    if MonsterCategorySet[Category] and not Was and Target and Target.Parent and not LastMonsterNotified[Target] then
        LastMonsterNotified[Target]=true; task.defer(CR4.OnMonsterSpawned,Target,Category)
    end
end

function CR4.UpdateBackdoorsTimer()
    if not State.ShowBackdoorsTimer then BackdoorsTimerLabel.Visible=false; return end
    local Room50=CurrentRooms:FindFirstChild("50")
    local TL=Room50 and Room50:FindFirstChild("TimerLever",true)
    local DT=TL and TL:FindFirstChild("DisplayTimer",true)
    local TextObj=nil
    if DT and (DT:IsA("TextLabel") or DT:IsA("TextBox") or DT:IsA("TextButton")) then
        TextObj=DT
    elseif DT then
        TextObj=DT:FindFirstChildWhichIsA("TextLabel",true) or DT:FindFirstChildWhichIsA("TextBox",true) or DT:FindFirstChildWhichIsA("TextButton",true)
    end
    if TextObj then BackdoorsTimerLabel.Text="Backdoors: "..tostring(TextObj.Text); BackdoorsTimerLabel.Visible=true else BackdoorsTimerLabel.Visible=false end
end

function CR4.CopyContact(Key)
    local Link=CONTACT_LINKS[Key]
    if type(Link)~="string" or Link=="" then CR4.Notify(Key.." link is empty",3); return end
    local F=(getgenv and getgenv().setclipboard) or (type(setclipboard)=="function" and setclipboard or nil)
    if type(F)=="function" then pcall(F,Link); CR4.Notify(Key.." copied",2) else CR4.Notify(Link,6) end
end
