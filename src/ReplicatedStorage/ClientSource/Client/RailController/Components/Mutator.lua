local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Superbullet = require(ReplicatedStorage.Packages.Superbullet)

local module = {}

local PlacementTool

function module.ResetPlacement()
	PlacementTool.ResetPlacement()
end

function module.SetTension(value)
	PlacementTool._tension = math.clamp(value, 0, 1)
end

function module.Start()
end

function module.Init()
	local RailController = Superbullet.GetController("RailController")
	PlacementTool = RailController.Components.PlacementTool
end

return module
