-- language: Lua, file: mm2.lua, target: Murder Mystery 2
-- own build. cooler UI, fly, coin teleport farm, hide toggle.

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer
local Camera            = workspace.CurrentCamera

-- ── remotes ────────────────────────────────────────────────────────────────
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
    or ReplicatedStorage:FindFirstChild("RemoteEvents")
    or ReplicatedStorage

local function findRemote(name)
    local r = Remotes:FindFirstChild(name)
    if r then return r end
    for _, v in ipairs(Remotes:GetDescendants()) do
        if v.Name == name then return v end
    end
    return nil
end

local shootRemote = findRemote("Shoot")
local stabRemote  = findRemote("Stab")
local coinRemote  = findRemote("Coin")
local dropRemote  = findRemote("Drop")

print("[MM2] remotes — Stab:", stabRemote and "ok" or "MISS",
      "Coin:", coinRemote and "ok" or "MISS")

-- ── state ──────────────────────────────────────────────────────────────────
local flags = {
    esp = false, speed = false, noclip = false, infiniteJump = false,
    killAll = false, autoShoot = false, autoStab = false,
    autoFarm = false, fly = false, flySpeed = 100,
}

local flyConnection, flyVelocity
local espHighlights = {}

-- ── ESP ────────────────────────────────────────────────────────────────────
local function clearESP()
    for _, h in pairs(espHighlights) do
        if h and h.Parent then h:Destroy() end
    end
    espHighlights = {}
end

local function applyESP(player)
    if player == LocalPlayer or not player.Character then return end
    local roleVal = player:FindFirstChild("Role")
        or (player.Character and player.Character:FindFirstChild("Role"))
    local role = roleVal and tostring(roleVal.Value):lower() or "innocent"

    local color = Color3.fromRGB(50, 255, 50)
    if role:find("murder") then color = Color3.fromRGB(255, 50, 50)
    elseif role:find("sheriff") then color = Color3.fromRGB(50, 100, 255) end

    if espHighlights[player] then espHighlights[player]:Destroy() end
    local h = Instance.new("Highlight")
    h.Adornee = player.Character
    h.Parent = player.Character
    h.FillColor = color
    h.OutlineColor = Color3.new(1, 1, 1)
    h.FillTransparency = 0.5
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    espHighlights[player] = h
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
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end
    if flyVelocity then flyVelocity:Destroy() flyVelocity = nil end
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
    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyVelocity.Velocity = Vector3.zero
    flyVelocity.Parent = hrp

    flyConnection = RunService.RenderStepped:Connect(function()
        if not flags.fly then stopFly() return end
        local dir = Vector3.zero
        local cam = Camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
        flyVelocity.Velocity = dir.Magnitude > 0
            and dir.Unit * flags.flySpeed
            or Vector3.zero
    end)
end

-- ── role ───────────────────────────────────────────────────────────────────
local function getMyRole()
    local r = LocalPlayer:FindFirstChild("Role")
        or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Role"))
    return r and tostring(r.Value):lower() or ""
end
local function isMurderer() return getMyRole():find("murder") ~= nil end
local function isSheriff()  return getMyRole():find("sheriff") ~= nil end

-- ── combat ─────────────────────────────────────────────────────────────────
local function killAll()
    if not stabRemote then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and h and h.Health > 0 then
                pcall(function() stabRemote:FireServer(hrp) end)
                pcall(function() stabRemote:FireServer(p) end)
            end
        end
    end
end

local function autoShoot()
    if not shootRemote or not isSheriff() then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local rv = p:FindFirstChild("Role")
                or (p.Character and p.Character:FindFirstChild("Role"))
            local role = rv and tostring(rv.Value):lower() or ""
            if role:find("murder") then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then pcall(function() shootRemote:FireServer(hrp) end) end
            end
        end
    end
end

local function autoStab()
    if not stabRemote or not isMurderer() then return end
    local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and h and h.Health > 0
               and (hrp.Position - myHrp.Position).Magnitude < 15 then
                pcall(function() stabRemote:FireServer(hrp) end)
                pcall(function() stabRemote:FireServer(p) end)
            end
        end
    end
end

-- ── coin farm: fly + teleport to each coin ─────────────────────────────────
local farmConnection

local function stopFarm()
    if farmConnection then farmConnection:Disconnect() farmConnection = nil end
    stopFly()
    flags.fly = false
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

    farmConnection = RunService.Heartbeat:Connect(function()
        if not flags.autoFarm then stopFarm() return end
        if not LocalPlayer.Character then return end
        local myHrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myHrp then return end

        -- find nearest coin
        local nearest, nearestDist = nil, math.huge
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart")
               and (obj.Name == "Coin" or obj.Name:lower():find("coin")) then
                local d = (obj.Position - myHrp.Position).Magnitude
                if d < nearestDist then
                    nearest = obj
                    nearestDist = d
                end
            end
        end

        if nearest then
            myHrp.CFrame = CFrame.new(nearest.Position)
            if coinRemote then
                pcall(function() coinRemote:FireServer(nearest) end)
                pcall(function() coinRemote:FireServer(nearest.Position) end)
            end
        else
            -- no coin nearby: fly straight up and let the next scan catch one
            myHrp.Velocity = Vector3.new(0, 50, 0)
        end
    end)
