-- ================== DRIP CLIENT V7.5 (HP EDITION + FLY FIX) ==================
-- Version: 7.5 (Khusus HP - Touch Control + Crosshair)
-- Developer: Putzz XD

-- ================== KEY SYSTEM CONFIG ==================
local FIREBASE_URL = "https://keyweb-f8e96-default-rtdb.europe-west1.firebasedatabase.app/keys.json"
local WEBSITE_URL = "https://putzzdevxit.github.io/KEY-GENERATOR-/"
local SCRIPT_NAME = "DRIP CLIENT"

local SAVE_FILE = "drip_key_data.txt"
local activeKeys = {}
local currentUserKey = nil
local keyExpiryTime = 0

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
local healthEnabled = false
local skeletonEnabled = false
local ESPTable = {}
local SkeletonESP = {}

-- Player Counter
local playerCounterEnabled = false
local enemyCountText = nil

-- Movement HP (Fly) - Fix dari FlyGuiV3
local flyEnabled = false
local flyConnection = nil
local flySpeed = 50
local ctrl = {f = 0, b = 0, l = 0, r = 0}
local lastctrl = {f = 0, b = 0, l = 0, r = 0}
local speed = 0
local maxspeed = 50
local flyBodyVelocity = nil
local flyBodyGyro = nil
local flyTorso = nil

-- Noclip
local noclipEnabled = false
local noclipConnection = nil

local speedEnabled = false
local normalSpeed = 16
local fastSpeed = 60

-- Combat
local infinityJumpEnabled = false
local crosshairEnabled = false
local crosshairObject = nil

-- Utility
local antiDamageEnabled = false
local antiDamageConnection = nil
local antiDamageThread = nil
local antiDamageHeartbeat = nil

local spinEnabled = false
local spinSpeed = 10
local spinConnection = nil
local spinDirection = 1

local invisibleEnabled = false
local invisibleConnection = nil
local invisibleParts = {}
local invisibleRootPart = nil
local invisibleHumanoid = nil

-- Warna Tema
local themeColor = Color3.fromRGB(156, 39, 176)
local darkPurple = Color3.fromRGB(74, 20, 90)
local boxColor = Color3.fromRGB(0, 255, 0)
local skeletonColor = Color3.fromRGB(0, 255, 0)
local MAX_ESP_DISTANCE = 115

-- ================== FUNGSI KEY SYSTEM ==================
local function loadKeyData()
    if isfile and isfile(SAVE_FILE) then
        local success, content = pcall(function()
            return readfile(SAVE_FILE)
        end)
        if success and content and content ~= "" then
            local success2, data = pcall(function()
                return HttpService:JSONDecode(content)
            end)
            if success2 then
                activeKeys = data
            end
        end
    end
end

local function saveKeyData()
    if writefile then
        local success, json = pcall(function()
            return HttpService:JSONEncode(activeKeys)
        end)
        if success then
            writefile(SAVE_FILE, json)
        end
    end
end

local function getKeysFromFirebase()
    local success, data = pcall(function()
        return game:HttpGet(FIREBASE_URL)
    end)
    
    if success and data then
        local success2, jsonData = pcall(function()
            return HttpService:JSONDecode(data)
        end)
        if success2 and jsonData then
            local keysArray = {}
            for _, keyData in pairs(jsonData) do
                table.insert(keysArray, keyData)
            end
            return keysArray
        end
    end
    return nil
end

local function getTimeRemaining(expiryTimestamp)
    local currentTime = os.time()
    local remaining = expiryTimestamp - currentTime
    
    if remaining <= 0 then
        return 0, 0, 0, 0, "EXPIRED"
    end
    
    local days = math.floor(remaining / 86400)
    local hours = math.floor((remaining % 86400) / 3600)
    local minutes = math.floor((remaining % 3600) / 60)
    local seconds = remaining % 60
    
    local timeStr = string.format("%d Hari : %02d Jam : %02d Menit : %02d Detik", 
        days, hours, minutes, seconds)
    
    return days, hours, minutes, seconds, timeStr
end

local function checkKeyExpiry(inputKey)
    loadKeyData()
    
    local keysData = getKeysFromFirebase()
    if not keysData then
        return false, "Gagal mengambil data key dari server"
    end
    
    local foundKey = nil
    local expiryDays = nil
    
    for _, keyData in ipairs(keysData) do
        if keyData.key == inputKey then
            foundKey = keyData.key
            
            if keyData.jenis == "1 JAM" then
                expiryDays = 1/24
            elseif keyData.jenis == "1 HARI" then
                expiryDays = 1
            elseif keyData.jenis == "2 HARI" then
                expiryDays = 2
            elseif keyData.jenis == "3 HARI" then
                expiryDays = 3
            elseif keyData.jenis == "7 HARI" then
                expiryDays = 7
            elseif keyData.jenis == "30 HARI" then
                expiryDays = 30
            elseif keyData.jenis == "PERMANEN" then
                expiryDays = 9999999
            else
                expiryDays = 1
            end
            break
        end
    end
    
    if not foundKey then
        return false, "KEY TIDAK TERDAFTAR!"
    end
    
    if activeKeys[inputKey] then
        local firstUsed = activeKeys[inputKey].firstUsed
        local currentTime = os.time()
        local expiryTime = firstUsed + (expiryDays * 86400)
        
        if currentTime > expiryTime then
            return false, "KEY SUDAH EXPIRED! (" .. expiryDays .. " hari)"
        else
            local days, hours, minutes, seconds, timeStr = getTimeRemaining(expiryTime)
            keyExpiryTime = expiryTime
            currentUserKey = inputKey
            return true, "KEY VALID! Sisa " .. timeStr
        end
    else
        local currentTime = os.time()
        activeKeys[inputKey] = {
            firstUsed = currentTime,
            key = inputKey,
            expiryDays = expiryDays
        }
        saveKeyData()
        
        local expiryTime = currentTime + (expiryDays * 86400)
        keyExpiryTime = expiryTime
        currentUserKey = inputKey
        
        return true, "KEY VALID! Berlaku " .. expiryDays .. " hari"
    end
end

local function showNotification(title, text, duration, color)
    local notif = Instance.new("Frame")
    notif.Parent = KeyGui
    notif.Size = UDim2.new(0, 300, 0, 70)
    notif.Position = UDim2.new(0.5, -150, 0, -80)
    notif.BackgroundColor3 = color or Color3.fromRGB(30, 30, 40)
    notif.BackgroundTransparency = 0.1
    notif.BorderSizePixel = 0
    notif.ZIndex = 999

    local notifCorner = Instance.new("UICorner")
    notifCorner.Parent = notif
    notifCorner.CornerRadius = UDim.new(0, 12)

    local notifTitle = Instance.new("TextLabel")
    notifTitle.Parent = notif
    notifTitle.Size = UDim2.new(1, 0, 0.5, 0)
    notifTitle.Position = UDim2.new(0, 0, 0, 5)
    notifTitle.BackgroundTransparency = 1
    notifTitle.Text = title
    notifTitle.TextColor3 = Color3.new(1, 1, 1)
    notifTitle.Font = Enum.Font.GothamBold
    notifTitle.TextSize = 18

    local notifText = Instance.new("TextLabel")
    notifText.Parent = notif
    notifText.Size = UDim2.new(1, 0, 0.5, 0)
    notifText.Position = UDim2.new(0, 0, 0, 35)
    notifText.BackgroundTransparency = 1
    notifText.Text = text
    notifText.TextColor3 = Color3.new(1, 1, 1)
    notifText.Font = Enum.Font.Gotham
    notifText.TextSize = 14

    TweenService:Create(notif, TweenInfo.new(0.5), {Position = UDim2.new(0.5, -150, 0, 20)}):Play()
    task.wait(duration or 3)
    TweenService:Create(notif, TweenInfo.new(0.5), {Position = UDim2.new(0.5, -150, 0, -80)}):Play()
    task.wait(0.5)
    notif:Destroy()
