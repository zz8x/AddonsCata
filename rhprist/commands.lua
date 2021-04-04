-- Prist Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
SetCommand(
    'fear',
    function()
        -- apply (true if success)
        return DoSpell('Ментальный крик')
    end,
    function()
        -- check (true if command done)
        if not IsReadySpell('Ментальный крик') then
            RunMacroText('/targetlasttarget')
            return true
        end
        return false
    end,
    function()
        -- init (true if need stop cmd)
        if not IsReadySpell('Ментальный крик') then
            return true
        end
        RunMacroText('/cleartarget')
        RunMacroText('/stopattack')
        return false
    end
)

local stackCount = 0
SetCommand(
    'finish',
    function()
        -- apply (true if success)
        if not IsValidTarget('target') then
            return true
        end
        if stackCount < 2 then
            if DoSpell('Пронзание разума', 'target') then
                stackCount = stackCount + 1
            end
            ProlongCommand('finish')
            return true
        end
        if DoSpell('Взрыв разума', 'target') then
            stackCount = -1
            return true
        end
        return false
    end,
    function()
        -- check (true if command done)
        if not IsValidTarget('target') then
            return true
        end
        if stackCount == -1 then
            return true
        end
        return false
    end,
    function()
        -- init (true if need stop cmd)
        if not IsValidTarget('target') then
            return true
        end
        stackCount = GetDebuffStack('Пронзание разума', 'target')
        if GetSpellCooldownLeft('Взрыв разума') > GCDDuration * math.max(0, 2 - stackCount) then
            return true
        end
        return false
    end
)
