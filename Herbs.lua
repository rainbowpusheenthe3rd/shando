-- Herbs and skinning (Herbalore, folded into Shan'do 7 Nov 2026). When you gather a herb, the same voice says one of
-- that herb's lines, the least heard first; each line, and each herb, then rests longer every time (Ready, HerbReady).
-- Now and then, while you're gathering, a quiet line instead. Skinning has its own few lines: the first skin each
-- session, then now and then. Never in combat. Each part has its own switch in the settings:
--   ShandoNoHerbs   herb voices off        ShandoNoSkins   skinning lines off      ShandoHerbPace  how often herbs speak
-- Resting her (/shando) quiets these too. If the separate Herbalore addon is still enabled, this part stands down so
-- the two never speak over each other.
--
-- It also keeps a quiet notebook (account-wide), never sent anywhere:
--   ShandoHerbPicks[herb]    where each herb was picked, "mapID:x:y" (x, y in thousandths), for herb routes;
--   ShandoHerbUnknown[name]  anything picked from a node that has no line yet, with a count, so it can get one.
local _, ns = ...
local DIR = "Interface\\AddOns\\Shando\\sounds\\herbs\\"
local GAP, CALM = 45, 600  -- seconds: at least GAP between lines (ShandoGap overrides); a quiet line at most every CALM
local MAX_PICKS = 400      -- per herb, oldest dropped first
local lastCalm, skinned = GetTime(), false  -- AlbaLast is shared with the rest of Shan'do: one voice at a time
ShandoHerbSaid = {}  -- replaced by the saved table when it loads

-- Today's count per line and per herb (ShandoHerbSaid: key -> { count, unix time }, forgotten after FORGET, a new
-- day). Which line is said is ns.PickLeast's choice (Shando.lua), from the lifetime tally.
local FORGET = 12 * 3600
local function Mark(k)
    local s = ShandoHerbSaid[k]
    if not s or time() - s[2] > FORGET then s = { 0, 0 } end
    s[1], s[2] = s[1] + 1, time()
    ShandoHerbSaid[k] = s
end

local HERB_REST = 300  -- seconds a herb rests after one of its lines, doubling each time, times ShandoHerbPace
local function HerbReady(g)
    local s = ShandoHerbSaid[g]
    return not s or time() - s[2] > FORGET or time() - s[2] >= HERB_REST * (ShandoHerbPace or 1) * 2 ^ (s[1] - 1)
end

local function Say(k, text)
    AlbaLast = GetTime()
    Mark(k)
    ns.Heard(k)
    PlaySoundFile(ns.VoicePath(k, DIR .. k .. ".mp3"), "Dialog")
    DEFAULT_CHAT_FRAME:AddMessage("|cff9fd3a8" .. text .. "|r")
end


-- Say the list's least-heard line in your lifetime (ns.PickLeast in Shando.lua: ties at random, unheard lines first,
-- every line once before any twice). False for an empty list.
local function SayOne(list)
    local c = ns.PickLeast(list, list)
    if not c then return false end
    Say(c[1], c[2])
    return true
end

local function IsSkin(name)
    return name:find("Leather") or name:find("Hide$") or name:find(" Scale$")
end

local function Where()
    local map = C_Map and C_Map.GetBestMapForUnit("player")
    local pos = map and C_Map.GetPlayerMapPosition(map, "player")
    if not pos then return end
    local x, y = pos:GetXY()
    return ("%d:%d:%d"):format(map, x * 1000 + 0.5, y * 1000 + 0.5)
end

local function FromNode()
    local ok, guid = pcall(GetLootSourceInfo, 1)
    return ok and type(guid) == "string" and guid:find("^GameObject") ~= nil
end

