-- DK Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- // /run if IsReadySpell("s") and СanMagicAttack("target") then DoCommand("spell", "s", "target") end
SetCommand("spell", 
    function(spell, target) 
        if DoSpell(spell, target) then
            echo(spell.."!",1)
        end
    end, 
    function(spell, target) 
        if not HasSpell(spell) then
            chat(spell .. " - нет спела!")
            return true
        end
        if not InRange(spell, target) then
            chat(spell .. " - неверная дистанция!")
            return true
        end
        if not IsSpellNotUsed(spell, 1)  then
            chat(spell .. " - успешно сработало!")
            return true
        end
        return false
    end
)

------------------------------------------------------------------------------------------------------------------
local morTime = 0
SetCommand("mor", 
    function() 
        if not HasRunes(100) then DoSpell("Кровоотвод") end
        return DoSpell("Мор")
    end, 
    function() 
        if not IsValidTarget("target") or not InMelee() or not (HasMyDebuff("Озноб") or HasMyDebuff("Кровавая чума")) then return true end
        return not IsSpellNotUsed("Мор", 1)  
    end
)
------------------------------------------------------------------------------------------------------------------
SetCommand("silence", 
    function(target) 
        local spell = "Удушение"
        if not HasRunes(100) then DoSpell("Кровоотвод") end
        if DoSpell(spell, target) then
            echo(spell.."!",1)
        end
    end, 
    function(target) 
        if not CanMagicAttack(target) or HasBuff("Мастер аур", 0.1, target) then 
            chat('silence: !CanMagicAttack')
            return true 
        end
        local spell = "Удушение"
        if not InRange(spell, target) then
            chat(spell .. " - неверная дистанция!")
            return true
        end
        if not IsSpellNotUsed(spell, 1)  then
            chat(spell .. " - успешно сработало!")
            return true
        end
        return false
    end
)
  
------------------------------------------------------------------------------------------------------------------
local stopImmune = {"Длань свободы", "Отражение заклинания"}
SetCommand("stop", 
    function(target) 
        if target == nil then target = "target" end
        if HasDebuff("Ледяные оковы",5,target)  or DoSpell("Ледяные оковы", target) then return true end
    end, 
    function(target) 
        if target == nil then target = "target" end
        if not CanAttack(target) then 
            chat('stop: !CanAttack') 
            return true 
        end
        local immune = HasBuff(stopImmune, 0.1, target)
        if immune then 
            chat('stop: ' .. immune) 
            return true  
        end
        local  debuffTime = GetDebuffTime("Ледяные оковы" ,target)
        if debuffTime > 5 then 
            chat('stop: ' .. debuffTime) 
            return true 
        end
        return false  
    end
)
------------------------------------------------------------------------------------------------------------------
-- Death Grip
SetCommand("dg", 
    function(target) 
        if target == nil then target = "target" end
        return DoSpell("Хватка смерти", target) 
    end, 
    function(target) 
        if target == nil then target = "target" end
        if not CanAttack(target)  or HasBuff("Отражение заклинания", 0.1, target) or not IsReadySpell("Хватка смерти") then return true end
        return false  
    end
)


------------------------------------------------------------------------------------------------------------------
local stunTime = 0
SetCommand("stun", 
    function(target) 
        if not IsReadySpell("Отгрызть") then return end
        if target == nil then target = "target" end
        RunMacroText("/petattack "..target)
        if DoSpell("Отгрызть", target) then 
            stunTime = GetTime()
            return true
        end
        DoSpell("Прыжок", target)
    end, 
    function(target) 
        if target == nil then target = "target" end
        if not HasSpell("Отгрызть") then chat('stun: !HasSpell') return true end
        if not IsReadySpell("Отгрызть") then chat('stun: !IsReady') return true end
        if not CanAttack(target)  then  chat('stun: !CanAttack') return true end
        if GetTime() - stunTime < 0.1 then
            stunTime = 0
            chat("stun!")
            return true
        end
        if not CanControl(target) then  chat('stun: !CanControl') return true end
        return false  
    end
)
------------------------------------------------------------------------------------------------------------------
local tryMount = 0
SetCommand("mount", 
    function() 
        if not IsArena() then
            -- ускорение
            if IsAlt() and not PlayerInPlace() and UseSlot(6) then
                chat("Ускорители")
                tryMount = GetTime()
                return true
            end
            -- парашут
            if GetFalingTime() > 1 and UseSlot(15) then
                chat("Парашют")
                tryMount = GetTime()
                return true
            end
            -- хождение по воде
            if (IsCtr() or IsSwimming()) 
                and DoSpell("Льдистый путь") then 
                tryMount = GetTime()
                return true
            end
            -- рыбная ловля
            if IsEquippedItemType("Удочка") and DoSpell("Рыбная ловля") then
                tryMount = GetTime()
                return true
            end
        end
        if InGCD() or InCombatLockdown() or IsMounted() or CanExitVehicle() or IsPlayerCasting() or not IsOutdoors() or not PlayerInPlace() then
            tryMount = GetTime() 
            return true
        end
        --local mount = (IsFlyableArea() and not IsShiftKeyDown()) and "Крылатый скакун Черного Клинка" or "Конь смерти Акеруса"
        local mount = (IsShift() or IsBattleground() or IsArena()) and  "Конь смерти Акеруса" or "Ветролет" --"Вороной грифон"
        if IsAlt() then mount = "Тундровый мамонт путешественника" end
        if UseMount(mount) then 
            tryMount = GetTime() 
            return true
        end
    end, 
    function() 

        if tryMount > 0 and GetTime() - tryMount > 0.01 then
            tryMount = 0    
            return  true
        end

        return false 
    end
)



