-- Rogue Rotation Helper by Timofeev Alexey
-- Binding
BINDING_HEADER_RRH = "Rogue Rotation Helper"
BINDING_NAME_RRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
BINDING_NAME_RRH_AUTO_AOE = "Авто AOE"
print("|cff0055ffRotation Helper|r|cffffe00a > |r|cffffff20Rogue|r loaded")
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
local interruptTime = 0
function TryInterrupt(target)
    if target == nil then target = "target" end
    if GetTime() < interruptTime  then return false end
    local spell, t, channel, notinterrupt, m = GetKickInfo(target)
    if not spell then return end
    if not notinterrupt and not IsInterruptImmune(target) then 
        if (channel or t < 0.8) and InMelee(target) and DoSpell("Пинок", target) then 
            echo("Пинок"..m)
            interruptTime = GetTime() + 4
            return true 
        end
    end
    return false
end
------------------------------------------------------------------------------------------------------------------
local freedomTime = 0
function AutoFreedom()
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
            return true
        end
    end 
end
------------------------------------------------------------------------------------------------------------------
function DoSpell(spell, target, mana)
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
-- Автоматическая покупка предметов
local function autoBuy(name, count)
    local c = count - countItem(name)
    if c > 0 then buy(name, c) end
end

local function UpdateItems(name)
    autoBuy("Дурманящий яд", 20)
    autoBuy("Смертельный яд", 20)
    autoBuy("Нейтрализующий яд", 20)
    autoBuy("Калечащий яд", 20)
    autoBuy("Пшеничный рогалик с маслом", 20)
end
AttachEvent('MERCHANT_SHOW', UpdateItems)
------------------------------------------------------------------------------------------------------------------
local autoLootTimer = 0
function TemporaryAutoLoot(t)
    if not t then t = 3 end
    if autoLootTimer == 0 then
        chat("Автолут ON")
        RunMacroText("/console autoLootDefault 1")
    end
    autoLootTimer = GetTime() + t
end
local function UpdateAutoLootTimer()
    if autoLootTimer ~= 0 and GetTime() > autoLootTimer then
        chat("Автолут OFF")
        RunMacroText("/console autoLootDefault 0")
        autoLootTimer = 0
    end
end
AttachUpdate(UpdateAutoLootTimer) 

------------------------------------------------------------------------------------------------------------------
local lootList = {}
local function tryLootFromList()
    if #lootList < 1 then return end
    TemporaryAutoLoot(2)
    RunMacroText("/use ".. lootList[1])
    tremove(lootList, 1)
    setTimeout(0.5, tryLootFromList)
end

function openContainers(name)
    if #lootList > 0 then return end
    for bag=0,NUM_BAG_SLOTS do
        for slot=1,GetContainerNumSlots(bag) do
            local item = GetContainerItemLink(bag,slot)
            if item then 
                local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType,
                        itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(item)
                if sContains(itemName, "ларец") or sContains(itemName, "сейф") then
                    RunMacroText("/use  Взлом замка")
                    RunMacroText("/use "..bag .." " .. slot)
                    tinsert(lootList, bag .." " .. slot)
                end 
            end
        end
    end
    tryLootFromList()
end
------------------------------------------------------------------------------------------------------------------
function gopStop()
    RunMacroText("/stopmacro [nostealth]")
    RunMacroText("/cleartarget")
    RunMacroText("/targetenemy")
    RunMacroText("/stopmacro [noexists]")
    TemporaryAutoLoot(2)
    RunMacroText("/cast Обшаривание карманов")
end
------------------------------------------------------------------------------------------------------------------
