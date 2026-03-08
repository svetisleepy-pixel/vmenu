local stores = {
    {
        id = 'grove_24_7',
        label = 'Rob Register',
        model = 'prop_till_01',
        dispatchCode = '10-31'
    }
}

local function sendDispatch(storeId)
    local coords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('nx_dispatch:server:newCall', {
        code = '10-31',
        title = 'Store Robbery',
        description = ('Active robbery in progress (%s)'):format(storeId),
        coords = { x = coords.x, y = coords.y, z = coords.z }
    })
end

CreateThread(function()
    Wait(1000)
    local targetOptions = {}

    for _, store in ipairs(stores) do
        targetOptions[#targetOptions + 1] = {
            label = store.label,
            icon = 'fa-solid fa-mask-face',
            event = 'nx_shop_robbery:client:tryStart'
        }
    end

    exports.nx_target:AddTargetModel({ 'prop_till_01' }, { options = targetOptions })
end)

RegisterNetEvent('nx_shop_robbery:client:tryStart', function(entity)
    local storeId = ('store_%s'):format(NetworkGetNetworkIdFromEntity(entity))
    TriggerServerEvent('nx_shop_robbery:server:attempt', storeId)
end)

RegisterNetEvent('nx_shop_robbery:client:startMinigame', function(storeId)
    sendDispatch(storeId)

    exports.nx_lib:Progress({
        label = 'Bypassing security lock...',
        duration = 9000,
        canCancel = true
    }, function(success)
        if not success then
            TriggerServerEvent('nx_shop_robbery:server:reward', false)
            return
        end

        local win = math.random() > 0.35
        TriggerServerEvent('nx_shop_robbery:server:reward', win)
    end)
end)
