# Buttons

## AddButton

```lua
Section:AddButton("Save Config", {
    Callback = function()
        print("clicked")
    end,
    Variant = "Default",
})
```

### Options
- `Callback`
- `Variant` - `Default`, `Primary`, `Danger`
- `Tooltip`
- `DisabledTooltip`
- `Disabled`
- `Save = false`

## AddHoldButton

```lua
Section:AddHoldButton("Charge", {
    OnStart = function() print("start") end,
    OnStop = function() print("stop") end,
})
```

### Notes
- `AddHoldButton` is not a persistent state control and is not saved by config.
