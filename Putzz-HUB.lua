-- ================== DRIP CLIENT - MAINTENANCE MODE (RAYFIELD UI) ==================
-- Script ini muncul saat developer sedang mengupdate script.
-- Timer 5 jam tersimpan secara lokal (tidak reset walau keluar game)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- ================== LOAD RAYFIELD ==================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

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

-- Fungsi format waktu
local function formatTime(seconds)
    if seconds <= 0 then return "00:00:00" end
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

-- Fungsi get status text
local function getStatusText()
    if remainingSeconds <= 0 then
        return "✅ UPDATE SELESAI! Silakan execute ulang"
    end
    return "⏳ Perkiraan selesai: " .. formatTime(remainingSeconds)
end

-- ================== BUAT WINDOW RAYFIELD ==================
local Window = Rayfield:CreateWindow({
    Name = "DRIP CLIENT - MAINTENANCE",
    LoadingTitle = "DRIP CLIENT",
    LoadingSubtitle = "Sedang dalam pemeliharaan...",
    Theme = "Amethyst",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,
    ConfigurationSaving = {
        Enabled = false,
    },
})

-- ================== TAB INFORMASI ==================
local TabInfo = Window:CreateTab("Informasi", "info")

-- Section Status
TabInfo:CreateSection("Status Maintenance")

-- Label status utama
local statusLabel = TabInfo:CreateLabel("🔧 DRIP CLIENT - SEDANG DIUPDATE")
-- Label timer (akan diupdate setiap detik)
timerLabel = TabInfo:CreateLabel("⏳ Perkiraan selesai: " .. formatTime(remainingSeconds))

-- Update timer setiap detik
task.spawn(function()
    while timerRunning and remainingSeconds > 0 do
        task.wait(1)
        remainingSeconds = remainingSeconds - 1
        saveRemainingTime(remainingSeconds)
        
        if remainingSeconds <= 0 then
            timerRunning = false
            pcall(function() 
                if timerLabel and timerLabel.Set then
                    timerLabel:Set("✅ UPDATE SELESAI! Silakan execute ulang")
                end
            end)
        else
            pcall(function()
                if timerLabel and timerLabel.Set then
                    timerLabel:Set("⏳ Perkiraan selesai: " .. formatTime(remainingSeconds))
                end
            end)
        end
    end
end)

TabInfo:CreateDivider()

-- ================== PESAN DARI DEVELOPER ==================
TabInfo:CreateSection("Pesan Developer")

local messageText = [[
Mohon maaf atas ketidaknyamanannya.

Saat ini developer sedang melakukan proses update pada script / fix error yang ada dan akan menambah fitur terbaru.

Script akan kembali aktif setelah proses update selesai.

Terima kasih atas pengertian dan dukungannya.
]]

TabInfo:CreateParagraph(messageText)

TabInfo:CreateDivider()

-- ================== KONTAK DEVELOPER ==================
TabInfo:CreateSection("Kontak Developer")

TabInfo:CreateLabel("📢 Pantau channel WhatsApp / Telegram untuk info update terbaru.")
TabInfo:CreateLabel("")
TabInfo:CreateLabel("💬 KONTAK DEVELOPER:")
TabInfo:CreateLabel("   WhatsApp: 088976255131")
TabInfo:CreateLabel("   TikTok: @putzz_mvpp")

TabInfo:CreateDivider()

-- ================== TOMBOL SALIN KONTAK ==================
TabInfo:CreateButton({
    Name = "📋 Salin Nomor WhatsApp",
    Callback = function()
        if setclipboard then
            setclipboard("088976255131")
            Rayfield:Notify({
                Title = "Berhasil!",
                Content = "Nomor WhatsApp berhasil disalin!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Info",
                Content = "088976255131",
                Duration = 5,
                Image = 4483362458
            })
        end
    end,
})

TabInfo:CreateButton({
    Name = "📋 Salin Username TikTok",
    Callback = function()
        if setclipboard then
            setclipboard("@putzz_mvpp")
            Rayfield:Notify({
                Title = "Berhasil!",
                Content = "Username TikTok berhasil disalin!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Info",
                Content = "@putzz_mvpp",
                Duration = 5,
                Image = 4483362458
            })
        end
    end,
})

-- ================== TAB STATISTIK ==================
local TabStats = Window:CreateTab("Statistik", "bar-chart")

TabStats:CreateSection("Informasi Timer")

-- Label info timer
TabStats:CreateLabel("⏱️ Timer Maintenance")
local timerInfoLabel = TabStats:CreateLabel("Sisa waktu: " .. formatTime(remainingSeconds))

-- Update timer info
task.spawn(function()
    while true do
        task.wait(1)
        if remainingSeconds > 0 then
            pcall(function()
                if timerInfoLabel and timerInfoLabel.Set then
                    timerInfoLabel:Set("Sisa waktu: " .. formatTime(remainingSeconds))
                end
            end)
        else
            pcall(function()
                if timerInfoLabel and timerInfoLabel.Set then
                    timerInfoLabel:Set("✅ Update selesai!")
                end
            end)
            break
        end
    end
end)

