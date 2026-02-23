local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Superbullet = require(ReplicatedStorage.Packages.Superbullet)

local RailController = Superbullet.CreateController({
	Name = "RailController",
	Instance = script,
})

--- Superbullet Services
local RailService

function RailController:SuperbulletStart()
end

function RailController:SuperbulletInit()
	RailService = Superbullet.GetService("RailService")
end

return RailController
