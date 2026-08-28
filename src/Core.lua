-- Experiment 17 | Rivals | Core.lua
-- Physical logical module. Loaded in the shared Loader.lua environment.

--[[
    Experiment 17 | Experiment17_GuiLib Legacy v22

    DEBUG_LOADSTRING_URLS: 4 debug loadstring URLs.
    CLICK_SOUND_IDS: 10 UI click sound IDs.
    NOTIFICATION_SOUND_IDS: 10 notification sound IDs.
    CONTACT_LINKS: Discord / Telegram.

    UI backend:
    https://github.com/GasterNoCopyAble/Experiment17_GuiLib
]]

--==================================================
-- DEBUG / SOUND SLOTS
--==================================================

DEBUG_LOADSTRING_URLS = {
    "", -- Slot 1
    "", -- Slot 2
    "", -- Slot 3
    "", -- Slot 4
}

CLICK_SOUND_IDS = {
    "", -- Sound 1
    "", -- Sound 2
    "", -- Sound 3
    "", -- Sound 4
    "", -- Sound 5
    "", -- Sound 6
    "", -- Sound 7
    "", -- Sound 8
    "", -- Sound 9
    "", -- Sound 10
}

NOTIFICATION_SOUND_IDS = {
    "", -- Notify 1
    "", -- Notify 2
    "", -- Notify 3
    "", -- Notify 4
    "", -- Notify 5
    "", -- Notify 6
    "", -- Notify 7
    "", -- Notify 8
    "", -- Notify 9
    "", -- Notify 10
}

CONTACT_LINKS = {
    Discord = "",
    Telegram = "",
}

--==================================================
-- EXPERIMENT17 GUI LIB v22 / LINORIA COMPATIBILITY
--==================================================
--==================================================
-- EXPERIMENT 17 GUI LIB v22 / LINORIA COMPAT BRIDGE
-- Replace the old LINORIA block with this block.
--==================================================

NativeLibrary = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/GasterNoCopyAble/Experiment17_GuiLib/main/Experiment17.lua"
))()

Environment = getgenv()
Environment.Toggles = {}
Environment.Options = {}

Toggles = Environment.Toggles
Options = Environment.Options

Library = {}
ThemeManager = {}
SaveManager = {}

Library.Native = NativeLibrary
Library.ScreenGui = NativeLibrary.Root
Library.OpenedFrames = {}
if NativeLibrary.Main then
    Library.OpenedFrames[NativeLibrary.Main] = true
end

CompatConnections = {}
CompatControls = {}
CompatKeybinds = {}
UnloadCallbacks = {}
CompatUnloading = false

function trackCompat(Connection)
    if Connection then
        table.insert(CompatConnections, Connection)
    end
    return Connection
end

function safeCall(Function, ...)
    if type(Function) ~= "function" then
        return
    end
    local Ok, ErrorText = pcall(Function, ...)
    if not Ok then
        warn("[Experiment17 GUI Compat] callback error:", ErrorText)
    end
end

function arrayToLinoriaMap(Value)
    local Result = {}
    if type(Value) ~= "table" then
        return Result
    end

    for Key, Item in pairs(Value) do
        if type(Key) == "number" then
            Result[Item] = true
        elseif Item == true then
            Result[Key] = true
        end
    end

    return Result
end

function linoriaMapToArray(Value)
    if type(Value) ~= "table" then
        return {}
    end

    local IsArray = #Value > 0
    if IsArray then
        local Copy = {}
        for Index, Item in ipairs(Value) do
            Copy[Index] = Item
        end
        return Copy
    end

    local Result = {}
    for Key, Enabled in pairs(Value) do
        if Enabled then
            table.insert(Result, Key)
        end
    end
    table.sort(Result, function(A, B)
        return tostring(A) < tostring(B)
    end)
    return Result
end

function getNativeValue(Control)
    if not Control or type(Control.Get) ~= "function" then
        return nil
    end

    local Ok, Value = pcall(function()
        return Control:Get()
    end)
    return Ok and Value or nil
end

