--[[

Mod: Buff Timers
Author:Nitro

--]]

--Need to figure out how to save/load the position of the UI element 

local aux_util = require("openmw_aux.util")
local core = require("openmw.core")
local self = require("openmw.self")
local storage = require("openmw.storage")
local types = require("openmw.types")
local ui = require("openmw.ui")
local ambient = require("openmw.ambient")
local input = require("openmw.input")
local I = require("openmw.interfaces")
local util = require("openmw.util")
local time = require('openmw_aux.time')
local calendar = require('openmw_aux.calendar')
local async = require('openmw.async')
local v2 = util.vector2
local color = util.color
local fnc = require('Scripts.BuffTimers.common')
local auxUi = require('openmw_aux.ui')

local modInfo = require("Scripts.BuffTimers.modInfo")

local playerSettings = storage.playerSection("SettingsPlayer" .. modInfo.name)
local userInterfaceSettings = storage.playerSection("SettingsPlayer" .. modInfo.name .. "UI")
local controlsSettings = storage.playerSection("SettingsPlayer" .. modInfo.name .. "Controls")
local gameplaySettings = storage.playerSection("SettingsPlayer" .. modInfo.name .. "Gameplay")

local Actor = types.Actor
local Armor = types.Armor
local Item = types.Item
local Weapon = types.Weapon
local Clothing = types.Clothing
local Book = types.Book
local SLOT_CARRIED_RIGHT = Actor.EQUIPMENT_SLOT.CarriedRight
local weaponHotKeyPressed = false
local spellHotKeyPressed = false
local debug = true

local function traverseTable(tbl, indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)  -- Indentation for visualizing depth
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            print(prefix .. 'KEY:' .. tostring(key) .. " => Table")
            traverseTable(value, indent + 3)  -- Recursively traverse nested tables
        else
            print(prefix .. 'KEY:' .. tostring(key) .. " Value => " .. tostring(value))
        end
    end
end


local function d_message(msg)
	if not debug then return end

	ui.showMessage(tostring(msg))
end

local fadingOut = true
local alpha = 0.5 -- initial alpha 50%
d_message("Initial Alpha: " .. alpha)


local function d_print(fname, msg)
	if not debug then return end

	if fname == nil then
		fname = "\x1b[35mnil"
	end

	if msg == nil then
		msg = "\x1b[35mnil"
	end

	print("\n\t\x1b[33;3m" .. tostring(fname) .. "\n\t\t\x1b[33;3m" .. tostring(msg) .. "\n\x1b[39m")
end


local ActiveFX = Actor.activeSpells(self)

local function reverseTable(t)
    local reversed = {}
    for i = #t, 1, -1 do
        table.insert(reversed, t[i])
    end
    return reversed
end

local spellTable = fnc.getActiveSpells(Actor.activeSpells(self))

local debugOn = false

local myBuffs = fnc.getBuffs(spellTable)
local mydeBuffs = fnc.getdeBuffs(spellTable)

local allBuffsLayout = fnc.ui.createLayoutBasic2(myBuffs,_,v2(0.55,0),24)
local buffElement = {}
buffElement = ui.create(allBuffsLayout)
allBuffsLayout.content:add(fnc.ui.createFlexRow2(mydeBuffs,v2(0,-0.55),24))

allBuffsLayout.events = {
    mousePress = async:callback(function(coord, layout)
		layout.userData.doDrag = true
		layout.userData.lastMousePos = coord.position
		print("mouseclicked!", coord.position, layout.name)
		end),
    mouseRelease = async:callback(function(_, layout)
		layout.userData.doDrag = false
		print("mousereleased!")
		end),
    mouseMove = async:callback(function(coord, layout)
      if not layout.userData.doDrag then return end
      local props = layout.props
      props.position = props.position - (layout.userData.lastMousePos - coord.position)
	  buffElement:update()
      layout.userData.lastMousePos = coord.position
		end),
    }

local function updateAlpha()
    --local alpha = alpha
    if fadingOut and alpha >= 0.5 then
        alpha = alpha - 0.1
        if alpha <= 0.5 then
            fadingOut = false
        end
    else
        alpha = alpha + 0.1
        if alpha >= 1 then
            if alpha > 1 then alpha = 1 end
            fadingOut = true
        end
    end
end

local function getContentKeys(contentLayer, debugF)
    local contentNames = {}
    local printLog = debugF or false
    for i = 1, #contentLayer do
        contentNames[i] = contentLayer[i].name
        if printLog then
            print('widget',contentLayer[i].name,'at',i)
            --traverseTable(contentNames)
        end
    end
    return contentNames
end

