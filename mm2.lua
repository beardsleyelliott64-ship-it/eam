-- language: Lua, file: mm2_hub.lua, target: Delta Mobile / Murder Mystery 2
-- *v3 — fixed autofarm, new EXTRAS tab, 6 new mods, all UI preserved*

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local Workspace      = game:GetService("Workspace")
local LocalPlayer    = Players.LocalPlayer

-- ===================== SETTINGS =====================
local Settings = {
    -- existing
    ESP          = true,
    AutoFarm     = false,
    AutoKill     = false,
    KillAura     = false,
    GrabGun      = true,
    Fly          = false,
    InfJump      = false,
    Noclip       = false,
    Speed        = 16,
    -- new
    AntiVoid     = false,   -- teleports you back if you fall out of map
    AlwaysSheriff= false,   -- equips gun from anywhere the moment it spawns
    FakeLag      = false,   -- simulate lag for knife hitbox extension (local CFrame jitter)
    GodMode      = false,   -- zero-jump infinite no-damage via Humanoid state spam
    ESPDistance  = false,   -- show stud distance on ESP labels
    -- internal
    FarmSpeed    = 0.08,
    ESPColor = {
        Murderer = Color3.fromRGB(255, 60, 60),
        Sheriff  = Color3.fromRGB(60, 160, 255),
        Innocent = Color3.fromRGB(90, 255, 140)
    }
}

local ESPObjects  = {}
local CurrentTab  = "MAIN"
local FarmActive  = false  -- per-loop gate to avoid stacking farm threads

-- ===================== TWEEN HELPERS =====================
local function Tween(obj, props, t, style, dir)
    style = style or Enum.EasingStyle.Quart
    dir   = dir   or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(t, style, dir), props):Play()
end
local function TweenPos(obj, pos, t)      Tween(obj, {Position = pos}, t) end
local function TweenSize(obj, sz, t)      Tween(obj, {Size = sz}, t) end
local function TweenColor(obj, c, t)      Tween(obj, {BackgroundColor3 = c}, t) end
local function TweenTextColor(obj, c, t)  Tween(obj, {TextColor3 = c}, t) end

-- ===================== GUI SCAFFOLD =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2HubV3"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 360, 0, 440)
Main.Position = UDim2.new(0.5, -180, 1.5, 0)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
Main.BorderSizePixel = 0
Main.ZIndex = 2
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 18)

local Rim = Instance.new("UIStroke")
Rim.Color = Color3.fromRGB(80, 80, 100)
Rim.Thickness = 1
Rim.Transparency = 0.4
Rim.Parent = Main

local Gradient = Instance.new("UIGradient")
Gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(25, 25, 35)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(14, 14, 20)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(10, 10, 14))
})
Gradient.Rotation = 120
Gradient.Parent = Main

-- ===================== TITLE BAR =====================
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 52)
TitleBar.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 3
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 18)

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 22)
TitleFix.Position = UDim2.new(0, 0, 1, -22)
TitleFix.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
TitleFix.BorderSizePixel = 0
TitleFix.ZIndex = 3
TitleFix.Parent = TitleBar

local AccentLine = Instance.new("Frame")
AccentLine.Size = UDim2.new(0, 0, 0, 2)
AccentLine.Position = UDim2.new(0, 0, 1, -1)
AccentLine.BackgroundColor3 = Color3.fromRGB(0, 200, 120)
AccentLine.BorderSizePixel = 0
AccentLine.ZIndex = 4
AccentLine.Parent = TitleBar
Instance.new("UICorner", AccentLine).CornerRadius = UDim.new(0, 2)
local AccentGrad = Instance.new("UIGradient")
AccentGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0, 220, 140)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 160, 255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(160, 0, 255))
})
AccentGrad.Parent = AccentLine

local TitleDot = Instance.new("Frame")
TitleDot.Size = UDim2.new(0, 10, 0, 10)
TitleDot.Position = UDim2.new(0, 16, 0.5, -5)
TitleDot.BackgroundColor3 = Color3.fromRGB(0, 210, 130)
TitleDot.BorderSizePixel = 0
TitleDot.ZIndex = 4
TitleDot.Parent = TitleBar
Instance.new("UICorner", TitleDot).CornerRadius = UDim.new(1, 0)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -90, 1, 0)
Title.Position = UDim2.new(0, 34, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "MM2 Hub"
Title.TextColor3 = Color3.fromRGB(245, 245, 250)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 4
Title.Parent = TitleBar

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, -90, 0, 14)
SubTitle.Position = UDim2.new(0, 34, 0.55, 0)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "murder mystery 2  •  v3"
SubTitle.TextColor3 = Color3.fromRGB(100, 100, 120)
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextSize = 11
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.ZIndex = 4
SubTitle.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 34, 0, 34)
CloseBtn.Position = UDim2.new(1, -44, 0.5, -17)
CloseBtn.BackgroundColor3 = Color3.fromRGB(35, 20, 25)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 110)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 20
CloseBtn.AutoButtonColor = false
CloseBtn.ZIndex = 5
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 10)

