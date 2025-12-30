--[[

Mod: Buffs_Timers
Author:Nitro

--]]

--Need to figure out how to save/load the position of the UI element 
--Need to figure out if I need to handle spell overwrites.
--Consider creating update or init functions. 

-- Need to figure out how to handle seperate buffs or not. perhaps wrap eveyrthing in an if statement. 


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
local wasPaused = false -- Track the previous pause state

local modInfo = require("Scripts.BuffTimers.modInfo")
local API = require("Scripts.BuffTimers.api")

local playerSettings = storage.playerSection("SettingsPlayer" .. modInfo.name)
local userInterfaceSettings = storage.playerSection("SettingsPlayer" .. modInfo.name .. "UI")
local controlsSettings = storage.playerSection("SettingsPlayer" .. modInfo.name .. "Controls")
local gameplaySettings = storage.playerSection("SettingsPlayer" .. modInfo.name .. "Gameplay")
local uiPositions = storage.playerSection("UI_positions") --added late

local xRes = ui.screenSize().x
local yRes = ui.screenSize().y

local debug = true
local timer = nil
local showTimedOnly = userInterfaceSettings:get("showTimedOnly")
local iconSize = userInterfaceSettings:get("iconScaling")
local showBox = userInterfaceSettings:get("showBox")
local buffAlign = userInterfaceSettings:get("buffAlign")
local debuffAlign = userInterfaceSettings:get("debuffAlign")
local splitBuffsDebuffs = userInterfaceSettings:get("splitBuffsDebuffs")
local iconOptions = userInterfaceSettings:get("iconOptions")
local timerColor = userInterfaceSettings:get("timerColor")
local detailTextColor = userInterfaceSettings:get("detailTextColor")
local iconPadding = userInterfaceSettings:get("iconPadding")
local rowLimit = userInterfaceSettings:get("rowLimit")
local buffLimit = userInterfaceSettings:get("buffLimit")
local enable = playerSettings:get("modEnable")

local function initLayer()
    if ui.layers[5].name == 'Effects_Layer' then return end -- Check if this layer already exists. 
    print("Creating Layer.. Effects Layer")
    ui.layers.insertAfter('HUD', 'Effects_Layer', { interactive = true })
end
initLayer()

---@return table
local function getStoredPositions()
    local stored = uiPositions:get("BuffPositions")

    if not stored then
        stored = {
            buffPos = v2(0, 0),
            debuffPos = v2(0, 0),
        }
        uiPositions:set("BuffPositions", stored)
    end
    -- Return a copy of a table, not a pointer to userData reference 
    return {
        buffPos   = stored.buffPos or v2(0, 0),
        debuffPos = stored.debuffPos or v2(0, 0),
    }
end


local buffPositions = getStoredPositions()

local function setPositionForKey(key,pos)
    if not key then return end
    local positions = getStoredPositions()
    positions[key] = pos
    uiPositions:set("BuffPositions", positions)
    buffPositions = positions
end

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
local alpha = 1 -- initial alpha 50%
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

-- Function to calculate size based on iconSize without children content
local function calculateDynamicSize(iconSize, pad)
    local padding = pad and 6 or 0
    
    -- Use iconSize directly for width
    local width = (iconSize+padding) or 30  -- Default to 30 if iconSize is nil
  
    -- Calculate total height using the logic from previous elements
    local fx_textSize = iconSize and (iconSize * 0.3+1)*2 or 10
    local fx_timeRemainSize = iconSize and iconSize * 0.3 + 1 or 10

    -- Total height is the sum of the text size, icon size, and timer size
    local totalHeight = fx_textSize + width + fx_timeRemainSize

    return v2(width, totalHeight)  -- Return as a vector
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


