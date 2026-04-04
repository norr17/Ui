--[[
    Kojo Hub — Universal UI Library
    Aikeo Hub inspired design, Obsidian API compatible
]]

-- Services
local cloneref = cloneref or clonereference or function(i) return i end
local CoreGui = cloneref(game:GetService("CoreGui"))
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TextService = cloneref(game:GetService("TextService"))
local TweenService = cloneref(game:GetService("TweenService"))
local HttpService = cloneref(game:GetService("HttpService"))
local SoundService = cloneref(game:GetService("SoundService"))

local getgenv = getgenv or function() return shared end
local setclipboard = setclipboard or nil
local protectgui = protectgui or (syn and syn.protect_gui) or function() end
local gethui = gethui or function() return CoreGui end

local LocalPlayer = Players.LocalPlayer or Players:FindFirstChildOfClass("Player") or Players.PlayerAdded:Wait()

-- State Tables (Obsidian compatible)
local Labels = {}
local Buttons = {}
local Toggles = {}
local Options = {}

-- Library Object
local Library = {
    Toggled = false,
    Unloaded = false,
    
    Labels = Labels,
    Buttons = Buttons,
    Toggles = Toggles,
    Options = Options,
    
    Registry = {},
    Signals = {},
    UnloadSignals = {},
    Notifications = {},
    Tabs = {},
    TabButtons = {},
    
    ToggleKeybind = Enum.KeyCode.RightControl,
    NotifySide = "Right",
    ShowCustomCursor = false,
    ForceCheckbox = false,
    ShowToggleFrameInKeybinds = true,
    
    CornerRadius = 12,
    
    IsMobile = false,
    
    Scheme = {
        BackgroundColor = Color3.fromRGB(9, 9, 11),
        MainColor = Color3.fromRGB(17, 17, 20),
        AccentColor = Color3.fromRGB(187, 154, 247),
        OutlineColor = Color3.fromRGB(30, 30, 35),
        FontColor = Color3.fromRGB(255, 255, 255),
        Font = Font.fromEnum(Enum.Font.Gotham),
        
        RedColor = Color3.fromRGB(255, 50, 50),
        DarkColor = Color3.fromRGB(0, 0, 0),
        WhiteColor = Color3.fromRGB(255, 255, 255),
    },
}

-- Mobile Detection
if RunService:IsStudio() then
    Library.IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
else
    pcall(function()
        local platform = UserInputService:GetPlatform()
        Library.IsMobile = (platform == Enum.Platform.Android or platform == Enum.Platform.IOS)
    end)
end

-- Scheme helper
local function GetSchemeValue(key)
    if typeof(key) == "string" then
        return Library.Scheme[key]
    end
    return nil
end

--==============================================================================
-- UTILITY FUNCTIONS
--==============================================================================
function Library:SafeCallback(func, ...)
    if not func then return end
    local ok, err = pcall(func, ...)
    if not ok then warn("[Kojo Hub] Callback error:", err) end
end

function Library:GetTextBounds(text, font, size, width)
    local params = Instance.new("GetTextBoundsParams")
    params.Text = text
    params.Font = font or Library.Scheme.Font
    params.Size = size or 14
    params.Width = width or math.huge
    local ok, result = pcall(TextService.GetTextBoundsAsync, TextService, params)
    return ok and result or Vector2.new(200, 20)
end

function Library:GiveSignal(conn)
    if conn then table.insert(Library.Signals, conn) end
    return conn
end

function Library:OnUnload(fn)
    table.insert(Library.UnloadSignals, fn)
end

-- Registry system (ThemeManager compatible)
function Library:AddToRegistry(instance, properties)
    Library.Registry[instance] = properties
end

function Library:RemoveFromRegistry(instance)
    Library.Registry[instance] = nil
end

function Library:UpdateColorsUsingRegistry()
    for inst, props in pairs(Library.Registry) do
        for prop, key in pairs(props) do
            local val = GetSchemeValue(key)
            if val then
                inst[prop] = val
            elseif typeof(key) == "function" then
                inst[prop] = key()
            end
        end
    end
end

function Library:SetFont(fontFace)
    if typeof(fontFace) == "EnumItem" then
        fontFace = Font.fromEnum(fontFace)
    end
    Library.Scheme.Font = fontFace
    Library:UpdateColorsUsingRegistry()
end

--==============================================================================
-- ICONS (Lucide support)
--==============================================================================
local FetchIcons, Icons = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua"))()
end)

function Library:GetIcon(iconName)
    if typeof(iconName) == "number" then return { Url = "rbxassetid://" .. iconName } end
    if typeof(iconName) == "string" then
        if FetchIcons and (iconName:match("^lucide%-") or Icons.GetAsset(iconName)) then
            local ok, asset = pcall(Icons.GetAsset, iconName)
            if ok and asset then
                return { Url = asset.Url, ImageRectOffset = asset.ImageRectOffset, ImageRectSize = asset.ImageRectSize }
            end
        end
        if iconName:match("^rbxassetid://") or iconName:match("^http") then return { Url = iconName } end
    end
    return nil
end

function Library:ApplyIcon(imgLabel, iconName)
    local icon = Library:GetIcon(iconName)
    if icon then
        imgLabel.Image = icon.Url
        if icon.ImageRectOffset then imgLabel.ImageRectOffset = icon.ImageRectOffset end
        if icon.ImageRectSize then imgLabel.ImageRectSize = icon.ImageRectSize end
    end
end

--==============================================================================
-- INSTANCE CREATOR
--==============================================================================
local function New(class, props)
    local inst = Instance.new(class)
    local registry = nil
    
    for k, v in pairs(props) do
        if k == "Parent" then continue end
        if typeof(v) == "string" and Library.Scheme[v] then
            if not registry then registry = {} end
            registry[k] = v
            inst[k] = Library.Scheme[v]
        else
            inst[k] = v
        end
    end
    
    -- Common defaults
    if inst:IsA("Frame") or inst:IsA("TextButton") or inst:IsA("TextLabel") or inst:IsA("TextBox") or inst:IsA("ScrollingFrame") then
        if props.BorderSizePixel == nil then inst.BorderSizePixel = 0 end
    end
    if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
        if props.FontFace == nil then inst.FontFace = Library.Scheme.Font end
        if props.TextColor3 == nil and not (registry and registry.TextColor3) then
            inst.TextColor3 = Library.Scheme.FontColor
            if not registry then registry = {} end
            registry.TextColor3 = "FontColor"
        end
        if props.BackgroundTransparency == nil and not inst:IsA("TextBox") then
            inst.BackgroundTransparency = 1
        end
    end
    if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
        if props.BackgroundTransparency == nil then inst.BackgroundTransparency = 1 end
        if props.BorderSizePixel == nil then inst.BorderSizePixel = 0 end
    end
    
    if registry then Library:AddToRegistry(inst, registry) end
    if props.Parent then inst.Parent = props.Parent end
    
    return inst
end

--==============================================================================
-- ANTI-DETECT & SCREENGUI
--==============================================================================
local function SafeParent(gui)
    pcall(protectgui, gui)
    local ok = pcall(function() gui.Parent = gethui() end)
    if not ok or not gui.Parent then
        ok = pcall(function() gui.Parent = CoreGui end)
    end
    if not ok or not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui", 10)
    end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KJ_" .. HttpService:GenerateGUID(false):sub(1, 8)
ScreenGui.DisplayOrder = 999
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SafeParent(ScreenGui)
Library.ScreenGui = ScreenGui

ScreenGui.DescendantRemoving:Connect(function(inst)
    Library:RemoveFromRegistry(inst)
end)

--==============================================================================
-- UNLOAD
--==============================================================================
function Library:Unload()
    for i = #Library.Signals, 1, -1 do
        local c = table.remove(Library.Signals, i)
        if c and c.Connected then c:Disconnect() end
    end
    for _, fn in pairs(Library.UnloadSignals) do
        Library:SafeCallback(fn)
    end
    Library.Unloaded = true
    ScreenGui:Destroy()
    getgenv().Library = nil
end

--==============================================================================
-- NOTIFY (Basic — Obsidian compatible)
--==============================================================================
local NotificationArea = New("Frame", {
    AnchorPoint = Vector2.new(1, 0),
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -10, 0, 10),
    Size = UDim2.new(0, 300, 1, -20),
    Parent = ScreenGui,
})
New("UIListLayout", {
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 6),
    Parent = NotificationArea,
})

