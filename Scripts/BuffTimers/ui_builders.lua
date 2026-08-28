-- ui_builders.lua
local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local auxUi = require('openmw_aux.ui')

-- ====================================================
-- BoxBuilder
-- ====================================================
local BoxBuilder = {}
BoxBuilder.__index = BoxBuilder

function BoxBuilder:new()
    local self = setmetatable({}, BoxBuilder)
    self.name =nil
    self.template = I.MWUI.templates.boxSolid
    self.props = {
        size = util.vector2(400, 300),
        relativePosition = nil,
        anchor = util.vector2(0.5, 0.5),
        position = util.vector2(0, 0),
    }
    self.userData = {}
    self.children = {}
    self.events = {}
    self.layer = nil
    self._onKeyPress = nil
    return self
end

function BoxBuilder:setName(name)
    self.name = name
    return self
end

function BoxBuilder:setTemplate(template)
    self.template = template
    return self
end

function BoxBuilder:setLayer(layerName)
    self.layer = layerName
    return self
end

function BoxBuilder:setSize(vec2)
    self.props.size = vec2
    return self
end

function BoxBuilder:onKeyPress(callback)
    self._onKeyPress = callback
    return self
end

function BoxBuilder:setRelativePosition(vec2)
    self.props.relativePosition = vec2
    return self
end

function BoxBuilder:setPosition(vec2)
    self.props.position = vec2
    return self
end

function BoxBuilder:setAnchor(vec2)
    self.props.anchor = vec2
    return self
end

function BoxBuilder:setUserData(data)
    self.userData = data
    return self
end

function BoxBuilder:setEvents(eventsTable)
    self.events = eventsTable
    return self
end

function BoxBuilder:addChild(childLayout)
    table.insert(self.children, childLayout)
    return self
end

function BoxBuilder:_buildEvents()
    local finalEvents = {}

    -- Merge user-defined events first
    if self.events then
        for k, v in pairs(self.events) do
            finalEvents[k] = v
        end
    end

    -- Override or add keyPress if self._onKeyPress is defined
    if self._onKeyPress then
        finalEvents.keyPress = async:callback(function(kE, layout)
            local ok, err = pcall(self._onKeyPress, kE, layout)
            if not ok then print("BoxBuilder KeyPress error:", err) end
        end)
    end

    return next(finalEvents) and finalEvents or {}
end

function BoxBuilder:build()
    local layout = {
        template = self.template,
        name = self.name,
        props = self.props,
    }

    if self.userData then layout.userData = self.userData end
    if self.events then layout.events = self.events end
    if self.layer then layout.layer = self.layer end

    -- assign anchor/position to outer template only
    if self.props.size then layout.props.size = self.props.size end
    if self.props.relativePosition then layout.props.relativePosition = self.props.relativePosition end
    if self.props.anchor then layout.props.anchor = self.props.anchor end
    -- inner widget events
    -- local events = {}
    -- if self._onKeyPress then
    --     events.keyPress = async:callback(function(kE, layout)
    --         local ok, err = pcall(self._onKeyPress, kE, layout)
    --         if not ok then print("ButtonBuilder KeyPress error:", err) end
    --     end)
    -- end
    -- inner widget defines size only, no anchor or relPos to prevent offset/scaling bugs
    local innerWidget = {
        type = ui.TYPE.Widget,
        name = "sizeWrapper",
        props = {
            size = self.props.size or util.vector2(200, 200),
        },
        events = self:_buildEvents(),
    }

    -- if events then innerWidget.events = events end

    if #self.children > 0 then
        innerWidget.content = ui.content(self.children)
    end

    layout.content = ui.content { innerWidget }

    return layout
end




-- ====================================================
-- ButtonBuilder
-- ====================================================
local ButtonBuilder = {}
ButtonBuilder.__index = ButtonBuilder

function ButtonBuilder:new()
    local self = setmetatable({}, ButtonBuilder)
    self.name = nil
    self.template = I.MWUI.templates.boxSolid
    self.size = util.vector2(120, 40)
    self.position = nil
    self.relativePosition = nil
    self.anchor = util.vector2(0.5, 0.5)
    self.text = "Button"
    self.events = {}
    self._onClick = nil
    self._onButtonPress = nil
    self._onKeyPress = nil
    self.userData = nil
    return self
