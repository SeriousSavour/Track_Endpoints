local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Superbullet = require(ReplicatedStorage.Packages.Superbullet)

local module = {}

local PlacementTool

function module.GetControlPoints()
	return PlacementTool._controlPoints
end

function module.GetTension()
	return PlacementTool._tension
end

function module.GetPointCount()
	return #PlacementTool._controlPoints
end

function module.Start()
end

function module.Init()
	local RailController = Superbullet.GetController("RailController")
	PlacementTool = RailController.Components.PlacementTool
end

return module
