﻿-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- Время сетевой задержки 
LagTime = 0
local lastUpdate = 0
local function UpdateLagTime()
    if GetTime() - lastUpdate < 30 then return end
    lastUpdate = GetTime() 
    LagTime = tonumber((select(3, GetNetStats()) or 0)) / 1000
end
AttachUpdate(UpdateLagTime)

local sendTime = nil
local function CastLagTime(event, ...)
    local unit, spell = select(1,...)
    if spell and unit == "player" then
        if event == "UNIT_SPELLCAST_SENT" then
            sendTime = GetTime()
        else
            if not sendTime then return end
            LagTime = (GetTime() - sendTime)
            sendTime = nil
        end
    end
end
AttachEvent('UNIT_SPELLCAST_SENT', CastLagTime)
AttachEvent('UNIT_SPELLCAST_START', CastLagTime)
AttachEvent('UNIT_SPELLCAST_SUCCEEDED', CastLagTime)
AttachEvent('UNIT_SPELLCAST_FAILED', CastLagTime)

------------------------------------------------------------------------------------------------------------------
function IsPlayerCasting(spellName, last)
    local spell = UnitIsCasting("player", last)
    if not spell then return false end
    if spellName then
        return (spell == spellName)
    end
    return true
end

-- using (nil if nothing casting)
-- local spell, left, duration, channel, nointerrupt = UnitIsCasting("unit")
function UnitIsCasting(unit, last)
    if type(last) ~= "number" then last = LagTime * 0.7 end
    if not unit then unit = "player" end
    local channel = false
    -- name, subText, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo("unit")
    local spell, _, _, _, startTime, endTime, _, _, notinterrupt = UnitCastingInfo(unit)
    if spell == nil then
        --name, subText, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo("unit")
        spell, _, _, _, startTime, endTime, _, nointerrupt = UnitChannelInfo(unit)
        channel = true
    end
    if spell == nil or not startTime or not endTime then return nil end
    local left = endTime * 0.001 - GetTime()
    local duration = (endTime - startTime) * 0.001
    if left < last then return nil end
    --print(unit, spell, left, duration, channel, nointerrupt)
    return spell, left, duration, channel, nointerrupt
end

------------------------------------------------------------------------------------------------------------------
local spellToIdList = {}
function GetSpellId(name, rank)
    spellGUID = name
    if rank then
        spellGUID = name .. rank
    end
    local result = spellToIdList[spellGUID]
    if nil == result then
        local link = GetSpellLink(name,rank)
        if not link then 
            result = 0 
        else
            result = 0 + link:match("spell:%d+"):match("%d+")
        end
        spellToIdList[spellGUID] = result
    end
    return result
end

------------------------------------------------------------------------------------------------------------------
function HasSpell(spellName)
    if GetSpellInfo(spellName) then return true end
    return false
end
------------------------------------------------------------------------------------------------------------------
GCDDuration = 1.5
function GetGCDLeft()
  local start, duration = GetSpellCooldown(61304);
  if not start then return 0 end
  if start == 0 then return 0 end
  if duration then GCDDuration = duration end
  return start + duration - GetTime()
end

function InGCD()
    return GetGCDLeft() > LagTime
end

local abs = math.abs
function IsReady(left, checkGCD)
    if checkGCD == nil then checkGCD = false end
    if not checkGCD then
        local gcdLeft = GetGCDLeft()
        if (abs(left - gcdLeft) < 0.01) then return true end
    end
    --if left > LagTime then return false end
    if left ~= 0 then return false end
    return true
end
------------------------------------------------------------------------------------------------------------------
-- Interact range - 40 yards
local interactSpells = {
    DRUID = "Целительное прикосновение",
    PALADIN = "Свет небес",
    SHAMAN = "Волна исцеления",
    PRIEST = "Малое исцеление"
}
InteractRangeSpell = interactSpells[GetClass()]

function InInteractRange(unit)
    -- need test and review
    if (unit == nil) then unit = "target" end
    if not IsInteractUnit(unit) then return false end
    if InteractRangeSpell then return IsSpellInRange(InteractRangeSpell, unit) == 1 end
    return  CheckInteractDistance(unit, 4) == 1
end
------------------------------------------------------------------------------------------------------------------
function InMelee(target)
    if (target == nil) then target = "target" end
    return IsItemInRange(37727, "target") == 1
end

------------------------------------------------------------------------------------------------------------------
function IsReadySpell(name, checkGCD)
    local left = GetSpellCooldownLeft(name)
    return IsReady(left, checkGCD)
end

------------------------------------------------------------------------------------------------------------------
function GetSpellCooldownLeft(name)
    local start, duration, enabled = GetSpellCooldown(name);
    if enabled ~= 1 then return 1 end
    if not start then return 0 end
    if start == 0 then return 0 end
    local left = start + duration - GetTime()
    return left
end

------------------------------------------------------------------------------------------------------------------
function UseMount(mountName)
    if IsPlayerCasting() then return false end
    if InGCD() then return false end
    if IsMounted() then return false end
    if Debug then
        print(mountName)
    end
    RunMacroText("/use "..mountName)
    return true
