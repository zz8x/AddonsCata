-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- Возвращает список членов группы отсортированных по приоритету исцеления
local members = {}
local membersHP = {}
local protBuffsList = {"Ледяная глыба", "Божественный щит", "Превращение", "Щит земли", "Частица Света"}
local dangerousType = {"worldboss", "rareelite", "elite"}
local function compareMembers(u1, u2) 
    return membersHP[u1] < membersHP[u2]
end
function GetHealingMembers(units)
    local myHP = UnitHealth100("player")
    if #members > 0 and FastUpdate then
        return members
    end
    wipe(members)
    wipe(membersHP)
    if units == nil then 
        tinsert(members, "player")
        membersHP["player"] = UnitHealth100("player")
        return members, membersHP
    end
    for i = 1, #units do
        local u = units[i]
        if CanHeal(u) then 
            local h =  UnitHealth100(u)
            if IsFriend(u) and UnitAffectingCombat(u) then 
                h = h - (110 - h) / 10
            end
            if UnitIsPet(u) then
                if UnitAffectingCombat("player") then 
                    h = h * 1.5
                end
            else
                if not IsPvP() then
                    local status = 0
                    for j = 1, #TARGETS do
                        local t = TARGETS[j]
                        if tContains(dangerousType, UnitClassification(t)) then 
                            local isTanking, state, scaledPercent, rawPercent, threatValue = UnitDetailedThreatSituation("player", t)
                            if state ~= nil and state > status then status = state end
                        end
                    end
                    h = h - 2 * status
                end
                if not IsOneUnit("player", u) and HasBuff(protBuffsList, 1, u) then h = h + 5 end
                if not IsArena() and myHP < 50 and not IsOneUnit("player", u) and not (UnitThreat(u) == 3) then h = h + 30 end
            end
            tinsert(members, u)
            membersHP[u] = h
        end
    end
    sort(members, compareMembers)  
    return members
end
------------------------------------------------------------------------------------------------------------------
-- friend list
local friendList = {}
local function friendListUpdate()
    wipe(friendList)
    local numberOfFriends = GetNumFriends()
    for i = 1, numberOfFriends do
        local name = GetFriendInfo(i);
        if name then 
            friendList[name] = true
        end
    end
end
friendListUpdate()
AttachEvent("FRIENDLIST_UPDATE", friendListUpdate)

function IsFriend(unit)
    if IsOneUnit(unit, "player") then return true end
    if not UnitIsPlayer(unit) or not IsInteractUnit(unit) then return false end
    return friendList[UnitName(unit)]
end

------------------------------------------------------------------------------------------------------------------
-- unit filted start
local IgnoredNames = {}

function Ignore(target)
    if target == nil then target = "target" end
    local n = UnitName(target)
    if n == nil then 
        Notify(target .. " not exists")
        return 
    end
    IgnoredNames[n] = true
    Notify("Ignore " .. n)
end

function IsIgnored(target)
    if target == nil then target = "target" end
    local n = UnitName(target)
    if n == nil or not IgnoredNames[n] then return false end
    -- Notify(n .. " in ignore list")
    return true
end

function NotIgnore(target)
    if target == nil then target = "target" end
    local n = UnitName(target)
    if n then 
        IgnoredNames[n] = false
        Notify("Not ignore " .. n)
    end
end

function NotIgnoreAll()
    wipe(IgnoredNames)
    Notify("Not ignore all")
end
-- unit filted start end

------------------------------------------------------------------------------------------------------------------
local units = {}
local realUnits = {}
function GetUnits()
	wipe(units)
	tinsert(units, "target")
	tinsert(units, "focus")
	local members = GetGroupUnits()
	for i = 1, #members, 1 do 
		tinsert(units, members[i])
		tinsert(units, members[i] .."pet")
	end
	tinsert(units, "mouseover")
	wipe(realUnits)
    for i = 1, #units do 
        local u = units[i]
        local exists = false
        for j = 1, #realUnits do 
        exists = IsOneUnit(realUnits[j], u)
			if exists then break end 
		end
        if not exists and InInteractRange(u) then 
			tinsert(realUnits, u) 
		end
    end
    return realUnits
end

------------------------------------------------------------------------------------------------------------------
local groupUnits  = {}
function GetGroupUnits()
	wipe(groupUnits)
	tinsert(groupUnits, "player")
    if not InGroup() then return groupUnits end
    local name = "party"
    local size = MAX_PARTY_MEMBERS
	if InRaid() then
		name = "raid"
		size = MAX_RAID_MEMBERS
    end
    for i = 0, size do 
		tinsert(groupUnits, name..i)
    end
    return groupUnits
end
------------------------------------------------------------------------------------------------------------------
-- /run DоCommand("cl", GetSameGroupUnit("mouseover"))
function GetSameGroupUnit(unit)
    local group = GetGroupUnits()
    for i = 1, #group do
        if InOneUnit(unit, group[i]) then return group[i] end
    end
