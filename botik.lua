local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Настройки
local SETTINGS = {
    GAME_ID = 109983668079237,
    PASTEFY_URL = "https://raw.githubusercontent.com/velo35001/logi/refs/heads/main/logi.txt",
    COOLDOWN_TIME = 5 * 60,
    COUNTDOWN_TIME = 2,
    ERROR_RETRY_DELAY = 3,  -- 3 секунды при ошибке
    SUCCESS_DELAY = 3       -- 6 секунд при успехе
}

-- Хранилище данных
local SERVER_LIST = {}
local BLACKLIST = {}
local SHOW_COUNTDOWN = true

-- Создание GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TeleportStatusGUI"
screenGui.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 120)
frame.Position = UDim2.new(0.5, -125, 1, -130)
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
title.Text = "AUTO TELEPORT"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 60)
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
    local tween = TweenService:Create(frame, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -125, 1, 130)})
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
    return servers
end

local function IsServerAvailable(serverId)
    if not BLACKLIST[serverId] then return true end
    return (os.time() - BLACKLIST[serverId]) > SETTINGS.COOLDOWN_TIME
end

local function TryTeleport(target)
    if SHOW_COUNTDOWN then
        for i = SETTINGS.COUNTDOWN_TIME, 1, -1 do
            UpdateStatus("🕒 Подключение через "..i.." сек...", Color3.fromRGB(255, 255, 150))
            task.wait(1)
        end
        SHOW_COUNTDOWN = false
    end
    
    UpdateStatus("🔗 Подключение к серверу...", Color3.fromRGB(150, 255, 150))
    
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(
            SETTINGS.GAME_ID,
            target,
            Players.LocalPlayer
        )
    end)
    
    if not success then
        if IsTeleportError(err) then
            UpdateStatus("⛔ Ошибка:\n"..tostring(err):match("^[^\n]+"):sub(1, 100), Color3.fromRGB(255, 100, 100))
        else
            UpdateStatus("⚠ Неизвестная ошибка:\n"..tostring(err):match("^[^\n]+"):sub(1, 100), Color3.fromRGB(255, 150, 100))
        end
        BLACKLIST[target] = os.time()
        UpdateStatus("⏳ Повтор через "..SETTINGS.ERROR_RETRY_DELAY.." сек...", Color3.fromRGB(255, 200, 100))
        task.wait(SETTINGS.ERROR_RETRY_DELAY)
        return false
    end
    
    UpdateStatus("✅ Успешное подключение!\nЗавершение через "..SETTINGS.SUCCESS_DELAY.." сек...", Color3.fromRGB(100, 255, 100))
    task.wait(SETTINGS.SUCCESS_DELAY)
    return true
end

