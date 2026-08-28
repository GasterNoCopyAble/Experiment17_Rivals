-- Experiment 17 | Rivals | Visuals.lua
-- Physical logical module. Loaded in the shared Loader.lua environment.

--==================================================
-- VISUALS / GRAPHICS / PATH
--==================================================

OriginalLighting = {
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ClockTime = Lighting.ClockTime,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,

    ExposureCompensation = Lighting.ExposureCompensation,
}

LowGFXOriginals = setmetatable({}, { __mode = "k" })
ShadowOriginals = setmetatable({}, { __mode = "k" })
PostEffectOriginals = setmetatable({}, { __mode = "k" })
AtmosphereOriginals = setmetatable({}, { __mode = "k" })
VisualTrackedPost = setmetatable({}, { __mode = "k" })
VisualTrackedAtmosphere = setmetatable({}, { __mode = "k" })
VisualEffectWatchers = setmetatable({}, { __mode = "k" })
StyleEffects = {}
VisualApplyGuard = false
StyleDirty = true
OriginalQualityLevel = nil
TerrainOriginal = nil

function CR4.IsParticleObject(Object)
    return Object:IsA("ParticleEmitter") or Object:IsA("Trail") or Object:IsA("Beam")
        or Object:IsA("Smoke") or Object:IsA("Fire") or Object:IsA("Sparkles")
end

function CR4.IsLightObject(Object)
    return Object:IsA("PointLight") or Object:IsA("SpotLight") or Object:IsA("SurfaceLight")
end

function CR4.IsPostEffect(Object)
    return Object:IsA("BlurEffect") or Object:IsA("BloomEffect")
        or Object:IsA("ColorCorrectionEffect") or Object:IsA("DepthOfFieldEffect")
        or Object:IsA("SunRaysEffect")
end

function CR4.RememberPostEffect(Object)
    if PostEffectOriginals[Object] == nil then PostEffectOriginals[Object] = Object.Enabled end
    VisualTrackedPost[Object] = true
    if not VisualEffectWatchers[Object] then
        local Connection = Object:GetPropertyChangedSignal("Enabled"):Connect(function()
            if IsUnloading or not Object.Parent or Object.Name:match("^LinoriaStyle_") then return end
            if State.NoPostEffects or State.LowGFX then
                task.defer(function()
                    if Object and Object.Parent and (State.NoPostEffects or State.LowGFX) then pcall(function() Object.Enabled = false end) end
                end)
            end
        end)
        VisualEffectWatchers[Object] = { Connection }
        CR4.TrackConnection(Connection)
    end
end

function CR4.RememberAtmosphere(Object)
    if not AtmosphereOriginals[Object] then
        AtmosphereOriginals[Object] = {
            Density = Object.Density, Haze = Object.Haze, Glare = Object.Glare,
            Offset = Object.Offset, Color = Object.Color, Decay = Object.Decay,
        }
    end
    VisualTrackedAtmosphere[Object] = true
    if not VisualEffectWatchers[Object] then
        local Connections = {}
        for _, Property in ipairs({ "Density", "Haze", "Glare" }) do
            local Connection = Object:GetPropertyChangedSignal(Property):Connect(function()
                if IsUnloading or not Object.Parent or not State.NoFog then return end
                task.defer(function()
                    if Object and Object.Parent and State.NoFog then
                        pcall(function() Object.Density = 0; Object.Haze = 0; Object.Glare = 0 end)
                    end
                end)
            end)
            table.insert(Connections, Connection)
            CR4.TrackConnection(Connection)
        end
        VisualEffectWatchers[Object] = Connections
    end
end

function CR4.RegisterLightingObject(Object)
    if CR4.IsPostEffect(Object) then CR4.RememberPostEffect(Object) end
    if Object:IsA("Atmosphere") then CR4.RememberAtmosphere(Object) end
end

for _, Object in ipairs(Lighting:GetDescendants()) do CR4.RegisterLightingObject(Object) end
if Camera then
    for _, Object in ipairs(Camera:GetDescendants()) do CR4.RegisterLightingObject(Object) end
end

