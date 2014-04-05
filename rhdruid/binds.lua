-- Druid Rotation Helper by Timofeev Alexey
-- Binding
BINDING_HEADER_DRH = "Druid Rotation Helper"
BINDING_NAME_DRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
BINDING_NAME_DRH_AUTO_AOE = "Авто AOE"
print("|cff0055ffRotation Helper|r|cffffe00a > |r|cffff7d0aDruid|r loaded")
------------------------------------------------------------------------------------------------------------------
if CanInterrupt == nil then CanInterrupt = true end

function UseInterrupt()
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
