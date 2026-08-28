-- Experiment 17 | Rivals | ESP.lua
-- Physical logical module; compiled independently by Loader.lua.

--========================================================
-- ESP GUI
--========================================================

ESPGui = Instance.new("ScreenGui")
ESPGui.Name = "Experiment17ESP"
ESPGui.IgnoreGuiInset = true
ESPGui.ResetOnSpawn = false
ESPGui.Parent = LP:WaitForChild("PlayerGui")

function NewLine(parent)
    local line = Instance.new("Frame")
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.BorderSizePixel = 0
    line.Visible = false
    line.Parent = parent
    return line
end

function DrawLine(frame, a, b, thickness)
    local delta = b - a
    local center = (a + b) / 2

    frame.Position = UDim2.fromOffset(center.X, center.Y)
    frame.Size = UDim2.fromOffset(delta.Magnitude, thickness)
    frame.Rotation = math.deg(math.atan2(delta.Y, delta.X))
end

function CreateESP(player)
    if ESPObjects[player] then
        return ESPObjects[player]
    end

    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = ESPGui

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Parent = box

    local corner = Instance.new("UICorner")
    corner.Parent = box

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(1, 1)
    fill.BorderSizePixel = 0
    fill.BackgroundTransparency = 1
    fill.Parent = box

    local fillCorner = Instance.new("UICorner")
    fillCorner.Parent = fill

    local info = Instance.new("TextLabel")
    info.AnchorPoint = Vector2.new(0.5, 0)
    info.Size = UDim2.fromOffset(360, 20)
    info.BackgroundTransparency = 1
    info.TextStrokeTransparency = 0
    info.TextColor3 = Color3.new(1, 1, 1)
    info.Font = Enum.Font.Code
    info.TextSize = 14
    info.Visible = false
    info.Parent = ESPGui

    local nameLabel = Instance.new("TextLabel")
    nameLabel.AnchorPoint = Vector2.new(0.5, 1)
    nameLabel.Size = UDim2.fromOffset(300, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.Font = Enum.Font.Code
    nameLabel.TextSize = 14
    nameLabel.Visible = false
    nameLabel.Parent = ESPGui

    local tracer = NewLine(ESPGui)

    local hpBack = Instance.new("Frame")
    hpBack.BorderSizePixel = 0
    hpBack.BackgroundColor3 = Color3.new(0, 0, 0)
    hpBack.Visible = false
    hpBack.Parent = ESPGui

    local hpFill = Instance.new("Frame")
    hpFill.AnchorPoint = Vector2.new(0, 1)
    hpFill.BorderSizePixel = 0
    hpFill.BackgroundColor3 = Color3.new(0, 1, 0)
    hpFill.Parent = hpBack

    ESPObjects[player] = {
        Box = box,
        Stroke = stroke,
        Corner = corner,
        Fill = fill,
        FillCorner = fillCorner,
        Info = info,
        Name = nameLabel,
        Tracer = tracer,
        HPBack = hpBack,
        HPFill = hpFill
    }

    return ESPObjects[player]
end

function DestroyESP(player)
    local object = ESPObjects[player]

    if not object then
        return
    end

    for _, instance in pairs(object) do
        if typeof(instance) == "Instance" then
            instance:Destroy()
        end
    end

    ESPObjects[player] = nil
end

function CharacterBox(character)
    local cf, size = character:GetBoundingBox()
    local half = size / 2

    local minX = math.huge
    local minY = math.huge
    local maxX = -math.huge
    local maxY = -math.huge
    local found = false

    for x = -1, 1, 2 do
        for y = -1, 1, 2 do
            for z = -1, 1, 2 do
                local point = cf:PointToWorldSpace(
                    Vector3.new(
                        half.X * x,
                        half.Y * y,
                        half.Z * z
                    )
                )

                local screen = Camera:WorldToViewportPoint(point)

                if screen.Z > 0 then
                    found = true
                    minX = math.min(minX, screen.X)
                    minY = math.min(minY, screen.Y)
                    maxX = math.max(maxX, screen.X)
                    maxY = math.max(maxY, screen.Y)
                end
            end
        end
    end

    if not found then
        return nil
    end

    return Vector2.new(minX, minY), Vector2.new(maxX, maxY)
end

function GetHighlight(player)
    local highlight = Highlights[player]

    if highlight and highlight.Parent == player.Character then
        return highlight
    end

    if highlight then
        highlight:Destroy()
    end

    if not player.Character then
        return nil
    end

    highlight = Instance.new("Highlight")
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = player.Character
    highlight.Parent = player.Character

    Highlights[player] = highlight
    return highlight
end


--========================================================
-- ESP LOOP
--========================================================

ESPAccumulator = 0

Connections.ESP = RunService.RenderStepped:Connect(function(dt)
    ESPAccumulator += dt

    local espRate = math.max(5, Options.ESPUpdateRate.Value)
    local espInterval = 1 / espRate

    if ESPAccumulator < espInterval then
        return
    end

    ESPAccumulator = 0

    if Unloaded then
        return
    end

    Camera = Workspace.CurrentCamera

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LP then
            continue
        end

        local object = CreateESP(player)

        local char = player.Character
        local hum =
            char
            and char:FindFirstChildOfClass("Humanoid")
        local root =
            char
            and char:FindFirstChild("HumanoidRootPart")

        if not char or not hum or not root or hum.Health <= 0 then
            object.Box.Visible = false
            object.Tracer.Visible = false
            object.Info.Visible = false
            object.Name.Visible = false
            object.HPBack.Visible = false

            local highlight = Highlights[player]

            if highlight then
                highlight.Enabled = false
            end

            continue
        end

        local distance = GetDistance(player)

        if distance > Options.ESPMaxDistance.Value then
            object.Box.Visible = false
            object.Tracer.Visible = false
            object.Info.Visible = false
            object.Name.Visible = false
            object.HPBack.Visible = false

            local highlight = Highlights[player]

            if highlight then
                highlight.Enabled = false
            end

            continue
        end

        local teammate = IsTeammate(player)

        if teammate and not Toggles.TeamESP.Value then
            object.Box.Visible = false
            object.Tracer.Visible = false
            object.Info.Visible = false
            object.Name.Visible = false
            object.HPBack.Visible = false

            local highlight = Highlights[player]

            if highlight then
                highlight.Enabled = false
            end

            continue
        end

        if Toggles.ESPFriendCheck.Value and IsFriend(player) then
            object.Box.Visible = false
            object.Tracer.Visible = false
            object.Info.Visible = false
            object.Name.Visible = false
            object.HPBack.Visible = false

            local highlight = Highlights[player]

            if highlight then
                highlight.Enabled = false
            end

            continue
        end

        if Toggles.ESPVisibleOnly.Value then
            local checkPart =
                char:FindFirstChild("Head")
                or root

            if not RayVisible(player, checkPart) then
                object.Box.Visible = false
                object.Tracer.Visible = false
                object.Info.Visible = false
                object.Name.Visible = false
                object.HPBack.Visible = false

                local highlight = Highlights[player]

                if highlight then
                    highlight.Enabled = false
                end

                continue
            end
        end

        local color =
            teammate
            and Options.TeamColor.Value
            or Options.EnemyColor.Value

        local highlight = GetHighlight(player)

        if highlight then
            highlight.Enabled = Toggles.HighlightESP.Value
            highlight.FillColor = color
            highlight.OutlineColor = color
            highlight.FillTransparency = 0.7
            highlight.OutlineTransparency = 0
        end

        local topLeft, bottomRight = CharacterBox(char)

        if not topLeft then
            object.Box.Visible = false
            object.Tracer.Visible = false
            object.Info.Visible = false
            object.Name.Visible = false
            object.HPBack.Visible = false
            continue
        end

        local width =
            bottomRight.X - topLeft.X

        local height =
            bottomRight.Y - topLeft.Y

        local centerX =
            topLeft.X + width / 2

        -- BOX
        object.Box.Position =
            UDim2.fromOffset(
                topLeft.X,
                topLeft.Y
            )

        object.Box.Size =
            UDim2.fromOffset(
                width,
                height
            )

        object.Box.Visible =
            Toggles.BoxESP.Value

        object.Stroke.Color = color
        object.Stroke.Thickness = Options.BoxThickness.Value

        object.Corner.CornerRadius =
            UDim.new(
                0,
                Options.BoxRoundness.Value
            )

        object.FillCorner.CornerRadius =
            object.Corner.CornerRadius

        object.Fill.BackgroundColor3 = color
        object.Fill.BackgroundTransparency =
            Toggles.BoxFill.Value
            and Options.FillTransparency.Value
            or 1

        -- NAME
        object.Name.TextSize = Options.ESPTextSize.Value
        object.Name.Text =
            teammate
            and ("[TEAM] " .. player.DisplayName)
            or player.DisplayName

        object.Name.Position =
            UDim2.fromOffset(
                centerX,
                topLeft.Y - 2
            )

        object.Name.Visible =
            Toggles.ESPName.Value

        -- INFO
        local infoParts = {}

        if Toggles.ESPHealth.Value then
            table.insert(
                infoParts,
                string.format(
                    "%d/%d HP",
                    math.floor(hum.Health),
                    math.floor(hum.MaxHealth)
                )
            )
        end

        if Toggles.ESPDistance.Value then
            table.insert(
                infoParts,
                tostring(math.floor(distance)) .. " studs"
            )
        end

        object.Info.TextSize = Options.ESPTextSize.Value
        object.Info.Text = table.concat(infoParts, " | ")
        object.Info.Position =
            UDim2.fromOffset(
                centerX,
                bottomRight.Y + 3
            )

        object.Info.Visible = #infoParts > 0

        -- HEALTH BAR
        object.HPBack.Position =
            UDim2.fromOffset(
                topLeft.X - 7,
                topLeft.Y
            )

        object.HPBack.Size =
            UDim2.fromOffset(
                4,
                height
            )

        object.HPBack.Visible =
            Toggles.ESPHealthBar.Value

        local healthRatio =
            math.clamp(
                hum.Health / math.max(hum.MaxHealth, 1),
                0,
                1
            )

        object.HPFill.Position =
            UDim2.fromScale(
                0,
                1
            )

        object.HPFill.Size =
            UDim2.new(
                1,
                0,
                healthRatio,
                0
            )

        object.HPFill.BackgroundColor3 =
            Color3.fromRGB(
                math.floor(255 * (1 - healthRatio)),
                math.floor(255 * healthRatio),
                60
            )

        -- TRACER
        if Toggles.TracerESP.Value then
            local originMode = Options.TracerOrigin.Value
            local origin

            if originMode == "Top" then
                origin = Vector2.new(
                    Camera.ViewportSize.X / 2,
                    0
                )
            elseif originMode == "Center" then
                origin = Camera.ViewportSize / 2
            else
                origin = Vector2.new(
                    Camera.ViewportSize.X / 2,
                    Camera.ViewportSize.Y
                )
            end

            object.Tracer.BackgroundColor3 = color

            DrawLine(
                object.Tracer,
                origin,
                Vector2.new(
                    centerX,
                    bottomRight.Y
                ),
                1
            )

            object.Tracer.Visible = true
        else
            object.Tracer.Visible = false
        end
    end
end)
