print("Loaded sv_player.lua")

SWQ = SWQ or {}

local function SetPlayerData(ply)

    if not IsValid(ply) then print("Player is not valid") return end

    ply.Reputation = {}
    ply.Quest = {}

    -- Reputation
    function ply:GetReputation(town)
        if not town or not town.Name then return nil end

        local SteamID = self:SteamID64()

        local Query = string.format("SELECT TownReputations FROM SWQ_PLAYERS WHERE SteamID = %q", SteamID)
        local Result = sql.QueryRow(Query)

        if not Result then
            self:CreateEntries()
            return nil
        end

        local success, TownsReputations = pcall(util.JSONToTable, Result.TownReputations)
        if not success then
            print("Failed to convert JSON to table:", TownsReputations)
            return nil
        end

        if not TownsReputations then return nil end
        return TownsReputations[town.Key]
    end

    function ply:SetReputation(town, rep)
        if not rep or not town then print("Error with rep or town") return end

        local SteamID = self:SteamID64()

        -- Retrieve existing reputations
        local Query = string.format("SELECT TownReputations FROM SWQ_PLAYERS WHERE SteamID = %q", SteamID)
        local Result = sql.QueryRow(Query)

        local CurrentRep = {}
        if Result then
            local success, TownsReputations = pcall(util.JSONToTable, Result.TownReputations)
            if success and TownsReputations then
                CurrentRep = TownsReputations
            else
                print("Failed to convert JSON to table:", TownsReputations)
            end
        end

        -- Update the specific town's reputation
        CurrentRep[town.Key] = rep

        -- Save the updated reputations back to the database
        local TownReputationsJSON = sql.SQLStr(util.TableToJSON(CurrentRep))
        local UpdateQuery = string.format("UPDATE SWQ_PLAYERS SET TownReputations = %s WHERE SteamID = %q", TownReputationsJSON, SteamID)
        sql.Query(UpdateQuery)

        self:SyncReputation()
    end

    function ply:AddReputation(town, amt)
        if not amt or not town then return end
        self:SyncReputation()
        self:SetReputation(town, self.Reputation[town.Key] + amt) 
    end

    function ply:RemoveReputation(town, amt)
        if not amt or not town then return end
        self:SyncReputation()
        self:SetReputation(town, self.Reputation[town.Key] - amt) 
    end

    function ply:CreateEntries()
        local SteamID = self:SteamID64()
        local Query = string.format("SELECT TownReputations FROM SWQ_PLAYERS WHERE SteamID = %q", SteamID)
        local Result = sql.QueryRow(Query)
        
        if not Result then
            print("Creating player entry")
            local DefaultTownReputations = {}

            for key, value in pairs(SWQ.Config.Towns) do
                DefaultTownReputations[key] = 0
            end

            local TownReputationsJSON = sql.SQLStr(util.TableToJSON(DefaultTownReputations))
            local CompletedQuestsJSON = sql.SQLStr("{}")
            local InProgressQuestsJSON = sql.SQLStr("{}")

            local InsertQuery = string.format([[
                INSERT INTO SWQ_PLAYERS (SteamID, TownReputations, CompletedQuests, InProgressQuests) VALUES (%q, %s, %s, %s);
            ]], SteamID, TownReputationsJSON, CompletedQuestsJSON, InProgressQuestsJSON)

            local InsertResult = sql.Query(InsertQuery)
            if not InsertResult then
                print("Failed to create entry for SteamID:", SteamID)
            end
        else
            -- Check for missing towns and add them
            local success, TownsReputations = pcall(util.JSONToTable, Result.TownReputations)
            if not success then
                print("Failed to convert JSON to table:", TownsReputations)
                return
            end

            local updated = false
            for key, value in pairs(SWQ.Config.Towns) do
                if not TownsReputations[key] then
                    TownsReputations[key] = 0
                    updated = true
                end
            end

            if updated then
                local TownReputationsJSON = sql.SQLStr(util.TableToJSON(TownsReputations))
                local UpdateQuery = string.format("UPDATE SWQ_PLAYERS SET TownReputations = %s WHERE SteamID = %q", TownReputationsJSON, SteamID)
                sql.Query(UpdateQuery)
            end
        end

        self:SyncReputation()
    end

    function ply:SyncReputation()
        for _, Town in ipairs(Towns.Instances) do
            ply.Reputation[Town.Key] = ply:GetReputation(Town)
        end
    end

    -- Quests
    ply.CurrentQuest = nil
    function ply:SetQuest(quest)

        if ply.CurrentQuest then return end

        local SteamID = ply:SteamID64()
        local Query = string.format("SELECT InProgressQuests FROM SWQ_PLAYERS WHERE SteamID = %q", SteamID)
        local Result = sql.QueryRow(Query)
        local TableResult = util.JSONToTable(Result['InProgressQuests'])

        if #TableResult < 1 then
            if not quest then return end

            local RequestedQuest = SWQ.Quests[quest]
            if not RequestedQuest then return end
            if not RequestedQuest.IsPossible() then return end
            
            ply.CurrentQuest = Quests:new(quest, RequestedQuest)

            if not ply.CurrentQuest then self:StopQuest(true) return end
            if not ply.CurrentQuest.Key then self:StopQuest(true) return end
            return true
        end


        return false
    end

    function ply:StopQuest(force)
        if force then
            if not Quests.Instances then return end
            
            if not ply.CurrentQuest then
                net.Start("SWQ:StopQuest")
                net.Send(ply)
    
                net.Start("SWQ:StopQuestNPCPosition")
                net.Send(ply)

                return
            end

            if Quests.Instances[ply.CurrentQuest['QuestInstanceIndex']] then
                Quests.Instances[ply.CurrentQuest['QuestInstanceIndex']] = nil
            else
                for index, value in ipairs(Quests.Instances) do
                    if value.Key == ply.CurrentQuest then Quests.Instances[index] = nil end
                 end
            end

            ply.CurrentQuest = nil

            -- This is only used when forcing the player to stop the quest. The OnEnd function in sv_quest.lua is what is used normally.
            net.Start("SWQ:StopQuest")
            net.Send(ply)

            net.Start("SWQ:StopQuestNPCPosition")
            net.Send(ply)

            -- Possibly needs garbage collection
        end
    end

    function ply:StartQuest(ent)
        if not ply.CurrentQuest then print("Player has no current quest") return end
        if not ent then print("Entity does not exist") return end

        print("Sending quest")

        net.Start("SWQ:MainNotify")
            net.WriteString("Quest Started")
            net.WriteString(ply.CurrentQuest.title)
        net.Send(self)
        
        print("Starting")
        ply.CurrentQuest.OnStart(ply, ent, ply.CurrentQuest)
    end
end

-- Testing only, remove later.
for index, ply in ipairs(player.GetAll()) do
    SetPlayerData(ply)
    ply:CreateEntries()
    ply:SyncReputation()
end

hook.Add("PlayerInitialSpawn", "SWQ_PLY_INITS", function(ply)
    timer.Simple(5, function()  -- Increased delay to 5 seconds
        if IsValid(ply) then
            SetPlayerData(ply)
            ply:CreateEntries()
            ply:SyncReputation()
            print("Player data set for:", ply:Nick()) -- Debugging info
        else
            print("Player was not valid during initial spawn")
        end
    end)
end)