TabStats:CreateDivider()

TabStats:CreateSection("Informasi Sistem")

-- Executor info
local function detectExecutor()
    local executorName = "Unknown"
    local executors = {
        {name = "Delta", check = function() return syn and syn.request and syn.crypt end},
        {name = "Arceus X", check = function() return game:GetService("CoreGui"):FindFirstChild("Arceus X V2") or (identifyexecutor and identifyexecutor() == "Arceus X") end},
        {name = "CodeX", check = function() return CodeX and CodeX.Execute end},
        {name = "Hydrogen", check = function() return isfile and readfile and writefile and (not syn) end},
        {name = "Fluxus", check = function() return fluxus and fluxus.ismobile end},
        {name = "Krnl", check = function() return krnl and krnl.loadlibrary end},
        {name = "ScriptWare", check = function() return scriptware and scriptware.loader end},
        {name = "Synapse X", check = function() return syn and syn.crypt and syn.request end},
        {name = "Evon", check = function() return evon and evon.execute end},
        {name = "Vega X", check = function() return game:GetService("CoreGui"):FindFirstChild("Vega Hub") end},
    }
    for _, exec in ipairs(executors) do
        local success, result = pcall(exec.check)
        if success and result then executorName = exec.name break end
    end
    local success, idName = pcall(function() if identifyexecutor then return identifyexecutor() end return nil end)
    if success and idName and idName ~= "" then executorName = idName end
    return executorName
end

TabStats:CreateLabel("Executor: " .. detectExecutor())
TabStats:CreateLabel("Game: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Unknown")
TabStats:CreateLabel("Player: " .. LocalPlayer.Name)

-- ================== TAB UPDATE LOG ==================
local TabUpdate = Window:CreateTab("Update Log", "clipboard")

TabUpdate:CreateSection("Changelog")

local changelog = [[
📋 DAFTAR PERUBAHAN (UPDATE v8.3):

✅ FIX:
   - Memperbaiki bug pada sistem key
   - Memperbaiki ESP yang tidak stabil
   - Optimasi performa UI

✨ FITUR BARU:
   - Menambahkan sistem auto-update
   - UI lebih responsif
   - Fitur anti-kick

🔄 DALAM PENGERJAAN:
   - Aim assist
   - Auto farm
   - Custom theme

📅 Tanggal Update: 16 Juni 2026
]]

TabUpdate:CreateParagraph(changelog)

-- ================== TAB SETTINGS ==================
local TabSettings = Window:CreateTab("Settings", "settings")

TabSettings:CreateSection("Pengaturan")

-- Toggle untuk notifikasi
local notifEnabled = true
TabSettings:CreateToggle({
    Name = "Notifikasi",
    CurrentValue = true,
    Flag = "Notifikasi",
    Callback = function(state)
        notifEnabled = state
        Rayfield:Notify({
            Title = "Notifikasi",
            Content = state and "Notifikasi diaktifkan" or "Notifikasi dinonaktifkan",
            Duration = 2,
            Image = 4483362458
        })
    end,
})

TabSettings:CreateDivider()

TabSettings:CreateSection("Informasi File")

-- Tombol reset timer (hanya untuk debugging)
TabSettings:CreateButton({
    Name = "🔄 Reset Timer (Debug)",
    Callback = function()
        if writefile then
            remainingSeconds = TOTAL_DURATION
            timerRunning = true
            saveRemainingTime(TOTAL_DURATION)
            pcall(function()
                if timerLabel and timerLabel.Set then
                    timerLabel:Set("⏳ Perkiraan selesai: " .. formatTime(TOTAL_DURATION))
                end
                if timerInfoLabel and timerInfoLabel.Set then
                    timerInfoLabel:Set("Sisa waktu: " .. formatTime(TOTAL_DURATION))
                end
            end)
            Rayfield:Notify({
                Title = "Timer Reset",
                Content = "Timer telah direset ke 5 jam",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Executor tidak support writefile!",
                Duration = 3,
                Image = 4483362458
            })
        end
    end,
})

TabSettings:CreateButton({
    Name = "ℹ️ Lokasi File Timer",
    Callback = function()
        Rayfield:Notify({
            Title = "Info",
            Content = "File timer tersimpan di: " .. TIMER_FILE,
            Duration = 4,
            Image = 4483362458
        })
    end,
})

-- ================== NOTIFIKASI AWAL ==================
task.wait(0.5)
Rayfield:Notify({
    Title = "🔧 DRIP CLIENT",
    Content = "Maintenance mode aktif. Timer: " .. formatTime(remainingSeconds),
    Duration = 5,
    Image = 4483362458
})

print("DRIP CLIENT - MAINTENANCE MODE ACTIVE (RAYFIELD UI)")
print("Timer 5 jam berjalan. Sisa waktu tersimpan di file:", TIMER_FILE)
print("Sisa waktu:", formatTime(remainingSeconds))