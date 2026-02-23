--[[
	RailSettingsData
	Defines slider constraints and defaults for the Track Settings panel.
	Shared between client (GUI) and server (validation).
]]

local RailSettingsData = {
	Tension = {
		Default = 0.5,
		Min = 0,
		Max = 1,
		Step = 0.05,
		DisplayName = "Curve Tension",
		Format = "%.2f",
	},

	Banking = {
		Default = 25,
		Min = 0,
		Max = 45,
		Step = 1,
		DisplayName = "Banking (°)",
		Format = "%d",
	},

	Smoothness = {
		Default = 1.5,
		Min = 0.5,
		Max = 3,
		Step = 0.1,
		DisplayName = "Smoothness",
		Format = "%.1f",
	},

	HeightOffset = {
		Default = 0,
		Min = 0,
		Max = 10,
		Step = 0.5,
		DisplayName = "Height Offset",
		Format = "%.1f",
	},

	-- Ordered list for GUI rendering
	Order = { "Tension", "Banking", "Smoothness", "HeightOffset" },
}

return RailSettingsData
