local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "VeloAutoJoiner"
gui.Parent = player:WaitForChild("PlayerGui")

-- Основной контейнер - точно по центру
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 350, 0, 400)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(220, 235, 255)
mainFrame.ClipsDescendants = true
mainFrame.Visible = false

-- Закругление углов
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 15)
corner.Parent = mainFrame

-- Основной фон (синий)
local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
background.BorderSizePixel = 0
background.Parent = mainFrame

local bgCorner = Instance.new("UICorner")
bgCorner.CornerRadius = UDim.new(0, 15)
bgCorner.Parent = background

-- Контейнер для размытых кругов
local circlesContainer = Instance.new("Frame")
circlesContainer.Name = "CirclesContainer"
circlesContainer.Size = UDim2.new(1, 0, 1, 0)
circlesContainer.BackgroundTransparency = 1
circlesContainer.Parent = background

-- Очень размытые белые круги на фоне
local circles = {}
local function createCircles()
    for i = 1, 6 do
        local circleGroup = Instance.new("Frame")
        circleGroup.Name = "CircleGroup" .. i
        local size = math.random(120, 200)
        circleGroup.Size = UDim2.new(0, size, 0, size)
        circleGroup.Position = UDim2.new(math.random(), 0, math.random(), 0)
        circleGroup.BackgroundTransparency = 1
        circleGroup.BorderSizePixel = 0
        circleGroup.AnchorPoint = Vector2.new(0.5, 0.5)
        
        -- Создаем несколько слоев для эффекта сильного размытия
        for j = 1, 6 do
            local blurCircle = Instance.new("Frame")
            local blurSize = size * (0.7 + j * 0.05)
            blurCircle.Size = UDim2.new(0, blurSize, 0, blurSize)
            blurCircle.Position = UDim2.new(0.5, -blurSize/2, 0.5, -blurSize/2)
            blurCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            blurCircle.BackgroundTransparency = 0.96 + j * 0.007
            blurCircle.BorderSizePixel = 0
            blurCircle.AnchorPoint = Vector2.new(0.5, 0.5)
            
            local blurCorner = Instance.new("UICorner")
            blurCorner.CornerRadius = UDim.new(1, 0)
            blurCorner.Parent = blurCircle
            
            blurCircle.Parent = circleGroup
        end
        
        circleGroup.Parent = circlesContainer
        table.insert(circles, circleGroup)
    end
end

-- Анимация движения кругов (медленная и плавная)
local function animateCircles()
    while true do
        for _, circle in pairs(circles) do
            local newX = math.random()
            local newY = math.random()
            local tweenInfo = TweenInfo.new(
                math.random(20, 30),
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.InOut
            )
            local tween = TweenService:Create(circle, tweenInfo, {
                Position = UDim2.new(newX, 0, newY, 0)
            })
            tween:Play()
        end
        wait(25)
    end
end

-- Обводка с плавным переливанием
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80, 160, 255)
stroke.Thickness = 3
stroke.Transparency = 0
stroke.Parent = mainFrame

-- Анимация обводки
spawn(function()
    local brightness = 0.8
    local direction = 0.008
    while true do
        brightness = brightness + direction
        if brightness >= 1 then
            brightness = 1
            direction = -0.008
        elseif brightness <= 0.6 then
            brightness = 0.6
            direction = 0.008
        end
        stroke.Color = Color3.fromRGB(
            math.floor(80 * brightness),
            math.floor(160 * brightness),
            math.floor(255 * brightness)
        )
        wait(0.05)
    end
end)

-- Заголовок
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(0.8, 0, 0, 30)
title.Position = UDim2.new(0.1, 0, 0.05, 0)
title.BackgroundTransparency = 1
title.Text = "VELO AUTOJOINER PREMIUM"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextTransparency = 0.5
title.Font = Enum.Font.Gotham
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame

-- Контейнер для буквы V (новая позиция)
local vContainer = Instance.new("Frame")
vContainer.Name = "VContainer"
vContainer.Size = UDim2.new(0, 220, 0, 200)
vContainer.Position = UDim2.new(0.5, -110, 0.25, -80)
vContainer.BackgroundTransparency = 1
vContainer.Parent = mainFrame

