-- Paladin Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local bersTimer = 0
function UseBers()
    bersTimer = GetTime()
end

function IsBers()
    return IsPvP() and (GetTime() - bersTimer < 30) or (bersTimer ~= 0)
end
------------------------------------------------------------------------------------------------------------------
local fearTargetTime = 0
local peaceBuff = {"Пища", "Питье"}
local steathClass = {"ROGUE", "DRUID"}
function Idle()
    if bersTimer ~= 0 and not InCombatLockdown() then bersTimer = 0 end
    if not IsAttack() and not IsPlayerCasting() and TryAura() then return end
    if IsAttack() then
        if HasBuff("Парашют") then RunMacroText("/cancelaura Парашют") return end
        if CanExitVehicle() then VehicleExit() return end
        if IsMounted() then Dismount() return end 
    else
        -- дайте поесть (побегать) спокойно
        if IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)  or IsPlayerCasting() then return end

    end
     
    if IsMouse3() and TryTaunt("mouseover") then return end

    if HasDebuff("Темный симулякр", 0.1, "player") and DoSpell("Очищение", "player") then return end

    if InCombatLockdown() then

        TryProtect()

        if IsReadySpell("Изгнание зла") and (GetTime() - fearTargetTime > 2) then 
            fearTargetTime = GetTime()
            local tName = UnitName("target")
            RunMacroText("/targetexact [harm, nodead] Вороная горгулья")
            local uName = UnitName("target")
            if uName and uName == "Вороная горгулья"  then
                if not HasDebuff("Изгнание зла", 1, "target") then DoSpell("Изгнание зла") end
                RunMacroText("/focus target")
                if tName then RunMacroText("/targetlasttarget") end
            end
        end


        if IsReadySpell("Молот гнева") then
            for i = 1, #TARGETS do
                local t = TARGETS[i]
                if CanAttack(t) and UnitHealth100(t) < 20 and DoSpell("Молот гнева", t) then return end    
            end
        end

        if IsPvP() then
            if IsReadySpell("Изгнание зла") and IsSpellNotUsed("Изгнание зла", 5) then
                for i = 1, #TARGETS do
                    local t = TARGETS[i]
                    if CanMagicAttack(t) and (UnitCreatureType(t) == "Нежить" or UnitCreatureType(t) == "Демон")
                        and not HasDebuff("Изгнание зла", 0.1, t) and DoSpell("Изгнание зла",t) then return end
                end
            end

            if IsReadySpell("Длань возмездия") then
                for i = 1, #ITARGETS do
                    local t = ITARGETS[i]
                    if UnitIsPlayer(t) and CanAttack(t) and ((tContains(steathClass, GetClass(t)) and not UnitAffectingCombat(t)) or HasBuff("Эффект тотема заземления", 1, t)) and DoSpell("Длань возмездия", t) then return end
                end
            end

            if IsReadySpell("Укор") then
                for i = 1, #ITARGETS do
                    local t = ITARGETS[i]
                    if UnitIsPlayer(t) and CanAttack(t) and HasBuff(reflectBuff, 1, t) and DoSpell("Укор", t) then return end
                end
            end
        end

        if HasBuff("Праведное неистовство") and InGroup() then
            for i = 1, #TARGETS do
                local t = TARGETS[i]
                if UnitAffectingCombat(t) and TryTaunt(t) then return end
            end
        end
    end

    if HasSpell("Шок небес") then
        if IsAttack() then TryTarget() end
        HolyRotation()
        if not IsPlayerCasting() and TryBuff() then return end
        return
    end
    
    if (IsArena() or InDuel() or InCombatLockdown() or IsCtr()) and TrySave() then return end
    
	if IsAttack() or InCombatLockdown() then
        TryTarget()        
        Rotation()
        if not IsPlayerCasting() and TryBuff() then return end
        return
    end
end

------------------------------------------------------------------------------------------------------------------
local function IsFinishHim(target) 
    return CanAttack(target) and UnitHealth100(target) < 35 
end
------------------------------------------------------------------------------------------------------------------
function ActualDistance(target)
    if target == nil then target = "target" end
    return (CheckInteractDistance(target, 4) == 1)
