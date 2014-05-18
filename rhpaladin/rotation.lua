-- Paladin Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local bersTimer = 0
function UseBers()
    bersTimer = GetTime()
end

function IsBers()
    return (GetTime() - bersTimer < 5)
end
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}
function Idle()

    if TryAura() then return end
    if IsAttack() then
        if CanExitVehicle() then VehicleExit() end
        if IsMounted() then Dismount() return end 
    end
    -- дайте поесть (побегать) спокойно 
    if not IsAttack() and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end
    if (InCombatLockdown() or IsShift()) and TrySave() then return end
    
	if IsAttack() or InCombatLockdown() then
        if TryBuff() then return end
        if not InCombatLockdown() and DispelParty() then return end
        TryTarget()        
        Rotation()
        return
    end
end

------------------------------------------------------------------------------------------------------------------
local function IsFinishHim(target) 
    return CanAttack(target) and UnitHealth100(target) < 35 
end
------------------------------------------------------------------------------------------------------------------
function DispelParty()
     -- Диспел пати арены/друзей
    if IsReadySpell("Очищение") then
        for i = 1, #IUNITS do
            local u = IUNITS[i]
            if CanHeal(u) and TryDispel(u) then return true end
        end
    end
    return false
end
------------------------------------------------------------------------------------------------------------------
function ActualDistance(target)
    if target == nil then target = "target" end
    return (CheckInteractDistance(target, 3) == 1)
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
        if not IsValidTarget("focus") then
            if UnitExists("focus") then RunMacroText("/clearfocus") end
            for i = 1, #TARGETS do
                local t = TARGETS[i]
                if UnitAffectingCombat(t) and ActualDistance(t) and not IsOneUnit("target", t) then 
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
local toggleAuraTime = 0
function TryAura()
    local t = GetTime()
    if IsMounted() then
        if not HasBuff("Аура воина Света") then return DoSpell("Аура воина Света") end
        toggleAuraTime = t
        return false
    end
    if t - toggleAuraTime < 10 then return false end
    if not IsAttack() then
        if not HasBuff("Аура") or HasMyBuff("Аура воина Света") then 
            if not HasBuff("Аура благочестия") then return DoSpell("Аура благочестия") end
            if not HasBuff("Аура воздаяния") then return DoSpell("Аура воздаяния") end
            if not HasBuff("Аура сопротивления") then return DoSpell("Аура сопротивления") end
            if not HasBuff("Аура сосредоточенности") then return DoSpell("Аура сосредоточенности") end
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
local steathClass = {"ROGUE", "DRUID"}
function Rotation()

    if IsAttack() then
        if HasBuff("Парашют") then RunMacroText("/cancelaura Парашют") return end
        if CanExitVehicle() then VehicleExit() return end
        if IsMounted() then Dismount() return end 
    else
        if IsMounted() or CanExitVehicle() or HasBuff(peaceBuff) or not InCombatLockdown() or IsPlayerCasting() then return end
    end

    if CanInterrupt then
        for i=1,#TARGETS do
            TryInterrupt(TARGETS[i])
        end
    end

    if (IsAttack() or UnitHealth100() > 60) and HasBuff("Длань защиты") then RunMacroText("/cancelaura Длань защиты") end
    if not IsPvP() and HasBuff("Праведное неистовство") then RunMacroText("/cancelaura Праведное неистовство") end

    if (UnitMana100("player") < 60 or UnitHealth100("player") < 50) and not HasBuff("Печать прозрения") and DoSpell("Печать прозрения") then return end
    if (UnitMana100("player") > 80 and UnitHealth100("player") > 80) then RunMacroText("/cancelaura Печать прозрения") end

    if IsPvP() and IsReadySpell("Изгнание зла") and IsSpellNotUsed("Изгнание зла", 6) then
        for i = 1, #TARGETS do
            local t = TARGETS[i]
            if CanMagicAttack(t) and (UnitCreatureType(t) == "Нежить" or UnitCreatureType(t) == "Демон") 
                and not HasDebuff("Изгнание зла", 0.1, t) and DoSpell("Изгнание зла",t) then return end
        end
    end

    if IsPvP() and IsReadySpell("Длань возмездия") then
        for i = 1, #ITARGETS do
            local t = ITARGETS[i]
            if UnitIsPlayer(t) and tContains(steathClass, GetClass(t)) and not UnitAffectingCombat(t) and DoSpell("Длань возмездия", t) then return end
        end
    end

    if HasDebuff("Темный симулякр", 0.1, "player") and DoSpell("Очищение", "player") then return end
    local speed = GetUnitSpeed("player")
    if ((speed > 0 and speed < 7 and not IsFalling()) or HasDebuff(rootDispelList, 0.1, "player")) and not InMelee("target") and not IsFinishHim("target") then
        if DoSpell("Длань свободы", "player") then return end
        if not HasBuff("Длань свободы") and not HasDebuff(zonalRoot, 0.1, "player") and IsSpellNotUsed("Очищение", 4)  and DoSpell("Очищение", "player") then return end
    end

    if IsNotAttack("target") then return end
    
    local canMagic = CanMagicAttack("target")
    -- Ротация
    if UseSlot(10) then return end
    if GetBuffStack("Титаническая мощь") > (IsBers() and 3 or 4) then UseEquippedItem("Устройство Каз'горота") end  
    if IsBers() then 
        --if UseItem("Зелье из крови голема") then return end
        if DoSpell("Гнев карателя") then return end
        if (UnitPower("player", 9) == 3 or HasBuff("Божественный замысел")) and DoSpell("Фанатизм") then return end
        if DoSpell("Защитник древних королей") then return end
    end
  
    if (UnitPower("player", 9) == 3 or HasBuff("Божественный замысел")) then
        if  not HasBuff("Дознание", 2) and DoSpell("Дознание") then return end
        if DoSpell("Вердикт храмовника") then return end
    end

    if InMelee() and DoSpell("Удар воина Света") then return end
    if canMagic and HasBuff("Искусство войны") and DoSpell("Экзорцизм") then return end
    if canMagic and DoSpell("Молот гнева") then return end
    if IsReadySpell("Молот гнева") then
        for i = 1, #TARGETS do
            local t = TARGETS[i]
            if CanAttack(t) and UnitHealth100(t) < 20 and DoSpell("Молот гнева", t) then return end    
        end
    end

    if canMagic and DoSpell("Правосудие") then return end

    if canMagic and InMelee() and DoSpell("Гнев небес") then return end

    if UnitHealth100("player") > 80 and UnitMana100("player") < 50 and DoSpell("Святая клятва") then return end
    if not IsFinishHim("target") and UnitMana100("player") > 20 and IsSpellNotUsed("Очищение", 6) and DispelParty() then return end
