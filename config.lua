Config = {}

-- Add as many parking/delete locations as needed.
-- Each location can have its own blip name, color, sprite and radius.
Config.VehicleDeletePoints = {
    {
        coords = vector3(-42.15, -1098.61, 26.42),
        radius = 5.0,
        blip = {
            enabled = true,
            sprite = 357,
            color = 1,
            scale = 0.8,
            name = 'Vehicle Storage'
        }
    },
    {
        coords = vector3(1853.74, 2585.92, 45.67),
        radius = 5.0,
        blip = {
            enabled = true,
            sprite = 357,
            color = 1,
            scale = 0.8,
            name = 'Gang Vehicle Storage'
        }
    }
}

Config.DrawMarker = true
Config.MarkerType = 36
Config.MarkerScale = vec3(1.2, 1.2, 1.2)
Config.MarkerColor = { r = 220, g = 40, b = 40, a = 180 }

Config.HelpText = 'Press ~INPUT_CONTEXT~ to store/delete this vehicle'
Config.SuccessText = 'Vehicle stored.'
Config.MustBeInVehicleText = 'You must be inside a vehicle.'
