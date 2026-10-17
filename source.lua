--==================================================================
-- CandyLib v1.0.1 (Studio & FileSystem fixes)
--==================================================================

local CandyLib = {}
CandyLib.Version = '1.0.1'
CandyLib.Flags   = {}
CandyLib.Signals = {}
CandyLib.UnloadEnabled = true

do
    local n = 'CANDY_SKIP'
    if getfenv then getfenv()[n] = getfenv()[n] or function(f) return f end end
end

cloneref       = cloneref       or function(i) return i end
gethui         = gethui         or get_hidden_gui
getcustomasset = getcustomasset or getsynasset
getgenv        = getgenv        or getfenv

-- ---------- Принудительная эмуляция файлов для Studio ----------
if game:GetService('RunService'):IsStudio() then
    local folder = game:GetService('ReplicatedFirst'):FindFirstChild('CANDY_FS')
        or Instance.new('Folder', game:GetService('ReplicatedFirst'))
    folder.Name = 'CANDY_FS'
    local function split(p) return (string.find(p,'/',1,true) and string.split(p,'/')) or (string.find(p,'\\',1,true) and string.split(p,'\\')) or {p} end
    local function walk(p) local b=folder for _,v in next,split(p) do if b then b=b[v] end end return b end
    getgenv().writefile = function(p, c)
        local b=folder; local seg=split(p)
        for i,v in next,seg do
            local ch=b:FindFirstChild(v)
            if not ch then ch=Instance.new('StringValue',b); ch.Name=tostring(v); ch.Value=c
            else if ch:IsA('StringValue') then ch.Value=c end; b=ch end
        end
    end
    getgenv().readfile = function(p) local r = walk(p); return r and r.Value or '' end
    getgenv().isfile   = function(p) local s,r=pcall(walk,p); return s and r and not r:IsA('Folder') end
    getgenv().isfolder = function(p) local s,r=pcall(walk,p); return s and r and r:IsA('Folder') end
    getgenv().makefolder = function(p)
        local b=folder
        for _,v in next,split(p) do
            local ch=b:FindFirstChild(v)
            if not ch then ch=Instance.new('Folder',b); ch.Name=tostring(v) else b=ch end
        end
    end
    getgenv().listfiles = function(p)
        local out={}
        local f = walk(p)
        if f then for _,v in next,f:GetChildren() do table.insert(out,p..'/'..tostring(v)) end end
        return out
    end
    getgenv().delfile = function(p)
        local b=folder; local seg=split(p)
        for i,v in next,seg do
            local ch=b:FindFirstChild(v)
            if i==#seg and ch then ch:Destroy() else b=ch end
        end
    end
    writefile  = getgenv().writefile
    readfile   = getgenv().readfile
    isfile     = getgenv().isfile
    isfolder   = getgenv().isfolder
    makefolder = getgenv().makefolder
    listfiles  = getgenv().listfiles
    delfile    = getgenv().delfile
else
    writefile  = writefile  or getgenv().writefile
    readfile   = readfile   or getgenv().readfile
    isfile     = isfile     or getgenv().isfile
    isfolder   = isfolder   or getgenv().isfolder
    makefolder = makefolder or getgenv().makefolder
    listfiles  = listfiles  or getgenv().listfiles
    delfile    = delfile    or getgenv().delfile
end

-- ---------- Services ----------
local TweenService       = cloneref(game:GetService('TweenService'))
local UserInputService   = cloneref(game:GetService('UserInputService'))
local TextService        = cloneref(game:GetService('TextService'))
local RunService         = cloneref(game:GetService('RunService'))
local Players            = cloneref(game:GetService('Players'))
local HttpService        = cloneref(game:GetService('HttpService'))
local LocalPlayer        = Players.LocalPlayer
local CoreGui            = (gethui and gethui()) or cloneref(game:FindFirstChild('CoreGui')) or cloneref(LocalPlayer.PlayerGui)
local Mouse              = LocalPlayer:GetMouse()
local ProtectGui         = protect_gui or (syn and syn.protect_gui) or function(s) return s end

-- ---------- Theme ----------
local Theme = {
    BG         = Color3.fromRGB(22, 22, 26),
    Panel      = Color3.fromRGB(28, 28, 33),
    PanelAlt   = Color3.fromRGB(34, 34, 40),
    Border     = Color3.fromRGB(52, 52, 60),
    BorderSoft = Color3.fromRGB(42, 42, 50),
    Text       = Color3.fromRGB(242, 242, 247),
    TextMuted  = Color3.fromRGB(150, 150, 160),
    Accent     = Color3.fromRGB(255, 255, 255),
    AccentGlow = Color3.fromRGB(180, 180, 200),
    Danger     = Color3.fromRGB(220, 100, 110),
}
CandyLib.Theme = Theme

-- ---------- Fonts ----------
local IconRegular = Font.new('rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
local IconBold    = Font.new('rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json', Enum.FontWeight.Bold,    Enum.FontStyle.Normal)
CandyLib.IconRegular = IconRegular
CandyLib.IconBold    = IconBold

-- ---------- ScreenGui ----------
CandyLib.ScreenGui = Instance.new('ScreenGui')
CandyLib.ScreenGui.Name = 'CandyLib_'..math.random(100000,999999)
CandyLib.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
CandyLib.ScreenGui.ResetOnSpawn   = false
CandyLib.ScreenGui.IgnoreGuiInset = true
CandyLib.ScreenGui.DisplayOrder   = 1000
ProtectGui(CandyLib.ScreenGui)
CandyLib.ScreenGui.Parent = CoreGui

CandyLib.RandomString = function() return 'cnd_'..math.random(100000,999999) end
CandyLib.UserProfile  = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)

-- ---------- Utilities ----------
local function Tween(o,i,p) local t=TweenService:Create(o, i or TweenInfo.new(0.15,Enum.EasingStyle.Quad), p); t:Play(); return t end
local function Track(s) table.insert(CandyLib.Signals, s); return s end
local function Glow(parent, color, thick)
    local g = Instance.new('UIStroke')
    g.Color = color or Theme.Accent
    g.Thickness = thick or 1.5
    g.Transparency = 0.55
    g.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    g.Parent = parent
    return g
end
local function CreateInput(parent, cb)
    local b = Instance.new('TextButton')
    b.BackgroundTransparency = 1
    b.BorderSizePixel = 0
    b.Size = UDim2.fromScale(1,1)
    b.ZIndex = (parent.ZIndex or 1)+50
    b.Text = ''
    b.Parent = parent
    if cb then
        local s = b.MouseButton1Click:Connect(cb)
        return b, s
    end
    return b
end
local function MouseOver(frame)
    if not frame or not frame.Parent then return false end
    local p,s = frame.AbsolutePosition, frame.AbsoluteSize
    return Mouse.X>=p.X and Mouse.X<=p.X+s.X and Mouse.Y>=p.Y and Mouse.Y<=p.Y+s.Y
end
CandyLib.IsMouseOverFrame = MouseOver

local function Drag(drag, move, speed)
    local on, start, sPos
    local info = TweenInfo.new(speed or 0.14, Enum.EasingStyle.Quad)
    Track(drag.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            on=true; start=inp.Position; sPos=move.Position
            inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then on=false end end)
        end
    end))
    Track(UserInputService.InputChanged:Connect(function(inp)
        if on and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local d = inp.Position - start
            Tween(move, info, {Position = UDim2.new(sPos.X.Scale, sPos.X.Offset+d.X, sPos.Y.Scale, sPos.Y.Offset+d.Y)})
        end
    end))
end
CandyLib.Drag = Drag

local function Round(obj, r)
    local c = Instance.new('UICorner')
    c.CornerRadius = UDim.new(0, r or 10)
    c.Parent = obj
    return c
end
local function Stroke(obj, color, transparency, thickness)
    local s = Instance.new('UIStroke')
    s.Color = color or Theme.Border
    s.Transparency = transparency or 0.5
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
    return s
end

