print("Loaded sv_debug.lua")

local function SerializeEntity(ent)
    if not IsValid(ent) then return nil end

    return {
        Task = ent:GetTask(),
        State = ent:GetCurrentState(),
        Town = ent:GetTown(),
        Gender = ent:GetGender(),
        Pos = ent:GetPos(),
        OBBCenter = ent:OBBCenter(),
        DetectedBins = ent.DetectedBins,
        DetectedOthers = ent.DetectedOthers,
        DetectedPlayers = ent.DetectedPlayers,
        IsWaitingForNPC = ent.IsWaitingForNPC,
    }
end

net.Receive("SWQ:REQUEST_DEBUG_TOWNS", function (len, ply)
    net.Start("SWQ:SEND_DEBUG_TOWNS")
        net.WriteTable(Towns.Instances)
    net.Send(ply)
end)

net.Receive("SWQ:REQUEST_DEBUG_NPCS", function (len, ply)

    local Entities = {}
    for _, Class in ipairs(SWQ.Entities) do
        for index, value in ipairs(ents.FindByClass(Class)) do
            table.insert(Entities, SerializeEntity(value))
        end
    end

    net.Start("SWQ:SEND_DEBUG_NPCS")
        net.WriteTable(Entities)
    net.Send(ply)
end)
