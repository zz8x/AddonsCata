-- Death Knight Rotation Helper by Timofeev Alexey
print("|cff0055ffRotation Helper|r|cffffe00a > |cff800000Death Knight|r loaded.")
-- Binding
BINDING_HEADER_RHDEATHKNIGHT = "Death Knight Rotation Helper"
BINDING_NAME_RHDEATHKNIGHT_AOE = "Вкл/Выкл AOE в ротации"
BINDING_NAME_RHDEATHKNIGHT_INTERRUPT = "Вкл/Выкл сбивание кастов"
------------------------------------------------------------------------------------------------------------------
if CanAOE == nil then CanAOE = true end

function AOEToggle()
    CanAOE = not CanAOE
    if CanAOE then
        echo("AOE: ON",true)
    else
        echo("AOE: OFF",true)
    end 
end

function IsAOE()
   if not CanAOE then return false end
   if IsShift() then return true end
   return (IsValidTarget("target") and IsValidTarget("focus") and not IsOneUnit("target", "focus") and Dotes(7) and Dotes(7, "focus"))
end

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
function IsMouse3()
    return  IsMouseButtonDown(3) == 1
end

------------------------------------------------------------------------------------------------------------------
function IsCtr()
    return  (IsControlKeyDown() == 1 and not GetCurrentKeyBoardFocus())
end

------------------------------------------------------------------------------------------------------------------
function IsAlt()
    return  (IsAltKeyDown() == 1 and not GetCurrentKeyBoardFocus())
end

------------------------------------------------------------------------------------------------------------------
function IsShift()
    return  (IsShiftKeyDown() == 1 and not GetCurrentKeyBoardFocus())
end
------------------------------------------------------------------------------------------------------------------

local nointerruptBuffs = {"Мастер аур"}
local lichSpells = {"Превращение", "Сглаз", "Соблазн", "Страх", "Вой ужаса", "Контроль над разумом"}
local conrLichSpells = {"Изгнание зла", "Сковывание нежити"}
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

    if tContains(conrLichSpells, spell) then RunMacroText("/cancelaura Перерождение") end

    if IsPvP() and not InInterruptRedList(spell) then return false end
    local t = endTime/1000 - GetTime()

    if t < 0.2 then return false end
    if channel and t < 0.7 then return false end

    m = " -> " .. spell .. " ("..target..")"

    if not notinterrupt and not HasBuff(nointerruptBuffs, 0.1, target) and CanMagicAttack(target) then 
        if (channel or t < 0.8) and InMelee(target) and DoSpell("Заморозка разума", target) then 
            echo("Заморозка разума"..m)
            interruptTime = GetTime() + 4
            return true 
        end
        if (not channel and t < 1.8) and DoSpell("Удушение", target) then 
            echo("Удушение"..m)
            interruptTime = GetTime() + 2
            return true 
        end
    end
    
    if CanAttack(target) and (channel or t < 0.8) and (UnitIsPlayer(target) or not InParty()) and DoSpell("Хватка смерти", target) then 
        echo("Хватка смерти"..m)
        interruptTime = GetTime() + 2
        return true 
    end

    if HasSpell("Перерождение") and IsOneUnit("player",target .. "-target") and tContains(lichSpells, spell) and DoSpell("Перерождение") then 
        echo("Перерождение"..m)
        interruptTime = GetTime() + 2
        return true 
    end

    if IsPvP() and IsHarmfulSpell(spell) and IsOneUnit("player", target .. "-target") and DoSpell("Антимагический панцирь") then 
        echo("Антимагический панцирь"..m)
        interruptTime = GetTime() + 5
        return true 
    end

end
------------------------------------------------------------------------------------------------------------------
local DeathPact = 0
local function UpdateDeathPact(event, ...)
    local timestamp, type, hideCaster,                                                                      
      sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,   
      spellId, spellName, spellSchool,                                                                     
      amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = ...
    if amount and sourceGUID == UnitGUID("player") and (type:match("^SPELL_CAST") and spellId and spellName)  then
        if spellName == "Смертельный союз" and amount == "У вас нет питомца." then
            DeathPact = GetTime()
        end
    end
end
AttachEvent("COMBAT_LOG_EVENT_UNFILTERED", UpdateDeathPact)

local pact = false
function NeedDeathPact()
    if pact and not IsReadySpell("Смертельный союз") then
        chat("Сожрал пета!")
        pact = false
    end
    if UnitHealth100(player) > 80 then pact = false end
    if pact then return true end
    if (InCombatLockdown() and UnitHealth100("player") < 60) and (IsReadySpell("Войско мертвых") or IsReadySpell("Воскрешение мертвых")) and IsReadySpell("Смертельный союз") and (GetTime() - DeathPact > 10) then return true end
    return false
end

