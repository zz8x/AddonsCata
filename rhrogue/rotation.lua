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
    if not CanControl("target") then RunMacroText("/stopattack") end
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
                RunMacroText("/startattack [@" .. target .. "]") 
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

    if CanInterrupt then
        for i=1,#TARGETS do
            TryInterrupt(TARGETS[i])
        end
    end

    
    if not (IsValidTarget("target") and (UnitAffectingCombat("target") or IsAttack()))  then return end
    
    --if IsAttack() and HasSpell("Звериная атака - кошка") and (IsStealthed() or not IsReadySpell("Крадущийся зверь")) and DoSpell("Звериная атака - кошка") then return end
    
    if IsStealthed() then 
        
        --[[if IsNotBehindTarget() then
            if DoSpell("Наскок") then return end
        else
            if DoSpell("Накинуться") then return end
        end]]
        return 
    end
   
    
    
    --if InCombatLockdown() and IsAttack() and IsValidTarget("target") and InRange("Звериная атака - кошка", "target") and DoSpell("Звериная атака - кошка") then return end
            
    RunMacroText("/startattack")
    
    --[[if InGroup() then
        if TryEach(TARGETS, function(t) 
            if tContains({"worldboss", "rareelite", "elite"}, UnitClassification(t)) then 
            local isTanking, state, scaledPercent, rawPercent, threatValue = UnitDetailedThreatSituation("player", t)
                if not isTanking and state == 1 and DoSpell("Попятиться", t) then
                     print("Попятиться!!")
                    return true
                end
            end
        end) then return end
    end]]
    --[[if IsAOE() then
        if UnitMana("player") < 35 and UnitMana("player") > 25 and not HasBuff("Берсерк") and DoSpell("Тигриное неистовство") then return end
        DoSpell("Размах (кошка)")
        return
    end]]
   
    local CP = GetComboPoints("player", "target")
        
    if (CP == 5) then
        if UnitHealth100("player") < 60 and DoSpell("Заживление ран") then return end
        --if not HasBuff("Мясорубка", 1) and DoSpell("Мясорубка") then return end
        if DoSpell("Потрошение") then return end
        --if InGCD() or UnitMana("player") < 35 then return end
        return
    end
    if not IsBehind() and DoSpell("Парализующий удар") then return end
    if DoSpell(IsBehind() and "Удар в спину" or "Коварный удар" ) then return end
    if PlayerInPlace() and DoSpell("Бросок") then return end
end