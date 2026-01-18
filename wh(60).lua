if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(10)

-- // SERVICES //
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local PathfindingService = game:GetService("PathfindingService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- // WEBHOOKS //
local MerchantWebhookURL = "https://discord.com/api/webhooks/1462013112113823889/wDp25t3SwiUzulr54VNo28uAwiRfnatr20oJyitUWV0YUnYBBORaWGUEqbfP4xYRr5sn"
local StatsWebhookURL = "https://discord.com/api/webhooks/1461362837904429188/IPZwXAQc_zO5MJ6AGAq25wOyEjs41956LuoPEGOusq_7IdKH8dgWQ4SKqqdz0s3RqG85"

-- // CONFIGURATION //
getgenv().pathfindToken = 0
getgenv().StopShootingForQuest = false 
getgenv().FishmanKills = 0
getgenv().MerchantActive = false -- Флаг для остановки рыбалки во время покупки

local GlobalConfig = {
    -- Movement Settings
    Step = 1.0,
    FallSpeed = 2,
    HipHeight = 3.5,
    WallTPHeight = 100,
    WallCheckRange = 9,
    
    -- Level Farm Settings
    RiflePrice = 300,
    TargetLevel = 381, -- Установлено целевое значение для перехода к рыбалке
    
    -- Fishing Settings
    maxBaitToBuy = 50,
    baitCostPeli = 45,
    autoFishingBait = "Common Fish Bait",
    fishingRodPos = Vector3.new(-1341, 4, -4981),
    selectedFishingRod = "Fishing Rod",
    
    -- Items Data
    MerchantTargetItems = {
        "Mythical Fruit Chest",
    },
    
    FishToSell = {
        "Anglerfish", "Swordfish", "Golden Polka Puffer", "Skeletal Shark", "Common Fish",
        "Fangfish", "Crimson Polka Puffer", "Exotic Tigerfin", "Tigerfin", "Blue-Lip Grouper",
        "Rare Fish", "Legendary Fish", "Mythical Fish", "Ancient Fish", "Gold Fish", "Zebra Ribbon Angelfish",
        "Crimson Snapper", "Golden Ribbon Angelfish", "Golden Tigerin"
    },
    
    -- Positions
    Pos = {
        RifleShop = Vector3.new(-532, 6, -3448),
        QuestNPC = Vector3.new(-548, 6, -3403),
        BeckyQuest = Vector3.new(7735, -2176, -17223),
        FishmanFarm = Vector3.new(7838.7, -2151.3, -17134.5),
        FishmanSpawnSet = Vector3.new(7976.2, -2152.8, -17075.1), -- Координата из smth.txt
        
        -- Transition Coordinates
        TransitionPoint1 = Vector3.new(8580, -2139, -17088),
        FishingSpot = Vector3.new(-1297, 4, -5057)
    }
}

-- // REMOTES //
local rs_events = ReplicatedStorage:WaitForChild("Events")
local playgame_remote = rs_events:FindFirstChild("playgame")
local quest_remote = rs_events:FindFirstChild("Quest")
local takestam_remote = rs_events:FindFirstChild("takestam")
local shop_remote = rs_events:FindFirstChild("Shop")
local tools_remote = rs_events:FindFirstChild("Tools")
local fishing_remote = ReplicatedStorage:FindFirstChild("Fishing") and ReplicatedStorage.Fishing.Remotes.Action
local merchant_remote = rs_events:FindFirstChild("TravelingMerchentRemote")

-- // UTILITY FUNCTIONS //

local function GetStatsFolder()
    return ReplicatedStorage:FindFirstChild("Stats" .. LocalPlayer.Name)
end

local function GetPeli()
    local folder = GetStatsFolder()
    if folder and folder:FindFirstChild("Stats") then
        return folder.Stats.Peli.Value
    end
    return 0
end

local function GetLevel()
    local folder = GetStatsFolder()
    if folder and folder:FindFirstChild("Stats") and folder.Stats:FindFirstChild("Level") then
        return folder.Stats.Level.Value
    end
    return 0
end

local function GetChar()
    local Char = LocalPlayer.Character
    if Char then
        return Char, Char:FindFirstChild("HumanoidRootPart"), Char:FindFirstChild("Humanoid")
    end
    return nil, nil, nil
end

local function FireDash()
    if takestam_remote then
        takestam_remote:FireServer(0.56, "dash")
    end
end

-- // MOVEMENT SYSTEM (Unified) //
local function TweenMove(targetPos)
    local char, rootPart, _ = GetChar()
    if not rootPart then return end
    
    getgenv().pathfindToken = getgenv().pathfindToken + 1
    local myToken = getgenv().pathfindToken
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {char}
    rayParams.IgnoreWater = true
    
    local lastWallTP = 0
    
    while (rootPart.Position - targetPos).Magnitude > 4 and myToken == getgenv().pathfindToken do
        local currentPos = rootPart.Position
        local delta = targetPos - currentPos
        local dirXZ = Vector3.new(delta.X, 0, delta.Z).Unit
        local nextXZ = currentPos + dirXZ * GlobalConfig.Step
        
        local wallResult = Workspace:Raycast(currentPos, dirXZ * GlobalConfig.WallCheckRange, rayParams)
        
        if wallResult and wallResult.Instance.CanCollide and (tick() - lastWallTP > 0.3) then
            lastWallTP = tick()
            FireDash()
            local forwardPos = wallResult.Position + (dirXZ * 2)
            local topCheck = Workspace:Raycast(forwardPos + Vector3.new(0, GlobalConfig.WallTPHeight, 0), Vector3.new(0, -GlobalConfig.WallTPHeight * 2, 0), rayParams)
            local jumpY = topCheck and (topCheck.Position.Y + GlobalConfig.HipHeight) or (currentPos.Y + 15)
            rootPart.CFrame = CFrame.new(forwardPos.X, jumpY, forwardPos.Z)
            task.wait(0.05)
        else
            local groundRay = Workspace:Raycast(nextXZ + Vector3.new(0, 15, 0), Vector3.new(0, -50, 0), rayParams)
            local finalY = groundRay and (groundRay.Position.Y + GlobalConfig.HipHeight) or (currentPos.Y - GlobalConfig.FallSpeed)
            if targetPos.Y > -1000 then 
                finalY = math.max(finalY, 2)
            end
            rootPart.CFrame = CFrame.new(nextXZ.X, finalY, nextXZ.Z)
        end
        RunService.Heartbeat:Wait()
    end
end

local function PathfindTo(target)
    local targetPos = typeof(target) == "Vector3" and target or (typeof(target) == "CFrame" and target.Position or target.Position)
    TweenMove(targetPos)
end

-- // WEBHOOK LOGIC //

local function SendStatsWebhook()
    local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if not httpRequest then return end
    
    local historyLvl = nil
    local historyPeli = nil
    local firstRun = true
    
    while true do
        local currentLvl = GetLevel()
        local currentPeli = GetPeli()
        
        local payload = {
            ["username"] = "Onyx Squad [Private]",
            ["avatar_url"] = "https://cdn.discordapp.com/attachments/1455503437000347713/1461361287882735832/latest.png",
            ["embeds"] = {{
                ["title"] = "**Onyx Squad have info for you!**",
                ["description"] = string.format(
                    "Player: %s\n\nCurrent Lvl: %s\nCurrent Peli: %s\n\nLvl 10 min ago: %s\nPeli 10 min ago: %s",
                    LocalPlayer.Name,
                    tostring(currentLvl),
                    tostring(currentPeli),
                    tostring(historyLvl or "nil"),
                    tostring(historyPeli or "nil")
                ),
                ["color"] = 9807270,
                ["image"] = { ["url"] = "https://media.discordapp.net/attachments/1455503437000347713/1461359339272147037/image.png?ex=696a4471&is=6968f2f1&hm=1a5fe16b73e7a8f6d830a10f3a704ea21b7240fa929ca23b1a17ebc826a6d350&=&format=webp&quality=lossless" }
            }}
        }
        
        httpRequest({
            Url = StatsWebhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
        
        if firstRun then
            historyLvl = currentLvl
            historyPeli = currentPeli
            firstRun = false
        end
        
        task.wait(600)
        historyLvl = currentLvl
        historyPeli = currentPeli
    end
end

local function SendMerchantWebhook(stockText, boughtItems, peliBefore, peliAfter)
    local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if not httpRequest then return end

    local description = string.format("👤 **Player:** `%s`\n💰 **Current Peli:** `%d`\n\n**📦 [ MERCHANT STOCK ]**\n%s", 
        LocalPlayer.Name, peliAfter, stockText)
    
    if #boughtItems > 0 then
        description = description .. string.format("\n**🛒 [ PURCHASE LOG ]**\n✅ **Bought:** %s\n💸 **Transaction:** `%d` ➔ `%d`", 
            table.concat(boughtItems, ", "), peliBefore, peliAfter)
    else
        description = description .. "\n*❌ Ничего не куплено.*"
    end

    local payload = {
        ["username"] = "Onyx Squad | Merchant Tracker",
        ["avatar_url"] = "https://cdn.discordapp.com/attachments/1455503437000347713/1461361287882735832/latest.png",
        ["embeds"] = {{
            ["title"] = "🏪 Traveling Merchant Found!",
            ["description"] = description,
            ["color"] = 8421504,
            ["image"] = { ["url"] = "https://media.discordapp.net/attachments/1455503437000347713/1461359339272147037/image.png" },
            ["footer"] = { ["text"] = "Onyx Squad Private Service • " .. os.date("%X") }
        }}
    }

    httpRequest({
        Url = MerchantWebhookURL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode(payload)
    })
end

-- // LEVEL FARM & QUEST LOGIC //

local function HopServer()
    local sfUrl = "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=25"
    local success, result = pcall(function() return game:HttpGet(string.format(sfUrl, game.PlaceId)) end)
    if success then
        local servers = HttpService:JSONDecode(result)
        local candidates = {} 
        if servers and servers.data then
            for _, s in pairs(servers.data) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    table.insert(candidates, s)
                end
            end
        end
        if #candidates > 0 then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, candidates[math.random(1, #candidates)].id, LocalPlayer)
        end
    end
end

task.spawn(function()
    task.wait(18 * 60)
    HopServer()
end)

local function GetIslandData(islandName)
    local island = Workspace.Islands:FindFirstChild(islandName)
    if island then
        local cf, size = island:GetBoundingBox()
        return cf, size
    end
    return nil, nil
end

local function IsPositionOnIsland(pos, islandName)
    local cf, size = GetIslandData(islandName)
    if not cf then return false end
    local localPos = cf:PointToObjectSpace(pos)
    return math.abs(localPos.X) <= size.X/2 and math.abs(localPos.Z) <= size.Z/2
end

local function HasRifle()
    return LocalPlayer.Backpack:FindFirstChild("Rifle") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Rifle"))
end

local function GetGunObject(tool)
    for _, connection in pairs(getconnections(tool.Equipped)) do
        local func = connection.Function
        if func then
            local upvalues = debug.getupvalues(func)
            for _, val in pairs(upvalues) do
                if type(val) == "table" and val["Reloaded"] ~= nil then return val end
            end
        end
    end
    return nil
end

local function GetLivingFishman()
    if not Workspace:FindFirstChild("NPCs") then return nil end
    for _, npc in ipairs(Workspace.NPCs:GetChildren()) do
        if npc.Name == "Fishman Karate User" and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 and npc:FindFirstChild("Head") then
            return npc
        end
    end
    return nil
end

local function StartShooting()
    local tool = LocalPlayer.Backpack:FindFirstChild("Rifle") or LocalPlayer.Character:FindFirstChild("Rifle")
    if tool then
        if not LocalPlayer.Character:FindFirstChild("Rifle") then
            LocalPlayer.Character.Humanoid:EquipTool(tool)
        end
        local GunObject = GetGunObject(tool)
        local GunHandle = require(ReplicatedStorage.Modules.GunHandle)
        if GunObject then
            task.spawn(function()
                while task.wait() do
                    if GetLevel() >= GlobalConfig.TargetLevel then break end 
                    if getgenv().StopShootingForQuest then 
                        task.wait(0.5)
                        continue 
                    end
                    local targetNPC = GetLivingFishman()
                    if targetNPC then
                        while targetNPC and targetNPC.Parent and targetNPC:FindFirstChild("Humanoid") and targetNPC.Humanoid.Health > 0 do
                            if getgenv().StopShootingForQuest or GetLevel() >= GlobalConfig.TargetLevel then break end
                            if not GunObject.Reloaded then
                                GunHandle.Reload(GunObject)
                            else
                                local playerModels = Workspace:FindFirstChild("PlayerCharacters")
                                local myCharModel = playerModels and playerModels:FindFirstChild(LocalPlayer.Name)
                                local gunPart = myCharModel and myCharModel:FindFirstChild("RifleGun")
                                if gunPart and gunPart:FindFirstChild("Hole") and targetNPC:FindFirstChild("Head") then
                                    local args = {"fire", {
                                        Start = gunPart.Hole.CFrame,
                                        Gun = "Rifle",
                                        joe = "true",
                                        Position = targetNPC.Head.Position
                                    }}
                                    ReplicatedStorage.Events.CIcklcon:FireServer(unpack(args))
                                    GunObject.Reloaded = false
                                end
                            end
                            task.wait() 
                        end
                        if targetNPC and targetNPC:FindFirstChild("Humanoid") and targetNPC.Humanoid.Health <= 0 then
                            getgenv().FishmanKills = getgenv().FishmanKills + 1
                        end
                    end
                end
            end)
        end
    end
end

local function DoChestFarm(islandName)
    local targetIsland = islandName or "Town of Beginnings"
    local _, root = GetChar()
    if not root or not Workspace:FindFirstChild("Env") then return false end
    
    local nearest_prompt = nil
    local min_dist = math.huge
    
    for _, part in ipairs(Workspace.Env:GetChildren()) do
        if part:IsA("BasePart") and IsPositionOnIsland(part.Position, targetIsland) then
            local prompt = part:FindFirstChildOfClass("ProximityPrompt")
            if prompt then
                local dist = (root.Position - part.Position).Magnitude
                if dist < min_dist then
                    min_dist = dist
                    nearest_prompt = prompt
                end
            end
        end
    end
    
    if nearest_prompt then
        PathfindTo(nearest_prompt.Parent.Position + Vector3.new(0, 2, 0))
        fireproximityprompt(nearest_prompt)
        task.wait(0.5)
        return true
    end
    return false
end

-- // FISHING LOGIC //

local function GetInventory()
    local stats = GetStatsFolder()
    if not stats or not stats:FindFirstChild("Inventory") then return {} end
    local ok, inv = pcall(function() return HttpService:JSONDecode(stats.Inventory.Inventory.Value) end)
    return ok and inv or {}
end

local function HasItem(name)
    local inv = GetInventory()
    return inv[name] ~= nil
end

local function GetBaitCount()
    local inv = GetInventory()
    return tonumber(inv[GlobalConfig.autoFishingBait]) or 0
end

local function HasFish()
    local inv = GetInventory()
    for _, name in ipairs(GlobalConfig.FishToSell) do
        if inv[name] and tonumber(inv[name]) > 0 then
            return true
        end
    end
    return false
end

local function AutoSellFish()
    local shopRemote = ReplicatedStorage:FindFirstChild("FishingShopRemote")
    if not shopRemote then return end
    local inv = GetInventory()
    for _, fishName in ipairs(GlobalConfig.FishToSell) do
        if inv[fishName] and tonumber(inv[fishName]) > 0 then
            shopRemote:InvokeServer({["Fish"] = fishName, ["All"] = true, ["Method"] = "SellFish"})
            task.wait(0.1)
        end
    end
end

local function EquipRod()
    local args = {"equip", GlobalConfig.selectedFishingRod}
    tools_remote:InvokeServer(unpack(args))
    local char, _, hum = GetChar()
    local tool = LocalPlayer.Backpack:FindFirstChild(GlobalConfig.selectedFishingRod)
    if hum and tool then hum:EquipTool(tool) end
end

local function FishingLoop()
    print("[SYSTEM]: Starting Fishing Loop")
    while true do
        -- Check if paused by Merchant
        if getgenv().MerchantActive then
            print("[FISHING]: Paused for Merchant...")
            task.wait(2)
            continue
        end

        local peli = GetPeli()
        local baits = GetBaitCount()
        local fish = HasFish()

        if baits <= 0 then
            if fish then
                AutoSellFish()
            end
            
            if GetPeli() < GlobalConfig.baitCostPeli and not HasFish() then
                if not DoChestFarm("Town of Beginnings") then 
                    task.wait(1)
                end
            else
                print("[FISHING]: Buying Bait")
                PathfindTo(GlobalConfig.fishingRodPos)
                
                -- Купить удочку если нет
                if not HasItem(GlobalConfig.selectedFishingRod) and GetPeli() >= 100 then
                    shop_remote:InvokeServer(Workspace.BuyableItems[GlobalConfig.selectedFishingRod], 1)
                    task.wait(0.5)
                end
                
                local toBuy = math.min(math.floor(GetPeli() / GlobalConfig.baitCostPeli), GlobalConfig.maxBaitToBuy)
                if toBuy > 0 then
                    shop_remote:InvokeServer(Workspace.BuyableItems[GlobalConfig.autoFishingBait], toBuy)
                    task.wait(0.5)
                end
            end
        else
            -- Рыбачим
            PathfindTo(GlobalConfig.fishingRodPos)
            EquipRod()
            local _, root = GetChar()
            if root then
                fishing_remote:InvokeServer({Action = "Throw", Bait = GlobalConfig.autoFishingBait, Goal = root.Position + (root.CFrame.LookVector * 20)})
                fishing_remote:InvokeServer({Action = "Landed"})
                
                local hookName = LocalPlayer.Name .. "'s hook"
                local hook = nil
                
                -- Ждем крючок
                for i=1, 15 do
                    hook = Workspace:FindFirstChild("Effects") and Workspace.Effects:FindFirstChild(hookName)
                    if hook then break end
                    RunService.Heartbeat:Wait()
                end
                
                if hook then
                    local start = tick()
                    while hook.Parent and (tick() - start < 150) do
                         if getgenv().MerchantActive then break end -- Прервать если мерчант

                        if hook:GetAttribute("Caught") then
                            local randomWait = math.random(10, 15)
                            print("[FISHING]: Fish caught! Reeling in " .. randomWait .. "s...")
                            task.wait(randomWait)
                            
                            fishing_remote:InvokeServer({Action = "Reel"})
                            fishing_remote:InvokeServer({Action = "Cancel"})
                            fishing_remote:InvokeServer({Action = "HookReturning"})
                            task.wait(0.5)
                            AutoSellFish()
                            break
                        end
                        RunService.Heartbeat:Wait()
                    end
                end
            end
        end
        task.wait(0.1)
    end
end

-- // MERCHANT LOGIC //

local function ProcessMerchant()
    local isHere = false
    pcall(function()
        local compass = LocalPlayer.PlayerGui:FindFirstChild("Compass")
        if compass and compass.Compass.Guiders:FindFirstChild("Traveling Merchant") then
            if compass.Compass.Guiders["Traveling Merchant"].Visible then
                isHere = true
            end
        end
    end)

    if not isHere then return end

    local merchantPos = nil
    pcall(function()
        merchantPos = ReplicatedStorage.CompassGuider["Traveling Merchant"].Value
    end)

    if merchantPos then
        print("[MERCHANT]: Detected! Pausing other tasks.")
        getgenv().MerchantActive = true -- Пауза рыбалки
        
        TweenMove(merchantPos)
        task.wait(1)

        if merchant_remote then
            merchant_remote:InvokeServer("OpenShop")
            local shopGui = LocalPlayer.PlayerGui:WaitForChild("MerchentShop", 10)
            
            if shopGui then
                local pricesAttr = shopGui:GetAttribute("Prices")
                local seed = shopGui:GetAttribute("Seed")
                local peliBefore = GetPeli()
                local currentPeli = peliBefore
                local stockText = ""
                local boughtItems = {}

                if pricesAttr then
                    local stockData = HttpService:JSONDecode(pricesAttr)
                    for itemName, info in pairs(stockData) do
                        stockText = stockText .. string.format("• `%s` | Price: %d | Stock: %d\n", itemName, info.price, info.remaining)
                        
                        if table.find(GlobalConfig.MerchantTargetItems, itemName) then
                            for i = 1, info.remaining do
                                if currentPeli >= info.price then
                                    merchant_remote:InvokeServer(itemName, seed)
                                    table.insert(boughtItems, itemName)
                                    currentPeli = currentPeli - info.price
                                    task.wait(0.3)
                                end
                            end
                        end
                    end
                    SendMerchantWebhook(stockText, boughtItems, peliBefore, currentPeli)
                end
                
                task.wait(1)
                merchant_remote:InvokeServer("Close")
                print("[MERCHANT]: Finished. Sleeping.")
                
                -- Возвращаемся на точку рыбалки после покупок
                TweenMove(GlobalConfig.Pos.FishingSpot)
                
                getgenv().MerchantActive = false -- Возобновление рыбалки
                task.wait(300) -- Пауза проверки мерчанта
            end
        else
             getgenv().MerchantActive = false -- Если ошибка, сбросить флаг
        end
    end
end

-- // MAIN EXECUTION FLOW //

-- 1. Init
if playgame_remote then playgame_remote:FireServer("Main Game") end
task.spawn(SendStatsWebhook) -- Запуск логирования статистики

-- 2. Logic Selector
task.spawn(function()
    while true do
        local myLevel = GetLevel()
        local _, root = GetChar()
        
        -- ЛОГИКА ФАРМА (ДО TARGET LEVEL)
        if myLevel < GlobalConfig.TargetLevel then
            print("[SYSTEM]: Running Level Farm (Lvl < " .. GlobalConfig.TargetLevel .. ")")
            
            -- Прокачка Mastery
            task.spawn(function()
                while GetLevel() < GlobalConfig.TargetLevel do
                    local stats = GetStatsFolder()
                    if stats and stats.Stats.SkillPoints.Value > 0 then
                        ReplicatedStorage.Events.stats:FireServer("GunMastery", nil, 1)
                    end
                    task.wait(2)
                end
            end)

            -- Покупка винтовки
            if not HasRifle() then
                while not HasRifle() do
                     if GetPeli() >= GlobalConfig.RiflePrice then
                        PathfindTo(GlobalConfig.Pos.RifleShop)
                        shop_remote:InvokeServer(Workspace.BuyableItems.Rifle, 1)
                        task.wait(1)
                        tools_remote:InvokeServer("equip", "Rifle")
                     else
                        if not DoChestFarm("Town of Beginnings") then
                             HopServer()
                             task.wait(10)
                        end
                     end
                     task.wait(0.5)
                end
            end
            
            -- Путь до Fishman Island (Глитч под карту)
            if root and not IsPositionOnIsland(root.Position, "Fishman Island") then
                local startPos = Vector3.new(1793.7, 42.7, -12327.4)
                local underPos = CFrame.new(1793.7, -92.7, -12327.4)
                PathfindTo(startPos)
                task.wait(1)
                FireDash()
                local _, charRoot = GetChar()
                if charRoot then 
                    charRoot.CFrame = underPos 
                    task.wait(5)
                    local _, checkRoot = GetChar()
                    if not (checkRoot and IsPositionOnIsland(checkRoot.Position, "Fishman Island")) then
                        HopServer()
                        return 
                    else
                        -- [FIX FROM SMTH.TXT INTEGRATED HERE]
                        -- Мы успешно прилетели на остров. Теперь идем к точке спавна и ставим его.
                        print("[SYSTEM]: Arrived at Fishman Island. Setting Spawn...")
                        PathfindTo(GlobalConfig.Pos.FishmanSpawnSet) -- 7976.2, -2152.8, -17075.1
                        task.wait(1)
                        if rs_events:FindFirstChild("SetSpawn") then
                            rs_events:WaitForChild("SetSpawn"):FireServer()
                        elseif rs_events:FindFirstChild("SetSpawnPoint") then
                            rs_events:WaitForChild("SetSpawnPoint"):FireServer()
                        end
                        task.wait(1)
                        print("[SYSTEM]: Spawn Set.")
                    end
                end
            end

            -- Цикл Квестов и Убийств
            while GetLevel() < GlobalConfig.TargetLevel do
                if GetLevel() >= 190 then
                    getgenv().StopShootingForQuest = true
                    task.wait(0.5)
                    PathfindTo(GlobalConfig.Pos.BeckyQuest)
                    task.wait(0.5)
                    quest_remote:InvokeServer("takequest", "Help becky")
                    getgenv().FishmanKills = 0
                    task.wait(1)
                    PathfindTo(GlobalConfig.Pos.FishmanFarm)
                    getgenv().StopShootingForQuest = false
                    StartShooting() -- Запуск стрельбы
                    
                    while getgenv().FishmanKills < 5 do
                         if GetLevel() >= GlobalConfig.TargetLevel then break end
                         task.wait(1)
                    end
                    task.wait(1)
                else
                    PathfindTo(GlobalConfig.Pos.FishmanFarm)
                    StartShooting()
                    task.wait(5)
                end
            end
        
        -- ПЕРЕХОД И РЫБАЛКА (ПОСЛЕ TARGET LEVEL)
        else
            print("[SYSTEM]: Level requirement met (" .. myLevel .. "). Starting Transition.")
            
            -- 1. Если мы на Fishman Island или только достигли уровня - летим к первой точке
            if root and IsPositionOnIsland(root.Position, "Fishman Island") then
                PathfindTo(GlobalConfig.Pos.TransitionPoint1)
                print("[SYSTEM]: Arrived at Transition Point. Waiting 5s.")
                task.wait(5)
            end
            
            -- 2. Летим к точке рыбалки
            print("[SYSTEM]: Moving to Fishing Spot.")
            PathfindTo(GlobalConfig.Pos.FishingSpot)
            
            -- 3. Ставим спавн
            print("[SYSTEM]: Setting Spawn at Fishing Spot.")
            if rs_events:FindFirstChild("SetSpawn") then
                rs_events.SetSpawn:FireServer()
            elseif rs_events:FindFirstChild("SetSpawnPoint") then
                rs_events.SetSpawnPoint:FireServer()
            end
            task.wait(1)
            
            -- 4. Запускаем мониторинг Мерчанта в фоне
            task.spawn(function()
                print("[SYSTEM]: Merchant Monitor Started")
                while true do
                    ProcessMerchant()
                    task.wait(10)
                end
            end)
            
            -- 5. Запускаем цикл Рыбалки (Основной поток блокируется здесь)
            FishingLoop()
            
            break -- Выход из главного цикла while (так как FishingLoop бесконечный)
        end
        task.wait(1)
    end
end)
