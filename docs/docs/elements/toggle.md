# Toggle

```lua
Section:AddToggle("Auto Aim", {
    Flag = "Batting.Hitting.AutoAim",
    Default = false,
    Tooltip = "Enable assisted targeting.",
    Callback = function(value)
        print(value)
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
- `:Set(boolean)`
- `:Toggle()`
- `:GetValue()`
