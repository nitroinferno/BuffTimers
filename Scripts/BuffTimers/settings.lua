--[[

Mod: BuffTimers
Author: Nitro

--]]

-- Add user Setting for radial swipe direction and perhaps color

local async = require("openmw.async")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local input = require("openmw.input")
local ui = require("openmw.ui")
local util = require('openmw.util')
local core = require("openmw.core")

--local color = util.color

local modInfo = require("Scripts.BuffTimers.modInfo")
local l10n = core.l10n(modInfo.name)

-- local pageDescription = "By Nitro\nv" .. modInfo.version .. "\n\nBuff Timers\n\nThis mod shows all buffs or debuffs with timers and optional dynamic visual effects."
-- .."\n\nYou can click and drag both buff or debuff windows to any location on the HUD.\n\nFor Buff/Debuff HUD Positions:\n    Press '=' key to Save\n    Press '-' key to Reset"
-- local modEnableDescription = "This enables the mod or disables it."
-- local showTimedBuffsDescription = "Show only buffs/debuffs that have timers. When disabled all buffs/debuffs are shown."
-- local iconOptions = "Select which options you want for the icons the following options are available: \n 1. All (contains all below)\n 2. Icon Pulse on low time\n 3. Radial Swipe"
-- local sizeAndPosition = "Enable this to show the area box where buff icons will be rendered. When enabled allows click + drag on buff/debuff regions for repositioning." 
-- .."\n\nMouse Release saves the position, press '-' key to reset to default position."

local pageDescription = l10n("pageDescription", { version = modInfo.version })
local modEnableDescription = l10n("modEnableDescription")
local showTimedBuffsDescription = l10n("showTimedBuffsDescription")
local iconOptions = l10n("iconOptionsDescription")
local sizeAndPosition = l10n("sizeAndPositionDescription")


local menuParams = {
	const = {

	},
}

local function setting(key, renderer, argument, name, description, default)
	return {
		key = key,
		renderer = renderer,
		argument = argument,
		name = name,
		description = description,
		default = default,
	}
end

I.Settings.registerPage {
	key = modInfo.name,
	l10n = modInfo.name,
	name = "Buff Timers",
	description = pageDescription
}

I.Settings.registerGroup {
	key = "SettingsPlayer" .. modInfo.name,
	page = modInfo.name,
	order = 0,
	l10n = modInfo.name,
	name = "General",
	permanentStorage = false,
	settings = {
		setting("modEnable", "checkbox", {}, "Enable Mod", modEnableDescription, true),
	}
}

I.Settings.registerGroup {
	key = "SettingsPlayer" .. modInfo.name .. "UI",
	page = modInfo.name,
	order = 1,
	l10n = modInfo.name,
	name = "UI",
	permanentStorage = false,
	settings = {
		setting("showTimedOnly", "checkbox", {}, l10n("show_timed"), showTimedBuffsDescription, true),
		setting("iconScaling", "inputText", {defaultValue = 35}, l10n("buffScaling"), l10n("buffScalingDescription"), 35),
		setting("textScale", "number", {defaultValue = 1.0, max = 1.65, min = 0}, l10n("textScaling"), l10n("textScalingDescription"), 1.0),
		setting("showBox","checkbox",{}, l10n("posModeTex"), sizeAndPosition,true),
		setting("showMagnitude","checkbox",{}, l10n("showMag"), l10n("showMagDescription"),true),
		setting("buffAlign","checkbox",{}, l10n("buffAlign"), l10n("buffAlignDescription"),true),
		setting("debuffAlign","checkbox",{}, l10n("debuffAlign"), l10n("debuffAlignDescription"),true),
		setting("splitBuffsDebuffs","checkbox",{}, l10n("splitOption"), l10n("splitOptionDescription"), true),
		setting("iconOptions", "select", {l10n = modInfo.name, items = {"1", "2", "3"}}, l10n("fxSelection"), iconOptions, "1"),
		setting("timerColor","color",{}, l10n("timeColor"), l10n("timeColorDescription"), util.color.rgb(255, 255, 255)),
		setting("detailTextColor","color",{}, l10n("detailsColor"), l10n("detailsColorDescription"),util.color.hex('DFC99F')),
		setting("iconPadding","checkbox",{}, l10n("iconPad"), l10n("iconPadDescription"), true),
		setting("rowLimit","inputText",{defaultValue = 15}, l10n("maxPerRow"), l10n("maxPerRowDescription"), 15),
		setting("buffLimit","inputText",{defaultValue = 100}, l10n("maxTotalIcon"), l10n("maxTotalIconDescriptio"), 100),
		setting("radialSwipe","checkbox",{l10n = modInfo.name, trueLabel = 'UnShade', falseLabel = 'Shade'}, l10n("radialOptions"), l10n("radialOptionsDescription"), true),
		setting("timerOptions", "select", {l10n = modInfo.name, items = {"Bottom", "Mid", "Top"}}, l10n("textPosOption"), l10n("textPosOptionDescription"), "Bottom"),
	}
}

I.Settings.registerGroup {
	key = "SettingsPlayer" .. modInfo.name .. "Controls",
	page = modInfo.name,
	order = 2,
	l10n = modInfo.name,
	name = "Controls",
	permanentStorage = false,
	settings = {
		--Add settings here
	}
}

-- No need to even show this setting in 0.48
if (core.API_REVISION >= 31) then
	I.Settings.registerGroup {
		key = "SettingsPlayer" .. modInfo.name .. "Gameplay",
		page = modInfo.name,
		order = 3,
		l10n = modInfo.name,
		name = "Gameplay",
		permanentStorage = false,
		description = "Settings that modify how the icons interact with gameplay",
		settings = {
			--setting("iconScaling", "inputText", {}, "TextInputRenderer", "Test_of_icon_ScalingRenderer", 24),
		}
	}
end

--[[ for _, actionInfo in ipairs(actions) do
	--print(actionInfo)
	input.registerAction(actionInfo)
end ]]

print("[" .. modInfo.name .. "] Initialized v" .. modInfo.version)
