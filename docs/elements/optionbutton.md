# Option Button

`AddOptionButton` is a compact cycling selector.

```lua
Section:AddOptionButton("Aim Type", {
    Flag = "Batting.Hitting.AimType",
    Values = { "Aim", "Silent Aim", "Closest" },
    Default = "Aim",
    Callback = function(value)
        print(value)
    end,
})
```

## Options
- `Flag`
- `Options` or `Values`
- `Default`
- `Callback`
- `Tooltip`
- `DisabledTooltip`
- `Disabled`
- `Save = false`

## Returned object
- `:Set(value)`
- `:GetValue()`
