--[[

Mod: Buffs_Timers
Author:Nitro

--]]

--Need to figure out how to save/load the position of the UI element 
--Need to figure out if I need to handle spell overwrites.


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
local iconSize = userInterfaceSettings:get("iconScaling")

-- Set the scale of the icons by checking for changes in the UI settings. 
userInterfaceSettings:subscribe(async:callback(function(section, key)
    if key then
        --print("Something changed in: ", section)
        print('Value is changed:', key, '=', userInterfaceSettings:get(key))
        iconSize = userInterfaceSettings:get(key)
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


--[[ local tableOfLayouts = com.createBuffsContent('pad')
local flexContent = com.ui.createFlex(tableOfLayouts)
local buffBoxElement = com.ui.createElementContainer(flexContent)
 ]]
local newRootLayouts, fx_icons = com.createRootFlexLayouts('pad',iconSize)
--traverseTable(newRootLayouts)

local newFlexRow = com.ui.createFlex(newRootLayouts)
newFlexRow.props.size = v2(40*15,40*4)
local newBuffBoxElement = com.ui.createElementContainer(newFlexRow)
newBuffBoxElement.layout.props.relativePosition = v2(0.5,0.1)

local newRootLayouts2, wrapFxIcons, fxData = com.createRootFlexLayouts('pad',iconSize, com.fltBuffTimers)
local rowsOfIcons = com.flexWrapper(newRootLayouts2,{iconsPerRow = 4})
--[[ for i, v in ipairs(rowsOfIcons) do
    print(rowsOfIcons[i].name, v)
  
    for key, data in pairs(v) do
        print(key, data)
        if key == 'content' then
            for idex=1, #v.content do
                print("   `--> "..v.content[idex].name)
            end
        end
    end

end ]]

local flexWrap = com.ui.createFlex(rowsOfIcons,false)
print(com.calculateRootFlexSize(rowsOfIcons))
--removed or v2(40*12,60*6) from below
flexWrap.props.size = com.calculateRootFlexSize(rowsOfIcons)
flexWrap.props.arrange = ui.ALIGNMENT.Center
--flexWrap.props.horizontal = false
print(flexWrap.props.arrange)
local flexWrapElement = com.ui.createElementContainer(flexWrap)
flexWrapElement.layout.props.relativePosition = v2(0,0)

--[[ traverseTable(newRootLayouts)
changeIcon[1].props.alpha = 0.3
print("-----------------revising alpha 1st icon to 0.3!!----------------")
traverseTable(newRootLayouts) ]]
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

--local uiEl = com.ui.toolTipBox(fxData[2])


--traverseTable(tableOfLayouts)
--print(tableOfLayouts[1][1].name)
--getContentKeys(tableOfLayouts[1], true)
--getContentKeys(tableOfLayouts[1].content, true)
--print(tableOfLayouts[1][1].content[1].name)

local buffElement = {}

local function updateUI_Element()
    com.destroyTooltip(true)
    local testingLayout = ui.content{com.createBuffsContent('pad')}
    getContentKeys(testingLayout[1], false)
    --print(com.calculateRootFlexSize(newRootLayouts[1].content))
    newRootLayouts, fx_icons = com.createRootFlexLayouts('pad',iconSize)
    newFlexRow = com.ui.createFlex(newRootLayouts)
    newFlexRow.props.size = v2(40*15,40*4)
    --if not next(buffBoxElement) then return end --Doesn't work with userData
    --tableOfLayouts = com.createBuffsContent('pad')
    --flexContent = com.ui.createFlex(tableOfLayouts)
    --local currLayout = buffBoxElement.layout
    --print(currLayout.content)
    --currLayout.content = ui.content{flexContent}
    
    local currNewBuff = newBuffBoxElement.layout
    currNewBuff.content = ui.content{newFlexRow}

    newRootLayouts2, wrapFxIcons = com.createRootFlexLayouts('pad',iconSize, com.fltBuffTimers)
    rowsOfIcons = com.flexWrapper(newRootLayouts2,{iconsPerRow = 4})
    flexWrap = com.ui.createFlex(rowsOfIcons,false)
    flexWrap.props.size = com.calculateRootFlexSize(rowsOfIcons)
    flexWrap.props.arrange = ui.ALIGNMENT.Center
    local curflexWrapElement = flexWrapElement.layout
    curflexWrapElement.content = ui.content{flexWrap}

    updateAlpha()

    for i,layout in ipairs(newRootLayouts) do
        --print(newRootLayouts[i].userdata.DurationLeft)
        --print(layout.content[1].userdata.effectInfo.durationLeft)
        if layout.userdata.Duration and layout.userdata.fx.durationLeft < 10 then
            --print(fx_icons[i].props.alpha and fx_icons[i].props.alpha)
            fx_icons[i].props.alpha = alpha

            --print(fx_icons[i].props.alpha and fx_icons[i].name .." ".. fx_icons[i].props.alpha)
            --print(layout.content[1].props.alpha and layout.content[1].props.alpha)
            --layout.content[1].props.alpha = alpha
            --print(layout.content[1].props.alpha and layout.content[1].props.alpha)
        end
    end
    for i,layout in ipairs(newRootLayouts2) do
        --print(newRootLayouts[i].userdata.DurationLeft)
        --print(layout.content[1].userdata.effectInfo.durationLeft)
        if layout.userdata.Duration and layout.userdata.fx.durationLeft < 10 then
            wrapFxIcons[i].props.alpha = alpha
        end
    end
   
    newBuffBoxElement:update()
    flexWrapElement:update()
    --buffBoxElement:update()
end


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
			buffElement = ui.create(newFlexRow)
			startUpdating()
		end
	end
end

local function onKeyRelease(key)

end

local function onUpdate(dt)

end

startUpdating()

return {
	engineHandlers = {
		onKeyPress = onKeyPress,
		onKeyRelease = onKeyRelease,
        onUpdate = onUpdate,
	}
}
