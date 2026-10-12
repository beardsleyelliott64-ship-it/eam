-- language: Lua, file: mm2_mobile.lua, target: Delta Mobile / Murder Mystery 2
-- *fixed double ESP + wider cooler UI + reliable farm/kill*

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Settings = {
    ESP = true,
    AutoFarm = false,
    AutoKill = false,
    GrabGun = true,
    Fly = false,
    InfJump = false,
    Noclip = false,
    Speed = 16,
    FarmSpeed = 0.35, -- tween time
    ESPColor = {
        Murderer = Color3.fromRGB(255, 60, 60),
        Sheriff = Color3.fromRGB(60, 160, 255),
        Innocent = Color3.fromRGB(90, 255, 140)
    }
}

local ESPObjects = {}

-- ========== COOLER WIDER UI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 190, 0, 360)
Main.Position = UDim2.new(0, 14, 0.5, -180)
Main.BackgroundColor3 = Color3.fromRGB(11, 11, 14)
Main.BackgroundTransparency = 0.05
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 16)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(70, 70, 85)
Stroke.Thickness = 1.4
Stroke.Parent = Main

-- soft glow animation
task.spawn(function()
    while Main and Main.Parent do
        TweenService:Create(Stroke, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Color = Color3.fromRGB(100, 100, 130)
        }):Play()
        task.wait(1.8)
        TweenService:Create(Stroke, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Color = Color3.fromRGB(55, 55, 70)
        }):Play()
        task.wait(1.8)
    end
end)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 0, 36)
Title.BackgroundTransparency = 1
Title.Text = "MM2"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 18
Title.Parent = Main

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 32, 0, 32)
MinBtn.Position = UDim2.new(1, -40, 0, 2)
MinBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
MinBtn.Text = "–"
MinBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 18
MinBtn.Parent = Main
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 9)

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -28, 0, 1)
Divider.Position = UDim2.new(0, 14, 0, 38)
Divider.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
Divider.BorderSizePixel = 0
Divider.Parent = Main

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Main.Size = minimized and UDim2.new(0, 190, 0, 40) or UDim2.new(0, 190, 0, 360)
    MinBtn.Text = minimized and "+" or "–"
    for _, c in pairs(Main:GetChildren()) do
        if c:IsA("TextButton") and c ~= MinBtn then
            c.Visible = not minimized
        end
    end
    Divider.Visible = not minimized
end)

local function MakeToggle(name, y, default, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -22, 0, 33)
    btn.Position = UDim2.new(0, 11, 0, y)
    btn.BackgroundColor3 = default and Color3.fromRGB(0, 135, 75) or Color3.fromRGB(22, 22, 28)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = Main
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -55, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(240, 240, 245)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = btn

    local state = Instance.new("TextLabel")
    state.Size = UDim2.new(0, 38, 1, 0)
    state.Position = UDim2.new(1, -44, 0, 0)
    state.BackgroundTransparency = 1
    state.Text = default and "ON" or "OFF"
    state.TextColor3 = default and Color3.fromRGB(150, 255, 180) or Color3.fromRGB(140, 140, 150)
    state.Font = Enum.Font.GothamBold
    state.TextSize = 12
    state.Parent = btn

    local on = default
    btn.MouseButton1Click:Connect(function()
        on = not on
        state.Text = on and "ON" or "OFF"
        state.TextColor3 = on and Color3.fromRGB(150, 255, 180) or Color3.fromRGB(140, 140, 150)
        btn.BackgroundColor3 = on and Color3.fromRGB(0, 135, 75) or Color3.fromRGB(22, 22, 28)
        callback(on)
    end)
end

MakeToggle("ESP", 48, true, function(v) Settings.ESP = v end)
MakeToggle("Auto Farm", 86, false, function(v) Settings.AutoFarm = v end)
MakeToggle("Auto Kill", 124, false, function(v) Settings.AutoKill = v end)
MakeToggle("Grab Gun", 162, true, function(v) Settings.GrabGun = v end)
MakeToggle("Fly", 200, false, function(v) Settings.Fly = v ToggleFly(v) end)
MakeToggle("Inf Jump", 238, false, function(v) Settings.InfJump = v end)
MakeToggle("Noclip", 276, false, function(v) Settings.Noclip = v ToggleNoclip(v) end)

