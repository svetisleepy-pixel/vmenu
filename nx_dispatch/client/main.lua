local dispatchFeed = {}

RegisterNetEvent('nx_dispatch:client:newCall', function(call)
    dispatchFeed[#dispatchFeed + 1] = call
    if #dispatchFeed > 8 then
        table.remove(dispatchFeed, 1)
    end

    SendNUIMessage({ action = 'dispatch:update', calls = dispatchFeed })
    TriggerEvent('nx_ui:client:notify', {
        type = 'info',
        title = call.code,
        message = call.title,
        duration = 3500
    })
end)

RegisterCommand('911', function(_, args)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    TriggerServerEvent('nx_dispatch:server:newCall', {
        code = '10-78',
        title = 'Citizen Emergency',
        description = table.concat(args, ' '),
        coords = { x = coords.x, y = coords.y, z = coords.z }
    })
end)
