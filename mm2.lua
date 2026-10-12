-- language: Lua, file: mm2.lua, target: Murder Mystery 2
-- real remotes. role via GetCurrentPlayerData. kill via tool Activate.

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")
local Lighting          = game:GetService("Lighting")
local LocalPlayer       = Players.LocalPlayer
local Camera            = workspace.CurrentCamera

-- ── resolve real remotes ───────────────────────────────────────────────────
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
if not Remotes then
    warn("[MM2] Remotes folder not found")
    return
end

local Gameplay  = Remotes:FindFirstChild("Gameplay")
local Inventory = Remotes:FindFirstChild("Inventory")
local Extras    = Remotes:FindFirstChild("Extras")

local GetCoin        = Gameplay and Gameplay:FindFirstChild("GetCoin")
local GetPlayerData  = Gameplay and Gameplay:FindFirstChild("GetCurrentPlayerData")
local EquipRemote    = Inventory and Inventory:FindFirstChild("Equip")

print("[MM2] GetCoin:", GetCoin and "ok" or "MISS",
      "| Equip:", EquipRemote and "ok" or "MISS",
      "| GetPlayerData:", GetPlayerData and "ok" or "MISS")

-- ── role cache (pulled from GetCurrentPlayerData) ──────────────────────────
local roleCache = {}   -- playerName -> "Murderer" | "Sheriff" | "Innocent"

local function fetchMyData()
    if not GetPlayerData then return end
    local ok, data = pcall(function() return GetPlayerData:InvokeServer() end)
    if not ok or type(data) ~= "table" then return end
    -- data shape is game-specific; look for any string field that matches a role
    for _, v in pairs(data) do
        if type(v) == "string" then
            local lv = v:lower()
            if lv:find("murder") or lv:find("sheriff") or lv:find("innocent") then
                roleCache[LocalPlayer.Name] = v
                return
            end
        end
    end
end

-- pull once at load, then every 5s
task.spawn(function()
    while task.wait(5) do fetchMyData() end
end)
fetchMyData()

-- Infer other players' roles by elimination + kill-event tracking
local deadPlayers = {}
local lastKnownMurderer, lastKnownSheriff

-- listen for KillEvent args — the dump showed role strings arrive here
if Gameplay then
    local killEv = Gameplay:FindFirstChild("KillEvent")
    if killEv then
        killEv.OnClientEvent:Connect(function(role, evt, victimName)
            if type(role) == "string" then
                -- role arg here is often the killer's role, evt tells what happened
                if role:lower():find("murder") then lastKnownMurderer = victimName end
                if role:lower():find("sheriff") then lastKnownSheriff = victimName end
            end
            if evt == "MurdererDied" then
                deadPlayers[victimName] = true
                lastKnownMurderer = nil
            end
        end)
    end
end

local function getRoleOf(player)
    if deadPlayers[player.Name] then return "Dead" end
    if roleCache[player.Name] then return roleCache[player.Name] end
    if lastKnownMurderer == player.Name then return "Murderer" end
    if lastKnownSheriff == player.Name then return "Sheriff" end
    return "Innocent"
end

local function getMyRole() return getRoleOf(LocalPlayer):lower() end
local function isMurderer() return getMyRole():find("murder") ~= nil end
local function isSheriff()  return getMyRole():find("sheriff") ~= nil end

-- ── flags ──────────────────────────────────────────────────────────────────
local flags = {
    esp = false, speed = false, noclip = false, infiniteJump = false,
    autoFarm = false, fly = false, flySpeed = 60,
    antiFling = false, autoActivate = false,
    bringGun = false, fpsBoost = false,
    autoChase = false,
}

local espTracked = {}
local flyConn, flyVel
local farmConn, farmVel, farmTarget
local chaseConn, chaseVel
local originalLighting = {}

