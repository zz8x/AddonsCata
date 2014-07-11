-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
--UIParentLoadAddOn("Blizzard_DebugTools");
--DevTools_Dump(n)
------------------------------------------------------------------------------------------------------------------
function RegBG()
    RunMacroText([[
/click PVPMicroButton
/click PVPHonorFrameBgButton3
/script JoinBattlefield(1, InGroup())
      ]])
end

------------------------------------------------------------------------------------------------------------------
function SellGray()
    for b=0,4 do                                   
      for s=1, GetContainerNumSlots(b) do          
        local n=GetContainerItemLink(b,s)
        if n then
            if string.find(n, "ff9d9d9d") or (IsGray and IsGray(n)) then                                 
              UseContainerItem(b,s)                   
            end
        end
                                               
      end                                          
    end  
end

------------------------------------------------------------------------------------------------------------------
function DelGray()
    ClearCursor()
    for b=0,4 do                                   
      for s=1, GetContainerNumSlots(b) do          
        local n=GetContainerItemLink(b,s)
        if n then
            if string.find(n, "ff9d9d9d") or (IsTrash and IsTrash(n)) then                                 
              PickupContainerItem(b,s)
              DeleteCursorItem() 
            end
        end
      end                                          
    end                                            
end
------------------------------------------------------------------------------------------------------------------
function buy(name,q) 
    if q < 1 then return end
    local c = 0
    for bag=0, NUM_BAG_SLOTS do 
        local numberOfFreeSlots = GetContainerNumFreeSlots(bag);
        if numberOfFreeSlots then c = c + numberOfFreeSlots end
    end
    if c < 1 then return end
    if q == nil then q = 255 end
    for i=1,100 do 
        if name == GetMerchantItemInfo(i) then
            local s = c*GetMerchantItemMaxStack(i) 
            if q > s then q = s end
            BuyMerchantItem(i,q)
            break
        end 
    end
end

------------------------------------------------------------------------------------------------------------------
function sell(name) 
    if not name then name = "" end
    for bag = 0,NUM_BAG_SLOTS do 
        for slot = 1, GetContainerNumSlots(bag) do 
            local item = GetContainerItemLink(bag,slot)
            if item and string.find(item,name) then 
                UseContainerItem(bag,slot) 
            end
        end
    end
end

------------------------------------------------------------------------------------------------------------------
function countItem(name)
    local count = 0
    for bag=0,NUM_BAG_SLOTS do
        for slot=1,GetContainerNumSlots(bag) do
            local item = GetContainerItemLink(bag,slot)
            if item and string.find(item,name) then 
                count=count+(select(2,GetContainerItemInfo(bag,slot)))
            end
        end
    end
    return count
end
------------------------------------------------------------------------------------------------------------------
function switchTargetAndFocus()
  if UnitExists("target") and not UnitExists("focus") then 
      RunMacroText("/focus") 
      RunMacroText("/cleartarget") 
      return 
  end
  if UnitExists("focus") and not UnitExists("target") then 
    RunMacroText("/target focus") 
    RunMacroText("/clearfocus") 
    return 
  end
  RunMacroText("/target focus") 
  RunMacroText("/targetlasttarget") 
  RunMacroText("/focus") 
  RunMacroText("/targetlasttarget") 
end
------------------------------------------------------------------------------------------------------------------
-- Update Debug Frame
local notifyFrame
local notifyFrameTime = 0
local function notifyFrame_OnUpdate()
        if (notifyFrameTime > 0 and notifyFrameTime < GetTime() - 5) then
                local alpha = notifyFrame:GetAlpha()
                if (alpha ~= 0) then notifyFrame:SetAlpha(alpha - .02) end
                if (aplha == 0) then 
					notifyFrame:Hide() 
					notifyFrameTime = 0
				end
        end
end
-- Debug & Notification Frame
notifyFrame = CreateFrame('Frame')
notifyFrame:ClearAllPoints()
notifyFrame:SetHeight(300)
notifyFrame:SetWidth(800)
notifyFrame:SetScript('OnUpdate', notifyFrame_OnUpdate)
notifyFrame:Hide()
notifyFrame.text = notifyFrame:CreateFontString(nil, 'BACKGROUND', 'PVPInfoTextFont')
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
    if (cls ~= nil) then UIErrorsFrame:Clear() end
    UIErrorsFrame:AddMessage(msg, 0.0, 1.0, 0.0, 53, 2);
end

------------------------------------------------------------------------------------------------------------------
local lastEchoMsg = ""
local lastEchoTime = 0
function chat(msg)
    if msg == lastEchoMsg and GetTime() - lastEchoTime < 2 then return end
    DEFAULT_CHAT_FRAME:AddMessage(msg, 1.0, 0.5, 0.5);
    lastEchoTime = GetTime()
    lastEchoMsg = msg
end

