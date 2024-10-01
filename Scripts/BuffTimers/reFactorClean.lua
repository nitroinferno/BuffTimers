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
local com = require('Scripts.BuffTimers.common')
local shader = require('Scripts.BuffTimers.radialSwipe')
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
local timer = nil
local showMessages = userInterfaceSettings:get("showMessages")
local iconSize = userInterfaceSettings:get("iconScaling")
local showBox = userInterfaceSettings:get("showBox")
local alignSetting = userInterfaceSettings:get("buffAlign")
local debuffAlign = userInterfaceSettings:get("debuffAlign")
local splitBuffsDebuffs = userInterfaceSettings:get("splitBuffsDebuffs")
local iconOptions = userInterfaceSettings:get("iconOptions")
local timerColor = userInterfaceSettings:get("timerColor")
local detailTextColor = userInterfaceSettings:get("detailTextColor")
local iconPadding = userInterfaceSettings:get("iconPadding")
local rowLimit = userInterfaceSettings:get("rowLimit")
local buffLimit = userInterfaceSettings:get("buffLimit")

local fadingOut = true
local alpha = 0.5 -- initial alpha 50%

-- Set the scale of the icons by checking for changes in the UI settings. 
userInterfaceSettings:subscribe(async:callback(function(section, key)
    if key then
        print('Value is changed:', key, '=', userInterfaceSettings:get(key))
        if key == "showMessages" then
            showMessages = userInterfaceSettings:get(key)
        elseif key == "iconScaling" then
            iconSize = userInterfaceSettings:get(key)
        elseif key == "showBox" then
            showBox = userInterfaceSettings:get(key)
        elseif key == "buffAlign" then
            alignSetting = userInterfaceSettings:get(key)
        elseif key == "debuffAlign" then
            debuffAlign = userInterfaceSettings:get(key)
        elseif key == "splitBuffsDebuffs" then
            splitBuffsDebuffs = userInterfaceSettings:get(key)
        elseif key == "iconOptions" then
            iconOptions = userInterfaceSettings:get(key)
        elseif key == "timerColor" then
            timerColor = userInterfaceSettings:get(key)
        elseif key == "detailTextColor" then
            detailTextColor = userInterfaceSettings:get(key)
        elseif key == "iconPadding" then
            iconPadding = userInterfaceSettings:get(key)
        elseif key == "rowLimit" then
            buffLimit = userInterfaceSettings:get(key)
        elseif key == "buffLimit" then
            buffLimit = userInterfaceSettings:get(key)
        end
    else
        print('All values are changed')
    end
end))

local function updateAlpha()
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

local function getAlignment()
    if alignSetting then
        return ui.ALIGNMENT.Start
    else 
        return ui.ALIGNMENT.End
    end
end

local function nilCheck(tbl, ...)
    local value = tbl
    for _, key in ipairs({...}) do
        value = value and value[key]  -- Only proceed if the current level isn't nil
        if value == nil then
            return nil  -- Return nil if any key level does not exist
        end
    end
    return value  -- Return the final value if all keys were valid
end


local newRootLayouts2, wrapFxIcons, fxData = com.createRootFlexLayouts('pad',iconSize, com.fltDebuffTimers)
local rowsOfIcons = com.flexWrapper(newRootLayouts2,{iconsPerRow = rowLimit, Alignment = getAlignment()})

local flexWrap = com.ui.createFlex(rowsOfIcons,false)
print(com.calculateRootFlexSize(rowsOfIcons))

if nilCheck(flexWrap,"props","size") and nilCheck(flexWrap,"props","arrange") then
    flexWrap.props.size = com.calculateRootFlexSize(rowsOfIcons)
    flexWrap.props.arrange = ui.ALIGNMENT.Center
end

local flexWrapElement = com.ui.createElementContainer(flexWrap)
flexWrapElement.layout.props.relativePosition = v2(0,0)

flexWrapElement.layout.events = {
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
	  flexWrapElement:update()
      layout.userData.lastMousePos = coord.position
		end),
}


--Funtion whether to display box around icons. 
local function getBoxSetting()
    if not showBox then
        flexWrapElement.layout.props.alpha = 0
    else 
        flexWrapElement.layout.props.alpha = 0.2
    end
end

getBoxSetting()

-- Function that updates the entire buff box element
local function updateUI_Element()
    com.destroyTooltip(true)
    getBoxSetting()

    newRootLayouts2, wrapFxIcons = com.createRootFlexLayouts('pad',iconSize, com.fltDebuffTimers)
    rowsOfIcons = com.flexWrapper(newRootLayouts2,{iconsPerRow = rowLimit, Alignment = getAlignment()})
    flexWrap = com.ui.createFlex(rowsOfIcons,false)
    if nilCheck(flexWrap,"props","size") and nilCheck(flexWrap,"props","arrange") then
        flexWrap.props.size = com.calculateRootFlexSize(rowsOfIcons)
        flexWrap.props.arrange = ui.ALIGNMENT.Center
    end
    local curflexWrapElement = flexWrapElement.layout

    curflexWrapElement.content = ui.content{flexWrap or showBox and {props = {size = v2(iconSize*rowLimit,iconSize*util.round(buffLimit/rowLimit))}} or {}}

    -- Update the alpha variable asssigned to flash the icon
    -- Perhaps we need to create 2 updateAlpha functions or have 2 alpha values, one for buffs one for debuffs
    updateAlpha()

    for i,layout in ipairs(newRootLayouts2) do
        if layout.userdata.Duration and layout.userdata.fx.durationLeft < 10 then
            wrapFxIcons[i].props.alpha = alpha
        end
    end
    flexWrapElement:update()
end


local function startUpdating()
    timer = time.runRepeatedly(updateUI_Element, 4 * time.second, { type = time.GameTime })
end

local function stopUpdating()
    if timer then
        timer() -- Makes the timer stop
        timer = nil
        alpha = 1 -- Reset alpha to zero opacity when stopping
		--imageTest = imageContent()
    end
end

startUpdating()