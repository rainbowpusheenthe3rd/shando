r"""Smoke-test /emerald dream against a stubbed game: every line in order with its caption and voice, the world's
ambient sound and music fading out and back, combat ending it at once with the sound straight back, moving ending
it, a second /emerald stopping it, and a login after a closed game restoring the levels.

  uv run --with lupa python tests/smoke_emerald.py
"""
from pathlib import Path

import lupa.lua51 as lupa

ROOT = Path(__file__).resolve().parents[1]
lua = lupa.LuaRuntime()
lua.execute(r"""
local noop = function() end
local function stub(t)
  return setmetatable(t or {}, { __index = function(_, k) if type(k) == "string" and k:match("^%u") then return noop end end })
end
now = 1000
cvars = { Sound_AmbienceVolume = "0.6", Sound_MusicVolume = "0.4" }
function GetCVar(k) return cvars[k] end
function SetCVar(k, v) cvars[k] = tostring(v) end
function GetTime() return now end
function time() return 1700000000 + now end
date = os.date
timers = {}
C_Timer = {
  After = function(s, f) timers[#timers + 1] = { at = now + s, f = f } end,
  NewTicker = function(s, f, n)
    local t = { cancelled = false }
    function t:Cancel() self.cancelled = true end
    local count = 0
    local function step()
      if t.cancelled then return end
      count = count + 1
      f()
      if not t.cancelled and (not n or count < n) then timers[#timers + 1] = { at = now + s, f = step } end
    end
    timers[#timers + 1] = { at = now + s, f = step }
    return t
  end,
}
function advance(to)
  while true do
    table.sort(timers, function(a, b) return a.at < b.at end)
    local t = timers[1]
    if not t or t.at > to then break end
    table.remove(timers, 1)
    now = t.at
    t.f()
  end
  now = to
end
played, captions = {}, {}
function PlaySoundFile(path, channel) played[#played + 1] = { path = path, channel = channel } return true, #played end
stopped = {}
function StopSound(h, ms) stopped[#stopped + 1] = { h = h, ms = ms, at = now } end
speed, combat = 0, false
function GetUnitSpeed() return speed end
function InCombatLockdown() return combat end
function IsInInstance() return false end
function UnitIsDeadOrGhost() return false end
function UnitIsGhost() return false end
function UnitOnTaxi() return false end
function IsResting() return false end
function IsOutdoors() return true end
function IsSwimming() return false end
function GetGameTime() return 22, 0 end
function GetSubZoneText() return "" end
function GetZoneText() return "Teldrassil" end
function GetRealZoneText() return "Teldrassil" end
function UnitName() return "Tester" end
function UnitLevel() return 10 end
function UnitClass() return "Druid", "DRUID" end
function UnitRace() return "Night Elf", "NightElf" end
STANDARD_TEXT_FONT = "font"
UIParent = stub({})
Minimap = stub({ GetWidth = function() return 140 end })
DEFAULT_CHAT_FRAME = stub({})
SlashCmdList = {}
UISpecialFrames = {}
function print() end
function GetNumLootItems() return 0 end  -- Herbs.lua: no loot window in these checks
function hooksecurefunc() end
frames = {}
local function region()
  local r = stub({ alpha = 1, shown = true, scripts = {} })
  r.SetAlpha = function(s, a) s.alpha = a end
  r.GetAlpha = function(s) return s.alpha end
  r.Show = function(s) s.shown = true end
  r.Hide = function(s) s.shown = false end
  r.IsShown = function(s) return s.shown end
  r.SetScript = function(s, k, f) s.scripts[k] = f end
  r.GetScript = function(s, k) return s.scripts[k] end
  r.SetText = function(s, t) s.text = t if s.isCaption and t and t ~= "" then captions[#captions + 1] = t end end
  r.CreateTexture = function() return region() end
  r.CreateFontString = function() local fs = region() fs.isCaption = true return fs end
  r.CreateAnimationGroup = function() return region() end
  r.CreateAnimation = function() return region() end
  return r
end
function CreateFrame() local f = region() frames[#frames + 1] = f return f end
function tick() for _, f in ipairs(frames) do if f.scripts.OnUpdate then f.scripts.OnUpdate(f, 0.05) end end end
""")
ns = lua.eval("{}")
load = lua.eval("function(code, name, ns) return assert(loadstring(code, '@' .. name))('Shando', ns) end")
for name in ("Lines.lua", "Mine.lua", "HerbLines.lua", "Ambience.lua", "Shando.lua", "Herbs.lua"):   # the UI panels aren't needed here
    load((ROOT / name).read_text(encoding="utf-8"), name, ns)

