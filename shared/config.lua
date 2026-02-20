Config = {}

Config.Framework = 'esx'
Config.Command = 'ap'
Config.UseAcePermission = false
Config.RequiredGroups = {
    superadmin = true,
    admin = true,
    mod = true
}

Config.WarnKickThreshold = 3
Config.MaxAnnouncementLength = 220
Config.MaxReasonLength = 180
Config.MaxReportLength = 320
Config.MaxServiceMinutes = 240

Config.QuickActions = {
    { id = 'goto', label = 'Go to player' },
    { id = 'bring', label = 'Bring player' },
    { id = 'freeze', label = 'Freeze / Unfreeze' },
    { id = 'revive', label = 'Revive' },
    { id = 'heal', label = 'Heal' },
    { id = 'slay', label = 'Slay' }
}

Config.ServiceTickSeconds = 60
Config.LogRetention = 200
