-- Druid Rotation Helper by Timofeev Alexey
-- Binding
BINDING_HEADER_DRH = "Druid Rotation Helper"
BINDING_NAME_DRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
BINDING_NAME_DRH_AUTO_AOE = "Авто AOE"
print("|cff0055ffRotation Helper|r|cffffe00a > |r|cffff7d0aDruid|r loaded")
------------------------------------------------------------------------------------------------------------------
if CanInterrupt == nil then CanInterrupt = true end

function InterruptToggle()
    CanInterrupt = not CanInterrupt
    if CanInterrupt then
        echo("Interrupt: ON",true)
    else
        echo("Interrupt: OFF",true)
    end 
end
------------------------------------------------------------------------------------------------------------------
if AutoAOE == nil then AutoAOE = true end

function AutoAOEToggle()
    AutoAOE = not AutoAOE
    if AutoAOE then
        echo("Авто АОЕ: ON",true)
    else
        echo("Авто АОЕ: OFF",true)
    end 
end

function IsAOE()
   return (IsShiftKeyDown() == 1) or (AutoAOE and IsValidTarget("target") and IsValidTarget("focus") and not IsOneUnit("target", "focus") and InMelee("focus") and InMelee("target"))
end
------------------------------------------------------------------------------------------------------------------

function DoSpell(spell, target, mana)
    local baseMana =  (not IsAttack() and IsSpellNotUsed("Лобовая атака(Облик кошки)", 7.5)) and 10 or 0 -- 10 - 2.5
    local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange  = GetSpellInfo(spell)
    if powerType == 3 and cost > 0 and UnitPower("player" , powerType) - cost < baseMana then return false end
    return UseSpell(spell, target, mana)
end
------------------------------------------------------------------------------------------------------------------
local interruptTime = 0
function TryInterrupt(target)
    if target == nil then target = "target" end
    if GetTime() < interruptTime  then return false end
    local spell, t, channel, notinterrupt, m = GetKickInfo(target)
    if not spell then return end
    if not notinterrupt and not IsInterruptImmune(target) and (channel or t < 0.8)  then 
        if HasBuff("Облик кошки") and InRange("Лобовая атака(Облик кошки)", target) and DoSpell("Лобовая атака(Облик кошки)", target) then 
            echo("Лобовая атака"..m)
            interruptTime = GetTime() + 4
            return true 
        end
        if HasBuff("Облик медведя") and InRange("Лобовая атака(Облик медведя)", target) and DoSpell("Лобовая атака(Облик медведя)", target) then 
            echo("Лобовая атака"..m)
            interruptTime = GetTime() + 4
            return true 
        end
    end
end
------------------------------------------------------------------------------------------------------------------
local dispelSpell = "Снятие порчи"
local dispelTypes = {"Poison", "Curse"}
local dispelTypesHeal = {"Poison", "Curse", "Magic"}

function TryDispel(unit)
    if not IsReadySpell(dispelSpell) or InGCD() or not CanHeal(unit) or HasDebuff("Нестабильное колдовство", 0.1, unit) then return false end
    for i = 1, 40 do
        if not ret then
            local name, _, _, _, debuffType, duration, expirationTime   = UnitDebuff(unit, i,true) 
            if name and (expirationTime - GetTime() >= 3 or expirationTime == 0) and tContains(HasSpell("Буйный рост") and dispelTypesHeal or dispelTypes, debuffType) then
                return DoSpell(dispelSpell, unit)
            end
        end
    end
    return false
end
------------------------------------------------------------------------------------------------------------------