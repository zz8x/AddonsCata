-- Rogue Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}
function Idle()
    if IsAttack() then
        if CanExitVehicle() then VehicleExit() end
        if IsMounted() then Dismount() return end 
    end
    -- дайте поесть (побегать) спокойно 
    if not IsAttack() and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end
    -- чтоб контроли не сбивать
    if HasDebuff(ControlList, 0.01, "target") then 
        RunMacroText("/stopattack") 
        if not IsAttack() then return end
    end
	if IsAttack() or InCombatLockdown() then
        TryTarget()
        Rotation()
        return
    end
end
------------------------------------------------------------------------------------------------------------------
function ActualDistance(target)
    if target == nil then target = "target" end
    return (CheckInteractDistance(target, 3) == 1)
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
                RunMacroText("/startattack [@" .. target .. "][nostealth]") 
                break
            end
        end
    end
    -- пытаемся выбрать ну хоть что нибудь
    if not IsValidTarget("target") then
        -- если что-то не то есть в цели
        if UnitExists("target") then RunMacroText("/cleartarget") end

        if IsPvP() then
            RunMacroText("/targetenemyplayer [nodead]")
        else
            RunMacroText("/targetenemy [nodead]")
        end
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
        if not IsValidTarget("focus") then
            if UnitExists("focus") then RunMacroText("/clearfocus") end
            for i = 1, #TARGETS do
                local t = TARGETS[i]
                if UnitAffectingCombat(t) and ActualDistance(t) and not IsOneUnit("target", t) then 
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

function Rotation()
    if (IsAttack() or UnitHealth100() > 60) and HasBuff("Длань защиты") then RunMacroText("/cancelaura Длань защиты") end

    if IsAttack() then
        
        if HasBuff("Парашют") then RunMacroText("/cancelaura Парашют") return end
        if CanExitVehicle() then VehicleExit() return end
        if IsMounted() then Dismount() return end 

    else
        if IsMounted() or CanExitVehicle() or HasBuff(peaceBuff) or not InCombatLockdown() or IsPlayerCasting() then return end
    end

    local hp = UnitHealth100("player")
    if not IsArena() and hp < 40 and UseItem("Зелье разбойника") then return end
    if InCombatLockdown() and (IsOneUnit("player", "target-target") or IsOneUnit("player", "focus-target")) then
        if hp < 50 and DoSpell("Ускользание") then return end
        if hp < 60 and InMelee() and DoSpell("Дымовая шашка") then return end
        if hp < 70 and InMelee() and DoSpell("Ложный выпад") then return end
        if hp < 75 and InMelee() and DoSpell("Боевая готовность") then return end
    end

    if CanInterrupt then
        for i=1,#TARGETS do
            TryInterrupt(TARGETS[i])
        end
    end

    if IsAttack() and not IsStealthed() and not InCombatLockdown() and DoSpell("Незаметность") then return end
    
    if not InMelee() and not InCombatLockdown() then
        if DoSpell("Заживление ран") then return end
    end



    if IsStealthed() and IsAttack()  then 
        if IsValidTarget("target") then DoSpell("Умысел") end
        if DoSpell("Внезапный удар") then return end
       --if IsAttack() and DoSpell("Гаррота") then return end
    end
    
    --if IsAttack() and not InMelee() and DoSpell("Шаг сквозь тень") then return end

    --if IsAttack() and DoSpell(InRange("Ошеломление") and IsReadySpell("Ошеломление") and "Ошеломление" or "Шаг сквозь тень") then return end
    
    if IsStealthed()  then 
        RunMacroText("/stopattack")
        return 
    end

    --RunMacroText("/startattack [nostealth]")
    
    local CP = GetComboPoints("player", "target")
    if CP == 0 and DoSpell("Смена приоритетов") then return end
    if (CP == 2) and not HasBuff("Заживление ран", 1) then DoSpell("Заживление ран") return end   
    if (CP == 5) then
        if IsPvP() and CanControl("target") and DoSpell("Удар по почкам")  then return end
        if UnitHealth100("player") < 60 and DoSpell("Заживление ран") then return end
        --if not HasBuff("Мясорубка", 1) and DoSpell("Мясорубка") then return end
        if GetDebuffStack("Смертельный яд") == 5 and DoSpell("Отравление") then return end
        if DoSpell("Потрошение") then return end
        --if InGCD() or UnitMana("player") < 35 then return end
        return
    end
    if IsCtr() then
        DoSpell("Танец теней")
    end
    if HasBuff("Танец теней") then
        DoSpell("Умысел")
        if IsPvP() and CanControl() and DoSpell("Подлый трюк") then return end
        if DoSpell("Внезапный удар") then return end
    else
        if not HasDebuff("Кровоизлияние", 1) and DoSpell("Кровоизлияние") then return end
        if IsBehind() and HasBuff("Заживление ран") then
            if DoSpell("Удар в спину") then return end
        else
            if IsPvP() and CanControl("target") and DoSpell("Парализующий удар")  then return end
            if DoSpell("Кровоизлияние") then return end
        end
    end


   
    if IsAttack() and IsStealthed() and PlayerInPlace() then
        if CP > 2 and DoSpell("Смертельный бросок") then return end
        if DoSpell("Бросок") then return end
    end
end