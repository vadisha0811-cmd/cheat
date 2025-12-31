--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                    CHEAT UNIVERSAL                            ║
    ║              Русская версия + Жирные функции                  ║
    ╚═══════════════════════════════════════════════════════════════╝
]]

-- СЕРВИСЫ
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

StarterGui:SetCore("SendNotification", {Title = "Cheat", Text = "Загрузка...", Duration = 3})

-- СОСТОЯНИЕ
local State = {
    isAiming = false, currentTarget = nil, lastTargetHealth = nil, flickActive = false,
    lastUpdateTime = 0, targetUpdateInterval = 0.1, espEnabled = false, chamsEnabled = false,
    triggerbotEnabled = false, wallCheckDisabled = false, dynamicFOVEnabled = false,
    fullbrightEnabled = false, fovChangerEnabled = false, hitsoundsEnabled = false,
    lockpickerEnabled = false, lockpickerRunning = false, killSayEnabled = false,
    infiniteJumpEnabled = false, noclipEnabled = false, speedEnabled = false,
    flyEnabled = false, antiAFKEnabled = false, noFallDamageEnabled = false,
    spinbotEnabled = false, fakelagEnabled = false, silentAimEnabled = false,
    autoParryEnabled = false, hitboxExpanderEnabled = false, ragdollEnabled = false,
    godModeEnabled = false, invisibleEnabled = false, bhopping = false
}

-- КОНФИГ
local Config = {
    Smoothness = 80, FOVRadius = 200, Prediction = 0.1,
    ActivationKey = Enum.UserInputType.MouseButton2,
    TargetParts = {"Head", "UpperTorso"}, TeamCheck = false,
    HumanizationEnabled = false, HumanizationSpeed = 0.19,
    RandomOffset = 1, DriftIntensity = 1, AimJitter = 0.3,
    ElasticEnabled = false, ElasticSpeed = 1.6, ElasticCenterSpeed = 0.34, ElasticCorrection = 0.1,
    ESPOutlineColor = Color3.fromRGB(0, 255, 100), ESPGradientColor = Color3.fromRGB(0, 255, 100),
    ChamsColor = Color3.fromRGB(0, 255, 100), ChamsTransparency = 0.5,
    SelectedHitsound = "rbxassetid://6916371803", HitsoundVolume = 5,
    FullbrightColor = Color3.new(1, 1, 1), AdditionalFOV = 10,
    KillSayDelay = 1.5, KillSayThreshold = 20,
    KillSayMessages = {"GG EZ", "Удачи в следующий раз!", "Попробуй ещё!", "Скилл иссуе!", "Слишком легко!"},
    Hitsounds = {
        Slime = "rbxassetid://6916371803", Fortnite = "rbxassetid://4804954860",
        Pan = "rbxassetid://7109756845", Quake = "rbxassetid://1455817260",
        Boing = "rbxassetid://12222124", Neverlose = "rbxassetid://6607204501",
        Wood = "rbxassetid://9120903221", Minecraft = "rbxassetid://8766809464", Rust = "rbxassetid://4764109000"
    },
    WalkSpeed = 16, JumpPower = 50, FlySpeed = 50, HitboxSize = 10, SpinSpeed = 50
}

-- FOV КРУГ
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.Color = Color3.fromRGB(0, 255, 100)
fovCircle.Transparency = 0.5
fovCircle.Filled = false
fovCircle.Radius = Config.FOVRadius
fovCircle.Visible = true

local function updateFOVCircle()
    local mousePos = UserInputService:GetMouseLocation()
    fovCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
    fovCircle.Radius = Config.FOVRadius
end

-- УТИЛИТЫ
local function isEnemy(player)
    if not Config.TeamCheck then return true end
    return player.Team ~= LocalPlayer.Team
end

local function getClosestBodyPart(player)
    if not player.Character then return nil end
    local closestPart, closestDistance = nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()
    for _, partName in pairs(Config.TargetParts) do
        local part = player.Character:FindFirstChild(partName)
        if part then
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if distance < closestDistance then closestDistance = distance; closestPart = part end
            end
        end
    end
    return closestPart
end

