local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Superbullet = require(ReplicatedStorage.Packages.Superbullet)

local RailService = Superbullet.CreateService({
	Name = "RailService",
	Instance = script,
	Client = {
		PlaceRailRequest = Superbullet.CreateSignal(),
	},
	_lastPlacement = {},
})

---- Constants
local MIN_POINTS = 2
local MAX_POINTS = 20
local PLACEMENT_COOLDOWN = 2

function RailService:HandlePlaceRail(player, controlPoints, tension)
	-- Validate controlPoints is a table
	if typeof(controlPoints) ~= "table" then
		warn("[RailService] Bad controlPoints type from", player.Name)
		return
	end

	-- Validate count
	if #controlPoints < MIN_POINTS or #controlPoints > MAX_POINTS then
		warn("[RailService] Bad point count:", #controlPoints, "from", player.Name)
		return
	end

	-- Validate every entry is Vector3
	for i, pt in ipairs(controlPoints) do
		if typeof(pt) ~= "Vector3" then
			warn("[RailService] Point", i, "not Vector3 from", player.Name)
			return
		end
	end

	-- Sanitize tension
	tension = (typeof(tension) == "number") and math.clamp(tension, 0, 1) or 0

	-- Rate limit
	local uid = player.UserId
	local now = os.clock()
	if self._lastPlacement[uid] and (now - self._lastPlacement[uid]) < PLACEMENT_COOLDOWN then
		warn("[RailService] Rate limited:", player.Name)
		return
	end
	self._lastPlacement[uid] = now

	-- Spawn
	RailService.Components.RailSpawner.SpawnRails(controlPoints, tension)
end

function RailService:SuperbulletStart()
	self.Client.PlaceRailRequest:Connect(function(player, controlPoints, tension)
		self:HandlePlaceRail(player, controlPoints, tension)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self._lastPlacement[player.UserId] = nil
	end)
end

function RailService:SuperbulletInit()
end

return RailService
