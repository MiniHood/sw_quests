print("Loaded sh_towns.lua")
include("../server/sv_util.lua")

Towns = {}
Towns.__index = Towns

Towns.Instances = {}

function Towns:new(key, configData)
    local self = setmetatable({}, Towns)
    self.Key = key
    self.Name = configData.Name
    self.ShowNameOnEntry = configData.ShowNameOnEntry
    self.MinBound = configData.MinBound
    self.MaxBound = configData.MaxBound
    self.MaxNPCs = configData.AmountOfNPCS
    self.NPCsSpawned = false  
    self.PlayersInside = {}

    table.insert(Towns.Instances, self)

    if SERVER then
        local function spawnNPCs()
            for i = 1, self.MaxNPCs do
                print("Spawning NPC in " .. self.Name)
                timer.Simple(i * 2, function() 
                    local pos
                    local attempts = 0
                    repeat
                        pos = Vector(
                            math.random(self.MinBound.x, self.MaxBound.x),
                            math.random(self.MinBound.y, self.MaxBound.y),
                            math.random(self.MinBound.z, self.MaxBound.z)
                        )
                        pos = util.FindGroundPosition(pos)
                        attempts = attempts + 1
                    until (util.IsWithinBounds(pos, self.MinBound, self.MaxBound) and pos ~= Vector(0, 0, 0)) or attempts > 10  

                    if util.IsWithinBounds(pos, self.MinBound, self.MaxBound) then
                        local button = ents.Create("wandering_civ")
                        button:SetPos(pos)
                        button:Spawn()
                    else
                        print("Failed to find a valid position for NPC after 10 attempts.")
                    end
                end)
            end
        end

        -- Allowing time for the functions to be added to the metatable to avoid any errors when somebody first joins.
        timer.Simple(10, function ()
            timer.Create(self.Key .. "_checkforplayers", 1, -1, function ()
                for index, value in ipairs(player.GetAll()) do
                    if util.IsWithinBounds(value:GetPos(), self.MinBound, self.MaxBound) then
                        if not table.HasValue(self.PlayersInside, value) then
                            table.insert(self.PlayersInside, value)
                            print("Player is in, sending MainNotify")
                            net.Start("SWQ:MainNotify")
                                net.WriteString("Now entering " .. self.Name)
                                net.WriteString("You have " .. value.Reputation[self.Key] .. ' reputation.')
                            net.Send(value)
                        end
                    else
                        for index_t, value_t in ipairs(self.PlayersInside) do
                            if value == value_t then
                                self.PlayersInside[index_t] = nil
                                continue
                            end
                        end
                    end
                end
            end)
        end)

        hook.Add("PlayerSpawn", "SpawnNPCsOnPlayer_" .. self.Key, function()
            if not self.NPCsSpawned then
                spawnNPCs()
                self.NPCsSpawned = true
            end
        end)
    end

    hook.Call("SWQ_TownAdded")

    return self
end

-- Create the new towns
for key, table in pairs(SWQ.Config.Towns) do
    Towns:new(key, table)
end
