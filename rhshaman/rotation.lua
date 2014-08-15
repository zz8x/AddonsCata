-- Shaman Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье", "Призрачный волк"}
function Idle()
    if IsAttack() then
        if HasBuff("Призрачный волк") then RunMacroText("/cancelaura Призрачный волк") return end
        if CanExitVehicle() then VehicleExit() end
        if IsMounted() then Dismount() return end 
    end
    -- дайте поесть (побегать) спокойно 
    if not IsAttack() and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end
   
	if IsAttack() or InCombatLockdown() then
        TryTarget()        
        Rotation()
        return
    end
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
        if IsMouse3() and IsValidTarget("mouseover") and IsOneUnit("target", "mouseover") then 
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

function Rotation()
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

    if GetInventoryItemID("player",16) and not sContains(GetTemporaryEnchant(16), "Язык пламени") and DoSpell("Оружие языка пламени") then return end
    if not HasBuff("Щит молний") and DoSpell("Щит молний") then return end
    if InCombatLockdown() and HasBuff("Покорение стихий") and UseEquippedItem("Чаша Лунного колодца") then return end
    if not HasMyDebuff("Огненный шок", 1,"target") and  DoSpell("Огненный шок") then return end
    if HasMyDebuff("Огненный шок", 1.5,"target") and  DoSpell("Выброс лавы") then return end
    if HasTotem(1) ~= "Тотем элементаля огня" then
        if HasTotem(1) ~= "Опаляющий тотем" and DoSpell("Опаляющий тотем") then return end
    end
    if InCombatLockdown() and DoSpell("Покорение стихий") then return end
    if IsShift() and DoSpell("Цепная молния") then return end
    if HasMyDebuff("Огненный шок", 5,"target") and GetBuffStack("Щит молний") > 6 and DoSpell("Земной шок") then return end
    if GetBuffStack("Щит молний") > 8 and DoSpell("Земной шок") then return end
    if (IsLeftAltKeyDown() == 1) and HasTotem(1) ~= "Тотем элементаля огня" and DoSpell("Тотем элементаля огня") then return end
    if (IsRightAltKeyDown() == 1) and DoSpell("Зов Стихий") then return end
    if DoSpell("Молния") then return end
end
