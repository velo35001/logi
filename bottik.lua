local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Настройки для быстрого перебора серверов
local SETTINGS = {
    GAME_ID = 109983668079237,
    PASTEFY_URL = "https://raw.githubusercontent.com/velo35001/logi/refs/heads/main/log.txt",
    COOLDOWN_TIME = 0.5,  -- Уменьшено до 0.5 секунд
    COUNTDOWN_TIME = 0,   -- Убрана задержка перед телепортом
    ERROR_RETRY_DELAY = 0.2,  -- Уменьшено до 0.2 секунд при ошибке
    SUCCESS_DELAY = 0.2,      -- Уменьшено до 0.2 секунд при успехе
    MAX_PARALLEL_ATTEMPTS = 5, -- Параллельные попытки
    REFRESH_INTERVAL = 10      -- Обновление списка каждые 10 секунд
}

-- Хранилище данных
local SERVER_LIST = {}
local BLACKLIST = {}
local SHOW_COUNTDOWN = false
local LAST_REFRESH = 0
local ACTIVE_ATTEMPTS = 0
local IS_RUNNING = true

-- Создание GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FastTeleportGUI"
screenGui.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 140)
frame.Position = UDim2.new(0.5, -150, 1, -150)
frame.AnchorPoint = Vector2.new(0.5, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⚡ FAST TELEPORT ⚡"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 70)
status.Position = UDim2.new(0, 10, 0, 35)
status.BackgroundTransparency = 1
status.Text = "Загрузка списка серверов..."
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.Parent = frame

local stats = Instance.new("TextLabel")
stats.Size = UDim2.new(1, -20, 0, 30)
stats.Position = UDim2.new(0, 10, 0, 105)
stats.BackgroundTransparency = 1
stats.Text = "Ожидание..."
stats.TextColor3 = Color3.fromRGB(150, 200, 255)
stats.Font = Enum.Font.Gotham
stats.TextSize = 12
stats.TextXAlignment = Enum.TextXAlignment.Left
stats.Parent = frame

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 20, 0, 20)
closeButton.Position = UDim2.new(1, -25, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
closeButton.BorderSizePixel = 0
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "X"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
closeButton.Parent = frame

local corner2 = Instance.new("UICorner")
corner2.CornerRadius = UDim.new(0, 4)
corner2.Parent = closeButton

-- Анимация закрытия
closeButton.MouseButton1Click:Connect(function()
    IS_RUNNING = false
    local tween = TweenService:Create(frame, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -150, 1, 150)})
    tween:Play()
    tween.Completed:Wait()
    screenGui:Destroy()
end)

-- Перетаскивание GUI
local dragging = false
local dragStartPos, frameStartPos

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStartPos = Vector2.new(input.Position.X, input.Position.Y)
        frameStartPos = frame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStartPos
        frame.Position = UDim2.new(frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X, 
                                  frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Обновление статуса в GUI
local function UpdateStatus(text, color)
    status.Text = text
    status.TextColor3 = color or Color3.fromRGB(200, 200, 200)
end

local function UpdateStats(text)
    stats.Text = text
end

-- Проверка всех возможных ошибок телепортации
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
        return game:HttpGet(SETTINGS.PASTEFY_URL)
    end)
    
    if not success then 
        UpdateStatus("❌ Ошибка загрузки списка серверов:\n"..tostring(response):sub(1, 100), Color3.fromRGB(255, 100, 100))
        return {}
    end
    
    local servers = {}
    for serverId in string.gmatch(response, "([a-f0-9%-]+)") do
        table.insert(servers, serverId)
    end
    LAST_REFRESH = os.time()
    return servers
end

local function IsServerAvailable(serverId)
    if not BLACKLIST[serverId] then return true end
    return (os.time() - BLACKLIST[serverId]) > SETTINGS.COOLDOWN_TIME
end

