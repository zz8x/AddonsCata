﻿-- Priest Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
function Idle()
    
    if CanInterrupt then
        for i=1,#TARGETS do
            TryInterrupt(TARGETS[i])
        end
    end

    if IsAttack() then 
        if CanExitVehicle() then VehicleExit() return end
        if IsMounted() then Dismount() return end 
    else
        if not InCombatLockdown() or IsMounted() or CanExitVehicle() or HasBuff(peaceBuff) then return end
    end
    
    if TryBuffs() then return end
    TryTarget()

end

------------------------------------------------------------------------------------------------------------------
function TryBuffs()
    if not HasBuff("Внутренний огонь") and DoSpell("Внутренний огонь") then return true end
end

------------------------------------------------------------------------------------------------------------------
function ActualDistance(target)
    if target == nil then target = "target" end
    return (CheckInteractDistance(target, 4) == 1)
end
------------------------------------------------------------------------------------------------------------------
function TryTarget(useFocus)
    -- помощь в группе
    if not IsValidTarget("target") and InGroup() then
        -- если что-то не то есть в цели
        if UnitExists("target") then RunMacroText("/cleartarget") end
        for i = 1, #TARGET do
            local t = TARGET[i]
            if t and (UnitAffectingCombat(t) or IsPvP()) and ActualDistance(t) and (not IsPvP() or UnitIsPlayer(t))  then 
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
            or (not IsArena() and not ActualDistance("target"))  -- далековато
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
                if UnitAffectingCombat(t) and ActualDistance(t) and not IsOneUnit("target", t) and (not IsPvP() or UnitIsPlayer(t)) then 
                    RunMacroText("/focus " .. t) 
                    break
                end
            end
        end
        
        if not IsValidTarget("focus") or IsOneUnit("target", "focus") or (not IsArena() and not ActualDistance("focus")) then
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
------------------------------------------------------------------------------------------------------------------