G = lua.globals()
close = lambda a, b: abs(float(a) - float(b)) < 1e-6
lua.execute("ShandoDream = 'clearing'")   # pinned: the random pick is tested at the end
lua.execute("SlashCmdList.EMERALD('dream')")
lua.execute("advance(now + 7)")
assert close(G.cvars.Sound_AmbienceVolume, 0) and close(G.cvars.Sound_MusicVolume, 0), dict(G.cvars)
assert G.ShandoHush.amb == "0.6"
# the whole script: 23 lines on Dialog, in order, each with its caption; bells and the wind on Master
lua.execute("t0 = now - 7")
lua.execute("for i = 1, 560 do advance(now + 1) tick() end")   # to 567 s, just before the frogs (572 s)
assert close(G.cvars.Sound_AmbienceVolume, 0) and close(G.cvars.Sound_MusicVolume, 0)
assert not any("meld" in p.path for p in G.played.values())
lua.execute("advance(now + 20)")   # the frogs start on the ambience channel, and it rises from silence
frogs = [p for p in G.played.values() if p.path.endswith("meld.mp3")]
assert frogs and frogs[0].channel == "Ambience"
a = float(G.cvars.Sound_AmbienceVolume)
assert 0.1 < a < 0.6 and close(G.cvars.Sound_MusicVolume, 0), (a, dict(G.cvars))
lua.execute("advance(now + 20)")
assert close(G.cvars.Sound_AmbienceVolume, 0.6) and close(G.cvars.Sound_MusicVolume, 0)
assert G.ShandoDreamHeard.clearing, "heard once her last word is said"
lua.execute("for i = 1, 530 do advance(now + 1) tick() end")   # only frogs now, to 1137 s
last_voice = max(i for i, p in G.played.items() if "emerald" in p.path)
assert G.played[last_voice].path.endswith("emerald20.mp3"), "her frog introduction is the last thing she says"
assert all("emerald" not in p.path for i, p in G.played.items() if i > last_voice)
assert sum(1 for p in G.played.values() if p.path.endswith("meld.mp3")) >= 9, "the frog bed loops for ten minutes"
assert G.ShandoHush is not None and close(G.cvars.Sound_MusicVolume, 0), "still with the frogs, music not back yet"
assert G.ShandoEmerald.reached == "frogs"
lua.execute("advance(t0 + 1162)")                              # halfway through the 45 s fade (1140 s)
m = float(G.cvars.Sound_MusicVolume)
assert 0.1 < m < 0.35, m
n_frogs = sum(1 for p in G.played.values() if p.path.endswith("meld.mp3"))
lua.execute("advance(t0 + 1185)")
assert sum(1 for p in G.played.values() if p.path.endswith("meld.mp3")) == n_frogs, "no new frog copy once fading"
voices = [p.path for p in G.played.values() if "emerald" in p.path]   # checked inside the Dream, before it ends
order = [*range(1, 20), 21, 22, 23, 20]   # waking and the farewell first, then she introduces the frogs
assert [v.split("\\")[-1] for v in voices] == [f"emerald{i:02d}.mp3" for i in order], voices
assert all(p.channel == "Dialog" for p in G.played.values() if "emerald" in p.path)
assert all(p.channel == "Master" for p in G.played.values() if "kindbell" in p.path or "windbreath" in p.path)
assert sum(1 for p in G.played.values() if "windbreath" in p.path) == 1
HINT = "stay still to remain in the Dream; moving brings you back"
assert len([c for c in G.captions.values() if c != HINT]) == 23
lua.execute("advance(t0 + 1200) tick()")                       # it ends at 1190 s
# it ended by itself, the world's sound is back, and the record says so
assert close(G.cvars.Sound_AmbienceVolume, 0.6) and close(G.cvars.Sound_MusicVolume, 0.4) and G.ShandoHush is None
assert G.ShandoEmerald.ended == "finished" and G.ShandoEmerald.reached == "end"

