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

    if not (IsAttack() or InCombatLockdown()) then
        return
    end

    --    if CanInterrupt then
    --        for i=1,#TARGETS do
    --            TryInterrupt(TARGETS[i])
    --        end
    --    end

    if HasSpell('Облик тьмы') then
        TryBuffs()
        TryTarget()
        RDDRotation()
    end
end
------------------------------------------------------------------------------------------------------------------

function ActualDistance(target)
    if target == nil then
        target = 'target'
    end
    return (CheckInteractDistance(target, 3) == 1) and not InRange('Пытка разума', target)
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
    if not HasBuff('Облик Тьмы') then
        --if GetBuffStack("Жизнецвет", "player") < 3 and DoSpell("Жизнецвет", "player") then return end
        if (myHP < 50 and myMana > 30) then
            if not HasBuff('Обновление') and DoSpell('Обновление', 'player') then
                return
            end
            if not HasBuff('Молитва восстановления') and DoSpell('Молитва восстановления', 'player') then
                return
            end
        end
        if DoSpell('Облик Тьмы', 'player') then
            return true
        end
    end

    if myHP < (InMelee() and 80 or 50) and not HasDebuff('Ослабленная душа', 0.01, 'player') and DoSpell('Слово силы: Щит') then
        return
    end

    if not (IsValidTarget('target') and CanAttack('target') and (UnitAffectingCombat('target') or IsAttack())) then
        return
    end

    RunMacroText('/startattack')

    if HasBuff('Слияние с Тьмой') then
        return
    end

    if not inPlace and (myHP < 30 or myMana < 30) and DoSpell('Слияние с Тьмой') then
        return
    end

    --    if not IsCtr() and  myMana < (IsSpellInUse("Выстрел") and 70 or 30) then
    --        if not IsSpellInUse("Выстрел") then DoSpell("Выстрел") end
    --print(1)
    --        return
    --    end

    if GetBuffStack('Приверженность Тьме', 'player') > 4 and DoSpell('Архангел', 'player') then
        return
    end

    local tHP = UnitHealth('target') or 0
    local tHP100 = UnitHealth('target') or 0

    if (myHP > 60 and myMana < 90) and DoSpell('Слово Тьмы: Смерть', 'target') then
        return
    end

    -- UseSlot(13)
    -- UseSlot(14)

    if DoSpell('Исчадие Тьмы') then
        return
    end
    --if DoSpell("Ракетный обстрел") then return end

    if IsShift() then
        if IsPlayerCasting('Пытка разума') then
            if DEBUG then
                print('stopcasting for Иссушение разума')
            end
            RunMacroText('/stopcasting')
        end

        if inPlace and DoSpell('Иссушение разума', 'target') then
            return
        end
        --print(2)
        return
    end

    if
        inPlace and --and GetBuffStack("Сфера Тьмы", "player") > 2
            HasBuff('Сфера Тьмы') and
            HasMyDebuff('Прикосновение вампира') and
            IsSpellNotUsed('Взрыв разума', 2, true) and
            IsReadySpell('Взрыв Разума')
     then
        -- if IsPlayerCasting("Пытка разума") and not InGCD() then
        --     if DEBUG then print("stopcasting for Взрыв разума") end
        --     RunMacroText("/stopcasting")
        -- end
        UseSlot(13)
        UseSlot(14)
        if DoSpell('Взрыв разума', 'target') then
            return
        end

        return
    end

    if inPlace and not HasMyDebuff('Прикосновение вампира') and IsSpellNotUsed('Прикосновение вампира', 2, true) and DoSpell('Прикосновение вампира', 'target') then
        return
    end

    if not HasMyDebuff('Всепожирающая чума') and IsSpellNotUsed('Всепожирающая чума', 2, true) then
        if DoSpell('Всепожирающая чума', 'target') then
            return
        end
        return
    end
    if not HasMyDebuff('Слово Тьмы: Боль') and IsSpellNotUsed('Слово Тьмы: Боль', 2, true) then
        if DoSpell('Слово Тьмы: Боль', 'target') then
            return
        end
        return
    end

    if inPlace and DoSpell('Пытка разума', 'target') then
        return
    end
    --if not IsSpellInUse("Выстрел") then DoSpell("Выстрел") end
end
