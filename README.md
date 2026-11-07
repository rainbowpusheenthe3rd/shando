<p align="center"><img src="docs/banner.png" alt="Shan'do: A night elf spirit guide for quiet moments."></p>

<h1 align="center"><img src="docs/icon.png" width="56" align="center" alt="Shan'do icon"> Shan'do</h1>
<p align="center"><i>A night elf spirit guide for quiet moments.</i></p>
<p align="center"><b><a href="https://rainbowpusheenthe3rd.github.io/shando/">Listen to it →</a></b></p>

**Shan'do** is a free World of Warcraft addon for **World of Warcraft: Forever** (Classic+): a voiced night elf spirit guide who speaks at quiet moments. She greets storied places, breathes with you when you stand still, keeps rituals for shadowmeld, sleep and prayer, and notices kindness. Made for immersion, roleplay and a calmer evening in Azeroth.

Made for the World of Warcraft: Forever client (interface 16001, also 120105). Free, open source, no adverts.

## What it does

- **Places.** The first visit to a sacred or storied place (Shadowglen to Winterspring, 25 of them) gets a soft swell and one line. Felwood is *wounded, not wicked*: corruption belongs to places, never to you.
- **Stillness.** Stand still outdoors for a while and she offers a breath; then a wind that breathes with you, out-breath longer than in-breath. Moving ends it.
- **Inns.** Rest a minute at an inn: a stream with birds by day, crickets and wind by night, for five minutes.
- **People.** Joining a group (kin), visiting a trainer (teacher), healing or blessing someone else (kindness, with a bell).
- **Milestones.** Levels name a strength you showed; new forms and great spells; herbalism and skinning at 75, 150, 225 and 300; now and then a finished quest gets a chime and a moment to savour it.
- **Hard times.** One gentle word when you fall. After three falls in fifteen minutes, one word about rest, then quiet about dying.
- **Time.** Night, dawn and dusk on the server clock; very late at night, and after a long day's road, a word of care.
- **Rituals you choose.** Shadowmeld meditation (the music dips, the night rises, the wind breathes); /sleep in a barrow den (the screen's edges turn green and the Dream plays); /kneel or /pray at night (moonlight at the edges, a bell); the walk back as a wisp, with a choir.
- **Healing lines.** Inside a ritual you chose, at most once a day, a line about loss or old hurts: always with hope, grounded in research on self-compassion, earned security, compassion-focused therapy, grief and resilience.
- **The look-back.** At your next login, a chime and one sentence recalling your last journey: where you walked, what you gathered, who you helped.
- **Festivals.** Each calendar festival is greeted once a year.
- **Minimap button** at half opacity: left-click for the guide, right-click to rest her, drag to move.

## Install

Download this repository (Code → Download ZIP), and copy the `Shando` folder into
`World of Warcraft\_<flavour>_\Interface\AddOns`. Restart the game fully the first time, so its saved variables
are created.

## Commands

| Command | |
|---|---|
| `/shando` | rest her, or call her back |
| `/shando quieter` | speak less often (down to a quarter) |
| `/shando nearer` | speak more often (up to four times) |
| `/shando help` | the in-game guide |

## The research

[RESEARCH.md](RESEARCH.md) holds every design choice with its evidence: breathing, nature, savouring, kindness, self-compassion, belonging, grief, sound. DOIs were checked; effect sizes are reported with their caveats, and ideas that failed replication are listed as dropped.

## Spoilers

Every line is in `Shando/Lines.lua`. If you'd like to be surprised, don't open it.

## Also

**Herbalore** gives every herb a voice in the same night elf voice: [github.com/rainbowpusheenthe3rd/herbalore](https://github.com/rainbowpusheenthe3rd/herbalore)

## Credits

The voice is AI-generated with [VoxCPM2](https://huggingface.co/openbmb/VoxCPM2) (Apache-2.0): designed once from a
description and used for every line, with a soft moonwell reverb. Every other sound, the icon and the banner are
synthesised from scratch with numpy. Not affiliated with or endorsed by Blizzard Entertainment; World of Warcraft and
its names belong to Blizzard. Code and assets are MIT licensed.
