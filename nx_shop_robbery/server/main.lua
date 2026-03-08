local robbedStores = {}
local STORE_COOLDOWN = 60 * 30

RegisterNetEvent('nx_shop_robbery:server:attempt', function(storeId)
    local src = source
    local now = os.time()

    if robbedStores[storeId] and robbedStores[storeId] > now then
        TriggerClientEvent('nx_ui:client:notify', src, {
            type = 'error',
            title = 'Robbery',
            message = 'This register was recently robbed.',
            duration = 3500
        })
        return
    end

    robbedStores[storeId] = now + STORE_COOLDOWN
    TriggerClientEvent('nx_shop_robbery:client:startMinigame', src, storeId)
end)

RegisterNetEvent('nx_shop_robbery:server:reward', function(success)
    local src = source
    if not success then
        TriggerClientEvent('nx_ui:client:notify', src, {
            type = 'error',
            title = 'Robbery Failed',
            message = 'You were unable to crack the register.',
            duration = 3000
        })
        return
    end

    local payout = math.random(350, 900)
    TriggerClientEvent('nx_hud:client:updateMoney', src, payout)
    TriggerClientEvent('nx_ui:client:notify', src, {
        type = 'success',
        title = 'Robbery Success',
        message = ('You stole $%s'):format(payout),
        duration = 3500
    })
end)
