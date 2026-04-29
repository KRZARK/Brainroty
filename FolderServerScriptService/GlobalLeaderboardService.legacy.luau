local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local TEMPLATE_MODEL_NAME = "Tablica"
local BOARD_CORE_NAME = "Time Played Leaderboard"
local MAX_ROWS = 10
local REFRESH_INTERVAL = 60
local BOARD_GAP = 6
local DISPLAY_PART_SIZE = Vector3.new(13.2, 13.2, 0.001)
local DISPLAY_OFFSET = CFrame.new(0, -6.35, 0)

local PlayerTotalsStore = DataStoreService:GetDataStore("LeaderboardPlayerTotals_V1")
local RebirthsStore = DataStoreService:GetOrderedDataStore("Leaderboard_Rebirths_V1")
local RobuxSpentStore = DataStoreService:GetOrderedDataStore("Leaderboard_RobuxSpent_V1")
local CoinsCollectedStore = DataStoreService:GetOrderedDataStore("Leaderboard_CoinsCollected_V1")

local LeaderboardConfigs = {
	{
		id = "robux",
		title = "TOP ROBUX",
		valueHeader = "ROBUX",
		modelName = "Tablica_Robux",
		store = RobuxSpentStore,
		getLiveValue = function(player)
			return player:GetAttribute("RobuxSpent") or 0
		end,
		formatValue = function(value)
			return value .. " " .. utf8.char(0xE002)
		end,
	},
	{
		id = "rebirths",
		title = "TOP REBIRTHS",
		valueHeader = "REBIRTHS",
		modelName = TEMPLATE_MODEL_NAME,
		store = RebirthsStore,
		getLiveValue = function(player)
			local leaderstats = player:FindFirstChild("leaderstats")
			local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths")
			return rebirths and rebirths.Value or 0
		end,
		formatValue = function(value)
			return value
		end,
		useTemplate = true,
	},
	{
		id = "coins",
		title = "TOP COINS",
		valueHeader = "COINS",
		modelName = "Tablica_Monety",
		store = CoinsCollectedStore,
		getLiveValue = function(player)
			return player:GetAttribute("TotalCoinsCollected") or 0
		end,
		formatValue = function(value)
			return value
		end,
	},
}

local boardModels = {}
local trackedPlayers = {}
local nameCache = {}
local refreshQueued = false

local function formatCompactNumber(value)
	value = math.floor(tonumber(value) or 0)
	local absValue = math.abs(value)

	if absValue >= 1000000000000 then
		return string.format("%.1fT", value / 1000000000000):gsub("%.0T", "T")
	elseif absValue >= 1000000000 then
		return string.format("%.1fB", value / 1000000000):gsub("%.0B", "B")
	elseif absValue >= 1000000 then
		return string.format("%.1fM", value / 1000000):gsub("%.0M", "M")
	elseif absValue >= 1000 then
		return string.format("%.1fK", value / 1000):gsub("%.0K", "K")
	end

	return tostring(value)
end

for _, config in ipairs(LeaderboardConfigs) do
	local formatter = config.formatValue
	config.formatValue = function(value)
		return formatter(formatCompactNumber(value))
	end
end

local function readOrderedValue(store, userId)
	local success, result = pcall(function()
		return store:GetAsync(tostring(userId))
	end)

	if success and type(result) == "number" then
		return math.floor(result)
	end

	return 0
end

local function updateOrderedValue(store, userId, value)
	value = math.max(0, math.floor(tonumber(value) or 0))

	task.spawn(function()
		pcall(function()
			store:UpdateAsync(tostring(userId), function(oldValue)
				oldValue = math.max(0, math.floor(tonumber(oldValue) or 0))
				if value > oldValue then
					return value
				end
				return oldValue
			end)
		end)
	end)
end

local function getPlayerName(userId)
	if nameCache[userId] then
		return nameCache[userId]
	end

	local success, result = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)

	local name = success and result or ("User " .. tostring(userId))
	nameCache[userId] = name
	return name
end

local function getBoardCore(boardModel)
	if not boardModel then
		return nil
	end

	return boardModel:FindFirstChild(BOARD_CORE_NAME)
end

local function getBoardLabel(boardModel, partName, labelName)
	local core = getBoardCore(boardModel)
	local part = core and core:FindFirstChild(partName)
	local surfaceGui = part and part:FindFirstChildOfClass("SurfaceGui")
	local label = surfaceGui and surfaceGui:FindFirstChild(labelName)

	if label and label:IsA("TextLabel") then
		return label
	end

	return nil
end

local function styleRowLabel(label, text, color)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.45
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextScaled = false
	label.TextSize = 28
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = 34
	constraint.Parent = label
end

