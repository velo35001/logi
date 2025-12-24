local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local HttpService = game:GetService('HttpService')
local TeleportService = game:GetService("TeleportService")

local INCOME_THRESHOLD = 10_000_000 
local DISCORD_WEBHOOK_URL = 'https://ptb.discord.com/api/webhooks/1452947300040179835/Wb4JjutYSknqSEexwxb7DVrSrK_zAiHXuQMAd7kEWtua9zQBpP0mzz2obwloOt595JJQ' -- Хук пользователя

local WEBHOOK_FREE = 'https://ptb.discord.com/api/webhooks/1452947300040179835/Wb4JjutYSknqSEexwxb7DVrSrK_zAiHXuQMAd7kEWtua9zQBpP0mzz2obwloOt595JJQ'
local WEBHOOK_SECRET = 'https://ptb.discord.com/api/webhooks/1452947300040179835/Wb4JjutYSknqSEexwxb7DVrSrK_zAiHXuQMAd7kEWtua9zQBpP0mzz2obwloOt595JJQ'
local WEBHOOK_ABUSE = 'https://ptb.discord.com/api/webhooks/1452947300040179835/Wb4JjutYSknqSEexwxb7DVrSrK_zAiHXuQMAd7kEWtua9zQBpP0mzz2obwloOt595JJQ'

local JOIN_LINK = "https://fern.wtf/joiner?placeId="..game.PlaceId.."&gameInstanceId="..game.JobId

local FREE_MIN = 1_000_000 -- 1M/s
local FREE_MAX = 10_000_000 -- 10M/s
local SECRET_MIN = 10_000_000 -- 10M/s
local SECRET_MAX = 120_000_000 -- 120M/s
local ABUSE_MIN = 120_000_000 -- 120M/s

print('🎯 Brainrot Scanner v2.0 | JobId:', game.JobId)

local OBJECTS = {
    ['Garama and Madundung'] = { emoji = '🧂', important = true },
    ['Dragon Cannelloni'] = { emoji = '🐲', important = true },
    ['La Supreme Combinasion'] = { emoji = '🔫', important = true },
    ['Strawberry Elephant'] = { emoji = '🐘', important = true },
    ['Ketchuru and Musturu'] = { emoji = '🍾', important = true },
    ['La Secret Combinasion'] = { emoji = '❓', important = true },
    ['Burguro And Fryuro'] = { emoji = '🍔', important = true },
    ['Spooky and Pumpky'] = { emoji = '🎃', important = true },
    ['Meowl'] = { emoji = '🐈', important = true },
    ['La Casa Boo'] = { emoji = '👁‍🗨', important = true },
    ['Headless Horseman'] = { emoji = '🐴', important = true },
    ['Cooki and Milki'] = { emoji = '🍪', important = true },
    ['Fragrama and Chocrama'] = { emoji = '🍫', important = true },
    ['Lavadorito Spinito'] = { emoji = '📺', important = true },
    ['La Ginger Sekolah'] = { emoji = '🎄', important = true },
    ['Capitano Moby'] = { emoji = '🛥', important = true },
}

local ALWAYS_IMPORTANT = {}
for name, cfg in pairs(OBJECTS) do
    if cfg.important then
        ALWAYS_IMPORTANT[name] = true
    end
end

local sentMessages = {}

-- Настройки автотелепорта
local AUTO_TELEPORT_SETTINGS = {
    GAME_ID = 109983668079237,
    PASTEFY_URL = "https://raw.githubusercontent.com/velo35001/logi/refs/heads/main/log.txt",
    COOLDOWN_TIME = 5 * 60,
    COUNTDOWN_TIME = 1,
    ERROR_RETRY_DELAY = 2,
    SUCCESS_DELAY = 1,
    ENABLED = true, -- Включить/выключить автотелепорт
    SCAN_BEFORE_TELEPORT = true, -- Сканировать перед телепортацией
    MIN_OBJECTS_FOR_TELEPORT = 0, -- Минимальное количество объектов для телепортации (0 = всегда телепортироваться)
    TELEPORT_DELAY = 1 -- Задержка перед телепортацией (секунды)
}

