# Dropdown

```lua
Section:AddDropdown("Quit On Base", {
    Flag = "Batting.Running.QuitOnBase",
    Options = { "None", "1st", "2nd", "3rd", "Home" },
    Default = "None",
    Callback = function(value)
        print(value)
    end,
})
```

## Options
- `Flag`
- `Options` or `Values`
- `Default`
- `Multi`
- `Callback`
- `Tooltip`
- `DisabledTooltip`
- `Disabled`
- `Save = false`

## Returned object
- `:Set(value)`
- `:SetOptions(options)`
- `:GetValue()`

## Notes
- When `Multi = true`, `Default` may be a table.
- Outside-click close is handled by the library.
