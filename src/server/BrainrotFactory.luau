-- BrainrotFactory: builds a brainrot character as a simple Part-assembled
-- Model (body + head + eyes + one distinctive accessory) plus a
-- BillboardGui name / rarity label. No Humanoid: the server moves the model
-- along the path with PivotTo.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))

local BrainrotFactory = {}

local function makePart(name, shape, size, color, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = true
	part.Parent = parent
	return part
end

local function buildAccessory(def, model, body, head)
	local kind = def.accessory
	if kind == "log" then
		-- Tung Tung: a wooden log held across the body.
		local log = makePart("Accessory", Enum.PartType.Cylinder, Vector3.new(1, 4.5, 1), Color3.fromRGB(101, 67, 33), model)
		log.CFrame = body.CFrame * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.rad(90))
	elseif kind == "banana" then
		-- Chimpanzini: a big yellow banana on the head.
		local banana = makePart("Accessory", Enum.PartType.Block, Vector3.new(0.7, 2.2, 0.7), Color3.fromRGB(255, 220, 40), model)
		banana.CFrame = head.CFrame * CFrame.new(0.8, 1.2, 0) * CFrame.Angles(0, 0, math.rad(-30))
	elseif kind == "fin" then
		-- Tralalero: a shark fin on top of the head.
		local fin = makePart("Accessory", Enum.PartType.Wedge, Vector3.new(0.5, 1.6, 1.6), Color3.fromRGB(40, 90, 160), model)
		fin.CFrame = head.CFrame * CFrame.new(0, 1.3, 0)
	elseif kind == "hat" then
		-- Ballerina: a pink tutu hat / bun on the head.
		local hat = makePart("Accessory", Enum.PartType.Cylinder, Vector3.new(0.4, 2.4, 2.4), Color3.fromRGB(255, 150, 200), model)
		hat.CFrame = head.CFrame * CFrame.new(0, 1.1, 0)
	elseif kind == "shell" then
		-- Bombardiro: a bomber shell strapped on the back.
		local shell = makePart("Accessory", Enum.PartType.Ball, Vector3.new(1.6, 1.6, 1.2), Color3.fromRGB(80, 80, 80), model)
		shell.CFrame = body.CFrame * CFrame.new(0, 0.4, -1.4)
	elseif kind == "cactus" then
		-- Lirili: a green cactus sprouting from the head.
		local cactus = makePart("Accessory", Enum.PartType.Cylinder, Vector3.new(2, 0.9, 0.9), Color3.fromRGB(50, 180, 70), model)
		cactus.CFrame = head.CFrame * CFrame.new(0, 1.4, 0)
	elseif kind == "drum" then
		-- Patapim: a drum on the belly.
		local drum = makePart("Accessory", Enum.PartType.Cylinder, Vector3.new(1, 1.8, 1.8), Color3.fromRGB(220, 60, 60), model)
		drum.CFrame = body.CFrame * CFrame.new(0, -0.2, 1.4) * CFrame.Angles(math.rad(90), 0, 0)
	elseif kind == "crown" then
		-- Giraffa: a golden crown on the head.
		local crown = makePart("Accessory", Enum.PartType.Block, Vector3.new(1.8, 0.7, 1.8), Color3.fromRGB(255, 215, 0), model)
		crown.CFrame = head.CFrame * CFrame.new(0, 1.2, 0)
	end
end

