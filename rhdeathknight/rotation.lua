-- DK Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}
local stanceBuff = {"Власть крови", "Власть льда", "Власть нечестивости"}
local steathClass = {"ROGUE", "DRUID"}
local reflectBuff = {"Отражение заклинания", "Эффект тотема заземления", "Рунический покров"}
local UndeadFearClass = {"PALADIN", "PRIEST"}
local advansedTime = 0
function Idle()

    local advansedMod = false
    if GetTime() - advansedTime > 1 then
        advansedTime = GetTime()
        advansedMod = true
    end
    
    if (IsAttack() or UnitHealth100() > 60) and HasBuff("Длань защиты") then RunMacroText("/cancelaura Длань защиты") end

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
        
    if advansedMod then
        if IsPvP() and HasClass(TARGETS, UndeadFearClass) and not HasBuff("Антимагический панцирь") and HasBuff("Перерождение") and not HasBuff("Перерождение", 8) then RunMacroText("/cancelaura Перерождение") end    
        
        if not HasBuff(stanceBuff) and DoSpell("Власть нечестивости") then return end
        
        if IsPvP() and IsReadySpell("Темная власть") then
            for i = 1, #ITARGETS do
                local t = ITARGETS[i]
                if UnitIsPlayer(t) and ((tContains(steathClass, GetClass(t)) and not InRange("Ледяные оковы", t)) or HasBuff(reflectBuff, 1, t)) and not HasDebuff("Темная власть", 1, t) and DoSpell("Темная власть", t) then return end
            end
        end
    end    

    if TryHealing() then return end
    
    if TryProtect() then return end

    if IsAttack() and not IsValidTarget("target") then 
        if DoSpell("Зимний горн") then return end
        if HasSpell("Костяной щит") and not HasBuff("Костяной щит") and DoSpell("Костяной щит") then return end
    end

    TryTarget(CanAOE)

    if not (IsValidTarget("target") and CanAttack("target") and (UnitAffectingCombat("target")  or IsAttack()))  then return end

    RunMacroText("/startattack")

    if IsMouse3() and TryTaunt("mouseover") then return end

    if advansedMod and not IsPvP() and HasBuff("Власть крови") and InGroup() and InCombat(3) and (IsReadySpell("Темная власть") or IsReadySpell("Хватка смерти")) then
        for i = 1, #TARGETS do
            local t = TARGETS[i]
            if UnitAffectingCombat(t) and TryTaunt(t) then return end
        end
    end

    if HasSpell("Воющий ветер") then
        frostRotation()
    end

    if HasSpell("Танцующее руническое оружие") then
        bloodRotation()
    end
end

------------------------------------------------------------------------------------------------------------------
function bloodRotation()
    local canMagic = CanMagicAttack("target")
    local canMagicFocus = IsValidTarget("focus") and CanMagicAttack("focus")
    local rp = UnitMana("player")

    -- войти в бой
    if IsPvP() and UnitIsPlayer("target") and not InCombatLockdown() and not InMelee() and IsReadySpell("Темная власть") then DoSpell("Темная власть", "target") end

     -- разносим болезни на всех
    if IsAOE() and DoSpell("Мор") then return end
    
    if IsCtr() or (IsPvP() and InMelee()) then
        UseEquippedItem("Жетон победы беспощадного гладиатора")
        if DoSpell("Танцующее руническое оружие") then return end
    end

    if DoSpell("Рунический удар", "target", 90) then return end

    if canMagic then
        if DoSpell("Лик смерти", "target", 80) then return end
    else
        if canMagicFocus and DoSpell("Лик смерти", "focus", 80) then return end
    end

    if rp > 120 then return end
    if (rp < 20 or not HasBuff("Зимний горн")) and DoSpell("Зимний горн") then return end

    -- ресаем руну крови
    if not HasRunes(100) and DoSpell("Кровоотвод") then return end
    -- ресаем все.
    if not HasRunes(111) and DoSpell("Усиление рунического оружия") then return end

    if not HasBuff("Костяной щит") and DoSpell("Костяной щит") then return end

    -- накладываем болезни
    if not Dotes(3) and DoSpell("Вспышка болезни") then return end    
    if not HasMyDebuff("Кровавая чума", 3, "target") and DoSpell("Удар чумы") then return end
    if not HasMyDebuff("Озноб", 3, "target") and DoSpell(IsPvP() and "Ледяные оковы" or "Ледяное прикосновение") then return end

    -- собственно ротация

    if IsPvP() and not HasDebuff("Некротический удар") and DoSpell("Некротический удар") then return end
    if Dotes() and DoSpell("Удар смерти") then return end
    if DoSpell("Удар в сердце") then return end

    if (UnitMana("player") < 80 or not HasBuff("Зимний горн")) and DoSpell("Зимний горн") then return end
    if IsAttack() and not InMelee() and DoSpell(IsPvP() and "Ледяные оковы" or "Ледяное прикосновение") then return end
