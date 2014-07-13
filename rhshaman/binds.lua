-- Shaman Rotation Helper by Timofeev Alexey
-- Binding
BINDING_HEADER_SRH = "Shaman Rotation Helper"
BINDING_NAME_SRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
print("|cff0055ffRotation Helper|r|cffffe00a > |r|cff0000ffShaman|r loaded")
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

    if not notinterrupt and not IsInterruptImmune(target) then 
        if (channel or t < 0.8) and InMelee(target) and DoSpell("Пронизывающий ветер", target) then 
            echo("Пронизывающий ветер"..m)
            interruptTime = GetTime() + 2
            return true 
        end
    end

end

------------------------------------------------------------------------------------------------------------------
function DoSpell(spell, target, mana)
    return UseSpell(spell, target, mana)
end
