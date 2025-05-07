print("Loaded sv_reputation.lua")

function TakeReputation(ply, type, town)
    if not ply or not type or not town then return end

    ply:RemoveReputation(town, type.AmountRemoved)

    net.Start("SWQ:ReputationRemoved")
        net.WriteTable(type)
        net.WriteString(town.Name)
    net.Send(ply)
end

function GiveReputation(ply, type, town)
    if not ply or not type or not town then return end

    ply:AddReputation(town, type.AmountAdded)

    net.Start("SWQ:ReputationAdded")
        net.WriteTable(type)
        net.WriteString(town.Name)
    net.Send(ply)
end

function GetRep(ply, town)
    if not town then return end
    return ply.Reputation[town] or 0
end

