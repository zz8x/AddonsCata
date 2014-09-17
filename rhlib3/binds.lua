﻿-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- l18n
BINDING_HEADER_RHLIB = "Rotation Helper Library"
BINDING_NAME_RHLIB_OFF = "Выкл ротацию"
BINDING_NAME_RHLIB_DEBUG = "Вкл/Выкл режим отладки"
BINDING_NAME_RHLIB_RELOAD = "Перезагрузить интерфейс"
BINDING_NAME_RHLIB_FOLLOW = "Вкл/Выкл режим следования"
------------------------------------------------------------------------------------------------------------------
-- Условие для включения ротации
function IsAttack()
    return (IsMouseButtonDown(4) == 1)
end

------------------------------------------------------------------------------------------------------------------
if Paused == nil then Paused = false end
-- Отключаем авторотацию, при повторном нажатии останавливаем каст (если есть)
function AutoRotationOff()
    if IsPlayerCasting() and Paused then 
        RunMacroText("/stopcasting") 
    end
    Paused = true
    RunMacroText("/stopattack")
    RunMacroText("/petfollow")
    echo("Авто ротация: OFF",true)
end

------------------------------------------------------------------------------------------------------------------
if Debug == nil then Debug = false end
-- Переключает режим отладки, а так же и показ ошибок lua
function DebugToggle()
    Debug = not Debug
    if Debug then
        SetCVar("scriptErrors", 1)
        echo("Режим отладки: ON",true)
    else
        SetCVar("scriptErrors", 0)
        echo("Режим отладки: OFF",true)
    end 
end


------------------------------------------------------------------------------------------------------------------

if FollowTarget == nil then FollowTarget = false end
-- Переключает режим следования
function FollowToggle()
    if FollowTarget then
       FollowTarget = false
       echo("Режим следования: OFF",true)
    else
        if CanHeal("target") then
            FollowTarget = UnitName("target")
            RunMacroText("/follow target")
            echo("Режим следования ("..FollowTarget.."): ON",true)
        end
    end
end

local followTime = 0
local followState = false
function IsFollow()
    return followState
end

function FollowBegin(event, unit)
    followState = true
end
AttachEvent("AUTOFOLLOW_BEGIN", FollowBegin)

function FollowEnd()
    followState = false
end
AttachEvent("AUTOFOLLOW_END", FollowEnd)

------------------------------------------------------------------------------------------------------------------
-- Вызывает функцию Idle если таковая имеется, с заданным рекомендованным интервалом UpdateInterval, 
-- при включенной Авто-ротации
local iTargets = {"target", "focus", "mouseover"}
TARGETS = iTargets
ITARGETS = iTargets
UNITS = {"player"}
IUNITS = UNITS -- Important Units
local StartTime = GetTime()
local function getUnitWeight(u)
    local w = 0
    if IsFriend(u) then w = 2 end
    if IsOneUnit(u, "player") then w = 3 end
    return w
end
local unitWeights = {}
local friendTargets = {}
local function compareUnits(u1,u2) return unitWeights[u1] < unitWeights[u2] end
local function getTargetWeight(t)
    local w = friendTargets[UnitGUID(t)] or 0
    if InMelee(t) then w = 3 end
    if IsOneUnit("focus", t) then w = 3.1 end
    if IsOneUnit("target", t) then w = 3.2 end
    if IsOneUnit("mouseover", t) then w = 3.3 end
    w = w + 3 * (1 - UnitHealth100(t) / 100) 
    return w
end
local targetWeights = {}
local function compareTargets(t1,t2) return targetWeights[t1] < targetWeights[t2] end

