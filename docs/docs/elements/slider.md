# Slider

```lua
Section:AddSlider("Pitch Power", {
    Flag = "Fielding.InField.PitchPower",
    Min = 0,
    Max = 1,
    Step = 0.025,
    Decimals = 3,
    Default = 0.375,
    Suffix = "",
    Callback = function(value)
        print(value)
    end,
})
```

## Options
- `Flag`
- `Min`
- `Max`
- `Step`
- `Decimals`
- `Default`
- `Suffix`
- `Callback`
- `Tooltip`
- `DisabledTooltip`
- `Disabled`
- `Save = false`

## Returned object
- `:Set(number)`
- `:GetValue()`