function setNativeDPI(Value)
    Value = tonumber(Value)
    if not Value then
        return
    end

    local Candidates = { 50, 75, 100, 125, 150, 175 }
    local Best = Candidates[1]
    local BestDistance = math.huge

    for _, Candidate in ipairs(Candidates) do
        local Distance = math.abs(Candidate - Value)
        if Distance < BestDistance then
            BestDistance = Distance
            Best = Candidate
        end
    end

    if NativeLibrary.Settings then
        NativeLibrary.Settings.AutoFitDPI = false
        NativeLibrary.Settings.DPIPreset = tostring(Best) .. "%"
    end

    if type(NativeLibrary.ApplyDPIScale) == "function" then
        pcall(function()
            NativeLibrary:ApplyDPIScale()
        end)
    end
end

function applyNativeSpecial(Id, Value)
    if Id == "DPIScale" then
        setNativeDPI(Value)

    elseif Id == "FloatingGUIButton" then
        if NativeLibrary.Settings then
            NativeLibrary.Settings.MobileButtonEnabled = Value == true
        end
        if type(NativeLibrary.RefreshMobileButton) == "function" then
            pcall(function()
                NativeLibrary:RefreshMobileButton()
            end)
        end

    elseif Id == "FloatingGUIButtonSize" then
        if NativeLibrary.Settings then
            NativeLibrary.Settings.MobileButtonSize = tonumber(Value) or NativeLibrary.Settings.MobileButtonSize
        end
        if type(NativeLibrary.RefreshMobileButton) == "function" then
            pcall(function()
                NativeLibrary:RefreshMobileButton()
            end)
        end

    elseif Id == "MenuKeybind" then
        local KeyName = Value
        if typeof(Value) == "EnumItem" then
            KeyName = Value.Name
        end
        KeyName = tostring(KeyName or "RightShift")
        if Enum.KeyCode[KeyName] and NativeLibrary.Settings then
            NativeLibrary.Settings.MenuKey = KeyName
        end
    end
end

CompatControl = {}
CompatControl.__index = CompatControl

function CompatControl:_fromNative(Value)
    if self.Multi then
        return arrayToLinoriaMap(Value)
    end

    if self.SpecialType == "Player" and (Value == nil or Value == "None") then
        return nil
    end

    return Value
end

function CompatControl:_toNative(Value)
    if self.Multi then
        return linoriaMapToArray(Value)
    end

    if self.SpecialType == "Player" and Value == nil then
        return "None"
    end

    if self.Kind == "Keybind" and typeof(Value) == "EnumItem" then
        return Value.Name
    end

    return Value
end

function CompatControl:_emit(Value, Force)
    Value = self:_fromNative(Value)
    local OldValue = self.Value
    self.Value = Value
    applyNativeSpecial(self.Id, Value)

    local Changed = Force or OldValue ~= Value or type(Value) == "table"
    if not Changed then
        return
    end

    for _, Callback in ipairs(self.Callbacks) do
        safeCall(Callback, Value)
    end
end

function CompatControl:OnChanged(Callback)
    if type(Callback) == "function" then
        table.insert(self.Callbacks, Callback)
    end
    return self
end

function CompatControl:SetValue(Value)
    local NativeValue = self:_toNative(Value)

    if self.Native and type(self.Native.Set) == "function" then
        local Ok = pcall(function()
            self.Native:Set(NativeValue, false)
        end)

        if Ok then
            local Current = getNativeValue(self.Native)
            if Current ~= nil then
                self:_emit(Current, false)
                return self
            end
        end
    end

    self:_emit(Value, true)
    return self
end

function CompatControl:SetValues(Values)
    if type(Values) ~= "table" then
        Values = {}
    end

    self.Values = Values

    if self.Native and type(self.Native.SetValues) == "function" then
        local NativeValues = Values
        if #NativeValues == 0 then
            NativeValues = { "None" }
        end

        pcall(function()
            self.Native:SetValues(NativeValues, true)
        end)

        local Current = getNativeValue(self.Native)
        if Current ~= nil then
            self:_emit(Current, false)
        end
    end

    return self
end

function CompatControl:AddColorPicker(Id, Config)
    return self.Section:_AddColorPicker(Id, Config or {})
end

function CompatControl:AddKeyPicker(Id, Config)
    return self.Section:_AddKeyPicker(Id, Config or {}, self)
end