function CR4.ApplyLowGFXObject(Object)
    if not State.LowGFX or not Object or not Object.Parent then return end

    if Object:IsA("BasePart") then
        if not LowGFXOriginals[Object] then
            LowGFXOriginals[Object] = {
                Type = "Part", Material = Object.Material, MaterialVariant = Object.MaterialVariant,
                Reflectance = Object.Reflectance, CastShadow = Object.CastShadow,
                RenderFidelity = Object:IsA("MeshPart") and Object.RenderFidelity or nil,
                TextureID = Object:IsA("MeshPart") and Object.TextureID or nil,
            }
        end
        pcall(function()
            Object.Material = Enum.Material.Plastic
            Object.MaterialVariant = ""
            Object.Reflectance = 0
            Object.CastShadow = false
            if Object:IsA("MeshPart") then
                Object.RenderFidelity = Enum.RenderFidelity.Performance
                Object.TextureID = ""
            end
        end)
    elseif Object:IsA("SpecialMesh") then
        if not LowGFXOriginals[Object] then LowGFXOriginals[Object] = { Type = "SpecialMesh", TextureId = Object.TextureId } end
        pcall(function() Object.TextureId = "" end)
    elseif Object:IsA("SurfaceAppearance") then
        if not LowGFXOriginals[Object] then
            LowGFXOriginals[Object] = {
                Type = "SurfaceAppearance", ColorMap = Object.ColorMap, NormalMap = Object.NormalMap,
                RoughnessMap = Object.RoughnessMap, MetalnessMap = Object.MetalnessMap,
            }
        end
        pcall(function()
            Object.ColorMap = ""; Object.NormalMap = ""; Object.RoughnessMap = ""; Object.MetalnessMap = ""
        end)
    elseif CR4.IsParticleObject(Object) or CR4.IsLightObject(Object) then
        if not LowGFXOriginals[Object] then LowGFXOriginals[Object] = { Type = "Enabled", Enabled = Object.Enabled } end
        pcall(function() Object.Enabled = false end)
    elseif Object:IsA("Decal") or Object:IsA("Texture") then
        if not LowGFXOriginals[Object] then LowGFXOriginals[Object] = { Type = "Transparency", Transparency = Object.Transparency } end
        pcall(function() Object.Transparency = 1 end)
    end
end

function CR4.ApplyNoShadowObject(Object)
    if not State.NoShadows or not Object:IsA("BasePart") then return end
    if ShadowOriginals[Object] == nil then ShadowOriginals[Object] = Object.CastShadow end
    pcall(function() Object.CastShadow = false end)
end

function CR4.ScanVisualObjectsAsync()
    task.spawn(function()
        local Objects = workspace:GetDescendants()
        for Index, Object in ipairs(Objects) do
            if not CR4.IsPlayerCharacterObject(Object)
                and not Object:IsDescendantOf(HighlightFolder)
                and (not PathFolder or not Object:IsDescendantOf(PathFolder)) then
                if State.LowGFX then CR4.ApplyLowGFXObject(Object) end
                if State.NoShadows then CR4.ApplyNoShadowObject(Object) end
            end
            if Index % 180 == 0 then task.wait() end
        end
    end)
end

function CR4.ApplyLowGFXGlobal()
    if not State.LowGFX then return end
    pcall(function()
        local Rendering = settings().Rendering
        if OriginalQualityLevel == nil then OriginalQualityLevel = Rendering.QualityLevel end
        Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)

    if Terrain then
        if not TerrainOriginal then
            TerrainOriginal = {
                Decoration = Terrain.Decoration,
                WaterWaveSize = Terrain.WaterWaveSize,
                WaterWaveSpeed = Terrain.WaterWaveSpeed,
                WaterReflectance = Terrain.WaterReflectance,
            }
        end
        pcall(function()
            Terrain.Decoration = false
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
        end)
    end
    CR4.ScanVisualObjectsAsync()
end