local function Note(herb)
    local at = Where()
    if not at then return end
    ShandoHerbPicks = ShandoHerbPicks or {}
    local t = ShandoHerbPicks[herb] or {}
    ShandoHerbPicks[herb] = t
    t[#t + 1] = at
    if #t > MAX_PICKS then table.remove(t, 1) end
end

-- Found alongside a herb (Forever's scarce finds and seeds) or rare in itself: these speak instead of the herb.
local RARE = {
    ["Black Lotus"] = true, ["Death Lotus"] = true, ["Frilled Lichen"] = true, ["Rosecap"] = true,
    ["Stranglevine"] = true, ["Commonplace Herb Seeds"] = true, ["Uncommon Herb Seeds"] = true,
    ["Unusual Herb Seeds"] = true, ["Scarce Herb Seeds"] = true,
}

local function HerbaloreToo()  -- the separate addon still enabled: let it speak, so lines never double
    local loaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    return loaded and loaded("Herbalore")
end

-- Mineral nodes go in the notebook by the node's own name ("Copper Vein", and Forever's Teldrassil-only "Chunk of
-- Amber" and "Large Chunk of Amber", which carry its copper), from the target of the Mining cast just before the loot.
local MINE_TARGET = { "Vein$", "Deposit$", "Amber$" }
local mined, minedAt
local function Mineral(target)
    for _, p in ipairs(MINE_TARGET) do if target:find(p) then return true end end
end

local f = CreateFrame("Frame")
f:RegisterEvent("LOOT_OPENED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("UNIT_SPELLCAST_SENT")
f:SetScript("OnEvent", function(_, event, unit, target)
    if event == "UNIT_SPELLCAST_SENT" then
        if unit == "player" and type(target) == "string" and Mineral(target) then mined, minedAt = target, GetTime() end
        return
    end
    if event == "LOOT_OPENED" and mined and GetTime() - minedAt < 15 and FromNode() then
        Note(mined)  -- ShandoHerbPicks["Large Chunk of Amber"] and so on; tools/forever_runs.py reads them
        mined = nil
    end
    if event == "PLAYER_LOGIN" then
        if HerbaloreToo() then
            -- In her voice (chat only, no recording): she steps back so the herbs' other voice can speak. The plain
            -- note after it, in grey, is the only out-of-world text.
            DEFAULT_CHAT_FRAME:AddMessage("|cffb8c8ffThe green things already have a voice of their own beside you, thero'shan. I will let them speak, and listen with you.|r")
            DEFAULT_CHAT_FRAME:AddMessage("|cff888888(Herbalore is built into Shan'do now. Disable the separate Herbalore addon to hear the herbs through her.)|r")
        end
        return
    end
    if HerbaloreToo() then return end
    local herb, rare, skin, node = nil, nil, false, FromNode()
    for i = 1, GetNumLootItems() do
        local name = select(2, GetLootSlotInfo(i))
        if name then
            if ns.HERBS[name] and RARE[name] then
                rare = rare or name
            elseif ns.HERBS[name] then
                herb = herb or name
            elseif node then
                ShandoHerbUnknown = ShandoHerbUnknown or {}
                ShandoHerbUnknown[name] = (ShandoHerbUnknown[name] or 0) + 1
            elseif IsSkin(name) then
                skin = true
            end
        end
    end
    herb = herb or rare  -- the node's own herb goes in the notebook; a rare find alongside it is what she speaks of
    if herb then Note(herb) HerbaloreSession = (HerbaloreSession or 0) + 1 end  -- read by the look-back
    if skin then SkinSession = (SkinSession or 0) + 1 end
    if ShandoOff or InCombatLockdown() or GetTime() - (AlbaLast or -(ShandoGap or GAP)) < (ShandoGap or GAP) then return end
    local spoken = rare or herb
    if spoken and not ShandoNoHerbs then
        herb = spoken
        -- the herb itself rests too (HERB_REST, doubling), so one herb's lines don't come one after another
        local gate = "herb:" .. herb
        if HerbReady(gate) and SayOne(ns.HERBS[herb]) then
            Mark(gate)
        elseif GetTime() - lastCalm > CALM * ns.Backoff() and math.random() < 0.3 and SayOne(ns.HERB_CALM) then
            lastCalm = GetTime()
        end
    elseif skin and not ShandoNoSkins and ns.SKIN and #ns.SKIN > 0 then
        if not skinned then
            skinned = SayOne(ns.SKIN)
        elseif GetTime() - lastCalm > CALM and math.random() < 0.25 and SayOne(ns.SKIN) then
            lastCalm = GetTime()
        end
    end
end)