-- ---------- Notifications ----------
function CandyLib:Notify(opts)
    opts = opts or {}
    local title   = opts.Title   or 'Notification'
    local content = opts.Content or ''
    local dur     = opts.Duration or 3
    local icon    = opts.Icon    or 'check'

    local holder = self._NotifyHolder
    if not holder then
        holder = Instance.new('Frame')
        holder.Name = 'CandyNotify'
        holder.BackgroundTransparency = 1
        holder.Position = UDim2.new(1,-20,0,20)
        holder.AnchorPoint = Vector2.new(1,0)
        holder.Size = UDim2.new(0,300,0,0)
        holder.Parent = self.ScreenGui
        local l = Instance.new('UIListLayout')
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.HorizontalAlignment = Enum.HorizontalAlignment.Right
        l.Padding = UDim.new(0,6)
        l.Parent = holder
        self._NotifyHolder = holder
    end

    local box = Instance.new('Frame')
    box.BackgroundColor3 = Theme.Panel
    box.BackgroundTransparency = 1
    box.Size = UDim2.new(1,0,0,52)
    box.LayoutOrder = -os.clock()*1000
    box.ClipsDescendants = true
    box.Parent = holder
    Round(box, 12)
    local stroke = Stroke(box, Theme.Border, 1)
    Glow(box, Theme.Accent, 1)

    local iconBox = Instance.new('Frame')
    iconBox.BackgroundColor3 = Theme.PanelAlt
    iconBox.BackgroundTransparency = 1
    iconBox.Size = UDim2.new(0,36,0,36)
    iconBox.Position = UDim2.new(0,9,0.5,-18)
    iconBox.ZIndex = 3
    iconBox.Parent = box
    Round(iconBox, 9)

    local iconLbl = Instance.new('TextLabel')
    iconLbl.BackgroundTransparency = 1
    iconLbl.Size = UDim2.fromScale(1,1)
    iconLbl.ZIndex = 4
    iconLbl.FontFace = IconBold
    iconLbl.Text = icon
    iconLbl.TextColor3 = Theme.Text
    iconLbl.TextSize = 18
    iconLbl.TextTransparency = 1
    iconLbl.Parent = iconBox

    local titleLbl = Instance.new('TextLabel')
    titleLbl.BackgroundTransparency = 1
    titleLbl.Position = UDim2.new(0,53,0,8)
    titleLbl.Size = UDim2.new(1,-64,0,18)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.Text = title
    titleLbl.TextColor3 = Theme.Text
    titleLbl.TextSize = 14
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.TextTransparency = 1
    titleLbl.Parent = box

    local contentLbl = Instance.new('TextLabel')
    contentLbl.BackgroundTransparency = 1
    contentLbl.Position = UDim2.new(0,53,0,27)
    contentLbl.Size = UDim2.new(1,-64,0,16)
    contentLbl.Font = Enum.Font.Gotham
    contentLbl.Text = content
    contentLbl.TextColor3 = Theme.TextMuted
    contentLbl.TextSize = 12
    contentLbl.TextXAlignment = Enum.TextXAlignment.Left
    contentLbl.TextTransparency = 1
    contentLbl.Parent = box

    Tween(box, TweenInfo.new(0.22, Enum.EasingStyle.Quart), {BackgroundTransparency = 0.03})
    Tween(stroke, TweenInfo.new(0.22), {Transparency = 0.55})
    Tween(iconBox, TweenInfo.new(0.22), {BackgroundTransparency = 0.05})
    Tween(iconLbl, TweenInfo.new(0.22), {TextTransparency = 0.05})
    Tween(titleLbl, TweenInfo.new(0.22), {TextTransparency = 0.05})
    Tween(contentLbl, TweenInfo.new(0.22), {TextTransparency = 0.3})

    task.delay(dur, function()
        Tween(box, TweenInfo.new(0.22), {BackgroundTransparency = 1})
        Tween(stroke, TweenInfo.new(0.22), {Transparency = 1})
        Tween(iconBox, TweenInfo.new(0.22), {BackgroundTransparency = 1})
        Tween(iconLbl, TweenInfo.new(0.22), {TextTransparency = 1})
        Tween(titleLbl, TweenInfo.new(0.22), {TextTransparency = 1})
        Tween(contentLbl, TweenInfo.new(0.22), {TextTransparency = 1})
        task.wait(0.25)
        box:Destroy()
    end)
end

--=========================================================================
-- ELEMENT: TOGGLE
--=========================================================================
local function CreateToggle(parent, config)
    config = config or {}
    local flag     = config.Flag
    local default  = config.Default or false
    local callback = config.Callback or function() end
    local name     = config.Name or 'Toggle'

    local row = Instance.new('Frame')
    row.BackgroundColor3 = Theme.PanelAlt
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1,-16,0,34)
    row.Parent = parent
    Round(row, 8)

    local label = Instance.new('TextLabel')
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0,10,0,0)
    label.Size = UDim2.new(1,-60,1,0)
    label.Font = Enum.Font.GothamMedium
    label.Text = name
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.TextTransparency = 0.15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local pill = Instance.new('Frame')
    pill.BackgroundColor3 = Theme.PanelAlt
    pill.BorderSizePixel = 0
    pill.AnchorPoint = Vector2.new(1,0.5)
    pill.Position = UDim2.new(1,-8,0.5,0)
    pill.Size = UDim2.fromOffset(36,20)
    pill.Parent = row
    Round(pill, 20)
    local pillStroke = Stroke(pill, Theme.Border, 0.55)

    local knob = Instance.new('Frame')
    knob.BackgroundColor3 = Theme.TextMuted
    knob.BorderSizePixel = 0
    knob.AnchorPoint = Vector2.new(0,0.5)
    knob.Position = UDim2.new(0,3,0.5,0)
    knob.Size = UDim2.fromOffset(14,14)
    knob.Parent = pill
    Round(knob, 20)
    local knobGlow = Glow(knob, Theme.Accent, 0)

    local state = default

    local function refresh()
        if state then
            Tween(pill, TweenInfo.new(0.16), {BackgroundColor3 = Theme.Accent})
            Tween(pillStroke, TweenInfo.new(0.16), {Transparency = 0})
            Tween(knob, TweenInfo.new(0.16), {Position = UDim2.new(1,-17,0.5,0), BackgroundColor3 = Theme.BG})
            Tween(knobGlow, TweenInfo.new(0.16), {Thickness = 2, Transparency = 0.45})
        else
            Tween(pill, TweenInfo.new(0.16), {BackgroundColor3 = Theme.PanelAlt})
            Tween(pillStroke, TweenInfo.new(0.16), {Transparency = 0.55})
            Tween(knob, TweenInfo.new(0.16), {Position = UDim2.new(0,3,0.5,0), BackgroundColor3 = Theme.TextMuted})
            Tween(knobGlow, TweenInfo.new(0.16), {Thickness = 0, Transparency = 1})
        end
    end

    refresh()

    local input = CreateInput(row, function()
        state = not state
        refresh()
        callback(state)
    end)
    Track(input.MouseEnter:Connect(function() Tween(row, TweenInfo.new(0.15), {BackgroundTransparency = 0.9}) end))
    Track(input.MouseLeave:Connect(function() Tween(row, TweenInfo.new(0.15), {BackgroundTransparency = 1}) end))

    local api = {}
    function api:GetValue() return state end
    function api:SetValue(v) state = v; refresh(); callback(state) end
    function api:SetVisible(v) row.Visible = v end

    if flag then CandyLib.Flags[flag] = api end
    return api
end

