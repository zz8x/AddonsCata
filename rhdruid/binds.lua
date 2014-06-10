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
    return UseSpell(spell, target, mana)
end
------------------------------------------------------------------------------------------------------------------
local nointerruptBuffs = {"Мастер аур", "Сила духа"}
function TryInterrupt(target)
    if target == nil then target = "target" end
    if not IsValidTarget(target) then return false end
    local channel = false
    local spell, _, _, _, _, endTime, _, _, notinterrupt = UnitCastingInfo(target)
        
    if not spell then 
        spell, _, _, _, _, endTime, _, nointerrupt = UnitChannelInfo(target)
        channel = true
    end
    
    if not spell then return false end

    if IsPvP() and not InInterruptRedList(spell) then return false end
    local t = endTime/1000 - GetTime()

    if t < 0.2 then return false end
    if channel and t < 0.7 then return false end

    m = " -> " .. spell .. " ("..target..")"

    if not notinterrupt and not HasBuff(nointerruptBuffs, 0.1, target) and HasBuff("Облик кошки") then 
        if (channel or t < 0.8) and InRange("Лобовая атака(Облик кошки)", target) and DoSpell("Лобовая атака(Облик кошки)", target) then 
            echo("Лобовая атака"..m)
            interruptTime = GetTime() + 4
            return true 
        end
    end
    if not notinterrupt and not HasBuff(nointerruptBuffs, 0.1, target) and HasBuff("Облик медведя") then 
        if (channel or t < 0.8) and InRange("Лобовая атака(Облик медведя)", target) and DoSpell("Лобовая атака(Облик медведя)", target) then 
            echo("Лобовая атака"..m)
            interruptTime = GetTime() + 4
            return true 
        end
    end

end