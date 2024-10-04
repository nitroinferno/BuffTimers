--[[

Mod: Scrollable Weapons and Spells
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
local parts = require('Scripts.BuffTimers.common')

local modInfo = require("Scripts.ScrollHotKeyCombo.modInfo")

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

local function getEffectIcon(effect)
    --local strWithoutSpaces = string.gsub(effect.name, "%s", "")
    -- if( effectData[strWithoutSpaces] == nil) then
    --    ----print(strWithoutSpaces)
    --  end
    --strWithoutSpaces= string.sub(effectData[strWithoutSpaces], 1, -4) .. "dds"
    -- ----print(strWithoutSpaces)
    return effect.icon
end

local savedTextures = {}
local function getTexture(path)
    if not path then return nil end
    if not savedTextures[path] then
        savedTextures[path] = ui.texture({ path = path })
    end
    return savedTextures[path]
end
local magicIcon = nil
--magicIcon = getTexture(item.icon)


local function textContent(inputText, size)
    return {
        template = I.MWUI.templates.textNormal,
		type = ui.TYPE.Text,
		props = {
			text = inputText,
			autoSize = false,
			relativePosition = v2(0, 0),
			anchor = v2(0, 0),
			position = v2(0,0),
			--relativeSize = v2(100,100), --RelativeSize or Position do not work on I.MWUI.templates.box
			--textColor = color.hex('FFFFFF'),
			textSize = size and size.x/3 or 15,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
			size = size or v2(40,40),
			inheritAlpha = false,
		}
    }
end

local function imageContent(resource, size)
	if (size == nil) then
        size = 40
    end
    if not resource then
        return {
            --        type = ui.TYPE.Container,
            resource = resource,
			props = {
            size = v2(size, size),
			alpha = alpha,
			position = v2(20,20),
                -- relativeSize = util.vector2(1,1)
            }
        }
    end
    return {
        type = ui.TYPE.Image,
        props = {
            resource = resource,
            size = v2(size, size),
			alpha = alpha,
			position = v2(0,0),
            -- relativeSize = util.vector2(1,1)
        },
		content = ui.content {textContent("10m")}

    }
end

local function printTable(t)
	-- Color codes for formatting
	local colorReset = "\x1b[0m"
	local colorIndex = "\x1b[33m"  -- Yellow for index
	local colorObject = "\x1b[35m" -- Purple for object
	local colorType = "\x1b[36m"   -- Cyan for type

	-- Iterate over all key-value pairs in the table
	for key, value in pairs(t) do
		-- Print numeric indices with special formatting
		if type(key) == "number" then
			local valueType = type(value)
			-- Handle `nil` values
			if value == nil then
				print(colorIndex .. "[" .. key .. "]" .. colorReset .. " = " .. colorObject .. "nil" .. colorReset .. " (" .. colorType .. "nil" .. colorReset .. ")")
			else
				print(colorIndex .. "[" .. key .. "]" .. colorReset .. " = " .. colorObject .. tostring(value) .. colorReset .. " (" .. colorType .. valueType .. colorReset .. ")")
			end
		else
			-- Handle non-numeric keys
			local valueType = type(value)
			-- Handle `nil` values
			if value == nil then
				print(colorIndex .. tostring(key) .. colorReset .. " = " .. colorObject .. "nil" .. colorReset .. " (" .. colorType .. "nil" .. colorReset .. ")")
			else
				print(colorIndex .. tostring(key) .. colorReset .. " = " .. colorObject .. tostring(value) .. colorReset .. " (" .. colorType .. valueType .. colorReset .. ")")
			end
		end
	end
end

local ActiveFX = Actor.activeEffects(self)



local function reverseTable(t)
    local reversed = {}
    for i = #t, 1, -1 do
        table.insert(reversed, t[i])
    end
    return reversed
end

local mgef = core.magic.effects.records[core.magic.EFFECT_TYPE.FortifyHealth].icon
local magicIcon1 = ui.texture({path = mgef})
local imageTest = imageContent(magicIcon1)
imageTest.props.size = v2(40,40)

--somehow 1232 is the righthand side of the screen.
--mid_x position is 640?
--mid_y position is 360
local TESTlayout = {
	layer = 'HUD',
	template = I.MWUI.templates.box,
	props = {
	  position = v2(640, 360),
	  relativePosition = v2(0.0, 0),
	  anchor = v2(0, 1),
	},
	content = ui.content {
		{
			template = I.MWUI.templates.padding,
			content = ui.content {
			imageTest,
			},
		},
		--textContent("20", imageTest.props.size)
	}
}

local iconPath = core.magic.effects.records[core.magic.EFFECT_TYPE.Blind].icon
local magicIcon2 = ui.texture({path = iconPath})
local iconContent = imageContent(magicIcon2)
local countDown = textContent("10s", iconContent.props.size)
--d_message("iconContent: " .. tostring(iconContent))

--[[ for k,v in pairs(iconContent) do
	print(k, "type:", type(k), v, "typeV:", type(v))
	if type(v) == "table" then
		for key,val in pairs(v) do
		print("secondLevel_key:", key, "2ndVal:",val)
		end
	end
end
 ]]

local element3 = {}
local layout2 = {
	layer = 'Windows',
    type = ui.TYPE.Image, -- Extract the type
    props = iconContent.props,
    ------- RENAMED, SAVE THESE TO SOME NEW VARIABLE
    events = {
    mousePress = async:callback(function(coord, layout)
		layout.userData.doDrag = true
		layout.userData.lastMousePos = coord.position
		print("mouseclicked!")
		end),
    mouseRelease = async:callback(function(_, layout)
		layout.userData.doDrag = false
		print("mousereleased!")
		end),
    mouseMove = async:callback(function(coord, layout)
      if not layout.userData.doDrag then return end
      local props = layout.props
      props.position = props.position - (layout.userData.lastMousePos - coord.position)
	  element3:update()
      layout.userData.lastMousePos = coord.position
		end),
    },
    userData = {
      doDrag = false,
      lastMousePos = nil,
    },
	content = ui.content {
		countDown,
	}
}


--setup mousemove events?
local element2 = ui.create(TESTlayout)
element3 = ui.create(layout2)
d_message("Element: " .. tostring(element2))
d_message("ScreenSize!:")
d_message(ui.screenSize()) -- 1920 x 1080 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

--HUD and Windows sizes are 1280 x 720 ++++++++++++++++++++++++++++++++
--for i, layer in ipairs(ui.layers) do
--	print('layer', i, layer.name, layer.size)
--end
local iconPath2 = core.magic.effects.records[core.magic.EFFECT_TYPE.Telekinesis].icon

local function createImage(size, icon)
	local iconPaths = icon
	return {
		--name = "imageContent",
		type = ui.TYPE.Image,
		props = {
			resource = ui.texture({path = iconPaths or 'white'}),
			size = util.vector2(size or 40, size or 40),
			alpha = 1,
			inheritAlpha = false,
			visible = true,
			external = {
				grow = 3
			},
			--position = util.vector2(20,20)
		},
	}
end

local function createImageWithText(size, icon, text)
	local imageWidget = {
		type = ui.TYPE.Image,
		props = {
			resource = ui.texture({path = icon or 'white'}),
			size = util.vector2(size or 40, size or 40),
			alpha = 1,
			inheritAlpha = false,
			visible = true,
			external = { grow = 3 },
		},
	}

	local textWidget = {
		--template = I.MWUI.templates.textNormal,
		type = ui.TYPE.Text,
		props = {
			text = text or "",
			align = ui.ALIGNMENT.Center, -- Center the text under the image
			size = util.vector2(size or 40, 20), -- Text block size
			--textAlignH = ui.ALIGNMENT.End, -- does nothing??
			--textAlignV = ui.ALIGNMENT.End,
			inheritAlpha = false,
			--osition = v2(40,10),
			textColor = color.hex('FFFFFF'),
		},
	}

	-- Return a vertical container with the image on top and the text below
	return {
		type = ui.TYPE.Flex,
		props = {
			horizontal = false, -- Stack vertically
			--align = ui.ALIGNMENT.Center, -- Center the content
			size = v2(size*1,size*1.5),
			autoSize = false, -- Automatically size the container
			align = ui.ALIGNMENT.Start,
			arrange = ui.ALIGNMENT.Center,
		},
		content = ui.content {
			imageWidget,
			textWidget, -- The text widget is placed directly beneath the image
		},
	}
end

local myTemplate = {}
local borderV = v2(1,1) * 3

local customPadding = function(templates)
    templates.padding = {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                props = {
                    size = borderV,
                },
            },
            {
                external = { slot = true },
                props = {
                    position = borderV,
                    relativeSize = util.vector2(1, 1),
                },
            },
            {
                props = {
                    position = borderV,
                    relativePosition = util.vector2(1, 1),
                    size = borderV,
                },
            },
        }
    }
    templates.interval = {
        type = ui.TYPE.Widget,
        props = {
            size = borderV,
        },
    }
