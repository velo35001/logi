-- Авто-телепорт с прямым подключением к Telegram API
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

-- Переменные состояния
local isTeleporting = false
local currentServerId = ""
local retryCount = 0
local lastUpdateId = 0 -- Для отслеживания обработанных сообщений

-- Функция получения сообщений из Telegram
function getTelegramMessages()
    local success, response = pcall(function()
        local url = TELEGRAM_API_URL .. "/getUpdates?offset=" .. (lastUpdateId + 1) .. "&timeout=10"
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
end

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

-- Функция проверки новых сообщений от бота
function checkForNewServers()
    if isTeleporting then return end
    
    local updates = getTelegramMessages()
    
    for _, update in ipairs(updates) do
        if update.update_id > lastUpdateId then
            lastUpdateId = update.update_id
            
            -- Проверяем, что сообщение из нужного чата
            if update.message and update.message.chat and tostring(update.message.chat.id) == TELEGRAM_CHAT_ID then
                local messageText = update.message.text
                
                if messageText and hasTargetObjects(messageText) then
                    local serverId = extractServerId(messageText)
                    if serverId then
                        print("🎯 Найдено подходящее сообщение от бота!")
                        print("📝 Текст: " .. string.sub(messageText, 1, 100) .. "...")
                        attemptTeleport(serverId)
                        return true
                    end
                end
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

-- Ручной запуск телепорта (на случай если нужно принудительно телепортироваться)
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

-- Функция для просмотра текущих целевых объектов
function showTargetObjects()
    print("🎯 Текущие целевые объекты: " .. table.concat(TARGET_OBJECTS, ", "))
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
    print("🔍 Начинаем мониторинг Telegram сообщений...")
    
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
    local testUpdates = getTelegramMessages()
    if #testUpdates > 0 then
        print("✅ Соединение с Telegram API установлено!")
    else
        print("⚠️ Не удалось получить сообщения от Telegram. Проверьте токен и chat_id.")
    end
end)

-- Интерфейс для пользователя
print("========================================")
print("🤖 ТЕЛЕГРАМ АВТО-ТЕЛЕПОРТ v3.0")
print("👤 Chat ID: " .. TELEGRAM_CHAT_ID)
print("🎯 Цели: " .. table.concat(TARGET_OBJECTS, ", "))
print("⚡ Мгновенные переподключения АКТИВНЫ")
print("🔢 Макс. попыток: " .. MAX_RETRY_ATTEMPTS)
print("----------------------------------------")
print("📝 Команды:")
print('manualTeleport("server-id") - ручной телепорт')
print('addTargetObject("Новый объект") - добавить цель')
print('showTargetObjects() - показать цели')
print("========================================")
