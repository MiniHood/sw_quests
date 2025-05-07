AddCSLuaFile()

ENT.Base      = "base_nextbot"
ENT.Spawnable = true

ENT.LastTask  = nil

function ENT:SetGender(type)
	self.Gender = type or 'male'
end

function ENT:GetGender()
	return self.Gender or 'male'
end

function ENT:GetCurrentState()
	return self.CurrentState or "NPC_STATE_IDLE"
end

function ENT:SetCurrentState(state)
	self.CurrentState = state or "NPC_STATE_IDLE"
end

function ENT:SetTask(task)
	self.Task = task or "NPC_TASK_IDLE"
end

function ENT:GetTask()
	return self.Task or "NPC_TASK_IDLE"
end

function ENT:SetTown(town)
	self.Town = town or nil
end

function ENT:GetTown()
	return self.Town or nil
end

function ENT:CheckIfInTown()
	local OurPos = self:GetPos()
	for _, town in ipairs(Towns.Instances) do
		local inXBounds = OurPos.x >= town.MinBound.x and OurPos.x <= town.MaxBound.x
		local inZBounds = OurPos.z >= town.MinBound.z and OurPos.z <= town.MaxBound.z

		if inXBounds and inZBounds then
			self:SetTown(town)
			return true
		end
	end
	return false
end

