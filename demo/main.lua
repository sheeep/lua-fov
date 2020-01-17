local polygonSegments = require "map"
local uniquePoints

function getUniquePolygonSegments(segments)
    local uniqueTable = {}
    local hash = {}

    for _, segment in ipairs(polygonSegments) do
        local x1, y1, x2, y2 = unpack(segment)

        local keyFrom = "x:" .. x1 .. ",y:" .. y1
        local keyTo = "x:" .. x2 .. ",y:" .. y2

        if hash[keyFrom] == nil then
            hash[keyFrom] = true
            table.insert(uniqueTable, {x1, y1})
        end

        if hash[keyTo] == nil then
            hash[keyTo] = true
            table.insert(uniqueTable, {x2, y2})
        end
    end

    return uniqueTable
end

function getSightPolygon(x, y)
end

function love.load()
    uniquePoints = getUniquePolygonSegments(polygonSegments)

    print(uniquePoints)
    print(unpack(uniquePoints))
end

function love.draw()
    for _, segment in ipairs(polygonSegments) do
        -- Draw polygon segments
        love.graphics.setColor(255, 0, 0)
        love.graphics.line(unpack(segment))
    end

    -- Draw player
    love.graphics.setColor(0, 255, 0)
    love.graphics.circle("fill", love.mouse.getX(), love.mouse.getY(), 5)
end
