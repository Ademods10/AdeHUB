--========================================================--
--                 ADEX MODERN HUB V3.8.1                --
--========================================================--
-- COMPACT • MOBILE • PC • CLAMPED • STABLE              --
-- + CLOSE CONFIRMATION (YES / NO) - CLEAN LAYOUT        --
--========================================================--

--========================================================--
-- SERVICES
--========================================================--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

--========================================================--
-- CONFIG
--========================================================--

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
        DangerDark = Color3.fromRGB(160, 45, 45)
    }
}

--========================================================--
-- REMOVE OLD GUI
--========================================================--

pcall(function()
    local old = CoreGui:FindFirstChild("ADEX_MODERN_HUB")
    if old then old:Destroy() end
end)

--========================================================--
-- PARENT
--========================================================--

local Parent
pcall(function()
    if typeof(gethui) == "function" then
        Parent = gethui()
    end
end)
Parent = Parent or CoreGui

--========================================================--
-- HELPERS
--========================================================--

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

--========================================================--
-- SAFE TWEEN
--========================================================--

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

--========================================================--
-- RESPONSIVE SIZE
--========================================================--

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

--========================================================--
-- ROOT GUI
--========================================================--

local GUI = Create("ScreenGui", {
    Name = "ADEX_MODERN_HUB",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true
}, Parent)

--========================================================--
-- VIEWPORT & CLAMP HELPERS
--========================================================--

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

--========================================================--
-- LOADING SCREEN
--========================================================--

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

--========================================================--
-- MAIN
--========================================================--

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

--========================================================--
-- HEADER
--========================================================--

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

--========================================================--
-- MINIMIZE BUTTON
--========================================================--

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

--========================================================--
-- CLOSE BUTTON
--========================================================--

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

--========================================================--
-- FLOATING LOGO
--========================================================--

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

--========================================================--
-- BODY
--========================================================--

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

--========================================================--
-- TAB SYSTEM
--========================================================--

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

