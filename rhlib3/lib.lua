-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- protected lock test
RunMacroText('/cleartarget')
-- Инициализация скрытого фрейма для обработки событий
local frame = CreateFrame('Frame', 'RHLIB2FRAME', UIParent)

------------------------------------------------------------------------------------------------------------------
-- Список событие -> обработчики
local EventList = {}
function AttachEvent(event, func)
    if nil == func then
        error("Func can't be nil")
    end
    local funcList = EventList[event]
    if nil == funcList then
        funcList = {}
        -- attach events
        frame:RegisterEvent(event)
    end
    tinsert(funcList, func)
    EventList[event] = funcList
end

------------------------------------------------------------------------------------------------------------------
-- Выполняем обработчики соответсвующего события
local function onEvent(self, event, ...)
    if EventList[event] ~= nil then
        local funcList = EventList[event]
        for i = 1, #funcList do
            funcList[i](event, ...)
        end
    end
end
frame:SetScript('OnEvent', onEvent)

------------------------------------------------------------------------------------------------------------------
local UpdateList = {}
function AttachUpdate(f, i)
    if nil == f then
        error("Func can't be nil")
    end
    if i == nil then
        i = 1
    end -- одна секунда по умолчанию
    tinsert(UpdateList, {func = f, interval = i, update = 0})
end

------------------------------------------------------------------------------------------------------------------
-- Выполняем обработчики события OnUpdate
local function OnUpdate(frame, elapsed)
    for i = 1, #UpdateList do
        local u = UpdateList[i]
        u.update = u.update + elapsed
        if u.update > u.interval then
            u.func(u.update)
            u.update = 0
        end
    end
end
frame:SetScript('OnUpdate', OnUpdate)
