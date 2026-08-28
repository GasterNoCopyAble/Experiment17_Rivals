-- Experiment 17 | Rivals | XRay.lua
-- Physical logical module. Loaded in the shared Loader.lua environment.

--==================================================
-- X-RAY
--==================================================

DecorNames = {
    Painting_Small = true, Painting_Big = true, Painting_VeryBig = true,
    Typewriter = true, Potted_Plant = true, Grandfather_Clock = true,
    Luggage = true, Regal_Chair = true, Regal_Couch = true,
    Luggage_Cart = true, Bookcase = true, LightStand = true,
    BookshelfObstruction = true, Modular_Bookshelf = true,
}

OriginalXRayTransparency = setmetatable({}, { __mode = "k" })

function CR4.RestoreXRayPart(Part)
    local Original = OriginalXRayTransparency[Part]
    if Original == nil then return end
    if Part and Part.Parent then pcall(function() Part.LocalTransparencyModifier = Original end) end
    OriginalXRayTransparency[Part] = nil
end

RestoreXRayForTarget = function(Target)
    if not Target then return end
    if Target:IsA("BasePart") then CR4.RestoreXRayPart(Target) end
    for _, Object in ipairs(Target:GetDescendants()) do
        if Object:IsA("BasePart") then CR4.RestoreXRayPart(Object) end
    end
end

function CR4.ApplyXRayPart(Part)
    if not Part or not Part:IsA("BasePart") or not Part:IsDescendantOf(CurrentRooms) then return end
    if ProtectedESPParts[Part] then CR4.RestoreXRayPart(Part); return end
    if OriginalXRayTransparency[Part] == nil then OriginalXRayTransparency[Part] = Part.LocalTransparencyModifier end
    Part.LocalTransparencyModifier = State.XRayTransparency
end

function CR4.FindDecorRoot(Object)
    return CR4.FindAncestorFromSet(Object, DecorNames, CurrentRooms)
end

function CR4.ApplyXRayRoot(Root)
    if not Root then return end
    if Root:IsA("BasePart") then CR4.ApplyXRayPart(Root) end
    for _, Object in ipairs(Root:GetDescendants()) do
        if Object:IsA("BasePart") then CR4.ApplyXRayPart(Object) end
    end
end

function CR4.ProcessXRayObject(Object)
    if not State.XRay then return end
    if State.XRayMode == "Whole Map" then
        if Object:IsA("BasePart") then CR4.ApplyXRayPart(Object) end
    else
        local Root = CR4.FindDecorRoot(Object)
        if Root then CR4.ApplyXRayRoot(Root) end
    end
end

function CR4.RestoreXRay()
    for Part in pairs(OriginalXRayTransparency) do CR4.RestoreXRayPart(Part) end
end

XRayGeneration = 0
function CR4.ScanXRayAsync()
    if not State.XRay then return end
    XRayGeneration += 1
    local Generation = XRayGeneration
    task.spawn(function()
        local ProcessedDecor = {}
        for _, Room in ipairs(CurrentRooms:GetChildren()) do
            if Generation ~= XRayGeneration or not State.XRay then return end
            local Objects = Room:GetDescendants()
            for Index, Object in ipairs(Objects) do
                if State.XRayMode == "Whole Map" then
                    if Object:IsA("BasePart") then CR4.ApplyXRayPart(Object) end
                else
                    local Root = CR4.FindDecorRoot(Object)
                    if Root and not ProcessedDecor[Root] then
                        ProcessedDecor[Root] = true
                        CR4.ApplyXRayRoot(Root)
                    end
                end
                if Index % 200 == 0 then task.wait() end
            end
            task.wait()
        end
    end)
end

RefreshXRay = function()
    XRayGeneration += 1
    CR4.RestoreXRay()
    CR4.ScanXRayAsync()
end
