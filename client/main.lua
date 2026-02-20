local panelOpen = false
local lastPayload = nil

local function setNui(show)
    panelOpen = show
    SetNuiFocus(show, show)
    SendNUIMessage({
        type = 'visibility',
        visible = show,
        payload = lastPayload
    })
end

RegisterNetEvent('vmenu_admin:client:openPanel', function(payload)
    lastPayload = payload
    setNui(true)
end)

RegisterNetEvent('vmenu_admin:client:updateData', function(payload)
    lastPayload = payload
    SendNUIMessage({
        type = 'sync',
        payload = payload
    })
end)

RegisterNetEvent('vmenu_admin:client:pushLog', function(entry)
    SendNUIMessage({
        type = 'logPush',
        entry = entry
    })
end)

RegisterNUICallback('close', function(_, cb)
    setNui(false)
    cb({ ok = true })
end)

RegisterNUICallback('action', function(data, cb)
    TriggerServerEvent('vmenu_admin:server:panelAction', data)
    cb({ ok = true })
end)

RegisterNetEvent('vmenu_admin:client:teleportTo', function(coords)
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
end)

RegisterNetEvent('vmenu_admin:client:setFrozen', function(state)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, state)
end)

RegisterNetEvent('vmenu_admin:client:revive', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, 200)
    ClearPedBloodDamage(ped)
end)

RegisterNetEvent('vmenu_admin:client:heal', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, 200)
end)

RegisterNetEvent('vmenu_admin:client:slay', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, 0)
end)

RegisterNetEvent('vmenu_admin:client:serviceStatus', function(service)
    if service then
        SendNUIMessage({
            type = 'service',
            payload = service
        })
    end
end)

CreateThread(function()
    while true do
        Wait(1000 * Config.ServiceTickSeconds)
        TriggerServerEvent('vmenu_admin:server:panelAction', { action = 'serviceTick' })
        TriggerServerEvent('vmenu_admin:server:requestTick')
    end
end)

RegisterCommand('report', function(_, args)
    local msg = table.concat(args, ' ')
    if msg == '' then
        TriggerEvent('chat:addMessage', { args = { '^1Usage', '/report [message]' } })
        return
    end
    TriggerServerEvent('vmenu_admin:server:panelAction', {
        action = 'createReport',
        category = 'Player report',
        message = msg
    })
end, false)