# combat: straight back, at once, and no more lines
lua.execute("played = {} SlashCmdList.EMERALD('dream') advance(now + 30)")
assert close(G.cvars.Sound_AmbienceVolume, 0)
lua.execute("combat = true")
lua.execute("for _, f in ipairs(frames) do if f.scripts.OnEvent then f.scripts.OnEvent(f, 'PLAYER_REGEN_DISABLED') end end")
assert close(G.cvars.Sound_AmbienceVolume, 0.6) and G.ShandoHush is None
dream = lambda: sum(1 for p in G.played.values() if "emerald" in p.path)
n = dream()
lua.execute("combat = false advance(now + 400)")   # her ordinary lines may come back; the Dream's may not
assert dream() == n, "Dream lines after combat ended it"

# moving: it stops at once (every frame), she says why, and the sound comes back
lua.execute("played = {} captions = {} SlashCmdList.EMERALD('dream') advance(now + 60)")
# her line playing when you move fades out over 1.5 s, and the exit line starts only after that (no overlap)
spoken = [i for i, p in G.played.items() if "emerald" in p.path]
lua.execute("stopped = {}; speed = 1; tick(); speed = 0; moved_at = now")
assert G.ShandoEmerald.ended == "moved", G.ShandoEmerald.ended
fades = [s for s in G.stopped.values() if s.h == spoken[-1]]
assert fades and fades[0].ms == 1500, [(s.h, s.ms) for s in G.stopped.values()]
lua.execute("advance(now + 1.5)")
assert not any(p.path.endswith("dreamstop1.mp3") for p in G.played.values()), "exit line waits for the fade"
lua.execute("advance(now + 0.5)")
assert any(p.path.endswith("dreamstop1.mp3") and p.channel == "Dialog" for p in G.played.values())
assert any(c.startswith("You moved, so we've come back") for c in G.captions.values())
lua.execute("advance(now + 10)")
assert close(G.cvars.Sound_AmbienceVolume, 0.6) and G.ShandoHush is None

# The moonwell: its own twenty lines in order, captioned, then the pond frogs (vigil), not the swamp
lua.execute("played = {} captions = {} ShandoDream = 'well' SlashCmdList.EMERALD('dream')")
lua.execute("for i = 1, 700 do advance(now + 1) tick() end")
spoken = [p.path.split("\\")[-1] for p in G.played.values() if "sounds" in p.path]
assert spoken == [f"well{i:02d}.mp3" for i in range(1, 21)], spoken
assert len([c for c in G.captions.values() if c != HINT]) == 20
beds = [p.path.split("\\")[-1] for p in G.played.values() if p.path.endswith(("vigil.mp3", "meld.mp3"))]
assert beds and set(beds) == {"vigil.mp3"}, beds
lua.execute("SlashCmdList.EMERALD('dream') advance(now + 10)")
lua.execute("ShandoDream = 'clearing'")

# a second /emerald stops it, fading the sound back
lua.execute("SlashCmdList.EMERALD('dream') advance(now + 10) SlashCmdList.EMERALD('dream') advance(now + 10)")
assert close(G.cvars.Sound_AmbienceVolume, 0.6) and G.ShandoHush is None

# a login after the game closed mid-session puts the levels back
lua.execute("ShandoHush = { amb = '0.6', mus = '0.4' } cvars.Sound_AmbienceVolume = '0' cvars.Sound_MusicVolume = '0'")
lua.execute("for _, f in ipairs(frames) do if f.scripts.OnEvent then pcall(f.scripts.OnEvent, f, 'PLAYER_ENTERING_WORLD', true, false) end end")
assert close(G.cvars.Sound_AmbienceVolume, 0.6) and G.ShandoHush is None, dict(G.cvars)
# picking: a chosen one; on random, unheard first; once all are heard, each in turn after the last
lua.execute("ShandoDream = nil ShandoDreamHeard = {} ShandoDreamLast = nil")
fake = lua.eval("function(ns) ns.DREAMS[2] = { id = 'moonwell', name = 'b', kind = 'emerald', steps = {} } "
                "ns.DREAMS[3] = { id = 'vigil', name = 'c', kind = 'emerald', steps = {} } end")
