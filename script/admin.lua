--========================================
-- ADEX CHAT CMD V2
-- Chat listener | Android + PC
--========================================

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local savedLocations = {}
local prefix = ";"
local flyConn, flyBV, flyBG, flyHum = nil, nil, nil, nil
local flyActive = false
local specConn, specTarget, specBillboard = nil, nil, nil
local abConn, abActive = nil, false
local abDisabledParts = {}
local fbSaved = nil
local fbActive = false
local adminGui, adminListFrame = nil, nil

local SAVE_FILE = "ADEX_goto_save.json"
local ADMIN_FILE = "ADEX_admin_cache.json"

-- URL RAW admins.json di repo AdeHUB (root repo)
-- Jika kamu menaruh admins.json di dalam folder script, ganti menjadi:
-- https://raw.githubusercontent.com/Ademods10/AdeHUB/main/script/admins.json
local ADMIN_URL = "https://raw.githubusercontent.com/Ademods10/AdeHUB/main/admins.json"

local admins = {}

local function fetchGitHub(url)
    if not url or url == "" then
        return nil
    end
    -- Method 1: request (executor-specific)
    if type(request) == "function" then
        local ok, res = pcall(function()
            return request({ Url = url, Method = "GET" })
        end)
        if ok and res and (res.Body or res.body) then
            return res.Body or res.body
        end
    end
    -- Method 2: http_request
    if type(http_request) == "function" then
        local ok, res = pcall(function()
            return http_request({ Url = url, Method = "GET" })
        end)
        if ok and res and (res.Body or res.body) then
            return res.Body or res.body
        end
    end
    -- Method 3: syn.request
    if syn and type(syn.request) == "function" then
        local ok, res = pcall(function()
            return syn.request({ Url = url, Method = "GET" })
        end)
        if ok and res and (res.Body or res.body) then
            return res.Body or res.body
        end
    end
    -- Fallback: HttpService
    local ok2, res2 = pcall(function()
        return HttpService:GetAsync(url)
    end)
    if ok2 and res2 and res2 ~= "" then
        return res2
    end
    return nil
end

local function writeLocalAdmins(list)
    if type(writefile) ~= "function" then return end
    pcall(function()
        writefile(ADMIN_FILE, HttpService:JSONEncode(list))
    end)
end