-- Очень большая красивая буква V
local vLetter = Instance.new("TextLabel")
vLetter.Name = "VLetter"
vLetter.Size = UDim2.new(1, 0, 1, 0)
vLetter.BackgroundTransparency = 1
vLetter.Text = "V"
vLetter.TextColor3 = Color3.fromRGB(255, 255, 255)
vLetter.Font = Enum.Font.FredokaOne
vLetter.TextSize = 190
vLetter.TextTransparency = 1
vLetter.Parent = vContainer

-- Поле для ввода ключа
local keyBoxContainer = Instance.new("Frame")
keyBoxContainer.Name = "KeyBoxContainer"
keyBoxContainer.Size = UDim2.new(0.8, 0, 0, 50)
keyBoxContainer.Position = UDim2.new(0.1, 0, 0.6, 0)
keyBoxContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
keyBoxContainer.Parent = mainFrame

local keyBoxCorner = Instance.new("UICorner")
keyBoxCorner.CornerRadius = UDim.new(0, 10)
keyBoxCorner.Parent = keyBoxContainer

local keyBoxStroke = Instance.new("UIStroke")
keyBoxStroke.Color = Color3.fromRGB(100, 180, 255)
keyBoxStroke.Thickness = 2
keyBoxStroke.Parent = keyBoxContainer

local keyBox = Instance.new("TextBox")
keyBox.Name = "KeyBox"
keyBox.Size = UDim2.new(0.9, 0, 0.8, 0)
keyBox.Position = UDim2.new(0.05, 0, 0.1, 0)
keyBox.BackgroundTransparency = 1
keyBox.PlaceholderText = "Enter your key..."
keyBox.Text = ""
keyBox.TextColor3 = Color3.fromRGB(50, 50, 50)
keyBox.Font = Enum.Font.GothamSemibold
keyBox.TextSize = 16
keyBox.ClearTextOnFocus = false
keyBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
keyBox.TextXAlignment = Enum.TextXAlignment.Left
keyBox.Parent = keyBoxContainer

-- Иконка ключа
local keyIcon = Instance.new("TextLabel")
keyIcon.Name = "KeyIcon"
keyIcon.Size = UDim2.new(0, 20, 0, 20)
keyIcon.Position = UDim2.new(0.9, -10, 0.5, -10)
keyIcon.BackgroundTransparency = 1
keyIcon.Text = "🔑"
keyIcon.TextColor3 = Color3.fromRGB(150, 150, 150)
keyIcon.Font = Enum.Font.Gotham
keyIcon.TextSize = 14
keyIcon.Parent = keyBoxContainer

-- Кнопка Activate с тенью
local activateShadow = Instance.new("Frame")
activateShadow.Name = "ActivateShadow"
activateShadow.Size = UDim2.new(0.8, 0, 0, 45)
activateShadow.Position = UDim2.new(0.1, 4, 0.74, 4)
activateShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
activateShadow.BackgroundTransparency = 0.8
activateShadow.ZIndex = 1

local activateShadowCorner = Instance.new("UICorner")
activateShadowCorner.CornerRadius = UDim.new(0, 10)
activateShadowCorner.Parent = activateShadow

local activateBtn = Instance.new("TextButton")
activateBtn.Name = "ActivateBtn"
activateBtn.Size = UDim2.new(0.8, 0, 0, 45)
activateBtn.Position = UDim2.new(0.1, 0, 0.74, 0)
activateBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
activateBtn.Text = "ACTIVATE"
activateBtn.TextColor3 = Color3.fromRGB(80, 160, 255)
activateBtn.Font = Enum.Font.GothamBold
activateBtn.TextSize = 16
activateBtn.AutoButtonColor = false
activateBtn.ZIndex = 2

local activateCorner = Instance.new("UICorner")
activateCorner.CornerRadius = UDim.new(0, 10)
activateCorner.Parent = activateBtn

local activateStroke = Instance.new("UIStroke")
activateStroke.Color = Color3.fromRGB(255, 255, 255)
activateStroke.Thickness = 2
activateStroke.Parent = activateBtn

-- Glow эффект для кнопки Activate
local activateGlow = Instance.new("ImageLabel")
activateGlow.Name = "ActivateGlow"
activateGlow.Size = UDim2.new(1, 10, 1, 10)
activateGlow.Position = UDim2.new(0, -5, 0, -5)
activateGlow.BackgroundTransparency = 1
activateGlow.Image = "rbxassetid://8992231221"
activateGlow.ImageColor3 = Color3.fromRGB(255, 255, 255)
activateGlow.ScaleType = Enum.ScaleType.Slice
activateGlow.SliceCenter = Rect.new(100, 100, 100, 100)
activateGlow.ImageTransparency = 0.8
activateGlow.ZIndex = 3
activateGlow.Parent = activateBtn

