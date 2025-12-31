--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                    CHEAT UNIVERSAL v2.0                       ║
    ║              Русская версия + Максимум функций                ║
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
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ОБХОД АНТИЧИТА
local function bypassAntiCheat()
    -- Спуфинг HWID
    if getgenv then getgenv().HWID = HttpService:GenerateGUID(false) end
    
    -- Обход детекта эксплоита
    local mt = getrawmetatable(game)
    if mt and setreadonly then
        setreadonly(mt, false)
        local oldNamecall = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            if method == "Kick" or method == "kick" then return wait(9e9) end
            if method == "FireServer" or method == "InvokeServer" then
                local remoteName = tostring(self)
                if remoteName:lower():find("ban") or remoteName:lower():find("kick") or 
                   remoteName:lower():find("detect") or remoteName:lower():find("anticheat") or
                   remoteName:lower():find("report") or remoteName:lower():find("exploit") then
                    return nil
                end
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end
    
    -- Блокировка кика
    local oldKick = LocalPlayer.Kick
    if hookfunction then
        hookfunction(oldKick, function() return wait(9e9) end)
    end
    
    -- Анти-телепорт на бан сервер
    local oldTeleport = TeleportService.Teleport
    if hookfunction then
        hookfunction(oldTeleport, function(self, placeId, ...)
            if placeId == 0 then return end
            return oldTeleport(self, placeId, ...)
        end)
    end
end

pcall(bypassAntiCheat)

StarterGui:SetCore("SendNotification", {Title = "Cheat v2", Text = "Загрузка...", Duration = 2})

-- СОСТОЯНИЕ
local State = {
    isAiming = false, currentTarget = nil, lastTargetHealth = nil, flickActive = false,
    lastUpdateTime = 0, targetUpdateInterval = 0.1, espEnabled = false, chamsEnabled = false,
    triggerbotEnabled = false, wallCheckDisabled = false, dynamicFOVEnabled = false,
    fullbrightEnabled = false, fovChangerEnabled = false, hitsoundsEnabled = false,
    lockpickerEnabled = false, lockpickerRunning = false, killSayEnabled = false,
    infiniteJumpEnabled = false, noclipEnabled = false, speedEnabled = false,
    flyEnabled = false, antiAFKEnabled = false, spinbotEnabled = false,
    hitboxExpanderEnabled = false, bhopping = false, aimbotEnabled = true,
    autoClickerEnabled = false, reachEnabled = false, antiVoidEnabled = false,
    freecamEnabled = false, xrayEnabled = false, tracersEnabled = false,
    nameTagsEnabled = false, skeletonESPEnabled = false, autoFarmEnabled = false,
    godModeEnabled = false, ragdollEnabled = false, chatSpamEnabled = false,
    antiKnockbackEnabled = false, autoRespawnEnabled = false
}