local function loadAdmins()
    local defaults = {}
    local content = fetchGitHub(ADMIN_URL)
    local source = "GitHub"

    if not content or content == "" then
        source = "local"
        if type(readfile) == "function" then
            local ok, localContent = pcall(readfile, ADMIN_FILE)
            if ok and localContent and localContent ~= "" then
                content = localContent
            end
        end
    end

    if not content or content == "" then
        admins = defaults
        writeLocalAdmins(defaults)
        print("[ADEX] Admin kosong (GitHub tidak tersedia)")
        return
    end

    local ok2, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)

    if not ok2 or type(data) ~= "table" or #data == 0 then
        admins = defaults
        print("[ADEX] Admin JSON tidak valid atau kosong")
        return
    end

    admins = data
    if source == "local" then
        writeLocalAdmins(data)
    end
    print("[ADEX] Admin dimuat dari " .. source .. ":", #admins)
end

loadAdmins()

local function isAdmin(player)
    if not player then return false end
    local lname = player.Name:lower()
    for _, a in ipairs(admins) do
        if type(a) == "string" and a:lower() == lname then
            return true
        end
    end
    return false
end

local function isPlayerOnline(name)
    if not name then return false end
    local lname = name:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == lname then
            return true
        end
    end
    return false
end

if isAdmin(LP) then
    print("[ADEX] Kamu adalah admin ✓")
else
    warn("[ADEX] Kamu BUKAN admin! Tidak bisa pakai command.")
    warn("[ADEX] Tambahkan '" .. LP.Name .. "' ke admins.json di GitHub.")
end

local function refreshAdminGUI()
    if not adminGui or not adminGui.Parent or not adminListFrame then return end
    for _, c in ipairs(adminListFrame:GetChildren()) do
        if c:IsA("Frame") then
            c:Destroy()
        end
    end
    local y = 0
    for _, a in ipairs(admins) do
        if type(a) == "string" then
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -8, 0, 28)
            row.Position = UDim2.new(0, 4, 0, y)
            row.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            row.BackgroundTransparency = 0.3
            row.BorderSizePixel = 0
            row.Parent = adminListFrame

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.6, -4, 1, 0)
            nameLabel.Position = UDim2.new(0, 8, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = a
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.Font = Enum.Font.SourceSans
            nameLabel.TextSize = 16
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = row

            local statusLabel = Instance.new("TextLabel")
            statusLabel.Size = UDim2.new(0.4, -8, 1, 0)
            statusLabel.Position = UDim2.new(0.6, 0, 0, 0)
            statusLabel.BackgroundTransparency = 1
            statusLabel.Font = Enum.Font.SourceSansBold
            statusLabel.TextSize = 16
            statusLabel.TextXAlignment = Enum.TextXAlignment.Right
            statusLabel.Parent = row

            if isPlayerOnline(a) then
                statusLabel.Text = "Online"
                statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
            else
                statusLabel.Text = "Offline"
                statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            end
            y = y + 32
        end
    end
    adminListFrame.CanvasSize = UDim2.new(0, 0, 0, y)
end

local function openAdminGUI()
    if adminGui and adminGui.Parent then
        adminGui:Destroy()
        adminGui = nil
        adminListFrame = nil
        return
    end

    adminGui = Instance.new("ScreenGui")
    adminGui.Name = "ADEX_AdminList"
    adminGui.ResetOnSpawn = false
    adminGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    adminGui.Parent = LP:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 320, 0, 360)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = adminGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -50, 0, 36)
    title.BackgroundTransparency = 1
    title.Text = "ADEX ADMINS (" .. #admins .. ")"
    title.TextColor3 = Color3.fromRGB(0, 255, 170)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 20
    title.Parent = frame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 3)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 18
    closeBtn.Parent = frame

    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.new(1, -12, 1, -46)
    list.Position = UDim2.new(0, 6, 0, 42)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 6
    list.CanvasSize = UDim2.new(0, 0, 0, 0)
    list.Parent = frame

    adminListFrame = list

    closeBtn.MouseButton1Click:Connect(function()
        if adminGui then
            adminGui:Destroy()
            adminGui = nil
            adminListFrame = nil
        end
    end)

    refreshAdminGUI()
end

Players.PlayerAdded:Connect(function()
    refreshAdminGUI()
end)

Players.PlayerRemoving:Connect(function()
    refreshAdminGUI()
end)

local function encodeCFrame(cf)
    local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
    return {x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22}
end

local function decodeCFrame(t)
    return CFrame.new(t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9], t[10], t[11], t[12])
end

local function loadSavedLocations()
    if type(readfile) ~= "function" then return end
    local ok, content = pcall(readfile, SAVE_FILE)
    if not ok or not content or content == "" then return end
    local ok2, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    if not ok2 or type(data) ~= "table" then return end
    local count = 0
    for k, v in pairs(data) do
        if type(v) == "table" and #v == 12 then
            local ok3, cf = pcall(decodeCFrame, v)
            if ok3 then
                savedLocations[k] = cf
                count = count + 1
            end
        end
    end
    print("[ADEX] Lokasi tersimpan dimuat:", count)
end

local function saveSavedLocations()
    if type(writefile) ~= "function" then return end
    local out = {}
    for k, cf in pairs(savedLocations) do
        out[k] = encodeCFrame(cf)
    end
    pcall(function()
        writefile(SAVE_FILE, HttpService:JSONEncode(out))
    end)
end

loadSavedLocations()

