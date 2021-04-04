-- Prist Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------

local peaceBuff = {'Пища', 'Питье'}

function Idle()
    --print(IsSpellNotUsed("Прикосновение вампира", 2, true) and 'Yes' or 'No')
    --if IsSpellNotUsed("Прикосновение вампира", 2, true) and DoSpell("Прикосновение вампира", "target") then return end
    --if 1 then return end
    if IsAttack() then
        if CanExitVehicle() then
            VehicleExit()
        end
        if IsMounted() then
            Dismount()
            return
        end
    end
    -- дайте поесть (побегать) спокойно
    if not IsAttack() and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then
        return
    end

    if HasSpell('Облик тьмы') then
        TryBuffs()
        if not (InCombatMode() or IsArena()) then
            return
        end
        TryTarget()
        RDDRotation()
    end
end
------------------------------------------------------------------------------------------------------------------

function ActualDistance(target)
    if target == nil then
        target = 'target'
    end
    return InRange('Пытка разума', target)
    --return (CheckInteractDistance(target, 3) == 1)
end

function TryTarget()
    CheckTarget(true, ActualDistance)
end
------------------------------------------------------------------------------------------------------------------
function TryBuffs()
    if not HasBuff('Слово силы: Стойкость') and DoSpell('Слово силы: Стойкость', 'player') then
        return true
    end
    if not HasMyBuff('Внутренний огонь') and DoSpell('Внутренний огонь', 'player') then
        return true
    end
    if not HasMyBuff('Объятия вампира') and DoSpell('Объятия вампира', 'player') then
        return true
    end
    if not HasBuff('Защита от темной магии') and DoSpell('Защита от темной магии', 'player') then
        return true
    end
    return false
end
------------------------------------------------------------------------------------------------------------------

function RDDRotation()
    local myHP = UnitHealth100('player')
    local myMana = UnitMana100('player')
    local inPlace = PlayerInPlace()
    -- if not HasBuff('Облик Тьмы') then

    --     if (myHP < 50 and myMana > 30) then
    --         if not HasBuff('Обновление') and DoSpell('Обновление', 'player') then
    --             return
    --         end
    --         if not HasBuff('Молитва восстановления') and DoSpell('Молитва восстановления', 'player') then
    --             return
    --         end
    --     end
    --     if DoSpell('Облик Тьмы', 'player') then
    --         return true
    --     end
    -- end

    if myHP < (InMelee() and 80 or 50) and not HasDebuff('Ослабленная душа', 0.01, 'player') and DoSpell('Слово силы: Щит') then
        return
    end

    if not (IsValidTarget('target') and CanAttack('target') and (UnitAffectingCombat('target') or IsAttack())) then
        return
    end

    RunMacroText('/startattack')

    if HasBuff('Слияние с Тьмой') then
        if not IsSpellInUse('Выстрел') then
            DoSpell('Выстрел')
        end
        return
    end

    if ((myHP < 20) or (not inPlace and (myMana < 20))) and DoSpell('Слияние с Тьмой') then
        return
    end
    local bers = BersMode or (IsOneUnit('target', 'boss1') or IsOneUnit('target', 'boss2') or IsOneUnit('target', 'boss3'))
    if BersMode then
        -- if DoSpell("Ракетный обстрел") then return end
        UseSlot(13)
        UseSlot(14)
    end
    if (BersMode or (myMana < 40)) then
        if DoSpell('Исчадие Тьмы', 'target') then
            return
        end
        if GetBuffStack('Приверженность Тьме', 'player') > 4 and DoSpell('Архангел', 'player') then
            return
        end
    end
    if ((UnitHealth100('target') < 25) or (myMana < 40)) and (myHP > 30) and IsReadySpell('Слово Тьмы: Смерть') then
        DoSpell('Слово Тьмы: Смерть', 'target')
        return
    end

    if IsShift() and inPlace then
        if IsPlayerCasting('Пытка разума') then
            RunMacroText('/stopcasting')
        end
        DoSpell('Иссушение разума', 'target')
        return
    end

    if not HasMyDebuff('Слово Тьмы: Боль') and IsSpellNotUsed('Слово Тьмы: Боль', 2, true) then
        if DoSpell('Слово Тьмы: Боль', 'target') then
            return
        end
        return
    end

    local spheres = GetBuffStack('Сфера Тьмы', 'player')

    if inPlace and spheres > 0 and IsSpellNotUsed('Взрыв разума', 2, true) and IsReadySpell('Взрыв Разума') then
        DoSpell('Взрыв разума', 'target')
        return
    end

    if inPlace and not HasMyDebuff('Прикосновение вампира', GCDDuration) and IsSpellNotUsed('Прикосновение вампира', 2, true) and DoSpell('Прикосновение вампира', 'target') then
        return
    end

    if not HasMyDebuff('Всепожирающая чума') and IsSpellNotUsed('Всепожирающая чума', 2, true) then
        DoSpell('Всепожирающая чума', 'target')
        return
    end

    if inPlace and DoSpell('Пытка разума', 'target') then
        return
    end
    --if not IsSpellInUse("Выстрел") then DoSpell("Выстрел") end
end
