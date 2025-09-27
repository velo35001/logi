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

-- GUI элементы
local notificationMenu
local notifications = {}
local MAX_NOTIFICATIONS = 15

-- Функция для HTTP запросов
function httpGet(url)
    local success, result = pcall(function()
        return game:HttpGet(url, true)
    end)
    return success, result
end

-- Улучшенная функция получения сообщений через getUpdates
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
                
                -- Обрабатываем сообщения из нужного чата
                if update.message and update.message.chat and tostring(update.message.chat.id) == CHAT_ID then
                    table.insert(messages, update.message)
                -- Также обрабатываем edited_message
                elseif update.edited_message and update.edited_message.chat and tostring(update.edited_message.chat.id) == CHAT_ID then
                    table.insert(messages, update.edited_message)
                end
            end
            
            return messages
        else
            if data.description then
                print("❌ Ошибка API:", data.description)
            end
        end
    else
        print("❌ Ошибка HTTP запроса getUpdates")
    end
    return {}
end

-- Функция для отправки сообщений в Telegram (для отладки)
function sendTelegramMessage(text)
    local url = API_URL .. "/sendMessage?chat_id=" .. CHAT_ID .. "&text=" .. HttpService:UrlEncode(text)
    local success, response = httpGet(url)
    return success, response
end

-- Функция инициализации бота
function initializeBot()
    print("🔍 Инициализация бота...")
    
    -- Проверяем информацию о боте
    local url = API_URL .. "/getMe"
    local success, response = httpGet(url)
    
    if success and response then
        local data = HttpService:JSONDecode(response)
        if data.ok then
            print("✅ Бот: @" .. data.result.username)
            -- Отправляем тестовое сообщение для проверки
            sendTelegramMessage("🤖 Скрипт активирован! Ожидаю сообщения с серверами...")
        end
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
            elseif message.from.first_name then
                senderInfo = senderInfo .. " " .. message.from.first_name
            end
        end
        print("📄 Сообщение ID: " .. message.message_id .. " от " .. senderInfo)
        
        -- Логируем содержимое сообщения для отладки
        if message.text then
            print("   Текст: " .. string.sub(message.text, 1, 100) .. "...")
        end
        if message.caption then
            print("   Подпись: " .. string.sub(message.caption, 1, 100) .. "...")
        end
    end
    
    initialized = true
    print("✅ Бот инициализирован. Последний update_id: " .. lastUpdateId)
end

-- Улучшенная функция проверки целевых объектов
function hasTargetObjects(messageText)
    if not messageText then return false end
    
    local textLower = string.lower(messageText)
    
    for _, target in ipairs(TARGET_OBJECTS) do
        local targetLower = string.lower(target)
        if string.find(textLower, targetLower, 1, true) then
            print("🎯 Найден целевой объект: " .. target)
            return true
        end
    end
    return false
end

-- Улучшенная функция извлечения serverId
function extractServerId(messageText)
    if not messageText then return nil end
    
    -- Паттерн для UUID (стандартный формат Roblox)
    local pattern = "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x"
    local found = string.match(messageText, pattern)
    
    if found and #found == 36 then
        print("🔗 Найден Server ID: " .. found)
        return found
    end
    
    -- Альтернативный паттерн (без дефисов)
    local pattern2 = "%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x"
    local found2 = string.match(messageText, pattern2)
    
    if found2 and #found2 == 32 then
        -- Форматируем в стандартный UUID
        local formatted = string.sub(found2, 1, 8) .. "-" .. string.sub(found2, 9, 12) .. "-" .. 
                         string.sub(found2, 13, 16) .. "-" .. string.sub(found2, 17, 20) .. "-" .. 
                         string.sub(found2, 21, 32)
        print("🔗 Найден Server ID (форматированный): " .. formatted)
        return formatted
    end
    
    return nil
end

function extractObjectsPart(messageText)
    if not messageText then return "Нет информации об объектах" end
    
    local objectsStart = string.find(messageText, "🚨 ВАЖНЫЕ ОБЪЕКТЫ:")
    if not objectsStart then
        objectsStart = string.find(messageText, "ВАЖНЫЕ ОБЪЕКТЫ:")
        if not objectsStart then
            return string.sub(messageText:gsub("\n", " "), 1, 80) .. "..."
        end
    end
    
    local objectsEnd = string.find(messageText, "🚀 Телепорт:", objectsStart)
    if not objectsEnd then
        objectsEnd = string.find(messageText, "Телепорт:", objectsStart)
    end
    if not objectsEnd then
        objectsEnd = #messageText
    end
    
    local objectsText = string.sub(messageText, objectsStart, objectsEnd - 1)
    objectsText = objectsText:gsub("^%s*\n*", ""):gsub("\n*%s*$", "")
    
    return objectsText
end

