--==================================================================
-- CandyLib v2.1.0
--==================================================================
local CandyLib = {}
CandyLib.Version = '2.1.0'
CandyLib.Flags = {}
CandyLib.Signals = {}
CandyLib.UnloadEnabled = true

cloneref = cloneref or function(i) return i end
gethui = gethui or get_hidden_gui
getcustomasset = getcustomasset or getsynasset
getgenv = getgenv or getfenv

-- FS Emulation for Studio
if game:GetService('RunService'):IsStudio() then
    local folder = game:GetService('ReplicatedFirst'):FindFirstChild('CANDY_FS') or Instance.new('Folder', game:GetService('ReplicatedFirst'))
    folder.Name = 'CANDY_FS'
    local function split(p) return (string.find(p,'/',1,true) and string.split(p,'/')) or {p} end
    local function walk(p) local b=folder for _,v in next,split(p) do if b then b=b[v] end end return b end
    getgenv().writefile = function(p, c) 
        local b=folder
        for i,v in next,split(p) do 
            local ch=b:FindFirstChild(v)
            if not ch then 
                ch=Instance.new('StringValue',b); ch.Name=tostring(v); ch.Value=c 
            else 
                if ch:IsA('StringValue') then ch.Value=c end
                b=ch 
            end 
        end 
    end
    getgenv().readfile = function(p) local r = walk(p); return r and r.Value or '' end
    getgenv().isfile = function(p) local s,r=pcall(walk,p); return s and r and not r:IsA('Folder') end
    getgenv().isfolder = function(p) local s,r=pcall(walk,p); return s and r and r:IsA('Folder') end
    getgenv().makefolder = function(p) 
        local b=folder
        for _,v in next,split(p) do 
            local ch=b:FindFirstChild(v)
            if not ch then ch=Instance.new('Folder',b); ch.Name=tostring(v) else b=ch end 
        end 
    end
    getgenv().listfiles = function(p) 
        local out={}; local f=walk(p)
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
    writefile = getgenv().writefile; readfile = getgenv().readfile; isfile = getgenv().isfile; isfolder = getgenv().isfolder; makefolder = getgenv().makefolder; listfiles = getgenv().listfiles; delfile = getgenv().delfile
else
    writefile = writefile or getgenv().writefile; readfile = readfile or getgenv().readfile; isfile = isfile or getgenv().isfile; isfolder = isfolder or getgenv().isfolder; makefolder = makefolder or getgenv().makefolder; listfiles = listfiles or getgenv().listfiles; delfile = delfile or getgenv().delfile
end

local TweenService = cloneref(game:GetService('TweenService'))
local UserInputService = cloneref(game:GetService('UserInputService'))
local Players = cloneref(game:GetService('Players'))
local HttpService = cloneref(game:GetService('HttpService'))
local LocalPlayer = Players.LocalPlayer
local CoreGui = (gethui and gethui()) or cloneref(game:FindFirstChild('CoreGui')) or cloneref(LocalPlayer.PlayerGui)
local Mouse = LocalPlayer:GetMouse()
local ProtectGui = protect_gui or (syn and syn.protect_gui) or function(s) return s end

local Theme = {
    BG = Color3.fromRGB(20, 20, 24),
    Panel = Color3.fromRGB(26, 26, 32),
    PanelAlt = Color3.fromRGB(32, 32, 38),
    Border = Color3.fromRGB(45, 45, 55),
    BorderSoft = Color3.fromRGB(38, 38, 45),
    Text = Color3.fromRGB(240, 240, 245),
    TextMuted = Color3.fromRGB(140, 140, 155),
    Accent = Color3.fromRGB(255, 255, 255),
}
CandyLib.Theme = Theme
local IconBold = Font.new('rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)

CandyLib.ScreenGui = Instance.new('ScreenGui')
CandyLib.ScreenGui.Name = 'CandyLib_'..math.random(100000,999999)
CandyLib.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
CandyLib.ScreenGui.ResetOnSpawn = false
CandyLib.ScreenGui.IgnoreGuiInset = true
CandyLib.ScreenGui.DisplayOrder = 1000
ProtectGui(CandyLib.ScreenGui)
CandyLib.ScreenGui.Parent = CoreGui

CandyLib.RandomString = function() return 'cnd_'..math.random(100000,999999) end
CandyLib.UserProfile = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)

-- UTILITIES
local function Tween(o,i,p) 
    local t=TweenService:Create(o, i or TweenInfo.new(0.15,Enum.EasingStyle.Quad), p); t:Play(); return t 
end
local function Track(s) table.insert(CandyLib.Signals, s); return s end
local function Round(obj, r) 
    local c = Instance.new('UICorner'); c.CornerRadius = UDim.new(0, r or 10); c.Parent = obj; return c 
end
local function Stroke(obj, color, transparency, thickness) 
    local s = Instance.new('UIStroke'); s.Color = color or Theme.Border; s.Transparency = transparency or 0.5; s.Thickness = thickness or 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = obj; return s 
end
local function CreateInput(parent, cb) 
    local b = Instance.new('TextButton'); b.BackgroundTransparency = 1; b.BorderSizePixel = 0; b.Size = UDim2.fromScale(1,1); b.ZIndex = (parent.ZIndex or 1)+50; b.Text = ''; b.Parent = parent
    if cb then return b, b.MouseButton1Click:Connect(cb) end
    return b 
end
local function MouseOver(frame) 
    if not frame or not frame.Parent then return false end
    local p,s = frame.AbsolutePosition, frame.AbsoluteSize
    return Mouse.X>=p.X and Mouse.X<=p.X+s.X and Mouse.Y>=p.Y and Mouse.Y<=p.Y+s.Y 
end
CandyLib.IsMouseOverFrame = MouseOver

local function MakeDraggable(dragFrame, targetFrame)
    local dragging, start, sPos
    Track(dragFrame.InputBegan:Connect(function(i) 
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then 
            dragging=true; start=i.Position; sPos=targetFrame.Position 
        end 
    end))
    Track(UserInputService.InputChanged:Connect(function(i) 
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then 
            local d=i.Position-start
            targetFrame.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset+d.X, sPos.Y.Scale, sPos.Y.Offset+d.Y) 
        end 
    end))
    Track(UserInputService.InputEnded:Connect(function(i) 
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then 
            dragging=false 
        end 
    end))
end