-- Кнопка Copy Link с тенью
local copyShadow = Instance.new("Frame")
copyShadow.Name = "CopyShadow"
copyShadow.Size = UDim2.new(0.8, 0, 0, 40)
copyShadow.Position = UDim2.new(0.1, 3, 0.87, 3)
copyShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
copyShadow.BackgroundTransparency = 0.8
copyShadow.ZIndex = 1

local copyShadowCorner = Instance.new("UICorner")
copyShadowCorner.CornerRadius = UDim.new(0, 8)
copyShadowCorner.Parent = copyShadow

local copyBtn = Instance.new("TextButton")
copyBtn.Name = "CopyBtn"
copyBtn.Size = UDim2.new(0.8, 0, 0, 40)
copyBtn.Position = UDim2.new(0.1, 0, 0.87, 0)
copyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
copyBtn.BackgroundTransparency = 0.1
copyBtn.Text = "COPY LINK"
copyBtn.TextColor3 = Color3.fromRGB(80, 160, 255)
copyBtn.Font = Enum.Font.Gotham
copyBtn.TextSize = 14
copyBtn.AutoButtonColor = false
copyBtn.ZIndex = 2

local copyCorner = Instance.new("UICorner")
copyCorner.CornerRadius = UDim.new(0, 8)
copyCorner.Parent = copyBtn

