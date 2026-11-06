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
local GAP = 45
local EVERY = {  -- seconds between lines of a kind
    night = 3600, breath = 1200, rest = 1800, water = 1200, home = 4 * 3600, wounded = 2 * 3600, kin = 3600,
    teacher = 2 * 3600, kindness = 2700, linger = 2400, dawn = 20 * 3600, dusk = 20 * 3600,
    deepnight = 24 * 3600, longroad = 24 * 3600, meld = 1800, dream = 1200, vigil = 1200, farewell = 3600,
    mend = 20 * 3600,  -- healing lines: only inside a ritual you chose, at most once a day
}
local STILL, BED_STILL, BED_LEN, BED_EVERY = 90, 60, 300, 1800  -- seconds
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
    return ShandoOff or InCombatLockdown() or IsInInstance() or GetTime() - (AlbaLast or -GAP) < GAP
end

local function Sfx(name, channel)
    return select(2, PlaySoundFile(DIR .. "sfx\\" .. name .. ".mp3", channel or "SFX"))
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
        PlaySoundFile(DIR .. "sounds\\" .. l[1] .. ".mp3", "Dialog")
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
    if bed and now >= bedNext then  -- the bed is 60 s; start the next copy 2 s before the last one ends
        bed, bedNext = Sfx(Night() and "inn_night" or "inn_day", "Ambience"), now + 58
    elseif not bed and IsResting() and still >= BED_STILL and now - lastBed > BED_EVERY and not ShandoOff then
        lastBed, bedUntil, bedNext = now, now + BED_LEN, now + 58
        bed = Sfx(Night() and "inn_night" or "inn_day", "Ambience")
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

local function EndRitual()
    if not ritual then return end
    if ritual.bed then StopSound(ritual.bed, 4000) end
    if ritual.name == "meld" then Music(false) StopBreath() end
    if veil:IsShown() then Fade(0, 3) end
    ritual = nil
end

local function BeginRitual(name, bedFile, tint)
    EndRitual()
    ritual = { name = name, file = bedFile, bed = Sfx(bedFile, "Ambience"), nextBed = GetTime() + 58, t0 = GetTime() }
    if tint then
        veil.tex:SetVertexColor(tint[1], tint[2], tint[3])
        Fade(tint[4], 5)
    end
end

local function TickRitual(now)  -- keep the bed looping; end it when you move, fight or go elsewhere
    if not ritual then return end
    local moved = GetUnitSpeed("player") > 0
    if ritual.name == "wisp" then moved = not UnitIsGhost("player") end
    if ShandoOff or moved or InCombatLockdown() or now - ritual.t0 > 600 then EndRitual() return end
    if now >= ritual.nextBed then ritual.bed, ritual.nextBed = Sfx(ritual.file, "Ambience"), now + 58 end
end

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

local function CheckMeld()
    if Melded() and not InCombatLockdown() and not IsInInstance() and not ShandoOff then
        if ritual and ritual.name == "meld" then return end
        BeginRitual("meld", "meld")
        Music(true)
        C_Timer.After(4, function() if ritual and ritual.name == "meld" then Say("meld") end end)
        C_Timer.After(20, function()
            if ritual and ritual.name == "meld" and not breathing then breathing = Sfx("windbreath", "Ambience") end
        end)
    elseif ritual and ritual.name == "meld" and not Melded() then
        EndRitual()
    end
end