local function UpdateIdle()

    if (IsAttack() and Paused) then
        echo("Авто ротация: ON",true)
        Paused = false
    end

    if UpdateCommands() then return end
    
    if Paused then return end

    if GetTime() - StartTime < 2 then return end

    if IsBattleground() and UnitIsDead("player") and not UnitIsGhost("player") then
        --Notify("Выходим из тела!")
        RunMacroText("/run RepopMe()")
    end

    if UnitIsDeadOrGhost("player") or UnitIsCharmed("player") 
        or not UnitPlayerControlled("player") then return end
    if not FastUpdate then    
        -- Update units
        UNITS = GetUnits()
        wipe(unitWeights)
        wipe(friendTargets)
        for i=1,#UNITS do
            local u = UNITS[i]
            unitWeights[u] = getUnitWeight(u)

            local guid = UnitGUID(u .. "-target")
            if guid then
                local w = friendTargets[guid] or 1
                if w < 2 and IsFriend(u) then w = 2 end
                friendTargets[guid] = w
            end
        end
        sort(UNITS, compareUnits)
        
        -- Update targets
        TARGETS = GetTargets()
        wipe(targetWeights)
        for i=1,#TARGETS do
            local t = TARGETS[i]
            targetWeights[t] = getTargetWeight(t)
        end
        sort(TARGETS, compareTargets)
        wipe(IUNITS)
        for i = 0, #UNITS do
            local u = UNITS[i]
        	if IsArena() or IsFriend(u) then 
    			tinsert(IUNITS, u)
    		end
    	end
        ITARGETS = IsArena() and iTargets or TARGETS
    end

    if FollowTarget and GetTime() - followTime > 1 then
        followTime = GetTime()
        if IsFollow() then
            if not InCombatLockdown() and not IsMounted() then
                local s = GetUnitSpeed(FollowTarget)
                if s and (s / 7 * 100) > 190 then 
                    RunMacroText("/run MoveForwardStart()")-- сделать  функцию с таймаутом на вторую часть
                    RunMacroText("/run MoveForwardStop()")
                    DoCommand("mount")
                end
            end
            --[[if UnitAffectingCombat(FollowTarget) then --если скорость 0
                if IsMounted() and not IsFalling() then
                    RunMacroText("/dismount")
                end
                if not IsOneUnit("target",  FollowTarget .."-target") then
                    RunMacroText("/target " .. FollowTarget .. "-target")
                end
                if UnitAffectingCombat("target") then
                    RunMacroText("/startattack target")
                end
            end]]
        else
            if ( CheckInteractDistance(FollowTarget, 4) ) then
              if not IsPlayerCasting() then RunMacroText("/follow ".. FollowTarget) end
            end
            --if IsFriend(FollowTarget) then RunMacroText("/w "..FollowTarget .. " Вернись чуть назад плиз") end --тут пройти чуть вперед
            --если стоим то развернуться лицом к цели FollowTarget или хотябы как FollowTarget
        end
    end
    
    if Idle then Idle() end
end
AttachUpdate(UpdateIdle, -1000)

------------------------------------------------------------------------------------------------------------------
--Arena Raid Icons
local unitCD = {}
local raidIconsByClass = {WARRIOR=8,DEATHKNIGHT=7,PALADIN=3,PRIEST=5,SHAMAN=6,DRUID=2,ROGUE=1,MAGE=8,WARLOCK=3,HUNTER=4}
local function UpdateArenaRaidIcons(event, ...)
    if IsArena() then
        local members = GetGroupUnits()
        for i=1, #members do
            local u = members[i]
            if UnitExists(u) and not GetRaidTargetIndex(u) and (not unitCD[u] or GetTime() - unitCD[u] > 5) then 
                SetRaidTarget(u,raidIconsByClass[select(2,UnitClass(u))]) 
                unitCD[u] = GetTime()
            end
        end
	end
end
AttachEvent("GROUP_ROSTER_UPDATE", UpdateArenaRaidIcons)
AttachEvent("ARENA_OPPONENT_UPDATE", UpdateArenaRaidIcons)
AttachEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS", UpdateArenaRaidIcons)
------------------------------------------------------------------------------------------------------------------
-- Фиксим возможные подвисвния CombatLog
local CombatLogTimer = GetTime();
local CombatLogResetTimer = GetTime();

local function UpdateCombatLogFix()
    if InCombatLockdown() 
        and GetTime() - CombatLogTimer > 15
        and GetTime() - CombatLogResetTimer > 30 then 
        CombatLogClearEntries()
        --chat("Reset CombatLog!")
        CombatLogResetTimer = GetTime()
    end 
end
AttachUpdate(UpdateCombatLogFix)

local function UpdateCombatLogTimer(event, ...)
    CombatLogTimer = GetTime()
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', UpdateCombatLogTimer)

------------------------------------------------------------------------------------------------------------------
-- Мониторим, когда начался и когда закончился бой
local startCombatTime
local endCombatTime     
local function UpdateCombatTimers()
    if InCombatLockdown() then
        if not startCombatTime then 
            startCombatTime = GetTime()
        end
        endCombatTime = nil
    else
        if not endCombatTime then
            endCombatTime = GetTime()
        end
        startCombatTime = nil
        
    end
end
AttachUpdate(UpdateCombatTimers)   

function InCombat(t) 
    if not t then t = 0 end
    return InCombatLockdown() and startCombatTime and GetTime() - startCombatTime > t
end
function NotInCombat(t) 
    if not t then t = 0 end
    return not InCombatLockdown() and endCombatTime and GetTime() - endCombatTime > t
