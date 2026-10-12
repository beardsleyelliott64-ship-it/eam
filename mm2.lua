-- language: Lua, file: mm2_mobile.lua, target: Delta Executor Mobile / Murder Mystery 2
-- *fixed farm + Kill Aura, Grab Gun, Role Notifier, Coin ESP, Fly, Infinite Jump, Minimize*

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local Settings = {
    ESP = true,
    AutoFarm = false,
    AutoKill = false,
    KillAura = false,
    GrabGun = false,
    CoinESP = false,
    Fly = false,
    InfJump = false,
    Noclip = false,
    Speed = 16,
    ESPColor = {
        Murderer = Color3.fromRGB(255, 50, 50),
        Sheriff = Color3.fromRGB(50, 150, 255),
        Innocent = Color3.fromRGB(80, 255, 120)
    }
}

local ESPObjects = {}
local CoinESPFolder = Instance.new("Folder")
CoinESPFolder.Name = "CoinESP"
CoinESPFolder.Parent = Workspace

-- ========== UI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 148, 0, 380)
Main.Position = UDim2.new(0, 12, 0.5, -190)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
Main.BackgroundTransparency = 0.05
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(40, 40, 45)
Stroke.Thickness = 1
Stroke.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 32)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "MM2"
Title.TextColor3 = Color3.fromRGB(240, 240, 240)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.Parent = Main

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -34, 0, 2)
MinBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MinBtn.Text = "–"
MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16
MinBtn.Parent = Main
local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinBtn

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -20, 0, 1)
Divider.Position = UDim2.new(0, 10, 0, 32)
Divider.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
Divider.BorderSizePixel = 0
Divider.Parent = Main

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        Main.Size = UDim2.new(0, 148, 0, 36)
        MinBtn.Text = "+"
        for _, child in pairs(Main:GetChildren()) do
            if child:IsA("TextButton") and child ~= MinBtn then
                child.Visible = false
            end
        end
        Divider.Visible = false
    else
        Main.Size = UDim2.new(0, 148, 0, 380)
        MinBtn.Text = "–"
        for _, child in pairs(Main:GetChildren()) do
            if child:IsA("TextButton") and child ~= MinBtn then
                child.Visible = true
            end
        end
        Divider.Visible = true
    end
end)

local function MakeToggle(name, y, default, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 30)
    btn.Position = UDim2.new(0, 8, 0, y)
    btn.BackgroundColor3 = default and Color3.fromRGB(0, 110, 55) or Color3.fromRGB(22, 22, 26)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = Main

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(230, 230, 230)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = btn

    local state = Instance.new("TextLabel")
    state.Size = UDim2.new(0, 36, 1, 0)
    state.Position = UDim2.new(1, -42, 0, 0)
    state.BackgroundTransparency = 1
    state.Text = default and "ON" or "OFF"
    state.TextColor3 = default and Color3.fromRGB(120, 255, 160) or Color3.fromRGB(140, 140, 140)
    state.Font = Enum.Font.GothamBold
    state.TextSize = 11
    state.Parent = btn

    local enabled = default
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        state.Text = enabled and "ON" or "OFF"
        state.TextColor3 = enabled and Color3.fromRGB(120, 255, 160) or Color3.fromRGB(140, 140, 140)
        btn.BackgroundColor3 = enabled and Color3.fromRGB(0, 110, 55) or Color3.fromRGB(22, 22, 26)
        callback(enabled)
    end)
    return btn
end

MakeToggle("ESP", 40, true, function(v) Settings.ESP = v end)
MakeToggle("Auto Farm", 74, false, function(v) Settings.AutoFarm = v end)
MakeToggle("Auto Kill", 108, false, function(v) Settings.AutoKill = v end)
MakeToggle("Kill Aura", 142, false, function(v) Settings.KillAura = v end)
MakeToggle("Grab Gun", 176, false, function(v) Settings.GrabGun = v end)
MakeToggle("Coin ESP", 210, false, function(v) Settings.CoinESP = v end)
MakeToggle("Fly", 244, false, function(v) Settings.Fly = v ToggleFly(v) end)
MakeToggle("Inf Jump", 278, false, function(v) Settings.InfJump = v end)
MakeToggle("Noclip", 312, false, function(v) Settings.Noclip = v ToggleNoclip(v) end)

