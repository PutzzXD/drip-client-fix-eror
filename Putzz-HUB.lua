-- ================== DRIP CLIENT V8.0 (FULLY MODIFIED) ==================

-- ================== KEY SYSTEM CONFIG ==================
local FIREBASE_URL = "https://key-database-701af-default-rtdb.asia-southeast1.firebasedatabase.app/keys.json"
local WEBSITE_URL = "https://drip-client-get-key.vercel.app/"
local SCRIPT_NAME = "DRIP CLIENT"

local SAVE_FILE = "drip_key_data.txt"
local activeKeys = {}
local currentUserKey = nil
local keyExpiryTime = 0
local keyExpiryDays = 0
local keyJenis = ""
local keyValidGlobal = false

-- ================== LOAD SERVICES ==================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- ================== VARIABEL FITUR ==================
-- ESP
local espEnabled = false
local lineEnabled = false
local lineColor = Color3.fromRGB(0, 0, 0) -- Default Hitam untuk ESP Line
local skeletonEnabled = false
local ESPTable = {}
local SkeletonESP = {}

-- Player Counter
local playerCounterEnabled = false
local enemyCountText = nil

-- Movement HP (Fly)
local flyEnabled = false
local flyConnection = nil
local flySpeed = 100
local flyAutoForward = true
local ctrl = {f = 0, b = 0, l = 0, r = 0}
local lastctrl = {f = 0, b = 0, l = 0, r = 0}
local speed = 0
local maxspeed = flySpeed
local flyBodyVelocity = nil
local flyBodyGyro = nil
local flyTorso = nil

local noclipEnabled = false
local noclipConnection = nil

local speedEnabled = false
local normalSpeed = 16
local fastSpeed = 60

-- Jump Power Mod Variables
local jumpPowerEnabled = false
local jumpPowerValue = 50 

-- Combat & Utility Variables
local infinityJumpEnabled = false

local antiDamageEnabled = false
local antiDamageConnection = nil
local antiDamageThread = nil
local antiDamageHeartbeat = nil

local spinEnabled = false
local spinSpeed = 50
local spinConnection = nil
local spinDirection = 1

local invisibleEnabled = false
local invisibleConnection = nil
local invisibleParts = {}
local invisibleRootPart = nil
local invisibleHumanoid = nil

-- Warna Tema & Objek
local themeColor = Color3.fromRGB(156, 39, 176)
local darkPurple = Color3.fromRGB(74, 20, 90)
local boxColor = Color3.fromRGB(0, 0, 0) -- ESP BOX WARNA HITAM
local skeletonColor = Color3.fromRGB(0, 255, 0)
local redColor = Color3.fromRGB(255, 0, 0)
local MAX_ESP_DISTANCE = 115

-- ================== FUNGSI KEY SYSTEM ==================
local function loadKeyData()
    if isfile and isfile(SAVE_FILE) then
        local success, content = pcall(function() return readfile(SAVE_FILE) end)
        if success and content and content ~= "" then
            local success2, data = pcall(function() return HttpService:JSONDecode(content) end)
            if success2 then activeKeys = data end
        end
    end
end

local function saveKeyData()
    if writefile then
        local success, json = pcall(function() return HttpService:JSONEncode(activeKeys) end)
        if success then writefile(SAVE_FILE, json) end
    end
end

local function getKeysFromFirebase()
    local success, data = pcall(function() return game:HttpGet(FIREBASE_URL) end)
    if success and data then
        local success2, jsonData = pcall(function() return HttpService:JSONDecode(data) end)
        if success2 and jsonData then
            local keysArray = {}
            for _, keyData in pairs(jsonData) do table.insert(keysArray, keyData) end
            return keysArray
        end
    end
    return nil
end

local function getTimeRemaining(expiryTimestamp)
    local currentTime = os.time()
    local remaining = expiryTimestamp - currentTime
    if remaining <= 0 then return 0, 0, 0, 0, "EXPIRED" end
    local days = math.floor(remaining / 86400)
    local hours = math.floor((remaining % 86400) / 3600)
    local minutes = math.floor((remaining % 3600) / 60)
    local seconds = remaining % 60
    return days, hours, minutes, seconds, string.format("%d Hari %02d Jam %02d Menit", days, hours, minutes)
end

local function checkKeyExpiry(inputKey)
    loadKeyData()
    local keysData = getKeysFromFirebase()
    if not keysData then return false, "Gagal mengambil data server" end
    
    local foundKey, expiryDays, keyJenisData = nil, nil, nil
    for _, keyData in ipairs(keysData) do
        if keyData.key == inputKey then
            foundKey = keyData.key
            keyJenisData = keyData.jenis or "1 HARI"
            if keyData.jenis == "1 JAM" then expiryDays = 1/24
            elseif keyData.jenis == "1 HARI" then expiryDays = 1
            elseif keyData.jenis == "2 HARI" then expiryDays = 2
            elseif keyData.jenis == "3 HARI" then expiryDays = 3
            elseif keyData.jenis == "7 HARI" then expiryDays = 7
            elseif keyData.jenis == "30 HARI" then expiryDays = 30
            elseif keyData.jenis == "PERMANEN" then expiryDays = 9999999
            else expiryDays = 1 end
            break
        end
    end
    
    if not foundKey then return false, "KEY TIDAK TERDAFTAR!" end
    local currentTime = os.time()
    local expiryTime = nil
    
    if activeKeys[inputKey] and activeKeys[inputKey].expiryTime then
        expiryTime = activeKeys[inputKey].expiryTime
        if currentTime > expiryTime then return false, "KEY SUDAH EXPIRED!" end
    else
        expiryTime = currentTime + (expiryDays * 86400)
        activeKeys[inputKey] = {
            firstUsed = currentTime, key = inputKey, expiryDays = expiryDays,
            expiryTime = expiryTime, jenis = keyJenisData, lastUsed = true
        }
        saveKeyData()
    end
    
    for k, v in pairs(activeKeys) do v.lastUsed = nil end
    activeKeys[inputKey].lastUsed = true
    saveKeyData()
    
    keyExpiryTime = expiryTime
    keyExpiryDays = expiryDays
    keyJenis = keyJenisData
    currentUserKey = inputKey
    keyValidGlobal = true
    
    local _, _, _, _, timeStr = getTimeRemaining(expiryTime)
    return true, "KEY VALID! Sisa " .. timeStr