end

function ButtonBuilder:setName(name)
    self.name = name
    return self
end

function ButtonBuilder:setTemplate(template)
    self.template = template
    return self
end

function ButtonBuilder:setSize(vec2)
    self.size = vec2
    return self
end

function ButtonBuilder:setPosition(vec2)
    self.position = vec2
    return self
end

function ButtonBuilder:setRelativePosition(vec2)
    self.relativePosition = vec2
    return self
end

function ButtonBuilder:setAnchor(vec2)
    self.anchor = vec2
    return self
end

function ButtonBuilder:setText(t)
    self.text = t
    return self
end

function ButtonBuilder:onClick(callback)
    self._onClick = callback
    return self
end

function ButtonBuilder:onButtonPress(callback)
    self._onButtonPress = callback
    return self
end

function ButtonBuilder:onKeyPress(callback)
    self._onKeyPress = callback
    return self
end

function ButtonBuilder:setUserData(data)
    self.userData = data
    return self
end

function ButtonBuilder:setEvents(eventsTable)
    self.events = eventsTable
    return self
end

function ButtonBuilder:_buildEvents()
    local finalEvents = {}

    -- Merge user-defined events first
    if self.events then
        for k, v in pairs(self.events) do
            finalEvents[k] = v
        end
    end

    -- Override or add keyPress if self._onKeyPress is defined
    if self._onClick then
        finalEvents.mousePress = async:callback(function(mE, layout)
            local ok, err = pcall(self._onClick, mE, layout)
            if not ok then print("ButtonBuilder onClick error:", err) end
        end)
    end
	if self._onKeyPress then
        finalEvents.keyPress = async:callback(function(kE, layout)
            local ok, err = pcall(self._onKeyPress, kE, layout)
            if not ok then print("ButtonBuilder KeyPress error:", err) end
        end)
    end
	if self._onButtonPress then
        finalEvents.onButtonPress = async:callback(function(bE, layout)
            local ok, err = pcall(self._onButtonPress, bE, layout)
            if not ok then print("ButtonBuilder onButtonPress error:", err) end
        end)
    end

    return next(finalEvents) and finalEvents or {}
end

function ButtonBuilder:build()
    local myPad = auxUi.deepLayoutCopy(I.MWUI.templates.padding)

    --MEANS TO REVISE PADDING.
    for i = 1, #myPad.content do
        local props = myPad.content[i].props
        for k, v in pairs(props) do
            if (k == "size" or k == "position") and v then
                props[k] = v * 2
            end
        end
    end

    local textChild = {
        template = I.MWUI.templates.textNormal,
        props = {
            text = self.text,
            --relativePosition = util.vector2(0.5, 0.5),
            -- anchor = util.vector2(0.5, 0.5),
            size = self.size,
            textAlignH = ui.ALIGNMENT.Center,
            textAlignV = ui.ALIGNMENT.Center,
        },
    }
    local pad = {
        template = myPad,
        props = {},
        content = ui.content {textChild}
    }

    -- local events = {}
    -- if self._onClick then
    --     events.mousePress = async:callback(function(mE, layout)
    --         local ok, err = pcall(self._onClick, mE, layout)
    --         if not ok then print("ButtonBuilder onClick error:", err) end
    --     end)
    -- end
    -- if self._onKeyPress then
    --     events.keyPress = async:callback(function(kE, layout)
    --         local ok, err = pcall(self._onKeyPress, kE, layout)
    --         if not ok then print("ButtonBuilder KeyPress error:", err) end
    --     end)
    -- end

    local layout = {
        template = self.template,
        name = self.name,
        props = {
            size = self.size,
            position = self.position,
            relativePosition = self.relativePosition,
            anchor = self.anchor,
        },
        content = ui.content { pad },
        events = self:_buildEvents(),
        userData = self.userData
    }

    -- if events then layout.events = events end
    -- if self.userData then layout.userData = self.userData end

    return layout
