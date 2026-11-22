r"""Botany lines rest three days once said (Herbs.lua, ns.Rested): a line never said is open, one said an hour ago is
not, one said four days ago is open again.

    uv run --no-project --with lupa python tests/test_botany_rest.py
"""
from pathlib import Path

import lupa.lua51 as lua51

ADDON = Path(__file__).resolve().parent.parent

lua = lua51.LuaRuntime()
lua.execute("""
GetTime = function() return 1000 end
time = function() return 1800000000 end
CreateFrame = function() return { RegisterEvent = function() end, SetScript = function() end } end
""")
ns = lua.eval("{ LINES = {}, HERBS = {} }")
lua.eval("function(src, ns) return assert(loadstring(src))('Shando', ns) end")(
    (ADDON / "Herbs.lua").read_text(encoding="utf-8"), ns)

now = 1800000000
lua.execute(f"""
ShandoHeard = {{ said_hour_ago = {{ 1, 0, {now - 3600} }}, said_four_days_ago = {{ 2, 0, {now - 4 * 86400} }} }}
""")
pool = lua.eval("{ {'never_said', 'a'}, {'said_hour_ago', 'b'}, {'said_four_days_ago', 'c'} }")
kept = [str(l[1]) for l in ns.Rested(pool, now).values()]
assert kept == ["never_said", "said_four_days_ago"], kept
print("ok: rested lines kept", kept)
