-- // Mini Chat GUI (Optimized) \\ --
if getgenv().MiniChat then
    getgenv().MiniChat:Destroy()
end

local Players = game:GetService('Players')
local TextChatService = game:GetService('TextChatService')
local UIS = game:GetService('UserInputService')
local RunService = game:GetService('RunService')

-- Track join times
local joinTimes = {}

-- User colors
local userColors = {}
local function getUserColor(userId)
    if userColors[userId] then
        return userColors[userId]
    end
    local color = Color3.fromHSV(
        math.random(),
        0.6 + math.random() * 0.4,
        0.8 + math.random() * 0.2
    )
    userColors[userId] = color
    return color
end

local useDisplayName = false
local messageLabels = {}

-- ScreenGui
local ScreenGui = Instance.new('ScreenGui')
ScreenGui.Name = 'MiniChat'
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui
getgenv().MiniChat = ScreenGui

-- Main Frame
local Frame = Instance.new('Frame')
Frame.Size = UDim2.new(0, 300, 0, 300)
Frame.Position = UDim2.new(0.3, 0, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

-- Drag logic
local dragging, dragInput, dragStart, startPos
local function updateDrag(input)
    local delta = input.Position - dragStart
    Frame.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end
Frame.InputBegan:Connect(function(input)
    if
        input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
    then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
Frame.InputChanged:Connect(function(input)
    if
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    then
        dragInput = input
    end
end)
UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateDrag(input)
    end
end)

-- Tabs
local ChatFrame = Instance.new('Frame')
ChatFrame.Size = UDim2.new(1, -10, 1, -35)
ChatFrame.Position = UDim2.new(0, 5, 0, 35)
ChatFrame.BackgroundTransparency = 1
ChatFrame.Parent = Frame

local LogsFrame = Instance.new('ScrollingFrame')
LogsFrame.Size = ChatFrame.Size
LogsFrame.Position = ChatFrame.Position
LogsFrame.BackgroundTransparency = 1
LogsFrame.ScrollBarThickness = 5
LogsFrame.Visible = false
LogsFrame.Parent = Frame
local LogsLayout = Instance.new('UIListLayout')
LogsLayout.Parent = LogsFrame
LogsLayout.SortOrder = Enum.SortOrder.LayoutOrder
LogsLayout.Padding = UDim.new(0, 2)

local PlrsFrame = Instance.new('ScrollingFrame')
PlrsFrame.Size = ChatFrame.Size
PlrsFrame.Position = ChatFrame.Position
PlrsFrame.BackgroundTransparency = 1
PlrsFrame.ScrollBarThickness = 5
PlrsFrame.Visible = false
PlrsFrame.Parent = Frame
local PlrsLayout = Instance.new('UIListLayout')
PlrsLayout.Parent = PlrsFrame
PlrsLayout.SortOrder = Enum.SortOrder.LayoutOrder
PlrsLayout.Padding = UDim.new(0, 5)

-- Chat scrolling
local ChatScrolling = Instance.new('ScrollingFrame')
ChatScrolling.Size = UDim2.new(1, 0, 1, 0)
ChatScrolling.Position = UDim2.new(0, 0, 0, 0)
ChatScrolling.BackgroundTransparency = 1
ChatScrolling.ScrollBarThickness = 5
ChatScrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
ChatScrolling.Parent = ChatFrame
local UIListLayout = Instance.new('UIListLayout')
UIListLayout.Parent = ChatScrolling
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 2)
UIListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
    ChatScrolling.CanvasSize =
        UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
    ChatScrolling.CanvasPosition =
        Vector2.new(0, ChatScrolling.CanvasSize.Y.Offset)
end)

