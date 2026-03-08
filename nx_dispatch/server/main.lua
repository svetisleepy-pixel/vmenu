RegisterNetEvent('nx_dispatch:server:newCall', function(callData)
    local src = source
    local payload = {
        code = callData.code or '10-99',
        title = callData.title or 'Emergency Call',
        description = callData.description or 'No details supplied.',
        coords = callData.coords,
        source = src,
        time = os.time()
    }

    TriggerClientEvent('nx_dispatch:client:newCall', -1, payload)
end)