-- ── ESP ────────────────────────────────────────────────────────────────────
local function removeESP(player)
    local t = espTracked[player]
    if not t then return end
    if t.highlight and t.highlight.Parent then t.highlight:Destroy() end
    if t.billboard and t.billboard.Parent then t.billboard:Destroy() end
    espTracked[player] = nil
end

local function clearESP()
    for p, _ in pairs(espTracked) do removeESP(p) end
    for _, o in ipairs(workspace:GetDescendants()) do
        if o.Name == "MM2_ESP" or o.Name == "MM2_ESP_Label" then o:Destroy() end
    end
    espTracked = {}
end

local function applyESP(player)
    if player == LocalPlayer or not player.Character then return end
    local head = player.Character:FindFirstChild("Head")
    if not head then return end

    local role = getRoleOf(player):lower()
    local fill, txt, txtCol
    if role == "dead" then
        fill, txt, txtCol = Color3.fromRGB(120,120,120), "DEAD", Color3.fromRGB(120,120,120)
    elseif role:find("murder") then
        fill, txt, txtCol = Color3.fromRGB(255,60,60), "MURDERER", Color3.fromRGB(255,60,60)
    elseif role:find("sheriff") then
        fill, txt, txtCol = Color3.fromRGB(60,130,255), "SHERIFF", Color3.fromRGB(60,130,255)
    else
        fill, txt, txtCol = Color3.fromRGB(60,255,60), "INNOCENT", Color3.fromRGB(60,255,60)
    end

    removeESP(player)

    local h = Instance.new("Highlight")
    h.Name = "MM2_ESP"
    h.Adornee = player.Character
    h.Parent = player.Character
    h.FillColor = fill
    h.OutlineColor = Color3.new(1,1,1)
    h.FillTransparency = 0.55
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    local bb = Instance.new("BillboardGui")
    bb.Name = "MM2_ESP_Label"
    bb.Size = UDim2.fromOffset(130, 22)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = head
    bb.Parent = head

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.fromScale(1,1)
    lbl.BackgroundTransparency = 1
    lbl.Text = txt
    lbl.TextColor3 = txtCol
    lbl.TextStrokeTransparency = 0
    lbl.Font = Enum.Font.GothamBold
    lbl.TextScaled = true
    lbl.Parent = bb

    espTracked[player] = { highlight = h, billboard = bb }
end

-- ── movement ───────────────────────────────────────────────────────────────
local function applySpeed()
    local c = LocalPlayer.Character
    if c then
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = flags.speed and 50 or 16 end
    end
end

local function applyNoclip()
    local c = LocalPlayer.Character
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = not flags.noclip end
    end
end

UserInputService.JumpRequest:Connect(function()
    if not flags.infiniteJump then return end
    local c = LocalPlayer.Character
    if c then
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ── fly ────────────────────────────────────────────────────────────────────
local function stopFly()
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if flyVel then flyVel:Destroy() flyVel = nil end
    local c = LocalPlayer.Character
    if c then
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h.PlatformStand = false end
    end
end

local function startFly()
    stopFly()
    local c = LocalPlayer.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local h = c:FindFirstChildOfClass("Humanoid")
    if not hrp or not h then return end

    h.PlatformStand = true
    flyVel = Instance.new("BodyVelocity")
    flyVel.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    flyVel.Velocity = Vector3.zero
    flyVel.Parent = hrp

    flyConn = RunService.RenderStepped:Connect(function()
        if not flags.fly then stopFly() return end
        if not flyVel or not flyVel.Parent then return end
        local dir = Vector3.zero
        local cam = Camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
           or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            dir -= Vector3.new(0,1,0)
        end
        flyVel.Velocity = dir.Magnitude > 0
            and dir.Unit * flags.flySpeed
            or Vector3.zero
    end)
end

-- ── auto activate (real MM2 kill: swing tool near target) ─────────────────
local function equippedTool()
    local c = LocalPlayer.Character
    if not c then return nil end
    return c:FindFirstChildOfClass("Tool")
end

local function spamActivate()
    if not flags.autoActivate then return end
    local tool = equippedTool()
    if not tool then return end
    pcall(function() tool:Activate() end)
end

-- call Activate when a target is within hitbox range
local function autoActivateNearby()
    local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    local tool = equippedTool()
    if not tool then return end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and h and h.Health > 0 then
                local d = (hrp.Position - myHrp.Position).Magnitude
                if d < 6 then
                    pcall(function() tool:Activate() end)
                end
            end
        end
    end
end

-- ── anti-fling ─────────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not flags.antiFling then return end
    local c = LocalPlayer.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if hrp then
        local v = hrp.AssemblyLinearVelocity
        hrp.AssemblyLinearVelocity = Vector3.new(
            math.clamp(v.X, -50, 50),
            math.clamp(v.Y, -50, 50),
            math.clamp(v.Z, -50, 50))
    end
end)

