--[[
    Kojo - A Universal Roblox UI Library
    Version: 2.0.0
    Style: Dark theme with purple accents
    Features: Window, Tabs, Sections, Toggle, Slider, Dropdown, Button, Label,
              TextBox, Keybind, ColorPicker, Loading Screen, Notifications,
              Watermark, FPS helpers, config, tooltip system, and extension hooks
    
    Usage:
        local Library = loadstring(game:HttpGet("..."))()
        local Window = Library:CreateWindow({ Title = "My Hub", ... })
        local Tab = Window:AddTab("Main")
        local Section = Tab:AddSection("Features")
        Section:AddToggle("My Toggle", { Default = false, Callback = function(v) end })

    Note:
        Loading this file only returns the Library object.
        No UI is created until you call Library:CreateWindow(...) or another bootstrap API.
--]]

-- ============================================================
-- EXECUTOR COMPATIBILITY SHIMS
-- ============================================================

local cloneref      = (cloneref or clonereference or function(i) return i end)
local getgenv       = (getgenv or function() return shared end)
local gethui        = (gethui or nil)
local isfolder      = (isfolder or function() return false end)
local isfile        = (isfile or function() return false end)
local makefolder    = (makefolder or function() end)
local writefile     = (writefile or function() end)
local readfile      = (readfile or function() return "" end)
local listfiles     = (listfiles or function() return {} end)
local delfile       = (delfile or function() end)
local protectgui    = (protectgui or function() end)
local setclipboard  = (setclipboard or function() end)

-- ============================================================
-- SERVICES & GLOBALS
-- ============================================================

local Library = {}
Library.__index = Library
Library.Name = "Kojo"
Library.Version = "2.1.0"
Library._windows = {}
Library._gui = nil
Library._controlRegistry = {}
Library._sectionExtensions = {}
Library._extendedModules = {}
Library.Extended = {}
Library._toggleKey = Enum.KeyCode.RightShift
Library.Options = {}
Library.Toggles = {}
Library.Flags = {}
Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true
Library.ShowCustomCursor = false
Library.Unloaded = false
Library._unloadCallbacks = {}

local RunService       = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService     = cloneref(game:GetService("TweenService"))
local Players          = cloneref(game:GetService("Players"))
local HttpService      = cloneref(game:GetService("HttpService"))
local CoreGui          = cloneref(game:GetService("CoreGui"))
local TextService      = cloneref(game:GetService("TextService"))

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = LocalPlayer:GetMouse()

-- ============================================================
-- UTILITY: gethui / ScreenGui Container
-- ============================================================

local function GetGuiContainer()
    -- Universal gethui support for exploit environments
    local success, gui = pcall(function()
        if gethui then
            return gethui()
        end
        return nil
    end)
    if success and gui then
        return gui
    end
    -- Fallback to CoreGui (for games that allow it)
    local ok, cg = pcall(function()
        return CoreGui
    end)
    if ok and cg then
        return cg
    end
    -- Last resort: PlayerGui
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- ============================================================
-- THEME / COLOR CONSTANTS
-- ============================================================

local Theme = {
    -- Main backgrounds
    Background        = Color3.fromRGB(15, 15, 18),
    BackgroundSecond  = Color3.fromRGB(20, 20, 25),
    WindowBorder      = Color3.fromRGB(35, 35, 42),
    
    -- Section / Card backgrounds
    SectionBg         = Color3.fromRGB(22, 22, 28),
    SectionBorder     = Color3.fromRGB(38, 38, 48),
    
    -- Sidebar
    SidebarBg         = Color3.fromRGB(18, 18, 22),
    SidebarActive     = Color3.fromRGB(28, 28, 36),
    SidebarIcon       = Color3.fromRGB(130, 130, 155),
    SidebarIconActive = Color3.fromRGB(220, 215, 235),
    
    -- Breadcrumb / Nav
    BreadcrumbActive  = Color3.fromRGB(180, 155, 220),
    BreadcrumbInactive= Color3.fromRGB(100, 100, 120),
    BreadcrumbSep     = Color3.fromRGB(80, 80, 95),
    
    -- Toggle
    ToggleOff         = Color3.fromRGB(50, 50, 62),
    ToggleOn          = Color3.fromRGB(148, 100, 220),
    ToggleOnBright    = Color3.fromRGB(165, 115, 240),
    ToggleKnob        = Color3.fromRGB(235, 230, 245),
    ToggleKnobOff     = Color3.fromRGB(120, 115, 135),
    
    -- Slider
    SliderBg          = Color3.fromRGB(40, 38, 52),
    SliderFill        = Color3.fromRGB(148, 100, 220),
    SliderKnob        = Color3.fromRGB(220, 210, 240),
    
    -- Button
    ButtonBg          = Color3.fromRGB(38, 36, 50),
    ButtonBgHover     = Color3.fromRGB(55, 52, 72),
    ButtonBgActive    = Color3.fromRGB(148, 100, 220),
    ButtonBorder      = Color3.fromRGB(58, 55, 75),
    
    -- Dropdown
    DropdownBg        = Color3.fromRGB(32, 30, 42),
    DropdownBorder    = Color3.fromRGB(55, 52, 72),
    DropdownItem      = Color3.fromRGB(28, 26, 38),
    DropdownItemHover = Color3.fromRGB(42, 40, 56),
    DropdownSelected  = Color3.fromRGB(148, 100, 220),
    
    -- TextBox
    InputBg           = Color3.fromRGB(30, 28, 40),
    InputBorder       = Color3.fromRGB(52, 50, 68),
    InputBorderFocus  = Color3.fromRGB(148, 100, 220),
    
    -- Text colors
    TextPrimary       = Color3.fromRGB(225, 222, 238),
    TextSecondary     = Color3.fromRGB(155, 150, 175),
    TextDisabled      = Color3.fromRGB(90, 88, 105),
    TextAccent        = Color3.fromRGB(175, 140, 235),
    
    -- Accent
    Accent            = Color3.fromRGB(148, 100, 220),
    AccentLight       = Color3.fromRGB(175, 130, 245),
    AccentDark        = Color3.fromRGB(110, 72, 175),
    
    -- Notification
    NotifBg           = Color3.fromRGB(25, 24, 32),
    NotifBorder       = Color3.fromRGB(148, 100, 220),
    NotifSuccess      = Color3.fromRGB(80, 200, 120),
    NotifWarning      = Color3.fromRGB(240, 180, 60),
    NotifError        = Color3.fromRGB(220, 75, 75),
    NotifInfo         = Color3.fromRGB(85, 175, 235),
    
    -- Keybind
    KeybindBg         = Color3.fromRGB(35, 33, 46),
    KeybindBorder     = Color3.fromRGB(60, 57, 78),
    
    -- Loading
    LoadingBg         = Color3.fromRGB(12, 12, 16),
    LoadingProgressBg = Color3.fromRGB(35, 33, 46),
    LoadingProgressFill = Color3.fromRGB(148, 100, 220),
    
    -- Scrollbar
    ScrollBg          = Color3.fromRGB(30, 28, 40),
    ScrollBar         = Color3.fromRGB(75, 70, 95),
    
    -- Separator
    Separator         = Color3.fromRGB(35, 33, 46),
    
    -- Shadow
    Shadow            = Color3.fromRGB(5, 5, 8),
}

-- Font constants
local Font = {
    Regular   = Enum.Font.GothamMedium,
    Bold      = Enum.Font.GothamBold,
    SemiBold  = Enum.Font.GothamSemibold,
    Mono      = Enum.Font.Code,
}

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

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
    local factor = 10^dec
    return math.floor(n * factor + 0.5) / factor
end

local function Clamp(v, min, max)
    return math.max(min, math.min(max, v))
end

local function MakeDraggable(frame, dragHandle)
    dragHandle = dragHandle or frame
    local dragging, dragInput, dragStart, startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
            frame.Position = newPos
        end
    end)
end

local function AddDropShadow(parent, size, transparency)
    size = size or 15
    transparency = transparency or 0.7
    local shadow = Create("ImageLabel", {
        Name = "DropShadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 4),
        Size = UDim2.new(1, size * 2, 1, size * 2),
        ZIndex = parent.ZIndex - 1,
        Image = "rbxassetid://5554236805",
        ImageColor3 = Theme.Shadow,
        ImageTransparency = transparency,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        Parent = parent,
    })
    return shadow
end

local function MakeRounded(parent, radius)
    return Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 6),
        Parent = parent,
    })
end

local function MakeStroke(parent, color, thickness, trans)
    return Create("UIStroke", {
        Color = color or Theme.WindowBorder,
        Thickness = thickness or 1,
        Transparency = trans or 0,
        Parent = parent,
    })
end

local function MakePadding(parent, top, bottom, left, right)
    return Create("UIPadding", {
        PaddingTop    = UDim.new(0, top    or 8),
        PaddingBottom = UDim.new(0, bottom or 8),
        PaddingLeft   = UDim.new(0, left   or 10),
        PaddingRight  = UDim.new(0, right  or 10),
        Parent = parent,
    })
end

local function MakeListLayout(parent, padding, direction, halign, valign)
    return Create("UIListLayout", {
        Padding = UDim.new(0, padding or 6),
        FillDirection = direction or Enum.FillDirection.Vertical,
        HorizontalAlignment = halign or Enum.HorizontalAlignment.Left,
        VerticalAlignment = valign or Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = parent,
    })
end

local function MakeGridLayout(parent, cellSize, padding)
    return Create("UIGridLayout", {
        CellSize = cellSize or UDim2.new(0.5, -4, 0, 30),
        CellPaddingH = UDim.new(0, padding or 6),
        CellPaddingV = UDim.new(0, padding or 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = parent,
    })
end

-- Auto-resize frame based on UIListLayout content
local function AutoSize(frame, layout, minHeight, axis)
    axis = axis or "Y"
    local function update()
        if axis == "Y" then
            local h = layout.AbsoluteContentSize.Y
            frame.Size = UDim2.new(
                frame.Size.X.Scale,
                frame.Size.X.Offset,
                0,
                math.max(minHeight or 0, h)
            )
        else
            local w = layout.AbsoluteContentSize.X
            frame.Size = UDim2.new(
                0,
                math.max(minHeight or 0, w),
                frame.Size.Y.Scale,
                frame.Size.Y.Offset
            )
        end
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
    update()
end

local function PointInGui(guiObject, point)
    if not guiObject or not guiObject.Visible then
        return false
    end
    local pos = guiObject.AbsolutePosition
    local size = guiObject.AbsoluteSize
    return point.X >= pos.X and point.X <= pos.X + size.X and point.Y >= pos.Y and point.Y <= pos.Y + size.Y
end

local function NormalizeKeybindToken(token)
    if typeof(token) == "EnumItem" then
        return token
    end
    if type(token) == "string" then
        if token == "MB1" or token == "MB2" or token == "MB3" then
            return token
        end
        return Enum.KeyCode[token] or Enum.UserInputType[token] or Enum.KeyCode.Unknown
    end
    return Enum.KeyCode.Unknown
end

local function GetInputToken(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        return input.KeyCode
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        return "MB1"
    end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        return "MB2"
    end
    if input.UserInputType == Enum.UserInputType.MouseButton3 then
        return "MB3"
    end
    return input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode or input.UserInputType
end

local function KeyTokenToDisplay(token)
    if typeof(token) == "EnumItem" then
        return token.Name
    end
    return tostring(token or "None")
end

local function SanitizeFlag(value)
    value = tostring(value or "")
    value = value:gsub("[%c\r\n\t]", " ")
    value = value:gsub("%s+", "_")
    value = value:gsub("[^%w_%.%-]", "")
    return value
end

local function EncodeConfigValue(value)
    if typeof(value) == "Color3" then
        return {
            __type = "Color3",
            r = value.R,
            g = value.G,
            b = value.B,
        }
    end
    if typeof(value) == "EnumItem" then
        return {
            __type = "EnumItem",
            enumType = tostring(value.EnumType),
            name = value.Name,
        }
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
    if type(value) ~= "table" then
        return value
    end
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

local function NormalizeDisplayAndIndex(primary, opts, fallbackText)
    opts = opts or {}
    local index = opts.Index or opts.Flag or primary
    local text = opts.Text or fallbackText or primary
    return tostring(index), tostring(text), opts
end

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
    if not control or not control._changedCallbacks then
        return
    end
    for _, fn in ipairs(control._changedCallbacks) do
        task.spawn(fn, ...)
    end
end

function Library:_makeFlag(tabName, sectionName, label, explicitFlag)
    return SanitizeFlag(explicitFlag or string.format("%s.%s.%s", tabName or "Tab", sectionName or "Section", label or "Value"))
end

function Library:_registerControl(control)
    if not control or not control.Flag then
        return control
    end
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
        if control and not ignoreFlags[flag] and control.Set then
            local ok, err = pcall(function()
                control:Set(DecodeConfigValue(encoded))
            end)
            if not ok then
                warn("[Kojo] failed to apply config for flag:", flag, err)
            end
        end
    end
end

function Library:_attachTooltip(target, text, disabledText)
    if not target then
        return
    end
    local shown = disabledText or text
    if not shown or shown == "" then
        return
    end
    target.MouseEnter:Connect(function()
        local pos = UserInputService:GetMouseLocation()
        self:ShowTooltip(shown, pos.X, pos.Y)
    end)
    target.MouseMoved:Connect(function(x, y)
        self:ShowTooltip(shown, x, y)
    end)
    target.MouseLeave:Connect(function()
        self:HideTooltip()
    end)
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

function Library:UseExtended(extended)
    if type(extended) ~= "table" then
        return self
    end

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

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================

local NotificationHolder = nil

local function EnsureNotifHolder(guiRoot)
    if NotificationHolder and NotificationHolder.Parent then return end
    NotificationHolder = Create("Frame", {
        Name = "NotificationHolder",
        AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.new(0, 320, 1, 0),
        ZIndex = 9999,
        Parent = guiRoot,
    })
    local layout = Create("UIListLayout", {
        Padding = UDim.new(0, 8),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = NotificationHolder,
    })
end

function Library:Notify(options)
    options = options or {}
    local title    = options.Title or "Notification"
    local desc     = options.Description or ""
    local duration = options.Duration or 4
    local ntype    = options.Type or "Info" -- Info, Success, Warning, Error

    local typeColors = {
        Info    = Theme.NotifInfo,
        Success = Theme.NotifSuccess,
        Warning = Theme.NotifWarning,
        Error   = Theme.NotifError,
    }
    local accentColor = typeColors[ntype] or Theme.NotifInfo

    if not self._gui then
        self:Init()
    end
    EnsureNotifHolder(self._gui)

    local notif = Create("Frame", {
        Name = "Notification",
        BackgroundColor3 = Theme.NotifBg,
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundTransparency = 0,
        ClipsDescendants = true,
        Parent = NotificationHolder,
    })
    MakeRounded(notif, 8)
    MakeStroke(notif, Theme.WindowBorder, 1)

    -- Left accent bar
    local accentBar = Create("Frame", {
        BackgroundColor3 = accentColor,
        Size = UDim2.new(0, 3, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Parent = notif,
    })
    MakeRounded(accentBar, 2)

    -- Content
    local content = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -12, 1, 0),
        Parent = notif,
    })
    MakePadding(content, 8, 8, 4, 8)

    local titleLabel = Create("TextLabel", {
        Text = title,
        Font = Font.Bold,
        TextSize = 13,
        TextColor3 = Theme.TextPrimary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = content,
    })

    local descLabel = Create("TextLabel", {
        Text = desc,
        Font = Font.Regular,
        TextSize = 11,
        TextColor3 = Theme.TextSecondary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 22),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = content,
    })

    -- Progress bar
    local progressBg = Create("Frame", {
        BackgroundColor3 = Theme.LoadingProgressBg,
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        Parent = notif,
    })
    local progressFill = Create("Frame", {
        BackgroundColor3 = accentColor,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = progressBg,
    })

    -- Animate in
    notif.BackgroundTransparency = 1
    Tween(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundTransparency = 0 })

    -- Progress countdown
    local elapsed = 0
    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        local remaining = 1 - (elapsed / duration)
        progressFill.Size = UDim2.new(math.max(0, remaining), 0, 1, 0)
        if elapsed >= duration then
            conn:Disconnect()
            Tween(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
            }, function()
                notif:Destroy()
            end)
        end
    end)

    return notif
