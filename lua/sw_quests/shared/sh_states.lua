print("Loaded sh_states.lua")

SWQ = SWQ or {}

SWQ.DebugEnabled = false

SWQ.States = {
    "NPC_STATE_BUSY",
    "NPC_STATE_IDLE",
}

SWQ.Task = {

    -- Wandering Citizen
    'NPC_TASK_TALK',
    'NPC_TASK_SEARCHBIN',
    'NPC_TASK_FEAR',
    "NPC_TASK_IDLE",

    -- Town Police
    "NPC_TASK_SEARCH",
    "NPC_TASK_ATTACK",
    "NPC_TASK_PICKUPTHATCAN"    
}

SWQ.Entities = {
    'wandering_civ',
    'quest_giver'
}