function CR4.RestoreLowGFX()
    for Object, Original in pairs(LowGFXOriginals) do
        if Object and Object.Parent then
            pcall(function()
                if Original.Type == "Part" then
                    Object.Material = Original.Material
                    Object.MaterialVariant = Original.MaterialVariant or ""
                    Object.Reflectance = Original.Reflectance
                    Object.CastShadow = Original.CastShadow
                    if Object:IsA("MeshPart") then
                        if Original.RenderFidelity then Object.RenderFidelity = Original.RenderFidelity end
                        if Original.TextureID ~= nil then Object.TextureID = Original.TextureID end
                    end
                elseif Original.Type == "SpecialMesh" then
                    Object.TextureId = Original.TextureId
                elseif Original.Type == "SurfaceAppearance" then
                    Object.ColorMap = Original.ColorMap
                    Object.NormalMap = Original.NormalMap
                    Object.RoughnessMap = Original.RoughnessMap
                    Object.MetalnessMap = Original.MetalnessMap
                elseif Original.Type == "Enabled" then
                    Object.Enabled = Original.Enabled
                elseif Original.Type == "Transparency" then
                    Object.Transparency = Original.Transparency
                end
            end)
        end
        LowGFXOriginals[Object] = nil
    end
    if OriginalQualityLevel ~= nil then
        pcall(function() settings().Rendering.QualityLevel = OriginalQualityLevel end)
        OriginalQualityLevel = nil
    end
    if Terrain and TerrainOriginal then
        pcall(function()
            Terrain.Decoration = TerrainOriginal.Decoration
            Terrain.WaterWaveSize = TerrainOriginal.WaterWaveSize
            Terrain.WaterWaveSpeed = TerrainOriginal.WaterWaveSpeed
            Terrain.WaterReflectance = TerrainOriginal.WaterReflectance
        end)
        TerrainOriginal = nil
    end
end

function CR4.RestoreShadows()
    for Part, Value in pairs(ShadowOriginals) do
        if Part and Part.Parent then pcall(function() Part.CastShadow = Value end) end
        ShadowOriginals[Part] = nil
    end
    Lighting.GlobalShadows = OriginalLighting.GlobalShadows
end

function CR4.GetStyleEffect(ClassName, Name)
    local Existing = StyleEffects[Name]
    if Existing and Existing.Parent then return Existing end
    Existing = Lighting:FindFirstChild(Name)
    if not Existing or not Existing:IsA(ClassName) then
        CR4.SafeDestroy(Existing)
        Existing = Instance.new(ClassName)
        Existing.Name = Name
        Existing.Parent = Lighting
    end
    StyleEffects[Name] = Existing
    return Existing
end

StylePresets = {
    Beautiful = { Brightness = 2.2, Exposure = 0.12, Ambient = Color3.fromRGB(105,105,120), Outdoor = Color3.fromRGB(135,135,155), Tint = Color3.fromRGB(255,245,235), Contrast = 0.12, Saturation = 0.12, Bloom = 0.45, Sun = 0.08, Atmosphere = 0.18 },
    Fantasy = { Brightness = 2.4, Exposure = 0.18, Ambient = Color3.fromRGB(110,90,145), Outdoor = Color3.fromRGB(145,125,175), Tint = Color3.fromRGB(235,220,255), Contrast = 0.08, Saturation = 0.28, Bloom = 0.70, Sun = 0.12, Atmosphere = 0.22 },
    Horror = { Brightness = 1.3, Exposure = -0.25, Ambient = Color3.fromRGB(45,45,55), Outdoor = Color3.fromRGB(55,60,70), Tint = Color3.fromRGB(185,205,210), Contrast = 0.30, Saturation = -0.35, Bloom = 0.15, Sun = 0.02, Atmosphere = 0.30 },
    Realistic = { Brightness = 2.0, Exposure = 0.0, Ambient = Color3.fromRGB(90,90,95), Outdoor = Color3.fromRGB(125,125,130), Tint = Color3.fromRGB(255,250,245), Contrast = 0.16, Saturation = -0.03, Bloom = 0.20, Sun = 0.05, Atmosphere = 0.16 },
    Retro = { Brightness = 2.0, Exposure = 0.05, Ambient = Color3.fromRGB(115,95,80), Outdoor = Color3.fromRGB(150,125,95), Tint = Color3.fromRGB(255,220,175), Contrast = 0.22, Saturation = -0.18, Bloom = 0.10, Sun = 0.02, Atmosphere = 0.10 },
    Cinematic = { Brightness = 1.8, Exposure = -0.05, Ambient = Color3.fromRGB(75,80,95), Outdoor = Color3.fromRGB(105,110,125), Tint = Color3.fromRGB(225,235,255), Contrast = 0.28, Saturation = -0.08, Bloom = 0.32, Sun = 0.06, Atmosphere = 0.20, DOF = true },
    Dream = { Brightness = 2.5, Exposure = 0.25, Ambient = Color3.fromRGB(135,115,150), Outdoor = Color3.fromRGB(165,145,180), Tint = Color3.fromRGB(255,225,250), Contrast = -0.05, Saturation = 0.20, Bloom = 0.85, Sun = 0.10, Atmosphere = 0.25 },
    Cold = { Brightness = 2.0, Exposure = -0.02, Ambient = Color3.fromRGB(70,90,120), Outdoor = Color3.fromRGB(105,130,165), Tint = Color3.fromRGB(205,225,255), Contrast = 0.18, Saturation = -0.08, Bloom = 0.20, Sun = 0.04, Atmosphere = 0.18 },
    Warm = { Brightness = 2.1, Exposure = 0.10, Ambient = Color3.fromRGB(125,95,70), Outdoor = Color3.fromRGB(165,125,90), Tint = Color3.fromRGB(255,220,180), Contrast = 0.14, Saturation = 0.10, Bloom = 0.28, Sun = 0.08, Atmosphere = 0.14 },
    Noir = { Brightness = 1.7, Exposure = -0.12, Ambient = Color3.fromRGB(65,65,65), Outdoor = Color3.fromRGB(95,95,95), Tint = Color3.fromRGB(225,225,225), Contrast = 0.38, Saturation = -1.0, Bloom = 0.08, Sun = 0.02, Atmosphere = 0.12 },
}

