--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                    CHEAT UNIVERSAL v3.0                       ║
    ║              Максимум функций + Русский язык                  ║
    ╚═══════════════════════════════════════════════════════════════╝
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
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local PathfindingService = game:GetService("PathfindingService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Базовая защита
pcall(function()
    local mt = getrawmetatable(game)
    if mt and setreadonly then
        setreadonly(mt, false)
        local oldNamecall = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "Kick" then return wait(9e9) end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end
end)

StarterGui:SetCore("SendNotification", {Title = "Cheat v3", Text = "Загрузка...", Duration = 2})

-- СОСТОЯНИЕ
local State = {
    isAiming = false, currentTarget = nil, lastTargetHealth = nil,
    espEnabled = false, chamsEnabled = false, triggerbotEnabled = false,
    wallCheckDisabled = false, fullbrightEnabled = false, fovChangerEnabled = false,
    hitsoundsEnabled = false, lockpickerEnabled = false, lockpickerRunning = false,
    infiniteJumpEnabled = false, noclipEnabled = false, speedEnabled = false,
    flyEnabled = false, antiAFKEnabled = false, spinbotEnabled = false,
    hitboxExpanderEnabled = false, bhopping = false, aimbotEnabled = true,
    autoClickerEnabled = false, reachEnabled = false, antiVoidEnabled = false,
    freecamEnabled = false, xrayEnabled = false, tracersEnabled = false,
    autoFarmEnabled = false, autoParryEnabled = false, silentAimEnabled = false,
    camLockEnabled = false, autoShootEnabled = false, noRecoilEnabled = false,
    instantRespawnEnabled = false, autoCollectEnabled = false, magnetEnabled = false,
    autoEquipEnabled = false, godModeEnabled = false, invisEnabled = false,
    rainbowEnabled = false, nightVisionEnabled = false, thirdPersonEnabled = false,
    autoHealEnabled = false, autoReloadEnabled = false, noClipCamEnabled = false,
    autoJumpEnabled = false, antiSlowEnabled = false, moonJumpEnabled = false
}

-- КОНФИГ
local Config = {
    Smoothness = 80, FOVRadius = 200, Prediction = 0.1,
    ActivationKey = Enum.UserInputType.MouseButton2,
    TargetParts = {"Head", "UpperTorso"}, TeamCheck = false,
    ElasticEnabled = false, ElasticSpeed = 1.6,
    ESPColor = Color3.fromRGB(150, 150, 150),
    ChamsColor = Color3.fromRGB(150, 150, 150),
    ChamsTransparency = 0.5,
    SelectedHitsound = "rbxassetid://6916371803", HitsoundVolume = 5,
    FullbrightColor = Color3.new(1, 1, 1), AdditionalFOV = 10,
    Hitsounds = {
        Slime = "rbxassetid://6916371803", Fortnite = "rbxassetid://4804954860",
        Pan = "rbxassetid://7109756845", Minecraft = "rbxassetid://8766809464"
    },
    WalkSpeed = 16, JumpPower = 50, FlySpeed = 50, HitboxSize = 15,
    SpinSpeed = 50, ReachDistance = 20, ClickDelay = 0.1,
    TracerColor = Color3.fromRGB(150, 150, 150),
    CamLockPart = "Head", ThirdPersonDistance = 10, MoonJumpPower = 100,
    MagnetRange = 50, AutoHealThreshold = 50
}

-- FOV КРУГ
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.Color = Color3.fromRGB(150, 150, 150)
fovCircle.Transparency = 0.5
fovCircle.Filled = false
fovCircle.Radius = Config.FOVRadius
fovCircle.Visible = true

-- ТРЕЙСЕРЫ
local tracers = {}
local espObjects = {}
local highlights = {}

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
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if dist < closestDistance then closestDistance = dist; closestPart = part end
            end
        end
    end
    return closestPart
end

local function isVisible(player, targetPart)
    if State.wallCheckDisabled then return true end
    if not player.Character or not targetPart then return false end
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = Workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position), rayParams)
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
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist <= fovRadius and dist < closestDistance and isVisible(player, targetPart) then
                        closestDistance = dist; closestPlayer = player
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
    local velocity = hrp and hrp.AssemblyLinearVelocity or Vector3.zero
    return targetPart.Position + (velocity * predictionTime)
end

-- AIMBOT
local function aimAt(targetPosition)
    local screenPos = Camera:WorldToViewportPoint(targetPosition)
    local mousePos = UserInputService:GetMouseLocation()
    local deltaX = (screenPos.X - mousePos.X) * (Config.Smoothness / 100)
    local deltaY = (screenPos.Y - mousePos.Y) * (Config.Smoothness / 100)
    if Config.ElasticEnabled then deltaX, deltaY = deltaX * Config.ElasticSpeed, deltaY * Config.ElasticSpeed end
    if mousemoverel then mousemoverel(deltaX, deltaY) end
end

-- CAMERA LOCK
local function camLock()
    if not State.camLockEnabled then return end
    local target = getClosestPlayer(math.huge)
    if target and target.Character then
        local part = target.Character:FindFirstChild(Config.CamLockPart)
        if part then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
        end
    end
end

