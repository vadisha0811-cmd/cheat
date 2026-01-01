--[[
    CHEAT v5 - Полная версия
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")

local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera
local Mouse = LP:GetMouse()

pcall(function()
    local mt = getrawmetatable(game)
    if mt and setreadonly then
        setreadonly(mt, false)
        local old = mt.__namecall
        mt.__namecall = newcclosure(function(s, ...)
            if getnamecallmethod() == "Kick" then return wait(9e9) end
            return old(s, ...)
        end)
        setreadonly(mt, true)
    end
end)

local Settings = {
    ESP = false, Chams = false, Tracers = false, Aimbot = true,
    Triggerbot = false, Fullbright = false, InfJump = false,
    Noclip = false, Fly = false, Speed = false, Bhop = false,
    Spin = false, AntiAFK = false, Hitbox = false, CamLock = false,
    Xray = false, Rainbow = false, FOVCircle = true
}

local Cfg = {
    FOV = 200, Smooth = 80, Pred = 0.1, WalkSpd = 16, JumpPwr = 50,
    FlySpd = 50, SpinSpd = 30, HitboxSize = 15,
    Color = Color3.fromRGB(150, 150, 150)
}

local ESP_Obj, Chams_Obj, Tracers, Conns = {}, {}, {}, {}
local isAiming = false
local SelectedPlayer = nil

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Color = Cfg.Color
FOVCircle.Transparency = 0.5
FOVCircle.Radius = Cfg.FOV
FOVCircle.Visible = true

-- Функции
local function GetTarget()
    local closest, dist = nil, Cfg.FOV
    local mPos = UserInputService:GetMouseLocation()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local head = p.Character:FindFirstChild("Head")
            if head then
                local pos, vis = Cam:WorldToViewportPoint(head.Position)
                if vis then
                    local d = (Vector2.new(pos.X, pos.Y) - mPos).Magnitude
                    if d < dist then dist = d; closest = p end
                end
            end
        end
    end
    return closest
end

local function AimAt(pos)
    local scr = Cam:WorldToViewportPoint(pos)
    local mse = UserInputService:GetMouseLocation()
    local dx = (scr.X - mse.X) * (Cfg.Smooth / 100)
    local dy = (scr.Y - mse.Y) * (Cfg.Smooth / 100)
    if mousemoverel then mousemoverel(dx, dy) end
end

local function MakeESP(plr)
    if plr == LP or ESP_Obj[plr] then return end
    local chr = plr.Character
    if not chr then return end
    local hrp = chr:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bb = Instance.new("BillboardGui")
    bb.Adornee = hrp
    bb.Size = UDim2.new(4, 0, 5, 0)
    bb.AlwaysOnTop = true
    local fr = Instance.new("Frame", bb)
    fr.Size = UDim2.new(1, 0, 1, 0)
    fr.BackgroundTransparency = 1
    local st = Instance.new("UIStroke", fr)
    st.Color = Cfg.Color
    st.Thickness = 2
    local nm = Instance.new("TextLabel", fr)
    nm.Size = UDim2.new(1, 0, 0.2, 0)
    nm.BackgroundTransparency = 1
    nm.Text = plr.Name
    nm.TextColor3 = Cfg.Color
    nm.TextScaled = true
    nm.Font = Enum.Font.SourceSansBold
    bb.Parent = hrp
    ESP_Obj[plr] = bb
end

local function RemoveESP(plr)
    if ESP_Obj[plr] then ESP_Obj[plr]:Destroy(); ESP_Obj[plr] = nil end
end

local function MakeChams(plr)
    if plr == LP or Chams_Obj[plr] then return end
    local chr = plr.Character
    if not chr then return end
    local hl = Instance.new("Highlight")
    hl.FillColor = Cfg.Color
    hl.OutlineColor = Cfg.Color
    hl.FillTransparency = 0.5
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = chr
    Chams_Obj[plr] = hl
end

local function RemoveChams(plr)
    if Chams_Obj[plr] then Chams_Obj[plr]:Destroy(); Chams_Obj[plr] = nil end
end

local function UpdateTracers()
    for _, l in pairs(Tracers) do l:Remove() end
    Tracers = {}
    if not Settings.Tracers then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local pos, vis = Cam:WorldToViewportPoint(hrp.Position)
                if vis then
                    local ln = Drawing.new("Line")
                    ln.From = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y)
                    ln.To = Vector2.new(pos.X, pos.Y)
                    ln.Color = Cfg.Color
                    ln.Thickness = 1
                    ln.Visible = true
                    table.insert(Tracers, ln)
                end
            end
        end
    end
end

UserInputService.JumpRequest:Connect(function()
    if Settings.InfJump and LP.Character then
        local h = LP.Character:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

local function SetNoclip(on)
    if Conns.noclip then Conns.noclip:Disconnect(); Conns.noclip = nil end
    if on then
        Conns.noclip = RunService.Stepped:Connect(function()
            if LP.Character then
                for _, p in pairs(LP.Character:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    end
end

local function SetFly(on)
    if Conns.fly then Conns.fly:Disconnect(); Conns.fly = nil end
    if Conns.bv then Conns.bv:Destroy(); Conns.bv = nil end
    if Conns.bg then Conns.bg:Destroy(); Conns.bg = nil end
    if on then
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        Conns.bv = Instance.new("BodyVelocity", hrp)
        Conns.bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        Conns.bg = Instance.new("BodyGyro", hrp)
        Conns.bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        Conns.bg.P = 9e4
        Conns.fly = RunService.RenderStepped:Connect(function()
            local d = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then d = d + Cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then d = d - Cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then d = d - Cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then d = d + Cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then d = d - Vector3.yAxis end
            Conns.bv.Velocity = d * Cfg.FlySpd
            Conns.bg.CFrame = Cam.CFrame
        end)
    end
end

local function SetSpin(on)
    if Conns.spin then Conns.spin:Disconnect(); Conns.spin = nil end
    if on then
        Conns.spin = RunService.RenderStepped:Connect(function()
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(Cfg.SpinSpd), 0) end
        end)
    end
end

local function SetBhop(on)
    if Conns.bhop then Conns.bhop:Disconnect(); Conns.bhop = nil end
    if on then
        Conns.bhop = RunService.RenderStepped:Connect(function()
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h and h.FloorMaterial ~= Enum.Material.Air then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end

local function SetAFK(on)
    if Conns.afk then Conns.afk:Disconnect(); Conns.afk = nil end
    if on then
        local vu = game:GetService("VirtualUser")
        Conns.afk = LP.Idled:Connect(function() vu:CaptureController(); vu:ClickButton2(Vector2.new()) end)
    end
end

local function SetHitbox(on)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Size = on and Vector3.new(Cfg.HitboxSize, Cfg.HitboxSize, Cfg.HitboxSize) or Vector3.new(2, 2, 1)
                hrp.Transparency = on and 0.7 or 1
            end
        end
    end
end

local function SetXray(on)
    for _, o in pairs(Workspace:GetDescendants()) do
        if o:IsA("BasePart") and not Players:GetPlayerFromCharacter(o.Parent) then
            o.LocalTransparencyModifier = on and 0.8 or 0
        end
    end
end

local function SetRainbow(on)
    if Conns.rainbow then Conns.rainbow:Disconnect(); Conns.rainbow = nil end
    if on then
        Conns.rainbow = RunService.RenderStepped:Connect(function()
            Cfg.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
            FOVCircle.Color = Cfg.Color
        end)
    end
end

-- Main Loop
RunService.RenderStepped:Connect(function()
    local m = UserInputService:GetMouseLocation()
    FOVCircle.Position = Vector2.new(m.X, m.Y)
    FOVCircle.Radius = Cfg.FOV
    FOVCircle.Visible = Settings.FOVCircle
    
    if Settings.ESP then
        for _, p in pairs(Players:GetPlayers()) do if p ~= LP and p.Character then MakeESP(p) end end
    else
        for p in pairs(ESP_Obj) do RemoveESP(p) end
    end
    
    if Settings.Chams then
        for _, p in pairs(Players:GetPlayers()) do if p ~= LP and p.Character then MakeChams(p) end end
    else
        for p in pairs(Chams_Obj) do RemoveChams(p) end
    end
    
    UpdateTracers()
    
    if Settings.Speed and LP.Character then
        local h = LP.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = Cfg.WalkSpd; h.JumpPower = Cfg.JumpPwr end
    end
    
    if Settings.Hitbox then SetHitbox(true) end
    
    if Settings.Fullbright then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    end
    
    if Settings.Triggerbot then
        local t = Mouse.Target
        if t and t.Parent then
            local p = Players:GetPlayerFromCharacter(t.Parent)
            if p and p ~= LP then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end
        end
    end
    
    if isAiming and Settings.Aimbot then
        local tgt = GetTarget()
        if tgt and tgt.Character then
            local head = tgt.Character:FindFirstChild("Head")
            if head then
                local hrp = tgt.Character:FindFirstChild("HumanoidRootPart")
                local vel = hrp and hrp.AssemblyLinearVelocity or Vector3.zero
                AimAt(head.Position + vel * Cfg.Pred)
            end
        end
    end
    
    if Settings.CamLock then
        local tgt = GetTarget()
        if tgt and tgt.Character then
            local head = tgt.Character:FindFirstChild("Head")
            if head then Cam.CFrame = CFrame.new(Cam.CFrame.Position, head.Position) end
        end
    end
end)

UserInputService.InputBegan:Connect(function(i, g)
    if not g and i.UserInputType == Enum.UserInputType.MouseButton2 then isAiming = true end
end)

UserInputService.InputEnded:Connect(function(i, g)
    if not g and i.UserInputType == Enum.UserInputType.MouseButton2 then isAiming = false end
end)

Players.PlayerRemoving:Connect(function(p) RemoveESP(p); RemoveChams(p) end)

-- UI
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local Win = Lib:CreateWindow({Title = "Cheat v5", Center = true, AutoShow = true})

local T1 = Win:AddTab("Визуалы")
local T2 = Win:AddTab("Боевые")
local T3 = Win:AddTab("Движение")
local T4 = Win:AddTab("Разное")
local T5 = Win:AddTab("Игроки")

-- TAB 1: Визуалы
local G1L = T1:AddLeftGroupbox("ESP")
local G1R = T1:AddRightGroupbox("Цвета")

G1L:AddToggle("ESP", {Text = "ESP", Default = false, Callback = function(v) Settings.ESP = v end})
G1L:AddToggle("Chams", {Text = "Chams", Default = false, Callback = function(v) Settings.Chams = v end})
G1L:AddToggle("Tracers", {Text = "Трейсеры", Default = false, Callback = function(v) Settings.Tracers = v end})
G1L:AddToggle("Xray", {Text = "X-Ray", Default = false, Callback = function(v) Settings.Xray = v; SetXray(v) end})
G1L:AddToggle("FOVCircle", {Text = "FOV круг", Default = true, Callback = function(v) Settings.FOVCircle = v end})
G1L:AddToggle("Fullbright", {Text = "Fullbright", Default = false, Callback = function(v) Settings.Fullbright = v end})
G1L:AddToggle("NoShadow", {Text = "Убрать тени", Default = false, Callback = function(v) Lighting.GlobalShadows = not v end})
G1L:AddToggle("Rainbow", {Text = "Радуга", Default = false, Callback = function(v) Settings.Rainbow = v; SetRainbow(v) end})

G1R:AddLabel("Цвет"):AddColorPicker("MainColor", {Default = Color3.fromRGB(150,150,150), Callback = function(v) Cfg.Color = v; FOVCircle.Color = v end})
G1R:AddToggle("FPSBoost", {Text = "FPS Буст", Default = false, Callback = function(v)
    if v then Workspace.Terrain.WaterWaveSize = 0; Lighting.FogEnd = 9e9; settings().Rendering.QualityLevel = "Level01" end
end})

-- TAB 2: Боевые
local G2L = T2:AddLeftGroupbox("Аимбот")
local G2R = T2:AddRightGroupbox("Доп.")

G2L:AddToggle("Aimbot", {Text = "Аимбот", Default = true, Callback = function(v) Settings.Aimbot = v end})
G2L:AddToggle("CamLock", {Text = "Camera Lock", Default = false, Callback = function(v) Settings.CamLock = v end})
G2L:AddToggle("Triggerbot", {Text = "Триггербот", Default = false, Callback = function(v) Settings.Triggerbot = v end})
G2L:AddSlider("FOVSlider", {Text = "FOV", Default = 200, Min = 50, Max = 600, Rounding = 0, Callback = function(v) Cfg.FOV = v end})
G2L:AddSlider("SmoothSlider", {Text = "Плавность", Default = 80, Min = 1, Max = 200, Rounding = 0, Callback = function(v) Cfg.Smooth = v end})
G2L:AddSlider("PredSlider", {Text = "Предикшн", Default = 0.1, Min = 0, Max = 1, Rounding = 2, Callback = function(v) Cfg.Pred = v end})

G2R:AddToggle("Hitbox", {Text = "Расширить хитбоксы", Default = false, Callback = function(v) Settings.Hitbox = v; if not v then SetHitbox(false) end end})
G2R:AddSlider("HitboxSize", {Text = "Размер хитбокса", Default = 15, Min = 5, Max = 30, Rounding = 0, Callback = function(v) Cfg.HitboxSize = v end})

-- TAB 3: Движение
local G3L = T3:AddLeftGroupbox("Движение")
local G3R = T3:AddRightGroupbox("Настройки")

G3L:AddToggle("InfJump", {Text = "Бесконечный прыжок", Default = false, Callback = function(v) Settings.InfJump = v end})
G3L:AddToggle("Noclip", {Text = "Ноклип", Default = false, Callback = function(v) Settings.Noclip = v; SetNoclip(v) end})
G3L:AddToggle("Fly", {Text = "Полёт", Default = false, Callback = function(v) Settings.Fly = v; SetFly(v) end})
G3L:AddToggle("Speed", {Text = "Спидхак", Default = false, Callback = function(v) Settings.Speed = v end})
G3L:AddToggle("Bhop", {Text = "Банихоп", Default = false, Callback = function(v) Settings.Bhop = v; SetBhop(v) end})
G3L:AddToggle("Spin", {Text = "Спинбот", Default = false, Callback = function(v) Settings.Spin = v; SetSpin(v) end})

G3R:AddSlider("WalkSpd", {Text = "Скорость", Default = 16, Min = 16, Max = 200, Rounding = 0, Callback = function(v) Cfg.WalkSpd = v end})
G3R:AddSlider("JumpPwr", {Text = "Прыжок", Default = 50, Min = 50, Max = 200, Rounding = 0, Callback = function(v) Cfg.JumpPwr = v end})
G3R:AddSlider("FlySpd", {Text = "Скорость полёта", Default = 50, Min = 10, Max = 200, Rounding = 0, Callback = function(v) Cfg.FlySpd = v end})
G3R:AddSlider("SpinSpd", {Text = "Скорость вращения", Default = 30, Min = 5, Max = 60, Rounding = 0, Callback = function(v) Cfg.SpinSpd = v end})

-- TAB 4: Разное
local G4L = T4:AddLeftGroupbox("Утилиты")
local G4R = T4:AddRightGroupbox("Сервер")

G4L:AddToggle("AntiAFK", {Text = "Анти-АФК", Default = false, Callback = function(v) Settings.AntiAFK = v; SetAFK(v) end})
G4L:AddButton({Text = "Респавн", Func = function() if LP.Character then LP.Character:BreakJoints() end end})
G4L:AddButton({Text = "Сбросить скорость", Func = function()
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = 16; h.JumpPower = 50 end
    Lib:Notify("Сброшено!")
end})

G4R:AddButton({Text = "Переподключиться", Func = function() TeleportService:Teleport(game.PlaceId, LP) end})
G4R:AddButton({Text = "Сменить сервер", Func = function()
    pcall(function()
        local s = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
        for _, sv in pairs(s.data) do
            if sv.playing < sv.maxPlayers and sv.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, sv.id, LP)
                break
            end
        end
    end)
end})

-- TAB 5: Игроки
local G5L = T5:AddLeftGroupbox("Список")
local G5R = T5:AddRightGroupbox("Действия")

G5L:AddButton({Text = "Обновить список", Func = function()
    local names = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(names, p.Name) end
    end
    if Options and Options.PlayerList then
        Options.PlayerList:SetValues(names)
    end
    Lib:Notify("Обновлено! ("..#names.." игроков)")
end})

G5L:AddDropdown("PlayerList", {
    Values = {},
    Default = nil,
    Text = "Выбрать игрока",
    Callback = function(v)
        SelectedPlayer = Players:FindFirstChild(v)
        if SelectedPlayer then Lib:Notify("Выбран: "..v) end
    end
})

G5R:AddButton({Text = "Наблюдать", Func = function()
    if SelectedPlayer and SelectedPlayer.Character then
        Cam.CameraSubject = SelectedPlayer.Character:FindFirstChildOfClass("Humanoid")
        Lib:Notify("Наблюдаем: "..SelectedPlayer.Name)
    else
        Lib:Notify("Сначала выбери игрока!")
    end
end})

G5R:AddButton({Text = "Перестать наблюдать", Func = function()
    if LP.Character then
        Cam.CameraSubject = LP.Character:FindFirstChildOfClass("Humanoid")
        Lib:Notify("Остановлено")
    end
end})

G5R:AddButton({Text = "Телепорт к игроку", Func = function()
    if SelectedPlayer and SelectedPlayer.Character and LP.Character then
        local t = SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
        local m = LP.Character:FindFirstChild("HumanoidRootPart")
        if t and m then
            m.CFrame = t.CFrame * CFrame.new(0, 0, 3)
            Lib:Notify("Телепорт к: "..SelectedPlayer.Name)
        end
    else
        Lib:Notify("Сначала выбери игрока!")
    end
end})

G5R:AddButton({Text = "Копировать ник", Func = function()
    if SelectedPlayer then
        if setclipboard then
            setclipboard(SelectedPlayer.Name)
            Lib:Notify("Скопировано: "..SelectedPlayer.Name)
        end
    else
        Lib:Notify("Сначала выбери игрока!")
    end
end})

G5R:AddButton({Text = "Инфо об игроке", Func = function()
    if SelectedPlayer then
        local info = "Ник: "..SelectedPlayer.Name.."\nID: "..SelectedPlayer.UserId.."\nВозраст: "..SelectedPlayer.AccountAge.." дней"
        Lib:Notify(info, 5)
    else
        Lib:Notify("Сначала выбери игрока!")
    end
end})

-- Авто-обновление списка
Players.PlayerAdded:Connect(function()
    task.wait(1)
    local names = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(names, p.Name) end
    end
    if Options and Options.PlayerList then Options.PlayerList:SetValues(names) end
end)

Players.PlayerRemoving:Connect(function()
    task.wait(0.5)
    local names = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(names, p.Name) end
    end
    if Options and Options.PlayerList then Options.PlayerList:SetValues(names) end
end)

-- Инициализация списка
task.spawn(function()
    task.wait(1)
    local names = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(names, p.Name) end
    end
    if Options and Options.PlayerList then Options.PlayerList:SetValues(names) end
end)

-- Тема
Lib.AccentColor = Color3.fromRGB(150, 150, 150)
Lib.AccentColorDark = Color3.fromRGB(100, 100, 100)
Lib:UpdateColorsUsingRegistry()

-- Watermark
Lib:SetWatermarkVisibility(true)
local fps, lt = 0, tick()
RunService.RenderStepped:Connect(function()
    fps = fps + 1
    if tick() - lt >= 1 then
        local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        Lib:SetWatermark(string.format("Cheat v5 | FPS: %d | Пинг: %dms", fps, ping))
        fps, lt = 0, tick()
    end
end)

Lib.KeybindFrame.Visible = true
StarterGui:SetCore("SendNotification", {Title = "Cheat v5", Text = "Загружен!", Duration = 3})
print("Cheat v5 загружен!")