local function isVisible(player, targetPart)
    if State.wallCheckDisabled then return true end
    if not player.Character or not targetPart then return false end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = Workspace:Raycast(origin, direction * (targetPart.Position - origin).Magnitude, rayParams)
    return result == nil or result.Instance:IsDescendantOf(player.Character)
end

local function getClosestPlayer(fovRadius)
    local closestPlayer, closestDistance = nil, fovRadius
    local mousePos = UserInputService:GetMouseLocation()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isEnemy(player) and player.Character then
            local targetPart = getClosestBodyPart(player)
            if targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if distance <= fovRadius and distance < closestDistance and isVisible(player, targetPart) then
                        closestDistance = distance; closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function predictPosition(player, predictionTime)
    local targetPart = getClosestBodyPart(player)
    if not targetPart then return nil end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    local velocity = hrp and hrp.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
    return targetPart.Position + (velocity * predictionTime)
end

-- HUMANIZATION & ELASTIC
local function applyHumanization(deltaX, deltaY, distance)
    if not Config.HumanizationEnabled then return deltaX, deltaY end
    deltaX = deltaX + math.random(-Config.RandomOffset, Config.RandomOffset)
    deltaY = deltaY + math.random(-Config.RandomOffset, Config.RandomOffset)
    local shakeX = math.sin(tick() * 5) * Config.DriftIntensity
    local shakeY = math.cos(tick() * 5) * Config.DriftIntensity
    deltaX, deltaY = deltaX + shakeX, deltaY + shakeY
    local smoothFactor = math.clamp(1 / (distance / 500), 0.2, 1)
    return deltaX * Config.HumanizationSpeed * smoothFactor, deltaY * Config.HumanizationSpeed * smoothFactor
end

local function applyElastic(deltaX, deltaY)
    if not Config.ElasticEnabled then return deltaX, deltaY end
    if not State.flickActive then
        deltaX, deltaY = deltaX * Config.ElasticSpeed, deltaY * Config.ElasticSpeed
        State.flickActive = true
    else
        deltaX, deltaY = deltaX * Config.ElasticCenterSpeed, deltaY * Config.ElasticCenterSpeed
    end
    return deltaX, deltaY
end

-- AIMBOT
local function aimAt(targetPosition)
    local screenPos = Camera:WorldToViewportPoint(targetPosition)
    local mousePos = UserInputService:GetMouseLocation()
    local deltaX = (screenPos.X - mousePos.X) * (Config.Smoothness / 100)
    local deltaY = (screenPos.Y - mousePos.Y) * (Config.Smoothness / 100)
    local distance = (targetPosition - Camera.CFrame.Position).Magnitude
    deltaX, deltaY = applyElastic(deltaX, deltaY)
    deltaX, deltaY = applyHumanization(deltaX, deltaY, distance)
    if getfenv().mousemoverel then getfenv().mousemoverel(deltaX, deltaY) end
end

-- HITSOUNDS
local function playHitsound()
    if not State.hitsoundsEnabled then return end
    local sound = Instance.new("Sound")
    sound.Parent = SoundService
    sound.SoundId = Config.SelectedHitsound
    sound.Volume = Config.HitsoundVolume
    pcall(function() sound:Play() end)
    delay(2, function() if sound and sound.Parent then sound:Destroy() end end)
end

-- ESP
local function createESP(player)
    if player == LocalPlayer then return end
    if Config.TeamCheck and player.Team == LocalPlayer.Team then return end
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not hrp or not humanoid or hrp:FindFirstChild("PlayerESP") then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlayerESP"
    billboard.Adornee = hrp
    billboard.Size = UDim2.new(4, 0, 6, 0)
    billboard.AlwaysOnTop = true
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Config.ESPOutlineColor
    stroke.Parent = mainFrame
    
    local nameTag = Instance.new("TextLabel")
    nameTag.Size = UDim2.new(1, 0, 0.14, 0)
    nameTag.BackgroundTransparency = 1
    nameTag.TextScaled = true
    nameTag.Text = player.Name
    nameTag.TextColor3 = Config.ESPOutlineColor
    nameTag.Font = Enum.Font.SourceSansBold
    nameTag.Parent = mainFrame
    
    mainFrame.Parent = billboard
    billboard.Parent = hrp
end

