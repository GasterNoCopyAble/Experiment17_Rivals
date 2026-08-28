-- Experiment 17 | Rivals | Prompts.lua
-- Physical logical module. Loaded in the shared Loader.lua environment.

--==================================================
-- PROXIMITY PROMPTS
--==================================================

OriginalPrompts = setmetatable({}, { __mode = "k" })
PromptRegistry = setmetatable({}, { __mode = "k" })
PromptWatchers = setmetatable({}, { __mode = "k" })
PromptApplyGuard = setmetatable({}, { __mode = "k" })

PromptTimes = {
    Door = 0.20,
    Hide = 0.20,
    Gold = 0.20,
    Key = 0.20,
    Lockpick = 0.20,
    Item = 0.20,
    Chest = 0.20,
    Drawer = 0.20,
    Objective = 0.20,
    Other = 0.20,
}

function CR4.RememberPrompt(Prompt)
    if not OriginalPrompts[Prompt] then
        OriginalPrompts[Prompt] = {
            MaxActivationDistance = Prompt.MaxActivationDistance,
            HoldDuration = Prompt.HoldDuration,
            RequiresLineOfSight = Prompt.RequiresLineOfSight,
            Exclusivity = Prompt.Exclusivity,
            Enabled = Prompt.Enabled,
        }
    end
    return OriginalPrompts[Prompt]
end

function CR4.GetPromptDistance(Prompt, OriginalDistance)
    if Prompt.Name == "UnlockPrompt" then
        return 17
    elseif Prompt.Name == "HidePrompt" then
        return 19
    elseif Prompt.Name == "LootPrompt" then
        return 16
    elseif Prompt.Name == "ActivateEventPrompt" then
        return 20
    elseif Prompt.Name == "ModulePrompt" then
        if CR4.HasAncestorNamed(Prompt, "Candle", CurrentRooms) then
            return 12
        end
        return 14
    end
    return math.max(OriginalDistance, OriginalDistance * 2)
end

function CR4.GetPromptKind(Prompt)
    if CR4.HasAncestorNamed(Prompt, "GoldPile", CurrentRooms) then return "Gold" end
    if CR4.HasAncestorNamed(Prompt, "Lockpick", CurrentRooms) then return "Lockpick" end

    if CR4.HasAncestorNamed(Prompt, "KeyObtain", CurrentRooms)
        or CR4.HasAncestorNamed(Prompt, "SkeletonKey", CurrentRooms)
        or CR4.HasAncestorNamed(Prompt, "ElectricalKeyObtain", CurrentRooms) then
        return "Key"
    end

    if Prompt.Name == "UnlockPrompt"
        or CR4.HasAncestorNamed(Prompt, "DoorNormal", CurrentRooms)
        or CR4.HasAncestorNamed(Prompt, "Wax_Door", CurrentRooms)
        or CR4.HasAncestorNamed(Prompt, "_RoomsDoorEntrance", CurrentRooms)
        or CR4.HasAncestorNamed(Prompt, "ElectricalDoor", CurrentRooms) then
        return "Door"
    end

    if Prompt.Name == "HidePrompt"
        or CR4.HasAncestorNamed(Prompt, "Wardrobe", CurrentRooms)
        or CR4.HasAncestorNamed(Prompt, "Bed", CurrentRooms)
        or CR4.HasAncestorNamed(Prompt, "Toolshed", CurrentRooms) then
        return "Hide"
    end

    if Prompt.Name == "ActivateEventPrompt"
        or CR4.HasAncestorNamed(Prompt, "LeverForGate", CurrentRooms)
        or CR4.HasAncestorNamed(Prompt, "ThingToOpen", CurrentRooms)
        or CR4.HasAncestorNamed(Prompt, "CuttableVines", CurrentRooms) then
        return "Objective"
    end

    if CR4.HasAncestorNamed(Prompt, "ChestBox", CurrentRooms)
        or CR4.HasAncestorNamed(Prompt, "ChestBoxLocked", CurrentRooms) then
        return "Chest"
    end

    if CR4.HasAncestorNamed(Prompt, "DrawerContainer", CurrentRooms)
        or CR4.HasAncestorNamed(Prompt, "Toolshed_Small", CurrentRooms) then
        return "Drawer"
    end

    if Prompt.Name == "ModulePrompt" or Prompt.Name == "LootPrompt" then return "Item" end
    return "Other"
end

function CR4.UpdatePrompt(Prompt)
    if not Prompt or not Prompt:IsA("ProximityPrompt") or PromptApplyGuard[Prompt] then return end

    local Original = CR4.RememberPrompt(Prompt)
    PromptApplyGuard[Prompt] = true

    pcall(function()
        Prompt.MaxActivationDistance = State.PromptExpander
            and CR4.GetPromptDistance(Prompt, Original.MaxActivationDistance)
            or Original.MaxActivationDistance

        local Kind = CR4.GetPromptKind(Prompt)
        Prompt.HoldDuration = State.FastPrompts
            and (PromptTimes[Kind] or PromptTimes.Other)
            or Original.HoldDuration

        Prompt.RequiresLineOfSight = State.PromptThroughWalls and false or Original.RequiresLineOfSight
        Prompt.Exclusivity = Original.Exclusivity

        local InPainting = false
        local Current = Prompt.Parent
        while Current and Current ~= CurrentRooms do
            if string.find(string.lower(Current.Name), "painting", 1, true) then
                InPainting = true
                break
            end
            Current = Current.Parent
        end
        if State.RemovePaintingPrompts and InPainting then
            Prompt.Enabled = false
        elseif Original.Enabled ~= nil then
            Prompt.Enabled = Original.Enabled
        end
    end)

    PromptApplyGuard[Prompt] = nil
end

function CR4.TrackPrompt(Prompt)
    if not Prompt or not Prompt:IsA("ProximityPrompt") then return end

    PromptRegistry[Prompt] = true
    CR4.RememberPrompt(Prompt)
    CR4.UpdatePrompt(Prompt)

    if PromptWatchers[Prompt] then return end

    local Connections = {}
    for _, Property in ipairs({ "MaxActivationDistance", "HoldDuration", "RequiresLineOfSight", "Exclusivity", "Enabled" }) do
        table.insert(Connections, Prompt:GetPropertyChangedSignal(Property):Connect(function()
            if PromptApplyGuard[Prompt] or IsUnloading then return end
            task.defer(CR4.UpdatePrompt, Prompt)
        end))
    end
    PromptWatchers[Prompt] = Connections
end

function CR4.ScanPrompts(Container)
    if Container:IsA("ProximityPrompt") then CR4.TrackPrompt(Container) end
    for _, Object in ipairs(Container:GetDescendants()) do
        if Object:IsA("ProximityPrompt") then CR4.TrackPrompt(Object) end
    end

end

function CR4.RestorePrompts()
    for Prompt, Original in pairs(OriginalPrompts) do
        if Prompt and Prompt.Parent then
            PromptApplyGuard[Prompt] = true
            pcall(function()
                Prompt.MaxActivationDistance = Original.MaxActivationDistance
                Prompt.HoldDuration = Original.HoldDuration
                Prompt.RequiresLineOfSight = Original.RequiresLineOfSight
                Prompt.Exclusivity = Original.Exclusivity
                if Original.Enabled ~= nil then Prompt.Enabled = Original.Enabled end
            end)
            PromptApplyGuard[Prompt] = nil
        end
    end
end
