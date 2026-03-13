local ESX = exports['es_extended']:getSharedObject()

local plants = {}
local nextPlantId = 1

local function randomInCircle(center, radius)
    local theta = math.random() * 2.0 * math.pi
    local r = radius * math.sqrt(math.random())

    local x = center.x + r * math.cos(theta)
    local y = center.y + r * math.sin(theta)
    local z = center.z

    return vec3(x, y, z)
end

local function serializePlants()
    local data = {}

    for _, plant in pairs(plants) do
        data[#data + 1] = {
            id = plant.id,
            coords = {
                x = plant.coords.x,
                y = plant.coords.y,
                z = plant.coords.z
            }
        }
    end

    return data
end

local function syncPlants(target)
    TriggerClientEvent('vmenu_cocaine:client:syncPlants', target or -1, serializePlants())
end

local function spawnPlant()
    if #plants >= Config.MaxPlants then
        return
    end

    local plant = {
        id = nextPlantId,
        coords = randomInCircle(Config.FieldCenter, Config.FieldRadius)
    }

    nextPlantId = nextPlantId + 1
    plants[#plants + 1] = plant
end

local function removePlantById(plantId)
    for i = 1, #plants do
        if plants[i].id == plantId then
            table.remove(plants, i)
            return true
        end
    end

    return false
end

local function getPlantById(plantId)
    for i = 1, #plants do
        if plants[i].id == plantId then
            return plants[i]
        end
    end

    return nil
end

CreateThread(function()
    math.randomseed(os.time())

    for _ = 1, Config.MaxPlants do
        spawnPlant()
    end

    syncPlants(-1)
end)

RegisterNetEvent('vmenu_cocaine:server:requestPlants', function()
    syncPlants(source)
end)

RegisterNetEvent('vmenu_cocaine:server:harvestPlant', function(plantId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        return
    end

    local plant = getPlantById(plantId)
    if not plant then
        return
    end

    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local plantCoords = vector3(plant.coords.x, plant.coords.y, plant.coords.z)

    if #(playerCoords - plantCoords) > Config.PlantValidationDistance then
        return
    end

    local reward = math.random(Config.LeafRewardMin, Config.LeafRewardMax)
    xPlayer.addInventoryItem('coke_leaf', reward)

    removePlantById(plantId)
    syncPlants(-1)

    SetTimeout(Config.PlantRespawnTime * 1000, function()
        spawnPlant()
        syncPlants(-1)
    end)
end)

ESX.RegisterServerCallback('vmenu_cocaine:server:canProcess', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb(false)
        return
    end

    local leaves = xPlayer.getInventoryItem('coke_leaf').count
    cb(leaves > 0)
end)

RegisterNetEvent('vmenu_cocaine:server:processLeaves', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        return
    end

    local leaves = xPlayer.getInventoryItem('coke_leaf').count
    if leaves <= 0 then
        return
    end

    xPlayer.removeInventoryItem('coke_leaf', 1)

    local cokeReward = math.random(Config.CokePerLeafMin, Config.CokePerLeafMax)
    xPlayer.addInventoryItem('coke', cokeReward)
end)

ESX.RegisterUsableItem('coke', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return
    end

    xPlayer.removeInventoryItem('coke', 1)
    TriggerClientEvent('vmenu_cocaine:client:useCoke', source)
end)
