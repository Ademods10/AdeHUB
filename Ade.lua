local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local CONFIG = {
    Name = "ADEX HUB",
    Version = "3.8.1",
    Key = Enum.KeyCode.RightShift,
    LoadDuration = 1.8,
    LogoUrl = "rbxassetid://6031075931",

    Radius = {
        Outer = 12,
        Card = 10,
        Small = 8,
        Tiny = 2,
        Bar = 4,
        Logo = 12
    },

    Colors = {
        Background = Color3.fromRGB(14, 14, 18),
        Secondary = Color3.fromRGB(20, 20, 25),
        Card = Color3.fromRGB(28, 28, 35),
        Border = Color3.fromRGB(45, 45, 55),
        Accent = Color3.fromRGB(0, 170, 255),
        Text = Color3.fromRGB(245, 245, 250),
        SubText = Color3.fromRGB(150, 150, 160),
        Off = Color3.fromRGB(65, 65, 75),
        Danger = Color3.fromRGB(200, 60, 60),
        DangerDark = Color3.fromRGB(160, 45, 45),
        Online = Color3.fromRGB(50, 220, 100),
        Success = Color3.fromRGB(60, 210, 120)
    }
}

if _G.ADEX_HubKillers then
    for _, entry in ipairs(_G.ADEX_HubKillers) do
        pcall(function()
            if entry and entry.Disconnect then
                entry:Disconnect()
            end
        end)
    end
end
_G.ADEX_HubKillers = {}

pcall(function() RunService:UnbindFromRenderStep("ADEX_NicknameKiller") end)
pcall(function() RunService:UnbindFromRenderStep("ADEX_CrosshairKiller") end)
pcall(function() RunService:UnbindFromRenderStep("ADEX_GeneratorKiller") end)
pcall(function() RunService:UnbindFromRenderStep("ADEX_AutoGenKiller") end)

pcall(function()
    local old = CoreGui:FindFirstChild("ADEX_MODERN_HUB")
    if old then old:Destroy() end
end)

local Parent
pcall(function()
    if typeof(gethui) == "function" then
        Parent = gethui()
    end
end)
Parent = Parent or CoreGui

local function Create(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        pcall(function() object[property] = value end)
    end
    object.Parent = parent
    return object
end

local function Corner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = object
    return corner
end

local function Stroke(object, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or CONFIG.Colors.Border
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = object
    return stroke
end

local function Gradient(object, color1, color2, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(color1, color2)
    gradient.Rotation = rotation or 90
    gradient.Parent = object
    return gradient
end

local ActiveTweens = {}

local function Tween(object, duration, properties, style)
    if not object or not object.Parent then return nil end

    if ActiveTweens[object] then
        pcall(function() ActiveTweens[object]:Cancel() end)
        ActiveTweens[object] = nil
    end

    local success, result = pcall(function()
        return TweenService:Create(
            object,
            TweenInfo.new(
                duration or 0.2,
                style or Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            ),
            properties
        )
    end)

    if not success then
        warn("[ADEX] Tween failed:", object and object.Name, result)
        return nil
    end

    local tween = result
    if tween then
        ActiveTweens[object] = tween
        tween:Play()
        tween.Completed:Once(function()
            if ActiveTweens[object] == tween then
                ActiveTweens[object] = nil
            end
        end)
        return tween
    end
    return nil
end

local function GetSize()
    local camera = workspace.CurrentCamera
    if not camera then return 320, 400 end

    local viewport = camera.ViewportSize

    if UserInputService.TouchEnabled then
        return
            math.clamp(viewport.X - 24, 275, 340),
            math.clamp(viewport.Y * 0.62, 340, 450)
    end

    return
        math.clamp(viewport.X * 0.38, 460, 540),
        math.clamp(viewport.Y * 0.46, 320, 390)
end

local HubWidth, HubHeight = GetSize()

local GUI = Create("ScreenGui", {
    Name = "ADEX_MODERN_HUB",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true
}, Parent)

local function GetViewport()
    local viewport = GUI.AbsoluteSize
    if viewport.X <= 0 or viewport.Y <= 0 then
        local camera = workspace.CurrentCamera
        viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    end
    return viewport
end

local function ClampPixel(px, py, size, anchorPoint)
    local viewport = GetViewport()
    local halfW = size.X * anchorPoint.X
    local halfH = size.Y * anchorPoint.Y

    local minX, maxX = halfW, viewport.X - halfW
    local minY, maxY = halfH, viewport.Y - halfH

    if minX > maxX then px = viewport.X / 2
    else px = math.clamp(px, minX, maxX) end

    if minY > maxY then py = viewport.Y / 2
    else py = math.clamp(py, minY, maxY) end

    return px, py
end

local function GetPixelPosition(target)
    local viewport = GetViewport()
    local position = target.Position
    return
        position.X.Scale * viewport.X + position.X.Offset,
        position.Y.Scale * viewport.Y + position.Y.Offset
end

local function SetPixelPosition(target, px, py)
    if not target or not target.Parent then return end
    local size = target.AbsoluteSize
    if size.X <= 0 or size.Y <= 0 then
        size = Vector2.new(100, 100)
    end
    local cx, cy = ClampPixel(px, py, size, target.AnchorPoint)
    target.Position = UDim2.fromOffset(cx, cy)
end

local function ClampInside(target)
    if not target or not target.Parent then return end
    local px, py = GetPixelPosition(target)
    SetPixelPosition(target, px, py)
end

local Loader = Create("Frame", {
    Name = "Loader",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = CONFIG.Colors.Background,
    BorderSizePixel = 0,
    ZIndex = 100
}, GUI)

local LoaderCenter = Create("Frame", {
    Size = UDim2.fromOffset(280, 130),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = CONFIG.Colors.Secondary,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 101
}, Loader)

Corner(LoaderCenter, CONFIG.Radius.Outer)
Stroke(LoaderCenter)

local LoaderTitle = Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.fromOffset(0, 20),
    BackgroundTransparency = 1,
    Text = CONFIG.Name,
    TextColor3 = CONFIG.Colors.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 22,
    ZIndex = 102
}, LoaderCenter)

local LoaderVersion = Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 16),
    Position = UDim2.fromOffset(0, 52),
    BackgroundTransparency = 1,
    Text = "VERSION " .. CONFIG.Version,
    TextColor3 = CONFIG.Colors.Accent,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    ZIndex = 102
}, LoaderCenter)

local BarBG = Create("Frame", {
    Size = UDim2.new(1, -60, 0, 8),
    Position = UDim2.new(0, 30, 1, -40),
    BackgroundColor3 = CONFIG.Colors.Card,
    BorderSizePixel = 0,
    ZIndex = 102
}, LoaderCenter)

Corner(BarBG, CONFIG.Radius.Bar)

local BarFill = Create("Frame", {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = CONFIG.Colors.Accent,
    BorderSizePixel = 0,
    ZIndex = 103
}, BarBG)

Corner(BarFill, CONFIG.Radius.Bar)
Gradient(BarFill, CONFIG.Colors.Accent, Color3.fromRGB(120, 220, 255), 0)

local LoaderStatus = Create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 14),
    Position = UDim2.new(0, 0, 1, -22),
    BackgroundTransparency = 1,
    Text = "Initializing...",
    TextColor3 = CONFIG.Colors.SubText,
    Font = Enum.Font.Gotham,
    TextSize = 9,
    ZIndex = 102
}, LoaderCenter)

LoaderCenter.Size = UDim2.fromOffset(0, 0)
LoaderCenter.BackgroundTransparency = 1
LoaderTitle.TextTransparency = 1
LoaderVersion.TextTransparency = 1
LoaderStatus.TextTransparency = 1
BarBG.BackgroundTransparency = 1

Tween(LoaderCenter, 0.35, {
    Size = UDim2.fromOffset(280, 130),
    BackgroundTransparency = 0
})
Tween(LoaderTitle, 0.40, { TextTransparency = 0 })
Tween(LoaderVersion, 0.45, { TextTransparency = 0 })
Tween(LoaderStatus, 0.50, { TextTransparency = 0 })
Tween(BarBG, 0.50, { BackgroundTransparency = 0 })

local Main = Create("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(HubWidth, HubHeight),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = CONFIG.Colors.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Visible = false,
    ZIndex = 2
}, GUI)

Corner(Main, CONFIG.Radius.Outer)
Stroke(Main)

local Header = Create("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 46),
    BackgroundColor3 = CONFIG.Colors.Secondary,
    BorderSizePixel = 0,
    ZIndex = 3
}, Main)

Corner(Header, CONFIG.Radius.Outer)

Create("Frame", {
    Size = UDim2.new(1, 0, 0, CONFIG.Radius.Outer),
    Position = UDim2.new(0, 0, 1, -CONFIG.Radius.Outer),
    BackgroundColor3 = CONFIG.Colors.Secondary,
    BorderSizePixel = 0,
    ZIndex = 4
}, Header)

local DragZone = Create("Frame", {
    Name = "DragZone",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Active = true,
    ZIndex = 5
}, Header)

local AccentLine = Create("Frame", {
    Size = UDim2.new(1, -28, 0, 2),
    Position = UDim2.new(0, 14, 1, -2),
    BackgroundColor3 = CONFIG.Colors.Accent,
    BorderSizePixel = 0,
    ZIndex = 7
}, Header)
Corner(AccentLine, 1)

Create("TextLabel", {
    Size = UDim2.new(1, -140, 0, 20),
    Position = UDim2.fromOffset(14, 5),
    BackgroundTransparency = 1,
    Text = CONFIG.Name,
    TextColor3 = CONFIG.Colors.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left,
    Active = false,
    ZIndex = 18
}, Header)

Create("TextLabel", {
    Size = UDim2.new(1, -140, 0, 14),
    Position = UDim2.fromOffset(15, 25),
    BackgroundTransparency = 1,
    Text = "Modern UI • V" .. CONFIG.Version,
    TextColor3 = CONFIG.Colors.SubText,
    Font = Enum.Font.Gotham,
    TextSize = 8,
    TextXAlignment = Enum.TextXAlignment.Left,
    Active = false,
    ZIndex = 18
}, Header)

local MinimizeBtn = Create("TextButton", {
    Name = "Minimize",
    Size = UDim2.fromOffset(30, 27),
    Position = UDim2.new(1, -70, 0, 9.5),
    BackgroundColor3 = CONFIG.Colors.Card,
    BorderSizePixel = 0,
    Text = "—",
    TextColor3 = CONFIG.Colors.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    AutoButtonColor = false,
    Active = true,
    Selectable = false,
    ZIndex = 60
}, Main)

Corner(MinimizeBtn, CONFIG.Radius.Small)
Stroke(MinimizeBtn, CONFIG.Colors.Border, 1)

local CloseBtn = Create("TextButton", {
    Name = "Close",
    Size = UDim2.fromOffset(30, 27),
    Position = UDim2.new(1, -36, 0, 9.5),
    BackgroundColor3 = CONFIG.Colors.Card,
    BorderSizePixel = 0,
    Text = "×",
    TextColor3 = CONFIG.Colors.Danger,
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    AutoButtonColor = false,
    Active = true,
    Selectable = false,
    ZIndex = 60
}, Main)

Corner(CloseBtn, CONFIG.Radius.Small)
Stroke(CloseBtn, CONFIG.Colors.Border, 1)

local FloatingLogo = Create("TextButton", {
    Name = "FloatingLogo",
    Size = UDim2.fromOffset(52, 52),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = CONFIG.Colors.Secondary,
    BorderSizePixel = 0,
    Text = "",
    AutoButtonColor = false,
    Active = true,
    Selectable = false,
    Visible = false,
    ClipsDescendants = true,
    ZIndex = 80
}, GUI)