end

------------------------------------------------------------------------------------------------------------------
function frostRotation()
    local baseRP = 20
    local canMagic = CanMagicAttack("target")
    local canMagicFocus = IsValidTarget("focus") and CanMagicAttack("focus")

    local frostSpell = CanAOE and "Воющий ветер" or "Ледяное прикосновение"

    if IsCtr() or (IsPvP() and InMelee()) then
        UseEquippedItem("Жетон победы беспощадного гладиатора")
        if DoSpell("Ледяной столп") then return end
    end

    -- мега прок
    if HasBuff("Машина для убийств") then
        if canMagic or canMagicFocus then
            if canMagic then
                if DoSpell("Ледяной удар", "target") then return end
            else
                if canMagicFocus and DoSpell("Ледяной удар", "focus") then return end
            end
            if InMelee() and UnitMana("player") > 31 then return end
        else
            if Dotes() and DoSpell("Уничтожение") then return end
        end
    end

    if Dotes() and (UnitHealth100("player") < (IsAttack() and 35 or 85)) and DoSpell("Удар смерти") then return end 

    if not canMagic and InMelee() and DoSpell("Рунический удар") then return end

    -- чтоб зря не пропадало
    if UnitMana("player") > 80 then
        if canMagic then
            if DoSpell(InMelee() and "Ледяной удар" or "Лик смерти") then return end
        else
            if canMagicFocus and DoSpell(InMelee("focus") and "Ледяной удар" or "Лик смерти", "focus") then return end
        end
    end

    -- ресаем руну крови
    if not HasRunes(100) and DoSpell("Кровоотвод") then return end
    -- ресаем все.
    if not HasRunes(010) and DoSpell("Усиление рунического оружия") then return end

    -- разносим болезни на всех
    if CanAOE and Dotes() and IsValidTarget("focus") and not Dotes(1, "focus") and DoSpell("Мор") then return end

    -- накладываем болезни
    if not Dotes(2) and DoSpell("Вспышка болезни") then return end 
    --if (0 == GetDotesTime("target")) and DoSpell("Вспышка болезни") then return end
    
    if not HasMyDebuff("Кровавая чума", 3, "target") and DoSpell("Удар чумы") then return end

    -- собственно ротация
    if canMagic then
        if DoSpell(frostSpell) then return end
    else
        if canMagicFocus and DoSpell(frostSpell, "focus") then return end
    end

    if HasRunes(002, true) and DoSpell(IsPvP() and "Некротический удар" or "Удар чумы") then return end

    if canMagic then
     if not InMelee() and DoSpell("Лик смерти", "target", baseRP) then return end
    else
        if canMagicFocus and not InMelee("focus") and DoSpell("Лик смерти", "focus", baseRP) then return end
    end

    if (UnitMana("player") < 80 or not HasBuff("Зимний горн")) and DoSpell("Зимний горн") then return end
    
end

------------------------------------------------------------------------------------------------------------------
local TauntTime = 0
function TryTaunt(target)
    if not CanAttack(target) then return false end
    if UnitThreat("player",target) == 3 then return false end
    if (GetTime() - TauntTime < 1.5) then return false end
    local tt = UnitName(target .. "-target")
    if not IsMouse3() and (UnitIsPlayer(target) or not UnitExists(tt) or IsOneUnit("player", tt)) then return false end
    if DoSpell("Темная власть", target) then 
        TauntTime = GetTime()
            chat("Темная власть на " .. target)
        return true  
    end
    if DoSpell("Хватка смерти", target) then 
        TauntTime = GetTime()
            chat("Хватка смерти на " .. target)
        return true  
    end
    return false
