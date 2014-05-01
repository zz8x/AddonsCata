-- DK Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}
local stanceBuff = {"Власть крови", "Власть льда", "Власть нечестивости"}
local steathClass = {"ROGUE", "DRUID"}
local reflectBuff = {"Отражение заклинания", "Эффект тотема заземления", "Рунический покров"}
local UndeadFearClass = {"PALADIN", "PRIEST"}
local advansedTime = 0
local advansedMod = false
local useBers = false
function Idle()
    advansedMod = false
    if GetTime() - advansedTime > 1 then
        advansedTime = GetTime()
        advansedMod = true
    end

    if advansedMod then
        if useBers and NotInCombat(3) then
            chat("Бурсты отключены")
            useBers = false
        end

        if not useBers and InCombatLockdown() and IsCtr() then
            chat("Подключаем бурсты по кд")
            useBers = true;
        end
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
        
     -- призыв пета (анхолик)
    if HasSpell("Призыв горгульи") and not HasSpell("Цапнуть") and DoSpell("Воскрешение мертвых") then 
        return true 
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
    if HasSpell("Призыв горгульи") then
        if advansedMod and HasSpell("Отгрызть") then
            petRotation()
        end
        unholyRotation()
        return
    end
    if HasSpell("Воющий ветер") then
        frostRotation()
        return
    end

    if HasSpell("Танцующее руническое оружие") then
        bloodRotation()
        return
    end
end

------------------------------------------------------------------------------------------------------------------
local totems = { "Тотем оков земли", "Тотем прилива маны", "Тотем заземления", "Тотем очищения", "Тотем источника маны VIII" }
function petRotation()
    if UnitExists("mouseover") and tContains(totems, UnitName("mouseover"))  then
        RunMacroText("/petattack mouseover")
    end
    if not IsValidTarget("pet-target") or IsAttack() then
        RunMacroText("/petattack " .. ((IsValidTarget("focus") and IsAltKeyDown() == 1) and "[@focus]" or "[@target]"))
    end
    local mana = UnitMana("pet")
    if mana >= (IsAttack() and 40 or 70) then RunMacroText("/cast [@pet-target] Цапнуть") end
end

------------------------------------------------------------------------------------------------------------------
function unholyRotation()
    
    local canMagic = CanMagicAttack("target")
    -- войти в бой
    if IsPvP() and UnitIsPlayer("target") and not UnitAffectingCombat("target") and not InMelee() and IsReadySpell("Темная власть") then DoSpell("Темная власть", "target") end
     -- разносим болезни на всех
    if CanAOE and Dotes() and IsValidTarget("focus") and not Dotes(1, "focus") and DoSpell("Мор") then return end
     -- разносим болезни на всех
    if IsShift() and DoSpell("Вскипание крови") then return end

    local baseRP = (HasSpell("Призыв горгульи") and IsReadySpell("Призыв горгульи")) and 60 or 40

    if GetBuffStack("Титаническая мощь") > 4 then UseEquippedItem("Устройство Каз'горота") end

    if useBers then
        UseSlot(10)
        UseEquippedItem("Жетон победы беспощадного гладиатора")
        if IsCtr() then UseEquippedItem("Устройство Каз'горота") end
        if DoSpell("Нечестивое бешенство") then return end
        -- гарга по контролу
        if UnitMana("player") >= 60 and IsReadySpell("Призыв горгульи") then
            if advansedMod then
                RunMacroText("/cleartarget")
                RunMacroText("/targetlasttarget")
            end
            chat("Призываем гаргу")
            if DoSpell("Призыв горгульи") then return end
        end
    end
    if HasSpell("Цапнуть") and GetBuffStack("Вливание тьмы", "pet") > 4 and DoSpell("Темное превращение") then return end
    if HasBuff("Неумолимый рок") then
        if canMagic then
            if DoSpell("Лик смерти") then return end
        else
            if CanHeal("pet") and UnitHealth100("pet") < 100 and DoSpell("Лик смерти", "pet") then return end
        end
    end
    if UnitMana("player") > 80 then
        if canMagic then
            if DoSpell("Лик смерти") then return end
        else
            DoSpell("Рунический удар") 
        end
    end
    if (UnitMana("player") < 20 or not HasBuff("Зимний горн")) and DoSpell("Зимний горн") then return end
    -- ресаем руну крови
    if not HasRunes(100) and DoSpell("Кровоотвод") then return end
    -- ресаем все.
    if not HasRunes(111) and DoSpell("Усиление рунического оружия") then return end
     -- накладываем болезни
    local frostSpell = (IsPvP() and not HasDebuff("Ледяные оковы", 5) and "Ледяные оковы" or "Ледяное прикосновение")
    if InCombatLockdown() and useBers and not Dotes(3) and DoSpell("Вспышка болезни") then return end    
    if IsPvP() and (not HasMyDebuff("Кровавая чума", 3) or not HasDebuff("Осквернение")) and DoSpell("Удар чумы") then return end
    if not HasMyDebuff("Озноб", 3) and DoSpell(frostSpell) then return end
    if Dotes(1) and HasRunes(010, true) and DoSpell("Удар разложения") then return end  
    -- собственно ротация
    if Dotes() and UnitHealth100("player") > 75 and DoSpell("Удар смерти") then return end 
    if IsPvP() and (HasRunes(001, true) or (UnitHealth100("target") < 45 and not IsAttack())) and DoSpell("Некротический удар") then return end
    if Dotes() and DoSpell("Удар Плети") then return end
    if HasRunes(100, true) and DoSpell("Кровавый удар") then return end
    if not InMelee() and DoSpell(frostSpell) then return end
    if (UnitMana("player") < 120 or not HasBuff("Зимний горн")) and DoSpell("Зимний горн") then return end