end

local function showNotification(title, text, duration, color)
    local parentGui = game.CoreGui:FindFirstChild("DripClient") or game.CoreGui:FindFirstChild("DripKeySystem")
    if not parentGui then return end
    local notif = Instance.new("Frame")
    notif.Parent = parentGui
    notif.Size = UDim2.new(0, 280, 0, 60)
    notif.Position = UDim2.new(0.5, -140, 0, -80)
    notif.BackgroundColor3 = color or Color3.fromRGB(30, 30, 40)
    notif.BackgroundTransparency = 0.15
    notif.BorderSizePixel = 0
    notif.ZIndex = 9999

    local notifCorner = Instance.new("UICorner")
    notifCorner.Parent = notif
    notifCorner.CornerRadius = UDim.new(0, 10)

    local notifTitle = Instance.new("TextLabel")
    notifTitle.Parent = notif
    notifTitle.Size = UDim2.new(1, 0, 0.45, 0)
    notifTitle.Position = UDim2.new(0, 0, 0, 4)
    notifTitle.BackgroundTransparency = 1
    notifTitle.Text = title
    notifTitle.TextColor3 = Color3.new(1, 1, 1)
    notifTitle.Font = Enum.Font.GothamBold
    notifTitle.TextSize = 15

    local notifText = Instance.new("TextLabel")
    notifText.Parent = notif
    notifText.Size = UDim2.new(1, -10, 0.5, 0)
    notifText.Position = UDim2.new(0, 5, 0, 28)
    notifText.BackgroundTransparency = 1
    notifText.Text = text
    notifText.TextColor3 = Color3.fromRGB(220, 220, 220)
    notifText.Font = Enum.Font.Gotham
    notifText.TextSize = 12

    TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {Position = UDim2.new(0.5, -140, 0, 25)}):Play()
    task.wait(duration or 2.5)
    TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {Position = UDim2.new(0.5, -140, 0, -80)}):Play()
    task.wait(0.4)
    notif:Destroy()
end

-- ================== GUI KEY SYSTEM ==================
local KeyGui = Instance.new("ScreenGui")
KeyGui.Name = "DripKeySystem"
KeyGui.Parent = game.CoreGui
KeyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local KeyFrame = Instance.new("Frame")
KeyFrame.Parent = KeyGui
KeyFrame.Size = UDim2.new(0, 380, 0, 360)
KeyFrame.Position = UDim2.new(0.5, -190, 0.5, -180)
KeyFrame.BackgroundColor3 = darkPurple
KeyFrame.BackgroundTransparency = 0.1
KeyFrame.Active = true
KeyFrame.Draggable = true
local KeyCorner = Instance.new("UICorner")
KeyCorner.Parent = KeyFrame
KeyCorner.CornerRadius = UDim.new(0, 16)

local KeyStroke = Instance.new("UIStroke")
KeyStroke.Parent = KeyFrame
KeyStroke.Color = themeColor
KeyStroke.Thickness = 2
KeyStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local KeyHeader = Instance.new("Frame")
KeyHeader.Parent = KeyFrame
KeyHeader.Size = UDim2.new(1, 0, 0, 75)
KeyHeader.BackgroundTransparency = 1

local KeyIcon = Instance.new("ImageLabel")
KeyIcon.Parent = KeyHeader
KeyIcon.Size = UDim2.new(0, 60, 0, 60)
KeyIcon.Position = UDim2.new(0.5, -30, 0, 10)
KeyIcon.BackgroundTransparency = 1
KeyIcon.Image = "rbxassetid://72495850369898"
KeyIcon.ImageColor3 = themeColor
KeyIcon.ScaleType = Enum.ScaleType.Fit

local KeyTitle = Instance.new("TextLabel")
KeyTitle.Parent = KeyHeader
KeyTitle.Size = UDim2.new(1, 0, 0.4, 0)
KeyTitle.Position = UDim2.new(0, 0, 0, 52)
KeyTitle.BackgroundTransparency = 1
KeyTitle.Text = "DRIP CLIENT AUTH"
KeyTitle.TextColor3 = Color3.new(1, 1, 1)
KeyTitle.Font = Enum.Font.GothamBold
KeyTitle.TextSize = 15

local InfoFrame = Instance.new("Frame")
InfoFrame.Parent = KeyFrame
InfoFrame.Size = UDim2.new(0.9, 0, 0, 55)
InfoFrame.Position = UDim2.new(0.05, 0, 0.22, 0)
InfoFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
InfoFrame.BackgroundTransparency = 0.4
local InfoCorner = Instance.new("UICorner")
InfoCorner.Parent = InfoFrame
InfoCorner.CornerRadius = UDim.new(0, 10)

local InfoText = Instance.new("TextLabel")
InfoText.Parent = InfoFrame
InfoText.Size = UDim2.new(1, -20, 1, 0)
InfoText.Position = UDim2.new(0, 10, 0, 0)
InfoText.BackgroundTransparency = 1
InfoText.Text = "Masukkan Key Premium untuk memuat menu cheat"
InfoText.TextColor3 = Color3.fromRGB(180, 180, 190)
InfoText.Font = Enum.Font.Gotham
InfoText.TextSize = 12
InfoText.TextWrapped = true

local KeyTextBox = Instance.new("TextBox")
KeyTextBox.Parent = KeyFrame
KeyTextBox.Size = UDim2.new(0.8, 0, 0, 42)
KeyTextBox.Position = UDim2.new(0.1, 0, 0.42, 0)
KeyTextBox.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
KeyTextBox.TextColor3 = Color3.new(1, 1, 1)
KeyTextBox.PlaceholderText = "Masukkan key..."
KeyTextBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
KeyTextBox.Font = Enum.Font.Gotham
KeyTextBox.TextSize = 13
KeyTextBox.ClearTextOnFocus = true
local KeyBoxCorner = Instance.new("UICorner")
KeyBoxCorner.Parent = KeyTextBox
KeyBoxCorner.CornerRadius = UDim.new(0, 8)

