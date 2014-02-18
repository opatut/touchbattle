require("util/helper")
require("scene/entity")

Label = class("Label", Entity)
function Label:__init(text, pos, color, font)
    Entity.__init(self)
    self.text = text
    self.position = pos
    self.color = color or {255, 255, 255}
    self.font = font or resources.fonts.default
    self.scale = Vector(1, 1)
    self.z = 10000
end

function Label:onDraw()
    local shader = resources.shaders.border
    local s = self.scale / SCALE
    local w = self.font:getWidth(self.text)
    local h = self.font:getHeight()

    shader:send("size", {w/self.scale.x, h/self.scale.y})

    -- draw
    love.graphics.setColor(unpack(self.color))
    love.graphics.setFont(self.font)
    love.graphics.setShader(shader)
    love.graphics.printf(self.text, self.position.x - w / 2 * s.x, self.position.y - h / 2 * s.y, w, "center", self.rotation, s.x, s.y)

    -- cleanup
    love.graphics.setShader()
end