end

------------------------------------------------------------------------------------------------------------------
local targets = {}
local realTargets = {}
function GetTargets()
	wipe(targets)
	tinsert(targets, "target")
	tinsert(targets, "focus")
	if IsArena() then
		for i = 1, 5 do 
			 tinsert(targets, "arena" .. i)
		end
	end
	for i = 1, 4 do 
		 tinsert(targets, "boss" .. i)
	end
	local members = GetGroupUnits()
	for i = 1, #members do 
		 tinsert(targets, members[i] .."-target")
		 tinsert(targets, members[i] .."pet-target")
	end
	tinsert(targets, "mouseover")
	wipe(realTargets)
    for i = 1, #targets do 
        local u = targets[i]
        
        local exists = false
        for j = 1, #realTargets do 
 			exists = IsOneUnit(realTargets[j], u) 
			if exists then break end 
		end
        
        if not exists and IsValidTarget(u) and (IsArena() or CheckInteractDistance(u, 1) 
                or IsOneUnit("player", u .. '-target')) then 
            tinsert(realTargets, u) 
        end
        
    end
    return realTargets
end

------------------------------------------------------------------------------------------------------------------
IsValidTargetInfo = ""
function IsValidTarget(target)
    IsValidTargetInfo = ""
    if target == nil then target = "target" end
    if not UnitName(target) then 
        IsValidTargetInfo = "Нет цели"
        return false 
    end
    if IsIgnored(target) then 
        IsValidTargetInfo = "Цель в игнор листе"
        return false 
    end
    if UnitIsDeadOrGhost(target) and not HasBuff("Притвориться мертвым", 1,target) then 
        IsValidTargetInfo = "Цель дохлая"
        return false 
    end
    --[[if (UnitInParty(target) or UnitInRaid(target)) then 
        IsValidTargetInfo = "Цель из нашей пати"
        return false 
    end]]

    if not UnitCanAttack("player", target) then
        IsValidTargetInfo = "Невозможно атаковать"
        return false
    end

    --[[if UnitIsEnemy("player",target) then 
        return true 
    end]]
    return true
end

------------------------------------------------------------------------------------------------------------------
function IsInteractUnit(t)
    if not UnitExists(t) then return false end
    if IsIgnored(t) then return false end
    if IsValidTarget(t) then return false end
    if UnitIsDeadOrGhost(t) then return false end
    if UnitIsCharmed(t) then return false end
    return not UnitIsEnemy("player",t)
end

------------------------------------------------------------------------------------------------------------------
function CanHeal(t)
    return InInteractRange(t) and not HasDebuff("Смерч", 0.1, t) and IsVisible(t)
end 
------------------------------------------------------------------------------------------------------------------
function GetClass(target)
    if not target then target = "player" end
    local _, class = UnitClass(target)
    return class
end

------------------------------------------------------------------------------------------------------------------
function HasClass(units, classes)
    local function checkClass(u, classes)
        return  UnitExists(u) and UnitIsPlayer(u) and (type(classes) == 'table' and tContains(classes, GetClass(u)) or classes == GetClass(u)) 
    end
    if type(units) == 'table' then
    	for i = 1, #units do
            local u = units[i]
    		if checkClass(u, classes) then return true end
    	end
    else
        if checkClass(units, classes) then return true end
    end
    return false
end

------------------------------------------------------------------------------------------------------------------
function GetUnitType(target)
    if not target then target = "target" end
    local unitType = UnitName(target)
    if UnitIsPlayer(target) then
        unitType = GetClass(target)
    end
    if UnitIsPet(target) then
        unitType ='PET'
    end
    return unitType
end

------------------------------------------------------------------------------------------------------------------
function UnitIsNPC(unit)
    return UnitExists(unit) and not (UnitIsPlayer(unit) or UnitPlayerControlled(unit) or UnitCanAttack("player", unit));
end

------------------------------------------------------------------------------------------------------------------
function UnitIsPet(unit)
    return UnitExists(unit) and not UnitIsNPC(unit) and not UnitIsPlayer(unit) and UnitPlayerControlled(unit);
end

------------------------------------------------------------------------------------------------------------------
function IsOneUnit(unit1, unit2)
    if not UnitExists(unit1) or not UnitExists(unit2) then return false end
    return UnitGUID(unit1) == UnitGUID(unit2)
end

------------------------------------------------------------------------------------------------------------------
function UnitThreat(u, t)
    if not UnitIsPlayer(u) then return 0 end
    local threat = UnitThreatSituation(u, t)
    if threat == nil then threat = 0 end
    return threat
end