end
------------------------------------------------------------------------------------------------------------------
function InRange(spell, target) 
    if target == nil then target = "target" end
    if spell and IsSpellInRange(spell, target) == 0 then return false end 
    return true    
end

------------------------------------------------------------------------------------------------------------------
local InCast = {}
local function getCastInfo(spell)
	if not InCast[spell] then
		InCast[spell] = {}
	end
	return InCast[spell]
end
local function UpdateIsCast(event, ...)
    local unit, spell, rank, target = select(1,...)
    if spell and unit == "player" then
        local castInfo = getCastInfo(spell)
        if event == "UNIT_SPELLCAST_SUCCEEDED"
            and castInfo.StartTime and castInfo.StartTime > 0 then
            castInfo.LastCastTime = castInfo.StartTime 
        end
        if event == "UNIT_SPELLCAST_SENT" then
            castInfo.StartTime = GetTime()
            castInfo.TargetName = target
        else
            castInfo.StartTime = 0
        end
    end
end
AttachEvent('UNIT_SPELLCAST_SENT', UpdateIsCast)
AttachEvent('UNIT_SPELLCAST_SUCCEEDED', UpdateIsCast)
AttachEvent('UNIT_SPELLCAST_FAILED', UpdateIsCast)

function GetLastSpellTarget(spell)
    local castInfo = getCastInfo(spell)
    return (castInfo.Target and castInfo.TargetGUID and UnitExists(castInfo.Target) and UnitGUID(castInfo.Target) == castInfo.TargetGUID) and castInfo.Target or nil
end

function GetSpellLastTime(spell)
    local castInfo = getCastInfo(spell)
    return castInfo.LastCastTime or 0
end

function IsSpellNotUsed(spell, t)
    local castInfo = getCastInfo(spell)
    local last = castInfo.LastCastTime or 0
    return GetTime() - last >= t
end

function IsSpellInUse(spellName)
    if not spellName or not InCast[spellName] or not InCast[spellName].StartTime then return false end
    local start = InCast[spellName].StartTime
    if (GetTime() - start <= 0.5) then return true end
    if IsReadySpell(spellName) then InCast[spellName].StartTime = 0 end
    return false
end
------------------------------------------------------------------------------------------------------------------
local function checkTargetInErrList(target, list)
    if not target then target = "target" end
    if target == "player" then return true end
    if not UnitExists(target) then return false end
    local t = list[UnitGUID(target)]
    if t and GetTime() - t < 1.2 then return false end
    return true;
end

local notVisible = {}
--~ Цель в поле зрения.
function IsVisible(target)
    return checkTargetInErrList(target, notVisible)
end

local notInView = {}
-- передо мной
function IsInView(target)
    return checkTargetInErrList(target, notInView)
end

local notBehind = {}
-- за спиной цели
function IsBehind(target)
    return checkTargetInErrList(target, notBehind)
end

local lastFailedSpellTime = {}
local lastFailedSpellError = {}

function GetLastSpellError(spellName, t)
    if not spellName then return nil end
    local lastTime = lastFailedSpellTime[spellName]
    if t and lastTime and (GetTime() - lastTime > t) then return nil end
    return lastFailedSpellError[spellName]
end

