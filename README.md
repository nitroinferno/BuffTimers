# OpenMW BUFF ICONS & TIMERS
Lua scripts that puts buff and debuffs onto the screen. 

![Buffs With Timers](/photos/screencap1.png?raw=true)
## DESCRIPTION
There are 2 separate icon windows one for buffs and one for debuffs that can be user configured to limit the total buffs, how many buffs per row, size, and font colors. 
Each buff can be repositioned to anywhere on the HUD by just clicking and dragging the window box. Set the display box setting to 'Yes' to see the buff box space, while you have no buffs or debuffs present

The buff box positions can be saved by pressing the '=' key. If you need to reset their positions to the default press '-'.

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

    5. Copy and Paste the following line between the 2 lines of code:  <Property key="Size" value="0,0"/> 
    
    6. Save file. 
    


