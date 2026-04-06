# Theme

KojoLib supports direct palette overrides, and `ThemeManager.lua` adds a higher-level preset UI.

## Direct theme override

```lua
Library:SetTheme({
    Accent = Color3.fromRGB(230, 110, 160),
    TextPrimary = Color3.fromRGB(240, 240, 245),
})
```

## ThemeManager setup

```lua
local ThemeManager = loadstring(game:HttpGet(repo .. "ThemeManager.lua"))()

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("KojoHub")
ThemeManager:ApplyToTab(Tabs.Setting)
```

## Presets
Current built-in presets:
- `Default`
- `Rose`
- `Emerald`
- `Amber`

## ThemeManager methods
- `SetLibrary`
- `SetFolder`
- `GetThemes`
- `ApplyTheme`
- `ApplyToTab`
- `ApplyToGroupbox`
