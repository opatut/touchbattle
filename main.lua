require("util/helper")
require("util/resources")
require("scene/world")
require("scene/entity")
tween = require("external/tween")

COLORS = {}
for i=1,12 do
    table.insert(COLORS, pack(hsl2rgb((i-1)/12, 1, 0.5)))
end
-- COLORS = {
--     {255, 200, 0},
--     {0, 100, 255},
--     {255, 0, 0},
--     {140, 0, 230},
--     {100, 255, 50},
--     {255, 160, 30},
--     {255, 0, 255},
--     {
--     {255, 200, 0},
--     {0, 100, 255},
--     {255, 0, 0},
--     {128, 0, 200}
-- }

MODES = {}
MODES.SELECT_COLOR = "select color"
MODES.READY = "ready"
MODES.TAP = "tap"
MODES.SWIPE = "swipe"
MODES.SPIN = "spin"
MODES.WIN = "victory"
MODES.LOSE = "defeat"

--------------------------------------------------------------------------------

function getTouches()
    local function _getTouches()
        local touches = {}
        for i=1,love.touch.getTouchCount() do
            local id, x, y, p = love.touch.getTouch(i)
            local touch = {}
            touch.id = id
            touch.x = x * love.graphics.getWidth()
            touch.y = y * love.graphics.getHeight()
            touch.p = p
            table.insert(touches, touch)
        end
        return touches
    end

    local e, r = pcall(_getTouches)
    return e and r or {}
end

function getPulse()
    if math.sin(TIME * math.pi * 2 * 4) < 0.9 then
        return 1
    else
        return 0
    end
end

--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------

Player = class("Player")

function Player:__init(id)
    self.world = World()
    self.overlay = World()

    self.color = COLORS[id+1]
    self.rotation = math.pi / 2 - math.pi * id
    self.id = id
    self.activity = 0
    self.cooldown = 0
    self.lastActive = -1000
    self.mode = MODES.SELECT_COLOR
    self.modeTime = 0
    self.percent = 0.5

    self.stats = {}
    self.stats.touches = 0

    self.modeLabel = Label(self.mode, Vector(0, 0))
    self.overlay:add(self.modeLabel)

    self.countdownLabel = Label("?", Vector(0, 0), nil, resources.fonts.large)
    self.countdownLabel.visible = false
    self.overlay:add(self.countdownLabel)

    self.p = love.graphics.newParticleSystem(resources.images.blur)

    -- prepare color buttons
    local cols = 4
    local rows = math.ceil(#COLORS / cols)
    local d = 200 / (cols+1)
    for i, c in pairs(COLORS) do
        local row = (i-1) % rows
        local col = math.floor((i-1) / rows)
        local button = ColorButton(Vector(d * (col - (cols-1) / 2), - (2.8-row) * d), c, i)
        button.onTouchReleased = function(data)
            for k,b in pairs(self.world:findByType("ColorButton")) do
                tween(0.4, b, {size={x=0,y=0}, rotation=math.pi}, "outSine", function() b:kill() end)
            end

            for _,b in pairs(self:other().world:findByType("ColorButton")) do
                if b.id == button.id then
                    b.active = false
                end
            end

            self.color = button.color
            self:setMode(MODES.READY)
            self:start()
        end
        self.world:add(button)
    end
end

function Player:other()
    return self.id == 0 and players[2] or players[1]
end

function Player:setMode(mode)
    if mode == self.mode then return end

    local y = self.modeLabel.position.y
    local time = 0.2
    self.mode = mode
    self.modeTime = 0
    tween(time, self.modeLabel, {position={x=200, y=y}}, "inQuad", function()
        self.modeLabel.position.x = -200
        self.modeLabel.text = self.mode
        tween(time, self.modeLabel, {position={x=0, y=y}}, "inQuad")
    end)
end

function Player:start()
    self.p:setColors(
        self.color[1], self.color[2], self.color[3], 255, 
        255, 255, 255, 0)
    self.p:setParticleLifetime(0.7, 1)
    self.p:setDirection(-math.pi / 2)
    self.p:setSpread(-1, 1)
    self.p:setSpeed(300, 400)
    self.p:setRadialAcceleration(-300)
    self.p:setSizes(1, 0.2, 2)
    self.p:setAreaSpread("uniform", 100, 0)
end

function Player:pushMatrix()
    love.graphics.push()
    love.graphics.translate(self.offset.x, self.offset.y)
    love.graphics.scale(SCALE, SCALE)
    love.graphics.rotate(self.rotation)
    --love.graphics.setScissor(self.id * love.graphics.getWidth() / 2, 0, love.graphics.getWidth() / 2, love.graphics.getHeight())
end

function Player:draw()
    self:pushMatrix()

    -- background
    -- love.graphics.setColor(255, 255, 255, 100)
    -- love.graphics.rectangle("fill", -100, -HEIGHT, 200, HEIGHT)

    -- entities
    self.world:draw()

    -- gradient
    love.graphics.setColor(unpack(self.color))
    local h = self.activity * HEIGHT * 0.1
    love.graphics.draw(resources.images.gradient, -100, -h, 0, 100, h/2)

    love.graphics.setBlendMode("additive")
    love.graphics.draw(self.p)
    love.graphics.setBlendMode("alpha")

    love.graphics.pop()
end

function Player:drawOverlay()
    self:pushMatrix()
    self.overlay:draw()
    love.graphics.pop()
end

function Player:update(dt)
    self.modeTime = self.modeTime + dt

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
        local speed = HEIGHT * 4 * self.percent
        self.p:setSpeed(speed, speed * 1.2)
        self.p:setRadialAcceleration(-speed * 1.1)
        self.p:setEmissionRate(500 * self.activity)
    end
    self.p:update(dt)


    local other = self:other()
    if self.mode == MODES.READY then
        if other.mode == MODES.READY then
            self.modeTime = p1.modeTime
            if self.modeTime > 1.5 then
                self:setMode(MODES.TAP)
                other:setMode(MODES.TAP)
            end
        else
            self.modeTime = 0
        end
    end

    -- mode label
    -- self.modeLabel.scale.x = 1 - 0.02 * getPulse()
    self.modeLabel.scale.x = 0.99 + 0.02 * math.sin(TIME * math.pi * 2 * 2)
    self.modeLabel.scale.y = 0.95 + 0.10 * math.sin(math.pi + TIME * math.pi * 2 * 2)
    self.modeLabel.position.y = - HEIGHT + self.modeLabel.font:getHeight() / SCALE
    if self.mode == MODES.WIN or self.mode == MODES.LOSE then
        self.modeLabel.color = self.color
    end

    -- countdown label
    if self.mode == MODES.READY then 
        -- self.countdownLabel.scale = 2 - getPulse() * 0.1
        self.countdownLabel.text = string.format("%d", 3 - math.floor(self.modeTime * 2))
        self.countdownLabel.position.y = - HEIGHT / 2
        self.countdownLabel.visible = true
    else
        self.countdownLabel.visible = false
    end

end

function Player:active(strength, x)
    self.activity = math.min(1, self.activity + strength)
    self.lastActive = TIME
end

function Player:touchpressed(id, x, y, p)
    local p = self:screenToLocal(Vector(x * love.graphics.getWidth(), y * love.graphics.getHeight()))
    if p.y > -HEIGHT then
        -- activity
        if self.mode == MODES.TAP then
            self:active(0.1, p.x)
            self.stats.touches = self.stats.touches + 1
        end
    end

    self.world:handleEvent("touchpressed", {id=id, x=p.x, y=p.y, p=p})
end

function Player:touchreleased(id, x, y, p)
    local p = self:screenToLocal(Vector(x * love.graphics.getWidth(), y * love.graphics.getHeight()))
    self.world:handleEvent("touchreleased", {id=id, x=p.x, y=p.y, p=p})
end

function Player:touchmoved(id, x, y, p)
    local p = self:screenToLocal(Vector(x * love.graphics.getWidth(), y * love.graphics.getHeight()))
    self.world:handleEvent("touchmoved", {id=id, x=p.x, y=p.y, p=p})
end

function Player:screenToLocal(screen)
    return ((screen - self.offset) / SCALE):rotated(-self.rotation)
end

function Player:adjustPercent(change)
    self.percent = self.percent + change
    if self.percent >= 1 then
        self:win()
    elseif self.percent <= 0 then
        self:lose()
    end
end

function Player:win()
    if self.mode ~= MODES.WIN then
        self:setMode(MODES.WIN)
        self:displayStats()
    end
end

function Player:lose()
    if self.mode ~= MODES.LOSE then
        self:setMode(MODES.LOSE)
        self:displayStats()
    end
end

function Player:displayStats()
    local l = Label(string.format("%d times tapped\n\nTouch center to restart", self.stats.touches), Vector(0, -HEIGHT/2))
    l.scale = Vector(0.5, 0.5)
    self.overlay:add(l)
end

--------------------------------------------------------------------------------

resources = Resources("data/")
TIME = 0
players = {}
p1, p2 = nil, nil

--------------------------------------------------------------------------------

function love.load()
    resources:addFont("default", "BD_Cartoon_Shout.ttf", 70)
    resources:addFont("large", "BD_Cartoon_Shout.ttf", 160)
    resources:addFont("small", "BD_Cartoon_Shout.ttf", 40)
    resources:addImage("blur", "blur.png")
    resources:addImage("star", "star.png")
    resources:addImage("colorbutton", "color-button.png")
    resources:makeGradientImage("gradient", {255, 255, 255, 0}, {255, 255, 255, 255}, false)
    resources:addShader("border", "border.glsl")
    resources:load()

    reset()
end

function reset()
    players = {Player(0), Player(1)}
    p1, p2 = players[1], players[2]
    TIME = 0
end

function love.update(dt)
    TIME = TIME + dt
    SCALE = love.graphics.getHeight() / 200
    HEIGHT = love.graphics.getWidth() / 2 / SCALE

    for i,p in pairs(players) do
        p:update(dt)
    end 

    local diff = p1.activity - p2.activity
    local change = diff * dt * 0.1 * math.pow(TIME/10, 2)
    p1:adjustPercent(change)
    p2:adjustPercent(-change)

    tween.update(dt)
end

function love.touchpressed(id, x, y, p)
    for i,p in pairs(players) do
        p:touchpressed(id, x, y, p)
    end

    if x > 0.45 and x < 0.55 and y > 0.4 and y < 0.6 then
        reset()
    end
end

function love.touchreleased(id, x, y, p)
    for i,p in pairs(players) do
        p:touchreleased(id, x, y, p)
    end
end

function love.touchmoved(id, x, y, p)
    for i,p in pairs(players) do
        p:touchmoved(id, x, y, p)
    end
end

function love.draw()
    for i,p in pairs(players) do
        p:draw()
    end 

    for i,p in pairs(players) do
        p:drawOverlay()
    end 

    love.graphics.setColor(255, 255, 255, 100)
    local n = 20.5
    local x = love.graphics.getWidth() * 0.5
    for i=0,n do
        love.graphics.line(x, love.graphics.getHeight() * i / n, x, love.graphics.getHeight() * (i+0.5) / n)
        love.graphics.line(x, love.graphics.getHeight() * i / n, x, love.graphics.getHeight() * (i+0.5) / n)
    end

    x = love.graphics.getWidth() * p1.percent
    love.graphics.line(x-3, 0, x-3, love.graphics.getHeight())
    love.graphics.line(x+3, 0, x+3, love.graphics.getHeight())
end
