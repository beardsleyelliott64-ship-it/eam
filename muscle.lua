if game.PlaceId ~= 155615604 then
    warn("[ML] not in Muscle Legends")
    return
end

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer

local MuscleEvent = LocalPlayer:FindFirstChild("MuscleEvent")
    or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("MuscleEvent"))

local rEvents = ReplicatedStorage:WaitForChild("rEvents", 10)

if not MuscleEvent then
    warn("[ML] MuscleEvent not found — are you in the game?")
    return
end

if not rEvents then
    warn("[ML] rEvents folder not found")
    return
end

local flags = {
    fastRep      = false,
    autoRebirth  = false,
    autoCrystal  = false,
    crystalType  = "Blue Crystal",
    repDelay     = 0.05,
    rebirthDelay = 5,
    crystalDelay = 1,
}

local rocks = {
    "Rock", "Magma Rock", "Legendary Rock",
    "Eternal Rock", "Mythical Rock"
}

local function firePunch()
    pcall(function() MuscleEvent:FireServer("punch", "leftHand") end)
    pcall(function() MuscleEvent:FireServer("punch", "rightHand") end)

    local machines = workspace:FindFirstChild("Machines")
    if machines then
        for _, name in ipairs(rocks) do
            local rock = machines:FindFirstChild(name)
            if rock then
                pcall(function() MuscleEvent:FireServer("punch", rock) end)
            end
        end
    end
end

task.spawn(function()
    while task.wait(flags.repDelay) do
        if flags.fastRep then
            firePunch()
        end
    end
end)

if rEvents:FindFirstChild("rebirthRemote") then
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

if rEvents:FindFirstChild("openCrystalRemote") then
    task.spawn(function()
        while task.wait(flags.crystalDelay) do
            if flags.autoCrystal then
                pcall(function()
                    rEvents.openCrystalRemote:InvokeServer(
                        "openCrystalRequest",
                        flags.crystalType
                    )
                end)
            end
        end
    end)
end

local gui = Instance.new("ScreenGui")
gui.Name = "MLOwn"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(260, 220)
frame.Position = UDim2.fromOffset(20, 20)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundTransparency = 1
title.Text = "ML — own build"
title.TextColor3 = Color3.fromRGB(240, 240, 245)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = frame

local function makeToggle(labelText, key, yPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -24, 0, 32)
    btn.Position = UDim2.new(0, 12, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    btn.BorderSizePixel = 0
    btn.Text = labelText .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(200, 200, 210)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        flags[key] = not flags[key]
        btn.Text = labelText .. ": " .. (flags[key] and "ON" or "OFF")
        btn.BackgroundColor3 = flags[key]
            and Color3.fromRGB(80, 120, 220)
            or Color3.fromRGB(45, 45, 55)
    end)
    return btn
end

makeToggle("Fast Rep",     "fastRep",     40)
makeToggle("Auto Rebirth", "autoRebirth", 80)
makeToggle("Auto Crystal", "autoCrystal", 120)

local crystalBtn = Instance.new("TextButton")
crystalBtn.Size = UDim2.new(1, -24, 0, 32)
crystalBtn.Position = UDim2.new(0, 12, 0, 160)
crystalBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
crystalBtn.BorderSizePixel = 0
crystalBtn.Text = "Crystal: " .. flags.crystalType
crystalBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
crystalBtn.Font = Enum.Font.Gotham
crystalBtn.TextSize = 12
crystalBtn.Parent = frame
Instance.new("UICorner", crystalBtn).CornerRadius = UDim.new(0, 6)

local crystalCycle = {
    "Blue Crystal", "Green Crystal", "Mythical Crystal",
    "Frost Crystal", "Inferno Crystal", "Legends Crystal",
    "Muscle Elite Crystal"
}
local crystalIndex = 1

crystalBtn.MouseButton1Click:Connect(function()
    crystalIndex = crystalIndex % #crystalCycle + 1
    flags.crystalType = crystalCycle[crystalIndex]
    crystalBtn.Text = "Crystal: " .. flags.crystalType
end)

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
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
title.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

print("[ML] own build loaded")