local function removeExpiredBuff(element, contentLayer, index)
    -- Find the index of the element to remove
    if index then
        -- Shift content up from the expired buff to maintain the contiguous structure
        local content = contentLayer
        for i = index, #content - 1 do
            content[i] = content[i + 1]  -- Shift everything one index up
        end
        content[#content] = nil  -- Remove the last now-empty slot
    else
        print("Error: Could not find the index of the element")
    end
end

local function clearExpiredBuff(contentLayer, contentNameArray, tableCompare)
    print('I have entered ClearExpiredBuff()')
    local tmp_T = contentNameArray
    local remainBuffs = tableCompare
    local lookUp = nil
    local test
--[[     for k,v in pairs(remainBuffs) do
        print(v)
    end
    for key, val in pairs(tmp_T) do
        print(val)
    end ]]
    --this loop is being ignored after... doing contentLayer[contentKeyName] = {} sometimes...
    for i, contentKeyName in pairs(tmp_T) do
        lookUp = contentKeyName:match("_(.*)")
        test = contentKeyName
        print('CONTENT KEYNAMES  ' .. test)
        print(string.rep("+",50))
        print('   LOOKUP  =>' .. lookUp)
        if not remainBuffs[lookUp] then
            print(string.rep("-",50))
            print(contentKeyName..'\n ############## Is missing from the Timed Buffs Table #####')
            contentLayer[contentKeyName] = {}
            --table.remove(contentLayer,i) -- Causes it throw except when content table has a hole (e.g. index not at zero)
            --removeExpiredBuff(contentKeyName,contentLayer, i)
        end
    end
end

local timer = nil

local function updateUI_Element(buffs, debuffs)
    if not buffElement then return end
    local keyTimes = {}
    local layoutStr =  allBuffsLayout.content[1]
    local pad_contentTableNames
    for _, data in pairs(buffs) do
        for _, effect in pairs(data) do
            if effect.duration and effect.durationLeft > 0 then
                print(effect.name..'DurationLeft inside Loop: ' .. tostring(effect.durationLeft))
                keyTimes[effect.key] = { time = effect.durationLeft }
            end
        end
    end

    -- Update alpha value based on fade direction
    updateAlpha()

    -- iterate over a Content
--[[     for i = 1, #layoutStr.content do
        print('widget',layoutStr.content[i].name,'at',i)
    end ]]

    pad_contentTableNames = getContentKeys(layoutStr.content, true)
    clearExpiredBuff(layoutStr.content,pad_contentTableNames,keyTimes)
    --Need to turn the above into a function or something that returns the index, if the name matches, then can pass to 'if' below

    for k, v in pairs(keyTimes) do
        -- Safely check if content exists before modifying it
        local paddedElement = layoutStr.content['padded_'..k]
        local flexContainer = paddedElement and paddedElement.content['BuffFlexContainer_'.. k]
        if paddedElement and flexContainer then
            if v.time <= 10 then
                flexContainer.content[1].props.alpha = alpha
            end

            flexContainer.content[2].props.text = fnc.formatDuration(v.time)

        end
    end

    --auxUi.deepUpdate(buffElement)
    buffElement:update()
end


local function startUpdating()

    --timer = time.runRepeatedly(updateUI_Element, 5 * time.second, { type = time.GameTime }) --5 is a slow pulse, 2 is a quick pulse. Perhaps increase speed to 2, under 5s duration remaining. 
    timer = time.runRepeatedly(function()
        local currentSpells = Actor.activeSpells(self)
        local spellsTable = fnc.getActiveSpells(currentSpells)
        local buffs = fnc.getBuffs(spellsTable)
        local debuffs = fnc.getdeBuffs(spellsTable)
        updateUI_Element(buffs, debuffs)
    end, 5 * time.second, { type = time.GameTime })
end

local function stopUpdating()
    if timer then
        timer() -- Makes the timer stop
        timer = nil
        alpha = 1 -- Reset alpha to zero opacity when stopping
		--imageTest = imageContent()
    end
end

local function onKeyPress(key)
	local tempKeyBind = input.KEY.G
	if (not playerSettings:get("modEnable")) or (key.code ~= tempKeyBind) or core.isWorldPaused()  then return end
	if tempKeyBind == input.KEY.G then
		if buffElement then
			buffElement:destroy()
			buffElement = nil
			stopUpdating()
		else
			buffElement = ui.create(allBuffsLayout)
			startUpdating()
		end
	end
end

startUpdating()

local function onKeyRelease(key)

end


return {
	engineHandlers = {
		onKeyPress = onKeyPress,
		onKeyRelease = onKeyRelease,
	}
}
