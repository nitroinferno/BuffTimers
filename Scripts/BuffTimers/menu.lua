print('MENU_LUA_LOADED_' .. os.time())
local util = require('openmw.util')
local ui = require('openmw.ui')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local input = require('openmw.input')
local ui_builders = require('Scripts.BuffTimers.ui_builders')
local v2 = util.vector2

local DEFAULT_VALUE = 24 -- Default scaling value
local MIN_VALUE = 1    -- Minimum allowable value
local MAX_VALUE = 100     -- Maximum allowable value

local msg = "Current Bound Key: "
local msgNew = "New KeyBind: "

local activeCapture = nil
local activePopup = nil
local t = nil

local controllerButtonNames = require('Scripts.BuffTimers.controllerButtons')

local function validateInput(input, defaultValue)
    local numValue = tonumber(input)  -- Try converting the input to a number
    if not numValue then
        ui.showMessage("Invalid input! Resetting to default value.")
        return defaultValue or DEFAULT_VALUE
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
        local defaultValue = arg.defaultValue or DEFAULT_VALUE  -- Default to 24 if no default is provided
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
                                local validatedValue = validateInput(newText, defaultValue)  -- Validate the new input
                                set(validatedValue)  -- Update the setting with the validated value
                            end),
                        },
                    }
                }),
            }
            })
        }
    end
)

I.Settings.registerRenderer(
    'myToggle',
    function(value, set, arg)
        -- Determine the initial state
        local selectedOption = value or "Unshade"  -- Default to "Shade"

        -- Function to toggle between "Shade" and "Unshade"
        local function toggle()
            if selectedOption == "Shade" then
                selectedOption = "Unshade"
            else
                selectedOption = "Shade"
            end
            set(selectedOption)  -- Update the setting value
        end

        -- Return the renderer with toggleable text
        return {
            template = I.MWUI.templates.box,  -- Use the provided template for box styling
            content = ui.content({
                {
                    template = I.MWUI.templates.padding,
                    content = ui.content({
                        {
                            type = ui.TYPE.Text,  -- Use text type for clickable option
                            props = {
                                text = selectedOption,  -- Display current state
                                textColor = util.color.rgb(202 / 255, 165 / 255, 96 / 255),  -- Custom text color
                                textSize = 15,  -- Text size
                                textAlignH = ui.ALIGNMENT.Center,  -- Center align the text horizontally
                                textAlignV = ui.ALIGNMENT.Center,
                                size = v2(60,20),
                                autoSize = false
                            },
                            events = {
                                mousePress = async:callback(function(e)
                                    if e.button ~= 1 then return end
                                    toggle()  -- Toggle the option when clicked
                                end),
                            },
                        },
                    })
                },
            })
        }
    end
)

-- Controller Functions and Renderers ---
-- =========================================================
-- GLOBAL CLOSE (single authority)
-- =========================================================
local function closeBindingUI()
    activeCapture = nil

    if activePopup then
        activePopup:destroy()
        activePopup = nil
    end
end

-- =========================================================
-- STATE RESET (local only)
-- =========================================================
local function resetState(state)
    if not state then return end
    state.capturedButton = nil
    state.capturedKey = nil
    state.confirmed = false
    state.cleared = false
end

-- =========================================================
-- INPUT CAPTURE
-- =========================================================
local function handleInputCapture(inputType, idOrCode)
    if not activeCapture then return end

    local tempTime = os.time()
    --print("timeinsideinputhandler",t)
    if tempTime - t < 1 then
        --print("Input ignored due to time guard:", tempTime - t)
        return
    end

    local state = activeCapture.state
    local element = activeCapture.element

    if not element then return end

    -- ownership guard (prevents stale closures writing wrong UI)
    if activeCapture.state ~= state then
        return
    end

    -- already captured, ignore spam
    if state.capturedButton or state.capturedKey then
        return
    end

    -- keyboard input
    if inputType == "keyboard" then
        state.capturedKey = idOrCode
    elseif inputType == "controller" then
        state.capturedButton = controllerButtonNames[idOrCode]
    end

    local displayName
    if state.capturedButton then
        displayName = state.capturedButton
    elseif state.capturedKey then
        local ok, keyName = pcall(input.getKeyName, state.capturedKey)
        displayName = ok and keyName or tostring(state.capturedKey)
    end

    if element and element.layout then
        element.layout.content.sizeWrapper.content.DisplayText.props.text =
            (msgNew .. string.upper(displayName or "No Key Set"))
        element:update()
    end