local SpeedBtn = Instance.new("TextButton")
SpeedBtn.Size = UDim2.new(1, -16, 0, 30)
SpeedBtn.Position = UDim2.new(0, 8, 0, 346)
SpeedBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
SpeedBtn.Text = ""
SpeedBtn.AutoButtonColor = false
SpeedBtn.Parent = Main
local sc = Instance.new("UICorner")
sc.CornerRadius = UDim.new(0, 8)
sc.Parent = SpeedBtn

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -50, 1, 0)
speedLabel.Position = UDim2.new(0, 10, 0, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed"
speedLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
speedLabel.Font = Enum.Font.GothamMedium
speedLabel.TextSize = 12
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = SpeedBtn

local speedValue = Instance.new("TextLabel")
speedValue.Size = UDim2.new(0, 36, 1, 0)
speedValue.Position = UDim2.new(1, -42, 0, 0)
speedValue.BackgroundTransparency = 1
speedValue.Text = "16"
speedValue.TextColor3 = Color3.fromRGB(140, 140, 140)
speedValue.Font = Enum.Font.GothamBold
speedValue.TextSize = 11
speedValue.Parent = SpeedBtn

SpeedBtn.MouseButton1Click:Connect(function()
    Settings.Speed = Settings.Speed == 16 and 28 or 16
    speedValue.Text = tostring(Settings.Speed)
    speedValue.TextColor3 = Settings.Speed > 16 and Color3.fromRGB(120, 255, 160) or Color3.fromRGB(140, 140, 140)
    SpeedBtn.BackgroundColor3 = Settings.Speed > 16 and Color3.fromRGB(0, 110, 55) or Color3.fromRGB(22, 22, 26)
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

-- ========== ROLE NOTIFIER ==========
local NotifyGui = Instance.new("ScreenGui")
NotifyGui.Name = "RoleNotify"
NotifyGui.ResetOnSpawn = false
NotifyGui.Parent = game:GetService("CoreGui")

local NotifyLabel = Instance.new("TextLabel")
NotifyLabel.Size = UDim2.new(0, 280, 0, 50)
NotifyLabel.Position = UDim2.new(0.5, -140, 0.15, 0)
NotifyLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
NotifyLabel.BackgroundTransparency = 0.3
NotifyLabel.TextColor3 = Color3.new(1,1,1)
NotifyLabel.Font = Enum.Font.GothamBold
NotifyLabel.TextSize = 22
NotifyLabel.Visible = false
NotifyLabel.Parent = NotifyGui
local nc = Instance.new("UICorner")
nc.CornerRadius = UDim.new(0, 10)
nc.Parent = NotifyLabel

local lastRole = nil
local function CheckRole()
    local role = "Innocent"
    local char = LocalPlayer.Character
    if char then
        if char:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife") then
            role = "Murderer"
        elseif char:FindFirstChild("Gun") or LocalPlayer.Backpack:FindFirstChild("Gun") then
            role = "Sheriff"
        end
    end
    if role ~= lastRole and role ~= "Innocent" then
        lastRole = role
        NotifyLabel.Text = "You are " .. role
        NotifyLabel.TextColor3 = role == "Murderer" and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(60, 160, 255)
        NotifyLabel.Visible = true
        task.delay(3, function() NotifyLabel.Visible = false end)
    elseif role == "Innocent" then
        lastRole = "Innocent"
    end
end

-- ========== ESP ==========
local function CreateESP(player)
    if player == LocalPlayer or ESPObjects[player] then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "MM2ESP"
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 100, 0, 40)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.Parent = Workspace

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, 0, 0.5, 0)
    name.BackgroundTransparency = 1
    name.Text = player.Name
    name.TextColor3 = Color3.new(1,1,1)
    name.TextStrokeTransparency = 0.4
    name.Font = Enum.Font.GothamBold
    name.TextSize = 13
    name.Parent = bb

    local role = Instance.new("TextLabel")
    role.Size = UDim2.new(1, 0, 0.5, 0)
    role.Position = UDim2.new(0, 0, 0.5, 0)
    role.BackgroundTransparency = 1
    role.Text = "..."
    role.TextColor3 = Color3.new(1,1,1)
    role.TextStrokeTransparency = 0.4
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