end

-- ── main loop ──────────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if flags.esp then
        for _, p in ipairs(Players:GetPlayers()) do applyESP(p) end
    end
    if flags.speed then applySpeed() end
    if flags.noclip then applyNoclip() end
    if flags.killAll then killAll() end
    if flags.autoShoot then autoShoot() end
    if flags.autoStab then autoStab() end
end)

-- ── UI ─────────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "MM2Own"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- animated gradient border frame
local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(280, 460)
frame.Position = UDim2.fromOffset(20, 60)
frame.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.5
stroke.Color = Color3.fromRGB(120, 90, 255)
stroke.Transparency = 0.2
stroke.Parent = frame

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 90, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 90, 180)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 200, 255)),
}
gradient.Rotation = 45
gradient.Parent = stroke

-- title bar
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 0, 40)
title.Position = UDim2.fromOffset(16, 0)
title.BackgroundTransparency = 1
title.Text = "MM2"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -60, 0, 14)
subtitle.Position = UDim2.fromOffset(16, 20)
subtitle.BackgroundTransparency = 1
subtitle.Text = "own build"
subtitle.TextColor3 = Color3.fromRGB(140, 140, 160)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 10
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = frame

-- minimise button
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.fromOffset(28, 28)
minBtn.Position = UDim2.new(1, -40, 0, 8)
minBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
minBtn.BorderSizePixel = 0
minBtn.Text = "–"
minBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 18
minBtn.Parent = frame
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

-- scroll container for toggles
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -24, 1, -70)
scroll.Position = UDim2.fromOffset(12, 60)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(120, 90, 255)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

-- minimise behaviour
local visible = true
minBtn.MouseButton1Click:Connect(function()
    visible = not visible
    for _, child in ipairs(frame:GetChildren()) do
        if child ~= title and child ~= subtitle and child ~= minBtn
           and child ~= stroke and child ~= gradient then
            child.Visible = visible
        end
    end
    frame.Size = visible and UDim2.fromOffset(280, 460)
                          or UDim2.fromOffset(280, 48)
    minBtn.Text = visible and "–" or "+"
end)

-- toggle factory
local function makeToggle(labelText, key, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = scroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 4, 1, -12)
    accent.Position = UDim2.fromOffset(6, 6)
    accent.BackgroundColor3 = Color3.fromRGB(120, 90, 255)
    accent.BorderSizePixel = 0
    accent.Parent = btn
    Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 2)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.fromOffset(20, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(220, 220, 235)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = btn

    local status = Instance.new("TextLabel")
    status.Size = UDim2.fromOffset(50, 20)
    status.Position = UDim2.new(1, -58, 0.5, -10)
    status.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    status.BorderSizePixel = 0
    status.Text = "OFF"
    status.TextColor3 = Color3.fromRGB(160, 160, 180)
    status.Font = Enum.Font.GothamBold
    status.TextSize = 11
    status.Parent = btn
    Instance.new("UICorner", status).CornerRadius = UDim.new(0, 4)

    btn.MouseButton1Click:Connect(function()
        flags[key] = not flags[key]
        local on = flags[key]
        status.Text = on and "ON" or "OFF"
        status.BackgroundColor3 = on
            and Color3.fromRGB(120, 90, 255)
            or Color3.fromRGB(45, 45, 55)
        status.TextColor3 = on
            and Color3.fromRGB(255, 255, 255)
            or Color3.fromRGB(160, 160, 180)
        accent.BackgroundColor3 = on
            and Color3.fromRGB(120, 90, 255)
            or Color3.fromRGB(60, 60, 75)
        if callback then callback() end
    end)
    return btn
end

-- section header helper
local function sectionHeader(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -8, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Text = text:upper()
    lbl.TextColor3 = Color3.fromRGB(120, 90, 255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = scroll
end

sectionHeader("Visual")
makeToggle("ESP",            "esp",          nil)
sectionHeader("Movement")
makeToggle("Speed",          "speed",        applySpeed)
makeToggle("Noclip",         "noclip",       applyNoclip)
makeToggle("Infinite Jump",  "infiniteJump", nil)
makeToggle("Fly",            "fly",          function()
    if flags.fly then startFly() else stopFly() end
end)
sectionHeader("Combat")
makeToggle("Kill All",       "killAll",      nil)
makeToggle("Auto Shoot",     "autoShoot",    nil)
makeToggle("Auto Stab",      "autoStab",     nil)
sectionHeader("Economy")
makeToggle("Auto Farm Coins","autoFarm",     function()
    if flags.autoFarm then startFarm() else stopFarm() end
end)

-- drag
local dragging, dragStart, startPos
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)
title.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                     or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
title.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- keybind: right shift toggles whole UI
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        gui.Enabled = not gui.Enabled
    end
end)

print("[MM2] own build loaded")
