-- language: Lua, file: muscle.lua, target: Pumpkin Muscle Legends
-- EAM menu. auto lift on equipped tool. no guessing.

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local LocalPlayer       = Players.LocalPlayer
local Camera            = workspace.CurrentCamera

local MuscleEvent = LocalPlayer:FindFirstChild("MuscleEvent")
task.spawn(function()
    while not MuscleEvent do
        MuscleEvent = LocalPlayer:FindFirstChild("MuscleEvent")
        if not MuscleEvent and LocalPlayer.Character then
            MuscleEvent = LocalPlayer.Character:FindFirstChild("MuscleEvent")
        end
        task.wait(1)
    end
end)

local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
local petshopRemote = rEvents and rEvents:FindFirstChild("cPetshopRemote")

local flags = {
    autoLift     = false,
    liftDelay    = 0.03,
    autoRebirth  = false,
    autoBuyPet   = false,
    petName      = "Green Aura",
    speed        = false,
    noclip       = false,
    infiniteJump = false,
    fly          = false,
    flySpeed     = 60,
    antiFling    = false,
    fullbright   = false,
    noFog        = false,
    fpsBoost     = false,
    hideGui      = false,
    rebirthDelay = 5,
    petDelay     = 1,
}

-- ── auto lift ──────────────────────────────────────────────────────────────
local function findWeightTool()
    local c = LocalPlayer.Character
    if c then
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") then return t end
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then return t end
        end
    end
    return nil
end

task.spawn(function()
    while task.wait(flags.liftDelay) do
        if flags.autoLift then
            local tool = findWeightTool()
            if tool then
                pcall(function() tool:Activate() end)
            end
        end
    end
end)

-- ── movement ───────────────────────────────────────────────────────────────
local function applySpeed()
    local c = LocalPlayer.Character
    if c then
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = flags.speed and 60 or 16 end
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

local flyConn, flyVel
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

-- ── lighting ───────────────────────────────────────────────────────────────
local Lighting = game:GetService("Lighting")
local originalLighting = {}

local function applyLighting()
    if flags.fullbright then
        if originalLighting.Ambient == nil then
            originalLighting.Ambient = Lighting.Ambient
            originalLighting.Brightness = Lighting.Brightness
        end
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
    else
        if originalLighting.Ambient then
            Lighting.Ambient = originalLighting.Ambient
            Lighting.Brightness = originalLighting.Brightness
        end
    end
    if flags.noFog then
        if originalLighting.FogEnd == nil then
            originalLighting.FogEnd = Lighting.FogEnd
        end
        Lighting.FogEnd = 1e6
    else
        if originalLighting.FogEnd then
            Lighting.FogEnd = originalLighting.FogEnd
        end
    end
    if flags.fpsBoost then
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") then
                v.Enabled = false
            end
        end
        Lighting.GlobalShadows = false
    end
end

-- ── rebirth / pets ─────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(flags.rebirthDelay) do
        if flags.autoRebirth and rEvents
           and rEvents:FindFirstChild("rebirthRemote") then
            pcall(function()
                rEvents.rebirthRemote:InvokeServer("rebirthRequest")
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(flags.petDelay) do
        if flags.autoBuyPet and petshopRemote then
            pcall(function()
                petshopRemote:InvokeServer(flags.petName)
            end)
        end
    end
end)

-- ── UI ─────────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "EAM"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local glow = Instance.new("Frame")
glow.Size = UDim2.fromOffset(330, 540)
glow.Position = UDim2.new(0.5, -165, 0, 40)
glow.BackgroundColor3 = Color3.fromRGB(140, 80, 255)
glow.BackgroundTransparency = 0.88
glow.BorderSizePixel = 0
glow.ZIndex = 1
glow.Parent = gui
Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 26)

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(320, 530)
frame.Position = UDim2.new(0.5, -160, 0, 46)
frame.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
frame.BorderSizePixel = 0
frame.ZIndex = 2
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 22)

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.2
stroke.Color = Color3.fromRGB(160, 100, 255)
stroke.Parent = frame

local strokeGrad = Instance.new("UIGradient")
strokeGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 80, 200)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(150, 90, 255)),
    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(80, 200, 255)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 80, 200)),
}
strokeGrad.Parent = stroke

task.spawn(function()
    while strokeGrad.Parent do
        strokeGrad.Rotation = (strokeGrad.Rotation + 1.2) % 360
        task.wait(0.03)
    end
end)

-- header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 74)
header.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
header.BorderSizePixel = 0
header.ZIndex = 3
header.Parent = frame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 22)

local headerCover = Instance.new("Frame")
headerCover.Size = UDim2.new(1, 0, 0, 28)
headerCover.Position = UDim2.new(0, 0, 1, -28)
headerCover.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
headerCover.BorderSizePixel = 0
headerCover.ZIndex = 3
headerCover.Parent = header

-- EAM badge with gradient
local badge = Instance.new("Frame")
badge.Size = UDim2.fromOffset(50, 50)
badge.Position = UDim2.fromOffset(14, 12)
badge.BackgroundColor3 = Color3.fromRGB(150, 90, 255)
badge.BorderSizePixel = 0
badge.ZIndex = 4
badge.Parent = header
Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 14)