function TryDeathPact()
    if InGCD() or UnitCastingInfo("player") ~= nil or UnitChannelInfo("player") ~= nil then return false end
    if pact then 
        if IsReadySpell("Смертельный союз") then
            DoSpell("Смертельный союз")
            return true
        end
        return false
    end
    if not NeedDeathPact() then return false end
    if  (IsReadySpell("Войско мертвых") or IsReadySpell("Воскрешение мертвых")) and IsReadySpell("Смертельный союз") then
        DoSpell(IsReadySpell("Воскрешение мертвых") and "Воскрешение мертвых" or "Войско мертвых")
        chat("Вызвал пета!")
        pact = true
        return true
    end
    return false
end

------------------------------------------------------------------------------------------------------------------
local lichList = {
"Сон",
"Соблазн",
"Страх", 
"Вой ужаса", 
"Устрашающий крик", 
"Контроль над разумом", 
"Глубинный ужас", 
"Ментальный крик"
}

    
local exceptionControlList = { -- > 4
"Ошеломление", -- 20s
"Покаяние", 
}

local freedomTime = 0
function UpdateAutoFreedom(event, ...)
    if GetTime() - freedomTime < 1.5 then return end
    local debuff = HasDebuff(lichList, 2, "player")
    if debuff then 
        if HasSpell("Перерождение") and IsReadySpell("Перерождение") then
            print("lich", debuff)
            DoCommand("lich") 
        else
            if not HasBuff("Перерождение") then  
                print("lich->freedom", debuff)
                DoCommand("freedom") 
            end
        end
        freedomTime = GetTime()
        return
    end 
    debuff = HasDebuff(ControlList, 2, "player")
    if debuff and (not tContains(exceptionControlList, debuff) or IsAttack()) then 
        local forceMode = tContains(exceptionControlList, debuff) and IsAttack() and "force!" or ""
        print("freedom", debuff, forceMode)
        DoCommand("freedom") 
        freedomTime = GetTime()
        return
    end 
end
AttachUpdate(UpdateAutoFreedom, -1)
------------------------------------------------------------------------------------------------------------------

local macroSpell = {
    "Отгрызть",
    "Прыжок",
    "Взрыв трупа",
    "Призыв горгульи",
    "Смертельный союз",
    "Воскрешение мертвых"
}

local spellRunes = {
    ["Ледяные оковы"] = 010,
    ["Ледяной столп"] = 010,
    ["Ледяное прикосновение"] = 010,
    ["Удар чумы"] = 001,
    ["Некротический удар"] = 001,
    ["Вскипание крови"] = 100,
    ["Кровавый удар"] = 100,
    ["Удар смерти"] = 011,
    ["Удар Плети"] = 001,
    ["Уничтожение"] = 011,
    ["Костяной щит"] = 001,
    ["Удар разложения"] = 110,
    ["Захват рун"] = 100,
    ["Мор"] = 100,
    ["Войско мертвых"] = 111,
    ["Смерть и разложение"] = 001,
    ["Врата смерти"] = 001,
    ["Зона антимагии"] = 001,
    ["Удушение"] = 100,
    ["Удар в сердце"] = 100,
}

local spellCD = {}
function DoSpell(spellName, target, baseRP)
    local t = GetTime()
    local c = spellCD[spellName]
    if c ~= nil and t - c < 0.1 then 
        return false 
    end

    if tContains(macroSpell, spellName) then
        if not IsReadySpell(spellName) or not InRange(spellName, target) then return false end
        local cast = "/cast "
        if target then cast = cast .. "[@" .. target .. "] " end
        RunMacroText(cast .. spellName)
        spellCD[spellName] = t
        chat(spellName)
        return IsReadySpell(spellName)
    end
    runes = spellRunes[spellName]
    if runes ~= nil and not HasRunes(runes) then return false end

    if not baseRP or IsAttack() then baseRP = 0 end

    local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange  = GetSpellInfo(spellName)

    if NeedDeathPact() then 
        if name ~= "Смертельный союз" then 
            if IsReadySpell("Смертельный союз") or (powerType == 6) then return false end
        end
        if IsReadySpell("Войско мертвых") and IsReadySpell("Смертельный союз") and name ~= "Войско мертвых" then return false end
    end

    if (powerType == 6) then
        if IsCtr() then return false end
        if cost > 0 and UnitMana("player") - cost < baseRP then return false end
    end

    spellCD[spellName] = t
    return UseSpell(spellName, target)
end
------------------------------------------------------------------------------------------------------------------
if TrashList == nil then TrashList = {} end
function IsTrash(n) --n - itemlink
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(n)
    if tContains(TrashList, itemName) then return true end
    if itemRarity == 2 and (itemType == "Оружие" or itemType == "Доспехи") then
      return true
    end
    return false
end


function trashToggle()
    local itemName, ItemLink = GameTooltip:GetItem()
    if nil == itemName then return end
    if tContains(TrashList, itemName) then 
        for i=1, #TrashList do
            if TrashList[i] ==  itemName then 
                tremove(TrashList, i)
                chat(itemName .. " это НЕ Хлам! ")
            end
        end            
    else
        chat(itemName .. " это Хлам! ")
        tinsert(TrashList, itemName)
    end
end