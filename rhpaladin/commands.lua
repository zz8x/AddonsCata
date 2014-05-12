-- Paladin Rotation Helper by Timofeev Alexey
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
SetCommand("control", 
    function(spell, target) 
        if target == nil then target = "target" end
        return DoSpell(spell, target)
    end, 
    function(spell, target) 
        if target == nil then target = "target" end
        if HasDebuff(spell, 0.1, target) then chat(spell..':OK!') return true end
        if not CanControl(target) then chat(spell..':!control') return true end
        if not InGCD() and not IsReadySpell(spell) then chat(spell..':!Ready') return true end
        if not CanMagicAttack(target)  then  chat(spell..':!Magic') return true end
        return false  
    end
)
------------------------------------------------------------------------------------------------------------------
local tryMount = 0
SetCommand("mount", 
    function() 
        --[[if not IsArena() then
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
        end]]
        if InGCD() or InCombatLockdown() or IsMounted() or CanExitVehicle() or IsPlayerCasting() or not IsOutdoors() or not PlayerInPlace() then
            tryMount = GetTime() 
            return true
        end
        local mount = (IsShift() or IsBattleground() or IsArena()) and  "Призыв боевого коня" or "Вороной грифон" 
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
 ------------------------------------------------------------------------------------------------------------------