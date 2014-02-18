require("util/helper")
require("util/resources")
require("scene/world")

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

