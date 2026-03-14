local ESX = exports['es_extended']:getSharedObject()

local spawnedPlants = {}
local currentAction = false
local promptVisible = false
local currentPromptText = nil
local plantModelLoaded = false
local processInputLocked = false

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

local function showEsxTextUi(text)
    local ok = pcall(function()
        exports['esx_textui']:TextUI(text)
    end)

    if ok then
        promptVisible = true
        currentPromptText = text
        return true
    end

    return false
end

local function hideEsxTextUi()
    if not promptVisible then
        return
    end

    pcall(function()
        exports['esx_textui']:HideUI()
    end)

    promptVisible = false
    currentPromptText = nil
end

local function showInteractionPrompt(text)
    if Config.InteractionUI == 'esx_textui' then
        if (not promptVisible) or currentPromptText ~= text then
            hideEsxTextUi()
            if not showEsxTextUi(text) then
                showGtaHelp(text)
            end
        end
        return
    end

    showGtaHelp(text)
end

local function hideInteractionPrompt()
    if Config.InteractionUI == 'esx_textui' then
        hideEsxTextUi()
    end
end

local function playScenario(scenario)
    TaskStartScenarioInPlace(PlayerPedId(), scenario, 0, true)
end

local function playAnimation(dict, name, duration)
    if not dict or not name then
        return false
    end

    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000

    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do
        Wait(0)
    end

    if not HasAnimDictLoaded(dict) then
        return false
    end

    TaskPlayAnim(PlayerPedId(), dict, name, 8.0, -8.0, duration, 1, 0.0, false, false, false)
    return true
end

local function clearActionState()
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
    currentAction = false
    hideInteractionPrompt()
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

local function ensurePlantModelLoaded()
    if plantModelLoaded then
        return true
    end

    RequestModel(Config.PlantModel)
    local timeout = GetGameTimer() + 5000

    while not HasModelLoaded(Config.PlantModel) and GetGameTimer() < timeout do
        Wait(0)
    end

    plantModelLoaded = HasModelLoaded(Config.PlantModel)
    return plantModelLoaded
end

local function resolvePlantGroundZ(coords)
    local testHeights = { 1000.0, 500.0, 250.0, 120.0, 60.0 }

    for i = 1, #testHeights do
        local sampleZ = coords.z + testHeights[i]

        RequestCollisionAtCoord(coords.x, coords.y, sampleZ)
        local tries = 0
        while not HasCollisionLoadedAroundEntity(PlayerPedId()) and tries < 20 do
            Wait(0)
            tries = tries + 1
        end

        local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, sampleZ, false)
        if found then
            return groundZ
        end
    end

    return coords.z
end


local function snapPlantEntityToGround(plant)
    if not plant or not DoesEntityExist(plant.entity) then
        return
    end

    local entityCoords = GetEntityCoords(plant.entity)
    local groundZ = resolvePlantGroundZ(vector3(entityCoords.x, entityCoords.y, entityCoords.z))

    SetEntityCoordsNoOffset(plant.entity, entityCoords.x, entityCoords.y, groundZ, false, false, false)
    PlaceObjectOnGroundProperly(plant.entity)
    FreezeEntityPosition(plant.entity, true)

    local finalCoords = GetEntityCoords(plant.entity)
    plant.coords = vector3(finalCoords.x, finalCoords.y, finalCoords.z)
end

local function syncPlantEntities(plantData)
    local active = {}

    for _, plant in ipairs(plantData) do
        active[plant.id] = true

        if not spawnedPlants[plant.id] then
            if not ensurePlantModelLoaded() then
                debugPrint('Failed to load plant model:', Config.PlantModel)
                break
            end

            local spawnZ = resolvePlantGroundZ(plant.coords)
            local obj = CreateObjectNoOffset(Config.PlantModel, plant.coords.x, plant.coords.y, spawnZ, false, false, false)

            SetEntityAsMissionEntity(obj, true, true)
            SetEntityCollision(obj, true, true)
            PlaceObjectOnGroundProperly(obj)
            FreezeEntityPosition(obj, true)

            local tmpPlant = { entity = obj }
            snapPlantEntityToGround(tmpPlant)

            local objCoords = GetEntityCoords(obj)
            spawnedPlants[plant.id] = {
                entity = obj,
                coords = vector3(objCoords.x, objCoords.y, objCoords.z)
            }
        else
            local ent = spawnedPlants[plant.id].entity
            if DoesEntityExist(ent) then
                snapPlantEntityToGround(spawnedPlants[plant.id])
            end
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
    playScenario(Config.SniffScenario)

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
                    local objCoords = GetEntityCoords(plant.entity)
                    plant.coords = vector3(objCoords.x, objCoords.y, objCoords.z)

                    local distance = #(playerCoords - plant.coords)
                    if distance < closestPlantDistance then
                        closestPlantDistance = distance
                        closestPlantId = id
                    end
                end
            end

            local nearPlant = closestPlantId and closestPlantDistance <= Config.HarvestInteractDistance
            local nearProcess = #(playerCoords - Config.ProcessLocation) <= Config.ProcessInteractDistance

            if nearPlant then
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
            elseif nearProcess then
                waitTime = 0
                showInteractionPrompt('[E] Process 1 cocaine leaf')

                if IsControlJustReleased(0, 38) and not processInputLocked then
                    processInputLocked = true
                    currentAction = true

                    SetTimeout(5000, function()
                        if currentAction and processInputLocked then
                            currentAction = false
                            processInputLocked = false
                            hideInteractionPrompt()
                        end
                    end)

                    ESX.TriggerServerCallback('vmenu_cocaine:server:canProcess', function(canProcess)
                        if not canProcess then
                            ESX.ShowNotification('You have no cocaine leaves to process.')
                            currentAction = false
                            hideInteractionPrompt()

                            SetTimeout(Config.ProcessInputCooldown, function()
                                processInputLocked = false
                            end)
                            return
                        end

                        FreezeEntityPosition(ped, true)

                        local animPlayed = playAnimation(Config.ProcessAnimDict, Config.ProcessAnimName, Config.ProcessDuration)
                        if not animPlayed then
                            playScenario('WORLD_HUMAN_STAND_IMPATIENT')
                        end

                        local finished = runProgressBar('Processing cocaine leaves...', Config.ProcessDuration)
                        clearActionState()
                        processInputLocked = false

                        if finished then
                            TriggerServerEvent('vmenu_cocaine:server:processLeaves')
                        end
                    end)
                end
            else
                hideInteractionPrompt()
            end
        else
            hideInteractionPrompt()
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



CreateThread(function()
    while true do
        Wait(2000)

        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)

        for _, plant in pairs(spawnedPlants) do
            if DoesEntityExist(plant.entity) then
                local entityCoords = GetEntityCoords(plant.entity)
                if #(playerCoords - entityCoords) <= 150.0 then
                    snapPlantEntityToGround(plant)
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    hideInteractionPrompt()

    for _, plant in pairs(spawnedPlants) do
        if DoesEntityExist(plant.entity) then
            DeleteEntity(plant.entity)
        end
    end
end)
