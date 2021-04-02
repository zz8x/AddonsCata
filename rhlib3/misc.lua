-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
--UIParentLoadAddOn("Blizzard_DebugTools");
--DevTools_Dump(n)

--[[
/run UIParentLoadAddOn("Blizzard_DebugTools");
/fstack true
/etrace 
]]
------------------------------------------------------------------------------------------------------------------
function RegBG()
    RunMacroText([[
/click PVPMicroButton
/click PVPHonorFrameBgButton3
/script JoinBattlefield(1, InGroup())
]])
end
-------------------------------------------------------------------------------------------------------------------
-- Автоматическая продажа хлама и починка
local money = 0
OpenMerchant = false
local function SellGrayAndRepair()
    OpenMerchant = true
    money = GetMoney()
    TimerStart('Sell')
    if CanMerchantRepair() then
        RepairAllItems(1) -- сперва пробуем за счет ги банка
        RepairAllItems()
    end
    SellGray()
end
AttachEvent('MERCHANT_SHOW', SellGrayAndRepair)
local function StopSell()
    local m = GetMoney() - money
    if not (math.abs(m) < 1) then
        m = (m > 0 and '+' or '-') .. GetCoinTextureString(math.abs(m))
        chat(('Итого: %s, за %s'):format(m, SecondsToTime(TimerElapsed('Sell'))), 1, 1, 1)
    end
    OpenMerchant = false
    DelGray() -- удаляем то, что не смогли продать
end
AttachEvent('MERCHANT_CLOSED', StopSell)
------------------------------------------------------------------------------------------------------------------
-- Автоматическая покупка предметов
local function autoBuy(name, count)
    local c = count - countItem(name)
    if c > 0 then
        buy(name, c)
    end
end
-----------------------------------------------------------------------------------------------------------------
function GetMinEquippedItemLevel()
    local minItemLevel = nil
    for i = 1, 18 do
        local itemID = GetInventoryItemID('player', i)
        if itemID then
            local name, _, _, itemLevel, _, itemType, itemSubType = GetItemInfo(itemID)
            --print(name, itemLevel, itemType, itemSubType)
            if itemType == 'Доспехи' and itemSubType ~= 'Разное' and (not minItemLevel or (itemLevel < minItemLevel)) then
                minItemLevel = itemLevel
            end
        end
    end
    return minItemLevel
end
-----------------------------------------------------------------------------------------------------------------
function SellGray()
    for b = 0, 4 do
        for s = 1, GetContainerNumSlots(b) do
            local n = GetContainerItemLink(b, s)
            if n then
                if string.find(n, 'ff9d9d9d') or (IsGray and IsGray(n)) then
                    UseContainerItem(b, s)
                end
            end
        end
    end
end

------------------------------------------------------------------------------------------------------------------
function DelGray()
    ClearCursor()
    for b = 0, 4 do
        for s = 1, GetContainerNumSlots(b) do
            local n = GetContainerItemLink(b, s)
            if n then
                if string.find(n, 'ff9d9d9d') or (IsTrash and IsTrash(n)) then
                    PickupContainerItem(b, s)
                    DeleteCursorItem()
                end
            end
        end
    end
end
------------------------------------------------------------------------------------------------------------------
function buy(name, q)
    if q < 1 then
        return
    end
    local c = 0
    for bag = 0, NUM_BAG_SLOTS do
        local numberOfFreeSlots = GetContainerNumFreeSlots(bag)
        if numberOfFreeSlots then
            c = c + numberOfFreeSlots
        end
    end
    if c < 1 then
        return
    end
    if q == nil then
        q = 255
    end
    for i = 1, 100 do
        if name == GetMerchantItemInfo(i) then
            local s = c * GetMerchantItemMaxStack(i)
            if q > s then
                q = s
            end
            BuyMerchantItem(i, q)
            break
        end
    end
end

------------------------------------------------------------------------------------------------------------------
function sell(name)
    if not name then
        name = ''
    end
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            local item = GetContainerItemLink(bag, slot)
            if item and string.find(item, name) then
                UseContainerItem(bag, slot)
            end
        end
    end
end

------------------------------------------------------------------------------------------------------------------
function countItem(name)
    local count = 0
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            local item = GetContainerItemLink(bag, slot)
            if item and string.find(item, name) then
                count = count + (select(2, GetContainerItemInfo(bag, slot)))
            end
        end
    end
    return count
