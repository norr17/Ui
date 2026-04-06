# KojoLib API

Use this file as the compact index. For examples and option notes, read the pages in `docs/`.

## Library

- `Library:CreateWindow(options)`
- `Library:CreateLoading(options)`
- `Library:Notify(options)`
- `Library:SetTheme(themeTable)`
- `Library:GetTheme()`
- `Library:SetToggleKey(key)`
- `Library:Destroy()`
- `Library:CreateWatermark(options)`
- `Library:CreateFPSCounter(options)`
- `Library:CreateConfig(options)`
- `Library:EnableAntiAFK()`
- `Library:CreateSpeedHack(options)`
- `Library:CreateNoclip()`
- `Library:CreateFlyHack(options)`
- `Library:CreateClickTeleport(options)`
- `Library:UseExtended(extended)`

## Window

- `Window:AddTab(name, iconId)`
- `Window:Toggle()`
- `Window:Show()`
- `Window:Hide()`
- `Window:Destroy()`

## Tab

- `Tab:AddSection(name, column)`

## Core section methods

All stateful elements accept `Flag` and `Save = false`.

- `Section:AddToggle(label, opts)`
- `Section:AddSlider(label, opts)`
- `Section:AddDropdown(label, opts)`
- `Section:AddTextbox(label, opts)`
- `Section:AddKeybind(label, opts)`
- `Section:AddColorPicker(label, opts)`
- `Section:AddButton(labelOrOpts, opts)`
- `Section:AddLabel(text, opts)`
- `Section:AddSeparator()`
- `Section:AddHoldButton(label, opts)`
- `Section:AddOptionButton(label, opts)`
- `Section:AddBind(label, opts)`
- `Section:AddRadioGroup(label, opts)`
- `Section:AddProgressBar(label, opts)`

## Keybind modes

`AddKeybind` supports:
- `Toggle`
- `Hold`
- `Always`
- `Press`

Accepted defaults:
- `Enum.KeyCode.Q`
- `{ "Q", "Toggle" }`
- `{ Key = "Q", Mode = "Toggle" }`
- mouse buttons: `"MB1"`, `"MB2"`, `"MB3"`

Returned keybind object:
- `:Set(keyOrTable)`
- `:SetMode(mode)`
- `:GetValue()`
- `:GetState()`

## Config manager

- `config:Set(flag, value)`
- `config:Get(flag)`
- `config:SetIgnoreFlags({ ... })`
- `config:IgnoreFlag(flag)`
- `config:Collect()`
- `config:Apply(data)`
- `config:Save(name?)`
- `config:Load(name?)`
- `config:Delete(name?)`
- `config:ListConfigs()`
- `config:SetAutoload(name?)`
- `config:GetAutoload()`
- `config:ClearAutoload()`
- `config:LoadAutoload()`

## KojoExtended section methods

Available after `Library:UseExtended(Extended)`:
- `Section:AddTable(label, opts)`
- `Section:AddSearchBox(label, opts)`
- `Section:AddSubTabs(label, opts)`
- `Section:AddToggleLock(label, opts)`
