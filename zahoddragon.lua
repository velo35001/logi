-- Исправленная версия скрипта для отображения сообщений от бота
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

-- Конфигурация Telegram API
local BOT_TOKEN = "8158106101:AAGTaP3CEjnWh1rjNjj7UlqfJisani8Gwz8"
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
local lastProcessedMessageId = 0
local scriptStartTime = os.time()
local initialized = false
local allProcessedMessages = {} -- Храним все обработанные сообщения

-- Функция для HTTP запросов
function httpGet(url)
    local success, result = pcall(function()
        return game:HttpGet(url, true)
    end)
    return success, result
end

-- Функция получения ВСЕХ сообщений из чата (включая от бота)
function getAllChatMessages()
    local url = API_URL .. "/getChatHistory?chat_id=" .. CHAT_ID .. "&limit=10"
    local success, response = httpGet(url)
    
    if success and response then
        local data = HttpService:JSONDecode(response)
        if data.ok and data.result then
            return data.result.messages or {}
        end
    end
    return {}
end

-- Альтернативная функция через getUpdates (исправленная)
function getBotMessagesCorrected()
    local url = API_URL .. "/getUpdates?offset=" .. (lastProcessedMessageId + 1) .. "&timeout=5"
    local success, response = httpGet(url)
    
    if success and response then
        local data = HttpService:JSONDecode(response)
        if data.ok and data.result then
            -- Фильтруем сообщения из нужного чата
            local filteredMessages = {}
            for _, update in ipairs(data.result) do
                if update.message and update.message.chat and tostring(update.message.chat.id) == CHAT_ID then
                    table.insert(filteredMessages, update.message)
                end
            end
            return filteredMessages
        end
    end
    return {}
end

-- Функция получения сообщений через getChat (более надежная)
function getChatMessages()
    local url = API_URL .. "/getChat?chat_id=" .. CHAT_ID
    local success, response = httpGet(url)
    
    if success and response then
        -- Если чат доступен, получаем историю
        return getBotMessagesCorrected()
    else
        print("❌ Не удалось получить доступ к чату. Используем альтернативный метод.")
        return getBotMessagesCorrected()
    end
end

-- Функция инициализации
function initializeMessageFilter()
    print("🔍 Инициализация фильтра сообщений...")
    
    -- Получаем последние сообщения для инициализации
    local messages = getBotMessagesCorrected()
    local maxMessageId = 0
    
    for _, message in ipairs(messages) do
        if message.message_id > maxMessageId then
            maxMessageId = message.message_id
        end
    end
    
    if maxMessageId > 0 then
        lastProcessedMessageId = maxMessageId
        print("✅ Установлен последний message_id: " .. lastProcessedMessageId)
    else
        print("⚠️ Не удалось найти сообщения для инициализации")
    end
    
    initialized = true
end

-- Функция проверки наличия целевых объектов
function hasTargetObjects(messageText)
    if not messageText then return false end
    
    for _, target in ipairs(TARGET_OBJECTS) do
        if string.find(messageText, target) then
            return true
        end
    end
    return false
end

-- Функция извлечения serverId из сообщения
function extractServerId(messageText)
    if not messageText then return nil end
    
    local pattern = "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x"
    local found = messageText:match(pattern)
    
    if found and #found == 36 then
        return found
    end
    return nil
end

-- Функция для извлечения части с объектами
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