------------------------------------------------------------------------------------------------------------------
function UnitThreatAlert(u)
    local threat, target = UnitThreat(u), format("%s-target", u)
    if UnitAffectingCombat(target) 
        and UnitIsPlayer(target) 
        and IsValidTarget(target) 
        and IsOneUnit(u, target .. "-target") then threat = 3 end
    return threat
end

------------------------------------------------------------------------------------------------------------------
function UnitHealth100(target)
    if target == nil then target = "player" end
    return UnitHP(target) * 100 / UnitHealthMax(target)
end

------------------------------------------------------------------------------------------------------------------
function UnitMana100(target)
    if target == nil then target = "player" end
    return UnitMana(target) * 100 / UnitManaMax(target)
end

------------------------------------------------------------------------------------------------------------------
function UnitLostHP(unit)
    local hp = UnitHP(unit)
    local maxhp = UnitHealthMax(unit) 
   -- if target == "player" and IsCtr() then return maxhp / 2 end
    local lost = maxhp - hp
    if UnitThreatAlert(unit) == 3 then lost = lost * 1.5 end
    return lost
end

------------------------------------------------------------------------------------------------------------------
function UnitHP(unit)
  --if target == "player" and IsCtr() then return 50 end
  local hp = UnitHealth(unit) + (UnitGetIncomingHeals(unit) or 0)
  if hp > UnitHealthMax(unit) then hp = UnitHealthMax(unit) end
  return hp
end

------------------------------------------------------------------------------------------------------------------
function InGroup()
    return (InRaid() or InParty())
end

------------------------------------------------------------------------------------------------------------------
function InRaid()
    return (GetNumRaidMembers() > 0)
end

------------------------------------------------------------------------------------------------------------------
function InParty()
    return (GetNumPartyMembers() > 0)
end

------------------------------------------------------------------------------------------------------------------
function IsBattleground()
    local inInstance, instanceType = IsInInstance()
    return (inInstance ~= nil and instanceType =="pvp")
end

------------------------------------------------------------------------------------------------------------------
function IsArena()
    local inInstance, instanceType = IsInInstance()
    return (inInstance ~= nil and instanceType =="arena")
end

------------------------------------------------------------------------------------------------------------------
function IsPvP()
    return (IsBattleground() or IsArena() or (IsValidTarget("target") and UnitIsPlayer("target")))
end
------------------------------------------------------------------------------------------------------------------
function PlayerInPlace()
    return (GetUnitSpeed("player") == 0) and not IsFalling()
end

------------------------------------------------------------------------------------------------------------------
if ZoneData == nil then ZoneData = {} end
local function getMapID()
    local id = GetCurrentMapAreaID()
    if ( id < 0 and GetCurrentMapContinent() == WORLDMAP_WORLD_ID ) then
        return 0
    end
    return id
end
local updateZoneX, undateZoneY, updateZoneStart, updateZoneSpeed, updateZoneDir, updateZoneId = 0, 0, 0, 0, 1, 0
local function ZoneChanged(event, ...)
    SetMapToCurrentZone()
end
AttachEvent('PLAYER_ENTERING_WORLD', ZoneChanged)
AttachEvent('ZONE_CHANGED', ZoneChanged)
AttachEvent('ZONE_CHANGED_NEW_AREA', ZoneChanged)
AttachEvent('ZONE_CHANGED_INDOORS', ZoneChanged)
local _dx, _dy
local abs = math.abs
local cos = math.cos
local sin = math.sin
local function UpdateZone() 
    local speed = IsFalling() and 0 or GetUnitSpeed("player")
    local time = GetTime() - updateZoneStart
    local id = getMapID()
    if (math.abs(updateZoneDir - GetPlayerFacing())) > 0.01 or (speed ~= updateZoneSpeed) or (id ~= updateZoneId) then
        updateZoneStart = 0
    end
    
    if updateZoneStart > 0 and time > 0.3 then
        local currentX,currentY = GetPlayerMapPosition("player")
        local l = updateZoneSpeed  * time

        local dx = updateZoneX - currentX
        if _dx ~= nil and ((_dx > 0 and dx < 0) or (_dx > 0 and dx < 0)) then
            updateZoneStart = 0
        end
        _dx = dx
        dx = abs(dx)
        if updateZoneStart > 0 and dx > 0.005 then
            ZoneData[updateZoneId].Width = (l * abs(sin(updateZoneDir))) / dx
        end

        local dy = undateZoneY - currentY
        if _dy ~= nil and ((_dy > 0 and dy < 0) or (_dy > 0 and dy < 0)) then
            updateZoneStart = 0
        end
        _dy = dy
        dy = abs(dy)
        if updateZoneStart > 0 and dy > 0.005 then
            ZoneData[updateZoneId].Height = (l * abs(cos(updateZoneDir))) / dy
        end
    end
    if speed > 0  and updateZoneStart == 0 then
        updateZoneX,  undateZoneY = GetPlayerMapPosition("player")
        updateZoneStart = GetTime()
        updateZoneSpeed = speed
        updateZoneDir = GetPlayerFacing()
        updateZoneId = getMapID()
        if ZoneData[updateZoneId] == nil then
            ZoneData[updateZoneId] = {Width = 1, Height = 1}
        end
    end
