Config = {}

Config.Debug = false

Config.GatherZone = {
    center = vec3(2228.29, 5577.13, 53.84),
    radius = 38.0,
    maxPlants = 20,
    minDistanceBetweenPlants = 2.2,
    model = `prop_weed_02`,
    respawnDelayMs = 12000,
    interactDistance = 2.0,
    durationMs = 5000,
    rewardItem = 'weed_leaf',
    rewardAmount = { min = 2, max = 5 }
}

Config.Process = {
    coords = vec3(2434.42, 4968.72, 42.35),
    heading = 312.0,
    interactDistance = 2.0,
    durationMs = 5000,
    inputItem = 'weed_leaf',
    inputAmount = 3,
    outputItem = 'weed_drug',
    outputAmount = { min = 1, max = 2 }
}

Config.DrugUse = {
    item = 'weed_drug',
    durationMs = { min = 40000, max = 50000 },
    speedMultiplier = 1.18,
    armour = 100,
    animation = {
        dict = 'mp_suicide',
        clip = 'pill',
        durationMs = 3500
    }
}

Config.CancelKey = 73 -- X

Config.HelpTexts = {
    harvest = 'Press ~INPUT_CONTEXT~ to harvest leaves',
    process = 'Press ~INPUT_CONTEXT~ to process leaves'
}

Config.Notifications = {
    harvestSuccess = 'You collected leaves.',
    harvestFailed = 'You failed to collect this plant.',
    processStart = 'Processing leaves...',
    processSuccess = 'You processed leaves into product.',
    processFailed = 'Processing failed.',
    cancelled = 'Action cancelled.',
    needLeaves = 'Not enough leaves.',
    drugStart = 'You used the drug.',
    drugEnd = 'The effect has worn off.'
}

Config.ItemLabels = {
    leaves = 'weed_leaf',
    drug = 'weed_drug'
}
