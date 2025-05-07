print("Loaded sv_network.lua")

-- Debug
util.AddNetworkString("SWQ:REQUEST_DEBUG_TOWNS")
util.AddNetworkString("SWQ:SEND_DEBUG_TOWNS")
util.AddNetworkString("SWQ:REQUEST_DEBUG_NPCS")
util.AddNetworkString("SWQ:SEND_DEBUG_NPCS")

-- Reputation
util.AddNetworkString("SWQ:ReputationRemoved")
util.AddNetworkString("SWQ:ReputationAdded")

-- Quest
util.AddNetworkString("SWQ:MainNotify")
util.AddNetworkString("SWQ:StopQuest")
util.AddNetworkString("SWQ:UpdateQuestNPCPosition")
util.AddNetworkString("SWQ:StopQuestNPCPosition")