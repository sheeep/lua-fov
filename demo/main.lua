-- Error at: 160/215
-- Strange polygon at: 166/249, 185/254
-- ^-- appears to come from parallel stuff

local polygonSegments = require "map"
local fuzzyRadius = 10
local uniquePoints
local sightPolygons, drawPolygons

function getIntersection(ray, segment)
    -- Ray in parametric view
    local r_pX = ray.from.x
    local r_pY = ray.from.y
    local r_dX = ray.to.x - r_pX
    local r_dY = ray.to.y - r_pY

    -- Sometimes, ray.to.x and ray.form.x come to close together
    -- which makes r_dX = 0, later on we need this value as a divisor
    -- so it really can't be 0 at all.
    if (r_dX == 0) then
        r_dX = 0.00001
    end

    if (r_dY == 0) then
        r_dY = 0.00001
    end

    -- Segment in parametric view
    local s_x1, s_y1, s_x2, s_y2 = unpack(segment)

    local s_pX = s_x1;
    local s_pY = s_y1;
    local s_dX = s_x2 - s_x1;
    local s_dY = s_y2 - s_y1;

    -- Are they parallel? If so, no intersect
    local r_mag = math.sqrt(r_dX * r_dX + r_dY * r_dY);
	local s_mag = math.sqrt(s_dX * s_dX + s_dY * s_dY);

    if r_dX / r_mag == s_dX / s_mag and r_dY / r_mag == s_dY / s_mag then
        return nil;
	end

    local T2 = (r_dX * (s_pY - r_pY) + r_dY * (r_pX - s_pX)) / (s_dX * r_dY - s_dY * r_dX)
    local T1 = (s_pX + s_dX * T2 - r_pX) / r_dX;

    if T1 < 0 then
        return nil
    end

    if T2 < 0 or T2 > 1 then
        return nil
    end

    return {
        x = r_pX + r_dX * T1,
        y = r_pY + r_dY * T1,
        param = T1
    }
end

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

function getUniqueAnglesFromPoints(points, x, y)
    local angles = {}

    for _, point in ipairs(points) do
        local pX, pY = unpack(point)
        local angle = math.atan2(pY - y, pX - x);

        table.insert(angles, angle - 0.00001)
        table.insert(angles, angle)
        table.insert(angles, angle + 0.00001)
    end

    return angles
end

function getSightPolygon(points, x, y)
    -- Get unique angles
    local angles = getUniqueAnglesFromPoints(points, x, y)
    local intersects = {}

    for _, angle in ipairs(angles) do
        -- Calculate dx and dy from angle
        local dX = math.cos(angle)
        local dY = math.sin(angle)

        -- Create a ray from x/y
        local ray = {
            from = {
                x = x,
                y = y
            },
            to = {
                x = x + dX,
                y = y + dY
            }
        }

        local closestIntersect
        for _, polygonSegment in ipairs(polygonSegments) do
            local intersect = getIntersection(ray, polygonSegment)

            if intersect then
                if closestIntersect == nil or intersect.param < closestIntersect.param then
                    closestIntersect = intersect
                end
            end
        end

        if closestIntersect then
            closestIntersect.angle = angle

            table.insert(intersects, closestIntersect)
        end
    end

    table.sort(intersects, function(a, b)
        return a.angle < b.angle
    end)

    return intersects
end

function love.load()
    love.graphics.setBackgroundColor(255, 255, 255, 1)

    uniquePoints = getUniquePolygonSegments(polygonSegments)
end

function love.update(dt)
    sightPolygons = {}
    drawPolygons = {}

    table.insert(sightPolygons, getSightPolygon(uniquePoints, love.mouse.getX(), love.mouse.getY()))

    for angle = 0, math.pi * 2, (math.pi * 2) / 10 do
        local dX = math.cos(angle) * fuzzyRadius;
        local dY = math.sin(angle) * fuzzyRadius;

        -- table.insert(sightPolygons, getSightPolygon(uniquePoints, love.mouse.getX() + dX, love.mouse.getY() + dY))
    end

    for key, sightPolygon in ipairs(sightPolygons) do
        local polygon = {}

        for key, value in ipairs(sightPolygon) do
            table.insert(polygon, value.x)
            table.insert(polygon, value.y)
        end

        local status, triangles = pcall(love.math.triangulate, polygon)

        if status == true then
            for _, triangle in ipairs(triangles) do
                table.insert(drawPolygons, triangle)
            end
        else
            -- print(unpack(polygon))
            print("Could not triangulate polygon at: " .. love.mouse.getX() .. "/" .. love.mouse.getY())
        end
    end

    love.window.setTitle("Demo (running at " .. love.timer.getFPS() .. " fps, mP: " .. love.mouse.getX() ..  "/" .. love.mouse.getY() .. ")")
end

function love.draw()

    for _, point in ipairs(uniquePoints) do
        love.graphics.setColor(0, 255, 0)
        love.graphics.line(point[1], point[2], love.mouse.getX(), love.mouse.getY())
    end

    for _, segment in ipairs(polygonSegments) do
        -- Draw polygon segments
        love.graphics.setColor(255, 0, 0)
        love.graphics.line(unpack(segment))
    end

    love.graphics.setColor({ 0, 0, 0, 0.1})
    for _, triangle in ipairs(drawPolygons) do
        love.graphics.polygon("fill", triangle)
    end

    -- Draw player
    love.graphics.setColor(0, 255, 0)
    love.graphics.circle("fill", love.mouse.getX(), love.mouse.getY(), 5)
end