end

customPadding(myTemplate)

local function createPaddingContent(size,imagePath)
	local myIconWithText = createImageWithText(size or 20, imagePath,"60s")
	--local myImage = createImage(size or 20, imagePath)
	return {
				template = myTemplate.padding,
				content = ui.content {
					myIconWithText
				}
			}
end



local function createFlexHorz()
	return ui.content {
		{
			type = ui.TYPE.Flex,
			props = {
				size = v2(300,70+3*2),
				--relativePosition = v2(0,0), --doesn't do anything
				horizontal = true,
				align = ui.ALIGNMENT.Start,
				arrange = ui.ALIGNMENT.Start,
				autoSize = false,
				--position = v2(0,0),
				anchor = v2(0,0) -- anchor can be used to offset for next row
			},
			--content = ui.content {createImage(_,iconPath2), {external = {grow=2}, props = { name = 'someName'}},createImage(_,iconPath),{external = {grow=10}, props = { name = 'pad2'}},createImage(35,iconPath2),createPaddingContent(35,iconPath2),
			--createPaddingContent(30,iconPath2)
			content = ui.content {createPaddingContent(35,iconPath2), createPaddingContent(35,iconPath2), createPaddingContent(35,iconPath), createPaddingContent(35)
				,createPaddingContent(35), createPaddingContent(35,iconPath), createPaddingContent(35,iconPath),
			},
		}
	}
end

local function createLayoutBasic()
	local layoutMaker = {
		layer = 'Windows',
		name = 'NameChecker',
		template = I.MWUI.templates.boxTransparent,
		props = {
			relativePosition = v2(0.5, 0.5),
			anchor = v2(0, 0),
			alpha = 0.2,
			position = v2(0,0)
		},
		content = createFlexHorz(),
	}
	return layoutMaker
end

local element4 = {}
local dynElement = createLayoutBasic()
dynElement.userData = {
	doDrag = false,
	lastMousePos = nil,
  }

dynElement.events = {
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
	  element4:update()
      layout.userData.lastMousePos = coord.position
		end),
    }