--=========================================================================
-- ELEMENT: SLIDER (FIXED)
--=========================================================================
local function CreateSlider(parent, config)
    config = config or {}
    local flag     = config.Flag
    local default  = config.Default or 50
    local min      = config.Min or 0
    local max      = config.Max or 100
    local round    = config.Rounding or 0
    local callback = config.Callback or function() end
    local name     = config.Name or 'Slider'
    local suffix   = config.Suffix or ''

    local row = Instance.new('Frame')
    row.BackgroundColor3 = Theme.PanelAlt
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1,-16,0,46)
    row.Parent = parent
    Round(row, 8)

    local label = Instance.new('TextLabel')
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0,10,0,6)
    label.Size = UDim2.new(1,-80,0,16)
    label.Font = Enum.Font.GothamMedium
    label.Text = name
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.TextTransparency = 0.15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local valueBox = Instance.new('Frame')
    valueBox.BackgroundColor3 = Theme.Panel
    valueBox.AnchorPoint = Vector2.new(1,0)
    valueBox.Position = UDim2.new(1,-10,0,5)
    valueBox.Size = UDim2.fromOffset(48,18)
    valueBox.Parent = row
    Round(valueBox, 6)
    Stroke(valueBox, Theme.BorderSoft, 0.4)

    local valueTxt = Instance.new('TextBox')
    valueTxt.BackgroundTransparency = 1
    valueTxt.Size = UDim2.fromScale(1,1)
    valueTxt.Font = Enum.Font.GothamMedium
    valueTxt.Text = tostring(default)
    valueTxt.TextColor3 = Theme.Text
    valueTxt.TextSize = 11
    valueTxt.TextTransparency = 0.2
    valueTxt.ClearTextOnFocus = false
    valueTxt.Parent = valueBox

    local track = Instance.new('Frame')
    track.BackgroundColor3 = Theme.BorderSoft
    track.AnchorPoint = Vector2.new(0,0.5)
    track.Position = UDim2.new(0,10,1,-10)
    track.Size = UDim2.new(1,-20,0,4)
    track.Parent = row
    Round(track, 2)

    local fill = Instance.new('Frame')
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new(0,0,1,0)
    fill.Parent = track
    Round(fill, 2)
    Glow(fill, Theme.Accent, 1.5)

    local knob = Instance.new('Frame')
    knob.BackgroundColor3 = Theme.Accent
    knob.BorderSizePixel = 0
    knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Size = UDim2.fromOffset(12,12)
    knob.Parent = fill
    Round(knob, 20)
    Glow(knob, Theme.Accent, 2)

    local current = default

    local function setFromValue(v, silent)
        current = math.clamp(v, min, max)
        local alpha = (max==min) and 0 or (current-min)/(max-min)
        Tween(fill, TweenInfo.new(0.08), {Size = UDim2.new(alpha,0,1,0)})
        knob.Position = UDim2.new(1,0,0.5,0)
        valueTxt.Text = tostring(current)..suffix
        if not silent then callback(current) end
    end
    setFromValue(default, true)

    local dragging = false
    local function updateFromInput(inp)
        local rel = (inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
        rel = math.clamp(rel, 0, 1)
        local val = min + (max-min)*rel
        val = math.floor(val * (10^round) + 0.5) / (10^round)
        setFromValue(val)
    end

    Track(track.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true; updateFromInput(inp)
        end
    end))
    Track(UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=false
        end
    end))
    Track(UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            updateFromInput(inp)
        end
    end))
    Track(valueTxt.FocusLost:Connect(function()
        local n = tonumber(valueTxt.Text:gsub('[^%d%.%-]',''))
        if n then setFromValue(n) else setFromValue(current, true) end
    end))

    local hoverBtn = Instance.new('TextButton')
    hoverBtn.BackgroundTransparency = 1
    hoverBtn.BorderSizePixel = 0
    hoverBtn.Size = UDim2.fromScale(1, 1)
    hoverBtn.Text = ''
    hoverBtn.Active = false
    hoverBtn.ZIndex = 0
    hoverBtn.Parent = row
    Track(hoverBtn.MouseEnter:Connect(function() Tween(row, TweenInfo.new(0.15), {BackgroundTransparency = 0.9}) end))
    Track(hoverBtn.MouseLeave:Connect(function() Tween(row, TweenInfo.new(0.15), {BackgroundTransparency = 1}) end))

    local api = {}
    function api:GetValue() return current end
    function api:SetValue(v) setFromValue(v) end
    function api:SetVisible(v) row.Visible = v end
    if flag then CandyLib.Flags[flag] = api end
    return api
end

--=========================================================================
-- ELEMENT: BUTTON
--=========================================================================
local function CreateButton(parent, config)
    config = config or {}
    local name     = config.Name or 'Button'
    local icon     = config.Icon or 'arrow-small-right'
    local callback = config.Callback or function() end

    local btn = Instance.new('Frame')
    btn.BackgroundColor3 = Theme.PanelAlt
    btn.BackgroundTransparency = 0.05
    btn.Size = UDim2.new(1,-16,0,34)
    btn.Parent = parent
    Round(btn, 8)
    local stroke = Stroke(btn, Theme.BorderSoft, 0.5)

    local ic = Instance.new('TextLabel')
    ic.BackgroundTransparency = 1
    ic.Position = UDim2.new(0,10,0,0)
    ic.Size = UDim2.new(0,20,1,0)
    ic.FontFace = IconBold
    ic.Text = icon
    ic.TextColor3 = Theme.Accent
    ic.TextSize = 16
    ic.TextTransparency = 0.15
    ic.Parent = btn

    local lbl = Instance.new('TextLabel')
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0,36,0,0)
    lbl.Size = UDim2.new(1,-46,1,0)
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = name
    lbl.TextColor3 = Theme.Text
    lbl.TextSize = 13
    lbl.TextTransparency = 0.1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = btn

    local inp = CreateInput(btn, callback)
    Track(inp.MouseEnter:Connect(function()
        Tween(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0})
        Tween(stroke, TweenInfo.new(0.15), {Transparency = 0.2, Color = Theme.Accent})
    end))
    Track(inp.MouseLeave:Connect(function()
        Tween(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.05})
        Tween(stroke, TweenInfo.new(0.15), {Transparency = 0.5, Color = Theme.BorderSoft})
    end))

    local api = {}
    function api:SetVisible(v) btn.Visible = v end
    return api
end

--=========================================================================
-- ELEMENT: TEXT INPUT
--=========================================================================
local function CreateTextInput(parent, config)
    config = config or {}
    local flag     = config.Flag
    local default  = config.Default or ''
    local name     = config.Name or 'Input'
    local cb       = config.Callback or function() end
    local numeric  = config.Numeric or false

    local row = Instance.new('Frame')
    row.BackgroundColor3 = Theme.PanelAlt
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1,-16,0,34)
    row.Parent = parent
    Round(row, 8)

    local label = Instance.new('TextLabel')
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0,10,0,0)
    label.Size = UDim2.new(0,100,1,0)
    label.Font = Enum.Font.GothamMedium
    label.Text = name
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.TextTransparency = 0.15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local box = Instance.new('Frame')
    box.BackgroundColor3 = Theme.Panel
    box.AnchorPoint = Vector2.new(1,0.5)
    box.Position = UDim2.new(1,-8,0.5,0)
    box.Size = UDim2.new(0,140,0,22)
    box.Parent = row
    Round(box, 6)
    Stroke(box, Theme.BorderSoft, 0.4)

    local tb = Instance.new('TextBox')
    tb.BackgroundTransparency = 1
    tb.Position = UDim2.new(0,6,0,0)
    tb.Size = UDim2.new(1,-12,1,0)
    tb.Font = Enum.Font.GothamMedium
    tb.PlaceholderText = 'Enter...'
    tb.Text = tostring(default)
    tb.TextColor3 = Theme.Text
    tb.TextSize = 12
    tb.ClearTextOnFocus = false
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.Parent = box

    local function parse(t)
        if numeric then return tonumber(t) or 0 end
        return t
    end

    Track(tb:GetPropertyChangedSignal('Text'):Connect(function()
        if numeric then tb.Text = tb.Text:gsub('[^%d%.%-]','') end
        cb(parse(tb.Text))
    end))

    local api = {}
    function api:GetValue() return parse(tb.Text) end
    function api:SetValue(v) tb.Text = tostring(v); cb(parse(tb.Text)) end
    function api:SetVisible(v) row.Visible = v end
    if flag then CandyLib.Flags[flag] = api end
    return api
end

--=========================================================================
-- ELEMENT: KEYBIND
--=========================================================================
local function KeycodeToString(k)
    if typeof(k) == 'string' then return k end
    if not k then return 'None' end
    return tostring(k.Name)
end

