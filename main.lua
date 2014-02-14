require("util/helper")
require("util/resources")
require("scene/world")
require("scene/entity")

Particle = class("Particle", Entity)
function Particle:__init(pos, vel, color)
    Entity.__init(self)
    self.position = pos
    self.velocity = vel
    self.color = color
end

function Particle:onUpdate(dt)
    if self.lifetime > 1 then
        self:kill()
    end
end

function Particle:onDraw()
    local r, g, b = unpack(self.color)
    love.graphics.setColor(r, g, b, (1-self.lifetime) * 255)
    local img = resources.images.blur
    love.graphics.setBlendMode("additive")
    love.graphics.draw(img, self.position.x, self.position.y, self.rotation, 
        1, 1, img:getWidth() / 2, img:getHeight() / 2)
    love.graphics.setBlendMode("alpha")
end

--------------------------------------------------------------------------------

Player = class("Player")

function Player:__init(id)
    self.world = World()
    self.color = {255 * (1 - id), 255 * id, 0}
    self.offset = Vector(love.graphics.getWidth() * id, love.graphics.getHeight() / 2)
    self.rotation = math.pi / 2 - math.pi * id
    self.id = id
    self.activity = 0
    self.cooldown = 0
end

function Player:draw()
    love.graphics.push()
    love.graphics.translate(self.offset.x, self.offset.y)
    love.graphics.scale(SCALE, SCALE)
    love.graphics.rotate(self.rotation)
    love.graphics.setScissor(self.id * love.graphics.getWidth() / 2, 0, love.graphics.getWidth() / 2, love.graphics.getHeight())

    -- entities
    self.world:draw()

    -- text
    local t = state .. " " .. math.round(self.activity, 3)
    love.graphics.setFont(resources.fonts.default)
    love.graphics.setColor(255, 255, 255)
    local s = 1/(SCALE * (1 + 0.1 * getPulse()))
    love.graphics.print(t, -resources.fonts.default:getWidth(t)/2*s, -HEIGHT+10, 0, s, s)
    love.graphics.rectangle("fill", -0.1, -HEIGHT+0.01, 0.2, 0.5)

    -- circle
    love.graphics.setColor(unpack(self.color))
    love.graphics.circle("fill", 0, 0, 10, 32)

    love.graphics.pop()
end

function Player:update(dt)
    self.world:update(dt)
    self.activity = math.max(0, self.activity * (1 - dt))

    self.cooldown = self.cooldown - dt
    if self.cooldown < 0 then
        self.world:add(Particle(Vector(0, 0), Vector(0, -300), self.color))
        self.cooldown = 1/self.activity
    end
end

function Player:active()
    self.activity = math.min(1, self.activity + 0.1)
end

--------------------------------------------------------------------------------

resources = Resources("data/")
state = "TAP"
TIME = 0
players = {Player(0), Player(1)}


--------------------------------------------------------------------------------

function getPulse()
    if math.sin(TIME * math.pi * 2 * 4) < 0.9 then
        return 1
    else
        return 0
    end
end

function love.load()
    resources:addFont("default", "BD_Cartoon_Shout.ttf", 80)
    resources:addImage("blur", "blur.png")
    resources:load()
end

function love.update(dt)
    TIME = TIME + dt
    SCALE = love.graphics.getHeight() / 200
    HEIGHT = love.graphics.getWidth() / 2 / SCALE

    for i,p in pairs(players) do
        p:update(dt)
    end 
end

function love.touchpressed(id, x, y, p)
    local p = x < 0.5 and 1 or 2
    players[p]:active()
end

function love.draw()
    for i,p in pairs(players) do
        p:draw()
    end 
end
