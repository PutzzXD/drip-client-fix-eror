-- ================== DRIP CLIENT - MAINTENANCE MODE (DENGAN TIMER) ==================
-- Script ini muncul saat developer sedang mengupdate script.
-- Tidak ada fitur cheat di dalamnya.
-- Timer 5 jam tersimpan secara lokal (tidak reset walau keluar game)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

local themeColor = Color3.fromRGB(156, 39, 176)
local darkPurple = Color3.fromRGB(18, 14, 24)

-- ================== TIMER 5 JAM (TETAP TERSIMPAN) ==================
local TIMER_FILE = "drip_timer_data.txt"
local TOTAL_DURATION = 5 * 60 * 60 -- 5 jam dalam detik

-- Fungsi baca sisa waktu dari file
local function loadRemainingTime()
    if isfile and isfile(TIMER_FILE) then
        local success, content = pcall(function() return readfile(TIMER_FILE) end)
        if success and content then
            local savedTime = tonumber(content)
            if savedTime and savedTime > 0 then
                return savedTime
            end
        end
    end
    return TOTAL_DURATION
end

-- Fungsi simpan sisa waktu
local function saveRemainingTime(remaining)
    if writefile then
        pcall(function() writefile(TIMER_FILE, tostring(math.floor(remaining))) end)
    end
end

-- Variabel timer
local remainingSeconds = loadRemainingTime()
local timerRunning = (remainingSeconds > 0)
local timerLabel = nil

-- Fungsi update timer
local function updateTimerDisplay()
    if not timerLabel then return end
    
    if remainingSeconds <= 0 then
        timerLabel.Text = "✅ UPDATE SELESAI! Silakan ulangi lalu execute ulang"
        timerLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        return
    end
    
    local hours = math.floor(remainingSeconds / 3600)
    local minutes = math.floor((remainingSeconds % 3600) / 60)
    local seconds = remainingSeconds % 60
    
    timerLabel.Text = string.format("⏳ Perkiraan selesai: %02d Jam %02d Menit %02d Detik", hours, minutes, seconds)
    timerLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
end

-- Loop timer di background
task.spawn(function()
    while timerRunning and remainingSeconds > 0 do
        task.wait(1)
        remainingSeconds = remainingSeconds - 1
        saveRemainingTime(remainingSeconds)
        updateTimerDisplay()
        
        if remainingSeconds <= 0 then
            timerRunning = false
            updateTimerDisplay()
        end
    end
end)

-- ================== MAIN MENU (MAINTENANCE MODE) ==================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DripClient"
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local mainFrame = Instance.new("Frame", ScreenGui)
mainFrame.Size = UDim2.new(0, 390, 0, 450)
mainFrame.Position = UDim2.new(0.5, -195, 0.5, -225)
mainFrame.BackgroundColor3 = darkPurple
mainFrame.Active = true
mainFrame.Draggable = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = themeColor
mainStroke.Thickness = 2

local header = Instance.new("Frame", mainFrame)
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundColor3 = themeColor
header.BackgroundTransparency = 0.3
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)

local logoImage = Instance.new("ImageLabel", header)
logoImage.Size = UDim2.new(0, 32, 0, 32)
logoImage.Position = UDim2.new(0, 15, 0, 14)
logoImage.BackgroundTransparency = 1
logoImage.Image = "rbxassetid://72495850369898"
logoImage.ScaleType = Enum.ScaleType.Fit

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, -60, 0.5, 0)
title.Position = UDim2.new(0, 60, 0, 10)
title.BackgroundTransparency = 1
title.Text = "DRIP CLIENT"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left

local subtitle = Instance.new("TextLabel", header)
subtitle.Size = UDim2.new(1, -60, 0.3, 0)
subtitle.Position = UDim2.new(0, 60, 0, 34)
subtitle.BackgroundTransparency = 1
subtitle.Text = "MAINTENANCE MODE"
subtitle.TextColor3 = Color3.fromRGB(255, 100, 100)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 11
subtitle.TextXAlignment = Enum.TextXAlignment.Left

local tabBar = Instance.new("Frame", mainFrame)
tabBar.Size = UDim2.new(0.94, 0, 0, 35)
tabBar.Position = UDim2.new(0.03, 0, 0, 70)
tabBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 6)

-- Tab Informasi
local tabInfoBtn = Instance.new("TextButton", tabBar)
tabInfoBtn.Size = UDim2.new(1, -4, 1, -6)
tabInfoBtn.Position = UDim2.new(0.02, 0, 0, 3)
tabInfoBtn.BackgroundColor3 = themeColor
tabInfoBtn.BackgroundTransparency = 0.2
tabInfoBtn.Text = "INFORMASI"
tabInfoBtn.TextColor3 = Color3.new(1, 1, 1)
tabInfoBtn.Font = Enum.Font.GothamBold
tabInfoBtn.TextSize = 12
Instance.new("UICorner", tabInfoBtn).CornerRadius = UDim.new(0, 5)