local function getAlignment(alignment)
    return alignment and ui.ALIGNMENT.Start or ui.ALIGNMENT.End
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
            if not showBox then return end
            layout.userData.doDrag = true
            layout.userData.lastMousePos = coord.position
            --print("mouseclicked!", coord.position, layout.name)
        end),
        mouseRelease = async:callback(function(_, layout)
            if not showBox then return end
            layout.userData.doDrag = false
            local key = layout.userData.positionKey
            if key then
                setPositionForKey(key, layout.props.position)
            end
            --print("mousereleased!")
        end),
        mouseMove = async:callback(function(coord, layout)
            if not showBox then return end
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

local function grabIndexes(tbl, x)
    local result = {}
    -- Ensure x doesn't exceed the table size
    local limit = math.min(x, #tbl)
    
    -- Loop through the first x elements and insert them into result
    for i = 1, limit do
        result[i] = tbl[i]
    end
    
    return result
end

-- Effect group helpers
local function createEffectGroup(def)
    return {
        key = def.key,
        filter = def.filter,
        align = def.align,
        positionKey = def.positionKey,
        anchor = def.anchor,
        relativePos = def.relativePos,
    }
end

local function getActiveEffectGroups()
    local filterBuff = showTimedOnly and com.fltBuffTimers
    local filtTime = showTimedOnly and com.fltTimeFx
	if splitBuffsDebuffs then
        return {
            createEffectGroup {
                key = "buffs",
                filter = filterBuff,
                align = buffAlign,
                positionKey = "buffPos",
            },
            createEffectGroup {
                key = "debuffs",
                filter = com.fltDebuffTimers,
                align = debuffAlign,
                positionKey = "debuffPos",
                anchor = v2(1,0),
                relativePos = v2(1,0),
            },
        }
    end

    return {
        createEffectGroup {
            key = "combined",
            filter = filtTime,
            align = buffAlign,
            positionKey = "buffPos",
        },
    }
end

local function updateEffectGroupVisuals(group, alphaValue, tooltipData, tooltipRootName)
    for i, layout in ipairs(group.rootLayouts) do
        if tooltipData and layout.name == tooltipRootName then
            com.updateToolTipText(layout.userdata.fx, tooltipData)
        end

        if layout.userdata.Duration and layout.userdata.fx.durationLeft < 10 then
            group.wraps[i].props.alpha = alphaValue
        end
    end
end

local function buildEffectGroup(def)
    local rootLayouts, wraps = com.createRootFlexLayouts(iconPadding and 'pad', iconSize, def.filter)
    rootLayouts = grabIndexes(rootLayouts, buffLimit)
    wraps = grabIndexes(wraps, buffLimit)

    local rows = com.flexWrapper(rootLayouts, { iconsPerRow = rowLimit, Alignment = getAlignment(def.align) })
    local flex = com.ui.createFlex(rows, false)
    updateFlexWrapProps(flex, rows)
    local element = com.ui.createElementContainer(flex)
    element.layout.userData.positionKey = def.positionKey -- Store a unique ID for buffPos or debuffPos

    local positions = buffPositions or getStoredPositions()
    element.layout.props.position = (positions and positions[def.positionKey]) or v2(0, 0)
    if def.anchor then
        element.layout.props.anchor = def.anchor
    end
    if def.relativePos then
        element.layout.props.relativePosition = def.relativePos
    end
    setupMouseEvents(element)

    return {
        key = def.key,
        filter = def.filter,
        align = def.align,
        positionKey = def.positionKey,
        rootLayouts = rootLayouts,
        wraps = wraps,
        rows = rows,
        flex = flex,
        element = element,
    }
end

local effectGroups = {}

local function destroyEffectGroups()
    for key, group in pairs(effectGroups) do
        if group.element then
            group.element:destroy()
        end
        effectGroups[key] = nil
    end
end

local function applyPositionsToGroups(positions)
    for _, group in pairs(effectGroups) do
        local pos = positions[group.positionKey]
        if pos and group.element and group.element.layout then
            group.element.layout.props.position = pos
            group.element:update()
        end
    end
end

-- Initialization function
local function initLayouts(callBack)
    destroyEffectGroups()

    for _, def in ipairs(getActiveEffectGroups()) do
        local group = buildEffectGroup(def)
        effectGroups[group.key] = group
    end

    if callBack then callBack() end
end

-- Call once initially
initLayouts()


--Funtion whether to display box around icons. 
local function getBoxSetting()
    local alphaBox = showBox and 0.2 or 0
    for _, group in pairs(effectGroups) do
        if group.element and group.element.layout then
            group.element.layout.props.alpha = alphaBox
        end
    end
end

getBoxSetting()
-- Function that updates both Buffs and Debuffs in UI
local function updateUI_Element()
    com.destroyTooltip(true)
	getBoxSetting()

    for _, g in pairs(effectGroups) do
        g.rootLayouts, g.wraps = com.createRootFlexLayouts(iconPadding and 'pad', iconSize, g.filter)
        g.rootLayouts = grabIndexes(g.rootLayouts,buffLimit)
        g.wraps = grabIndexes(g.wraps,buffLimit)
        g.rows = com.flexWrapper(g.rootLayouts, { iconsPerRow = rowLimit, Alignment = getAlignment(g.align) })
        g.flex = com.ui.createFlex(g.rows, false)
        updateFlexWrapProps(g.flex, g.rows)
    end

    local actualIconSz = calculateDynamicSize(iconSize,iconPadding)
    local buffBoxSize = v2(actualIconSz.x*rowLimit, actualIconSz.y*(util.round(buffLimit/rowLimit)))

    for _, g in pairs(effectGroups) do
        g.element.layout.content = ui.content{
            g.flex or showBox and {props = {size = buffBoxSize}} or {}
        }
    end

    if iconOptions ~= '3' then updateAlpha() end

    local tooltipData = com.getTooltip()
    local rootNameTT = tooltipData and tooltipData.layout.userdata.origin.name --name of the root layout

    for _, g in pairs(effectGroups) do
        updateEffectGroupVisuals(g, alpha, tooltipData, rootNameTT)
        g.element:update()
    end

end

local function rebuildAllEffectGroups()
    initLayouts(getBoxSetting)
    updateUI_Element()
end

local buffElement = {}


local function startUpdating()
    --timer = time.runRepeatedly(updateUI_Element, 5 * time.second, { type = time.GameTime }) --5 is a slow pulse, 2 is a quick pulse. Perhaps increase speed to 2, under 5s duration remaining.
    --Gametime is 30x faster than real time so 1s in gametime is 1/30s in real time.
    timer = time.runRepeatedly(updateUI_Element, 4/30 * time.second, { type = time.SimulationTime })
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
    local SavePositions = input.KEY.Equals
    local resetPositions = input.KEY.Minus
    local toggleBox = input.KEY.Semicolon
    if (not playerSettings:get("modEnable")) or (key.code ~= SavePositions) and (key.code ~= resetPositions) and (key.code ~= toggleBox) or core.isWorldPaused()  then return end

    if key.code == SavePositions then
        print("Saving Positions onKeyPress...")
        local stored = {}
        for _, group in pairs(effectGroups) do
            local element = group.element
            if element then
                local pos = element.layout and element.layout.props and element.layout.props.position
                if pos and group.positionKey then
                    --print(group.positionKey, pos)
                    stored[group.positionKey] = pos
                end
            end
        end
        uiPositions:set("BuffPositions", stored)
        buffPositions = stored
        print(uiPositions:get("BuffPositions").buffPos)
        print(uiPositions:get("BuffPositions").debuffPos)

    end

    if key.code == resetPositions then
        print("Reset Positions onKeyPress...")
        local reset = {buffPos = v2(0,0), debuffPos = v2(0,0)} --Consider getting relative position
        uiPositions:set("BuffPositions", reset)
        buffPositions = reset
        applyPositionsToGroups(reset)
        print(uiPositions:get("BuffPositions").buffPos)
        print(uiPositions:get("BuffPositions").debuffPos)
    end

    if key.code == toggleBox then
        userInterfaceSettings:set("showBox", not showBox)
    end
end

local function onKeyRelease(key)

end

local function onUpdate(dt)
    if not enable then return end
    if not I.UI.isHudVisible() and timer then
        --print("Hiding the Buff timers for screenshots!")
        stopUpdating()
        com.destroyTooltip('force')
        destroyEffectGroups()
    elseif I.UI.isHudVisible() and not timer then
        --If there is no timer, then stopupdating() has been called, reinitialize everything, startUpdating again. 
        rebuildAllEffectGroups()
        startUpdating() -- Creates the timer function
        --print("timer is not nil.. in the onUpdate function...")
    end
end

local function onFrame(dt)
    if dt ~= 0 or wasPaused == true then return end --indicates not paused
    wasPaused = true -- Set pause toggle

    if wasPaused then
        --print("Game paused!")
    end

end

local function onSave()
    print("OnSave called....")
    local stored = {}
    local changed = false

    for _, group in pairs(effectGroups) do
        local element = group.element
        if element then
            local pos = element.layout and element.layout.props and element.layout.props.position
            if pos and group.positionKey then
                print(group.positionKey, pos)
                stored[group.positionKey] = pos
                changed = true
            end
        end
    end

    if changed then
        --print(stored['buffPos'], stored['debuffPos'])
        uiPositions:set("BuffPositions", stored)
        buffPositions = stored
    end
end

local function onLoad()

end

startUpdating()


-- Set the scale of the icons by checking for changes in the UI settings. 
userInterfaceSettings:subscribe(async:callback(function(section, key)
    if key then
        print('Value is changed:', key, '=', userInterfaceSettings:get(key))
        if key == "showTimedOnly" then
            showTimedOnly = userInterfaceSettings:get(key)
            rebuildAllEffectGroups()
        elseif key == "iconScaling" then
            iconSize = userInterfaceSettings:get(key)
        elseif key == "showBox" then
            showBox = userInterfaceSettings:get(key)
            rebuildAllEffectGroups()
        elseif key == "buffAlign" then
            buffAlign = userInterfaceSettings:get(key)
            rebuildAllEffectGroups()
        elseif key == "debuffAlign" then
            debuffAlign = userInterfaceSettings:get(key)
            rebuildAllEffectGroups()
        elseif key == "splitBuffsDebuffs" then
            splitBuffsDebuffs = userInterfaceSettings:get(key)
            rebuildAllEffectGroups()
        elseif key == "iconOptions" then
            iconOptions = userInterfaceSettings:get(key)
            if iconOptions == '3' then
                alpha = 1
            end
        elseif key == "timerColor" then
            timerColor = userInterfaceSettings:get(key)
        elseif key == "detailTextColor" then
            detailTextColor = userInterfaceSettings:get(key)
        elseif key == "iconPadding" then
            iconPadding = userInterfaceSettings:get(key)
        elseif key == "rowLimit" then
            rowLimit = userInterfaceSettings:get(key)
        elseif key == "buffLimit" then
            buffLimit = userInterfaceSettings:get(key)
        elseif key == "showMagnitude" then
            rebuildAllEffectGroups()
        elseif key == "textScale" then
            rebuildAllEffectGroups()
        elseif key == "timerOptions" then
            rebuildAllEffectGroups()
        elseif key == "radialSwipe" then
            rebuildAllEffectGroups()
        end
    else
        print('All values are changed')
    end
end))

playerSettings:subscribe(async:callback(function(section, key)
    if key == "modEnable" then
        enable = playerSettings:get(key)
        if not enable then
            print("disabling.. ")
            stopUpdating()
            com.destroyTooltip('force')
            destroyEffectGroups()
        else
            print("enabling.. ")
            rebuildAllEffectGroups()
            startUpdating() -- Creates the timer function
        end
    end
end))


return {
    interfaceName = 'BuffTimers',
    interface = API.interface,
    engineHandlers = {
       onKeyPress = onKeyPress,
       onKeyRelease = onKeyRelease,
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
        onFrame = onFrame,
    },
    eventHandlers = {
        UiModeChanged = function(data)
            --print('UiModeChanged from', data.oldMode , 'to', data.newMode, '('..tostring(data.arg)..')')
            if not data.newMode then
                --print('Attempting to Destroy Tooltip...')
                com.destroyTooltip('force')
            end
        end
    },
}
