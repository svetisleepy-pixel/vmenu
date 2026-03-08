local playerInventories = {}

local function ensureInventory(src)
    if not playerInventories[src] then
        playerInventories[src] = {
            { name = 'bandage', label = 'Bandage', count = 3 },
            { name = 'water', label = 'Water Bottle', count = 5 },
            { name = 'lockpick', label = 'Lockpick', count = 2 }
        }
    end

    return playerInventories[src]
end

NX.RegisterServerCallback('nx_inventory:getItems', function(src, _, cb)
    cb(ensureInventory(src))
end)

RegisterNetEvent('nx_inventory:server:useItem', function(itemName)
    local src = source
    local items = ensureInventory(src)

    for _, item in ipairs(items) do
        if item.name == itemName and item.count > 0 then
            item.count -= 1
            TriggerClientEvent('nx_ui:client:notify', src, {
                type = 'success',
                title = 'Inventory',
                message = ('Used %s'):format(item.label),
                duration = 2800
            })
            TriggerClientEvent('nx_inventory:client:refresh', src, items)
            break
        end
    end
end)

AddEventHandler('playerDropped', function()
    playerInventories[source] = nil
end)
