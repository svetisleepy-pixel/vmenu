local ESX = exports['es_extended']:getSharedObject()

local function notify(source, msg)
    TriggerClientEvent('esx:showNotification', source, msg)
end

local function isAllowed(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return false
    end

    local group = xPlayer.getGroup()
    return Config.AllowedGroups[group] == true
end

local function registerVehicleCommand(commandName, eventName, actionLabel)
    RegisterCommand(commandName, function(source)
        if source <= 0 then
            print(('^3[vmenu_esx_vehicle_admin]^7 Command /%s can only be used in game.'):format(commandName))
            return
        end

        if not isAllowed(source) then
            notify(source, Config.Locale.noPermission)
            return
        end

        TriggerClientEvent(eventName, source)
        notify(source, Config.Locale.actionSent:format(actionLabel))
    end, false)
end

registerVehicleCommand(Config.Commands.boost, 'vmenu_esx_vehicle_admin:client:boost', 'BOOST')
registerVehicleCommand(Config.Commands.god, 'vmenu_esx_vehicle_admin:client:toggleGodMode', 'GOD MODE')
registerVehicleCommand(Config.Commands.repair, 'vmenu_esx_vehicle_admin:client:repair', 'REPAIR')
registerVehicleCommand(Config.Commands.clean, 'vmenu_esx_vehicle_admin:client:clean', 'CLEAN')
registerVehicleCommand(Config.Commands.flip, 'vmenu_esx_vehicle_admin:client:flip', 'FLIP')
registerVehicleCommand(Config.Commands.maxupgrade, 'vmenu_esx_vehicle_admin:client:maxUpgrade', 'MAX UPGRADE')