end
------------------------------------------------------------------------------------------------------------------
function TryTarget(useFocus)
    -- помощь в группе
    if not IsValidTarget("target") and InGroup() then
        -- если что-то не то есть в цели
        if UnitExists("target") then RunMacroText("/cleartarget") end
        for i = 1, #TARGET do
            local t = TARGET[i]
            if t and (UnitAffectingCombat(t) or IsPvP()) and ActualDistance(t) and (not IsPvP() or UnitIsPlayer(t))  then 
                RunMacroText("/target [@" .. t .. "]")
                if CanAttack("target") then
                    break
                end
            end
        end
    end
    -- пытаемся выбрать ну хоть что нибудь
    if not IsValidTarget("target") then
        -- если что-то не то есть в цели
        if UnitExists("target") then RunMacroText("/cleartarget") end
        RunMacroText("/targetenemy" .. (IsPvP() and "player" or "") .." [nodead]")
        if not IsAttack()  -- если в авторежиме
            and (
            not IsValidTarget("target")  -- вообще не цель
            or (not IsArena() and not ActualDistance("target"))  -- далековато
            or (not IsPvP() and not UnitAffectingCombat("target")) -- моб не в бою
            or (IsPvP() and not UnitIsPlayer("target")) -- не игрок в пвп
            )  then 
            if UnitExists("target") then RunMacroText("/cleartarget") end
        end
    end

    if useFocus ~= false then 
        if IsMouse3() and IsValidTarget("mouseover") and not IsOneUnit("target", "mouseover") then 
            RunMacroText("/focus mouseover") 
        end
        if not IsValidTarget("focus") then
            if UnitExists("focus") then RunMacroText("/clearfocus") end
            for i = 1, #TARGETS do
                local t = TARGETS[i]
                if UnitAffectingCombat(t) and ActualDistance(t) and not IsOneUnit("target", t) and (not IsPvP() or UnitIsPlayer(t)) then 
                    RunMacroText("/focus " .. t) 
                    break
                end
            end
        end
        
        if not IsValidTarget("focus") or IsOneUnit("target", "focus") or (not IsArena() and not ActualDistance("focus")) then
            if UnitExists("focus") then RunMacroText("/clearfocus") end
        end
    end

    if IsArena() then
        if IsValidTarget("target") and (not UnitExists("focus") or IsOneUnit("target", "focus")) then
            if IsOneUnit("target","arena1") then RunMacroText("/focus arena2") end
            if IsOneUnit("target","arena2") then RunMacroText("/focus arena1") end
        end
    end
end

------------------------------------------------------------------------------------------------------------------

local _aura, _auraW = {}, {}
local function _sortAura(a1, a2) return _auraW[a1] > _auraW[a2] end

local toggleAuraTime = 0
function TryAura()
    if FastUpdate then return end
    local t = GetTime()

    if IsMounted() and not IsArena() then
        if not HasBuff("Аура воина Света") then return DoSpell("Аура воина Света") end
        toggleAuraTime = t
        return false
    end
    if t - toggleAuraTime < 3 then return false end
    if not HasBuff("Аура") or HasMyBuff("Аура воина Света") then 
        local IsHeal = HasSpell("Шок небес")
        _auraW["Аура благочестия"] = IsPvP() and (IsHeal and 3 or 4) or 5
        _auraW["Аура воздаяния"]  = IsHeal and 2 or 3
        _auraW["Аура сосредоточенности"] = IsHeal and 4 or 1
        _auraW["Аура сопротивления"] = IsHeal and 1 or 2
        wipe(_aura)
        for a, w in pairs(_auraW) do
            tinsert(_aura, a)
        end
        table.sort(_aura, _sortAura)
        for i = 1, #_aura do
            local a = _aura[i]
            if not HasBuff(a) then return DoSpell(a) end
        end
        toggleAuraTime = t
    end
    return false
end
------------------------------------------------------------------------------------------------------------------

local zonalRoot =  {
    "Ледяная ловушка",
    "Оковы земли",
    "Осквернение"
}

local rootDispelList = {
    "Ледяной шок", 
    "Заморозка",
    "Удар грома",
    "Ледяная стрела", 
    "Ночной кошмар",
    "Ледяные оковы",
    "Обморожение",
    "Кольцо льда",
    "Стрела ледяного огня",
    "Холод",
    "Окоченение",
    "Конус холода",
    "Разрушенная преграда",
    "Замедление",
    "Удержание",
    "Гнев деревьев",
    "Обездвиживающее поле",
    "Леденящий взгляд",
    "Хватка земли"
}

local reflectBuff = {"Отражение заклинания", "Эффект тотема заземления"}
local eTime = 0
function HasLight(c)
    if not c then c = 3 end
    if HasBuff("Божественный замысел") then return true end
    if HasSpell("Фанатизм") and IsReadySpell("Фанатизм") and IsBers() then return false end
    return (UnitPower("player", 9) >= c)
