print("Loaded cl_vgui.lua")

GUI = GUI or {}

GUI.PositionMenu = nil

local FrameColor = Color(47, 54, 64)
local TextColor = Color(255, 255, 255)

surface.CreateFont("SWQNotify", {
    font = "Inknut Antiqua Medium",
    size = 30, -- Adjusted font size for readability
    weight = 1000,
})

surface.CreateFont("SWQQuestStarted", {
    font = "Inknut Antiqua Medium",
    size = 84, -- Adjusted font size for readability
    weight = 1000,
})

surface.CreateFont("SWQQuestTitle", {
    font = "Inknut Antiqua Medium",
    size = 48, -- Adjusted font size for readability
    weight = 1000,
})

surface.CreateFont("SWQPosUpdate", {
    font = "Inknut Antiqua Medium",
    size = 72, -- Adjusted font size for readability
    weight = 1000,
})

GUI.ActiveNotifications = GUI.ActiveNotifications or {}

GUI.SendNotify = function(message)
    local screenW, screenH = ScrW(), ScrH()

    -- Create the notification panel
    local notificationPanel = vgui.Create("DPanel")
    notificationPanel:SetSize(300, 40)  -- Initial size, will be adjusted later
    notificationPanel:SetBackgroundColor(FrameColor)

    -- Add label to display the message
    local notificationLabel = vgui.Create("DLabel", notificationPanel)
    notificationLabel:SetText(message)
    notificationLabel:SetFont("SWQNotify")
    notificationLabel:SetTextColor(TextColor)
    notificationLabel:SetContentAlignment(5)
    
    -- Calculate text size and adjust panel size
    local textWide, textTall = notificationLabel:GetContentSize()
    notificationPanel:SetSize(math.max(300, textWide + 20), textTall + 10)
    notificationLabel:SetSize(notificationPanel:GetWide() - 20, notificationPanel:GetTall() - 10)
    notificationLabel:SetPos(10, 5)

    -- Position the panel based on the number of active notifications
    local yPos = screenH - 80 - (#GUI.ActiveNotifications * notificationPanel:GetTall())

    -- Set initial position
    notificationPanel:SetPos(screenW, yPos)
    notificationPanel:InvalidateLayout(true)

    -- Insert the new notification into the active list
    table.insert(GUI.ActiveNotifications, notificationPanel)

    -- Define the target position
    local targetX = screenW - notificationPanel:GetWide() - 20

    -- Animate the panel into view and out of view
    notificationPanel:MoveTo(targetX, yPos, 0.5, 0, 1, function()
        timer.Simple(5, function()
            if IsValid(notificationPanel) then
                notificationPanel:MoveTo(screenW, yPos, 0.5, 0, 1, function()
                    notificationPanel:Remove()
                    table.RemoveByValue(GUI.ActiveNotifications, notificationPanel)
                end)
            end
        end)
    end)
end

-- Queue to store notifications
local notificationQueue = {}
local isNotificationActive = false

-- Function to process the next notification in the queue
local function ProcessNextNotification()
    -- If the queue is empty or a notification is already active, return
    if #notificationQueue == 0 or isNotificationActive then return end

    -- Set the notification as active
    isNotificationActive = true

    -- Dequeue the next notification
    local nextNotification = table.remove(notificationQueue, 1)
    local Title = nextNotification.Title
    local Description = nextNotification.Description

    surface.PlaySound("quest_start.wav")
    local relativeWidth = 685
    local relativeHeight = 145

    -- Create the notification frame
    local frame = vgui.Create("DPanel")
    frame:SetSize(relativeWidth, relativeHeight) -- Set the size of the frame
    frame:Center()                               -- Center the frame on the screen
    local x, y = frame:GetPos()
    frame:SetPos(x, y - 330)
    frame:SetAlpha(0)
    frame:AlphaTo(255, 1, 0, function() end)

    local textAlpha = 0
    local beepBoopAlpha = 0
    local questTextYPos = relativeHeight / 2
    local questStartedTime = CurTime()

    frame.Paint = function(self, w, h)
        -- Background and border color
        surface.SetDrawColor(60, 60, 60, 200)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawOutlinedRect(0, 0, w, h)

        -- Fade in the "Quest Started" text
        textAlpha = math.min(textAlpha + 0.6, 255)

        -- Draw the "Quest Started" text with fading effect
        draw.SimpleText(Title, "SWQQuestStarted", w / 2, questTextYPos, Color(255, 255, 255, textAlpha),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- If 3 seconds have passed, start moving the text up and fade in the "Beep Boop" text
        if CurTime() > questStartedTime + 3 then
            questTextYPos = Lerp(0.05, questTextYPos, relativeHeight / 2 - 20) -- Move "Quest Started" up
            beepBoopAlpha = math.min(beepBoopAlpha + 0.6, 255)                 -- Fade in "Beep Boop"
        end

        -- Draw the "Beep Boop" text below "Quest Started" with fading effect
        draw.SimpleText(Description, "SWQQuestTitle", w / 2, questTextYPos + 40, Color(255, 255, 255, beepBoopAlpha),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- Fade out and remove the frame after 5 seconds, then process the next notification
    timer.Simple(5, function()
        if IsValid(frame) then
            frame:AlphaTo(0, 1, 0, function()
                frame:Remove()
                isNotificationActive = false
                ProcessNextNotification() -- Process the next notification after this one fades out
            end)
        end
    end)
end

-- Add new notifications to the queue and trigger processing
net.Receive("SWQ:MainNotify", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local Title = net.ReadString()
    local Description = net.ReadString()

    if not Title or not Description then return end

    -- Add the notification to the queue
    table.insert(notificationQueue, { Title = Title, Description = Description })

    -- Process the notification queue if not already active
    if not isNotificationActive then
        ProcessNextNotification()
    end
end)



net.Receive("SWQ:UpdateQuestNPCPosition", function ()
    local ent = net.ReadEntity()



    if not GUI.PositionMenu then
        local frame = vgui.Create("DPanel")

        local relativeX = (ScrW() / 2776) /2
        local relativeY = (ScrH() / 1901) /2 

        frame:SetPos(relativeX, relativeY)
        frame:SetSize(392, 83)

        frame.Paint = function(self, w, h)
            -- Background and border color
            surface.SetDrawColor(60, 60, 60, 200)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawOutlinedRect(0, 0, w, h)

            local lclPlayerPos = LocalPlayer():GetPos()
            lclPlayerPos.z = 0

            if IsValid(ent) then
                local Position = ent:GetPos()
                Position.z = 0
    
                draw.SimpleText((math.ceil(lclPlayerPos:Distance(Position) - 30)) .. "m away", "SWQPosUpdate", w / 2, h/2, Color(255, 255, 255, 255),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                GUI.PositionMenu:Remove()
                GUI.PositionMenu = nil
                hook.Remove("PreDrawHalos", "SWQ_DrawHaloAroundNPC")
            end
        end

        GUI.PositionMenu = frame

        hook.Add("PreDrawHalos", "SWQ_DrawHaloAroundNPC", function()
            if IsValid(ent) then
                halo.Add({ent}, Color(0, 255, 0), 5, 5, 2, true, true)
            end
        end)

    end
end)

net.Receive("SWQ:StopQuestNPCPosition", function ()
    hook.Remove("PreDrawHalos", "SWQ_DrawHaloAroundNPC")
    if IsValid(GUI.PositionMenu) then GUI.PositionMenu:Remove() GUI.PositionMenu = nil return end
end)

GUI.QuestTest = function ()

    surface.PlaySound("quest_start.wav")

    local relativeWidth = 685
    local relativeHeight = 145

    -- Create the main frame that will hold the quest info
    local frame = vgui.Create("DPanel")
    frame:SetSize(relativeWidth, relativeHeight) -- Set the size of the frame
    frame:Center()                               -- Center the frame on the screen
    local x, y = frame:GetPos()
    frame:SetPos(x, y - 330)
    frame:SetAlpha(0)
    frame:AlphaTo(255, 1, 0, function() end)

    local textAlpha = 0
    local beepBoopAlpha = 0
    local questTextYPos = relativeHeight / 2
    local questStartedTime = CurTime()

    frame.Paint = function(self, w, h)
        -- Background and border color
        surface.SetDrawColor(60, 60, 60, 200)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawOutlinedRect(0, 0, w, h)

        textAlpha = math.min(textAlpha + 0.6, 255)

        draw.SimpleText("Quest Started", "SWQQuestStarted", w / 2, questTextYPos, Color(255, 255, 255, textAlpha),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        if CurTime() > questStartedTime + 3 then
            questTextYPos = Lerp(0.05, questTextYPos, relativeHeight / 2 - 20) -- Move "Quest Started" up
            beepBoopAlpha = math.min(beepBoopAlpha + 0.6, 255)                 -- Fade in "Beep Boop"
        end

        draw.SimpleText("Package Mayhem", "SWQQuestTitle", w / 2, questTextYPos + 40, Color(255, 255, 255, beepBoopAlpha),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    timer.Simple(5, function()
        if IsValid(frame) then
            frame:AlphaTo(0, 1, 0, function()
                frame:Remove()
            end)
        end
    end)
end

-- GUI.QuestTest()
