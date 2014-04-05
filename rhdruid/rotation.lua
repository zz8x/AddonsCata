-- Druid Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье", "Походный облик", "Облик стремительной птицы", "Водный облик"}
function Idle()
    if IsAttack() then
        if CanExitVehicle() then VehicleExit() end
        if IsMounted() then Dismount() return end 
    end
    -- дайте поесть (побегать) спокойно 
    if not IsAttack() and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end
    -- чтоб контроли не сбивать
    if not CanControl("target") then RunMacroText("/stopattack") end
    
	if not (IsAttack() or InCombatLockdown()) then return end
	TryTarget()
    

    local myHP = CalculateHP("player")
    
 
   
    if HasBuff("Быстрота хищника") then
        if IsControlKeyDown() and HasDebuff("Смерч",1,"target") then DoSpell("Смерч") return end
        if myHP < 60 then DoSpell("Целительное прикосновение", "player") return end
    end
    
    
    if HasBuff("Облик медведя") and IsValidTarget("target")  then
        if UnitMana("target") < 50 and DoSpell("Исступление") then return end
    
        if HasSpell("Звериный рывок(Облик медведя)")and InRange("Звериный рывок(Облик медведя)", "target")  and (UnitMana("target") >= 5 or IsReadySpell("Исступление")) then 
            DoSpell("Звериный рывок(Облик медведя)")
            return
        end
    
        -- if DoSpell("Оглушить") then return end
        -- if not HasDebuff("Устрашающий рев",3) and DoSpell("Устрашающий рев") then return end
    end
    if HasBuff("Облик кошки") then
        if not HasBuff("Крадущийся зверь") and HasSpell("Звериный рывок(Облик медведя)") and IsAttack() and IsValidTarget("target") and InRange("Звериный рывок(Облик медведя)", "target") and GetSpellCooldownLeft("Звериный рывок(облик кошки)") > 2 and GetSpellCooldownLeft("Звериный рывок(Облик медведя)") == 0 then
            UseMount("Облик медведя")
            return
        end
    
        if IsAttack() and InRange("Волшебный огонь (облик зверя)", "target") and IsValidTarget("target") and not InCombatLockdown() and HasBuff("Облик кошки") and IsReadySpell("Крадущийся зверь") then 
            DoSpell("Крадущийся зверь")
            return 
        end
        
    
        if not (IsValidTarget("target") and (UnitAffectingCombat("target") or IsAttack()))  then return end
        
        if IsAttack() and HasSpell("Звериный рывок(облик кошки)") and (IsStealthed() or not IsReadySpell("Крадущийся зверь")) and DoSpell("Звериный рывок(облик кошки)") then return end
        
        if IsStealthed() then 
            
            if not IsBehind() then
                if DoSpell("Наскок") then return end
            else
                if DoSpell("Накинуться") then return end
            end
            return 
        end
       
        
        
        if InCombatLockdown() and IsAttack() and IsValidTarget("target") and InRange("Звериный рывок(облик кошки)", "target") and DoSpell("Звериный рывок(облик кошки)") then return end
                
        RunMacroText("/startattack")


--~      Ротация для кошки 
        if IsAOE() then
            if UnitMana("player") < 35 and UnitMana("player") > 25 and not HasBuff("Берсерк") and DoSpell("Тигриное неистовство") then return end
            DoSpell("Размах (кошка)")
            return
        end
        
        
        if UnitMana("player") < 30 and DoSpell("Тигриное неистовство") then return end
        
        if HasDebuff("Глубокая рана") and HasDebuff("Разорвать",7) and InMelee() then
            if UnitMana("player") > 25 and UnitMana("player") < 85 and HasSpell("Берсерк") and DoSpell("Берсерк") then return end
        end
        
        if HasBuff("Ясность мысли") then
            if not IsBehind() then
                if HasSpell("Увечье (облик кошки)") then
                    if DoSpell("Увечье (облик кошки)") then return end
                else
                    if DoSpell("Цапнуть") then return end
                end
            else
                if DoSpell("Полоснуть")  then return end
            end
        end
        
        
        --if not HasDebuff("Волшебный огонь (облик зверя)", 2) and DoSpell("Волшебный огонь (облик зверя)") then return end
        
        if HasSpell("Увечье (облик кошки)") and not (HasDebuff("Увечье (облик медведя)") or HasDebuff("Увечье (облик кошки)"))then
                DoSpell("Увечье (облик кошки)") 
            return
        end
        if not HasDebuff("Глубокая рана") then 
            DoSpell("Глубокая рана") 
            return 
        end
        
        local CP = GetComboPoints("player", "target")

        --if (CP > 3) and not HasBuff("Дикий рев", 3) and DoSpell("Дикий рев") then return end
        --if (CP > 0) and not HasBuff("Дикий рев") then 
            --DoSpell("Дикий рев")
            --return 
        --end
        if (CP == 5) then
            if UnitMana("player") < 40 and HasSpell("Берсерк") and HasDebuff("Разорвать", 5) and DoSpell("Свирепый укус") then return end
            if not HasDebuff("Разорвать", 0.8) and DoSpell("Разорвать") then return end
            if UnitMana("player") < 40 and HasDebuff("Разорвать", 6) and DoSpell("Свирепый укус") then return end
            if InGCD() or UnitMana("player") < 40 then return end
        end
      
      
        if not IsBehind() then
            if HasSpell("Увечье (облик кошки)") then
                if DoSpell("Увечье (облик кошки)") then return end
            else
                if DoSpell("Цапнуть") then return end
            end
        else
            if DoSpell("Полоснуть")  then return end
        end
        
        --if not HasDebuff("Волшебный огонь (облик зверя)", 7) and DoSpell("Волшебный огонь (облик зверя)") then return end
        
    else
        if HasBuff("дикой природы") and UseMount("Облик кошки") then return end
    end
end


function TryTarget()
    -- помощь в группе
    if not IsValidTarget("target") and InGroup() then
        -- если что-то не то есть в цели
        if UnitExists("target") then RunMacroText("/cleartarget") end
        for i = 1, #TARGET do
            local t = TARGET[i]
            if t and (UnitAffectingCombat(t) or IsPvP()) and ActualDistance(t) and (not IsPvP() or UnitIsPlayer(t))  then 
                RunMacroText("/startattack " .. target) 
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
            or not ActualDistance("target")  -- далековато
            or (not IsPvP() and not UnitAffectingCombat("target")) -- моб не в бою
            or (IsPvP() and not UnitIsPlayer("target")) -- не игрок в пвп
            )  then 
            if UnitExists("target") then RunMacroText("/cleartarget") end
        end
    end
end

function TryBuffs()
    if HasBuff("Крадущийся зверь") or InCombatLockdown() or (IsFalling() or IsSwimming()) or not IsAttack() then return false end
    if HasBuff("дикой природы", 15 * 60) then return false end
    if GetShapeshiftForm() ~= 0 then RunMacroText("/cancelform") return true end
    if DoSpell("Знак дикой природы", "player") then return true end
    return false
end