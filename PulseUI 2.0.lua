--[[
    Pulse UI Library
    Premium Roblox dashboard UI with a real tab/content system.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Pulse = {}
Pulse.__index = Pulse

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

local Theme = {
    Background = Color3.fromRGB(11, 11, 14),
    Surface = Color3.fromRGB(17, 17, 22),
    Surface2 = Color3.fromRGB(22, 22, 29),
    Sidebar = Color3.fromRGB(14, 14, 18),
    Topbar = Color3.fromRGB(16, 16, 20),
    Outline = Color3.fromRGB(44, 44, 56),
    Text = Color3.fromRGB(239, 239, 244),
    Subtext = Color3.fromRGB(155, 155, 168),
    Accent = Color3.fromRGB(220, 42, 42),
    AccentDark = Color3.fromRGB(115, 22, 22),
    White = Color3.fromRGB(255, 255, 255),
    Black = Color3.fromRGB(0, 0, 0),
}

local FontFaceValue = Font.new("rbxasset://fonts/families/GothamSSm.json")

local FastTween = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local MidTween = TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local SlowTween = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function tween(instance, info, props)
    local t = TweenService:Create(instance, info, props)
    t:Play()
    return t
end

local function create(className, props)
    local obj = Instance.new(className)
    for key, value in pairs(props or {}) do
        obj[key] = value
    end
    return obj
end

local function corner(instance, radius)
    create("UICorner", {
        CornerRadius = UDim.new(0, radius or 12),
        Parent = instance,
    })
end

local function stroke(instance, color, transparency)
    create("UIStroke", {
        Color = color or Theme.Outline,
        Transparency = transparency or 0,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = instance,
    })
end

local function padding(instance, top, bottom, left, right)
    create("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        Parent = instance,
    })
end

local function list(instance, pad, horizontal)
    return create("UIListLayout", {
        Padding = UDim.new(0, pad or 8),
        FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = instance,
    })
end

local function gradient(instance, fromColor, toColor)
    create("UIGradient", {
        Color = ColorSequence.new(fromColor, toColor),
        Parent = instance,
    })
end

local function shadow(parent, size, transparency)
    local frame = create("Frame", {
        Name = "Shadow",
        BackgroundColor3 = Theme.Black,
        BackgroundTransparency = transparency or 0.78,
        BorderSizePixel = 0,
        Size = UDim2.new(1, size or 18, 1, size or 18),
        Position = UDim2.new(0, -((size or 18) / 2), 0, -((size or 18) / 2)),
        ZIndex = math.max(parent.ZIndex - 1, 0),
        Parent = parent,
    })
    corner(frame, 24)
    return frame
end

local function safeCall(callback, ...)
    if typeof(callback) ~= "function" then
        return
    end
    local ok, err = pcall(callback, ...)
    if not ok then
        warn("[Pulse UI]", err)
    end
end

local LuaKeywords = {
    ["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true, ["elseif"] = true,
    ["end"] = true, ["false"] = true, ["for"] = true, ["function"] = true, ["if"] = true,
    ["in"] = true, ["local"] = true, ["nil"] = true, ["not"] = true, ["or"] = true,
    ["repeat"] = true, ["return"] = true, ["then"] = true, ["true"] = true, ["until"] = true,
    ["while"] = true,
}

local SyntaxColors = {
    keyword = "#ff6b6b",
    string = "#97e58b",
    number = "#ffbf7a",
    comment = "#8a8f98",
    func = "#7cc7ff",
    roblox = "#7cc7ff",
    normal = "#efeff4",
}

local RobloxIdentifiers = {
    ["self"] = true, ["Enum"] = true, ["Instance"] = true, ["game"] = true,
    ["workspace"] = true, ["script"] = true, ["math"] = true, ["table"] = true,
    ["string"] = true, ["Color3"] = true, ["Vector2"] = true, ["Vector3"] = true,
    ["UDim2"] = true, ["CFrame"] = true, ["RaycastParams"] = true,
    ["TweenService"] = true, ["Players"] = true, ["Workspace"] = true,
    ["ReplicatedStorage"] = true, ["Lighting"] = true, ["StarterGui"] = true,
    ["RunService"] = true, ["UserInputService"] = true, ["TextService"] = true,
    ["HttpService"] = true, ["ReplicatedFirst"] = true, ["Debris"] = true,
    ["CollectionService"] = true,
}

local function richEscape(text)
    text = text:gsub("&", "&amp;")
    text = text:gsub("<", "&lt;")
    text = text:gsub(">", "&gt;")
    return text
end

local function colorize(text, color)
    return string.format('<font color="%s">%s</font>', color, richEscape(text))
end

local function highlightLua(code)
    local out = {}
    local i = 1
    local len = #code

    while i <= len do
        local two = code:sub(i, i + 1)
        local ch = code:sub(i, i)

        if two == "--" then
            local stop = code:find("\n", i, true) or (len + 1)
            table.insert(out, colorize(code:sub(i, stop - 1), SyntaxColors.comment))
            if stop <= len then
                table.insert(out, "\n")
            end
            i = stop + 1
        elseif ch == '"' or ch == "'" then
            local quote = ch
            local j = i + 1
            while j <= len do
                local current = code:sub(j, j)
                if current == "\\" then
                    j = j + 2
                elseif current == quote then
                    j = j + 1
                    break
                else
                    j = j + 1
                end
            end
            table.insert(out, colorize(code:sub(i, math.min(j - 1, len)), SyntaxColors.string))
            i = j
        elseif ch:match("[%a_]") then
            local j = i
            while j <= len and code:sub(j, j):match("[%w_]") do
                j = j + 1
            end
            local word = code:sub(i, j - 1)
            local nextNonSpace = code:match("^%s*(.)", j) or ""
            local consumedSpecial = false
            if word == "Instance" and code:sub(j, j + 3) == ".new" then
                table.insert(out, colorize("Instance.new", SyntaxColors.func))
                i = j + 4
                consumedSpecial = true
            elseif LuaKeywords[word] then
                table.insert(out, colorize(word, SyntaxColors.keyword))
            elseif RobloxIdentifiers[word] then
                table.insert(out, colorize(word, SyntaxColors.roblox))
            elseif nextNonSpace == "(" then
                table.insert(out, colorize(word, SyntaxColors.func))
            else
                table.insert(out, colorize(word, SyntaxColors.normal))
            end
            if not consumedSpecial then
                i = j
            end
        elseif ch:match("%d") then
            local j = i
            while j <= len and code:sub(j, j):match("[%d%.]") do
                j = j + 1
            end
            table.insert(out, colorize(code:sub(i, j - 1), SyntaxColors.number))
            i = j
        else
            table.insert(out, richEscape(ch))
            i = i + 1
        end
    end

    return table.concat(out)
end

local CompletionSets = {
    game = {"GetService", "Players", "Workspace", "ReplicatedStorage", "Lighting"},
    players = {"LocalPlayer", "GetPlayers", "PlayerAdded", "PlayerRemoving"},
    enum = {"KeyCode", "UserInputType", "EasingStyle", "EasingDirection", "Font"},
    instance = {"new"},
    globals = {"local", "function", "if", "then", "end", "for", "while", "return", "print", "game", "self", "Enum", "Instance"},
}

local function getCompletions(sourceBeforeCursor)
    local gamePrefix = sourceBeforeCursor:match("game%.([%w_]*)$")
    if gamePrefix ~= nil then
        local results = {}
        for _, item in ipairs(CompletionSets.game) do
            if item:lower():find(gamePrefix:lower(), 1, true) == 1 then
                table.insert(results, item)
            end
        end
        return results, "game", gamePrefix
    end

    local playersPrefix = sourceBeforeCursor:match('game:GetService%(%s*["' .. "'" .. ']Players["' .. "'" .. ']%s*%)%.([%w_]*)$')
    if playersPrefix ~= nil then
        local results = {}
        for _, item in ipairs(CompletionSets.players) do
            if item:lower():find(playersPrefix:lower(), 1, true) == 1 then
                table.insert(results, item)
            end
        end
        return results, "players", playersPrefix
    end

    local enumPrefix = sourceBeforeCursor:match("Enum%.([%w_]*)$")
    if enumPrefix ~= nil then
        local results = {}
        for _, item in ipairs(CompletionSets.enum) do
            if item:lower():find(enumPrefix:lower(), 1, true) == 1 then
                table.insert(results, item)
            end
        end
        return results, "enum", enumPrefix
    end

    local instancePrefix = sourceBeforeCursor:match("Instance%.([%w_]*)$")
    if instancePrefix ~= nil then
        local results = {}
        for _, item in ipairs(CompletionSets.instance) do
            if item:lower():find(instancePrefix:lower(), 1, true) == 1 then
                table.insert(results, item)
            end
        end
        return results, "instance", instancePrefix
    end

    local wordPrefix = sourceBeforeCursor:match("([%a_][%w_]*)$")
    if wordPrefix then
        local results = {}
        for _, item in ipairs(CompletionSets.globals) do
            if item:lower():find(wordPrefix:lower(), 1, true) == 1 and item ~= wordPrefix then
                table.insert(results, item)
            end
        end
        return results, "word", wordPrefix
    end

    return {}, nil, ""
end

local function ripple(button)
    local clip = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = true,
        Parent = button,
    })
    corner(clip, 12)

    button.MouseButton1Down:Connect(function(x, y)
        local circle = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset(x - button.AbsolutePosition.X, y - button.AbsolutePosition.Y),
            Size = UDim2.fromOffset(0, 0),
            BackgroundColor3 = Theme.White,
            BackgroundTransparency = 0.82,
            BorderSizePixel = 0,
            Parent = clip,
        })
        corner(circle, 999)
        local goal = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 1.8
        tween(circle, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(goal, goal),
            BackgroundTransparency = 1,
        })
        task.delay(0.5, function()
            if circle.Parent then
                circle:Destroy()
            end
        end)
    end)
