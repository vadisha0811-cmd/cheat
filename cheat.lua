--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                    CHEAT UNIVERSAL                            ║
    ║              Clean & Customizable Version                     ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    Usage: loadstring(game:HttpGet('YOUR_RAW_URL/cheat.lua'))()
]]

-- ═══════════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ═══════════════════════════════════════════════════════════════
-- NOTIFICATION
-- ═══════════════════════════════════════════════════════════════
StarterGui:SetCore("SendNotification", {
    Title = "Cheat Activated!",
    Text = "Clean Version Loaded",
    Duration = 5
})

-- ═══════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════
local State = {
    isAiming = false,
    currentTarget = nil,
    lastTargetHealth = nil,
    flickActive = false,
    lastUpdateTime = 0,
    targetUpdateInterval = 0.1,
    espEnabled = false,
    chamsEnabled = false,
    crateESPEnabled = false,
    inventoryViewerEnabled = false,
    triggerbotEnabled = false,
    wallCheckDisabled = false,
    dynamicFOVEnabled = false,
    fullbrightEnabled = false,
    fovChangerEnabled = false,
    hitsoundsEnabled = false,
    lockpickerEnabled = false,
    lockpickerRunning = false,
    killSayEnabled = false
}

-- ═══════════════════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════════════════
local Config = {
    Smoothness = 80,
    FOVRadius = 200,
    Prediction = 0.1,
    ActivationKey = Enum.UserInputType.MouseButton2,
    TargetParts = {"Head", "UpperTorso"},
    TeamCheck = false,
    HumanizationEnabled = false,
    HumanizationSpeed = 0.19,
    RandomOffset = 1,
    DriftIntensity = 1,
    AimJitter = 0.3,
    ElasticEnabled = false,
    ElasticSpeed = 1.6,
    ElasticCenterSpeed = 0.34,
    ElasticCorrection = 0.1,
    ESPOutlineColor = Color3.fromRGB(0, 255, 100),
    ESPGradientColor = Color3.fromRGB(0, 255, 100),
    ChamsColor = Color3.fromRGB(0, 255, 100),
    ChamsTransparency = 0.5,
    SelectedHitsound = "rbxassetid://6916371803",
    HitsoundVolume = 5,
    FullbrightColor = Color3.new(1, 1, 1),
    AdditionalFOV = 10,
    KillSayDelay = 1.5,
    KillSayThreshold = 20,
    KillSayMessages = {
        "GG EZ", "Better luck next time!", "Nice try!", "Get good!", 
        "Too easy!", "You tried...", "Skill issue!", "Outplayed!"
    },
    Hitsounds = {
        Slime = "rbxassetid://6916371803",
        Fortnite = "rbxassetid://4804954860",
        Pan = "rbxassetid://7109756845",
        Quake = "rbxassetid://1455817260",
        Boing = "rbxassetid://12222124",
        Neverlose = "rbxassetid://6607204501",
        Wood = "rbxassetid://9120903221",
        Minecraft = "rbxassetid://8766809464",
        Rust = "rbxassetid://4764109000"
    }
}

-- ═══════════════════════════════════════════════════════════════
-- FOV CIRCLE
-- ═══════════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════════
-- UTILITIES
-- ═══════════════════════════════════════════════════════════════
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
                if distance < closestDistance then
                    closestDistance = distance
                    closestPart = part
                end
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
                        closestDistance = distance
                        closestPlayer = player
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

-- ═══════════════════════════════════════════════════════════════
-- HUMANIZATION & ELASTIC
-- ═══════════════════════════════════════════════════════════════
local function applyHumanization(deltaX, deltaY, distance)
    if not Config.HumanizationEnabled then return deltaX, deltaY end
    deltaX = deltaX + math.random(-Config.RandomOffset, Config.RandomOffset)
    deltaY = deltaY + math.random(-Config.RandomOffset, Config.RandomOffset)
    local shakeX = math.sin(tick() * 5) * Config.DriftIntensity
    local shakeY = math.cos(tick() * 5) * Config.DriftIntensity
    deltaX, deltaY = deltaX + shakeX, deltaY + shakeY
    deltaX = deltaX + (deltaX * Config.AimJitter * math.random(-1, 1))
    deltaY = deltaY + (deltaY * Config.AimJitter * math.random(-1, 1))
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
        deltaX, deltaY = deltaX - (deltaX * Config.ElasticCorrection), deltaY - (deltaY * Config.ElasticCorrection)
    end
    return deltaX, deltaY
