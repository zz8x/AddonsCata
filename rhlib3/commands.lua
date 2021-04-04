﻿-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local GetTime = GetTime
-- список команд
local Commands = {}
------------------------------------------------------------------------------------------------------------------
-- метод для задания команды, которая имеет приоритет на ротацией
-- SetCommand(string 'произвольное имя', function(...) команда, bool function(...) проверка, что все выполнилось, или выполнение невозможно)
function SetCommand(name, applyFunc, checkFunc, initFunc)
    if not name then
        print('DoCommand: Ошибка! Нет имени комманды')
        return
    end
    if not applyFunc then
        applyFunc = function()
            return true
        end
    end
    if not checkFunc then
        checkFunc = function()
            return true
        end
    end
    if not initFunc then
        initFunc = function()
            return false
        end
    end
    Commands[name] = {Last = 0, Timer = 0, Apply = applyFunc, Check = checkFunc, Init = initFunc, Params == null}
end

------------------------------------------------------------------------------------------------------------------
function ProlongCommand(name, time)
    if Commands[name] then
        Commands[name].Timer = GetTime() + (time or 2)
    end
end

------------------------------------------------------------------------------------------------------------------
function ApplyCommand(cmd, ...)
    if HaveCommand(cmd) and not InUseCommand(cmd) then
        DoCommand(cmd, ...)
        return true
    end
    return false
end

------------------------------------------------------------------------------------------------------------------
function HaveCommand(cmd)
    if not Commands[cmd] then
        return false
    end
    return true
end
------------------------------------------------------------------------------------------------------------------
function InUseCommand(cmd)
    if not Commands[cmd] then
        print('DoCommand: Ошибка! Нет такой комманды ' .. cmd)
        return false
    end
    return ((Commands[cmd].Timer - GetTime()) > 0)
end
------------------------------------------------------------------------------------------------------------------
-- Используется в макросах
-- /run DoCommand('my_command', 'focus')
function DoCommand(cmd, ...)
    --print('cmd: ' .. cmd, ...)
    if not Commands[cmd] then
        print('DoCommand: Ошибка! Нет такой комманды ' .. cmd)
        return
    end
    local time = GetTime()
    local d = 1.55
    local t = time + d
    local spell, left = UnitIsCasting('player')
    if spell and not isSameSpellCommand(spell, cmd, ...) then
        t = time + d + left
        if Commands[cmd].Timer and math.abs(Commands[cmd].Timer - t) < 0.01 then
            RunMacroText('/stopcasting')
            t = time + d
        end
    end
    if Commands[cmd].Init and (Commands[cmd].Timer - time <= 0) and Commands[cmd].Init(...) then
        return
    end
    --print('cmd: ' .. cmd, ...)
    Commands[cmd].Timer = t
    Commands[cmd].Params = {...}
    --print(cmd, spell, t - time)
end

------------------------------------------------------------------------------------------------------------------
local function receiveAddonMessage(type, prefix, message, channel, sender)
    if prefix ~= 'rhlib3' then
        return
    end
    if IsOneUnit(sender, 'player') then
        return
    end
    if UnitIsVisible(sender) and message:match('cmd:') then
        echo(sender .. ': ' .. message)
        chat(sender .. ': ' .. message, 0, 0, 1)
    end
end
AttachEvent('CHAT_MSG_ADDON', receiveAddonMessage)

------------------------------------------------------------------------------------------------------------------
-- навешиваем обработчик с максимальным приоритетом на событие OnUpdate, для обработки вызванных комманд
function UpdateCommands()
    if InCombatMode() and UnitIsCasting('player') then
        return false
    end
    local ret = false
    local time = GetTime()
    for cmd, _ in pairs(Commands) do
        if not ret then
            if (Commands[cmd].Timer - time > 0) then
                ret = true
                if Commands[cmd].Check(unpack(Commands[cmd].Params)) then
                    --print(cmd, 'Check True')
                    Commands[cmd].Timer = 0
                else
                    if GetTime() - Commands[cmd].Last > 0.3 and Commands[cmd].Apply(unpack(Commands[cmd].Params)) then
                        --print(cmd, 'Apply true')
                        Commands[cmd].Last = time
                        local s = ''
                        for i = 1, select('#', unpack(Commands[cmd].Params)) do
                            s = s .. ' ' .. select(i, unpack(Commands[cmd].Params))
                        end
                        chat('CMD:' .. cmd .. s .. '!', 0, 1, 0)
                        SendAddonMessage('rhlib3', 'cmd: ' .. cmd .. s .. '!', 'PARTY')
                    end
                end
            else
                if Commands[cmd].Timer > 0 then
                    --print(cmd, 'Time')
                    Commands[cmd].Timer = 0
                end
            end
        end
    end
    return ret
end

------------------------------------------------------------------------------------------------------------------
function isSameSpellCommand(cast, cmd, spell)
    return cmd == 'spell' and cast == spell
end
-- // /run if IsReadySpell("s") and СanMagicAttack("target") then DoCommand("spell", "s", "target") end
SetCommand(
    'spell',
    function(spell, target)
        if IsCurrentSpell(spell) == 1 then
            --echo("Используем " .. spell, 1)
            return true
        end
        if not IsSpellNotUsed(spell, 1) then
            return true
        end
        if DoSpell(spell, target) then
            echo(spell .. '!', 1)
            return true
        end
        return false
    end,
    function(spell, target)
        if not HasSpell(spell) then
            chat(spell .. ' - нет спела!')
            return true
        end
        if target and not InRange(spell, target) then
            chat(spell .. ' - неверная дистанция!')
            return true
        end
        if not IsSpellNotUsed(spell, 1) then
            chat(spell .. ' - успешно сработало!')
            return true
        end
        if not IsReadySpell(spell) then
            chat(spell .. ' - не готово!')
            return true
        end
        if IsCurrentSpell(spell) == 1 then
            echo('Используем ' .. spell, 1)
            return true
        end
        local cast = UnitIsCasting('player')
        if spell == cast then
            chat('Кастуем ' .. spell)
            return true
        end
        return false
    end
)
------------------------------------------------------------------------------------------------------------------
local function hookUseAction(slot, ...)
    local actiontype, id, subtype = GetActionInfo(slot)
    if actiontype and id and id ~= 0 then
        local name = nil
        if actiontype == 'spell' then
            name = GetSpellInfo(id)
            DoCommand('spell', name)
        elseif actiontype == 'item' then
            name = GetItemInfo(id)
        elseif actiontype == 'companion' then
            name = select(2, GetCompanionInfo(subtype, id))
        elseif actiontype == 'macro' then
            name = GetMacroInfo(id)
            if Commands[name] then
                DoCommand(name)
            end
        end
    --if name then print("UseAction", slot, name, actiontype, ...) end
    end
end
hooksecurefunc('UseAction', hookUseAction)
------------------------------------------------------------------------------------------------------------------