-- Кнопка закрытия с крутой анимацией
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(0.88, 0, 0.02, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 24
closeBtn.Parent = mainFrame

-- Функция для создания уведомления
local function createNotification(message, isSuccess)
    local notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "NotificationGui"
    notificationGui.Parent = player:WaitForChild("PlayerGui")
    
    -- Основной контейнер уведомления
    local notificationFrame = Instance.new("TextButton")
    notificationFrame.Name = "NotificationFrame"
    notificationFrame.Size = UDim2.new(0, 300, 0, 70)
    notificationFrame.Position = UDim2.new(0.5, 0, 0, -70) -- Начинаем выше экрана, центрировано по горизонтали
    notificationFrame.AnchorPoint = Vector2.new(0.5, 0)
    notificationFrame.BackgroundColor3 = Color3.fromRGB(220, 235, 255)
    notificationFrame.ClipsDescendants = true
    notificationFrame.Text = ""
    notificationFrame.AutoButtonColor = false
    
    -- Закругление углов
    local notificationCorner = Instance.new("UICorner")
    notificationCorner.CornerRadius = UDim.new(0, 12)
    notificationCorner.Parent = notificationFrame
    
    -- Основной фон (синий)
    local notificationBackground = Instance.new("Frame")
    notificationBackground.Name = "Background"
    notificationBackground.Size = UDim2.new(1, 0, 1, 0)
    notificationBackground.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
    notificationBackground.BorderSizePixel = 0
    notificationBackground.Parent = notificationFrame
    
    local notificationBgCorner = Instance.new("UICorner")
    notificationBgCorner.CornerRadius = UDim.new(0, 12)
    notificationBgCorner.Parent = notificationBackground
    
    -- Контейнер для размытых кругов
    local notificationCirclesContainer = Instance.new("Frame")
    notificationCirclesContainer.Name = "CirclesContainer"
    notificationCirclesContainer.Size = UDim2.new(1, 0, 1, 0)
    notificationCirclesContainer.BackgroundTransparency = 1
    notificationCirclesContainer.Parent = notificationBackground
    
    -- Создаем круги для уведомления
    for i = 1, 3 do
        local circleGroup = Instance.new("Frame")
        circleGroup.Name = "CircleGroup" .. i
        local size = math.random(60, 90)
        circleGroup.Size = UDim2.new(0, size, 0, size)
        circleGroup.Position = UDim2.new(math.random(), 0, math.random(), 0)
        circleGroup.BackgroundTransparency = 1
        circleGroup.BorderSizePixel = 0
        circleGroup.AnchorPoint = Vector2.new(0.5, 0.5)
        
        for j = 1, 3 do
            local blurCircle = Instance.new("Frame")
            local blurSize = size * (0.7 + j * 0.05)
            blurCircle.Size = UDim2.new(0, blurSize, 0, blurSize)
            blurCircle.Position = UDim2.new(0.5, -blurSize/2, 0.5, -blurSize/2)
            blurCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            blurCircle.BackgroundTransparency = 0.96 + j * 0.007
            blurCircle.BorderSizePixel = 0
            blurCircle.AnchorPoint = Vector2.new(0.5, 0.5)
            
            local blurCorner = Instance.new("UICorner")
            blurCorner.CornerRadius = UDim.new(1, 0)
            blurCorner.Parent = blurCircle
            
            blurCircle.Parent = circleGroup
        end
        
        circleGroup.Parent = notificationCirclesContainer
    end
    
    -- Обводка
    local notificationStroke = Instance.new("UIStroke")
    notificationStroke.Color = Color3.fromRGB(80, 160, 255)
    notificationStroke.Thickness = 2
    notificationStroke.Transparency = 0
    notificationStroke.Parent = notificationFrame
    
    -- Иконка статуса
    local statusIcon = Instance.new("TextLabel")
    statusIcon.Name = "StatusIcon"
    statusIcon.Size = UDim2.new(0, 24, 0, 24)
    statusIcon.Position = UDim2.new(0.05, 0, 0.3, 0)
    statusIcon.BackgroundTransparency = 1
    statusIcon.Text = "✓"
    statusIcon.TextColor3 = Color3.fromRGB(0, 200, 0)
    statusIcon.Font = Enum.Font.GothamBold
    statusIcon.TextSize = 18
    statusIcon.Parent = notificationFrame
    
    -- Основной текст уведомления
    local notificationText = Instance.new("TextLabel")
    notificationText.Name = "NotificationText"
    notificationText.Size = UDim2.new(0.7, 0, 0.5, 0)
    notificationText.Position = UDim2.new(0.15, 0, 0.2, 0)
    notificationText.BackgroundTransparency = 1
    notificationText.Text = message
    notificationText.TextColor3 = Color3.fromRGB(255, 255, 255)
    notificationText.Font = Enum.Font.Gotham
    notificationText.TextSize = 14
    notificationText.TextXAlignment = Enum.TextXAlignment.Left
    notificationText.Parent = notificationFrame
    
    -- Текст "нажмите чтобы скрыть"
    local clickText = Instance.new("TextLabel")
    clickText.Name = "ClickText"
    clickText.Size = UDim2.new(0.7, 0, 0.3, 0)
    clickText.Position = UDim2.new(0.15, 0, 0.6, 0)
    clickText.BackgroundTransparency = 1
    clickText.Text = "Click to hide notification"
    clickText.TextColor3 = Color3.fromRGB(255, 255, 255)
    clickText.TextTransparency = 0.7
    clickText.Font = Enum.Font.Gotham
    clickText.TextSize = 10
    clickText.TextXAlignment = Enum.TextXAlignment.Left
    clickText.Parent = notificationFrame
    
    -- Контейнер для полоски таймера с обрезкой
    local timerContainer = Instance.new("Frame")
    timerContainer.Name = "TimerContainer"
    timerContainer.Size = UDim2.new(1, -24, 0, 4) -- Уменьшаем ширину чтобы не заходить за края
    timerContainer.Position = UDim2.new(0.5, 0, 1, -4)
    timerContainer.AnchorPoint = Vector2.new(0.5, 1)
    timerContainer.BackgroundTransparency = 1
    timerContainer.ClipsDescendants = true
    timerContainer.Parent = notificationFrame
    
    local timerContainerCorner = Instance.new("UICorner")
    timerContainerCorner.CornerRadius = UDim.new(0, 2)
    timerContainerCorner.Parent = timerContainer
    
    -- Полоска таймера
    local timerBar = Instance.new("Frame")
    timerBar.Name = "TimerBar"
    timerBar.Size = UDim2.new(1, 0, 1, 0)
    timerBar.Position = UDim2.new(0, 0, 0, 0)
    timerBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    timerBar.BorderSizePixel = 0
    timerBar.Parent = timerContainer
    
    local timerBarCorner = Instance.new("UICorner")
    timerBarCorner.CornerRadius = UDim.new(0, 2)
    timerBarCorner.Parent = timerBar
    
    -- Переменная для отслеживания состояния
    local notificationActive = true
    
    -- Функция скрытия уведомления
    local function hideNotification()
        if not notificationActive then return end
        notificationActive = false
        
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        local tween = TweenService:Create(notificationFrame, tweenInfo, {
            Position = UDim2.new(0.5, 0, 0, -70),
            Size = UDim2.new(0, 0, 0, 0)
        })
        tween:Play()
        
        tween.Completed:Connect(function()
            if notificationGui and notificationGui.Parent then
                notificationGui:Destroy()
            end
        end)
    end
    
    -- Анимация появления
    notificationFrame.Parent = notificationGui
    
    local showTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local showTween = TweenService:Create(notificationFrame, showTweenInfo, {
        Position = UDim2.new(0.5, 0, 0, 20) -- Центрировано по горизонтали, 20 пикселей от верха
    })
    showTween:Play()
    
    -- Анимация таймера
    local timerTweenInfo = TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
    local timerTween = TweenService:Create(timerBar, timerTweenInfo, {
        Size = UDim2.new(0, 0, 1, 0)
    })
    timerTween:Play()
    
    -- Автоматическое скрытие через 5 секунд
    spawn(function()
        wait(5)
        if notificationActive then
            hideNotification()
        end
    end)
    
    -- Обработчик клика
    notificationFrame.MouseButton1Click:Connect(function()
        if notificationActive then
            hideNotification()
        end
    end)
    
    return notificationGui
end

-- Анимация появления с масштабированием и bounce эффектом
local function showAnimation()
    -- Создаем круги перед показом
    createCircles()
    
    mainFrame.Visible = true
    mainFrame.Size = UDim2.new(0, 0, 0, 0) -- Начинаем с нулевого размера
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    -- Эффект размытия в начале
    mainFrame.BackgroundTransparency = 0.5
    
    -- Анимация масштабирования с bounce эффектом
    local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0)
    local tween = TweenService:Create(mainFrame, tweenInfo, {
        Size = UDim2.new(0, 350, 0, 400),
        BackgroundTransparency = 0
    })
    tween:Play()
    
    -- Анимация появления буквы V
    wait(0.3)
    local vTweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local vTween = TweenService:Create(vLetter, vTweenInfo, {
        TextTransparency = 0
    })
    vTween:Play()
    
    -- Запускаем анимацию кругов
    spawn(animateCircles)
