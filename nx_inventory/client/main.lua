local isOpen = false
local cache = {}

local function setInventoryState(state)
    isOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({ action = 'inventory:visibility', visible = state })
end

local function openInventory()
    exports.nx_lib:TriggerCallback('nx_inventory:getItems', {}, function(items)
        cache = items or {}
        SendNUIMessage({ action = 'inventory:setItems', items = cache })
        setInventoryState(true)
    end)
end

RegisterCommand('inventory', function()
    if isOpen then
        setInventoryState(false)
        return
    end

    openInventory()
end)
RegisterKeyMapping('inventory', 'Open NX inventory', 'keyboard', 'TAB')

RegisterNUICallback('inventory:close', function(_, cb)
    setInventoryState(false)
    cb(true)
end)

RegisterNUICallback('inventory:useItem', function(data, cb)
    TriggerServerEvent('nx_inventory:server:useItem', data.name)
    cb(true)
end)

RegisterNetEvent('nx_inventory:client:refresh', function(items)
    cache = items
    SendNUIMessage({ action = 'inventory:setItems', items = cache })
end)
