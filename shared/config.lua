Config = {}

Config.Debug = true

Config.Truck = {
    model = 'phantom',
    coords = vec4(201.53, 2796.61, 45.66, 96.39)
}

Config.PickUpLocation = {
    {
        model = 'docktrailer',
        coords = vec4(582.91, 2794.75, 42.19, 5.99)
    },
}

Config.DropoffLocation = {
    {
        coords = vec4(1209.25, 2714.85, 38.01, 357.72)
    },
}

Config.Manager = {
    model = 'ig_nigel',
    coords = vec4(180.09, 2793.35, 45.66, 283.48),

    targetData = {
        label = 'Trucker Job',
        icon = 'fa-solid fa-truck'
    }
}

function dbug(...)
    if Config.Debug then print('^3[DEBUG]^7', ...) end
end