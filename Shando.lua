-- Shan'do: a spirit guide who speaks at quiet moments, as a teacher (shan'do) to a student (thero'shan).
-- What she responds to, and why (the research behind each choice is in docs/spirit/RESEARCH.md):
--   * places: the first visit to a sacred or storied place, after a soft swell; a wounded place (Felwood) is
--     wounded, never you; coming home to Darnassus.                                   (awe, nature, belonging)
--   * stillness: a breath after 90 s standing still outdoors, then a wind that breathes slowly, out-breath longer.
--   * resting at an inn: after a minute's stillness, a stream with birds by day, crickets by night, for 5 minutes.
--   * people: joining a group (kin), visiting a trainer (teacher), a spell cast on someone else (kindness).
--   * milestones: a new level, a new form or great spell, profession milestones, now and then a finished quest
--     (linger: a chime, then a moment to savour it).
--   * hard times: one gentle line per death; after three deaths in 15 minutes, one line about rest, then quiet.
--   * time: night, dawn and dusk on the server clock; very late at night, and after two hours, a word of care.
-- She invites, never instructs; says nothing about what you are, only about what is here and what was done.
-- Never in combat or instances, never within GAP seconds of her last line (Herbalore's included: they share
-- AlbaLast); every line rests longer each time it is said (Ready). /shando toggles.
local _, ns = ...
local DIR = "Interface\\AddOns\\Shando\\"
local GAP = 45  -- default; ShandoGap (the options panel) overrides it, shared with Herbalore
local EVERY = {  -- seconds between lines of a kind
    night = 3600, breath = 1200, rest = 1800, water = 1200, home = 4 * 3600, wounded = 2 * 3600, kin = 3600,
    teacher = 2 * 3600, kindness = 2700, linger = 2400, dawn = 20 * 3600, dusk = 20 * 3600,
    deepnight = 24 * 3600, longroad = 24 * 3600, meld = 1800, dream = 1200, vigil = 1200, farewell = 3600,
    mend = 20 * 3600,  -- healing lines: only inside a ritual you chose, at most once a day
}
local STILL, BED_STILL, BED_LEN, BED_EVERY = 90, 60, 300, 1800  -- seconds
-- Beds are 62 s files: a seamless 60 s loop plus a 2 s crossfade tail (tools/spirit_beds.py). The next copy starts
-- exactly BED_PERIOD after the last, checked every frame, so the copies overlap by their matching fades.
local BED_PERIOD = 60
local REPAIR_DEATHS, REPAIR_WINDOW = 3, 900
local LONGROAD = 2 * 3600
local KIND_SPELLS = {  -- cast on someone else: a kindness
    ["Mark of the Wild"] = true, ["Thorns"] = true, ["Rejuvenation"] = true, ["Regrowth"] = true,
    ["Healing Touch"] = true, ["Rebirth"] = true, ["Remove Curse"] = true, ["Cure Poison"] = true,
    ["Abolish Poison"] = true, ["Innervate"] = true, ["Gift of the Wild"] = true,
}
local SKILL_MILESTONES = { [75] = true, [150] = true, [225] = true, [300] = true }

local said, zones, still = {}, {}, 0
local bag = {}  -- per kind, the lines not yet said, so none repeats until all have been
local started = GetTime()
local deaths, quietDeathUntil = {}, 0
local pending  -- a place line that couldn't be said yet (another line too recent); retried while you're there
local bed, bedUntil, bedNext, lastBed = nil, 0, 0, -BED_EVERY
local breathing  -- the wind-breath handle while it plays
local lastHour
local owed = {}  -- once-in-a-life lines (forms, skills) that couldn't be said yet: { kind, opts, until }
ShandoSaid = {}  -- replaced by the saved tables when they load
ShandoOnce = {}

-- Backoff, per line: once a line is said it rests BASE seconds, then twice that, then twice again, so a line you've
-- heard a few times drops out of the evening. Kept per character across /reload; forgotten after FORGET (a new day).
local BASE, FORGET = 1800, 12 * 3600
local function Ready(k)
    local s = ShandoSaid[k]
    return not s or time() - s[2] > FORGET or time() - s[2] >= BASE * 2 ^ (s[1] - 1)
end
local function Mark(k)
    local s = ShandoSaid[k]
    if not s or time() - s[2] > FORGET then s = { 0, 0 } end
    s[1], s[2] = s[1] + 1, time()
    ShandoSaid[k] = s
end

local function Pick(kind)
    if not bag[kind] or #bag[kind] == 0 then
        bag[kind] = {}
        for _, l in ipairs(ns.LINES[kind] or {}) do bag[kind][#bag[kind] + 1] = l end
    end
    local ready, fewest = {}, math.huge  -- of the lines not resting, the least heard today (survives /reload)
    for i, l in ipairs(bag[kind]) do
        if Ready(l[1]) then
            local s = ShandoSaid[l[1]]
            local n = (s and time() - s[2] <= FORGET) and s[1] or 0
            if n < fewest then ready, fewest = { i }, n elseif n == fewest then ready[#ready + 1] = i end
        end
    end
    if #ready == 0 then return end
    return table.remove(bag[kind], ready[math.random(#ready)])
end

local function Quiet()  -- times she never speaks
    return ShandoOff or InCombatLockdown() or IsInInstance() or GetTime() - (AlbaLast or -(ShandoGap or GAP)) < (ShandoGap or GAP)
end

local function Sfx(name, channel)
    return select(2, PlaySoundFile(DIR .. "sfx\\" .. name .. ".mp3", channel or "SFX"))
end

-- 8 Nov 2026: the player's own recordings (voices\mine\<key>.mp3, listed in Mine.lua) replace the designed voice
-- line by line when ShandoMyVoice is on; any line not yet recorded keeps the designed voice.
-- ShandoMyVoice = "elf" plays the same recordings with the night-elf treatment (voices\elf, tools/spirit_nightelf.py).
function ns.VoicePath(key, default)
    if ShandoMyVoice and ns.MINE and ns.MINE[key] then
        return DIR .. "voices\\" .. (ShandoMyVoice == "elf" and "elf" or "mine") .. "\\" .. key .. ".mp3"
    end
    return default
end

-- On Forever, Find Minerals switches itself off at every death (wow-professions.com's Forever mining guide, read
-- 9 Nov 2026). A miner coming back gets a quiet nudge in chat, at most once every 10 minutes.
local FIND_MINERALS, hinted = 2580, 0
local function MineralsHint()
    if ShandoOff or GetTime() - hinted < 600 then return end
    local known = (IsPlayerSpell and IsPlayerSpell(FIND_MINERALS)) or (IsSpellKnown and IsSpellKnown(FIND_MINERALS))
    if not known then return end
    hinted = GetTime()
    print("|cffb8c8ffShan'do|r: the stones hide themselves again after a fall. Find Minerals, when you're ready.")
end

-- Say a line of `kind`. opts.sfx plays first and the voice follows opts.delay seconds later.
local function Say(kind, opts)
    if Quiet() then return end
    if EVERY[kind] and said[kind] and GetTime() - said[kind] < EVERY[kind] * (ShandoPace or 1) then return end
    local l = Pick(kind)
    if not l then return end
    AlbaLast, said[kind] = GetTime(), GetTime()
    Mark(l[1])
    local function Voice()
        PlaySoundFile(ns.VoicePath(l[1], DIR .. "sounds\\" .. l[1] .. ".mp3"), "Dialog")
        DEFAULT_CHAT_FRAME:AddMessage("|cffb8c8ff" .. l[2] .. "|r")
    end
    if opts and opts.sfx then
        Sfx(opts.sfx)
        C_Timer.After(opts.delay or 1.5, Voice)
    else
        Voice()
    end
    return true
end

local function Once(kind, opts)  -- a line that belongs to one moment in a character's life: said once, ever
    if ShandoOnce[kind] or not ns.LINES[kind] then return end
    if Say(kind, opts) then ShandoOnce[kind] = true return true end
end

local function Owe(kind, opts)  -- Once, and if she can't speak just now, keep trying for ten minutes
    if not Once(kind, opts) and ns.LINES[kind] and not ShandoOnce[kind] then
        owed[#owed + 1] = { kind, opts, GetTime() + 600 }
    end
end

local function SpellName(id)  -- C_Spell on newer clients, GetSpellInfo on older ones
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
    return GetSpellInfo and (GetSpellInfo(id))
end

-- The moonwell: from full mana to empty, standing in a moonwell, casting nothing but heals. One line, once.
-- The Temple of the Moon is found by its subzone; other wells by position (zone -> {x, y} as map fractions):
-- two Ashenvale wells where Warcraft Wiki and a Wowhead coordinate list agree, and any well you mark yourself
-- with /shando moonwell (ShandoWells, account-wide), since published coordinates for the rest disagree.
local HEALS = { ["Healing Touch"] = true, ["Regrowth"] = true, ["Rejuvenation"] = true, ["Tranquility"] = true }
local WELLS = { ["Ashenvale"] = { { 0.5375, 0.4600 }, { 0.6020, 0.7290 } } }
local WELL_R = 0.008  -- how near counts as in the well, in map fractions
local wellRun  -- true while every cast since full mana has been a heal at a well

local function Spot()
    local map = C_Map and C_Map.GetBestMapForUnit("player")
    local pos = map and C_Map.GetPlayerMapPosition(map, "player")
    if pos then return pos:GetXY() end
end

local function AtWell()
    if GetSubZoneText() == "Temple of the Moon" then return true end
    local x, y = Spot()
    if not x then return false end
    local zone = GetZoneText() or ""
    for _, list in ipairs({ WELLS[zone] or {}, (ShandoWells or {})[zone] or {} }) do
        for _, w in ipairs(list) do
            if (x - w[1]) ^ 2 + (y - w[2]) ^ 2 <= WELL_R ^ 2 then return true end
        end
    end
    return false
end

local function Mana()
    local m = UnitPowerMax("player", 0)
    return m > 0 and UnitPower("player", 0) / m or 0
end

local function Outdoors()
    return IsOutdoors() and not IsInInstance() and not IsResting()
end

-- Places -------------------------------------------------------------------------------------------------------

local function Here()
    return { GetSubZoneText() or "", GetMinimapZoneText() or "", GetZoneText() or "" }
end

local function TryPlace()
    for _, name in ipairs(Here()) do
        local kind = "place:" .. name
        if name ~= "" and ns.LINES[kind] and not ShandoOnce[kind] then
            if Once(kind, { sfx = "swell", delay = 2.5 }) then pending = nil else pending = kind end
            return true
        end
    end
    pending = nil
end

local function NewArea()
    local z = GetZoneText() or ""
    if GetTime() - started < 20 then zones[z] = true return end  -- logging in fires this too: the greeting comes first
    if TryPlace() then
    elseif z == "Darnassus" then C_Timer.After(5, function() Say("home") end)
    elseif z == "Felwood" then C_Timer.After(5, function() Say("wounded") end)
    elseif not zones[z] then C_Timer.After(4, function() Say("zone") end)
    end
    zones[z] = true
end

-- Beds and breath ------------------------------------------------------------------------------------------------

local innName  -- the inn bed playing now ("inn_day" or "inn_night"), so its single sounds match it

local function StopBed()
    if bed then StopSound(bed, 3000) bed = nil end
    bedUntil = 0
end

local function StopBreath()
    if breathing then StopSound(breathing, 3000) breathing = nil end
end

local function Night()
    local h = GetGameTime()
    return h >= 21 or h < 5
end

local function TickBed(now)
    if bed and (still == 0 or not IsResting() or now > bedUntil) then StopBed() return end
    if bed then  -- still playing: the clock frame below starts each next copy on time
    elseif not bed and IsResting() and still >= BED_STILL and now - lastBed > BED_EVERY and not ShandoOff
        and not ShandoNoBeds then
        lastBed, bedUntil, bedNext = now, now + BED_LEN, now + BED_PERIOD
        innName = Night() and "inn_night" or "inn_day"
        bed = Sfx(innName, "Ambience")
    end
end

-- Rituals: things you choose to do, answered with light and sound -----------------------------------------------
-- Shadowmeld out of combat: the music dips, a night bed rises, a breathing wind; moving brings it all back.
-- /sleep in a barrow den: the edges of the world go green, the Dream plays until you stand.
-- /kneel or /pray outdoors at night (or in the Temple of the Moon): moonlight at the edges, a bell, a word.
-- Released as a wisp: a soft choir under the walk back, until you live again.

local veil = CreateFrame("Frame", nil, UIParent)
veil:SetAllPoints()
veil:SetFrameStrata("BACKGROUND")
veil:EnableMouse(false)
veil.tex = veil:CreateTexture(nil, "BACKGROUND")
veil.tex:SetAllPoints()
veil.tex:SetTexture(DIR .. "vignette")
veil:SetAlpha(0)
veil:Hide()
local ritual  -- { name, bed handle, bed file, next bed time, started }

local function Fade(to, secs)
    local from, t0 = veil:GetAlpha(), GetTime()
    veil:Show()
    veil:SetScript("OnUpdate", function()
        local p = math.min(1, (GetTime() - t0) / secs)
        veil:SetAlpha(from + (to - from) * p)
        if p >= 1 then
            veil:SetScript("OnUpdate", nil)
            if to == 0 then veil:Hide() end
        end
    end)
end

local function Music(dip)  -- dip the game's music while melded; the old level is saved in case the game closes
    if dip and not ShandoMusic then
        ShandoMusic = GetCVar("Sound_MusicVolume")
        SetCVar("Sound_MusicVolume", tostring((tonumber(ShandoMusic) or 0.4) * 0.25))
    elseif not dip and ShandoMusic then
        SetCVar("Sound_MusicVolume", ShandoMusic)
        ShandoMusic = nil
    end
end

-- The Emerald Dream (/emerald dream) quietens the world: the game's ambient sounds and music fade out over a few
-- seconds and come back when it ends. The old levels are saved (ShandoHush) so a closed game or a /reload mid-way
-- still gets them back at the next login or logout. Its own sounds play on the Master and Dialog channels.
local hushTicker
local function WorldHush(on, secs)
    if hushTicker then hushTicker:Cancel() hushTicker = nil end
    if on and not ShandoHush then
        ShandoHush = { amb = GetCVar("Sound_AmbienceVolume"), mus = GetCVar("Sound_MusicVolume") }
    end
    local h = ShandoHush
    if not h then return end
    local amb, mus = tonumber(h.amb) or 0.6, tonumber(h.mus) or 0.4
    if not on and (secs or 0) <= 0 then  -- straight back (combat, logout)
        SetCVar("Sound_AmbienceVolume", h.amb) SetCVar("Sound_MusicVolume", h.mus)
        ShandoHush = nil
        return
    end
    local steps, i = math.max(1, math.floor((secs or 6) / 0.2)), 0
    hushTicker = C_Timer.NewTicker(0.2, function()
        i = i + 1
        local p = on and (1 - i / steps) or (i / steps)
        SetCVar("Sound_AmbienceVolume", tostring(amb * p))
        SetCVar("Sound_MusicVolume", tostring(mus * p))
        if i >= steps then
            hushTicker:Cancel() hushTicker = nil
            if not on then SetCVar("Sound_AmbienceVolume", h.amb) SetCVar("Sound_MusicVolume", h.mus) ShandoHush = nil end
        end
    end, steps)
end

-- A soft caption under the character for each spoken line, for eyes left open (and before the voice is rendered).
local caption = CreateFrame("Frame", nil, UIParent)
caption:SetSize(760, 80)
caption:SetPoint("CENTER", UIParent, "CENTER", 0, -170)
caption:SetFrameStrata("BACKGROUND")
caption:EnableMouse(false)
caption.text = caption:CreateFontString(nil, "OVERLAY")
caption.text:SetFont(STANDARD_TEXT_FONT, 17, "")
caption.text:SetShadowOffset(1, -1)
caption.text:SetAllPoints()
caption.text:SetTextColor(0.80, 0.94, 0.84)
caption.text:SetJustifyH("CENTER")
caption:SetAlpha(0)
local function Caption(text)
    caption.text:SetText(text or "")
    if not text then caption:SetScript("OnUpdate", nil) caption:SetAlpha(0) return end
    local t0, hold = GetTime(), 3 + #text / 15   -- about as long as it takes to say
    caption:SetScript("OnUpdate", function()
        local t = GetTime() - t0
        local a = math.min(1, t / 1.2) * math.max(0, math.min(1, (hold + 1.5 - t) / 1.5))
        caption:SetAlpha(a * 0.9)
        if t > hold + 1.5 then caption:SetScript("OnUpdate", nil) end
    end)
end

local function EndRitual(now)
    if not ritual then return end
    if ritual.bed then StopSound(ritual.bed, 4000) end
    if ritual.name == "meld" then Music(false) StopBreath() end
    if ritual.name == "emerald" then StopBreath() Caption(nil) WorldHush(false, now and 0 or 5) end
    if veil:IsShown() then Fade(0, 3) end
    ritual = nil
end

local function BeginRitual(name, bedFile, tint)
    EndRitual()
    ritual = { name = name, file = bedFile, bed = bedFile and not ShandoNoBeds and Sfx(bedFile, "Ambience") or nil,
               nextBed = GetTime() + BED_PERIOD, t0 = GetTime() }
    if tint then
        veil.tex:SetVertexColor(tint[1], tint[2], tint[3])
        Fade(tint[4] * (ShandoEdge or 1), 5)  -- ShandoEdge: screen edge strength, 0 to 1
    end
end

local function TickRitual(now)  -- keep the bed looping; end it when you move, fight or go elsewhere
    if not ritual then return end
    local moved = GetUnitSpeed("player") > 0
    if ritual.name == "wisp" then moved = not UnitIsGhost("player") end
    if ShandoOff or moved or InCombatLockdown() or now - ritual.t0 > 600 then EndRitual(InCombatLockdown()) return end
end

-- Single sounds over a bed (Ambience.lua, from tools/spirit_ambience.py): a drop, a crackle, a knock, each at a gap of
-- min + a random exponential with mean `mean` seconds, never one of the last three again, in one of v pre-rendered
-- versions (PlaySoundFile has no pitch, pan or volume control). The base loop underneath is real recording too.
local evName, evNext, evRecent = nil, 0, {}
local function Gap(a) return a.min - a.mean * math.log(1 - math.random()) end
local function TickEvents(now, name)
    local a = name and ns.AMB and ns.AMB[name]
    if not a or a.n == 0 then evName = nil return end
    if name ~= evName then evName, evNext, evRecent = name, now + Gap(a), {} return end
    if now < evNext then return end
    local pool = {}
    for i = 1, a.n do
        local recent = false
        for k = math.max(1, #evRecent - 2), #evRecent do if evRecent[k] == i then recent = true end end
        if not recent then pool[#pool + 1] = i end
    end
    local i = #pool > 0 and pool[math.random(#pool)] or math.random(a.n)
    evRecent[#evRecent + 1] = i
    Sfx(("%s\\e%02d_%d"):format(name, i, math.random(a.v)), "Ambience")
    evNext = now + Gap(a)
end

local clock = CreateFrame("Frame")
clock:SetScript("OnUpdate", function()
    local now = GetTime()
    if ritual and ritual.file and now >= ritual.nextBed and not ShandoNoBeds then
        ritual.bed, ritual.nextBed = Sfx(ritual.file, "Ambience"), ritual.nextBed + BED_PERIOD
    end
    if bed and now >= bedNext then
        bed, bedNext = Sfx(innName, "Ambience"), bedNext + BED_PERIOD
    end
    TickEvents(now, (ritual and ritual.bed and ritual.file) or (bed and innName) or nil)
end)

local MELD = SpellName(20580) or "Shadowmeld"
local function Melded()
    if AuraUtil and AuraUtil.FindAuraByName then return AuraUtil.FindAuraByName(MELD, "player", "HELPFUL") ~= nil end
    for i = 1, 40 do
        local name = UnitBuff and UnitBuff("player", i)
        if not name then return false end
        if name == MELD then return true end
    end
    return false
end

-- The meld's breath: the screen's dark violet edge opens a little on each in-breath and closes on the longer out-breath, in
-- step with the windbreath sound (the same curve as tools/spirit_sfx.py windbreath: 11 breaths a minute slowing to
-- 6 over 105 s, in-breath 40% of each cycle, 150 s long). When it ends, a bell and a closing word.
local BREATH_LEN, BREATH_SLOW, IN_FRAC = 150, 105, 0.4
local meldCount = 0
local pulse = CreateFrame("Frame")
pulse:SetScript("OnUpdate", function(_, dt)
    local r = ritual
    if not r or (r.name ~= "meld" and r.name ~= "emerald") or not r.breathT0 then return end
    local t = GetTime() - r.breathT0
    if t < BREATH_LEN then
        local bpm = 11 - 5 * math.min(1, t / BREATH_SLOW)
        r.phase = ((r.phase or 0) + bpm / 60 * dt) % 1
        local env
        if r.phase < IN_FRAC then env = math.sin(r.phase / IN_FRAC * math.pi / 2) ^ 2
        else env = math.cos((r.phase - IN_FRAC) / (1 - IN_FRAC) * math.pi / 2) ^ 2 end
        local edge = math.min(1, t / 4) * math.min(1, (BREATH_LEN - t) / 6)
        local base = r.base or 0.3
        veil:SetAlpha((base - 0.4 * base * env * edge) * (ShandoEdge or 1))  -- the edges open a little on the in-breath, close softly on the out
    elseif not r.closed then
        r.closed = true
        veil:SetAlpha((r.base or 0.3) * (ShandoEdge or 1))
        if r.name == "emerald" then return end  -- the Dream goes on: its own script says what comes next
        Sfx("kindbell")
        C_Timer.After(2.5, function() if ritual == r then Say("meldend") end end)
    end
end)

local function CheckMeld()
    if Melded() and not InCombatLockdown() and not IsInInstance() and not ShandoOff then
        if ritual and ritual.name == "meld" then return end
        BeginRitual("meld", Night() and "meld" or "meld_day", { 0.09, 0.05, 0.16, 0.3 })  -- deep violet
        meldCount = meldCount + 1
        Music(true)
        C_Timer.After(4, function() if ritual and ritual.name == "meld" then Say("meld") end end)
        C_Timer.After(20, function()
            if ritual and ritual.name == "meld" and not breathing then
                breathing = Sfx("windbreath", "Ambience")
                ritual.breathT0, ritual.phase = GetTime(), 0
            end
        end)
    elseif ritual and ritual.name == "meld" and not Melded() then
        EndRitual()
    end
end

-- The Emerald Dream: a guided meditation of about nine minutes, chosen with /emerald dream (again to stop).
-- Shaped by the research record (docs/RESEARCH.md in spirit-studio) and its cautions: meditation can bring on anxiety
-- or low mood in some people (adverse events 8.3% overall; Farias et al., 2020), so it is opt-in and short, says at
-- the start that moving ends it, offers eyes open, and anchors attention outside the body first (sounds, the
-- ground) before the breath (trauma-sensitive practice: Treleaven, 2018). The breath is slow and exhale-led, the
-- windbreath slowing towards 6 a minute (slow breathing: Zaccaro et al., 2018; one cyclic sigh: Balban et al.,
-- 2023), then imagery of the Dream, a kindness wish for yourself and for others (Kirby et al., 2017), and a return
-- to the room. The world's ambient sound and music fade out for it, and come straight back in combat.
local EMERALD = {   -- seconds from the start: a line key, or what happens
    { 0, "bell" }, { 4, "emerald01" }, { 24, "emerald02" }, { 44, "emerald03" }, { 74, "emerald04" },
    { 106, "emerald05" }, { 124, "breath" }, { 142, "emerald06" }, { 188, "emerald07" }, { 234, "emerald08" },
    { 282, "emerald09" }, { 318, "emerald10" }, { 356, "emerald11" }, { 396, "emerald12" }, { 432, "emerald13" },
    { 470, "emerald14" }, { 492, "emerald15" }, { 512, "bell" }, { 515, "emerald16" }, { 538, "end" },
}
local function EmeraldText(key)
    for _, l in ipairs(ns.LINES.emerald or {}) do if l[1] == key then return l[2] end end
end

local function Emerald()
    BeginRitual("emerald", nil, { 0.03, 0.14, 0.07, 0.45 })   -- the Dream's green at the edges
    local r = ritual
    r.base = 0.45
    WorldHush(true, 6)
    for _, step in ipairs(EMERALD) do
        C_Timer.After(step[1], function()
            if ritual ~= r then return end   -- ended (moved, combat, /emerald again)
            local what = step[2]
            if what == "bell" then
                Sfx("kindbell", "Master")
            elseif what == "breath" then
                StopBreath()
                breathing = Sfx("windbreath", "Master")
                r.breathT0, r.phase = GetTime(), 0
            elseif what == "end" then
                EndRitual()
            else
                AlbaLast = GetTime()   -- Herbalore keeps its distance
                Mark(what)
                PlaySoundFile(ns.VoicePath(what, DIR .. "sounds\\" .. what .. ".mp3"), "Dialog")
                Caption(EmeraldText(what))
            end
        end)
    end
end

SLASH_EMERALD1 = "/emerald"        -- /emerald dream
SLASH_EMERALD2 = "/dreamemerald"
SLASH_EMERALD3 = "/emeralddream"
SlashCmdList.EMERALD = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if msg ~= "" and msg ~= "dream" then print("|cffb8c8ffShan'do|r: /emerald dream, to walk in the Dream a while.") return end
    if ritual and ritual.name == "emerald" then
        EndRitual()
        print("|cffb8c8ffShan'do|r: we're back. Gently does it.")
        return
    end
    if ShandoOff then print("|cffb8c8ffShan'do|r: I'm resting just now. /shando to wake me, and we'll go.") return end
    if InCombatLockdown() or IsInInstance() or UnitIsDeadOrGhost("player") then
        print("|cffb8c8ffShan'do|r: not here, not now. Somewhere quiet, when the fighting's done.")
        return
    end
    Emerald()
end

local function OnEmote(token)
    token = type(token) == "string" and token:upper() or ""
    if ShandoOff or InCombatLockdown() or IsInInstance() then return end
    local sub = GetSubZoneText() or ""
    local want = (token == "SLEEP" and "dream") or ((token == "KNEEL" or token == "PRAY") and "vigil")
    if ritual and ritual.name == want then return end  -- the hook and the chat fallback can both fire
    if token == "SLEEP" and sub:find("Barrow") then
        BeginRitual("dream", "dream", { 0.03, 0.14, 0.07, 0.45 })  -- a dark green dusk at the edges
        C_Timer.After(8, function()
            if ritual and ritual.name == "dream" and not (math.random() < 0.25 and Say("mend")) then Say("dream") end
        end)
    elseif (token == "KNEEL" or token == "PRAY") and ((IsOutdoors() and Night()) or sub == "Temple of the Moon") then
        BeginRitual("vigil", "vigil", { 0.05, 0.07, 0.2, 0.4 })  -- deep night blue
        C_Timer.After(5, function()
            if ritual and ritual.name == "vigil" and not (math.random() < 0.34 and Say("mend")) then Say("vigil") end
        end)
    end
end
local function Later(token) C_Timer.After(0.5, function() OnEmote(token) end) end  -- out of Blizzard's call path
for _, fn in ipairs({ "DoEmote", "PerformEmote" }) do  -- the name differs between clients
    if type(_G[fn]) == "function" then hooksecurefunc(fn, Later) end
end
if C_ChatInfo and type(C_ChatInfo.PerformEmote) == "function" then hooksecurefunc(C_ChatInfo, "PerformEmote", Later) end
local EMOTE_TEXT = { { "go to sleep", "SLEEP" }, { "kneel", "KNEEL" }, { "pray", "PRAY" } }  -- fallback: your own emote text
local function FromChat(text, sender)
    if not text or not sender or Ambiguate(sender, "short") ~= UnitName("player") then return end
    for _, e in ipairs(EMOTE_TEXT) do
        if text:lower():find("^you .*" .. e[1]) then Later(e[2]) return end
    end
end

-- The look-back: what this session held, said gently at the next login ------------------------------------------

local session = { zones = {}, order = {}, kind = 0, quests = 0, levels = 0 }
local function Visit(z)
    if z and z ~= "" and not session.zones[z] then session.zones[z] = true session.order[#session.order + 1] = z end
end

local function List(t)
    if #t == 1 then return t[1] end
    return table.concat(t, ", ", 1, #t - 1) .. " and " .. t[#t]
end

local function LookBack(l, tries)
    if not l then l, tries = ShandoLast, 0 ShandoLast = nil end
    if not l or (l.elapsed or 0) < 600 or (l.herbs or 0) + (l.skins or 0) + (l.melds or 0) + l.kind + l.quests + l.levels + #l.zones == 0 then return end
    local parts = {}
    if #l.zones > 0 then parts[#parts + 1] = "you walked " .. List(l.zones) end
    if (l.herbs or 0) > 0 then parts[#parts + 1] = ("gathered %d herb%s"):format(l.herbs, l.herbs == 1 and "" or "s") end
    if (l.skins or 0) > 0 then parts[#parts + 1] = ("honoured %d hide%s"):format(l.skins, l.skins == 1 and "" or "s") end
    if l.kind > 0 then parts[#parts + 1] = ("helped others %d time%s"):format(l.kind, l.kind == 1 and "" or "s") end
    if l.quests > 0 then parts[#parts + 1] = ("saw %d task%s through"):format(l.quests, l.quests == 1 and "" or "s") end
    if l.levels > 0 then parts[#parts + 1] = ("grew %d level%s"):format(l.levels, l.levels == 1 and "" or "s") end
    if (l.melds or 0) > 0 then parts[#parts + 1] = ("rested in shadow %d time%s"):format(l.melds, l.melds == 1 and "" or "s") end
    local when = l.at and date("%A", l.at) or "last time"
    if Say("recall", { sfx = "chime", delay = 1.8 }) then
        C_Timer.After(4, function()
            DEFAULT_CHAT_FRAME:AddMessage(("|cffb8c8ffOn %s, %s.|r"):format(when, List(parts)))
        end)
    elseif tries < 30 then  -- another line had the moment; try again for up to ten minutes
        C_Timer.After(20, function() LookBack(l, tries + 1) end)
    end
end

-- Holidays: the calendar's festivals, each greeted once a year -----------------------------------------------------
-- Children's Week is handled with great care. Its lines are gentle and present: play, wonder, kindness given;
-- the healing (mend) lines speak to loss only with hope. Never the word "orphan". Holidays listed here stay silent.
local SILENT_HOLIDAYS = {}

local function Holidays()
    if not (C_Calendar and C_Calendar.GetNumDayEvents and C_DateAndTime) then return end
    local ok, now = pcall(C_DateAndTime.GetCurrentCalendarTime)
    if not ok or not now then return end
    local okN, n = pcall(C_Calendar.GetNumDayEvents, 0, now.monthDay)
    for i = 1, (okN and n or 0) do
        local okE, e = pcall(C_Calendar.GetDayEvent, 0, now.monthDay, i)
        local kind = okE and e and e.calendarType == "HOLIDAY" and not SILENT_HOLIDAYS[e.title or ""]
            and ("holiday:" .. (e.title or ""))
        local key = kind and (kind .. ":" .. now.year)
        if kind and ns.LINES[kind] and not ShandoOnce[key] then
            if Say(kind, { sfx = "swell", delay = 2.5 }) then ShandoOnce[key] = true end
            return
        end
    end
end

-- Events ---------------------------------------------------------------------------------------------------------

local f = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS",
    "PLAYER_UPDATE_RESTING", "PLAYER_LEVEL_UP", "PLAYER_DEAD", "PLAYER_CONTROL_LOST", "GROUP_JOINED", "TRAINER_SHOW",
    "LEARNED_SPELL_IN_TAB", "CHAT_MSG_SKILL", "QUEST_TURNED_IN", "UNIT_SPELLCAST_SENT", "PLAYER_ALIVE",
    "PLAYER_UNGHOST", "PLAYER_CAMPING", "PLAYER_LOGOUT", "CALENDAR_UPDATE_EVENT_LIST", "CHAT_MSG_TEXT_EMOTE",
    "PLAYER_REGEN_DISABLED" }) do
    pcall(f.RegisterEvent, f, e)  -- tolerate an event this client doesn't have
end
pcall(f.RegisterUnitEvent, f, "UNIT_AURA", "player")
pcall(f.RegisterUnitEvent, f, "UNIT_SPELLCAST_SUCCEEDED", "player")
f:SetScript("OnEvent", function(_, event, a1, a2, a3, a4)
    if event == "PLAYER_REGEN_DISABLED" then   -- combat: the world's sound comes straight back
        if ritual and ritual.name == "emerald" then EndRitual(true) end
        return
    elseif event == "UNIT_AURA" then
        CheckMeld()
    elseif event == "CHAT_MSG_TEXT_EMOTE" then
        FromChat(a1, a2)
        return
    elseif event == "PLAYER_ALIVE" or (event == "PLAYER_ENTERING_WORLD" and UnitIsGhost("player")) then
        if UnitIsGhost("player") and not ShandoOff and not (ritual and ritual.name == "wisp") then
            BeginRitual("wisp", "wisp")
        end
        if event == "PLAYER_ALIVE" then
            if not UnitIsGhost("player") then MineralsHint() end  -- raised where she fell
            return
        end
    elseif event == "PLAYER_UNGHOST" then
        if ritual and ritual.name == "wisp" then EndRitual() end
        MineralsHint()
        return
    elseif event == "PLAYER_CAMPING" then
        Say("farewell")
        return
    elseif event == "PLAYER_LOGOUT" then
        Music(false)
        WorldHush(false, 0)   -- never leave the game's sound faded
        -- Saved every time, /reload included (live = true), so the session carries across reloads; the look-back
        -- at the next login skips sessions shorter than 10 minutes (elapsed).
        ShandoLast = { zones = session.order, kind = session.kind, quests = session.quests,
            levels = session.levels, herbs = HerbaloreSession, skins = SkinSession, melds = meldCount, at = time(),
            elapsed = GetTime() - started, live = true }
        return
    elseif event == "CALENDAR_UPDATE_EVENT_LIST" then
        if GetTime() - started > 30 then Holidays() end
        return
    end
    if event == "PLAYER_ENTERING_WORLD" then
        if ShandoHush and not (ritual and ritual.name == "emerald") then WorldHush(false, 0) end  -- left faded last time
        local l = ShandoLast
        if a2 and l and l.live and time() - (l.at or 0) < 600 then  -- a /reload: carry the session on
            session.order, session.kind, session.quests, session.levels = l.zones, l.kind, l.quests, l.levels
            for _, z in ipairs(session.order) do session.zones[z] = true end
            HerbaloreSession, SkinSession, session.live, meldCount = l.herbs, l.skins, true, l.melds or 0
            started = GetTime() - (l.elapsed or 0)
            ShandoLast = nil
        elseif l and l.live then  -- a real login: the saved session is now the one to look back on
            l.live = nil
        end
        if a1 then  -- login
            started = GetTime()
            Music(false)  -- if the game closed mid-meld, put the music back
            C_Timer.After(8, function() Say("login") end)
            C_Timer.After(75, function() LookBack() end)
            C_Timer.After(40, function()
                if C_Calendar and C_Calendar.OpenCalendar then pcall(C_Calendar.OpenCalendar) end
                C_Timer.After(140, Holidays)  -- after the look-back has had its turn
            end)
        end
        Visit(GetZoneText())
        zones[GetZoneText() or ""] = true  -- the zone you log in to isn't "new"
        C_Timer.After(12, TryPlace)
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        Visit(GetZoneText())
        NewArea()
    elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then
        C_Timer.After(2, TryPlace)
    elseif event == "PLAYER_UPDATE_RESTING" then
        if IsResting() then C_Timer.After(3, function() Say("rest") end) else StopBed() end
    elseif event == "PLAYER_LEVEL_UP" then
        session.levels = session.levels + 1
        C_Timer.After(2, function() Say("level") end)
    elseif event == "PLAYER_DEAD" then
        local now = GetTime()
        deaths[#deaths + 1] = now
        while deaths[1] and now - deaths[1] > REPAIR_WINDOW do table.remove(deaths, 1) end
        if #deaths >= REPAIR_DEATHS and now >= quietDeathUntil then
            quietDeathUntil = now + REPAIR_WINDOW  -- one line about rest, then quiet about dying for a while
            C_Timer.After(3, function() Say("repair") end)
        elseif now >= quietDeathUntil then
            C_Timer.After(3, function() Say("death") end)
        end
    elseif event == "PLAYER_CONTROL_LOST" then  -- a flight path starting
        C_Timer.After(6, function() if UnitOnTaxi("player") then Say("flight") end end)
    elseif event == "GROUP_JOINED" then
        C_Timer.After(5, function() Say("kin") end)
    elseif event == "TRAINER_SHOW" then
        C_Timer.After(1, function() Say("teacher") end)
    elseif event == "LEARNED_SPELL_IN_TAB" then
        local name = a1 and SpellName(a1)
        if name then C_Timer.After(3, function() Owe("form:" .. name) end) end
    elseif event == "CHAT_MSG_SKILL" then
        local skill, level = (a1 or ""):match("Your skill in (.+) has increased to (%d+)")
        level = tonumber(level)
        if skill and SKILL_MILESTONES[level] then
            C_Timer.After(2, function() Owe(("skill:%s:%d"):format(skill, level), { sfx = "chime", delay = 1.8 }) end)
        end
    elseif event == "QUEST_TURNED_IN" then
        session.quests = session.quests + 1
        if math.random() < 0.2 then C_Timer.After(3, function() Say("linger", { sfx = "chime", delay = 1.8 }) end) end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local spell = a3 and SpellName(a3)
        if a1 == "player" and wellRun and spell and HEALS[spell] and Mana() < 0.05 then
            wellRun = nil
            C_Timer.After(3, function() Owe("moonwell", { sfx = "swell", delay = 2.5 }) end)
        end
    elseif event == "UNIT_SPELLCAST_SENT" then
        local target, spell = a2, a4 and SpellName(a4)
        if a1 == "player" and spell then
            if HEALS[spell] and AtWell() then
                wellRun = wellRun or Mana() >= 0.9 or nil
            else
                wellRun = nil  -- anything but a heal, or a heal away from the well, starts it over
            end
        end
        if a1 == "player" and spell and KIND_SPELLS[spell] and target and target ~= "" and target ~= UnitName("player") then
            session.kind = session.kind + 1
            if math.random() < 0.5 then
                C_Timer.After(4, function() Say("kindness", { sfx = "kindbell", delay = 2.5 }) end)
            end
        end
    end
end)

-- every 5 seconds: stillness, the inn bed, water, night, dawn and dusk, the very late hours, the long road
C_Timer.NewTicker(5, function()
    local now = GetTime()
    TickRitual(now)
    if UnitIsGhost("player") and not ShandoOff and not ritual then BeginRitual("wisp", "wisp") end
    if ShandoOff or InCombatLockdown() or UnitIsDeadOrGhost("player") then
        still = 0
        StopBed()
        StopBreath()
        return
    end
    if GetUnitSpeed("player") == 0 and not UnitOnTaxi("player") then still = still + 5 else still = 0 end
    if still == 0 then StopBreath() end
    TickBed(now)
    if ritual then return end  -- a ritual you chose has the floor; ambient lines wait
    if now - started < 20 then return end  -- the login greeting comes first
    for i = #owed, 1, -1 do
        local o = owed[i]
        if ShandoOnce[o[1]] or now > o[3] or Once(o[1], o[2]) then table.remove(owed, i) end
    end
    if pending then
        local here = false
        for _, name in ipairs(Here()) do if pending == "place:" .. name then here = true end end
        if here then TryPlace() else pending = nil end
    end
    local h, m = GetGameTime()
    if lastHour and h ~= lastHour and Outdoors() then
        if h == 6 then Say("dawn") elseif h == 20 then Say("dusk") end
    end
    lastHour = h
    local real = tonumber(date("%H"))
    if now - started > 1800 and real >= 0 and real < 5 and Say("deepnight") then
        said.longroad = now  -- one word of care is enough; the long-road line waits its turn
    end
    if now - started > LONGROAD then Say("longroad") end
    if still >= STILL and Outdoors() then
        if Say("breath") then
            still = 0
            C_Timer.After(10, function()
                if GetUnitSpeed("player") == 0 and not breathing then breathing = Sfx("windbreath", "Ambience") end
            end)
        end
    elseif IsSwimming() then
        Say("water")
    elseif Outdoors() and Night() then
        Say("night")
    end
end)

-- /shando: on or off. /shando quieter, /shando nearer: halve or double how often she speaks (between 1/4 and 4x).
-- /shando voice: her designed voice, your own recordings, or those with the night-elf treatment (in turn).
-- /shando listen: play your recordings, in whichever of yours is chosen.
-- Being able to choose matters in itself (Glass, Reim & Singer, 1971; Ryan & Deci, 2000).
SLASH_SHANDO1 = "/shando"
SlashCmdList.SHANDO = function(msg)
    msg = (msg or ""):lower()
    if msg == "help" then ns.ShowReadme() return end
    if msg == "options" then ns.ShowOptions() return end
    if msg == "moonwell" then  -- mark the moonwell you're standing in, so she knows it
        local x, y = Spot()
        if not x then print("|cffb8c8ffShan'do|r: I can't tell where we are just here.") return end
        local zone = GetZoneText() or ""
        ShandoWells = ShandoWells or {}
        ShandoWells[zone] = ShandoWells[zone] or {}
        table.insert(ShandoWells[zone], { x, y })
        print(("|cffb8c8ffShan'do|r: a moonwell in %s, at %.1f, %.1f. I'll know it now."):format(zone, x * 100, y * 100))
        return
    end
    if msg == "voice" then  -- cycle: her designed voice, the player's own recordings, those with the night-elf treatment
        ShandoMyVoice = (not ShandoMyVoice and true) or (ShandoMyVoice == true and "elf") or nil
        local n = 0
        for _ in pairs(ns.MINE or {}) do n = n + 1 end
        print(("|cffb8c8ffShan'do|r: %s"):format(not ShandoMyVoice and "her own voice again"
            or ("your own voice%s, for the %d line%s you've recorded; the rest stay as they were"):format(
                ShandoMyVoice == "elf" and ", night-elf" or "", n, n == 1 and "" or "s")))
        return
    end
    if msg == "listen" then  -- play the player's own recordings one after another, to hear how they sit
        local keys = {}
        for k in pairs(ns.MINE or {}) do keys[#keys + 1] = k end
        table.sort(keys)
        if #keys == 0 then print("|cffb8c8ffShan'do|r: you haven't recorded any lines yet.") return end
        print(("|cffb8c8ffShan'do|r: your %d recorded lines, about 12 seconds apart."):format(#keys))
        for i, k in ipairs(keys) do
            C_Timer.After((i - 1) * 12, function()
                PlaySoundFile(ns.VoicePath(k, DIR .. "voices\\mine\\" .. k .. ".mp3"), "Dialog")
            end)
        end
        return
    end
    if msg == "quieter" or msg == "nearer" then
        ShandoPace = math.max(0.25, math.min(4, (ShandoPace or 1) * (msg == "quieter" and 2 or 0.5)))
        print(("|cffb8c8ffShan'do|r: %s (lines of a kind at most every %sx the usual time)"):format(
            msg == "quieter" and "a little further away" or "a little closer", ShandoPace))
        return
    end
    ShandoOff = not ShandoOff
    if ShandoOff then StopBed() StopBreath() EndRitual() end
    print("|cffb8c8ffShan'do|r: " .. (ShandoOff and "resting" or "with you"))
end