local function GetRole(player)
    local char = player.Character
    if not char then return "Unknown" end
    if char:FindFirstChild("Knife") or player.Backpack:FindFirstChild("Knife") then return "Murderer" end
    if char:FindFirstChild("Gun") or player.Backpack:FindFirstChild("Gun") then return "Sheriff" end
    return "Innocent"
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

-- ========== COIN ESP ==========
local function UpdateCoinESP()
    for _, child in pairs(CoinESPFolder:GetChildren()) do
        child:Destroy()
    end
    if not Settings.CoinESP then return end
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v.Name == "Coin" or v.Name == "CoinPickup" or v.Name:lower() == "coin") then
            local bb = Instance.new("BillboardGui")
            bb.Size = UDim2.new(0, 40, 0, 20)
            bb.AlwaysOnTop = true
            bb.StudsOffset = Vector3.new(0, 1.5, 0)
            bb.Adornee = v
            bb.Parent = CoinESPFolder
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = "●"
            lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
            lbl.TextStrokeTransparency = 0.3
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 16
            lbl.Parent = bb
        end
    end
end

-- ========== FEATURES ==========
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

-- fixed Auto Farm
local function AutoFarm()
    if not Settings.AutoFarm then return end
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
        hrp.CFrame = CFrame.new(closest.Position + Vector3.new(0, 3, 0))
    end
end

local function AutoKill()
    if not Settings.AutoKill then return end
    local char = LocalPlayer.Character
    if not char then return end
    local gun = char:FindFirstChild("Gun") or LocalPlayer.Backpack:FindFirstChild("Gun")
    if not gun then return end
    local nearest, dist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and GetRole(p) == "Murderer" then
            local d = (p.Character.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude
            if d < dist then dist = d nearest = p end
        end
    end
    if nearest then
        if gun.Parent == LocalPlayer.Backpack then char.Humanoid:EquipTool(gun) end
        local remote = gun:FindFirstChild("Remote") or gun:FindFirstChildWhichIsA("RemoteEvent")
        if remote then
            remote:FireServer(nearest.Character.HumanoidRootPart.Position)
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
            local d = (p.Character.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude
            if d < 12 then
                -- activate knife (common MM2 pattern)
                knife:Activate()
                local remote = knife:FindFirstChild("Remote") or knife:FindFirstChildWhichIsA("RemoteEvent")
                if remote then
                    remote:FireServer("Slash")
                end
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

-- Inf Jump
UserInputService.JumpRequest:Connect(function()
    if Settings.InfJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Fly movement
RunService.RenderStepped:Connect(function()
    if Settings.Fly and FlyBV and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local cam = Workspace.CurrentCamera
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) or true then -- mobile uses thumbstick, simplified
            dir = cam.CFrame.LookVector
        end
        FlyBV.Velocity = dir * 50
        if FlyBG then
            FlyBG.CFrame = cam.CFrame
        end
    end
end)

-- ========== LOOPS ==========
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

RunService.RenderStepped:Connect(function()
    UpdateESP()
    CheckRole()
end)

task.spawn(function()
    while true do
        AutoFarm()
        AutoKill()
        KillAura()
        GrabGun()
        UpdateCoinESP()
        task.wait(0.15)
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.4)
    if char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = Settings.Speed
    end
    lastRole = nil
end)

print("[MM2] updated — farm fixed + new features")
