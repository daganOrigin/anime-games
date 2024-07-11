local RunService = game:GetService("RunService")

if RunService:IsClient() then
	-- to make the same object accessible for all local scripts, maybe i should made local not oop
	return require(script.Client).new()
end

-- stateprofiles[player]
return require(script.Server)
