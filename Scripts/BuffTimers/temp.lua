layout2.startDrag = async:callback(function(coord)
    layout2.userData.doDrag = true
    layout2.userData.lastMousePos = coord.position
  end)

layout2.stopDrag = async:callback(function()
    layout2.userData.doDrag = false
end)

layout2.drag = async:callback(function(coord, layout)
    if not layout2.userData.doDrag then return end
    local props = layout.props
    props.position = props.position - (layout2.userData.lastMousePos - coord.position)
    I.s3ChimSleep.Menu:update()
    layout2.userData.lastMousePos = coord.position
end)

layout2.events = {
mousePress = layout2.startDrag,
mouseRelease = layout2.stopDrag,
mouseMove = layout2.drag,
}




--[[ print("\n\n----------------------------------------------------------")
for k,v in pairs(layout2) do
	print("Key:", k, "type:", type(k), "Value:", v, "typeV:", type(v))
	if type(v) == "table" then
		for key,val in pairs(v) do
		print(k,":", key, "2ndVal:",val)
		end
	end
end
 ]]


local TextContent = com.ui.makeTextContent("MY STRING", {tSize = 50, size = 400, aSize = false})
local textElement = ui.create{
    layer = 'Windows',
    name = 'testingText',
    type = ui.TYPE.Container,
    --template = I.MWUI.templates.boxTransparent,
    props = {
        relativePosition = v2(0.1,0.1),
        positiong = v2(0,0),
        visible = true,
        --autoSize = false,
        --size = v2(10,10)
    },
    content = ui.content({TextContent}),
}

local function scaleSize(baseSize, userSize)
    local xRes, yRes = ui.screenSize().x, ui.screenSize().y
    -- Calculate scaling factor based on the resolution
    local scaleFactor = (xRes + yRes) / (1920 + 1080)  -- Assuming 1920x1080 is your reference resolution
    return userSize * scaleFactor
end



local util = require('openmw.util')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')

local DEFAULT_VALUE = 1 -- Default scaling value
local MIN_VALUE = 0.1    -- Minimum allowable value
local MAX_VALUE = 10     -- Maximum allowable value

I.Settings.registerRenderer(
    'MyCustomTextEditRenderer',
    function(value, set)
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

        return {
            template = I.MWUI.templates.textEdit,  -- Use the TextEdit template
            content = ui.content({
                {
                    type = ui.TYPE.TextEdit,
                    props = {
                        text = tostring(value),  -- Initial text set to current value
                        onTextChanged = function(newText)
                            local validatedValue = validateInput(newText)
                            set(validatedValue)  -- Update the setting with the validated value
                        end,
                    },
                },
            }),
        }
    end
)



local util = require('openmw.util')
local ui = require('openmw.ui')
local async = require('openmw.async')
local I = require('openmw.interfaces')

local DEFAULT_VALUE = 1 -- Default scaling value
local MIN_VALUE = 0.1    -- Minimum allowable value
local MAX_VALUE = 10     -- Maximum allowable value

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
    'MyCustomTextEditRenderer',
    function(value, set, arg)
        return {
            type = ui.TYPE.TextEdit,
            props = {
                size = util.vector2(arg and arg.size or 150, 30),  -- Set size, defaulting to 150x30
                text = tostring(value),  -- Initial text set to current value
                textColor = util.color.rgb(1, 1, 1),  -- White text color
                textSize = 15,  -- Text size
                textAlignV = ui.ALIGNMENT.End,  -- Vertical alignment
            },
            events = {
                textChanged = async:callback(function(newText)
                    local validatedValue = validateInput(newText)  -- Validate the new input
                    set(validatedValue)  -- Update the setting with the validated value
                end),
            },
        }
    end
)