-- NOTIFICATIONS
function CandyLib:Notify(opts)
    opts = opts or {}
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
        l.SortOrder = Enum.SortOrder.LayoutOrder; l.HorizontalAlignment = Enum.HorizontalAlignment.Right; l.Padding = UDim.new(0,6); l.Parent = holder
        self._NotifyHolder = holder
    end

    local box = Instance.new('Frame')
    box.BackgroundColor3 = Theme.Panel; box.BackgroundTransparency = 1; box.Size = UDim2.new(1,0,0,52); box.LayoutOrder = -os.clock()*1000; box.ClipsDescendants = true; box.Parent = holder; Round(box, 12)
    local stroke = Stroke(box, Theme.Border, 1)
    
    local iconBox = Instance.new('Frame')
    iconBox.BackgroundColor3 = Theme.PanelAlt; iconBox.BackgroundTransparency = 1; iconBox.Size = UDim2.new(0,36,0,36); iconBox.Position = UDim2.new(0,9,0.5,-18); iconBox.ZIndex = 3; iconBox.Parent = box; Round(iconBox, 9)
    local iconLbl = Instance.new('TextLabel')
    iconLbl.BackgroundTransparency = 1; iconLbl.Size = UDim2.fromScale(1,1); iconLbl.ZIndex = 4; iconLbl.FontFace = IconBold; iconLbl.Text = opts.Icon or 'check'; iconLbl.TextColor3 = Theme.Text; iconLbl.TextSize = 18; iconLbl.TextTransparency = 1; iconLbl.Parent = iconBox
    
    local titleLbl = Instance.new('TextLabel')
    titleLbl.BackgroundTransparency = 1; titleLbl.Position = UDim2.new(0,53,0,8); titleLbl.Size = UDim2.new(1,-64,0,18); titleLbl.Font = Enum.Font.GothamBold; titleLbl.Text = opts.Title or 'Notification'; titleLbl.TextColor3 = Theme.Text; titleLbl.TextSize = 14; titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.TextTransparency = 1; titleLbl.Parent = box
    
    local contentLbl = Instance.new('TextLabel')
    contentLbl.BackgroundTransparency = 1; contentLbl.Position = UDim2.new(0,53,0,27); contentLbl.Size = UDim2.new(1,-64,0,16); contentLbl.Font = Enum.Font.Gotham; contentLbl.Text = opts.Content or ''; contentLbl.TextColor3 = Theme.TextMuted; contentLbl.TextSize = 12; contentLbl.TextXAlignment = Enum.TextXAlignment.Left; contentLbl.TextTransparency = 1; contentLbl.Parent = box
    
    Tween(box, TweenInfo.new(0.22), {BackgroundTransparency = 0.03}); Tween(stroke, TweenInfo.new(0.22), {Transparency = 0.55}); Tween(iconBox, TweenInfo.new(0.22), {BackgroundTransparency = 0.05}); Tween(iconLbl, TweenInfo.new(0.22), {TextTransparency = 0.05}); Tween(titleLbl, TweenInfo.new(0.22), {TextTransparency = 0.05}); Tween(contentLbl, TweenInfo.new(0.22), {TextTransparency = 0.3})
    
    task.delay(opts.Duration or 3, function()
        Tween(box, TweenInfo.new(0.22), {BackgroundTransparency = 1}); Tween(stroke, TweenInfo.new(0.22), {Transparency = 1}); Tween(iconBox, TweenInfo.new(0.22), {BackgroundTransparency = 1}); Tween(iconLbl, TweenInfo.new(0.22), {TextTransparency = 1}); Tween(titleLbl, TweenInfo.new(0.22), {TextTransparency = 1}); Tween(contentLbl, TweenInfo.new(0.22), {TextTransparency = 1})
        task.wait(0.25); box:Destroy()
    end)
end

-- ELEMENTS
local function CreateToggle(parent, config)
    local row = Instance.new('Frame')
    row.BackgroundColor3 = Theme.PanelAlt; row.BackgroundTransparency = 1; row.Size = UDim2.new(1,-16,0,34); row.Parent = parent; Round(row, 8)
    
    local label = Instance.new('TextLabel')
    label.BackgroundTransparency = 1; label.Position = UDim2.new(0,10,0,0); label.Size = UDim2.new(1,-60,1,0); label.Font = Enum.Font.GothamMedium; label.Text = config.Name or 'Toggle'; label.TextColor3 = Theme.Text; label.TextSize = 13; label.TextTransparency = 0.15; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = row
    
    local pill = Instance.new('Frame')
    pill.BackgroundColor3 = Theme.PanelAlt; pill.BorderSizePixel = 0; pill.AnchorPoint = Vector2.new(1,0.5); pill.Position = UDim2.new(1,-8,0.5,0); pill.Size = UDim2.fromOffset(36,20); pill.Parent = row; Round(pill, 20)
    local pillStroke = Stroke(pill, Theme.Border, 0.55)
    
    local knob = Instance.new('Frame')
    knob.BackgroundColor3 = Theme.TextMuted; knob.BorderSizePixel = 0; knob.AnchorPoint = Vector2.new(0,0.5); knob.Position = UDim2.new(0,3,0.5,0); knob.Size = UDim2.fromOffset(14,14); knob.Parent = pill; Round(knob, 20)
    
    local state = config.Default or false
    local function refresh()
        if state then 
            Tween(pill, TweenInfo.new(0.16), {BackgroundColor3 = Theme.Accent}); Tween(pillStroke, TweenInfo.new(0.16), {Transparency = 0}); Tween(knob, TweenInfo.new(0.16), {Position = UDim2.new(1,-17,0.5,0), BackgroundColor3 = Theme.BG})
        else 
            Tween(pill, TweenInfo.new(0.16), {BackgroundColor3 = Theme.PanelAlt}); Tween(pillStroke, TweenInfo.new(0.16), {Transparency = 0.55}); Tween(knob, TweenInfo.new(0.16), {Position = UDim2.new(0,3,0.5,0), BackgroundColor3 = Theme.TextMuted}) 
        end 
    end
    refresh()
    
    local input = CreateInput(row, function() 
        state = not state; refresh(); if config.Callback then config.Callback(state) end 
    end)
    Track(input.MouseEnter:Connect(function() Tween(row, TweenInfo.new(0.15), {BackgroundTransparency = 0.9}) end))
    Track(input.MouseLeave:Connect(function() Tween(row, TweenInfo.new(0.15), {BackgroundTransparency = 1}) end))
    
    local api = {}
    function api:GetValue() return state end
    function api:SetValue(v) state = v; refresh(); if config.Callback then config.Callback(state) end end
    if config.Flag then CandyLib.Flags[config.Flag] = api end
    return api
end

local function CreateSlider(parent, config)
    local row = Instance.new('Frame')
    row.BackgroundColor3 = Theme.PanelAlt; row.BackgroundTransparency = 1; row.Size = UDim2.new(1,-16,0,46); row.Parent = parent; Round(row, 8)
    
    local label = Instance.new('TextLabel')
    label.BackgroundTransparency = 1; label.Position = UDim2.new(0,10,0,6); label.Size = UDim2.new(1,-80,0,16); label.Font = Enum.Font.GothamMedium; label.Text = config.Name or 'Slider'; label.TextColor3 = Theme.Text; label.TextSize = 13; label.TextTransparency = 0.15; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = row
    
    local valBox = Instance.new('Frame')
    valBox.BackgroundColor3 = Theme.Panel; valBox.AnchorPoint = Vector2.new(1,0); valBox.Position = UDim2.new(1,-10,0,5); valBox.Size = UDim2.fromOffset(40,18); valBox.Parent = row; Round(valBox, 6); Stroke(valBox, Theme.BorderSoft, 0.4)
    
    local valTxt = Instance.new('TextLabel')
    valTxt.BackgroundTransparency = 1; valTxt.Size = UDim2.fromScale(1,1); valTxt.Font = Enum.Font.GothamMedium; valTxt.Text = tostring(config.Default or 50); valTxt.TextColor3 = Theme.Text; valTxt.TextSize = 11; valTxt.TextTransparency = 0.2; valTxt.Parent = valBox
    
    local track = Instance.new('Frame')
    track.BackgroundColor3 = Theme.BorderSoft; track.AnchorPoint = Vector2.new(0,0.5); track.Position = UDim2.new(0,10,1,-10); track.Size = UDim2.new(1,-20,0,4); track.Parent = row; Round(track, 2)
    
    local fill = Instance.new('Frame')
    fill.BackgroundColor3 = Theme.Accent; fill.BorderSizePixel = 0; fill.Size = UDim2.new(0,0,1,0); fill.Parent = track; Round(fill, 2)
    
    local knob = Instance.new('Frame')
    knob.BackgroundColor3 = Theme.Accent; knob.BorderSizePixel = 0; knob.AnchorPoint = Vector2.new(0.5,0.5); knob.Size = UDim2.fromOffset(12,12); knob.Parent = fill; Round(knob, 20)
    
    local current = config.Default or 50
    local min = config.Min or 0
    local max = config.Max or 100
    
    local function setVal(v) 
        current = math.clamp(v, min, max); local alpha = (max==min) and 0 or (current-min)/(max-min)
        Tween(fill, TweenInfo.new(0.08), {Size = UDim2.new(alpha,0,1,0)}); valTxt.Text = tostring(current); if config.Callback then config.Callback(current) end 
    end
    setVal(current)
    
    local dragging = false
    Track(track.InputBegan:Connect(function(i) 
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then 
            dragging=true; local r=(i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X; setVal(min+(max-min)*math.clamp(r,0,1)) 
        end 
    end))
    Track(UserInputService.InputEnded:Connect(function(i) 
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end 
    end))
    Track(UserInputService.InputChanged:Connect(function(i) 
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then 
            local r=(i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X; setVal(min+(max-min)*math.clamp(r,0,1)) 
        end 
    end))
    
    local api = {}
    function api:GetValue() return current end
    function api:SetValue(v) setVal(v) end
    if config.Flag then CandyLib.Flags[config.Flag] = api end
    return api
end

local function CreateButton(parent, config)
    local btn = Instance.new('Frame')
    btn.BackgroundColor3 = Theme.PanelAlt; btn.BackgroundTransparency = 0.05; btn.Size = UDim2.new(1,-16,0,34); btn.Parent = parent; Round(btn, 8)
    local stroke = Stroke(btn, Theme.BorderSoft, 0.5)
    
    local ic = Instance.new('TextLabel')
    ic.BackgroundTransparency = 1; ic.Position = UDim2.new(0,10,0,0); ic.Size = UDim2.new(0,20,1,0); ic.FontFace = IconBold; ic.Text = config.Icon or 'arrow-small-right'; ic.TextColor3 = Theme.Accent; ic.TextSize = 16; ic.TextTransparency = 0.15; ic.Parent = btn
    
    local lbl = Instance.new('TextLabel')
    lbl.BackgroundTransparency = 1; lbl.Position = UDim2.new(0,36,0,0); lbl.Size = UDim2.new(1,-46,1,0); lbl.Font = Enum.Font.GothamMedium; lbl.Text = config.Name or 'Button'; lbl.TextColor3 = Theme.Text; lbl.TextSize = 13; lbl.TextTransparency = 0.1; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = btn
    
    local inp = CreateInput(btn, config.Callback or function() end)
    Track(inp.MouseEnter:Connect(function() Tween(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0}); Tween(stroke, TweenInfo.new(0.15), {Transparency = 0.2, Color = Theme.Accent}) end))
    Track(inp.MouseLeave:Connect(function() Tween(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.05}); Tween(stroke, TweenInfo.new(0.15), {Transparency = 0.5, Color = Theme.BorderSoft}) end))