end

-- ============================================================
-- LOADING SCREEN
-- ============================================================

local LoadingClass = {}
LoadingClass.__index = LoadingClass

function Library:CreateLoading(options)
    options = options or {}
    local title      = options.Title or "Kojo Hub"
    local totalSteps = options.TotalSteps or 4
    local currentStep = options.CurrentStep or 0

    local gui = GetGuiContainer()
    local screenGui = Create("ScreenGui", {
        Name = "KojoLoading",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 9990,
        IgnoreGuiInset = true,
        Parent = gui,
    })

    -- Backdrop
    local backdrop = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.4,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 1,
        Parent = screenGui,
    })

    -- Main window
    local window = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.LoadingBg,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 420, 0, 200),
        ZIndex = 2,
        Parent = screenGui,
    })
    MakeRounded(window, 12)
    MakeStroke(window, Theme.WindowBorder, 1)
    AddDropShadow(window, 20, 0.5)
    MakePadding(window, 28, 28, 32, 32)

    -- Spinning icon
    local iconFrame = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(0, 40, 0, 40),
        Parent = window,
    })
    local iconOuter = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        Parent = iconFrame,
    })
    local iconRing = Create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        Image = "rbxassetid://4965945816",
        ImageColor3 = Theme.Accent,
        Parent = iconOuter,
    })

    -- Rotate animation
    local rotConn
    local angle = 0
    rotConn = RunService.Heartbeat:Connect(function(dt)
        angle = (angle + dt * 180) % 360
        iconOuter.Rotation = angle
    end)

    -- Title
    local titleLabel = Create("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 52),
        Size = UDim2.new(1, 0, 0, 22),
        Text = title,
        Font = Font.Bold,
        TextSize = 18,
        TextColor3 = Theme.TextPrimary,
        Parent = window,
    })

    -- Status message
    local messageLabel = Create("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 80),
        Size = UDim2.new(1, 0, 0, 18),
        Text = "Initializing...",
        Font = Font.Regular,
        TextSize = 13,
        TextColor3 = Theme.TextSecondary,
        Parent = window,
    })

    -- Description
    local descLabel = Create("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 100),
        Size = UDim2.new(1, 0, 0, 16),
        Text = "",
        Font = Font.Regular,
        TextSize = 11,
        TextColor3 = Theme.TextDisabled,
        Parent = window,
    })

    -- Progress bar background
    local progressBg = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundColor3 = Theme.LoadingProgressBg,
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 5),
        Parent = window,
    })
    MakeRounded(progressBg, 3)

    local progressFill = Create("Frame", {
        BackgroundColor3 = Theme.LoadingProgressFill,
        Size = UDim2.new(0, 0, 1, 0),
        Parent = progressBg,
    })
    MakeRounded(progressFill, 3)

    -- Step counter
    local stepLabel = Create("TextLabel", {
        AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, 0, 1, -12),
        Size = UDim2.new(0, 80, 0, 14),
        Text = string.format("0 / %d", totalSteps),
        Font = Font.Regular,
        TextSize = 10,
        TextColor3 = Theme.TextDisabled,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = window,
    })

    local self = setmetatable({}, LoadingClass)
    self._gui = screenGui
    self._window = window
    self._progressFill = progressFill
    self._messageLabel = messageLabel
    self._descLabel = descLabel
    self._stepLabel = stepLabel
    self._totalSteps = totalSteps
    self._currentStep = currentStep
    self._rotConn = rotConn
    self._library = Library

    function self:SetMessage(msg)
        self._messageLabel.Text = msg
    end

    function self:SetDescription(desc)
        self._descLabel.Text = desc
    end

    function self:SetTotalSteps(n)
        self._totalSteps = n
        self:_UpdateProgress()
    end

    function self:SetCurrentStep(n)
        self._currentStep = n
        self:_UpdateProgress()
    end

    function self:_UpdateProgress()
        local frac = math.min(1, self._currentStep / math.max(1, self._totalSteps))
        Tween(self._progressFill, TweenInfo.new(0.35, Enum.EasingStyle.Quart), {
            Size = UDim2.new(frac, 0, 1, 0)
        })
        self._stepLabel.Text = string.format("%d / %d", self._currentStep, self._totalSteps)
    end

    function self:ShowErrorPage(show)
        if show then
            self._messageLabel.TextColor3 = Theme.NotifError
            self._messageLabel.Text = "An Error Occurred"
        else
            self._messageLabel.TextColor3 = Theme.TextSecondary
        end
    end

    function self:SetErrorMessage(msg)
        self._descLabel.Text = msg
        self._descLabel.TextColor3 = Theme.NotifError
    end

    function self:Destroy()
        if self._rotConn then self._rotConn:Disconnect() end
        if self._gui then
            Tween(backdrop, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
            Tween(self._window, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 380, 0, 160),
            }, function()
                self._gui:Destroy()
            end)
        end
    end

    function self:Continue()
        self:Destroy()
    end

    return self
end

-- ============================================================
-- MAIN WINDOW
-- ============================================================

local WindowClass = {}
WindowClass.__index = WindowClass

function Library:Init()
    local gui = GetGuiContainer()
    local screenGui = Create("ScreenGui", {
        Name = "KojoLib_" .. HttpService:GenerateGUID(false):sub(1, 8),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100,
        IgnoreGuiInset = true,
        Parent = gui,
    })
    pcall(protectgui, screenGui)
    self._gui = screenGui
    return self
end