local SpeedBtn = Instance.new("TextButton")
SpeedBtn.Size = UDim2.new(1, -22, 0, 33)
SpeedBtn.Position = UDim2.new(0, 11, 0, 314)
SpeedBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
SpeedBtn.Text = ""
SpeedBtn.AutoButtonColor = false
SpeedBtn.Parent = Main
Instance.new("UICorner", SpeedBtn).CornerRadius = UDim.new(0, 10)

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -55, 1, 0)
speedLabel.Position = UDim2.new(0, 12, 0, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed"
speedLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
speedLabel.Font = Enum.Font.GothamMedium
speedLabel.TextSize = 13
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = SpeedBtn

local speedValue = Instance.new("TextLabel")
speedValue.Size = UDim2.new(0, 38, 1, 0)
speedValue.Position = UDim2.new(1, -44, 0, 0)
speedValue.BackgroundTransparency = 1
speedValue.Text = "16"
speedValue.TextColor3 = Color3.fromRGB(140, 140, 150)
speedValue.Font = Enum.Font.GothamBold
speedValue.TextSize = 12
speedValue.Parent = SpeedBtn

SpeedBtn.MouseButton1Click:Connect(function()
    Settings.Speed = Settings.Speed == 16 and 28 or 16
    speedValue.Text = tostring(Settings.Speed)
    speedValue.TextColor3 = Settings.Speed > 16 and Color3.fromRGB(150, 255, 180) or Color3.fromRGB(140, 140, 150)
    SpeedBtn.BackgroundColor3 = Settings.Speed > 16 and Color3.fromRGB(0, 135, 75) or Color3.fromRGB(22, 22, 28)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = Settings.Speed
    end
end)

-- drag
local dragging, dragStart, startPos
Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ========== ESP (fixed double name) ==========
local function ClearESP(player)
    if ESPObjects[player] then
        ESPObjects[player]:Destroy()
        ESPObjects[player] = nil
    end
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    ClearESP(player) -- prevent doubles

    local bb = Instance.new("BillboardGui")
    bb.Name = "MM2ESP"
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 120, 0, 40)
    bb.StudsOffset = Vector3.new(0, 3.3, 0)
    bb.Parent = Workspace

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, 0, 0.5, 0)
    name.BackgroundTransparency = 1
    name.Text = player.Name
    name.TextColor3 = Color3.new(1, 1, 1)
    name.TextStrokeTransparency = 0.3
    name.Font = Enum.Font.GothamBold
    name.TextSize = 13
    name.Parent = bb

    local role = Instance.new("TextLabel")
    role.Size = UDim2.new(1, 0, 0.5, 0)
    role.Position = UDim2.new(0, 0, 0.5, 0)
    role.BackgroundTransparency = 1
    role.Text = "..."
    role.TextColor3 = Color3.new(1, 1, 1)
    role.TextStrokeTransparency = 0.3
    role.Font = Enum.Font.Gotham
    role.TextSize = 12
    role.Parent = bb

    ESPObjects[player] = bb
end

local function GetRole(player)
    local char = player.Character
    if not char then return "Unknown" end
    if char:FindFirstChild("Knife") or player.Backpack:FindFirstChild("Knife") then return "Murderer" end
    if char:FindFirstChild("Gun") or player.Backpack:FindFirstChild("Gun") then return "Sheriff" end
    return "Innocent"
end

local function UpdateESP()
    for player, bb in pairs(ESPObjects) do
        if player.Character and player.Character:FindFirstChild("Head") then
            bb.Adornee = player.Character.Head
            local role = GetRole(player)
            local roleLabel = bb:FindFirstChildWhichIsA("TextLabel", true)
            -- second label is role
            local labels = {}
            for _, l in pairs(bb:GetChildren()) do
                if l:IsA("TextLabel") then table.insert(labels, l) end
            end
            if labels[2] then
                labels[2].Text = role
                labels[2].TextColor3 = Settings.ESPColor[role] or Color3.new(1,1,1)
            end
            bb.Enabled = Settings.ESP
        end
    end
end

