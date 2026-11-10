-- Settings: left-click the minimap button (or /shando options). On/off, how often she speaks, the quiet gap between
-- any two lines, screen edge strength for the rituals, soundscapes on/off, herb voices and skinning lines on/off (from
-- Herbalore, folded in), how often herbs speak, which meditation /emerald dream plays (and Begin), and the guide.
local _, ns = ...
local COLOUR = "|cffb8c8ff"

local function Window(name, title, height)
    local ok, f = pcall(CreateFrame, "Frame", name, UIParent, "BasicFrameTemplateWithInset")
    if not ok then
        f = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
        f:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 } })
        local x = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        x:SetPoint("TOPRIGHT", -4, -4)
    end
    f:SetSize(320, height)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    tinsert(UISpecialFrames, name)  -- Escape closes it
    local t = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    t:SetPoint("TOP", 0, -6)
    t:SetText(title)
    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetSize(40, 40)
    icon:SetPoint("TOPLEFT", 16, -30)
    icon:SetTexture("Interface\\AddOns\\Shando\\icon")
    return f
end

local function Check(f, y, label, get, set)
    local c = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    c:SetPoint("TOPLEFT", 16, y)
    local l = c:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    l:SetPoint("LEFT", c, "RIGHT", 4, 0)
    l:SetText(label)
    c:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
    c.Refresh = function() c:SetChecked(get()) end
    return c
end

local function Slider(f, y, min, max, step, get, set, text)
    local l = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    l:SetPoint("TOPLEFT", 22, y)
    local s = CreateFrame("Slider", nil, f, "BackdropTemplate")
    s:SetOrientation("HORIZONTAL")
    s:SetSize(270, 16)
    s:SetPoint("TOPLEFT", 22, y - 18)
    s:SetBackdrop({ bgFile = "Interface\\Buttons\\UI-SliderBar-Background", edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8, insets = { left = 3, right = 3, top = 6, bottom = 6 } })
    s:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    s:SetMinMaxValues(min, max)
    s:SetValueStep(step)
    if s.SetObeyStepDrag then s:SetObeyStepDrag(true) end
    s:SetScript("OnValueChanged", function(_, v)
        v = math.floor(v / step + 0.5) * step
        set(v)
        l:SetText(text(v))
    end)
    s.Refresh = function() local v = get() s:SetValue(v) l:SetText(text(v)) end
    return s
end

local PACE = { 4, 2, 1, 0.5, 0.25 }  -- ShandoPace multiplies every rest: higher is quieter
local PACE_NAME = { "rarely", "less often", "as usual", "more often", "often" }
local function PaceIndex() for i, p in ipairs(PACE) do if math.abs(p - (ShandoPace or 1)) < 0.01 then return i end end return 3 end

local HERB_PACE = { 3, 2, 1, 0.5 }  -- ShandoHerbPace multiplies every herb line's rest: higher is quieter
local HERB_PACE_NAME = { "rarely", "less often", "as usual", "more often" }
local function HerbPaceIndex()
    for i, p in ipairs(HERB_PACE) do if math.abs(p - (ShandoHerbPace or 1)) < 0.01 then return i end end
    return 3
end

local f
local function Build()
    f = Window("ShandoOptionsFrame", COLOUR .. "Shan'do|r", 510)
    local sub = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", 64, -38)
    sub:SetWidth(240)
    sub:SetJustifyH("LEFT")
    sub:SetText("A night elf spirit guide. She speaks at quiet moments, never in combat or dungeons.")
    local items = {
        Check(f, -78, "With you (untick to let her rest)", function() return not ShandoOff end,
            function(on) if on == (ShandoOff and true or false) then SlashCmdList.SHANDO("") end end),
        Slider(f, -112, 1, 5, 1, PaceIndex, function(i) ShandoPace = PACE[i] end,
            function(i) return "How often she speaks: " .. PACE_NAME[i] end),
        Slider(f, -160, 30, 180, 15, function() return ShandoGap or 45 end, function(v) ShandoGap = v end,
            function(v) return ("Quiet gap between any two lines: %d s"):format(v) end),
        Slider(f, -208, 0, 100, 10, function() return math.floor((ShandoEdge or 1) * 100 + 0.5) end,
            function(v) ShandoEdge = v / 100 end, function(v) return ("Ritual screen edges: %d%%"):format(v) end),
        Check(f, -252, "Soundscapes (inns, rituals, the wisp)", function() return not ShandoNoBeds end,
            function(on) ShandoNoBeds = not on or nil end),
        Check(f, -282, "Herb voices (a line when you gather)", function() return not ShandoNoHerbs end,
            function(on) ShandoNoHerbs = not on or nil end),
        Check(f, -312, "Skinning (a word of thanks)", function() return not ShandoNoSkins end,
            function(on) ShandoNoSkins = not on or nil end),
        Slider(f, -346, 1, #HERB_PACE, 1, HerbPaceIndex, function(i) ShandoHerbPace = HERB_PACE[i] end,
            function(i) return "How often herbs speak: " .. HERB_PACE_NAME[i] end),
    }
    -- The meditation (/emerald dream): click the name to step through Random and each one; Begin starts it now.
    local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", 22, -392)
    label:SetText("Meditation (/emerald dream)")
    local pick = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    pick:SetSize(180, 22)
    pick:SetPoint("TOPLEFT", 20, -412)
    local function Name()
        for _, d in ipairs(ns.DREAMS or {}) do if d.id == ShandoDream then return d.name end end
        return "Random, then in turn"
    end
    pick:SetScript("OnClick", function()
        local ids = { "random" }
        for _, d in ipairs(ns.DREAMS or {}) do ids[#ids + 1] = d.id end
        local i = 1
        for k, id in ipairs(ids) do if id == (ShandoDream or "random") then i = k end end
        ShandoDream = ids[i % #ids + 1]
        if ShandoDream == "random" then ShandoDream = nil end
        pick:SetText(Name())
    end)
    pick.Refresh = function() pick:SetText(Name()) end
    items[#items + 1] = pick
    local begin = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    begin:SetSize(90, 22)
    begin:SetPoint("LEFT", pick, "RIGHT", 8, 0)
    begin:SetText("Begin")
    begin:SetScript("OnClick", function() f:Hide() ns.StartDream() end)
    -- The player's own recordings, only when there are some (none ship with the addon)
    if next(ns.MINE or {}) then
        items[#items + 1] = Check(f, -446, "My own voice (where recorded)", function() return ShandoMyVoice end,
            function(on) ShandoMyVoice = on or nil end)
        items[#items + 1] = Check(f, -472, "...with the night-elf treatment", function() return ShandoMyVoice == "elf" end,
            function(on) ShandoMyVoice = on and "elf" or (ShandoMyVoice and true) or nil end)
        f:SetHeight(560)
    end
    local guide = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    guide:SetSize(130, 24)
    guide:SetPoint("BOTTOM", 0, 16)
    guide:SetText("Guide and features")
    guide:SetScript("OnClick", function() f:Hide() ns.ShowReadme() end)
    f:SetScript("OnShow", function() for _, w in ipairs(items) do w.Refresh() end end)
end

function ns.ShowOptions()
    if not f then Build() end
    f:SetShown(not f:IsShown())
end