end

-- ====================================================
-- textBuilder
-- ====================================================
local textBuilder = {}
textBuilder.__index = textBuilder

function textBuilder:new()
    local self = setmetatable({}, textBuilder)
    self.name = nil
    self.template = I.MWUI.templates.textNormal
    self.size = nil
    self.relativePosition = util.vector2(0,0)
    self.position = util.vector2(0,0)
    self.anchor = nil
    self.text = "PlaceHolder"
    self.userData = nil
    self.padding = false
    self.padTemplate = nil
    self.textAlignH = ui.ALIGNMENT.Center
    self.textAlignV = ui.ALIGNMENT.Center
    return self
end

function textBuilder:setName(name)
    self.name = name
    return self
end

function textBuilder:setTemplate(template)
    self.template = template
    return self
end

function textBuilder:setSize(vec2)
    self.size = vec2
    return self
end

function textBuilder:setRelativePosition(vec2)
    self.relativePosition = vec2
    return self
end

function textBuilder:setPosition(vec2)
    self.position = vec2
    return self
end

function textBuilder:setAnchor(vec2)
    self.anchor = vec2
    return self
end

function textBuilder:setText(t)
    self.text = t
    return self
end

function textBuilder:setUserData(data)
    self.userData = data
    return self
end

function textBuilder:pad(enable, num)
    self.padding = enable
    if num then
        local myPad = auxUi.deepLayoutCopy(I.MWUI.templates.padding)

        --MEANS TO REVISE PADDING.
        for i = 1, #myPad.content do
            local props = myPad.content[i].props
            for k, v in pairs(props) do
                if (k == "size" or k == "position") and v then
                    props[k] = v * num
                end
            end
        end
        
        self.padTemplate = myPad
    end
    return self
end

function textBuilder:build()
    local events = {}
    local layout = {
        template = self.template,
        name = self.name,
        props = {
            size = self.size,
            position = self.position,
            relativePosition = self.relativePosition,
            anchor = self.anchor,
            text = self.text,
        },
        content = ui.content {},
    }
    if events then layout.events = events end
    if self.userData then layout.userData = self.userData end

    -- ======================================
    -- CONDITIONAL WRAPPING
    -- ======================================
    if self.padding then
        local default = util.vector2(0,0)
        local layout2 = {
                template = self.template,
                name = self.name,
                props = {
                    text = self.text,
                    size = self.size,
                    textAlignH = self.textAlignH,
                    textAlignV = self.textAlignV,
                },
                content = ui.content {},
            }
        return {
            template = I.MWUI.templates.box,
            name = self.name .. 'Box',
            props = {
                --size = self.size,
                position = self.position,
                relativePosition = self.relativePosition,
            },
            content = ui.content{
                {
                    template = self.padTemplate or I.MWUI.templates.padding,
                    props = {
                        --size = self.size,
                        -- position = self.position,
                        -- relativePosition = self.relativePosition,
                    },
                    name = self.name .. 'Pad',
                    content = ui.content { layout2 },
                },
            }
        }
    end

    return layout
end

-- ====================================================
-- imageBuilder
-- ====================================================
local imageBuilder = {}
imageBuilder.__index = imageBuilder

function imageBuilder:new()
    local self = setmetatable({}, imageBuilder)
    self.name = nil
    self.size = nil
    self.relativePosition = nil
	self.relativeSize = util.vector2(0, 0)
    self.anchor = nil
    self.userData = nil
	self.position = util.vector2(0, 0)
	self.visible = true
	self.alpha = 1.0
	self.resourcePath = 'white'
	self.resourceSize = util.vector2(0, 0)
	self.resource = ui.texture{path = self.resourcePath, size = self.resourceSize }
	self.color = util.color.rgb(1,1,1)
	self.content = nil
    --Optional box wrapper
    self.wrapInBox = false      -- <-- NEW
    self.boxTemplate = I.MWUI.templates.box -- optional override

    return self
end

function imageBuilder:setName(name)
    self.name = name
    return self
end