-- КОНФИГ
local Config = {
    Smoothness = 80, FOVRadius = 200, Prediction = 0.1,
    ActivationKey = Enum.UserInputType.MouseButton2,
    TargetParts = {"Head", "UpperTorso"}, TeamCheck = false,
    HumanizationEnabled = false, HumanizationSpeed = 0.19,
    RandomOffset = 1, DriftIntensity = 1, AimJitter = 0.3,
    ElasticEnabled = false, ElasticSpeed = 1.6,
    ESPColor = Color3.fromRGB(150, 150, 150),
    ChamsColor = Color3.fromRGB(150, 150, 150),
    ChamsTransparency = 0.5,
    SelectedHitsound = "rbxassetid://6916371803", HitsoundVolume = 5,
    FullbrightColor = Color3.new(1, 1, 1), AdditionalFOV = 10,
    KillSayMessages = {"GG EZ", "Удачи в следующий раз!", "Скилл иссуе!", "Слишком легко!"},
    Hitsounds = {
        Slime = "rbxassetid://6916371803", Fortnite = "rbxassetid://4804954860",
        Pan = "rbxassetid://7109756845", Quake = "rbxassetid://1455817260",
        Minecraft = "rbxassetid://8766809464", Rust = "rbxassetid://4764109000"
    },
    WalkSpeed = 16, JumpPower = 50, FlySpeed = 50, HitboxSize = 15,
    SpinSpeed = 50, ReachDistance = 20, ClickDelay = 0.1,
    TracerColor = Color3.fromRGB(150, 150, 150)
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

-- AIMBOT
local function aimAt(targetPosition)
    local screenPos = Camera:WorldToViewportPoint(targetPosition)
    local mousePos = UserInputService:GetMouseLocation()
    local deltaX = (screenPos.X - mousePos.X) * (Config.Smoothness / 100)
    local deltaY = (screenPos.Y - mousePos.Y) * (Config.Smoothness / 100)
    if Config.ElasticEnabled then
        deltaX, deltaY = deltaX * Config.ElasticSpeed, deltaY * Config.ElasticSpeed
    end
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
    delay(2, function() if sound then sound:Destroy() end end)
end

-- ESP
local espObjects = {}
local function createESP(player)
    if player == LocalPlayer then return end
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp or espObjects[player] then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "CheatESP"
    billboard.Adornee = hrp
    billboard.Size = UDim2.new(4, 0, 6, 0)
    billboard.AlwaysOnTop = true
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Config.ESPColor
    stroke.Parent = frame
    
    local nameTag = Instance.new("TextLabel")
    nameTag.Size = UDim2.new(1, 0, 0.15, 0)
    nameTag.BackgroundTransparency = 1
    nameTag.TextScaled = true
    nameTag.Text = player.Name
    nameTag.TextColor3 = Config.ESPColor
    nameTag.Font = Enum.Font.SourceSansBold
    nameTag.Parent = frame
    
    -- Дистанция
    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0.12, 0)
    distLabel.Position = UDim2.new(0, 0, 0.88, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.TextScaled = true
    distLabel.TextColor3 = Config.ESPColor
    distLabel.Font = Enum.Font.SourceSans
    distLabel.Parent = frame
    
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
                local dist = math.floor((myHRP.Position - theirHRP.Position).Magnitude)
                data.distLabel.Text = dist .. "m"
            end
        end
    end
    
    if not State.espEnabled then
        for player, data in pairs(espObjects) do
            if data.billboard then data.billboard:Destroy() end
        end
        espObjects = {}
        return
    end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then createESP(player) end
    end
end

-- CHAMS
local highlights = {}
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

-- ЖИРНЫЕ ФУНКЦИИ

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

-- AUTO CLICKER
local autoClickConn
local function toggleAutoClicker(enabled)
    if enabled then
        autoClickConn = RunService.RenderStepped:Connect(function()
            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(Config.ClickDelay)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end
        end)
    else
        if autoClickConn then autoClickConn:Disconnect() end
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
    else
        if reachConn then reachConn:Disconnect() end
    end
end

-- ANTI VOID
local antiVoidConn
local lastSafePos = nil
local function toggleAntiVoid(enabled)
    if enabled then
        antiVoidConn = RunService.Heartbeat:Connect(function()
            if LocalPlayer.Character then
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if hrp.Position.Y > -50 then
                        lastSafePos = hrp.CFrame
                    elseif lastSafePos then
                        hrp.CFrame = lastSafePos
                    end
                end
            end
        end)
    else
        if antiVoidConn then antiVoidConn:Disconnect() end
    end
end

-- FREECAM
local freecamConn
local freecamPos
local function toggleFreecam(enabled)
    if enabled then
        freecamPos = Camera.CFrame
        freecamConn = RunService.RenderStepped:Connect(function()
            local moveDir = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
            freecamPos = freecamPos + moveDir * 2
            Camera.CameraType = Enum.CameraType.Scriptable
            Camera.CFrame = freecamPos
        end)
    else
        if freecamConn then freecamConn:Disconnect() end
        Camera.CameraType = Enum.CameraType.Custom
    end
end

-- X-RAY
local function toggleXray(enabled)
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not Players:GetPlayerFromCharacter(obj.Parent) then
            if enabled then
                obj.LocalTransparencyModifier = 0.8
            else
                obj.LocalTransparencyModifier = 0
            end
        end
    end
end

-- ANTI KNOCKBACK
local antiKBConn
local function toggleAntiKnockback(enabled)
    if enabled then
        antiKBConn = RunService.Heartbeat:Connect(function()
            if LocalPlayer.Character then
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, hrp.AssemblyLinearVelocity.Y, hrp.AssemblyLinearVelocity.Z)
                end
            end
        end)
    else
        if antiKBConn then antiKBConn:Disconnect() end
    end
