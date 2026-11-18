-- Game.client: Brainrot Base Rush HUD.
-- Shows money, $/s, brainrot count, the next spawn preview, the wave
-- countdown, a Rebirth button and a help panel. Everything sits clear of
-- the top-left corner, where Roblox puts its menu buttons. Also wires the
-- Slap tool: clicking it fires SlapHit to the server, which checks range.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local updateHud = ReplicatedStorage:WaitForChild("UpdateHUD")
local announceEvent = ReplicatedStorage:WaitForChild("Announce")
local slapEvent = ReplicatedStorage:WaitForChild("SlapHit")
local rebirthEvent = ReplicatedStorage:WaitForChild("RequestRebirth")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local function makeLabel(name, parent, position, size, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	label.BackgroundTransparency = 0.25
	label.BorderSizePixel = 0
	label.Text = ""
	label.TextColor3 = color
	label.TextSize = textSize
	label.Font = Enum.Font.SourceSansBold
	label.TextXAlignment = Enum.TextAlignment.Left
	label.Parent = parent
	return label
end

-- Top-right stats panel (clear of the top-left Roblox menu).
local stats = Instance.new("Frame")
stats.Name = "StatsPanel"
stats.AnchorPoint = Vector2.new(1, 0)
stats.Position = UDim2.new(1, -12, 0, 12)
stats.Size = UDim2.new(0, 300, 0, 190)
stats.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
stats.BackgroundTransparency = 0.2
stats.BorderSizePixel = 0
stats.Parent = gui

local title = makeLabel("Title", stats, UDim2.new(0, 10, 0, 6), UDim2.new(1, -20, 0, 28), 22, Color3.fromRGB(255, 215, 0))
title.Text = "BRAINROT BASE RUSH"
title.TextXAlignment = Enum.TextAlignment.Center

local moneyLabel = makeLabel("Money", stats, UDim2.new(0, 10, 0, 38), UDim2.new(1, -20, 0, 30), 26, Color3.fromRGB(120, 255, 120))
local rateLabel = makeLabel("Rate", stats, UDim2.new(0, 10, 0, 72), UDim2.new(1, -20, 0, 24), 20, Color3.fromRGB(255, 255, 255))
local countLabel = makeLabel("Count", stats, UDim2.new(0, 10, 0, 100), UDim2.new(1, -20, 0, 24), 20, Color3.fromRGB(255, 255, 255))
local nextLabel = makeLabel("NextSpawn", stats, UDim2.new(0, 10, 0, 128), UDim2.new(1, -20, 0, 24), 20, Color3.fromRGB(160, 200, 255))
local waveLabel = makeLabel("Wave", stats, UDim2.new(0, 10, 0, 156), UDim2.new(1, -20, 0, 24), 20, Color3.fromRGB(255, 180, 30))

-- Center announcement banner (below the top bar, above the action).
local banner = Instance.new("TextLabel")
banner.Name = "Banner"
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 70)
banner.Size = UDim2.new(0, 560, 0, 44)
banner.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
banner.BackgroundTransparency = 0.2
banner.BorderSizePixel = 0
banner.Text = ""
banner.TextColor3 = Color3.fromRGB(255, 255, 255)
banner.TextSize = 24
banner.Font = Enum.Font.SourceSansBold
banner.Visible = false
banner.Parent = gui

local bannerUntil = 0
local function showBanner(text, color)
	banner.Text = text
	banner.TextColor3 = color
	banner.Visible = true
	bannerUntil = os.clock() + 5
end

-- Bottom-right Rebirth button (hidden until $25,000 lifetime earned).
local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "RebirthButton"
rebirthButton.AnchorPoint = Vector2.new(1, 1)
rebirthButton.Position = UDim2.new(1, -12, 1, -12)
rebirthButton.Size = UDim2.new(0, 260, 0, 56)
rebirthButton.BackgroundColor3 = Color3.fromRGB(255, 180, 30)
rebirthButton.Text = "REBIRTH (+50% earnings)"
rebirthButton.TextColor3 = Color3.fromRGB(40, 20, 0)
rebirthButton.TextSize = 20
rebirthButton.Font = Enum.Font.SourceSansBold
rebirthButton.Visible = false
rebirthButton.Parent = gui