-- ========== FEATURES ==========
local function AutoFarm()
    if not Settings.AutoFarm then return end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart

    local closest, dist = nil, math.huge
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v.Name == "Coin" or v.Name == "CoinPickup" or v.Name:lower():find("coin")) then
            local d = (v.Position - hrp.Position).Magnitude
            if d < dist and d > 1 then
                dist = d
                closest = v
            end
        end
    end

    if closest then
        local tween = TweenService:Create(hrp, TweenInfo.new(Settings.FarmSpeed, Enum.EasingStyle.Linear), {
            CFrame = CFrame.new(closest.Position + Vector3.new(0, 3, 0))
        })
        tween:Play()
        tween.Completed:Wait()
    end
end

local function AutoKill()
    if not Settings.AutoKill then return end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart

    local knife = char:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
    if knife then
        if knife.Parent == LocalPlayer.Backpack then
            char.Humanoid:EquipTool(knife)
        end
        local nearest, dist = nil, math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local d = (p.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                if d < dist then
                    dist = d
                    nearest = p
                end
            end
        end
        if nearest and dist < 80 then
            hrp.CFrame = CFrame.new(nearest.Character.HumanoidRootPart.Position + Vector3.new(0, 1, 0))
            task.wait(0.06)
            knife:Activate()
        end
        return
    end

    -- sheriff
    local gun = char:FindFirstChild("Gun") or LocalPlayer.Backpack:FindFirstChild("Gun")
    if gun then
        if gun.Parent == LocalPlayer.Backpack then
            char.Humanoid:EquipTool(gun)
        end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and GetRole(p) == "Murderer" then
                local remote = gun:FindFirstChildWhichIsA("RemoteEvent")
                if remote then
                    pcall(function() remote:FireServer(p.Character.HumanoidRootPart.Position) end)
                end
                break
            end
        end
    end
end

local function GrabGun()
    if not Settings.GrabGun then return end
    local char = LocalPlayer.Character
    if not char then return end

    -- common drop locations
    local drop = Workspace:FindFirstChild("GunDrop")
    if drop then
        for _, v in pairs(drop:GetDescendants()) do
            if v:IsA("Tool") and v.Name == "Gun" then
                v.Parent = char
                return
            end
        end
    end
    for _, v in pairs(Workspace:GetChildren()) do
        if v:IsA("Tool") and v.Name == "Gun" then
            v.Parent = char
            return
        end
    end
end

local NoclipConnection
function ToggleNoclip(state)
    if NoclipConnection then NoclipConnection:Disconnect() NoclipConnection = nil end
    if state then
        NoclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, p in pairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    end
end

local FlyBV, FlyBG
function ToggleFly(state)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    if FlyBV then FlyBV:Destroy() FlyBV = nil end
    if FlyBG then FlyBG:Destroy() FlyBG = nil end
    if state then
        FlyBV = Instance.new("BodyVelocity")
        FlyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        FlyBV.Velocity = Vector3.zero
        FlyBV.Parent = hrp
        FlyBG = Instance.new("BodyGyro")
        FlyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        FlyBG.P = 9e4
        FlyBG.Parent = hrp
        char.Humanoid.PlatformStand = true
    else
        if char.Humanoid then char.Humanoid.PlatformStand = false end
    end
end

UserInputService.JumpRequest:Connect(function()
    if Settings.InfJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

RunService.RenderStepped:Connect(function()
    if Settings.Fly and FlyBV and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local cam = Workspace.CurrentCamera
        FlyBV.Velocity = cam.CFrame.LookVector * 60
        if FlyBG then FlyBG.CFrame = cam.CFrame end
    end
    UpdateESP()
end)

-- clean player handling
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.8)
        CreateESP(p)
    end)
end)
Players.PlayerRemoving:Connect(ClearESP)

for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        CreateESP(p)
        p.CharacterAdded:Connect(function()
            task.wait(0.8)
            CreateESP(p)
        end)
    end
end

task.spawn(function()
    while true do
        if Settings.AutoFarm then AutoFarm() end
        if Settings.AutoKill then AutoKill() end
        if Settings.GrabGun then GrabGun() end
        task.wait(0.2)
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = Settings.Speed
    end
end)

print("[MM2] fixed double ESP + wider cooler UI loaded")
