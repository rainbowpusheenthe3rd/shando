r"""Smoke-test the brief drifting moments (Drift.lua), first alone, then wired into Shan'do.

Alone: every kind has its art on disk, starts its sprites, moves them (falling ones down, rising ones up), fades
them in and out, and has none left at the end of its life, when the frame stops updating; the off switch
(ShandoNoDrift) starts nothing; DriftClear removes everything at once.
Wired: each meditation's moments fire on their lines, in order; moving ends a meditation and its moments with it;
an inn's petals (by day) or embers (by night) come a minute into its sound, once per stay, and not if you've left.

  uv run --no-project --with lupa python tests/smoke_drift.py
"""
import re
from pathlib import Path

import lupa.lua51 as lupa

ROOT = Path(__file__).resolve().parents[1]
# the stubbed game is the meditation test's own (its first Lua block), so the two can't drift apart
STUBS = re.search(r'lua\.execute\(r"""(.*?)"""\)', (ROOT / "tests" / "smoke_emerald.py").read_text(encoding="utf-8"),
                  re.S).group(1)
# frames that know the screen's size, and textures that record where they're put and how bright
RECORD = r"""
resting, hour = false, 14
function IsResting() return resting end
function GetGameTime() return hour, 0 end
log = {}
local made = CreateFrame
function CreateFrame(...)
  local f = made(...)
  f.GetWidth = function() return 1920 end
  f.GetHeight = function() return 1080 end
  f.CreateTexture = function()
    local t = setmetatable({}, { __index = function() return function() end end })
    t.SetTexture = function(tx, p) tx.path = p end
    t.SetBlendMode = function(tx, m) tx.blend = m end
    t.SetAlpha = function(tx, a) tx.a = a end
    t.Show = function(tx) tx.shown = true end
    t.Hide = function(tx) tx.shown = false end
    t.SetPoint = function(tx, _, _, _, x, y) log[#log + 1] = { tex = tx, x = x, y = y, a = tx.a } end
    return t
  end
  return f
end
"""


def runtime(files):
    """Starts a stubbed game with these addon files loaded, in this order.

    Args:
        files: The addon's Lua files to load.

    Returns:
        The Lua runtime and the addon's namespace table.
    """
    lua = lupa.LuaRuntime()
    lua.execute(STUBS)
    lua.execute(RECORD)
    ns = lua.eval("{}")
    load = lua.eval("function(code, name, ns) return assert(loadstring(code, '@' .. name))('Shando', ns) end")
    for name in files:
        load((ROOT / name).read_text(encoding="utf-8"), name, ns)
    return lua, ns


# ---- alone: Drift.lua and nothing else
lua, ns = runtime(["Drift.lua"])
sky = lua.eval("frames[1]")
step = lambda secs: lua.execute(f"for i = 1, {int(secs * 20)} do if frames[1].scripts.OnUpdate then "
                                f"frames[1].scripts.OnUpdate(frames[1], 0.05) end end")
kinds = sorted(ns.DRIFT_KINDS.keys())
assert kinds == ["blossom", "ember", "green", "maple", "mote", "oak", "poppy", "spark"], kinds
for kind in kinds:
    k = ns.DRIFT_KINDS[kind]
    assert (ROOT / "drift" / (k.art + ".tga")).exists(), f"{kind}: no drift/{k.art}.tga"
    lua.execute("log = {}")
    assert ns.Drift(kind, 1) == 1 and sky.shown
    step(k.life + 1)
    track = [(e.x, e.y, e.a) for e in lua.eval("log").values()]
    assert len(track) > 20, (kind, len(track))
    ys = [y for _, y, _ in track]
    if k.move == "fall":
        assert ys[-1] < ys[0] - 100, f"{kind} should fall: {ys[0]:.0f} -> {ys[-1]:.0f}"
    else:
        assert ys[-1] > ys[0] + 100, f"{kind} should rise: {ys[0]:.0f} -> {ys[-1]:.0f}"
    xs = [x for x, _, _ in track]
    assert all(0 <= x <= 1920 for x in xs) and all(0 <= y <= 1080 for y in ys), f"{kind} left the screen"
    alphas = [a for _, _, a in track]
    assert alphas[0] < 0.2 * k.alpha and max(alphas) > 0.6 * k.alpha and alphas[-1] < 0.2 * k.alpha, \
        f"{kind} should fade in and out: {alphas[0]:.2f} .. {max(alphas):.2f} .. {alphas[-1]:.2f}"
    tex = lua.eval("log[1].tex")
    assert tex.path.endswith("drift\\" + k.art) and tex.blend == ("ADD" if k.add else "BLEND"), (tex.path, tex.blend)
    assert not sky.shown and lua.eval("frames[1].scripts.OnUpdate") is None, f"{kind}: still updating after its life"
# several over a spread: they start one after another, not all at once
lua.execute("log = {}")
ns.Drift("ember", 5, 12)
step(1)
lua.execute("function started() local seen, n = {}, 0 for _, e in ipairs(log) do "
            "if not seen[e.tex] then seen[e.tex], n = true, n + 1 end end return n end")