element4 = ui.create(dynElement)

local iconsTest = {}
iconsTest[1] = core.magic.effects.records[core.magic.EFFECT_TYPE.BoundBattleAxe]
iconsTest[2] = core.magic.effects.records[core.magic.EFFECT_TYPE.Chameleon]
iconsTest[3] = core.magic.effects.records[core.magic.EFFECT_TYPE.FortifyHealth]
local iconsTest2 = parts.clone(iconsTest)

iconsTest2[3], iconsTest2[4] = iconsTest[2], core.magic.effects.records[core.magic.EFFECT_TYPE.Telekinesis]
local externalLayout = parts.ui.createLayoutBasic(iconsTest,_,v2(0.1,0.1),24)
local tempLay = parts.ui.createFlexRow(iconsTest,v2(0,-0.55),24)
externalLayout.content:add(tempLay)
local tempLay2 = parts.ui.createFlexRow(iconsTest2,v2(0,-1.1),24)
externalLayout.content:add(tempLay2)
print("name: " .. (externalLayout.content[1].name or ""))
--externalLayout.content['BuffRow']

local elementExtern = {}

--[[ for k, v in pairs(externalLayout.content['BuffRow']) do
	print("key", k, "value:", v)
	if type(v) == 'table' then
		print("      Table: " .. tostring(k))
		for key, val in pairs(v) do
			print("           ",key,val)
		end
	end
end
 ]]

--the following works!!!
externalLayout.content[1].content['padded_chameleon'].content['BuffFlexContainer_chameleon'].content[1].props.alpha = 0.5
elementExtern = ui.create(externalLayout)

--The following either {} or nil erases the content. even without an update to elementExtern
--externalLayout.content[3] = {}
--elementExtern:update()

