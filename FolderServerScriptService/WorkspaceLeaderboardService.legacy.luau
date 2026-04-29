local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local BOARD_CORE_NAME = "Time Played Leaderboard"
local DISPLAY_PART_NAME = "LeaderboardDisplay"
local MAX_ENTRIES = 50
local ENTRIES_PER_PAGE = 10
local PAGE_COUNT = math.ceil(MAX_ENTRIES / ENTRIES_PER_PAGE)
local ORDERED_REFRESH_INTERVAL = 120
local FLUSH_INTERVAL = 120
local INITIAL_ORDERED_REFRESH_DELAY = 8
local DISPLAY_PART_SIZE = Vector3.new(13.2, 13.2, 0.001)
local DISPLAY_OFFSET = CFrame.new(0, -6.35, 0)
local ROW_HEIGHT = 96
local ROW_SPACING = 4
local ROW_TEXT_SIZE = 56
local SCROLLER_LEFT_INSET = 10
local SCROLLER_RIGHT_INSET = 10
local SCROLLER_TOP_INSET = 74
local SCROLLER_BOTTOM_INSET = 122
local PAGE_BAR_HEIGHT = 74
local PAGE_BAR_BOTTOM_INSET = 22
local PAGE_BUTTON_WIDTH = 86
local PAGE_BUTTON_GAP = 10
local NAV_BUTTON_WIDTH = 154
local SURFACE_CANVAS_SIZE = Vector2.new(1200, 1200)

local PlayerTotalsStore = DataStoreService:GetDataStore("LeaderboardPlayerTotals_V1")
local RebirthsStore = DataStoreService:GetOrderedDataStore("Leaderboard_Rebirths_V1")
local RobuxSpentStore = DataStoreService:GetOrderedDataStore("Leaderboard_RobuxSpent_V1")
local CoinsCollectedStore = DataStoreService:GetOrderedDataStore("Leaderboard_CoinsCollected_V1")