local function removeESP(player)
    local character = player.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp and hrp:FindFirstChild("PlayerESP") then hrp.PlayerESP:Destroy() end
    end
end

local function updateESP()
    if not State.espEnabled then
        for _, player in pairs(Players:GetPlayers()) do removeESP(player) end
        return
    end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then createESP(player) else removeESP(player) end
    end
end

-- CHAMS
local highlights = {}
local function createHighlight(character)
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Config.ChamsColor
    highlight.OutlineColor = Config.ChamsColor:Lerp(Color3.new(0, 0, 0), 0.3)
    highlight.FillTransparency = Config.ChamsTransparency
    highlight.OutlineTransparency = Config.ChamsTransparency
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = character
    highlight.Parent = character
    return highlight
end

local function setupChams(player)
    if player == LocalPlayer then return end
    local function onCharacterAdded(character)
        if not State.chamsEnabled then return end
        if highlights[player] then highlights[player]:Destroy() end
        highlights[player] = createHighlight(character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
    if player.Character then onCharacterAdded(player.Character) end
end

-- TRIGGERBOT
local function triggerFire()
    if not State.triggerbotEnabled then return end
    local target = Mouse.Target
    if target and target.Parent then
        local player = Players:GetPlayerFromCharacter(target.Parent)
        if player and player ~= LocalPlayer then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end
    end
end

-- LOCKPICKER
local function findLockpickGUI()
    local gui = LocalPlayer.PlayerGui:FindFirstChild("LockpickGUI")
    if not gui then return nil end
    return {Frames = gui:FindFirstChild("Frames", true), Line = gui:FindFirstChild("Line", true)}
end

local function startLockpicker()
    if not State.lockpickerEnabled or State.lockpickerRunning then return end
    State.lockpickerRunning = true
    local currentBar, lastClickTime = 1, 0
    local lockpickBars = {"B1", "B2", "B3"}
    
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not State.lockpickerEnabled then conn:Disconnect(); State.lockpickerRunning = false; return end
        local gui = findLockpickGUI()
        if not gui or not gui.Frames or not gui.Line then conn:Disconnect(); State.lockpickerRunning = false; return end
        
        local barFrame = gui.Frames:FindFirstChild(lockpickBars[currentBar])
        if barFrame then
            local bar = barFrame:FindFirstChild("Bar")
            if bar then
                local yDiff = bar.AbsolutePosition.Y - gui.Line.AbsolutePosition.Y
                if math.abs(yDiff) <= 8 and (os.clock() - lastClickTime) > 0.02 then
                    local pos = bar.AbsolutePosition + bar.AbsoluteSize / 2
                    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
                    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
                    lastClickTime = os.clock()
                    currentBar = currentBar + 1
                end
            end
        end
        if currentBar > 3 then currentBar = 1 end
    end)
end

spawn(function()
    RunService.Heartbeat:Connect(function()
        if State.lockpickerEnabled and not State.lockpickerRunning and findLockpickGUI() then
            startLockpicker()
            repeat wait(0.5) until not findLockpickGUI()
            State.lockpickerRunning = false
        end
    end)
end)