local function findPlayer(name)
    if not name or name == "" then
        return nil
    end

    name = name:lower()

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and (
            p.Name:lower():sub(1, #name) == name
            or p.DisplayName:lower():sub(1, #name) == name
        ) then
            return p
        end
    end

    return nil
end

local function removeSpecBillboard()
    if specBillboard then
        specBillboard:Destroy()
        specBillboard = nil
    end
end

local function createSpecBillboard(target)
    removeSpecBillboard()
    local char = target.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "ADEX_SpecName"
    bb.Size = UDim2.new(0, 80, 0, 20)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = head
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = target.DisplayName
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 1
    label.Font = Enum.Font.SourceSans
    label.TextScaled = true
    label.Parent = bb
    specBillboard = bb
end

local function unspec()
    if specConn then
        specConn:Disconnect()
        specConn = nil
    end
    removeSpecBillboard()
    specTarget = nil
    local cam = workspace.CurrentCamera
    if cam then
        cam.CameraType = Enum.CameraType.Custom
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            cam.CameraSubject = hum
        end
    end
end

local function startSpec(target)
    unspec()
    if not target then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    specTarget = target
    cam.CameraType = Enum.CameraType.Custom
    local function bindSubject()
        local tChar = target.Character
        if not tChar then return end
        local tHum = tChar:FindFirstChildOfClass("Humanoid")
        if not tHum then return end
        cam.CameraType = Enum.CameraType.Custom
        cam.CameraSubject = tHum
    end
    bindSubject()
    createSpecBillboard(target)
    specConn = RunService.RenderStepped:Connect(function()
        if specTarget ~= target or not target.Parent then
            unspec()
            return
        end
        local tChar = target.Character
        if not tChar then return end
        local tHum = tChar:FindFirstChildOfClass("Humanoid")
        if not tHum or tHum.Health <= 0 then
            unspec()
            return
        end
        if cam.CameraSubject ~= tHum then
            bindSubject()
        end
        if not specBillboard or specBillboard.Parent ~= tChar:FindFirstChild("Head") then
            createSpecBillboard(target)
        end
    end)
    print("[ADEX] View:", target.Name)
end

local function stopAntiBorder()
    abActive = false
    if abConn then
        abConn:Disconnect()
        abConn = nil
    end
    for part in pairs(abDisabledParts) do
        pcall(function()
            if part and part.Parent then
                part.CanCollide = true
            end
        end)
    end
    abDisabledParts = {}
end

local function startAntiBorder()
    if abActive then
        print("[ADEX] Anti border sudah aktif")
        return
    end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        warn("[ADEX] Karakter belum tersedia")
        return
    end
    abActive = true
    abDisabledParts = {}

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude

    abConn = RunService.Heartbeat:Connect(function()
        if not abActive then return end
        local c = LP.Character
        local h = c and c:FindFirstChild("HumanoidRootPart")
        if not h then return end

        params.FilterDescendantsInstances = {c}
        local origin = h.Position
        local look = h.CFrame.LookVector
        local right = h.CFrame.RightVector
        local dirs = {
            look,
            -look,
            right,
            -right,
            Vector3.new(0, 1, 0),
            Vector3.new(0, -1, 0),
        }
        if h.Velocity.Magnitude > 1 then
            table.insert(dirs, h.Velocity.Unit)
        end

        for _, dir in ipairs(dirs) do
            local result = workspace:Raycast(origin, dir * 15, params)
            if result and result.Instance then
                local part = result.Instance
                if part.CanCollide and part.Transparency >= 0.99 and not part:IsDescendantOf(c) then
                    part.CanCollide = false
                    abDisabledParts[part] = true
                end
            end
        end
    end)
    print("[ADEX] Anti border aktif")
end

local function stopFly()
    flyActive = false
    if flyConn then
        flyConn:Disconnect()
        flyConn = nil
    end
    if flyBV then
        flyBV:Destroy()
        flyBV = nil
    end
    if flyBG then
        flyBG:Destroy()
        flyBG = nil
    end
    if flyHum then
        pcall(function()
            flyHum.PlatformStand = false
        end)
        flyHum = nil
    end
    local char = LP.Character
    if char then
        local anim = char:FindFirstChild("Animate")
        if anim then
            anim.Disabled = false
        end
    end
end

local function startFly()
    if flyActive then
        print("[ADEX] Fly sudah aktif")
        return
    end
    local plr = LP
    local char = plr.Character
    if not char then
        warn("[ADEX] Karakter belum tersedia")
        return
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
        warn("[ADEX] Humanoid tidak ditemukan")
        return
    end

    local torso
    if hum.RigType == Enum.HumanoidRigType.R6 then
        torso = char:FindFirstChild("Torso")
    else
        torso = char:FindFirstChild("UpperTorso")
    end
    if not torso then
        warn("[ADEX] Torso tidak ditemukan")
        return
    end

    flyActive = true
    flyHum = hum
    local maxspeed = 50
    local flySpeed = 0
    local lastf, lastb, lastl, lastr = 0, 0, 0, 0

    flyBG = Instance.new("BodyGyro", torso)
    flyBG.P = 9e4
    flyBG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBG.cframe = torso.CFrame
    flyBV = Instance.new("BodyVelocity", torso)
    flyBV.velocity = Vector3.new(0, 0.1, 0)
    flyBV.maxForce = Vector3.new(9e9, 9e9, 9e9)
    hum.PlatformStand = true

    local anim = char:FindFirstChild("Animate")
    if anim then
        anim.Disabled = true
    end

    flyConn = RunService.RenderStepped:Connect(function(dt)
        if not flyActive then return end
        if not torso.Parent or not hum.Parent or hum.Health <= 0 then
            stopFly()
            return
        end

        local cam = workspace.CurrentCamera
        local look = cam.CFrame.LookVector
        local flatLook = Vector3.new(look.X, 0, look.Z)
        if flatLook.Magnitude > 0 then
            flatLook = flatLook.Unit
        else
            flatLook = Vector3.new(0, 0, -1)
        end
        local flatRight = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z)
        if flatRight.Magnitude > 0 then
            flatRight = flatRight.Unit
        else
            flatRight = Vector3.new(1, 0, 0)
        end

        local f, b, l, r = 0, 0, 0, 0
        local md = hum.MoveDirection
        if md.Magnitude > 0 then
            local fwd = md:Dot(flatLook)
            local side = md:Dot(flatRight)
            if fwd > 0 then f = fwd else b = fwd end
            if side > 0 then r = side else l = side end
        end

        if f + b ~= 0 or l + r ~= 0 then
            flySpeed = flySpeed + .5 + (flySpeed / maxspeed)
            if flySpeed > maxspeed then
                flySpeed = maxspeed
            end
        elseif flySpeed ~= 0 then
            flySpeed = flySpeed - 1
            if flySpeed < 0 then
                flySpeed = 0
            end
        end

        local targetVel = Vector3.new(0, 0, 0)
        if (l + r) ~= 0 or (f + b) ~= 0 then
            targetVel = ((cam.CFrame.lookVector * (f + b)) + ((cam.CFrame * CFrame.new(l + r, (f + b) * .2, 0).p) - cam.CFrame.p)) * flySpeed
            lastf, lastb, lastl, lastr = f, b, l, r
        elseif (l + r) == 0 and (f + b) == 0 and flySpeed ~= 0 then
            targetVel = ((cam.CFrame.lookVector * (lastf + lastb)) + ((cam.CFrame * CFrame.new(lastl + lastr, (lastf + lastb) * .2, 0).p) - cam.CFrame.p)) * flySpeed
        end
        local targetCF = cam.CFrame * CFrame.Angles(-math.rad((f + b) * 50 * flySpeed / maxspeed), 0, 0)

        local alpha = math.clamp((dt or 0.0167) * 15, 0, 1)
        flyBV.velocity = flyBV.velocity:Lerp(targetVel, alpha)
        flyBG.cframe = flyBG.cframe:Lerp(targetCF, alpha)
    end)

    print("[ADEX] Fly aktif")
end

local function doRejoin()
    print("[ADEX] Rejoin...")
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
    end)