function registerCompatControl(Store, Id, NativeControl, DefaultValue, Meta)
    Meta = Meta or {}

    local Control = setmetatable({
        Id = Id,
        Kind = Meta.Kind,
        Native = NativeControl,
        Section = Meta.Section,
        Multi = Meta.Multi == true,
        SpecialType = Meta.SpecialType,
        SyncToggleState = Meta.SyncToggleState == true,
        Mode = Meta.Mode or "Toggle",
        NoUI = Meta.NoUI == true,
        LinkedToggle = Meta.LinkedToggle,
        Value = DefaultValue,
        Values = Meta.Values,
        Callbacks = {},
    }, CompatControl)

    Store[Id] = Control
    CompatControls[Id] = Control
    applyNativeSpecial(Id, DefaultValue)
    return Control
end

SectionCompat = {}
SectionCompat.__index = SectionCompat

function SectionCompat:AddToggle(Id, Config)
    Config = Config or {}
    local Wrapper

    local NativeControl = self.Native:AddToggle({
        Name = Config.Text or Id,
        Flag = Id,
        Default = Config.Default == true,
        RequiredGraphics = "Low",
        Callback = function(Value)
            if Wrapper then
                Wrapper:_emit(Value, false)
            end
        end,
    })

    Wrapper = registerCompatControl(Toggles, Id, NativeControl, Config.Default == true, {
        Kind = "Toggle",
        Section = self,
    })

    return Wrapper
end

function SectionCompat:AddSlider(Id, Config)
    Config = Config or {}
    local Wrapper
    local DefaultValue = tonumber(Config.Default) or tonumber(Config.Min) or 0

    local NativeControl = self.Native:AddSlider({
        Name = Config.Text or Id,
        Flag = Id,
        Min = tonumber(Config.Min) or 0,
        Max = tonumber(Config.Max) or 100,
        Default = DefaultValue,
        Decimals = tonumber(Config.Rounding) or 0,
        RequiredGraphics = "Low",
        Callback = function(Value)
            if Wrapper then
                Wrapper:_emit(Value, false)
            end
        end,
    })

    Wrapper = registerCompatControl(Options, Id, NativeControl, DefaultValue, {
        Kind = "Slider",
        Section = self,
    })

    return Wrapper
end

function getPlayerValues()
    local PlayerService = game:GetService("Players")
    local Values = { "None" }

    for _, Player in ipairs(PlayerService:GetPlayers()) do
        if Player ~= PlayerService.LocalPlayer then
            table.insert(Values, Player.Name)
        end
    end

    table.sort(Values, function(A, B)
        if A == "None" then return true end
        if B == "None" then return false end
        return A:lower() < B:lower()
    end)

    return Values
end

function SectionCompat:AddDropdown(Id, Config)
    Config = Config or {}
    local Wrapper
    local IsMulti = Config.Multi == true
    local IsPlayer = Config.SpecialType == "Player"
    local Values = IsPlayer and getPlayerValues() or (Config.Values or { "None" })

    if #Values == 0 then
        Values = { "None" }
    end

    if IsMulti then
        local DefaultValue = Config.Default or {}
        local NativeControl = self.Native:AddMultiDropdown({
            Name = Config.Text or Id,
            Flag = Id,
            Values = Values,
            Default = linoriaMapToArray(DefaultValue),
            RequiredGraphics = "Low",
            Callback = function(Value)
                if Wrapper then
                    Wrapper:_emit(Value, false)
                end
            end,
        })

        Wrapper = registerCompatControl(Options, Id, NativeControl, arrayToLinoriaMap(DefaultValue), {
            Kind = "Dropdown",
            Section = self,
            Multi = true,
            Values = Values,
        })
    else
        local DefaultValue = Config.Default
        if IsPlayer and DefaultValue == nil then
            DefaultValue = "None"
        elseif DefaultValue == nil then
            DefaultValue = Values[1]
        end

        local NativeControl = self.Native:AddChoice({
            Name = Config.Text or Id,
            Flag = Id,
            Values = Values,
            Default = DefaultValue,
            RequiredGraphics = "Low",
            Callback = function(Value)
                if Wrapper then
                    Wrapper:_emit(Value, false)
                end
            end,
        })

        Wrapper = registerCompatControl(Options, Id, NativeControl,
            IsPlayer and (DefaultValue == "None" and nil or DefaultValue) or DefaultValue, {
                Kind = "Dropdown",
                Section = self,
                SpecialType = IsPlayer and "Player" or nil,
                Values = Values,
            })
    end

    if IsPlayer then
        local PlayerService = game:GetService("Players")
        local function RefreshPlayers()
            if not Wrapper then return end
            Wrapper:SetValues(getPlayerValues())
        end
        trackCompat(PlayerService.PlayerAdded:Connect(RefreshPlayers))
        trackCompat(PlayerService.PlayerRemoving:Connect(function()
            task.defer(RefreshPlayers)
        end))
    end

    return Wrapper