end

-- ================== GUI KEY SYSTEM ==================
local KeyGui = Instance.new("ScreenGui")
KeyGui.Name = "DripKeySystem"
KeyGui.Parent = game.CoreGui
KeyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
KeyGui.DisplayOrder = 999

local KeyFrame = Instance.new("Frame")
KeyFrame.Parent = KeyGui
KeyFrame.Size = UDim2.new(0, 400, 0, 380)
KeyFrame.Position = UDim2.new(0.5, -200, 0.5, -190)
KeyFrame.BackgroundColor3 = darkPurple
KeyFrame.BackgroundTransparency = 0.1
KeyFrame.BorderSizePixel = 0
KeyFrame.Active = true
KeyFrame.Draggable = true

local KeyCorner = Instance.new("UICorner")
KeyCorner.Parent = KeyFrame
KeyCorner.CornerRadius = UDim.new(0, 20)

local KeyBorder = Instance.new("Frame")
KeyBorder.Parent = KeyFrame
KeyBorder.Size = UDim2.new(1, 0, 1, 0)
KeyBorder.BackgroundTransparency = 1
KeyBorder.BorderSizePixel = 2
KeyBorder.BorderColor3 = themeColor

local KeyBorderCorner = Instance.new("UICorner")
KeyBorderCorner.Parent = KeyBorder
KeyBorderCorner.CornerRadius = UDim.new(0, 20)

local KeyHeader = Instance.new("Frame")
KeyHeader.Parent = KeyFrame
KeyHeader.Size = UDim2.new(1, 0, 0, 80)
KeyHeader.BackgroundTransparency = 1

local KeyIcon = Instance.new("TextLabel")
KeyIcon.Parent = KeyHeader
KeyIcon.Size = UDim2.new(1, 0, 0.5, 0)
KeyIcon.Position = UDim2.new(0, 0, 0, 10)
KeyIcon.BackgroundTransparency = 1
KeyIcon.Text = "🔐"
KeyIcon.TextColor3 = themeColor
KeyIcon.Font = Enum.Font.GothamBlack
KeyIcon.TextSize = 45

local KeyTitle = Instance.new("TextLabel")
KeyTitle.Parent = KeyHeader
KeyTitle.Size = UDim2.new(1, 0, 0.5, 0)
KeyTitle.Position = UDim2.new(0, 0, 0, 50)
KeyTitle.BackgroundTransparency = 1
KeyTitle.Text = "DRIP CLIENT AUTH"
KeyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyTitle.Font = Enum.Font.GothamBold
KeyTitle.TextSize = 16
KeyTitle.TextStrokeTransparency = 0.3
KeyTitle.TextStrokeColor3 = themeColor

local InfoFrame = Instance.new("Frame")
InfoFrame.Parent = KeyFrame
InfoFrame.Size = UDim2.new(0.9, 0, 0, 70)
InfoFrame.Position = UDim2.new(0.05, 0, 0.22, 0)
InfoFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
InfoFrame.BackgroundTransparency = 0.3
InfoFrame.BorderSizePixel = 0

local InfoCorner = Instance.new("UICorner")
InfoCorner.Parent = InfoFrame
InfoCorner.CornerRadius = UDim.new(0, 12)

local InfoText = Instance.new("TextLabel")
InfoText.Parent = InfoFrame
InfoText.Size = UDim2.new(1, -20, 1, -10)
InfoText.Position = UDim2.new(0, 10, 0, 5)
InfoText.BackgroundTransparency = 1
InfoText.Text = "Masukkan Key Anda untuk mengakses script premium"
InfoText.TextColor3 = Color3.fromRGB(200, 200, 200)
InfoText.Font = Enum.Font.Gotham
InfoText.TextSize = 13
InfoText.TextXAlignment = Enum.TextXAlignment.Left

local KeyLabel = Instance.new("TextLabel")
KeyLabel.Parent = KeyFrame
KeyLabel.Size = UDim2.new(0.8, 0, 0, 20)
KeyLabel.Position = UDim2.new(0.1, 0, 0.38, 0)
KeyLabel.BackgroundTransparency = 1
KeyLabel.Text = "MASUKAN KEY ANDA"
KeyLabel.TextColor3 = themeColor
KeyLabel.Font = Enum.Font.GothamBold
KeyLabel.TextSize = 12
KeyLabel.TextXAlignment = Enum.TextXAlignment.Left

local KeyTextBox = Instance.new("TextBox")
KeyTextBox.Parent = KeyFrame
KeyTextBox.Size = UDim2.new(0.8, 0, 0, 45)
KeyTextBox.Position = UDim2.new(0.1, 0, 0.42, 0)
KeyTextBox.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
KeyTextBox.BackgroundTransparency = 0.1
KeyTextBox.TextColor3 = Color3.new(1, 1, 1)
KeyTextBox.PlaceholderText = "Masukkan key..."
KeyTextBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
KeyTextBox.Font = Enum.Font.Gotham
KeyTextBox.TextSize = 14
KeyTextBox.ClearTextOnFocus = true

local KeyBoxCorner = Instance.new("UICorner")
KeyBoxCorner.Parent = KeyTextBox
KeyBoxCorner.CornerRadius = UDim.new(0, 10)

local VerifyBtn = Instance.new("TextButton")
VerifyBtn.Parent = KeyFrame
VerifyBtn.Size = UDim2.new(0.8, 0, 0, 45)
VerifyBtn.Position = UDim2.new(0.1, 0, 0.55, 0)
VerifyBtn.BackgroundColor3 = themeColor
VerifyBtn.BackgroundTransparency = 0.2
VerifyBtn.Text = "VERIFIKASI KEY"
VerifyBtn.TextColor3 = Color3.new(1, 1, 1)
VerifyBtn.Font = Enum.Font.GothamBold
VerifyBtn.TextSize = 16

local VerifyCorner = Instance.new("UICorner")
VerifyCorner.Parent = VerifyBtn
VerifyCorner.CornerRadius = UDim.new(0, 10)

