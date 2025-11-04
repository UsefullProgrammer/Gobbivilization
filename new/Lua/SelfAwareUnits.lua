-- Lua Script1
-- Original code for self-ware units: Whoward. 
-- Serialization and other tweaks and fixes added by Hambil.
-- DateCreated: 5/12/2013 9:02:12 AM
--------------------------------------------------------------
local gSaveData	= Modding.OpenSaveData()

MoveAwareUnitManager = {
	new = function(self, clazz)
		local me = {}
		setmetatable(me, self)
		self.__index = self

		me.clazz = clazz
		me.store = {}

		-- If this is the first time we're being called, create the manager store and start the movement listener
		if (not self.managers) then
			self.managers = {}
			GameEvents.UnitSetXY.Add(function(iPlayer, iUnit, iX, iY)
				for m = 1, #self.managers, 1 do
					local ps = self.managers[m].store[iPlayer]
					if (ps and ps[iUnit]) then
						ps[iUnit]:MovedTo(iX, iY)
					end
				end
			end)
			GameEvents.PlayerDoTurn.Add(function(iPlayer)
			    if (Players[iPlayer]:IsHuman()) then
					for m = 1, #self.managers, 1 do
						local ps = self.managers[m].store[iPlayer]
						for _, pUnit in pairs(ps) do
							if (pUnit:IsEscort()) then
								pUnit:Fortify()
							end
						end
					end
				end
			end)
		end

		-- Keep track of every derived manager
		table.insert(self.managers, me)

		return me
	end,

	Get = function(self, pUnit)
		local iPlayer = pUnit:GetOwner()
		local iUnit = pUnit:GetID()

		if (not self.store[iPlayer]) then
			self.store[iPlayer] = {}
		end
		local forPlayer = self.store[iPlayer]

		local moveAwareUnit
		if (forPlayer[iUnit]) then
			moveAwareUnit = forPlayer[iUnit]
		else
			moveAwareUnit = self.clazz:new(pUnit)
			forPlayer[iUnit] = moveAwareUnit
		end

		return moveAwareUnit
	end,

	Serialize = function(self, iPlayer)
		pPlayer = Players[iPlayer]
		local saveTable = {}
		for m = 1, #self.managers, 1 do
			local ps = self.managers[m].store[iPlayer]
			for m = 1, #self.managers, 1 do
				local ps = self.managers[m].store[iPlayer]
				if (ps) then
					for _, pUnit in pairs(ps) do
						if (pUnit and pUnit:IsEscort()) then
							saveTable[pUnit:GetID()] = pUnit:GetWorker():GetID()
						elseif (pUnit and pUnit:IsEscorted()) then
							saveTable[pUnit:GetEscort():GetID()] = pUnit:GetID()
						end
					end
				end
			end
		end
		sSave = TableToString(saveTable)
		debug('Save data: ' .. sSave)
		gSaveData.SetValue("escort_mod_" .. pPlayer:GetName() .. "_savedata", sSave)
	end,

	Load = function(self, iPlayer)
		pPlayer = Players[iPlayer]
		str = gSaveData.GetValue("escort_mod_" .. pPlayer:GetName() .. "_savedata")
		local saveTable = {}
		if (str ~= nil) then
			debug('Load data: ' .. str)
			saveTable = StringToTable(str)
		end
		for iEscort, iWorker in pairs(saveTable) do
			pWorker = WorkerManager:Get(pPlayer:GetUnitByID(iWorker))
			pWorker:AddEscort(pPlayer:GetUnitByID(iEscort))
		end
	end,
}

--
-- MoveAwareUnit class - generic members and methods
--
-- It's important to remember that x:y(...) is the same as x.y(x, ...)
--
MoveAwareUnit = {
	new = function(self, pUnit)
		local me = {}
		setmetatable(me, self)
		self.__index = self

		me.pUnit = pUnit
		me.iPlayer = pUnit:GetOwner()
		me.iUnit = pUnit:GetID()

		return me
	end,

  -- abstract MoveTo = function(self, iX, iY) end,

	Equals = function(self, pOther)
		return (self.iUnit == pOther:GetID() and self.iPlayer == pOther:GetOwner())
	end,

	Notify = function(self, sMessage)
		debug(sMessage)

		if (Players[self.iPlayer]:IsHuman() and Game.GetActivePlayer() == self.iPlayer) then
			msg = Locale.ConvertTextKey(sMessage)
			tip = Locale.ConvertTextKey(sMessage)
			Players[self.iPlayer]:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, tip, msg, Players[self.iPlayer], self.pUnit, self.pUnit) 
		end
	end,

	ToString = function(self)
		return string.format("%s [id=%i] at (%i, %i)", self.pUnit:GetName(), self.iUnit, self.pUnit:GetX(), self.pUnit:GetY())
	end,

	GetName = function(self)
		return self.pUnit:GetName()
	end,

	GetID = function(self)
		return self.iUnit
	end,	

}