end

local function attachThemedScrollbar(scrollingFrame, parent, position, size)
    scrollingFrame.ScrollBarThickness = 0

    local track = create("Frame", {
        Name = "CustomScrollbar",
        BackgroundColor3 = Theme.Surface2,
        BorderSizePixel = 0,
        Position = position,
        Size = size,
        ZIndex = 6,
        Parent = parent,
    })
    corner(track, 999)

    local thumb = create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0.2, 0),
        ZIndex = 7,
        Parent = track,
    })
    corner(thumb, 999)
    gradient(thumb, Color3.fromRGB(255, 94, 94), Theme.Accent)

    local function update()
        local canvasY = scrollingFrame.AbsoluteCanvasSize.Y
        local windowY = scrollingFrame.AbsoluteWindowSize.Y

        if canvasY <= 0 or windowY <= 0 or canvasY <= windowY + 2 then
            track.Visible = false
            return
        end

        track.Visible = scrollingFrame.Visible
        local ratio = math.clamp(windowY / canvasY, 0.08, 1)
        local thumbHeight = math.max(22, track.AbsoluteSize.Y * ratio)
        local maxScroll = math.max(canvasY - windowY, 1)
        local progress = math.clamp(scrollingFrame.CanvasPosition.Y / maxScroll, 0, 1)
        local travel = math.max(track.AbsoluteSize.Y - thumbHeight, 0)

        thumb.Size = UDim2.new(1, 0, 0, thumbHeight)
        thumb.Position = UDim2.new(0, 0, 0, travel * progress)
    end

    scrollingFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(update)
    scrollingFrame:GetPropertyChangedSignal("CanvasSize"):Connect(update)
    scrollingFrame:GetPropertyChangedSignal("Visible"):Connect(update)
    scrollingFrame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(update)
    parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
    task.defer(update)

    return track, thumb, update
end

local function makeDraggable(handle, target)
    local dragging = false
    local dragStart
    local startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end
        dragging = true
        dragStart = input.Position
        startPos = target.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end
        local delta = input.Position - dragStart
        target.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end)
end

function Pulse:_createTooltip()
    local tip = create("TextLabel", {
        Name = "Tooltip",
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        TextColor3 = Theme.Text,
        FontFace = FontFaceValue,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        AutomaticSize = Enum.AutomaticSize.XY,
        Visible = false,
        ZIndex = 50,
        Parent = self.ScreenGui,
    })
    padding(tip, 8, 8, 10, 10)
    corner(tip, 10)
    stroke(tip, Theme.Outline, 0.1)

    self.Tooltip = tip

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and tip.Visible then
            tip.Position = UDim2.fromOffset(input.Position.X + 18, input.Position.Y + 18)
        end
    end)
end

function Pulse:_bindTooltip(guiObject, text)
    if not text or text == "" then
        return
    end
    guiObject.MouseEnter:Connect(function()
        self.Tooltip.Text = text
        self.Tooltip.Visible = true
        self.Tooltip.BackgroundTransparency = 1
        tween(self.Tooltip, FastTween, {BackgroundTransparency = 0})
    end)
    guiObject.MouseLeave:Connect(function()
        tween(self.Tooltip, FastTween, {BackgroundTransparency = 1})
        task.delay(0.16, function()
            if self.Tooltip.BackgroundTransparency >= 0.99 then
                self.Tooltip.Visible = false
            end
        end)
    end)
end

function Pulse:Notify(options)
    options = options or {}
    local note = create("Frame", {
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 70),
        Parent = self.NotificationStack,
    })
    corner(note, 12)
    stroke(note, Theme.Outline, 0.12)
    shadow(note, 14, 0.84)

    local accent = create("Frame", {
        BackgroundColor3 = options.Color or Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 4, 1, 0),
        Parent = note,
    })
    corner(accent, 12)

    local body = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.fromOffset(16, 0),
        Parent = note,
    })
    padding(body, 10, 10, 12, 12)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        FontFace = FontFaceValue,
        Text = options.Title or "Notification",
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = body,
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 24),
        Size = UDim2.new(1, 0, 0, 28),
        FontFace = FontFaceValue,
        Text = options.Content or "",
        TextColor3 = Theme.Subtext,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = body,
    })

    note.BackgroundTransparency = 1
    note.Size = UDim2.new(1, 0, 0, 0)
    tween(note, MidTween, {BackgroundTransparency = 0, Size = UDim2.new(1, 0, 0, 70)})

    task.delay(options.Duration or 3.5, function()
        if not note.Parent then
            return
        end
        tween(note, MidTween, {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0)})
        task.delay(0.28, function()
            if note.Parent then
                note:Destroy()
            end
        end)
    end)
end

function Pulse:_createLoading(title)
    local overlay = create("Frame", {
        BackgroundColor3 = Theme.Black,
        BackgroundTransparency = 0.28,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        Parent = self.ScreenGui,
        ZIndex = 100,
    })

    local card = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(420, 170),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        ZIndex = 101,
        Parent = overlay,
    })
    corner(card, 18)
    stroke(card, Theme.Outline, 0.12)
    shadow(card, 24, 0.8)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(26, 24),
        Size = UDim2.new(1, -52, 0, 28),
        FontFace = FontFaceValue,
        Text = title or "Pulse Dashboard",
        TextColor3 = Theme.Text,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 102,
        Parent = card,
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(26, 58),
        Size = UDim2.new(1, -52, 0, 22),
        FontFace = FontFaceValue,
        Text = "Loading resources...",
        TextColor3 = Theme.Subtext,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 102,
        Parent = card,
    })

    local bar = create("Frame", {
        BackgroundColor3 = Theme.Surface2,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(26, 104),
        Size = UDim2.new(1, -52, 0, 18),
        ZIndex = 102,
        Parent = card,
    })
    corner(bar, 999)

    local glow = create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 0, 1, 14),
        ZIndex = 101,
        Parent = bar,
    })
    corner(glow, 999)

    local fill = create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
        ZIndex = 103,
        Parent = bar,
    })
    corner(fill, 999)
    gradient(fill, Color3.fromRGB(255, 94, 94), Theme.Accent)

    local percent = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(26, 132),
        Size = UDim2.new(1, -52, 0, 18),
        FontFace = FontFaceValue,
        Text = "0%",
        TextColor3 = Theme.Subtext,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 102,
        Parent = card,
    })

    local progressValue = create("NumberValue", {
        Value = 0,
        Parent = card,
    })

    local function renderProgress()
        local alpha = math.clamp(progressValue.Value / 100, 0, 1)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        glow.Size = UDim2.new(alpha, 18, 1, 14)
        percent.Text = string.format("%d%%", math.floor(progressValue.Value + 0.5))
    end

    progressValue:GetPropertyChangedSignal("Value"):Connect(renderProgress)
    renderProgress()

    tween(progressValue, TweenInfo.new(1.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Value = 20})
    task.wait(1.45)
    tween(progressValue, TweenInfo.new(2.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Value = 70})
    task.wait(2.1)
    tween(progressValue, TweenInfo.new(1.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Value = 100})
    task.wait(1.35)
    task.wait(0.4)

    tween(card, SlowTween, {BackgroundTransparency = 1, Size = UDim2.fromOffset(400, 160)})
    tween(overlay, SlowTween, {BackgroundTransparency = 1})
    task.wait(0.36)
    overlay:Destroy()
