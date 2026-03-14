# vmenu vehicle park/delete script

Simple FiveM resource that adds configurable vehicle storage points.

## What it does
- Creates one blip per configured location.
- Draws a marker at each location.
- When a player drives any vehicle into the marker and presses **E**, the vehicle is immediately deleted.
- Supports unlimited locations through the config table.

## Installation
1. Put this folder in your server `resources` directory.
2. Add `ensure vmenu` to your `server.cfg`.
3. Edit `config.lua` and add/remove locations in `Config.VehicleDeletePoints`.

## Adding unlimited locations
Copy/paste another entry inside `Config.VehicleDeletePoints`:

```lua
{
    coords = vector3(0.0, 0.0, 0.0),
    radius = 5.0,
    blip = {
        enabled = true,
        sprite = 357,
        color = 1,
        scale = 0.8,
        name = 'Vehicle Storage'
    }
}
```

You can add as many entries as you want.
