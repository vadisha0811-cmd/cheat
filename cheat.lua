--[[
    CHEAT UNIVERSAL v3.1
    Исправленная версия
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Защита от кика
pcall(function()
    local mt = getrawmetatable(game)
    if mt and setreadonly then
        setreadonly(mt, false)
        local old = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            if getnamecallmethod() == "Kick" then return wait(9e9) end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end
end)

-- Состояние
local State = {
    espEnabled = false,
    chamsEnabled = false,
    tracersEnabled = false,
    aimbotEnabled = true,
    triggerbotEnabled = false,
    wallCheckDisabled = false,
    fullbrightEnabled = false,
    fovChangerEnabled = false,
    hitsoundsEnabled = false,
    infiniteJumpEnabled = false,
    noclipEnabled = false,
    speedEnabled = false,
    flyEnabled = false,
    antiAFKEnabled = false,
    spinbotEnabled = false,
    hitboxEnabled = false,
    bhopEnabled = false,
    camLockEnabled = false,
    xrayEnabled = false,
    rainbowEnabled = false,
    isAiming = false,
    currentTarget = nil
}

-- Конфиг
local Config = {
    FOVRadius = 200,
    Smoothness = 80,
    Prediction = 0.1,
    ActivationKey = Enum.UserInputType.MouseButton2,
    TargetParts = {"Head", "UpperTorso"},
    TeamCheck = false,
    ESPColor = Color3.fromRGB(150, 150, 150),
    ChamsColor = Color3.fromRGB(150, 150, 150),
    TracerColor = Color3.fromRGB(150, 150, 150),
    ChamsTransparency = 0.5,
    HitsoundId = "rbxassetid://6916371803",
    HitsoundVolume = 5,
    WalkSpeed = 16,
    JumpPower = 50,
    FlySpeed = 50,
    HitboxSize = 15,
    SpinSpeed = 30,
    AdditionalFOV = 10
}

-- FOV Круг
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.Color = Color3.fromRGB(150, 150, 150)
fovCircle.Transparency = 0.5
fovCircle.Filled = false
fovCircle.Radius = Config.FOVRadius
fovCircle.Visible = true

-- Хранилища
local espObjects = {}
local highlights = {}
local tracers = {}
local connections = {}

-- Утилиты
local function getClosestPlayer()
    local closest, dist = nil, Config.FOVRadius
    local mousePos = UserInputService:GetMouseLocation()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local head = p.Character:FindFirstChild("Head")
            if head then
                local pos, vis = Camera:WorldToViewportPoint(head.Position)
                if vis then
                    local d = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if d < dist then dist = d; closest = p end
                end
            end
        end
    end
    return closest
end

local function aimAt(pos)
    local screen = Camera:WorldToViewportPoint(pos)
    local mouse = UserInputService:GetMouseLocation()
    local dx = (screen.X - mouse.X) * (Config.Smoothness / 100)
    local dy = (screen.Y - mouse.Y) * (Config.Smoothness / 100)
    if mousemoverel then mousemoverel(dx, dy) end
end

local function playHitsound()
    if not State.hitsoundsEnabled then return end
    local s = Instance.new("Sound", SoundService)
    s.SoundId = Config.HitsoundId
    s.Volume = Config.HitsoundVolume
    s:Play()
    task.delay(2, function() s:Destroy() end)
end

-- ESP
local function createESP(player)
    if player == LocalPlayer or espObjects[player] then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP"
    bb.Adornee = hrp
    bb.Size = UDim2.new(4, 0, 5, 0)
    bb.AlwaysOnTop = true
    
    local f = Instance.new("Frame", bb)
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundTransparency = 1
    Instance.new("UIStroke", f).Color = Config.ESPColor
    
    local n = Instance.new("TextLabel", f)
    n.Size = UDim2.new(1, 0, 0.2, 0)
    n.BackgroundTransparency = 1
    n.Text = player.Name
    n.TextColor3 = Config.ESPColor
    n.TextScaled = true
    n.Font = Enum.Font.SourceSansBold
    
    bb.Parent = hrp
    espObjects[player] = bb
end

local function removeESP(player)
    if espObjects[player] then
        espObjects[player]:Destroy()
        espObjects[player] = nil
    end
end

-- Chams
local function createChams(player)
    if player == LocalPlayer or highlights[player] then return end
    local char = player.Character
    if not char then return end
    
    local hl = Instance.new("Highlight")
    hl.FillColor = Config.ChamsColor
    hl.OutlineColor = Config.ChamsColor
    hl.FillTransparency = Config.ChamsTransparency
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = char
    highlights[player] = hl
end

local function removeChams(player)
    if highlights[player] then
        highlights[player]:Destroy()
        highlights[player] = nil
    end
end

-- Tracers
local function updateTracers()
    for _, l in pairs(tracers) do l:Remove() end
    tracers = {}
    if not State.tracersEnabled then return end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local pos, vis = Camera:WorldToViewportPoint(hrp.Position)
                if vis then
                    local l = Drawing.new("Line")
                    l.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    l.To = Vector2.new(pos.X, pos.Y)
                    l.Color = Config.TracerColor
                    l.Thickness = 1
                    l.Visible = true
                    table.insert(tracers, l)
                end
            end
        end
    end
end

-- Движение
UserInputService.JumpRequest:Connect(function()
    if State.infiniteJumpEnabled and LocalPlayer.Character then
        local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

local function toggleNoclip(on)
    if connections.noclip then connections.noclip:Disconnect() end
    if on then
        connections.noclip = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, p in pairs(LocalPlayer.Character:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    end
end

local function toggleFly(on)
    if connections.fly then connections.fly:Disconnect() end
    if connections.flyBV then connections.flyBV:Destroy() end
    if connections.flyBG then connections.flyBG:Destroy() end
    
    if on then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        connections.flyBV = Instance.new("BodyVelocity", hrp)
        connections.flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        connections.flyBG = Instance.new("BodyGyro", hrp)
        connections.flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        connections.flyBG.P = 9e4
        
        connections.fly = RunService.RenderStepped:Connect(function()
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.yAxis end
            connections.flyBV.Velocity = dir * Config.FlySpeed
            connections.flyBG.CFrame = Camera.CFrame
        end)
    end
end

local function toggleSpin(on)
    if connections.spin then connections.spin:Disconnect() end
    if on then
        connections.spin = RunService.RenderStepped:Connect(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(Config.SpinSpeed), 0) end
        end)
    end
end

local function toggleBhop(on)
    if connections.bhop then connections.bhop:Disconnect() end
    if on then
        connections.bhop = RunService.RenderStepped:Connect(function()
            local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if h and h.FloorMaterial ~= Enum.Material.Air then
                h:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end

local function toggleAntiAFK(on)
    if connections.afk then connections.afk:Disconnect() end
    if on then
        local vu = game:GetService("VirtualUser")
        connections.afk = LocalPlayer.Idled:Connect(function()
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
    end
end

local function toggleHitbox(on)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                if on then
                    hrp.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                    hrp.Transparency = 0.7
                else
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                end
            end
        end
    end
end

local function toggleXray(on)
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not Players:GetPlayerFromCharacter(obj.Parent) then
            obj.LocalTransparencyModifier = on and 0.8 or 0
        end
    end
end

local function toggleRainbow(on)
    if connections.rainbow then connections.rainbow:Disconnect() end
    if on then
        connections.rainbow = RunService.RenderStepped:Connect(function()
            local c = Color3.fromHSV(tick() % 5 / 5, 1, 1)
            fovCircle.Color = c
            Config.ESPColor = c
            Config.ChamsColor = c
            Config.TracerColor = c
        end)
    end
end

-- Главный цикл
RunService.RenderStepped:Connect(function()
    -- FOV круг
    local m = UserInputService:GetMouseLocation()
    fovCircle.Position = Vector2.new(m.X, m.Y)
    fovCircle.Radius = Config.FOVRadius
    
    -- ESP
    if State.espEnabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then createESP(p) end
        end
    else
        for p, _ in pairs(espObjects) do removeESP(p) end
    end
    
    -- Chams
    if State.chamsEnabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then createChams(p) end
        end
    else
        for p, _ in pairs(highlights) do removeChams(p) end
    end
    
    -- Tracers
    updateTracers()
    
    -- Speed
    if State.speedEnabled and LocalPlayer.Character then
        local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = Config.WalkSpeed; h.JumpPower = Config.JumpPower end
    end
    
    -- Hitbox
    if State.hitboxEnabled then toggleHitbox(true) end
    
    -- Fullbright
    if State.fullbrightEnabled then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    end
    
    -- FOV Changer
    if State.fovChangerEnabled then
        Camera.FieldOfView = 70 + Config.AdditionalFOV
    end
    
    -- Triggerbot
    if State.triggerbotEnabled then
        local t = Mouse.Target
        if t and t.Parent then
            local p = Players:GetPlayerFromCharacter(t.Parent)
            if p and p ~= LocalPlayer then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end
        end
    end
    
    -- Aimbot
    if State.isAiming and State.aimbotEnabled then
        local target = getClosestPlayer()
        if target and target.Character then
            local head = target.Character:FindFirstChild("Head")
            if head then
                local hrp = target.Character:FindFirstChild("HumanoidRootPart")
                local vel = hrp and hrp.AssemblyLinearVelocity or Vector3.zero
                local pred = head.Position + vel * Config.Prediction
                aimAt(pred)
            end
        end
    end
    
    -- CamLock
    if State.camLockEnabled then
        local target = getClosestPlayer()
        if target and target.Character then
            local head = target.Character:FindFirstChild("Head")
            if head then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            end
        end
    end
end)

-- Input
UserInputService.InputBegan:Connect(function(i, g)
    if not g and i.UserInputType == Config.ActivationKey then
        State.isAiming = true
    end
end)

UserInputService.InputEnded:Connect(function(i, g)
    if not g and i.UserInputType == Config.ActivationKey then
        State.isAiming = false
    end
end)

-- Cleanup
Players.PlayerRemoving:Connect(function(p)
    removeESP(p)
    removeChams(p)
end)

-- UI
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local TM = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"))()
local SM = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua"))()

local Win = Lib:CreateWindow({Title = "Cheat v3.1", Center = true, AutoShow = true})

local TabVis = Win:AddTab("Визуалы")
local TabCombat = Win:AddTab("Боевые")
local TabMove = Win:AddTab("Движение")
local TabMisc = Win:AddTab("Разное")
local TabPlayers = Win:AddTab("Игроки")
local TabCfg = Win:AddTab("Настройки")

-- ВИЗУАЛЫ
local VL = TabVis:AddLeftGroupbox("ESP")
local VR = TabVis:AddRightGroupbox("Цвета")

VL:AddToggle("tESP", {Text = "ESP", Default = false}):OnChanged(function(v) State.espEnabled = v end)
VL:AddToggle("tChams", {Text = "Chams", Default = false}):OnChanged(function(v) State.chamsEnabled = v end)
VL:AddToggle("tTracers", {Text = "Трейсеры", Default = false}):OnChanged(function(v) State.tracersEnabled = v end)
VL:AddToggle("tXray", {Text = "X-Ray", Default = false}):OnChanged(function(v) State.xrayEnabled = v; toggleXray(v) end)
VL:AddToggle("tFOV", {Text = "FOV круг", Default = true}):OnChanged(function(v) fovCircle.Visible = v end)
VL:AddToggle("tFull", {Text = "Fullbright", Default = false}):OnChanged(function(v) State.fullbrightEnabled = v end)
VL:AddToggle("tShadow", {Text = "Убрать тени", Default = false}):OnChanged(function(v) Lighting.GlobalShadows = not v end)
VL:AddToggle("tRainbow", {Text = "Радуга", Default = false}):OnChanged(function(v) State.rainbowEnabled = v; toggleRainbow(v) end)
VL:AddToggle("tFOVCam", {Text = "FOV камеры", Default = false}):OnChanged(function(v) State.fovChangerEnabled = v end)
VL:AddSlider("sFOVAdd", {Text = "Доп. FOV", Default = 10, Min = 0, Max = 60, Rounding = 0}):OnChanged(function(v) Config.AdditionalFOV = v end)

VR:AddLabel("ESP"):AddColorPicker("cESP", {Default = Color3.fromRGB(150,150,150)}):OnChanged(function(v) Config.ESPColor = v end)
VR:AddLabel("Chams"):AddColorPicker("cChams", {Default = Color3.fromRGB(150,150,150)}):OnChanged(function(v) Config.ChamsColor = v end)
VR:AddLabel("Трейсеры"):AddColorPicker("cTracer", {Default = Color3.fromRGB(150,150,150)}):OnChanged(function(v) Config.TracerColor = v end)
VR:AddLabel("FOV круг"):AddColorPicker("cFOV", {Default = Color3.fromRGB(150,150,150)}):OnChanged(function(v) fovCircle.Color = v end)
VR:AddSlider("sChamsT", {Text = "Прозрачность Chams", Default = 0.5, Min = 0, Max = 1, Rounding = 2}):OnChanged(function(v) Config.ChamsTransparency = v end)
VR:AddToggle("tFPS", {Text = "FPS Буст", Default = false}):OnChanged(function(v)
    if v then
        Workspace.Terrain.WaterWaveSize = 0
        Lighting.FogEnd = 9e9
        settings().Rendering.QualityLevel = "Level01"
    end
end)

-- БОЕВЫЕ
local CL = TabCombat:AddLeftGroupbox("Аимбот")
local CR = TabCombat:AddRightGroupbox("Доп.")

CL:AddToggle("tAim", {Text = "Аимбот", Default = true}):OnChanged(function(v) State.aimbotEnabled = v end)
CL:AddToggle("tCamLock", {Text = "Camera Lock", Default = false}):OnChanged(function(v) State.camLockEnabled = v end)
CL:AddToggle("tTrigger", {Text = "Триггербот", Default = false}):OnChanged(function(v) State.triggerbotEnabled = v end)
CL:AddToggle("tWall", {Text = "Игнор стен", Default = false}):OnChanged(function(v) State.wallCheckDisabled = v end)
CL:AddSlider("sFOVRad", {Text = "Радиус FOV", Default = 200, Min = 50, Max = 600, Rounding = 0}):OnChanged(function(v) Config.FOVRadius = v end)
CL:AddSlider("sSmooth", {Text = "Плавность", Default = 80, Min = 1, Max = 200, Rounding = 0}):OnChanged(function(v) Config.Smoothness = v end)
CL:AddSlider("sPred", {Text = "Предикшн", Default = 0.1, Min = 0, Max = 1, Rounding = 2}):OnChanged(function(v) Config.Prediction = v end)

CR:AddToggle("tHit", {Text = "Хитсаунды", Default = false}):OnChanged(function(v) State.hitsoundsEnabled = v end)
CR:AddSlider("sHitVol", {Text = "Громкость", Default = 5, Min = 1, Max = 10, Rounding = 0}):OnChanged(function(v) Config.HitsoundVolume = v end)
CR:AddToggle("tHitbox", {Text = "Расширить хитбоксы", Default = false}):OnChanged(function(v) State.hitboxEnabled = v; if not v then toggleHitbox(false) end end)
CR:AddSlider("sHitSize", {Text = "Размер хитбокса", Default = 15, Min = 5, Max = 30, Rounding = 0}):OnChanged(function(v) Config.HitboxSize = v end)

-- ДВИЖЕНИЕ
local ML = TabMove:AddLeftGroupbox("Передвижение")
local MR = TabMove:AddRightGroupbox("Настройки")

ML:AddToggle("tInfJump", {Text = "Бесконечный прыжок", Default = false}):OnChanged(function(v) State.infiniteJumpEnabled = v end)
ML:AddToggle("tNoclip", {Text = "Ноклип", Default = false}):OnChanged(function(v) State.noclipEnabled = v; toggleNoclip(v) end)
ML:AddToggle("tFly", {Text = "Полёт", Default = false}):OnChanged(function(v) State.flyEnabled = v; toggleFly(v) end)
ML:AddToggle("tSpeed", {Text = "Спидхак", Default = false}):OnChanged(function(v) State.speedEnabled = v end)
ML:AddToggle("tBhop", {Text = "Банихоп", Default = false}):OnChanged(function(v) State.bhopEnabled = v; toggleBhop(v) end)
ML:AddToggle("tSpin", {Text = "Спинбот", Default = false}):OnChanged(function(v) State.spinbotEnabled = v; toggleSpin(v) end)

MR:AddSlider("sWalk", {Text = "Скорость", Default = 16, Min = 16, Max = 200, Rounding = 0}):OnChanged(function(v) Config.WalkSpeed = v end)
MR:AddSlider("sJump", {Text = "Прыжок", Default = 50, Min = 50, Max = 200, Rounding = 0}):OnChanged(function(v) Config.JumpPower = v end)
MR:AddSlider("sFlySpd", {Text = "Скорость полёта", Default = 50, Min = 10, Max = 200, Rounding = 0}):OnChanged(function(v) Config.FlySpeed = v end)
MR:AddSlider("sSpinSpd", {Text = "Скорость вращения", Default = 30, Min = 5, Max = 60, Rounding = 0}):OnChanged(function(v) Config.SpinSpeed = v end)

-- РАЗНОЕ
local MiscL = TabMisc:AddLeftGroupbox("Утилиты")
local MiscR = TabMisc:AddRightGroupbox("Сервер")

MiscL:AddToggle("tAFK", {Text = "Анти-АФК", Default = false}):OnChanged(function(v) State.antiAFKEnabled = v; toggleAntiAFK(v) end)
MiscL:AddButton("Респавн", function() if LocalPlayer.Character then LocalPlayer.Character:BreakJoints() end end)
MiscL:AddButton("Сбросить скорость", function()
    local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = 16; h.JumpPower = 50 end
    Lib:Notify("Сброшено!")
end)

MiscR:AddButton("Переподключиться", function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
MiscR:AddButton("Сменить сервер", function()
    pcall(function()
        local s = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
        for _, sv in pairs(s.data) do
            if sv.playing < sv.maxPlayers and sv.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, sv.id, LocalPlayer)
                break
            end
        end
    end)
end)
MiscR:AddButton("Копировать PlaceId", function() if setclipboard then setclipboard(tostring(game.PlaceId)); Lib:Notify("Скопировано!") end end)

-- ИГРОКИ
local PL = TabPlayers:AddLeftGroupbox("Список")
local PR = TabPlayers:AddRightGroupbox("Действия")

local selPlayer = nil
local pNames = {}

local function updList()
    pNames = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(pNames, p.Name) end
    end
    if Options and Options.dPlayers then Options.dPlayers:SetValues(pNames) end
end

PL:AddButton("Обновить", function() updList(); Lib:Notify("Обновлено!") end)
PL:AddDropdown("dPlayers", {Values = pNames, Text = "Игрок"}):OnChanged(function(v) selPlayer = Players:FindFirstChild(v) end)

PR:AddButton("Наблюдать", function()
    if selPlayer and selPlayer.Character then
        Camera.CameraSubject = selPlayer.Character:FindFirstChildOfClass("Humanoid")
        Lib:Notify("Наблюдаем: "..selPlayer.Name)
    end
end)
PR:AddButton("Перестать", function()
    if LocalPlayer.Character then Camera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid") end
end)
PR:AddButton("Телепорт", function()
    if selPlayer and selPlayer.Character and LocalPlayer.Character then
        local t = selPlayer.Character:FindFirstChild("HumanoidRootPart")
        local m = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if t and m then m.CFrame = t.CFrame * CFrame.new(0,0,3); Lib:Notify("ТП!") end
    end
end)
PR:AddButton("Копировать ник", function()
    if selPlayer and setclipboard then setclipboard(selPlayer.Name); Lib:Notify("Скопировано!") end
end)

Players.PlayerAdded:Connect(function() task.wait(1); updList() end)
Players.PlayerRemoving:Connect(function() task.wait(0.5); updList() end)
task.spawn(updList)

-- НАСТРОЙКИ
TM:SetLibrary(Lib)
SM:SetLibrary(Lib)
SM:SetFolder("CheatV31")
TM:SetFolder("CheatV31")
SM:BuildConfigSection(TabCfg)
TM:ApplyToTab(TabCfg)

local CfgG = TabCfg:AddLeftGroupbox("Управление")
CfgG:AddButton("Выгрузить", function() Lib:Unload(); fovCircle:Remove(); for _,l in pairs(tracers) do l:Remove() end end)

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
        Lib:SetWatermark(string.format("Cheat v3.1 | FPS: %d | Пинг: %dms", fps, ping))
        fps, lt = 0, tick()
    end
end)

Lib.KeybindFrame.Visible = true
SM:LoadAutoloadConfig()

StarterGui:SetCore("SendNotification", {Title = "Cheat", Text = "Загружен!", Duration = 3})
print("Cheat v3.1 загружен!")
