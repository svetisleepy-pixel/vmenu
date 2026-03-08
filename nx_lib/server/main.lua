NX = NX or {}
NX.ServerCallbacks = NX.ServerCallbacks or {}

function NX.RegisterServerCallback(name, cb)
    NX.ServerCallbacks[name] = cb
end

RegisterNetEvent('nx_lib:server:triggerCallback', function(name, requestId, payload)
    local src = source
    local callback = NX.ServerCallbacks[name]

    if not callback then
        TriggerClientEvent('nx_lib:client:callback', src, requestId, nil)
        return
    end

    callback(src, payload, function(result)
        TriggerClientEvent('nx_lib:client:callback', src, requestId, result)
    end)
end)

exports('RegisterServerCallback', NX.RegisterServerCallback)