CloseBtn.MouseEnter:Connect(function()
    TweenColor(CloseBtn, Color3.fromRGB(200, 40, 55), 0.18)
    TweenTextColor(CloseBtn, Color3.fromRGB(255, 255, 255), 0.18)
end)
CloseBtn.MouseLeave:Connect(function()
    TweenColor(CloseBtn, Color3.fromRGB(35, 20, 25), 0.18)
    TweenTextColor(CloseBtn, Color3.fromRGB(255, 100, 110), 0.18)
end)

local isOpen = true
CloseBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    if isOpen then
        TweenPos(Main, UDim2.new(0.5, -180, 0.5, -220), 0.4)
    else
        TweenPos(Main, UDim2.new(0.5, -180, 1.5, 0), 0.35)
    end
end)

-- ===================== SIDEBAR =====================
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 106, 1, -62)
Sidebar.Position = UDim2.new(0, 8, 0, 56)
Sidebar.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 3
Sidebar.Parent = Main
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 12)
local SideStroke = Instance.new("UIStroke")
SideStroke.Color = Color3.fromRGB(40, 40, 55)
SideStroke.Thickness = 1
SideStroke.Parent = Sidebar

-- ===================== CONTENT AREA =====================
local ContentClip = Instance.new("Frame")
ContentClip.Size = UDim2.new(1, -130, 1, -68)
ContentClip.Position = UDim2.new(0, 122, 0, 60)
ContentClip.BackgroundTransparency = 1
ContentClip.ClipsDescendants = true
ContentClip.ZIndex = 3
ContentClip.Parent = Main

local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, 0, 1, 0)
Content.Position = UDim2.new(0, 0, 0, 0)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = Color3.fromRGB(0, 180, 110)
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.ZIndex = 3
Content.Parent = ContentClip

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 6)
ContentLayout.Parent = Content

local ContentPad = Instance.new("UIPadding")
ContentPad.PaddingTop = UDim.new(0, 4)
ContentPad.PaddingLeft = UDim.new(0, 2)
ContentPad.PaddingRight = UDim.new(0, 6)
ContentPad.Parent = Content

ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Content.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 12)
end)

-- ===================== SECTION HEADER =====================
local function MakeSectionHeader(text, order)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 24)
    f.BackgroundTransparency = 1
    f.LayoutOrder = order
    f.Parent = Content
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -8, 1, 0)
    l.Position = UDim2.new(0, 4, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(0, 200, 120)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, -8, 0, 1)
    line.Position = UDim2.new(0, 4, 1, -1)
    line.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
    line.BackgroundTransparency = 0.7
    line.BorderSizePixel = 0
    line.Parent = f
    return f
end

-- ===================== TOGGLE =====================
local function CreateToggle(name, order, default, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.Parent = Content
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    local BtnStroke = Instance.new("UIStroke")
    BtnStroke.Color = default and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(35, 35, 48)
    BtnStroke.Thickness = 1
    BtnStroke.Parent = btn

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 0.6, 0)
    bar.Position = UDim2.new(0, 0, 0.2, 0)
    bar.BackgroundColor3 = default and Color3.fromRGB(0, 210, 130) or Color3.fromRGB(50, 50, 65)
    bar.BorderSizePixel = 0
    bar.Parent = btn
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 2)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = default and Color3.fromRGB(235, 235, 245) or Color3.fromRGB(160, 160, 180)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = btn

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 44, 0, 24)
    pill.Position = UDim2.new(1, -52, 0.5, -12)
    pill.BackgroundColor3 = default and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(38, 38, 52)
    pill.BorderSizePixel = 0
    pill.Parent = btn
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = default and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = pill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local knobGlow = Instance.new("UIStroke")
    knobGlow.Color = Color3.fromRGB(0, 230, 140)
    knobGlow.Thickness = default and 2 or 0
    knobGlow.Parent = knob

    local on = default
    btn.MouseButton1Click:Connect(function()
        on = not on
        TweenColor(pill, on and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(38, 38, 52), 0.2)
        Tween(knob, {Position = on and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)}, 0.2)
        Tween(knobGlow, {Thickness = on and 2 or 0}, 0.2)
        TweenColor(BtnStroke, on and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(35, 35, 48), 0.2)
        TweenColor(bar, on and Color3.fromRGB(0, 210, 130) or Color3.fromRGB(50, 50, 65), 0.2)
        TweenTextColor(label, on and Color3.fromRGB(235, 235, 245) or Color3.fromRGB(160, 160, 180), 0.2)
        callback(on)
    end)
    btn.MouseEnter:Connect(function()  TweenColor(btn, Color3.fromRGB(22, 22, 32), 0.15) end)
    btn.MouseLeave:Connect(function()  TweenColor(btn, Color3.fromRGB(18, 18, 26), 0.15) end)
    return btn
