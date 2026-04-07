--[[
    KojoLib — A Premium Roblox UI Library
    Version: 3.0.0
    Visual: Kojo/Aikeo dark matte design
    API: Obsidian/Linoria-grade developer experience

    Usage:
        local Library = loadstring(game:HttpGet("..."))()
        local Window = Library:CreateWindow({ Title = "Kojo Hub" })
        local Tab = Window:AddTab("Main")
        local Section = Tab:AddLeftGroupbox("Features")
        Section:AddToggle("MyToggle", { Text = "Enable", Callback = function(v) end })

    Phase 1: Foundation + Theme Engine
--]]

-- ================================================================
-- SERVICES
-- ================================================================

local RunService      = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local Players         = game:GetService("Players")
local HttpService     = game:GetService("HttpService")
local CoreGui         = game:GetService("CoreGui")
local TextService     = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer and LocalPlayer:GetMouse() or nil

-- ================================================================
-- LIBRARY OBJECT
-- ================================================================

local Library = {}
Library.__index = Library

Library.Name    = "Kojo"
Library.Version = "3.0.0"

-- State
Library._gui              = nil       -- ScreenGui root
Library._windows          = {}        -- window instances
Library._controlRegistry  = {}        -- flag → control mapping
Library._sectionExtensions = {}       -- extended section methods
Library._extendedModules  = {}        -- loaded extension modules
Library._themedObjects    = {}        -- objects to update on theme change
Library._unloadCallbacks  = {}        -- cleanup callbacks
Library._connections      = {}        -- RBXScriptConnections to disconnect on unload

Library.Extended = {}

-- Public registries (Obsidian-compatible)
Library.Options = {}   -- non-boolean controls (sliders, dropdowns, inputs, etc.)
Library.Toggles = {}   -- boolean controls (toggles, checkboxes)
Library.Flags   = {}   -- all flags combined (alias into Options/Toggles)

-- Settings
Library._toggleKey             = Enum.KeyCode.RightShift
Library.ForceCheckbox          = false
Library.ShowToggleFrameInKeybinds = true
Library.ShowCustomCursor       = false
Library.Unloaded               = false

-- ================================================================
-- GUI CONTAINER (executor compatibility)
-- ================================================================

local function GetGuiContainer()
    -- gethui: universal exploit API
    local ok1, result1 = pcall(function()
        if gethui then return gethui() end
        return nil
    end)
    if ok1 and result1 then return result1 end

    -- CoreGui fallback
    local ok2, result2 = pcall(function()
        return CoreGui
    end)
    if ok2 and result2 then return result2 end

    -- PlayerGui last resort
    if LocalPlayer then
        return LocalPlayer:WaitForChild("PlayerGui")
    end
    return nil
end

-- ================================================================
-- FONT CONSTANTS
-- ================================================================

local Font = {
    Regular  = Enum.Font.GothamMedium,
    Bold     = Enum.Font.GothamBold,
    SemiBold = Enum.Font.GothamSemibold,
    Mono     = Enum.Font.Code,
}

-- ================================================================
-- THEME ENGINE
-- ================================================================

--[[
    Theme structure: 5 base colors per preset.
    All derived colors (sidebar bg, groupbox bg, etc.) are computed
    from these 5 + hardcoded offsets to match the CSS reference.

    Keys: FontColor, MainColor, AccentColor, BackgroundColor, OutlineColor
    Values: hex strings WITHOUT the # prefix
--]]

