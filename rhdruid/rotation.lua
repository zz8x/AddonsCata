-- Druid Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
--[[
#showtooltip Берсерк
/run UseBers()
]]


local bersTimer = 0
function UseBers()
    bersTimer = GetTime()
end

function IsBers()
    return (GetTime() - bersTimer < 5)
end


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

  
    if IsCtr() and HasBuff("Быстрота хищника") then
        --if not HasBuff("Облик медведя") and CanHeal("Танак") and UnitHealth100("Танак") < 40 then DoSpell("Целительное прикосновение", "Танак") return end
        if not HasBuff("Облик медведя") and myHP < 80 then DoSpell("Целительное прикосновение", "player") return end
    end

    --if IsBattleground() and UnitMana100() < 30 or UnitHealth100("player") < 35 and UseItem("Глоток войны", 5) then return true end
    if IsCtr() and GetBuffStack("Жизнецвет", "player") < 3 and DoSpell("Жизнецвет", "player") then return end
    if IsCtr() and GetBuffStack("Жизнецвет", "player") == 3 and  not HasBuff("Омоложение") and DoSpell("Омоложение", "player") then return end
    --[[if not HasBuff("Облик медведя") and GetTime() - fixRageTime > 5 then
        if InRage("target") and DoSpell("Умиротворение", "target") then return end
        if InRage("focus") and DoSpell("Умиротворение", "focus") then return end
        fixRageTime = GetTime()
    end]]

    if not IsStealthed() and CanInterrupt then
        for i=1,#TARGETS do
            TryInterrupt(TARGETS[i])
        end
    end

    if IsBers() then
        if DoSpell("Берсерк") then return end
        if HasBuff("Берсерк") and UseEquippedItem("Жетон завоевания гладиатора Катаклизма") then return end
    end

    if HasBuff("Облик медведя") and IsValidTarget("target") then
        if UnitMana("player") < 80 and DoSpell("Исступление") then return end
        if IsNotAttack("target") then return end
        if HasSpell("Звериный рывок(Облик медведя)") and IsAttack() and InRange("Звериный рывок(Облик медведя)", "target") then 
            DoSpell("Звериный рывок(Облик медведя)")
            return
        end

        if DoSpell("Оглушить") then return end
        if IsReadySpell("Оглушить") then return end
        --RunMacroText("/startattack")
            if myHP < 25 and DoSpell("Неистовое восстановление") then return end
            if myHP < 60 and DoSpell("Дубовая кожа") then return end
            if DoSpell("Увечье(Облик медведя)") then return end
            if IsShiftKeyDown() == 1 and DoSpell("Размах(Облик медведя)") then return end
            if DoSpell("Взбучка") then return end
            if DoSpell("Растерзать") then return end
    end
  
    if HasBuff("Облик кошки") then
        if InCombatLockdown() and not HasBuff("Крадущийся зверь") and HasSpell("Звериный рывок(Облик медведя)") and IsAttack() and IsValidTarget("target") and InRange("Звериный рывок(Облик медведя)", "target") and GetSpellCooldownLeft("Звериный рывок(Облик кошки)") > 2 and GetSpellCooldownLeft("Звериный рывок(Облик медведя)") == 0 then
            UseMount("Облик медведя")
            return
        end
    
        if IsAttack() --[[and InRange("Волшебный огонь (облик зверя)", "target") and IsValidTarget("target")]] and not InCombatLockdown() and HasBuff("Облик кошки") and IsReadySpell("Крадущийся зверь") then 
            DoSpell("Крадущийся зверь")
            return 
        end
        
        if IsNotAttack("target") then return end

        if IsAttack() and HasSpell("Звериный рывок(Облик кошки)") and (IsStealthed() or not IsReadySpell("Крадущийся зверь")) and DoSpell("Звериный рывок(Облик кошки)") and RunMacroText("/stopattack") then return end
        
        if IsStealthed() then 
                if DoSpell("Наскок") then return end
            if IsBehind() then
                if DoSpell("Накинуться") then return end
            end
            return 
        end
       
        if not FastUpdate and IsPvP() and IsReadySpell("Волшебный огонь (облик зверя)") then
            --не дать уйти в инвиз или сбить рефлект
            for i = 1, #ITARGETS do
                local t = ITARGETS[i]
                if UnitIsPlayer(t) and CanAttack(t) and (tContains(steathClass, GetClass(t)) or HasBuff(reflectBuff, 1, t)) and not HasDebuff("Волшебный огонь", 1, t) and DoSpell("Волшебный огонь (облик зверя)", t) then return end
            end
        end
        
        if InCombatLockdown() and IsAttack() and IsValidTarget("target") and InRange("Звериный рывок(Облик кошки)", "target") and DoSpell("Звериный рывок(Облик кошки)") then return end
                