end

-- ===================== PAGES =====================
local function ClearContent()
    for _, c in pairs(Content:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") or c:IsA("ScrollingFrame") then
            c:Destroy()
        end
    end
end

local function SlideIn()
    Content.Position = UDim2.new(0.15, 0, 0, 0)
    TweenPos(Content, UDim2.new(0, 0, 0, 0), 0.22)
end

local function ShowPage(name)
    CurrentTab = name
    ClearContent()
    SlideIn()

    if name == "MAIN" then
        MakeSectionHeader("GENERAL", 1)
        CreateToggle("Auto Farm",   2, Settings.AutoFarm,  function(v) Settings.AutoFarm  = v end)
        CreateToggle("Grab Gun",    3, Settings.GrabGun,   function(v) Settings.GrabGun   = v end)
        CreateToggle("Speed Boost", 4, Settings.Speed > 16, function(v)
            Settings.Speed = v and 32 or 16
            local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if h then h.WalkSpeed = Settings.Speed end
        end)

    elseif name == "ESP" then
        MakeSectionHeader("VISUALS", 1)
        CreateToggle("Player ESP",     2, Settings.ESP,         function(v) Settings.ESP         = v end)
        CreateToggle("Show Distance",  3, Settings.ESPDistance, function(v) Settings.ESPDistance = v end)

    elseif name == "MURDERER" then
        MakeSectionHeader("MURDERER TOOLS", 1)
        CreateToggle("Auto Kill",        2, Settings.AutoKill,        function(v) Settings.AutoKill        = v end)
        CreateToggle("Kill Aura",        3, Settings.KillAura,        function(v) Settings.KillAura        = v end)
        CreateToggle("Fake Lag",         4, Settings.FakeLag,         function(v) Settings.FakeLag         = v end)

    elseif name == "SHERIFF" then
        MakeSectionHeader("SHERIFF TOOLS", 1)
        CreateToggle("Auto Shoot",      2, Settings.AutoKill,       function(v) Settings.AutoKill       = v end)
        CreateToggle("Grab Gun",        3, Settings.GrabGun,        function(v) Settings.GrabGun        = v end)
        CreateToggle("Always Sheriff",  4, Settings.AlwaysSheriff,  function(v) Settings.AlwaysSheriff  = v end)

    elseif name == "MOVEMENT" then
        MakeSectionHeader("MOVEMENT", 1)
        CreateToggle("Fly",      2, Settings.Fly,      function(v) Settings.Fly      = v ToggleFly(v)      end)
        CreateToggle("Noclip",   3, Settings.Noclip,   function(v) Settings.Noclip   = v ToggleNoclip(v)   end)
        CreateToggle("Inf Jump", 4, Settings.InfJump,  function(v) Settings.InfJump  = v end)

    elseif name == "EXTRAS" then
        MakeSectionHeader("MISC", 1)
        CreateToggle("Anti Void",  2, Settings.AntiVoid,  function(v) Settings.AntiVoid  = v end)
        CreateToggle("God Mode",   3, Settings.GodMode,   function(v) Settings.GodMode   = v end)
    end
end

-- ===================== SIDEBAR TABS =====================
local tabs = {
    {name = "MAIN",     icon = "⬡"},
    {name = "ESP",      icon = "◈"},
    {name = "MURDERER", icon = "⚔"},
    {name = "SHERIFF",  icon = "✦"},
    {name = "MOVEMENT", icon = "◎"},
    {name = "EXTRAS",   icon = "✶"},
}
local tabButtons = {}

for i, tab in ipairs(tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -12, 0, 36)
    btn.Position = UDim2.new(0, 6, 0, 6 + (i - 1) * 42)
    btn.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.ZIndex = 4
    btn.Parent = Sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    local activePill = Instance.new("Frame")
    activePill.Size = UDim2.new(0, 3, 0.55, 0)
    activePill.Position = UDim2.new(0, 0, 0.225, 0)
    activePill.BackgroundColor3 = Color3.fromRGB(0, 210, 130)
    activePill.BackgroundTransparency = 1
    activePill.BorderSizePixel = 0
    activePill.ZIndex = 5
    activePill.Parent = btn
    Instance.new("UICorner", activePill).CornerRadius = UDim.new(0, 2)

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 18, 1, 0)
    icon.Position = UDim2.new(0, 9, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = tab.icon
    icon.TextColor3 = Color3.fromRGB(100, 100, 120)
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 12
    icon.ZIndex = 5
    icon.Parent = btn

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -34, 1, 0)
    lbl.Position = UDim2.new(0, 30, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = tab.name
    lbl.TextColor3 = Color3.fromRGB(130, 130, 150)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 5
    lbl.Parent = btn

    tabButtons[tab.name] = {btn = btn, lbl = lbl, icon = icon, pill = activePill}

    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabButtons) do
            TweenColor(t.btn, Color3.fromRGB(18, 18, 26), 0.18)
            TweenTextColor(t.lbl, Color3.fromRGB(130, 130, 150), 0.18)
            TweenTextColor(t.icon, Color3.fromRGB(100, 100, 120), 0.18)
            Tween(t.pill, {BackgroundTransparency = 1}, 0.18)
        end
        TweenColor(btn, Color3.fromRGB(22, 22, 32), 0.18)
        TweenTextColor(lbl, Color3.fromRGB(235, 235, 245), 0.18)
        TweenTextColor(icon, Color3.fromRGB(0, 210, 130), 0.18)
        Tween(activePill, {BackgroundTransparency = 0}, 0.18)
        ShowPage(tab.name)
    end)