function imageBuilder:setResourceDirect(resourceUiTexture)
    self.resource = resourceUiTexture
    return self
end

function imageBuilder:wrap(enable, template)
    self.wrapInBox = enable
    if template then
        self.boxTemplate = template
    end
    return self
end

function imageBuilder:setResource(resourceTable)
    self.resourcePath = resourceTable.path
    self.resourceSize = resourceTable.size or self.resourceSize
    local safeTable = {path = self.resourcePath, size = self.resourceSize}
    self.resource = ui.texture(safeTable)
    return self
end

function imageBuilder:setResourcePath(path)
    self.resourcePath = path
    self.resource = ui.texture({ path = self.resourcePath, size = self.resourceSize })
    return self
end

function imageBuilder:setResourceSize(vec2)
    self.resourceSize = vec2
    self.resource = ui.texture({ path = self.resourcePath, size = self.resourceSize })
    return self
end

function imageBuilder:setColor(rgbColor)
    self.color = rgbColor
    return self
end

function imageBuilder:setTemplate(template)
    self.template = template
    return self
end

function imageBuilder:setPosition(vec2)
    self.position = vec2
    return self
end

function imageBuilder:setSize(vec2)
    self.size = vec2
    return self
end

function imageBuilder:setRelativeSize(vec2)
    self.relativeSize = vec2
    return self
end

function imageBuilder:setRelativePosition(vec2)
    self.relativePosition = vec2
    return self
end

function imageBuilder:setAnchor(vec2)
    self.anchor = vec2
    return self
end

function imageBuilder:setUserData(data)
    self.userData = data
    return self
end

function imageBuilder:setEvents(eventsTable)
    self.events = eventsTable
    return self
end

function imageBuilder:_buildEvents()
    local finalEvents = {}

    -- Merge user-defined events first
    if self.events then
        for k, v in pairs(self.events) do
            finalEvents[k] = v
        end
    end

    -- Override or add keyPress if self._mousePress is defined
    if self._mousePress then
        finalEvents.mousePress = async:callback(function(coord, layout)
            local ok, err = pcall(self._mousePress, coord, layout)
            if not ok then print("imageBuilder KeyPress error:", err) end
        end)
    end
    -- Override or add keyPress if self._mouseRelease is defined
    if self._mouseRelease then
        finalEvents.mouseRelease = async:callback(function(_, layout)
            local ok, err = pcall(self._mouseRelease, _, layout)
            if not ok then print("imageBuilder KeyPress error:", err) end
        end)
    end
    -- Override or add keyPress if self._mouseMove is defined
    if self._mouseMove then
        finalEvents.mouseMove = async:callback(function(coord, layout)
            local ok, err = pcall(self._mouseMove, coord, layout)
            if not ok then print("imageBuilder KeyPress error:", err) end
        end)
    end

    return next(finalEvents) and finalEvents or {}
end

function imageBuilder:build()
    local events = {}
    local layout = {
		type = ui.TYPE.Image,
        name = self.name,
        props = {
            size = self.size,
            position = self.position,
            relativePosition = self.relativePosition,
            relativeSize = self.relativeSize,
            anchor = self.anchor,
            text = self.text,
            visible = self.visible,
            alpha = self.alpha,
            inheritAlpha = false,
            resource = self.resource,
            color = self.color,
        },
        content = ui.content {self.content},
        events = self:_buildEvents(),
        userData = self.userData,
    }

    -- ======================================
    -- CONDITIONAL WRAPPING
    -- ======================================
    if self.wrapInBox then
        return {
            template = self.boxTemplate,
            name = self.name .. 'Box',
            props = {
                size = self.size,
                position = self.position,
                relativePosition = self.relativePosition,
                relativeSize = self.relativeSize,
                anchor = self.anchor,
            },
            content = ui.content{ layout }
        }
    end

    return layout
end

-- ====================================================
-- Return builders
-- ====================================================
return {
    BoxBuilder = BoxBuilder,
    ButtonBuilder = ButtonBuilder,
    textBuilder = textBuilder,
    imageBuilder = imageBuilder
}
