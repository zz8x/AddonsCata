-- Paladin Rotation Helper by Timofeev Alexey
-- Binding
BINDING_HEADER_PRH = "Paladin Rotation Helper"
BINDING_NAME_PRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
BINDING_NAME_PRH_AUTO_AOE = "Авто AOE"
print("|cff0055ffRotation Helper|r|cffffe00a > |r|cffff4080Paladin|r loaded")
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
        if (channel or t < 0.8) and InMelee(target) and DoSpell("Укор", target) then 
            echo("Укор"..m)
            interruptTime = GetTime() + 2
            return true 
        end
    end

end
------------------------------------------------------------------------------------------------------------------
local freedomTime = 0
function UpdateAutoFreedom(event, ...)
    -- не слишком часто
    if GetTime() - freedomTime < 0.5 then return end
    freedomTime = GetTime()
    -- контроли или сапы (по атаке)
    debuff = InStun("player", 2) or (IsCtr() and InSap("player", 2))
    -- больше 3 сек
    if debuff and (IsCtr() or GetDebuffTime(debuff, "player") > 3) then
        Notify('freedom: ' .. debuff)
        if DoSpell("Каждый за себя") then
            chat('freedom: ' .. debuff)
        end
    end 
end
AttachUpdate(UpdateAutoFreedom, -1)
------------------------------------------------------------------------------------------------------------------
local dispelSpell = "Очищение"
local dispelTypes = {"Poison", "Disease"}
function TryDispel(unit)
    if not IsReadySpell(dispelSpell) or InGCD() or not CanHeal(unit) or HasDebuff("Нестабильное колдовство", 0.1, unit) then return false end
    for i = 1, 40 do
        if not ret then
            local name, _, _, _, debuffType, duration, expirationTime   = UnitDebuff(unit, i,true) 
            if name and (expirationTime - GetTime() >= 3 or expirationTime == 0) and tContains(dispelTypes, debuffType) then
                return DoSpell(dispelSpell, unit)
            end
        end
    end
    return false
end
------------------------------------------------------------------------------------------------------------------
local forbearanceSpells = {"Божественный щит", "Возложение рук", "Длань защиты"}
------------------------------------------------------------------------------------------------------------------
function DoSpell(spell, target, mana)
    if tContains(forbearanceSpells, spellName) then
        if target == nil then target = "player" end
        if HasDebuff("Воздержанность", 0.01, target) then return false end
    end
    return UseSpell(spell, target, mana)
end
------------------------------------------------------------------------------------------------------------------
if GrayList == nil then GrayList = {} end
if TrashList == nil then TrashList = {} end

function IsGray(n) --n - itemlink
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(n)
    if tContains(GrayList, itemName) then return true end
    if itemRarity == 2 and (itemType == "Оружие" or itemType == "Доспехи") then
      return true
    end
    return false
end


function grayToggle()
    local itemName, ItemLink = GameTooltip:GetItem()
    if nil == itemName then return end
    if tContains(GrayList, itemName) then 
        for i=1, #GrayList do
            if GrayList[i] ==  itemName then 
                tremove(GrayList, i)
                chat(itemName .. " НЕ ПРОДАВАТЬ! ")
            end
        end            
    else
        chat(itemName .. " ПРОДАВАТЬ! ")
        tinsert(GrayList, itemName)
    end
end
------------------------------------------------------------------------------------------------------------------

function IsTrash(n) --n - itemlink
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(n)
    if sContains(itemName, "Эскиз:") then return true end
    if tContains(TrashList, itemName) then return true end
    return false
end


function trashToggle()
    local itemName, ItemLink = GameTooltip:GetItem()
    if nil == itemName then return end
    if tContains(TrashList, itemName) then 
        for i=1, #TrashList do
            if TrashList[i] ==  itemName then 
                tremove(TrashList, i)
                chat(itemName .. " НЕ УДАЛЯТЬ! ")
            end
        end            
    else
        chat(itemName .. " УДАЛЯТЬ! ")
        tinsert(TrashList, itemName)
    end
end

------------------------------------------------------------------------------------------------------------------
