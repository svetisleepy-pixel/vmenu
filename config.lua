Config = {}

-- ESX groups that can use the commands below.
Config.AllowedGroups = {
    admin = true,
    superadmin = true,
    owner = true,
}

-- Command names (without /)
Config.Commands = {
    boost = 'vboost',
    god = 'vgodcar',
    repair = 'vfixcar',
    clean = 'vcleancar',
    flip = 'vflipcar',
    maxupgrade = 'vmaxcar',
}

-- How strong the boost should be.
Config.Boost = {
    power = 85.0, -- default vMenu-like quick launch feel
    durationMs = 2500,
}

Config.Locale = {
    noPermission = 'Nimaš dovoljenja za ta ukaz.',
    actionSent = 'Vozilo je bilo posodobljeno: %s',
    noVehicle = 'Moraš biti v vozilu (voznik).',
    toggledOn = 'VKLOPLJENO',
    toggledOff = 'IZKLOPLJENO',
}
