-- Experiment 17 | Rivals | Visuals.lua
-- Physical logical module; compiled independently by Loader.lua.

--========================================================
-- SPHERICAL PARTICLES
--========================================================

ParticleTextures = {
    Sparkles = "rbxasset://textures/particles/sparkles_main.dds",
    Smoke = "rbxasset://textures/particles/smoke_main.dds",
    Soft = "rbxasset://textures/particles/sparkles_main.dds",
    Fireflies = "rbxasset://textures/particles/sparkles_main.dds"
}

function DestroyParticles()
    ParticleEmitter = nil

    if ParticleSphere then
        ParticleSphere:Destroy()
        ParticleSphere = nil
    end
end

function UpdateParticles()
    if not Toggles.Particles.Value then
        DestroyParticles()
        return
    end

    local root = GetRoot()

    if not root then
        return
    end

    if not ParticleSphere or not ParticleSphere.Parent then
        DestroyParticles()

        ParticleSphere = Instance.new("Part")
        ParticleSphere.Name = "Experiment17ParticleSphere"
        ParticleSphere.Shape = Enum.PartType.Ball
        ParticleSphere.Transparency = 1
        ParticleSphere.CanCollide = false
        ParticleSphere.CanTouch = false
        ParticleSphere.CanQuery = false
        ParticleSphere.Massless = true
        ParticleSphere.CFrame = root.CFrame
        ParticleSphere.Parent = Workspace

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = ParticleSphere
        weld.Part1 = root
        weld.Parent = ParticleSphere

        ParticleEmitter = Instance.new("ParticleEmitter")
        ParticleEmitter.Name = "Experiment17ParticleEmitter"
        ParticleEmitter.Parent = ParticleSphere
        ParticleEmitter.SpreadAngle = Vector2.new(360, 360)
        ParticleEmitter.Rotation = NumberRange.new(0, 360)
        ParticleEmitter.RotSpeed = NumberRange.new(-180, 180)
        ParticleEmitter.LightEmission = 1
        ParticleEmitter.LightInfluence = 0

        pcall(function()
            ParticleEmitter.Shape = Enum.ParticleEmitterShape.Sphere
            ParticleEmitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
            ParticleEmitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
        end)
    end

    local radius = Options.ParticleRadius.Value

    ParticleSphere.Size = Vector3.new(
        radius * 2,
        radius * 2,
        radius * 2
    )

    ParticleEmitter.Enabled = true
    ParticleEmitter.Rate = Options.ParticleAmount.Value
    ParticleEmitter.Color = ColorSequence.new(Options.ParticleColor.Value)

    local particleType = Options.ParticleType.Value

    if particleType == "Custom" then
        local texture = tostring(Options.ParticleTexture.Value or "")

        if tonumber(texture) then
            texture = "rbxassetid://" .. texture
        end

        if texture ~= "" then
            ParticleEmitter.Texture = texture
        end
    else
        ParticleEmitter.Texture = ParticleTextures[particleType]
    end

    ParticleEmitter.Size = NumberSequence.new(Options.ParticleSize.Value)
    ParticleEmitter.Speed = NumberRange.new(
        Options.ParticleSpeed.Value * 0.7,
        Options.ParticleSpeed.Value
    )
    ParticleEmitter.Lifetime = NumberRange.new(
        math.max(0.05, Options.ParticleLifetime.Value * 0.8),
        Options.ParticleLifetime.Value
    )

    pcall(function()
        if Options.ParticleRegion.Value == "Surface" then
            ParticleEmitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
        else
            ParticleEmitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
        end
    end)

    if particleType == "Smoke" then
        ParticleEmitter.Acceleration = Vector3.new(0, 3, 0)
        ParticleEmitter.LightEmission = 0
    elseif particleType == "Soft" then
        ParticleEmitter.Acceleration = Vector3.new(0, 1, 0)
        ParticleEmitter.LightEmission = 0.35
    else
        ParticleEmitter.Acceleration = Vector3.zero
        ParticleEmitter.LightEmission = 1
    end
end

--========================================================
-- X-RAY
--========================================================

