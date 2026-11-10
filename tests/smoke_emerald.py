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
function StopSound() end
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
for name in ("Lines.lua", "Mine.lua", "Ambience.lua", "Shando.lua"):   # the UI panels aren't needed here
    load((ROOT / name).read_text(encoding="utf-8"), name, ns)

G = lua.globals()
close = lambda a, b: abs(float(a) - float(b)) < 1e-6
lua.execute("SlashCmdList.EMERALD('dream')")
lua.execute("advance(now + 7)")
assert close(G.cvars.Sound_AmbienceVolume, 0) and close(G.cvars.Sound_MusicVolume, 0), dict(G.cvars)
assert G.ShandoHush.amb == "0.6"
# the whole script: 16 lines on Dialog, in order, each with its caption; bells and the wind on Master
lua.execute("for i = 1, 540 do advance(now + 1) tick() end")   # the session ends at 538 s
voices = [p.path for p in G.played.values() if "emerald" in p.path]
assert [v.split("\\")[-1] for v in voices] == [f"emerald{i:02d}.mp3" for i in range(1, 17)], voices
assert all(p.channel == "Dialog" for p in G.played.values() if "emerald" in p.path)
assert all(p.channel == "Master" for p in G.played.values() if "kindbell" in p.path or "windbreath" in p.path)
assert sum(1 for p in G.played.values() if "windbreath" in p.path) == 1
assert len(list(G.captions.values())) == 16
# it ended by itself and the world's sound came back
assert close(G.cvars.Sound_AmbienceVolume, 0.6) and close(G.cvars.Sound_MusicVolume, 0.4) and G.ShandoHush is None

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

# a second /emerald stops it, fading the sound back
lua.execute("SlashCmdList.EMERALD('dream') advance(now + 10) SlashCmdList.EMERALD('dream') advance(now + 10)")
assert close(G.cvars.Sound_AmbienceVolume, 0.6) and G.ShandoHush is None

# a login after the game closed mid-session puts the levels back
lua.execute("ShandoHush = { amb = '0.6', mus = '0.4' } cvars.Sound_AmbienceVolume = '0' cvars.Sound_MusicVolume = '0'")
lua.execute("for _, f in ipairs(frames) do if f.scripts.OnEvent then pcall(f.scripts.OnEvent, f, 'PLAYER_ENTERING_WORLD', true, false) end end")
assert close(G.cvars.Sound_AmbienceVolume, 0.6) and G.ShandoHush is None, dict(G.cvars)
print("emerald dream checks pass")