local LeaderboardConfigs = {
	{
		id = "rebirths",
		title = "TOP REBIRTHS",
		valueHeader = "REBIRTHS",
		modelName = "Tablica",
		store = RebirthsStore,
		getLiveValue = function(player)
			local leaderstats = player:FindFirstChild("leaderstats")
			local rebirths = leaderstats and leaderstats:FindFirstChild("Rebirths")
			return rebirths and rebirths.Value or 0
		end,
		formatValue = function(value)
			return value
		end,
	},
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
local dirtyOrderedValues = {}
local writtenOrderedValues = {}
local orderedEntriesCache = {}
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

local function markDirty(userId, key, value)
	local bucket = dirtyOrderedValues[userId]
	if not bucket then
		bucket = {}
		dirtyOrderedValues[userId] = bucket
	end

	bucket[key] = math.max(0, math.floor(tonumber(value) or 0))
end

local function updateOrderedValue(store, userId, key, value)
	value = math.max(0, math.floor(tonumber(value) or 0))

	local userWrittenValues = writtenOrderedValues[userId]
	if not userWrittenValues then
		userWrittenValues = {}
		writtenOrderedValues[userId] = userWrittenValues
	end

	if value <= (userWrittenValues[key] or 0) then
		return
	end

	local success = pcall(function()
		store:UpdateAsync(tostring(userId), function(oldValue)
			oldValue = math.max(0, math.floor(tonumber(oldValue) or 0))
			if value > oldValue then
				return value
			end
			return oldValue
		end)
	end)

	if success then
		userWrittenValues[key] = value
	end
end

local function flushDirtyUser(userId)
	local bucket = dirtyOrderedValues[userId]
	if not bucket then
		return
	end

	dirtyOrderedValues[userId] = nil

	if bucket.rebirths ~= nil then
		updateOrderedValue(RebirthsStore, userId, "rebirths", bucket.rebirths)
	end
	if bucket.robux ~= nil then
		updateOrderedValue(RobuxSpentStore, userId, "robux", bucket.robux)
	end
	if bucket.coins ~= nil then
		updateOrderedValue(CoinsCollectedStore, userId, "coins", bucket.coins)
	end
end

local function flushAllDirty()
	for userId in pairs(dirtyOrderedValues) do
		flushDirtyUser(userId)
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
	return boardModel and boardModel:FindFirstChild(BOARD_CORE_NAME)
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

local function ensureTextConstraint(label, constraintName, minSize, maxSize)
	local constraint = label:FindFirstChild(constraintName)
	if not constraint then
		constraint = Instance.new("UITextSizeConstraint")
		constraint.Name = constraintName
		constraint.Parent = label
	end

	constraint.MinTextSize = minSize
	constraint.MaxTextSize = maxSize
end

local function styleHeaderLabel(label, minSize, maxSize)
	label.TextScaled = true
	label.TextWrapped = true
	label.TextStrokeTransparency = 0
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	ensureTextConstraint(label, "LeaderboardHeaderConstraint", minSize, maxSize)
end

local function styleRowLabel(label, text, color)
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = text
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.2
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextScaled = false
	label.TextSize = ROW_TEXT_SIZE
	label.TextWrapped = false
	label.TextTruncate = Enum.TextTruncate.None
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
end

local function styleNameLabel(label, text)
	styleRowLabel(label, text, Color3.fromRGB(255, 200, 74))
	label.TextScaled = true
	label.TextWrapped = false
	label.TextTruncate = Enum.TextTruncate.None
	ensureTextConstraint(label, "LeaderboardNameConstraint", 18, 46)
end

local function stylePageButton(button, text)
	button.Active = true
	button.Selectable = true
	button.AutoButtonColor = false
	button.Text = text
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.TextWrapped = false
	button.TextColor3 = Color3.fromRGB(234, 244, 255)
	button.BackgroundColor3 = Color3.fromRGB(43, 56, 84)
	button.BackgroundTransparency = 0.04
	button.BorderSizePixel = 0
	button.ZIndex = 4
	ensureTextConstraint(button, "PageButtonConstraint", 18, 36)

	local corner = button:FindFirstChild("UICorner") or Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = button

	local stroke = button:FindFirstChild("PageButtonStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Name = "PageButtonStroke"
		stroke.Parent = button
	end
	stroke.Color = Color3.fromRGB(90, 118, 168)
	stroke.Thickness = 2
	stroke.Transparency = 0.15
end

local function ensureBoardDisplay(boardModel)
	local core = getBoardCore(boardModel)
	local namePart = core and core:FindFirstChild("name")
	if not (namePart and namePart:IsA("BasePart")) then
		return nil
	end

	local displayPart = core:FindFirstChild(DISPLAY_PART_NAME)
	if not displayPart then
		displayPart = Instance.new("Part")
		displayPart.Name = DISPLAY_PART_NAME
		displayPart.Parent = core
	end

	displayPart.Anchored = true
	displayPart.CanCollide = false
	displayPart.CanQuery = true
	displayPart.CanTouch = false
	displayPart.Transparency = 1
	displayPart.CastShadow = false
	displayPart.Size = DISPLAY_PART_SIZE
	displayPart.CFrame = namePart.CFrame * DISPLAY_OFFSET

	local surfaceGui = displayPart:FindFirstChild("RowsGui")
	if not surfaceGui then
		surfaceGui = Instance.new("SurfaceGui")
		surfaceGui.Name = "RowsGui"
		surfaceGui.Parent = displayPart
	end

	surfaceGui.Active = true
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.LightInfluence = 0
	surfaceGui.MaxDistance = 200
	surfaceGui.CanvasSize = SURFACE_CANVAS_SIZE

	local scroller = surfaceGui:FindFirstChild("RowsScroller")
	if not scroller then
		scroller = Instance.new("ScrollingFrame")
		scroller.Name = "RowsScroller"
		scroller.Parent = surfaceGui
	end

	local contentHeight = MAX_ENTRIES * (ROW_HEIGHT + ROW_SPACING) + ROW_SPACING
	scroller.Active = false
	scroller.Selectable = false
	scroller.ScrollingEnabled = false
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.Position = UDim2.new(0, SCROLLER_LEFT_INSET, 0, SCROLLER_TOP_INSET)
	scroller.Size = UDim2.new(1, -(SCROLLER_LEFT_INSET + SCROLLER_RIGHT_INSET), 1, -(SCROLLER_TOP_INSET + SCROLLER_BOTTOM_INSET))
	scroller.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
	scroller.CanvasPosition = Vector2.zero
	scroller.ScrollBarThickness = 0
	scroller.ScrollingDirection = Enum.ScrollingDirection.Y

	local holder = scroller:FindFirstChild("RowsHolder")
	if not holder then
		holder = Instance.new("Frame")
		holder.Name = "RowsHolder"
		holder.Parent = scroller
	end

	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Position = UDim2.new(0, 0, 0, 0)
	holder.Size = UDim2.new(1, 0, 0, contentHeight)

	local pageBar = surfaceGui:FindFirstChild("PageBar")
	if not pageBar then
		pageBar = Instance.new("Frame")
		pageBar.Name = "PageBar"
		pageBar.Parent = surfaceGui
	end

	pageBar.Active = true
	pageBar.BackgroundColor3 = Color3.fromRGB(22, 29, 45)
	pageBar.BackgroundTransparency = 0.04
	pageBar.BorderSizePixel = 0
	pageBar.Position = UDim2.new(0, 14, 1, -(PAGE_BAR_HEIGHT + PAGE_BAR_BOTTOM_INSET))
	pageBar.Size = UDim2.new(1, -28, 0, PAGE_BAR_HEIGHT)
	pageBar.ZIndex = 3

	local pageBarCorner = pageBar:FindFirstChild("UICorner") or Instance.new("UICorner")
	pageBarCorner.CornerRadius = UDim.new(0, 14)
	pageBarCorner.Parent = pageBar

	local pageBarStroke = pageBar:FindFirstChild("PageBarStroke")
	if not pageBarStroke then
		pageBarStroke = Instance.new("UIStroke")
		pageBarStroke.Name = "PageBarStroke"
		pageBarStroke.Parent = pageBar
	end
	pageBarStroke.Color = Color3.fromRGB(89, 114, 160)
	pageBarStroke.Thickness = 2
	pageBarStroke.Transparency = 0.15

	local prevButton = pageBar:FindFirstChild("PrevButton")
	if not prevButton then
		prevButton = Instance.new("TextButton")
		prevButton.Name = "PrevButton"
		prevButton.Parent = pageBar
	end
	prevButton.Position = UDim2.new(0, 10, 0, 8)
	prevButton.Size = UDim2.new(0, NAV_BUTTON_WIDTH, 1, -16)
	stylePageButton(prevButton, "WSTECZ")

	local nextButton = pageBar:FindFirstChild("NextButton")
	if not nextButton then
		nextButton = Instance.new("TextButton")
		nextButton.Name = "NextButton"
		nextButton.Parent = pageBar
	end
	nextButton.Position = UDim2.new(1, -(NAV_BUTTON_WIDTH + 10), 0, 8)
	nextButton.Size = UDim2.new(0, NAV_BUTTON_WIDTH, 1, -16)
	stylePageButton(nextButton, "DALEJ")

	local buttonsFrame = pageBar:FindFirstChild("PageButtonsFrame")
	if not buttonsFrame then
		buttonsFrame = Instance.new("Frame")
		buttonsFrame.Name = "PageButtonsFrame"
		buttonsFrame.Parent = pageBar
	end
	buttonsFrame.BackgroundTransparency = 1
	buttonsFrame.BorderSizePixel = 0
	buttonsFrame.Position = UDim2.new(0, NAV_BUTTON_WIDTH + 26, 0, 8)
	buttonsFrame.Size = UDim2.new(1, -((NAV_BUTTON_WIDTH * 2) + 52), 1, -16)

	local layout = buttonsFrame:FindFirstChild("UIListLayout")
	if not layout then
		layout = Instance.new("UIListLayout")
		layout.Parent = buttonsFrame
	end
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, PAGE_BUTTON_GAP)
	layout.SortOrder = Enum.SortOrder.LayoutOrder

	for pageIndex = 1, PAGE_COUNT do
		local pageButton = buttonsFrame:FindFirstChild("PageButton_" .. pageIndex)
		if not pageButton then
			pageButton = Instance.new("TextButton")
			pageButton.Name = "PageButton_" .. pageIndex
			pageButton.Parent = buttonsFrame
		end
		pageButton.LayoutOrder = pageIndex
		pageButton.Size = UDim2.new(0, PAGE_BUTTON_WIDTH, 1, 0)
		stylePageButton(pageButton, tostring(pageIndex))
	end

	for _, child in ipairs(buttonsFrame:GetChildren()) do
		if child:IsA("TextButton") then
			local pageIndex = tonumber(child.Name:match("PageButton_(%d+)"))
			if not pageIndex or pageIndex > PAGE_COUNT then
				child:Destroy()
			end
		end
	end

	return displayPart, scroller, holder
end

local function getColumnLayout()
	return {
		rank = {left = 0.02, width = 0.12},
		name = {left = 0.16, width = 0.60},
		value = {left = 0.78, width = 0.20},
	}
end

local function createRowLabel(row, name, left, width, text, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = UDim2.new(left, 0, 0, 0)
	label.Size = UDim2.new(width, 0, 1, 0)
	label.Parent = row
	styleRowLabel(label, text, color)
	return label
end

local function getRankColor(rank)
	if rank == 1 then
		return Color3.fromRGB(255, 215, 80)
	elseif rank == 2 then
		return Color3.fromRGB(205, 226, 255)
	elseif rank == 3 then
		return Color3.fromRGB(255, 176, 120)
	end

	return Color3.fromRGB(108, 173, 255)
end

local function buildRow(holder, columns, rank, playerName, valueText)
	local row = Instance.new("Frame")
	row.Name = "Row_" .. tostring(rank)
	row.Position = UDim2.new(0, 0, 0, (rank - 1) * (ROW_HEIGHT + ROW_SPACING))
	row.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
	row.BackgroundColor3 = (rank % 2 == 0) and Color3.fromRGB(39, 49, 71) or Color3.fromRGB(49, 61, 88)
	row.BackgroundTransparency = 0.08
	row.BorderSizePixel = 0
	row.Parent = holder

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = row

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(89, 114, 160)
	stroke.Thickness = 2
	stroke.Transparency = 0.2
	stroke.Parent = row

	createRowLabel(row, "Rank", columns.rank.left, columns.rank.width, tostring(rank), getRankColor(rank))
	local nameLabel = createRowLabel(row, "PlayerName", columns.name.left, columns.name.width, playerName, Color3.fromRGB(255, 200, 74))
	styleNameLabel(nameLabel, playerName)
	createRowLabel(row, "Value", columns.value.left, columns.value.width, valueText, Color3.fromRGB(255, 255, 255))
end

local function applyBoardText(boardModel, config)
	local titleLabel = getBoardLabel(boardModel, "TItle", "Title")
	local rankLabel = getBoardLabel(boardModel, "Rank", "Name")
	local nameLabel = getBoardLabel(boardModel, "name", "Name")
	local valueLabel = getBoardLabel(boardModel, "Time Played", "Taps")

	if titleLabel then
		titleLabel.Text = config.title
		styleHeaderLabel(titleLabel, 34, 92)
	end

	if rankLabel then
		rankLabel.Text = "#"
		styleHeaderLabel(rankLabel, 22, 60)
	end

	if nameLabel then
		nameLabel.Text = "GRACZ"
		styleHeaderLabel(nameLabel, 22, 60)
		nameLabel.TextColor3 = Color3.fromRGB(255, 199, 67)
	end

	if valueLabel then
		valueLabel.Text = config.valueHeader
		styleHeaderLabel(valueLabel, 22, 60)
	end
end

local function sortEntries(entries)
	table.sort(entries, function(a, b)
		if a.value == b.value then
			return a.userId < b.userId
		end
		return a.value > b.value
	end)
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

	sortEntries(entries)
	while #entries > MAX_ENTRIES do
		table.remove(entries)
	end

	return entries
end

local function fetchOrderedEntries(config)
	local success, pages = pcall(function()
		return config.store:GetSortedAsync(false, MAX_ENTRIES)
	end)

	if not success then
		return nil
	end

	local orderedEntries = {}
	for _, item in ipairs(pages:GetCurrentPage()) do
		local userId = tonumber(item.key)
		if userId then
			table.insert(orderedEntries, {
				userId = userId,
				name = getPlayerName(userId),
				value = math.floor(tonumber(item.value) or 0),
			})
		end
	end

	return orderedEntries
end

local function mergeOnlineEntries(config, orderedEntries)
	local mergedByUserId = {}
	for _, entry in ipairs(orderedEntries) do
		mergedByUserId[entry.userId] = entry
	end

	for _, player in ipairs(Players:GetPlayers()) do
		local value = math.max(0, math.floor(tonumber(config.getLiveValue(player)) or 0))
		if value > 0 then
			local existing = mergedByUserId[player.UserId]
			if not existing or value > existing.value then
				mergedByUserId[player.UserId] = {
					userId = player.UserId,
					name = player.Name,
					value = value,
				}
			end
		end
	end

	local entries = {}
	for _, entry in pairs(mergedByUserId) do
		if entry.value > 0 then
			if not entry.name then
				entry.name = getPlayerName(entry.userId)
			end
			table.insert(entries, entry)
		end
	end

	sortEntries(entries)
	while #entries > MAX_ENTRIES do
		table.remove(entries)
	end

	return entries
end

local function getTopEntries(config)
	local cachedEntries = orderedEntriesCache[config.id]
	if not cachedEntries then
		return getFallbackEntries(config)
	end

	return mergeOnlineEntries(config, cachedEntries)
end

local function renderBoard(boardModel, config)
	local core = getBoardCore(boardModel)
	local displayPart, scroller, holder = ensureBoardDisplay(boardModel)
	if not (core and displayPart and scroller and holder) then
		return
	end

	for _, child in ipairs(holder:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local columns = getColumnLayout()
	local entries = getTopEntries(config)

	for rank = 1, MAX_ENTRIES do
		local entry = entries[rank]
		buildRow(
			holder,
			columns,
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

local function refreshOrderedCaches()
	for _, config in ipairs(LeaderboardConfigs) do
		local orderedEntries = fetchOrderedEntries(config)
		if orderedEntries then
			orderedEntriesCache[config.id] = orderedEntries
		elseif not orderedEntriesCache[config.id] then
			orderedEntriesCache[config.id] = {}
		end
	end
end

local function refreshOrderedBoards()
	refreshOrderedCaches()
	refreshAllBoards()
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
	local foundAny = false

	for _, config in ipairs(LeaderboardConfigs) do
		local model = Workspace:FindFirstChild(config.modelName)
		if model and model:IsA("Model") then
			boardModels[config.id] = model
			foundAny = true
		else
			warn("[WorkspaceLeaderboardService] Missing Workspace." .. config.modelName)
		end
	end

	return foundAny
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
				local updatedTotal = (player:GetAttribute("TotalCoinsCollected") or 0) + gained
				player:SetAttribute("TotalCoinsCollected", updatedTotal)
			end
			playerState.lastCoinsValue = newValue
		end)

		rebirths:GetPropertyChangedSignal("Value"):Connect(function()
			markDirty(player.UserId, "rebirths", rebirths.Value)
			queueRefresh(1)
		end)

		player:GetAttributeChangedSignal("RobuxSpent"):Connect(function()
			markDirty(player.UserId, "robux", player:GetAttribute("RobuxSpent") or 0)
			queueRefresh(1)
		end)

		player:GetAttributeChangedSignal("TotalCoinsCollected"):Connect(function()
			markDirty(player.UserId, "coins", player:GetAttribute("TotalCoinsCollected") or 0)
			queueRefresh(1)
		end)

		markDirty(player.UserId, "rebirths", rebirths.Value)
		markDirty(player.UserId, "robux", robuxSpent)
		markDirty(player.UserId, "coins", totalCoinsCollected)
		queueRefresh(1)
	end)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
	savePlayerTotals(player)
	flushDirtyUser(player.UserId)
	trackedPlayers[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

if setupBoards() then
	refreshAllBoards()
	task.delay(INITIAL_ORDERED_REFRESH_DELAY, refreshOrderedBoards)
end

task.spawn(function()
	while true do
		task.wait(FLUSH_INTERVAL)
		flushAllDirty()
	end
end)

task.spawn(function()
	while true do
		task.wait(ORDERED_REFRESH_INTERVAL)
		refreshOrderedBoards()
	end
end)

game:BindToClose(function()
	flushAllDirty()
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayerTotals(player)
		flushDirtyUser(player.UserId)
	end
end)

print("WorkspaceLeaderboardService loaded successfully.")
