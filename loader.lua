--[[
    CHEAT v6
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")

local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera
local Mouse = LP:GetMouse()

local S = {ESP=false,Chams=false,Tracers=false,Aimbot=true,Triggerbot=false,Fullbright=false,InfJump=false,Noclip=false,Fly=false,Speed=false,Bhop=false,Spin=false,AntiAFK=false,Hitbox=false,CamLock=false,Xray=false,Rainbow=false,FOVCircle=true}
local C = {FOV=200,Smooth=80,Pred=0.1,WalkSpd=16,JumpPwr=50,FlySpd=50,SpinSpd=30,HitboxSize=15,Color=Color3.fromRGB(150,150,150)}
local ESP_O,Chams_O,Tracers_L,Conns = {},{},{},{}
local isAiming,SelPlayer = false,nil

local FOV = Drawing.new("Circle")
FOV.Thickness=2 FOV.Color=C.Color FOV.Transparency=0.5 FOV.Radius=C.FOV FOV.Visible=true

local function GetTarget()
    local cl,d = nil,C.FOV
    local m = UserInputService:GetMouseLocation()
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            local h = p.Character:FindFirstChild("Head")
            if h then
                local pos,vis = Cam:WorldToViewportPoint(h.Position)
                if vis then
                    local dist = (Vector2.new(pos.X,pos.Y)-m).Magnitude
                    if dist<d then d=dist cl=p end
                end
            end
        end
    end
    return cl
end

local function Aim(pos)
    local scr = Cam:WorldToViewportPoint(pos)
    local m = UserInputService:GetMouseLocation()
    local dx,dy = (scr.X-m.X)*(C.Smooth/100),(scr.Y-m.Y)*(C.Smooth/100)
    if mousemoverel then mousemoverel(dx,dy) end
end

local function MkESP(p)
    if p==LP or ESP_O[p] then return end
    local c = p.Character if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart") if not hrp then return end
    local bb = Instance.new("BillboardGui") bb.Adornee=hrp bb.Size=UDim2.new(4,0,5,0) bb.AlwaysOnTop=true
    local fr = Instance.new("Frame",bb) fr.Size=UDim2.new(1,0,1,0) fr.BackgroundTransparency=1
    local st = Instance.new("UIStroke",fr) st.Color=C.Color st.Thickness=2
    local nm = Instance.new("TextLabel",fr) nm.Size=UDim2.new(1,0,0.2,0) nm.BackgroundTransparency=1 nm.Text=p.Name nm.TextColor3=C.Color nm.TextScaled=true nm.Font=Enum.Font.SourceSansBold
    bb.Parent=hrp ESP_O[p]=bb
end

local function RmESP(p) if ESP_O[p] then ESP_O[p]:Destroy() ESP_O[p]=nil end end

local function MkChams(p)
    if p==LP or Chams_O[p] then return end
    local c = p.Character if not c then return end
    local hl = Instance.new("Highlight") hl.FillColor=C.Color hl.OutlineColor=C.Color hl.FillTransparency=0.5 hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop hl.Parent=c
    Chams_O[p]=hl
end

local function RmChams(p) if Chams_O[p] then Chams_O[p]:Destroy() Chams_O[p]=nil end end

local function UpdTracers()
    for _,l in pairs(Tracers_L) do l:Remove() end Tracers_L={}
    if not S.Tracers then return end
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local pos,vis = Cam:WorldToViewportPoint(hrp.Position)
                if vis then
                    local ln = Drawing.new("Line") ln.From=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y) ln.To=Vector2.new(pos.X,pos.Y) ln.Color=C.Color ln.Thickness=1 ln.Visible=true
                    table.insert(Tracers_L,ln)
                end
            end
        end
    end
end

UserInputService.JumpRequest:Connect(function()
    if S.InfJump and LP.Character then
        local h = LP.Character:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

local function SetNoclip(on)
    if Conns.nc then Conns.nc:Disconnect() Conns.nc=nil end
    if on then Conns.nc = RunService.Stepped:Connect(function() if LP.Character then for _,p in pairs(LP.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end) end
end

local function SetFly(on)
    if Conns.fl then Conns.fl:Disconnect() Conns.fl=nil end
    if Conns.bv then Conns.bv:Destroy() Conns.bv=nil end
    if Conns.bg then Conns.bg:Destroy() Conns.bg=nil end
    if on then
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") if not hrp then return end
        Conns.bv = Instance.new("BodyVelocity",hrp) Conns.bv.MaxForce=Vector3.new(1e9,1e9,1e9)
        Conns.bg = Instance.new("BodyGyro",hrp) Conns.bg.MaxTorque=Vector3.new(1e9,1e9,1e9) Conns.bg.P=9e4
        Conns.fl = RunService.RenderStepped:Connect(function()
            local d = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then d=d+Cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then d=d-Cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then d=d-Cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then d=d+Cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then d=d+Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then d=d-Vector3.yAxis end
            Conns.bv.Velocity=d*C.FlySpd Conns.bg.CFrame=Cam.CFrame
        end)
    end
end

local function SetSpin(on) if Conns.sp then Conns.sp:Disconnect() Conns.sp=nil end if on then Conns.sp = RunService.RenderStepped:Connect(function() local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") if hrp then hrp.CFrame=hrp.CFrame*CFrame.Angles(0,math.rad(C.SpinSpd),0) end end) end end
local function SetBhop(on) if Conns.bh then Conns.bh:Disconnect() Conns.bh=nil end if on then Conns.bh = RunService.RenderStepped:Connect(function() local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") if h and h.FloorMaterial~=Enum.Material.Air then h:ChangeState(Enum.HumanoidStateType.Jumping) end end) end end
local function SetAFK(on) if Conns.af then Conns.af:Disconnect() Conns.af=nil end if on then local vu = game:GetService("VirtualUser") Conns.af = LP.Idled:Connect(function() vu:CaptureController() vu:ClickButton2(Vector2.new()) end) end end
local function SetHitbox(on) for _,p in pairs(Players:GetPlayers()) do if p~=LP and p.Character then local hrp = p.Character:FindFirstChild("HumanoidRootPart") if hrp then hrp.Size = on and Vector3.new(C.HitboxSize,C.HitboxSize,C.HitboxSize) or Vector3.new(2,2,1) hrp.Transparency = on and 0.7 or 1 end end end end
local function SetXray(on) for _,o in pairs(Workspace:GetDescendants()) do if o:IsA("BasePart") and not Players:GetPlayerFromCharacter(o.Parent) then o.LocalTransparencyModifier = on and 0.8 or 0 end end end
local function SetRainbow(on) if Conns.rb then Conns.rb:Disconnect() Conns.rb=nil end if on then Conns.rb = RunService.RenderStepped:Connect(function() C.Color = Color3.fromHSV(tick()%5/5,1,1) FOV.Color=C.Color end) end end

RunService.RenderStepped:Connect(function()
    local m = UserInputService:GetMouseLocation()
    FOV.Position = Vector2.new(m.X,m.Y) FOV.Radius=C.FOV FOV.Visible=S.FOVCircle
    if S.ESP then for _,p in pairs(Players:GetPlayers()) do if p~=LP and p.Character then MkESP(p) end end else for p in pairs(ESP_O) do RmESP(p) end end
    if S.Chams then for _,p in pairs(Players:GetPlayers()) do if p~=LP and p.Character then MkChams(p) end end else for p in pairs(Chams_O) do RmChams(p) end end
    UpdTracers()
    if S.Speed and LP.Character then local h = LP.Character:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed=C.WalkSpd h.JumpPower=C.JumpPwr end end
    if S.Hitbox then SetHitbox(true) end
    if S.Fullbright then Lighting.Ambient=Color3.new(1,1,1) Lighting.OutdoorAmbient=Color3.new(1,1,1) end
    if S.Triggerbot then local t = Mouse.Target if t and t.Parent then local p = Players:GetPlayerFromCharacter(t.Parent) if p and p~=LP then VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,0) VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,0) end end end
    if isAiming and S.Aimbot then local tgt = GetTarget() if tgt and tgt.Character then local head = tgt.Character:FindFirstChild("Head") if head then local hrp = tgt.Character:FindFirstChild("HumanoidRootPart") local vel = hrp and hrp.AssemblyLinearVelocity or Vector3.zero Aim(head.Position+vel*C.Pred) end end end
    if S.CamLock then local tgt = GetTarget() if tgt and tgt.Character then local head = tgt.Character:FindFirstChild("Head") if head then Cam.CFrame = CFrame.new(Cam.CFrame.Position,head.Position) end end end
end)

UserInputService.InputBegan:Connect(function(i,g) if not g and i.UserInputType==Enum.UserInputType.MouseButton2 then isAiming=true end end)
UserInputService.InputEnded:Connect(function(i,g) if not g and i.UserInputType==Enum.UserInputType.MouseButton2 then isAiming=false end end)
Players.PlayerRemoving:Connect(function(p) RmESP(p) RmChams(p) end)

local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local Win = Lib:CreateWindow({Title="Cheat v6",Center=true,AutoShow=true})

local T1,T2,T3,T4,T5 = Win:AddTab("Визуалы"),Win:AddTab("Боевые"),Win:AddTab("Движение"),Win:AddTab("Разное"),Win:AddTab("Игроки")

local G1L,G1R = T1:AddLeftGroupbox("ESP"),T1:AddRightGroupbox("Цвета")
G1L:AddToggle("a1",{Text="ESP",Default=false,Callback=function(v) S.ESP=v end})
G1L:AddToggle("a2",{Text="Chams",Default=false,Callback=function(v) S.Chams=v end})
G1L:AddToggle("a3",{Text="Трейсеры",Default=false,Callback=function(v) S.Tracers=v end})
G1L:AddToggle("a4",{Text="X-Ray",Default=false,Callback=function(v) S.Xray=v SetXray(v) end})
G1L:AddToggle("a5",{Text="FOV круг",Default=true,Callback=function(v) S.FOVCircle=v end})
G1L:AddToggle("a6",{Text="Fullbright",Default=false,Callback=function(v) S.Fullbright=v end})
G1L:AddToggle("a7",{Text="Убрать тени",Default=false,Callback=function(v) Lighting.GlobalShadows=not v end})
G1L:AddToggle("a8",{Text="Радуга",Default=false,Callback=function(v) S.Rainbow=v SetRainbow(v) end})
G1R:AddLabel("Цвет"):AddColorPicker("cp1",{Default=Color3.fromRGB(150,150,150),Callback=function(v) C.Color=v FOV.Color=v end})
G1R:AddToggle("a9",{Text="FPS Буст",Default=false,Callback=function(v) if v then Workspace.Terrain.WaterWaveSize=0 Lighting.FogEnd=9e9 settings().Rendering.QualityLevel="Level01" end end})

local G2L,G2R = T2:AddLeftGroupbox("Аимбот"),T2:AddRightGroupbox("Доп.")
G2L:AddToggle("b1",{Text="Аимбот",Default=true,Callback=function(v) S.Aimbot=v end})
G2L:AddToggle("b2",{Text="Camera Lock",Default=false,Callback=function(v) S.CamLock=v end})
G2L:AddToggle("b3",{Text="Триггербот",Default=false,Callback=function(v) S.Triggerbot=v end})
G2L:AddSlider("b4",{Text="FOV",Default=200,Min=50,Max=600,Rounding=0,Callback=function(v) C.FOV=v end})
G2L:AddSlider("b5",{Text="Плавность",Default=80,Min=1,Max=200,Rounding=0,Callback=function(v) C.Smooth=v end})
G2L:AddSlider("b6",{Text="Предикшн",Default=0.1,Min=0,Max=1,Rounding=2,Callback=function(v) C.Pred=v end})
G2R:AddToggle("b7",{Text="Расширить хитбоксы",Default=false,Callback=function(v) S.Hitbox=v if not v then SetHitbox(false) end end})
G2R:AddSlider("b8",{Text="Размер хитбокса",Default=15,Min=5,Max=30,Rounding=0,Callback=function(v) C.HitboxSize=v end})

local G3L,G3R = T3:AddLeftGroupbox("Движение"),T3:AddRightGroupbox("Настройки")
G3L:AddToggle("c1",{Text="Бесконечный прыжок",Default=false,Callback=function(v) S.InfJump=v end})
G3L:AddToggle("c2",{Text="Ноклип",Default=false,Callback=function(v) S.Noclip=v SetNoclip(v) end})
G3L:AddToggle("c3",{Text="Полёт",Default=false,Callback=function(v) S.Fly=v SetFly(v) end})
G3L:AddToggle("c4",{Text="Спидхак",Default=false,Callback=function(v) S.Speed=v end})
G3L:AddToggle("c5",{Text="Банихоп",Default=false,Callback=function(v) S.Bhop=v SetBhop(v) end})
G3L:AddToggle("c6",{Text="Спинбот",Default=false,Callback=function(v) S.Spin=v SetSpin(v) end})
G3R:AddSlider("c7",{Text="Скорость",Default=16,Min=16,Max=200,Rounding=0,Callback=function(v) C.WalkSpd=v end})
G3R:AddSlider("c8",{Text="Прыжок",Default=50,Min=50,Max=200,Rounding=0,Callback=function(v) C.JumpPwr=v end})
G3R:AddSlider("c9",{Text="Скорость полёта",Default=50,Min=10,Max=200,Rounding=0,Callback=function(v) C.FlySpd=v end})
G3R:AddSlider("c10",{Text="Скорость вращения",Default=30,Min=5,Max=60,Rounding=0,Callback=function(v) C.SpinSpd=v end})

local G4L,G4R = T4:AddLeftGroupbox("Утилиты"),T4:AddRightGroupbox("Сервер")
G4L:AddToggle("d1",{Text="Анти-АФК",Default=false,Callback=function(v) S.AntiAFK=v SetAFK(v) end})
G4L:AddButton({Text="Респавн",Func=function() if LP.Character then LP.Character:BreakJoints() end end})
G4L:AddButton({Text="Сбросить скорость",Func=function() local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed=16 h.JumpPower=50 end Lib:Notify("Сброшено!") end})
G4R:AddButton({Text="Переподключиться",Func=function() TeleportService:Teleport(game.PlaceId,LP) end})
G4R:AddButton({Text="Сменить сервер",Func=function() pcall(function() local s = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")) for _,sv in pairs(s.data) do if sv.playing<sv.maxPlayers and sv.id~=game.JobId then TeleportService:TeleportToPlaceInstance(game.PlaceId,sv.id,LP) break end end end) end})

local G5L,G5R = T5:AddLeftGroupbox("Список"),T5:AddRightGroupbox("Действия")
G5L:AddButton({Text="Обновить список",Func=function() local n={} for _,p in pairs(Players:GetPlayers()) do if p~=LP then table.insert(n,p.Name) end end if Options and Options.PL then Options.PL:SetValues(n) end Lib:Notify("Обновлено! ("..#n..")") end})
G5L:AddDropdown("PL",{Values={},Text="Выбрать игрока",Callback=function(v) SelPlayer = Players:FindFirstChild(v) if SelPlayer then Lib:Notify("Выбран: "..v) end end})
G5R:AddButton({Text="Наблюдать",Func=function() if SelPlayer and SelPlayer.Character then Cam.CameraSubject=SelPlayer.Character:FindFirstChildOfClass("Humanoid") Lib:Notify("Наблюдаем: "..SelPlayer.Name) else Lib:Notify("Выбери игрока!") end end})
G5R:AddButton({Text="Перестать",Func=function() if LP.Character then Cam.CameraSubject=LP.Character:FindFirstChildOfClass("Humanoid") Lib:Notify("Остановлено") end end})
G5R:AddButton({Text="Телепорт",Func=function() if SelPlayer and SelPlayer.Character and LP.Character then local t,m = SelPlayer.Character:FindFirstChild("HumanoidRootPart"),LP.Character:FindFirstChild("HumanoidRootPart") if t and m then m.CFrame=t.CFrame*CFrame.new(0,0,3) Lib:Notify("ТП!") end else Lib:Notify("Выбери игрока!") end end})
G5R:AddButton({Text="Копировать ник",Func=function() if SelPlayer and setclipboard then setclipboard(SelPlayer.Name) Lib:Notify("Скопировано!") else Lib:Notify("Выбери игрока!") end end})
G5R:AddButton({Text="Инфо",Func=function() if SelPlayer then Lib:Notify("Ник: "..SelPlayer.Name.."\nID: "..SelPlayer.UserId.."\nВозраст: "..SelPlayer.AccountAge.." дней",5) else Lib:Notify("Выбери игрока!") end end})

task.spawn(function() task.wait(1) local n={} for _,p in pairs(Players:GetPlayers()) do if p~=LP then table.insert(n,p.Name) end end if Options and Options.PL then Options.PL:SetValues(n) end end)
Players.PlayerAdded:Connect(function() task.wait(1) local n={} for _,p in pairs(Players:GetPlayers()) do if p~=LP then table.insert(n,p.Name) end end if Options and Options.PL then Options.PL:SetValues(n) end end)
Players.PlayerRemoving:Connect(function() task.wait(0.5) local n={} for _,p in pairs(Players:GetPlayers()) do if p~=LP then table.insert(n,p.Name) end end if Options and Options.PL then Options.PL:SetValues(n) end end)

Lib.AccentColor=Color3.fromRGB(150,150,150) Lib.AccentColorDark=Color3.fromRGB(100,100,100) Lib:UpdateColorsUsingRegistry()
Lib:SetWatermarkVisibility(true)
local fps,lt = 0,tick()
RunService.RenderStepped:Connect(function() fps=fps+1 if tick()-lt>=1 then local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) Lib:SetWatermark(string.format("Cheat v6 | FPS: %d | Пинг: %dms",fps,ping)) fps,lt = 0,tick() end end)
Lib.KeybindFrame.Visible = true
StarterGui:SetCore("SendNotification",{Title="Cheat v6",Text="Загружен!",Duration=3})
print("Cheat v6!")