Corner(FloatingLogo, CONFIG.Radius.Logo)
Stroke(FloatingLogo, CONFIG.Colors.Border, 1)

local FloatingLogoInner = Create("Frame", {
    Name = "Inner",
    Size = UDim2.new(1, -6, 1, -6),
    Position = UDim2.fromOffset(3, 3),
    BackgroundColor3 = CONFIG.Colors.Background,
    BorderSizePixel = 0,
    Active = false,
    ZIndex = 81
}, FloatingLogo)

Corner(FloatingLogoInner, CONFIG.Radius.Logo - 2)

local FloatingLogoImg = Create("ImageLabel", {
    Name = "Logo",
    Size = UDim2.new(1, -12, 1, -12),
    Position = UDim2.fromOffset(6, 6),
    BackgroundTransparency = 1,
    Image = CONFIG.LogoUrl,
    ImageTransparency = 0,
    ScaleType = Enum.ScaleType.Fit,
    Active = false,
    ZIndex = 82
}, FloatingLogo)

Corner(FloatingLogoImg, CONFIG.Radius.Logo - 4)

local LogoFallback = Create("TextLabel", {
    Name = "Fallback",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "A",
    TextColor3 = CONFIG.Colors.Accent,
    Font = Enum.Font.GothamBold,
    TextSize = 22,
    Visible = false,
    Active = false,
    ZIndex = 83
}, FloatingLogo)

local function UpdateLogoFallback()
    if not FloatingLogoImg or not FloatingLogoImg.Parent then return end
    if FloatingLogoImg.IsLoaded then
        LogoFallback.Visible = false
        if FloatingLogoImg.ImageTransparency >= 1 then
            FloatingLogoImg.ImageTransparency = 0
        end
    else
        LogoFallback.Visible = true
        FloatingLogoImg.ImageTransparency = 1
    end
end

FloatingLogoImg:GetPropertyChangedSignal("IsLoaded"):Connect(UpdateLogoFallback)
task.defer(UpdateLogoFallback)

local SidebarWidth = UserInputService.TouchEnabled and 100 or 112

local Body = Create("Frame", {
    Name = "Body",
    Size = UDim2.new(1, 0, 1, -46),
    Position = UDim2.fromOffset(0, 46),
    BackgroundTransparency = 1,
    ZIndex = 2
}, Main)

local Sidebar = Create("Frame", {
    Name = "Sidebar",
    Size = UDim2.new(0, SidebarWidth, 1, 0),
    BackgroundColor3 = CONFIG.Colors.Secondary,
    BorderSizePixel = 0,
    ZIndex = 3
}, Body)

Corner(Sidebar, CONFIG.Radius.Outer)

Create("Frame", {
    Size = UDim2.new(1, 0, 0, CONFIG.Radius.Outer),
    BackgroundColor3 = CONFIG.Colors.Secondary,
    BorderSizePixel = 0,
    ZIndex = 5
}, Sidebar)

Create("UIPadding", {
    PaddingTop = UDim.new(0, CONFIG.Radius.Outer + 2),
    PaddingLeft = UDim.new(0, 6),
    PaddingRight = UDim.new(0, 6),
    PaddingBottom = UDim.new(0, CONFIG.Radius.Outer)
}, Sidebar)

Create("UIListLayout", {
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder
}, Sidebar)

local Content = Create("Frame", {
    Name = "Content",
    Size = UDim2.new(1, -SidebarWidth, 1, 0),
    Position = UDim2.fromOffset(SidebarWidth, 0),
    BackgroundTransparency = 1,
    ZIndex = 2
}, Body)

local PagesHolder = Create("Frame", {
    Name = "PagesHolder",
    Size = UDim2.new(1, -12, 1, -12),
    Position = UDim2.fromOffset(6, 6),
    BackgroundTransparency = 1,
    ZIndex = 2
}, Content)

local Tabs = {}

local function CreatePage(name)
    local page = Create("ScrollingFrame", {
        Name = name,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = CONFIG.Colors.Accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false,
        Active = true,
        ZIndex = 2
    }, PagesHolder)

    Create("UIPadding", {
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 1),
        PaddingRight = UDim.new(0, 5)
    }, page)

    Create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, page)

    return page
end

local function SelectTab(name)
    for tabName, data in pairs(Tabs) do
        local active = tabName == name
        data.Page.Visible = active

        Tween(data.Button, 0.15, {
            BackgroundColor3 = active
                and CONFIG.Colors.Card
                or CONFIG.Colors.Secondary
        })
        Tween(data.Label, 0.15, {
            TextColor3 = active
                and CONFIG.Colors.Text
                or CONFIG.Colors.SubText
        })
        Tween(data.Indicator, 0.15, {
            BackgroundTransparency = active and 0 or 1
        })
    end
end

local function CreateTab(name, icon)
    local button = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = CONFIG.Colors.Secondary,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Active = true,
        Selectable = false,
        ZIndex = 10
    }, Sidebar)

    Corner(button, CONFIG.Radius.Card)

    local indicator = Create("Frame", {
        Size = UDim2.fromOffset(3, 18),
        Position = UDim2.new(0, 0, 0.5, -9),
        BackgroundColor3 = CONFIG.Colors.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 11
    }, button)

    Corner(indicator, CONFIG.Radius.Tiny)

    Create("TextLabel", {
        Size = UDim2.fromOffset(24, 34),
        Position = UDim2.fromOffset(5, 0),
        BackgroundTransparency = 1,
        Text = icon,
        TextColor3 = CONFIG.Colors.SubText,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Active = false,
        ZIndex = 11
    }, button)

    local label = Create("TextLabel", {
        Size = UDim2.new(1, -32, 1, 0),
        Position = UDim2.fromOffset(30, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = CONFIG.Colors.SubText,
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        Active = false,
        ZIndex = 11
    }, button)

    local page = CreatePage(name)

    button.Activated:Connect(function() SelectTab(name) end)

    Tabs[name] = {
        Button = button,
        Label = label,
        Indicator = indicator,
        Page = page
    }

    return page
end

local function AddSection(page, text)
    return Create("TextLabel", {
        Size = UDim2.new(1, -3, 0, 21),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = CONFIG.Colors.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        Active = false,
        ZIndex = 2
    }, page)
end

local function AddLabel(page, title, description)
    local height = description and 49 or 37

    local card = Create("Frame", {
        Size = UDim2.new(1, -3, 0, height),
        BackgroundColor3 = CONFIG.Colors.Card,
        BorderSizePixel = 0,
        ZIndex = 2
    }, page)

    Corner(card, CONFIG.Radius.Card)
    Stroke(card)

    Create("TextLabel", {
        Size = UDim2.new(1, -18, 0, 18),
        Position = UDim2.fromOffset(9, 5),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = CONFIG.Colors.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Active = false,
        ZIndex = 3
    }, card)

    if description then
        Create("TextLabel", {
            Size = UDim2.new(1, -18, 0, 20),
            Position = UDim2.fromOffset(9, 25),
            BackgroundTransparency = 1,
            Text = description,
            TextColor3 = CONFIG.Colors.SubText,
            Font = Enum.Font.Gotham,
            TextSize = 8,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Active = false,
            ZIndex = 3
        }, card)
    end

    return card
end

local function AddStatusLabel(page, title)
    local card = Create("Frame", {
        Size = UDim2.new(1, -3, 0, 49),
        BackgroundColor3 = CONFIG.Colors.Card,
        BorderSizePixel = 0,
        ZIndex = 2
    }, page)

    Corner(card, CONFIG.Radius.Card)
    Stroke(card)

    Create("TextLabel", {
        Size = UDim2.new(1, -90, 0, 18),
        Position = UDim2.fromOffset(9, 5),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = CONFIG.Colors.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Active = false,
        ZIndex = 3
    }, card)

    local statusText = Create("TextLabel", {
        Size = UDim2.new(1, -90, 0, 18),
        Position = UDim2.fromOffset(9, 25),
        BackgroundTransparency = 1,
        Text = "Online",
        TextColor3 = CONFIG.Colors.Online,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Active = false,
        ZIndex = 3
    }, card)

    local dot = Create("Frame", {
        Name = "StatusDot",
        Size = UDim2.fromOffset(12, 12),
        Position = UDim2.new(1, -24, 0.5, -6),
        BackgroundColor3 = CONFIG.Colors.Online,
        BorderSizePixel = 0,
        Active = false,
        ZIndex = 4
    }, card)

    Corner(dot, 12)

    local ring = Create("Frame", {
        Name = "StatusRing",
        Size = UDim2.fromOffset(12, 12),
        Position = UDim2.fromOffset(0, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = false,
        ZIndex = 3
    }, dot)

    ring.Position = UDim2.fromScale(0.5, 0.5)
    Corner(ring, 12)

    local ringStroke = Instance.new("UIStroke")
    ringStroke.Color = CONFIG.Colors.Online
    ringStroke.Thickness = 1
    ringStroke.Transparency = 0.5
    ringStroke.Parent = ring

    local pulseConnection
    pulseConnection = RunService.Heartbeat:Connect(function()
        if not card or not card.Parent then
            if pulseConnection then
                pulseConnection:Disconnect()
                pulseConnection = nil
            end
            return
        end

        local t = tick() % 1.5
        local progress = t / 1.5

        local size = 12 + (progress * 12)
        ring.Size = UDim2.fromOffset(size, size)
        ringStroke.Transparency = 0.3 + (progress * 0.7)
    end)

    return {
        Card = card,
        Text = statusText,
        Dot = dot,
        SetStatus = function(isOnline)
            if isOnline then
                statusText.Text = "Online"
                statusText.TextColor3 = CONFIG.Colors.Online
                dot.BackgroundColor3 = CONFIG.Colors.Online
                ringStroke.Color = CONFIG.Colors.Online
            else
                statusText.Text = "Offline"
                statusText.TextColor3 = CONFIG.Colors.Danger
                dot.BackgroundColor3 = CONFIG.Colors.Danger
                ringStroke.Color = CONFIG.Colors.Danger
            end
        end
    }
end

local function AddButton(page, title, description, callback)
    local height = description and 50 or 38

    local button = Create("TextButton", {
        Size = UDim2.new(1, -3, 0, height),
        BackgroundColor3 = CONFIG.Colors.Card,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Active = true,
        Selectable = false,
        ZIndex = 5
    }, page)

    Corner(button, CONFIG.Radius.Card)
    Stroke(button)

    local titleLabel = Create("TextLabel", {
        Size = UDim2.new(1, -50, 0, 18),
        Position = UDim2.fromOffset(10, description and 5 or 10),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = CONFIG.Colors.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Active = false,
        ZIndex = 6
    }, button)

    if description then
        Create("TextLabel", {
            Size = UDim2.new(1, -50, 0, 16),
            Position = UDim2.fromOffset(10, 25),
            BackgroundTransparency = 1,
            Text = description,
            TextColor3 = CONFIG.Colors.SubText,
            Font = Enum.Font.Gotham,
            TextSize = 8,
            TextXAlignment = Enum.TextXAlignment.Left,
            Active = false,
            ZIndex = 6
        }, button)
    end

    local arrow = Create("TextLabel", {
        Size = UDim2.fromOffset(25, 22),
        Position = UDim2.new(1, -33, 0.5, -11),
        BackgroundColor3 = CONFIG.Colors.Secondary,
        Text = "›",
        TextColor3 = CONFIG.Colors.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Active = false,
        ZIndex = 6
    }, button)

    Corner(arrow, CONFIG.Radius.Small)

    button.Activated:Connect(function()
        Tween(button, 0.08, {
            BackgroundColor3 = CONFIG.Colors.Secondary
        })
        task.delay(0.08, function()
            if button and button.Parent then
                Tween(button, 0.12, {
                    BackgroundColor3 = CONFIG.Colors.Card
                })
            end
        end)
        if callback then
            task.spawn(function()
                local ok, err = pcall(callback)
                if not ok then
                    warn("[ADEX] Button error:", err)
                end
            end)
        end
    end)

    return {
        Button = button,
        Label = titleLabel,
        SetText = function(newText)
            titleLabel.Text = newText
        end
    }
end

local ToggleRegistry = {}

local function AddToggle(page, title, description, default, callback, noRegister)
    local state = default == true
    local height = description and 51 or 38

    local card = Create("Frame", {
        Size = UDim2.new(1, -3, 0, height),
        BackgroundColor3 = CONFIG.Colors.Card,
        BorderSizePixel = 0,
        ZIndex = 2
    }, page)

    Corner(card, CONFIG.Radius.Card)
    Stroke(card)

    Create("TextLabel", {
        Size = UDim2.new(1, -65, 0, 18),
        Position = UDim2.fromOffset(10, description and 5 or 10),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = CONFIG.Colors.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Active = false,
        ZIndex = 3
    }, card)

    if description then
        Create("TextLabel", {
            Size = UDim2.new(1, -65, 0, 16),
            Position = UDim2.fromOffset(10, 26),
            BackgroundTransparency = 1,
            Text = description,
            TextColor3 = CONFIG.Colors.SubText,
            Font = Enum.Font.Gotham,
            TextSize = 8,
            TextXAlignment = Enum.TextXAlignment.Left,
            Active = false,
            ZIndex = 3
        }, card)
    end

    local toggle = Create("TextButton", {
        Size = UDim2.fromOffset(38, 21),
        Position = UDim2.new(1, -48, 0.5, -10),
        BackgroundColor3 = state
            and CONFIG.Colors.Accent
            or CONFIG.Colors.Off,
        Text = "",
        AutoButtonColor = false,
        Active = true,
        Selectable = false,
        ZIndex = 5
    }, card)

    Corner(toggle, 20)

    local knob = Create("Frame", {
        Size = UDim2.fromOffset(15, 15),
        Position = state
            and UDim2.new(1, -18, 0.5, -7)
            or UDim2.fromOffset(3, 3),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Active = false,
        ZIndex = 6
    }, toggle)

    Corner(knob, 20)

    local function Set(value)
        state = value == true

        Tween(toggle, 0.15, {
            BackgroundColor3 = state
                and CONFIG.Colors.Accent
                or CONFIG.Colors.Off
        })

        Tween(knob, 0.15, {
            Position = state
                and UDim2.new(1, -18, 0.5, -7)
                or UDim2.fromOffset(3, 3)
        })

        if callback then
            task.spawn(function()
                local ok, err = pcall(callback, state)
                if not ok then
                    warn("[ADEX] Toggle error:", err)
                end
            end)
        end
    end

    toggle.Activated:Connect(function()
        Set(not state)
    end)

    local toggleObj = {
        Set = Set,
        Get = function() return state end,
        Frame = card
    }

    if not noRegister then
        ToggleRegistry[title] = toggleObj
    end

    return toggleObj
end

local function AddTextBox(page, title, description, placeholder, default, callback)
    local hasDesc = description ~= nil
    local height = hasDesc and 78 or 64

    local card = Create("Frame", {
        Size = UDim2.new(1, -3, 0, height),
        BackgroundColor3 = CONFIG.Colors.Card,
        BorderSizePixel = 0,
        ZIndex = 2
    }, page)

    Corner(card, CONFIG.Radius.Card)
    Stroke(card)

    Create("TextLabel", {
        Size = UDim2.new(1, -18, 0, 18),
        Position = UDim2.fromOffset(10, 5),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = CONFIG.Colors.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Active = false,
        ZIndex = 3
    }, card)

    if hasDesc then
        Create("TextLabel", {
            Size = UDim2.new(1, -18, 0, 14),
            Position = UDim2.fromOffset(10, 24),
            BackgroundTransparency = 1,
            Text = description,
            TextColor3 = CONFIG.Colors.SubText,
            Font = Enum.Font.Gotham,
            TextSize = 8,
            TextXAlignment = Enum.TextXAlignment.Left,
            Active = false,
            ZIndex = 3
        }, card)
    end

    local boxY = hasDesc and 42 or 27

    local box = Create("TextBox", {
        Size = UDim2.new(1, -20, 0, 28),
        Position = UDim2.fromOffset(10, boxY),
        BackgroundColor3 = CONFIG.Colors.Secondary,
        BorderSizePixel = 0,
        Text = default or "",
        PlaceholderText = placeholder or "Enter...",
        TextColor3 = CONFIG.Colors.Text,
        PlaceholderColor3 = CONFIG.Colors.SubText,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = 4
    }, card)

    Corner(box, CONFIG.Radius.Small)
    Stroke(box, CONFIG.Colors.Border, 1)

    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8)
    }, box)

    box.Focused:Connect(function()
        Tween(box, 0.15, {
            BackgroundColor3 = CONFIG.Colors.Background
        })
        Tween(box, 0.15, {
            TextColor3 = CONFIG.Colors.Accent
        })
    end)

    box.FocusLost:Connect(function()
        Tween(box, 0.15, {
            BackgroundColor3 = CONFIG.Colors.Secondary
        })
        Tween(box, 0.15, {
            TextColor3 = CONFIG.Colors.Text
        })
        if callback then
            task.spawn(function()
                local ok, err = pcall(callback, box.Text)
                if not ok then
                    warn("[ADEX] TextBox error:", err)
                end
            end)
        end
    end)

    return {
        Get = function() return box.Text end,
        Set = function(v) box.Text = v end,
        Box = box,
        Frame = card
    }