end

function Pulse.new()
    local self = setmetatable({}, Pulse)

    local existing = PlayerGui:FindFirstChild("PulseUILibrary")
    if existing then
        existing:Destroy()
    end

    self.ScreenGui = create("ScreenGui", {
        Name = "PulseUILibrary",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        Parent = PlayerGui,
    })

    self.NotificationStack = create("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -20, 1, -20),
        Size = UDim2.fromOffset(320, 300),
        Parent = self.ScreenGui,
    })
    local noteLayout = list(self.NotificationStack, 10, false)
    noteLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

    self:_createTooltip()
    return self
end

Pulse.Create = Pulse.new

function Pulse:CreateWindow(options)
    options = options or {}

    local window = setmetatable({}, Window)
    window.Library = self
    window.Title = options.Title or "Pulse Dashboard"
    window.ToggleKey = options.ToggleKey or Enum.KeyCode.RightControl
    window.Size = options.Size or UDim2.fromOffset(1080, 650)
    window.MinSize = options.MinSize or Vector2.new(860, 540)
    window.Visible = true
    window.Maximized = false
    window.RestoreSize = window.Size
    window.RestorePosition = UDim2.fromScale(0.5, 0.5)
    window.Tabs = {}
    window.CurrentTab = nil
    window.LastSearchMiss = nil

    self:_createLoading(window.Title)

    local root = create("Frame", {
        Name = "MainWindow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(window.Size.X.Offset - 40, window.Size.Y.Offset - 28),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Parent = self.ScreenGui,
    })
    corner(root, 24)
    stroke(root, Theme.Outline, 0.08)
    shadow(root, 26, 0.78)
    window.Root = root
    create("UISizeConstraint", {
        MinSize = window.MinSize,
        Parent = root,
    })

    local topbar = create("Frame", {
        BackgroundColor3 = Theme.Topbar,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 58),
        Parent = root,
    })
    corner(topbar, 24)

    create("Frame", {
        BackgroundColor3 = Theme.Topbar,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -22),
        Size = UDim2.new(1, 0, 0, 22),
        Parent = topbar,
    })

    local macButtons = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(22, 0),
        Size = UDim2.fromOffset(100, 58),
        Parent = topbar,
    })
    local macLayout = list(macButtons, 10, true)
    macLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local function traffic(color)
        local button = create("TextButton", {
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(18, 18),
            Text = "",
            AutoButtonColor = false,
            Parent = macButtons,
        })
        corner(button, 999)
        return button
    end

    local closeButton = traffic(Color3.fromRGB(255, 95, 86))
    local minimizeButton = traffic(Color3.fromRGB(255, 189, 46))
    local maximizeButton = traffic(Color3.fromRGB(39, 201, 63))

    local titleBlock = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(150, 0),
        Size = UDim2.new(1, -470, 1, 0),
        Parent = topbar,
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 8),
        Size = UDim2.new(1, 0, 0, 22),
        FontFace = FontFaceValue,
        Text = window.Title,
        TextColor3 = Theme.Text,
        TextSize = 17,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = titleBlock,
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 28),
        Size = UDim2.new(1, 0, 0, 16),
        FontFace = FontFaceValue,
        Text = options.Subtitle or "Made by Patdanai",
        TextColor3 = Theme.Subtext,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = titleBlock,
    })

    local searchBox = create("TextBox", {
        ClearTextOnFocus = false,
        PlaceholderText = "Search...",
        Text = "",
        BackgroundColor3 = Theme.Surface2,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -22, 0.5, 0),
        Size = UDim2.fromOffset(240, 38),
        FontFace = FontFaceValue,
        TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.Subtext,
        TextSize = 14,
        Parent = topbar,
    })
    corner(searchBox, 12)
    stroke(searchBox, Theme.Outline, 0.14)
    padding(searchBox, 0, 0, 14, 14)

    local body = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 58),
        Size = UDim2.new(1, 0, 1, -58),
        Parent = root,
    })

    local sidebar = create("Frame", {
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(18, 0),
        Size = UDim2.new(0, 232, 1, -18),
        ClipsDescendants = true,
        Parent = body,
    })
    corner(sidebar, 18)
    stroke(sidebar, Theme.Outline, 0.12)

    local sidebarHeader = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 42),
        Parent = sidebar,
    })
    padding(sidebarHeader, 14, 0, 16, 16)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        FontFace = FontFaceValue,
        Text = "Navigation",
        TextColor3 = Theme.Subtext,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = sidebarHeader,
    })

    create("Frame", {
        BackgroundColor3 = Theme.Outline,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(16, 41),
        Size = UDim2.new(1, -32, 0, 1),
        Parent = sidebar,
    })

    local tabScroll = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(14, 52),
        Size = UDim2.new(1, -34, 1, -66),
        CanvasSize = UDim2.new(),
        Parent = sidebar,
    })

    local tabList = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = tabScroll,
    })
    local tabLayout = list(tabList, 8, false)
    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabScroll.CanvasSize = UDim2.fromOffset(0, tabLayout.AbsoluteContentSize.Y + 4)
    end)
    local sidebarTrack, _, updateSidebarScrollbar = attachThemedScrollbar(
        tabScroll,
        sidebar,
        UDim2.new(1, -12, 0, 58),
        UDim2.new(0, 4, 1, -76)
    )

    local contentPanel = create("Frame", {
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(268, 0),
        Size = UDim2.new(1, -286, 1, -18),
        Parent = body,
    })
    corner(contentPanel, 18)
    stroke(contentPanel, Theme.Outline, 0.12)

    local pageHost = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(20, 20),
        Size = UDim2.new(1, -40, 1, -40),
        ClipsDescendants = true,
        Parent = contentPanel,
    })

    window.Sidebar = sidebar
    window.TabScroll = tabScroll
    window.ContentPanel = contentPanel
    window.SearchBox = searchBox
    window.PageHost = pageHost
    window.TitleBlock = titleBlock

    local function getViewportSize()
        local camera = Workspace.CurrentCamera
        if camera then
            return camera.ViewportSize
        end
        return Vector2.new(1280, 720)
    end

    local function screenMaximizedSize()
        local viewport = getViewportSize()
        local margin = 26
        return UDim2.fromOffset(
            math.max(window.MinSize.X, viewport.X - (margin * 2)),
            math.max(window.MinSize.Y, viewport.Y - (margin * 2))
        )
    end

    function window:RefreshSearchBox()
        local searchWidth = math.min(260, math.max(200, root.AbsoluteSize.X * 0.22))
        searchBox.Size = UDim2.fromOffset(math.floor(searchWidth + 0.5), 38)
        titleBlock.Size = UDim2.new(1, -(searchBox.AbsoluteSize.X + 220), 1, 0)
        updateSidebarScrollbar()
    end

    makeDraggable(topbar, root)

    function window:SetVisible(state)
        window.Visible = state
        if state then
            root.Visible = true
            root.BackgroundTransparency = 1
            tween(root, MidTween, {BackgroundTransparency = 0, Size = window.Maximized and screenMaximizedSize() or window.Size})
        else
            tween(root, MidTween, {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(root.AbsoluteSize.X - 30, root.AbsoluteSize.Y - 20),
            })
            task.delay(0.24, function()
                if root.Parent then
                    root.Visible = false
                end
            end)
        end
    end

    function window:ToggleVisible()
        window:SetVisible(not window.Visible)
    end

    function window:SetMaximized(state)
        if state == window.Maximized then
            return
        end

        if state then
            window.RestoreSize = UDim2.fromOffset(root.AbsoluteSize.X, root.AbsoluteSize.Y)
            window.RestorePosition = root.Position
            window.Maximized = true
            tween(root, SlowTween, {
                Position = UDim2.fromScale(0.5, 0.5),
                Size = screenMaximizedSize(),
            })
        else
            window.Maximized = false
            window.Size = window.RestoreSize
            tween(root, SlowTween, {
                Position = window.RestorePosition,
                Size = window.RestoreSize,
            })
        end
    end

    function window:SelectTab(tab)
        for _, other in ipairs(window.Tabs) do
            other.Page.Visible = false
            other.Button.BackgroundColor3 = Theme.Sidebar
            other.Button.TextLabel.TextColor3 = Theme.Subtext
            other.Button.IconLabel.TextColor3 = Theme.Accent
            if other.ScrollbarTrack then
                other.ScrollbarTrack.Visible = false
            end
        end

        window.CurrentTab = tab
        tab.Page.Visible = true
        tab.Button.BackgroundColor3 = Theme.Surface2
        tab.Button.TextLabel.TextColor3 = Theme.Text
        tab.Button.IconLabel.TextColor3 = Theme.White
        if tab.UpdateScrollbar then
            tab.UpdateScrollbar()
        end
    end

    function window:HighlightItem(item)
        local target = item.HighlightInstance or item.Instance
        if not target or target.Parent == nil then
            return
        end
        if target:IsA("Frame") or target:IsA("TextButton") or target:IsA("TextBox") then
            local original = target.BackgroundColor3
            tween(target, FastTween, {BackgroundColor3 = Theme.AccentDark})
            task.delay(0.24, function()
                if target.Parent then
                    tween(target, MidTween, {BackgroundColor3 = original})
                end
            end)
        end
    end

    function window:FocusItem(tab, item)
        window:SelectTab(tab)
        task.defer(function()
            if tab.Page and item.Instance and item.Instance.Parent then
                if typeof(item.Reveal) == "function" then
                    item.Reveal()
                end
                local absoluteY = item.Instance.AbsolutePosition.Y - tab.Page.AbsolutePosition.Y + tab.Page.CanvasPosition.Y
                tab.Page.CanvasPosition = Vector2.new(0, math.max(absoluteY - 18, 0))
                if tab.UpdateScrollbar then
                    tab.UpdateScrollbar()
                end
                window:HighlightItem(item)
            end
        end)
    end

    function window:RunSearch(query)
        query = string.lower(query or "")
        if query == "" then
            window.LastSearchMiss = nil
            return
        end

        for _, tab in ipairs(window.Tabs) do
            for _, item in ipairs(tab.Items) do
                if string.find(item.SearchText, query, 1, true) then
                    window.LastSearchMiss = nil
                    window:FocusItem(tab, item)
                    return
                end
            end
        end

        if window.LastSearchMiss ~= query then
            window.LastSearchMiss = query
            window.Library:Notify({
                Title = "Search",
                Content = "No results found",
                Duration = 2.2,
            })
        end
    end

    function window:CreateTab(name, iconText)
        local tab = setmetatable({}, Tab)
        tab.Window = window
        tab.Name = name
        tab.Items = {}

        local button = create("TextButton", {
            BackgroundColor3 = Theme.Sidebar,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 44),
            Text = "",
            AutoButtonColor = false,
            Parent = tabList,
        })
        corner(button, 12)
        stroke(button, Theme.Outline, 0.15)
        ripple(button)

        create("TextLabel", {
            Name = "IconLabel",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(14, 0),
            Size = UDim2.fromOffset(22, 44),
            FontFace = FontFaceValue,
            Text = iconText or string.sub(name, 1, 1),
            TextColor3 = Theme.Accent,
            TextSize = 14,
            Parent = button,
        })

        create("TextLabel", {
            Name = "TextLabel",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(42, 0),
            Size = UDim2.new(1, -54, 1, 0),
            FontFace = FontFaceValue,
            Text = name,
            TextColor3 = Theme.Subtext,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = button,
        })

        local page = create("ScrollingFrame", {
            Name = name .. "Frame",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            Visible = false,
            CanvasSize = UDim2.new(),
            Parent = pageHost,
        })

        local pageBody = create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = page,
        })
        local pageLayout = list(pageBody, 12, false)
        pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.fromOffset(0, pageLayout.AbsoluteContentSize.Y + 4)
        end)
        local pageTrack, _, updatePageScrollbar = attachThemedScrollbar(
            page,
            pageHost,
            UDim2.new(1, -6, 0, 4),
            UDim2.new(0, 4, 1, -8)
        )
        pageTrack.Visible = false

        tab.Button = button
        tab.Page = page
        tab.PageBody = pageBody
        tab.ScrollbarTrack = pageTrack
        tab.UpdateScrollbar = updatePageScrollbar

        function tab:RegisterItem(instance, searchText, highlightInstance, revealCallback)
            table.insert(tab.Items, {
                Instance = instance,
                SearchText = string.lower(searchText or ""),
                HighlightInstance = highlightInstance or instance,
                Reveal = revealCallback,
            })
        end

        function tab:CreateSection(title)
            local section = setmetatable({}, Section)
            section.Tab = tab

            local card = create("Frame", {
                BackgroundColor3 = Theme.Background,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = pageBody,
            })
            corner(card, 16)
            stroke(card, Theme.Outline, 0.14)
            shadow(card, 12, 0.86)
            padding(card, 16, 16, 16, 16)

            create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 20),
                FontFace = FontFaceValue,
                Text = title,
                TextColor3 = Theme.Text,
                TextSize = 15,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = card,
            })

            local holder = create("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 28),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = card,
            })
            list(holder, 10, false)

            section.Card = card
            section.Holder = holder
            return section
        end

        button.MouseButton1Click:Connect(function()
            window:SelectTab(tab)
        end)

        table.insert(window.Tabs, tab)
        return tab
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        window:RunSearch(searchBox.Text)
    end)

    closeButton.MouseButton1Click:Connect(function()
        tween(root, MidTween, {BackgroundTransparency = 1, Size = UDim2.fromOffset(980, 590)})
        task.delay(0.3, function()
            if self.ScreenGui.Parent then
                self.ScreenGui:Destroy()
            end
        end)
    end)

    minimizeButton.MouseButton1Click:Connect(function()
        window:ToggleVisible()
    end)

    maximizeButton.MouseButton1Click:Connect(function()
        window:SetMaximized(not window.Maximized)
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == window.ToggleKey then
            window:ToggleVisible()
        end
    end)

    local function updateWindowSize(newWidth, newHeight)
        local clampedWidth = math.max(window.MinSize.X, math.floor(newWidth + 0.5))
        local clampedHeight = math.max(window.MinSize.Y, math.floor(newHeight + 0.5))
        window.Size = UDim2.fromOffset(clampedWidth, clampedHeight)
        root.Size = window.Size
        window:RefreshSearchBox()
    end

    local resizeRight = create("Frame", {
        Name = "ResizeRight",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 14),
        Size = UDim2.new(0, 8, 1, -22),
        Parent = root,
    })

    local resizeBottom = create("Frame", {
        Name = "ResizeBottom",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 14, 1, 0),
        Size = UDim2.new(1, -22, 0, 8),
        Parent = root,
    })

    local resizeCorner = create("Frame", {
        Name = "ResizeCorner",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 0, 1, 0),
        Size = UDim2.fromOffset(16, 16),
        Parent = root,
    })

    local resizeState = {
        Active = false,
        Mode = nil,
        StartMouse = nil,
        StartSize = nil,
    }

    local function beginResize(mode, input)
        if window.Maximized then
            window:SetMaximized(false)
        end
        resizeState.Active = true
        resizeState.Mode = mode
        resizeState.StartMouse = input.Position
        resizeState.StartSize = root.AbsoluteSize
    end

    for mode, handle in pairs({
        Right = resizeRight,
        Bottom = resizeBottom,
        Corner = resizeCorner,
    }) do
        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                beginResize(mode, input)
            end
        end)
    end

    UserInputService.InputChanged:Connect(function(input)
        if not resizeState.Active or input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end

        local delta = input.Position - resizeState.StartMouse
        local width = resizeState.StartSize.X
        local height = resizeState.StartSize.Y

        if resizeState.Mode == "Right" or resizeState.Mode == "Corner" then
            width = width + delta.X
        end
        if resizeState.Mode == "Bottom" or resizeState.Mode == "Corner" then
            height = height + delta.Y
        end

        updateWindowSize(width, height)
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizeState.Active = false
        end
    end)

    root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        window:RefreshSearchBox()
    end)

    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        if window.Maximized then
            root.Size = screenMaximizedSize()
        end
        window:RefreshSearchBox()
    end)

    tween(root, SlowTween, {Size = window.Size})
    window:RefreshSearchBox()
    return window