end

local function doReset()
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Health = 0
        print("[ADEX] Reset karakter")
    else
        warn("[ADEX] Humanoid tidak ditemukan")
    end
end

local function doSit()
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Sit = true
        print("[ADEX] Duduk")
    else
        warn("[ADEX] Humanoid tidak ditemukan")
    end
end

local function doFullbright()
    if fbActive then
        print("[ADEX] Fullbright sudah aktif")
        return
    end
    local Lighting = game:GetService("Lighting")
    fbSaved = {}
    local props = {
        "Ambient",
        "OutdoorAmbient",
        "Brightness",
        "ClockTime",
        "FogEnd",
        "FogStart",
        "GlobalShadows",
        "EnvironmentDiffuseScale",
        "EnvironmentSpecularScale",
        "ShadowSoftness",
        "ExposureCompensation",
    }
    for _, prop in ipairs(props) do
        local ok, val = pcall(function()
            return Lighting[prop]
        end)
        if ok then
            fbSaved[prop] = val
        end
    end
    local atmosphereSaved = nil
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Atmosphere") then
            atmosphereSaved = {
                obj = obj,
                Density = obj.Density,
                Haze = obj.Haze,
                Glare = obj.Glare,
            }
        end
        if obj:IsA("BloomEffect") then
            obj.Enabled = false
        end
        if obj:IsA("BlurEffect") then
            obj.Enabled = false
        end
        if obj:IsA("SunRaysEffect") then
            obj.Enabled = false
        end
        if obj:IsA("ColorCorrectionEffect") then
            obj.Enabled = false
        end
        if obj:IsA("DepthOfFieldEffect") then
            obj.Enabled = false
        end
    end
    fbSaved.Atmosphere = atmosphereSaved

    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    Lighting.Brightness = 3
    Lighting.ClockTime = 14
    Lighting.FogEnd = 100000
    Lighting.FogStart = 0
    Lighting.GlobalShadows = false
    pcall(function()
        Lighting.EnvironmentDiffuseScale = 1
        Lighting.EnvironmentSpecularScale = 1
    end)
    if atmosphereSaved and atmosphereSaved.obj then
        pcall(function()
            atmosphereSaved.obj.Density = 0
            atmosphereSaved.obj.Haze = 0
            atmosphereSaved.obj.Glare = 0
        end)
    end
    fbActive = true
    print("[ADEX] Fullbright aktif")