end

local ADEX_CleanupFunctions = {}

local function ADEX_RegisterCleanup(fn)
    if type(fn) == "function" then
        table.insert(ADEX_CleanupFunctions, fn)
    end
end

local function ADEX_AddKiller(conn)
    if conn then
        table.insert(_G.ADEX_HubKillers, conn)
    end
    return conn
end

local function ADEX_RunAllCleanups()
    for _, fn in ipairs(ADEX_CleanupFunctions) do
        pcall(fn)
    end
    ADEX_CleanupFunctions = {}
end

local SAVES_FOLDER = "ADEX_HUB_SAVES"
local SAVE_EXT = ".txt"
local META_FILE = "ADEX_HUB_META.txt"
local INDEX_FILE = "ADEX_HUB_INDEX.txt"

local SavesMemory = {}
local IndexMemory = {}

local SaveDataEnabled = false
local AutoLoadEnabled = false
local LastSaveName = ""

local function EnsureFolder()
    pcall(function()
        if isfolder and makefolder and not isfolder(SAVES_FOLDER) then
            makefolder(SAVES_FOLDER)
        end
    end)
end

local function SanitizeName(name)
    if type(name) ~= "string" then return "" end
    name = name:gsub("[^%w_%-]", "")
    return name
end

local function GetSavePath(name)
    return SAVES_FOLDER .. "/" .. name .. SAVE_EXT
end

local function ReadMetaFile()
    local meta = {}
    pcall(function()
        if isfile and isfile(META_FILE) and readfile then
            local content = readfile(META_FILE)
            for line in tostring(content):gmatch("[^\r\n]+") do
                local k, v = line:match("^(.+)=(.+)$")
                if k and v then
                    meta[k] = v
                end
            end
        elseif _G.ADEX_HubMeta then
            meta = _G.ADEX_HubMeta
        end
    end)
    return meta
end

local function WriteMetaFile(meta)
    local lines = {}
    for k, v in pairs(meta) do
        table.insert(lines, k .. "=" .. tostring(v))
    end
    local content = table.concat(lines, "\n")
    pcall(function()
        if writefile then
            writefile(META_FILE, content)
        else
            _G.ADEX_HubMeta = meta
        end
    end)
end

local function ReadIndexFile()
    local names = {}
    local seen = {}

    pcall(function()
        if isfile and isfile(INDEX_FILE) and readfile then
            local content = readfile(INDEX_FILE)
            for line in tostring(content):gmatch("[^\r\n]+") do
                local n = line:match("^%s*(.-)%s*$")
                if n and n ~= "" and not seen[n] then
                    seen[n] = true
                    table.insert(names, n)
                end
            end
        elseif _G.ADEX_SaveIndex then
            for _, n in ipairs(_G.ADEX_SaveIndex) do
                if not seen[n] then
                    seen[n] = true
                    table.insert(names, n)
                end
            end
        end
    end)

    for n in pairs(IndexMemory) do
        if not seen[n] then
            seen[n] = true
            table.insert(names, n)
        end
    end

    return names
end

local function WriteIndexFile(names)
    local content = table.concat(names, "\n")
    pcall(function()
        if writefile then
            writefile(INDEX_FILE, content)
        else
            _G.ADEX_SaveIndex = names
        end
    end)
end

local function AddToIndex(name)
    if type(name) ~= "string" or name == "" then return end
    IndexMemory[name] = true
    local names = ReadIndexFile()
    for _, n in ipairs(names) do
        if n == name then return end
    end
    table.insert(names, name)
    WriteIndexFile(names)
end

local function RemoveFromIndex(name)
    if type(name) ~= "string" or name == "" then return end
    IndexMemory[name] = nil
    local names = ReadIndexFile()
    local newNames = {}
    for _, n in ipairs(names) do
        if n ~= name then
            table.insert(newNames, n)
        end
    end
    WriteIndexFile(newNames)
end

local ADEX_InitialMeta = ReadMetaFile()

local function SerializeToggles()
    local lines = {}
    for name, toggle in pairs(ToggleRegistry) do
        if toggle and toggle.Get then
            table.insert(lines, name .. "=" .. tostring(toggle.Get()))
        end
    end
    return table.concat(lines, "\n")
end

local function SaveToName(name, content)
    EnsureFolder()
    local ok = pcall(function()
        if writefile then
            writefile(GetSavePath(name), content)
        else
            SavesMemory[name] = content
        end
    end)
    if ok then
        AddToIndex(name)
    end
    return ok
end

local function ReadFromName(name)
    local content
    pcall(function()
        if readfile and isfile and isfile(GetSavePath(name)) then
            content = readfile(GetSavePath(name))
        elseif SavesMemory[name] then
            content = SavesMemory[name]
        end
    end)
    return content
end

local function DeleteSave(name)
    if type(name) ~= "string" or name == "" then return false end
    local ok = pcall(function()
        if delfile and isfile and isfile(GetSavePath(name)) then
            delfile(GetSavePath(name))
        end
    end)
    SavesMemory[name] = nil
    RemoveFromIndex(name)
    return ok
end

local function ListSaveNames()
    local names = {}
    local seen = {}

    for _, n in ipairs(ReadIndexFile()) do
        if not seen[n] then
            seen[n] = true
            table.insert(names, n)
        end
    end

    pcall(function()
        if listfiles and isfolder and isfolder(SAVES_FOLDER) then
            local files = listfiles(SAVES_FOLDER)
            for _, file in ipairs(files) do
                local name = file:match("([^/\\]+)%.txt$")
                if name and not seen[name] then
                    seen[name] = true
                    table.insert(names, name)
                end
            end
        end
    end)

    for name in pairs(SavesMemory) do
        if not seen[name] then
            seen[name] = true
            table.insert(names, name)
        end
    end

    table.sort(names)
    return names
