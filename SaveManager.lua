return function()
    local env = getgenv and getgenv() or _G
    local library = env.KojoLibrary
    assert(library and library.SaveManagerClass, "[KojoHub] Load KojoHub.lua before addons/SaveManager.lua")

    return setmetatable({
        Library = library,
        Folder = "KojoHub",
        IgnoreFlags = {},
        IgnoreThemeData = false,
        SubFolder = nil,
    }, library.SaveManagerClass)
end