function CR4.ClearStyleEffects()
    for _, Object in pairs(StyleEffects) do CR4.SafeDestroy(Object) end
    StyleEffects = {}
end

function CR4.ApplyVisualStyle()
    local Preset = StylePresets[State.VisualStyle]
    if not Preset then
        CR4.ClearStyleEffects()
        if not State.Fullbright then
            Lighting.Brightness = OriginalLighting.Brightness
            Lighting.Ambient = OriginalLighting.Ambient
            Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
            Lighting.ExposureCompensation = OriginalLighting.ExposureCompensation
        end
        return
    end

    Lighting.Brightness = Preset.Brightness
    Lighting.Ambient = Preset.Ambient
    Lighting.OutdoorAmbient = Preset.Outdoor
    Lighting.ExposureCompensation = Preset.Exposure

    local CC = CR4.GetStyleEffect("ColorCorrectionEffect", "LinoriaStyle_Color")
    CC.TintColor = Preset.Tint
    CC.Contrast = Preset.Contrast
    CC.Saturation = Preset.Saturation
    CC.Brightness = 0
    CC.Enabled = not State.NoPostEffects and not State.LowGFX

    local Bloom = CR4.GetStyleEffect("BloomEffect", "LinoriaStyle_Bloom")
    Bloom.Intensity = Preset.Bloom
    Bloom.Size = 32
    Bloom.Threshold = 1.1
    Bloom.Enabled = not State.NoPostEffects and not State.LowGFX

    local Sun = CR4.GetStyleEffect("SunRaysEffect", "LinoriaStyle_Sun")
    Sun.Intensity = Preset.Sun
    Sun.Spread = 0.8
    Sun.Enabled = not State.NoPostEffects and not State.LowGFX

    local DOF = CR4.GetStyleEffect("DepthOfFieldEffect", "LinoriaStyle_DOF")
    DOF.FarIntensity = Preset.DOF and 0.08 or 0
    DOF.NearIntensity = Preset.DOF and 0.06 or 0
    DOF.FocusDistance = 20
    DOF.InFocusRadius = 35
    DOF.Enabled = Preset.DOF and not State.NoPostEffects and not State.LowGFX

    local Atmosphere = CR4.GetStyleEffect("Atmosphere", "LinoriaStyle_Atmosphere")
    Atmosphere.Density = State.NoFog and 0 or Preset.Atmosphere
    Atmosphere.Haze = State.NoFog and 0 or 1
    Atmosphere.Glare = 0
    Atmosphere.Offset = 0
end

