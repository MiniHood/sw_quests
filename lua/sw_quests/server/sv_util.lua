print("Loaded sv_util.lua")

--- Returns the ground position
---@param pos Vector The position of the hittrace
---@return Vector Position The position of the ground
util.FindGroundPosition = function(pos)
    local trace = util.TraceLine({
        start = pos,
        endpos = pos - Vector(0, 0, 1000),
        filter = function(ent) return ent:IsWorld() end
    })
    return trace.HitPos
end

--- Checks if a position is within a min and max bound. This doesn't check the Y axis
---@param pos Vector The position to be checked
---@param minBound Vector The minimum bound
---@param maxBound Vector The maximum bound
---@return boolean IsWithinBounds If the position is within the X & Z axis of the bounds.
util.IsWithinBounds = function(pos, minBound, maxBound)
    if not pos then return false end
    if not minBound then return false end
    if not maxBound then return false end
    return pos.x >= minBound.x and pos.x <= maxBound.x and
    pos.y <= minBound.y and pos.y >= maxBound.y and
           pos.z >= minBound.z and pos.z <= maxBound.z
end

--- Spawns an NPC randomly around the map and returns the entity it has spawned
---@param ent_class string What should we spawn?
---@return EntClass ENTITY Returns the entity
util.SpawnNPCAnywhere = function(ent_class)
    local navPos = navmesh.GetAllNavAreas()
    local selectedPos = nil
    local randomindex = math.random(1, 100)
    local index = 0

    for key, value in pairs(navPos) do
        index = index + 1
        if index == randomindex then
            selectedPos = value
        end
    end

    local rEnt = ents.Create(ent_class) 
    local randomPoint = selectedPos:GetRandomPoint()
    randomPoint.y = randomPoint.y - 20
    rEnt:SetPos(selectedPos:GetRandomPoint())

    rEnt:Spawn()

    return rEnt
end