end

-- =========================================================
-- RENDERER
-- =========================================================
I.Settings.registerRenderer(
"inputKeySelection",
function(value, set)

    local element = nil

    local state = {
        capturedButton = nil,
        capturedKey = nil,
        confirmed = false,
        cleared = false,
    }

    local function refresh(newVal)
        set(newVal)
    end

    local ok, keyName = pcall(input.getKeyName, value)
    local currentVal = ok and keyName or value
    local bindLabel = currentVal and string.upper(currentVal) or "No Key Set"

    local BindingBox = ui_builders.BoxBuilder:new()
        :setTemplate(I.MWUI.templates.boxSolidThick)
        :setSize(util.vector2(300, 150))
        :setRelativePosition(util.vector2(0.5, 0.5))
        :setLayer('Settings')
        :addChild(ui_builders.ButtonBuilder:new()
            :setText("Confirm")
            :setSize(util.vector2(120, 40))
            :setRelativePosition(util.vector2(0.75, 0.88))
            :onClick(function()
                if activeCapture and activeCapture.state == state then
                    if state.cleared then
                        refresh("Unset")
                    elseif state.capturedButton then
                        refresh(state.capturedButton)
                    elseif state.capturedKey then
                        refresh(state.capturedKey)
                    else
                        refresh(currentVal)
                    end
                    activeCapture = nil
                end
                resetState(state)
                closeBindingUI()
            end)
            :build())
        :addChild(ui_builders.ButtonBuilder:new()
            :setText("Clear")
            :setSize(util.vector2(120, 40))
            :setRelativePosition(util.vector2(0.5, 0.88))
            :onClick(function()
                state.capturedButton = nil
                state.capturedKey = nil
                state.cleared = true
                t = os.time()
                if element then
                    element.layout.content.sizeWrapper.content.DisplayText.props.text =
                        (msgNew .. "No Key Set")
                    element:update()
                end
            end)
            :build())
        :addChild(ui_builders.ButtonBuilder:new()
            :setText("Cancel")
            :setSize(util.vector2(120, 40))
            :setRelativePosition(util.vector2(0.25, 0.88))
            :onClick(function()
                closeBindingUI()
                resetState(state)
            end)
            :build())

        :addChild(ui_builders.textBuilder:new()
            :setName("DisplayText")
            :setText(msg)
            :setRelativePosition(util.vector2(0.5, 0.5))
            :setAnchor(util.vector2(0.5, 0.5))
            :build())
        :build()

        local bindButtonWidget = ui_builders.ButtonBuilder:new()
        :setText("Key Binding Menu")
        :setSize(util.vector2(120, 40))
        :onClick(function()
            closeBindingUI()
            t = os.time()
            --print(t)
            state.capturedButton = nil
            state.capturedKey = nil
            state.cleared = false
            element = ui.create(BindingBox)
            activePopup = element

            activeCapture = {
                state = state,
                element = element,
                refresh = refresh
            }

            element.layout.content.sizeWrapper.content.DisplayText.props.text =
                value and (msg .. string.upper(currentVal)) or (msg .. "No Key Set")
        end)
        :build()

        local keyLabelLayout = ui_builders.textBuilder:new()
        :setName("currentKeyLabel")
        :setText(bindLabel)
        :setAnchor(util.vector2(0, 0.5))
        :build()

        local bindButton = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            autoSize = true,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            keyLabelLayout,
            { template = I.MWUI.templates.interval },
            bindButtonWidget,
        },
    }

    return bindButton
end
)

-- =========================================================
-- ENGINE HANDLERS
-- =========================================================
return {
    eventHandlers = {
        E_ControllerPress = handleInputCapture,
    },

    engineHandlers = {
        onControllerButtonPress = function(id)
            local name = controllerButtonNames[id]

            if name == "B" then
                closeBindingUI()
                return
            end

            handleInputCapture("controller", id)
        end,

        onKeyPress = function(key)
            if key.code == input.KEY.Escape then
                closeBindingUI()
                return
            end

            handleInputCapture("keyboard", key.code)
        end,
    }
}