local SERVER_LIST = {}
local BLACKLIST = {}
local SHOW_COUNTDOWN = true

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

-- 🔍 ФУНКЦИЯ СКАНИРОВАНИЯ DEBRIS FOLDER
local function scanDebrisForIncome()
    local DebrisFolder = workspace:FindFirstChild("Debris")
    if not DebrisFolder then 
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
                table.insert(results, { name = name, gen = genNum, location = "Debris" })
            end
        end
    end

    return results
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

        -- Запускаем все сканеры
        local allSources = {
            scanPlots(),
            scanRunway(),
            scanAllOverheads(),
            scanPlayerGui(),
            scanDebrisForIncome(), -- Добавлен сканер Debris
        }

        -- Объединяем результаты
        for _, source in ipairs(allSources) do
            for _, item in ipairs(source) do
                table.insert(collected, item)
            end
        end

        -- Убираем дубликаты
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

local function shouldShow(name, gen)
    if ALWAYS_IMPORTANT[name] then
        return true
    end
    return (type(gen) == 'number') and gen >= INCOME_THRESHOLD
end

-- Определяет, куда отправлять объект: 'user', 'free', 'secret', 'abuse', или nil (не отправлять)
local function getDestination(name, gen)
    if not name or not gen or type(gen) ~= 'number' then
        return nil
    end
    
    -- Проверяем, есть ли объект в списке важных (important = true)
    if ALWAYS_IMPORTANT[name] then
        -- Важные объекты всегда отправляются пользователю
        return 'user'
    end
    
    -- Все остальные объекты распределяются по каналам по доходу
    if gen >= ABUSE_MIN then
        return 'abuse'
    elseif gen >= SECRET_MIN then
        return 'secret'
    elseif gen >= FREE_MIN then
        return 'free'
    end
    
    return nil
end

-- Проверяет, был ли объект уже отправлен
local function wasSent(name, gen, destination)
    local key = string.format('%s:%d:%s', name, gen, destination)
    return sentMessages[key] == true
end

-- Отмечает объект как отправленный
local function markAsSent(name, gen, destination)
    local key = string.format('%s:%d:%s', name, gen, destination)
    sentMessages[key] = true
end

-- 📤 DISCORD УВЕДОМЛЕНИЯ
local function getRequester()
    return http_request
        or request
        or (syn and syn.request)
        or (fluxus and fluxus.request)
        or (KRNL_HTTP and KRNL_HTTP.request)
end