-- Add chat message
local function addMessage(userId, userName, displayName, text)
    local lbl = Instance.new('TextLabel')
    lbl.Size = UDim2.new(1, -10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 16
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.RichText = true
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Parent = ChatScrolling

    local colorHex = string.format(
        '%02X%02X%02X',
        math.floor(getUserColor(userId).R * 255),
        math.floor(getUserColor(userId).G * 255),
        math.floor(getUserColor(userId).B * 255)
    )
    local nameToShow = useDisplayName and displayName or userName
    lbl.Text = string.format(
        "<font color='#%s'>%s</font>: %s",
        colorHex,
        nameToShow,
        text
    )

    table.insert(messageLabels, {
        label = lbl,
        userId = userId,
        userName = userName,
        displayName = displayName,
        text = text,
    })
end

TextChatService.OnIncomingMessage = function(msg)
    if not msg or msg.Status ~= Enum.TextChatMessageStatus.Success then
        return
    end
    local src, text = msg.TextSource, msg.Text or ''
    if src and src.UserId > 0 then
        local plr = Players:GetPlayerByUserId(src.UserId)
        addMessage(
            src.UserId,
            plr and plr.Name or 'Unknown',
            plr and plr.DisplayName or 'Unknown',
            text
        )
    else
        addMessage(0, 'System', 'System', text)
    end
end

-- Logs
local function addLog(text, joined)
    local lbl = Instance.new('TextLabel')
    lbl.Size = UDim2.new(1, -10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 16
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.TextColor3 = joined and Color3.fromRGB(0, 255, 0)
        or Color3.fromRGB(255, 0, 0)
    lbl.Text = text
    lbl.Parent = LogsFrame
    LogsFrame.CanvasSize = UDim2.new(0, 0, 0, LogsLayout.AbsoluteContentSize.Y)
    LogsFrame.CanvasPosition = Vector2.new(0, LogsFrame.CanvasSize.Y.Offset)
end

-- Player join/leave
Players.PlayerAdded:Connect(function(plr)
    joinTimes[plr.UserId] = os.time()
    addLog(plr.Name .. ' joined', true)
    updatePlayers()
end)

Players.PlayerRemoving:Connect(function(plr)
    local joinTime = joinTimes[plr.UserId]
    if joinTime then
        local duration = os.time() - joinTime
        local h = math.floor(duration / 3600)
        local m = math.floor((duration % 3600) / 60)
        local s = duration % 60
        local timeStr = ''
        if h > 0 then
            timeStr = timeStr .. h .. 'h '
        end
        if m > 0 then
            timeStr = timeStr .. m .. 'm '
        end
        timeStr = timeStr .. s .. 's'
        addLog(plr.Name .. ' left (' .. timeStr .. ')', false)
        joinTimes[plr.UserId] = nil
    else
        addLog(plr.Name .. ' left', false)
    end
    updatePlayers()
end)

-- Player list (optimized)
local playerRows = {}
local camera = workspace.CurrentCamera
local oldSubject = camera.CameraSubject

function updatePlayers()
    for _, plr in ipairs(Players:GetPlayers()) do
        if not playerRows[plr.UserId] then
            local row = Instance.new('Frame')
            row.Size = UDim2.new(1, -10, 0, 25)
            row.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            row.BorderSizePixel = 0
            row.Parent = PlrsFrame

            local nameLabel = Instance.new('TextLabel')
            nameLabel.Size = UDim2.new(0.6, -5, 1, 0)
            nameLabel.Position = UDim2.new(0, 5, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Font = Enum.Font.SourceSans
            nameLabel.TextSize = 14
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.Text = plr.DisplayName ~= plr.Name
                    and plr.DisplayName .. ' (@' .. plr.Name .. ')'
                or plr.Name
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.Parent = row

            local healthLabel = Instance.new('TextLabel')
            healthLabel.Size = UDim2.new(0.15, -5, 1, 0)
            healthLabel.Position = UDim2.new(0.6, 0, 0, 0)
            healthLabel.BackgroundTransparency = 1
            healthLabel.Font = Enum.Font.SourceSans
            healthLabel.TextSize = 14
            healthLabel.TextXAlignment = Enum.TextXAlignment.Right
            healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            healthLabel.Parent = row

            local function updateHealth()
                if
                    plr.Character and plr.Character:FindFirstChild('Humanoid')
                then
                    healthLabel.Text = 'HP: '
                        .. math.floor(plr.Character.Humanoid.Health)
                end
            end
            if plr.Character then
                plr.Character
                    :WaitForChild('Humanoid').HealthChanged
                    :Connect(updateHealth)
                updateHealth()
            end
            plr.CharacterAdded:Connect(function(char)
                char:WaitForChild('Humanoid').HealthChanged
                    :Connect(updateHealth)
                updateHealth()
            end)

            -- TP button
            local tpBtn = Instance.new('TextButton')
            tpBtn.Size = UDim2.new(0.1, 0, 0.8, 0)
            tpBtn.Position = UDim2.new(0.75, 0, 0.1, 0)
            tpBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            tpBtn.BorderSizePixel = 0
            tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            tpBtn.Font = Enum.Font.SourceSansBold
            tpBtn.TextSize = 12
            tpBtn.Text = 'TP'
            tpBtn.Parent = row
            tpBtn.MouseButton1Click:Connect(function()
                local localChar = Players.LocalPlayer.Character
                if
                    localChar
                    and localChar:FindFirstChild('HumanoidRootPart')
                    and plr.Character
                    and plr.Character:FindFirstChild('HumanoidRootPart')
                then
                    localChar.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame
                        * CFrame.new(0, 3, 0)
                end
            end)

            -- View button
            local viewBtn = Instance.new('TextButton')
            viewBtn.Size = UDim2.new(0.1, 0, 0.8, 0)
            viewBtn.Position = UDim2.new(0.87, 0, 0.1, 0)
            viewBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            viewBtn.BorderSizePixel = 0
            viewBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            viewBtn.Font = Enum.Font.SourceSansBold
            viewBtn.TextSize = 12
            viewBtn.Text = 'View'
            viewBtn.Parent = row
            local viewing = false
            viewBtn.MouseButton1Click:Connect(function()
                viewing = not viewing
                viewBtn.Text = viewing and 'Viewing' or 'View'
                if viewing then
                    if
                        plr.Character
                        and plr.Character:FindFirstChild('Humanoid')
                    then
                        oldSubject = camera.CameraSubject
                        camera.CameraSubject = plr.Character.Humanoid
                    end
                else
                    camera.CameraSubject = oldSubject
                end
            end)

            playerRows[plr.UserId] = row
        end
    end
end

-- Tabs
local tabNames = { 'Chat', 'Logs', 'Plrs' }
for i, name in ipairs(tabNames) do
    local btn = Instance.new('TextButton')
    btn.Size = UDim2.new(0, 25, 0, 25)
    btn.Position = UDim2.new(0, 5 + (i - 1) * 30, 0, 5)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.Text = string.sub(name, 1, 1)
    btn.Parent = Frame
    btn.MouseButton1Click:Connect(function()
        ChatFrame.Visible = (name == 'Chat')
        LogsFrame.Visible = (name == 'Logs')
        PlrsFrame.Visible = (name == 'Plrs')
    end)
end

-- U/D toggle
local ToggleBtn = Instance.new('TextButton')
ToggleBtn.Size = UDim2.new(0, 25, 0, 25)
ToggleBtn.Position = UDim2.new(1, -30, 0, 5)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 16
ToggleBtn.Text = 'U'
ToggleBtn.Parent = Frame
ToggleBtn.MouseButton1Click:Connect(function()
    useDisplayName = not useDisplayName
    ToggleBtn.Text = useDisplayName and 'D' or 'U'
    for _, info in pairs(messageLabels) do
        local nameToShow = useDisplayName and info.displayName or info.userName
        local colorHex = string.format(
            '%02X%02X%02X',
            math.floor(getUserColor(info.userId).R * 255),
            math.floor(getUserColor(info.userId).G * 255),
            math.floor(getUserColor(info.userId).B * 255)
        )
        info.label.Text = string.format(
            "<font color='#%s'>%s</font>: %s",
            colorHex,
            nameToShow,
            info.text
        )
    end
end)

-- Default tab
ChatFrame.Visible = true
LogsFrame.Visible = false
PlrsFrame.Visible = false

-- Initialize existing players join times
for _, plr in ipairs(Players:GetPlayers()) do
    joinTimes[plr.UserId] = os.time()
end

updatePlayers()