-- KILL SAY
local function sendKillMessage()
    if not State.killSayEnabled then return end
    local message = Config.KillSayMessages[math.random(1, #Config.KillSayMessages)]
    local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if chatEvents then
        local sayRequest = chatEvents:FindFirstChild("SayMessageRequest")
        if sayRequest then sayRequest:FireServer(message, "All") end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ЖИРНЫЕ ФУНКЦИИ
-- ═══════════════════════════════════════════════════════════════

-- INFINITE JUMP
UserInputService.JumpRequest:Connect(function()
    if State.infiniteJumpEnabled and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- NOCLIP
local noclipConn
local function toggleNoclip(enabled)
    if enabled then
        noclipConn = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect() end
    end
end

-- FLY
local flyConn, flyBV, flyBG
local function toggleFly(enabled)
    if enabled then
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBV.Velocity = Vector3.new(0, 0, 0)
        flyBV.Parent = hrp
        
        flyBG = Instance.new("BodyGyro")
        flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        flyBG.P = 9e4
        flyBG.Parent = hrp
        
        flyConn = RunService.RenderStepped:Connect(function()
            local moveDir = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
            flyBV.Velocity = moveDir * Config.FlySpeed
            flyBG.CFrame = Camera.CFrame
        end)
    else
        if flyConn then flyConn:Disconnect() end
        if flyBV then flyBV:Destroy() end
        if flyBG then flyBG:Destroy() end
    end
end

-- SPEED HACK
local function updateSpeed()
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and State.speedEnabled then
            humanoid.WalkSpeed = Config.WalkSpeed
            humanoid.JumpPower = Config.JumpPower
        end
    end
end

-- ANTI-AFK
local antiAFKConn
local function toggleAntiAFK(enabled)
    if enabled then
        local vu = game:GetService("VirtualUser")
        antiAFKConn = LocalPlayer.Idled:Connect(function()
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
    else
        if antiAFKConn then antiAFKConn:Disconnect() end
    end
end

-- SPINBOT
local spinConn
local function toggleSpinbot(enabled)
    if enabled then
        spinConn = RunService.RenderStepped:Connect(function()
            if LocalPlayer.Character then
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(Config.SpinSpeed), 0) end
            end
        end)
    else
        if spinConn then spinConn:Disconnect() end
    end
end

-- HITBOX EXPANDER
local originalSizes = {}
local function toggleHitboxExpander(enabled)
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                if enabled then
                    if not originalSizes[player] then originalSizes[player] = hrp.Size end
                    hrp.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                    hrp.Transparency = 0.7
                else
                    if originalSizes[player] then hrp.Size = originalSizes[player] end
                    hrp.Transparency = 1
                end
            end
        end
    end
end

-- BHOP
local bhopConn
local function toggleBhop(enabled)
    if enabled then
        bhopConn = RunService.RenderStepped:Connect(function()
            if LocalPlayer.Character then
                local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
    else
        if bhopConn then bhopConn:Disconnect() end
    end
end

-- VISUALS
local originalFOV = Camera.FieldOfView
local function updateVisuals()
    if State.fullbrightEnabled then
        Lighting.Ambient = Config.FullbrightColor
        Lighting.OutdoorAmbient = Config.FullbrightColor
    end
    if State.fovChangerEnabled then
        Camera.FieldOfView = originalFOV + Config.AdditionalFOV
    end
end

-- INPUT
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.UserInputType == Config.ActivationKey then
        State.isAiming = true
        State.flickActive = false
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if not gameProcessed and input.UserInputType == Config.ActivationKey then
        State.isAiming = false
        State.currentTarget = nil
    end
end)

-- MAIN LOOP
RunService.RenderStepped:Connect(function()
    updateFOVCircle()
    updateESP()
    updateVisuals()
    updateSpeed()
    triggerFire()
    
    if State.hitboxExpanderEnabled then toggleHitboxExpander(true) end
    
    if State.isAiming then
        local now = tick()
        if (now - State.lastUpdateTime) >= State.targetUpdateInterval then
            State.lastUpdateTime = now
            State.currentTarget = getClosestPlayer(Config.FOVRadius)
            if State.currentTarget and State.currentTarget.Character then
                local humanoid = State.currentTarget.Character:FindFirstChild("Humanoid")
                if humanoid then State.lastTargetHealth = humanoid.Health end
            end
        end
        
        if State.currentTarget and isVisible(State.currentTarget, getClosestBodyPart(State.currentTarget)) then
            local predictedPos = predictPosition(State.currentTarget, Config.Prediction)
            if predictedPos then aimAt(predictedPos) end
            local humanoid = State.currentTarget.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health < State.lastTargetHealth then
                playHitsound()
                State.lastTargetHealth = humanoid.Health
            end
        else
            State.currentTarget = nil
        end
    end
end)

-- INIT
for _, player in ipairs(Players:GetPlayers()) do setupChams(player) end
Players.PlayerAdded:Connect(function(player)
    setupChams(player)
    player.CharacterAdded:Connect(function() if State.espEnabled then createESP(player) end end)
end)
Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
    if highlights[player] then highlights[player]:Destroy(); highlights[player] = nil end
end)

-- ═══════════════════════════════════════════════════════════════
-- LINORIA UI (РУССКИЙ)
-- ═══════════════════════════════════════════════════════════════
local LinoriaURL = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"
local Library = loadstring(game:HttpGet(LinoriaURL .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(LinoriaURL .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(LinoriaURL .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Cheat Universal",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2,
    AccentColor = Color3.fromRGB(0, 255, 100)
})

local Tabs = {
    Main = Window:AddTab("Разное"),
    Combat = Window:AddTab("Боевые"),
    Movement = Window:AddTab("Движение"),
    Players = Window:AddTab("Игроки"),
    Config = Window:AddTab("Настройки")
}

-- ВКЛАДКА РАЗНОЕ
local MiscLeft = Tabs.Main:AddLeftGroupbox("Визуалы")
local MiscRight = Tabs.Main:AddRightGroupbox("Настройки визуалов")

MiscLeft:AddToggle("ESPEnabled", {Text = "ESP (Обводка игроков)", Default = false, Callback = function(v) State.espEnabled = v end})
MiscLeft:AddToggle("chamsEnabled", {Text = "Chams (Подсветка)", Default = false, Callback = function(v) 
    State.chamsEnabled = v
    if v then for _, p in pairs(Players:GetPlayers()) do setupChams(p) end
    else for _, h in pairs(highlights) do h:Destroy() end; highlights = {} end
end})
MiscLeft:AddToggle("FovCircleVisibility", {Text = "Показать FOV круг", Default = true, Callback = function(v) fovCircle.Visible = v end})
MiscLeft:AddToggle("enableLight", {Text = "Fullbright (Яркость)", Default = false, Callback = function(v) State.fullbrightEnabled = v end})
MiscLeft:AddToggle("NoShadows", {Text = "Убрать тени", Default = false, Callback = function(v) Lighting.GlobalShadows = not v end})
MiscLeft:AddToggle("enableFOVLock", {Text = "Изменить FOV камеры", Default = false, Callback = function(v) State.fovChangerEnabled = v end})
MiscLeft:AddSlider("Field Of View", {Text = "Доп. FOV камеры", Default = 10, Min = 1, Max = 120, Rounding = 0, Callback = function(v) Config.AdditionalFOV = v end})

MiscRight:AddLabel("Цвет FOV круга"):AddColorPicker("fovCircleColor", {Default = Color3.fromRGB(0, 255, 100), Callback = function(v) fovCircle.Color = v end})
MiscRight:AddLabel("Цвет Chams"):AddColorPicker("colorForChams", {Default = Color3.fromRGB(0, 255, 100), Callback = function(v) Config.ChamsColor = v end})
MiscRight:AddLabel("Цвет освещения"):AddColorPicker("lightColor", {Default = Color3.new(1, 1, 1), Callback = function(v) Config.FullbrightColor = v end})
MiscRight:AddLabel("Цвет ESP"):AddColorPicker("boxColor", {Default = Color3.fromRGB(0, 255, 100), Callback = function(v) Config.ESPOutlineColor = v end})
MiscRight:AddSlider("chamsTransparency", {Text = "Прозрачность Chams", Default = 0.5, Min = 0.01, Max = 1, Rounding = 2, Callback = function(v) Config.ChamsTransparency = v end})

MiscRight:AddToggle("FpsBoost", {Text = "FPS Буст", Default = false, Callback = function(v)
    if v then
        local Terrain = Workspace.Terrain
        Terrain.WaterWaveSize, Terrain.WaterWaveSpeed, Terrain.WaterReflectance, Terrain.WaterTransparency = 0, 0, 0, 0
        Lighting.FogEnd, Lighting.Brightness = 9e9, 0
        settings().Rendering.QualityLevel = "Level01"
        for _, obj in pairs(game:GetDescendants()) do
            if obj:IsA("Part") or obj:IsA("MeshPart") then obj.Material = Enum.Material.Plastic; obj.Reflectance = 0
            elseif obj:IsA("Decal") then obj.Transparency = 1
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then obj.Lifetime = NumberRange.new(0) end
        end
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") or effect:IsA("BloomEffect") then effect.Enabled = false end
        end
    end
end})

-- ВКЛАДКА БОЕВЫЕ
local CombatLeft = Tabs.Combat:AddLeftGroupbox("Наведение")
local CombatRight = Tabs.Combat:AddRightGroupbox("Дополнительно")

CombatLeft:AddToggle("TeamCheck", {Text = "Проверка команды", Default = false, Callback = function(v) Config.TeamCheck = v end})
CombatLeft:AddToggle("DynamicFOV", {Text = "Динамический FOV", Default = false, Callback = function(v) State.dynamicFOVEnabled = v end})
CombatLeft:AddToggle("Elastic", {Text = "Аим ассист (Elastic)", Default = false, Callback = function(v) Config.ElasticEnabled = v end})
CombatLeft:AddSlider("Aim Assist Speed", {Text = "Скорость Elastic", Default = 1.6, Min = 0.01, Max = 2, Rounding = 2, Callback = function(v) Config.ElasticSpeed = v end})
CombatLeft:AddSlider("fov", {Text = "Радиус FOV", Default = 200, Min = 1, Max = 600, Rounding = 0, Callback = function(v) Config.FOVRadius = v end})
CombatLeft:AddSlider("sensitivity", {Text = "Плавность", Default = 80, Min = 1, Max = 200, Rounding = 0, Callback = function(v) Config.Smoothness = v end})
CombatLeft:AddSlider("predictionFactor", {Text = "Предикшн", Default = 0.1, Min = 0.01, Max = 2, Rounding = 2, Callback = function(v) Config.Prediction = v end})

CombatLeft:AddLabel("Триггербот"):AddKeyPicker("enableTriggerBot", {Default = "K", Mode = "Toggle", Text = "Триггербот", Callback = function() 
    State.triggerbotEnabled = not State.triggerbotEnabled
    Library:Notify("Триггербот: " .. (State.triggerbotEnabled and "ВКЛ" or "ВЫКЛ"))
end})
CombatLeft:AddLabel("Сквозь стены"):AddKeyPicker("ignorewalls", {Default = "J", Mode = "Toggle", Text = "Игнор стен", Callback = function() 
    State.wallCheckDisabled = not State.wallCheckDisabled
    Library:Notify("Игнор стен: " .. (State.wallCheckDisabled and "ВКЛ" or "ВЫКЛ"))
end})

CombatRight:AddToggle("hitsoundsEnabled", {Text = "Хитсаунды", Default = false, Callback = function(v) State.hitsoundsEnabled = v end})
local hitsoundNames = {"Slime", "Fortnite", "Pan", "Quake", "Boing", "Neverlose", "Wood", "Minecraft", "Rust"}
CombatRight:AddDropdown("hitsoundSelected", {Values = hitsoundNames, Default = "Slime", Text = "Выбрать хитсаунд", Callback = function(v) Config.SelectedHitsound = Config.Hitsounds[v] end})
CombatRight:AddSlider("hitsoundVol", {Text = "Громкость хитсаунда", Default = 5, Min = 0.1, Max = 10, Rounding = 1, Callback = function(v) Config.HitsoundVolume = v end})

CombatRight:AddToggle("toggleKillSay", {Text = "Kill Say (сообщение)", Default = false, Callback = function(v) State.killSayEnabled = v end})
CombatRight:AddToggle("enableAutoLockpicker", {Text = "Авто-взлом замков", Default = false, Callback = function(v) State.lockpickerEnabled = v end})

CombatRight:AddToggle("hitboxExpander", {Text = "Расширить хитбоксы", Default = false, Callback = function(v) 
    State.hitboxExpanderEnabled = v
    if not v then toggleHitboxExpander(false) end
end})
CombatRight:AddSlider("hitboxSize", {Text = "Размер хитбокса", Default = 10, Min = 5, Max = 30, Rounding = 0, Callback = function(v) Config.HitboxSize = v end})

CombatRight:AddLabel("Гуманизатор"):AddKeyPicker("humanizer", {Default = "V", Mode = "Toggle", Text = "Гуманизатор", Callback = function() 
    Config.HumanizationEnabled = not Config.HumanizationEnabled
    Library:Notify("Гуманизатор: " .. (Config.HumanizationEnabled and "ВКЛ" or "ВЫКЛ"))
end})
CombatRight:AddSlider("humanizerSpeed", {Text = "Скорость гуманизатора", Default = 0.19, Min = 0.01, Max = 5, Rounding = 2, Callback = function(v) Config.HumanizationSpeed = v end})

local hitpartOptions = {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm"}
CombatRight:AddDropdown("HitpartDropdown", {Values = hitpartOptions, Default = Config.TargetParts, Multi = true, Text = "Части тела", Callback = function(v)
    local parts = {}
    for name, enabled in pairs(v) do if enabled then table.insert(parts, name) end end
    if #parts == 0 then parts = {"Head"} end
    Config.TargetParts = parts
end})
Options.HitpartDropdown:SetValue({Head = true, UpperTorso = true})

local keybindOptions = {"Q", "E", "R", "F", "G", "MouseButton1", "MouseButton2", "MouseButton3"}
CombatLeft:AddDropdown("KeybindDropdown", {Values = keybindOptions, Default = "MouseButton2", Text = "Кнопка аима", Callback = function(v)
    for _, key in pairs(Enum.KeyCode:GetEnumItems()) do if key.Name == v then Config.ActivationKey = key; return end end
    for _, key in pairs(Enum.UserInputType:GetEnumItems()) do if key.Name == v then Config.ActivationKey = key; return end end
end})

-- ВКЛАДКА ДВИЖЕНИЕ
local MoveLeft = Tabs.Movement:AddLeftGroupbox("Передвижение")
local MoveRight = Tabs.Movement:AddRightGroupbox("Настройки")

MoveLeft:AddToggle("infiniteJump", {Text = "Бесконечный прыжок", Default = false, Callback = function(v) State.infiniteJumpEnabled = v end})
MoveLeft:AddToggle("noclip", {Text = "Ноклип (сквозь стены)", Default = false, Callback = function(v) State.noclipEnabled = v; toggleNoclip(v) end})
MoveLeft:AddToggle("fly", {Text = "Полёт", Default = false, Callback = function(v) State.flyEnabled = v; toggleFly(v) end})
MoveLeft:AddToggle("speed", {Text = "Спидхак", Default = false, Callback = function(v) State.speedEnabled = v end})
MoveLeft:AddToggle("bhop", {Text = "Банихоп (автопрыжок)", Default = false, Callback = function(v) State.bhopping = v; toggleBhop(v) end})
MoveLeft:AddToggle("spinbot", {Text = "Спинбот (вращение)", Default = false, Callback = function(v) State.spinbotEnabled = v; toggleSpinbot(v) end})
MoveLeft:AddToggle("antiAFK", {Text = "Анти-АФК", Default = false, Callback = function(v) State.antiAFKEnabled = v; toggleAntiAFK(v) end})

MoveRight:AddSlider("walkSpeed", {Text = "Скорость ходьбы", Default = 16, Min = 16, Max = 500, Rounding = 0, Callback = function(v) Config.WalkSpeed = v end})
MoveRight:AddSlider("jumpPower", {Text = "Сила прыжка", Default = 50, Min = 50, Max = 500, Rounding = 0, Callback = function(v) Config.JumpPower = v end})
MoveRight:AddSlider("flySpeed", {Text = "Скорость полёта", Default = 50, Min = 10, Max = 500, Rounding = 0, Callback = function(v) Config.FlySpeed = v end})
MoveRight:AddSlider("spinSpeed", {Text = "Скорость вращения", Default = 50, Min = 10, Max = 100, Rounding = 0, Callback = function(v) Config.SpinSpeed = v end})

-- ВКЛАДКА ИГРОКИ
local PlayersLeft = Tabs.Players:AddLeftGroupbox("Список игроков")
local PlayersRight = Tabs.Players:AddRightGroupbox("Действия")

local selectedPlayer = nil
local playerNames = {}

local function updatePlayerList()
    playerNames = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then table.insert(playerNames, player.Name) end
    end
    if Options and Options.PlayerDropdown then Options.PlayerDropdown:SetValues(playerNames) end
end

PlayersLeft:AddButton("Обновить список", function()
    updatePlayerList()
    Library:Notify("Список обновлён! (" .. #playerNames .. " игроков)")
end)

PlayersLeft:AddButton("Показать всех", function()
    local list = "Игроки на сервере:\n"
    for i, player in ipairs(Players:GetPlayers()) do
        list = list .. i .. ". " .. player.Name .. "\n"
    end
    Library:Notify(list, 10)
end)

PlayersLeft:AddDropdown("PlayerDropdown", {
    Values = playerNames, Default = nil, Text = "Выбрать игрока",
    Callback = function(v)
        selectedPlayer = Players:FindFirstChild(v)
        if selectedPlayer then Library:Notify("Выбран: " .. v) end
    end
})

PlayersRight:AddButton("Наблюдать", function()
    if selectedPlayer and selectedPlayer.Character then
        Camera.CameraSubject = selectedPlayer.Character:FindFirstChildOfClass("Humanoid")
        Library:Notify("Наблюдаем за: " .. selectedPlayer.Name)
    else Library:Notify("Игрок не выбран!") end
end)

PlayersRight:AddButton("Перестать наблюдать", function()
    if LocalPlayer.Character then
        Camera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        Library:Notify("Наблюдение остановлено")
    end
end)

PlayersRight:AddButton("Телепорт к игроку", function()
    if selectedPlayer and selectedPlayer.Character and LocalPlayer.Character then
        local targetHRP = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetHRP and myHRP then
            myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
            Library:Notify("Телепорт к: " .. selectedPlayer.Name)
        end
    else Library:Notify("Игрок не выбран!") end
end)

PlayersRight:AddButton("Копировать ник", function()
    if selectedPlayer then
        if setclipboard then setclipboard(selectedPlayer.Name); Library:Notify("Скопировано: " .. selectedPlayer.Name)
        else Library:Notify("Буфер обмена недоступен!") end
    else Library:Notify("Игрок не выбран!") end
end)

PlayersRight:AddButton("Инфо об игроке", function()
    if selectedPlayer then
        local info = "Информация:\n"
        info = info .. "Ник: " .. selectedPlayer.Name .. "\n"
        info = info .. "Дисплей: " .. selectedPlayer.DisplayName .. "\n"
        info = info .. "ID: " .. selectedPlayer.UserId .. "\n"
        info = info .. "Возраст акка: " .. selectedPlayer.AccountAge .. " дней\n"
        if selectedPlayer.Character then
            local humanoid = selectedPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then info = info .. "HP: " .. math.floor(humanoid.Health) .. "/" .. humanoid.MaxHealth end
        end
        Library:Notify(info, 8)
    else Library:Notify("Игрок не выбран!") end
end)

PlayersRight:AddButton("Телепорт всех ко мне", function()
    Library:Notify("Эта функция требует серверных прав!")
end)

Players.PlayerAdded:Connect(function() task.wait(1); updatePlayerList() end)
Players.PlayerRemoving:Connect(function() task.wait(0.5); updatePlayerList() end)
task.spawn(updatePlayerList)

-- ВКЛАДКА НАСТРОЙКИ
local ConfigGroup = Tabs.Config:AddLeftGroupbox("Конфигурация")
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
SaveManager:SetFolder("Cheat")
ThemeManager:SetFolder("Cheat")
SaveManager:BuildConfigSection(Tabs.Config)
ThemeManager:ApplyToTab(Tabs.Config)
ConfigGroup:AddButton("Выгрузить чит", function() Library:Unload(); fovCircle:Remove() end)

Library.AccentColor = Color3.fromRGB(0, 255, 100)
Library.AccentColorDark = Color3.fromRGB(0, 200, 80)
Library.OutlineColor = Color3.fromRGB(0, 255, 100)
Library:UpdateColorsUsingRegistry()

Library:SetWatermarkVisibility(true)
local fps, lastTick = 0, tick()
RunService.RenderStepped:Connect(function()
    fps = fps + 1
    if tick() - lastTick >= 1 then
        local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        Library:SetWatermark(string.format("FPS: %d | Пинг: %dms | Cheat", fps, ping))
        fps, lastTick = 0, tick()
    end
end)

Library.KeybindFrame.Visible = true
Library:OnUnload(function() print("Cheat выгружен!") end)
SaveManager:LoadAutoloadConfig()

StarterGui:SetCore("SendNotification", {Title = "Cheat", Text = "Успешно загружен!", Duration = 5})
print("Cheat Universal загружен!")