assert lua.eval("started()") == 1, lua.eval("started()")
step(12)
assert lua.eval("started()") == 5, lua.eval("started()")
step(10)
assert not sky.shown
# the off switch, an unknown kind, and clearing at once
lua.execute("ShandoNoDrift = true")
assert ns.Drift("maple", 3) == 0 and not sky.shown
lua.execute("ShandoNoDrift = nil")
assert ns.Drift("nosuch") == 0
ns.Drift("poppy", 4, 8)
step(2)
ns.DriftClear()
assert not sky.shown and lua.eval("frames[1].scripts.OnUpdate") is None
print("drift alone: every kind moves, fades and ends; off switch and clear work")

# ---- wired into Shan'do
lua, ns = runtime(["Lines.lua", "Mine.lua", "HerbLines.lua", "Ambience.lua", "Drift.lua", "Shando.lua", "Herbs.lua"])
lua.execute("frames[#frames].scripts.OnEvent(frames[#frames], 'ADDON_LOADED', 'Shando') "
            "for _, f in ipairs(frames) do if f.scripts.OnEvent then f.scripts.OnEvent(f, 'PLAYER_LOGIN') end end")
lua.execute("drifts = {}")
lua.eval("function(ns) local real = ns.Drift; ns.Drift = function(kind, n, spread) "
         "local started = real(kind, n, spread) if started > 0 then "
         "drifts[#drifts + 1] = { kind = kind, n = n or 1, at = now } end return started end end")(ns)
G = lua.globals()
want = {"clearing": [("green", 2)], "well": [("green", 1), ("mote", 6)], "acorn": [("oak", 1)],
        "ember": [("maple", 1), ("spark", 3), ("poppy", 2), ("ember", 5)]}
moments = ns.DREAM_MOMENTS
for dream, kinds in want.items():
    lua.execute(f"drifts = {{}} ShandoDream = '{dream}' t0 = now SlashCmdList.EMERALD('dream')")
    lua.execute("for i = 1, 1700 do advance(now + 1) tick() end")
    got = [(d.kind, d.n) for d in G.drifts.values()]
    assert got == kinds, (dream, got)
    # each on its own line: the moment comes a few seconds after the line it belongs to starts
    times = [round(d.at - G.t0) for d in G.drifts.values()]
    assert times == [m[1] for m in moments[dream].values()], (dream, times)
    assert lua.eval("ShandoEmerald.ended") == "finished", dream
# moving ends The ember before its leaf, and nothing drifts afterwards
lua.execute("drifts = {} ShandoDream = 'ember' SlashCmdList.EMERALD('dream') advance(now + 200) tick()")
lua.execute("speed = 1 tick() speed = 0")
assert lua.eval("ShandoEmerald.ended") == "moved"
lua.execute("for i = 1, 1500 do advance(now + 1) tick() end")
assert len(G.drifts) == 0, [d.kind for d in G.drifts.values()]
# moving mid-moment clears what's on screen at once
lua.execute("drifts = {} ShandoDream = 'ember' SlashCmdList.EMERALD('dream') advance(now + 1060) tick()")
assert [d.kind for d in G.drifts.values()][-1] == "ember"
lua.execute("speed = 1 tick() speed = 0")
assert lua.eval("ShandoEmerald.ended") == "moved"
print("drift in the meditations: each moment on its line, in order; moving ends them")

# the inn: a minute into its sound, once per stay; petals by day, embers by night; nothing if you've left
for hour, kind in ((14, "blossom"), (23, "ember")):
    lua.execute(f"drifts = {{}} hour = {hour} resting = true speed = 0")
    lua.execute("for i = 1, 400 do advance(now + 1) tick() end")
    got = [d.kind for d in G.drifts.values()]
    assert got == [kind], (hour, got)
    lua.execute("resting = false for i = 1, 30 do advance(now + 1) tick() end")
    lua.execute("for i = 1, 2000 do advance(now + 1) tick() end")      # the inn's sound waits 30 min to come back
lua.execute("drifts = {} hour = 14 resting = true speed = 0 for i = 1, 30 do advance(now + 1) tick() end")
lua.execute("resting = false for i = 1, 60 do advance(now + 1) tick() end")   # left before the minute was up
assert len(G.drifts) == 0, [d.kind for d in G.drifts.values()]
lua.execute("drifts = {} ShandoNoDrift = true resting = true for i = 1, 2400 do advance(now + 1) tick() end")
assert len(G.drifts) == 0, "switched off, yet something drifted"
lua.execute("ShandoNoDrift = nil")
print("drift at the inn: petals by day, embers by night, once per stay; not after you've left; off switch holds")

# /shando drift <kind> shows one now; without a kind (or an unknown one) it lists them; off means off
lua.execute("printed = {} function print(s) printed[#printed + 1] = s end")
lua.execute("drifts = {} SlashCmdList.SHANDO('drift maple') SlashCmdList.SHANDO('drift ember')")
assert [(d.kind, d.n) for d in G.drifts.values()] == [("maple", 3), ("ember", 5)]
lua.execute("drifts = {} SlashCmdList.SHANDO('drift') SlashCmdList.SHANDO('drift nosuch')")
assert len(G.drifts) == 0 and "maple" in G.printed[1] and "blossom" in G.printed[2], list(G.printed.values())
lua.execute("ShandoNoDrift = true SlashCmdList.SHANDO('drift maple')")
assert len(G.drifts) == 0 and "off" in G.printed[3]
lua.execute("ShandoNoDrift = nil")
print("/shando drift: shows each kind on demand")
