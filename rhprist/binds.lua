-- Prist Rotation Helper by Timofeev Alexey
-- Binding
BINDING_HEADER_PRH = "Prist Rotation Helper"
BINDING_NAME_PRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
print("|cff0055ffRotation Helper|r|cffffe00a > |r|cffbbbbbbPrist|r loaded")
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

function DoSpell(spell, target, mana)
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
       --[[ if HasBuff("Облик медведя") and InRange("Лобовая атака(Облик медведя)", target) and DoSpell("Лобовая атака(Облик медведя)", target) then 
            echo("Лобовая атака"..m)
            interruptTime = GetTime() + 4
            return true 
        end]]
    end
end
------------------------------------------------------------------------------------------------------------------
function IsTrash(itemName)
    if sContains(itemName, "ларец") or sContains(itemName, "сейф") then
        return true
    end
    return false
end

------------------------------------------------------------------------------------------------------------------
-- Автоматическая покупка предметов
local function autoBuy(name, count)
    local c = count - countItem(name)
    if c > 0 then buy(name, c) end
end

local function UpdateItems(name)
    autoBuy("Легкое перышко", 20)
end
AttachEvent('MERCHANT_SHOW', UpdateItems)