function IsCharacterPart(part)
    local model = part:FindFirstAncestorOfClass("Model")
    return model and model:FindFirstChildOfClass("Humanoid")
end

function ApplyXRayPart(part)
    if not part:IsA("BasePart") or IsCharacterPart(part) then
        return
    end

    if XRayCache[part] == nil then
        XRayCache[part] = part.LocalTransparencyModifier
    end

    part.LocalTransparencyModifier = Options.XRayTransparency.Value
end

function EnableXRay()
    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("BasePart") then
            ApplyXRayPart(object)
        end
    end
end

function DisableXRay()
    for part, oldValue in pairs(XRayCache) do
        if part and part.Parent then
            pcall(function()
                part.LocalTransparencyModifier = oldValue
            end)
        end
    end

    table.clear(XRayCache)
end

--========================================================
-- GRAPHICS
--========================================================

function ClearVisualEffects()
    for _, effect in ipairs(VisualEffects) do
        if effect and effect.Parent then
            effect:Destroy()
        end
    end

    table.clear(VisualEffects)
end

function NewEffect(class)
    local object = Instance.new(class)
    object.Name = "Experiment17Visual"
    object.Parent = Lighting

    table.insert(VisualEffects, object)
    return object
end

function RestoreGraphics()
    ClearVisualEffects()

    Lighting.Brightness = OriginalLighting.Brightness
    Lighting.ClockTime = OriginalLighting.ClockTime
    Lighting.ExposureCompensation = OriginalLighting.Exposure
    Lighting.Ambient = OriginalLighting.Ambient
    Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    Lighting.FogColor = OriginalLighting.FogColor
    Lighting.FogStart = OriginalLighting.FogStart
    Lighting.FogEnd = OriginalLighting.FogEnd
    Lighting.GlobalShadows = OriginalLighting.Shadows
    Lighting.ShadowSoftness = OriginalLighting.ShadowSoftness
end