local function OnEmote(token)
    token = type(token) == "string" and token:upper() or ""
    if ShandoOff or InCombatLockdown() or IsInInstance() then return end
    local sub = GetSubZoneText() or ""
    local want = (token == "SLEEP" and "dream") or ((token == "KNEEL" or token == "PRAY") and "vigil")
    if ritual and ritual.name == want then return end  -- the hook and the chat fallback can both fire
    if token == "SLEEP" and sub:find("Barrow") then
        BeginRitual("dream", "dream", { 0.35, 0.85, 0.45, 0.55 })
        C_Timer.After(8, function()
            if ritual and ritual.name == "dream" and not (math.random() < 0.25 and Say("mend")) then Say("dream") end
        end)
    elseif (token == "KNEEL" or token == "PRAY") and ((IsOutdoors() and Night()) or sub == "Temple of the Moon") then
        BeginRitual("vigil", "vigil", { 0.75, 0.82, 1.0, 0.45 })
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
    if not l or (l.elapsed or 0) < 600 or (l.herbs or 0) + (l.skins or 0) + l.kind + l.quests + l.levels + #l.zones == 0 then return end
    local parts = {}
    if #l.zones > 0 then parts[#parts + 1] = "you walked " .. List(l.zones) end
    if (l.herbs or 0) > 0 then parts[#parts + 1] = ("gathered %d herb%s"):format(l.herbs, l.herbs == 1 and "" or "s") end
    if (l.skins or 0) > 0 then parts[#parts + 1] = ("honoured %d hide%s"):format(l.skins, l.skins == 1 and "" or "s") end
    if l.kind > 0 then parts[#parts + 1] = ("helped others %d time%s"):format(l.kind, l.kind == 1 and "" or "s") end
    if l.quests > 0 then parts[#parts + 1] = ("saw %d task%s through"):format(l.quests, l.quests == 1 and "" or "s") end
    if l.levels > 0 then parts[#parts + 1] = ("grew %d level%s"):format(l.levels, l.levels == 1 and "" or "s") end
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
    "PLAYER_UNGHOST", "PLAYER_CAMPING", "PLAYER_LOGOUT", "CALENDAR_UPDATE_EVENT_LIST", "CHAT_MSG_TEXT_EMOTE" }) do
    pcall(f.RegisterEvent, f, e)  -- tolerate an event this client doesn't have
end
pcall(f.RegisterUnitEvent, f, "UNIT_AURA", "player")
f:SetScript("OnEvent", function(_, event, a1, a2, _, a4)
    if event == "UNIT_AURA" then
        CheckMeld()
    elseif event == "CHAT_MSG_TEXT_EMOTE" then
        FromChat(a1, a2)
        return
    elseif event == "PLAYER_ALIVE" or (event == "PLAYER_ENTERING_WORLD" and UnitIsGhost("player")) then
        if UnitIsGhost("player") and not ShandoOff and not (ritual and ritual.name == "wisp") then
            BeginRitual("wisp", "wisp")
        end
        if event == "PLAYER_ALIVE" then return end
    elseif event == "PLAYER_UNGHOST" then
        if ritual and ritual.name == "wisp" then EndRitual() end
        return
    elseif event == "PLAYER_CAMPING" then
        Say("farewell")
        return
    elseif event == "PLAYER_LOGOUT" then
        Music(false)
        -- Saved every time, /reload included (live = true), so the session carries across reloads; the look-back
        -- at the next login skips sessions shorter than 10 minutes (elapsed).
        ShandoLast = { zones = session.order, kind = session.kind, quests = session.quests,
            levels = session.levels, herbs = HerbaloreSession, skins = SkinSession, at = time(),
            elapsed = GetTime() - started, live = true }
        return
    elseif event == "CALENDAR_UPDATE_EVENT_LIST" then
        if GetTime() - started > 30 then Holidays() end
        return
    end
    if event == "PLAYER_ENTERING_WORLD" then
        local l = ShandoLast
        if a2 and l and l.live and time() - (l.at or 0) < 600 then  -- a /reload: carry the session on
            session.order, session.kind, session.quests, session.levels = l.zones, l.kind, l.quests, l.levels
            for _, z in ipairs(session.order) do session.zones[z] = true end
            HerbaloreSession, SkinSession, session.live = l.herbs, l.skins, true
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
    elseif event == "UNIT_SPELLCAST_SENT" then
        local target, spell = a2, a4 and SpellName(a4)
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
-- Being able to choose matters in itself (Glass, Reim & Singer, 1971; Ryan & Deci, 2000).
SLASH_SHANDO1 = "/shando"
SlashCmdList.SHANDO = function(msg)
    msg = (msg or ""):lower()
    if msg == "help" then ns.ShowReadme() return end
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