end

local function CreateTextInput(parent, config)
    local row = Instance.new('Frame')
    row.BackgroundColor3 = Theme.PanelAlt; row.BackgroundTransparency = 1; row.Size = UDim2.new(1,-16,0,34); row.Parent = parent; Round(row, 8)
    
    local label = Instance.new('TextLabel')
    label.BackgroundTransparency = 1; label.Position = UDim2.new(0,10,0,0); label.Size = UDim2.new(0,100,1,0); label.Font = Enum.Font.GothamMedium; label.Text = config.Name or 'Input'; label.TextColor3 = Theme.Text; label.TextSize = 13; label.TextTransparency = 0.15; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = row
    
    local box = Instance.new('Frame')
    box.BackgroundColor3 = Theme.Panel; box.AnchorPoint = Vector2.new(1,0.5); box.Position = UDim2.new(1,-8,0.5,0); box.Size = UDim2.new(0,140,0,22); box.Parent = row; Round(box, 6); Stroke(box, Theme.BorderSoft, 0.4)
    
    local tb = Instance.new('TextBox')
    tb.BackgroundTransparency = 1; tb.Position = UDim2.new(0,6,0,0); tb.Size = UDim2.new(1,-12,1,0); tb.Font = Enum.Font.GothamMedium; tb.PlaceholderText = 'Enter...'; tb.Text = tostring(config.Default or ''); tb.TextColor3 = Theme.Text; tb.TextSize = 12; tb.ClearTextOnFocus = false; tb.TextXAlignment = Enum.TextXAlignment.Left; tb.Parent = box
    
    local function parse(t) if config.Numeric then return tonumber(t) or 0 end return t end
    Track(tb:GetPropertyChangedSignal('Text'):Connect(function()
        if config.Numeric then tb.Text = tb.Text:gsub('[^%d%.%-]','') end
        if config.Callback then config.Callback(parse(tb.Text)) end
    end))
    
    local api = {}
    function api:GetValue() return parse(tb.Text) end
    function api:SetValue(v) tb.Text = tostring(v); if config.Callback then config.Callback(parse(tb.Text)) end end
    if config.Flag then CandyLib.Flags[config.Flag] = api end
    return api
end

local function KeycodeToString(k)
    if typeof(k) == 'string' then return k end
    if not k then return 'None' end
    return tostring(k.Name)
end

local function CreateKeybind(parent, config)
    local row = Instance.new('Frame')
    row.BackgroundColor3 = Theme.PanelAlt; row.BackgroundTransparency = 1; row.Size = UDim2.new(1,-16,0,34); row.Parent = parent; Round(row, 8)
    
    local label = Instance.new('TextLabel')
    label.BackgroundTransparency = 1; label.Position = UDim2.new(0,10,0,0); label.Size = UDim2.new(1,-90,1,0); label.Font = Enum.Font.GothamMedium; label.Text = config.Name or 'Keybind'; label.TextColor3 = Theme.Text; label.TextSize = 13; label.TextTransparency = 0.15; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = row
    
    local keyBox = Instance.new('Frame')
    keyBox.BackgroundColor3 = Theme.Panel; keyBox.AnchorPoint = Vector2.new(1,0.5); keyBox.Position = UDim2.new(1,-8,0.5,0); keyBox.Size = UDim2.fromOffset(70,22); keyBox.Parent = row; Round(keyBox, 6); Stroke(keyBox, Theme.BorderSoft, 0.4)
    
    local keyTxt = Instance.new('TextLabel')
    keyTxt.BackgroundTransparency = 1; keyTxt.Size = UDim2.fromScale(1,1); keyTxt.Font = Enum.Font.GothamMedium; keyTxt.Text = KeycodeToString(config.Default); keyTxt.TextColor3 = Theme.Text; keyTxt.TextSize = 11; keyTxt.TextTransparency = 0.3; keyTxt.Parent = keyBox
    
    local current = config.Default
    local inp = CreateInput(keyBox, function()
        keyTxt.Text = '...'
        local sel
        while not sel do
            local k = UserInputService.InputBegan:Wait()
            if k.KeyCode ~= Enum.KeyCode.Unknown then sel = k.KeyCode.Name end
        end
        current = sel; keyTxt.Text = KeycodeToString(current); if config.Callback then config.Callback(current) end
    end)
    
    Track(inp.MouseEnter:Connect(function() Tween(keyBox, TweenInfo.new(0.15), {BackgroundColor3 = Theme.PanelAlt}) end))
    Track(inp.MouseLeave:Connect(function() Tween(keyBox, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Panel}) end))
    
    Track(UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if not current then return end
        local pressed = inp.KeyCode.Name == current or (current == 'MouseLeft' and inp.UserInputType==Enum.UserInputType.MouseButton1)
        if pressed and config.Callback then config.Callback(current) end
    end))
    
    local api = {}
    function api:GetValue() return current end
    function api:SetValue(v) current=v; keyTxt.Text = KeycodeToString(v) end
    if config.Flag then CandyLib.Flags[config.Flag] = api end
    return api
end

