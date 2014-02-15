require("util/helper")
require("util/resources")
require("scene/world")
require("scene/entity")

COLORS = {
    {255, 200, 0},
    {0, 100, 255}
}

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
    self.color = COLORS[id+1]
    self.rotation = math.pi / 2 - math.pi * id
    self.id = id
    self.activity = 0
    self.cooldown = 0
    self.lastActive = -1000

    self.p = love.graphics.newParticleSystem(resources.images.blur)
    self.p:setColors(
        self.color[1], self.color[2], self.color[3], 255, 
        --self.color[1], self.color[2], self.color[3], 100, 
        255, 255, 255, 0)
    self.p:setParticleLifetime(0.8, 1)
    self.p:setDirection(-math.pi / 2)
    self.p:setSpread(-0.5, 0.5)
    self.p:setSpeed(300, 400)
    self.p:setRadialAcceleration(-300)
    self.p:setSizes(1, 0.2, 2)
    self.p:setAreaSpread("normal", 100, 0)
end

function Player:draw()
    love.graphics.push()
    love.graphics.translate(self.offset.x, self.offset.y)
    love.graphics.scale(SCALE, SCALE)
    love.graphics.rotate(self.rotation)
    --love.graphics.setScissor(self.id * love.graphics.getWidth() / 2, 0, love.graphics.getWidth() / 2, love.graphics.getHeight())


    -- background
    if TIME - self.lastActive < 0.02 then
        love.graphics.setColor(255, 255, 255, 20)
        love.graphics.rectangle("fill", -100, -HEIGHT, 200, HEIGHT)
    end

    -- entities
    self.world:draw()

    -- text
    local t = state
    love.graphics.setFont(resources.fonts.default)
    love.graphics.setColor(255, 255, 255)
    local s = 1/(SCALE * (1 + 0.1 * getPulse()))
    love.graphics.print(t, -resources.fonts.default:getWidth(t)/2*s, -HEIGHT+10, 0, s, s)

    -- gradient
    love.graphics.setColor(unpack(self.color))
    local h = self.activity * HEIGHT * 0.1
    love.graphics.draw(resources.images.gradient, -100, -h, 0, 100, h/2)

    love.graphics.setBlendMode("additive")
    love.graphics.draw(self.p)
    love.graphics.setBlendMode("alpha")

    love.graphics.pop()
end

function Player:update(dt)
    -- fix offset when rotating
    self.offset = Vector(love.graphics.getWidth() * self.id, love.graphics.getHeight() / 2)

    self.world:update(dt)
    self.activity = math.max(0, self.activity * (1 - dt*1))

    self.cooldown = self.cooldown - dt
    if self.cooldown < 0 then
        -- self.world:add(Particle(Vector(0, 0), Vector(0, -300), self.color))
        self.cooldown = 1/self.activity
    end

    if self.activity < 0.01 then
        self.p:pause()
    else
        self.p:start()
        self.p:setEmissionRate(500 * self.activity)
    end
    self.p:update(dt)
end

function Player:active(strength, x)
    self.activity = math.min(1, self.activity + strength)
    self.lastActive = TIME
end

--------------------------------------------------------------------------------

resources = Resources("data/")
state = "TAP"
TIME = 0
players = {}

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
    resources:addImage("star", "star.png")
    resources:makeGradientImage("gradient", {255, 255, 255, 0}, {255, 255, 255, 255}, false)
    resources:load()

    players = {Player(0), Player(1)}
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
    local yp = 200 * y - 100
    players[p]:active(0.1, p == 1 and yp or -yp)
end

function love.draw()
    for i,p in pairs(players) do
        p:draw()
    end 

    love.graphics.setColor(255, 255, 255, 100)
    local n = 20.5
    for i=0,n do
        love.graphics.line(love.graphics.getWidth() / 2, love.graphics.getHeight() * i / n, love.graphics.getWidth() / 2, love.graphics.getHeight() * (i+0.5) / n)
    end
end
