-- GameServer: Brainrot Base Rush.
-- Spawning (every ~6s a brainrot walks the path from the portal to the
-- base), buying on touch, per-second earnings, the Brainrot Tsunami wave
-- every ~90s, the Noob Nabber thief every ~75s, and Rebirth at $25,000
-- lifetime earned. HUD state is pushed to clients once a second.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService") -- tsunami wall sweep
local Workspace = game:GetService("Workspace")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local BrainrotFactory = require(script:WaitForChild("BrainrotFactory"))

-- Remotes (created here so the place file needs no hand-made instances).
local updateHud = Instance.new("RemoteEvent")
updateHud.Name = "UpdateHUD"
updateHud.Parent = ReplicatedStorage

local announceEvent = Instance.new("RemoteEvent")
announceEvent.Name = "Announce"
announceEvent.Parent = ReplicatedStorage

local slapEvent = Instance.new("RemoteEvent")
slapEvent.Name = "SlapHit"
slapEvent.Parent = ReplicatedStorage

local rebirthEvent = Instance.new("RemoteEvent")
rebirthEvent.Name = "RequestRebirth"
rebirthEvent.Parent = ReplicatedStorage

-- World landmarks (must match the Parts in default.project.json).
local PORTAL_POS = Vector3.new(0, 0, -80)
local BASE_CENTER = Vector3.new(0, 2, 70)
local WAYPOINTS = {
	Vector3.new(0, 0, -40),
	Vector3.new(25, 0, -20),
	Vector3.new(25, 0, 20),
	Vector3.new(0, 0, 50),
}
local SLOT_POSITIONS = {}
for row = 1, 2 do
	for col = 1, 4 do
		local x = -22.5 + (col - 1) * 15
		local z = 62 + (row - 1) * 16
		table.insert(SLOT_POSITIONS, Vector3.new(x, 2, z))
	end
end

local function inSafeZone(pos)
	return math.abs(pos.X) <= 30 and pos.Z >= 50 and pos.Z <= 90
end

local function announceAll(text, color)
	announceEvent:FireAllClients(text, color)
end

-- Per-player state.
local playerState = {}

local function newState()
	return {
		money = BrainrotData.STARTING_MONEY,
		lifetimeEarned = 0,
		rebirths = 0,
		owned = {},
	}
end

local function earningsMultiplier(state)
	return 1 + BrainrotData.REBIRTH_BONUS * state.rebirths
end

local function incomePerSecond(state)
	local total = 0
	for _, record in ipairs(state.owned) do
		total += record.def.rate * record.mutationMult
	end
	return total * earningsMultiplier(state)
end

local function freeSlot(state)
	for i = 1, BrainrotData.MAX_SLOTS do
		local taken = false
		for _, record in ipairs(state.owned) do
			if record.slot == i then
				taken = true
				break
			end
		end
		if not taken then
			return i
		end
	end
	return nil
end

local function sendHud(player)
	local state = playerState[player]
	if not state then
		return
	end
	updateHud:FireClient(player, {
		money = state.money,
		rate = incomePerSecond(state),
		count = #state.owned,
		maxSlots = BrainrotData.MAX_SLOTS,
		nextName = nextSpawnDef.name,
		nextRarity = nextSpawnDef.rarity,
		nextMutation = nextSpawnMutation,
		waveIn = waveCountdown,
		thiefActive = thief ~= nil,
		rebirthReady = state.lifetimeEarned >= BrainrotData.REBIRTH_REQUIREMENT,
		lifetimeEarned = state.lifetimeEarned,
		rebirthRequirement = BrainrotData.REBIRTH_REQUIREMENT,
		multiplier = earningsMultiplier(state),
		rebirths = state.rebirths,
	})
end

-- Move + rotate a whole Part-assembled model rigidly around its PrimaryPart.
-- (Model:PivotTo uses the bounding-box pivot, which would sink the model
-- into the ground, so the server moves models through their PrimaryPart.)
local function setModelCFrame(model, cf)
	local primary = model.PrimaryPart
	if not primary then
		return
	end
	local offset = cf * primary.CFrame:Inverse()
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CFrame = offset * part.CFrame
		end
	end
end

-- Move a model toward a target ground position at the given speed
-- (studs/second), facing its direction of travel. Returns when it arrives.
-- The model's feet stay on the ground: the PrimaryPart rides 1.5 studs up.
local function walkTo(model, target, speed)
	local primary = model.PrimaryPart
	if not primary then
		return
	end
	while model.Parent ~= nil do
		local current = primary.Position
		local ground = Vector3.new(current.X, 0, current.Z)
		local delta = target - ground
		delta = Vector3.new(delta.X, 0, delta.Z)
		local distance = delta.Magnitude
		if distance < 0.5 then
			return
		end
		local step = math.min(distance, speed * 0.05)
		local nextGround = ground + delta.Unit * step
		local nextPos = Vector3.new(nextGround.X, 1.5, nextGround.Z)
		local look = CFrame.lookAt(nextPos, nextPos + delta)
		setModelCFrame(model, look)
		task.wait(0.05)
	end
