-- ================== DRIP CLIENT MAINTENANCE / UPDATE NOTICE ==================
-- Orion Library Version

-- Load Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Orion Library
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

-- ================== REAL-TIME TIMER CALCULATOR ==================
local startTime = os.time()
local targetTime = startTime + 27000 -- 7.5 Jam (27000 detik)
local kickTimeout = 20 -- Waktu tunggu sebelum di-kick otomatis (60 detik)

local function getRemainingTime()
    local currentTime = os.time()
    local timeLeft = targetTime - currentTime
    
    if timeLeft <= 0 then
        return "Selesai (Menunggu Perilisan)"
    end
    
    local hours = math.floor(timeLeft / 3600)
    local minutes = math.floor((timeLeft % 3600) / 60)
    local seconds = timeLeft % 60
    
    return string.format("%02d Jam %02d Menit %02d Detik", hours, minutes, seconds)
end

-- ================== INITIALIZATION ==================
local Window = OrionLib:MakeWindow({
    Name = "Putzzdev - Drip Client 📢",
    HidePremium = true,
    SaveConfig = false,
    ConfigFolder = "DripClient",
    IntroEnabled = true,
    IntroText = "Drip Client System",
    IntroIcon = "rbxassetid://4483345998"
})

-- ================== UI TABS & ELEMENTS ==================
local TabInfo = Window:MakeTab({
    Name = "Update Notice 🛠️",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

TabInfo:AddLabel("🚨 PENGUMUMAN WAJIB / MAINTENANCE SISTEM 🚨")

-- 1. SISTEM MARQUEE TEXT (TEKS BERJALAN)
local baseMarqueeText = "⚠️ PERINGATAN: DRIP CLIENT PREMIUM TIDAK PERNAH DIPERJUALBELIKAN DI LUAR SALURAN WHATSAPP RESMI PUTZZDEV! HATI-HATI PENIPUAN! ⚠️      "
local MarqueeLabel = TabInfo:AddLabel(baseMarqueeText)

TabInfo:AddParagraph("STATUS SCRIPT: DISABLED / UNDER DEVELOPMENT", "Script Drip Client saat ini DI-NONAKTIFKAN SEMENTARA. Tindakan ini diambil demi keamanan akun pengguna karena sistem mendeteksi adanya celah keamanan yang wajib diperbaiki segera.")

TabInfo:AddParagraph("FOKUS UTAMA MAINTENANCE:", "1. Memperbaiki seluruh error script dan crash eksternal.\n2. Melakukan bypass total terhadap deteksi anti-cheat game terbaru.\n3. Optimalisasi kestabilan fitur dan penambahan fitur baru premium.")

-- Label Info Timer & Auto Kick
local TimerLabel = TabInfo:AddLabel("Sisa Waktu Update: Menghitung...")
local KickLabel = TabInfo:AddLabel("Game akan ditutup otomatis dalam: " .. kickTimeout .. " detik")

-- Tombol Saluran WhatsApp Resmi
TabInfo:AddButton({
    Name = "📢 MASUK SALURAN WHATSAPP (KLIK UNTUK SALIN LINK)",
    Callback = function()
        setclipboard("https://whatsapp.com/channel/0029VbD9AJ36rsQm4hMLqR1R")
        OrionLib:MakeNotification({
            Name = "Drip Client Link",
            Content = "Link Saluran WhatsApp berhasil disalin ke clipboard!",
            Image = "rbxassetid://4483345998",
            Time = 3
        })
    end
})

-- ================== LOOPS & AUTOMATION ==================

-- Loop 1: Sistem Teks Berjalan (Marquee Effect)
task.spawn(function()
    local displayUpdateText = baseMarqueeText
    while true do
        task.wait(0.15)
        pcall(function()
            displayUpdateText = string.sub(displayUpdateText, 2) .. string.sub(displayUpdateText, 1, 1)
            MarqueeLabel:Set(displayUpdateText)
        end)
    end
end)

-- Loop 2: Update Waktu Maintenance
task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            TimerLabel:Set("Sisa Waktu Update: " .. getRemainingTime())
        end)
    end
end)

-- Loop 3: Hitung Mundur Auto-Kick
task.spawn(function()
    while kickTimeout > 0 do
        task.wait(1)
        kickTimeout = kickTimeout - 1
        pcall(function()
            KickLabel:Set("Game akan ditutup otomatis dalam: " .. kickTimeout .. " detik")
        end)
    end
    
    LocalPlayer:Kick("Kick by Putzzdev maaf script sedang update harap tunggu.")
end)

-- Notification Load
OrionLib:MakeNotification({
    Name = "System Notice Loaded",
    Content = "Teks Berjalan & Auto-Kick Aktif.",
    Image = "rbxassetid://4483345998",
    Time = 3
})

-- Init Orion
OrionLib:Init()