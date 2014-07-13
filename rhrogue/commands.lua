-- Rogue Rotation Helper by Timofeev Alexey
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
function TryAura()
    if IsMounted() then
        if not HasBuff("Аура воина Света") then return DoSpell("Аура воина Света") end
        return false
    end
    if IsAttack() then
        if not HasBuff("Аура") or HasBuff("Аура воина Света") then 
            if not HasBuff("Аура сопротивления") then return DoSpell("Аура сопротивления") end
            if not HasBuff("Аура благочестия") then return DoSpell("Аура благочестия") end
            if not HasBuff("Аура воздаяния") then return DoSpell("Аура воздаяния") end
            if not HasBuff("Аура сосредоточенности") then return DoSpell("Аура сосредоточенности") end
        end
    end
    return false
end
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
            -- Парашют
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
        local mount = (IsShift() or IsBattleground() or IsArena()) and  "Стремительный белый рысак" or "Белоснежный грифон" 
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

