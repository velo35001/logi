-- НАСТРОЙКИ --
local HOP_DELAY = 5  -- задержка перед первым переходом (5 секунд)
local HOP_INTERVAL = 5  -- интервал между переходами (5 секунд)
local USE_VPN_SIMULATION = true
local ANTI_BAN_PROTECTION = true

-- ТЕХНИЧЕСКИЕ ПЕРЕМЕННЫЕ --
local lastHopTime = 0
local sessionId = tostring(math.random(1, 1000000))..tostring(tick())
local isHopping = false
local visitedServers = {}  -- Таблица для хранения посещённых серверов
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local NetworkClient = game:GetService("NetworkClient")

-- Функция безопасного телепорта
local function safeTeleport()
    local placeId = game.PlaceId  -- ID текущего места
    local success = pcall(function()
        TeleportService:Teleport(placeId)  -- основной метод
    end)
    
    -- Альтернативные методы
    if not success then
        wait(1)
        pcall(function()
            TeleportService:TeleportToPlaceInstance(placeId, tostring(math.random(1, 1000000)))  -- альтернативный метод
        end)
    end

    -- Аварийное завершение
    if not success and Players.LocalPlayer then
        wait(2)
        pcall(function() game:Shutdown() end)
    end
end

-- Функция перехода
local function nuclearHop()
    if isHopping then return end
    isHopping = true

    -- Защита от бана
    if ANTI_BAN_PROTECTION and os.time() - lastHopTime < 5 then
        warn("[ЗАЩИТА] Слишком частые переходы! Ждем...")
        isHopping = false
        return
    end
    lastHopTime = os.time()

    -- VPN-симуляция
    if USE_VPN_SIMULATION then
        pcall(function()
            NetworkClient:SetOutgoingKBPSLimit(math.random(500, 2000))
        end)
    end

    -- Отключение для безопасного телепорта
    pcall(function()
        Players.LocalPlayer:Kick("Автопереход...")
    end)
    wait(0.5)
    safeTeleport()

    -- Двойная проверка
    wait(3)
    if Players.LocalPlayer then
        pcall(function()
            game:Shutdown()
        end)
    end

    isHopping = false
end

-- Проверка сервера, чтобы не заходить на тот же сервер повторно
local function isServerVisited(serverId)
    return visitedServers[serverId] == true
end

local function addServerToVisited(serverId)
    visitedServers[serverId] = true
end

-- Интерфейс
local gui = Instance.new("ScreenGui")
gui.Name = "KlimHopGUI"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.12, 0, 0.06, 0)
frame.Position = UDim2.new(0.85, 0, 0.9, 0)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Parent = gui

local uICorner = Instance.new("UICorner")
uICorner.CornerRadius = UDim.new(0.3, 0)
uICorner.Parent = frame

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 1, 0)
label.Text = "turbo Клим"
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextSize = 14
label.Parent = frame

-- Автопереход
local function startAutoHop()
    -- Первый переход через 5 секунд
    label.Text = "turbo Клим | запуск..."
    wait(HOP_DELAY)

    -- Основной цикл
    while true do
        label.Text = "turbo Клим | переход"
        
        -- Здесь добавим проверку, чтобы избегать повторных заходов на тот же сервер
        local serverId = tostring(math.random(1, 1000000))  -- Генерация уникального id сервера (псевдокод)
        
        -- Пример проверки, если сервер был уже посещён
        if not isServerVisited(serverId) then
            addServerToVisited(serverId)
            nuclearHop()
        else
            warn("Сервер уже посещён. Переходим к следующему.")
        end
        
        wait(HOP_INTERVAL)
    end
end

-- Запуск
spawn(startAutoHop)

-- Автовосстановление
Players.LocalPlayer.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Started then
        if gui then
            gui:Destroy()
        end
    end
end)

-- Анти-краш
game:GetService("ScriptContext").Error:Connect(function()
    pcall(function() gui:Destroy() end)
end)
