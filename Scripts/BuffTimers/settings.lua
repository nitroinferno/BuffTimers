--[[

Mod: BuffTimers
Author: Nitro

--]]

--plagiarise https://www.nexusmods.com/morrowind/mods/53717 for UI settings menu.

local async = require("openmw.async")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local input = require("openmw.input")
local ui = require("openmw.ui")

local modInfo = require("Scripts.BuffTimers.modInfo")

local pageDescription = "By Nitro\nv" .. modInfo.version .. "\n\nBuff Timers"
local modEnableDescription = "This enables the mod or disables it."
local showMessagesDescription = "Enables UI messages to be shown for any cases which require it. (Currently none)"


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
		setting("showMessages", "checkbox", {}, "Show Messages", showMessagesDescription, true),
		setting("iconScaling", "inputText", {}, "Icon and Text Size", "Set the icon size in pixels. Default is 24, min/max is: 1/100", 24)
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
		description = "This is where you set the size of the icons.",
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
