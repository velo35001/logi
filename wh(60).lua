if getgenv().OnyxLoaded then return end
getgenv().OnyxLoaded = true

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
end
LocalPlayer.Character:WaitForChild("HumanoidRootPart", 60)
LocalPlayer.Character:WaitForChild("Humanoid", 60)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
ReplicatedStorage:WaitForChild("Events", 60)

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

getgenv().WebhookURL = "https://discord.com/api/webhooks/1461680245882093633/4_2q02-LJ4Lz3CG-Crfmp_1Jc0iU0gFQ-1mo8Ix-sNf32AWXPjOVnLhfChCEyItnoswO" 

local rs_events = ReplicatedStorage:WaitForChild("Events")
local playgame_remote = rs_events:FindFirstChild("playgame")
local quest_remote = rs_events:FindFirstChild("Quest")
local takestam_remote = rs_events:FindFirstChild("takestam")
local shop_remote = rs_events:FindFirstChild("Shop")
local tools_remote = rs_events:FindFirstChild("Tools")

-- // ФУНКЦИЯ СМЕНЫ СЕРВЕРА
local function HopServer()
    local sfUrl = "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100"
    local success, result = pcall(function()
        return game:HttpGet(string.format(sfUrl, game.PlaceId))
    end)
    
    if success and result then
        local decodeSuccess, servers = pcall(function()
            return HttpService:JSONDecode(result)
        end)
        
        if decodeSuccess and servers and servers.data then
            for _, s in pairs(servers.data) do
                if type(s) == "table" and s.playing and s.maxPlayers and s.id then
                    if s.playing < s.maxPlayers and s.id ~= game.JobId then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                        return
                    end
                end
            end
        end
    end
end

task.spawn(function()
    task.wait(18 * 60)
    HopServer()
end)

local function check_sea()
    if game.GameId == 648454481 and playgame_remote then
        playgame_remote:FireServer("Main Game")
    end
end

check_sea()

getgenv().pathfindToken = 0
getgenv().StopShootingForQuest = false 
getgenv().FishmanKills = 0

local settings = {
    Step = 1.0,
    FallSpeed = 2,
    HipHeight = 3.5,
    WallTPHeight = 100,
    WallCheckRange = 4.8,
    RiflePrice = 300,
}

local positions = {
    rifle_shop = Vector3.new(-532, 6, -3448),
    quest_npc = Vector3.new(-548, 6, -3403),
    becky_quest = Vector3.new(7735, -2176, -17223),
    fishman_farm = Vector3.new(7838.7, -2151.3, -17134.5)
}

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

