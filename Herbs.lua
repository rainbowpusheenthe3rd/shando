-- Herbs and skinning (Herbalore, folded into Shan'do 7 Nov 2026). When you gather a herb, the same voice says one of
-- that herb's lines, the least heard first (ns.PickLeast); each herb then rests longer every time (HerbReady).
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
local SOUNDS = "Interface\\AddOns\\Shando\\sounds\\"  -- Shan'do's own lines, botany among them
local GAP, CALM = 45, 600  -- seconds: at least GAP between lines (ShandoGap overrides); a quiet line at most every CALM
local MAX_PICKS = 400      -- per herb, oldest dropped first

-- Botany, a Linnaean tree (22 Nov 2026, Luke: "a more linnaean system"; docs/lines/BOTANY.md in the studio). Each
-- herb sits at the narrowest real taxon its look or name supports (TAXON), and each taxon knows its parent (PARENT),
-- so a herb's lineage runs from its family up to its kingdom: Peacebloom is daisy family, eudicots, flowering
-- plants, seed plants, vascular plants, land plants. Every taxon has its own lines (ns.LINES["botany:<taxon>"]), so a
-- line about flowering plants can come from any flower you pick. Gathering counts towards every taxon in the
-- lineage (ShandoBotany[taxon], per character); the narrowest unlocks at once, the next at 10 gathers within it, the
-- rest at 30 (UNLOCK, a spiral: what you see, how it lives, deep time). The herbs are fictional, so every placement
-- is a resemblance, not a claim about Azeroth. A botany line takes the place of a herb's own line while it rests.
local PARENT = {
    mosses = "landplants", vascular = "landplants", seedplants = "vascular", angiosperms = "seedplants",
    monocots = "angiosperms", eudicots = "angiosperms",
    grasses = "monocots", lilies = "monocots", amaryllis = "monocots",
    lotus = "eudicots", rose = "eudicots", daisy = "eudicots", mint = "eudicots", ginseng = "eudicots",
    mushrooms = "fungi", lichens = "fungi",
    -- landplants, fungi and kelp (brown algae, not plants at all) are roots of their own
}
local TAXON = {
    ["Peacebloom"] = "daisy", ["Wilted Peacebloom"] = "daisy", ["Swiftthistle"] = "daisy",
    ["Mageroyal"] = "rose", ["Briarthorn"] = "rose",
    ["Dreamfoil"] = "mint", ["Mountain Silversage"] = "mint", ["Demonsage"] = "mint",
    ["Golden Sansam"] = "ginseng",
    ["Purple Lotus"] = "lotus", ["Black Lotus"] = "lotus", ["Death Lotus"] = "lotus",
    ["Sungrass"] = "grasses", ["Firebloom"] = "lilies", ["Arthas' Tears"] = "lilies", ["Wintersbite"] = "amaryllis",
    ["Silverleaf"] = "eudicots", ["Stunted Silverleaf"] = "eudicots", ["Bruiseweed"] = "eudicots",
    ["Wild Steelbloom"] = "eudicots", ["Kingsblood"] = "eudicots", ["Goldthorn"] = "eudicots",
    ["Khadgar's Whisker"] = "eudicots", ["Blindweed"] = "eudicots", ["Gromsblood"] = "eudicots",
    ["Fadeleaf"] = "angiosperms", ["Icecap"] = "angiosperms", ["Plaguebloom"] = "angiosperms",
    ["Marefoil"] = "angiosperms", ["Rosecap"] = "angiosperms", ["Stranglevine"] = "angiosperms",
    ["Commonplace Herb Seeds"] = "seedplants", ["Uncommon Herb Seeds"] = "seedplants",
    ["Unusual Herb Seeds"] = "seedplants", ["Scarce Herb Seeds"] = "seedplants", ["Timberling Sprout"] = "seedplants",
    ["Earthroot"] = "vascular", ["Liferoot"] = "vascular",
    ["Grave Moss"] = "mosses", ["Ghost Mushroom"] = "mushrooms", ["Frilled Lichen"] = "lichens",
    ["Stranglekelp"] = "kelp",
}
local UNLOCK = { 1, 10, 30 }  -- gathers within a taxon before its lines open: the narrowest, the next, the rest
local BOTANY_EVERY = 900      -- seconds between botany lines
local lastBotany = -BOTANY_EVERY
ShandoBotany = {}  -- replaced by the saved table when it loads

-- A herb's lineage, narrowest taxon first; empty for a herb with no place yet.
function ns.Lineage(herb)
    local out, t = {}, TAXON[herb]
    while t do out[#out + 1] = t; t = PARENT[t] end
    return out
end

-- Count a gather towards every taxon in the herb's lineage.
function ns.CountBotany(herb)
    for _, t in ipairs(ns.Lineage(herb)) do ShandoBotany[t] = (ShandoBotany[t] or 0) + 1 end
end

-- The botany lines open to you for a herb: each taxon in its lineage whose gathers have reached its unlock.
function ns.BotanyPool(herb)
    local pool = {}
    for i, t in ipairs(ns.Lineage(herb)) do
        if (ShandoBotany[t] or 0) >= UNLOCK[math.min(i, #UNLOCK)] then
            for _, l in ipairs(ns.LINES["botany:" .. t] or {}) do pool[#pool + 1] = l end
        end
    end
    return pool
end

-- Saved counts from the old flat groups (kelp, flower, root...) mean nothing on the tree. On the first login with
-- the tree, rebuild the counts from the herb notebook (ShandoHerbPicks, account-wide, up to 400 picks per herb), the
-- closest record there is of what's been gathered, and mark the table as the tree's.
function ns.MigrateBotany()
    if ShandoBotany.tree then return end
    local fresh = { tree = 1 }
    ShandoBotany = fresh
    for herb, picks in pairs(ShandoHerbPicks or {}) do
        for _ = 1, #picks do ns.CountBotany(herb) end
    end
end
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

-- A botany line rests BOTANY_REST once said (22 Nov 2026: each group has one line per level, and the flower group,
-- which most early herbs are in, only two, so they came back 9 times in 7 days; the backoff forgets after a few
-- sessions). Rested() keeps the lines of a pool that have rested, from ShandoHeard's last-said time.
local BOTANY_REST = 3 * 24 * 3600
function ns.Rested(pool, now)
    local out = {}
    for _, l in ipairs(pool) do
        local h = ShandoHeard and ShandoHeard[l[1]]
        if not h or now - h[3] >= BOTANY_REST then out[#out + 1] = l end
    end
    return out
end

-- Say a botany line for the herb's group, if it's time and one is open to you and has rested. Its sound is with
-- Shan'do's own lines (sounds\<key>.mp3), not the herbs'. True if said.
local function SayBotany(herb)
    local pool = ns.Rested(ns.BotanyPool(herb), time())
    if GetTime() - lastBotany <= BOTANY_EVERY * ns.Backoff(pool) then return false end
    local l = ns.PickLeast(pool, "botany")
    if not l then return false end
    AlbaLast = GetTime()
    Mark(l[1])
    ns.Heard(l[1])
    PlaySoundFile(ns.VoicePath(l[1], SOUNDS .. l[1] .. ".mp3"), "Dialog")
    DEFAULT_CHAT_FRAME:AddMessage("|cff9fd3a8" .. l[2] .. "|r")
    return true
end

local function IsSkin(name)
    return name:find("Leather") or name:find("Hide$") or name:find(" Scale$")
end

-- Skinning lines need your own Skinning cast just before the loot (15 Nov 2026: a Twilight Thug's corpse loot, most
-- likely leather gear or scraps, had her speak of the animal's warmth leaving the hide). The cast's spell is named
-- "Skinning" whatever the rank; its loot comes from the same corpse as the kill's, so the loot alone can't tell them.
local SKIN_WINDOW = 15            -- seconds from the Skinning cast to its loot
local skinnedAt

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
f:SetScript("OnEvent", function(_, event, unit, target, _, spellID)
    if event == "UNIT_SPELLCAST_SENT" then
        if unit == "player" and type(target) == "string" and Mineral(target) then mined, minedAt = target, GetTime() end
        local spell = unit == "player" and spellID and not (issecretvalue and issecretvalue(spellID))
            and ((C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)) or (GetSpellInfo and GetSpellInfo(spellID)))
        if spell == "Skinning" then skinnedAt = GetTime() end
        return
    end
    if event == "LOOT_OPENED" and mined and GetTime() - minedAt < 15 and FromNode() then
        Note(mined)  -- ShandoHerbPicks["Large Chunk of Amber"] and so on; tools/forever_runs.py reads them
        mined = nil
    end
    if event == "PLAYER_LOGIN" then
        ns.MigrateBotany()
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
            elseif IsSkin(name) and skinnedAt and GetTime() - skinnedAt < SKIN_WINDOW then
                skin = true
            end
        end
    end
    herb = herb or rare  -- the node's own herb goes in the notebook; a rare find alongside it is what she speaks of
    if herb then Note(herb) HerbaloreSession = (HerbaloreSession or 0) + 1 end  -- read by the look-back
    for _, h in ipairs({ herb, rare ~= herb and rare or nil }) do ns.CountBotany(h) end
    if skin then SkinSession = (SkinSession or 0) + 1 end
    if ShandoOff or InCombatLockdown() or GetTime() - (AlbaLast or -(ShandoGap or GAP)) < (ShandoGap or GAP) then return end
    local spoken = rare or herb
    if spoken and not ShandoNoHerbs then
        herb = spoken
        -- the herb itself rests too (HERB_REST, doubling), so one herb's lines don't come one after another
        local gate = "herb:" .. herb
        if HerbReady(gate) and SayOne(ns.HERBS[herb]) then
            Mark(gate)
        elseif SayBotany(herb) then
            lastBotany = GetTime()
        elseif GetTime() - lastCalm > CALM * ns.Backoff(ns.HERB_CALM) and math.random() < 0.3 and SayOne(ns.HERB_CALM) then
            lastCalm = GetTime()
        end
    elseif skin and not ShandoNoSkins and ns.SKIN and #ns.SKIN > 0 then
        if not skinned then
            skinned = SayOne(ns.SKIN)
        elseif GetTime() - lastCalm > CALM * ns.Backoff(ns.SKIN) and math.random() < 0.25 and SayOne(ns.SKIN) then
            lastCalm = GetTime()
        end
    end
end)
