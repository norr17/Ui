# Color Picker

```lua
Section:AddColorPicker("Accent Preview", {
    Flag = "Setting.Menu.AccentPreview",
    Default = Color3.fromRGB(186, 147, 255),
    Callback = function(color)
        Library:SetTheme({ Accent = color })
    end,
})
```

## Options
- `Flag`
- `Default`
- `Callback`
- `Tooltip`
- `DisabledTooltip`
- `Disabled`
- `Save = false`

## Returned object
- `:Set(color3)`
- `:GetValue()`
