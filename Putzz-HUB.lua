-- ====================================================================
-- DRIPT CLIENT PREMIUM — UNIVERSAL MAINTENANCE & COUNTDOWN SYSTEM
-- ====================================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Dript Client Premium",
   LoadingTitle = "Dript Client Premium Core Engine",
   LoadingSubtitle = "by Putzzdev",
   ConfigurationSaving = {
      Enabled = false
   },
   Discord = {
      Enabled = false
   },
   KeySystem = false
})

-- ====================================================================
-- LOGIKA HITUNG MUNDUR (COUNTDOWN TIMER) 24 JAM
-- ====================================================================
local targetDuration = 86400 
local startTime = os.time()
local targetTime = startTime + targetDuration

-- TAB 1: INFORMASI
local InfoTab = Window:CreateTab("Informasi", 4483362458)

-- Pengumuman Rapat & Rahasia (Tanpa Bocoran Fitur)
InfoTab:CreateParagraph({
    Title = "⚠️ PEMBERITAHUAN: SYSTEM UNDER MAINTENANCE", 
    Content = "Halo seluruh pengguna setia Dript Client Premium! Saat ini, core system kami sedang memasuki masa pemeliharaan wajib dan pengamanan database server secara berkala.\n\n" ..
              "Tim developer sedang fokus melakukan perbaikan bug menyeluruh (fix bugs), melakukan optimalisasi sistem agar performa script jauh lebih ringan, serta menyuntikkan sistem perlindungan tambahan demi keamanan akun Anda.\n\n" ..
              "Demi kenyamanan bersama, seluruh fungsi eksekusi dinonaktifkan sementara waktu sampai pembaruan ini selesai sepenuhnya."
})

-- Label Real-time Countdown Timer
local TimerLabel = InfoTab:CreateLabel("⏳ Sisa Waktu Pemeliharaan: Menghubungkan...")

InfoTab:CreateButton({
   Name = "Join Saluran WA untuk Info Live Update",
   Callback = function()
      setclipboard("https://whatsapp.com/channel/0029VbD9AJ36rsQm4hMLqR1R")
      Rayfield:Notify({
         Title = "Berhasil",
         Content = "Link saluran WA sudah disalin ke clipboard",
         Duration = 3,
         Image = 4483362458
      })
   end,
})

InfoTab:CreateLabel("Script Status: [MAINTENANCE MODE]")

-- ====================================================================
-- TAB 2: UPDATE DETAIL
-- ====================================================================
local UpdateTab = Window:CreateTab("Update Detail", 4483345875)

UpdateTab:CreateParagraph({
    Title = "📢 Rencana Pengembangan Patch Terbaru", 
    Content = "Kami sedang merombak struktur internal agar script menjadi jauh lebih stabil saat digunakan nanti. Anda dapat memantau info perilisan resmi melalui tautan di bawah."
})

UpdateTab:CreateLabel("🌐 Tautan Komunitas Resmi:")

UpdateTab:CreateButton({
   Name = "Saluran WhatsApp",
   Callback = function()
      setclipboard("https://whatsapp.com/channel/0029VbD9AJ36rsQm4hMLqR1R")
      Rayfield:Notify({
         Title = "Link Di Copy",
         Content = "Link WA Channel berhasil di copy",
         Duration = 3,
         Image = 4483362458
      })
   end,
})

UpdateTab:CreateButton({
   Name = "Buka Link di Browser",
   Callback = function()
      local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
      if req then
         req({
            Url = "https://whatsapp.com/channel/0029VbD9AJ36rsQm4hMLqR1R",
            Method = "GET"
         })
      end
      Rayfield:Notify({
         Title = "Info Launcher",
         Content = "Jika browser tidak terbuka otomatis, silakan tempel link yang sudah tersalin ke Google Chrome.",
         Duration = 4,
         Image = 4483362458
      })
      setclipboard("https://whatsapp.com/channel/0029VbD9AJ36rsQm4hMLqR1R")
   end,
})

UpdateTab:CreateDivider()

-- Changelog Rahasia (Tanpa Menyebutkan Nama Fiturnya)
UpdateTab:CreateParagraph({
    Title = "📝 Changelog v1.1.0 (Upcoming Patch)", 
    Content = "[+] Added: Penambahan Fitur-Fitur Premium Terbaru\n" ..
              "[*] Improved: Optimalisasi FPS & Manajemen Memori\n" ..
              "[*] Improved: Peningkatan Sistem Keamanan Internal (Anti-Ban)\n" ..
              "[!] Fixed: Pembersihan Masalah Crash Pada Beberapa Device\n" ..
              "[!] Fixed: Perbaikan Bug Internal (Fix Bugs)"
})

-- Notifikasi Mengambang Saat Script Dimuat Pertama Kali
Rayfield:Notify({
   Title = "Dript Client Core",
   Content = "Sistem mendeteksi status pemeliharaan server. Silakan cek tab Informasi untuk sisa waktu.",
   Duration = 7,
   Image = 4483362458
})

-- Thread Pembaruan Waktu Hitung Mundur 24 Jam secara Otomatis
task.spawn(function()
    while true do
        local currentTime = os.time()
        local timeLeft = targetTime - currentTime
        
        if timeLeft > 0 then
            local hours = math.floor(timeLeft / 3600)
            local minutes = math.floor((timeLeft % 3600) / 60)
            local seconds = timeLeft % 60
            
            TimerLabel:Set(string.format("⏳ Sisa Waktu Pemeliharaan: %02d Jam %02d Menit %02d Detik", hours, minutes, seconds))
        else
            TimerLabel:Set("🎉 Pemeliharaan Selesai! Silakan Muat Ulang Script.")
            break
        end
        task.wait(1)
    end
end)

Rayfield:LoadConfiguration()