local function CreateKeybind(parent, config)
    config = config or {}
    local flag     = config.Flag
    local default  = config.Default
    local callback = config.Callback or function() end
    local name     = config.Name or 'Keybind'

    local row = Instance.new('Frame')
    row.BackgroundColor3 = Theme.PanelAlt
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1,-16,0,34)
    row.Parent = parent
    Round(row, 8)

    local label = Instance.new('TextLabel')
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0,10,0,0)
    label.Size = UDim2.new(1,-90,1,0)
    label.Font = Enum.Font.GothamMedium
    label.Text = name
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.TextTransparency = 0.15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local keyBox = Instance.new('Frame')
    keyBox.BackgroundColor3 = Theme.Panel
    keyBox.AnchorPoint = Vector2.new(1,0.5)
    keyBox.Position = UDim2.new(1,-8,0.5,0)
    keyBox.Size = UDim2.fromOffset(70,22)
    keyBox.Parent = row
    Round(keyBox, 6)
    Stroke(keyBox, Theme.BorderSoft, 0.4)

    local keyTxt = Instance.new('TextLabel')
    keyTxt.BackgroundTransparency = 1
    keyTxt.Size = UDim2.fromScale(1,1)
    keyTxt.Font = Enum.Font.GothamMedium
    keyTxt.Text = KeycodeToString(default)
    keyTxt.TextColor3 = Theme.Text
    keyTxt.TextSize = 11
    keyTxt.TextTransparency = 0.3
    keyTxt.Parent = keyBox

    local current = default

    local inp = CreateInput(keyBox, function()
        keyTxt.Text = '...'
        local sel
        while not sel do
            local k = UserInputService.InputBegan:Wait()
            if k.KeyCode ~= Enum.KeyCode.Unknown then sel = k.KeyCode.Name end
        end
        current = sel
        keyTxt.Text = KeycodeToString(current)
        callback(current)
    end)
    Track(inp.MouseEnter:Connect(function() Tween(keyBox, TweenInfo.new(0.15), {BackgroundColor3 = Theme.PanelAlt}) end))
    Track(inp.MouseLeave:Connect(function() Tween(keyBox, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Panel}) end))

    Track(UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if not current then return end
        local pressed = inp.KeyCode.Name == current or (current == 'MouseLeft' and inp.UserInputType==Enum.UserInputType.MouseButton1)
        if pressed then callback(current) end
    end))

    local api = {}
    function api:GetValue() return current end
    function api:SetValue(v) current=v; keyTxt.Text = KeycodeToString(v) end
    function api:SetVisible(v) row.Visible = v end
    if flag then CandyLib.Flags[flag] = api end
    return api
end