end
------------------------------------------------------------------------------------------------------------------
function bloodRotation()
    local canMagic = CanMagicAttack("target")
    local canMagicFocus = IsValidTarget("focus") and CanMagicAttack("focus")
    local rp = UnitMana("player")

    -- войти в бой
    if IsPvP() and UnitIsPlayer("target") and not InCombatLockdown() and not InMelee() and IsReadySpell("Темная власть") then DoSpell("Темная власть", "target") end
     -- разносим болезни на всех
    if CanAOE and Dotes() and IsValidTarget("focus") and not Dotes(1, "focus") and DoSpell("Мор") then return end
     -- разносим болезни на всех
    if IsShift() and DoSpell("Вскипание крови") then return end

    if GetBuffStack("Титаническая мощь") > 4 then UseEquippedItem("Устройство Каз'горота") end
    if useBers then
        UseSlot(10)
        UseEquippedItem("Жетон победы беспощадного гладиатора")
        if DoSpell("Танцующее руническое оружие") then return end
    end

    if DoSpell("Рунический удар", "target", 80) then return end

    if canMagic then
        if DoSpell("Лик смерти", "target", 80) then return end
    else
        if canMagicFocus and DoSpell("Лик смерти", "focus", 80) then return end
    end

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
    local frostSpell = CanAOE and "Воющий ветер" or "Ледяное прикосновение"
    if GetBuffStack("Титаническая мощь") > 4 then UseEquippedItem("Устройство Каз'горота") end
    if useBers then
        UseSlot(10)
        UseEquippedItem("Жетон победы беспощадного гладиатора")
        if DoSpell("Ледяной столп") then return end
    end
    -- ресаем руну крови
    if not HasRunes(100) and DoSpell("Кровоотвод") then return end
    -- ресаем все.
    if not HasRunes(010) and DoSpell("Усиление рунического оружия") then return end
    -- мега прок
    if HasBuff("Морозная дымка") and DoSpell(frostSpell) then return end
    if HasBuff("Машина для убийств") then
        if canMagic and UnitMana("player") > 90 and  DoSpell("Ледяной удар") then return end
        if Dotes() and DoSpell("Уничтожение") then return end
        
    end
    if not canMagic and DoSpell("Рунический удар") then return end
    -- чтоб зря не пропадало
    if canMagic and UnitMana("player") > 75 and DoSpell(InMelee() and "Ледяной удар" or "Лик смерти") then return end     
    -- разносим болезни на всех
    if CanAOE and Dotes() and IsValidTarget("focus") and not Dotes(1, "focus") and DoSpell("Мор") then return end
    -- накладываем болезни
    if InCombatLockdown() and useBers and not Dotes(2) and DoSpell("Вспышка болезни") then return end 
    if not HasMyDebuff("Кровавая чума", 3, "target") and DoSpell("Удар чумы") then return end
    if not HasMyDebuff("Озноб", 3, "target") and DoSpell(frostSpell) then return end
    if IsPvP() and (not HasMyDebuff("Кровавая чума", 3) or not HasDebuff("Осквернение")) and DoSpell("Удар чумы") then return end
    if IsPvP() and (HasRunes(001, true) or (UnitHealth100("target") < 45 and not IsAttack())) and DoSpell("Некротический удар") then return end
    if IsShift() and DoSpell("Воющий ветер") then return end
    if Dotes() and DoSpell(UnitHealth100("player") > (IsAttack() and 45 or 75) and "Уничтожение" or "Удар смерти") then return end 
    -- собственно ротация
    if canMagic and DoSpell(frostSpell) then return end
    if canMagic and not InMelee() and DoSpell("Лик смерти", "target", baseRP) then return end
    if (UnitMana("player") < 120 or not HasBuff("Зимний горн")) and DoSpell("Зимний горн") then return end
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
    if h < 90 and UseEquippedItem("Весы жизни") then return true end
    if h < 68 and HasSpell("Кровь вампира") and DoSpell("Кровь вампира") then return true end
    if h < 71 and HasSpell("Захват рун") and DoSpell("Захват рун") then return true end
    --if h < 80 and HasSpell("Кровь земли") and DoSpell("Кровь земли") then return true end
    if HasBuff("Перерождение") and UnitHealth100("player") < 100 and DoSpell("Лик смерти", "player") then return true end
    if InCombatLockdown() then
        if h < 30 and not IsArena() and UseHealPotion() then return true end
        if (not IsPvP() or not HasClass(TARGETS, UndeadFearClass) or HasBuff("Антимагический панцирь")) and HasSpell("Перерождение") and IsReadySpell("Перерождение") and h < 40 and UnitMana("player") >= 40 and DoSpell("Перерождение") then 
            return DoSpell("Лик смерти", "player") 
        end
    end
    if h < 45 and (HasMyDebuff("Озноб") or HasMyDebuff("Кровавая чума")) and DoSpell("Удар смерти") then return true end
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
