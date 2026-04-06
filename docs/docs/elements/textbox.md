# Textbox

```lua
Section:AddTextbox("Config Name", {
    Flag = "Setting.Config.NameBuffer",
    Default = "example",
    Placeholder = "Config name",
    Callback = function(text, enterPressed)
        print(text, enterPressed)
    end,
})
```

## Options
- `Flag`
- `Default`
- `Placeholder`
- `Callback`
- `OnFocus`
- `OnLoseFocus`
- `Numeric`
- `Tooltip`
- `DisabledTooltip`
- `Disabled`
- `Save = false`

## Returned object
- `:Set(value)`
- `:GetValue()`