end

local function ApplySaveContent(content)
    if not content or content == "" then
        return 0
    end

    local loaded = 0
    for line in tostring(content):gmatch("[^\r\n]+") do
        local key, val = line:match("^(.+)=(.+)$")
        if key and val then
            local toggle = ToggleRegistry[key]
            if toggle and toggle.Set then
                pcall(function()
                    toggle.Set(val == "true")
                end)
                loaded = loaded + 1
            end
        end
    end
    return loaded
end

local Home = CreateTab("Home", "⌂")
local Visuals = CreateTab("Visuals", "◉")
local PlayerTab = CreateTab("Player", "●")
local Settings = CreateTab("Settings", "⚙")

AddSection(Home, "WELCOME")
AddLabel(Home, "ADEX MODERN HUB", "Compact • Responsive • Android + PC")

AddSection(Home, "STATUS SCRIPT")
local StatusCard = AddStatusLabel(Home, "Script Status")
StatusCard.SetStatus(true)

AddSection(Visuals, "VISUAL FEATURES")
AddButton(Visuals, "Refresh", "Refresh fitur.", function()
    print("Refresh")
end)

local ADEX_EspBodyLoaded = false
local ADEX_EspBodyEnabled = false
local ADEX_EspBodyToggle = nil

ADEX_EspBodyToggle = AddToggle(Visuals, "Esp Body", "Killer (Merah) / Survivor (Biru).", false, function(enabled)
    ADEX_EspBodyEnabled = enabled

    if enabled and not ADEX_EspBodyLoaded then
        ADEX_EspBodyLoaded = true

        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer

        local COLORS = {
            Killer = Color3.fromRGB(255, 45, 45),
            Survivor = Color3.fromRGB(45, 140, 255),
            Unknown = Color3.fromRGB(180, 180, 180)
        }

        local function NormalizeRole(value)
            if value == nil then
                return nil
            end

            local role = string.lower(tostring(value))
            role = role:gsub("%s+", "")

            if role == "killer"
            or role == "killers" then
                return "Killer"
            end

            if role == "survivor"
            or role == "survivors" then
                return "Survivor"
            end

            return nil
        end

        local function ReadValue(object)
            if not object then
                return nil
            end

            if object:IsA("StringValue")
            or object:IsA("ObjectValue")
            or object:IsA("IntValue")
            or object:IsA("NumberValue") then
                return object.Value
            end

            return nil
        end

        local function GetRole(player)
            if player.Team then
                local role = NormalizeRole(player.Team.Name)
                if role then
                    return role
                end
            end

            local attributeRole = player:GetAttribute("Role")
            local role = NormalizeRole(attributeRole)

            if role then
                return role
            end

            local roleObject = player:FindFirstChild("Role")
            role = NormalizeRole(ReadValue(roleObject))

            if role then
                return role
            end

            local leaderstats = player:FindFirstChild("leaderstats")

            if leaderstats then
                local leaderRole = leaderstats:FindFirstChild("Role")

                role = NormalizeRole(ReadValue(leaderRole))

                if role then
                    return role
                end
            end

            local character = player.Character

            if character then
                local characterRole = character:FindFirstChild("Role")

                role = NormalizeRole(ReadValue(characterRole))

                if role then
                    return role
                end

                role = NormalizeRole(character:GetAttribute("Role"))

                if role then
                    return role
                end
            end

            return "Unknown"
        end

        local function UpdateESP(player)
            if player == LocalPlayer then
                return
            end

            local character = player.Character
            if not character then
                return
            end

            local esp = character:FindFirstChild("ADEX_BodyESP")

            if not esp then
                esp = Instance.new("Highlight")
                esp.Name = "ADEX_BodyESP"
                esp.Adornee = character
                esp.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                esp.FillTransparency = 0.55
                esp.OutlineTransparency = 0
                esp.Parent = character
            end

            local role = GetRole(player)
            local color = COLORS.Unknown

            if role == "Killer" then
                color = COLORS.Killer
            elseif role == "Survivor" then
                color = COLORS.Survivor
            end

            esp.FillColor = color
            esp.OutlineColor = color

            esp:SetAttribute("DetectedRole", role)
        end

        local function SetupPlayer(player)
            if player == LocalPlayer then
                return
            end

            player.CharacterAdded:Connect(function()
                task.wait(0.5)
                UpdateESP(player)
            end)

            player:GetPropertyChangedSignal("Team"):Connect(function()
                UpdateESP(player)
            end)

            player:GetAttributeChangedSignal("Role"):Connect(function()
                UpdateESP(player)
            end)

            task.spawn(function()
                while player.Parent do
                    UpdateESP(player)
                    task.wait(1)
                end
            end)

            if player.Character then
                UpdateESP(player)
            end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            SetupPlayer(player)
        end

        Players.PlayerAdded:Connect(SetupPlayer)

        local espBodyConn
        espBodyConn = RunService.Heartbeat:Connect(function()
            if not GUI or not GUI.Parent then
                if espBodyConn then
                    espBodyConn:Disconnect()
                    espBodyConn = nil
                end
                return
            end

            local fill = ADEX_EspBodyEnabled and 0.55 or 1
            local outline = ADEX_EspBodyEnabled and 0 or 1

            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then
                    local esp = p.Character:FindFirstChild("ADEX_BodyESP")
                    if esp then
                        esp.FillTransparency = fill
                        esp.OutlineTransparency = outline
                    end
                end
            end
        end)

        ADEX_RegisterCleanup(function()
            if ADEX_EspBodyToggle then ADEX_EspBodyToggle.Set(false) end
            ADEX_EspBodyEnabled = false

            if espBodyConn then
                pcall(function() espBodyConn:Disconnect() end)
                espBodyConn = nil
            end

            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then
                    local esp = p.Character:FindFirstChild("ADEX_BodyESP")
                    if esp then
                        pcall(function() esp:Destroy() end)
                    end
                end
            end
        end)
    end
end)

local ADEX_CrosshairLoaded = false
local ADEX_CrosshairEnabled = false
local ADEX_CrosshairGui = nil
local ADEX_CrosshairToggle = nil

ADEX_CrosshairToggle = AddToggle(Visuals, "Crosshair", "Titik crosshair di tengah layar.", false, function(enabled)
    ADEX_CrosshairEnabled = enabled

    if enabled and not ADEX_CrosshairLoaded then
        ADEX_CrosshairLoaded = true

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local Player = Players.LocalPlayer
        local PlayerGui = Player:WaitForChild("PlayerGui")

        local GUI_NAME = "ADEX_DotCrosshair"

        local function CreateCrosshair()
            local old = PlayerGui:FindFirstChild(GUI_NAME)
            if old then
                old:Destroy()
            end

            local gui = Instance.new("ScreenGui")
            gui.Name = GUI_NAME
            gui.ResetOnSpawn = false
            gui.IgnoreGuiInset = true
            gui.DisplayOrder = 999999
            gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
            gui.Enabled = true
            gui.Parent = PlayerGui

            local dot = Instance.new("Frame")
            dot.Name = "Dot"
            dot.Size = UDim2.fromOffset(4, 4)
            dot.AnchorPoint = Vector2.new(0.5, 0.5)
            dot.Position = UDim2.fromScale(0.5, 0.5)

            dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            dot.BackgroundTransparency = 0
            dot.BorderSizePixel = 0

            dot.Visible = true
            dot.ZIndex = 999999
            dot.Parent = gui

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = dot

            return gui, dot
        end

        local gui, dot = CreateCrosshair()

        local checkTimer = 0

        RunService.RenderStepped:Connect(function(dt)

            checkTimer += dt

            if checkTimer < 0.25 then
                return
            end

            checkTimer = 0

            if not gui
                or not gui.Parent
                or not PlayerGui:FindFirstChild(GUI_NAME) then

                gui, dot = CreateCrosshair()
                return
            end

            if gui.Enabled == false then
                gui.Enabled = true
            end

            if not dot
                or not dot.Parent then

                dot = Instance.new("Frame")
                dot.Name = "Dot"
                dot.Size = UDim2.fromOffset(4, 4)
                dot.AnchorPoint = Vector2.new(0.5, 0.5)
                dot.Position = UDim2.fromScale(0.5, 0.5)
                dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                dot.BorderSizePixel = 0
                dot.Visible = true
                dot.ZIndex = 999999
                dot.Parent = gui

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(1, 0)
                corner.Parent = dot
            end

            dot.Visible = true
            dot.Position = UDim2.fromScale(0.5, 0.5)
        end)

        Player.CharacterAdded:Connect(function()

            task.wait(0.2)

            if not PlayerGui:FindFirstChild(GUI_NAME) then
                gui, dot = CreateCrosshair()
            else
                gui = PlayerGui:FindFirstChild(GUI_NAME)
                gui.Enabled = true

                dot = gui:FindFirstChild("Dot")

                if dot then
                    dot.Visible = true
                end
            end
        end)

        PlayerGui.ChildRemoved:Connect(function(child)

            if child.Name == GUI_NAME then
                task.wait()

                gui, dot = CreateCrosshair()
            end
        end)

        ADEX_CrosshairGui = gui

        ADEX_RegisterCleanup(function()
            if ADEX_CrosshairToggle then ADEX_CrosshairToggle.Set(false) end
            ADEX_CrosshairEnabled = false

            pcall(function()
                local lp = game:GetService("Players").LocalPlayer
                if not lp then return end
                local pgui = lp:FindFirstChildOfClass("PlayerGui")
                if not pgui then return end
                local g = pgui:FindFirstChild("ADEX_DotCrosshair")
                if not g then return end
                local d = g:FindFirstChild("Dot")
                if d then
                    d.BackgroundTransparency = 1
                    d.Visible = false
                end
                g.Enabled = false
            end)

            pcall(function()
                RunService:UnbindFromRenderStep("ADEX_CrosshairKiller")
            end)
            pcall(function()
                RunService:BindToRenderStep("ADEX_CrosshairKiller", Enum.RenderPriority.Last.Value, function()
                    if not GUI or not GUI.Parent then
                        pcall(function()
                            RunService:UnbindFromRenderStep("ADEX_CrosshairKiller")
                        end)
                        return
                    end

                    local lp = game:GetService("Players").LocalPlayer
                    if not lp then return end
                    local pgui = lp:FindFirstChildOfClass("PlayerGui")
                    if not pgui then return end
                    local g = pgui:FindFirstChild("ADEX_DotCrosshair")
                    if not g then return end
                    local d = g:FindFirstChild("Dot")
                    if d then
                        if d.BackgroundTransparency < 1 then
                            d.BackgroundTransparency = 1
                        end
                        if d.Visible then
                            d.Visible = false
                        end
                    end
                end)
            end)
        end)
    end
end)

local ADEX_NicknameLoaded = false
local ADEX_NicknameEnabled = false
local ADEX_NicknameToggle = nil

