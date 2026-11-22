# Changelog

## Unreleased

### New

- A third meditation, The acorn: about twenty-two minutes beneath an old oak. Jays forget where they buried their
  acorns, brambles guard the seedlings from deer, an oak takes forty years to bear its first acorn, and when it falls
  at last a stag beetle's young spend years inside it, turning it back into soil. Every great oak was once just an
  acorn seed. Choose it in the options, or let Random find it.
- With Homeland installed, a meditation can dress the minimap in its own wreath from the first bell until the frogs
  fade, then give you back your own. Without Homeland nothing changes. The acorn has one already: oak, acorns,
  bramble and stag beetles.

### Bug fixes

- Meditations now end when their own script does. Every one used to stop at a fixed 21 minutes, which would have
  left The acorn's farewell unsaid.

## 1.2.1 (15 Nov 2026)

### Bug fixes

- Fixed an issue where Shan'do would kneel over a freshly defeated Twilight cultist and speak softly of the animal's
  warmth leaving the hide. It was his trousers. Skinning lines now wait for your own Skinning cast just before the
  loot.
- Fixed an issue where healing yourself counted as a kindness to a stranger. Shan'do was very moved that you had
  helped someone, and that someone was you. Forever names your spell's target in full while the game gives your own
  name as the first name only; a name now matches on its first word too.
- Shan'do's memory has been improved. She forgot everything she'd said every third login (sometimes the second),
  and once that was fixed she still forgot any line older than three logins, so she'd mention the night birds again
  with 36 night lines she had never said still waiting their turn. She now picks the line you've heard fewest times
  across all your play, so every line is heard once before any comes round twice. The three-session count now only
  sets how long she waits between repeats once a kind's lines have all been heard.
- Fixed an issue where the game's music didn't come back if the game closed mid-Shadowmeld. The line that restores
  it was folded into a comment in 1.2.0, where it stayed perfectly still and unseen, as Shadowmeld intends.
- Mageroyal is now said "Mage royal", as the game says it. The flower has been informed.

## 1.2.0 (13 Nov 2026)

- **Twice as much to say.** 574 new lines, all in her night elf voice: more for breathing, night, Shadowmeld,
  quests, levelling, flights, new zones, logging in and out, Darnassus, Felwood, inns, swimming, groups,
  trainers, death, the Dream and vigils, plus new quiet lines for herbalism and skinning. About 1,100 lines in all.
- **Botany as you gather.** Each herb belongs to a real plant family it's named after or looks like: kelp, moss,
  lichen, mushrooms, grasses, lilies, lotuses, the daisy family, roots, thorns, or flowering plants in general.
  Gather a family's herbs and Shan'do teaches a little about it, in three levels that open at 1, 10 and 30
  gathers: what you can see, how it lives, and where it sits in the long history of plants.
- **Less repetition.** She now says the line you've heard least, so you hear every line of a kind before any
  repeats. The count runs across three play sessions, then starts again.
- **Quieter as lines repeat.** Once you've heard every line of a kind, the wait before that kind speaks again
  grows 1.6 times with each round of repeats. Kinds with many lines rarely get there.
- **Kindness, properly.** Buffing yourself no longer counts as a kindness to a stranger, including when an enemy
  is targeted or your name carries a realm.
- "Elune-adore" is now said "Elune ador-ey", as night elves say it (seven lines re-recorded).
- In /emerald dream, moving fades the current line out before she says you've come back.
- The herbalism pace setting now sets how long each herb rests before it speaks again.

## 1.1.0 (10 Nov 2026)

- **/emerald dream**: two guided meditations, each about ten minutes of gentle guidance and then about ten of
  frogs at the water's edge, fading slowly back to the game's own sound. **The clearing**: the sounds around you,
  the breathing wind, and the Emerald Dream as a place. **The moonwell**: grounding by touch, a breath you shape
  yourself, savouring one small good moment, a word of thanks, and a moonwell's light; it ends at a pond.
  The world's ambient sound and music fade out while it lasts, and each line has a soft caption.
- Moving ends a meditation at once, and Shan'do says so; a faint line under the captions says it all along.
  Combat ends it too, with the world's sound back straight away.
- Options: choose a meditation, or Random (each one you haven't heard first, then in turn), and Begin.
- The source now lives in this repo (it used to be mirrored from a private one).
- The "My own voice" options only appear when recordings are present; none ship with the addon.