end

-- Анимация закрытия с масштабированием
local function closeAnimation()
    -- Эффект размытия в конце
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In, 0, false, 0)
    local tween = TweenService:Create(mainFrame, tweenInfo, {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 0.5
    })
    tween:Play()
    tween.Completed:Wait()
    gui:Destroy()
end

-- Функция для анимации кнопки Copy Link
local isAnimatingCopy = false
local function animateCopyButton()
    if isAnimatingCopy then return end
    isAnimatingCopy = true
    
    local originalText = copyBtn.Text
    local originalTextColor = copyBtn.TextColor3
    
    -- Анимация изменения текста и цвета
    local textTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local textTween = TweenService:Create(copyBtn, textTweenInfo, {
        TextColor3 = Color3.fromRGB(0, 200, 0) -- Зеленый цвет для подтверждения
    })
    textTween:Play()
    
    -- Легкая анимация "пульсации"
    local pulseTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local pulseTween = TweenService:Create(copyBtn, pulseTweenInfo, {
        Size = UDim2.new(0.82, 0, 0, 42) -- Легкое увеличение
    })
    pulseTween:Play()
    
    -- Анимация тени
    local shadowTween = TweenService:Create(copyShadow, pulseTweenInfo, {
        Size = UDim2.new(0.82, 0, 0, 42)
    })
    shadowTween:Play()
    
    -- Меняем текст
    copyBtn.Text = "LINK COPIED!"
    
    -- Ждем 2 секунды
    wait(2)
    
    -- Возвращаем обратно
    local returnTextTween = TweenService:Create(copyBtn, textTweenInfo, {
        TextColor3 = originalTextColor -- Возвращаем исходный цвет
    })
    returnTextTween:Play()
    
    local returnPulseTween = TweenService:Create(copyBtn, pulseTweenInfo, {
        Size = UDim2.new(0.8, 0, 0, 40) -- Возвращаем исходный размер
    })
    returnPulseTween:Play()
    
    local returnShadowTween = TweenService:Create(copyShadow, pulseTweenInfo, {
        Size = UDim2.new(0.8, 0, 0, 40)
    })
    returnShadowTween:Play()
    
    -- Возвращаем исходный текст
    copyBtn.Text = originalText
    
    isAnimatingCopy = false
end

