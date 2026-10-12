local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer

local MuscleEvent
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if not MuscleEvent and (method == "FireServer" or method == "InvokeServer") then
        if self.Name == "MuscleEvent" then
            MuscleEvent = self
        end
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

print("[ML] hook installed — punch once to capture MuscleEvent")

for _ = 1, 150 do
    if MuscleEvent then break end
    task.wait(0.1)
end

if not MuscleEvent then
    warn("[ML] MuscleEvent never fired — punch once and re-run")
    return
end
print("[ML] captured:", MuscleEvent:GetFullName())

local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
local petshopRemote = rEvents and rEvents:FindFirstChild("cPetshopRemote")
if petshopRemote then
    print("[ML] cPetshopRemote found")
end

local flags = {
    fastRep      = false,
    autoRebirth  = false,
    autoBuyPet   = false,
    petName      = "Green Aura",
    repDelay     = 0.05,
    rebirthDelay = 5,
    petDelay     = 1,
}

local function firePunch()
    pcall(function() MuscleEvent:FireServer("punch", "leftHand") end)
    pcall(function() MuscleEvent:FireServer("punch", "rightHand") end)
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
makeToggle("Auto Buy Pet", "autoBuyPet",  120)

local petBtn = Instance.new("TextButton")
petBtn.Size = UDim2.new(1, -24, 0, 32)
petBtn.Position = UDim2.new(0, 12, 0, 160)
petBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
petBtn.BorderSizePixel = 0
petBtn.Text = "Pet: " .. flags.petName
petBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
petBtn.Font = Enum.Font.Gotham
petBtn.TextSize = 12
petBtn.Parent = frame
Instance.new("UICorner", petBtn).CornerRadius = UDim.new(0, 6)

local petCycle = {
    "Green Aura", "Blue Aura", "Red Aura", "Purple Aura",
    "Gold Aura", "Rainbow Aura", "Legendary Aura"
}
local petIndex = 1

petBtn.MouseButton1Click:Connect(function()
    petIndex = petIndex % #petCycle + 1
    flags.petName = petCycle[petIndex]
    petBtn.Text = "Pet: " .. flags.petName
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

print("[ML] loaded — MuscleEvent at " .. MuscleEvent:GetFullName())