end

function SectionCompat:AddInput(Id, Config)
    Config = Config or {}
    local Wrapper
    local DefaultValue = tostring(Config.Default or "")

    local NativeControl = self.Native:AddInput({
        Name = Config.Text or Id,
        Flag = Id,
        Default = DefaultValue,
        Placeholder = Config.Placeholder or "",
        RequiredGraphics = "Low",
        Callback = function(Value)
            if Wrapper then
                Wrapper:_emit(Value, false)
            end
        end,
    })

    Wrapper = registerCompatControl(Options, Id, NativeControl, DefaultValue, {
        Kind = "Input",
        Section = self,
    })

    return Wrapper
end

function SectionCompat:AddButton(Config)
    Config = Config or {}
    local LastClick = 0

    self.Native:AddButton({
        Name = Config.Text or "Button",
        ButtonText = Config.Text or "Button",
        RequiredGraphics = "Low",
        Callback = function()
            if Config.DoubleClick then
                local Now = os.clock()
                if Now - LastClick > 0.55 then
                    LastClick = Now
                    NativeLibrary:Notify({
                        Title = "Experiment 17",
                        Text = "Click again to confirm",
                        Type = "Warning",
                        Duration = 1.5,
                    })
                    return
                end
                LastClick = 0
            end

            safeCall(Config.Func)
        end,
    })

    return self
end

function SectionCompat:_AddColorPicker(Id, Config, LabelText)
    Config = Config or {}
    local Wrapper
    local DefaultValue = Config.Default or Color3.new(1, 1, 1)

    local NativeControl = self.Native:AddColorPicker({
        Name = Config.Title or LabelText or Config.Text or Id,
        Flag = Id,
        Default = DefaultValue,
        RequiredGraphics = "Low",
        Callback = function(Value)
            if Wrapper then
                Wrapper:_emit(Value, false)
            end
        end,
    })

    Wrapper = registerCompatControl(Options, Id, NativeControl, DefaultValue, {
        Kind = "ColorPicker",
        Section = self,
    })

    return Wrapper
end

function SectionCompat:_AddKeyPicker(Id, Config, LinkedToggle, LabelText)
    Config = Config or {}
    local Wrapper
    local DefaultValue = Config.Default or "RightShift"
    if typeof(DefaultValue) == "EnumItem" then
        DefaultValue = DefaultValue.Name
    end
    DefaultValue = tostring(DefaultValue)

    local NativeControl = nil
    if not Config.NoUI then
        NativeControl = self.Native:AddKeybind({
            Name = Config.Text or LabelText or Id,
            Flag = Id,
            Default = DefaultValue,
            RequiredGraphics = "Low",
            Callback = function(Value)
                if Wrapper then
                    Wrapper:_emit(Value, false)
                end
            end,
        })
    end

    Wrapper = registerCompatControl(Options, Id, NativeControl, DefaultValue, {
        Kind = "Keybind",
        Section = self,
        SyncToggleState = Config.SyncToggleState == true,
        Mode = Config.Mode or "Toggle",
        NoUI = Config.NoUI == true,
        LinkedToggle = LinkedToggle,
    })

    if Id == "MenuKeybind" then
        Wrapper.Value = NativeLibrary.Settings and NativeLibrary.Settings.MenuKey or DefaultValue
        applyNativeSpecial(Id, Wrapper.Value)
    end

    if Wrapper.SyncToggleState and LinkedToggle then
        table.insert(CompatKeybinds, Wrapper)
    end

    return Wrapper
end

function SectionCompat:AddLabel(Text)
    local Section = self
    local LabelProxy = {}

    function LabelProxy:AddColorPicker(Id, Config)
        return Section:_AddColorPicker(Id, Config or {}, Text)
    end

    function LabelProxy:AddKeyPicker(Id, Config)
        return Section:_AddKeyPicker(Id, Config or {}, nil, Text)
    end

    return LabelProxy
end

function wrapSection(NativeSection)
    return setmetatable({ Native = NativeSection }, SectionCompat)
end

TabCompat = {}
TabCompat.__index = TabCompat

function TabCompat:AddLeftGroupbox(Name)
    return wrapSection(self.Native:CreateSection(Name, false))
end