local ThemePresets = {
    Default        = { FontColor = "ffffff", MainColor = "0d0d10", AccentColor = "9464dc", BackgroundColor = "060608", OutlineColor = "1a1a22" },
    Sakura         = { FontColor = "fef0f5", MainColor = "1a0a10", AccentColor = "ff6b9d", BackgroundColor = "0e0508", OutlineColor = "2d1220" },
    ["Midnight Anime"] = { FontColor = "e0d4f5", MainColor = "100e18", AccentColor = "9b59b6", BackgroundColor = "080610", OutlineColor = "1e1830" },
    ["Neon Tokyo"] = { FontColor = "e0f7fa", MainColor = "07090d", AccentColor = "00e5ff", BackgroundColor = "030507", OutlineColor = "0f1820" },
    ["Rose Gold"]  = { FontColor = "fff5f5", MainColor = "120b0e", AccentColor = "e8a87c", BackgroundColor = "090608", OutlineColor = "221318" },
    ["Ocean Breeze"] = { FontColor = "e3f2fd", MainColor = "081018", AccentColor = "48cae4", BackgroundColor = "040810", OutlineColor = "102030" },
    ["Violet Dream"] = { FontColor = "f3e5f5", MainColor = "100820", AccentColor = "ce93d8", BackgroundColor = "080414", OutlineColor = "1e1030" },
    Emerald        = { FontColor = "e8f5e9", MainColor = "051008", AccentColor = "4caf50", BackgroundColor = "030804", OutlineColor = "102018" },
    ["Blood Moon"] = { FontColor = "ffebee", MainColor = "0f0505", AccentColor = "e53935", BackgroundColor = "080303", OutlineColor = "220c0c" },
    Catppuccin     = { FontColor = "d9e0ee", MainColor = "1a1826", AccentColor = "f5c2e7", BackgroundColor = "0f0e18", OutlineColor = "302d41" },
    Dracula        = { FontColor = "f8f8f2", MainColor = "1a1c24", AccentColor = "ff79c6", BackgroundColor = "10121a", OutlineColor = "282a36" },
    Cyberpunk      = { FontColor = "f9f9f9", MainColor = "0e0d18", AccentColor = "00ff9f", BackgroundColor = "080810", OutlineColor = "1e1c2e" },
    Sunset         = { FontColor = "fff8e1", MainColor = "0f0805", AccentColor = "ff9800", BackgroundColor = "080503", OutlineColor = "201408" },
    Phantom        = { FontColor = "cfd8dc", MainColor = "0c0c0c", AccentColor = "78909c", BackgroundColor = "080808", OutlineColor = "1a1a1a" },
}

-- Active theme state
local _activePresetName = "Default"
local _customOverrides  = {}   -- user color overrides: { AccentColor = "ff0000", ... }

-- Derived color cache (rebuilt on theme change)
local Theme = {}

-- Helper: hex string → Color3
local function HexToColor3(hex)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1, 2), 16) or 0
    local g = tonumber(hex:sub(3, 4), 16) or 0
    local b = tonumber(hex:sub(5, 6), 16) or 0
    return Color3.fromRGB(r, g, b)
end

