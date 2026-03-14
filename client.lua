local function showHelpText(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function showNotification(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, false)
end

local function drawDeleteMarker(point)
    if not Config.DrawMarker then
        return
    end

    local c = point.coords
    local s = Config.MarkerScale
    local mc = Config.MarkerColor

    DrawMarker(
        Config.MarkerType,
        c.x,
        c.y,
        c.z - 0.95,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        s.x,
        s.y,
        s.z,
        mc.r,
        mc.g,
        mc.b,
        mc.a,
        false,
        false,
        2,
        false,
        nil,
        nil,
        false
    )
end

local function createBlips()
    for _, point in ipairs(Config.VehicleDeletePoints) do
        if point.blip and point.blip.enabled then
            local blip = AddBlipForCoord(point.coords.x, point.coords.y, point.coords.z)
            SetBlipSprite(blip, point.blip.sprite or 357)
            SetBlipColour(blip, point.blip.color or 1)
            SetBlipScale(blip, point.blip.scale or 0.8)
            SetBlipAsShortRange(blip, true)

            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(point.blip.name or 'Vehicle Storage')
            EndTextCommandSetBlipName(blip)
        end
    end
end

CreateThread(function()
    createBlips()

    while true do
        local waitTime = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for _, point in ipairs(Config.VehicleDeletePoints) do
            local dist = #(playerCoords - point.coords)
            local radius = point.radius or 5.0

            if dist <= radius + 15.0 then
                waitTime = 0
                drawDeleteMarker(point)
            end

            if dist <= radius then
                showHelpText(Config.HelpText)

                if IsControlJustReleased(0, 38) then -- E
                    if IsPedInAnyVehicle(playerPed, false) then
                        local veh = GetVehiclePedIsIn(playerPed, false)

                        if veh ~= 0 then
                            SetEntityAsMissionEntity(veh, true, true)
                            DeleteVehicle(veh)

                            if DoesEntityExist(veh) then
                                NetworkRequestControlOfEntity(veh)
                                SetVehicleHasBeenOwnedByPlayer(veh, false)
                                SetEntityAsMissionEntity(veh, true, true)
                                DeleteEntity(veh)
                            end

                            showNotification(Config.SuccessText)
                        end
                    else
                        showNotification(Config.MustBeInVehicleText)
                    end
                end
            end
        end

        Wait(waitTime)
    end
end)