function CR4.EnforceVisualState()
    if VisualApplyGuard then return end
    VisualApplyGuard = true
    pcall(function()
        if State.VisualStyle ~= "Off" and StyleDirty then
            CR4.ApplyVisualStyle()
            StyleDirty = false
        end
        if State.Fullbright then
            Lighting.Brightness = 3
            Lighting.Ambient = Color3.new(1,1,1)
            Lighting.OutdoorAmbient = Color3.new(1,1,1)
            Lighting.ClockTime = 14
            Lighting.ExposureCompensation = 0.15
        end
        if State.NoFog then
            Lighting.FogStart = 0
            Lighting.FogEnd = 1000000
            for Object in pairs(VisualTrackedAtmosphere) do
                if Object and Object.Parent then Object.Density=0; Object.Haze=0; Object.Glare=0 end
            end
        end
        if State.NoPostEffects or State.LowGFX then
            for Object in pairs(VisualTrackedPost) do
                if Object and Object.Parent and not Object.Name:match("^LinoriaStyle_") then Object.Enabled=false end
            end
        end
        if State.NoShadows or State.LowGFX then Lighting.GlobalShadows=false end
    end)
    VisualApplyGuard = false
end

for _, Property in ipairs({ "Brightness", "Ambient", "OutdoorAmbient", "ClockTime", "ExposureCompensation", "FogStart", "FogEnd", "GlobalShadows" }) do
    CR4.TrackConnection(Lighting:GetPropertyChangedSignal(Property):Connect(function()
        if IsUnloading then return end
        if State.Fullbright or State.NoFog or State.NoShadows or State.LowGFX or State.VisualStyle ~= "Off" then
            task.defer(CR4.EnforceVisualState)
        end
    end))
end

function CR4.RestorePostEffects()
    for Object, Enabled in pairs(PostEffectOriginals) do
        if Object and Object.Parent and not Object.Name:match("^LinoriaStyle_") then
            pcall(function() Object.Enabled = Enabled end)
        end
    end
end

function CR4.RestoreAtmosphere()

    for Object, Original in pairs(AtmosphereOriginals) do
        if Object and Object.Parent and not Object.Name:match("^LinoriaStyle_") then
            pcall(function()
                Object.Density = Original.Density
                Object.Haze = Original.Haze
                Object.Glare = Original.Glare
                Object.Offset = Original.Offset
                Object.Color = Original.Color
                Object.Decay = Original.Decay
            end)
        end
    end
end

function CR4.RestoreVisuals()
    CR4.RestoreLowGFX()
    CR4.RestoreShadows()
    CR4.RestorePostEffects()
    CR4.RestoreAtmosphere()
    CR4.ClearStyleEffects()
    Lighting.Brightness = OriginalLighting.Brightness
    Lighting.Ambient = OriginalLighting.Ambient
    Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    Lighting.ClockTime = OriginalLighting.ClockTime
    Lighting.FogStart = OriginalLighting.FogStart
    Lighting.FogEnd = OriginalLighting.FogEnd
    Lighting.GlobalShadows = OriginalLighting.GlobalShadows
    Lighting.ExposureCompensation = OriginalLighting.ExposureCompensation
end

-- Smart path
PathFolder = Instance.new("Folder")
PathFolder.Name = "LinoriaSmartPath"
PathFolder.Parent = workspace
PathLastUpdate = 0
PathLastRootPosition = nil
PathBusy = false

function CR4.ClearPathVisual()
    for _, Object in ipairs(PathFolder:GetChildren()) do Object:Destroy() end
end

function CR4.GetRoomNumberFromObject(Object)
    local Current = Object
    while Current and Current ~= CurrentRooms do
        if Current.Parent == CurrentRooms then return tonumber(Current.Name) end
        Current = Current.Parent
    end
    return nil
end