ADEX_NicknameToggle = AddToggle(Visuals, "Esp Nickname", "Nama pemain • Small • Clean • Distance.", false, function(enabled)
    ADEX_NicknameEnabled = enabled

    if enabled and not ADEX_NicknameLoaded then
        ADEX_NicknameLoaded = true

        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer

        local MAX_DISTANCE = 1000

        local function CreateNicknameESP(player)

            if player == LocalPlayer then
                return
            end

            local function Setup(character)

                local head = character:WaitForChild("Head", 5)

                if not head then
                    return
                end

                local old = head:FindFirstChild("ADEX_NicknameESP")

                if old then
                    old:Destroy()
                end

                local billboard = Instance.new("BillboardGui")

                billboard.Name = "ADEX_NicknameESP"
                billboard.Adornee = head

                billboard.Size = UDim2.fromOffset(120, 22)

                billboard.StudsOffset = Vector3.new(0, 2.5, 0)

                billboard.AlwaysOnTop = true
                billboard.MaxDistance = MAX_DISTANCE

                billboard.Parent = head

                local label = Instance.new("TextLabel")

                label.Name = "Nickname"

                label.Size = UDim2.fromScale(1, 1)

                label.BackgroundTransparency = 1

                label.Text = player.DisplayName

                label.TextSize = 13

                label.Font = Enum.Font.GothamMedium

                label.TextColor3 = Color3.fromRGB(255, 255, 255)

                label.TextStrokeTransparency = 0.25
                label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

                label.TextXAlignment = Enum.TextXAlignment.Center
                label.TextYAlignment = Enum.TextYAlignment.Center

                label.Parent = billboard
            end

            if player.Character then
                Setup(player.Character)
            end

            player.CharacterAdded:Connect(function(character)
                Setup(character)
            end)
        end

        for _, player in ipairs(Players:GetPlayers()) do
            CreateNicknameESP(player)
        end

        Players.PlayerAdded:Connect(function(player)
            CreateNicknameESP(player)
        end)

        pcall(function()
            RunService:UnbindFromRenderStep("ADEX_NicknameKiller")
        end)
        pcall(function()
            RunService:BindToRenderStep("ADEX_NicknameKiller", Enum.RenderPriority.Last.Value, function()
                if not GUI or not GUI.Parent then
                    pcall(function()
                        RunService:UnbindFromRenderStep("ADEX_NicknameKiller")
                    end)
                    return
                end

                if ADEX_NicknameEnabled then
                    return
                end
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character then
                        local head = p.Character:FindFirstChild("Head")
                        if head then
                            local billboard = head:FindFirstChild("ADEX_NicknameESP")
                            if billboard and billboard.Enabled then
                                billboard.Enabled = false
                            end
                        end
                    end
                end
            end)
        end)

        ADEX_RegisterCleanup(function()
            if ADEX_NicknameToggle then ADEX_NicknameToggle.Set(false) end
            ADEX_NicknameEnabled = false

            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then
                    local head = p.Character:FindFirstChild("Head")
                    if head then
                        local bb = head:FindFirstChild("ADEX_NicknameESP")
                        if bb then
                            pcall(function() bb:Destroy() end)
                        end
                    end
                end
            end
        end)
    end
end)

local ADEX_GeneratorLoaded = false
local ADEX_GeneratorEnabled = false
local ADEX_GeneratorToggle = nil

ADEX_GeneratorToggle = AddToggle(Visuals, "Esp Generator", "Repair Progress • Persentase generator.", false, function(enabled)
    ADEX_GeneratorEnabled = enabled

    if enabled and not ADEX_GeneratorLoaded then
        ADEX_GeneratorLoaded = true

        local Workspace = game:GetService("Workspace")

        local MAX_DISTANCE = 1000
        local VALUE_NAME = "RepairProgress"

        local PERCENT_TEXT_SIZE = 14

        local PERCENT_HEIGHT = 4

        local function FormatPercent(value)
            value = tonumber(value)

            if not value then
                return nil
            end

            return math.clamp(math.floor(value + 0.5), 0, 100)
        end

        local function GetPart(generator)

            if generator:IsA("BasePart") then
                return generator
            end

            if generator:IsA("Model") then
                return generator.PrimaryPart
                    or generator:FindFirstChildWhichIsA("BasePart", true)
            end

            return nil
        end

        local function FindRepairProgress(generator)

            local value = generator:FindFirstChild(VALUE_NAME, true)

            if value and value:IsA("ValueBase") then
                return value, "Value"
            end

            if generator:GetAttribute(VALUE_NAME) ~= nil then
                return generator, "Attribute"
            end

            for _, object in ipairs(generator:GetDescendants()) do

                if object:GetAttribute(VALUE_NAME) ~= nil then
                    return object, "Attribute"
                end

            end

            return nil
        end

        local function CreateESP(generator)

            local part = GetPart(generator)

            if not part then
                return
            end

            if part:FindFirstChild("ADEX_GeneratorESP") then
                return
            end

            local progress, source = FindRepairProgress(generator)

            if not progress then
                return
            end

            local highlight = Instance.new("Highlight")

            highlight.Name = "ADEX_GeneratorESP"
            highlight.Adornee = generator

            highlight.FillColor = Color3.fromRGB(255, 190, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)

            highlight.FillTransparency = 0.55
            highlight.OutlineTransparency = 0

            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

            highlight.Parent = part

            local billboard = Instance.new("BillboardGui")

            billboard.Name = "ADEX_GeneratorPercent"
            billboard.Adornee = part

            billboard.Size = UDim2.fromOffset(120, 25)

            billboard.StudsOffset = Vector3.new(0, PERCENT_HEIGHT, 0)

            billboard.AlwaysOnTop = true
            billboard.MaxDistance = MAX_DISTANCE

            billboard.Parent = part

            local label = Instance.new("TextLabel")

            label.Name = "Percentage"

            label.Size = UDim2.fromScale(1, 1)

            label.BackgroundTransparency = 1

            label.Text = "0%"

            label.TextSize = PERCENT_TEXT_SIZE

            label.Font = Enum.Font.GothamBold

            label.TextColor3 = Color3.fromRGB(255, 80, 70)

            label.TextStrokeTransparency = 0
            label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

            label.TextXAlignment = Enum.TextXAlignment.Center
            label.TextYAlignment = Enum.TextYAlignment.Center

            label.Parent = billboard

            local function Update()

                local rawValue

                if source == "Value" then
                    rawValue = progress.Value
                else
                    rawValue = progress:GetAttribute(VALUE_NAME)
                end

                local percent = FormatPercent(rawValue)

                if percent == nil then
                    label.Text = "0%"
                    return
                end

                label.Text = percent .. "%"

                if percent >= 100 then

                    label.TextColor3 = Color3.fromRGB(
                        50, 255, 100
                    )

                elseif percent >= 50 then

                    label.TextColor3 = Color3.fromRGB(
                        255, 220, 50
                    )

                else

                    label.TextColor3 = Color3.fromRGB(
                        255, 80, 70
                    )

                end
            end

            Update()

            if source == "Value" then

                progress:GetPropertyChangedSignal("Value"):Connect(Update)

            else

                progress:GetAttributeChangedSignal(VALUE_NAME):Connect(Update)

            end
        end

        for _, object in ipairs(Workspace:GetDescendants()) do

            if object.Name == "Generator" then
                CreateESP(object)
            end

        end

        Workspace.DescendantAdded:Connect(function(object)

            if object.Name == "Generator" then

                task.wait(0.2)

                CreateESP(object)

            end

        end)

        pcall(function()
            RunService:UnbindFromRenderStep("ADEX_GeneratorKiller")
        end)
        pcall(function()
            RunService:BindToRenderStep("ADEX_GeneratorKiller", Enum.RenderPriority.Last.Value, function()
                if not GUI or not GUI.Parent then
                    pcall(function()
                        RunService:UnbindFromRenderStep("ADEX_GeneratorKiller")
                    end)
                    return
                end

                if ADEX_GeneratorEnabled then
                    return
                end
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj.Name == "ADEX_GeneratorESP" or obj.Name == "ADEX_GeneratorPercent" then
                        if obj:IsA("Highlight") or obj:IsA("BillboardGui") then
                            obj.Enabled = false
                        end
                    end
                end
            end)
        end)

        ADEX_RegisterCleanup(function()
            if ADEX_GeneratorToggle then ADEX_GeneratorToggle.Set(false) end
            ADEX_GeneratorEnabled = false

            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj.Name == "ADEX_GeneratorESP" or obj.Name == "ADEX_GeneratorPercent" then
                    pcall(function() obj:Destroy() end)
                end
            end
        end)
    end
end)

local ADEX_AutoGenLoaded = false
local ADEX_AutoGenEnabled = false
local ADEX_AutoGenToggle = nil
local ADEX_AutoGenModeBtn = nil
local ADEX_AutoGenSetEnabled = nil
local ADEX_AutoGenCycleMode = nil
local ADEX_AutoGenGetMode = nil

