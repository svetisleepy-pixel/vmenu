local function getRoadSpawn(origin)
    local found, outPos, outHeading = GetClosestVehicleNodeWithHeading(origin.x, origin.y, origin.z, 1, 3.0, 0)
    if found then
        return vector3(outPos.x, outPos.y, outPos.z), outHeading
    end

    local foundSimple, simplePos = GetClosestVehicleNode(origin.x, origin.y, origin.z, 1, 3.0, 0)
    if foundSimple then
        return vector3(simplePos.x, simplePos.y, simplePos.z), GetEntityHeading(PlayerPedId())
    end

    return origin, GetEntityHeading(PlayerPedId())
end

RegisterCommand(Config.Command, function()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local spawnPos, heading = getRoadSpawn(pos)

    TriggerServerEvent('vmenu:revent:trigger', {
        x = spawnPos.x,
        y = spawnPos.y,
        z = spawnPos.z,
        heading = heading
    })
end, false)

RegisterNetEvent('vmenu:revent:dispatch', function(data)
    if GetResourceState('ps-dispatch') ~= 'started' then
        return
    end

    local ok, err = pcall(function()
        exports['ps-dispatch']:CustomAlert({
            coords = data.coords,
            message = 'Nesreča na cesti',
            dispatchCode = '10-50',
            description = 'Random prometna nesreča',
            radius = 0,
            sprite = 488,
            color = 1,
            scale = 1.2,
            length = 2,
            sound = 'Lose_1st',
            jobs = { 'police' }
        })
    end)

    if not ok then
        print(('[vmenu_revent] Dispatch failed: %s'):format(err))
    end
end)
