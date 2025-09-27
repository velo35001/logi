-- Авто-телепорт с фильтрацией по свежим сообщениям
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

-- Конфигурация Telegram API
local TELEGRAM_BOT_TOKEN = "8158106101:AAGTaP3CEjnWh1rjNjj7UlqfJisani8Gwz8"
local TELEGRAM_CHAT_ID = "1090955422"
local TELEGRAM_API_URL = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN

-- Конфигурация скрипта
local TARGET_OBJECTS = {"Dragon Cannelloni", "Strawberry Elephant"}
local GAME_ID = 109983668079237
local MAX_RETRY_ATTEMPTS = 50
local NORMAL_RETRY_DELAY = 2
local CHECK_INTERVAL = 3 -- Проверка каждые 3 секунды
local MAX_MESSAGE_AGE = 2 -- Максимальная давность сообщения (в количестве сообщений)

-- Переменные состояния
local isTeleporting = false
local currentServerId = ""
local retryCount = 0
local processedMessageIds = {} -- Храним ID обработанных сообщений
local lastMessageTime = 0 -- Время последнего обработанного сообщения

-- Функция получения сообщений из Telegram
function getTelegramMessages()
    local success, response = pcall(function()
        local url = TELEGRAM_API_URL .. "/getUpdates?timeout=10"
        return game:HttpGet(url)
    end)
    
    if success then
        local data = HttpService:JSONDecode(response)
        if data.ok and data.result then
            return data.result
        else
            print("❌ Ошибка Telegram API: " .. tostring(data.description))
        end
    else
        print("❌ Ошибка HTTP запроса: " .. tostring(response))
    end
    
    return {}
end}

-- Функция проверки наличия целевых объектов
function hasTargetObjects(messageText)
    if not messageText then return false end
    
    for _, objectName in pairs(TARGET_OBJECTS) do
        if string.find(messageText, objectName) then
            return true
        end
    end
    return false
end

-- Функция извлечения serverId из сообщения
function extractServerId(messageText)
    -- Ищем serverId в формате UUID
    local pattern = "[%x]+%-[%x]+%-[%x]+%-[%x]+%-[%x]+"
    local serverId = messageText:match(pattern)
    
    -- Альтернативный поиск в строке телепорта
    if not serverId then
        serverId = messageText:match("TeleportToPlaceInstance%(%d+,%s*'([^']+)'%)")
    end
    
    return serverId
end

