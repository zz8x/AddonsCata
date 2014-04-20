-- DK Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local freedomItem = nil
local freedomSpell = "Каждый за себя"
SetCommand("freedom", 
    function() 
        if HasSpell(freedomSpell) then
            DoSpell(freedomSpell)
            return
        end
        UseEquippedItem(freedomItem) 
    end, 
    function() 
        if IsPlayerCasting() then return true end
        if freedomItem == nil then
           freedomItem = (UnitFactionGroup("player") == "Horde" and "Медальон Орды" or "Медальон Альянса")
        end
        if HasSpell(freedomSpell) and (not InGCD() and not IsReadySpell(freedomSpell)) then return true else return false end
        return not IsEquippedItem(freedomItem) or (not InGCD() and not IsReadyItem(freedomItem)) 
    end
)

------------------------------------------------------------------------------------------------------------------

SetCommand("lich", 
    function() 
        if DoSpell("Перерождение") then
            echo("Перерождение!",1)
        end
    end, 
    function() 
        return not HasSpell("Перерождение") or  HasBuff("Перерождение", 1, "player") or not IsSpellNotUsed("Перерождение", 1) 
    end
)
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
        if not CanMagicAttack(target) or HasBuff("Мастер аур", 0.1, target) then return true end
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
        if HasDebuff("Ледяные оковы",6,target)  or DoSpell("Ледяные оковы", target) then return true end
    end, 
    function(target) 
        if target == nil then target = "target" end
        if not CanAttack(target) or HasBuff(stopImmune, 0.1, target) or HasDebuff("Ледяные оковы", 6 ,target) then return true end
        return false  
    end
)
------------------------------------------------------------------------------------------------------------------
-- Death Grip
SetCommand("dg", 
    function(target) 
        if target == nil then target = "target" end
        if DoSpell("Хватка смерти", target) then 
            return true
        end
    end, 
    function(target) 
        if target == nil then target = "target" end
        if not CanAttack(target)  or HasBuff("Отражение заклинания", 0.1, target) or not IsReadySpell("Хватка смерти") then return true end
        return false  
    end
)


------------------------------------------------------------------------------------------------------------------
local tryMount = 0
SetCommand("mount", 
    function() 
        if (IsCtr() or IsSwimming()) 
            and DoSpell("Льдистый путь") then 
            tryMount = GetTime()
            return
        end
        if IsEquippedItemType("Удочка") and DoSpell("Рыбная ловля") then
            tryMount = GetTime()
            return
        end
        if InGCD() or InCombatLockdown() or IsMounted() or CanExitVehicle() or IsPlayerCasting() or not IsOutdoors() or not PlayerInPlace() then
            tryMount = GetTime() 
            return
        end
        --local mount = (IsFlyableArea() and not IsShiftKeyDown()) and "Крылатый скакун Черного Клинка" or "Конь смерти Акеруса"
        local mount = (IsShift() or IsBattleground() or IsArena()) and  "Конь смерти Акеруса" or "Вороной грифон"
        --if IsAlt() then mount = "Тундровый мамонт путешественника" end
        if UseMount(mount) then 
            tryMount = GetTime() 
            return
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


