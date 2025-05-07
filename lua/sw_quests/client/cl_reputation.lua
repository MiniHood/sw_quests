print("Loaded cl_reputation.lua")

net.Receive("SWQ:ReputationRemoved", function ()
    local Type = net.ReadTable()
    local Town = net.ReadString()
    GUI.SendNotify(string.format(Type.Message, Type.AmountRemoved, Town))
end)

net.Receive("SWQ:ReputationAdded", function ()
    local Type = net.ReadTable()
    local Town = net.ReadString()
    GUI.SendNotify(string.format(Type.Message, Type.Amount, Town))
end)