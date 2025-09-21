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
    if not userColors[userId] then
        userColors[userId] = Color3.fromHSV(
            math.random(),
            0.6 + math.random() * 0.4,
            0.8 + math.random() * 0.2
        )
    end
    return userColors[userId]
end

local useDisplayName = false
local messageLabels = {}
local playerRows = {}

-- ScreenGui
local ScreenGui = Instance.new('ScreenGui')
ScreenGui.Name, ScreenGui.ResetOnSpawn, ScreenGui.Parent =
    'MiniChat', false, game.CoreGui
getgenv().MiniChat = ScreenGui

-- Main Frame
local Frame = Instance.new('Frame')
Frame.Size, Frame.Position =
    UDim2.new(0, 300, 0, 300), UDim2.new(0.3, 0, 0.3, 0)
Frame.BackgroundColor3, Frame.BorderSizePixel = Color3.fromRGB(30, 30, 30), 0
Frame.Active, Frame.Draggable, Frame.Parent = true, true, ScreenGui

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
        dragging, dragStart, startPos = true, input.Position, Frame.Position
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
local function createFrame(name, visible)
    local frame = Instance.new(name == 'Chat' and 'Frame' or 'ScrollingFrame')
    frame.Size, frame.Position =
        UDim2.new(1, -10, 1, -35), UDim2.new(0, 5, 0, 35)
    frame.BackgroundTransparency, frame.Visible = 1, visible
    if name ~= 'Chat' then
        frame.ScrollBarThickness = 5
    end
    frame.Parent = Frame

    if name ~= 'Chat' then
        local layout = Instance.new('UIListLayout')
        layout.Parent, layout.SortOrder, layout.Padding =
            frame, Enum.SortOrder.LayoutOrder, UDim.new(0, 2)
    end
    return frame
end

local ChatFrame = createFrame('Chat', true)
local LogsFrame, PlrsFrame =
    createFrame('Logs', false), createFrame('Plrs', false)

-- Chat scrolling
local ChatScrolling = Instance.new('ScrollingFrame')
ChatScrolling.Size, ChatScrolling.Position =
    UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0)
ChatScrolling.BackgroundTransparency, ChatScrolling.ScrollBarThickness, ChatScrolling.CanvasSize =
    1, 5, UDim2.new(0, 0, 0, 0)
ChatScrolling.Parent = ChatFrame

local UIListLayout = Instance.new('UIListLayout')
UIListLayout.Parent, UIListLayout.SortOrder, UIListLayout.Padding =
    ChatScrolling, Enum.SortOrder.LayoutOrder, UDim.new(0, 2)
UIListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
    ChatScrolling.CanvasSize =
        UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
    ChatScrolling.CanvasPosition =
        Vector2.new(0, ChatScrolling.CanvasSize.Y.Offset)
end)

-- Add message function
local function addMessage(userId, userName, displayName, text)
    local lbl = Instance.new('TextLabel')
    lbl.Size, lbl.BackgroundTransparency = UDim2.new(1, -10, 0, 0), 1
    lbl.Font, lbl.TextSize, lbl.TextXAlignment =
        Enum.Font.SourceSans, 16, Enum.TextXAlignment.Left
    lbl.TextWrapped, lbl.AutomaticSize, lbl.RichText =
        true, Enum.AutomaticSize.Y, true
    lbl.TextColor3, lbl.Parent = Color3.fromRGB(255, 255, 255), ChatScrolling

    local color = getUserColor(userId)
    local colorHex = string.format(
        '%02X%02X%02X',
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255)
    )
    local nameToShow = useDisplayName and displayName or userName
    lbl.Text = string.format(
        "<font color='#%s'>%s</font>: %s",
        colorHex,
        nameToShow,
        text
    )

    table.insert(
        messageLabels,
        {
            label = lbl,
            userId = userId,
            userName = userName,
            displayName = displayName,
            text = text,
        }
    )
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
    lbl.Size, lbl.BackgroundTransparency = UDim2.new(1, -10, 0, 0), 1
    lbl.Font, lbl.TextSize, lbl.TextXAlignment =
        Enum.Font.SourceSans, 16, Enum.TextXAlignment.Left
    lbl.TextWrapped, lbl.AutomaticSize, lbl.TextColor3 =
        true,
        Enum.AutomaticSize.Y,
        joined and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    lbl.Text, lbl.Parent = text, LogsFrame
    LogsFrame.CanvasSize =
        UDim2.new(0, 0, 0, LogsFrame.UIListLayout.AbsoluteContentSize.Y)
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
    local timeStr = ''
    if joinTime then
        local duration = os.time() - joinTime
        local h, m, s =
            math.floor(duration / 3600),
            math.floor((duration % 3600) / 60),
            duration % 60
        if h > 0 then
            timeStr = timeStr .. h .. 'h '
        end
        if m > 0 then
            timeStr = timeStr .. m .. 'm '
        end
        timeStr = timeStr .. s .. 's'
        joinTimes[plr.UserId] = nil
    end
    addLog(
        plr.Name .. ' left' .. (timeStr ~= '' and ' (' .. timeStr .. ')' or ''),
        false
    )
    updatePlayers()