--
-- Worker class - wraps up useful operations on a Worker
--
Worker = {
	new = function(self, pUnit)
		local parent = MoveAwareUnit:new(pUnit)

		local me = {}
		-- The next line says "if you can't find what you're looking for in me, try my class (Worker), then my parent class (MoveAwareUnit)
		setmetatable(me, {__index = function(_, key) return ((self[key]) and self[key] or parent[key]) end})

		me.escort = nil

		return me
	end,

	AddEscort = function(self, pEscort)
		if self:IsValidEscort(pEscort) then
			if (self:IsEscorted()) then
				self:RemoveEscort()
			end

			self.escort = EscortManager:Get(pEscort)
			self.escort:AddWorker(self.pUnit)
		else
			self:Notify("TXT_KEY_ESCORT_INVALID")
		end
	end,

	RemoveEscort = function(self, bNotify)
		if (bNotify) then
		    if self and self.escort and self.escort.GetWorker() and (self.escort.GetWorker():IsDead() or self.escort.GetWorker():IsDelayedDeath()) then
				self:Notify("TXT_KEY_ESCORT_DIED")
			else
				self:Notify("TXT_KEY_ESCORT_ABANDONED")
			end
		end

		self.escort = nil
	end,

	IsEscorted = function(self)
		return (self.escort ~= nil)
	end,

	IsEscort = function(self)
		return false
	end,
	
	GetEscort = function(self)
		return self.escort
	end,

	IsValidEscort = function(self, pEscort)
		if (pEscort:GetTeam() ~= self.pUnit:GetTeam()) then
			debug("Escort is not on the same team!")
			return false
		end

		if (pEscort:GetOwner() == self.iPlayer and pEscort:GetID() == self.iUnit) then
			debug("Can't escort ourselves!")
			return false
		end

		if (pEscort:IsDead() or pEscort:IsDelayedDeath()) then
			debug("Escort is dead or dying!")
			return false
		end

		if (self.pUnit:GetDomainType() == DomainTypes.DOMAIN_AIR or pEscort:GetDomainType() == DomainTypes.DOMAIN_AIR) then
			debug("Escort is an aircraft!")
			return false
		end

		-- The escort must be the opposite of the worker - this allows Great Admirals to escort Destroyers escorting embarked units
		if (self.pUnit:IsCombatUnit() == pEscort:IsCombatUnit() ) then
			debug("Escort is the same type (civilian+civilian or combat+combat)")
			return false
		end

		-- We'll excuse immobile and scouting units
		if (pEscort:IsImmobile() or pEscort:GetUnitCombatType() == GameInfoTypes.UNITCOMBAT_RECON) then
			debug("Escort is a scout or immobile!")
			return false
		end

		if (not self:IsValidDomainEscort(pEscort)) then
			return false
		end

		-- TODO - Check that the escort
		--  * can at least move as fast as the worker
		--  * has similiar (or better) terrain crossing promotions
		-- or we need to cripple the worker
		return true
	end,

	IsValidDomainEscort = function(self, pEscort)
		-- Different domain types (Land/Sea or Sea/Land) are ok so long as I'm embarked
		if (self.pUnit:GetDomainType() ~= pEscort:GetDomainType()) then
			if (not self.pUnit:IsEmbarked()) then
				debug("Escort is not valid for the domain or I'm not embarked!")
			end
			return self.pUnit:IsEmbarked()
		end

		-- We are the same domain (Land/Land or Sea/Sea) so make sure I'm not embarked
		if (self.pUnit:IsEmbarked()) then
			debug("Escort is valid for the domain but I'm embarked!")
		end
		return not self.pUnit:IsEmbarked()
	end,

	MovedTo = function(self, iX, iY)
		debug(string.format("%s just moved to (%i, %i)", self:ToString(), iX, iY))

		if (self:IsEscorted()) then
			if (self:IsValidDomainEscort(self.escort.pUnit)) then
				self.escort:MoveTo(iX, iY)
			else
			-- No longer a valid escort, the worker probably (dis)embarked
			self:Notify("TXT_KEY_ESCORT_NOLONGER_VALID") 

			self.escort:Wake()
			self.escort = nil
			end
		end
	end,

	Fortify = function(self)
		return true -- no reason to fortify workers
	end,

}
WorkerManager = MoveAwareUnitManager:new(Worker)

