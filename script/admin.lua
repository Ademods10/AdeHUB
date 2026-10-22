--========================================
-- ADEX CHAT CMD V2
-- Chat listener | Android + PC
--========================================

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local savedLocations = {}
local prefix = ";"
local flyConn, flyBV, flyBG, flyHum = nil, nil, nil, nil
local flyActive = false
local specConn, specTarget, specBillboard = nil, nil, nil

local SAVE_FILE = "ADEX_goto_save.json"

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
    print("[ADEX] Spectate:", target.Name)
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

local function execute(message)
    if message:sub(1, 1) ~= prefix then
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
        print(";setgoto <nama> - Simpan lokasi")
        print(";goto <nama> - Teleport ke lokasi tersimpan")
        print(";fly - Aktifkan fly")
        print(";unfly - Matikan fly")
        print(";to <nama> - Teleport ke player")
        print(";bring <nama> - Tarik player ke kamu")
        print(";spawn - Teleport ke spawn")
        print(";spec <nama> - Spectate player")
        print(";unspec - Berhenti spectate")
        print("========================")

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

    elseif cmd == ";spec" then
        local target = findPlayer(name)
        if not target then
            warn("[ADEX] Pemain tidak ditemukan")
            return
        end
        startSpec(target)

    elseif cmd == ";unspec" then
        unspec()
        print("[ADEX] Spectate dimatikan")

    else
        warn("[ADEX] Command tidak dikenal:", cmd)
    end
end

LP.Chatted:Connect(function(message)
    print("[ADEX] Chat terdeteksi:", message)
    execute(message)
end)

print("[ADEX] Chat CMD V2 aktif")
