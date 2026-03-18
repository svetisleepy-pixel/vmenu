math.randomseed(os.time())

local plants = {}
local nextPlantId = 1
local actionLocks = {}
local playerCooldowns = {}

local function debugPrint(...)
    if Config.Debug then
        print('[vmenu_drugs]', ...)
    end
end

local function notify(src, message, nType)
    TriggerClientEvent('vmenu_drugs:client:notify', src, message, nType)
end

local function itemDelta(src, label, amount)
    TriggerClientEvent('vmenu_drugs:client:itemDelta', src, label, amount)
end

local function currentTimeMs()
    return os.time() * 1000
end

local function isOnCooldown(src, key, ms)
    playerCooldowns[src] = playerCooldowns[src] or {}
    local now = currentTimeMs()
    local untilTs = playerCooldowns[src][key] or 0
    if now < untilTs then
        return true
    end
    playerCooldowns[src][key] = now + ms
    return false
end

local function countPlants()
    local c = 0
    for _ in pairs(plants) do
        c += 1
    end
    return c
end

local function isTooCloseToOtherPlants(pos)
    for _, plant in pairs(plants) do
        local dx = pos.x - plant.x
        local dy = pos.y - plant.y
        local dz = pos.z - plant.z
        local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
        if dist < Config.GatherZone.minDistanceBetweenPlants then
            return true
        end
    end

    return false
end

local function randomPointInZone()
    local radius = Config.GatherZone.radius * math.sqrt(math.random())
    local theta = math.random() * math.pi * 2.0

    return {
        x = Config.GatherZone.center.x + radius * math.cos(theta),
        y = Config.GatherZone.center.y + radius * math.sin(theta),
        z = Config.GatherZone.center.z
    }
end

local function createPlant()
    for _ = 1, 60 do
        local pos = randomPointInZone()
        if not isTooCloseToOtherPlants(pos) then
            local id = nextPlantId
            nextPlantId += 1

            plants[id] = {
                id = id,
                x = pos.x,
                y = pos.y,
                z = pos.z
            }
            return id, plants[id]
        end
    end

    return nil, nil
end

local function syncAllPlants(target)
    TriggerClientEvent('vmenu_drugs:client:syncPlants', target, plants)
end

local function topUpPlants()
    local max = Config.GatherZone.maxPlants
    local current = countPlants()
    if current >= max then
        return
    end

    local needed = max - current
    for _ = 1, needed do
        local id, plant = createPlant()
        if not id then
            debugPrint('Could not find non-overlapping spawn point.')
            break
        end

        TriggerClientEvent('vmenu_drugs:client:addPlant', -1, id, plant)
    end
end

local function scheduleRespawn()
    SetTimeout(Config.GatherZone.respawnDelayMs, function()
        topUpPlants()
    end)
end

local function getPlayerCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then
        return nil
    end

    local coords = GetEntityCoords(ped)
    return { x = coords.x, y = coords.y, z = coords.z }
end

local function distance(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

CreateThread(function()
    while GetResourceState('ox_inventory') ~= 'started' do
        Wait(500)
    end

    topUpPlants()
    debugPrint(('Initial plants: %d'):format(countPlants()))
end)

RegisterNetEvent('vmenu_drugs:server:requestPlants', function()
    local src = source
    syncAllPlants(src)
end)

RegisterNetEvent('vmenu_drugs:server:harvestPlant', function(plantId)
    local src = source
    plantId = tonumber(plantId)
    if not plantId then
        return
    end

    if isOnCooldown(src, 'harvest', 1200) then
        return
    end

    if actionLocks[src] then
        return
    end

    local plant = plants[plantId]
    if not plant then
        notify(src, Config.Notifications.harvestFailed, 'error')
        return
    end

    local playerCoords = getPlayerCoords(src)
    if not playerCoords then
        return
    end

    if distance(playerCoords, plant) > 4.0 then
        notify(src, Config.Notifications.harvestFailed, 'error')
        return
    end

    actionLocks[src] = true

    local amount = math.random(Config.GatherZone.rewardAmount.min, Config.GatherZone.rewardAmount.max)
    local canCarry = exports.ox_inventory:CanCarryItem(src, Config.GatherZone.rewardItem, amount)
    if not canCarry then
        notify(src, 'Not enough inventory space.', 'error')
        actionLocks[src] = nil
        return
    end

    plants[plantId] = nil
    TriggerClientEvent('vmenu_drugs:client:removePlant', -1, plantId)

    local added = exports.ox_inventory:AddItem(src, Config.GatherZone.rewardItem, amount)
    if not added then
        notify(src, Config.Notifications.harvestFailed, 'error')
        actionLocks[src] = nil
        return
    end

    notify(src, Config.Notifications.harvestSuccess, 'success')
    itemDelta(src, Config.ItemLabels.leaves, amount)

    actionLocks[src] = nil
    scheduleRespawn()
end)

RegisterNetEvent('vmenu_drugs:server:processLeaves', function()
    local src = source

    if isOnCooldown(src, 'process', 1200) then
        return
    end

    if actionLocks[src] then
        return
    end

    local playerCoords = getPlayerCoords(src)
    if not playerCoords then
        return
    end

    if distance(playerCoords, Config.Process.coords) > 4.0 then
        notify(src, Config.Notifications.processFailed, 'error')
        return
    end

    actionLocks[src] = true

    local haveLeaves = exports.ox_inventory:Search(src, 'count', Config.Process.inputItem) or 0
    if haveLeaves < Config.Process.inputAmount then
        notify(src, Config.Notifications.needLeaves, 'error')
        actionLocks[src] = nil
        return
    end

    local outputAmount = math.random(Config.Process.outputAmount.min, Config.Process.outputAmount.max)

    if not exports.ox_inventory:CanCarryItem(src, Config.Process.outputItem, outputAmount) then
        notify(src, 'Not enough inventory space.', 'error')
        actionLocks[src] = nil
        return
    end

    local removed = exports.ox_inventory:RemoveItem(src, Config.Process.inputItem, Config.Process.inputAmount)
    if not removed then
        notify(src, Config.Notifications.processFailed, 'error')
        actionLocks[src] = nil
        return
    end

    local added = exports.ox_inventory:AddItem(src, Config.Process.outputItem, outputAmount)
    if not added then
        exports.ox_inventory:AddItem(src, Config.Process.inputItem, Config.Process.inputAmount)
        notify(src, Config.Notifications.processFailed, 'error')
        actionLocks[src] = nil
        return
    end

    notify(src, Config.Notifications.processSuccess, 'success')
    itemDelta(src, Config.ItemLabels.leaves, -Config.Process.inputAmount)
    itemDelta(src, Config.ItemLabels.drug, outputAmount)

    actionLocks[src] = nil
end)

AddEventHandler('playerDropped', function()
    local src = source
    actionLocks[src] = nil
    playerCooldowns[src] = nil
end)
