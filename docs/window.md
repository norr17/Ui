# Window

## CreateWindow

```lua
local Window = Library:CreateWindow({
    Title = "Kojo Hub",
    Width = 780,
    Height = 520,
    Icon = "rbxassetid://4483362458",
})
```

### Options
- `Title` - string shown in the breadcrumb root
- `Width` - window width in pixels
- `Height` - window height in pixels
- `Icon` - asset id used for the sidebar logo and default tab icons

## Window methods
- `Window:AddTab(name, iconId)`
- `Window:Toggle()`
- `Window:Show()`
- `Window:Hide()`
- `Window:Destroy()`

## AddTab

```lua
local Tab = Window:AddTab("Batting", "rbxassetid://4483362458")
```

Each tab gets:
- a sidebar button
- a scrollable content frame
- left and right section columns