end

-- ═══════════════════════════════════════════════════════════════
-- AIMBOT
-- ═══════════════════════════════════════════════════════════════
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

local function updateDynamicFOV()
    if not State.dynamicFOVEnabled then return end
    local target = getClosestPlayer(math.huge)
    if target and target.Character then
        local distance = (Camera.CFrame.Position - target.Character:GetModelCFrame().Position).Magnitude
        Config.FOVRadius = math.clamp(600 - (((distance - 1) / 39) * 560), 40, 600)
        fovCircle.Radius = Config.FOVRadius
    end
end

-- ═══════════════════════════════════════════════════════════════
-- HITSOUNDS
-- ═══════════════════════════════════════════════════════════════
local function playHitsound()
    if not State.hitsoundsEnabled then return end
    local sound = Instance.new("Sound")
    sound.Parent = SoundService
    sound.SoundId = Config.SelectedHitsound
    sound.Volume = Config.HitsoundVolume
    pcall(function() sound:Play() end)
    delay(2, function() if sound and sound.Parent then sound:Destroy() end end)
end

-- ═══════════════════════════════════════════════════════════════
-- ESP
-- ═══════════════════════════════════════════════════════════════
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
    billboard.StudsOffset = Vector3.new(0, 0, 0)
    billboard.AlwaysOnTop = true
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.BorderSizePixel = 0
    
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Config.ESPOutlineColor
    stroke.Parent = mainFrame
    
    local boxImage = Instance.new("ImageLabel")
    boxImage.Size = UDim2.new(1, 0, 1, 0)
    boxImage.BackgroundTransparency = 1
    boxImage.Image = "rbxassetid://1448806388"
    boxImage.ImageColor3 = Config.ESPGradientColor
    boxImage.Parent = mainFrame
    
    local healthBg = Instance.new("Frame")
    healthBg.Name = "HealthBarBg"
    healthBg.Size = UDim2.new(0.05, 0, 1, 0)
    healthBg.Position = UDim2.new(0, 0, 0.5, 0)
    healthBg.AnchorPoint = Vector2.new(0, 0.5)
    healthBg.BackgroundColor3 = Color3.fromRGB(159, 0, 0)
    healthBg.BorderSizePixel = 0
    Instance.new("UICorner", healthBg).CornerRadius = UDim.new(1, 0)
    
    local healthFill = Instance.new("Frame")
    healthFill.Name = "HealthFill"
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.Position = UDim2.new(0, 0, 1, 0)
    healthFill.AnchorPoint = Vector2.new(0, 1)
    healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthFill.BorderSizePixel = 0
    Instance.new("UICorner", healthFill).CornerRadius = UDim.new(1, 0)
    healthFill.Parent = healthBg
    healthBg.Parent = mainFrame
    
    humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        local percent = humanoid.Health / humanoid.MaxHealth
        healthFill.Size = UDim2.new(1, 0, percent, 0)
        healthFill.BackgroundColor3 = Color3.new(1 - percent, percent, 0)
    end)
    
    local nameTag = Instance.new("TextLabel")
    nameTag.Name = "PlayerNameTag"
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
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            createESP(player)
        else
            removeESP(player)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- CHAMS
-- ═══════════════════════════════════════════════════════════════
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
        character.Destroying:Connect(function()
            if highlights[player] then highlights[player]:Destroy(); highlights[player] = nil end
        end)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
    if player.Character then onCharacterAdded(player.Character) end
end

-- ═══════════════════════════════════════════════════════════════
-- TRIGGERBOT
-- ═══════════════════════════════════════════════════════════════
local function isTargetingEnemy()
    local target = Mouse.Target
    if target and target.Parent then
        local player = Players:GetPlayerFromCharacter(target.Parent)
        if player and player ~= LocalPlayer then return true end
    end
    return false
end

local function triggerFire()
    if State.triggerbotEnabled and isTargetingEnemy() then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- LOCKPICKER