local function CreateDropdown(parent, config)
    local row = Instance.new('Frame')
    row.BackgroundColor3 = Theme.PanelAlt; row.BackgroundTransparency = 1; row.Size = UDim2.new(1,-16,0,34); row.Parent = parent; Round(row, 8)
    
    local label = Instance.new('TextLabel')
    label.BackgroundTransparency = 1; label.Position = UDim2.new(0,10,0,0); label.Size = UDim2.new(1,-140,1,0); label.Font = Enum.Font.GothamMedium; label.Text = config.Name or 'Dropdown'; label.TextColor3 = Theme.Text; label.TextSize = 13; label.TextTransparency = 0.15; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = row
    
    local btn = Instance.new('Frame')
    btn.BackgroundColor3 = Theme.Panel; btn.AnchorPoint = Vector2.new(1,0.5); btn.Position = UDim2.new(1,-8,0.5,0); btn.Size = UDim2.new(0,120,0,22); btn.Parent = row; Round(btn, 6); Stroke(btn, Theme.BorderSoft, 0.4)
    
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
    btnTxt.BackgroundTransparency = 1; btnTxt.Position = UDim2.new(0,6,0,0); btnTxt.Size = UDim2.new(1,-24,1,0); btnTxt.Font = Enum.Font.GothamMedium; btnTxt.Text = fmt(config.Default); btnTxt.TextColor3 = Theme.Text; btnTxt.TextSize = 11; btnTxt.TextTransparency = 0.3; btnTxt.TextXAlignment = Enum.TextXAlignment.Left; btnTxt.TextTruncate = Enum.TextTruncate.AtEnd; btnTxt.Parent = btn
    
    local chevron = Instance.new('TextLabel')
    chevron.BackgroundTransparency = 1; chevron.AnchorPoint = Vector2.new(1,0.5); chevron.Position = UDim2.new(1,-2,0.5,0); chevron.Size = UDim2.fromOffset(18,18); chevron.FontFace = IconBold; chevron.Text = 'chevron-small-down'; chevron.TextColor3 = Theme.TextMuted; chevron.TextSize = 14; chevron.Parent = btn
    
    local current = config.Default
    if config.Multi and type(current)~='table' then current = {} end
    
    local popup = Instance.new('Frame')
    popup.BackgroundColor3 = Theme.Panel; popup.BackgroundTransparency = 1; popup.Size = UDim2.fromOffset(160, math.min(#(config.Values or {})*24+8, 200)); popup.ClipsDescendants = true; popup.Visible = false; popup.Parent = CandyLib.ScreenGui; Round(popup, 10)
    local popupStroke = Stroke(popup, Theme.Border, 1)
    
    local scroll = Instance.new('ScrollingFrame')
    scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.Position = UDim2.new(0,4,0,4); scroll.Size = UDim2.new(1,-8,1,-8); scroll.ScrollBarThickness = 2; scroll.ScrollBarImageColor3 = Theme.BorderSoft; scroll.CanvasSize = UDim2.new(0,0,0,#(config.Values or {})*24); scroll.Parent = popup
    local list = Instance.new('UIListLayout')
    list.SortOrder = Enum.SortOrder.LayoutOrder; list.Parent = scroll
    
    local function refresh() btnTxt.Text = fmt(current) end
    refresh()
    
    local function isSelected(v)
        if config.Multi then return current[v] == true end
        return current == v
    end
    
    local itemRefs = {}
    local function buildItems()
        for _, ch in ipairs(scroll:GetChildren()) do if ch:IsA('Frame') then ch:Destroy() end end
        table.clear(itemRefs)
        for i, v in ipairs(config.Values or {}) do
            local item = Instance.new('Frame')
            item.BackgroundColor3 = Theme.PanelAlt; item.BackgroundTransparency = 1; item.Size = UDim2.new(1,0,0,24); item.LayoutOrder = i; item.Parent = scroll; Round(item, 5)
            
            local txt = Instance.new('TextLabel')
            txt.BackgroundTransparency = 1; txt.Position = UDim2.new(0,8,0,0); txt.Size = UDim2.new(1,-16,1,0); txt.Font = Enum.Font.GothamMedium; txt.Text = tostring(v); txt.TextColor3 = Theme.Text; txt.TextSize = 12; txt.TextTransparency = 0.15; txt.TextXAlignment = Enum.TextXAlignment.Left; txt.Parent = item
            
            local function paint()
                if isSelected(v) then
                    txt.TextColor3 = Theme.Accent; txt.TextTransparency = 0
                else
                    txt.TextColor3 = Theme.Text; txt.TextTransparency = 0.15
                end
            end
            paint(); table.insert(itemRefs, paint)
            
            local inp = CreateInput(item, function()
                if config.Multi then
                    current[v] = not current[v]; refresh()
                    for _, p in ipairs(itemRefs) do p() end
                    if config.Callback then config.Callback(current) end
                else
                    current = v; refresh(); popup.Visible = false
                    if config.Callback then config.Callback(current) end
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
            popup.Size = UDim2.fromOffset(math.max(140, size.X), math.min(#(config.Values or {})*24+8, 200))
            popup.Visible = true
            Tween(popup, TweenInfo.new(0.16), {BackgroundTransparency = 0.03}); Tween(popupStroke, TweenInfo.new(0.16), {Transparency = 0.55})
            task.spawn(function()
                while open do
                    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and not MouseOver(popup) and not MouseOver(btn) then
                        open = false; popup.Visible = false; popup.BackgroundTransparency = 1
                    end
                    task.wait(0.05)
                end
            end)
        else
            Tween(popup, TweenInfo.new(0.14), {BackgroundTransparency = 1}); Tween(popupStroke, TweenInfo.new(0.14), {Transparency = 1})
            task.delay(0.15, function() if not open then popup.Visible = false end end)
        end
    end
    
    local bInp = CreateInput(btn, togglePopup)
    Track(bInp.MouseEnter:Connect(function() Tween(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.PanelAlt}) end))
    Track(bInp.MouseLeave:Connect(function() Tween(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Panel}) end))
    
    local api = {}
    function api:GetValue() return current end
    function api:SetValue(v) current=v; refresh(); for _,p in ipairs(itemRefs) do p() end; if config.Callback then config.Callback(current) end end
    function api:SetValues(vs) config.Values=vs; buildItems(); refresh() end
    if config.Flag then CandyLib.Flags[config.Flag] = api end
    return api
end

local function CreateColorPicker(parent, config)
    local row = Instance.new('Frame')
    row.BackgroundColor3 = Theme.PanelAlt; row.BackgroundTransparency = 1; row.Size = UDim2.new(1,-16,0,34); row.Parent = parent; Round(row, 8)
    
    local label = Instance.new('TextLabel')
    label.BackgroundTransparency = 1; label.Position = UDim2.new(0,10,0,0); label.Size = UDim2.new(1,-50,1,0); label.Font = Enum.Font.GothamMedium; label.Text = config.Name or 'Color'; label.TextColor3 = Theme.Text; label.TextSize = 13; label.TextTransparency = 0.15; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = row
    
    local swatch = Instance.new('Frame')
    swatch.BackgroundColor3 = config.Default or Color3.new(1,1,1); swatch.AnchorPoint = Vector2.new(1,0.5); swatch.Position = UDim2.new(1,-8,0.5,0); swatch.Size = UDim2.fromOffset(24,22); swatch.Parent = row; Round(swatch, 6); Stroke(swatch, Theme.Border, 0.4)
    
    local current = config.Default or Color3.new(1,1,1)
    
    local popup = Instance.new('Frame')
    popup.BackgroundColor3 = Theme.Panel; popup.BackgroundTransparency = 1; popup.Size = UDim2.fromOffset(200, 240); popup.ClipsDescendants = true; popup.Visible = false; popup.Parent = CandyLib.ScreenGui; Round(popup, 10)
    local pStroke = Stroke(popup, Theme.Border, 1)
    
    local sv = Instance.new('Frame')
    sv.BackgroundColor3 = Color3.fromRGB(255,0,0); sv.Position = UDim2.new(0,10,0,10); sv.Size = UDim2.fromOffset(180,150); sv.ClipsDescendants = true; sv.Parent = popup; Round(sv, 6)
    
    local sat = Instance.new('Frame')
    sat.BackgroundColor3 = Color3.new(1,1,1); sat.Size = UDim2.fromScale(1,1); sat.Parent = sv; Round(sat, 6)
    local satGrad = Instance.new('UIGradient'); satGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)}); satGrad.Parent = sat
    
    local val = Instance.new('Frame')
    val.BackgroundColor3 = Color3.new(0,0,0); val.Size = UDim2.fromScale(1,1); val.Parent = sv; Round(val, 6)
    local valGrad = Instance.new('UIGradient'); valGrad.Rotation = 90; valGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)}); valGrad.Parent = val
    
    local knob = Instance.new('Frame')
    knob.AnchorPoint = Vector2.new(0.5,0.5); knob.BackgroundColor3 = Color3.new(1,1,1); knob.BackgroundTransparency = 1; knob.Size = UDim2.fromOffset(12,12); knob.Parent = sv; Round(knob, 20); Stroke(knob, Color3.new(1,1,1), 0, 2)
    
    local hue = Instance.new('Frame')
    hue.BackgroundColor3 = Color3.new(1,1,1); hue.Position = UDim2.new(0,10,0,170); hue.Size = UDim2.new(1,-20,0,14); hue.Parent = popup; Round(hue, 4)
    local hueGrad = Instance.new('UIGradient')
    hueGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)),ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0))}
    hueGrad.Parent = hue
    
    local hueKnob = Instance.new('Frame')
    hueKnob.AnchorPoint = Vector2.new(0.5,0.5); hueKnob.Position = UDim2.new(0,0,0.5,0); hueKnob.Size = UDim2.fromOffset(10,18); hueKnob.Parent = hue; Round(hueKnob, 4); Stroke(hueKnob, Color3.new(1,1,1), 0, 2)
    
    local hex = Instance.new('TextBox')
    hex.BackgroundColor3 = Theme.PanelAlt; hex.Position = UDim2.new(0,10,0,196); hex.Size = UDim2.new(1,-20,0,22); hex.Font = Enum.Font.GothamMedium; hex.Text = '#'..current:ToHex(); hex.TextColor3 = Theme.Text; hex.TextSize = 11; hex.ClearTextOnFocus = false; hex.Parent = popup; Round(hex, 6); Stroke(hex, Theme.BorderSoft, 0.5)
    
    local h, s, v = current:ToHSV()
    local function updateSV()
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1); knob.Position = UDim2.fromScale(s, 1-v); hueKnob.Position = UDim2.new(h, 0, 0.5, 0)
        current = Color3.fromHSV(h, s, v); swatch.BackgroundColor3 = current; hex.Text = '#'..string.upper(current:ToHex())
        if config.Callback then config.Callback(current) end
    end
    updateSV()
    
    local dSV, dHue = false, false
    Track(sv.InputBegan:Connect(function(i) 
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then 
            dSV=true; local r=(i.Position-sv.AbsolutePosition)/sv.AbsoluteSize; s=math.clamp(r.X,0,1); v=1-math.clamp(r.Y,0,1); updateSV() 
        end 
    end))
    Track(hue.InputBegan:Connect(function(i) 
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then 
            dHue=true; local r=(i.Position.X-hue.AbsolutePosition.X)/hue.AbsoluteSize.X; h=math.clamp(r,0,1); updateSV() 
        end 
    end))
    Track(UserInputService.InputEnded:Connect(function(i) 
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dSV=false; dHue=false end 
    end))
    Track(UserInputService.InputChanged:Connect(function(i) 
        if dSV and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then 
            local r=(i.Position-sv.AbsolutePosition)/sv.AbsoluteSize; s=math.clamp(r.X,0,1); v=1-math.clamp(r.Y,0,1); updateSV() 
        end
        if dHue and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then 
            local r=(i.Position.X-hue.AbsolutePosition.X)/hue.AbsoluteSize.X; h=math.clamp(r,0,1); updateSV() 
        end 
    end))
    
    local open = false
    CreateInput(swatch, function()
        open = not open
        if open then
            popup.Position = UDim2.fromOffset(swatch.AbsolutePosition.X-176, swatch.AbsolutePosition.Y+30); popup.Visible = true
            Tween(popup, TweenInfo.new(0.16), {BackgroundTransparency = 0.03}); Tween(pStroke, TweenInfo.new(0.16), {Transparency = 0.55})
        else
            Tween(popup, TweenInfo.new(0.14), {BackgroundTransparency = 1}); Tween(pStroke, TweenInfo.new(0.14), {Transparency = 1})
            task.delay(0.15, function() if not open then popup.Visible=false end end)
        end
    end)
    
    local api = {}
    function api:GetValue() return current end
    function api:SetValue(c) h,s,v = c:ToHSV(); updateSV() end
    if config.Flag then CandyLib.Flags[config.Flag] = api end
    return api
