-- Rogue Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local casterClass = {
    "PRIEST",
    "SHAMAN",
    "MAGE",
    "WARLOCK"
}
 
local function TryOpener()
    if not IsValidTarget("target") then return false end
    
    DoSpell("Умысел")

    if UnitIsPlayer("target") and tContains(casterClass, GetClass("target")) and IsBehind() and not HasDebuff("Гаррота - немота") then
        return DoSpell("Гаррота")
    end

    if UnitIsPlayer("target") and CanControl("target") then
        return DoSpell("Подлый трюк")
    end 

    return DoSpell("Внезапный удар")
end

local function updatePoison(slot, poison)
    if GetInventoryItemID("player",slot) and not sContains(GetTemporaryEnchant(slot), poison) then
        RunMacroText("/use "..poison)
        RunMacroText("/use "..slot)
        RunMacroText("/click StaticPopup1Button1")
        return true
    end
    return false
end
------------------------------------------------------------------------------------------------------------------
local lastCP = 0;
local lastGUID
local peaceBuff = {"Пища", "Питье"}
function Idle()
    if AutoFreedom() then return end
    if IsAttack() then
        if CanExitVehicle() then VehicleExit() end
        if IsMounted() then Dismount() return end 
    end
    -- дайте поесть (побегать) спокойно 
    if not IsAttack() and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end
    -- чтоб контроли не сбивать
    if HasDebuff(SappedList, 0.01, "target") and not IsAttack() then 
        RunMacroText("/stopattack") 
        return
    end
    if IsAttack() or InCombatLockdown() then
        TryTarget()
    end
        
    if (IsAttack() or UnitHealth100() > 60) and HasBuff("Длань защиты") then RunMacroText("/cancelaura Длань защиты") end

    if IsAttack() then
        if HasBuff("Парашют") then RunMacroText("/cancelaura Парашют") return end
        if CanExitVehicle() then VehicleExit() return end
        if IsMounted() then Dismount() return end 
    else
        if IsMounted() or CanExitVehicle() or HasBuff(peaceBuff) or IsPlayerCasting() then return end
    end
    if IsAlt() and IsValidTarget("mouseover") and CanControl("mouseover") and DoSpell(UnitAffectingCombat("mouseover") and "Ослепление" or "Ошеломление", "mouseover") then return end
    if (IsValidTarget("target") or IsAttack()) and not IsStealthed() and not InCombatLockdown() and DoSpell("Незаметность") then return end

    local hp = UnitHealth100("player")
    if not IsArena() and hp < 40 and (UseItem("Зелье разбойника") or UseHealPotion()) then return end
    if InCombatLockdown() and (IsOneUnit("player", "target-target") or IsOneUnit("player", "focus-target")) then
        if hp < 50 and DoSpell("Ускользание") then return end
        if hp < 60 and InMelee() and DoSpell("Дымовая шашка") then return end
        if hp < 70 and DoSpell("Ложный выпад") then return end
        if hp < 75 and InMelee() and DoSpell("Боевая готовность") then return end
    end

    if not InCombatLockdown() and IsCtr() then
        if updatePoison(16, IsValidTarget("target") and UnitIsPlayer("target") and tContains(casterClass, GetClass("target")) and "Дурманящий яд" or "Смертельный яд") then return end
        if updatePoison(17, "Нейтрализующий яд") then return end
        if updatePoison(18, "Калечащий яд") then return end
    end

    if not (IsValidTarget("target") and CanAttack("target") and (UnitAffectingCombat("target")  or IsAttack()))  then return end

    if CanInterrupt then
        for i=1,#TARGETS do
            TryInterrupt(TARGETS[i])
        end
    end

    if not InMelee() and not InCombatLockdown() then
        if DoSpell("Заживление ран") then return end
    end

    if IsStealthed() and IsAttack() then 
        if TryOpener() then return end
    end
    
    --if IsAttack() and not InMelee() and DoSpell("Шаг сквозь тень") then return end

    --if IsAttack() and DoSpell(InRange("Ошеломление") and IsReadySpell("Ошеломление") and "Ошеломление" or "Шаг сквозь тень") then return end
    
    if IsStealthed() then 
        RunMacroText("/stopattack")
        return 
    end

    if IsAttack() or InMelee() then RunMacroText("/startattack [nostealth]") end
    local CP = GetComboPoints("player", "target")

    local targetGUID = UnitGUID("target")
    if lastGUID ~= targetGUID then
        if CP == 0 and lastCP > 2  then DoSpell("Смена приоритетов") end
        lastGUID = targetGUID
    end
    lastCP = CP
    
    if (CP == 2) and not HasBuff("Заживление ран", 1) then DoSpell("Заживление ран") return end   
    if (CP == 5) then
        if IsPvP() and CanControl("target") and DoSpell("Удар по почкам")  then return end
        if UnitHealth100("player") < (HasBuff("Заживление ран", 5) and 60 or 75) and DoSpell("Заживление ран") then return end
        --if not UnitIsPlayer("target") and UnitHealthMax("target") > 300000 and UnitHealth100("target") > 40 and not HasBuff("Мясорубка", 1) and DoSpell("Мясорубка") then return end
        --if UnitHealth100("target") > 50 and not HasDebuff("Рваная рана") and DoSpell("Рваная рана") then return end
        --if GetDebuffStack("Смертельный яд") == 5 and DoSpell("Отравление") then return end
        if DoSpell("Потрошение") then return end
        if not InGCD() and UnitMana("player") < 35 then return end
        return
    end
    
    if IsShift() and (IsAttack() or not IsStealthed()) and DoSpell("аое") then return end

    if IsCtr() then
        if UnitIsPlayer("target") then DoSpell("Долой оружие", "target") end
        if not HasBuff("Танец теней") and UnitMana("player") < 60 then return end
        DoSpell("Танец теней")
    end

    if HasBuff("Танец теней") then
        if TryOpener() then return end
    else
        if not HasDebuff("Кровоизлияние", 1) and DoSpell("Кровоизлияние") then return end
        --if not IsBehind() and IsSpellNotUsed("Отравляющий укол", 5) and DoSpell("Отравляющий укол") then return end
        if not IsBehind() and UnitIsPlayer("target") and CanControl("target") and DoSpell("Парализующий удар") then return end
        if DoSpell(IsBehind() and HasBuff("Заживление ран") and "Удар в спину" or "Кровоизлияние") then return end
    end

    if IsAttack() and InCombatLockdown() and not IsStealthed()  then
        if CP > 0 and DoSpell("Смертельный бросок") then return end
        if PlayerInPlace() and DoSpell("Бросок") then return end
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
                RunMacroText("/target [@" .. target .. "]") 
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
