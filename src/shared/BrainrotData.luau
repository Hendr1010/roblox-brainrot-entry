-- BrainrotData: shared definitions for Brainrot Base Rush.
-- Every brainrot, its rarity, earnings, price and look lives here so the
-- server (spawning, economy) and the client (HUD preview) agree exactly.

local BrainrotData = {}

BrainrotData.RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic" }

BrainrotData.RARITY_COLORS = {
	Common = Color3.fromRGB(160, 160, 160),
	Rare = Color3.fromRGB(60, 140, 255),
	Epic = Color3.fromRGB(170, 80, 255),
	Legendary = Color3.fromRGB(255, 180, 30),
	Mythic = Color3.fromRGB(255, 60, 120),
}

-- rate = dollars earned per second once owned. cost = buy price in dollars.
-- bodyColor / headColor / accessory describe the Part-assembled look;
-- accessory is one of: "log", "banana", "fin", "hat", "shell", "cactus",
-- "drum", "crown". BrainrotFactory builds the model from these fields.
BrainrotData.BRAINROTS = {
	{
		name = "Tung Tung Tung Sahur",
		rarity = "Common",
		rate = 1,
		cost = 25,
		bodyColor = Color3.fromRGB(139, 90, 43),
		headColor = Color3.fromRGB(160, 110, 60),
		accessory = "log",
	},
	{
		name = "Chimpanzini Bananini",
		rarity = "Common",
		rate = 2,
		cost = 60,
		bodyColor = Color3.fromRGB(120, 80, 40),
		headColor = Color3.fromRGB(150, 105, 55),
		accessory = "banana",
	},
	{
		name = "Tralalero Tralala",
		rarity = "Rare",
		rate = 5,
		cost = 200,
		bodyColor = Color3.fromRGB(70, 130, 200),
		headColor = Color3.fromRGB(120, 180, 230),
		accessory = "fin",
	},
	{
		name = "Ballerina Cappuccina",
		rarity = "Rare",
		rate = 8,
		cost = 350,
		bodyColor = Color3.fromRGB(245, 220, 200),
		headColor = Color3.fromRGB(255, 240, 220),
		accessory = "hat",
	},
	{
		name = "Bombardiro Crocodilo",
		rarity = "Epic",
		rate = 15,
		cost = 800,
		bodyColor = Color3.fromRGB(60, 160, 80),
		headColor = Color3.fromRGB(90, 190, 100),
		accessory = "shell",
	},
	{
		name = "Lirili Larila",
		rarity = "Epic",
		rate = 22,
		cost = 1200,
		bodyColor = Color3.fromRGB(255, 200, 90),
		headColor = Color3.fromRGB(255, 220, 140),
		accessory = "cactus",
	},
	{
		name = "Brr Brr Patapim",
		rarity = "Legendary",
		rate = 50,
		cost = 3000,
		bodyColor = Color3.fromRGB(200, 120, 60),
		headColor = Color3.fromRGB(230, 150, 80),
		accessory = "drum",
	},
	{
		name = "Giraffa Celeste",
		rarity = "Mythic",
		rate = 150,
		cost = 10000,
		bodyColor = Color3.fromRGB(255, 230, 120),
		headColor = Color3.fromRGB(255, 245, 180),
		accessory = "crown",
	},
}

BrainrotData.SPAWN_INTERVAL = 6
BrainrotData.WAVE_INTERVAL = 90
BrainrotData.WAVE_WARNING = 10
BrainrotData.THIEF_INTERVAL = 75
BrainrotData.THIEF_CHANNEL = 3
BrainrotData.REBIRTH_REQUIREMENT = 25000
BrainrotData.REBIRTH_BONUS = 0.5
BrainrotData.MAX_SLOTS = 8
BrainrotData.STARTING_MONEY = 50
BrainrotData.WAVE_CASH_LOSS = 0.10

-- Weighted spawn pick: cheap commons show up most, mythics almost never.
function BrainrotData.pickRandom()
	local roll = math.random(1, 100)
	local index = 1
	if roll <= 30 then
		index = 1
	elseif roll <= 55 then
		index = 2
	elseif roll <= 72 then
		index = 3
	elseif roll <= 84 then
		index = 4
	elseif roll <= 91 then
		index = 5
	elseif roll <= 96 then
		index = 6
	elseif roll <= 99 then
		index = 7
	else
		index = 8
	end
	return BrainrotData.BRAINROTS[index]
end

-- Mutations: 5% Golden (2x rate), 1% Rainbow (5x rate). Returns
-- "Normal", "Golden" or "Rainbow" plus the rate multiplier.
function BrainrotData.rollMutation()
	local roll = math.random(1, 100)
	if roll == 1 then
		return "Rainbow", 5
	elseif roll <= 6 then
		return "Golden", 2
	else
		return "Normal", 1
	end
end

function BrainrotData.mutationColor(mutation)
	if mutation == "Golden" then
		return Color3.fromRGB(255, 215, 0)
	elseif mutation == "Rainbow" then
		return Color3.fromRGB(255, 80, 200)
	else
		return Color3.fromRGB(255, 255, 255)
	end
end

function BrainrotData.formatMoney(amount)
	amount = math.floor(amount + 0.5)
	local text = tostring(amount)
	local out = ""
	while #text > 3 do
		out = "," .. string.sub(text, -3) .. out
		text = string.sub(text, 1, -4)
	end
	return "$" .. text .. out
end

return BrainrotData
