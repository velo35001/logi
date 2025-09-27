-- Полная функция создания меню уведомлений
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
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragStart = nil
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

-- Функция добавления уведомления в меню (исправленная)
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

-- Инициализация меню (добавьте этот код после определения функций)
print("🔄 Создание меню уведомлений...")
notificationMenu = createNotificationMenu()

if notificationMenu then
    print("✅ Меню уведомлений успешно создано!")
else
    print("❌ Не удалось создать меню уведомлений")
end

-- Обновите основную функцию мониторинга
function startMonitoring()
    print("🔍 Инициализация скрипта...")
    
    -- Инициализируем бота
    initializeBot()
    
    -- Проверяем, создалось ли меню
    if not notificationMenu then
        print("⚠️ Меню не создано, но скрипт продолжит работу в фоновом режиме")
    end
    
    print("✅ Скрипт готов! Ожидаю сообщения от бота...")
    
    while true do
        if not isTeleporting then
            checkForNewMessages()
        end
        wait(CHECK_DELAY)
    end
end