local WebsiteBtn = Instance.new("TextButton")
WebsiteBtn.Parent = KeyFrame
WebsiteBtn.Size = UDim2.new(0.5, 0, 0, 35)
WebsiteBtn.Position = UDim2.new(0.25, 0, 0.67, 0)
WebsiteBtn.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
WebsiteBtn.BackgroundTransparency = 0.2
WebsiteBtn.Text = "GET KEY"
WebsiteBtn.TextColor3 = Color3.new(1, 1, 1)
WebsiteBtn.Font = Enum.Font.GothamBold
WebsiteBtn.TextSize = 14

local WebsiteCorner = Instance.new("UICorner")
WebsiteCorner.Parent = WebsiteBtn
WebsiteCorner.CornerRadius = UDim.new(0, 8)

local StatusFrame = Instance.new("Frame")
StatusFrame.Parent = KeyFrame
StatusFrame.Size = UDim2.new(0.9, 0, 0, 40)
StatusFrame.Position = UDim2.new(0.05, 0, 0.78, 0)
StatusFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
StatusFrame.BackgroundTransparency = 0.3
StatusFrame.BorderSizePixel = 0

local StatusCorner = Instance.new("UICorner")
StatusCorner.Parent = StatusFrame
StatusCorner.CornerRadius = UDim.new(0, 10)

