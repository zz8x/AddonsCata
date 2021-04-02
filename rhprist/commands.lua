-- Prist Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
SetCommand("fear", 
    function() -- apply (true if success)
        return DoSpell("Ментальный крик")  
    end, 
    function() -- check (true if command done)
        if not IsReadySpell("Ментальный крик") then 
            RunMacroText("/targetlasttarget")
            return true 
        end
        return false  
    end,
    function() -- init (true if need stop cmd)
        if not IsReadySpell("Ментальный крик") then 
            return true 
        end
        RunMacroText("/cleartarget")
        RunMacroText("/stopattack")
        return false  
    end
)