-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
--UIParentLoadAddOn("Blizzard_DebugTools");
--DevTools_Dump(n)
function SellGray()
    for b=0,4 do                                   
      for s=1, GetContainerNumSlots(b) do          
        local n=GetContainerItemLink(b,s)
        if n then
            if string.find(n, "ff9d9d9d") or (IsTrash and IsTrash(n)) then                                 
              UseContainerItem(b,s)                   
            end
        end
                                               
      end                                          
    end                                            
end

------------------------------------------------------------------------------------------------------------------
function buy(name,q) 
    local c = 0
    for i=0,3 do 
        local numberOfFreeSlots = GetContainerNumFreeSlots(i);
        if numberOfFreeSlots then c = c + numberOfFreeSlots end
    end
    if c < 1 then return end
    if q == nil then q = 255 end
    for i=1,100 do 
        if name == GetMerchantItemInfo(i) then
            local s = c*GetMerchantItemMaxStack(i) 
            if q > s then q = s end
            BuyMerchantItem(i,q)
        end 
    end
end

------------------------------------------------------------------------------------------------------------------
function sell(name) 
    if not name then name = "" end
    for bag = 0,4,1 do 
        for slot = 1, GetContainerNumSlots(bag), 1 do 
            local item = GetContainerItemLink(bag,slot)
            if item and string.find(item,name) then 
                UseContainerItem(bag,slot) 
            end
        end
    end
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
function chat(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg, 1.0, 0.5, 0.5);
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
--Верхняя часть вашей цели становится прозрачной, как у фрейма Игрока
UnitSelectionColor = function(unit)
  if not UnitExists(unit) then return 1,1,1,1 end
  local color = UnitIsPlayer(unit) and RAID_CLASS_COLORS[select(2, 
  UnitClass(unit))] or FACTION_BAR_COLORS[UnitReaction(unit, 'player')]
  if color then
    if not UnitIsConnected(unit) then 
      return .5, .5, .5, 1
    else
      return 0, 0, 0, 0.5
    end
  else
    if UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then
      return .5, .5, .5, 1
    end
  end
end
------------------------------------------------------------------------------------------------------------------
-- Изменяем размер Бафов\Дебафов на целе и фокусе
hooksecurefunc("TargetFrame_UpdateAuraPositions", function(self, auraName, numAuras, numOppositeAuras,largeAuraList, updateFunc, maxRowWidth, offsetX)
    local AURA_OFFSET_Y = 3   --размер ОФФ аур (Накидка и т.д)
    local LARGE_AURA_SIZE = 33 -- размер ВАШИХ баффов/дебаффов.
    local SMALL_AURA_SIZE = 20 -- размер чужих баффов/дебаффов.
    local size
    local offsetY = AURA_OFFSET_Y
    local rowWidth = 0
    local firstBuffOnRow = 1
    for i=1, numAuras do
     if ( largeAuraList[i] ) then
       size = LARGE_AURA_SIZE
       offsetY = AURA_OFFSET_Y + AURA_OFFSET_Y
     else
       size = SMALL_AURA_SIZE
     end
     if ( i == 1 ) then
       rowWidth = size
       self.auraRows = self.auraRows + 1
     else
       rowWidth = rowWidth + size + offsetX
     end
     if ( rowWidth > maxRowWidth ) then
       updateFunc(self, auraName, i, numOppositeAuras, firstBuffOnRow, size, offsetX, offsetY)
       rowWidth = size
       self.auraRows = self.auraRows + 1
       firstBuffOnRow = i
       offsetY = AURA_OFFSET_Y
     else
       updateFunc(self, auraName, i, numOppositeAuras, i - 1, size, offsetX, offsetY)
     end
    end
    end)
------------------------------------------------------------------------------------------------------------------
-- Полоски со здоровьем теперь не зеленого цвета а в цвет класса (Довольно приятно)
local UnitIsPlayer, UnitIsConnected, UnitClass, RAID_CLASS_COLORS =
UnitIsPlayer, UnitIsConnected, UnitClass, RAID_CLASS_COLORS
local _, class, c
local function colour(statusbar, unit)
-- только для игроков
--if UnitIsPlayer(unit) and UnitIsConnected(unit) and unit == statusbar.unit and UnitClass(unit) then
-- для всех
if unit and unit == statusbar.unit and UnitClass(unit) then
_, class = UnitClass(unit)
c = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
statusbar:SetStatusBarColor(c.r, c.g, c.b)
end
end
hooksecurefunc("UnitFrameHealthBar_Update", colour)
hooksecurefunc("HealthBar_OnValueChanged", function(self)
colour(self, self.unit)
end)
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
  SetCVar("cameraDistanceMaxFactor", 3.4)