------------------------------------------------------------------------------------------------------------------
function printtable(t, indent)
  indent = indent or 0;
  local keys = {};
  for k in pairs(t) do
    keys[#keys+1] = k;
    table.sort(keys, function(a, b)
      local ta, tb = type(a), type(b);
      if (ta ~= tb) then
        return ta < tb;
      else
        return a < b;
      end
    end);
  end
  print(string.rep('  ', indent)..'{');
  indent = indent + 1;
  for k, v in pairs(t) do
    local key = k;
    if (type(key) == 'string') then
      if not (string.match(key, '^[A-Za-z_][0-9A-Za-z_]*$')) then
        key = "['"..key.."']";
      end
    elseif (type(key) == 'number') then
      key = "["..key.."]";
    end
    if (type(v) == 'table') then
      if (next(v)) then
        print(format("%s%s =", string.rep('  ', indent), tostring(key)));
        printtable(v, indent);
      else
        print(format("%s%s = {},", string.rep('  ', indent), tostring(key)));
      end 
    elseif (type(v) == 'string') then
      print(format("%s%s = %s,", string.rep('  ', indent), tostring(key), "'"..v.."'"));
    else
      print(format("%s%s = %s,", string.rep('  ', indent), tostring(key), tostring(v)));
    end
  end
  indent = indent - 1;
  print(string.rep('  ', indent)..'}');
end

------------------------------------------------------------------------------------------------------------------
function tContainsKey(table, key)
    for name,value in pairs(table) do 
        if key == name then return true end
    end
    return false
end

function sContains(str, sub)
    if (not str or not sub) then
      return false
    end
    return (strlower(str):find(strlower(sub), 1, true) ~= nil)
end

------------------------------------------------------------------------------------------------------------------
function IsMouse3()
    return  IsMouseButtonDown(3) == 1
end

------------------------------------------------------------------------------------------------------------------
function IsCtr()
    return  (IsControlKeyDown() == 1 and not GetCurrentKeyBoardFocus())
end

------------------------------------------------------------------------------------------------------------------
function IsAlt()
    return  (IsAltKeyDown() == 1 and not GetCurrentKeyBoardFocus())
end

------------------------------------------------------------------------------------------------------------------
function IsShift()
    return  (IsShiftKeyDown() == 1 and not GetCurrentKeyBoardFocus())
end
------------------------------------------------------------------------------------------------------------------
-- Стандартная карта мира принимает более лучший вид(Не разворачивается на весь экран)
local BigMap = function()
     WorldMapFrame:SetParent(UIParent)
     WorldMapFrame:EnableMouse(false)
     WorldMapFrame:EnableKeyboard(false)
     WorldMapFrame:SetScale(1)
     SetUIPanelAttribute(WorldMapFrame, "area", "center")
     SetUIPanelAttribute(WorldMapFrame, "allowOtherPanels", true)
     WorldMapFrame:SetFrameLevel(6)
     WorldMapDetailFrame:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 1)
     WorldMapFrame:SetFrameStrata('TOOLTIP')
     BlackoutWorld:SetTexture(0, 0, 0, 0)
end
hooksecurefunc("WorldMap_ToggleSizeUp", BigMap)
hooksecurefunc("WorldMapFrame_SetFullMapView", BigMap)
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
hooksecurefunc("UnitFrameHealthBar_Update", colour)
hooksecurefunc("HealthBar_OnValueChanged", function(self) colour(self, self.unit) end)
local sb = _G.GameTooltipStatusBar
local addon = CreateFrame("Frame", "StatusColour")
addon:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
addon:SetScript("OnEvent", function()
  colour(sb, "mouseover")
end)
------------------------------------------------------------------------------------------------------------------
-- Снимаем все ограничения с Чата. Возможность переместить в самый угол экрана
for i = 1, NUM_CHAT_WINDOWS do 
_G["ChatFrame"..i]:SetClampRectInsets(0,0,0,0) 
FCF_SavePositionAndDimensions(_G[format("ChatFrame%d", i)]) end
------------------------------------------------------------------------------------------------------------------
-- Возможность отдалять камеру намного дальше чем возможно стандартными настройками игры
AttachEvent("PLAYER_ENTERING_WORLD", function()
  SetCVar("cameraDistanceMax", 50)
  SetCVar("cameraDistanceMaxFactor", 5)
end)
------------------------------------------------------------------------------------------------------------------
-- Миникарта (С миникарты убрано лишее, теперь маштаб регулируется колесиком мышки)
--MinimapBorderTop:Hide()
MiniMapWorldMapButton:Hide() -- Скрытие значка Мировой карты Установите 
--MinimapZoneText:SetPoint("TOPLEFT","MinimapZoneTextButton","TOPLEFT", 8, 0) -- Координата центрального текста карты(Пс. Названия Зоны где вы находитесь)
MinimapZoomIn:Hide() -- Скрытие кнопок +\-
MinimapZoomOut:Hide()
Minimap:EnableMouseWheel(true)
Minimap:SetScript('OnMouseWheel', function(self, delta)
        if delta > 0 then
                Minimap_ZoomIn()
        else
                Minimap_ZoomOut()
        end
end)

------------------------------------------------------------------------------------------------------------------
local waitTable = {};
local waitFrame = nil;

local function waitUpdate(self,elapse)
  local count = #waitTable;
  local i = 1;
  while(i<=count) do
    local waitRecord = tremove(waitTable,i);
    local d = tremove(waitRecord,1);
    local f = tremove(waitRecord,1);
    local p = tremove(waitRecord,1);
    if(d>elapse) then
      tinsert(waitTable,i,{d-elapse,f,p});
      i = i + 1;
    else
      count = count - 1;
      f(unpack(p));
    end
  end
end
AttachUpdate(waitUpdate)

function setTimeout(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  tinsert(waitTable,{delay,func,{...}});
  return true;
end
------------------------------------------------------------------------------------------------------------------
function round(number, decimals)
    return (("%%.%df"):format(decimals)):format(number)
end