-- Функция для получения только свежих сообщений (1-2 последних)
function getFreshMessages()
    local updates = getTelegramMessages()
    local freshMessages = {}
    
    -- Сортируем сообщения по времени (новые сначала)
    table.sort(updates, function(a, b)
        return (a.message and a.message.date or a.update_id) > (b.message and b.message.date or b.update_id)
    end)
    
    -- Берем только последние MAX_MESSAGE_AGE сообщений
    for i = 1, math.min(MAX_MESSAGE_AGE, #updates) do
        local update = updates[i]
        if update.message and update.message.chat and tostring(update.message.chat.id) == TELEGRAM_CHAT_ID then
            -- Проверяем, что сообщение не старше 10 минут
            local messageTime = update.message.date or 0
            local currentTime = os.time()
            
            if currentTime - messageTime < 600 then -- 10 минут в секундах
                table.insert(freshMessages, update)
            end
        end
    end
    
    return freshMessages
end

-- Функция проверки новых сообщений от бота
function checkForNewServers()
    if isTeleporting then return end
    
    local freshMessages = getFreshMessages()
    
    for _, update in ipairs(freshMessages) do
        local messageId = update.message.message_id
        local messageText = update.message.text
        
        -- Проверяем, не обрабатывали ли уже это сообщение
        if not processedMessageIds[messageId] and messageText and hasTargetObjects(messageText) then
            local serverId = extractServerId(messageText)
            if serverId then
                -- Помечаем сообщение как обработанное
                processedMessageIds[messageId] = true
                lastMessageTime = update.message.date or os.time()
                
                -- Ограничиваем размер таблицы обработанных сообщений
                if table.count(processedMessageIds) > 20 then
                    -- Удаляем самые старые записи
                    local oldestId = nil
                    for id, _ in pairs(processedMessageIds) do
                        if not oldestId or id < oldestId then
                            oldestId = id
                        end
                    end
                    if oldestId then
                        processedMessageIds[oldestId] = nil
                    end
                end
                
                print("🎯 Найдено свежее сообщение от бота!")
                print("📝 Время: " .. os.date("%H:%M:%S", update.message.date))
                print("📋 Текст: " .. string.sub(messageText, 1, 80) .. "...")
                attemptTeleport(serverId)
                return true
            end
        end
    end
    
    return false
end

-- Основная функция телепорта с мгновенными повторными попытками
function attemptTeleport(serverId)
    if isTeleporting or retryCount >= MAX_RETRY_ATTEMPTS then
        if retryCount >= MAX_RETRY_ATTEMPTS then
            print("🚫 Достигнут лимит попыток! Сброс...")
            resetTeleportState()
        end
        return
    end
    
    isTeleporting = true
    currentServerId = serverId
    retryCount = retryCount + 1
    
    print("🔄 Попытка #" .. retryCount .. " для сервера: " .. serverId)
    
    local success, errorMessage = pcall(function()
        TeleportService:TeleportToPlaceInstance(GAME_ID, serverId)
    end)
    
    if not success then
        handleTeleportError(errorMessage)
    else
        print("✅ Запрос телепортации отправлен...")
    end
end

-- Обработка ошибок телепортации (без задержки для переполненных серверов)
function handleTeleportError(errorMessage)
    isTeleporting = false
    local errorText = tostring(errorMessage)
    
    print("❌ Ошибка: " .. errorText)
    
    -- Проверяем тип ошибки
    if string.find(errorText:lower(), "full", 1, true) or 
       string.find(errorText:lower(), "переполнен", 1, true) or
       string.find(errorText:lower(), "заполнен", 1, true) or
       string.find(errorText:lower(), "capacity", 1, true) then
        
        print("⚠️ Сервер переполнен! Мгновенная повторная попытка...")
        -- НЕТ ЗАДЕРЖКИ - мгновенный повтор
        attemptTeleport(currentServerId)
        
    else
        -- Для других ошибок небольшая задержка
        print("⏱ Другая ошибка. Повтор через " .. NORMAL_RETRY_DELAY .. " сек...")
        wait(NORMAL_RETRY_DELAY)
        attemptTeleport(currentServerId)
    end
end

-- Сброс состояния телепорта
function resetTeleportState()
    isTeleporting = false
    retryCount = 0
    currentServerId = ""
    print("🔄 Состояние сброшено, готов к новым серверам")
end

-- Ручной запуск телепорта
function manualTeleport(serverId)
    if serverId and #serverId > 10 then
        resetTeleportState()
        attemptTeleport(serverId)
    else
        print("❌ Неверный serverId!")
    end
end

-- Функция для добавления новых целевых объектов
function addTargetObject(objectName)
    table.insert(TARGET_OBJECTS, objectName)
    print("✅ Добавлен новый объект для поиска: " .. objectName)
end

-- Функция для очистки истории сообщений
function clearMessageHistory()
    processedMessageIds = {}
    lastMessageTime = 0
    print("🗑 История сообщений очищена")
end

-- Функция для изменения максимального возраста сообщений
function setMaxMessageAge(age)
    MAX_MESSAGE_AGE = age
    print("📅 Максимальный возраст сообщений установлен: " .. age)
end

-- Обработчик успешной телепортации
Players.PlayerAdded:Connect(function(joinedPlayer)
    if joinedPlayer == player then
        print("🎉 Успешно подключились к серверу!")
        resetTeleportState()
    end
end)

-- Основной цикл проверки сообщений
spawn(function()
    print("🔍 Начинаем мониторинг СВЕЖИХ Telegram сообщений...")
    
    while true do
        if not isTeleporting then
            local found = checkForNewServers()
            if not found then
                -- Тихий режим - не спамим в консоль если ничего не найдено
            end
        end
        wait(CHECK_INTERVAL)
    end
end)

-- Проверка соединения с Telegram при старте
spawn(function()
    wait(2)
    local testMessages = getFreshMessages()
    if #testMessages > 0 then
        print("✅ Соединение с Telegram API установлено!")
        print("📊 Доступно свежих сообщений: " .. #testMessages)
    else
        print("⚠️ Не удалось получить сообщения от Telegram. Проверьте токен и chat_id.")
    end
end)

-- Интерфейс для пользователя
print("========================================")
print("🤖 ТЕЛЕГРАМ АВТО-ТЕЛЕПОРТ v4.0")
print("👤 Chat ID: " .. TELEGRAM_CHAT_ID)
print("🎯 Цели: " .. table.concat(TARGET_OBJECTS, ", "))
print("📅 Реагирует только на последние " .. MAX_MESSAGE_AGE .. " сообщения")
print("⚡ Мгновенные переподключения АКТИВНЫ")
print("🔢 Макс. попыток: " .. MAX_RETRY_ATTEMPTS)
print("----------------------------------------")
print("📝 Команды:")
print('manualTeleport("server-id") - ручной телепорт')
print('addTargetObject("Новый объект") - добавить цель')
print('clearMessageHistory() - очистить историю')
print('setMaxMessageAge(3) - изменить кол-во сообщений')
print("========================================")