fake(ns)
picks = lua.eval("function(ns) local seen = {} for i = 1, 3 do local d = ns.PickDream() seen[#seen + 1] = d.id "
                 "ShandoDreamHeard[d.id] = true ShandoDreamLast = d.id end return table.concat(seen, ',') end")(ns)
assert sorted(picks.split(",")) == ["clearing", "moonwell", "vigil"], picks   # each once before any repeats
cycle = lua.eval("function(ns) local seen = {} for i = 1, 4 do local d = ns.PickDream() seen[#seen + 1] = d.id "
                 "ShandoDreamLast = d.id end return table.concat(seen, ',') end")(ns)
first = cycle.split(",")
ids = ["clearing", "moonwell", "vigil"]
assert all(ids.index(first[i + 1]) == (ids.index(first[i]) + 1) % 3 for i in range(3)), cycle   # in turn
lua.execute("ShandoDream = 'moonwell'")
assert lua.eval("function(ns) return ns.PickDream().id end")(ns) == "moonwell"

# the lifetime tally (ShandoHeard, ShandoHeardLog) counts every line said, and the log keeps only the newest
lua.execute("ShandoHeard, ShandoHeardLog = {}, {}")
heard = lua.eval("function(ns) now = now + 5 ns.Heard('a') now = now + 5 ns.Heard('a') ns.Heard('b') "
                 "local h = ShandoHeard.a return h[1], h[3] - h[2], ShandoHeard.b[1], #ShandoHeardLog, ShandoHeardLog[3] end")(ns)
assert tuple(heard)[:4] == (2, 5, 1, 3) and tuple(heard)[4].startswith("b "), tuple(heard)
lua.eval("function(ns) for i = 1, 2100 do ns.Heard('x') end end")(ns)
assert lua.eval("#ShandoHeardLog") == 2000 and lua.eval("ShandoHeard.x[1]") == 2100

# a kindness needs the spell to go to someone else: not yourself, with or without a realm, nor with an enemy targeted
lua.execute("""
  function UnitName(u) if u == "player" then return "Chalice" end return tgt end
  function UnitExists(u) return u == "target" and tgt ~= nil end
  function UnitCanAttack() return enemy end
  function Ambiguate(n) return (n:gsub("%-.*", "")) end
  ShandoKindLog = nil
""")
other = lua.eval("function(ns, target, t, e) tgt, enemy = t, e return ns.CastOnOther(target) end")
assert other(ns, "Thrall", "Thrall", False) is True                       # a friend, targeted
assert other(ns, "Chalice", None, False) is False                         # yourself
assert other(ns, "Chalice-Moonwater", None, False) is False               # yourself, with a realm
assert other(ns, "", None, False) is False and other(ns, None, None, False) is False
assert other(ns, "Kobold Miner", "Kobold Miner", True) is False           # an enemy targeted: the buff went to you
assert lua.eval("#ShandoKindLog") == 6 and lua.eval("ShandoKindLog[1]").endswith("Thrall -> other")

# which line (ns.PickLeast): nine inn lines, five visits a session for three sessions. Every line once before any
# twice, so after 15 visits all nine are heard and exactly six twice; never the same line twice in a row; and
# lifetime counts carry over, so a new line is said first
lua.execute("ShandoHeard, ShandoHeardLog, ShandoRepeat = {}, {}, nil")
picks = lua.eval("""function(ns)
  local list, out = {}, {}
  for i = 1, 9 do list[i] = { "inn" .. i, "" } end
  for _ = 1, 15 do local l = ns.PickLeast(list, "inn") ns.Heard(l[1]) out[#out + 1] = l[1] end
  list[10] = { "inn10", "" }
  out[#out + 1] = ns.PickLeast(list, "inn")[1]
  return table.concat(out, ",")
end""")(ns).split(",")
counts = sorted(picks[:15].count(f"inn{i}") for i in range(1, 10))
assert counts == [1, 1, 1, 2, 2, 2, 2, 2, 2], counts
assert len(set(picks[:9])) == 9, "the first nine visits are nine different lines"
assert all(a != b for a, b in zip(picks[:15], picks[1:15])), "never twice in a row"
assert picks[15] == "inn10", picks[15]
assert lua.eval("function(ns) return ns.PickLeast({}, 'none') end")(ns) is None