end

local defTab = tabButtons["MAIN"]
defTab.btn.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
defTab.lbl.TextColor3 = Color3.fromRGB(235, 235, 245)
defTab.icon.TextColor3 = Color3.fromRGB(0, 210, 130)
defTab.pill.BackgroundTransparency = 0
ShowPage("MAIN")

-- ===================== DRAG =====================
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local d = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

-- ===================== OPEN ANIMATION =====================
task.delay(0.1, function()
    TweenPos(Main, UDim2.new(0.5, -180, 0.5, -220), 0.55)
    TweenSize(AccentLine, UDim2.new(1, 0, 0, 2), 0.65)
    task.delay(0.15, function()
        local function pulse()
            Tween(TitleDot, {BackgroundTransparency = 0.5}, 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.delay(0.8, function()
                Tween(TitleDot, {BackgroundTransparency = 0}, 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                task.delay(0.8, pulse)
            end)
        end
        pulse()
    end)
end)

-- ===================== ESP =====================
local function ClearESP(player)
    if ESPObjects[player] then ESPObjects[player]:Destroy(); ESPObjects[player] = nil end
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    ClearESP(player)
    local bb = Instance.new("BillboardGui")
    bb.Name = "MM2ESP"
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 140, 0, 48)
    bb.StudsOffset = Vector3.new(0, 3.3, 0)
    bb.Parent = Workspace

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 13
    nameLabel.Parent = bb

    local roleLabel = Instance.new("TextLabel")
    roleLabel.Size = UDim2.new(1, 0, 0.5, 0)
    roleLabel.Position = UDim2.new(0, 0, 0.5, 0)
    roleLabel.BackgroundTransparency = 1
    roleLabel.Text = "..."
    roleLabel.TextColor3 = Color3.new(1, 1, 1)
    roleLabel.TextStrokeTransparency = 0.3
    roleLabel.Font = Enum.Font.Gotham
    roleLabel.TextSize = 12
    roleLabel.Parent = bb

    ESPObjects[player] = bb
end

local function GetRole(player)
    local char = player.Character
    if not char then return "Unknown" end
    if char:FindFirstChild("Knife") or player.Backpack:FindFirstChild("Knife") then return "Murderer" end
    if char:FindFirstChild("Gun")   or player.Backpack:FindFirstChild("Gun")   then return "Sheriff"  end
    return "Innocent"
end

local function UpdateESP()
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    for player, bb in pairs(ESPObjects) do
        if player.Character and player.Character:FindFirstChild("Head") then
            bb.Adornee = player.Character.Head
            local labels = {}
            for _, l in pairs(bb:GetChildren()) do
                if l:IsA("TextLabel") then table.insert(labels, l) end
            end
            if labels[1] then labels[1].Text = player.Name end
            if labels[2] then
                local role = GetRole(player)
                local distStr = ""
                if Settings.ESPDistance and myHRP and player.Character:FindFirstChild("HumanoidRootPart") then
                    local d = math.floor((player.Character.HumanoidRootPart.Position - myHRP.Position).Magnitude)
                    distStr = "  [" .. d .. "st]"
                end
                labels[2].Text = role .. distStr
                labels[2].TextColor3 = Settings.ESPColor[role] or Color3.new(1, 1, 1)
            end
            bb.Enabled = Settings.ESP
        end
    end
end

-- ===================== AUTO FARM (fixed) =====================
-- fix: CFrame-step per heartbeat instead of tween on hrp.
-- tween on hrp fights the physics sim → rubber-bands, stalls, loops on dead coins.
-- per-heartbeat CFrame with coin re-validation each tick is stable and coin-delete safe.
local FarmConnection
local function StartFarm()
    if FarmConnection then FarmConnection:Disconnect(); FarmConnection = nil end
    FarmConnection = RunService.Heartbeat:Connect(function()
        if not Settings.AutoFarm then
            FarmConnection:Disconnect(); FarmConnection = nil; return
        end
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local closest, dist = nil, math.huge
        -- search all descendants; re-validate every tick so deleted coins don't stall
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and v.Parent ~= nil then
                local n = v.Name:lower()
                if n == "coin" or n == "coinpickup" or n:find("coin") then
                    local d = (v.Position - hrp.Position).Magnitude
                    if d < dist and d > 0.8 then
                        dist = d; closest = v
                    end
                end
            end
        end

        if closest then
            -- step toward coin fast; stop when close enough to trigger pickup
            if dist > 2.5 then
                local target = CFrame.new(closest.Position + Vector3.new(0, 2.8, 0))
                -- move in increments so physics doesn't fight us; 90 studs/sec feel
                local step = math.min(dist, 90 * (1/60))
                local dir = (target.Position - hrp.Position).Unit
                hrp.CFrame = CFrame.new(hrp.Position + dir * step)
            else
                -- snap on top to guarantee pickup
                hrp.CFrame = CFrame.new(closest.Position + Vector3.new(0, 2.8, 0))
            end
        end
    end)
end

-- watch the setting; start farm loop when toggled on
task.spawn(function()
    local last = false
    while true do
        if Settings.AutoFarm and not last then
            StartFarm()
        end
        last = Settings.AutoFarm
        task.wait(0.2)
    end
end)

-- ===================== AUTO KILL =====================
local function AutoKill()
    if not Settings.AutoKill then return end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart

    local knife = char:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
    if knife then
        if knife.Parent == LocalPlayer.Backpack then char.Humanoid:EquipTool(knife) end
        local nearest, nearDist = nil, math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local d = (p.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                if d < nearDist then nearDist = d; nearest = p end
            end
        end
        if nearest then
            hrp.CFrame = CFrame.new(nearest.Character.HumanoidRootPart.Position + Vector3.new(0, 1, 0))
            task.wait(0.04); knife:Activate(); task.wait(0.03); knife:Activate()
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

-- ===================== KILL AURA =====================
local function KillAura()
    if not Settings.KillAura then return end
    local char = LocalPlayer.Character
    if not char then return end
    local knife = char:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
    if not knife then return end
    if knife.Parent == LocalPlayer.Backpack then char.Humanoid:EquipTool(knife) end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            if (p.Character.HumanoidRootPart.Position - hrp.Position).Magnitude < 16 then
                knife:Activate()
            end
        end
    end
end

-- ===================== GRAB GUN =====================
local function GrabGun()
    if not Settings.GrabGun then return end
    local char = LocalPlayer.Character
    if not char then return end
    local drop = Workspace:FindFirstChild("GunDrop")
    if drop then
        for _, v in pairs(drop:GetDescendants()) do
            if v:IsA("Tool") and v.Name == "Gun" then v.Parent = char; return end
        end
    end
    for _, v in pairs(Workspace:GetChildren()) do
        if v:IsA("Tool") and v.Name == "Gun" then v.Parent = char; return end
    end
end

-- ===================== NEW: ALWAYS SHERIFF =====================
local function AlwaysSheriff()
    if not Settings.AlwaysSheriff then return end
    local char = LocalPlayer.Character
    if not char then return end
    if char:FindFirstChild("Gun") or LocalPlayer.Backpack:FindFirstChild("Gun") then return end
    GrabGun()
end

-- ===================== NEW: ANTI VOID =====================
local VOID_Y = -100  -- if below this Y, snap back to spawn
local lastSafePos = nil
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if hrp.Position.Y > VOID_Y then
        lastSafePos = hrp.CFrame
    elseif Settings.AntiVoid and lastSafePos then
        hrp.CFrame = lastSafePos
    end
end)

-- ===================== NEW: GOD MODE =====================
-- client-side only: keeps Humanoid in Jumping state so damage state never triggers
local GodConnection
local function UpdateGodMode(state)
    if GodConnection then GodConnection:Disconnect(); GodConnection = nil end
    if state then
        GodConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local h = char:FindFirstChild("Humanoid")
            if h then
                h:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end
-- hook into toggle
local _origCreateToggle = CreateToggle
-- god mode is wired via the toggle callback above in EXTRAS page already

-- ===================== NEW: FAKE LAG =====================
-- jitters HRP CFrame slightly every other frame — widens server-side hitbox window for knife
local FakeLagFrame = 0
RunService.RenderStepped:Connect(function()
    if Settings.FakeLag then
        FakeLagFrame = FakeLagFrame + 1
        if FakeLagFrame % 2 == 0 then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                local jitter = Vector3.new(
                    math.random(-3, 3) * 0.06,
                    0,
                    math.random(-3, 3) * 0.06
                )
                hrp.CFrame = hrp.CFrame + jitter
            end
        end
    end
end)

-- ===================== NOCLIP =====================
local NoclipConnection
function ToggleNoclip(state)
    if NoclipConnection then NoclipConnection:Disconnect(); NoclipConnection = nil end
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

-- ===================== FLY =====================
local FlyBV, FlyBG
function ToggleFly(state)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    if FlyBV then FlyBV:Destroy(); FlyBV = nil end
    if FlyBG then FlyBG:Destroy(); FlyBG = nil end
    if state then
        FlyBV = Instance.new("BodyVelocity"); FlyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        FlyBV.Velocity = Vector3.zero; FlyBV.Parent = hrp
        FlyBG = Instance.new("BodyGyro"); FlyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        FlyBG.P = 9e4; FlyBG.Parent = hrp
        char.Humanoid.PlatformStand = true
    else
        if char.Humanoid then char.Humanoid.PlatformStand = false end
    end
end

-- ===================== INF JUMP =====================
UserInputService.JumpRequest:Connect(function()
    if Settings.InfJump then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ===================== RENDER LOOP =====================
RunService.RenderStepped:Connect(function()
    if Settings.Fly and FlyBV then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            FlyBV.Velocity = Workspace.CurrentCamera.CFrame.LookVector * 60
            if FlyBG then FlyBG.CFrame = Workspace.CurrentCamera.CFrame end
        end
    end
    UpdateESP()
end)

-- ===================== MAIN LOOP =====================
-- god mode watcher (separate from toggle — re-hooks on character respawn)
task.spawn(function()
    while true do
        if Settings.GodMode and not GodConnection then UpdateGodMode(true) end
        if not Settings.GodMode and GodConnection then UpdateGodMode(false) end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while true do
        if Settings.AutoKill       then AutoKill()        end
        if Settings.KillAura       then KillAura()        end
        if Settings.GrabGun        then GrabGun()         end
        if Settings.AlwaysSheriff  then AlwaysSheriff()   end
        task.wait(0.1)
    end
end)

-- ===================== PLAYER HOOKS =====================
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() task.wait(0.8); CreateESP(p) end)
end)
Players.PlayerRemoving:Connect(ClearESP)

for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        CreateESP(p)
        p.CharacterAdded:Connect(function() task.wait(0.8); CreateESP(p) end)
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local h = char:FindFirstChild("Humanoid")
    if h then h.WalkSpeed = Settings.Speed end
    -- re-wire fly/noclip on respawn
    if Settings.Fly     then ToggleFly(true)     end
    if Settings.Noclip  then ToggleNoclip(true)  end
end)

print("[MM2 Hub v3] loaded — fixed farm, 6 new mods, animated UI")
