# Kojo Hub UI

Single-file Roblox Luau UI library built for executor-side `loadstring(game:HttpGet(...))()` use.

The design target stays locked to the dark Kojo/Aikeo-style screenshots:

- matte black shell
- thin borders
- soft rounded cards
- muted mauve accent
- white-active text/icons only when active

This build keeps that visual language, but expands the feature surface toward Obsidian-style library usage.

## Files

- `C:\Users\Admin\Desktop\Kojo Project\backend\lua\KojoHub\KojoHub.lua` - runtime library
- `C:\Users\Admin\Desktop\Kojo Project\backend\lua\KojoHub\SaveManager.lua` - standalone save manager
- `C:\Users\Admin\Desktop\Kojo Project\backend\lua\KojoHub\ThemeManager.lua` - standalone theme manager
- `C:\Users\Admin\Desktop\Kojo Project\backend\lua\KojoHub\EXAMPLE.lua` - end-to-end example
- `C:\Users\Admin\Desktop\Kojo Project\backend\lua\KojoHub\SPEC.md` - visual teardown
- `C:\Users\Admin\Desktop\Kojo Project\backend\lua\KojoHub\render_preview.ps1` - static preview renderer

## Loadstring usage

```lua
local repo = "https://raw.githubusercontent.com/norr17/Ui/main/"
local Library = loadstring(game:HttpGet(repo .. "KojoHub.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "SaveManager.lua"))()
```

## Bootstrap

```lua
local Library = loadstring(game:HttpGet(repo .. "KojoHub.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "SaveManager.lua"))()

ThemeManager:SetLibrary(Library):SetFolder("KojoHub/themes")
SaveManager:SetLibrary(Library):SetFolder("KojoHub"):SetSubFolder("specific-place")

local Window = Library:CreateWindow({
    Title = "Kojo Hub",
    Icon = 95816097006870,
    ToggleKey = Enum.KeyCode.RightShift,
    NotifySide = "Right",
    MobileButtonsSide = "Right",
    ShowMobileButtons = true,
})
```

## Window API

### `Library:CreateWindow(options)`

Supported options:

- `Title` / `Name`
- `Footer`
- `Icon` / `Logo` - Roblox image asset id or `rbxassetid://...`
- `Size`
- `ToggleKey` / `ToggleKeybind`
- `SidebarWidth`
- `NotifySide`
- `CornerRadius`
- `MobileButtonsSide`
- `ShowMobileButtons`

Window methods:

- `AddTab(info, icon)`
- `AddKeyTab(info, icon)`
- `SetTab(tabOrName)`
- `SetVisible(boolean)`
- `SetCornerRadius(number)`
- `ChangeTitle(text)`
- `ChangeFooter(text)`

## Tabs and layout

### Window tabs

```lua
local Main = Window:AddTab({ Name = "Main", Icon = 123456 })
local Setting = Window:AddTab({ Name = "Setting", Icon = 123456 })
```

### Tab methods

- `AddLeftGroupbox(title)`
- `AddRightGroupbox(title)`
- `AddLeftTabbox(title)`
- `AddRightTabbox(title)`
- `AddGroupbox({ Side = 1 | 2, Name = "..." })`
- `AddTabbox({ Side = 1 | 2, Name = "..." })`

### Groupbox / tabbox page methods

- `AddLabel(...)`
- `AddButton(...)`
- `AddToggle(...)`
- `AddCheckbox(...)`
- `AddInput(...)`
- `AddSlider(...)`
- `AddDropdown(...)`
- `AddKeybind(...)`
- `AddKeyPicker(...)`
- `AddColorPicker(...)`
- `AddDivider(...)`
- `AddViewport(...)`
- `AddImage(...)`
- `AddVideo(...)`
- `AddUIPassthrough(...)`
- `AddDependencyBox()`
- `AddDependencyGroupbox()`

### Layout behavior

- side-by-side groupboxes are height-synced in pairs
- containers auto-grow with content
- dropdowns expand their own card height instead of overflowing out of the box

## Options / globals

The library exposes:

- `Library.Options`
- `Library.Toggles`

And also mirrors them to globals for executor convenience:

- `getgenv().Options`
- `getgenv().Toggles`
- `getgenv().KojoLibrary`

## Element features

Common methods on stateful elements:

- `GetValue()`
- `SetValue(value, silent?)`
- `OnChanged(callback)`
- `SetVisible(boolean)`
- `SetDisabled(boolean)`
- `SetText(text)`
- `AddDependency(optionOrFlag, expectedValue, predicate?)`

## Implemented controls

### Toggle / Checkbox

Supports:

- `Default`
- `Callback`
- `Changed`
- `Risky`
- `Disabled`
- `Visible`

