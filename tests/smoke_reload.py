r"""Smoke-test that a /reload doesn't make Shan'do's lines new again.

28 Nov 2026: past midnight her late-night word of care ("It's late...") came after every /reload. The session (and
how long you'd played) carried across the reload, but what she'd said, and when, didn't, so each reload looked like
the first chance that night. Now what she said goes with the session.

Plays half an hour past 1 a.m. until she gives the late-night line, logs out, loads every file again as a /reload
does (the saved variables kept), and plays on: the line must not come again. A real login the next day still may.

  uv run --no-project --with lupa python tests/smoke_reload.py
"""
import re
from pathlib import Path

import lupa.lua51 as lupa

ROOT = Path(__file__).resolve().parents[1]
STUBS = re.search(r'lua\.execute\(r"""(.*?)"""\)', (ROOT / "tests" / "smoke_emerald.py").read_text(encoding="utf-8"),
                  re.S).group(1)
FILES = ("Lines.lua", "Mine.lua", "HerbLines.lua", "Ambience.lua", "Shando.lua", "Herbs.lua")

lua = lupa.LuaRuntime()
lua.execute(STUBS)
lua.execute("""
  function GetMinimapZoneText() return "" end   -- a full login touches what the meditation test never does
  realDate = date
  date = function(f, ...) if f == "%H" then return "01" end return realDate(f, ...) end   -- 1 a.m., real clock
  function late() local n = 0 for _, p in ipairs(played) do if p.path:find("deepnight") then n = n + 1 end end return n end
  function fire(...) for _, f in ipairs(frames) do if f.scripts.OnEvent then f.scripts.OnEvent(f, ...) end end end
  function play(secs) for i = 1, secs do advance(now + 1) if i % 5 == 0 then tick() end end end
""")
load = lua.eval("function(code, name, ns) return assert(loadstring(code, '@' .. name))('Shando', ns) end")


def boot():
    """Loads every file afresh, as the game does at login or /reload (globals, the saved variables, kept)."""
    lua.execute("frames, timers = {}, {}")
    ns = lua.eval("{}")
    for name in FILES:
        load((ROOT / name).read_text(encoding="utf-8"), name, ns)
    lua.execute("fire('ADDON_LOADED', 'Shando')")
    return ns


boot()
lua.execute("fire('PLAYER_ENTERING_WORLD', true, false)")             # a real login
lua.execute("play(2400)")                                             # 40 minutes past 1 a.m.
first = lua.eval("late()")
assert first == 1, f"she should give the late-night line once in the first 40 minutes, gave it {first} times"

lua.execute("fire('PLAYER_LOGOUT')")                                  # /reload: saved, then every file again
boot()
lua.execute("fire('PLAYER_ENTERING_WORLD', false, true)")
lua.execute("play(1200)")
assert lua.eval("late()") == first, f"after the reload she said it again: {lua.eval('late()')} times"
print("a /reload carries what she said: the late-night line once, not again after reloading")