local function ensureBoardDisplay(boardModel)
	local core = getBoardCore(boardModel)
	local namePart = core and core:FindFirstChild("name")
	if not (namePart and namePart:IsA("BasePart")) then
		return nil
	end

	local displayPart = core:FindFirstChild("LeaderboardDisplay")
	if not displayPart then
		displayPart = Instance.new("Part")
		displayPart.Name = "LeaderboardDisplay"
		displayPart.Anchored = true
		displayPart.CanCollide = false
		displayPart.CanQuery = false
		displayPart.CanTouch = false
		displayPart.Transparency = 1
		displayPart.CastShadow = false
		displayPart.Size = DISPLAY_PART_SIZE
		displayPart.CFrame = namePart.CFrame * DISPLAY_OFFSET
		displayPart.Parent = core

		local surfaceGui = Instance.new("SurfaceGui")
		surfaceGui.Name = "RowsGui"
		surfaceGui.Face = Enum.NormalId.Front
		surfaceGui.LightInfluence = 0
		surfaceGui.CanvasSize = Vector2.new(1120, 1080)
		surfaceGui.Parent = displayPart

		local holder = Instance.new("Frame")
		holder.Name = "RowsHolder"
		holder.BackgroundTransparency = 1
		holder.Size = UDim2.new(1, -40, 1, -20)
		holder.Position = UDim2.new(0, 20, 0, 10)
		holder.Parent = surfaceGui

		local listLayout = Instance.new("UIListLayout")
		listLayout.Padding = UDim.new(0, 6)
		listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Parent = holder
	end

	return displayPart:FindFirstChild("RowsGui")
end

local function buildRow(holder, rank, playerName, valueText)
	local row = Instance.new("Frame")
	row.Name = "Row_" .. tostring(rank)
	row.BackgroundColor3 = Color3.fromRGB(42, 52, 74)
	row.BackgroundTransparency = 0.2
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, 95)
	row.LayoutOrder = rank
	row.Parent = holder

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = row

	local rankLabel = Instance.new("TextLabel")
	rankLabel.Name = "Rank"
	rankLabel.Size = UDim2.new(0.16, 0, 1, 0)
	rankLabel.Parent = row
	styleRowLabel(rankLabel, "#" .. tostring(rank), Color3.fromRGB(78, 156, 255))

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "PlayerName"
	nameLabel.Size = UDim2.new(0.48, 0, 1, 0)
	nameLabel.Position = UDim2.new(0.16, 0, 0, 0)
	nameLabel.Parent = row
	styleRowLabel(nameLabel, playerName, Color3.fromRGB(255, 188, 59))

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.Size = UDim2.new(0.36, 0, 1, 0)
	valueLabel.Position = UDim2.new(0.64, 0, 0, 0)
	valueLabel.Parent = row
	styleRowLabel(valueLabel, valueText, Color3.fromRGB(255, 255, 255))
end

local function applyBoardText(boardModel, config)
	local titleLabel = getBoardLabel(boardModel, "TItle", "Title")
	local rankLabel = getBoardLabel(boardModel, "Rank", "Name")
	local nameLabel = getBoardLabel(boardModel, "name", "Name")
	local valueLabel = getBoardLabel(boardModel, "Time Played", "Taps")

	if titleLabel then
		titleLabel.Text = config.title
	end

	if rankLabel then
		rankLabel.Text = "#"
	end

	if nameLabel then
		nameLabel.Text = "GRACZ"
	end

	if valueLabel then
		valueLabel.Text = config.valueHeader
	end
end

local function getFallbackEntries(config)
	local entries = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local value = config.getLiveValue(player)
		if value > 0 then
			table.insert(entries, {
				userId = player.UserId,
				name = player.Name,
				value = value,
			})
		end
	end

	table.sort(entries, function(a, b)
		if a.value == b.value then
			return a.userId < b.userId
		end
		return a.value > b.value
	end)

	while #entries > MAX_ROWS do
		table.remove(entries)
	end

	return entries
end

local function getTopEntries(config)
	local success, pages = pcall(function()
		return config.store:GetSortedAsync(false, MAX_ROWS)
	end)

	if not success then
		return getFallbackEntries(config)
	end

	local entries = {}
	for _, item in ipairs(pages:GetCurrentPage()) do
		local userId = tonumber(item.key)
		if userId then
			table.insert(entries, {
				userId = userId,
				name = getPlayerName(userId),
				value = math.floor(tonumber(item.value) or 0),
			})
		end
	end

	if #entries == 0 then
		return getFallbackEntries(config)
	end

	return entries
end