end

-- Smoothly slide a whole model to a target ground position (feet on the
-- ground: the PrimaryPart ends 1.5 studs above the target).
local function tweenModelTo(model, target, seconds)
	local primary = model.PrimaryPart
	if not primary or model.Parent == nil then
		return
	end
	local start = primary.CFrame
	local goal = CFrame.new(target + Vector3.new(0, 1.5, 0))
	local steps = math.max(1, math.floor(seconds / 0.05))
	for i = 1, steps do
		if model.Parent == nil then
			return
		end
		setModelCFrame(model, start:Lerp(goal, i / steps))
		task.wait(0.05)
	end
end

-- The next brainrot to spawn (pre-rolled so the HUD can preview it).
nextSpawnDef = BrainrotData.pickRandom()
nextSpawnMutation, nextSpawnMult = BrainrotData.rollMutation()

local function rollNextSpawn()
	nextSpawnDef = BrainrotData.pickRandom()
	nextSpawnMutation, nextSpawnMult = BrainrotData.rollMutation()
end

local function tryBuy(player, model, record)
	local state = playerState[player]
	if not state or record.bought then
		return
	end
	if record.def.cost > state.money then
		return
	end
	local slot = freeSlot(state)
	if not slot then
		announceEvent:FireClient(player, "Your base is FULL! Rebirth to grow.", Color3.fromRGB(255, 180, 30))
		return
	end
	record.bought = true
	state.money -= record.def.cost
	record.slot = slot
	table.insert(state.owned, record)
	record.model = model
	announceEvent:FireClient(player, "You bought " .. record.def.name .. " for " .. BrainrotData.formatMoney(record.def.cost) .. "!", Color3.fromRGB(120, 255, 120))
	task.spawn(function()
		tweenModelTo(model, SLOT_POSITIONS[slot], 1.5)
	end)
end

