-- Brief things that drift across the screen and fade (27 Nov 2026, Luke: "brief elements appearing in the Emerald
-- Dream and then fading rather than fixtures"): a leaf letting go, a petal, sparks or embers rising, moonlight
-- motes. Each is a few seconds long, behind the interface, never a fixture. Off in the options (ShandoNoDrift).
--
-- ns.Drift(kind, n, spread): n of one kind, starting over `spread` seconds. Kinds are in KINDS below.
-- Art: the maple leaf and poppy petal are cut from Homeland's own wreath paintings (same author); the oak leaf is
-- Manabloom's; the ember is a soft dot drawn in code, tinted per kind.
local _, ns = ...
local DIR = "Interface\\AddOns\\Shando\\drift\\"

-- fall: from the top band down; rise: from the bottom band up. Sizes in pixels at UI scale 1; colours tint the art.
local KINDS = {
    maple   = { art = "leaf_maple", move = "fall", life = 9, size = 34, alpha = 0.85 },
    oak     = { art = "leaf_oak", move = "fall", life = 9, size = 30, alpha = 0.85, rgb = { 0.72, 0.66, 0.30 } },
    green   = { art = "leaf_oak", move = "fall", life = 9, size = 26, alpha = 0.8, rgb = { 0.45, 0.66, 0.32 } },
    poppy   = { art = "petal_poppy", move = "fall", life = 10, size = 22, alpha = 0.9 },
    blossom = { art = "petal_white", move = "fall", life = 10, size = 18, alpha = 0.85, rgb = { 1.0, 0.78, 0.84 } },
    spark   = { art = "ember", move = "rise", life = 4, size = 12, alpha = 0.9, rgb = { 1.0, 0.62, 0.22 }, add = true },
    ember   = { art = "ember", move = "rise", life = 6, size = 16, alpha = 0.8, rgb = { 1.0, 0.42, 0.12 }, add = true },
    mote    = { art = "ember", move = "rise", life = 8, size = 14, alpha = 0.7, rgb = { 0.75, 0.82, 1.0 }, add = true },
}
ns.DRIFT_KINDS = KINDS
local IN, OUT = 1.0, 1.5        -- seconds to fade in, and out at the end of its life

local sky = CreateFrame("Frame", nil, UIParent)
sky:SetAllPoints()
sky:SetFrameStrata("BACKGROUND")     -- over the world, under every window and bar
sky:EnableMouse(false)
sky:Hide()
local pool = {}

local function Sprite()
    for _, s in ipairs(pool) do if not s.on then return s end end
    local s = { tex = sky:CreateTexture(nil, "ARTWORK") }
    pool[#pool + 1] = s
    return s
end

local function Step(_, dt)
    local w, h, any = sky:GetWidth(), sky:GetHeight(), false
    for _, s in ipairs(pool) do
        if s.on then
            s.age = s.age + dt
            local k = s.k
            if s.age < 0 then
                any = true
            elseif s.age >= k.life then
                s.on = nil
                s.tex:Hide()
            else
                any = true
                local p = s.age / k.life
                local x = s.x + math.sin(s.phase + s.age * 1.1) * s.sway
                local y = k.move == "fall" and s.y - p * s.dist or s.y + p * s.dist
                local a = k.alpha * math.min(1, s.age / IN, (k.life - s.age) / OUT)
                if k.move == "rise" then a = a * (0.8 + 0.2 * math.sin(s.age * 9 + s.phase)) end   -- embers flicker
                s.tex:ClearAllPoints()
                s.tex:SetPoint("CENTER", sky, "BOTTOMLEFT", x * w, y * h)
                s.tex:SetAlpha(a)
                if s.tex.SetRotation then s.tex:SetRotation(s.turn * s.age) end
                s.tex:Show()
            end
        end
    end
    if not any then sky:SetScript("OnUpdate", nil) sky:Hide() end
end

-- One sprite of a kind, starting after `delay` seconds. Positions are fractions of the screen.
local function One(k, delay)
    local s = Sprite()
    s.k, s.on, s.age = k, true, -(delay or 0)
    if k.move == "fall" then
        s.x, s.y, s.dist = 0.15 + math.random() * 0.7, 0.85 + math.random() * 0.1, 0.35 + math.random() * 0.2
    else
        s.x, s.y, s.dist = 0.3 + math.random() * 0.4, 0.08 + math.random() * 0.12, 0.25 + math.random() * 0.15
    end
    s.sway = (k.move == "fall" and 0.03 or 0.012) * (0.6 + math.random() * 0.8)
    s.phase, s.turn = math.random() * 6.28, (math.random() - 0.5) * (k.move == "fall" and 1.2 or 0)
    local size = k.size * (0.85 + math.random() * 0.3)
    s.tex:SetTexture(DIR .. k.art)
    s.tex:SetSize(size, size)
    s.tex:SetBlendMode(k.add and "ADD" or "BLEND")
    s.tex:SetVertexColor(k.rgb and k.rgb[1] or 1, k.rgb and k.rgb[2] or 1, k.rgb and k.rgb[3] or 1)
    s.tex:SetAlpha(0)
    s.tex:Hide()
end

-- n sprites of one kind, spread over `spread` seconds. Returns how many started (0 when switched off or unknown).
function ns.Drift(kind, n, spread)
    local k = KINDS[kind]
    if not k or ShandoNoDrift then return 0 end
    n = n or 1
    for i = 1, n do One(k, n > 1 and (spread or 0) * (i - 1) / (n - 1) or 0) end
    sky:Show()
    sky:SetScript("OnUpdate", Step)
    return n
end

-- Stops everything drifting now (a meditation that ends early takes its moments with it).
function ns.DriftClear()
    for _, s in ipairs(pool) do s.on = nil s.tex:Hide() end
    sky:SetScript("OnUpdate", nil)
    sky:Hide()
end