function Library:CreateWindow(options)
    options = options or {}
    local title    = options.Title or "Kojo Hub"
    local width    = options.Width or 780
    local height   = options.Height or 520
    local tabs     = options.Tabs or {}
    local icon     = options.Icon or nil

    if not self._gui then
        self:Init()
    end

    local gui = self._gui

    -- Main window frame
    local windowFrame = Create("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Background,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, width, 0, height),
        ClipsDescendants = false,
        Parent = gui,
    })
    MakeRounded(windowFrame, 12)
    MakeStroke(windowFrame, Theme.WindowBorder, 1)
    AddDropShadow(windowFrame, 25, 0.45)

    -- Sidebar (left)
    local sidebar = Create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = Theme.SidebarBg,
        Size = UDim2.new(0, 52, 1, 0),
        ClipsDescendants = true,
        Parent = windowFrame,
    })
    local sidebarCorner = Create("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = sidebar,
    })
    -- Override right corners to be square
    local sidebarRight = Create("Frame", {
        BackgroundColor3 = Theme.SidebarBg,
        Position = UDim2.new(1, -12, 0, 0),
        Size = UDim2.new(0, 12, 1, 0),
        Parent = sidebar,
    })
    MakeStroke(sidebar, Theme.WindowBorder, 1)

    -- Logo / icon at top of sidebar
    local logoFrame = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 10),
        Size = UDim2.new(1, 0, 0, 52),
        Parent = sidebar,
    })
    local logoIcon = Create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 28, 0, 28),
        Image = icon or "rbxassetid://4483362458",
        ImageColor3 = Theme.Accent,
        Parent = logoFrame,
    })

    -- Tab icon list in sidebar
    local sidebarTabList = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 72),
        Size = UDim2.new(1, 0, 1, -72),
        Parent = sidebar,
    })
    local sidebarLayout = Create("UIListLayout", {
        Padding = UDim.new(0, 4),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = sidebarTabList,
    })
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        Parent = sidebarTabList,
    })

    -- Right content area
    local contentArea = Create("Frame", {
        Name = "ContentArea",
        BackgroundColor3 = Theme.Background,
        Position = UDim2.new(0, 52, 0, 0),
        Size = UDim2.new(1, -52, 1, 0),
        ClipsDescendants = true,
        Parent = windowFrame,
    })
    local contentCorner = Create("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = contentArea,
    })
    -- Square left corners
    Create("Frame", {
        BackgroundColor3 = Theme.Background,
        Size = UDim2.new(0, 12, 1, 0),
        Parent = contentArea,
    })

    -- Header bar (breadcrumb)
    local headerBar = Create("Frame", {
        Name = "HeaderBar",
        BackgroundColor3 = Theme.BackgroundSecond,
        Size = UDim2.new(1, 0, 0, 44),
        ClipsDescendants = true,
        Parent = contentArea,
    })
    -- Square bottom corners
    Create("Frame", {
        BackgroundColor3 = Theme.BackgroundSecond,
        Position = UDim2.new(0, 0, 1, -12),
        Size = UDim2.new(1, 0, 0, 12),
        Parent = headerBar,
    })
    MakeStroke(headerBar, Theme.WindowBorder, 1)

    -- Breadcrumb container
    local breadcrumbContainer = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -14, 1, 0),
        Parent = headerBar,
    })
    local breadcrumbLayout = Create("UIListLayout", {
        Padding = UDim.new(0, 4),
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = breadcrumbContainer,
    })

    -- Tab content area
    local tabViewport = Create("Frame", {
        Name = "TabViewport",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(1, 0, 1, -44),
        ClipsDescendants = true,
        Parent = contentArea,
    })

    -- Make draggable via header
    MakeDraggable(windowFrame, headerBar)

    -- Window object
    local windowObj = setmetatable({}, WindowClass)
    windowObj._frame       = windowFrame
    windowObj._sidebar     = sidebar
    windowObj._sidebarTabList = sidebarTabList
    windowObj._breadcrumb  = breadcrumbContainer
    windowObj._tabViewport = tabViewport
    windowObj._tabs        = {}
    windowObj._activeTab   = nil
    windowObj._library     = self
    windowObj._title       = title
    windowObj.Tabs         = {}

    -- Build breadcrumb for a tab and its sub-tabs
    function windowObj:_BuildBreadcrumb(tabObj)
        -- Clear existing
        for _, c in pairs(breadcrumbContainer:GetChildren()) do
            if c:IsA("TextLabel") or c:IsA("TextButton") or c:IsA("Frame") then
                c:Destroy()
            end
        end

        -- Hub name (root)
        local rootLabel = Create("TextLabel", {
            Text = "> " .. title,
            Font = Font.SemiBold,
            TextSize = 12,
            TextColor3 = Theme.BreadcrumbInactive,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Parent = breadcrumbContainer,
        })

        -- Each tab as breadcrumb segment
        for i, t in ipairs(self._tabs) do
            local sep = Create("TextLabel", {
                Text = "/",
                Font = Font.Regular,
                TextSize = 12,
                TextColor3 = Theme.BreadcrumbSep,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 14, 1, 0),
                Parent = breadcrumbContainer,
            })

            local isActive = t == tabObj
            local crumb = Create("TextButton", {
                Text = t._name,
                Font = isActive and Font.SemiBold or Font.Regular,
                TextSize = 12,
                TextColor3 = isActive and Theme.BreadcrumbActive or Theme.BreadcrumbInactive,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                Parent = breadcrumbContainer,
            })
            crumb.MouseButton1Click:Connect(function()
                self:_SelectTab(t)
            end)
        end
    end

    function windowObj:_SelectTab(tabObj)
        if self._activeTab == tabObj then return end
        -- Hide all tab frames
        for _, t in ipairs(self._tabs) do
            t._frame.Visible = false
            if t._sidebarBtn then
                t._sidebarBtn.BackgroundTransparency = 1
                t._sidebarIcon.ImageColor3 = Theme.SidebarIcon
            end
        end
        -- Show selected
        tabObj._frame.Visible = true
        self._activeTab = tabObj
        if tabObj._sidebarBtn then
            tabObj._sidebarBtn.BackgroundColor3 = Theme.SidebarActive
            tabObj._sidebarBtn.BackgroundTransparency = 0
            tabObj._sidebarIcon.ImageColor3 = Theme.SidebarIconActive
        end
        self:_BuildBreadcrumb(tabObj)
    end

    function windowObj:AddTab(name, iconId)
        iconId = iconId or "rbxassetid://4483362458"

        -- Sidebar button
        local sidebarBtn = Create("TextButton", {
            Name = "SidebarBtn_" .. name,
            BackgroundColor3 = Theme.SidebarActive,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 38, 0, 38),
            Text = "",
            Parent = sidebarTabList,
        })
        MakeRounded(sidebarBtn, 8)

        local sidebarIcon = Create("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 20, 0, 20),
            Image = iconId,
            ImageColor3 = Theme.SidebarIcon,
            Parent = sidebarBtn,
        })

        -- Tooltip
        local tooltip = Create("TextLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Theme.NotifBg,
            Position = UDim2.new(1, 8, 0.5, 0),
            Size = UDim2.new(0, 0, 0, 22),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = "  " .. name .. "  ",
            Font = Font.Regular,
            TextSize = 11,
            TextColor3 = Theme.TextPrimary,
            Visible = false,
            ZIndex = 999,
            Parent = sidebarBtn,
        })
        MakeRounded(tooltip, 4)
        MakeStroke(tooltip, Theme.WindowBorder, 1)

        sidebarBtn.MouseEnter:Connect(function()
            tooltip.Visible = true
            Tween(sidebarBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0.6 })
        end)
        sidebarBtn.MouseLeave:Connect(function()
            tooltip.Visible = false
            if self._activeTab and self._activeTab._sidebarBtn == sidebarBtn then return end
            Tween(sidebarBtn, TweenInfo.new(0.15), { BackgroundTransparency = 1 })
        end)

        -- Tab frame (scrollable content)
        local tabFrame = Create("ScrollingFrame", {
            Name = "Tab_" .. name,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.ScrollBar,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y,
            Visible = false,
            Parent = tabViewport,
        })
        MakePadding(tabFrame, 10, 10, 10, 10)

        -- Grid layout for sections (two columns)
        local sectionGrid = Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = tabFrame,
        })
        local gridLayout = Create("UIGridLayout", {
            CellSize = UDim2.new(0.5, -6, 0, 0),
            CellPaddingH = UDim.new(0, 12),
            CellPaddingV = UDim.new(0, 10),
            FillDirectionMaxCells = 2,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = sectionGrid,
        })
        -- Override with auto-height cells by using a different approach
        sectionGrid.AutomaticSize = Enum.AutomaticSize.Y
        -- Remove grid, use horizontal list instead for proper auto-sizing
        gridLayout:Destroy()

        local columnLayout = Create("UIListLayout", {
            Padding = UDim.new(0, 10),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = sectionGrid,
        })

        -- Left and right columns
        local leftCol = Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0.5, -5, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = sectionGrid,
        })
        MakeListLayout(leftCol, 10)

        local rightCol = Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0.5, -5, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = sectionGrid,
        })
        MakeListLayout(rightCol, 10)

        local tabObj = {
            _name       = name,
            _frame      = tabFrame,
            _sectionGrid = sectionGrid,
            _leftCol    = leftCol,
            _rightCol   = rightCol,
            _sidebarBtn = sidebarBtn,
            _sidebarIcon = sidebarIcon,
            _sections   = {},
            _sectionCount = 0,
            _library    = self._library,
        }

        sidebarBtn.MouseButton1Click:Connect(function()
            windowObj:_SelectTab(tabObj)
        end)

        table.insert(self._tabs, tabObj)
        self.Tabs[name] = tabObj

        -- Auto-select first tab
        if #self._tabs == 1 then
            self:_SelectTab(tabObj)
        end

        function tabObj:UpdateWarningBox(opts)
            opts = opts or {}
            self._warningBox = self._warningBox or self:AddSection(opts.Title or "Warning", "Left")
            if opts.Text then
                if self._warningLabel then
                    self._warningLabel:Set(opts.Text)
                else
                    self._warningLabel = self._warningBox:AddLabel(opts.Text, {
                        Color = Theme.NotifWarning,
                        RichText = true,
                    })
                end
            end
            if self._warningBox and self._warningBox._frame then
                self._warningBox._frame.Visible = opts.Visible ~= false
            end
        end

        -- Section creation
        function tabObj:AddSection(sectionName, column)
            -- column: "Left" (default) or "Right"
            column = column or "Left"
            local parent = column == "Right" and self._rightCol or self._leftCol

            self._sectionCount = self._sectionCount + 1

            local sectionFrame = Create("Frame", {
                Name = "Section_" .. sectionName,
                BackgroundColor3 = Theme.SectionBg,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = self._sectionCount,
                ClipsDescendants = false,
                Parent = parent,
            })
            MakeRounded(sectionFrame, 10)
            MakeStroke(sectionFrame, Theme.SectionBorder, 1)
            MakePadding(sectionFrame, 10, 12, 0, 0)

            -- Section header
            local headerFrame = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 28),
                Parent = sectionFrame,
            })
            MakePadding(headerFrame, 0, 0, 12, 12)

            -- Section icon
            local sectionIcon = Create("ImageLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0.5, -8),
                Size = UDim2.new(0, 16, 0, 16),
                Image = "rbxassetid://4483362458",
                ImageColor3 = Theme.TextSecondary,
                Parent = headerFrame,
            })

            local sectionTitle = Create("TextLabel", {
                Text = sectionName,
                Font = Font.SemiBold,
                TextSize = 13,
                TextColor3 = Theme.TextPrimary,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 22, 0, 6),
                Size = UDim2.new(1, -22, 0, 18),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = headerFrame,
            })

            -- Separator line
            local sep = Create("Frame", {
                BackgroundColor3 = Theme.Separator,
                Size = UDim2.new(1, 0, 0, 1),
                Parent = sectionFrame,
            })

            -- Element list
            local elemList = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = sectionFrame,
            })
            MakePadding(elemList, 4, 4, 0, 0)
            MakeListLayout(elemList, 2)

            local sectionObj = {
                _frame    = sectionFrame,
                _elemList = elemList,
                _items    = {},
                _library  = self._library,
                _tabName  = self._name,
                _sectionName = sectionName,
            }

            local function registerControl(control, controlType, itemLabel, opts)
                opts = opts or {}
                EnsureObservable(control)
                control.Type = controlType
                control.Label = itemLabel
                control.Flag = self._library:_makeFlag(self._name, sectionName, itemLabel, opts.Flag)
                control.Index = tostring(opts.Index or control.Flag)
                control.Save = opts.Save ~= false
                control._library = self._library
                if not control.GetValue and control.Value ~= nil then
                    control.GetValue = function(selfControl)
                        return selfControl.Value
                    end
                end
                if not control.Set and control.SetValue then
                    control.Set = function(selfControl, value)
                        return selfControl:SetValue(value)
                    end
                end
                if control.Set and not control.SetValue then
                    control.SetValue = function(selfControl, value)
                        return selfControl:Set(value)
                    end
                end
                self._library:_registerControl(control)
                self._library.Options[control.Index] = control
                self._library.Flags[control.Flag] = control
                if controlType == "toggle" or controlType == "checkbox" then
                    self._library.Toggles[control.Index] = control
                end
                table.insert(sectionObj._items, control)
                return control
            end

            -- ====================================================
            -- ADD TOGGLE
            -- ====================================================
            function sectionObj:AddToggle(label, opts)
                opts = opts or {}
                local index, displayText = NormalizeDisplayAndIndex(label, opts)
                local default  = opts.Default ~= nil and opts.Default or false
                local callback = opts.Callback or function() end
                local tooltip  = opts.Tooltip or nil
                local disabledTooltip = opts.DisabledTooltip or tooltip
                local disabled = opts.Disabled ~= nil and opts.Disabled or false

                local value = default

                local row = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 32),
                    Parent = elemList,
                })
                MakePadding(row, 0, 0, 12, 12)

                local labelEl = Create("TextLabel", {
                    Text = displayText,
                    Font = Font.Regular,
                    TextSize = 12,
                    TextColor3 = disabled and Theme.TextDisabled or Theme.TextPrimary,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -52, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = row,
                })

                -- Toggle track
                local trackBg = Create("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = value and Theme.ToggleOn or Theme.ToggleOff,
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0, 38, 0, 20),
                    Parent = row,
                })
                MakeRounded(trackBg, 10)
                MakeStroke(trackBg, value and Theme.ToggleOnBright or Theme.SectionBorder, 1)

                local knob = Create("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = value and Theme.ToggleKnob or Theme.ToggleKnobOff,
                    Position = value and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
                    Size = UDim2.new(0, 14, 0, 14),
                    Parent = trackBg,
                })
                MakeRounded(knob, 7)

                local toggleObj
                local function SetToggle(v, skipCallback)
                    value = v
                    if disabled then return end
                    Tween(trackBg, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {
                        BackgroundColor3 = v and Theme.ToggleOn or Theme.ToggleOff,
                    })
                    Tween(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {
                        Position = v and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
                        BackgroundColor3 = v and Theme.ToggleKnob or Theme.ToggleKnobOff,
                    })
                    -- Stroke update
                    local stroke = trackBg:FindFirstChildWhichIsA("UIStroke")
                    if stroke then
                        stroke.Color = v and Theme.ToggleOnBright or Theme.SectionBorder
                    end
                    if not skipCallback then
                        callback(v)
                    end
                    toggleObj.Value = value
                    FireChanged(toggleObj, value)
                end

                local btn = Create("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    Parent = row,
                })
                if not disabled then
                    btn.MouseButton1Click:Connect(function()
                        SetToggle(not value)
                    end)
                    btn.MouseEnter:Connect(function()
                        Tween(row, TweenInfo.new(0.1), { BackgroundTransparency = 0.92 })
                        row.BackgroundColor3 = Theme.SidebarActive
                    end)
                    btn.MouseLeave:Connect(function()
                        row.BackgroundTransparency = 1
                    end)
                end

                toggleObj = EnsureObservable({
                    Value = value,
                    Set = function(self, v)
                        SetToggle(v, false)
                    end,
                    SetValue = function(self, v)
                        SetToggle(v, false)
                    end,
                    Toggle = function(self)
                        SetToggle(not value, false)
                    end,
                    GetValue = function(self)
                        return value
                    end,
                })
                toggleObj.Index = index
                toggleObj.AddColorPicker = function(self, pickerIndex, pickerOpts)
                    pickerOpts = pickerOpts or {}
                    pickerOpts.Index = pickerIndex
                    return sectionObj:AddColorPicker(pickerIndex, pickerOpts)
                end
                toggleObj.AddKeyPicker = function(self, pickerIndex, pickerOpts)
                    pickerOpts = pickerOpts or {}
                    pickerOpts.Index = pickerIndex
                    if pickerOpts.SyncToggleState == nil then
                        pickerOpts.SyncToggleState = true
                    end
                    pickerOpts.ParentToggle = self
                    return sectionObj:AddKeyPicker(pickerIndex, pickerOpts)
                end
                sectionObj._library:_attachTooltip(btn, disabled and disabledTooltip or tooltip, disabled and disabledTooltip or nil)
                return registerControl(toggleObj, "toggle", displayText, {
                    Flag = opts.Flag,
                    Index = index,
                    Save = opts.Save,
                })
            end

            -- ====================================================
            -- ADD SLIDER
            -- ====================================================
            function sectionObj:AddSlider(label, opts)
                opts = opts or {}
                local index, displayText = NormalizeDisplayAndIndex(label, opts)
                local min      = opts.Min or 0
                local max      = opts.Max or 100
                local default  = opts.Default ~= nil and opts.Default or min
                local step     = opts.Step or 1
                local decimals = opts.Decimals or 0
                local callback = opts.Callback or function() end
                local suffix   = opts.Suffix or ""
                local flag     = opts.Flag or nil
                local tooltip  = opts.Tooltip or nil
                local disabledTooltip = opts.DisabledTooltip or tooltip
                local disabled = opts.Disabled ~= nil and opts.Disabled or false

                local value = Clamp(default, min, max)

                local container = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 44),
                    Parent = elemList,
                })
                MakePadding(container, 0, 0, 12, 12)

                -- Top row: label + value
                local topRow = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18),
                    Parent = container,
                })

                local labelEl = Create("TextLabel", {
                    Text = displayText,
                    Font = Font.Regular,
                    TextSize = 12,
                    TextColor3 = disabled and Theme.TextDisabled or Theme.TextPrimary,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -50, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = topRow,
                })

                local valueLabel = Create("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0),
                    Text = tostring(Round(value, decimals)) .. suffix,
                    Font = Font.Regular,
                    TextSize = 12,
                    TextColor3 = Theme.TextSecondary,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, 0, 0, 0),
                    Size = UDim2.new(0, 48, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = topRow,
                })

                -- Slider track
                local track = Create("Frame", {
                    BackgroundColor3 = Theme.SliderBg,
                    Position = UDim2.new(0, 0, 0, 22),
                    Size = UDim2.new(1, 0, 0, 5),
                    Parent = container,
                })
                MakeRounded(track, 3)

                local fill = Create("Frame", {
                    BackgroundColor3 = disabled and Theme.ToggleOff or Theme.SliderFill,
                    Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                    Parent = track,
                })
                MakeRounded(fill, 3)

                local knob = Create("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = disabled and Theme.TextDisabled or Theme.SliderKnob,
                    Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
                    Size = UDim2.new(0, 14, 0, 14),
                    Parent = track,
                })
                MakeRounded(knob, 7)
                MakeStroke(knob, Theme.SliderFill, 1.5)

                local sliderObj
                local function SetSlider(v, skipCallback)
                    v = Clamp(v, min, max)
                    if step > 0 then
                        v = math.floor(v / step + 0.5) * step
                    end
                    v = Clamp(v, min, max)
                    value = v
                    local frac = (v - min) / (max - min)
                    fill.Size = UDim2.new(frac, 0, 1, 0)
                    knob.Position = UDim2.new(frac, 0, 0.5, 0)
                    valueLabel.Text = tostring(Round(v, decimals)) .. suffix
                    if not skipCallback then callback(v) end
                    sliderObj.Value = value
                    FireChanged(sliderObj, value)
                end

                if not disabled then
                    local draggingSlider = false
                    local trackBtn = Create("TextButton", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 18),
                        Position = UDim2.new(0, 0, 0, 15),
                        Text = "",
                        ZIndex = 5,
                        Parent = container,
                    })

                    trackBtn.MouseButton1Down:Connect(function()
                        draggingSlider = true
                    end)
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            draggingSlider = false
                        end
                    end)
                    UserInputService.InputChanged:Connect(function(input)
                        if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
                            local abs = track.AbsolutePosition
                            local size = track.AbsoluteSize
                            local mx = input.Position.X
                            local frac = Clamp((mx - abs.X) / size.X, 0, 1)
                            local newVal = min + frac * (max - min)
                            SetSlider(newVal)
                        end
                    end)
                end

                sliderObj = EnsureObservable({
                    Value = value,
                    Set = function(self, v)
                        SetSlider(v, false)
                    end,
                    SetValue = function(self, v)
                        SetSlider(v, false)
                    end,
                    GetValue = function(self)
                        return value
                    end,
                })
                sliderObj.Index = index
                sectionObj._library:_attachTooltip(trackBtn or container, disabled and disabledTooltip or tooltip, disabled and disabledTooltip or nil)
                return registerControl(sliderObj, "slider", displayText, {
                    Flag = opts.Flag,
                    Index = index,
                    Save = opts.Save,
                })
            end

            -- ====================================================
            -- ADD BUTTON
            -- ====================================================
            function sectionObj:AddButton(label, opts)
                if type(label) == "table" and opts == nil then
                    opts = label
                    label = opts.Text or opts.Label or "Button"
                else
                    local rawOpts = opts
                    opts = type(opts) == "table" and opts or {}
                    if type(rawOpts) == "function" then
                        opts.Callback = rawOpts
                    end
                end
                local callback  = opts.Callback or opts.Func or function() end
                local tooltip   = opts.Tooltip or nil
                local disabledTooltip = opts.DisabledTooltip or tooltip
                local disabled  = opts.Disabled ~= nil and opts.Disabled or false
                local variant   = opts.Variant or "Default" -- Default, Primary, Danger
                local doubleClick = opts.DoubleClick or false

                local variantColors = {
                    Default = Theme.ButtonBg,
                    Primary = Theme.Accent,
                    Danger  = Theme.NotifError,
                }
                local bgColor = variantColors[variant] or Theme.ButtonBg

                local row = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 30),
                    Parent = elemList,
                })
                MakePadding(row, 0, 0, 12, 12)

                local btn = Create("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = bgColor,
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0, 96, 0, 24),
                    Text = label,
                    Font = Font.Regular,
                    TextSize = 11,
                    TextColor3 = disabled and Theme.TextDisabled or Theme.TextPrimary,
                    AutoButtonColor = false,
                    Parent = row,
                })
                MakeRounded(btn, 6)
                MakeStroke(btn, Theme.ButtonBorder, 1)
                local clickArmed = false

                if not disabled then
                    btn.MouseEnter:Connect(function()
                        Tween(btn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.ButtonBgHover })
                    end)
                    btn.MouseLeave:Connect(function()
                        Tween(btn, TweenInfo.new(0.12), { BackgroundColor3 = bgColor })
                    end)
                    btn.MouseButton1Down:Connect(function()
                        Tween(btn, TweenInfo.new(0.08), { Size = UDim2.new(0, 92, 0, 22) })
                    end)
                    btn.MouseButton1Up:Connect(function()
                        Tween(btn, TweenInfo.new(0.12), { Size = UDim2.new(0, 96, 0, 24) })
                        if doubleClick then
                            if clickArmed then
                                clickArmed = false
                                callback()
                            else
                                clickArmed = true
                                task.delay(0.35, function()
                                    clickArmed = false
                                end)
                            end
                        else
                            callback()
                        end
                    end)
                end

                local btnObj = {
                    _btn = btn,
                    SetLabel = function(self, text)
                        btn.Text = text
                    end,
                    SetDisabled = function(self, v)
                        disabled = v
                        btn.TextColor3 = v and Theme.TextDisabled or Theme.TextPrimary
                    end,
                    AddButton = function(self, nestedOpts)
                        return sectionObj:AddButton(nestedOpts)
                    end,
                }
                sectionObj._library:_attachTooltip(btn, disabled and disabledTooltip or tooltip, disabled and disabledTooltip or nil)
                return btnObj
            end

            -- ====================================================
            -- ADD LABEL
            -- ====================================================
            function sectionObj:AddLabel(text, opts, idx)
                local labelText = text
                local wrapFlag = false
                if type(opts) == "boolean" then
                    wrapFlag = opts
                    opts = {}
                    if idx then
                        opts.Index = idx
                    end
                elseif type(text) == "string" and type(opts) == "table" then
                    if opts.Text then
                        labelText = opts.Text
                        opts.Index = opts.Index or text
                    end
                    wrapFlag = opts.DoesWrap or false
                elseif type(text) == "table" and opts == nil then
                    opts = text
                    labelText = opts.Text or ""
                    wrapFlag = opts.DoesWrap or false
                else
                    opts = opts or {}
                end

                local index = tostring(opts.Index or idx or labelText)
                local color = opts.Color or Theme.TextSecondary
                local size  = opts.Size or 11
                local rich  = opts.RichText or false

                local row = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 22),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = elemList,
                })
                MakePadding(row, 2, 2, 12, 12)

                local label = Create("TextLabel", {
                    Text = labelText,
                    Font = Font.Regular,
                    TextSize = size,
                    TextColor3 = color,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = wrapFlag,
                    RichText = rich,
                    Parent = row,
                })

                local labelObj = EnsureObservable({
                    _label = label,
                    Set = function(self, txt)
                        label.Text = txt
                        FireChanged(self, txt)
                    end,
                    SetText = function(self, txt)
                        label.Text = txt
                        FireChanged(self, txt)
                    end,
                    SetColor = function(self, c)
                        label.TextColor3 = c
                    end,
                    GetValue = function(self)
                        return label.Text
                    end,
                })
                labelObj.Index = index
                labelObj.AddColorPicker = function(self, pickerIndex, pickerOpts)
                    pickerOpts = pickerOpts or {}
                    pickerOpts.Index = pickerIndex
                    return sectionObj:AddColorPicker(pickerIndex, pickerOpts)
                end
                labelObj.AddKeyPicker = function(self, pickerIndex, pickerOpts)
                    pickerOpts = pickerOpts or {}
                    pickerOpts.Index = pickerIndex
                    return sectionObj:AddKeyPicker(pickerIndex, pickerOpts)
                end
                sectionObj._library.Options[index] = labelObj
                return labelObj
            end

            -- ====================================================
            -- ADD SEPARATOR
            -- ====================================================
            function sectionObj:AddSeparator()
                local sep = Create("Frame", {
                    BackgroundColor3 = Theme.Separator,
                    Size = UDim2.new(1, 0, 0, 1),
                    Parent = elemList,
                })
                MakePadding(sep, 2, 2, 0, 0)
                return sep
            end

            function sectionObj:AddRadioGroup(label, opts)
                local radioObj = Library._buildRadioGroup(elemList, label, opts)
                return registerControl(radioObj, "radiogroup", label, opts or {})
            end

            function sectionObj:AddProgressBar(label, opts)
                local progressObj = Library._buildProgressBar(elemList, label, opts)
                progressObj.Save = false
                return registerControl(progressObj, "progressbar", label, {
                    Flag = opts and opts.Flag,
                    Save = false,
                })
            end

            -- ====================================================
            -- ADD DROPDOWN
            -- ====================================================
            function sectionObj:AddDropdown(label, opts)
                opts = opts or {}
                local index, displayText = NormalizeDisplayAndIndex(label, opts)
                local options   = opts.Options or opts.Values or {}
                if opts.SpecialType == "Player" then
                    options = {}
                    for _, player in ipairs(Players:GetPlayers()) do
                        if not opts.ExcludeLocalPlayer or player ~= LocalPlayer then
                            table.insert(options, player.Name)
                        end
                    end
                elseif opts.SpecialType == "Team" then
                    options = {}
                    for _, team in ipairs(game:GetService("Teams"):GetChildren()) do
                        table.insert(options, team.Name)
                    end
                end
                local default   = opts.Default ~= nil and opts.Default or options[1]
                local callback  = opts.Callback or function() end
                local multi     = opts.Multi or false
                local searchable = opts.Searchable or false
                local disabledValues = {}
                for _, value in ipairs(opts.DisabledValues or {}) do
                    disabledValues[tostring(value)] = true
                end
                local formatDisplayValue = opts.FormatDisplayValue
                local maxVisibleDropdownItems = opts.MaxVisibleDropdownItems or 8
                local tooltip   = opts.Tooltip or nil
                local disabledTooltip = opts.DisabledTooltip or tooltip
                local disabled  = opts.Disabled ~= nil and opts.Disabled or false

                if type(default) == "number" then
                    default = options[default]
                end

                local value = default
                local multiSelected = {}
                if multi and type(default) == "table" then
                    for key, state in pairs(default) do
                        if state then
                            table.insert(multiSelected, key)
                        end
                    end
                end

                local container = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 32),
                    ClipsDescendants = false,
                    ZIndex = 5,
                    Parent = elemList,
                })
                MakePadding(container, 0, 0, 12, 12)

                local labelEl = Create("TextLabel", {
                    Text = displayText,
                    Font = Font.Regular,
                    TextSize = 12,
                    TextColor3 = disabled and Theme.TextDisabled or Theme.TextPrimary,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -108, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = container,
                })

                -- Dropdown button
                local dropBtn = Create("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = Theme.DropdownBg,
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0, 100, 0, 24),
                    Text = multi and "Select..." or tostring(value or "None"),
                    Font = Font.Regular,
                    TextSize = 11,
                    TextColor3 = Theme.TextPrimary,
                    AutoButtonColor = false,
                    ClipsDescendants = false,
                    ZIndex = 5,
                    Parent = container,
                })
                MakeRounded(dropBtn, 6)
                MakeStroke(dropBtn, Theme.DropdownBorder, 1)

                local searchBox

                -- Arrow icon
                local arrow = Create("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Text = "▾",
                    Font = Font.Regular,
                    TextSize = 11,
                    TextColor3 = Theme.TextSecondary,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -6, 0.5, 0),
                    Size = UDim2.new(0, 14, 0, 14),
                    Parent = dropBtn,
                })

                -- Dropdown list (popup)
                local dropList = Create("Frame", {
                    BackgroundColor3 = Theme.DropdownBg,
                    Position = UDim2.new(0, 0, 1, 4),
                    Size = UDim2.new(1, 0, 0, 0),
                    ClipsDescendants = true,
                    ZIndex = 50,
                    Visible = false,
                    Parent = dropBtn,
                })
                MakeRounded(dropList, 6)
                MakeStroke(dropList, Theme.DropdownBorder, 1)
                MakePadding(dropList, 4, 4, 0, 0)

                local listLayout = MakeListLayout(dropList, 2)
                local dropObj

                local function CloseDropdown()
                    dropList.Visible = false
                    Tween(arrow, TweenInfo.new(0.1), { Rotation = 0 })
                end

                local function OpenDropdown()
                    dropList.Visible = true
                    Tween(arrow, TweenInfo.new(0.1), { Rotation = 180 })
                end

                local function UpdateLabel()
                    if multi then
                        if #multiSelected == 0 then
                            dropBtn.Text = "None"
                        else
                            local displayValues = {}
                            for _, selected in ipairs(multiSelected) do
                                table.insert(displayValues, formatDisplayValue and (formatDisplayValue(selected) or selected) or selected)
                            end
                            dropBtn.Text = table.concat(displayValues, ", ")
                        end
                    else
                        local display = formatDisplayValue and value and (formatDisplayValue(value) or value) or value
                        dropBtn.Text = tostring(display or "None")
                    end
                end

                local function RebuildList()
                    for _, c in pairs(dropList:GetChildren()) do
                        if c:IsA("TextButton") or c:IsA("Frame") or c:IsA("TextBox") then
                            c:Destroy()
                        end
                    end

                    local filteredOptions = {}
                    local filter = searchBox and string.lower(searchBox.Text) or ""
                    for _, opt in ipairs(options) do
                        if filter == "" or string.find(string.lower(tostring(opt)), filter, 1, true) then
                            table.insert(filteredOptions, opt)
                        end
                    end

                    if searchable then
                        searchBox = Create("TextBox", {
                            BackgroundColor3 = Theme.InputBg,
                            BorderSizePixel = 0,
                            Size = UDim2.new(1, 0, 0, 24),
                            PlaceholderText = "Search...",
                            Text = filter,
                            Font = Font.Regular,
                            TextSize = 11,
                            TextColor3 = Theme.TextPrimary,
                            Parent = dropList,
                        })
                        MakeRounded(searchBox, 4)
                        MakeStroke(searchBox, Theme.InputBorder, 1)
                        MakePadding(searchBox, 0, 0, 6, 6)
                        searchBox:GetPropertyChangedSignal("Text"):Connect(RebuildList)
                    end

                    local totalH = 0
                    for _, opt in ipairs(filteredOptions) do
                        local isSelected = multi and table.find(multiSelected, opt) ~= nil or opt == value
                        local item = Create("TextButton", {
                            BackgroundColor3 = isSelected and Theme.DropdownSelected or Theme.DropdownItem,
                            BackgroundTransparency = isSelected and 0.2 or 0,
                            Size = UDim2.new(1, 0, 0, 26),
                            Text = "  " .. tostring(formatDisplayValue and (formatDisplayValue(opt) or opt) or opt),
                            Font = Font.Regular,
                            TextSize = 11,
                            TextColor3 = disabledValues[tostring(opt)] and Theme.TextDisabled or (isSelected and Theme.AccentLight or Theme.TextPrimary),
                            TextXAlignment = Enum.TextXAlignment.Left,
                            AutoButtonColor = false,
                            ZIndex = 51,
                            Parent = dropList,
                        })
                        MakeRounded(item, 4)
                        MakePadding(item, 0, 0, 6, 6)

                        item.MouseEnter:Connect(function()
                            if not isSelected then
                                Tween(item, TweenInfo.new(0.1), { BackgroundTransparency = 0.6 })
                                item.BackgroundColor3 = Theme.DropdownItemHover
                            end
                        end)
                        item.MouseLeave:Connect(function()
                            if not isSelected then
                                Tween(item, TweenInfo.new(0.1), {
                                    BackgroundTransparency = 0,
                                    BackgroundColor3 = Theme.DropdownItem,
                                })
                            end
                        end)

                        item.MouseButton1Click:Connect(function()
                            if disabledValues[tostring(opt)] then
                                return
                            end
                            if multi then
                                local idx = table.find(multiSelected, opt)
                                if idx then
                                    table.remove(multiSelected, idx)
                                else
                                    table.insert(multiSelected, opt)
                                end
                                callback(multiSelected)
                            else
                                value = opt
                                CloseDropdown()
                                callback(value)
                            end
                            dropObj.Value = multi and multiSelected or value
                            FireChanged(dropObj, dropObj.Value)
                            UpdateLabel()
                            RebuildList()
                        end)

                        totalH = totalH + 28
                    end

                    local headerHeight = searchable and 30 or 0
                    local maxHeight = maxVisibleDropdownItems * 28
                    dropList.Size = UDim2.new(1, 0, 0, math.min(totalH + headerHeight + 8, maxHeight + headerHeight + 8))
                end

                RebuildList()

                dropBtn.MouseButton1Click:Connect(function()
                    if disabled then return end
                    if dropList.Visible then
                        CloseDropdown()
                    else
                        OpenDropdown()
                    end
                end)

                -- Close when clicking elsewhere
                UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local mousePos = UserInputService:GetMouseLocation()
                        if dropList.Visible and not PointInGui(dropBtn, mousePos) and not PointInGui(dropList, mousePos) then
                            task.defer(CloseDropdown)
                        end
                    end
                end)

                dropObj = EnsureObservable({
                    Value = value,
                    Set = function(self, v)
                        if multi and type(v) == "table" then
                            multiSelected = {}
                            for key, state in pairs(v) do
                                if state then
                                    table.insert(multiSelected, key)
                                end
                            end
                        else
                            if type(v) == "number" then
                                v = options[v]
                            end
                            value = v
                        end
                        UpdateLabel()
                        RebuildList()
                        self.Value = multi and multiSelected or value
                        callback(self.Value)
                        FireChanged(self, self.Value)
                    end,
                    SetValue = function(self, v)
                        self:Set(v)
                    end,
                    SetOptions = function(self, newOpts)
                        options = newOpts
                        RebuildList()
                    end,
                    GetValue = function(self)
                        if multi then
                            local mapped = {}
                            for _, selected in ipairs(multiSelected) do
                                mapped[selected] = true
                            end
                            return mapped
                        end
                        return value
                    end,
                })
                dropObj.Index = index
                sectionObj._library:_attachTooltip(dropBtn, disabled and disabledTooltip or tooltip, disabled and disabledTooltip or nil)
                UpdateLabel()
                return registerControl(dropObj, "dropdown", displayText, {
                    Flag = opts.Flag,
                    Index = index,
                    Save = opts.Save,
                })
            end

            -- ====================================================
            -- ADD TEXTBOX
            -- ====================================================
            function sectionObj:AddTextbox(label, opts)
                opts = opts or {}
                local index, displayText = NormalizeDisplayAndIndex(label, opts)
                local placeholder = opts.Placeholder or "Type here..."
                local default     = opts.Default or ""
                local callback    = opts.Callback or function() end
                local onFocus     = opts.OnFocus or function() end
                local onLoseFocus = opts.OnLoseFocus or function() end
                local numeric     = opts.Numeric or false
                local tooltip     = opts.Tooltip or nil
                local disabledTooltip = opts.DisabledTooltip or tooltip
                local disabled    = opts.Disabled ~= nil and opts.Disabled or false

                local container = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 32),
                    Parent = elemList,
                })
                MakePadding(container, 0, 0, 12, 12)

                local labelEl = Create("TextLabel", {
                    Text = displayText,
                    Font = Font.Regular,
                    TextSize = 12,
                    TextColor3 = disabled and Theme.TextDisabled or Theme.TextPrimary,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -108, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = container,
                })

                local inputFrame = Create("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = Theme.InputBg,
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0, 100, 0, 24),
                    Parent = container,
                })
                MakeRounded(inputFrame, 6)
                local inputStroke = MakeStroke(inputFrame, Theme.InputBorder, 1)
                local tbObj

                local textbox = Create("TextBox", {
                    BackgroundTransparency = 1,
                    PlaceholderText = placeholder,
                    PlaceholderColor3 = Theme.TextDisabled,
                    Text = default,
                    Font = Font.Regular,
                    TextSize = 11,
                    TextColor3 = Theme.TextPrimary,
                    Size = UDim2.new(1, 0, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ClearTextOnFocus = false,
                    Editable = not disabled,
                    Parent = inputFrame,
                })
                MakePadding(textbox, 2, 2, 6, 6)

                textbox.Focused:Connect(function()
                    Tween(inputStroke, TweenInfo.new(0.15), { Color = Theme.InputBorderFocus })
                    onFocus()
                end)
                textbox.FocusLost:Connect(function(enterPressed)
                    Tween(inputStroke, TweenInfo.new(0.15), { Color = Theme.InputBorder })
                    local text = textbox.Text
                    if numeric then
                        text = tonumber(text) or 0
                        textbox.Text = tostring(text)
                    end
                    tbObj.Value = text
                    callback(text, enterPressed)
                    FireChanged(tbObj, text, enterPressed)
                    onLoseFocus(text, enterPressed)
                end)

                tbObj = EnsureObservable({
                    _textbox = textbox,
                    Value = textbox.Text,
                    Set = function(self, v)
                        textbox.Text = tostring(v)
                        self.Value = textbox.Text
                        FireChanged(self, self:GetValue())
                    end,
                    SetValue = function(self, v)
                        self:Set(v)
                    end,
                    GetValue = function(self)
                        return numeric and (tonumber(textbox.Text) or 0) or textbox.Text
                    end,
                })
                tbObj.Index = index
                sectionObj._library:_attachTooltip(inputFrame, disabled and disabledTooltip or tooltip, disabled and disabledTooltip or nil)
                return registerControl(tbObj, "textbox", displayText, {
                    Flag = opts.Flag,
                    Index = index,
                    Save = opts.Save,
                })
            end

            -- ====================================================
            -- ADD KEYBIND
            -- ====================================================
            function sectionObj:AddKeybind(label, opts)
                opts = opts or {}
                local index, displayText = NormalizeDisplayAndIndex(label, opts)
                local default   = opts.Default or Enum.KeyCode.Unknown
                local callback  = opts.Callback or function() end
                local changedCallback = opts.ChangedCallback or function() end
                local holdCallback = opts.HoldCallback or nil
                local tooltip   = opts.Tooltip or nil
                local disabledTooltip = opts.DisabledTooltip or tooltip
                local disabled  = opts.Disabled ~= nil and opts.Disabled or false
                local syncToggleState = opts.SyncToggleState or false
                local parentToggle = opts.ParentToggle
                local modes = { "Toggle", "Hold", "Always", "Press" }

                local currentKey = default
                local currentMode = tostring(opts.Mode or "Toggle")
                local listening  = false
                local state      = false

                if type(default) == "table" then
                    currentKey = default.Key or default[1] or Enum.KeyCode.Unknown
                    currentMode = tostring(default.Mode or default[2] or currentMode)
                end
                currentKey = NormalizeKeybindToken(currentKey)
                if currentMode == "Always" then
                    state = true
                end

                local row = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 32),
                    Parent = elemList,
                })
                MakePadding(row, 0, 0, 12, 12)

                local labelEl = Create("TextLabel", {
                    Text = displayText,
                    Font = Font.Regular,
                    TextSize = 12,
                    TextColor3 = disabled and Theme.TextDisabled or Theme.TextPrimary,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -108, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = row,
                })

                local keyBtn = Create("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = Theme.KeybindBg,
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0, 92, 0, 24),
                    Text = "",
                    Font = Font.Regular,
                    TextSize = 11,
                    TextColor3 = Theme.TextPrimary,
                    AutoButtonColor = false,
                    Parent = row,
                })
                MakeRounded(keyBtn, 6)
                MakeStroke(keyBtn, Theme.KeybindBorder, 1)
                local kbStroke = keyBtn:FindFirstChildWhichIsA("UIStroke")
                local kbObj

                local function updateButtonText()
                    if listening then
                        keyBtn.Text = "..."
                    else
                        local keyText = currentKey == Enum.KeyCode.Unknown and "None" or KeyTokenToDisplay(currentKey)
                        keyBtn.Text = string.format("%s [%s]", keyText, currentMode)
                    end
                end

                local function syncParentToggle(newState)
                    if syncToggleState and parentToggle and parentToggle.SetValue then
                        parentToggle:SetValue(newState)
                    end
                end

                local function fireStateChanged(payload)
                    if kbObj then
                        kbObj.Value = currentKey
                        kbObj.Mode = currentMode
                    end
                    FireChanged(kbObj, payload)
                end

                local function SetKey(key, skipChanged)
                    currentKey = NormalizeKeybindToken(key)
                    listening = false
                    updateButtonText()
                    if kbStroke then
                        Tween(kbStroke, TweenInfo.new(0.15), { Color = Theme.KeybindBorder })
                    end
                    if not skipChanged then
                        changedCallback(currentKey, nil)
                        fireStateChanged({
                            Key = KeyTokenToDisplay(currentKey),
                            Mode = currentMode,
                        })
                    end
                end

                local function SetMode(mode, fireCallback)
                    mode = tostring(mode or currentMode)
                    if not table.find(modes, mode) then
                        mode = "Toggle"
                    end
                    currentMode = mode
                    if mode == "Always" then
                        state = true
                        syncParentToggle(true)
                    elseif mode ~= "Toggle" then
                        state = false
                        syncParentToggle(false)
                    end
                    updateButtonText()
                    if fireCallback then
                        callback(state, currentKey, currentMode)
                        fireStateChanged({
                            Key = KeyTokenToDisplay(currentKey),
                            Mode = currentMode,
                            State = state,
                        })
                    end
                end

                local function FireHoldLoop()
                    if not holdCallback then
                        return
                    end
                    task.spawn(function()
                        while state and currentMode == "Hold" do
                            holdCallback(currentKey)
                            task.wait(0.05)
                        end
                    end)
                end

                if not disabled then
                    keyBtn.MouseButton1Click:Connect(function()
                        if listening then
                            SetKey(Enum.KeyCode.Unknown)
                            return
                        end
                        listening = true
                        updateButtonText()
                        if kbStroke then
                            Tween(kbStroke, TweenInfo.new(0.15), { Color = Theme.Accent })
                        end
                    end)
                    keyBtn.MouseButton2Click:Connect(function()
                        local idx = table.find(modes, currentMode) or 1
                        idx = idx % #modes + 1
                        SetMode(modes[idx], true)
                    end)

                    UserInputService.InputBegan:Connect(function(input, gpe)
                        if gpe then return end
                        local token = GetInputToken(input)
                        if listening then
                            SetKey(token)
                        elseif token == currentKey then
                            if currentMode == "Press" then
                                callback(true, currentKey, currentMode)
                                fireStateChanged({
                                    Key = KeyTokenToDisplay(currentKey),
                                    Mode = currentMode,
                                    State = true,
                                })
                            elseif currentMode == "Hold" then
                                state = true
                                syncParentToggle(true)
                                callback(true, currentKey, currentMode)
                                fireStateChanged({
                                    Key = KeyTokenToDisplay(currentKey),
                                    Mode = currentMode,
                                    State = true,
                                })
                                FireHoldLoop()
                            elseif currentMode == "Toggle" then
                                state = not state
                                syncParentToggle(state)
                                callback(state, currentKey, currentMode)
                                fireStateChanged({
                                    Key = KeyTokenToDisplay(currentKey),
                                    Mode = currentMode,
                                    State = state,
                                })
                            elseif currentMode == "Always" then
                                state = true
                                syncParentToggle(true)
                                callback(true, currentKey, currentMode)
                                fireStateChanged({
                                    Key = KeyTokenToDisplay(currentKey),
                                    Mode = currentMode,
                                    State = true,
                                })
                            end
                        end
                    end)

                    UserInputService.InputEnded:Connect(function(input)
                        local token = GetInputToken(input)
                        if token == currentKey and currentMode == "Hold" then
                            state = false
                            syncParentToggle(false)
                            callback(false, currentKey, currentMode)
                            fireStateChanged({
                                Key = KeyTokenToDisplay(currentKey),
                                Mode = currentMode,
                                State = false,
                            })
                        end
                    end)
                end

                updateButtonText()

                kbObj = EnsureObservable({
                    Value = currentKey,
                    Mode = currentMode,
                    Set = function(self, key)
                        if type(key) == "table" then
                            SetKey(key.Key or key[1] or currentKey, true)
                            SetMode(key.Mode or key[2] or currentMode, false)
                        else
                            SetKey(key, true)
                        end
                        self.Value = currentKey
                        self.Mode = currentMode
                        fireStateChanged({
                            Key = KeyTokenToDisplay(currentKey),
                            Mode = currentMode,
                            State = state,
                        })
                    end,
                    SetValue = function(self, key)
                        self:Set(key)
                    end,
                    GetValue = function(self)
                        return {
                            Key = KeyTokenToDisplay(currentKey),
                            Mode = currentMode,
                        }
                    end,
                    GetState = function(self)
                        return currentMode == "Always" and true or state
                    end,
                    SetMode = function(self, mode)
                        SetMode(mode, false)
                        self.Mode = currentMode
                        fireStateChanged({
                            Key = KeyTokenToDisplay(currentKey),
                            Mode = currentMode,
                            State = state,
                        })
                    end,
                    OnClick = function(self, fn)
                        return self:OnChanged(function(payload)
                            if type(payload) == "table" and payload.Mode == "Toggle" then
                                fn(payload.State)
                            end
                        end)
                    end,
                })
                kbObj.Index = index
                sectionObj._library:_attachTooltip(keyBtn, disabled and disabledTooltip or tooltip, disabled and disabledTooltip or nil)
                return registerControl(kbObj, "keybind", displayText, {
                    Flag = opts.Flag,
                    Index = index,
                    Save = opts.Save,
                })
            end

            -- ====================================================
            -- ADD COLOR PICKER
            -- ====================================================
            function sectionObj:AddColorPicker(label, opts)
                opts = opts or {}
                local index, displayText = NormalizeDisplayAndIndex(label, opts)
                local default  = opts.Default or Color3.fromRGB(148, 100, 220)
                local callback = opts.Callback or function() end
                local tooltip  = opts.Tooltip or nil
                local disabledTooltip = opts.DisabledTooltip or tooltip
                local disabled = opts.Disabled ~= nil and opts.Disabled or false

                local value = default
                local hue, sat, val2 = Color3.toHSV(value)

                local container = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 32),
                    ClipsDescendants = false,
                    ZIndex = 10,
                    Parent = elemList,
                })
                MakePadding(container, 0, 0, 12, 12)

                local labelEl = Create("TextLabel", {
                    Text = displayText,
                    Font = Font.Regular,
                    TextSize = 12,
                    TextColor3 = disabled and Theme.TextDisabled or Theme.TextPrimary,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -50, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = container,
                })

                -- Color preview swatch
                local swatch = Create("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = value,
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0, 38, 0, 20),
                    Text = "",
                    AutoButtonColor = false,
                    Parent = container,
                })
                MakeRounded(swatch, 5)
                MakeStroke(swatch, Theme.InputBorder, 1)

                -- Picker popup
                local picker = Create("Frame", {
                    BackgroundColor3 = Theme.DropdownBg,
                    Position = UDim2.new(1, -142, 1, 4),
                    Size = UDim2.new(0, 142, 0, 130),
                    ClipsDescendants = false,
                    ZIndex = 100,
                    Visible = false,
                    Parent = container,
                })
                MakeRounded(picker, 8)
                MakeStroke(picker, Theme.DropdownBorder, 1)
                MakePadding(picker, 8, 8, 8, 8)

                -- SV gradient (saturation/value)
                local svField = Create("ImageLabel", {
                    BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
                    Size = UDim2.new(1, 0, 0, 80),
                    Image = "rbxassetid://4155801252",
                    ZIndex = 101,
                    Parent = picker,
                })
                MakeRounded(svField, 4)

                local svKnob = Create("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Position = UDim2.new(sat, 0, 1 - val2, 0),
                    Size = UDim2.new(0, 10, 0, 10),
                    ZIndex = 102,
                    Parent = svField,
                })
                MakeRounded(svKnob, 5)
                MakeStroke(svKnob, Color3.new(1, 1, 1), 1.5)

                -- Hue slider
                local hueBar = Create("ImageLabel", {
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Position = UDim2.new(0, 0, 0, 88),
                    Size = UDim2.new(1, 0, 0, 8),
                    Image = "rbxassetid://4155881758",
                    ZIndex = 101,
                    Parent = picker,
                })
                MakeRounded(hueBar, 4)

                local hueKnob = Create("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Position = UDim2.new(hue, 0, 0.5, 0),
                    Size = UDim2.new(0, 8, 0, 14),
                    ZIndex = 102,
                    Parent = hueBar,
                })
                MakeRounded(hueKnob, 3)
                MakeStroke(hueKnob, Color3.new(1, 1, 1), 1)

                local cpObj
                local function UpdateColor()
                    value = Color3.fromHSV(hue, sat, val2)
                    swatch.BackgroundColor3 = value
                    svField.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                    svKnob.Position = UDim2.new(sat, 0, 1 - val2, 0)
                    hueKnob.Position = UDim2.new(hue, 0, 0.5, 0)
                    if cpObj then
                        cpObj.Value = value
                    end
                    callback(value)
                    FireChanged(cpObj, value)
                end

                -- SV interaction
                local svDragging = false
                svField.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        svDragging = true
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        svDragging = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if svDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local abs = svField.AbsolutePosition
                        local sz  = svField.AbsoluteSize
                        sat  = Clamp((input.Position.X - abs.X) / sz.X, 0, 1)
                        val2 = 1 - Clamp((input.Position.Y - abs.Y) / sz.Y, 0, 1)
                        UpdateColor()
                    end
                end)

                -- Hue interaction
                local hueDragging = false
                hueBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        hueDragging = true
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        hueDragging = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if hueDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local abs = hueBar.AbsolutePosition
                        local sz  = hueBar.AbsoluteSize
                        hue = Clamp((input.Position.X - abs.X) / sz.X, 0, 1)
                        UpdateColor()
                    end
                end)

                swatch.MouseButton1Click:Connect(function()
                    if disabled then return end
                    picker.Visible = not picker.Visible
                end)

                cpObj = EnsureObservable({
                    Value = value,
                    Transparency = opts.Transparency or 0,
                    Set = function(self, color)
                        value = color
                        hue, sat, val2 = Color3.toHSV(color)
                        UpdateColor()
                        FireChanged(self, value)
                    end,
                    SetValue = function(self, color)
                        self:Set(color)
                    end,
                    SetValueRGB = function(self, color)
                        self:Set(color)
                    end,
                    GetValue = function(self)
                        return value
                    end,
                })
                cpObj.Index = index
                sectionObj._library:_attachTooltip(swatch, disabled and disabledTooltip or tooltip, disabled and disabledTooltip or nil)
                return registerControl(cpObj, "colorpicker", displayText, {
                    Flag = opts.Flag,
                    Index = index,
                    Save = opts.Save,
                })
            end

            -- ====================================================
            -- ADD HOLD BUTTON (for FPS macros)
            -- ====================================================
            function sectionObj:AddHoldButton(label, opts)
                opts = opts or {}
                local onStart   = opts.OnStart or function() end
                local onStop    = opts.OnStop or function() end
                local tooltip   = opts.Tooltip or nil
                local disabledTooltip = opts.DisabledTooltip or tooltip
                local disabled  = opts.Disabled ~= nil and opts.Disabled or false

                local holding = false

                local row = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 32),
                    Parent = elemList,
                })
                MakePadding(row, 0, 0, 12, 12)

                local labelEl = Create("TextLabel", {
                    Text = label,
                    Font = Font.Regular,
                    TextSize = 12,
                    TextColor3 = disabled and Theme.TextDisabled or Theme.TextPrimary,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -108, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = row,
                })

                local holdBtn = Create("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = Theme.ButtonBg,
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0, 96, 0, 24),
                    Text = "Hold",
                    Font = Font.Regular,
                    TextSize = 11,
                    TextColor3 = Theme.TextPrimary,
                    AutoButtonColor = false,
                    Parent = row,
                })
                MakeRounded(holdBtn, 6)
                MakeStroke(holdBtn, Theme.ButtonBorder, 1)

                if not disabled then
                    holdBtn.MouseButton1Down:Connect(function()
                        if holding then return end
                        holding = true
                        Tween(holdBtn, TweenInfo.new(0.1), { BackgroundColor3 = Theme.Accent })
                        holdBtn.Text = "Holding"
                        onStart()
                    end)
                    holdBtn.MouseButton1Up:Connect(function()
                        holding = false
                        Tween(holdBtn, TweenInfo.new(0.1), { BackgroundColor3 = Theme.ButtonBg })
                        holdBtn.Text = "Hold"
                        onStop()
                    end)
                    holdBtn.MouseLeave:Connect(function()
                        if holding then return end
                        Tween(holdBtn, TweenInfo.new(0.1), { BackgroundColor3 = Theme.ButtonBg })
                    end)
                end

                local holdObj = {
                    IsHolding = function(self) return holding end,
                }
                sectionObj._library:_attachTooltip(holdBtn, disabled and disabledTooltip or tooltip, disabled and disabledTooltip or nil)
                return holdObj
            end

            -- ====================================================
            -- ADD TOGGLE-BUTTON (Multi-option selector, like "Silent Aim")
            -- ====================================================
            function sectionObj:AddOptionButton(label, opts)
                opts = opts or {}
                local index, displayText = NormalizeDisplayAndIndex(label, opts)
                local options   = opts.Options or opts.Values or {"Option 1"}
                local default   = opts.Default or options[1]
                local callback  = opts.Callback or function() end
                local tooltip   = opts.Tooltip or nil
                local disabledTooltip = opts.DisabledTooltip or tooltip
                local disabled  = opts.Disabled ~= nil and opts.Disabled or false

                local value = default

                local container = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 32),
                    Parent = elemList,
                })
                MakePadding(container, 0, 0, 12, 12)

                local labelEl = Create("TextLabel", {
                    Text = displayText,
                    Font = Font.Regular,
                    TextSize = 12,
                    TextColor3 = disabled and Theme.TextDisabled or Theme.TextPrimary,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -108, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = container,
                })

                local optBtn = Create("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = Theme.ButtonBg,
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0, 96, 0, 24),
                    Text = value,
                    Font = Font.Regular,
                    TextSize = 11,
                    TextColor3 = Theme.TextAccent,
                    AutoButtonColor = false,
                    Parent = container,
                })
                MakeRounded(optBtn, 6)
                MakeStroke(optBtn, Theme.ButtonBorder, 1)
                local optionButtonObj

                if not disabled then
                    optBtn.MouseButton1Click:Connect(function()
                        local idx = table.find(options, value) or 1
                        idx = idx % #options + 1
                        value = options[idx]
                        optBtn.Text = value
                        callback(value)
                        optionButtonObj.Value = value
                        FireChanged(optionButtonObj, value)
                    end)
                    optBtn.MouseEnter:Connect(function()
                        Tween(optBtn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.ButtonBgHover })
                    end)
                    optBtn.MouseLeave:Connect(function()
                        Tween(optBtn, TweenInfo.new(0.12), { BackgroundColor3 = Theme.ButtonBg })
                    end)
                end

                optionButtonObj = EnsureObservable({
                    Value = value,
                    Set = function(self, v)
                        value = v
                        optBtn.Text = v
                        self.Value = value
                        FireChanged(self, value)
                    end,
                    SetValue = function(self, v)
                        self:Set(v)
                    end,
                    GetValue = function(self) return value end,
                })
                optionButtonObj.Index = index
                sectionObj._library:_attachTooltip(optBtn, disabled and disabledTooltip or tooltip, disabled and disabledTooltip or nil)
                return registerControl(optionButtonObj, "optionbutton", displayText, {
                    Flag = opts.Flag,
                    Index = index,
                    Save = opts.Save,
                })
            end

            -- ====================================================
            -- ADD BIND (FPS-specific: keyboard+mouse combo)
            -- ====================================================
            function sectionObj:AddBind(label, opts)
                return self:AddKeybind(label, opts)
            end

            function sectionObj:AddCheckbox(label, opts)
                return self:AddToggle(label, opts)
            end

            function sectionObj:AddInput(label, opts)
                return self:AddTextbox(label, opts)
            end

            function sectionObj:AddDivider()
                return self:AddSeparator()
            end

            function sectionObj:AddKeyPicker(label, opts)
                return self:AddKeybind(label, opts)
            end

            table.insert(tabObj._sections, sectionObj)
            return self._library:_extendSection(sectionObj)
        end

        function tabObj:AddLeftGroupbox(name)
            return self:AddSection(name, "Left")
        end

        function tabObj:AddRightGroupbox(name)
            return self:AddSection(name, "Right")
        end

        local function createTabbox(column)
            local parent = column == "Right" and tabObj._rightCol or tabObj._leftCol
            local host = Create("Frame", {
                Name = "Tabbox",
                BackgroundColor3 = Theme.SectionBg,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                ClipsDescendants = false,
                Parent = parent,
            })
            MakeRounded(host, 10)
            MakeStroke(host, Theme.SectionBorder, 1)
            MakePadding(host, 10, 12, 10, 10)

            local header = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 24),
                Parent = host,
            })
            local headerLayout = MakeListLayout(header, 6, Enum.FillDirection.Horizontal)

            local pages = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = host,
            })
            MakePadding(pages, 8, 0, 0, 0)

            local tabbox = {
                _host = host,
                _header = header,
                _pages = {},
                _active = nil,
            }

            function tabbox:AddTab(tabName)
                local button = Create("TextButton", {
                    BackgroundColor3 = Theme.ButtonBg,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2.new(0, 0, 1, 0),
                    Text = "  " .. tostring(tabName) .. "  ",
                    Font = Font.Regular,
                    TextSize = 11,
                    TextColor3 = Theme.TextSecondary,
                    AutoButtonColor = false,
                    Parent = header,
                })
                MakeRounded(button, 6)
                MakeStroke(button, Theme.ButtonBorder, 1)

                local proxy = tabObj:AddSection(tabName, column)
                proxy._frame.Parent = pages
                proxy._frame.Visible = false

                local function selectPage()
                    for _, page in ipairs(tabbox._pages) do
                        page.section._frame.Visible = false
                        page.button.BackgroundColor3 = Theme.ButtonBg
                        page.button.TextColor3 = Theme.TextSecondary
                    end
                    proxy._frame.Visible = true
                    button.BackgroundColor3 = Theme.Accent
                    button.TextColor3 = Theme.ToggleKnob
                    tabbox._active = proxy
                end

                button.MouseButton1Click:Connect(selectPage)
                table.insert(tabbox._pages, {
                    button = button,
                    section = proxy,
                })

                if not tabbox._active then
                    selectPage()
                end

                return proxy
            end

            return tabbox
        end

        function tabObj:AddLeftTabbox()
            return createTabbox("Left")
        end

        function tabObj:AddRightTabbox()
            return createTabbox("Right")
        end

        local function ensureInlineSection()
            tabObj._inlineSection = tabObj._inlineSection or tabObj:AddSection("General", "Left")
            return tabObj._inlineSection
        end

        function tabObj:AddLabel(...)
            return ensureInlineSection():AddLabel(...)
        end

        function tabObj:AddButton(...)
            return ensureInlineSection():AddButton(...)
        end

        return tabObj
    end

    function windowObj:AddKeyTab(name, iconId)
        local keyTab = self:AddTab(name, iconId)
        function keyTab:AddKeyBox(callback)
            local section = self._keyBoxSection
            if not section then
                section = self:AddSection("Key", "Left")
                self._keyBoxSection = section
            end
            return section:AddTextbox("Key Input", {
                Placeholder = "Enter key",
                Callback = function(value, enterPressed)
                    if enterPressed then
                        callback(value)
                    end
                end,
                Save = false,
            })
        end
        return keyTab
    end

    -- Toggle window visibility
    function windowObj:Toggle()
        windowFrame.Visible = not windowFrame.Visible
    end

    function windowObj:Hide()
        Tween(windowFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, width * 0.95, 0, height * 0.95),
        }, function()
            windowFrame.Visible = false
            windowFrame.BackgroundTransparency = 0
            windowFrame.Size = UDim2.new(0, width, 0, height)
        end)
    end

    function windowObj:Show()
        windowFrame.Visible = true
        windowFrame.BackgroundTransparency = 1
        windowFrame.Size = UDim2.new(0, width * 0.95, 0, height * 0.95)
        Tween(windowFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
            BackgroundTransparency = 0,
            Size = UDim2.new(0, width, 0, height),
        })
    end

    function windowObj:Destroy()
        windowFrame:Destroy()
    end

    table.insert(Library._windows, windowObj)
    return windowObj