local function spawnBrainrot()
	local def = nextSpawnDef
	local mutation = nextSpawnMutation
	local mutationMult = nextSpawnMult
	rollNextSpawn()

	local model = BrainrotFactory.build(def, mutation, PORTAL_POS)
	model.Parent = Workspace

	local record = {
		def = def,
		mutation = mutation,
		mutationMult = mutationMult,
		model = model,
		bought = false,
		slot = nil,
	}
	local debounce = {}

	local function onTouched(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end
		if debounce[player] then
			return
		end
		debounce[player] = true
		task.delay(1, function()
			debounce[player] = false
		end)
		tryBuy(player, model, record)
	end

	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") then
			part.Touched:Connect(onTouched)
		end
	end

	task.spawn(function()
		for _, waypoint in ipairs(WAYPOINTS) do
			if record.bought or model.Parent == nil then
				return
			end
			walkTo(model, waypoint, 7)
		end
		-- Linger at the base entrance so players can still grab it.
		local waited = 0
		while not record.bought and model.Parent ~= nil and waited < 25 do
			task.wait(1)
			waited += 1
		end
		if not record.bought and model.Parent ~= nil then
			model:Destroy()
		end
	end)
end

-- Tsunami wave: a wall sweeps the arena; anyone outside the base loses 10%.
waveCountdown = BrainrotData.WAVE_INTERVAL

local function runWave()
	announceAll("BRAINROT TSUNAMI! Get to your BASE!", Color3.fromRGB(255, 60, 60))
	local wall = Instance.new("Part")
	wall.Name = "TsunamiWall"
	wall.Shape = Enum.PartType.Block
	wall.Size = Vector3.new(220, 30, 4)
	wall.Color = Color3.fromRGB(30, 140, 255)
	wall.Material = Enum.Material.Neon
	wall.Anchored = true
	wall.CanCollide = false
	wall.Position = Vector3.new(0, 12, -110)
	wall.Parent = Workspace

	local tween = TweenService:Create(wall, TweenInfo.new(4, Enum.EasingStyle.Linear), { Position = Vector3.new(0, 12, 110) })
	tween:Play()

	-- Punish once, as the wall passes the middle of the arena.
	task.wait(2)
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and not inSafeZone(root.Position) then
			local state = playerState[player]
			if state then
				local lost = math.floor(state.money * BrainrotData.WAVE_CASH_LOSS)
				state.money = math.max(0, state.money - lost)
				announceEvent:FireClient(player, "The tsunami caught you outside! You lost " .. BrainrotData.formatMoney(lost) .. ".", Color3.fromRGB(255, 120, 120))
			end
			root.CFrame = CFrame.new(BASE_CENTER + Vector3.new(math.random(-10, 10), 3, math.random(-8, 8)))
		end
	end
	tween.Completed:Wait()
	wall:Destroy()
	announceAll("The tsunami passed. Your base kept you safe!", Color3.fromRGB(120, 200, 255))
end

-- Noob Nabber thief: runs to a random owned brainrot, channels 3s, steals it
-- unless a player slaps him away with the Slap tool first.
thief = nil

local function spawnThief()
	local candidates = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local state = playerState[player]
		if state and #state.owned > 0 then
			table.insert(candidates, player)
		end
	end
	if #candidates == 0 then
		return
	end
	local victim = candidates[math.random(1, #candidates)]
	local state = playerState[victim]
	local record = state.owned[math.random(1, #state.owned)]

	local model = BrainrotFactory.buildThief(PORTAL_POS)
	model.Parent = Workspace
	thief = { model = model, victim = victim, record = record, channeling = false }
	announceAll("Noob Nabber is coming to STEAL a brainrot! SLAP him with your Slap tool!", Color3.fromRGB(255, 60, 60))

	task.spawn(function()
		local targetPos = SLOT_POSITIONS[record.slot] + Vector3.new(0, 0, 4)
		walkTo(model, targetPos, 10)
		if thief == nil or thief.model ~= model then
			return
		end
		thief.channeling = true
		announceAll("Noob Nabber is stealing " .. record.def.name .. "! Slap him NOW!", Color3.fromRGB(255, 60, 60))
		local elapsed = 0
		while elapsed < BrainrotData.THIEF_CHANNEL do
			task.wait(0.5)
			elapsed += 0.5
			if thief == nil or thief.model ~= model then
				return
			end
		end
		-- Channel complete: the brainrot is gone.
		if record.model and record.model.Parent ~= nil then
			record.model:Destroy()
		end
		for i, owned in ipairs(state.owned) do
			if owned == record then
				table.remove(state.owned, i)
				break
			end
		end
		announceAll("Noob Nabber stole " .. record.def.name .. " from " .. victim.Name .. "!", Color3.fromRGB(255, 60, 60))
		if model.Parent ~= nil then
			model:Destroy()
		end
		thief = nil
	end)
end

slapEvent.OnServerEvent:Connect(function(player)
	if thief == nil or thief.model.Parent == nil then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local thiefRoot = thief.model.PrimaryPart
	if not root or not thiefRoot then
		return
	end
	if (root.Position - thiefRoot.Position).Magnitude > 15 then
		return
	end
	-- Slap landed: fling the thief away and despawn him.
	local model = thief.model
	thief = nil
	announceAll(player.Name .. " slapped the Noob Nabber away!", Color3.fromRGB(120, 255, 120))
	task.spawn(function()
		local start = model.PrimaryPart.CFrame
		local goal = start * CFrame.new(0, 25, -40)
		for i = 1, 16 do
			if model.Parent == nil then
				return
			end
			setModelCFrame(model, start:Lerp(goal, i / 16))
			task.wait(0.05)
		end
		if model.Parent ~= nil then
			model:Destroy()
		end
	end)
end)

rebirthEvent.OnServerEvent:Connect(function(player)
	local state = playerState[player]
	if not state then
		return
	end
	if state.lifetimeEarned < BrainrotData.REBIRTH_REQUIREMENT then
		return
	end
	for _, record in ipairs(state.owned) do
		if record.model and record.model.Parent ~= nil then
			record.model:Destroy()
		end
	end
	state.owned = {}
	state.money = BrainrotData.STARTING_MONEY
	state.rebirths += 1
	announceEvent:FireClient(player, "REBIRTH! Permanent +" .. tostring(math.floor(BrainrotData.REBIRTH_BONUS * 100)) .. "% earnings (x" .. string.format("%.1f", earningsMultiplier(state)) .. ").", Color3.fromRGB(255, 215, 0))
	sendHud(player)
end)

local function onPlayerAdded(player)
	playerState[player] = newState()
	player:LoadCharacter()
	task.spawn(function()
		while player.Parent ~= nil do
			sendHud(player)
			task.wait(1)
		end
	end)
end

local function onPlayerRemoving(player)
	local state = playerState[player]
	if state then
		for _, record in ipairs(state.owned) do
			if record.model and record.model.Parent ~= nil then
				record.model:Destroy()
			end
		end
	end
	playerState[player] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Main loops: economy tick, spawning, wave timer, thief timer.
task.spawn(function()
	while true do
		task.wait(1)
		for player, state in pairs(playerState) do
			local earned = incomePerSecond(state)
			state.money += earned
			state.lifetimeEarned += earned
		end
		waveCountdown -= 1
		if waveCountdown == BrainrotData.WAVE_WARNING then
			announceAll("BRAINROT TSUNAMI in 10 seconds! Get to your BASE!", Color3.fromRGB(255, 180, 30))
		elseif waveCountdown <= 0 then
			waveCountdown = BrainrotData.WAVE_INTERVAL
			task.spawn(runWave)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(BrainrotData.SPAWN_INTERVAL)
		spawnBrainrot()
	end
end)

task.spawn(function()
	while true do
		task.wait(BrainrotData.THIEF_INTERVAL)
		spawnThief()
	end
end)

print("Brainrot Base Rush server ready.")
