# Utilities

These APIs are part of `KojoLib.lua`.

## Notifications

```lua
Library:Notify({
    Title = "Kojo Hub",
    Description = "Loaded",
    Type = "Success",
    Duration = 3,
})
```

## Loading overlay
- `Library:CreateLoading(options)`

## Watermark
- `Library:CreateWatermark(options)`
- returned object supports `:SetText(...)`

## FPS counter
- `Library:CreateFPSCounter(options)`
- returned object supports enable/disable/update lifecycle internally

## Anti-AFK

```lua
Library:EnableAntiAFK()
```

## Movement helpers
- `Library:CreateSpeedHack({ DefaultSpeed = 24 })`
- `Library:CreateNoclip()`
- `Library:CreateFlyHack({ Speed = 2 })`
- `Library:CreateClickTeleport({})`

Example:

```lua
local Speed = Library:CreateSpeedHack({ DefaultSpeed = 24 })
Speed:Enable()
Speed:SetSpeed(30)
Speed:Disable()
```

## Global UI key

```lua
Library:SetToggleKey(Enum.KeyCode.RightShift)
```

This toggles all windows created by the library.
