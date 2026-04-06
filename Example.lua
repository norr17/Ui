-- Kojo executor-ready example

local repo = "https://raw.githubusercontent.com/norr17/Ui/main/"

local Library = loadstring(game:HttpGet(repo .. "KojoLib.lua"))()
local Extended = loadstring(game:HttpGet(repo .. "KojoExtended.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "SaveManager.lua"))()

Library:UseExtended(Extended)
Library:SetToggleKey(Enum.KeyCode.RightShift)

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({
    Title = "Kojo Hub",
    Width = 780,
    Height = 520,
    Icon = "rbxassetid://4483362458",
})

local Tabs = {
    Batting = Window:AddTab("Batting", "rbxassetid://4483362458"),
    Fielding = Window:AddTab("Fielding", "rbxassetid://4483362458"),
    Misc = Window:AddTab("Misc", "rbxassetid://4483362458"),
    Player = Window:AddTab("Player", "rbxassetid://4483362458"),
    Key = Window:AddKeyTab("Key System", "rbxassetid://4483362458"),
    Setting = Window:AddTab("Setting", "rbxassetid://4483362458"),
}

local Hitting = Tabs.Batting:AddLeftGroupbox("Hitting")
local Running = Tabs.Batting:AddRightGroupbox("Running")

Hitting:AddToggle("BallEsp", {
    Text = "Ball esp",
    Default = false,
    Tooltip = "Toggle the ball ESP overlay.",
    Callback = function(value)
        print("Ball esp:", value)
    end,
})

Hitting:AddToggle("AutoAim", {
    Text = "Auto Aim",
    Default = false,
    Tooltip = "Enable assisted targeting.",
    Callback = function(value)
        print("Auto Aim:", value)
    end,
})
    :AddColorPicker("AutoAimColor", {
        Default = Color3.fromRGB(186, 147, 255),
        Callback = function(value)
            print("AutoAim color:", value)
        end,
    })

Hitting:AddOptionButton("AimType", {
    Text = "Aim Type",
    Values = { "Aim", "Silent Aim", "Closest" },
    Default = "Aim",
})

Hitting:AddToggle("AutoSwing", {
    Text = "Auto Swing",
    Default = false,
})

Hitting:AddSlider("TimeAdjustment", {
    Text = "Time Adjustment",
    Min = -1,
    Max = 1,
    Step = 0.1,
    Decimals = 1,
    Default = 0,
})

Hitting:AddCheckbox("StrikeboxOnly", {
    Text = "Strikebox Only",
    Default = false,
})

Running:AddToggle("AutoRunBases", {
    Text = "Auto Run Bases",
    Default = false,
})

Running:AddToggle("VisualizePath", {
    Text = "Visualize Path",
    Default = false,
})

Running:AddSlider("BaseWaitTime", {
    Text = "Base Wait Time",
    Min = 0,
    Max = 2,
    Step = 0.1,
    Decimals = 1,
    Default = 1,
})

Running:AddDropdown("QuitOnBase", {
    Text = "Quit On Base",
    Values = { "None", "1st", "2nd", "3rd", "Home" },
    Default = "None",
})

local OutField = Tabs.Fielding:AddLeftGroupbox("outField")
local InField = Tabs.Fielding:AddRightGroupbox("inFiled")

OutField:AddToggle("TeleportBallEndPosition", {
    Text = "Teleport Ball end position",
    Default = false,
})
OutField:AddToggle("ShowStrikebox", {
    Text = "show Strikebox",
    Default = false,
})
OutField:AddOptionButton("CustomBat", {
    Text = "custom Bat",
    Values = { "Neon", "Wood", "Chrome" },
    Default = "Neon",
})

InField:AddToggle("AutoPitch", {
    Text = "Auto Pitch",
    Default = false,
})
InField:AddSlider("PitchPower", {
    Text = "Pitch Power",
    Min = 0,
    Max = 1,
    Step = 0.025,
    Decimals = 3,
    Default = 0.375,
})
InField:AddToggle("AutoTagRunners", {
    Text = "Auto Tag Runners",
    Default = false,
})

local Catcher = Tabs.Misc:AddLeftGroupbox("Catcher")
local Showcase = Tabs.Misc:AddRightGroupbox("Showcase")

Catcher:AddToggle("BlockBattersView", {
    Text = "Block Batters View",
    Default = false,
})
Catcher:AddSlider("InfrontOffset", {
    Text = "Infront Offset",
    Min = 0,
    Max = 2,
    Step = 0.1,
    Decimals = 1,
    Default = 1,
})
Catcher:AddSlider("BlockDuration", {
    Text = "Block Duration",
    Min = 0,
    Max = 1,
    Step = 0.1,
    Decimals = 1,
    Default = 0.5,
})

Showcase:AddRadioGroup("Mode", {
    Options = { "Legit", "Rage", "Hybrid" },
    Default = "Legit",
})
Showcase:AddProgressBar("Sync", {
    Default = 72,
    Save = false,
})
Showcase:AddSearchBox("Search", {
    Placeholder = "Filter features",
    Save = false,
    Callback = function(text)
        print("Search:", text)
    end,
})

local MediaTabbox = Tabs.Misc:AddRightTabbox()
local TabOne = MediaTabbox:AddTab("Tab 1")
TabOne:AddToggle("Tab1Toggle", { Text = "Tab1 Toggle" })
local TabTwo = MediaTabbox:AddTab("Tab 2")
TabTwo:AddToggle("Tab2Toggle", { Text = "Tab2 Toggle" })

local Walk = Tabs.Player:AddLeftGroupbox("Walk")
local Jump = Tabs.Player:AddRightGroupbox("Jump")

Walk:AddToggle("EnableWalkTP", {
    Text = "Enable Walk TP",
    Default = false,
})
Walk:AddSlider("WalkTPInterval", {
    Text = "Walk TP interval",
    Min = 0,
    Max = 5,
    Step = 0.1,
    Decimals = 1,
    Default = 1,
})
Walk:AddLabel("Walk Key")
    :AddKeyPicker("WalkTPBind", {
        Default = { "Q", "Toggle" },
        Text = "Walk TP bind",
    })

Jump:AddToggle("EnableSuperJump", {
    Text = "Enable Super Jump",
    Default = false,
})
Jump:AddSlider("JumpPower", {
    Text = "Jump Power",
    Min = 0,
    Max = 100,
    Step = 1,
    Default = 50,
})
Jump:AddKeybind("JumpBind", {
    Text = "Jump Bind",
    Default = { "V", "Hold" },
})

Tabs.Key:AddLabel({
    Text = "Enter the key: Banana",
    DoesWrap = true,
    Size = 14,
})
Tabs.Key:AddKeyBox(function(receivedKey)
    Library:Notify({
        Title = "Key System",
        Description = string.format("Received key: %s", tostring(receivedKey)),
        Type = receivedKey == "Banana" and "Success" or "Warning",
        Duration = 3,
    })
end)

local Menu = Tabs.Setting:AddLeftGroupbox("Menu")
local Behavior = Tabs.Setting:AddRightGroupbox("Behavior")

Menu:AddDropdown("NotificationSide", {
    Text = "Notification Side",
    Values = { "Right", "Left" },
    Default = "Right",
})
Menu:AddSlider("CornerRadius", {
    Text = "Corner Radius",
    Min = 6,
    Max = 16,
    Step = 1,
    Default = 12,
    Save = false,
})
Menu:AddLabel("Menu bind")
    :AddKeyPicker("MenuKeybind", {
        Default = { "RightShift", "Toggle" },
        Save = false,
        Text = "Menu keybind",
    })
Menu:AddButton({
    Text = "Unload",
    Func = function()
        Library:Unload()
    end,
})

Behavior:AddInput("StatusText", {
    Text = "Status Text",
    Default = "Kojo loaded",
    Callback = function(value)
        print("Status:", value)
    end,
})
Behavior:AddColorPicker("AccentPreview", {
    Text = "Accent Preview",
    Default = Color3.fromRGB(186, 147, 255),
    Save = false,
    Callback = function(color)
        Library:SetTheme({ Accent = color })
    end,
})
Behavior:AddButton({
    Text = "Notify",
    Func = function()
        Library:Notify({
            Title = "Kojo Hub",
            Description = "Notification test fired from example.",
            Type = "Info",
            Duration = 3,
        })
    end,
})

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind", "StatusText" })
ThemeManager:SetFolder("KojoHub")
SaveManager:SetFolder("KojoHub")
SaveManager:SetSubFolder("universal")
SaveManager:BuildConfigSection(Tabs.Setting)
ThemeManager:ApplyToTab(Tabs.Setting)
SaveManager:LoadAutoloadConfig()

Toggles.AutoAim:OnChanged(function(value)
    print("AutoAim changed:", value)
end)

Options.TimeAdjustment:OnChanged(function(value)
    print("TimeAdjustment:", value)
end)

Options.QuitOnBase:SetValue("2nd")
Toggles.BallEsp:SetValue(true)

Library:AddDraggableLabel("Kojo Drag Label")
Library:OnUnload(function()
    print("Kojo unloaded")
end)

Library:Notify({
    Title = "Kojo Hub",
    Description = "Example booted from GitHub raw.",
    Type = "Success",
    Duration = 4,
})
