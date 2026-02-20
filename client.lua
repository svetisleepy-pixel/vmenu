local godModeVehicles = {}

local function notify(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, false)
end

local function getDriverVehicle()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        return nil
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        return nil
    end

    return vehicle
end

local function ensureVehicleOrNotify()
    local vehicle = getDriverVehicle()
    if not vehicle then
        notify(Config.Locale.noVehicle)
        return nil
    end

    return vehicle
end

RegisterNetEvent('vmenu_esx_vehicle_admin:client:boost', function()
    local vehicle = ensureVehicleOrNotify()
    if not vehicle then return end

    SetVehicleForwardSpeed(vehicle, GetEntitySpeed(vehicle) + Config.Boost.power)

    local endTime = GetGameTimer() + Config.Boost.durationMs
    CreateThread(function()
        while GetGameTimer() < endTime do
            if DoesEntityExist(vehicle) then
                SetVehicleCheatPowerIncrease(vehicle, 50.0)
            end
            Wait(0)
        end
        if DoesEntityExist(vehicle) then
            SetVehicleCheatPowerIncrease(vehicle, 1.0)
        end
    end)
end)

RegisterNetEvent('vmenu_esx_vehicle_admin:client:toggleGodMode', function()
    local vehicle = ensureVehicleOrNotify()
    if not vehicle then return end

    local netId = VehToNet(vehicle)
    local newState = not godModeVehicles[netId]
    godModeVehicles[netId] = newState

    SetEntityInvincible(vehicle, newState)
    SetVehicleCanBreak(vehicle, not newState)
    SetVehicleTyresCanBurst(vehicle, not newState)
    SetVehicleEngineCanDegrade(vehicle, not newState)
    SetVehiclePetrolTankHealth(vehicle, newState and 4000.0 or 1000.0)

    local status = newState and Config.Locale.toggledOn or Config.Locale.toggledOff
    notify(('Vehicle god mode: %s'):format(status))
end)

RegisterNetEvent('vmenu_esx_vehicle_admin:client:repair', function()
    local vehicle = ensureVehicleOrNotify()
    if not vehicle then return end

    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleUndriveable(vehicle, false)
    SetVehicleEngineOn(vehicle, true, true, false)
end)

RegisterNetEvent('vmenu_esx_vehicle_admin:client:clean', function()
    local vehicle = ensureVehicleOrNotify()
    if not vehicle then return end

    SetVehicleDirtLevel(vehicle, 0.0)
    WashDecalsFromVehicle(vehicle, 1.0)
end)

RegisterNetEvent('vmenu_esx_vehicle_admin:client:flip', function()
    local vehicle = ensureVehicleOrNotify()
    if not vehicle then return end

    local coords = GetEntityCoords(vehicle)
    SetEntityRotation(vehicle, 0.0, 0.0, GetEntityHeading(vehicle), 2, true)
    SetEntityCoordsNoOffset(vehicle, coords.x, coords.y, coords.z + 0.4, false, false, false)
end)

RegisterNetEvent('vmenu_esx_vehicle_admin:client:maxUpgrade', function()
    local vehicle = ensureVehicleOrNotify()
    if not vehicle then return end

    SetVehicleModKit(vehicle, 0)

    for modType = 0, 49 do
        local modCount = GetNumVehicleMods(vehicle, modType)
        if modCount > 0 then
            SetVehicleMod(vehicle, modType, modCount - 1, false)
        end
    end

    ToggleVehicleMod(vehicle, 18, true) -- Turbo
    ToggleVehicleMod(vehicle, 20, true) -- Tire smoke
    SetVehicleTyreSmokeColor(vehicle, 0, 0, 0)
    SetVehicleWindowTint(vehicle, 1)
end)