-- HITSOUNDS
local function playHitsound()
    if not State.hitsoundsEnabled then return end
    local sound = Instance.new("Sound")
    sound.Parent = SoundService
    sound.SoundId = Config.SelectedHitsound
    sound.Volume = Config.HitsoundVolume
    pcall(function() sound:Play() end)
    task.delay(2, function() if sound then sound:Destroy() end end)
end

-- ESP
local function createESP(player)
    if player == LocalPlayer or espObjects[player] then return end
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "CheatESP"
    billboard.Adornee = hrp
    billboard.Size = UDim2.new(4, 0, 6, 0)
    billboard.AlwaysOnTop = true
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    Instance.new("UIStroke", frame).Color = Config.ESPColor
    
    local nameTag = Instance.new("TextLabel", frame)
    nameTag.Size = UDim2.new(1, 0, 0.15, 0)
    nameTag.BackgroundTransparency = 1
    nameTag.TextScaled = true
    nameTag.Text = player.Name
    nameTag.TextColor3 = Config.ESPColor
    nameTag.Font = Enum.Font.SourceSansBold
    
    local distLabel = Instance.new("TextLabel", frame)
    distLabel.Size = UDim2.new(1, 0, 0.12, 0)
    distLabel.Position = UDim2.new(0, 0, 0.88, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.TextScaled = true
    distLabel.TextColor3 = Config.ESPColor
    distLabel.Font = Enum.Font.SourceSans
    
    frame.Parent = billboard
    billboard.Parent = hrp
    espObjects[player] = {billboard = billboard, distLabel = distLabel}
end

local function updateESP()
    for player, data in pairs(espObjects) do
        if data.distLabel and LocalPlayer.Character then
            local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local theirHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if myHRP and theirHRP then
                data.distLabel.Text = math.floor((myHRP.Position - theirHRP.Position).Magnitude) .. "m"
            end
        end
    end
    if not State.espEnabled then
        for _, data in pairs(espObjects) do if data.billboard then data.billboard:Destroy() end end
        espObjects = {}
        return
    end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then createESP(player) end
    end
end

-- CHAMS
local function setupChams(player)
    if player == LocalPlayer then return end
    local function onChar(character)
        if not State.chamsEnabled then return end
        if highlights[player] then highlights[player]:Destroy() end
        local hl = Instance.new("Highlight")
        hl.FillColor = Config.ChamsColor
        hl.OutlineColor = Config.ChamsColor
        hl.FillTransparency = Config.ChamsTransparency
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = character
        highlights[player] = hl
    end
    player.CharacterAdded:Connect(onChar)
    if player.Character then onChar(player.Character) end
end

-- TRACERS
local function updateTracers()
    for _, line in pairs(tracers) do line:Remove() end
    tracers = {}
    if not State.tracersEnabled then return end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local line = Drawing.new("Line")
                    line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    line.To = Vector2.new(screenPos.X, screenPos.Y)
                    line.Color = Config.TracerColor
                    line.Thickness = 1
                    line.Visible = true
                    table.insert(tracers, line)
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ФУНКЦИИ ДВИЖЕНИЯ
-- ═══════════════════════════════════════════════════════════════

-- INFINITE JUMP
UserInputService.JumpRequest:Connect(function()
    if State.infiniteJumpEnabled and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- MOON JUMP
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.Space and State.moonJumpEnabled then
        if LocalPlayer.Character then
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Velocity = Vector3.new(hrp.Velocity.X, Config.MoonJumpPower, hrp.Velocity.Z) end
        end
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
    elseif noclipConn then noclipConn:Disconnect() end
end

-- FLY
local flyConn, flyBV, flyBG
local function toggleFly(enabled)
    if enabled then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        flyBV = Instance.new("BodyVelocity", hrp)
        flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBG = Instance.new("BodyGyro", hrp)
        flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        flyBG.P = 9e4
        flyConn = RunService.RenderStepped:Connect(function()
            local moveDir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.yAxis end
            flyBV.Velocity = moveDir * Config.FlySpeed
            flyBG.CFrame = Camera.CFrame
        end)
    else
        if flyConn then flyConn:Disconnect() end
        if flyBV then flyBV:Destroy() end
        if flyBG then flyBG:Destroy() end
    end
end

-- SPEED
local function updateSpeed()
    if LocalPlayer.Character and State.speedEnabled then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
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
        antiAFKConn = LocalPlayer.Idled:Connect(function() vu:CaptureController(); vu:ClickButton2(Vector2.new()) end)
    elseif antiAFKConn then antiAFKConn:Disconnect() end
end

-- SPINBOT
local spinConn
local function toggleSpinbot(enabled)
    if enabled then
        spinConn = RunService.RenderStepped:Connect(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(Config.SpinSpeed), 0) end
        end)
    elseif spinConn then spinConn:Disconnect() end
end

-- BHOP
local bhopConn
local function toggleBhop(enabled)
    if enabled then
        bhopConn = RunService.RenderStepped:Connect(function()
            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    elseif bhopConn then bhopConn:Disconnect() end
end

-- ANTI VOID
local antiVoidConn, lastSafePos
local function toggleAntiVoid(enabled)
    if enabled then
        antiVoidConn = RunService.Heartbeat:Connect(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                if hrp.Position.Y > -50 then lastSafePos = hrp.CFrame
                elseif lastSafePos then hrp.CFrame = lastSafePos end
            end
        end)
    elseif antiVoidConn then antiVoidConn:Disconnect() end
end

-- FREECAM
local freecamConn, freecamPos
local function toggleFreecam(enabled)
    if enabled then
        freecamPos = Camera.CFrame
        freecamConn = RunService.RenderStepped:Connect(function()
            local moveDir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
            freecamPos = freecamPos + moveDir * 2
            Camera.CameraType = Enum.CameraType.Scriptable
            Camera.CFrame = freecamPos
        end)
    else
        if freecamConn then freecamConn:Disconnect() end
        Camera.CameraType = Enum.CameraType.Custom
    end
end

-- ANTI SLOW
local antiSlowConn
local function toggleAntiSlow(enabled)
    if enabled then
        antiSlowConn = RunService.Heartbeat:Connect(function()
            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.WalkSpeed < 16 then humanoid.WalkSpeed = 16 end
        end)
    elseif antiSlowConn then antiSlowConn:Disconnect() end
end

-- ═══════════════════════════════════════════════════════════════
-- БОЕВЫЕ ФУНКЦИИ
-- ═══════════════════════════════════════════════════════════════

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

-- AUTO CLICKER
local autoClickConn
local function toggleAutoClicker(enabled)
    if enabled then
        autoClickConn = task.spawn(function()
            while State.autoClickerEnabled do
                if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                    task.wait(Config.ClickDelay)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                end
                task.wait()
            end
        end)
    end
end

-- REACH
local reachConn
local function toggleReach(enabled)
    if enabled then
        reachConn = RunService.RenderStepped:Connect(function()
            if LocalPlayer.Character then
                for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
                    if tool:IsA("Tool") then
                        local handle = tool:FindFirstChild("Handle")
                        if handle then
                            handle.Size = Vector3.new(Config.ReachDistance, Config.ReachDistance, Config.ReachDistance)
                            handle.Massless = true
                            handle.Transparency = 1
                        end
                    end
                end
            end
        end)
    elseif reachConn then reachConn:Disconnect() end
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

-- AUTO SHOOT
local autoShootConn
local function toggleAutoShoot(enabled)
    if enabled then
        autoShootConn = RunService.RenderStepped:Connect(function()
            local target = getClosestPlayer(Config.FOVRadius)
            if target then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end
        end)
    elseif autoShootConn then autoShootConn:Disconnect() end
end

-- AUTO PARRY (для игр с парированием)
local autoParryConn
local function toggleAutoParry(enabled)
    if enabled then
        autoParryConn = RunService.Heartbeat:Connect(function()
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and myHRP then
                        local dist = (hrp.Position - myHRP.Position).Magnitude
                        if dist < 15 then
                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                            task.wait(0.1)
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                        end
                    end
                end
            end
        end)
    elseif autoParryConn then autoParryConn:Disconnect() end
end

-- LOCKPICKER
local function startLockpicker()
    if not State.lockpickerEnabled or State.lockpickerRunning then return end
    State.lockpickerRunning = true
    local currentBar = 1
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not State.lockpickerEnabled then conn:Disconnect(); State.lockpickerRunning = false; return end
        local gui = LocalPlayer.PlayerGui:FindFirstChild("LockpickGUI")
        if not gui then conn:Disconnect(); State.lockpickerRunning = false; return end
        local frames = gui:FindFirstChild("Frames", true)
        local line = gui:FindFirstChild("Line", true)
        if not frames or not line then return end
        local barFrame = frames:FindFirstChild("B" .. currentBar)
        if barFrame then
            local bar = barFrame:FindFirstChild("Bar")
            if bar and math.abs(bar.AbsolutePosition.Y - line.AbsolutePosition.Y) <= 8 then
                local pos = bar.AbsolutePosition + bar.AbsoluteSize / 2
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
                currentBar = currentBar % 3 + 1
            end
        end
    end)
end

task.spawn(function()
    while true do
        if State.lockpickerEnabled and not State.lockpickerRunning then
            if LocalPlayer.PlayerGui:FindFirstChild("LockpickGUI") then startLockpicker() end
        end
        task.wait(0.5)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- УТИЛИТЫ И ФАРМ
-- ═══════════════════════════════════════════════════════════════

-- X-RAY
local function toggleXray(enabled)
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not Players:GetPlayerFromCharacter(obj.Parent) then
            obj.LocalTransparencyModifier = enabled and 0.8 or 0
        end
    end
end

-- NIGHT VISION
local function toggleNightVision(enabled)
    if enabled then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
    else
        Lighting.Ambient = Color3.new(0, 0, 0)
        Lighting.Brightness = 1
    end
end

-- THIRD PERSON
local function toggleThirdPerson(enabled)
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.CameraOffset = enabled and Vector3.new(0, 0, -Config.ThirdPersonDistance) or Vector3.zero
        end
    end
end

-- AUTO COLLECT (собирает предметы рядом)
local autoCollectConn
local function toggleAutoCollect(enabled)
    if enabled then
        autoCollectConn = RunService.Heartbeat:Connect(function()
            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not myHRP then return end
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    local dist = (obj.Parent.Position - myHRP.Position).Magnitude
                    if dist < obj.MaxActivationDistance + 5 then
                        fireproximityprompt(obj)
                    end
                end
                if obj:IsA("ClickDetector") then
                    local part = obj.Parent
                    if part:IsA("BasePart") then
                        local dist = (part.Position - myHRP.Position).Magnitude
                        if dist < 15 then fireclickdetector(obj) end
                    end
                end
            end
        end)
    elseif autoCollectConn then autoCollectConn:Disconnect() end
end

-- MAGNET (притягивает предметы)
local magnetConn
local function toggleMagnet(enabled)
    if enabled then
        magnetConn = RunService.Heartbeat:Connect(function()
            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not myHRP then return end
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Tool") or (obj.Name:lower():find("coin") or obj.Name:lower():find("cash") or obj.Name:lower():find("drop")) then
                    if obj:IsA("BasePart") then
                        local dist = (obj.Position - myHRP.Position).Magnitude
                        if dist < Config.MagnetRange then
                            obj.CFrame = myHRP.CFrame
                        end
                    end
                end
            end
        end)
    elseif magnetConn then magnetConn:Disconnect() end
end

-- AUTO EQUIP
local function autoEquip()
    for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            tool.Parent = LocalPlayer.Character
            break
        end
    end
end

-- AUTO HEAL
local autoHealConn
local function toggleAutoHeal(enabled)
    if enabled then
        autoHealConn = RunService.Heartbeat:Connect(function()
            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health < Config.AutoHealThreshold then
                for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                    if tool.Name:lower():find("heal") or tool.Name:lower():find("medkit") or tool.Name:lower():find("bandage") then
                        tool.Parent = LocalPlayer.Character
                        task.wait(0.1)
                        if tool.Activate then tool:Activate() end
                    end
                end
            end
        end)
    elseif autoHealConn then autoHealConn:Disconnect() end
end

-- RAINBOW MODE
local rainbowConn
local function toggleRainbow(enabled)
    if enabled then
        rainbowConn = RunService.RenderStepped:Connect(function()
            local hue = tick() % 5 / 5
            local color = Color3.fromHSV(hue, 1, 1)
            fovCircle.Color = color
            Config.ESPColor = color
            Config.ChamsColor = color
            Config.TracerColor = color
        end)
    elseif rainbowConn then rainbowConn:Disconnect() end
end

-- INSTANT RESPAWN
local function setupInstantRespawn()
    LocalPlayer.CharacterAdded:Connect(function(char)
        if State.instantRespawnEnabled then
            char:WaitForChild("Humanoid").Died:Connect(function()
                task.wait(0.1)
                local respawn = ReplicatedStorage:FindFirstChild("Respawn") or ReplicatedStorage:FindFirstChild("RequestRespawn")
                if respawn then respawn:FireServer() end
            end)
        end
    end)
end
pcall(setupInstantRespawn)

-- ═══════════════════════════════════════════════════════════════
-- ВИЗУАЛЫ
-- ═══════════════════════════════════════════════════════════════

local originalFOV = Camera.FieldOfView
local function updateVisuals()
    if State.fullbrightEnabled then
        Lighting.Ambient = Config.FullbrightColor
        Lighting.OutdoorAmbient = Config.FullbrightColor
    end
    if State.fovChangerEnabled then Camera.FieldOfView = originalFOV + Config.AdditionalFOV end
end

local function updateFOVCircle()
    local mousePos = UserInputService:GetMouseLocation()
    fovCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
    fovCircle.Radius = Config.FOVRadius
end

-- INPUT
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.UserInputType == Config.ActivationKey then
        State.isAiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
    if not gpe and input.UserInputType == Config.ActivationKey then
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
    updateTracers()
    triggerFire()
    camLock()
    
    if State.hitboxExpanderEnabled then toggleHitboxExpander(true) end
    if State.thirdPersonEnabled then toggleThirdPerson(true) end
    
    if State.isAiming and State.aimbotEnabled then
        State.currentTarget = getClosestPlayer(Config.FOVRadius)
        if State.currentTarget then
            local humanoid = State.currentTarget.Character and State.currentTarget.Character:FindFirstChild("Humanoid")
            if humanoid then State.lastTargetHealth = humanoid.Health end
        end
        
        if State.currentTarget and isVisible(State.currentTarget, getClosestBodyPart(State.currentTarget)) then
            local predictedPos = predictPosition(State.currentTarget, Config.Prediction)
            if predictedPos then aimAt(predictedPos) end
            local humanoid = State.currentTarget.Character and State.currentTarget.Character:FindFirstChild("Humanoid")
            if humanoid and State.lastTargetHealth and humanoid.Health < State.lastTargetHealth then
                playHitsound()
                State.lastTargetHealth = humanoid.Health
            end
        end
    end
end)

-- INIT
for _, player in ipairs(Players:GetPlayers()) do setupChams(player) end
Players.PlayerAdded:Connect(setupChams)
Players.PlayerRemoving:Connect(function(player)
    if espObjects[player] then espObjects[player].billboard:Destroy(); espObjects[player] = nil end
    if highlights[player] then highlights[player]:Destroy(); highlights[player] = nil end
end)

-- ═══════════════════════════════════════════════════════════════
-- LINORIA UI
-- ═══════════════════════════════════════════════════════════════
local LinoriaURL = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"
local Library = loadstring(game:HttpGet(LinoriaURL .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(LinoriaURL .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(LinoriaURL .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Cheat Universal v3.0",
    Center = true, AutoShow = true, TabPadding = 8, MenuFadeTime = 0.2
})

local Tabs = {
    Visuals = Window:AddTab("Визуалы"),
    Combat = Window:AddTab("Боевые"),
    Movement = Window:AddTab("Движение"),
    Misc = Window:AddTab("Разное"),
    Farm = Window:AddTab("Фарм"),
    Players = Window:AddTab("Игроки"),
    Config = Window:AddTab("Настройки")
}

-- ВИЗУАЛЫ
local VL = Tabs.Visuals:AddLeftGroupbox("ESP")
local VR = Tabs.Visuals:AddRightGroupbox("Настройки")

VL:AddToggle("esp", {Text = "ESP (Обводка)", Default = false, Callback = function(v) State.espEnabled = v end})
VL:AddToggle("chams", {Text = "Chams (Подсветка)", Default = false, Callback = function(v) 
    State.chamsEnabled = v
    if v then for _, p in pairs(Players:GetPlayers()) do setupChams(p) end
    else for _, h in pairs(highlights) do h:Destroy() end; highlights = {} end
end})
VL:AddToggle("tracers", {Text = "Трейсеры", Default = false, Callback = function(v) State.tracersEnabled = v end})
VL:AddToggle("xray", {Text = "X-Ray", Default = false, Callback = function(v) State.xrayEnabled = v; toggleXray(v) end})
VL:AddToggle("fovCircle", {Text = "FOV круг", Default = true, Callback = function(v) fovCircle.Visible = v end})
VL:AddToggle("fullbright", {Text = "Fullbright", Default = false, Callback = function(v) State.fullbrightEnabled = v end})
VL:AddToggle("nightVision", {Text = "Ночное зрение", Default = false, Callback = function(v) State.nightVisionEnabled = v; toggleNightVision(v) end})
VL:AddToggle("noShadows", {Text = "Убрать тени", Default = false, Callback = function(v) Lighting.GlobalShadows = not v end})
VL:AddToggle("rainbow", {Text = "Радужный режим", Default = false, Callback = function(v) State.rainbowEnabled = v; toggleRainbow(v) end})
VL:AddToggle("fovChanger", {Text = "FOV камеры", Default = false, Callback = function(v) State.fovChangerEnabled = v end})
VL:AddSlider("fovAdd", {Text = "Доп. FOV", Default = 10, Min = 1, Max = 120, Rounding = 0, Callback = function(v) Config.AdditionalFOV = v end})
VL:AddToggle("thirdPerson", {Text = "Третье лицо", Default = false, Callback = function(v) State.thirdPersonEnabled = v; toggleThirdPerson(v) end})
VL:AddSlider("thirdDist", {Text = "Дистанция камеры", Default = 10, Min = 5, Max = 30, Rounding = 0, Callback = function(v) Config.ThirdPersonDistance = v end})

VR:AddLabel("Цвет ESP"):AddColorPicker("espCol", {Default = Color3.fromRGB(150, 150, 150), Callback = function(v) Config.ESPColor = v end})
VR:AddLabel("Цвет Chams"):AddColorPicker("chamsCol", {Default = Color3.fromRGB(150, 150, 150), Callback = function(v) Config.ChamsColor = v end})
VR:AddLabel("Цвет трейсеров"):AddColorPicker("tracerCol", {Default = Color3.fromRGB(150, 150, 150), Callback = function(v) Config.TracerColor = v end})
VR:AddLabel("Цвет FOV"):AddColorPicker("fovCol", {Default = Color3.fromRGB(150, 150, 150), Callback = function(v) fovCircle.Color = v end})
VR:AddSlider("chamsTransp", {Text = "Прозрачность Chams", Default = 0.5, Min = 0.01, Max = 1, Rounding = 2, Callback = function(v) Config.ChamsTransparency = v end})
VR:AddToggle("fpsBoost", {Text = "FPS Буст", Default = false, Callback = function(v)
    if v then
        Workspace.Terrain.WaterWaveSize = 0
        Lighting.FogEnd = 9e9
        settings().Rendering.QualityLevel = "Level01"
        for _, obj in pairs(game:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then obj.Enabled = false end
        end
    end
end})

-- БОЕВЫЕ
local CL = Tabs.Combat:AddLeftGroupbox("Аимбот")
local CR = Tabs.Combat:AddRightGroupbox("Дополнительно")

CL:AddToggle("aimbot", {Text = "Аимбот", Default = true, Callback = function(v) State.aimbotEnabled = v end})
CL:AddToggle("camLock", {Text = "Camera Lock", Default = false, Callback = function(v) State.camLockEnabled = v end})
CL:AddToggle("teamCheck", {Text = "Проверка команды", Default = false, Callback = function(v) Config.TeamCheck = v end})
CL:AddToggle("elastic", {Text = "Elastic", Default = false, Callback = function(v) Config.ElasticEnabled = v end})
CL:AddSlider("elasticSpd", {Text = "Скорость Elastic", Default = 1.6, Min = 0.5, Max = 3, Rounding = 1, Callback = function(v) Config.ElasticSpeed = v end})
CL:AddSlider("fovRad", {Text = "Радиус FOV", Default = 200, Min = 50, Max = 600, Rounding = 0, Callback = function(v) Config.FOVRadius = v end})
CL:AddSlider("smooth", {Text = "Плавность", Default = 80, Min = 1, Max = 200, Rounding = 0, Callback = function(v) Config.Smoothness = v end})
CL:AddSlider("pred", {Text = "Предикшн", Default = 0.1, Min = 0.01, Max = 1, Rounding = 2, Callback = function(v) Config.Prediction = v end})

CL:AddLabel("Триггербот"):AddKeyPicker("triggerKey", {Default = "K", Mode = "Toggle", Callback = function() 
    State.triggerbotEnabled = not State.triggerbotEnabled
    Library:Notify("Триггербот: " .. (State.triggerbotEnabled and "ВКЛ" or "ВЫКЛ"))
end})
CL:AddLabel("Игнор стен"):AddKeyPicker("wallKey", {Default = "J", Mode = "Toggle", Callback = function() 
    State.wallCheckDisabled = not State.wallCheckDisabled
    Library:Notify("Игнор стен: " .. (State.wallCheckDisabled and "ВКЛ" or "ВЫКЛ"))
end})

local keybinds = {"Q", "E", "R", "F", "MouseButton1", "MouseButton2"}
CL:AddDropdown("aimKey", {Values = keybinds, Default = "MouseButton2", Text = "Кнопка аима", Callback = function(v)
    for _, key in pairs(Enum.KeyCode:GetEnumItems()) do if key.Name == v then Config.ActivationKey = key; return end end
    for _, key in pairs(Enum.UserInputType:GetEnumItems()) do if key.Name == v then Config.ActivationKey = key; return end end
end})

local hitparts = {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm"}
CR:AddDropdown("hitparts", {Values = hitparts, Default = Config.TargetParts, Multi = true, Text = "Части тела", Callback = function(v)
    local parts = {}
    for name, enabled in pairs(v) do if enabled then table.insert(parts, name) end end
    Config.TargetParts = #parts > 0 and parts or {"Head"}
end})
Options.hitparts:SetValue({Head = true, UpperTorso = true})

local camParts = {"Head", "UpperTorso", "HumanoidRootPart"}
CR:AddDropdown("camPart", {Values = camParts, Default = "Head", Text = "Часть для CamLock", Callback = function(v) Config.CamLockPart = v end})

CR:AddToggle("hitsounds", {Text = "Хитсаунды", Default = false, Callback = function(v) State.hitsoundsEnabled = v end})
local sounds = {"Slime", "Fortnite", "Pan", "Minecraft"}
CR:AddDropdown("hitsound", {Values = sounds, Default = "Slime", Text = "Хитсаунд", Callback = function(v) Config.SelectedHitsound = Config.Hitsounds[v] end})
CR:AddSlider("hitsoundVol", {Text = "Громкость", Default = 5, Min = 1, Max = 10, Rounding = 0, Callback = function(v) Config.HitsoundVolume = v end})

CR:AddToggle("hitbox", {Text = "Расширить хитбоксы", Default = false, Callback = function(v) State.hitboxExpanderEnabled = v; if not v then toggleHitboxExpander(false) end end})
CR:AddSlider("hitboxSize", {Text = "Размер хитбокса", Default = 15, Min = 5, Max = 30, Rounding = 0, Callback = function(v) Config.HitboxSize = v end})
CR:AddToggle("reach", {Text = "Reach", Default = false, Callback = function(v) State.reachEnabled = v; toggleReach(v) end})
CR:AddSlider("reachDist", {Text = "Дистанция Reach", Default = 20, Min = 5, Max = 50, Rounding = 0, Callback = function(v) Config.ReachDistance = v end})
CR:AddToggle("autoClick", {Text = "Авто-кликер", Default = false, Callback = function(v) State.autoClickerEnabled = v; toggleAutoClicker(v) end})
CR:AddSlider("clickDelay", {Text = "Задержка клика", Default = 0.1, Min = 0.01, Max = 0.5, Rounding = 2, Callback = function(v) Config.ClickDelay = v end})
CR:AddToggle("autoShoot", {Text = "Авто-стрельба", Default = false, Callback = function(v) State.autoShootEnabled = v; toggleAutoShoot(v) end})
CR:AddToggle("autoParry", {Text = "Авто-парри", Default = false, Callback = function(v) State.autoParryEnabled = v; toggleAutoParry(v) end})
CR:AddToggle("lockpicker", {Text = "Авто-взлом замков", Default = false, Callback = function(v) State.lockpickerEnabled = v end})

-- ДВИЖЕНИЕ
local ML = Tabs.Movement:AddLeftGroupbox("Передвижение")
local MR = Tabs.Movement:AddRightGroupbox("Настройки")

ML:AddToggle("infJump", {Text = "Бесконечный прыжок", Default = false, Callback = function(v) State.infiniteJumpEnabled = v end})
ML:AddToggle("moonJump", {Text = "Moon Jump (Space)", Default = false, Callback = function(v) State.moonJumpEnabled = v end})
ML:AddToggle("noclip", {Text = "Ноклип", Default = false, Callback = function(v) State.noclipEnabled = v; toggleNoclip(v) end})
ML:AddToggle("fly", {Text = "Полёт (WASD+Space/Ctrl)", Default = false, Callback = function(v) State.flyEnabled = v; toggleFly(v) end})
ML:AddToggle("speed", {Text = "Спидхак", Default = false, Callback = function(v) State.speedEnabled = v end})
ML:AddToggle("bhop", {Text = "Банихоп", Default = false, Callback = function(v) State.bhopping = v; toggleBhop(v) end})
ML:AddToggle("spinbot", {Text = "Спинбот", Default = false, Callback = function(v) State.spinbotEnabled = v; toggleSpinbot(v) end})
ML:AddToggle("freecam", {Text = "Свободная камера", Default = false, Callback = function(v) State.freecamEnabled = v; toggleFreecam(v) end})
ML:AddToggle("antiVoid", {Text = "Анти-войд", Default = false, Callback = function(v) State.antiVoidEnabled = v; toggleAntiVoid(v) end})
ML:AddToggle("antiSlow", {Text = "Анти-замедление", Default = false, Callback = function(v) State.antiSlowEnabled = v; toggleAntiSlow(v) end})

MR:AddSlider("walkSpd", {Text = "Скорость ходьбы", Default = 16, Min = 16, Max = 500, Rounding = 0, Callback = function(v) Config.WalkSpeed = v end})
MR:AddSlider("jumpPwr", {Text = "Сила прыжка", Default = 50, Min = 50, Max = 500, Rounding = 0, Callback = function(v) Config.JumpPower = v end})
MR:AddSlider("flySpd", {Text = "Скорость полёта", Default = 50, Min = 10, Max = 500, Rounding = 0, Callback = function(v) Config.FlySpeed = v end})
MR:AddSlider("spinSpd", {Text = "Скорость вращения", Default = 50, Min = 10, Max = 100, Rounding = 0, Callback = function(v) Config.SpinSpeed = v end})
MR:AddSlider("moonPwr", {Text = "Сила Moon Jump", Default = 100, Min = 50, Max = 300, Rounding = 0, Callback = function(v) Config.MoonJumpPower = v end})

-- РАЗНОЕ
local MiscL = Tabs.Misc:AddLeftGroupbox("Утилиты")
local MiscR = Tabs.Misc:AddRightGroupbox("Сервер")

MiscL:AddToggle("antiAFK", {Text = "Анти-АФК", Default = false, Callback = function(v) State.antiAFKEnabled = v; toggleAntiAFK(v) end})
MiscL:AddToggle("instantRespawn", {Text = "Мгновенный респавн", Default = false, Callback = function(v) State.instantRespawnEnabled = v end})
MiscL:AddButton("Респавн", function() if LocalPlayer.Character then LocalPlayer.Character:BreakJoints() end end)
MiscL:AddButton("Сбросить скорость", function()
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.WalkSpeed = 16; humanoid.JumpPower = 50 end
    Library:Notify("Скорость сброшена!")
end)
MiscL:AddButton("Экипировать оружие", autoEquip)

MiscR:AddButton("Переподключиться", function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
MiscR:AddButton("Сменить сервер", function()
    pcall(function()
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        for _, server in pairs(servers.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                break
            end
        end
    end)
end)
MiscR:AddButton("Копировать PlaceId", function() if setclipboard then setclipboard(tostring(game.PlaceId)); Library:Notify("Скопировано!") end end)
MiscR:AddButton("Копировать JobId", function() if setclipboard then setclipboard(game.JobId); Library:Notify("Скопировано!") end end)

-- ФАРМ
local FL = Tabs.Farm:AddLeftGroupbox("Авто-фарм")
local FR = Tabs.Farm:AddRightGroupbox("Настройки")

FL:AddToggle("autoCollect", {Text = "Авто-сбор предметов", Default = false, Callback = function(v) State.autoCollectEnabled = v; toggleAutoCollect(v) end})
FL:AddToggle("magnet", {Text = "Магнит предметов", Default = false, Callback = function(v) State.magnetEnabled = v; toggleMagnet(v) end})
FL:AddToggle("autoHeal", {Text = "Авто-лечение", Default = false, Callback = function(v) State.autoHealEnabled = v; toggleAutoHeal(v) end})
FL:AddToggle("autoEquip", {Text = "Авто-экипировка", Default = false, Callback = function(v) State.autoEquipEnabled = v end})

FR:AddSlider("magnetRange", {Text = "Радиус магнита", Default = 50, Min = 10, Max = 200, Rounding = 0, Callback = function(v) Config.MagnetRange = v end})
FR:AddSlider("healThreshold", {Text = "Порог лечения (HP)", Default = 50, Min = 10, Max = 90, Rounding = 0, Callback = function(v) Config.AutoHealThreshold = v end})

FL:AddButton("Собрать всё рядом", function()
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    local count = 0
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            pcall(function() fireproximityprompt(obj) end)
            count = count + 1
        end
    end
    Library:Notify("Собрано: " .. count .. " предметов")
end)

FL:AddButton("ТП к ближайшему дропу", function()
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    local closest, closestDist = nil, math.huge
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") or (obj:IsA("BasePart") and (obj.Name:lower():find("drop") or obj.Name:lower():find("loot"))) then
            local pos = obj:IsA("BasePart") and obj.Position or (obj.Handle and obj.Handle.Position)
            if pos then
                local dist = (pos - myHRP.Position).Magnitude
                if dist < closestDist then closestDist = dist; closest = pos end
            end
        end
    end
    if closest then myHRP.CFrame = CFrame.new(closest); Library:Notify("Телепорт!") end
end)

-- ИГРОКИ
local PL = Tabs.Players:AddLeftGroupbox("Список")
local PR = Tabs.Players:AddRightGroupbox("Действия")

local selectedPlayer = nil
local playerNames = {}

local function updatePlayerList()
    playerNames = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then table.insert(playerNames, player.Name) end
    end
    if Options and Options.playerSelect then Options.playerSelect:SetValues(playerNames) end
end

PL:AddButton("Обновить список", function() updatePlayerList(); Library:Notify("Обновлено! (" .. #playerNames .. ")") end)
PL:AddButton("Показать всех", function()
    local list = "Игроки:\n"
    for i, p in ipairs(Players:GetPlayers()) do list = list .. i .. ". " .. p.Name .. "\n" end
    Library:Notify(list, 10)
end)
PL:AddDropdown("playerSelect", {Values = playerNames, Default = nil, Text = "Выбрать игрока", Callback = function(v)
    selectedPlayer = Players:FindFirstChild(v)
    if selectedPlayer then Library:Notify("Выбран: " .. v) end
end})

PR:AddButton("Наблюдать", function()
    if selectedPlayer and selectedPlayer.Character then
        Camera.CameraSubject = selectedPlayer.Character:FindFirstChildOfClass("Humanoid")
        Library:Notify("Наблюдаем: " .. selectedPlayer.Name)
    end
end)
PR:AddButton("Перестать наблюдать", function()
    if LocalPlayer.Character then Camera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid") end
end)
PR:AddButton("Телепорт к игроку", function()
    if selectedPlayer and selectedPlayer.Character and LocalPlayer.Character then
        local t = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
        local m = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if t and m then m.CFrame = t.CFrame * CFrame.new(0, 0, 3); Library:Notify("Телепорт!") end
    end
end)
PR:AddButton("Копировать ник", function()
    if selectedPlayer and setclipboard then setclipboard(selectedPlayer.Name); Library:Notify("Скопировано!") end
end)
PR:AddButton("Инфо", function()
    if selectedPlayer then
        Library:Notify("Ник: " .. selectedPlayer.Name .. "\nID: " .. selectedPlayer.UserId .. "\nВозраст: " .. selectedPlayer.AccountAge .. " дней", 8)
    end
end)

Players.PlayerAdded:Connect(function() task.wait(1); updatePlayerList() end)
Players.PlayerRemoving:Connect(function() task.wait(0.5); updatePlayerList() end)
task.spawn(updatePlayerList)

-- НАСТРОЙКИ
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("CheatV3")
ThemeManager:SetFolder("CheatV3")
SaveManager:BuildConfigSection(Tabs.Config)
ThemeManager:ApplyToTab(Tabs.Config)

local CG = Tabs.Config:AddLeftGroupbox("Управление")
CG:AddButton("Выгрузить чит", function() 
    Library:Unload()
    fovCircle:Remove()
    for _, line in pairs(tracers) do line:Remove() end
end)
CG:AddButton("Скопировать loadstring", function()
    if setclipboard then
        setclipboard("loadstring(game:HttpGet('https://raw.githubusercontent.com/vadisha0811-cmd/cheat/main/cheat.lua'))()")
        Library:Notify("Скопировано!")
    end
end)

-- СЕРАЯ ТЕМА
Library.AccentColor = Color3.fromRGB(150, 150, 150)
Library.AccentColorDark = Color3.fromRGB(100, 100, 100)
Library.OutlineColor = Color3.fromRGB(150, 150, 150)
Library:UpdateColorsUsingRegistry()

-- WATERMARK
Library:SetWatermarkVisibility(true)
local fps, lastTick = 0, tick()
RunService.RenderStepped:Connect(function()
    fps = fps + 1
    if tick() - lastTick >= 1 then
        local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        Library:SetWatermark(string.format("Cheat v3 | FPS: %d | Пинг: %dms", fps, ping))
        fps, lastTick = 0, tick()
    end
end)

Library.KeybindFrame.Visible = true
Library:OnUnload(function() print("Cheat v3 выгружен!") end)
SaveManager:LoadAutoloadConfig()

StarterGui:SetCore("SendNotification", {Title = "Cheat v3", Text = "Загружен!", Duration = 5})
print("Cheat Universal v3.0 загружен!")