--=========================================================================
-- ELEMENT: DROPDOWN
--=========================================================================
local function CreateDropdown(parent, config)
    config = config or {}
    local flag     = config.Flag
    local values   = config.Values or {}
    local default  = config.Default or (values[1])
    local callback = config.Callback or function() end
    local name     = config.Name or 'Dropdown'
    local multi    = config.Multi or false

    local row = Instance.new('Frame')
    row.BackgroundColor3 = Theme.PanelAlt
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1,-16,0,34)
    row.Parent = parent
    Round(row, 8)

    local label = Instance.new('TextLabel')
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0,10,0,0)
    label.Size = UDim2.new(1,-140,1,0)
    label.Font = Enum.Font.GothamMedium
    label.Text = name
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.TextTransparency = 0.15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local btn = Instance.new('Frame')
    btn.BackgroundColor3 = Theme.Panel
    btn.AnchorPoint = Vector2.new(1,0.5)
    btn.Position = UDim2.new(1,-8,0.5,0)
    btn.Size = UDim2.new(0,120,0,22)
    btn.Parent = row
    Round(btn, 6)
    Stroke(btn, Theme.BorderSoft, 0.4)

    local function fmt(v)
        if type(v)=='table' then
            local out={}
            for k,on in next,v do if on then table.insert(out,k) end end
            if #out==0 then return 'Select' end
            return table.concat(out, ', ')
        end
        return tostring(v or 'Select')
    end

    local btnTxt = Instance.new('TextLabel')
    btnTxt.BackgroundTransparency = 1
    btnTxt.Position = UDim2.new(0,6,0,0)
    btnTxt.Size = UDim2.new(1,-24,1,0)
    btnTxt.Font = Enum.Font.GothamMedium
    btnTxt.Text = fmt(default)
    btnTxt.TextColor3 = Theme.Text
    btnTxt.TextSize = 11
    btnTxt.TextTransparency = 0.3
    btnTxt.TextXAlignment = Enum.TextXAlignment.Left
    btnTxt.TextTruncate = Enum.TextTruncate.AtEnd
    btnTxt.Parent = btn

    local chevron = Instance.new('TextLabel')
    chevron.BackgroundTransparency = 1
    chevron.AnchorPoint = Vector2.new(1,0.5)
    chevron.Position = UDim2.new(1,-2,0.5,0)
    chevron.Size = UDim2.fromOffset(18,18)
    chevron.FontFace = IconBold
    chevron.Text = 'chevron-small-down'
    chevron.TextColor3 = Theme.TextMuted
    chevron.TextSize = 14
    chevron.Parent = btn

    local current = default
    if multi and type(current)~='table' then current = {} end

    local popup = Instance.new('Frame')
    popup.BackgroundColor3 = Theme.Panel
    popup.BackgroundTransparency = 1
    popup.Size = UDim2.fromOffset(160, math.min(#values*24+8, 200))
    popup.ClipsDescendants = true
    popup.Visible = false
    popup.Parent = CandyLib.ScreenGui
    Round(popup, 10)
    local popupStroke = Stroke(popup, Theme.Border, 1)
    Glow(popup, Theme.Accent, 1)

    local scroll = Instance.new('ScrollingFrame')
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.Position = UDim2.new(0,4,0,4)
    scroll.Size = UDim2.new(1,-8,1,-8)
    scroll.ScrollBarThickness = 2
    scroll.ScrollBarImageColor3 = Theme.BorderSoft
    scroll.CanvasSize = UDim2.new(0,0,0,#values*24)
    scroll.Parent = popup
    local list = Instance.new('UIListLayout')
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = scroll

    local function refresh()
        btnTxt.Text = fmt(current)
    end
    refresh()

    local function isSelected(v)
        if multi then return current[v] == true end
        return current == v
    end

    local itemRefs = {}

    local function buildItems()
        for _, ch in ipairs(scroll:GetChildren()) do if ch:IsA('Frame') then ch:Destroy() end end
        table.clear(itemRefs)
        for i, v in ipairs(values) do
            local item = Instance.new('Frame')
            item.BackgroundColor3 = Theme.PanelAlt
            item.BackgroundTransparency = 1
            item.Size = UDim2.new(1,0,0,24)
            item.LayoutOrder = i
            item.Parent = scroll
            Round(item, 5)

            local txt = Instance.new('TextLabel')
            txt.BackgroundTransparency = 1
            txt.Position = UDim2.new(0,8,0,0)
            txt.Size = UDim2.new(1,-16,1,0)
            txt.Font = Enum.Font.GothamMedium
            txt.Text = tostring(v)
            txt.TextColor3 = Theme.Text
            txt.TextSize = 12
            txt.TextTransparency = 0.15
            txt.TextXAlignment = Enum.TextXAlignment.Left
            txt.Parent = item

            local function paint()
                if isSelected(v) then
                    txt.TextColor3 = Theme.Accent
                    txt.TextTransparency = 0
                else
                    txt.TextColor3 = Theme.Text
                    txt.TextTransparency = 0.15
                end
            end
            paint()
            table.insert(itemRefs, paint)

            local inp = CreateInput(item, function()
                if multi then
                    current[v] = not current[v]
                    refresh()
                    for _, p in ipairs(itemRefs) do p() end
                    callback(current)
                else
                    current = v
                    refresh()
                    popup.Visible = false
                    callback(current)
                end
            end)
            Track(inp.MouseEnter:Connect(function() Tween(item, TweenInfo.new(0.1), {BackgroundTransparency = 0.9}) end))
            Track(inp.MouseLeave:Connect(function() Tween(item, TweenInfo.new(0.1), {BackgroundTransparency = 1}) end))
        end
    end
    buildItems()

    local open = false
    local function togglePopup()
        open = not open
        if open then
            local abs = btn.AbsolutePosition
            local size = btn.AbsoluteSize
            popup.Position = UDim2.fromOffset(abs.X, abs.Y + size.Y + 4)
            popup.Size = UDim2.fromOffset(math.max(140, size.X), math.min(#values*24+8, 200))
            popup.Visible = true
            Tween(popup, TweenInfo.new(0.16), {BackgroundTransparency = 0.03})
            Tween(popupStroke, TweenInfo.new(0.16), {Transparency = 0.55})
            task.spawn(function()
                while open do
                    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        and not MouseOver(popup) and not MouseOver(btn) then
                        open = false
                        popup.Visible = false
                        popup.BackgroundTransparency = 1
                    end
                    task.wait(0.05)
                end
            end)
        else
            Tween(popup, TweenInfo.new(0.14), {BackgroundTransparency = 1})
            Tween(popupStroke, TweenInfo.new(0.14), {Transparency = 1})
            task.delay(0.15, function() if not open then popup.Visible = false end end)
        end
    end
    local bInp = CreateInput(btn, togglePopup)
    Track(bInp.MouseEnter:Connect(function() Tween(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.PanelAlt}) end))
    Track(bInp.MouseLeave:Connect(function() Tween(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Panel}) end))

    local api = {}
    function api:GetValue() return current end
    function api:SetValue(v) current=v; refresh(); for _,p in ipairs(itemRefs) do p() end; callback(current) end
    function api:SetValues(vs) values=vs; buildItems(); refresh() end
    function api:SetVisible(v) row.Visible=v end
    if flag then CandyLib.Flags[flag] = api end
    return api
end

--=========================================================================
-- ELEMENT: COLOR PICKER
--=========================================================================
local function CreateColorPicker(parent, config)
    config = config or {}
    local flag     = config.Flag
    local default  = config.Default or Color3.fromRGB(255,255,255)
    local callback = config.Callback or function() end
    local name     = config.Name or 'Color'

    local row = Instance.new('Frame')
    row.BackgroundColor3 = Theme.PanelAlt
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1,-16,0,34)
    row.Parent = parent
    Round(row, 8)

    local label = Instance.new('TextLabel')
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0,10,0,0)
    label.Size = UDim2.new(1,-50,1,0)
    label.Font = Enum.Font.GothamMedium
    label.Text = name
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.TextTransparency = 0.15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local swatch = Instance.new('Frame')
    swatch.BackgroundColor3 = default
    swatch.AnchorPoint = Vector2.new(1,0.5)
    swatch.Position = UDim2.new(1,-8,0.5,0)
    swatch.Size = UDim2.fromOffset(24,22)
    swatch.Parent = row
    Round(swatch, 6)
    Stroke(swatch, Theme.Border, 0.4)

    local current = default

    local popup = Instance.new('Frame')
    popup.BackgroundColor3 = Theme.Panel
    popup.BackgroundTransparency = 1
    popup.Size = UDim2.fromOffset(200, 240)
    popup.ClipsDescendants = true
    popup.Visible = false
    popup.Parent = CandyLib.ScreenGui
    Round(popup, 10)
    local pStroke = Stroke(popup, Theme.Border, 1)
    Glow(popup, Theme.Accent, 1)

    local sv = Instance.new('Frame')
    sv.BackgroundColor3 = Color3.fromRGB(255,0,0)
    sv.Position = UDim2.new(0,10,0,10)
    sv.Size = UDim2.fromOffset(180,150)
    sv.ClipsDescendants = true
    sv.Parent = popup
    Round(sv, 6)

    local sat = Instance.new('Frame')
    sat.BackgroundColor3 = Color3.new(1,1,1)
    sat.Size = UDim2.fromScale(1,1)
    sat.Parent = sv
    Round(sat, 6)
    local satGrad = Instance.new('UIGradient')
    satGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)})
    satGrad.Parent = sat

    local val = Instance.new('Frame')
    val.BackgroundColor3 = Color3.new(0,0,0)
    val.Size = UDim2.fromScale(1,1)
    val.Parent = sv
    Round(val, 6)
    local valGrad = Instance.new('UIGradient')
    valGrad.Rotation = 90
    valGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)})
    valGrad.Parent = val

    local knob = Instance.new('Frame')
    knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BackgroundTransparency = 1
    knob.Size = UDim2.fromOffset(12,12)
    knob.Parent = sv
    Round(knob, 20)
    Stroke(knob, Color3.new(1,1,1), 0, 2)

    local hue = Instance.new('Frame')
    hue.BackgroundColor3 = Color3.new(1,1,1)
    hue.Position = UDim2.new(0,10,0,170)
    hue.Size = UDim2.new(1,-20,0,14)
    hue.Parent = popup
    Round(hue, 4)
    local hueGrad = Instance.new('UIGradient')
    hueGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0)),
    }
    hueGrad.Parent = hue

    local hueKnob = Instance.new('Frame')
    hueKnob.AnchorPoint = Vector2.new(0.5,0.5)
    hueKnob.Position = UDim2.new(0,0,0.5,0)
    hueKnob.Size = UDim2.fromOffset(10,18)
    hueKnob.Parent = hue
    Round(hueKnob, 4)
    Stroke(hueKnob, Color3.new(1,1,1), 0, 2)

    local hex = Instance.new('TextBox')
    hex.BackgroundColor3 = Theme.PanelAlt
    hex.Position = UDim2.new(0,10,0,196)
    hex.Size = UDim2.new(1,-20,0,22)
    hex.Font = Enum.Font.GothamMedium
    hex.Text = '#FFFFFF'
    hex.TextColor3 = Theme.Text
    hex.TextSize = 11
    hex.ClearTextOnFocus = false
    hex.Parent = popup
    Round(hex, 6)
    Stroke(hex, Theme.BorderSoft, 0.5)

    local h, s, v = current:ToHSV()

    local function updateSV()
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        knob.Position = UDim2.fromScale(s, 1-v)
        hueKnob.Position = UDim2.new(h, 0, 0.5, 0)
        current = Color3.fromHSV(h, s, v)
        swatch.BackgroundColor3 = current
        hex.Text = '#'..string.upper(current:ToHex())
        callback(current)
    end
    updateSV()

    local draggingSV = false
    Track(sv.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            draggingSV = true
            local rel = (inp.Position - sv.AbsolutePosition) / sv.AbsoluteSize
            s = math.clamp(rel.X,0,1); v = 1-math.clamp(rel.Y,0,1)
            updateSV()
        end
    end))
    local draggingHue = false
    Track(hue.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            draggingHue = true
            local rel = (inp.Position.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X
            h = math.clamp(rel,0,1); updateSV()
        end
    end))
    Track(UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            draggingSV = false
            draggingHue = false
        end
    end))
    Track(UserInputService.InputChanged:Connect(function(inp)
        if draggingSV and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local rel = (inp.Position - sv.AbsolutePosition) / sv.AbsoluteSize
            s = math.clamp(rel.X,0,1); v = 1-math.clamp(rel.Y,0,1)
            updateSV()
        elseif draggingHue and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local rel = (inp.Position.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X
            h = math.clamp(rel,0,1); updateSV()
        end
    end))
    Track(hex.FocusLost:Connect(function()
        local ok, color = pcall(Color3.fromHex, hex.Text:gsub('#',''))
        if ok and color then
            h,s,v = color:ToHSV()
            updateSV()
        else updateSV() end
    end))

    local open = false
    CreateInput(swatch, function()
        open = not open
        if open then
            local abs = swatch.AbsolutePosition
            local siz = swatch.AbsoluteSize
            popup.Position = UDim2.fromOffset(abs.X - 176, abs.Y + siz.Y + 4)
            popup.Visible = true
            Tween(popup, TweenInfo.new(0.16), {BackgroundTransparency = 0.03})
            Tween(pStroke, TweenInfo.new(0.16), {Transparency = 0.55})
        else
            Tween(popup, TweenInfo.new(0.14), {BackgroundTransparency = 1})
            Tween(pStroke, TweenInfo.new(0.14), {Transparency = 1})
            task.delay(0.15, function() if not open then popup.Visible=false end end)
        end
    end)

    local api = {}
    function api:GetValue() return current end
    function api:SetValue(c)
        if typeof(c)=='string' then c = Color3.fromHex(c:gsub('#','')) end
        h,s,v = c:ToHSV(); updateSV()
    end
    function api:SetVisible(vv) row.Visible = vv end
    if flag then CandyLib.Flags[flag] = api end
    return api
end

--=========================================================================
-- SECTION
--=========================================================================
local function CreateSection(parent, name)
    local holder = Instance.new('Frame')
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.new(1,-8,0,0)
    holder.AutomaticSize = Enum.AutomaticSize.Y
    holder.Parent = parent

    local title = Instance.new('TextLabel')
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0,4,0,0)
    title.Size = UDim2.new(1,-8,0,20)
    title.Font = Enum.Font.GothamBold
    title.Text = string.upper(name)
    title.TextColor3 = Theme.TextMuted
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = holder

    local panel = Instance.new('Frame')
    panel.BackgroundColor3 = Theme.Panel
    panel.BackgroundTransparency = 0.05
    panel.Position = UDim2.new(0,0,0,24)
    panel.Size = UDim2.new(1,0,0,0)
    panel.AutomaticSize = Enum.AutomaticSize.Y
    panel.Parent = holder
    Round(panel, 14)
    Stroke(panel, Theme.BorderSoft, 0.55)
    Glow(panel, Theme.AccentGlow, 1)

    local pad = Instance.new('UIPadding')
    pad.PaddingTop = UDim.new(0,8)
    pad.PaddingBottom = UDim.new(0,8)
    pad.Parent = panel
    local list = Instance.new('UIListLayout')
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.Padding = UDim.new(0,4)
    list.Parent = panel

    local api = {}
    function api:AddToggle(cfg) cfg=cfg or {}; return CreateToggle(panel, cfg) end
    function api:AddSlider(cfg) cfg=cfg or {}; return CreateSlider(panel, cfg) end
    function api:AddButton(cfg) cfg=cfg or {}; return CreateButton(panel, cfg) end
    function api:AddTextInput(cfg) cfg=cfg or {}; return CreateTextInput(panel, cfg) end
    function api:AddKeybind(cfg) cfg=cfg or {}; return CreateKeybind(panel, cfg) end
    function api:AddDropdown(cfg) cfg=cfg or {}; return CreateDropdown(panel, cfg) end
    function api:AddColorPicker(cfg) cfg=cfg or {}; return CreateColorPicker(panel, cfg) end
    api.Root = holder
    return api