local VerifyBtn = Instance.new("TextButton")
VerifyBtn.Parent = KeyFrame
VerifyBtn.Size = UDim2.new(0.8, 0, 0, 42)
VerifyBtn.Position = UDim2.new(0.1, 0, 0.56, 0)
VerifyBtn.BackgroundColor3 = themeColor
VerifyBtn.BackgroundTransparency = 0.1
VerifyBtn.Text = "VERIFIKASI"
VerifyBtn.TextColor3 = Color3.new(1, 1, 1)
VerifyBtn.Font = Enum.Font.GothamBold
VerifyBtn.TextSize = 14
local VerifyCorner = Instance.new("UICorner")
VerifyCorner.Parent = VerifyBtn
VerifyCorner.CornerRadius = UDim.new(0, 8)

local WebsiteBtn = Instance.new("TextButton")
WebsiteBtn.Parent = KeyFrame
WebsiteBtn.Size = UDim2.new(0.4, 0, 0, 32)
WebsiteBtn.Position = UDim2.new(0.3, 0, 0.70, 0)
WebsiteBtn.BackgroundColor3 = Color3.fromRGB(240, 140, 0)
WebsiteBtn.BackgroundTransparency = 0.2
WebsiteBtn.Text = "GET KEY"
WebsiteBtn.TextColor3 = Color3.new(1, 1, 1)
WebsiteBtn.Font = Enum.Font.GothamBold
WebsiteBtn.TextSize = 13
local WebsiteCorner = Instance.new("UICorner")
WebsiteCorner.Parent = WebsiteBtn
WebsiteCorner.CornerRadius = UDim.new(0, 6)

local StatusFrame = Instance.new("Frame")
StatusFrame.Parent = KeyFrame
StatusFrame.Size = UDim2.new(0.9, 0, 0, 38)
StatusFrame.Position = UDim2.new(0.05, 0, 0.82, 0)
StatusFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
StatusFrame.BackgroundTransparency = 0.4
local StatusCorner = Instance.new("UICorner")
StatusCorner.Parent = StatusFrame
StatusCorner.CornerRadius = UDim.new(0, 8)

local StatusIcon = Instance.new("TextLabel")
StatusIcon.Parent = StatusFrame
StatusIcon.Size = UDim2.new(0, 30, 1, 0)
StatusIcon.Position = UDim2.new(0, 5, 0, 0)
StatusIcon.BackgroundTransparency = 1
StatusIcon.Text = "LOCK"
StatusIcon.TextSize = 14
StatusIcon.TextColor3 = Color3.fromRGB(255, 255, 0)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Parent = StatusFrame
StatusLabel.Size = UDim2.new(1, -40, 1, 0)
StatusLabel.Position = UDim2.new(0, 35, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Menunggu key..."
StatusLabel.TextColor3 = Color3.new(1, 1, 1)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

WebsiteBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(WEBSITE_URL)
        StatusLabel.Text = "Link disalin"
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        showNotification("BERHASIL", "Link key disalin", 2, Color3.fromRGB(0, 120, 0))
    else
        StatusLabel.Text = WEBSITE_URL
    end
end)

-- ================== CORE MECHANICS ==================
local function startFlyMode()
    local plr = LocalPlayer
    if not plr.Character then return end
    flyTorso = plr.Character:FindFirstChild("UpperTorso") or plr.Character:FindFirstChild("Torso") or plr.Character:FindFirstChild("HumanoidRootPart")
    if not flyTorso then return end
    ctrl = {f = 0, b = 0, l = 0, r = 0}
    speed = 0
    if plr.Character:FindFirstChildOfClass("Humanoid") then plr.Character:FindFirstChildOfClass("Humanoid").PlatformStand = true end
    
    local flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.Name = "FlyBG"
    flyBodyGyro.P = 9e4
    flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBodyGyro.Parent = flyTorso

    local flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.Name = "FlyBV"
    flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBodyVelocity.Parent = flyTorso

    flyConnection = RunService.RenderStepped:Connect(function()
        if not flyEnabled or not plr.Character or not flyTorso:IsDescendantOf(workspace) then return end
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then ctrl.f = 1 else ctrl.f = 0 end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then ctrl.b = -1 else ctrl.b = 0 end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then ctrl.l = -1 else ctrl.l = 0 end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then ctrl.r = 1 else ctrl.r = 0 end
        
        local forwardInput = (flyAutoForward and ctrl.f == 0 and ctrl.b == 0) and 1 or (ctrl.f + ctrl.b)
        if forwardInput ~= 0 or ctrl.l + ctrl.r ~= 0 then
            speed = math.min(speed + 1.5, flySpeed)
            local camCF = Camera.CFrame
            flyBodyVelocity.Velocity = ((camCF.LookVector * forwardInput) + (camCF.RightVector * (ctrl.l + ctrl.r))).Unit * speed
        else
            speed = math.max(speed - 2, 0)
            flyBodyVelocity.Velocity = Vector3.new(0,0,0)
        end
        flyBodyGyro.CFrame = Camera.CFrame
    end)
end

local function stopFlyMode()
    flyEnabled = false
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end
    local char = LocalPlayer.Character
    if char then
        if char:FindFirstChildOfClass("Humanoid") then char:FindFirstChildOfClass("Humanoid").PlatformStand = false end
        local t = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
        if t then
            if t:FindFirstChild("FlyBV") then t.FlyBV:Destroy() end
            if t:FindFirstChild("FlyBG") then t.FlyBG:Destroy() end
        end
    end
end

