require("util/helper")
require("scene/entity")

ColorButton = class("ColorButton", Entity)
function ColorButton:__init(pos, color, id)
    Entity.__init(self)
    self.position = pos
    self.color = {color[1], color[2], color[3], 255}
    self.id = id
    self.size = Vector(32, 32)
    self.z = 1000
    self.active = true

    self.onTouchPressed = nil
    self.onTouchReleased = nil
    self.touchedDownId = -1
    self.touchedDown = false
end

function ColorButton:isInside(p)
    return p.x >= self.position.x - self.size.x / 2 and 
        p.x <= self.position.x + self.size.x / 2 and 
        p.y >= self.position.y - self.size.y / 2 and 
        p.y <= self.position.y + self.size.y / 2
end

function ColorButton:onDraw()
    local c = self.touchedDown and {255, 255, 255} or 
        self.active and self.color or
        {120, 120, 120}
    love.graphics.setColor(unpack(c))
    local img = resources.images.colorbutton
    love.graphics.draw(img, self.position.x, self.position.y, self.rotation, self.size.x / img:getWidth(), self.size.y / img:getHeight(), img:getWidth() / 2, img:getHeight() / 2)
    -- love.graphics.rectangle("fill", self.position.x - self.size / 2, self.position.y - self.size / 2, self.size, self.size)
end

function ColorButton:onEvent(type, data)
    if type == "touchpressed" then
        if(self:isInside(Vector(data.x, data.y))) then
            self:handleTouchPressed(data)
            self.touchedDownId = data.id
            self.touchedDown = true
        end
    elseif type == "touchreleased" then
        if data.id == self.touchedDownId then
            if self:isInside(Vector(data.x, data.y)) then
                self:handleTouchReleased(data)
            end
            self.touchedDownId = -1
            self.touchedDown = false
        end
    elseif type == "touchmoved" then
        if data.id == self.touchedDownId then 
            self.touchedDown = self:isInside(Vector(data.x, data.y))
        end
    end
end

function ColorButton:handleTouchPressed(data)
    if self.active and self.onTouchPressed then self:onTouchPressed(data) end
end

function ColorButton:handleTouchReleased(data)
    if self.active and self.onTouchReleased then self:onTouchReleased(data) end
end
