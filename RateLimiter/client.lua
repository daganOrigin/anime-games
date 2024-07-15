
local function createRate(timeFunction: () -> number, rates: {[any]: number}, ignoreFirstRate: boolean?)
	local RateLimiter = {}
	local earlierTimes = {} :: {
		[any]: number
	}

	local initialTime = ignoreFirstRate and 0 or timeFunction()

	for index, rate in rates do
		earlierTimes[index] = initialTime
	end

	function RateLimiter:isOver(index: any)
		if not rates[index] then
			warn(`unable to find {index} in rates`)
			return false
		end

		local timeNow = timeFunction()

		if timeNow < earlierTimes[index] then
			return false
		end

		earlierTimes[index] = timeNow + rates[index]

		return true
	end

	-- should be used for localscripts in 'StarterCharacterScripts'
	function RateLimiter:clear()
		table.clear(earlierTimes)
		table.clear(rates) 
		table.clear(self)
	end

	return RateLimiter
end

return {
	new = createRate
}
