# Sections

## AddSection

```lua
local Hitting = Tab:AddSection("Hitting", "Left")
local Running = Tab:AddSection("Running", "Right")
```

`column` is either:
- `"Left"`
- `"Right"`

## Common control options

Most stateful controls support:
- `Flag` - stable config key
- `Default` - initial value
- `Callback` - called on value change
- `Tooltip` - hover tooltip text
- `DisabledTooltip` - tooltip shown when disabled
- `Disabled` - disables interaction
- `Save = false` - excludes the control from config snapshots

## Available core methods
- `AddToggle`
- `AddSlider`
- `AddDropdown`
- `AddTextbox`
- `AddKeybind`
- `AddColorPicker`
- `AddButton`
- `AddLabel`
- `AddSeparator`
- `AddHoldButton`
- `AddOptionButton`
- `AddBind`
- `AddRadioGroup`
- `AddProgressBar`