end

function Section:_row(height, searchText, tooltip)
    local row = create("Frame", {
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height or 46),
        Parent = self.Holder,
    })
    corner(row, 12)
    stroke(row, Theme.Outline, 0.14)
    self.Tab:RegisterItem(row, searchText)
    self.Tab.Window.Library:_bindTooltip(row, tooltip)
    return row
end

function Section:AddLabel(options)
    options = options or {}
    local row = self:_row(42, options.Text or "label", options.Tooltip)
    local label = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -28, 1, 0),
        FontFace = FontFaceValue,
        Text = options.Text or "Label",
        TextColor3 = options.Color or Theme.Subtext,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    return {
        Set = function(_, text)
            label.Text = text
        end,
    }
end

function Section:AddDivider(options)
    options = options or {}
    local row = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
        Parent = self.Holder,
    })
    local line = create("Frame", {
        BackgroundColor3 = Theme.Outline,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = row,
    })
    if options.Text and options.Text ~= "" then
        create("TextLabel", {
            BackgroundColor3 = Theme.Background,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 18),
            FontFace = FontFaceValue,
            Text = "  " .. options.Text .. "  ",
            TextColor3 = Theme.Subtext,
            TextSize = 12,
            Parent = row,
        })
    end
    self.Tab:RegisterItem(row, options.Text or "divider")
    return line
