-- Prist Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local tryMount = 0
SetCommand("mount", 
    function() 
    
        if (not PlayerInPlace() or (GetFalingTime() > 1)) and DoSpell("Реактивный прыжок") then
            chat("Реактивный прыжок")
            tryMount = GetTime()
            return true
        end
    
--        if IsEquippedItemType("Удочка") and DoSpell("Рыбная ловля") then
--            tryMount = GetTime()
--            return true
--        end
        
        if InGCD() or InCombatLockdown() or IsMounted() or CanExitVehicle() or IsPlayerCasting() or not IsOutdoors() or not PlayerInPlace() then
            tryMount = GetTime() 
            return true
        end
        --local mount = (IsShift() or IsBattleground() or IsArena()) and  "Гоблинский турбоцикл" or "Белоснежный грифон" 
        local mount = (IsShift() or IsBattleground() or IsArena()) and  "Гоблинский турботрицикл" or "Синий ветрокрыл" 
        --local mount = "Гоблинский турботрицикл"
        --if IsAlt() then mount = "Тундровый мамонт путешественника" end
        if UseMount(mount) then 
            tryMount = GetTime() 
            return true
        end
    end, 
    function() 

        if tryMount > 0 and GetTime() - tryMount > 0.01 then
            tryMount = 0    
            return  true
        end
        return false 
    end
)
------------------------------------------------------------------------------------------------------------------

SetCommand("fear", 
    function() 
        RunMacroText("/cleartarget")
        RunMacroText("/stopattack")
        local result = DoSpell("Ментальный крик")  
        return  result
    end, 
    function() 
        if not IsReadySpell("Ментальный крик") then 
            RunMacroText("/targetlasttarget")
            return true 
        end
        return false  
    end
)