local function startNoclip()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Stepped:Connect(function()
        if noclipEnabled and LocalPlayer.Character then
            for _, p in pairs(LocalPlayer.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end)
end

local function stopNoclip()
    if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
end

local function toggleSpin(state)
    spinEnabled = state
    if spinConnection then spinConnection:Disconnect() spinConnection = nil end
    if state then
        spinConnection = RunService.Heartbeat:Connect(function()
            if spinEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame *= CFrame.Angles(0, math.rad(spinSpeed * spinDirection), 0)
            end
        end)
    end
end

local function toggleInvisible(state)
    invisibleEnabled = state
    if invisibleConnection then invisibleConnection:Disconnect() invisibleConnection = nil end
    if state and LocalPlayer.Character then
        invisibleRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        invisibleHumanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        invisibleParts = {}
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.Transparency == 0 then table.insert(invisibleParts, v) v.Transparency = 0.5 end
        end
        invisibleConnection = RunService.Heartbeat:Connect(function()
            if invisibleEnabled and invisibleRootPart and invisibleHumanoid then
                local oldCF = invisibleRootPart.CFrame
                local oldOffset = invisibleHumanoid.CameraOffset
                local hideCF = oldCF * CFrame.new(0, -500000, 0)
                invisibleRootPart.CFrame = hideCF
                invisibleHumanoid.CameraOffset = hideCF:ToObjectSpace(CFrame.new(oldCF.Position)).Position
                RunService.RenderStepped:Wait()
                invisibleRootPart.CFrame = oldCF
                invisibleHumanoid.CameraOffset = oldOffset
            end
        end)
    else
        if LocalPlayer.Character then
            for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then v.Transparency = 0 end
            end
        end
    end
end

local function setupAntiDamage()
    if antiDamageHeartbeat then antiDamageHeartbeat:Disconnect() end
    antiDamageHeartbeat = RunService.Heartbeat:Connect(function()
        if antiDamageEnabled and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then 
                if hum.Health < hum.MaxHealth or hum.Health <= 0 then hum.Health = hum.MaxHealth end
            end
        end
    end)
end

UserInputService.JumpRequest:Connect(function()
    if infinityJumpEnabled and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Loop Sinkronisasi Fitur Player
RunService.Heartbeat:Connect(function()
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            if jumpPowerEnabled then
                hum.UseJumpPower = true
                hum.JumpPower = jumpPowerValue
            end
        end
    end
end)

-- ================== ESP DRAWINGS SYSTEM ==================
local function createPlayerCounter()
    if enemyCountText then pcall(function() enemyCountText:Remove() end) end
    enemyCountText = Drawing.new("Text")
    enemyCountText.Size = 24
    enemyCountText.Color = redColor
    enemyCountText.Center = true
    enemyCountText.Outline = true
    enemyCountText.Position = Vector2.new(Camera.ViewportSize.X / 2, 55)
    enemyCountText.Visible = false
    enemyCountText.Text = "PLAYERS: 0"
end

local function createESP(player)
    if player == LocalPlayer then return end
    local box = Drawing.new("Square") box.Thickness = 2 box.Filled = false box.Visible = false
    local name = Drawing.new("Text") name.Size = 14 name.Center = true name.Outline = true name.Visible = false
    local dist = Drawing.new("Text") dist.Size = 12 dist.Center = true dist.Outline = true dist.Visible = false
    local line = Drawing.new("Line") line.Thickness = 2 line.Visible = false
    local healthBg = Drawing.new("Square") healthBg.Filled = true healthBg.Visible = false
    local healthFg = Drawing.new("Square") healthFg.Filled = true healthFg.Visible = false
    ESPTable[player] = {box, name, dist, line, healthBg, healthFg}
end

local function createSkeleton(player)
    if player == LocalPlayer then return end
    local lines = {}
    local joints = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}
    }
    for i=1, #joints do
        local l = Drawing.new("Line") l.Thickness = 2.5 l.Color = skeletonColor l.Visible = false
        table.insert(lines, {l, joints[i][1], joints[i][2]})
    end
    SkeletonESP[player] = lines
end

RunService.RenderStepped:Connect(function()
    local myChar = LocalPlayer.Character
    local myPos = myChar and myChar:FindFirstChild("HumanoidRootPart") and myChar.HumanoidRootPart.Position
    local screenCount = 0

    for player, esp in pairs(ESPTable) do
        local box, name, distText, line, hBg, hFg = unpack(esp)
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") then
            local hrp = char.HumanoidRootPart
            local head = char.Head
            local hum = char:FindFirstChildOfClass("Humanoid")
            local pos, visible = Camera:WorldToViewportPoint(hrp.Position)
            local distance = myPos and (myPos - hrp.Position).Magnitude or 9999
            
            if visible and distance <= MAX_ESP_DISTANCE then
                screenCount = screenCount + 1
                local top = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local bottom = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                local height = math.abs(top.Y - bottom.Y)
                local width = height / 2

                if espEnabled then
                    box.Size = Vector2.new(width, height)
                    box.Position = Vector2.new(pos.X - width/2, top.Y)
                    box.Color = boxColor
                    box.Visible = true

                    name.Position = Vector2.new(pos.X, top.Y - 16)
                    name.Text = player.DisplayName or player.Name
                    name.Visible = true

                    distText.Text = math.floor(distance).."m"
                    distText.Position = Vector2.new(pos.X, bottom.Y + 4)
                    distText.Visible = true

                    if hum then
                        local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        hBg.Size = Vector2.new(5, height)
                        hBg.Position = Vector2.new(pos.X + width/2 + 3, top.Y)
                        hBg.Color = Color3.fromRGB(40,40,40)
                        hBg.Visible = true

                        hFg.Size = Vector2.new(5, height * pct)
                        hFg.Position = Vector2.new(pos.X + width/2 + 3, bottom.Y - (height * pct))
                        hFg.Color = Color3.fromRGB(255 * (1-pct), 255 * pct, 0)
                        hFg.Visible = true
                    end
                else
                    box.Visible = false name.Visible = false distText.Visible = false hBg.Visible = false hFg.Visible = false
                end
            else
                box.Visible = false name.Visible = false distText.Visible = false hBg.Visible = false hFg.Visible = false
            end

            if lineEnabled and visible then
                line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                line.To = Vector2.new(pos.X, pos.Y)
                line.Color = lineColor -- Mengikuti konfigurasi warna dari List Warna aktif
                line.Visible = true
            else
                line.Visible = false
            end
        end
    end

    if skeletonEnabled then
        for player, lines in pairs(SkeletonESP) do
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") and myPos then
                for _, lData in pairs(lines) do
                    local l, p1, p2 = lData[1], char:FindFirstChild(lData[2]), char:FindFirstChild(lData[3])
                    if p1 and p2 then
                        local pos1, vis1 = Camera:WorldToViewportPoint(p1.Position)
                        local pos2, vis2 = Camera:WorldToViewportPoint(p2.Position)
                        if vis1 and vis2 then
                            l.From = Vector2.new(pos1.X, pos1.Y)
                            l.To = Vector2.new(pos2.X, pos2.Y)
                            l.Visible = true
                        else l.Visible = false end
                    else l.Visible = false end
                end
            else
                for _, ld in pairs(lines) do ld[1].Visible = false end
            end
        end
    else
        for _, lines in pairs(SkeletonESP) do for _, ld in pairs(lines) do ld[1].Visible = false end end
    end

    if playerCounterEnabled and enemyCountText then
        enemyCountText.Text = "PLAYERS: " .. screenCount
        enemyCountText.Visible = true
    elseif enemyCountText then
        enemyCountText.Visible = false
    end
end)

