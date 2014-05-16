-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- TODO: need review
ControlList = { -- > 4
"Низвержение",
"Ненасытная стужа", -- 10s
"Смерч", -- 6s
"Калечение", -- 5s max
"Сон", -- 20s
"Тайфун", -- 6s
"Эффект замораживающей стрелы", -- 20s
"Эффект замораживающей ловушки", -- 10s
"Глубокая заморозка", -- 5s
"Дыхание дракона", -- 5s
"Превращение", -- 20s
"Молот правосудия", -- 6s
"Покаяние", -- 6s
"Удар по почкам", -- 6s max
"Сглаз", -- 30s
"Соблазн", -- 30s
"Огненный шлейф", -- 5s
"Оглушающий удар", -- 5s
"Пронзительный вой", -- 6s
"Головокружение", -- 6s
"Ошеломление", -- 20s
"Подлый трюк",
"Парализующий удар",
"Сон",
"Соблазн",
"Страх", 
"Вой ужаса", 
"Устрашающий крик", 
"Контроль над разумом", 
"Глубинный ужас", 
"Ментальный крик"
}

SappedList  = { -- > 4
"Ненасытная стужа", -- 10s
"Сон", -- 20s
"Превращение", -- 20s
"Покаяние", -- 6s
"Сглаз", -- 30s
"Соблазн", -- 30s
"Пронзительный вой", -- 6s
"Ошеломление", -- 20s
"Подлый трюк",
"Парализующий удар",
"Изгнание зла",
"Сон",
"Соблазн",
"Страх", 
"Вой ужаса", 
"Устрашающий крик", 
"Глубинный ужас", 
"Ментальный крик"
}

------------------------------------------------------------------------------------------------------------------
-- Можно законтролить игрока
local imperviousList = {"Вихрь клинков", "Зверь внутри", "Незыблемость льда"} -- TODO: Незыблемость льда под вопросом
CanControlInfo = ""
function CanControl(target)
    CanControlInfo = ""
    if nil == target then target = "target" end 
    if not CanAttack(target) then
        CanControlInfo = CanAttackInfo
        return false
    end
    local aura = HasBuff(imperviousList, 0.1, target) or HasDebuff(ControlList, 1.5, target)
    if aura then
        CanControlInfo = aura
        return false
    end 
    return true   
end

------------------------------------------------------------------------------------------------------------------
-- можно использовать магические атаки против игрока
CanMagicAttackInfo = ""
local magicList = {"Отражение заклинания", "Антимагический панцирь", "Рунический покров", "Эффект тотема заземления"}
function CanMagicAttack(target)
    CanMagicAttackInfo = ""
    if nil == target then target = "target" end 
    if not CanAttack(target) then
        CanMagicAttackInfo = CanAttackInfo
        return false
    end
    local aura = HasBuff(magicList, 0.1, target) 
    if aura then
        CanMagicAttackInfo = aura
        return false
    end
    return true
end

------------------------------------------------------------------------------------------------------------------
-- можно атаковать игрока (в противном случае не имеет смысла просаживать кд))
local immuneList = {"Божественный щит", "Ледяная глыба", "Сдерживание"}
CanAttackInfo = ""
function CanAttack(target)
    CanAttackInfo = ""
    if nil == target then target = "target" end 
    if not IsValidTarget(target) then
        CanAttackInfo = IsValidTargetInfo
        return false
    end
    if not IsInView(target) then
        CanAttackInfo = "Спиной к цели"
        return false
    end
    local aura = HasBuff(immuneList, 0.01, target) or HasDebuff("Смерч", 0.01, target)
    if aura then
        CanAttackInfo = "Цель имунна: " .. aura
        return false
    end
    return true
end

------------------------------------------------------------------------------------------------------------------
-- касты обязательные к сбитию в любом случае
local InterruptRedList = {
    "Великая волна исцеления",
    "Волна исцеления",
    "Выброс лавы",
    "Сглаз",
    "Цепное исцеление",
    "Превращение",
    "Прилив сил",
    "Нестабильное колдовство",
    "Блуждающий дух",
    "Стрела Тьмы",
    "Сокрушительный бросок",
    "Стрела Хаоса",
    "Вой ужаса",
    "Страх",
    "Похищение жизни",
    "Похищение души",
    "Свет небес",
    "Вспышка Света",
    "Быстрое исцеление",
    "Исповедь",
    "Божественный гимн",
    "Связующее исцеление",
    "Массовое рассеивание",
    "Прикосновение вампира",
    "Сожжение маны",
    "Молитва исцеления",
    "Исцеление",
    "Контроль над разумом",
    "Великое исцеление",
    "Покровительство Природы",
    "Звездный огонь",
    "Смерч",
    "Спокойствие потоковое",
    "Восстановление",
    "Целительное прикосновение",
    "Изгнание зла", 
    "Сковывание нежити",
    "Спячка",
    "Исцеляющий всплеск",
    "Божественный свет",
    "Отпугивание зверя",
    "Святое сияние",
    "Божественный свет",
    "Звездный поток"
}

function InInterruptRedList(spellName)
    return tContains(InterruptRedList, spellName)
end
------------------------------------------------------------------------------------------------------------------
-- касты обязательные к сбитию в любом случае
local RageList = {
    "Нечестивое бешенство",
    "Кровавая баня",
    "Исступление",
    "Ярость берсерка",
    "Безрассудство",
    "Отражение заклинания",
    "Дикий рев",
    "Бешенство совуха"
}

function InRage(target)
    if target == nil then target = "target" end
    return HasBuff(RageList, 1 , target)
end

------------------------------------------------------------------------------------------------------------------
local AlertList = {
    "Божественный щит",
    "Вихрь клинков", 
    "Стылая кровь",
    "Гнев карателя",
    "Призыв горгульи",
    "PvP-аксессуар",
    "Каждый за себя",
    "Озарение",
    "Святая клятва",
    "Питье",
    "Длань свободы",
    "Воля Отрекшихся",
    "Перерождение"
}

function InAlertList(spellName)
    return tContains(AlertList, spellName)
end
------------------------------------------------------------------------------------------------------------------
function IsNotAttack(target)
    if not target then target = "target" end
    -- не бьем в имун
    local stop = false
    local msg = ""
    if not CanAttack(target) then 
        msg = msg .. CanAttackInfo .. " "
        stop = true 
    else
        if not stop and not UnitAffectingCombat("target") then 
            msg = msg .. "Цель не в бою "
            stop = true
        end
        if not stop then
            -- чтоб контроли не сбивать
            local aura = HasDebuff(SappedList, 0.01, target)
            if aura then 
                msg = msg .. "На цели " .. aura .. " "
                result = true
            end
        end
        if stop and IsAttack() then
            msg = msg .. "(Force!)"
            stop = false
        end
        if (stop) then
            RunMacroText("/stopattack")
        else
            RunMacroText("/startattack [nostealth]")
        end    
    end
    
    if msg ~= "" then chat(target..": " .. msg) end
    return stop
end