--~      Ротация для кошки 
        if IsShift() and HasBuff("Облик кошки") and DoSpell("Размах(Облик кошки)") then return end
              

        if InMelee("target") and HasBuff("Неистовство дикой природы") and UseEquippedItem("Перчатки из драконьей шкуры гладиатора Катаклизма") then return end

        if myHP < 50 and DoSpell("Инстинкты выживания") then return end
        if myHP < 80 and DoSpell("Дубовая кожа") then return end
       
        if HasDebuff("Глубокая рана") and HasDebuff("Разорвать",7) and not IsStealthed() and not HasDebuff("Волшебный огонь", 2) and DoSpell("Волшебный огонь (облик зверя)") then return end
        
        if HasSpell("Увечье(Облик кошки)") and not HasDebuff("Увечье") then
                DoSpell("Увечье(Облик кошки)") 
            return
        end

        local CP = GetComboPoints("player", "target")

        if (CP == 5) then
            if UnitMana("player") < 40 and DoSpell("Тигриное неистовство") then return end
            if HasDebuff("Разорвать", 5) and DoSpell("Свирепый укус") then return end
            if not HasDebuff("Разорвать", 1) and DoSpell("Разорвать") then return end
            if InGCD() or UnitMana("player") < 25 then return end
        end

        if UnitMana("player") < 40 and DoSpell("Тигриное неистовство") then return end

        if HasBuff("Обращение в бегство") and RunMacroText("/cast Накинуться!") then return end

        if not HasDebuff("Глубокая рана") then 
            DoSpell("Глубокая рана") 
            return 
        end


        if not IsPvP() and HasBuff("Ясность мысли") and HasBuff("Разорвать") then
            if not IsBehind() then
                if HasSpell("Увечье(Облик кошки)") then
                    if DoSpell("Увечье(Облик кошки)") then return end
                else
                    if DoSpell("Цапнуть") then return end
                end
            else
                if DoSpell("Полоснуть")  then return end
            end
        end
          
      
        if not IsBehind() then
            if HasSpell("Увечье(Облик кошки)") then
                if DoSpell("Увечье(Облик кошки)") then return end
            else
                if DoSpell("Цапнуть") then return end
            end
        else
            if DoSpell("Полоснуть")  then return end
        end
        
    else
        if HasBuff("Облик медведя") and InCombatLockdown() then return end
        if not IsCtr() and not HasBuff("Неистовое восстановление") and ((HasBuff("дикой природы") or HasBuff("королей")) or InCombatLockdown()) and UseMount("Облик кошки") then return end
    end
end

function ActualDistance(target)
    if target == nil then target = "target" end
    return (CheckInteractDistance(target, 3) == 1) and not InRange("Звериный рывок(Облик кошки)", target)
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
    if HasBuff("Крадущийся зверь") or InCombatLockdown() or (IsFalling() or IsSwimming()) or not IsAttack() then return false end
    if HasBuff("дикой природы", 15 * 60) or HasBuff("королей") then return false end
    if GetShapeshiftForm() ~= 0 then RunMacroText("/cancelform") return true end
    if DoSpell("Знак дикой природы", "player") then return true end
    return false
end