-- ================== HUB MAIN INTERFACE ==================
local function loadMainScript()
    if game.CoreGui:FindFirstChild("DripKeySystem") then
        game.CoreGui.DripKeySystem:Destroy()
    end
    createPlayerCounter()
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Parent = game.CoreGui
    ScreenGui.Name = "DripClient"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = ScreenGui
    mainFrame.Size = UDim2.new(0, 400, 0, 520)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -260)
    mainFrame.BackgroundColor3 = darkPurple
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.Active = true
    mainFrame.Draggable = true
    local mainCorner = Instance.new("UICorner") mainCorner.CornerRadius = UDim.new(0, 20) mainCorner.Parent = mainFrame
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Parent = mainFrame
    mainStroke.Color = themeColor
    mainStroke.Thickness = 2.5
    mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local header = Instance.new("Frame")
    header.Parent = mainFrame header.Size = UDim2.new(1, 0, 0, 65) header.BackgroundColor3 = themeColor header.BackgroundTransparency = 0.2
    local headerCorner = Instance.new("UICorner") headerCorner.CornerRadius = UDim.new(0, 20) headerCorner.Parent = header
    
    local logoImage = Instance.new("ImageLabel")
    logoImage.Parent = header logoImage.Size = UDim2.new(0, 42, 0, 42) logoImage.Position = UDim2.new(0, 15, 0, 12) logoImage.BackgroundTransparency = 1 logoImage.Image = "rbxassetid://72495850369898" logoImage.ScaleType = Enum.ScaleType.Fit
    
    local title = Instance.new("TextLabel")
    title.Parent = header title.Size = UDim2.new(1, -70, 0.5, 0) title.Position = UDim2.new(0, 65, 0, 12) title.BackgroundTransparency = 1 title.Text = "DRIP CLIENT" title.TextColor3 = Color3.new(1,1,1) title.Font = Enum.Font.GothamBlack title.TextSize = 22 title.TextXAlignment = Enum.TextXAlignment.Left
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Parent = header subtitle.Size = UDim2.new(1, -70, 0.3, 0) subtitle.Position = UDim2.new(0, 65, 0, 36) subtitle.BackgroundTransparency = 1 subtitle.Text = "V8.0" subtitle.TextColor3 = Color3.fromRGB(0, 255, 0) subtitle.Font = Enum.Font.Gotham subtitle.TextSize = 11 subtitle.TextXAlignment = Enum.TextXAlignment.Left

    local tabBar = Instance.new("Frame")
    tabBar.Parent = mainFrame tabBar.Size = UDim2.new(0.94, 0, 0, 38) tabBar.Position = UDim2.new(0.03, 0, 0, 75) tabBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55) tabBar.BackgroundTransparency = 0.4
    local tabBarCorner = Instance.new("UICorner") tabBarCorner.CornerRadius = UDim.new(0, 8) tabBarCorner.Parent = tabBar

    local tabs, contents = {}, {}
    local function createTab(name, idx)
        local btn = Instance.new("TextButton")
        btn.Parent = tabBar btn.Size = UDim2.new(0.25, -2, 1, -6) btn.Position = UDim2.new((idx-1)*0.25, 2, 0, 3) btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70) btn.BackgroundTransparency = 0.6 btn.Text = name btn.TextColor3 = Color3.fromRGB(190, 190, 190) btn.Font = Enum.Font.GothamBold btn.TextSize = 11
        local btnCorner = Instance.new("UICorner") btnCorner.CornerRadius = UDim.new(0, 6) btnCorner.Parent = btn
        
        local content = Instance.new("ScrollingFrame")
        content.Parent = mainFrame content.Size = UDim2.new(0.94, 0, 0, 380) content.Position = UDim2.new(0.03, 0, 0, 122) content.BackgroundColor3 = Color3.fromRGB(25, 25, 35) content.BackgroundTransparency = 0.5 content.BorderSizePixel = 0 content.ScrollBarThickness = 6 content.ScrollBarImageColor3 = themeColor
        content.CanvasSize = UDim2.new(0, 0, 0, 0) content.Visible = false content.AutomaticCanvasSize = Enum.AutomaticSize.Y content.ScrollingDirection = Enum.ScrollingDirection.Y content.ElasticBehavior = Enum.ElasticBehavior.Never
        local contentCorner = Instance.new("UICorner") contentCorner.CornerRadius = UDim.new(0, 10) contentCorner.Parent = content
        local layout = Instance.new("UIListLayout") layout.Parent = content layout.Padding = UDim.new(0, 8) layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        table.insert(tabs, btn) table.insert(contents, content)
        
        btn.MouseButton1Click:Connect(function()
            for i, b in ipairs(tabs) do b.TextColor3 = Color3.fromRGB(190, 190, 190) b.BackgroundTransparency = 0.6 contents[i].Visible = false end
            btn.TextColor3 = Color3.new(1,1,1) btn.BackgroundTransparency = 0.2 content.Visible = true
            task.wait(0.02)
            local h = 0 for _, c in pairs(content:GetChildren()) do if c:IsA("Frame") then h = h + c.Size.Y.Offset + 8 end end
            content.CanvasSize = UDim2.new(0, 0, 0, h + 30)
        end)
        return content
    end
    
    local tabMain = createTab("MAIN", 1)
    local tabESP = createTab("ESP SYSTEM", 2)
    local tabUtility = createTab("UTILITY", 3)
    local tabInfo = createTab("INFO", 4)

    local function createToggle(parent, text, default, callback)
        local frame = Instance.new("Frame") frame.Parent = parent frame.Size = UDim2.new(0.95, 0, 0, 42) frame.BackgroundColor3 = Color3.fromRGB(50, 50, 60) frame.BackgroundTransparency = 0.2
        local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, 8) corner.Parent = frame
        local label = Instance.new("TextLabel") label.Parent = frame label.Size = UDim2.new(0.65, 0, 1, 0) label.Position = UDim2.new(0.05, 0, 0, 0) label.BackgroundTransparency = 1 label.Text = text label.TextColor3 = Color3.new(1,1,1) label.Font = Enum.Font.Gotham label.TextSize = 13 label.TextXAlignment = Enum.TextXAlignment.Left
        
        local switch = Instance.new("Frame") switch.Parent = frame switch.Size = UDim2.new(0, 44, 0, 22) switch.Position = UDim2.new(0.83, 0, 0.5, -11) switch.BackgroundColor3 = default and themeColor or Color3.fromRGB(80, 80, 90)
        local sCorner = Instance.new("UICorner") sCorner.CornerRadius = UDim.new(0, 11) sCorner.Parent = switch
        local circle = Instance.new("Frame") circle.Parent = switch circle.Size = UDim2.new(0, 18, 0, 18) circle.Position = default and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0.05, 0, 0.5, -9) circle.BackgroundColor3 = Color3.new(1,1,1)
        local cCorner = Instance.new("UICorner") cCorner.CornerRadius = UDim.new(1, 0) cCorner.Parent = circle
        
        local state = default
        local click = Instance.new("TextButton") click.Parent = frame click.Size = UDim2.new(1, 0, 1, 0) click.BackgroundTransparency = 1 click.Text = ""
        click.MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(switch, TweenInfo.new(0.2), {BackgroundColor3 = state and themeColor or Color3.fromRGB(80, 80, 90)}):Play()
            TweenService:Create(circle, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0.05, 0, 0.5, -9)}):Play()
            callback(state)
        end)
        return frame
    end

    -- SUB-MENU JUMP POWER PINGGIR
    local function createJumpPowerMenu(parent)
        local baseFrame = Instance.new("Frame") baseFrame.Parent = parent baseFrame.Size = UDim2.new(0.95, 0, 0, 42) baseFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60) baseFrame.BackgroundTransparency = 0.2 baseFrame.ClipsDescendants = true
        local baseCorner = Instance.new("UICorner") baseCorner.CornerRadius = UDim.new(0, 8) baseCorner.Parent = baseFrame
        
        local mainButton = Instance.new("TextButton") mainButton.Parent = baseFrame mainButton.Size = UDim2.new(1, 0, 0, 42) mainButton.BackgroundTransparency = 1 mainButton.Text = "Jump Power" mainButton.TextColor3 = Color3.new(1,1,1) mainButton.Font = Enum.Font.GothamBold mainButton.TextSize = 13 mainButton.TextXAlignment = Enum.TextXAlignment.Left mainButton.Position = UDim2.new(0.05, 0, 0, 0)
        
        local toggleFrame = Instance.new("Frame") toggleFrame.Parent = baseFrame toggleFrame.Size = UDim2.new(0.9, 0, 0, 35) toggleFrame.Position = UDim2.new(0.05, 0, 0, 45) toggleFrame.BackgroundTransparency = 1
        local tLabel = Instance.new("TextLabel") tLabel.Parent = toggleFrame tLabel.Size = UDim2.new(0.6, 0, 1, 0) tLabel.BackgroundTransparency = 1 tLabel.Text = "Aktifkan Custom Power" tLabel.TextColor3 = Color3.new(1,1,1) tLabel.Font = Enum.Font.Gotham tLabel.TextSize = 12 tLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local tSwitch = Instance.new("TextButton") tSwitch.Parent = toggleFrame tSwitch.Size = UDim2.new(0, 50, 0, 22) tSwitch.Position = UDim2.new(0.75, 0, 0.5, -11) tSwitch.BackgroundColor3 = Color3.fromRGB(80, 80, 90) tSwitch.Text = "OFF" tSwitch.TextColor3 = Color3.new(1,1,1) tSwitch.Font = Enum.Font.GothamBold tSwitch.TextSize = 10
        Instance.new("UICorner", tSwitch).CornerRadius = UDim.new(0, 6)
        
        tSwitch.MouseButton1Click:Connect(function()
            jumpPowerEnabled = not jumpPowerEnabled
            tSwitch.Text = jumpPowerEnabled and "ON" or "OFF"
            tSwitch.BackgroundColor3 = jumpPowerEnabled and themeColor or Color3.fromRGB(80, 80, 90)
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then if not jumpPowerEnabled then hum.JumpPower = 50 end end
        end)

        local inputFrame = Instance.new("Frame") inputFrame.Parent = baseFrame inputFrame.Size = UDim2.new(0.9, 0, 0, 35) inputFrame.Position = UDim2.new(0.05, 0, 0, 82) inputFrame.BackgroundTransparency = 1
        local iLabel = Instance.new("TextLabel") iLabel.Parent = inputFrame iLabel.Size = UDim2.new(0.6, 0, 1, 0) iLabel.BackgroundTransparency = 1 iLabel.Text = "Atur Power (Value):" iLabel.TextColor3 = Color3.new(1,1,1) iLabel.Font = Enum.Font.Gotham iLabel.TextSize = 12 iLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local valBox = Instance.new("TextBox") valBox.Parent = inputFrame valBox.Size = UDim2.new(0, 65, 0, 26) valBox.Position = UDim2.new(0.72, 0, 0.5, -13) valBox.BackgroundColor3 = Color3.fromRGB(30, 30, 40) valBox.TextColor3 = Color3.fromRGB(0, 255, 0) valBox.Font = Enum.Font.GothamBold valBox.TextSize = 12 valBox.Text = tostring(jumpPowerValue) valBox.ClearTextOnFocus = false
        Instance.new("UICorner", valBox).CornerRadius = UDim.new(0, 5)
        
        valBox.FocusLost:Connect(function()
            local num = tonumber(valBox.Text)
            if num then jumpPowerValue = num else valBox.Text = tostring(jumpPowerValue) end
        end)

        local isOpen = false
        mainButton.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            TweenService:Create(baseFrame, TweenInfo.new(0.2), {Size = isOpen and UDim2.new(0.95, 0, 0, 125) or UDim2.new(0.95, 0, 0, 42)}):Play()
            task.wait(0.22)
            local h = 0 for _, c in pairs(parent:GetChildren()) do if c:IsA("Frame") then h = h + c.Size.Y.Offset + 8 end end parent.CanvasSize = UDim2.new(0, 0, 0, h + 30)
        end)
    end

    -- TAB MAIN FEATURES LIST
    createToggle(tabMain, "Fly Mode", false, function(s) flyEnabled = s if s then startFlyMode() else stopFlyMode() end end)
    createToggle(tabMain, "Speed Boost", false, function(s) speedEnabled = s local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") if hum then hum.WalkSpeed = s and fastSpeed or normalSpeed end end)
    createToggle(tabMain, "NoClip", false, function(s) noclipEnabled = s if s then startNoclip() else stopNoclip() end end)
    createToggle(tabMain, "Infinity Jump", false, function(s) infinityJumpEnabled = s end)
    
    createJumpPowerMenu(tabMain)

    createToggle(tabMain, "God Mode", false, function(s) antiDamageEnabled = s if s then setupAntiDamage() else if antiDamageHeartbeat then antiDamageHeartbeat:Disconnect() end end end)
    createToggle(tabMain, "Spin Muter", false, function(s) toggleSpin(s) end)
    createToggle(tabMain, "Invisible Mode", false, function(s) toggleInvisible(s) end)

    -- TAB ESP SYSTEM
    createToggle(tabESP, "ESP Box (Hitam)", false, function(s) espEnabled = s end)
    createToggle(tabESP, "ESP Line", false, function(s) lineEnabled = s end)
    createToggle(tabESP, "ESP Skeleton", false, function(s) skeletonEnabled = s end)
    createToggle(tabESP, "Player Counter", false, function(s) playerCounterEnabled = s end)

    -- TAB UTILITY (Teleport)
    local function createTeleportDropdown(parent)
        local baseFrame = Instance.new("Frame") baseFrame.Parent = parent baseFrame.Size = UDim2.new(0.95, 0, 0, 42) baseFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60) baseFrame.BackgroundTransparency = 0.2 baseFrame.ClipsDescendants = true
        local baseCorner = Instance.new("UICorner") baseCorner.CornerRadius = UDim.new(0, 8) baseCorner.Parent = baseFrame
        local mainButton = Instance.new("TextButton") mainButton.Parent = baseFrame mainButton.Size = UDim2.new(1, 0, 0, 42) mainButton.BackgroundTransparency = 1 mainButton.Text = "TELEPORT TO PLAYER" mainButton.TextColor3 = Color3.new(1,1,1) mainButton.Font = Enum.Font.GothamBold mainButton.TextSize = 13
        
        local scrollList = Instance.new("ScrollingFrame") scrollList.Parent = baseFrame scrollList.Size = UDim2.new(1, 0, 0, 140) scrollList.Position = UDim2.new(0, 0, 0, 42) scrollList.BackgroundTransparency = 1 scrollList.ScrollBarThickness = 5 scrollList.ScrollBarImageColor3 = themeColor
        local listLayout = Instance.new("UIListLayout") listLayout.Parent = scrollList listLayout.Padding = UDim.new(0, 5) listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        local isOpen = false
        mainButton.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            if isOpen then
                for _, c in pairs(scrollList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer then
                        local pBtn = Instance.new("TextButton") pBtn.Parent = scrollList pBtn.Size = UDim2.new(0.92, 0, 0, 28) pBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45) pBtn.TextColor3 = Color3.fromRGB(230, 230, 230) pBtn.Font = Enum.Font.Gotham pBtn.TextSize = 12 pBtn.Text = plr.DisplayName or plr.Name
                        Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 5)
                        pBtn.MouseButton1Click:Connect(function()
                            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0)
                                showNotification("TELEPORT", "Teleport ke " .. plr.Name, 2, Color3.fromRGB(0,140,0))
                            end
                            isOpen = false TweenService:Create(baseFrame, TweenInfo.new(0.2), {Size = UDim2.new(0.95, 0, 0, 42)}):Play()
                        end)
                    end
                end
                scrollList.CanvasSize = UDim2.new(0,0,0, listLayout.AbsoluteContentSize.Y + 10)
                TweenService:Create(baseFrame, TweenInfo.new(0.2), {Size = UDim2.new(0.95, 0, 0, 190)}):Play()
            else
                TweenService:Create(baseFrame, TweenInfo.new(0.2), {Size = UDim2.new(0.95, 0, 0, 42)}):Play()
            end
            task.wait(0.22)
            local h = 0 for _, c in pairs(parent:GetChildren()) do if c:IsA("Frame") then h = h + c.Size.Y.Offset + 8 end end parent.CanvasSize = UDim2.new(0, 0, 0, h + 30)
        end)
    end
    createTeleportDropdown(tabUtility)

    -- FITUR BARU (TAB UTILITY): DROPDOWN LIST WARNA KHUSUS ESP LINE
    local function createColorListDropdown(parent)
        local baseFrame = Instance.new("Frame") baseFrame.Parent = parent baseFrame.Size = UDim2.new(0.95, 0, 0, 42) baseFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60) baseFrame.BackgroundTransparency = 0.2 baseFrame.ClipsDescendants = true
        local baseCorner = Instance.new("UICorner") baseCorner.CornerRadius = UDim.new(0, 8) baseCorner.Parent = baseFrame
        local mainButton = Instance.new("TextButton") mainButton.Parent = baseFrame mainButton.Size = UDim2.new(1, 0, 0, 42) mainButton.BackgroundTransparency = 1 mainButton.Text = "LIST WARNA (ESP LINE)" mainButton.TextColor3 = Color3.new(1,1,1) mainButton.Font = Enum.Font.GothamBold mainButton.TextSize = 13
        
        local scrollList = Instance.new("ScrollingFrame") scrollList.Parent = baseFrame scrollList.Size = UDim2.new(1, 0, 0, 140) scrollList.Position = UDim2.new(0, 0, 0, 42) scrollList.BackgroundTransparency = 1 scrollList.ScrollBarThickness = 5 scrollList.ScrollBarImageColor3 = themeColor
        local listLayout = Instance.new("UIListLayout") listLayout.Parent = scrollList listLayout.Padding = UDim.new(0, 5) listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        -- Opsi list warna khusus mengubah ESP Line sesuai request
        local targetColors = {
            {name = "Hitam", color = Color3.fromRGB(0, 0, 0)},
            {name = "Putih", color = Color3.fromRGB(255, 255, 255)},
            {name = "Biru", color = Color3.fromRGB(0, 0, 255)},
            {name = "Hijau", color = Color3.fromRGB(0, 255, 0)},
            {name = "Kuning", color = Color3.fromRGB(255, 255, 0)},
            {name = "Merah", color = Color3.fromRGB(255, 0, 0)}
        }

        for _, item in ipairs(targetColors) do
            local cBtn = Instance.new("TextButton") cBtn.Parent = scrollList cBtn.Size = UDim2.new(0.92, 0, 0, 28) cBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45) cBtn.TextColor3 = item.color cBtn.Font = Enum.Font.GothamBold cBtn.TextSize = 12 cBtn.Text = item.name:upper()
            Instance.new("UICorner", cBtn).CornerRadius = UDim.new(0, 5)
            
            cBtn.MouseButton1Click:Connect(function()
                lineColor = item.color -- Mengubah variabel warna global ESP Line
                showNotification("WARNA ESP LINE", "Warna ESP Line berhasil diubah ke: " .. item.name, 2, item.color)
            end)
        end

        local isOpen = false
        mainButton.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            scrollList.CanvasSize = UDim2.new(0,0,0, listLayout.AbsoluteContentSize.Y + 10)
            if isOpen then
                TweenService:Create(baseFrame, TweenInfo.new(0.2), {Size = UDim2.new(0.95, 0, 0, 190)}):Play()
            else
                TweenService:Create(baseFrame, TweenInfo.new(0.2), {Size = UDim2.new(0.95, 0, 0, 42)}):Play()
            end
            task.wait(0.22)
            local h = 0 for _, c in pairs(parent:GetChildren()) do if c:IsA("Frame") then h = h + c.Size.Y.Offset + 8 end end parent.CanvasSize = UDim2.new(0, 0, 0, h + 30)
        end)
    end
    createColorListDropdown(tabUtility)

    -- TAB INFORMASI (Hanya Menyisakan Info Developer Saja)
    local infoBox = Instance.new("Frame", tabInfo) infoBox.Size = UDim2.new(0.95, 0, 0, 100) infoBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55) infoBox.BackgroundTransparency = 0.4
    Instance.new("UICorner", infoBox).CornerRadius = UDim.new(0, 10)
    
    local iLabel = Instance.new("TextLabel", infoBox) iLabel.Size = UDim2.new(1, 0, 0, 30) iLabel.BackgroundTransparency = 1 iLabel.Text = "DEVELOPER INFORMATION" iLabel.TextColor3 = themeColor iLabel.Font = Enum.Font.GothamBold iLabel.TextSize = 13

    local infoDevLabel = Instance.new("TextLabel", infoBox) infoDevLabel.Size = UDim2.new(0.92, 0, 0, 60) infoDevLabel.Position = UDim2.new(0.04, 0, 0, 30) infoDevLabel.BackgroundTransparency = 1 infoDevLabel.TextColor3 = Color3.fromRGB(200,210,255) infoDevLabel.Font = Enum.Font.Gotham infoDevLabel.TextSize = 12 infoDevLabel.Text = "DRIP CLIENT V8.0\nDeveloper: Putzzdev\nWhatsApp: 088976255131"

    tabs[1].TextColor3 = Color3.new(1,1,1) tabs[1].BackgroundTransparency = 0.2 contents[1].Visible = true
    
    local openBtn = Instance.new("ImageButton", ScreenGui) openBtn.Size = UDim2.new(0, 55, 0, 55) openBtn.Position = UDim2.new(0, 15, 0.5, -27) openBtn.BackgroundTransparency = 1 openBtn.Image = "rbxassetid://72495850369898" openBtn.Active = true openBtn.Draggable = true
    Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 12) local obs = Instance.new("UIStroke", openBtn) obs.Color = Color3.new(1,1,1) obs.Thickness = 1.5

    local menuOpen = true
    openBtn.MouseButton1Click:Connect(function()
        menuOpen = not menuOpen
        if menuOpen then mainFrame.Visible = true TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {Position = UDim2.new(0.5, -200, 0.5, -260)}):Play()
        else TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {Position = UDim2.new(0.5, -200, 1, 10)}):Play() task.wait(0.25) mainFrame.Visible = false end
    end)
    
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        if noclipEnabled then startNoclip() end
        if flyEnabled then startFlyMode() end
    end)
    
    print("DRIP CLIENT V8.0 - MENU SUCCESS")
