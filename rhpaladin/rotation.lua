-- Paladin Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}
function Idle()
    if IsAttack() then
        if CanExitVehicle() then VehicleExit() end
        if IsMounted() then Dismount() return end 
    end
    -- дайте поесть (побегать) спокойно 
    if not IsAttack() and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end
    -- чтоб контроли не сбивать
    if not CanControl("target") then RunMacroText("/stopattack") end
	if IsAttack() or InCombatLockdown() then
        TryTarget()
        TryBuff()
        TrySave()
        Rotation()
        return
    end
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
                RunMacroText("/startattack [@" .. target .. "][nostealth]") 
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

function Rotation()
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
    -- Ротация
    if IsCtr() and DoSpell("Гнев карателя") then return end
    if IsCtr() and (UnitPower("player", 9) == 3 or HasBuff("Божественный замысел")) and DoSpell("Фанатизм") then return end
    if IsCtr() and DoSpell("Защитник древних королей") then return end
    if GetBuffStack("Титаническая мощь") > 4 then UseEquippedItem("Устройство Каз'горота") end   
    if (UnitPower("player", 9) == 3 or HasBuff("Божественный замысел")) and not HasBuff("Дознание", 2) and DoSpell("Дознание") then return end
    if (UnitPower("player", 9) == 3 or HasBuff("Божественный замысел")) and DoSpell("Вердикт храмовника") then return end
    if InMelee() and DoSpell("Удар воина Света") then return end
    if HasBuff("Искусство войны") and DoSpell("Экзорцизм") then return end
    if DoSpell("Молот гнева") then return end
    if DoSpell("Правосудие") then return end
    if InMelee() and DoSpell("Гнев небес") then return end
end

------------------------------------------------------------------------------------------------------------------

function TryBuff()
    if not HasBuff("печать") and DoSpell("Печать правды") then return end
    if not InCombatLockdown() and not HasBuff("Благословение могущества") and DoSpell("Благословение могущества", "player") then return end
end

------------------------------------------------------------------------------------------------------------------

function TrySave()
    local h = UnitHealth100("player")
    if h < 80 and DoSpell("Божественная защита") then return true end
    if h < 60 and (UnitPower("player", 9) == 3 or HasBuff("Божественный замысел")) and DoSpell("Торжество", "player") then return true end
    if h < 10 and  DoSpell("Божественная щит") then return true end
end