-- Builds the model at the given position. mutation tints the label and the
-- effective rate; the caller stores the real numbers as attributes.
function BrainrotFactory.build(def, mutation, position)
	local model = Instance.new("Model")
	model.Name = def.name

	local body = makePart("Body", Enum.PartType.Block, Vector3.new(3, 3, 2), def.bodyColor, model)
	body.Position = position + Vector3.new(0, 1.5, 0)
	body.CanCollide = true

	local head = makePart("Head", Enum.PartType.Ball, Vector3.new(2.6, 2.6, 2.6), def.headColor, model)
	head.Position = position + Vector3.new(0, 4.2, 0)
	head.CanCollide = true

	local eyeLeft = makePart("EyeLeft", Enum.PartType.Ball, Vector3.new(0.5, 0.7, 0.5), Color3.fromRGB(20, 20, 20), model)
	eyeLeft.Position = position + Vector3.new(-0.6, 4.4, 1.2)
	local eyeRight = makePart("EyeRight", Enum.PartType.Ball, Vector3.new(0.5, 0.7, 0.5), Color3.fromRGB(20, 20, 20), model)
	eyeRight.Position = position + Vector3.new(0.6, 4.4, 1.2)

	buildAccessory(def, model, body, head)

	-- Feet so the character reads as walking along the path.
	local footLeft = makePart("FootLeft", Enum.PartType.Block, Vector3.new(1, 0.6, 1.4), Color3.fromRGB(40, 40, 40), model)
	footLeft.Position = position + Vector3.new(-0.8, 0.3, 0)
	local footRight = makePart("FootRight", Enum.PartType.Block, Vector3.new(1, 0.6, 1.4), Color3.fromRGB(40, 40, 40), model)
	footRight.Position = position + Vector3.new(0.8, 0.3, 0)

	-- Name / rarity label floating above the head.
	local labelGui = Instance.new("BillboardGui")
	labelGui.Name = "BrainrotLabel"
	labelGui.Size = UDim2.new(0, 160, 0, 50)
	labelGui.StudsOffset = Vector3.new(0, 3.5, 0)
	labelGui.AlwaysOnTop = true
	labelGui.Adornee = head
	labelGui.Parent = model

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = def.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Parent = labelGui

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Position = UDim2.new(0, 0, 0.55, 0)
	rarityLabel.Size = UDim2.new(1, 0, 0.45, 0)
	rarityLabel.BackgroundTransparency = 1
	local labelText = def.rarity .. "  $" .. tostring(def.rate) .. "/s  " .. BrainrotData.formatMoney(def.cost)
	if mutation ~= "Normal" then
		labelText = mutation .. " " .. labelText
	end
	rarityLabel.Text = labelText
	rarityLabel.TextColor3 = BrainrotData.RARITY_COLORS[def.rarity]
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.SourceSansBold
	rarityLabel.TextStrokeTransparency = 0
	rarityLabel.Parent = labelGui

	model.PrimaryPart = body
	model:SetAttribute("BrainrotName", def.name)
	model:SetAttribute("Rarity", def.rarity)
	model:SetAttribute("Mutation", mutation)
	model:SetAttribute("Cost", def.cost)

	return model
end

-- The Noob Nabber thief: a plain yellow noob with a grabby look.
function BrainrotFactory.buildThief(position)
	local model = Instance.new("Model")
	model.Name = "NoobNabber"

	local body = makePart("Body", Enum.PartType.Block, Vector3.new(3, 3, 2), Color3.fromRGB(255, 220, 0), model)
	body.Position = position + Vector3.new(0, 1.5, 0)
	body.CanCollide = true

	local head = makePart("Head", Enum.PartType.Ball, Vector3.new(2.4, 2.4, 2.4), Color3.fromRGB(255, 220, 0), model)
	head.Position = position + Vector3.new(0, 4.1, 0)

	local eyeLeft = makePart("EyeLeft", Enum.PartType.Ball, Vector3.new(0.5, 0.7, 0.5), Color3.fromRGB(20, 20, 20), model)
	eyeLeft.Position = position + Vector3.new(-0.55, 4.3, 1.1)
	local eyeRight = makePart("EyeRight", Enum.PartType.Ball, Vector3.new(0.5, 0.7, 0.5), Color3.fromRGB(20, 20, 20), model)
	eyeRight.Position = position + Vector3.new(0.55, 4.3, 1.1)

	-- A red bandit mask stripe across the face.
	local mask = makePart("Mask", Enum.PartType.Block, Vector3.new(2.2, 0.6, 0.4), Color3.fromRGB(200, 30, 30), model)
	mask.Position = position + Vector3.new(0, 4.3, 1.1)

	local labelGui = Instance.new("BillboardGui")
	labelGui.Name = "ThiefLabel"
	labelGui.Size = UDim2.new(0, 140, 0, 30)
	labelGui.StudsOffset = Vector3.new(0, 3.2, 0)
	labelGui.AlwaysOnTop = true
	labelGui.Adornee = head
	labelGui.Parent = model

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.Text = "Noob Nabber! SLAP HIM!"
	text.TextColor3 = Color3.fromRGB(255, 60, 60)
	text.TextScaled = true
	text.Font = Enum.Font.SourceSansBold
	text.TextStrokeTransparency = 0
	text.Parent = labelGui

	model.PrimaryPart = body
	return model
end

return BrainrotFactory
