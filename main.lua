--[[
    CHEAT v4 - Рабочая версия
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

-- Защита
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

-- Переменные
local Settings = {
    ESP = false, Chams = false, Tracers = false, Aimbot = true,
    Triggerbot = false, IgnoreWalls = false, Fullbright = false,
    InfJump = false, Noclip = false, Fly = false, Speed = false,
    Bhop = false, Spin = false, AntiAFK = false, Hitbox = false,
    CamLock = false, Xray = false, Rainbow = false, FOVCircle = true
}

local Cfg = {
    FOV = 200, Smooth = 80, Pred = 0.1, WalkSpd = 16, JumpPwr = 50,
    FlySpd = 50, SpinSpd = 30, HitboxSize = 15, HitVol = 5,
    Color = Color3.fromRGB(150, 150, 150)
}

local ESP_Objects = {}
local Chams_Objects = {}
local Tracer_Lines = {}
local Conns = {}

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Color = Cfg.Color
FOVCircle.Transparency = 0.5
FOVCircle.Filled = false
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

-- ESP
local function MakeESP(plr)
    if plr == LP or ESP_Objects[plr] then return end
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
    ESP_Objects[plr] = bb
end

local function RemoveESP(plr)
    if ESP_Objects[plr] then ESP_Objects[plr]:Destroy(); ESP_Objects[plr] = nil end
end

-- Chams
local function MakeChams(plr)
    if plr == LP or Chams_Objects[plr] then return end
    local chr = plr.Character
    if not chr then return end
    
    local hl = Instance.new("Highlight")
    hl.FillColor = Cfg.Color
    hl.OutlineColor = Cfg.Color
    hl.FillTransparency = 0.5
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = chr
    Chams_Objects[plr] = hl
end

local function RemoveChams(plr)
    if Chams_Objects[plr] then Chams_Objects[plr]:Destroy(); Chams_Objects[plr] = nil end
end

-- Tracers
local function UpdateTracers()
    for _, l in pairs(Tracer_Lines) do l:Remove() end
    Tracer_Lines = {}
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
                    table.insert(Tracer_Lines, ln)
                end
            end
        end
    end
end

-- Movement
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
local isAiming = false

RunService.RenderStepped:Connect(function()
    local m = UserInputService:GetMouseLocation()
    FOVCircle.Position = Vector2.new(m.X, m.Y)
    FOVCircle.Radius = Cfg.FOV
    FOVCircle.Visible = Settings.FOVCircle
    
    if Settings.ESP then
        for _, p in pairs(Players:GetPlayers()) do if p ~= LP and p.Character then MakeESP(p) end end
    else
        for p in pairs(ESP_Objects) do RemoveESP(p) end
    end
    
    if Settings.Chams then
        for _, p in pairs(Players:GetPlayers()) do if p ~= LP and p.Character then MakeChams(p) end end
    else
        for p in pairs(Chams_Objects) do RemoveChams(p) end
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
local Win = Lib:CreateWindow({Title = "Cheat v4", Center = true, AutoShow = true})

local T1 = Win:AddTab("Визуалы")
local T2 = Win:AddTab("Боевые")
local T3 = Win:AddTab("Движение")
local T4 = Win:AddTab("Разное")
local T5 = Win:AddTab("Игроки")

-- Визуалы
local G1L = T1:AddLeftGroupbox("ESP")
local G1R = T1:AddRightGroupbox("Цвета")

G1L:AddToggle("t1", {Text = "ESP", Default = false, Callback = function(v) Settings.ESP = v end})
G1L:AddToggle("t2", {Text = "Chams", Default = false, Callback = function(v) Settings.Chams = v end})
G1L:AddToggle("t3", {Text = "Трейсеры", Default = false, Callback = function(v) Settings.Tracers = v end})
G1L:AddToggle("t4", {Text = "X-Ray", Default = false, Callback = function(v) Settings.Xray = v; SetXray(v) end})
G1L:AddToggle("t5", {Text = "FOV круг", Default = true, Callback = function(v) Settings.FOVCircle = v end})
G1L:AddToggle("t6", {Text = "Fullbright", Default = false, Callback = function(v) Settings.Fullbright = v end})
G1L:AddToggle("t7", {Text = "Убрать тени", Default = false, Callback = function(v) Lighting.GlobalShadows = not v end})
G1L:AddToggle("t8", {Text = "Радуга", Default = false, Callback = function(v) Settings.Rainbow = v; SetRainbow(v) end})

G1R:AddLabel("Цвет"):AddColorPicker("c1", {Default = Color3.fromRGB(150,150,150), Callback = function(v) Cfg.Color = v; FOVCircle.Color = v end})
G1R:AddToggle("t9", {Text = "FPS Буст", Default = false, Callback = function(v)
    if v then Workspace.Terrain.WaterWaveSize = 0; Lighting.FogEnd = 9e9; settings().Rendering.QualityLevel = "Level01" end
end})

-- Боевые
local G2L = T2:AddLeftGroupbox("Аимбот")
local G2R = T2:AddRightGroupbox("Доп.")

G2L:AddToggle("t10", {Text = "Аимбот", Default = true, Callback = function(v) Settings.Aimbot = v end})
G2L:AddToggle("t11", {Text = "Camera Lock", Default = false, Callback = function(v) Settings.CamLock = v end})
G2L:AddToggle("t12", {Text = "Триггербот", Default = false, Callback = function(v) Settings.Triggerbot = v end})
G2L:AddToggle("t13", {Text = "Игнор стен", Default = false, Callback = function(v) Settings.IgnoreWalls = v end})
G2L:AddSlider("s1", {Text = "FOV", Default = 200, Min = 50, Max = 600, Rounding = 0, Callback = function(v) Cfg.FOV = v end})
G2L:AddSlider("s2", {Text = "Плавность", Default = 80, Min = 1, Max = 200, Rounding = 0, Callback = function(v) Cfg.Smooth = v end})
G2L:AddSlider("s3", {Text = "Предикшн", Default = 0.1, Min = 0, Max = 1, Rounding = 2, Callback = function(v) Cfg.Pred = v end})

G2R:AddToggle("t14", {Text = "Расширить хитбоксы", Default = false, Callback = function(v) Settings.Hitbox = v; if not v then SetHitbox(false) end end})
G2R:AddSlider("s4", {Text = "Размер хитбокса", Default = 15, Min = 5, Max = 30, Rounding = 0, Callback = function(v) Cfg.HitboxSize = v end})

-- Движение
local G3L = T3:AddLeftGroupbox("Движение")
local G3R = T3:AddRightGroupbox("Настройки")

G3L:AddToggle("t15", {Text = "Бесконечный прыжок", Default = false, Callback = function(v) Settings.InfJump = v end})
G3L:AddToggle("t16", {Text = "Ноклип", Default = false, Callback = function(v) Settings.Noclip = v; SetNoclip(v) end})
G3L:AddToggle("t17", {Text = "Полёт", Default = false, Callback = function(v) Settings.Fly = v; SetFly(v) end})
G3L:AddToggle("t18", {Text = "Спидхак", Default = false, Callback = function(v) Settings.Speed = v end})
G3L:AddToggle("t19", {Text = "Банихоп", Default = false, Callback = function(v) Settings.Bhop = v; SetBhop(v) end})
G3L:AddToggle("t20", {Text = "Спинбот", Default = false, Callback = function(v) Settings.Spin = v; SetSpin(v) end})

G3R:AddSlider("s5", {Text = "Скорость", Default = 16, Min = 16, Max = 200, Rounding = 0, Callback = function(v) Cfg.WalkSpd = v end})
G3R:AddSlider("s6", {Text = "Прыжок", Default = 50, Min = 50, Max = 200, Rounding = 0, Callback = function(v) Cfg.JumpPwr = v end})
G3R:AddSlider("s7", {Text = "Скорость полёта", Default = 50, Min = 10, Max = 200, Rounding = 0, Callback = function(v) Cfg.FlySpd = v end})
G3R:AddSlider("s8", {Text = "Скорость вращения", Default = 30, Min = 5, Max = 60, Rounding = 0, Callback = function(v) Cfg.SpinSpd = v end})

-- Разное
local G4L = T4:AddLeftGroupbox("Утилиты")
local G4R = T4:AddRightGroupbox("Сервер")

G4L:AddToggle("t21", {Text = "Анти-АФК", Default = false, Callback = function(v) Settings.AntiAFK = v; SetAFK(v) end})
G4L:AddButton("Респавн", function() if LP.Character then LP.Character:BreakJoints() end end)
G4L:AddButton("Сбросить скорость", function()
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = 16; h.JumpPower = 50 end
    Lib:Notify("Сброшено!")
end)

G4R:AddButton("Переподключиться", function() TeleportService:Teleport(game.PlaceId, LP) end)
G4R:AddButton("Сменить сервер", function()
    pcall(function()
        local s = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
        for _, sv in pairs(s.data) do
            if sv.playing < sv.maxPlayers and sv.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, sv.id, LP)
                break
            end
        end
    end)
end)

-- Игроки
local G5L = T5:AddLeftGroupbox("Список")
local G5R = T5:AddRightGroupbox("Действия")

local selP = nil
local pList = {}

local function UpdList()
    pList = {}
    for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(pList, p.Name) end end
    if Options and Options.dp then Options.dp:SetValues(pList) end
end

G5L:AddButton("Обновить", function() UpdList(); Lib:Notify("Обновлено!") end)
G5L:AddDropdown("dp", {Values = pList, Text = "Игрок", Callback = function(v) selP = Players:FindFirstChild(v) end})

G5R:AddButton("Наблюдать", function()
    if selP and selP.Character then Cam.CameraSubject = selP.Character:FindFirstChildOfClass("Humanoid"); Lib:Notify("Наблюдаем") end
end)
G5R:AddButton("Перестать", function()
    if LP.Character then Cam.CameraSubject = LP.Character:FindFirstChildOfClass("Humanoid") end
end)
G5R:AddButton("Телепорт", function()
    if selP and selP.Character and LP.Character then
        local t = selP.Character:FindFirstChild("HumanoidRootPart")
        local m = LP.Character:FindFirstChild("HumanoidRootPart")
        if t and m then m.CFrame = t.CFrame * CFrame.new(0,0,3); Lib:Notify("ТП!") end
    end
end)
G5R:AddButton("Копировать ник", function()
    if selP and setclipboard then setclipboard(selP.Name); Lib:Notify("Скопировано!") end
end)

Players.PlayerAdded:Connect(function() task.wait(1); UpdList() end)
Players.PlayerRemoving:Connect(function() task.wait(0.5); UpdList() end)
task.spawn(UpdList)

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
        Lib:SetWatermark(string.format("Cheat v4 | FPS: %d | Пинг: %dms", fps, ping))
        fps, lt = 0, tick()
    end
end)

Lib.KeybindFrame.Visible = true
StarterGui:SetCore("SendNotification", {Title = "Cheat", Text = "Загружен!", Duration = 3})
print("Cheat v4 загружен!")
