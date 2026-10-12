-- language: Lua, file: mm2_mobile.lua, target: Delta Executor Mobile / Murder Mystery 2
-- *on-screen toggle buttons, no keyboard required*

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
    Noclip = false,
    Speed = 16,
    ESPColor = {
        Murderer = Color3.fromRGB(255, 0, 0),
        Sheriff = Color3.fromRGB(0, 150, 255),
        Innocent = Color3.fromRGB(0, 255, 0),
        Knife = Color3.fromRGB(255, 100, 0),
        Gun = Color3.fromRGB(0, 255, 255)
    }
}

local ESPObjects = {}

-- ========== MOBILE UI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2MobileUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

local Frame = Instance.new("Frame")
Frame.Name = "Main"
Frame.Size = UDim2.new(0, 160, 0, 220)
Frame.Position = UDim2.new(0, 15, 0.5, -110)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Frame.BackgroundTransparency = 0.15
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 28)
Title.BackgroundTransparency = 1
Title.Text = "MM2 Delta"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = Frame

local function CreateButton(name, y, callback)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(1, -16, 0, 32)
    btn.Position = UDim2.new(0, 8, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    btn.Text = name .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.Parent = Frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        callback(btn)
    end)
    return btn
end

local ESPBtn = CreateButton("ESP", 34, function(btn)
    Settings.ESP = not Settings.ESP
    btn.Text = "ESP: " .. (Settings.ESP and "ON" or "OFF")
    btn.BackgroundColor3 = Settings.ESP and Color3.fromRGB(0, 120, 60) or Color3.fromRGB(40, 40, 50)
end)

local FarmBtn = CreateButton("AutoFarm", 72, function(btn)
    Settings.AutoFarm = not Settings.AutoFarm
    btn.Text = "AutoFarm: " .. (Settings.AutoFarm and "ON" or "OFF")
    btn.BackgroundColor3 = Settings.AutoFarm and Color3.fromRGB(0, 120, 60) or Color3.fromRGB(40, 40, 50)
end)

local KillBtn = CreateButton("AutoKill", 110, function(btn)
    Settings.AutoKill = not Settings.AutoKill
    btn.Text = "AutoKill: " .. (Settings.AutoKill and "ON" or "OFF")
    btn.BackgroundColor3 = Settings.AutoKill and Color3.fromRGB(0, 120, 60) or Color3.fromRGB(40, 40, 50)
end)

local NoclipBtn = CreateButton("Noclip", 148, function(btn)
    Settings.Noclip = not Settings.Noclip
    btn.Text = "Noclip: " .. (Settings.Noclip and "ON" or "OFF")
    btn.BackgroundColor3 = Settings.Noclip and Color3.fromRGB(0, 120, 60) or Color3.fromRGB(40, 40, 50)
    ToggleNoclip(Settings.Noclip)
end)

local SpeedBtn = CreateButton("Speed", 186, function(btn)
    Settings.Speed = Settings.Speed == 16 and 28 or 16
    btn.Text = "Speed: " .. Settings.Speed
    btn.BackgroundColor3 = Settings.Speed > 16 and Color3.fromRGB(0, 120, 60) or Color3.fromRGB(40, 40, 50)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = Settings.Speed
    end
end)

-- set initial button states
ESPBtn.Text = "ESP: ON"
ESPBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 60)
SpeedBtn.Text = "Speed: 16"

-- make frame draggable on mobile
local dragging, dragInput, dragStart, startPos
Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
Frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ========== ESP ==========
local function CreateESP(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "MM2ESP"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 100, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.Parent = billboard

    local roleLabel = Instance.new("TextLabel")
    roleLabel.Size = UDim2.new(1, 0, 0.5, 0)
    roleLabel.Position = UDim2.new(0, 0, 0.5, 0)
    roleLabel.BackgroundTransparency = 1
    roleLabel.Text = "Unknown"
    roleLabel.TextColor3 = Color3.new(1, 1, 1)
    roleLabel.TextStrokeTransparency = 0.5
    roleLabel.Font = Enum.Font.Gotham
    roleLabel.TextSize = 12
    roleLabel.Parent = billboard

    billboard.Parent = Workspace

    ESPObjects[player] = {
        Billboard = billboard,
        Name = nameLabel,
        Role = roleLabel
    }
end

local function RemoveESP(player)
    if ESPObjects[player] then
        ESPObjects[player].Billboard:Destroy()
        ESPObjects[player] = nil
    end
end

local function GetRole(player)
    local character = player.Character
    if not character then return "Unknown" end
    if character:FindFirstChild("Knife") or player.Backpack:FindFirstChild("Knife") then
        return "Murderer"
    end
    if character:FindFirstChild("Gun") or player.Backpack:FindFirstChild("Gun") then
        return "Sheriff"
    end
    return "Innocent"
end

local function UpdateESP()
    for player, data in pairs(ESPObjects) do
        if player.Character and player.Character:FindFirstChild("Head") then
            data.Billboard.Adornee = player.Character.Head
            local role = GetRole(player)
            data.Role.Text = role
            if role == "Murderer" then
                data.Role.TextColor3 = Settings.ESPColor.Murderer
            elseif role == "Sheriff" then
                data.Role.TextColor3 = Settings.ESPColor.Sheriff
            else
                data.Role.TextColor3 = Settings.ESPColor.Innocent
            end
            data.Billboard.Enabled = Settings.ESP
        end
    end
end

-- ========== FEATURES ==========
local NoclipConnection
function ToggleNoclip(state)
    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end
    if state then
        NoclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end

local function AutoFarm()
    if not Settings.AutoFarm then return end
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    for _, v in pairs(Workspace:GetDescendants()) do
        if (v.Name == "Coin" or v.Name:lower():find("coin")) and v:IsA("BasePart") then
            character.HumanoidRootPart.CFrame = v.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.12)
        end
    end
end

local function AutoKill()
    if not Settings.AutoKill then return end
    local character = LocalPlayer.Character
    if not character then return end
    local gun = character:FindFirstChild("Gun") or LocalPlayer.Backpack:FindFirstChild("Gun")
    if not gun then return end

    local nearest, dist = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if GetRole(player) == "Murderer" then
                local d = (player.Character.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude
                if d < dist then
                    dist = d
                    nearest = player
                end
            end
        end
    end

    if nearest and nearest.Character then
        if gun.Parent == LocalPlayer.Backpack then
            character.Humanoid:EquipTool(gun)
        end
        local remote = gun:FindFirstChild("Remote") or gun:FindFirstChildWhichIsA("RemoteEvent")
        if remote then
            remote:FireServer(nearest.Character.HumanoidRootPart.Position)
        end
    end
end

-- ========== LOOPS ==========
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        CreateESP(player)
    end)
end)

Players.PlayerRemoving:Connect(RemoveESP)

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
        player.CharacterAdded:Connect(function()
            task.wait(1)
            CreateESP(player)
        end)
    end
end

RunService.RenderStepped:Connect(UpdateESP)

task.spawn(function()
    while true do
        AutoFarm()
        AutoKill()
        task.wait(0.25)
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = Settings.Speed
    end
end)

print("[MM2 Mobile] loaded — use the on-screen panel")