function CR4.GetPathDestination(Root)
    local Best, BestScore = nil, math.huge
    local HighestRoom = -1
    local function AllowedCategory(Cat)
        if State.PathTargetMode == "Progress Door" then return Cat == "Doors" or Cat == "Chapter" or Cat == "DangerDoor" end
        if State.PathTargetMode == "Lever" then return Cat == "Levers" end
        if State.PathTargetMode == "Key / Lockpick" then return Cat == "Keys" or Cat == "Lockpicks" end
        if State.PathTargetMode == "Gold" then return Cat == "Gold" end
        if State.PathTargetMode == "Wardrobe" then return Cat == "Wardrobes" end
        if State.PathTargetMode == "Fuse / Breaker" then return Cat == "Fuses" or Cat == "Breakers" end
        if State.PathTargetMode == "Objective" then return Cat == "Objectives" or Cat == "Breakers" or Cat == "Chapter" or Cat == "Fuses" or Cat == "Levers" end
        if State.PathTargetMode == "Loot" then return Cat == "Gold" or Cat == "Keys" or Cat == "Lockpicks" or Cat == "Chests" or Cat == "Items" or Cat == "Lootables" end
        if State.PathTargetMode == "Nearest ESP" then return ESPCategories[Cat] and ESPCategories[Cat].Enabled end
        return false
    end
    for Target, Entry in pairs(ESPEntries) do
        if Target and Target.Parent and AllowedCategory(Entry.Category) then
            local Position = CR4.GetWorldPosition(Target)
            if Position then
                local Distance = (Position - Root.Position).Magnitude
                if Distance > 2.5 and Distance <= State.PathMaxDistance then
                    local RoomNumber = CR4.GetRoomNumberFromObject(Target) or -1
                    if State.PathTargetMode == "Progress Door" then HighestRoom = math.max(HighestRoom, RoomNumber)
                    elseif Distance < BestScore then Best, BestScore = Target, Distance end
                end
            end
        end
    end
    if State.PathTargetMode == "Progress Door" and HighestRoom >= 0 then
        for Target, Entry in pairs(ESPEntries) do
            if Target and Target.Parent and AllowedCategory(Entry.Category) and (CR4.GetRoomNumberFromObject(Target) or -1) == HighestRoom then
                local Position = CR4.GetWorldPosition(Target)
                if Position then
                    local Distance = (Position - Root.Position).Magnitude
                    if Distance > 2.5 and Distance <= State.PathMaxDistance and Distance < BestScore then Best, BestScore = Target, Distance end
                end
            end
        end
    end
    return Best
end

function CR4.DrawPath(Waypoints)
    CR4.ClearPathVisual()
    for Index = 1, #Waypoints - 1 do
        local A = Waypoints[Index].Position + Vector3.new(0, 0.15, 0)
        local B = Waypoints[Index + 1].Position + Vector3.new(0, 0.15, 0)
        local Delta = B - A
        local Length = Delta.Magnitude
        if Length > 0.05 then
            local Part = Instance.new("Part")
            Part.Name = "PathSegment"
            Part.Anchored = true
            Part.CanCollide = false
            Part.CanTouch = false
            Part.CanQuery = false
            Part.Material = Enum.Material.Neon
            Part.Color = State.PathColor
            Part.Transparency = 0.18
            Part.Size = Vector3.new(0.18, 0.08, Length)
            Part.CFrame = CFrame.lookAt((A + B) * 0.5, B)
            Part.Parent = PathFolder
        end
    end
end

function CR4.DrawDirectPath(A, B)
    CR4.DrawPath({ { Position = A }, { Position = B } })
end

function CR4.UpdateSmartPath(Force)
    if not State.SmartPath or PathBusy then return end
    local Character, Humanoid, Root = CR4.GetCharacter()
    if not Character or not Humanoid or Humanoid.Health <= 0 or not Root then return end
    local Now = os.clock()
    if not Force and Now - PathLastUpdate < State.PathRecompute then return end
    local Target = CR4.GetPathDestination(Root)
    local TargetPosition = Target and CR4.GetWorldPosition(Target)
    if not TargetPosition then return end
    PathLastUpdate = Now
    PathLastRootPosition = Root.Position
    local ToRoot = Root.Position - TargetPosition
    local Destination = TargetPosition
    if ToRoot.Magnitude > 0.1 then Destination = TargetPosition + ToRoot.Unit * math.min(2.5, ToRoot.Magnitude * 0.25) end
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = { Character, PathFolder, HighlightFolder }
    Params.IgnoreWater = true
    local Ray = workspace:Raycast(Root.Position, Destination - Root.Position, Params)
    if not Ray then CR4.DrawDirectPath(Root.Position, Destination) end

    PathBusy = true
    local StartPosition = Root.Position
    task.spawn(function()
        local Path = PathfindingService:CreatePath({ AgentRadius=1.6, AgentHeight=5, AgentCanJump=false, AgentCanClimb=true, WaypointSpacing=2.5 })
        local Success = pcall(function() Path:ComputeAsync(StartPosition, Destination) end)
        if State.SmartPath and Success and Path.Status == Enum.PathStatus.Success then
            local Waypoints = Path:GetWaypoints()
            if #Waypoints >= 2 then CR4.DrawPath(Waypoints) end
        end
        PathBusy = false
    end)
end
