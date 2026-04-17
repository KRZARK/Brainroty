local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local MAX_ENTRIES = 50
local ENTRIES_PER_PAGE = 10
local PAGE_COUNT = math.ceil(MAX_ENTRIES / ENTRIES_PER_PAGE)
local ROW_HEIGHT = 96
local ROW_SPACING = 4
local PAGE_STEP = ENTRIES_PER_PAGE * (ROW_HEIGHT + ROW_SPACING)
local SCAN_INTERVAL = 2

local INACTIVE_BUTTON_COLOR = Color3.fromRGB(43, 56, 84)
local INACTIVE_TEXT_COLOR = Color3.fromRGB(234, 244, 255)
local INACTIVE_STROKE_COLOR = Color3.fromRGB(90, 118, 168)
local ACTIVE_BUTTON_COLOR = Color3.fromRGB(255, 201, 87)
local ACTIVE_TEXT_COLOR = Color3.fromRGB(20, 28, 43)
local ACTIVE_STROKE_COLOR = Color3.fromRGB(255, 232, 133)
local DISABLED_BUTTON_COLOR = Color3.fromRGB(32, 40, 58)
local DISABLED_TEXT_COLOR = Color3.fromRGB(152, 166, 188)

local bindings = {}

local function isPointerInput(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function clampPage(page)
	return math.clamp(page, 1, PAGE_COUNT)
end

local function getRowsGuiFromModel(model)
	local core = model:FindFirstChild("Time Played Leaderboard")
	local display = core and core:FindFirstChild("LeaderboardDisplay")
	return display and display:FindFirstChild("RowsGui")
end

local function isPointInside(guiObject, position)
	if not guiObject or not guiObject.Parent then
		return false
	end

	local absolutePosition = guiObject.AbsolutePosition
	local absoluteSize = guiObject.AbsoluteSize
	return position.X >= absolutePosition.X
		and position.X <= absolutePosition.X + absoluteSize.X
		and position.Y >= absolutePosition.Y
		and position.Y <= absolutePosition.Y + absoluteSize.Y
end

local function setButtonVisual(button, isActive, isDisabled)
	if not button then
		return
	end

	local stroke = button:FindFirstChild("PageButtonStroke")
	if isDisabled then
		button.BackgroundColor3 = DISABLED_BUTTON_COLOR
		button.BackgroundTransparency = 0.2
		button.TextColor3 = DISABLED_TEXT_COLOR
		if stroke then
			stroke.Color = INACTIVE_STROKE_COLOR
			stroke.Transparency = 0.45
		end
		return
	end

	button.BackgroundTransparency = 0.04
	if isActive then
		button.BackgroundColor3 = ACTIVE_BUTTON_COLOR
		button.TextColor3 = ACTIVE_TEXT_COLOR
		if stroke then
			stroke.Color = ACTIVE_STROKE_COLOR
			stroke.Transparency = 0
		end
	else
		button.BackgroundColor3 = INACTIVE_BUTTON_COLOR
		button.TextColor3 = INACTIVE_TEXT_COLOR
		if stroke then
			stroke.Color = INACTIVE_STROKE_COLOR
			stroke.Transparency = 0.15
		end
	end
end

local function applyButtonStates(binding)
	if not (binding.rowsGui.Parent and binding.scroller.Parent and binding.pageBar.Parent) then
		bindings[binding.rowsGui] = nil
		return
	end

	for pageIndex, pageButton in ipairs(binding.pageButtons) do
		setButtonVisual(pageButton, pageIndex == binding.currentPage, false)
	end

	setButtonVisual(binding.prevButton, false, binding.currentPage <= 1)
	setButtonVisual(binding.nextButton, false, binding.currentPage >= PAGE_COUNT)
end

local function setPage(binding, page)
	local clampedPage = clampPage(page)
	if binding.currentPage == clampedPage and binding.scroller.CanvasPosition.Y == (clampedPage - 1) * PAGE_STEP then
		applyButtonStates(binding)
		return
	end

	binding.currentPage = clampedPage
	binding.scroller.CanvasPosition = Vector2.new(0, (clampedPage - 1) * PAGE_STEP)
	applyButtonStates(binding)
end

local function syncPageFromScroller(binding)
	local targetPage = clampPage(math.floor((binding.scroller.CanvasPosition.Y + (PAGE_STEP * 0.5)) / PAGE_STEP) + 1)
	if targetPage ~= binding.currentPage then
		binding.currentPage = targetPage
	end
	applyButtonStates(binding)
end

local function activateHit(binding, position)
	if isPointInside(binding.prevButton, position) then
		setPage(binding, binding.currentPage - 1)
		return true
	end

	if isPointInside(binding.nextButton, position) then
		setPage(binding, binding.currentPage + 1)
		return true
	end

	for pageIndex, pageButton in ipairs(binding.pageButtons) do
		if isPointInside(pageButton, position) then
			setPage(binding, pageIndex)
			return true
		end
	end

	return false
end

local function bindRowsGui(rowsGui)
	if bindings[rowsGui] then
		return
	end

	local scroller = rowsGui:FindFirstChild("RowsScroller")
	local pageBar = rowsGui:FindFirstChild("PageBar")
	local prevButton = pageBar and pageBar:FindFirstChild("PrevButton")
	local nextButton = pageBar and pageBar:FindFirstChild("NextButton")
	local buttonsFrame = pageBar and pageBar:FindFirstChild("PageButtonsFrame")
	if not (scroller and pageBar and prevButton and nextButton and buttonsFrame) then
		return
	end

	local pageButtons = {}
	for pageIndex = 1, PAGE_COUNT do
		local pageButton = buttonsFrame:FindFirstChild("PageButton_" .. pageIndex)
		if not pageButton then
			return
		end
		pageButtons[pageIndex] = pageButton
	end

	local binding = {
		rowsGui = rowsGui,
		scroller = scroller,
		pageBar = pageBar,
		prevButton = prevButton,
		nextButton = nextButton,
		pageButtons = pageButtons,
		currentPage = 1,
	}
	bindings[rowsGui] = binding

	scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		syncPageFromScroller(binding)
	end)

	rowsGui.AncestryChanged:Connect(function(_, parent)
		if not parent then
			bindings[rowsGui] = nil
		end
	end)

	for pageIndex, pageButton in ipairs(pageButtons) do
		pageButton.Activated:Connect(function()
			setPage(binding, pageIndex)
		end)
		pageButton.MouseButton1Click:Connect(function()
			setPage(binding, pageIndex)
		end)
	end

	prevButton.Activated:Connect(function()
		setPage(binding, binding.currentPage - 1)
	end)
	prevButton.MouseButton1Click:Connect(function()
		setPage(binding, binding.currentPage - 1)
	end)

	nextButton.Activated:Connect(function()
		setPage(binding, binding.currentPage + 1)
	end)
	nextButton.MouseButton1Click:Connect(function()
		setPage(binding, binding.currentPage + 1)
	end)

	task.defer(function()
		setPage(binding, 1)
	end)
end

UserInputService.InputBegan:Connect(function(input)
	if not isPointerInput(input) then
		return
	end

	for _, binding in pairs(bindings) do
		if activateHit(binding, input.Position) then
			return
		end
	end
end)

local function scanBoards()
	for _, model in ipairs(Workspace:GetChildren()) do
		if model:IsA("Model") then
			local rowsGui = getRowsGuiFromModel(model)
			if rowsGui then
				bindRowsGui(rowsGui)
			end
		end
	end
end

Workspace.DescendantAdded:Connect(function(descendant)
	if descendant.Name == "RowsGui" and descendant:IsA("SurfaceGui") then
		bindRowsGui(descendant)
	end
end)

scanBoards()

task.spawn(function()
	while true do
		task.wait(SCAN_INTERVAL)
		scanBoards()
	end
end)

print("LeaderboardPageClient loaded")