local badgeGrad = Instance.new("UIGradient")
badgeGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 70, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 90, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 160, 255)),
}
badgeGrad.Rotation = 135
badgeGrad.Parent = badge

local badgeText = Instance.new("TextLabel")
badgeText.Size = UDim2.fromScale(1, 1)
badgeText.BackgroundTransparency = 1
badgeText.Text = "EAM"
badgeText.TextColor3 = Color3.fromRGB(255, 255, 255)
badgeText.Font = Enum.Font.GothamBlack
badgeText.TextSize = 16
badgeText.ZIndex = 5
badgeText.Parent = badge

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -160, 0, 26)
title.Position = UDim2.fromOffset(76, 12)
title.BackgroundTransparency = 1
title.Text = "EAM"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 4
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -160, 0, 16)
subtitle.Position = UDim2.fromOffset(76, 38)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Muscle Legends  •  v1"
subtitle.TextColor3 = Color3.fromRGB(150, 150, 180)
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextSize = 11
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 4
subtitle.Parent = header

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.fromOffset(32, 32)
minBtn.Position = UDim2.new(1, -44, 0, 20)
minBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
minBtn.BorderSizePixel = 0
minBtn.Text = "–"
minBtn.TextColor3 = Color3.fromRGB(220, 220, 235)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 20
minBtn.ZIndex = 4
minBtn.Parent = header
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 8)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -92)
scroll.Position = UDim2.fromOffset(10, 84)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(150, 90, 255)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ZIndex = 3
scroll.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

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

local function makeToggle(labelText, key, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 48)
    btn.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.ZIndex = 4
    btn.Parent = scroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 1, -20)
    accent.Position = UDim2.fromOffset(10, 10)
    accent.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    accent.BorderSizePixel = 0
    accent.ZIndex = 5
    accent.Parent = btn
    Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 2)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -100, 1, 0)
    label.Position = UDim2.fromOffset(24, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(230, 230, 245)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 5
    label.Parent = btn

    local pill = Instance.new("Frame")
    pill.Size = UDim2.fromOffset(48, 24)
    pill.Position = UDim2.new(1, -58, 0.5, -12)
    pill.BackgroundColor3 = Color3.fromRGB(38, 38, 52)
    pill.BorderSizePixel = 0
    pill.ZIndex = 5
    pill.Parent = btn
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(18, 18)
    knob.Position = UDim2.fromOffset(3, 3)
    knob.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    knob.BorderSizePixel = 0
    knob.ZIndex = 6
    knob.Parent = pill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function animate(on)
        TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad),
            { Position = on and UDim2.fromOffset(27, 3) or UDim2.fromOffset(3, 3),
              BackgroundColor3 = on and Color3.fromRGB(255, 255, 255)
                                      or Color3.fromRGB(100, 100, 120) }):Play()
        TweenService:Create(pill, TweenInfo.new(0.18),
            { BackgroundColor3 = on and Color3.fromRGB(150, 90, 255)
                                    or Color3.fromRGB(38, 38, 52) }):Play()
        TweenService:Create(accent, TweenInfo.new(0.18),
            { BackgroundColor3 = on and Color3.fromRGB(150, 90, 255)
                                    or Color3.fromRGB(60, 60, 80) }):Play()
    end

    bindButton(btn, function()
        flags[key] = not flags[key]
        animate(flags[key])
        if callback then callback() end
    end)
end

local function sectionHeader(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -8, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Text = "— " .. text:upper() .. " —"
    lbl.TextColor3 = Color3.fromRGB(160, 100, 255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4
    lbl.Parent = scroll
end

sectionHeader("Training")
makeToggle("Auto Lift", "autoLift")

sectionHeader("Movement")
makeToggle("Speed", "speed", applySpeed)
makeToggle("Noclip", "noclip", applyNoclip)
makeToggle("Infinite Jump", "infiniteJump")
makeToggle("Fly", "fly", function()
    if flags.fly then startFly() else stopFly() end
end)
makeToggle("Anti Fling", "antiFling")

sectionHeader("Visual")
makeToggle("Fullbright", "fullbright", applyLighting)
makeToggle("No Fog", "noFog", applyLighting)
makeToggle("FPS Boost", "fpsBoost", applyLighting)

sectionHeader("Progress")
makeToggle("Auto Rebirth", "autoRebirth")
makeToggle("Auto Buy Pet", "autoBuyPet")

local expanded = true
bindButton(minBtn, function()
    expanded = not expanded
    for _, child in ipairs(frame:GetChildren()) do
        if child ~= header and child ~= stroke then
            child.Visible = expanded
        end
    end
    frame.Size = expanded and UDim2.fromOffset(320, 530)
                          or UDim2.fromOffset(320, 74)
    glow.Size  = expanded and UDim2.fromOffset(330, 540)
                          or UDim2.fromOffset(330, 84)
    minBtn.Text = expanded and "–" or "+"
end)

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
        local newPos = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        frame.Position = newPos
        glow.Position = UDim2.new(
            newPos.X.Scale, newPos.X.Offset - 5,
            newPos.Y.Scale, newPos.Y.Offset - 5)
    end
end)
header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        gui.Enabled = not gui.Enabled
    end
end)

print("[EAM] loaded")