end
------------------------------------------------------------------------------------------------------------------
function DispelParty(light, units)
    if nil == units then units = IUNITS end
    -- Диспел пати арены/друзей

    if IsReadySpell("Очищение") and UnitMana100("player") > 35 then
        for i = 1, #units do
            local u = units[i]
            if CanHeal(u) and  InControl(u) and TryDispel(u) then return true end
        end
        if IsAlt() or IsSpellNotUsed("Очищение", light and 5 or 5) then
            for i = 1, #units do
                local u = units[i]
                if CanHeal(u) and TryDispel(u) then return true end
            end
        end
    end
    return false
end
------------------------------------------------------------------------------------------------------------------
function Rotation()

    if CanInterrupt then
        for i=1,#TARGETS do
            if TryInterrupt(TARGETS[i]) then return end
        end
    end

    if IsReadySpell("Очищение") and UnitMana100("player") > 10  and DispelParty(u, true) then return end

    if (IsAttack() or UnitHealth100() > 60) and HasBuff("Длань защиты") then RunMacroText("/cancelaura Длань защиты") end
    if (UnitMana100("player") < 30 or UnitHealth100("player") < 30) and not HasBuff("Печать прозрения") and DoSpell("Печать прозрения") then return end
    if (UnitMana100("player") > 70 and UnitHealth100("player") > 70) then RunMacroText("/cancelaura Печать прозрения") end
    if UnitHealth100("player") > 60 and UnitMana100("player") < 60 and DoSpell("Святая клятва") then return end
    if not FastUpdate and InCombatLockdown() and HasDebuff("") and not InMelee("target") and not IsFinishHim("target") then
        local speed = GetUnitSpeed("player")
        if ((speed > 0 and speed < 7 and not IsFalling()) or HasDebuff(rootDispelList, 0.1, "player"))  then
            if DoSpell("Длань свободы", "player") then return end
            if not HasBuff("Длань свободы") and not HasDebuff(zonalRoot, 0.1, "player") and IsSpellNotUsed("Очищение", 3)  and DoSpell("Очищение", "player") then return end
        end
    end  

    if IsNotAttack("target") then return end
    
    local canMagic = CanMagicAttack("target")
    -- Ротация
    if IsValidTarget("target") then 
        if InMelee() and UseSlot(10) then return end
        if GetBuffStack("Титаническая мощь") > (IsBers() and 3 or 5) then UseEquippedItem("Устройство Каз'горота") end  
        if IsBers() then 
            UseEquippedItem("Жетон победы гладиатора Катаклизма")
            if GetTime() - eTime > 2 then
                eTime = GetTime()
                if UseItem("Зелье из крови голема") then return end
            end
            if DoSpell("Защитник древних королей") then return end
            local last  = GetSpellLastTime("Защитник древних королей")
            if last == 0 and GetSpellCooldownLeft("Защитник древних королей") > 10 then
                last = 10
            end
            if last > 0 and GetTime() - last > 9 and (UnitPower("player", 9) == 3 or HasBuff("Божественный замысел")) and DoSpell("Фанатизм") then return end
            if HasBuff("Фанатизм") and (not IsPvP() or not HasClass(TARGETS, "MAGE")) and DoSpell("Гнев карателя") then return end
            
        end
    end

    if not HasLight() and DoSpell("Удар воина Света") then return end
    if not HasLight() and DoSpell("Правосудие") then return end
    if canMagic and HasBuff("Искусство войны") and DoSpell("Экзорцизм") then return end
    -- кд Торжества - 10 сек в ретри, поэтому тратим частицы, если hp > 50 или (Торжество на кд больше еще больше 5 сек)
    if UnitHealth100("player") > 50 or not IsSpellNotUsed("Торжество", 5) then
        if not IsFinishHim("target") and HasLight(2) and not HasBuff("Дознание") and DoSpell("Дознание") then return end   
        if HasLight() and HasBuff("Дознание", 1) and DoSpell("Вердикт храмовника") then return end
    end

    if canMagic and DoSpell("Молот гнева") then return end
    if IsShift() and UnitMana100() > 65 and DoSpell("Освящение") then return end
    --if HasLight() and InMelee() then return end
    if InMelee() and UnitMana100() > 30 and DoSpell("Гнев небес") then return end
    if not InMelee("target") and not IsFinishHim("target") and UnitMana100("player") > 30 and IsSpellNotUsed("Очищение", 2) and DispelParty() then return end
    if not InMelee("target") and not IsFinishHim("target") and UnitMana100("player") > 50 and TryBuff() then return end
end