-- ── coin farm (uses real GetCoin remote) ───────────────────────────────────
local function findNearestCoin(origin)
    local nearest, best = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("coin")
           and obj.Transparency < 1 and obj.Parent then
            local d = (obj.Position - origin).Magnitude
            if d < best then nearest = obj best = d end
        end
    end
    return nearest
end

local function stopFarm()
    if farmConn then farmConn:Disconnect() farmConn = nil end
    if farmVel then farmVel:Destroy() farmVel = nil end
    farmTarget = nil
    local c = LocalPlayer.Character
    if c then
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h.PlatformStand = false end
    end
end

local function startFarm()
    stopFarm()
    local c = LocalPlayer.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local h = c:FindFirstChildOfClass("Humanoid")
    if not hrp or not h then return end

    h.PlatformStand = true
    flags.noclip = true

    farmVel = Instance.new("BodyVelocity")
    farmVel.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    farmVel.Velocity = Vector3.zero
    farmVel.Parent = hrp

    farmConn = RunService.Heartbeat:Connect(function()
        if not flags.autoFarm then stopFarm() return end
        if not LocalPlayer.Character then return end
        local myHrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myHrp or not farmVel or not farmVel.Parent then return end

        if not farmTarget or not farmTarget.Parent
           or farmTarget.Transparency >= 1 then
            farmTarget = findNearestCoin(myHrp.Position)
        end

        if farmTarget then
            local dist = (farmTarget.Position - myHrp.Position).Magnitude
            if dist < 4 then
                if GetCoin then
                    pcall(function() GetCoin:FireServer(farmTarget) end)
                    pcall(function() GetCoin:FireServer(farmTarget.Position) end)
                    pcall(function() GetCoin:FireServer() end)
                end
                farmVel.Velocity = Vector3.zero
                farmTarget = nil
            else
                local dir = (farmTarget.Position - myHrp.Position).Unit
                farmVel.Velocity = dir * 45
            end
        else
            farmVel.Velocity = Vector3.zero
        end
    end)
end

-- ── bring gun (real Equip remote) ──────────────────────────────────────────
local function bringGun()
    if not EquipRemote then return end
    local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart")
           and (obj.Name:lower():find("gun") or obj.Name:lower():find("knife")) then
            if (obj.Position - myHrp.Position).Magnitude < 20
               and not obj:IsDescendantOf(LocalPlayer.Character) then
                pcall(function() EquipRemote:FireServer(obj) end)
            end
        end
    end
end

-- ── auto chase (fly to target + spam Activate) ─────────────────────────────
local function stopChase()
    if chaseConn then chaseConn:Disconnect() chaseConn = nil end
    if chaseVel then chaseVel:Destroy() chaseVel = nil end
    local c = LocalPlayer.Character
    if c then
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h.PlatformStand = false end
    end
end

