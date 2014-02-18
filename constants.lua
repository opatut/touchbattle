-- CONSTANTS

require("util/helper")

-- generate 12 rainbow colors
COLORS = {}
for i=1,12 do
    table.insert(COLORS, pack(hsl2rgb((i-1)/12, 1, 0.5)))
end

-- mode strings
MODES = {}
MODES.SELECT_COLOR = "select color"
MODES.READY = "ready"
MODES.TAP = "tap"
MODES.SWIPE = "swipe"
MODES.SPIN = "spin"
MODES.WIN = "victory"
MODES.LOSE = "defeat"

-- tweak settings
SPIN_MIN_RADIUS = 20 -- width: 200
METER_PER_PIXEL = 1/2800 -- 72 dpi = ~28 dots per cm