-- Content panel
local contentInfo = Instance.new("ScrollingFrame", mainFrame)
contentInfo.Size = UDim2.new(0.94, 0, 0, 300)
contentInfo.Position = UDim2.new(0.03, 0, 0, 115)
contentInfo.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
contentInfo.BackgroundTransparency = 0.4
contentInfo.BorderSizePixel = 0
contentInfo.ScrollBarThickness = 4
contentInfo.ScrollBarImageColor3 = themeColor
contentInfo.Visible = true
contentInfo.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", contentInfo).CornerRadius = UDim.new(0, 10)

local infoLayout = Instance.new("UIListLayout", contentInfo)
infoLayout.Padding = UDim.new(0, 10)
infoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- ================== BOX PESAN UTAMA (Teks Lo yang Dulu) ==================
local messageBox = Instance.new("Frame", contentInfo)
messageBox.Size = UDim2.new(0.96, 0, 0, 0)
messageBox.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
messageBox.AutomaticSize = Enum.AutomaticSize.Y
Instance.new("UICorner", messageBox).CornerRadius = UDim.new(0, 10)

local messageText = Instance.new("TextLabel", messageBox)
messageText.Size = UDim2.new(1, -20, 0, 0)
messageText.Position = UDim2.new(0, 10, 0, 10)
messageText.BackgroundTransparency = 1
messageText.Text = [[
🔧 DRIP CLIENT - SEDANG DIUPDATE 🔧
NOTIFICATION FROM DEVELOPER

Mohon maaf atas ketidaknyamanannya.

Saat ini developer sedang melakukan proses update pada script / fix error yang ada dan akan menambah fitur terbaru.

Script akan kembali aktif setelah proses update selesai.

Terima kasih atas pengertian dan dukungannya.
]]
messageText.TextColor3 = Color3.fromRGB(200, 210, 240)
messageText.Font = Enum.Font.Gotham
messageText.TextSize = 12
messageText.TextWrapped = true
messageText.TextYAlignment = Enum.TextYAlignment.Top
messageText.TextXAlignment = Enum.TextXAlignment.Left

task.wait(0.1)
messageBox.Size = UDim2.new(0.96, 0, 0, messageText.TextBounds.Y + 20)

-- ================== BOX TIMER (DI BAWAH PESAN) ==================
local timerBox = Instance.new("Frame", contentInfo)
timerBox.Size = UDim2.new(0.96, 0, 0, 50)
timerBox.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Instance.new("UICorner", timerBox).CornerRadius = UDim.new(0, 10)

timerLabel = Instance.new("TextLabel", timerBox)
timerLabel.Size = UDim2.new(1, -20, 1, 0)
timerLabel.Position = UDim2.new(0, 10, 0, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = ""
timerLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextSize = 11
timerLabel.TextWrapped = true
timerLabel.TextYAlignment = Enum.TextYAlignment.Center

-- Update tampilan timer pertama kali
updateTimerDisplay()

-- ================== BOX KONTAK DEVELOPER ==================
local contactBox = Instance.new("Frame", contentInfo)
contactBox.Size = UDim2.new(0.96, 0, 0, 0)
contactBox.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
contactBox.AutomaticSize = Enum.AutomaticSize.Y
Instance.new("UICorner", contactBox).CornerRadius = UDim.new(0, 10)

local contactText = Instance.new("TextLabel", contactBox)
contactText.Size = UDim2.new(1, -20, 0, 0)
contactText.Position = UDim2.new(0, 10, 0, 10)
contactText.BackgroundTransparency = 1
contactText.Text = [[
📢 Pantau channel WhatsApp / Telegram untuk info update terbaru.

💬 KONTAK DEVELOPER:
   WhatsApp: 088976255131
   TikTok: @putzz_mvpp

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️ DRIP CLIENT - MAINTENANCE MODE ⚠️
]]
contactText.TextColor3 = Color3.fromRGB(200, 210, 240)
contactText.Font = Enum.Font.Gotham
contactText.TextSize = 12
contactText.TextWrapped = true
contactText.TextYAlignment = Enum.TextYAlignment.Top
contactText.TextXAlignment = Enum.TextXAlignment.Left

task.wait(0.1)
contactBox.Size = UDim2.new(0.96, 0, 0, contactText.TextBounds.Y + 20)

-- ================== TOMBOL GESER (IMAGE) ==================
local openBtn = Instance.new("ImageButton", ScreenGui)
openBtn.Size = UDim2.new(0, 50, 0, 50)
openBtn.Position = UDim2.new(0, 15, 0.5, -25)
openBtn.BackgroundTransparency = 1
openBtn.Image = "rbxassetid://72495850369898"
openBtn.Active = true
openBtn.Draggable = true
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 10)

local btnStroke = Instance.new("UIStroke", openBtn)
btnStroke.Color = Color3.new(1, 1, 1)
btnStroke.Thickness = 1.2

local menuOpen = true
openBtn.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    if menuOpen then
        mainFrame.Visible = true
        TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Position = UDim2.new(0.5, -195, 0.5, -225)}):Play()
    else
        TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Position = UDim2.new(0.5, -195, 1, 10)}):Play()
        task.wait(0.2)
        mainFrame.Visible = false
    end
end)

print("DRIP CLIENT - MAINTENANCE MODE ACTIVE")
print("Timer 5 jam berjalan. Sisa waktu tersimpan di file:", TIMER_FILE)