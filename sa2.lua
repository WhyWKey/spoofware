local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/sametexe001/juanitahaxx/refs/heads/main/Library.lua"
))()

Library.Directory = "BitchBot_StayAlive2"
Library.MenuKeybind = tostring(Enum.KeyCode.RightShift)

pcall(function()
    if not isfolder(Library.Directory) then makefolder(Library.Directory) end
    for _, folder in pairs(Library.Folders) do
        local path = Library.Directory .. folder
        if not isfolder(path) then makefolder(path) end
    end
    if not isfile(Library.Directory .. "/autoload.json") then
        writefile(Library.Directory .. "/autoload.json", "")
    end
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local CFG = {
    Enabled = false,
    Range = 8,
    DelayMs = 120,
    TeamCheck = true,
    WallCheck = false,
    RequireTool = true,
    AttackMode = "Activate",
    TargetParts = { "Head", "HumanoidRootPart", "UpperTorso", "Torso" },
    ShowRange = true,
    RangeColor = Color3.fromRGB(80, 255, 120),
}

local lastAttack = 0
local rangeCircle = nil

local function notify(msg, dur, col)
    pcall(function()
        Library:Notification(msg, dur or 3, col or Library.Theme.Accent)
    end)
end

local function clampDelay(v)
    local n = tonumber(v)
    if not n or n ~= n then -- nil or NaN
        n = 120
    end
    n = math.floor(n + 0.5)
    if n < 50 then n = 50 end
    if n > 500 then n = 500 end
    return n
end

local function getChar()
    return LocalPlayer.Character
end

local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getTool()
    local c = getChar()
    if not c then return nil, nil end
    for _, v in ipairs(c:GetChildren()) do
        if v:IsA("Tool") then
            return v, v:FindFirstChild("Handle")
        end
    end
    return nil, nil
end

local function isAlive(plr)
    local c = plr.Character
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function isEnemy(plr)
    if plr == LocalPlayer then return false end
    if not isAlive(plr) then return false end
    if CFG.TeamCheck then
        if LocalPlayer.Team and plr.Team and LocalPlayer.Team == plr.Team then
            return false
        end
    end
    return true
end

local function originPart()
    local tool, handle = getTool()
    if handle and handle:IsA("BasePart") then
        return handle, tool
    end
    return getHRP(), tool
end

local function visibleTo(fromPos, toPos, targetChar)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character }
    local result = workspace:Raycast(fromPos, toPos - fromPos, params)
    if not result then return true end
    return targetChar and result.Instance:IsDescendantOf(targetChar)
end

local function getClosestInRange()
    local origin, tool = originPart()
    if not origin then return nil end
    if CFG.RequireTool and not tool then return nil end

    local best, bestDist = nil, CFG.Range
    for _, plr in ipairs(Players:GetPlayers()) do
        if not isEnemy(plr) then continue end
        local char = plr.Character
        if not char then continue end
        for _, partName in ipairs(CFG.TargetParts) do
            local part = char:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                local dist = (part.Position - origin.Position).Magnitude
                if dist <= bestDist then
                    if CFG.WallCheck and not visibleTo(origin.Position, part.Position, char) then
                        continue
                    end
                    bestDist = dist
                    best = { player = plr, part = part, dist = dist, tool = tool }
                end
            end
        end
    end
    return best
end

local function doAttack(tool)
    if CFG.AttackMode == "Click" then
        pcall(function()
            if mouse1click then
                mouse1click()
            elseif VirtualInputManager then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait()
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end
        end)
    end
    if tool then
        pcall(function() tool:Activate() end)
    end
end

-- Drawing range circle (no character parts)
if Drawing then
    rangeCircle = Drawing.new("Circle")
    rangeCircle.Thickness = 1.5
    rangeCircle.NumSides = 64
    rangeCircle.Filled = false
    rangeCircle.Visible = false
end

local function updateRangeCircle()
    if not rangeCircle then return end
    if not (CFG.Enabled and CFG.ShowRange) then
        rangeCircle.Visible = false
        return
    end
    local hrp = getHRP()
    local cam = workspace.CurrentCamera
    if not hrp or not cam then
        rangeCircle.Visible = false
        return
    end
    local center, onScreen = cam:WorldToViewportPoint(hrp.Position)
    if not onScreen or center.Z <= 0 then
        rangeCircle.Visible = false
        return
    end
    local edge = cam:WorldToViewportPoint(hrp.Position + cam.CFrame.RightVector * CFG.Range)
    local radius = math.abs(edge.X - center.X)
    if radius < 2 then
        edge = cam:WorldToViewportPoint(hrp.Position + Vector3.new(CFG.Range, 0, 0))
        radius = math.abs(edge.X - center.X)
    end
    rangeCircle.Visible = true
    rangeCircle.Position = Vector2.new(center.X, center.Y)
    rangeCircle.Radius = math.clamp(radius, 8, 3000)
    rangeCircle.Color = CFG.RangeColor
