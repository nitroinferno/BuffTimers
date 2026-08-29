# OpenMW BUFF ICONS & TIMERS
Lua scripts that puts buff and debuffs onto the screen. 

![Buffs With Timers](/photos/screencap1.png?raw=true)
## DESCRIPTION
There are 2 separate icon windows one for buffs and one for debuffs that can be user configured to limit the total buffs, how many buffs per row, size, and font colors. 
Each buff can be repositioned to anywhere on the HUD by just clicking and dragging the window box. Set the display box setting to 'Yes' OR press the ';' key in game to see the buff box space.

A new Feature has been added to combine buff and debuff boxes into a single box.
Radial swipe is user configurable as well as timer position
Display of skill & attribue alias/abbreviation and magnitude text can be set on or off.
Constant Effects can be set to be displayed or hidden.  

+ Buff/debuff box positions should save automatically after repositioning.  
+ To show/hide the buff box borders press ';'. When borders are shown you can click and drag the buff/debuffs to any position you like.
+ The buff box positions can be saved by pressing the '=' key (This is a failsafe if for whatever reason your positioning is not saving). If you need to reset their positions to the default press '-'.

### The Above keybinds are user configurable and support gamepad button binding as well. If the Keybinds are not needed they may be set to none. 


The buff icons have tooltip mouseover support as well. 


## Installation instructions

1. Download and extract the contents to your desired folder. (e.g. C:/users/games/OpenMW/mods/)

2. Enable the mod in your OpenMW launcher or alternatively add content=BuffTimers.omwscripts to content= section and file path to data= inside your OpenMW.cfg file. (e.g. data="C:/users/games/OpenMW/Mods/BuffTimers")

## Optional File Installation Instructions (Hiding of regular effects box on UI)
**IF** you don't use any other UI files for OpenMW the do as follows:

 1. Locate where you have installed OpenMW 

 2. Backup the resources folder, this will make it very easy to uninstall later

 3. Copy and paste the openmw_hud.layout file from /optional files into /resources/vfs/mygui folder, replace existing file.

**IF** you **DO** use any other UI files for OpenMW the do as follows:

1. Locate where you have installed OpenMW 

2. Backup the resources folder, this will make it very easy to uninstall later

3. Locate /resources/vfs/mygui/openmw_hud.layout file open in text editor of choice.

4. Find the section for:

        <Widget type="Widget" skin="HUD_Box_Transparent" position="199 168 20 20" align="Right Bottom" name="EffectBox">
        </Widget>

6. Copy and Paste the following line between the 2 lines of code:  `<Property key="Size" value="0,0"/>`
    
7. Save file. 
    
## API for modders

BuffTimers exposes an API for modders, so mod authors can hook into the effect system and display buffs or debuffs with custom icons. This is helpful to prevent cluttering of effects that are predictable, like perhaps wounds, environmental effects, or other long-term, but still temporary effects.

Usage (see Scripts/BuffTimers/api.lua for more information):

```lua
local I = require("openmw.interfaces")

local function myPredicate(spell) 
	return spell.id == "my_custom_icon_spell"
end

local function myEffectFactory(spell) 
    -- Take only the longest effect
    local result = nil
    for _, effect in pairs(spell.effects) do
        if (not result or (effect.durationLeft > result.durationLeft)) then
            result = effect
        end
    end

    -- Returns a list of effect infos
    return {
        {
            activeSpellId = spell.activeSpellId,
            id = result.id,
            index = result.index,
            duration = result.duration,
            durationLeft = result.durationLeft,
            icon = "icons/myCoolIcon.dds",
            parentSpellName = spell.name,
        },
    }
end

I.BuffTimers.registerCustomEffect(myPredicate, myEffectFactory)
```