function ApplyGraphics()
    RestoreGraphics()

    local preset = Options.GraphicsPreset.Value

    if preset == "Default" then
        return
    end

    local atmosphere = NewEffect("Atmosphere")
    local color = NewEffect("ColorCorrectionEffect")
    local bloom = NewEffect("BloomEffect")

    if preset == "Realistic" then
        Lighting.ClockTime = 15.5
        Lighting.Brightness = 2.5
        Lighting.ExposureCompensation = 0.1
        Lighting.GlobalShadows = true
        Lighting.ShadowSoftness = 0.25

        atmosphere.Density = 0.28
        atmosphere.Offset = 0.1
        atmosphere.Color = Color3.fromRGB(210, 225, 255)
        atmosphere.Decay = Color3.fromRGB(120, 135, 150)
        atmosphere.Haze = 1

        color.Contrast = 0.08
        color.Saturation = 0.05

        bloom.Intensity = 0.2
        bloom.Size = 24
        bloom.Threshold = 1.8
    elseif preset == "Horror" then
        Lighting.ClockTime = 1.5
        Lighting.Brightness = 0.8
        Lighting.ExposureCompensation = -0.8
        Lighting.Ambient = Color3.fromRGB(20, 15, 20)
        Lighting.OutdoorAmbient = Color3.fromRGB(25, 20, 30)
        Lighting.FogColor = Color3.fromRGB(30, 20, 25)
        Lighting.FogStart = 20
        Lighting.FogEnd = 300

        atmosphere.Density = 0.55
        atmosphere.Offset = 0.15
        atmosphere.Color = Color3.fromRGB(65, 55, 65)
        atmosphere.Decay = Color3.fromRGB(20, 5, 10)
        atmosphere.Haze = 3

        color.TintColor = Color3.fromRGB(190, 170, 180)
        color.Contrast = 0.3
        color.Saturation = -0.65
        color.Brightness = -0.08

        bloom.Intensity = 0.1
        bloom.Threshold = 2
    elseif preset == "Surreal" then
        Lighting.ClockTime = 18.5
        Lighting.Brightness = 3
        Lighting.ExposureCompensation = 0.25
        Lighting.Ambient = Color3.fromRGB(95, 45, 130)
        Lighting.OutdoorAmbient = Color3.fromRGB(80, 90, 180)

        atmosphere.Density = 0.4
        atmosphere.Offset = 0.2
        atmosphere.Color = Color3.fromRGB(185, 120, 255)
        atmosphere.Decay = Color3.fromRGB(80, 30, 160)
        atmosphere.Glare = 0.8
        atmosphere.Haze = 2

        color.TintColor = Color3.fromRGB(225, 185, 255)
        color.Contrast = 0.18
        color.Saturation = 0.75

        bloom.Intensity = 1.2
        bloom.Size = 50
        bloom.Threshold = 0.8
    elseif preset == "Dream" then
        Lighting.ClockTime = 7.5
        Lighting.Brightness = 3
        Lighting.ExposureCompensation = 0.4
        Lighting.Ambient = Color3.fromRGB(170, 160, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 190, 220)

        atmosphere.Density = 0.35
        atmosphere.Color = Color3.fromRGB(255, 210, 240)
        atmosphere.Decay = Color3.fromRGB(150, 170, 255)
        atmosphere.Glare = 0.5
        atmosphere.Haze = 1.5

        color.TintColor = Color3.fromRGB(255, 225, 245)
        color.Saturation = 0.25
        color.Contrast = -0.05

        bloom.Intensity = 0.8
        bloom.Size = 48
        bloom.Threshold = 1
    elseif preset == "Neon Night" then
        Lighting.ClockTime = 0
        Lighting.Brightness = 1.5
        Lighting.ExposureCompensation = -0.15
        Lighting.Ambient = Color3.fromRGB(15, 10, 45)
        Lighting.OutdoorAmbient = Color3.fromRGB(25, 15, 70)

        atmosphere.Density = 0.35
        atmosphere.Color = Color3.fromRGB(35, 25, 100)
        atmosphere.Decay = Color3.fromRGB(120, 15, 150)
        atmosphere.Glare = 0.3
        atmosphere.Haze = 1.2

        color.TintColor = Color3.fromRGB(180, 150, 255)
        color.Saturation = 0.65
        color.Contrast = 0.25

        bloom.Intensity = 1.4
        bloom.Size = 45
        bloom.Threshold = 0.5
    end
end

--========================================================
-- FPS BOOST
--========================================================

function CacheProperty(object, property)
    FPSCache[object] = FPSCache[object] or {}

    if FPSCache[object][property] == nil then
        local ok, value = pcall(function()
            return object[property]
        end)

        if ok then
            FPSCache[object][property] = value
        end
    end
end

function ApplyFPSObject(object)
    if object.Name:find("Experiment17") then
        return
    end

    if object:IsA("ParticleEmitter")
        or object:IsA("Trail")
        or object:IsA("Beam")
        or object:IsA("Smoke")
        or object:IsA("Fire")
        or object:IsA("Sparkles")
        or object:IsA("PostEffect") then

        CacheProperty(object, "Enabled")
        object.Enabled = false
        return
    end

    if object:IsA("BasePart") then
        CacheProperty(object, "CastShadow")
        object.CastShadow = false

        if Options.FPSMode.Value == "Aggressive" then
            CacheProperty(object, "Material")
            CacheProperty(object, "Reflectance")

            object.Material = Enum.Material.Plastic
            object.Reflectance = 0
        end
    elseif Options.FPSMode.Value == "Aggressive"
        and (object:IsA("Decal") or object:IsA("Texture")) then

        CacheProperty(object, "Transparency")
        object.Transparency = 1
    end
end

function EnableFPS()
    for _, object in ipairs(game:GetDescendants()) do
        ApplyFPSObject(object)
    end

    CacheProperty(Lighting, "GlobalShadows")
    Lighting.GlobalShadows = false
end

function DisableFPS()
    for object, properties in pairs(FPSCache) do
        if object and object.Parent then
            for property, value in pairs(properties) do
                pcall(function()
                    object[property] = value
                end)
            end
        end
    end

    table.clear(FPSCache)
end
