-- language: Lua, file: mm2_mobile.lua, target: Delta Mobile / Murder Mystery 2
-- *tabbed hub UI like Moondiety style + all working features*

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
    KillAura = false,
    GrabGun = true,
    Fly = false,
    InfJump = false,
    Noclip = false,
    Speed = 16,
    FarmSpeed = 0.12,
    ESPColor = {
        Murderer = Color3.fromRGB(255, 60, 60),
        Sheriff = Color3.fromRGB(60, 160, 255),
        Innocent = Color3.fromRGB(90, 255, 140)
    }
}

local ESPObjects = {}
local CurrentTab = "MAIN"

-- ========== HUB UI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2Hub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 340, 0, 380)
Main.Position = UDim2.new(0.5, -170, 0.5, -190)
Main.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
Main.BackgroundTransparency = 0.02
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(50, 50, 60)
Stroke.Thickness = 1.2
Stroke.Parent = Main

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 42)
TitleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 14)

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 20)
TitleFix.Position = UDim2.new(0, 0, 1, -20)
TitleFix.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "MM2 Hub"
Title.TextColor3 = Color3.fromRGB(240, 240, 245)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -38, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 110, 1, -50)
Sidebar.Position = UDim2.new(0, 8, 0, 48)
Sidebar.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

-- Content area
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -130, 1, -58)
Content.Position = UDim2.new(0, 126, 0, 50)
Content.BackgroundTransparency = 1
Content.Parent = Main

local ContentTitle = Instance.new("TextLabel")
ContentTitle.Size = UDim2.new(1, 0, 0, 24)
ContentTitle.BackgroundTransparency = 1
ContentTitle.Text = "== MAIN =="
ContentTitle.TextColor3 = Color3.fromRGB(160, 160, 175)
ContentTitle.Font = Enum.Font.GothamBold
ContentTitle.TextSize = 12
ContentTitle.TextXAlignment = Enum.TextXAlignment.Left
ContentTitle.Parent = Content

-- toggle creator
local function CreateToggle(parent, name, y, default, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 34)
    btn.Position = UDim2.new(0, 4, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(230, 230, 235)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = btn

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 42, 0, 22)
    indicator.Position = UDim2.new(1, -50, 0.5, -11)
    indicator.BackgroundColor3 = default and Color3.fromRGB(0, 140, 80) or Color3.fromRGB(50, 50, 58)
    indicator.Parent = btn
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.Parent = indicator
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

    local on = default
    btn.MouseButton1Click:Connect(function()
        on = not on
        indicator.BackgroundColor3 = on and Color3.fromRGB(0, 140, 80) or Color3.fromRGB(50, 50, 58)
        circle.Position = on and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        callback(on)
    end)
    return btn
end

-- pages
local Pages = {}

local function ClearContent()
    for _, child in pairs(Content:GetChildren()) do
        if child:IsA("TextButton") or (child:IsA("TextLabel") and child ~= ContentTitle) then
            child:Destroy()
        end
    end
end

local function ShowPage(name)
    CurrentTab = name
    ContentTitle.Text = "== " .. name .. " =="
    ClearContent()

    if name == "MAIN" then
        CreateToggle(Content, "Auto Farm", 32, Settings.AutoFarm, function(v) Settings.AutoFarm = v end)
        CreateToggle(Content, "Grab Gun", 72, Settings.GrabGun, function(v) Settings.GrabGun = v end)
        CreateToggle(Content, "Speed Boost", 112, Settings.Speed > 16, function(v)
            Settings.Speed = v and 28 or 16
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.WalkSpeed = Settings.Speed
            end
        end)
    elseif name == "ESP" then
        CreateToggle(Content, "Player ESP", 32, Settings.ESP, function(v) Settings.ESP = v end)
    elseif name == "MURDERER" then
        CreateToggle(Content, "Auto Kill", 32, Settings.AutoKill, function(v) Settings.AutoKill = v end)
        CreateToggle(Content, "Kill Aura", 72, Settings.KillAura, function(v) Settings.KillAura = v end)
    elseif name == "SHERIFF" then
        CreateToggle(Content, "Auto Kill (Shoot)", 32, Settings.AutoKill, function(v) Settings.AutoKill = v end)
        CreateToggle(Content, "Grab Gun", 72, Settings.GrabGun, function(v) Settings.GrabGun = v end)
    elseif name == "MOVEMENT" then
        CreateToggle(Content, "Fly", 32, Settings.Fly, function(v) Settings.Fly = v ToggleFly(v) end)
        CreateToggle(Content, "Noclip", 72, Settings.Noclip, function(v) Settings.Noclip = v ToggleNoclip(v) end)
        CreateToggle(Content, "Inf Jump", 112, Settings.InfJump, function(v) Settings.InfJump = v end)
    end
end