ADEX_AutoGenToggle = AddToggle(Visuals, "Auto Generator", "Auto skill check (Normal + King Scourge).", false, function(enabled)
    ADEX_AutoGenEnabled = enabled

    if ADEX_AutoGenSetEnabled then
        ADEX_AutoGenSetEnabled(enabled)
    end

    if enabled and not ADEX_AutoGenLoaded then
        ADEX_AutoGenLoaded = true

        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local RunService = game:GetService("RunService")
        local UserInputService = game:GetService("UserInputService")

        local LocalPlayer = Players.LocalPlayer
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

        local Enabled = false
        local Mode = "SUCCESS"

        local SUCCESS_MIN = 102
        local SUCCESS_MAX = 116

        local NEUTRAL_MIN = 116
        local NEUTRAL_MAX = 159

        local TriggerDelay = 0.035
        local LastTrigger = 0

        local Busy = false
        local ScourgeActive = false
        local ScourgeRound = 0

        local KingScourgeStart
        local KingScourgeEnd

        pcall(function()

            local KillerPerks =
                ReplicatedStorage:WaitForChild("Remotes")
                    :WaitForChild("KillerPerks")

            local KingScourge =
                KillerPerks:WaitForChild("kingscourge")

            KingScourgeStart =
                KingScourge:WaitForChild("KingScourgeStart")

            KingScourgeEnd =
                KingScourge:WaitForChild("KingScourgeEnd")

        end)

        local ScreenGui = GUI

        local Check
        local Line
        local Goal
        local Action

        local function RefreshReferences()

            pcall(function()

                local SkillGui =
                    PlayerGui:FindFirstChild("SkillCheckPromptGui")

                if SkillGui then

                    Check =
                        SkillGui:FindFirstChild("Check")

                    if Check then

                        Line =
                            Check:FindFirstChild("Line")

                        Goal =
                            Check:FindFirstChild("Goal")

                    end

                end

                local Survivor =
                    PlayerGui:FindFirstChild("Survivor-mob")

                if Survivor then

                    local Controls =
                        Survivor:FindFirstChild("Controls")

                    if Controls then
                        Action =
                            Controls:FindFirstChild("action")
                    end

                end

            end)

        end

        RefreshReferences()

        task.spawn(function()

            while ScreenGui.Parent do

                RefreshReferences()

                task.wait(0.5)

            end

        end)

        local function TriggerAction()

            if not Action then
                RefreshReferences()
            end

            if not Action then
                return false
            end

            local Now = os.clock()

            if Now - LastTrigger < TriggerDelay then
                return false
            end

            LastTrigger = Now

            pcall(function()

                if Action:IsA("GuiButton") then
                    Action:Activate()
                end

            end)

            if typeof(firesignal) == "function" then

                pcall(function()
                    firesignal(Action.MouseButton1Down)
                end)

            end

            return true
        end

        local function GetAngle()

            if not Line or not Goal then
                return nil
            end

            return
                tonumber(Line.Rotation) or 0,
                tonumber(Goal.Rotation) or 0

        end

        local function IsSuccess()

            local LineRotation, GoalRotation =
                GetAngle()

            if not LineRotation then
                return false
            end

            local Min =
                GoalRotation + SUCCESS_MIN

            local Max =
                GoalRotation + SUCCESS_MAX

            return
                LineRotation >= Min
                and
                LineRotation <= Max

        end

        local function IsNeutral()

            local LineRotation, GoalRotation =
                GetAngle()

            if not LineRotation then
                return false
            end

            local Min =
                GoalRotation + NEUTRAL_MIN

            local Max =
                GoalRotation + NEUTRAL_MAX

            return
                LineRotation > Min
                and
                LineRotation <= Max

        end

        local function InstantNormal()

            if not Check or not Line or not Goal then
                RefreshReferences()
            end

            if not Check or not Line or not Goal then
                return
            end

            if not Check.Visible then
                return
            end

            local GoalRotation =
                tonumber(Goal.Rotation) or 0

            Line.Rotation =
                GoalRotation + 109

            TriggerAction()

        end

        local function InstantScourge()

            if not Enabled then
                return
            end

            if not ScourgeActive then
                return
            end

            if not Line or not Goal then
                RefreshReferences()
            end

            if not Line or not Goal then
                return
            end

            local GoalRotation =
                tonumber(Goal.Rotation) or 0

            Line.Rotation =
                GoalRotation + 109

            TriggerAction()

            ScourgeRound += 1

        end

        if KingScourgeStart then

            KingScourgeStart.OnClientEvent:Connect(
                function(p1,p2,p3)

                    if not Enabled then
                        return
                    end

                    ScourgeActive = true
                    ScourgeRound = 0
                    Busy = false

                    task.defer(function()

                        if not Enabled then
                            return
                        end

                        if Mode == "INSTANT" then

                            InstantScourge()

                        end

                    end)

                end
            )

        end

        if KingScourgeEnd then

            KingScourgeEnd.OnClientEvent:Connect(
                function(p)

                    ScourgeActive = false
                    Busy = false

                end
            )

        end

        local PreviousVisible = false

        local autoGenConn
        autoGenConn = RunService.RenderStepped:Connect(function()

            if not GUI or not GUI.Parent then
                if autoGenConn then
                    autoGenConn:Disconnect()
                    autoGenConn = nil
                end
                return
            end

            if not Enabled then

                PreviousVisible = false

                return
            end

            if not Check then
                RefreshReferences()
            end

            if not Check then
                return
            end

            local Visible =
                Check.Visible

            if Visible and not PreviousVisible then

                Busy = false

                if not ScourgeActive then

                    if Mode == "INSTANT" then

                        InstantNormal()

                    end

                end

            end

            PreviousVisible =
                Visible

            if Visible and not ScourgeActive then

                if not Busy then

                    local ShouldTrigger = false

                    if Mode == "SUCCESS" then

                        ShouldTrigger =
                            IsSuccess()

                    elseif Mode == "NEUTRAL" then

                        ShouldTrigger =
                            IsNeutral()

                    end

                    if ShouldTrigger then

                        Busy = true

                        TriggerAction()

                        task.delay(0.07,function()

                            Busy = false

                        end)

                    end

                end

            end

            if ScourgeActive and Visible then

                if Mode == "SUCCESS" then

                    if not Busy and IsSuccess() then

                        Busy = true

                        TriggerAction()

                        task.delay(0.06,function()
                            Busy = false
                        end)

                    end

                elseif Mode == "NEUTRAL" then

                    if not Busy and IsNeutral() then

                        Busy = true

                        TriggerAction()

                        task.delay(0.06,function()
                            Busy = false
                        end)

                    end

                elseif Mode == "INSTANT" then

                    local CurrentGoal =
                        tonumber(Goal.Rotation) or 0

                    local CurrentLine =
                        tonumber(Line.Rotation) or 0

                    local Distance =
                        math.abs(CurrentLine - CurrentGoal)

                    if Distance > 130 then

                        Busy = false

                    end

                end

            end

        end)

        local goalDetectorConn
        goalDetectorConn = task.spawn(function()

            local LastGoalRotation = nil

            while GUI and GUI.Parent do

                if Enabled
                    and ScourgeActive
                    and Mode == "INSTANT" then

                    RefreshReferences()

                    if Check
                        and Check.Visible
                        and Goal
                        and Line then

                        local CurrentGoal =
                            tonumber(Goal.Rotation) or 0

                        if LastGoalRotation == nil then

                            LastGoalRotation =
                                CurrentGoal

                            InstantScourge()

                        elseif
                            math.abs(
                                CurrentGoal -
                                LastGoalRotation
                            ) > 1 then

                            LastGoalRotation =
                                CurrentGoal

                            InstantScourge()

                        end

                    end

                else

                    LastGoalRotation = nil

                end

                task.wait(0.005)

            end

        end)

        local function UpdateUI()

            if ADEX_AutoGenModeBtn then
                if Enabled then
                    ADEX_AutoGenModeBtn.SetText("Mode : " .. Mode)
                else
                    ADEX_AutoGenModeBtn.SetText("Mode : " .. Mode)
                end
            end

        end

        ADEX_AutoGenSetEnabled = function(v)
            Enabled = v
            Busy = false
            if not Enabled then
                ScourgeActive = false
            end
            UpdateUI()
        end

        ADEX_AutoGenGetMode = function()
            return Mode
        end

        local Modes = {
            "SUCCESS",
            "NEUTRAL",
            "INSTANT"
        }

        local ModeIndex = 1

        ADEX_AutoGenCycleMode = function()
            ModeIndex += 1

            if ModeIndex > #Modes then
                ModeIndex = 1
            end

            Mode = Modes[ModeIndex]

            Busy = false

            UpdateUI()
        end

        LocalPlayer.CharacterAdded:Connect(function()

            Busy = false
            ScourgeActive = false
            PreviousVisible = false

            task.wait(1)

            RefreshReferences()

        end)

        UpdateUI()

        if ADEX_AutoGenEnabled then
            Enabled = true
            UpdateUI()
        end

        ADEX_RegisterCleanup(function()
            if ADEX_AutoGenToggle then ADEX_AutoGenToggle.Set(false) end
            ADEX_AutoGenEnabled = false
            Enabled = false
            ScourgeActive = false
            Busy = false

            if autoGenConn then
                pcall(function() autoGenConn:Disconnect() end)
                autoGenConn = nil
            end
        end)

        print("ABCD")
        print("AUTO GENERATOR v3")
        print("NORMAL SKILLCHECK : ENABLED")
        print("KING SCOURGE       : ENABLED")
        print("SUCCESS            : 102° - 116°")
        print("NEUTRAL            : 116° - 159°")
        print("INSTANT            : 109°")
        print("ACTION TRIGGER     : ORIGINAL")
        print("==========================================")
    end
end)

ADEX_AutoGenModeBtn = AddButton(Visuals, "Mode : SUCCESS", "Ganti mode auto generator.", function()
    if ADEX_AutoGenCycleMode then
        ADEX_AutoGenCycleMode()
    end
end)

AddSection(PlayerTab, "PLAYER FEATURES")
AddToggle(PlayerTab, "Feature A", "Tempat fitur player.", false, function(v)
    print("Feature A:", v)
end)
AddToggle(PlayerTab, "Feature B", "Fitur player lainnya.", false, function(v)
    print("Feature B:", v)
end)

AddSection(Settings, "INTERFACE")
AddButton(Settings, "Reset Position", "Kembalikan UI ke tengah.", function()
    Main.Position = UDim2.fromScale(0.5, 0.5)
    ClampInside(Main)

    FloatingLogo.Position = UDim2.fromScale(0.5, 0.5)
    ClampInside(FloatingLogo)
end)

AddLabel(Settings, "Keybind", "RightShift = Minimize / Restore")

AddSection(Settings, "SAVE SYSTEM")

SaveDataEnabled = (ADEX_InitialMeta.SaveData == "true")
AutoLoadEnabled = (ADEX_InitialMeta.AutoLoad == "true")
LastSaveName = ADEX_InitialMeta.LastSaveName or ""

AddToggle(Settings, "Save Data", "Aktifkan fitur simpan data.", SaveDataEnabled, function(v)
    SaveDataEnabled = v
    local meta = ReadMetaFile()
    meta.SaveData = tostring(v)
    WriteMetaFile(meta)
end, true)

AddToggle(Settings, "Auto Load", "Auto load save terakhir saat script dibuka.", AutoLoadEnabled, function(v)
    AutoLoadEnabled = v
    local meta = ReadMetaFile()
    meta.AutoLoad = tostring(v)
    WriteMetaFile(meta)
end, true)

local SaveNameBox = AddTextBox(
    Settings,
    "Save Name",
    "Masukkan nama untuk save slot.",
    "e.g. config1",
    LastSaveName,
    nil
)

AddButton(Settings, "Save", "Simpan semua toggle dengan nama di atas.", function()
    if not SaveDataEnabled then
        warn("[ADEX SAVE] Aktifkan 'Save Data' dulu!")
        return
    end

    local raw = SaveNameBox.Get()
    local name = SanitizeName(raw)

    if name == "" then
        warn("[ADEX SAVE] Nama save tidak valid!")
        return
    end

    local content = SerializeToggles()
    local ok = SaveToName(name, content)

    if ok then
        LastSaveName = name
        SaveNameBox.Set(name)
        local meta = ReadMetaFile()
        meta.LastSaveName = name
        WriteMetaFile(meta)
        print("[ADEX SAVE] Tersimpan: " .. name)
    else
        print("[ADEX SAVE] Gagal menyimpan: " .. name)
    end
end)

local ListSavePanel = Create("Frame", {
    Name = "ListSavePanel",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 210
}, GUI)

local LSP_Card = Create("Frame", {
    Name = "Card",
    Size = UDim2.fromOffset(320, 380),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = CONFIG.Colors.Secondary,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 211
}, ListSavePanel)

Corner(LSP_Card, CONFIG.Radius.Outer)
Stroke(LSP_Card, CONFIG.Colors.Border, 1)

Create("Frame", {
    Name = "TopAccent",
    Size = UDim2.new(1, 0, 0, 3),
    BackgroundColor3 = CONFIG.Colors.Accent,
    BorderSizePixel = 0,
    ZIndex = 212
}, LSP_Card)

Create("TextLabel", {
    Name = "Title",
    Size = UDim2.new(1, -60, 0, 22),
    Position = UDim2.fromOffset(16, 14),
    BackgroundTransparency = 1,
    Text = "List Save",
    TextColor3 = CONFIG.Colors.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 213
}, LSP_Card)

local LSP_Subtitle = Create("TextLabel", {
    Name = "Subtitle",
    Size = UDim2.new(1, -60, 0, 14),
    Position = UDim2.fromOffset(16, 34),
    BackgroundTransparency = 1,
    Text = "Klik untuk load • X untuk hapus",
    TextColor3 = CONFIG.Colors.SubText,
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 213
}, LSP_Card)

local LSP_CloseBtn = Create("TextButton", {
    Name = "CloseBtn",
    Size = UDim2.fromOffset(28, 28),
    Position = UDim2.new(1, -36, 0, 12),
    BackgroundColor3 = CONFIG.Colors.Card,
    BorderSizePixel = 0,
    Text = "×",
    TextColor3 = CONFIG.Colors.Danger,
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    AutoButtonColor = false,
    Active = true,
    Selectable = false,
    ZIndex = 214
}, LSP_Card)

Corner(LSP_CloseBtn, CONFIG.Radius.Small)
Stroke(LSP_CloseBtn, CONFIG.Colors.Border, 1)

Create("Frame", {
    Name = "Divider",
    Size = UDim2.new(1, -32, 0, 1),
    Position = UDim2.fromOffset(16, 58),
    BackgroundColor3 = CONFIG.Colors.Border,
    BorderSizePixel = 0,
    ZIndex = 212
}, LSP_Card)