--========================================================--
-- COMPONENTS
--========================================================--

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

    Create("TextLabel", {
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

    return button
end

local function AddToggle(page, title, description, default, callback)
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

    return {
        Set = Set,
        Get = function() return state end,
        Frame = card
    }
end

--========================================================--
-- CREATE TABS
--========================================================--

local Home = CreateTab("Home", "⌂")
local Visuals = CreateTab("Visuals", "◉")
local PlayerTab = CreateTab("Player", "●")
local Settings = CreateTab("Settings", "⚙")

--========================================================--
-- HOME CONTENT
--========================================================--

AddSection(Home, "WELCOME")
AddLabel(Home, "ADEX MODERN HUB", "Compact • Responsive • Android + PC")
AddLabel(Home, "Status", "UI berhasil dimuat.")

AddSection(Home, "EXAMPLE")
AddButton(Home, "Example Button", "Contoh tombol fitur.", function()
    print("[ADEX] Button clicked")
end)

AddToggle(Home, "Example Toggle", "Contoh toggle.", false, function(value)
    print("[ADEX] Toggle:", value)
end)

--========================================================--
-- VISUALS CONTENT
--========================================================--

AddSection(Visuals, "VISUAL FEATURES")
AddButton(Visuals, "Refresh", "Refresh fitur.", function()
    print("Refresh")
end)

--========================================================--
-- ESP BODY (User Code - Unchanged)
--========================================================--

local ADEX_EspBodyLoaded = false
local ADEX_EspBodyEnabled = false

AddSection(Visuals, "ESP BODY")

AddToggle(Visuals, "Esp Body", "Killer (Merah) / Survivor (Biru).", false, function(enabled)
    ADEX_EspBodyEnabled = enabled

    if enabled and not ADEX_EspBodyLoaded then
        ADEX_EspBodyLoaded = true

        --//=====================================================//
        --//  USER CODE ESP BODY - TIDAK DIUBAH SAMA SEKALI      //
        --//=====================================================//

        --// ADEX BODY ESP
        --// ROLE DETECTION
        --// Killer   = RED
        --// Survivor = BLUE

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
            -- 1. Team
            if player.Team then
                local role = NormalizeRole(player.Team.Name)
                if role then
                    return role
                end
            end

            -- 2. Attribute Role
            local attributeRole = player:GetAttribute("Role")
            local role = NormalizeRole(attributeRole)

            if role then
                return role
            end

            -- 3. Role langsung di Player
            local roleObject = player:FindFirstChild("Role")
            role = NormalizeRole(ReadValue(roleObject))

            if role then
                return role
            end

            -- 4. Leaderstats
            local leaderstats = player:FindFirstChild("leaderstats")

            if leaderstats then
                local leaderRole = leaderstats:FindFirstChild("Role")

                role = NormalizeRole(ReadValue(leaderRole))

                if role then
                    return role
                end
            end

            -- 5. Character
            local character = player.Character

            if character then
                local characterRole = character:FindFirstChild("Role")

                role = NormalizeRole(ReadValue(characterRole))

                if role then
                    return role
                end

                -- Attribute Character
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

            -- Simpan role agar mudah dicek
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

        --//=====================================================//
        --//  END USER CODE - TIDAK DIUBAH SAMA SEKALI           //
        --//=====================================================//

        -- State applier eksternal (untuk fungsi ON/OFF toggle)
        -- TIDAK menyentuh code user di atas
        RunService.Heartbeat:Connect(function()
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
    end
end)

--========================================================--
-- CROSSHAIR V2 (User Code - Unchanged)
--========================================================--

local ADEX_CrosshairLoaded = false
local ADEX_CrosshairEnabled = false
local ADEX_CrosshairGui = nil
local ADEX_CrosshairAutoGuard = nil

AddSection(Visuals, "CROSSHAIR")

AddToggle(Visuals, "Crosshair", "Titik crosshair di tengah layar.", false, function(enabled)
    ADEX_CrosshairEnabled = enabled

    if enabled and not ADEX_CrosshairLoaded then
        ADEX_CrosshairLoaded = true

        --//=====================================================//
        --//  USER CODE CROSSHAIR V2 - TIDAK DIUBAH SAMA SEKALI  //
        --//=====================================================//

        --// ADEX DOT CROSSHAIR V2
        --// LocalScript
        --// StarterPlayer > StarterPlayerScripts

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local Player = Players.LocalPlayer
        local PlayerGui = Player:WaitForChild("PlayerGui")

        local GUI_NAME = "ADEX_DotCrosshair"

        local function CreateCrosshair()
            -- Hapus GUI lama
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

        --==================================================
        -- AUTO RECOVERY
        --==================================================

        local checkTimer = 0

        RunService.RenderStepped:Connect(function(dt)

            checkTimer += dt

            -- Tidak perlu mengecek setiap frame
            if checkTimer < 0.25 then
                return
            end

            checkTimer = 0

            -- GUI hilang
            if not gui
                or not gui.Parent
                or not PlayerGui:FindFirstChild(GUI_NAME) then

                gui, dot = CreateCrosshair()
                return
            end

            -- GUI mati
            if gui.Enabled == false then
                gui.Enabled = true
            end

            -- Dot hilang
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

            -- Pastikan posisi dan visibility tetap benar
            dot.Visible = true
            dot.Position = UDim2.fromScale(0.5, 0.5)
        end)

        --==================================================
        -- RESPAWN PROTECTION
        --==================================================

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

        -- Jika PlayerGui berubah/di-reset
        PlayerGui.ChildRemoved:Connect(function(child)

            if child.Name == GUI_NAME then
                task.wait()

                gui, dot = CreateCrosshair()
            end
        end)

        --//=====================================================//
        --//  END USER CODE - TIDAK DIUBAH SAMA SEKALI           //
        --//=====================================================//

        ADEX_CrosshairGui = gui
    end
end)

--========================================================--
-- PLAYER CONTENT
--========================================================--

AddSection(PlayerTab, "PLAYER FEATURES")
AddToggle(PlayerTab, "Feature A", "Tempat fitur player.", false, function(v)
    print("Feature A:", v)
end)
AddToggle(PlayerTab, "Feature B", "Fitur player lainnya.", false, function(v)
    print("Feature B:", v)
end)

--========================================================--
-- SETTINGS CONTENT
--========================================================--

AddSection(Settings, "INTERFACE")
AddButton(Settings, "Reset Position", "Kembalikan UI ke tengah.", function()
    Main.Position = UDim2.fromScale(0.5, 0.5)
    ClampInside(Main)

    FloatingLogo.Position = UDim2.fromScale(0.5, 0.5)
    ClampInside(FloatingLogo)
end)

AddLabel(Settings, "Keybind", "RightShift = Minimize / Restore")

--========================================================--
-- CLOSE CONFIRMATION DIALOG
--========================================================--

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

-- Top danger accent strip
Create("Frame", {
    Name = "AccentStrip",
    Size = UDim2.new(1, 0, 0, 3),
    BackgroundColor3 = CONFIG.Colors.Danger,
    BorderSizePixel = 0,
    ZIndex = 202
}, ModalCard)

-- Warning icon
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

-- Title
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

-- Subtitle
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

-- Divider
Create("Frame", {
    Name = "Divider",
    Size = UDim2.new(1, -32, 0, 1),
    Position = UDim2.fromOffset(16, 68),
    BackgroundColor3 = CONFIG.Colors.Border,
    BorderSizePixel = 0,
    ZIndex = 202
}, ModalCard)

-- Message
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

-- Button row container
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

    -- Press effect
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

-- Click outside card = cancel
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

--========================================================--
-- DRAG SYSTEM
--========================================================--

local dragging = false
local dragTarget = nil
local dragStart = nil
local dragStartX = 0
local dragStartY = 0
local movedDistance = 0

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
    dragging = false
    dragTarget = nil
    dragStart = nil
end

--========================================================--
-- MINIMIZE / RESTORE
--========================================================--

local minimized = false
local minimizeBusy = false
local closeBusy = false
local logoBusy = false

local function MinimizeMenu()
    if minimized then return end
    if not Main or not Main.Parent then return end
    if not Main.Visible then return end

    minimized = true

    local px, py = GetPixelPosition(Main)
    local logoSize = Vector2.new(52, 52)
    local cx, cy = ClampPixel(px, py, logoSize, FloatingLogo.AnchorPoint)

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

    local px, py = GetPixelPosition(FloatingLogo)

    local mainSizeUDim = UDim2.fromOffset(HubWidth, HubHeight)
    local mainSizeVec = Vector2.new(HubWidth, HubHeight)
    local cx, cy = ClampPixel(px, py, mainSizeVec, Main.AnchorPoint)

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

--========================================================--
-- INPUT BINDINGS
--========================================================--

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

    -- ESC = tutup modal
    if input.KeyCode == Enum.KeyCode.Escape and modalOpen then
        CloseModal(false)
        return
    end

    if input.KeyCode ~= CONFIG.Key then return end

    -- Tidak boleh toggle minimize saat modal terbuka
    if modalOpen then return end

    if minimized then
        RestoreMenu()
    else
        MinimizeMenu()
    end
end)

--========================================================--
-- CAMERA SYSTEM
--========================================================--

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
            ClampInside(FloatingLogo)
        elseif Main and Main.Parent then
            Main.Size = UDim2.fromOffset(width, height)
            task.defer(function()
                if Main and Main.Parent then
                    ClampInside(Main)
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

--========================================================--
-- INITIAL TAB
--========================================================--

SelectTab("Home")

--========================================================--
-- LOADING ANIMATION
--========================================================--

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
    end
end)

--========================================================--
-- CLEANUP
--========================================================--

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
end)
