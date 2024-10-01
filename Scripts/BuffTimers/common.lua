local async = require('openmw.async')
local aux_util = require('openmw_aux.util')
local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')
local core = require("openmw.core")
local I = require('openmw.interfaces')
local storage = require("openmw.storage")
local modInfo = require("Scripts.BuffTimers.modInfo")
local shader = require('Scripts.BuffTimers.radialSwipe')
local uiSettings = storage.playerSection("SettingsPlayer" .. modInfo.name .. "UI")

local templates = I.MWUI.templates
local v2 = util.vector2
local color = util.color
local borderV = v2(1,1) * 3
local magRecs = core.magic.effects.records
local mgFx = core.magic.EFFECT_TYPE
local Actor = types.Actor

local xRes = ui.screenSize().x
local yRes = ui.screenSize().y
local Aright = ui.ALIGNMENT.End
local Amid = ui.ALIGNMENT.Center
local Aleft = ui.ALIGNMENT.Start
local TOOLTIP = nil
local TOOLTIP_ID = nil
local fxKey = {}




local common = {
    const = {
      CHAR_ROTATE_SPEED = 0.3,
    },
    --need to store all debuff type effects
    debuffs = {
        [magRecs[mgFx.AbsorbAttribute].id] = true,
        [magRecs[mgFx.AbsorbFatigue].id] = true,
        [magRecs[mgFx.AbsorbHealth].id] = true,
        [magRecs[mgFx.AbsorbMagicka].id] = true,
        [magRecs[mgFx.AbsorbSkill].id] = true,
        [magRecs[mgFx.Blind].id] = true,
        [magRecs[mgFx.Burden].id] = true,
        [magRecs[mgFx.CalmCreature].id] = true,
        [magRecs[mgFx.CalmHumanoid].id] = true,
        [magRecs[mgFx.Charm].id] = true,
        [magRecs[mgFx.CommandCreature].id] = true,
        [magRecs[mgFx.CommandHumanoid].id] = true,
        [magRecs[mgFx.Corprus].id] = true,
        [magRecs[mgFx.DamageAttribute].id] = true,
        [magRecs[mgFx.DamageFatigue].id] = true,
        [magRecs[mgFx.DamageHealth].id] = true,
        [magRecs[mgFx.DamageMagicka].id] = true,
        [magRecs[mgFx.DamageSkill].id] = true,
        [magRecs[mgFx.DemoralizeCreature].id] = true,
        [magRecs[mgFx.DemoralizeHumanoid].id] = true,
        [magRecs[mgFx.DisintegrateArmor].id] = true,
        [magRecs[mgFx.DisintegrateWeapon].id] = true,
        [magRecs[mgFx.DrainAttribute].id] = true,
        [magRecs[mgFx.DrainFatigue].id] = true,
        [magRecs[mgFx.DrainHealth].id] = true,
        [magRecs[mgFx.DrainMagicka].id] = true,
        [magRecs[mgFx.DrainSkill].id] = true,
        [magRecs[mgFx.FireDamage].id] = true,
        [magRecs[mgFx.FrenzyCreature].id] = true,
        [magRecs[mgFx.FrenzyHumanoid].id] = true,
        [magRecs[mgFx.FrostDamage].id] = true,
        [magRecs[mgFx.Lock].id] = true,
        [magRecs[mgFx.Paralyze].id] = true,
        [magRecs[mgFx.Poison].id] = true,
        [magRecs[mgFx.ShockDamage].id] = true,
        [magRecs[mgFx.Silence].id] = true,
        [magRecs[mgFx.Soultrap].id] = true,
        [magRecs[mgFx.Sound].id] = true,
        [magRecs[mgFx.SpellAbsorption].id] = true,
        [magRecs[mgFx.StuntedMagicka].id] = true,
        [magRecs[mgFx.SunDamage].id] = true,
        [magRecs[mgFx.TurnUndead].id] = true,
        [magRecs[mgFx.Vampirism].id] = true,
        [magRecs[mgFx.WeaknessToBlightDisease].id] = true,
        [magRecs[mgFx.WeaknessToCommonDisease].id] = true,
        [magRecs[mgFx.WeaknessToCorprusDisease].id] = true,
        [magRecs[mgFx.WeaknessToFire].id] = true,
        [magRecs[mgFx.WeaknessToFrost].id] = true,
        [magRecs[mgFx.WeaknessToMagicka].id] = true,
        [magRecs[mgFx.WeaknessToNormalWeapons].id] = true,
        [magRecs[mgFx.WeaknessToPoison].id] = true,
        [magRecs[mgFx.WeaknessToShock].id] = true,
    },
    buffs = {
        [magRecs[mgFx.AlmsiviIntervention].id] = true,
        [magRecs[mgFx.BoundBattleAxe].id] = true,
        [magRecs[mgFx.BoundBoots].id] = true,
        [magRecs[mgFx.BoundCuirass].id] = true,
        [magRecs[mgFx.BoundDagger].id] = true,
        [magRecs[mgFx.BoundGloves].id] = true,
        [magRecs[mgFx.BoundHelm].id] = true,
        [magRecs[mgFx.BoundLongbow].id] = true,
        [magRecs[mgFx.BoundLongsword].id] = true,
        [magRecs[mgFx.BoundMace].id] = true,
        [magRecs[mgFx.BoundShield].id] = true,
        [magRecs[mgFx.BoundSpear].id] = true,
        [magRecs[mgFx.Chameleon].id] = true,
        [magRecs[mgFx.CureBlightDisease].id] = true,
        [magRecs[mgFx.CureCommonDisease].id] = true,
        [magRecs[mgFx.CureCorprusDisease].id] = true,
        [magRecs[mgFx.CureParalyzation].id] = true,
        [magRecs[mgFx.CurePoison].id] = true,
        [magRecs[mgFx.DetectAnimal].id] = true,
        [magRecs[mgFx.DetectEnchantment].id] = true,
        [magRecs[mgFx.DetectKey].id] = true,
        [magRecs[mgFx.Dispel].id] = true,
        [magRecs[mgFx.DivineIntervention].id] = true,
        [magRecs[mgFx.ExtraSpell].id] = true,
        [magRecs[mgFx.Feather].id] = true,
        [magRecs[mgFx.FireShield].id] = true,
        [magRecs[mgFx.FortifyAttack].id] = true,
        [magRecs[mgFx.FortifyAttribute].id] = true,
        [magRecs[mgFx.FortifyFatigue].id] = true,
        [magRecs[mgFx.FortifyHealth].id] = true,
        [magRecs[mgFx.FortifyMagicka].id] = true,
        [magRecs[mgFx.FortifyMaximumMagicka].id] = true,
        [magRecs[mgFx.FortifySkill].id] = true,
        [magRecs[mgFx.FrostShield].id] = true,
        [magRecs[mgFx.Invisibility].id] = true,
        [magRecs[mgFx.Jump].id] = true,
        [magRecs[mgFx.Levitate].id] = true,
        [magRecs[mgFx.Light].id] = true,
        [magRecs[mgFx.LightningShield].id] = true,
        [magRecs[mgFx.Mark].id] = true,
        [magRecs[mgFx.NightEye].id] = true,
        [magRecs[mgFx.Open].id] = true,
        [magRecs[mgFx.RallyCreature].id] = true,
        [magRecs[mgFx.RallyHumanoid].id] = true,
        [magRecs[mgFx.Recall].id] = true,
        [magRecs[mgFx.Reflect].id] = true,
        [magRecs[mgFx.RemoveCurse].id] = true,
        [magRecs[mgFx.ResistBlightDisease].id] = true,
        [magRecs[mgFx.ResistCommonDisease].id] = true,
        [magRecs[mgFx.ResistCorprusDisease].id] = true,
        [magRecs[mgFx.ResistFire].id] = true,
        [magRecs[mgFx.ResistFrost].id] = true,
        [magRecs[mgFx.ResistMagicka].id] = true,
        [magRecs[mgFx.ResistNormalWeapons].id] = true,
        [magRecs[mgFx.ResistParalysis].id] = true,
        [magRecs[mgFx.ResistPoison].id] = true,
        [magRecs[mgFx.ResistShock].id] = true,
        [magRecs[mgFx.RestoreAttribute].id] = true,
        [magRecs[mgFx.RestoreFatigue].id] = true,
        [magRecs[mgFx.RestoreHealth].id] = true,
        [magRecs[mgFx.RestoreMagicka].id] = true,
        [magRecs[mgFx.RestoreSkill].id] = true,
        [magRecs[mgFx.Sanctuary].id] = true,
        [magRecs[mgFx.Shield].id] = true,
        [magRecs[mgFx.SlowFall].id] = true,
        [magRecs[mgFx.SummonAncestralGhost].id] = true,
        [magRecs[mgFx.SummonBear].id] = true,
        [magRecs[mgFx.SummonBonelord].id] = true,
        [magRecs[mgFx.SummonBonewalker].id] = true,
        [magRecs[mgFx.SummonBonewolf].id] = true,
        [magRecs[mgFx.SummonCenturionSphere].id] = true,
        [magRecs[mgFx.SummonClannfear].id] = true,
        --[mRs[mgFx.SummonCreature04].id] = true, -- for some reason these equate to nil
        --[mRs[mgFx.SummonCreature05].id] = true,
        [magRecs[mgFx.SummonDaedroth].id] = true,
        [magRecs[mgFx.SummonDremora].id] = true,
        [magRecs[mgFx.SummonFabricant].id] = true,
        [magRecs[mgFx.SummonFlameAtronach].id] = true,
        [magRecs[mgFx.SummonFrostAtronach].id] = true,
        [magRecs[mgFx.SummonGoldenSaint].id] = true,
        [magRecs[mgFx.SummonGreaterBonewalker].id] = true,
        [magRecs[mgFx.SummonHunger].id] = true,
        [magRecs[mgFx.SummonScamp].id] = true,
        [magRecs[mgFx.SummonSkeletalMinion].id] = true,
        [magRecs[mgFx.SummonStormAtronach].id] = true,
        [magRecs[mgFx.SummonWingedTwilight].id] = true,
        [magRecs[mgFx.SummonWolf].id] = true,
        [magRecs[mgFx.SwiftSwim].id] = true,
        [magRecs[mgFx.Telekinesis].id] = true,
        [magRecs[mgFx.WaterBreathing].id] = true,
        [magRecs[mgFx.WaterWalking].id] = true,
    },
    skillAttributeFx = {
        [magRecs[mgFx.DamageAttribute].id] = true,
        [magRecs[mgFx.DamageSkill].id] = true,
        [magRecs[mgFx.DrainAttribute].id] = true,
        [magRecs[mgFx.DrainSkill].id] = true,
        [magRecs[mgFx.FortifySkill].id] = true,
        [magRecs[mgFx.FortifyAttribute].id] = true,
        [magRecs[mgFx.RestoreSkill].id] = true,
        [magRecs[mgFx.RestoreAttribute].id] = true,
    },
    attributeAlias = {
        ['agility'] = 'AGIL',
        ['endurance'] = 'ENDR',
        ['intelligence'] = 'INT',
        ['luck'] = 'LUCK',
        ['personality'] = 'CHAR',
        ['speed'] = 'SPD',
        ['strength'] = 'STR',
        ['willpower'] = 'WPWR',
    },
    skillAlias = {
        ['acrobatics']= 'ACRB',
        ['alchemy']= 'ALCH',
        ['alteration']= 'ALTR',
        ['armorer']= 'RPAIR',
        ['athletics']= 'ATHL',
        ['axe']= 'AXE',
        ['block']= 'BLCK',
        ['bluntWeapon']= 'BLNT',
        ['conjuration']= 'CONJ',
        ['destruction']= 'DEST',
        ['enchant']= 'ENCH',
        ['hand-to-hand']= 'FIST',
        ['heavyarmor']= 'ARMH',
        ['illusion']= 'ILLU',
        ['lightarmor']= 'ARML',
        ['longblade']= 'LBLD',
        ['marksman']= 'BOW',
        ['mediumarmor']= 'ARMM',
        ['mercantile']= 'MERC',
        ['mysticism']= 'MYST',
        ['restoration']= 'REST',
        ['security']= 'SEC',
        ['short Blade']= 'SBLD',
        ['sneak']= 'SNK',
        ['spear']= 'SPR',
        ['speechcraft']= 'SPCH',
        ['unarmored']= 'UNAR',
    },
    ui = {},
}