end

-- ================== KEY VERIFICATION EVENT ==================
VerifyBtn.MouseButton1Click:Connect(function()
    local inputKey = KeyTextBox.Text:gsub("%s+", "")
    if inputKey == "" then 
        StatusLabel.Text = "Masukkan key!"
        StatusLabel.TextColor3 = Color3.fromRGB(255,0,0) 
        return 
    end
    
    StatusLabel.Text = "Memverifikasi..." 
    StatusLabel.TextColor3 = Color3.fromRGB(255,255,0) 
    StatusIcon.Text = "WAIT"
    
    local isValid, message = checkKeyExpiry(inputKey)
    
    if isValid then
        StatusLabel.Text = message 
        StatusLabel.TextColor3 = Color3.fromRGB(0,255,0) 
        StatusIcon.Text = "OK"
        
        task.wait(1)
        StatusLabel.Text = "Loading 3..."
        task.wait(1)
        StatusLabel.Text = "Loading 2..."
        task.wait(1)
        StatusLabel.Text = "Loading 1..."
        task.wait(1)
        
        pcall(loadMainScript)
    else
        StatusLabel.Text = message 
        StatusLabel.TextColor3 = Color3.fromRGB(255,0,0) 
        StatusIcon.Text = "X"
    end
end)

-- ================== INITIAL ESP SETUP ==================
for _, p in pairs(Players:GetPlayers()) do 
    createESP(p) 
    createSkeleton(p) 
end

Players.PlayerAdded:Connect(function(p) 
    createESP(p) 
    createSkeleton(p) 
end)

Players.PlayerRemoving:Connect(function(p)
    if ESPTable[p] then for _, d in pairs(ESPTable[p]) do pcall(function() d:Remove() end) end ESPTable[p] = nil end
    if SkeletonESP[p] then for _, ld in pairs(SkeletonESP[p]) do pcall(function() ld[1]:Remove() end) end SkeletonESP[p] = nil end
end)

print("DRIP CLIENT V8.0 BUILT COMPLETED SUCCESSFULLY")