function Library:Notify(...)
    local data = {}
    local info = select(1, ...)
    if typeof(info) == "table" then
        data.Title = tostring(info.Title or "Kojo Hub")
        data.Description = tostring(info.Description or "")
        data.Time = info.Time or 5
    else
        data.Description = tostring(info or "")
        data.Time = select(2, ...) or 5
    end
    
    local notif = New("Frame", {
        BackgroundColor3 = "MainColor",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = NotificationArea,
    })
    New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = notif })
    New("UIStroke", { Color = Library.Scheme.OutlineColor, Thickness = 1, Parent = notif })
    Library:AddToRegistry(notif:FindFirstChildOfClass("UIStroke"), { Color = "OutlineColor" })
    New("UIPadding", {
        PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
        Parent = notif,
    })
    
    if data.Title then
        New("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = data.Title,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = notif,
        })
    end
    New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.fromOffset(0, data.Title and 18 or 0),
        Text = data.Description,
        TextSize = 13,
        TextTransparency = 0.3,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = notif,
    })
    
    -- Animate in
    notif.BackgroundTransparency = 1
    TweenService:Create(notif, TweenInfo.new(0.3), { BackgroundTransparency = 0 }):Play()
    
    task.delay(data.Time, function()
        local tw = TweenService:Create(notif, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
        tw:Play()
        tw.Completed:Wait()
        notif:Destroy()
    end)
    
    return { Destroy = function() notif:Destroy() end }
end

--==============================================================================
-- DRAG HELPER
--==============================================================================
local function MakeDraggable(frame, handle)
    local dragging, dragStart, startPos
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
end

--==============================================================================
-- CREATE WINDOW
--==============================================================================
function Library:CreateWindow(config)
    config = config or {}
    local title = config.Title or "Kojo Hub"
    local footer = config.Footer or ""
    local icon = config.Icon -- rbxassetid number or string
    local iconSize = config.IconSize or UDim2.fromOffset(28, 28)
    local windowSize = config.Size or UDim2.fromOffset(580, 420)
    local center = config.Center ~= false
    local autoShow = config.AutoShow ~= false
    local resizable = config.Resizable or false
    
    if config.NotifySide then Library.NotifySide = config.NotifySide end
    if config.ShowCustomCursor ~= nil then Library.ShowCustomCursor = config.ShowCustomCursor end
    if config.ToggleKeybind then Library.ToggleKeybind = config.ToggleKeybind end
    if config.CornerRadius then Library.CornerRadius = config.CornerRadius end
    if config.Font then Library:SetFont(config.Font) end
    
    local SIDEBAR_W = 50
    local TOPBAR_H = 40
    
    -- Main Frame
    local MainFrame = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        Size = windowSize,
        Position = center and UDim2.new(0.5, -windowSize.X.Offset / 2, 0.5, -windowSize.Y.Offset / 2) or UDim2.fromOffset(100, 100),
        Visible = autoShow,
        Parent = ScreenGui,
    })
    New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = MainFrame })
    New("UIStroke", { Color = Library.Scheme.OutlineColor, Thickness = 1, Parent = MainFrame })
    Library:AddToRegistry(MainFrame:FindFirstChildOfClass("UIStroke"), { Color = "OutlineColor" })
    
    local baseScale = config.Scale or 1.25 -- 1.25 default scale so it doesn't look tiny on 1080p
    Library.DPIScale = baseScale
    New("UIScale", { Scale = baseScale, Parent = MainFrame })
    
    Library.Toggled = autoShow
    Library.MainFrame = MainFrame
    
    -- Sidebar
    local Sidebar = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, SIDEBAR_W, 1, 0),
        Parent = MainFrame,
    })
    -- Sidebar right border
    New("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = "OutlineColor",
        Position = UDim2.new(1, 0, 0, 10),
        Size = UDim2.new(0, 1, 1, -20),
        Parent = Sidebar,
    })
    
    -- Logo at top of sidebar
    local LogoHolder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, TOPBAR_H),
        Parent = Sidebar,
    })
    local LogoImage
    if icon then
        LogoImage = New("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = iconSize,
            Image = typeof(icon) == "number" and ("rbxassetid://" .. icon) or icon,
            ScaleType = Enum.ScaleType.Fit,
            Parent = LogoHolder,
        })
    end
    
    -- Category icons container (below logo)
    local CategoryList = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, TOPBAR_H),
        Size = UDim2.new(1, 0, 1, -TOPBAR_H),
        CanvasSize = UDim2.fromScale(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0,
        Parent = Sidebar,
    })
    New("UIListLayout", {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 4),
        Parent = CategoryList,
    })
    New("UIPadding", { PaddingTop = UDim.new(0, 8), Parent = CategoryList })
    
    -- TopBar
    local TopBar = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(SIDEBAR_W, 0),
        Size = UDim2.new(1, -SIDEBAR_W, 0, TOPBAR_H),
        Parent = MainFrame,
    })
    MakeDraggable(MainFrame, TopBar)
    
    -- TopBar bottom border
    New("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = "OutlineColor",
        Position = UDim2.new(0, 10, 1, 0),
        Size = UDim2.new(1, -20, 0, 1),
        Parent = TopBar,
    })
    
    -- Breadcrumb + Tabs container
    local TopTabsScroll = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(1, -32, 1, 0),
        CanvasSize = UDim2.fromScale(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        ScrollBarThickness = 0,
        Parent = TopBar,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 0),
        Parent = TopTabsScroll,
    })
    
    -- Breadcrumb prefix: ">  Title  /"
    New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.XY,
        Text = ">",
        TextSize = 13,
        TextTransparency = 0.5,
        LayoutOrder = -2,
        Parent = TopTabsScroll,
    })
    New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.XY,
        Text = "   " .. title .. "   /   ",
        TextSize = 13,
        TextTransparency = 0.5,
        LayoutOrder = -1,
        Parent = TopTabsScroll,
    })
    
    -- Content container (right of sidebar, below topbar)
    local ContentArea = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(SIDEBAR_W, TOPBAR_H),
        Size = UDim2.new(1, -SIDEBAR_W, 1, -TOPBAR_H),
        Parent = MainFrame,
    })
    
    --==========================================================================
    -- WINDOW OBJECT
    --==========================================================================
    local Window = {}
    Window.Categories = {}
    Window.ActiveCategory = nil
    Window.ActiveTab = nil
    Window.Tabs = {}
    
    function Window:ChangeTitle(t) title = t end
    function Window:SetFooter(f) footer = f end
    
    function Window:Toggle()
        Library.Toggled = not Library.Toggled
        MainFrame.Visible = Library.Toggled
    end
    
    --==========================================================================
    -- CATEGORY SYSTEM (Sidebar icons)
    --==========================================================================
    function Window:AddCategory(info)
        info = info or {}
        local catName = info.Name or "Category"
        local catIcon = info.Icon -- rbxassetid number or lucide string or nil
        local catIconSize = info.IconSize or UDim2.fromOffset(22, 22)
        
        local catObj = { Name = catName, Tabs = {}, Window = Window }
        
        -- Category button in sidebar
        local catBtn = New("TextButton", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 36),
            Text = "",
            AutoButtonColor = false,
            Parent = CategoryList,
        })
        
        local catImg
        if catIcon then
            catImg = New("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = catIconSize,
                BackgroundTransparency = 1,
                ImageTransparency = 0.5,
                ScaleType = Enum.ScaleType.Fit,
                Parent = catBtn,
            })
            Library:ApplyIcon(catImg, catIcon)
        end
        
        local catData = { Button = catBtn, Icon = catImg, Obj = catObj }
        table.insert(Window.Categories, catData)
        
        catBtn.MouseButton1Click:Connect(function()
            Window:SelectCategory(catObj)
        end)
        
        -- Category:AddTab
        function catObj:AddTab(tabName, tabIcon)
            local tab = Window:AddTab(tabName, tabIcon)
            tab.Category = catObj
            table.insert(catObj.Tabs, tab)
            
            if Window.ActiveCategory ~= catObj then
                tab.TabButton.Visible = false
                tab.TabContainer.Visible = false
            end
            return tab
        end
        
        -- Auto-select first category
        if not Window.ActiveCategory then
            Window:SelectCategory(catObj)
        end
        
        return catObj
    end
    
    function Window:SelectCategory(catObj)
        Window.ActiveCategory = catObj
        
        -- Update sidebar icon highlights
        for _, cd in pairs(Window.Categories) do
            if cd.Icon then
                cd.Icon.ImageTransparency = (cd.Obj == catObj) and 0 or 0.5
            end
        end
        
        -- Show/hide tabs belonging to categories
        local firstTab = nil
        for _, tab in pairs(Library.Tabs) do
            if tab.Category == catObj then
                tab.TabButton.Visible = true
                if not firstTab then firstTab = tab end
            elseif tab.Category then
                tab.TabButton.Visible = false
                tab.TabContainer.Visible = false
            end
        end
        
        if firstTab then
            Window:SelectTab(firstTab)
        end
    end
    
    --==========================================================================
    -- TAB SYSTEM (TopBar text buttons)
    --==========================================================================
    function Window:AddTab(tabName, tabIcon)
        tabName = tabName or "Tab"
        
        -- Tab button in topbar
        local tabBtn = New("TextButton", {
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            Text = "",
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            LayoutOrder = #Library.Tabs + 1,
            Parent = TopTabsScroll,
        })
        
        local tabLabel = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.XY,
            Text = tabName .. "   /   ",
            TextSize = 13,
            TextTransparency = 0.5,
            Parent = tabBtn,
        })
        
        -- Content container for this tab
        local tabContainer = New("ScrollingFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.fromScale(0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.Scheme.OutlineColor,
            Visible = false,
            Parent = ContentArea,
        })
        New("UIPadding", {
            PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
            Parent = tabContainer,
        })
        
        -- Two-column layout inside tab
        local columnsFrame = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = tabContainer,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 6),
            Parent = columnsFrame,
        })
        
        local leftCol = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0.5, -3, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = columnsFrame,
        })
        New("UIListLayout", { Padding = UDim.new(0, 6), Parent = leftCol })
        
        local rightCol = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0.5, -3, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = columnsFrame,
        })
        New("UIListLayout", { Padding = UDim.new(0, 6), Parent = rightCol })
        
        -- Tab object
        local Tab = {
            Name = tabName,
            TabButton = tabBtn,
            TabLabel = tabLabel,
            TabContainer = tabContainer,
            LeftColumn = leftCol,
            RightColumn = rightCol,
            Category = nil,
        }
        
        table.insert(Library.Tabs, Tab)
        
        tabBtn.MouseButton1Click:Connect(function()
            Window:SelectTab(Tab)
        end)
        
        -- Auto-show first tab
        if #Library.Tabs == 1 then
            Window:SelectTab(Tab)
        end
        
        -- Tab Methods
        function Tab:SetVisible(v)
            tabBtn.Visible = v
            if not v then tabContainer.Visible = false end
        end
        function Tab:SetName(n)
            tabName = n
            tabLabel.Text = n .. "   /   "
        end
        function Tab:Show()
            Window:SelectTab(self)
        end
        
        --======================================================================
        -- GROUPBOX CREATION
        --======================================================================
        local function CreateGroupbox(name, gbIcon, parent, isInline)
            local gb, elementList
            
            if isInline then
                -- Inline mode: no visual frame, elements go directly into parent
                gb = parent
                elementList = parent
            else
                gb = New("Frame", {
                    BackgroundColor3 = "MainColor",
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = parent,
                })
                New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = gb })
                New("UIStroke", { Color = Library.Scheme.OutlineColor, Thickness = 1, Parent = gb })
                Library:AddToRegistry(gb:FindFirstChildOfClass("UIStroke"), { Color = "OutlineColor" })
                New("UIPadding", {
                    PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
                    PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
                    Parent = gb,
                })
                
                -- Title row
                local titleRow = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    LayoutOrder = -1,
                    Parent = gb,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 6),
                    Parent = titleRow,
                })
                
                if gbIcon then
                    local gbImg = New("ImageLabel", {
                        Size = UDim2.fromOffset(16, 16),
                        BackgroundTransparency = 1,
                        ImageColor3 = Library.Scheme.FontColor,
                        ImageTransparency = 0.3,
                        ScaleType = Enum.ScaleType.Fit,
                        Parent = titleRow,
                    })
                    Library:ApplyIcon(gbImg, gbIcon)
                end
                
                New("TextLabel", {
                    AutomaticSize = Enum.AutomaticSize.XY,
                    Text = name or "Group",
                    TextSize = 14,
                    Parent = titleRow,
                })
                
                -- Element list
                elementList = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = gb,
                })
                New("UIListLayout", { Padding = UDim.new(0, 2), Parent = elementList })
                
                -- Groupbox layout
                New("UIListLayout", { Padding = UDim.new(0, 6), Parent = gb })
            end
            
            --==================================================================
            -- GROUPBOX OBJECT (Element methods will be added)
            --==================================================================
            local Groupbox = { Container = elementList, Frame = gb }
            
            -- TOGGLE
            function Groupbox:AddToggle(idx, info)
                info = info or {}
                local text = info.Text or "Toggle"
                local default = info.Default or false
                local disabled = info.Disabled or false
                local callback = info.Callback
                local risky = info.Risky or false
                
                local toggle = {
                    Type = "Toggle",
                    Value = default,
                    Callbacks = {},
                }
                
                local row = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 24),
                    Visible = info.Visible ~= false,
                    Parent = elementList,
                })
                
                local label = New("TextLabel", {
                    Size = UDim2.new(1, -34, 1, 0),
                    Text = text,
                    TextSize = 13,
                    TextTransparency = disabled and 0.5 or (risky and 0 or 0.3),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextColor3 = risky and Library.Scheme.RedColor or nil,
                    Parent = row,
                })
                if risky then Library:AddToRegistry(label, { TextColor3 = "RedColor" }) end
                toggle.TextLabel = label
                
                -- Pill switch
                local pillW, pillH = 28, 14
                local pillFrame = New("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.fromOffset(pillW, pillH),
                    BackgroundColor3 = default and Library.Scheme.AccentColor or Color3.fromRGB(45, 45, 50),
                    Parent = row,
                })
                New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = pillFrame })
                
                local ball = New("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = default and UDim2.new(1, -pillH + 2, 0.5, 0) or UDim2.fromOffset(2, pillH / 2),
                    Size = UDim2.fromOffset(pillH - 4, pillH - 4),
                    BackgroundColor3 = default and Color3.new(1, 1, 1) or Color3.fromRGB(200, 200, 200),
                    Parent = pillFrame,
                })
                New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ball })
                
                local clickBtn = New("TextButton", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text = "",
                    AutoButtonColor = false,
                    Parent = row,
                })
                
                local function updateVisual(v)
                    local color = v and Library.Scheme.AccentColor or Color3.fromRGB(45, 45, 50)
                    local ballColor = v and Color3.new(1, 1, 1) or Color3.fromRGB(200, 200, 200)
                    TweenService:Create(pillFrame, TweenInfo.new(0.2), { BackgroundColor3 = color }):Play()
                    TweenService:Create(ball, TweenInfo.new(0.2), { BackgroundColor3 = ballColor }):Play()
                    
                    local pos = v and UDim2.new(1, -pillH + 2, 0.5, 0) or UDim2.fromOffset(2, pillH / 2)
                    TweenService:Create(ball, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Position = pos }):Play()
                end
                
                function toggle:SetValue(v)
                    toggle.Value = v
                    updateVisual(v)
                    Library:SafeCallback(callback, v)
                    for _, fn in pairs(toggle.Callbacks) do
                        Library:SafeCallback(fn, v)
                    end
                end
                
                function toggle:OnChanged(fn)
                    table.insert(toggle.Callbacks, fn)
                end
                
                function toggle:SetText(t) label.Text = t end
                function toggle:SetDisabled(d) disabled = d; label.TextTransparency = d and 0.5 or 0.3 end
                function toggle:SetVisible(v) row.Visible = v end
                
                clickBtn.MouseButton1Click:Connect(function()
                    if disabled then return end
                    toggle:SetValue(not toggle.Value)
                end)
                
                Toggles[idx] = toggle
                toggle.Row = row
                
                -- Return toggle for chaining :AddKeyPicker / :AddColorPicker
                local chainObj = setmetatable({}, { __index = toggle })
                function chainObj:AddKeyPicker(kpIdx, kpInfo)
                    Groupbox:_AddKeyPicker(kpIdx, kpInfo, row, toggle)
                    return chainObj
                end
                function chainObj:AddColorPicker(cpIdx, cpInfo)
                    Groupbox:_AddColorPicker(cpIdx, cpInfo, row)
                    return chainObj
                end
                
                return chainObj
            end
            
            -- SLIDER
            function Groupbox:AddSlider(idx, info)
                info = info or {}
                local text = info.Text or "Slider"
                local default = info.Default or info.Min or 0
                local min = info.Min or 0
                local max = info.Max or 100
                local rounding = info.Rounding or 1
                local suffix = info.Suffix or ""
                local callback = info.Callback
                local compact = info.Compact or false
                
                local slider = { Type = "Slider", Value = default, Callbacks = {} }
                
                local container = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, compact and 26 or 32),
                    Parent = elementList,
                })
                
                -- Title + Value row
                local titleLabel = New("TextLabel", {
                    Size = UDim2.new(0.6, 0, 0, 16),
                    Text = text,
                    TextSize = 13,
                    TextTransparency = 0.3,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = container,
                })
                
                local valueLabel = New("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.fromScale(1, 0),
                    Size = UDim2.new(0.4, 0, 0, 16),
                    Text = tostring(default) .. suffix,
                    TextSize = 13,
                    TextTransparency = 0.5,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = container,
                })
                
                -- Track
                local trackY = compact and 16 or 20
                local track = New("Frame", {
                    Position = UDim2.fromOffset(0, trackY + 4),
                    Size = UDim2.new(1, 0, 0, 3),
                    BackgroundColor3 = Color3.fromRGB(45, 45, 50),
                    Parent = container,
                })
                New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
                
                local fill = New("Frame", {
                    Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
                    BackgroundColor3 = "AccentColor",
                    Parent = track,
                })
                New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
                
                local thumb = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0),
                    Size = UDim2.fromOffset(10, 10),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Parent = track,
                })
                New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = thumb })
                
                local function setValue(v, skipCb)
                    v = math.clamp(v, min, max)
                    if rounding >= 1 then
                        v = math.floor(v / rounding + 0.5) * rounding
                    else
                        v = tonumber(string.format("%." .. math.ceil(-math.log10(rounding)) .. "f", v))
                    end
                    slider.Value = v
                    local pct = (v - min) / (max - min)
                    fill.Size = UDim2.new(pct, 0, 1, 0)
                    thumb.Position = UDim2.new(pct, 0, 0.5, 0)
                    valueLabel.Text = tostring(v) .. suffix
                    if not skipCb then
                        Library:SafeCallback(callback, v)
                        for _, fn in pairs(slider.Callbacks) do Library:SafeCallback(fn, v) end
                    end
                end
                
                function slider:SetValue(v) setValue(v) end
                function slider:OnChanged(fn) table.insert(slider.Callbacks, fn) end
                
                -- Drag
                local sliding = false
                local inputBtn = New("TextButton", {
                    Size = UDim2.new(1, 0, 0, 20),
                    Position = UDim2.fromOffset(0, trackY - 8),
                    BackgroundTransparency = 1,
                    Text = "",
                    AutoButtonColor = false,
                    Parent = container,
                })
                
                inputBtn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = true
                        local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                        setValue(min + (max - min) * pct)
                    end
                end)
                inputBtn.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = false
                    end
                end)
                Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
                    if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                        setValue(min + (max - min) * pct)
                    end
                end))
                
                Options[idx] = slider
                return slider
            end
            
            -- DROPDOWN
            function Groupbox:AddDropdown(idx, info)
                info = info or {}
                local text = info.Text or "Dropdown"
                local values = info.Values or {}
                local default = info.Default
                local multi = info.Multi or false
                local allowNull = info.AllowNull or false
                local callback = info.Callback
                local maxVisible = info.MaxVisibleDropdownItems or 8
                local disabled = info.Disabled or false
                
                -- Resolve numeric default
                if typeof(default) == "number" then default = values[default] end
                
                local dropdown = {
                    Type = "Dropdown",
                    Value = multi and {} or (default or (allowNull and nil or values[1])),
                    Values = values,
                    Multi = multi,
                    Callbacks = {},
                    Opened = false,
                }
                
                local container = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 28),
                    ClipsDescendants = false,
                    Visible = info.Visible ~= false,
                    Parent = elementList,
                })
                
                New("TextLabel", {
                    Size = UDim2.new(0.5, 0, 0, 28),
                    Text = text,
                    TextSize = 13,
                    TextTransparency = disabled and 0.5 or 0.3,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = container,
                })
                
                local function getDisplayText()
                    if multi then
                        local selected = {}
                        for k, v in pairs(dropdown.Value) do
                            if v then table.insert(selected, tostring(k)) end
                        end
                        return #selected > 0 and table.concat(selected, ", ") or "None"
                    end
                    return tostring(dropdown.Value or "None")
                end
                
                local displayBtn = New("TextButton", {
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, 0, 0, 3),
                    Size = UDim2.new(0.45, 0, 0, 22),
                    BackgroundColor3 = Color3.fromRGB(26, 26, 32),
                    Text = getDisplayText(),
                    TextSize = 12,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    AutoButtonColor = false,
                    Parent = container,
                })
                New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = displayBtn })
                New("UIStroke", { Color = Library.Scheme.OutlineColor, Thickness = 1, Parent = displayBtn })
                Library:AddToRegistry(displayBtn:FindFirstChildOfClass("UIStroke"), { Color = "OutlineColor" })
                New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = displayBtn })
                
                -- Chevron
                New("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 2, 0.5, 0),
                    Size = UDim2.fromOffset(12, 12),
                    Text = "▾",
                    TextSize = 14,
                    TextTransparency = 0.4,
                    Parent = displayBtn,
                })
                
                -- Popup list (parented to ScreenGui for z-order)
                local popupFrame = New("Frame", {
                    BackgroundColor3 = Color3.fromRGB(22, 22, 28),
                    Size = UDim2.fromOffset(0, 0),
                    Visible = false,
                    ZIndex = 50,
                    Parent = ScreenGui,
                })
                New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = popupFrame })
                New("UIStroke", { Color = Library.Scheme.OutlineColor, Thickness = 1, Parent = popupFrame })
                Library:AddToRegistry(popupFrame:FindFirstChildOfClass("UIStroke"), { Color = "OutlineColor" })
                
                local popupScroll = New("ScrollingFrame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    CanvasSize = UDim2.fromScale(0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 2,
                    ScrollBarImageColor3 = Library.Scheme.OutlineColor,
                    ZIndex = 51,
                    Parent = popupFrame,
                })
                New("UIListLayout", { Padding = UDim.new(0, 0), ZIndex = 51, Parent = popupScroll })
                New("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = popupScroll })
                
                local optionButtons = {}
                
                local function rebuildOptions()
                    for _, btn in pairs(optionButtons) do btn:Destroy() end
                    optionButtons = {}
                    
                    for _, val in ipairs(dropdown.Values) do
                        local isSelected
                        if multi then
                            isSelected = dropdown.Value[val] == true
                        else
                            isSelected = dropdown.Value == val
                        end
                        
                        local optBtn = New("TextButton", {
                            Size = UDim2.new(1, 0, 0, 24),
                            BackgroundColor3 = isSelected and Library.Scheme.AccentColor or Color3.fromRGB(22, 22, 28),
                            BackgroundTransparency = isSelected and 0.8 or 1,
                            Text = "  " .. tostring(val),
                            TextSize = 12,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextColor3 = isSelected and Library.Scheme.AccentColor or Library.Scheme.FontColor,
                            AutoButtonColor = false,
                            ZIndex = 52,
                            Parent = popupScroll,
                        })
                        
                        optBtn.MouseEnter:Connect(function()
                            if not (multi and dropdown.Value[val]) and dropdown.Value ~= val then
                                TweenService:Create(optBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0.85 }):Play()
                            end
                        end)
                        optBtn.MouseLeave:Connect(function()
                            local sel = multi and dropdown.Value[val] or dropdown.Value == val
                            TweenService:Create(optBtn, TweenInfo.new(0.15), { BackgroundTransparency = sel and 0.8 or 1 }):Play()
                        end)
                        
                        optBtn.MouseButton1Click:Connect(function()
                            if disabled then return end
                            if multi then
                                dropdown.Value[val] = not dropdown.Value[val] or nil
                                displayBtn.Text = getDisplayText()
                                rebuildOptions()
                                Library:SafeCallback(callback, dropdown.Value)
                                for _, fn in pairs(dropdown.Callbacks) do Library:SafeCallback(fn, dropdown.Value) end
                            else
                                dropdown.Value = val
                                displayBtn.Text = getDisplayText()
                                dropdown:Close()
                                Library:SafeCallback(callback, val)
                                for _, fn in pairs(dropdown.Callbacks) do Library:SafeCallback(fn, val) end
                            end
                        end)
                        
                        table.insert(optionButtons, optBtn)
                    end
                end
                
                local function positionPopup()
                    local absPos = displayBtn.AbsolutePosition
                    local absSize = displayBtn.AbsoluteSize
                    local itemH = 24
                    local listH = math.min(#dropdown.Values, maxVisible) * itemH + 8
                    popupFrame.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 2)
                    popupFrame.Size = UDim2.fromOffset(absSize.X, listH)
                end
                
                function dropdown:Open()
                    if disabled or dropdown.Opened then return end
                    dropdown.Opened = true
                    rebuildOptions()
                    positionPopup()
                    popupFrame.Visible = true
                end
                
                function dropdown:Close()
                    dropdown.Opened = false
                    popupFrame.Visible = false
                end
                
                function dropdown:SetValue(v)
                    dropdown.Value = v
                    displayBtn.Text = getDisplayText()
                    Library:SafeCallback(callback, v)
                    for _, fn in pairs(dropdown.Callbacks) do Library:SafeCallback(fn, v) end
                end
                function dropdown:SetValues(newVals)
                    dropdown.Values = newVals or {}
                    if dropdown.Opened then rebuildOptions() end
                end
                function dropdown:OnChanged(fn) table.insert(dropdown.Callbacks, fn) end
                
                displayBtn.MouseButton1Click:Connect(function()
                    if disabled then return end
                    if dropdown.Opened then dropdown:Close() else dropdown:Open() end
                end)
                
                -- Close on outside click
                Library:GiveSignal(UserInputService.InputBegan:Connect(function(input)
                    if not dropdown.Opened then return end
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        task.defer(function()
                            local mousePos = UserInputService:GetMouseLocation()
                            local pPos, pSize = popupFrame.AbsolutePosition, popupFrame.AbsoluteSize
                            local bPos, bSize = displayBtn.AbsolutePosition, displayBtn.AbsoluteSize
                            local inPopup = mousePos.X >= pPos.X and mousePos.X <= pPos.X + pSize.X and mousePos.Y >= pPos.Y and mousePos.Y <= pPos.Y + pSize.Y
                            local inBtn = mousePos.X >= bPos.X and mousePos.X <= bPos.X + bSize.X and mousePos.Y >= bPos.Y and mousePos.Y <= bPos.Y + bSize.Y
                            if not inPopup and not inBtn then dropdown:Close() end
                        end)
                    end
                end))
                
                Options[idx] = dropdown
                return dropdown
            end
            
            -- INPUT
            function Groupbox:AddInput(idx, info)
                info = info or {}
                local text = info.Text or "Input"
                local default = info.Default or ""
                local placeholder = info.Placeholder or ""
                local callback = info.Callback
                
                local input = { Type = "Input", Value = default, Callbacks = {} }
                
                local container = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 28),
                    Parent = elementList,
                })
                
                New("TextLabel", {
                    Size = UDim2.new(0.45, 0, 1, 0),
                    Text = text,
                    TextSize = 13,
                    TextTransparency = 0.3,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = container,
                })
                
                local textBox = New("TextBox", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0.5, 0, 0, 22),
                    BackgroundColor3 = Color3.fromRGB(26, 26, 32),
                    Text = default,
                    PlaceholderText = placeholder,
                    TextSize = 12,
                    ClearTextOnFocus = false,
                    Parent = container,
                })
                New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = textBox })
                New("UIStroke", { Color = Library.Scheme.OutlineColor, Thickness = 1, Parent = textBox })
                Library:AddToRegistry(textBox:FindFirstChildOfClass("UIStroke"), { Color = "OutlineColor" })
                New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = textBox })
                
                function input:SetValue(v)
                    input.Value = v
                    textBox.Text = v
                    Library:SafeCallback(callback, v)
                    for _, fn in pairs(input.Callbacks) do Library:SafeCallback(fn, v) end
                end
                function input:OnChanged(fn) table.insert(input.Callbacks, fn) end
                
                textBox.FocusLost:Connect(function()
                    input.Value = textBox.Text
                    Library:SafeCallback(callback, textBox.Text)
                    for _, fn in pairs(input.Callbacks) do Library:SafeCallback(fn, textBox.Text) end
                end)
                
                Options[idx] = input
                return input
            end
            
            -- LABEL (Obsidian-compatible overloads)
            -- Signatures: AddLabel(text), AddLabel(text, wrap), AddLabel(text, wrap, idx)
            --             AddLabel(idx, {Text, DoesWrap, Size})
            function Groupbox:AddLabel(arg1, arg2, arg3)
                local text, doesWrap, size, labelIdx
                
                if typeof(arg1) == "table" then
                    text = arg1.Text or ""
                    doesWrap = arg1.DoesWrap
                    size = arg1.Size
                elseif typeof(arg2) == "table" then
                    -- AddLabel(idx, {options})
                    labelIdx = arg1
                    text = arg2.Text or ""
                    doesWrap = arg2.DoesWrap
                    size = arg2.Size
                else
                    text = tostring(arg1 or "")
                    doesWrap = arg2
                    labelIdx = arg3
                end
                
                local lbl = New("TextLabel", {
                    Size = UDim2.new(1, 0, 0, size or 20),
                    Text = text,
                    TextSize = size or 13,
                    TextTransparency = 0.3,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = doesWrap or false,
                    AutomaticSize = doesWrap and Enum.AutomaticSize.Y or nil,
                    Parent = elementList,
                })
                
                local labelObj = { TextLabel = lbl, Row = lbl, Type = "Label", Value = text }
                function labelObj:SetText(t) lbl.Text = t; labelObj.Value = t end
                
                local chain = setmetatable({}, { __index = labelObj })
                function chain:AddColorPicker(cpIdx, cpInfo)
                    Groupbox:_AddColorPicker(cpIdx, cpInfo, lbl)
                    return chain
                end
                function chain:AddKeyPicker(kpIdx, kpInfo)
                    Groupbox:_AddKeyPicker(kpIdx, kpInfo, lbl, nil)
                    return chain
                end
                
                table.insert(Labels, labelObj)
                if labelIdx then Options[labelIdx] = labelObj end
                return chain
            end
            
            -- BUTTON (supports both old and new API)
            -- Old: AddButton(text, callback)
            -- New: AddButton({Text, Func, DoubleClick, Disabled, Visible, Risky})
            function Groupbox:AddButton(textOrInfo, cb)
                local text, func, doubleClick, disabled, risky
                if typeof(textOrInfo) == "table" then
                    text = textOrInfo.Text or "Button"
                    func = textOrInfo.Func or textOrInfo.Callback
                    doubleClick = textOrInfo.DoubleClick or false
                    disabled = textOrInfo.Disabled or false
                    risky = textOrInfo.Risky or false
                else
                    text = textOrInfo or "Button"
                    func = cb
                    doubleClick = false
                    disabled = false
                    risky = false
                end
                
                local holder = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 28),
                    Parent = elementList,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    Padding = UDim.new(0, 0),
                    Parent = holder,
                })
                
                local btn = New("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = Color3.fromRGB(26, 26, 32),
                    Text = doubleClick and (text .. " (2x)") or text,
                    TextSize = 13,
                    TextColor3 = risky and Library.Scheme.RedColor or Library.Scheme.FontColor,
                    TextTransparency = disabled and 0.5 or 0,
                    AutoButtonColor = false,
                    Parent = holder,
                })
                New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })
                New("UIStroke", { Color = Library.Scheme.OutlineColor, Thickness = 1, Parent = btn })
                Library:AddToRegistry(btn:FindFirstChildOfClass("UIStroke"), { Color = "OutlineColor" })
                if risky then Library:AddToRegistry(btn, { TextColor3 = "RedColor" }) end
                
                -- Hover
                btn.MouseEnter:Connect(function()
                    if disabled then return end
                    TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(34, 34, 42) }):Play()
                end)
                btn.MouseLeave:Connect(function()
                    TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(26, 26, 32) }):Play()
                end)
                
                local clickCount = 0
                btn.MouseButton1Click:Connect(function()
                    if disabled then return end
                    if doubleClick then
                        clickCount = clickCount + 1
                        if clickCount >= 2 then
                            clickCount = 0
                            btn.Text = text
                            Library:SafeCallback(func)
                        else
                            btn.Text = text .. " (click again)"
                            task.delay(0.5, function()
                                if clickCount > 0 then
                                    clickCount = 0
                                    btn.Text = doubleClick and (text .. " (2x)") or text
                                end
                            end)
                        end
                    else
                        Library:SafeCallback(func)
                    end
                end)
                
                local buttonObj = {
                    Instance = btn,
                    Holder = holder,
                    Text = text,
                    Visible = true,
                }
                
                function buttonObj:SetText(t) text = t; btn.Text = t end
                function buttonObj:SetDisabled(d) disabled = d; btn.TextTransparency = d and 0.5 or 0 end
                function buttonObj:SetVisible(v) holder.Visible = v end
                
                -- SubButton chaining
                function buttonObj:AddButton(subInfo)
                    local subText, subFunc, subDC
                    if typeof(subInfo) == "table" then
                        subText = subInfo.Text or "Sub"
                        subFunc = subInfo.Func or subInfo.Callback
                        subDC = subInfo.DoubleClick or false
                    else
                        subText = tostring(subInfo or "Sub")
                        subFunc = nil
                    end
                    
                    -- Resize main button to share space
                    btn.Size = UDim2.new(0.5, -1, 1, 0)
                    
                    local subBtn = New("TextButton", {
                        Size = UDim2.new(0.5, -1, 1, 0),
                        BackgroundColor3 = Color3.fromRGB(26, 26, 32),
                        Text = subText,
                        TextSize = 13,
                        AutoButtonColor = false,
                        Parent = holder,
                    })
                    New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = subBtn })
                    New("UIStroke", { Color = Library.Scheme.OutlineColor, Thickness = 1, Parent = subBtn })
                    Library:AddToRegistry(subBtn:FindFirstChildOfClass("UIStroke"), { Color = "OutlineColor" })
                    
                    subBtn.MouseEnter:Connect(function()
                        TweenService:Create(subBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(34, 34, 42) }):Play()
                    end)
                    subBtn.MouseLeave:Connect(function()
                        TweenService:Create(subBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(26, 26, 32) }):Play()
                    end)
                    
                    local subClicks = 0
                    subBtn.MouseButton1Click:Connect(function()
                        if subDC then
                            subClicks = subClicks + 1
                            if subClicks >= 2 then
                                subClicks = 0; subBtn.Text = subText
                                Library:SafeCallback(subFunc)
                            else
                                subBtn.Text = subText .. " (click again)"
                                task.delay(0.5, function()
                                    if subClicks > 0 then subClicks = 0; subBtn.Text = subText end
                                end)
                            end
                        else
                            Library:SafeCallback(subFunc)
                        end
                    end)
                    
                    return buttonObj
                end
                
                table.insert(Buttons, buttonObj)
                return buttonObj
            end
            
            -- CHECKBOX (same as Toggle but with square vi            function Groupbox:AddCheckbox(idx, info)
                info = info or {}
                local text = info.Text or "Checkbox"
                local default = info.Default or false
                local disabled = info.Disabled or false
                local callback = info.Callback
                local risky = info.Risky or false
                
                local toggle = { Type = "Toggle", Value = default, Callbacks = {} }
                
                local row = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 24),
                    Visible = info.Visible ~= false,
                    Parent = elementList,
                })
                
                local label = New("TextLabel", {
                    Size = UDim2.new(1, -26, 1, 0),
                    Text = text,
                    TextSize = 13,
                    TextTransparency = disabled and 0.5 or (risky and 0 or 0.3),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextColor3 = risky and Library.Scheme.RedColor or nil,
                    Parent = row,
                })
                if risky then Library:AddToRegistry(label, { TextColor3 = "RedColor" }) end
                toggle.TextLabel = label
                
                -- Square checkbox
                local boxSize = 16
                local boxFrame = New("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.fromOffset(boxSize, boxSize),
                    BackgroundColor3 = default and Library.Scheme.AccentColor or Color3.fromRGB(45, 45, 50),
                    Parent = row,
                })
                New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = boxFrame })
                
                -- UIStroke to make it clean
                local stroke = New("UIStroke", {
                    Color = default and Library.Scheme.AccentColor or Color3.fromRGB(55, 55, 60),
                    Thickness = 1,
                    Parent = boxFrame,
                })
                
                -- Checkmark
                local checkmark = New("TextLabel", {
                    Size = UDim2.fromScale(1, 1),
                    Text = "✓",
                    TextSize = 12,
                    TextTransparency = default and 0 or 1,
                    TextColor3 = Color3.new(1, 1, 1),
                    Parent = boxFrame,
                })
                
                local clickBtn = New("TextButton", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text = "",
                    AutoButtonColor = false,
                    Parent = row,
                })
                
                local function updateVisual(v)
                    local color = v and Library.Scheme.AccentColor or Color3.fromRGB(45, 45, 50)
                    local outline = v and Library.Scheme.AccentColor or Color3.fromRGB(55, 55, 60)
                    TweenService:Create(boxFrame, TweenInfo.new(0.2), { BackgroundColor3 = color }):Play()
                    TweenService:Create(stroke, TweenInfo.new(0.2), { Color = outline }):Play()
                    TweenService:Create(checkmark, TweenInfo.new(0.2), { TextTransparency = v and 0 or 1 }):Play()
                end     end
                
                function toggle:SetValue(v)
                    toggle.Value = v
                    updateVisual(v)
                    Library:SafeCallback(callback, v)
                    for _, fn in pairs(toggle.Callbacks) do Library:SafeCallback(fn, v) end
                end
                function toggle:OnChanged(fn) table.insert(toggle.Callbacks, fn) end
                function toggle:SetText(t) label.Text = t end
                function toggle:SetDisabled(d) disabled = d; label.TextTransparency = d and 0.5 or 0.3 end
                function toggle:SetVisible(v) row.Visible = v end
                
                clickBtn.MouseButton1Click:Connect(function()
                    if disabled then return end
                    toggle:SetValue(not toggle.Value)
                end)
                
                Toggles[idx] = toggle
                toggle.Row = row
                
                local chainObj = setmetatable({}, { __index = toggle })
                function chainObj:AddKeyPicker(kpIdx, kpInfo)
                    Groupbox:_AddKeyPicker(kpIdx, kpInfo, row, toggle)
                    return chainObj
                end
                function chainObj:AddColorPicker(cpIdx, cpInfo)
                    Groupbox:_AddColorPicker(cpIdx, cpInfo, row)
                    return chainObj
                end
                return chainObj
            end
            
            -- DIVIDER
            function Groupbox:AddDivider()
                New("Frame", {
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = "OutlineColor",
                    Parent = elementList,
                })
            end
            
            -- KEYPICKER (Full implementation with always/toggle/hold/press modes)
            function Groupbox:_AddKeyPicker(kpIdx, kpInfo, parentRow, parentToggle)
                kpInfo = kpInfo or {}
                local kp = {
                    Type = "KeyPicker",
                    Value = kpInfo.Default or "None",
                    Mode = kpInfo.Mode or "Toggle",
                    Modes = kpInfo.Modes or { "Always", "Toggle", "Hold" },
                    Modifiers = kpInfo.DefaultModifiers or {},
                    SyncToggleState = kpInfo.SyncToggleState or false,
                    NoUI = kpInfo.NoUI or false,
                    Text = kpInfo.Text or "",
                    Callbacks = {},
                    ClickCb = nil,
                    ChangedCb = kpInfo.ChangedCallback,
                    
                    _state = false,
                    _listening = false,
                }
                
                -- Map key names to KeyCode/UserInputType
                local KEY_MAP = {
                    MB1 = Enum.UserInputType.MouseButton1,
                    MB2 = Enum.UserInputType.MouseButton2,
                    MB3 = Enum.UserInputType.MouseButton3,
                }
                
                local function keyToEnum(keyName)
                    if KEY_MAP[keyName] then return KEY_MAP[keyName] end
                    local ok, kc = pcall(function() return Enum.KeyCode[keyName] end)
                    return ok and kc or nil
                end
                
                local function enumToName(enum)
                    if not enum then return "None" end
                    for name, e in pairs(KEY_MAP) do
                        if e == enum then return name end
                    end
                    if typeof(enum) == "EnumItem" then return enum.Name end
                    return "None"
                end
                
                -- Small keybind display button on the right side of parentRow
                local kpBtn = New("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, parentToggle and -42 or 0, 0.5, 0),
                    Size = UDim2.fromOffset(44, 18),
                    BackgroundColor3 = Color3.fromRGB(30, 30, 38),
                    Text = "[" .. tostring(kp.Value) .. "]",
                    TextSize = 11,
                    AutoButtonColor = false,
                    ZIndex = 5,
                    Parent = parentRow,
                })
                New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = kpBtn })
                
                local function updateDisplay()
                    if kp._listening then
                        kpBtn.Text = "[...]"
                    else
                        kpBtn.Text = "[" .. tostring(kp.Value) .. "]"
                    end
                end
                
                function kp:GetState()
                    if kp.Mode == "Always" then return true end
                    return kp._state
                end
                
                function kp:SetValue(v)
                    if typeof(v) == "table" then
                        kp.Value = v[1] or kp.Value
                        if v[2] then kp.Mode = v[2] end
                        kp.Modifiers = v[3] or {}
                    else
                        kp.Value = tostring(v)
                    end
                    updateDisplay()
                end
                
                function kp:OnClick(fn) kp.ClickCb = fn end
                function kp:OnChanged(fn) table.insert(kp.Callbacks, fn) end
                function kp:SetText(t) kp.Text = t end
                function kp:Update() updateDisplay() end
                
                -- Click to start listening
                kpBtn.MouseButton1Click:Connect(function()
                    kp._listening = true
                    updateDisplay()
                end)
                
                -- Right-click to cycle mode
                kpBtn.MouseButton2Click:Connect(function()
                    local idx = table.find(kp.Modes, kp.Mode) or 0
                    kp.Mode = kp.Modes[(idx % #kp.Modes) + 1]
                    Library:Notify({ Title = "Keybind", Description = kp.Text .. ": " .. kp.Mode, Time = 1.5 })
                end)
                
                -- Listen for key press
                Library:GiveSignal(UserInputService.InputBegan:Connect(function(input, gpe)
                    if Library.Unloaded then return end
                    
                    -- If listening for new keybind
                    if kp._listening then
                        local keyName
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            keyName = input.KeyCode.Name
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                            keyName = "MB1"
                        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                            keyName = "MB2"
                        elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                            keyName = "MB3"
                        end
                        
                        if keyName then
                            kp.Value = keyName
                            kp._listening = false
                            updateDisplay()
                            Library:SafeCallback(kp.ChangedCb, keyName, kp.Modifiers)
                            for _, fn in pairs(kp.Callbacks) do Library:SafeCallback(fn, keyName) end
                        end
                        return
                    end
                    
                    -- Check if this input matches our keybind
                    if gpe then return end
                    local keyEnum = keyToEnum(kp.Value)
                    if not keyEnum then return end
                    
                    local matches = false
                    if typeof(keyEnum) == "EnumItem" then
                        if keyEnum.EnumType == Enum.KeyCode then
                            matches = input.KeyCode == keyEnum
                        elseif keyEnum.EnumType == Enum.UserInputType then
                            matches = input.UserInputType == keyEnum
                        end
                    end
                    
                    if matches then
                        if kp.Mode == "Toggle" then
                            kp._state = not kp._state
                            Library:SafeCallback(kp.ClickCb, kp._state)
                            if kp.SyncToggleState and parentToggle then
                                parentToggle:SetValue(kp._state)
                            end
                        elseif kp.Mode == "Hold" then
                            kp._state = true
                            Library:SafeCallback(kp.ClickCb, true)
                            if kp.SyncToggleState and parentToggle then
                                parentToggle:SetValue(true)
                            end
                        elseif kp.Mode == "Press" then
                            Library:SafeCallback(kp.ClickCb, true)
                        end
                        Library:SafeCallback(kpInfo.Callback, kp._state)
                    end
                end))
                
                Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
                    if Library.Unloaded then return end
                    if kp.Mode ~= "Hold" then return end
                    
                    local keyEnum = keyToEnum(kp.Value)
                    if not keyEnum then return end
                    
                    local matches = false
                    if typeof(keyEnum) == "EnumItem" then
                        if keyEnum.EnumType == Enum.KeyCode then
                            matches = input.KeyCode == keyEnum
                        elseif keyEnum.EnumType == Enum.UserInputType then
                            matches = input.UserInputType == keyEnum
                        end
                    end
                    
                    if matches then
                        kp._state = false
                        Library:SafeCallback(kp.ClickCb, false)
                        Library:SafeCallback(kpInfo.Callback, false)
                        if kp.SyncToggleState and parentToggle then
                            parentToggle:SetValue(false)
                        end
                    end
                end))
                
                -- Sync toggle -> keybind state
                if kp.SyncToggleState and parentToggle then
                    parentToggle:OnChanged(function(v)
                        kp._state = v
                    end)
                end
                
                Options[kpIdx] = kp
                return kp
            end
            
            -- COLORPICKER (with swatch + popup panel)
            function Groupbox:_AddColorPicker(cpIdx, cpInfo, parentRow)
                cpInfo = cpInfo or {}
                local defaultColor = cpInfo.Default or Color3.new(1, 1, 1)
                local hasAlpha = cpInfo.Transparency ~= nil
                local defaultAlpha = cpInfo.Transparency or 0
                local callback = cpInfo.Callback
                local title = cpInfo.Title or cpIdx or "Color"
                
                local cp = {
                    Type = "ColorPicker",
                    Value = defaultColor,
                    Transparency = defaultAlpha,
                    Callbacks = {},
                    Opened = false,
                }
                
                -- Color swatch button on the right side of parentRow
                local swatchSize = 18
                local swatch = New("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.fromOffset(swatchSize, swatchSize),
                    BackgroundColor3 = defaultColor,
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 5,
                    Parent = parentRow,
                })
                New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = swatch })
                New("UIStroke", { Color = Library.Scheme.OutlineColor, Thickness = 1, Parent = swatch })
                Library:AddToRegistry(swatch:FindFirstChildOfClass("UIStroke"), { Color = "OutlineColor" })
                
                -- Popup panel
                local popupPanel = New("Frame", {
                    BackgroundColor3 = Color3.fromRGB(18, 18, 22),
                    Size = UDim2.fromOffset(200, hasAlpha and 230 or 200),
                    Position = UDim2.fromOffset(0, 0),
                    Visible = false,
                    ZIndex = 60,
                    Parent = ScreenGui,
                })
                New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = popupPanel })
                New("UIStroke", { Color = Library.Scheme.OutlineColor, Thickness = 1, Parent = popupPanel })
                Library:AddToRegistry(popupPanel:FindFirstChildOfClass("UIStroke"), { Color = "OutlineColor" })
                New("UIPadding", {
                    PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
                    PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
                    Parent = popupPanel,
                })
                
                -- Title
                New("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 16),
                    Text = title,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 61,
                    Parent = popupPanel,
                })
                
                -- Saturation/Value canvas
                local h, s, v = defaultColor:ToHSV()
                local canvasSize = 184
                local canvas = New("Frame", {
                    Position = UDim2.fromOffset(0, 22),
                    Size = UDim2.new(1, 0, 0, 120),
                    BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                    ZIndex = 61,
                    Parent = popupPanel,
                })
                New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = canvas })
                
                -- White gradient overlay
                local whiteGrad = New("Frame", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    ZIndex = 62,
                    Parent = canvas,
                })
                New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = whiteGrad })
                New("UIGradient", { Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(1,1,1)), Transparency = NumberSequence.new(0, 1), Rotation = 0, Parent = whiteGrad })
                
                -- Black gradient overlay
                local blackGrad = New("Frame", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundColor3 = Color3.new(0, 0, 0),
                    ZIndex = 63,
                    Parent = canvas,
                })
                New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = blackGrad })
                New("UIGradient", { Color = ColorSequence.new(Color3.new(0,0,0), Color3.new(0,0,0)), Transparency = NumberSequence.new(1, 0), Rotation = 90, Parent = blackGrad })
                
                -- Canvas cursor
                local cursorDot = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(s, 0, 1 - v, 0),
                    Size = UDim2.fromOffset(10, 10),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    ZIndex = 65,
                    Parent = canvas,
                })
                New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = cursorDot })
                New("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Parent = cursorDot })
                
                -- Hue bar
                local hueBar = New("Frame", {
                    Position = UDim2.fromOffset(0, 148),
                    Size = UDim2.new(1, 0, 0, 14),
                    ZIndex = 61,
                    Parent = popupPanel,
                })
                New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = hueBar })
                -- Rainbow gradient for hue
                local hueColors = {}
                for i = 0, 6 do
                    table.insert(hueColors, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
                end
                New("UIGradient", { Color = ColorSequence.new(hueColors), Parent = hueBar })
                
                local hueCursor = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(h, 0, 0.5, 0),
                    Size = UDim2.fromOffset(6, 18),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    ZIndex = 62,
                    Parent = hueBar,
                })
                New("UICorner", { CornerRadius = UDim.new(0, 2), Parent = hueCursor })
                
                -- Hex input
                local hexBox = New("TextBox", {
                    Position = UDim2.fromOffset(0, 170),
                    Size = UDim2.new(1, 0, 0, 22),
                    BackgroundColor3 = Color3.fromRGB(26, 26, 32),
                    Text = "#" .. defaultColor:ToHex(),
                    PlaceholderText = "#ffffff",
                    TextSize = 12,
                    ClearTextOnFocus = true,
                    ZIndex = 61,
                    Parent = popupPanel,
                })
                New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = hexBox })
                New("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = hexBox })
                
                local function applyColor(newH, newS, newV)
                    h, s, v = newH, newS, newV
                    local color = Color3.fromHSV(h, s, v)
                    cp.Value = color
                    swatch.BackgroundColor3 = color
                    canvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                    cursorDot.Position = UDim2.new(s, 0, 1 - v, 0)
                    hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
                    hexBox.Text = "#" .. color:ToHex()
                    Library:SafeCallback(callback, color)
                    for _, fn in pairs(cp.Callbacks) do Library:SafeCallback(fn, color) end
                end
                
                -- Canvas drag
                local draggingCanvas = false
                local canvasInput = New("TextButton", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 64,
                    AutoButtonColor = false,
                    Parent = canvas,
                })
                canvasInput.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        draggingCanvas = true
                        local pct_x = math.clamp((input.Position.X - canvas.AbsolutePosition.X) / canvas.AbsoluteSize.X, 0, 1)
                        local pct_y = math.clamp((input.Position.Y - canvas.AbsolutePosition.Y) / canvas.AbsoluteSize.Y, 0, 1)
                        applyColor(h, pct_x, 1 - pct_y)
                    end
                end)
                canvasInput.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        draggingCanvas = false
                    end
                end)
                
                -- Hue drag
                local draggingHue = false
                local hueInput = New("TextButton", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 62,
                    AutoButtonColor = false,
                    Parent = hueBar,
                })
                hueInput.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        draggingHue = true
                        local pct = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
                        applyColor(pct, s, v)
                    end
                end)
                hueInput.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        draggingHue = false
                    end
                end)
                
                Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                        if draggingCanvas then
                            local pct_x = math.clamp((input.Position.X - canvas.AbsolutePosition.X) / canvas.AbsoluteSize.X, 0, 1)
                            local pct_y = math.clamp((input.Position.Y - canvas.AbsolutePosition.Y) / canvas.AbsoluteSize.Y, 0, 1)
                            applyColor(h, pct_x, 1 - pct_y)
                        elseif draggingHue then
                            local pct = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
                            applyColor(pct, s, v)
                        end
                    end
                end))
                
                -- Hex input
                hexBox.FocusLost:Connect(function()
                    local hex = hexBox.Text:gsub("#", "")
                    local ok, color = pcall(Color3.fromHex, hex)
                    if ok and color then
                        local nh, ns, nv = color:ToHSV()
                        applyColor(nh, ns, nv)
                    else
                        hexBox.Text = "#" .. cp.Value:ToHex()
                    end
                end)
                
                function cp:SetValueRGB(color, transparency)
                    if color then
                        cp.Value = color
                        local nh, ns, nv = color:ToHSV()
                        h, s, v = nh, ns, nv
                        swatch.BackgroundColor3 = color
                        canvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                        cursorDot.Position = UDim2.new(s, 0, 1 - v, 0)
                        hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
                        hexBox.Text = "#" .. color:ToHex()
                    end
                    if transparency then cp.Transparency = transparency end
                    for _, fn in pairs(cp.Callbacks) do Library:SafeCallback(fn, cp.Value) end
                end
                function cp:OnChanged(fn) table.insert(cp.Callbacks, fn) end
                
                -- Position popup near swatch
                local function positionPopup()
                    local absPos = swatch.AbsolutePosition
                    popupPanel.Position = UDim2.fromOffset(absPos.X - 200, absPos.Y + 24)
                end
                
                swatch.MouseButton1Click:Connect(function()
                    cp.Opened = not cp.Opened
                    if cp.Opened then positionPopup() end
                    popupPanel.Visible = cp.Opened
                end)
                
                -- Close on outside click
                Library:GiveSignal(UserInputService.InputBegan:Connect(function(input)
                    if not cp.Opened then return end
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        task.defer(function()
                            local mousePos = UserInputService:GetMouseLocation()
                            local pPos, pSize = popupPanel.AbsolutePosition, popupPanel.AbsoluteSize
                            local inPanel = mousePos.X >= pPos.X and mousePos.X <= pPos.X + pSize.X and mousePos.Y >= pPos.Y and mousePos.Y <= pPos.Y + pSize.Y
                            local sPos, sSize = swatch.AbsolutePosition, swatch.AbsoluteSize
                            local inSwatch = mousePos.X >= sPos.X and mousePos.X <= sPos.X + sSize.X and mousePos.Y >= sPos.Y and mousePos.Y <= sPos.Y + sSize.Y
                            if not inPanel and not inSwatch then
                                cp.Opened = false
                                popupPanel.Visible = false
                            end
                        end)
                    end
                end))
                
                Options[cpIdx] = cp
                return cp
            end
            
            return Groupbox
        end
        
        function Tab:AddLeftGroupbox(name, icon)
            return CreateGroupbox(name, icon, leftCol)
        end
        function Tab:AddRightGroupbox(name, icon)
            return CreateGroupbox(name, icon, rightCol)
        end
        
        -- TABBOX (container with multiple sub-grouped tabs)
        local function CreateTabbox(parentCol)
            local tbFrame = New("Frame", {
                BackgroundColor3 = "MainColor",
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = parentCol,
            })
            New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = tbFrame })
            New("UIStroke", { Color = Library.Scheme.OutlineColor, Thickness = 1, Parent = tbFrame })
            Library:AddToRegistry(tbFrame:FindFirstChildOfClass("UIStroke"), { Color = "OutlineColor" })
            
            -- Tab header buttons row
            local headerRow = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 28),
                Parent = tbFrame,
            })
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Parent = headerRow,
            })
            
            -- Bottom border under header
            New("Frame", {
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 8, 1, 0),
                Size = UDim2.new(1, -16, 0, 1),
                BackgroundColor3 = "OutlineColor",
                Parent = headerRow,
            })
            
            -- Content area
            local contentArea = New("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 28),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = tbFrame,
            })
            
            -- Layout for tabbox frame
            New("UIListLayout", { Padding = UDim.new(0, 0), Parent = tbFrame })
            
            local Tabbox = { Tabs = {}, ActiveTab = nil, BoxHolder = tbFrame }
            
            function Tabbox:AddTab(tabName)
                tabName = tabName or "Tab"
                
                local tabBtnWidth = 1 / math.max(#Tabbox.Tabs + 1, 1)
                
                local tabHeaderBtn = New("TextButton", {
                    Size = UDim2.new(tabBtnWidth, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = tabName,
                    TextSize = 12,
                    TextTransparency = 0.5,
                    AutoButtonColor = false,
                    Parent = headerRow,
                })
                
                local tabContent = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Visible = false,
                    Parent = contentArea,
                })
                New("UIPadding", {
                    PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
                    PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
                    Parent = tabContent,
                })
                local tabElementList = tabContent
                New("UIListLayout", { Padding = UDim.new(0, 2), Parent = tabElementList })
                
                local subTab = { Container = tabContent, Button = tabHeaderBtn, ButtonHolder = tabHeaderBtn }
                table.insert(Tabbox.Tabs, subTab)
                
                -- Rebuild all tab header widths
                local count = #Tabbox.Tabs
                for _, st in pairs(Tabbox.Tabs) do
                    st.Button.Size = UDim2.new(1 / count, 0, 1, 0)
                end
                
                -- Inherit groupbox element methods via inline mode
                local gb = CreateGroupbox(nil, nil, tabContent, true)
                -- Copy methods to subTab
                for k, fn in pairs(gb) do
                    if typeof(fn) == "function" then subTab[k] = fn end
                end
                subTab.Elements = {}
                subTab.DependencyBoxes = {}
                
                function subTab:Show()
                    Tabbox:SelectTab(subTab)
                end
                
                function subTab:Resize() end
                
                tabHeaderBtn.MouseButton1Click:Connect(function()
                    Tabbox:SelectTab(subTab)
                end)
                
                -- Auto-select first tab
                if #Tabbox.Tabs == 1 then
                    Tabbox:SelectTab(subTab)
                end
                
                return subTab
            end
            
            function Tabbox:SelectTab(subTab)
                Tabbox.ActiveTab = subTab
                for _, st in pairs(Tabbox.Tabs) do
                    st.Button.TextTransparency = (st == subTab) and 0 or 0.5
                    if st.Container then
                        st.Container.Visible = (st == subTab)
                    end
                end
            end
            
            return Tabbox
        end
        
        function Tab:AddLeftTabbox(name)
            return CreateTabbox(leftCol)
        end
        function Tab:AddRightTabbox(name)
            return CreateTabbox(rightCol)
        end
        
        return Tab
    end
    
    function Window:SelectTab(tab)
        for _, t in pairs(Library.Tabs) do
            t.TabContainer.Visible = false
            t.TabLabel.TextTransparency = 0.5
            t.TabLabel.TextColor3 = Library.Scheme.FontColor
        end
        tab.TabContainer.Visible = true
        tab.TabLabel.TextTransparency = 0
        tab.TabLabel.TextColor3 = Library.Scheme.WhiteColor
        Window.ActiveTab = tab
    end
    
    -- Toggle keybind (supports both KeyCode and KeyPicker object)
    Library:GiveSignal(UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if Library.ToggleKeybind then
            if typeof(Library.ToggleKeybind) == "table" and Library.ToggleKeybind.Value then
                -- KeyPicker object — check if key matches
                local kpVal = Library.ToggleKeybind.Value
                local matches = false
                if kpVal == "MB1" then matches = input.UserInputType == Enum.UserInputType.MouseButton1
                elseif kpVal == "MB2" then matches = input.UserInputType == Enum.UserInputType.MouseButton2
                else
                    local ok, kc = pcall(function() return Enum.KeyCode[kpVal] end)
                    if ok and kc then matches = input.KeyCode == kc end
                end
                if matches then Window:Toggle() end
            elseif typeof(Library.ToggleKeybind) == "EnumItem" and input.KeyCode == Library.ToggleKeybind then
                Window:Toggle()
            end
        end
    end))
    
    --==========================================================================
    -- KEYBIND FRAME (Floating mini keybind list)
    --==========================================================================
    local KeybindFrame = New("Frame", {
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.fromOffset(10, 300),
        Size = UDim2.fromOffset(180, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = "MainColor",
        Visible = false,
        Parent = ScreenGui,
    })
    New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = KeybindFrame })
    New("UIStroke", { Color = Library.Scheme.OutlineColor, Thickness = 1, Parent = KeybindFrame })
    Library:AddToRegistry(KeybindFrame:FindFirstChildOfClass("UIStroke"), { Color = "OutlineColor" })
    New("UIPadding", {
        PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
        Parent = KeybindFrame,
    })
    New("UIListLayout", { Padding = UDim.new(0, 2), Parent = KeybindFrame })
    
    -- Title
    New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        Text = "Keybinds",
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = KeybindFrame,
    })
    New("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = "OutlineColor",
        Parent = KeybindFrame,
    })
    
    Library.KeybindFrame = KeybindFrame
    Library.KeybindContainer = KeybindFrame
    MakeDraggable(KeybindFrame, KeybindFrame)
    
    --==========================================================================
    -- MOBILE TOGGLE BUTTON
    --==========================================================================
    if Library.IsMobile then
        local mobileBtn = New("TextButton", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 6, 0.5, 0),
            Size = UDim2.fromOffset(36, 36),
            BackgroundColor3 = "MainColor",
            Text = "☰",
            TextSize = 20,
            AutoButtonColor = false,
            Parent = ScreenGui,
        })
        New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = mobileBtn })
        New("UIStroke", { Color = Library.Scheme.OutlineColor, Thickness = 1, Parent = mobileBtn })
        Library:AddToRegistry(mobileBtn:FindFirstChildOfClass("UIStroke"), { Color = "OutlineColor" })
        MakeDraggable(mobileBtn, mobileBtn)
        
        mobileBtn.MouseButton1Click:Connect(function()
            Window:Toggle()
        end)
    end
    
    return Window