end
------------------------------------------------------------------------------------------------------------------
local FallingTime
function GetFalingTime()
    if IsFalling() and FallingTime then return GetTime() - FallingTime end
    return 0
end

local function UpdateFallingTime()
    if IsFalling() then
        if FallingTime == nil then FallingTime = GetTime() end
    else
        if FallingTime ~= nil then FallingTime = nil end
    end
end
--FALLING
AttachUpdate(UpdateFallingTime)

------------------------------------------------------------------------------------------------------------------
local function UpdateMacroAlertHider()
    if StaticPopup1Button2:IsVisible() == 1 and StaticPopup1Button2:IsEnabled() == 1 and StaticPopup1Button2:GetText() == "Пропустить" then
       chat(StaticPopup1.text:GetText())
       StaticPopup1Button2:Click()
    end
end
AttachUpdate(UpdateMacroAlertHider)
------------------------------------------------------------------------------------------------------------------
-- нас сапнул рога
function UpdateSapped(event, ...)
    local timestamp, type, hideCaster,                                                                      
      sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,   
      spellId, spellName, spellSchool,                                                                     
      amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = ...
	if spellName == "Ошеломление"
	and destGUID == UnitGUID("player")
	and type == "SPELL_AURA_APPLIED"
	then
		RunMacroText("/к Меня сапнули, помогите плиз!")
		Notify("Словил сап от роги: "..(sourceName or "(unknown)"))
	end
end
AttachEvent("COMBAT_LOG_EVENT_UNFILTERED", UpdateSapped)
------------------------------------------------------------------------------------------------------------------
-- Alert опасных спелов
local checkedTargets = {"target", "focus", "arena1", "arena2", "mouseover"}


function UpdateSpellAlert(event, ...)
    local timestamp, type, hideCaster,                                                                      
      sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,   
      spellId, spellName, spellSchool,                                                                     
      amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = ...
    if type and InAlertList(spellName) then
        type = type:gsub("SPELL_", "")
        type = type:gsub("AURA_", "")
        type = type:gsub("CAST_", "")
        if type == "APPLIED" or type == "FAILED" or type == "PERIODIC_ENERGIZE" then return end
        if UnitGUID("player") == sourceGUID and IsArena() then
            RunMacroText("/p " .. spellName .. (destName and (": ".. destName) or "") .." - " .. type .. "!")
        end
        for i=1,#checkedTargets do
            local t = checkedTargets[i]
            if IsValidTarget(t) and UnitGUID(t) == sourceGUID then
                Notify(spellName .. ": "..(sourceName or "unknown").." - " .. type .. "!")
                PlaySound("AlarmClockWarning2", "master");
                break
            end
        end
    end
end
AttachEvent("COMBAT_LOG_EVENT_UNFILTERED", UpdateSpellAlert)
------------------------------------------------------------------------------------------------------------------
-- Автоматическая продажа хлама и починка
local function SellGrayAndRepair()
    SellGray()
    DelGray()
    RepairAllItems(1) -- сперва пробуем за счет ги банка
    RepairAllItems()
end
AttachEvent('MERCHANT_SHOW', SellGrayAndRepair)
------------------------------------------------------------------------------------------------------------------
-- Автоматическoe удаление хлама
AttachEvent('MERCHANT_CLOSED', DelGray)
------------------------------------------------------------------------------------------------------------------
local inDuel = false
local startDuel = StartDuel
function StartDuel()
    inDuel = true
    startDuel()
end

function InDuel()
    return inDuel
end
local function DuelUpdate(event)
   inDuel = event == 'DUEL_REQUESTED' and true or false
end
AttachEvent('DUEL_REQUESTED', DuelUpdate)
AttachEvent('DUEL_FINISHED', DuelUpdate)
------------------------------------------------------------------------------------------------------------------
-- Запоминаем вредоносные спелы которые нужно кастить (нужно для сбивания кастов, например тотемом заземления)
if HarmfulCastingSpell == nil then HarmfulCastingSpell = {} end
function IsHarmfulCast(spellName)
    return HarmfulCastingSpell[spellName]
end

local function UpdateHarmfulSpell(event, ...)
    local timestamp, type, hideCaster,                                                                      
      sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,   
      spellId, spellName, spellSchool,                                                                     
      amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = ...
    if type:match("SPELL_DAMAGE") and spellName and amount > 0 then
        local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spellId) 
        if castTime and castTime > 0 then HarmfulCastingSpell[name] = true end
    end
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', UpdateHarmfulSpell)

