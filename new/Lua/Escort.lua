-- Lua Script1
-- Author: Mark
-- DateCreated: 5/12/2013 9:02:41 AM
--------------------------------------------------------------
print("--[ Escort Mod Loaded ]--")

MapModData.g_bDebug	= MapModData.g_bDebug or false
local g_bDebug		= MapModData.g_bDebug

include("SelfAwareUnits.lua")
include("PlotIterators.lua")
include("FLuaVector.lua")

local MAX_MOVE_TO_ESCORT_RANGE	= 4
local bClearEscortHighlight = false

local EscortAction = {
	Name = "Escort",
	Title = Locale.ConvertTextKey("TXT_KEY_ESCORT_TITLE"),
	OrderPriority = 89,
	IconAtlas = "CITIZEN_ATLAS",
	PortraitIndex = 6,
	ToolTip = function(pAction, pUnit) return EscortTooltip(pAction, pUnit) end,
	Condition = function(pAction, pUnit) return ShowEscortButton(pAction, pUnit) end,
	Disabled = function(pAction, pUnit) return DisabledEscortButton(pAction, pUnit) end, 
	Action = function(pAction, pUnit, eClick)
		local bResult = DoAutomation(pAction, pUnit, eClick) 
		Events.SerialEventUnitInfoDirty()
		return bResult
	end,
}
LuaEvents.UnitPanelActionAddin(EscortAction)

local CancelEscortAction = {
	Name = "CancelEscort",
	Title = Locale.ConvertTextKey("TXT_KEY_CANCEL_ESCORT_TITLE"),
	OrderPriority = 89,
	IconAtlas = "UNIT_ACTION_ATLAS",
	PortraitIndex = 0,
	ToolTip = function(pAction, pUnit) return CancelEscortTooltip(pAction, pUnit) end,
	Condition = function(pAction, pUnit) return ShowCancelButton(pAction, pUnit) end,
	Disabled = false, function(pAction, pUnit) return DisabledCancelButton(pAction, pUnit) end, 
	Action = function(pAction, pUnit, eClick)
		local bResult = StopAutomation(pAction, pUnit, eClick) 
		Events.SerialEventUnitInfoDirty()
		return bResult
	end,
}
LuaEvents.UnitPanelActionAddin(CancelEscortAction)

function FindWorkerToEscort(pUnit)
	local pTempUnit = nil

	for pPlot in PlotAreaSpiralIterator(pUnit:GetPlot(), MAX_MOVE_TO_ESCORT_RANGE, SECTOR_NORTH, DIRECTION_CLOCKWISE, DIRECTION_OUTWARDS, CENTRE_INCLUDE) do
		local i = 0
		for i = 0, pPlot:GetNumUnits()-1 do
			pTempUnit = pPlot:GetUnit(i)
			debug(pTempUnit:GetName() .. ' Found')
			if (pUnit ~= pTempUnit and pTempUnit:GetOwner() == pUnit:GetOwner()) then
				local pWorker = WorkerManager:Get(pTempUnit)
				if (not pWorker:IsEscorted() and pWorker:IsValidEscort(pUnit)) then
					return pTempUnit
				end
			end
		end
	end
		
	return nil
end

function debug(sString)
	if g_bDebug then
		print(sString)
	end
end

function TableToString(t)
	-- don't get fancy we already know there is no recursion
	local result = ''
	for k, v in pairs(t) do
		if (string.len(result) > 0) then 
			result = result .. ', '
		end
		result = result .. tostring(k) .. '=' .. tostring(v)
	end	
	return result
end

function StringToTable(str)
	-- we already know the table isn't recursive
	local result = {}
	for k, v in string.gmatch(str, "(%w+)=(%w+)") do
		result[tonumber(k)] = tonumber(v)
	end
	return result
end

function EscortTooltip(pAction, pUnit)
	pWorker = FindWorkerToEscort(pUnit)
	if (pWorker) then
		return Locale.ConvertTextKey("TXT_KEY_ESCORT_TIP", pWorker:GetName())
	else
		return Locale.ConvertTextKey("TXT_KEY_CANCEL_ESCORT_TIP_NOTFOUND")
	end
end

function CancelEscortTooltip(pAction, pUnit)
	pEscort = EscortManager:Get(pUnit)
	if (pEscort and pEscort:IsEscort()) then
		return Locale.ConvertTextKey("TXT_KEY_CANCEL_ESCORT_TIP", pEscort:GetName())
	else
		return Locale.ConvertTextKey("TXT_KEY_CANCEL_ESCORT_TIP_NOTFOUND")
	end
end

function ShowCancelButton(pAction, pUnit)
	local pEscort = EscortManager:Get(pUnit)
	if (pEscort:IsEscort()) then
		return true
	end

	return false
end