local LSP_Scroll = Create("ScrollingFrame", {
    Name = "ListScroll",
    Size = UDim2.new(1, -32, 1, -110),
    Position = UDim2.fromOffset(16, 68),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = CONFIG.Colors.Accent,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ZIndex = 213
}, LSP_Card)

Create("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder
}, LSP_Scroll)

local LSP_EmptyLabel = Create("TextLabel", {
    Name = "EmptyLabel",
    Size = UDim2.new(1, 0, 0, 60),
    BackgroundTransparency = 1,
    Text = "Belum ada save tersimpan.\nGunakan tombol Save untuk membuat.",
    TextColor3 = CONFIG.Colors.SubText,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center,
    Visible = false,
    ZIndex = 214
}, LSP_Scroll)

local LSP_RefreshBtn = Create("TextButton", {
    Name = "RefreshBtn",
    Size = UDim2.new(0.5, -20, 0, 32),
    Position = UDim2.new(0, 16, 1, -44),
    BackgroundColor3 = CONFIG.Colors.Card,
    BorderSizePixel = 0,
    Text = "Refresh",
    TextColor3 = CONFIG.Colors.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    AutoButtonColor = false,
    Active = true,
    Selectable = false,
    ZIndex = 214
}, LSP_Card)

Corner(LSP_RefreshBtn, CONFIG.Radius.Small)
Stroke(LSP_RefreshBtn, CONFIG.Colors.Border, 1)

local LSP_DeleteAllBtn = Create("TextButton", {
    Name = "DeleteAllBtn",
    Size = UDim2.new(0.5, -20, 0, 32),
    Position = UDim2.new(0.5, 4, 1, -44),
    BackgroundColor3 = CONFIG.Colors.Card,
    BorderSizePixel = 0,
    Text = "Delete All",
    TextColor3 = CONFIG.Colors.Danger,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    AutoButtonColor = false,
    Active = true,
    Selectable = false,
    ZIndex = 214
}, LSP_Card)

Corner(LSP_DeleteAllBtn, CONFIG.Radius.Small)
Stroke(LSP_DeleteAllBtn, CONFIG.Colors.Border, 1)

local listSaveOpen = false

local function RefreshListSaveUI()
    for _, child in ipairs(LSP_Scroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local names = ListSaveNames()

    if #names == 0 then
        LSP_EmptyLabel.Visible = true
        LSP_EmptyLabel.Parent = LSP_Scroll
        LSP_Subtitle.Text = "Belum ada save"
        return
    end

    LSP_EmptyLabel.Visible = false
    LSP_Subtitle.Text = #names .. " save tersimpan • Klik untuk load"

    for i, name in ipairs(names) do
        local row = Create("TextButton", {
            Name = "Row_" .. name,
            Size = UDim2.new(1, -6, 0, 40),
            BackgroundColor3 = CONFIG.Colors.Card,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Active = true,
            Selectable = false,
            LayoutOrder = i,
            ZIndex = 214
        }, LSP_Scroll)

        Corner(row, CONFIG.Radius.Small)
        Stroke(row, CONFIG.Colors.Border, 1)

        local isLast = (name == LastSaveName)

        local nameLabel = Create("TextLabel", {
            Size = UDim2.new(1, -70, 0, 18),
            Position = UDim2.fromOffset(10, 4),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = isLast and CONFIG.Colors.Accent or CONFIG.Colors.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Active = false,
            ZIndex = 215
        }, row)

        local subLabel = Create("TextLabel", {
            Size = UDim2.new(1, -70, 0, 14),
            Position = UDim2.fromOffset(10, 22),
            BackgroundTransparency = 1,
            Text = isLast and "▶ Terakhir digunakan" or "Klik untuk load",
            TextColor3 = CONFIG.Colors.SubText,
            Font = Enum.Font.Gotham,
            TextSize = 8,
            TextXAlignment = Enum.TextXAlignment.Left,
            Active = false,
            ZIndex = 215
        }, row)

        local deleteBtn = Create("TextButton", {
            Name = "DeleteBtn",
            Size = UDim2.fromOffset(26, 26),
            Position = UDim2.new(1, -34, 0.5, -13),
            BackgroundColor3 = CONFIG.Colors.Secondary,
            BorderSizePixel = 0,
            Text = "×",
            TextColor3 = CONFIG.Colors.Danger,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            AutoButtonColor = false,
            Active = true,
            Selectable = false,
            ZIndex = 216
        }, row)

        Corner(deleteBtn, CONFIG.Radius.Small)
        Stroke(deleteBtn, CONFIG.Colors.Border, 1)

        deleteBtn.Activated:Connect(function()
            deleteBtn:Destroy()
            DeleteSave(name)
            task.wait(0.05)
            RefreshListSaveUI()
        end)

        row.Activated:Connect(function()
            local content = ReadFromName(name)
            if content then
                local loaded = ApplySaveContent(content)
                LastSaveName = name
                local meta = ReadMetaFile()
                meta.LastSaveName = name
                WriteMetaFile(meta)
                SaveNameBox.Set(name)
                print("[ADEX LOAD] Loaded " .. loaded .. " items dari '" .. name .. "'")

                Tween(row, 0.12, {
                    BackgroundColor3 = CONFIG.Colors.Success
                })
                task.delay(0.2, function()
                    if row and row.Parent then
                        Tween(row, 0.2, {
                            BackgroundColor3 = CONFIG.Colors.Card
                        })
                    end
                end)

                task.delay(0.3, function()
                    RefreshListSaveUI()
                end)
            else
                print("[ADEX LOAD] Gagal load save: " .. name)
            end
        end)

        row.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                Tween(row, 0.08, {
                    BackgroundColor3 = CONFIG.Colors.Secondary
                })
            end
        end)

        row.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                Tween(row, 0.12, {
                    BackgroundColor3 = CONFIG.Colors.Card
                })
            end
        end)
    end
end

local function OpenListSave()
    if listSaveOpen then return end
    listSaveOpen = true

    ListSavePanel.Visible = true
    ListSavePanel.BackgroundTransparency = 1

    LSP_Card.Size = UDim2.fromOffset(0, 0)
    LSP_Card.BackgroundTransparency = 1

    RefreshListSaveUI()

    Tween(ListSavePanel, 0.18, { BackgroundTransparency = 0.55 })
    Tween(LSP_Card, 0.25, {
        Size = UDim2.fromOffset(320, 380),
        BackgroundTransparency = 0
    })
end

local function CloseListSave()
    if not listSaveOpen then return end
    listSaveOpen = false

    Tween(ListSavePanel, 0.15, { BackgroundTransparency = 1 })
    Tween(LSP_Card, 0.18, {
        Size = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1
    })

    task.delay(0.2, function()
        ListSavePanel.Visible = false
    end)
end

LSP_CloseBtn.Activated:Connect(CloseListSave)

LSP_RefreshBtn.Activated:Connect(function()
    RefreshListSaveUI()
end)

LSP_DeleteAllBtn.Activated:Connect(function()
    local names = ListSaveNames()
    for _, name in ipairs(names) do
        DeleteSave(name)
    end
    task.wait(0.05)
    RefreshListSaveUI()
end)

ListSavePanel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        CloseListSave()
    end
end)

AddButton(Settings, "List Save", "Tampilkan panel list save tersimpan.", function()
    OpenListSave()
end)

local Modal = Create("Frame", {
    Name = "ConfirmModal",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 200
}, GUI)

local ModalCard = Create("Frame", {
    Name = "Card",
    Size = UDim2.fromOffset(300, 175),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = CONFIG.Colors.Secondary,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 201
}, Modal)

Corner(ModalCard, CONFIG.Radius.Outer)
Stroke(ModalCard, CONFIG.Colors.Border, 1)

Create("Frame", {
    Name = "AccentStrip",
    Size = UDim2.new(1, 0, 0, 3),
    BackgroundColor3 = CONFIG.Colors.Danger,
    BorderSizePixel = 0,
    ZIndex = 202
}, ModalCard)

local IconCircle = Create("Frame", {
    Name = "Icon",
    Size = UDim2.fromOffset(34, 34),
    Position = UDim2.fromOffset(16, 18),
    BackgroundColor3 = Color3.fromRGB(60, 25, 25),
    BorderSizePixel = 0,
    ZIndex = 202
}, ModalCard)

Corner(IconCircle, 17)

Create("TextLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "!",
    TextColor3 = CONFIG.Colors.Danger,
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    ZIndex = 203
}, IconCircle)

Create("TextLabel", {
    Name = "Title",
    Size = UDim2.new(1, -80, 0, 20),
    Position = UDim2.fromOffset(60, 18),
    BackgroundTransparency = 1,
    Text = "Konfirmasi",
    TextColor3 = CONFIG.Colors.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 203
}, ModalCard)

Create("TextLabel", {
    Name = "Subtitle",
    Size = UDim2.new(1, -80, 0, 14),
    Position = UDim2.fromOffset(60, 38),
    BackgroundTransparency = 1,
    Text = "Tindakan ini tidak bisa dibatalkan",
    TextColor3 = CONFIG.Colors.SubText,
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 203
}, ModalCard)

Create("Frame", {
    Name = "Divider",
    Size = UDim2.new(1, -32, 0, 1),
    Position = UDim2.fromOffset(16, 68),
    BackgroundColor3 = CONFIG.Colors.Border,
    BorderSizePixel = 0,
    ZIndex = 202
}, ModalCard)

Create("TextLabel", {
    Name = "Message",
    Size = UDim2.new(1, -32, 0, 36),
    Position = UDim2.fromOffset(16, 80),
    BackgroundTransparency = 1,
    Text = "Yakin ingin menutup UI?",
    TextColor3 = CONFIG.Colors.Text,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true,
    ZIndex = 203
}, ModalCard)

local ButtonRow = Create("Frame", {
    Name = "ButtonRow",
    Size = UDim2.new(1, -32, 0, 38),
    Position = UDim2.new(0, 16, 1, -54),
    BackgroundTransparency = 1,
    ZIndex = 203
}, ModalCard)

Create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 10)
}, ButtonRow)

local function MakeModalButton(text, bgColor)
    local btn = Create("TextButton", {
        Size = UDim2.new(0.5, -5, 1, 0),
        BackgroundColor3 = bgColor,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = CONFIG.Colors.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        AutoButtonColor = false,
        Active = true,
        Selectable = false,
        ZIndex = 204
    }, ButtonRow)

    Corner(btn, CONFIG.Radius.Small)
    Stroke(btn, CONFIG.Colors.Border, 1)

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            Tween(btn, 0.08, {
                BackgroundColor3 = bgColor:Lerp(Color3.new(0, 0, 0), 0.25)
            })
        end
    end)

    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            Tween(btn, 0.12, { BackgroundColor3 = bgColor })
        end
    end)

    return btn
end

local NoBtn = MakeModalButton("NO", CONFIG.Colors.Card)
local YesBtn = MakeModalButton("YES", CONFIG.Colors.Danger)

local modalOpen = false

local function OpenModal()
    if modalOpen then return end
    if not Main or not Main.Visible then return end
    modalOpen = true

    Modal.Visible = true
    Modal.BackgroundTransparency = 1

    ModalCard.Size = UDim2.fromOffset(0, 0)
    ModalCard.BackgroundTransparency = 1

    Tween(Modal, 0.18, { BackgroundTransparency = 0.55 })
    Tween(ModalCard, 0.25, {
        Size = UDim2.fromOffset(300, 175),
        BackgroundTransparency = 0
    })
end

