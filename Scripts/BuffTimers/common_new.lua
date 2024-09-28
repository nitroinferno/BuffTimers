local async = require('openmw.async')
local aux_util = require('openmw_aux.util')
local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')
local core = require("openmw.core")
local I = require('openmw.interfaces')
local templates = I.MWUI.templates
local v2 = util.vector2
local color = util.color
local borderV = v2(1,1) * 3
local mRs = core.magic.effects.records
local mgFx = core.magic.EFFECT_TYPE

local xRes = ui.screenSize().x
local yRes = ui.screenSize().y

local common = {
    const = {
      CHAR_ROTATE_SPEED = 0.3,
      DEFAULT_ITEM_TYPES = {[types.Clothing] = true},
      WINDOW_HEIGHT = math.min(640, yRes * 0.95), -- Occupy 800px preferably, or full vertical size
      RIGHT_PANE_WIDTH = math.min(720, xRes * 0.30), -- Occupy 600px preferably, or 25% horizontal size
      LEFT_PANE_WIDTH = math.min(140, xRes * 0.2), -- Occupy 200px preferably, or 20% horizontal size
      TEXT_COLOR = util.color.rgb(255, 255, 255),
      BACKGROUND_COLOR = util.color.rgb(0, 0, 0),
      HIGHLIGHT_COLOR = util.color.rgba(44 / 255, 46 / 255, 45 / 255, 0.5),
      IMAGE_SIZE = util.vector2(32, 32),
      INVENTORY_IMAGE_SIZE = util.vector2(48, 48),
      FONT_SIZE = 18,
      HEADER_FONT_SIZE = 24,
      HEADER_REL_SIZE = 0.1,
      FOOTER_REL_SIZE = 0.05,
      MAX_ITEMS = util.vector2(9, 9),
      WIDGET_ORIGIN_PCT = 0.75, -- % of the distance from the top-left corner of the widget to the center of the screen
      TOOLTIP_SEGMENT_HEIGHT = 85,
      TOOLTIP_TYPE_TEXT_SIZE = util.vector2(120.0, 28),
      TOOLTIP_PRIMARY_FIELDS_WIDTH = 120.0,
    },
    --need to store all debuff type effects
    debuffs = {
        [mRs[mgFx.AbsorbAttribute].id] = true,
        [mRs[mgFx.AbsorbFatigue].id] = true,
        [mRs[mgFx.AbsorbHealth].id] = true,
        [mRs[mgFx.AbsorbMagicka].id] = true,
        [mRs[mgFx.AbsorbSkill].id] = true,
        [mRs[mgFx.Blind].id] = true,
        [mRs[mgFx.Burden].id] = true,
        [mRs[mgFx.CalmCreature].id] = true,
        [mRs[mgFx.CalmHumanoid].id] = true,
        [mRs[mgFx.Charm].id] = true,
        [mRs[mgFx.CommandCreature].id] = true,
        [mRs[mgFx.CommandHumanoid].id] = true,
        [mRs[mgFx.Corprus].id] = true,
        [mRs[mgFx.DamageAttribute].id] = true,
        [mRs[mgFx.DamageFatigue].id] = true,
        [mRs[mgFx.DamageHealth].id] = true,
        [mRs[mgFx.DamageMagicka].id] = true,
        [mRs[mgFx.DamageSkill].id] = true,
        [mRs[mgFx.DemoralizeCreature].id] = true,
        [mRs[mgFx.DemoralizeHumanoid].id] = true,
        [mRs[mgFx.DisintegrateArmor].id] = true,
        [mRs[mgFx.DisintegrateWeapon].id] = true,
        [mRs[mgFx.DrainAttribute].id] = true,
        [mRs[mgFx.DrainFatigue].id] = true,
        [mRs[mgFx.DrainHealth].id] = true,
        [mRs[mgFx.DrainMagicka].id] = true,
        [mRs[mgFx.DrainSkill].id] = true,
        [mRs[mgFx.FireDamage].id] = true,
        [mRs[mgFx.FrenzyCreature].id] = true,
        [mRs[mgFx.FrenzyHumanoid].id] = true,
        [mRs[mgFx.FrostDamage].id] = true,
        [mRs[mgFx.Lock].id] = true,
        [mRs[mgFx.Paralyze].id] = true,
        [mRs[mgFx.Poison].id] = true,
        [mRs[mgFx.ShockDamage].id] = true,
        [mRs[mgFx.Silence].id] = true,
        [mRs[mgFx.Soultrap].id] = true,
        [mRs[mgFx.Sound].id] = true,
        [mRs[mgFx.SpellAbsorption].id] = true,
        [mRs[mgFx.StuntedMagicka].id] = true,
        [mRs[mgFx.SunDamage].id] = true,
        [mRs[mgFx.TurnUndead].id] = true,
        [mRs[mgFx.Vampirism].id] = true,
        [mRs[mgFx.WeaknessToBlightDisease].id] = true,
        [mRs[mgFx.WeaknessToCommonDisease].id] = true,
        [mRs[mgFx.WeaknessToCorprusDisease].id] = true,
        [mRs[mgFx.WeaknessToFire].id] = true,
        [mRs[mgFx.WeaknessToFrost].id] = true,
        [mRs[mgFx.WeaknessToMagicka].id] = true,
        [mRs[mgFx.WeaknessToNormalWeapons].id] = true,
        [mRs[mgFx.WeaknessToPoison].id] = true,
        [mRs[mgFx.WeaknessToShock].id] = true,
    },
    buffs = {
        [mRs[mgFx.AlmsiviIntervention].id] = true,
        [mRs[mgFx.BoundBattleAxe].id] = true,
        [mRs[mgFx.BoundBoots].id] = true,
        [mRs[mgFx.BoundCuirass].id] = true,
        [mRs[mgFx.BoundDagger].id] = true,
        [mRs[mgFx.BoundGloves].id] = true,
        [mRs[mgFx.BoundHelm].id] = true,
        [mRs[mgFx.BoundLongbow].id] = true,
        [mRs[mgFx.BoundLongsword].id] = true,
        [mRs[mgFx.BoundMace].id] = true,
        [mRs[mgFx.BoundShield].id] = true,
        [mRs[mgFx.BoundSpear].id] = true,
        [mRs[mgFx.Chameleon].id] = true,
        [mRs[mgFx.CureBlightDisease].id] = true,
        [mRs[mgFx.CureCommonDisease].id] = true,
        [mRs[mgFx.CureCorprusDisease].id] = true,
        [mRs[mgFx.CureParalyzation].id] = true,
        [mRs[mgFx.CurePoison].id] = true,
        [mRs[mgFx.DetectAnimal].id] = true,
        [mRs[mgFx.DetectEnchantment].id] = true,
        [mRs[mgFx.DetectKey].id] = true,
        [mRs[mgFx.Dispel].id] = true,
        [mRs[mgFx.DivineIntervention].id] = true,
        [mRs[mgFx.ExtraSpell].id] = true,
        [mRs[mgFx.Feather].id] = true,
        [mRs[mgFx.FireShield].id] = true,
        [mRs[mgFx.FortifyAttack].id] = true,
        [mRs[mgFx.FortifyAttribute].id] = true,
        [mRs[mgFx.FortifyFatigue].id] = true,
        [mRs[mgFx.FortifyHealth].id] = true,
        [mRs[mgFx.FortifyMagicka].id] = true,
        [mRs[mgFx.FortifyMaximumMagicka].id] = true,
        [mRs[mgFx.FortifySkill].id] = true,
        [mRs[mgFx.FrostShield].id] = true,
        [mRs[mgFx.Invisibility].id] = true,
        [mRs[mgFx.Jump].id] = true,
        [mRs[mgFx.Levitate].id] = true,
        [mRs[mgFx.Light].id] = true,
        [mRs[mgFx.LightningShield].id] = true,
        [mRs[mgFx.Mark].id] = true,
        [mRs[mgFx.NightEye].id] = true,
        [mRs[mgFx.Open].id] = true,
        [mRs[mgFx.RallyCreature].id] = true,
        [mRs[mgFx.RallyHumanoid].id] = true,
        [mRs[mgFx.Recall].id] = true,
        [mRs[mgFx.Reflect].id] = true,
        [mRs[mgFx.RemoveCurse].id] = true,
        [mRs[mgFx.ResistBlightDisease].id] = true,
        [mRs[mgFx.ResistCommonDisease].id] = true,
        [mRs[mgFx.ResistCorprusDisease].id] = true,
        [mRs[mgFx.ResistFire].id] = true,
        [mRs[mgFx.ResistFrost].id] = true,
        [mRs[mgFx.ResistMagicka].id] = true,
        [mRs[mgFx.ResistNormalWeapons].id] = true,
        [mRs[mgFx.ResistParalysis].id] = true,
        [mRs[mgFx.ResistPoison].id] = true,
        [mRs[mgFx.ResistShock].id] = true,
        [mRs[mgFx.RestoreAttribute].id] = true,
        [mRs[mgFx.RestoreFatigue].id] = true,
        [mRs[mgFx.RestoreHealth].id] = true,
        [mRs[mgFx.RestoreMagicka].id] = true,
        [mRs[mgFx.RestoreSkill].id] = true,
        [mRs[mgFx.Sanctuary].id] = true,
        [mRs[mgFx.Shield].id] = true,
        [mRs[mgFx.SlowFall].id] = true,
        [mRs[mgFx.SummonAncestralGhost].id] = true,
        [mRs[mgFx.SummonBear].id] = true,
        [mRs[mgFx.SummonBonelord].id] = true,
        [mRs[mgFx.SummonBonewalker].id] = true,
        [mRs[mgFx.SummonBonewolf].id] = true,
        [mRs[mgFx.SummonCenturionSphere].id] = true,
        [mRs[mgFx.SummonClannfear].id] = true,
        --[mRs[mgFx.SummonCreature04].id] = true, -- for some reason these equate to nil
        --[mRs[mgFx.SummonCreature05].id] = true,
        [mRs[mgFx.SummonDaedroth].id] = true,
        [mRs[mgFx.SummonDremora].id] = true,
        [mRs[mgFx.SummonFabricant].id] = true,
        [mRs[mgFx.SummonFlameAtronach].id] = true,
        [mRs[mgFx.SummonFrostAtronach].id] = true,
        [mRs[mgFx.SummonGoldenSaint].id] = true,
        [mRs[mgFx.SummonGreaterBonewalker].id] = true,
        [mRs[mgFx.SummonHunger].id] = true,
        [mRs[mgFx.SummonScamp].id] = true,
        [mRs[mgFx.SummonSkeletalMinion].id] = true,
        [mRs[mgFx.SummonStormAtronach].id] = true,
        [mRs[mgFx.SummonWingedTwilight].id] = true,
        [mRs[mgFx.SummonWolf].id] = true,
        [mRs[mgFx.SwiftSwim].id] = true,
        [mRs[mgFx.Telekinesis].id] = true,
        [mRs[mgFx.WaterBreathing].id] = true,
        [mRs[mgFx.WaterWalking].id] = true,
    },
    attributeAlias = {
        ['Agility'] = 'AGIL',
        ['Endurance'] = 'ENDR',
        ['Intelligence'] = 'INT',
        ['Luck '] = 'LUCK',
        ['Personality '] = 'CHAR',
        ['Speed'] = 'SPD',
        ['Strength  '] = 'STR',
        ['Willpower'] = 'WPWR',
    },
    skillAlias = {
        ['Acrobatics']= 'ACRB',
        ['Alchemy']= 'ALCH',
        ['Alteration']= 'ALTR',
        ['Armorer']= 'RPAIR',
        ['Athletics']= 'ATHL',
        ['Axe']= 'AXE',
        ['Block']= 'BLCK',
        ['Blunt Weapon']= 'BLNT',
        ['Conjuration']= 'CONJ',
        ['Destruction']= 'DEST',
        ['Enchant']= 'ENCH',
        ['Hand-to-hand']= 'FIST',
        ['Heavy Armor']= 'ARMH',
        ['Illusion']= 'ILLU',
        ['Light Armor']= 'ARML',
        ['Long Blade']= 'LBLD',
        ['Marksman']= 'BOW',
        ['Medium Armor']= 'ARMM',
        ['Mercantile']= 'MERC',
        ['Mysticism']= 'MYST',
        ['Restoration']= 'REST',
        ['Security']= 'SEC',
        ['Short Blade']= 'SBLD',
        ['Sneak']= 'SNK',
        ['Spear']= 'SPR',
        ['Speechcraft']= 'SPCH',
        ['Unarmored']= 'UNAR',
    },
    ui = {},
}

