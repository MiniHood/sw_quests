print("Loaded sv_init.lua")

SWQ = SWQ or {}

-- Create Database if not made already
if not sql.TableExists("SWQ_PLAYERS") then
    sql.Query([[
        CREATE TABLE IF NOT EXISTS SWQ_PLAYERS (
            SteamID TEXT PRIMARY KEY,
            TownReputations TEXT,
            CompletedQuests TEXT,
            InProgressQuests TEXT
        );
    ]])
end


-- Lua refresh compatability
for index, value in ipairs(SWQ.Entities) do
    for _, ent in ents.Iterator() do
        if ( ent:GetClass() == value ) then
            ent:Remove()
        end
    end
end