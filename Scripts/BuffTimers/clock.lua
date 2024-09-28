local ui = require('openmw.ui')
local async = require('openmw.async')
local util = require('openmw.util')
local input = require('openmw.input')
local calendar = require('openmw_aux.calendar')
local time = require('openmw_aux.time')
local I = require('openmw.interfaces')

local v2 = util.vector2

local textLayout = {
  type = ui.TYPE.Text,
  template = I.MWUI.templates.textNormal,
  props = {
    text = calendar.formatGameTime('%H:%M'),
  },
}

local layout = {
  layer = 'HUD',
  template = I.MWUI.templates.boxTransparent,
  props = {
    position = v2(0, 0),
    relativePosition = v2(1, 0),
    anchor = v2(1, 0),
  },
  content = ui.content {
    {
      template = I.MWUI.templates.padding,
      content = ui.content {
        textLayout,
      },
    },
  }
}

local element = ui.create(layout)

local function updateTime()
  if not element then return end
  textLayout.props.text = calendar.formatGameTime('%H:%M')
  element:update()
end

local timer = nil
local function startUpdating()
  timer = time.runRepeatedly(updateTime, 1 * time.minute, { type = time.GameTime })
end
local function stopUpdating()
  if timer then
    timer()
    timer = nil
  end
end

startUpdating()

return {
  engineHandlers = {
    onKeyPress = function(key)
      if key.code == input.KEY.O then
        if element then
          element:destroy()
          element = nil
          stopUpdating()
        else
          element = ui.create(layout)
          startUpdating()
        end
      end
    end,
  }
}
