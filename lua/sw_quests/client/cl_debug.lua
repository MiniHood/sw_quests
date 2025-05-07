print("Loaded cl_debug.lua")

local NPC_STATE_DEBUG = false
local TOWN_DEBUG = false

-- Reset for lua refresh
timer.Remove("sw_debug_draw_npcs_update")
hook.Remove("HUDPaint", "SW_DEBUG_NPC_STATE_TALKING")
hook.Remove("PostDrawOpaqueRenderables", "SW_DEBUG_DRAW_TOWNS")

local function SimpleAutoComplete( cmd, args, ... )
	local possibleArgs = { ... }
	local autoCompletes = {}

	--TODO: Handle "test test" "test test" type arguments
	local arg = string.Split( args:TrimLeft(), " " )

	local lastItem = nil
	for i, str in pairs( arg ) do
		if ( str == "" && ( lastItem && lastItem == "" ) ) then table.remove( arg, i ) end
		lastItem = str
	end -- Remove empty entries. Can this be done better?

	local numArgs = #arg
	local lastArg = table.remove( arg, numArgs )
	local prevArgs = table.concat( arg, " " )
	if ( #prevArgs > 0 ) then prevArgs = " " .. prevArgs end

	local possibilities = possibleArgs[ numArgs ] or { lastArg }
	for _, acStr in pairs( possibilities ) do
		if ( !acStr:StartsWith( lastArg ) ) then continue end
		table.insert( autoCompletes, cmd .. prevArgs .. " " .. acStr )
	end
		
	return autoCompletes
end

concommand.Add("sw_debug_draw_npc", function (ply, cmd, args, argStr)
    if not NPC_STATE_DEBUG then
        NPC_STATE_DEBUG = true

        net.Start("SWQ:REQUEST_DEBUG_NPCS")
        net.SendToServer()

        timer.Create("sw_debug_draw_npcs_update", 0.2, -1, function ()
            hook.Remove("HUDPaint", "SW_DEBUG_NPC_STATE_TALKING")
            net.Start("SWQ:REQUEST_DEBUG_NPCS")
            net.SendToServer()
        end)
    else
        NPC_STATE_DEBUG = false
        hook.Remove("HUDPaint", "SW_DEBUG_NPC_STATE_TALKING")
        timer.Remove("sw_debug_draw_npcs_update")
    end
end, function (cmd, args)
    return SimpleAutoComplete(cmd, args)
end)

net.Receive("SWQ:SEND_DEBUG_NPCS", function ()
    local Entities = net.ReadTable()

    hook.Add("HUDPaint", "SW_DEBUG_NPC_STATE_TALKING", function()
        if not Entities then print("Entity table for debug has return nil.") return end

        for _, Entity in ipairs(Entities) do
            local DrawingPos = Entity.Pos + Entity.OBBCenter
            local Draw2D = DrawingPos:ToScreen()
            Draw2D.y = Draw2D.y + 50

            if not Draw2D.visible then continue end

            local Task = Entity.Task or "No task"
            local State = Entity.State or "No state"
            local Town = Entity.Town.Name or "No town"
            local Gender = Entity.Gender or "No gender"
            local DetectedBins = Entity.DetectedBins or 0
            local DetectedOthers = Entity.DetectedOthers or 0
            local DetectedPlayers = Entity.DetectedPlayers or 0
            local IsWaitingForNPC = Entity.IsWaitingForNPC or "None"


            draw.SimpleText("TASK: " .. Task, "Default", Draw2D.x, Draw2D.y + 10, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("STATE: " .. State, "Default", Draw2D.x, Draw2D.y + 25, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("TOWN: " .. Town, "Default", Draw2D.x, Draw2D.y + 40, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("GENDER: " .. Gender, "Default", Draw2D.x, Draw2D.y + 55, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Detected Bins: " .. DetectedBins, "Default", Draw2D.x, Draw2D.y + 70, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Detected Others: " .. DetectedOthers, "Default", Draw2D.x, Draw2D.y + 85, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Detected Players: " .. DetectedPlayers, "Default", Draw2D.x, Draw2D.y + 100, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Waiting For NPC: " .. IsWaitingForNPC, "Default", Draw2D.x, Draw2D.y + 115, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        end
    end)
end)

concommand.Add("sw_debug_draw_towns", function (ply, cmd, args, argStr)

    if not TOWN_DEBUG then
        TOWN_DEBUG = true

        net.Start("SWQ:REQUEST_DEBUG_TOWNS")
        net.SendToServer()
    else
        TOWN_DEBUG = false
        hook.Remove("PostDrawOpaqueRenderables", "SW_DEBUG_DRAW_TOWNS")
    end
end, function (cmd, args)
    return SimpleAutoComplete(cmd, args)
end)

net.Receive("SWQ:SEND_DEBUG_TOWNS", function ()
    local TownNet = net.ReadTable()
    PrintTable(TownNet)
    hook.Add("PostDrawOpaqueRenderables", "SW_DEBUG_DRAW_TOWNS", function()
        for I, V in ipairs(TownNet) do
            local center = (V.MinBound + V.MaxBound) / 2
            local size = V.MinBound - V.MaxBound

            cam.Start3D()

            render.SetColorMaterial()

            -- Draw main box
            render.DrawBox(
                center,
                Angle(0, 0, 0),
                -size / 2,
                size / 2,
                Color(255, 0, 0, 100)
            )

            -- Draw minbound
            render.DrawBox(
                V.MinBound,
                Angle(0, 0, 0),
                Vector(10, 10, 10),
                -Vector(10, 10, 10),
                Color(255, 255, 255, 100)
            )

            -- Draw maxbound
            render.DrawBox(
                V.MaxBound,
                Angle(0, 0, 0),
                Vector(10, 10, 10),
                -Vector(10, 10, 10),
                Color(255, 255, 255, 100)
            )

            cam.End3D()

            local keyIndex = 0 

            for Key, Value in pairs(V) do
                cam.Start3D2D(center + Vector(0, 0, 50 + (keyIndex * 20)), Angle(0, LocalPlayer():EyeAngles().y - 90, 90), 0.7)
                    draw.SimpleText(Key .. ": " .. tostring(Value), "DermaLarge", 0, 0, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                cam.End3D2D()

                keyIndex = keyIndex + 1 
            end
        end
    end)
end)