-- Отправляет уведомление в указанный канал
local function sendToChannel(objects, destination, channelName)
    if #objects == 0 then
        return false
    end
    
    local req = getRequester()
    if not req then
        warn('❌ Нет HTTP API в executor')
        return false
    end
    
    -- Определяем webhook URL
    local webhookUrl = nil
    if destination == 'user' then
        webhookUrl = DISCORD_WEBHOOK_URL
    elseif destination == 'free' then
        webhookUrl = WEBHOOK_FREE
    elseif destination == 'secret' then
        webhookUrl = WEBHOOK_SECRET
    elseif destination == 'abuse' then
        webhookUrl = WEBHOOK_ABUSE
    end
    
    if not webhookUrl or webhookUrl == '' then
        warn(string.format('❌ Webhook для %s не настроен', channelName))
        return false
    end
    
    local jobId = game.JobId
    local placeId = game.PlaceId
    
    -- Сортируем по доходу (по убыванию)
    table.sort(objects, function(a, b)
        return a.gen > b.gen
    end)
    
    -- Формируем красивый список (максимум 10)
    local objectsList = {}
    for i = 1, math.min(10, #objects) do
        local obj = objects[i]
        local emoji = (OBJECTS[obj.name] and OBJECTS[obj.name].emoji) or '💰'
        local mark = ALWAYS_IMPORTANT[obj.name] and '❗ ' or ''
        table.insert(
            objectsList,
            string.format(
                '%s%s %s (%s)',
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
        "local ts = game:GetService('TeleportService'); ts:TeleportToPlaceInstance(%d, '%s')",
        placeId,
        jobId
    )
    
    local title = destination == 'user' and '🕷️ | Sammy Logs ON TOP!' or string.format('🕷️ | Found objects in Steal a brainrot! (%s)', channelName)
    
    local payload = {
        username = '🕷️ | Sammy Product',
        embeds = {
            {
                title = title,
                color = 0xf44336,
                fields = {
                    {
                        name = '🆔 Job ID',
                        value = string.format('```%s```', jobId),
                        inline = false,
                    },
                    {
                        name = '💰 Objects:',
                        value = string.format('```\n%s\n```', objectsText),
                        inline = false,
                    },
                    {
                        name = '🚀 Teleport command:',
                        value = string.format('```lua\n%s\n```', teleportText),
                        inline = false,
                    },
                    {
                        name = '🔗 Join Link:',
                        value =  string.format('\n%s\n', JOIN_LINK),
                        inline = false,
                    },

                },
                footer = {
                    text = string.format(
                        'Total: %d Brainrots • %s',
                        #objects,
                        os.date('%H:%M:%S')
                    ),
                },
                timestamp = DateTime.now():ToIsoDate(),
            },
        },
    }
    
    print(string.format('📤 Отправляю %d объектов в %s', #objects, channelName))
    
    local ok, res = pcall(function()
        return req({
            Url = webhookUrl,
            Method = 'POST',
            Headers = { ['Content-Type'] = 'application/json' },
            Body = HttpService:JSONEncode(payload),
        })
    end)
    
    if ok then
        print(string.format('✅ Уведомление отправлено в %s!', channelName))
        -- Отмечаем все объекты как отправленные
        for _, obj in ipairs(objects) do
            markAsSent(obj.name, obj.gen, destination)
        end
        return true
    else
        warn(string.format('❌ Ошибка отправки в %s:', channelName), res)
        return false
    end
end

-- 🎮 ГЛАВНАЯ ФУНКЦИЯ
local function scanAndNotify()
    print('🔍 Сканирую все объекты...')
    local allFound = collectAll(8.0) -- 8 секунд таймаут

    -- Распределяем объекты по каналам
    local forUser = {} -- Объекты для пользователя (important или исключения выше порога)
    local forFree = {} -- Объекты для канала free (1-10M/s)
    local forSecret = {} -- Объекты для канала secret (10-120M/s)
    local forAbuse = {} -- Объекты для канала abuse (120M/s+)
    
    for _, obj in ipairs(allFound) do
        -- Проверяем, был ли объект уже отправлен
        local destination = getDestination(obj.name, obj.gen)
        
        if destination then
            -- Проверяем, не был ли уже отправлен
            if wasSent(obj.name, obj.gen, destination) then
                print(string.format('⏭️ Объект %s уже был отправлен в %s', obj.name, destination))
            else
                if destination == 'user' then
                    table.insert(forUser, obj)
                elseif destination == 'free' then
                    table.insert(forFree, obj)
                elseif destination == 'secret' then
                    table.insert(forSecret, obj)
                elseif destination == 'abuse' then
                    table.insert(forAbuse, obj)
                end
            end
        end
    end

    -- Вывод в консоль
    print('Найдено всего объектов:', #allFound)
    print('Для пользователя:', #forUser)
    print('Для free:', #forFree)
    print('Для secret:', #forSecret)
    print('Для abuse:', #forAbuse)

    -- Выводим все объекты в консоль
    for _, obj in ipairs(forUser) do
        local emoji = (OBJECTS[obj.name] and OBJECTS[obj.name].emoji) or '💰'
        local mark = ALWAYS_IMPORTANT[obj.name] and '❗ ' or ''
        print(
            string.format(
                '%s%s %s: %s (%s) → USER',
                mark,
                emoji,
                obj.name,
                formatIncomeNumber(obj.gen),
                obj.location or 'Unknown'
            )
        )
    end
    
    for _, obj in ipairs(forFree) do
        local emoji = (OBJECTS[obj.name] and OBJECTS[obj.name].emoji) or '💰'
        print(
            string.format(
                '%s %s: %s (%s) → FREE',
                emoji,
                obj.name,
                formatIncomeNumber(obj.gen),
                obj.location or 'Unknown'
            )
        )
    end
    
    for _, obj in ipairs(forSecret) do
        local emoji = (OBJECTS[obj.name] and OBJECTS[obj.name].emoji) or '💰'
        print(
            string.format(
                '%s %s: %s (%s) → SECRET',
                emoji,
                obj.name,
                formatIncomeNumber(obj.gen),
                obj.location or 'Unknown'
            )
        )
    end
    
    for _, obj in ipairs(forAbuse) do
        local emoji = (OBJECTS[obj.name] and OBJECTS[obj.name].emoji) or '💰'
        print(
            string.format(
                '%s %s: %s (%s) → ABUSE',
                emoji,
                obj.name,
                formatIncomeNumber(obj.gen),
                obj.location or 'Unknown'
            )
        )
    end

    -- Отправляем уведомления (только одно сообщение в канал с наивысшим приоритетом)
    -- Приоритеты: USER > ABUSE > SECRET > FREE
    local sent = false
    
    -- Приоритет 1: USER (высший)
    if #forUser > 0 then
        sendToChannel(forUser, 'user', 'USER')
        sent = true
    -- Приоритет 2: ABUSE
    elseif #forAbuse > 0 then
        sendToChannel(forAbuse, 'abuse', 'ABUSE')
        sent = true
    -- Приоритет 3: SECRET
    elseif #forSecret > 0 then
        sendToChannel(forSecret, 'secret', 'SECRET')
        sent = true
    -- Приоритет 4: FREE (низший)
    elseif #forFree > 0 then
        sendToChannel(forFree, 'free', 'FREE')
        sent = true
    end
    
    if not sent then
        print('🔍 Нет объектов для уведомления')
    end
    
    -- Возвращаем количество найденных объектов для автотелепорта
    return #allFound
end

-- 🚀 СИСТЕМА АВТОТЕЛЕПОРТА
local function IsTeleportError(err)
    local errorStr = tostring(err)
    return string.find(errorStr, "Unauthorized") ~= nil or
           string.find(errorStr, "cannot be joined") ~= nil or
           string.find(errorStr, "Teleport") ~= nil or
           string.find(errorStr, "experience is full") ~= nil or
           string.find(errorStr, "GameFull") ~= nil
end

local function LoadServers()
    local success, response = pcall(function()
        return game:HttpGet(AUTO_TELEPORT_SETTINGS.PASTEFY_URL)
    end)
    
    if not success then 
        warn("❌ Ошибка загрузки списка серверов:", tostring(response):sub(1, 100))
        return {}
    end
    
    local servers = {}
    for serverId in string.gmatch(response, "([a-f0-9%-]+)") do
        table.insert(servers, serverId)
    end
    return servers
end

local function IsServerAvailable(serverId)
    if not BLACKLIST[serverId] then return true end
    return (os.time() - BLACKLIST[serverId]) > AUTO_TELEPORT_SETTINGS.COOLDOWN_TIME
end

local function TryTeleport(target)
    if SHOW_COUNTDOWN then
        for i = AUTO_TELEPORT_SETTINGS.COUNTDOWN_TIME, 1, -1 do
            task.wait(1)
        end
        SHOW_COUNTDOWN = false
    end
    
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(
            AUTO_TELEPORT_SETTINGS.GAME_ID,
            target,
            Players.LocalPlayer
        )
    end)
    
    if not success then
        if IsTeleportError(err) then
            warn("⛔️ Ошибка телепортации:", tostring(err):match("^[^\n]+"):sub(1, 100))
        else
            warn("⚠️ Неизвестная ошибка:", tostring(err):match("^[^\n]+"):sub(1, 100))
        end
        BLACKLIST[target] = os.time()
        task.wait(AUTO_TELEPORT_SETTINGS.ERROR_RETRY_DELAY)
        return false
    end
    
    task.wait(AUTO_TELEPORT_SETTINGS.SUCCESS_DELAY)
    return true
end

local function TeleportLoop()
    if not AUTO_TELEPORT_SETTINGS.ENABLED then
        print("🚫 Автотелепорт отключен в настройках")
        return
    end
    
    print("⏳ Ожидание перед телепортацией...")
    task.wait(AUTO_TELEPORT_SETTINGS.TELEPORT_DELAY)
    
    while true do
        SERVER_LIST = LoadServers()
        if #SERVER_LIST == 0 then
            warn("⚠️ Список серверов пуст, повтор через 10 сек...")
            task.wait(10)
        else
            print("✅ Доступно серверов: " .. #SERVER_LIST)
            break
        end
    end
    
    while true do
        local available = {}
        for _, serverId in ipairs(SERVER_LIST) do
            if IsServerAvailable(serverId) then
                table.insert(available, serverId)
            end
        end
        
        if #available == 0 then
            warn("⏳ Все серверы на кд, ожидание " .. AUTO_TELEPORT_SETTINGS.COOLDOWN_TIME .. " сек...")
            SHOW_COUNTDOWN = true
            task.wait(AUTO_TELEPORT_SETTINGS.COOLDOWN_TIME)
            SERVER_LIST = LoadServers()
        else
            local target = available[math.random(1, #available)]
            print("🔍 Попытка подключения к: " .. target:sub(1, 8) .. "...")
            
            if TryTeleport(target) then
                print("🚀 Успешное подключение!")
                break
            end
        end
    end
end

local function StartAutoTeleport()
    task.spawn(function()
        if not AUTO_TELEPORT_SETTINGS.ENABLED then
            return
        end
        
        -- Ждем минимальную загрузку
        if not Players.LocalPlayer then
            Players:WaitForChild("LocalPlayer", 10)
        end
        task.wait(0.5)
        
        -- Запускаем основной цикл
        while true do
            local success, err = pcall(TeleportLoop)
            if not success then
                warn("🛑 Критическая ошибка:", tostring(err):sub(1, 100))
                SHOW_COUNTDOWN = true
                task.wait(5)
            end
        end
    end)
end

-- 🚀 ЗАПУСК
print('🎯 === BRAINROT INCOME SCANNER ЗАПУЩЕН ===')
local foundObjects = scanAndNotify()

-- Запускаем автотелепорт только если найдено мало объектов
if foundObjects <= AUTO_TELEPORT_SETTINGS.MIN_OBJECTS_FOR_TELEPORT then
    print(string.format("📊 Найдено %d объектов (минимум для телепортации: %d)", foundObjects, AUTO_TELEPORT_SETTINGS.MIN_OBJECTS_FOR_TELEPORT))
    StartAutoTeleport()
else
    print("✅ Достаточно объектов на сервере, автотелепорт не запущен")
end

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
        local newFoundObjects = scanAndNotify()
        
        -- Проверяем, нужно ли телепортироваться после нового сканирования
        if AUTO_TELEPORT_SETTINGS.ENABLED and newFoundObjects <= AUTO_TELEPORT_SETTINGS.MIN_OBJECTS_FOR_TELEPORT then
            print("📊 Мало объектов, запускаю автотелепорт...")
            StartAutoTeleport()
        end
    end
end)

print('💡 Нажмите F для повторного сканирования')
print('📱 Discord webhook готов к отправке уведомлений')
print('🚀 Система автотелепорта активна')