--
-- Escort class - wraps up useful operations on an Escort
--
Escort = {
	new = function(self, pUnit)
		local parent = MoveAwareUnit:new(pUnit)

		local me = {}
		-- The next line says "if you can't find what you're looking for in me, try my class (Escort), then my parent class (MoveAwareUnit)
		setmetatable(me, {__index = function(_, key) return ((self[key]) and self[key] or parent[key]) end})

		me.wayPoints = nil
		me.worker = nil

		return me
	end,

	AddWorker = function(self, pWorker)
		if (self.worker) then
			self.worker:RemoveEscort(true)
		end

		self.worker = WorkerManager:Get(pWorker)
		self.wayPoints = nil
	end,

	RemoveWorker = function(self, bNotify)
		if (bNotify) then
			if self.worker and (self.worker.IsDead() or self.worker:IsDelayedDeath()) then
				self:Notify("TXT_KEY_WORKER_DIED")
			else
				self:Notify("TXT_KEY_WORKER_ABANDONED")
			end
		end
	
		if (self.worker) then
			self.worker:RemoveEscort(true)
		end
		self.wayPoints = nil
		self.worker = nil
	end,

	IsEscort = function(self)
		return (self.worker ~= nil)
	end,

	IsEscorted = function(self)
		return false
	end,

	IsValidWorker = function(self, pWorker)
		return WorkerManager:Get(pWorker):IsValidEscort(self.pUnit)
	end,

	MayEnter = function(self, iX, iY)
		return (Map.GetPlot(iX, iY):GetNumFriendlyUnitsOfType(self.pUnit) < GameDefines.PLOT_UNIT_LIMIT)
	end,

	MovedTo = function(self, iX, iY)
		-- Empty function, we're not interested in our own movement but that of our worker
	end,

	GetWorker = function(self)
		if (self) then
			return self.worker
		else
			return nil
		end
	end,

	-- This method gets called by our associated worker
	MoveTo = function(self, iX, iY, bWayPoint)
		if (self.pUnit:IsDead() or self.pUnit:IsDelayedDeath()) then
			self.worker:RemoveEscort(true)
			self.wayPoints = nil
		else
			debug(string.format("%s moving to (%i, %i)", self:ToString(), iX, iY))

			if (self:MayEnter(iX, iY)) then
				self.wayPoints = nil

				self:Wake()
				self:GoTo(iX, iY)
				else
				self.wayPoints = self.wayPoints or {}

				if (bWayPoint) then
					table.insert(self.wayPoints, 1, {x=iX, y=iY})
				else
					table.insert(self.wayPoints, {x=iX, y=iY})
				end

				debug(string.format("%s is blocked at (%i, %i)", self:ToString(), iX, iY))
				local pPlot = Map.GetPlot(iX, iY)
				local iTeam = self.pUnit:GetTeam()
				local iDomain = self.pUnit:GetDomainType()
				local bIsCombat = self.pUnit:IsCombatUnit()

				for iPlotUnit = 0, pPlot:GetNumUnits()-1, 1 do
					local pPlotUnit = pPlot:GetUnit(iPlotUnit)

					if (pPlotUnit:GetDomainType() == iDomain and pPlotUnit:IsCombatUnit() == bIsCombat and pPlotUnit:GetTeam() == iTeam) then
						local blocker = BlockerManager:Get(pPlotUnit)
						blocker:AddBlocking(self.pUnit)
						-- Don't "break" here, as if the player has changed the 1UPT rule there may be multiple possible blockers
					end
				end
			end

		end
	end,

  -- MoveTo() = try and go there, GoTo() = really go there
	GoTo = function(self, iX, iY)
		local iDistance = Map.PlotDistance(iX, iY, self.pUnit:GetX(), self.pUnit:GetY())
		if (iDistance == 1) then
			-- We are adjacent to the plot, just go there
			self.pUnit:SetMoves(math.max(GameDefines.MOVE_DENOMINATOR/2, self.pUnit:GetMoves()))
			self.pUnit:PushMission(MissionTypes.MISSION_MOVE_TO, iX, iY)
		elseif (iDistance > 1) then
			-- Give ourselves the FlatMovementRate promotion so that we can get there in one go
			-- We need flat movement rate for the following scenario
			--  * Worker+Escort on hill next to a river, next to grassland with a fortified Warrior, next to Wheat
			--  * Worker finishes the mine, crosses river and stops.  Escort can't follow due to blocker (fortified Warrior)
			--  * Next turn worker moves onto wheat, escort still can't follow as crossing the river uses all their movement and they can't get into the blocked hex
			local bHasFlatMoves = self.pUnit:IsHasPromotion(GameInfoTypes.PROMOTION_FLAT_MOVEMENT_COST)
			self.pUnit:SetHasPromotion(GameInfoTypes.PROMOTION_FLAT_MOVEMENT_COST, true)

			-- Give ourselves enough movement to get there in one go, and move
			self.pUnit:SetMoves(math.max(iDistance * GameDefines.MOVE_DENOMINATOR, self.pUnit:GetMoves()))
			self.pUnit:PushMission(MissionTypes.MISSION_MOVE_TO, iX, iY)

			-- Remove the flat movement promotion if necessary
			if (not bHasFlatMoves) then
				self.pUnit:SetHasPromotion(GameInfoTypes.PROMOTION_FLAT_MOVEMENT_COST, false)
			end
		end
		self:Fortify()
	end,

	Fortify = function(self)
 		-- Fortify, Sentry or Do Not as appropriate
		if (self.pUnit:CanFortify(self.pUnit:GetPlot()) and self.pUnit:GetFortifyTurns() == 0) then
			debug(string.format("%s is digging in", self:ToString()))
			self.pUnit:PushMission(MissionTypes.MISSION_FORTIFY)
		elseif (self.pUnit:CanSentry(self.pUnit:GetPlot())) then
			debug(string.format("%s is on sentry duty", self:ToString()))
			self.pUnit:PushMission(MissionTypes.MISSION_ALERT)
		elseif (self.pUnit:CanSleep(self.pUnit:GetPlot())) then
			debug(string.format("%s is catching some zzzz", self:ToString()))
			self.pUnit:PushMission(MissionTypes.MISSION_SLEEP)
		elseif (self.pUnit:GetFortifyTurns() == 0 and self.pUnit:IsCombatUnit()) then	
			self.pUnit:SetMoves(0)
		end	
	end,

	Wake = function(self)
		self.pUnit:PopMission()
	end,

	Unblock = function(self, iX, iY)
		debug(string.format("Blocker at (%i, %i) just moved out of %s way", iX, iY, self:ToString()))

		-- If we still want to get to that plot and can enter it, go there
		if (self.wayPoints and self:MayEnter(iX, iY)) then
			-- Search the way points backwards until we find this plot (backwards as the worker may have looped back on themselves)
			for i = #self.wayPoints, 1, -1 do
				if (iX == self.wayPoints[i].x and iY == self.wayPoints[i].y) then
					-- Remove all prior way points
					for r = 1, i, 1 do
						table.remove(self.wayPoints, 1)
					end

					self:MoveTo(iX, iY, true)
					break
				end
			end
		end
	end
}
EscortManager = MoveAwareUnitManager:new(Escort)