-- ═══════════════════════════════════════════════════════════════
local lockpickBars = {"B1", "B2", "B3"}

local function findLockpickGUI()
    local gui = LocalPlayer.PlayerGui:FindFirstChild("LockpickGUI")
    if not gui then return nil end
    return {
        Frames = gui:FindFirstChild("Frames", true),
        Line = gui:FindFirstChild("Line", true)
    }
end

local function clickElement(element)
    if element then
        local pos, size = element.AbsolutePosition, element.AbsoluteSize
        local center = Vector2.new(pos.X + size.X / 2, pos.Y + size.Y / 2)
        VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
        VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
    end
end

local function startLockpicker()
    if not State.lockpickerEnabled or State.lockpickerRunning then return end
    State.lockpickerRunning = true
    local currentBar, lastClickTime = 1, 0
    
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not State.lockpickerEnabled then conn:Disconnect(); State.lockpickerRunning = false; return end
        local gui = findLockpickGUI()
        if not gui or not gui.Frames or not gui.Line then conn:Disconnect(); State.lockpickerRunning = false; return end
        
        local barName = lockpickBars[currentBar]
        if not barName then conn:Disconnect(); State.lockpickerRunning = false; return end
        
        local barFrame = gui.Frames:FindFirstChild(barName)
        if barFrame then
            local bar = barFrame:FindFirstChild("Bar")
            if bar then
                local yDiff = bar.AbsolutePosition.Y - gui.Line.AbsolutePosition.Y
                if math.abs(yDiff) <= 8 and (os.clock() - lastClickTime) > 0.02 then
                    clickElement(bar)
                    lastClickTime = os.clock()
                    currentBar = currentBar + 1
                end
            end
        end
        if currentBar > #lockpickBars then currentBar = 1 end
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

-- ═══════════════════════════════════════════════════════════════
-- KILL SAY
-- ═══════════════════════════════════════════════════════════════
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
-- VISUALS
-- ═══════════════════════════════════════════════════════════════
local originalFOV = Camera.FieldOfView

local function updateVisuals()
    if State.fullbrightEnabled then
        Lighting.Ambient = Config.FullbrightColor
        Lighting.OutdoorAmbient = Config.FullbrightColor
    end
    if State.fovChangerEnabled then
        Camera.FieldOfView = originalFOV + Config.AdditionalFOV
    else
        originalFOV = Camera.FieldOfView
    end
end

-- ═══════════════════════════════════════════════════════════════
-- INPUT HANDLING
-- ═══════════════════════════════════════════════════════════════
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
        State.lastTargetHealth = nil
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- MAIN LOOP
-- ═══════════════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    updateDynamicFOV()
    updateFOVCircle()
    updateESP()
    updateVisuals()
    triggerFire()
    
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

-- Initialize
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
-- LINORIA UI
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
    Main = Window:AddTab("Misc"),
    Combat = Window:AddTab("Combat"),
    Players = Window:AddTab("Players"),
    Config = Window:AddTab("Config")
}

-- MISC TAB
local MiscLeft = Tabs.Main:AddLeftGroupbox("Misc Features")
local MiscRight = Tabs.Main:AddRightGroupbox("Visual Settings")

MiscLeft:AddToggle("ESPEnabled", {Text = "Toggle ESP", Default = false, Callback = function(v) State.espEnabled = v end})
MiscLeft:AddToggle("toggleKillSay", {Text = "Kill Say", Default = false, Callback = function(v) State.killSayEnabled = v end})
MiscLeft:AddSlider("MessageKillDelay", {Text = "Kill Message Delay", Default = 1.5, Min = 0.5, Max = 5, Rounding = 1, Callback = function(v) Config.KillSayDelay = v end})
MiscLeft:AddToggle("FovCircleVisibility", {Text = "Toggle FOV Circle", Default = true, Callback = function(v) fovCircle.Visible = v end})
MiscLeft:AddToggle("chamsEnabled", {Text = "Enable Chams", Default = false, Callback = function(v) State.chamsEnabled = v end})
MiscLeft:AddToggle("hitsoundsEnabled", {Text = "Toggle Hitsounds", Default = false, Callback = function(v) State.hitsoundsEnabled = v end})
MiscLeft:AddToggle("enableAutoLockpicker", {Text = "Toggle Lockpicker", Default = false, Callback = function(v) State.lockpickerEnabled = v end})

