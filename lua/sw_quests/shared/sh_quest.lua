SWQ = SWQ or {}

include("../server/sv_util.lua")

if SERVER then
    SWQ.Quests = {
        ['pickup_package'] = {
            title = 'Package Pickup',
            description = 'Pickup a package from Jack and deliver it back.',
            restricted = { "platform", "boreas_town" },

            OnComplete = function (ply, town)
                ply:AddReputation(town, 10)

                net.Start("SWQ:MainNotify")
                net.WriteString("Quest Completed")
                net.WriteString("You have gained +10 reputation.")
                net.Send(ply)

                ply:StopQuest(true)
            end,

            IsPossible = function()
                local AmountOfTowns = 0

                for _,_ in pairs(SWQ.Config.Towns) do
                    AmountOfTowns = AmountOfTowns + 1
                end

                if AmountOfTowns > 1 then
                    return true
                end

                return false
            end,

            -- Player is the player who started, ent is the entity who gave the quest.
            -- By this point, we've already set the current quest for the player
            -- And sent the player a net message letting them know to start.
            -- This is where code for actual quest logic would go
            --
            OnStart = function(ply, ent, this)
                local Cancel = false
            
                -- Spawn random NPC
                local RandomEnt = util.SpawnNPCAnywhere("npc_citizen", false)
                if not RandomEnt then
                    ply:StopQuest(true)
                    return
                end
            
                print(RandomEnt:EntIndex())
                local GenderType = (math.random(1, 2) == 1) and "male" or "female"
            
                -- Set NPC model based on gender
                if GenderType == "male" then
                    RandomEnt:SetModel(SWQ.Config.NPCs.MaleCivModels[math.random(1, #SWQ.Config.NPCs.MaleCivModels)])
                else
                    RandomEnt:SetModel(SWQ.Config.NPCs.FemaleModels[math.random(1, #SWQ.Config.NPCs.FemaleModels)])
                end
            
                -- Notify client about the spawned NPC
                net.Start("SWQ:UpdateQuestNPCPosition")
                net.WriteEntity(RandomEnt)
                net.Send(ply)
            
                -- Set NPC to idle
                ent:StartActivity(ACT_IDLE)
            
                -- Handle NPC death
                hook.Add("OnNPCKilled", "SWQ_PlayerQuestNPCKilled_" .. RandomEnt:EntIndex(), function(npc, attacker, inflictor)
                    if npc == RandomEnt then
                        ply:StopQuest(true)
                        Cancel = true
                    end
                end)
            
                if Cancel then return end
            
                -- Handle player interaction with the NPC
                hook.Add("PlayerUse", "SWQ_PlayerUse_" .. RandomEnt:EntIndex(), function(interact_player, interact_entity)
                    if interact_entity ~= RandomEnt then return end
            
                    if ply ~= interact_player then
                        net.Start("SWQ:Notify")
                        net.WriteString("This is not for you.")
                        net.Send(interact_player)
                        return
                    end
            
                    -- Remove death hook before deleting NPC
                    hook.Remove("OnNPCKilled", "SWQ_PlayerQuestNPCKilled_" .. RandomEnt:EntIndex())
            
                    if ply.CurrentQuest == nil then
                        RandomEnt:Remove()
                        return
                    end
            
                    -- Play NPC sound based on gender
                    local soundPath = (GenderType == "female") and "vo/npc/female01/abouttime01.wav" or "vo/npc/male01/abouttime01.wav"
                    RandomEnt:EmitSound(soundPath, 75, 100, 1, CHAN_AUTO)
            
                    -- Notify player and update quest NPC position
                    net.Start("SWQ:MainNotify")
                    net.WriteString("You received the package.")
                    net.WriteString("Now take it back.")
                    net.Send(interact_player)
            
                    net.Start("SWQ:StopQuestNPCPosition")
                    net.Send(ply)
            
                    net.Start("SWQ:UpdateQuestNPCPosition")
                    net.WriteEntity(ent)
                    net.Send(ply)
            
                    -- Handle new NPC death
                    hook.Add("OnNPCKilled", "SWQ_PlayerQuestNPCKilled_" .. ent:EntIndex(), function(npc, attacker, inflictor)
                        if npc == ent then
                            ply:StopQuest(true)
                            Cancel = true
                        end
                    end)
            
                    if Cancel then
                        if IsValid(RandomEnt) then
                            RandomEnt:Remove()
                        end
                        ply:StopQuest(true)
                        return
                    end
            
                    -- Handle interaction with the entity
                    hook.Add("PlayerUse", "SWQ_PlayerUse_" .. ent:EntIndex(), function(iinteract_player, iinteract_entity)
                        if iinteract_entity ~= ent then return end
            
                        if ply.CurrentQuest == nil then
                            RandomEnt:Remove()
                            return
                        end
            
                        if iinteract_player ~= ply then
                            net.Start("SWQ:Notify")
                            net.WriteString("This NPC is awaiting somebody.")
                            net.Send(iinteract_player)
                            return
                        end
            
                        hook.Remove("PlayerUse", "SWQ_PlayerUse_" .. ent:EntIndex())
                        this.OnComplete(ply, ent:GetTown())
                    end)
            
                    RandomEnt:Remove()
                end)
            end            
        }
    }

    Quests = {}
    Quests.__index = Towns

    Quests.Instances = {}

    function Quests:new(key, configData)
        local self = setmetatable({}, Quests)
        self.title = configData.title
        self.description = configData.description
        self.restricted = configData.restricted
        self.IsPossible = configData.IsPossible
        self.OnStart = configData.OnStart
        self.OnComplete = configData.OnComplete
        self.Key = key
        table.insert(Quests.Instances, self)
        self.QuestInstanceIndex = (#Quests.Instances + 1)
        return self
    end
end
