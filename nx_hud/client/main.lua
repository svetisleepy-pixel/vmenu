local playerState = {
    money = 2500,
    job = 'Civilian'
}

RegisterNetEvent('nx_hud:client:updateJob', function(jobLabel)
    playerState.job = jobLabel
end)

RegisterNetEvent('nx_hud:client:updateMoney', function(amount)
    playerState.money = amount
end)

CreateThread(function()
    while true do
        Wait(250)
        local ped = PlayerPedId()
        local health = math.max(0, (GetEntityHealth(ped) - 100))
        local armor = GetPedArmour(ped)
        local stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId())

        SendNUIMessage({
            action = 'hud:update',
            data = {
                health = health,
                armor = armor,
                stamina = stamina,
                money = playerState.money,
                job = playerState.job
            }
        })
    end
end)
