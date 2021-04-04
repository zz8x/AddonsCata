-- Prist Rotation Helper by Timofeev Alexey
-- Binding
BINDING_HEADER_PRH = 'Prist Rotation Helper'
BINDING_NAME_PRH_BERS = 'Вкл/Выкл режим берсерка'
print('|cff0055ffRotation Helper|r|cffffe00a > |r|cffbbbbbbPrist|r loaded')
------------------------------------------------------------------------------------------------------------------
if BersMode == nil then
    BersMode = false
end

function BersModeToggle()
    BersMode = not BersMode
    if BersMode then
        echo('BersMode: ON', true)
    else
        echo('BersMode: OFF', true)
    end
end
------------------------------------------------------------------------------------------------------------------
function DoSpell(spell, target)
    return UseSpell(spell, target)
end
------------------------------------------------------------------------------------------------------------------
local function autobuy()
    buy('Высокогорная ключевая вода', 60)
end
AttachEvent('MERCHANT_SHOW', autobuy)
------------------------------------------------------------------------------------------------------------------
