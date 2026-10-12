-- language: Lua, file: muscle.lua, target: Pumpkin Muscle Legends
-- no blocking waits. poll in background. UI appears immediately.

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer

local MuscleEvent = LocalPlayer:FindFirstChild("MuscleEvent")
if MuscleEvent then
    print("[ML] MuscleEvent already present:", MuscleEvent:GetFullName())
end

task.spawn(function()
    while not MuscleEvent do
        MuscleEvent = LocalPlayer:FindFirstChild("MuscleEvent")
        if not MuscleEvent and LocalPlayer.Character then
            MuscleEvent = LocalPlayer.Character:FindFirstChild("MuscleEvent")
        end
        if MuscleEvent then
            print("[ML] MuscleEvent appeared:", MuscleEvent:GetFullName())
            break
        end
        task.wait(1)
    end
end)

local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
local petshopRemote = rEvents and rEvents:FindFirstChild("cPetshopRemote")
print("[ML] rEvents:", rEvents and "ok" or "MISS",
      "| cPetshopRemote:", petshopRemote and "ok" or "MISS")

local flags = {
    fastRep    = false,
    autoRebirth = false,
    autoBuyPet = false,
    petName    = "Green Aura",
    repDelay   = 0.05,
    rebirthDelay = 5,
    petDelay   = 1,
}

local function firePunch()
    local ev = MuscleEvent or LocalPlayer:FindFirstChild("MuscleEvent")
    if not ev then return end
    MuscleEvent = ev
    pcall(function() ev:FireServer("punch", "leftHand") end)
    pcall(function() ev:FireServer("punch", "rightHand") end)
end

task.spawn(function()
    while task.wait(flags.repDelay) do
        if flags.fastRep then firePunch() end
    end
end)

if rEvents and rEvents:FindFirstChild("rebirthRemote") then
    task.spawn(function()
        while task.wait(flags.rebirthDelay) do
            if flags.autoRebirth then
                pcall(function()
                    rEvents.rebirthRemote:InvokeServer("rebirthRequest")
                end)
            end
        end
    end)
end

if petshopRemote then
    task.spawn(function()
        while task.wait(flags.petDelay) do
            if flags.autoBuyPet then
                pcall(function()
                    petshopRemote:InvokeServer(flags.petName)
                end)
            end
        end
    end)
end

local gui = Instance.new("ScreenGui")
gui.Name = "MLOwn"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(280, 260)
frame.Position = UDim2.new(0.5, -140, 0, 80)
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
title.Text = "ML"
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

local function makeToggle(labelText, key)
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

sectionHeader("Training")
makeToggle("Fast Rep", "fastRep")
sectionHeader("Progress")
makeToggle("Auto Rebirth", "autoRebirth")
sectionHeader("Pets")
makeToggle("Auto Buy Pet", "autoBuyPet")

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

print("[ML] panel loaded")