-- // ВЕБХУК
local function SendWebhook()
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
                ["color"] = 0,
                ["image"] = {
                    ["url"] = "https://media.discordapp.net/attachments/1455503437000347713/1461359339272147037/image.png"
                }
            }}
        }
        httpRequest({
            Url = getgenv().WebhookURL,
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
task.spawn(SendWebhook)

local function GetChar()
    local Char = LocalPlayer.Character
    if Char then
        return Char, Char:FindFirstChild("HumanoidRootPart"), Char:FindFirstChild("Humanoid")
    end
    return nil, nil, nil
end

local function HasRifle()
    return LocalPlayer.Backpack:FindFirstChild("Rifle") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Rifle"))
end

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

-- // НОВАЯ ФУНКЦИЯ ПРОВЕРКИ ИГРОКОВ
local function CheckOtherPlayersOnIsland(islandName)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if IsPositionOnIsland(player.Character.HumanoidRootPart.Position, islandName) then
                return true
            end
        end
    end
    return false
end

local function FireDash()
    if takestam_remote then
        takestam_remote:FireServer(0.56, "dash")
    end
end

local function TweenMove(targetPos)
    local char, rootPart, _ = GetChar()
    if not rootPart then return end
    local myToken = getgenv().pathfindToken
    local lastWallTP = 0
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {char}
    rayParams.IgnoreWater = true
    while (rootPart.Position - targetPos).Magnitude > 4 and myToken == getgenv().pathfindToken do
        local currentPos = rootPart.Position
        local delta = targetPos - currentPos
        local dirXZ = Vector3.new(delta.X, 0, delta.Z).Unit
        local nextXZ = currentPos + dirXZ * settings.Step
        local wallResult = Workspace:Raycast(currentPos, dirXZ * settings.WallCheckRange, rayParams)
        if wallResult and wallResult.Instance.CanCollide and (tick() - lastWallTP > 0.3) then
            lastWallTP = tick()
            FireDash()
            local forwardPos = wallResult.Position + (dirXZ * 2)
            local topCheck = Workspace:Raycast(forwardPos + Vector3.new(0, settings.WallTPHeight, 0), Vector3.new(0, -settings.WallTPHeight * 2, 0), rayParams)
            local jumpY = topCheck and (topCheck.Position.Y + settings.HipHeight) or (currentPos.Y + 15)
            rootPart.CFrame = CFrame.new(forwardPos.X, jumpY, forwardPos.Z)
            task.wait(0.05)
        else
            local groundRay = Workspace:Raycast(nextXZ + Vector3.new(0, 15, 0), Vector3.new(0, -50, 0), rayParams)
            local finalY = groundRay and (groundRay.Position.Y + settings.HipHeight) or (currentPos.Y - settings.FallSpeed)
            if targetPos.Y > -1000 then
                finalY = math.max(finalY, 2)
            end
            rootPart.CFrame = CFrame.new(nextXZ.X, finalY, nextXZ.Z)
        end
        RunService.Heartbeat:Wait()
    end
end

local function PathfindTo(target)
    getgenv().pathfindToken = getgenv().pathfindToken + 1
    local targetPos = typeof(target) == "Vector3" and target or (typeof(target) == "CFrame" and target.Position or target.Position)
    TweenMove(targetPos)
end

local function do_chest_farm()
    local nearest_prompt = nil
    local min_dist = math.huge
    local _, root = GetChar()
    if not root then return false end
    if not Workspace:FindFirstChild("Env") then return false end
    for _, part in ipairs(Workspace.Env:GetChildren()) do
        if part:IsA("BasePart") and IsPositionOnIsland(part.Position, "Town of Beginnings") then
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
                    if getgenv().StopShootingForQuest then 
                        task.wait(0.5)
                        continue 
                    end
                    local targetNPC = GetLivingFishman()
                    if targetNPC then
                        while targetNPC and targetNPC.Parent and targetNPC:FindFirstChild("Humanoid") and targetNPC.Humanoid.Health > 0 do
                            if getgenv().StopShootingForQuest then break end
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

for _, v in next, getconnections(LocalPlayer.Idled) do v:Disable() end
if playgame_remote then playgame_remote:FireServer("Main Game") end

task.spawn(function()
    while task.wait(2) do
        local stats = GetStatsFolder()
        if stats and stats.Stats.SkillPoints.Value > 0 then
            ReplicatedStorage.Events.stats:FireServer("GunMastery", nil, 1)
        end
    end
end)

-- // ПОКУПКА ВИНТОВКИ
if not HasRifle() then
    while not HasRifle() do
        local currentPeli = GetPeli()
        if currentPeli >= settings.RiflePrice then
            PathfindTo(positions.rifle_shop)
            shop_remote:InvokeServer(Workspace.BuyableItems.Rifle, 1)
            task.wait(1)
            tools_remote:InvokeServer("equip", "Rifle")
            task.wait(1)
        else
            if not do_chest_farm() then
                HopServer() 
                task.wait(10)
            end
        end
        task.wait(0.5)
    end
end

-- // ПРОВЕРКА ИГРОКОВ ПЕРЕД ОТПРАВКОЙ НА ОСТРОВ
if CheckOtherPlayersOnIsland("Fishman Island") then
    warn("Игроки обнаружены. Меняю сервер...")
    HopServer()
    return
end

-- // ПЕРЕХОД НА FISHMAN ISLAND
local _, hrp = GetChar()
if not IsPositionOnIsland(hrp.Position, "Fishman Island") then
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
        end
    end
end

-- // ФАРМ С ПРОВЕРКОЙ ИГРОКОВ В ЦИКЛЕ
task.spawn(function()
    local done = false
    while task.wait(1) do
        -- Постоянная проверка на других игроков во время фарма
        if CheckOtherPlayersOnIsland("Fishman Island") then
            HopServer()
            break
        end

        local _, charRoot = GetChar()
        if charRoot and IsPositionOnIsland(charRoot.Position, "Fishman Island") and not done then
            done = true
            PathfindTo(Vector3.new(7976.2, -2152.8, -17075.1))
            task.wait(1)
            ReplicatedStorage:WaitForChild("Events"):WaitForChild("SetSpawn"):FireServer()
            task.wait(1)
            StartShooting()
            if GetLevel() < 190 then
                 PathfindTo(positions.fishman_farm)
            end
            break
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if GetLevel() >= 190 then
            getgenv().StopShootingForQuest = true
            task.wait(0.5)
            PathfindTo(positions.becky_quest)
            task.wait(0.5)
            local args = {{"takequest", "Help becky"}}
            quest_remote:InvokeServer(unpack(args))
            getgenv().FishmanKills = 0
            task.wait(1)
            PathfindTo(positions.fishman_farm)
            getgenv().StopShootingForQuest = false
            while getgenv().FishmanKills < 5 do
                task.wait(0.5)
                local _, _, hum = GetChar()
                if not hum or hum.Health <= 0 then
                    task.wait(2)
                end
            end
            task.wait(1)
        end
    end
end)
