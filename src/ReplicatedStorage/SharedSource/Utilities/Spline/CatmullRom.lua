--[[
	CatmullRom Spline Utility

	- Adjustable tension (0 = smooth Catmull-Rom, 1 = linear)
	- Arc-length parameterization for gap-free uniform sampling
	- Rotation-Minimizing Frames (double-reflection / Bishop frames)
]]

local CatmullRom = {}

--------------------------------------------------------------------------------
-- Core evaluation (single segment p1→p2, with neighbors p0 and p3)
--------------------------------------------------------------------------------

function CatmullRom.Position(p0, p1, p2, p3, t, tension)
	local s = (1 - (tension or 0)) / 2
	local t2 = t * t
	local t3 = t2 * t
	return (-s * p0 + (2 - s) * p1 + (s - 2) * p2 + s * p3) * t3
		+ (2 * s * p0 + (s - 3) * p1 + (3 - 2 * s) * p2 - s * p3) * t2
		+ (-s * p0 + s * p2) * t
		+ p1
end

function CatmullRom.Tangent(p0, p1, p2, p3, t, tension)
	local s = (1 - (tension or 0)) / 2
	local t2 = t * t
	return 3 * (-s * p0 + (2 - s) * p1 + (s - 2) * p2 + s * p3) * t2
		+ 2 * (2 * s * p0 + (s - 3) * p1 + (3 - 2 * s) * p2 - s * p3) * t
		+ (-s * p0 + s * p2)
end

--------------------------------------------------------------------------------
-- Arc-length parameterization
--------------------------------------------------------------------------------

function CatmullRom.BuildArcLUT(p0, p1, p2, p3, tension, steps)
	steps = steps or 64
	local lut = { { t = 0, len = 0 } }
	local total = 0
	local prev = p1
	for i = 1, steps do
		local t = i / steps
		local pos = CatmullRom.Position(p0, p1, p2, p3, t, tension)
		total = total + (pos - prev).Magnitude
		prev = pos
		table.insert(lut, { t = t, len = total })
	end
	return lut, total
end

function CatmullRom.ArcToT(lut, dist)
	if dist <= 0 then return 0 end
	if dist >= lut[#lut].len then return 1 end
	local lo, hi = 1, #lut
	while lo < hi - 1 do
		local mid = math.floor((lo + hi) / 2)
		if lut[mid].len < dist then
			lo = mid
		else
			hi = mid
		end
	end
	local segLen = lut[hi].len - lut[lo].len
	if segLen < 1e-8 then return lut[lo].t end
	local frac = (dist - lut[lo].len) / segLen
	return lut[lo].t + frac * (lut[hi].t - lut[lo].t)
end

--------------------------------------------------------------------------------
-- Rotation-Minimizing Frame propagation (double-reflection method)
--------------------------------------------------------------------------------

function CatmullRom.PropagateRMF(prevPos, prevTan, prevNorm, curPos, curTan)
	local v1 = curPos - prevPos
	local c1 = v1:Dot(v1)
	if c1 < 1e-10 then return prevNorm end
	local rL = prevNorm - (2 / c1) * v1:Dot(prevNorm) * v1
	local rT = prevTan - (2 / c1) * v1:Dot(prevTan) * v1
	local v2 = curTan - rT
	local c2 = v2:Dot(v2)
	if c2 < 1e-10 then return rL end
	return rL - (2 / c2) * v2:Dot(rL) * v2
end

--------------------------------------------------------------------------------
-- Build uniformly-spaced CFrames along a full spline
--
-- controlPoints : {Vector3}  (>= 2)
-- stepSize      : arc-length between samples (studs)
-- tension       : 0..1
--
-- Returns : { { position, cframe, tangent, normal, binormal } , ... }
--------------------------------------------------------------------------------

function CatmullRom.BuildFrames(controlPoints, stepSize, tension)
	if type(controlPoints) ~= "table" then
		warn("[CatmullRom] controlPoints must be a table, got", typeof(controlPoints))
		return {}
	end
	local n = #controlPoints
	if n < 2 then return {} end
	tension = tension or 0
	stepSize = stepSize or 4

	-- 1. Collect raw uniform-arc-length samples across all segments
	local raw = {}
	for seg = 1, n - 1 do
		local p0 = controlPoints[math.max(1, seg - 1)]
		local p1 = controlPoints[seg]
		local p2 = controlPoints[seg + 1]
		local p3 = controlPoints[math.min(n, seg + 2)]

		local lut, arcLen = CatmullRom.BuildArcLUT(p0, p1, p2, p3, tension)
		local numSteps = math.max(1, math.ceil(arcLen / stepSize))
		local last = (seg == n - 1) and numSteps or (numSteps - 1)

		for j = 0, last do
			local dist = (j / numSteps) * arcLen
			local t = CatmullRom.ArcToT(lut, dist)
			local pos = CatmullRom.Position(p0, p1, p2, p3, t, tension)
			local tan = CatmullRom.Tangent(p0, p1, p2, p3, t, tension)
			if tan.Magnitude < 1e-6 then
				tan = (p2 - p1)
			end
			tan = tan.Unit
			table.insert(raw, { position = pos, tangent = tan })
		end
	end

	if #raw < 2 then return {} end

	-- 2. Compute initial normal (project world-up perpendicular to tangent)
	local firstTan = raw[1].tangent
	local initNormal = Vector3.yAxis - firstTan * firstTan:Dot(Vector3.yAxis)
	if initNormal.Magnitude < 1e-6 then
		initNormal = Vector3.xAxis - firstTan * firstTan:Dot(Vector3.xAxis)
	end
	initNormal = initNormal.Unit

	-- 3. Build frames with RMF propagation
	local frames = {}
	local prevNorm = initNormal

	for i, sample in ipairs(raw) do
		local tangent = sample.tangent
		local normal

		if i == 1 then
			normal = initNormal
		else
			normal = CatmullRom.PropagateRMF(
				raw[i - 1].position, raw[i - 1].tangent, prevNorm,
				sample.position, tangent
			)
			if normal.Magnitude < 1e-6 then
				normal = prevNorm
			else
				normal = normal.Unit
			end
		end

		local binormal = tangent:Cross(normal)
		if binormal.Magnitude < 1e-6 then
			binormal = tangent:Cross(Vector3.yAxis)
			if binormal.Magnitude < 1e-6 then
				binormal = tangent:Cross(Vector3.xAxis)
			end
		end
		binormal = binormal.Unit
		normal = binormal:Cross(tangent).Unit

		local cf = CFrame.fromMatrix(sample.position, binormal, normal, -tangent)

		table.insert(frames, {
			position = sample.position,
			cframe = cf,
			tangent = tangent,
			normal = normal,
			binormal = binormal,
		})

		prevNorm = normal
	end

	return frames
end

return CatmullRom