end

-- ============================================================
-- FPS UTILITIES (built-in for FPS games)
-- ============================================================

Library.FPS = {}

-- ESP drawing utility (placeholder API surface)
function Library.FPS:CreateESP(options)
    options = options or {}
    local espObj = {
        Enabled = false,
        ShowNames   = options.ShowNames or true,
        ShowHealth  = options.ShowHealth or true,
        ShowBoxes   = options.ShowBoxes or true,
        ShowTracers = options.ShowTracers or false,
        TeamColor   = options.TeamColor or false,
        Color       = options.Color or Color3.fromRGB(255, 75, 75),
        
        _drawings = {},

        Enable = function(self)
            self.Enabled = true
        end,
        Disable = function(self)
            self.Enabled = false
            for _, d in pairs(self._drawings) do
                pcall(function() d:Remove() end)
            end
            self._drawings = {}
        end,
    }
    return espObj
end

-- Aim utility (aimbot surface)
function Library.FPS:CreateAimbot(options)
    options = options or {}
    local aimObj = {
        Enabled     = false,
        FOV         = options.FOV or 180,
        Smoothing   = options.Smoothing or 0.15,
        Target      = options.Target or "Head",
        TeamCheck   = options.TeamCheck or true,
        VisCheck    = options.VisCheck or false,
        
        Enable = function(self)
            self.Enabled = true
        end,
        Disable = function(self)
            self.Enabled = false
        end,
        GetNearestTarget = function(self)
            local nearest, dist = nil, math.huge
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local char = player.Character
                    if char then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local _, onScreen = workspace.CurrentCamera:WorldToScreenPoint(hrp.Position)
                            if onScreen then
                                local screenPos = workspace.CurrentCamera:WorldToScreenPoint(hrp.Position)
                                local center = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
                                local d2 = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                                if d2 < self.FOV and d2 < dist then
                                    if not self.TeamCheck or player.Team ~= LocalPlayer.Team then
                                        nearest = player
                                        dist = d2
                                    end
                                end
                            end
                        end
                    end
                end
            end
            return nearest
        end,
    }
    return aimObj