--[[ local test2 = createLayoutBasic()
test2.content[1] = createImage(50)
test2.props.relativePosition = v2(0.25, 0.50)
test2.content[1].props.resource = ui.texture { path = 'black' } --you can modify on the fly. 
test2.props.alpha = 0.2
print(test2.content[1].props.alpha)
local rando = ui.create(test2) --This works! 
rando:destroy()
test2 = {} ]]

--[[ --This is a wrapper function that modifies createLayoutBasic(), it works as well. 
local function createModifiedLayout(x,y, add)
    local layout = createLayoutBasic()
    layout.content[1] = createImage(50)
    layout.props.relativePosition = v2(x or 0.25, y or 0.25)
	layout.content[1].props.resource = ui.texture { path = core.magic.effects.records[core.magic.EFFECT_TYPE.Corprus].icon }
	if add then
		layout.content:add(createImage(25, core.magic.effects.records[core.magic.EFFECT_TYPE.Telekinesis].icon))
	end
    return layout
end

local element5 = ui.create(createModifiedLayout(0.1,0.1))
local element7 = ui.create(createModifiedLayout(0.75,0.75,true)) ]]

-- Padding template settings
--[[ local paddingTemplate = I.MWUI.templates.padding
for key, value in pairs(paddingTemplate) do
    print("Key:", key, "--- Val:", value)
end

for i=1,3 do
	for key, value in pairs(paddingTemplate.content[i]) do
		print("Layout " .. i, "Key:", key, "--- Value:", value)
		if type(value) == "table" then
			for nextKey, value2 in pairs(paddingTemplate.content[i][key]) do
				print("\t" .. nextKey, "--- Value:", value2)
				if type(value2) == "table" then
					for nextKey2, value3 in pairs(paddingTemplate.content[i][key][nextKey]) do
						print("\t" .. nextKey2," --- Value:" .. value3)
					end
				end
			end
		end
	end
end ]]

local function updateUI_Element()
    if not element3 then return end

    -- Update alpha value based on fade direction
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
	--print("Alpha:",alpha,"time:", calendar.formatGameTime('%H:%M:%S'))
    -- Update the UI element's alpha
    iconContent.props.alpha = alpha -- updates the UI element's alpha value
	local keyTest = 'fortifyhealth'
	local keyTest2 = 'chameleon'
	--Need a way to pass a key into the function then into each key field
	externalLayout.content[1].content['padded_'.. keyTest].content['BuffFlexContainer_'.. keyTest].content[1].props.alpha = alpha
	externalLayout.content[1].content['padded_'.. keyTest].content['BuffFlexContainer_'.. keyTest].content[2].props.text = tostring(alpha) .. 's'
	countDown.props.text = tostring(alpha) .. 's'
	externalLayout.content[3].content['padded_'.. keyTest2].content['BuffFlexContainer_'.. keyTest2].content[1].props.alpha = alpha
	externalLayout.content[3].content['padded_'.. keyTest2].content['BuffFlexContainer_'.. keyTest2].content[2].props.text = tostring(alpha) .. 's'
    element3:update()
	elementExtern:update()
end

local timer = nil
local function startUpdating()
	--imageTest = imageContent(magicIcon2)
    timer = time.runRepeatedly(updateUI_Element, 5 * time.second, { type = time.GameTime }) --5 is a slow pulse, 2 is a quick pulse. Perhaps increase speed to 2, under 5s duration remaining. 
end

local function stopUpdating()
    if timer then
        timer() -- Makes the timer stop
        timer = nil
        alpha = 1 -- Reset alpha to zero opacity when stopping
		--imageTest = imageContent()
    end
end

local spellTable = parts.getActiveSpells(Actor.activeSpells(self))
--print("SPELLTABLE-------------", spellTable)
local debugOn = false
--local newFuncTab = parts.getActiveFxFilter(spellTable)
local myBuffs = parts.getBuffs(spellTable)
local mydeBuffs = parts.getdeBuffs(spellTable)
print('-------------------------SPELLTABLE------------------------------------')
traverseTable(spellTable)
print('-------------------------MY BUFFS--------------------------------------')
traverseTable(myBuffs)
print('-------------------------DEBUFFS---------------------------------------')
traverseTable(mydeBuffs)