local function TeleportLoop()
    while true do
        SERVER_LIST = LoadServers()
        if #SERVER_LIST == 0 then
            UpdateStatus("⚠ Список серверов пуст\nПовтор через 10 сек...", Color3.fromRGB(255, 200, 100))
            task.wait(10)
        else
            UpdateStatus("✅ Доступно серверов: "..#SERVER_LIST, Color3.fromRGB(150, 255, 150))
            break
        end
    end
    
    while true do
        local available = {}
        for _, serverId in ipairs(SERVER_LIST) do
            if IsServerAvailable(serverId) then
                table.insert(available, serverId)
            end
        end
        
        if #available == 0 then
            UpdateStatus("⏳ Все серверы на кд\nОжидание "..SETTINGS.COOLDOWN_TIME.." сек...", Color3.fromRGB(255, 200, 100))
            SHOW_COUNTDOWN = true
            task.wait(SETTINGS.COOLDOWN_TIME)
            SERVER_LIST = LoadServers()
        else
            local target = available[math.random(1, #available)]
            UpdateStatus("🔍 Попытка подключения к:\n"..target:sub(1, 8).."...", Color3.fromRGB(200, 200, 255))
            
            if TryTeleport(target) then
                UpdateStatus("🚀 Успешное подключение!", Color3.fromRGB(100, 255, 100))
                break
            end
        end
    end
end

-- Основной цикл
while true do
    local success, err = pcall(TeleportLoop)
    if not success then
        UpdateStatus("🛑 Критическая ошибка:\n"..tostring(err):sub(1, 100), Color3.fromRGB(255, 100, 100))
        SHOW_COUNTDOWN = true
        task.wait(5)
    end
end

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local request = syn and syn.request or http and http.request or fluxus and fluxus.request or http_request or request

-- Конфигурация ESP
local ESP_SETTINGS = {
    UpdateInterval = 0.5,
    MaxDistance = 500,
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    PartColors = {
        Color3.new(1, 1, 1),    -- Белый
        Color3.new(0.2, 0.6, 1),-- Синий
        Color3.new(1, 0.2, 0.2) -- Красный
    },
    SoundId = "rbxassetid://130785805",
    SoundVolume = 1.5,
    PlaySoundOnce = false
}

-- Настройки сканера
local SCANNER_SETTINGS = {
    ScanKey = Enum.KeyCode.F,
    DebounceTime = 3,
    IgnoreClasses = {"SurfaceAppearance", "Part"}
}

-- Настройки Telegram ботов
local TG_MAIN = {
    Token = "8158106101:AAGTaP3CEjnWh1rjNjj7UlqfJisani8Gwz8",
    ChatId = "1090955422",
    Enabled = true,
    ImportantObjects = {
        ["Secret Lucky Block"] = true,
        ["Pot Hotspot"] = true,
        ["La Grande Combinasion"] = true,
        ["Garama and Madundung"] = true,
        ["Nuclearo Dinossauro"] = true,
        ["Chicleteira Bicicleteira"] = true,
        ["Dragon Cannelloni"] = true,
        ["Los Combinasionas"] = true,
        ["Los Hotspotsitos"] = true,
        ["Esok Sekolah"] = true,
        ["La Supreme Combinasion"] = true,
        ["Ketupat Kepat"] = true,
        ["Admin Lucky Block"] = true
    }
}

local TG_SPECIAL = {
    Token = "8403219194:AAHXD_oxTlI2YHWKFz6SKvspfo7hJY32Tsk",
    ChatId = "-1002767532824",
    Enabled = true
}

-- Доходы объектов (все значения в /s)
local OBJECT_INCOME = {
    ["La Vacca Saturno Saturnita"] = "250K/s",
    ["Chimpanzini Spiderini"] = "325K/s",
    ["Los Tralaleritos"] = "500K/s",
    ["Las Tralaleritas"] = "625K/s",
    ["Graipuss Medussi"] = "1M/s",
    ["Torrtuginni Dragonfrutini"] = "325K/s",
    ["Pot Hotspot"] = "2.5M/s",
    ["La Grande Combinasion"] = "10M/s",
    ["Garama and Madundung"] = "50M/s",
    ["Secret Lucky Block"] = "???/s",
    ["Dragon Cannelloni"] = "100M/s",
    ["Nuclearo Dinossauro"] = "15M/s",
    ["Las Vaquitas Saturnitas"] = "750K/s",
    ["Chicleteira Bicicleteira"] = "3.5M/s",
    ["Los Combinasionas"] = "15M/s",
    ["Agarrini la Palini"] = "475K/s",
    ["Los Hotspotsitos"] = "20M/s",
    ["Esok Sekolah"] = "30M/s",
    ["Karkerkar Kurkur"] = "275K/s",
    ["La Supreme Combinasion"] = "40M/s",
    ["Ketupat Kepat"] = "35M/s",
    ["Admin Lucky Block"] = "???/s"

}

-- Множители мутаций и трейтов
local MUTATION_MULTIPLIERS = {
    ["Rainbow"] = 10,
    ["Gold"] = 1.25,
    ["Diamond"] = 1.5,
    ["Bloodrot"] = 2,
    ["Candy"] = 4,
    ["Lava"] = 6
}

local TRAIT_MULTIPLIERS = {
    ["Taco"] = 3,
    ["Claws"] = 5,
    ["Snowy"] = 3,
    ["Glitched"] = 5,
    ["Fire"] = 5,
    ["Fireworks"] = 6,
    ["Nyan"] = 6,
    ["Disco"] = 5,
    ["10B"] = 3,
    ["Zombie"] = 4,
    ["Shark Fin"] = 4,
    ["Bubblegum"] = 4,
    ["Cometstruck"] = 3.5,
    ["Galactic"] = 4,
    ["Explosive"] = 4
}

-- Эмодзи для объектов
local OBJECT_EMOJIS = {
    ["La Vacca Saturno Saturnita"] = "🐮",
    ["Chimpanzini Spiderini"] = "🕷",
    ["Los Tralaleritos"] = "🐟",
    ["Las Tralaleritas"] = "🌸",
    ["Graipuss Medussi"] = "🦑",
    ["Torrtuginni Dragonfrutini"] = "🐉",
    ["Pot Hotspot"] = "📱",
    ["La Grande Combinasion"] = "❗️",
    ["Garama and Madundung"] = "🥫",
    ["Secret Lucky Block"] = "⬛️",
    ["Dragon Cannelloni"] = "🐲",
    ["Nuclearo Dinossauro"] = "🦕",
    ["Las Vaquitas Saturnitas"] = "👦",
    ["Chicleteira Bicicleteira"] = "🚲",
    ["Los Combinasionas"] = "⚒️",
    ["Agarrini la Palini"] = "🥄",
    ["Los Hotspotsitos"] = "☎️",
    ["Esok Sekolah"] = "🏠",
    ["Karkerkar Kurkur"] = "🪑",
    ["La Supreme Combinasion"] = "⁉️",
    ["Ketupat Kepat"] = "🍏",
    ["Admin Lucky Block"] = "🎩"
}

-- Эмодзи для мутаций
local MUTATION_EMOJIS = {
    ["Gold"] = "🟨",
    ["Lava"] = "🟧",
    ["Rainbow"] = "🌈",
    ["Diamond"] = "💎",
    ["Candy"] = "🍬",
    ["Bloodrot"] = "🟥"
}

-- Список объектов
local OBJECT_NAMES = {
    "La Vacca Saturno Saturnita",
    "Chimpanzini Spiderini",
    "Los Tralaleritos",
    "Las Tralaleritas",
    "Graipuss Medussi",
    "Torrtuginni Dragonfrutini",
    "Pot Hotspot",
    "La Grande Combinasion",
    "Garama and Madundung",
    "Secret Lucky Block",
    "Dragon Cannelloni",
    "Nuclearo Dinossauro",
    "Las Vaquitas Saturnitas",
    "Chicleteira Bicicleteira",
    "Los Combinasionas",
    "Agarrini la Palini",
    "Los Hotspotsitos",
    "Esok Sekolah",
    "Karkerkar Kurkur",
    "La Supreme Combinasion",
    "Ketupat Kepat",
    "Admin Lucky Block"
}

-- Системные переменные
local camera = workspace.CurrentCamera
local espCache = {}
local lastUpdate = 0
local foundObjects = {}
local objectsToNotifyMain = {}
local objectsToNotifySpecial = {}
local lastScanTime = 0
local lastNotificationTimeMain = 0
local lastNotificationTimeSpecial = 0
local lastServerNotified = ""

-- Создаем интерфейс
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RussianESP"
screenGui.Parent = CoreGui
screenGui.ResetOnSpawn = false

-- Функции утилиты
local function getAccountInfo()
    local player = Players.LocalPlayer
    return player and player.Name or "Неизвестный аккаунт"
end

local function getServerId()
    local jobId = game.JobId
    return jobId ~= "" and jobId or "Одиночная игра"
end

local function incomeToNumber(incomeStr)
    if incomeStr == "???/s" then return 0 end
    
    local value = tonumber(incomeStr:match("%d+%.?%d*"))
    local unit = incomeStr:match("([MK])/s")
    
    if unit == "M" then
        return value * 1000000
    elseif unit == "K" then
        return value * 1000
    else
        return value
    end
end

local function formatIncomeNumber(num)
    if num >= 1000000 then
        local mValue = num/1000000
        return string.format(mValue % 1 == 0 and "%dM/s" or "%.1fM/s", mValue):gsub("%.0M/s", "M/s")
    elseif num >= 1000 then
        local kValue = num/1000
        return string.format(kValue % 1 == 0 and "%dK/s" or "%.1fK/s", kValue):gsub("%.0K/s", "K/s")
    else
        return string.format("%d/s", num)
    end
end

local function getMutationEmoji(mutation)
    return MUTATION_EMOJIS[mutation] or "⬜️"
end

-- Функции для сбора информации об объектах
local function findMutation(obj)
    local mutation = obj:GetAttribute("Mutation")
    if mutation then return tostring(mutation) end
    
    for _, child in ipairs(obj:GetDescendants()) do
        if child:IsA("StringValue") and child.Name == "Mutation" then
            return child.Value
        end
        
        if child:IsA("ObjectValue") and child.Name == "Mutation" and child.Value then
            return child.Value.Name
        end
    end
    
    local nameParts = obj.Name:split(" ")
    for _, part in ipairs(nameParts) do
        if MUTATION_MULTIPLIERS[part] then
            return part
        end
    end
    
    return nil
end

local function findTraits(obj)
    local traits = {}
    
    local traitsAttr = obj:GetAttribute("Traits")
    if traitsAttr then
        if type(traitsAttr) == "table" then
            for _, v in pairs(traitsAttr) do
                table.insert(traits, tostring(v))
            end
        else
            table.insert(traits, tostring(traitsAttr))
        end
    end
    
    for _, child in ipairs(obj:GetDescendants()) do
        if child:IsA("StringValue") and (child.Name == "Trait" or child.Name == "Traits") then
            table.insert(traits, child.Value)
        end
    end
    
    for _, child in ipairs(obj:GetDescendants()) do
        if child:IsA("ObjectValue") and (child.Name == "Trait" or child.Name == "Traits") and child.Value then
            table.insert(traits, child.Value.Name)
        end
    end
    
    return traits
end

local function scanObject(obj)
    if not obj or not obj.Parent then return nil end
    
    local mutation = findMutation(obj)
    local traits = findTraits(obj)
    local baseIncomeStr = OBJECT_INCOME[obj.Name] or "0/s"
    local baseIncome = incomeToNumber(baseIncomeStr)
    
    -- Раздельные множители
    local mutationMultiplier = 1
    local traitsMultiplier = 1
    local appliedMutation = {}
    local appliedTraits = {}

    -- Применяем множитель мутации
    if mutation and MUTATION_MULTIPLIERS[mutation] then
        mutationMultiplier = MUTATION_MULTIPLIERS[mutation]
        table.insert(appliedMutation, mutation.." (x"..MUTATION_MULTIPLIERS[mutation]..")")
    end

    -- Применяем множители трейтов
    for _, trait in ipairs(traits) do
        if TRAIT_MULTIPLIERS[trait] then
            traitsMultiplier = traitsMultiplier * TRAIT_MULTIPLIERS[trait]
            table.insert(appliedTraits, trait.." (x"..TRAIT_MULTIPLIERS[trait]..")")
        end
    end

    -- Рассчитываем итоговый доход (формула: base * mutation + base * (traits - 1))
    local finalIncome = baseIncome
    if baseIncomeStr ~= "???/s" then
        finalIncome = baseIncome * mutationMultiplier + baseIncome * (traitsMultiplier - 1)
    end

    return {
        name = obj.Name,
        mutation = mutation,
        traits = traits,
        baseIncome = baseIncomeStr,
        finalIncome = formatIncomeNumber(finalIncome),
        mutationMultiplier = mutationMultiplier,
        traitsMultiplier = traitsMultiplier,
        appliedMutation = appliedMutation,
        appliedTraits = appliedTraits,
        numericIncome = finalIncome
    }
end

local function createColoredText(objData)
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0, 350, 0, 50)
    textLabel.BackgroundTransparency = 1
    textLabel.TextSize = ESP_SETTINGS.TextSize
    textLabel.Font = ESP_SETTINGS.Font
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextStrokeTransparency = 0.3
    
    local emoji = OBJECT_EMOJIS[objData.name] or "🔹"
    local incomeText = objData.finalIncome ~= "???/s" and objData.finalIncome or "???"
    
    local richText = string.format(
        '<font color="rgb(255,255,255)">%s%s %s: %s</font>',
        emoji, getMutationEmoji(objData.mutation), objData.name, incomeText
    )
    
    -- Показываем мутации и трейты с их множителями
    if objData.mutation and MUTATION_MULTIPLIERS[objData.mutation] then
        richText = richText .. string.format(
            '\n<font color="rgb(255,255,150)">%s x%.2f</font>',
            objData.mutation, objData.mutationMultiplier
        )
    end
    
    if #objData.traits > 0 then
        richText = richText .. '\n<font color="rgb(150,255,150)">'
        for _, trait in ipairs(objData.traits) do
            if TRAIT_MULTIPLIERS[trait] then
                richText = richText .. string.format('%s x%.2f ', trait, TRAIT_MULTIPLIERS[trait])
            else
                richText = richText .. trait .. ' '
            end
        end
        richText = richText .. '</font>'
    end
    
    textLabel.Text = richText
    textLabel.RichText = true
    return textLabel
end

local function createESPElement(obj)
    local rootPart = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")) or obj
    if not rootPart then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 350, 0, 80)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = ESP_SETTINGS.MaxDistance
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    
    local objData = scanObject(obj)
    local textLabel = createColoredText(objData)
    textLabel.Parent = billboard
    
    billboard.Adornee = rootPart
    billboard.Parent = screenGui
    
    return {
        labelGui = billboard,
        label = textLabel,
        rootPart = rootPart,
        object = obj,
        data = objData
    }
end

local function canSendNotification(botType)
    local currentServer = getServerId()
    local now = os.time()
    local lastNotificationTime = botType == "main" and lastNotificationTimeMain or lastNotificationTimeSpecial
    
    if currentServer == lastServerNotified and now - lastNotificationTime < 7 then
        return false
    end
    
    if botType == "main" then
        lastNotificationTimeMain = now
    else
        lastNotificationTimeSpecial = now
    end
    lastServerNotified = currentServer
    return true
end

local function sendMainTelegramAlert()
    if not TG_MAIN.Enabled or not request or #objectsToNotifyMain == 0 then return end
    if not canSendNotification("main") then return end
    
    local serverId = getServerId()
    local username = getAccountInfo()
    
    local importantObjects = {}
    local regularObjects = {}
    
    for _, objData in ipairs(objectsToNotifyMain) do
        if TG_MAIN.ImportantObjects[objData.name] then
            table.insert(importantObjects, objData)
        else
            table.insert(regularObjects, objData)
        end
    end
    
    local message = string.format(
        "*🔍 Обнаружены объекты в Steal a brainrot*\n"..
        "👤 Игрок: `@%s`\n"..
        "🌐 Сервер: `%s`\n"..
        "🕘 Время: `%s`\n\n",
        username, serverId, os.date("%X")
    )
    
    if #importantObjects > 0 then
        message = message .. "*🚨 ВАЖНЫЕ ОБЪЕКТЫ:*\n"
        for _, objData in ipairs(importantObjects) do
            local emoji = OBJECT_EMOJIS[objData.name] or "⚠️"
            local mutationEmoji = getMutationEmoji(objData.mutation)
            
            message = message .. string.format("%s%s %s (%s)", emoji, mutationEmoji, objData.name, objData.finalIncome)
            
            if #objData.traits > 0 then
                message = message .. " " .. table.concat(objData.traits, " ")
            end
            
            message = message .. "\n"
        end
        message = message .. "\n"
    end
    
    if #regularObjects > 0 then
        message = message .. "*🔹 Обычные объекты:*\n"
        for _, objData in ipairs(regularObjects) do
            local emoji = OBJECT_EMOJIS[objData.name] or "🔸"
            local mutationEmoji = getMutationEmoji(objData.mutation)
            
            message = message .. string.format("%s%s %s (%s)", emoji, mutationEmoji, objData.name, objData.finalIncome)
            
            if #objData.traits > 0 then
                message = message .. " " .. table.concat(objData.traits, " ")
            end
            
            message = message .. "\n"
        end
    end
    
    if serverId ~= "Одиночная игра" then
        message = message .. string.format(
            "\n🚀 Телепорт:\n```lua\nlocal ts = game:GetService('TeleportService')\nts:TeleportToPlaceInstance(109983668079237, '%s')\n```",
            serverId
        )
    end
    
    request({
        Url = "https://api.telegram.org/bot"..TG_MAIN.Token.."/sendMessage",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode({
            chat_id = TG_MAIN.ChatId,
            text = message,
            parse_mode = "Markdown"
        })
    })
end

local function sendSpecialTelegramAlert()
    if not TG_SPECIAL.Enabled or not request or #objectsToNotifySpecial == 0 then return end
    if not canSendNotification("special") then return end
    
    local serverId = getServerId()
    local username = getAccountInfo()
    
    local message = string.format(
        "*🔍 Обнаружены объекты в Steal a brainrot*\n"..
        "👤 Игрок: `@%s`\n"..
        "🌐 Сервер: `%s`\n"..
        "🕘 Время: `%s`\n\n"..
        "*🔸 Объекты с низким доходом:*\n",
        username, serverId, os.date("%X")
    )
    
    for _, objData in ipairs(objectsToNotifySpecial) do
        local emoji = OBJECT_EMOJIS[objData.name] or "🔸"
        local mutationEmoji = getMutationEmoji(objData.mutation)
        
        message = message .. string.format("%s%s %s (%s)", emoji, mutationEmoji, objData.name, objData.finalIncome)
        
        if #objData.traits > 0 then
            message = message .. " " .. table.concat(objData.traits, " ")
        end
        
        message = message .. "\n"
    end
    
    if serverId ~= "Одиночная игра" then
        message = message .. string.format(
            "\n🚀 Телепорт:\n```lua\nlocal ts = game:GetService('TeleportService')\nts:TeleportToPlaceInstance(109983668079237, '%s')\n```",
            serverId
        )
    end
    
    request({
        Url = "https://api.telegram.org/bot"..TG_SPECIAL.Token.."/sendMessage",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode({
            chat_id = TG_SPECIAL.ChatId,
            text = message,
            parse_mode = "Markdown"
        })
    })
end

local function playDetectionSound()
    local sound = Instance.new("Sound")
    sound.SoundId = ESP_SETTINGS.SoundId
    sound.Volume = ESP_SETTINGS.SoundVolume
    sound.Parent = workspace
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 3)
end

