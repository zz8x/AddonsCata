﻿-- Paladin Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local teammate = "Смерчебот"
function DoHelpCommand(cmd, param)
     local target = "player"
     if IsAlt() then target = teammate end
     if not CanHeal(target) then chat('!help ' .. target) return end
     DoCommand(cmd, param, target)
end
------------------------------------------------------------------------------------------------------------------
function DoAttackCommand(cmd, param)
     local target = "target"
     if IsAlt() then target = "focus" end
     if not CanAttack(target) then chat('!Attack ' .. target) return end
     DoCommand(cmd, param, target)
end
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
        if HasDebuff(spell, 0.1, target) then chat(spell..': OK!') return true end
        if not HasSpell(spell) then chat(spell .. ": Нет спела!") return true end
        if not InRange(spell, target) then chat(spell .. ": Неверная дистанция!") return true end
        local aura = InControl(target, 0.1)
        if aura then chat(spell..': уже в котроле '..aura) return true end
        if not CanControl(target, spell) then chat(spell..': '..CanControlInfo) return true end
        if (not InGCD() and not IsReadySpell(spell)) or not IsSpellNotUsed(spell, 1) then chat(spell..': КД') return true end
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
            -- Парашют
            if GetFalingTime() > 1 and UseSlot(15) then
                chat("Парашют")
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
        local mount = (IsShift() or IsBattleground() or IsArena()) and "Стремительный гнедой рысак" or "Камнешкурый дракон"--"Ветролет" 
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