rebirthButton.MouseButton1Click:Connect(function()
	rebirthEvent:FireServer()
end)

-- Bottom-left help panel.
local help = Instance.new("Frame")
help.Name = "HelpPanel"
help.Position = UDim2.new(0, 12, 1, -108)
help.Size = UDim2.new(0, 360, 0, 96)
help.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
help.BackgroundTransparency = 0.25
help.BorderSizePixel = 0
help.Parent = gui

local helpText = makeLabel("HelpText", help, UDim2.new(0, 10, 0, 6), UDim2.new(1, -20, 1, -12), 16, Color3.fromRGB(230, 230, 230))
helpText.Text = "Touch a brainrot on the path to BUY it.\nIt earns $ every second on your base.\nTsunami wave? Run to the GREEN base!\nSlap the Noob Nabber before he steals!"
helpText.TextXAlignment = Enum.TextAlignment.Left
helpText.TextYAlignment = Enum.TextAlignment.Top
helpText.BackgroundTransparency = 1

updateHud.OnClientEvent:Connect(function(data)
	moneyLabel.Text = "Money: " .. BrainrotData.formatMoney(data.money)
	local multText = ""
	if data.multiplier > 1 then
		multText = "  (x" .. string.format("%.1f", data.multiplier) .. ")"
	end
	rateLabel.Text = "Income: " .. BrainrotData.formatMoney(data.rate) .. "/s" .. multText
	countLabel.Text = "Brainrots: " .. tostring(data.count) .. "/" .. tostring(data.maxSlots)
	local mutationText = ""
	if data.nextMutation ~= "Normal" then
		mutationText = " [" .. data.nextMutation .. "]"
	end
	nextLabel.Text = "Next: " .. data.nextName .. " (" .. data.nextRarity .. ")" .. mutationText
	if data.waveIn <= 10 then
		waveLabel.Text = "TSUNAMI IN " .. tostring(data.waveIn) .. "s - GET TO BASE!"
		waveLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
	else
		waveLabel.Text = "Tsunami in " .. tostring(data.waveIn) .. "s"
		waveLabel.TextColor3 = Color3.fromRGB(255, 180, 30)
	end
	if data.thiefActive then
		waveLabel.Text = waveLabel.Text .. "  |  THIEF!"
	end
	if data.rebirthReady then
		rebirthButton.Visible = true
		rebirthButton.Text = "REBIRTH! +" .. tostring(data.rebirths + 1) .. " (x" .. string.format("%.1f", data.multiplier + 0.5) .. " earnings)"
	else
		rebirthButton.Visible = false
	end
end)

announceEvent.OnClientEvent:Connect(function(text, color)
	showBanner(text, color)
end)

-- Hide the banner again a few seconds after it appears.
task.spawn(function()
	while true do
		task.wait(0.5)
		if banner.Visible and os.clock() > bannerUntil then
			banner.Visible = false
		end
	end
end)

-- Slap tool: the Tool lives in StarterPack; when the player clicks with it
-- equipped, tell the server (which checks the thief is actually in range).
local function hookSlapTool(tool)
	if tool.Name ~= "Slap" then
		return
	end
	tool.Activated:Connect(function()
		slapEvent:FireServer()
		showBanner("SLAP!", Color3.fromRGB(255, 220, 80))
	end)
end

local backpack = player:WaitForChild("Backpack")
for _, tool in ipairs(backpack:GetChildren()) do
	hookSlapTool(tool)
end
backpack.ChildAdded:Connect(hookSlapTool)

print("Brainrot Base Rush HUD ready.")
