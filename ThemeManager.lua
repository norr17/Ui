return function()
    local env = getgenv and getgenv() or _G
    local library = env.KojoLibrary
    assert(library and library.ThemeManagerClass, "[KojoHub] Load KojoHub.lua before addons/ThemeManager.lua")

    return setmetatable({
        Library = library,
        Folder = "KojoHub/themes",
    }, library.ThemeManagerClass)
end
