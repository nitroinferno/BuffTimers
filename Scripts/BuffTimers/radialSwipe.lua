local ui = require('openmw.ui')
local vector2 = require('openmw.util').vector2
local shader = {}

shader.radialWipe = function(fx, iconSize)
    if not fx.duration or fx.durationLeft <= 0 then return end
    local myAtlas = 'textures/radial/partial_invert.png' -- a 4096x4096 atlas
    local offset = 204 -- each square is 204 x 204
    local durL = fx.durationLeft
    local dur = fx.duration
    local maxDegree = 360
    local position = math.floor((durL / dur) * maxDegree) -- determine the corresponding tile from thr 360 tiles
    local col = position % 20 -- Determine remainder to get x tile position; the tile images is 20 x 20
    local colOffset = col * offset -- multiply by tile width
    local row = math.floor(position/20) -- determine which row we're in on atlas map
    local rowOffset = row * offset -- multiply row by height of tile
    local texture1 = ui.texture { -- texture in the top left corner of the atlas
        path = myAtlas,
        offset = vector2(0, 0),
        size = vector2(0, 0),
    }
    local texture2 = ui.texture { -- texture in the top right corner of the atlas
        path = myAtlas,
        offset = vector2(colOffset, rowOffset),
        size = vector2(iconSize, iconSize),
    }
	return texture2
end

shader.Overlay = function(atlasMap,iconSize)

local radialSwipeOverlay = {
  name = "RadialSwipe",
  type = ui.TYPE.image,
  props = {
      size = v2(iconSize, iconSize),
      visible = true,
      alpha = 1,
      inheritAlpha = false,
      resource = atlasMap
      },
  events = {
	  -- Some events perhaps mouseover Tooltip
  },
}

return radialSwipeOverlay

end

return shader