--simple table copy function
common.clone = function(org) 
    return {table.unpack(org)}
end

common.round = function(value)
    return value >= 0 and math.floor(value + 0.5) or math.ceil(value - 0.5)
end

common.checkGetSize = function(args)
    if not args or type(args) ~= 'table' then return end
    local rtsize
    --print(args)
    if args.size then
        if args.size.x and args.size.y then
            -- Use both x and y values
            rtsize = v2(args.size.x, args.size.y)
        else
            -- If size is a single value or has no y, use that value
            rtsize = v2(args.size, args.size)
        end
    else
        -- Default size if args.size is nil
        rtsize = v2(24,10)
    end
    return rtsize
end

common.ui.createImage = function(size, icon)
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

common.ui.createImageWithText = function(size, icon, text, effectname, key)
  local imageWidget = {
        name = key and 'image_' .. key or 'image',
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
        name = key and 'textWidget_' .. key or 'textWidget',
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
        name = key and 'BuffFlexContainer_' .. key or 'BuffFlexContainer',
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

common.ui.customPadding = function(templates)
  templates.padding = {
    type = ui.TYPE.Container,
    content = ui.content {
        {
            props = {
                size = borderV,
                color = color.hex('FFFFFF'),
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

--Need to add dynamic names as keys, such as the name of the spell effect
common.ui.createPaddedContent = function(size, imagePath, text, effectname, key)
  local IconWithText = common.ui.createImageWithText(size or 20, imagePath, text, effectname, key)
  local myTemplate = {}
  common.ui.customPadding(myTemplate)
	--local myImage = createImage(size or 20, imagePath)
	return {
            name = key and 'padded_' .. key or 'padded',
            template = myTemplate.padding,
            content = ui.content {
                IconWithText
            }
    }
end


--@param offset util.vector2(#,#) The second parameter (default: false/nil).
common.ui.createFlexRow = function(spellEffects, offset, size)
    local flexContent = {}
    -- Iterate through spell effects and add each one to the flex content
    for _, effect in ipairs(spellEffects) do
        --local widget = common.ui.createPaddedContent(size, effect.icon, effect.duration)
        local widget = common.ui.createPaddedContent(size, effect.icon, "20s", effect.id)
        table.insert(flexContent, widget)
    end
    -- Return the flex container
    return {
            name = offset and 'BuffRow_' .. tostring(offset.y) or 'BuffRow', --Will this work?
            type = ui.TYPE.Flex,
            props = {
                size = v2((size +10)*10, (size +10)*2), -- Adjust size as needed
                horizontal = true, -- Layout the icons horizontally
                align = ui.ALIGNMENT.Start, -- Align the icons at the start
                arrange = ui.ALIGNMENT.Start, -- Center the text below icons
                anchor = offset or v2(0,0),
                autoSize = false
            },
            content = ui.content(flexContent),
        }
end

--@param offset util.vector2(#,#) The second parameter (default: false/nil).
common.ui.createFlexRow2 = function(myBuffs, offset, size)
    local flexContent = {}
    -- Iterate through spell effects and add each one to the flex content
    for _, data in pairs(myBuffs) do
        for _, effect in pairs(data) do
			--local widget = common.ui.createPaddedContent(size, effect.icon, effect.duration)
			if effect.duration and effect.durationLeft > 0 then
                local widget = common.ui.createPaddedContent(size, effect.icon, effect.duration and common.formatDuration(effect.durationLeft) or '', effect.name, effect.key)
                table.insert(flexContent, widget)
            end
		end
    end
    -- Return the flex container
    return {
            name = offset and 'BuffRow_' .. tostring(offset.y) or 'BuffRow', --Will this work?
            type = ui.TYPE.Flex,
            props = {
                size = v2((size +10)*10, (size +10)*2), -- Adjust size as needed
                horizontal = true, -- Layout the icons horizontally
                align = ui.ALIGNMENT.Start, -- Align the icons at the start
                arrange = ui.ALIGNMENT.Start, -- Center the text below icons
                anchor = offset or v2(0,0),
                autoSize = false
            },
            content = ui.content(flexContent),
        }
end

--need to revise spellEffects to myBuffs
common.ui.createLayoutBasic = function(spellEffects, offset, pos, size)
	if offset then
        if type(offset) == 'number' or type(offset) == 'string' then
            error('offset must be a util.vector(x,y), where x/y are numbers')
        end
    end
    local layoutMaker = {
		layer = 'Windows',
		template = I.MWUI.templates.boxTransparent,
        name = 'MainBuffBoundary',
		props = {
            relativePosition = pos or v2(0.5, 0.5),
			anchor = v2(0, 0),
			alpha = 0.2,
			position = v2(0,0)
		},
		content = ui.content{common.ui.createFlexRow(spellEffects, offset, size),}
	}
	return layoutMaker
end


common.ui.createLayoutBasic2 = function(myBuffs, offset, pos, size)
	if offset then
        if type(offset) == 'number' or type(offset) == 'string' then
            error('offset must be a util.vector(x,y), where x/y are numbers')
        end
    end
    local layoutMaker = {
		layer = 'Windows',
		template = I.MWUI.templates.boxTransparent,
        name = 'MainBuffBoundary',
		props = {
            relativePosition = pos or v2(0.5, 0.5),
			anchor = v2(0, 0),
			alpha = 0.2,
			position = v2(0,0)
		},
		content = ui.content{common.ui.createFlexRow2(myBuffs, offset, size),},
        userData = {
            doDrag = false,
            lastMousePos = nil
        },
	}
	return layoutMaker
end

-- @param actor (userData) of the form actor.Types.activeSpells(self)
-- @param debuff (boolean) The second parameter (default: false/nil).
common.getActiveBuffs = function(actor, debuff)
    local activeBuffsTable = {}
    if not actor then return end
    -- Iterate over active spells
    for spellId, spellParams in pairs(actor) do
        local spellName = spellParams.name
        -- Iterate over effects within the spell
        for _, effect in ipairs(spellParams.effects) do
            -- Create a unique key based on spellName and effectId
            if common.buffs[effect.id] and not debuff then
                local uniqueKey = spellId.. "_" .. tostring(effect.id)
                -- Insert the relevant data into the table with the unique key
                activeBuffsTable[uniqueKey] = {
                    spellId = spellParams.id,
                    spellName = spellName,
                    effectId = effect.id,
                    effectName = effect.name,
                    magnitudeThisFrame = effect.magnitudeThisFrame,
                    duration = effect.duration,
                    durationLeft = effect.durationLeft,
                }
            elseif debuff then
                if common.debuffs[effect.id] then
                    local uniqueKey = spellName .. "_" .. tostring(effect.id)
                    -- Insert the relevant data into the table with the unique key
                    activeBuffsTable[uniqueKey] = {
                        spellId = spellParams.id,
                        spellName = spellName,
                        effectId = effect.id,
                        effectName = effect.name,
                        magnitudeThisFrame = effect.magnitudeThisFrame,
                        duration = effect.duration,
                        durationLeft = effect.durationLeft,
                    }
                end
            end
        end
    end

    -- Return the structured table
    return activeBuffsTable
end

common.getIndexedSpellEffects = function(actorSpells, filterFn)
    if not actorSpells then return end
    local indexedSpells = {}

    -- Use index as the key and store spellId and spellParams (which are userdata) in a table
    local index = 1
    for spellId, spellParams in pairs(actorSpells) do
        indexedSpells[index] = {
            spellId = spellId,  -- userdata
            params = spellParams  -- userdata
        }
        index = index + 1
    end

    return indexedSpells
end

--MAIN FUNCTION TO GET SPELLS AND KEY THEM!!!
common.getActiveSpells = function(actorSpells)
    if not actorSpells then return end
    local uniqueSpells = {}

    -- Use index as the key and store spellId and spellParams (which are userdata) in a table
    for spellId, spellParams in pairs(actorSpells) do
        uniqueSpells[spellParams.activeSpellId] = {
            spellId = spellId,  -- userdata
            params = spellParams  -- userdata
        }
    end
    return uniqueSpells
end

--This is just a reference delete later
--[[ common.getActiveFxFilter = function(indexedSpellTable, debuff)
    local FxTable = {}
    if not indexedSpellTable then return end
    -- Iterate over active spells
    for index, data in pairs(indexedSpellTable) do
        local key = index..'.'.. data.spellId
        -- Iterate over effects within the spell
        for i, effect in pairs(data.params.effects) do
            -- Create a unique key based on spellName and effectId
            if common.buffs[effect.id] and not debuff then
                local uniqueKey = key .. '_'.. i ..'.'..tostring(effect.id)
                -- Insert the relevant data into the table with the unique key
                FxTable[uniqueKey] = {
                    effectId = effect.id,
                    effectName = effect.name,
                    magnitudeThisFrame = effect.magnitudeThisFrame,
                    duration = effect.duration,
                    durationLeft = effect.durationLeft,
                }
            elseif debuff then
                if common.debuffs[effect.id] then
                    local uniqueKey = key .. '_'.. i ..'.'..tostring(effect.id)
                    -- Insert the relevant data into the table with the unique key
                    FxTable[uniqueKey] = {
                        effectId = effect.id,
                        effectName = effect.name,
                        magnitudeThisFrame = effect.magnitudeThisFrame,
                        duration = effect.duration,
                        durationLeft = effect.durationLeft,
                    }
                end
            end
        end
    end

    -- Return the structured table
    return FxTable
end
 ]]

common.getBuffs = function(uniqueSpells)
    local buffs = {}
    if not uniqueSpells then return end
    -- Iterate over active spells
    for key, data in pairs(uniqueSpells) do
        local effects = data.params.effects
        buffs[key] = {}
        for _, effect in pairs(effects) do
            --print("insideBuffsfunc:", effect.name, common.buffs[effect.id])
            --May be easier to just assign the unique key to the buffs table keys
            if common.buffs[effect.id] then
                buffs[key][effect.index] = {
                    key =  key..'_'..data.spellId..'_'..effect.index..'_'..effect.id,
                    id = effect.id,
                    name = effect.name,
                    magnitudeThisFrame = effect.magnitudeThisFrame,
                    duration = effect.duration,
                    durationLeft = effect.durationLeft,
                    icon = magRecs[effect.id].icon,
                    index = effect.index
                }
            end
        end
        -- Check if the current index table is empty and remove it
        if not next(buffs[key]) then
            buffs[key] = nil
        end
    end
    -- Return the structured table
    return buffs
end

common.getdeBuffs = function(uniqueSpells)
    local debuffs = {}
    if not uniqueSpells then return end
    -- Iterate over active spells
    for key, data in pairs(uniqueSpells) do
        local effects = data.params.effects
        debuffs[key] = {}
        for _, effect in pairs(effects) do
            --print("insideBuffsfunc:", effect.name, common.buffs[effect.id])
            if common.debuffs[effect.id] then
                debuffs[key][effect.index] = {
                    key =  key..'_'..data.spellId..'_'..effect.index..'_'..effect.id,
                    id = effect.id,
                    name = effect.name,
                    magnitudeThisFrame = effect.magnitudeThisFrame,
                    duration = effect.duration,
                    durationLeft = effect.durationLeft,
                    icon = magRecs[effect.id].icon,
                    index = effect.index
                }
            end
        end
        -- Check if the current index table is empty and remove it
        if not next(debuffs[key]) then
            debuffs[key] = nil
        end
    end

    -- Return the structured table
    return debuffs
end

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Means to convernt buff timer from hour to min to s, to s.ms
common.formatDuration = function(timeRemaining)
    if not timeRemaining or type(timeRemaining) ~= 'number' then return end
    local time = timeRemaining
    if time > 3600 then
        time = util.round(time/3600)
        time = time .. 'h'
    elseif time > 60 then
        time = util.round(time/60)
        time = time .. 'm'
    elseif time > 10 then
        time = util.round(time)
        time = time .. 's'
    else
        time = util.round(time * 10) / 10  -- Round to one decimal place
        time = string.format("%.1fs", time) -- Format to ensure one decimal place
    end

    return time
end

-- New stuff 9-22-2024
common.createFxTable = function(spellList)
    local fxTable = {}
    fxKey = {}  -- clear out stale old keys. 
  -- Iterate over active spells
      for _, spells in pairs(spellList) do
        local activeSpellId = spells.activeSpellId
        for _, effect in pairs(spells.effects) do
          -- Create a copy of the effect and add activeSpellId
          local effectWithId = {
            activeSpellId = activeSpellId,
            id = effect.id,
            name = effect.name,
            index = effect.index,
            minMagnitude = effect.minMagnitude,
            maxMagnitude = effect.maxMagnitude,
            duration = effect.duration,
            durationLeft = effect.durationLeft,
            magnitudeThisFrame = effect.magnitudeThisFrame,
            affectedSkill = effect.affectedSkill,
            affectedAttribute = effect.affectedAttribute,
            icon = magRecs[effect.id].icon
          }
          local uniqueKey = activeSpellId..'/'..effect.index..'/'..effect.id
          fxKey[uniqueKey] = true -- Add the unique Effecet as a key to the fxKey table
          table.insert(fxTable, effectWithId)
        end
      end
    return fxTable
end

-- New stuff 9-24-2024
common.ui.makeTextContent = function(inputText, args)
    args = args or {}  -- Initialize args to an empty table if nil
    --local sz = (args and args.size) and args.size or 24
    local sz = common.checkGetSize(args)
    local textWidget = {
		name = inputText and 'textWidget/'..inputText or (args and args.id) and 'textWidget/'..'blank/'..args.id,
		type = ui.TYPE.Text,
		props = {
			text = inputText or "",
			size = sz, -- Text block size
			textAlignH = args.h or Aleft, -- does nothing??
			textAlignV = args.v or Aright,
			inheritAlpha = false,
			--position = v2(40,10),
			textColor = (args and args.colorIn) and color.hex(args.colorIn) or color.hex('FFFFFF'),
			textSize = args.tSize or 10,
			autoSize = args.aSize or false,
            multiline = true,   -- Enable multiline
            wordWrap = true,    -- Enable word wrap
		},
	}
	return textWidget
end

common.ui.makeIconContent = function(iconPath, args)
    args = args or {}  -- Initialize args to an empty table if nil
    local sz = (args and args.size) and args.size or 24
    local iconWidget = {
        name = 'iconWidget/'..iconPath,
        type = ui.TYPE.Image,
		props = {
			resource = ui.texture({path = iconPath or 'white'}), -- No issue with the icon.. why isn't this dispalying. 
			size = v2(sz, sz),
			alpha = 1,
			inheritAlpha = false,
			visible = true,
		},
        content = ui.content({}),
	}
	return iconWidget
end

--This will be fed either Fxtable or a table of icons and text widgets
common.ui.rootFlex = function(content, args, id)
    args = args or {}  -- Initialize args to an empty table if nil
--[[     local size
    if args.size then
        if args.size.x and args.size.y then
            -- Use both x and y values
            size = v2(args.size.x, args.size.y * 1.5)
        else
            -- If size is a single value or has no y, use that value
            size = v2(args.size, args.size * 1.5)
        end
    else
        -- Default size if args.size is nil
        size = v2(30, 60)
    end ]]

    local rootFlex = {
        name = id and 'rootFlex/'..id or 'rootFlex/'..content,
        type = ui.TYPE.Flex,
		props = {
			horizontal = false, -- Stack vertically
			--align = ui.ALIGNMENT.Center, -- Center the content
			size = args.size and args.size or v2(30,60),
			autoSize = args.aSize or false, -- Automatically size the container
			align = Aleft,
			arrange = Amid,
		},
        userdata = {
            mouseOver = false,
            lastMousePos = nil
        },
        content = ui.content(content),
        events = {
            mouseMove = async:callback(function(e,layout)
                --print("Mouse has moved onto icon", e.position, "Printing offset...",e.offset)
                --print(layout.userdata.fx)
                if TOOLTIP then -- handle updating the tooltip. 
                    TOOLTIP.layout.props.position = e.position
					TOOLTIP:update()
					layout.userdata.lastMousePos = e.position
                elseif layout.userdata.fx then
                    TOOLTIP = common.ui.toolTipBox(layout.userdata.fx, e.position) -- handle creating the tooltip if it does not exist
                    -- need to handle offsetting tool tip if the user sets the buffs to align on end, need to set anchor(-1,0)
                end
            end),
			focusLoss = async:callback(function(layout)
				common.destroyTooltip()
			end),
        },
	}
	return rootFlex

end

  -- content which needs to be dynamically updated and fed to flex box
common.createBuffsContent = function(returnType)
    --if not actor then return end
    local spellList = Actor.activeSpells(self)
    --added on PC:
    local myTemplate = {}
    common.ui.customPadding(myTemplate)

    -- create flat table with indexed effects
    local fxTable = common.createFxTable(spellList)

    -- do some processing on fxTable to create widgets or elements
    local table_elements = {}
    local table_layouts = {}
    local paddedTable_layouts = {}

    for _, fx in ipairs(fxTable) do
        --some code to generare layouts
        local layout = {
            name = fx.activeSpellId..'/'..fx.index..'/'..fx.id,
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
                resource = ui.texture({path = fx.icon or 'white'})
            },
            userdata = {
            --some userdata
                effectInfo = fx,
                Duration = fx.duration,
                DurationLeft = fx.durationLeft
            },
            events = {
            -- Some events perhaps mouseover Tooltip
            },
        }

        local paddedIcons = {
            name = 'padded/'..fx.activeSpellId..'/'..fx.index..'/'..fx.id,
            template = myTemplate.padding,
            content = ui.content {layout}
        }

        local element = ui.create(layout)
        table.insert(table_layouts, layout)
        table.insert(paddedTable_layouts, paddedIcons)
        table.insert(table_elements, element)
    end

    -- Return the structured table with effects grouped by unique keys
    if not returnType or returnType == 'content' then
        return table_layouts
    elseif returnType == 'pad' then
        return paddedTable_layouts
    elseif returnType == 'element' then
        return table_elements
    end

    -- Need to create a table of references to the layout itself
end

-- New stuff 9-22-2024
common.ui.createFlex = function(inputContent, direction)
    local dir = true
    if direction ~= nil then
        dir = direction
    end
    local flexLay = {
        name = 'FLEXBUFFs',
        type = ui.TYPE.Flex,
        props = {
            size = v2((24 +10)*12, (24 +10)*2), -- Adjust size as needed
            horizontal = dir, -- Layout the icons horizontally
            align = ui.ALIGNMENT.Start, -- Align the icons at the start
            arrange = ui.ALIGNMENT.Start, -- Center the text below icons
            anchor = v2(0,0),
            autoSize = false,
            inheritAlpha = false
        },
        content = ui.content(inputContent),
    }
    return flexLay
end

-- New stuff 9-22-2024
common.ui.boxForFlex = function(inputContent, pos)
    local rootWidget = {
		layer = 'Windows',
		template = I.MWUI.templates.boxTransparent,
        name = 'MainBuffBoundary',
		props = {
            relativePosition = pos or v2(0.5, 0.5),
			anchor = v2(0, 0),
			alpha = 0.2,
			position = v2(0,0)
		},
		content = ui.content{inputContent},
        userData = {
            doDrag = false,
            lastMousePos = nil
        },
	}
	return rootWidget
end

common.calculateRootFlexSize = function(children)
    local maxWidth = 0
    local totalHeight = 0
    --local padding = 0  -- Example padding value

    for _, child in ipairs(children) do
        local childWidth = child.props.size.x
        local childHeight = child.props.size.y
        
        -- Update maxWidth and totalHeight
        maxWidth = math.max(maxWidth, childWidth)
        totalHeight = totalHeight + childHeight -- Add padding between items
    end

    -- Add additional padding for the container
    totalHeight = totalHeight

    return v2(maxWidth, totalHeight)  -- Return the calculated size as a vector
end

-- New stuff 9-22-2024
common.ui.createElementContainer = function(inputContent, pos)
    local element = ui.create {
		layer = 'Windows',
		template = I.MWUI.templates.boxTransparent,
        name = 'MainBuffBoundary',
		props = {
            relativePosition = pos or v2(0.5, 0.5),
			anchor = v2(0, 0),
			alpha = 0.2,
			position = v2(0,0),
		},
		content = ui.content{inputContent,},
        userData = {
            doDrag = false,
            lastMousePos = nil
        },
	}
	return element
end
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--new 09-25-2024
common.createRootFlexLayouts = function(returnType,iconSize, fltr)
	local spellList = Actor.activeSpells(self)
	local myTemplate = {}
	common.ui.customPadding(myTemplate)
	-- create flat table with indexed effects
    local fxTable = common.createFxTable(spellList)

	--track indexed alpha and durations values in order to recall later by index
	local alphaIndex = {}
    local FxIndex = {}
    local timeIndex = {}

	-- do some processing on fxTable to create widgets or elements
	local root_layouts = {}
	local padded_roots = {}
    
    --Default size table
    local sizeTable = {tSize = iconSize and iconSize*0.28 or 9, size ={x= iconSize and iconSize or 30,y=iconSize and (iconSize*0.3+1)*2 or 10}}



	for _, fx in ipairs(fxTable) do
        --print(fltr(fx))
		if not fltr or (fltr ~= nil and fltr(fx)) then
            --local rootFlexInput = {}
            local ID = fx.activeSpellId..'/'..fx.index..'/'..fx.id
            local timeText = common.formatDuration(fx.durationLeft)
            
            local fx_text
            local fx_icon
            local fx_timeRemain
            local inText = common.attributeAlias[fx.affectedAttribute] or common.skillAlias[fx.affectedSkill] or nil
            if inText then
                local magnitudeStr = tostring(util.round(fx.magnitudeThisFrame))
                -- Check if either inText or magnitude is longer than 3 or overall characters > 6
                if (#inText > 3 or #magnitudeStr > 3) and (#inText + #magnitudeStr) > 6 then
                    --print('inText>3', #inText, fx.name)
                    inText = inText .. ':\n' .. magnitudeStr
                else
                    inText = inText .. ': ' .. magnitudeStr
                end
                fx_text = common.ui.makeTextContent(string.lower(inText), sizeTable)
                --print(fx_text.name,fx_text.props.textSize)
            else
                --If it has no effect just assign it a space holder. 
                fx_text = common.ui.makeTextContent("",{tSize = iconSize and iconSize*0.28 or 9, size ={x= iconSize and iconSize or 30,y=iconSize and (iconSize*0.3+1)*2 or 10}, id = ID})
            end
            fx_icon = common.ui.makeIconContent(fx.icon,{size = iconSize or 30})
            fx_icon.content:add(shader.Overlay(shader.radialWipe(fx),iconSize))
            local timeArgs = {h = Amid, tSize = iconSize and iconSize*0.3+1 or 10, size ={x= iconSize and iconSize or 30,y=iconSize and iconSize*0.3+1 or 10}}
            fx_timeRemain =  common.ui.makeTextContent(timeText, timeArgs)

            --Determine the rootFlexSize Props needed for children content
            local rootFlexSize = common.calculateRootFlexSize({fx_text, fx_icon, fx_timeRemain})
            --fx_timeRemain.userdata.durationLeft = fx.duration and fx.durationLeft or nil
            --print(rootFlexSize)
            local rootFlexWidget = common.ui.rootFlex({fx_text,fx_icon,fx_timeRemain}, {size = rootFlexSize, aSize = false},ID)
            --local rootFlexWidget = common.ui.createImageWithText(45,fx.icon,timeText,fx.name,ID)
            rootFlexWidget.userdata.fx = fx
            rootFlexWidget.userdata.Duration = fx.duration
            rootFlexWidget.userdata.DurationLeft = fx.durationLeft

            local paddedFlexRoots = {
                name = 'padded/'..ID,
                template = myTemplate.padding,
                content = ui.content {rootFlexWidget},
                userdata = {fx = fx, Duration = fx.duration, DurationLeft = timeText}
            }

            table.insert(root_layouts, rootFlexWidget)
            table.insert(alphaIndex, fx_icon)
            table.insert(timeIndex, fx_timeRemain)
            table.insert(FxIndex, fx)
            table.insert(padded_roots, paddedFlexRoots)
        end
	end

	-- Return the structured table with effects grouped by unique keys
    if not returnType or returnType == 'content' then
        return root_layouts, alphaIndex, FxIndex, timeIndex
    elseif returnType == 'pad' then
        return padded_roots, alphaIndex, FxIndex, timeIndex
    else
        return root_layouts, alphaIndex, FxIndex, timeIndex
    end
end

--09-27-2024
common.flexWrapper = function(content, args)
    -- Extract parameters from args
    local iconScale = args.iconScale or 1.0  -- Default to 1.0 if not provided
    local textScale = args.textScale or 1.0  -- Default to 1.0 if not provided
    local iconsPerRow = args.iconsPerRow or 2  -- Default to 10 icons per row if not provided
    local rootSize
    local baseIconWidth
    local baseRowHeight
    local padding = false
    --print(content[1].name)
    --print(content[1].name)
    if content[1].name and string.sub(content[1].name , 1, 3) == 'pad' then
        rootSize = common.calculateRootFlexSize(content[1].content)
        padding = true
        --print("It's Padded <=> RootSize: " .. rootSize.x ..","..rootSize.y)
        baseIconWidth = args.baseIconWidth or (rootSize.x + 2 * borderV.x)  -- Default base width
        baseRowHeight = args.baseRowHeight or (rootSize.y + 2 * borderV.y)  -- Default row height
    else
        rootSize = common.calculateRootFlexSize(content[1].content)
        --print("RootSize: " .. rootSize.x ..","..rootSize.y)
        baseIconWidth = args.baseIconWidth or (rootSize.x)  -- Default base width
        baseRowHeight = args.baseRowHeight or (rootSize.y)  -- Default row height
    end

    -- Calculate scaled dimensions
    local iconWidth = baseIconWidth * iconScale
    local rowHeight = baseRowHeight * iconScale
    local containerWidth = iconWidth * iconsPerRow  -- Total width of each row
    
    -- Initialize layout variables
    local currentRowWidth = 0
    local rows = { {} }  -- Each row starts as an empty table
    local flexWidgets = {}  -- Store each row's flex widget

    -- Iterate through the icons (content table)
    for i, buff in ipairs(content) do
        if currentRowWidth + iconWidth > containerWidth then
            -- Start a new row when exceeding container width
            table.insert(rows, {})
            currentRowWidth = 0
        end

        -- Add the buff icon to the current row
        table.insert(rows[#rows], buff)
        currentRowWidth = currentRowWidth + iconWidth
    end
    --print("Width: " .. containerWidth, "Height: " .. rowHeight)
    -- Create flex widgets for each row
    for rowIndex, row in ipairs(rows) do
        --print("RowIndex is: ".. rowIndex)
        local flexRow = {
            name = 'flexRow'..rowIndex,
            type = ui.TYPE.Flex,
            props = {
                position = v2(0, 0),  -- Adjust vertical position dynamically
                size = v2(containerWidth, rowHeight),  -- Set row width and height
                horizontal = true,  -- Horizontal layout
                anchor = v2(0, tonumber(rowIndex)),  -- Offset the widget vertically
                align = args and args.Alignment or Aleft
            },
            content = ui.content(row)  -- Add icons to the row
        }
        table.insert(flexWidgets, flexRow)
    end

    return flexWidgets  -- Return the table of flex rows
end

common.fltBuffs = function(fx)
    return common.buffs[fx.id] and fx
end

common.fltDebuffs = function(fx)
    return common.debuffs[fx.id] and fx
end

common.fltBuffTimers = function(fx)
    return common.buffs[fx.id] and fx.duration and fx
end

common.fltDebuffTimers = function(fx)
    return common.debuffs[fx.id] and fx.duration and fx
end

-- Need to figure out how to handle this when the ui-modes omwscript is being used.. 
-- it creates copies of the tooltip and doesnt clear them
common.ui.toolTipBox = function(fxData,position)
    if not fxData then return end
    local fx = fxData
    TOOLTIP_ID = fx.activeSpellId..'/'..fx.index..'/'..fx.id -- Update the tracked tooltip unique id
    local inputText = fx.id ..'\n'..fx.name.." "
    --inputText = fx.affectedAttribute and inputText .."("..fx.affectedAttribute..")" or fx.affectedSkill and inputText .."("..fx.affectedSkill..")"
    inputText = fx.magnitudeThisFrame and inputText..":"..fx.magnitudeThisFrame.." "
    inputText = fx.durationLeft and inputText.."Duration: "..common.formatDuration(fx.durationLeft)
    local displayText = common.ui.makeTextContent(inputText)
    displayText.props.textColor = color.rgb(202 / 255, 165 / 255, 96 / 255)
    displayText.props.autoSize = true
    displayText.props.textAlignH = Amid
    displayText.props.wordWrap = false
    displayText.props.textSize = 16
    --print("Attempting to create UI element...")
    local offset = uiSettings:get("buffAlign")
    

    local tooltip = ui.create {
        layer = 'Notification',
		template = I.MWUI.templates.boxSolid,
        name = 'effect_tooltip',
		props = {
            relativePosition = v2(0, 0),
			anchor = not offset and v2(1,0) or v2(0, 0),
			alpha = 1,
			position = v2(0,0),
            --size = v2(500,500)
		},
		content = ui.content({
            {
            template = I.MWUI.templates.padding,
            props = {anchor = v2(0,0)},
            content = ui.content({
                displayText
                })
            }
        }),
    }
    --print("Printing the tooltipLayout ",tooltip.layout.content[1].content[1].props.text)
return tooltip
end

-- Function to update the tooltip's text
common.updateTooltip = function(newText)
    if TOOLTIP then
        -- Assuming TOOLTIP has a method to update its content
        TOOLTIP:updateContent(newText)  -- Call an update method to change the text
    end
end

-- Function to destroy the tooltip
common.destroyTooltip = function(checkExistence)
    if TOOLTIP and not checkExistence then
        TOOLTIP:destroy()  -- Assuming your tooltip object has a destroy method
        TOOLTIP = nil  -- Reset the global TOOLTIP variable
    end

    if TOOLTIP_ID and checkExistence then
        --print("... Checking Icon for tooltip still exists")
        if not fxKey[TOOLTIP_ID] then
            --print("Icon_ID: "..TOOLTIP_ID.." does not Exist ... Destroying")
            TOOLTIP:destroy()  -- Assuming your tooltip object has a destroy method
            TOOLTIP = nil  -- Reset the global TOOLTIP variable
            TOOLTIP_ID = nil
        end
    end
end

-- Optional: Function to get the current tooltip (for checking or debugging)
common.getTooltip = function()
    return TOOLTIP
end

return common