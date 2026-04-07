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
-- WINDOW SYSTEM (Phase 2 — fixed Roblox rendering)
-- ================================================================

local WindowClass = {}
WindowClass.__index = WindowClass
local TabClass = {}
TabClass.__index = TabClass

function Library:CreateWindow(options)
    options = options or {}
    local title  = options.Title or "Kojo Hub"
    local width  = options.Width or 760
    local height = options.Height or 560
    local icon   = options.Icon or nil

    if not self._gui then self:Init() end
    local gui = self._gui

    -- ═══ Outer window: UICorner + ClipsDescendants = all children auto-clipped ═══
    local win = Instance.new("Frame")
    win.Name = "Window"
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    win.Position = UDim2.new(0.5, 0, 0.5, 0)
    win.Size = UDim2.new(0, width, 0, height)
    win.BackgroundColor3 = Theme.Background
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.Parent = gui
    MakeRounded(win, 10)
    MakeStroke(win, Theme.WindowBorder, 1)

    -- ═══ SIDEBAR (flat frame, clipped by parent) ═══
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 46, 1, 0)
    sidebar.Position = UDim2.new(0, 0, 0, 0)
    sidebar.BackgroundColor3 = HexToColor3("02010a")
    sidebar.BorderSizePixel = 0
    sidebar.Parent = win

    -- Sidebar right border (1px line)
    local sbBorder = Instance.new("Frame")
    sbBorder.Size = UDim2.new(0, 1, 1, 0)
    sbBorder.Position = UDim2.new(1, 0, 0, 0)
    sbBorder.BackgroundColor3 = Theme.WindowBorder
    sbBorder.BorderSizePixel = 0
    sbBorder.Parent = sidebar

    -- Logo area (top 40px of sidebar)
    local logoArea = Instance.new("Frame")
    logoArea.Size = UDim2.new(1, 0, 0, 40)
    logoArea.BackgroundTransparency = 1
    logoArea.BorderSizePixel = 0
    logoArea.Parent = sidebar

    local logoImg = Instance.new("ImageLabel")
    logoImg.AnchorPoint = Vector2.new(0.5, 0.5)
    logoImg.Position = UDim2.new(0.5, 0, 0.5, 0)
    logoImg.Size = UDim2.new(0, 22, 0, 22)
    logoImg.BackgroundTransparency = 1
    logoImg.Image = icon or "rbxassetid://4483362458"
    logoImg.ImageColor3 = Theme.Accent
    logoImg.Parent = logoArea

    -- Logo bottom border
    local logoBorder = Instance.new("Frame")
    logoBorder.Size = UDim2.new(1, 0, 0, 1)
    logoBorder.Position = UDim2.new(0, 0, 1, -1)
    logoBorder.BackgroundColor3 = Theme.WindowBorder
    logoBorder.BorderSizePixel = 0
    logoBorder.Parent = logoArea

    -- Category buttons container
    local catFrame = Instance.new("Frame")
    catFrame.Name = "Categories"
    catFrame.Size = UDim2.new(1, 0, 1, -64)
    catFrame.Position = UDim2.new(0, 0, 0, 40)
    catFrame.BackgroundTransparency = 1
    catFrame.BorderSizePixel = 0
    catFrame.Parent = sidebar
    MakeListLayout(catFrame, 4, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center)
    MakePadding(catFrame, 8, 0, 0, 0)

    -- Bottom hint
    local hint = Instance.new("TextLabel")
    hint.AnchorPoint = Vector2.new(0.5, 1)
    hint.Position = UDim2.new(0.5, 0, 1, -4)
    hint.Size = UDim2.new(0, 30, 0, 16)
    hint.Text = "⌨"
    hint.Font = Font.Regular
    hint.TextSize = 9
    hint.TextColor3 = HexToColor3("14122a")
    hint.BackgroundTransparency = 1
    hint.Parent = sidebar

    -- ═══ TITLEBAR (right of sidebar, 40px tall) ═══
    local titlebar = Instance.new("Frame")
    titlebar.Name = "Titlebar"
    titlebar.Size = UDim2.new(1, -47, 0, 40)
    titlebar.Position = UDim2.new(0, 47, 0, 0)
    titlebar.BackgroundColor3 = HexToColor3("02010a")
    titlebar.BorderSizePixel = 0
    titlebar.Parent = win

    -- Titlebar bottom border
    local tbBorder = Instance.new("Frame")
    tbBorder.Size = UDim2.new(1, 0, 0, 1)
    tbBorder.Position = UDim2.new(0, 0, 1, -1)
    tbBorder.BackgroundColor3 = Theme.WindowBorder
    tbBorder.BorderSizePixel = 0
    tbBorder.Parent = titlebar

    -- Breadcrumb
    local bcFrame = Instance.new("Frame")
    bcFrame.Size = UDim2.new(0.55, 0, 1, 0)
    bcFrame.Position = UDim2.new(0, 10, 0, 0)
    bcFrame.BackgroundTransparency = 1
    bcFrame.Parent = titlebar
    MakeListLayout(bcFrame, 5, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local function bcLabel(text, color, font)
        local l = Instance.new("TextLabel")
        l.Text = text
        l.Font = font or Font.SemiBold
        l.TextSize = 11
        l.TextColor3 = color
        l.BackgroundTransparency = 1
        l.Size = UDim2.new(0, 0, 1, 0)
        l.AutomaticSize = Enum.AutomaticSize.X
        l.Parent = bcFrame
        return l
    end

    local bcRoot = bcLabel(title, HexToColor3("3a3858"), Font.SemiBold)
    local bcS1 = bcLabel("›", HexToColor3("18162a"), Font.Regular)
    local bcCat = bcLabel("", Theme.Accent, Font.Bold)
    local bcS2 = bcLabel("›", HexToColor3("18162a"), Font.Regular)
    local bcTab = bcLabel("", HexToColor3("5a5875"), Font.Regular)

    -- Right side: FPS + Watermark + Close
    local rightFrame = Instance.new("Frame")
    rightFrame.AnchorPoint = Vector2.new(1, 0.5)
    rightFrame.Position = UDim2.new(1, -6, 0.5, 0)
    rightFrame.Size = UDim2.new(0, 220, 0, 24)
    rightFrame.BackgroundTransparency = 1
    rightFrame.Parent = titlebar
    MakeListLayout(rightFrame, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)

    -- FPS badge
    local fpsBg = Instance.new("Frame")
    fpsBg.Size = UDim2.new(0, 68, 0, 20)
    fpsBg.BackgroundColor3 = HexToColor3("03020a")
    fpsBg.BorderSizePixel = 0
    fpsBg.Parent = rightFrame
    MakeRounded(fpsBg, 4)
    MakeStroke(fpsBg, HexToColor3("0e0d1a"), 1)

    local fpsDot = Instance.new("Frame")
    fpsDot.Size = UDim2.new(0, 5, 0, 5)
    fpsDot.Position = UDim2.new(0, 6, 0.5, -2)
    fpsDot.BackgroundColor3 = Theme.FPSGreen
    fpsDot.BorderSizePixel = 0
    fpsDot.Parent = fpsBg
    MakeRounded(fpsDot, 99)

    local fpsText = Instance.new("TextLabel")
    fpsText.Size = UDim2.new(1, -16, 1, 0)
    fpsText.Position = UDim2.new(0, 14, 0, 0)
    fpsText.Text = "FPS: 60"
    fpsText.Font = Font.Mono
    fpsText.TextSize = 10
    fpsText.TextColor3 = Theme.FPSGreen
    fpsText.TextXAlignment = Enum.TextXAlignment.Left
    fpsText.BackgroundTransparency = 1
    fpsText.Parent = fpsBg

    -- Watermark
    local wmBg = Instance.new("Frame")
    wmBg.Size = UDim2.new(0, 72, 0, 20)
    wmBg.BackgroundColor3 = HexToColor3("03020a")
    wmBg.BorderSizePixel = 0
    wmBg.Parent = rightFrame
    MakeRounded(wmBg, 4)
    MakeStroke(wmBg, HexToColor3("0e0d1a"), 1)

    local wmText = Instance.new("TextLabel")
    wmText.Size = UDim2.new(1, 0, 1, 0)
    wmText.Text = "Kojo v3.0"
    wmText.Font = Font.Bold
    wmText.TextSize = 10
    wmText.TextColor3 = Theme.Accent
    wmText.BackgroundTransparency = 1
    wmText.Parent = wmBg

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Text = "×"
    closeBtn.Font = Font.Bold
    closeBtn.TextSize = 18
    closeBtn.TextColor3 = HexToColor3("2e2c3a")
    closeBtn.BackgroundTransparency = 1
    closeBtn.Parent = rightFrame
    closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = HexToColor3("ff5050") end)
    closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = HexToColor3("2e2c3a") end)

    -- ═══ SUBTAB BAR (34px, below titlebar) ═══
    local subtabBar = Instance.new("Frame")
    subtabBar.Name = "SubtabBar"
    subtabBar.Size = UDim2.new(1, -47, 0, 34)
    subtabBar.Position = UDim2.new(0, 47, 0, 40)
    subtabBar.BackgroundColor3 = HexToColor3("01000a")
    subtabBar.BorderSizePixel = 0
    subtabBar.Parent = win

    local stBorder = Instance.new("Frame")
    stBorder.Size = UDim2.new(1, 0, 0, 1)
    stBorder.Position = UDim2.new(0, 0, 1, -1)
    stBorder.BackgroundColor3 = Theme.WindowBorder
    stBorder.BorderSizePixel = 0
    stBorder.Parent = subtabBar

    local stContainer = Instance.new("Frame")
    stContainer.Size = UDim2.new(1, 0, 1, -1)
    stContainer.Position = UDim2.new(0, 6, 0, 0)
    stContainer.BackgroundTransparency = 1
    stContainer.Parent = subtabBar
    MakeListLayout(stContainer, 0, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)

    -- ═══ CONTENT AREA (scrollable, below subtab bar) ═══
    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -47, 1, -74)
    content.Position = UDim2.new(0, 47, 0, 74)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = HexToColor3("1a1828")
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
    content.ScrollingDirection = Enum.ScrollingDirection.Y
    content.Parent = win
    MakePadding(content, 8, 8, 8, 8)

    -- Draggable
    MakeDraggable(win, titlebar)

    -- ═══ Window object ═══
    local wObj = setmetatable({}, WindowClass)
    wObj._frame = win
    wObj._catFrame = catFrame
    wObj._stContainer = stContainer
    wObj._content = content
    wObj._bcCat = bcCat
    wObj._bcTab = bcTab
    wObj._fpsText = fpsText
    wObj._fpsDot = fpsDot
    wObj._library = self
    wObj._title = title
    wObj._width = width
    wObj._height = height
    wObj._categories = {}
    wObj._activeCategory = nil
    wObj._tabObjects = {}
    wObj.Tabs = {}

    closeBtn.MouseButton1Click:Connect(function() wObj:Hide() end)

    -- FPS counter
    local fpsCnt, fpsT = 0, tick()
    local fpsConn = RunService.Heartbeat:Connect(function()
        fpsCnt = fpsCnt + 1
        local now = tick()
        if now - fpsT >= 1 then
            local fps = math.floor(fpsCnt / (now - fpsT))
            fpsText.Text = "FPS: " .. fps
            local c = fps >= 50 and Theme.FPSGreen or fps >= 30 and Theme.FPSYellow or Theme.FPSRed
            fpsText.TextColor3 = c
            fpsDot.BackgroundColor3 = c
            fpsCnt = 0
            fpsT = now
        end
    end)
    table.insert(self._connections, fpsConn)

    -- Toggle key
    local tConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == self._toggleKey then wObj:Toggle() end
    end)
    table.insert(self._connections, tConn)
    table.insert(self._windows, wObj)

    -- ═══ Navigation methods ═══

    function wObj:_UpdateBreadcrumb()
        if self._activeCategory then
            bcCat.Text = self._activeCategory
            local cat = self._categories[self._activeCategory]
            if cat and cat.activeTab then
                bcTab.Text = cat.activeTab._name
            end
        end
    end

    function wObj:_SwitchCategory(name)
        if self._activeCategory == name then return end
        -- Deactivate old
        if self._activeCategory then
            local old = self._categories[self._activeCategory]
            if old then
                old.btn.BackgroundTransparency = 1
                old.icon.ImageColor3 = HexToColor3("28263a")
                if old.stroke then old.stroke.Transparency = 1 end
            end
        end
        self._activeCategory = name
        local cat = self._categories[name]
        if not cat then return end
        cat.btn.BackgroundColor3 = Theme.SidebarBtnActiveBg
        cat.btn.BackgroundTransparency = 0
        cat.icon.ImageColor3 = Theme.Accent
        if cat.stroke then cat.stroke.Transparency = 0 end
        self:_RebuildSubtabs(name)
        if not cat.activeTab and #cat.tabs > 0 then
            self:_SwitchTab(cat.tabs[1])
        elseif cat.activeTab then
            self:_SwitchTab(cat.activeTab)
        end
        self:_UpdateBreadcrumb()
    end

    function wObj:_RebuildSubtabs(catName)
        for _, c in pairs(stContainer:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        local cat = self._categories[catName]
        if not cat then return end
        for _, tabObj in ipairs(cat.tabs) do
            local isAct = cat.activeTab == tabObj
            local btn = Instance.new("TextButton")
            btn.Name = "ST_" .. tabObj._name
            btn.Text = tabObj._name
            btn.Font = isAct and Font.Bold or Font.Regular
            btn.TextSize = 11
            btn.TextColor3 = isAct and Theme.Accent or HexToColor3("28263a")
            btn.BackgroundTransparency = 1
            btn.Size = UDim2.new(0, 0, 1, 0)
            btn.AutomaticSize = Enum.AutomaticSize.X
            btn.Parent = stContainer
            MakePadding(btn, 0, 0, 12, 12)

            local uline = Instance.new("Frame")
            uline.Size = UDim2.new(1, 0, 0, 2)
            uline.Position = UDim2.new(0, 0, 1, -2)
            uline.BackgroundColor3 = Theme.Accent
            uline.BorderSizePixel = 0
            uline.Visible = isAct
            uline.Parent = btn

            btn.MouseEnter:Connect(function()
                if cat.activeTab ~= tabObj then btn.TextColor3 = HexToColor3("5a5875") end
            end)
            btn.MouseLeave:Connect(function()
                if cat.activeTab ~= tabObj then btn.TextColor3 = HexToColor3("28263a") end
            end)
            btn.MouseButton1Click:Connect(function() self:_SwitchTab(tabObj) end)
            tabObj._stBtn = btn
            tabObj._stLine = uline
        end
    end

    function wObj:_SwitchTab(tabObj)
        local cat = self._categories[tabObj._category]
        if not cat then return end
        for _, t in ipairs(cat.tabs) do
            t._frame.Visible = false
            if t._stBtn then
                t._stBtn.Font = Font.Regular
                t._stBtn.TextColor3 = HexToColor3("28263a")
                if t._stLine then t._stLine.Visible = false end
            end
        end
        tabObj._frame.Visible = true
        cat.activeTab = tabObj
        if tabObj._stBtn then
            tabObj._stBtn.Font = Font.Bold
            tabObj._stBtn.TextColor3 = Theme.Accent
            if tabObj._stLine then tabObj._stLine.Visible = true end
        end
        self:_UpdateBreadcrumb()
    end

    function wObj:AddTab(name, iconId)
        local catName = name
        iconId = iconId or "rbxassetid://7743878857"

        if not self._categories[catName] then
            local btn = Instance.new("TextButton")
            btn.Name = "Cat_" .. catName
            btn.Size = UDim2.new(0, 36, 0, 36)
            btn.BackgroundColor3 = Theme.SidebarBtnActiveBg
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.BorderSizePixel = 0
            btn.Parent = catFrame
            MakeRounded(btn, 8)
            local stroke = MakeStroke(btn, Theme.SidebarBtnActiveBorder, 1, 1)

            local ico = Instance.new("ImageLabel")
            ico.AnchorPoint = Vector2.new(0.5, 0.5)
            ico.Position = UDim2.new(0.5, 0, 0.5, 0)
            ico.Size = UDim2.new(0, 18, 0, 18)
            ico.BackgroundTransparency = 1
            ico.Image = iconId
            ico.ImageColor3 = HexToColor3("28263a")
            ico.Parent = btn

            btn.MouseEnter:Connect(function()
                if self._activeCategory ~= catName then
                    ico.ImageColor3 = HexToColor3("5a5875")
                end
            end)
            btn.MouseLeave:Connect(function()
                if self._activeCategory ~= catName then
                    ico.ImageColor3 = HexToColor3("28263a")
                end
            end)
            btn.MouseButton1Click:Connect(function()
                self:_SwitchCategory(catName)
            end)

            self._categories[catName] = { btn = btn, icon = ico, stroke = stroke, tabs = {}, activeTab = nil }
        end

        -- Tab content
        local tabFrame = Instance.new("Frame")
        tabFrame.Name = "Tab_" .. name
        tabFrame.Size = UDim2.new(1, 0, 0, 0)
        tabFrame.AutomaticSize = Enum.AutomaticSize.Y
        tabFrame.BackgroundTransparency = 1
        tabFrame.Visible = false
        tabFrame.Parent = content

        local colFrame = Instance.new("Frame")
        colFrame.Name = "Cols"
        colFrame.Size = UDim2.new(1, 0, 0, 0)
        colFrame.AutomaticSize = Enum.AutomaticSize.Y
        colFrame.BackgroundTransparency = 1
        colFrame.Parent = tabFrame
        MakeListLayout(colFrame, 8, Enum.FillDirection.Vertical)

        local tab = setmetatable({}, TabClass)
        tab._name = name
        tab._frame = tabFrame
        tab._cols = colFrame
        tab._category = catName
        tab._library = self
        tab._stBtn = nil
        tab._stLine = nil
        tab._sections = {}
        tab._curRow = nil

        local cat = self._categories[catName]
        table.insert(cat.tabs, tab)
        self.Tabs[name] = tab

        if not self._activeCategory then self:_SwitchCategory(catName) end
        return tab
    end

    function wObj:Toggle()
        if win.Visible then self:Hide() else self:Show() end
    end
    function wObj:Show()
        win.Visible = true
    end
    function wObj:Hide()
        win.Visible = false
    end

    -- ═══ Groupbox ═══
    function TabClass:AddLeftGroupbox(name) return self:_AddGB(name, "L") end
    function TabClass:AddRightGroupbox(name) return self:_AddGB(name, "R") end

    function TabClass:_AddGB(name, side)
        if side == "L" or not self._curRow then
            local row = Instance.new("Frame")
            row.Name = "GBRow"
            row.Size = UDim2.new(1, 0, 0, 0)
            row.AutomaticSize = Enum.AutomaticSize.Y
            row.BackgroundTransparency = 1
            row.Parent = self._cols
            MakeListLayout(row, 8, Enum.FillDirection.Horizontal)
            self._curRow = row
        end

        local gb = Instance.new("Frame")
        gb.Name = "GB_" .. name
        gb.Size = UDim2.new(0.5, -4, 0, 0)
        gb.AutomaticSize = Enum.AutomaticSize.Y
        gb.BackgroundColor3 = HexToColor3("06050e")
        gb.BorderSizePixel = 0
        gb.ClipsDescendants = true
        gb.Parent = self._curRow
        MakeRounded(gb, 8)
        MakeStroke(gb, HexToColor3("0e0d1a"), 1)

        -- Header
        local hdr = Instance.new("Frame")
        hdr.Size = UDim2.new(1, 0, 0, 32)
        hdr.BackgroundTransparency = 1
        hdr.Parent = gb

        local hdrText = Instance.new("TextLabel")
        hdrText.Size = UDim2.new(1, -24, 1, 0)
        hdrText.Position = UDim2.new(0, 12, 0, 0)
        hdrText.Text = name
        hdrText.Font = Font.Bold
        hdrText.TextSize = 12
        hdrText.TextColor3 = HexToColor3("e8e4f6")
        hdrText.TextXAlignment = Enum.TextXAlignment.Left
        hdrText.BackgroundTransparency = 1
        hdrText.Parent = hdr

        local hdrLine = Instance.new("Frame")
        hdrLine.Size = UDim2.new(1, 0, 0, 1)
        hdrLine.Position = UDim2.new(0, 0, 1, -1)
        hdrLine.BackgroundColor3 = HexToColor3("0c0b16")
        hdrLine.BorderSizePixel = 0
        hdrLine.Parent = hdr

        -- Content
        local cnt = Instance.new("Frame")
        cnt.Name = "Content"
        cnt.Size = UDim2.new(1, 0, 0, 0)
        cnt.Position = UDim2.new(0, 0, 0, 32)
        cnt.AutomaticSize = Enum.AutomaticSize.Y
        cnt.BackgroundTransparency = 1
        cnt.Parent = gb
        MakeListLayout(cnt, 0)
        MakePadding(cnt, 2, 6, 0, 0)

        local section = {
            _name = name, _frame = gb, _content = cnt,
            _tab = self, _library = self._library,
        }
        if side == "R" then self._curRow = nil end
        table.insert(self._sections, section)
        return section
    end

    return wObj
end

-- ================================================================
-- EXPOSE UTILITIES
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
Library.EnsureObservable  = EnsureObservable
Library.FireChanged       = FireChanged
Library.AutoSize          = AutoSize
Library.MakeDraggable     = MakeDraggable
Library.AddDropShadow     = AddDropShadow
Library.MakeListLayout    = MakeListLayout
Library.ThemePresets = ThemePresets

function Library.Theme() return Theme end

return Library
