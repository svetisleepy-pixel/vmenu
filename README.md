# vmenu_drugs

Standalone FiveM drug script using only GTA V native help text + notifications, with ox_inventory support.

## Files
- `fxmanifest.lua`
- `config.lua`
- `client.lua`
- `server.lua`

## ox_inventory item setup
Add these items in your ox_inventory data/items.lua:

```lua
['weed_leaf'] = {
    label = 'Weed Leaf',
    weight = 10,
    stack = true,
    close = true,
    description = 'Freshly harvested leaf.'
},

['weed_drug'] = {
    label = 'Processed Drug',
    weight = 20,
    stack = true,
    close = true,
    description = 'Ready to use.',
    client = {
        export = 'vmenu_drugs.useDrug'
    }
},
```

## Start order
Ensure `ox_inventory` starts before this resource.

```cfg
ensure ox_inventory
ensure vmenu_drugs
```

## Controls
- `E` = interact (harvest/process)
- `X` = cancel current harvest/process animation

## Config
All locations, radii, rewards, durations, and item names are in `config.lua`.
