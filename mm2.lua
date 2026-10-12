-- language: Lua, file: mm2.lua, target: Murder Mystery 2
-- own build. remotes resolved by name. no external hub.

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer
local Camera            = workspace.CurrentCamera

-- ── remotes ────────────────────────────────────────────────────────────────
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
    or ReplicatedStorage:FindFirstChild("RemoteEvents")
    or ReplicatedStorage

if not Remotes then
    warn("[MM2] no remotes folder found")
    return
end

local function findRemote(name)
    local r = Remotes:FindFirstChild(name)
    if r then return r end
    for _, v in ipairs(Remotes:GetDescendants()) do
        if v.Name == name then return v end
    end
    return nil
end

local shootRemote    = findRemote("Shoot")
local stabRemote     = findRemote("Stab")
local killRemote     = findRemote("Kill")
local coinRemote     = findRemote("Coin")
local dropRemote     = findRemote("Drop")
local throwRemote    = findRemote("Throw")
local equipRemote    = findRemote("Equip")
local roleRemote     = findRemote("Role")
local roundRemote    = findRemote("Round")

print("[MM2] remotes resolved:")
for name, r in pairs({
    Shoot=shootRemote, Stab=stabRemote, Kill=killRemote,
    Coin=coinRemote, Drop=dropRemote, Throw=throwRemote,
    Equip=equipRemote, Role=roleRemote, Round=roundRemote,
}) do
    print("  ", name, r and r:GetFullName() or "NOT FOUND")
end

-- ── flags ──────────────────────────────────────────────────────────────────
local flags = {
    esp          = false,
    espMurderer  = true,
    espSheriff   = true,
    speed        = false,
    speedValue   = 50,
    noclip       = false,
    infiniteJump = false,
    autoFarm     = false,
    autoShoot    = false,
    autoStab     = false,
    killAll      = false,
}

-- ── ESP ────────────────────────────────────────────────────────────────────
local espHighlights = {}

local function clearESP()
    for _, h in pairs(espHighlights) do
        if h and h.Parent then h:Destroy() end
    end
    espHighlights = {}
end

local function applyESP(player)
    if player == LocalPlayer or not player.Character then return end

    local role = "Innocent"
    local roleVal = player:FindFirstChild("Role")
        or (player.Character and player.Character:FindFirstChild("Role"))
    if roleVal and roleVal.Value then
        role = tostring(roleVal.Value)
    end

    local color
    local rl = role:lower()
    if rl:find("murder") then
        color = Color3.fromRGB(255, 50, 50)
    elseif rl:find("sheriff") then
        color = Color3.fromRGB(50, 100, 255)
    else
        color = Color3.fromRGB(50, 255, 50)
    end

    if espHighlights[player] then
        espHighlights[player]:Destroy()
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "MM2_ESP"
    highlight.Adornee = player.Character
    highlight.Parent = player.Character
    highlight.FillColor = color
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    espHighlights[player] = highlight
end

local function refreshESP()
    if not flags.esp then
        clearESP()
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        applyESP(player)
    end
end

-- ── speed / noclip ─────────────────────────────────────────────────────────
local function applySpeed()
    local char = LocalPlayer.Character
    if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = flags.speed and flags.speedValue or 16 end
end

local function applyNoclip()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not flags.noclip
        end
    end
end

-- ── infinite jump ──────────────────────────────────────────────────────────
UserInputService.JumpRequest:Connect(function()
    if not flags.infiniteJump then return end
    local char = LocalPlayer.Character
    if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- ── role helpers ───────────────────────────────────────────────────────────
local function getMyRole()
    local r = LocalPlayer:FindFirstChild("Role")
        or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Role"))
    return r and r.Value and tostring(r.Value):lower() or ""
end

local function isMurderer() return getMyRole():find("murder") ~= nil end
local function isSheriff()  return getMyRole():find("sheriff") ~= nil end

-- ── kill all ───────────────────────────────────────────────────────────────
-- fires the stab remote at every other player in sequence
local function killAll()
    if not stabRemote then
        warn("[MM2] stab remote missing — kill all unavailable")
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local h   = player.Character:FindFirstChildOfClass("Humanoid")
            if hrp and h and h.Health > 0 then
                pcall(function()
                    stabRemote:FireServer(hrp)
                    stabRemote:FireServer(player)
                end)
            end
        end
    end
end

-- ── auto shoot (sheriff) ───────────────────────────────────────────────────
local function autoShoot()
    if not shootRemote or not isSheriff() then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end
        local roleVal = player:FindFirstChild("Role")
            or (player.Character and player.Character:FindFirstChild("Role"))
        local role = roleVal and roleVal.Value and tostring(roleVal.Value):lower() or ""
        if role:find("murder") then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                pcall(function() shootRemote:FireServer(hrp) end)
            end
        end
    end
end

-- ── auto stab (murderer) ───────────────────────────────────────────────────
local function autoStab()
    if not stabRemote or not isMurderer() then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        local h   = player.Character:FindFirstChildOfClass("Humanoid")
        if hrp and h and h.Health > 0 then
            local dist = (hrp.Position - (LocalPlayer.Character
                and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                and LocalPlayer.Character.HumanoidRootPart.Position
                or Vector3.zero)).Magnitude
            if dist < 15 then
                pcall(function()
                    stabRemote:FireServer(hrp)
                    stabRemote:FireServer(player)
                end)
            end
        end
    end
end

-- ── auto farm coins ────────────────────────────────────────────────────────
local function autoFarm()
    if not coinRemote then return end
    for _, coin in ipairs(workspace:GetDescendants()) do
        if coin.Name == "Coin" or coin.Name:lower():find("coin") then
            if coin:IsA("BasePart") then
                pcall(function()
                    coinRemote:FireServer(coin)
                    coinRemote:FireServer(coin.Position)
                end)
            end
        end
    end
end

-- ── main loop ──────────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if flags.esp then refreshESP() end
    if flags.speed then applySpeed() end
    if flags.noclip then applyNoclip() end

    if flags.killAll then killAll() end
    if flags.autoShoot then autoShoot() end
    if flags.autoStab then autoStab() end
    if flags.autoFarm then autoFarm() end
end)

-- ── player lifecycle ───────────────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
    if flags.esp then
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            applyESP(player)
        end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if espHighlights[player] then
        espHighlights[player]:Destroy()
        espHighlights[player] = nil
    end
end)

-- ── UI ─────────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "MM2Own"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(260, 380)
frame.Position = UDim2.fromOffset(20, 20)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundTransparency = 1
title.Text = "MM2 — own build"
title.TextColor3 = Color3.fromRGB(240, 240, 245)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = frame

local function makeToggle(labelText, key, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -24, 0, 30)
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
        if callback then callback() end
    end)
    return btn
end

makeToggle("ESP",           "esp",          40)
makeToggle("Speed",         "speed",        75, applySpeed)
makeToggle("Noclip",        "noclip",       110, applyNoclip)
makeToggle("Infinite Jump", "infiniteJump", 145)
makeToggle("Kill All",      "killAll",      180)
makeToggle("Auto Shoot",    "autoShoot",    215)
makeToggle("Auto Stab",     "autoStab",     250)
makeToggle("Auto Farm Coins", "autoFarm",   285)

-- drag
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

print("[MM2] own build loaded")