-- sidebar buttons
local tabs = {"MAIN", "ESP", "MURDERER", "SHERIFF", "MOVEMENT"}
local tabButtons = {}

for i, tabName in ipairs(tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -12, 0, 36)
    btn.Position = UDim2.new(0, 6, 0, 8 + (i-1)*42)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    btn.Text = tabName
    btn.TextColor3 = Color3.fromRGB(200, 200, 210)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 12
    btn.Parent = Sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    tabButtons[tabName] = btn
    btn.MouseButton1Click:Connect(function()
        for _, b in pairs(tabButtons) do
            b.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
            b.TextColor3 = Color3.fromRGB(200, 200, 210)
        end
        btn.BackgroundColor3 = Color3.fromRGB(0, 120, 70)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        ShowPage(tabName)
    end)
end

-- default tab
tabButtons["MAIN"].BackgroundColor3 = Color3.fromRGB(0, 120, 70)
tabButtons["MAIN"].TextColor3 = Color3.fromRGB(255, 255, 255)
ShowPage("MAIN")

-- drag
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
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

-- ========== FEATURES (same reliable ones) ==========
local function ClearESP(player)
    if ESPObjects[player] then
        ESPObjects[player]:Destroy()
        ESPObjects[player] = nil
    end
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    ClearESP(player)
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
    name.TextColor3 = Color3.new(1,1,1)
    name.TextStrokeTransparency = 0.3
    name.Font = Enum.Font.GothamBold
    name.TextSize = 13
    name.Parent = bb

    local role = Instance.new("TextLabel")
    role.Size = UDim2.new(1, 0, 0.5, 0)
    role.Position = UDim2.new(0, 0, 0.5, 0)
    role.BackgroundTransparency = 1
    role.Text = "..."
    role.TextColor3 = Color3.new(1,1,1)
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
            local labels = {}
            for _, l in pairs(bb:GetChildren()) do
                if l:IsA("TextLabel") then table.insert(labels, l) end
            end
            if labels[2] then
                local role = GetRole(player)
                labels[2].Text = role
                labels[2].TextColor3 = Settings.ESPColor[role] or Color3.new(1,1,1)
            end
            bb.Enabled = Settings.ESP
        end
    end
end

local function AutoFarm()
    if not Settings.AutoFarm then return end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local closest, dist = nil, math.huge
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v.Name == "Coin" or v.Name == "CoinPickup" or v.Name:lower():find("coin")) then
            local d = (v.Position - hrp.Position).Magnitude
            if d < dist and d > 1.5 then
                dist = d
                closest = v
            end
        end
    end
    if closest then
        local tween = TweenService:Create(hrp, TweenInfo.new(Settings.FarmSpeed, Enum.EasingStyle.Linear), {
            CFrame = CFrame.new(closest.Position + Vector3.new(0, 2.8, 0))
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
        if knife.Parent == LocalPlayer.Backpack then char.Humanoid:EquipTool(knife) end
        local nearest, dist = nil, math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local d = (p.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                if d < dist then dist = d nearest = p end
            end
        end
        if nearest then
            hrp.CFrame = CFrame.new(nearest.Character.HumanoidRootPart.Position + Vector3.new(0, 1, 0))
            task.wait(0.04)
            knife:Activate()
            task.wait(0.03)
            knife:Activate()
        end
        return
    end

    local gun = char:FindFirstChild("Gun") or LocalPlayer.Backpack:FindFirstChild("Gun")
    if gun then
        if gun.Parent == LocalPlayer.Backpack then char.Humanoid:EquipTool(gun) end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and GetRole(p) == "Murderer" then
                local remote = gun:FindFirstChildWhichIsA("RemoteEvent")
                if remote then
                    pcall(function()
                        remote:FireServer(p.Character.HumanoidRootPart.Position)
                        remote:FireServer(p.Character.HumanoidRootPart.Position)
                    end)
                end
                break
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
    if knife.Parent == LocalPlayer.Backpack then char.Humanoid:EquipTool(knife) end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            if (p.Character.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude < 16 then
                knife:Activate()
            end
        end
    end
end

local function GrabGun()
    if not Settings.GrabGun then return end
    local char = LocalPlayer.Character
    if not char then return end
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

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() task.wait(0.8) CreateESP(p) end)
end)
Players.PlayerRemoving:Connect(ClearESP)

for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        CreateESP(p)
        p.CharacterAdded:Connect(function() task.wait(0.8) CreateESP(p) end)
    end
end

task.spawn(function()
    while true do
        if Settings.AutoFarm then AutoFarm() end
        if Settings.AutoKill then AutoKill() end
        if Settings.KillAura then KillAura() end
        if Settings.GrabGun then GrabGun() end
        task.wait(0.1)
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = Settings.Speed
    end
end)

print("[MM2 Hub] tabbed UI loaded")