end
------------------------------------------------------------------------------------------------------------------
function switchTargetAndFocus()
    if UnitExists('target') and not UnitExists('focus') then
        RunMacroText('/focus')
        RunMacroText('/cleartarget')
        return
    end
    if UnitExists('focus') and not UnitExists('target') then
        RunMacroText('/target focus')
        RunMacroText('/clearfocus')
        return
    end
    RunMacroText('/target focus')
    RunMacroText('/targetlasttarget')
    RunMacroText('/focus')
    RunMacroText('/targetlasttarget')
end
------------------------------------------------------------------------------------------------------------------
-- Update Debug Frame
local notifyFrame
local notifyFrameTime = 0
local function notifyFrame_OnUpdate()
    if (notifyFrameTime > 0 and notifyFrameTime < GetTime() - 5) then
        local alpha = notifyFrame:GetAlpha()
        if (alpha ~= 0) then
            notifyFrame:SetAlpha(alpha - .02)
        end
        if (aplha == 0) then
            notifyFrame:Hide()
            notifyFrameTime = 0
        end
    end
end
-- /run Notify("test")
-- Debug & Notification Frame
notifyFrame = CreateFrame('Frame')
notifyFrame:ClearAllPoints()
notifyFrame:SetHeight(300)
notifyFrame:SetWidth(800)
notifyFrame:SetScript('OnUpdate', notifyFrame_OnUpdate)
notifyFrame:Hide()
notifyFrame.text = notifyFrame:CreateFontString(nil, 'BACKGROUND', 'BossEmoteNormalHuge')
notifyFrame.text:SetAllPoints()
notifyFrame:SetPoint('CENTER', 0, 0)

-- Debug messages.
function Notify(message)
    notifyFrame.text:SetText(message)
    notifyFrame:SetAlpha(1)
    notifyFrame:Show()
    notifyFrameTime = GetTime()
end

------------------------------------------------------------------------------------------------------------------
function echo(msg, cls)
    if (cls ~= nil) then
        UIErrorsFrame:Clear()
    end
    UIErrorsFrame:AddMessage(msg, 0.0, 1.0, 0.0, 53, 2)
end

------------------------------------------------------------------------------------------------------------------
local lastMsg = {}
function chat(msg, r, g, b)
    r = r or 1.0
    b = b or 0.5
    g = g or 0.5
    local key = r * 100 + g * 10 + b
    if lastMsg[key] == msg and TimerLess('EchoMsg' .. key, 2) then
        return
    end

    DEFAULT_CHAT_FRAME:AddMessage(msg, r, b, g)
    TimerStart('EchoMsg' .. key)
    lastMsg[key] = msg
end
------------------------------------------------------------------------------------------------------------------
function printtable(t, indent)
    indent = indent or 0
    local keys = {}
    for k in pairs(t) do
        keys[#keys + 1] = k
        sort(
            keys,
            function(a, b)
                local ta, tb = type(a), type(b)
                if (ta ~= tb) then
                    return ta < tb
                else
                    return a < b
                end
            end
        )
    end
    print(string.rep('  ', indent) .. '{')
    indent = indent + 1
    for k, v in pairs(t) do
        local key = k
        if (type(key) == 'string') then
            if not (string.match(key, '^[A-Za-z_][0-9A-Za-z_]*$')) then
                key = "['" .. key .. "']"
            end
        elseif (type(key) == 'number') then
            key = '[' .. key .. ']'
        end
        if (type(v) == 'table') then
            if (next(v)) then
                print(format('%s%s =', string.rep('  ', indent), tostring(key)))
                printtable(v, indent)
            else
                print(format('%s%s = {},', string.rep('  ', indent), tostring(key)))
            end
        elseif (type(v) == 'string') then
            print(format('%s%s = %s,', string.rep('  ', indent), tostring(key), "'" .. v .. "'"))
        else
            print(format('%s%s = %s,', string.rep('  ', indent), tostring(key), tostring(v)))
        end
    end
    indent = indent - 1
    print(string.rep('  ', indent) .. '}')
end

------------------------------------------------------------------------------------------------------------------
function tContainsKey(table, key)
    local result = false
    for name, value in pairs(table) do
        if key == name then
            result = true
            break
        end
    end
    return result
end
------------------------------------------------------------------------------------------------------------------

function sContains(str, sub)
    if (not str or not sub) then
        return false
    end
    return (strlower(str):find(strlower(sub), 1, true) ~= nil)
end

------------------------------------------------------------------------------------------------------------------
function IsMouse(n)
    return IsMouseButtonDown(n) == 1
end

------------------------------------------------------------------------------------------------------------------
function IsCtr()
    return (IsControlKeyDown() == 1 and not GetCurrentKeyBoardFocus())
end

------------------------------------------------------------------------------------------------------------------
function IsAlt()
    return (IsAltKeyDown() == 1 and not GetCurrentKeyBoardFocus())
end

------------------------------------------------------------------------------------------------------------------
function IsShift()
    return (IsShiftKeyDown() == 1 and not GetCurrentKeyBoardFocus())
end
------------------------------------------------------------------------------------------------------------------
local timers = {}

function TimerReset(name)
    timers[name] = 0
end

function TimerStarted(name)
    return (timers[name] or 0) > 0
end

function TimerStart(name, offset)
    timers[name] = GetTime() + (offset or 0)
end

function TimerElapsed(name)
    return GetTime() - (timers[name] or 0)
end

function TimerLess(name, less)
    return TimerElapsed(name) < (less or 0)
end

function TimerMore(name, less)
    return TimerElapsed(name) > (less or 0)
end

function TimerToggle(name, toggle)
    if toggle then
        if not TimerStarted(name) then
            TimerStart(name)
        end
    else
        if TimerStarted(name) then
            TimerReset(name)
        end
    end
end
------------------------------------------------------------------------------------------------------------------
-- Стандартная карта мира принимает более лучший вид(Не разворачивается на весь экран)
local BigMap = function()
    WorldMapFrame:SetParent(UIParent)
    WorldMapFrame:EnableMouse(false)
    WorldMapFrame:EnableKeyboard(false)
    WorldMapFrame:SetScale(1)
    SetUIPanelAttribute(WorldMapFrame, 'area', 'center')
    SetUIPanelAttribute(WorldMapFrame, 'allowOtherPanels', true)
    WorldMapFrame:SetFrameLevel(6)
    WorldMapDetailFrame:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 1)
    WorldMapFrame:SetFrameStrata('TOOLTIP')
    BlackoutWorld:SetTexture(0, 0, 0, 0)
