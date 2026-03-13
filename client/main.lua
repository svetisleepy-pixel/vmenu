local ESX = exports['es_extended']:getSharedObject()

local spawnedPlants = {}
local currentAction = false

local function debugPrint(...)
    if Config.Debug then
        print('[vmenu_cocaine]', ...)
    end
end

local function showGtaHelp(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function drawTextUi(text)
    DrawRect(0.5, 0.92, 0.36, 0.04, 0, 0, 0, 120)
    SetTextFont(4)
    SetTextScale(0.34, 0.34)
    SetTextColour(255, 255, 255, 220)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.5, 0.907)
end

local function showInteractionPrompt(text)
    if Config.InteractionUI == 'gta_help' then
        showGtaHelp(text)
        return
    end

    drawTextUi(text)
end

local function playScenario(scenario)
    local ped = PlayerPedId()
    TaskStartScenarioInPlace(ped, scenario, 0, true)
end

local function playAnimation(dict, anim, duration)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end

    TaskPlayAnim(PlayerPedId(), dict, anim, 8.0, -8.0, duration, 49, 0.0, false, false, false)
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


local function resolvePlantGroundZ(coords)
    local ok, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 200.0, false)
    if ok then
        return groundZ
    end

    return coords.z
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

            local spawnZ = resolvePlantGroundZ(plant.coords)
            local obj = CreateObject(Config.PlantModel, plant.coords.x, plant.coords.y, spawnZ, false, false, false)
            SetEntityAsMissionEntity(obj, true, true)
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

    FreezeEntityPosition(ped, true)
    playAnimation(Config.SniffAnimDict, Config.SniffAnimName, Config.SniffDuration)

    local finished = runProgressBar('Sniffing cocaine...', Config.SniffDuration)
    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)

    if not finished then
        return
    end

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
                showInteractionPrompt('[E] Pick cocaine plant')

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
                showInteractionPrompt('[E] Process 1 cocaine leaf')

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


CreateThread(function()
    while true do
        Wait(15000)
        TriggerServerEvent('vmenu_cocaine:server:requestPlants')
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
