local MAX_INT_VALUE = 2147483647

local CoinGrantHelper = {}

local function getCoinsValue(player)
	if not player then
		return nil, "MissingPlayer"
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return nil, "MissingLeaderstats"
	end

	local coinsValue = leaderstats:FindFirstChild("Coins")
	if not coinsValue or not coinsValue:IsA("IntValue") then
		return nil, "MissingCoins"
	end

	return coinsValue
end

function CoinGrantHelper.grantCoins(player, amount, source)
	local sourceName = tostring(source or "UnknownSource")
	local numericAmount = tonumber(amount)
	if not numericAmount then
		warn("[CoinGrantHelper] Invalid coin amount from " .. sourceName)
		return false, "InvalidAmount"
	end

	numericAmount = math.floor(numericAmount)
	if numericAmount <= 0 then
		warn("[CoinGrantHelper] Non-positive coin amount from " .. sourceName .. ": " .. tostring(numericAmount))
		return false, "InvalidAmount"
	end

	local coinsValue, err = getCoinsValue(player)
	if not coinsValue then
		warn("[CoinGrantHelper] Failed to grant coins from " .. sourceName .. ": " .. tostring(err))
		return false, err
	end

	local previousValue = coinsValue.Value
	local nextValue = math.clamp(previousValue + numericAmount, 0, MAX_INT_VALUE)
	local grantedAmount = nextValue - previousValue
	if grantedAmount <= 0 then
		warn("[CoinGrantHelper] Coins cap prevented reward from " .. sourceName)
		return false, "CoinsCapReached"
	end

	coinsValue.Value = nextValue
	return true, grantedAmount, nextValue
end

return CoinGrantHelper
