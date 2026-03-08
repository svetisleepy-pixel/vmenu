local registeredTargets = {}
local enabled = true

local function getEntityFromRaycast(distance)
    local cameraCoord = GetGameplayCamCoord()
    local direction = GetGameplayCamRot(2)
    local adjusted = vector3(
        -math.sin(math.rad(direction.z)) * math.abs(math.cos(math.rad(direction.x))),
        math.cos(math.rad(direction.z)) * math.abs(math.cos(math.rad(direction.x))),
        math.sin(math.rad(direction.x))
    )

    local destination = cameraCoord + (adjusted * distance)
    local ray = StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0)
    local _, hit, _, _, entity = GetShapeTestResult(ray)

    if hit == 1 and entity ~= 0 then
        return entity
    end

    return nil
end

local function findOptionsForEntity(entity)
    local model = GetEntityModel(entity)
    local options = {}

    for _, target in pairs(registeredTargets) do
        if target.models and target.models[model] then
            for _, option in ipairs(target.options) do
                options[#options + 1] = option
            end
        end
    end

    return options
end

function AddTargetModel(models, data)
    local normalizedModels = {}
    for _, model in ipairs(models) do
        normalizedModels[GetHashKey(model)] = true
    end

    registeredTargets[#registeredTargets + 1] = {
        models = normalizedModels,
        options = data.options or {}
    }
end
exports('AddTargetModel', AddTargetModel)

function RemoveTargetModel(model)
    local hash = GetHashKey(model)
    for index = #registeredTargets, 1, -1 do
        if registeredTargets[index].models[hash] then
            table.remove(registeredTargets, index)
        end
    end
end
exports('RemoveTargetModel', RemoveTargetModel)

RegisterNetEvent('nx_target:client:setEnabled', function(state)
    enabled = state
    SendNUIMessage({ action = 'target:visibility', visible = state })
end)

CreateThread(function()
    while true do
        Wait(100)

        if not enabled then
            goto continue
        end

        local entity = getEntityFromRaycast(NX.TargetConfig.DrawDistance)
        if not entity then
            SendNUIMessage({ action = 'target:update', visible = false })
            goto continue
        end

        local entityOptions = findOptionsForEntity(entity)
        if #entityOptions == 0 then
            SendNUIMessage({ action = 'target:update', visible = false })
            goto continue
        end

        local option = entityOptions[1]
        SendNUIMessage({
            action = 'target:update',
            visible = true,
            label = option.label,
            icon = option.icon or NX.TargetConfig.DefaultIcon
        })

        if IsControlJustPressed(0, 38) then
            if option.event then
                TriggerEvent(option.event, entity)
            elseif option.serverEvent then
                TriggerServerEvent(option.serverEvent, NetworkGetNetworkIdFromEntity(entity))
            elseif option.action then
                option.action(entity)
            end
        end

        ::continue::
    end
end)
