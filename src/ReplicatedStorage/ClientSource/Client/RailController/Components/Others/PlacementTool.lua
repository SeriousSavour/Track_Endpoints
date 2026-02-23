--[[
	PlacementTool — multi-point spline rail placement

	Click       → add control point
	Enter       → finalize & send to server
	R           → reset / cancel
	T           → cycle tension (0 → 0.25 → 0.5 → 0.75 → 1 → 0)
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Superbullet = require(ReplicatedStorage.Packages.Superbullet)

local PlacementTool = {}

---- Services
local RailService

---- State
local player = Players.LocalPlayer

PlacementTool._controlPoints = {}
PlacementTool._markers = {}
PlacementTool._tension = 0

---- Constraints (enforced DURING editing, not after)
local MIN_POINT_DISTANCE = 10
local MAX_CONTROL_POINTS = 20
local TENSION_STEPS = { 0, 0.25, 0.5, 0.75, 1 }

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

function PlacementTool.GetGroundPosition(mousePosition)
	local camera = workspace.CurrentCamera
	local ray = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local filterList = {}
	if player.Character then
		table.insert(filterList, player.Character)
	end
	for _, m in PlacementTool._markers do
		table.insert(filterList, m)
	end
	params.FilterDescendantsInstances = filterList

	local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
	return result and result.Position or nil
end

function PlacementTool.CreateMarker(position, color)
	local marker = Instance.new("Part")
	marker.Shape = Enum.PartType.Ball
	marker.Size = Vector3.new(3, 3, 3)
	marker.Position = position
	marker.Anchored = true
	marker.CanCollide = false
	marker.Material = Enum.Material.Neon
	marker.Color = color
	marker.Parent = workspace
	table.insert(PlacementTool._markers, marker)
	return marker
end

function PlacementTool.ClearAll()
	for _, m in PlacementTool._markers do
		if m and m.Parent then m:Destroy() end
	end
	PlacementTool._markers = {}
	PlacementTool._controlPoints = {}
end

----------------------------------------------------------------
-- Constraint enforcement (checked every click, before accepting)
----------------------------------------------------------------

function PlacementTool.ValidatePoint(position)
	if #PlacementTool._controlPoints >= MAX_CONTROL_POINTS then
		print("[Rail] Max " .. MAX_CONTROL_POINTS .. " points reached")
		return false
	end
	if #PlacementTool._controlPoints > 0 then
		local last = PlacementTool._controlPoints[#PlacementTool._controlPoints]
		if (position - last).Magnitude < MIN_POINT_DISTANCE then
			print("[Rail] Too close — need " .. MIN_POINT_DISTANCE .. "+ studs from previous point")
			return false
		end
	end
	return true
end

----------------------------------------------------------------
-- Actions
----------------------------------------------------------------

function PlacementTool.AddPoint(mousePosition)
	local position = PlacementTool.GetGroundPosition(mousePosition)
	if not position then return end
	if not PlacementTool.ValidatePoint(position) then return end

	table.insert(PlacementTool._controlPoints, position)

	local color
	if #PlacementTool._controlPoints == 1 then
		color = Color3.new(0, 1, 0)
	else
		color = Color3.new(1, 1, 0)
	end
	PlacementTool.CreateMarker(position, color)
	print("[Rail] Point " .. #PlacementTool._controlPoints .. " placed")
end

function PlacementTool.Finalize()
	local count = #PlacementTool._controlPoints
	if count < 2 then
		print("[Rail] Need at least 2 points — click more, then press Enter")
		return
	end

	RailService.PlaceRailRequest:Fire(PlacementTool._controlPoints, PlacementTool._tension)
	print("[Rail] Building with " .. count .. " points, tension=" .. PlacementTool._tension)

	task.delay(2, function()
		PlacementTool.ClearAll()
	end)
end

function PlacementTool.CycleTension()
	local current = PlacementTool._tension
	for i, v in ipairs(TENSION_STEPS) do
		if math.abs(v - current) < 0.01 then
			local next = TENSION_STEPS[(i % #TENSION_STEPS) + 1]
			PlacementTool._tension = next
			print("[Rail] Tension = " .. next)
			return
		end
	end
	PlacementTool._tension = 0
	print("[Rail] Tension = 0")
end

function PlacementTool.ResetPlacement()
	PlacementTool.ClearAll()
	print("[Rail] Placement reset")
end

----------------------------------------------------------------
-- Lifecycle
----------------------------------------------------------------

function PlacementTool.Start()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			PlacementTool.AddPoint(UserInputService:GetMouseLocation())
		elseif input.KeyCode == Enum.KeyCode.Return then
			PlacementTool.Finalize()
		elseif input.KeyCode == Enum.KeyCode.T then
			PlacementTool.CycleTension()
		elseif input.KeyCode == Enum.KeyCode.R then
			PlacementTool.ResetPlacement()
		end
	end)

	print("[PlacementTool] Ready — Click to place points, Enter to build, T for tension, R to reset")
end

function PlacementTool.Init()
	RailService = Superbullet.GetService("RailService")
end

return PlacementTool
