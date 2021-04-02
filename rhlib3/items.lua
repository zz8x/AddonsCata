﻿-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
function IsReadySlot(slot)
    if not HasAction(slot) then
        return false
    end
    local itemID = GetInventoryItemID('player', slot)
    if not itemID or (IsItemInRange(itemID, 'target') == 0) then
        return false
    end
    if not IsReadyItem(itemID) then
        return false
    end
    return true
end

------------------------------------------------------------------------------------------------------------------

function UseSlot(slot)
    if IsPlayerCasting() then
        return false
    end
    if not IsReadySlot(slot) then
        return false
    end
    RunMacroText('/use ' .. slot)
    TrySpellTargeting()
    return not IsReadySlot(slot)
end

------------------------------------------------------------------------------------------------------------------
function GetItemCooldownLeft(name)
    local itemName, itemLink = GetItemInfo(name)
    if not itemName then
        if Debug then
            error('Итем [' .. name .. '] не найден!')
        end
        return false
    end
    local itemID = itemLink:match('item:(%d+):')
    local start, duration, enabled = GetItemCooldown(itemID)
    if enabled ~= 1 then
        return 1
    end
    if not start then
        return 0
    end
    if start == 0 then
        return 0
    end
    local left = start + duration - GetTime()
    return left
end

------------------------------------------------------------------------------------------------------------------
function ItemExists(item)
    return GetItemInfo(item) and true or false
end

------------------------------------------------------------------------------------------------------------------
function ItemInRange(item, unit)
    if ItemExists(item) then
        return (IsItemInRange(item, unit) == 1)
    end
    return false
end

------------------------------------------------------------------------------------------------------------------
function IsReadyItem(name)
    local usable = IsUsableItem(name)
    if not usable then
        return true
    end
    local left = GetItemCooldownLeft(name)
    if left > LagTime then
        return false
    end
    return true
end

------------------------------------------------------------------------------------------------------------------
function EquipItem(itemName)
    if IsEquippedItem(itemName) then
        return false
    end
    if Debug then
        print(itemName)
    end
    RunMacroText('/equip  ' .. itemName)
    return IsEquippedItem(itemName)
end
------------------------------------------------------------------------------------------------------------------

function UseItem(itemName, count)
    --if SpellIsTargeting() then CameraOrSelectOrMoveStart() CameraOrSelectOrMoveStop() end
    if IsPlayerCasting() then
        return false
    end
    if not IsEquippedItem(itemName) and not IsUsableItem(itemName) then
        return false
    end
    if not IsReadyItem(itemName) then
        return false
    end
    local spellName = GetItemSpell(itemName)
    local err = GetLastSpellError(spellName, 2)
    if err then
        if Debug then
            chat(itemName .. ' - ' .. err)
        end
        return false
    end
    if not count then
        count = 1
    end
    for i = 1, count do
        RunMacroText('/use ' .. itemName)
        TrySpellTargeting()
    end
    if not IsReadyItem(itemName) then
        if Debug then
            print(itemName)
        end
        return true
    end
    return false
end
------------------------------------------------------------------------------------------------------------------
function UseEquippedItem(item)
    if ItemExists(item) and IsReadyItem(item) then
        local itemSpell = GetItemSpell(item)
        if itemSpell and IsSpellInUse(itemSpell) then
            return false
        end
    end
    if IsEquippedItem(item) and UseItem(item) then
        return true
    end
    return false
end

------------------------------------------------------------------------------------------------------------------
local potions = {
    'Камень здоровья',
    'Легендарное лечебное зелье',
    'Рунический флакон с лечебным зельем' --[[,
	"Бездонный флакон с лечебным зельем",
    "Гигантский флакон с лечебным зельем"]]
}
function UseHealPotion()
    for i = 1, #potions do
        if UseItem(potions[i], 5) then
            return true
        end
    end
    return false
end
