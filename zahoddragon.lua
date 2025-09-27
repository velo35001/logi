local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

-- Конфигурация Telegram API
local BOT_TOKEN = "7994146351:AAE_w1jgiZRvGHNG1jlTLyn7v8bvYyZe4Z8"
local CHAT_ID = "-1003189784409"
local API_URL = "https://api.telegram.org/bot" .. BOT_TOKEN

-- Конфигурация скрипта
local TARGET_OBJECTS = {"Dragon Cannelloni", "Strawberry Elephant"}
local GAME_ID = 109983668079237
local MAX_RETRIES = 50
local CHECK_DELAY = 2

-- Переменные состояния
local isTeleporting = false
local currentServerId = ""
local retryCount = 0
local lastUpdateId = 0
local scriptStartTime = os.time()
local initialized = false
local allProcessedMessages = {}

-- Функция для HTTP запросов
function httpGet(url)
    local success, result = pcall(function()
        return game:HttpGet(url, true)
    end)
    return success, result
end

-- ПРАВИЛЬНАЯ функция получения сообщений через getUpdates
function getMessages()
    local url = API_URL .. "/getUpdates?timeout=10&offset=" .. (lastUpdateId + 1)
    local success, response = httpGet(url)
    
    if success and response then
        local data = HttpService:JSONDecode(response)
        if data.ok and data.result then
            local messages = {}
            
            for _, update in ipairs(data.result) do
                -- Обновляем lastUpdateId
                if update.update_id > lastUpdateId then
                    lastUpdateId = update.update_id
                end
                
                -- Обрабатываем только сообщения из нужного чата
                if update.message and update.message.chat and tostring(update.message.chat.id) == CHAT_ID then
                    table.insert(messages, update.message)
                end
            end
            
            return messages
        else
            if data.description then
                print("❌ Ошибка API:", data.description)
            end
        end
    else
        print("❌ Ошибка HTTP запроса")
    end
    return {}
end

-- Альтернативный метод через getChat (для получения информации о чате)
function getChatInfo()
    local url = API_URL .. "/getChat?chat_id=" .. CHAT_ID
    local success, response = httpGet(url)
    
    if success and response then
        local data = HttpService:JSONDecode(response)
        if data.ok then
            print("✅ Информация о чате:")
            print("   Название:", data.result.title or "Нет названия")
            print("   Тип:", data.result.type or "Неизвестно")
            return true
        end
    end
    return false
end

-- Функция инициализации
function initializeBot()
    print("🔍 Инициализация бота...")
    
    -- Проверяем информацию о боте
    local url = API_URL .. "/getMe"
    local success, response = httpGet(url)
    
    if success and response then
        local data = HttpService:JSONDecode(response)
        if data.ok then
            print("✅ Бот: @" .. data.result.username)
        end
    end
    
    -- Проверяем информацию о чате
    if not getChatInfo() then
        print("❌ Не удалось получить информацию о чате. Убедитесь, что:")
        print("   - Бот добавлен в группу")
        print("   - Бот имеет права на чтение сообщений")
        print("   - CHAT_ID указан правильно")
    end
    
    -- Получаем последние сообщения для инициализации
    local messages = getMessages()
    local maxMessageId = 0
    
    for _, message in ipairs(messages) do
        if message.message_id > maxMessageId then
            maxMessageId = message.message_id
        end
        
        local senderInfo = "Unknown"
        if message.from then
            senderInfo = message.from.is_bot and "Bot" or "User"
            if message.from.username then
                senderInfo = senderInfo .. " @" .. message.from.username
            end
        end
        print("📄 Сообщение ID: " .. message.message_id .. " от " .. senderInfo)
    end
    
    initialized = true
    print("✅ Бот инициализирован. Последний update_id: " .. lastUpdateId)
end

function hasTargetObjects(messageText)
    if not messageText then return false end
    
    for _, target in ipairs(TARGET_OBJECTS) do
        if string.find(string.lower(messageText), string.lower(target)) then
            return true
        end
    end
    return false
end

