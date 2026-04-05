-- Remote usage:
-- local repo = "https://raw.githubusercontent.com/norr17/Ui/main/"
-- local Library = loadstring(game:HttpGet(repo .. "KojoHub.lua"))()
-- local ThemeManager = loadstring(game:HttpGet(repo .. "ThemeManager.lua"))()
-- local SaveManager = loadstring(game:HttpGet(repo .. "SaveManager.lua"))()

local repo = "https://raw.githubusercontent.com/norr17/Ui/main/"
local Library = loadstring(game:HttpGet(repo .. "KojoHub.lua?v=example"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "ThemeManager.lua?v=example"))()
local SaveManager = loadstring(game:HttpGet(repo .. "SaveManager.lua?v=example"))()

ThemeManager:SetLibrary(Library):SetFolder("KojoHub/themes")
SaveManager:SetLibrary(Library):SetFolder("KojoHub"):SetSubFolder("baseball-demo")

Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
    Title = "Kojo Hub",
    Icon = 95816097006870,
    ToggleKey = Enum.KeyCode.RightShift,
    NotifySide = "Right",
    MobileButtonsSide = "Right",
    ShowMobileButtons = true,
})

local Tabs = {
    Batting = Window:AddTab({ Name = "Batting", Icon = "" }),
    Fielding = Window:AddTab({ Name = "Fielding", Icon = "" }),
    Misc = Window:AddTab({ Name = "Misc", Icon = "" }),
    Player = Window:AddTab({ Name = "Player", Icon = "" }),
    Setting = Window:AddTab({ Name = "Setting", Icon = "" }),
}

local Hitting = Tabs.Batting:AddLeftGroupbox("Hitting")
local Running = Tabs.Batting:AddRightGroupbox("Running")

local BallEsp = Hitting:AddToggle("BallEsp", {
    Text = "Ball esp",
    Default = false,
})

local AutoAim = Hitting:AddToggle("AutoAim", {
    Text = "Auto Aim",
    Default = false,
})

AutoAim:AddKeyPicker("AutoAimBind", {
    Text = "Auto Aim keybind",
    Default = { "Q", "Toggle" },
})

Hitting:AddDropdown("AimType", {
    Text = "Aim Type",
    Values = { "Aim", "Silent Aim", "Closest" },
    Default = "Aim",
})

Hitting:AddToggle("AutoSwing", {
    Text = "Auto Swing",
    Default = false,
}):AddDependency(AutoAim, true)

Hitting:AddSlider("TimeAdjustment", {
    Text = "Time Adjustment",
    Min = -1,
    Max = 1,
    Rounding = 1,
    Default = -0.1,
})

Hitting:AddToggle("StrikeboxOnly", {
    Text = "Strikebox Only",
    Default = false,
}):AddDependency(BallEsp, false, function(value)
    return value == false
end)

Running:AddToggle("AutoRunBases", {
    Text = "Auto Run Bases",
})

Running:AddToggle("VisualizePath", {
    Text = "Visualize Path",
})

Running:AddSlider("BaseWaitTime", {
    Text = "Base Wait Time",
    Min = 0,
    Max = 2,
    Rounding = 1,
    Default = 1,
})

Running:AddDropdown("QuitOnBase", {
    Text = "Quit On Base",
    Values = { "None", "First", "Second", "Third", "Home" },
    Default = "None",
})

local OutField = Tabs.Fielding:AddLeftGroupbox("outField")
local InField = Tabs.Fielding:AddRightGroupbox("inField")

OutField:AddToggle("TeleportBallEndPosition", {
    Text = "Teleport Ball end position",
})

OutField:AddToggle("ShowStrikebox", {
    Text = "show Strikebox",
})

OutField:AddDropdown("CustomBat", {
    Text = "custom Bat",
    Values = { "Neon", "Wood", "Chrome" },
    Default = "Neon",
})

InField:AddToggle("AutoPitch", {
    Text = "Auto Pitch",
})

InField:AddSlider("PitchPower", {
    Text = "Pitch Power",
    Min = 0,
    Max = 1,
    Rounding = 3,
    Default = 0.375,
})

InField:AddToggle("AutoTagRunners", {
    Text = "Auto Tag Runners",
})

local Catcher = Tabs.Misc:AddLeftGroupbox("Catcher")

Catcher:AddToggle("BlockBattersView", {
    Text = "Block Batters View",
})

Catcher:AddSlider("InfrontOffset", {
    Text = "Infront Offset",
    Min = 0,
    Max = 2,
    Rounding = 1,
    Default = 1,
})

Catcher:AddSlider("BlockDuration", {
    Text = "Block Duration",
    Min = 0,
    Max = 1,
    Rounding = 1,
    Default = 0.5,
})

local Utility = Tabs.Misc:AddRightTabbox("UI Elements")
local General = Utility:AddTab("General")
local Lists = Utility:AddTab("Lists")
local Media = Utility:AddTab("Media")
local Binds = Utility:AddTab("Binds")

General:AddLabel("All core controls live in the library; this example only instantiates them.", true)
General:AddDivider("Actions")

General:AddButton({
    Text = "Refresh theme list",
    Func = function()
        if Library.Options.ThemeManager_BuiltinList then
            Library.Options.ThemeManager_BuiltinList:SetValues(ThemeManager:List())
        end
    end,
})

General:AddInput("StatusText", {
    Text = "Status",
    Default = "Kojo loaded",
    Placeholder = "write something",
})

General:AddCheckbox("DemoCheckbox", {
    Text = "Checkbox example",
    Default = true,
})

General:AddSlider("DemoSlider", {
    Text = "Example slider",
    Min = 0,
    Max = 100,
    Default = 35,
})