--simple table copy function
common.clone = function(org) 
    return {table.unpack(org)}
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

common.ui.createImageWithText = function(size, icon, text, effectname)
  local imageWidget = {
        name = effectname and 'image_' .. effectname or 'image',
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
        name = effectname and 'textWidget_' .. effectname or 'textWidget',
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
        name = effectname and 'BuffFlexContainer_' .. effectname or 'BuffFlexContainer',
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
common.ui.createPaddedContent = function(size, imagePath, text, effectname)
  local IconWithText = common.ui.createImageWithText(size or 20, imagePath, text, effectname)
  local myTemplate = {}
  common.ui.customPadding(myTemplate)
	--local myImage = createImage(size or 20, imagePath)
	return {
			name = effectname and 'padded_' .. effectname or 'padded',
			template = myTemplate.padding,
			content = ui.content {
				IconWithText
			}
    }
end

--@param offset util.vector2(#,#) The second parameter (default: false/nil).
common.ui.createFlexRow2 = function(myBuffs, offset, size)
    local flexContent = {}
    -- Iterate through spell effects and add each one to the flex content
    for _, data in pairs(myBuffs) do
        for _, effect in pairs(data) do
			--local widget = common.ui.createPaddedContent(size, effect.icon, effect.duration)
			if effect.durationLeft and effect.durationLeft > 0 then
                local widget = common.ui.createPaddedContent(size, effect.icon, effect.durationLeft and common.formatDuration(effect.durationLeft) or '', effect.name)
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
common.ui.createLayoutBasic = function(myBuffs, offset, pos, size)
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
		content = ui.content{common.ui.createFlexRow2(myBuffs, offset, size),}
	}
	return layoutMaker
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
                    icon = mRs[effect.id].icon,
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
                    icon = mRs[effect.id].icon,
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
        time = util.round(time * 10)
        time = time/10
        time = time .. 's'
    end

    return time
end

return common