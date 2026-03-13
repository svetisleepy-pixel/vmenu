local ESX = exports['es_extended']:getSharedObject()

local spawnedPlants = {}
local currentAction = false

local function debugPrint(...)
    if Config.Debug then
        print('[vmenu_cocaine]', ...)
    end
end

local function showHelpNotification(text)
    ESX.ShowHelpNotification(text, true)
end

local function playScenario(scenario)
    local ped = PlayerPedId()
    TaskStartScenarioInPlace(ped, scenario, 0, true)
end

local function clearActionState()
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
    currentAction = false
end

local function runProgressBar(label, duration)
    local completed = false

    local ok, result = pcall(function()
        return exports['esx_progressbar']:Progressbar(label, duration)
    end)

    if ok and result ~= nil then
        completed = result == true or result == 1
    elseif Config.UseProgressFallback then
        Wait(duration)
        completed = true
    end

    return completed
end

local function syncPlantEntities(plantData)
    local active = {}

    for _, plant in ipairs(plantData) do
        active[plant.id] = true

        if not spawnedPlants[plant.id] then
            RequestModel(Config.PlantModel)
            while not HasModelLoaded(Config.PlantModel) do
                Wait(0)
            end

            local obj = CreateObject(Config.PlantModel, plant.coords.x, plant.coords.y, plant.coords.z - 1.0, false, false, false)
            PlaceObjectOnGroundProperly(obj)
            FreezeEntityPosition(obj, true)

            spawnedPlants[plant.id] = {
                entity = obj,
                coords = vector3(plant.coords.x, plant.coords.y, plant.coords.z)
            }
        else
            spawnedPlants[plant.id].coords = vector3(plant.coords.x, plant.coords.y, plant.coords.z)
        end
    end

    for id, plant in pairs(spawnedPlants) do
        if not active[id] then
            if DoesEntityExist(plant.entity) then
                DeleteEntity(plant.entity)
            end

            spawnedPlants[id] = nil
        end
    end
end

RegisterNetEvent('vmenu_cocaine:client:syncPlants', function(plants)
    syncPlantEntities(plants)
end)

RegisterNetEvent('vmenu_cocaine:client:useCoke', function()
    local ped = PlayerPedId()
    SetPedArmour(ped, Config.CokeArmor)
    SetRunSprintMultiplierForPlayer(PlayerId(), Config.CokeSpeedMultiplier)

    StartScreenEffect(Config.CokeScreenEffect, 0, true)

    CreateThread(function()
        Wait(Config.CokeEffectDuration)
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        StopScreenEffect(Config.CokeScreenEffect)
    end)
end)

CreateThread(function()
    Wait(1000)
    TriggerServerEvent('vmenu_cocaine:server:requestPlants')

    while true do
        local waitTime = 1000

        if not currentAction then
            local ped = PlayerPedId()
            local playerCoords = GetEntityCoords(ped)

            local closestPlantId = nil
            local closestPlantDistance = 9999.0

            for id, plant in pairs(spawnedPlants) do
                if DoesEntityExist(plant.entity) then
                    local distance = #(playerCoords - plant.coords)
                    if distance < closestPlantDistance then
                        closestPlantDistance = distance
                        closestPlantId = id
                    end
                end
            end

            if closestPlantId and closestPlantDistance <= Config.HarvestInteractDistance then
                waitTime = 0
                showHelpNotification('Press ~INPUT_CONTEXT~ to pick cocaine plant')

                if IsControlJustReleased(0, 38) then
                    currentAction = true
                    FreezeEntityPosition(ped, true)
                    playScenario(Config.PickScenario)

                    local finished = runProgressBar('Picking cocaine plant...', Config.HarvestDuration)
                    clearActionState()

                    if finished then
                        TriggerServerEvent('vmenu_cocaine:server:harvestPlant', closestPlantId)
                    end
                end
            end

            local processDistance = #(playerCoords - Config.ProcessLocation)
            if processDistance <= Config.ProcessInteractDistance then
                waitTime = 0
                showHelpNotification('Press ~INPUT_CONTEXT~ to process cocaine leaves')

                if IsControlJustReleased(0, 38) then
                    ESX.TriggerServerCallback('vmenu_cocaine:server:canProcess', function(canProcess)
                        if not canProcess then
                            ESX.ShowNotification('You have no cocaine leaves to process.')
                            return
                        end

                        currentAction = true
                        FreezeEntityPosition(ped, true)
                        playScenario(Config.ProcessScenario)

                        local finished = runProgressBar('Processing cocaine leaves...', Config.ProcessDuration)
                        clearActionState()

                        if finished then
                            TriggerServerEvent('vmenu_cocaine:server:processLeaves')
                        end
                    end)
                end
            end
        end

        Wait(waitTime)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    for _, plant in pairs(spawnedPlants) do
        if DoesEntityExist(plant.entity) then
            DeleteEntity(plant.entity)
        end
    end
end)
