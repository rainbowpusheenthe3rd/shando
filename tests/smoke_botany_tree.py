r"""The Linnaean botany tree (Herbs.lua): a herb's lineage runs from its family to its kingdom, a gather counts for
every taxon in it, the narrowest taxon opens at once and the wider ones at 10 and 30 gathers, and the first login
rebuilds the counts from the herb notebook. Every herb with lines has a place in the tree, and every taxon in the
tree has at least one line in Lines.lua.

    uv run --no-project --with lupa python tests/smoke_botany_tree.py
"""
import re
from pathlib import Path

import lupa.lua51 as lua51

ADDON = Path(__file__).resolve().parent.parent

lua = lua51.LuaRuntime()
lua.execute("""
GetTime = function() return 1000 end
time = function() return 1800000000 end
CreateFrame = function() return { RegisterEvent = function() end, SetScript = function() end } end
""")
ns = lua.eval("{ HERBS = {} }")
load = lua.eval("function(src, ns) return assert(loadstring(src))('Shando', ns) end")
for f in ("Lines.lua", "HerbLines.lua", "Herbs.lua"):
    load((ADDON / f).read_text(encoding="utf-8"), ns)


def lineage(herb):
    return list(ns.Lineage(herb).values())


assert lineage("Peacebloom") == ["daisy", "eudicots", "angiosperms", "seedplants", "vascular", "landplants"], \
    lineage("Peacebloom")
assert lineage("Stranglekelp") == ["kelp"]
assert lineage("Ghost Mushroom") == ["mushrooms", "fungi"]
assert lineage("Not a herb") == []

# every herb Shan'do has lines for is placed; every taxon on the way has lines (checked at the end, so the rest of
# the logic is tested even before a new taxon's lines are written)
lineless = set()
for herb in ns.HERBS.keys():
    assert lineage(herb), f"{herb} has no place in the tree"
    lineless |= {t for t in lineage(herb) if ns.LINES["botany:" + t] is None}

# unlocking: one gather opens the narrowest taxon only; ten open the next; thirty open the rest
lua.execute("ShandoBotany = {}")
g = lua.globals()


def pool_kinds(herb):
    keys = {str(l[1]) for l in ns.BotanyPool(herb).values()}
    return {t for t in lineage(herb) for l in (ns.LINES["botany:" + t] or {}).values() if str(l[1]) in keys}


ns.CountBotany("Peacebloom")
assert pool_kinds("Peacebloom") == {"daisy"}, pool_kinds("Peacebloom")
for _ in range(9):
    ns.CountBotany("Swiftthistle")           # also daisy family: counts towards the same taxa
assert g.ShandoBotany["eudicots"] == 10
assert pool_kinds("Peacebloom") == {"daisy", "eudicots"}, pool_kinds("Peacebloom")
for _ in range(20):
    ns.CountBotany("Silverleaf")             # eudicots, but not daisy family
assert g.ShandoBotany["daisy"] == 10 and g.ShandoBotany["angiosperms"] == 30
assert pool_kinds("Peacebloom") == set(lineage("Peacebloom")) & {
    t for t in lineage("Peacebloom") if ns.LINES["botany:" + t] is not None}

# migration: old flat counts are replaced once, from the notebook
lua.execute("""
ShandoBotany = { flower = 40, kelp = 2 }
ShandoHerbPicks = { ["Peacebloom"] = { "1:1:1", "1:2:2", "1:3:3" }, ["Grave Moss"] = { "1:4:4" } }
""")
ns.MigrateBotany()
assert g.ShandoBotany["tree"] == 1 and g.ShandoBotany["flower"] is None
assert g.ShandoBotany["daisy"] == 3 and g.ShandoBotany["landplants"] == 4 and g.ShandoBotany["mosses"] == 1
ns.MigrateBotany()                           # a second login changes nothing
assert g.ShandoBotany["daisy"] == 3

assert not lineless, f"taxa with no lines yet: {sorted(lineless)}"
print("ok:", len(list(ns.HERBS.keys())), "herbs placed;",
      len({t for h in ns.HERBS.keys() for t in lineage(h)}), "taxa, each with lines")