# backoff by repeat round, within the window: the nine inn lines above, after 15 visits, are in round 1 (every line
# heard once, six twice), so their gap is 1.6x; first time through it's 1x; after three full rounds, 1.6^3
inn = lua.eval("function() local l = {} for i = 1, 9 do l[i] = { 'inn' .. i, '' } end return l end")()
assert lua.eval("function(ns, l) return ns.Round(l), ns.Backoff(l) end")(ns, inn) == (1, 1.6)
assert lua.eval("function(ns) return ns.Backoff({ { 'never', '' } }), ns.Backoff({}) end")(ns) == (1, 1)
lua.execute("for i = 1, 9 do ShandoRepeat.n['inn' .. i] = 3 end")
assert abs(lua.eval("function(ns, l) return ns.Backoff(l) end")(ns, inn) - 1.6 ** 3) < 1e-9

# the repeat counter starts again every three sessions: logins 1-3 share a window, the 4th begins a new one
win = lua.eval("""function(ns)
  ShandoSession, ShandoRepeat = 0, nil
  local out = {}
  for s = 1, 7 do ns.NewSession() ns.Heard("w") out[s] = ShandoRepeat.n.w end
  return table.concat(out, ",")
end""")(ns)
assert win == "1,2,3,1,2,3,1", win
assert lua.eval("ShandoHeard.w[1]") == 7, "the lifetime tally keeps counting"

# botany: a herb's group opens level 1 at the first gather, level 2 at 10, level 3 at 30; unknown herbs have none
pool = lua.eval("""function(ns, herb, n)
  ShandoBotany = { root = n }
  local levels = {}
  for _, l in ipairs(ns.BotanyPool(herb)) do levels[#levels + 1] = l[1]:match("^botany_root(%d)_") end
  table.sort(levels)
  return table.concat(levels, "")
end""")
assert pool(ns, "Earthroot", 0) == "" and pool(ns, "Earthroot", 1) == "1"
assert pool(ns, "Liferoot", 9) == "1" and pool(ns, "Liferoot", 10) == "12" and pool(ns, "Golden Sansam", 30) == "123"
assert pool(ns, "Linen Cloth", 99) == ""

# a whole gather: Earthroot from a node counts towards its group, says the herb's own line first, then, with the
# herb resting, a root botany line from Shan'do's own sounds folder
gather = lua.eval("""function(ns)
  ShandoBotany, ShandoHerbSaid, ShandoOff, AlbaLast = {}, {}, nil, nil
  function GetNumLootItems() return 1 end
  function GetLootSlotInfo() return nil, "Earthroot" end
  function GetLootSourceInfo() return "GameObject-0-1-2-3-4-5" end
  local herbs
  for _, fr in ipairs(frames) do local h = fr.scripts.OnEvent if h and debug.getinfo(h, "S").source == "@Herbs.lua" then herbs = fr end end
  local out = {}
  for i = 1, 2 do
    now = now + (i == 1 and 1000 or 100)  -- the second gather inside the herb's 300 s rest
    local n = #played
    herbs.scripts.OnEvent(herbs, "LOOT_OPENED")
    out[i] = n < #played and played[#played].path or "-"
  end
  function GetNumLootItems() return 0 end
  return ShandoBotany.root, out[1], out[2]
end""")
n, first, second = gather(ns)
assert n == 2, n
assert "sounds\\herbs\\earthroot" in first, first
assert "sounds\\botany_root1_" in second, second
print("emerald dream checks pass")