local function FastTeleport(target)
    if SHOW_COUNTDOWN then
        for i = SETTINGS.COUNTDOWN_TIME, 1, -1 do
            UpdateStatus("🕒 Подключение через "..i.." сек...", Color3.fromRGB(255, 255, 150))
            task.wait(1)
        end
        SHOW_COUNTDOWN = false
    end
    
    UpdateStatus("⚡ Подключение к серверу...", Color3.fromRGB(150, 255, 150))
    
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(
            SETTINGS.GAME_ID,
            target,
            Players.LocalPlayer
        )
    end)
    
    if not success then
        if IsTeleportError(err) then
            UpdateStatus("⛔️ Ошибка:\n"..tostring(err):match("^[^\n]+"):sub(1, 100), Color3.fromRGB(255, 100, 100))
        else
            UpdateStatus("⚠️ Неизвестная ошибка:\n"..tostring(err):match("^[^\n]+"):sub(1, 100), Color3.fromRGB(255, 150, 100))
        end
        BLACKLIST[target] = os.time()
        return false
    end
    
    UpdateStatus("✅ Успешное подключение!", Color3.fromRGB(100, 255, 100))
    return true
end

local function AttemptTeleport(target)
    ACTIVE_ATTEMPTS = ACTIVE_ATTEMPTS + 1
    UpdateStats("Попытка #"..ACTIVE_ATTEMPTS.." | Сервер: "..target:sub(1, 8).."...")
    
    local success = FastTeleport(target)
    
    if success then
        task.wait(SETTINGS.SUCCESS_DELAY)
    else
        task.wait(SETTINGS.ERROR_RETRY_DELAY)
    end
    
    return success
end

local function FastTeleportLoop()
    while IS_RUNNING do
        -- Обновляем список серверов если прошло больше REFRESH_INTERVAL секунд
        if #SERVER_LIST == 0 or os.time() - LAST_REFRESH > SETTINGS.REFRESH_INTERVAL then
            UpdateStatus("📥 Загрузка списка серверов...", Color3.fromRGB(200, 200, 255))
            SERVER_LIST = LoadServers()
            
            if #SERVER_LIST == 0 then
                UpdateStatus("⚠️ Список серверов пуст\nПовтор через 2 сек...", Color3.fromRGB(255, 200, 100))
                task.wait(2)
                continue
            else
                UpdateStatus("✅ Загружено серверов: "..#SERVER_LIST, Color3.fromRGB(150, 255, 150))
            end
        end
        
        -- Фильтруем доступные серверы
        local available = {}
        for _, serverId in ipairs(SERVER_LIST) do
            if IsServerAvailable(serverId) then
                table.insert(available, serverId)
            end
        end
        
        UpdateStats("Доступно: "..#available.."/"..#SERVER_LIST.." серверов")
        
        if #available == 0 then
            UpdateStatus("⏳ Все серверы на кд\nОжидание 0.5 сек...", Color3.fromRGB(255, 200, 100))
            task.wait(0.5)
        else
            -- Пытаемся подключиться к случайному доступному серверу
            local target = available[math.random(1, #available)]
            UpdateStatus("🔍 Попытка подключения к:\n"..target:sub(1, 8).."...", Color3.fromRGB(200, 200, 255))
            
            if AttemptTeleport(target) then
                UpdateStatus("🚀 Успешное подключение!", Color3.fromRGB(100, 255, 100))
                -- Не выходим из цикла, продолжаем пытаться
                task.wait(0.1)
            else
                UpdateStatus("🔄 Поиск другого сервера...", Color3.fromRGB(255, 200, 100))
                task.wait(0.1)
            end
        end
    end
end

-- Запускаем несколько потоков для максимальной скорости
for i = 1, SETTINGS.MAX_PARALLEL_ATTEMPTS do
    task.spawn(function()
        while IS_RUNNING do
            local success, err = pcall(FastTeleportLoop)
            if not success and IS_RUNNING then
                UpdateStatus("🛑 Ошибка в потоке "..i..":\n"..tostring(err):sub(1, 100), Color3.fromRGB(255, 100, 100))
                task.wait(1)
            end
        end
    end)
    task.wait(0.05) -- Небольшая задержка между запуском потоков
end

-- Основной поток для обновления GUI
while IS_RUNNING do
    UpdateStats("Активных попыток: "..ACTIVE_ATTEMPTS)
    task.wait(0.5)
end