-- Создание меню уведомлений
function createNotificationMenu()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TelegramNotifications"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false
    
    local notificationMenu = Instance.new("Frame")
    notificationMenu.Name = "NotificationMenu"
    notificationMenu.Size = UDim2.new(0, 400, 0, 500)
    notificationMenu.Position = UDim2.new(0, 10, 0.5, -250)
    notificationMenu.AnchorPoint = Vector2.new(0, 0.5)
    notificationMenu.BackgroundColor3 = Color3.fromRGB(16, 14, 24)
    notificationMenu.BackgroundTransparency = 0.1
    notificationMenu.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = notificationMenu
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(95, 70, 160)
    stroke.Thickness = 2
    stroke.Parent = notificationMenu
    
    local header = Instance.new("TextLabel")
    header.Name = "Header"
    header.Text = "📱 Все уведомления от бота"
    header.Font = Enum.Font.GothamBold
    header.TextSize = 16
    header.TextColor3 = Color3.fromRGB(235, 225, 255)
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, 0, 0, 40)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.Parent = notificationMenu
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Text = "−"
    toggleButton.Font = Enum.Font.GothamBlack
    toggleButton.TextSize = 18
    toggleButton.Size = UDim2.new(0, 30, 0, 30)
    toggleButton.Position = UDim2.new(1, -35, 0, 5)
    toggleButton.BackgroundColor3 = Color3.fromRGB(148, 0, 211)
    toggleButton.TextColor3 = Color3.new(1, 1, 1)
    toggleButton.AutoButtonColor = true
    toggleButton.Parent = notificationMenu
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 6)
    toggleCorner.Parent = toggleButton
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "NotificationsScroll"
    scrollFrame.Size = UDim2.new(1, -10, 1, -50)
    scrollFrame.Position = UDim2.new(0, 5, 0, 45)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.Parent = notificationMenu
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = scrollFrame
    
    local isMenuVisible = true
    
    toggleButton.MouseButton1Click:Connect(function()
        isMenuVisible = not isMenuVisible
        if isMenuVisible then
            notificationMenu.Size = UDim2.new(0, 400, 0, 500)
            toggleButton.Text = "−"
        else
            notificationMenu.Size = UDim2.new(0, 400, 0, 40)
            toggleButton.Text = "+"
        end
    end)
    
    return scrollFrame
end

-- Глобальная переменная для меню
local notificationMenu = createNotificationMenu()
local notifications = {}
local MAX_NOTIFICATIONS = 15

-- Функция добавления уведомления в меню
function addNotificationToMenu(messageText, serverId, isTarget, messageId, isFromBot)
    if not notificationMenu then return end
    
    -- Проверяем, не обрабатывали ли уже это сообщение
    if allProcessedMessages[messageId] then
        return
    end
    allProcessedMessages[messageId] = true
    
    -- Очищаем старые уведомления если превышен лимит
    while #notifications >= MAX_NOTIFICATIONS do
        local oldestNotification = table.remove(notifications, 1)
        if oldestNotification and oldestNotification.frame then
            oldestNotification.frame:Destroy()
        end
    end
    
    -- Извлекаем только часть с объектами
    local objectsText = extractObjectsPart(messageText)
    
    -- Создаем фрейм для уведомления
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Size = UDim2.new(1, 0, 0, 70)
    notificationFrame.BackgroundColor3 = isTarget and Color3.fromRGB(40, 160, 120) or Color3.fromRGB(160, 60, 80)
    notificationFrame.BackgroundTransparency = 0.2
    notificationFrame.Parent = notificationMenu
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notificationFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = isTarget and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(95, 70, 160)
    stroke.Thickness = 1.5
    stroke.Parent = notificationFrame
    
    -- Индикатор отправителя
    local senderIndicator = Instance.new("TextLabel")
    senderIndicator.Text = isFromBot and "🤖 БОТ" or "👤 ВЫ"
    senderIndicator.Font = Enum.Font.GothamBold
    senderIndicator.TextSize = 10
    senderIndicator.TextColor3 = isFromBot and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(255, 200, 100)
    senderIndicator.BackgroundTransparency = 1
    senderIndicator.Size = UDim2.new(0, 50, 0, 15)
    senderIndicator.Position = UDim2.new(1, -55, 0, 2)
    senderIndicator.TextXAlignment = Enum.TextXAlignment.Right
    senderIndicator.Parent = notificationFrame
    
    -- Текст уведомления
    local textLabel = Instance.new("TextLabel")
    textLabel.Text = objectsText
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextSize = 12
    textLabel.TextColor3 = Color3.fromRGB(235, 225, 255)
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, -80, 1, -25)
    textLabel.Position = UDim2.new(0, 5, 0, 5)
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Top
    textLabel.TextWrapped = true
    textLabel.Parent = notificationFrame
    
    -- Время и ID
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Text = "ID: " .. messageId .. " | " .. os.date("%H:%M:%S")
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 10
    infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Size = UDim2.new(1, -80, 0, 15)
    infoLabel.Position = UDim2.new(0, 5, 1, -18)
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.Parent = notificationFrame
    
    -- Кнопка телепорта
    local teleportButton = Instance.new("TextButton")
    teleportButton.Text = "🚀"
    teleportButton.Font = Enum.Font.GothamBold
    teleportButton.TextSize = 16
    teleportButton.Size = UDim2.new(0, 60, 0, 25)
    teleportButton.Position = UDim2.new(1, -65, 0.5, -12)
    teleportButton.AnchorPoint = Vector2.new(1, 0.5)
    teleportButton.BackgroundColor3 = Color3.fromRGB(148, 0, 211)
    teleportButton.TextColor3 = Color3.new(1, 1, 1)
    teleportButton.AutoButtonColor = true
    teleportButton.Parent = notificationFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = teleportButton
    
    -- Обработчик кнопки телепорта
    teleportButton.MouseButton1Click:Connect(function()
        teleportToServer(serverId)
    end)
    
    local notification = {
        frame = notificationFrame,
        text = messageText,
        serverId = serverId,
        messageId = messageId,
        timestamp = os.time(),
        isTarget = isTarget,
        isFromBot = isFromBot
    }
    
    table.insert(notifications, notification)
    
    print("✅ Добавлено уведомление в меню. Отправитель: " .. (isFromBot and "Бот" or "Вы"))
    
    return notification