end

RunService.RenderStepped:Connect(updateRangeCircle)

RunService.Heartbeat:Connect(function()
    if not CFG.Enabled then return end
    local delayMs = clampDelay(CFG.DelayMs)
    CFG.DelayMs = delayMs
    local now = os.clock()
    if now - lastAttack < delayMs / 1000 then return end
    local hit = getClosestInRange()
    if not hit then return end
    lastAttack = now
    doAttack(hit.tool or select(1, getTool()))
end)

----------------------------------------------------------------
-- UI
----------------------------------------------------------------
local Window = Library:Window({ Name = "Stay Alive 2" })
local Watermark = Window:Watermark({ Name = "Stay Alive 2" })
local KeybindList = Window:KeybindList()

do
    local FpsText = Watermark:Add("FPS: —")
    local StatusText = Watermark:Add("trig OFF")
    local frames, elapsed = 0, 0
    Library:Connect(RunService.RenderStepped, function(dt)
        frames += 1
        elapsed += dt
        if elapsed >= 1 then
            FpsText:SetText("FPS: " .. math.floor(frames / elapsed))
            frames, elapsed = 0, 0
        end
        if CFG.Enabled then
            StatusText:SetText(string.format("trig %dms", clampDelay(CFG.DelayMs)))
        else
            StatusText:SetText("trig OFF")
        end
    end)
end

local CombatPage = Window:Page({ Name = "combat" })

do
    local Sec = CombatPage:Section({ Name = "Sword Triggerbot", Side = 1 })
    local Opt = CombatPage:Section({ Name = "Options", Side = 2 })

    Sec:Toggle({
        Name = "Enabled",
        Flag = "TriggerEnabled",
        Default = false,
        Callback = function(v)
            CFG.Enabled = v and true or false
            notify(CFG.Enabled and "Triggerbot ON" or "Triggerbot OFF", 2)
        end,
    }):Keybind({
        Name = "Triggerbot",
        Flag = "TriggerKey",
        Default = Enum.KeyCode.T,
        Mode = "Toggle",
        Callback = function() end,
    })

    Sec:Slider({
        Name = "Range",
        Flag = "TriggerRange",
        Min = 2,
        Max = 20,
        Default = 8,
        Decimals = 1,
        Suffix = " stud",
        Callback = function(v)
            local n = tonumber(v)
            if n and n == n then
                CFG.Range = n
            end
        end,
    })

    -- whole numbers only; clamp inside callback so UI never drives NaN
    -- NOTE: juanitahaxx Round uses 1/Decimals — Decimals=0 → NaN. Use 1 (integer step).
    Sec:Slider({
        Name = "Attack Delay",
        Flag = "TriggerDelayMs",
        Min = 50,
        Max = 500,
        Default = 120,
        Decimals = 1,
        Suffix = " ms",
        Callback = function(v)
            CFG.DelayMs = clampDelay(v)
        end,
    })

    Sec:Dropdown({
        Name = "Attack Mode",
        Flag = "TriggerMode",
        Items = { "Activate", "Click" },
        Default = "Activate",
        Multi = false,
        Callback = function(v)
            if type(v) == "string" then
                CFG.AttackMode = v
            end
        end,
    })

    Opt:Toggle({
        Name = "Team Check",
        Flag = "TriggerTeam",
        Default = true,
        Callback = function(v) CFG.TeamCheck = v and true or false end,
    })

    Opt:Toggle({
        Name = "Wall Check",
        Flag = "TriggerWall",
        Default = false,
        Callback = function(v) CFG.WallCheck = v and true or false end,
    })

    Opt:Toggle({
        Name = "Require Tool",
        Flag = "TriggerRequireTool",
        Default = true,
        Callback = function(v) CFG.RequireTool = v and true or false end,
    })

    Opt:Toggle({
        Name = "Show Range",
        Flag = "TriggerShowRange",
        Default = true,
        Callback = function(v) CFG.ShowRange = v and true or false end,
    }):Colorpicker({
        Flag = "TriggerRangeColor",
        Default = Color3.fromRGB(80, 255, 120),
        Callback = function(c)
            if typeof(c) == "Color3" then
                CFG.RangeColor = c
            end
        end,
    })
end

Window:Init()

-- fix autoload / bad saved delay
pcall(function()
    local path = Library.Directory .. "/autoload.json"
    if isfile(path) then
        local raw = readfile(path)
        if raw and #raw > 2 then
            Library:LoadConfig(raw)
        end
    end
end)

CFG.DelayMs = clampDelay(CFG.DelayMs)
if Library.Flags and Library.Flags.TriggerDelayMs ~= nil then
    local f = Library.Flags.TriggerDelayMs
    if type(f) == "number" then
        CFG.DelayMs = clampDelay(f)
    end
end

notify("SA2 triggerbot loaded", 3)