end

function Section:AddButton(options)
    options = options or {}
    local hasSubText = options.SubText and options.SubText ~= ""
    local button = create("TextButton", {
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, hasSubText and 60 or 46),
        Text = "",
        AutoButtonColor = false,
        Parent = self.Holder,
    })
    corner(button, 12)
    stroke(button, Theme.Outline, 0.14)
    ripple(button)

    local titleLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, hasSubText and 8 or 0),
        Size = UDim2.new(1, -28, 0, 20),
        FontFace = FontFaceValue,
        Text = options.Text or "Button",
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = button,
    })

    local subLabel
    if hasSubText then
        subLabel = create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(14, 28),
            Size = UDim2.new(1, -28, 0, 16),
            FontFace = FontFaceValue,
            Text = options.SubText,
            TextColor3 = Theme.Subtext,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = button,
        })
    end

    button.MouseEnter:Connect(function()
        tween(button, FastTween, {BackgroundColor3 = Theme.Surface2})
    end)
    button.MouseLeave:Connect(function()
        tween(button, FastTween, {BackgroundColor3 = Theme.Surface})
    end)
    button.MouseButton1Click:Connect(function()
        safeCall(options.Callback)
    end)

    self.Tab:RegisterItem(button, (options.Text or "button") .. " " .. (options.SubText or ""))
    self.Tab.Window.Library:_bindTooltip(button, options.Tooltip)
    return {
        Instance = button,
        SetText = function(_, text)
            titleLabel.Text = text
        end,
        SetSubText = function(_, text)
            local shouldShow = text and text ~= ""
            if shouldShow and not subLabel then
                subLabel = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(14, 28),
                    Size = UDim2.new(1, -28, 0, 16),
                    FontFace = FontFaceValue,
                    Text = text,
                    TextColor3 = Theme.Subtext,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = button,
                })
            elseif subLabel then
                subLabel.Text = text or ""
                subLabel.Visible = shouldShow
            end

            button.Size = UDim2.new(1, 0, 0, shouldShow and 60 or 46)
            titleLabel.Position = UDim2.fromOffset(14, shouldShow and 8 or 0)
        end,
    }
end

function Section:AddButtonGroup(options)
    options = options or {}
    local expanded = options.DefaultExpanded or false

    local group = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 46),
        ClipsDescendants = true,
        Parent = self.Holder,
    })

    local mainButton = create("TextButton", {
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 46),
        Text = "",
        AutoButtonColor = false,
        Parent = group,
    })
    corner(mainButton, 12)
    stroke(mainButton, Theme.Outline, 0.14)
    ripple(mainButton)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -56, 1, 0),
        FontFace = FontFaceValue,
        Text = options.Text or "Group",
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = mainButton,
    })

    local arrow = create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        FontFace = FontFaceValue,
        Text = expanded and "^" or "v",
        TextColor3 = Theme.Subtext,
        TextSize = 14,
        Parent = mainButton,
    })

    local subClip = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 54),
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        Parent = group,
    })

    local subHolder = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(18, 0),
        Size = UDim2.new(1, -18, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = subClip,
    })
    local subLayout = list(subHolder, 8, false)

    local subButtons = {}
    local contentHeight = 0

    local function recalcHeight()
        contentHeight = subLayout.AbsoluteContentSize.Y
        local target = expanded and (54 + contentHeight) or 46
        tween(group, MidTween, {Size = UDim2.new(1, 0, 0, target)})
        tween(subClip, MidTween, {Size = UDim2.new(1, 0, 0, expanded and contentHeight or 0)})
        arrow.Text = expanded and "^" or "v"
    end

    subLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(recalcHeight)

    local api = {}

    function api:SetExpanded(state)
        expanded = state
        recalcHeight()
    end

    function api:Toggle()
        api:SetExpanded(not expanded)
    end

    function api:AddSubButton(text, callback, tooltip)
        local subButton = create("TextButton", {
            BackgroundColor3 = Theme.Surface2,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 38),
            Text = "",
            AutoButtonColor = false,
            Parent = subHolder,
        })
        corner(subButton, 10)
        stroke(subButton, Theme.Outline, 0.18)
        ripple(subButton)

        create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(14, 0),
            Size = UDim2.new(1, -28, 1, 0),
            FontFace = FontFaceValue,
            Text = text,
            TextColor3 = Theme.Subtext,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = subButton,
        })

        subButton.MouseEnter:Connect(function()
            tween(subButton, FastTween, {BackgroundColor3 = Theme.AccentDark})
        end)
        subButton.MouseLeave:Connect(function()
            tween(subButton, FastTween, {BackgroundColor3 = Theme.Surface2})
        end)
        subButton.MouseButton1Click:Connect(function()
            safeCall(callback)
        end)

        table.insert(subButtons, subButton)
        self.Tab:RegisterItem(subButton, text or "sub button", subButton, function()
            api:SetExpanded(true)
        end)
        self.Tab.Window.Library:_bindTooltip(subButton, tooltip)
        recalcHeight()
        return subButton
    end

    mainButton.MouseEnter:Connect(function()
        tween(mainButton, FastTween, {BackgroundColor3 = Theme.Surface2})
    end)
    mainButton.MouseLeave:Connect(function()
        tween(mainButton, FastTween, {BackgroundColor3 = Theme.Surface})
    end)
    mainButton.MouseButton1Click:Connect(function()
        api:Toggle()
        safeCall(options.Callback, expanded)
    end)

    self.Tab:RegisterItem(group, options.Text or "group", mainButton)
    self.Tab.Window.Library:_bindTooltip(mainButton, options.Tooltip)
    recalcHeight()
    return api