end

-- SECTION
local function CreateSection(parent, name)
    local holder = Instance.new('Frame')
    holder.BackgroundTransparency = 1; holder.Size = UDim2.new(1,-8,0,0); holder.AutomaticSize = Enum.AutomaticSize.Y; holder.Parent = parent
    
    local title = Instance.new('TextLabel')
    title.BackgroundTransparency = 1; title.Position = UDim2.new(0,4,0,0); title.Size = UDim2.new(1,-8,0,20); title.Font = Enum.Font.GothamBold; title.Text = string.upper(name); title.TextColor3 = Theme.TextMuted; title.TextSize = 11; title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = holder
    
    local panel = Instance.new('Frame')
    panel.BackgroundColor3 = Theme.Panel; panel.BackgroundTransparency = 0.05; panel.Position = UDim2.new(0,0,0,24); panel.Size = UDim2.new(1,0,0,0); panel.AutomaticSize = Enum.AutomaticSize.Y; panel.Parent = holder; Round(panel, 14); Stroke(panel, Theme.BorderSoft, 0.55)
    
    local pad = Instance.new('UIPadding')
    pad.PaddingTop = UDim.new(0,8); pad.PaddingBottom = UDim.new(0,8); pad.Parent = panel
    
    local list = Instance.new('UIListLayout')
    list.SortOrder = Enum.SortOrder.LayoutOrder; list.HorizontalAlignment = Enum.HorizontalAlignment.Center; list.Padding = UDim.new(0,4); list.Parent = panel
    
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

