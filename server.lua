local activeEvents = {}

local function randomFrom(tbl)
    return tbl[math.random(1, #tbl)]
end

local function toVector3(pos)
    return vector3(pos.x + 0.0, pos.y + 0.0, pos.z + 0.0)
end

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)

    if not IsModelInCdimage(hash) then
        return nil
    end

    RequestModel(hash)
    local timeout = GetGameTimer() + 8000

    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(25)
    end

    if not HasModelLoaded(hash) then
        return nil
    end

    return hash
end

local function applyVehicleDamage(vehicle, scenarioType)
    if not DoesEntityExist(vehicle) then
        return
    end

    SetVehicleEngineOn(vehicle, false, true, true)
    SetVehicleUndriveable(vehicle, true)

    SetVehicleEngineHealth(vehicle, math.random(-1500, -350))
    SetVehicleBodyHealth(vehicle, math.random(180, 680))
    SetVehiclePetrolTankHealth(vehicle, math.random(150, 700))

    for i = 0, 7 do
        if math.random() < 0.75 then
            SmashVehicleWindow(vehicle, i)
        end
    end

    for i = 0, 7 do
        if math.random() < 0.5 then
            SetVehicleDoorBroken(vehicle, i, true)
        end
    end

    for i = 0, 5 do
        if math.random() < 0.6 then
            SetVehicleTyreBurst(vehicle, i, true, 1000.0)
        end
    end

    if math.random() < 0.4 then
        local rot = GetEntityRotation(vehicle, 2)
        SetEntityRotation(vehicle, rot.x + math.random(130, 190), rot.y + math.random(-15, 15), rot.z + math.random(-35, 35), 2, true)
    elseif scenarioType == 'wall_hit' then
        SetVehicleDamage(vehicle, 0.0, 2.2, 0.3, 140.0, 40.0, true)
    end

    SetVehicleOnGroundProperly(vehicle)
end

local function spawnPedForVehicle(bucket, basePos, index)
    local pedModel = loadModel(randomFrom(Config.PedModels))
    if not pedModel then
        return
    end

    local pedOffset = vector3(math.random(-5, 5) + (index * 0.25), math.random(-5, 5), 0.0)
    local pedPos = vector3(basePos.x + pedOffset.x, basePos.y + pedOffset.y, basePos.z)

    local _, groundZ = GetGroundZFor_3dCoord(pedPos.x, pedPos.y, pedPos.z + 20.0, false)
    pedPos = vector3(pedPos.x, pedPos.y, groundZ or pedPos.z)

    local ped = CreatePed(4, pedModel, pedPos.x, pedPos.y, pedPos.z, math.random(0, 359) + 0.0, true, true)
    if not DoesEntityExist(ped) then
        SetModelAsNoLongerNeeded(pedModel)
        return
    end

    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, true)
    SetPedCanPlayAmbientAnims(ped, true)
    SetEntityInvincible(ped, false)

    if math.random() < 0.35 then
        SetPedToRagdoll(ped, 8000, 8000, 0, true, true, false)
    else
        TaskStartScenarioInPlace(ped, randomFrom(Config.PedScenarios), 0, true)
    end

    bucket.peds[#bucket.peds + 1] = ped
    SetModelAsNoLongerNeeded(pedModel)
end

local function spawnVehicle(bucket, basePos, heading, scenarioType, vehicleIdx)
    local model = loadModel(randomFrom(Config.VehicleModels))
    if not model then
        return nil
    end

    local lateral = (vehicleIdx % 2 == 0 and 1 or -1) * math.random(1, 4)
    local forward = math.random(-4, 14) + (vehicleIdx * 3)

    if scenarioType == 'ped_hit' then
        forward = math.random(-2, 8)
        lateral = math.random(-2, 2)
    elseif scenarioType == 'wall_hit' then
        lateral = math.random(3, 8)
    end

    local spawnPos = GetOffsetFromCoordAndHeadingInWorldCoords(basePos.x, basePos.y, basePos.z, heading, lateral + 0.0, forward + 0.0, 0.0)
    local _, groundZ = GetGroundZFor_3dCoord(spawnPos.x, spawnPos.y, spawnPos.z + 25.0, false)
    spawnPos = vector3(spawnPos.x, spawnPos.y, groundZ or spawnPos.z)

    local vehicle = CreateVehicle(model, spawnPos.x, spawnPos.y, spawnPos.z, heading + math.random(-55, 55), true, true)
    if not DoesEntityExist(vehicle) then
        SetModelAsNoLongerNeeded(model)
        return nil
    end

    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, false)
    SetVehicleDoorsLocked(vehicle, 2)

    applyVehicleDamage(vehicle, scenarioType)

    bucket.vehicles[#bucket.vehicles + 1] = vehicle

    local pedCount = math.random(Config.MinPedsPerVehicle, Config.MaxPedsPerVehicle)
    for i = 1, pedCount do
        spawnPedForVehicle(bucket, spawnPos, i)
    end

    SetModelAsNoLongerNeeded(model)
    return vehicle
end

local function cleanupEvent(eventId)
    local bucket = activeEvents[eventId]
    if not bucket then
        return
    end

    for _, ped in ipairs(bucket.peds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end

    for _, vehicle in ipairs(bucket.vehicles) do
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end

    activeEvents[eventId] = nil
end

local function createAccident(coords, heading)
    local scenarioType = randomFrom(Config.Scenarios)
    local vehicleCount = math.random(Config.MinVehicles, Config.MaxVehicles)

    if scenarioType == 'ped_hit' then
        vehicleCount = 1
    elseif scenarioType == 'wall_hit' then
        vehicleCount = math.min(vehicleCount, 3)
    end

    local eventId = ('evt_%s_%s'):format(GetGameTimer(), math.random(1000, 9999))
    local bucket = { vehicles = {}, peds = {} }
    activeEvents[eventId] = bucket

    local basePos = toVector3(coords)

    for i = 1, vehicleCount do
        spawnVehicle(bucket, basePos, heading, scenarioType, i)
    end

    SetTimeout((Config.CleanupMinutes * 60) * 1000, function()
        cleanupEvent(eventId)
    end)

    return eventId
end

RegisterNetEvent('vmenu:revent:trigger', function(data)
    local src = source
    if type(data) ~= 'table' then
        return
    end

    local coords = vector3((data.x or 0.0) + 0.0, (data.y or 0.0) + 0.0, (data.z or 0.0) + 0.0)
    local heading = (data.heading or 0.0) + 0.0

    createAccident(coords, heading)

    TriggerClientEvent('vmenu:revent:dispatch', -1, {
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z
        }
    })

    print(('[vmenu_revent] Accident created by %s at %.2f %.2f %.2f'):format(src, coords.x, coords.y, coords.z))
end)
