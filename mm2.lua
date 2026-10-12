-- language: Lua, file: mm2_mobile.lua, target: Delta Executor Mobile / Murder Mystery 2
-- *smooth farm fly + dual AutoKill (Murderer & Sheriff) + cooler UI + more OP*

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Settings = {
    ESP = true,
    AutoFarm = false,
    AutoKill = false,
    KillAura = false,
    GrabGun = true,
    CoinESP = false,
    GunESP = true,
    Fly = false,
    InfJump = false,
    Noclip = false,
    Speed = 16,
    FarmSpeed = 55,
    ESPColor = {
        Murderer = Color3.fromRGB(255, 55, 55),
        Sheriff = Color3.fromRGB(55, 160, 255),
        Innocent = Color3.fromRGB(80, 255, 130)
    }
}

local ESPObjects = {}
local CoinESPFolder = Instance.new("Folder", Workspace)
CoinESPFolder.Name = "CoinESPs"
local GunESPFolder = Instance.new("Folder", Workspace)
GunESPFolder.Name = "GunESPs"

-- ========== COOLER UI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 155, 0, 410)
Main.Position = UDim2.new(0, 12, 0.5, -205)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
Main.BackgroundTransparency = 0.08
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 14)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(55, 55, 65)
Stroke.Thickness = 1.2
Stroke.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 34)
Title.BackgroundTransparency = 1
Title.Text = "MM2"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 16
Title.Parent = Main

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -36, 0, 2)
MinBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MinBtn.Text = "–"
MinBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 18
MinBtn.Parent = Main
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -24, 0, 1)
Divider.Position = UDim2.new(0, 12, 0, 34)
Divider.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
Divider.BorderSizePixel = 0
Divider.Parent = Main

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Main.Size = minimized and UDim2.new(0, 155, 0, 38) or UDim2.new(0, 155, 0, 410)
    MinBtn.Text = minimized and "+" or "–"
    for _, c in pairs(Main:GetChildren()) do
        if c:IsA("TextButton") and c ~= MinBtn then c.Visible = not minimized end
    end
    Divider.Visible = not minimized
end)

