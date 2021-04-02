-- Prist Rotation Helper by Timofeev Alexey
-- Binding
BINDING_HEADER_PRH = 'Prist Rotation Helper'
BINDING_NAME_PRH_INTERRUPT = 'Вкл/Выкл сбивание кастов'
print('|cff0055ffRotation Helper|r|cffffe00a > |r|cffbbbbbbPrist|r loaded')
------------------------------------------------------------------------------------------------------------------
if CanInterrupt == nil then
    CanInterrupt = true
end

function InterruptToggle()
    CanInterrupt = not CanInterrupt
    if CanInterrupt then
        echo('Interrupt: ON', true)
    else
        echo('Interrupt: OFF', true)
    end
end
------------------------------------------------------------------------------------------------------------------
function DoSpell(spell, target)
    return UseSpell(spell, target)
end
------------------------------------------------------------------------------------------------------------------
function TryInterrupt(target)
    if target == nil then
        target = 'target'
    end
end
------------------------------------------------------------------------------------------------------------------
function IsTrash(itemName)
    if sContains(itemName, 'ларец') or sContains(itemName, 'сейф') then
        return true
    end
    return false
end

------------------------------------------------------------------------------------------------------------------