end)
------------------------------------------------------------------------------------------------------------------
-- Миникарта (С миникарты убрано лишее, теперь маштаб регулируется колесиком мышки)
MinimapBorderTop:Hide()
MiniMapWorldMapButton:Hide() -- Скрытие значка Мировой карты Установите 
MinimapZoneText:SetPoint("TOPLEFT","MinimapZoneTextButton","TOPLEFT", 8, 0) -- Координата центрального текста карты(Пс. Названия Зоны где вы находитесь)
MinimapZoomIn:Hide() -- Скрытие кнопок +\-
MinimapZoomOut:Hide()
Minimap:EnableMouseWheel(true)
Minimap:EnableMouseWheel(true)
Minimap:SetScript('OnMouseWheel', function(self, delta)
        if delta > 0 then
                Minimap_ZoomIn()
        else
                Minimap_ZoomOut()
        end
end)
------------------------------------------------------------------------------------------------------------------
 -- BaffTracker отслеживает ваши Бафы\Таланты количество ограничено 40 бафов
 --[[local size = 26 --Размер
local spells = {5171,73651,1966,113742} -- нужные баффы
local spellsDB = {}
for _,s in pairs(spells) do
    spellsDB[s] = CreateFrame("frame", nil, PlayerFrame)
    spellsDB[s]:SetSize(size, size)
    spellsDB[s].c = CreateFrame("Cooldown", nil, spellsDB[s])
    spellsDB[s].c:SetAllPoints()
    spellsDB[s].t = spellsDB[s]:CreateTexture(nil, 'BORDER')
    spellsDB[s].t:SetAllPoints()
    spellsDB[s].t:SetTexture(select(3, GetSpellInfo(s)))
    spellsDB[s]:Hide()
end

AttachEvent("PLAYER_ENTERING_WORLD", function(event, ...)
    local unit = ...
    local sfound, rfound = false, false
    if event == "UNIT_AURA" and unit=='player' then
        local index = 0
        for _,s in pairs(spells) do spellsDB[s]:Hide() end
        for i = 1, 40 do
            local n, _, _, _, _, d, x, _, _, _, spellID = UnitBuff("player", i)
            if not n then break end
            if spellsDB[spellID] then
                if index == 0 then spellsDB[spellID]:SetPoint("TOP", 30, 10) else spellsDB[spellID]:SetPoint("TOP", 30+index*size, 10) end
                spellsDB[spellID]:Show() spellsDB[spellID].c:SetCooldown(x - d - 0.5, d) index = index + 1
            end
        end
    end
end)]]
------------------------------------------------------------------------------------------------------------------
-- Арена тринкеты + Динимишинг (Так сказать Gladius)
--[[local trinkets = {}
local events = CreateFrame("Frame")

function events:ADDON_LOADED(addonName)
    if addonName ~= "Blizzard_ArenaUI" then
        return
    end
        ArenaEnemyFrame1:ClearAllPoints()
        ArenaEnemyFrame1:SetPoint("CENTER", nil, "CENTER", 250.0, 250.0)  -- Координаты Горизонталь\Вертикаль
        ArenaEnemyFrames:SetScale(1.7)                    -- Размер
    local arenaFrame, trinket
    for i = 1, MAX_ARENA_ENEMIES do
        arenaFrame = "ArenaEnemyFrame"..i
        trinket = CreateFrame("Cooldown", arenaFrame.."Trinket", ArenaEnemyFrames)
        trinket:SetPoint("TOPRIGHT", arenaFrame, 30, -6)          --Координаты положения Тринкета относительно Арена фреймов
        trinket:SetSize(24, 24)                       --Размер значка арена тринкета
        trinket.icon = trinket:CreateTexture(nil, "BACKGROUND")
        trinket.icon:SetAllPoints()
        trinket.icon:SetTexture("Interface\\Icons\\inv_jewelry_trinketpvp_01")
        trinket:Hide()
        trinkets["arena"..i] = trinket
    end
    self:UnregisterEvent("ADDON_LOADED")
end

function events:UNIT_SPELLCAST_SUCCEEDED(unitID, spell, rank, lineID, spellID)
    if not trinkets[unitID] then
        return
    end
    if spellID == 59752 or spellID == 42292 then
        CooldownFrame_SetTimer(trinkets[unitID], GetTime(), 120, 1)
        SendChatMessage("Trinket used by: "..GetUnitName(unitID, true), "PARTY")
    elseif spellID == 7744 then
        CooldownFrame_SetTimer(trinkets[unitID], GetTime(), 45, 1)
        SendChatMessage("WotF used by: "..GetUnitName(unitID, true), "PARTY")
    end
end

function events:PLAYER_ENTERING_WORLD()
    local _, instanceType = IsInInstance()
    if instanceType == "arena" then
        self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    elseif self:IsEventRegistered("UNIT_SPELLCAST_SUCCEEDED") then
        self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        for _, trinket in pairs(trinkets) do
            trinket:SetCooldown(0, 0)
            trinket:Hide()
        end
    end
end

SLASH_TESTAEF1 = "/testaef"             --Команда для Теста скрипта вне арены
SlashCmdList["TESTAEF"] = function(msg, editBox)
    if not IsAddOnLoaded("Blizzard_ArenaUI") then
        LoadAddOn("Blizzard_ArenaUI")
    end
    ArenaEnemyFrames:Show()
    local arenaFrame
    for i = 1, 3 do
        arenaFrame = _G["ArenaEnemyFrame"..i]   
        arenaFrame.classPortrait:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
        arenaFrame.classPortrait:SetTexCoord(unpack(CLASS_ICON_TCOORDS["WARRIOR"]))
        arenaFrame.name:SetText("Dispelme")
        arenaFrame:Show()
        CooldownFrame_SetTimer(trinkets["arena"..i], GetTime(), 120, 1)   
    end
end

events:SetScript("OnEvent", function(self, event, ...) return self[event](self, ...) end)
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")

local frame = CreateFrame("FRAME")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
frame:RegisterEvent("UNIT_FACTION")
frame:RegisterEvent("ARENA_OPPONENT_UPDATE")
frame:RegisterEvent("ADDON_LOADED");
 
local function DoArenaColorHook()
        hooksecurefunc("ArenaEnemyFrame_Unlock",
                function(self)
                        local color=RAID_CLASS_COLORS[select(2,UnitClass(self.unit)) or ""]
                        if color then
                                self.healthbar:SetStatusBarColor(color.r,color.g,color.b)
                                self.healthbar.lockColor=true
                        end           
                end
        )
end
 
local function eventHandler(self, event, arg, ...)
        if (event == "UNIT_FACTION" and arg ~= "target" and arg ~= "focus") then return end
       
        if event == "ADDON_LOADED" then
                if arg == "Blizzard_ArenaUI" then
                        self:UnregisterEvent(event);
                        DoArenaColorHook();
                end
        end  
       
        
end 
if IsAddOnLoaded("Blizzard_ArenaUI") then
        DoArenaColorHook();
end 
frame:SetScript("OnEvent", eventHandler)

DRt={{5211,12809,44572,47481,2812,853,408,22570,6785,30283,46968,20549,85388,1833,9005},{118,6770,1776,49203,28272,28271,61305,61721,61780,82691,51514},{5782,8122,5484,20511,2094},{676,51722,64044},{12958,703,2139,50479,34490,13867,15487,19647,47476}} 
drx=86;drs=26;dp="RIGHT";dre="COMBAT_LOG_EVENT_UNFILTERED"drp="PLAYER_ENTERING_WORLD"dra="ARENA_OPPONENT_UPDATE"LoadAddOn("Blizzard_ArenaUI")function gaef(f,n)return _G["ArenaEnemyFrame"..n.."HealthBar"]end 
function rDR(f)f.e=1;f.t:SetTexture(nil)f.c:Hide()end function sDR(f)f.e=f.e+1;f.c:Show()end function gDRt(i,j)return _G["drc"..i..":"..j]end function runDR(f,n)CooldownFrame_SetTimer(f.c,GetTime(),18,1)eDR(f,n)sDR(f)oDR(n)end 
function eDR(f,n)local t=1;f:SetScript("OnUpdate",function(s,e)t=t+e;if(t>=18)then f:SetScript("OnUpdate",nil)rDR(f)oDR(n)end end)end function cDR(f,n,s)if f.e<4 then local _,_,t=GetSpellInfo(s)f.t:SetTexture(t)runDR(f,n)end end 
function oDR(n)local r=1;for j in ipairs(DRt)do local f=gDRt(n,j)f:SetPoint(dp,gaef(f,n),dp,drx+(r-1)*25,-2)r=r+1;end end function uDR(n,s)for i,t in ipairs(DRt)do for _,j in ipairs(t)do if s==j then cDR(gDRt(n,i),n,s)end end end end 
function DRc(i,j)local f=CreateFrame("Frame",nil,UIParent)f:SetSize(drs,drs)f.t=f:CreateTexture(nil,"BORDER")f.t:SetAllPoints(true)f.c=CreateFrame("Cooldown",nil,f)f.c:SetAllPoints(f)f.e=1 return f end 
function clDR(_,e,_,_,_,_,_,d,_,_,_,s)if(e=="SPELL_AURA_REMOVED" or e=="SPELL_AURA_REFRESH")then for i=1,5 do local ag=UnitGUID("arena"..i)if(ag ~= nil and d==ag)then uDR(i,s)end end end end 
function iDRt(o,m)for i=1,m do for j in ipairs(DRt)do local f=gDRt(i,j)rDR(f)if o then f:Show()end end end end for i=1,5 do for j in ipairs(DRt)do _G["drc"..i..":"..j]=DRc(i,j)end end 
dt=CreateFrame("Frame")dt:SetScript("OnEvent",function(_,e,...)if e==dre then clDR(...)elseif e==dra then iDRt(1,GetNumArenaOpponents())else iDRt(nil,5)end end)dt:RegisterEvent(dra)dt:RegisterEvent(drp)dt:RegisterEvent(dre)

local f = CreateFrame("Frame")
local function Update(self, event, ...)
  
  local pvpType = GetZonePVPInfo()  
    f:UnregisterEvent("ZONE_CHANGED_NEW_AREA")  
  if event == "COMBAT_LOG_EVENT_UNFILTERED" then
    if UnitInRaid("player") and GetNumRaidMembers() > 5 then channel = "RAID" elseif GetNumPartyMembers() > 0 then channel = "PARTY" else return end
    -- local channel = "SAY"
    local timestamp, eventType, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, _, spellID, spellName, _, extraskillID, extraSkillName = ...
    if eventType == "SPELL_INTERRUPT" and sourceName == UnitName("player") then
      SendChatMessage("Interrupted -> "..GetSpellLink(extraskillID).."!", channel)
    end
  end
end
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:SetScript("OnEvent", Update)

local function Update(self, event, ...)
  if event == "UNIT_SPELLCAST_SUCCEEDED" then
    local unit, spellName, spellrank, spelline, spellID = ...
    if GetZonePVPInfo() == "arena" then
      if UnitIsEnemy("player", unit) and (spellID == 80167 or spellID == 94468 or spellID == 43183 or spellID == 57073 or spellName == "Trinken") then
        SendChatMessage(UnitName(unit).." is drinking.", "PARTY")
      end
    end
  end
end

local f = CreateFrame("Frame")
f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
f:SetScript("OnEvent", Update)]]
------------------------------------------------------------------------------------------------------------------
-- Перемещение фреймов Игрока\Цели\Фокуса и Групповых Фреймов
--[[local a = CreateFrame("Frame")
a:SetScript("OnEvent", function(self, event)
if event == "PLAYER_ENTERING_WORLD" then
  PlayerFrame:ClearAllPoints()
  TargetFrame:ClearAllPoints()
  FocusFrame:ClearAllPoints()
  
  PlayerFrame:SetPoint("TOPLEFT",UIParent,"TOPLEFT", 300, -350) -- Координаты Фрейма Игрока
  TargetFrame:SetPoint("TOPLEFT",UIParent,"TOPLEFT", 400, -400) -- Координаты Таргета(Вашей цели)
  FocusFrame:SetPoint("TOPLEFT",UIParent,"TOPLEFT",  120, -400) -- Координаты Фокуса (Запомненой цели)
  
  PlayerFrame:SetScale(1.3) -- Размер Фрейма Игрока
  TargetFrame:SetScale(1.3) -- Размер фрейма Цели
  FocusFrame:SetScale(1.3)  -- Размер фрейма Фокуса
  
  PartyMemberFrame1:ClearAllPoints()
  PartyMemberFrame2:ClearAllPoints()
  PartyMemberFrame3:ClearAllPoints()
  PartyMemberFrame4:ClearAllPoints()
  
  PartyMemberFrame1:SetPoint("TOPLEFT",UIParent,"TOPLEFT", 50, -150)  -- Координата фрема 1го члена группы
  PartyMemberFrame2:SetPoint("TOPLEFT",UIParent,"TOPLEFT", 50, -230)  -- Координата фрема 2го члена группы
  PartyMemberFrame3:SetPoint("TOPLEFT",UIParent,"TOPLEFT", 50, -310)  -- Координата фрема 3го члена группы
  PartyMemberFrame4:SetPoint("TOPLEFT",UIParent,"TOPLEFT", 50, -390)  -- Координата фрема 4го члена группы
  
  PartyMemberFrame1:SetScale(1.3) -- Размер фрема 1го члена группы
  PartyMemberFrame2:SetScale(1.3) -- Размер фрема 1го члена группы
  PartyMemberFrame3:SetScale(1.3) -- Размер фрема 1го члена группы
  PartyMemberFrame4:SetScale(1.3) -- Размер фрема 1го члена группы
  
  FocusFrameSpellBar:SetScale(1.3)  -- Размер Полоски применения вашей цели
  TargetFrameSpellBar:SetScale(1.3) -- Размер Полоски применения фокуса
end
end)
a:RegisterEvent("PLAYER_ENTERING_WORLD")]]