end

------------------------------------------------------------------------------------------------------------------

function TryBuff()
    if not HasBuff("Повышенная сила") and UseItem("Эликсир улучшения") then return true end
    --if IsPvP() and not HasDebuff("Праведное неистовство") and DoSpell("Праведное неистовство") then return true end
    if not HasBuff("печать") and DoSpell("Печать правды") then return true end
    if not InCombatLockdown() and not HasBuff("Благословение могущества") and DoSpell("Благословение могущества", "player") then return true end
    return false
end

------------------------------------------------------------------------------------------------------------------
local healList = {"player", "Смерчебот", "Ириха", "Омниссия"}
function TrySave()
    if not IsArena() and InCombatLockdown() then
        if IsBattleground() and UnitMana100() < 30 or UnitHealth100("player") < 35 and UseItem("Глоток войны", 5) then return true end
        if UnitHealth100("player") < 35 and UseHealPotion() then return true end
        if UnitMana100() < 20 and UseItem("Рунический флакон с зельем маны", 5) then return true end
    end

    local members, membersHP = GetHealingMembers(IsArena() and IUNITS or healList)
    if #members < 1 then return false end
    local u = members[1]
    local h = membersHP[u]
    local isPlayer = IsOneUnit(u, "player")
    if not isPlayer and h > 50 then 
        u = "player" 
        h = membersHP[u]
        if not h then return false end
    end

    if isPlayer or not UnitIsPet(u) then
        local combat = UnitAffectingCombat(u)
        if combat and isPlayer and h < 25 and  DoSpell("Божественный щит") then return true end

        if combat and IsBattleground() and h < 15 and DoSpell("Возложение рук",u) then return true end

        if (not IsValidTarget("target") or not InMelee("target")) and h < 25 and (UnitPower("player", 9) > 0) and DoSpell("Торжество", u) then return true end

        if combat and isPlayer and h < 85 and DoSpell("Божественная защита") then return true end

        if PlayerInPlace() and h < 95 and IsShift() and DoSpell(HasBuff("Воин света") and "Свет небес" or "Вспышка света", u) then return true end

        if h < 65 and UnitMana100("player") > 30 and (UnitPower("player", 9) == 3 or HasBuff("Божественный замысел")) and DoSpell("Торжество", u) then return true end
    end
    return false
end

------------------------------------------------------------------------------------------------------------------