function ENT:Initialize()
	if SERVER then
		local GenderType = tostring(math.random(1, 2))

		if GenderType == "1" then
			GenderType = 'male'
			self:SetModel(SWQ.Config.NPCs.MaleCivModels[math.random(1, #SWQ.Config.NPCs.MaleCivModels)])
		elseif GenderType == "2" then
			GenderType = 'female'
			self:SetModel(SWQ.Config.NPCs.FemaleModels[math.random(1, #SWQ.Config.NPCs.FemaleModels)])
		end

		self.Gender = GenderType

		self:SetCurrentState("NPC_STATE_IDLE")
		self:SetTask("NPC_TASK_IDLE")

		if (not self:FindBodygroupByName("head")) == -1 then
			self:SetBodygroup(self:FindBodygroupByName("head"),
				math.random(0, self:GetBodygroupCount(self:FindBodygroupByName("head")) - 1))
		end

		if (not self:FindBodygroupByName("chest")) == -1 then
			self:SetBodygroup(self:FindBodygroupByName("chest"),
				math.random(0, self:GetBodygroupCount(self:FindBodygroupByName("chest")) - 1))
		end

		if (not self:FindBodygroupByName("legs")) == -1 then
			self:SetBodygroup(self:FindBodygroupByName("legs"),
				math.random(0, self:GetBodygroupCount(self:FindBodygroupByName("legs")) - 1))
		end

		if SWQ.Config.NPCs.RandomiseColor then
			self:SetColor(Color(math.random(0, 255), math.random(0, 255), math.random(0, 255)))
		end

		if not self:CheckIfInTown() then
			self:Remove()
		end

		self:SetMaxHealth(25)
		self:SetHealth(25)

		self.next_use = 0
	end
end

local function IsWithin(EntPos, TownMinBound, TownMaxBound)
	if EntPos.x >= TownMinBound.x and EntPos.x <= TownMaxBound.x and
		EntPos.z >= TownMinBound.z and EntPos.z <= TownMaxBound.z then
		return true
	else
		return false
	end
end

function ENT:PerformTask(type, interactable)
	if not IsValid(interactable) then return end
	self.LastTask = type
	self:SetTask(type)
	self:SetCurrentState("NPC_STATE_BUSY")
	if interactable then
		self.CurrentInteractable = interactable
	end
end

ENT.DetectedBins = 0
ENT.DetectedOthers = 0
ENT.DetectedPlayers = 0

ENT.IsWaitingForNPC = nil

function ENT:OnRemove()
	timer.Remove(self:EntIndex())
end

function ENT:Think()
	if not (self.CurrentState == 'NPC_STATE_IDLE' and self.Task == 'NPC_TASK_IDLE') then
		return
	end


	self.DetectedPlayers = 0
	self.DetectedOthers = 0
	self.DetectedBins = 0

	local un_Others = ents.FindByClass("wandering_civ")

	local un_Bins = {}
	table.insert(un_Bins, ents.FindByModel("models/props_trainstation/trashcan_indoor001b.mdl"))
	table.insert(un_Bins, ents.FindByModel("models/props_trainstation/trashcan_indoor001a.mdl"))
	table.insert(un_Bins, ents.FindByModel("models/props_junk/trashbin01a.mdl"))

	local un_Players = player.GetAll()

	local Others = {}
	local Bins = {}
	local Players = {}

	local TownMaxBound = self.Town.MaxBound
	local TownMinBound = self.Town.MinBound

	for _, ent in pairs(un_Others) do
		if not IsValid(ent) then continue end

		local EntPos = ent:GetPos()

		if ent == self then
			continue
		end

		if IsWithin(EntPos, TownMinBound, TownMaxBound) then
			self.DetectedOthers = self.DetectedOthers + 1
			table.insert(Others, ent)
		end
	end

	for _, binGroup in pairs(un_Bins) do
		for _, ent in pairs(binGroup) do
			if not IsValid(ent) then continue end

			local EntPos = ent:GetPos()

			if IsWithin(EntPos, TownMinBound, TownMaxBound) then
				self.DetectedBins = self.DetectedBins + 1
				table.insert(Bins, ent)
			end
		end
	end

	for _, ply in pairs(un_Players) do
		if not IsValid(ply) then continue end

		local PlyPos = ply:GetPos()

		if IsWithin(PlyPos, TownMinBound, TownMaxBound) then
			self.DetectedPlayers = self.DetectedPlayers + 1
			table.insert(Players, ply)
		end
	end

	un_Bins = nil
	un_Others = nil
	un_Players = nil

	for _, ply in ipairs(Players) do
		if not IsValid(ply) then continue end

		if ply:GetPos():Distance(self:GetPos()) < 200 then
			if GetRep(ply, self:GetTown().Key) < 0 then
				self.IsWaitingForNPC = nil
				self:PerformTask("NPC_TASK_FEAR", ply)
				break
			end
		end
	end

	local RandomTask = SWQ.Task[math.random(1, #SWQ.Task)]
	if RandomTask == self.LastTask then return end

	if not self.IsWaitingForNPC then
		if RandomTask == "NPC_TASK_SEARCHBIN" then
			if not Bins then return end
			local RandomBin = Bins[math.random(1, #Bins)]
			self:PerformTask(RandomTask, RandomBin)
		else
			if RandomTask == "NPC_TASK_TALK" then
				self.IsWaitingForNPC = "NPC_TASK_TALK"
				for index, Ent in ipairs(Others) do
					if Ent.IsWaitingForNPC == "NPC_TASK_TALK" then
						self:PerformTask('NPC_TASK_TALK', Ent)
						self.IsWaitingForNPC = nil
						break
					end
				end
			end
		end
	else
		if not Others then return end


		if self.IsWaitingForNPC == "NPC_TASK_TALK" then
			for index, Ent in ipairs(Others) do
				if Ent:GetTask() == "NPC_TASK_TALK" then
					self:PerformTask('NPC_TASK_TALK', Ent)
					self.IsWaitingForNPC = nil
				end
			end
		end
	end
end

function ENT:OnTakeDamage(DamageInfo)
	local Attacker = DamageInfo:GetAttacker()

	if not Attacker:IsPlayer() then
		return 0
	end

	if DamageInfo:GetDamage() < self:Health() then
		TakeReputation(Attacker, SWQ.Reputation['REASON_DAMAGE_NPC'], self.Town)
	elseif DamageInfo:GetDamage() >= self:Health() then
		TakeReputation(Attacker, SWQ.Reputation['REASON_KILL_NPC'], self.Town)
	end
end

function ENT:GetAngleNeedsSpace()
	local closest_ang = nil
	local closest_dist = nil
	local trace_length = 45
	local start = self:GetPos() + Vector(0, 0, 75 / 2)

	local offset = (CurTime() % 45) * 8

	for ang = 0, 360, 45 do
		local ang2 = ang + offset

		local normal = Angle(0, ang2, 0):Forward()
		local endpos = start + normal * trace_length

		local tr = util.TraceEntity({
				start = start,
				endpos = endpos,
				filter = self,
				mask = MASK_SOLID,
			},
			self
		)

		debugoverlay.Line(start, start + normal * (trace_length * tr.Fraction), 0.1, color_white, true)

		if tr.Hit and (closest_dist == nil or tr.Fraction * trace_length < closest_dist) then
			closest_ang = ang2
			closest_dist = tr.Fraction * trace_length
		end
	end

	if closest_dist == nil or closest_dist > 1 then
		return nil
	else
		return Angle(0, closest_ang, 0)
	end
end

function ENT:HandleStuck(options)
	local options = options or {}
	local timeout = CurTime() + (options.timeout or 60)
	local unstuck_attempts = options.unstuck_attempts or 0
	local max_unstuck_attempts = 5


	self.loco:SetDesiredSpeed(50)
	while CurTime() < timeout do
		local result = self:GetAngleNeedsSpace()
		if result == nil then break end
		self.loco:Approach(self:GetPos() - (result:Forward() * 100), 1)
		coroutine.yield()
	end

	if CurTime() >= timeout then return "timeout" end

	local start_dist = self.path:GetCursorPosition()
	local start_pos = self.path:GetPositionOnPath(start_dist)


	local attempts = { 64, 32, 24, 16, 12, 8 }
	local offset_mult = 1
	local path_gen = nil
	local result = nil

	for i, attempt in ipairs(attempts) do
		offset_mult = attempt * 2
		path_gen = OBST_AVOID_PATH_GEN:create(self, self.path, start_dist + 20, 25, 75, 75,
			{ draw = true, node_min_dist = attempt })
		path_gen:CreateSeedNode(self:GetPos())
		result = path_gen:CalcPath()

		if result == "ok" then break end
	end

	if result != "ok" then
		unstuck_attempts = unstuck_attempts + 1
		if unstuck_attempts >= max_unstuck_attempts then
			local town = self:GetTown()
			if town then
				local middlePos = (town.MinBound + town.MaxBound) / 2
				self:SetPos(middlePos)
				return "teleported"
			end
		end
		return "failed"
	end

	local path = path_gen.output

	timeout = CurTime() + (options.timeout or 60)

	self.loco:SetDesiredSpeed(100)

	while #path > 0 and CurTime() < timeout do
		for i = 1, #path - 1 do
			debugoverlay.Line(path[i], path[i + 1], 0.1, color_white, true)
		end

		local offset = vector_origin

		local result = self:GetAngleNeedsSpace()
		if result != nil then offset = -result:Forward() * offset_mult end

		self.loco:Approach(path[1] + offset, 1)
		self.loco:FaceTowards(path[1])
		if self:GetPos():Distance(path[1]) < 10 then
			table.remove(path, 1)
		end

		coroutine.yield()
	end

	if CurTime() >= timeout then return "timeout" end

	self.loco:ClearStuck()
	self.loco:SetDesiredSpeed(200)
	return "ok"
end

function ENT:MoveToEntity(target, options)
	local options = options or {}
	local unstuck_attempts = 0
	local max_unstuck_attempts = 5

	self.path = Path("Follow")
	self.path:SetMinLookAheadDistance(300)
	self.path:SetGoalTolerance(40)
	self.path:Compute(self, target:GetPos())

	if not self.path:IsValid() then return "failed" end

	local last_update = CurTime()
	local motionless_ticks = 0

	while self.path:IsValid() and IsValid(target) do
		-- Check if target is still valid
		if not IsValid(target) then
			self.loco:Stop()
			self:SetCurrentState("NPC_STATE_IDLE")
			self:SetTask("NPC_TASK_IDLE")
			return "failed"
		end

		local current_update = CurTime()
		self.path:Update(self)

		if options.draw then
			self.path:Draw()
		end

		-- Check if NPC is motionless
		local reset_motionless_ticks = true
		if self:OnGround() then
			local ground_ent = self:GetGroundEntity()

			if IsValid(ground_ent) or ground_ent:IsWorld() then
				local relative_vel = self:GetVelocity() - ground_ent:GetVelocity()
				local speed = relative_vel:Length()

				if speed < 2 then
					reset_motionless_ticks = false
				end
			end
		end

		-- Manage motionless ticks
		if reset_motionless_ticks then
			motionless_ticks = 0
		else
			motionless_ticks = motionless_ticks + 1
		end

		-- Handle stuck situations or lack of movement
		if self.loco:IsStuck() or motionless_ticks * engine.TickInterval() > 0.5 then
			local result = self:HandleStuck({ unstuck_attempts = unstuck_attempts, timeout = 3 })
			if result == "teleported" then return result end
			if result != "ok" then
				unstuck_attempts = unstuck_attempts + 1
				if unstuck_attempts >= max_unstuck_attempts then
					return "failed"
				end
			end

			-- Recompute path if unstuck or target is still valid
			self.path:Compute(self, target:GetPos())
		end

		-- If NPC is within goal tolerance (close to the target)
		if self:GetPos():Distance(target:GetPos()) < 40 then
			return "ok"
		end

		last_update = current_update

		coroutine.yield()
	end

	-- If loop is exited, assume target is no longer valid or reached
	self:SetCurrentState("NPC_STATE_IDLE")
	self:SetTask("NPC_TASK_IDLE")
	return "ok"
end

function ENT:MoveToPos(pos, options)
	local options = options or {}
	local unstuck_attempts = 0
	local max_unstuck_attempts = 5

	self.path = Path("Follow")
	self.path:SetMinLookAheadDistance(300)
	self.path:SetGoalTolerance(40)
	self.path:Compute(self, pos)

	if not self.path:IsValid() then return "failed" end

	local last_update = CurTime()
	local motionless_ticks = 0

	while self.path:IsValid() do
		local current_update = CurTime()

		self.path:Update(self)

		if options.draw then
			self.path:Draw()
		end

		-- Check if NPC is motionless
		local reset_motionless_ticks = true
		if self:OnGround() then
			local ground_ent = self:GetGroundEntity()

			if IsValid(ground_ent) or ground_ent:IsWorld() then
				local relative_vel = self:GetVelocity() - ground_ent:GetVelocity()
				local speed = relative_vel:Length()

				if speed < 2 then
					reset_motionless_ticks = false
				end
			end
		end

		-- Manage motionless ticks
		if reset_motionless_ticks then
			motionless_ticks = 0
		else
			motionless_ticks = motionless_ticks + 1
		end

		-- Handle stuck situations or lack of movement
		if self.loco:IsStuck() or motionless_ticks * engine.TickInterval() > 0.5 then
			local result = self:HandleStuck({ unstuck_attempts = unstuck_attempts, timeout = 3 })
			if result == "teleported" then return result end
			if result != "ok" then
				unstuck_attempts = unstuck_attempts + 1
				if unstuck_attempts >= max_unstuck_attempts then
					return "failed"
				end
			end

			-- Recompute path if unstuck
			self.path:Compute(self, pos)
		end

		last_update = current_update

		coroutine.yield()
	end

	return "ok"
end

local function CheckForBadRepPlayerMidWalk(self)
	local un_Players = player.GetAll()
	local Players = {}
	local TownMaxBound = self.Town.MaxBound
	local TownMinBound = self.Town.MinBound
	self.DetectedPlayers = 0

	for _, ply in pairs(un_Players) do
		if not IsValid(ply) then continue end

		local PlyPos = ply:GetPos()

		if IsWithin(PlyPos, TownMinBound, TownMaxBound) then
			self.DetectedPlayers = self.DetectedPlayers + 1
			table.insert(Players, ply)
		end
	end

	for _, ply in ipairs(Players) do
		if ply:GetPos():Distance(self:GetPos()) < 200 then
			if GetRep(ply, self.Town.Key) < 0 then
				return ply
			end
		end
	end
end

local function PlaySounds(self, sounds)
	PrintTable(sounds)
	local gender = self:GetGender()
	local soundTable = gender == 'male' and sounds.male or sounds.female
	self:EmitSound(soundTable[math.random(1, #soundTable)], 75, 100, 1, CHAN_AUTO)
end

function ENT:RunBehaviour()
	self:StartActivity(ACT_IDLE)

	local function MoveToTarget(target, speed)
		self.loco:SetDesiredSpeed(speed)
		while IsValid(target) and self:GetPos():Distance(target:GetPos()) > 100 do
			self:MoveToEntity(target, { drawpath = SWQ.Config.NPCs.DrawPaths })
			local check = CheckForBadRepPlayerMidWalk(self)
			if check then
				self.IsWaitingForNPC = nil
				self:SetTask("NPC_TASK_FEAR")
				self:SetCurrentState("NPC_STATE_BUSY")
				self.CurrentInteractable = check
				return false
			end
			coroutine.wait(0.1)
		end
		return true
	end

	while true do
		local task = self:GetTask()
		if task == "NPC_TASK_IDLE" then
			self:StartActivity(ACT_IDLE)
			coroutine.wait(1)
		
		elseif task == "NPC_TASK_SEARCHBIN" or task == "NPC_TASK_TALK" then
			local target = self.CurrentInteractable
			if IsValid(target) then
				self:StartActivity(ACT_WALK)
				if not MoveToTarget(target, 100) then coroutine.yield() end
				self:StartActivity(ACT_IDLE)

				if task == "NPC_TASK_TALK" then
					PlaySounds(self, SWQ.Config.NPCs.Greeting)
					for i = 1, 3 do
						PlaySounds(self, SWQ.Config.NPCs.RandomChatter)
						coroutine.wait(math.random(3, 5))
					end
				else
					self:ResetSequence("takepackage")
					coroutine.wait(2.4)
				end

				self:SetTask("NPC_TASK_IDLE")
				self:SetCurrentState("NPC_STATE_IDLE")
			end

		elseif task == "NPC_TASK_FEAR" then
			PlaySounds(self, SWQ.Config.NPCs.FearSounds)
			self.loco:SetDesiredSpeed(200)
			local town = self:GetTown()
			if town then
				local randomPos = Vector(
					math.random(town.MinBound.x, town.MaxBound.x),
					math.Clamp(self:GetPos().y + math.random(-50, 50), town.MinBound.y, town.MaxBound.y),
					math.random(town.MinBound.z, town.MaxBound.z)
				)
				self:StartActivity(ACT_RUN)
				self:MoveToPos(randomPos, { drawpath = true })
				self:SetTask("NPC_TASK_IDLE")
				self:SetCurrentState("NPC_STATE_IDLE")
				self:StartActivity(ACT_IDLE)
			end

		elseif task == "NPC_TASK_DROPITEM" then
			return
		end
		
		coroutine.yield()
	end
end


function ENT:Use(activator, caller, type, value)
	if CurTime() > self.next_use then
		self.next_use = CurTime() + 1000

		if IsValid(activator) and activator:IsPlayer() then
			local reputation = activator:GetReputation(self:GetTown())

			local chance = math.random(1, 100)
			local rejectionThreshold = 100

			print(chance .. ' ' .. rejectionThreshold .. ' ' .. reputation)

			if reputation < 0 then
				rejectionThreshold = rejectionThreshold + reputation
			else
				rejectionThreshold = rejectionThreshold - reputation
			end

			if chance < rejectionThreshold and not activator.CurrentQuest then
				local maxTries = 6
				local tryCount = 0

				repeat
					local questKeys = {}
					for k, _ in pairs(SWQ.Quests) do
						table.insert(questKeys, k)
					end
					
					local randomQuestIndex = math.random(1, #questKeys)
					local randomQuestKey = questKeys[randomQuestIndex]
					local randomQuest = SWQ.Quests[randomQuestKey]
					

					if randomQuest.IsPossible() and table.HasValue(randomQuest.restricted, self.Town.Key) then
						activator:SetQuest(randomQuestKey)
						activator:StartQuest(self)
						break
					end


					tryCount = tryCount + 1
				until tryCount >= maxTries
			else
				PlaySounds(self, SWQ.Config.NPCs.QuestRejection)
			end
		end


		PlaySounds(self, SWQ.Config.NPCs.RandomChatter)
	end
end

list.Set("NPC", "town_police", {
	Name = "Town Police",
	Class = "town_police",
	Category = "SW Quests"
})
