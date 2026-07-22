-- rgnMultitool 1.4.0
local RGN_MULTITOOL_VERSION = "1.4.0"
local RGN_MULTITOOL_SIGNATURE = "RGN_MULTITOOL_SOURCE_V1"
_G.RGN_MULTITOOL_VERSION = RGN_MULTITOOL_VERSION

local staleEvents = { "Draw", "CreateMove", "PreMove", "DrawESP", "FireGameEvent", "Unload" }
local function clearCallbacks(ids)
    for _, id in ipairs(ids) do
        for _, event in ipairs(staleEvents) do
            pcall(callbacks.Unregister, event, id)
        end
    end
end

clearCallbacks({
    "rgnMultitool_Watermark", "rgnMultitool_MISCLogic",
    "rgnMultitool_MISCLogicMove", "rgnMultitool_MISCEvents",
    "rgnMultitool_WeaponsSessionEvents", "rgnMultitool_GameEvents",
    "rgnMultitool_GameEventsUnload", "rgnMultitool_MISCUnload"
})
if type(M) == "table" and type(M.Watermark) == "function" then
    pcall(M.Watermark, M, false)
end

if type(UnloadScript) == "function" then
    pcall(UnloadScript, "rgnSkins.lua")
    pcall(UnloadScript, "rgnMisc.lua")
    pcall(UnloadScript, "rgnWEAPONS.lua")
    pcall(UnloadScript, "manual_aa.lua")
    pcall(UnloadScript, "whitelist.lua")
end

clearCallbacks({
    "rgnSkins_UIDraw", "rgnSkins_UIInput", "rgnSkins_UIUnload",
    "rgnSkins_StableEvents", "rgnSkins_SpawnWatch", "rgnSkins_SetModelUnload",
    "rgnMISC_UIDraw", "rgnMISC_UIInput", "rgnMISC_UIUnload",
    "rgnMISC_Logic", "rgnMISC_Events", "rgnMISC_Unload",
    "rgnWEAPONS_UIDraw", "rgnWEAPONS_UIInput", "rgnWEAPONS_UIUnload",
    "rgnWEAPONS_Engine", "rgnWEAPONS_Unload", "rgnWEAPONS_Watermark",
    "rgnWEAPONS_LateMesh",
    "rgnMultitool_ManualAADraw", "rgnMultitool_ManualAAMove",
    "rgnMultitool_ManualAAUnload", "rgnMultitool_WhitelistRefresh",
    "rgnMultitool_WhitelistESP", "rgnMultitool_WhitelistUnload",
    "rgnMultitool_RegionDraw", "rgnMultitool_RegionUnload"
})

local __RGN_GUILIB = [===[
local M = {}
M.VERSION = "1.0"

local T = {
    x = 360, y = 200, w = 600, h = 440,

    accent    = { 74, 166, 255 },
    accent2   = { 107, 219, 255, 255 },
    accent_bg = { 20, 43, 68, 255 },
    bg        = { 8, 10, 14, 252 },
    bg2       = { 11, 14, 19, 252 },
    section   = { 15, 19, 26, 252 },
    border    = { 40, 48, 61, 255 },
    divider   = { 29, 36, 47, 255 },
    text      = { 205, 213, 225, 255 },
    textdim   = { 119, 132, 150, 255 },
    texthi    = { 247, 249, 255, 255 },
    widget    = { 19, 25, 34, 255 },
    widgethi  = { 26, 36, 48, 255 },
    shadow    = { 0, 0, 0, 115 },

    title     = "rgn",
    title_tld = "MULTITOOL",
    titlebar  = 58,
    pad       = 18,
    sec_gap   = 16,

    font      = { "Segoe UI", "Bahnschrift", "Tahoma" },
    font_logo = { "Bahnschrift", "Segoe UI Semibold", "Segoe UI" },
    font_size = 14,

    notif_pos    = "bottom-right",
    notif_w      = 290,
    notif_margin = 18,
    notif_life   = 3.5,
    notif_info    = { 230, 230, 235 },
    notif_success = { 170, 220, 185 },
    notif_error   = { 235, 90, 90 },
}

local WH = { check = 28, button = 36, slider = 36, combo = 52, multicombo = 52, input = 52, color = 28, keybox = 52 }
local function wheight(wd)
    if wd.kind == "listbox" then
        return ((wd.label and wd.label ~= "") and 18 or 0) + wd.h + 6
    end
    if wd.kind == "custom" then return wd._measured or wd.h end
    return WH[wd.kind] or 28
end

local ANIM = { open = 13, tab = 17 }

local floor, sqrt, mmin, mmax, mabs = math.floor, math.sqrt, math.min, math.max, math.abs
local function rnd(n) return floor(n + 0.5) end
local function clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi else return v end end
local function smooth(t) t = clamp(t, 0, 1); return t * t * (3 - 2 * t) end

local function decimalsOf(step)
    if not step or step >= 1 then return 0 end
    local d, s = 0, step
    while s < 1 and d < 6 do
        s = s * 10; d = d + 1
        if mabs(s - floor(s + 0.5)) < 1e-7 then break end
    end
    return d
end

local ALPHA = 1
local DT = 0
local clipTop, clipBottom

local function approach(cur, target, speed)
    return cur + (target - cur) * clamp(DT * speed, 0, 1)
end

local function lerpc(a, b, t)
    t = clamp(t, 0, 1)
    return {
        a[1] + (b[1] - a[1]) * t,
        a[2] + (b[2] - a[2]) * t,
        a[3] + (b[3] - a[3]) * t,
        (a[4] or 255) + ((b[4] or 255) - (a[4] or 255)) * t,
    }
end

local ffi = ffi

local FONT, FONT_B, FONT_LOGO
local function initFonts()
    local mk = function(list, size, weight)
        for _, name in ipairs(list) do
            local f
            pcall(function() f = draw.CreateFont(name, size, weight) end)
            if not f then pcall(function() f = draw.AddFont(name, size, weight) end) end
            if f then return f, name end
        end
    end
    FONT              = mk(T.font, T.font_size, 400)
    FONT_B            = mk(T.font, T.font_size, 600)
    FONT_LOGO         = mk(T.font_logo, T.font_size + 2, 700) or FONT_B
end

local function setcol(c) draw.Color(c[1], c[2], c[3], rnd((c[4] or 255) * ALPHA)) end

local function rect(x, y, w, h, c)
    setcol(c); draw.FilledRect(rnd(x), rnd(y), rnd(x + w), rnd(y + h))
end

local function drawLogo(x, y, w, h)
    local ok = pcall(function()
        if FONT_LOGO then draw.SetFont(FONT_LOGO) end
        local label = "RGN"
        local tw, th = draw.GetTextSize(label)
        -- This runs before the rounded-box helpers are declared.  Keep the
        -- wordmark self-contained so it cannot silently fail during startup.
        draw.Color(T.texthi[1], T.texthi[2], T.texthi[3], rnd(255 * ALPHA))
        draw.Text(rnd(x + (w - tw) * 0.5), rnd(y + (h - th) * 0.5 - 1), label)
        draw.Color(T.accent[1], T.accent[2], T.accent[3], rnd(235 * ALPHA))
        draw.FilledRect(rnd(x), rnd(y + h - 2), rnd(x + w), rnd(y + h))
    end)
    return ok
end

local function rfill(x, y, w, h, r, c, tl, tr, br, bl)
    x, y, w, h = rnd(x), rnd(y), rnd(w), rnd(h)
    r = mmin(r, floor(w / 2), floor(h / 2))
    if r <= 0 then rect(x, y, w, h, c); return end
    if tl == nil then tl, tr, br, bl = true, true, true, true end
    rect(x, y + r, w, h - 2 * r, c)
    for dy = 0, r - 1 do
        local dx = r - floor(sqrt(r * r - (r - dy - 0.5) ^ 2) + 0.5)
        local lt, rt = tl and dx or 0, tr and dx or 0
        local lb, rb = bl and dx or 0, br and dx or 0
        rect(x + lt, y + dy, w - lt - rt, 1, c)
        rect(x + lb, y + h - 1 - dy, w - lb - rb, 1, c)
    end
end

local function rbox(x, y, w, h, r, fill, brd)
    rfill(x, y, w, h, r, brd)
    rfill(x + 1, y + 1, w - 2, h - 2, r - 1, fill)
end

local function frame(x, y, w, h, c)
    rect(x, y, w, 1, c); rect(x, y + h - 1, w, 1, c)
    rect(x, y, 1, h, c); rect(x + w - 1, y, 1, h, c)
end

local function rgb2hsv(r, g, b)
    r, g, b = r / 255, g / 255, b / 255
    local mx, mn = mmax(r, g, b), mmin(r, g, b)
    local v, d = mx, mx - mn
    local s = mx == 0 and 0 or d / mx
    local h = 0
    if d ~= 0 then
        if mx == r then h = ((g - b) / d) % 6
        elseif mx == g then h = (b - r) / d + 2
        else h = (r - g) / d + 4 end
        h = h / 6; if h < 0 then h = h + 1 end
    end
    return h, s, v
end

local function hsv2rgb(h, s, v)
    local i = floor(h * 6) % 6
    local f = h * 6 - floor(h * 6)
    local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
    local r, g, b
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    else r, g, b = v, p, q end
    return rnd(r * 255), rnd(g * 255), rnd(b * 255)
end

local function textw(s) local w = draw.GetTextSize(s); return w or 0 end

local function fitText(s, maxWidth, font)
    s = tostring(s or "")
    if font then pcall(function() draw.SetFont(font) end) end
    if textw(s) <= maxWidth then return s end
    local suffix = "..."
    local available = mmax(0, maxWidth - textw(suffix))
    local lo, hi, best = 0, #s, 0
    while lo <= hi do
        local mid = floor((lo + hi) / 2)
        if textw(s:sub(1, mid)) <= available then best = mid; lo = mid + 1
        else hi = mid - 1 end
    end
    return s:sub(1, best) .. suffix
end

local function text(x, y, c, s, font, align)
    if font then draw.SetFont(font) end
    if align == "center" then x = x - textw(s) / 2
    elseif align == "right" then x = x - textw(s) end
    setcol(c); draw.Text(rnd(x), rnd(y), s)
end

local _getMouse
local function resolveMouse()
    local cands = {
        function() local p = input.GetMousePos();    return p.x or p[1], p.y or p[2] end,
        function() local p = input.GetCursorPos();    return p.x or p[1], p.y or p[2] end,
        function() local x, y = input.GetMousePos();  return x, y end,
        function() local x, y = input.GetCursorPos(); return x, y end,
    }
    for _, f in ipairs(cands) do
        local ok, x, y = pcall(f)
        if ok and type(x) == "number" and type(y) == "number" then return f end
    end
end

local _clock
local function resolveClock()
    local cands = {
        function() return globals.RealTime() end,
        function() return globals.CurTime() end,
        function() return os.clock() end,
    }
    for _, f in ipairs(cands) do
        local ok, v = pcall(f)
        if ok and type(v) == "number" then return f end
    end
end
local function now() if _clock then local ok, v = pcall(_clock); if ok then return v end end return 0 end

local _getWheel
local function resolveWheel()
    local cands = {
        function() return input.GetMouseWheel() end,
        function() return input.GetMouseWheelDelta() end,
        function() return input.GetScrollDelta() end,
        function() return input.GetScroll() end,
    }
    for _, f in ipairs(cands) do
        local ok, v = pcall(f)
        if ok and type(v) == "number" then return f end
    end
end
local function readWheel() if _getWheel then local ok, v = pcall(_getWheel); if ok and type(v) == "number" then return v end end return 0 end

local SHIFT_DIGITS = { [0x30] = ")", [0x31] = "!", [0x32] = "@", [0x33] = "#", [0x34] = "$",
                       [0x35] = "%", [0x36] = "^", [0x37] = "&", [0x38] = "*", [0x39] = "(" }
local OEM = {
    [0xBA] = { ";", ":" }, [0xBB] = { "=", "+" }, [0xBC] = { ",", "<" }, [0xBD] = { "-", "_" },
    [0xBE] = { ".", ">" }, [0xBF] = { "/", "?" }, [0xC0] = { "`", "~" }, [0xDB] = { "[", "{" },
    [0xDC] = { "\\", "|" }, [0xDD] = { "]", "}" }, [0xDE] = { "'", '"' },
}
local function keyPressed(k) local v = false; pcall(function() v = input.IsButtonPressed(k) end); return v end
local function keyDown(k)    local v = false; pcall(function() v = input.IsButtonDown(k)  end); return v end

pcall(function() ffi.cdef[[
    int    OpenClipboard(void*);
    int    CloseClipboard(void);
    int    EmptyClipboard(void);
    void*  GetClipboardData(unsigned int);
    void*  SetClipboardData(unsigned int, void*);
    void*  GlobalAlloc(unsigned int, size_t);
    void*  GlobalLock(void*);
    int    GlobalUnlock(void*);
]] end)

local function clipGet()
    local out
    pcall(function()
        if ffi.C.OpenClipboard(nil) == 0 then return end
        local h = ffi.C.GetClipboardData(1)
        if h ~= nil then
            local p = ffi.C.GlobalLock(h)
            if p ~= nil then out = ffi.string(ffi.cast("char*", p)); ffi.C.GlobalUnlock(h) end
        end
        ffi.C.CloseClipboard()
    end)
    if out then out = out:gsub("[\r\n\t]", "") end
    return out
end

local function clipSet(s)
    s = tostring(s or "")
    pcall(function()
        if ffi.C.OpenClipboard(nil) == 0 then return end
        ffi.C.EmptyClipboard()
        local n = #s + 1
        local h = ffi.C.GlobalAlloc(2, n)
        if h ~= nil then
            local p = ffi.C.GlobalLock(h)
            if p ~= nil then
                local dst = ffi.cast("char*", p)
                for i = 0, n - 1 do dst[i] = (i < #s) and s:byte(i + 1) or 0 end
                ffi.C.GlobalUnlock(h)
                ffi.C.SetClipboardData(1, h)
            end
        end
        ffi.C.CloseClipboard()
    end)
end

local _kr = {}
local REPEAT_DELAY, REPEAT_RATE = 0.40, 0.035
local function keyRepeat(k, t)
    if not keyDown(k) then _kr[k] = nil; return false end
    local s = _kr[k]
    if not s then _kr[k] = { first = t, last = t }; return true end
    if (t - s.first) >= REPEAT_DELAY and (t - s.last) >= REPEAT_RATE then s.last = t; return true end
    return false
end

local function selBounds(wd)
    local c = wd._caret or #wd.value
    local a = wd._anchor or c
    if a > c then a, c = c, a end
    return a, c
end
local function hasSel(wd) return (wd._anchor or wd._caret or 0) ~= (wd._caret or 0) end
local function delSel(wd)
    local a, b = selBounds(wd)
    if a == b then return false end
    wd.value = wd.value:sub(1, a) .. wd.value:sub(b + 1)
    wd._caret = a; wd._anchor = a
    return true
end

local function inputView(wd, avail)
    local v, n = wd.value, #wd.value
    local caret = clamp(wd._caret or n, 0, n); wd._caret = caret
    if wd._anchor then wd._anchor = clamp(wd._anchor, 0, n) end
    local off = clamp(wd._off or 0, 0, n)
    if caret < off then off = caret end
    while off < caret and textw(v:sub(off + 1, caret)) > avail do off = off + 1 end
    local e = n
    while e > off and textw(v:sub(off + 1, e)) > avail do e = e - 1 end
    if e < caret then e = caret end
    wd._off = off
    return v:sub(off + 1, e), off, e
end

local function caretFromX(wd, relx, off)
    local v, n = wd.value, #wd.value
    if relx <= 0 then return off end
    for i = off + 1, n do
        local w = textw(v:sub(off + 1, i))
        if w >= relx then
            local wp = textw(v:sub(off + 1, i - 1))
            return ((relx - wp) < (w - relx)) and (i - 1) or i
        end
    end
    return n
end

local function pollText(wd, t)
    local ctrl  = keyDown(0x11)
    local shift = keyDown(0x10)
    local n = #wd.value
    wd._caret  = clamp(wd._caret or n, 0, n)
    wd._anchor = wd._anchor and clamp(wd._anchor, 0, n) or wd._caret

    if ctrl then
        if keyPressed(0x41) then wd._anchor = 0; wd._caret = n end
        if keyPressed(0x43) then local a, b = selBounds(wd); clipSet(a ~= b and wd.value:sub(a + 1, b) or wd.value) end
        if keyPressed(0x58) then
            local a, b = selBounds(wd)
            if a ~= b then clipSet(wd.value:sub(a + 1, b)); delSel(wd)
            else clipSet(wd.value); wd.value = ""; wd._caret = 0; wd._anchor = 0 end
        end
        if keyPressed(0x56) then
            local s = clipGet()
            if s then
                delSel(wd)
                local c = wd._caret
                wd.value = wd.value:sub(1, c) .. s .. wd.value:sub(c + 1)
                wd._caret = c + #s; wd._anchor = wd._caret
            end
        end
        return
    end

    local function move(to)
        wd._caret = clamp(to, 0, #wd.value)
        if not shift then wd._anchor = wd._caret end
    end
    local function ins(ch)
        delSel(wd)
        local c = wd._caret
        wd.value = wd.value:sub(1, c) .. ch .. wd.value:sub(c + 1)
        wd._caret = c + 1; wd._anchor = wd._caret
    end

    if keyRepeat(0x25, t) then
        local a, b = selBounds(wd)
        if not shift and a ~= b then wd._caret = a; wd._anchor = a else move(wd._caret - 1) end
    end
    if keyRepeat(0x27, t) then
        local a, b = selBounds(wd)
        if not shift and a ~= b then wd._caret = b; wd._anchor = b else move(wd._caret + 1) end
    end
    if keyPressed(0x24) then move(0) end
    if keyPressed(0x23) then move(#wd.value) end

    if keyRepeat(0x08, t) then
        if not delSel(wd) then
            local c = wd._caret
            if c > 0 then wd.value = wd.value:sub(1, c - 1) .. wd.value:sub(c + 1); wd._caret = c - 1; wd._anchor = c - 1 end
        end
    end
    if keyRepeat(0x2E, t) then
        if not delSel(wd) then
            local c = wd._caret
            if c < #wd.value then wd.value = wd.value:sub(1, c) .. wd.value:sub(c + 2) end
        end
    end

    if keyRepeat(0x20, t) then ins(" ") end
    for k = 0x41, 0x5A do
        if keyRepeat(k, t) then local ch = string.char(k); ins(shift and ch or ch:lower()) end
    end
    for k = 0x30, 0x39 do
        if keyRepeat(k, t) then ins(shift and SHIFT_DIGITS[k] or string.char(k)) end
    end
    for k, pair in pairs(OEM) do
        if keyRepeat(k, t) then ins(shift and pair[2] or pair[1]) end
    end
    if keyPressed(0x0D) or keyPressed(0x1B) then M._focus = nil end
end

local ms = { x = 0, y = 0, down = false, pressed = false, released = false, consumed = false }
local function updateMouse()
    if _getMouse then
        local ok, x, y = pcall(_getMouse)
        if ok then ms.x, ms.y = x or ms.x, y or ms.y end
    end
    local down = false
    pcall(function() down = input.IsButtonDown(0x01) and true or false end)
    ms.pressed  = down and not ms.down
    ms.released = (not down) and ms.down
    ms.down     = down
    ms.consumed = false
    ms.wheel    = readWheel()
end

local function hovering(x, y, w, h)
    return ms.x >= x and ms.x <= x + w and ms.y >= y and ms.y <= y + h
end

local function clicked(x, y, w, h)
    if ms.consumed or not ms.pressed then return false end
    if hovering(x, y, w, h) then ms.consumed = true; return true end
    return false
end

local function handle(w)
    return {
        Get = function() return w.value end,
        Set = function(_, v) w.value = v end,
    }
end

local UI = {
    T = T, now = now, clamp = clamp, lerp = lerpc,
    rect  = function(x, y, w, h, c) rect(x, y, w, h, c) end,
    rfill = function(x, y, w, h, r, c) rfill(x, y, w, h, r, c) end,
    rbox  = function(x, y, w, h, r, f, b) rbox(x, y, w, h, r, f, b or T.border) end,
    text  = function(x, y, s, col, align) text(x, y, col or T.text, tostring(s), FONT, align) end,
    title = function(x, y, s, col, align) text(x, y, col or T.texthi, tostring(s), FONT_B, align) end,
    textw = function(s) return textw(tostring(s)) end,
    hover = function(x, y, w, h) return hovering(x, y, w, h) end,
    click = function(x, y, w, h) return clicked(x, y, w, h) end,
    mouse = function() return ms.x, ms.y, ms.down end,
    screen = function() local w, h = 0, 0; pcall(function() w, h = draw.GetScreenSize() end); return w, h end,
}

local IM = {}
UI._x, UI._cy, UI._w = 0, 0, 200
UI.layout = function(x, y, w) UI._x = x; UI._cy = y; if w then UI._w = w end end

local Section = {}
Section.__index = Section

function Section.new(title) return setmetatable({ title = title, ws = {} }, Section) end

function Section:_add(w) self.ws[#self.ws + 1] = w; return handle(w) end

function Section:Checkbox(label, def)
    return self:_add({ kind = "check", label = label, value = def and true or false })
end

function Section:Button(label, cb)
    return self:_add({ kind = "button", label = label, cb = cb })
end

function Section:Slider(label, def, mn, mx, step, fmt)
    step = step or 1
    return self:_add({ kind = "slider", label = label, value = def, min = mn, max = mx,
                       step = step, dec = decimalsOf(step), fmt = fmt })
end

function Section:SliderFloat(label, def, mn, mx, fmt, step)
    return self:Slider(label, def, mn, mx, step or 0.01, fmt)
end

function Section:Combo(label, options, def)
    return self:_add({ kind = "combo", label = label, options = options, value = def or 1 })
end

function Section:MultiCombo(label, options, defaults)
    local sel = {}
    if defaults then for _, i in ipairs(defaults) do sel[i] = true end end
    return self:_add({ kind = "multicombo", label = label, options = options, value = sel })
end

function Section:Input(label, def, placeholder)
    return self:_add({ kind = "input", label = label, value = def or "", placeholder = placeholder })
end

function Section:ColorPicker(label, col)
    col = col or { 255, 255, 255, 255 }
    return self:_add({ kind = "color", label = label, value = { col[1], col[2], col[3], col[4] or 255 } })
end

function Section:Keybox(label, def)
    return self:_add({ kind = "keybox", label = label, value = tonumber(def) or 0 })
end

function Section:Listbox(label, items, height, def)
    local fill = (height == "fill")
    if fill then self._hasFill = true end
    return self:_add({ kind = "listbox", label = label, items = items or {}, value = def or 1,
                       h = fill and 120 or (height or 200), fill = fill, scroll = 0 })
end

function Section:Custom(height, fn)
    return self:_add({ kind = "custom", h = height or 60, fn = fn })
end

function Section:height()
    local h = 42 + 10
    for _, wd in ipairs(self.ws) do h = h + wheight(wd) end
    return h
end

function Section:render(x, y, w)
    -- Layout height: explicit row stretch (_layoutH), else natural.
    -- Fill-to-window only when NOT in a measured row (auto-pack / Skins),
    -- so Row() siblings cannot inflate and push later panels off-screen.
    local natural = self:height()
    local h = natural
    if self._layoutH then
        h = mmax(natural, self._layoutH)
    elseif self._hasFill and clipBottom then
        local fh = (clipBottom - 12) - y
        if fh > h then h = fh end
    end

    if clipBottom and y >= clipBottom then return h end
    if clipTop and (y + h) <= clipTop then return h end

    local boxH = h
    if clipBottom and (y + boxH) > clipBottom then
        boxH = mmax(0, clipBottom - y)
    end
    if boxH > 0 and (not clipTop or y + boxH > clipTop) then
        local drawY = y
        local drawH = boxH
        if clipTop and drawY < clipTop then
            drawH = drawH - (clipTop - drawY)
            drawY = clipTop
        end
        if drawH > 0 then
            rbox(x, drawY, w, drawH, 10, T.section, T.border)
            rfill(x + 1, drawY + 1, w - 2, 1, 9, { T.accent[1], T.accent[2], T.accent[3], 50 })
        end
        if (not clipTop or y + 26 > clipTop) and (not clipBottom or y + 12 < clipBottom) then
            rfill(x + 14, y + 12, 3, 14, 1, T.accent)
            text(x + 23, y + 12, T.texthi, self.title, FONT_B)
            if (not clipBottom or y + 33 < clipBottom) and (not clipTop or y + 34 > clipTop) then
                rect(x + 14, y + 33, w - 28, 1, T.divider)
            end
        end
    end

    local iy = y + 44
    local ix = x + 14
    local iw = w - 28
    for _, wd in ipairs(self.ws) do
        local wh
        if wd.kind == "listbox" and wd.fill then
            local labelH = (wd.label and wd.label ~= "") and 18 or 0
            local remain = (y + h - 12) - (iy + labelH)
            wd._fillH = mmax(wd.h or 120, remain)
            wh = labelH + wd._fillH + 6
        else
            wh = wheight(wd)
        end
        local visible = true
        if clipBottom and iy >= clipBottom then visible = false end
        if clipTop and (iy + wh) <= clipTop then visible = false end
        if visible then
            self:_widget(wd, ix, iy, iw)
        end
        iy = iy + wh
        if clipBottom and iy >= clipBottom then break end
    end
    return h
end

local KEYBOX_NAMES = {
    [0x00] = "None", [0x01] = "Mouse1", [0x02] = "Mouse2", [0x04] = "Mouse3",
    [0x05] = "Mouse4", [0x06] = "Mouse5", [0x08] = "Backspace", [0x09] = "Tab",
    [0x0D] = "Enter", [0x10] = "Shift", [0x11] = "Ctrl", [0x12] = "Alt",
    [0x1B] = "Escape", [0x20] = "Space", [0x21] = "Page Up", [0x22] = "Page Down",
    [0x23] = "End", [0x24] = "Home", [0x25] = "Left", [0x26] = "Up",
    [0x27] = "Right", [0x28] = "Down", [0x2D] = "Insert", [0x2E] = "Delete",
}
local function keyboxName(code)
    code = tonumber(code) or 0
    if KEYBOX_NAMES[code] then return KEYBOX_NAMES[code] end
    if code >= 0x30 and code <= 0x39 then return string.char(code) end
    if code >= 0x41 and code <= 0x5A then return string.char(code) end
    if code >= 0x70 and code <= 0x7B then return "F" .. tostring(code - 0x6F) end
    return code > 0 and string.format("VK 0x%02X", code) or "None"
end
function Section:_widget(wd, x, y, w)
    if wd.kind == "check" then
        local box = 15
        local by  = y + 1
        local hov = hovering(x, by, w, box)
        wd._h  = approach(wd._h or 0, hov and 1 or 0, 16)
        wd._on = approach(wd._on or 0, wd.value and 1 or 0, 16)
        local fill = lerpc(lerpc(T.widget, T.widgethi, wd._h), T.accent, wd._on)
        rbox(x, by, box, box, 4, fill, lerpc(T.border, T.accent, wd._on))
        text(x + box + 9, y + 2, lerpc(T.text, T.texthi, mmax(wd._h, wd._on)), wd.label, FONT)
        if clicked(x, by, w, box) then wd.value = not wd.value end

    elseif wd.kind == "button" then
        local bh  = 22
        local hov = hovering(x, y + 1, w, bh)
        wd._h = approach(wd._h or 0, hov and 1 or 0, 16)
        rbox(x, y + 1, w, bh, 6, lerpc(T.widget, T.widgethi, wd._h), lerpc(T.border, T.accent, wd._h * 0.55))
        local buttonText = fitText(wd.label, mmax(20, w - 18), FONT)
        text(x + w / 2, y + 6, lerpc(T.text, T.texthi, wd._h), buttonText, FONT, "center")
        if clicked(x, y + 1, w, bh) then
            local ok, err = pcall(wd.cb); if not ok then print("[rgnMultitool] button error: " .. tostring(err)) end
        end

    elseif wd.kind == "slider" then
        local active = (M._slider == wd)
        wd._h = approach(wd._h or 0, (active or hovering(x, y + 18 - 6, w, 18)) and 1 or 0, 16)
        text(x, y, lerpc(T.text, T.texthi, wd._h), wd.label, FONT)
        local valstr
        if wd.fmt then valstr = string.format(wd.fmt, wd.value)
        elseif wd.dec > 0 then valstr = string.format("%." .. wd.dec .. "f", wd.value)
        else valstr = tostring(rnd(wd.value)) end
        text(x + w, y, T.texthi, valstr, FONT, "right")
        local ty, th = y + 18, 6
        local frac = clamp((wd.value - wd.min) / (wd.max - wd.min), 0, 1)
        rbox(x, ty, w, th, 3, lerpc(T.widget, T.widgethi, wd._h), T.border)
        if frac > 0 then rfill(x, ty, mmax(th, w * frac), th, 3, T.accent, true, false, false, true) end
        if ms.pressed and not ms.consumed and hovering(x, ty - 6, w, th + 12) then
            ms.consumed = true; M._slider = wd
        end
        if active then
            if ms.down and w > 0 then
                local raw = wd.min + clamp((ms.x - x) / w, 0, 1) * (wd.max - wd.min)
                if raw ~= raw then raw = wd.min end
                local v = wd.min + floor((raw - wd.min) / wd.step + 0.5) * wd.step
                v = clamp(v, wd.min, wd.max)
                if wd.dec > 0 then v = tonumber(string.format("%." .. wd.dec .. "f", v)) or v end
                wd.value = v
            elseif not ms.down then
                M._slider = nil
            end
        end

    elseif wd.kind == "combo" then
        local by, bh = y + 18, 22
        local open = (M._combo == wd)
        local hov  = hovering(x, by, w, bh)
        wd._h = approach(wd._h or 0, (hov or open) and 1 or 0, 16)
        text(x, y, lerpc(T.text, T.texthi, wd._h), wd.label, FONT)
        rbox(x, by, w, bh, 5, lerpc(T.widget, T.widgethi, wd._h), open and T.accent or T.border)
        local shown = wd.options[wd.value] or "?"
        local selectedColor = wd.optionColors and wd.optionColors[wd.value]
        local suffix = wd.optionSuffixes and wd.optionSuffixes[wd.value]
        local normalColor = open and T.texthi or lerpc(T.text, T.texthi, wd._h)
        local available = mmax(20, w - 28)
        if suffix and selectedColor and shown:sub(-#suffix) == suffix then
            local prefix = fitText(shown:sub(1, #shown - #suffix), mmax(0, available - textw(suffix)), FONT)
            text(x + 9, by + 5, normalColor, prefix, FONT)
            text(x + 9 + textw(prefix), by + 5, selectedColor, suffix, FONT)
        else
            text(x + 9, by + 5, normalColor, fitText(shown, available, FONT), FONT)
        end
        text(x + w - 16, by + 5, open and T.accent or T.textdim, open and "-" or "v", FONT)
        if clicked(x, by, w, bh) then M._combo = open and nil or wd end
        if M._combo == wd then M._dd = { wd = wd, x = x, y = by + bh, w = w, bh = bh } end

    elseif wd.kind == "multicombo" then
        local by, bh = y + 18, 22
        local open = (M._combo == wd)
        local hov  = hovering(x, by, w, bh)
        wd._h = approach(wd._h or 0, (hov or open) and 1 or 0, 16)
        text(x, y, lerpc(T.text, T.texthi, wd._h), wd.label, FONT)
        rbox(x, by, w, bh, 5, lerpc(T.widget, T.widgethi, wd._h), open and T.accent or T.border)
        local parts, count = {}, 0
        for i, o in ipairs(wd.options) do if wd.value[i] then count = count + 1; parts[#parts + 1] = o end end
        local shown = count == 0 and "None" or (count > 2 and (count .. " selected") or table.concat(parts, ", "))
        shown = fitText(shown, mmax(20, w - 28), FONT)
        text(x + 9, by + 5, open and T.texthi or lerpc(T.text, T.texthi, wd._h), shown, FONT)
        text(x + w - 16, by + 5, open and T.accent or T.textdim, open and "-" or "v", FONT)
        if clicked(x, by, w, bh) then M._combo = open and nil or wd end
        if M._combo == wd then M._dd = { wd = wd, x = x, y = by + bh, w = w, bh = bh } end

    elseif wd.kind == "input" then
        local by, bh = y + 18, 22
        local focused = (M._focus == wd)
        local hov = hovering(x, by, w, bh)
        wd._h = approach(wd._h or 0, (hov or focused) and 1 or 0, 16)
        text(x, y, lerpc(T.text, T.texthi, wd._h), wd.label, FONT)
        rbox(x, by, w, bh, 5, lerpc(T.widget, T.widgethi, wd._h), focused and T.accent or T.border)
        local pad, avail = 9, w - 16
        local tx, ty = x + pad, by + 5
        if wd.value ~= "" or focused then
            local vis, off = inputView(wd, avail)
            if focused then
                local a, b = selBounds(wd)
                if a ~= b then
                    local va, vb = clamp(a, off, off + #vis), clamp(b, off, off + #vis)
                    local sx = textw(wd.value:sub(off + 1, va))
                    local sw = textw(wd.value:sub(off + 1, vb)) - sx
                    if sw > 0 then rfill(tx + sx - 1, by + 4, mmin(sw + 2, avail), bh - 8, 3, { T.accent[1], T.accent[2], T.accent[3], 110 }) end
                end
            end
            text(tx, ty, focused and T.texthi or T.text, vis, FONT)
            if focused and not hasSel(wd) and (floor(now() * 1.6) % 2 == 0) then
                rfill(tx + textw(wd.value:sub(off + 1, wd._caret)), by + 4, 1, bh - 8, 0, T.accent)
            end
        else
            text(tx, ty, T.textdim, wd.placeholder or "", FONT)
        end
        if ms.pressed and not ms.consumed and hovering(x, by, w, bh) then
            ms.consumed = true; M._focus = wd
            local c = caretFromX(wd, ms.x - tx, wd._off or 0)
            wd._caret, wd._anchor, M._inputDrag = c, c, wd
        end
        if M._inputDrag == wd then
            if ms.down and M._focus == wd then wd._caret = caretFromX(wd, ms.x - tx, wd._off or 0)
            else M._inputDrag = nil end
        end
        if focused then pollText(wd, now()) end

    elseif wd.kind == "keybox" then
        local by, bh = y + 18, 22
        local active = (M._keybox == wd)
        local hov = hovering(x, by, w, bh)
        wd._h = approach(wd._h or 0, (hov or active) and 1 or 0, 16)
        text(x, y, lerpc(T.text, T.texthi, wd._h), wd.label, FONT)
        rbox(x, by, w, bh, 5, lerpc(T.widget, T.widgethi, wd._h), active and T.accent or T.border)
        local shown = active and "Press a key (Esc clears)" or keyboxName(wd.value)
        text(x + w / 2, by + 5, active and T.accent or T.text, fitText(shown, w - 16, FONT), FONT, "center")
        if clicked(x, by, w, bh) then
            if active then M._keybox = nil
            else M._keybox = wd; wd._captureAt = now() + 0.12 end
        end
        if M._keybox == wd and now() >= (wd._captureAt or 0) then
            for code = 1, 255 do
                if keyPressed(code) then
                    wd.value = (code == 0x1B or code == 0x08 or code == 0x2E) and 0 or code
                    M._keybox = nil
                    break
                end
            end
        end
    elseif wd.kind == "color" then
        local hov = hovering(x, y, w, 20)
        wd._h = approach(wd._h or 0, hov and 1 or 0, 16)
        text(x, y + 4, lerpc(T.text, T.texthi, wd._h), wd.label, FONT)
        local sw, shh = 32, 14
        local bx, by = x + w - sw, y + 3
        rbox(bx, by, sw, shh, 3, { wd.value[1], wd.value[2], wd.value[3], 255 }, (M._cp == wd) and T.accent or T.border)
        if clicked(bx, by, sw, shh) then
            if M._cp == wd then M._cp = nil
            else M._cp = wd; wd._hsv = { rgb2hsv(wd.value[1], wd.value[2], wd.value[3]) } end
        end
        if M._cp == wd then
            M._cpRect = { x = x, y = y + 24, sx = bx, sy = by, sw = sw, sh = shh }
        end

    elseif wd.kind == "listbox" then
        local ly = y
        if wd.label and wd.label ~= "" then text(x, y, T.text, wd.label, FONT); ly = y + 18 end
        local lh, itemH = (wd._fillH or wd.h), 20
        -- A fill-height list must never paint past the active window clip.
        if clipBottom then lh = mmax(40, mmin(lh, clipBottom - ly - 8)) end
        rbox(x, ly, w, lh, 5, T.bg2, T.border)
        local n = #wd.items
        local visible = mmax(1, floor(lh / itemH))
        local maxScroll = mmax(0, n - visible)
        if (ms.wheel or 0) ~= 0 and hovering(x, ly, w, lh) then
            wd.scroll = wd.scroll - (ms.wheel > 0 and 1 or -1)
            ms.wheel = 0
        end
        wd.scroll = clamp(wd.scroll, 0, maxScroll)
        local hasBar = n > visible
        local listW = hasBar and (w - 9) or w
        for vi = 0, visible - 1 do
            local idx = vi + 1 + floor(wd.scroll)
            if idx <= n then
                local iy = ly + vi * itemH
                local sel = (idx == wd.value)
                local hov = hovering(x + 2, iy, listW - 4, itemH)
                if sel then
                    rfill(x + 3, iy + 1, listW - 6, itemH - 2, 3, T.accent_bg)
                    rfill(x + 3, iy + 1, 2, itemH - 2, 1, T.accent)
                elseif hov then
                    rfill(x + 3, iy + 1, listW - 6, itemH - 2, 3, T.widget)
                end
                text(x + 11, iy + 3, (sel or hov) and T.texthi or T.text, tostring(wd.items[idx]), FONT)
                if clicked(x + 2, iy, listW - 4, itemH) then wd.value = idx end
            end
        end
        if hasBar then
            local trackX = x + w - 6
            local thumbH = mmax(20, lh * visible / n)
            local thumbY = ly + (lh - thumbH) * (maxScroll > 0 and wd.scroll / maxScroll or 0)
            rfill(trackX, ly + 2, 4, lh - 4, 2, T.widget)
            rfill(trackX, thumbY, 4, thumbH, 2, T.widgethi)
            if ms.pressed and not ms.consumed and hovering(trackX - 2, ly, 8, lh) then
                ms.consumed = true; M._scrollbar = wd
            end
            if M._scrollbar == wd then
                if ms.down then wd.scroll = rnd(clamp((ms.y - ly) / lh, 0, 1) * maxScroll)
                else M._scrollbar = nil end
            end
        end

    elseif wd.kind == "custom" then
        if wd.fn then
            UI._x, UI._cy, UI._w = x, y, w
            local ok, err = pcall(wd.fn, UI, x, y, w)
            if not ok then print("[rgnMultitool] custom widget error: " .. tostring(err)) end
            local used = UI._cy - y
            wd._measured = used > 0 and used or wd.h
        end
    end
end

local function imWidget(id, factory)
    local wd = IM[id]
    if not wd then wd = factory(); IM[id] = wd end
    return wd
end
local function imEmit(wd)
    Section._widget(Section, wd, UI._x, UI._cy, UI._w)
    UI._cy = UI._cy + wheight(wd)
end

function UI.checkbox(id, def)
    local wd = imWidget(id, function() return { kind = "check", label = id, value = def and true or false } end)
    imEmit(wd); return wd.value
end
function UI.slider(id, def, mn, mx, step, fmt)
    local wd = imWidget(id, function() local s = step or 1
        return { kind = "slider", label = id, value = def, min = mn, max = mx, step = s, dec = decimalsOf(s), fmt = fmt } end)
    wd.min, wd.max = mn, mx
    imEmit(wd); return wd.value
end
function UI.combo(id, options, def)
    local wd = imWidget(id, function() return { kind = "combo", label = id, options = options, value = def or 1 } end)
    wd.options = options
    imEmit(wd); return wd.value
end
function UI.button(id)
    local wd = imWidget(id, function() return { kind = "button", label = id } end)
    wd._clicked = false
    wd.cb = function() wd._clicked = true end
    imEmit(wd); return wd._clicked
end
function UI.colorpicker(id, def)
    local wd = imWidget(id, function() local c = def or { 255, 255, 255, 255 }
        return { kind = "color", label = id, value = { c[1], c[2], c[3], c[4] or 255 } } end)
    imEmit(wd); return wd.value
end
function UI.label(s, col)
    -- Custom panels share the same fixed content width as normal widgets.
    -- Keep informational text inside that width instead of letting a long
    -- relay/player name bleed into the neighbouring column.
    local shown = fitText(tostring(s), mmax(20, (UI._w or 200) - 2), FONT)
    text(UI._x, UI._cy, col or T.text, shown, FONT); UI._cy = UI._cy + 18
end

local function renderSectionAt(s, x, y, w)
    local h = 40
    pcall(function() h = s:height() end)
    if s._layoutH then h = mmax(h, s._layoutH) end
    if clipBottom and y >= clipBottom then return h end
    if clipTop and (y + h) <= clipTop then return h end
    local rh = h
    local ok, err = pcall(function() rh = s:render(x, y, w) or h end)
    if not ok then print("[rgnMultitool] section '" .. tostring(s.title) .. "' error: " .. tostring(err)); return h end
    return rh
end

local function renderAutoPack(secs, x, y, w, cols)
    cols = cols or 2
    local colW = (w - (cols - 1) * T.pad) / cols
    local colY, colX = {}, {}
    for c = 1, cols do colY[c] = y; colX[c] = x + (c - 1) * (colW + T.pad) end
    for _, s in ipairs(secs) do
        local best = 1
        for c = 2, cols do if colY[c] < colY[best] then best = c end end
        colY[best] = colY[best] + renderSectionAt(s, colX[best], colY[best], colW) + T.sec_gap
    end
end

local function renderRows(rows, x, y, w)
    local cy = y
    for _, row in ipairs(rows) do
        local n = #row
        if n > 0 then
            local gap = 8
            local colW = (w - (n - 1) * gap) / n
            -- Pass 1: natural heights per column
            local colH = {}
            local rowH = 0
            for ci, col in ipairs(row) do
                local h = 0
                for _, s in ipairs(col) do
                    s._layoutH = nil
                    local sh = 40
                    pcall(function() sh = s:height() end)
                    h = h + sh + T.sec_gap
                end
                colH[ci] = h
                if h > rowH then rowH = h end
            end
            -- Pass 2: stretch fill sections to row height, then render
            for ci, col in ipairs(row) do
                local cxx = x + (ci - 1) * (colW + gap)
                local yy = cy
                local stretch = rowH - colH[ci]
                if stretch > 0 then
                    for _, s in ipairs(col) do
                        if s._hasFill then
                            local sh = 40
                            pcall(function() sh = s:height() end)
                            s._layoutH = sh + stretch
                            break
                        end
                    end
                end
                for _, s in ipairs(col) do
                    yy = yy + renderSectionAt(s, cxx, yy, colW) + T.sec_gap
                    s._layoutH = nil
                end
            end
            cy = cy + rowH
        end
    end
end

local function renderContainer(cont, x, y, w)
    if cont._rows and #cont._rows > 0 then renderRows(cont._rows, x, y, w)
    else renderAutoPack(cont.secs, x, y, w, cont._cols) end
end

local function measureSecs(secs)
    local total = 0
    for _, s in ipairs(secs) do local h = 40; pcall(function() h = s:height() end); total = total + h + T.sec_gap end
    return total
end

local function containerHeight(cont)
    if cont._rows and #cont._rows > 0 then
        local total = 0
        for _, row in ipairs(cont._rows) do
            local rowH = 0
            for _, col in ipairs(row) do local h = measureSecs(col); if h > rowH then rowH = h end end
            total = total + rowH
        end
        return total
    end
    local cols = cont._cols or 2
    local colY = {}
    for c = 1, cols do colY[c] = 0 end
    for _, s in ipairs(cont.secs) do
        local best = 1
        for c = 2, cols do if colY[c] < colY[best] then best = c end end
        local h = 40; pcall(function() h = s:height() end)
        colY[best] = colY[best] + h + T.sec_gap
    end
    local mx = 0
    for c = 1, cols do if colY[c] > mx then mx = colY[c] end end
    return mx
end

local function tabContentHeight(tab)
    if #tab.subs == 0 then return containerHeight(tab) end
    local sub = tab.subs[tab._activeSub]
    return 28 + T.sec_gap + (sub and containerHeight(sub) or 0)
end

local function addSection(cont, title)
    local s = Section.new(title)
    if cont._rows and #cont._rows > 0 then
        local row = cont._rows[#cont._rows]
        local col = row[#row]
        col[#col + 1] = s
    else
        cont.secs[#cont.secs + 1] = s
    end
    return s
end
local function contRow(cont) cont._rows[#cont._rows + 1] = { {} }; return cont end
local function contCol(cont)
    if #cont._rows == 0 then cont._rows[#cont._rows + 1] = { {} } end
    local row = cont._rows[#cont._rows]
    row[#row + 1] = {}
    return cont
end

local Sub = {}
Sub.__index = Sub
function Sub.new(name) return setmetatable({ name = name, secs = {}, _rows = {} }, Sub) end
function Sub:Section(title) return addSection(self, title) end
function Sub:Row() return contRow(self) end
function Sub:Col() return contCol(self) end
function Sub:Columns(n) self._cols = n; return self end

local Tab = {}
Tab.__index = Tab

function Tab.new(name)
    return setmetatable({ name = name, secs = {}, subs = {}, _rows = {}, _activeSub = 1, _subT = 1 }, Tab)
end

function Tab:Section(title) return addSection(self, title) end
function Tab:Row() return contRow(self) end
function Tab:Col() return contCol(self) end
function Tab:Columns(n) self._cols = n; return self end

function Tab:Sub(name)
    local s = Sub.new(name)
    self.subs[#self.subs + 1] = s
    return s
end

function Tab:render(x, y, w)
    if #self.subs == 0 then
        renderContainer(self, x, y, w)
        return
    end

    local barH = 28
    local sx = x
    local pos, tgtX, tgtW = {}, x, 0
    for i, sub in ipairs(self.subs) do
        local tw = textw(sub.name) + 24
        pos[i] = { x = sx, w = tw }
        if i == self._activeSub then tgtX, tgtW = sx, tw end
        sx = sx + tw
    end

    local relX = tgtX - x
    self._subX = approach(self._subX or relX, relX, 16)
    self._subW = approach(self._subW or tgtW, tgtW, 16)
    rfill(x + self._subX + 6, y + barH - 6, self._subW - 12, 2, 1, T.accent)

    for i, sub in ipairs(self.subs) do
        local p = pos[i]
        local active = (i == self._activeSub)
        local hov = hovering(p.x, y, p.w, barH)
        sub._h = approach(sub._h or 0, (active or hov) and 1 or 0, 16)
        text(p.x + p.w / 2, y + 6, lerpc(T.textdim, T.texthi, sub._h), sub.name, FONT, "center")
        if clicked(p.x, y, p.w, barH) and self._activeSub ~= i then self._activeSub = i; self._subT = 0 end
    end
    rect(x, y + barH, w, 1, T.divider)

    self._subT = self._subT + (1 - self._subT) * clamp(DT * ANIM.tab, 0, 1)
    local e = smooth(self._subT)
    local sub = self.subs[self._activeSub]
    if sub then renderContainer(sub, x + (1 - e) * 16, y + barH + T.sec_gap, w) end
end

M._tabs   = {}
M._active = 1
M._win    = { x = T.x, y = T.y, w = T.w, h = T.h }
M._minimized = false
M._t      = 0
M._tabT   = 1
M._last   = nil
M._toasts = {}
M._notifPos = T.notif_pos
M._onframe = {}

M._hitlog = {
    queue     = {},
    enabled   = false,
    pos       = nil,
    x_off     = 0,
    y_off     = nil,
    font_size = T.font_size,
    life      = 2.8,
    fade_in   = 0.16,
    fade_out  = 0.40,
    max       = 6,
    colors    = {
        miss = { 235, 90, 90 },
        hit  = { 139, 124, 246 },
        hurt = { 245, 170, 70 },
        kill = { 80, 200, 120 },
    },
}

M._watermark = {
    enabled    = false,
    parts      = { cheat = false, lua = true, user = false, nick = true, fps = true, ping = true },
    cheat_name = "AIMWARE.NET",
    lua_name   = "rgnMultitool",
    user       = nil,
    nick       = nil,
    ping       = nil,
    pos        = "top-right",
    _fps       = 0,
    _killTry   = -1,
}

local WM_MISC_KEYS = { "misc.watermark", "misc.watermark.enable", "misc.indicators.watermark" }

function M:Watermark(on) self._watermark.enabled = on and true or false; return self end

function M:WatermarkSet(opts)
    local wm = self._watermark
    if opts.enabled    ~= nil then wm.enabled = opts.enabled and true or false end
    if opts.cheat_name ~= nil then wm.cheat_name = opts.cheat_name end
    if opts.lua_name   ~= nil then wm.lua_name = opts.lua_name end
    if opts.user       ~= nil then wm.user = opts.user end
    if opts.nick       ~= nil then wm.nick = opts.nick end
    if opts.ping       ~= nil then wm.ping = opts.ping end
    if opts.pos        ~= nil then wm.pos = opts.pos end
    if opts.parts then
        for k, v in pairs(opts.parts) do wm.parts[k] = v and true or false end
    end
    return self
end

function M:OnFrame(fn) self._onframe[#self._onframe + 1] = fn; return self end

function M:Tab(name)
    local t = Tab.new(name)
    self._tabs[#self._tabs + 1] = t
    return t
end

local function smoother(x) x = clamp(x, 0, 1); return x * x * x * (x * (x * 6 - 15) + 10) end

function M:Notify(text, kind)
    self._toasts[#self._toasts + 1] = { text = tostring(text), kind = kind or "info", born = now(), life = T.notif_life }
    while #self._toasts > 6 do table.remove(self._toasts, 1) end
end
function M:Info(t)    self:Notify(t, "info")    end
function M:Success(t) self:Notify(t, "success") end
function M:Error(t)   self:Notify(t, "error")   end

function M:SetNotifPos(p) self._notifPos = p end
function M:GetNotifPos() return self._notifPos end

local HITLOG_TEXT = { miss = "missed", hit = "hit", hurt = "hurt", kill = "killed enemy" }

local function hitlogLabel(e)
    if e.text and e.text ~= "" then return e.text end
    local base = HITLOG_TEXT[e.kind] or e.kind
    if e.dmg then return base .. "  " .. tostring(e.dmg) end
    return base
end

function M:Hitlog(kind, dmg, txt)
    local hl = self._hitlog
    hl.queue[#hl.queue + 1] = {
        kind = tostring(kind or "hit"):lower(),
        dmg  = dmg, text = txt, born = now(),
    }
    while #hl.queue > (hl.max or 6) do table.remove(hl.queue, 1) end
    return self
end

function M:HitlogSet(opts)
    local hl = self._hitlog
    if opts.enabled   ~= nil then hl.enabled   = opts.enabled   end
    if opts.pos       ~= nil then hl.pos       = opts.pos       end
    if opts.x_off     ~= nil then hl.x_off     = opts.x_off     end
    if opts.y_off     ~= nil then hl.y_off     = opts.y_off     end
    if opts.font_size        then hl.font_size = opts.font_size end
    if opts.life             then hl.life      = opts.life      end
    if opts.colors then
        for k, v in pairs(opts.colors) do if v then hl.colors[tostring(k):lower()] = v end end
    end
    return self
end

function M:HitlogPos() return self._hitlog.x_off or 0, self._hitlog.y_off end
function M:HitlogResetPos() self._hitlog.x_off, self._hitlog.y_off = 0, nil; return self end

function M:HitlogColor(kind, col)
    if col then self._hitlog.colors[tostring(kind):lower()] = col end
    return self
end

function M:HitlogClear() self._hitlog.queue = {}; return self end

function M:_drawToasts()
    local toasts = self._toasts
    if #toasts == 0 then return end

    local SLIDE_IN, SLIDE_OUT, SLIDE_DIST, GAP = 0.32, 0.45, 24, 8
    local MIN_W, M_OFF = T.notif_w, T.notif_margin
    local sw, sh = 0, 0
    pcall(function() sw, sh = draw.GetScreenSize() end)
    if sw == 0 then return end

    local pos   = self._notifPos
    local right = pos:find("right") ~= nil
    local top   = pos:find("top") ~= nil

    local i = 1
    while i <= #toasts do
        if (now() - toasts[i].born) >= toasts[i].life + SLIDE_OUT + 0.05 then table.remove(toasts, i)
        else i = i + 1 end
    end

    local y = top and M_OFF or (sh - M_OFF)

    local order = {}
    if top then for k = 1, #toasts do order[#order + 1] = k end
    else for k = #toasts, 1, -1 do order[#order + 1] = k end end

    for _, k in ipairs(order) do
        local tw = toasts[k]
        local age = now() - tw.born
        local inE  = smoother(clamp(age / SLIDE_IN, 0, 1))
        local outE = smoother(clamp((age - tw.life) / SLIDE_OUT, 0, 1))
        local dx   = (1 - inE) * SLIDE_DIST + outE * SLIDE_DIST
        local a    = inE * (1 - outE)
        local h    = 46
        pcall(function() draw.SetFont(FONT) end)
        local W = clamp(textw(tw.text) + 30, MIN_W, mmax(MIN_W, mmin(520, sw - M_OFF * 2)))

        local bx = right and (sw - M_OFF - W + dx) or (M_OFF - dx)
        local by = top and y or (y - h)

        ALPHA = a
        local kc = (tw.kind == "success" and T.notif_success) or (tw.kind == "error" and T.notif_error) or T.notif_info
        rbox(bx, by, W, h, 8, T.section, T.border)
        rfill(bx, by, 3, h, 3, kc, true, false, false, true)
        text(bx + 14, by + 9, T.texthi, fitText(tw.text, W - 28, FONT), FONT)

        local prog = 1 - clamp(age / tw.life, 0, 1)
        rect(bx + 12, by + h - 9, W - 24, 3, T.widget)
        if prog > 0 then rfill(bx + 12, by + h - 9, (W - 24) * prog, 3, 1, kc, true, false, false, true) end

        y = top and (y + (h + GAP) * a) or (y - (h + GAP) * a)
    end
end

local HITLOG_DEMO = {
    { kind = "hit",  label = "hit player in head for 90hp" },
    { kind = "hurt", label = "hurt by player in chest for 20hp" },
    { kind = "miss", label = "missed shot" },
    { kind = "kill", label = "killed player in head for 100hp" },
}
local HL_SNAP_IN, HL_SNAP_OUT, HL_DEAD = 12, 18, 28
local HL_BOTTOM = 160
local function easeOutCubic(t) t = clamp(t, 0, 1); local u = 1 - t; return 1 - u * u * u end

local function hitlogPos(hl, sw, sh)
    local px = sw / 2 + (hl.x_off or 0)
    local py = hl.y_off and (sh / 2 + hl.y_off) or (sh - HL_BOTTOM)
    return px, py
end

local function hitlogEdit(hl, sw, sh, cx, cy, rowH, gap, reveal, row)
    local x, y = hitlogPos(hl, sw, sh)
    local grab = hl._rect

    local dragging = hl._drag or false
    local snapX, snapY = hl._snapX or false, hl._snapY or false
    local pendX, pendY = hl._pendX or 0, hl._pendY or 0
    local mx, my = ms.x, ms.y

    if ms.pressed then
        if grab and mx >= grab.x and mx <= grab.x + grab.w
               and my >= grab.y and my <= grab.y + grab.h then
            dragging = true; ms.consumed = true
        end
        snapX = mabs(x - cx) < 0.5
        snapY = mabs(y - cy) < 0.5
        pendX, pendY = 0, 0
        hl._lmx, hl._lmy = mx, my
    end
    if not ms.down then dragging = false; pendX, pendY = 0, 0 end

    local hw = grab and grab.w / 2 or 90
    local hh = grab and grab.h / 2 or 50
    local minX, maxX = HL_DEAD + hw, sw - HL_DEAD - hw
    local minY, maxY = HL_DEAD + hh, sh - HL_DEAD - hh

    if dragging then
        ms.consumed = true
        local dx = mx - (hl._lmx or mx)
        local dy = my - (hl._lmy or my)
        if dx ~= 0 then
            if snapX then
                pendX = pendX + dx
                if mabs(pendX) > HL_SNAP_OUT then
                    x = cx + (pendX >= 0 and 1 or -1) * (mabs(pendX) - HL_SNAP_OUT)
                    snapX, pendX = false, 0
                else x = cx end
            else
                x = x + dx
                if mabs(x - cx) < HL_SNAP_IN then x, snapX, pendX = cx, true, 0 end
            end
        end
        if dy ~= 0 then
            if snapY then
                pendY = pendY + dy
                if mabs(pendY) > HL_SNAP_OUT then
                    y = cy + (pendY >= 0 and 1 or -1) * (mabs(pendY) - HL_SNAP_OUT)
                    snapY, pendY = false, 0
                else y = cy end
            else
                y = y + dy
                if mabs(y - cy) < HL_SNAP_IN then y, snapY, pendY = cy, true, 0 end
            end
        end
        if minX <= maxX then x = clamp(x, minX, maxX) end
        if minY <= maxY then y = clamp(y, minY, maxY) end
    end

    hl._lmx, hl._lmy = mx, my
    hl._drag, hl._snapX, hl._snapY, hl._pendX, hl._pendY = dragging, snapX, snapY, pendX, pendY

    if dragging then hl.x_off, hl.y_off = x - cx, y - cy end

    if dragging then
        ALPHA = 0.55
        if snapX or mabs(x - cx) < 0.5 then rect(cx, 0, 1, sh, T.accent) end
        if snapY or mabs(y - cy) < 0.5 then rect(0, cy, sw, 1, T.accent) end
        ALPHA = 1
    end

    local n = #HITLOG_DEMO
    local STAGGER = 0.18
    local span = 1 + STAGGER * (n - 1)
    local cyTop = y
    local lx, rx, ty, by2 = 1 / 0, -1 / 0, 1 / 0, -1 / 0
    for i = 1, n do
        local d = HITLOG_DEMO[i]
        local e = easeOutCubic(reveal * span - (i - 1) * STAGGER)
        if e > 0.004 then
            local slide = (1 - e) * 10
            local ry = cyTop + (i - 1) * (rowH + gap) + slide
            local boxW = row(d.kind, d.label, x, ry, e)
            if x - boxW / 2 < lx then lx = x - boxW / 2 end
            if x + boxW / 2 > rx then rx = x + boxW / 2 end
            if ry < ty then ty = ry end
            if ry + rowH > by2 then by2 = ry + rowH end
        end
    end

    if by2 > ty then
        hl._rect = { x = lx, y = ty, w = rx - lx, h = by2 - ty }
        ALPHA = reveal
        local hint = "preview Â· drag to move"
        text(x + 1, by2 + 7, { 0, 0, 0, 235 }, hint, FONT, "center")
        text(x, by2 + 6, T.texthi, hint, FONT, "center")
        ALPHA = 1
    end
end

function M:_drawHitlog()
    local hl = self._hitlog
    if not hl.enabled then return end

    local sw, sh = 0, 0
    pcall(function() sw, sh = draw.GetScreenSize() end)
    if sw == 0 then return end
    local cx, cy = sw / 2, sh / 2

    pcall(function() draw.SetFont(FONT) end)
    local padX, padY, dotR, dotGap = 11, 5, 3, 8

    local txtH = floor((hl.font_size or T.font_size) + 0.5)
    pcall(function() local _, h = draw.GetTextSize("Ayg"); if h and h > 4 then txtH = floor(h + 0.5) end end)
    local rowH = txtH + padY * 2
    local gap  = 6

    local function row(kind, label, px, by, a)
        local col  = hl.colors[kind] or hl.colors.hit or T.accent
        local boxW = floor(padX * 2 + dotR * 2 + dotGap + textw(label) + 0.5)
        local bx   = floor(px - boxW / 2 + 0.5)
        by         = floor(by + 0.5)
        ALPHA = a
        local fill = lerpc(T.section, { col[1], col[2], col[3], 255 }, 0.12)
        local brd  = lerpc(T.border,  { col[1], col[2], col[3], 255 }, 0.45)
        rbox(bx, by, boxW, rowH, 6, fill, brd)

        rfill(bx + 2, by + 4, 2, rowH - 8, 1, col)

        local dcy = by + floor((rowH - dotR * 2) / 2 + 0.5)
        rfill(bx + padX, dcy, dotR * 2, dotR * 2, dotR, col)
        text(bx + padX + dotR * 2 + dotGap, by + padY, T.texthi, label, FONT)
        ALPHA = 1
        return boxW
    end

    local reveal = self._t or 0

    if reveal > 0.02 then
        if self._open ~= false then
            hitlogEdit(hl, sw, sh, cx, cy, rowH, gap, reveal, row)
        else

            local x, y = hitlogPos(hl, sw, sh)
            local n = #HITLOG_DEMO
            local cyTop = y
            for i = 1, n do
                local d = HITLOG_DEMO[i]
                local e = easeOutCubic(reveal)
                if e > 0.004 then row(d.kind, d.label, x, cyTop + (i - 1) * (rowH + gap), e) end
            end
        end
        return
    end

    local q = hl.queue
    local life, fadeIn, fadeOut = hl.life, hl.fade_in, hl.fade_out
    local i = 1
    while i <= #q do
        if (now() - q[i].born) >= life + fadeOut + 0.05 then table.remove(q, i)
        else i = i + 1 end
    end
    if #q == 0 then return end

    local px, py = hitlogPos(hl, sw, sh)
    local n = #q
    local cyTop = py
    for k = 1, n do
        local e   = q[k]
        local age = now() - e.born
        local inE  = smoother(clamp(age / fadeIn, 0, 1))
        local outE = smoother(clamp((age - life) / fadeOut, 0, 1))
        local a    = inE * (1 - outE)
        if a > 0.004 then
            local rowY = cyTop + (n - k) * (rowH + gap) + (1 - inE) * 14
            row(e.kind, hitlogLabel(e), px, rowY, a)
        end
    end
end

local function killMiscWatermark()
    for _, k in ipairs(WM_MISC_KEYS) do
        pcall(function()
            local v = gui.GetValue(k)
            if v == true or v == 1 then gui.SetValue(k, false) end
        end)
    end
end

function M:_drawWatermark()
    local wm = self._watermark
    if not wm.enabled then return end

    if DT and DT > 0 then
        local inst = 1 / DT
        wm._fps = wm._fps > 0 and (wm._fps + (inst - wm._fps) * 0.12) or inst
    end

    local t = now()
    if t - (wm._killTry or -1) > 1 then wm._killTry = t; killMiscWatermark() end

    local function nameSeg(s)
        s = tostring(s or "")
        local dot
        for i = #s, 2, -1 do if s:sub(i, i) == "." then dot = i; break end end
        if dot and dot >= 2 and dot < #s then
            return { { s:sub(1, dot - 1), T.texthi, FONT_LOGO }, { s:sub(dot), T.accent, FONT_LOGO } }
        end
        return { { s, T.texthi, FONT_LOGO } }
    end

    local segs = {}
    if wm.parts.cheat then segs[#segs + 1] = nameSeg(wm.cheat_name or "AIMWARE.NET") end
    if wm.parts.lua   then segs[#segs + 1] = nameSeg(wm.lua_name or "rgnSkins") end
    if wm.parts.user  then segs[#segs + 1] = { { tostring(wm.user or "?"), T.text, FONT } } end
    if wm.parts.nick  then segs[#segs + 1] = { { tostring(wm.nick or "?"), T.text, FONT } } end
    if wm.parts.fps   then segs[#segs + 1] = { { floor(wm._fps + 0.5) .. " fps", T.text, FONT } } end
    if wm.parts.ping  then
        segs[#segs + 1] = { { (wm.ping and (floor(wm.ping + 0.5) .. " ms") or "- ms"), T.text, FONT } }
    end
    if #segs == 0 then return end

    local sw, sh = 0, 0
    pcall(function() sw, sh = draw.GetScreenSize() end)
    if sw == 0 then return end

    local PADX, PADY, DIVPAD = 11, 6, 9
    local function runW(run)
        if run[3] then pcall(function() draw.SetFont(run[3]) end) end
        return textw(run[1])
    end

    local totalW = PADX * 2
    for si, seg in ipairs(segs) do
        if si > 1 then totalW = totalW + DIVPAD * 2 + 1 end
        for _, run in ipairs(seg) do totalW = totalW + runW(run) end
    end

    local txtH = T.font_size
    pcall(function() draw.SetFont(FONT) end)
    pcall(function() local _, h = draw.GetTextSize("Ayg"); if h and h > 4 then txtH = floor(h + 0.5) end end)
    local barH = txtH + PADY * 2

    local margin = 14
    local pos    = wm.pos or "top-right"
    local right  = pos:find("right") ~= nil
    local bottom = pos:find("bottom") ~= nil
    local bx = right  and (sw - margin - totalW) or margin
    local by = bottom and (sh - margin - barH)   or margin

    ALPHA = 1
    rbox(bx, by, totalW, barH, 6, T.section, T.border)
    rfill(bx, by, totalW, 2, 6, T.accent, true, true, false, false)

    local cx = bx + PADX
    local ty = by + PADY
    for si, seg in ipairs(segs) do
        if si > 1 then
            rect(cx + DIVPAD, by + 6, 1, barH - 12, T.divider)
            cx = cx + DIVPAD * 2 + 1
        end
        for _, run in ipairs(seg) do
            text(cx, ty, run[2], run[1], run[3])
            cx = cx + textw(run[1])
        end
    end
end

local SIDEBAR_W = 192
local NAV_LABELS = {
    ["WEAPONS"] = "Weapons", ["AGENTS"] = "Agents", ["SKINS CUSTOM"] = "Custom skins",
    ["VIEWMODEL"] = "Viewmodel", ["SCOPE OVERLAY"] = "Scope overlay", ["CUSTOM SOUNDS"] = "Custom sounds",
    ["MOVEMENT"] = "Movement", ["REGION"] = "Region", ["IDENTITY"] = "Identity",
    ["KILLSAY"] = "Killsay", ["WHITELIST"] = "Whitelist", ["CONFIGS"] = "Settings",
}
local HEADER_USER
local function aimwareHeaderUser()
    if HEADER_USER and HEADER_USER ~= "" then return HEADER_USER end
    local value
    pcall(function()
        local api = rawget(_G, "cheat")
        if api and type(api.GetUserName) == "function" then value = api.GetUserName() end
    end)
    value = tostring(value or ""):gsub("[%c%z]", "")
    if value ~= "" then HEADER_USER = value; return value end
    return "Aimware user"
end

local function tabLayout(tabs, win)
    local pos = {}
    local x = win.x + 10
    local y = win.y + T.titlebar + 40
    local w, step = SIDEBAR_W - 20, 42
    if #tabs > 11 then
        step = math.max(32, math.floor((win.h - T.titlebar - 48) / #tabs))
    end
    local h = math.min(36, step - 6)
    for i = 1, #tabs do
        pos[i] = { x = x, y = y, w = w, h = h }
        y = y + step
    end
    return pos
end

function M:_tabInput(win)
    local pos = tabLayout(self._tabs, win)
    for i, p in ipairs(pos) do
        if clicked(p.x, p.y, p.w, p.h) and self._active ~= i then
            self._active = i
            self._scroll = 0
            M._combo = nil
            self._tabT = 0
        end
    end
end

function M:_drawTabBar(win)
    drawLogo(win.x + 15, win.y + 15, 40, 28)
    text(win.x + 67, win.y + 11, T.texthi, "rgnMultitool", FONT_LOGO)
    text(win.x + 67, win.y + 33, T.textdim, "Aimware Lua Suite", FONT_SMALL)
    local credit = fitText("Made by " .. aimwareHeaderUser(), 180, FONT_SMALL)
    text(win.x + win.w - 50, win.y + 22, T.textdim, credit, FONT_SMALL, "right")

    rfill(win.x + 1, win.y + T.titlebar + 1, SIDEBAR_W - 1, win.h - T.titlebar - 2, 10, T.bg, false, false, true, false)
    rect(win.x + SIDEBAR_W, win.y + T.titlebar + 1, 1, win.h - T.titlebar - 3, T.divider)
    text(win.x + 18, win.y + T.titlebar + 15, T.textdim, "MODULES / TOOLS", FONT_SMALL)

    local pos = tabLayout(self._tabs, win)
    for i, t in ipairs(self._tabs) do
        local p = pos[i]
        local active = (i == self._active)
        local hov = hovering(p.x, p.y, p.w, p.h)
        t._h = approach(t._h or 0, (active or hov) and 1 or 0, 16)
        if active then
            rfill(p.x, p.y, p.w, p.h, 6, T.accent_bg)
            rfill(p.x, p.y + 7, 2, p.h - 14, 1, T.accent)
        elseif hov then
            rfill(p.x, p.y, p.w, p.h, 6, { T.widgethi[1], T.widgethi[2], T.widgethi[3], 150 })
        end
        local label = NAV_LABELS[t.name] or t.name
        label = fitText(label, p.w - 30, FONT)
        text(p.x + 15, p.y + 10, lerpc(T.textdim, T.texthi, t._h), label, FONT)
    end
end

local DD_ITEMH, DD_MAXVIS = 22, 9

function M:_dropdownInput()
    if not M._combo or not M._dd or M._dd.wd ~= M._combo then return end
    local d, wd = M._dd, M._dd.wd
    local n = #wd.options
    local visible = mmin(n, DD_MAXVIS)
    local listH = visible * DD_ITEMH
    local maxScroll = mmax(0, n - visible)
    wd._ddScroll = clamp(wd._ddScroll or 0, 0, maxScroll)

    if (ms.wheel or 0) ~= 0 and hovering(d.x, d.y, d.w, listH) then
        wd._ddScroll = clamp(wd._ddScroll - (ms.wheel > 0 and 1 or -1), 0, maxScroll)
        ms.wheel = 0
    end

    if maxScroll > 0 then
        local trackX = d.x + d.w - 7
        if ms.pressed and not ms.consumed and hovering(trackX - 2, d.y, 10, listH) then
            ms.consumed = true; M._ddScrollbar = wd
        end
        if M._ddScrollbar == wd then
            if ms.down then wd._ddScroll = rnd(clamp((ms.y - d.y) / listH, 0, 1) * maxScroll)
            else M._ddScrollbar = nil end
            return
        end
    end

    if not ms.pressed or ms.consumed then return end
    if hovering(d.x, d.y, d.w, listH) then
        for vi = 0, visible - 1 do
            if hovering(d.x, d.y + vi * DD_ITEMH, d.w, DD_ITEMH) then
                local i = vi + 1 + floor(wd._ddScroll)
                if i <= n then
                    if wd.kind == "multicombo" then wd.value[i] = not wd.value[i] or nil
                    else wd.value = i; M._combo = nil end
                end
                break
            end
        end
        ms.consumed = true
    elseif not hovering(d.x, d.y - d.bh, d.w, d.bh) then
        M._combo = nil
    end
end

local function drawOptionText(x, y, maxWidth, normalColor, value, suffix, suffixColor)
    value = tostring(value or "")
    maxWidth = mmax(8, maxWidth or 8)
    if suffix and suffixColor and value:sub(-#suffix) == suffix then
        local prefix = fitText(value:sub(1, #value - #suffix), mmax(0, maxWidth - textw(suffix)), FONT)
        text(x, y, normalColor, prefix, FONT)
        text(x + textw(prefix), y, suffixColor, suffix, FONT)
    else
        text(x, y, normalColor, fitText(value, maxWidth, FONT), FONT)
    end
end

function M:_drawDropdown()
    if not M._combo or not M._dd or M._dd.wd ~= M._combo then return end
    local d, wd = M._dd, M._dd.wd
    local multi = (wd.kind == "multicombo")
    local n = #wd.options
    local visible = mmin(n, DD_MAXVIS)
    local listH = visible * DD_ITEMH
    local maxScroll = mmax(0, n - visible)
    local scroll = clamp(wd._ddScroll or 0, 0, maxScroll)
    local hasBar = maxScroll > 0
    local iw = hasBar and (d.w - 9) or d.w
    rbox(d.x, d.y, d.w, listH, 5, T.widget, T.accent)
    for vi = 0, visible - 1 do
        local i = vi + 1 + floor(scroll)
        if i <= n then
            local opt = wd.options[i]
            local iy = d.y + vi * DD_ITEMH
            local sel = multi and wd.value[i] or (not multi and wd.value == i)
            local hov = hovering(d.x, iy, iw, DD_ITEMH)
            if hov then rect(d.x + 1, iy, iw - 2, DD_ITEMH, T.widgethi) end
            local optionColor = wd.optionColors and wd.optionColors[i]
            local suffix = wd.optionSuffixes and wd.optionSuffixes[i]
            if multi then
                rbox(d.x + 8, iy + 5, 12, 12, 3, sel and T.accent or T.widget, sel and T.accent or T.border)
                drawOptionText(d.x + 26, iy + 5, iw - 34, (sel or hov) and T.texthi or T.text, opt, suffix, optionColor)
            else
                if sel then rect(d.x + 1, iy, 3, DD_ITEMH, T.accent) end
                local normalColor = (sel or hov) and T.texthi or T.text
                drawOptionText(d.x + 9, iy + 5, iw - 18, normalColor, opt, suffix, optionColor)
            end
        end
    end
    if hasBar then
        local trackX = d.x + d.w - 6
        local thumbH = mmax(20, listH * visible / n)
        local thumbY = d.y + (listH - thumbH) * (scroll / maxScroll)
        rfill(trackX, d.y + 2, 4, listH - 4, 2, T.widget)
        rfill(trackX, thumbY, 4, thumbH, 2, T.accent)
    end
end

local CP = { pad = 12, svW = 138, svH = 128, barW = 14, gap = 10, sw = 22, sgap = 6, slots = 5 }
local function cpWidth()  return CP.pad * 2 + CP.svW + CP.gap * 2 + CP.barW * 2 end
local function cpHeight() return CP.pad * 2 + CP.svH + 52 end

function M:_cpInput()
    if not M._cp or not M._cpRect then return end
    if not ms.pressed or ms.consumed then return end
    local r = M._cpRect
    if hovering(r.x, r.y, cpWidth(), cpHeight()) then ms.consumed = true
    elseif not hovering(r.sx, r.sy, r.sw, r.sh) then M._cp = nil end
end

function M:_cpDraw()
    if not M._cp or not M._cpRect then return end
    local wd, r = M._cp, M._cpRect
    if not wd._hsv then wd._hsv = { rgb2hsv(wd.value[1], wd.value[2], wd.value[3]) } end
    local hsv = wd._hsv
    local w = cpWidth()

    if self._win then r.x = mmin(r.x, self._win.x + self._win.w - w - 6) end

    rbox(r.x, r.y, w, cpHeight(), 6, T.section, T.accent)
    local svX, svY, svW, svH = r.x + CP.pad, r.y + CP.pad, CP.svW, CP.svH
    local hueX   = svX + svW + CP.gap
    local alphaX = hueX + CP.barW + CP.gap

    if ms.pressed and not M._cpDrag then
        if hovering(svX, svY, svW, svH) then M._cpDrag = "sv"
        elseif hovering(hueX, svY, CP.barW, svH) then M._cpDrag = "hue"
        elseif hovering(alphaX, svY, CP.barW, svH) then M._cpDrag = "alpha" end
    end
    if M._cpDrag then
        if ms.down then
            if M._cpDrag == "sv" then
                hsv[2] = clamp((ms.x - svX) / svW, 0, 1)
                hsv[3] = clamp(1 - (ms.y - svY) / svH, 0, 1)
            elseif M._cpDrag == "hue" then
                hsv[1] = clamp((ms.y - svY) / svH, 0, 1)
            elseif M._cpDrag == "alpha" then
                wd.value[4] = rnd(clamp(1 - (ms.y - svY) / svH, 0, 1) * 255)
            end
        else M._cpDrag = nil end
    end

    M._swatches = M._swatches or {}
    local sy   = svY + svH + 28
    local addX = svX
    local addHov = hovering(addX, sy, CP.sw, CP.sw)
    local pre = { hsv2rgb(hsv[1], hsv[2], hsv[3]) }
    if ms.pressed and addHov then
        table.insert(M._swatches, 1, { pre[1], pre[2], pre[3], wd.value[4] or 255 })
        while #M._swatches > CP.slots do table.remove(M._swatches) end
    end
    for i = 1, CP.slots do
        local c = M._swatches[i]
        local cxs = addX + i * (CP.sw + CP.sgap)
        if c and ms.pressed and hovering(cxs, sy, CP.sw, CP.sw) then
            hsv[1], hsv[2], hsv[3] = rgb2hsv(c[1], c[2], c[3])
            wd.value[4] = c[4] or 255
        end
    end

    local h, s, v = hsv[1], hsv[2], hsv[3]
    local cr, cg, cb = hsv2rgb(h, s, v)
    local av = wd.value[4] or 255

    local hr, hg, hb = hsv2rgb(h, 1, 1)
    rect(svX, svY, svW, svH, { hr, hg, hb })
    for dx = 0, svW - 1, 2 do
        rect(svX + dx, svY, 2, svH, { 255, 255, 255, 255 * (1 - dx / svW) })
    end
    for dy = 0, svH - 1, 2 do
        rect(svX, svY + dy, svW, 2, { 0, 0, 0, 255 * (dy / svH) })
    end
    frame(svX, svY, svW, svH, T.border)
    local cxp = svX + clamp(s, 0, 1) * svW
    local cyp = svY + (1 - clamp(v, 0, 1)) * svH
    rbox(cxp - 5, cyp - 5, 10, 10, 5, { cr, cg, cb }, { 255, 255, 255 })

    for dy = 0, svH - 1, 2 do
        rect(hueX, svY + dy, CP.barW, 2, { hsv2rgb(dy / svH, 1, 1) })
    end
    frame(hueX, svY, CP.barW, svH, T.border)
    rfill(hueX - 2, svY + clamp(h, 0, 1) * svH - 2, CP.barW + 4, 4, 1, { 255, 255, 255 })

    rect(alphaX, svY, CP.barW, svH, T.widget)
    for dy = 0, svH - 1, 2 do
        rect(alphaX, svY + dy, CP.barW, 2, { cr, cg, cb, 255 * (1 - dy / svH) })
    end
    frame(alphaX, svY, CP.barW, svH, T.border)
    rfill(alphaX - 2, svY + (1 - av / 255) * svH - 2, CP.barW + 4, 4, 1, { 255, 255, 255 })

    wd.value[1], wd.value[2], wd.value[3] = cr, cg, cb
    local ty = svY + svH + 6
    text(svX, ty, T.textdim, string.format("R %d  G %d  B %d  A %d", cr, cg, cb, av), FONT)

    rbox(addX, sy, CP.sw, CP.sw, 4, addHov and T.widgethi or T.widget, T.border)
    text(addX + CP.sw / 2, sy + 3, addHov and T.texthi or T.textdim, "+", FONT, "center")
    for i = 1, CP.slots do
        local c = M._swatches[i]
        local cxs = addX + i * (CP.sw + CP.sgap)
        rbox(cxs, sy, CP.sw, CP.sw, 4, c and { c[1], c[2], c[3], 255 } or T.bg2, T.border)
    end
end

function M:_drag(win)
    if ms.pressed and not ms.consumed and hovering(win.x, win.y, win.w, T.titlebar) then
        ms.consumed = true
        self._dragWin = { dx = ms.x - win.x, dy = ms.y - win.y }
    end
    if self._dragWin then
        if ms.down then win.x = ms.x - self._dragWin.dx; win.y = ms.y - self._dragWin.dy
        else self._dragWin = nil end
    end
end

function M:_frame()
    local real = self._win

    -- Minimized header.
    if self._minimized then
        local ease = smooth(self._t)
        ALPHA = ease
        local miniW, miniH = 184, 42
        local expandX = real.x + miniW - 28
        if clicked(expandX, real.y + 10, 22, 22) then
            self._minimized = false
            self._dragWin = nil
            return
        end
        local dragWin = { x = real.x, y = real.y, w = miniW - 31, h = miniH }
        self:_drag(dragWin)
        real.x, real.y = dragWin.x, dragWin.y
        expandX = real.x + miniW - 28

        rbox(real.x + 5, real.y + 7, miniW, miniH, 9, T.shadow, { 0, 0, 0, 0 })
        rbox(real.x, real.y, miniW, miniH, 9, T.bg, T.border)
        rfill(real.x, real.y, miniW, 2, 9, T.accent, true, true, false, false)
        drawLogo(real.x + 7, real.y + 8, 36, 26)
        text(real.x + 53, real.y + 13, T.texthi, "rgnMultitool", FONT_LOGO)
        rbox(expandX, real.y + 10, 22, 22, 5, T.widget, T.border)
        text(expandX + 11, real.y + 12, T.texthi, "+", FONT_B, "center")
        return
    end

    local tab = self._tabs[self._active]

    local contentH = 0
    if tab then pcall(function() contentH = tabContentHeight(tab) end) end
    local chrome = T.titlebar + T.pad * 2

    local screenW, screenH = 1920, 1080
    pcall(function() screenW, screenH = draw.GetScreenSize() end)
    screenW = screenW or 1920
    screenH = screenH or 1080

    -- resize grip (bottom-right)
    local grip = 14
    if self._resizeEnabled ~= false then
        local gx, gy = real.x + real.w - grip, real.y + real.h - grip
        if ms.pressed and not ms.consumed and hovering(gx, gy, grip, grip) then
            ms.consumed = true
            self._resize = { ox = ms.x, oy = ms.y, ow = real.w, oh = real.h }
            self._autoH = false
        end
        if self._resize then
            if ms.down then
                real.w = clamp(self._resize.ow + (ms.x - self._resize.ox), 520, screenW - 40)
                real.h = clamp(self._resize.oh + (ms.y - self._resize.oy), 300, screenH - 40)
            else
                self._resize = nil
            end
        end
    end

    if self._autoH then
        local targetH = clamp(contentH + chrome + 8, 280, screenH - 60)
        real.h = real.h + (targetH - real.h) * clamp(DT * 14, 0, 1)
    end

    local ease = smooth(self._t)
    ALPHA = ease
    local oy = (1 - ease) * 14
    local win = { x = real.x, y = real.y - oy, w = real.w, h = real.h }

    local minimizeX = win.x + win.w - 34
    if clicked(minimizeX, win.y + 17, 24, 24) then
        self._minimized = true
        self._combo, self._focus, self._resize = nil, nil, nil
        self._dragWin = nil
        return
    end

    rbox(win.x + 7, win.y + 9, win.w, win.h, 11, T.shadow, { 0, 0, 0, 0 })
    rbox(win.x, win.y, win.w, win.h, 11, T.bg, T.border)
    rfill(win.x + 1, win.y + T.titlebar, win.w - 2, win.h - T.titlebar - 1, 10, T.bg2, false, false, true, true)
    rect(win.x + 2, win.y + T.titlebar + 1, 2, win.h - T.titlebar - 4, { T.accent[1], T.accent[2], T.accent[3], 65 })

    self:_tabInput(win)
    self:_drag(win)
    self:_dropdownInput()
    self:_cpInput()

    local availH = win.h - chrome
    local maxScroll = mmax(0, contentH - availH)
    self._scroll = clamp(self._scroll or 0, 0, maxScroll)

    -- scrollbar drag
    if maxScroll > 0 then
        local barX, barW = win.x + win.w - 7, 4
        local th = mmax(20, (availH / contentH) * availH)
        local ty = win.y + T.titlebar + (availH - th) * (self._scroll / maxScroll)
        if ms.pressed and not ms.consumed and hovering(barX - 2, win.y + T.titlebar, barW + 6, availH) then
            ms.consumed = true
            self._scrollDrag = true
        end
        if self._scrollDrag then
            if ms.down then
                local frac = clamp((ms.y - (win.y + T.titlebar) - th * 0.5) / mmax(1, availH - th), 0, 1)
                self._scroll = frac * maxScroll
            else
                self._scrollDrag = nil
            end
        end
    end

    local tabEase = smooth(self._tabT)
    local cx = win.x + SIDEBAR_W + T.pad + (1 - tabEase) * 18
    local cy = win.y + T.titlebar + T.pad - self._scroll
    local cw = win.w - SIDEBAR_W - T.pad * 2 - 8
    clipTop, clipBottom = win.y + T.titlebar, win.y + win.h - 2
    if tab then
        local ok, err = pcall(function() tab:render(cx, cy, cw) end)
        if not ok then print("[rgnMultitool] tab '" .. tostring(tab.name) .. "' error: " .. tostring(err)) end
    end
    clipTop, clipBottom = nil, nil

    if maxScroll > 0 and (ms.wheel or 0) ~= 0 and hovering(win.x, win.y + T.titlebar, win.w, win.h - T.titlebar) then
        self._scroll = clamp(self._scroll - (ms.wheel > 0 and 36 or -36), 0, maxScroll)
        ms.wheel = 0
    end

    rfill(win.x + 1, win.y + 1, win.w - 2, T.titlebar - 1, 6, T.bg, true, true, false, false)
    rfill(win.x, win.y, win.w, 2, 7, T.accent, true, true, false, false)
    rect(win.x + 1, win.y + T.titlebar, win.w - 2, 1, T.border)
    self:_drawTabBar(win)
    rbox(minimizeX, win.y + 17, 24, 24, 6, T.widget, T.border)
    text(minimizeX + 12, win.y + 18, T.texthi, "-", FONT_B, "center")

    if maxScroll > 0 then
        local th = mmax(20, (availH / contentH) * availH)
        local ty = win.y + T.titlebar + (availH - th) * (self._scroll / maxScroll)
        rfill(win.x + win.w - 6, win.y + T.titlebar + 2, 3, availH - 4, 1, T.widget)
        rfill(win.x + win.w - 6, ty, 3, th, 1, T.accent)
    end

    -- resize grip visual
    if self._resizeEnabled ~= false then
        local gx, gy = win.x + win.w - 11, win.y + win.h - 11
        rect(gx, gy + 6, 8, 1, T.textdim)
        rect(gx + 3, gy + 3, 5, 1, T.textdim)
        rect(gx + 6, gy, 2, 1, T.textdim)
    end

    self:_drawDropdown()
    self:_cpDraw()

    if M._focus and ms.pressed and not ms.consumed then M._focus = nil end

    real.x = win.x
    real.y = win.y + oy
end

function M:OpenFolder()
    pcall(function()
        ffi.cdef[[ int ShellExecuteA(void*, const char*, const char*, const char*, const char*, int); ]]
    end)
    pcall(function()
        local shell = ffi.load("shell32")
        shell.ShellExecuteA(nil, "open", M._dir or ".", nil, nil, 1)
    end)
end

function M:_initScreen()
    local win = self._win
    ALPHA = smooth(self._t)
    rbox(win.x, win.y, win.w, win.h, 7, T.bg, T.border)
    rfill(win.x, win.y, win.w, 2, 7, T.accent, true, true, false, false)
    local dots = string.rep(".", floor(now() * 2) % 4)
    text(win.x + win.w / 2, win.y + win.h / 2 - 12, T.texthi, "Initialization in progress" .. dots, FONT_B, "center")
    text(win.x + win.w / 2, win.y + win.h / 2 + 12, T.textdim, "fetching fonts, please wait", FONT, "center")
end

function M:Build(opts)
    opts = opts or {}
    if opts.w then self._win.w = opts.w end
    if opts.h then self._win.h = opts.h end
    if opts.x then self._win.x = opts.x end
    if opts.y then self._win.y = opts.y end
    if opts.autoH ~= nil then
        self._autoH = opts.autoH and true or false
    else
        self._autoH = (opts.h == nil)
    end
    if opts.resize ~= nil then
        self._resizeEnabled = opts.resize and true or false
    else
        self._resizeEnabled = true
    end

    _getMouse = resolveMouse()
    _getWheel = resolveWheel()
    _clock    = resolveClock()
    initFonts()
    if not _getMouse then print("[rgnMultitool] WARNING: mouse position API not found -- cursor won't track") end

    local menuRef
    pcall(function() menuRef = gui.Reference("MENU") end)

    -- Runtime overlays must keep drawing while the Aimware menu is closed.
    -- Keep this dispatcher outside Draw so Lua does not allocate a fresh
    -- closure on every rendered frame.
    local function drawRuntimeOverlays(t)
        local movementDrawActive = self._movementDrawActive
        if type(self._movementDrawCallback) == "function"
            and (type(movementDrawActive) ~= "function" or movementDrawActive()) then
            local ok, err = pcall(self._movementDrawCallback)
            self._movementDrawAliveAt = t
            if ok then
                self._movementDrawError = nil
            else
                local message = tostring(err)
                if self._movementDrawError ~= message then
                    self._movementDrawError = message
                    print("[rgnMovement] main Draw hook error: " .. message)
                end
            end
        end
        local killsayDrawActive = self._killsayDrawActive
        if type(self._killsayDrawCallback) == "function"
            and (type(killsayDrawActive) ~= "function" or killsayDrawActive()) then
            local ok, err = pcall(self._killsayDrawCallback)
            self._killsayDrawAliveAt = t
            if ok then
                self._killsayDrawError = nil
            else
                local message = tostring(err)
                if self._killsayDrawError ~= message then
                    self._killsayDrawError = message
                    print("[rgnKillsay] main Draw hook error: " .. message)
                end
            end
        end
        local scopeDrawActive = self._scopeDrawActive
        if type(self._scopeDrawCallback) == "function"
            and (type(scopeDrawActive) ~= "function" or scopeDrawActive()) then
            local ok, err = pcall(self._scopeDrawCallback)
            if ok then
                self._scopeDrawError = nil
            else
                local message = tostring(err)
                if self._scopeDrawError ~= message then
                    self._scopeDrawError = message
                    print("[rgnScope] main Draw hook error: " .. message)
                end
            end
        end
        local manualAADrawActive = self._manualAADrawActive
        if type(self._manualAADrawCallback) == "function"
            and (type(manualAADrawActive) ~= "function" or manualAADrawActive()) then
            local ok, err = pcall(self._manualAADrawCallback)
            self._manualAADrawAliveAt = t
            if ok then
                self._manualAADrawError = nil
            else
                local message = tostring(err)
                if self._manualAADrawError ~= message then
                    self._manualAADrawError = message
                    print("[rgnManualAA] main Draw hook error: " .. message)
                end
            end
        end
        local whitelistDrawActive = self._whitelistDrawActive
        if type(self._whitelistDrawCallback) == "function"
            and (type(whitelistDrawActive) ~= "function" or whitelistDrawActive()) then
            local ok, err = pcall(self._whitelistDrawCallback)
            self._whitelistDrawAliveAt = t
            if ok then
                self._whitelistDrawError = nil
            else
                local message = tostring(err)
                if self._whitelistDrawError ~= message then
                    self._whitelistDrawError = message
                    print("[rgnWhitelist] main Draw hook error: " .. message)
                end
            end
        end
    end

    callbacks.Register("Draw", "rgnMultitool_UIDraw", function()
        local open = true
        if menuRef then pcall(function() open = menuRef:IsActive() end) end
        self._open = open
        if not open then self._focus = nil; self._inputDrag = nil; self._keybox = nil end

        local t  = now()
        local dt = 1
        if _clock then dt = self._last and clamp(t - self._last, 0, 0.1) or 0 end
        self._last = t
        DT = dt

        self._t    = self._t    + ((open and 1 or 0) - self._t) * clamp(dt * ANIM.open, 0, 1)
        self._tabT = self._tabT + (1 - self._tabT)              * clamp(dt * ANIM.tab,  0, 1)

        if self._initco then
            pcall(function()
                if coroutine.status(self._initco) ~= "dead" then coroutine.resume(self._initco) end
            end)
            if coroutine.status(self._initco) == "dead" then self._initco = nil end
            pcall(function() self:_initScreen() end)
            return
        end

        if not open and self._t < 0.005 and #self._toasts == 0 then
            drawRuntimeOverlays(t)
            self._t = 0
            return
        end

        updateMouse()
        pcall(function() self:_drawToasts() end)

        ALPHA = 1
        for _, fn in ipairs(self._onframe) do pcall(fn, UI) end

        if not open and self._t < 0.005 then
            drawRuntimeOverlays(t)
            self._t = 0
            return
        end

        local ok, err = pcall(function() self:_frame() end)
        if not ok then print("[rgnMultitool] frame error: " .. tostring(err)) end
        drawRuntimeOverlays(t)
    end)

    pcall(function()
        callbacks.Register("CreateMove", "rgnMultitool_UIInput", function(cmd)
        local viewmodelCommandActive = M._viewmodelCommandActive
        if cmd and type(M._viewmodelCommandCallback) == "function"
            and (type(viewmodelCommandActive) ~= "function" or viewmodelCommandActive()) then
            local ok, err = pcall(M._viewmodelCommandCallback, cmd)
            M._viewmodelCommandAliveAt = now()
            if ok then
                M._viewmodelCommandError = nil
            else
                local message = tostring(err)
                if M._viewmodelCommandError ~= message then
                    M._viewmodelCommandError = message
                    print("[rgnMultitool] viewmodel command hook error: " .. message)
                end
            end
        end
        local movementCommandActive = M._movementCommandActive
        if cmd and type(M._movementCommandCallback) == "function"
            and (type(movementCommandActive) ~= "function" or movementCommandActive()) then
            local ok, err = pcall(M._movementCommandCallback, cmd)
            M._movementCommandAliveAt = now()
            if ok then
                M._movementCommandError = nil
            else
                local message = tostring(err)
                if M._movementCommandError ~= message then
                    M._movementCommandError = message
                    print("[rgnMovement] main CreateMove hook error: " .. message)
                end
            end
        end
        local manualAACommandActive = M._manualAACommandActive
        local whitelistCommandActive = M._whitelistCommandActive
        if cmd and type(M._whitelistCommandCallback) == "function"
            and (type(whitelistCommandActive) ~= "function" or whitelistCommandActive()) then
            local ok, err = pcall(M._whitelistCommandCallback, cmd)
            M._whitelistCommandAliveAt = now()
            if ok then
                M._whitelistCommandError = nil
            else
                local message = tostring(err)
                if M._whitelistCommandError ~= message then
                    M._whitelistCommandError = message
                    print("[rgnWhitelist] main CreateMove hook error: " .. message)
                end
            end
        end
        if cmd and type(M._manualAACommandCallback) == "function"
            and (type(manualAACommandActive) ~= "function" or manualAACommandActive()) then
            local ok, err = pcall(M._manualAACommandCallback, cmd)
            M._manualAACommandAliveAt = now()
            if ok then
                M._manualAACommandError = nil
            else
                local message = tostring(err)
                if M._manualAACommandError ~= message then
                    M._manualAACommandError = message
                    print("[rgnManualAA] main CreateMove hook error: " .. message)
                end
            end
        end
        if not (M._open and M._focus) or not cmd then return end
        pcall(function() cmd.forwardmove = 0 end)
        pcall(function() cmd.sidemove = 0 end)
        pcall(function() cmd.upmove = 0 end)
        pcall(function() cmd.buttons = 0 end)
        pcall(function() cmd:SetForwardMove(0) end)
        pcall(function() cmd:SetSideMove(0) end)
        pcall(function() cmd:SetUpMove(0) end)
        pcall(function() cmd:SetButtons(0) end)
        end)
    end)

    pcall(function()
        callbacks.Register("Unload", "rgnMultitool_UIUnload", function()
            pcall(callbacks.Unregister, "Draw", "rgnMultitool_UIDraw")
            pcall(callbacks.Unregister, "CreateMove", "rgnMultitool_UIInput")
        end)
    end)

    return self
end

return M
]===]
local __chunk, __err = loadstring(__RGN_GUILIB, "=rgnMultitool_guilib.lua")
if not __chunk then print("[rgnMultitool] UI compile error: " .. tostring(__err)); return end
local __ok, M = pcall(__chunk)
if not __ok or type(M) ~= "table" then print("[rgnMultitool] UI load error: " .. tostring(M)); return end
local RGN_MULTI = rawget(_G, "RGN_MULTITOOL_STATE") or {}
local CUSTOM_MODE_FILE = "rgnmultitool_custom_enabled.txt"
local function loadCustomEnabled()
    local value
    pcall(function()
        local f = file.Open(CUSTOM_MODE_FILE, "r")
        if f then value = f:Read(); f:Close() end
    end)
    if type(value) ~= "string" then return true end
    return value:match("^%s*1%s*$") ~= nil
end
local function saveCustomEnabled(enabled)
    pcall(function()
        local f = file.Open(CUSTOM_MODE_FILE, "w")
        if f then f:Write(enabled and "1" or "0"); f:Close() end
    end)
end

RGN_MULTI.customEnabled = loadCustomEnabled()
RGN_MULTI.characterMode = RGN_MULTI.customEnabled and "custom" or "none"
RGN_MULTI.setAgentEnabled = nil
RGN_MULTI.setCustomEnabled = nil
RGN_MULTI.suspendCustomModel = nil

function RGN_MULTI.activateAgents(reason)
    RGN_MULTI.customEnabled = false
    RGN_MULTI.characterMode = "agents"
    RGN_MULTI.reason = reason or "official agents enabled"
    saveCustomEnabled(false)
    if RGN_MULTI.suspendCustomModel then pcall(RGN_MULTI.suspendCustomModel) end
    if RGN_MULTI.setCustomEnabled then pcall(RGN_MULTI.setCustomEnabled, false) end
    if RGN_MULTI.setAgentEnabled then pcall(RGN_MULTI.setAgentEnabled, true) end
end

function RGN_MULTI.activateCustom(reason)
    RGN_MULTI.customEnabled = true
    RGN_MULTI.characterMode = "custom"
    RGN_MULTI.reason = reason or "custom characters enabled"
    saveCustomEnabled(true)
    if RGN_MULTI.setCustomEnabled then pcall(RGN_MULTI.setCustomEnabled, true) end
    if RGN_MULTI.setAgentEnabled then pcall(RGN_MULTI.setAgentEnabled, false) end
end

function RGN_MULTI.disableCustom(reason)
    RGN_MULTI.customEnabled = false
    if RGN_MULTI.characterMode ~= "agents" then RGN_MULTI.characterMode = "none" end
    RGN_MULTI.reason = reason or "custom characters disabled"
    saveCustomEnabled(false)
    if RGN_MULTI.suspendCustomModel then pcall(RGN_MULTI.suspendCustomModel) end
    if RGN_MULTI.setCustomEnabled then pcall(RGN_MULTI.setCustomEnabled, false) end
end

function RGN_MULTI.deactivateAgents(reason)
    if RGN_MULTI.setAgentEnabled then pcall(RGN_MULTI.setAgentEnabled, false) end
    RGN_MULTI.characterMode = RGN_MULTI.customEnabled and "custom" or "none"
    RGN_MULTI.reason = reason or "official agents disabled"
end

_G.RGN_MULTITOOL_STATE = RGN_MULTI

local function loadModule(name, fn)
    local ok, err = pcall(fn)
    if not ok then
        print("[rgn] " .. name .. ": " .. tostring(err))
        return false
    end
    return true
end

loadModule("MANUAL AA", function()
-- Native Aimware controls stay under Ragebot > Anti-Aim. Runtime drawing and
-- callbacks are owned by rgnMultitool so reloading cannot duplicate them.
local rbotAA = gui.Reference("Ragebot", "Anti-Aim")
local yawOffsetRef = gui.Reference("Ragebot", "Anti-Aim", "Yaw Offset")
local pitchRef = gui.Reference("Ragebot", "Anti-Aim", "Pitch Angle")

local enabled = gui.Checkbox(rbotAA, "manual_enabled", "Manual anti-aim", true)
local indicators = gui.Checkbox(rbotAA, "manual_ind_on", "Manual AA indicators", false)
local keyLeft = gui.Keybox(rbotAA, "manual_left_key", "Manual left", 0)
local keyRight = gui.Keybox(rbotAA, "manual_right_key", "Manual right", 0)
local keyForward = gui.Keybox(rbotAA, "manual_forward_key", "Manual forward", 0)
local keyJumpBug = gui.Keybox(rbotAA, "jb_hold_key", "Jump bug hold", 0)
local idleYaw = gui.Slider(rbotAA, "manual_idle_yaw", "Back yaw offset", 24, -180, 180)
local lrPitchOff = gui.Checkbox(rbotAA, "manual_lr_pitch_off", "Left/right pitch off", true)
local activeColor = gui.ColorPicker(rbotAA, "manual_indicator_active", "Active direction", 74, 166, 255, 255)
local inactiveColor = gui.ColorPicker(rbotAA, "manual_indicator_inactive", "Inactive direction", 112, 122, 138, 150)

local manualState = 0 -- back, left, right, forward
local jumpBugHeld, savedAutostrafe = false, nil
local capturedYaw, capturedPitch, capturedOriginals = nil, nil, false
local wasEnabled = enabled:GetValue() == true
local titleFont, rowFont
pcall(function() titleFont = draw.CreateFont("Bahnschrift SemiBold", 15, 700) end)
pcall(function() rowFont = draw.CreateFont("Bahnschrift", 13, 600) end)
if not titleFont then pcall(function() titleFont = draw.CreateFont("Verdana", 13, 700) end) end
if not rowFont then pcall(function() rowFont = draw.CreateFont("Verdana", 12, 600) end) end

local function getValue(path)
    local value
    pcall(function() value = gui.GetValue(path) end)
    return value
end

local function setValue(path, value)
    pcall(function() gui.SetValue(path, value) end)
end

local function rgba(picker, fallback)
    local ok, r, g, b, a = pcall(function() return picker:GetValue() end)
    if ok and type(r) == "number" then return r, g or r, b or r, a or 255 end
    return fallback[1], fallback[2], fallback[3], fallback[4]
end

local function releaseJumpBug()
    if not jumpBugHeld then return end
    jumpBugHeld = false
    local restore = savedAutostrafe
    if restore == nil then restore = true end
    setValue("misc.autostrafe", restore)
end

local function checkHotkeys()
    if enabled:GetValue() ~= true then
        releaseJumpBug()
        return
    end

    local function pressed(box)
        local key = tonumber(box:GetValue()) or 0
        return key ~= 0 and input.IsButtonPressed(key)
    end
    if pressed(keyLeft) then manualState = manualState == 1 and 0 or 1 end
    if pressed(keyRight) then manualState = manualState == 2 and 0 or 2 end
    if pressed(keyForward) then manualState = manualState == 3 and 0 or 3 end

    local jumpKey = tonumber(keyJumpBug:GetValue()) or 0
    local down = jumpKey ~= 0 and input.IsButtonDown(jumpKey) or false
    if down and not jumpBugHeld then
        jumpBugHeld = true
        savedAutostrafe = getValue("misc.autostrafe")
        setValue("misc.autostrafe", false)
    elseif not down then
        releaseJumpBug()
    end
end

local function inGame()
    local player
    pcall(function() player = entities.GetLocalPlayer() end)
    if not player then pcall(function() player = entities.GetLocalPawn() end) end
    if not player then return false end
    local team
    pcall(function() team = player:GetTeamNumber() end)
    if team == nil then pcall(function() team = player:GetFieldInt("m_iTeamNum") end) end
    if type(team) == "number" and team >= 1 and team <= 3 then return true end
    local server = ""
    pcall(function() server = tostring(engine.GetServerIP() or "") end)
    return server ~= "" and server ~= "0.0.0.0:0"
end

local function drawIndicator()
    if enabled:GetValue() ~= true or indicators:GetValue() ~= true or not inGame() then return end
    local _, sh = draw.GetScreenSize()
    if not sh then return end
    local ar, ag, ab, aa = rgba(activeColor, { 74, 166, 255, 255 })
    local ir, ig, ib, ia = rgba(inactiveColor, { 112, 122, 138, 150 })
    -- Aimware keeps NS / MD / SM around the lower half of the left edge.
    -- Anchor our compact block directly below it and scale it with resolution.
    local x, y = 11, math.min(math.max(120, math.floor(sh * 0.55)), sh - 92)
    local rows = {
        { "LEFT", manualState == 1 },
        { "RIGHT", manualState == 2 },
        { "FORWARD", manualState == 3 },
    }

    if titleFont then draw.SetFont(titleFont) end
    draw.Color(8, 12, 18, 205)
    draw.FilledRect(x, y, x + 104, y + 18)
    draw.Color(ar, ag, ab, 235)
    draw.FilledRect(x, y, x + 3, y + 18)
    draw.Color(226, 232, 240, 245)
    draw.Text(x + 9, y + 2, "MANUAL AA")

    if rowFont then draw.SetFont(rowFont) end
    for i = 1, #rows do
        local rowY, active = y + 22 + (i - 1) * 18, rows[i][2]
        draw.Color(7, 10, 15, active and 205 or 150)
        draw.FilledRect(x, rowY, x + 104, rowY + 15)
        if active then
            draw.Color(ar, ag, ab, aa)
            draw.FilledRect(x, rowY, x + 3, rowY + 15)
            draw.Color(238, 244, 252, 255)
        else
            draw.Color(ir, ig, ib, ia)
        end
        draw.Text(x + 9, rowY + 1, rows[i][1])
    end
end

local function restoreOrientation()
    if not capturedOriginals then return end
    if capturedYaw ~= nil then pcall(function() yawOffsetRef:SetValue(capturedYaw) end) end
    if capturedPitch ~= nil then pcall(function() pitchRef:SetValue(capturedPitch) end) end
    capturedYaw, capturedPitch, capturedOriginals = nil, nil, false
end

local function manualDraw()
    local current = enabled:GetValue() == true
    if wasEnabled and not current then
        releaseJumpBug()
        restoreOrientation()
    end
    wasEnabled = current
    drawIndicator()
end

local function manualMove()
    -- Input belongs to the command-rate path; this avoids polling hotkeys at
    -- the render frame rate on high-FPS clients.
    checkHotkeys()
    if enabled:GetValue() ~= true or not getValue("rbot.antiaim.enabled") then return end
    local player
    pcall(function() player = entities.GetLocalPlayer() end)
    if not player then pcall(function() player = entities.GetLocalPawn() end) end
    if not player then return end
    if not capturedOriginals then
        capturedOriginals = true
        pcall(function() capturedYaw = yawOffsetRef:GetValue() end)
        pcall(function() capturedPitch = pitchRef:GetValue() end)
    end
    local yaw, pitch = idleYaw:GetValue(), 1
    local sidePitch = lrPitchOff:GetValue() and 0 or 1
    if manualState == 1 then yaw, pitch = -90, sidePitch
    elseif manualState == 2 then yaw, pitch = 90, sidePitch
    elseif manualState == 3 then yaw, pitch = 180, 1 end
    pcall(function() yawOffsetRef:SetValue(yaw) end)
    pcall(function() pitchRef:SetValue(pitch) end)
end

M._manualAADrawCallback = manualDraw
M._manualAADrawActive = function() return true end
M._manualAACommandCallback = manualMove
M._manualAACommandActive = function() return enabled:GetValue() == true end

callbacks.Register("Unload", "rgnMultitool_ManualAAUnload", function()
    releaseJumpBug()
    restoreOrientation()
    if M._manualAADrawCallback == manualDraw then M._manualAADrawCallback = nil end
    if M._manualAACommandCallback == manualMove then M._manualAACommandCallback = nil end
    M._manualAADrawActive, M._manualAACommandActive = nil, nil
end)
end)

loadModule("SKINS", function()
local M = M
-- Local player model override.
local SetModel = {
    path = nil, error = nil, phase = "idle", persistence = true,
    original = nil, lastAppliedPath = nil,
}
local setModelError
local ffi, bit_ = rawget(_G, "ffi"), rawget(_G, "bit")
local MODEL_CONFIG_FILE = "rgnskins_character.txt"

if type(ffi) ~= "table" or type(bit_) ~= "table" then
    setModelError = "LuaJIT ffi/bit unavailable"
elseif type(mem) ~= "table" or type(entities) ~= "table" then
    setModelError = "Aimware mem/entities API unavailable"
else
    pcall(function() ffi.cdef[[
        void* GetModuleHandleA(const char*);
        void* GetProcAddress(void*, const char*);
        typedef struct {
            int32_t length;
            uint32_t allocated;
            union { char* p; char s[8]; } data;
        } RGN_CBufferString;
    ]] end)

    local band, rshift = bit_.band, bit_.rshift
    local CLIENT = "client.dll"
    local SETMODEL_SIG = "40 53 48 83 EC ?? 48 8B D9 4C 8B C2 48 8B 0D ?? ?? ?? ?? 48 8D 54 24 40"
    local ENTITY_SIGS = {
        "48 8B 0D ?? ?? ?? ?? 48 89 7C 24 ?? 8B FA C1 EB",
        "48 89 0D ?? ?? ?? ?? E9 ?? ?? ?? ?? CC",
    }
    local PRECACHE_SIG = "40 53 55 57 48 81 EC 80 00 00 00 48 8B 01 49 8B E8 48 8B FA"
    local fnSetModel, fnPrecache, fnInsert, resourceSystem, entityRva
    local tick, applyAt, pendingReason, pendingFreshPawn = 0, nil, nil, false
    local finalizingRefresh = false
    local wasAlive, lastPawnKey, lastAppliedKey, lastAppliedAt = nil, nil, nil, -100000
    local APPLY_DELAY, ROUND_DELAY = 1.0, 2.0
    local REFRESH_DELAY, DUPLICATE_WINDOW = 0.45, 2.0

    local function valid(p)
        return type(p) == "number" and p > 0x10000 and p < 0x7FFFFFFFFFFF
    end
    local function ri32(a) return tonumber(ffi.cast("int32_t*", a)[0]) end
    local function rptr(a) return tonumber(ffi.cast("uint64_t*", a)[0]) end

    local function resolve()
        local base = mem.GetModuleBase(CLIENT)
        if not base then return false end
        if not entityRva then
            for _, pattern in ipairs(ENTITY_SIGS) do
                local hit = mem.FindPattern(CLIENT, pattern)
                if hit and hit ~= 0 then
                    hit = tonumber(hit)
                    entityRva = (hit + 7 + ri32(hit + 3)) - base
                    break
                end
            end
        end
        if not fnSetModel then
            local hit = mem.FindPattern(CLIENT, SETMODEL_SIG)
            if hit and hit ~= 0 then
                fnSetModel = ffi.cast("void(*)(void*, const char*)", hit)
            end
        end
        return entityRva ~= nil and fnSetModel ~= nil
    end

    local function resolvePrecache()
        if fnPrecache and fnInsert and resourceSystem then return true end
        local hit = mem.FindPattern("resourcesystem.dll", PRECACHE_SIG)
        if hit and hit ~= 0 then
            fnPrecache = ffi.cast("void*(*)(void*, void*, const char*)", hit)
        end
        pcall(function()
            local rs = ffi.C.GetModuleHandleA("resourcesystem.dll")
            local ci = rs ~= nil and ffi.C.GetProcAddress(rs, "CreateInterface") or nil
            if ci ~= nil then
                resourceSystem = ffi.cast("void*(*)(const char*, int*)", ci)("ResourceSystem013", nil)
            end
        end)
        pcall(function()
            local t0 = ffi.C.GetModuleHandleA("tier0.dll")
            local address = t0 ~= nil and ffi.C.GetProcAddress(
                t0, "?Insert@CBufferString@@QEAAPEBDHPEBDH_N@Z"
            ) or nil
            if address ~= nil then
                fnInsert = ffi.cast("const char*(*)(void*, int, const char*, int, int)", address)
            end
        end)
        return fnPrecache ~= nil and fnInsert ~= nil and resourceSystem ~= nil
    end

    local function precache(path)
        -- Keep the resource alive by precaching immediately before SetModel.
        -- This function is reached only after a respawn/round event and cooldown.
        if not resolvePrecache() then return false end
        local buffer = ffi.new("RGN_CBufferString")
        buffer.length, buffer.allocated, buffer.data.p = 0, 0xC0000008, nil
        local ok = pcall(function()
            fnInsert(buffer, 0, path, -1, 0)
            fnPrecache(resourceSystem, buffer, "")
        end)
        return ok
    end

    local function rawEntity(index)
        if not index or index <= 0 or index > 0x7FFF or not resolve() then return nil end
        local base = mem.GetModuleBase(CLIENT)
        local list = base and rptr(base + entityRva) or nil
        if not valid(list) then return nil end
        local chunk = rptr(list + 8 * rshift(index, 9) + 16)
        if not valid(chunk) then return nil end
        local entity = rptr(chunk + 112 * band(index, 0x1FF))
        if valid(entity) and valid(rptr(entity)) then return entity end
        return nil
    end

    -- CS2 separates the local controller from its current pawn. A team change
    -- can replace the pawn without producing a visible alive -> dead -> alive
    -- transition, so SetModel must always target and observe GetLocalPawn.
    local function localPawn()
        local getter = type(entities.GetLocalPawn) == "function"
            and entities.GetLocalPawn or entities.GetLocalPlayer
        local ok, pawn = pcall(getter)
        return ok and pawn or nil
    end

    local function clock()
        local ok, value = pcall(function()
            return globals and globals.RealTime and globals.RealTime()
        end)
        return ok and tonumber(value) or (tick / 64)
    end

    local function pawnState()
        local pawn = localPawn()
        if not pawn then return nil, false, nil end
        local alive, index, team = false, nil, nil
        pcall(function() alive = pawn:IsAlive() end)
        pcall(function() index = pawn:GetIndex() end)
        pcall(function() team = pawn:GetTeamNumber() end)
        if not alive or type(index) ~= "number" or index <= 0 then
            return pawn, false, nil
        end
        return pawn, true, tostring(index) .. ":" .. tostring(team or 0)
    end

    local function scheduleApply(reason, freshPawn, delay)
        if not SetModel.path then return end
        if RGN_MULTI.characterMode ~= "custom" then
            SetModel.phase = "custom characters disabled"
            return
        end
        -- Several events can describe the same spawn. A confirmed new pawn
        -- restarts the delay so SetModel runs after that pawn is fully ready.
        local wait = delay or APPLY_DELAY
        if freshPawn or not applyAt then applyAt = clock() + wait end
        if freshPawn then finalizingRefresh = false end
        pendingFreshPawn = pendingFreshPawn or (freshPawn and true or false)
        pendingReason = reason or "spawn detected"
        SetModel.phase = pendingReason .. "; " .. tostring(wait) .. "s safety delay"
    end

    local function isLocalEvent(event)
        if not client or not client.GetPlayerIndexByUserID or not client.GetLocalPlayerIndex then
            return false
        end
        local userid, playerIndex, localIndex
        pcall(function() userid = event:GetInt("userid") end)
        if not userid or userid == 0 then return false end
        pcall(function() playerIndex = client.GetPlayerIndexByUserID(userid) end)
        pcall(function() localIndex = client.GetLocalPlayerIndex() end)
        return type(playerIndex) == "number" and playerIndex > 0
            and type(localIndex) == "number" and localIndex > 0
            and playerIndex == localIndex
    end

    local function savePath(path)
        local ok = false
        pcall(function()
            local f = file.Open(MODEL_CONFIG_FILE, "w")
            if f then f:Write(path or ""); f:Close(); ok = true end
        end)
        return ok
    end

    local function loadPath()
        local value
        pcall(function()
            local f = file.Open(MODEL_CONFIG_FILE, "r")
            if f then value = f:Read(); f:Close() end
        end)
        if type(value) ~= "string" then return nil end
        value = value:gsub("^%s+", ""):gsub("%s+$", ""):gsub("\\", "/")
        return value:lower():match("%.vmdl$") and value or nil
    end

    function SetModel.SetPath(path)
        if path ~= nil and path ~= "" then
            path = tostring(path):gsub("\\", "/")
            if not path:lower():match("%.vmdl$") then return false, "invalid .vmdl path" end
        else
            path = nil
        end
        -- A newly selected path must never inherit a pending respawn timer from
        -- the previous model. It waits for the next safe spawn/round event.
        applyAt, pendingReason, pendingFreshPawn = nil, nil, false
        finalizingRefresh = false
        local persisted = savePath(path)
        SetModel.path, SetModel.error = path, nil
        SetModel.persistence = persisted
        SetModel.phase = path and "queued; waiting for death/respawn or next round" or "override off"
        if persisted then return true end
        return true, "could not save " .. MODEL_CONFIG_FILE
    end

    function SetModel.ApplyNow(forceFinal)
        if not SetModel.path then return true end
        if RGN_MULTI.characterMode ~= "custom" then
            SetModel.phase = "custom characters disabled"
            return true
        end
        local player = localPawn()
        if not player then return false, "local pawn unavailable" end
        local alive = false
        pcall(function() alive = player:IsAlive() end)
        if not alive then return false, "local player is not alive" end
        local current
        pcall(function() current = player:GetModelName() end)
        if type(current) == "string" and current ~= "" and current ~= SetModel.path
            and current ~= SetModel.lastAppliedPath and current:lower():match("%.vmdl$") then
            SetModel.original = current
        end
        local index
        pcall(function() index = player:GetIndex() end)
        local entity = rawEntity(index)
        if not valid(entity) or entity % 8 ~= 0 then return false, "invalid local-player pointer" end

        -- Source 2 can keep the custom model name while losing its renderable
        -- after a round reset. Setting the identical path is then a no-op. A
        -- brief switch to the last real team model forces a clean rebuild.
        if not forceFinal and current == SetModel.path and type(SetModel.original) == "string"
            and SetModel.original ~= SetModel.path then
            local resetOk, resetErr = pcall(function()
                fnSetModel(ffi.cast("void*", entity), SetModel.original)
            end)
            if not resetOk then return false, tostring(resetErr) end
            SetModel.phase = "refreshing renderable; 0.45s safety delay"
            return true, "refresh_pending"
        end

        if not precache(SetModel.path) then
            return false, "model precache failed"
        end
        local applied, err = pcall(function()
            fnSetModel(ffi.cast("void*", entity), SetModel.path)
        end)
        if not applied then return false, tostring(err) end
        SetModel.lastAppliedPath = SetModel.path
        SetModel.phase = "active"
        return true
    end

    function SetModel.GetPath() return SetModel.path end
    SetModel.path = loadPath()
    if SetModel.path then SetModel.phase = "queued; waiting for death/respawn or next round" end
    if not resolve() then setModelError = "SetModel signature not found" end
    pcall(resolvePrecache)

    pcall(function()
        if client and client.AllowListener then
            client.AllowListener("player_spawn")
            client.AllowListener("player_team")
            client.AllowListener("round_start")
            client.AllowListener("game_newmap")
            client.AllowListener("server_spawn")
            client.AllowListener("cs_game_disconnected")
        end
    end)

    pcall(function()
        callbacks.Register("FireGameEvent", "rgnMultitool_SkinsEvents", function(event)

            local name
            pcall(function() name = event:GetName() end)
            if name == "game_newmap" or name == "server_spawn" or name == "cs_game_disconnected" then
                applyAt, pendingReason, pendingFreshPawn = nil, nil, false
                finalizingRefresh = false
                wasAlive = nil
                lastPawnKey, lastAppliedKey, lastAppliedAt = nil, nil, -100000
            end
            if name == "round_start" or name == "game_newmap" or name == "server_spawn" then
                local reason = name == "server_spawn" and "new server detected"
                    or (name == "game_newmap" and "new map detected" or "round detected")
                scheduleApply(reason, true, ROUND_DELAY)
            elseif name == "player_spawn" and isLocalEvent(event) then
                scheduleApply("local spawn event", true)
            elseif name == "player_team" and isLocalEvent(event) then
                -- Do not apply to the old pawn while the team transition is in
                -- progress. player_spawn or the pawn watcher schedules the call
                -- as soon as the replacement pawn is alive.
                if lastAppliedKey and lastPawnKey and lastPawnKey ~= lastAppliedKey then
                    scheduleApply("new team pawn detected", true)
                else
                    applyAt, pendingReason, pendingFreshPawn = nil, nil, false
                    finalizingRefresh = false
                    SetModel.phase = "team change detected; waiting for new pawn"
                end
            end
        end)
    end)

    RGN_MULTI.suspendCustomModel = function()
        applyAt, pendingReason, pendingFreshPawn = nil, nil, false
        finalizingRefresh = false
        if SetModel.path then SetModel.phase = "custom characters disabled" end
    end

    callbacks.Register("CreateMove", "rgnMultitool_SkinsSpawnWatch", function()
        tick = tick + 1
        if tick % 8 == 0 then
            local _, alive, pawnKey = pawnState()
            if alive and (wasAlive ~= true or pawnKey ~= lastPawnKey) then
                scheduleApply(wasAlive == nil and "saved model detected"
                    or (wasAlive ~= true and "respawn detected" or "new pawn/team detected"), true)
            end
            wasAlive = alive
            if pawnKey then lastPawnKey = pawnKey end
        end
        if applyAt and SetModel.path and RGN_MULTI.characterMode == "custom" and clock() >= applyAt then
            local _, alive, pawnKey = pawnState()
            if not alive or not pawnKey then
                -- Do not touch a controller or a pawn that is not ready. The
                -- next alive/new-pawn observation schedules a fresh safe call.
                applyAt, pendingReason, pendingFreshPawn = nil, nil, false
                finalizingRefresh = false
                SetModel.phase = "spawn event received; waiting for live pawn"
            else
                local now = clock()
                local freshPawn = pendingFreshPawn
                applyAt, pendingReason, pendingFreshPawn = nil, nil, false
                if not freshPawn and pawnKey == lastAppliedKey and now - lastAppliedAt < DUPLICATE_WINDOW then
                    SetModel.phase = "active; duplicate spawn event ignored"
                else
                    local forceFinal = finalizingRefresh
                    finalizingRefresh = false
                    local callOk, applyOk, err = pcall(SetModel.ApplyNow, forceFinal)
                    if callOk and applyOk then
                        if err == "refresh_pending" then
                            applyAt = clock() + REFRESH_DELAY
                            pendingReason = "finalizing model refresh"
                            pendingFreshPawn = true
                            finalizingRefresh = true
                            SetModel.error = nil
                        else
                            lastAppliedKey, lastAppliedAt = pawnKey, now
                            SetModel.error = nil
                        end
                    else
                        SetModel.error = tostring(err or applyOk)
                        SetModel.phase = "apply failed; waiting for next spawn"
                        print("[rgnSkins] spawn apply failed: " .. SetModel.error)
                    end
                end
            end
        end
    end)

    pcall(function()
        callbacks.Register("Unload", "rgnMultitool_SkinsUnload", function()
            pcall(callbacks.Unregister, "FireGameEvent", "rgnMultitool_SkinsEvents")
            pcall(callbacks.Unregister, "CreateMove", "rgnMultitool_SkinsSpawnWatch")
        end)
    end)
end

if setModelError then print("[rgnSkins:LITE] " .. setModelError) end
local savedCharacter = SetModel.GetPath and SetModel.GetPath() or nil

-- Runtime catalogue: populated only from filenames inside csgo/characters.
-- No model or material contents are opened.
local VALIDATED_MODELS = {}

local BLOCKED_MODEL_PATHS = {
    ["characters/models/exg/wesker/wesker.vmdl"] = true, -- confirmed ResourceSystem crash
}

local CATEGORY_NAMES = {
    "All models",
    "Anime / game girls",
    "Touhou Project",
    "Blue Archive",
    "VTuber / Vocaloid",
    "Resident Evil / horror",
    "Other / creatures",
}

local TOUHOU = {
    alice=true, chen=true, cirno=true, clown_piece=true, daiyouse=true,
    devildom_fairy=true, eternity_larva=true, flandre=true, flandre_scarlet=true,
    fortune_teller=true, hieda_no_akyuu=true, ibuki_suika=true,
    imaizumi_kagerou=true, kogasa=true, kogasa_tatara=true, koishi=true,
    kyoko_youmu=true, letty=true, lily_black=true, lily_white=true, marisa=true,
    momiji=true, morichika_rinnosuke=true, motoori_kosuzu_nohitbox=true,
    okunoda_miyoi=true, penglai=true, reimu=true, remilia=true,
    remilia_scarlet=true, rumia=true, sanae=true, satori=true,
    seiga_nyannyan=true, shanghai=true, shinki=true, youmu=true,
    zombie_fairy=true, maid_fairy=true, normal_fairy=true,
}

local BLUE_ARCHIVE = {
    arona=true, hina=true, hoshino=true, hoshino_hinata=true, maid_midori=true,
    maid_momoi=true, midori=true, mika=true, mika_sheep=true, momoi=true,
    plana=true, professor_niyaniya=true, seia=true, serina=true, shiroko=true,
}

local VTUBER = {
    flare=true, koyori=true, lami=true, minato_aqua_sailor=true, mio=true,
    miku=true, miku2=true, snow_miku=true, watame=true,
}

local OTHER = {
    bahamut=true, banana=true, cat=true, nvboss=true, swordbahamut=true,
    trollman=true, tungtungtungsahur=true,
}

local HORROR_WORDS = {
    "zombie", "headcrab", "mutation", "regenerador", "wesker",
    "resident", "undead", "monster", "nvboss",
}

local function modelCategory(item)
    local name = tostring(item.name or ""):lower()
    local haystack = name .. " " .. tostring(item.path or ""):lower()
    for _, word in ipairs(HORROR_WORDS) do
        if haystack:find(word, 1, true) then return 6 end
    end
    if TOUHOU[name] then return 3 end
    if BLUE_ARCHIVE[name] then return 4 end
    if VTUBER[name] then return 5 end
    if OTHER[name] then return 7 end
    return 2
end

-- Build the character list once at startup.
pcall(function() ffi.cdef[[
    typedef struct {
        uint32_t attributes;
        uint32_t creation_lo, creation_hi;
        uint32_t access_lo, access_hi;
        uint32_t write_lo, write_hi;
        uint32_t size_hi, size_lo;
        uint32_t reserved0, reserved1;
        char filename[260];
        char alternate[14];
    } RGN_CHARACTER_FIND_DATA;
]] end)

-- Resolve WinAPI functions as private pointers. Declaring FindFirstFileA in
-- ffi.cdef makes all Aimware Luas share one global C signature; another script
-- using its own WIN32_FIND_DATA typedef can then make this entire cdef fail.
local findFirstA, findNextA, findClose, getCurrentDirectoryA, getModuleFileNameA
pcall(function()
    local kernel32 = ffi.C.GetModuleHandleA("kernel32.dll")
    local function address(name) return ffi.C.GetProcAddress(kernel32, name) end
    findFirstA = ffi.cast("void*(*)(const char*, void*)", address("FindFirstFileA"))
    findNextA = ffi.cast("int(*)(void*, void*)", address("FindNextFileA"))
    findClose = ffi.cast("int(*)(void*)", address("FindClose"))
    getCurrentDirectoryA = ffi.cast("uint32_t(*)(uint32_t, char*)", address("GetCurrentDirectoryA"))
    getModuleFileNameA = ffi.cast("uint32_t(*)(void*, char*, uint32_t)", address("GetModuleFileNameA"))
end)

local function invalidFindHandle()
    return ffi.cast("void*", ffi.cast("intptr_t", -1))
end

local function deriveCsgoRoot(path)
    if type(path) ~= "string" or path == "" then return nil end
    local normalized = path:gsub("/", "\\")
    local lower = normalized:lower()
    if lower:sub(-5) == "\\csgo" then return normalized end

    local executableSuffix = "\\bin\\win64\\cs2.exe"
    if lower:sub(-#executableSuffix) == executableSuffix then
        return normalized:sub(1, #normalized - #executableSuffix) .. "\\csgo"
    end

    local binMarker = "\\bin\\win64"
    local markerAt = lower:find(binMarker, 1, true)
    if markerAt then return normalized:sub(1, markerAt - 1) .. "\\csgo" end
    return nil
end

local function charactersGameRoot()
    if not getCurrentDirectoryA or not getModuleFileNameA then return nil end
    local buffer = ffi.new("char[1024]")
    local count = getCurrentDirectoryA(1024, buffer)
    if count and count > 0 and count < 1024 then
        local cwd = ffi.string(buffer, count)
        local root = deriveCsgoRoot(cwd)
        if root then return root end
    end
    count = getModuleFileNameA(nil, buffer, 1024)
    if count and count > 0 and count < 1024 then
        local executable = ffi.string(buffer, count)
        local root = deriveCsgoRoot(executable)
        if root then return root end
    end
    return nil
end

local function listCharacterModels(directory, root, output)
    if not findFirstA or not findNextA or not findClose then return end
    local data = ffi.new("RGN_CHARACTER_FIND_DATA")
    local handle = findFirstA(directory .. "\\*", data)
    if handle == invalidFindHandle() then return end
    repeat
        local name = ffi.string(data.filename)
        if name ~= "." and name ~= ".." then
            local full = directory .. "\\" .. name
            if bit_.band(tonumber(data.attributes), 0x10) ~= 0 then
                listCharacterModels(full, root, output)
            elseif name:lower():sub(-7) == ".vmdl_c" then
                local relative = full:sub(#root + 2):gsub("\\", "/")
                local sourcePath = relative:sub(1, #relative - 2)
                if not BLOCKED_MODEL_PATHS[sourcePath:lower()] then
                    output[#output + 1] = {
                        name = name:sub(1, #name - 7),
                        path = sourcePath,
                    }
                end
            end
        end
    until findNextA(handle, data) == 0
    findClose(handle)
end

local root
if type(ffi) == "table" and type(bit_) == "table" then
    local rootOk, resolvedRoot = pcall(charactersGameRoot)
    if rootOk then root = resolvedRoot end
    if root then
        local ok, err = pcall(listCharacterModels, root .. "\\characters", root, VALIDATED_MODELS)
        if not ok then
            VALIDATED_MODELS = {}
            print("[rgnSkins] characters listing failed: " .. tostring(err))
        end
    else
        print("[rgnSkins] game/csgo/characters could not be resolved on this PC")
    end
else
    print("[rgnSkins] FFI unavailable: enable 'Allow insecure FFI' and rerun")
end

table.sort(VALIDATED_MODELS, function(a, b)
    local an, bn = a.name:lower(), b.name:lower()
    return an == bn and a.path:lower() < b.path:lower() or an < bn
end)
if #VALIDATED_MODELS == 0 then
    print("[rgnSkins] SETUP: copy the complete game/csgo/characters folder, enable game scripting + insecure FFI, then rerun")
end

-- Only restore paths that still exist in this PC's local catalogue. The spawn
-- watcher reapplies the selection after a new pawn, team, round or map.
local savedCharacterIndex
if savedCharacter then
    for i, item in ipairs(VALIDATED_MODELS) do
        if item.path == savedCharacter then
            savedCharacterIndex = i
            break
        end
    end
    if not savedCharacterIndex then
        print("[rgnSkins] saved character is no longer in the validated catalogue")
        savedCharacter = nil
        if SetModel.SetPath then pcall(SetModel.SetPath, nil) end
    end
end

if savedCharacter then
    print("[rgnSkins] restored saved character: " .. savedCharacter)
end

local function catalogue(query, categoryIndex)
    local names, paths = {}, {}
    query = tostring(query or ""):lower()
    categoryIndex = tonumber(categoryIndex) or 1
    for _, item in ipairs(VALIDATED_MODELS) do
        local categoryMatch = categoryIndex == 1 or modelCategory(item) == categoryIndex
        local queryMatch = query == "" or item.name:lower():find(query, 1, true)
                or item.path:lower():find(query, 1, true)
        if categoryMatch and queryMatch then
            names[#names + 1] = item.name
            paths[#paths + 1] = item.path
        end
    end
    if #names == 0 then names[1] = "[ no character models found ]"; paths[1] = "" end
    return names, paths
end

local tab = M:Tab("SKINS CUSTOM")
tab:Row()
local listSection = tab:Section("Character skins")
local initialNames, initialPaths = catalogue("")
local modelList = listSection:Listbox("", initialNames, "fill", 1)
local modelWidget = listSection.ws[#listSection.ws]
local modelPaths = initialPaths
if savedCharacterIndex then
    modelWidget.value = savedCharacterIndex
    modelWidget.scroll = math.max(0, savedCharacterIndex - 4)
end

tab:Col()
local searchSection = tab:Section("Catalogue")
local category = searchSection:Combo("Category", CATEGORY_NAMES, 1)
local filter = searchSection:Input("Search", "", "character name...")
searchSection:Button("Apply category / search", function()
    local names, paths = catalogue(filter:Get(), category:Get())
    if not names then
        M:Notify("catalogue filter failed: " .. tostring(paths), "error")
        return
    end
    modelPaths = paths
    modelWidget.items = names
    modelWidget.value = 1
    modelWidget.scroll = 0
    M:Notify("character models found: " .. tostring(paths[1] == "" and 0 or #paths), "success")
end)

local infoSection = tab:Section("Selected character")
local customEnabledToggle = infoSection:Checkbox("Enable custom characters", RGN_MULTI.customEnabled)
RGN_MULTI.setCustomEnabled = function(enabled)
    customEnabledToggle:Set(enabled and true or false)
end
local lastCustomEnabled = customEnabledToggle:Get()
M:OnFrame(function()
    local enabled = customEnabledToggle:Get()
    if enabled ~= lastCustomEnabled then
        lastCustomEnabled = enabled
        if enabled then
            RGN_MULTI.activateCustom("custom characters enabled")
        else
            RGN_MULTI.disableCustom("custom characters disabled")
        end
    end
end)

infoSection:Button("Save for every spawn / team", function()
    local path = modelPaths[modelList:Get() or 1] or ""
    if path == "" then M:Notify("select a character first", "error"); return end
    if not SetModel.SetPath or setModelError then
        M:Notify("SetModel unavailable; check console", "error")
        print("[rgnSkins] SetModel error: " .. tostring(setModelError))
        return
    end
    local callOk, savedOk, result = pcall(SetModel.SetPath, path)
    if not callOk or not savedOk then
        print("[rgnSkins] SetModel error: " .. tostring(result))
        M:Notify(tostring(result or "SetModel save failed"), "error")
        return
    end
    savedCharacter = path
    RGN_MULTI.activateCustom("custom character selected")
    print("[rgnSkins] local model saved for every spawn/team: " .. path)
    if result then
        print("[rgnSkins] warning: " .. tostring(result))
        M:Notify("queued for this session; config was not saved", "info")
    else
        M:Notify("saved; applies 1s after every spawn", "success")
    end
end)

infoSection:Button("Turn model override OFF", function()
    if not SetModel.SetPath or setModelError then M:Notify("SetModel unavailable", "error"); return end
    local callOk, savedOk, err = pcall(SetModel.SetPath, nil)
    if not callOk or not savedOk then
        print("[rgnSkins] SetModel OFF error: " .. tostring(err))
        M:Notify("failed to disable model", "error")
        return
    end
    savedCharacter = nil
    RGN_MULTI.disableCustom("custom model cleared")
    if err then
        print("[rgnSkins] warning: " .. tostring(err))
        M:Notify("override disabled; config could not be updated", "info")
    else
        M:Notify("saved model cleared; respawn to restore", "info")
    end
end)

infoSection:Button("Show model path", function()
    local path = modelPaths[modelList:Get() or 1] or ""
    if path == "" then M:Notify("select a character first", "error"); return end
    print("[rgnSkins] selected character: " .. path)
    M:Notify("path printed in console", "info")
end)

local safetySection = tab:Section("Status")
safetySection:Button("Safe timing: spawn 1s / round 2s", function()
    M:Notify("one two-stage render refresh per round", "info")
end)
safetySection:Button("Portable status / requirements", function()
    if setModelError then
        M:Notify("SetModel unavailable; check console", "error")
    elseif #VALIDATED_MODELS == 0 then
        M:Notify("no models: copy the complete csgo/characters folder", "error")
    elseif not SetModel.persistence then
        M:Notify(tostring(#VALIDATED_MODELS) .. " models | enable file permission to save", "info")
    else
        M:Notify(tostring(#VALIDATED_MODELS) .. " models | portable setup ready", "success")
    end
end)
end)

loadModule("VIEWMODEL", function()
local M = M
local M = M
-- Lightweight XYZ-only viewmodel positioning for this CS2 build.

local ffi = rawget(_G, "ffi")
local CONFIG_FILE = "rgnmultitool_viewmodel.txt"
local DEFAULT = { enabled = false, knifeLeft = false, x = 1.0, y = 1.0, z = -1.0 }
local original = { x = DEFAULT.x, y = DEFAULT.y, z = DEFAULT.z, preset = 1 }
local status = "ready"
local lastApply, lastSignature, lastSave = -100, "", -100
local lastEnabled, lastExtended = false, false
local knifeLeftOwned, knifeHandWasAlive = false, false
local knifeHandStatus = "disabled"

-- Femboytap's additive XYZ hook is useful, but upstream disabled automatic
-- installation after an execute-AV regression. This version is opt-in and
-- refuses to patch unless the call site, target and current bytes all match.
local EXT = {
    installed = false, page = nil, code = nil, match = nil,
    originalTarget = nil, originalRel = nil, lastError = nil,
}
local VM_SIGNATURE = "E8 ?? ?? ?? ?? 48 8B CB E8 ?? ?? ?? ?? 84 C0 74 11 F3 0F 10 45 B0"
local VM_AFTER = { 0x48, 0x8B, 0xCB, 0xE8, -1, -1, -1, -1, 0x84, 0xC0, 0x74, 0x11, 0xF3, 0x0F, 0x10, 0x45, 0xB0 }
local VM_TARGET_PROLOGUE = { 0x40, 0x55, 0x53, 0x56, 0x41, 0x56, 0x41, 0x57, 0x48, 0x8B, 0xEC, 0x48, 0x83, 0xEC, 0x20 }

local function clock()
    local value = 0
    pcall(function() value = globals.RealTime() end)
    return tonumber(value) or 0
end

local function clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function loadConfig()
    local values = {}
    pcall(function()
        local handle = file.Open(CONFIG_FILE, "r")
        if not handle then return end
        local data = handle:Read(); handle:Close()
        for line in tostring(data or ""):gmatch("[^\r\n]+") do
            local key, value = line:match("^([%w_]+)=(.*)$")
            if key then values[key] = value end
        end
    end)
    return values
end

local function readConVar(name, fallback)
    local value
    pcall(function()
        if client and type(client.GetConVar) == "function" then value = client.GetConVar(name) end
    end)
    return tonumber(value) or fallback
end

local function setConVar(name, value)
    local text = type(value) == "number" and string.format("%.3f", value) or tostring(value)
    local apiOk, commandOk = false, false
    pcall(function()
        if client and type(client.SetConVar) == "function" then
            local result = client.SetConVar(name, text, true)
            apiOk = result ~= false
        end
    end)
    commandOk = pcall(function() client.Command(name .. " " .. text, true) end)
    return apiOk or commandOk
end

local function pointer(value)
    value = tonumber(value)
    if value and value > 0x10000 and value < 0x7FFFFFFFFFFF then return value end
    return nil
end

local function prepareFfi()
    if type(ffi) ~= "table" then return false, "Aimware FFI is unavailable" end
    local ok = pcall(function() ffi.cdef [[
        void* VirtualAlloc(void*, size_t, uint32_t, uint32_t);
        int VirtualProtect(void*, size_t, uint32_t, uint32_t*);
        void* GetCurrentProcess(void);
        int FlushInstructionCache(void*, void*, size_t);
    ]] end)
    -- Re-declaring an existing cdef can fail even though the functions are ready.
    if not ok then
        local probe = pcall(function() return ffi.C.GetCurrentProcess() end)
        if not probe then return false, "Windows memory API is unavailable" end
    end
    return true
end

local function r_u8(address) return tonumber(ffi.cast("uint8_t*", address)[0]) end
local function r_i32(address) return tonumber(ffi.cast("int32_t*", address)[0]) end
local function w_u8(address, value) ffi.cast("uint8_t*", address)[0] = value end
local function w_i32(address, value) ffi.cast("int32_t*", address)[0] = value end
local function w_f32(address, value) ffi.cast("float*", address)[0] = value end

local function sameBytes(address, expected)
    for index = 1, #expected do
        local wanted = expected[index]
        if wanted >= 0 and r_u8(address + index - 1) ~= wanted then return false end
    end
    return true
end

local function le64(value)
    local bytes = {}
    for _ = 1, 8 do
        bytes[#bytes + 1] = value % 256
        value = math.floor(value / 256)
    end
    return bytes
end

local function moduleRange()
    if not (mem and type(mem.GetModuleBase) == "function") then return nil, nil end
    local base = pointer(mem.GetModuleBase("client.dll"))
    if not base then return nil, nil end
    local pe = tonumber(ffi.cast("uint32_t*", base + 0x3C)[0])
    if not pe or pe < 0x40 or pe > 0x100000 then return nil, nil end
    local size = tonumber(ffi.cast("uint32_t*", base + pe + 0x50)[0])
    if not size or size < 0x100000 or size > 0x40000000 then return nil, nil end
    return base, base + size
end

local function validateSite()
    local ok, reason = prepareFfi()
    if not ok then return nil, nil, reason end
    if not (mem and type(mem.FindPattern) == "function") then
        return nil, nil, "Aimware pattern API is unavailable"
    end
    local base, finish = moduleRange()
    if not base then return nil, nil, "client.dll range could not be validated" end
    local match = pointer(mem.FindPattern("client.dll", VM_SIGNATURE))
    if not match then return nil, nil, "current CS2 build does not match the validated signature" end
    if match < base or match + 22 >= finish or r_u8(match) ~= 0xE8 then
        return nil, nil, "signature address is outside client.dll"
    end
    if not sameBytes(match + 5, VM_AFTER) then
        return nil, nil, "viewmodel call-site bytes changed"
    end
    local original = match + 5 + r_i32(match + 1)
    if original < base or original + #VM_TARGET_PROLOGUE >= finish then
        return nil, nil, "viewmodel target is outside client.dll"
    end
    if not sameBytes(original, VM_TARGET_PROLOGUE) then
        return nil, nil, "viewmodel target prologue changed"
    end
    return match, original
end

local function allocNear(target, size)
    local granularity = 0x10000
    local base = target - (target % granularity)
    for index = 1, 4096 do
        local low, high = base - index * granularity, base + index * granularity
        if low > 0x10000 then
            local p = ffi.C.VirtualAlloc(ffi.cast("void*", low), size, 0x3000, 0x40)
            local address = pointer(ffi.cast("uintptr_t", p))
            if address then return address end
        end
        local p = ffi.C.VirtualAlloc(ffi.cast("void*", high), size, 0x3000, 0x40)
        local address = pointer(ffi.cast("uintptr_t", p))
        if address then return address end
    end
    local p = ffi.C.VirtualAlloc(nil, size, 0x3000, 0x40)
    return pointer(ffi.cast("uintptr_t", p))
end

local function patchRel32(match, relative)
    if relative < -2147483648 or relative > 2147483647 then return false, "rel32 overflow" end
    local old = ffi.new("uint32_t[1]")
    if ffi.C.VirtualProtect(ffi.cast("void*", match), 5, 0x40, old) == 0 then
        return false, "VirtualProtect failed"
    end
    w_i32(match + 1, relative)
    local restored = ffi.C.VirtualProtect(ffi.cast("void*", match), 5, old[0], old) ~= 0
    pcall(function()
        ffi.C.FlushInstructionCache(ffi.C.GetCurrentProcess(), ffi.cast("void*", match), 5)
    end)
    if not restored then return false, "memory protection restore failed" end
    return true
end

function EXT.install()
    if EXT.installed then return true end
    local match, originalTarget, reason = validateSite()
    if not match then EXT.lastError = reason; return false, reason end

    -- Reconnect a trampoline already owned by this session.
    if EXT.page and EXT.code and EXT.match == match and EXT.originalTarget == originalTarget then
        if r_i32(match + 1) ~= EXT.originalRel then
            return false, "call site is owned by another hook"
        end
        local ok, err = patchRel32(match, EXT.code - (match + 5))
        if not ok then EXT.lastError = err; return false, err end
        EXT.installed, EXT.lastError = true, nil
        return true
    end

    local originalRel = r_i32(match + 1)
    local page = allocNear(match, 0x1000)
    if not page then EXT.lastError = "near executable allocation failed"; return false, EXT.lastError end
    local code = page + 16
    if code - (match + 5) < -2147483648 or code - (match + 5) > 2147483647 then
        EXT.lastError = "allocated trampoline is too far from client.dll"
        return false, EXT.lastError
    end

    local bytes = { 0x53, 0x56, 0x48, 0x83, 0xEC, 0x28, 0x48, 0x89, 0xD6, 0x48, 0xB8 }
    for _, value in ipairs(le64(originalTarget)) do bytes[#bytes + 1] = value end
    for _, value in ipairs({ 0xFF, 0xD0, 0x48, 0xBB }) do bytes[#bytes + 1] = value end
    for _, value in ipairs(le64(page)) do bytes[#bytes + 1] = value end
    for _, value in ipairs({
        0x8B,0x0B, 0x85,0xC9, 0x74,0x2B,
        0xF3,0x0F,0x10,0x4B,0x04, 0xF3,0x0F,0x58,0x0E, 0xF3,0x0F,0x11,0x0E,
        0xF3,0x0F,0x10,0x4B,0x08, 0xF3,0x0F,0x58,0x4E,0x04, 0xF3,0x0F,0x11,0x4E,0x04,
        0xF3,0x0F,0x10,0x4B,0x0C, 0xF3,0x0F,0x58,0x4E,0x08, 0xF3,0x0F,0x11,0x4E,0x08,
        0x48,0x83,0xC4,0x28, 0x5E, 0x5B, 0xC3,
    }) do bytes[#bytes + 1] = value end
    for index = 1, #bytes do w_u8(code + index - 1, bytes[index]) end
    w_i32(page, 0); w_f32(page + 4, 0); w_f32(page + 8, 0); w_f32(page + 12, 0)

    EXT.page, EXT.code, EXT.match = page, code, match
    EXT.originalTarget, EXT.originalRel = originalTarget, originalRel
    local patched, err = patchRel32(match, code - (match + 5))
    if not patched then EXT.lastError = err; return false, err end
    EXT.installed, EXT.lastError = true, nil
    return true
end

function EXT.set(x, y, z)
    if not (EXT.installed and EXT.page) then return false end
    w_i32(EXT.page, 0)
    w_f32(EXT.page + 4, tonumber(x) or 0)
    w_f32(EXT.page + 8, tonumber(y) or 0)
    w_f32(EXT.page + 12, tonumber(z) or 0)
    w_i32(EXT.page, 1)
    return true
end

function EXT.uninstall()
    if EXT.page then pcall(w_i32, EXT.page, 0) end
    if not EXT.installed then return true end
    if not (EXT.match and EXT.originalRel) then return false end
    local current = r_i32(EXT.match + 1)
    local ours = EXT.code - (EXT.match + 5)
    if current ~= ours then
        EXT.installed, EXT.lastError = false, "call site changed before restore"
        return false
    end
    local ok, err = patchRel32(EXT.match, EXT.originalRel)
    EXT.installed, EXT.lastError = false, err
    -- Deliberately never VirtualFree the trampoline: another game thread may
    -- still be returning through it while Unload is restoring the call site.
    return ok
end

-- Extended FOV memory resolver removed after a verified engine2.dll access violation.

original.x = readConVar("viewmodel_offset_x", DEFAULT.x)
original.y = readConVar("viewmodel_offset_y", DEFAULT.y)
original.z = readConVar("viewmodel_offset_z", DEFAULT.z)
original.preset = readConVar("viewmodel_presetpos", 1)

local config = loadConfig()
local tab = M:Tab("VIEWMODEL")
tab:Row()
local control = tab:Section("Viewmodel override")
local enabled = control:Checkbox("Enable viewmodel override", config.enabled == "1")
local extended = control:Checkbox("Extended XYZ (validated hook)", false)
local knifeLeft = control:Checkbox("Knife in left hand", config.knife_left == "1")
local offsetX = control:Slider("Horizontal position (X)", clamp(config.x or DEFAULT.x, -30, 30), -30, 30, 0.1, "%.1f")
local offsetY = control:Slider("Depth position (Y)", clamp(config.y or DEFAULT.y, -30, 30), -30, 30, 0.1, "%.1f")
local offsetZ = control:Slider("Vertical position (Z)", clamp(config.z or DEFAULT.z, -30, 30), -30, 30, 0.1, "%.1f")

tab:Col()
local presets = tab:Section("Presets")
tab:Col()
local actions = tab:Section("Actions")

local function values()
    return clamp(offsetX:Get(), -30, 30), clamp(offsetY:Get(), -30, 30),
        clamp(offsetZ:Get(), -30, 30)
end

local function signature()
    local x, y, z = values()
    return table.concat({
        enabled:Get() and "1" or "0", extended:Get() and "1" or "0", knifeLeft:Get() and "1" or "0",
        x, y, z,
    }, ":")
end

local function saveConfig()
    local x, y, z = values()
    local data = table.concat({
        "enabled=" .. (enabled:Get() and "1" or "0"),
        "knife_left=" .. (knifeLeft:Get() and "1" or "0"),
        "x=" .. tostring(x), "y=" .. tostring(y), "z=" .. tostring(z),
    }, "\n")
    local ok = false
    pcall(function()
        local handle = file.Open(CONFIG_FILE, "w")
        if handle then handle:Write(data); handle:Close(); ok = true end
    end)
    return ok
end

local function apply(force)
    if not enabled:Get() then return false end
    local now, sig = clock(), signature()
    if not force and sig == lastSignature and now - lastApply < 2.50 then return true end
    local x, y, z = values()
    local nativeX = clamp(x, -2.0, 2.5)
    local nativeY = clamp(y, -2.0, 2.0)
    local nativeZ = clamp(z, -2.0, 2.0)
    if extended:Get() then
        local hooked, reason = EXT.install()
        if not hooked then
            extended:Set(false)
            status = "extended mode refused: " .. tostring(reason or EXT.lastError or "validation failed")
            lastSignature = ""
            return false
        end
        EXT.set(x - nativeX, y - nativeY, z - nativeZ)
    else
        EXT.uninstall()
    end
    local ok = setConVar("viewmodel_presetpos", 0)
    ok = setConVar("viewmodel_offset_x", nativeX) and ok
    ok = setConVar("viewmodel_offset_y", nativeY) and ok
    ok = setConVar("viewmodel_offset_z", nativeZ) and ok
    lastApply, lastSignature = now, sig
    local mode = extended:Get() and "extended XYZ" or "native XYZ"
    status = string.format("%s | X %.1f Y %.1f Z %.1f", mode, x, y, z)
    if not ok then status = "partial apply: " .. status end
    return ok
end

local function restore()
    EXT.uninstall()
    local ok = setConVar("viewmodel_offset_x", original.x)
    ok = setConVar("viewmodel_offset_y", original.y) and ok
    ok = setConVar("viewmodel_offset_z", original.z) and ok
    ok = setConVar("viewmodel_presetpos", original.preset) and ok
    lastSignature, status = "", ok and "original viewmodel restored" or "restore failed"
    return ok
end

local function usePreset(x, y, z, name, wantsExtended)
    offsetX:Set(x); offsetY:Set(y); offsetZ:Set(z)
    extended:Set(wantsExtended == true)
    enabled:Set(true)
    local ok = apply(true)
    saveConfig()
    M:Notify(ok and (name .. " preset applied") or status, ok and "success" or "error")
end

presets:Button("Default", function() usePreset(1.0, 1.0, -1.0, "default") end)
presets:Button("Wide / extended", function() usePreset(2.5, 2.0, -1.5, "wide") end)
presets:Button("Centered", function() usePreset(0.0, 0.0, -1.0, "centered") end)
presets:Button("Left side", function() usePreset(-2.0, 1.5, -1.0, "left-side") end)
presets:Button("Compact", function() usePreset(1.0, 1.0, -1.0, "compact") end)
presets:Button("Extreme", function() usePreset(8.0, 8.0, -5.0, "extreme", true) end)

actions:Button("Apply now", function()
    enabled:Set(true)
    local ok = apply(true); saveConfig()
    M:Notify(ok and status or "viewmodel could not be applied", ok and "success" or "error")
end)
actions:Button("Restore original", function()
    enabled:Set(false)
    local ok = restore(); saveConfig()
    M:Notify(status, ok and "success" or "error")
end)
actions:Button("Show current values", function()
    M:Notify(status .. " | knife hand: " .. knifeHandStatus, "info")
end)

local function commandHand(left)
    local ok = pcall(function()
        if not client or type(client.Command) ~= "function" then error("client.Command unavailable") end
        client.Command(left and "switchhandsleft" or "switchhandsright", true)
    end)
    if ok then
        knifeLeftOwned = left == true
        knifeHandStatus = left and "left" or "right"
    else
        knifeHandStatus = "command unavailable"
    end
    return ok
end

local function knifeHandTick()
    if not knifeLeft:Get() then
        if knifeLeftOwned then commandHand(false) end
        knifeHandWasAlive = false
        knifeHandStatus = "disabled"
        return
    end

    local player
    pcall(function() player = entities.GetLocalPlayer() end)
    if not player then
        knifeHandWasAlive = false
        knifeHandStatus = "waiting for player"
        return
    end

    local alive = false
    pcall(function() alive = player:IsAlive() == true end)
    if not alive then
        knifeHandWasAlive = false
        knifeHandStatus = "waiting for spawn"
        return
    end

    local weaponType
    pcall(function() weaponType = tonumber(player:GetWeaponType()) end)
    if weaponType == nil then
        knifeHandWasAlive = false
        knifeHandStatus = "weapon type unavailable"
        return
    end

    local wantsLeft = weaponType == 0
    if not knifeHandWasAlive or wantsLeft ~= knifeLeftOwned then
        knifeHandWasAlive = commandHand(wantsLeft)
    else
        knifeHandWasAlive = true
        knifeHandStatus = wantsLeft and "left" or "right"
    end
end

-- Aimware may discard additional CreateMove callbacks. Route this through the
-- Multitool's proven main command hook, shared with Movement, and emit a hand
-- command only on spawn or weapon transitions.
M._viewmodelCommandActive = function()
    -- Keep one final command tick available after disabling so an owned
    -- left-hand state is restored to the normal right hand immediately.
    return knifeLeft:Get() == true or knifeLeftOwned == true
end
M._viewmodelCommandCallback = function()
    local ok, err = pcall(knifeHandTick)
    if not ok then
        knifeHandWasAlive = false
        knifeHandStatus = "error"
        print("[rgnMultitool] knife-hand error: " .. tostring(err))
    end
end

lastEnabled, lastExtended = enabled:Get(), extended:Get()
M:OnFrame(function()
    local now = clock()
    local on = enabled:Get()
    local ext = extended:Get()
    if on then
        pcall(apply, false)
    elseif lastEnabled then
        pcall(restore)
    elseif EXT.installed then
        pcall(EXT.uninstall)
    end
    lastEnabled, lastExtended = on, ext
    local sig = signature()
    if (sig ~= lastSignature or now - lastSave >= 2.50) and now - lastSave >= 0.50 then
        lastSave = now
        pcall(saveConfig)
    end
end)

pcall(function()
    callbacks.Register("Unload", "rgnMultitool_ViewmodelUnload", function()
        pcall(saveConfig)
        if knifeLeftOwned then pcall(commandHand, false) end
        M._viewmodelCommandCallback = nil
        M._viewmodelCommandActive = nil
        if enabled:Get() then pcall(restore) end
        pcall(EXT.uninstall)
        pcall(callbacks.Unregister, "Unload", "rgnMultitool_ViewmodelUnload")
    end)
end)

end)

loadModule("SCOPE OVERLAY", function()
local M = M
local CONFIG_FILE = "rgnscope_config.txt"
-- Aimware exposes the two native scope layers separately:
--   world.noscope        -> removes the game's scope presentation
--   world.noscopeoverlay -> draws Aimware's full-screen replacement cross lines
-- Our custom overlay needs the first enabled and the second disabled.
local NO_SCOPE_KEY = "world.noscope"
local NATIVE_OVERLAY_KEY = "world.noscopeoverlay"
local config = {}

local timeSource
if common and type(common.Time) == "function" then timeSource = common.Time
elseif globals and type(globals.RealTime) == "function" then timeSource = globals.RealTime
elseif globals and type(globals.CurTime) == "function" then timeSource = globals.CurTime end
local function clock()
    if not timeSource then return 0 end
    return tonumber(timeSource()) or 0
end

local function clampValue(value, minimum, maximum)
    value = tonumber(value) or minimum
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function readConfig()
    pcall(function()
        local handle = file.Open(CONFIG_FILE, "r")
        if not handle then return end
        local body = handle:Read() or ""
        handle:Close()
        for line in body:gmatch("[^\r\n]+") do
            local key, value = line:match("^([%w_]+)%s*=%s*(.-)%s*$")
            if key then config[key] = value end
        end
    end)
end

local function cfgBool(key, default)
    local value = config[key]
    if value == nil then return default end
    return value == "1" or value == "true"
end

local function cfgColor(key, default)
    local value, result = tostring(config[key] or ""), {}
    for number in value:gmatch("%d+") do result[#result + 1] = clampValue(number, 0, 255) end
    if #result < 3 then return { default[1], default[2], default[3], default[4] or 255 } end
    return { result[1], result[2], result[3], result[4] or 255 }
end

readConfig()

local tab = M:Tab("SCOPE OVERLAY")
tab:Row()
local mainSection = tab:Section("Custom sniper scope")
local enabled = mainSection:Checkbox("Enable scope overlay", cfgBool("enabled", false))
local replaceOriginal = mainSection:Checkbox("Replace original scope", cfgBool("replace", true))

tab:Col()
local appearanceSection = tab:Section("Appearance")
local scopeColor = appearanceSection:ColorPicker("Overlay color", cfgColor("color", { 255, 205, 160, 255 }))

tab:Col()
local scopeState, removalState = "disabled", "original scope unchanged"
local statusSection = tab:Section("Status")
statusSection:Custom(62, function(ui)
    ui.label("Overlay: " .. scopeState, ui.T.text)
    ui.label("Default: " .. removalState, ui.T.textdim)
end)

local function colorValue()
    local value = scopeColor:Get()
    if type(value) ~= "table" then return { 255, 205, 160, 255 } end
    return {
        clampValue(value[1], 0, 255), clampValue(value[2], 0, 255),
        clampValue(value[3], 0, 255), clampValue(value[4] or 255, 0, 255),
    }
end

local function snapshot()
    local color = colorValue()
    return table.concat({
        enabled:Get() and "1" or "0", replaceOriginal:Get() and "1" or "0",
        table.concat(color, ","),
    }, "|")
end

local function saveConfig()
    local color = colorValue()
    pcall(function()
        local handle = file.Open(CONFIG_FILE, "w")
        if not handle then return end
        handle:Write(table.concat({
            "enabled=" .. (enabled:Get() and "1" or "0"),
            "replace=" .. (replaceOriginal:Get() and "1" or "0"),
            "color=" .. table.concat(color, ","),
        }, "\n"))
        handle:Close()
    end)
end

local originalNoScope, originalNativeOverlay, ownsRemoval = nil, nil, false
local lastRemovalEnforce = 0
local function getGuiValue(key)
    local value, ok
    ok = pcall(function() value = gui.GetValue(key) end)
    if not ok then return nil end
    return value
end

local function setGuiValue(key, value)
    return pcall(function() gui.SetValue(key, value) end)
end

local function restoreRemoval()
    if not ownsRemoval then return end
    if originalNoScope ~= nil then pcall(setGuiValue, NO_SCOPE_KEY, originalNoScope) end
    if originalNativeOverlay ~= nil then pcall(setGuiValue, NATIVE_OVERLAY_KEY, originalNativeOverlay) end
    ownsRemoval, originalNoScope, originalNativeOverlay = false, nil, nil
    removalState = "original scope restored"
end

local function syncRemoval(wanted)
    if wanted == nil then wanted = enabled:Get() and replaceOriginal:Get() end
    if wanted and not ownsRemoval then
        local currentNoScope = getGuiValue(NO_SCOPE_KEY)
        local currentNativeOverlay = getGuiValue(NATIVE_OVERLAY_KEY)
        if currentNoScope == nil and currentNativeOverlay == nil then
            removalState = "Aimware removal unavailable; overlay only"
            return
        end
        originalNoScope = currentNoScope
        originalNativeOverlay = currentNativeOverlay
        local scopeOK = currentNoScope == nil or setGuiValue(NO_SCOPE_KEY, true)
        local overlayOK = currentNativeOverlay == nil or setGuiValue(NATIVE_OVERLAY_KEY, false)
        if scopeOK and overlayOK then
            ownsRemoval = true
            lastRemovalEnforce = clock()
            removalState = "native scope + cross lines hidden"
        else
            if originalNoScope ~= nil then pcall(setGuiValue, NO_SCOPE_KEY, originalNoScope) end
            if originalNativeOverlay ~= nil then pcall(setGuiValue, NATIVE_OVERLAY_KEY, originalNativeOverlay) end
            originalNoScope, originalNativeOverlay = nil, nil
            removalState = "Aimware removal refused; overlay only"
        end
    elseif wanted and ownsRemoval then
        -- Config/map changes can restore Aimware's overlay. Reassert at a low
        -- frequency so the native full-screen lines stay off without frame cost.
        local now = clock()
        if now - lastRemovalEnforce >= 0.50 then
            lastRemovalEnforce = now
            if originalNoScope ~= nil and getGuiValue(NO_SCOPE_KEY) ~= true then
                setGuiValue(NO_SCOPE_KEY, true)
            end
            if originalNativeOverlay ~= nil and getGuiValue(NATIVE_OVERLAY_KEY) ~= false then
                setGuiValue(NATIVE_OVERLAY_KEY, false)
            end
        end
        removalState = "native scope + cross lines hidden"
    elseif not wanted and ownsRemoval then
        restoreRemoval()
    elseif not wanted then
        removalState = "original scope unchanged"
    end
end

local SNIPER_IDS = { [9] = true, [11] = true, [38] = true, [40] = true }

local function applyGlowColor(color, alpha, whiteMix)
    whiteMix = whiteMix or 0
    draw.Color(
        math.floor(color[1] + (255 - color[1]) * whiteMix + 0.5),
        math.floor(color[2] + (255 - color[2]) * whiteMix + 0.5),
        math.floor(color[3] + (255 - color[3]) * whiteMix + 0.5),
        math.floor(color[4] * alpha + 0.5)
    )
end

local function fourTaperedSegments(cx, cy, inner, outer, halfWidth)
    -- Each arm is one triangle: its broad end faces the center gap and its
    -- outer end converges to a single pixel instead of a square cap.
    draw.Triangle(cx - inner, cy - halfWidth, cx - inner, cy + halfWidth, cx - outer, cy)
    draw.Triangle(cx + inner, cy - halfWidth, cx + inner, cy + halfWidth, cx + outer, cy)
    draw.Triangle(cx - halfWidth, cy - inner, cx + halfWidth, cy - inner, cx, cy - outer)
    draw.Triangle(cx - halfWidth, cy + inner, cx + halfWidth, cy + inner, cx, cy + outer)
end

local function drawNeverloseGlow(cx, cy, color, alpha)
    -- Fixed Neverlose-inspired geometry: short separated arms, a very thin
    -- luminous core and two soft halo layers. The center dot uses the same
    -- three-pass treatment and also covers the regular game crosshair dot.
    applyGlowColor(color, alpha * 0.075, 0.00)
    fourTaperedSegments(cx, cy, 10, 122, 5)
    draw.FilledCircle(cx, cy, 5)

    applyGlowColor(color, alpha * 0.20, 0.22)
    fourTaperedSegments(cx, cy, 12, 118, 3)
    draw.FilledCircle(cx, cy, 3)

    applyGlowColor(color, alpha * 0.88, 0.76)
    fourTaperedSegments(cx, cy, 15, 112, 1)
    draw.FilledCircle(cx, cy, 2)
end

local renderConfig = {}
local function refreshRenderConfig()
    renderConfig.enabled = enabled:Get() == true
    renderConfig.replace = replaceOriginal:Get() == true
    renderConfig.color = colorValue()
end
refreshRenderConfig()

-- Render the polished scope once as a supersampled SVG texture. This gives
-- the tapered core true sub-pixel antialiasing and lets us stack several
-- translucent bloom/fog layers without paying for them every frame.
local TEXTURE_SIZE, TEXTURE_HALF = 300, 150
local scopeTexture, builtTextureKey = nil, nil
local requestedTextureKey, requestedTextureColor = nil, nil
local textureDirtyAt, nextTextureRetry = 0, 0

local function colorKey(color)
    return table.concat({ color[1], color[2], color[3], color[4] }, ",")
end

local function mixedRGB(color, whiteMix)
    local function channel(value)
        return math.floor(value + (255 - value) * whiteMix + 0.5)
    end
    return string.format("rgb(%d,%d,%d)", channel(color[1]), channel(color[2]), channel(color[3]))
end

local function taperedArmsPath(halfWidth, tipLength)
    local c, inner, outer = TEXTURE_HALF, 17, 112
    local leftInner, leftTip = c - inner, c - outer
    local rightInner, rightTip = c + inner, c + outer
    local topInner, topTip = c - inner, c - outer
    local bottomInner, bottomTip = c + inner, c + outer
    local leftBase, rightBase = leftTip + tipLength, rightTip - tipLength
    local topBase, bottomBase = topTip + tipLength, bottomTip - tipLength
    return table.concat({
        string.format("M %.2f %.2f L %.2f %.2f L %.2f %.2f L %.2f %.2f L %.2f %.2f Z",
            leftInner, c - halfWidth, leftBase, c - halfWidth, leftTip, c,
            leftBase, c + halfWidth, leftInner, c + halfWidth),
        string.format("M %.2f %.2f L %.2f %.2f L %.2f %.2f L %.2f %.2f L %.2f %.2f Z",
            rightInner, c - halfWidth, rightBase, c - halfWidth, rightTip, c,
            rightBase, c + halfWidth, rightInner, c + halfWidth),
        string.format("M %.2f %.2f L %.2f %.2f L %.2f %.2f L %.2f %.2f L %.2f %.2f Z",
            c - halfWidth, topInner, c - halfWidth, topBase, c, topTip,
            c + halfWidth, topBase, c + halfWidth, topInner),
        string.format("M %.2f %.2f L %.2f %.2f L %.2f %.2f L %.2f %.2f L %.2f %.2f Z",
            c - halfWidth, bottomInner, c - halfWidth, bottomBase, c, bottomTip,
            c + halfWidth, bottomBase, c + halfWidth, bottomInner),
    }, " ")
end

local function buildScopeSVG(color)
    local alphaScale = (tonumber(color[4]) or 255) / 255
    local layers = {
        { 16.0, 24, 0.010, 0.00, 14.0 },
        { 11.0, 21, 0.018, 0.02, 10.0 },
        {  7.0, 18, 0.032, 0.06,  7.0 },
        {  4.0, 15, 0.065, 0.14,  4.5 },
        {  2.1, 12, 0.160, 0.32,  2.8 },
        {  0.65, 9, 0.940, 0.78,  1.55 },
    }
    local parts = {
        string.format('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d" shape-rendering="geometricPrecision">',
            TEXTURE_SIZE, TEXTURE_SIZE, TEXTURE_SIZE, TEXTURE_SIZE),
    }
    for i = 1, #layers do
        local layer = layers[i]
        local opacity = layer[3] * alphaScale
        parts[#parts + 1] = string.format('<path d="%s" fill="%s" fill-opacity="%.5f"/>',
            taperedArmsPath(layer[1], layer[2]), mixedRGB(color, layer[4]), opacity)
        parts[#parts + 1] = string.format('<circle cx="%d" cy="%d" r="%.2f" fill="%s" fill-opacity="%.5f"/>',
            TEXTURE_HALF, TEXTURE_HALF, layer[5], mixedRGB(color, layer[4]), opacity)
    end
    parts[#parts + 1] = "</svg>"
    return table.concat(parts)
end

local function rebuildScopeTexture(color, now)
    now = now or clock()
    if not common or type(common.RasterizeSVG) ~= "function" or
       not draw or type(draw.CreateTexture) ~= "function" then
        nextTextureRetry = now + 2.0
        return false
    end
    local key = colorKey(color)
    local ok, rgba, width, height = pcall(common.RasterizeSVG, buildScopeSVG(color), 2)
    if not ok or type(rgba) ~= "string" or not width or not height then
        nextTextureRetry = now + 2.0
        return false
    end
    if scopeTexture and type(draw.UpdateTexture) == "function" then
        local updateOK = pcall(draw.UpdateTexture, scopeTexture, rgba)
        if updateOK then
            builtTextureKey, textureDirtyAt = key, 0
            return true
        end
    end
    local createOK, texture = pcall(draw.CreateTexture, rgba, width, height)
    if createOK and texture then
        scopeTexture, builtTextureKey, textureDirtyAt = texture, key, 0
        return true
    end
    nextTextureRetry = now + 2.0
    return false
end

local function requestScopeTexture(color, now, immediate)
    local key = colorKey(color)
    if key ~= requestedTextureKey then
        requestedTextureKey = key
        requestedTextureColor = { color[1], color[2], color[3], color[4] }
        textureDirtyAt = immediate and now or (now + 0.12)
    end
end

requestScopeTexture(renderConfig.color, clock(), true)
rebuildScopeTexture(requestedTextureColor, clock())

local scopedReaders = {
    function(player) return player:GetFieldBool("m_bIsScoped") end,
    function(player) return player:GetPropBool("m_bIsScoped") end,
    function(player) return player:GetFieldInt("m_bIsScoped") end,
    function(player) return player:GetPropInt("m_bIsScoped") end,
}
local selectedScopedReader = nil
local function readScopedFast(player)
    if selectedScopedReader then
        local ok, value = pcall(selectedScopedReader, player)
        if ok and value ~= nil then return value == true or tonumber(value) == 1 end
        selectedScopedReader = nil
    end
    for i = 1, #scopedReaders do
        local reader = scopedReaders[i]
        local ok, value = pcall(reader, player)
        if ok and value ~= nil then
            selectedScopedReader = reader
            return value == true or tonumber(value) == 1
        end
    end
    return false
end

local function scopedSniperFast()
    local ok, player = pcall(entities.GetLocalPlayer)
    if not ok or not player then return false, "waiting for player" end
    local aliveOK, alive = pcall(function() return player:IsAlive() end)
    if not aliveOK or alive ~= true then return false, "waiting for spawn" end
    local idOK, weaponID = pcall(function() return tonumber(player:GetWeaponID()) end)
    if not idOK or not SNIPER_IDS[weaponID] then return false, "sniper inactive" end
    if not readScopedFast(player) then return false, "not scoped" end
    return true, "active"
end

local fade, lastDrawAt = 0, clock()
local scopeVisible = false
local nextStatePoll, nextRemovalPoll, nextScreenPoll = 0, 0, 0
local screenWidth, screenHeight = 0, 0
M._scopeDrawActive = function()
    -- The menu path keeps configuration/restoration immediate. Once closed,
    -- a fully disabled and fully faded scope has no per-frame work to do.
    return M._open == true or renderConfig.enabled == true or fade >= 0.01
end
M._scopeDrawCallback = function()
    local now = clock()
    local dt = clampValue(now - lastDrawAt, 0, 0.10)
    lastDrawAt = now

    -- Entity/property access is substantially more expensive than drawing.
    -- Twenty checks per second are instant to the eye while avoiding hundreds
    -- of entity calls per second on high-refresh-rate systems.
    if now >= nextStatePoll then
        nextStatePoll = now + 0.05
        if renderConfig.enabled then
            scopeVisible, scopeState = scopedSniperFast()
        else
            scopeVisible, scopeState = false, "disabled"
        end
    end
    if now >= nextRemovalPoll then
        nextRemovalPoll = now + 0.50
        syncRemoval(renderConfig.enabled and renderConfig.replace)
    end

    local target = scopeVisible and 1 or 0
    fade = fade + (target - fade) * math.min(1, dt * 16)
    if fade < 0.01 or M._open then return end

    if now >= nextScreenPoll or screenWidth <= 0 or screenHeight <= 0 then
        nextScreenPoll = now + 2.0
        pcall(function() screenWidth, screenHeight = draw.GetScreenSize() end)
    end
    if not screenWidth or not screenHeight or screenWidth <= 0 or screenHeight <= 0 then return end
    local cx, cy = math.floor(screenWidth / 2), math.floor(screenHeight / 2)
    if textureDirtyAt > 0 and now >= textureDirtyAt and now >= nextTextureRetry then
        rebuildScopeTexture(requestedTextureColor or renderConfig.color, now)
    end
    if scopeTexture and type(draw.SetTexture) == "function" then
        draw.Color(255, 255, 255, math.floor(255 * fade + 0.5))
        draw.SetTexture(scopeTexture)
        draw.FilledRect(cx - TEXTURE_HALF, cy - TEXTURE_HALF,
            cx + TEXTURE_HALF, cy + TEXTURE_HALF)
        pcall(draw.SetTexture, nil)
    else
        drawNeverloseGlow(cx, cy, renderConfig.color, fade)
    end
end

local observed, dirtyAt = snapshot(), nil
M:OnFrame(function()
    refreshRenderConfig()
    syncRemoval(renderConfig.enabled and renderConfig.replace)
    local current = snapshot()
    local now = clock()
    requestScopeTexture(renderConfig.color, now, false)
    if textureDirtyAt > 0 and now >= textureDirtyAt and now >= nextTextureRetry then
        rebuildScopeTexture(requestedTextureColor or renderConfig.color, now)
    end
    if current ~= observed then observed, dirtyAt = current, now + 0.50 end
    if dirtyAt and now >= dirtyAt then saveConfig(); dirtyAt = nil end
end)
syncRemoval()

pcall(function()
    callbacks.Register("Unload", "rgnMultitool_ScopeUnload", function()
        pcall(saveConfig)
        pcall(restoreRemoval)
        pcall(draw.SetTexture, nil)
        scopeTexture = nil
        M._scopeDrawCallback = nil
        M._scopeDrawActive = nil
        pcall(callbacks.Unregister, "Unload", "rgnMultitool_ScopeUnload")
    end)
end)

end)

loadModule("WEAPONS", function()
local M = M
-- rgnWEAPONS - weapon-only frontend for Aimware CS2.
-- The memory engine is loaded separately so rgnSKINS remains untouched.

-- Remove the legacy render guard from earlier builds when this file is
-- reloaded without restarting Aimware.
pcall(function() callbacks.Unregister("Draw", "rgnWEAPONS_LateMesh") end)

-- Pin the repository revision inspected for this build. Its preview changer
-- contains the current weapon/viewmodel mesh handling; character code is
-- disabled below before the engine is executed.
local ENGINE_REV = "957eedf27b832e505656475ee57f91b3b14b4340"
local ENGINE_URL = "https://raw.githubusercontent.com/cachorropacoca/aw_cs2v6_femboytap/" .. ENGINE_REV .. "/preview/femboytap_changer.lua"
local OFFSETS_URL = "https://raw.githubusercontent.com/a2x/cs2-dumper/main/output/offsets.json"
local ENGINE_CACHE = "rgnweapons_preview_engine_cache.lua"
local ENGINE_MIN_SIZE = 90000
local EMBEDDED_ENGINE = [====[
local ffi  = ffi
local band, rshift, bxor, lshift = bit.band, bit.rshift, bit.bxor, bit.lshift
local floor = math.floor

local off = {}

local DUMPER = "https://raw.githubusercontent.com/a2x/cs2-dumper/main/output/"

local FIELDS = {
    m_pWeaponServices      = "m_pWeaponServices",
    m_hMyWeapons           = "m_hMyWeapons",
    m_hActiveWeapon        = "m_hActiveWeapon",
    m_AttributeManager     = { "m_AttributeManager", "C_EconEntity" },
    m_Item                 = "m_Item",
    m_pGameSceneNode       = "m_pGameSceneNode",
    m_modelState           = { "m_modelState", "CSkeletonInstance" },
    m_MeshGroupMask        = { "m_MeshGroupMask", "CModelState" },
    m_hModel               = { "m_hModel", "CModelState" },
    m_nSubclassID          = "m_nSubclassID",
    m_iTeamNum             = "m_iTeamNum",
    m_iHealth              = "m_iHealth",
    m_lifeState            = "m_lifeState",
    m_hOwnerEntity         = "m_hOwnerEntity",
    m_hPlayerPawn          = "m_hPlayerPawn",
    m_steamID              = "m_steamID",
    m_iItemDefinitionIndex = "m_iItemDefinitionIndex",
    m_bRestoreCustomMat    = "m_bRestoreCustomMaterialAfterPrecache",
    m_iEntityQuality       = "m_iEntityQuality",
    m_iItemIDLow           = "m_iItemIDLow",
    m_iItemIDHigh          = "m_iItemIDHigh",
    m_iAccountID           = "m_iAccountID",
    m_OriginalOwnerXuidLow = { "m_OriginalOwnerXuidLow", "C_EconEntity" },
    m_bInitialized         = "m_bInitialized",
    m_bDisallowSOC         = "m_bDisallowSOC",
    m_AttributeList        = "m_AttributeList",
    m_Attributes           = "m_Attributes",
    m_nFallbackPaintKit    = { "m_nFallbackPaintKit", "C_EconEntity" },
    m_nFallbackSeed        = { "m_nFallbackSeed", "C_EconEntity" },
    m_flFallbackWear       = { "m_flFallbackWear", "C_EconEntity" },
    m_nFallbackStatTrak    = { "m_nFallbackStatTrak", "C_EconEntity" },
    m_hViewmodelAttachment = { "m_hViewmodelAttachment", "C_EconEntity" },
    m_EconGloves           = { "m_EconGloves", "C_CSPlayerPawn" },
    m_bNeedToReApplyGloves = { "m_bNeedToReApplyGloves", "C_CSPlayerPawn" },

}
local function pull_offset(j, name, after)
    local init = 1

    if after then local p = j:find('"' .. after .. '"%s*:%s*{'); if p then init = p end end
    local v = j:match('"' .. name .. '"%s*:%s*(%d+)', init)
    return v and tonumber(v) or nil
end
pcall(function()
    local j = http.Get(DUMPER .. "client_dll.json")
    if type(j) ~= "string" then return end
    for key, spec in pairs(FIELDS) do
        local name, after = spec, nil
        if type(spec) == "table" then name, after = spec[1], spec[2] end
        local v = pull_offset(j, name, after)
        if v then off[key] = v end
    end
end)
off.m_szWorldModel = 48
off.m_modelState = off.m_modelState or 336
off.m_hModel     = off.m_hModel     or 160
off.m_MeshGroupMask = off.m_MeshGroupMask or 520
off.m_hViewmodelAttachment = off.m_hViewmodelAttachment or 5808

-- Compact legacy paint IDs (ByMykel legacy_model=true). Avoid downloading 5MB skins.json on inject.
local LEGACY_PAINT = {}
do
    local csv = [[5,6,8,9,10,11,12,13,14,15,16,17,20,21,34,36,42,43,44,48,51,59,60,62,67,70,71,73,74,75,76,77,78,83,84,90,92,125,154,155,156,158,159,164,165,166,169,171,172,174,177,178,180,181,182,183,184,185,187,188,189,190,191,192,195,200,202,203,204,207,211,212,213,214,215,217,218,219,220,221,222,223,224,226,227,228,230,231,232,235,236,237,238,240,247,248,249,250,251,252,255,256,257,258,259,260,261,262,263,264,265,266,267,268,270,271,272,273,275,277,278,279,280,281,282,283,284,286,287,288,289,290,291,293,295,296,298,299,300,301,302,303,304,305,306,307,308,309,310,311,312,313,314,315,316,317,318,319,320,321,323,325,326,327,328,329,330,332,334,335,336,337,338,339,340,341,342,343,344,345,346,347,348,349,350,351,352,353,354,355,356,357,358,359,360,361,362,363,364,365,366,367,368,370,371,372,373,374,379,380,381,382,383,384,385,386,387,388,389,390,391,393,394,395,396,397,398,399,400,401,402,403,404,405,406,407,409,410,411,413,414,422,423,424,425,426,427,428,429,430,431,432,433,434,435,436,438,439,440,441,445,446,447,449,450,451,452,454,455,456,457,458,459,460,462,463,464,465,466,468,469,470,471,474,475,476,477,478,479,480,481,482,483,484,485,486,487,488,489,490,491,492,493,494,495,496,497,498,499,500,501,502,503,504,505,506,507,508,509,510,511,512,514,515,516,517,518,519,520,521,524,525,526,527,528,529,530,532,533,534,535,537,538,539,540,541,542,543,544,546,547,548,549,550,551,552,553,554,555,556,557,558,559,560,561,562,563,564,565,566,567,573,574,575,576,577,578,579,580,581,582,583,584,585,586,587,588,589,590,591,592,593,594,595,596,597,598,599,600,601,602,603,604,605,606,607,608,609,610,611,612,613,614,615,616,620,622,623,624,625,626,627,628,629,631,632,633,634,635,636,637,638,639,640,641,642,643,644,645,646,650,652,653,654,655,656,657,658,660,661,662,663,664,665,666,667,668,669,670,671,672,673,674,675,676,677,678,679,680,681,682,683,684,685,686,687,688,689,690,691,692,693,694,695,696,697,699,700,701,703,704,705,706,707,708,709,711,712,713,714,715,716,717,718,719,720,721,722,723,724,725,727,729,731,732,734,736,737,738,739,740,741,742,743,744,745,746,747,748,749,750,751,754,755,756,757,758,759,760,761,763,764,775,776,777,778,779,780,781,782,783,784,785,786,787,788,789,790,791,792,793,795,797,800,801,802,803,804,805,806,807,808,809,810,811,812,814,815,816,817,818,819,820,821,822,823,829,836,837,838,839,840,841,843,844,845,846,847,848,849,850,851,856,857,858,859,860,862,863,865,867,868,872,880,884,885,886,887,888,889,890,891,892,893,894,895,897,898,899,900,902,903,904,905,906,907,908,909,910,911,913,914,915,916,917,918,919,920,921,922,923,924,925,926,927,928,929,941,942,943,944,945,946,947,948,949,950,951,952,953,954,955,956,957,958,959,960,961,962,963,964,965,966,967,968,969,970,971,972,973,974,975,976,977,978,979,980,981,982,983,984,985,986,987,988,989,990,991,992,993,994,995,996,997,998,999,1000,1001,1003,1004,1005,1006,1007,1008,1009,1010,1011,1012,1013,1014,1015,1016,1018,1019,1021,1023,1024,1027,1028,1029,1030,1031,1032,1033,1034,1035,1036,1037,1038,1039,1040,1041,1042,1043,1044,1045,1046,1047,1048,1049,1050,1052,1053,1058,1060,1061,1063,1064,1067,1070,1072,1073,1074,1075,1076,1077,1080,1082,1084,1087,1088,1089,1090,1091,1092,1093,1095,1096,1097,1098,1099,1100,1101,1102,1103,1104,1105,1106,1107,1108,1109,1110,1111,1112,1113,1114,1115,1116,1117,1118,1119,1120,1121,1122,1123,1125,1126,1127,1128,1129,1130,1131,1132,1133,1134,1135,1136,1137,1138,1140,1141,1142,1143,1144,1145,1146,1147,1148,1149,1150,1151,1152,1153,1154,1155,1156,1157,1158,1220,1221,1222,1223,1224,1225,1226,1227,1228,1229,1230,1231,1232,1233,1234,1235,1236,1237,1238,1239,1240,1241,1242,1243,1244,1245,1246,1247,1248,1249,1250,1251,1252,1253,1254,1255]]
    local n = 0
    for id in csv:gmatch("%d+") do
        LEGACY_PAINT[tonumber(id)] = true
        n = n + 1
    end
    print(string.format("[changer] legacy map: %d paints (embedded)", n))
end

local function r_u8 (a) return ffi.cast("uint8_t*",  a)[0] end
local function r_u16(a) return ffi.cast("uint16_t*", a)[0] end
local function r_i32(a) return ffi.cast("int32_t*",  a)[0] end
local function r_u32(a) return ffi.cast("uint32_t*", a)[0] end
local function r_u64(a) return ffi.cast("uint64_t*", a)[0] end
local function r_ptr(a) return tonumber(ffi.cast("uint64_t*", a)[0]) end
local function w_u8 (a,v) ffi.cast("uint8_t*",  a)[0]=v end
local function w_u16(a,v) ffi.cast("uint16_t*", a)[0]=v end
local function w_i32(a,v) ffi.cast("int32_t*",  a)[0]=v end
local function w_u32(a,v) ffi.cast("uint32_t*", a)[0]=v end
local function w_u64(a,v) ffi.cast("uint64_t*", a)[0]=v end
local function w_f32(a,v) ffi.cast("float*",    a)[0]=v end
local function valid(p) return p ~= nil and p > 0x10000 and p < 0x7FFFFFFFFFFF end
local function read_cstr(a, max)
    if not valid(a) then return "" end
    local t = {}
    for i = 0, (max or 160) - 1 do
        local c = r_u8(a + i); if c == 0 then break end
        t[#t+1] = string.char(c)
    end
    return table.concat(t)
end

local function sig_rva(modBase, mod, pattern, instrLen)
    if not modBase then return nil end
    local a = mem.FindPattern(mod, pattern); if not a or a == 0 then return nil end
    a = tonumber(a)
    return (a + instrLen + r_i32(a + 3)) - modBase
end
local function sig_disp(mod, pattern)
    local a = mem.FindPattern(mod, pattern); if not a or a == 0 then return nil end
    return r_i32(tonumber(a) + 3)
end
-- cs2-dumper 2026-07-10 fallbacks (updated after CS2 patch)
local FALLBACK_ENTITYLIST = 0x254EE60
local FALLBACK_LOCALCTRL  = 0x237EBA0

do
    local cb = mem.GetModuleBase("client.dll")
    local eb = mem.GetModuleBase("engine2.dll")

    local ENTLIST_PATS = {
        "48 8B 0D ?? ?? ?? ?? 48 89 7C 24 ?? 8B FA C1 EB",
        "48 89 0D ?? ?? ?? ?? E9 ?? ?? ?? ?? CC",
    }
    for _, pat in ipairs(ENTLIST_PATS) do
        off.dwEntityList = sig_rva(cb, "client.dll", pat, 7)
        if off.dwEntityList then break end
    end
    if not off.dwEntityList then
        off.dwEntityList = FALLBACK_ENTITYLIST
        print(string.format("[changer] entlist pattern miss, using fallback RVA 0x%X", FALLBACK_ENTITYLIST))
    end

    off.dwLocalPlayerController = sig_rva(cb, "client.dll", "48 8B 05 ?? ?? ?? ?? 41 89 BE", 7)
    if not off.dwLocalPlayerController then
        off.dwLocalPlayerController = FALLBACK_LOCALCTRL
        print(string.format("[changer] localctrl pattern miss, using fallback RVA 0x%X", FALLBACK_LOCALCTRL))
    end

    off.dwNetworkGameClient     = sig_rva(eb, "engine2.dll", "48 89 3D ?? ?? ?? ?? FF 87", 7)
    off.dwNetworkGameClient_signOnState = sig_disp("engine2.dll", "44 8B 81 ?? ?? ?? ?? 48 8D 0D")
    if not off.dwLocalPlayerController or not off.dwEntityList or not off.m_hMyWeapons then
        print("[changer] WARNING: signatures/netvars not resolved -- changer inactive")
    else
        print(string.format("[changer] sigs ok: entlist=%X ctrl=%X ngc=%s",
            off.dwEntityList, off.dwLocalPlayerController,
            off.dwNetworkGameClient and string.format("%X", off.dwNetworkGameClient) or "nil"))
    end
end

local function tou32(x) x = x % 0x100000000; if x < 0 then x = x + 0x100000000 end; return x end
local function mul32(a, b)
    a = a % 0x100000000; b = b % 0x100000000
    local ah, al = floor(a/0x10000), a%0x10000
    local bh = floor(b/0x10000)
    return (al*(b%0x10000) + ((al*bh + ah*(b%0x10000)) % 0x10000)*0x10000) % 0x100000000
end
local MM = 0x5bd1e995
local function murmur2(str, seed)
    local len = #str
    local h = tou32(bxor(seed, len))
    local i, rem = 1, len
    while rem >= 4 do
        local b0,b1,b2,b3 = str:byte(i, i+3)
        local k = b0 + b1*256 + b2*65536 + b3*16777216
        k = mul32(k, MM); k = tou32(bxor(k, rshift(k, 24))); k = mul32(k, MM)
        h = mul32(h, MM); h = tou32(bxor(h, k))
        i = i + 4; rem = rem - 4
    end
    if rem >= 3 then h = tou32(bxor(h, lshift(str:byte(i+2), 16))) end
    if rem >= 2 then h = tou32(bxor(h, lshift(str:byte(i+1), 8))) end
    if rem >= 1 then h = tou32(bxor(h, str:byte(i))); h = mul32(h, MM) end
    h = tou32(bxor(h, rshift(h, 13))); h = mul32(h, MM); h = tou32(bxor(h, rshift(h, 15)))
    return h
end
local function subclass_hash(def) return murmur2(tostring(def):lower(), 0x31415926) end

local DLL = "client.dll"
-- client.dll 
local sig = {
    set_model      = "40 53 48 83 EC ?? 48 8B D9 4C 8B C2 48 8B 0D ?? ?? ?? ?? 48 8D 54 24 40",  -- CBaseModelEntity::SetModel
    update_subclass= "4C 8B DC 53 48 81 EC ?? ?? ?? ?? 48 8B 41",                                 -- CEconItemView subclass refresh
    set_mesh_mask  = "48 89 5C 24 ?? 48 89 74 24 ?? 57 48 83 EC ?? 48 8D 99 ?? ?? ?? ?? 48 8B 71", -- CSkeletonInstance mesh mask
    regen_skins    = "48 83 EC ?? E8 ?? ?? ?? ?? 48 85 C0 0F 84 ?? ?? ?? ?? 48 8B 10",            -- regenerate custom skins
}
-- a + 5 + rel32 -> CBodyComponent::SetBodyGroup
local SBG_SIG = "E8 ?? ?? ?? ?? EB 0C 48 8B CF"
local fn, fnptr = {}, {}
local function resolve()
    for name, pattern in pairs(sig) do
        if not fn[name] then local a = mem.FindPattern(DLL, pattern); if a and a ~= 0 then fn[name] = a end end
    end
    if not fn.set_body_group then
        local a = mem.FindPattern(DLL, SBG_SIG)
        if a and a ~= 0 then fn.set_body_group = a + 5 + r_i32(a + 1) end
    end
    if fn.set_model       and not fnptr.set_model       then fnptr.set_model       = ffi.cast("void(*)(void*, const char*)", fn.set_model) end
    if fn.update_subclass and not fnptr.update_subclass then fnptr.update_subclass = ffi.cast("void(*)(void*)",              fn.update_subclass) end
    if fn.set_mesh_mask   and not fnptr.set_mesh_mask   then fnptr.set_mesh_mask   = ffi.cast("void(*)(void*, uint64_t)",    fn.set_mesh_mask) end
    if fn.regen_skins     and not fnptr.regen_skins     then fnptr.regen_skins     = ffi.cast("void(*)(void)",               fn.regen_skins) end
    if fn.set_body_group  and not fnptr.set_body_group  then fnptr.set_body_group  = ffi.cast("void(*)(void*, const char*, unsigned int)", fn.set_body_group) end
end
local function vfunc(this, index)
    if not valid(this) then return nil end
    local vt = r_ptr(this); if not valid(vt) then return nil end
    local f = r_ptr(vt + index*8); if not valid(f) then return nil end
    return f
end
local function vcall_void(this, index)
    local f = vfunc(this, index); if not f then return end
    ffi.cast("void(*)(void*)", f)(ffi.cast("void*", this))
end
local function vcall_void_bool(this, index, b)
    local f = vfunc(this, index); if not f then return end
    ffi.cast("void(*)(void*, int)", f)(ffi.cast("void*", this), b and 1 or 0)
end

local KNIVES = {
    { name = "Default (no swap)", def = nil },
    { name = "Bayonet",        def = 500 }, { name = "Classic Knife",  def = 503 },
    { name = "Flip Knife",     def = 505 }, { name = "Gut Knife",      def = 506 },
    { name = "Karambit",       def = 507 }, { name = "M9 Bayonet",     def = 508 },
    { name = "Huntsman",       def = 509 }, { name = "Falchion",       def = 512 },
    { name = "Bowie Knife",    def = 514 }, { name = "Butterfly",      def = 515 },
    { name = "Shadow Daggers", def = 516 }, { name = "Paracord Knife", def = 517 },
    { name = "Survival Knife", def = 518 }, { name = "Ursus Knife",    def = 519 },
    { name = "Navaja Knife",   def = 520 }, { name = "Nomad Knife",    def = 521 },
    { name = "Stiletto",       def = 522 }, { name = "Talon Knife",    def = 523 },
    { name = "Skeleton Knife", def = 525 }, { name = "Kukri Knife",    def = 526 },
}
local WEAPONS = {
    { name = "AK-47",        def = 7  }, { name = "M4A4",         def = 16 },
    { name = "M4A1-S",       def = 60 }, { name = "AWP",          def = 9  },
    { name = "SSG 08",       def = 40 }, { name = "SCAR-20",      def = 38 },
    { name = "G3SG1",        def = 11 }, { name = "SG 553",       def = 39 },
    { name = "AUG",          def = 8  }, { name = "FAMAS",        def = 10 },
    { name = "Galil AR",     def = 13 }, { name = "Desert Eagle", def = 1  },
    { name = "R8 Revolver",  def = 64 }, { name = "Dual Berettas",def = 2  },
    { name = "Five-SeveN",   def = 3  }, { name = "Glock-18",     def = 4  },
    { name = "Tec-9",        def = 30 }, { name = "P2000",        def = 32 },
    { name = "P250",         def = 36 }, { name = "USP-S",        def = 61 },
    { name = "CZ75-Auto",    def = 63 }, { name = "MAC-10",       def = 17 },
    { name = "P90",          def = 19 }, { name = "PP-Bizon",     def = 26 },
    { name = "MP5-SD",       def = 23 }, { name = "MP7",          def = 33 },
    { name = "MP9",          def = 34 }, { name = "UMP-45",       def = 24 },
    { name = "M249",         def = 14 }, { name = "Negev",        def = 28 },
    { name = "XM1014",       def = 25 }, { name = "MAG-7",        def = 27 },
    { name = "Nova",         def = 35 }, { name = "Sawed-Off",    def = 29 },
}
local GLOVES = {
    { name = "Default (off)",      def = 0    },
    { name = "Bloodhound Gloves",  def = 5027 }, { name = "Sport Gloves",      def = 5030 },
    { name = "Driver Gloves",      def = 5031 }, { name = "Hand Wraps",        def = 5032 },
    { name = "Moto Gloves",        def = 5033 }, { name = "Specialist Gloves", def = 5034 },
    { name = "Hydra Gloves",       def = 5035 }, { name = "Broken Fang Gloves",def = 4725 },
}
local function is_knife(def) return def == 42 or def == 59 or (def >= 500 and def <= 526) end

local SKINS = {
  [1]={{"Blaze",37},{"Blue Ply",945},{"Bronze Deco",425},{"Calligraffiti",114},{"Cobalt Disruption",231},{"Code Red",711},{"Conspiracy",351},{"Corinthian",509},{"Crimson Web",232},{"Directive",603},{"Emerald JГ¶rmungandr",757},{"Fennec Fox",764},{"Firebreathing",1430},{"Golden Koi",185},{"Hand Cannon",328},{"Heat Treated",1054},{"Heirloom",273},{"Hypnotic",61},{"Kumicho Dragon",527},{"Light Rail",841},{"Mecha Industries",805},{"Meteorite",296},{"Midnight Storm",468},{"Mint Fan",1257},{"Mudder",90},{"Mulberry",1318},{"Naga",397},{"Night",40},{"Night Heist",1006},{"Ocean Drive",1090},{"Oxide Blaze",645},{"Pilot",347},{"Printstream",962},{"Serpent Strike",1189},{"Sputnik",1056},{"Starcade",938},{"Sunset Storm еЈ±",469},{"Sunset Storm ејђ",470},{"The Bronze",992},{"The Daily Deagle",1360},{"Tilted",138},{"Trigger Discipline",1050},{"Urban DDPAT",17},{"Urban Rubble",237}},
  [2]={{"Angel Eyes",1347},{"Anodized Navy",28},{"Balance",895},{"Black Limba",190},{"BorDeux",1335},{"Briar",330},{"Cartel",528},{"Cobalt Quartz",249},{"Cobra Strike",658},{"Colony",47},{"Contractor",46},{"Demolition",153},{"Dezastre",978},{"Drift Wood",824},{"Dualing Dragons",491},{"Duelist",447},{"Elite 1.6",903},{"Emerald",453},{"Flora Carnivora",1156},{"Heist",1005},{"Hemoglobin",220},{"Hideout",1169},{"Hydro Strike",112},{"Marina",261},{"Melondrama",1126},{"Moon in Libra",450},{"Oil Change",1086},{"Panther",276},{"Polished Malachite",1290},{"Pyre",860},{"Retribution",307},{"Rose Nacre",1263},{"Royal Consorts",625},{"Shred",710},{"Silver Pour",1373},{"Stained",43},{"Sweet Little Angels",139},{"Switch Board",998},{"Tread",1091},{"Twin Turbo",747},{"Urban Shock",396},{"Ventilators",544}},
  [3]={{"Angry Mob",837},{"Anodized Gunmetal",210},{"Autumn Thicket",1336},{"Berries And Cherries",1002},{"Boost Protocol",1093},{"Buddy",906},{"Candy Apple",3},{"Capillary",646},{"Case Hardened",44},{"Contractor",46},{"Coolant",784},{"Copper Galaxy",274},{"Crimson Blossom",729},{"Dark Polymer",1429},{"Fairy Tale",979},{"Fall Hazard",1082},{"Flame Test",693},{"Forest Night",78},{"Fowl Play",352},{"Fraise Crane",1380},{"Heat Treated",831},{"Hot Shot",377},{"Hybrid",1168},{"Hyper Beast",660},{"Jungle",151},{"Kami",265},{"Midnight Paintover",1062},{"Monkey Business",427},{"Neon Kimono",464},{"Nightshade",223},{"Nitro",254},{"Orange Peel",141},{"Retrobution",510},{"Scrawl",1128},{"Scumbria",605},{"Silver Quartz",252},{"Sky Blue",1262},{"Triumvirate",530},{"Urban Hazard",387},{"Violent Daimyo",585},{"Withered Vine",932}},
  [4]={{"AXIA",832},{"Block-18",1167},{"Blue Fissure",278},{"Brass",159},{"Bullet Queen",957},{"Bunsen Burner",479},{"Candy Apple",3},{"Catacombs",399},{"Clear Polymer",1039},{"Coral Bloom",1312},{"Death Rattle",293},{"Dragon Tattoo",48},{"Fade",38},{"Franklin",1016},{"Fully Tuned",1421},{"Gamma Doppler",1119},{"Gamma Doppler",1120},{"Gamma Doppler",1121},{"Gamma Doppler",1122},{"Gamma Doppler",1123},{"Glockingbird",1282},{"Gold Toof",129},{"Green Line",1200},{"Grinder",381},{"Groundwater",2},{"High Beam",799},{"Ironwork",623},{"Mirror Mosaic",1348},{"Moonrise",694},{"Neo-Noir",988},{"Night",40},{"Nuclear Garden",789},{"Ocean Topo",1265},{"Off World",680},{"Oxide Blaze",808},{"Pink DDPAT",84},{"Ramese's Reach",1240},{"Reactor",367},{"Red Tire",1079},{"Royal Legion",532},{"Sacrifice",918},{"Sand Dune",208},{"Shinobu",1208},{"Snack Attack",1100},{"Steel Disruption",230},{"Synth Leaf",732},{"Teal Graf",152},{"Trace Lock",1357},{"Twilight Galaxy",437},{"Umbral Rabbit",1227},{"Vogue",963},{"Warhawk",713},{"Wasteland Rebel",586},{"Water Elemental",353},{"Weasel",607},{"Winterized",1158},{"Wraiths",495}},
  [7]={{"Aphrodite",1397},{"Aquamarine Revenge",474},{"Asiimov",801},{"B the Monster",142},{"Baroque Purple",745},{"Black Laminate",172},{"Bloodsport",639},{"Blue Laminate",226},{"Breakthrough",1358},{"Cartel",394},{"Case Hardened",44},{"Crane Flight",1425},{"Crossfade",912},{"Elite Build",422},{"Emerald Pinstripe",300},{"Fire Serpent",180},{"First Class",341},{"Frontside Misty",490},{"Fuel Injector",524},{"Gold Arabesque",921},{"Green Laminate",1070},{"Head Shot",1221},{"Hydroponic",456},{"Ice Coaled",1143},{"Inheritance",1171},{"Jaguar",316},{"Jet Set",340},{"Jungle Spray",122},{"Leet Museo",1087},{"Legion of Anubis",959},{"Midnight Laminate",1218},{"Neon Revolution",600},{"Neon Rider",707},{"Nightwish",1141},{"Nouveau Rouge",1309},{"Olive Polycam",1179},{"Orbit Mk01",656},{"Panthera onca",1018},{"Phantom Disruptor",941},{"Point Disarray",506},{"Predator",170},{"Rat Rod",885},{"Red Laminate",14},{"Redline",282},{"Safari Mesh",72},{"Safety Net",795},{"Searing Rage",1207},{"Slate",1035},{"Steel Delta",1238},{"The Empress",675},{"The Oligarch",1352},{"The Outsiders",113},{"Uncharted",836},{"VariCamo Grey",1288},{"Vulcan",302},{"Wasteland Rebel",380},{"Wild Lotus",724},{"Wintergreen",1283},{"X-Ray",1004}},
  [8]={{"Akihabara Accept",455},{"Amber Fade",246},{"Amber Slipstream",708},{"Anodized Navy",197},{"Arctic Wolf",886},{"Aristocrat",583},{"Bengal Tiger",9},{"Carved Jade",1033},{"Chameleon",280},{"Colony",47},{"Commando Company",1308},{"Condemned",110},{"Contractor",46},{"Copperhead",10},{"Creep",1362},{"Daedalus",444},{"Death by Puppy",913},{"Eye of Zapems",134},{"Flame JГ¶rmungandr",758},{"Fleet Flock",541},{"Hot Rod",33},{"Lil' Pig",173},{"Luxe Trim",121},{"Midnight Lily",727},{"Momentum",845},{"Navy Murano",740},{"Plague",1088},{"Radiation Hazard",375},{"Random Access",779},{"Ricochet",507},{"Sand Storm",823},{"Snake Pit",1249},{"Spalted Wood",927},{"Steel Sentinel",1198},{"Storm",100},{"Stymphalian",690},{"Surveillance",995},{"Sweeper",794},{"Syd Mead",601},{"Tom Cat",942},{"Torque",305},{"Trigger Discipline",1339},{"Triqua",674},{"Wings",73}},
  [9]={{"Acheron",788},{"Arsenic Spill",1324},{"Asiimov",279},{"Atheris",838},{"Black Nile",1239},{"BOOM",174},{"Capillary",943},{"Chromatic Aberration",1144},{"Chrome Cannon",1170},{"CMYK",163},{"Containment Breach",887},{"Corticera",181},{"Crakow!",137},{"Desert Hydra",819},{"Dragon Lore",344},{"Duality",1222},{"Electric Hive",227},{"Elite Build",525},{"Exoskeleton",975},{"Exothermic",1378},{"Fade",1026},{"Fever Dream",640},{"Graphite",212},{"Green Energy",1280},{"Gungnir",756},{"Hyper Beast",475},{"Ice Coaled",1346},{"Lightning Strike",51},{"LongDog",1213},{"Man-o'-war",395},{"Medusa",446},{"Mortis",691},{"Neo-Noir",803},{"Oni Taiji",662},{"PAW",718},{"Phobos",584},{"Pink DDPAT",84},{"Pit Viper",251},{"POP AWP",1058},{"Printstream",1206},{"Queen's Gambit",1422},{"Redline",259},{"Safari Mesh",72},{"Silk Tiger",1029},{"Snake Camo",30},{"Sun in Leo",451},{"The End",1356},{"The Prince",736},{"Wildfire",917},{"Worm God",424}},
  [10]={{"2A2F",1202},{"Afterimage",154},{"Bad Trip",1184},{"Byproduct",1393},{"CaliCamo",240},{"Colony",47},{"Commemoration",919},{"Contrast Spray",22},{"Crypsis",835},{"Cyanospatter",92},{"Dark Water",60},{"Decommissioned",904},{"Djinn",429},{"Doomkitty",178},{"Eye of Athena",723},{"Faulty Wiring",1066},{"Grey Ghost",1321},{"Half Sleeve",461},{"Halftone Wash",882},{"Hexane",218},{"Macabre",659},{"Mecha Industries",626},{"Meltdown",1053},{"Meow 36",1146},{"Neural Net",477},{"Night Borre",863},{"Palm",1302},{"Prime Conspiracy",999},{"Pulse",260},{"Rapid Eye Movement",1127},{"Roll Cage",604},{"Sergeant",288},{"Spitfire",194},{"Styx",371},{"Sundown",869},{"Survivor Z",492},{"Teardown",244},{"Valence",529},{"Vendetta",1365},{"Waters of Nephthys",1241},{"Yeti Camo",1219},{"ZX Spectron",1092}},
  [11]={{"Ancient Ritual",1034},{"Arctic Camo",6},{"Azure Zebra",229},{"Black Sand",891},{"Chronos",438},{"Contractor",46},{"Demeter",195},{"Desert Storm",8},{"Digital Mesh",980},{"Dream Glade",1129},{"Flux",493},{"Green Apple",294},{"Green Cell",1305},{"High Seas",712},{"Hunter",677},{"Jungle Dashed",147},{"Keeping Tabs",1095},{"Murky",382},{"New Roots",930},{"Orange Crash",545},{"Orange Kimono",465},{"Polar Camo",74},{"Red Jasper",1328},{"Safari Mesh",72},{"Scavenger",806},{"Stinger",628},{"The Executioner",511},{"VariCamo",235},{"Ventilator",606},{"Violet Murano",739}},
  [13]={{"Acid Dart",1296},{"Akoben",842},{"Amber Fade",246},{"Aqua Terrace",460},{"Black Sand",629},{"Blue Titanium",216},{"CAUTION!",1071},{"Cerberus",379},{"Chatterbox",398},{"Chromatic Aberration",1038},{"Cold Fusion",790},{"Connexion",972},{"Control",1185},{"Crimson Tsunami",647},{"Destroyer",1147},{"Dusk Ruins",1032},{"Eco",428},{"Firefight",546},{"Galigator",1434},{"Green Apple",294},{"Grey Smoke",1275},{"Hunting Blind",241},{"Kami",308},{"Metallic Squeezer",239},{"NV",939},{"O-Ranger",1314},{"Orange DDPAT",83},{"Phoenix Blacklight",1013},{"Rainbow Spoon",1178},{"Robin's Egg",1264},{"Rocket Pop",478},{"Sage Spray",119},{"Sandstorm",264},{"Shattered",192},{"Signal",807},{"Sky Mandala",1383},{"Stone Cold",494},{"Sugar Rush",661},{"Tornado",101},{"Tuxedo",297},{"Urban Rubble",237},{"Vandal",981},{"VariCamo",235},{"Winter Forest",76}},
  [14]={{"Aztec",902},{"Blizzard Marbleized",75},{"Bock Blocks",1435},{"Contrast Spray",22},{"Deep Relief",983},{"Downtown",1148},{"Emerald Poison Dart",648},{"Gator Mesh",243},{"Humidor",827},{"Hypnosis",120},{"Impact Drill",472},{"Jungle",151},{"Jungle DDPAT",202},{"Magma",266},{"Midnight Palm",933},{"Nebula Crusader",496},{"O.S.I.P.R.",1042},{"Predator",170},{"Sage Camo",1298},{"Shipping Forecast",452},{"Sleet",1370},{"Spectre",547},{"Spectrogram",875},{"Submerged",1242},{"System Lock",401},{"Warbird",900}},
  [16]={{"Aeolian Dark",1364},{"Asiimov",255},{"Bullet Rain",155},{"Buzz Kill",632},{"Choppa",1210},{"Converter",793},{"Cyber Security",985},{"Dark Blossom",730},{"Daybreak",471},{"Desert Storm",8},{"Desert-Strike",336},{"Desolate Space",588},{"Etch Lord",1165},{"Evil Daimyo",480},{"Eye of Horus",1255},{"Faded Zebra",176},{"Full Throttle",1353},{"Global Offensive",993},{"Griffin",384},{"Hellfire",664},{"Hellish",1209},{"Howl",309},{"In Living Color",1041},{"Jungle Tiger",16},{"Magnesium",811},{"Mainframe",780},{"Modern Hunter",164},{"Naval Shred Camo",1266},{"Neo-Noir",695},{"Poly Mag",1149},{"Polysoup",874},{"Poseidon",449},{"Radiation Hazard",167},{"Red DDPAT",926},{"Royal Paladin",512},{"Sheet Lightning",1281},{"Spider Lily",1097},{"Steel Work",1313},{"Temukau",1228},{"The Battlestar",533},{"The Coalition",1063},{"The Emperor",844},{"Tooth Fairy",971},{"Tornado",101},{"Turbine",118},{"Urban DDPAT",17},{"X-Ray",215},{"Zirka",187},{"Zubastick",1432},{"йѕЌзЋ‹ (Dragon King)",400}},
  [17]={{"Acid Hex",1295},{"Allure",965},{"Aloha",665},{"Amber Fade",246},{"Bronzer",1334},{"Button Masher",1045},{"Calf Skin",748},{"Candy Apple",3},{"Carnivore",589},{"Case Hardened",44},{"Cat Fight",1349},{"Classic Crate",908},{"Commuter",343},{"Copper Borre",761},{"Curse",310},{"Derailment",1204},{"Disco Tech",947},{"Echoing Sands",1244},{"Ensnared",1131},{"Fade",38},{"Gold Brick",1025},{"Graven",188},{"Heat",284},{"Hot Snakes",1009},{"Indigo",333},{"Lapis Gator",534},{"Last Dive",651},{"Light Box",1164},{"Malachite",402},{"Monkeyflage",1150},{"Neon Rider",433},{"Nuclear Garden",372},{"Oceanic",682},{"Palm",157},{"Pipe Down",812},{"Pipsqueak",140},{"Poplar Thicket",1285},{"Propaganda",1067},{"Rangeen",498},{"Red Filigree",742},{"SaibДЃ Oni",126},{"Sakkaku",1229},{"Sienna Damask",826},{"Silver",32},{"Snow Splash",1367},{"Stalker",898},{"Storm Camo",1269},{"Strats",1075},{"Surfwood",871},{"Tatter",337},{"Tornado",101},{"Toybox",1098},{"Ultraviolet",98},{"Urban DDPAT",17},{"Whitefish",840}},
  [19]={{"Aeolian Light",1361},{"Ancient Earth",1020},{"Ash Wood",234},{"Asiimov",359},{"Astral JГ¶rmungandr",759},{"Attack Vector",936},{"Baroque Red",744},{"Blind Spot",228},{"Blue Tac",1277},{"Chopper",593},{"Cocoa Rampage",977},{"Cold Blooded",67},{"Death by Kitty",156},{"Death Grip",669},{"Deathgaze",1419},{"Desert DDPAT",925},{"Desert Halftone",1332},{"Desert Warfare",311},{"Elite Build",486},{"Emerald Dragon",182},{"Facility Negative",776},{"Fallout Warning",169},{"Freight",969},{"Glacier Mesh",111},{"Grim",611},{"Leather",342},{"Module",335},{"Mustard Gas",1291},{"Neoqueen",1233},{"Nostalgia",911},{"Off World",849},{"Randy Rush",127},{"Reef Grief",1256},{"Run and Hide",1000},{"Sand Spray",124},{"ScaraB Rush",1250},{"Schematic",1074},{"Scorched",175},{"Shallow Grave",636},{"Shapewood",516},{"Storm",100},{"Straight Dimes",1199},{"Sunset Lily",726},{"Teardown",244},{"Tiger Pit",1015},{"Traction",717},{"Trigon",283},{"Vent Rush",1154},{"Verdant Growth",828},{"Virus",20},{"Wash me",133},{"Wave Breaker",1190}},
  [23]={{"Acid Wash",888},{"Agent",915},{"Autumn Twilly",1061},{"Bamboo Garden",872},{"Co-Processor",781},{"Condition Zero",986},{"Desert Strike",949},{"Dirt Drop",753},{"Focus",1344},{"Gauss",846},{"Gold Leaf",1294},{"Kitbash",974},{"Lab Rats",800},{"Lime Hex",1274},{"Liquidation",1231},{"Necro Jr.",1137},{"Neon Squeezer",161},{"Nitro",798},{"Oxide Oasis",923},{"Phosphor",810},{"Picnic",1385},{"Savannah Halftone",768},{"Snow Splash",1366},{"Statics",1180}},
  [24]={{"Arctic Wolf",704},{"Blaze",37},{"Bone Pile",193},{"Briefing",615},{"Caramel",93},{"Carbon Fiber",70},{"Continuum",1351},{"Corporal",281},{"Crime Scene",1003},{"Crimson Foil",412},{"Day Lily",725},{"Delusion",392},{"Exposure",688},{"Facility Dark",778},{"Fade",879},{"Fallout Warning",169},{"Fragment",1426},{"Full Stop",250},{"Gold Bismuth",990},{"Grand Prix",436},{"Green Swirl",1303},{"Gunsmoke",15},{"Houndstooth",1008},{"Indigo",333},{"K.O. Factory",1194},{"Labyrinth",362},{"Late Night Transit",1203},{"Mechanism",1085},{"Metal Flowers",672},{"Minotaur's Labyrinth",441},{"Momentum",802},{"Moonrise",851},{"Motorized",1175},{"Mudder",90},{"Neo-Noir",131},{"Oscillator",1049},{"Plastique",916},{"Primal Saber",556},{"Riot",488},{"Roadblock",1157},{"Scaffold",652},{"Scorched",175},{"Urban DDPAT",17},{"Warm Blooded",1387},{"Wild Child",1236}},
  [25]={{"Ancient Lore",1021},{"Banana Leaf",731},{"Black Tie",557},{"Blaze Orange",166},{"Blue Spruce",96},{"Blue Steel",42},{"Blue Tire",1078},{"Bone Machine",370},{"CaliCamo",240},{"Canvas Cloud",1333},{"Charter",994},{"Copperflage",1287},{"Elegant Vines",821},{"Entombed",970},{"Fallout Warning",169},{"Frost Borre",760},{"Grassland",95},{"Gum Wall Camo",1267},{"Halftone Shift",834},{"Heaven Guard",314},{"Hieroglyph",1254},{"Incinegator",850},{"Irezumi",1174},{"Jungle",205},{"Mockingbird",1182},{"Monster Melt",146},{"Oxide Blaze",706},{"Quicksilver",407},{"Red Leather",348},{"Red Python",320},{"Run Run Run",1201},{"Scumbria",505},{"Seasons",654},{"Slipstream",616},{"Solitude",1215},{"Teclu Burner",521},{"Tranquility",393},{"Urban Perforated",135},{"VariCamo Blue",238},{"Watchdog",1103},{"XoooM",1381},{"XOXO",1046},{"Ziggy",689},{"Zombie Offensive",1135}},
  [26]={{"Anolis",829},{"Antique",306},{"Bamboo Print",457},{"Bizoom",1374},{"Blue Streak",13},{"Brass",159},{"Breaker Box",1083},{"Candy Apple",3},{"Carbon Fiber",70},{"Chemical Green",376},{"Cobalt Halftone",267},{"Cold Cell",770},{"Death Rattle",293},{"Embargo",884},{"Facility Sketch",775},{"Forest Leaves",25},{"Fuel Rod",508},{"Harvester",594},{"High Roller",676},{"Irradiated Alert",171},{"Judgement of Anubis",542},{"Jungle Slipstream",641},{"Lumen",1099},{"Modern Hunter",164},{"Night Ops",236},{"Night Riot",692},{"Osiris",349},{"Photic Zone",526},{"RMX",1418},{"Runic",973},{"Rust Coat",203},{"Sand Dashed",148},{"Seabird",873},{"Space Cat",1125},{"Thermal Currents",1392},{"Urban Dashed",149},{"Water Sigil",224},{"Wood Block Camo",1325}},
  [27]={{"BI83 Spectrum",1089},{"Bulldozer",39},{"Carbon Fiber",70},{"Chainmail",327},{"Cinquedea",737},{"Cobalt Core",499},{"Copper Coated",1245},{"Copper Oxide",1306},{"Core Breach",787},{"Counter Terrace",462},{"Firestarter",385},{"Foresight",1132},{"Hard Water",666},{"Hazard",198},{"Heat",431},{"Heaven Guard",291},{"Insomnia",1220},{"Irradiated Alert",171},{"Justice",948},{"MAGnitude",1355},{"Memento",177},{"Metallic DDPAT",34},{"Monster Call",961},{"Navy Sheen",822},{"Petroglyph",608},{"Popdog",909},{"Praetorian",535},{"Prism Terrace",1072},{"Resupply",1188},{"Rust Coat",754},{"Sand Dune",99},{"Seabird",473},{"Silver",32},{"Sonar",633},{"Storm",100},{"SWAG-7",703},{"Wildwood",773}},
  [28]={{"Anodized Navy",28},{"Army Sheen",298},{"Boroque Sand",920},{"Bratatat",317},{"Bulkhead",783},{"CaliCamo",240},{"Dazzle",610},{"Desert-Strike",355},{"dev_texture",1043},{"Drop Me",1152},{"Infrastructure",1080},{"Lionfish",698},{"Loudmouth",483},{"Man-o'-war",432},{"MjГ¶lnir",763},{"Nuclear Waste",369},{"Palm",201},{"Phoenix Stencil",1012},{"Power Loader",514},{"Prototype",950},{"Raw Ceramic",1300},{"Sour Grapes",1260},{"Terrain",285},{"Ultralight",958},{"Wall Bang",144}},
  [29]={{"Amber Fade",246},{"Analog Input",1160},{"Apocalypto",953},{"Bamboo Shadow",458},{"Black Sand",814},{"Brake Light",797},{"Clay Ambush",1014},{"Copper",41},{"Crimson Batik",1391},{"Devourer",720},{"First Class",345},{"Forest DDPAT",5},{"Fubar",552},{"Full Stop",250},{"Fusion",1427},{"Highwayman",390},{"Irradiated Alert",171},{"Jungle Thicket",870},{"Kissв™ҐLove",1155},{"Limelight",596},{"Morris",673},{"Mosaico",204},{"Orange DDPAT",83},{"Origami",434},{"Parched",880},{"Runoff",1272},{"Rust Coat",323},{"Sage Spray",119},{"Serenity",405},{"Snake Camo",30},{"Spirit Board",1140},{"The Kraken",256},{"Wasteland Princess",638},{"Yorick",517},{"Zander",655}},
  [30]={{"Army Mesh",242},{"Avalanche",520},{"Bamboo Forest",459},{"Bamboozle",839},{"Banana Leaf",1384},{"Blast From the Past",1024},{"Blue Blast",1279},{"Blue Titanium",216},{"Brass",159},{"Brother",964},{"Citric Acid",1322},{"Cracked Opal",684},{"Cut Out",671},{"Decimator",889},{"Flash Out",905},{"Fubar",816},{"Fuel Injector",614},{"Garter-9",1286},{"Groundwater",2},{"Hades",439},{"Ice Cap",599},{"Isaac",303},{"Jambiya",539},{"Mummy's Rot",1252},{"Nuclear Threat",179},{"Orange Murano",738},{"Ossified",36},{"Phoenix Chalk",1010},{"Raw Ceramic",1299},{"Re-Entry",555},{"Rebel",1235},{"Red Quartz",248},{"Remote Control",791},{"Rust Leaf",733},{"Safety Net",795},{"Sandstorm",289},{"Slag",1159},{"Snek-9",722},{"Terrace",463},{"Tiger Stencil",766},{"Titanium Bit",272},{"Tornado",206},{"Toxic",374},{"Urban DDPAT",17},{"VariCamo",235},{"Whiteout",1214}},
  [31]={{"Charged Up",1205},{"Dragon Snore",292},{"Earth Mandala",1382},{"Electric Blue",1268},{"Olympus",1172},{"Swamp DDPAT",1297},{"Tosai",1183}},
  [32]={{"Acid Etched",951},{"Amber Fade",246},{"Chainmail",327},{"Coach Class",346},{"Coral Halftone",878},{"Corticera",184},{"Dispatch",997},{"Fire Elemental",389},{"Gnarled",960},{"Granite Marbleized",21},{"Grassland",95},{"Grassland Leaves",104},{"Grip Tape",1359},{"Handgun",485},{"Imperial",515},{"Imperial Dragon",591},{"Ivory",357},{"Lifted Spirits",1138},{"Marsh",1292},{"Obsidian",894},{"Ocean Foam",211},{"Oceanic",550},{"Panther Camo",1019},{"Pathfinder",443},{"Pulse",338},{"Red FragCam",275},{"Red Wing",1342},{"Royal Baroque",1259},{"Scorpion",71},{"Silver",32},{"Space Race",1055},{"Sure Grip",1181},{"Turf",635},{"Urban Hazard",700},{"Wicked Sick",1224},{"Woodsman",667}},
  [33]={{"Abyssal Apparition",1133},{"Akoben",649},{"Amberline",1436},{"Anodized Navy",28},{"Armor Core",423},{"Army Recon",245},{"Asterion",442},{"Astrolabe",940},{"Bloodsport",696},{"Cirrus",627},{"Coral Paisley",1386},{"Fade",752},{"Forest DDPAT",5},{"Full Stop",250},{"Groundwater",209},{"Guerrilla",1096},{"Gunsmoke",15},{"Impire",536},{"Just Smile",1163},{"Mischief",847},{"Motherboard",782},{"Nemesis",481},{"Neon Ply",893},{"Ocean Foam",213},{"Olive Plaid",365},{"Orange Peel",141},{"Powercore",719},{"Prey",935},{"Scorched",175},{"Short Ochre",1326},{"Skulls",11},{"Smoking Kills",1354},{"Special Delivery",500},{"Sunbaked",1246},{"Tall Grass",1023},{"Teal Blossom",728},{"Urban Hazard",354},{"Vault Heist",1007},{"Whiteout",102}},
  [34]={{"Airlock",609},{"Arctic Tri-Tone",331},{"Army Sheen",298},{"Bee-Tron",1388},{"Bioleak",549},{"Black Sand",697},{"Broken Record",1341},{"Buff Blue",1278},{"Bulldozer",39},{"Capillary",715},{"Cobalt Paisley",1258},{"Dark Age",329},{"Dart",386},{"Deadly Poison",403},{"Dizzy",1375},{"Dry Season",199},{"Featherweight",1225},{"Food Chain",1037},{"Goo",679},{"Green Plaid",366},{"Hot Rod",33},{"Hydra",910},{"Hypnotic",61},{"Latte Rush",1211},{"Modest Threat",804},{"Mount Fuji",1094},{"Multi-Terrain",1330},{"Music Box",820},{"Nexus",1193},{"Old Roots",931},{"Orange Peel",141},{"Pandora's Box",448},{"Pine",1301},{"Rose Iron",262},{"Ruby Poison Dart",482},{"Sand Dashed",148},{"Sand Scale",630},{"Setting Sun",368},{"Shredded",1310},{"Slide",755},{"Stained Glass",867},{"Starlight Protector",1134},{"Storm",100},{"Urban Sovereign",1423},{"Wild Lily",734}},
  [35]={{"Antique",286},{"Army Sheen",298},{"Baroque Orange",746},{"Blaze Orange",166},{"Bloomstick",62},{"Caged Steel",299},{"Candy Apple",3},{"Clear Polymer",987},{"Currents",1368},{"Dark Sigil",1162},{"Exo",590},{"Forest Leaves",25},{"Ghost Camo",225},{"Gila",634},{"Graphite",214},{"Green Apple",294},{"Hyper Beast",537},{"Interlock",1077},{"Koi",356},{"Mandrel",785},{"Marsh Grass",1331},{"Modern Hunter",164},{"Moon in Libra",450},{"Ocular",1350},{"Plume",890},{"Polar Mesh",107},{"Predator",170},{"Quick Sand",929},{"Rain Station",1337},{"Ranger",484},{"Red Quartz",248},{"Rising Skull",263},{"Rising Sun",1192},{"Rust Coat",323},{"Sand Dune",99},{"Sobek's Bite",1247},{"Tempest",191},{"Toy Soldier",716},{"Turquoise Pour",1261},{"Walnut",158},{"Wild Six",699},{"Windblown",1051},{"Wood Fired",809},{"Wurst HГ¶lle",145},{"Yorkshire",324}},
  [36]={{"Apep's Curse",1248},{"Asiimov",551},{"Bengal Tiger",1030},{"Black & Tan",928},{"Bone Mask",27},{"Boreal Forest",77},{"Bullfrog",1345},{"Cartel",388},{"Cassette",968},{"Constructivist",1212},{"Contaminant",982},{"Contamination",373},{"Copper Oxide",1307},{"Crimson Kimono",466},{"Cyber Shell",1044},{"Dark Filigree",741},{"Digital Architect",1081},{"Drought",825},{"Epicenter",130},{"Exchanger",786},{"Facets",207},{"Facility Draft",777},{"Forest Night",78},{"Franklin",295},{"Gunsmoke",15},{"Hive",219},{"Inferno",907},{"Iron Clad",592},{"Kintsugi",1420},{"Mehndi",258},{"Metallic DDPAT",34},{"Mint Kimono",467},{"Modern Hunter",164},{"Muertos",404},{"Nevermore",813},{"Nuclear Threat",168},{"Plum Netting",1273},{"Re.built",1230},{"Red Rock",668},{"Red Tide",1315},{"Ripple",650},{"Sand Dune",99},{"Sedimentary",1317},{"See Ya Later",678},{"Sleet",1369},{"Small Game",774},{"Splash",162},{"Steel Disruption",230},{"Supernova",358},{"Undertow",271},{"Valence",426},{"Verdigris",848},{"Vino Primo",749},{"Visions",1153},{"Whiteout",102},{"Wingshot",501},{"X-Ray",125}},
  [38]={{"Army Sheen",298},{"Assault",914},{"Bloodsport",597},{"Blueprint",642},{"Brass",159},{"Caged",1343},{"Carbon Fiber",70},{"Cardiac",391},{"Contractor",46},{"Crimson Web",232},{"Cyrex",312},{"Emerald",196},{"Enforcer",954},{"Fragments",1226},{"Green Marine",502},{"Grotto",406},{"Jungle Slipstream",685},{"Magna Carta",1028},{"Outbreak",518},{"Palm",157},{"Poultrygeist",1139},{"Powercore",612},{"Sand Mesh",116},{"Short Ochre",1327},{"Splash Jam",165},{"Stone Mosaico",865},{"Storm",100},{"Torn",896},{"Trail Blazer",117},{"Wild Berry",883},{"Zinc",1371}},
  [39]={{"Aerial",598},{"Aloha",702},{"Anodized Navy",28},{"Army Sheen",298},{"Atlas",553},{"Barricade",861},{"Basket Halftone",1320},{"Berry Gel Coat",901},{"Bleached",934},{"Bulldozer",39},{"Candy Apple",864},{"Colony IV",897},{"Cyberforce",1234},{"Cyrex",487},{"Damascus Steel",247},{"Danger Close",815},{"Darkwing",955},{"Desert Blossom",765},{"Dragon Tech",1151},{"Fallout Warning",378},{"Gator Mesh",243},{"Hazard Pay",1084},{"Heavy Metal",1048},{"Hypnotic",61},{"Integrale",750},{"Lush Ruins",1022},{"Night Camo",1270},{"Ol' Rusty",966},{"Phantom",686},{"Pulse",287},{"Safari Print",1394},{"Tiger Moth",519},{"Tornado",101},{"Traveler",363},{"Triarch",613},{"Ultraviolet",98},{"Wave Spray",186},{"Waves Perforated",136}},
  [40]={{"Abyss",361},{"Acid Fade",253},{"Azure Glyph",1251},{"Big Iron",503},{"Blood in the Water",222},{"Bloodshot",899},{"Blue Spruce",96},{"Blush Pour",1316},{"Calligrafaux",1379},{"Carbon Fiber",70},{"Dark Water",60},{"Death Strike",1052},{"Death's Head",670},{"Detour",319},{"Dezastre",1161},{"Dragonfire",624},{"Fever Dream",956},{"Ghost Crusader",554},{"Green Ceramic",1304},{"Grey Smoke",1271},{"Halftone Whorl",877},{"Hand Brake",751},{"Jungle Dashed",147},{"Lichen Dashed",26},{"Mainframe 001",967},{"Mayan Dreams",200},{"Memorial",1187},{"Necropos",538},{"Orange Filigree",743},{"Parallax",989},{"Prey",935},{"Rapid Transit",128},{"Red Stone",762},{"Sand Dune",99},{"Sans Comic",1372},{"Sea Calico",868},{"Slashed",304},{"Spring Twilly",1060},{"Threat Detected",996},{"Tiger Tear",1289},{"Tropical Storm",233},{"Turbo Peek",1101},{"Zeno",513}},
  [60]={{"Atomic Alloy",301},{"Basilisk",383},{"Black Lotus",1166},{"Blood Tiger",217},{"Blue Phosphor",1017},{"Boreal Forest",77},{"Briefing",663},{"Bright Water",189},{"Chantico's Fire",548},{"Control Panel",792},{"Cyrex",360},{"Dark Water",60},{"Decimator",644},{"Electrum",1433},{"Emphorosaur-S",1223},{"Fade",1177},{"Fizzy POP",1059},{"Flashback",631},{"Glitched Paint",1311},{"Golden Coil",497},{"Guardian",257},{"Hot Rod",445},{"Hyper Beast",430},{"Icarus Fell",440},{"Imminent Danger",1073},{"Knight",326},{"Leaded Glass",681},{"Liquidation",1340},{"Master Piece",321},{"Mecha Industries",587},{"Moss Quartz",862},{"Mud-Spec",1243},{"Night Terror",1130},{"Nightmare",714},{"Nitro",254},{"Party Animal",1376},{"Player Two",946},{"Printstream",984},{"Rose Hex",1319},{"Solitude",1338},{"Stratosphere",1216},{"Vaporwave",106},{"VariCamo",235},{"Wash me plz",160},{"Welcome to the Jungle",1001}},
  [61]={{"27",115},{"Alpine Camo",830},{"Ancient Visions",1031},{"Black Lotus",1102},{"Bleeding Edge",1323},{"Blood Tiger",217},{"Blueprint",657},{"Business Class",364},{"Caiman",339},{"Check Engine",796},{"Cortex",705},{"Cyrex",637},{"Dark Water",60},{"Desert Tactical",1253},{"Flashback",817},{"Forest Leaves",25},{"Guardian",290},{"Jawbreaker",1173},{"Kill Confirmed",504},{"Lead Conduit",540},{"Monster Mashup",991},{"Neo-Noir",653},{"Night Ops",236},{"Orange Anolis",922},{"Orion",313},{"Overgrowth",183},{"Para Green",454},{"Pathfinder",443},{"PC-GRN",1186},{"Printstream",1142},{"Purple DDPAT",818},{"Road Rash",318},{"Royal Blue",332},{"Royal Guard",1217},{"Serum",221},{"Silent Shot",1431},{"Sleeping Potion",1377},{"Stainless",277},{"Target Acquired",1027},{"The Traitor",1040},{"Ticket to Hell",1136},{"Torque",489},{"Tropical Breeze",1284},{"Whiteout",1065}},
  [63]={{"Army Sheen",298},{"Chalice",325},{"Circaetus",1036},{"Copper Fiber",1195},{"Crimson Web",12},{"Distressed",944},{"Eco",709},{"Emerald",453},{"Emerald Quartz",859},{"Framework",1076},{"Green Plaid",366},{"Hexane",218},{"Honey Paisley",1390},{"Imprint",602},{"Indigo",333},{"Jungle Dashed",147},{"Midnight Palm",933},{"Nitro",322},{"Pink Pearl",1329},{"Poison Dart",315},{"Pole Position",435},{"Polymer",622},{"Red Astor",543},{"Silver",32},{"Slalom",937},{"Syndicate",1064},{"Tacticat",687},{"The Fuschia Is Now",269},{"Tigris",350},{"Tread Plate",268},{"Tuxedo",297},{"Twist",334},{"Vendetta",976},{"Victoria",270},{"Xiangliu",643},{"Yellow Jacket",476}},
  [64]={{"Amber Fade",523},{"Banana Cannon",1232},{"Blaze",37},{"Bone Forged",952},{"Bone Mask",27},{"Canal Spray",866},{"Cobalt Grip",1276},{"Crazy 8",1145},{"Crimson Web",12},{"Dark Chamber",1363},{"Desert Brush",924},{"Fade",522},{"Grip",701},{"Inlay",1237},{"Junk Yard",1047},{"Leafhopper",1293},{"Llama Cannon",683},{"Mauve Aside",1389},{"Memento",892},{"Night",40},{"Nitro",798},{"Phoenix Marker",1011},{"Reboot",595},{"Skull Crusher",843},{"Survivalist",721},{"Tango",123}},
  [500]={{"Autotronic",573},{"Black Laminate",563},{"Blue Steel",42},{"Boreal Forest",77},{"Bright Water",578},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",410},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Freehand",580},{"Gamma Doppler",568},{"Gamma Doppler",569},{"Gamma Doppler",570},{"Gamma Doppler",571},{"Gamma Doppler",572},{"Lore",558},{"Marble Fade",413},{"Night",40},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [503]={{"Blue Steel",42},{"Boreal Forest",77},{"Case Hardened",44},{"Crimson Web",12},{"Fade",38},{"Forest DDPAT",5},{"Night Stripe",735},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Urban Masked",143}},
  [505]={{"Autotronic",574},{"Black Laminate",564},{"Blue Steel",42},{"Boreal Forest",77},{"Bright Water",578},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",410},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Freehand",580},{"Gamma Doppler",568},{"Gamma Doppler",569},{"Gamma Doppler",570},{"Gamma Doppler",571},{"Gamma Doppler",572},{"Lore",559},{"Marble Fade",413},{"Night",40},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [506]={{"Autotronic",575},{"Black Laminate",565},{"Blue Steel",42},{"Boreal Forest",77},{"Bright Water",578},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",410},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Freehand",580},{"Gamma Doppler",568},{"Gamma Doppler",569},{"Gamma Doppler",570},{"Gamma Doppler",571},{"Gamma Doppler",572},{"Lore",560},{"Marble Fade",413},{"Night",40},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [507]={{"Autotronic",576},{"Black Laminate",566},{"Blue Steel",42},{"Boreal Forest",77},{"Bright Water",578},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",410},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Freehand",582},{"Gamma Doppler",568},{"Gamma Doppler",569},{"Gamma Doppler",570},{"Gamma Doppler",571},{"Gamma Doppler",572},{"Lore",561},{"Marble Fade",413},{"Night",40},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [508]={{"Autotronic",577},{"Black Laminate",567},{"Blue Steel",42},{"Boreal Forest",77},{"Bright Water",579},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",411},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Freehand",581},{"Gamma Doppler",568},{"Gamma Doppler",569},{"Gamma Doppler",570},{"Gamma Doppler",571},{"Gamma Doppler",572},{"Lore",562},{"Marble Fade",413},{"Night",40},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [509]={{"Autotronic",1117},{"Black Laminate",1112},{"Blue Steel",42},{"Boreal Forest",77},{"Bright Water",579},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",411},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Freehand",581},{"Gamma Doppler",568},{"Gamma Doppler",569},{"Gamma Doppler",570},{"Gamma Doppler",571},{"Gamma Doppler",572},{"Lore",1107},{"Marble Fade",413},{"Night",40},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",620},{"Urban Masked",143}},
  [512]={{"Autotronic",1116},{"Black Laminate",1111},{"Blue Steel",42},{"Boreal Forest",77},{"Bright Water",579},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",411},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Freehand",581},{"Gamma Doppler",568},{"Gamma Doppler",569},{"Gamma Doppler",570},{"Gamma Doppler",571},{"Gamma Doppler",572},{"Lore",1106},{"Marble Fade",413},{"Night",40},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",621},{"Urban Masked",143}},
  [514]={{"Autotronic",1114},{"Black Laminate",1109},{"Blue Steel",42},{"Boreal Forest",77},{"Bright Water",579},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",411},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Freehand",581},{"Gamma Doppler",568},{"Gamma Doppler",569},{"Gamma Doppler",570},{"Gamma Doppler",571},{"Gamma Doppler",572},{"Lore",1104},{"Marble Fade",413},{"Night",40},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [515]={{"Autotronic",1115},{"Black Laminate",1110},{"Blue Steel",42},{"Boreal Forest",77},{"Bright Water",579},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",411},{"Doppler",617},{"Doppler",418},{"Doppler",618},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",619},{"Fade",38},{"Forest DDPAT",5},{"Freehand",581},{"Gamma Doppler",568},{"Gamma Doppler",569},{"Gamma Doppler",570},{"Gamma Doppler",571},{"Gamma Doppler",572},{"Lore",1105},{"Marble Fade",413},{"Night",40},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [516]={{"Autotronic",1118},{"Black Laminate",1113},{"Blue Steel",42},{"Boreal Forest",77},{"Bright Water",579},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",411},{"Doppler",617},{"Doppler",418},{"Doppler",618},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",619},{"Fade",38},{"Forest DDPAT",5},{"Freehand",581},{"Gamma Doppler",568},{"Gamma Doppler",569},{"Gamma Doppler",570},{"Gamma Doppler",571},{"Gamma Doppler",572},{"Lore",1108},{"Marble Fade",413},{"Night",40},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [517]={{"Blue Steel",42},{"Boreal Forest",77},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",410},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Marble Fade",413},{"Night Stripe",735},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",621},{"Urban Masked",143}},
  [518]={{"Blue Steel",42},{"Boreal Forest",77},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",410},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Marble Fade",413},{"Night Stripe",735},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [519]={{"Blue Steel",42},{"Boreal Forest",77},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",857},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Marble Fade",413},{"Night Stripe",735},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [520]={{"Blue Steel",42},{"Boreal Forest",77},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",857},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Marble Fade",413},{"Night Stripe",735},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [521]={{"Blue Steel",42},{"Boreal Forest",77},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",410},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Marble Fade",413},{"Night Stripe",735},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [522]={{"Blue Steel",42},{"Boreal Forest",77},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",857},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Marble Fade",413},{"Night Stripe",735},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [523]={{"Blue Steel",42},{"Boreal Forest",77},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",858},{"Doppler",417},{"Doppler",852},{"Doppler",853},{"Doppler",854},{"Doppler",855},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Marble Fade",856},{"Night Stripe",735},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [525]={{"Blue Steel",42},{"Boreal Forest",77},{"Case Hardened",44},{"Crimson Web",12},{"Damascus Steel",410},{"Doppler",417},{"Doppler",418},{"Doppler",419},{"Doppler",420},{"Doppler",421},{"Doppler",415},{"Doppler",416},{"Fade",38},{"Forest DDPAT",5},{"Marble Fade",413},{"Night Stripe",735},{"Rust Coat",414},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Tiger Tooth",409},{"Ultraviolet",98},{"Urban Masked",143}},
  [526]={{"Blue Steel",42},{"Boreal Forest",77},{"Case Hardened",44},{"Crimson Web",12},{"Fade",38},{"Forest DDPAT",5},{"Night Stripe",735},{"Safari Mesh",72},{"Scorched",175},{"Slaughter",59},{"Stained",43},{"Urban Masked",143}},
  [4725]={{"Jade",10085},{"Needle Point",10087},{"Unhinged",10088},{"Yellow-banded",10086}},
  [5027]={{"Bronzed",10008},{"Charred",10006},{"Guerrilla",10039},{"Snakebite",10007}},
  [5030]={{"Amphibious",10045},{"Arid",10019},{"Big Game",10074},{"Blaze",1407},{"Bronze Morph",10046},{"Creme Pinstripe",1408},{"Frosty",1406},{"Hedge Maze",10038},{"Nocts",10076},{"Occult",1417},{"Omega",10047},{"Pandora's Box",10037},{"Red Racer",1409},{"Scarlet Shamagh",10075},{"Slingshot",10073},{"Superconductor",10018},{"Ultra Violent",1410},{"Vice",10048},{"Violet Beadwork",1405}},
  [5031]={{"Black Tie",10072},{"Brocade Crane",1399},{"Brocade Flowers",1400},{"Convoy",10015},{"Crimson Weave",10016},{"Diamondback",10040},{"Dragon Fists",1401},{"Garden",1402},{"Hand Sweaters",1439},{"Imperial Plaid",10042},{"King Snake",10041},{"Lunar Weave",10013},{"Overtake",10043},{"Plum Quill",1412},{"Queen Jaguar",10071},{"Racing Green",10044},{"Rezan the Red",10069},{"Seigaiha",1404},{"Snow Leopard",10070},{"Wave Chaser",1398}},
  [5032]={{"Arboreal",10056},{"Badlands",10036},{"CAUTION!",10084},{"Cobalt Skulls",10053},{"Constrictor",10083},{"Desert Shamagh",10081},{"Duct Tape",10055},{"Giraffe",10082},{"Leather",10009},{"Overprint",10054},{"Slaughter",10021},{"Spruce DDPAT",10010}},
  [5033]={{"3rd Commando Company",10080},{"Blood Pressure",10079},{"Boom!",10027},{"Cool Mint",10028},{"Eclipse",10024},{"Finish Line",10077},{"Polygon",10052},{"POW!",10049},{"Smoke Out",10078},{"Spearmint",10026},{"Transport",10051},{"Turtle",10050}},
  [5034]={{"Big Swell",1437},{"Blackbook",1414},{"Buckshot",10062},{"Chocolate Chesterfield",1415},{"Cloud Chaser",1440},{"Crimson Kimono",10033},{"Crimson Web",10061},{"Emerald Web",10034},{"Fade",10063},{"Field Agent",10068},{"Forest DDPAT",10030},{"Foundation",10035},{"Lime Polycam",1413},{"Lt. Commander",10066},{"Marble Fade",10065},{"Mogul",10064},{"Pillow Punchers",1438},{"Sunburst",1416},{"Tiger Strike",10067}},
  [5035]={{"Case Hardened",10060},{"Emerald",10057},{"Mangrove",10058},{"Rattler",10059}},
}

local function skin_list_for(def)
    local names  = { "[ None ]" }
    local paints = { 0 }
    local src = def and SKINS[def]
    if src then
        for i = 1, #src do
            names[i+1]  = src[i][1]
            paints[i+1] = src[i][2]
        end
    end
    return names, paints
end

local ITEMS = {}
local function add_item(name, def, kind) ITEMS[#ITEMS+1] = { name = name, def = def, kind = kind } end

for i = 1, #KNIVES do
    local k = KNIVES[i]
    if k.def then add_item("[Knife] " .. k.name, k.def, "knife") end
end
for i = 1, #WEAPONS do
    add_item(WEAPONS[i].name, WEAPONS[i].def, "weapon")
end
for i = 1, #GLOVES do
    local g = GLOVES[i]
    add_item(g.def == 0 and "[Glove] Default (off)" or "[Glove] " .. g.name, g.def, "glove")
end

local itemNames = {}; for i = 1, #ITEMS do itemNames[i] = ITEMS[i].name end

local DEF_TO_ITEM = {}
for i = 1, #ITEMS do
    if ITEMS[i].kind ~= "glove" then DEF_TO_ITEM[ITEMS[i].def] = i end
end

local state = {
    cfg          = {},
    opts         = {},
    knifeDef     = nil,
    gloveDef     = nil,
    applied      = {},
    pendingReset = {},
    resetKnife   = false,
    resetGlove   = false,
    localModel       = nil,
    appliedLocalModel= nil,
    -- multiplayer model changer
    modelAssignments = {}, -- key -> path
    modelApplied     = {}, -- key -> last path we set
    modelPersist     = true,
    modelTargetMode  = 1,  -- 1 self, 2 teammates, 3 enemies, 4 selected
    modelCrashFix    = false, -- optional: throttle + safe precache + cache
}

local Config = {}

local g_activeDef = nil

local function item_ptr(wpn) return wpn + off.m_AttributeManager + off.m_Item end

local function safe_wear(wear)
    if not wear or wear <= 0 then return 0.0001 end
    return wear
end

local function write_fallback(wpn, paint, wear, seed, stat, statval)
    w_i32(wpn + off.m_nFallbackPaintKit, paint)
    w_f32(wpn + off.m_flFallbackWear, safe_wear(wear))
    w_i32(wpn + off.m_nFallbackSeed, seed)
    w_i32(wpn + off.m_nFallbackStatTrak, stat and (statval or 0) or -1)
end

local function mark_item_custom(item)
    w_u32(item + off.m_iItemIDHigh, 0xFFFFFFFF)
    w_u8 (item + off.m_bInitialized, 1)
    w_u8 (item + off.m_bDisallowSOC, 0)
    w_u8 (item + off.m_bRestoreCustomMat, 1)
end

local function refresh_econ(wpn)
    vcall_void_bool(wpn, 10, true)
    vcall_void_bool(wpn, 110, true)
end

-- Mesh group: 1 = modern UV, 2 = legacy UV. Wrong mask = crooked/mirrored texture.
local function weapon_mesh_mask(paint)
    if paint and LEGACY_PAINT[paint] then return 2 end
    return 1
end

-- Cheap sticky write (no engine rebuild). notify=true calls set_mesh_mask once on full apply.
local function write_mesh_group(ent, mask)
    if not valid(ent) or not off.m_MeshGroupMask or not off.m_modelState then return end
    local node = r_ptr(ent + off.m_pGameSceneNode)
    if not valid(node) then return end
    pcall(function() w_u64(node + off.m_modelState + off.m_MeshGroupMask, mask) end)
end

local function apply_mesh_mask(ent, mask, notify)
    write_mesh_group(ent, mask)
    if notify and fnptr.set_mesh_mask and valid(ent) then
        local node = r_ptr(ent + off.m_pGameSceneNode)
        if valid(node) then
            pcall(function() fnptr.set_mesh_mask(ffi.cast("void*", node), mask) end)
        end
    end
end

local skin_dbg = {}
local function dbg_paint(kind, paint, wpn, mask)
    local key = kind .. ":" .. tostring(paint)
    if skin_dbg[key] then return end
    skin_dbg[key] = true
    local rb = r_i32(wpn + off.m_nFallbackPaintKit)
    local leg = (paint and LEGACY_PAINT[paint]) and "yes" or "no"
    print(string.format("[changer] %s paint written=%d readback=%d mask=%s legacy=%s",
        kind, paint, rb, mask and tostring(mask) or "-", leg))
end

local function apply_knife_model(wpn)
    if fnptr.set_model then
        local vdata = r_ptr(wpn + off.m_nSubclassID + 8)
        if valid(vdata) then
            local s = read_cstr(vdata + off.m_szWorldModel, 160)
            if s:find("models/") and s:find("%.vmdl") then fnptr.set_model(ffi.cast("void*", wpn), s) end
        end
    end
    apply_mesh_mask(wpn, 2, true)
end

local function set_knife_subclass(wpn, def_target, quality)
    local item = item_ptr(wpn)
    w_u16(item + off.m_iItemDefinitionIndex, def_target)
    w_i32(item + off.m_iEntityQuality, quality)
    w_u32(wpn + off.m_nSubclassID, subclass_hash(def_target))
    if fnptr.update_subclass then fnptr.update_subclass(ffi.cast("void*", wpn)) end
    apply_knife_model(wpn)
    return item
end

local function process_knife(wpn, def_target, paint, wear, seed, stat, statval)
    local item = set_knife_subclass(wpn, def_target, 3)
    mark_item_custom(item)
    write_fallback(wpn, paint, wear, seed, stat, statval)
    refresh_econ(wpn)
    vcall_void(wpn, 195)
end

local function process_weapon(wpn, paint, wear, seed, stat, statval)
    mark_item_custom(item_ptr(wpn))
    write_fallback(wpn, paint, wear, seed, stat, statval)
    refresh_econ(wpn)
end

local function restore_weapon(wpn)
    write_fallback(wpn, 0, 0.0001, 0, false)
    refresh_econ(wpn)
end

local function restore_knife(wpn, pawn)
    local def_target = (r_u8(pawn + off.m_iTeamNum) == 2) and 59 or 42
    set_knife_subclass(wpn, def_target, 0)
    write_fallback(wpn, 0, 0.0001, 0, false)
    refresh_econ(wpn)
    vcall_void(wpn, 195)
end

local ATTR_STRUCT = 72

local game_alloc, game_free
local function resolve_mem()
    if game_alloc then return true end
    pcall(function() ffi.cdef[[ void* GetModuleHandleA(const char*); ]] end)
    pcall(function() ffi.cdef[[ void* GetProcAddress(void*, const char*); ]] end)
    local tier0
    pcall(function() tier0 = ffi.C.GetModuleHandleA("tier0.dll") end)
    if not tier0 then return false end
    local pa, pf
    pcall(function() pa = ffi.C.GetProcAddress(tier0, "MemAlloc_AllocFunc") end)
    pcall(function() pf = ffi.C.GetProcAddress(tier0, "MemAlloc_FreeFunc") end)
    if not pa or not pf then return false end
    pcall(function()
        game_alloc = ffi.cast("void*(*)(size_t)", pa)
        game_free  = ffi.cast("void(*)(void*)", pf)
    end)
    return game_alloc ~= nil and game_free ~= nil
end

local function glove_attr_remove(item)
    local addr = item + off.m_AttributeList + off.m_Attributes
    local size = r_ptr(addr)
    local ptr  = r_ptr(addr + 8)
    w_u64(addr, 0); w_u64(addr + 8, 0)
    if game_free and size ~= 0 and valid(ptr) then
        pcall(function() game_free(ffi.cast("void*", ptr)) end)
    end
end

local function glove_attr_set(item, paint, seed, wear)
    glove_attr_remove(item)
    if paint <= 0 then return end
    if not resolve_mem() then return end
    wear = safe_wear(wear)
    local raw  = game_alloc(ATTR_STRUCT * 3)
    local bptr = tonumber(ffi.cast("uintptr_t", raw))
    if not bptr or bptr == 0 then return end
    for i = 0, (ATTR_STRUCT * 3) / 8 - 1 do w_u64(bptr + i * 8, 0) end
    local function mk(i, def, val)
        local b = bptr + i * ATTR_STRUCT
        w_u16(b + 0x30, def); w_f32(b + 0x34, val); w_f32(b + 0x38, val)
    end
    mk(0, 6, paint)
    mk(1, 7, seed)
    mk(2, 8, wear)
    local addr = item + off.m_AttributeList + off.m_Attributes
    w_u64(addr, 3)
    w_u64(addr + 8, bptr)
end

local function local_account_id(base)
    local ctrl = r_ptr(base + off.dwLocalPlayerController)
    if not valid(ctrl) then return 0 end
    local sid = r_u64(ctrl + off.m_steamID)
    return tonumber(sid % 0x100000000)
end

local glove_key, glove_apply = nil, 0
local function apply_gloves(base, pawn, gdef, paint, wear, seed)
    local g    = pawn + off.m_EconGloves
    local cur  = r_u16(g + off.m_iItemDefinitionIndex)
    local init = r_u8 (g + off.m_bInitialized)
    local key  = gdef.."|"..paint.."|"..floor(wear*100000).."|"..seed

    if key ~= glove_key then glove_key = key; glove_apply = 6 end
    local engine_reset = (cur ~= gdef) or (init == 0)
    if engine_reset and glove_apply <= 0 then glove_apply = 2 end

    if glove_apply > 0 then
        local acc = local_account_id(base)
        w_u8 (g + off.m_bInitialized, 0)
        w_u16(g + off.m_iItemDefinitionIndex, gdef)
        w_i32(g + off.m_iEntityQuality, 3)
        w_u32(g + off.m_iItemIDHigh, 0xFFFFFFFF)
        w_u32(g + off.m_iItemIDLow,  0xFFFFFFFF)
        w_u32(g + off.m_iAccountID, acc)
        w_u32(g + off.m_OriginalOwnerXuidLow, acc)
        glove_attr_set(g, paint, seed, wear)
        w_u8 (g + off.m_bDisallowSOC, 0)
        w_u8 (g + off.m_bRestoreCustomMat, 1)
        w_u8 (g + off.m_bInitialized, 1)
        w_u8 (pawn + off.m_bNeedToReApplyGloves, 1)
        if fnptr.set_body_group then
            pcall(function() fnptr.set_body_group(ffi.cast("void*", pawn), "first_or_third_person", 1) end)
        end
        glove_apply = glove_apply - 1
    end
end

local function reset_gloves(pawn)
    local g = pawn + off.m_EconGloves
    w_u8 (g + off.m_bInitialized, 0)
    w_u16(g + off.m_iItemDefinitionIndex, 0)
    glove_attr_remove(g)
    w_u8 (pawn + off.m_bNeedToReApplyGloves, 1)
    glove_key, glove_apply = nil, 0
    if fnptr.set_body_group then
        pcall(function() fnptr.set_body_group(ffi.cast("void*", pawn), "first_or_third_person", 1) end)
    end
end

local function handle_to_entity(elist, hnd)
    if not valid(elist) or hnd == 0 or hnd == 0xFFFFFFFF then return nil end
    local idx   = band(hnd, 0x7FFF)
    local chunk = r_ptr(elist + 8 * rshift(idx, 9) + 16); if not valid(chunk) then return nil end
    local e     = r_ptr(chunk + 112 * band(idx, 0x1FF))
    if valid(e) and valid(r_ptr(e)) then return e end
    return nil
end

-- First-person weapon mesh only (never HudModelArms — prior AV).
local function apply_viewmodel_mesh(wpn, mask, elist, notify)
    if not elist or not off.m_hViewmodelAttachment then return end
    local h = r_u32(wpn + off.m_hViewmodelAttachment)
    if h == 0 or h == 0xFFFFFFFF then return end
    local att = handle_to_entity(elist, h)
    if att then apply_mesh_mask(att, mask, notify) end
end

local function apply_weapon_meshes(wpn, paint, elist, notify)
    local mask = weapon_mesh_mask(paint)
    apply_mesh_mask(wpn, mask, notify)
    apply_viewmodel_mesh(wpn, mask, elist, notify)
    return mask
end

local function pawn_alive(pawn)

    local ls = r_u8 (pawn + off.m_lifeState)
    local hp = r_i32(pawn + off.m_iHealth)
    return ls == 0 and hp > 0 and hp < 100000
end

local function in_game()
    local cl, so = off.dwNetworkGameClient, off.dwNetworkGameClient_signOnState
    -- missing offsets: do NOT assume in-game (avoids SetModel on bad ptrs in menu)
    if not cl or not so then return false end
    local eng = mem.GetModuleBase("engine2.dll"); if not eng then return false end
    local client = r_ptr(eng + cl); if not valid(client) then return false end
    return r_i32(client + so) == 6
end

local function get_live_local()
    local ok, lp = pcall(entities.GetLocalPlayer)
    if not ok or not lp then return nil end
    local alive = false
    pcall(function() alive = lp:IsAlive() end)
    return alive and lp or nil
end

local model_ffi_done = false
local function model_ffi()
    if model_ffi_done then return end
    model_ffi_done = true
    pcall(function() ffi.cdef[[
        typedef struct {
            uint32_t dwFileAttributes;
            uint32_t ftCreationLo, ftCreationHi;
            uint32_t ftAccessLo,   ftAccessHi;
            uint32_t ftWriteLo,    ftWriteHi;
            uint32_t nFileSizeHigh, nFileSizeLow;
            uint32_t dwReserved0,  dwReserved1;
            char     cFileName[260];
            char     cAlternateFileName[14];
        } AW_FIND_DATA;
        void*    FindFirstFileA(const char*, AW_FIND_DATA*);
        int      FindNextFileA(void*, AW_FIND_DATA*);
        int      FindClose(void*);
        uint32_t GetCurrentDirectoryA(uint32_t, char*);
        typedef struct {
            int32_t  m_nLength;
            uint32_t m_nAllocatedSize;
            union { char* p; char s[8]; } u;
        } AW_CBufStr;
    ]] end)
    pcall(function() ffi.cdef[[ void* GetModuleHandleA(const char*); ]] end)
    pcall(function() ffi.cdef[[ void* GetProcAddress(void*, const char*); ]] end)
end

local function find_invalid() return ffi.cast("void*", ffi.cast("intptr_t", -1)) end

local modelClock = (function()
    for _, fn in ipairs({
        function() return globals.RealTime() end,
        function() return globals.CurTime() end,
        function() return os.clock() end,
    }) do
        local ok, v = pcall(fn)
        if ok and type(v) == "number" then
            return fn
        end
    end
    return function() return 0 end
end)()

local function now_s()
    local ok, v = pcall(modelClock)
    if ok and type(v) == "number" then return v end
    return 0
end

local function models_root()
    model_ffi()
    local buf = ffi.new("char[?]", 1024)
    local n = ffi.C.GetCurrentDirectoryA(1024, buf)
    local cwd = ffi.string(buf, n)

    local root, count = cwd:gsub("[\\/]bin[\\/]win64.*$", "\\csgo")
    if count == 0 then return nil end
    return root
end

local SCAN_DIRS = { "characters", "agents", "models" }
local SKIP_DIRS_ALT = { exg = true, materials = true }

local g_modelScanAlt = false
local g_modelFilter  = ""

local function scan_into(dir, names, paths, opts)
    opts = opts or {}
    local fd = ffi.new("AW_FIND_DATA")
    local h = ffi.C.FindFirstFileA(dir .. "\\*", fd)
    if h == find_invalid() then return end
    repeat
        local nm = ffi.string(fd.cFileName)
        if nm ~= "." and nm ~= ".." then
            local full = dir .. "\\" .. nm
            if band(fd.dwFileAttributes, 0x10) ~= 0 then
                local low = nm:lower()
                if not (opts.skip_exg_mat and SKIP_DIRS_ALT[low]) then
                    scan_into(full, names, paths, opts)
                end
            elseif nm:sub(-7) == ".vmdl_c" then
                local stem = nm:sub(1, #nm - 7)
                if not stem:lower():match("_arms?$") then
                    local p = full:lower():find("\\csgo\\", 1, true)
                    if p then
                        local rel = full:sub(p + 6):gsub("\\", "/")
                        rel = rel:sub(1, #rel - 2)
                        local filt = opts.filter
                        if filt and filt ~= "" then
                            local fl = filt:lower()
                            if not stem:lower():find(fl, 1, true) and not rel:lower():find(fl, 1, true) then
                                -- skip non-matching name
                            else
                                names[#names + 1] = stem
                                paths[#paths + 1] = rel
                            end
                        else
                            names[#names + 1] = stem
                            paths[#paths + 1] = rel
                        end
                    end
                end
            end
        end
    until ffi.C.FindNextFileA(h, fd) == 0
    ffi.C.FindClose(h)
end

local g_modelNames, g_modelPaths
local function scan_models()
    if g_modelNames then return g_modelNames, g_modelPaths end
    local names, paths = { "[ OFF ]" }, { "" }
    pcall(function()
        local root = models_root()
        if not root then return end
        local opts = {
            skip_exg_mat = g_modelScanAlt and true or false,
            filter = (g_modelFilter and g_modelFilter ~= "") and g_modelFilter or nil,
        }
        if g_modelScanAlt then
            scan_into(root .. "\\characters", names, paths, opts)
        else
            for _, sub in ipairs(SCAN_DIRS) do
                scan_into(root .. "\\" .. sub, names, paths, opts)
            end
        end
    end)
    g_modelNames, g_modelPaths = names, paths
    return names, paths
end
local function rescan_models()
    g_modelNames, g_modelPaths = nil, nil
    return scan_models()
end

local g_IRS = nil
local PRECACHE_SIG = "40 53 55 57 48 81 EC 80 00 00 00 48 8B 01 49 8B E8 48 8B FA"
local g_precache_ok = nil -- nil=unknown, true/false decided
local g_precached_paths = {}
local function resolve_model_fns()
    if fnptr.precache and g_IRS and fnptr.cbuf_insert then return true end
    model_ffi()
    if not fn.precache then
        local a = mem.FindPattern("resourcesystem.dll", PRECACHE_SIG)
        if a and a ~= 0 then fn.precache = a end
    end
    if fn.precache and not fnptr.precache then
        fnptr.precache = ffi.cast("void*(*)(void*, void*, const char*)", fn.precache)
    end
    if not g_IRS then
        pcall(function()
            local rs = ffi.C.GetModuleHandleA("resourcesystem.dll")
            local ci = rs and ffi.C.GetProcAddress(rs, "CreateInterface")
            if ci then
                local CI = ffi.cast("void*(*)(const char*, int*)", ci)
                local irs = CI("ResourceSystem013", nil)
                if irs ~= nil then g_IRS = irs end
            end
        end)
    end
    if not fnptr.cbuf_insert then
        pcall(function()
            local t0 = ffi.C.GetModuleHandleA("tier0.dll")
            local ins = t0 and ffi.C.GetProcAddress(t0, "?Insert@CBufferString@@QEAAPEBDHPEBDH_N@Z")
            if ins then fnptr.cbuf_insert = ffi.cast("const char*(*)(void*, int, const char*, int, int)", ins) end
        end)
    end

    local ok = (fnptr.precache ~= nil and g_IRS ~= nil and fnptr.cbuf_insert ~= nil)
    if not ok then
        g_precache_ok = false
        return false
    end

    -- Safety check (Fix C): verify IRS vtable slot points to the same function as our signature.
    -- Only enabled when crash-fix mode is on.
    if state.modelCrashFix and g_precache_ok == nil then
        local decided = false
        local safe = false
        pcall(function()
            local vtbl = ffi.cast("void***", g_IRS)[0]
            local vt41 = tonumber(ffi.cast("uintptr_t", vtbl[41]))
            local sigp = tonumber(ffi.cast("uintptr_t", fn.precache))
            if vt41 and sigp and vt41 == sigp then
                safe = true
            else
                safe = false
            end
            decided = true
        end)
        if not decided then safe = false end
        g_precache_ok = safe
        if not g_precache_ok then
            print("[changer] precache unsafe (vtable mismatch) -> disabling precache calls")
        end
    end

    return true
end

local function precache_model(path)
    if path == nil or path == "" then return end
    if not resolve_model_fns() then return end
    if state.modelCrashFix then
        if g_precached_paths[path] then return end -- Fix D: cache per path
        if g_precache_ok == false then return end
    end
    local cb = ffi.new("AW_CBufStr")
    cb.m_nLength = 0
    cb.m_nAllocatedSize = 0xC0000008
    cb.u.p = nil
    pcall(function() fnptr.cbuf_insert(cb, 0, path, -1, 0) end)
    pcall(function() fnptr.precache(g_IRS, cb, "") end)
    if state.modelCrashFix then
        g_precached_paths[path] = true
    end
end

local function safe_set_model(pawn, path)
    if not fnptr.set_model then return false end
    if not valid(pawn) then return false end
    if type(path) ~= "string" or path == "" or not path:find("%.vmdl") then return false end
    if (pawn % 8) ~= 0 then return false end
    if not valid(r_ptr(pawn)) then return false end
    precache_model(path)
    local ok = pcall(function() fnptr.set_model(ffi.cast("void*", pawn), path) end)
    return ok
end

local function entity_by_index(idx)
    if not idx or idx <= 0 or idx > 0x7fff then return nil end
    if not off.dwEntityList then return nil end
    if not in_game() then return nil end
    local ok, ent = pcall(function()
        local base = mem.GetModuleBase(DLL); if not base then return nil end
        local elist = r_ptr(base + off.dwEntityList); if not valid(elist) then return nil end
        local chunk = r_ptr(elist + 8 * rshift(idx, 9) + 16); if not valid(chunk) then return nil end
        local e = r_ptr(chunk + 112 * band(idx, 0x1FF))
        if valid(e) and valid(r_ptr(e)) then return e end
        return nil
    end)
    if ok and valid(ent) then return ent end
    return nil
end

local function player_display_name(pawn)
    local n
    pcall(function()
        local ctrl = pawn:GetPropEntity("m_hController")
        if ctrl then
            n = ctrl:GetName()
            if (not n or n == "") then n = ctrl:GetPropString("m_iszPlayerName") end
        end
        if (not n or n == "") then n = pawn:GetName() end
    end)
    if n and n ~= "" then return n end
    local idx = 0
    pcall(function() idx = pawn:GetIndex() end)
    return "#" .. tostring(idx)
end

local function player_key(pawn, is_local)
    if is_local then return "local" end
    local sid
    pcall(function()
        local ctrl = pawn:GetPropEntity("m_hController")
        if ctrl then
            sid = ctrl:GetProp("m_steamID")
            if not sid or sid == 0 then
                if ctrl.GetPropInt then sid = ctrl:GetPropInt("m_steamID") end
            end
        end
    end)
    if sid and tonumber(sid) and tonumber(sid) > 0 then return "s:" .. tostring(sid) end
    local idx = 0
    pcall(function() idx = pawn:GetIndex() end)
    return "i:" .. tostring(idx)
end

local function collect_alive_players()
    local out = {}
    local ok_f, pawns = pcall(entities.FindByClass, "C_CSPlayerPawn")
    if not ok_f or not pawns then return out end

    local ok_lp, lp = pcall(entities.GetLocalPlayer)
    if not ok_lp or not lp then
        ok_lp, lp = pcall(entities.GetLocalPawn)
    end
    local lp_idx = -1
    if ok_lp and lp then pcall(function() lp_idx = lp:GetIndex() end) end

    for _, pawn in pairs(pawns) do
        local alive, idx, team = false, 0, 0
        pcall(function() alive = pawn:IsAlive() end)
        if alive then
            pcall(function() idx = pawn:GetIndex() end)
            pcall(function() team = pawn:GetTeamNumber() end)
            if idx and idx > 0 then
                local is_local = (idx == lp_idx)
                out[#out + 1] = {
                    pawn = pawn,
                    raw = nil, -- resolve lazily only when applying in-game
                    idx = idx,
                    team = team or 0,
                    is_local = is_local,
                    name = player_display_name(pawn),
                    key = player_key(pawn, is_local),
                }
            end
        end
    end
    return out
end

local function model_needs_apply(info, path)
    if not path or path == "" then return false end
    if state.modelPersist then
        local cur
        pcall(function() cur = info.pawn:GetModelName() end)
        if type(cur) == "string" and cur == path then return false end
        return true
    end
    return state.modelApplied[info.key] ~= path
end

local function apply_path_to_player(info, path)
    if not info or not path or path == "" then return false end
    if not in_game() then return false end

    local t = now_s()
    if state.modelCrashFix then
        -- Fix B: cooldown to avoid hammering resourcesystem.dll / SetModel in persist mode
        state.modelNextTry = state.modelNextTry or {}
        local nxt = state.modelNextTry[info.key]
        if nxt and t < nxt then
            return false
        end
    end

    if not model_needs_apply(info, path) then return false end
    local raw = info.raw
    if not valid(raw) then
        raw = entity_by_index(info.idx)
        info.raw = raw
    end
    if not valid(raw) then return false end
    if safe_set_model(raw, path) then
        state.modelApplied[info.key] = path
        if info.is_local then
            state.appliedLocalModel = path
            state.overrideActive = true
        end
        if state.modelCrashFix then
            -- small cooldown even on success to prevent rapid reapply loops
            state.modelNextTry[info.key] = t + 1.25
        end
        return true
    end
    if state.modelCrashFix then
        -- backoff on failure (prevents tight crash loops)
        state.modelNextTry[info.key] = t + 2.5
    end
    return false
end

local function apply_all_model_assignments()
    if not fnptr.set_model then return end
    if not in_game() then return end
    if not next(state.modelAssignments) and not (state.localModel and state.localModel ~= "") then
        return
    end
    if state.modelCrashFix then
        -- Fix B: global throttle (persist shouldn't run every CreateMove)
        state.modelNextGlobal = state.modelNextGlobal or 0
        local t = now_s()
        if t < (state.modelNextGlobal or 0) then return end
        state.modelNextGlobal = t + 0.25
    end

    local ok, players = pcall(collect_alive_players)
    if not ok or not players then return end
    for _, info in ipairs(players) do
        local path = state.modelAssignments[info.key]
        if (not path or path == "") and info.is_local then
            path = state.localModel
        end
        if path and path ~= "" then
            pcall(apply_path_to_player, info, path)
        end
    end
end

local function apply_local_model(pawn, lp)
    if not fnptr.set_model then return end
    if not valid(pawn) then return end
    if not in_game() then return end
    local path = state.modelAssignments["local"] or state.localModel
    if path and path ~= "" then
        if not lp then return end
        local info = { pawn = lp, raw = pawn, key = "local", is_local = true, idx = 0 }
        pcall(function() info.idx = lp:GetIndex() end)
        apply_path_to_player(info, path)
    else
        if state.appliedLocalModel == "OFF" then return end
        state.modelApplied["local"] = nil
        state.appliedLocalModel = "OFF"
    end
end

local function assign_models_to_target(mode, selected_key, path)
    if not in_game() then return 0 end
    local players = collect_alive_players()
    local lp_team = 0
    for _, info in ipairs(players) do
        if info.is_local then lp_team = info.team; break end
    end
    local count = 0
    for _, info in ipairs(players) do
        local match = false
        if mode == 1 then
            match = info.is_local
        elseif mode == 2 then
            match = (not info.is_local) and info.team == lp_team and lp_team > 1
        elseif mode == 3 then
            match = info.team ~= lp_team and info.team > 1
        elseif mode == 4 then
            match = selected_key and info.key == selected_key
        end
        if match then
            if path and path ~= "" then
                state.modelAssignments[info.key] = path
                if info.is_local then state.localModel = path end
                state.modelApplied[info.key] = nil
                pcall(apply_path_to_player, info, path)
            else
                state.modelAssignments[info.key] = nil
                state.modelApplied[info.key] = nil
                if info.is_local then
                    state.localModel = nil
                    state.appliedLocalModel = nil
                end
            end
            count = count + 1
        end
    end
    pcall(Config.save)
    return count
end

local function clear_model_assignments(mode, selected_key)
    return assign_models_to_target(mode, selected_key, nil)
end

local function clear_all_model_assignments()
    state.modelAssignments = {}
    state.modelApplied = {}
    state.localModel = nil
    state.appliedLocalModel = nil
    pcall(Config.save)
end

local function run()

    local lp = get_live_local()
    if not lp or not in_game() then
        if next(state.applied) then state.applied = {} end
        return
    end

    local base = mem.GetModuleBase(DLL); if not base then return end
    local ctrl = r_ptr(base + off.dwLocalPlayerController); if not valid(ctrl) then return end
    local myHandle = r_u32(ctrl + off.m_hPlayerPawn)
    if myHandle == 0 or myHandle == 0xFFFFFFFF then return end

    local elist = r_ptr(base + off.dwEntityList); if not valid(elist) then return end
    local pawn = handle_to_entity(elist, myHandle); if not valid(pawn) then return end
    if not valid(r_ptr(pawn + off.m_pGameSceneNode)) then return end

    if not pawn_alive(pawn) then
        if next(state.applied) then state.applied = {} end
        return
    end

    local applied = state.applied

    apply_all_model_assignments()
    apply_local_model(pawn, lp)

    if state.resetGlove then
        reset_gloves(pawn); state.resetGlove = false
    elseif state.gloveDef then
        local c = state.cfg[state.gloveDef]
        if c then apply_gloves(base, pawn, state.gloveDef, c.paint, c.wear, c.seed) end
    end

    local ws   = r_ptr(pawn + off.m_pWeaponServices); if not valid(ws) then return end
    local count= r_i32(ws + off.m_hMyWeapons)
    local arr  = r_ptr(ws + off.m_hMyWeapons + 8)
    if count<=0 or count>64 or not valid(arr) then return end

    local kdef = state.knifeDef
    local kc   = kdef and state.cfg[kdef]

    local did = false
    for i = 0, count - 1 do
        local wpn = handle_to_entity(elist, r_u32(arr + i*4))
        if wpn then

            if r_u32(wpn + off.m_hOwnerEntity) == myHandle then
                do
                    local def = r_u16(item_ptr(wpn) + off.m_iItemDefinitionIndex)
                    if is_knife(def) then
                        if state.resetKnife and not (kdef and kc) then
                            restore_knife(wpn, pawn)
                            applied["knife"] = nil
                            state.resetKnife = false
                            did = true
                        elseif kdef and kc then
                            local s = "k|"..kdef.."|"..kc.paint.."|"..kc.wear.."|"..kc.seed.."|"..tostring(kc.stat).."|"..tostring(kc.statval or 0)
                            if applied["knife"] ~= s then
                                process_knife(wpn, kdef, kc.paint, kc.wear, kc.seed, kc.stat, kc.statval)
                                apply_viewmodel_mesh(wpn, 2, elist, true)
                                dbg_paint("knife", kc.paint, wpn, 2)
                                applied["knife"] = s
                                did = true
                            else
                                -- sticky paint + mesh write only (no set_mesh_mask spam)
                                write_fallback(wpn, kc.paint, kc.wear, kc.seed, kc.stat, kc.statval)
                                apply_mesh_mask(wpn, 2, false)
                                apply_viewmodel_mesh(wpn, 2, elist, false)
                            end
                        end
                    else
                        local key = "w:" .. def
                        if state.pendingReset[def] then
                            restore_weapon(wpn)
                            applied[key] = nil
                            state.pendingReset[def] = nil
                            did = true
                        else
                            local c = state.cfg[def]
                            if c then
                                if c.paint > 0 then
                                    local s = "w|"..c.paint.."|"..c.wear.."|"..c.seed.."|"..tostring(c.stat).."|"..tostring(c.statval or 0)
                                    local mask = weapon_mesh_mask(c.paint)
                                    if applied[key] ~= s then
                                        process_weapon(wpn, c.paint, c.wear, c.seed, c.stat, c.statval)
                                        apply_weapon_meshes(wpn, c.paint, elist, true)
                                        dbg_paint("weapon", c.paint, wpn, mask)
                                        applied[key] = s
                                        did = true
                                    else
                                        write_fallback(wpn, c.paint, c.wear, c.seed, c.stat, c.statval)
                                        apply_mesh_mask(wpn, mask, false)
                                        apply_viewmodel_mesh(wpn, mask, elist, false)
                                    end
                                else
                                    if applied[key] ~= "w|none" then
                                        restore_weapon(wpn)
                                        applied[key] = "w|none"
                                        did = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if did and fnptr.regen_skins then fnptr.regen_skins() end
end

local function active_weapon_def()
    if not get_live_local() then return nil end
    local base = mem.GetModuleBase(DLL); if not base then return nil end
    local ctrl = r_ptr(base + off.dwLocalPlayerController); if not valid(ctrl) then return nil end
    local elist = r_ptr(base + off.dwEntityList)
    local pawn = handle_to_entity(elist, r_u32(ctrl + off.m_hPlayerPawn)); if not valid(pawn) then return nil end
    local ws   = r_ptr(pawn + off.m_pWeaponServices); if not valid(ws) then return nil end
    local wpn  = handle_to_entity(elist, r_u32(ws + off.m_hActiveWeapon)); if not wpn then return nil end
    return r_u16(item_ptr(wpn) + off.m_iItemDefinitionIndex)
end

local CFG_FILE = "awchanger.txt"

local function file_write(path, data)
    local ok = false
    pcall(function()
        local f = file.Open(path, "w")
        if f then f:Write(data); f:Close(); ok = true end
    end)
    return ok
end

local function file_read(path)
    local data
    pcall(function()
        local f = file.Open(path, "r")
        if f then data = f:Read(); f:Close() end
    end)
    return data
end

function Config.serialize()
    local lines = { "AWCFG1",
                    "K " .. tostring(state.knifeDef or 0),
                    "G " .. tostring(state.gloveDef or 0) }
    for def, c in pairs(state.cfg) do
        lines[#lines + 1] = string.format("E %d %d %.6f %d %d %s %d",
            def, c.paint or 0, c.wear or 0.0001, c.seed or 0, c.stat and 1 or 0, c.kind or "weapon", c.statval or 0)
    end
    for k, v in pairs(state.opts) do
        local tv = type(v)
        local tag = (tv == "boolean") and "b" or (tv == "number") and "n" or "s"
        local sv  = (tv == "boolean") and (v and "1" or "0") or tostring(v)
        lines[#lines + 1] = string.format("O %s %s %s", k, tag, sv)
    end
    if state.localModel and state.localModel ~= "" then
        lines[#lines + 1] = "L " .. state.localModel
    end
    lines[#lines + 1] = "P " .. (state.modelPersist and "1" or "0")
    for key, path in pairs(state.modelAssignments) do
        if key ~= "local" and type(path) == "string" and path ~= "" then
            lines[#lines + 1] = "A " .. key .. " " .. path
        end
    end
    return table.concat(lines, "\n")
end

function Config.parse(str)
    if type(str) ~= "string" or not str:find("AWCFG1", 1, true) then return nil end
    local newCfg, kdef, gdef, opts, lmodel = {}, nil, nil, {}, nil
    local persist, assigns = true, {}
    for line in str:gmatch("[^\r\n]+") do
        local t = line:sub(1, 1)
        if t == "K" then
            local v = tonumber(line:match("^K%s+(%-?%d+)")); if v and v ~= 0 then kdef = v end
        elseif t == "G" then
            local v = tonumber(line:match("^G%s+(%-?%d+)")); if v and v ~= 0 then gdef = v end
        elseif t == "E" then
            local d, p, w, s, st, kind, sv =
                line:match("^E%s+(%-?%d+)%s+(%-?%d+)%s+([%d%.eE%+%-]+)%s+(%-?%d+)%s+(%d)%s+(%a+)%s*(%d*)")
            d, p, w, s = tonumber(d), tonumber(p), tonumber(w), tonumber(s)
            if d then
                newCfg[d] = { paint = p or 0, wear = w or 0.0001, seed = s or 0,
                              stat = (st == "1"), kind = kind or "weapon", statval = tonumber(sv) or 0 }
            end
        elseif t == "O" then
            local k, tag, v = line:match("^O%s+(%S+)%s+(%a)%s+(.*)$")
            if k then
                if     tag == "b" then opts[k] = (v == "1")
                elseif tag == "n" then opts[k] = tonumber(v) or 0
                else                   opts[k] = v end
            end
        elseif t == "L" then
            local v = line:match("^L%s+(.+)$")
            if v and v ~= "" then lmodel = v end
        elseif t == "P" then
            local v = line:match("^P%s+(%d)")
            persist = (v == "1")
        elseif t == "A" then
            local k, p = line:match("^A%s+(%S+)%s+(.+)$")
            if k and p and p ~= "" then assigns[k] = p end
        end
    end
    return newCfg, kdef, gdef, opts, lmodel, persist, assigns
end

function Config.applyTable(newCfg, kdef, gdef, opts, lmodel, persist, assigns)
    for def, c in pairs(state.cfg) do
        if c.kind == "weapon" and not newCfg[def] then state.pendingReset[def] = true end
    end
    if state.knifeDef and state.knifeDef ~= kdef then state.resetKnife = true end
    if state.gloveDef and state.gloveDef ~= gdef then state.resetGlove = true end
    state.cfg      = newCfg
    state.knifeDef = kdef
    state.gloveDef = gdef
    state.opts     = opts or {}
    state.localModel = lmodel
    state.appliedLocalModel = nil
    state.applied  = {}
    state.modelPersist = (persist ~= false)
    state.modelCrashFix = not not state.opts.model_crashfix
    state.modelAssignments = assigns or {}
    if lmodel and lmodel ~= "" then state.modelAssignments["local"] = lmodel end
    state.modelApplied = {}
    g_modelScanAlt = not not state.opts.model_scan_alt
    g_modelFilter  = type(state.opts.model_filter) == "string" and state.opts.model_filter or ""
    g_modelNames, g_modelPaths = nil, nil

    -- if crash-fix got toggled via config, reset runtime caches
    state.modelNextTry = {}
    state.modelNextGlobal = 0
    g_precached_paths = {}
    g_precache_ok = nil
end

function Config.save() return file_write(CFG_FILE, Config.serialize()) end

function Config.load()
    local newCfg, kdef, gdef, opts, lmodel, persist, assigns = Config.parse(file_read(CFG_FILE))
    if not newCfg then return false end
    Config.applyTable(newCfg, kdef, gdef, opts, lmodel, persist, assigns)
    return true
end

local function commit()
    state.applied = {}
    Config.save()
end

local C = {}
C.items     = ITEMS
C.names     = itemNames
C.defToItem = DEF_TO_ITEM
C.offsets   = off

function C.skinList(def) return skin_list_for(def) end
function C.isKnife(def)  return is_knife(def) end
function C.activeDef()   return g_activeDef end
function C.knifeDef()    return state.knifeDef end
function C.getCfg(def)   return state.cfg[def] end

function C.apply(item, paint, wear, seed, stat, statval)
    if not item then return "nothing selected" end
    if item.kind == "glove" and item.def == 0 then
        state.cfg[0]     = nil
        state.gloveDef   = nil
        state.resetGlove = true
        commit()
        return "gloves: default"
    end
    state.cfg[item.def] = { paint = paint, wear = wear, seed = seed, stat = stat, statval = statval, kind = item.kind }
    if     item.kind == "knife" then state.knifeDef = item.def
    elseif item.kind == "glove" then state.gloveDef = item.def end
    commit()
    return string.format("applied: %s (paint %d)", item.name, paint)
end

function C.remove(item)
    if not item then return "nothing selected" end
    state.cfg[item.def] = nil
    if item.kind == "knife" then
        if state.knifeDef == item.def then state.knifeDef = nil end
        state.resetKnife = true
    elseif item.kind == "glove" then
        if state.gloveDef == item.def then state.gloveDef = nil end
        state.resetGlove = true
    else
        state.pendingReset[item.def] = true
    end
    commit()
    return "removed: " .. item.name
end

function C.resetAll()
    for def, c in pairs(state.cfg) do
        if c.kind == "weapon" then state.pendingReset[def] = true end
    end
    state.cfg        = {}
    state.knifeDef   = nil
    state.gloveDef   = nil
    state.resetKnife = true
    state.resetGlove = true
    commit()
    return "reset all"
end

function C.clearConfig()
    C.resetAll()
    pcall(function() file.Delete(CFG_FILE) end)
    return "config cleared"
end

function C.loadConfig() return Config.load() end
function C.getOpt(k)     return state.opts[k] end
function C.setOpt(k, v)  state.opts[k] = v; Config.save() end

function C.modelList()     return scan_models() end
function C.refreshModels() return rescan_models() end
function C.getModelScanAlt() return g_modelScanAlt end
function C.setModelScanAlt(on)
    g_modelScanAlt = not not on
    state.opts.model_scan_alt = g_modelScanAlt
    Config.save()
end
function C.getModelFilter() return g_modelFilter or "" end
function C.setModelFilter(q)
    g_modelFilter = tostring(q or "")
    state.opts.model_filter = g_modelFilter
    Config.save()
end
function C.getLocalModel() return state.localModel end
function C.setLocalModel(path)
    if path == nil or path == "" then
        state.localModel = nil
        state.modelAssignments["local"] = nil
    else
        state.localModel = path
        state.modelAssignments["local"] = path
    end
    state.appliedLocalModel = nil
    state.modelApplied["local"] = nil
    Config.save()
    return state.localModel
end

function C.getModelPersist() return state.modelPersist end
function C.setModelPersist(on)
    state.modelPersist = not not on
    state.opts.model_persist = state.modelPersist
    -- force re-check next tick
    state.modelApplied = {}
    state.appliedLocalModel = nil
    Config.save()
end

function C.getModelCrashFix() return not not state.modelCrashFix end
function C.setModelCrashFix(on)
    state.modelCrashFix = not not on
    state.opts.model_crashfix = state.modelCrashFix
    -- reset throttles/caches so behavior changes immediately
    state.modelNextTry = {}
    state.modelNextGlobal = 0
    g_precached_paths = {}
    g_precache_ok = nil
    Config.save()
end

function C.listPlayers()
    return collect_alive_players()
end

function C.applyModelTarget(mode, selected_key, path)
    state.modelTargetMode = mode or 1
    return assign_models_to_target(mode or 1, selected_key, path)
end

function C.clearModelTarget(mode, selected_key)
    return clear_model_assignments(mode or 1, selected_key)
end

function C.clearAllModels()
    clear_all_model_assignments()
end

callbacks.Register("CreateMove", function()
    local okd, d = pcall(active_weapon_def); g_activeDef = okd and d or nil
    local ok, err = pcall(run)
    if not ok then print("[changer] error: " .. tostring(err)) end
end)

resolve()
pcall(resolve_model_fns)
local n = 0; for _ in pairs(SKINS) do n = n + 1 end
print(string.format("[changer] ready: %d weapons, set_model=%s", n, fn.set_model and "ok" or "NIL"))
local ok_root, root_str = pcall(models_root)
print(string.format("[changer] precache: fn=%s irs=%s cbuf=%s root=%s",
    fnptr.precache and "ok" or "NIL", g_IRS and "ok" or "NIL",
    fnptr.cbuf_insert and "ok" or "NIL", tostring(ok_root and root_str or "ERR")))

return C

]====]

local function readFile(path)
    local data
    pcall(function()
        local f = file.Open(path, "r")
        if f then data = f:Read(); f:Close() end
    end)
    return data
end

local function writeFile(path, data)
    local ok = false
    pcall(function()
        local f = file.Open(path, "w")
        if f then f:Write(data); f:Close(); ok = true end
    end)
    return ok
end

local function fetchEngine()
    local source
    if type(http) == "table" and type(http.Get) == "function" then
        pcall(function()
            source = http.Get(ENGINE_URL .. "?rgn=" .. tostring({}):gsub("%W", ""))
        end)
        if type(source) ~= "string" or #source < ENGINE_MIN_SIZE then
            pcall(function() source = http.Get(ENGINE_URL) end)
        end
        if type(source) == "string" and #source >= ENGINE_MIN_SIZE then
            return source, "GitHub"
        end
    end
    source = readFile(ENGINE_CACHE)
    if type(source) == "string" and #source >= ENGINE_MIN_SIZE then return source, "cache" end
    if type(EMBEDDED_ENGINE) == "string" and #EMBEDDED_ENGINE >= ENGINE_MIN_SIZE then
        return EMBEDDED_ENGINE, "embedded portable"
    end
    return nil, "portable weapon engine unavailable"
end

local function fetchRuntimeOffsets()
    local json
    if type(http) == "table" and type(http.Get) == "function" then
        pcall(function() json = http.Get(OFFSETS_URL .. "?rgn=" .. tostring({}):gsub("%W", "")) end)
        if type(json) ~= "string" or #json < 1000 then pcall(function() json = http.Get(OFFSETS_URL) end) end
    end
    -- Validated fallback for the packaged CS2 build. Live cs2-dumper values,
    -- when available, replace these without making internet mandatory.
    local values = {
        dwEntityList = 39120480,
        dwLocalPlayerController = 37219232,
        dwNetworkGameClient = 9491632,
        dwNetworkGameClient_signOnState = 560,
    }
    if type(json) ~= "string" then return values end
    for _, key in ipairs({
        "dwEntityList", "dwLocalPlayerController",
        "dwNetworkGameClient", "dwNetworkGameClient_signOnState",
    }) do
        local parsed = tonumber(json:match('"' .. key .. '"%s*:%s*(%d+)'))
        if parsed then values[key] = parsed end
    end
    return values
end

local function replaceLiteral(source, old, new)
    local at = source:find(old, 1, true)
    if not at then return source, false end
    return source:sub(1, at - 1) .. new .. source:sub(at + #old), true
end

local runtimeOffsets = {}

local function prepareEngine(source)
    source = source:gsub("\r\n", "\n")
    if not (source:find("local function process_weapon", 1, true)
        and source:find("local function apply_gloves", 1, true)
        and source:find("local LEGACY_PAINT", 1, true)
        and source:find("local function apply_weapon_meshes", 1, true)
        and source:find("local function apply_viewmodel_mesh", 1, true)
        and source:find("if did and fnptr.regen_skins", 1, true)) then
        return nil, "preview weapon engine layout not recognized"
    end
    local okConfig, okCallback, okRuntime, okNetworkedAttributesOffset
    local okAttributesInitializedOffset, okFullItemIDOffset
    local okEntity, okController, okNetwork, okExtraPaints
    local okRespawn, okDeathState, okProfiles, okControlledPawn, okOwner, okActivePawn
    local okRefreshIndex, okWeaponPointerKey, okKnifePointerKey, okPostRegenMesh
    local okCompatibleCatalog, okLegacyApplyGuard
    local okNativeSkinFlow, okDirtyMeshNotify
    local okHudViewmodelFields, okHudViewmodelFallbacks, okHudViewmodelTraversal, okHudViewmodelCalls
    local okSafeGloveAttributes, okGloveTransitionGuard, okDeathTransitionGuard, okPlayableTeamGuard
    local okEngineThrottle, okSparseStickyState, okSparseKnife, okSparseWeapon
    local okNoModelTick, okNoModelResolve, okAgentApply
    local okNoModelDiagnostic
    local okCleanConfig, okSingleSelection, okWeaponEntityKey, okMaterialRetry, okRetryCommit, knifeEntityKeys
    local knifeKeyChanges, weaponKeyChanges

    -- Paint kits added after the pinned upstream build. Every pair was checked
    -- against the current CSGO-API weapon association; all use the modern mesh.
    local extraPaints = {
        [1]={{"Eastern Enigma",1458}}, [2]={{"Mystic Conjunction",1459}},
        [3]={{"Desert Seal",1457}}, [4]={{"Ghost Protocol",1450},{"Ifrit Lattice",1460}},
        [7]={{"AUTOEXEC",1449},{"Consequence of the Jinn",1466}},
        [8]={{"Signal Scanner",1452},{"Lapis Lazuli",1464}},
        [9]={{"Sovereign Flame",1465},{"Black Box",1467}},
        [10]={{"Snake Song",1461},{"Corp Defense",1477}},
        [16]={{"Dark Operative",1446},{"Falak",1463}},
        [17]={{"Video Cam",1448},{"Arabesque Mosaic",1454}},
        [25]={{"Black Site",1471}}, [26]={{"Traitor",1472}},
        [29]={{"Lunar Wyrm",1475}}, [30]={{"Perimeter",1447},{"Sultan",1462}},
        [33]={{"Base-2",1468}}, [34]={{"Spy Prototype",1469},{"Dune Asp",1473}},
        [35]={{"Smart Gun",1442},{"Morning Sun",1474}}, [36]={{"Lotus Imprint",1455}},
        [38]={{"Sirocco Script",1453},{"Arctic Camo Panels",1470}},
        [60]={{"Fatal Glitch",1476}}, [61]={{"Spiral Glitch",1451}},
        [63]={{"Hydraulics",1443}}, [64]={{"Monarch",1445}},
    }
    local addedPaints = 0
    for def, entries in pairs(extraPaints) do
        local marker = "  [" .. tostring(def) .. "]={{"
        local first = source:find(marker, 1, true)
        local lineEnd = first and source:find("\n", first, true)
        if first and lineEnd then
            local line = source:sub(first, lineEnd - 1)
            local close = line:find("}},", 1, true) or line:find("}}", 1, true)
            if close then
                local append = {}
                for _, entry in ipairs(entries) do
                    local token = string.format('{%q,%d}', entry[1], entry[2])
                    if not line:find("," .. tostring(entry[2]) .. "}", 1, true) then
                        append[#append + 1] = token
                        addedPaints = addedPaints + 1
                    end
                end
                if #append > 0 then
                    line = line:sub(1, close - 1) .. "," .. table.concat(append, ",") .. line:sub(close)
                    source = source:sub(1, first - 1) .. line .. source:sub(lineEnd)
                end
            end
        end
    end
    okExtraPaints = addedPaints == 34

    -- Keep every paint kit associated with the selected weapon. Legacy paints
    -- use their own mesh group later in the native application flow.
    source, okCompatibleCatalog = replaceLiteral(source, [[local function skin_list_for(def)
    local names  = { "[ None ]" }
    local paints = { 0 }
    local src = def and SKINS[def]
    if src then
        for i = 1, #src do
            names[i+1]  = src[i][1]
            paints[i+1] = src[i][2]
        end
    end
    return names, paints
end]], [[local function skin_list_for(def)
    local names  = { "[ None ]" }
    local paints = { 0 }
    local src = def and SKINS[def]
    if src then
        for i = 1, #src do
            names[i+1]  = src[i][1]
            paints[i+1] = src[i][2]
        end
    end
    return names, paints
end]])

    source, okConfig = replaceLiteral(source,
        'local CFG_FILE = "awchanger.txt"',
        'local CFG_FILE = "rgnweapons_config.txt"')
    source, okCallback = replaceLiteral(source,
        'callbacks.Register("CreateMove", function()',
        'callbacks.Register("CreateMove", "rgnMultitool_WeaponsEngine", function()')
    local runtimeLiteral = string.format(
        "{ dwEntityList=%s, dwLocalPlayerController=%s, dwNetworkGameClient=%s, dwNetworkGameClient_signOnState=%s }",
        tostring(runtimeOffsets.dwEntityList), tostring(runtimeOffsets.dwLocalPlayerController),
        tostring(runtimeOffsets.dwNetworkGameClient), tostring(runtimeOffsets.dwNetworkGameClient_signOnState))
    source, okRuntime = replaceLiteral(source,
        'local off = {}',
        'local off = {}\nlocal rgnRuntimeOffsets = ' .. runtimeLiteral)

    source, okNetworkedAttributesOffset = replaceLiteral(source,
        '    m_AttributeList        = "m_AttributeList",\n    m_Attributes           = "m_Attributes",',
        '    m_AttributeList        = "m_AttributeList",\n    m_NetworkedDynamicAttributes = "m_NetworkedDynamicAttributes",\n    m_Attributes           = "m_Attributes",')
    source, okAttributesInitializedOffset = replaceLiteral(source,
        '    m_AttributeManager     = { "m_AttributeManager", "C_EconEntity" },\n    m_Item                 = "m_Item",',
        '    m_AttributeManager     = { "m_AttributeManager", "C_EconEntity" },\n    m_bAttributesInitialized = { "m_bAttributesInitialized", "C_EconEntity" },\n    m_Item                 = "m_Item",')
    source, okFullItemIDOffset = replaceLiteral(source,
        '    m_iItemIDLow           = "m_iItemIDLow",\n    m_iItemIDHigh          = "m_iItemIDHigh",',
        '    m_iItemID              = "m_iItemID",\n    m_iItemIDLow           = "m_iItemIDLow",\n    m_iItemIDHigh          = "m_iItemIDHigh",')

    -- Never use stale hardcoded RVAs after a CS2 update. Pattern results are
    -- preferred; current cs2-dumper offsets are the validated fallback.
    source, okEntity = replaceLiteral(source, [[    if not off.dwEntityList then
        off.dwEntityList = FALLBACK_ENTITYLIST
        print(string.format("[changer] entlist pattern miss, using fallback RVA 0x%X", FALLBACK_ENTITYLIST))
    end]], [[    if not off.dwEntityList then
        off.dwEntityList = rgnRuntimeOffsets.dwEntityList
        print("[changer] entity-list pattern miss; using current cs2-dumper offset")
    end]])
    source, okController = replaceLiteral(source, [[    if not off.dwLocalPlayerController then
        off.dwLocalPlayerController = FALLBACK_LOCALCTRL
        print(string.format("[changer] localctrl pattern miss, using fallback RVA 0x%X", FALLBACK_LOCALCTRL))
    end]], [[    if not off.dwLocalPlayerController then
        off.dwLocalPlayerController = rgnRuntimeOffsets.dwLocalPlayerController
        print("[changer] local-controller pattern miss; using current cs2-dumper offset")
    end]])
    source, okNetwork = replaceLiteral(source, [[    off.dwNetworkGameClient     = sig_rva(eb, "engine2.dll", "48 89 3D ?? ?? ?? ?? FF 87", 7)
    off.dwNetworkGameClient_signOnState = sig_disp("engine2.dll", "44 8B 81 ?? ?? ?? ?? 48 8D 0D")]], [[    off.dwNetworkGameClient = sig_rva(eb, "engine2.dll", "48 89 3D ?? ?? ?? ?? FF 87", 7)
        or rgnRuntimeOffsets.dwNetworkGameClient
    off.dwNetworkGameClient_signOnState = sig_disp("engine2.dll", "44 8B 81 ?? ?? ?? ?? 48 8D 0D")
        or rgnRuntimeOffsets.dwNetworkGameClient_signOnState]])

    -- The current client moved CEconEntity::OnDataChanged from vtable 110 to
    -- 111. Index 110 now returns immediately and cannot rebuild a paint.
    source, okRefreshIndex = replaceLiteral(source, [[local function refresh_econ(wpn)
    vcall_void_bool(wpn, 10, true)
    vcall_void_bool(wpn, 110, true)
end]], [[local function refresh_econ(wpn)
    vcall_void_bool(wpn, 10, true)
    vcall_void_bool(wpn, 111, true)
end]])

    -- m_nFallbackPaintKit is not the final source used by every CS2 material.
    -- Once the econ item has been initialized, paint/wear are also cached in
    -- its dynamic attribute vector (definitions 6 and 8). Preserve every
    -- engine-owned entry and append only paint/wear when either one is absent.
    source, okWeaponAttributes = replaceLiteral(source, [[local function mark_item_custom(item)
    w_u32(item + off.m_iItemIDHigh, 0xFFFFFFFF)
    w_u8 (item + off.m_bInitialized, 1)
    w_u8 (item + off.m_bDisallowSOC, 0)
    w_u8 (item + off.m_bRestoreCustomMat, 1)
end]], [[local rgn_item_alloc
local function alloc_item_attributes(bytes)
    if not rgn_item_alloc then
        pcall(function() ffi.cdef("void* GetModuleHandleA(const char*); void* GetProcAddress(void*, const char*);") end)
        local tier0
        pcall(function() tier0 = ffi.C.GetModuleHandleA("tier0.dll") end)
        if tier0 then
            local proc
            pcall(function() proc = ffi.C.GetProcAddress(tier0, "MemAlloc_AllocFunc") end)
            if proc then rgn_item_alloc = ffi.cast("void*(*)(size_t)", proc) end
        end
    end
    if not rgn_item_alloc then return nil end
    local raw
    pcall(function() raw = rgn_item_alloc(bytes) end)
    local ptr
    pcall(function() ptr = tonumber(ffi.cast("uintptr_t", raw)) end)
    return valid(ptr) and ptr or nil
end

local function sync_weapon_attributes(wpn, paint, wear)
    local item = item_ptr(wpn)
    local changed = false
    wear = safe_wear(wear)
    local function sync_list(listOffset, createMissing)
        if type(listOffset) ~= "number" then return end
        local addr = item + listOffset + off.m_Attributes
        local count = r_u32(addr)
        local ptr = r_ptr(addr + 8)
        if count > 32 or (count > 0 and not valid(ptr)) then return end
        local foundPaint, foundWear = false, false
        for i = 0, count - 1 do
            local attr = ptr + i * 72
            local definition = r_u16(attr + 0x30)
            if definition == 6 then
                w_f32(attr + 0x34, paint); w_f32(attr + 0x38, paint)
                foundPaint = true
                changed = true
            elseif definition == 8 then
                w_f32(attr + 0x34, wear); w_f32(attr + 0x38, wear)
                foundWear = true
                changed = true
            end
        end
        if not createMissing or (foundPaint and foundWear) then return end
        local missing = (foundPaint and 0 or 1) + (foundWear and 0 or 1)
        local newCount = count + missing
        local newPtr = alloc_item_attributes(newCount * 72)
        if not newPtr then return end
        for q = 0, newCount * 9 - 1 do w_u64(newPtr + q * 8, 0) end
        if count > 0 then
            for q = 0, count * 9 - 1 do w_u64(newPtr + q * 8, r_u64(ptr + q * 8)) end
        end
        local at = count
        local function append(definition, value)
            local attr = newPtr + at * 72
            w_u16(attr + 0x30, definition)
            w_f32(attr + 0x34, value); w_f32(attr + 0x38, value)
            at = at + 1
        end
        if not foundPaint then append(6, paint) end
        if not foundWear then append(8, wear) end
        w_u64(addr, newCount)
        w_u64(addr + 8, newPtr)
        changed = true
    end
    sync_list(off.m_AttributeList, true)
    sync_list(off.m_NetworkedDynamicAttributes, false)
    return changed
end

local function mark_item_custom(item, paint)
    -- A different low ID invalidates the material cache while High=-1 keeps
    -- fallback attributes authoritative. Toggle initialized before rewriting,
    -- following the same safe rebuild sequence already used by gloves.
    if paint ~= nil then
        w_u8 (item + off.m_bInitialized, 0)
        local cacheID = 0x40000000 + ((tonumber(paint) or 0) % 0x3FFFFFFF)
        w_u64(item + off.m_iItemID, cacheID)
        w_u32(item + off.m_iItemIDLow, cacheID)
    end
    w_u32(item + off.m_iItemIDHigh, 0xFFFFFFFF)
    w_u8 (item + off.m_bInitialized, 1)
    w_u8 (item + off.m_bDisallowSOC, 0)
    w_u8 (item + off.m_bRestoreCustomMat, 1)
end]])

    source, okProcessAttributes = replaceLiteral(source, [[local function process_weapon(wpn, paint, wear, seed, stat, statval)
    mark_item_custom(item_ptr(wpn))
    write_fallback(wpn, paint, wear, seed, stat, statval)
    refresh_econ(wpn)
end]], [[local function replace_weapon_attributes(wpn, paint, wear, seed)
    local item = item_ptr(wpn)
    local addr = item + off.m_AttributeList + off.m_Attributes
    local fresh = alloc_item_attributes(72 * 3)
    if not fresh then return false end
    for q = 0, 26 do w_u64(fresh + q * 8, 0) end
    local function put(index, definition, value)
        local attr = fresh + index * 72
        w_u16(attr + 0x30, definition)
        w_f32(attr + 0x34, value)
        w_f32(attr + 0x38, value)
    end
    put(0, 6, math.max(0, tonumber(paint) or 0))
    put(1, 7, math.max(0, tonumber(seed) or 0))
    put(2, 8, safe_wear(wear))
    -- The current native changer rebuilds from exactly paint, seed and wear.
    w_u64(addr, 3)
    w_u64(addr + 8, fresh)
    return true
end

local function process_weapon(wpn, paint, wear, seed, stat, statval)
    local item = item_ptr(wpn)
    mark_item_custom(item, paint)
    write_fallback(wpn, paint, wear, seed, stat, statval)
    if not replace_weapon_attributes(wpn, paint, wear, seed) then
        sync_weapon_attributes(wpn, paint, wear)
    end
    w_u8(wpn + off.m_bAttributesInitialized, 0)
end

local function finalize_weapon_skin(wpn)
    -- Current CEconEntity::update_skin(bool): bit 0 must be set. Passing 2
    -- skips material reconstruction and leaves legacy finishes black/default.
    local update = vfunc(wpn, 111)
    if update then
        ffi.cast("void(*)(void*, int)", update)(ffi.cast("void*", wpn), 1)
    end
    vcall_void(wpn, 107)
    w_u8(wpn + off.m_bAttributesInitialized, 1)
end]])

    source, okStickyAttributes = replaceLiteral(source, [[                                        write_fallback(wpn, c.paint, c.wear, c.seed, c.stat, c.statval)
                                        apply_mesh_mask(wpn, mask, false)]], [[                                        write_fallback(wpn, c.paint, c.wear, c.seed, c.stat, c.statval)
                                        sync_weapon_attributes(wpn, c.paint, c.wear)
                                        apply_mesh_mask(wpn, mask, false)]])

    -- A paint resource may finish loading after the first rebuild. Perform a
    -- handful of spaced full applications only after a user change. This is
    -- event-driven and has no steady-state FPS cost.
    source, okMaterialRetry = replaceLiteral(source, [[    local applied = state.applied

    apply_all_model_assignments()]], [[    local applied = state.applied
    local retryNow = 0
    pcall(function() retryNow = globals.RealTime() end)
    -- Deathmatch can create the weapon and its first-person attachment a few
    -- frames after the pawn becomes alive. Repeat only the complete spawn
    -- initialization, with a short bounded schedule, so the knife cannot keep
    -- a stale/default viewmodel after a rapid death/respawn cycle.
    if (state.rgnRespawnRetries or 0) > 0 and retryNow >= (state.rgnRespawnNext or 0) then
        state.rgnRespawnRetries = state.rgnRespawnRetries - 1
        state.rgnRespawnNext = retryNow + 0.25
        state.applied = {}
        applied = state.applied
    end
    if (state.rgnMaterialRetries or 0) > 0 and retryNow >= (state.rgnMaterialNext or 0) then
        state.rgnMaterialRetries = state.rgnMaterialRetries - 1
        state.rgnMaterialNext = retryNow + 0.35
        state.applied = {}
        applied = state.applied
    end

    apply_all_model_assignments()]])

    -- Preview's sticky mesh writes are useful, but its cache is keyed by item
    -- definition. Key it by the concrete entity so a pickup/recreated weapon
    -- always receives the full custom-item initialization and material rebuild.
    source, knifeKeyChanges = source:gsub('applied%["knife"%]', 'applied[wpn]')
    source, weaponKeyChanges = source:gsub('local key = "w:" %.%. def', 'local key = wpn')
    okKnifePointerKey = knifeKeyChanges == 3
    okWeaponPointerKey = weaponKeyChanges == 1
    okWeaponEntityKey = source:find("applied[wpn]", 1, true) ~= nil
    knifeEntityKeys = okWeaponEntityKey and 3 or 0

    -- Resolve the pawn Aimware currently considers local. Unlike the original
    -- controller handle, this follows a bot taken over after the player dies.
    source, okControlledPawn = replaceLiteral(source, [[    local base = mem.GetModuleBase(DLL); if not base then return end
    local ctrl = r_ptr(base + off.dwLocalPlayerController); if not valid(ctrl) then return end
    local myHandle = r_u32(ctrl + off.m_hPlayerPawn)
    if myHandle == 0 or myHandle == 0xFFFFFFFF then return end]], [[    local base = mem.GetModuleBase(DLL); if not base then return end
    local myHandle
    pcall(function() myHandle = tonumber(lp:GetIndex()) end)
    if not myHandle or myHandle <= 0 then
        local ctrl = r_ptr(base + off.dwLocalPlayerController); if not valid(ctrl) then return end
        myHandle = r_u32(ctrl + off.m_hPlayerPawn)
    end
    if not myHandle or myHandle == 0 or myHandle == 0xFFFFFFFF then return end]])

    source, okDeathState = replaceLiteral(source, [[    local lp = get_live_local()
    if not lp or not in_game() then
        if next(state.applied) then state.applied = {} end
        return
    end]], [[    local lp = get_live_local()
    if not lp or not in_game() then
        if next(state.applied) then state.applied = {} end
        state.rgnWasAlive = false
        return
    end]])

    -- A handle includes serial bits while Entity:GetIndex returns only its
    -- entity index. Comparing the masked index supports both representations.
    source, okOwner = replaceLiteral(source,
        '            if r_u32(wpn + off.m_hOwnerEntity) == myHandle then',
        '            if band(r_u32(wpn + off.m_hOwnerEntity), 0x7FFF) == band(myHandle, 0x7FFF) then')

    source, okActivePawn = replaceLiteral(source, [[local function active_weapon_def()
    if not get_live_local() then return nil end
    local base = mem.GetModuleBase(DLL); if not base then return nil end
    local ctrl = r_ptr(base + off.dwLocalPlayerController); if not valid(ctrl) then return nil end
    local elist = r_ptr(base + off.dwEntityList)
    local pawn = handle_to_entity(elist, r_u32(ctrl + off.m_hPlayerPawn)); if not valid(pawn) then return nil end]], [[local function active_weapon_def()
    local lp = get_live_local(); if not lp then return nil end
    local base = mem.GetModuleBase(DLL); if not base then return nil end
    local elist = r_ptr(base + off.dwEntityList)
    local pawnIndex
    pcall(function() pawnIndex = tonumber(lp:GetIndex()) end)
    local pawn = pawnIndex and handle_to_entity(elist, pawnIndex) or nil
    if not valid(pawn) then
        local ctrl = r_ptr(base + off.dwLocalPlayerController); if not valid(ctrl) then return nil end
        pawn = handle_to_entity(elist, r_u32(ctrl + off.m_hPlayerPawn))
    end
    if not valid(pawn) then return nil end]])

    -- Team/map transitions and Deathmatch respawns may replace the pawn or
    -- reuse the same handle. Track the alive edge as well as handle/team, then
    -- schedule four bounded refreshes while CS2 finishes creating inventory.
    source, okRespawn = replaceLiteral(source, [[    local pawn = handle_to_entity(elist, myHandle); if not valid(pawn) then return end
    if not valid(r_ptr(pawn + off.m_pGameSceneNode)) then return end]], [[    local pawn = handle_to_entity(elist, myHandle); if not valid(pawn) then return end
    if not valid(r_ptr(pawn + off.m_pGameSceneNode)) then return end

    local currentTeam = r_u8(pawn + off.m_iTeamNum)
    local freshLife = state.rgnWasAlive ~= true
    if freshLife or state.lastPawnHandle ~= myHandle or state.lastTeam ~= currentTeam then
        state.lastPawnHandle = myHandle
        state.lastTeam = currentTeam
        state.rgnWasAlive = true
        state.applied = {}
        glove_key, glove_apply = nil, 6
        local spawnNow = 0
        pcall(function() spawnNow = globals.RealTime() end)
        state.rgnRespawnRetries = 4
        state.rgnRespawnNext = spawnNow + 0.15
    end]])

    -- Keep the broad custom-character subsystem disabled. The replacement
    -- below applies only a user-selected official CS2 agent to the local pawn.
    source, okNoModelTick = replaceLiteral(source, [[    apply_all_model_assignments()
    apply_local_model(pawn, lp)]], [[    apply_rgn_agent(pawn, lp)]])
    source, okNoModelResolve = replaceLiteral(source,
        'pcall(resolve_model_fns)',
        'pcall(resolve_model_fns) -- official-agent precache support')
    source, okAgentApply = replaceLiteral(source, [[local function apply_local_model(pawn, lp)
    if not fnptr.set_model then return end
    if not valid(pawn) then return end
    if not in_game() then return end
    local path = state.modelAssignments["local"] or state.localModel
    if path and path ~= "" then
        if not lp then return end
        local info = { pawn = lp, raw = pawn, key = "local", is_local = true, idx = 0 }
        pcall(function() info.idx = lp:GetIndex() end)
        apply_path_to_player(info, path)
    else
        if state.appliedLocalModel == "OFF" then return end
        state.modelApplied["local"] = nil
        state.appliedLocalModel = "OFF"
    end
end]], [[local function apply_local_model(pawn, lp)
    -- Disabled: arbitrary character models belong to rgnSKINS.
end

local function apply_rgn_agent(pawn, lp)
    local multi = rawget(_G, "RGN_MULTITOOL_STATE")
    if multi and multi.characterMode ~= "agents" then return end
    if not state.opts.rgn_agent_enabled then
        state.modelApplied["rgn-agent"] = nil
        return
    end
    if not lp or not valid(pawn) or not in_game() then return end
    local team = r_u8(pawn + off.m_iTeamNum)
    local path = team == 3 and state.opts.rgn_agent_ct or team == 2 and state.opts.rgn_agent_t or nil
    if type(path) ~= "string" or path == "" or not path:find("^agents/models/") or not path:find("%.vmdl$") then
        return
    end
    local info = { pawn = lp, raw = pawn, key = "rgn-agent", is_local = false, idx = 0 }
    pcall(function() info.idx = lp:GetIndex() end)
    apply_path_to_player(info, path)
end]])
    source, okNoModelDiagnostic = replaceLiteral(source, [[local ok_root, root_str = pcall(models_root)
print(string.format("[changer] precache: fn=%s irs=%s cbuf=%s root=%s",
    fnptr.precache and "ok" or "NIL", g_IRS and "ok" or "NIL",
    fnptr.cbuf_insert and "ok" or "NIL", tostring(ok_root and root_str or "ERR")))]], [[print("[rgnWEAPONS engine] character filesystem/model diagnostics disabled")]])

    -- Preview applies the mesh before regenerate_weapon_skins; the global
    -- rebuild then restores the stock mask on normal weapons. Make the mesh
    -- notification the final operation. This mirrors the working knife path
    -- while retaining preview's modern/legacy paint classification.
    source, okPostRegenMesh = replaceLiteral(source, [[    if did and fnptr.regen_skins then fnptr.regen_skins() end
end]], [[    if did and fnptr.regen_skins then fnptr.regen_skins() end
    if did then
        for i = 0, count - 1 do
            local wpn = handle_to_entity(elist, r_u32(arr + i * 4))
            if wpn and band(r_u32(wpn + off.m_hOwnerEntity), 0x7FFF) == band(myHandle, 0x7FFF) then
                local def = r_u16(item_ptr(wpn) + off.m_iItemDefinitionIndex)
                if is_knife(def) then
                    if kdef and kc then
                        apply_mesh_mask(wpn, 2, true)
                        apply_viewmodel_mesh(wpn, 2, elist, true)
                    end
                else
                    local c = state.cfg[def]
                    if c and c.paint > 0 then apply_weapon_meshes(wpn, c.paint, elist, true) end
                end
            end
        end
    end
end]])

    -- Reuse the engine serializer for complete, lightweight profile snapshots.
    source, okProfiles = replaceLiteral(source,
        'function C.loadConfig() return Config.load() end',
        [[function C.loadConfig()
    local ok = Config.load()
    if ok then Config.save() end
    return ok
end
function C.exportConfig() return Config.serialize() end
function C.importConfig(data)
    local cfg, knife, glove, opts, model, persist, assignments = Config.parse(data)
    if not cfg then return false end
    Config.applyTable(cfg, knife, glove, opts, model, persist, assignments)
    Config.save()
    return true
end]])

    -- Older selections remained in cfg even though only one knife/glove can be
    -- active. Prune them on load/import to prevent stale glove states.
    source, okCleanConfig = replaceLiteral(source,
        'function Config.applyTable(newCfg, kdef, gdef, opts, lmodel, persist, assigns)\n    for def, c in pairs(state.cfg) do',
        [[function Config.applyTable(newCfg, kdef, gdef, opts, lmodel, persist, assigns)
    for def, c in pairs(newCfg) do
        if (c.kind == "knife" and def ~= kdef) or (c.kind == "glove" and def ~= gdef) then
            newCfg[def] = nil
        end
    end
    for def, c in pairs(state.cfg) do]])

    source, okLegacyApplyGuard = replaceLiteral(source, [[function C.apply(item, paint, wear, seed, stat, statval)
    if not item then return "nothing selected" end]], [[function C.apply(item, paint, wear, seed, stat, statval)
    if not item then return "nothing selected" end]])

    source, okSingleSelection = replaceLiteral(source, [[    state.cfg[item.def] = { paint = paint, wear = wear, seed = seed, stat = stat, statval = statval, kind = item.kind }
    if     item.kind == "knife" then state.knifeDef = item.def
    elseif item.kind == "glove" then state.gloveDef = item.def end]], [[    if item.kind == "knife" and state.knifeDef and state.knifeDef ~= item.def then
        state.cfg[state.knifeDef] = nil
    elseif item.kind == "glove" and state.gloveDef and state.gloveDef ~= item.def then
        state.cfg[state.gloveDef] = nil
    end
    state.cfg[item.def] = { paint = paint, wear = wear, seed = seed, stat = stat, statval = statval, kind = item.kind }
    if     item.kind == "knife" then state.knifeDef = item.def
    elseif item.kind == "glove" then state.gloveDef = item.def end]])

    source, okRetryCommit = replaceLiteral(source, [[local function commit()
    state.applied = {}
    Config.save()
end]], [[local function commit()
    state.applied = {}
    state.rgnMaterialRetries = 4
    state.rgnMaterialNext = 0
    Config.save()
end]])
    okMaterialRetry = okMaterialRetry and okRetryCommit

    -- Never detach or free the attribute vector owned by CS2. Team changes can
    -- recreate the glove component while the old vector is still referenced;
    -- freeing it from Lua caused repeated heap work, disappearing gloves and
    -- severe FPS loss. Update existing attributes and allocate only if absent.
    source, okSafeGloveAttributes = replaceLiteral(source, [[local function glove_attr_remove(item)
    local addr = item + off.m_AttributeList + off.m_Attributes
    local size = r_ptr(addr)
    local ptr  = r_ptr(addr + 8)
    w_u64(addr, 0); w_u64(addr + 8, 0)
    if game_free and size ~= 0 and valid(ptr) then
        pcall(function() game_free(ffi.cast("void*", ptr)) end)
    end
end

local function glove_attr_set(item, paint, seed, wear)
    glove_attr_remove(item)
    if paint <= 0 then return end
    if not resolve_mem() then return end
    wear = safe_wear(wear)
    local raw  = game_alloc(ATTR_STRUCT * 3)
    local bptr = tonumber(ffi.cast("uintptr_t", raw))
    if not bptr or bptr == 0 then return end
    for i = 0, (ATTR_STRUCT * 3) / 8 - 1 do w_u64(bptr + i * 8, 0) end
    local function mk(i, def, val)
        local b = bptr + i * ATTR_STRUCT
        w_u16(b + 0x30, def); w_f32(b + 0x34, val); w_f32(b + 0x38, val)
    end
    mk(0, 6, paint)
    mk(1, 7, seed)
    mk(2, 8, wear)
    local addr = item + off.m_AttributeList + off.m_Attributes
    w_u64(addr, 3)
    w_u64(addr + 8, bptr)
end]], [[local function glove_attr_sync(item, paint, seed, wear, clearOnly)
    local addr = item + off.m_AttributeList + off.m_Attributes
    local count = r_u32(addr)
    local ptr = r_ptr(addr + 8)
    if count > 32 or (count > 0 and not valid(ptr)) then return false end

    paint = clearOnly and 0 or math.max(0, tonumber(paint) or 0)
    seed  = clearOnly and 0 or math.max(0, tonumber(seed) or 0)
    wear  = clearOnly and 0 or safe_wear(wear)
    local defs, vals = { 6, 7, 8 }, { paint, seed, wear }
    local found = { false, false, false }

    for i = 0, count - 1 do
        local attr = ptr + i * ATTR_STRUCT
        local definition = r_u16(attr + 0x30)
        for wanted = 1, 3 do
            if definition == defs[wanted] then
                w_f32(attr + 0x34, vals[wanted]); w_f32(attr + 0x38, vals[wanted])
                found[wanted] = true
            end
        end
    end
    if clearOnly then return true end

    local missing = 0
    for wanted = 1, 3 do if not found[wanted] then missing = missing + 1 end end
    if missing == 0 then return true end
    if not resolve_mem() or count + missing > 32 then return false end

    local newCount = count + missing
    local raw = game_alloc(ATTR_STRUCT * newCount)
    local newPtr = tonumber(ffi.cast("uintptr_t", raw))
    if not valid(newPtr) then return false end
    for q = 0, newCount * 9 - 1 do w_u64(newPtr + q * 8, 0) end
    if count > 0 then
        for q = 0, count * 9 - 1 do w_u64(newPtr + q * 8, r_u64(ptr + q * 8)) end
    end
    local at = count
    for wanted = 1, 3 do
        if not found[wanted] then
            local attr = newPtr + at * ATTR_STRUCT
            w_u16(attr + 0x30, defs[wanted])
            w_f32(attr + 0x34, vals[wanted]); w_f32(attr + 0x38, vals[wanted])
            at = at + 1
        end
    end
    -- Publish the new pointer first and its count last. The previous vector
    -- remains owned by CS2 and is never freed by this script.
    w_u64(addr + 8, newPtr)
    w_u64(addr, newCount)
    return true
end

local function glove_attr_remove(item)
    glove_attr_sync(item, 0, 0, 0, true)
end

local function glove_attr_set(item, paint, seed, wear)
    if paint <= 0 then glove_attr_remove(item); return end
    glove_attr_sync(item, paint, seed, wear, false)
end]])

    -- Spread glove reconstruction across the period in which CS2 replaces the
    -- deathmatch pawn. The key includes pawn and team, so the saved glove is
    -- reapplied even if the selected paint itself did not change.
    source, okGloveTransitionGuard = replaceLiteral(source, [[local glove_key, glove_apply = nil, 0
local function apply_gloves(base, pawn, gdef, paint, wear, seed)
    local g    = pawn + off.m_EconGloves
    local cur  = r_u16(g + off.m_iItemDefinitionIndex)
    local init = r_u8 (g + off.m_bInitialized)
    local key  = gdef.."|"..paint.."|"..floor(wear*100000).."|"..seed

    if key ~= glove_key then glove_key = key; glove_apply = 6 end
    local engine_reset = (cur ~= gdef) or (init == 0)
    if engine_reset and glove_apply <= 0 then glove_apply = 2 end

    if glove_apply > 0 then
        local acc = local_account_id(base)
        w_u8 (g + off.m_bInitialized, 0)
        w_u16(g + off.m_iItemDefinitionIndex, gdef)
        w_i32(g + off.m_iEntityQuality, 3)
        w_u32(g + off.m_iItemIDHigh, 0xFFFFFFFF)
        w_u32(g + off.m_iItemIDLow,  0xFFFFFFFF)
        w_u32(g + off.m_iAccountID, acc)
        w_u32(g + off.m_OriginalOwnerXuidLow, acc)
        glove_attr_set(g, paint, seed, wear)
        w_u8 (g + off.m_bDisallowSOC, 0)
        w_u8 (g + off.m_bRestoreCustomMat, 1)
        w_u8 (g + off.m_bInitialized, 1)
        w_u8 (pawn + off.m_bNeedToReApplyGloves, 1)
        if fnptr.set_body_group then
            pcall(function() fnptr.set_body_group(ffi.cast("void*", pawn), "first_or_third_person", 1) end)
        end
        glove_apply = glove_apply - 1
    end
end]], [[local glove_key, glove_apply, glove_next, glove_repair_after = nil, 0, 0, 0
local function apply_gloves(base, pawn, gdef, paint, wear, seed)
    local g    = pawn + off.m_EconGloves
    local cur  = r_u16(g + off.m_iItemDefinitionIndex)
    local init = r_u8 (g + off.m_bInitialized)
    local team = r_u8(pawn + off.m_iTeamNum)
    local key  = tostring(pawn).."|"..team.."|"..gdef.."|"..paint.."|"..floor(wear*100000).."|"..seed
    local now = 0
    pcall(function() now = globals.RealTime() end)

    if key ~= glove_key then
        glove_key, glove_apply = key, 5
        glove_next, glove_repair_after = now + 0.10, now + 1.50
    end
    local engine_reset = (cur ~= gdef) or (init == 0)
    if engine_reset and glove_apply <= 0 and now >= glove_repair_after then
        glove_apply, glove_next, glove_repair_after = 2, now + 0.10, now + 1.50
    end

    if glove_apply > 0 and now >= glove_next then
        local acc = local_account_id(base)
        w_u8 (g + off.m_bInitialized, 0)
        w_u16(g + off.m_iItemDefinitionIndex, gdef)
        w_i32(g + off.m_iEntityQuality, 3)
        w_u32(g + off.m_iItemIDHigh, 0xFFFFFFFF)
        w_u32(g + off.m_iItemIDLow,  0xFFFFFFFF)
        w_u32(g + off.m_iAccountID, acc)
        w_u32(g + off.m_OriginalOwnerXuidLow, acc)
        glove_attr_set(g, paint, seed, wear)
        w_u8 (g + off.m_bDisallowSOC, 0)
        w_u8 (g + off.m_bRestoreCustomMat, 1)
        w_u8 (g + off.m_bInitialized, 1)
        w_u8 (pawn + off.m_bNeedToReApplyGloves, 1)
        if fnptr.set_body_group then
            pcall(function() fnptr.set_body_group(ffi.cast("void*", pawn), "first_or_third_person", 1) end)
        end
        glove_apply = glove_apply - 1
        glove_next = now + 0.30
    end
end]])
    source = source:gsub("glove_key, glove_apply = nil, 0", "glove_key, glove_apply, glove_next, glove_repair_after = nil, 0, 0, 0")

    source, okDeathTransitionGuard = replaceLiteral(source, [[    if not pawn_alive(pawn) then
        if next(state.applied) then state.applied = {} end
        return
    end]], [[    if not pawn_alive(pawn) then
        if next(state.applied) then state.applied = {} end
        state.rgnWasAlive = false
        state.rgnRespawnRetries = 0
        glove_apply = 0
        return
    end]])

    source, okPlayableTeamGuard = replaceLiteral(source, [[    local currentTeam = r_u8(pawn + off.m_iTeamNum)
    local freshLife = state.rgnWasAlive ~= true
    if freshLife or state.lastPawnHandle ~= myHandle or state.lastTeam ~= currentTeam then
        state.lastPawnHandle = myHandle
        state.lastTeam = currentTeam
        state.rgnWasAlive = true
        state.applied = {}
        glove_key, glove_apply = nil, 6
        local spawnNow = 0
        pcall(function() spawnNow = globals.RealTime() end)
        state.rgnRespawnRetries = 4
        state.rgnRespawnNext = spawnNow + 0.15
    end]], [[    local currentTeam = r_u8(pawn + off.m_iTeamNum)
    if currentTeam ~= 2 and currentTeam ~= 3 then
        state.rgnWasAlive = false
        state.lastTeam = currentTeam
        state.rgnRespawnRetries = 0
        glove_apply = 0
        return
    end
    local freshLife = state.rgnWasAlive ~= true
    if freshLife or state.lastPawnHandle ~= myHandle or state.lastTeam ~= currentTeam then
        state.lastPawnHandle = myHandle
        state.lastTeam = currentTeam
        state.rgnWasAlive = true
        state.applied = {}
        local spawnNow = 0
        pcall(function() spawnNow = globals.RealTime() end)
        glove_key, glove_apply, glove_next, glove_repair_after = nil, 5, spawnNow + 0.10, spawnNow + 1.50
        state.rgnRespawnRetries = 4
        state.rgnRespawnNext = spawnNow + 0.15
    end]])

    -- A full mesh notification must perform a real group transition. Writing
    -- the target mask first caused the engine setter to return without dirtying
    -- its render/material state.
    source, okDirtyMeshNotify = replaceLiteral(source, [[local function write_mesh_group(ent, mask)
    if not valid(ent) or not off.m_MeshGroupMask or not off.m_modelState then return end
    local node = r_ptr(ent + off.m_pGameSceneNode)
    if not valid(node) then return end
    pcall(function() w_u64(node + off.m_modelState + off.m_MeshGroupMask, mask) end)
end

local function apply_mesh_mask(ent, mask, notify)
    write_mesh_group(ent, mask)
    if notify and fnptr.set_mesh_mask and valid(ent) then
        local node = r_ptr(ent + off.m_pGameSceneNode)
        if valid(node) then
            pcall(function() fnptr.set_mesh_mask(ffi.cast("void*", node), mask) end)
        end
    end
end]], [[local function write_mesh_group(ent, mask)
    if not valid(ent) or not off.m_MeshGroupMask or not off.m_modelState then return end
    local node = r_ptr(ent + off.m_pGameSceneNode)
    if not valid(node) then return end
    pcall(function() w_u64(node + off.m_modelState + off.m_MeshGroupMask, mask) end)
end

local function apply_mesh_mask(ent, mask, notify)
    if not valid(ent) or not off.m_MeshGroupMask or not off.m_modelState then return end
    local node = r_ptr(ent + off.m_pGameSceneNode)
    if not valid(node) then return end
    if notify and fnptr.set_mesh_mask then
        local address = node + off.m_modelState + off.m_MeshGroupMask
        local current = r_u64(address)
        if current == mask then
            local alternate = (mask == 2) and 1 or 2
            pcall(function() fnptr.set_mesh_mask(ffi.cast("void*", node), alternate) end)
        end
        local ok = pcall(function() fnptr.set_mesh_mask(ffi.cast("void*", node), mask) end)
        if ok then return end
    end
    write_mesh_group(ent, mask)
end]])

    source, okHudViewmodelFields = replaceLiteral(source,
        '    m_hViewmodelAttachment = { "m_hViewmodelAttachment", "C_EconEntity" },\n    m_EconGloves           = { "m_EconGloves", "C_CSPlayerPawn" },',
        '    m_hViewmodelAttachment = { "m_hViewmodelAttachment", "C_EconEntity" },\n    m_hHudModelArms        = { "m_hHudModelArms", "C_CSPlayerPawn" },\n    m_pChild               = { "m_pChild", "CGameSceneNode" },\n    m_pNextSibling         = { "m_pNextSibling", "CGameSceneNode" },\n    m_pOwner               = { "m_pOwner", "CGameSceneNode" },\n    m_EconGloves           = { "m_EconGloves", "C_CSPlayerPawn" },')

    source, okHudViewmodelFallbacks = replaceLiteral(source, [[off.m_hViewmodelAttachment = off.m_hViewmodelAttachment or 5808]], [[off.m_hViewmodelAttachment = off.m_hViewmodelAttachment or 5808
off.m_hHudModelArms = off.m_hHudModelArms or 0x1B7C
off.m_pChild = off.m_pChild or 0x40
off.m_pNextSibling = off.m_pNextSibling or 0x48
off.m_pOwner = off.m_pOwner or 0x30]])

    source, okHudViewmodelTraversal = replaceLiteral(source, [[local function apply_viewmodel_mesh(wpn, mask, elist, notify)
    if not elist or not off.m_hViewmodelAttachment then return end
    local h = r_u32(wpn + off.m_hViewmodelAttachment)
    if h == 0 or h == 0xFFFFFFFF then return end
    local att = handle_to_entity(elist, h)
    if att then apply_mesh_mask(att, mask, notify) end
end

local function apply_weapon_meshes(wpn, paint, elist, notify)
    local mask = weapon_mesh_mask(paint)
    apply_mesh_mask(wpn, mask, notify)
    apply_viewmodel_mesh(wpn, mask, elist, notify)
    return mask
end]], [[local vm_query_ready = false
local function vm_readable(address, bytes)
    if not valid(address) then return false end
    if not vm_query_ready then
        pcall(function() ffi.cdef("size_t VirtualQuery(const void*, void*, size_t);") end)
        vm_query_ready = true
    end
    local info = ffi.new("uint8_t[48]")
    local ok, result = pcall(function()
        return tonumber(ffi.C.VirtualQuery(ffi.cast("void*", address), info, 48))
    end)
    if not ok or not result or result == 0 then return false end
    local base = tonumber(ffi.cast("uintptr_t*", info)[0])
    local region = tonumber(ffi.cast("size_t*", info + 24)[0])
    local state = tonumber(ffi.cast("uint32_t*", info + 32)[0])
    local protect = tonumber(ffi.cast("uint32_t*", info + 36)[0])
    bytes = bytes or 8
    return state == 0x1000 and bit.band(protect, 0x101) == 0
        and address >= base and address + bytes <= base + region
end

local function find_hud_viewmodel(wpn, pawn, elist)
    if not valid(pawn) or not valid(elist) then return nil end
    if not off.m_hHudModelArms or not off.m_pChild or not off.m_pNextSibling or not off.m_pOwner then return nil end
    if not vm_readable(pawn + off.m_hHudModelArms, 4) then return nil end
    local arms = handle_to_entity(elist, r_u32(pawn + off.m_hHudModelArms))
    if not valid(arms) or not vm_readable(arms + off.m_pGameSceneNode, 8) then return nil end
    local armsNode = r_ptr(arms + off.m_pGameSceneNode)
    if not vm_readable(armsNode + off.m_pChild, 8) then return nil end
    local node = r_ptr(armsNode + off.m_pChild)
    for _ = 1, 24 do
        if not vm_readable(node, 8) then break end
        if vm_readable(node + off.m_pOwner, 8) then
            local owner = r_ptr(node + off.m_pOwner)
            if owner == wpn then return owner end
            if valid(owner) and vm_readable(owner + off.m_hOwnerEntity, 4) then
                local owned = handle_to_entity(elist, r_u32(owner + off.m_hOwnerEntity))
                if owned == wpn then return owner end
            end
        end
        if not vm_readable(node + off.m_pNextSibling, 8) then break end
        node = r_ptr(node + off.m_pNextSibling)
        if not valid(node) then break end
    end
    return nil
end

local function apply_viewmodel_mesh(wpn, mask, elist, notify, pawn)
    local viewmodel = find_hud_viewmodel(wpn, pawn, elist)
    if viewmodel then apply_mesh_mask(viewmodel, mask, notify) end
    if not elist or not off.m_hViewmodelAttachment then return end
    local h = r_u32(wpn + off.m_hViewmodelAttachment)
    if h == 0 or h == 0xFFFFFFFF then return end
    local attachment = handle_to_entity(elist, h)
    if attachment and attachment ~= viewmodel then apply_mesh_mask(attachment, mask, notify) end
end

local function apply_weapon_meshes(wpn, paint, elist, notify, pawn)
    local mask = weapon_mesh_mask(paint)
    apply_mesh_mask(wpn, mask, notify)
    apply_viewmodel_mesh(wpn, mask, elist, notify, pawn)
    return mask
end]])

    -- Native order: write attributes, select the UV mesh, run both current econ
    -- updates, then let the existing global regeneration/post-pass finish.
    source, okNativeSkinFlow = replaceLiteral(source, [[                                        process_weapon(wpn, c.paint, c.wear, c.seed, c.stat, c.statval)
                                        apply_weapon_meshes(wpn, c.paint, elist, true)]], [[                                        process_weapon(wpn, c.paint, c.wear, c.seed, c.stat, c.statval)
                                        apply_weapon_meshes(wpn, c.paint, elist, true)
                                        finalize_weapon_skin(wpn)]])

    local vmCallA, vmCallB, vmCallC, vmCallD
    source, vmCallA = source:gsub("apply_viewmodel_mesh%(wpn, 2, elist, true%)", "apply_viewmodel_mesh(wpn, 2, elist, true, pawn)")
    source, vmCallB = source:gsub("apply_viewmodel_mesh%(wpn, 2, elist, false%)", "apply_viewmodel_mesh(wpn, 2, elist, false, pawn)")
    source, vmCallC = source:gsub("apply_weapon_meshes%(wpn, c%.paint, elist, true%)", "apply_weapon_meshes(wpn, c.paint, elist, true, pawn)")
    source, vmCallD = source:gsub("apply_viewmodel_mesh%(wpn, mask, elist, false%)", "apply_viewmodel_mesh(wpn, mask, elist, false, pawn)")
    okHudViewmodelCalls = vmCallA == 2 and vmCallB == 1 and vmCallC == 2 and vmCallD == 1

    -- Aimware may invoke CreateMove well over 100 times per second. Detect
    -- inventory/pawn changes at 20 Hz, which is still effectively immediate to
    -- the player, instead of traversing Source 2 entities on every command.
    source, okEngineThrottle = replaceLiteral(source, [[callbacks.Register("CreateMove", "rgnMultitool_WeaponsEngine", function()
    local okd, d = pcall(active_weapon_def); g_activeDef = okd and d or nil]], [[local rgnNextEngineTick = 0
callbacks.Register("CreateMove", "rgnMultitool_WeaponsEngine", function()
    local tickNow = now_s()
    if tickNow < rgnNextEngineTick then return end
    rgnNextEngineTick = tickNow + 0.05
    local okd, d = pcall(active_weapon_def); g_activeDef = okd and d or nil
    if state.rgnLastActiveDef ~= g_activeDef then
        state.rgnLastActiveDef = g_activeDef
        state.rgnStickyNext = 0
    end]])

    -- A full apply remains event-driven through state.applied. Steady-state
    -- fallback/mesh repair runs only once per second, and the costly HUD
    -- viewmodel walk is limited to the weapon currently held.
    source, okSparseStickyState = replaceLiteral(source, [[    local applied = state.applied
    local retryNow = 0]], [[    local applied = state.applied
    local stickyClock = now_s()
    local stickyPass = stickyClock >= (state.rgnStickyNext or 0)
    if stickyPass then state.rgnStickyNext = stickyClock + 1.0 end
    local retryNow = 0]])

    source, okSparseKnife = replaceLiteral(source, [[                            else
                                -- sticky paint + mesh write only (no set_mesh_mask spam)
                                write_fallback(wpn, kc.paint, kc.wear, kc.seed, kc.stat, kc.statval)
                                apply_mesh_mask(wpn, 2, false)
                                apply_viewmodel_mesh(wpn, 2, elist, false, pawn)
                            end]], [[                            elseif stickyPass then
                                write_fallback(wpn, kc.paint, kc.wear, kc.seed, kc.stat, kc.statval)
                                apply_mesh_mask(wpn, 2, false)
                                apply_viewmodel_mesh(wpn, 2, elist, false, pawn)
                            end]])

    source, okSparseWeapon = replaceLiteral(source, [[                                    else
                                        write_fallback(wpn, c.paint, c.wear, c.seed, c.stat, c.statval)
                                        sync_weapon_attributes(wpn, c.paint, c.wear)
                                        apply_mesh_mask(wpn, mask, false)
                                        apply_viewmodel_mesh(wpn, mask, elist, false, pawn)
                                    end]], [[                                    elseif stickyPass then
                                        write_fallback(wpn, c.paint, c.wear, c.seed, c.stat, c.statval)
                                        sync_weapon_attributes(wpn, c.paint, c.wear)
                                        apply_mesh_mask(wpn, mask, false)
                                        if g_activeDef == def then
                                            apply_viewmodel_mesh(wpn, mask, elist, false, pawn)
                                        end
                                    end]])
    -- LOCAL TEST: explicitly invalidate only runtime caches when the session
    -- changes. Saved weapon/agent/glove selections remain untouched.
    local okLocalSessionRun, okLocalSessionClock, okLocalSessionEvents
    source, okLocalSessionRun = replaceLiteral(source, [[local function run()

    local lp = get_live_local()
    if not lp or not in_game() then
        if next(state.applied) then state.applied = {} end
        state.rgnWasAlive = false
        return
    end]], [[local rgnSessionInGame = false
local function rgnResetSession(reason)
    local resetNow = now_s()
    state.applied = {}
    state.modelApplied = {}
    state.appliedLocalModel = nil
    state.rgnWasAlive = false
    state.lastPawnHandle = nil
    state.lastTeam = nil
    state.rgnLastActiveDef = nil
    state.rgnStickyNext = 0
    state.rgnRespawnRetries = 6
    state.rgnRespawnNext = resetNow + 0.15
    state.rgnMaterialRetries = 5
    state.rgnMaterialNext = resetNow + 0.20
    state.modelNextTry = {}
    state.modelNextGlobal = 0
    glove_key, glove_apply, glove_next, glove_repair_after = nil, 0, 0, 0
    g_activeDef = nil
    g_precached_paths = {}
    if reason ~= "round_start" then
        print("[rgnWEAPONS engine] session cache reset: " .. tostring(reason or "transition"))
    end
end

local function run()
    local sessionOnline = in_game()
    if not sessionOnline then
        if rgnSessionInGame then rgnResetSession("left game") end
        rgnSessionInGame = false
        if next(state.applied) then state.applied = {} end
        state.rgnWasAlive = false
        return
    end
    if not rgnSessionInGame then
        rgnSessionInGame = true
        rgnResetSession("entered game")
    end

    local lp = get_live_local()
    if not lp then
        if next(state.applied) then state.applied = {} end
        state.rgnWasAlive = false
        return
    end]])

    source, okLocalSessionClock = replaceLiteral(source, [[local rgnNextEngineTick = 0
callbacks.Register("CreateMove", "rgnMultitool_WeaponsEngine", function()
    local tickNow = now_s()
    if tickNow < rgnNextEngineTick then return end]], [[local rgnNextEngineTick = 0
local rgnLastEngineClock = 0
callbacks.Register("CreateMove", "rgnMultitool_WeaponsEngine", function()
    local tickNow = now_s()
    if tickNow + 0.25 < rgnLastEngineClock then
        rgnNextEngineTick = 0
        rgnSessionInGame = false
        rgnResetSession("clock rollback / map load")
    end
    rgnLastEngineClock = tickNow
    if tickNow < rgnNextEngineTick then return end]])

    source, okLocalSessionEvents = replaceLiteral(source, [[local rgnNextEngineTick = 0
local rgnLastEngineClock = 0]], [[pcall(function()
    if client and client.AllowListener then
        client.AllowListener("server_spawn")
        client.AllowListener("game_newmap")
        client.AllowListener("cs_game_disconnected")
        client.AllowListener("round_start")
    end
    callbacks.Register("FireGameEvent", "rgnMultitool_WeaponsSessionEvents", function(event)
        local name
        pcall(function() name = event:GetName() end)
        if name == "server_spawn" or name == "game_newmap" or name == "cs_game_disconnected" or name == "round_start" then
            if name ~= "round_start" then rgnSessionInGame = false end
            rgnResetSession(name)
        end
    end)
end)

local rgnNextEngineTick = 0
local rgnLastEngineClock = 0]])

    if not (okLocalSessionRun and okLocalSessionClock and okLocalSessionEvents) then
        return nil, "local session lifecycle patch refused"
    end
    source = source:gsub("%[changer%]", "[rgnWEAPONS engine]")
    if not (okConfig and okCallback and okRuntime and okNetworkedAttributesOffset
        and okAttributesInitializedOffset and okFullItemIDOffset
        and okEntity and okController and okNetwork and okExtraPaints
        and okRefreshIndex and okWeaponAttributes and okProcessAttributes and okStickyAttributes
        and okMaterialRetry
        and okWeaponPointerKey and okKnifePointerKey and okPostRegenMesh
        and okCompatibleCatalog and okLegacyApplyGuard
        and okNativeSkinFlow and okDirtyMeshNotify
        and okHudViewmodelFields and okHudViewmodelFallbacks and okHudViewmodelTraversal and okHudViewmodelCalls
        and okSafeGloveAttributes and okGloveTransitionGuard and okDeathTransitionGuard and okPlayableTeamGuard
        and okEngineThrottle and okSparseStickyState and okSparseKnife and okSparseWeapon
        and okNoModelTick and okNoModelResolve and okAgentApply
        and okNoModelDiagnostic
        and okWeaponEntityKey and knifeEntityKeys == 3
        and okControlledPawn and okOwner and okActivePawn and okRespawn and okDeathState and okProfiles
        and okCleanConfig and okSingleSelection) then
        local failed = {}
        local function need(name, value) if not value then failed[#failed + 1] = name end end
        need("config", okConfig); need("callback", okCallback); need("runtime", okRuntime)
        need("networked-attributes-offset", okNetworkedAttributesOffset)
        need("attributes-initialized-offset", okAttributesInitializedOffset)
        need("full-item-id-offset", okFullItemIDOffset)
        need("extra-paints", okExtraPaints)
        need("entity", okEntity); need("controller", okController); need("network", okNetwork)
        need("refresh-index", okRefreshIndex); need("weapon-attributes", okWeaponAttributes)
        need("process-attributes", okProcessAttributes); need("sticky-attributes", okStickyAttributes)
        need("material-retry", okMaterialRetry)
        need("weapon-pointer-key", okWeaponPointerKey)
        need("knife-pointer-key", okKnifePointerKey)
        need("post-regen-mesh", okPostRegenMesh)
        need("compatible-catalog", okCompatibleCatalog); need("legacy-apply-guard", okLegacyApplyGuard)
        need("native-skin-flow", okNativeSkinFlow); need("dirty-mesh-notify", okDirtyMeshNotify)
        need("hud-viewmodel-fields", okHudViewmodelFields); need("hud-viewmodel-fallbacks", okHudViewmodelFallbacks)
        need("hud-viewmodel-traversal", okHudViewmodelTraversal); need("hud-viewmodel-calls", okHudViewmodelCalls)
        need("safe-glove-attributes", okSafeGloveAttributes); need("glove-transition-guard", okGloveTransitionGuard)
        need("death-transition-guard", okDeathTransitionGuard); need("playable-team-guard", okPlayableTeamGuard)
        need("engine-throttle", okEngineThrottle); need("sparse-sticky-state", okSparseStickyState)
        need("sparse-knife", okSparseKnife); need("sparse-weapon", okSparseWeapon)
        need("model-tick", okNoModelTick); need("model-resolver", okNoModelResolve); need("agent-apply", okAgentApply)
        need("model-diagnostic", okNoModelDiagnostic)
        need("weapon-key", okWeaponEntityKey); need("knife-keys", knifeEntityKeys == 3)
        need("controlled-pawn", okControlledPawn)
        need("owner", okOwner); need("active-pawn", okActivePawn); need("respawn", okRespawn); need("death-state", okDeathState)
        need("profiles", okProfiles); need("clean-config", okCleanConfig); need("single-selection", okSingleSelection)
        return nil, "safety patch refused: " .. table.concat(failed, ", ")
    end
    return source
end

local C, engineWhere, engineError
if type(rawget(_G, "ffi")) ~= "table" or type(rawget(_G, "bit")) ~= "table" then
    engineError = "enable Allow insecure FFI and rerun"
elseif type(mem) ~= "table" then
    engineError = "Aimware mem API unavailable"
else
    runtimeOffsets = fetchRuntimeOffsets()
    local source, where = fetchEngine()
    if not source then
        engineError = where
    else
        local rawSource, prepared = source, nil
        prepared, engineError = prepareEngine(rawSource)
        if not prepared and where == "GitHub" then
            local cached = readFile(ENGINE_CACHE)
            if type(cached) == "string" and #cached >= ENGINE_MIN_SIZE then
                local cachedPrepared, cachedError = prepareEngine(cached)
                if cachedPrepared then prepared, engineError, where = cachedPrepared, nil, "cache" else engineError = cachedError end
            end
        elseif prepared and where == "GitHub" then
            writeFile(ENGINE_CACHE, rawSource)
        end
        if prepared then
            local chunk, compileError = loadstring(prepared, "=rgnweapons_engine.lua")
            if not chunk then
                engineError = "engine compile error: " .. tostring(compileError)
            else
                local ok, result = pcall(chunk)
                if ok and type(result) == "table" then
                    C, engineWhere = result, where
                else
                    engineError = "engine load error: " .. tostring(result)
                end
            end
        end
    end
end

local REQUIRED_OFFSETS = {
    "dwEntityList", "dwLocalPlayerController", "dwNetworkGameClient",
    "dwNetworkGameClient_signOnState", "m_pWeaponServices", "m_hMyWeapons",
    "m_hActiveWeapon", "m_hPlayerPawn", "m_hOwnerEntity", "m_pGameSceneNode",
    "m_iHealth", "m_lifeState", "m_AttributeManager", "m_Item",
    "m_iItemDefinitionIndex", "m_iItemID", "m_iItemIDHigh", "m_iItemIDLow",
    "m_bInitialized", "m_bAttributesInitialized",
    "m_bDisallowSOC", "m_bRestoreCustomMat", "m_nFallbackPaintKit",
    "m_nFallbackSeed", "m_flFallbackWear", "m_nFallbackStatTrak",
    "m_nSubclassID", "m_iTeamNum", "m_steamID", "m_iEntityQuality",
    "m_iItemIDLow", "m_iAccountID", "m_OriginalOwnerXuidLow", "m_modelState",
    "m_AttributeList", "m_NetworkedDynamicAttributes", "m_Attributes",
    "m_EconGloves", "m_bNeedToReApplyGloves",
}

if C then
    local missing = {}
    for _, key in ipairs(REQUIRED_OFFSETS) do
        if type(C.offsets[key]) ~= "number" then missing[#missing + 1] = key end
    end
    if #missing > 0 then
        pcall(callbacks.Unregister, "CreateMove", "rgnMultitool_WeaponsEngine")
        pcall(callbacks.Unregister, "FireGameEvent", "rgnMultitool_WeaponsSessionEvents")
        engineError = "current offsets unavailable: " .. table.concat(missing, ", ")
        C = nil
    end
end

local itemsByKind = { weapon = {}, knife = {}, glove = {} }
local namesByKind = { weapon = {}, knife = {}, glove = {} }
local defToSelection = {}
if C then
    pcall(C.loadConfig)
    for _, item in ipairs(C.items or {}) do
        local items, names = itemsByKind[item.kind], namesByKind[item.kind]
        if items and names then
            items[#items + 1] = item
            names[#names + 1] = item.name:gsub("^%[[^%]]+%]%s*", "")
            if item.kind ~= "glove" then
                defToSelection[item.def] = { category = item.kind == "knife" and 2 or 1, index = #items }
            end
        end
    end
end
if #namesByKind.weapon == 0 then namesByKind.weapon[1] = "[ weapon engine unavailable ]" end
if #namesByKind.knife == 0 then namesByKind.knife[1] = "[ no knives available ]" end
if #namesByKind.glove == 0 then namesByKind.glove[1] = "[ no gloves available ]" end

-- Official CS2 agent catalogue. These models ship with the game and do not
-- depend on the custom characters folder used by rgnSKINS.
local AGENTS = {
    { name = "1st Lieutenant Farlow | SWAT", team = "CT", def = 4712, path = "agents/models/ctm_swat/ctm_swat_variantf.vmdl" },
    { name = "3rd Commando Company | KSK", team = "CT", def = 5400, path = "agents/models/ctm_st6/ctm_st6_variantk.vmdl" },
    { name = "Aspirant | Gendarmerie Nationale", team = "CT", def = 4752, path = "agents/models/ctm_gendarmerie/ctm_gendarmerie_variantd.vmdl" },
    { name = "B Squadron Officer | SAS", team = "CT", def = 5601, path = "agents/models/ctm_sas/ctm_sas_variantf.vmdl" },
    { name = "Bio-Haz Specialist | SWAT", team = "CT", def = 4714, path = "agents/models/ctm_swat/ctm_swat_varianth.vmdl" },
    { name = "'Blueberries' Buckshot | NSWC SEAL", team = "CT", def = 4619, path = "agents/models/ctm_st6/ctm_st6_variantj.vmdl" },
    { name = "Buckshot | NSWC SEAL", team = "CT", def = 5402, path = "agents/models/ctm_st6/ctm_st6_variantg.vmdl" },
    { name = "Chef d'Escadron Rouchard | Gendarmerie Nationale", team = "CT", def = 4751, path = "agents/models/ctm_gendarmerie/ctm_gendarmerie_variantc.vmdl" },
    { name = "Chem-Haz Capitaine | Gendarmerie Nationale", team = "CT", def = 4750, path = "agents/models/ctm_gendarmerie/ctm_gendarmerie_variantb.vmdl" },
    { name = "Chem-Haz Specialist | SWAT", team = "CT", def = 4716, path = "agents/models/ctm_swat/ctm_swat_variantj.vmdl" },
    { name = "Cmdr. Davida 'Goggles' Fernandez | SEAL Frogman", team = "CT", def = 4757, path = "agents/models/ctm_diver/ctm_diver_varianta.vmdl" },
    { name = "Cmdr. Frank 'Wet Sox' Baroud | SEAL Frogman", team = "CT", def = 4771, path = "agents/models/ctm_diver/ctm_diver_variantb.vmdl" },
    { name = "Cmdr. Mae 'Dead Cold' Jamison | SWAT", team = "CT", def = 4711, path = "agents/models/ctm_swat/ctm_swat_variante.vmdl" },
    { name = "D Squadron Officer | NZSAS", team = "CT", def = 5602, path = "agents/models/ctm_sas/ctm_sas_variantg.vmdl" },
    { name = "John 'Van Healen' Kask | SWAT", team = "CT", def = 4713, path = "agents/models/ctm_swat/ctm_swat_variantg.vmdl" },
    { name = "Lieutenant Rex Krikey | SEAL Frogman", team = "CT", def = 4772, path = "agents/models/ctm_diver/ctm_diver_variantc.vmdl" },
    { name = "Lieutenant 'Tree Hugger' Farlow | SWAT", team = "CT", def = 4756, path = "agents/models/ctm_swat/ctm_swat_variantk.vmdl" },
    { name = "Lt. Commander Ricksaw | NSWC SEAL", team = "CT", def = 5404, path = "agents/models/ctm_st6/ctm_st6_varianti.vmdl" },
    { name = "Markus Delrow | FBI HRT", team = "CT", def = 5306, path = "agents/models/ctm_fbi/ctm_fbi_variantg.vmdl" },
    { name = "Michael Syfers | FBI Sniper", team = "CT", def = 5307, path = "agents/models/ctm_fbi/ctm_fbi_varianth.vmdl" },
    { name = "Officer Jacques Beltram | Gendarmerie Nationale", team = "CT", def = 4753, path = "agents/models/ctm_gendarmerie/ctm_gendarmerie_variante.vmdl" },
    { name = "Operator | FBI SWAT", team = "CT", def = 5305, path = "agents/models/ctm_fbi/ctm_fbi_variantf.vmdl" },
    { name = "Primeiro Tenente | Brazilian 1st Battalion", team = "CT", def = 5405, path = "agents/models/ctm_st6/ctm_st6_variantn.vmdl" },
    { name = "Seal Team 6 Soldier | NSWC SEAL", team = "CT", def = 5401, path = "agents/models/ctm_st6/ctm_st6_variante.vmdl" },
    { name = "Sergeant Bombson | SWAT", team = "CT", def = 4715, path = "agents/models/ctm_swat/ctm_swat_varianti.vmdl" },
    { name = "Sous-Lieutenant Medic | Gendarmerie Nationale", team = "CT", def = 4749, path = "agents/models/ctm_gendarmerie/ctm_gendarmerie_varianta.vmdl" },
    { name = "Special Agent Ava | FBI", team = "CT", def = 5308, path = "agents/models/ctm_fbi/ctm_fbi_variantb.vmdl" },
    { name = "'Two Times' McCoy | TACP Cavalry", team = "CT", def = 4680, path = "agents/models/ctm_st6/ctm_st6_variantl.vmdl" },
    { name = "'Two Times' McCoy | USAF TACP", team = "CT", def = 5403, path = "agents/models/ctm_st6/ctm_st6_variantm.vmdl" },
    { name = "Arno The Overgrown | Guerrilla Warfare", team = "T", def = 4775, path = "agents/models/tm_jungle_raider/tm_jungle_raider_variantc.vmdl" },
    { name = "Blackwolf | Sabre", team = "T", def = 5503, path = "agents/models/tm_balkan/tm_balkan_variantj.vmdl" },
    { name = "Bloody Darryl The Strapped | The Professionals", team = "T", def = 4613, path = "agents/models/tm_professional/tm_professional_varf5.vmdl" },
    { name = "Col. Mangos Dabisi | Guerrilla Warfare", team = "T", def = 4776, path = "agents/models/tm_jungle_raider/tm_jungle_raider_variantd.vmdl" },
    { name = "Crasswater The Forgotten | Guerrilla Warfare", team = "T", def = 4774, path = "agents/models/tm_jungle_raider/tm_jungle_raider_variantb.vmdl" },
    { name = "Dragomir | Sabre", team = "T", def = 5500, path = "agents/models/tm_balkan/tm_balkan_variantf.vmdl" },
    { name = "Dragomir | Sabre Footsoldier", team = "T", def = 5505, path = "agents/models/tm_balkan/tm_balkan_variantl.vmdl" },
    { name = "Elite Trapper Solman | Guerrilla Warfare", team = "T", def = 4773, path = "agents/models/tm_jungle_raider/tm_jungle_raider_varianta.vmdl" },
    { name = "Enforcer | Phoenix", team = "T", def = 5206, path = "agents/models/tm_phoenix/tm_phoenix_variantf.vmdl" },
    { name = "Getaway Sally | The Professionals", team = "T", def = 4730, path = "agents/models/tm_professional/tm_professional_varj.vmdl" },
    { name = "Ground Rebel | Elite Crew", team = "T", def = 5105, path = "agents/models/tm_leet/tm_leet_variantg.vmdl" },
    { name = "Jungle Rebel | Elite Crew", team = "T", def = 5109, path = "agents/models/tm_leet/tm_leet_variantj.vmdl" },
    { name = "Little Kev | The Professionals", team = "T", def = 4728, path = "agents/models/tm_professional/tm_professional_varh.vmdl" },
    { name = "Maximus | Sabre", team = "T", def = 5501, path = "agents/models/tm_balkan/tm_balkan_varianti.vmdl" },
    { name = "'Medium Rare' Crasswater | Guerrilla Warfare", team = "T", def = 4780, path = "agents/models/tm_jungle_raider/tm_jungle_raider_variantb2.vmdl" },
    { name = "Number K | The Professionals", team = "T", def = 4732, path = "agents/models/tm_professional/tm_professional_vari.vmdl" },
    { name = "Osiris | Elite Crew", team = "T", def = 5106, path = "agents/models/tm_leet/tm_leet_varianth.vmdl" },
    { name = "Prof. Shahmat | Elite Crew", team = "T", def = 5107, path = "agents/models/tm_leet/tm_leet_varianti.vmdl" },
    { name = "Rezan The Ready | Sabre", team = "T", def = 5502, path = "agents/models/tm_balkan/tm_balkan_variantg.vmdl" },
    { name = "Rezan the Redshirt | Sabre", team = "T", def = 4718, path = "agents/models/tm_balkan/tm_balkan_variantk.vmdl" },
    { name = "Safecracker Voltzmann | The Professionals", team = "T", def = 4727, path = "agents/models/tm_professional/tm_professional_varg.vmdl" },
    { name = "Sir Bloody Darryl Royale | The Professionals", team = "T", def = 4735, path = "agents/models/tm_professional/tm_professional_varf3.vmdl" },
    { name = "Sir Bloody Loudmouth Darryl | The Professionals", team = "T", def = 4736, path = "agents/models/tm_professional/tm_professional_varf4.vmdl" },
    { name = "Sir Bloody Miami Darryl | The Professionals", team = "T", def = 4726, path = "agents/models/tm_professional/tm_professional_varf.vmdl" },
    { name = "Sir Bloody Silent Darryl | The Professionals", team = "T", def = 4733, path = "agents/models/tm_professional/tm_professional_varf1.vmdl" },
    { name = "Sir Bloody Skullhead Darryl | The Professionals", team = "T", def = 4734, path = "agents/models/tm_professional/tm_professional_varf2.vmdl" },
    { name = "Slingshot | Phoenix", team = "T", def = 5207, path = "agents/models/tm_phoenix/tm_phoenix_variantg.vmdl" },
    { name = "Soldier | Phoenix", team = "T", def = 5205, path = "agents/models/tm_phoenix/tm_phoenix_varianth.vmdl" },
    { name = "Street Soldier | Phoenix", team = "T", def = 5208, path = "agents/models/tm_phoenix/tm_phoenix_varianti.vmdl" },
    { name = "'The Doctor' Romanov | Sabre", team = "T", def = 5504, path = "agents/models/tm_balkan/tm_balkan_varianth.vmdl" },
    { name = "The Elite Mr. Muhlik | Elite Crew", team = "T", def = 5108, path = "agents/models/tm_leet/tm_leet_variantf.vmdl" },
    { name = "Trapper | Guerrilla Warfare", team = "T", def = 4781, path = "agents/models/tm_jungle_raider/tm_jungle_raider_variantf2.vmdl" },
    { name = "Trapper Aggressor | Guerrilla Warfare", team = "T", def = 4778, path = "agents/models/tm_jungle_raider/tm_jungle_raider_variantf.vmdl" },
    { name = "Vypa Sista of the Revolution | Guerrilla Warfare", team = "T", def = 4777, path = "agents/models/tm_jungle_raider/tm_jungle_raider_variante.vmdl" },
}

local agentsByTeam, agentNamesByTeam = { CT = {}, T = {} }, { CT = {}, T = {} }
for _, agent in ipairs(AGENTS) do
    local list, names = agentsByTeam[agent.team], agentNamesByTeam[agent.team]
    list[#list + 1], names[#names + 1] = agent, agent.name
end

local function savedBool(key, default)
    if not C then return default end
    local value = C.getOpt(key)
    if value == nil then return default end
    return value and true or false
end

local tab = M:Tab("WEAPONS")
tab:Row()
local itemSection = tab:Section("Inventory item")
local category = itemSection:Combo("Category", { "Weapons", "Knives", "Gloves" }, 1)
local itemList = itemSection:Listbox("", namesByKind.weapon, "fill", 1)
local itemWidget = itemSection.ws[#itemSection.ws]

tab:Col()
local skinSection = tab:Section("Paint kits")
local skinList = skinSection:Listbox("", { "[ select a weapon ]" }, "fill", 1)
local skinWidget = skinSection.ws[#skinSection.ws]
skinWidget.paintIds = { 0 }

tab:Col()
local settingsSection = tab:Section("Settings")
local wear = settingsSection:Slider("Wear / Float", 0.0001, 0.0001, 1.0, 0.001, "%.3f")
local seed = settingsSection:Slider("Seed", 0, 0, 1000, 1)
local autoFollow = settingsSection:Checkbox("Follow active weapon / knife", savedBool("autoFollow", false))

local actionSection = tab:Section("Actions")
local KIND_BY_CATEGORY = { "weapon", "knife", "glove" }
local function selectedItem()
    local kind = KIND_BY_CATEGORY[category:Get() or 1] or "weapon"
    return itemsByKind[kind][itemList:Get() or 1]
end
local function selectedPaint()
    -- Read the value from the same widget that draws and updates the rows.
    -- Keeping the row->paint mapping on that widget prevents a replaced list
    -- table (when changing weapons) from leaving the button on paint row 1.
    local index = math.floor(tonumber(skinWidget.value) or tonumber(skinList:Get()) or 1)
    local ids = skinWidget.paintIds or { 0 }
    if index < 1 or index > #ids then index = 1 end
    return tonumber(ids[index]) or 0, index
end

actionSection:Button("Apply selected skin", function()
    if not C then M:Notify(engineError or "weapon engine unavailable", "error"); return end
    local item = selectedItem()
    if not item then M:Notify("select a weapon first", "error"); return end
    local paint, index = selectedPaint()
    local expected = skinWidget.items and skinWidget.items[index]
    if paint == 0 and expected ~= "[ None ]" then
        M:Notify("invalid paint selection; select the row again", "error")
        return
    end
    local result = C.apply(item, paint, wear:Get(), math.floor((seed:Get() or 0) + 0.5))
    M:Notify(result or "skin saved and queued", "success")
end)
actionSection:Button("Restore selected item", function()
    if not C then M:Notify(engineError or "weapon engine unavailable", "error"); return end
    M:Notify(C.remove(selectedItem()) or "skin removed", "info")
end)
actionSection:Button("Reset weapons / knives / gloves", function()
    if not C then M:Notify(engineError or "weapon engine unavailable", "error"); return end
    M:Notify(C.resetAll() or "all weapon skins reset", "info")
end)
local visualStatus = "waiting for an equipped weapon"
local statusSection = tab:Section("Status")
statusSection:Button("Show engine status", function()
    if C then
        local live = 0
        for _, key in ipairs({ "dwEntityList", "dwLocalPlayerController", "dwNetworkGameClient" }) do
            if type(runtimeOffsets[key]) == "number" then live = live + 1 end
        end
        M:Notify("engine ready | offsets " .. tostring(live) .. "/3 | " .. visualStatus, "success")
    else
        M:Notify(engineError or "weapon engine unavailable", "error")
    end
end)
statusSection:Button("Show selected configuration", function()
    if not C then M:Notify(engineError or "engine unavailable", "error"); return end
    local item = selectedItem()
    local cfg = item and C.getCfg(item.def)
    if not item then M:Notify("select an item first", "error")
    elseif cfg then M:Notify(item.name .. " | paint " .. tostring(cfg.paint) .. " | saved", "success")
    else M:Notify(item.name .. " | default / not configured", "info") end
end)

local configTab = M:Tab("CONFIGS")
configTab:Row()
local autoConfigSection = configTab:Section("Automatic setup")
autoConfigSection:Button("Reapply saved setup now", function()
    if not C then M:Notify(engineError or "weapon engine unavailable", "error"); return end
    local data = C.exportConfig()
    if type(data) == "string" and C.importConfig(data) then
        M:Notify("saved weapons, knife and gloves queued again", "success")
    else
        M:Notify("automatic setup could not be reapplied", "error")
    end
end)
autoConfigSection:Button("Reload automatic setup from disk", function()
    if not C then M:Notify(engineError or "weapon engine unavailable", "error"); return end
    if C.loadConfig() then
        M:Notify("automatic setup loaded and queued", "success")
    else
        M:Notify("no automatic setup has been saved yet", "info")
    end
end)
autoConfigSection:Button("Show automatic save status", function()
    if not C then M:Notify(engineError or "weapon engine unavailable", "error"); return end
    local configured = 0
    for _, configuredItem in ipairs(C.items or {}) do
        if C.getCfg(configuredItem.def) then configured = configured + 1 end
    end
    M:Notify(tostring(configured) .. " configured items | saved after every change", "success")
end)autoConfigSection:Button("Check for updates", function()
    local updater = rawget(_G, "RGN_MULTITOOL_UPDATER")
    if type(updater) ~= "table" or type(updater.check) ~= "function" then
        M:Notify("updates are available when rgnMultitool is launched with loader.lua", "info")
        return
    end
    local callOk, success, message, state = pcall(updater.check)
    if not callOk then
        M:Notify("update check failed: " .. tostring(success), "error")
    elseif not success then
        M:Notify(tostring(message or "update check failed"), "error")
    elseif state == "downloaded" then
        M:Notify(tostring(message), "success")
    else
        M:Notify(tostring(message), "info")
    end
end)

configTab:Col()
local profileSection = configTab:Section("Saved profiles")
local PROFILE_NAMES_FILE = "rgnweapons_profile_names.txt"
local profileNames = { "Profile 1", "Profile 2", "Profile 3", "Profile 4", "Profile 5" }
local namesRaw = readFile(PROFILE_NAMES_FILE)
if type(namesRaw) == "string" then
    for line in namesRaw:gmatch("[^\r\n]+") do
        local index, name = line:match("^(%d)%s+(.+)$")
        index = tonumber(index)
        if index and index >= 1 and index <= 5 and name ~= "" then profileNames[index] = name end
    end
end
local function saveProfileNames()
    local lines = {}
    for index = 1, 5 do lines[index] = tostring(index) .. " " .. profileNames[index] end
    return writeFile(PROFILE_NAMES_FILE, table.concat(lines, "\n"))
end
local function profilePath(slot) return "rgnweapons_profile_" .. tostring(slot) .. ".txt" end

local profileSlot = profileSection:Combo("Profile slot", { "Slot 1", "Slot 2", "Slot 3", "Slot 4", "Slot 5" }, 1)
local profileName = profileSection:Input("Profile name", profileNames[1], "example: main setup")
local lastProfileSlot = 1
profileSection:Button("Save current setup to profile", function()
    if not C then M:Notify(engineError or "weapon engine unavailable", "error"); return end
    local slot = profileSlot:Get() or 1
    local name = tostring(profileName:Get() or ""):gsub("[\r\n]", " "):sub(1, 32)
    if name:match("^%s*$") then name = "Profile " .. tostring(slot) end
    local data = C.exportConfig()
    if type(data) == "string" and writeFile(profilePath(slot), data) then
        profileNames[slot] = name
        saveProfileNames()
        M:Notify(name .. " saved", "success")
    else
        M:Notify("profile could not be written", "error")
    end
end)
profileSection:Button("Load selected profile", function()
    if not C then M:Notify(engineError or "weapon engine unavailable", "error"); return end
    local slot = profileSlot:Get() or 1
    local data = readFile(profilePath(slot))
    if type(data) == "string" and C.importConfig(data) then
        M:Notify(profileNames[slot] .. " loaded and queued", "success")
    else
        M:Notify("that profile slot is empty or invalid", "info")
    end
end)
profileSection:Button("Delete selected profile", function()
    local slot = profileSlot:Get() or 1
    pcall(function() file.Delete(profilePath(slot)) end)
    profileNames[slot] = "Profile " .. tostring(slot)
    profileName:Set(profileNames[slot])
    saveProfileNames()
    M:Notify("profile slot " .. tostring(slot) .. " deleted", "info")
end)

local function syncProfileSlot()
    local slot = profileSlot:Get() or 1
    if slot ~= lastProfileSlot then
        lastProfileSlot = slot
        profileName:Set(profileNames[slot])
    end
end

local agentsTab = M:Tab("AGENTS")
agentsTab:Row()
local agentListSection = agentsTab:Section("Official CS2 agents")
local agentTeam = agentListSection:Combo("Team", { "Counter-Terrorists", "Terrorists" }, 1)
local agentList = agentListSection:Listbox("", agentNamesByTeam.CT, "fill", 1)
local agentWidget = agentListSection.ws[#agentListSection.ws]

agentsTab:Col()
local agentControlSection = agentsTab:Section("Local operator")
local agentEnabled = agentControlSection:Checkbox("Enable agent changer", savedBool("rgn_agent_enabled", false))
RGN_MULTI.setAgentEnabled = function(enabled)
    enabled = enabled and true or false
    agentEnabled:Set(enabled)
    if C then C.setOpt("rgn_agent_enabled", enabled) end
end
if agentEnabled:Get() then RGN_MULTI.activateAgents("saved agent configuration") end

local function agentTeamKey()
    return (agentTeam:Get() or 1) == 1 and "CT" or "T"
end

local function selectedAgent()
    local list = agentsByTeam[agentTeamKey()] or {}
    return list[agentList:Get() or 1]
end

agentControlSection:Button("Apply selected agent", function()
    if not C then M:Notify(engineError or "weapon engine unavailable", "error"); return end
    local agent = selectedAgent()
    if not agent then M:Notify("select an agent first", "error"); return end
    C.setOpt(agent.team == "CT" and "rgn_agent_ct" or "rgn_agent_t", agent.path)
    C.setOpt("rgn_agent_enabled", true)
    agentEnabled:Set(true)
    RGN_MULTI.activateAgents("official agent selected")
    M:Notify(agent.team .. " agent saved: " .. agent.name, "success")
end)

agentControlSection:Button("Turn agent changer OFF", function()
    if C then C.setOpt("rgn_agent_enabled", false) end
    agentEnabled:Set(false)
    RGN_MULTI.deactivateAgents("official agents disabled")
    M:Notify("agents off; enable Skins Custom if you want a custom character", "info")
end)

local agentInfoSection = agentsTab:Section("Status")
agentInfoSection:Button("Show saved agents", function()
    if not C then M:Notify(engineError or "weapon engine unavailable", "error"); return end
    local ct, tt = tostring(C.getOpt("rgn_agent_ct") or "not selected"), tostring(C.getOpt("rgn_agent_t") or "not selected")
    print("[rgnWEAPONS] CT agent: " .. ct)
    print("[rgnWEAPONS] T agent: " .. tt)
    M:Notify("saved CT/T agent paths printed in console", "info")
end)

local lastAgentTeam, lastAgentEnabled = -1, agentEnabled:Get()
local function syncAgentList()
    local selectedTeam = agentTeam:Get() or 1
    if selectedTeam == lastAgentTeam then return end
    lastAgentTeam = selectedTeam
    local key = selectedTeam == 1 and "CT" or "T"
    local list, names = agentsByTeam[key], agentNamesByTeam[key]
    local wanted = C and C.getOpt(key == "CT" and "rgn_agent_ct" or "rgn_agent_t") or nil
    local index = 1
    for i, agent in ipairs(list) do if agent.path == wanted then index = i; break end end
    agentWidget.items, agentWidget.value, agentWidget.scroll = names, index, 0
end

local lastCategory, lastItem, lastActive = -1, -1, nil
local lastAuto = autoFollow:Get()
-- Watermark-only cache removed.
local lastActiveCheck = -100
local pendingItem

local function syncItemList()
    if not C then return end
    local categoryIndex = category:Get() or 1
    if categoryIndex ~= lastCategory then
        lastCategory, lastItem = categoryIndex, -1
        local kind = KIND_BY_CATEGORY[categoryIndex] or "weapon"
        itemWidget.items, itemWidget.value, itemWidget.scroll = namesByKind[kind], pendingItem or 1, 0
        pendingItem = nil
        skinWidget.items, skinWidget.value, skinWidget.scroll = { "[ select an item ]" }, 1, 0
        skinWidget.paintIds = { 0 }
    end
    local selected = itemList:Get() or 1
    if selected == lastItem then return end
    lastItem = selected
    local item = selectedItem()
    if not item then return end
    local names, paintIds = C.skinList(item.def)
    skinWidget.items, skinWidget.value, skinWidget.scroll = names, 1, 0
    skinWidget.paintIds = paintIds
    local cfg = C.getCfg(item.def)
    if cfg then
        wear:Set(tonumber(cfg.wear) or 0.0001)
        seed:Set(tonumber(cfg.seed) or 0)
        for index, paint in ipairs(skinWidget.paintIds) do
            if paint == cfg.paint then skinWidget.value = index; break end
        end
    end
end

local function syncActiveWeapon(now)
    if not C or not autoFollow:Get() then lastActive = nil; return end
    if now - lastActiveCheck < 0.25 then return end
    lastActiveCheck = now
    local ok, def = pcall(C.activeDef)
    if not ok or not def or def == lastActive then return end
    lastActive = def
    local target = defToSelection[def]
    if target then
        pendingItem = target.index
        category:Set(target.category)
        if target.category == lastCategory then itemList:Set(target.index); pendingItem = nil end
    end
end

-- The changer performs its verified econ notification, mesh update and global
-- material rebuild in the same engine cycle. No second Draw-time memory path.
local function refreshActiveMaterial(now)
    visualStatus = C and "native paint + viewmodel refresh active" or "weapon engine unavailable"
end

M:OnFrame(function()
    local now = 0
    pcall(function() now = globals.RealTime() end)
    syncProfileSlot()
    syncAgentList()
    syncItemList()
    syncActiveWeapon(now)
    refreshActiveMaterial(now)

    local auto = autoFollow:Get()
    if C and auto ~= lastAuto then lastAuto = auto; C.setOpt("autoFollow", auto) end
    local agentOn = agentEnabled:Get()
    if C and agentOn ~= lastAgentEnabled then
        lastAgentEnabled = agentOn
        C.setOpt("rgn_agent_enabled", agentOn)
        if agentOn then
            RGN_MULTI.activateAgents("agent checkbox enabled")
        else
            RGN_MULTI.deactivateAgents("agent checkbox disabled")
        end
    elseif C then
        local configured = C.getOpt("rgn_agent_enabled")
        local configuredOn = configured == true or configured == 1 or configured == "1"
        if configuredOn ~= agentOn then
            agentEnabled:Set(configuredOn)
            lastAgentEnabled = configuredOn
            if configuredOn then
                RGN_MULTI.activateAgents("agent profile loaded")
            else
                RGN_MULTI.deactivateAgents("agent profile loaded with agents off")
            end
        end
    end

end)

pcall(function()
    callbacks.Register("Unload", "rgnMultitool_WeaponsUnload", function()
        pcall(callbacks.Unregister, "CreateMove", "rgnMultitool_WeaponsEngine")
        pcall(callbacks.Unregister, "FireGameEvent", "rgnMultitool_WeaponsSessionEvents")

    end)
end)


if not C then print("[rgn] WEAPONS: " .. tostring(engineError)) end
end)

loadModule("MOVEMENT", function()
local M = M

-- rgnMultitool movement module. Movement is attached to the multitool's
-- already-live Draw/CreateMove callbacks so Aimware cannot discard it as a
-- second callback for the same event.
local bitlib = rawget(_G, "bit")
-- v2 starts with every feature disabled; choices are persisted after opt-in.
local CONFIG_FILE = "rgnmovement_config_v2.txt"
local IN_DUCK = 4
local FL_ONGROUND = 1
local KEY_W, KEY_A, KEY_S, KEY_D = 0x57, 0x41, 0x53, 0x44

local function clamp(v, lo, hi)
    if v < lo then return lo elseif v > hi then return hi end
    return v
end

local function now()
    local value
    pcall(function() value = globals.RealTime() end)
    if type(value) ~= "number" then pcall(function() value = globals.CurTime() end) end
    return type(value) == "number" and value or 0
end

local function tickInterval()
    local value
    pcall(function() value = globals.TickInterval() end)
    if type(value) ~= "number" or value <= 0 or value > 0.1 then return 1 / 64 end
    return value
end

local function hasBit(value, mask)
    value = tonumber(value) or 0
    if bitlib and bitlib.band then return bitlib.band(value, mask) ~= 0 end
    return value % (mask * 2) >= mask
end

local function addBit(value, mask)
    value = tonumber(value) or 0
    if bitlib and bitlib.bor then return bitlib.bor(value, mask) end
    return hasBit(value, mask) and value or (value + mask)
end

local errors = {}
local function safe(label, fn, ...)
    local ok, a, b, c = pcall(fn, ...)
    if not ok then
        local key = label .. ":" .. tostring(a)
        if not errors[key] then
            errors[key] = true
            print("[rgnMovement] " .. label .. " error: " .. tostring(a))
        end
        return nil
    end
    return a, b, c
end

local config = {}
pcall(function()
    local f = file.Open(CONFIG_FILE, "r")
    if not f then return end
    local raw = f:Read() or ""
    f:Close()
    for line in raw:gmatch("[^\r\n]+") do
        local key, value = line:match("^([%w_]+)=(.*)$")
        if key then config[key] = value end
    end
end)

local function cfgBool(key, default)
    local value = config[key]
    if value == nil then return default end
    return value == "1" or value == "true"
end

local function cfgNumber(key, default, lo, hi)
    local value = tonumber(config[key]) or default
    return clamp(value, lo, hi)
end

local function cfgColor(key, default)
    local value = config[key]
    if not value then return default end
    local r, g, b, a = value:match("^(%d+),(%d+),(%d+),(%d+)$")
    if not r then return default end
    return {
        clamp(tonumber(r), 0, 255), clamp(tonumber(g), 0, 255),
        clamp(tonumber(b), 0, 255), clamp(tonumber(a), 0, 255)
    }
end

local tab = M:Tab("MOVEMENT")
tab:Row()
local velocitySection = tab:Section("Velocity display")
local velocityEnabled = velocitySection:Checkbox("Enable velocity number", cfgBool("velocity", false))
local velocityColor = velocitySection:ColorPicker("Number color", cfgColor("velocity_color", { 245, 248, 255, 255 }))
local jumpColor = velocitySection:ColorPicker("Jump-speed color", cfgColor("jump_color", { 74, 166, 255, 255 }))
local velocityY = velocitySection:Slider("Vertical position", cfgNumber("velocity_y", 83, 55, 94), 55, 94, 1, "%d%%")

local trailSection = tab:Section("Jump trail")
local trailEnabled = trailSection:Checkbox("Enable jump trail", cfgBool("trail", false))
local trailDuration = trailSection:Slider("Duration", cfgNumber("trail_duration", 4, 1, 10), 1, 10, 0.5, "%.1fs")
local trailThickness = trailSection:Slider("Thickness", cfgNumber("trail_thickness", 3, 1, 8), 1, 8, 1)
local trailRainbow = trailSection:Checkbox("RGB rainbow", cfgBool("trail_rainbow", false))
local trailColor = trailSection:ColorPicker("Trail color", cfgColor("trail_color", { 74, 166, 255, 230 }))

tab:Col()
local edgeSection = tab:Section("Prediction edge bug")
local edgeEnabled = edgeSection:Checkbox("Enable smart edge bug", cfgBool("edge", false))
local edgeKey = edgeSection:Keybox("Activation key", cfgNumber("edge_key", 0, 0, 255))
local edgeMode = edgeSection:Combo("Activation mode", { "Hold", "Toggle" }, cfgNumber("edge_mode", 1, 1, 2))

local nullSection = tab:Section("Null binds")
local nullEnabled = nullSection:Checkbox("Enable W/A/S/D resolver", cfgBool("null_binds", false))

local statusSection = tab:Section("Status")
local debugEnabled = statusSection:Checkbox("Live debug overlay", cfgBool("debug", false))

local vectorMode
local function vecComponent(v, axis)
    if v == nil then return nil end
    local methods = {
        function() return v[axis] end,
        function() return v[axis == "x" and 1 or (axis == "y" and 2 or 3)] end,
        function() return v[axis == "x" and 0 or (axis == "y" and 1 or 2)] end,
        function() return v["Get" .. axis:upper()](v) end,
    }
    if vectorMode then
        local ok, value = pcall(methods[vectorMode])
        value = ok and tonumber(value) or nil
        if value ~= nil then return value end
        vectorMode = nil
    end
    for i = 1, #methods do
        local ok, value = pcall(methods[i])
        value = ok and tonumber(value) or nil
        if value ~= nil then vectorMode = i; return value end
    end
    local text = tostring(v)
    local x, y, z = text:match("([%-%d%.eE+]+)[ ,]+([%-%d%.eE+]+)[ ,]+([%-%d%.eE+]+)")
    return tonumber(axis == "x" and x or (axis == "y" and y or z))
end

local function vectorXYZ(v)
    local x, y, z = vecComponent(v, "x"), vecComponent(v, "y"), vecComponent(v, "z")
    if x == nil or y == nil or z == nil then return nil end
    return x, y, z
end

local velocityReader, flagsReader, moveTypeReader
local velocitySource, flagsSource, moveTypeSource = "origin delta", "fallback", "fallback"

local function readVelocity(lp)
    if velocityReader == false then return nil end
    local readers = {
        { "m_vecAbsVelocity/GetFieldVector", function(e) return e:GetFieldVector("m_vecAbsVelocity") end },
        { "m_vecVelocity/GetFieldVector", function(e) return e:GetFieldVector("m_vecVelocity") end },
        { "m_vecAbsVelocity/GetField", function(e) return e:GetField("m_vecAbsVelocity") end },
        { "m_vecVelocity/GetField", function(e) return e:GetField("m_vecVelocity") end },
    }
    if type(velocityReader) == "number" then
        local ok, value = pcall(readers[velocityReader][2], lp)
        if ok and value ~= nil then
            local x, y, z = vectorXYZ(value)
            if x then return x, y, z end
        end
        velocityReader = nil
    end
    for i = 1, #readers do
        local ok, value = pcall(readers[i][2], lp)
        if ok and value ~= nil then
            local x, y, z = vectorXYZ(value)
            if x then
                velocityReader, velocitySource = i, readers[i][1]
                return x, y, z
            end
        end
    end
    velocityReader = false
    velocitySource = "origin delta"
    return nil
end

local function readInteger(lp, property, cacheName)
    local cache
    if cacheName == "flags" then cache = flagsReader else cache = moveTypeReader end
    if cache == false then return nil end
    local readers = {
        { property .. "/GetFieldInt", function(e) return e:GetFieldInt(property) end },
        { property .. "/GetField", function(e) return e:GetField(property) end },
        { property .. "/GetPropInt", function(e) return e:GetPropInt(property) end },
    }
    local function accept(i, value)
        value = tonumber(value)
        if value == nil then return nil end
        if cacheName == "flags" then flagsReader, flagsSource = i, readers[i][1]
        else moveTypeReader, moveTypeSource = i, readers[i][1] end
        return value
    end
    if type(cache) == "number" then
        local ok, value = pcall(readers[cache][2], lp)
        if ok then
            value = accept(cache, value)
            if value ~= nil then return value end
        end
        if cacheName == "flags" then flagsReader = nil else moveTypeReader = nil end
    end
    for i = 1, #readers do
        local ok, value = pcall(readers[i][2], lp)
        if ok then
            value = accept(i, value)
            if value ~= nil then return value end
        end
    end
    if cacheName == "flags" then flagsReader, flagsSource = false, "fallback"
    else moveTypeReader, moveTypeSource = false, "fallback" end
    return nil
end

local function readMoveType(lp)
    if moveTypeReader == false then return nil end
    local readers = {
        { "m_MoveType/GetFieldInt", function(e) return e:GetFieldInt("m_MoveType") end },
        { "m_nActualMoveType/GetFieldInt", function(e) return e:GetFieldInt("m_nActualMoveType") end },
        { "m_nMoveType/GetFieldInt", function(e) return e:GetFieldInt("m_nMoveType") end },
        { "m_MoveType/GetField", function(e) return e:GetField("m_MoveType") end },
        { "m_MoveType/GetPropInt", function(e) return e:GetPropInt("m_MoveType") end },
    }
    if type(moveTypeReader) == "number" then
        local ok, value = pcall(readers[moveTypeReader][2], lp)
        value = ok and tonumber(value) or nil
        if value ~= nil then return value end
        moveTypeReader = nil
    end
    for i = 1, #readers do
        local ok, value = pcall(readers[i][2], lp)
        value = ok and tonumber(value) or nil
        if value ~= nil then
            moveTypeReader, moveTypeSource = i, readers[i][1]
            return value
        end
    end
    moveTypeReader, moveTypeSource = false, "fallback"
    return nil
end

local state = {
    valid = false, alive = false, speed = 0, displaySpeed = 0,
    x = 0, y = 0, z = 0, vx = 0, vy = 0, vz = 0,
    onGround = true, onLadder = false, groundDistance = nil,
    jumpSpeed = nil, jumpActive = false, jumpLandedAt = 0,
    edgeActive = false, edgeDuck = false,
}

local lastX, lastY, lastZ, lastSampleAt, lastPawnKey
local lastGround = true
local trail, trailHead, lastTrailAt = {}, 1, 0
local edgeBind = { last = false, toggled = false }
local nullState = { w = false, a = false, s = false, d = false, stamp = 0, pressed = {} }
local traceSource = "not probed"

local function clearTrail()
    trail, trailHead, lastTrailAt = {}, 1, 0
end

local function resetMovement(reason)
    state.valid, state.alive = false, false
    state.speed, state.displaySpeed = 0, 0
    state.groundDistance = nil
    state.edgeActive, state.edgeDuck = false, false
    state.jumpSpeed, state.jumpActive, state.jumpLandedAt = nil, false, 0
    lastX, lastY, lastZ, lastSampleAt, lastPawnKey = nil, nil, nil, nil, nil
    lastGround = true
    edgeBind.last, edgeBind.toggled = false, false
    velocityReader, flagsReader, moveTypeReader = nil, nil, nil
    velocitySource, flagsSource, moveTypeSource = "origin delta", "fallback", "fallback"
    traceSource = "not probed"
    clearTrail()
    if reason and reason ~= "player_spawn" then
        print("[rgnMovement] state reset: " .. tostring(reason))
    end
end

local function playerKey(lp)
    local index
    pcall(function() index = lp:GetIndex() end)
    return tostring(index or lp)
end

local function tracePoint(lp, x, y, z, maxDistance)
    if not engine or type(engine.TraceLine) ~= "function" or type(Vector3) ~= "function" then
        traceSource = "TraceLine unavailable"
        return nil
    end
    local distance
    local ok = pcall(function()
        local start = Vector3(x, y, z + 2)
        local finish = Vector3(x, y, z - maxDistance)
        local tr = engine.TraceLine(start, finish)
        if not tr or tr.startsolid or tr.allSolid then return end
        local fraction = tonumber(tr.fraction)
        if not fraction or fraction < 0 or fraction >= 1 then return end
        local hitLocal = false
        pcall(function() hitLocal = tr.entity ~= nil and tr.entity:GetIndex() == lp:GetIndex() end)
        if hitLocal then return end
        distance = math.max(0, (maxDistance + 2) * fraction - 2)
    end)
    if not ok then
        traceSource = "TraceLine error"
        return nil
    end
    traceSource = "5-point TraceLine"
    return distance
end

local function groundDistance(lp, x, y, z)
    local half, maxDistance = 15, 96
    local points = { { 0, 0 }, { -half, -half }, { -half, half }, { half, -half }, { half, half } }
    local best
    for i = 1, #points do
        local distance = tracePoint(lp, x + points[i][1], y + points[i][2], z, maxDistance)
        if distance and (not best or distance < best) then best = distance end
    end
    return best
end

local function edgeBindingActive()
    if not edgeEnabled:Get() then
        edgeBind.last, edgeBind.toggled = false, false
        return false
    end
    local key = tonumber(edgeKey:Get()) or 0
    if key <= 0 then return false end
    local down = false
    pcall(function() down = input.IsButtonDown(key) and true or false end)
    local rising = down and not edgeBind.last
    edgeBind.last = down
    if edgeMode:Get() == 2 then
        if rising then edgeBind.toggled = not edgeBind.toggled end
        return edgeBind.toggled
    end
    return down
end

local function updateState(edgeActive)
    local lp
    pcall(function() lp = entities.GetLocalPlayer() end)
    if not lp then
        if state.valid then resetMovement("no local player") end
        return false
    end
    local alive = false
    pcall(function() alive = lp:IsAlive() and true or false end)
    if not alive then
        if state.alive then resetMovement("death") end
        state.alive = false
        return false
    end

    local origin
    pcall(function() origin = lp:GetAbsOrigin() end)
    local x, y, z = vectorXYZ(origin)
    if not x then
        state.valid = false
        return false
    end

    local key = playerKey(lp)
    if lastPawnKey and key ~= lastPawnKey then resetMovement("pawn changed") end
    lastPawnKey = key

    local t = now()
    local previousZ = lastZ
    local vx, vy, vz = readVelocity(lp)
    if vx == nil then
        local dt = lastSampleAt and (t - lastSampleAt) or tickInterval()
        if lastX and dt > 0 and dt <= 0.1 then
            vx, vy, vz = (x - lastX) / dt, (y - lastY) / dt, (z - lastZ) / dt
        else
            vx, vy, vz = 0, 0, 0
        end
    end
    lastX, lastY, lastZ, lastSampleAt = x, y, z, t

    local flags = readInteger(lp, "m_fFlags", "flags")
    local moveType = readMoveType(lp)
    local onGround
    if flags ~= nil then
        onGround = hasBit(flags, FL_ONGROUND)
    else
        local closeGround
        if math.abs(vz) < 40 then closeGround = tracePoint(lp, x, y, z, 8) end
        onGround = closeGround ~= nil and closeGround <= 3
        if closeGround == nil and previousZ ~= nil then
            onGround = lastGround and math.abs(vz) < 25 and math.abs(z - previousZ) < 0.05
        end
    end
    local onLadder = moveType == 9
    local speed = math.sqrt(vx * vx + vy * vy)
    if speed > 5000 then speed = 0 end

    state.valid, state.alive = true, true
    state.x, state.y, state.z = x, y, z
    state.vx, state.vy, state.vz = vx, vy, vz
    state.speed, state.onGround, state.onLadder = speed, onGround, onLadder
    if speed >= state.displaySpeed then state.displaySpeed = speed
    else state.displaySpeed = state.displaySpeed + (speed - state.displaySpeed) * 0.22 end

    local tookOff = lastGround and not onGround and vz > 80
    if not tookOff and not state.jumpActive and vz > 150 and vz < 420 then tookOff = true end
    if tookOff then
        state.jumpSpeed, state.jumpActive, state.jumpLandedAt = speed, true, 0
        clearTrail()
    elseif state.jumpActive and onGround then
        state.jumpActive, state.jumpLandedAt = false, t
    end
    if state.jumpSpeed and state.jumpLandedAt > 0 and t - state.jumpLandedAt > 3 then
        state.jumpSpeed, state.jumpLandedAt = nil, 0
    end
    lastGround = onGround

    if edgeActive and not onGround and not onLadder and vz < -80 then
        state.groundDistance = groundDistance(lp, x, y, z)
    else
        state.groundDistance = nil
    end
    return true
end

local function shouldDuck()
    if not state.valid or state.onGround or state.onLadder or state.vz >= -80 then return false end
    local distance = state.groundDistance
    if not distance then return false end
    local fallSpeed = -state.vz
    local gravity = 800
    local discriminant = fallSpeed * fallSpeed + 2 * gravity * distance
    if discriminant < 0 then return false end
    local seconds = (-fallSpeed + math.sqrt(discriminant)) / gravity
    local ticks = seconds / tickInterval()
    return ticks >= 0 and ticks <= 1.65
end

local function applyEdgeBug(cmd, active)
    if not active or not shouldDuck() or not cmd then return false end
    local buttons
    pcall(function() buttons = cmd:GetButtons() end)
    if type(buttons) == "number" then
        local ok = pcall(function() cmd:SetButtons(addBit(buttons, IN_DUCK)) end)
        return ok
    end
    return false
end

local function keyDown(code)
    local down = false
    pcall(function() down = input.IsButtonDown(code) and true or false end)
    return down
end

local function updateNullPresses(w, a, s, d)
    local current = { w = w, a = a, s = s, d = d }
    for key, down in pairs(current) do
        if down and not nullState[key] then
            nullState.stamp = nullState.stamp + 1
            nullState.pressed[key] = nullState.stamp
        end
        nullState[key] = down
    end
end

local function applyNullBinds(cmd)
    if not nullEnabled:Get() or not cmd then return end
    local w, a, s, d = keyDown(KEY_W), keyDown(KEY_A), keyDown(KEY_S), keyDown(KEY_D)
    updateNullPresses(w, a, s, d)
    if w and s then
        local magnitude = 450
        pcall(function() magnitude = math.abs(cmd:GetForwardMove() or 0) end)
        if magnitude < 10 then magnitude = 450 end
        local forward = (nullState.pressed.w or 0) >= (nullState.pressed.s or 0)
        pcall(function() cmd:SetForwardMove(forward and magnitude or -magnitude) end)
    end
    if a and d then
        local magnitude = 450
        pcall(function() magnitude = math.abs(cmd:GetSideMove() or 0) end)
        if magnitude < 10 then magnitude = 450 end
        local right = (nullState.pressed.d or 0) >= (nullState.pressed.a or 0)
        pcall(function() cmd:SetSideMove(right and magnitude or -magnitude) end)
    end
end

local function trimTrail(t)
    local life = tonumber(trailDuration:Get()) or 4
    while trailHead <= #trail and t - trail[trailHead].t > life do trailHead = trailHead + 1 end
    if trailHead > 96 then
        local compact = {}
        for i = trailHead, #trail do compact[#compact + 1] = trail[i] end
        trail, trailHead = compact, 1
    end
end

local function updateTrail(t)
    if not trailEnabled:Get() then
        if #trail > 0 then clearTrail() end
        return
    end
    trimTrail(t)
    if not state.valid or not state.jumpActive or t - lastTrailAt < 0.025 then return end
    lastTrailAt = t
    trail[#trail + 1] = { x = state.x, y = state.y, z = state.z + 3, t = t }
    if #trail - trailHead > 255 then trailHead = trailHead + 1 end
end

local function hsvToRgb(h)
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local q, t = 1 - f, f
    local m = i % 6
    local r, g, b
    if m == 0 then r, g, b = 1, t, 0
    elseif m == 1 then r, g, b = q, 1, 0
    elseif m == 2 then r, g, b = 0, 1, t
    elseif m == 3 then r, g, b = 0, q, 1
    elseif m == 4 then r, g, b = t, 0, 1
    else r, g, b = 1, 0, q end
    return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

local velocityFont, smallFont
pcall(function()
    velocityFont = draw.CreateFont("Segoe UI", 42, 700)
    smallFont = draw.CreateFont("Segoe UI", 18, 600)
end)

local function drawVelocity()
    if not velocityEnabled:Get() or not state.valid then return end
    local sw, sh = draw.GetScreenSize()
    if not sw or not sh then return end
    if velocityFont then draw.SetFont(velocityFont) end
    local value = tostring(math.floor(state.displaySpeed + 0.5))
    local tw, th = draw.GetTextSize(value)
    local x = math.floor(sw * 0.5 - (tw or 0) * 0.5)
    local y = math.floor(sh * (velocityY:Get() / 100) - (th or 0) * 0.5)
    draw.Color(0, 0, 0, 210); draw.Text(x + 2, y + 2, value)
    local color = velocityColor:Get()
    draw.Color(color[1], color[2], color[3], color[4]); draw.Text(x, y, value)

    if state.jumpSpeed then
        if smallFont then draw.SetFont(smallFont) end
        local jump = string.format("( %d )", math.floor(state.jumpSpeed + 0.5))
        local jw = select(1, draw.GetTextSize(jump)) or 0
        local alpha = 255
        if state.jumpLandedAt > 0 then alpha = math.floor(255 * clamp(3 - (now() - state.jumpLandedAt), 0, 1)) end
        local jc = jumpColor:Get()
        draw.Color(0, 0, 0, math.floor(alpha * 0.8)); draw.Text(sw * 0.5 - jw * 0.5 + 1, y + (th or 38) + 5, jump)
        draw.Color(jc[1], jc[2], jc[3], math.min(jc[4], alpha)); draw.Text(sw * 0.5 - jw * 0.5, y + (th or 38) + 4, jump)
    end
end

local function project(point)
    local sx, sy
    local ok = pcall(function() sx, sy = client.WorldToScreen(Vector3(point.x, point.y, point.z)) end)
    if ok and sx and sy then return sx, sy end
end

local function drawTrail()
    if not trailEnabled:Get() or trailHead >= #trail then return end
    local t = now()
    local life = tonumber(trailDuration:Get()) or 4
    local thickness = math.floor(tonumber(trailThickness:Get()) or 3)
    local base = trailColor:Get()
    local rainbow = trailRainbow:Get()
    local previousX, previousY
    for i = trailHead, #trail do
        local point = trail[i]
        local x, y = project(point)
        if x and previousX then
            local age = t - point.t
            local fade = clamp(1 - age / life, 0, 1)
            if fade > 0 then
                local r, g, b = base[1], base[2], base[3]
                if rainbow then r, g, b = hsvToRgb((t * 0.16 + i * 0.025) % 1) end
                local dx, dy = x - previousX, y - previousY
                local length = math.sqrt(dx * dx + dy * dy)
                if length > 0.5 then
                    local nx, ny = -dy / length, dx / length
                    local half = math.floor(thickness * 0.5)
                    draw.Color(r, g, b, math.floor((base[4] or 230) * fade * 0.24))
                    for offset = -half, half, 2 do
                        local ox, oy = math.floor(nx * offset + 0.5), math.floor(ny * offset + 0.5)
                        draw.Line(previousX + ox, previousY + oy, x + ox, y + oy)
                    end
                    draw.Color(math.min(255, r + 45), math.min(255, g + 45), math.min(255, b + 45), math.floor((base[4] or 230) * fade))
                    draw.Line(previousX, previousY, x, y)
                end
            end
        end
        previousX, previousY = x, y
    end
end

local moveRegistered, moveActiveEvent, lastMovementAt = "main hook ready", nil, nil
local function drawDebug()
    if not debugEnabled:Get() then return end
    if smallFont then draw.SetFont(smallFont) end
    local lines = {
        string.format("rgnMovement | valid=%s speed=%.1f vz=%.1f", tostring(state.valid), state.speed, state.vz),
        string.format("move callback=%s age=%s", tostring(moveActiveEvent or moveRegistered or "none"), lastMovementAt and string.format("%.2fs", math.max(0, now() - lastMovementAt)) or "never"),
        string.format("ground=%s ladder=%s distance=%s", tostring(state.onGround), tostring(state.onLadder), state.groundDistance and string.format("%.1f", state.groundDistance) or "nil"),
        string.format("edge active=%s inject duck=%s", tostring(state.edgeActive), tostring(state.edgeDuck)),
        "velocity: " .. velocitySource,
        "flags: " .. flagsSource .. " | movetype: " .. moveTypeSource,
        "trace: " .. traceSource,
    }
    local x, y = 18, 180
    draw.Color(8, 10, 14, 210); draw.FilledRect(x - 8, y - 8, x + 470, y + #lines * 20 + 8)
    for i = 1, #lines do
        draw.Color(i == 1 and 74 or 205, i == 1 and 166 or 213, 255, 255)
        draw.Text(x, y + (i - 1) * 20, lines[i])
    end
end

local function colorText(c) return table.concat({ c[1], c[2], c[3], c[4] }, ",") end
local function settingsSnapshot()
    return table.concat({
        velocityEnabled:Get() and "1" or "0", colorText(velocityColor:Get()), colorText(jumpColor:Get()), velocityY:Get(),
        trailEnabled:Get() and "1" or "0", trailDuration:Get(), trailThickness:Get(), trailRainbow:Get() and "1" or "0", colorText(trailColor:Get()),
        edgeEnabled:Get() and "1" or "0", edgeKey:Get(), edgeMode:Get(), nullEnabled:Get() and "1" or "0", debugEnabled:Get() and "1" or "0"
    }, "|")
end

local function saveSettings()
    pcall(function()
        local f = file.Open(CONFIG_FILE, "w")
        if not f then return end
        local lines = {
            "velocity=" .. (velocityEnabled:Get() and "1" or "0"),
            "velocity_color=" .. colorText(velocityColor:Get()),
            "jump_color=" .. colorText(jumpColor:Get()),
            "velocity_y=" .. tostring(velocityY:Get()),
            "trail=" .. (trailEnabled:Get() and "1" or "0"),
            "trail_duration=" .. tostring(trailDuration:Get()),
            "trail_thickness=" .. tostring(trailThickness:Get()),
            "trail_rainbow=" .. (trailRainbow:Get() and "1" or "0"),
            "trail_color=" .. colorText(trailColor:Get()),
            "edge=" .. (edgeEnabled:Get() and "1" or "0"),
            "edge_key=" .. tostring(edgeKey:Get()),
            "edge_mode=" .. tostring(edgeMode:Get()),
            "null_binds=" .. (nullEnabled:Get() and "1" or "0"),
            "debug=" .. (debugEnabled:Get() and "1" or "0"),
        }
        f:Write(table.concat(lines, "\n"))
        f:Close()
    end)
end

statusSection:Button("Show movement engine status", function()
    local moveStatus = moveActiveEvent or moveRegistered or "not connected"
    local drawAge = M._movementDrawAliveAt and math.max(0, now() - M._movementDrawAliveAt) or nil
    local drawStatus = M._movementDrawError and "draw=error" or (drawAge and string.format("draw=live %.2fs", drawAge) or "draw=waiting")
    M:Notify(string.format("move=%s | %s | velocity=%s | flags=%s | trace=%s", moveStatus, drawStatus, velocitySource, flagsSource, traceSource), "info")
end)
statusSection:Button("Reset movement state", function()
    resetMovement("manual reset")
    M:Notify("movement state reset", "success")
end)

pcall(function()
    callbacks.Unregister("PreMove", "rgnMultitool_MovementPreMove")
    callbacks.Unregister("CreateMove", "rgnMultitool_MovementCreateMove")
    callbacks.Unregister("Draw", "rgnMultitool_MovementDraw")
    callbacks.Unregister("FireGameEvent", "rgnMultitool_MovementEvents")
    callbacks.Unregister("Unload", "rgnMultitool_MovementUnload")
end)

local function onMovementCommand(cmd)
    local edgeActive = edgeBindingActive()
    state.edgeActive = edgeActive
    local needsState = velocityEnabled:Get() or trailEnabled:Get() or edgeActive or debugEnabled:Get()
    if needsState then safe("state", updateState, edgeActive) end
    state.edgeDuck = safe("edge bug", applyEdgeBug, cmd, edgeActive) and true or false
    safe("null binds", applyNullBinds, cmd)
    if needsState then safe("jump trail", updateTrail, now()) end
end

M._movementCommandActive = function()
    return velocityEnabled:Get() == true
        or trailEnabled:Get() == true
        or edgeEnabled:Get() == true
        or nullEnabled:Get() == true
        or debugEnabled:Get() == true
end
M._movementCommandCallback = function(cmd)
    moveActiveEvent, lastMovementAt = "Main/CreateMove", now()
    onMovementCommand(cmd)
end

local observedSettings = settingsSnapshot()
local dirtyAt, nextSettingsPoll = nil, 0
M._movementDrawActive = function()
    return M._open == true or dirtyAt ~= nil
        or velocityEnabled:Get() == true
        or trailEnabled:Get() == true
        or debugEnabled:Get() == true
end
M._movementDrawCallback = function()
    local t = now()
    -- Visual fallback: state still updates when an injector accepts CreateMove
    -- registration but never dispatches it. Command mutations remain confined
    -- to the real CreateMove hook below.
    if not lastMovementAt or t - lastMovementAt > 0.20 then
        local needsState = velocityEnabled:Get() or trailEnabled:Get() or debugEnabled:Get()
        if needsState then
            safe("draw state fallback", updateState, false)
            safe("draw trail fallback", updateTrail, t)
        end
    end
    safe("velocity draw", drawVelocity)
    safe("trail draw", drawTrail)
    safe("debug draw", drawDebug)
    if t >= nextSettingsPoll then
        nextSettingsPoll = t + 0.25
        local snapshot = settingsSnapshot()
        if snapshot ~= observedSettings then observedSettings, dirtyAt = snapshot, t + 0.8 end
        if dirtyAt and t >= dirtyAt then saveSettings(); dirtyAt = nil end
    end
end

pcall(function()
    if client and client.AllowListener then
        client.AllowListener("player_spawn")
        client.AllowListener("server_spawn")
        client.AllowListener("game_newmap")
        client.AllowListener("cs_game_disconnected")
    end
    callbacks.Register("FireGameEvent", "rgnMultitool_MovementEvents", function(event)
        if type(M._movementCommandActive) == "function" and not M._movementCommandActive() then return end
        local name
        pcall(function() name = event:GetName() end)
        if name == "server_spawn" or name == "game_newmap" or name == "cs_game_disconnected" then
            resetMovement(name)
        elseif name == "player_spawn" then
            local userID, playerIndex, localIndex
            pcall(function() userID = event:GetInt("userid") end)
            pcall(function() playerIndex = client.GetPlayerIndexByUserID(userID) end)
            pcall(function() localIndex = client.GetLocalPlayerIndex() end)
            if playerIndex and localIndex and playerIndex == localIndex then resetMovement("player_spawn") end
        end
    end)
end)

callbacks.Register("Unload", "rgnMultitool_MovementUnload", function()
    saveSettings()
    M._movementCommandCallback = nil
    M._movementCommandActive = nil
    M._movementDrawCallback = nil
    M._movementDrawActive = nil
    pcall(callbacks.Unregister, "PreMove", "rgnMultitool_MovementPreMove")
    pcall(callbacks.Unregister, "CreateMove", "rgnMultitool_MovementCreateMove")
    pcall(callbacks.Unregister, "Draw", "rgnMultitool_MovementDraw")
    pcall(callbacks.Unregister, "FireGameEvent", "rgnMultitool_MovementEvents")
end)

end)

loadModule("CUSTOM SOUNDS", function()
local M = M

-- Compatible with femboytap's sound pack: place compiled .vsnd_c files in
-- game/csgo/sounds or one of its subfolders. Discovery happens once at load
-- and only when Refresh is pressed; no directory scan runs during gameplay.
local CONFIG_FILE = "rgncustomsounds_config.txt"
local f = rawget(_G, "ffi")
local config = {}
local soundDir, soundNames, soundPaths = nil, {}, {}
local hitComboWidget, killComboWidget
local nextConfigPoll, nextListenerRefresh, observedConfig = 0, 0, nil

local function clock()
    local value = 0
    pcall(function()
        if common and type(common.Time) == "function" then value = common.Time()
        elseif globals and type(globals.RealTime) == "function" then value = globals.RealTime()
        elseif globals and type(globals.CurTime) == "function" then value = globals.CurTime() end
    end)
    return tonumber(value) or 0
end

local function readConfig()
    pcall(function()
        local handle = file.Open(CONFIG_FILE, "r")
        if not handle then return end
        local body = handle:Read() or ""
        handle:Close()
        for line in body:gmatch("[^\r\n]+") do
            local key, value = line:match("^([%w_]+)%s*=%s*(.-)%s*$")
            if key then config[key] = value end
        end
    end)
end

local function cfgBool(key, default)
    local value = config[key]
    if value == nil then return default end
    return value == "1" or value == "true"
end

local function cfgNumber(key, default, minimum, maximum)
    local value = tonumber(config[key]) or default
    if value < minimum then value = minimum elseif value > maximum then value = maximum end
    return value
end

readConfig()

local findFirstA, findNextA, findClose, getCurrentDirectoryA, getModuleFileNameA
local createDirectoryA, winExec
if type(f) == "table" then
    pcall(function() f.cdef[[
        typedef struct {
            uint32_t attributes;
            uint32_t creation_lo, creation_hi;
            uint32_t access_lo, access_hi;
            uint32_t write_lo, write_hi;
            uint32_t size_hi, size_lo;
            uint32_t reserved0, reserved1;
            char filename[260];
            char alternate[14];
        } RGN_SOUND_FIND_DATA;
    ]] end)
    pcall(function() f.cdef[[
        void* GetModuleHandleA(const char*);
        void* GetProcAddress(void*, const char*);
    ]] end)
    pcall(function()
        local kernel32 = f.C.GetModuleHandleA("kernel32.dll")
        local function proc(name, ctype)
            local address = kernel32 ~= nil and f.C.GetProcAddress(kernel32, name) or nil
            return address ~= nil and f.cast(ctype, address) or nil
        end
        findFirstA = proc("FindFirstFileA", "void*(*)(const char*, void*)")
        findNextA = proc("FindNextFileA", "int(*)(void*, void*)")
        findClose = proc("FindClose", "int(*)(void*)")
        getCurrentDirectoryA = proc("GetCurrentDirectoryA", "uint32_t(*)(uint32_t, char*)")
        getModuleFileNameA = proc("GetModuleFileNameA", "uint32_t(*)(void*, char*, uint32_t)")
        createDirectoryA = proc("CreateDirectoryA", "int(*)(const char*, void*)")
        winExec = proc("WinExec", "uint32_t(*)(const char*, uint32_t)")
    end)
end

local function deriveCsgoRoot(path)
    if type(path) ~= "string" or path == "" then return nil end
    local normalized = path:gsub("/", "\\")
    local lower = normalized:lower()
    if lower:sub(-5) == "\\csgo" then return normalized end
    local executableSuffix = "\\bin\\win64\\cs2.exe"
    if lower:sub(-#executableSuffix) == executableSuffix then
        return normalized:sub(1, #normalized - #executableSuffix) .. "\\csgo"
    end
    local marker = "\\bin\\win64"
    local position = lower:find(marker, 1, true)
    if position then return normalized:sub(1, position - 1) .. "\\csgo" end
    return nil
end

local function resolveSoundDirectory()
    if not getCurrentDirectoryA or not getModuleFileNameA or type(f) ~= "table" then return nil end
    local buffer = f.new("char[1024]")
    local count = getCurrentDirectoryA(1024, buffer)
    if count and count > 0 and count < 1024 then
        local root = deriveCsgoRoot(f.string(buffer, count))
        if root then return root .. "\\sounds" end
    end
    count = getModuleFileNameA(nil, buffer, 1024)
    if count and count > 0 and count < 1024 then
        local root = deriveCsgoRoot(f.string(buffer, count))
        if root then return root .. "\\sounds" end
    end
    return nil
end

local function ensureSoundDirectory()
    if not soundDir then soundDir = resolveSoundDirectory() end
    if soundDir and createDirectoryA then pcall(createDirectoryA, soundDir, nil) end
    return soundDir ~= nil
end

local function hasFileAttribute(value, flag)
    value = tonumber(value) or 0
    return value % (flag * 2) >= flag
end

local function safeRelativeSoundPath(path)
    if type(path) ~= "string" or path == "" then return false end
    if path:find('[";\r\n]') or path:find(":", 1, true) then return false end
    for part in path:gmatch("[^\\]+") do
        if part == "" or part == "." or part == ".." then return false end
    end
    return true
end

local function scanSoundDirectory(absoluteDir, relativeDir, paths, depth)
    if depth > 6 then return end
    local data = f.new("RGN_SOUND_FIND_DATA")
    local invalid = f.cast("void*", f.cast("intptr_t", -1))
    local handle = findFirstA(absoluteDir .. "\\*", data)
    if handle == nil or handle == invalid then return end
    repeat
        local filename = f.string(data.filename)
        if filename ~= "." and filename ~= ".." then
            local relative = relativeDir == "" and filename or (relativeDir .. "\\" .. filename)
            local attributes = tonumber(data.attributes) or 0
            if hasFileAttribute(attributes, 0x10) then
                -- Never follow junctions/symlinks outside csgo/sounds.
                if not hasFileAttribute(attributes, 0x400) and safeRelativeSoundPath(relative) then
                    scanSoundDirectory(absoluteDir .. "\\" .. filename, relative, paths, depth + 1)
                end
            elseif filename:lower():sub(-7) == ".vsnd_c" and safeRelativeSoundPath(relative) then
                paths[#paths + 1] = relative:sub(1, #relative - 7)
            end
        end
    until findNextA(handle, data) == 0
    findClose(handle)
end

local function scanSounds()
    local names, paths = {}, {}
    if not ensureSoundDirectory() or not findFirstA or not findNextA or not findClose or type(f) ~= "table" then
        return { "[ csgo\\sounds unavailable ]" }, paths
    end
    scanSoundDirectory(soundDir, "", paths, 0)
    table.sort(paths, function(a, b) return a:lower() < b:lower() end)
    for i = 1, #paths do names[i] = paths[i] end
    if #names == 0 then names[1] = "[ put .vsnd_c in csgo\\sounds ]" end
    return names, paths
end

soundDir = resolveSoundDirectory()
soundNames, soundPaths = scanSounds()

local function soundIndex(saved)
    saved = tostring(saved or "")
    for i = 1, #soundPaths do if soundPaths[i] == saved then return i end end
    return 1
end

local tab = M:Tab("CUSTOM SOUNDS")
tab:Row()
local hitSection = tab:Section("Hit sound")
local hitEnabled = hitSection:Checkbox("Enable custom hit sound", cfgBool("hit_enabled", false))
local hitCombo = hitSection:Combo("Sound", soundNames, soundIndex(config.hit_sound))
hitComboWidget = hitSection.ws[#hitSection.ws]
local hitVolume = hitSection:Slider("Volume", cfgNumber("hit_volume", 100, 0, 100), 0, 100, 1, "%.0f%%")

tab:Col()
local killSection = tab:Section("Kill sound")
local killEnabled = killSection:Checkbox("Enable custom kill sound", cfgBool("kill_enabled", false))
local killCombo = killSection:Combo("Sound", soundNames, soundIndex(config.kill_sound))
killComboWidget = killSection.ws[#killSection.ws]
local killVolume = killSection:Slider("Volume", cfgNumber("kill_volume", 100, 0, 100), 0, 100, 1, "%.0f%%")

M._customSoundsEventActive = function()
    return hitEnabled:Get() == true or killEnabled:Get() == true
end

tab:Col()
local librarySection = tab:Section("Sound library")

local function selectedSound(combo)
    return tostring(soundPaths[tonumber(combo:Get()) or 1] or "")
end

local function playSound(path, volume)
    path = tostring(path or ""):gsub("/", "\\")
    if path == "" or not safeRelativeSoundPath(path) then return false end
    local amount = math.max(0, math.min(100, tonumber(volume) or 100)) / 100
    if amount <= 0 then return false end
    pcall(function() client.SetConVar("snd_toolvolume", amount, true) end)
    local ok = pcall(function() client.Command('play "sounds\\' .. path .. '"', true) end)
    return ok
end

local function currentSnapshot()
    return table.concat({
        hitEnabled:Get() and "1" or "0", selectedSound(hitCombo), tostring(hitVolume:Get()),
        killEnabled:Get() and "1" or "0", selectedSound(killCombo), tostring(killVolume:Get()),
    }, "|")
end

local function saveConfig()
    pcall(function()
        local handle = file.Open(CONFIG_FILE, "w")
        if not handle then return end
        handle:Write(table.concat({
            "hit_enabled=" .. (hitEnabled:Get() and "1" or "0"),
            "hit_sound=" .. selectedSound(hitCombo),
            "hit_volume=" .. tostring(hitVolume:Get()),
            "kill_enabled=" .. (killEnabled:Get() and "1" or "0"),
            "kill_sound=" .. selectedSound(killCombo),
            "kill_volume=" .. tostring(killVolume:Get()),
        }, "\n"))
        handle:Close()
    end)
end

local function refreshSounds()
    local oldHit, oldKill = selectedSound(hitCombo), selectedSound(killCombo)
    soundNames, soundPaths = scanSounds()
    hitComboWidget.options, killComboWidget.options = soundNames, soundNames
    hitCombo:Set(soundIndex(oldHit))
    killCombo:Set(soundIndex(oldKill))
    observedConfig = currentSnapshot()
    saveConfig()
    print(string.format("[rgnSounds] refreshed: %d .vsnd_c files in %s", #soundPaths, tostring(soundDir or "unresolved")))
end

librarySection:Button("Preview hit sound", function()
    if not playSound(selectedSound(hitCombo), hitVolume:Get()) then print("[rgnSounds] select a valid hit sound") end
end)
librarySection:Button("Preview kill sound", function()
    if not playSound(selectedSound(killCombo), killVolume:Get()) then print("[rgnSounds] select a valid kill sound") end
end)
librarySection:Button("Refresh csgo/sounds", refreshSounds)
librarySection:Button("Open sounds folder", function()
    if ensureSoundDirectory() and winExec then
        pcall(function() winExec('explorer.exe "' .. soundDir .. '"', 5) end)
    else
        print("[rgnSounds] csgo/sounds could not be resolved")
    end
end)
librarySection:Custom(44, function(ui)
    ui.label("Detected: " .. tostring(#soundPaths) .. " compiled sounds", ui.T.text)
    ui.label("Folder: csgo\\sounds (.vsnd_c)", ui.T.textdim)
end)

local function entityIndex(entity)
    local value
    if not entity then return nil end
    pcall(function() value = tonumber(entity:GetIndex()) end)
    return value and value > 0 and value or nil
end

local function pawnHandleIndex(value)
    value = tonumber(value)
    if not value or value == 0 or value == -1 then return nil end
    local index = value % 32768
    if index <= 0 or index == 32767 then return nil end
    return index
end

local function controllerPawn(controller)
    local pawn
    if not controller then return nil end
    pcall(function() pawn = controller:GetPropEntity("m_hPlayerPawn") end)
    if not pawn then pcall(function() pawn = controller:GetFieldEntity("m_hPlayerPawn") end) end
    return pawn
end

-- Strict local identity cache. User IDs, controller indices and pawn handles
-- live in different namespaces; treating them as interchangeable caused
-- accidental matches with unrelated players (especially in Deathmatch).
local localIdentity = {
    updatedAt = -100,
    pawnIndices = {},
    playerIndices = {},
    userIDs = {},
}

local function addPlayerInfo(identity, index)
    index = tonumber(index)
    if not index or index <= 0 then return end
    identity.playerIndices[index] = true
    local info
    pcall(function() info = client.GetPlayerInfo(index) end)
    if type(info) ~= "table" then return end
    local userID = tonumber(info.UserID or info.userID or info.userid)
    if userID and userID > 0 then identity.userIDs[userID] = true end
end

local function refreshLocalIdentity(force)
    local now = clock()
    if not force and now - localIdentity.updatedAt < 0.25 then return localIdentity end
    localIdentity.updatedAt = now
    localIdentity.pawnIndices = {}
    localIdentity.playerIndices = {}
    localIdentity.userIDs = {}

    local localPawn
    pcall(function() localPawn = entities.GetLocalPlayer() end)
    local localPawnIndex = entityIndex(localPawn)
    if localPawnIndex then
        localIdentity.pawnIndices[localPawnIndex] = true
        addPlayerInfo(localIdentity, localPawnIndex)
    end

    local localClientIndex
    pcall(function() localClientIndex = tonumber(client.GetLocalPlayerIndex()) end)
    addPlayerInfo(localIdentity, localClientIndex)

    local controllers
    pcall(function() controllers = entities.FindByClass("CCSPlayerController") end)
    if type(controllers) == "table" then
        for i = 1, #controllers do
            local controller = controllers[i]
            local controllerIndex = entityIndex(controller)
            local controllerIsLocal
            pcall(function() controllerIsLocal = controller:GetFieldBool("m_bIsLocalPlayerController") end)
            if controllerIsLocal == nil then
                pcall(function() controllerIsLocal = controller:GetPropBool("m_bIsLocalPlayerController") end)
            end
            local pawnIndex = entityIndex(controllerPawn(controller))
            if controllerIsLocal == true or
               (localPawnIndex and pawnIndex and pawnIndex == localPawnIndex) then
                if pawnIndex then localIdentity.pawnIndices[pawnIndex] = true end
                addPlayerInfo(localIdentity, controllerIndex)
                if pawnIndex then addPlayerInfo(localIdentity, pawnIndex) end
            end
        end
    end
    return localIdentity
end

local function isLocalActor(rawUserID, pawnHandle)
    local identity = refreshLocalIdentity(false)
    local pawnIndex = pawnHandleIndex(pawnHandle)
    if pawnIndex then
        -- A supplied pawn is authoritative. Never fall back to a coincidental
        -- userid/entity-index match when it belongs to somebody else.
        return identity.pawnIndices[pawnIndex] == true
    end

    rawUserID = tonumber(rawUserID)
    if not rawUserID or rawUserID <= 0 then return false end
    if identity.userIDs[rawUserID] == true then return true end

    local mappedIndex
    pcall(function() mappedIndex = tonumber(client.GetPlayerIndexByUserID(rawUserID)) end)
    return mappedIndex ~= nil and identity.playerIndices[mappedIndex] == true
end

local lastKillSignature, lastKillAt = nil, -100

local function killSignature(attacker, victim, attackerPawn, victimPawn)
    return table.concat({
        tostring(pawnHandleIndex(attackerPawn) or attacker or 0),
        tostring(pawnHandleIndex(victimPawn) or victim or 0),
    }, ":")
end

local function playKillOnce(signature)
    local t = clock()
    if signature == lastKillSignature and t - lastKillAt < 0.50 then return end
    lastKillSignature, lastKillAt = signature, t
    playSound(selectedSound(killCombo), killVolume:Get())
end

M._customSoundsEventCallback = function(event)
    if not hitEnabled:Get() and not killEnabled:Get() then return end
    local name
    pcall(function() name = event:GetName() end)
    if name ~= "player_hurt" and name ~= "player_death" then return end
    local attacker, victim, attackerPawn, victimPawn, health, damage
    pcall(function()
        attacker = tonumber(event:GetInt("attacker"))
        victim = tonumber(event:GetInt("userid"))
        attackerPawn = tonumber(event:GetInt("attacker_pawn"))
        victimPawn = tonumber(event:GetInt("userid_pawn"))
        health = tonumber(event:GetInt("health"))
        damage = tonumber(event:GetInt("dmg_health"))
    end)
    local attackerPawnIndex, victimPawnIndex = pawnHandleIndex(attackerPawn), pawnHandleIndex(victimPawn)
    if attacker and victim and attacker == victim then return end
    if attackerPawnIndex and victimPawnIndex and attackerPawnIndex == victimPawnIndex then return end
    if not isLocalActor(attacker, attackerPawn) then return end
    if isLocalActor(victim, victimPawn) then return end

    local signature = killSignature(attacker, victim, attackerPawn, victimPawn)
    if name == "player_death" then
        if killEnabled:Get() then playKillOnce(signature) end
        return
    end
    if not damage or damage <= 0 then return end
    if health and health <= 0 then
        if killEnabled:Get() then playKillOnce(signature)
        elseif hitEnabled:Get() then playSound(selectedSound(hitCombo), hitVolume:Get()) end
    elseif hitEnabled:Get() then
        playSound(selectedSound(hitCombo), hitVolume:Get())
    end
end

local function requestSoundListeners()
    pcall(function()
        if client and type(client.AllowListener) == "function" then
            client.AllowListener("player_hurt")
            client.AllowListener("player_death")
        end
    end)
end

requestSoundListeners()
observedConfig = currentSnapshot()
M:OnFrame(function()
    local now = clock()
    if now >= nextListenerRefresh then
        nextListenerRefresh = now + 2.0
        requestSoundListeners()
    end
    if now < nextConfigPoll then return end
    nextConfigPoll = now + 0.50
    local snapshot = currentSnapshot()
    if snapshot ~= observedConfig then observedConfig = snapshot; saveConfig() end
end)

callbacks.Register("Unload", function()
    pcall(saveConfig)
    M._customSoundsEventCallback = nil
    M._customSoundsEventActive = nil
end)

end)

loadModule("KILLSAY", function()
local M = M

-- Clean event-driven killsay. It deliberately avoids the obfuscated upstream
-- payload and sends at most one sanitized public-chat message per local kill.
local CONFIG_FILE = "rgnkillsay_config.txt"
local PACK_NAMES = {
    "English / Competitive", "English / Savage", "Argentina / Cancha", "Short",
    "Portuguese BR", "Spanish LATAM", "French", "German", "Italian", "Polish",
    "Russian (Latin)", "Turkish", "Japanese (Romaji)", "Chinese (Pinyin)",
    "Korean (Romanized)", "Dutch", "Swedish", "Custom"
}
local FALLBACK_NAMES = {
    [3] = "maestro", [5] = "jogador", [6] = "rival", [7] = "joueur",
    [8] = "Gegner", [9] = "rivale", [10] = "gracz", [11] = "igrok",
    [12] = "rakip", [13] = "aite", [14] = "duishou", [15] = "sangdae",
    [16] = "tegenstander", [17] = "motstandare",
}
local PACKS = {
    [1] = {
        "That duel was free, {name}; thanks for the warmup.",
        "You peeked like you wanted to lose, {name}.",
        "Read like a children's book, {name}.",
        "Your timing is a public service for my score, {name}.",
        "Another free round delivered by {name}.",
        "You held that angle like it owed you money, {name}.",
        "Caught clueless again, {name}.",
        "You made that look embarrassingly easy, {name}.",
        "Back to spectator school, {name}; lesson one starts now.",
        "You lost the duel before you even clicked, {name}.",
    },
    [2] = {
        "Sit down, {name}; you are padding my stats.",
        "Even the practice bots put up more resistance, {name}.",
        "You are not the threat you imagined, {name}.",
        "That aim belongs on the loading screen, {name}.",
        "Keep donating rounds, {name}; the scoreboard loves you.",
        "You turned a fair duel into a free frag, {name}.",
        "Spectator suits you better, {name}.",
        "You brought confidence and forgot the skill, {name}.",
        "Delete that peek from your memory, {name}.",
        "You got humbled before the fight even started, {name}.",
        "At this point the crosshair is just decoration, {name}.",
        "Thanks for standing exactly where a free kill should be, {name}.",
    },
    [3] = {
        "Que muerto sos, {name}; ni con el arbitro a favor.",
        "Te comiste el amague entero, {name}; segui de largo.",
        "Sos mas pecho frio que una tribuna vacia, {name}.",
        "Cerra el estadio, {name}; esto ya es goleada.",
        "Te pinte la cara, {name}; anda a buscarla adentro.",
        "Sos un cono, {name}; te gambetee parado.",
        "Dale que arrancamos, {name}; vos seguis en el vestuario.",
        "Te mandaron al banco, {name}; ni para hacer tiempo servis.",
        "Que baile te comiste, {name}; pedi la hora.",
        "Ni con VAR te salvas de esa, {name}.",
        "Te saque a pasear, {name}; faltaba la correa.",
        "Pecho frio, {name}; desapareciste en la importante.",
        "Jugaste con los botines cambiados, {name}.",
        "Te hice precio, {name}; la proxima es goleada.",
        "Aplaudi desde la platea, {name}; en la cancha no existis.",
        "Te fuiste silbado, {name}; no aparezcas en el segundo tiempo.",
    },
    [4] = {
        "nt {name}",
        "outplayed {name}",
        "free frag {name}",
        "back to spawn {name}",
        "sit down {name}",
        "too easy {name}",
        "timing diff {name}",
        "scoreboard filler {name}",
    },
    [5] = {
        "Volta pro lobby, {name}; voce so veio completar numero.",
        "Que mira triste, {name}; ate o bot ficou com pena.",
        "Foi de graca, {name}; nem precisei tentar.",
        "Abre espaco no banco, {name}; titular voce nao e.",
        "Voce entrou so para virar highlight, {name}.",
        "Desinstala com calma, {name}; por hoje ja deu.",
        "Mais perdido que bala no ceu, {name}.",
        "Obrigado pelo frag gratis, {name}.",
        "Sua mira pediu demissao, {name}.",
        "Voce fala como craque e joga como alvo, {name}.",
    },
    [6] = {
        "De vuelta al lobby, {name}; solo viniste a regalar puntos.",
        "Ni los bots se asoman tan mal, {name}.",
        "Mucho ruido y cero punteria, {name}.",
        "Te mande a mirar la partida desde afuera, {name}.",
        "Gracias por el punto gratis, {name}.",
        "Tu mira se fue antes que vos, {name}.",
        "Entraste confiado y saliste de adorno, {name}.",
        "Cada vez que apareces sube mi marcador, {name}.",
        "Te quedo grande ese duelo, {name}.",
        "Hasta el espectador vio venir eso, {name}.",
    },
    [7] = {
        "Retour au lobby, {name}; tu sers de cible gratuite.",
        "Meme un bot resiste mieux que toi, {name}.",
        "Beaucoup de confiance, aucune precision, {name}.",
        "Merci pour le point gratuit, {name}.",
        "Le mode spectateur te va mieux, {name}.",
        "Ton viseur est juste decoratif, {name}.",
        "Tu as perdu ce duel avant de tirer, {name}.",
        "Encore une apparition inutile, {name}.",
        "Tu rends mes frags beaucoup trop faciles, {name}.",
        "Reviens quand tu trouveras ta precision, {name}.",
    },
    [8] = {
        "Zurueck in die Lobby, {name}; du bist nur ein Gratisfrag.",
        "Sogar ein Bot haette laenger ueberlebt, {name}.",
        "Viel Selbstvertrauen, null Treffer, {name}.",
        "Danke fuer den kostenlosen Punkt, {name}.",
        "Der Zuschauermodus passt besser zu dir, {name}.",
        "Dein Fadenkreuz ist nur Dekoration, {name}.",
        "Du hattest den Kampf schon vorher verloren, {name}.",
        "Noch so ein Peek und mein Score bedankt sich, {name}.",
        "Du spielst das Ziel, ich sammle die Punkte, {name}.",
        "Dein Aim ist heute nicht erschienen, {name}.",
    },
    [9] = {
        "Torna nella lobby, {name}; sei solo un punto gratis.",
        "Anche un bot avrebbe resistito di piu, {name}.",
        "Tanta sicurezza, zero mira, {name}.",
        "Grazie per il frag gratuito, {name}.",
        "La modalita spettatore ti dona, {name}.",
        "Quel mirino e solo decorazione, {name}.",
        "Hai perso il duello prima di sparare, {name}.",
        "Continua cosi, il mio punteggio ringrazia, {name}.",
        "Sei entrato da eroe e uscito da comparsa, {name}.",
        "Oggi la tua mira e rimasta a casa, {name}.",
    },
    [10] = {
        "Wracaj do lobby, {name}; jestes tylko darmowym fragiem.",
        "Nawet bot stawilby wiekszy opor, {name}.",
        "Duza pewnosc siebie, zero celowania, {name}.",
        "Dzieki za darmowy punkt, {name}.",
        "Tryb widza pasuje ci lepiej, {name}.",
        "Ten celownik masz chyba tylko dla ozdoby, {name}.",
        "Przegrales ten pojedynek przed pierwszym strzalem, {name}.",
        "Dalej tak zagladaj, moj wynik rosnie, {name}.",
        "Wszedles pewny siebie, wyszedles bez wyniku, {name}.",
        "Twoj aim wzial dzis wolne, {name}.",
    },
    [11] = {
        "Nazad v lobby, {name}; ty segodnya besplatnyy frag.",
        "Dazhe bot igral by luchshe, {name}.",
        "Mnogo uverennosti, nol popadaniy, {name}.",
        "Spasibo za besplatnoe ochko, {name}.",
        "Rezhim zritelya tebe podhodit bolshe, {name}.",
        "Pricel u tebya prosto dlya krasoty, {name}.",
        "Ty proigral duel eshche do vystrela, {name}.",
        "Prodolzhay tak, moy schet rastet, {name}.",
        "Zashel kak geroi, vyshel kak statist, {name}.",
        "Tvoy aim segodnya ne prishel, {name}.",
    },
    [12] = {
        "Lobiye geri don, {name}; bedava skor oldun.",
        "Bot bile daha uzun dayanirdi, {name}.",
        "Ozguven cok, isabet yok, {name}.",
        "Bedava puan icin tesekkurler, {name}.",
        "Izleyici modu sana daha cok yakisiyor, {name}.",
        "Nisangahin sadece sus gibi duruyor, {name}.",
        "Daha ates etmeden duelloyu kaybettin, {name}.",
        "Boyle devam et, skorum seni seviyor, {name}.",
        "Kahraman gibi girdin, hedef gibi ciktin, {name}.",
        "Bugun aimini evde unutmusun, {name}.",
    },
    [13] = {
        "Lobby ni modore, {name}; tada no free frag da.",
        "Bot no hou ga mada tsuyoi, {name}.",
        "Jishin dake de aim ga nai na, {name}.",
        "Free point arigatou, {name}.",
        "Spectator no hou ga niautteru yo, {name}.",
        "Sono crosshair wa kazari ka, {name}.",
        "Utsu mae kara maketeta yo, {name}.",
        "Mata kite kure, score ga fuete tasukaru, {name}.",
        "Hero no tsumori de target ni natta na, {name}.",
        "Kyou no aim wa yasumi mitai da, {name}.",
    },
    [14] = {
        "Hui dating ba, {name}; ni zhi shi mianfei ren tou.",
        "Lian bot dou bi ni neng da, {name}.",
        "Zixin hen duo, mingzhong wei ling, {name}.",
        "Xiexie ni song de mianfei fen, {name}.",
        "Pangguan moshi geng shihe ni, {name}.",
        "Ni de zhunxing zhi shi zhuangshi, {name}.",
        "Hai mei kaiqiang ni jiu yijing shule, {name}.",
        "Jixu zheyang, wo de fenshu hen kaixin, {name}.",
        "Ni xiang dang yingxiong, jieguo dang le mubiao, {name}.",
        "Ni jintian ba qiangfa wang zai jia le, {name}.",
    },
    [15] = {
        "Lobiro doraga, {name}; neon geunyang gongjja fragiya.",
        "Botdo neoboda deo jalhanda, {name}.",
        "Jasin-gameun manhgo aim-eun eopne, {name}.",
        "Gongjja jeomsu gomawo, {name}.",
        "Gwangjeon modeuga deo jal eoullinda, {name}.",
        "Crosshair-ga jangsig-inga, {name}.",
        "Ssogido jeone gyeonggireul jyeosseo, {name}.",
        "Gyesok geureoke hae, nae scorega joahae, {name}.",
        "Yeongungcheoreom deureowa targetcheoreom nagane, {name}.",
        "Oneul aim-eun swineun nal-inga bwa, {name}.",
    },
    [16] = {
        "Terug naar de lobby, {name}; je bent een gratis frag.",
        "Zelfs een bot hield het langer vol, {name}.",
        "Veel zelfvertrouwen, geen enkel schot raak, {name}.",
        "Bedankt voor het gratis punt, {name}.",
        "De toeschouwermodus past beter bij je, {name}.",
        "Dat vizier is blijkbaar alleen versiering, {name}.",
        "Je verloor het duel voordat je schoot, {name}.",
        "Blijf zo pieken, mijn score is je dankbaar, {name}.",
        "Je kwam binnen als held en vertrok als doelwit, {name}.",
        "Je aim is vandaag thuisgebleven, {name}.",
    },
    [17] = {
        "Tillbaka till lobbyn, {name}; du ar ett gratis frag.",
        "Till och med en bot hade overlevt langre, {name}.",
        "Mycket sjalvfortroende, inga traffar, {name}.",
        "Tack for gratispoangen, {name}.",
        "Askadarlaget passar dig battre, {name}.",
        "Ditt sikte verkar bara vara dekoration, {name}.",
        "Du forlorade duellen innan du skot, {name}.",
        "Fortsatt sa, min poang tackar dig, {name}.",
        "Du kom in som hjalte och gick ut som maltavla, {name}.",
        "Ditt aim tog visst ledigt idag, {name}.",
    },
}

local function clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function now()
    local value
    pcall(function() value = globals.RealTime() end)
    if type(value) ~= "number" then pcall(function() value = globals.CurTime() end) end
    return tonumber(value) or 0
end

local config = {}
pcall(function()
    local handle = file.Open(CONFIG_FILE, "r")
    if not handle then return end
    local raw = handle:Read() or ""
    handle:Close()
    for line in tostring(raw):gmatch("[^\r\n]+") do
        local key, value = line:match("^([%w_]+)=(.*)$")
        if key then config[key] = value end
    end
end)

local function cfgBool(key, default)
    if config[key] == nil then return default end
    return config[key] == "1" or config[key] == "true"
end

local function cfgNumber(key, default, minimum, maximum)
    return clamp(tonumber(config[key]) or default, minimum, maximum)
end

local function cleanChatText(value)
    value = tostring(value or "")
    value = value:gsub("[%c]", " "):gsub('"', ""):gsub(";", ""):gsub("\\", "")
    value = value:gsub("%s+", " "):match("^%s*(.-)%s*$") or ""
    if #value > 120 then value = value:sub(1, 120) end
    return value
end

local tab = M:Tab("KILLSAY")
tab:Row()
local mainSection = tab:Section("Killsay")
-- Deliberately session-only: every Lua Run starts disarmed regardless of an
-- older config file.  The user must explicitly tick Enable killsay.
local enabled = mainSection:Checkbox("Enable killsay", false)
local savedPack = cfgNumber("pack", 1, 1, #PACK_NAMES)
-- Catalogue v1 had Custom at index 5. Move that saved selection to the new
-- final index once, while leaving every other existing selection untouched.
if config.pack_catalog ~= "2" and savedPack == 5 then savedPack = #PACK_NAMES end
local pack = mainSection:Combo("Message pack", PACK_NAMES, savedPack)
local order = mainSection:Combo("Message order", { "Random", "Sequential" }, cfgNumber("order", 1, 1, 2))
local includeName = mainSection:Checkbox("Include victim name", cfgBool("include_name", true))
local delay = mainSection:Slider("Minimum chat interval", cfgNumber("chat_interval", 0.75, 0.70, 1.5), 0.70, 1.5, 0.05, "%.2fs")

local customSection = tab:Section("Custom message")
local customMessage = customSection:Input("Text ({name} / [name] = victim)", config.custom or "Nice try, {name}.", "message sent after a kill...")
M._killsayCustomPackIndex = #PACK_NAMES

tab:Col()
local statusSection = tab:Section("Preview / status")
local sequence, lastIndex, eventCounter = {}, {}, 0
local pending, lastSentAt = {}, -100
local lastVictim, lastMessage, status = "none", "none", "disabled"
local deathEvents, localKills, sendMethod = 0, 0, "not used"
local lastDeathSignature, lastDeathAt = nil, -100
local eventKillCredits = 0
local lastTestAt = -100
local awaitingChat, chatConfirmed, chatTimeouts = nil, 0, 0
local RUNTIME_FILE = "rgnkillsay_runtime.txt"
local callbackEvents = 0
local runtimeHistory = {}
local armed = false
local nextSessionPoll, nextListenerRefresh = 0, 0
local lastSessionKey, sessionEpoch = nil, 0

M._killsayEventActive = function()
    return armed == true
end

local function requestKillsayListeners()
    pcall(function()
        if not client or type(client.AllowListener) ~= "function" then return end
        client.AllowListener("player_death")
        client.AllowListener("player_hurt")
        client.AllowListener("player_chat")
        client.AllowListener("server_spawn")
        client.AllowListener("game_newmap")
        client.AllowListener("cs_game_disconnected")
    end)
end

local function currentSessionKey()
    local server, map, localIndex = "", "", 0
    pcall(function()
        if engine and type(engine.GetServerIP) == "function" then server = engine.GetServerIP() or "" end
    end)
    pcall(function()
        if engine and type(engine.GetMapName) == "function" then map = engine.GetMapName() or "" end
    end)
    pcall(function()
        if client and type(client.GetLocalPlayerIndex) == "function" then localIndex = tonumber(client.GetLocalPlayerIndex()) or 0 end
    end)
    return cleanChatText(server) .. "|" .. cleanChatText(map) .. "|" .. (localIndex > 0 and "online" or "offline")
end

local function writeRuntime(reason, values)
    pcall(function()
        local detail = {}
        if type(values) == "table" then
            local keys = {}
            for key in pairs(values) do keys[#keys + 1] = tostring(key) end
            table.sort(keys)
            for i = 1, #keys do
                local key = keys[i]
                detail[#detail + 1] = cleanChatText(key) .. ":" .. cleanChatText(values[key])
            end
        end
        runtimeHistory[#runtimeHistory + 1] = string.format(
            "%d|%s|%s", callbackEvents, cleanChatText(reason), table.concat(detail, ",")
        )
        if #runtimeHistory > 16 then table.remove(runtimeHistory, 1) end

        local handle = file.Open(RUNTIME_FILE, "w")
        if not handle then return end
        local lines = {
            "reason=" .. cleanChatText(reason),
            "callback_events=" .. tostring(callbackEvents),
            "enabled=" .. (enabled:Get() and "1" or "0"),
            "armed=" .. (armed and "1" or "0"),
            "death_events=" .. tostring(deathEvents),
            "local_kills=" .. tostring(localKills),
            "pending=" .. tostring(#pending),
            "send_method=" .. cleanChatText(sendMethod),
            "history_count=" .. tostring(#runtimeHistory),
        }
        if type(values) == "table" then
            for key, value in pairs(values) do
                lines[#lines + 1] = cleanChatText(key) .. "=" .. cleanChatText(value)
            end
        end
        for i = 1, #runtimeHistory do
            lines[#lines + 1] = "history_" .. tostring(i) .. "=" .. runtimeHistory[i]
        end
        handle:Write(table.concat(lines, "\n"))
        handle:Close()
    end)
end

local function selectedList()
    local selected = clamp(pack:Get(), 1, #PACK_NAMES)
    if selected == #PACK_NAMES then
        local custom = cleanChatText(customMessage:Get())
        if custom == "" then custom = "Nice try, {name}." end
        return { custom }, selected
    end
    return PACKS[selected], selected
end

local function chooseTemplate(advance)
    local list, selected = selectedList()
    local index
    if order:Get() == 2 then
        index = sequence[selected] or 1
        if advance then sequence[selected] = index % #list + 1 end
    else
        local salt = math.floor(now() * 1000) + eventCounter * 37 + selected * 97
        index = salt % #list + 1
        if #list > 1 and index == lastIndex[selected] then index = index % #list + 1 end
        if advance then lastIndex[selected] = index end
    end
    return list[index], selected
end

local function formatMessage(template, victimName, selected)
    local fallback = FALLBACK_NAMES[selected] or "opponent"
    local replacement = includeName:Get() and cleanChatText(victimName) or fallback
    if replacement == "" then replacement = fallback end
    local message = tostring(template):gsub("{name}", function() return replacement end)
    message = message:gsub("%[name%]", function() return replacement end)
    return cleanChatText(message)
end

local function playerName(userID, playerIndex)
    local name
    pcall(function()
        if client.GetPlayerNameByUserID then name = client.GetPlayerNameByUserID(userID) end
    end)
    if type(name) ~= "string" or name == "" then
        local candidates = {}
        local function addCandidate(value)
            value = tonumber(value)
            if value and value > 0 then candidates[#candidates + 1] = value end
        end
        addCandidate(playerIndex)
        addCandidate(userID)
        addCandidate(tonumber(userID) and (tonumber(userID) % 32768) or nil)
        for i = 1, #candidates do
            local candidate = tonumber(candidates[i])
            if candidate and candidate > 0 then
                pcall(function()
                    if client.GetPlayerNameByIndex then name = client.GetPlayerNameByIndex(candidate) end
                end)
                if type(name) == "string" and name ~= "" then break end
            end
        end
    end
    return cleanChatText(name ~= nil and name or "opponent")
end

local function queueForVictim(victimName)
    eventCounter = eventCounter + 1
    local template, selected = chooseTemplate(true)
    local message = formatMessage(template, victimName, selected)
    if message == "" then status = "empty message blocked"; return end
    if #pending >= 12 then table.remove(pending, 1) end
    pending[#pending + 1] = { text = message, victim = victimName, at = now() }
    lastVictim, lastMessage, status = victimName, message, "queued"
end

local function sendPublic(message)
    if client and type(client.ChatSay) == "function" then
        local ok, result = pcall(client.ChatSay, message)
        if ok and result ~= false then return true, "client.ChatSay" end
    end
    local ok, err = pcall(function() client.Command('say "' .. message .. '"', true) end)
    if ok then return true, "client.Command fallback" end
    return false, tostring(err)
end

local function sendForVictimNow(victimName)
    eventCounter = eventCounter + 1
    local template, selected = chooseTemplate(true)
    local message = formatMessage(template, victimName, selected)
    if message == "" then
        status = "empty message blocked"
        return false, "empty message", message
    end
    local ok, method = sendPublic(message)
    if ok then
        lastSentAt, lastVictim, lastMessage = now(), victimName, message
        sendMethod, status = method, "sent"
        return true, method, message
    end
    status = "send failed"
    sendMethod = tostring(method)
    return false, method, message
end

statusSection:Button("Preview next message", function()
    local template, selected = chooseTemplate(false)
    local message = formatMessage(template, "Player", selected)
    print("[rgnKillsay] preview: " .. message)
    M:Notify(message, "info")
end)
statusSection:Button("Send test message to chat", function()
    local t = now()
    if t - lastTestAt < 1.0 then return end
    lastTestAt = t
    local template, selected = chooseTemplate(false)
    local message = formatMessage(template, "TestPlayer", selected)
    local ok, method = sendPublic(message)
    if ok then
        lastMessage, sendMethod, status = message, method, "test sent"
        print("[rgnKillsay] test sent via " .. method .. ": " .. message)
        M:Notify("test sent via " .. method, "success")
    else
        status = "test failed"
        print("[rgnKillsay] test send error: " .. tostring(method))
        M:Notify("chat send failed; check console", "error")
    end
end)
statusSection:Button("Show killsay status", function()
    M:Notify(string.format("%s | deaths=%d local=%d queued=%d | %s", status, deathEvents, localKills, #pending, sendMethod), "info")
    print(string.format("[rgnKillsay] pack=%s | victim=%s | last=%s", PACK_NAMES[pack:Get()] or "?", lastVictim, lastMessage))
end)
statusSection:Button("Clear pending messages", function()
    pending = {}
    status = enabled:Get() and "ready" or "disabled"
    M:Notify("pending killsays cleared", "success")
end)

local function saveConfig()
    pcall(function()
        local handle = file.Open(CONFIG_FILE, "w")
        if not handle then return end
        local lines = {
            "enabled=0",
            "pack_catalog=2",
            "pack=" .. tostring(pack:Get()),
            "order=" .. tostring(order:Get()),
            "include_name=" .. (includeName:Get() and "1" or "0"),
            "chat_interval=" .. tostring(delay:Get()),
            "custom=" .. cleanChatText(customMessage:Get()),
        }
        handle:Write(table.concat(lines, "\n"))
        handle:Close()
    end)
end

local function snapshot()
    return table.concat({
        enabled:Get() and "1" or "0", pack:Get(), order:Get(), includeName:Get() and "1" or "0",
        delay:Get(), cleanChatText(customMessage:Get())
    }, "|")
end

local observed, dirtyAt, nextPoll = snapshot(), nil, 0
local killPollAt, pollCounter, pollCounterKind = 0, nil, nil
local pollAlive = {}

M._killsayDrawActive = function()
    -- While the menu is open this keeps setting changes and enable/disable
    -- transitions immediate. A pending config save also finishes after close;
    -- otherwise closed + disabled is a true zero-work state.
    return M._open == true or armed == true or enabled:Get() == true or dirtyAt ~= nil
end

local function pollKillsayConfig(t)
    if t < nextPoll then return end
    nextPoll = t + 0.25
    local current = snapshot()
    if current ~= observed then observed, dirtyAt = current, t + 0.8 end
    if dirtyAt and t >= dirtyAt then saveConfig(); dirtyAt = nil end
end

local function entityIndex(entity)
    local value
    pcall(function() value = entity:GetIndex() end)
    value = tonumber(value)
    return value and value > 0 and value or nil
end

local function pawnHandleIndex(value)
    value = tonumber(value)
    if not value or value == 0 or value == -1 then return nil end
    -- Source 2 serialises player_controller_and_pawn as a CHandle.  Aimware's
    -- Entity APIs expect the entry index stored in its low 15 bits. Handles
    -- may arrive as signed 32-bit integers, so negative values are valid here.
    local index = value % 32768
    if index <= 0 or index == 32767 then return nil end
    return index
end

local function fieldInt(entity, name)
    local value
    if not entity then return nil end
    pcall(function() value = entity:GetFieldInt(name) end)
    value = tonumber(value)
    return value
end

local function fieldBool(entity, name)
    local value
    if not entity then return nil end
    pcall(function() value = entity:GetFieldBool(name) end)
    if type(value) == "boolean" then return value end
    if type(value) == "number" then return value ~= 0 end
    return nil
end

local function fieldString(entity, name)
    local value
    if not entity then return nil end
    pcall(function() value = entity:GetFieldString(name) end)
    if type(value) == "string" and value ~= "" then return cleanChatText(value) end
    return nil
end

local function findLocalController()
    local controllers
    pcall(function() controllers = entities.FindByClass("CCSPlayerController") end)
    if type(controllers) ~= "table" then return nil end
    for i = 1, #controllers do
        if fieldBool(controllers[i], "m_bIsLocalPlayerController") == true then
            return controllers[i]
        end
    end
    return nil
end

local function controllerName(controller)
    local value = fieldString(controller, "m_sSanitizedPlayerName")
        or fieldString(controller, "m_iszPlayerName")
    if not value then pcall(function() value = controller:GetName() end) end
    value = cleanChatText(value)
    return value ~= "" and value or "opponent"
end

local function controllerCounter(controller)
    local service
    pcall(function() service = controller:GetFieldEntity("m_pActionTrackingServices") end)
    local kills = fieldInt(service, "m_iKills")
    if kills and kills >= 0 then return kills, "kills" end
    local score = fieldInt(controller, "m_iScore")
    if score and score >= 0 then return score, "score" end
    return nil, nil
end

local function resetKillPoll()
    killPollAt, pollCounter, pollCounterKind = 0, nil, nil
    pollAlive, eventKillCredits = {}, 0
end

local function resetKillsaySession(reason)
    pending = {}
    awaitingChat = nil
    lastDeathSignature, lastDeathAt = nil, -100
    lastSentAt = -100
    resetKillPoll()
    sessionEpoch = sessionEpoch + 1
    status = armed and "session rearmed" or "disabled"
    writeRuntime("session rearmed", {
        reason = reason or "session transition",
        session = lastSessionKey or "unknown",
        epoch = sessionEpoch,
    })
end

local function pollLocalKills(t)
    if t < killPollAt then return end
    killPollAt = t + 0.10

    local controllers
    pcall(function() controllers = entities.FindByClass("CCSPlayerController") end)
    if type(controllers) ~= "table" or #controllers == 0 then return end

    local localIndex
    pcall(function() localIndex = client.GetLocalPlayerIndex() end)
    local localController
    for i = 1, #controllers do
        local controller = controllers[i]
        local isLocal = fieldBool(controller, "m_bIsLocalPlayerController")
        if not isLocal and localIndex then isLocal = entityIndex(controller) == localIndex end
        if isLocal then localController = controller; break end
    end
    if not localController then return end

    local current, kind = controllerCounter(localController)
    local newlyDead = {}
    for i = 1, #controllers do
        local controller = controllers[i]
        if controller ~= localController then
            local index = entityIndex(controller)
            local alive = fieldBool(controller, "m_bPawnIsAlive")
            if index and alive ~= nil then
                if pollAlive[index] == true and alive == false then
                    newlyDead[#newlyDead + 1] = controller
                end
                pollAlive[index] = alive
            end
        end
    end

    if not current then return end
    if pollCounter == nil or pollCounterKind ~= kind or current < pollCounter then
        pollCounter, pollCounterKind = current, kind
        return
    end
    if current <= pollCounter then return end
    pollCounter = current

    local skip = math.min(eventKillCredits, #newlyDead)
    eventKillCredits = math.max(0, eventKillCredits - skip)
    for i = skip + 1, #newlyDead do
        localKills = localKills + 1
        queueForVictim(controllerName(newlyDead[i]))
    end
end

M._killsayDrawCallback = function()
    local t = now()

    local requested = enabled:Get() == true
    if requested ~= armed then
        armed = requested
        pending = {}
        awaitingChat = nil
        lastDeathSignature, lastDeathAt = nil, -100
        resetKillPoll()
        status = armed and "armed" or "disabled"
        if armed then
            -- Refresh immediately when the user enables the module; there is
            -- no need to keep listener/session polling alive while disabled.
            requestKillsayListeners()
            lastSessionKey = currentSessionKey()
            nextListenerRefresh = t + 2.0
            nextSessionPoll = t + 0.50
        end
        writeRuntime(armed and "enabled by checkbox" or "disabled by checkbox")
    end

    if not armed then
        status = "disabled"
        pollKillsayConfig(t)
        return
    end

    -- Aimware can clear game-event listener subscriptions while changing maps
    -- or servers even though the Lua remains loaded. Refreshing AllowListener
    -- is idempotent and much cheaper than polling player state every frame.
    if t >= nextListenerRefresh then
        nextListenerRefresh = t + 2.0
        requestKillsayListeners()
    end
    if t >= nextSessionPoll then
        nextSessionPoll = t + 0.50
        local key = currentSessionKey()
        if lastSessionKey == nil then
            lastSessionKey = key
        elseif key ~= lastSessionKey then
            local previous = lastSessionKey
            lastSessionKey = key
            requestKillsayListeners()
            resetKillsaySession("session changed: " .. previous .. " -> " .. key)
        end
    end

    if awaitingChat and t - awaitingChat.at >= 1.50 then
        chatTimeouts = chatTimeouts + 1
        local oldInterval = delay:Get()
        local newInterval = math.min(1.50, oldInterval + 0.10)
        if newInterval > oldInterval then delay:Set(newInterval) end
        writeRuntime("chat confirmation timeout", {
            message = awaitingChat.text,
            old_interval = oldInterval,
            new_interval = newInterval,
            timeouts = chatTimeouts,
        })
        awaitingChat = nil
    end

    if armed and not awaitingChat and #pending > 0 and t >= pending[1].at and t - lastSentAt >= delay:Get() then
        local item = table.remove(pending, 1)
        local ok, method = sendPublic(item.text)
        if ok then
            lastSentAt, lastVictim, lastMessage, sendMethod, status = t, item.victim or lastVictim, item.text, method, "sent"
            awaitingChat = { text = item.text, at = t }
            print("[rgnKillsay] sent via " .. method .. ": " .. item.text)
        else
            status = "send failed"
            print("[rgnKillsay] send error: " .. tostring(method))
            writeRuntime("queued message send failed", {
                victim = item.victim,
                message = item.text,
                method = method,
                remaining = #pending,
            })
        end
    elseif armed then
        status = #pending > 0 and "waiting" or "ready"
    end

    pollKillsayConfig(t)
end

M._killsayEventCallback = function(event)
    local eventName
    pcall(function() eventName = event:GetName() end)
    if eventName == "player_chat" then
        local text
        pcall(function() text = cleanChatText(event:GetString("text")) end)
        if awaitingChat and text ~= "" and text == cleanChatText(awaitingChat.text) then
            chatConfirmed = chatConfirmed + 1
            awaitingChat = nil
        end
        return
    end
    if eventName == "server_spawn" or eventName == "game_newmap" or eventName == "cs_game_disconnected" then
        requestKillsayListeners()
        resetKillsaySession(eventName)
        return
    end
    if eventName ~= "player_death" then return end
    -- With Killsay disabled, deaths must be a true zero-work path. The stable
    -- build used to open/write its diagnostics file twice for every death in
    -- the server even though no message could be sent.
    if not armed then return end
    callbackEvents = callbackEvents + 1

    -- Current CS2/Aimware exposes player_controller_and_pawn event members
    -- through the *_pawn aliases.  The public reference Killsay uses these
    -- direct pawn indices; treating them as legacy user IDs drops every kill.
    local attackerPawnHandle, victimPawnHandle
    pcall(function() attackerPawnHandle = tonumber(event:GetInt("attacker_pawn")) end)
    pcall(function() victimPawnHandle = tonumber(event:GetInt("userid_pawn")) end)
    local attackerPawnIndex = pawnHandleIndex(attackerPawnHandle)
    local victimPawnIndex = pawnHandleIndex(victimPawnHandle)
    local rawAttacker, rawVictim
    pcall(function() rawAttacker = tonumber(event:GetInt("attacker")) end)
    pcall(function() rawVictim = tonumber(event:GetInt("userid")) end)
    if attackerPawnIndex and attackerPawnIndex > 0 and victimPawnIndex and victimPawnIndex > 0 then
        if attackerPawnIndex == victimPawnIndex then
            return
        end

        local localPawn, attackerPawn, victimPawn
        pcall(function() localPawn = entities.GetLocalPlayer() end)
        pcall(function() attackerPawn = entities.GetByIndex(attackerPawnIndex) end)
        pcall(function() victimPawn = entities.GetByIndex(victimPawnIndex) end)

        local localPawnIndex = entityIndex(localPawn)
        local attackerEntityIndex = entityIndex(attackerPawn)
        local victimEntityIndex = entityIndex(victimPawn)
        local localClientIndex
        pcall(function() localClientIndex = tonumber(client.GetLocalPlayerIndex()) end)

        local isLocal = localPawnIndex and (
            attackerPawnIndex == localPawnIndex or attackerEntityIndex == localPawnIndex
        ) or false
        if not isLocal and localClientIndex and localClientIndex > 0 then
            isLocal = attackerPawnIndex == localClientIndex or attackerEntityIndex == localClientIndex
        end
        if not isLocal then
            local attackerName, localName
            pcall(function() if attackerPawn then attackerName = attackerPawn:GetName() end end)
            pcall(function() if localPawn then localName = localPawn:GetName() end end)
            attackerName, localName = cleanChatText(attackerName):lower(), cleanChatText(localName):lower()
            if attackerName ~= "" and localName ~= "" and attackerName == localName then isLocal = true end
        end
        if not isLocal then
            return
        end
        if localPawnIndex and (victimPawnIndex == localPawnIndex or victimEntityIndex == localPawnIndex) then
            return
        end

        local victimName
        pcall(function() if victimPawn then victimName = victimPawn:GetName() end end)
        victimName = cleanChatText(victimName)
        if victimName == "" then
            pcall(function() victimName = client.GetPlayerNameByIndex(victimPawnIndex) end)
            victimName = cleanChatText(victimName)
        end
        if victimName == "" then victimName = "opponent" end

        local signature, eventTime = "pawn:" .. tostring(attackerPawnIndex) .. ":" .. tostring(victimPawnIndex), now()
        if signature == lastDeathSignature and eventTime - lastDeathAt < 0.10 then return end
        lastDeathSignature, lastDeathAt = signature, eventTime
        deathEvents, localKills = deathEvents + 1, localKills + 1
        queueForVictim(victimName)
        return
    end

    -- Compatibility fallback for older event schemas that still expose IDs.
    local attackerID, victimID = rawAttacker, rawVictim
    if not attackerID or not victimID or attackerID == 0 or attackerID == victimID then return end

    attackerID, victimID = tonumber(attackerID), tonumber(victimID)
    if not attackerID or not victimID then return end
    local signature, eventTime = tostring(attackerID) .. ":" .. tostring(victimID), now()
    if signature == lastDeathSignature and eventTime - lastDeathAt < 0.10 then return end
    lastDeathSignature, lastDeathAt = signature, eventTime
    deathEvents = deathEvents + 1

    local attackerIndex, victimIndex, localIndex
    pcall(function() attackerIndex = client.GetPlayerIndexByUserID(attackerID) end)
    pcall(function() victimIndex = client.GetPlayerIndexByUserID(victimID) end)
    pcall(function() localIndex = client.GetLocalPlayerIndex() end)
    if type(attackerIndex) ~= "number" or attackerIndex <= 0 then attackerIndex = nil end
    if type(victimIndex) ~= "number" or victimIndex <= 0 then victimIndex = nil end
    if type(localIndex) ~= "number" or localIndex <= 0 then localIndex = nil end
    local attackerEntry = pawnHandleIndex(attackerID)
    local victimEntry = pawnHandleIndex(victimID)
    local isLocal = attackerIndex and localIndex and attackerIndex == localIndex or false
    local localPawnIndex
    pcall(function()
        local pawn = entities.GetLocalPlayer()
        if pawn then localPawnIndex = pawn:GetIndex() end
    end)
    if not isLocal and type(attackerIndex) == "number" and type(localPawnIndex) == "number" then
        isLocal = attackerIndex == localPawnIndex
    end
    if not isLocal and type(localIndex) == "number" then
        isLocal = attackerID == localIndex or attackerEntry == localIndex
    end
    if not isLocal and type(localPawnIndex) == "number" then
        isLocal = attackerID == localPawnIndex or attackerEntry == localPawnIndex
    end
    local localController = findLocalController()
    local localControllerIndex = entityIndex(localController)
    if not isLocal and localControllerIndex then
        isLocal = attackerID == localControllerIndex or attackerEntry == localControllerIndex
    end
    if not isLocal and type(localIndex) == "number" then
        local info
        pcall(function() info = client.GetPlayerInfo(localIndex) end)
        local localUserID
        pcall(function() localUserID = tonumber(info.UserID or info.userID or info.userid) end)
        if localUserID and localUserID == attackerID then isLocal = true end
    end
    if not isLocal then
        local attackerName, localName
        pcall(function() attackerName = client.GetPlayerNameByUserID(attackerID) end)
        pcall(function() localName = client.GetPlayerNameByIndex(localIndex) end)
        attackerName, localName = cleanChatText(attackerName):lower(), cleanChatText(localName):lower()
        if attackerName ~= "" and localName ~= "" and attackerName == localName then isLocal = true end
    end
    if not isLocal then
        return
    end
    if victimIndex == localIndex then return end
    eventKillCredits = eventKillCredits + 1
    localKills = localKills + 1
    local legacyVictim = playerName(victimID, victimIndex or victimID % 32768)
    queueForVictim(legacyVictim)
end

requestKillsayListeners()
lastSessionKey = currentSessionKey()

end)
loadModule("IDENTITY", function()
local M = M

-- CS2 no longer exposes a conventional clan-tag setter.  The current,
-- scoreboard-visible equivalent is a prefix composed with the user name.
-- This module follows the working engine2.dll name-ConVar route from the
-- Aimware reference, but validates every signature and pointer before use.
local CONFIG_FILE = "rgnidentity_config.txt"
local RUNTIME_FILE = "rgnidentity_runtime.txt"
local ENGINE_DLL = "engine2.dll"
local CVAR_PATTERN = "48 8B 0D ?? ?? ?? ?? 48 8B 16 48 89 7C 24 ?? 4C 89 4C 24 ??"
local RESOLVE_PATTERN = "48 8B D3 E8 ?? ?? ?? ?? 48 8B 44 24"
local FCVAR_DEVELOPMENTONLY = 0x2
local FCVAR_USERINFO = 0x200
local MIN_WRITE_INTERVAL = 0.30

local function clock()
    local value = 0
    pcall(function()
        if common and type(common.Time) == "function" then value = common.Time()
        elseif globals and type(globals.RealTime) == "function" then value = globals.RealTime()
        elseif globals and type(globals.CurTime) == "function" then value = globals.CurTime() end
    end)
    return tonumber(value) or 0
end

local function clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function clean(value, maximum)
    value = tostring(value or "")
    value = value:gsub("[%c]", " "):gsub('"', ""):gsub(";", ""):gsub("\\", "")
    value = value:gsub("%s+", " "):match("^%s*(.-)%s*$") or ""
    maximum = maximum or 48
    if #value > maximum then value = value:sub(1, maximum) end
    return value
end

local config = {}
pcall(function()
    local handle = file.Open(CONFIG_FILE, "r")
    if not handle then return end
    local raw = handle:Read() or ""
    handle:Close()
    for line in tostring(raw):gmatch("[^\r\n]+") do
        local key, value = line:match("^([%w_]+)=(.*)$")
        if key then config[key] = value end
    end
end)

local function cfgBool(key, default)
    if config[key] == nil then return default end
    return config[key] == "1" or config[key] == "true"
end

local function cfgNumber(key, default, minimum, maximum)
    return clamp(tonumber(config[key]) or default, minimum, maximum)
end

local tab = M:Tab("IDENTITY")
tab:Row()
local nameSection = tab:Section("Custom name")
local nameEnabled = nameSection:Checkbox("Enable custom name", cfgBool("name_enabled", false))
local nameText = nameSection:Input("Name text", config.name_text or "rgnMultitool", "custom player name...")
local nameAnimated = nameSection:Checkbox("Animate custom name", cfgBool("name_animated", false))
local nameSpeed = nameSection:Slider("Name animation speed", cfgNumber("name_speed", 0.60, 0.35, 2.0), 0.35, 2.0, 0.05, "%.2fs")

local clanSection = tab:Section("Clan tag / prefix")
local clanEnabled = clanSection:Checkbox("Enable clan prefix", cfgBool("clan_enabled", false))
local clanText = clanSection:Input("Clan text", config.clan_text or "RGN", "prefix shown before name...")
local clanAnimated = clanSection:Checkbox("Animate clan text", cfgBool("clan_animated", false))
local separatorBar = clanSection:Checkbox("Use middle bar |", cfgBool("separator_bar", true))
local clanSpeed = clanSection:Slider("Clan animation speed", cfgNumber("clan_speed", 0.60, 0.35, 2.0), 0.35, 2.0, 0.05, "%.2fs")

tab:Col()
local actionSection = tab:Section("Actions")
local statusSection = tab:Section("Status")

local f = rawget(_G, "ffi")
local bitlib = rawget(_G, "bit") or rawget(_G, "bit32")
local sharedState = rawget(_G, "RGN_IDENTITY_SHARED_STATE")
if type(sharedState) ~= "table" then
    sharedState = {}
    rawset(_G, "RGN_IDENTITY_SHARED_STATE", sharedState)
end
local flagsPointer, originalFlags = sharedState.flagsPointer, sharedState.originalFlags
local patchReady = flagsPointer ~= nil and originalFlags ~= nil
local patchAttempted = patchReady
local originalName = clean(sharedState.originalName or config.original_name or "", 64)
local storedLastApplied = clean(sharedState.lastApplied or config.last_applied or "", 64)
local lastApplied, lastWriteAt = nil, -100
local changed, captured = false, false
local status = "waiting for a server"
local initAt, nextSessionPoll = clock(), 0
local lastSessionKey = nil
local forceApply = false
local runtimeHistory = {}

local function writeRuntime(reason, values)
    pcall(function()
        local details = {}
        if type(values) == "table" then
            local keys = {}
            for key in pairs(values) do keys[#keys + 1] = tostring(key) end
            table.sort(keys)
            for i = 1, #keys do
                local key = keys[i]
                details[#details + 1] = clean(key, 40) .. ":" .. clean(values[key], 80)
            end
        end
        runtimeHistory[#runtimeHistory + 1] = clean(reason, 80) .. "|" .. table.concat(details, ",")
        if #runtimeHistory > 12 then table.remove(runtimeHistory, 1) end
        local handle = file.Open(RUNTIME_FILE, "w")
        if not handle then return end
        local lines = {
            "reason=" .. clean(reason, 80),
            "status=" .. clean(status, 100),
            "patch_ready=" .. (patchReady and "1" or "0"),
            "captured=" .. (captured and "1" or "0"),
            "changed=" .. (changed and "1" or "0"),
            "original=" .. clean(originalName, 64),
            "last_applied=" .. clean(lastApplied or "", 64),
        }
        for i = 1, #runtimeHistory do lines[#lines + 1] = "history_" .. i .. "=" .. runtimeHistory[i] end
        handle:Write(table.concat(lines, "\n"))
        handle:Close()
    end)
end

local function saveConfig()
    local values = {
        "name_enabled=" .. (nameEnabled:Get() and "1" or "0"),
        "name_text=" .. clean(nameText:Get(), 48),
        "name_animated=" .. (nameAnimated:Get() and "1" or "0"),
        "name_speed=" .. string.format("%.2f", clamp(nameSpeed:Get(), 0.35, 2.0)),
        "clan_enabled=" .. (clanEnabled:Get() and "1" or "0"),
        "clan_text=" .. clean(clanText:Get(), 32),
        "clan_animated=" .. (clanAnimated:Get() and "1" or "0"),
        "separator_bar=" .. (separatorBar:Get() and "1" or "0"),
        "clan_speed=" .. string.format("%.2f", clamp(clanSpeed:Get(), 0.35, 2.0)),
        "original_name=" .. clean(originalName, 64),
        "last_applied=" .. clean(lastApplied or storedLastApplied, 64),
    }
    local ok = false
    pcall(function()
        local handle = file.Open(CONFIG_FILE, "w")
        if not handle then return end
        handle:Write(table.concat(values, "\n"))
        handle:Close()
        ok = true
    end)
    return ok
end

local function sessionKey()
    local server, map, localIndex = "", "", 0
    pcall(function() if engine and type(engine.GetServerIP) == "function" then server = engine.GetServerIP() or "" end end)
    pcall(function() if engine and type(engine.GetMapName) == "function" then map = engine.GetMapName() or "" end end)
    pcall(function() if client and type(client.GetLocalPlayerIndex) == "function" then localIndex = tonumber(client.GetLocalPlayerIndex()) or 0 end end)
    return clean(server, 80) .. "|" .. clean(map, 80) .. "|" .. (localIndex > 0 and "online" or "offline")
end

local function validAddress(value)
    value = tonumber(value)
    return value and value >= 0x10000
end

local function restoreFlags()
    if flagsPointer ~= nil and originalFlags ~= nil then
        pcall(function() flagsPointer[0] = originalFlags end)
    end
    flagsPointer, originalFlags = nil, nil
    sharedState.flagsPointer, sharedState.originalFlags = nil, nil
    patchReady, patchAttempted = false, false
end

local function patchNameConVar()
    if patchReady then return true end
    if patchAttempted then return false end
    patchAttempted = true
    if type(f) ~= "table" or not mem or type(mem.FindPattern) ~= "function" or
       type(bitlib) ~= "table" or type(bitlib.band) ~= "function" or type(bitlib.bor) ~= "function" then
        status = "name engine unavailable: enable insecure FFI"
        writeRuntime("patch prerequisites unavailable")
        return false
    end

    local ok, result = pcall(function()
        pcall(function() f.cdef[[ void* GetModuleHandleA(const char* lpModuleName); ]] end)
        local module = f.C.GetModuleHandleA(ENGINE_DLL)
        local base = tonumber(f.cast("uintptr_t", module))
        if not validAddress(base) then error("engine2.dll is not loaded") end

        local cvarPattern = tonumber(mem.FindPattern(ENGINE_DLL, CVAR_PATTERN))
        local resolvePattern = tonumber(mem.FindPattern(ENGINE_DLL, RESOLVE_PATTERN))
        if not validAddress(cvarPattern) then error("VEngineCvar007 signature not found") end
        if not validAddress(resolvePattern) then error("ResolveConVar signature not found") end

        local cvarRelative = tonumber(f.cast("int32_t*", cvarPattern + 3)[0])
        local resolveRelative = tonumber(f.cast("int32_t*", resolvePattern + 4)[0])
        local cvarGlobal = cvarPattern + cvarRelative + 7
        local resolveAddress = resolvePattern + resolveRelative + 8
        if not validAddress(cvarGlobal) or not validAddress(resolveAddress) then error("invalid resolved signature") end

        local engineAddress = tonumber(f.cast("uintptr_t*", cvarGlobal)[0])
        if not validAddress(engineAddress) then error("invalid VEngineCvar007 object") end
        local engineVtable = tonumber(f.cast("uintptr_t*", engineAddress)[0])
        if not validAddress(engineVtable) then error("invalid VEngineCvar007 vtable") end
        local findAddress = tonumber(f.cast("uintptr_t*", engineVtable)[0xB])
        if not validAddress(findAddress) then error("invalid FindConVar function") end

        local findConVar = f.cast("void* (*)(void*, void*, const char*, int)", findAddress)
        local findOutput = f.new("void*[1]")
        local findName = f.new("char[5]", "name")
        findConVar(f.cast("void*", engineAddress), findOutput, findName, 0)
        if findOutput[0] == nil then error("name ConVar handle not found") end

        local resolveConVar = f.cast("void* (*)(int64_t*, int32_t, int16_t)", resolveAddress)
        local resolveOutput = f.new("int64_t[2]")
        resolveConVar(resolveOutput, f.cast("int32_t", findOutput[0]), 0)
        local convarAddress = tonumber(resolveOutput[1])
        if not validAddress(convarAddress) then error("name ConVar could not be resolved") end

        local pointer = f.cast("uint32_t*", convarAddress + 0x30)
        local current = tonumber(pointer[0])
        if current == nil then error("name ConVar flags unavailable") end
        flagsPointer, originalFlags = pointer, current
        pointer[0] = bitlib.bor(bitlib.band(current, bitlib.bnot(FCVAR_DEVELOPMENTONLY)), FCVAR_USERINFO)
        sharedState.flagsPointer, sharedState.originalFlags = pointer, current
        return true
    end)

    if not ok or not result then
        status = "name engine refused: " .. clean(result, 80)
        restoreFlags()
        patchAttempted = true
        writeRuntime("patch failed", { error = result })
        return false
    end
    patchReady = true
    status = "name engine ready"
    writeRuntime("patch ready")
    return true
end

local function localPlayerName()
    local result = ""
    pcall(function()
        local player = entities and entities.GetLocalPlayer and entities.GetLocalPlayer()
        if player and type(player.GetName) == "function" then result = player:GetName() or "" end
    end)
    return clean(result, 64)
end

local function captureOriginal()
    if captured then return originalName ~= "" end
    local current = localPlayerName()
    if current == "" then return false end
    if storedLastApplied ~= "" and current == storedLastApplied and originalName ~= "" then
        -- A previous hot reload left the composed name active; keep the saved
        -- real name rather than capturing our own prefix as the new baseline.
    else
        originalName = current
    end
    captured = originalName ~= ""
    if captured then
        sharedState.originalName = originalName
        status = "original name captured"
        saveConfig()
        writeRuntime("original captured", { name = originalName })
    end
    return captured
end

local function animatedPart(value, speed, phase)
    value = clean(value, 48)
    if value == "" then return "" end
    local length = #value
    local steps = length * 2
    if steps <= 0 then return value end
    local tick = math.floor((clock() + (phase or 0)) / clamp(speed, 0.35, 2.0)) % steps
    local count = tick <= length and tick or (steps - tick)
    if count <= 0 then return "" end
    return value:sub(1, count)
end

local function composeIdentity()
    local base = originalName
    if nameEnabled:Get() then
        base = clean(nameText:Get(), 48)
        if nameAnimated:Get() then base = animatedPart(base, nameSpeed:Get(), 0) end
    end
    if base == "" then base = originalName ~= "" and originalName or "player" end

    local prefix = ""
    if clanEnabled:Get() then
        prefix = clean(clanText:Get(), 32)
        if clanAnimated:Get() then prefix = animatedPart(prefix, clanSpeed:Get(), 0.17) end
    end
    local composed = base
    if prefix ~= "" then composed = prefix .. (separatorBar:Get() and " | " or " ") .. base end
    composed = clean(composed, 63)
    if composed == "" then composed = "player" end
    return composed
end

local function writeName(value, forced)
    value = clean(value, 63)
    if value == "" then return false, "empty name refused" end
    local t = clock()
    if not forced and (value == lastApplied or t - lastWriteAt < MIN_WRITE_INTERVAL) then
        return value == lastApplied, value == lastApplied and "unchanged" or "throttled"
    end
    if not patchNameConVar() then return false, status end
    local ok, err = pcall(function()
        client.Command('name "' .. value .. '"', true)
        client.Command('setinfo name "' .. value .. '"', true)
    end)
    if not ok then
        status = "name command failed: " .. clean(err, 70)
        writeRuntime("command failed", { error = err })
        return false, status
    end
    lastApplied, storedLastApplied, lastWriteAt = value, value, t
    sharedState.lastApplied = value
    changed = originalName ~= "" and value ~= originalName
    status = changed and "identity active" or "original name restored"
    return true, status
end

local function restoreOriginal(forced)
    if not captureOriginal() then return false, "original name unavailable" end
    local ok, message = writeName(originalName, forced ~= false)
    if ok then
        changed = false
        nameEnabled:Set(false)
        clanEnabled:Set(false)
        status = "original name restored"
        saveConfig()
        writeRuntime("original restored")
    end
    return ok, message
end

actionSection:Button("Apply identity now", function()
    if not captureOriginal() then M:Notify("join a server before applying identity", "error"); return end
    forceApply = true
    saveConfig()
    M:Notify("identity queued safely", "success")
end)
actionSection:Button("Save identity settings", function()
    local ok = saveConfig()
    M:Notify(ok and "identity settings saved" or "identity settings could not be saved", ok and "success" or "error")
end)
actionSection:Button("Restore original name", function()
    local ok, message = restoreOriginal(true)
    M:Notify(ok and "original name restored" or message, ok and "success" or "error")
end)
statusSection:Button("Show identity status", function()
    M:Notify(status .. " | prefix=" .. (clanEnabled:Get() and "on" or "off") .. " name=" .. (nameEnabled:Get() and "on" or "off"), "info")
end)
statusSection:Button("Show composed name", function()
    M:Notify("current target: " .. composeIdentity(), "info")
end)

M._identityHandles = {
    nameEnabled = nameEnabled, clanEnabled = clanEnabled,
    nameAnimated = nameAnimated, clanAnimated = clanAnimated,
}
M._identityComposeForTest = composeIdentity

local generation = (tonumber(rawget(_G, "RGN_IDENTITY_GENERATION")) or 0) + 1
rawset(_G, "RGN_IDENTITY_GENERATION", generation)

local function identityDraw()
    if rawget(_G, "RGN_IDENTITY_GENERATION") ~= generation then return end
    local wantsIdentity = nameEnabled:Get() or clanEnabled:Get()
    -- The stable callback kept polling the server/map clock while identity was
    -- completely idle. If we do not own a changed name there is nothing to
    -- restore, so return before clock/session/API work.
    if not wantsIdentity and not changed then return end
    local t = clock()
    if not wantsIdentity then
        if captured and t - lastWriteAt >= MIN_WRITE_INTERVAL then restoreOriginal(false) end
        return
    end
    if t >= nextSessionPoll then
        nextSessionPoll = t + 0.75
        local key = sessionKey()
        if lastSessionKey == nil then lastSessionKey = key end
        if key ~= lastSessionKey then
            lastSessionKey = key
            captured, lastApplied, changed = false, nil, false
            initAt, forceApply = t, false
            status = "session changed; waiting for player"
            writeRuntime("session changed", { session = key })
        end
    end

    if t - initAt < 1.0 then return end
    if not captureOriginal() then status = "waiting for local player"; return end

    local target = composeIdentity()
    if forceApply or target ~= lastApplied then
        local ok = writeName(target, forceApply)
        if ok then
            forceApply = false
        elseif patchAttempted and not patchReady then
            -- Do not retry a broken signature every frame.  A server/map
            -- transition or a fresh Lua Run will perform one new safe probe.
            forceApply = false
        end
    end
end
M._identityDrawCallback = identityDraw
callbacks.Register("Draw", identityDraw)

callbacks.Register("Unload", function()
    if rawget(_G, "RGN_IDENTITY_GENERATION") ~= generation then return end
    pcall(saveConfig)
    if changed and originalName ~= "" then pcall(function() writeName(originalName, true) end) end
    restoreFlags()
    rawset(_G, "RGN_IDENTITY_GENERATION", generation + 1)
end)

writeRuntime("module loaded")
end)

loadModule("VOTES", function()
-- rgnMultitool vote revealer.
-- Uses documented game events and ordinary entity APIs. The only FFI call is
-- the current local HUD-chat printer; Steam avatar vtables remain excluded.
-- The service is always enabled and intentionally has no tab. Event/session
-- work runs outside Draw; Draw only renders the overlay behind a hard
-- re-entry guard so a Panorama/chat refresh cannot recursively exhaust CS2's
-- stack.
local PLAY_SOUND, DISPLAY_DURATION = true, 15

local active, order, chatQueue = {}, {}, {}
-- These numbers are not interchangeable in Source 2. vote_cast.userid is a
-- zero-based controller slot, player events expose UserIDs and entity APIs use
-- one-based entity indices. Keeping them in one table made slot 1 inherit the
-- name cached for controller index 1 (slot 0), then cascaded that name through
-- the rest of an enemy vote.
local namesByUserID, namesByIndex, voteSlotNames = {}, {}, {}
local teamsByUserID, teamsByIndex, voteSlotTeams = {}, {}, {}
local preStartVotes, firstNoName = {}, ""
local recentDisconnect = { at = -1000, team = nil, name = "" }
local currentVoteTeam, currentVoteLabel = nil, ""
local pendingVoteHint = { at = -1000, team = nil, label = "", issue = nil, parameter = nil }
local armed, lastVote, endAt, voteOpen = true, 0, 0, false
local eventCount, status = 0, "ready"
local callbackEvents = 0
local nextListenerRefresh, nextSessionPoll, nextLogicTick = 0, 0, 0
local lastSessionKey
local RUNTIME_FILE = "rgnvotes_runtime.txt"
local runtimeHistory = {}
local localChatPrint, localChatStatus
local localPrintCount = 0

local function clock()
    local value = 0
    pcall(function()
        if common and type(common.Time) == "function" then value = common.Time()
        elseif globals and type(globals.RealTime) == "function" then value = globals.RealTime()
        elseif globals and type(globals.CurTime) == "function" then value = globals.CurTime() end
    end)
    return tonumber(value) or 0
end

local function clean(value)
    value = tostring(value or "")
    value = value:gsub("[%c]", " "):gsub('"', ""):gsub(";", ""):gsub("\\", "")
    value = value:gsub("%s+", " "):match("^%s*(.-)%s*$") or ""
    if #value > 80 then value = value:sub(1, 80) end
    return value
end

local function writeRuntime(reason, values)
    pcall(function()
        local details = {}
        if type(values) == "table" then
            local keys = {}
            for key in pairs(values) do keys[#keys + 1] = tostring(key) end
            table.sort(keys)
            for i = 1, #keys do
                local key = keys[i]
                details[#details + 1] = clean(key) .. ":" .. clean(values[key])
            end
        end
        runtimeHistory[#runtimeHistory + 1] = clean(reason) .. "|" .. table.concat(details, ",")
        if #runtimeHistory > 20 then table.remove(runtimeHistory, 1) end
        local handle = file.Open(RUNTIME_FILE, "w")
        if not handle then return end
        local lines = {
            "reason=" .. clean(reason),
            "enabled=1",
            "armed=1",
            "events=" .. tostring(eventCount),
            "callback_events=" .. tostring(callbackEvents),
            "visible=" .. tostring(#order),
            "queued=" .. tostring(#chatQueue),
            "local_chat=" .. clean(localChatStatus or "not initialized"),
        }
        if type(values) == "table" then
            for key, value in pairs(values) do lines[#lines + 1] = clean(key) .. "=" .. clean(value) end
        end
        for i = 1, #runtimeHistory do lines[#lines + 1] = "history_" .. i .. "=" .. runtimeHistory[i] end
        handle:Write(table.concat(lines, "\n"))
        handle:Close()
    end)
end

local function initLocalChat()
    localChatPrint, localChatStatus = nil, "unavailable"
    local f = rawget(_G, "ffi")
    if type(f) ~= "table" or not mem or type(mem.FindPattern) ~= "function" then
        localChatStatus = "ffi or mem unavailable"
        return false
    end
    local ok, address = pcall(mem.FindPattern, "client.dll",
        "4C 89 4C 24 20 53 56 B8 38 10 00 00 E8 ?? ?? ?? ?? 48 2B E0 48 8B 0D ?? ?? ?? ?? 41 8B D8 48 8B F2")
    address = tonumber(address)
    if not ok or not address or address < 0x10000 then
        localChatStatus = "chat signature not found"
        return false
    end
    local castOK, fn, flags = pcall(function()
        return f.cast("void(*)(void*, void*, uint32_t, const char*, const char*)", f.cast("void*", address)),
            f.new("int[1]", 0x0100)
    end)
    if not castOK or not fn then
        localChatStatus = "chat signature cast failed"
        return false
    end
    localChatPrint = function(text)
        return pcall(function() fn(nil, flags, 0, "%s", tostring(text)) end)
    end
    localChatStatus = string.format("ready@%X", address)
    return true
end

local function requestListeners()
    pcall(function()
        if not client or type(client.AllowListener) ~= "function" then return end
        for _, name in ipairs({
            "vote_started", "vote_begin", "start_vote", "vote_cast", "vote_changed", "vote_options",
            "vote_ended", "vote_failed", "vote_passed", "player_connect",
            "player_info", "player_team", "player_disconnect", "server_spawn",
            "game_newmap", "cs_game_disconnected"
        }) do
            client.AllowListener(name)
        end
    end)
end

local function sessionKey()
    local server, map, localIndex = "", "", 0
    pcall(function() if engine and type(engine.GetServerIP) == "function" then server = engine.GetServerIP() or "" end end)
    pcall(function() if engine and type(engine.GetMapName) == "function" then map = engine.GetMapName() or "" end end)
    pcall(function() if client and type(client.GetLocalPlayerIndex) == "function" then localIndex = tonumber(client.GetLocalPlayerIndex()) or 0 end end)
    return clean(server) .. "|" .. clean(map) .. "|" .. (localIndex > 0 and "online" or "offline")
end

local function clearVote(reason, preserveChat)
    active, order = {}, {}
    if not preserveChat then chatQueue = {} end
    preStartVotes, firstNoName = {}, ""
    currentVoteTeam, currentVoteLabel = nil, ""
    lastVote, endAt, voteOpen = 0, 0, false
    status = reason or "ready"
end

local function eventInt(event, field)
    local value
    pcall(function() value = tonumber(event:GetInt(field)) end)
    return value
end

local function eventString(event, field)
    local value
    pcall(function() value = event:GetString(field) end)
    return clean(value)
end

local function eventBool(event, field)
    local value
    pcall(function() value = event:GetBool(field) end)
    if type(value) == "boolean" then return value end
    return (eventInt(event, field) or 0) ~= 0
end

local function entityIndex(entity)
    local value
    if not entity then return nil end
    pcall(function() value = tonumber(entity:GetIndex()) end)
    return value and value > 0 and value or nil
end

local function controllerFor(raw)
    raw = tonumber(raw)
    if not raw then return nil, nil end

    -- Aimware's original CS2 Vote Reveal defines vote_cast.userid as a
    -- zero-based player slot: CCSPlayerController:GetIndex() - 1 == userid.
    -- Mapping raw directly to a controller shifts every name by one player.
    local controllerIndex = (raw % 32768) + 1
    local controllers
    pcall(function() controllers = entities.FindByClass("CCSPlayerController") end)
    if type(controllers) == "table" then
        for i = 1, #controllers do
            local candidate = entityIndex(controllers[i])
            if candidate == controllerIndex then
                return controllers[i], candidate
            end
        end
    end
    return nil, controllerIndex
end

local function playerNameByIndex(index)
    index = tonumber(index)
    if not index or index <= 0 then return "" end
    local name = ""
    pcall(function()
        if client and type(client.GetPlayerNameByIndex) == "function" then
            name = client.GetPlayerNameByIndex(index)
        end
    end)
    name = clean(name)
    if name == "CCSPlayerController" then return "" end
    return name
end

local function playerNameByUserID(userID)
    userID = tonumber(userID)
    if not userID or userID <= 0 then return "" end
    local name = ""
    pcall(function()
        if client and type(client.GetPlayerNameByUserID) == "function" then
            name = client.GetPlayerNameByUserID(userID)
        end
    end)
    name = clean(name)
    if name == "CCSPlayerController" then return "" end
    return name
end

local function pawnForController(controller)
    if not controller then return nil, nil end

    -- Current vote events provide a CCSPlayerController slot, while Aimware's
    -- stable name path operates on the associated player pawn.
    local pawn
    pcall(function() pawn = controller:GetPropEntity("m_hPlayerPawn") end)
    if not pawn then pcall(function() pawn = controller:GetPropEntity("m_hPawn") end) end
    if not pawn then pcall(function() pawn = controller:GetFieldEntity("m_hPlayerPawn") end) end
    if not pawn then pcall(function() pawn = controller:GetFieldEntity("m_hPawn") end) end
    local pawnIndex = entityIndex(pawn)
    if pawn and pawnIndex then return pawn, pawnIndex end

    -- Compatibility path for builds that expose the CHandle only as an int.
    local handle
    pcall(function() handle = tonumber(controller:GetPropInt("m_hPlayerPawn")) end)
    if not handle or handle == 0 or handle == -1 then pcall(function() handle = tonumber(controller:GetPropInt("m_hPawn")) end) end
    if not handle or handle == 0 or handle == -1 then pcall(function() handle = tonumber(controller:GetFieldInt("m_hPlayerPawn")) end) end
    if not handle or handle == 0 or handle == -1 then pcall(function() handle = tonumber(controller:GetFieldInt("m_hPawn")) end) end
    if handle and handle ~= 0 and handle ~= -1 then
        pawnIndex = handle % 32768
        if pawnIndex > 0 and pawnIndex ~= 32767 then
            pcall(function() pawn = entities.GetByIndex(pawnIndex) end)
            if pawn then return pawn, pawnIndex end
        end
    end
    return nil, nil
end

local function pawnByControllerIndex(controllerIndex)
    controllerIndex = tonumber(controllerIndex)
    if not controllerIndex or controllerIndex <= 0 then return nil, nil end
    controllerIndex = controllerIndex % 32768

    -- Enemy controllers can expose a dormant/empty pawn handle. In that case
    -- enumerate the small player-pawn list and resolve the relationship in the
    -- opposite direction through CBasePlayerPawn.m_hController.
    local pawns
    pcall(function() pawns = entities.FindByClass("C_CSPlayerPawn") end)
    if type(pawns) ~= "table" then return nil, nil end
    for i = 1, #pawns do
        local pawn = pawns[i]
        local controller
        pcall(function() controller = pawn:GetPropEntity("m_hController") end)
        if not controller then pcall(function() controller = pawn:GetFieldEntity("m_hController") end) end
        local linkedIndex = entityIndex(controller)
        if not linkedIndex then
            local handle
            pcall(function() handle = tonumber(pawn:GetPropInt("m_hController")) end)
            if not handle or handle == 0 or handle == -1 then pcall(function() handle = tonumber(pawn:GetFieldInt("m_hController")) end) end
            if handle and handle ~= 0 and handle ~= -1 then linkedIndex = handle % 32768 end
        end
        if linkedIndex == controllerIndex then return pawn, entityIndex(pawn) end
    end
    return nil, nil
end

local function entityPlayerName(entity)
    if not entity then return "" end
    local name = ""
    pcall(function() name = entity:GetName() end)
    name = clean(name)
    if name == "CCSPlayerController" or name == "CCSPlayerPawn"
        or name == "C_CSPlayerPawn" or name == "C_CSPlayerPawnBase" then
        return ""
    end
    return name
end

local function controllerFieldName(entity)
    if not entity then return "" end
    local value = ""
    for _, field in ipairs({ "m_sSanitizedPlayerName", "m_iszPlayerName" }) do
        pcall(function() value = entity:GetFieldString(field) end)
        value = clean(value)
        if value ~= "" and value ~= "CCSPlayerController" then return value end
        pcall(function() value = entity:GetPropString(field) end)
        value = clean(value)
        if value ~= "" and value ~= "CCSPlayerController" then return value end
    end
    return ""
end

local function entityInt(entity, field)
    local value
    if not entity then return nil end
    pcall(function() value = tonumber(entity:GetPropInt(field)) end)
    if value == nil then pcall(function() value = tonumber(entity:GetFieldInt(field)) end) end
    return value
end

local function voteIssueIndexLabel(issue, team)
    issue = tonumber(issue)
    team = tonumber(team)
    if issue == nil then return nil end
    if team == 2 or team == 3 then
        if issue == 0 then return "KICK PLAYER" end
        if issue == 1 then return "TIMEOUT" end
        if issue == 2 then return "SURRENDER" end
        return nil
    end
    if issue == 0 then return "KICK PLAYER" end
    if issue == 1 then return "CHANGE MAP" end
    if issue == 3 then return "SCRAMBLE TEAMS" end
    if issue == 4 then return "SWAP TEAMS" end
    return nil
end

local function controllerVoteLabel(team)
    if not entities or type(entities.FindByClass) ~= "function" then return nil, nil end
    local seen, candidates = {}, {}
    for _, className in ipairs({ "CVoteController", "C_VoteController" }) do
        local list
        pcall(function() list = entities.FindByClass(className) end)
        if type(list) == "table" then
            for i = 1, #list do
                local entity = list[i]
                local index = entityIndex(entity) or tostring(entity)
                if not seen[index] then
                    seen[index] = true
                    candidates[#candidates + 1] = entity
                end
            end
        end
    end
    local fallbackIssue, fallbackTeam
    for i = 1, #candidates do
        local entity = candidates[i]
        local issue = entityInt(entity, "m_iActiveIssueIndex")
        local onlyTeam = entityInt(entity, "m_iOnlyTeamToVote")
        if issue ~= nil and (onlyTeam == team or (team == nil and (onlyTeam == 2 or onlyTeam == 3))) then
            return voteIssueIndexLabel(issue, onlyTeam or team), issue
        end
        if issue ~= nil and fallbackIssue == nil then
            fallbackIssue, fallbackTeam = issue, onlyTeam
        end
    end
    if team == nil and fallbackIssue ~= nil then
        return voteIssueIndexLabel(fallbackIssue, fallbackTeam), fallbackIssue
    end
    return nil, fallbackIssue
end

local function activeTimeoutLabel(team)
    if not entities or type(entities.FindByClass) ~= "function" then return nil end
    local flag = team == 2 and "m_bTerroristTimeOutActive"
        or (team == 3 and "m_bCTTimeOutActive" or nil)
    if not flag then return nil end
    for _, className in ipairs({ "CCSGameRulesProxy", "C_CSGameRulesProxy" }) do
        local proxies
        pcall(function() proxies = entities.FindByClass(className) end)
        if type(proxies) == "table" then
            for i = 1, #proxies do
                local proxy, rules = proxies[i], nil
                pcall(function() rules = proxy:GetFieldEntity("m_pGameRules") end)
                if not rules then pcall(function() rules = proxy:GetPropEntity("m_pGameRules") end) end
                if entityInt(rules or proxy, flag) == 1 or entityInt(proxy, flag) == 1 then
                    return "TIMEOUT"
                end
            end
        end
    end
    return nil
end

local function hintedVoteLabel(team)
    local age = clock() - (tonumber(pendingVoteHint.at) or -1000)
    if age < 0 or age > 3.0 then return nil end
    if pendingVoteHint.team == nil or team == nil or pendingVoteHint.team == team then
        return pendingVoteHint.label ~= "" and pendingVoteHint.label or nil
    end
    return nil
end

local function bestVoteLabel(team)
    local label, issue = controllerVoteLabel(team)
    if label then return label, issue, "controller" end
    label = hintedVoteLabel(team)
    if label then return label, pendingVoteHint.issue, "start_vote" end
    label = activeTimeoutLabel(team)
    if label then return label, issue, "game_rules" end
    return nil, issue, "none"
end

local function replaceQueuedVoteLabel(label)
    if not label or label == "" then return end
    for i = 1, #chatQueue do
        local entry = chatQueue[i]
        if type(entry) == "table" and type(entry.text) == "string" then
            entry.text = entry.text:gsub("TEAM VOTE %(UNKNOWN TYPE%)", label)
                :gsub("UNKNOWN VOTE", label)
        end
    end
end

local function voterInfo(raw, eventTeam)
    raw = tonumber(raw) or 0
    local entity, index = controllerFor(raw)
    local pawn, pawnIndex = pawnForController(entity)
    if not pawn then pawn, pawnIndex = pawnByControllerIndex(index or raw) end
    -- Networked controller string fields currently return invalid bytes on
    -- some CS2 builds. Use the same pawn-name route that Killsay uses and never
    -- display raw controller strings in chat or the overlay.
    local name = pawn and entityPlayerName(pawn) or ""
    if name == "" and pawnIndex then
        name = playerNameByIndex(pawnIndex)
    end
    if name == "" and index then
        name = playerNameByIndex(index)
    end
    if name == "" and entity then
        name = entityPlayerName(entity)
    end
    if name == "" and entity then name = controllerFieldName(entity) end
    if name == "" then name = clean(voteSlotNames[raw] or "") end
    if name == "" and index then name = clean(namesByIndex[index] or "") end
    if name == "" and pawnIndex then name = clean(namesByIndex[pawnIndex] or "") end
    -- Only interpret raw as a legacy UserID when no controller entity matched;
    -- otherwise the same small number can name a completely different player.
    if name == "" and not entity then
        name = clean(namesByUserID[raw] or "")
        if name == "" then name = playerNameByUserID(raw) end
    end
    if name == "" then
        name = "player #" .. tostring(raw)
    else
        -- Do not cache the numeric fallback: a player API can become available
        -- a few frames later while the same vote is still in progress.
        voteSlotNames[raw] = name
        if index then namesByIndex[index] = name end
        if pawnIndex then namesByIndex[pawnIndex] = name end
    end

    -- The vote event's team is authoritative. Entity lookup is only a
    -- fallback when the server omitted it; it must never override a valid 2/3.
    local team = tonumber(eventTeam)
    if team ~= 2 and team ~= 3 and entity then
        local value = entityInt(entity, "m_iTeamNum")
        if value == 2 or value == 3 then team = value end
    end
    if team ~= 2 and team ~= 3 and pawn then
        local value = entityInt(pawn, "m_iTeamNum")
        if value == 2 or value == 3 then team = value end
    end
    if team ~= 2 and team ~= 3 then
        team = voteSlotTeams[raw] or (index and teamsByIndex[index])
            or (pawnIndex and teamsByIndex[pawnIndex])
    end
    if team ~= 2 and team ~= 3 and not entity then
        team = teamsByUserID[raw]
    end
    if team == 2 or team == 3 then
        voteSlotTeams[raw] = team
        if index then teamsByIndex[index] = team end
        if pawnIndex then teamsByIndex[pawnIndex] = team end
    end
    local teamName = team == 2 and "T" or (team == 3 and "CT" or "SPEC")
    return name, teamName, team
end

local function voteTargetName(event)
    local text = eventString(event, "param1")
    if text == "" then text = eventString(event, "details_str") end

    local targetID = eventInt(event, "target")
    if not targetID or targetID <= 0 then targetID = eventInt(event, "targetid") end
    if not targetID or targetID <= 0 then targetID = tonumber(text) end
    if targetID and targetID > 0 then
        local resolved = voterInfo(targetID)
        if resolved and not resolved:match("^player #%d+$") then return resolved end
    end
    return text
end

local function queueChat(teamName, message)
    message = clean(message)
    if message ~= "" then
        chatQueue[#chatQueue + 1] = { team = teamName, text = message }
    end
    if #chatQueue > 24 then table.remove(chatQueue, 1) end
end

local function upsertVote(key, name, teamName, option)
    key = tostring(key or (#order + 1))
    if not active[key] then order[#order + 1] = key end
    active[key] = {
        name = name,
        team = teamName,
        option = option,
        alpha = active[key] and active[key].alpha or 0,
        slide = active[key] and active[key].slide or 80,
    }
end

local function voteLabel(issue)
    local lower = clean(issue):lower()
    if lower:find("timeout", 1, true) or lower:find("pause", 1, true) then return "TIMEOUT" end
    if lower:find("kick", 1, true) then return "KICK PLAYER" end
    if lower:find("surrender", 1, true) then return "SURRENDER" end
    if lower:find("restart", 1, true) then return "RESTART MATCH" end
    if lower:find("rematch", 1, true) then return "REMATCH" end
    if lower:find("changelevel", 1, true) or lower:find("changemap", 1, true) then return "CHANGE MAP" end
    if lower:find("swap", 1, true) then return "SWAP TEAMS" end
    if lower ~= "" then return lower:gsub("#", ""):gsub("_", " "):upper() end
    return "UNKNOWN VOTE"
end

M._voteEventCallback = function(event)
    local name
    pcall(function() name = event:GetName() end)
    callbackEvents = callbackEvents + 1

    if name == "server_spawn" or name == "game_newmap" or name == "cs_game_disconnected" then
        requestListeners()
        -- A passed change-map vote can emit game_newmap before Draw gets a
        -- chance to print. Keep those already-resolved local chat messages.
        clearVote("session rearmed", true)
        namesByUserID, namesByIndex, voteSlotNames = {}, {}, {}
        teamsByUserID, teamsByIndex, voteSlotTeams = {}, {}, {}
        recentDisconnect = { at = -1000, team = nil, name = "" }
        pendingVoteHint = { at = -1000, team = nil, label = "", issue = nil, parameter = nil }
        writeRuntime("session event", { event = name, callbacks = callbackEvents, preserved = #chatQueue })
        return
    end
    if name == "player_connect" or name == "player_info" then
        local user = eventInt(event, "userid")
        local entityID = eventInt(event, "entityid")
        local playerName = eventString(event, "name")
        if user and playerName ~= "" then namesByUserID[user] = playerName end
        if entityID and playerName ~= "" then
            namesByIndex[entityID] = playerName
            if entityID > 0 then voteSlotNames[entityID - 1] = playerName end
        end
        return
    end
    if name == "player_team" or name == "player_disconnect" then
        local raw = eventInt(event, "userid")
        if not raw or raw <= 0 then raw = eventInt(event, "entityid") end
        local eventTeam = eventInt(event, "team")
        local oldTeam = eventInt(event, "oldteam")
        local disconnected = name == "player_disconnect" or eventBool(event, "disconnect")
        if raw and raw > 0 then
            -- CS2's player_team schema has no string field named "name".
            -- Aimware's GameEvent wrapper forwards a null default to strlen
            -- when that missing field is queried, which crashes exactly at the
            -- halftime TT/CT swap. player_disconnect does define the field;
            -- team changes must resolve identity from our slot/UserID cache.
            local playerName = ""
            if name == "player_disconnect" then playerName = eventString(event, "name") end
            if playerName == "" then playerName = clean(namesByUserID[raw] or "") end
            if playerName == "" then playerName = playerNameByUserID(raw) end
            local resolvedTeam = eventTeam
            if resolvedTeam ~= 2 and resolvedTeam ~= 3 then resolvedTeam = teamsByUserID[raw] end
            if playerName == "" then playerName = "player #" .. tostring(raw) end
            local team = (oldTeam == 2 or oldTeam == 3) and oldTeam or resolvedTeam
            if not disconnected and (eventTeam == 2 or eventTeam == 3) then teamsByUserID[raw] = eventTeam end
            if disconnected then
                recentDisconnect = { at = clock(), team = team, name = playerName }
                writeRuntime("player disconnected", { raw = raw, name = playerName, team = team })
            end
        end
        return
    end
    if not armed then return end

    if name == "start_vote" then
        local raw = eventInt(event, "userid") or 0
        local _, _, team = voterInfo(raw, eventInt(event, "team"))
        local issue = eventInt(event, "type")
        local parameter = eventInt(event, "vote_parameter")
        local label = voteIssueIndexLabel(issue, team)
        pendingVoteHint = {
            at = clock(), team = team, label = label or "", issue = issue, parameter = parameter,
        }
        writeRuntime("start vote hint", {
            raw = raw, team = team, issue = issue, parameter = parameter, label = label or "unknown",
        })
        return
    end

    if name == "vote_started" or name == "vote_begin" then
        active, order, preStartVotes, firstNoName = {}, {}, {}, ""
        lastVote, endAt, voteOpen = clock(), 0, true
        local initiator = eventInt(event, "initiator")
        if not initiator or initiator <= 0 then initiator = eventInt(event, "entityid") end
        if not initiator or initiator <= 0 then initiator = eventInt(event, "userid") end
        initiator = initiator or 0
        local initiatorName, teamName, team = voterInfo(initiator, eventInt(event, "team"))
        local issue = eventString(event, "issue")
        local label = voteLabel(issue)
        local source, issueIndex
        if label == "UNKNOWN VOTE" then
            local detected
            detected, issueIndex, source = bestVoteLabel(team)
            if detected then label = detected end
        end
        currentVoteTeam, currentVoteLabel = team, label
        local target = voteTargetName(event)
        status = initiatorName .. " started " .. label
        queueChat(teamName, string.format("%s started vote: %s%s", initiatorName, label,
            target ~= "" and (" | target: " .. target) or ""))
        eventCount = eventCount + 1
        writeRuntime("vote started", {
            initiator = initiator, name = initiatorName, team = teamName,
            issue = issue, issue_index = issueIndex, source = source,
            label = label, target = target, callbacks = callbackEvents,
        })
        return
    end

    if name == "vote_options" then
        writeRuntime("vote options", { count = eventInt(event, "count"), callbacks = callbackEvents })
        return
    end
    if name == "vote_changed" then
        writeRuntime("vote counts changed", {
            yes = eventInt(event, "vote_option1"), no = eventInt(event, "vote_option2"),
            potential = eventInt(event, "potentialVotes"), callbacks = callbackEvents,
        })
        return
    end

    if name == "vote_ended" or name == "vote_failed" or name == "vote_passed" then
        endAt = clock() + DISPLAY_DURATION
        status = name:gsub("_", " ")
        local result = name == "vote_passed" and "PASSED" or (name == "vote_failed" and "FAILED" or "ENDED")
        local resultTeam = currentVoteTeam == 2 and "T" or (currentVoteTeam == 3 and "CT" or nil)
        queueChat(resultTeam, "Vote " .. result .. (currentVoteLabel ~= "" and (": " .. currentVoteLabel) or ""))
        writeRuntime("vote result", { event = name, result = result })
        return
    end
    if name ~= "vote_cast" then return end

    local raw = eventInt(event, "userid")
    if not raw or raw <= 0 then raw = eventInt(event, "entityid") end
    if not raw then return end
    local option = eventInt(event, "vote_option")
    if option == nil then option = eventInt(event, "vote") end
    if option == nil then return end

    local voter, teamName, team = voterInfo(raw, eventInt(event, "team"))
    local choice = option == 0 and "YES (F1)" or (option == 1 and "NO (F2)" or ("OPTION " .. tostring(option + 1)))
    local detectedLabel, detectedIssue, detectedSource = bestVoteLabel(team)
    if detectedLabel and (currentVoteLabel == "" or currentVoteLabel:find("UNKNOWN", 1, true)) then
        currentVoteLabel = detectedLabel
        replaceQueuedVoteLabel(detectedLabel)
    end
    if not voteOpen and option == 1 then
        -- CS2 often sends the kick target's automatic F2 before the caller's
        -- F1 and omits vote_started. Preserve it until the initiator arrives.
        firstNoName = firstNoName ~= "" and firstNoName or voter
        preStartVotes[#preStartVotes + 1] = { raw = raw, team = teamName, name = voter, choice = choice }
        upsertVote(raw, voter, teamName, option)
        lastVote, endAt = clock(), 0
        eventCount = eventCount + 1
        writeRuntime("vote cast buffered before initiator", {
            raw = raw, name = voter, team = teamName, option = option, buffered = #preStartVotes,
        })
        if PLAY_SOUND then pcall(function() client.Command("play buttons\\button14.wav", true) end) end
        return
    end
    if not voteOpen then
        voteOpen = true
        -- Resolve the buffered automatic F2 again now that the player list has
        -- had another event frame to settle. This player is the kick target.
        if #preStartVotes > 0 and preStartVotes[1].raw then
            local refreshedTarget = voterInfo(preStartVotes[1].raw)
            if refreshedTarget and not refreshedTarget:match("^player #%d+$") then
                preStartVotes[1].name = refreshedTarget
                firstNoName = refreshedTarget
            end
        end
        local label
        if firstNoName ~= "" then
            label = "KICK PLAYER"
        else
            label = detectedLabel or "TEAM VOTE (UNKNOWN TYPE)"
        end
        currentVoteTeam, currentVoteLabel = team, label
        queueChat(teamName, string.format("%s started vote: %s%s", voter, label,
            firstNoName ~= "" and (" | target: " .. firstNoName) or ""))
        for i = 1, #preStartVotes do
            local early = preStartVotes[i]
            queueChat(early.team, string.format("%s voted %s", early.name, early.choice))
        end
        preStartVotes = {}
    end
    upsertVote(raw, voter, teamName, option)
    lastVote, endAt = clock(), 0
    eventCount = eventCount + 1
    status = voter .. " voted " .. choice
    queueChat(teamName, string.format("%s voted %s%s", voter, choice,
        currentVoteLabel ~= "" and (" | " .. currentVoteLabel) or ""))
    writeRuntime("vote cast", {
        raw = raw, name = voter, team = teamName, option = option, choice = choice,
        issue = detectedIssue, source = detectedSource, label = currentVoteLabel,
    })
    if PLAY_SOUND then pcall(function() client.Command("play buttons\\button14.wav", true) end) end
end

local function sendQueued(t)
    if #chatQueue == 0 then return end
    local count = 0
    while #chatQueue > 0 and count < 8 do
        local entry = table.remove(chatQueue, 1)
        if type(entry) ~= "table" then entry = { text = tostring(entry or "") } end
        local message, teamName = clean(entry.text), entry.team
        local plainMarker = teamName == "T" and "(T) " or (teamName == "CT" and "(CT) " or "")
        local prefixColor, reset = string.char(14), string.char(1)
        -- Explicit HUD colors: red for Terrorists and blue for Counter-Terrorists.
        -- Reset immediately after the marker so the vote description stays readable.
        local teamColor = teamName == "T" and string.char(2) or (teamName == "CT" and string.char(11) or reset)
        local colorMarker = teamName == "T" and "(T)" or (teamName == "CT" and "(CT)" or "")
        local formatted = prefixColor .. "[rgnVotes] " .. reset
        if colorMarker ~= "" then formatted = formatted .. teamColor .. colorMarker .. reset .. " " end
        formatted = formatted .. message
        M._voteLastFormattedChat = formatted
        M._voteLastPlainChat = plainMarker .. message
        M._voteLastTeam = teamName
        local ok = false
        if type(localChatPrint) == "function" then
            ok = localChatPrint(formatted) == true
        end
        if not ok then print("[rgnVotes/local] " .. plainMarker .. message) end
        localPrintCount = localPrintCount + 1
        M._voteLocalPrintCount = localPrintCount
        count = count + 1
    end
    if count > 0 then
        writeRuntime("local chat flushed", {
            count = count,
            total = localPrintCount,
            remaining = #chatQueue,
            chat = localChatStatus,
        })
    end
end

local function voteLogicTick(t)
    if t >= nextListenerRefresh then
        nextListenerRefresh = t + 2.0
        requestListeners()
    end
    if t >= nextSessionPoll then
        nextSessionPoll = t + 0.50
        local key = sessionKey()
        if lastSessionKey == nil then lastSessionKey = key
        elseif key ~= lastSessionKey then
            lastSessionKey = key
            requestListeners()
            clearVote("session rearmed", true)
        end
    end
    sendQueued(t)
    if lastVote > 0 and endAt == 0 and t - lastVote > 2.0 then endAt = t + DISPLAY_DURATION end
    if endAt > 0 and t >= endAt then clearVote("ready"); return end
end

pcall(function() callbacks.Unregister("Draw", "rgnMultitool_VoteDraw") end)
pcall(function() callbacks.Unregister("CreateMove", "rgnMultitool_VoteLogic") end)
pcall(function() callbacks.Unregister("FireGameEvent", "rgnMultitool_VoteEvents") end)
local runtimeGeneration = (tonumber(rawget(_G, "RGN_VOTE_RUNTIME_GENERATION")) or 0) + 1
rawset(_G, "RGN_VOTE_RUNTIME_GENERATION", runtimeGeneration)
local logicBusy = false
callbacks.Register("CreateMove", "rgnMultitool_VoteLogic", function()
    if rawget(_G, "RGN_VOTE_RUNTIME_GENERATION") ~= runtimeGeneration or logicBusy then return end
    -- Vote/session work runs at 20 Hz.
    local t = clock()
    if t < nextLogicTick then return end
    nextLogicTick = t + 0.05
    logicBusy = true
    local ok, err = pcall(voteLogicTick, t)
    if not ok then writeRuntime("logic callback error", { error = tostring(err) }) end
    logicBusy = false
end)
requestListeners()
lastSessionKey = sessionKey()
initLocalChat()
writeRuntime("module loaded", { session = lastSessionKey, chat = localChatStatus })

callbacks.Register("Unload", function()
    if rawget(_G, "RGN_VOTE_RUNTIME_GENERATION") ~= runtimeGeneration then return end
    rawset(_G, "RGN_VOTE_RUNTIME_GENERATION", runtimeGeneration + 1)
    pcall(callbacks.Unregister, "CreateMove", "rgnMultitool_VoteLogic")
    logicBusy = false
end)

end)

loadModule("REGION", function()
-- Safe region preference: use CS2/SteamNetworkingSockets console settings
-- instead of patching steamnetworkingsockets.dll functions at fixed RVAs.
local tab = M:Tab("REGION")
tab:Row()

local CONFIG_FILE = "rgnregion_config.txt"
local SDR_ENDPOINT = "https://api.steampowered.com/ISteamApps/GetSDRConfig/v1/?appid=730"
local fallbackRegions = {
    { "ams", "Amsterdam (Netherlands)" },
    { "atl", "Atlanta (Georgia)" },
    { "eze", "Buenos Aires (Argentina)" },
    { "maa2", "Chennai - Ambattur (India)" },
    { "ord", "Chicago (Illinois)" },
    { "dfw", "Dallas (Texas)" },
    { "dxb", "Dubai (United Arab Emirates)" },
    { "fsn", "Falkenstein (Germany)" },
    { "fra", "Frankfurt (Germany)" },
    { "gum", "Guam" },
    { "hel", "Helsinki (Finland)" },
    { "hkg", "Hong Kong" },
    { "jnb", "Johannesburg (South Africa)" },
    { "lim", "Lima (Peru)" },
    { "lhr", "London (England)" },
    { "lax", "Los Angeles (California)" },
    { "mad", "Madrid (Spain)" },
    { "bom2", "Mumbai (India)" },
    { "par", "Paris (France)" },
    { "scl", "Santiago (Chile)" },
    { "gru", "Sao Paulo (Brazil)" },
    { "sea", "Seattle (Washington)" },
    { "seo", "Seoul (South Korea)" },
    { "sgp", "Singapore" },
    { "iad", "Sterling (Virginia)" },
    { "sto2", "Stockholm - Bromma (Sweden)" },
    { "sto", "Stockholm - Kista (Sweden)" },
    { "syd", "Sydney (Australia)" },
    { "tyo", "Tokyo Koto City (Japan)" },
    { "vie", "Vienna (Austria)" },
    { "waw", "Warsaw (Poland)" },
    { "eat", "Wenatchee (Washington)" },
    { "ctu", "Alibaba Cloud Chengdu (China)" },
    { "ctum", "Alibaba Cloud Chengdu - Mobile (China)" },
    { "ctut", "Alibaba Cloud Chengdu - Telecom (China)" },
    { "ctuu", "Alibaba Cloud Chengdu - Unicom (China)" },
    { "pek", "Alibaba Cloud Beijing (China)" },
    { "pekm", "Alibaba Cloud Beijing - Mobile (China)" },
    { "pekt", "Alibaba Cloud Beijing - Telecom (China)" },
    { "peku", "Alibaba Cloud Beijing - Unicom (China)" },
    { "pvg", "Perfect World Shanghai (China)" },
    { "pvgm", "Perfect World Shanghai - Mobile (China)" },
    { "pvgt", "Perfect World Shanghai - Telecom (China)" },
    { "pvgu", "Perfect World Shanghai - Unicom (China)" },
    { "tgd", "Tencent Guangzhou (China)" },
    { "tgdm", "Tencent Guangzhou - Mobile (China)" },
    { "tgdt", "Tencent Guangzhou - Telecom (China)" },
    { "tgdu", "Tencent Guangzhou - Unicom (China)" },
}

-- Current and older POP aliases which can be returned by Steam's live relay
-- interface even when the public app configuration exposes a newer name.
local POP_NAME_OVERRIDES = {
    bom = "Mumbai (India)", maa = "Chennai - Ambattur (India)",
    mwh = "Wenatchee (Washington)", helm = "Helsinki (Finland)",
    tyo1 = "Tokyo Koto City (Japan)", tyo2 = "Tokyo Koto City (Japan)", tyo3 = "Tokyo Koto City (Japan)",
    can = "Guangzhou (China)", sha = "Shanghai (China)",
    pwj = "Tianjin (China)", pwg = "Guangzhou (China)", pwz = "Chengdu (China)",
    pwu = "China relay", tsn = "Tianjin (China)",
}

local function readText(path)
    local out
    pcall(function()
        local f = file.Open(path, "r")
        if f then out = f:Read(); f:Close() end
    end)
    return type(out) == "string" and out or ""
end

local function writeText(path, text)
    local ok = false
    pcall(function()
        local f = file.Open(path, "w")
        if f then f:Write(text); f:Close(); ok = true end
    end)
    return ok
end

local saved = {}
for key, value in readText(CONFIG_FILE):gmatch("([%w_]+)=([^\r\n]*)") do saved[key] = value end

local regionCodes, regionNames, regionColors, regionSuffixes = { "" }, { "Automatic (nearest available)" }, {}, {}
local regionPings, nearestCode, nearestName, nearestPing = {}, "", "", nil

local function pingColor(ping)
    if type(ping) ~= "number" then return { 128, 140, 158, 210 } end
    -- Smooth green -> amber -> red transition: low latency is green, while
    -- an increasingly high value shifts gradually through yellow to red.
    local function blend(a, b, t)
        return {
            math.floor(a[1] + (b[1] - a[1]) * t + 0.5),
            math.floor(a[2] + (b[2] - a[2]) * t + 0.5),
            math.floor(a[3] + (b[3] - a[3]) * t + 0.5), 255,
        }
    end
    if ping <= 55 then return blend({ 74, 210, 132 }, { 235, 207, 78 }, ping / 55) end
    if ping <= 145 then return blend({ 235, 207, 78 }, { 239, 93, 83 }, (ping - 55) / 90) end
    return { 239, 93, 83, 255 }
end

local function cloneEntries(entries)
    local out = {}
    for i = 1, #entries do out[#out + 1] = { entries[i][1], entries[i][2] } end
    return out
end

local regionCatalog = cloneEntries(fallbackRegions)

local function replaceRegions(entries, keepCode)
    local rows, seen = {}, {}
    for i = 1, #entries do
        local code = tostring(entries[i][1] or ""):lower()
        local name = tostring(entries[i][2] or "")
        if code:match("^[%w%d_]+$") and code ~= "" and name ~= "" and not seen[code] then
            seen[code] = true
            rows[#rows + 1] = { code = code, name = name, ping = tonumber(regionPings[code]) }
        end
    end

    -- Resolve older and China-specific POP aliases returned by the live
    -- network interface.  Unknown internal relays are intentionally omitted:
    -- presenting them as "Steam relay" is not useful for making a choice.
    for code, ping in pairs(regionPings) do
        if not seen[code] then
            local name = POP_NAME_OVERRIDES[code]
            if name then
                seen[code] = true
                rows[#rows + 1] = { code = code, name = name, ping = tonumber(ping) }
            end
        end
    end

    table.sort(rows, function(a, b)
        local ap, bp = a.ping, b.ping
        if (ap ~= nil) ~= (bp ~= nil) then return ap ~= nil end
        if ap and bp and ap ~= bp then return ap < bp end
        return a.name < b.name
    end)

    nearestCode, nearestName, nearestPing = "", "", nil
    for i = 1, #rows do
        if rows[i].ping and (nearestPing == nil or rows[i].ping < nearestPing) then
            nearestCode, nearestName, nearestPing = rows[i].code, rows[i].name, rows[i].ping
        end
    end

    local automatic, automaticSuffix = "Automatic (nearest available)", nil
    if nearestCode ~= "" then
        automaticSuffix = tostring(nearestPing) .. " ms)"
        local shortName = nearestName:gsub("%s*%b()", "")
        automatic = "Automatic (" .. shortName .. " / " .. automaticSuffix
    end
    local codes, names, colors, suffixes = { "" }, { automatic }, { pingColor(nearestPing) }, { automaticSuffix }
    for i = 1, #rows do
        local row = rows[i]
        local latency = row.ping and (" (" .. tostring(math.floor(row.ping + 0.5)) .. " ms)") or " (probe pending)"
        codes[#codes + 1] = row.code
        names[#names + 1] = row.name .. latency
        colors[#colors + 1] = pingColor(row.ping)
        suffixes[#suffixes + 1] = latency
    end
    regionCodes, regionNames, regionColors, regionSuffixes = codes, names, colors, suffixes
    local selected = 1
    for i = 1, #regionCodes do
        if regionCodes[i] == keepCode then selected = i; break end
    end
    return selected
end

local savedCodes = {}
for code in tostring(saved.region or ""):gmatch("[%w%d_]+") do savedCodes[code:lower()] = true end
replaceRegions(fallbackRegions, "")
local regionSection = tab:Section("Matchmaking region")
local regionForceEnabled = saved.enabled == "1" and next(savedCodes) ~= nil
local initialSelected = {}
for i = 2, #regionCodes do
    if savedCodes[regionCodes[i]] then initialSelected[#initialSelected + 1] = i end
end
local regionCombo = regionSection:MultiCombo("Preferred relay(s)", regionNames, initialSelected)
local regionWidget = regionSection.ws[#regionSection.ws]
regionWidget.optionColors = regionColors
regionWidget.optionSuffixes = regionSuffixes
local maxPing = regionSection:Slider("Maximum matchmaking ping", math.max(25, math.min(350, tonumber(saved.max_ping) or 80)), 25, 350, 5, "%.0f ms")

tab:Col()
local actionSection = tab:Section("Actions")
local statusSection = tab:Section("Status")

local originalPing = 150
pcall(function()
    local value = tonumber(client.GetConVar("mm_dedicated_search_maxping"))
    if value and value >= 1 then originalPing = value end
end)

local applied = false
local activeCode = ""
local activePing = originalPing
local statusText = "Automatic selection; module is off"
local lastAppliedSignature, lastSavedSignature
local nextPoll = 0
local nextProbe, probeAttempts = 0, 0
local PROBE_MAX_ATTEMPTS = 12
local PROBE_RETRY_SECONDS = 6.0

local selectedCodes, bestSelectedCode, selectionSignature, restoreSelectedCodes

selectedCodes = function()
    local picked, seen = {}, {}
    local value = regionCombo:Get()
    if type(value) ~= "table" then return picked end
    for i = 2, #regionCodes do
        if value[i] and not seen[regionCodes[i]] then
            seen[regionCodes[i]] = true
            picked[#picked + 1] = regionCodes[i]
        end
    end
    return picked
end

selectionSignature = function()
    local codes = selectedCodes()
    table.sort(codes)
    return table.concat(codes, ",")
end

bestSelectedCode = function()
    local codes = selectedCodes()
    local best, bestPing
    for i = 1, #codes do
        local ping = tonumber(regionPings[codes[i]])
        if best == nil or (ping ~= nil and (bestPing == nil or ping < bestPing)) then
            best, bestPing = codes[i], ping
        end
    end
    return best or "", #codes
end

restoreSelectedCodes = function(codes)
    local wanted, selected = {}, {}
    for i = 1, #(codes or {}) do wanted[codes[i]] = true end
    for i = 2, #regionCodes do
        if wanted[regionCodes[i]] then selected[i] = true end
    end
    regionCombo:Set(selected)
end

-- Steam publishes this interface specifically for estimating relay latency.
-- It is a read-only V4 call: no signatures, RVA offsets, memory patches, or
-- per-frame native calls are used here.  A failed probe simply leaves the
-- normal official list intact.
local relayProbe = { tried = false, ready = false, detail = "Relay probe pending" }

local function decodePop(id)
    local text = ""
    for shift = 24, 0, -8 do
        local byte = math.floor((tonumber(id) or 0) / (2 ^ shift)) % 256
        if byte >= 32 and byte < 127 then text = text .. string.char(byte) end
    end
    return (text:gsub("%s", "")):lower()
end

local function openRelayProbe()
    if relayProbe.tried then return relayProbe.ready end
    relayProbe.tried = true
    if type(ffi) ~= "table" then
        relayProbe.detail = "Aimware FFI is unavailable"
        return false
    end

    local ok, reason = pcall(function()
        local module = ffi.C.GetModuleHandleA("steamnetworkingsockets.dll")
        if module == nil then error("steamnetworkingsockets.dll is not loaded") end
        local accessor = ffi.C.GetProcAddress(module, "SteamNetworkingUtils_LibV4")
        if accessor == nil then error("SteamNetworkingUtils V4 is unavailable") end

        local utils = ffi.cast("void*(*)(void)", accessor)()
        if utils == nil then error("SteamNetworkingUtils returned no interface") end
        local vtable = ffi.cast("void***", utils)[0]
        if vtable == nil then error("SteamNetworkingUtils returned no vtable") end

        -- ISteamNetworkingUtils V4 public methods: CheckPingDataUpToDate=7,
        -- GetPingToDataCenter=8, GetPOPCount=10 and GetPOPList=11.
        relayProbe.utils = utils
        relayProbe.checkFresh = ffi.cast("bool(*)(void*, float)", vtable[7])
        relayProbe.getPing = ffi.cast("int(*)(void*, uint32_t, uint32_t*)", vtable[8])
        relayProbe.getDirectPing = ffi.cast("int(*)(void*, uint32_t)", vtable[9])
        relayProbe.getCount = ffi.cast("int(*)(void*)", vtable[10])
        relayProbe.getList = ffi.cast("int(*)(void*, uint32_t*, int)", vtable[11])
    end)
    relayProbe.ready = ok and relayProbe.utils ~= nil and relayProbe.getPing ~= nil
        and relayProbe.getDirectPing ~= nil and relayProbe.getCount ~= nil and relayProbe.getList ~= nil
    relayProbe.detail = relayProbe.ready and "Steam relay latency API ready" or ("Relay API unavailable: " .. tostring(reason))
    return relayProbe.ready
end

local function refreshRelayPings(keepCodes)
    if not openRelayProbe() then return 0 end
    -- This runs only after a user refresh or during the bounded startup pass.
    -- Asking for fresh data here starts Steam's measurement if it has not
    -- already started; it does not patch or alter matchmaking state.
    pcall(function() relayProbe.checkFresh(relayProbe.utils, 0.0) end)

    local okCount, count = pcall(function() return tonumber(relayProbe.getCount(relayProbe.utils)) or 0 end)
    if not okCount or count <= 0 then
        relayProbe.detail = "Steam relay list is still initializing"
        return 0
    end
    count = math.min(count, 256)
    local ids = ffi.new("uint32_t[?]", count)
    local okList, filled = pcall(function() return tonumber(relayProbe.getList(relayProbe.utils, ids, count)) or 0 end)
    if not okList or filled <= 0 then
        relayProbe.detail = "Steam returned no relay list yet"
        return 0
    end

    local measured, directCount, relayedCount = {}, 0, 0
    for i = 0, math.min(filled, count) - 1 do
        local id, code = tonumber(ids[i]), decodePop(ids[i])
        if code ~= "" then
            local ping
            local okDirect, direct = pcall(function() return tonumber(relayProbe.getDirectPing(relayProbe.utils, id)) end)
            if okDirect and type(direct) == "number" and direct >= 0 and direct <= 2000 then
                ping, directCount = direct, directCount + 1
            else
                local via = ffi.new("uint32_t[1]")
                local okPing, relayed = pcall(function() return tonumber(relayProbe.getPing(relayProbe.utils, id, via)) end)
                if okPing and type(relayed) == "number" and relayed >= 0 and relayed <= 2000 then
                    ping, relayedCount = relayed, relayedCount + 1
                end
            end
            if ping then
                measured[code] = math.floor(ping + 0.5)
            end
        end
    end
    if next(measured) == nil then
        relayProbe.detail = "Steam is measuring relay latency (" .. tostring(count) .. " relays found, no samples yet)"
        return 0
    end

    local measuredCount = 0
    for _ in pairs(measured) do measuredCount = measuredCount + 1 end
    regionPings = measured
    local keep = keepCodes or selectedCodes()
    replaceRegions(regionCatalog, "")
    regionWidget.options = regionNames
    regionWidget.optionColors = regionColors
    regionWidget.optionSuffixes = regionSuffixes
    restoreSelectedCodes(keep)
    relayProbe.detail = "Measured " .. tostring(measuredCount) .. " Steam relays (direct "
        .. tostring(directCount) .. ", relayed " .. tostring(relayedCount) .. ")"
    return measuredCount
end

local function settingsSignature()
    return table.concat({
        regionForceEnabled and "1" or "0",
        selectionSignature(),
        tostring(math.floor(tonumber(maxPing:Get()) or 80)),
    }, "|")
end

local function saveSettings()
    local text = table.concat({
        "enabled=" .. (regionForceEnabled and "1" or "0"),
        "region=" .. selectionSignature(),
        "max_ping=" .. tostring(math.floor(tonumber(maxPing:Get()) or 80)),
    }, "\n")
    writeText(CONFIG_FILE, text)
    lastSavedSignature = settingsSignature()
end

local function resetRelay()
    pcall(function() client.Command('sdr SDRClient_ForceRelayCluster ""', true) end)
end

local function regionNameForCode(code)
    for i = 2, #regionCodes do
        if regionCodes[i] == code then
            -- Remove only the final latency suffix, retaining country names.
            return (regionNames[i] or code):gsub(" %([^()]+ ms%)$", "")
        end
    end
    return code
end

local function restoreAutomatic(showNotice)
    resetRelay()
    pcall(function() client.SetConVar("mm_dedicated_search_maxping", originalPing, true) end)
    regionForceEnabled = false
    applied = false
    activeCode = ""
    activePing = originalPing
    lastAppliedSignature = nil
    statusText = "Automatic selection restored"
    if showNotice then M:Notify(statusText, "success") end
end

local function applySelection(showNotice)
    local code, selectedCount = bestSelectedCode()
    regionForceEnabled = code ~= ""
    local ping = math.max(25, math.min(350, math.floor(tonumber(maxPing:Get()) or 80)))
    local pingOK = pcall(function() client.SetConVar("mm_dedicated_search_maxping", ping, true) end)
    local relayOK
    if code == "" then
        relayOK = pcall(resetRelay)
    else
        relayOK = pcall(function()
            client.Command("sdr SDRClient_ForceRelayCluster " .. code, true)
        end)
    end
    applied = pingOK and relayOK
    activeCode, activePing = code, ping
    lastAppliedSignature = settingsSignature()
    local measured = tonumber(regionPings[code])
    statusText = code == "" and "Automatic relay selection" or ("Forced: " .. regionNameForCode(code))
    if showNotice then M:Notify(statusText, applied and "success" or "error") end
    return applied
end

local function refreshOfficialRegions(showNotice)
    local keep = selectedCodes()
    local raw
    pcall(function() raw = http.Get(SDR_ENDPOINT .. "&nocache=" .. tostring(math.floor((globals.RealTime() or 0) * 1000))) end)
    local loadedOfficial = false
    if type(raw) == "string" and #raw >= 100 then
        local entries, seen = {}, {}
        -- Extract the `pops` object first.  Individual POP entries may contain
        -- aliases, geo data and nested relay arrays before/after `desc`, so a
        -- simple one-line JSON pattern loses many of them (notably China).
        local pops = raw:match('"pops"%s*:%s*(%b{})') or ""
        for code, object in pops:gmatch('"([%w%d_]+)"%s*:%s*(%b{})') do
            code = code:lower()
            local name = object:match('"desc"%s*:%s*"([^"]+)"')
            if name and not seen[code] then
                seen[code] = true
                name = name:gsub('\\/', '/')
                entries[#entries + 1] = { code, name }
                local aliases = object:match('"aliases"%s*:%s*(%b[])')
                if aliases then
                    for alias in aliases:gmatch('"([%w%d_]+)"') do
                        alias = alias:lower()
                        if not seen[alias] then
                            seen[alias] = true
                            entries[#entries + 1] = { alias, name }
                        end
                    end
                end
            end
        end
        if #entries >= 10 then
            regionCatalog = entries
            loadedOfficial = true
        end
    end

    local measured = refreshRelayPings(keep)
    if measured <= 0 then
        replaceRegions(regionCatalog, "")
        regionWidget.options = regionNames
        regionWidget.optionColors = regionColors
        regionWidget.optionSuffixes = regionSuffixes
        restoreSelectedCodes(keep)
        -- Steam takes a few seconds to create fresh ping measurements.  Retry
        -- only a handful of times, never on every frame.
        nextProbe, probeAttempts = (globals.RealTime() or 0) + 1.0, 0
    end

    if measured > 0 and nearestCode ~= "" then
        statusText = "Nearest: " .. nearestName .. " (" .. tostring(nearestPing) .. " ms)"
    elseif loadedOfficial then
        statusText = "Official Steam list loaded; " .. relayProbe.detail
    else
        statusText = "Built-in Steam list in use; " .. relayProbe.detail
    end
    if showNotice then M:Notify(statusText, measured > 0 and "success" or "info") end
    return loadedOfficial or measured > 0
end

actionSection:Button("Reload relay pings", function()
    refreshOfficialRegions(true)
    saveSettings()
end)
actionSection:Button("Force selected relay(s)", function()
    applySelection(true)
    saveSettings()
end)

statusSection:Custom(62, function(ui)
    ui.label(statusText, ui.T.text)
    local code, count = bestSelectedCode()
    local measured = tonumber(regionPings[code])
    if code ~= "" then
        ui.label((count > 1 and ("Best of " .. tostring(count) .. " selected") or "One relay selected")
            .. " | max " .. tostring(math.floor(tonumber(maxPing:Get()) or 80)) .. " ms"
            .. (measured and (" | " .. tostring(measured) .. " ms") or ""), ui.T.textdim)
    else
        ui.label("Select one or more relays to force matchmaking.", ui.T.textdim)
    end
    local total, direct, relayed = relayProbe.detail:match("^Measured (%d+) Steam relays %(direct (%d+), relayed (%d+)%)$")
    ui.label(total and ("Samples: " .. total .. " (direct " .. direct .. " / relay " .. relayed .. ")") or relayProbe.detail, ui.T.textdim)
end)

pcall(function() callbacks.Unregister("Draw", "rgnMultitool_RegionDraw") end)
pcall(function() callbacks.Unregister("Unload", "rgnMultitool_RegionUnload") end)
callbacks.Register("Draw", "rgnMultitool_RegionDraw", function()
    local t = 0
    pcall(function() t = globals.RealTime() end)
    if t < nextPoll then return end
    nextPoll = t + 0.25
    local signature = settingsSignature()
    if signature ~= lastSavedSignature then saveSettings() end
    if regionForceEnabled then
        if signature ~= lastAppliedSignature then applySelection(false) end
    elseif applied then
        restoreAutomatic(false)
    end

    -- One bounded initialization pass obtains the local Steam relay pings
    -- without leaving an expensive polling loop running during a match.
    if nextProbe > 0 and t >= nextProbe and probeAttempts < PROBE_MAX_ATTEMPTS then
        probeAttempts = probeAttempts + 1
        local keep = selectedCodes()
        local measured = refreshRelayPings(keep)
        if measured > 0 then
            nextProbe = 0
            statusText = "Nearest: " .. nearestName .. " (" .. tostring(nearestPing) .. " ms)"
        else
            nextProbe = t + 2.0
        end
    elseif nextProbe > 0 and probeAttempts >= PROBE_MAX_ATTEMPTS then
        -- The relay subsystem may only become ready after CS2 has completed
        -- its own connection work.  Keep trying at a very low frequency so
        -- the user never needs to press Refresh, while avoiding render-rate
        -- polling or any meaningful FPS cost.
        nextProbe = t + PROBE_RETRY_SECONDS
        probeAttempts = 0
        relayProbe.detail = "Waiting for Steam relay samples; retrying automatically"
    end
end)

-- Begin one low-frequency local probe on load.  The static catalogue remains
-- usable while Steam finishes its asynchronous latency measurement.
nextProbe = (globals.RealTime() or 0) + 0.5

callbacks.Register("Unload", "rgnMultitool_RegionUnload", function()
    saveSettings()
    if applied then restoreAutomatic(false) end
    pcall(callbacks.Unregister, "Draw", "rgnMultitool_RegionDraw")
end)

end)

loadModule("WHITELIST", function()
-- Session whitelist with the original immunity behavior, presented inside the
-- multitool instead of opening a second Aimware window.
local tab = M:Tab("WHITELIST")
tab:Row()
local playersSection = tab:Section("Enemy players")
local playerLabels = { "[ no enemies detected ]" }
local playerList = playersSection:Listbox("", playerLabels, "fill", 1)
tab:Col()
local controlSection = tab:Section("Whitelist control")
local whitelistEnabled = controlSection:Checkbox("Enable whitelist", false)
local forceAll = controlSection:Checkbox("Ignore whitelist / target everyone", false)
-- The original whitelist stored its state by C_CSPlayerPawn index.  Ragebot
-- and DrawESP both receive that pawn, whereas a CCSPlayerController can keep
-- a different index after a respawn or side change.  Keep the same identity
-- end-to-end so the UI state and the actual target are always identical.
local protectedByIndex, rowsBySelection, knownEntities = {}, {}, {}
local refreshRequested = true
local lastEnabled = false
local detectionStatus = "Waiting for a match"
local enforcementStatus = "Protection inactive"

local colorSection = tab:Section("Visuals")
local protectedColor = colorSection:ColorPicker("Protected color", { 76, 201, 156, 255 })
local targetColor = colorSection:ColorPicker("Target color", { 255, 166, 74, 255 })

local function safeCall(fn, fallback)
    local ok, value = pcall(fn)
    if ok then return value end
    return fallback
end

local function entityIndex(entity)
    local value = safeCall(function() return tonumber(entity:GetIndex()) end)
    return value and value > 0 and value or nil
end

local function entityTeam(entity)
    local value = safeCall(function() return tonumber(entity:GetTeamNumber()) end)
    if value == nil then value = safeCall(function() return tonumber(entity:GetPropInt("m_iTeamNum")) end) end
    if value == nil then value = safeCall(function() return tonumber(entity:GetFieldInt("m_iTeamNum")) end) end
    return value
end

local function fieldBool(entity, name)
    local value = safeCall(function() return entity:GetFieldBool(name) end)
    if value == nil then value = safeCall(function() return entity:GetPropBool(name) end) end
    if type(value) == "number" then return value ~= 0 end
    return value == true
end

local function controllerPawn(controller)
    if not controller then return nil end
    local pawn = safeCall(function() return controller:GetPropEntity("m_hPlayerPawn") end)
    if not pawn then pawn = safeCall(function() return controller:GetPropEntity("m_hPawn") end) end
    if not pawn then pawn = safeCall(function() return controller:GetFieldEntity("m_hPlayerPawn") end) end
    if not pawn then pawn = safeCall(function() return controller:GetFieldEntity("m_hPawn") end) end
    if pawn then return pawn end
    local handle = safeCall(function() return tonumber(controller:GetPropInt("m_hPlayerPawn")) end)
    if not handle or handle == 0 or handle == -1 then handle = safeCall(function() return tonumber(controller:GetFieldInt("m_hPlayerPawn")) end) end
    if handle and handle ~= 0 and handle ~= -1 then
        local index = handle % 32768
        if index > 0 and index ~= 32767 then pawn = safeCall(function() return entities.GetByIndex(index) end) end
    end
    return pawn
end

local function setImmortal(entity, value)
    if not entity then return end
    pcall(function()
        local current = entity:GetFieldBool("m_bGunGameImmunity")
        if current ~= nil and current ~= (value and true or false) then
            entity:SetFieldBool(value and true or false, "m_bGunGameImmunity")
        end
    end)
end

local function cleanupImmortalStates()
    local pawns = safeCall(function() return entities.FindByClass("C_CSPlayerPawn") end, {}) or {}
    for i = 1, #pawns do
        local entity = pawns[i]
        if safeCall(function() return entity:IsPlayer() end, false) then setImmortal(entity, false) end
    end
    local controllers = safeCall(function() return entities.FindByClass("CCSPlayerController") end, {}) or {}
    for i = 1, #controllers do setImmortal(controllerPawn(controllers[i]), false) end
end

local function cleanPlayerName(value)
    if type(value) ~= "string" then return nil end
    if value:find("%z") then return nil end
    value = value:gsub("[%c%z]", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if value == "" or value == "CCSPlayerController" or value == "C_CSPlayerPawn"
        or value == "CCSPlayerPawn" or value == "C_CSPlayerPawnBase" then return nil end
    local compact = value:gsub("%s", "")
    local wordish = 0
    for i = 1, #compact do
        local byte = compact:byte(i)
        if (byte >= 48 and byte <= 57) or (byte >= 65 and byte <= 90)
            or (byte >= 97 and byte <= 122) or byte == 95 or byte >= 128 then
            wordish = wordish + 1
        end
    end
    if #compact < 2 or wordish < math.max(1, math.floor(#compact * 0.40)) then return nil end
    return value:sub(1, 48)
end

local function playerName(entity, controller)
    local name
    local controllerIndex = entityIndex(controller)
    local pawnIndex = entityIndex(entity)

    -- Aimware's public player-name helpers are safer than reading raw
    -- controller string storage and work for both humans and bots.
    if type(client) == "table" and type(client.GetPlayerNameByIndex) == "function" then
        if controllerIndex then name = cleanPlayerName(safeCall(function() return client.GetPlayerNameByIndex(controllerIndex) end)) end
        if not name and pawnIndex then name = cleanPlayerName(safeCall(function() return client.GetPlayerNameByIndex(pawnIndex) end)) end
    end
    if not name and type(client) == "table" and type(client.GetPlayerInfo) == "function" then
        local info
        if controllerIndex then info = safeCall(function() return client.GetPlayerInfo(controllerIndex) end) end
        if type(info) ~= "table" and pawnIndex then info = safeCall(function() return client.GetPlayerInfo(pawnIndex) end) end
        if type(info) == "table" then name = cleanPlayerName(info.Name or info.name or info.PlayerName or info.playername) end
    end

    -- Exact compatibility path used by the original working whitelist.lua.
    if not name and entity then
        name = cleanPlayerName(safeCall(function()
            local original = entity:GetFieldEntity("m_hOriginalController")
            return original and original:GetFieldString("m_iszPlayerName") or nil
        end))
    end

    -- Last fallback for builds that only expose controller fields.
    if not name and controller then
        name = cleanPlayerName(safeCall(function() return controller:GetFieldString("m_iszPlayerName") end))
        if not name then name = cleanPlayerName(safeCall(function() return controller:GetPropString("m_iszPlayerName") end)) end
        if not name then name = cleanPlayerName(safeCall(function() return controller:GetName() end)) end
    end
    return name or ("Player #" .. tostring(controllerIndex or pawnIndex or "?"))
end

local function localPawn()
    local pawn = safeCall(function() return entities.GetLocalPawn() end)
    if pawn == nil then pawn = safeCall(function() return entities.GetLocalPlayer() end) end
    return pawn
end

local function isEnemy(entity, team)
    if not entity or safeCall(function() return entity:IsPlayer() end, false) ~= true then return false end
    local otherTeam = entityTeam(entity)
    return type(otherTeam) == "number" and otherTeam ~= team and otherTeam >= 2 and otherTeam <= 3
end

local function applyState(entity, index)
    local enabledNow = whitelistEnabled:Get() == true
    local protected = enabledNow and forceAll:Get() ~= true and protectedByIndex[index] == true
    setImmortal(entity, protected)
    return protected
end

local function refreshPlayers()
    local current, rows = {}, {}
    local pawn = localPawn()
    local team = entityTeam(pawn)
    local pawns = safeCall(function() return entities.FindByClass("C_CSPlayerPawn") end, {}) or {}

    -- This is intentionally the original whitelist enumeration path.  It is
    -- the only source used for the row key and for the immunity write below.
    if type(team) == "number" then
        for i = 1, #pawns do
            local entity = pawns[i]
            if isEnemy(entity, team) then
                local index = entityIndex(entity)
                if index then
                    if protectedByIndex[index] == nil then protectedByIndex[index] = false end
                    current[index] = entity
                    applyState(entity, index)
                    rows[#rows + 1] = { index = index, entity = entity, name = playerName(entity) }
                end
            end
        end
    end
    detectionStatus = string.format("Detected: %d | pawns: %d | team: %s",
                                    #rows, #pawns, tostring(team or "?"))
    if whitelistEnabled:Get() == true then
        local protectedCount = 0
        if forceAll:Get() ~= true then
            for index, entity in pairs(current) do
                if entity and protectedByIndex[index] == true then protectedCount = protectedCount + 1 end
            end
        end
        enforcementStatus = string.format("Protected: %d | Targets: %d", protectedCount, math.max(0, #rows - protectedCount))
    else
        enforcementStatus = "Protection inactive"
    end
    for index, entity in pairs(knownEntities) do
        if current[index] == nil or current[index] ~= entity then
            setImmortal(entity, false)
        end
        if current[index] == nil then
            protectedByIndex[index] = nil
        end
    end
    knownEntities = current
    table.sort(rows, function(a, b)
        local an, bn = a.name:lower(), b.name:lower()
        if an == bn then return a.index < b.index end
        return an < bn
    end)

    for i = #playerLabels, 1, -1 do playerLabels[i] = nil end
    for i = #rowsBySelection, 1, -1 do rowsBySelection[i] = nil end
    if #rows == 0 then
        playerLabels[1] = "[ no enemies detected ]"
    else
        for i = 1, #rows do
            local row = rows[i]
            rowsBySelection[i] = row
            local state = protectedByIndex[row.index] == true and "PROTECTED" or "TARGET"
            playerLabels[i] = string.format("[%s] %s", state, row.name)
        end
    end
    local selected = tonumber(playerList:Get()) or 1
    if selected < 1 then selected = 1 end
    if selected > #playerLabels then selected = #playerLabels end
    playerList:Set(selected)
end

local function selectedRow()
    return rowsBySelection[tonumber(playerList:Get()) or 1]
end

controlSection:Button("Toggle selected protection", function()
    local row = selectedRow()
    if not row then M:Notify("select an enemy first", "info"); return end
    protectedByIndex[row.index] = not (protectedByIndex[row.index] == true)
    applyState(row.entity, row.index)
    refreshPlayers()
end)
controlSection:Button("Protect every enemy", function()
    forceAll:Set(false)
    for index in pairs(knownEntities) do protectedByIndex[index] = true end
    refreshPlayers()
end)
controlSection:Button("Target every enemy", function()
    forceAll:Set(false)
    for index in pairs(knownEntities) do protectedByIndex[index] = false end
    refreshPlayers()
end)

local statusSection = tab:Section("Selected player")
statusSection:Custom(72, function(ui)
    local row = selectedRow()
    if not row then
        ui.label("No enemy selected", ui.T.textdim)
        ui.label(detectionStatus, ui.T.textdim)
        ui.label(enforcementStatus, ui.T.textdim)
        ui.label("New enemies start as valid targets.", ui.T.textdim)
        return
    end
    local protected = protectedByIndex[row.index] == true
    ui.label(row.name, ui.T.texthi)
    ui.label(protected and "Status: protected from targeting" or "Status: valid target",
             protected and { 76, 201, 156, 255 } or { 255, 166, 74, 255 })
    ui.label(detectionStatus, ui.T.textdim)
    ui.label(enforcementStatus, ui.T.textdim)
end)

cleanupImmortalStates()
local function clock()
    local value = 0
    pcall(function()
        if type(common) == "table" and type(common.Time) == "function" then value = common.Time()
        elseif type(globals) == "table" and type(globals.RealTime) == "function" then value = globals.RealTime() end
    end)
    return tonumber(value) or 0
end
local nextRefresh = 0
local function whitelistRuntime()
    local currentEnabled = whitelistEnabled:Get() == true
    if lastEnabled and not currentEnabled then cleanupImmortalStates() end
    if currentEnabled and not lastEnabled then refreshRequested = true end
    lastEnabled = currentEnabled
    local t = clock()
    if refreshRequested or t >= nextRefresh then
        refreshRequested = false
        nextRefresh = t + 0.35
        refreshPlayers()
    end
end
callbacks.Register("Draw", "rgnMultitool_WhitelistRefresh", whitelistRuntime)

-- DrawESP owns the label, but Ragebot can resolve a target before that draw
-- pass.  Mirror the exact pawn state from CreateMove as well, so a click on
-- any whitelist action is effective for the very next target calculation.
local function whitelistCommand()
    if whitelistEnabled:Get() ~= true then return end
    local pawn = localPawn()
    local team = entityTeam(pawn)
    if type(team) ~= "number" then return end
    local pawns = safeCall(function() return entities.FindByClass("C_CSPlayerPawn") end, {}) or {}
    for i = 1, #pawns do
        local entity = pawns[i]
        if isEnemy(entity, team) then
            local index = entityIndex(entity)
            if index then
                if protectedByIndex[index] == nil then
                    protectedByIndex[index] = false
                    refreshRequested = true
                end
                applyState(entity, index)
            end
        end
    end
end
M._whitelistCommandCallback = whitelistCommand
M._whitelistCommandActive = function() return whitelistEnabled:Get() == true end
refreshPlayers()

callbacks.Register("DrawESP", "rgnMultitool_WhitelistESP", function(esp)
    if whitelistEnabled:Get() ~= true or not esp then return end
    local entity = safeCall(function() return esp:GetEntity() end)
    local pawn = localPawn()
    if not entity or not pawn then return end
    local team = entityTeam(pawn)
    if not isEnemy(entity, team) or safeCall(function() return entity:IsAlive() end, false) ~= true then return end
    local pawnIndex = entityIndex(entity)
    if not pawnIndex then return end
    if protectedByIndex[pawnIndex] == nil then protectedByIndex[pawnIndex] = false; refreshRequested = true end
    local protected = applyState(entity, pawnIndex)
    local color = protected and protectedColor:Get() or targetColor:Get()
    if type(color) ~= "table" then color = protected and { 76, 201, 156, 255 } or { 255, 166, 74, 255 } end
    pcall(function() esp:Color(unpack(color)) end)
    pcall(function() esp:AddTextTop(protected and "WHITELISTED" or "TARGET") end)
end)

callbacks.Register("Unload", "rgnMultitool_WhitelistUnload", function()
    cleanupImmortalStates()
    pcall(callbacks.Unregister, "Draw", "rgnMultitool_WhitelistRefresh")
    pcall(callbacks.Unregister, "DrawESP", "rgnMultitool_WhitelistESP")
    if M._whitelistCommandCallback == whitelistCommand then M._whitelistCommandCallback = nil end
    M._whitelistCommandActive = nil
end)
end)

-- Aimware's anonymous event bridge is tokened so reloads cannot double-dispatch.
do
    local callbackId = "rgnMultitool_GameEvents"
    local unloadId = "rgnMultitool_GameEventsUnload"
    local bridgeKey = "RGN_MULTITOOL_EVENT_BRIDGE_V1"
    local dispatchBusy = false
    local handlers = {
        { field = "_killsayEventCallback", active = "_killsayEventActive", label = "Killsay" },
        { field = "_customSoundsEventCallback", active = "_customSoundsEventActive", label = "Sounds" },
        { field = "_voteEventCallback", label = "Votes" },
    }

    local function dispatchGameEvent(event)
        if dispatchBusy or event == nil then return end
        dispatchBusy = true
        for i = 1, #handlers do
            local entry = handlers[i]
            local handler = M[entry.field]
            local active = entry.active and M[entry.active] or nil
            if type(handler) == "function"
                and (type(active) ~= "function" or active()) then
                local ok, err = pcall(handler, event)
                if not ok then
                    print(string.format("[rgnMultitool] %s event error: %s", entry.label, tostring(err)))
                end
            end
        end
        dispatchBusy = false
    end

    local bridge = rawget(_G, bridgeKey)
    if type(bridge) ~= "table" then
        bridge = { registered = false, token = 0, events = 0 }
        rawset(_G, bridgeKey, bridge)
    end
    bridge.token = (tonumber(bridge.token) or 0) + 1
    local token = bridge.token
    bridge.dispatch = dispatchGameEvent

    pcall(callbacks.Unregister, "FireGameEvent", callbackId)
    pcall(callbacks.Unregister, "Unload", unloadId)
    local registered, registerError = pcall(function()
        callbacks.Register("FireGameEvent", function(event)
            local current = rawget(_G, bridgeKey)
            if type(current) ~= "table" or current.token ~= token then return end
            local dispatcher = current.dispatch
            if type(dispatcher) ~= "function" then return end
            current.events = (tonumber(current.events) or 0) + 1
            local ok, err = pcall(dispatcher, event)
            if not ok then
                current.lastError = tostring(err)
                print("[rgnMultitool] event bridge error: " .. tostring(err))
            end
        end)
    end)
    bridge.registered = registered == true
    if not registered then
        print("[rgnMultitool] stable event bridge failed: " .. tostring(registerError))
    end

    callbacks.Register("Unload", unloadId, function()
        local current = rawget(_G, bridgeKey)
        if type(current) == "table" and current.token == token then
            current.dispatch = nil
            current.registered = false
        end
        M._killsayEventCallback = nil
        M._killsayEventActive = nil
        M._customSoundsEventCallback = nil
        M._customSoundsEventActive = nil
        M._voteEventCallback = nil
        dispatchBusy = false
        pcall(callbacks.Unregister, "Unload", unloadId)
    end)
end

do
    local wanted = { "WEAPONS", "AGENTS", "SKINS CUSTOM", "VIEWMODEL", "SCOPE OVERLAY", "CUSTOM SOUNDS", "MOVEMENT", "REGION", "IDENTITY", "KILLSAY", "WHITELIST", "CONFIGS" }
    local byName, ordered = {}, {}
    for _, tab in ipairs(M._tabs) do byName[tab.name] = tab end
    for _, name in ipairs(wanted) do
        if byName[name] then ordered[#ordered + 1] = byName[name]; byName[name] = nil end
    end
    for _, tab in ipairs(M._tabs) do if byName[tab.name] then ordered[#ordered + 1] = tab end end
    M._tabs, M._active = ordered, 1
end

M:Build({ w = 940, h = 560, autoH = false, resize = true })
print("[rgn] ready " .. RGN_MULTITOOL_VERSION)