end
hooksecurefunc('WorldMap_ToggleSizeUp', BigMap)
hooksecurefunc('WorldMapFrame_SetFullMapView', BigMap)
BigMap()

------------------------------------------------------------------------------------------------------------------
-- Полоски со здоровьем теперь не зеленого цвета а в цвет класса (Довольно приятно)
local _, class, c
local function colour(statusbar, unit)
    if UnitIsPlayer(unit) and UnitIsConnected(unit) and unit == statusbar.unit and UnitClass(unit) then
        _, class = UnitClass(unit)
        c = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
        statusbar:SetStatusBarColor(c.r, c.g, c.b)
    end
end
hooksecurefunc('UnitFrameHealthBar_Update', colour)
hooksecurefunc(
    'HealthBar_OnValueChanged',
    function(self)
        colour(self, self.unit)
    end
)
local sb = _G.GameTooltipStatusBar
local addon = CreateFrame('Frame', 'StatusColour')
addon:RegisterEvent('UPDATE_MOUSEOVER_UNIT')
addon:SetScript(
    'OnEvent',
    function()
        colour(sb, 'mouseover')
    end
)
------------------------------------------------------------------------------------------------------------------
-- Снимаем все ограничения с Чата. Возможность переместить в самый угол экрана
for i = 1, NUM_CHAT_WINDOWS do
    _G['ChatFrame' .. i]:SetClampRectInsets(0, 0, 0, 0)
    FCF_SavePositionAndDimensions(_G[format('ChatFrame%d', i)])
end
------------------------------------------------------------------------------------------------------------------
-- Возможность отдалять камеру намного дальше чем возможно стандартными настройками игры
AttachEvent(
    'PLAYER_ENTERING_WORLD',
    function()
        SetCVar('cameraDistanceMax', 50)
        SetCVar('cameraDistanceMaxFactor', 5)
    end
)
------------------------------------------------------------------------------------------------------------------
-- Миникарта (С миникарты убрано лишее, теперь маштаб регулируется колесиком мышки)
--MinimapBorderTop:Hide()
MiniMapWorldMapButton:Hide() -- Скрытие значка Мировой карты Установите
--MinimapZoneText:SetPoint("TOPLEFT","MinimapZoneTextButton","TOPLEFT", 8, 0) -- Координата центрального текста карты(Пс. Названия Зоны где вы находитесь)
MinimapZoomIn:Hide() -- Скрытие кнопок +\-
MinimapZoomOut:Hide()
Minimap:EnableMouseWheel(true)
Minimap:SetScript(
    'OnMouseWheel',
    function(self, delta)
        if delta > 0 then
            Minimap_ZoomIn()
        else
            Minimap_ZoomOut()
        end
    end
)
------------------------------------------------------------------------------------------------------------------
function round(number, decimals)
    if decimals == nil then
        decimals = 0
    end
    return (('%%.%df'):format(decimals)):format(number)
end
