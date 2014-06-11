-- Druid Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local freedomItem
local freedomSpell = "Каждый за себя"
SetCommand("freedom", 
    function() 
        if HasSpell(freedomSpell) then
            DoSpell(freedomSpell)
            return
        end
        UseEquippedItem(freedomItem) 
    end, 
    function() 
        if IsPlayerCasting() then return true end
        if HasSpell(freedomSpell) and (not InGCD() and not IsReadySpell(freedomSpell)) then return true end
        if freedomItem == nil then
           freedomItem = (UnitFactionGroup("player") == "Horde" and "Медальон Орды" or "Медальон Альянса")
        end
        return not IsEquippedItem(freedomItem) or (not InGCD() and not IsReadyItem(freedomItem)) 
    end
)

------------------------------------------------------------------------------------------------------------------
local tryMount = false
SetCommand("mount", 
    function() 
        if InGCD() or IsPlayerCasting() then return end

        if IsControlKeyDown() then
                
            if HasBuff("Облик кошки") and HasBuff("Крадущийся зверь") then
                RunMacroText("/cancelaura Крадущийся зверь")
                tryMount = true
                return
            end
            
            if not InCombatLockdown() and GetShapeshiftForm() ~= 0 and not (IsFalling() or IsSwimming()) then 
                RunMacroText("/cancelform") 
                tryMount = true
                return
            end
                       
            return
        end
        
        if InCombatLockdown() or IsArena() or IsAttack() or IsIndoors() or (IsFalling() and not IsFlyableArea() and not HasBuff("Облик кошки")) then 
            DoSpell("Облик кошки")
            tryMount = true
            return 
        end
           
        if InCombatLockdown() and not (IsFalling() and not IsFlyableArea()) and HasBuff("Облик кошки") then 
            DoSpell("Облик лютого медведя")
            tryMount = true
            return 
        end
           
        if InCombatLockdown() or not IsOutdoors() then return end
        local mount = "Огромный белый кодо"--"Стремительный белый рысак"
        if IsAltKeyDown() then mount = "Тундровый мамонт путешественника" end
        if not PlayerInPlace() then mount = "Походный облик" end
        if IsFlyableArea() and (not IsLeftControlKeyDown() or IsFalling()) then mount = "Облик стремительной птицы" end
        if IsSwimming() then mount = "Водный облик" end
        if UseMount(mount) then tryMount = true return end
        
    end, 
    function() 
        if tryMount then
            tryMount = false
            return true
        end
        return false 
    end
)
 
------------------------------------------------------------------------------------------------------------------
 SetCommand("bear", 
   function() return DoSpell("Облик медведя") end, 
   function() return HasBuff("Облик медведя") end
)
------------------------------------------------------------------------------------------------------------------
local clnTime = 0
local immuneList = {
  "Божественный щит",
  "Ледяная глыба",
  "Сдерживание",
  "Вихрь клинков",
  "Зверь внутри",
  "Отражение заклинания",
  "Антимагический панцирь",
  "Эффект тотема заземления"
}
local controlList = {"Покаяние", "Изгнание зла", "Молот правосудия"} -- TODO: для игры с паладином
SetCommand("сyclone", 
  function(target) 
    if clnTime ~= 0 and GetTime() - clnTime < 0.2 then return end
    if DoSpell("Смерч", target) then
      clnTime = GetTime()
      return
    end
  end, 
  function(target) 
    if target == nil then target = "target" end
    local spell = "Смерч"
    if not IsValidTarget(target) then chat(spell .. ": Неверная цель!") return true end
    if not InRange(spell, target) then chat(spell .. ": Неверная дистанция!") return true end
    local predictionTime = HasBuff("Быстрота хищника") and 0.2 or 1.5
    local aura = HasBuff(immuneList, predictionTime, target) or HasDebuff(spell, predictionTime, target)
    if aura then chat(spell .. ": Цель имунна: " .. aura) return true end
    if IsArena() then
      local control = HasDebuff(spell, predictionTime, target)        
      if control then chat(spell..': Цель еще в котроле: '.. control) return true end
    end
    if GetTime() - clnTime < 0.2 then
      clnTime = 0
      return true
      end
    return false 
  end
)
------------------------------------------------------------------------------------------------------------------
local rtsTime = 0
SetCommand("roots", 
  function(target)
    if rtsTime ~= 0 and GetTime() - rtsTime < 0.2 then return end
    if DoSpell("Гнев деревьев", target) then
      rtsTime = GetTime()
      return
    end 
  end, 
  function(target) 
    if target == nil then target = "target" end
    if (not InGCD() and not IsSpellNotUsed("Гнев деревьев",1)) or not CanMagicAttack(target) then return true end
    if GetTime() - rtsTime < 0.2 then
      rtsTime = 0
      return true
      end
    return false 
  end
)
------------------------------------------------------------------------------------------------------------------
 SetCommand("root", 
   function() return DoSpell("Хватка природы") end, 
   function() return HasBuff("Хватка природы") end
)
------------------------------------------------------------------------------------------------------------------
 SetCommand("stun", 
   function() return DoSpell("Калечение") end, 
   function() return HasDebuff("Калечение", 1, "target") or GetComboPoints("player", "target") == 0 end
)
------------------------------------------------------------------------------------------------------------------ 
 SetCommand("heal", 
  function(target) 
    DoSpell("Целительное прикосновение", target)
  end, 
  function(target) 
    if target == nil then target = "target" end
    if (not InGCD() and not IsSpellNotUsed("Целительное прикосновение",1)) then return true end
    return false 
  end
)
------------------------------------------------------------------------------------------------------------------ 
 SetCommand("ms", 
  function()
    if HasBuff("Облик медведя") and DoSpell("Тревожный рев(Облик медведя)") then return end
    if HasBuff("Облик кошки") and DoSpell("Тревожный рев(Облик кошки)") then return end
  end, 
  function() return HasBuff("Тревожный рев") end
)
------------------------------------------------------------------------------------------------------------------
local slpTime = 0
local controlList = {"Покаяние", "Изгнание зла", "Молот правосудия"} -- TODO: для игры с паладином
SetCommand("sleep", 
  function(target) 
    if slpTime ~= 0 and GetTime() - slpTime < 0.2 then return end
    if DoSpell("Спячка", target) then
      slpTime = GetTime()
      return
    end
  end, 
  function(target) 
    if target == nil then target = "target" end
    if (not InGCD() and not IsSpellNotUsed("Спячка",1)) or not CanMagicAttack(target) then return true end
    if GetTime() - slpTime < 0.2 then
      rtsTime = 0
      return true
      end
    return false 
  end
)