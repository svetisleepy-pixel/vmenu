local plants = {}
local busy = false
local effectActive = false
local effectThread = nil

local function showHelp(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function notify(text)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandThefeedPostTicker(false, false)
end

local function itemFeed(text)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandThefeedPostTicker(false, true)
end

local function loadModel(model)
    if not HasModelLoaded(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(0)
        end
    end
end

local function loadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(0)
        end
    end
end

local function tryGroundZ(coords)
    local found, z = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 50.0, false)
    if found then
        return vec3(coords.x, coords.y, z)
    end
    return coords
end

local function createPlantEntity(plantId, coords)
    local model = Config.GatherZone.model
    loadModel(model)

    local pos = tryGroundZ(coords)
    local obj = CreateObject(model, pos.x, pos.y, pos.z, false, false, false)
    SetEntityAsMissionEntity(obj, true, true)
    FreezeEntityPosition(obj, true)
    PlaceObjectOnGroundProperly(obj)

    plants[plantId] = {
        id = plantId,
        coords = GetEntityCoords(obj),
        entity = obj
    }
end

local function removePlantEntity(plantId)
    local plant = plants[plantId]
    if not plant then return end

    if plant.entity and DoesEntityExist(plant.entity) then
        DeleteObject(plant.entity)
    end

    plants[plantId] = nil
end

local function clearAllPlants()
    for plantId in pairs(plants) do
        removePlantEntity(plantId)
    end
end

local function runAction(durationMs, scenario)
    local ped = PlayerPedId()
    local startCoords = GetEntityCoords(ped)

    ClearPedTasks(ped)
    TaskStartScenarioInPlace(ped, scenario, 0, true)

    local start = GetGameTimer()
    while (GetGameTimer() - start) < durationMs do
        Wait(0)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 22, true)
        DisableControlAction(0, 23, true)
        DisableControlAction(0, 44, true)
        DisableControlAction(0, 140, true)
        DisableControlAction(0, 141, true)

        if IsEntityDead(ped) then
            ClearPedTasksImmediately(ped)
            return false, 'dead'
        end

        if IsControlJustPressed(0, Config.CancelKey) then
            ClearPedTasksImmediately(ped)
            return false, 'cancel'
        end

        local moved = #(GetEntityCoords(ped) - startCoords)
        if moved > 2.2 then
            ClearPedTasksImmediately(ped)
            return false, 'moved'
        end
    end

    ClearPedTasksImmediately(ped)
    return true
end

local function applyDrugEffect()
    if effectActive then
        notify('~y~Drug effect is already active.')
        return
    end

    effectActive = true

    local ped = PlayerPedId()
    loadAnimDict(Config.DrugUse.animation.dict)
    TaskPlayAnim(
        ped,
        Config.DrugUse.animation.dict,
        Config.DrugUse.animation.clip,
        8.0,
        -8.0,
        Config.DrugUse.animation.durationMs,
        49,
        0.0,
        false,
        false,
        false
    )

    Wait(Config.DrugUse.animation.durationMs)
    SetPedArmour(ped, Config.DrugUse.armour)
    SetRunSprintMultiplierForPlayer(PlayerId(), Config.DrugUse.speedMultiplier)
    notify('~g~' .. Config.Notifications.drugStart)

    local duration = math.random(Config.DrugUse.durationMs.min, Config.DrugUse.durationMs.max)
    effectThread = CreateThread(function()
        local finishAt = GetGameTimer() + duration
        while effectActive and GetGameTimer() < finishAt do
            Wait(250)
            if IsEntityDead(PlayerPedId()) then
                break
            end
        end

        effectActive = false
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        notify('~b~' .. Config.Notifications.drugEnd)
    end)
end

RegisterNetEvent('vmenu_drugs:client:syncPlants', function(serverPlants)
    clearAllPlants()

    for plantId, data in pairs(serverPlants) do
        createPlantEntity(plantId, vec3(data.x, data.y, data.z))
    end
end)

RegisterNetEvent('vmenu_drugs:client:addPlant', function(plantId, coords)
    if plants[plantId] then
        removePlantEntity(plantId)
    end

    createPlantEntity(plantId, vec3(coords.x, coords.y, coords.z))
end)

RegisterNetEvent('vmenu_drugs:client:removePlant', function(plantId)
    removePlantEntity(plantId)
end)

RegisterNetEvent('vmenu_drugs:client:itemDelta', function(label, amount)
    if amount == 0 then return end
    local sign = amount > 0 and '+' or '-'
    itemFeed(string.format('~g~%s%dx ~w~%s', sign, math.abs(amount), label))
end)

RegisterNetEvent('vmenu_drugs:client:notify', function(message, nType)
    local prefix = '~w~'
    if nType == 'error' then
        prefix = '~r~'
    elseif nType == 'success' then
        prefix = '~g~'
    elseif nType == 'info' then
        prefix = '~b~'
    end
    notify(prefix .. message)
end)

CreateThread(function()
    Wait(1000)
    TriggerServerEvent('vmenu_drugs:server:requestPlants')
end)

CreateThread(function()
    while true do
        local waitMs = 1000

        if not busy then
            local ped = PlayerPedId()
            local playerCoords = GetEntityCoords(ped)

            for plantId, plant in pairs(plants) do
                if plant.entity and DoesEntityExist(plant.entity) then
                    local dist = #(playerCoords - plant.coords)
                    if dist <= 15.0 then
                        waitMs = 0
                    end

                    if dist <= Config.GatherZone.interactDistance then
                        showHelp(Config.HelpTexts.harvest)
                        if IsControlJustPressed(0, 38) then
                            busy = true
                            local ok, reason = runAction(Config.GatherZone.durationMs, 'WORLD_HUMAN_GARDENER_PLANT')
                            if ok then
                                TriggerServerEvent('vmenu_drugs:server:harvestPlant', plantId)
                            else
                                if reason == 'cancel' or reason == 'moved' then
                                    notify('~y~' .. Config.Notifications.cancelled)
                                end
                            end
                            busy = false
                        end
                        break
                    end
                end
            end

            local processDist = #(playerCoords - Config.Process.coords)
            if processDist <= 20.0 then
                waitMs = 0
                DrawMarker(1, Config.Process.coords.x, Config.Process.coords.y, Config.Process.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.1, 1.1, 0.6, 55, 180, 75, 140, false, false, 2, false, nil, nil, false)
                if processDist <= Config.Process.interactDistance then
                    showHelp(Config.HelpTexts.process)
                    if IsControlJustPressed(0, 38) then
                        busy = true
                        notify('~b~' .. Config.Notifications.processStart)
                        local ok, reason = runAction(Config.Process.durationMs, 'PROP_HUMAN_BUM_BIN')
                        if ok then
                            TriggerServerEvent('vmenu_drugs:server:processLeaves')
                        else
                            if reason == 'cancel' or reason == 'moved' then
                                notify('~y~' .. Config.Notifications.cancelled)
                            end
                        end
                        busy = false
                    end
                end
            end
        end

        Wait(waitMs)
    end
end)

function useDrug(data, slot)
    if busy then
        return false
    end

    busy = true
    applyDrugEffect()
    busy = false
    return true
end

exports('useDrug', useDrug)


RegisterNetEvent('vmenu_drugs:useDrug', function(data, slot)
    useDrug(data, slot)
end)


AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    clearAllPlants()
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
end)