------------------------------------------------------------------------------------------------------------------
local forceBuff = {"Настой силы титанов", "Повышенная сила"}
local healBuff = {"Фляга текущей воды", "Настой драконьего разума", "Повышенный интеллект"}
function TryBuff()
    if FastUpdate then return end
    local IsHeal = HasSpell("Шок небес")
    if (IsArena() or IsBattleground()) and not HasBuff("Праведное неистовство") and DoSpell("Праведное неистовство", "player") then return end
    if not IsPvP() and HasBuff("Праведное неистовство") then RunMacroText("/cancelaura Праведное неистовство") end
    if not HasBuff(IsHeal and healBuff or forceBuff) and UseItem("Эликсир улучшения") then return true end
    if IsHeal then
        --if not InCombatLockdown() and not HasBuff("Частица Света", 1 , UNITS) and DoSpell("Частица Света", "player") then return end
        if not HasBuff("Печать прозрения") and DoSpell("Печать прозрения", "player") then return end
        if not HasBuff("Благословение королей") and not HasBuff("Знак дикой природы") then
            if DoSpell("Благословение королей", "player") then return true end
        else
            if not HasMyBuff("Благословение королей") and not HasBuff("Благословение могущества") and DoSpell("Благословение могущества", "player") then return true end
        end
    else
        if not HasBuff("печать") and DoSpell("Печать правды") then return true end
        if not InCombatLockdown() and not HasMyBuff("Благословение королей") and not HasBuff("Благословение могущества") and DoSpell("Благословение могущества", "player") then return true end
    end
    return false
end

------------------------------------------------------------------------------------------------------------------
function TryProtect()
    local hp = UnitHealth100("player")
    local mana = UnitMana100("player")
    if HasBuff("Божественный щит") then Notify("Божественный щит") end
    if hp < (IsArena() and 45 or 25) and DoSpell("Божественный щит", u) then chat("Божественный щит "..round(hp,1).."%") end
    if not (IsArena() or InDuel()) then
        local bg = IsBattleground()
        if bg and (mana < 35 or hp < 45) then 
            if UseItem("Глоток войны", 5) then chat("Глоток войны hp:"..round(hp,1).."%, mana: " ..round(mana,1).."%") end
        end
        if (not bg or GetItemCount("Глоток войны") < 1) then 
            if hp < 35 then UseHealPotion() end
            if mana < 20 then UseItem("Рунический флакон с зельем маны", 5) end
        end
    end
end
------------------------------------------------------------------------------------------------------------------

--local healList = {"player", "Смерчебот", "Ириха", "Омниссия"}
function TrySave()
    --local members = GetHealingMembers(IsArena() and IUNITS or healList)
    local members = GetHealingMembers(IUNITS)
    if #members < 1 then return false end
    local u = members[1]
    local h = UnitHealth100(u)
    local isPlayer = IsOneUnit(u, "player")
    if not isPlayer and h > 60 then 
        u = "player" 
        isPlayer = true
        if not CanHeal(u) then return false end
        h = UnitHealth100(u)
    end

    if isPlayer or not UnitIsPet(u) then
        if h < (isPlayer and 51 or 45) and HasLight() and DoSpell("Торжество", u) then return true end
        if h < (isPlayer and 91 or 75) and DoSpell("Божественная защита", u) then end
        if  UnitAffectingCombat(u) and not (IsArena() or InDuel()) and h < 15 and DoSpell("Возложение рук",u) then  chat("Возложение рук на " .. UnitName(u) .. " " .. round(h,1).."%") return true end
        if PlayerInPlace() and IsCtr() then
            if h < 90 and DoSpell(HasBuff("Воин света") and "Свет небес" or "Божественный свет", u) then return true end
        end
    end
    return false
end