local function UpdateTargetPosition(event, ...)

    local timestamp, type, hideCaster,                                                                      
      sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,   
      spellId, spellName, spellSchool,                                                                     
      amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = ...
    if sourceGUID == UnitGUID("player") and sContains(type, "SPELL_CAST_FAILED") and spellId and spellName  then
        local err = amount
        if err then
            lastFailedSpellTime[spellName] = GetTime()
            lastFailedSpellError[spellName] = err
        end
        local cast = getCastInfo(spellName)
        local guid = cast.TargetGUID or nil
        if err and guid then
            if err == "Цель вне поля зрения." then
                notVisible[guid] = GetTime()
            end
            if err == "Цель должна быть перед вами." then
                notInView[guid] = GetTime() 
            end
            if err == "Вы должны находиться позади цели." then 
                notBehind[guid] = GetTime() 
            end
        end
    end
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', UpdateTargetPosition)
------------------------------------------------------------------------------------------------------------------
local spellsAmounts = {};
local spellsAmount = {};
local function UpdateSpellsAmounts(event, ...)
    local timestamp, type, hideCaster,                                                                      
      sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,   
      spellId, spellName, spellSchool,                                                                     
      amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = ...
    if amount and sourceGUID == UnitGUID("player") and sContains(type, "SPELL_HEAL") and spellId and spellName  then
        local amounts = spellsAmounts[spellName]
        if nil == amounts then amounts = {} end
        tinsert(amounts, amount)
        if #amounts > 5 then tremove(amounts, 1) end
        spellsAmounts[spellName] = amounts
        local average = 0
        for i = 1, #amounts do
            average = average + amounts[i]
        end
        spellsAmount[spellName] = floor(average / #amounts)
    end
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', UpdateSpellsAmounts)

function GetSpellAmount(spellName, expected)
    local amount = spellsAmount[spellName]
    return nil == amount and expected or amount
end
------------------------------------------------------------------------------------------------------------------
local cameraCD = 0;
function TrySpellTargeting()
    if SpellIsTargeting() and GetTime() - cameraCD > 0.05 then 
        cameraCD = GetTime()
        local look = IsMouselooking()
        if look then
            TurnOrActionStop()
        end
        CameraOrSelectOrMoveStart() 
        CameraOrSelectOrMoveStop()
        if look then
            TurnOrActionStart() 
        end
        SpellStopTargeting()
    end
end
------------------------------------------------------------------------------------------------------------------

local badSpellTarget = {}
local inCastSpells = {"Трепка", "Рунический удар", "Удар героя", "Рассекающий удар", "Гиперскоростное ускорение", "Нарукавная зажигательная ракетница"} -- TODO: Нужно уточнить и дополнить.
function UseSpell(spellName, target)
    local dump = false --spellName == "Быстрое восстановление"
    if dump then print("Пытаемся прожать", spellName, "на", target) end
    -- Не мешаем выбрать область для спела (нажат вручную)
    if SpellIsTargeting() then 
        if dump or true then print("Ждем выбор цели, не можем прожать", spellName) end
        SpellStopTargeting()
        return false 
    end 
    -- Не пытаемся что либо прожимать во время каста
    if IsPlayerCasting() then 
        if dump then print("Кастим, не можем прожать", spellName) end
        return false 
    end
    if target == nil and IsHarmfulSpell(spellName) then target = "target" end
    -- Проверяем на наличе спела в спелбуке
    local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange  = GetSpellInfo(spellName)
    if not name then
        if Debug then error("Спел [".. spellName .. "] не найден!") end
        return false;
    end

    local err = GetLastSpellError(spellName, 0.15)
    if err then
        if Debug then chat(spellName .. " - " .. err) end
        return false
    end 
    -- проверяем, что этот спел не используется сейчас
    local IsBusy = IsSpellInUse(spellName)
    if IsBusy then
        if dump then print("Уже прожали, SPELL_SENT пошел, не можем больше прожать", spellName) end
        return false 
    end
     -- проверяем, что не кастится другой спел
    for s,_ in pairs(InCast) do
        if not IsBusy and not tContains(inCastSpells, s) and IsSpellInUse(s) then
            if dump then print("Уже прожали " .. s .. ", ждем окончания, пока не можем больше прожать", spellName) end
            IsBusy = true
            break
        end
    end
    if IsBusy then return false end
    -- проверяем, что цель подходящая для этого спела
    if UnitExists(target) and badSpellTarget[spellName] then 
        local badTargetTime = badSpellTarget[spellName][UnitGUID(target)]
        if badTargetTime and (GetTime() - badTargetTime < 10) then 
            if dump then 
                print(target, "- Цель не подходящая, не можем прожать", spellName) 
            end
            return false 
        end
    end
    -- проверяем что цель в зоне досягаемости
    if not InRange(spellName, target) then 
        if dump then print(target," - Цель вне зоны досягаемости, не можем прожать", spellName) end
        return false
    end  
    -- Проверяем что все готово
    if IsReadySpell(spellName, true) then
        -- собираем команду
        local cast = "/cast "
        -- с учетом цели
        if target ~= nil then cast = cast .."[@".. target .."] "  end
        -- проверяем, хватает ли нам маны
        if cost and cost > 0 and UnitManaMax("player") > cost and UnitMana("player") <= cost then 
            if dump then print("Не достаточно маны, не можем прожать", spellName) end
            return false
        end
        if UnitExists(target) then 
            -- данные о кастах
            local castInfo = getCastInfo(spellName)
            castInfo.Target = target
            castInfo.TargetName = UnitName(target)
            castInfo.TargetGUID = UnitGUID(target)
        end
        -- пробуем скастовать
        if Debug then print("Жмем", cast .. "!" .. spellName) end
        RunMacroText(cast .. "!" .. spellName)
        -- если нужно выбрать область - кидаем на текущий mouseover
        TrySpellTargeting()
        -- данные о кастах
        local castInfo = getCastInfo(spellName)
        -- проверка на успешное начало кд
        if castInfo.StartTime and (GetTime() - castInfo.StartTime < 0.01) then
            if UnitExists(target) then
                -- проверяем цель на соответствие реальной
                if castInfo.TargetName and castInfo.TargetName ~= "" and castInfo.TargetName ~= UnitName(target) then 
                    if dump then print("Цели не совпали", spellName) end
                    RunMacroText("/stopcasting") 
                    --chat("bad target", target, spellName)
                    if nil == badSpellTarget[spellName] then
						badSpellTarget[spellName] = {}
                    end
                    local badTargets = badSpellTarget[spellName]
                    badTargets[UnitGUID(target)] = GetTime()
                    castInfo.Target = nil
                    castInfo.TargetName = nil
                    castInfo.TargetGUID = nil
                end
            end
        end
        if dump then print("Спел вроде прожался", spellName) end
        if Debug then
            print(spellName, cost, target)
        end
        return true
    end
    if dump then print("Не готово, не можем прожать", spellName) end
    return false
end
------------------------------------------------------------------------------------------------------------------
