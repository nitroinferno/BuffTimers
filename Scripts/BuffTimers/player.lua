--[[

Mod: Buffs_Timers
Author:Nitro

--]]

--Need to figure out how to save/load the position of the UI element 
--Need to figure out if I need to handle spell overwrites.
--Consider creating update or init functions. 


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
--d_message("Initial Alpha: " .. alpha)


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

local function reverseTable(t)
    local reversed = {}
    for i = #t, 1, -1 do
        table.insert(reversed, t[i])
    end
    return reversed
end

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
            print('widget_name:',contentLayer[i].name,'at Index: ',i)
            --traverseTable(contentNames)
            if contentLayer[i].content then
                print('  `--ChildWidget_name: ', contentLayer[i].content[1].name )
            end
        end
    end
    return contentNames
end

local dummyLayout = ui.content {
    {
        name = 'someString',
        type = ui.TYPE.Image,
        props = {
            position = v2(0,0),
            size = v2(24, 24),
            relativePosition = v2(0,0),
            relativeSize = v2(0,0),
            anchor = v2(0,0),
            visible = true,
            alpha = 1,
            inheritAlpha = false,
            resource = ui.texture({path = 'white'})
        },
        userdata = {
        --some userdata
            --Duration = fx.duration,
        },
        events = {
        -- Some events perhaps mouseover Tooltip
        },
    },
}


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

-- Function to set up mouse events for a given flexWrapElement
local function setupMouseEvents(flexWrapElement)
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
end

-- Function to update flexWrap properties
local function updateFlexWrapProps(flexWrap, rowsOfIcons)
    if nilCheck(flexWrap, "props", "size") and nilCheck(flexWrap, "props", "arrange") then
        flexWrap.props.size = com.calculateRootFlexSize(rowsOfIcons)
        flexWrap.props.arrange = ui.ALIGNMENT.Center
    end
end

-- Initialize Buff and Debuff Layouts
local rootLayoutDebuffs, wrapFxIconsDebuffs = com.createRootFlexLayouts('pad', iconSize, com.fltDebuffTimers)
local rowsOfDebuffIcons = com.flexWrapper(rootLayoutDebuffs, { iconsPerRow = rowLimit, Alignment = getAlignment() })
local debuff_FlexWrap = com.ui.createFlex(rowsOfDebuffIcons, false)
updateFlexWrapProps(debuff_FlexWrap, rowsOfDebuffIcons)
local debuff_FlexWrapElement = com.ui.createElementContainer(debuff_FlexWrap)
debuff_FlexWrapElement.layout.props.relativePosition = v2(0,0.25)
setupMouseEvents(debuff_FlexWrapElement)

local rootLayoutBuffs, wrapFxIconsBuffs = com.createRootFlexLayouts('pad', iconSize, com.fltBuffTimers)
local rowsOfBuffIcons = com.flexWrapper(rootLayoutBuffs, { iconsPerRow = rowLimit, Alignment = getAlignment() })
local buff_FlexWrap = com.ui.createFlex(rowsOfBuffIcons, false)
updateFlexWrapProps(buff_FlexWrap, rowsOfBuffIcons)
local Buff_FlexWrapElement = com.ui.createElementContainer(buff_FlexWrap)
Buff_FlexWrapElement.layout.props.relativePosition = v2(0,0)
setupMouseEvents(Buff_FlexWrapElement)

--Funtion whether to display box around icons. 
local function getBoxSetting()
    if not showBox then
        Buff_FlexWrapElement.layout.props.alpha = 0
		debuff_FlexWrapElement.layout.props.alpha = 0
    else 
        Buff_FlexWrapElement.layout.props.alpha = 0.2
		debuff_FlexWrapElement.layout.props.alpha = 0.2
    end
end

getBoxSetting()


-- Function that updates both Buffs and Debuffs in UI
local function updateUI_Element()
    -- Destroy previous tooltips
    com.destroyTooltip(true)
	getBoxSetting()

    -- Update debuffs
    rootLayoutDebuffs, wrapFxIconsDebuffs = com.createRootFlexLayouts('pad', iconSize, com.fltDebuffTimers)
    rowsOfDebuffIcons = com.flexWrapper(rootLayoutDebuffs, { iconsPerRow = rowLimit, Alignment = getAlignment() })
    debuff_FlexWrap = com.ui.createFlex(rowsOfDebuffIcons, false)
    updateFlexWrapProps(debuff_FlexWrap, rowsOfDebuffIcons)

    -- Update buffs
    rootLayoutBuffs, wrapFxIconsBuffs = com.createRootFlexLayouts('pad', iconSize, com.fltBuffTimers)
    rowsOfBuffIcons = com.flexWrapper(rootLayoutBuffs, { iconsPerRow = rowLimit, Alignment = getAlignment() })
    buff_FlexWrap = com.ui.createFlex(rowsOfBuffIcons, false)
    updateFlexWrapProps(buff_FlexWrap, rowsOfBuffIcons)

    -- Get current layouts for buffs and debuffs
    local curDebuff_FlexWrapElement = debuff_FlexWrapElement.layout  -- Debuffs layout
    local curBuff_FlexWrapElement = Buff_FlexWrapElement.layout    -- Buffs layout (may need a separate flexWrapElement)

    -- Update debuff content
    curDebuff_FlexWrapElement.content = ui.content{
        debuff_FlexWrap or showBox and {props = {size = v2(iconSize*rowLimit, iconSize*util.round(buffLimit/rowLimit))}} or {}
    }

    -- Update buff content
    curBuff_FlexWrapElement.content = ui.content{
        buff_FlexWrap or showBox and {props = {size = v2(iconSize*rowLimit, iconSize*util.round(buffLimit/rowLimit))}} or {}
    }

    -- Update the alpha value (flashing effect)
    updateAlpha()

    -- Update alpha for debuff icons
    for i, layout in ipairs(rootLayoutDebuffs) do
        if layout.userdata.Duration and layout.userdata.fx.durationLeft < 10 then
            wrapFxIconsDebuffs[i].props.alpha = alpha
        end
    end

    -- Update alpha for buff icons
    for i, layout in ipairs(rootLayoutBuffs) do
        if layout.userdata.Duration and layout.userdata.fx.durationLeft < 10 then
            wrapFxIconsBuffs[i].props.alpha = alpha
        end
    end

    -- Update both debuff and buff flexWrap elements
    debuff_FlexWrapElement:update()
	Buff_FlexWrapElement:update()
end

local buffElement = {}


local function startUpdating()
    --timer = time.runRepeatedly(updateUI_Element, 5 * time.second, { type = time.GameTime }) --5 is a slow pulse, 2 is a quick pulse. Perhaps increase speed to 2, under 5s duration remaining. 
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

local function onKeyPress(key)
	local tempKeyBind = input.KEY.G
	if (not playerSettings:get("modEnable")) or (key.code ~= tempKeyBind) or core.isWorldPaused()  then return end
	if tempKeyBind == input.KEY.G then
		if buffElement then
			buffElement:destroy()
			buffElement = nil
			stopUpdating()
		else
			--buffElement = ui.create(newFlexRow)
			startUpdating()
		end
	end
end

local function onKeyRelease(key)

end

local function onUpdate(dt)

end

local function onSave()
end

local function onLoad()

end

startUpdating()

return {
	engineHandlers = {
		onKeyPress = onKeyPress,
		onKeyRelease = onKeyRelease,
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
	}
}