local StatusIcon = Instance.new("TextLabel")
StatusIcon.Parent = StatusFrame
StatusIcon.Size = UDim2.new(0, 30, 1, 0)
StatusIcon.Position = UDim2.new(0, 5, 0, 0)
StatusIcon.BackgroundTransparency = 1
StatusIcon.Text = "🔒"
StatusIcon.TextColor3 = Color3.fromRGB(255, 255, 0)
StatusIcon.Font = Enum.Font.GothamBold
StatusIcon.TextSize = 18

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Parent = StatusFrame
StatusLabel.Size = UDim2.new(1, -40, 1, 0)
StatusLabel.Position = UDim2.new(0, 35, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Menunggu Key..."
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 13
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

local LoadingCircle = Instance.new("Frame")
LoadingCircle.Parent = KeyFrame
LoadingCircle.Size = UDim2.new(0, 30, 0, 30)
LoadingCircle.Position = UDim2.new(0.5, -15, 0.9, -15)
LoadingCircle.BackgroundColor3 = themeColor
LoadingCircle.BackgroundTransparency = 1
LoadingCircle.Visible = false

local CircleCorner = Instance.new("UICorner")
CircleCorner.Parent = LoadingCircle
CircleCorner.CornerRadius = UDim.new(1, 0)

local function showLoading(show)
    LoadingCircle.Visible = show
    if show then
        spawn(function()
            local rotation = 0
            while LoadingCircle.Visible do
                rotation = (rotation + 5) % 360
                LoadingCircle.Rotation = rotation
                task.wait(0.01)
            end
        end)
    end
end

WebsiteBtn.MouseButton1Click:Connect(function()
    local success = pcall(function()
        if setclipboard then
            setclipboard(WEBSITE_URL)
            StatusLabel.Text = "✓ Link disalin! Buka browser"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            StatusIcon.Text = "✅"
            showNotification("✅ LINK DISALIN!", "Buka browser dan paste linknya", 2, Color3.fromRGB(0, 150, 0))
        else
            StatusLabel.Text = "🌐 " .. WEBSITE_URL
            StatusLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
        end
    end)
end)

-- ================== FUNGSI FLY (DARI FLYGUI V3 - WORKING) ==================
local function startFlyMode()
    local plr = LocalPlayer
    local char = plr.Character
    if not char then return end
    
    -- Ambil torso (R6/R15 kompatibel)
    flyTorso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
    if not flyTorso then return end
    
    -- Reset variables
    ctrl = {f = 0, b = 0, l = 0, r = 0}
    lastctrl = {f = 0, b = 0, l = 0, r = 0}
    speed = 0
    maxspeed = 50
    
    -- Disable animasi dan platform stand
    if char:FindFirstChildOfClass("Humanoid") then
        char.Humanoid.PlatformStand = true
    end
    if char:FindFirstChild("Animate") then
        char.Animate.Disabled = true
    end
    
    -- Buat BodyGyro
    flyBodyGyro = flyTorso:FindFirstChild("FlyBG")
    if not flyBodyGyro then
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.Name = "FlyBG"
        flyBodyGyro.P = 9e4
        flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBodyGyro.Parent = flyTorso
    end
    
    -- Buat BodyVelocity
    flyBodyVelocity = flyTorso:FindFirstChild("FlyBV")
    if not flyBodyVelocity then
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.Name = "FlyBV"
        flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBodyVelocity.Parent = flyTorso
    end
    
    if flyConnection then flyConnection:Disconnect() end
    
    flyConnection = RunService.RenderStepped:Connect(function()
        if not flyEnabled then return end
        
        local currentChar = plr.Character
        if not currentChar then return end
        
        local currentTorso = currentChar:FindFirstChild("UpperTorso") or currentChar:FindFirstChild("Torso") or currentChar:FindFirstChild("HumanoidRootPart")
        if not currentTorso then return end
        
        local bv = currentTorso:FindFirstChild("FlyBV")
        local bg = currentTorso:FindFirstChild("FlyBG")
        if not bv or not bg then return end
        
        -- Update input WASD
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then ctrl.f = 1 else ctrl.f = 0 end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then ctrl.b = -1 else ctrl.b = 0 end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then ctrl.l = -1 else ctrl.l = 0 end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then ctrl.r = 1 else ctrl.r = 0 end
        
        -- Hitung speed
        if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
            speed = speed + 0.5 + (speed / maxspeed)
            if speed > maxspeed then speed = maxspeed end
        elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and speed ~= 0 then
            speed = speed - 1
            if speed < 0 then speed = 0 end
        end
        
        -- Terapkan velocity
        if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
            bv.Velocity = ((Camera.CFrame.LookVector * (ctrl.f + ctrl.b)) + 
                ((Camera.CFrame * CFrame.new(ctrl.l + ctrl.r, (ctrl.f + ctrl.b) * 0.2, 0).p) - Camera.CFrame.p)) * speed
            lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
        elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
            bv.Velocity = ((Camera.CFrame.LookVector * (lastctrl.f + lastctrl.b)) + 
                ((Camera.CFrame * CFrame.new(lastctrl.l + lastctrl.r, (lastctrl.f + lastctrl.b) * 0.2, 0).p) - Camera.CFrame.p)) * speed
        else
            bv.Velocity = Vector3.new(0, 0, 0)
        end
        
        -- Update gyro
        bg.CFrame = Camera.CFrame * CFrame.Angles(-math.rad((ctrl.f + ctrl.b) * 50 * speed / maxspeed), 0, 0)
    end)
end

local function stopFlyMode()
    flyEnabled = false
    
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    
    local plr = LocalPlayer
    local char = plr.Character
    if char then
        if char:FindFirstChildOfClass("Humanoid") then
            char.Humanoid.PlatformStand = false
        end
        if char:FindFirstChild("Animate") then
            char.Animate.Disabled = false
        end
        
        local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
        if torso then
            local bv = torso:FindFirstChild("FlyBV")
            if bv then bv:Destroy() end
            local bg = torso:FindFirstChild("FlyBG")
            if bg then bg:Destroy() end
        end
    end
    
    ctrl = {f = 0, b = 0, l = 0, r = 0}
    lastctrl = {f = 0, b = 0, l = 0, r = 0}
    speed = 0
end

-- ================== FUNGSI CROSSHAIR ==================
local function createCrosshair()
    if crosshairObject then
        pcall(function() crosshairObject:Destroy() end)
        crosshairObject = nil
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DripCrosshair"
    screenGui.Parent = game.CoreGui
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999
    
    local centerX = 0.5
    local centerY = 0.5
    
    local lineV = Instance.new("Frame")
    lineV.Parent = screenGui
    lineV.Size = UDim2.new(0, 2, 0, 30)
    lineV.Position = UDim2.new(centerX, -1, centerY, -15)
    lineV.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    lineV.BackgroundTransparency = 0
    lineV.BorderSizePixel = 0
    lineV.ZIndex = 999
    
    local lineH = Instance.new("Frame")
    lineH.Parent = screenGui
    lineH.Size = UDim2.new(0, 30, 0, 2)
    lineH.Position = UDim2.new(centerX, -15, centerY, -1)
    lineH.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    lineH.BackgroundTransparency = 0
    lineH.BorderSizePixel = 0
    lineH.ZIndex = 999
    
    local circle = Instance.new("Frame")
    circle.Parent = screenGui
    circle.Size = UDim2.new(0, 6, 0, 6)
    circle.Position = UDim2.new(centerX, -3, centerY, -3)
    circle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    circle.BackgroundTransparency = 0
    circle.BorderSizePixel = 0
    circle.ZIndex = 999
    local circleCorner = Instance.new("UICorner")
    circleCorner.Parent = circle
    circleCorner.CornerRadius = UDim.new(1, 0)
    
    crosshairObject = screenGui
end

local function removeCrosshair()
    if crosshairObject then
        pcall(function() crosshairObject:Destroy() end)
        crosshairObject = nil
    end
end

-- ================== FUNGSI NOCLIP ==================
local function startNoclip()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Stepped:Connect(function()
        if noclipEnabled and LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function stopNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    if LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- ================== FUNGSI UTILITY ==================
local function toggleSpin(state)
    spinEnabled = state
    if spinConnection then spinConnection:Disconnect() spinConnection = nil end
    if state then
        spinConnection = RunService.Heartbeat:Connect(function()
            if spinEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local rootPart = LocalPlayer.Character.HumanoidRootPart
                rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(spinSpeed * spinDirection), 0)
            end
        end)
    end
end

local function toggleSpinDirection()
    spinDirection = spinDirection * -1
end

local function updateInvisibleData()
    if LocalPlayer.Character then
        invisibleRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        invisibleHumanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        invisibleParts = {}
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.Transparency == 0 then
                table.insert(invisibleParts, v)
            end
        end
    end
end

local function toggleInvisible(state)
    invisibleEnabled = state
    if invisibleConnection then invisibleConnection:Disconnect() invisibleConnection = nil end
    updateInvisibleData()
    if state then
        for _, v in pairs(invisibleParts) do v.Transparency = 0.5 end
        invisibleConnection = RunService.Heartbeat:Connect(function()
            if invisibleEnabled and invisibleRootPart and invisibleHumanoid then
                local oldCF = invisibleRootPart.CFrame
                local oldOffset = invisibleHumanoid.CameraOffset
                local hideCF = oldCF * CFrame.new(0, -200000, 0)
                invisibleRootPart.CFrame = hideCF
                invisibleHumanoid.CameraOffset = hideCF:ToObjectSpace(CFrame.new(oldCF.Position)).Position
                RunService.RenderStepped:Wait()
                invisibleRootPart.CFrame = oldCF
                invisibleHumanoid.CameraOffset = oldOffset
            end
        end)
    else
        for _, v in pairs(invisibleParts) do v.Transparency = 0 end
    end
end

local function setupAntiDamage()
    if antiDamageHeartbeat then antiDamageHeartbeat:Disconnect() end
    if antiDamageConnection then antiDamageConnection:Disconnect() end
    if antiDamageThread then antiDamageThread = nil end
    
    antiDamageHeartbeat = RunService.Heartbeat:Connect(function()
        if antiDamageEnabled and LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if humanoid.Health < humanoid.MaxHealth then humanoid.Health = humanoid.MaxHealth end
                if humanoid.Health <= 0 then humanoid.Health = humanoid.MaxHealth end
            end
        end
    end)
    
    antiDamageThread = task.spawn(function()
        while antiDamageEnabled do
            task.wait(0.001)
            pcall(function()
                if LocalPlayer.Character then
                    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health < humanoid.MaxHealth then humanoid.Health = humanoid.MaxHealth end
                end
            end)
        end
    end)
    
    local function onHealthChanged()
        if antiDamageEnabled and LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.HealthChanged:Connect(function(newHealth)
                    if antiDamageEnabled and newHealth < humanoid.MaxHealth then humanoid.Health = humanoid.MaxHealth end
                end)
            end
        end
    end
    
    if LocalPlayer.Character then onHealthChanged() end
    LocalPlayer.CharacterAdded:Connect(function() task.wait(0.5); if antiDamageEnabled then onHealthChanged() end end)
end

-- ================== FUNGSI INFINITY JUMP ==================
local function onJumpRequest()
    if infinityJumpEnabled then
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end
UserInputService.JumpRequest:Connect(onJumpRequest)

-- ================== FUNGSI PLAYER COUNTER ==================
local function createPlayerCounter()
    if enemyCountText then
        pcall(function() enemyCountText:Remove() end)
        enemyCountText = nil
    end
    
    enemyCountText = Drawing.new("Text")
    enemyCountText.Size = 24
    enemyCountText.Color = themeColor
    enemyCountText.Center = true
    enemyCountText.Outline = true
    enemyCountText.OutlineColor = Color3.fromRGB(0, 0, 0)
    enemyCountText.Position = Vector2.new(Camera.ViewportSize.X / 2, 50)
    enemyCountText.Visible = false
    enemyCountText.Text = "👥 ENEMIES: 0"
end

local function updatePlayerCounter()
    if not playerCounterEnabled or not enemyCountText then return end
    
    local count = 0
    for player, esp in pairs(ESPTable) do
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and player ~= LocalPlayer then
            local hrp = char.HumanoidRootPart
            local pos, visible = Camera:WorldToViewportPoint(hrp.Position)
            if visible then
                count = count + 1
            end
        end
    end
    
    enemyCountText.Text = "👥 ENEMIES: " .. count
    enemyCountText.Color = themeColor
    enemyCountText.Visible = playerCounterEnabled
    enemyCountText.Position = Vector2.new(Camera.ViewportSize.X / 2, 50)
end

-- ================== FUNGSI ESP ==================
local function createESP(player)
    if player == LocalPlayer then return end
    
    local box = Drawing.new("Square")
    box.Thickness = 2.5
    box.Color = boxColor
    box.Filled = false
    box.Visible = false
    
    local name = Drawing.new("Text")
    name.Size = 16
    name.Color = Color3.fromRGB(255, 255, 255)
    name.Center = true
    name.Outline = true
    name.OutlineColor = Color3.fromRGB(0, 0, 0)
    name.Visible = false
    
    local dist = Drawing.new("Text")
    dist.Size = 13
    dist.Color = Color3.fromRGB(200, 200, 200)
    dist.Center = true
    dist.Outline = true
    dist.OutlineColor = Color3.fromRGB(0, 0, 0)
    dist.Visible = false
    
    local line = Drawing.new("Line")
    line.Thickness = 2.5
    line.Color = themeColor
    line.Visible = false
    
    local healthBg = Drawing.new("Square")
    healthBg.Thickness = 1
    healthBg.Color = Color3.fromRGB(30, 30, 30)
    healthBg.Filled = true
    healthBg.Visible = false
    
    local healthFg = Drawing.new("Square")
    healthFg.Thickness = 0
    healthFg.Color = Color3.fromRGB(0, 255, 0)
    healthFg.Filled = true
    healthFg.Visible = false
    
    ESPTable[player] = {box, name, dist, line, healthBg, healthFg}
end

local function createSkeleton(player)
    if player == LocalPlayer then return end
    local lines = {}
    local connections = {
        {"Head", "UpperTorso"}, {"Head", "Torso"},
        {"UpperTorso", "LowerTorso"}, {"Torso", "HumanoidRootPart"},
        {"UpperTorso", "LeftUpperArm"}, {"Torso", "Left Arm"}, 
        {"LeftUpperArm", "LeftLowerArm"}, {"Left Arm", "LeftLowerArm"},
        {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"Torso", "Right Arm"},
        {"RightUpperArm", "RightLowerArm"}, {"Right Arm", "RightLowerArm"},
        {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"}, {"HumanoidRootPart", "Left Leg"},
        {"LeftUpperLeg", "LeftLowerLeg"}, {"Left Leg", "LeftLowerLeg"},
        {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"}, {"HumanoidRootPart", "Right Leg"},
        {"RightUpperLeg", "RightLowerLeg"}, {"Right Leg", "RightLowerLeg"},
        {"RightLowerLeg", "RightFoot"}
    }
    for i = 1, #connections do
        local line = Drawing.new("Line")
        line.Thickness = 3
        line.Color = skeletonColor
        line.Visible = false
        table.insert(lines, {line, connections[i][1], connections[i][2]})
    end
    SkeletonESP[player] = lines
end

local function updateSkeleton(player, lines)
    local char = player.Character
    if not char then
        for _, lineData in pairs(lines) do lineData[1].Visible = false end
        return
    end
    for _, lineData in pairs(lines) do
        local line, part1Name, part2Name = unpack(lineData)
        
        local function findPart(partName)
            if partName == "UpperTorso" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") end
            if partName == "LowerTorso" then return char:FindFirstChild("LowerTorso") or char:FindFirstChild("HumanoidRootPart") end
            if partName == "LeftUpperArm" then return char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm") end
            if partName == "RightUpperArm" then return char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm") end
            if partName == "LeftUpperLeg" then return char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg") end
            if partName == "RightUpperLeg" then return char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg") end
            if partName == "LeftLowerArm" then return char:FindFirstChild("LeftLowerArm") or char:FindFirstChild("Left Arm") end
            if partName == "RightLowerArm" then return char:FindFirstChild("RightLowerArm") or char:FindFirstChild("Right Arm") end
            if partName == "LeftLowerLeg" then return char:FindFirstChild("LeftLowerLeg") or char:FindFirstChild("Left Leg") end
            if partName == "RightLowerLeg" then return char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Leg") end
            if partName == "LeftHand" then return char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm") end
            if partName == "RightHand" then return char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm") end
            if partName == "LeftFoot" then return char:FindFirstChild("LeftFoot") or char:FindFirstChild("Left Leg") end
            if partName == "RightFoot" then return char:FindFirstChild("RightFoot") or char:FindFirstChild("Right Leg") end
            return char:FindFirstChild(partName)
        end
        
        local part1 = findPart(part1Name)
        local part2 = findPart(part2Name)
        
        if part1 and part2 then
            local pos1, vis1 = Camera:WorldToViewportPoint(part1.Position)
            local pos2, vis2 = Camera:WorldToViewportPoint(part2.Position)
            if vis1 and vis2 then
                line.From = Vector2.new(pos1.X, pos1.Y)
                line.To = Vector2.new(pos2.X, pos2.Y)
                line.Visible = skeletonEnabled
                line.Color = skeletonColor
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    end
end

-- ================== RENDER STEP ESP ==================
RunService.RenderStepped:Connect(function()
    local myChar = LocalPlayer.Character
    local myPos = myChar and myChar:FindFirstChild("HumanoidRootPart") and myChar.HumanoidRootPart.Position
    
    for player, esp in pairs(ESPTable) do
        local box, name, distText, line, healthBg, healthFg = unpack(esp)
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") then
            local hrp = char.HumanoidRootPart
            local head = char.Head
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local pos, visible = Camera:WorldToViewportPoint(hrp.Position)
            local distance = myPos and (myPos - hrp.Position).Magnitude or math.huge
            local withinRange = distance <= MAX_ESP_DISTANCE
            
            if visible and withinRange then
                local top = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local bottom = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                local height = math.abs(top.Y - bottom.Y)
                local width = height / 2
                
                if espEnabled then
                    box.Size = Vector2.new(width, height)
                    box.Position = Vector2.new(pos.X - width/2, top.Y)
                    box.Visible = true
                    box.Color = boxColor
                    
                    name.Position = Vector2.new(pos.X, top.Y - 18)
                    name.Text = player.Name
                    name.Visible = true
                    distText.Text = math.floor(distance) .. "m"
                    distText.Position = Vector2.new(pos.X, bottom.Y + 5)
                    distText.Visible = true
                else
                    box.Visible = false
                    name.Visible = false
                    distText.Visible = false
                end
                
                if healthEnabled and humanoid then
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    local barWidth = width * 0.8
                    local barHeight = 4
                    local barX = pos.X - barWidth / 2
                    local barY = top.Y - 22
                    healthBg.Size = Vector2.new(barWidth, barHeight)
                    healthBg.Position = Vector2.new(barX, barY)
                    healthBg.Visible = true
                    healthFg.Size = Vector2.new(barWidth * healthPercent, barHeight)
                    healthFg.Position = Vector2.new(barX, barY)
                    healthFg.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                    healthFg.Visible = true
                else
                    healthBg.Visible = false
                    healthFg.Visible = false
                end
            else
                box.Visible = false
                name.Visible = false
                distText.Visible = false
                healthBg.Visible = false
                healthFg.Visible = false
            end
            
            if lineEnabled then
                line.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
                line.To = Vector2.new(pos.X, pos.Y)
                line.Visible = visible
                line.Color = themeColor
            else
                line.Visible = false
            end
        end
    end
    
    if skeletonEnabled then
        for player, lines in pairs(SkeletonESP) do
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") and myPos then
                local hrp = char.HumanoidRootPart
                local distance = (myPos - hrp.Position).Magnitude
                if distance <= MAX_ESP_DISTANCE then
                    updateSkeleton(player, lines)
                else
                    for _, lineData in pairs(lines) do lineData[1].Visible = false end
                end
            else
                for _, lineData in pairs(lines) do lineData[1].Visible = false end
            end
        end
    else
        for _, lines in pairs(SkeletonESP) do
            for _, lineData in pairs(lines) do lineData[1].Visible = false end
        end
    end
    
    if playerCounterEnabled then
        updatePlayerCounter()
    elseif enemyCountText then
        enemyCountText.Visible = false
    end
end)

for _, p in pairs(Players:GetPlayers()) do
    createESP(p)
    createSkeleton(p)
end

Players.PlayerAdded:Connect(function(p)
    createESP(p)
    createSkeleton(p)
end)

Players.PlayerRemoving:Connect(function(player)
    if ESPTable[player] then
        for _, drawing in pairs(ESPTable[player]) do
            pcall(function() if drawing and drawing.Remove then drawing:Remove() end end)
        end
        ESPTable[player] = nil
    end
    if SkeletonESP[player] then
        for _, lineData in pairs(SkeletonESP[player]) do
            pcall(function() if lineData[1] and lineData[1].Remove then lineData[1]:Remove() end end)
        end
        SkeletonESP[player] = nil
    end
end)

task.spawn(function()
    while task.wait(30) do
        pcall(function()
            for player, drawings in pairs(ESPTable) do
                if not player or not player.Parent then
                    for _, drawing in pairs(drawings) do
                        if drawing and drawing.Remove then drawing:Remove() end
                    end
                    ESPTable[player] = nil
                end
            end
            for player, lines in pairs(SkeletonESP) do
                if not player or not player.Parent then
                    for _, lineData in pairs(lines) do
                        if lineData[1] and lineData[1].Remove then lineData[1]:Remove() end
                    end
                    SkeletonESP[player] = nil
                end
            end
        end)
    end
end)

-- ================== FUNGSI UTAMA (MENU) ==================
local function loadMainScript()
    KeyGui:Destroy()
    
    print("✅ DRIP CLIENT - Memuat semua fitur...")
    
    createPlayerCounter()
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Parent = game.CoreGui
    ScreenGui.Name = "DripClient"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 100
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = ScreenGui
    mainFrame.Size = UDim2.new(0, 400, 0, 550)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -275)
    mainFrame.BackgroundColor3 = darkPurple
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.Parent = mainFrame
    mainCorner.CornerRadius = UDim.new(0, 24)
    
    local glowBg = Instance.new("ImageLabel")
    glowBg.Parent = mainFrame
    glowBg.Size = UDim2.new(1.1, 0, 1.1, 0)
    glowBg.Position = UDim2.new(-0.05, 0, -0.05, 0)
    glowBg.BackgroundTransparency = 1
    glowBg.Image = "rbxassetid://6014261993"
    glowBg.ImageColor3 = themeColor
    glowBg.ImageTransparency = 0.7
    glowBg.ScaleType = Enum.ScaleType.Slice
    glowBg.SliceCenter = Rect.new(10, 10, 118, 118)
    glowBg.ZIndex = 0
    
    local premiumBorder = Instance.new("Frame")
    premiumBorder.Parent = mainFrame
    premiumBorder.Size = UDim2.new(1, 0, 1, 0)
    premiumBorder.BackgroundTransparency = 1
    premiumBorder.BorderSizePixel = 3
    premiumBorder.BorderColor3 = themeColor
    local borderCorner = Instance.new("UICorner")
    borderCorner.Parent = premiumBorder
    borderCorner.CornerRadius = UDim.new(0, 24)
    
    local header = Instance.new("Frame")
    header.Parent = mainFrame
    header.Size = UDim2.new(1, 0, 0, 70)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = themeColor
    header.BackgroundTransparency = 0.15
    header.BorderSizePixel = 0
    local headerCorner = Instance.new("UICorner")
    headerCorner.Parent = header
    headerCorner.CornerRadius = UDim.new(0, 24)
    local headerGradient = Instance.new("UIGradient")
    headerGradient.Parent = header
    headerGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, themeColor),
        ColorSequenceKeypoint.new(1, darkPurple)
    })
    headerGradient.Rotation = 90
    
    local title = Instance.new("TextLabel")
    title.Parent = header
    title.Size = UDim2.new(1, 0, 0.6, 0)
    title.Position = UDim2.new(0, 0, 0, 15)
    title.BackgroundTransparency = 1
    title.Text = "DRIP CLIENT"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 26
    title.TextXAlignment = Enum.TextXAlignment.Center
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Parent = header
    subtitle.Size = UDim2.new(1, 0, 0.3, 0)
    subtitle.Position = UDim2.new(0, 0, 0, 48)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Drip VIP"
    subtitle.TextColor3 = boxColor
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 11
    subtitle.TextXAlignment = Enum.TextXAlignment.Center
    
    local tabBar = Instance.new("Frame")
    tabBar.Parent = mainFrame
    tabBar.Size = UDim2.new(0.95, 0, 0, 42)
    tabBar.Position = UDim2.new(0.025, 0, 0.13, 0)
    tabBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    tabBar.BackgroundTransparency = 0.3
    tabBar.BorderSizePixel = 0
    local tabBarCorner = Instance.new("UICorner")
    tabBarCorner.Parent = tabBar
    tabBarCorner.CornerRadius = UDim.new(0, 10)
    
    local tabs = {}
    local contents = {}
    
    local function createTab(name, icon, idx)
        local btn = Instance.new("TextButton")
        btn.Parent = tabBar
        btn.Size = UDim2.new(0.2, -2, 1, -6)
        btn.Position = UDim2.new((idx-1)*0.2, 5, 0, 3)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        btn.BackgroundTransparency = 0.5
        btn.Text = icon .. " " .. name
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        local btnCorner = Instance.new("UICorner")
        btnCorner.Parent = btn
        btnCorner.CornerRadius = UDim.new(0, 8)
        
        local content = Instance.new("ScrollingFrame")
        content.Parent = mainFrame
        content.Size = UDim2.new(0.94, 0, 1, -0.28)
        content.Position = UDim2.new(0.03, 0, 0.2, 0)
        content.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        content.BackgroundTransparency = 0.4
        content.BorderSizePixel = 0
        content.ScrollBarThickness = 8
        content.ScrollBarImageColor3 = themeColor
        content.CanvasSize = UDim2.new(0, 0, 0, 0)
        content.Visible = false
        content.AutomaticCanvasSize = Enum.AutomaticSize.Y
        content.ScrollingDirection = Enum.ScrollingDirection.Y
        content.ElasticBehavior = Enum.ElasticBehavior.Never
        content.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
        local contentCorner = Instance.new("UICorner")
        contentCorner.Parent = content
        contentCorner.CornerRadius = UDim.new(0, 12)
        local layout = Instance.new("UIListLayout")
        layout.Parent = content
        layout.Padding = UDim.new(0, 10)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        table.insert(tabs, btn)
        table.insert(contents, content)
        
        btn.MouseButton1Click:Connect(function()
            for i, b in ipairs(tabs) do
                b.TextColor3 = Color3.fromRGB(200, 200, 200)
                b.BackgroundTransparency = 0.5
                contents[i].Visible = false
            end
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.BackgroundTransparency = 0.2
            content.Visible = true
            task.wait(0.05)
            local height = 0
            for _, child in pairs(content:GetChildren()) do
                if child:IsA("Frame") then
                    height = height + child.Size.Y.Offset + 10
                end
            end
            content.CanvasSize = UDim2.new(0, 0, 0, height + 40)
        end)
        
        return content
    end
    
    local tabMain = createTab("MAIN", "▸", 1)
    local tabESP = createTab("ESP", "▸", 2)
    local tabUtility = createTab("UTILITY", "▸", 3)
    local tabColor = createTab("COLOR", "▸", 4)
    local tabInfo = createTab("INFORMASI", "▸", 5)
    
    local function createButton(parent, text, callback)
        local frame = Instance.new("Frame")
        frame.Parent = parent
        frame.Size = UDim2.new(0.95, 0, 0, 44)
        frame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        frame.BackgroundTransparency = 0.2
        frame.BorderSizePixel = 0
        local corner = Instance.new("UICorner")
        corner.Parent = frame
        corner.CornerRadius = UDim.new(0, 10)
        local btn = Instance.new("TextButton")
        btn.Parent = frame
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.MouseButton1Click:Connect(callback)
        return frame
    end
    
    local function createToggle(parent, text, default, callback)
        local frame = Instance.new("Frame")
        frame.Parent = parent
        frame.Size = UDim2.new(0.95, 0, 0, 44)
        frame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        frame.BackgroundTransparency = 0.2
        frame.BorderSizePixel = 0
        local corner = Instance.new("UICorner")
        corner.Parent = frame
        corner.CornerRadius = UDim.new(0, 10)
        local label = Instance.new("TextLabel")
        label.Parent = frame
        label.Size = UDim2.new(0.65, 0, 1, 0)
        label.Position = UDim2.new(0.05, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        local switch = Instance.new("Frame")
        switch.Parent = frame
        switch.Size = UDim2.new(0, 48, 0, 24)
        switch.Position = UDim2.new(0.82, 0, 0.5, -12)
        switch.BackgroundColor3 = default and themeColor or Color3.fromRGB(80, 80, 90)
        switch.BorderSizePixel = 0
        local switchCorner = Instance.new("UICorner")
        switchCorner.Parent = switch
        switchCorner.CornerRadius = UDim.new(0, 12)
        local circle = Instance.new("Frame")
        circle.Parent = switch
        circle.Size = UDim2.new(0, 20, 0, 20)
        circle.Position = default and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0.05, 0, 0.5, -10)
        circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        circle.BorderSizePixel = 0
        local circleCorner = Instance.new("UICorner")
        circleCorner.Parent = circle
        circleCorner.CornerRadius = UDim.new(1, 0)
        local state = default
        local click = Instance.new("TextButton")
        click.Parent = frame
        click.Size = UDim2.new(1, 0, 1, 0)
        click.BackgroundTransparency = 1
        click.Text = ""
        click.MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(switch, TweenInfo.new(0.2), {BackgroundColor3 = state and themeColor or Color3.fromRGB(80, 80, 90)}):Play()
            TweenService:Create(circle, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0.05, 0, 0.5, -10)}):Play()
            callback(state)
        end)
        return frame
    end
    
    local function createTextBox(parent, placeholder, callback)
        local frame = Instance.new("Frame")
        frame.Parent = parent
        frame.Size = UDim2.new(0.95, 0, 0, 44)
        frame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        frame.BackgroundTransparency = 0.2
        frame.BorderSizePixel = 0
        local corner = Instance.new("UICorner")
        corner.Parent = frame
        corner.CornerRadius = UDim.new(0, 10)
        local textBox = Instance.new("TextBox")
        textBox.Parent = frame
        textBox.Size = UDim2.new(1, -10, 1, -10)
        textBox.Position = UDim2.new(0, 5, 0, 5)
        textBox.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        textBox.PlaceholderText = placeholder
        textBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
        textBox.Font = Enum.Font.Gotham
        textBox.TextSize = 14
        textBox.ClearTextOnFocus = false
        local boxCorner = Instance.new("UICorner")
        boxCorner.Parent = textBox
        boxCorner.CornerRadius = UDim.new(0, 8)
        textBox.FocusLost:Connect(function(enterPressed)
            if enterPressed and textBox.Text ~= "" then
                callback(textBox.Text)
                textBox.Text = ""
            end
        end)
        return frame
    end
    
    -- ===== TAB MAIN =====
    createToggle(tabMain, "Fly", false, function(s)
        if s then 
            flyEnabled = true
            startFlyMode()
        else 
            flyEnabled = false
            stopFlyMode()
        end
    end)
    
    createToggle(tabMain, "Speed Boost", false, function(s)
        speedEnabled = s
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = s and fastSpeed or normalSpeed end
        LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.5)
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and speedEnabled then hum.WalkSpeed = fastSpeed end
        end)
    end)
    
    createToggle(tabMain, "NoClip", false, function(s)
        noclipEnabled = s
        if s then 
            startNoclip() 
        else 
            stopNoclip() 
        end
    end)
    
    createToggle(tabMain, "Infinity Jump", false, function(s)
        infinityJumpEnabled = s
    end)
    
    createToggle(tabMain, "Crosshair", false, function(s)
        crosshairEnabled = s
        if s then
            createCrosshair()
        else
            removeCrosshair()
        end
    end)
    
    -- ===== TAB ESP =====
    createToggle(tabESP, "ESP Box", false, function(s) espEnabled = s end)
    createToggle(tabESP, "ESP Line", false, function(s) lineEnabled = s end)
    createToggle(tabESP, "Health Bar", false, function(s) healthEnabled = s end)
    createToggle(tabESP, "ESP Skeleton", false, function(s) skeletonEnabled = s end)
    createToggle(tabESP, "Player Counter", false, function(s) 
        playerCounterEnabled = s
        if s then
            createPlayerCounter()
            updatePlayerCounter()
        elseif enemyCountText then
            enemyCountText.Visible = false
        end
    end)
    
    -- ===== TAB UTILITY =====
    createToggle(tabUtility, "God Mode", false, function(s)
        antiDamageEnabled = s
        if s then
            setupAntiDamage()
        else
            if antiDamageHeartbeat then antiDamageHeartbeat:Disconnect() end
            if antiDamageConnection then antiDamageConnection:Disconnect() end
            antiDamageThread = nil
        end
    end)
    
    createToggle(tabUtility, "Spin Muter", false, function(s)
        toggleSpin(s)
    end)
    
    createButton(tabUtility, "Ganti Arah Spin", function()
        toggleSpinDirection()
    end)
    
    createToggle(tabUtility, "Invisible Mode", false, function(s)
        toggleInvisible(s)
    end)
    
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        updateInvisibleData()
        if invisibleEnabled then toggleInvisible(true) end
        if noclipEnabled then startNoclip() end
        if flyEnabled then 
            task.wait(0.5)
            startFlyMode()
        end
    end)
    
    -- ===== TAB COLOR =====
    local function changeTheme(newColor)
        themeColor = newColor
        premiumBorder.BorderColor3 = themeColor
        for _, content in pairs(contents) do
            content.ScrollBarImageColor3 = themeColor
        end
        for player, esp in pairs(ESPTable) do
            if esp and esp[4] then esp[4].Color = themeColor end
        end
        if enemyCountText then
            enemyCountText.Color = themeColor
        end
    end
    
    createButton(tabColor, "Ungu (Default)", function()
        changeTheme(Color3.fromRGB(156, 39, 176))
    end)
    createButton(tabColor, "Chan", function()
        changeTheme(Color3.fromRGB(0, 255, 255))
    end)
    createButton(tabColor, "Merah", function()
        changeTheme(Color3.fromRGB(255, 0, 0))
    end)
    createButton(tabColor, "Hijau", function()
        changeTheme(Color3.fromRGB(0, 255, 0))
    end)
    createButton(tabColor, "Biru", function()
        changeTheme(Color3.fromRGB(0, 0, 255))
    end)
    createButton(tabColor, "Kuning", function()
        changeTheme(Color3.fromRGB(255, 255, 0))
    end)
    createButton(tabColor, "Orange", function()
        changeTheme(Color3.fromRGB(255, 165, 0))
    end)
    createButton(tabColor, "Pink", function()
        changeTheme(Color3.fromRGB(255, 105, 180))
    end)
    
    -- ===== TAB INFORMASI =====
    local infoFrame = Instance.new("Frame")
    infoFrame.Parent = tabInfo
    infoFrame.Size = UDim2.new(0.95, 0, 0, 180)
    infoFrame.Position = UDim2.new(0.025, 0, 0, 10)
    infoFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    infoFrame.BackgroundTransparency = 0.3
    infoFrame.BorderSizePixel = 0
    local infoCorner = Instance.new("UICorner")
    infoCorner.Parent = infoFrame
    infoCorner.CornerRadius = UDim.new(0, 12)
    
    local infoTitle = Instance.new("TextLabel")
    infoTitle.Parent = infoFrame
    infoTitle.Size = UDim2.new(1, 0, 0, 35)
    infoTitle.Position = UDim2.new(0, 0, 0, 10)
    infoTitle.BackgroundTransparency = 1
    infoTitle.Text = "INFORMASI SCRIPT"
    infoTitle.TextColor3 = themeColor
    infoTitle.Font = Enum.Font.GothamBlack
    infoTitle.TextSize = 20
    
    local infoText = Instance.new("TextLabel")
    infoText.Parent = infoFrame
    infoText.Size = UDim2.new(0.95, 0, 0, 120)
    infoText.Position = UDim2.new(0.025, 0, 0, 50)
    infoText.BackgroundTransparency = 1
    infoText.Text = "DRIP CLIENT HP EDITION\n\nVERSI 7.5\n\nDEVELOPER: Putzzdev\n\nKONTAK: 088976255131"
    infoText.TextColor3 = Color3.fromRGB(255, 255, 255)
    infoText.Font = Enum.Font.Gotham
    infoText.TextSize = 14
    infoText.TextWrapped = true
    infoText.TextXAlignment = Enum.TextXAlignment.Center
    
    task.wait(0.1)
    for _, content in pairs(contents) do
        local height = 0
        for _, child in pairs(content:GetChildren()) do
            if child:IsA("Frame") then
                height = height + child.Size.Y.Offset + 10
            end
        end
        content.CanvasSize = UDim2.new(0, 0, 0, height + 40)
    end
    
    tabs[1].TextColor3 = Color3.fromRGB(255, 255, 255)
    tabs[1].BackgroundTransparency = 0.2
    contents[1].Visible = true
    
    local openBtn = Instance.new("TextButton")
    openBtn.Parent = ScreenGui
    openBtn.Size = UDim2.new(0, 120, 0, 45)
    openBtn.Position = UDim2.new(0, 15, 0.5, -22.5)
    openBtn.BackgroundColor3 = themeColor
    openBtn.BackgroundTransparency = 0.2
    openBtn.Text = "DRIP CLIENT"
    openBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    openBtn.Font = Enum.Font.GothamBlack
    openBtn.TextSize = 13
    openBtn.ZIndex = 10
    openBtn.Active = true
    openBtn.Draggable = true
    
    local openBtnCorner = Instance.new("UICorner")
    openBtnCorner.Parent = openBtn
    openBtnCorner.CornerRadius = UDim.new(0, 14)
    local openBtnStroke = Instance.new("UIStroke")
    openBtnStroke.Parent = openBtn
    openBtnStroke.Color = Color3.fromRGB(255, 255, 255)
    openBtnStroke.Thickness = 1.5
    
    local menuOpen = true
    openBtn.MouseButton1Click:Connect(function()
        menuOpen = not menuOpen
        if menuOpen then
            mainFrame.Visible = true
            TweenService:Create(mainFrame, TweenInfo.new(0.25), {
                Position = UDim2.new(0.5, -200, 0.5, -275)
            }):Play()
        else
            TweenService:Create(mainFrame, TweenInfo.new(0.25), {
                Position = UDim2.new(0.5, -200, 1, 0)
            }):Play()
            task.wait(0.25)
            mainFrame.Visible = false
        end
    end)
    
    openBtn.MouseEnter:Connect(function()
        TweenService:Create(openBtn, TweenInfo.new(0.2), {Size = UDim2.new(0, 130, 0, 48)}):Play()
        openBtn.BackgroundTransparency = 0
    end)
    openBtn.MouseLeave:Connect(function()
        TweenService:Create(openBtn, TweenInfo.new(0.2), {Size = UDim2.new(0, 120, 0, 45)}):Play()
        openBtn.BackgroundTransparency = 0.2
    end)
    
    print("✅ DRIP CLIENT V7.5 - MENU BERHASIL DIMUAT!")
end

-- ================== EVENT VERIFY BUTTON ==================
VerifyBtn.MouseButton1Click:Connect(function()
    local inputKey = KeyTextBox.Text:gsub("%s+", "")
    if inputKey == "" then
        StatusLabel.Text = "Masukkan Key Anda!"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        StatusIcon.Text = "❌"
        return
    end
    
    showLoading(true)
    StatusLabel.Text = "Memverifikasi Key..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    StatusIcon.Text = "⏳"
    
    local isValid, message = checkKeyExpiry(inputKey)
    
    showLoading(false)
    
    if isValid then
        StatusLabel.Text = message
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        StatusIcon.Text = "✅"
        
        task.wait(1)
        StatusLabel.Text = "Loading (3)..."
        task.wait(1)
        StatusLabel.Text = "Loading (2)..."
        task.wait(1)
        StatusLabel.Text = "Loading (1)..."
        task.wait(1)
        
        pcall(loadMainScript)
        
    else
        StatusLabel.Text = message
        StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        StatusIcon.Text = "❌"
        showNotification("GAGAL", message, 2, Color3.fromRGB(150, 0, 0))
    end
end)

KeyTextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        VerifyBtn.MouseButton1Click:Fire()
    end
end)

print("DRIP CLIENT V7.5")