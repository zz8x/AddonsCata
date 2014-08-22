-- Priest Rotation Helper by Timofeev Alexey
print("|cff0055ffRotation Helper|r|cffffe00a > |cffffffff Priest|r loaded.")
-- Binding
BINDING_HEADER_RHPRIEST = "Priest Rotation Helper"
BINDING_NAME_RH_INTERRUPT = "Вкл/Выкл сбивание кастов"
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

------------------------------------------------------------------------------------------------------------------
local sList = {
    "Соблазн",
    "Страх",
    "Контроль над разумом",
    "Превращение",
    "Сглаз"
}

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
    
    if not tContains(sList, spell) or UnitHealth100("player") < 20 then return false end
    
    local t = endTime/1000 - GetTime()

    if t < 0.2 then return false end

    m = " -> " .. spell .. " ("..target..")"
    
    -- if UnitCastingInfo("player") ~= nil then RunMacroText("/stopcasting") end

    if (channel or t < 0.8) and DoSpell("Слово Тьмы: Смерть", target) then 
        echo("Швд"..m)
        RunMacroText("/cancelaura Слово силы: Щит")
        interruptTime = GetTime()
        return true 
    end

end

------------------------------------------------------------------------------------------------------------------
function DoSpell(spellName, target)
    return UseSpell(spellName, target)
end