-- Анимация для правильного ключа
local function animateSuccess()
    -- Отключаем кнопку на время анимации
    activateBtn.AutoButtonColor = false
    
    -- Сохраняем исходные значения
    local originalText = activateBtn.Text
    local originalTextColor = activateBtn.TextColor3
    local originalBackgroundColor = activateBtn.BackgroundColor3
    
    -- Анимация изменения текста и цвета на зеленый
    local successTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local successTween = TweenService:Create(activateBtn, successTweenInfo, {
        TextColor3 = Color3.fromRGB(0, 200, 0),
        BackgroundColor3 = Color3.fromRGB(230, 255, 230)
    })
    successTween:Play()
    
    -- Анимация тени
    local shadowTween = TweenService:Create(activateShadow, successTweenInfo, {
        BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    })
    shadowTween:Play()
    
    -- Анимация glow эффекта
    local glowTween = TweenService:Create(activateGlow, successTweenInfo, {
        ImageColor3 = Color3.fromRGB(0, 255, 0),
        ImageTransparency = 0.4
    })
    glowTween:Play()
    
    -- Меняем текст
    activateBtn.Text = "KEY ACTIVATED"
    
    -- Показываем уведомление об успехе
    createNotification("Key activated successfully", true)
    
    -- Ждем завершения анимации
    wait(1.5)
    
    -- Сворачиваем меню
    closeAnimation()
end

-- Анимация для неправильного ключа с тряской
local function animateError()
    -- Отключаем кнопку на время анимации
    activateBtn.AutoButtonColor = false
    
    -- Сохраняем исходные значения
    local originalText = activateBtn.Text
    local originalTextColor = activateBtn.TextColor3
    local originalBackgroundColor = activateBtn.BackgroundColor3
    local originalPosition = activateBtn.Position -- Сохраняем исходную позицию
    
    -- Анимация изменения текста и цвета на красный
    local errorTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local errorTween = TweenService:Create(activateBtn, errorTweenInfo, {
        TextColor3 = Color3.fromRGB(200, 0, 0),
        BackgroundColor3 = Color3.fromRGB(255, 230, 230)
    })
    errorTween:Play()
    
    -- Анимация тени
    local shadowTween = TweenService:Create(activateShadow, errorTweenInfo, {
        BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    })
    shadowTween:Play()
    
    -- Анимация glow эффекта
    local glowTween = TweenService:Create(activateGlow, errorTweenInfo, {
        ImageColor3 = Color3.fromRGB(255, 0, 0),
        ImageTransparency = 0.4
    })
    glowTween:Play()
    
    -- Анимация "тряски" кнопки
    local shakeIntensity = 5 -- Интенсивность тряски
    local shakeDuration = 0.5 -- Длительность тряски
    local shakeCount = 6 -- Количество колебаний
    
    local startTime = tick()
    local connection
    connection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        if elapsed >= shakeDuration then
            connection:Disconnect()
            -- Гарантированно возвращаем на исходную позицию
            activateBtn.Position = originalPosition
            return
        end
        
        -- Вычисляем прогресс анимации (0 to 1)
        local progress = elapsed / shakeDuration
        local easeProgress = 1 - (progress * progress) -- Ease out
        
        -- Вычисляем смещение с затуханием
        local offset = math.sin(elapsed * math.pi * 2 * shakeCount) * shakeIntensity * easeProgress
        activateBtn.Position = UDim2.new(
            originalPosition.X.Scale, 
            originalPosition.X.Offset + offset,
            originalPosition.Y.Scale, 
            originalPosition.Y.Offset
        )
    end)
    
    -- Меняем текст
    activateBtn.Text = "INVALID KEY"
    
    -- Ждем завершения анимации тряски + дополнительное время
    wait(shakeDuration + 0.5)
    
    -- Возвращаем обратно
    local returnTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local returnTween = TweenService:Create(activateBtn, returnTweenInfo, {
        TextColor3 = originalTextColor,
        BackgroundColor3 = originalBackgroundColor,
        Position = originalPosition -- Используем сохраненную позицию
    })
    returnTween:Play()
    
    local returnShadowTween = TweenService:Create(activateShadow, returnTweenInfo, {
        BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    })
    returnShadowTween:Play()
    
    local returnGlowTween = TweenService:Create(activateGlow, returnTweenInfo, {
        ImageColor3 = Color3.fromRGB(255, 255, 255),
        ImageTransparency = 0.8
    })
    returnGlowTween:Play()
    
    -- Возвращаем исходный текст
    activateBtn.Text = originalText
    
    -- Включаем кнопку обратно
    activateBtn.AutoButtonColor = false