local function MakeToggle(name, y, default, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -18, 0, 31)
    btn.Position = UDim2.new(0, 9, 0, y)
    btn.BackgroundColor3 = default and Color3.fromRGB(0, 130, 70) or Color3.fromRGB(20, 20, 24)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = Main
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 9)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -48, 1, 0)
    label.Position = UDim2.new(0, 11, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(235, 235, 240)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = btn

    local state = Instance.new("TextLabel")
    state.Size = UDim2.new(0, 34, 1, 0)
    state.Position = UDim2.new(1, -40, 0, 0)
    state.BackgroundTransparency = 1
    state.Text = default and "ON" or "OFF"
    state.TextColor3 = default and Color3.fromRGB(140, 255, 170) or Color3.fromRGB(130, 130, 140)
    state.Font = Enum.Font.GothamBold
    state.TextSize = 11
    state.Parent = btn

    local on = default
    btn.MouseButton1Click:Connect(function()
        on = not on
        state.Text = on and "ON" or "OFF"
        state.TextColor3 = on and Color3.fromRGB(140, 255, 170) or Color3.fromRGB(130, 130, 140)
        btn.BackgroundColor3 = on and Color3.fromRGB(0, 130, 70) or Color3.fromRGB(20, 20, 24)
        callback(on)
    end)
end

MakeToggle("ESP", 42, true, function(v) Settings.ESP = v end)
MakeToggle("Auto Farm", 76, false, function(v) Settings.AutoFarm = v end)
MakeToggle("Auto Kill", 110, false, function(v) Settings.AutoKill = v end)
MakeToggle("Kill Aura", 144, false, function(v) Settings.KillAura = v end)
MakeToggle("Grab Gun", 178, true, function(v) Settings.GrabGun = v end)
MakeToggle("Coin ESP", 212, false, function(v) Settings.CoinESP = v end)
MakeToggle("Gun ESP", 246, true, function(v) Settings.GunESP = v end)
MakeToggle("Fly", 280, false, function(v) Settings.Fly = v ToggleFly(v) end)
MakeToggle("Inf Jump", 314, false, function(v) Settings.InfJump = v end)
MakeToggle("Noclip", 348, false, function(v) Settings.Noclip = v ToggleNoclip(v) end)

local SpeedBtn = Instance.new("TextButton")
SpeedBtn.Size = UDim2.new(1, -18, 0, 31)
SpeedBtn.Position = UDim2.new(0, 9, 0, 382)
SpeedBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
SpeedBtn.Text = ""
SpeedBtn.AutoButtonColor = false
SpeedBtn.Parent = Main
Instance.new("UICorner", SpeedBtn).CornerRadius = UDim.new(0, 9)

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -48, 1, 0)
speedLabel.Position = UDim2.new(0, 11, 0, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed"
speedLabel.TextColor3 = Color3.fromRGB(235, 235, 240)
speedLabel.Font = Enum.Font.GothamMedium
speedLabel.TextSize = 12
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = SpeedBtn

local speedValue = Instance.new("TextLabel")
speedValue.Size = UDim2.new(0, 34, 1, 0)
speedValue.Position = UDim2.new(1, -40, 0, 0)
speedValue.BackgroundTransparency = 1
speedValue.Text = "16"
speedValue.TextColor3 = Color3.fromRGB(130, 130, 140)
speedValue.Font = Enum.Font.GothamBold
speedValue.TextSize = 11
speedValue.Parent = SpeedBtn

SpeedBtn.MouseButton1Click:Connect(function()
    Settings.Speed = Settings.Speed == 16 and 28 or 16
    speedValue.Text = tostring(Settings.Speed)
    speedValue.TextColor3 = Settings.Speed > 16 and Color3.fromRGB(140, 255, 170) or Color3.fromRGB(130, 130, 140)
    SpeedBtn.BackgroundColor3 = Settings.Speed > 16 and Color3.fromRGB(0, 130, 70) or Color3.fromRGB(20, 20, 24)
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

-- ========== HELPERS ==========
local function GetRole(player)
    local char = player.Character
    if not char then return "Unknown" end
    if char:FindFirstChild("Knife") or player.Backpack:FindFirstChild("Knife") then return "Murderer" end
    if char:FindFirstChild("Gun") or player.Backpack:FindFirstChild("Gun") then return "Sheriff" end
    return "Innocent"
end

local function CreateESP(player)
    if player == LocalPlayer or ESPObjects[player] then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "MM2ESP"
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 110, 0, 42)
    bb.StudsOffset = Vector3.new(0, 3.2, 0)
    bb.Parent = Workspace

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, 0, 0.5, 0)
    name.BackgroundTransparency = 1
    name.Text = player.Name
    name.TextColor3 = Color3.new(1,1,1)
    name.TextStrokeTransparency = 0.35
    name.Font = Enum.Font.GothamBold
    name.TextSize = 13
    name.Parent = bb

    local role = Instance.new("TextLabel")
    role.Size = UDim2.new(1, 0, 0.5, 0)
    role.Position = UDim2.new(0, 0, 0.5, 0)
    role.BackgroundTransparency = 1
    role.Text = "..."
    role.TextColor3 = Color3.new(1,1,1)
    role.TextStrokeTransparency = 0.35
    role.Font = Enum.Font.Gotham
    role.TextSize = 12
    role.Parent = bb

    ESPObjects[player] = {Billboard = bb, Name = name, Role = role}
end

local function RemoveESP(player)
    if ESPObjects[player] then
        ESPObjects[player].Billboard:Destroy()
        ESPObjects[player] = nil
    end
end

local function UpdateESP()
    for player, data in pairs(ESPObjects) do
        if player.Character and player.Character:FindFirstChild("Head") then
            data.Billboard.Adornee = player.Character.Head
            local role = GetRole(player)
            data.Role.Text = role
            data.Role.TextColor3 = Settings.ESPColor[role] or Color3.new(1,1,1)
            data.Billboard.Enabled = Settings.ESP
        end
    end
end

-- ========== FARM (smooth fly) ==========
local FarmBV
local function AutoFarm()
    if not Settings.AutoFarm then
        if FarmBV then FarmBV:Destroy() FarmBV = nil end
        return
    end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart

    local closest, dist = nil, math.huge
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v.Name == "Coin" or v.Name == "CoinPickup" or v.Name:lower() == "coin") then
            local d = (v.Position - hrp.Position).Magnitude
            if d < dist then
                dist = d
                closest = v
            end
        end
    end

    if closest then
        if not FarmBV then
            FarmBV = Instance.new("BodyVelocity")
            FarmBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            FarmBV.Parent = hrp
        end
        local dir = (closest.Position + Vector3.new(0, 2.5, 0) - hrp.Position).Unit
        FarmBV.Velocity = dir * Settings.FarmSpeed
    else
        if FarmBV then FarmBV.Velocity = Vector3.zero end
    end
end