end

------------------------------------------------------------------------------------------------------------------
function TryHealing()
    TryDeathPact()
    local h = UnitHealth100("player")
    if h < 55 and HasSpell("Кровь вампира") and DoSpell("Кровь вампира") then return end
    if h < 80 and HasSpell("Захват рун") and DoSpell("Захват рун") then return end
    --if h < 80 and HasSpell("Кровь земли") and DoSpell("Кровь земли") then return end
    if HasBuff("Перерождение") and UnitHealth100("player") < 100 and DoSpell("Лик смерти", "player") then return end
    if InCombatLockdown() then
        if h < 30 and not IsArena() and UseHealPotion() then return true end
        if (not IsPvP() or not HasClass(TARGETS, UndeadFearClass) or HasBuff("Антимагический панцирь")) and HasSpell("Перерождение") and IsReadySpell("Перерождение") and h < 60 and UnitMana("player") >= 40 and DoSpell("Перерождение") then 
            return DoSpell("Лик смерти", "player") 
        end
    end
    if h < 45 and InMelee() and (HasMyDebuff("Озноб") or HasMyDebuff("Кровавая чума")) and DoSpell("Удар смерти") then return true end
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
                RunMacroText("/startattack [@" .. target .. "]") 
                break
            end
        end
    end
    -- пытаемся выбрать ну хоть что нибудь
    if not IsValidTarget("target") then
        -- если что-то не то есть в цели
        if UnitExists("target") then RunMacroText("/cleartarget") end

        if IsPvP() then
            RunMacroText("/targetenemyplayer [nodead]")
        else
            RunMacroText("/targetenemy [nodead]")
        end
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

local physDebuff = {
    "Poison"
}
local magicBuff = {
    "Стылая кровь",
    "Героизм",
    "Жажда крови"

}
local magicDebuff = {
    "Призыв горгульи"
}
local checkedTargets = TARGETS
function TryProtect()

    local defPhys = false;
    local defMagic = false;

    if InCombatLockdown() and (IsValidTarget("target") or IsValidTarget("focus")) then
        for i=1,#checkedTargets do
            local t = checkedTargets[i]
            if defPhys and defMagic then break end
            if IsValidTarget(t) then
                if IsOneUnit("player", t .. "-target") then
                    if HasBuff("Гнев карателя", 4, t) and InRange("Ледяные оковы", t) then
                        echo("Гнев карателя!", true)
                        defPhys = true
                        defMagic = true;
                    end
                    if HasDebuff(magicDebuff, 4, "player") or HasBuff(magicBuff, 4, t) then
                        echo("Магия!", true)
                        defMagic = true;
                    end
                    if HasDebuff(physDebuff, 4, "player") then
                        echo("Яды!", true)
                        defPhys = true;
                    end
                end

            end
        end
        if defPhys then 
            DoSpell("Незыблемость льда")
        end
        if defMagic then 
            if DoSpell("Антимагический панцирь") then return true end
        end
    end
    return false;
end
------------------------------------------------------------------------------------------------------------------
function Dotes(t, target)
    if target == nil then target = "target" end
    if t == nil then t = 0.2 end
    return GetDotesTime(target) > t
end

------------------------------------------------------------------------------------------------------------------
function GetDotesTime(target)
    if target == nil then target = "target" end
    return min(GetMyDebuffTime("Озноб", target),GetMyDebuffTime("Кровавая чума", target))
end
------------------------------------------------------------------------------------------------------------------
function HasRunes(runes, strong, time)
    local r = floor(runes / 100)
    local b = floor((runes - r * 100) / 10)
    local g = floor(runes - r * 100 - b * 10)
    local a = 0
    for i = 1, 6 do
        if IsRuneReady(i, time) then
            local t = select(1,GetRuneType(i))
            if t == 1 then r = r - 1 end
            if t == 2 then g = g - 1 end
            if t == 3 then b = b - 1 end
            if t == 4 then a = a + 1 end
        end
    end

    if r < 0 then r = 0 end
    if g < 0 then g = 0 end
    if b < 0 then b = 0 end
    if strong then a = 0 end
    if r + g + b - a <= 0 then return true end
    return false;
end

------------------------------------------------------------------------------------------------------------------