end

-- AUTO RESPAWN
local function setupAutoRespawn()
    LocalPlayer.CharacterAdded:Connect(function(char)
        if State.autoRespawnEnabled then
            char:WaitForChild("Humanoid").Died:Connect(function()
                task.wait(0.5)
                local respawnEvent = ReplicatedStorage:FindFirstChild("Respawn") or ReplicatedStorage:FindFirstChild("RequestRespawn")
                if respawnEvent then respawnEvent:FireServer() end
            end)
        end
    end)
end
pcall(setupAutoRespawn)

-- CHAT SPAM
local chatSpamConn
local function toggleChatSpam(enabled)
    if enabled then
        chatSpamConn = task.spawn(function()
            while State.chatSpamEnabled do
                local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                if chatEvents then
                    local sayRequest = chatEvents:FindFirstChild("SayMessageRequest")
                    if sayRequest then
                        sayRequest:FireServer("Cheat Universal v2 | discord.gg/cheat", "All")
                    end
                end
                task.wait(3)
            end
        end)
    end
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
local function startLockpicker()
    if not State.lockpickerEnabled or State.lockpickerRunning then return end
    State.lockpickerRunning = true
    local currentBar = 1
    local lockpickBars = {"B1", "B2", "B3"}
    
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not State.lockpickerEnabled then conn:Disconnect(); State.lockpickerRunning = false; return end
        local gui = LocalPlayer.PlayerGui:FindFirstChild("LockpickGUI")
        if not gui then conn:Disconnect(); State.lockpickerRunning = false; return end
        
        local frames = gui:FindFirstChild("Frames", true)
        local line = gui:FindFirstChild("Line", true)
        if not frames or not line then return end
        
        local barFrame = frames:FindFirstChild(lockpickBars[currentBar])
        if barFrame then
            local bar = barFrame:FindFirstChild("Bar")
            if bar and math.abs(bar.AbsolutePosition.Y - line.AbsolutePosition.Y) <= 8 then
                local pos = bar.AbsolutePosition + bar.AbsoluteSize / 2
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
                currentBar = currentBar + 1
                if currentBar > 3 then currentBar = 1 end
            end
        end
    end)
end

spawn(function()
    while true do
        if State.lockpickerEnabled and not State.lockpickerRunning then
            local gui = LocalPlayer.PlayerGui:FindFirstChild("LockpickGUI")
            if gui then startLockpicker() end
        end
        wait(0.5)
    end
end)

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
    updateTracers()
    triggerFire()
    
    if State.hitboxExpanderEnabled then toggleHitboxExpander(true) end
    
    if State.isAiming and State.aimbotEnabled then
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
            if humanoid and State.lastTargetHealth and humanoid.Health < State.lastTargetHealth then
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
Players.PlayerAdded:Connect(function(player) setupChams(player) end)
Players.PlayerRemoving:Connect(function(player)
    if espObjects[player] then espObjects[player].billboard:Destroy(); espObjects[player] = nil end
    if highlights[player] then highlights[player]:Destroy(); highlights[player] = nil end
end)