function TabCompat:AddRightGroupbox(Name)
    return wrapSection(self.Native:CreateSection(Name, false))
end

function wrapTab(NativeTab)
    return setmetatable({ Native = NativeTab }, TabCompat)
end

function Library:CreateWindow(Config)
    Config = Config or {}

    -- Invisible holder only exists because the old script still references
    -- Window.Holder for Linoria-specific DPI/clamping code. The real menu is
    -- NativeLibrary.Main and is fully controlled by Experiment17_GuiLib.
    local Holder = Instance.new("Frame")
    Holder.Name = "Experiment17_LinoriaCompatHolder"
    Holder.AnchorPoint = Vector2.new(0.5, 0.5)
    Holder.Position = UDim2.fromScale(0.5, 0.5)
    Holder.Size = Config.Size or UDim2.fromOffset(650, 600)
    Holder.BackgroundTransparency = 1
    Holder.Visible = false
    Holder.Parent = NativeLibrary.Root

    local Window = {
        Holder = Holder,
        Native = NativeLibrary,
    }

    function Window:AddTab(Name)
        local NativeTab
        if Name == "UI" or Name == "UI Settings" or Name == "Settings" then
            NativeTab = NativeLibrary.SettingsTab
        else
            NativeTab = NativeLibrary:CreateTab(Name)
        end

        return wrapTab(NativeTab)
    end

    return Window
end

function Library:Notify(Text, Time)
    NativeLibrary:Notify({
        Title = "Experiment 17",
        Text = tostring(Text),
        Type = "Info",
        Duration = tonumber(Time) or 3,
    })
end

function Library:Toggle()
    if NativeLibrary.Unloaded then
        return
    end
    NativeLibrary:SetMenuVisible(not NativeLibrary.MenuVisible)
end

function Library:OnUnload(Callback)
    if type(Callback) == "function" then
        table.insert(UnloadCallbacks, Callback)
    end
end

function Library:Unload()
    NativeLibrary:Unload()
end

function syncCompatControls(Force)
    for _, Control in pairs(CompatControls) do
        if Control.Native then
            local Value = getNativeValue(Control.Native)
            if Value ~= nil then
                Control:_emit(Value, Force == true)
            end
        elseif Control.Id == "MenuKeybind" and NativeLibrary.Settings then
            Control:_emit(NativeLibrary.Settings.MenuKey, Force == true)
        end
    end
end

-- Keep the old script's state/callback tables synchronized when the native
-- config system loads controls silently.
if type(NativeLibrary.LoadConfig) == "function" then
    local NativeLoadConfig = NativeLibrary.LoadConfig
    NativeLibrary.LoadConfig = function(Self, ...)
        local Result = NativeLoadConfig(Self, ...)
        task.defer(function()
            syncCompatControls(true)
        end)
        return Result
    end
end

if type(NativeLibrary.ApplyProfile) == "function" then
    local NativeApplyProfile = NativeLibrary.ApplyProfile
    NativeLibrary.ApplyProfile = function(Self, ...)
        local Result = NativeApplyProfile(Self, ...)
        task.defer(function()
            syncCompatControls(true)
        end)
        return Result
    end
end

-- Make the native library's own Unload button execute the script cleanup too.
NativeUnload = NativeLibrary.Unload
NativeLibrary.Unload = function(Self, ...)
    if CompatUnloading then
        return
    end
    CompatUnloading = true

    for _, Callback in ipairs(UnloadCallbacks) do
        pcall(Callback)
    end

    for Index = #CompatConnections, 1, -1 do
        local Connection = CompatConnections[Index]
        CompatConnections[Index] = nil
        pcall(function()
            Connection:Disconnect()
        end)
    end

    return NativeUnload(Self, ...)
end

-- Linoria had a separate floating GUI button. v22 already has its own mobile
-- button, so the legacy duplicate is suppressed while its settings are routed
-- into NativeLibrary.Settings.MobileButton* above.
function suppressOldFloatingButton(Object)
    if not Object or Object.Name ~= "LinoriaFloatingButton" or not Object:IsA("GuiObject") then
        return
    end

    Object.Visible = false
    trackCompat(Object:GetPropertyChangedSignal("Visible"):Connect(function()
        if Object.Parent and Object.Visible then
            Object.Visible = false
        end
    end))
end

for _, Object in ipairs(NativeLibrary.Root:GetChildren()) do
    suppressOldFloatingButton(Object)
