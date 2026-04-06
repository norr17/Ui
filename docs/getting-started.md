# Getting Started

```lua
local Library = loadstring(readfile("KojoLib.lua"))()
local Extended = loadstring(readfile("KojoExtended.lua"))()
Library:UseExtended(Extended)
Library:SetToggleKey(Enum.KeyCode.RightShift)

local Window = Library:CreateWindow({
    Title = "Kojo Hub",
    Width = 780,
    Height = 520,
})

local Main = Window:AddTab("Main")
local Combat = Main:AddSection("Combat", "Left")

Combat:AddToggle("Enabled", {
    Flag = "Main.Combat.Enabled",
    Default = false,
})
```

## Flow

1. Load `KojoLib.lua`
2. Optionally load `KojoExtended.lua`
3. Call `Library:CreateWindow(...)`
4. Add tabs with `Window:AddTab(...)`
5. Add sections with `Tab:AddSection(...)`
6. Add controls inside sections