function ShowEscortButton(pAction, pUnit)
	debug('Condition Escort')
	-- do not show if domain is air
	if (pUnit:GetDomainType() == GameInfoTypes.DOMAIN_AIR) then
		return false
	end
	-- do not show if unit is stationary
	if (pUnit:IsImmobile()) then
		return false
	end
	-- do not show if the unit is type RECON (scouts)
	if (pUnit:GetUnitCombatType() == GameInfoTypes.UNITCOMBAT_RECON) then
		return false
	end
	-- do not show if the unit is a civilian
	if (not pUnit:IsCombatUnit()) then
		return false
	end
	-- do not show if we are already an escort
	pEscort = EscortManager:Get(pUnit)
	if (pEscort:IsEscort()) then
		return false
	end

	return true
end

function DisabledCancelButton(pAction, pUnit)
	local pEscort = EscortManager:Get(pUnit)
	if (pEscort:IsEscort()) then
		return true
	end
	
	return false
end

function DisabledEscortButton(pAction, pUnit)
	debug('Disable Escort')
	
	-- disable if out of moves
	if (pUnit:MovesLeft() == 0 or pUnit:IsAutomated()) then
		return true
	end

	-- disable if no other units are in escort range
	-- disable if all units in range already have an escort
	pWorker = FindWorkerToEscort(pUnit)
	return (not pWorker)
end

function DoAutomation(pAction, pUnit, eClick)
	debug('Start')
	-- find the nearest unescorted unit
	local pTempUnit = FindWorkerToEscort(pUnit)
	if (pUnit ~= pTempUnit and pTempUnit:GetOwner() == pUnit:GetOwner()) then
		local pWorker = WorkerManager:Get(pTempUnit)
		if (not pWorker:IsEscorted()) then
			debug('Set to escort')
			-- Set this unit to escort the nearest unescorted unit
			pUnit:DoCommand(GameInfoTypes.COMMAND_WAKE)
			pWorker:AddEscort(pUnit)
			pEscort = EscortManager:Get(pUnit)
			pEscort:MoveTo(pTempUnit:GetX(), pTempUnit:GetY())
			pEscort:Fortify()
		end
	end
end

function StopAutomation(pAction, pUnit, eClick)
	debug('Stop')
	-- Stop automation for iUnit
	pEscort = EscortManager:Get(pUnit)
	pEscort:RemoveWorker(false)	
	return false
end

function DoExplore(iPlayer, iUnit)
	pPlayer = Players[iPlayer]
	pUnit = pPlayer:GetUnitByID(iUnit)
	pEscort = EscortManager:Get(pUnit)
	pEscort:RemoveWorker(false)
	return true
end

function DoTurn(iPlayer)
	if (Players[iPlayer]:IsHuman()) then
		Events.ClearHexHighlights()
		WorkerManager:Serialize(iPlayer)
	end
end

function P_DoExplore(iPlayer, iUnit)
	local bSuccess
	local sResult
	bSuccess, sResult = pcall(DoExplore, iPlayer, iUnit)
	if (not bSuccess) then
		debug(sResult)
	end
end

function P_DoTurn(iPlayer)
	local bSuccess
	local sResult
	bSuccess, sResult = pcall(DoTurn, iPlayer)
	if (not bSuccess) then
		debug(sResult)
	end
end

function DoUnitSelectionChange(iPlayerID, iUnitID, i, j, k, isSelected)
	if (isSelected) then
		local pUnit = Players[iPlayerID]:GetUnitByID(iUnitID)
		if (pUnit and not pUnit:IsCombatUnit()) then
			return
		end
		pWorker = FindWorkerToEscort(pUnit)
		if (pWorker) then
			Events.SerialEventHexHighlight(ToHexFromGrid(Vector2(pWorker:GetX(), pWorker:GetY())), true, nil, "MovementRangeBorder")
			bClearEscortHighlight = true
			UI.LookAt(pWorker:GetPlot(), 0)
		end
	end
end

function DoUnitSelectionCleared()
	if (bClearEscortHighlight) then
		Events.ClearHexHighlightStyle("MovementRangeBorder")
		bClearEscortHighlight = false
	end
end

function DoChangeEvent(iPlayer, iUnit)
	pPlayer = Players[iPlayer]
	pUnit = pPlayer:GetUnitByID()
	UI.SetDirty(InterfaceDirtyBits.UnitInfo_DIRTY_BIT, true)
end

function DoInitMod()
	for _, v in pairs(Players) do
		if (v:IsHuman()) then
			WorkerManager:Load(v:GetID())
		end
	end
end

Events.UnitSelectionChanged.Add(DoUnitSelectionChange)
Events.UnitSelectionCleared.Add(DoUnitSelectionCleared)
Events.UnitActionChanged.Add(DoChangeEvent)
Events.SequenceGameInitComplete.Add(DoInitMod)
GameEvents.UnitGetSpecialExploreTarget.Add(g_bDebug and P_DoExplore or DoExplore)
GameEvents.PlayerDoTurn.Add(g_bDebug and P_DoTurn or DoTurn)