end
trackCompat(NativeLibrary.Root.ChildAdded:Connect(suppressOldFloatingButton))

-- Emulate Linoria SyncToggleState keybind behavior for controls such as
-- MouseUnlockKey. MenuKeybind itself is handled natively by v22.
UserInputService = game:GetService("UserInputService")

function keyNameFromInput(Input)
    if Input.UserInputType ~= Enum.UserInputType.Keyboard then
        return nil
    end
    return Input.KeyCode ~= Enum.KeyCode.Unknown and Input.KeyCode.Name or nil
end

trackCompat(UserInputService.InputBegan:Connect(function(Input, Processed)
    if Processed or NativeLibrary.Unloaded or NativeLibrary.BindingKey then
        return
    end
    if UserInputService:GetFocusedTextBox() then
        return
    end

    local KeyName = keyNameFromInput(Input)
    if not KeyName then
        return
    end

    for _, Keybind in ipairs(CompatKeybinds) do
        if tostring(Keybind.Value) == KeyName and Keybind.LinkedToggle then
            if Keybind.Mode == "Hold" then
                Keybind.LinkedToggle:SetValue(true)
            else
                Keybind.LinkedToggle:SetValue(not Keybind.LinkedToggle.Value)
            end
        end
    end
end))

trackCompat(UserInputService.InputEnded:Connect(function(Input)
    if NativeLibrary.Unloaded then
        return
    end

    local KeyName = keyNameFromInput(Input)
    if not KeyName then
        return
    end

    for _, Keybind in ipairs(CompatKeybinds) do
        if Keybind.Mode == "Hold"
            and tostring(Keybind.Value) == KeyName
            and Keybind.LinkedToggle then
            Keybind.LinkedToggle:SetValue(false)
        end
    end
end))

-- Native v22 already owns themes/config UI. These adapters keep the original
-- script's ThemeManager/SaveManager calls valid without loading Linoria addons.
function ThemeManager:SetLibrary() end
function ThemeManager:SetFolder() end
function ThemeManager:ApplyToTab() end

function SaveManager:SetLibrary() end
function SaveManager:IgnoreThemeSettings() end
function SaveManager:SetIgnoreIndexes() end
function SaveManager:SetFolder() end
function SaveManager:BuildConfigSection() end
function SaveManager:LoadAutoloadConfig()
    if type(NativeLibrary.TryAutoload) == "function" then

        pcall(function()
            NativeLibrary:TryAutoload()
        end)
    end
    task.defer(function()
        syncCompatControls(true)
    end)
end

--==================================================
-- SERVICES / OBJECTS
--==================================================

Players = game:GetService("Players")
RunService = game:GetService("RunService")
UserInputService = game:GetService("UserInputService")
ReplicatedStorage = game:GetService("ReplicatedStorage")
Lighting = game:GetService("Lighting")
SoundService = game:GetService("SoundService")
PathfindingService = game:GetService("PathfindingService")

LocalPlayer = Players.LocalPlayer
Camera = workspace.CurrentCamera
CurrentRooms = workspace:FindFirstChild("CurrentRooms")
    or workspace:WaitForChild("CurrentRooms", 30)
Terrain = workspace:FindFirstChildOfClass("Terrain")

if not CurrentRooms then
    error("CurrentRooms was not found")
end

IsMobile = UserInputService.TouchEnabled
IsUnloading = false
CR4 = {}

-- Forward declarations used by functions defined before their implementation.
PathFolder = nil
AntiScreechBusy = false

--==================================================
-- HELPERS / CLEANUP
--==================================================

ScriptConnections = {}

function CR4.TrackConnection(Connection)
    table.insert(ScriptConnections, Connection)
    return Connection
end

function CR4.DisconnectConnection(Connection)
    if Connection then
        pcall(function()
            Connection:Disconnect()
        end)
    end
end

function CR4.DisconnectAllConnections()
    for Index = #ScriptConnections, 1, -1 do
        CR4.DisconnectConnection(table.remove(ScriptConnections, Index))
    end
end

function CR4.SafeDestroy(Object)
    if Object then
        pcall(function()
            Object:Destroy()
        end)
    end
end

function CR4.Notify(Text, Time)
    pcall(function()
        Library:Notify(Text, Time or 3)
    end)
end