end)

-- Player list
local camera = workspace.CurrentCamera
local oldSubject = camera.CameraSubject

function updatePlayers()
    for _, plr in ipairs(Players:GetPlayers()) do
        if not playerRows[plr.UserId] then
            local row = Instance.new('Frame')
            row.Size, row.BackgroundColor3, row.BorderSizePixel =
                UDim2.new(1, -10, 0, 25), Color3.fromRGB(40, 40, 40), 0
            row.Parent = PlrsFrame

            local nameLabel = Instance.new('TextLabel')
            nameLabel.Size, nameLabel.Position =
                UDim2.new(0.6, -5, 1, 0), UDim2.new(0, 5, 0, 0)
            nameLabel.BackgroundTransparency, nameLabel.Font, nameLabel.TextSize =
                1, Enum.Font.SourceSans, 14
            nameLabel.TextXAlignment, nameLabel.TextColor3, nameLabel.TextTruncate =
                Enum.TextXAlignment.Left,
                Color3.fromRGB(255, 255, 255),
                Enum.TextTruncate.AtEnd
            nameLabel.Text = plr.DisplayName ~= plr.Name
                    and plr.DisplayName .. ' (@' .. plr.Name .. ')'
                or plr.Name
            nameLabel.Parent = row

            local healthLabel = Instance.new('TextLabel')
            healthLabel.Size, healthLabel.Position =
                UDim2.new(0.15, -5, 1, 0), UDim2.new(0.6, 0, 0, 0)
            healthLabel.BackgroundTransparency, healthLabel.Font, healthLabel.TextSize =
                1, Enum.Font.SourceSans, 14
            healthLabel.TextXAlignment, healthLabel.TextColor3 =
                Enum.TextXAlignment.Right, Color3.fromRGB(255, 255, 255)
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
            tpBtn.Size, tpBtn.Position =
                UDim2.new(0.1, 0, 0.8, 0), UDim2.new(0.75, 0, 0.1, 0)
            tpBtn.BackgroundColor3, tpBtn.BorderSizePixel, tpBtn.TextColor3 =
                Color3.fromRGB(60, 60, 60), 0, Color3.fromRGB(255, 255, 255)
            tpBtn.Font, tpBtn.TextSize, tpBtn.Text =
                Enum.Font.SourceSansBold, 12, 'TP'
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
            viewBtn.Size, viewBtn.Position =
                UDim2.new(0.1, 0, 0.8, 0), UDim2.new(0.87, 0, 0.1, 0)
            viewBtn.BackgroundColor3, viewBtn.BorderSizePixel, viewBtn.TextColor3 =
                Color3.fromRGB(60, 60, 60), 0, Color3.fromRGB(255, 255, 255)
            viewBtn.Font, viewBtn.TextSize, viewBtn.Text =
                Enum.Font.SourceSansBold, 12, 'View'
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
    btn.Size, btn.Position =
        UDim2.new(0, 25, 0, 25), UDim2.new(0, 5 + (i - 1) * 30, 0, 5)
    btn.BackgroundColor3, btn.BorderSizePixel, btn.TextColor3 =
        Color3.fromRGB(50, 50, 50), 0, Color3.fromRGB(255, 255, 255)
    btn.Font, btn.TextSize, btn.Text =
        Enum.Font.SourceSansBold, 14, string.sub(name, 1, 1)
    btn.Parent = Frame
    btn.MouseButton1Click:Connect(function()
        ChatFrame.Visible = (name == 'Chat')
        LogsFrame.Visible = (name == 'Logs')
        PlrsFrame.Visible = (name == 'Plrs')
    end)
end

-- U/D toggle
local ToggleBtn = Instance.new('TextButton')
ToggleBtn.Size, ToggleBtn.Position =
    UDim2.new(0, 25, 0, 25), UDim2.new(1, -30, 0, 5)
ToggleBtn.BackgroundColor3, ToggleBtn.TextColor3 =
    Color3.fromRGB(50, 50, 50), Color3.fromRGB(255, 255, 255)
ToggleBtn.Font, ToggleBtn.TextSize, ToggleBtn.Text =
    Enum.Font.SourceSansBold, 16, 'U'
ToggleBtn.Parent = Frame

ToggleBtn.MouseButton1Click:Connect(function()
    useDisplayName = not useDisplayName
    ToggleBtn.Text = useDisplayName and 'D' or 'U'
    for _, info in pairs(messageLabels) do
        local nameToShow = useDisplayName and info.displayName or info.userName
        local color = getUserColor(info.userId)
        local colorHex = string.format(
            '%02X%02X%02X',
            math.floor(color.R * 255),
            math.floor(color.G * 255),
            math.floor(color.B * 255)
        )
        info.label.Text = string.format(
            "<font color='#%s'>%s</font>: %s",
            colorHex,
            nameToShow,
            info.text
        )
    end
end)

-- Initialize existing players
for _, plr in ipairs(Players:GetPlayers()) do
    joinTimes[plr.UserId] = os.time()
end
updatePlayers()