-- Основная функция телепортации
function teleportToServer(serverId)
    if isTeleporting then 
        print("⚠️ Телепортация уже выполняется")
        return 
    end
    
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
    
    print("❌ Ошибка телепортации: " .. errorText)
    
    if string.find(errorText, "full") or string.find(errorText, "переполнен") or string.find(errorText, "capacity") then
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

-- Функция создания меню уведомлений
function createNotificationMenu()
    local success, errorMsg = pcall(function()
        -- Создаем основной GUI
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "TelegramNotifications"
        screenGui.Parent = game:GetService("CoreGui")
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        -- Основной фрейм меню
        local notificationMenu = Instance.new("Frame")
        notificationMenu.Name = "NotificationMenu"
        notificationMenu.Size = UDim2.new(0, 400, 0, 500)
        notificationMenu.Position = UDim2.new(0, 10, 0.5, -250)
        notificationMenu.AnchorPoint = Vector2.new(0, 0.5)
        notificationMenu.BackgroundColor3 = Color3.fromRGB(16, 14, 24)
        notificationMenu.BackgroundTransparency = 0.1
        notificationMenu.BorderSizePixel = 0
        notificationMenu.Parent = screenGui
        
        -- Закругленные углы
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = notificationMenu
        
        -- Обводка
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(95, 70, 160)
        stroke.Thickness = 2
        stroke.Parent = notificationMenu
        
        -- Заголовок
        local header = Instance.new("TextLabel")
        header.Name = "Header"
        header.Text = "📱 Уведомления от бота"
        header.Font = Enum.Font.GothamBold
        header.TextSize = 16
        header.TextColor3 = Color3.fromRGB(235, 225, 255)
        header.BackgroundTransparency = 1
        header.Size = UDim2.new(1, -40, 0, 40)
        header.Position = UDim2.new(0, 10, 0, 0)
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.Parent = notificationMenu
        
        -- Кнопка сворачивания
        local toggleButton = Instance.new("TextButton")
        toggleButton.Name = "ToggleButton"
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
        
        -- Прокручиваемая область для уведомлений
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Name = "NotificationsScroll"
        scrollFrame.Size = UDim2.new(1, -10, 1, -50)
        scrollFrame.Position = UDim2.new(0, 5, 0, 45)
        scrollFrame.BackgroundTransparency = 1
        scrollFrame.ScrollBarThickness = 6
        scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(95, 70, 160)
        scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        scrollFrame.Parent = notificationMenu
        
        -- Layout для уведомлений
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.Parent = scrollFrame
        
        -- Автоматическое обновление размера canvas
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
        end)
        
        -- Функционал сворачивания/разворачивания
        local isMenuVisible = true
        
        toggleButton.MouseButton1Click:Connect(function()
            isMenuVisible = not isMenuVisible
            if isMenuVisible then
                notificationMenu.Size = UDim2.new(0, 400, 0, 500)
                toggleButton.Text = "−"
                scrollFrame.Visible = true
            else
                notificationMenu.Size = UDim2.new(0, 400, 0, 40)
                toggleButton.Text = "+"
                scrollFrame.Visible = false
            end
        end)
        
        -- Добавляем возможность перетаскивания
        local dragInput, dragStart, startPos
        local function update(input)
            local delta = input.Position - dragStart
            notificationMenu.Position = UDim2.new(0, startPos.X.Offset + delta.X, 0.5, startPos.Y.Offset + delta.Y)
        end
        
        header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragStart = input.Position
                startPos = notificationMenu.Position
                
                local connection
                connection = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragStart = nil
                        connection:Disconnect()
                    end
                end)
            end
        end)
        
        header.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end)
        
        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if input == dragInput and dragStart then
                update(input)
            end
        end)
        
        return scrollFrame
    end)
    
    if not success then
        warn("❌ Ошибка при создании меню: " .. tostring(errorMsg))
        return nil
    end
end

-- Функция добавления уведомления в меню
function addNotificationToMenu(messageText, serverId, isTarget, messageId, isFromBot)
    if not notificationMenu then 
        print("❌ Меню уведомлений не создано")
        return 
    end
    
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
    
    local success, errorMsg = pcall(function()
        -- Создаем фрейм для уведомления
        local notificationFrame = Instance.new("Frame")
        notificationFrame.Size = UDim2.new(1, 0, 0, 80)
        notificationFrame.BackgroundColor3 = isTarget and Color3.fromRGB(40, 160, 120) or Color3.fromRGB(60, 60, 80)
        notificationFrame.BackgroundTransparency = 0.1
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
        textLabel.Size = UDim2.new(1, -70, 1, -30)
        textLabel.Position = UDim2.new(0, 8, 0, 5)
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.TextYAlignment = Enum.TextYAlignment.Top
        textLabel.TextWrapped = true
        textLabel.TextScaled = false
        textLabel.Parent = notificationFrame
        
        -- Время и ID
        local infoLabel = Instance.new("TextLabel")
        infoLabel.Text = "ID: " .. messageId .. " | " .. os.date("%H:%M:%S")
        infoLabel.Font = Enum.Font.Gotham
        infoLabel.TextSize = 10
        infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        infoLabel.BackgroundTransparency = 1
        infoLabel.Size = UDim2.new(1, -70, 0, 15)
        infoLabel.Position = UDim2.new(0, 8, 1, -18)
        infoLabel.TextXAlignment = Enum.TextXAlignment.Left
        infoLabel.Parent = notificationFrame
        
        -- Кнопка телепорта (только если есть serverId)
        if serverId and #serverId >= 32 then
            local teleportButton = Instance.new("TextButton")
            teleportButton.Text = "🚀"
            teleportButton.Font = Enum.Font.GothamBold
            teleportButton.TextSize = 16
            teleportButton.Size = UDim2.new(0, 50, 0, 25)
            teleportButton.Position = UDim2.new(1, -55, 0.5, -12)
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
                print("🚀 Ручной телепорт на сервер: " .. serverId)
                teleportToServer(serverId)
            end)
        end
        
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
    end)
    
    if not success then
        warn("❌ Ошибка при добавлении уведомления: " .. tostring(errorMsg))
    end