function CR4.GetCharacter()
    local Character = LocalPlayer.Character

    if not Character then
        return nil, nil, nil
    end

    return Character,
        Character:FindFirstChildOfClass("Humanoid"),
        Character:FindFirstChild("HumanoidRootPart")
end

function CR4.HasAncestorNamed(Object, Name, StopAt)
    local Current = Object

    while Current and Current ~= StopAt do
        if Current.Name == Name then
            return true, Current
        end

        Current = Current.Parent
    end

    return false, nil
end

function CR4.FindAncestorFromSet(Object, NameSet, StopAt)
    local Current = Object

    while Current and Current ~= StopAt do
        if NameSet[Current.Name] then
            return Current
        end

        Current = Current.Parent
    end

    return nil
end

function CR4.IsSpatialTarget(Object)
    return Object and (Object:IsA("Model") or Object:IsA("BasePart"))
end

function CR4.GetWorldPosition(Object)
    if not Object or not Object.Parent then
        return nil
    end

    if Object:IsA("BasePart") then
        return Object.Position
    end

    if Object:IsA("Model") then
        local Success, Pivot = pcall(function()
            return Object:GetPivot()
        end)

        if Success then
            return Pivot.Position
        end
    end

    local Part = Object:FindFirstChildWhichIsA("BasePart", true)
    return Part and Part.Position or nil
end

function CR4.GetNearestSpatialDescendant(Object)
    if CR4.IsSpatialTarget(Object) then
        return Object
    end

    if not Object then
        return nil
    end

    local Model = Object:FindFirstChildWhichIsA("Model", true)
    if Model then
        return Model
    end

    return Object:FindFirstChildWhichIsA("BasePart", true)
end

--==================================================
-- STATE
--==================================================

State = {
    PromptExpander = false,
    FastPrompts = false,
    PromptThroughWalls = false,

    ESPNames = false,
    ESPDistance = false,
    ESPMaxDistance = 1200,
    ESPThickness = 1,
    ESPVerticalOffset = -8,
    TracerOrigin = "Bottom",
    ESPFillTransparency = 0.55,
    ESPFPS = 30,


    XRay = false,
    XRayMode = "Decor Only",
    XRayTransparency = 0.82,

    LowGFX = false,
    Fullbright = false,
    NoFog = false,
    NoPostEffects = false,
    NoShadows = false,
    VisualStyle = "Off",

    SmartPath = false,
    PathTargetMode = "Progress Door",
    PathRecompute = 0.35,
    PathMaxDistance = 500,
    PathColor = Color3.fromRGB(80, 220, 255),

    WalkSpeedEnabled = false,
    WalkSpeed = 20,
    SeekSpeedhack = false,
    SeekSpeed = 26,
    SpeedMethod = "WalkSpeed",
    BodyVelocityForce = 50000,
    CFrameSpeed = 14,

    JumpEnabled = false,
    JumpPower = 32,
    BunnyHop = false,
    BunnyHopStep = 1,
    BunnyHopMaxBonus = 8,
    MicroTPEnabled = false,
    MicroTPDistance = 1.2,
    MicroTPInterval = 0.08,
    FlyEnabled = false,
    FlyMethod = "BodyVelocity",
    FlySpeed = 20,
    ThirdPerson = false,
    ThirdPersonDistance = 10,
    ThirdPersonOffsetX = 0,
    ThirdPersonOffsetY = 3,
    ThirdPersonOffsetZ = 10,
    ThirdPersonSmooth = 0.22,
    MouseUnlock = false,
    FOVOverride = false,
    FOV = 80,

    AutoGold = false,
    AutoKeys = false,
    AutoLoot = false,
    AutoLootDistance = 18,

    RemovePaintingPrompts = false,
    AntiScreech = false,
    AntiScreechTurnTime = 0.25,
    AntiScreechDisable = false,
    AntiA90 = false,
    AntiStun = false,
    AntiFigure = false,
    AntiDread = false,
    AntiEyes = false,
    AntiHalt = false,
    AntiDupe = false,
    AntiSnare = false,
    AntiSeekObstacles = false,
    Room50AutoCode = false,
    AntiRush = false,
    AntiAmbush = false,
    AntiA60 = false,
    AntiA120 = false,
    AntiBackdoorRush = false,
    AntiGlitchAmbush = false,
    AntiEntityTP = false,
    AntiTeleport = false,
    AntiTeleportThreshold = 18,
    ThreatEvadeHeight = 650,

    SpectateEnabled = false,
    SpectatePlayerName = nil,

    CustomTexture = false,
    CustomTextureMode = "Whole Map",
    CustomTextureID = "",

    DPIScale = IsMobile and 80 or 100,
    FloatingButtonVisible = IsMobile,
    FloatingButtonSize = 52,
    ClickSounds = false,
    ClickSoundSlot = "Sound 1",
    ClickSoundVolume = 0.5,

    MonsterNotifications = true,
    MonsterQuestionMark = true,
    NotificationSounds = false,
    NotificationSoundSlot = "Notify 1",
    NotificationSoundVolume = 0.65,
    ShowBackdoorsTimer = true,

    FunCameraSpin = false,
    FunCameraSpinSpeed = 90,
}