-- ═══════════════════════════════════════════════════════════════
-- LINORIA UI (СЕРАЯ ТЕМА + РУССКИЙ)
-- ═══════════════════════════════════════════════════════════════
local LinoriaURL = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"
local Library = loadstring(game:HttpGet(LinoriaURL .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(LinoriaURL .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(LinoriaURL .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Cheat Universal v2.0",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Main = Window:AddTab("Визуалы"),
    Combat = Window:AddTab("Боевые"),
    Movement = Window:AddTab("Движение"),
    Misc = Window:AddTab("Разное"),
    Players = Window:AddTab("Игроки"),
    Config = Window:AddTab("Настройки")
}

-- ВКЛАДКА ВИЗУАЛЫ
local VisLeft = Tabs.Main:AddLeftGroupbox("ESP")
local VisRight = Tabs.Main:AddRightGroupbox("Настройки")

VisLeft:AddToggle("espToggle", {Text = "ESP (Обводка)", Default = false, Callback = function(v) State.espEnabled = v end})
VisLeft:AddToggle("chamsToggle", {Text = "Chams (Подсветка)", Default = false, Callback = function(v) 
    State.chamsEnabled = v
    if v then for _, p in pairs(Players:GetPlayers()) do setupChams(p) end
    else for _, h in pairs(highlights) do h:Destroy() end; highlights = {} end
end})
VisLeft:AddToggle("tracersToggle", {Text = "Трейсеры (Линии)", Default = false, Callback = function(v) State.tracersEnabled = v end})
VisLeft:AddToggle("xrayToggle", {Text = "X-Ray (Прозрачность)", Default = false, Callback = function(v) State.xrayEnabled = v; toggleXray(v) end})
VisLeft:AddToggle("fovToggle", {Text = "Показать FOV круг", Default = true, Callback = function(v) fovCircle.Visible = v end})
VisLeft:AddToggle("fullbrightToggle", {Text = "Fullbright (Яркость)", Default = false, Callback = function(v) State.fullbrightEnabled = v end})
VisLeft:AddToggle("noShadows", {Text = "Убрать тени", Default = false, Callback = function(v) Lighting.GlobalShadows = not v end})
VisLeft:AddToggle("fovChanger", {Text = "Изменить FOV камеры", Default = false, Callback = function(v) State.fovChangerEnabled = v end})
VisLeft:AddSlider("fovSlider", {Text = "Доп. FOV камеры", Default = 10, Min = 1, Max = 120, Rounding = 0, Callback = function(v) Config.AdditionalFOV = v end})

VisRight:AddLabel("Цвет ESP"):AddColorPicker("espColor", {Default = Color3.fromRGB(150, 150, 150), Callback = function(v) Config.ESPColor = v end})
VisRight:AddLabel("Цвет Chams"):AddColorPicker("chamsColor", {Default = Color3.fromRGB(150, 150, 150), Callback = function(v) Config.ChamsColor = v end})
VisRight:AddLabel("Цвет трейсеров"):AddColorPicker("tracerColor", {Default = Color3.fromRGB(150, 150, 150), Callback = function(v) Config.TracerColor = v end})
VisRight:AddLabel("Цвет FOV"):AddColorPicker("fovColor", {Default = Color3.fromRGB(150, 150, 150), Callback = function(v) fovCircle.Color = v end})
VisRight:AddSlider("chamsTransp", {Text = "Прозрачность Chams", Default = 0.5, Min = 0.01, Max = 1, Rounding = 2, Callback = function(v) Config.ChamsTransparency = v end})

VisRight:AddToggle("fpsBoost", {Text = "FPS Буст", Default = false, Callback = function(v)
    if v then
        Workspace.Terrain.WaterWaveSize = 0
        Lighting.FogEnd = 9e9
        settings().Rendering.QualityLevel = "Level01"
        for _, obj in pairs(game:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then obj.Enabled = false end
        end
    end
end})

-- ВКЛАДКА БОЕВЫЕ
local CombatLeft = Tabs.Combat:AddLeftGroupbox("Аимбот")
local CombatRight = Tabs.Combat:AddRightGroupbox("Дополнительно")

CombatLeft:AddToggle("aimbotToggle", {Text = "Аимбот", Default = true, Callback = function(v) State.aimbotEnabled = v end})
CombatLeft:AddToggle("teamCheck", {Text = "Проверка команды", Default = false, Callback = function(v) Config.TeamCheck = v end})
CombatLeft:AddToggle("elastic", {Text = "Elastic (Резкий аим)", Default = false, Callback = function(v) Config.ElasticEnabled = v end})
CombatLeft:AddSlider("elasticSpeed", {Text = "Скорость Elastic", Default = 1.6, Min = 0.5, Max = 3, Rounding = 1, Callback = function(v) Config.ElasticSpeed = v end})
CombatLeft:AddSlider("fovRadius", {Text = "Радиус FOV", Default = 200, Min = 50, Max = 600, Rounding = 0, Callback = function(v) Config.FOVRadius = v end})
CombatLeft:AddSlider("smoothness", {Text = "Плавность", Default = 80, Min = 1, Max = 200, Rounding = 0, Callback = function(v) Config.Smoothness = v end})
CombatLeft:AddSlider("prediction", {Text = "Предикшн", Default = 0.1, Min = 0.01, Max = 1, Rounding = 2, Callback = function(v) Config.Prediction = v end})

CombatLeft:AddLabel("Триггербот"):AddKeyPicker("triggerKey", {Default = "K", Mode = "Toggle", Text = "Триггербот", Callback = function() 
    State.triggerbotEnabled = not State.triggerbotEnabled
    Library:Notify("Триггербот: " .. (State.triggerbotEnabled and "ВКЛ" or "ВЫКЛ"))
end})
CombatLeft:AddLabel("Сквозь стены"):AddKeyPicker("wallKey", {Default = "J", Mode = "Toggle", Text = "Игнор стен", Callback = function() 
    State.wallCheckDisabled = not State.wallCheckDisabled
    Library:Notify("Игнор стен: " .. (State.wallCheckDisabled and "ВКЛ" or "ВЫКЛ"))
end})

local keybindOptions = {"Q", "E", "R", "F", "MouseButton1", "MouseButton2"}
CombatLeft:AddDropdown("aimKey", {Values = keybindOptions, Default = "MouseButton2", Text = "Кнопка аима", Callback = function(v)
    for _, key in pairs(Enum.KeyCode:GetEnumItems()) do if key.Name == v then Config.ActivationKey = key; return end end
    for _, key in pairs(Enum.UserInputType:GetEnumItems()) do if key.Name == v then Config.ActivationKey = key; return end end
end})

local hitpartOptions = {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm"}
CombatRight:AddDropdown("hitparts", {Values = hitpartOptions, Default = Config.TargetParts, Multi = true, Text = "Части тела", Callback = function(v)
    local parts = {}
    for name, enabled in pairs(v) do if enabled then table.insert(parts, name) end end
    if #parts == 0 then parts = {"Head"} end
    Config.TargetParts = parts
end})
Options.hitparts:SetValue({Head = true, UpperTorso = true})

CombatRight:AddToggle("hitsounds", {Text = "Хитсаунды", Default = false, Callback = function(v) State.hitsoundsEnabled = v end})
local hitsoundNames = {"Slime", "Fortnite", "Pan", "Quake", "Minecraft", "Rust"}
CombatRight:AddDropdown("hitsoundSelect", {Values = hitsoundNames, Default = "Slime", Text = "Выбрать хитсаунд", Callback = function(v) Config.SelectedHitsound = Config.Hitsounds[v] end})
CombatRight:AddSlider("hitsoundVol", {Text = "Громкость", Default = 5, Min = 1, Max = 10, Rounding = 0, Callback = function(v) Config.HitsoundVolume = v end})

CombatRight:AddToggle("hitboxExp", {Text = "Расширить хитбоксы", Default = false, Callback = function(v) 
    State.hitboxExpanderEnabled = v
    if not v then toggleHitboxExpander(false) end
end})
CombatRight:AddSlider("hitboxSize", {Text = "Размер хитбокса", Default = 15, Min = 5, Max = 30, Rounding = 0, Callback = function(v) Config.HitboxSize = v end})

CombatRight:AddToggle("reachToggle", {Text = "Reach (Дальность удара)", Default = false, Callback = function(v) State.reachEnabled = v; toggleReach(v) end})
CombatRight:AddSlider("reachDist", {Text = "Дистанция Reach", Default = 20, Min = 5, Max = 50, Rounding = 0, Callback = function(v) Config.ReachDistance = v end})

CombatRight:AddToggle("autoClick", {Text = "Авто-кликер", Default = false, Callback = function(v) State.autoClickerEnabled = v; toggleAutoClicker(v) end})
CombatRight:AddSlider("clickDelay", {Text = "Задержка клика", Default = 0.1, Min = 0.01, Max = 0.5, Rounding = 2, Callback = function(v) Config.ClickDelay = v end})

CombatRight:AddToggle("lockpicker", {Text = "Авто-взлом замков", Default = false, Callback = function(v) State.lockpickerEnabled = v end})

-- ВКЛАДКА ДВИЖЕНИЕ
local MoveLeft = Tabs.Movement:AddLeftGroupbox("Передвижение")
local MoveRight = Tabs.Movement:AddRightGroupbox("Настройки")

MoveLeft:AddToggle("infJump", {Text = "Бесконечный прыжок", Default = false, Callback = function(v) State.infiniteJumpEnabled = v end})
MoveLeft:AddToggle("noclip", {Text = "Ноклип (сквозь стены)", Default = false, Callback = function(v) State.noclipEnabled = v; toggleNoclip(v) end})
MoveLeft:AddToggle("fly", {Text = "Полёт (WASD+Space/Ctrl)", Default = false, Callback = function(v) State.flyEnabled = v; toggleFly(v) end})
MoveLeft:AddToggle("speed", {Text = "Спидхак", Default = false, Callback = function(v) State.speedEnabled = v end})
MoveLeft:AddToggle("bhop", {Text = "Банихоп (автопрыжок)", Default = false, Callback = function(v) State.bhopping = v; toggleBhop(v) end})
MoveLeft:AddToggle("spinbot", {Text = "Спинбот (вращение)", Default = false, Callback = function(v) State.spinbotEnabled = v; toggleSpinbot(v) end})
MoveLeft:AddToggle("freecam", {Text = "Свободная камера", Default = false, Callback = function(v) State.freecamEnabled = v; toggleFreecam(v) end})
MoveLeft:AddToggle("antiVoid", {Text = "Анти-войд (анти-падение)", Default = false, Callback = function(v) State.antiVoidEnabled = v; toggleAntiVoid(v) end})

MoveRight:AddSlider("walkSpeed", {Text = "Скорость ходьбы", Default = 16, Min = 16, Max = 500, Rounding = 0, Callback = function(v) Config.WalkSpeed = v end})
MoveRight:AddSlider("jumpPower", {Text = "Сила прыжка", Default = 50, Min = 50, Max = 500, Rounding = 0, Callback = function(v) Config.JumpPower = v end})
MoveRight:AddSlider("flySpeed", {Text = "Скорость полёта", Default = 50, Min = 10, Max = 500, Rounding = 0, Callback = function(v) Config.FlySpeed = v end})
MoveRight:AddSlider("spinSpeed", {Text = "Скорость вращения", Default = 50, Min = 10, Max = 100, Rounding = 0, Callback = function(v) Config.SpinSpeed = v end})

-- ВКЛАДКА РАЗНОЕ
local MiscLeft = Tabs.Misc:AddLeftGroupbox("Утилиты")
local MiscRight = Tabs.Misc:AddRightGroupbox("Защита")

MiscLeft:AddToggle("antiAFK", {Text = "Анти-АФК", Default = false, Callback = function(v) State.antiAFKEnabled = v; toggleAntiAFK(v) end})
MiscLeft:AddToggle("autoRespawn", {Text = "Авто-респавн", Default = false, Callback = function(v) State.autoRespawnEnabled = v end})
MiscLeft:AddToggle("killSay", {Text = "Kill Say (сообщение)", Default = false, Callback = function(v) State.killSayEnabled = v end})
MiscLeft:AddToggle("chatSpam", {Text = "Спам в чат", Default = false, Callback = function(v) State.chatSpamEnabled = v; if v then toggleChatSpam(v) end end})

MiscLeft:AddButton("Респавн", function()
    local char = LocalPlayer.Character
    if char then char:BreakJoints() end
end)

MiscLeft:AddButton("Сбросить скорость", function()
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.WalkSpeed = 16; humanoid.JumpPower = 50 end
    end
    Library:Notify("Скорость сброшена!")
end)

MiscRight:AddToggle("antiKB", {Text = "Анти-откидывание", Default = false, Callback = function(v) State.antiKnockbackEnabled = v; toggleAntiKnockback(v) end})
MiscRight:AddLabel("Обход античита активен"):AddColorPicker("bypassColor", {Default = Color3.fromRGB(0, 255, 0)})
MiscRight:AddButton("Переподключиться", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)
MiscRight:AddButton("Сменить сервер", function()
    local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    for _, server in pairs(servers.data) do
        if server.playing < server.maxPlayers and server.id ~= game.JobId then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
            break
        end
    end
end)

-- ВКЛАДКА ИГРОКИ
local PlayersLeft = Tabs.Players:AddLeftGroupbox("Список")
local PlayersRight = Tabs.Players:AddRightGroupbox("Действия")

local selectedPlayer = nil
local playerNames = {}

local function updatePlayerList()
    playerNames = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then table.insert(playerNames, player.Name) end
    end
    if Options and Options.playerSelect then Options.playerSelect:SetValues(playerNames) end
end

PlayersLeft:AddButton("Обновить список", function()
    updatePlayerList()
    Library:Notify("Обновлено! (" .. #playerNames .. " игроков)")
end)

PlayersLeft:AddButton("Показать всех", function()
    local list = "Игроки:\n"
    for i, player in ipairs(Players:GetPlayers()) do
        list = list .. i .. ". " .. player.Name .. "\n"
    end
    Library:Notify(list, 10)
end)

PlayersLeft:AddDropdown("playerSelect", {
    Values = playerNames, Default = nil, Text = "Выбрать игрока",
    Callback = function(v)
        selectedPlayer = Players:FindFirstChild(v)
        if selectedPlayer then Library:Notify("Выбран: " .. v) end
    end
})

PlayersRight:AddButton("Наблюдать", function()
    if selectedPlayer and selectedPlayer.Character then
        Camera.CameraSubject = selectedPlayer.Character:FindFirstChildOfClass("Humanoid")
        Library:Notify("Наблюдаем: " .. selectedPlayer.Name)
    else Library:Notify("Игрок не выбран!") end
end)

PlayersRight:AddButton("Перестать наблюдать", function()
    if LocalPlayer.Character then
        Camera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        Library:Notify("Остановлено")
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
    if selectedPlayer and setclipboard then
        setclipboard(selectedPlayer.Name)
        Library:Notify("Скопировано: " .. selectedPlayer.Name)
    end
end)

PlayersRight:AddButton("Инфо об игроке", function()
    if selectedPlayer then
        local info = "Ник: " .. selectedPlayer.Name .. "\n"
        info = info .. "ID: " .. selectedPlayer.UserId .. "\n"
        info = info .. "Возраст: " .. selectedPlayer.AccountAge .. " дней"
        Library:Notify(info, 8)
    end
end)

PlayersRight:AddButton("Телепорт всех ко мне", function()
    Library:Notify("Требуются серверные права!")
end)

Players.PlayerAdded:Connect(function() task.wait(1); updatePlayerList() end)
Players.PlayerRemoving:Connect(function() task.wait(0.5); updatePlayerList() end)
task.spawn(updatePlayerList)

-- ВКЛАДКА НАСТРОЙКИ
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("CheatV2")
ThemeManager:SetFolder("CheatV2")
SaveManager:BuildConfigSection(Tabs.Config)
ThemeManager:ApplyToTab(Tabs.Config)

local ConfigGroup = Tabs.Config:AddLeftGroupbox("Управление")
ConfigGroup:AddButton("Выгрузить чит", function() 
    Library:Unload()
    fovCircle:Remove()
    for _, line in pairs(tracers) do line:Remove() end
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
        Library:SetWatermark(string.format("Cheat v2 | FPS: %d | Пинг: %dms", fps, ping))
        fps, lastTick = 0, tick()
    end
end)

Library.KeybindFrame.Visible = true
Library:OnUnload(function() print("Cheat v2 выгружен!") end)
SaveManager:LoadAutoloadConfig()

StarterGui:SetCore("SendNotification", {Title = "Cheat v2", Text = "Загружен! Обход античита активен.", Duration = 5})
print("Cheat Universal v2.0 загружен!")
