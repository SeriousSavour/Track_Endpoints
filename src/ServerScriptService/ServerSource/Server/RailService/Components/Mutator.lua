local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Superbullet = require(ReplicatedStorage.Packages.Superbullet)

local module = {}

---- Components
local RailSpawner

function module.ClearAllRails()
	for _, folder in ipairs(RailSpawner._placedRails) do
		if folder and folder.Parent then
			folder:Destroy()
		end
	end
	table.clear(RailSpawner._placedRails)
end

function module.Start()

end

function module.Init()
	local RailService = Superbullet.GetService("RailService")
	RailSpawner = RailService.Components.RailSpawner
end

return module
