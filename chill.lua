-- FIXED PERMANENT VISUAL SELF-INVISIBILITY SCRIPT
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Переменные
local isInvisible = true
local originalProperties = {}

-- Функция для скрытия персонажа (без отключения инструментов)
local function hideCharacter()
    local character = LocalPlayer.Character
    if not character then return false end
    
    -- Сохраняем оригинальные свойства
    originalProperties = {}
    
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            originalProperties[part] = {
                Transparency = part.Transparency,
                LocalTransparencyModifier = part.LocalTransparencyModifier
            }
            
            -- Делаем часть полностью прозрачной
            part.Transparency = 1
            part.LocalTransparencyModifier = 1
        elseif part:IsA("Decal") then
            originalProperties[part] = {
                Transparency = part.Transparency
            }
            part.Transparency = 1
        elseif part:IsA("ParticleEmitter") then
            originalProperties[part] = {Enabled = part.Enabled}
            part.Enabled = false
        elseif part:IsA("Beam") then
            originalProperties[part] = {Enabled = part.Enabled}
            part.Enabled = false
        elseif part:IsA("Trail") then
            originalProperties[part] = {Enabled = part.Enabled}
            part.Enabled = false
        end
    end
    
    -- НЕ отключаем инструменты в инвентаре - оставляем их функциональными
    -- Только скрываем визуально, если они уже в руках персонажа
    
    -- Скрываем одежду и аксессуары
    for _, accessory in pairs(character:GetChildren()) do
        if accessory:IsA("Accessory") then
            local handle = accessory:FindFirstChild("Handle")
            if handle then
                originalProperties[handle] = {
                    Transparency = handle.Transparency,
                    LocalTransparencyModifier = handle.LocalTransparencyModifier
                }
                handle.Transparency = 1
                handle.LocalTransparencyModifier = 1
            end
        end
    end
    
    return true
end

-- Функция для принудительного скрытия новых частей
local function forceHideNewParts()
    local character = LocalPlayer.Character
    if not character then return end
    
    -- Постоянно проверяем и скрываем новые части, но не трогаем функциональность инструментов
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and (part.Transparency < 1 or part.LocalTransparencyModifier < 1) then
            -- Пропускаем инструменты, которые могут быть функциональными
            local isToolPart = false
            local parent = part.Parent
            while parent do
                if parent:IsA("Tool") then
                    isToolPart = true
                    break
                end
                parent = parent.Parent
            end
            
            if not isToolPart then
                part.Transparency = 1
                part.LocalTransparencyModifier = 1
            end
        elseif part:IsA("ParticleEmitter") and part.Enabled then
            part.Enabled = false
        elseif part:IsA("Beam") and part.Enabled then
            part.Enabled = false
        elseif part:IsA("Trail") and part.Enabled then
            part.Enabled = false
        end
    end
end

-- Основная функция активации невидимости
local function activatePermanentInvisibility()
    -- Сразу применяем к текущему персонажу
    if LocalPlayer.Character then
        hideCharacter()
    end
    
    -- Создаем постоянный цикл для поддержания невидимости
    RunService.Heartbeat:Connect(function()
        if LocalPlayer.Character then
            forceHideNewParts()
        end
    end)
end

-- Обработчик смены персонажа
LocalPlayer.CharacterAdded:Connect(function(character)
    wait(0.5) -- Ждем полной загрузки персонажа
    hideCharacter()
end)

-- Создаем простой индикатор статуса
local function createStatusIndicator()
    if LocalPlayer.PlayerGui:FindFirstChild("PermanentInvisibilityStatus") then
        LocalPlayer.PlayerGui.PermanentInvisibilityStatus:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PermanentInvisibilityStatus"
    screenGui.Parent = LocalPlayer.PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 40)
    frame.Position = UDim2.new(0.02, 0, 0.02, 0)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Text = "PERMANENT INVISIBILITY: ACTIVE"
    label.TextColor3 = Color3.new(0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextScaled = true
    label.Parent = frame
    
    return screenGui
end

-- Инициализация при загрузке
coroutine.wrap(function()
    wait(2) -- Ждем полной загрузки игры
    
    -- Активируем постоянную невидимость
    activatePermanentInvisibility()
    
    -- Создаем индикатор статуса
    if LocalPlayer.PlayerGui then
        createStatusIndicator()
    else
        LocalPlayer:WaitForChild("PlayerGui")
        createStatusIndicator()
    end
    
    -- Сообщение об успешной активации
    game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
        Text = "ПОСТОЯННАЯ НЕВИДИМОСТЬ АКТИВИРОВАНА! Ваш персонаж теперь невидим для вас. Инструменты остаются функциональными.",
        Color = Color3.new(0, 1, 0),
        Font = Enum.Font.SourceSansBold,
        FontSize = Enum.FontSize.Size18
    })
    
    print("=== PERMANENT INVISIBILITY ACTIVATED ===")
end)()

-- Дополнительная защита: перехват новых объектов
local function monitorNewObjects()
    LocalPlayer.CharacterAdded:Connect(function(character)
        -- Мониторим добавление новых объектов к персонажу
        character.DescendantAdded:Connect(function(descendant)
            wait(0.1) -- Небольшая задержка для стабильности
            if isInvisible then
                -- Проверяем, не является ли объект частью инструмента
                local isToolPart = false
                local parent = descendant.Parent
                while parent do
                    if parent:IsA("Tool") then
                        isToolPart = true
                        break
                    end
                    parent = parent.Parent
                end
                
                if not isToolPart then
                    if descendant:IsA("BasePart") then
                        descendant.Transparency = 1
                        descendant.LocalTransparencyModifier = 1
                    elseif descendant:IsA("ParticleEmitter") then
                        descendant.Enabled = false
                    elseif descendant:IsA("Beam") then
                        descendant.Enabled = false
                    elseif descendant:IsA("Trail") then
                        descendant.Enabled = false
                    end
                end
            end
        end)
    end)
end

-- Запускаем мониторинг новых объектов
monitorNewObjects()

-- Функция для экстренного восстановления видимости (на случай проблем)
local function emergencyRestoreVisibility()
    isInvisible = false
    local character = LocalPlayer.Character
    if not character then return end
    
    for part, properties in pairs(originalProperties) do
        if part and part.Parent then
            if part:IsA("BasePart") then
                part.Transparency = properties.Transparency or 0
                part.LocalTransparencyModifier = properties.LocalTransparencyModifier or 0
            elseif part:IsA("Decal") then
                part.Transparency = properties.Transparency or 0
            elseif part:IsA("ParticleEmitter") or part:IsA("Beam") or part:IsA("Trail") then
                part.Enabled = properties.Enabled
            end
        end
    end
    
    originalProperties = {}
    
    game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
        Text = "ВИДИМОСТЬ ВОССТАНОВЛЕНА!",
        Color = Color3.new(1, 0, 0),
        Font = Enum.Font.SourceSansBold,
        FontSize = Enum.FontSize.Size18
    })
end

-- Добавляем команду для восстановления видимости в консоль (на крайний случай)
print("=== EMERGENCY COMMAND ===")
print("If something goes wrong, run: emergencyRestoreVisibility()")
