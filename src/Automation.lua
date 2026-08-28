-- Experiment 17 | Rivals | Automation.lua
-- Physical logical module. Loaded in the shared Loader.lua environment.

--==================================================
-- AUTO PICKUP
--==================================================

LastPromptFire = setmetatable({}, { __mode = "k" })
AutoLootAccumulator = 0

function CR4.GetPromptWorldPosition(Prompt)
    local Current = Prompt.Parent
    while Current and Current ~= game do
        if Current:IsA("Attachment") then return Current.WorldPosition end
        if Current:IsA("BasePart") then return Current.Position end
        Current = Current.Parent
    end
    return nil
end

function CR4.GetAutoPromptCategory(Prompt)
    if CR4.HasAncestorNamed(Prompt, "JeffShop_Hotel", CurrentRooms) then return nil end
    if CR4.HasAncestorNamed(Prompt, "GoldPile", CurrentRooms) then return "Gold" end
    if CR4.HasAncestorNamed(Prompt, "KeyObtain", CurrentRooms)
        or CR4.HasAncestorNamed(Prompt, "Lockpick", CurrentRooms)
        or CR4.HasAncestorNamed(Prompt, "SkeletonKey", CurrentRooms)
        or CR4.HasAncestorNamed(Prompt, "ElectricalKeyObtain", CurrentRooms) then
        return "Keys"
    end

    local LootNames = {
        ChestBox = true, ChestBoxLocked = true, DrawerContainer = true, Toolshed_Small = true,
        Vitamins = true, Battery = true, Bandage = true, Candle = true, CrucifixOnTheWall = true,
        Crucifix = true, Flashlight = true, Lighter = true, YellowLight = true, Glowstick = true,
        AlarmClock = true, LiveHintBook = true, LibraryHintPaper = true, Smoothie = true,
        Green_Herb = true, LiveBreakerPolePickup = true,
    }
    if CR4.FindAncestorFromSet(Prompt, LootNames, CurrentRooms) then return "Loot" end
    return nil
end

function CR4.GetFirePromptFunction()
    local Env = getgenv and getgenv() or nil
    if Env and type(Env.fireproximityprompt) == "function" then return Env.fireproximityprompt end
    if type(fireproximityprompt) == "function" then return fireproximityprompt end
    return nil
end

function CR4.TriggerPrompt(Prompt)
    if not Prompt or not Prompt.Parent or not Prompt.Enabled then return end
    local Now = os.clock()
    local AutoCategory = CR4.GetAutoPromptCategory(Prompt)
    local Cooldown = AutoCategory == "Loot" and 2.0 or 0.65
    if LastPromptFire[Prompt] and Now - LastPromptFire[Prompt] < Cooldown then return end
    LastPromptFire[Prompt] = Now

    CR4.RememberPrompt(Prompt)
    local Kind = CR4.GetPromptKind(Prompt)
    local HoldTime = math.max(0, PromptTimes[Kind] or 0.2)
    PromptApplyGuard[Prompt] = true
    pcall(function()
        Prompt.MaxActivationDistance = math.max(Prompt.MaxActivationDistance, State.AutoLootDistance + 3)
        Prompt.RequiresLineOfSight = false
        Prompt.HoldDuration = HoldTime
    end)
    PromptApplyGuard[Prompt] = nil

    local FireFunction = CR4.GetFirePromptFunction()
    local FiredByExecutor = false
    if FireFunction then
        FiredByExecutor = pcall(FireFunction, Prompt)
        if not FiredByExecutor then FiredByExecutor = pcall(FireFunction, Prompt, 1) end
    end

    if not FiredByExecutor then
        task.spawn(function()
            pcall(function()
                Prompt:InputHoldBegin()
                task.wait(HoldTime + 0.05)
                if Prompt and Prompt.Parent then Prompt:InputHoldEnd() end
            end)
        end)
    else
        task.delay(0.08, function()
            if Prompt and Prompt.Parent and Prompt.Enabled then
                pcall(function()
                    Prompt:InputHoldBegin()
                    task.wait(HoldTime + 0.02)
                    if Prompt and Prompt.Parent then Prompt:InputHoldEnd() end
                end)
            end
        end)
    end

    task.delay(HoldTime + 0.08, function()
        if Prompt and Prompt.Parent then CR4.UpdatePrompt(Prompt) end
    end)
end

function CR4.ScanAutoLootRegistry()
    if not State.AutoGold and not State.AutoKeys and not State.AutoLoot then return end
    local _, Humanoid, Root = CR4.GetCharacter()
    if not Humanoid or Humanoid.Health <= 0 or not Root then return end

    for Prompt in pairs(PromptRegistry) do
        if not Prompt or not Prompt.Parent then
            PromptRegistry[Prompt] = nil
        elseif Prompt.Enabled then
            local Category = CR4.GetAutoPromptCategory(Prompt)
            local ShouldFire = (Category == "Gold" and (State.AutoGold or State.AutoLoot))
                or (Category == "Keys" and (State.AutoKeys or State.AutoLoot))
                or (Category == "Loot" and State.AutoLoot)
            if ShouldFire then
                local Position = CR4.GetPromptWorldPosition(Prompt)
                if Position and (Position - Root.Position).Magnitude <= State.AutoLootDistance then CR4.TriggerPrompt(Prompt) end
            end
        end
    end
end
