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
local interruptTime = 0
function TryInterrupt(target)
    if target == nil then target = "target" end

    if GetTime() < interruptTime  then return false end
    local spell, t, channel, notinterrupt, m = GetKickInfo(target)
    if not spell then return end
    
    local item = "Высокомощный крепежный пистолет"
    if (not IsArena() and (channel or t < 1.8 ) and t > 1.2 and IsOneUnit(target, "mouseover") and not IsInterruptImmune(target))
        and (GetItemCount(item) > 0 and IsReadyItem(item) and GetItemCount("Горсть обсидиановых болтов") > 0)
        and (UnitIsPlayer(target) or GetUnitName("player") == GetUnitName(target .. "-target")  or UnitClassification(target) == "worldboss") 
        and UseItem(item) then 
        echo(item..m)
        interruptTime = GetTime() + 1
        return true 
    end

    if not notinterrupt and not IsInterruptImmune(target) and CanMagicAttack(target) then 
        if (channel or t < 0.8) and InMelee(target) and DoSpell("Укор", target) then 
            echo("Укор"..m)
            interruptTime = GetTime() + 1
            return true 
        end
    end

    return false
end
------------------------------------------------------------------------------------------------------------------
local freedomTime = 0
function UpdateAutoFreedom()
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
AttachUpdate(UpdateAutoFreedom, -7)
------------------------------------------------------------------------------------------------------------------
local dispelSpell = "Очищение"
local dispelTypes = {"Poison", "Disease"}
local dispelTypesHeal = {"Poison", "Disease", "Magic"}

function TryDispel(unit)
    if not IsReadySpell(dispelSpell) or InGCD() or not CanHeal(unit) or HasDebuff("Нестабильное колдовство", 0.1, unit) then return false end
    for i = 1, 40 do
        if not ret then
            local name, _, _, _, debuffType, duration, expirationTime   = UnitDebuff(unit, i,true) 
            if name and (expirationTime - GetTime() >= 3 or expirationTime == 0) and tContains(HasSpell("Шок небес") and dispelTypesHeal or dispelTypes, debuffType) then
                return DoSpell(dispelSpell, unit)
            end
        end
    end
    return false
end
------------------------------------------------------------------------------------------------------------------
local forbearanceSpells = {"Божественный щит", "Возложение рук", "Длань защиты"}
local forceSpells = {"Торжество", "Шок небес", "Вердикт храмовника"}
------------------------------------------------------------------------------------------------------------------
function DoSpell(spell, target, mana)
    if tContains(forbearanceSpells, spellName) then
        local unit = target
        if unit == nil then 
            unit = "player" 
        else
            if not CanHeal(unit) then 
                unit = "player"
            end
        end
        if HasDebuff("Воздержанность", 0.01, unit) then return false end
    end
    if tContains(forceSpells, spellName) then
        if not target then target = "target" end
        if InRange(spell, target) and IsSpellNotUsed(0.1) then 
            RunMacroText("/cast [@"..target.."] !"..spell) 
        end
        return not IsSpellNotUsed(0.1)
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