-- Helper: Color3 → hex string (no #)
local function Color3ToHex(c)
    return string.format("%02x%02x%02x", 
        math.floor(c.R * 255 + 0.5),
        math.floor(c.G * 255 + 0.5),
        math.floor(c.B * 255 + 0.5)
    )
end

-- Helper: lighten/darken a Color3 by factor
local function AdjustBrightness(color, factor)
    return Color3.new(
        math.clamp(color.R * factor, 0, 1),
        math.clamp(color.G * factor, 0, 1),
        math.clamp(color.B * factor, 0, 1)
    )
end

-- Helper: mix two Color3 values
local function MixColors(a, b, t)
    return Color3.new(
        a.R + (b.R - a.R) * t,
        a.G + (b.G - a.G) * t,
        a.B + (b.B - a.B) * t
    )
end

-- Helper: get a color with alpha transparency applied over black background
-- (Roblox doesn't have alpha, so we simulate accent+"20" by mixing with bg)
local function AccentAlpha(accentColor, bgColor, alpha)
    return MixColors(bgColor, accentColor, alpha)
end

-- Resolve the 5 base theme colors (preset + overrides)
local function ResolveBaseColors()
    local preset = ThemePresets[_activePresetName] or ThemePresets["Default"]
    local base = {}
    for _, key in ipairs({"FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor"}) do
        local hex = _customOverrides[key] or preset[key]
        base[key] = HexToColor3(hex)
        base[key .. "Hex"] = hex
    end
    return base
end

-- Build the full derived Theme table from the 5 base colors
-- These match the CSS reference exactly
local function BuildTheme()
    local base = ResolveBaseColors()

    local accent = base.AccentColor
    local bg     = base.BackgroundColor
    local main   = base.MainColor
    local outline = base.OutlineColor
    local font   = base.FontColor

    -- Store base hex for serialization
    Theme._baseHex = {
        FontColor       = base.FontColorHex,
        MainColor       = base.MainColorHex,
        AccentColor     = base.AccentColorHex,
        BackgroundColor = base.BackgroundColorHex,
        OutlineColor    = base.OutlineColorHex,
    }

    -- ── Window ──
    Theme.Background       = bg                              -- #060608
    Theme.WindowBorder     = outline                          -- #1a1a22

    -- ── Sidebar ──
    Theme.SidebarBg        = HexToColor3("02010a")            -- near-black
    Theme.SidebarIconInactive = HexToColor3("28263a")
    Theme.SidebarIconHover = HexToColor3("5a5875")
    Theme.SidebarIconActive = accent
    Theme.SidebarBtnActiveBg = AccentAlpha(accent, HexToColor3("02010a"), 0.125)  -- accent+"20"
    Theme.SidebarBtnActiveBorder = AccentAlpha(accent, HexToColor3("02010a"), 0.25) -- accent+"40"
    Theme.SidebarHintText  = HexToColor3("14122a")

    -- ── Titlebar / Header ──
    Theme.HeaderBg         = HexToColor3("02010a")
    Theme.BreadcrumbRoot   = HexToColor3("3a3858")
    Theme.BreadcrumbSep    = HexToColor3("18162a")
    Theme.BreadcrumbCategory = accent
    Theme.BreadcrumbTab    = HexToColor3("5a5875")

    -- ── Subtab bar ──
    Theme.SubtabBg         = HexToColor3("01000a")
    Theme.SubtabActive     = accent
    Theme.SubtabInactive   = HexToColor3("28263a")
    Theme.SubtabHover      = HexToColor3("5a5875")

    -- ── Groupbox ──
    Theme.GroupboxBg       = HexToColor3("06050e")
    Theme.GroupboxBorder   = HexToColor3("0e0d1a")
    Theme.GroupboxHeaderBorder = HexToColor3("0c0b16")
    Theme.GroupboxTitle    = HexToColor3("e8e4f6")

    -- ── Row / Labels ──
    Theme.RowLabelActive   = HexToColor3("e8e4f6")           -- textOn = true
    Theme.RowLabelNeutral  = HexToColor3("5a5875")           -- textOn = nil
    Theme.RowLabelOff      = HexToColor3("28263a")           -- textOn = false
    Theme.RowLabelDisabled = HexToColor3("1c1a2c")           -- disabled

    -- ── Separator / GroupLabel ──
    Theme.Separator        = HexToColor3("0c0b16")
    Theme.GroupLabelText   = HexToColor3("28263a")

    -- ── Toggle ──
    Theme.ToggleOffBg      = HexToColor3("0d0c18")
    Theme.ToggleOffBorder  = HexToColor3("1c1a2e")
    Theme.ToggleOffKnob    = HexToColor3("38365a")
    Theme.ToggleOnBg       = accent
    Theme.ToggleOnBorder   = accent
    Theme.ToggleOnKnob     = HexToColor3("f0ecfa")

    -- ── Slider ──
    Theme.SliderTrackBg    = HexToColor3("10101a")
    Theme.SliderFill       = accent
    Theme.SliderKnob       = HexToColor3("e8e4f6")
    Theme.SliderKnobBorder = accent
    Theme.SliderValueText  = HexToColor3("3c3a55")
    Theme.SliderEditBg     = HexToColor3("0a0918")

    -- ── Button ──
    Theme.ButtonDefaultBg     = HexToColor3("07060f")
    Theme.ButtonDefaultBorder = HexToColor3("18172a")
    Theme.ButtonPrimaryBg     = accent
    Theme.ButtonPrimaryBorder = accent
    Theme.ButtonDangerBg      = HexToColor3("3a0a0a")
    Theme.ButtonDangerBorder  = HexToColor3("6b1010")
    Theme.ButtonText          = HexToColor3("ddd8f0")

    -- ── Dropdown ──
    Theme.DropdownTriggerBg    = HexToColor3("07060f")
    Theme.DropdownTriggerBorder = AccentAlpha(accent, HexToColor3("07060f"), 0.25) -- accent+"40"
    Theme.DropdownPopupBg      = HexToColor3("04030b")
    Theme.DropdownPopupBorder  = AccentAlpha(accent, HexToColor3("04030b"), 0.19) -- accent+"30"
    Theme.DropdownArrow        = HexToColor3("2e2c3a")
    Theme.DropdownItemHover    = Color3.fromRGB(255, 255, 255) -- at 0.02 transparency
    Theme.DropdownSelectedBg   = AccentAlpha(accent, HexToColor3("04030b"), 0.094) -- accent+"18"

    -- ── Input / TextBox ──
    Theme.InputBg           = HexToColor3("07060f")
    Theme.InputBorder       = HexToColor3("18172a")
    Theme.InputBorderFocus  = accent
    Theme.InputText         = HexToColor3("ddd8f0")
    Theme.InputPlaceholder  = HexToColor3("28263a")

    -- ── Keybind ──
    Theme.KeybindBg         = HexToColor3("07060f")
    Theme.KeybindBorder     = HexToColor3("18172a")
    Theme.KeybindText       = HexToColor3("5a5875")
    Theme.KeybindListening  = accent

    -- ── ColorSwatch ──
    Theme.SwatchBorder      = AccentAlpha(accent, HexToColor3("07060f"), 0.31) -- accent+"50"

    -- ── OptionButton ──
    Theme.OptionBtnBg       = HexToColor3("07060f")
    Theme.OptionBtnBorder   = AccentAlpha(accent, HexToColor3("07060f"), 0.25)
    Theme.OptionBtnText     = accent

    -- ── Notification / Toast ──
    Theme.ToastBg           = HexToColor3("05040c")
    Theme.ToastBorder       = HexToColor3("10101e")
    Theme.NotifInfo         = HexToColor3("55afeb")
    Theme.NotifSuccess      = HexToColor3("50c878")
    Theme.NotifWarning      = HexToColor3("f0b43c")
    Theme.NotifError        = HexToColor3("dc4b4b")

    -- ── Loading ──
    Theme.LoadingBg         = HexToColor3("03020a")
    Theme.LoadingCardBg     = HexToColor3("050410")
    Theme.LoadingCardBorder = HexToColor3("0e0d1e")
    Theme.LoadingProgressBg = HexToColor3("0c0b18")
    Theme.LoadingProgressFill = accent
    Theme.LoadingSubtext    = HexToColor3("18162a")
    Theme.LoadingStepText   = HexToColor3("3a3858")
    Theme.LoadingVersion    = HexToColor3("1e1c2a")

    -- ── FPS / Watermark ──
    Theme.BadgeBg           = HexToColor3("03020a")
    Theme.BadgeBorder       = HexToColor3("0e0d1a")
    Theme.FPSGreen          = HexToColor3("50c878")
    Theme.FPSYellow         = HexToColor3("f0b43c")
    Theme.FPSRed            = HexToColor3("dc4b4b")
    Theme.WatermarkText     = accent

    -- ── Keybind Frame ──
    Theme.KeyframeBg        = HexToColor3("04030b")
    Theme.KeyframeLabel     = HexToColor3("5a5875")
    Theme.KeyframeTileBg    = HexToColor3("0d0c18")
    Theme.KeyframeTileBorder = AccentAlpha(accent, HexToColor3("0d0c18"), 0.25)
    Theme.KeyframeTileText  = accent

    -- ── Scrollbar ──
    Theme.ScrollBar         = HexToColor3("1a1828")

    -- ── Shadow ──
    Theme.Shadow            = Color3.fromRGB(0, 0, 0)

    -- ── Text hierarchy ──
    Theme.TextPrimary       = HexToColor3("e8e4f6")
    Theme.TextSecondary     = HexToColor3("5a5875")
    Theme.TextDisabled      = HexToColor3("28263a")
    Theme.TextAccent        = accent

    -- ── Accent reference ──
    Theme.Accent            = accent
    Theme.AccentLight       = AdjustBrightness(accent, 1.25)
    Theme.AccentDark        = AdjustBrightness(accent, 0.7)

    -- ── Close button ──
    Theme.CloseBtnDefault   = HexToColor3("2e2c3a")
    Theme.CloseBtnHover     = HexToColor3("ff5050")
end

-- Initial build
BuildTheme()

-- ================================================================
-- THEME PUBLIC API
-- ================================================================

function Library:GetTheme()
    return Theme
end

function Library:GetThemePresets()
    local names = {}
    for name in pairs(ThemePresets) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

function Library:GetActivePreset()
    return _activePresetName
end

function Library:SetTheme(themeOrOverrides)
    if type(themeOrOverrides) ~= "table" then return end

    -- If it has a known preset key, it's a full theme application
    -- Otherwise treat it as partial overrides
    for key, value in pairs(themeOrOverrides) do
        if key == "Preset" then
            if ThemePresets[value] then
                _activePresetName = value
                _customOverrides = {}
            end
        elseif key == "AccentColor" or key == "BackgroundColor" or key == "MainColor" or key == "OutlineColor" or key == "FontColor" then
            -- Accept Color3 or hex string
            if typeof(value) == "Color3" then
                _customOverrides[key] = Color3ToHex(value)
            elseif type(value) == "string" then
                _customOverrides[key] = value:gsub("#", "")
            end
        end
    end

    BuildTheme()
    self:_RefreshThemedObjects()
end

function Library:ApplyPreset(presetName)
    if ThemePresets[presetName] then
        _activePresetName = presetName
        _customOverrides = {}
        BuildTheme()
        self:_RefreshThemedObjects()
    end
end

-- Register an object+property to auto-update on theme changes
function Library:_TrackThemed(obj, property, themeKey)
    table.insert(self._themedObjects, {
        Object   = obj,
        Property = property,
        ThemeKey = themeKey,
    })
end

-- Refresh all tracked themed objects
function Library:_RefreshThemedObjects()
    local alive = {}
    for _, entry in ipairs(self._themedObjects) do
        local obj = entry.Object
        if typeof(obj) == "Instance" and obj.Parent then
            pcall(function()
                obj[entry.Property] = Theme[entry.ThemeKey]
            end)
            table.insert(alive, entry)
        end
    end
    self._themedObjects = alive
end

-- ================================================================
-- UTILITY FUNCTIONS
-- ================================================================

local function Create(class, props, children)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            obj[k] = v
        end
    end
    for _, child in pairs(children or {}) do
        child.Parent = obj
    end
    if props and props.Parent then
        obj.Parent = props.Parent
    end
    return obj
end

local function Tween(obj, info, goal, callback)
    local t = TweenService:Create(obj, info, goal)
    if callback then
        t.Completed:Connect(callback)
    end
    t:Play()
    return t
end

local function Lerp(a, b, t)
    return a + (b - a) * t
end

local function Round(n, dec)
    dec = dec or 0
    local factor = 10 ^ dec
    return math.floor(n * factor + 0.5) / factor
end

local function Clamp(v, mn, mx)
    return math.max(mn, math.min(mx, v))
end

-- ================================================================
-- GUI HELPER FUNCTIONS
-- ================================================================

local function MakeRounded(parent, radius)
    return Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 6),
        Parent = parent,
    })