When active, the label brightens to white and gets a subtle glow.

Toggle and checkbox keybind sync is built in:

```lua
local autoAim = Groupbox:AddToggle("AutoAim", { Text = "Auto Aim" })
autoAim:AddKeyPicker("AutoAimBind", {
    Default = { "Q", "Toggle" },
})
```

### Button

Supports Obsidian-style table syntax:

```lua
Groupbox:AddButton({
    Text = "Do thing",
    Func = function() end,
    DoubleClick = false,
    Risky = false,
    Disabled = false,
    Visible = true,
})
```

Also supports chained `:AddButton(...)`.

### Input

Supports:

- `Default`
- `Numeric`
- `Finished`
- `ClearTextOnFocus`
- `Placeholder`
- `MaxLength`
- `AllowEmpty`
- `EmptyReset`

### Slider

Supports:

- `Min`
- `Max`
- `Rounding`
- `Increment`
- `Prefix`
- `Suffix`
- `Compact`
- `HideMax`
- `FormatDisplayValue`

Methods:

- `SetMin(value)`
- `SetMax(value)`
- `SetPrefix(text)`
- `SetSuffix(text)`

### Dropdown

Supports:

- `Values`
- `Default`
- `Multi`
- `AllowNull`
- `Searchable`
- `DisabledValues`
- `MaxVisibleDropdownItems`
- `FormatDisplayValue`
- `SpecialType = "Player" | "Team"`
- `ExcludeLocalPlayer`

Methods:

- `GetActiveValues()`
- `SetValues(list)`
- `AddValues(listOrValue)`
- `SetDisabledValues(list)`
- `AddDisabledValues(listOrValue)`
- `RefreshSpecialValues()`

### Keybind / KeyPicker

Supports:

- keyboard keys
- mouse buttons (`MB1`, `MB2`, `MB3`)
- modes: `Always`, `Toggle`, `Hold`, `Press`
- `SyncToggleState`
- `WaitForCallback`
- `NoUI`
- right click on the keybind row cycles the mode

Methods:

- `GetState()`
- `OnChanged(callback)` - fires when the key or mode changes
- `OnClick(callback)` - fires when the bind is triggered
- `DoClick()`
- `SetValue({ key, mode, modifiers })`
- `SetMode(mode)`

### ColorPicker

Supports:

- `Default`
- `Transparency`
- `Title`
- `Callback`
- `Changed`

Methods:

- `SetValue(color, transparency?, silent?)`
- `SetValueRGB(color, transparency?, silent?)`

## SaveManager

```lua
local SaveManager = Library:CreateSaveManager()
SaveManager:SetFolder("KojoHub")
SaveManager:SetSubFolder("specific-place")
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:BuildConfigSection(Tab)
SaveManager:LoadAutoloadConfig()
```

Implemented methods:

- `SetLibrary(library)`
- `SetFolder(path)`
- `SetSubFolder(path)`
- `IgnoreFlag(flag)`
- `SetIgnoreIndexes(list)`
- `IgnoreThemeSettings()`
- `Save(name)`
- `Load(name)`
- `Delete(name)`
- `List()`
- `RefreshConfigList()`
- `GetAutoloadConfig()`
- `SaveAutoloadConfig(name)`
- `LoadAutoloadConfig()`
- `DeleteAutoLoadConfig()`
- `BuildConfigSection(tab)`

Saved element types:

- toggles
- checkboxes
- inputs
- sliders
- dropdowns
- keybinds
- color pickers

## ThemeManager

```lua
local ThemeManager = Library:CreateThemeManager():SetFolder("KojoHub/themes")
ThemeManager:ApplyToTab(Tabs.Setting)
```

Implemented methods:

- `SetLibrary(library)`
- `SetFolder(path)`
- `Register(name, themeTable)`
- `Apply(name)`
- `ApplyTheme(name)`
- `List()`
- `Save(name)`
- `Load(name)`
- `Delete(name)`
- `ReloadCustomThemes()`
- `ApplyToTab(tab)`
- `ApplyToGroupbox(groupbox)`

Built-in themes:

- `Kojo`
- `Slate`
- `Rose`

## Utility methods

- `Library:Notify(...)`
- `Library:SetNotifySide("Left" | "Right")`
- `Library:SetDPIScale(number)`
- `Library:Toggle(boolean?)`
- `Library:AddDraggableLabel(text)`
- `Library:OnUnload(callback)`
- `Library:Unload()`

## Notes

- logo and tab icons can be Roblox asset ids
- the sidebar and breadcrumb states brighten only for the active tab
- groupbox internals are tuned for equal-width two-column layouts like the reference screenshots
- the build is intentionally single-file for GitHub raw delivery