end

-- Улучшенная функция проверки новых сообщений с автоматическим заходом
function checkForNewMessages()
    if isTeleporting or not initialized then 
        return false 
    end
    
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
        
        -- Если нашли serverId, добавляем в меню
        if serverId then
            local isTarget = hasTargetObjects(messageText)
            
            -- Добавляем в меню ВСЕ сообщения с serverId
            addNotificationToMenu(messageText, serverId, isTarget, messageId, isFromBot)
            
            -- АВТОМАТИЧЕСКИЙ ЗАХОД: телепортируемся если есть целевые объекты
            if isTarget and not foundTarget then
                print("🎯 АВТОМАТИЧЕСКИЙ ЗАХОД! Найден целевой объект!")
                print("🚀 Авто-телепорт на сервер: " .. serverId)
                teleportToServer(serverId)
                foundTarget = true
                
                -- Отправляем подтверждение в Telegram
                sendTelegramMessage("✅ Авто-заход на сервер с " .. 
                    table.concat(TARGET_OBJECTS, "/") .. 
                    " | Server: " .. serverId)
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
    
    -- Создаем меню уведомлений
    print("🔄 Создание меню уведомлений...")
    notificationMenu = createNotificationMenu()
    
    if notificationMenu then
        print("✅ Меню уведомлений успешно создано!")
    else
        print("❌ Не удалось создать меню уведомлений")
    end
    
    -- Инициализируем бота
    initializeBot()
    
    print("✅ Скрипт готов! Ожидаю сообщения от бота...")
    print("🎯 Авто-заход активирован для: " .. table.concat(TARGET_OBJECTS, ", "))
    
    -- Загружаем существующие сообщения при старте
    local initialMessages = getMessages()
    for _, message in ipairs(initialMessages) do
        local messageText = message.text or message.caption
        if messageText then
            local serverId = extractServerId(messageText)
            if serverId then
                local isTarget = hasTargetObjects(messageText)
                local isFromBot = message.from and message.from.is_bot
                addNotificationToMenu(messageText, serverId, isTarget, message.message_id, isFromBot)
            end
        end
    end
    
    -- Основной цикл мониторинга
    while true do
        if not isTeleporting then
            local found = checkForNewMessages()
            if found then
                print("⏳ Ожидаю завершения телепортации...")
            end
        end
        wait(CHECK_DELAY)
    end
end

-- Запуск мониторинга
print("========================================")
print("🤖 ТЕЛЕГРАМ АВТО-ТЕЛЕПОРТ PRO")
print("👤 Chat ID: " .. CHAT_ID)
print("🎯 Авто-цели: " .. table.concat(TARGET_OBJECTS, ", "))
print("🚀 АВТОМАТИЧЕСКИЙ ЗАХОД АКТИВИРОВАН")
print("📱 Меню уведомлений включено")
print("========================================")

-- Запускаем мониторинг
spawn(startMonitoring)

-- Функции для ручного управления
function manualTeleport(serverId)
    if serverId and (#serverId == 36 or #serverId == 32) then
        resetState()
        teleportToServer(serverId)
    else
        print("❌ Неверный serverId! Должен быть 32 или 36 символов")
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
    print("📋 Всего обработано сообщений: " .. #allProcessedMessages)
end

-- Обработчик клавиши M для информации
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.M then
        print("📱 Информация о меню:")
        print("   - Используйте кнопку −/+ для сворачивания")
        print("   - Перетаскивайте за заголовок")
        print("   - Уведомлений: " .. #notifications)
        print("   - Обработано сообщений: " .. #allProcessedMessages)
        print("   - Текущий update_id: " .. lastUpdateId)
    end
end)

-- Автоматическая отправка статуса при запуске
wait(5)
sendTelegramMessage("🟢 Скрипт активирован и готов к работе! | " .. os.date("%H:%M:%S"))