end

local function MakeStroke(parent, color, thickness, transparency)
    return Create("UIStroke", {
        Color = color or Theme.WindowBorder,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function MakePadding(parent, top, bottom, left, right)
    return Create("UIPadding", {
        PaddingTop    = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft   = UDim.new(0, left or 0),
        PaddingRight  = UDim.new(0, right or 0),
        Parent = parent,
    })
end

local function MakeListLayout(parent, padding, direction, halign, valign)
    return Create("UIListLayout", {
        Padding = UDim.new(0, padding or 0),
        FillDirection = direction or Enum.FillDirection.Vertical,
        HorizontalAlignment = halign or Enum.HorizontalAlignment.Left,
        VerticalAlignment = valign or Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = parent,
    })
end

local function AddDropShadow(parent, size, transparency)
    size = size or 15
    transparency = transparency or 0.7
    return Create("ImageLabel", {
        Name = "DropShadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 4),
        Size = UDim2.new(1, size * 2, 1, size * 2),
        ZIndex = -1,
        Image = "rbxassetid://5554236805",
        ImageColor3 = Theme.Shadow,
        ImageTransparency = transparency,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        Parent = parent,
    })
end

-- Draggable with touch support
local function MakeDraggable(frame, dragHandle)
    dragHandle = dragHandle or frame
    local dragging = false
    local dragStart, startPos

    local function onInputStart(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end

    local function onInputEnd(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end

    local function onInputChanged(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end

    dragHandle.InputBegan:Connect(onInputStart)
    dragHandle.InputEnded:Connect(onInputEnd)
    UserInputService.InputChanged:Connect(onInputChanged)
end

-- Auto-resize frame height based on UIListLayout content
local function AutoSize(frame, layout, minHeight, extraPadding)
    extraPadding = extraPadding or 0
    local function update()
        local contentH = layout.AbsoluteContentSize.Y
        frame.Size = UDim2.new(
            frame.Size.X.Scale,
            frame.Size.X.Offset,
            0,
            math.max(minHeight or 0, contentH + extraPadding)
        )
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
    task.defer(update)
    return update
end

-- Check if a point is inside a GuiObject
local function PointInGui(guiObject, point)
    if not guiObject or not guiObject.Visible then return false end
    local pos = guiObject.AbsolutePosition
    local size = guiObject.AbsoluteSize
    return point.X >= pos.X
        and point.X <= pos.X + size.X
        and point.Y >= pos.Y
        and point.Y <= pos.Y + size.Y
end

-- ================================================================
-- KEYBIND HELPERS
-- ================================================================

local function NormalizeKeybindToken(token)
    if typeof(token) == "EnumItem" then return token end
    if type(token) == "string" then
        if token == "MB1" or token == "MB2" or token == "MB3" then return token end
        local ok, enum = pcall(function() return Enum.KeyCode[token] end)
        if ok and enum then return enum end
        local ok2, enum2 = pcall(function() return Enum.UserInputType[token] end)
        if ok2 and enum2 then return enum2 end
        return Enum.KeyCode.Unknown
    end
    return Enum.KeyCode.Unknown
end

local function GetInputToken(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        return input.KeyCode
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then return "MB1" end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then return "MB2" end
    if input.UserInputType == Enum.UserInputType.MouseButton3 then return "MB3" end
    return input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode or input.UserInputType
end

local function KeyTokenToDisplay(token)
    if typeof(token) == "EnumItem" then return token.Name end
    return tostring(token or "None")
end

-- ================================================================
-- FLAG / CONFIG SYSTEM
-- ================================================================

local function SanitizeFlag(value)
    value = tostring(value or "")
    value = value:gsub("[%c\r\n\t]", " ")
    value = value:gsub("%s+", "_")
    value = value:gsub("[^%w_%.%-]", "")
    return value
end

local function EncodeConfigValue(value)
    if typeof(value) == "Color3" then
        return { __type = "Color3", r = value.R, g = value.G, b = value.B }
    end
    if typeof(value) == "EnumItem" then
        return { __type = "EnumItem", enumType = tostring(value.EnumType), name = value.Name }
    end
    if type(value) == "table" then
        local encoded = {}
        for k, v in pairs(value) do
            encoded[k] = EncodeConfigValue(v)
        end
        return encoded
    end
    return value
end

local function DecodeConfigValue(value)
    if type(value) ~= "table" then return value end
    if value.__type == "Color3" then
        return Color3.new(value.r or 0, value.g or 0, value.b or 0)
    end
    if value.__type == "EnumItem" and value.enumType and value.name then
        local enumTypeName = tostring(value.enumType):match("^Enum%.(.+)$")
        local enumType = enumTypeName and Enum[enumTypeName]
        return enumType and enumType[value.name] or Enum.KeyCode[value.name] or value.name
    end
    local decoded = {}
    for k, v in pairs(value) do
        decoded[k] = DecodeConfigValue(v)
    end
    return decoded
end

function Library:_makeFlag(tabName, sectionName, label, explicitFlag)
    return SanitizeFlag(explicitFlag or string.format("%s.%s.%s", tabName or "Tab", sectionName or "Section", label or "Value"))
end

function Library:_registerControl(control)
    if not control or not control.Flag then return control end
    self._controlRegistry[control.Flag] = control
    return control
end

function Library:_snapshotControls(ignoreFlags)
    local snapshot = {}
    ignoreFlags = ignoreFlags or {}
    for flag, control in pairs(self._controlRegistry) do
        if control.Save ~= false and not ignoreFlags[flag] and control.GetValue then
            snapshot[flag] = EncodeConfigValue(control:GetValue())
        end
    end
    return snapshot
end

function Library:_applySnapshot(snapshot, ignoreFlags)
    ignoreFlags = ignoreFlags or {}
    for flag, encoded in pairs(snapshot or {}) do
        local control = self._controlRegistry[flag]
        if control and not ignoreFlags[flag] and control.SetValue then
            local ok, err = pcall(function()
                control:SetValue(DecodeConfigValue(encoded))
            end)
            if not ok then
                warn("[Kojo] Failed to apply config for flag:", flag, err)
            end
        end
    end
end

-- ================================================================
-- OBSERVABLE PATTERN
-- ================================================================

local function EnsureObservable(control)
    control._changedCallbacks = control._changedCallbacks or {}
    if not control.OnChanged then
        control.OnChanged = function(self, fn)
            if type(fn) == "function" then
                table.insert(self._changedCallbacks, fn)
            end
            return self
        end
    end
    return control
end

local function FireChanged(control, ...)
    if not control or not control._changedCallbacks then return end
    for _, fn in ipairs(control._changedCallbacks) do
        task.spawn(fn, ...)
    end
end

-- ================================================================
-- EXTENSION SYSTEM
-- ================================================================

function Library:UseExtended(extended)
    if type(extended) ~= "table" then return self end

    local sectionMethods = extended.SectionMethods or extended.Section or {}
    for name, method in pairs(sectionMethods) do
        if type(method) == "function" then
            self._sectionExtensions[name] = method
        end
    end

    self.Extended = self.Extended or {}
    for name, value in pairs(extended.Utilities or {}) do
        self.Extended[name] = value
    end
    for name, value in pairs(extended) do
        if name ~= "SectionMethods" and name ~= "Section" and name ~= "Utilities" then
            self.Extended[name] = value
        end
    end

    table.insert(self._extendedModules, extended)
    return self
end

function Library:_extendSection(sectionObj)
    for name, method in pairs(self._sectionExtensions) do
        if sectionObj[name] == nil then
            sectionObj[name] = function(self, ...)
                return method(self, ...)
            end
        end
    end
    return sectionObj
end

-- ================================================================
-- TOGGLE KEY
-- ================================================================

function Library:SetToggleKey(key)
    if typeof(key) == "EnumItem" then
        self._toggleKey = key
    elseif type(key) == "string" then
        self._toggleKey = NormalizeKeybindToken(key)
    end
end

-- ================================================================
-- UNLOAD / CLEANUP
-- ================================================================

function Library:OnUnload(callback)
    if type(callback) == "function" then
        table.insert(self._unloadCallbacks, callback)
    end
end

function Library:Unload()
    if self.Unloaded then return end
    self.Unloaded = true

    -- Fire callbacks
    for _, fn in ipairs(self._unloadCallbacks) do
        pcall(fn)
    end

    -- Disconnect connections
    for _, conn in ipairs(self._connections) do
        pcall(function() conn:Disconnect() end)
    end
    self._connections = {}

    -- Destroy GUI
    if self._gui then
        pcall(function() self._gui:Destroy() end)
        self._gui = nil
    end

    -- Clear registries
    self._controlRegistry = {}
    self._themedObjects = {}
    self.Options = {}
    self.Toggles = {}
    self.Flags = {}
end

function Library:Destroy()
    self:Unload()
end

-- ================================================================
-- INIT (creates ScreenGui container)
-- ================================================================

function Library:Init()
    if self._gui then return self end
    local container = GetGuiContainer()
    if not container then
        warn("[Kojo] Could not find GUI container")
        return self
    end
    local screenGui = Create("ScreenGui", {
        Name = "KojoLib_" .. HttpService:GenerateGUID(false):sub(1, 8),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100,
        IgnoreGuiInset = true,
        Parent = container,
    })
    self._gui = screenGui
    return self
end

-- ================================================================
-- SELF TEST (Phase 1 verification)
-- ================================================================

function Library:SelfTest()
    print("═══════════════════════════════════════════")
    print("  KojoLib Phase 1 — Self Test")
    print("═══════════════════════════════════════════")
    print(string.format("  Library: %s v%s", self.Name, self.Version))

    -- Test theme
    local preset = self:GetActivePreset()
    print(string.format("  Active Preset: %s", preset))
    print(string.format("  Accent Color: %s", Theme._baseHex.AccentColor))
    print(string.format("  Theme Keys: %d derived colors", (function()
        local n = 0
        for _ in pairs(Theme) do n = n + 1 end
        return n
    end)()))

    -- Test all presets load
    local presets = self:GetThemePresets()
    print(string.format("  Theme Presets: %d loaded", #presets))
    local allOk = true
    for _, name in ipairs(presets) do
        self:ApplyPreset(name)
        if not Theme.Accent then
            print(string.format("    ✗ %s — FAILED", name))
            allOk = false
        end
    end
    self:ApplyPreset("Default") -- reset
    if allOk then
        print("    ✓ All presets load correctly")
    end

    -- Test custom override
    self:SetTheme({ AccentColor = "ff0000" })
    local isRed = Theme.Accent.R > 0.9 and Theme.Accent.G < 0.1
    print(string.format("  Custom Override: %s", isRed and "✓ works" or "✗ FAILED"))
    self:SetTheme({ Preset = "Default" }) -- reset

    -- Test GUI container
    self:Init()
    local guiOk = self._gui ~= nil and self._gui:IsA("ScreenGui")
    print(string.format("  GUI Container: %s", guiOk and "✓ created" or "✗ FAILED"))

    -- Test flag system
    local testControl = EnsureObservable({
        Flag = "TestFlag",
        Value = true,
        Save = true,
        GetValue = function(self) return self.Value end,
        SetValue = function(self, v) self.Value = v end,
    })
    self:_registerControl(testControl)
    local snapshot = self:_snapshotControls()
    local snapOk = snapshot["TestFlag"] == true
    print(string.format("  Flag System: %s", snapOk and "✓ works" or "✗ FAILED"))

    -- Test encode/decode
    local encoded = EncodeConfigValue(Color3.fromRGB(148, 100, 220))
    local decoded = DecodeConfigValue(encoded)
    local encOk = typeof(decoded) == "Color3" and math.abs(decoded.R - 148/255) < 0.01
    print(string.format("  Config Encode/Decode: %s", encOk and "✓ works" or "✗ FAILED"))

    -- Show visual proof
    self:_ShowTestVisual()

    -- Cleanup test control
    self._controlRegistry["TestFlag"] = nil

    print("═══════════════════════════════════════════")
    print("  Phase 1 complete. Ready for Phase 2.")
    print("═══════════════════════════════════════════")
end

function Library:_ShowTestVisual()
    if not self._gui then return end

    -- Small card showing theme colors — proves rendering works
    local card = Create("Frame", {
        Name = "Phase1Test",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.GroupboxBg,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 300, 0, 200),
        Parent = self._gui,
    })
    MakeRounded(card, 10)
    MakeStroke(card, Theme.WindowBorder, 1)
    AddDropShadow(card, 20, 0.5)

    -- Title
    Create("TextLabel", {
        Text = "KojoLib v" .. self.Version .. " — Phase 1 ✓",
        Font = Font.Bold,
        TextSize = 14,
        TextColor3 = Theme.TextPrimary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 12),
        Parent = card,
    })

    -- Theme color swatches
    local swatchY = 50
    local presets = {"Default", "Sakura", "Neon Tokyo", "Dracula", "Cyberpunk", "Blood Moon"}
    for i, name in ipairs(presets) do
        local p = ThemePresets[name]
        if p then
            local y = swatchY + (i - 1) * 22
            -- Accent swatch
            Create("Frame", {
                BackgroundColor3 = HexToColor3(p.AccentColor),
                Position = UDim2.new(0, 16, 0, y),
                Size = UDim2.new(0, 14, 0, 14),
                Parent = card,
            })
            MakeRounded(card:FindFirstChild("") or Create("UICorner", {
                CornerRadius = UDim.new(0, 3),
                Parent = card:GetChildren()[#card:GetChildren()],
            }), 3)
            -- Label
            Create("TextLabel", {
                Text = name,
                Font = Font.Regular,
                TextSize = 11,
                TextColor3 = Theme.TextSecondary,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 38, 0, y),
                Size = UDim2.new(0, 100, 0, 14),
                Parent = card,
            })
            -- Bg swatch
            Create("Frame", {
                BackgroundColor3 = HexToColor3(p.BackgroundColor),
                Position = UDim2.new(0, 150, 0, y),
                Size = UDim2.new(0, 14, 0, 14),
                Parent = card,
            })
            -- Outline swatch
            Create("Frame", {
                BackgroundColor3 = HexToColor3(p.OutlineColor),
                Position = UDim2.new(0, 170, 0, y),
                Size = UDim2.new(0, 14, 0, 14),
                Parent = card,
            })
        end
    end

    -- Auto-remove after 10 seconds
    task.delay(10, function()
        if card and card.Parent then
            card:Destroy()
        end
    end)
end

-- ================================================================
-- EXPOSE UTILITIES (for SaveManager/ThemeManager/Extensions)
-- ================================================================

Library.Tween       = Tween
Library.Create      = Create
Library.MakeRounded = MakeRounded
Library.MakeStroke  = MakeStroke
Library.MakePadding = MakePadding
Library.Round       = Round
Library.Clamp       = Clamp
Library.HexToColor3 = HexToColor3
Library.Color3ToHex = Color3ToHex
Library.Font        = Font

Library.EncodeConfigValue = EncodeConfigValue
Library.DecodeConfigValue = DecodeConfigValue
Library.SanitizeFlag      = SanitizeFlag
Library.NormalizeKeybindToken = NormalizeKeybindToken
Library.GetInputToken     = GetInputToken
Library.KeyTokenToDisplay = KeyTokenToDisplay
Library.EnsureObservable  = EnsureObservable
Library.FireChanged       = FireChanged
Library.AutoSize          = AutoSize
Library.PointInGui        = PointInGui
Library.MakeDraggable     = MakeDraggable
Library.AddDropShadow     = AddDropShadow
Library.MakeListLayout    = MakeListLayout

Library.ThemePresets = ThemePresets

-- Theme getter (returns current derived theme table)
function Library.Theme()
    return Theme
end

return Library