------------------------------------------------------------------------------------------------------------------
local improveTime = 0;
local lightTime = 0;
function HolyRotation()
    local members = GetHealingMembers(UNITS)
    if #members < 1 then return false end
    local u = members[1]
    local h = UnitHealth100(u)
    local l = UnitLostHP(u)
    
    if InCombatLockdown() and h < 40 and PlayerInPlace() then
        DoSpell("Мастер аур")
    end
    
    if h > 40 and CanInterrupt then
        for i=1,#TARGETS do
            if TryInterrupt(TARGETS[i]) then return end
        end
    end

    if DispelParty(true, members) then return end

    if InCombatLockdown()  and #members > 1 and GetTime() - lightTime > 5 then
        local u2 = members[2]
        local h2 = UnitHealth100(u2)
        local l2 = UnitLostHP(u2)
        if not HasBuff("Частица Света",1 , u2) and h2 < (HasBuff("Частица Света",1 , UNITS) and 75 or 95) and DoSpell("Частица Света", u2) then lightTime = GetTime() return end
    end

    if InCombatLockdown() and IsBers() then 
        if DoSpell("Защитник древних королей") then return end
    end
    if InCombatLockdown() and h < 70  then UseSlot(10) end 
    if InCombatLockdown() and not InGCD() and (GetTime() - improveTime > 5) and h < 40 then
        if  UseEquippedItem("Жетон господства гладиатора Катаклизма") then improveTime = GetTime() return end
        if  (not IsPvP() or not HasClass(TARGETS, "MAGE")) and DoSpell("Гнев карателя") then improveTime = GetTime() return end
        if  DoSpell("Божественное одобрение") then improveTime = GetTime() return end
    end

    if InCombatLockdown() and  h > 50 and UnitMana100("player") < 93 then DoSpell("Святая клятва", "player") end

    local p = UnitPower("player", 9)
    if p > 2 and  h < 100 then 
        if DoSpell("Торжество", u) then return end
    end

    if (InCombatLockdown() and not CanMagicAttack("target") or h < 100) and DoSpell("Шок небес", u) then return end

    if h > 30 and IsReadySpell("Очищение") and UnitMana100("player") > 10  then
        for i = 1, #members do
            if IsAlt() or InControl(members[i]) and TryDispel(members[i]) then return end
        end
    end

    local rUnit, rCount = nil, 0
    for i=1,#members do 
        local u, c = members[i], 0
        for j=1,#members do
            local d = CheckDistance(u, members[j])
            if d and d < 10 and UnitLostHP(members[j]) > GetSpellAmount("Святое сияние", 6000) then c = c + 1 end 
        end
        if rUnit == nil or rCount < c then 
            rUnit = u
            rCount = c
        end
    end 
    
    if h < (IsOneUnit("player", u) and 91 or 75) and DoSpell("Божественная защита", u) then return end

    if HasBuff("Прилив света") then
        if PlayerInPlace() then
            if rCount > 1 and DoSpell("Святое сияние",rUnit) then return end
            if (l > GetSpellAmount("Божественный свет", 32000) or h < 20) and DoSpell("Божественный свет", u) then return end

        end
        if (l > GetSpellAmount("Вспышка света", 17000) or h < 30) and DoSpell("Вспышка света") then return end
    end
    
    if (IsAttack() or InCombatLockdown()) and not IsNotAttack("target") then 
        if h > (IsAttack() and 70 or 99) and DoSpell("Шок небес", "target") then return end
        if InMelee() and DoSpell("Удар воина Света", "target") then return end
        if DoSpell("Правосудие", "target") then return end
    end

    if PlayerInPlace() and rCount > 3 and DoSpell("Святое сияние",rUnit) then return end

    if UnitAffectingCombat(u) and not (IsArena() or InDuel()) and (l > (UnitHealthMax("player") * 0.9) or h < 10) and DoSpell("Возложение рук",u) then  chat("Возложение рук на " .. UnitName(u) .. " " .. round(h,1).."%") return end

    if PlayerInPlace() then
        if (l > GetSpellAmount("Божественный свет", 32000) or h < 20) and DoSpell("Божественный свет", u) then return end
        if (l > GetSpellAmount("Вспышка света", 17000) * 2 or h < 30)  and DoSpell("Вспышка света") then return end
    end

    if p > 0 and (l > 5000 * p ) and h < 50 and DoSpell("Торжество", u) then return true end

    if UnitMana100("player") > 30 and DispelParty(false, members) then return end
end

------------------------------------------------------------------------------------------------------------------
local TauntTime = 0
function TryTaunt(target)
 if (GetTime() - TauntTime < 1.5) then return false end

 if not CanAttack(target) then return false end
 if UnitIsPlayer(target) then return false end
 
 local tt = UnitName(target .. "-target")
 if not UnitExists(tt) then return false end
 
 if IsOneUnit("player", tt) then return false end
 -- Снимаем только с игроков, причем только с тех, которые не в черном списке
 local status = false
 for i = 1, #UNITS do
    local u = UNITS[i]
    if not IsOneUnit("player", u) and UnitThreat(u,target) == 3 then 
        status = true 
        break
    end
 end
 if not status then return false end
 
if DoSpell("Длань возмездия", target) then 
     TauntTime = GetTime()
     chat("Длань возмездия на " .. UnitName(target))
     return true  
 end

 if not IsReadySpell("Длань возмездия") and IsInteractUnit(tt) and DoSpell("Праведная защита", tt) then 
     TauntTime = GetTime()
     chat("Праведная защита на " .. UnitName(tt))
     return true  
 end
 return false
end