end

-- Функция проверки новых сообщений (исправленная)
function checkForNewServers()
    if isTeleporting or not initialized then return end
    
    local newMessages = getBotMessagesCorrected()
    local foundTarget = false
    
    for _, message in ipairs(newMessages) do
        local messageId = message.message_id
        local messageText = message.text
        
        -- Пропускаем сообщения, которые уже обрабатывали
        if messageId <= lastProcessedMessageId then
            continue
        end
        
        -- Обновляем последний обработанный ID
        lastProcessedMessageId = messageId
        
        if messageText then
            local serverId = extractServerId(messageText)
            if serverId then
                local isTarget = hasTargetObjects(messageText)
                local isFromBot = message.from and message.from.is_bot -- Проверяем, от бота ли сообщение
                
                -- Добавляем в меню ВСЕ сообщения
                addNotificationToMenu(messageText, serverId, isTarget, messageId, isFromBot)
                
                -- Автотелепорт только для целевых объектов
                if isTarget and not foundTarget then
                    print("🎯 Найдено подходящее сообщение! ID: " .. messageId)
                    teleportToServer(serverId)
                    foundTarget = true
                end
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

-- Обработчик клавиши M для сворачивания/разворачивания меню
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.M then
        -- Здесь будет логика сворачивания меню
        print("📱 Нажмите кнопку −/+ в меню для сворачивания")
    end
end)

-- Основной цикл проверки сообщений
function startMonitoring()
    print("🔍 Инициализация скрипта...")
    
    -- Инициализируем фильтр сообщений
    initializeMessageFilter()
    
    print("✅ Скрипт готов! Ожидаю сообщения от бота...")
    
    -- Первоначальная загрузка существующих сообщений
    local initialMessages = getBotMessagesCorrected()
    for _, message in ipairs(initialMessages) do
        if message.message_id <= lastProcessedMessageId then
            local serverId = extractServerId(message.text)
            if serverId then
                local isTarget = hasTargetObjects(message.text)
                local isFromBot = message.from and message.from.is_bot
                addNotificationToMenu(message.text, serverId, isTarget, message.message_id, isFromBot)
            end
        end
    end
    
    while true do
        if not isTeleporting then
            checkForNewServers()
        end
        wait(CHECK_DELAY)
    end
end

-- Запуск мониторинга
print("========================================")
print("🤖 ТЕЛЕГРАМ АВТО-ТЕЛЕПОРТ (ИСПРАВЛЕННЫЙ)")
print("👤 Chat ID: " .. CHAT_ID)
print("🎯 Авто-цели: " .. table.concat(TARGET_OBJECTS, ", "))
print("📱 Меню покажет все сообщения (от бота и от вас)")
print("🔧 Кнопка −/+ для сворачивания меню")
print("========================================")

-- Запускаем мониторинг
spawn(startMonitoring)

-- Функции для ручного управления
function manualTeleport(serverId)
    if serverId and #serverId == 36 then
        resetState()
        teleportToServer(serverId)
    else
        print("❌ Неверный serverId!")
    end
end

function clearNotifications()
    if notificationMenu then
        for _, child in ipairs(notificationMenu:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
    end
    notifications = {}
    allProcessedMessages = {}
    print("🗑 Все уведомления очищены")
end

function showNotificationCount()
    print("📊 Количество уведомлений в меню: " .. #notifications)
end