end

-- FOV circle
function Library.FPS:CreateFOVCircle(radius, color)
    radius = radius or 180
    color = color or Color3.fromRGB(255, 255, 255)
    local circle = nil
    local ok = pcall(function()
        circle = Drawing.new("Circle")
        circle.Radius = radius
        circle.Color = color
        circle.Thickness = 1
        circle.Filled = false
        circle.Visible = true
        circle.Position = Vector2.new(
            workspace.CurrentCamera.ViewportSize.X / 2,
            workspace.CurrentCamera.ViewportSize.Y / 2
        )
    end)
    if not ok then circle = nil end
    return {
        _circle = circle,
        SetRadius = function(self, r)
            if self._circle then self._circle.Radius = r end
        end,
        SetVisible = function(self, v)
            if self._circle then self._circle.Visible = v end
        end,
        Destroy = function(self)
            if self._circle then self._circle:Remove() end
        end,
    }
end

-- ============================================================
-- THEME MANAGEMENT
-- ============================================================

function Library:SetTheme(newTheme)
    for k, v in pairs(newTheme) do
        if Theme[k] then
            Theme[k] = v
        end
    end
end

function Library:GetTheme()
    return Theme
end

Library.Theme = function()
    return Theme
end

-- ============================================================
-- KEYBIND (Global toggle for UI)
-- ============================================================

