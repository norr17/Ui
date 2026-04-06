# Keybind

```lua
Section:AddKeybind("Walk TP Bind", {
    Flag = "Player.Walk.WalkTPBind",
    Default = { "Q", "Toggle" },
    Callback = function(stateOrKey, key, mode)
        print(stateOrKey, key, mode)
    end,
    HoldCallback = function(key)
        print("holding", key)
    end,
})
```

## Modes
- `Toggle`
- `Hold`
- `Always`
- `Press`

## Accepted defaults
- `Enum.KeyCode.Q`
- `{ "Q", "Toggle" }`
- `{ Key = "Q", Mode = "Toggle" }`
- `"MB1"`, `"MB2"`, `"MB3"`

## Interaction
- left click the bind button to listen for a new key
- right click the bind button to cycle modes

## Returned object
- `:Set(keyOrTable)`
- `:SetMode(mode)`
- `:GetValue()`
- `:GetState()`