end

function Section:AddToggle(options)
    options = options or {}
    local state = options.Default or false
    local row = self:_row(48, options.Text or "toggle", options.Tooltip)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -96, 1, 0),
        FontFace = FontFaceValue,
        Text = options.Text or "Toggle",
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local toggle = create("TextButton", {
        BackgroundColor3 = state and Theme.Accent or Theme.Surface2,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(48, 24),
        Text = "",
        AutoButtonColor = false,
        Parent = row,
    })
    corner(toggle, 999)

    local knob = create("Frame", {
        BackgroundColor3 = Theme.White,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(18, 18),
        Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
        Parent = toggle,
    })
    corner(knob, 999)

    local function setState(value)
        state = value
        tween(toggle, FastTween, {BackgroundColor3 = state and Theme.Accent or Theme.Surface2})
        tween(knob, FastTween, {
            Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
        })
        safeCall(options.Callback, state)
    end

    toggle.MouseButton1Click:Connect(function()
        setState(not state)
    end)

    return {
        Set = function(_, value)
            setState(value)
        end,
        Get = function()
            return state
        end,
    }
end

function Section:AddDropdown(options)
    options = options or {}
    local values = options.Values or {}
    local selected = options.Default or values[1] or "Select"
    local open = false

    local holder = create("Frame", {
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 46),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = self.Holder,
    })
    corner(holder, 12)
    stroke(holder, Theme.Outline, 0.14)

    local top = create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 46),
        Text = "",
        AutoButtonColor = false,
        Parent = holder,
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(0.55, 0, 1, 0),
        FontFace = FontFaceValue,
        Text = options.Text or "Dropdown",
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = top,
    })

    local valueLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.45, 0, 0, 0),
        Size = UDim2.new(0.55, -38, 1, 0),
        FontFace = FontFaceValue,
        Text = tostring(selected),
        TextColor3 = Theme.Subtext,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = top,
    })

    local arrow = create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        FontFace = FontFaceValue,
        Text = "v",
        TextColor3 = Theme.Subtext,
        TextSize = 14,
        Parent = top,
    })

    local optionsFrame = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 46),
        Size = UDim2.new(1, -20, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = holder,
    })
    padding(optionsFrame, 0, 10, 0, 0)
    list(optionsFrame, 6, false)

    local function rebuild()
        for _, child in ipairs(optionsFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        for _, entry in ipairs(values) do
            local optionButton = create("TextButton", {
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 34),
                Text = tostring(entry),
                TextColor3 = Theme.Text,
                TextSize = 13,
                FontFace = FontFaceValue,
                AutoButtonColor = false,
                Parent = optionsFrame,
            })
            corner(optionButton, 10)
            ripple(optionButton)
            optionButton.MouseButton1Click:Connect(function()
                selected = entry
                valueLabel.Text = tostring(entry)
                open = false
                optionsFrame.Visible = false
                arrow.Text = "v"
                safeCall(options.Callback, selected)
            end)
        end
    end

    rebuild()
    top.MouseButton1Click:Connect(function()
        open = not open
        optionsFrame.Visible = open
        arrow.Text = open and "^" or "v"
    end)

    self.Tab:RegisterItem(holder, options.Text or "dropdown")
    self.Tab.Window.Library:_bindTooltip(holder, options.Tooltip)
    return {
        Set = function(_, value)
            selected = value
            valueLabel.Text = tostring(value)
            safeCall(options.Callback, value)
        end,
        Refresh = function(_, newValues)
            values = newValues
            rebuild()
        end,
        Get = function()
            return selected
        end,
    }
end

function Section:AddSlider(options)
    options = options or {}
    local min = options.Min or 0
    local max = options.Max or 100
    local value = options.Default or min

    local row = self:_row(68, options.Text or "slider", options.Tooltip)
    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 10),
        Size = UDim2.new(1, -90, 0, 18),
        FontFace = FontFaceValue,
        Text = options.Text or "Slider",
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local valueLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -80, 0, 10),
        Size = UDim2.fromOffset(66, 18),
        FontFace = FontFaceValue,
        Text = tostring(value),
        TextColor3 = Theme.Subtext,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row
    })

    local bar = create("Frame", {
        BackgroundColor3 = Theme.Surface2,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(14, 40),
        Size = UDim2.new(1, -28, 0, 12),
        Parent = row,
    })
    corner(bar, 999)

    local fill = create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new((value - min) / math.max(max - min, 1), 0, 1, 0),
        Parent = bar,
    })
    corner(fill, 999)
    gradient(fill, Color3.fromRGB(255, 94, 94), Theme.Accent)

    local knob = create("Frame", {
        BackgroundColor3 = Theme.White,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((value - min) / math.max(max - min, 1), 0, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        Parent = bar,
    })
    corner(knob, 999)

    local dragging = false
    local function update(percent)
        percent = math.clamp(percent, 0, 1)
        value = math.floor((min + ((max - min) * percent)) + 0.5)
        valueLabel.Text = tostring(value)
        fill.Size = UDim2.new(percent, 0, 1, 0)
        knob.Position = UDim2.new(percent, 0, 0.5, 0)
        safeCall(options.Callback, value)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return {
        Set = function(_, newValue)
            update((newValue - min) / math.max(max - min, 1))
        end,
        Get = function()
            return value
        end,
    }
end

function Section:AddProgressBar(options)
    options = options or {}
    local value = math.clamp(options.Default or 0, 0, 100)

    local row = self:_row(64, options.Text or "progress", options.Tooltip)
    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 10),
        Size = UDim2.new(1, -90, 0, 18),
        FontFace = FontFaceValue,
        Text = options.Text or "Progress",
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local percent = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -80, 0, 10),
        Size = UDim2.fromOffset(66, 18),
        FontFace = FontFaceValue,
        Text = tostring(value) .. "%",
        TextColor3 = Theme.Subtext,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row,
    })

    local bar = create("Frame", {
        BackgroundColor3 = Theme.Surface2,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(14, 40),
        Size = UDim2.new(1, -28, 0, 14),
        Parent = row,
    })
    corner(bar, 999)

    local fill = create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(value / 100, 0, 1, 0),
        Parent = bar,
    })
    corner(fill, 999)
    gradient(fill, Color3.fromRGB(255, 94, 94), Theme.Accent)

    return {
        Set = function(_, newValue)
            value = math.clamp(newValue, 0, 100)
            percent.Text = tostring(value) .. "%"
            tween(fill, MidTween, {Size = UDim2.new(value / 100, 0, 1, 0)})
        end,
        Get = function()
            return value
        end,
    }
end