-- WINDOW
function CandyLib:CreateWindow(cfg)
    cfg = cfg or {}
    local Window = { Tabs = {}, Current = 1, ConfigFolder = cfg.ConfigFolder or 'CandyConfigs' }
    
    if not isfolder(Window.ConfigFolder) then makefolder(Window.ConfigFolder) end

    local main = Instance.new('Frame')
    main.Name = CandyLib.RandomString(); main.AnchorPoint = Vector2.new(0.5,0.5); main.BackgroundColor3 = Theme.BG; main.BackgroundTransparency = 0.03; main.BorderSizePixel = 0; main.ClipsDescendants = true; main.Position = UDim2.fromScale(0.5, 0.5); main.Size = cfg.Size or UDim2.fromOffset(720, 500); main.Parent = CandyLib.ScreenGui; Round(main, 18); Stroke(main, Theme.BorderSoft, 0.45, 1.2)
    
    local dragBar = Instance.new('Frame')
    dragBar.BackgroundTransparency = 1; dragBar.Size = UDim2.new(1,0,0,40); dragBar.Parent = main
    MakeDraggable(dragBar, main)

    local rail = Instance.new('Frame')
    rail.BackgroundColor3 = Theme.Panel; rail.BackgroundTransparency = 0.05; rail.Position = UDim2.fromOffset(10,10); rail.Size = UDim2.new(0,64,1,-20); rail.Parent = main; Round(rail, 14); Stroke(rail, Theme.BorderSoft, 0.5)
    
    if cfg.Logo then 
        local li = Instance.new('ImageLabel')
        li.BackgroundTransparency = 1; li.Position = UDim2.new(0.5,0,0,12); li.AnchorPoint = Vector2.new(0.5,0); li.Size = UDim2.fromOffset(40,40); li.Image = cfg.Logo; li.Parent = rail 
    end
    
    local tabList = Instance.new('Frame')
    tabList.BackgroundTransparency = 1; tabList.Position = UDim2.new(0,10,0,68); tabList.Size = UDim2.new(1,-20,1,-160); tabList.Parent = rail
    local tabListLayout = Instance.new('UIListLayout')
    tabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder; tabListLayout.Padding = UDim.new(0,6); tabListLayout.Parent = tabList

    local avatar = Instance.new('ImageLabel')
    avatar.BackgroundTransparency = 1; avatar.AnchorPoint = Vector2.new(0.5,1); avatar.Position = UDim2.new(0.5,0,1,-12); avatar.Size = UDim2.fromOffset(40,40); avatar.Image = CandyLib.UserProfile; avatar.Parent = rail; Round(avatar, 20)

    local contentPanel = Instance.new('Frame')
    contentPanel.BackgroundColor3 = Theme.Panel; contentPanel.BackgroundTransparency = 0.03; contentPanel.Position = UDim2.new(0, 84, 0, 10); contentPanel.Size = UDim2.new(1, -94, 1, -20); contentPanel.Parent = main; Round(contentPanel, 14); Stroke(contentPanel, Theme.BorderSoft, 0.5)
    
    local header = Instance.new('Frame')
    header.BackgroundTransparency = 1; header.Size = UDim2.new(1,0,0,52); header.Parent = contentPanel
    
    local headerLogo = Instance.new('ImageLabel')
    headerLogo.BackgroundTransparency = 1; headerLogo.Position = UDim2.new(0,20,0.5,-14); headerLogo.Size = UDim2.fromOffset(28,28); headerLogo.Image = cfg.Logo or ''; headerLogo.Parent = header
    
    local headerTitle = Instance.new('TextLabel')
    headerTitle.BackgroundTransparency = 1; headerTitle.Position = UDim2.new(0, (cfg.Logo and 56 or 20), 0, 10); headerTitle.Size = UDim2.new(1,-200,0,20); headerTitle.Font = Enum.Font.GothamBold; headerTitle.Text = cfg.Name or 'Candy'; headerTitle.TextColor3 = Theme.Text; headerTitle.TextSize = 15; headerTitle.TextXAlignment = Enum.TextXAlignment.Left; headerTitle.Parent = header
    
    local headerSub = Instance.new('TextLabel')
    headerSub.BackgroundTransparency = 1; headerSub.Position = UDim2.new(0, (cfg.Logo and 56 or 20), 0, 28); headerSub.Size = UDim2.new(1,-200,0,14); headerSub.Font = Enum.Font.Gotham; headerSub.Text = cfg.Content or 'v2.1.0'; headerSub.TextColor3 = Theme.TextMuted; headerSub.TextSize = 11; headerSub.TextTransparency = 0.3; headerSub.TextXAlignment = Enum.TextXAlignment.Left; headerSub.Parent = header

    -- CONFIG SYSTEM
    local cfgBtn = Instance.new('Frame')
    cfgBtn.BackgroundColor3 = Theme.PanelAlt; cfgBtn.BackgroundTransparency = 0.05; cfgBtn.AnchorPoint = Vector2.new(1,0.5); cfgBtn.Position = UDim2.new(1,-16,0.5,0); cfgBtn.Size = UDim2.fromOffset(120,30); cfgBtn.Parent = header; Round(cfgBtn, 8); Stroke(cfgBtn, Theme.BorderSoft, 0.4)
    
    local cfgIcon = Instance.new('TextLabel')
    cfgIcon.BackgroundTransparency = 1; cfgIcon.Position = UDim2.new(0,10,0,0); cfgIcon.Size = UDim2.fromOffset(18,30); cfgIcon.FontFace = IconBold; cfgIcon.Text = 'floppy-disk'; cfgIcon.TextColor3 = Theme.Accent; cfgIcon.TextSize = 14; cfgIcon.TextTransparency = 0.2; cfgIcon.Parent = cfgBtn
    
    local cfgLbl = Instance.new('TextLabel')
    cfgLbl.BackgroundTransparency = 1; cfgLbl.Position = UDim2.new(0,34,0,0); cfgLbl.Size = UDim2.new(1,-44,1,0); cfgLbl.Font = Enum.Font.GothamMedium; cfgLbl.Text = 'Default'; cfgLbl.TextColor3 = Theme.Text; cfgLbl.TextSize = 12; cfgLbl.TextTransparency = 0.2; cfgLbl.TextXAlignment = Enum.TextXAlignment.Left; cfgLbl.TextTruncate = Enum.TextTruncate.AtEnd; cfgLbl.Parent = cfgBtn

    local cfgPopup = Instance.new('Frame')
    cfgPopup.BackgroundColor3 = Theme.Panel; cfgPopup.BackgroundTransparency = 1; cfgPopup.Size = UDim2.fromOffset(220, 300); cfgPopup.ClipsDescendants = true; cfgPopup.Visible = false; cfgPopup.Parent = CandyLib.ScreenGui; Round(cfgPopup, 12)
    local cfgPopupStroke = Stroke(cfgPopup, Theme.Border, 1)
    
    local cfgScroll = Instance.new('ScrollingFrame')
    cfgScroll.BackgroundTransparency = 1; cfgScroll.BorderSizePixel = 0; cfgScroll.Position = UDim2.new(0,6,0,6); cfgScroll.Size = UDim2.new(1,-12,1,-12); cfgScroll.ScrollBarThickness = 2; cfgScroll.ScrollBarImageColor3 = Theme.BorderSoft; cfgScroll.CanvasSize = UDim2.new(0,0,0,0); cfgScroll.Parent = cfgPopup
    local cfgList = Instance.new('UIListLayout')
    cfgList.SortOrder = Enum.SortOrder.LayoutOrder; cfgList.Padding = UDim.new(0,4); cfgList.Parent = cfgScroll

    local newCfgRow = Instance.new('Frame')
    newCfgRow.BackgroundColor3 = Theme.PanelAlt; newCfgRow.BackgroundTransparency = 0.05; newCfgRow.Size = UDim2.new(1,-4,0,32); newCfgRow.LayoutOrder = -1; newCfgRow.Parent = cfgScroll; Round(newCfgRow, 8)
    
    local newCfgInput = Instance.new('TextBox')
    newCfgInput.BackgroundTransparency = 1; newCfgInput.Position = UDim2.new(0,8,0,0); newCfgInput.Size = UDim2.new(1,-42,1,0); newCfgInput.Font = Enum.Font.GothamMedium; newCfgInput.PlaceholderText = 'New config name...'; newCfgInput.PlaceholderColor3 = Theme.TextMuted; newCfgInput.Text = ''; newCfgInput.TextColor3 = Theme.Text; newCfgInput.TextSize = 12; newCfgInput.ClearTextOnFocus = false; newCfgInput.TextXAlignment = Enum.TextXAlignment.Left; newCfgInput.Parent = newCfgRow
    
    local newCfgBtn = Instance.new('TextLabel')
    newCfgBtn.BackgroundTransparency = 1; newCfgBtn.AnchorPoint = Vector2.new(1,0.5); newCfgBtn.Position = UDim2.new(1,-6,0.5,0); newCfgBtn.Size = UDim2.fromOffset(24,24); newCfgBtn.FontFace = IconBold; newCfgBtn.Text = 'plus-large'; newCfgBtn.TextColor3 = Theme.Accent; newCfgBtn.TextSize = 14; newCfgBtn.Parent = newCfgRow

    local function xorEncode(data, key) 
        local out={} 
        for i=1,#data do out[i]=string.char(bit32.bxor(string.byte(data,i),string.byte(key,(i-1)%#key+1))) end 
        return table.concat(out) 
    end
    local XKEY = 'CandyLibKey'
    
    local function getConfigData() 
        local flags = {} 
        for name, obj in pairs(CandyLib.Flags) do 
            if obj.GetValue then 
                local v = obj:GetValue()
                if typeof(v)=='Color3' then v={__color=v:ToHex()} end
                flags[name]=v 
            end 
        end 
        return HttpService:JSONEncode(flags) 
    end
    local function setConfigData(raw) 
        local ok,tbl=pcall(function() return HttpService:JSONDecode(raw) end)
        if not ok or type(tbl)~='table' then return end
        for name,value in pairs(tbl) do 
            local obj=CandyLib.Flags[name]
            if obj and obj.SetValue then 
                if type(value)=='table' and value.__color then value=Color3.fromHex(value.__color) end
                pcall(function() obj:SetValue(value) end) 
            end 
        end 
    end

    local currentCfg = 'Default'
    local function refreshConfigs()
        for _, ch in ipairs(cfgScroll:GetChildren()) do if ch ~= newCfgRow and ch:IsA('Frame') then ch:Destroy() end end
        local files = {}; pcall(function() files = listfiles(Window.ConfigFolder) or {} end)
        for i, path in ipairs(files) do
            local name = path:sub(#Window.ConfigFolder+2)
            if name and name ~= '' then
                local row = Instance.new('Frame')
                row.BackgroundColor3 = Theme.PanelAlt; row.BackgroundTransparency = 1; row.Size = UDim2.new(1,-4,0,30); row.LayoutOrder = i; row.Parent = cfgScroll; Round(row, 8)
                
                local lbl = Instance.new('TextLabel')
                lbl.BackgroundTransparency = 1; lbl.Position = UDim2.new(0,8,0,0); lbl.Size = UDim2.new(1,-80,1,0); lbl.Font = Enum.Font.GothamMedium; lbl.Text = name; lbl.TextColor3 = Theme.Text; lbl.TextSize = 12; lbl.TextTransparency = 0.2; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
                
                local saveBtn = Instance.new('TextLabel')
                saveBtn.BackgroundTransparency = 1; saveBtn.AnchorPoint = Vector2.new(1,0.5); saveBtn.Position = UDim2.new(1,-32,0.5,0); saveBtn.Size = UDim2.fromOffset(22,22); saveBtn.FontFace = IconBold; saveBtn.Text = 'arrow-right-from-portrait-rectangle'; saveBtn.TextColor3 = Theme.TextMuted; saveBtn.TextSize = 12; saveBtn.Parent = row
                
                local delBtn = Instance.new('TextLabel')
                delBtn.BackgroundTransparency = 1; delBtn.AnchorPoint = Vector2.new(1,0.5); delBtn.Position = UDim2.new(1,-6,0.5,0); delBtn.Size = UDim2.fromOffset(22,22); delBtn.FontFace = IconBold; delBtn.Text = 'trash-can'; delBtn.TextColor3 = Theme.TextMuted; delBtn.TextSize = 12; delBtn.Parent = row
                
                CreateInput(row, function() 
                    local ok2, data = pcall(readfile, path)
                    if ok2 and data then 
                        pcall(function() setConfigData(xorEncode(data, XKEY)) end)
                        currentCfg = name; cfgLbl.Text = name
                        CandyLib:Notify({Title='Config', Content='Loaded '..name, Icon='folder'}) 
                    end 
                end)
                CreateInput(saveBtn, function() 
                    local enc = xorEncode(getConfigData(), XKEY)
                    pcall(writefile, path, enc)
                    CandyLib:Notify({Title='Config', Content='Saved '..name, Icon='floppy-disk'}) 
                end)
                CreateInput(delBtn, function() 
                    if name=='Default' then return end
                    pcall(delfile, path); refreshConfigs()
                    CandyLib:Notify({Title='Config', Content='Deleted '..name, Icon='trash-can'}) 
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
            cfgPopup.Position = UDim2.fromOffset(cfgBtn.AbsolutePosition.X + cfgBtn.AbsoluteSize.X - 220, cfgBtn.AbsolutePosition.Y + cfgBtn.AbsoluteSize.Y + 6)
            cfgPopup.Visible = true
            Tween(cfgPopup, TweenInfo.new(0.16), {BackgroundTransparency = 0.03}); Tween(cfgPopupStroke, TweenInfo.new(0.16), {Transparency = 0.55})
            task.spawn(function()
                while cfgPopupOpen do
                    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and not MouseOver(cfgPopup) and not MouseOver(cfgBtn) then
                        cfgPopupOpen = false
                        Tween(cfgPopup, TweenInfo.new(0.14), {BackgroundTransparency = 1}); Tween(cfgPopupStroke, TweenInfo.new(0.14), {Transparency = 1})
                        task.wait(0.15); cfgPopup.Visible = false
                    end
                    task.wait(0.05)
                end
            end)
        else
            Tween(cfgPopup, TweenInfo.new(0.14), {BackgroundTransparency = 1}); Tween(cfgPopupStroke, TweenInfo.new(0.14), {Transparency = 1})
            task.delay(0.15, function() if not cfgPopupOpen then cfgPopup.Visible = false end end)
        end
    end)
    CreateInput(newCfgBtn, function() 
        local name = newCfgInput.Text:gsub('[\\/]',''):sub(1,24)
        if name and name~='' then 
            local enc = xorEncode(getConfigData(), XKEY)
            pcall(writefile, Window.ConfigFolder..'/'..name, enc)
            currentCfg = name; cfgLbl.Text = name; newCfgInput.Text = ''; refreshConfigs()
            CandyLib:Notify({Title='Config', Content='Created '..name, Icon='folder'}) 
        end 
    end)
    
    task.delay(0.5, function()
        local path = Window.ConfigFolder..'/Default'
        if isfile(path) then local ok, data = pcall(readfile, path); if ok and data then pcall(function() setConfigData(xorEncode(data, XKEY)) end) end end
    end)
    task.spawn(function()
        while true do
            task.wait(15)
            local path = Window.ConfigFolder..'/Default'
            if currentCfg == 'Default' then local enc = xorEncode(getConfigData(), XKEY); pcall(writefile, path, enc) end
        end
    end)

    local sep = Instance.new('Frame')
    sep.BackgroundColor3 = Theme.BorderSoft; sep.BackgroundTransparency = 0.6; sep.Position = UDim2.new(0,16,0,52); sep.Size = UDim2.new(1,-32,0,1); sep.Parent = contentPanel
    
    local body = Instance.new('Frame')
    body.BackgroundTransparency = 1; body.Position = UDim2.new(0,10,0,56); body.Size = UDim2.new(1,-20,1,-64); body.Parent = contentPanel

    -- TABS (DOUBLE COLUMN SUPPORT)
    function Window:AddTab(tabCfg)
        local tab = { Name = tabCfg.Name }
        local btn = Instance.new('Frame')
        btn.BackgroundColor3 = Theme.PanelAlt; btn.BackgroundTransparency = 1; btn.Size = UDim2.fromOffset(44,44); btn.LayoutOrder = #self.Tabs+1; btn.Parent = tabList; Round(btn, 12)
        local bStroke = Stroke(btn, Theme.BorderSoft, 1)
        
        local ic = Instance.new('TextLabel')
        ic.BackgroundTransparency = 1; ic.Size = UDim2.fromScale(1,1); ic.FontFace = IconBold; ic.Text = tabCfg.Icon or 'crosshairs'; ic.TextColor3 = Theme.TextMuted; ic.TextSize = 20; ic.TextTransparency = 0.3; ic.Parent = btn
        
        local page = Instance.new('Frame')
        page.BackgroundTransparency = 1; page.Size = UDim2.fromScale(1,1); page.Visible = false; page.Parent = body
        
        local leftScroll = Instance.new('ScrollingFrame')
        leftScroll.BackgroundTransparency = 1; leftScroll.BorderSizePixel = 0; leftScroll.Size = UDim2.new(0.5,-5,1,0); leftScroll.Position = UDim2.new(0,0,0,0); leftScroll.ScrollBarThickness = 3; leftScroll.CanvasSize = UDim2.new(0,0,0,0); leftScroll.Parent = page
        local lList = Instance.new('UIListLayout')
        lList.SortOrder = Enum.SortOrder.LayoutOrder; lList.Padding = UDim.new(0,8); lList.Parent = leftScroll
        Track(lList:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function() leftScroll.CanvasSize = UDim2.new(0,0,lList.AbsoluteContentSize.Y+16,0) end))
        
        local rightScroll = Instance.new('ScrollingFrame')
        rightScroll.BackgroundTransparency = 1; rightScroll.BorderSizePixel = 0; rightScroll.Size = UDim2.new(0.5,-5,1,0); rightScroll.Position = UDim2.new(0.5,5,0,0); rightScroll.ScrollBarThickness = 3; rightScroll.CanvasSize = UDim2.new(0,0,0,0); rightScroll.Parent = page
        local rList = Instance.new('UIListLayout')
        rList.SortOrder = Enum.SortOrder.LayoutOrder; rList.Padding = UDim.new(0,8); rList.Parent = rightScroll
        Track(rList:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function() rightScroll.CanvasSize = UDim2.new(0,0,rList.AbsoluteContentSize.Y+16,0) end))

        if tabCfg.Type == 'Single' then rightScroll.Visible = false; leftScroll.Size = UDim2.new(1,0,1,0) end

        function tab:AddSection(name, side)
            local parentScroll = (side == 'Right' and rightScroll or leftScroll)
            if tabCfg.Type == 'Single' then parentScroll = leftScroll end
            local s = CreateSection(parentScroll, name)
            s.Root.LayoutOrder = #parentScroll:GetChildren()
            return s
        end
        
        function tab.Render(on) 
            if on then 
                Tween(btn, TweenInfo.new(0.16), {BackgroundTransparency = 0}); Tween(bStroke, TweenInfo.new(0.16), {Transparency = 0.35, Color = Theme.Accent}); Tween(ic, TweenInfo.new(0.16), {TextColor3 = Theme.Accent, TextTransparency = 0.05}); page.Visible = true 
            else 
                Tween(btn, TweenInfo.new(0.16), {BackgroundTransparency = 1}); Tween(bStroke, TweenInfo.new(0.16), {Transparency = 1, Color = Theme.BorderSoft}); Tween(ic, TweenInfo.new(0.16), {TextColor3 = Theme.TextMuted, TextTransparency = 0.3}); page.Visible = false 
            end 
        end
        
        CreateInput(btn, function() for i,t in ipairs(self.Tabs) do if t == tab then t.Render(true); self.Current = i else t.Render(false) end end end)
        table.insert(self.Tabs, tab)
        if #self.Tabs == 1 then tab.Render(true) else tab.Render(false) end
        return tab
    end

    Track(UserInputService.InputBegan:Connect(function(i,gp) if not gp and i.KeyCode.Name == (cfg.Keybind or 'Insert') then main.Visible = not main.Visible end end))
    return Window