end
AttachUpdate(UpdateZone, 0.25)

------------------------------------------------------------------------------------------------------------------
function GetYardCoords(unit)
    if not unit then unit = "player" end
    local id = getMapID()
    local x, y = GetPlayerMapPosition(unit)
    return x *  (ZoneData[id] and ZoneData[id].Width or 1), y * (ZoneData[id] and ZoneData[id].Height or 1)
end

------------------------------------------------------------------------------------------------------------------
function CheckDistanceCoord(x1, y1, x2, y2)
    if x1 == 0 or y1 == 0 or x2 == 0 or y2 == 0 then return nil end
    local dx = (x1-x2)
    local dy = (y1-y2)
    return sqrt( dx^2 + dy^2 )
end

------------------------------------------------------------------------------------------------------------------
function CheckDistance(unit1,unit2)
  if IsOneUnit(unit1,unit2) then return 0 end
  local x1,y1 = GetYardCoords(unit)
  local x2,y2 = GetYardCoords(unit2)
  return CheckDistanceCoord(x1, y1, x2, y2)
end

------------------------------------------------------------------------------------------------------------------
function InDistance(unit1,unit2, distance)
  local d = CheckDistance(unit1, unit2)
  return not d or d < distance
end

------------------------------------------------------------------------------------------------------------------
function TargetActualDistance(target)
    if target == nil then target = "target" end
    return (CheckInteractDistance(target, 4) == 1)
end
------------------------------------------------------------------------------------------------------------------
local checkHunter = false;
function CheckTarget(useFocus , actualDistance)
    if not actualDistance then
        actualDistance = TargetActualDistance
    end
    -- проверяем на 
    if IsValidTarget("target") then
       checkHunter = UnitIsPlayer("target") and ("HUNTER" == GetClass("target"))
    else
        if checkHunter then
            RunMacroText("/targetlasttarget")
            if not IsValidTarget("target") then
                checkHunter = false
                if UnitExists("target") then RunMacroText("/cleartarget") end   
            else
                chat("Перевыбрали ханта")
                RunMacroText("/startattack")
                TryAttack() 
            end
        end
    end
    -- помощь в группе
    if not IsValidTarget("target") and InGroup() then
        -- если что-то не то есть в цели
        if UnitExists("target") then RunMacroText("/cleartarget") end
        for i = 1, #TARGET do
            local t = TARGET[i]
            if t and (UnitAffectingCombat(t) or IsPvP()) and actualDistance(t) and (not IsPvP() or UnitIsPlayer(t))  then 
                RunMacroText("/target [@" .. t .. "]")
                if CanAttack("target") then
                    break
                end
            end
        end
    end
    -- пытаемся выбрать ну хоть что нибудь
    if not IsValidTarget("target") then
        -- если что-то не то есть в цели
        if UnitExists("target") then RunMacroText("/cleartarget") end
        RunMacroText("/targetenemy" .. (IsPvP() and "player" or "") .." [nodead]")
        if not IsAttack()  -- если в авторежиме
            and (
            not IsValidTarget("target")  -- вообще не цель
            or (not IsArena() and not actualDistance("target"))  -- далековато
            or (not IsPvP() and not UnitAffectingCombat("target")) -- моб не в бою
            or (IsPvP() and not UnitIsPlayer("target")) -- не игрок в пвп
            )  then 
            if UnitExists("target") then RunMacroText("/cleartarget") end
        end
    end

    if useFocus ~= false then 
        if IsMouse3() and IsValidTarget("mouseover") and not IsOneUnit("target", "mouseover") then 
            RunMacroText("/focus mouseover") 
        end
        if not IsValidTarget("focus") then
            if UnitExists("focus") then RunMacroText("/clearfocus") end
            for i = 1, #TARGETS do
                local t = TARGETS[i]
                if UnitAffectingCombat(t) and actualDistance(t) and not IsOneUnit("target", t) and (not IsPvP() or UnitIsPlayer(t)) then 
                    RunMacroText("/focus " .. t) 
                    break
                end
            end
        end
        
        if not IsValidTarget("focus") or IsOneUnit("target", "focus") or (not IsArena() and not actualDistance("focus")) then
            if UnitExists("focus") then RunMacroText("/clearfocus") end
        end
    end

    if IsArena() then
        if IsValidTarget("target") and (not UnitExists("focus") or IsOneUnit("target", "focus")) then
            if IsOneUnit("target","arena1") then RunMacroText("/focus arena2") end
            if IsOneUnit("target","arena2") then RunMacroText("/focus arena1") end
        end
    end
end