local function updateESP(deltaTime)
    lastUpdate = lastUpdate + deltaTime
    if lastUpdate < ESP_SETTINGS.UpdateInterval then return end
    lastUpdate = 0

    -- Очистка кэша
    for obj, data in pairs(espCache) do
        if not obj.Parent or not data.rootPart.Parent then
            data.labelGui:Destroy()
            espCache[obj] = nil
            foundObjects[obj] = nil
        end
    end

    -- Сброс списков для уведомлений перед новым сканированием
    objectsToNotifyMain = {}
    objectsToNotifySpecial = {}

    -- Поиск объектов
    for _, obj in ipairs(workspace:GetDescendants()) do
        if table.find(OBJECT_NAMES, obj.Name) and (obj:IsA("BasePart") or obj:IsA("Model")) then
            local rootPart = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")) or obj
            if not rootPart then continue end

            local distance = (rootPart.Position - camera.CFrame.Position).Magnitude
            if distance > ESP_SETTINGS.MaxDistance then
                if espCache[obj] then
                    espCache[obj].labelGui.Enabled = false
                end
                continue
            end

            local isNewObject = not foundObjects[obj]
            foundObjects[obj] = true

            if not espCache[obj] then
                espCache[obj] = createESPElement(obj)
                local objData = espCache[obj].data
                playDetectionSound()
                
                -- Добавляем в соответствующий список для уведомлений
                if TG_MAIN.ImportantObjects[obj.Name] or objData.numericIncome >= 3000000 then
                    table.insert(objectsToNotifyMain, objData)
                else
                    table.insert(objectsToNotifySpecial, objData)
                end
            end

            -- Обновление видимости ESP
            local data = espCache[obj]
            local _, onScreen = camera:WorldToViewportPoint(rootPart.Position)
            data.labelGui.Enabled = onScreen
        end
    end
    
    -- Отправка уведомлений (независимо друг от друга)
    if #objectsToNotifyMain > 0 then
        sendMainTelegramAlert()
    end
    
    if #objectsToNotifySpecial > 0 then
        sendSpecialTelegramAlert()
    end
