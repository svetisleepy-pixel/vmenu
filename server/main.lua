local ESX = exports.es_extended:getSharedObject()

local Reports = {}
local Warns = {}
local ServiceState = {}
local FrozenPlayers = {}
local AdminLogs = {}

local function trim(value)
    if type(value) ~= 'string' then return '' end
    return value:match('^%s*(.-)%s*$')
end

local function cut(value, max)
    value = trim(value)
    if #value > max then
        return value:sub(1, max)
    end
    return value
end

local function addLog(kind, adminSrc, targetSrc, message, extra)
    local entry = {
        id = #AdminLogs + 1,
        kind = kind,
        adminSrc = adminSrc,
        adminName = adminSrc and GetPlayerName(adminSrc) or 'SYSTEM',
        targetSrc = targetSrc,
        targetName = targetSrc and GetPlayerName(targetSrc) or nil,
        message = message,
        extra = extra,
        createdAt = os.time()
    }
    AdminLogs[#AdminLogs + 1] = entry

    if #AdminLogs > Config.LogRetention then
        table.remove(AdminLogs, 1)
    end

    TriggerClientEvent('vmenu_admin:client:pushLog', -1, entry)
end

local function hasPerms(src)
    if src == 0 then return true end
    if Config.UseAcePermission and IsPlayerAceAllowed(src, 'vmenu.adminpanel') then
        return true
    end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end

    local group = xPlayer.getGroup()
    return Config.RequiredGroups[group] == true
end

local function findPlayer(source, targetId)
    local numeric = tonumber(targetId)
    if not numeric then return nil, 'Invalid target id.' end
    if not GetPlayerName(numeric) then return nil, ('Player %s is offline.'):format(numeric) end
    return numeric
end

local function getDashboard()
    local players = GetPlayers()
    local openReports = 0
    local inService = 0

    for _, report in pairs(Reports) do
        if report.status ~= 'closed' then
            openReports = openReports + 1
        end
    end

    for _ in pairs(ServiceState) do
        inService = inService + 1
    end

    return {
        onlinePlayers = #players,
        openReports = openReports,
        activeServices = inService,
        recentLogs = AdminLogs
    }
end

local function getPlayersList()
    local list = {}

    for _, src in ipairs(GetPlayers()) do
        local id = tonumber(src)
        local xPlayer = ESX.GetPlayerFromId(id)
        local warnCount = Warns[id] and #Warns[id] or 0

        list[#list + 1] = {
            id = id,
            name = GetPlayerName(id),
            group = xPlayer and xPlayer.getGroup() or 'user',
            ping = GetPlayerPing(id),
            warns = warnCount,
            inService = ServiceState[id] ~= nil
        }
    end

    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

local function getReportsList()
    local list = {}
    for id, report in pairs(Reports) do
        list[#list + 1] = {
            id = id,
            author = report.author,
            authorName = report.authorName,
            category = report.category,
            message = report.message,
            status = report.status,
            claimedBy = report.claimedBy,
            createdAt = report.createdAt,
            updates = report.updates
        }
    end

    table.sort(list, function(a, b) return a.id > b.id end)
    return list
end

local function getServices()
    local list = {}
    for src, service in pairs(ServiceState) do
        list[#list + 1] = {
            id = src,
            name = GetPlayerName(src) or ('ID %s'):format(src),
            reason = service.reason,
            remaining = service.remaining
        }
    end

    table.sort(list, function(a, b) return a.remaining > b.remaining end)
    return list
end

RegisterCommand(Config.Command, function(source)
    if not hasPerms(source) then
        TriggerClientEvent('esx:showNotification', source, 'No access to admin panel.')
        return
    end

    TriggerClientEvent('vmenu_admin:client:openPanel', source, {
        dashboard = getDashboard(),
        players = getPlayersList(),
        reports = getReportsList(),
        services = getServices(),
        logs = AdminLogs,
        quickActions = Config.QuickActions
    })
end)

local function guard(source)
    if not hasPerms(source) then
        addLog('security', nil, source, 'Unauthorized panel callback blocked', nil)
        return false
    end
    return true
end

RegisterNetEvent('vmenu_admin:server:panelAction', function(payload)
    local src = source
    if not guard(src) then return end

    if type(payload) ~= 'table' then return end
    local action = payload.action
    local target, err = findPlayer(src, payload.target)
    local reason = cut(payload.reason or 'No reason', Config.MaxReasonLength)

    if action ~= 'announcement' and action ~= 'refresh' and action ~= 'serviceTick' and action ~= 'closeReport' and action ~= 'claimReport' and action ~= 'createReport' then
        if not target then
            TriggerClientEvent('esx:showNotification', src, err)
            return
        end
    end

    if action == 'kick' then
        DropPlayer(target, ('Kicked by admin: %s'):format(reason))
        addLog('kick', src, target, reason)
    elseif action == 'ban' then
        DropPlayer(target, ('Banned by admin: %s'):format(reason))
        addLog('ban', src, target, reason, { duration = payload.duration or 'perm' })
    elseif action == 'warn' then
        Warns[target] = Warns[target] or {}
        Warns[target][#Warns[target] + 1] = { by = src, reason = reason, at = os.time() }
        TriggerClientEvent('esx:showNotification', target, ('You were warned: %s'):format(reason))
        addLog('warn', src, target, reason)

        if #Warns[target] >= Config.WarnKickThreshold then
            DropPlayer(target, 'Reached warning threshold.')
            addLog('auto_kick', src, target, 'Auto kick after warns')
        end
    elseif action == 'announcement' then
        local message = cut(payload.message or '', Config.MaxAnnouncementLength)
        if message == '' then return end
        TriggerClientEvent('chat:addMessage', -1, {
            color = { 255, 50, 50 },
            multiline = true,
            args = { '[ADMIN ANNOUNCEMENT]', message }
        })
        addLog('announcement', src, nil, message)
    elseif action == 'goto' then
        local coords = GetEntityCoords(GetPlayerPed(target))
        TriggerClientEvent('vmenu_admin:client:teleportTo', src, coords)
        addLog('goto', src, target, 'Teleported to player')
    elseif action == 'bring' then
        local coords = GetEntityCoords(GetPlayerPed(src))
        TriggerClientEvent('vmenu_admin:client:teleportTo', target, coords)
        addLog('bring', src, target, 'Brought player')
    elseif action == 'freeze' then
        FrozenPlayers[target] = not FrozenPlayers[target]
        TriggerClientEvent('vmenu_admin:client:setFrozen', target, FrozenPlayers[target])
        addLog('freeze', src, target, FrozenPlayers[target] and 'Frozen' or 'Unfrozen')
    elseif action == 'revive' then
        TriggerClientEvent('vmenu_admin:client:revive', target)
        addLog('revive', src, target, 'Revived player')
    elseif action == 'heal' then
        TriggerClientEvent('vmenu_admin:client:heal', target)
        addLog('heal', src, target, 'Healed player')
    elseif action == 'slay' then
        TriggerClientEvent('vmenu_admin:client:slay', target)
        addLog('slay', src, target, 'Slayed player')
    elseif action == 'service' then
        local minutes = math.floor(tonumber(payload.minutes) or 0)
        minutes = math.min(math.max(minutes, 1), Config.MaxServiceMinutes)
        ServiceState[target] = {
            reason = reason,
            remaining = minutes
        }
        TriggerClientEvent('esx:showNotification', target, ('Community service assigned: %s min | %s'):format(minutes, reason))
        addLog('service_assign', src, target, reason, { minutes = minutes })
    elseif action == 'clearService' then
        ServiceState[target] = nil
        TriggerClientEvent('esx:showNotification', target, 'Community service completed by admin.')
        addLog('service_clear', src, target, 'Community service removed')
    elseif action == 'createReport' then
        local category = cut(payload.category or 'General', 40)
        local message = cut(payload.message or '', Config.MaxReportLength)
        if message == '' then return end

        local reportId = #Reports + 1
        Reports[reportId] = {
            author = src,
            authorName = GetPlayerName(src),
            category = category,
            message = message,
            status = 'open',
            claimedBy = nil,
            createdAt = os.time(),
            updates = {}
        }

        addLog('report_created', src, nil, message, { reportId = reportId, category = category })
        TriggerClientEvent('esx:showNotification', src, ('Report #%s created.'):format(reportId))
    elseif action == 'claimReport' then
        local id = tonumber(payload.reportId)
        local report = id and Reports[id]
        if not report then return end
        report.claimedBy = src
        report.status = 'claimed'
        report.updates[#report.updates + 1] = { by = src, action = 'claimed', at = os.time() }
        addLog('report_claimed', src, report.author, ('Claimed report #%s'):format(id))
    elseif action == 'closeReport' then
        local id = tonumber(payload.reportId)
        local report = id and Reports[id]
        if not report then return end
        report.status = 'closed'
        report.updates[#report.updates + 1] = { by = src, action = 'closed', at = os.time(), note = reason }
        addLog('report_closed', src, report.author, ('Closed report #%s: %s'):format(id, reason))
    elseif action == 'serviceTick' then
        if ServiceState[src] then
            ServiceState[src].remaining = ServiceState[src].remaining - 1
            if ServiceState[src].remaining <= 0 then
                ServiceState[src] = nil
                TriggerClientEvent('esx:showNotification', src, 'Community service completed.')
                addLog('service_completed', src, nil, 'Service finished')
            end
        end
    elseif action == 'refresh' then
        -- intentional no-op; below returns fresh payload
    end

    TriggerClientEvent('vmenu_admin:client:updateData', src, {
        dashboard = getDashboard(),
        players = getPlayersList(),
        reports = getReportsList(),
        services = getServices(),
        logs = AdminLogs
    })
end)

RegisterNetEvent('vmenu_admin:server:requestTick', function()
    local src = source
    if ServiceState[src] then
        TriggerClientEvent('vmenu_admin:client:serviceStatus', src, ServiceState[src])
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    FrozenPlayers[src] = nil
end)
