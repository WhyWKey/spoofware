local LIBRARY_URL = "https://raw.githubusercontent.com/cueshut/vitremake/main/vitality.lua"
local Library = loadstring(game:HttpGet(LIBRARY_URL))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Flags = Library.Flags

local function flag(name, fallback)
	local v = Flags[name]
	if v == nil then return fallback end
	return v
end

local function flagBool(name, fallback)
	local v = Flags[name]
	if v == nil then return fallback == true end
	return v == true
end

local function flagNum(name, fallback)
	local n = tonumber(Flags[name])
	if n == nil then return fallback end
	return n
end

local function flagColor(name, fallback)
	local v = Flags[name]
	if typeof(v) == "Color3" then return v end
	if typeof(v) == "table" then
		if typeof(v.Color) == "Color3" then return v.Color end
		if typeof(v.Value) == "Color3" then return v.Value end
	end
	return fallback
end

local function flagAlpha(name, fallback)
	local v = Flags[name]
	if typeof(v) == "table" and typeof(v.Alpha) == "number" then
		return math.clamp(v.Alpha, 0, 1)
	end
	return fallback
end

local function keybindActive(flagName)
	local v = Flags[flagName]
	if v == nil then return true end
	if typeof(v) == "table" then
		local key = v.Key
		local mode = v.Mode or "Hold"
		if key == nil or key == "" or key == "None" or tostring(key):find("Unknown") then
			return true
		end
		if mode == "Always" then return true end
		return v.Toggled == true
	end
	return true
end

local function aimActive(prefix)
	if not flagBool(prefix .. "_aim_enabled", false) then return false end
	return keybindActive(prefix .. "_aim_bind")
end

local Window = Library:Window({ Name = "Room" })

pcall(function()
	local wm = Library:Watermark({ Name = "Room", SubName = "combat" })
	Library.WatermarkObject = wm or Library.WatermarkObject
end)
pcall(function()
	local kl = Library:KeybindList({ Name = "Keybinds" })
	Library.KeyList = kl or Library.KeyList
end)

task.defer(function()
	local items = Window.Items
	if not items then return end
	if items.IconBar and items.IconBar.Instance then
		items.IconBar.Instance.Visible = false
	end
	for _, key in ipairs({
		"HomeButton", "ConsoleButton", "PlayersButton",
		"KeybindsButton", "NotifyButton",
	}) do
		local btn = items[key]
		if btn and btn.Instance then
			btn.Instance.Visible = false
		end
	end
end)

local function isDeadModel(model)
	if not model or not model.Parent then return true end
	if model:GetAttribute("Dead") == true then return true end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health <= 0 then return true end
	return false
end

local function findRoot(model)
	local p = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("RootPart") or model.PrimaryPart
	if p and p:IsA("BasePart") then return p end
	for _, d in ipairs(model:GetChildren()) do
		if d:IsA("BasePart") then return d end
	end
	return nil
end

local function resolveNape(model)
	local hitboxes = model:FindFirstChild("Hitboxes")
	if hitboxes then
		local nape = hitboxes:FindFirstChild("Nape")
		if nape and nape:IsA("BasePart") then return nape end
		if nape then
			for _, d in ipairs(nape:GetDescendants()) do
				if d:IsA("BasePart") then return d end
			end
		end
	end
	local nape = model:FindFirstChild("Nape", true)
	if nape and nape:IsA("BasePart") then return nape end
	return nil
end

local cachedTitans, cachedPlayers = {}, {}
local lastTargetRefresh = 0

