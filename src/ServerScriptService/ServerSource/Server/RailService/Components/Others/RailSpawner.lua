--[[
	RailSpawner — generates rail geometry by extruding a cross-section
	along a Catmull-Rom spline using rotation-minimizing frames.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CatmullRom = require(
	ReplicatedStorage:WaitForChild("SharedSource", 5).Utilities.Spline.CatmullRom
)

local RailSpawner = {}
RailSpawner._placedRails = {}

---- Track cross-section config ------------------------------------------------

local RAIL_GAUGE    = 5.87   -- center-to-center of the two rails
local RAIL_WIDTH    = 0.66
local RAIL_HEIGHT   = 0.60
local RAIL_COLOR    = Color3.new(0.424, 0.345, 0.294)
local RAIL_MATERIAL = Enum.Material.Metal

local TIE_WIDTH     = 10.91  -- across the track
local TIE_HEIGHT    = 0.40
local TIE_DEPTH     = 1.50   -- along the track
local TIE_SPACING   = 4      -- studs between ties
local TIE_COLOR     = Color3.new(0.35, 0.25, 0.15)
local TIE_MATERIAL  = Enum.Material.Wood

local STEP_SIZE     = 2      -- arc-length per rail segment (lower = smoother)

---- Helpers -------------------------------------------------------------------

local function makeRailPart(p1, p2, upHint, folder)
	local mid = (p1 + p2) * 0.5
	local segLen = (p2 - p1).Magnitude
	if segLen < 0.01 then return end

	local part = Instance.new("Part")
	part.Size = Vector3.new(RAIL_WIDTH, RAIL_HEIGHT, segLen)
	part.CFrame = CFrame.lookAt(mid, p2, upHint)
	part.Anchored = true
	part.CanCollide = true
	part.Material = RAIL_MATERIAL
	part.Color = RAIL_COLOR
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = folder
end

local function makeTie(cf, folder)
	local pos = cf:PointToWorldSpace(Vector3.new(0, TIE_HEIGHT * 0.5, 0))
	local tie = Instance.new("Part")
	tie.Size = Vector3.new(TIE_WIDTH, TIE_HEIGHT, TIE_DEPTH)
	tie.CFrame = CFrame.lookAt(pos, pos + cf.LookVector, cf.UpVector)
	tie.Anchored = true
	tie.CanCollide = true
	tie.Material = TIE_MATERIAL
	tie.Color = TIE_COLOR
	tie.TopSurface = Enum.SurfaceType.Smooth
	tie.BottomSurface = Enum.SurfaceType.Smooth
	tie.Parent = folder
end

---- Public API ----------------------------------------------------------------

function RailSpawner.SpawnRails(controlPoints, tension)
	local frames = CatmullRom.BuildFrames(controlPoints, STEP_SIZE, tension)
	if #frames < 2 then
		warn("[RailSpawner] Not enough spline frames")
		return nil
	end

	local folder = Instance.new("Folder")
	folder.Name = "Rail_" .. tostring(math.floor(os.clock() * 100))

	local halfGauge = RAIL_GAUGE * 0.5
	local railY = TIE_HEIGHT + RAIL_HEIGHT * 0.5
	local arcSinceTie = TIE_SPACING -- place first tie immediately

	for i = 1, #frames - 1 do
		local cf1 = frames[i].cframe
		local cf2 = frames[i + 1].cframe
		local upHint = ((cf1.UpVector + cf2.UpVector) * 0.5).Unit

		-- Left rail segment
		local lp1 = cf1:PointToWorldSpace(Vector3.new(-halfGauge, railY, 0))
		local lp2 = cf2:PointToWorldSpace(Vector3.new(-halfGauge, railY, 0))
		makeRailPart(lp1, lp2, upHint, folder)

		-- Right rail segment
		local rp1 = cf1:PointToWorldSpace(Vector3.new(halfGauge, railY, 0))
		local rp2 = cf2:PointToWorldSpace(Vector3.new(halfGauge, railY, 0))
		makeRailPart(rp1, rp2, upHint, folder)

		-- Ties at interval
		local segDist = (frames[i + 1].position - frames[i].position).Magnitude
		arcSinceTie = arcSinceTie + segDist
		if arcSinceTie >= TIE_SPACING then
			arcSinceTie = arcSinceTie - TIE_SPACING
			makeTie(cf1, folder)
		end
	end

	folder.Parent = workspace
	table.insert(RailSpawner._placedRails, folder)
	print("[RailSpawner] Built rail:", #frames, "frames")
	return folder
end

---- Lifecycle -----------------------------------------------------------------

function RailSpawner.Start()
end

function RailSpawner.Init()
end

return RailSpawner