end

local function doUnbright()
    if not fbActive or not fbSaved then
        print("[ADEX] Fullbright tidak aktif")
        return
    end
    local Lighting = game:GetService("Lighting")
    for prop, val in pairs(fbSaved) do
        if prop ~= "Atmosphere" then
            pcall(function()
                Lighting[prop] = val
            end)
        end
    end
    local atm = fbSaved.Atmosphere
    if atm and atm.obj and atm.obj.Parent then
        pcall(function()
            atm.obj.Density = atm.Density
            atm.obj.Haze = atm.Haze
            atm.obj.Glare = atm.Glare
        end)
    end
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("BloomEffect")
            or obj:IsA("BlurEffect")
            or obj:IsA("SunRaysEffect")
            or obj:IsA("ColorCorrectionEffect")
            or obj:IsA("DepthOfFieldEffect") then
            obj.Enabled = true
        end
    end
    fbSaved = nil
    fbActive = false
    print("[ADEX] Fullbright dimatikan")
end

local function execute(message)
    if message:sub(1, 1) ~= prefix then
        return
    end

    if not isAdmin(LP) then
        warn("[ADEX] Kamu bukan admin. Command ditolak.")
        return
    end

    local args = {}
    for word in message:gmatch("%S+") do
        table.insert(args, word)
    end

    local cmd = (args[1] or ""):lower()
    local name = args[2]

    if cmd == ";cmds" then
        print("===== ADEX CHAT CMD =====")
        print(";cmds - Daftar command")
        print(";admins / ;admin - Tampilkan list admin")
        print(";reloadadmins - Refresh admin dari GitHub")
        print(";setgoto <nama> - Simpan lokasi")
        print(";goto <nama> - Teleport ke lokasi tersimpan")
        print(";fly - Aktifkan fly")
        print(";unfly - Matikan fly")
        print(";to <nama> - Teleport ke player")
        print(";bring <nama> - Tarik player ke kamu")
        print(";spawn - Teleport ke spawn")
        print(";view <nama> - Lihat player")
        print(";unview - Berhenti lihat player")
        print(";antiborder - Tembus dinding invisible")
        print(";noantiborder - Matikan anti border")
        print(";rejoin - Rejoin server")
        print(";reset / ;re - Reset karakter")
        print(";sit - Duduk")
        print(";fullbright - Mencerahkan tampilan lokal")
        print(";unbright - Memulihkan pencahayaan")
        print("========================")

    elseif cmd == ";admins" or cmd == ";admin" then
        openAdminGUI()

    elseif cmd == ";reloadadmins" then
        loadAdmins()
        refreshAdminGUI()
        print("[ADEX] Admin reload selesai")

    elseif cmd == ";setgoto" then
        if not name then
            warn("[ADEX] Usage: ;setgoto <nama>")
            return
        end
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            warn("[ADEX] Karakter belum tersedia")
            return
        end
        savedLocations[name:lower()] = hrp.CFrame
        saveSavedLocations()
        print("[ADEX] Lokasi tersimpan:", name)

    elseif cmd == ";goto" then
        if not name then
            warn("[ADEX] Usage: ;goto <nama>")
            return
        end
        local loc = savedLocations[name:lower()]
        if not loc then
            warn("[ADEX] Lokasi tidak ditemukan:", name)
            return
        end
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            warn("[ADEX] Karakter belum tersedia")
            return
        end
        hrp.CFrame = loc
        print("[ADEX] Teleport ke lokasi:", name)

    elseif cmd == ";fly" then
        startFly()

    elseif cmd == ";unfly" then
        stopFly()
        print("[ADEX] Fly dimatikan")

    elseif cmd == ";to" then
        local target = findPlayer(name)
        if not target then
            warn("[ADEX] Pemain tidak ditemukan")
            return
        end
        local char = LP.Character
        local targetChar = target.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local targetRoot = targetChar
            and targetChar:FindFirstChild("HumanoidRootPart")
        if root and targetRoot then
            root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
            print("[ADEX] Teleport ke pemain:", target.Name)
        else
            warn("[ADEX] Karakter belum tersedia")
        end

    elseif cmd == ";bring" then
        local target = findPlayer(name)
        if not target then
            warn("[ADEX] Pemain tidak ditemukan")
            return
        end
        local char = LP.Character
        local targetChar = target.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local targetRoot = targetChar
            and targetChar:FindFirstChild("HumanoidRootPart")
        if root and targetRoot then
            targetRoot.CFrame = root.CFrame * CFrame.new(0, 0, 3)
            print("[ADEX] Membawa pemain:", target.Name)
        else
            warn("[ADEX] Karakter belum tersedia")
        end

    elseif cmd == ";spawn" then
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            warn("[ADEX] Karakter belum tersedia")
            return
        end
        local spawnLoc = workspace:FindFirstChildOfClass("SpawnLocation")
        if spawnLoc then
            hrp.CFrame = spawnLoc.CFrame + Vector3.new(0, 5, 0)
            print("[ADEX] Teleport ke spawn")
        else
            warn("[ADEX] SpawnLocation tidak ditemukan")
        end

    elseif cmd == ";view" then
        local target = findPlayer(name)
        if not target then
            warn("[ADEX] Pemain tidak ditemukan")
            return
        end
        startSpec(target)

    elseif cmd == ";unview" then
        unspec()
        print("[ADEX] View dimatikan")

    elseif cmd == ";antiborder" then
        startAntiBorder()

    elseif cmd == ";noantiborder" then
        stopAntiBorder()
        print("[ADEX] Anti border dimatikan")

    elseif cmd == ";rejoin" then
        doRejoin()

    elseif cmd == ";reset" or cmd == ";re" then
        doReset()

    elseif cmd == ";sit" then
        doSit()

    elseif cmd == ";fullbright" then
        doFullbright()

    elseif cmd == ";unbright" then
        doUnbright()

    else
        warn("[ADEX] Command tidak dikenal:", cmd)
    end
end

LP.Chatted:Connect(function(message)
    print("[ADEX] Chat terdeteksi:", message)
    execute(message)
end)

print("[ADEX] Chat CMD V2 aktif")
