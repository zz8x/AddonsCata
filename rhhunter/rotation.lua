-- Hunter Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье", "Походный облик", "Облик стремительной птицы", "Водный облик"}
local fixRageTime = 0
local steathClass = {"ROGUE", "DRUID"}
function Idle()
    if IsAttack() then
        if CanExitVehicle() then VehicleExit() end
        if IsMounted() then Dismount() return end 
    end
    -- дайте поесть (побегать) спокойно 
    if not IsAttack() and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end
    
	if not (IsAttack() or InCombatLockdown()) then return end
	TryTarget()
    TryBuffs()

    local myHP = UnitHealth100("player")

    if HasSpell("Черная стрела") then 
        if IsCtr() and DoSpell("Быстрая стрельба") then return end
        if IsCtr() and DoSpell("Зов дикой природы") then return end
        if IsCtr() and UseEquippedItem("Древнее окаменевшее семечко") then return end
        if IsCtr() and UseEquippedItem("Магнитный огненный шар Рикет") then return end
        if IsAlt() and DoSpell("Метание ловушки") then return end
        if IsAlt() and HasBuff("Метание ловушки") and DoSpell("Ледяная ловушка") then return end

        if not HasDebuff("Метка охотника") and DoSpell("Метка охотника") then return end
        if InCombatLockdown() and UseEquippedItem("Древнее окаменевшее семечко") then return end
        if not HasMyDebuff("Укус змеи") and DoSpell("Укус змеи") then return end 
        if DoSpell("Убийственный выстрел") then return end
        if not HasMyDebuff("Разрывной выстрел") and DoSpell("Разрывной выстрел") then return end
        if DoSpell("Черная стрела") then return end
        if UnitMana100("player") > 65 and DoSpell("Чародейский выстрел") then return end
        if DoSpell("Выстрел кобры") then return end
        return
    end

    if HasSpell("Выстрел химеры") then 
        if IsCtr() and DoSpell("Быстрая стрельба") then return end
        if IsCtr() and DoSpell("Зов дикой природы") then return end
        if IsCtr() and UseEquippedItem("Магнитный огненный шар Рикет") then return end
        if IsAlt() and DoSpell("Метание ловушки") then return end
        if IsAlt() and HasBuff("Метание ловушки") and DoSpell("Ледяная ловушка") then return end

        if not HasDebuff("Метка охотника") and DoSpell("Метка охотника") then return end
        if UseEquippedItem("Древнее окаменевшее семечко") then return end
        if not HasMyDebuff("Укус змеи") and DoSpell("Укус змеи") then return end
        if HasMyBuff("Огонь!") and DoSpell("Прицельный выстрел") then return end 
        if DoSpell("Убийственный выстрел") then return end
        if DoSpell("Быстрая стрельба") then return end
        if not HasMyBuff("Улучшенный верный выстрел") and DoSpell("Верный выстрел") then return end
        if DoSpell("Выстрел химеры") then return end
        if UnitMana100("player") > 65 and DoSpell("Чародейский выстрел") then return end
        if DoSpell("Верный выстрел") then return end
        return
    end

   --[[ if CanInterrupt then
        for i=1,#TARGETS do
            TryInterrupt(TARGETS[i])
        end
    end]]

end
function ActualDistance(target)
    if target == nil then target = "target" end
    return (CheckInteractDistance(target, 3) == 1) and not InRange("Укус змеи", target)
end

function TryTarget()
    -- помощь в группе
    if not IsValidTarget("target") and InGroup() then
        -- если что-то не то есть в цели
        if UnitExists("target") then RunMacroText("/cleartarget") end
        for i = 1, #TARGET do
            local t = TARGET[i]
            if t and (UnitAffectingCombat(t) or IsPvP()) and ActualDistance(t) and (not IsPvP() or UnitIsPlayer(t)) and not IsStealthed() then 
                RunMacroText("/target [@" .. target .. "]") 
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
    if IsArena() then
        if IsValidTarget("target") and (not UnitExists("focus") or IsOneUnit("target", "focus")) then
            if IsOneUnit("target","arena1") then RunMacroText("/focus arena2") end
            if IsOneUnit("target","arena2") then RunMacroText("/focus arena1") end
        end
    end
end

function TryBuffs()
 
    return false
end