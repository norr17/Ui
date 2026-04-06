# Config

KojoLib has a built-in config layer, and `SaveManager.lua` provides a higher-level manager that builds config UI.

## Low-level config

```lua
local Config = Library:CreateConfig({
    Folder = "KojoHub",
    Name = "legit",
})

Config:SetIgnoreFlags({ "Setting.Menu.Menu Bind" })
Config:Save()
Config:Load()
Config:SetAutoload()
Config:LoadAutoload()
```

## SaveManager setup

```lua
local SaveManager = loadstring(game:HttpGet(repo .. "SaveManager.lua"))()

SaveManager:SetLibrary(Library)
SaveManager:SetFolder("KojoHub")
SaveManager:SetSubFolder("universal")
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:BuildConfigSection(Tabs.Setting)
SaveManager:LoadAutoloadConfig()
```

## SaveManager methods
- `SetLibrary`
- `SetFolder`
- `SetSubFolder`
- `IgnoreThemeSettings`
- `SetIgnoreIndexes`
- `BuildConfigSection`
- `LoadAutoloadConfig`