------------------------------------------------------------------------------------------------------------------
local debugFrame
local debugFrameTime = 0
local function debugFrame_OnUpdate()
        if (debugFrameTime > 0 and debugFrameTime < GetTime() - 1) then
                local alpha = debugFrame:GetAlpha()
                if (alpha ~= 0) then debugFrame:SetAlpha(alpha - .005) end
                if (aplha == 0) then 
					debugFrame:Hide() 
					debugFrameTime = 0
				end
        end
end
-- Debug & Notification Frame
debugFrame = CreateFrame('Frame')
debugFrame:ClearAllPoints()
debugFrame:SetHeight(15)
debugFrame:SetWidth(800)
debugFrame:SetScript('OnUpdate', debugFrame_OnUpdate)
debugFrame:Hide()
debugFrame.text = debugFrame:CreateFontString(nil, 'BACKGROUND', 'GameFontNormalSmallLeft')
debugFrame.text:SetAllPoints()
debugFrame:SetPoint('TOPLEFT', 2, 0)
debugFrame:SetScale(0.8);

-- Debug messages.
function debug(message)
        debugFrame.text:SetText(message)
        debugFrame:SetAlpha(1)
        debugFrame:Show()
        debugFrameTime = GetTime()
end

local updateDebugStatsTime = 0
local function UpdateDebugStats()
	if not Debug or GetTime() - updateDebugStatsTime < 0.5 then return end
    updateDebugStatsTime = GetTime()
	UpdateAddOnMemoryUsage()
    UpdateAddOnCPUUsage()
    local mem  = GetAddOnMemoryUsage("rhlib3")
    local fps = GetFramerate();
    local speed = GetUnitSpeed("Player") / 7 * 100
    debug(format('MEM: %.1fKB, LAG: %ims, FPS: %i, SPD: %d%%', mem, LagTime * 1000, fps, speed))
end
AttachUpdate(UpdateDebugStats) 

if ShowTeammateDirection == nil then ShowTeammateDirection = false end
function ToggleTeammateDirection()
    ShowTeammateDirection = not ShowTeammateDirection
end
local modf = math.modf
local function ColorGradient(perc, ...)
    local num = select("#", ...)
    local hexes = type(select(1, ...)) == "string"

    if perc == 1 then
        return select(num-2, ...), select(num-1, ...), select(num, ...)
    end

    num = num / 3

    local segment, relperc = modf(perc*(num-1))
    local r1, g1, b1, r2, g2, b2
    r1, g1, b1 = select((segment*3)+1, ...), select((segment*3)+2, ...), select((segment*3)+3, ...)
    r2, g2, b2 = select((segment*3)+4, ...), select((segment*3)+5, ...), select((segment*3)+6, ...)

    if not r2 or not g2 or not b2 then
        return r1, g1, b1
    else
        return r1 + (r2-r1)*relperc,
        g1 + (g2-g1)*relperc,
        b1 + (b2-b1)*relperc
    end
end
local pi = math.pi
local twoPi = pi * 2
local abs = math.abs
local function updateFriendDistance()

    if not TomTom then return end

    local unit, dist
    if InGroup() then
        local members = GetGroupUnits()
        for i = 1, #members, 1 do
            local u = members[i]
            if IsFriend(u) and not IsOneUnit(u, "player") then
                dist = CheckDistance("player",u) 
                if nil ~= dist then 
                    unit = u  
                    break
                end
            end
        end
    end

    if (unit == nil or not ShowTeammateDirection) and TomTom:CrazyArrowIsHijacked() then
        TomTom:ReleaseCrazyArrow()
        return
    end

    if ShowTeammateDirection and unit and not TomTom:CrazyArrowIsHijacked() then
        TomTom:HijackCrazyArrow(function(self, elapsed)
            dist = CheckDistance("player",unit) 
            dist = (nil ~= dist) and round(dist) or "?"
            local tx, ty = GetPlayerMapPosition (unit)
            local px, py = GetPlayerMapPosition ("player")
            local player = GetPlayerFacing()
            local angle = rad(atan2 (tx - px, py - ty))
            angle = ((angle > 0) and (twoPi - angle) or -angle)  - player
            TomTom:SetCrazyArrowDirection(angle)
            TomTom:SetCrazyArrowColor(ColorGradient(abs((pi - abs(angle)) / pi), 1, 0.2, 0.2, 1, 1, 0.2, 0.2, 1, 0.2))
            TomTom:SetCrazyArrowTitle(UnitName(unit), dist .. 'm.')
        end)
    end
end
AttachUpdate(updateFriendDistance) 