local function startChase()
    stopChase()
    local c = LocalPlayer.Character
    if not c then return end
    local myHrp = c:FindFirstChild("HumanoidRootPart")
    local h = c:FindFirstChildOfClass("Humanoid")
    if not myHrp or not h then return end

    h.PlatformStand = true
    flags.noclip = true

    chaseVel = Instance.new("BodyVelocity")
    chaseVel.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    chaseVel.Velocity = Vector3.zero
    chaseVel.Parent = myHrp

    chaseConn = RunService.Heartbeat:Connect(function()
        if not flags.autoChase then stopChase() return end
        if not LocalPlayer.Character then return end
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp or not chaseVel or not chaseVel.Parent then return end

        local targetName
        if isMurderer() then targetName = "sheriff"
        elseif isSheriff() then targetName = "murder"
        else targetName = nil end
        if not targetName then chaseVel.Velocity = Vector3.zero return end

        local target, targetHrp
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character
               and getRoleOf(p):lower():find(targetName) then
                targetHrp = p.Character:FindFirstChild("HumanoidRootPart")
                if targetHrp then target = p break end
            end
        end

        if targetHrp and target then
            local dist = (targetHrp.Position - hrp.Position).Magnitude
            if dist < 4 then
                chaseVel.Velocity = Vector3.zero
                -- face them and spam Activate
                hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(
                    targetHrp.Position.X, hrp.Position.Y, targetHrp.Position.Z))
                local tool = equippedTool()
                if tool then pcall(function() tool:Activate() end) end
            else
                local dir = (targetHrp.Position - hrp.Position).Unit
                chaseVel.Velocity = dir * 55
            end
        else
            chaseVel.Velocity = Vector3.zero
        end
    end)
end

-- ── fps boost ──────────────────────────────────────────────────────────────
local function applyFPSBoost(on)
    if on then
        originalLighting.GlobalShadows = Lighting.GlobalShadows
        originalLighting.FogEnd = Lighting.FogEnd
        originalLighting.Brightness = Lighting.Brightness
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e6
        Lighting.Brightness = 0
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") then
                v.Enabled = false
            end
        end
    else
        if originalLighting.GlobalShadows ~= nil then
            Lighting.GlobalShadows = originalLighting.GlobalShadows
            Lighting.FogEnd = originalLighting.FogEnd
            Lighting.Brightness = originalLighting.Brightness
        end
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") then
                v.Enabled = true
            end
        end
    end
end

-- ── loop ───────────────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if flags.esp then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then applyESP(p) end
        end
    end
    if flags.speed then applySpeed() end
    if flags.noclip then applyNoclip() end
    if flags.autoActivate then autoActivateNearby() end
    if flags.bringGun then bringGun() end
end)

-- ── UI (clean flat dark, mobile-safe) ──────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "MM2Own"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(300, 520)
frame.Position = UDim2.new(0.5, -150, 0, 80)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.5
stroke.Color = Color3.fromRGB(150, 90, 255)
stroke.Transparency = 0.15
stroke.Parent = frame

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 54)
header.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
header.BorderSizePixel = 0
header.ZIndex = 3
header.Parent = frame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)

local headerCover = Instance.new("Frame")
headerCover.Size = UDim2.new(1, 0, 0, 20)
headerCover.Position = UDim2.new(0, 0, 1, -20)
headerCover.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
headerCover.BorderSizePixel = 0
headerCover.ZIndex = 3
headerCover.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 0, 26)
title.Position = UDim2.fromOffset(18, 6)
title.BackgroundTransparency = 1
title.Text = "MM2"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 4
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -80, 0, 14)
subtitle.Position = UDim2.fromOffset(18, 30)
subtitle.BackgroundTransparency = 1
subtitle.Text = "own build"
subtitle.TextColor3 = Color3.fromRGB(140, 140, 170)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 10
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 4
subtitle.Parent = header

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.fromOffset(34, 34)
minBtn.Position = UDim2.new(1, -44, 0, 10)
minBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
minBtn.BorderSizePixel = 0
minBtn.Text = "–"
minBtn.TextColor3 = Color3.fromRGB(220, 220, 235)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 20
minBtn.ZIndex = 4
minBtn.Parent = header
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 8)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -70)
scroll.Position = UDim2.fromOffset(10, 62)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(150, 90, 255)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ZIndex = 3
scroll.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 7)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local expanded = true
local function toggleMinimise()
    expanded = not expanded
    for _, child in ipairs(frame:GetChildren()) do
        if child ~= header and child ~= stroke then
            child.Visible = expanded
        end
    end
    frame.Size = expanded and UDim2.fromOffset(300, 520)
                          or UDim2.fromOffset(300, 54)
    minBtn.Text = expanded and "–" or "+"
