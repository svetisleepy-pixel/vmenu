NX = NX or {}
NX.Lib = NX.Lib or {}

local pendingCallbacks = {}
local callbackId = 0

local function nextCallbackId()
    callbackId += 1
    return callbackId
end

function NX.Lib.Notify(notificationType, title, message, duration)
    TriggerEvent('nx_ui:client:notify', {
        type = notificationType or 'info',
        title = title or 'NX',
        message = message or '',
        duration = duration or 3500
    })
end

function NX.Lib.Progress(data, done)
    local payload = {
        id = data.id or ('progress_' .. GetGameTimer()),
        label = data.label or 'Processing',
        duration = data.duration or 5000,
        canCancel = data.canCancel ~= false
    }

    local finished = false
    TriggerEvent('nx_ui:client:progress', payload)

    CreateThread(function()
        local start = GetGameTimer()
        while not finished do
            Wait(0)
            if payload.canCancel and IsControlJustPressed(0, 202) then
                finished = true
                if done then done(false) end
                return
            end

            if (GetGameTimer() - start) >= payload.duration then
                finished = true
                if done then done(true) end
            end
        end
    end)
end

function NX.Lib.TriggerCallback(name, payload, cb)
    local id = nextCallbackId()
    pendingCallbacks[id] = cb
    TriggerServerEvent('nx_lib:server:triggerCallback', name, id, payload)
end

RegisterNetEvent('nx_lib:client:callback', function(id, result)
    if pendingCallbacks[id] then
        pendingCallbacks[id](result)
        pendingCallbacks[id] = nil
    end
end)

exports('Notify', NX.Lib.Notify)
exports('Progress', NX.Lib.Progress)
exports('TriggerCallback', NX.Lib.TriggerCallback)