function extractServerId(messageText)
    if not messageText then return nil end
    
    local patterns = {
        "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x",
        "%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x"
    }
    
    for _, pattern in ipairs(patterns) do
        local found = messageText:match(pattern)
        if found and (#found == 36 or #found == 32) then
            return found
        end
    end
    return nil
end

function extractObjectsPart(messageText)
    if not messageText then return "Нет информации об объектах" end
    
    local objectsStart = messageText:find("🚨 ВАЖНЫЕ ОБЪЕКТЫ:")
    if not objectsStart then
        objectsStart = messageText:find("ВАЖНЫЕ ОБЪЕКТЫ:")
        if not objectsStart then
            return messageText:gsub("\n", " "):sub(1, 80) .. "..."
        end
    end
    
    local objectsEnd = messageText:find("🚀 Телепорт:", objectsStart)
    if not objectsEnd then
        objectsEnd = messageText:find("Телепорт:", objectsStart)
    end
    if not objectsEnd then
        objectsEnd = #messageText
    end
    
    local objectsText = messageText:sub(objectsStart, objectsEnd - 1)
    objectsText = objectsText:gsub("^%s*\n*", ""):gsub("\n*%s*$", "")
    
    return objectsText
end

-- Основная функция телепортации
function teleportToServer(serverId)
    if isTeleporting then return end
    
    retryCount = retryCount + 1
    if retryCount > MAX_RETRIES then
        print("🚫 Превышено максимальное количество попыток")
        resetState()
        return
    end
    
    isTeleporting = true
    currentServerId = serverId
    
    print("🔄 Попытка телепортации #" .. retryCount .. " на сервер: " .. serverId)
    
    local success, errorMsg = pcall(function()
        TeleportService:TeleportToPlaceInstance(GAME_ID, serverId)
    end)
    
    if not success then
        handleTeleportError(errorMsg)
    else
        print("✅ Запрос телепортации отправлен")
    end
end

-- Обработка ошибок телепортации
function handleTeleportError(errorMsg)
    isTeleporting = false
    local errorText = tostring(errorMsg):lower()
    
    print("❌ Ошибка: " .. errorText)
    
    if errorText:find("full") or errorText:find("переполнен") or errorText:find("capacity") then
        print("⚡ Сервер переполнен! Мгновенный повтор...")
        wait(0.1)
        teleportToServer(currentServerId)
    else
        print("⏳ Повтор через 2 секунды...")
        wait(2)
        teleportToServer(currentServerId)
    end
end

-- Сброс состояния
function resetState()
    isTeleporting = false
    retryCount = 0
    currentServerId = ""
end

-- Создание меню уведомлений (остается без изменений)
function createNotificationMenu()
    -- ... (ваш существующий код создания меню)
end

local notificationMenu = createNotificationMenu()
local notifications = {}
local MAX_NOTIFICATIONS = 15

function addNotificationToMenu(messageText, serverId, isTarget, messageId, isFromBot)
    -- ... (ваш существующий код добавления уведомлений)
end

-- Исправленная функция проверки новых сообщений
function checkForNewMessages()
    if isTeleporting or not initialized then return false end
    
    local messages = getMessages()
    local foundTarget = false
    
    for _, message in ipairs(messages) do
        local messageId = message.message_id
        local messageText = message.text or message.caption
        
        -- Пропускаем сообщения без текста
        if not messageText then
            continue
        end
        
        -- Пропускаем уже обработанные сообщения
        if allProcessedMessages[messageId] then
            continue
        end
        
        allProcessedMessages[messageId] = true
        
        local serverId = extractServerId(messageText)
        if serverId then
            local isTarget = hasTargetObjects(messageText)
            local isFromBot = message.from and message.from.is_bot
            local senderName = "Unknown"
            
            if message.from then
                if message.from.username then
                    senderName = "@" .. message.from.username
                elseif message.from.first_name then
                    senderName = message.from.first_name
                end
            end
            
            print("📩 Новое сообщение от " .. senderName .. 
                  " (Бот: " .. tostring(isFromBot) .. ")" ..
                  " ID: " .. messageId)
            
            -- Добавляем в меню ВСЕ сообщения с serverId
            addNotificationToMenu(messageText, serverId, isTarget, messageId, isFromBot)
            
            -- Автотелепорт только для сообщений от ботов с целевыми объектами
            if isFromBot and isTarget and not foundTarget then
                print("🎯 Найдено подходящее сообщение от бота! ID: " .. messageId)
                teleportToServer(serverId)
                foundTarget = true
            end
        end
    end
    
    return foundTarget
end

-- Обработчик успешного подключения к серверу
player.CharacterAdded:Connect(function()
    print("🎉 Успешно подключились к серверу!")
    resetState()
end)

-- Основной цикл проверки сообщений
function startMonitoring()
    print("🔍 Инициализация скрипта...")
    
    -- Инициализируем бота
    initializeBot()
    
    print("✅ Скрипт готов! Ожидаю сообщения от бота...")
    
    while true do
        if not isTeleporting then
            checkForNewMessages()
        end
        wait(CHECK_DELAY)
    end
end

-- Запуск мониторинга
print("========================================")
print("🤖 ТЕЛЕГРАМ АВТО-ТЕЛЕПОРТ (ИСПРАВЛЕННЫЙ)")
print("👤 Chat ID: " .. CHAT_ID)
print("🎯 Авто-цели: " .. table.concat(TARGET_OBJECTS, ", "))
print("📱 Используется метод getUpdates")
print("========================================")

-- Запускаем мониторинг
spawn(startMonitoring)