end

-- Функция проверки ключа
local function checkKey()
    local enteredKey = keyBox.Text:lower():gsub("%s+", "") -- Приводим к нижнему регистру и убираем пробелы
    local correctKey = "velopremium"
    
    -- Проверка на пустой ключ
    if enteredKey == "" then
        animateError()
        return
    end
    
    if enteredKey == correctKey then
        animateSuccess()
    else
        animateError()
    end
end

-- Крутая анимация для крестика при наведении
local function setupCloseButtonEffects()
    local originalRotation = closeBtn.Rotation
    local originalSize = closeBtn.Size
    local originalPosition = closeBtn.Position
    local originalTextColor = closeBtn.TextColor3
    
    closeBtn.MouseEnter:Connect(function()
        -- Анимация вращения и увеличения
        local tweenInfo1 = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        local tween1 = TweenService:Create(closeBtn, tweenInfo1, {
            Rotation = 90,
            Size = UDim2.new(0, 35, 0, 35),
            Position = UDim2.new(0.88, -2.5, 0.02, -2.5),
            TextColor3 = Color3.fromRGB(255, 100, 100) -- Красный цвет при наведении
        })
        tween1:Play()
        
        -- Дополнительная анимация "покачивания" после вращения
        wait(0.3)
        local tweenInfo2 = TweenInfo.new(0.2, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
        local tween2 = TweenService:Create(closeBtn, tweenInfo2, {
            Rotation = 85
        })
        tween2:Play()
    end)
    
    closeBtn.MouseLeave:Connect(function()
        -- Возвращаем в исходное состояние
        local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        local tween = TweenService:Create(closeBtn, tweenInfo, {
            Rotation = 0,
            Size = originalSize,
            Position = originalPosition,
            TextColor3 = originalTextColor -- Исходный цвет
        })
        tween:Play()
    end)
end

-- Эффекты при наведении на кнопки
local function setupButtonEffects(button, shadow)
    local originalSize = button.Size
    local originalPos = button.Position
    local originalShadowPos = shadow and shadow.Position
    
    button.MouseEnter:Connect(function()
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(button, tweenInfo, {
            Size = originalSize + UDim2.new(0.02, 0, 0.02, 0),
            Position = originalPos - UDim2.new(0.01, 0, 0.01, 0)
        })
        tween:Play()
        
        if shadow then
            local shadowTween = TweenService:Create(shadow, tweenInfo, {
                Size = originalSize + UDim2.new(0.02, 0, 0.02, 0),
                Position = originalShadowPos - UDim2.new(0.01, 0, 0.01, 0)
            })
            shadowTween:Play()
        end
        
        if button == activateBtn then
            local glowTween = TweenService:Create(activateGlow, tweenInfo, {
                ImageTransparency = 0.6
            })
            glowTween:Play()
        end
    end)
    
    button.MouseLeave:Connect(function()
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(button, tweenInfo, {
            Size = originalSize,
            Position = originalPos
        })
        tween:Play()
        
        if shadow then
            local shadowTween = TweenService:Create(shadow, tweenInfo, {
                Size = originalSize,
                Position = originalShadowPos
            })
            shadowTween:Play()
        end
        
        if button == activateBtn then
            local glowTween = TweenService:Create(activateGlow, tweenInfo, {
                ImageTransparency = 0.8
            })
            glowTween:Play()
        end
    end)
end

-- Собираем интерфейс
activateShadow.Parent = mainFrame
activateBtn.Parent = mainFrame  
copyShadow.Parent = mainFrame
copyBtn.Parent = mainFrame
mainFrame.Parent = gui

-- Настраиваем эффекты кнопок
setupButtonEffects(activateBtn, activateShadow)
setupButtonEffects(copyBtn, copyShadow)

-- Настраиваем крутую анимацию для крестика
setupCloseButtonEffects()

-- Запускаем анимацию появления
showAnimation()

-- Обработчики событий
activateBtn.MouseButton1Click:Connect(function()
    checkKey()
end)

copyBtn.MouseButton1Click:Connect(function()
    print("Copy Link clicked")
    setclipboard("https://example.com/get-key")
    animateCopyButton()
end)

closeBtn.MouseButton1Click:Connect(function()
    closeAnimation()
end)
