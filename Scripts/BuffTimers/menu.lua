local util = require('openmw.util')
local ui = require('openmw.ui')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local v2 = util.vector2

local DEFAULT_VALUE = 24 -- Default scaling value
local MIN_VALUE = 1    -- Minimum allowable value
local MAX_VALUE = 100     -- Maximum allowable value

local function validateInput(input)
    local numValue = tonumber(input)  -- Try converting the input to a number
    if not numValue then
        ui.showMessage("Invalid input! Resetting to default value.")
        return DEFAULT_VALUE
    end

    -- Clamp the number within the specified bounds
    if numValue < MIN_VALUE or numValue > MAX_VALUE then
        ui.showMessage("Value out of bounds! Clamping to allowed range.")
        return util.clamp(numValue, MIN_VALUE, MAX_VALUE)
    end

    return numValue  -- Return the valid number
end

I.Settings.registerRenderer(
    'inputText',
    function(value, set, arg)
        return {
            template = I.MWUI.templates.box,
            content = ui.content({
            {
                props = {
                    size = v2(arg and arg.size or 50, 15),
                },
                content = ui.content({
                    {
                        type = ui.TYPE.TextEdit,
                        props = {
                            size = v2(arg and arg.size or 50, 15),  -- Set size, defaulting to 150x30
                            text = tostring(value),  -- Initial text set to current value
                            textColor = util.color.rgb(202 / 255, 165 / 255, 96 / 255),  -- White text color
                            textSize = 15,  -- Text size
                            textAlignV = ui.ALIGNMENT.Start,  -- Vertical alignment
                            textAlignH = ui.ALIGNMENT.End,
                        },
                        events = {
                            textChanged = async:callback(function(newText)
                                local validatedValue = validateInput(newText)  -- Validate the new input
                                set(validatedValue)  -- Update the setting with the validated value
                            end),
                        },
                    }
                })
            }
            })
        }
    end
)