local i_spellTable = parts.getActiveSpells(Actor.activeSpells(self))
print('-----------------------New Spell Table-------------------------------')
traverseTable(i_spellTable)

local allBuffsLayout = parts.ui.createLayoutBasic2(myBuffs,_,v2(0.55,0),24)
local buffElement = {}
buffElement = ui.create(allBuffsLayout)
allBuffsLayout.content:add(parts.ui.createFlexRow2(mydeBuffs,v2(0,-0.55),24))


local function onKeyPress(key)
	local tempKeyBind = input.KEY.G
	if (not playerSettings:get("modEnable")) or (key.code ~= tempKeyBind) or core.isWorldPaused()  then return end
	if tempKeyBind == input.KEY.G then
		if element3 then
			element3:destroy()
			element3 = nil
			stopUpdating()
		else
			element3 = ui.create(layout2)
			startUpdating()
		end
	end
	local ActiveFX = Actor.activeEffects(self)
	local ActiveSpells = Actor.activeEffects(self)
	local mySpells = Actor.activeSpells(self)
	local buffTable = parts.getActiveBuffs(mySpells, true)
	debugOn = false
	--debugger for buffTable
	if debugOn then
		for key,item in pairs(buffTable) do
			print("KEY[" .. key .. "]", item.spellId, item.effectName, item.magnitudeThisFrame)
			for key2, item2 in pairs(item) do
				print("		|----" .. key2 .. " = ".. item2)
			end
		end
	end

	--debug = true
	if debugOn then
		spellTable = parts.getIndexedSpellEffects(Actor.activeSpells(self))
		for i, data in pairs(spellTable) do
			print("Index:" .. i, "Spell:" .. data.spellId, data.params.effects[1].durationLeft)
		end
	end

	debugOn = true
	if debugOn then
		for _, data in pairs(myBuffs) do
			for _, effect in pairs(data) do
				--local widget = common.ui.createPaddedContent(size, effect.icon, effect.duration)
				print(effect.id, tostring(effect.icon), effect.name, effect.duration, effect.key)
			end
		end
	end

	--Do some stuff
--[[ 	print("ACTIVE FX:")
	printTable(ActiveFX)
	print("\n\nACTIVE_SPELLS")
	printTable(ActiveSpells)
 ]]

--[[ 	for id, params in pairs(Actor.activeSpells(self)) do
		print('active spell '..tostring(id)..':')
		print('  name: '..tostring(params.name))
		print('  id: '..tostring(params.id))
		print('  item: '..tostring(params.item))
		print('  caster: '..tostring(params.caster))
		print('  effects: '..tostring(params.effects))
		print('  Icon Path: '..tostring(core.magic.effects.records[params.effects[1].id].icon)) -- another way to get the icon
		for _, effect in pairs(params.effects) do
			local mgef = core.magic.effects.records[effect.id]
 			
			--comment this block
			print('  -> effects['..tostring(effect)..']:')
			print('       id: '..tostring(effect.id))
			print('       name: '..tostring(effect.name))
			print('       affectedSkill: '..tostring(effect.affectedSkill))
			print('       affectedAttribute: '..tostring(effect.affectedAttribute))
			print('       magnitudeThisFrame: '..tostring(effect.magnitudeThisFrame))
			print('       minMagnitude: '..tostring(effect.minMagnitude))
			print('       maxMagnitude: '..tostring(effect.maxMagnitude))
			print('       duration: '..tostring(effect.duration)) 

			print('       durationLeft: '..tostring(effect.durationLeft))
			print('       Effect Icon: '..tostring(mgef.icon))
		end
	end
 ]]
--[[ 	-- Print all harmful effects, can use to determine buff or debuff
for _, effect in pairs(core.magic.effects.records) do
    if effect.harmful then
        print(effect.name)
    end
end ]]
	--local element = ui.create(layout)
	--element = ui.create(layout2) -- this prevents the ui element from being destroyed on 2nd key press
	--Hoever the element doesn't register on the screen if this isn't here... 

--[[ 	local mgef = core.magic.effects.records[core.magic.EFFECT_TYPE.FortifyHealth]
	print(tostring(core.magic.EFFECT_TYPE.Reflect))
	print('Reflect Icon: '..tostring(mgef.icon)) ]]

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