-- ========== AUTO KILL (Murderer + Sheriff) ==========
local function AutoKill()
    if not Settings.AutoKill then return end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local myRole = GetRole(LocalPlayer)

    if myRole == "Murderer" then
        local knife = char:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
        if not knife then return end
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

        if nearest then
            -- fly to them
            hrp.CFrame = CFrame.new(nearest.Character.HumanoidRootPart.Position + Vector3.new(0, 1, 0))
            task.wait(0.05)
            knife:Activate()
            local remote = knife:FindFirstChildWhichIsA("RemoteEvent") or knife:FindFirstChild("Remote")
            if remote then
                pcall(function() remote:FireServer("Slash") end)
            end
        end

    elseif myRole == "Sheriff" then
        local gun = char:FindFirstChild("Gun") or LocalPlayer.Backpack:FindFirstChild("Gun")
        if not gun then return end
        if gun.Parent == LocalPlayer.Backpack then
            char.Humanoid:EquipTool(gun)
        end

        local nearest, dist = nil, math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and GetRole(p) == "Murderer" then
                local d = (p.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                if d < dist then
                    dist = d
                    nearest = p
                end
            end
        end

        if nearest then
            local remote = gun:FindFirstChildWhichIsA("RemoteEvent") or gun:FindFirstChild("Remote")
            if remote then
                pcall(function() remote:FireServer(nearest.Character.HumanoidRootPart.Position) end)
            end
        end
    end
end

local function KillAura()
    if not Settings.KillAura then return end
    local char = LocalPlayer.Character
    if not char then return end
    local knife = char:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
    if not knife then return end
    if knife.Parent == LocalPlayer.Backpack then
        char.Humanoid:EquipTool(knife)
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            if (p.Character.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude < 14 then
                knife:Activate()
                local remote = knife:FindFirstChildWhichIsA("RemoteEvent")
                if remote then pcall(function() remote:FireServer("Slash") end) end
            end
        end
    end
end

local function GrabGun()
    if not Settings.GrabGun then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Tool") and v.Name == "Gun" and v.Parent == Workspace then
            v.Parent = char
            break
        end
    end
end

-- Coin + Gun ESP
local function UpdateWorldESP()
    for _, c in pairs(CoinESPFolder:GetChildren()) do c:Destroy() end
    for _, c in pairs(GunESPFolder:GetChildren()) do c:Destroy() end

    if Settings.CoinESP then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and (v.Name == "Coin" or v.Name:lower() == "coin") then
                local bb = Instance.new("BillboardGui")
                bb.Size = UDim2.new(0, 30, 0, 30)
                bb.AlwaysOnTop = true
                bb.StudsOffset = Vector3.new(0, 1.2, 0)
                bb.Adornee = v
                bb.Parent = CoinESPFolder
                local l = Instance.new("TextLabel")
                l.Size = UDim2.new(1,0,1,0)
                l.BackgroundTransparency = 1
                l.Text = "●"
                l.TextColor3 = Color3.fromRGB(255, 215, 0)
                l.TextStrokeTransparency = 0.2
                l.Font = Enum.Font.GothamBold
                l.TextSize = 18
                l.Parent = bb
            end
        end
    end

    if Settings.GunESP then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("Tool") and v.Name == "Gun" and v.Parent == Workspace then
                local handle = v:FindFirstChild("Handle") or v:FindFirstChildWhichIsA("BasePart")
                if handle then
                    local bb = Instance.new("BillboardGui")
                    bb.Size = UDim2.new(0, 70, 0, 24)
                    bb.AlwaysOnTop = true
                    bb.StudsOffset = Vector3.new(0, 2, 0)
                    bb.Adornee = handle
                    bb.Parent = GunESPFolder
                    local l = Instance.new("TextLabel")
                    l.Size = UDim2.new(1,0,1,0)
                    l.BackgroundTransparency = 1
                    l.Text = "GUN"
                    l.TextColor3 = Color3.fromRGB(0, 255, 255)
                    l.TextStrokeTransparency = 0.2
                    l.Font = Enum.Font.GothamBold
                    l.TextSize = 14
                    l.Parent = bb
                end
            end
        end
    end
end

-- Noclip / Fly / InfJump
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

-- loops
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() task.wait(1) CreateESP(p) end)
end)
Players.PlayerRemoving:Connect(RemoveESP)

for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        CreateESP(p)
        p.CharacterAdded:Connect(function() task.wait(1) CreateESP(p) end)
    end
end

task.spawn(function()
    while true do
        AutoFarm()
        AutoKill()
        KillAura()
        GrabGun()
        UpdateWorldESP()
        task.wait(0.12)
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.4)
    if char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = Settings.Speed
    end
    if FarmBV then FarmBV:Destroy() FarmBV = nil end
end)

print("[MM2] farm flies + dual AutoKill + cooler UI loaded")