end

-- Запуск системы
RunService.Heartbeat:Connect(updateESP)

-- Обработка игроков
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        updateESP(0)
    end)
end)

-- Обработчик клавиши сканера
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == SCANNER_SETTINGS.ScanKey then
        local now = os.time()
        if now - lastScanTime < SCANNER_SETTINGS.DebounceTime then
            print("Подождите...")
            return
        end
        
        lastScanTime = now
        print("\n🔍 Начинаем сканирование всех объектов...")
        
        local foundCount = 0
        
        for _, obj in ipairs(workspace:GetDescendants()) do
            if table.find(OBJECT_NAMES, obj.Name) and (obj:IsA("BasePart") or obj:IsA("Model")) then
                local details = scanObject(obj)
                if details then
                    foundCount = foundCount + 1
                    print("\n=== ОБЪЕКТ #"..foundCount.." ===")
                    print("Имя:", details.name)
                    print("Доход:", details.finalIncome)
                    if details.mutation then
                        print("Мутация:", details.mutation.." (x"..details.mutationMultiplier..")")
                    end
                    print("Traits ("..#details.traits.."):")
                    for i, trait in ipairs(details.traits) do
                        local multiplier = TRAIT_MULTIPLIERS[trait] and " (x"..TRAIT_MULTIPLIERS[trait]..")" or ""
                        print(i..".", trait..multiplier)
                    end
                end
            end
        end
        
        if foundCount == 0 then
            print("❌ Объекты не найдены")
        else
            print("\n=== РЕЗУЛЬТАТ ===")
            print("Найдено объектов:", foundCount)
        end
    end
end)

-- Первоначальное сканирование
updateESP(0)

print("Steal a brainrot ESP System активирован!")
print("Отслеживается объектов: "..#OBJECT_NAMES)
print("ID сервера:", getServerId())
print("\nНажмите F для сканирования всех объектов")
