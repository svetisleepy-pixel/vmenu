local function forward(event, action)
    RegisterNetEvent(event, function(payload)
        SendNUIMessage({
            action = action,
            payload = payload
        })
    end)
end

forward('nx_ui:client:notify', 'notify:push')
forward('nx_ui:client:progress', 'progress:start')

RegisterNUICallback('ui:ready', function(_, cb)
    cb(true)
end)