local function refreshTargets()
	local titans, seen = {}, {}
	local function push(model)
		if not model or not model:IsA("Model") or seen[model] or isDeadModel(model) then return end
		local p = model.Parent
		if p and p.Name == "Dead" then return end
		local root = findRoot(model)
		if not root then return end
		seen[model] = true
		titans[#titans + 1] = { Model = model, Root = root, Kind = "Titan" }
	end
	local folder = Workspace:FindFirstChild("Titans")
	if folder then
		local alive = folder:FindFirstChild("Alive")
		if alive then
			for _, c in ipairs(alive:GetChildren()) do push(c) end
		end
		for _, c in ipairs(folder:GetChildren()) do
			if c.Name ~= "Dead" and c.Name ~= "Alive" then
				if c:IsA("Model") then push(c)
				elseif c:IsA("Folder") then
					for _, x in ipairs(c:GetChildren()) do push(x) end
				end
			end
		end
	end
	cachedTitans = titans
	local players = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local char = plr.Character
			if char and not isDeadModel(char) then
				local root = findRoot(char)
				local hum = char:FindFirstChildOfClass("Humanoid")
				if root and hum and hum.Health > 0 then
					players[#players + 1] = { Model = char, Root = root, Kind = "Player", Player = plr }
				end
			end
		end
	end
	cachedPlayers = players
end

local function getTargets(prefix)
	if os.clock() - lastTargetRefresh >= 0.2 then
		lastTargetRefresh = os.clock()
		refreshTargets()
	end
	return prefix == "pve" and cachedTitans or cachedPlayers
end

local function mousePos()
	return UserInputService:GetMouseLocation()
end

local function worldToScreen(pos)
	local v, on = Camera:WorldToViewportPoint(pos)
	return Vector2.new(v.X, v.Y), on and v.Z > 0, v.Z
end

local function visibleCheck(origin, targetPart, subject)
	if not origin or not targetPart then return false end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.FilterDescendantsInstances = { LocalPlayer.Character, Camera, subject }
	local function clearTo(pos)
		local dir = pos - origin
		if dir.Magnitude < 0.05 then return true end
		return Workspace:Raycast(origin, dir, params) == nil
	end
	if clearTo(targetPart.Position) then return true end
	local cf, s = targetPart.CFrame, targetPart.Size * 0.35
	for _, off in ipairs({
		Vector3.new(s.X, 0, 0), Vector3.new(-s.X, 0, 0),
		Vector3.new(0, s.Y, 0), Vector3.new(0, -s.Y, 0),
		Vector3.new(0, 0, s.Z), Vector3.new(0, 0, -s.Z),
	}) do
		if clearTo((cf * CFrame.new(off)).Position) then return true end
	end
	return false
end

local function multiHas(tbl, name)
	if typeof(tbl) ~= "table" then return true end
	if tbl[name] == true then return true end
	for _, v in pairs(tbl) do
		if v == name or tostring(v) == name then return true end
	end
	if name ~= "Head" and multiHas(tbl, "Body") then return true end
	return false
end

local function pickPlayerPart(model, priority, allowed, center)
	local names = { "Head", "Torso", "UpperTorso", "HumanoidRootPart" }
	local parts = {}
	for _, n in ipairs(names) do
		local p = model:FindFirstChild(n, true)
		if p and p:IsA("BasePart") and multiHas(allowed, n) then
			parts[#parts + 1] = p
		end
	end
	if #parts == 0 then return findRoot(model) end
	if priority == "Head" then
		for _, p in ipairs(parts) do if p.Name == "Head" then return p end end
	elseif priority == "Torso" then
		for _, p in ipairs(parts) do
			if p.Name == "Torso" or p.Name == "UpperTorso" then return p end
		end
	end
	local best, bestD
	for _, p in ipairs(parts) do
		local sp, on = worldToScreen(p.Position)
		if on then
			local d = (sp - center).Magnitude
			if not bestD or d < bestD then best, bestD = p, d end
		end
	end
	return best or parts[1]
end

local function scoreTarget(part, center, fovPx)
	local sp, on = worldToScreen(part.Position)
	if on then
		local d = (sp - center).Magnitude
		if d <= fovPx then return d, sp, true end
	end
	local origin = Camera.CFrame.Position
	local to = part.Position - origin
	if to.Magnitude < 1 then return nil end
	local deg = math.deg(math.acos(math.clamp(to.Unit:Dot(Camera.CFrame.LookVector), -1, 1)))
	if deg <= math.clamp(fovPx / 6, 8, 120) then return deg * 15, sp, on == true end
	return nil
end

local function findBestTarget(prefix)
	local fov = flagNum(prefix .. "_aim_fov", 180)
	local dyn = flagNum(prefix .. "_aim_dynfov", 0)
	local dead = flagNum(prefix .. "_aim_deadzone", 0)
	local follow = flagBool(prefix .. "_aim_follow", true)
	local vis = flagBool(prefix .. "_aim_vischeck", false)
	local priority = tostring(flag(prefix .. "_aim_priority", "Closest"))
	local points = flag(prefix .. "_aim_points", { Head = true, Torso = true })
	local range = flagNum(prefix .. "_aim_range", 3000)
	local origin = Camera.CFrame.Position
	local center = follow and mousePos() or (Camera.ViewportSize * 0.5)
	local effectiveFov = math.max(20, fov * (1 - (dyn / 100) * 0.4))
	local best, bestScore
	for _, t in ipairs(getTargets(prefix)) do
		if t.Model.Parent and not isDeadModel(t.Model) then
			local dist = (t.Root.Position - origin).Magnitude
			if dist <= range then
				local part
				if prefix == "pve" then
					part = resolveNape(t.Model)
				else
					part = pickPlayerPart(t.Model, priority, points, center)
				end
				if part then
					local score = scoreTarget(part, center, effectiveFov)
					if not score and prefix == "pve" then
						score = scoreTarget(t.Root, center, effectiveFov * 1.75)
					end
					if score and score >= dead then
						local canSee = true
						if vis then
							canSee = visibleCheck(origin, part, t.Model)
							if not canSee then
								local head = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("Head") or LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
								if head then canSee = visibleCheck(head.Position, part, t.Model) end
							end
						end
						if canSee and (not bestScore or score < bestScore) then
							bestScore = score
							best = { Target = t, Part = part, Dist = dist }
						end
					end
				end
			end
		end
	end
	return best
end

local aimState = { pve = nil, pvp = nil }

local function runAimbot(prefix)
	if not aimActive(prefix) then
		aimState[prefix] = nil
		return
	end
	local locked = flagBool(prefix .. "_aim_lock", false)
	local current = aimState[prefix]
	if locked and current and current.Target and current.Target.Model.Parent and not isDeadModel(current.Target.Model) then
		if prefix == "pve" then
			current.Part = resolveNape(current.Target.Model) or current.Part
		else
			current.Part = pickPlayerPart(current.Target.Model, tostring(flag(prefix .. "_aim_priority", "Closest")), flag(prefix .. "_aim_points", { Head = true }), mousePos()) or current.Part
		end
	else
		current = findBestTarget(prefix)
		aimState[prefix] = current
	end
	if not current or not current.Part then return end
	local mouse = mousePos()
	local sp, on = worldToScreen(current.Part.Position)
	local step = math.clamp((110 - flagNum(prefix .. "_aim_smooth", 40)) / 100, 0.05, 1)
	if on and typeof(mousemoverel) == "function" then
		local delta = (sp - mouse) * step
		mousemoverel(delta.X, delta.Y)
	else
		Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, current.Part.Position), step)
	end
end

local fovCircles = {}
local function updateFov(prefix)
	local c = fovCircles[prefix]
	if not c then
		c = Drawing.new("Circle")
		c.Filled = false
		c.Thickness = 1.2
		c.NumSides = 48
		fovCircles[prefix] = c
	end
	if not flagBool(prefix .. "_aim_showfov", true) then
		c.Visible = false
		return
	end
	c.Color = flagColor(prefix .. "_aim_fov_color", Color3.fromRGB(255, 255, 255))
	c.Position = mousePos()
	c.Radius = flagNum(prefix .. "_aim_fov", 180)
	c.Visible = true
end

local highlights = {}
local hlFolder
local function getHlFolder()
	if hlFolder and hlFolder.Parent then return hlFolder end
	local parent
	pcall(function() parent = game:GetService("CoreGui") end)
	if not parent then parent = LocalPlayer:WaitForChild("PlayerGui") end
	hlFolder = parent:FindFirstChild("RoomHighlights") or Instance.new("Folder")
	hlFolder.Name = "RoomHighlights"
	hlFolder.Parent = parent
	return hlFolder
end

local function clearHighlights(prefix)
	for model, h in pairs(highlights) do
		if not prefix or h.Prefix == prefix then
			pcall(function() h.Instance:Destroy() end)
			highlights[model] = nil
		end
	end
end

local function applyHighlight(model, prefix, outlineOn, fillOn, oc, oa, fc, fa)
	local h = highlights[model]
	if not h or not h.Instance or not h.Instance.Parent then
		if h and h.Instance then pcall(function() h.Instance:Destroy() end) end
		local inst = Instance.new("Highlight")
		inst.Name = "RoomHL"
		inst.DepthMode = Enum.HighlightDepthMode.Occluded
		inst.Adornee = model
		inst.Parent = getHlFolder()
		h = { Instance = inst, Prefix = prefix }
		highlights[model] = h
	else
		h.Prefix = prefix
		if h.Instance.Adornee ~= model then h.Instance.Adornee = model end
	end
	local ot, ft = outlineOn and oa or 1, fillOn and fa or 1
	if h._oc ~= oc then h.Instance.OutlineColor = oc h._oc = oc end
	if h._fc ~= fc then h.Instance.FillColor = fc h._fc = fc end
	if h._ot ~= ot then h.Instance.OutlineTransparency = ot h._ot = ot end
	if h._ft ~= ft then h.Instance.FillTransparency = ft h._ft = ft end
end

local function runEsp(prefix)
	local outlineOn = flagBool(prefix .. "_esp_outline", false)
	local fillOn = flagBool(prefix .. "_esp_fill", false)
	if not outlineOn and not fillOn then clearHighlights(prefix) return end
	local oc = flagColor(prefix .. "_esp_outline_color", Color3.fromRGB(255, 90, 90))
	local oa = flagAlpha(prefix .. "_esp_outline_color", 0)
	local fc = flagColor(prefix .. "_esp_fill_color", Color3.fromRGB(255, 90, 90))
	local fa = flagAlpha(prefix .. "_esp_fill_color", 0.7)
	local origin = Camera.CFrame.Position
	local maxDist = flagNum(prefix .. "_esp_range", 5000)
	local maxCount = math.floor(flagNum(prefix .. "_esp_max", 48))
	local scored = {}
	for _, t in ipairs(getTargets(prefix)) do
		if t.Root then
			local d = (t.Root.Position - origin).Magnitude
			if d <= maxDist then scored[#scored + 1] = { Model = t.Model, Dist = d } end
		end
	end
	table.sort(scored, function(a, b) return a.Dist < b.Dist end)
	local alive, n = {}, 0
	for _, e in ipairs(scored) do
		if n >= maxCount then break end
		n = n + 1
		alive[e.Model] = true
		applyHighlight(e.Model, prefix, outlineOn, fillOn, oc, oa, fc, fa)
	end
	for model, h in pairs(highlights) do
		if h.Prefix == prefix and not alive[model] then
			pcall(function() h.Instance:Destroy() end)
			highlights[model] = nil
		end
	end
end

local function distToPartSurface(fromPos, part)
	local localPos = part.CFrame:PointToObjectSpace(fromPos)
	local half = part.Size * 0.5
	local closest = part.CFrame * Vector3.new(
		math.clamp(localPos.X, -half.X, half.X),
		math.clamp(localPos.Y, -half.Y, half.Y),
		math.clamp(localPos.Z, -half.Z, half.Z)
	)
	return (fromPos - closest).Magnitude
end

local trigHolding = false
local function setAttackHold(on)
	if on == trigHolding then return end
	trigHolding = on
	if typeof(mouse1press) == "function" then
		if on then pcall(mouse1press)
		else pcall(function() if mouse1release then mouse1release() end end) end
		return
	end
	pcall(function()
		game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, on, game, 1)
	end)
end

local function runNapeTriggerbot()
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local napeRange = flagNum("pve_trig_range", 14)
	local hangRange = flagNum("pve_trig_hang", 120)
	local origin = hrp.Position
	local nearTitan, atNape = false, false
	for _, t in ipairs(getTargets("pve")) do
		if t.Root and (origin - t.Root.Position).Magnitude <= hangRange then nearTitan = true end
		local nape = resolveNape(t.Model)
		if nape and distToPartSurface(origin, nape) <= napeRange then atNape = true break end
	end
	if atNape then setAttackHold(false) return true
	elseif nearTitan then setAttackHold(true) return true end
	return false
end

local function runPlayerTriggerbot()
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local hitRange = flagNum("pvp_trig_range", 8)
	local hangRange = flagNum("pvp_trig_hang", 60)
	local origin = hrp.Position
	local nearPlayer, atHitbox = false, false
	for _, t in ipairs(getTargets("pvp")) do
		local part = t.Root
		if part then
			if (origin - part.Position).Magnitude <= hangRange then nearPlayer = true end
			if distToPartSurface(origin, part) <= hitRange then atHitbox = true break end
		end
	end
	if atHitbox then setAttackHold(false) return true
	elseif nearPlayer then setAttackHold(true) return true end
	return false
end

local function runTriggers()
	local pveOn = flagBool("pve_trig_enabled", false)
	local pvpOn = flagBool("pvp_trig_enabled", false)
	if not pveOn and not pvpOn then setAttackHold(false) return end
	local handled = false
	if pveOn then handled = runNapeTriggerbot() end
	if pvpOn and not handled then handled = runPlayerTriggerbot() end
	if not handled then setAttackHold(false) end
end

local napeOriginal, napeOverlays = {}, {}
local lastNapeAt = 0

local function getNapeParts(model)
	local parts = {}
	local nape = resolveNape(model)
	if nape then parts[1] = nape end
	return parts
end

local function restoreNapes()
	for part, data in pairs(napeOriginal) do
		if part and part.Parent then
			pcall(function()
				part.Size = data.Size
				part.Transparency = data.Transparency
				part.CanCollide = data.CanCollide
				part.Massless = data.Massless
			end)
		end
	end
	table.clear(napeOriginal)
end

local function clearNapeOverlays()
	for _, overlay in pairs(napeOverlays) do pcall(function() overlay:Destroy() end) end
	table.clear(napeOverlays)
	restoreNapes()
end

local function runNapeExpander()
	if not flagBool("misc_nape_enabled", false) then
		if next(napeOverlays) or next(napeOriginal) then clearNapeOverlays() end
		return
	end
	if os.clock() - lastNapeAt < 0.2 then return end
	lastNapeAt = os.clock()
	local scale = flagNum("misc_nape_size", 10)
	local show = flagBool("misc_nape_show", true)
	local col = flagColor("misc_nape_color", Color3.fromRGB(255, 60, 60))
	local alpha = flagAlpha("misc_nape_color", 0.55)
	local mat = Enum.Material[tostring(flag("misc_nape_material", "ForceField"))] or Enum.Material.ForceField
	local alive = {}
	for _, t in ipairs(getTargets("pve")) do
		for _, part in ipairs(getNapeParts(t.Model)) do
			alive[part] = true
			if not napeOriginal[part] then
				napeOriginal[part] = { Size = part.Size, Transparency = part.Transparency, CanCollide = part.CanCollide, Massless = part.Massless }
			end
			local base = napeOriginal[part].Size
			local target = Vector3.new(math.max(base.X * 1.05, scale), math.max(base.Y * 1.05, scale), math.max(base.Z * 1.05, scale))
			pcall(function()
				part.Size = target
				part.CanCollide = false
				part.Massless = true
				part.Transparency = 1
			end)
			if show then
				local overlay = napeOverlays[part]
				if not overlay or not overlay.Parent then
					overlay = Instance.new("Part")
					overlay.Name = "RoomNapeOverlay"
					overlay.Anchored = true
					overlay.CanCollide = false
					overlay.CanQuery = false
					overlay.CanTouch = false
					overlay.CastShadow = false
					overlay.Parent = Workspace.CurrentCamera or Workspace
					napeOverlays[part] = overlay
				end
				overlay.Size = target
				overlay.CFrame = part.CFrame
				overlay.Color = col
				overlay.Transparency = alpha
				overlay.Material = mat
			elseif napeOverlays[part] then
				pcall(function() napeOverlays[part]:Destroy() end)
				napeOverlays[part] = nil
			end
		end
	end
	for part, data in pairs(napeOriginal) do
		if not alive[part] or not part.Parent then
			if part and part.Parent then
				pcall(function()
					part.Size = data.Size
					part.Transparency = data.Transparency
					part.CanCollide = data.CanCollide
					part.Massless = data.Massless
				end)
			end
			napeOriginal[part] = nil
			if napeOverlays[part] then
				pcall(function() napeOverlays[part]:Destroy() end)
				napeOverlays[part] = nil
			end
		end
	end
end

local playerHbOriginal, playerOverlays = {}, {}
local lastPlayerHbAt = 0

local function restorePlayerHb()
	for part, data in pairs(playerHbOriginal) do
		if part and part.Parent then
			pcall(function()
				part.Size = data.Size
				part.Transparency = data.Transparency
				part.CanCollide = data.CanCollide
				part.Massless = data.Massless
			end)
		end
	end
	table.clear(playerHbOriginal)
	for part, overlay in pairs(playerOverlays) do
		pcall(function() overlay:Destroy() end)
		playerOverlays[part] = nil
	end
end

local function runPlayerHitboxExpander()
	if not flagBool("misc_player_hb_enabled", false) then
		if next(playerHbOriginal) or next(playerOverlays) then restorePlayerHb() end
		return
	end
	if os.clock() - lastPlayerHbAt < 0.25 then return end
	lastPlayerHbAt = os.clock()
	local scale = flagNum("misc_player_hb_size", 8)
	local show = flagBool("misc_player_hb_show", true)
	local col = flagColor("misc_player_hb_color", Color3.fromRGB(80, 160, 255))
	local alpha = flagAlpha("misc_player_hb_color", 0.55)
	local mat = Enum.Material[tostring(flag("misc_player_hb_material", "ForceField"))] or Enum.Material.ForceField
	local alive = {}
	for _, t in ipairs(getTargets("pvp")) do
		local part = t.Root
		if part and part:IsA("BasePart") then
			alive[part] = true
			if not playerHbOriginal[part] then
				playerHbOriginal[part] = { Size = part.Size, Transparency = part.Transparency, CanCollide = part.CanCollide, Massless = part.Massless }
			end
			local base = playerHbOriginal[part].Size
			local target = Vector3.new(math.max(base.X, scale), math.max(base.Y, scale), math.max(base.Z, scale))
			pcall(function()
				part.Size = target
				part.CanCollide = false
				part.Massless = true
				part.Transparency = 1
			end)
			if show then
				local overlay = playerOverlays[part]
				if not overlay or not overlay.Parent then
					overlay = Instance.new("Part")
					overlay.Name = "RoomPlayerHB"
					overlay.Anchored = true
					overlay.CanCollide = false
					overlay.CanQuery = false
					overlay.CanTouch = false
					overlay.CastShadow = false
					overlay.Parent = Workspace.CurrentCamera or Workspace
					playerOverlays[part] = overlay
				end
				overlay.Size = target
				overlay.CFrame = part.CFrame
				overlay.Color = col
				overlay.Transparency = alpha
				overlay.Material = mat
			elseif playerOverlays[part] then
				pcall(function() playerOverlays[part]:Destroy() end)
				playerOverlays[part] = nil
			end
		end
	end
	for part, data in pairs(playerHbOriginal) do
		if not alive[part] or not part.Parent then
			if part and part.Parent then
				pcall(function()
					part.Size = data.Size
					part.Transparency = data.Transparency
					part.CanCollide = data.CanCollide
					part.Massless = data.Massless
				end)
			end
			playerHbOriginal[part] = nil
			if playerOverlays[part] then
				pcall(function() playerOverlays[part]:Destroy() end)
				playerOverlays[part] = nil
			end
		end
	end
end

local lastBreakAt = 0
local function fireCounterHandslash()
	local ok, remotes = pcall(function()
		return game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
	end)
	if not ok or not remotes then return end
	local titan = remotes:FindFirstChild("Titan")
	local remote = titan and titan:FindFirstChild("CounterHandslash")
	if remote and remote:IsA("RemoteEvent") then
		pcall(function() remote:FireServer(true) end)
		pcall(function() remote:FireServer(false) end)
	end
end

local function runBreakFree()
	if not flagBool("misc_breakfree_enabled", false) then return end
	if LocalPlayer:GetAttribute("Grabbed") ~= true then return end
	if not keybindActive("misc_breakfree_bind") then return end
	if os.clock() - lastBreakAt < flagNum("misc_breakfree_rate", 0.15) then return end
	lastBreakAt = os.clock()
	fireCounterHandslash()
end

local odmRef, odmSearchAt, lastGasAt = nil, 0, 0
local function findODM()
	if odmRef then return odmRef end
	if os.clock() - odmSearchAt < 5 then return nil end
	odmSearchAt = os.clock()
	pcall(function()
		if typeof(getgc) ~= "function" then return end
		for _, v in getgc(true) do
			if typeof(v) == "table" and typeof(rawget(v, "maxGas")) == "number" and typeof(rawget(v, "currentGas")) == "number" then
				odmRef = v
				return
			end
		end
	end)
	return odmRef
end

local baseHookRange = nil
local lastHookAt = 0
local function runHookRange()
	if not flagBool("misc_hook_enabled", false) then return end
	if os.clock() - lastHookAt < 0.5 then return end
	lastHookAt = os.clock()
	local odm = findODM()
	if not odm then return end
	local desired = flagNum("misc_hook_range", 120)
	pcall(function()
		if typeof(odm.config) == "table" then
			if baseHookRange == nil and typeof(odm.config.hook_range) == "number" then
				baseHookRange = odm.config.hook_range
			end
			odm.config.hook_range = desired
		end
		if typeof(odm.CONSTANTS) == "table" and typeof(odm.CONSTANTS.HookRange) == "number" then
			odm.CONSTANTS.HookRange = desired
		end
		if typeof(rawget(odm, "HookRange")) == "number" then
			odm.HookRange = desired
		end
	end)
end

local lastRefillAt = 0
local function runAutoBladeRefill()
	if not flagBool("misc_auto_blade_refill", false) then return end
	if os.clock() - lastRefillAt < 0.6 then return end
	lastRefillAt = os.clock()

	local odm = findODM()
	local needBlades = true
	if odm then
		local cur = tonumber(odm.currentBlades)
		local maxB = tonumber(odm.maxBlades) or 4
		if cur and maxB and cur >= maxB then
			needBlades = false
		end
	end
	if not needBlades then return end

	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local origin = hrp.Position
	local range = flagNum("misc_auto_blade_range", 20)

	local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
	local bladeFolder = remotes and (remotes:FindFirstChild("BladeRefill") or remotes:FindFirstChild("GasRefill"))
	local startHold = bladeFolder and (bladeFolder:FindFirstChild("StartHold") or bladeFolder:FindFirstChild("RequestBlade") or bladeFolder:FindFirstChild("RequestGas"))
	local endHold = bladeFolder and bladeFolder:FindFirstChild("EndHold")

	local function tryFire(station)
		if startHold and startHold:IsA("RemoteEvent") then
			pcall(function() startHold:FireServer(station) end)
		end
		if endHold and endHold:IsA("RemoteEvent") then
			task.delay(0.35, function()
				pcall(function() endHold:FireServer(station) end)
			end)
		end
		if odm then
			pcall(function()
				local maxB = tonumber(odm.maxBlades) or 4
				odm.currentBlades = maxB
				local maxS = tonumber(odm.maxBladeState) or 10
				odm.bladeState = maxS
				if odm.bladesBroken then odm.bladesBroken = false end
			end)
		end
	end

	for _, inst in ipairs(Workspace:GetDescendants()) do
		local isBlade = false
		pcall(function()
			if inst:GetAttribute("IsBladeRefillPrompt") == true then isBlade = true end
			if inst:GetAttribute("SupplyBar") == true and inst:GetAttribute("IsGasRefillPrompt") ~= true then
				isBlade = true
			end
		end)
		if isBlade or (inst:IsA("ProximityPrompt") and tostring(inst.ActionText):lower():find("blade")) then
			local part = inst:IsA("BasePart") and inst or inst:FindFirstAncestorWhichIsA("BasePart")
			local station = inst
			if inst:IsA("ProximityPrompt") then
				station = inst.Parent
				part = station and (station:IsA("BasePart") and station or station:FindFirstAncestorWhichIsA("BasePart"))
			elseif inst:GetAttribute("IsBladeRefillPrompt") then
				station = inst.Parent and inst.Parent.Parent or inst.Parent or inst
			end
			if part and (part.Position - origin).Magnitude <= range then
				tryFire(station)
				if inst:IsA("ProximityPrompt") then
					pcall(function()
						fireproximityprompt(inst)
					end)
				end
				return
			end
		end
	end
end

local function runInfiniteGas()
	if not flagBool("misc_inf_gas", false) then return end
	if os.clock() - lastGasAt < 0.75 then return end
	lastGasAt = os.clock()
	local odm = findODM()
	if not odm then return end
	local maxG = tonumber(odm.maxGas) or 100
	if maxG <= 0 then maxG = 100 end
	local cur = tonumber(odm.currentGas)
	if cur and cur >= maxG * 0.95 then return end
	pcall(function()
		odm.currentGas = maxG
		if typeof(odm.SetGas) == "function" then odm:SetGas(maxG) end
	end)
end

local lastBladeAt = 0
local function runInfiniteBlades()
	local wantCount = flagBool("misc_inf_blades", false)
	local wantDur = flagBool("misc_inf_durability", false)
	if not wantCount and not wantDur then return end
	if os.clock() - lastBladeAt < 0.75 then return end
	lastBladeAt = os.clock()
	local odm = findODM()
	if not odm then return end
	pcall(function()
		if wantCount then
			local maxB = tonumber(odm.maxBlades) or 4
			if maxB <= 0 then maxB = 4 end
			local cur = tonumber(odm.currentBlades)
			if not cur or cur < maxB then
				odm.currentBlades = maxB
				if typeof(odm.SetBlades) == "function" then
					odm:SetBlades(maxB)
				end
			end
		end
		if wantDur then
			local maxS = tonumber(odm.maxBladeState) or tonumber(odm.BladeDurability) or 10
			if maxS <= 0 then maxS = 10 end
			local st = tonumber(odm.bladeState)
			if not st or st < maxS * 0.95 then
				odm.bladeState = maxS
				if typeof(odm.SetBladeState) == "function" then
					odm:SetBladeState(maxS)
				end
			end
			if odm.bladesBroken == true then
				odm.bladesBroken = false
			end
		end
	end)
end

local function buildAimSection(section, prefix, label)
	local en = section:Toggle({
		Name = "Enabled",
		Flag = prefix .. "_aim_enabled",
		Default = false,
		Tooltip = "Toggle on, hold keybind to aim at " .. label,
	})
	pcall(function()
		en:Keybind({
			Name = prefix .. " aim",
			Flag = prefix .. "_aim_bind",
			Mode = "Hold",
			GateByToggle = true,
			Default = Enum.KeyCode.E,
		})
	end)
	local showFov = section:Toggle({ Name = "Show FOV", Flag = prefix .. "_aim_showfov", Default = true })
	pcall(function()
		showFov:Colorpicker({
			Flag = prefix .. "_aim_fov_color",
			Default = prefix == "pve" and Color3.fromRGB(255, 200, 80) or Color3.fromRGB(80, 180, 255),
			Alpha = 0,
		})
	end)
	section:Slider({ Name = "FOV", Flag = prefix .. "_aim_fov", Min = 20, Max = 800, Default = prefix == "pve" and 250 or 140, Decimals = 0 })
	section:Slider({ Name = "Dynamic FOV", Flag = prefix .. "_aim_dynfov", Min = 0, Max = 100, Default = 0, Decimals = 0, Suffix = "%" })
	section:Slider({ Name = "Dead Zone", Flag = prefix .. "_aim_deadzone", Min = 0, Max = 50, Default = 0, Decimals = 0 })
	section:Toggle({ Name = "Follow Mouse", Flag = prefix .. "_aim_follow", Default = true })
	section:Toggle({ Name = "Lock Target", Flag = prefix .. "_aim_lock", Default = false })
	section:Toggle({ Name = "Visible Check", Flag = prefix .. "_aim_vischeck", Default = false })
	if prefix ~= "pve" then
		section:Dropdown({ Name = "Hitscan Priority", Flag = prefix .. "_aim_priority", Items = { "Closest", "Head", "Torso", "Body" }, Default = "Closest" })
		section:Dropdown({ Name = "Hitscan Points", Flag = prefix .. "_aim_points", Items = { "Head", "Torso", "Body" }, Multi = true, Default = { "Head", "Torso" } })
	else
		pcall(function() section:Label({ Name = "Target: Nape only (Hitboxes.Nape)" }) end)
	end
	section:Slider({ Name = "Smoothing", Flag = prefix .. "_aim_smooth", Min = 1, Max = 100, Default = 35, Decimals = 0 })
	section:Slider({ Name = "Activation Range", Flag = prefix .. "_aim_range", Min = 50, Max = 8000, Default = 3500, Decimals = 0 })
end

local function buildEspSection(section, prefix)
	local outline = section:Toggle({ Name = "Outline", Flag = prefix .. "_esp_outline", Default = false })
	pcall(function()
		outline:Colorpicker({ Flag = prefix .. "_esp_outline_color", Default = Color3.fromRGB(255, 90, 90), Alpha = 0 })
	end)
	local fill = section:Toggle({ Name = "Fill", Flag = prefix .. "_esp_fill", Default = false })
	pcall(function()
		fill:Colorpicker({ Flag = prefix .. "_esp_fill_color", Default = Color3.fromRGB(255, 90, 90), Alpha = 0.7 })
	end)
	section:Slider({ Name = "Max Targets", Flag = prefix .. "_esp_max", Min = 4, Max = 64, Default = 48, Decimals = 0 })
	section:Slider({ Name = "Range", Flag = prefix .. "_esp_range", Min = 200, Max = 8000, Default = 5000, Decimals = 0 })
end

local function buildTriggerSection(section, prefix, label)
	section:Toggle({
		Name = "Enabled",
		Flag = prefix .. "_trig_enabled",
		Default = false,
		Tooltip = "Hold M1 near target, release at " .. label,
	})
	section:Slider({ Name = "Release Range", Flag = prefix .. "_trig_range", Min = 2, Max = 40, Default = prefix == "pve" and 14 or 8, Decimals = 0.5 })
	section:Slider({ Name = "Hold Range", Flag = prefix .. "_trig_hang", Min = 20, Max = 250, Default = prefix == "pve" and 120 or 60, Decimals = 0 })
	pcall(function() section:Label({ Name = "Hold near · release at " .. label }) end)
end

local PvePage = Window:Page({ Name = "PVE" })
buildAimSection(PvePage:Section({ Name = "Aimbot", Side = 1 }), "pve", "titans")
buildTriggerSection(PvePage:Section({ Name = "Nape Triggerbot", Side = 2 }), "pve", "nape")
buildEspSection(PvePage:Section({ Name = "ESP", Side = 2 }), "pve")

local PvpPage = Window:Page({ Name = "PVP" })
buildAimSection(PvpPage:Section({ Name = "Aimbot", Side = 1 }), "pvp", "players")
buildTriggerSection(PvpPage:Section({ Name = "Triggerbot", Side = 2 }), "pvp", "hitbox")
buildEspSection(PvpPage:Section({ Name = "ESP", Side = 2 }), "pvp")

local MiscPage = Window:Page({ Name = "Misc" })
local MiscLeft = MiscPage:Section({ Name = "Break Free", Side = 1 })
local bf = MiscLeft:Toggle({ Name = "Enabled", Flag = "misc_breakfree_enabled", Default = false })
pcall(function()
	bf:Keybind({ Name = "break free", Flag = "misc_breakfree_bind", Mode = "Hold", GateByToggle = true, Default = Enum.KeyCode.Q })
end)
MiscLeft:Slider({ Name = "Attempt Rate", Flag = "misc_breakfree_rate", Min = 0.05, Max = 0.5, Default = 0.15, Decimals = 0.01, Suffix = "s" })
MiscLeft:Toggle({ Name = "Infinite Gas", Flag = "misc_inf_gas", Default = false, Tooltip = "ODM gas stay full (light updates)" })
MiscLeft:Toggle({ Name = "Infinite Blades", Flag = "misc_inf_blades", Default = false, Tooltip = "Keep blade cartridges full" })
MiscLeft:Toggle({ Name = "Infinite Durability", Flag = "misc_inf_durability", Default = false, Tooltip = "Keep blade durability full" })
MiscLeft:Toggle({ Name = "Hook Range", Flag = "misc_hook_enabled", Default = false, Tooltip = "Client ODM hook range" })
MiscLeft:Slider({ Name = "Hook Studs", Flag = "misc_hook_range", Min = 40, Max = 600, Default = 200, Decimals = 0 })
MiscLeft:Toggle({ Name = "Auto Blade Refill", Flag = "misc_auto_blade_refill", Default = false, Tooltip = "Refill blades near supply stations" })
MiscLeft:Slider({ Name = "Refill Range", Flag = "misc_auto_blade_range", Min = 5, Max = 40, Default = 20, Decimals = 0 })
pcall(function()
	MiscLeft:Label({ Name = "Damage mult is server-side — not available" })
end)

local MiscRight = MiscPage:Section({ Name = "Nape Expander", Side = 2 })
MiscRight:Toggle({ Name = "Enabled", Flag = "misc_nape_enabled", Default = false })
MiscRight:Slider({ Name = "Size", Flag = "misc_nape_size", Min = 2, Max = 40, Default = 10, Decimals = 0.5 })
local showBox = MiscRight:Toggle({ Name = "Show Box", Flag = "misc_nape_show", Default = true })
pcall(function()
	showBox:Colorpicker({ Flag = "misc_nape_color", Default = Color3.fromRGB(255, 60, 60), Alpha = 0.55 })
end)
MiscRight:Dropdown({ Name = "Box Material", Flag = "misc_nape_material", Items = { "ForceField", "Neon", "SmoothPlastic", "Glass", "Plastic" }, Default = "ForceField" })

local MiscPlayer = MiscPage:Section({ Name = "Player Hitbox", Side = 2 })
MiscPlayer:Toggle({ Name = "Enabled", Flag = "misc_player_hb_enabled", Default = false })
MiscPlayer:Slider({ Name = "Size", Flag = "misc_player_hb_size", Min = 2, Max = 25, Default = 8, Decimals = 0.5 })
local phShow = MiscPlayer:Toggle({ Name = "Show Box", Flag = "misc_player_hb_show", Default = true })
pcall(function()
	phShow:Colorpicker({ Flag = "misc_player_hb_color", Default = Color3.fromRGB(80, 160, 255), Alpha = 0.55 })
end)
MiscPlayer:Dropdown({ Name = "Box Material", Flag = "misc_player_hb_material", Items = { "ForceField", "Neon", "SmoothPlastic", "Glass", "Plastic" }, Default = "ForceField" })

Window:InitSettings()

task.defer(function()
	pcall(function()
		if Library.WatermarkObject and Library.WatermarkObject.SetVisibility then
			local on = true
			if Flags["hud_watermark"] ~= nil then
				on = Flags["hud_watermark"] == true
			end
			Library.WatermarkObject:SetVisibility(on)
		end
	end)
	pcall(function()
		if Library.KeyList and Library.KeyList.SetVisibility then
			local on = true
			if Flags["hud_keybindlist"] ~= nil then
				on = Flags["hud_keybindlist"] == true
			end
			Library.KeyList:SetVisibility(on)
		end
	end)
end)

local cursorGui
local function setCustomCursor(on)
	if on then
		if not cursorGui or not cursorGui.Parent then
			cursorGui = Instance.new("ScreenGui")
			cursorGui.Name = "RoomCursor"
			cursorGui.IgnoreGuiInset = true
			cursorGui.DisplayOrder = 2147483646
			cursorGui.ResetOnSpawn = false
			cursorGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			pcall(function() cursorGui.Parent = game:GetService("CoreGui") end)
			if not cursorGui.Parent then cursorGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
			local dot = Instance.new("Frame")
			dot.Name = "Dot"
			dot.AnchorPoint = Vector2.new(0.5, 0.5)
			dot.Size = UDim2.fromOffset(4, 4)
			dot.BorderSizePixel = 0
			dot.ZIndex = 100000
			dot.BackgroundColor3 = Library.Theme and Library.Theme.Accent or Color3.fromRGB(181, 32, 55)
			dot.Parent = cursorGui
			Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
			local ring = Instance.new("Frame")
			ring.Name = "Ring"
			ring.AnchorPoint = Vector2.new(0.5, 0.5)
			ring.Size = UDim2.fromOffset(14, 14)
			ring.BackgroundTransparency = 1
			ring.ZIndex = 100000
			ring.Parent = cursorGui
			local st = Instance.new("UIStroke")
			st.Thickness = 1.5
			st.Color = Library.Theme and Library.Theme.Accent or Color3.fromRGB(181, 32, 55)
			st.Parent = ring
			Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
		else
			cursorGui.DisplayOrder = 2147483646
		end
		cursorGui.Enabled = true
		UserInputService.MouseIconEnabled = false
	else
		if cursorGui then cursorGui.Enabled = false end
		UserInputService.MouseIconEnabled = true
	end
end

refreshTargets()
local lastEspAt = 0

local conn = RunService.RenderStepped:Connect(function()
	Camera = Workspace.CurrentCamera
	local menuOpen = Window.IsOpen ~= false
	local popupOpen = false
	pcall(function()
		if Library.OpenFrames then
			for _ in pairs(Library.OpenFrames) do popupOpen = true break end
		end
	end)
	local showCursor = menuOpen or popupOpen
	setCustomCursor(showCursor)
	if showCursor and cursorGui and cursorGui.Enabled then
		cursorGui.DisplayOrder = 2147483646
		local m = mousePos()
		local dot, ring = cursorGui:FindFirstChild("Dot"), cursorGui:FindFirstChild("Ring")
		if dot then dot.ZIndex = 100000 dot.Position = UDim2.fromOffset(m.X, m.Y) end
		if ring then ring.ZIndex = 100000 ring.Position = UDim2.fromOffset(m.X, m.Y) end
	end
	pcall(runAimbot, "pve")
	pcall(runAimbot, "pvp")
	pcall(updateFov, "pve")
	pcall(updateFov, "pvp")
	pcall(runNapeExpander)
	pcall(runPlayerHitboxExpander)
	pcall(runBreakFree)
	pcall(runInfiniteGas)
	pcall(runInfiniteBlades)
	pcall(runHookRange)
	pcall(runAutoBladeRefill)
	pcall(runTriggers)
	if os.clock() - lastEspAt >= 0.15 then
		lastEspAt = os.clock()
		pcall(runEsp, "pve")
		pcall(runEsp, "pvp")
	end
end)

pcall(function() Library:Notification({ Name = "Room loaded", Time = 3 }) end)

getgenv().RoomUnload = function()
	pcall(function() setAttackHold(false) end)
	pcall(function() conn:Disconnect() end)
	for _, c in pairs(fovCircles) do pcall(function() c:Remove() end) end
	clearHighlights(nil)
	pcall(clearNapeOverlays)
	pcall(restorePlayerHb)
	if hlFolder then pcall(function() hlFolder:Destroy() end) end
	if cursorGui then pcall(function() cursorGui:Destroy() end) end
	UserInputService.MouseIconEnabled = true
	if Library.Unload then pcall(function() Library:Unload() end) end
end