function Window:CreateExecutorTab(options)
    options = options or {}

    local executorTab = self:CreateTab(options.Name or "Executor", options.Icon or "E")

    local shell = create("Frame", {
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = executorTab.PageBody,
    })
    corner(shell, 16)
    stroke(shell, Theme.Outline, 0.14)
    shadow(shell, 12, 0.86)
    padding(shell, 16, 16, 16, 16)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        FontFace = FontFaceValue,
        Text = "Script Executor",
        TextColor3 = Theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = shell,
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 24),
        Size = UDim2.new(1, 0, 0, 18),
        FontFace = FontFaceValue,
        Text = options.Subtitle or "Execute reusable Lua snippets from inside the dashboard.",
        TextColor3 = Theme.Subtext,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = shell,
    })

    local editorFrame = create("Frame", {
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 56),
        Size = UDim2.new(1, 0, 0, 340),
        Parent = shell,
    })
    corner(editorFrame, 14)
    stroke(editorFrame, Theme.Outline, 0.12)

    local editorScroll = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 12),
        Size = UDim2.new(1, -24, 1, -24),
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 0,
        Parent = editorFrame,
    })

    local lineHeight = TextService:GetTextSize("Ag", 14, Enum.Font.Code, Vector2.new(1000, 1000)).Y + 2

    local currentLineHighlight = create("Frame", {
        BackgroundColor3 = Theme.AccentDark,
        BackgroundTransparency = 0.78,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(48, 0),
        Size = UDim2.new(1, -48, 0, lineHeight),
        Parent = editorScroll,
    })
    corner(currentLineHighlight, 8)

    local lineNumbers = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(42, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Code,
        Text = "1",
        TextColor3 = Theme.Subtext,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextYAlignment = Enum.TextYAlignment.Top,
        RichText = false,
        Parent = editorScroll,
    })

    local codeLayer = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(54, 0),
        Size = UDim2.new(1, -54, 0, 20),
        Font = Enum.Font.Code,
        Text = "",
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextWrapped = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        RichText = true,
        Parent = editorScroll,
    })

    local editor = create("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(54, 0),
        Size = UDim2.new(1, -54, 0, 20),
        ClearTextOnFocus = false,
        MultiLine = true,
        TextWrapped = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Text = options.DefaultText or "",
        PlaceholderText = "Write your Lua script here...",
        Font = Enum.Font.Code,
        TextColor3 = Theme.Text,
        TextTransparency = 1,
        PlaceholderColor3 = Theme.Subtext,
        TextSize = 14,
        Parent = editorScroll,
    })
    padding(editor, 0, 0, 0, 0)

    local placeholder = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(54, 0),
        Size = UDim2.new(1, -54, 0, 20),
        Font = Enum.Font.Code,
        Text = "Write your Lua script here...",
        TextColor3 = Theme.Subtext,
        TextTransparency = 0.2,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = editorScroll,
    })

    local suggestionBox = create("Frame", {
        BackgroundColor3 = Theme.Surface2,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(180, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 20,
        Parent = editorFrame,
    })
    corner(suggestionBox, 10)
    stroke(suggestionBox, Theme.Outline, 0.12)
    local suggestionList = list(suggestionBox, 4, false)
    padding(suggestionBox, 6, 6, 6, 6)

    local actionRow = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 410),
        Size = UDim2.new(1, 0, 0, 42),
        Parent = shell,
    })
    local actionLayout = list(actionRow, 10, true)
    actionLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local function actionButton(text, width, color)
        local button = create("TextButton", {
            BackgroundColor3 = color or Theme.Surface,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(width, 42),
            Text = text,
            TextColor3 = Theme.Text,
            TextSize = 14,
            FontFace = FontFaceValue,
            AutoButtonColor = false,
            Parent = actionRow,
        })
        corner(button, 12)
        stroke(button, Theme.Outline, 0.12)
        ripple(button)
        return button
    end

    local runButton = actionButton("Run Script", 140, Theme.AccentDark)
    local clearButton = actionButton("Clear", 100, Theme.Surface)
    local copyButton = actionButton("Copy", 100, Theme.Surface)

    local output = create("TextLabel", {
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 462),
        Size = UDim2.new(1, 0, 0, 40),
        FontFace = FontFaceValue,
        Text = "Output: Ready",
        TextColor3 = Theme.Subtext,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = shell,
    })
    corner(output, 12)
    stroke(output, Theme.Outline, 0.12)
    padding(output, 0, 0, 14, 14)

    shell.Size = UDim2.new(1, 0, 0, 518)

    local function setOutput(message, color)
        output.Text = "Output: " .. message
        output.TextColor3 = color or Theme.Subtext
    end

    local function tryCopy(text)
        local clipboardFns = {
            rawget(getfenv(), "setclipboard"),
            rawget(getfenv(), "toclipboard"),
            rawget(getfenv(), "Clipboard"),
        }

        for _, fn in ipairs(clipboardFns) do
            if typeof(fn) == "function" then
                local ok = pcall(fn, text)
                if ok then
                    return true
                end
            end
        end

        if typeof(clipboard) == "table" and typeof(clipboard.set) == "function" then
            local ok = pcall(clipboard.set, text)
            if ok then
                return true
            end
        end

        return false
    end

    local suggestionItems = {}
    local activeSuggestion = nil
    local editorFocused = false
    local lastEditorText = editor.Text
    local internalEditorUpdate = false
    local refreshQueued = false
    local blockOpeners = {
        ["then"] = true,
        ["do"] = true,
        ["function"] = true,
        ["repeat"] = true,
    }
    local autoPairs = {
        ["("] = ")",
        ["["] = "]",
        ["{"] = "}",
        ['"'] = '"',
        ["'"] = "'",
    }

    local function rebuildLineNumbers(text)
        local lines = 1
        for _ in text:gmatch("\n") do
            lines = lines + 1
        end
        local numbers = table.create(lines)
        for i = 1, lines do
            numbers[i] = tostring(i)
        end
        lineNumbers.Text = table.concat(numbers, "\n")
    end

    local function syncEditorCanvas()
        local height = math.max(editor.TextBounds.Y + 10, editorScroll.AbsoluteSize.Y - 2)
        editor.Size = UDim2.new(1, -54, 0, height)
        codeLayer.Size = UDim2.new(1, -54, 0, height)
        lineNumbers.Size = UDim2.fromOffset(42, height)
        editorScroll.CanvasSize = UDim2.fromOffset(0, height + 4)
        currentLineHighlight.Size = UDim2.new(1, -48, 0, lineHeight)
    end

    local function clearSuggestions()
        for _, item in ipairs(suggestionItems) do
            item:Destroy()
        end
        suggestionItems = {}
        activeSuggestion = nil
        suggestionBox.Visible = false
    end

    local function setEditorState(newText, newCursor)
        internalEditorUpdate = true
        editor.Text = newText
        editor.CursorPosition = newCursor
        internalEditorUpdate = false
        lastEditorText = newText
    end

    local function insertCompletion(completion, prefix)
        local cursor = math.max(editor.CursorPosition, 1)
        local text = editor.Text
        local startAt = math.max(cursor - #prefix - 1, 0)
        setEditorState(
            text:sub(1, startAt) .. completion .. text:sub(cursor, #text),
            startAt + #completion + 1
        )
    end

    local function insertAtCursor(textToInsert, cursorOffset)
        local cursor = math.max(editor.CursorPosition, 1)
        local text = editor.Text
        local left = text:sub(1, cursor - 1)
        local right = text:sub(cursor, #text)
        setEditorState(left .. textToInsert .. right, cursor + (cursorOffset or #textToInsert))
    end

    local function tryAcceptCompletion()
        local beforeCursor = editor.Text:sub(1, math.max(editor.CursorPosition - 1, 0))
        local completions, _, prefix = getCompletions(beforeCursor)
        local completion = activeSuggestion or completions[1]
        if completion and prefix ~= nil and completion ~= prefix then
            insertCompletion(completion, prefix or "")
            clearSuggestions()
            queueRefresh()
            return true
        end
        return false
    end

    local function rebuildSuggestions()
        clearSuggestions()

        if not editorFocused then
            return
        end

        local cursor = editor.CursorPosition
        if cursor <= 1 then
            return
        end

        local beforeCursor = editor.Text:sub(1, cursor - 1)
        local completions, _, prefix = getCompletions(beforeCursor)
        if #completions == 0 then
            return
        end

        local lineText = beforeCursor:match("([^\n]*)$") or ""
        local lineIndex = 1
        for _ in beforeCursor:gmatch("\n") do
            lineIndex = lineIndex + 1
        end

        local charWidth = TextService:GetTextSize("M", 14, Enum.Font.Code, Vector2.new(1000, 1000)).X
        local x = math.clamp(54 + math.floor(#lineText * charWidth * 0.92), 54, math.max(editorFrame.AbsoluteSize.X - 190, 54))
        local y = math.clamp(((lineIndex - 1) * 16) - editorScroll.CanvasPosition.Y + 26, 26, math.max(editorFrame.AbsoluteSize.Y - 90, 26))
        suggestionBox.Position = UDim2.fromOffset(x, y)

        for _, completion in ipairs(completions) do
            local button = create("TextButton", {
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel = 0,
                Size = UDim2.fromOffset(168, 28),
                Text = completion,
                Font = Enum.Font.Code,
                TextColor3 = Theme.Text,
                TextSize = 13,
                AutoButtonColor = false,
                Parent = suggestionBox,
                ZIndex = 21,
            })
            corner(button, 8)
            button.MouseButton1Click:Connect(function()
                insertCompletion(completion, prefix)
                clearSuggestions()
            end)
            table.insert(suggestionItems, button)
        end

        activeSuggestion = completions[1]
        suggestionBox.Visible = true
    end

    local function refreshEditor()
        placeholder.Visible = editor.Text == ""
        codeLayer.Text = highlightLua(editor.Text == "" and " " or editor.Text)
        rebuildLineNumbers(editor.Text)
        syncEditorCanvas()
        rebuildSuggestions()
    end

    local updateCurrentLineHighlight

    local function queueRefresh()
        if refreshQueued then
            return
        end
        refreshQueued = true
        task.defer(function()
            refreshQueued = false
            refreshEditor()
            updateCurrentLineHighlight()
        end)
    end

    updateCurrentLineHighlight = function()
        local cursor = math.max(editor.CursorPosition, 1)
        local beforeCursor = editor.Text:sub(1, math.max(cursor - 1, 0))
        local lineIndex = 1
        for _ in beforeCursor:gmatch("\n") do
            lineIndex = lineIndex + 1
        end
        local y = ((lineIndex - 1) * lineHeight) - editorScroll.CanvasPosition.Y
        currentLineHighlight.Position = UDim2.fromOffset(48, y)
        currentLineHighlight.Visible = editorFocused

        local topVisible = editorScroll.CanvasPosition.Y
        local bottomVisible = topVisible + editorScroll.AbsoluteWindowSize.Y - lineHeight
        local absoluteLineY = (lineIndex - 1) * lineHeight
        if absoluteLineY < topVisible then
            editorScroll.CanvasPosition = Vector2.new(0, math.max(absoluteLineY, 0))
        elseif absoluteLineY > bottomVisible then
            editorScroll.CanvasPosition = Vector2.new(0, math.max(absoluteLineY - editorScroll.AbsoluteWindowSize.Y + lineHeight + 8, 0))
        end
    end

    local function applyAutoIndentAndPairs()
        if internalEditorUpdate then
            return
        end
        local text = editor.Text
        local cursor = editor.CursorPosition
        if cursor < 2 or #text <= #lastEditorText then
            lastEditorText = text
            return
        end

        local insertedChar = text:sub(cursor - 2, cursor - 2)
        local beforeCursor = text:sub(1, cursor - 1)
        local lineBeforeCursor = beforeCursor:match("([^\n]*)$") or ""
        local updatedText = text
        local updatedCursor = cursor

        if autoPairs[insertedChar] then
            local closing = autoPairs[insertedChar]
            local rightChar = text:sub(cursor, cursor)
            if rightChar ~= closing then
                updatedText = text:sub(1, cursor - 1) .. closing .. text:sub(cursor, #text)
                updatedCursor = cursor
                text = updatedText
            end
        elseif insertedChar == "\n" then
            local lineBeforeBreak = text:sub(1, cursor - 2):match("([^\n]*)\n?$") or ""
            local indent = lineBeforeBreak:match("^(%s*)") or ""
            local trimmed = lineBeforeBreak:gsub("^%s+", "")
            local lastWord = trimmed:match("([%a_]+)%s*$")
            if lastWord and blockOpeners[lastWord] then
                indent = indent .. "    "
            end

            local rightLine = text:sub(cursor, #text):match("^([^\n]*)") or ""
            if rightLine:match("^%s*end[%W]") then
                indent = indent:gsub("    $", "")
            end

            updatedText = text:sub(1, cursor - 1) .. indent .. text:sub(cursor, #text)
            updatedCursor = cursor + #indent
        elseif insertedChar == "d" then
            local currentLine = lineBeforeCursor
            local leading = currentLine:match("^(%s*)") or ""
            local trimmed = currentLine:gsub("^%s+", "")
            if trimmed == "end" and #leading >= 4 then
                local dedented = leading:sub(1, #leading - 4) .. "end"
                local lineStart = beforeCursor:match(".*()\n") or 1
                updatedText = text:sub(1, lineStart - 1) .. dedented .. text:sub(cursor, #text)
                updatedCursor = lineStart - 1 + #dedented + 1
            end
        end

        if updatedText ~= editor.Text or updatedCursor ~= editor.CursorPosition then
            setEditorState(updatedText, updatedCursor)
        else
            lastEditorText = text
        end
    end

    editor:GetPropertyChangedSignal("Text"):Connect(function()
        applyAutoIndentAndPairs()
        queueRefresh()
    end)
    editor:GetPropertyChangedSignal("CursorPosition"):Connect(function()
        rebuildSuggestions()
        updateCurrentLineHighlight()
    end)
    editorScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        local posY = -editorScroll.CanvasPosition.Y
        currentLineHighlight.Position = UDim2.fromOffset(48, currentLineHighlight.Position.Y.Offset)
        editor.Position = UDim2.fromOffset(54, posY)
        codeLayer.Position = UDim2.fromOffset(54, posY)
        lineNumbers.Position = UDim2.fromOffset(0, posY)
        placeholder.Position = UDim2.fromOffset(54, posY)
        rebuildSuggestions()
        updateCurrentLineHighlight()
    end)

    editor.Focused:Connect(function()
        editorFocused = true
        queueRefresh()
        updateCurrentLineHighlight()
    end)
    editor.FocusLost:Connect(function()
        editorFocused = false
        clearSuggestions()
        currentLineHighlight.Visible = false
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not editorFocused then
            return
        end

        if input.KeyCode == Enum.KeyCode.Tab then
            if not tryAcceptCompletion() then
                insertAtCursor("    ", 4)
                queueRefresh()
            end
            return
        end

        if activeSuggestion and input.KeyCode == Enum.KeyCode.Return then
            tryAcceptCompletion()
        end
    end)

    refreshEditor()
    updateCurrentLineHighlight()

    runButton.MouseButton1Click:Connect(function()
        local code = editor.Text
        if code == "" then
            setOutput("No script to run", Theme.Subtext)
            return
        end

        if typeof(loadstring) ~= "function" then
            setOutput("loadstring is unavailable in this environment", Theme.Accent)
            return
        end

        local chunk, compileError = loadstring(code)
        if not chunk then
            setOutput(compileError or "Compilation failed", Theme.Accent)
            return
        end

        local ok, runtimeError = pcall(chunk)
        if ok then
            setOutput("Script executed successfully", Color3.fromRGB(110, 214, 142))
        else
            setOutput(runtimeError or "Execution failed", Theme.Accent)
        end
    end)

    clearButton.MouseButton1Click:Connect(function()
        editor.Text = ""
        setOutput("Editor cleared", Theme.Subtext)
    end)

    copyButton.MouseButton1Click:Connect(function()
        if editor.Text == "" then
            setOutput("Nothing to copy", Theme.Subtext)
            return
        end
        if tryCopy(editor.Text) then
            setOutput("Copied to clipboard", Color3.fromRGB(110, 214, 142))
        else
            setOutput("Clipboard API unavailable", Theme.Accent)
        end
    end)

    executorTab:RegisterItem(shell, "script executor code editor run script clear copy executor", editorFrame)
    executorTab:RegisterItem(runButton, "run script execute")
    executorTab:RegisterItem(clearButton, "clear editor")
    executorTab:RegisterItem(copyButton, "copy script")
    executorTab:RegisterItem(output, "output console")

    return executorTab, {
        Editor = editor,
        Output = output,
        SetText = function(text)
            editor.Text = text
        end,
        GetText = function()
            return editor.Text
        end,
    }
end

function Window:Notify(options)
    self.Library:Notify(options)
end

return Pulse