local hitsoundNames = {"Slime", "Fortnite", "Pan", "Quake", "Boing", "Neverlose", "Wood", "Minecraft", "Rust"}
MiscLeft:AddDropdown("hitsoundSelected", {Values = hitsoundNames, Default = "Slime", Text = "Select Hitsound", Callback = function(v) Config.SelectedHitsound = Config.Hitsounds[v] or v end})
MiscLeft:AddInput("customHitsound", {Default = "", Numeric = false, Finished = true, Text = "Custom Hitsound", Placeholder = "rbxassetid://...", Callback = function(v)
    if v:match("^rbxassetid://%d+$") then
        local name = "Custom" .. tostring(#hitsoundNames + 1)
        Config.Hitsounds[name] = v
        table.insert(hitsoundNames, name)
        Options.hitsoundSelected:SetValues(hitsoundNames)
    end
end})
MiscLeft:AddToggle("enableFOVLock", {Text = "Enable FOV Changer", Default = false, Callback = function(v) State.fovChangerEnabled = v end})
MiscLeft:AddSlider("Field Of View", {Text = "Additional FOV", Default = 10, Min = 1, Max = 120, Rounding = 0, Callback = function(v) Config.AdditionalFOV = v end})

-- Visual Settings
MiscRight:AddLabel("FOV Circle Color"):AddColorPicker("fovCircleColor", {Default = Color3.fromRGB(0, 255, 100), Callback = function(v) fovCircle.Color = v end})
MiscRight:AddLabel("Chams Color"):AddColorPicker("colorForChams", {Default = Color3.fromRGB(0, 255, 100), Callback = function(v) Config.ChamsColor = v end})
MiscRight:AddToggle("enableLight", {Text = "Toggle Fullbright", Default = false, Callback = function(v) State.fullbrightEnabled = v end})
MiscRight:AddLabel("Lighting Color"):AddColorPicker("lightColor", {Default = Color3.new(1, 1, 1), Callback = function(v) Config.FullbrightColor = v end})
MiscRight:AddToggle("NoShadows", {Text = "Remove Shadows", Default = false, Callback = function(v) Lighting.GlobalShadows = not v end})
MiscRight:AddLabel("ESP Box Color"):AddColorPicker("boxColor", {Default = Color3.fromRGB(0, 255, 100), Callback = function(v) Config.ESPOutlineColor = v end})
MiscRight:AddSlider("chamsTransparency", {Text = "Chams Transparency", Default = 0.5, Min = 0.01, Max = 1, Rounding = 2, Callback = function(v) Config.ChamsTransparency = v end})
MiscRight:AddToggle("FpsBoost", {Text = "FPS Boost", Default = false, Callback = function(v)
    if v then
        local Terrain = Workspace.Terrain
        Terrain.WaterWaveSize, Terrain.WaterWaveSpeed, Terrain.WaterReflectance, Terrain.WaterTransparency = 0, 0, 0, 0
        Lighting.FogEnd, Lighting.Brightness = 9000000000, 0
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

-- COMBAT TAB
local CombatLeft = Tabs.Combat:AddLeftGroupbox("Aim Settings")
local CombatRight = Tabs.Combat:AddRightGroupbox("Advanced Settings")

CombatLeft:AddToggle("TeamCheck", {Text = "Team Check", Default = false, Callback = function(v) Config.TeamCheck = v end})
CombatLeft:AddToggle("DynamicFOV", {Text = "Dynamic FOV", Default = false, Callback = function(v) State.dynamicFOVEnabled = v end})
CombatLeft:AddToggle("Elastic", {Text = "Aim Assist (Elastic)", Default = false, Callback = function(v) Config.ElasticEnabled = v end})
CombatLeft:AddSlider("Aim Assist Speed", {Text = "Elastic Speed", Default = 1.6, Min = 0.01, Max = 2, Rounding = 2, Callback = function(v) Config.ElasticSpeed = v end})
CombatLeft:AddSlider("fov", {Text = "FOV Radius", Default = 200, Min = 1, Max = 600, Rounding = 0, Callback = function(v) Config.FOVRadius = v end})
CombatLeft:AddLabel("Triggerbot"):AddKeyPicker("enableTriggerBot", {Default = "K", Mode = "Toggle", Text = "Triggerbot", Callback = function() State.triggerbotEnabled = not State.triggerbotEnabled; Library:Notify("Triggerbot: " .. (State.triggerbotEnabled and "ON" or "OFF")) end})
CombatLeft:AddLabel("Wall Toggle"):AddKeyPicker("ignorewalls", {Default = "J", Mode = "Toggle", Text = "Ignore Walls", Callback = function() State.wallCheckDisabled = not State.wallCheckDisabled; Library:Notify("Ignore Walls: " .. (State.wallCheckDisabled and "ON" or "OFF")) end})
CombatLeft:AddSlider("sensitivity", {Text = "Smoothness", Default = 80, Min = 1, Max = 200, Rounding = 0, Callback = function(v) Config.Smoothness = v end})
CombatLeft:AddSlider("predictionFactor", {Text = "Prediction", Default = 0.1, Min = 0.01, Max = 2, Rounding = 2, Callback = function(v) Config.Prediction = v end})

-- Advanced Settings
CombatRight:AddLabel("Humanizer"):AddKeyPicker("humanizer", {Default = "V", Mode = "Toggle", Text = "Humanizer", Callback = function() Config.HumanizationEnabled = not Config.HumanizationEnabled; Library:Notify("Humanizer: " .. (Config.HumanizationEnabled and "ON" or "OFF")) end})
CombatRight:AddSlider("humanizerSpeed", {Text = "Humanizer Speed", Default = 0.19, Min = 0.01, Max = 5, Rounding = 2, Callback = function(v) Config.HumanizationSpeed = v end})
CombatRight:AddSlider("driftIntensity", {Text = "Drift Intensity", Default = 1, Min = 0.01, Max = 20, Rounding = 2, Callback = function(v) Config.DriftIntensity = v end})
CombatRight:AddSlider("overshootFactor", {Text = "Aim Jitter", Default = 0.3, Min = 0.01, Max = 20, Rounding = 2, Callback = function(v) Config.AimJitter = v end})

local hitpartOptions = {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg", "Torso"}
CombatRight:AddDropdown("HitpartDropdown", {Values = hitpartOptions, Default = Config.TargetParts, Multi = true, Text = "Select Hit Parts", Callback = function(v)
    local parts = {}
    for name, enabled in pairs(v) do if enabled then table.insert(parts, name) end end
    if #parts == 0 then parts = {"Head"} end
    Config.TargetParts = parts
end})
Options.HitpartDropdown:SetValue({Head = true, UpperTorso = true})

local keybindOptions = {"Q", "E", "R", "F", "G", "H", "J", "K", "MouseButton1", "MouseButton2", "MouseButton3"}
CombatLeft:AddDropdown("KeybindDropdown", {Values = keybindOptions, Default = "MouseButton2", Text = "Select Aim Key", Callback = function(v)
    for _, key in pairs(Enum.KeyCode:GetEnumItems()) do if key.Name == v then Config.ActivationKey = key; return end end
    for _, key in pairs(Enum.UserInputType:GetEnumItems()) do if key.Name == v then Config.ActivationKey = key; return end end
end})

-- ═══════════════════════════════════════════════════════════════
-- PLAYERS TAB
-- ═══════════════════════════════════════════════════════════════
local PlayersLeft = Tabs.Players:AddLeftGroupbox("Player List")
local PlayersRight = Tabs.Players:AddRightGroupbox("Player Actions")

local selectedPlayer = nil
local playerNames = {}

local function updatePlayerList()
    playerNames = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(playerNames, player.Name)
        end
    end
    if Options and Options.PlayerDropdown then
        Options.PlayerDropdown:SetValues(playerNames)
    end
end

PlayersLeft:AddButton("Refresh Player List", function()
    updatePlayerList()
    Library:Notify("Player list refreshed! (" .. #playerNames .. " players)")
end)

PlayersLeft:AddButton("Show All Players", function()
    local playerList = "Players on server:\n"
    for i, player in ipairs(Players:GetPlayers()) do
        local displayName = player.DisplayName ~= player.Name and " (" .. player.DisplayName .. ")" or ""
        playerList = playerList .. i .. ". " .. player.Name .. displayName .. "\n"
    end
    Library:Notify(playerList, 10)
end)

PlayersLeft:AddDropdown("PlayerDropdown", {
    Values = playerNames,
    Default = nil,
    Text = "Select Player",
    Callback = function(v)
        selectedPlayer = Players:FindFirstChild(v)
        if selectedPlayer then
            Library:Notify("Selected: " .. v)
        end
    end
})

PlayersRight:AddButton("Spectate Player", function()
    if selectedPlayer and selectedPlayer.Character then
        local hrp = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            Camera.CameraSubject = selectedPlayer.Character:FindFirstChildOfClass("Humanoid")
            Library:Notify("Spectating: " .. selectedPlayer.Name)
        end
    else
        Library:Notify("No player selected!")
    end
end)

PlayersRight:AddButton("Unspectate", function()
    if LocalPlayer.Character then
        Camera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        Library:Notify("Stopped spectating")
    end
end)

PlayersRight:AddButton("Teleport To Player", function()
    if selectedPlayer and selectedPlayer.Character and LocalPlayer.Character then
        local targetHRP = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetHRP and myHRP then
            myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
            Library:Notify("Teleported to: " .. selectedPlayer.Name)
        end
    else
        Library:Notify("No player selected or character not found!")
    end
end)

PlayersRight:AddButton("Copy Player Name", function()
    if selectedPlayer then
        if setclipboard then
            setclipboard(selectedPlayer.Name)
            Library:Notify("Copied: " .. selectedPlayer.Name)
        else
            Library:Notify("Clipboard not supported!")
        end
    else
        Library:Notify("No player selected!")
    end
end)

PlayersRight:AddButton("View Player Info", function()
    if selectedPlayer then
        local info = "Player Info:\n"
        info = info .. "Name: " .. selectedPlayer.Name .. "\n"
        info = info .. "Display: " .. selectedPlayer.DisplayName .. "\n"
        info = info .. "UserID: " .. selectedPlayer.UserId .. "\n"
        info = info .. "Account Age: " .. selectedPlayer.AccountAge .. " days\n"
        if selectedPlayer.Character then
            local humanoid = selectedPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                info = info .. "Health: " .. math.floor(humanoid.Health) .. "/" .. humanoid.MaxHealth
            end
        end
        Library:Notify(info, 8)
    else
        Library:Notify("No player selected!")
    end
end)

-- Auto-update player list
Players.PlayerAdded:Connect(function() task.wait(1); updatePlayerList() end)
Players.PlayerRemoving:Connect(function() task.wait(0.5); updatePlayerList() end)
task.spawn(updatePlayerList)

-- CONFIG TAB
local ConfigGroup = Tabs.Config:AddLeftGroupbox("Configuration")
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
SaveManager:SetFolder("Cheat")
ThemeManager:SetFolder("Cheat")
SaveManager:BuildConfigSection(Tabs.Config)
ThemeManager:ApplyToTab(Tabs.Config)
ConfigGroup:AddButton("Unload UI", function() Library:Unload(); fovCircle:Remove() end)

-- Set green theme
Library.AccentColor = Color3.fromRGB(0, 255, 100)
Library.AccentColorDark = Color3.fromRGB(0, 200, 80)
Library.OutlineColor = Color3.fromRGB(0, 255, 100)
Library:UpdateColorsUsingRegistry()

-- Watermark
Library:SetWatermarkVisibility(true)
local fps, lastTick = 0, tick()
RunService.RenderStepped:Connect(function()
    fps = fps + 1
    if tick() - lastTick >= 1 then
        local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        Library:SetWatermark(string.format("FPS: %d | Ping: %dms | Cheat", fps, ping))
        fps, lastTick = 0, tick()
    end
end)

Library.KeybindFrame.Visible = true
Library:OnUnload(function() print("Cheat unloaded!") end)
SaveManager:LoadAutoloadConfig()

print("Cheat Universal Loaded!")