end

-- ESP PREVIEW
function CandyLib:CreatePreview()
    local PreviewFrame = Instance.new('Frame')
    PreviewFrame.Name = CandyLib.RandomString(); PreviewFrame.AnchorPoint = Vector2.new(0.5,0.5); PreviewFrame.BackgroundColor3 = Theme.BG; PreviewFrame.BackgroundTransparency = 0.1; PreviewFrame.Position = UDim2.fromScale(0.8, 0.5); PreviewFrame.Size = UDim2.fromOffset(300, 400); PreviewFrame.Parent = CandyLib.ScreenGui; Round(PreviewFrame, 14); Stroke(PreviewFrame, Theme.Border, 0.5)
    
    local topBar = Instance.new('Frame')
    topBar.BackgroundTransparency = 1; topBar.Size = UDim2.new(1,0,0,30); topBar.Parent = PreviewFrame
    MakeDraggable(topBar, PreviewFrame)
    
    local title = Instance.new('TextLabel')
    title.BackgroundTransparency = 1; title.Position = UDim2.new(0,10,0,0); title.Size = UDim2.new(1,-40,1,0); title.Font = Enum.Font.GothamBold; title.Text = 'ESP Preview'; title.TextColor3 = Theme.Text; title.TextSize = 13; title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = topBar
    
    local closeBtn = Instance.new('TextLabel')
    closeBtn.BackgroundTransparency = 1; closeBtn.AnchorPoint = Vector2.new(1,0.5); closeBtn.Position = UDim2.new(1,-10,0.5,0); closeBtn.Size = UDim2.fromOffset(20,20); closeBtn.FontFace = IconBold; closeBtn.Text = 'x'; closeBtn.TextColor3 = Theme.TextMuted; closeBtn.TextSize = 14; closeBtn.Parent = topBar
    CreateInput(closeBtn, function() PreviewFrame.Visible = false end)

    local viewport = Instance.new('ViewportFrame')
    viewport.BackgroundColor3 = Theme.Panel; viewport.BackgroundTransparency = 0.5; viewport.Size = UDim2.new(1,-20,1,-40); viewport.Position = UDim2.new(0,10,0,30); viewport.Parent = PreviewFrame; Round(viewport, 10)
    
    local cam = Instance.new('Camera')
    cam.Parent = viewport; cam.CFrame = CFrame.new(0, 0, -5)
    
    local char = LocalPlayer.Character
    if char then
        local clone = char:Clone()
        clone.Parent = viewport
        for _, v in ipairs(clone:GetDescendants()) do
            if v:IsA('BasePart') then
                v.Anchored = true; v.CanCollide = false; v.Transparency = 0
            end
            if v:IsA('Humanoid') or v:IsA('Script') or v:IsA('LocalScript') then v:Destroy() end
        end
        local hrp = clone:FindFirstChild('HumanoidRootPart')
        if hrp then
            clone.PrimaryPart = hrp
            for _, v in ipairs(clone:GetDescendants()) do
                if v:IsA('BasePart') then v.CFrame = v.CFrame - hrp.CFrame.Position end
            end
        end
        task.spawn(function()
            while PreviewFrame.Parent do
                task.wait(0.03)
                if clone.PrimaryPart then
                    clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(1), 0))
                end
            end
        end)
    end

    local espBox = Instance.new('Frame')
    espBox.BackgroundTransparency = 1; espBox.AnchorPoint = Vector2.new(0.5,0.5); espBox.Position = UDim2.fromScale(0.5,0.5); espBox.Size = UDim2.fromOffset(120,200); espBox.Parent = viewport
    Stroke(espBox, Color3.fromRGB(255,255,255), 0, 1)
    
    local nameTag = Instance.new('TextLabel')
    nameTag.BackgroundTransparency = 1; nameTag.Position = UDim2.new(0.5,0,-20,0); nameTag.AnchorPoint = Vector2.new(0.5,1); nameTag.Size = UDim2.new(1,0,20,0); nameTag.Font = Enum.Font.GothamBold; nameTag.Text = LocalPlayer.Name; nameTag.TextColor3 = Color3.new(1,1,1); nameTag.TextSize = 12; nameTag.Parent = espBox
    
    local healthBg = Instance.new('Frame')
    healthBg.BackgroundColor3 = Color3.new(0,0,0); healthBg.BackgroundTransparency = 0.5; healthBg.AnchorPoint = Vector2.new(1,0); healthBg.Position = UDim2.new(-0.1,0,0,0); healthBg.Size = UDim2.new(0,4,1,0); healthBg.Parent = espBox; Round(healthBg, 2)
    
    local healthFill = Instance.new('Frame')
    healthFill.BackgroundColor3 = Color3.fromRGB(100,255,100); healthFill.Size = UDim2.new(1,0,0.8,0); healthFill.Parent = healthBg; Round(healthFill, 2)

    return PreviewFrame
end

getgenv().CandyLib = CandyLib
return CandyLib