end

local function bindButton(btn, fn)
    local last = 0
    local function fire()
        local n = tick()
        if n - last < 0.25 then return end
        last = n
        fn()
    end
    btn.MouseButton1Click:Connect(fire)
    btn.Activated:Connect(fire)
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then fire() end
    end)
end

bindButton(minBtn, toggleMinimise)

local function makeToggle(labelText, key, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.ZIndex = 4
    btn.Parent = scroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 1, -14)
    accent.Position = UDim2.fromOffset(8, 7)
    accent.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    accent.BorderSizePixel = 0
    accent.ZIndex = 5
    accent.Parent = btn
    Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 2)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -90, 1, 0)
    label.Position = UDim2.fromOffset(22, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(220, 220, 235)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 5
    label.Parent = btn

    local status = Instance.new("TextLabel")
    status.Size = UDim2.fromOffset(52, 22)
    status.Position = UDim2.new(1, -60, 0.5, -11)
    status.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
    status.BorderSizePixel = 0
    status.Text = "OFF"
    status.TextColor3 = Color3.fromRGB(160, 160, 180)
    status.Font = Enum.Font.GothamBold
    status.TextSize = 11
    status.ZIndex = 5
    status.Parent = btn
    Instance.new("UICorner", status).CornerRadius = UDim.new(0, 5)

    bindButton(btn, function()
        flags[key] = not flags[key]
        local on = flags[key]
        status.Text = on and "ON" or "OFF"
        status.BackgroundColor3 = on and Color3.fromRGB(150, 90, 255)
                                       or Color3.fromRGB(45, 45, 58)
        status.TextColor3 = on and Color3.fromRGB(255, 255, 255)
                                   or Color3.fromRGB(160, 160, 180)
        accent.BackgroundColor3 = on and Color3.fromRGB(150, 90, 255)
                                       or Color3.fromRGB(70, 70, 90)
        if callback then callback() end
    end)
end

local function sectionHeader(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -8, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Text = text:upper()
    lbl.TextColor3 = Color3.fromRGB(150, 90, 255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4
    lbl.Parent = scroll
end

sectionHeader("Visual")
makeToggle("ESP", "esp", function()
    if flags.esp then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then applyESP(p) end
        end
    else clearESP() end
end)
makeToggle("FPS Boost", "fpsBoost", function() applyFPSBoost(flags.fpsBoost) end)

sectionHeader("Movement")
makeToggle("Speed", "speed", applySpeed)
makeToggle("Noclip", "noclip", applyNoclip)
makeToggle("Infinite Jump", "infiniteJump", nil)
makeToggle("Fly", "fly", function()
    if flags.fly then startFly() else stopFly() end
end)
makeToggle("Anti Fling", "antiFling", nil)

sectionHeader("Combat")
makeToggle("Auto Activate", "autoActivate", nil)
makeToggle("Auto Chase Target", "autoChase", function()
    if flags.autoChase then startChase() else stopChase() end
end)
makeToggle("Bring Gun", "bringGun", nil)

sectionHeader("Economy")
makeToggle("Auto Farm Coins", "autoFarm", function()
    if flags.autoFarm then startFarm() else stopFarm() end
end)

Players.PlayerAdded:Connect(function(p)
    if flags.esp then
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            applyESP(p)
        end)
    end
end)
Players.PlayerRemoving:Connect(removeESP)

local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)
header.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                     or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

print("[MM2] own build loaded")