--
-- Blocker class - wraps up useful operations on a Blocker
--
Blocker = {
	new = function(self, pUnit)
		local parent = MoveAwareUnit:new(pUnit)

		local me = {}
		-- The next line says "if you can't find what you're looking for in me, try my class (Blocker), then my parent class (MoveAwareUnit)
		setmetatable(me, {__index = function(_, key) return ((self[key]) and self[key] or parent[key]) end})

		me.iBlockX = pUnit:GetX()
		me.iBlockY = pUnit:GetY()

		me.blocking = nil

		return me
	end,

	AddBlocking = function(self, pEscort)
		-- If we're immobile, we ain't ever going to get out of the way!
		if (not self.pUnit:IsImmobile()) then
			-- I can be blocking more than one escort
			self.blocking = self.blocking or {}

			for i = 1, #self.blocking, 1 do
				if (self.blocking:Equals(pEscort)) then
					return
				end
			end

			table.insert(self.blocking, EscortManager:Get(pEscort))
		end
	end,

	IsBlocking = function(self)
		return (self.blocking ~= nil)
	end,

	MovedTo = function(self, iX, iY)
		debug(string.format("Blocker %s just moved from (%i, %i) to (%i, %i)", self:ToString(), self.iBlockX, self.iBlockY, iX, iY))

		if (self:IsBlocking()) then
			-- Notify all blocked escorts that I just moved
			for _, blocked in pairs(self.blocking) do
				blocked:Unblock(self.iBlockX, self.iBlockY)
			end
		end

		-- If the 1UPT rule has been removed the ex-blocker may have just become part of a stack that is also blocking,
		-- but there is little we can do about it, so just ignore it for the time being,
		-- and hope one of the other units moves out of the way!
		-- TODO - It may be possible to look for blockers in the hex and if present duplicate their blocking array
		self.blocking = nil
	
		-- Remember the new position in case I'm about to block another unit
		self.iBlockX = iX
		self.iBlockY = iY
	end,
}
BlockerManager = MoveAwareUnitManager:new(Blocker)

--[[
-- Create a worker
local worker = WorkerManager:Get(pWorkerUnit)
-- and assign them an escort
worker:AddEscort(pEscortUnit)
-- as the worker moves around, they will be followed by the escort

pWorker=Players[0]:GetUnitByID(24576); pEscort=Players[0]:GetUnitByID(16385); pBlocker=Players[0]:GetUnitByID(32770)
worker = WorkerManager:Get(pWorker); worker:AddEscort(pEscort)
]]