local function CloseModal(thenDestroy)
    if not modalOpen then return end
    modalOpen = false

    Tween(Modal, 0.15, { BackgroundTransparency = 1 })
    Tween(ModalCard, 0.18, {
        Size = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1
    })

    task.delay(0.20, function()
        Modal.Visible = false
        if thenDestroy and GUI and GUI.Parent then
            GUI:Destroy()
        end
    end)
end

Modal.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        CloseModal(false)
    end
end)

YesBtn.Activated:Connect(function()
    CloseModal(true)
end)

NoBtn.Activated:Connect(function()
    CloseModal(false)
end)

local dragging = false
local dragTarget = nil
local dragStart = nil
local dragStartX = 0
local dragStartY = 0
local movedDistance = 0

local LastLogoPosition = nil
local LastMainPosition = nil

local function SaveMainPosition()
    if not Main or not Main.Parent then return end
    local px, py = GetPixelPosition(Main)
    LastMainPosition = Vector2.new(px, py)
end

local function SaveLogoPosition()
    if not FloatingLogo or not FloatingLogo.Parent then return end
    local px, py = GetPixelPosition(FloatingLogo)
    LastLogoPosition = Vector2.new(px, py)
end

local function BeginDrag(target, input)
    if not target or not target.Parent then return end
    dragging = true
    dragTarget = target
    dragStart = input.Position
    dragStartX, dragStartY = GetPixelPosition(target)
    movedDistance = 0
end

local function UpdateDrag(input)
    if not dragging or not dragTarget or not dragTarget.Parent then return end
    if not dragStart then return end

    local delta = input.Position - dragStart
    movedDistance = math.max(
        movedDistance,
        math.abs(delta.X) + math.abs(delta.Y)
    )

    SetPixelPosition(
        dragTarget,
        dragStartX + delta.X,
        dragStartY + delta.Y
    )
end

local function EndDrag()
    if dragTarget == Main then
        SaveMainPosition()
    elseif dragTarget == FloatingLogo then
        SaveLogoPosition()
    end

    dragging = false
    dragTarget = nil
    dragStart = nil
end

local minimized = false
local minimizeBusy = false
local closeBusy = false
local logoBusy = false

local function MinimizeMenu()
    if minimized then return end
    if not Main or not Main.Parent then return end
    if not Main.Visible then return end

    minimized = true

    SaveMainPosition()

    local targetPos = LastLogoPosition
    if not targetPos then
        local mpx, mpy = GetPixelPosition(Main)
        targetPos = Vector2.new(mpx, mpy)
    end

    local logoSize = Vector2.new(52, 52)
    local cx, cy = ClampPixel(targetPos.X, targetPos.Y, logoSize, FloatingLogo.AnchorPoint)

    FloatingLogo.Position = UDim2.fromOffset(cx, cy)
    FloatingLogo.Size = UDim2.fromOffset(52, 52)
    FloatingLogo.BackgroundTransparency = 0
    FloatingLogoInner.BackgroundTransparency = 0
    FloatingLogoImg.ImageTransparency = 0
    LogoFallback.TextTransparency = 0

    UpdateLogoFallback()
    FloatingLogo.Visible = true
    Main.Visible = false

    task.defer(function()
        if FloatingLogo and FloatingLogo.Parent then
            ClampInside(FloatingLogo)
        end
    end)
end

local function RestoreMenu()
    if not minimized then return end
    if not Main or not Main.Parent then return end

    minimized = false

    SaveLogoPosition()

    local targetPos = LastMainPosition
    if not targetPos then
        local lpx, lpy = GetPixelPosition(FloatingLogo)
        targetPos = Vector2.new(lpx, lpy)
    end

    local mainSizeUDim = UDim2.fromOffset(HubWidth, HubHeight)
    local mainSizeVec = Vector2.new(HubWidth, HubHeight)
    local cx, cy = ClampPixel(targetPos.X, targetPos.Y, mainSizeVec, Main.AnchorPoint)

    Main.Size = UDim2.fromOffset(0, 0)
    Main.Position = UDim2.fromOffset(cx, cy)
    Main.Visible = true

    Tween(Main, 0.30, { Size = mainSizeUDim })

    Tween(FloatingLogo, 0.18, {
        Size = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1
    })
    Tween(FloatingLogoInner, 0.15, { BackgroundTransparency = 1 })
    Tween(FloatingLogoImg, 0.15, { ImageTransparency = 1 })
    Tween(LogoFallback, 0.15, { TextTransparency = 1 })

    task.delay(0.20, function()
        if FloatingLogo and FloatingLogo.Parent then
            FloatingLogo.Visible = false
            FloatingLogo.Size = UDim2.fromOffset(52, 52)
            FloatingLogo.BackgroundTransparency = 0
            FloatingLogoInner.BackgroundTransparency = 0
            FloatingLogoImg.ImageTransparency = 0
            LogoFallback.TextTransparency = 0
            UpdateLogoFallback()
        end
    end)
end

DragZone.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    BeginDrag(Main, input)
end)

FloatingLogo.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    BeginDrag(FloatingLogo, input)
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        UpdateDrag(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if not dragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local target = dragTarget
    local distance = movedDistance

    if target == FloatingLogo and distance < 8 then
        if not logoBusy then
            logoBusy = true
            pcall(RestoreMenu)
            task.delay(0.30, function()
                logoBusy = false
            end)
        end
    end

    EndDrag()
end)

MinimizeBtn.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    if minimizeBusy or minimized then return end
    minimizeBusy = true

    local ok, err = pcall(MinimizeMenu)
    if not ok then
        warn("[ADEX] Minimize error:", err)
        minimized = false
    end

    task.delay(0.30, function()
        minimizeBusy = false
    end)
end)

CloseBtn.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    if closeBusy or modalOpen then return end
    closeBusy = true

    OpenModal()

    task.delay(0.30, function()
        closeBusy = false
    end)
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.Escape then
        if listSaveOpen then
            CloseListSave()
            return
        end
        if modalOpen then
            CloseModal(false)
            return
        end
    end

    if input.KeyCode ~= CONFIG.Key then return end

    if modalOpen then return end
    if listSaveOpen then return end

    if minimized then
        RestoreMenu()
    else
        MinimizeMenu()
    end
end)

local CameraConnection = nil
local CameraWatcher = nil
local ConnectedCamera = nil

local function ConnectCamera(camera)
    if CameraConnection then
        CameraConnection:Disconnect()
        CameraConnection = nil
    end

    if not camera then return end
    ConnectedCamera = camera

    CameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        if not GUI or not GUI.Parent then return end

        local width, height = GetSize()
        HubWidth = width
        HubHeight = height

        if minimized then
            if LastLogoPosition then
                local logoSize = Vector2.new(52, 52)
                local cx, cy = ClampPixel(
                    LastLogoPosition.X,
                    LastLogoPosition.Y,
                    logoSize,
                    FloatingLogo.AnchorPoint
                )
                FloatingLogo.Position = UDim2.fromOffset(cx, cy)
            else
                ClampInside(FloatingLogo)
            end
        elseif Main and Main.Parent then
            Main.Size = UDim2.fromOffset(width, height)
            task.defer(function()
                if Main and Main.Parent then
                    if LastMainPosition then
                        local mainSize = Vector2.new(width, height)
                        local cx, cy = ClampPixel(
                            LastMainPosition.X,
                            LastMainPosition.Y,
                            mainSize,
                            Main.AnchorPoint
                        )
                        Main.Position = UDim2.fromOffset(cx, cy)
                    else
                        ClampInside(Main)
                    end
                end
            end)
        end
    end)
end

ConnectCamera(workspace.CurrentCamera)

CameraWatcher = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if not GUI or not GUI.Parent then return end
    local camera = workspace.CurrentCamera
    if camera and camera ~= ConnectedCamera then
        ConnectCamera(camera)
    end
end)

SelectTab("Home")

local LoadingSteps = {
    { text = "Initializing core...", at = 0.15 },
    { text = "Loading modules...", at = 0.40 },
    { text = "Building interface...", at = 0.65 },
    { text = "Finalizing...", at = 0.85 },
    { text = "Ready!", at = 1.00 }
}

local stepIndex = 0
local startTime = os.clock()

local BarTween = TweenService:Create(
    BarFill,
    TweenInfo.new(
        CONFIG.LoadDuration,
        Enum.EasingStyle.Quart,
        Enum.EasingDirection.Out
    ),
    { Size = UDim2.new(1, 0, 1, 0) }
)
BarTween:Play()

local LoadingConnection

LoadingConnection = RunService.RenderStepped:Connect(function()
    if not GUI or not GUI.Parent then
        if LoadingConnection then
            LoadingConnection:Disconnect()
            LoadingConnection = nil
        end
        return
    end

    local progress = math.clamp(
        (os.clock() - startTime) / CONFIG.LoadDuration,
        0, 1
    )

    for i = #LoadingSteps, 1, -1 do
        if progress >= LoadingSteps[i].at and stepIndex < i then
            stepIndex = i
            LoaderStatus.Text = LoadingSteps[i].text
            break
        end
    end

    if progress >= 1 then
        LoadingConnection:Disconnect()
        LoadingConnection = nil

        Tween(LoaderCenter, 0.30, {
            Size = UDim2.fromOffset(0, 0),
            BackgroundTransparency = 1
        })
        Tween(LoaderTitle, 0.25, { TextTransparency = 1 })
        Tween(LoaderVersion, 0.25, { TextTransparency = 1 })
        Tween(LoaderStatus, 0.25, { TextTransparency = 1 })
        Tween(BarBG, 0.25, { BackgroundTransparency = 1 })
        Tween(Loader, 0.35, { BackgroundTransparency = 1 })

        task.wait(0.35)

        if not GUI or not GUI.Parent then return end

        Main.Visible = true
        Main.Size = UDim2.fromOffset(0, 0)

        Tween(Main, 0.40, {
            Size = UDim2.fromOffset(HubWidth, HubHeight)
        })

        task.wait(0.45)

        if Loader and Loader.Parent then
            Loader:Destroy()
        end

        if AutoLoadEnabled and LastSaveName ~= "" then
            task.wait(0.2)
            local content = ReadFromName(LastSaveName)
            if content then
                local loaded = ApplySaveContent(content)
                print("[ADEX AUTO LOAD] Loaded " .. loaded .. " items dari '" .. LastSaveName .. "'")
            else
                print("[ADEX AUTO LOAD] Save '" .. LastSaveName .. "' tidak ditemukan")
            end
        end
    end
end)

GUI.Destroying:Connect(function()
    if LoadingConnection then
        LoadingConnection:Disconnect()
        LoadingConnection = nil
    end
    if CameraConnection then
        CameraConnection:Disconnect()
        CameraConnection = nil
    end
    if CameraWatcher then
        CameraWatcher:Disconnect()
        CameraWatcher = nil
    end

    dragging = false
    dragTarget = nil
    dragStart = nil

    for obj in pairs(ActiveTweens) do
        ActiveTweens[obj] = nil
    end

    pcall(function()
        if StatusCard and StatusCard.SetStatus then
            StatusCard.SetStatus(false)
        end
    end)

    pcall(function()
        RunService:UnbindFromRenderStep("ADEX_CrosshairKiller")
    end)
    pcall(function()
        RunService:UnbindFromRenderStep("ADEX_NicknameKiller")
    end)
    pcall(function()
        RunService:UnbindFromRenderStep("ADEX_GeneratorKiller")
    end)
    pcall(function()
        RunService:UnbindFromRenderStep("ADEX_AutoGenKiller")
    end)

    pcall(ADEX_RunAllCleanups)
end)
