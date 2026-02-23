local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Superbullet = require(ReplicatedStorage.Packages.Superbullet)

local module = {}

---- Components
local RailSpawner

function module.GetPlacedRails()
	return RailSpawner._placedRails
end

function module.Start()

end

function module.Init()
	local RailService = Superbullet.GetService("RailService")
	RailSpawner = RailService.Components.RailSpawner
end

return module