end

--==============================================================================
-- DRAGGABLE LABEL (Watermark)
--==============================================================================
function Library:AddDraggableLabel(text)
    local label = New("Frame", {
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.fromOffset(10, 10),
        Size = UDim2.fromOffset(0, 24),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = "MainColor",
        Parent = ScreenGui,
    })
    New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = label })
    New("UIStroke", { Color = Library.Scheme.OutlineColor, Thickness = 1, Parent = label })
    Library:AddToRegistry(label:FindFirstChildOfClass("UIStroke"), { Color = "OutlineColor" })
    New("UIPadding", {
        PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
        Parent = label,
    })
    
    local lbl = New("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        AutomaticSize = Enum.AutomaticSize.X,
        Text = text or "",
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = label,
    })
    
    -- Make draggable
    local dragging, dragStart, startPos
    label.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = label.Position
        end
    end)
    label.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            label.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
    
    local obj = {}
    function obj:SetText(t) lbl.Text = t end
    function obj:SetVisible(v) label.Visible = v end
    return obj
end

--==============================================================================
-- UTILITY METHODS (ThemeManager/SaveManager compatibility)
--==============================================================================
function Library:SetNotifySide(side)
    Library.NotifySide = side
    -- Reposition notification area
    if side == "Left" then
        if Library.NotificationArea then
            Library.NotificationArea.AnchorPoint = Vector2.new(0, 0)
            Library.NotificationArea.Position = UDim2.new(0, 10, 0, 10)
        end
    else
        if Library.NotificationArea then
            Library.NotificationArea.AnchorPoint = Vector2.new(1, 0)
            Library.NotificationArea.Position = UDim2.new(1, -10, 0, 10)
        end
    end
end

function Library:SetDPIScale(scale)
    Library.DPIScale = (scale or 100) / 100
    if Library.MainFrame then
        local uiScale = Library.MainFrame:FindFirstChildOfClass("UIScale")
        if uiScale then
            uiScale.Scale = Library.DPIScale
        end
    end
end

-- Store notification area reference
Library.NotificationArea = nil
pcall(function()
    -- Find notification area created during init
    for _, child in pairs(ScreenGui:GetChildren()) do
        if child:IsA("Frame") and child:FindFirstChildOfClass("UIListLayout") and child.Size == UDim2.new(0, 300, 1, -20) then
            Library.NotificationArea = child
            break
        end
    end
end)

-- Export
getgenv().Library = Library
getgenv().Toggles = Toggles
getgenv().Options = Options

return Library
