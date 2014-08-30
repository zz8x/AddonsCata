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
local interruptTime = 0
function TryInterrupt(target)
    if target == nil then target = "target" end
    if GetTime() < interruptTime  then return false end
    local spell, t, channel, notinterrupt, m = GetKickInfo(target)
    if not spell then return end
    
    -- if UnitCastingInfo("player") ~= nil then RunMacroText("/stopcasting") end

    if (channel or t < 0.8) and DoSpell("Слово Тьмы: Смерть", target) then 
        echo("Швд"..m)
        RunMacroText("/cancelaura Слово силы: Щит")
        interruptTime = GetTime() + 1
        return true 
    end

end

------------------------------------------------------------------------------------------------------------------
function DoSpell(spellName, target)
    return UseSpell(spellName, target)
end