General:AddColorPicker("AccentPreview", {
    Text = "Accent Preview",
    Default = Color3.fromRGB(184, 165, 196),
    Transparency = 0,
})

Lists:AddDropdown("PlayerList", {
    Text = "Player list",
    SpecialType = "Player",
    ExcludeLocalPlayer = true,
    AllowNull = true,
    Searchable = true,
})

Lists:AddDropdown("MultiTargets", {
    Text = "Multi targets",
    Values = { "Legit", "Silent", "Resolver", "Auto Shoot", "Prediction", "ESP" },
    Multi = true,
    Searchable = true,
    MaxVisibleDropdownItems = 6,
})

Media:AddLabel("Viewport")
Media:AddViewport("Preview viewport", {
    Height = 110,
})

Media:AddImage("Preview image", {
    Height = 110,
    Image = "rbxassetid://95816097006870",
})

Media:AddVideo("Preview video", {
    Height = 110,
    Video = "",
    Playing = false,
})

Media:AddUIPassthrough({
    Height = 70,
    Transparent = false,
})

Binds:AddLabel("Right click a keybind row to cycle Toggle / Hold / Always / Press.", true)
Binds:AddKeybind("ListToggleBind", {
    Text = "List toggle bind",
    Default = { "T", "Toggle" },
})
Binds:AddKeybind("ListHoldBind", {
    Text = "List hold bind",
    Default = { "Y", "Hold" },
})
Binds:AddKeybind("ListAlwaysBind", {
    Text = "List always bind",
    Default = { "U", "Always" },
})
Binds:AddKeybind("ListPressBind", {
    Text = "List press bind",
    Default = { "I", "Press" },
})

local Walk = Tabs.Player:AddLeftGroupbox("Walk")
local Jump = Tabs.Player:AddRightGroupbox("Jump")

local WalkToggle = Walk:AddToggle("EnableWalkTP", {
    Text = "Enable Walk TP",
})

Walk:AddSlider("WalkTPInterval", {
    Text = "Walk TP interval",
    Min = 0,
    Max = 5,
    Rounding = 1,
    Default = 1,
}):AddDependency(WalkToggle, true)

local JumpToggle = Jump:AddToggle("EnableSuperJump", {
    Text = "Enable Super Jump",
})

Jump:AddSlider("JumpPower", {
    Text = "Jump Power",
    Min = 0,
    Max = 100,
    Default = 50,
}):AddDependency(JumpToggle, true)

Jump:AddLabel("Jump bind"):AddKeyPicker("JumpBind", {
    Default = { "V", "Hold" },
    Text = "Super jump key",
})

local MenuGroup = Tabs.Setting:AddLeftGroupbox("Menu")
local KeybindModes = Tabs.Setting:AddRightGroupbox("Keybind Modes")

MenuGroup:AddDropdown("NotificationSide", {
    Text = "Notification Side",
    Values = { "Left", "Right" },
    Default = "Right",
    Callback = function(value)
        Library:SetNotifySide(value)
    end,
})

MenuGroup:AddDropdown("DPIDropdown", {
    Text = "DPI Scale",
    Values = { "75%", "100%", "125%", "150%" },
    Default = "125%",
    Callback = function(value)
        local number = tonumber((value or "100"):gsub("%%", "")) or 100
        Library:SetDPIScale(number)
    end,
})

MenuGroup:AddSlider("CornerRadius", {
    Text = "Corner Radius",
    Min = 10,
    Max = 22,
    Default = 16,
    Callback = function(value)
        Window:SetCornerRadius(value)
    end,
})

MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = { "RightShift", "Toggle" },
    NoUI = true,
    Text = "Menu keybind",
})

Library.ToggleKeybind = Library.Options.MenuKeybind

MenuGroup:AddButton({
    Text = "Unload",
    Func = function()
        Library:Unload()
    end,
})

local SyncToggle = KeybindModes:AddToggle("ExampleSyncToggle", {
    Text = "Sync toggle",
    Default = false,
})

KeybindModes:AddKeybind("ToggleModeBind", {
    Text = "Toggle mode",
    Default = { "Z", "Toggle" },
    Callback = function(state)
        print("Toggle mode:", state)
    end,
})

KeybindModes:AddKeybind("HoldModeBind", {
    Text = "Hold mode",
    Default = { "X", "Hold" },
    Callback = function(state)
        print("Hold mode:", state)
    end,
})

KeybindModes:AddKeybind("AlwaysModeBind", {
    Text = "Always mode",
    Default = { "C", "Always" },
    Callback = function(state)
        print("Always mode:", state)
    end,
})

KeybindModes:AddKeybind("PressModeBind", {
    Text = "Press mode",
    Default = { "V", "Press" },
    Callback = function()
        print("Press mode fired")
    end,
})

KeybindModes:AddKeybind("SyncedToggleBind", {
    Text = "Synced toggle key",
    Default = { "B", "Toggle" },
    SyncToggleState = true,
    SyncTarget = SyncToggle,
    Callback = function(state)
        print("Synced toggle:", state)
    end,
})

KeybindModes:AddLabel("Mobile support")
KeybindModes:AddLabel("Touch drag, touch sliders, and a mobile menu button are enabled by default.", true)
KeybindModes:AddDivider("Toggle sync")
KeybindModes:AddLabel("Auto Aim also has a synced toggle keybind in the Batting tab.", true)

ThemeManager:ApplyToTab(Tabs.Setting)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind", "NotificationSide", "DPIDropdown", "CornerRadius" })
SaveManager:BuildConfigSection(Tabs.Setting)
SaveManager:LoadAutoloadConfig()

Library:AddDraggableLabel("Kojo Hub")

Library:Notify({
    Title = "Kojo Hub",
    Description = "Loaded example window. Use RightShift to toggle the menu.",
    Time = 5,
})