A90Active = false

--==================================================
-- WINDOW / TABS
--==================================================

Window = Library:CreateWindow({
    Title = "Experiment 17",
    Center = true,
    AutoShow = true,
    Size = UDim2.fromOffset(650, 600),
    TabPadding = 2,
    MenuFadeTime = 0.2,
})

Tabs = {
    Main = Window:AddTab("Main"),
    ESP = Window:AddTab("ESP"),
    Visual = Window:AddTab("Visual"),
    Player = Window:AddTab("Player"),
    Automation = Window:AddTab("Auto"),
    Fun = Window:AddTab("Fun"),
    Notification = Window:AddTab("Notify"),
    Debug = Window:AddTab("Debug"),
    Contact = Window:AddTab("Contact"),
    ["UI Settings"] = Window:AddTab("UI"),
}

-- Native Legacy v22 handles its own tab layout. This compatibility function is
-- intentionally kept as a no-op so old calls remain harmless.
function CR4.FitTabButtons() end

task.defer(CR4.FitTabButtons)

--==================================================
-- DPI / FLOATING BUTTON
--==================================================

-- Legacy v22 already owns DPI, window dragging and the mobile GUI button.
-- Keep the old objects invisible only for compatibility with the rest of the script.
MenuScale = Instance.new("UIScale")
MenuScale.Name = "LinoriaMenuScaleCompat"
MenuScale.Scale = 1
MenuScale.Parent = Window.Holder

function CR4.ClampMenuToViewport() end

FloatingButton = Instance.new("TextButton")
FloatingButton.Name = "LinoriaFloatingButton"
FloatingButton.Visible = false
FloatingButton.Size = UDim2.fromOffset(1, 1)
FloatingButton.BackgroundTransparency = 1
FloatingButton.Text = ""
FloatingButton.Parent = Library.ScreenGui

--==================================================
-- GAME UI LABEL
--==================================================

ExperimentInfoLabel = nil
function CR4.EnsureExperimentInfoLabel()
    local PG = LocalPlayer:FindFirstChild("PlayerGui")
    local MainUI = PG and PG:FindFirstChild("MainUI")
    local Settings = MainUI and MainUI:FindFirstChild("Settings")
    if not Settings then return end
    if ExperimentInfoLabel and ExperimentInfoLabel.Parent == Settings then return end
    local Existing = Settings:FindFirstChild("Info")
    local Label = Existing
    if Label and not Label:IsA("TextLabel") then Label = Settings:FindFirstChild("Experiment17Info") end
    if not Label or not Label:IsA("TextLabel") then
        Label = Instance.new("TextLabel")
        Label.Name = Existing and "Experiment17Info" or "Info"
        Label.Parent = Settings
    end
    Label:SetAttribute("Experiment17Owned", true)
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0.699999988, 0, -0.0399999991, 0)
    Label.Size = UDim2.new(1, 0, 0.100000001, 0)
    Label.ZIndex = 2205

    Label.Font = Enum.Font.Oswald
    Label.Text = "Experiment17"
    Label.TextSize = 50
    Label.TextScaled = false
    Label.TextColor3 = Color3.new(1, 1, 1)
    Label.TextStrokeTransparency = 0.35
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextYAlignment = Enum.TextYAlignment.Center
    ExperimentInfoLabel = Label
end

task.defer(CR4.EnsureExperimentInfoLabel)
PGForInfo = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)
if PGForInfo then
    CR4.TrackConnection(PGForInfo.DescendantAdded:Connect(function(Object)
        if Object.Name == "Settings" or Object.Name == "MainUI" then task.defer(CR4.EnsureExperimentInfoLabel) end
    end))
end