function Library:SetToggleKey(key)
    self._toggleKey = NormalizeKeybindToken(key or Enum.KeyCode.RightShift)
    if self._toggleConn then
        self._toggleConn:Disconnect()
        self._toggleConn = nil
    end
    self._toggleConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if GetInputToken(input) == self._toggleKey then
            for _, w in pairs(self._windows) do
                w:Toggle()
            end
        end
    end)
end

function Library:OnUnload(callback)
    if type(callback) == "function" then
        table.insert(self._unloadCallbacks, callback)
    end
    return self
end

function Library:AddDraggableLabel(text)
    if not self._gui then
        self:Init()
    end
    local frame = Create("Frame", {
        BackgroundColor3 = Theme.BackgroundSecond,
        Position = UDim2.new(0, 24, 0, 24),
        Size = UDim2.new(0, 180, 0, 28),
        Parent = self._gui,
    })
    MakeRounded(frame, 6)
    MakeStroke(frame, Theme.WindowBorder, 1)
    local label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = text,
        Font = Font.Regular,
        TextSize = 12,
        TextColor3 = Theme.TextPrimary,
        Parent = frame,
    })
    MakeDraggable(frame, frame)
    return {
        _frame = frame,
        SetText = function(self, newText)
            label.Text = newText
        end,
        Destroy = function(self)
            frame:Destroy()
        end,
    }