end

--=========================================================================
-- WINDOW
--=========================================================================
function CandyLib:CreateWindow(cfg)
    cfg = cfg or {}
    local cfgFolder = cfg.ConfigFolder or 'CandyConfigs'
    local title     = cfg.Name or 'Candy'
    local content   = cfg.Content or 'v1.0.0'
    local logo      = cfg.Logo
    local size      = cfg.Size or UDim2.fromOffset(720, 500)
    local keybind   = cfg.Keybind or 'Insert'

    pcall(function()
        if not isfolder(cfgFolder) then makefolder(cfgFolder) end
    end)

    local Window = {
        Tabs = {},
        Current = 1,
        ConfigFolder = cfgFolder,
        Opened = false,
    }

    local main = Instance.new('Frame')
    main.Name = CandyLib.RandomString()
    main.AnchorPoint = Vector2.new(0.5,0.5)
    main.BackgroundColor3 = Theme.BG
    main.BackgroundTransparency = 0.03
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Position = UDim2.fromScale(0.5, 0.5)
    main.Size = size
    main.Parent = CandyLib.ScreenGui
    Round(main, 18)
    Stroke(main, Theme.BorderSoft, 0.45, 1.2)
    Glow(main, Theme.AccentGlow, 1.2)

    local dragBar = Instance.new('Frame')
    dragBar.BackgroundTransparency = 1
    dragBar.Size = UDim2.new(1,0,0,40)
    dragBar.Parent = main
    Drag(dragBar, main, 0.12)

    local rail = Instance.new('Frame')
    rail.BackgroundColor3 = Theme.Panel
    rail.BackgroundTransparency = 0.05
    rail.Position = UDim2.fromOffset(10,10)
    rail.Size = UDim2.new(0,64,1,-20)
    rail.Parent = main
    Round(rail, 14)
    Stroke(rail, Theme.BorderSoft, 0.5)

    if logo then
        local logoBox = Instance.new('Frame')
        logoBox.BackgroundColor3 = Theme.PanelAlt
        logoBox.BackgroundTransparency = 0.15
        logoBox.Position = UDim2.new(0,12,0,12)
        logoBox.Size = UDim2.fromOffset(40,40)
        logoBox.Parent = rail
        Round(logoBox, 12)
        Stroke(logoBox, Theme.Border, 0.4)
        local li = Instance.new('ImageLabel')
        li.BackgroundTransparency = 1
        li.Size = UDim2.fromScale(1,1)
        li.Image = logo
        li.ScaleType = Enum.ScaleType.Fit
        li.Parent = logoBox
    end

    local tabList = Instance.new('Frame')
    tabList.BackgroundTransparency = 1
    tabList.Position = UDim2.new(0,10,0,68)
    tabList.Size = UDim2.new(1,-20,1,-160)
    tabList.Parent = rail
    local tabListLayout = Instance.new('UIListLayout')
    tabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabListLayout.Padding = UDim.new(0,6)
    tabListLayout.Parent = tabList

    local avatarBox = Instance.new('Frame')
    avatarBox.BackgroundColor3 = Theme.PanelAlt
    avatarBox.BackgroundTransparency = 0.05
    avatarBox.AnchorPoint = Vector2.new(0,1)
    avatarBox.Position = UDim2.new(0,12,1,-12)
    avatarBox.Size = UDim2.fromOffset(40,40)
    avatarBox.Parent = rail
    Round(avatarBox, 20)
    Stroke(avatarBox, Theme.Border, 0.35)
    local avatar = Instance.new('ImageLabel')
    avatar.BackgroundTransparency = 1
    avatar.Size = UDim2.fromScale(1,1)
    avatar.Image = CandyLib.UserProfile
    avatar.ScaleType = Enum.ScaleType.Crop
    avatar.Parent = avatarBox
    Round(avatar, 20)

    local contentPanel = Instance.new('Frame')
    contentPanel.BackgroundColor3 = Theme.Panel
    contentPanel.BackgroundTransparency = 0.03
    contentPanel.Position = UDim2.new(0, 84, 0, 10)
    contentPanel.Size = UDim2.new(1, -94, 1, -20)
    contentPanel.Parent = main
    Round(contentPanel, 14)
    Stroke(contentPanel, Theme.BorderSoft, 0.5)

    local header = Instance.new('Frame')
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1,0,0,52)
    header.Parent = contentPanel

    local headerTitle = Instance.new('TextLabel')
    headerTitle.BackgroundTransparency = 1
    headerTitle.Position = UDim2.new(0,20,0,10)
    headerTitle.Size = UDim2.new(1,-200,0,20)
    headerTitle.Font = Enum.Font.GothamBold
    headerTitle.Text = title
    headerTitle.TextColor3 = Theme.Text
    headerTitle.TextSize = 15
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.Parent = header

    local headerSub = Instance.new('TextLabel')
    headerSub.BackgroundTransparency = 1
    headerSub.Position = UDim2.new(0,20,0,28)
    headerSub.Size = UDim2.new(1,-200,0,14)
    headerSub.Font = Enum.Font.Gotham
    headerSub.Text = content
    headerSub.TextColor3 = Theme.TextMuted
    headerSub.TextSize = 11
    headerSub.TextTransparency = 0.3
    headerSub.TextXAlignment = Enum.TextXAlignment.Left
    headerSub.Parent = header

    local cfgBtn = Instance.new('Frame')
    cfgBtn.BackgroundColor3 = Theme.PanelAlt
    cfgBtn.BackgroundTransparency = 0.05
    cfgBtn.AnchorPoint = Vector2.new(1,0.5)
    cfgBtn.Position = UDim2.new(1,-16,0.5,0)
    cfgBtn.Size = UDim2.fromOffset(120,30)
    cfgBtn.Parent = header
    Round(cfgBtn, 8)
    Stroke(cfgBtn, Theme.BorderSoft, 0.4)

    local cfgIcon = Instance.new('TextLabel')
    cfgIcon.BackgroundTransparency = 1
    cfgIcon.Position = UDim2.new(0,10,0,0)
    cfgIcon.Size = UDim2.fromOffset(18,30)
    cfgIcon.FontFace = IconBold
    cfgIcon.Text = 'floppy-disk'
    cfgIcon.TextColor3 = Theme.Accent
    cfgIcon.TextSize = 14
    cfgIcon.TextTransparency = 0.2
    cfgIcon.Parent = cfgBtn

    local cfgLbl = Instance.new('TextLabel')
    cfgLbl.BackgroundTransparency = 1
    cfgLbl.Position = UDim2.new(0,34,0,0)
    cfgLbl.Size = UDim2.new(1,-44,1,0)
    cfgLbl.Font = Enum.Font.GothamMedium
    cfgLbl.Text = 'Default'
    cfgLbl.TextColor3 = Theme.Text
    cfgLbl.TextSize = 12
    cfgLbl.TextTransparency = 0.2
    cfgLbl.TextXAlignment = Enum.TextXAlignment.Left
    cfgLbl.TextTruncate = Enum.TextTruncate.AtEnd
    cfgLbl.Parent = cfgBtn

    local sep = Instance.new('Frame')
    sep.BackgroundColor3 = Theme.BorderSoft
    sep.BackgroundTransparency = 0.6
    sep.BorderSizePixel = 0
    sep.Position = UDim2.new(0,16,0,52)
    sep.Size = UDim2.new(1,-32,0,1)
    sep.Parent = contentPanel

    local body = Instance.new('Frame')
    body.BackgroundTransparency = 1
    body.Position = UDim2.new(0,10,0,56)
    body.Size = UDim2.new(1,-20,1,-64)
    body.Parent = contentPanel

    -- ============= CONFIG SYSTEM =============
    local cfgPopup = Instance.new('Frame')
    cfgPopup.BackgroundColor3 = Theme.Panel
    cfgPopup.BackgroundTransparency = 1
    cfgPopup.Size = UDim2.fromOffset(220, 300)
    cfgPopup.ClipsDescendants = true
    cfgPopup.Visible = false
    cfgPopup.Parent = CandyLib.ScreenGui
    Round(cfgPopup, 12)
    local cfgPopupStroke = Stroke(cfgPopup, Theme.Border, 1)
    Glow(cfgPopup, Theme.Accent, 1)

    local cfgScroll = Instance.new('ScrollingFrame')
    cfgScroll.BackgroundTransparency = 1
    cfgScroll.BorderSizePixel = 0
    cfgScroll.Position = UDim2.new(0,6,0,6)
    cfgScroll.Size = UDim2.new(1,-12,1,-12)
    cfgScroll.ScrollBarThickness = 2
    cfgScroll.ScrollBarImageColor3 = Theme.BorderSoft
    cfgScroll.CanvasSize = UDim2.new(0,0,0,0)
    cfgScroll.Parent = cfgPopup
    local cfgList = Instance.new('UIListLayout')
    cfgList.SortOrder = Enum.SortOrder.LayoutOrder
    cfgList.Padding = UDim.new(0,4)
    cfgList.Parent = cfgScroll

    local newCfgRow = Instance.new('Frame')
    newCfgRow.BackgroundColor3 = Theme.PanelAlt
    newCfgRow.BackgroundTransparency = 0.05
    newCfgRow.Size = UDim2.new(1,-4,0,32)
    newCfgRow.LayoutOrder = -1
    newCfgRow.Parent = cfgScroll
    Round(newCfgRow, 8)

    local newCfgInput = Instance.new('TextBox')
    newCfgInput.BackgroundTransparency = 1
    newCfgInput.Position = UDim2.new(0,8,0,0)
    newCfgInput.Size = UDim2.new(1,-42,1,0)
    newCfgInput.Font = Enum.Font.GothamMedium
    newCfgInput.PlaceholderText = 'New config name...'
    newCfgInput.PlaceholderColor3 = Theme.TextMuted
    newCfgInput.Text = ''
    newCfgInput.TextColor3 = Theme.Text
    newCfgInput.TextSize = 12
    newCfgInput.ClearTextOnFocus = false
    newCfgInput.TextXAlignment = Enum.TextXAlignment.Left
    newCfgInput.Parent = newCfgRow

    local newCfgBtn = Instance.new('TextLabel')
    newCfgBtn.BackgroundTransparency = 1
    newCfgBtn.AnchorPoint = Vector2.new(1,0.5)
    newCfgBtn.Position = UDim2.new(1,-6,0.5,0)
    newCfgBtn.Size = UDim2.fromOffset(24,24)
    newCfgBtn.FontFace = IconBold
    newCfgBtn.Text = 'plus-large'
    newCfgBtn.TextColor3 = Theme.Accent
    newCfgBtn.TextSize = 14
    newCfgBtn.Parent = newCfgRow

    local function xorEncode(data, key)
        local out = {}
        for i = 1, #data do
            out[i] = string.char(bit32.bxor(string.byte(data, i), string.byte(key, (i-1)%#key+1)))
        end
        return table.concat(out)
    end
    local XKEY = 'CandyLibKey7xK'

    local function getConfigData()
        local flags = {}
        for name, obj in pairs(CandyLib.Flags) do
            if obj.GetValue then
                local v = obj:GetValue()
                if typeof(v) == 'Color3' then v = {__color = v:ToHex()} end
                flags[name] = v
            end
        end
        return HttpService:JSONEncode(flags)
    end

    local function setConfigData(raw)
        local ok, tbl = pcall(function() return HttpService:JSONDecode(raw) end)
        if not ok or type(tbl) ~= 'table' then return end
        for name, value in pairs(tbl) do
            local obj = CandyLib.Flags[name]
            if obj and obj.SetValue then
                if type(value) == 'table' and value.__color then value = Color3.fromHex(value.__color) end
                pcall(function() obj:SetValue(value) end)
            end
        end
    end

    local currentCfg = 'Default'
    local function refreshConfigs()
        for _, ch in ipairs(cfgScroll:GetChildren()) do
            if ch ~= newCfgRow and ch:IsA('Frame') then ch:Destroy() end
        end
        local files = {}
        pcall(function() files = listfiles(cfgFolder) or {} end)
        for i, path in ipairs(files) do
            local name = path:sub(#cfgFolder+2)
            if name and name ~= '' then
                local row = Instance.new('Frame')
                row.BackgroundColor3 = Theme.PanelAlt
                row.BackgroundTransparency = 1
                row.Size = UDim2.new(1,-4,0,30)
                row.LayoutOrder = i
                row.Parent = cfgScroll
                Round(row, 8)

                local lbl = Instance.new('TextLabel')
                lbl.BackgroundTransparency = 1
                lbl.Position = UDim2.new(0,8,0,0)
                lbl.Size = UDim2.new(1,-80,1,0)
                lbl.Font = Enum.Font.GothamMedium
                lbl.Text = name
                lbl.TextColor3 = Theme.Text
                lbl.TextSize = 12
                lbl.TextTransparency = 0.2
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = row

                local saveBtn = Instance.new('TextLabel')
                saveBtn.BackgroundTransparency = 1
                saveBtn.AnchorPoint = Vector2.new(1,0.5)
                saveBtn.Position = UDim2.new(1,-32,0.5,0)
                saveBtn.Size = UDim2.fromOffset(22,22)
                saveBtn.FontFace = IconBold
                saveBtn.Text = 'arrow-right-from-portrait-rectangle'
                saveBtn.TextColor3 = Theme.TextMuted
                saveBtn.TextSize = 12
                saveBtn.Parent = row

                local delBtn = Instance.new('TextLabel')
                delBtn.BackgroundTransparency = 1
                delBtn.AnchorPoint = Vector2.new(1,0.5)
                delBtn.Position = UDim2.new(1,-6,0.5,0)
                delBtn.Size = UDim2.fromOffset(22,22)
                delBtn.FontFace = IconBold
                delBtn.Text = 'trash-can'
                delBtn.TextColor3 = Theme.TextMuted
                delBtn.TextSize = 12
                delBtn.Parent = row

                CreateInput(row, function()
                    local ok2, data = pcall(readfile, path)
                    if ok2 and data then
                        pcall(function() setConfigData(xorEncode(data, XKEY)) end)
                        currentCfg = name
                        cfgLbl.Text = name
                        CandyLib:Notify({Title = 'Config', Content = 'Loaded '..name, Icon = 'folder'})
                    end
                end)

                CreateInput(saveBtn, function()
                    local data = getConfigData()
                    local enc = xorEncode(data, XKEY)
                    pcall(writefile, path, enc)
                    CandyLib:Notify({Title = 'Config', Content = 'Saved '..name, Icon = 'floppy-disk'})
                end)
                CreateInput(delBtn, function()
                    if name == 'Default' then return end
                    pcall(delfile, path)
                    CandyLib:Notify({Title = 'Config', Content = 'Deleted '..name, Icon = 'trash-can'})
                    refreshConfigs()
                end)
            end
        end
        cfgScroll.CanvasSize = UDim2.new(0,0,cfgList.AbsoluteContentSize.Y + 8)
    end

    local cfgPopupOpen = false
    CreateInput(cfgBtn, function()
        cfgPopupOpen = not cfgPopupOpen
        if cfgPopupOpen then
            refreshConfigs()
            local abs = cfgBtn.AbsolutePosition
            local sz = cfgBtn.AbsoluteSize
            cfgPopup.Position = UDim2.fromOffset(abs.X + sz.X - 220, abs.Y + sz.Y + 6)
            cfgPopup.Visible = true
            Tween(cfgPopup, TweenInfo.new(0.16), {BackgroundTransparency = 0.03})
            Tween(cfgPopupStroke, TweenInfo.new(0.16), {Transparency = 0.55})
        else
            Tween(cfgPopup, TweenInfo.new(0.14), {BackgroundTransparency = 1})
            Tween(cfgPopupStroke, TweenInfo.new(0.14), {Transparency = 1})
            task.delay(0.15, function() if not cfgPopupOpen then cfgPopup.Visible=false end end)
        end
    end)

    CreateInput(newCfgBtn, function()
        local name = newCfgInput.Text:gsub('[\\/]',''):sub(1,24)
        if name and name ~= '' then
            local path = cfgFolder..'/'..name
            local enc = xorEncode(getConfigData(), XKEY)
            pcall(writefile, path, enc)
            currentCfg = name
            cfgLbl.Text = name
            newCfgInput.Text = ''
            CandyLib:Notify({Title = 'Config', Content = 'Created '..name, Icon = 'folder'})
            refreshConfigs()
        end
    end)

    task.delay(0.5, function()
        local path = cfgFolder..'/Default'
        if isfile(path) then
            local ok, data = pcall(readfile, path)
            if ok and data then
                pcall(function() setConfigData(xorEncode(data, XKEY)) end)
            end
        end
    end)

    task.spawn(function()
        while true do
            task.wait(15)
            local path = cfgFolder..'/Default'
            if currentCfg == 'Default' then
                local enc = xorEncode(getConfigData(), XKEY)
                pcall(writefile, path, enc)
            end
        end
    end)

    -- ============= TABS =============
    function Window:AddTab(tabCfg)
        tabCfg = tabCfg or {}
        local tabName = tabCfg.Name or 'Tab'
        local tabIcon = tabCfg.Icon or 'crosshairs'

        local tab = {
            Buttons = {},
            Sections = {},
            Name = tabName,
        }

        local btn = Instance.new('Frame')
        btn.BackgroundColor3 = Theme.PanelAlt
        btn.BackgroundTransparency = 1
        btn.Size = UDim2.fromOffset(44,44)
        btn.LayoutOrder = #self.Tabs+1
        btn.Parent = tabList
        Round(btn, 12)
        local btnStroke = Stroke(btn, Theme.BorderSoft, 1)

        local ic = Instance.new('TextLabel')
        ic.BackgroundTransparency = 1
        ic.Size = UDim2.fromScale(1,1)
        ic.FontFace = IconBold
        ic.Text = tabIcon
        ic.TextColor3 = Theme.TextMuted
        ic.TextSize = 20
        ic.TextTransparency = 0.3
        ic.Parent = btn

        local page = Instance.new('ScrollingFrame')
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.Size = UDim2.fromScale(1,1)
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = Theme.BorderSoft
        page.CanvasSize = UDim2.new(0,0,0,0)
        page.Visible = false
        page.Parent = body
        local pageList = Instance.new('UIListLayout')
        pageList.SortOrder = Enum.SortOrder.LayoutOrder
        pageList.Padding = UDim.new(0,8)
        pageList.Parent = page
        local pagePad = Instance.new('UIPadding')
        pagePad.PaddingTop = UDim.new(0,8)
        pagePad.PaddingBottom = UDim.new(0,8)
        pagePad.PaddingLeft = UDim.new(0,4)
        pagePad.PaddingRight = UDim.new(0,4)
        pagePad.Parent = page
        Track(pageList:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            page.CanvasSize = UDim2.new(0,0,pageList.AbsoluteContentSize.Y + 16, 0)
        end))

        tab.Page = page

        local function render(on)
            if on then
                Tween(btn, TweenInfo.new(0.16), {BackgroundTransparency = 0})
                Tween(btnStroke, TweenInfo.new(0.16), {Transparency = 0.35, Color = Theme.Accent})
                Tween(ic, TweenInfo.new(0.16), {TextColor3 = Theme.Accent, TextTransparency = 0.05})
                page.Visible = true
            else
                Tween(btn, TweenInfo.new(0.16), {BackgroundTransparency = 1})
                Tween(btnStroke, TweenInfo.new(0.16), {Transparency = 1, Color = Theme.BorderSoft})
                Tween(ic, TweenInfo.new(0.16), {TextColor3 = Theme.TextMuted, TextTransparency = 0.3})
                page.Visible = false
            end
        end
        tab.Render = render

        local btnInput = CreateInput(btn, function()
            for i, t in ipairs(self.Tabs) do
                if t == tab then
                    t.Render(true); self.Current = i
                else
                    t.Render(false)
                end
            end
        end)
        Track(btnInput.MouseEnter:Connect(function()
            if self.Tabs[self.Current] ~= tab then
                Tween(btn, TweenInfo.new(0.14), {BackgroundTransparency = 0.6})
            end
        end))
        Track(btnInput.MouseLeave:Connect(function()
            if self.Tabs[self.Current] ~= tab then
                Tween(btn, TweenInfo.new(0.14), {BackgroundTransparency = 1})
            end
        end))

        function tab:AddSection(name)
            local s = CreateSection(page, name)
            s.Root.LayoutOrder = #page:GetChildren()
            return s
        end

        table.insert(self.Tabs, tab)

        if #self.Tabs == 1 then render(true) else render(false) end
        return tab
    end

    Track(UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode.Name == keybind then
            Window:Toggle()
        end
    end))

    function Window:Toggle()
        if main.Visible then
            Tween(main, TweenInfo.new(0.15), {BackgroundTransparency = 1})
            task.delay(0.16, function() main.Visible = false end)
            Window.Opened = false
        else
            main.Visible = true
            Tween(main, TweenInfo.new(0.18), {BackgroundTransparency = 0.03})
            Window.Opened = true
        end
    end

    function Window:SetOpen(v)
        if v and not main.Visible then Window:Toggle() end
        if not v and main.Visible then Window:Toggle() end
    end

    CandyLib._currentWindow = Window
    return Window
end

--=========================================================================
-- CLEANUP
--=========================================================================
function CandyLib:Unload()
    if not self.UnloadEnabled then return end
    for _, s in ipairs(self.Signals) do pcall(function() s:Disconnect() end) end
    table.clear(self.Signals)
    self.ScreenGui:Destroy()
end

getgenv().CandyLib = CandyLib
return CandyLib