local function renderBoard(boardModel, config)
	local rowsGui = ensureBoardDisplay(boardModel)
	if not rowsGui then
		return
	end

	local holder = rowsGui:FindFirstChild("RowsHolder")
	if not holder then
		return
	end

	for _, child in ipairs(holder:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local entries = getTopEntries(config)
	for rank = 1, MAX_ROWS do
		local entry = entries[rank]
		buildRow(
			holder,
			rank,
			entry and entry.name or "---",
			entry and config.formatValue(entry.value) or "---"
		)
	end
end

local function refreshAllBoards()
	for _, config in ipairs(LeaderboardConfigs) do
		local boardModel = boardModels[config.id]
		if boardModel then
			applyBoardText(boardModel, config)
			renderBoard(boardModel, config)
		end
	end
end

local function queueRefresh(delaySeconds)
	if refreshQueued then
		return
	end

	refreshQueued = true
	task.delay(delaySeconds or 2, function()
		refreshQueued = false
		refreshAllBoards()
	end)
end

local function savePlayerTotals(player)
	local payload = {
		RobuxSpent = math.max(0, math.floor(player:GetAttribute("RobuxSpent") or 0)),
		TotalCoinsCollected = math.max(0, math.floor(player:GetAttribute("TotalCoinsCollected") or 0)),
	}

	pcall(function()
		PlayerTotalsStore:SetAsync(tostring(player.UserId), payload)
	end)
end

local function setupBoards()
	local templateModel = Workspace:FindFirstChild(TEMPLATE_MODEL_NAME)
	if not (templateModel and templateModel:IsA("Model")) then
		warn("[GlobalLeaderboardService] Missing Workspace." .. TEMPLATE_MODEL_NAME)
		return false
	end

	local templateParent = templateModel.Parent
	local templatePivot = templateModel:GetPivot()
	local _, templateSize = templateModel:GetBoundingBox()
	local spacing = templateSize.X + BOARD_GAP
	local offsets = { -spacing, 0, spacing }

	for _, config in ipairs(LeaderboardConfigs) do
		if not config.useTemplate then
			local existing = templateParent:FindFirstChild(config.modelName)
			if existing then
				existing:Destroy()
			end
		end
	end

	for index, config in ipairs(LeaderboardConfigs) do
		local boardModel
		if config.useTemplate then
			boardModel = templateModel
		else
			boardModel = templateModel:Clone()
			boardModel.Name = config.modelName
			boardModel.Parent = templateParent
		end

		boardModel:PivotTo(templatePivot * CFrame.new(offsets[index], 0, 0))
		boardModels[config.id] = boardModel
		applyBoardText(boardModel, config)
	end

	return true
end

local function setupPlayer(player)
	if trackedPlayers[player] then
		return
	end

	task.spawn(function()
		local leaderstats = player:WaitForChild("leaderstats", 30)
		if not leaderstats then
			return
		end

		local coins = leaderstats:WaitForChild("Coins", 10)
		local rebirths = leaderstats:WaitForChild("Rebirths", 10)
		if not (coins and rebirths) then
			return
		end

		local savedTotals = {}
		pcall(function()
			savedTotals = PlayerTotalsStore:GetAsync(tostring(player.UserId)) or {}
		end)

		local robuxSpent = math.max(
			math.floor(tonumber(savedTotals.RobuxSpent) or 0),
			readOrderedValue(RobuxSpentStore, player.UserId),
			math.floor(tonumber(player:GetAttribute("RobuxSpent")) or 0)
		)
		local totalCoinsCollected = math.max(
			math.floor(tonumber(savedTotals.TotalCoinsCollected) or 0),
			readOrderedValue(CoinsCollectedStore, player.UserId),
			math.floor(tonumber(player:GetAttribute("TotalCoinsCollected")) or 0),
			coins.Value
		)
		local orderedRebirths = readOrderedValue(RebirthsStore, player.UserId)

		if orderedRebirths > rebirths.Value then
			rebirths.Value = orderedRebirths
		end

		player:SetAttribute("RobuxSpent", robuxSpent)
		player:SetAttribute("TotalCoinsCollected", totalCoinsCollected)

		trackedPlayers[player] = {
			lastCoinsValue = coins.Value,
		}

		coins:GetPropertyChangedSignal("Value"):Connect(function()
			local playerState = trackedPlayers[player]
			if not playerState then
				return
			end

			local newValue = coins.Value
			if newValue > playerState.lastCoinsValue then
				local gained = newValue - playerState.lastCoinsValue
				player:SetAttribute("TotalCoinsCollected", (player:GetAttribute("TotalCoinsCollected") or 0) + gained)
			end
			playerState.lastCoinsValue = newValue
		end)

		rebirths:GetPropertyChangedSignal("Value"):Connect(function()
			updateOrderedValue(RebirthsStore, player.UserId, rebirths.Value)
			queueRefresh(1)
		end)

		player:GetAttributeChangedSignal("RobuxSpent"):Connect(function()
			updateOrderedValue(RobuxSpentStore, player.UserId, player:GetAttribute("RobuxSpent") or 0)
			queueRefresh(1)
		end)

		player:GetAttributeChangedSignal("TotalCoinsCollected"):Connect(function()
			updateOrderedValue(CoinsCollectedStore, player.UserId, player:GetAttribute("TotalCoinsCollected") or 0)
			queueRefresh(1)
		end)

		updateOrderedValue(RebirthsStore, player.UserId, rebirths.Value)
		updateOrderedValue(RobuxSpentStore, player.UserId, robuxSpent)
		updateOrderedValue(CoinsCollectedStore, player.UserId, totalCoinsCollected)
		queueRefresh(1)
	end)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
	savePlayerTotals(player)
	trackedPlayers[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

if setupBoards() then
	refreshAllBoards()
end

task.spawn(function()
	while true do
		task.wait(REFRESH_INTERVAL)
		refreshAllBoards()
	end
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayerTotals(player)
	end
end)

print("GlobalLeaderboardService loaded successfully.")