end

function Library:Unload()
    if self.Unloaded then
        return
    end
    self.Unloaded = true
    for _, callback in ipairs(self._unloadCallbacks) do
        pcall(callback)
    end
    self:Destroy()
end

-- ============================================================
-- DESTROY ALL
-- ============================================================

function Library:Destroy()
    if self._toggleConn then
        self._toggleConn:Disconnect()
        self._toggleConn = nil
    end
    if self._gui then
        self._gui:Destroy()
        self._gui = nil
    end
    self._windows = {}
    self._controlRegistry = {}
    self.Options = {}
    self.Toggles = {}
    self.Flags = {}
end

-- ============================================================
-- EXTENDED COMPONENTS (built into main library)
-- ============================================================

-- ====================================================
-- WATERMARK
-- ====================================================

local WatermarkClass = {}
WatermarkClass.__index = WatermarkClass

function Library:CreateWatermark(opts)
    opts = opts or {}
    local text     = opts.Text or "Kojo Hub | v" .. Library.Version
    local position = opts.Position or UDim2.new(1, -12, 0, 12)
    local anchor   = opts.AnchorPoint or Vector2.new(1, 0)

    if not self._gui then self:Init() end
    local gui = self._gui

    local frame = Create("Frame", {
        Name = "Watermark",
        AnchorPoint = anchor,
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.15,
        Position = position,
        Size = UDim2.new(0, 0, 0, 24),
        AutomaticSize = Enum.AutomaticSize.X,
        ZIndex = 999,
        Parent = gui,
    })
    MakeRounded(frame, 5)
    MakeStroke(frame, Theme.WindowBorder, 1)
    MakePadding(frame, 0, 0, 10, 10)

    local label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Text = text,
        Font = Font.SemiBold,
        TextSize = 12,
        TextColor3 = Theme.Accent,
        Parent = frame,
    })

    local wmObj = setmetatable({}, WatermarkClass)
    wmObj._frame = frame
    wmObj._label = label

    function wmObj:SetText(t)
        label.Text = t
    end
    function wmObj:SetVisible(v)
        frame.Visible = v
    end
    function wmObj:Destroy()
        frame:Destroy()
    end

    return wmObj
end

-- ====================================================
-- FPS COUNTER
-- ====================================================

local FPSCounterClass = {}
FPSCounterClass.__index = FPSCounterClass

function Library:CreateFPSCounter(opts)
    opts = opts or {}
    local position = opts.Position or UDim2.new(0, 12, 0, 12)

    if not self._gui then self:Init() end
    local gui = self._gui

    local frame = Create("Frame", {
        Name = "FPSCounter",
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.15,
        Position = position,
        Size = UDim2.new(0, 72, 0, 24),
        ZIndex = 999,
        Parent = gui,
    })
    MakeRounded(frame, 5)
    MakeStroke(frame, Theme.WindowBorder, 1)

    local label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "FPS: --",
        Font = Font.SemiBold,
        TextSize = 11,
        TextColor3 = Theme.NotifSuccess,
        Parent = frame,
    })

    local fpsObj = setmetatable({}, FPSCounterClass)
    fpsObj._frame = frame
    fpsObj._label = label
    fpsObj._enabled = false
    fpsObj._conn = nil

    local lastTime = tick()
    local frameCount = 0

    function fpsObj:Enable()
        if self._enabled then return end
        self._enabled = true
        self._conn = RunService.RenderStepped:Connect(function()
            frameCount = frameCount + 1
            local now = tick()
            local dt = now - lastTime
            if dt >= 0.5 then
                local fps = math.round(frameCount / dt)
                frameCount = 0
                lastTime = now
                local fpsColor = Theme.NotifSuccess
                if fps < 30 then
                    fpsColor = Theme.NotifError
                elseif fps < 50 then
                    fpsColor = Theme.NotifWarning
                end
                label.Text = "FPS: " .. fps
                label.TextColor3 = fpsColor
            end
        end)
    end

    function fpsObj:Disable()
        self._enabled = false
        if self._conn then
            self._conn:Disconnect()
            self._conn = nil
        end
    end

    function fpsObj:SetVisible(v)
        frame.Visible = v
    end

    function fpsObj:Destroy()
        self:Disable()
        frame:Destroy()
    end

    fpsObj:Enable()
    return fpsObj
end

-- ====================================================
-- CONFIG SYSTEM
-- ====================================================

local ConfigClass = {}
ConfigClass.__index = ConfigClass

function Library:CreateConfig(opts)
    opts = opts or {}
    local folderName = opts.Folder or "KojoHub"
    local configName = opts.Name or "default"

    local ok = pcall(function()
        if not isfolder(folderName) then
            makefolder(folderName)
        end
    end)

    local cfg = setmetatable({}, ConfigClass)
    cfg._library = self
    cfg._folder = folderName
    cfg._name = configName
    cfg._data = {}
    cfg._ignoreFlags = {}
    cfg._autoloadPath = folderName .. "/autoload.txt"

    function cfg:Set(flag, value)
        self._data[flag] = value
    end

    function cfg:Get(flag)
        return self._data[flag]
    end

    function cfg:SetIgnoreFlags(flags)
        self._ignoreFlags = {}
        for _, flag in ipairs(flags or {}) do
            self._ignoreFlags[SanitizeFlag(flag)] = true
        end
        return self
    end

    function cfg:IgnoreFlag(flag)
        self._ignoreFlags[SanitizeFlag(flag)] = true
        return self
    end

    function cfg:Collect()
        local snapshot = self._library:_snapshotControls(self._ignoreFlags)
        for flag, value in pairs(snapshot) do
            self._data[flag] = value
        end
        return self._data
    end

    function cfg:Apply(data)
        self._library:_applySnapshot(data or self._data, self._ignoreFlags)
        return true
    end

    function cfg:Save(name)
        name = name or self._name
        local path = self._folder .. "/" .. name .. ".json"
        local saveOk = pcall(function()
            local encoded = HttpService:JSONEncode(self:Collect())
            writefile(path, encoded)
        end)
        return saveOk
    end

    function cfg:Load(name)
        name = name or self._name
        local path = self._folder .. "/" .. name .. ".json"
        local loadOk, result = pcall(function()
            if isfile(path) then
                local content = readfile(path)
                return HttpService:JSONDecode(content)
            end
            return nil
        end)
        if loadOk and result then
            self._data = result
            self:Apply(result)
            return true
        end
        return false
    end

    function cfg:Delete(name)
        name = name or self._name
        local path = self._folder .. "/" .. name .. ".json"
        local delOk = pcall(function()
            delfile(path)
        end)
        return delOk
    end

    function cfg:ListConfigs()
        local configs = {}
        pcall(function()
            for _, file in pairs(listfiles(self._folder)) do
                if file:sub(-5) == ".json" then
                    local n = file:gsub(self._folder .. "/", ""):gsub(".json", "")
                    table.insert(configs, n)
                end
            end
        end)
        return configs
    end

    function cfg:SetAutoload(name)
        local target = name or self._name
        return pcall(function()
            writefile(self._autoloadPath, tostring(target))
        end)
    end

    function cfg:GetAutoload()
        local okRead, value = pcall(function()
            if isfile(self._autoloadPath) then
                return readfile(self._autoloadPath)
            end
        end)
        return okRead and value or nil
    end

    function cfg:ClearAutoload()
        return pcall(function()
            if isfile(self._autoloadPath) then
                delfile(self._autoloadPath)
            end
        end)
    end

    function cfg:LoadAutoload()
        local autoload = self:GetAutoload()
        if autoload and autoload ~= "" then
            return self:Load(autoload)
        end
        return false
    end

    return cfg
end

-- ====================================================
-- ANTI-AFK
-- ====================================================

