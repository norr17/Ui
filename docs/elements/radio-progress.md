# Radio Group and Progress Bar

## AddRadioGroup

```lua
Section:AddRadioGroup("Mode", {
    Flag = "Misc.Showcase.Mode",
    Options = { "Legit", "Rage", "Hybrid" },
    Default = "Legit",
    Callback = function(value)
        print(value)
    end,
})
```

Use this when exactly one option should be active.

## AddProgressBar

```lua
local Progress = Section:AddProgressBar("Sync", {
    Default = 72,
    Save = false,
})
```

Use this for read-only or manually updated status display.

## Notes
- These methods are part of core `KojoLib.lua`.
- They are not extension-only widgets.
