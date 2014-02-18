require("util/helper")
require("util/resources")
require("scene/world")
require("scene/entity")
tween = require("external/tween")

require("constants")
require("colorbutton")
require("label")
require("player")

function getPulse()
    if math.sin(TIME * math.pi * 2 * 4) < 0.9 then
        return 1
    else
        return 0
    end
end

resources = Resources("data/")
TIME = 0
players = {}
p1, p2 = nil, nil
playing = false
modeDuration = 0
modeTime = 0

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

function nextMode()
    modeDuration = math.random() * 10 + 5
    modeTime = 0
    local modes = {MODES.TAP, MODES.SPIN}
    local mode, oldMode = nil, p1.mode

    repeat
        mode = modes[math.random(#modes)]
    until mode ~= oldMode

    p1:setMode(mode)
    p2:setMode(mode)
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

    if playing then
        modeTime = modeTime + dt
        if modeTime >= modeDuration then
            nextMode()
        end
    end

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

function love.keypressed(k)
    if k == "escape" then
        love.event.quit()
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

    if modeDuration and playing then
        local p = modeTime / modeDuration
        local x = love.graphics.getWidth() * 0.5
        love.graphics.setColor(0, 255, 0)
        love.graphics.rectangle("fill", x - 4, love.graphics.getHeight() * (0.5 - 0.5 * p), 8, love.graphics.getHeight() * p)
    end
end