function Library:EnableAntiAFK()
    local VirtualUser = game:GetService("VirtualUser")
    local player = Players.LocalPlayer
    player.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(0.1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end

-- ====================================================
-- SPEED HACK
-- ====================================================

local SpeedHackClass = {}
SpeedHackClass.__index = SpeedHackClass

function Library:CreateSpeedHack(opts)
    opts = opts or {}
    local sh = setmetatable({}, SpeedHackClass)
    sh._speed = opts.DefaultSpeed or 16
    sh._enabled = false
    sh._conn = nil

    function sh:Enable(speed)
        speed = speed or self._speed
        self._speed = speed
        self._enabled = true
        if self._conn then self._conn:Disconnect() end
        self._conn = RunService.Heartbeat:Connect(function()
            local char = Players.LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = speed end
            end
        end)
    end

    function sh:Disable()
        self._enabled = false
        if self._conn then
            self._conn:Disconnect()
            self._conn = nil
        end
        local char = Players.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end

    function sh:SetSpeed(s)
        self._speed = s
        if self._enabled then self:Enable(s) end
    end

    return sh
end

-- ====================================================
-- NOCLIP
-- ====================================================

local NoclipClass = {}
NoclipClass.__index = NoclipClass

function Library:CreateNoclip()
    local nc = setmetatable({}, NoclipClass)
    nc._enabled = false
    nc._conn = nil

    function nc:Enable()
        if self._enabled then return end
        self._enabled = true
        self._conn = RunService.Stepped:Connect(function()
            local char = Players.LocalPlayer.Character
            if char then
                for _, p in pairs(char:GetDescendants()) do
                    if p:IsA("BasePart") and p.CanCollide then
                        p.CanCollide = false
                    end
                end
            end
        end)
    end

    function nc:Disable()
        self._enabled = false
        if self._conn then
            self._conn:Disconnect()
            self._conn = nil
        end
        local char = Players.LocalPlayer.Character
        if char then
            for _, p in pairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = true
                end
            end
        end
    end

    return nc
end

-- ====================================================
-- FLY HACK
-- ====================================================

local FlyHackClass = {}
FlyHackClass.__index = FlyHackClass

function Library:CreateFlyHack(opts)
    opts = opts or {}
    local fly = setmetatable({}, FlyHackClass)
    fly._speed = opts.Speed or 50
    fly._enabled = false
    fly._bv = nil
    fly._bg = nil
    fly._conn = nil

    function fly:Enable()
        if self._enabled then return end
        self._enabled = true
        local player = Players.LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local hum = char:WaitForChild("Humanoid")
        hum.PlatformStand = true

        local bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.P = 9e4
        bg.Parent = hrp
        self._bg = bg

        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Parent = hrp
        self._bv = bv

        local uis = UserInputService
        local cam = workspace.CurrentCamera

        self._conn = RunService.Heartbeat:Connect(function()
            local speed = self._speed
            local moveDir = Vector3.new(0, 0, 0)
            if uis:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
            if uis:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
            if uis:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
            if uis:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
            if uis:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if uis:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
            if moveDir.Magnitude > 0 then
                bv.Velocity = moveDir.Unit * speed
            else
                bv.Velocity = Vector3.new(0, 0, 0)
            end
            bg.CFrame = cam.CFrame
        end)
    end

    function fly:Disable()
        if not self._enabled then return end
        self._enabled = false
        if self._conn then self._conn:Disconnect(); self._conn = nil end
        local char = Players.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
        end
        if self._bv then self._bv:Destroy(); self._bv = nil end
        if self._bg then self._bg:Destroy(); self._bg = nil end
    end

    function fly:SetSpeed(s) self._speed = s end
    function fly:Toggle()
        if self._enabled then self:Disable() else self:Enable() end
    end

    return fly
end

-- ====================================================
-- CLICK TELEPORT
-- ====================================================

local ClickTpClass = {}
ClickTpClass.__index = ClickTpClass

function Library:CreateClickTeleport(opts)
    opts = opts or {}
    local ctp = setmetatable({}, ClickTpClass)
    ctp._enabled = false
    ctp._conn = nil

    function ctp:Enable()
        if self._enabled then return end
        self._enabled = true
        local mouse = Players.LocalPlayer:GetMouse()
        self._conn = mouse.Button1Down:Connect(function()
            if not self._enabled then return end
            local hit = mouse.Hit
            if hit then
                local char = Players.LocalPlayer.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.CFrame = hit * CFrame.new(0, 3, 0) end
                end
            end
        end)
    end

    function ctp:Disable()
        self._enabled = false
        if self._conn then self._conn:Disconnect(); self._conn = nil end
    end

    function ctp:Toggle()
        if self._enabled then self:Disable() else self:Enable() end
    end

    return ctp
end

-- ====================================================
-- HIGHLIGHT ESP
-- ====================================================

local HighlightESPClass = {}
HighlightESPClass.__index = HighlightESPClass

function Library:CreateHighlightESP(opts)
    opts = opts or {}
    local esp = setmetatable({}, HighlightESPClass)
    esp._enabled = false
    esp._highlights = {}
    esp._fillColor = opts.FillColor or Color3.fromRGB(255, 75, 75)
    esp._outlineColor = opts.OutlineColor or Color3.fromRGB(255, 255, 255)
    esp._fillTrans = opts.FillTransparency or 0.7
    esp._conn = nil

    local function AddHighlight(char)
        local h = Instance.new("Highlight")
        h.FillColor = esp._fillColor
        h.OutlineColor = esp._outlineColor
        h.FillTransparency = esp._fillTrans
        h.Parent = char
        return h
    end

    function esp:Enable()
        if self._enabled then return end
        self._enabled = true
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer and player.Character then
                self._highlights[player] = AddHighlight(player.Character)
            end
        end
        self._conn = Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function(char)
                if self._enabled then
                    self._highlights[player] = AddHighlight(char)
                end
            end)
        end)
    end

    function esp:Disable()
        self._enabled = false
        if self._conn then self._conn:Disconnect(); self._conn = nil end
        for _, h in pairs(self._highlights) do
            if h and h.Parent then h:Destroy() end
        end
        self._highlights = {}
    end

    function esp:SetFillColor(c)
        self._fillColor = c
        for _, h in pairs(self._highlights) do
            if h and h.Parent then h.FillColor = c end
        end
    end

    function esp:SetOutlineColor(c)
        self._outlineColor = c
        for _, h in pairs(self._highlights) do
            if h and h.Parent then h.OutlineColor = c end
        end
    end

    return esp
end

-- ====================================================
-- SILENT AIM
-- ====================================================

local SilentAimClass = {}
SilentAimClass.__index = SilentAimClass

function Library:CreateSilentAim(opts)
    opts = opts or {}
    local sa = setmetatable({}, SilentAimClass)
    sa._enabled = false
    sa._target = opts.Target or "Head"
    sa._fov = opts.FOV or 360
    sa._teamCheck = opts.TeamCheck ~= false

    function sa:GetNearestPlayer()
        local camera = workspace.CurrentCamera
        local viewCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        local nearest, nearDist = nil, math.huge
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer then
                if not (self._teamCheck and player.Team == Players.LocalPlayer.Team) then
                    local char = player.Character
                    if char then
                        local part = char:FindFirstChild(self._target)
                            or char:FindFirstChild("HumanoidRootPart")
                        if part then
                            local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                            if onScreen then
                                local d = (Vector2.new(screenPos.X, screenPos.Y) - viewCenter).Magnitude
                                local hum = char:FindFirstChildOfClass("Humanoid")
                                if d < self._fov and d < nearDist and hum and hum.Health > 0 then
                                    nearest = part
                                    nearDist = d
                                end
                            end
                        end
                    end
                end
            end
        end
        return nearest
    end

    function sa:Enable() self._enabled = true end
    function sa:Disable() self._enabled = false end
    function sa:SetFOV(fov) self._fov = fov end
    function sa:SetTarget(t) self._target = t end
    function sa:IsEnabled() return self._enabled end

    return sa
end

-- ====================================================
-- INFINITE JUMP
-- ====================================================

function Library:EnableInfiniteJump()
    local conn
    conn = UserInputService.JumpRequest:Connect(function()
        local char = Players.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
    self._infJumpConn = conn
    return conn
end

function Library:DisableInfiniteJump()
    if self._infJumpConn then
        self._infJumpConn:Disconnect()
        self._infJumpConn = nil
    end
end

-- ====================================================
-- RADIO GROUP (standalone helper)
-- ====================================================

-- Injected into section objects at creation time via the _buildRadioGroup helper
Library._buildRadioGroup = function(parent, label, opts)
    opts = opts or {}
    local options   = opts.Options or { "Option 1", "Option 2" }
    local default   = opts.Default or options[1]
    local callback  = opts.Callback or function() end
    local disabled  = opts.Disabled ~= nil and opts.Disabled or false
    local value = default

    local container = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 58),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = parent,
    })
    MakePadding(container, 4, 4, 12, 12)

    local labelEl = Create("TextLabel", {
        Text = label,
        Font = Font.Regular,
        TextSize = 12,
        TextColor3 = disabled and Theme.TextDisabled or Theme.TextPrimary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })

    local optRow = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 22),
        Size = UDim2.new(1, 0, 0, 26),
        Parent = container,
    })
    MakeListLayout(optRow, 6, Enum.FillDirection.Horizontal)

    local buttons = {}

    local function UpdateSelection(v)
        value = v
        for _, data in pairs(buttons) do
            local isSelected = data.value == v
            data.btn.BackgroundColor3 = isSelected and Theme.Accent or Theme.ButtonBg
            data.btn.TextColor3 = isSelected and Theme.ToggleKnob or Theme.TextSecondary
        end
        callback(v)
    end

    for i, opt in ipairs(options) do
        local btn = Create("TextButton", {
            BackgroundColor3 = opt == value and Theme.Accent or Theme.ButtonBg,
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = "  " .. opt .. "  ",
            Font = Font.Regular,
            TextSize = 11,
            TextColor3 = opt == value and Theme.ToggleKnob or Theme.TextSecondary,
            AutoButtonColor = false,
            LayoutOrder = i,
            Parent = optRow,
        })
        MakeRounded(btn, 5)
        if not disabled then
            btn.MouseButton1Click:Connect(function()
                UpdateSelection(opt)
            end)
        end
        table.insert(buttons, { btn = btn, value = opt })
    end

    return {
        Value = value,
        _frame = container,
        Set = function(self, v) UpdateSelection(v) end,
        GetValue = function(self) return value end,
    }
end

-- ====================================================
-- PROGRESS BAR HELPER (standalone)
-- ====================================================

Library._buildProgressBar = function(parent, label, opts)
    opts = opts or {}
    local min     = opts.Min or 0
    local max     = opts.Max or 100
    local default = opts.Default or 0
    local color   = opts.Color or Theme.Accent
    local suffix  = opts.Suffix or "%"
    local barH    = opts.Height or 6

    local value = Clamp(default, min, max)

    local container = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 42),
        Parent = parent,
    })
    MakePadding(container, 0, 0, 12, 12)

    local topRow = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Parent = container,
    })

    local labelEl = Create("TextLabel", {
        Text = label,
        Font = Font.Regular,
        TextSize = 12,
        TextColor3 = Theme.TextPrimary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -50, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topRow,
    })

    local valLabel = Create("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Text = tostring(math.floor(value)) .. suffix,
        Font = Font.Regular,
        TextSize = 12,
        TextColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 48, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = topRow,
    })

    local track = Create("Frame", {
        BackgroundColor3 = Theme.SliderBg,
        Position = UDim2.new(0, 0, 0, 24),
        Size = UDim2.new(1, 0, 0, barH),
        Parent = container,
    })
    MakeRounded(track, math.floor(barH / 2))

    local fill = Create("Frame", {
        BackgroundColor3 = color,
        Size = UDim2.new((value - min) / math.max(1, max - min), 0, 1, 0),
        Parent = track,
    })
    MakeRounded(fill, math.floor(barH / 2))

    local function SetProgress(v)
        value = Clamp(v, min, max)
        local frac = (value - min) / math.max(1, max - min)
        Tween(fill, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
            Size = UDim2.new(Clamp(frac, 0, 1), 0, 1, 0)
        })
        valLabel.Text = tostring(math.floor(value)) .. suffix
    end

    return {
        Value = value,
        _frame = container,
        Set = function(self, v) SetProgress(v) end,
        GetValue = function(self) return value end,
    }
end

-- ====================================================
-- CONTEXT MENU
-- ====================================================

function Library:CreateContextMenu(opts)
    opts = opts or {}
    local items = opts.Items or {}
    if not self._gui then self:Init() end

    local menu = Create("Frame", {
        BackgroundColor3 = Theme.DropdownBg,
        Size = UDim2.new(0, 160, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 9000,
        Parent = self._gui,
    })
    MakeRounded(menu, 7)
    MakeStroke(menu, Theme.DropdownBorder, 1)
    AddDropShadow(menu, 10, 0.6)
    MakePadding(menu, 4, 4, 0, 0)
    MakeListLayout(menu, 2)

    local function BuildItems()
        for _, c in pairs(menu:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
        end
        for _, item in ipairs(items) do
            if item == "separator" then
                Create("Frame", {
                    BackgroundColor3 = Theme.Separator,
                    Size = UDim2.new(1, 0, 0, 1),
                    Parent = menu,
                })
            else
                local btn = Create("TextButton", {
                    BackgroundColor3 = Theme.DropdownItem,
                    BackgroundTransparency = 0,
                    Size = UDim2.new(1, 0, 0, 28),
                    Text = "  " .. (item.Label or ""),
                    Font = Font.Regular,
                    TextSize = 12,
                    TextColor3 = item.Color or Theme.TextPrimary,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false,
                    ZIndex = 9001,
                    Parent = menu,
                })
                MakeRounded(btn, 4)
                btn.MouseEnter:Connect(function()
                    Tween(btn, TweenInfo.new(0.1), { BackgroundColor3 = Theme.DropdownItemHover })
                end)
                btn.MouseLeave:Connect(function()
                    Tween(btn, TweenInfo.new(0.1), { BackgroundColor3 = Theme.DropdownItem })
                end)
                btn.MouseButton1Click:Connect(function()
                    menu.Visible = false
                    if item.Callback then item.Callback() end
                end)
            end
        end
    end

    BuildItems()

    local menuObj = {
        _frame = menu,
        Show = function(self, x, y)
            menu.Position = UDim2.new(0, x, 0, y)
            menu.Visible = true
        end,
        Hide = function(self)
            menu.Visible = false
        end,
        SetItems = function(self, newItems)
            items = newItems
            BuildItems()
        end,
    }

    -- Close on outside click
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            task.defer(function()
                menu.Visible = false
            end)
        end
    end)

    return menuObj
end

-- ====================================================
-- TOOLTIP SYSTEM
-- ====================================================

local tooltipFrame = nil

function Library:ShowTooltip(text, x, y)
    if not self._gui then self:Init() end
    if not tooltipFrame then
        tooltipFrame = Create("Frame", {
            BackgroundColor3 = Theme.NotifBg,
            Size = UDim2.new(0, 0, 0, 24),
            AutomaticSize = Enum.AutomaticSize.X,
            Visible = false,
            ZIndex = 9500,
            Parent = self._gui,
        })
        MakeRounded(tooltipFrame, 4)
        MakeStroke(tooltipFrame, Theme.WindowBorder, 1)
        MakePadding(tooltipFrame, 0, 0, 8, 8)
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Font = Font.Regular,
            TextSize = 11,
            TextColor3 = Theme.TextSecondary,
            Name = "TooltipLabel",
            Parent = tooltipFrame,
        })
    end
    local lbl = tooltipFrame:FindFirstChild("TooltipLabel")
    if lbl then lbl.Text = text end
    tooltipFrame.Position = UDim2.new(0, x + 12, 0, y - 12)
    tooltipFrame.Visible = true
end

function Library:HideTooltip()
    if tooltipFrame then
        tooltipFrame.Visible = false
    end
end

-- ====================================================
-- TWEEN HELPER (exposed utility)
-- ====================================================

function Library.Tween(obj, info, goal, callback)
    return Tween(obj, info, goal, callback)
end

function Library.Create(class, props, children)
    return Create(class, props, children)
end

function Library.MakeRounded(parent, radius)
    return MakeRounded(parent, radius)
end

function Library.Theme()
    return Theme
end

return Library
