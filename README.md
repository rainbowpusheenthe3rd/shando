<p align="center"><img src="docs/banner.png" alt="Shan'do: A night elf spirit guide for quiet moments."></p>

<h1 align="center"><img src="docs/icon.png" width="56" align="center" alt="Shan'do icon"> Shan'do</h1>
<p align="center"><i>A night elf spirit guide for quiet moments.</i></p>
<p align="center"><b><a href="https://rainbowpusheenthe3rd.github.io/shando/">Listen to it →</a></b></p>

**Shan'do** is a free World of Warcraft addon for **World of Warcraft: Forever** (Classic+): a voiced night elf spirit guide who speaks at quiet moments. She greets storied places, breathes with you when you stand still, keeps rituals for shadowmeld, sleep and prayer, notices kindness, and gives every herb a voice. Made for immersion, roleplay and a calmer evening in Azeroth.

Made for the World of Warcraft: Forever client (interface 16001, also 120105). Free, open source, no adverts.

## What it does

- **Places.** The first visit to a sacred or storied place (Shadowglen to Winterspring, 25 of them) gets a soft swell and one line. Felwood is *wounded, not wicked*: corruption belongs to places, never to you.
- **Stillness.** Stand still outdoors for a while and she offers a breath; then a wind that breathes with you, out-breath longer than in-breath. Moving ends it.
- **Inns.** Rest a minute at an inn: a Japanese garden by day (water on stones, a water-jar's drops, now and then a bamboo knock), a hearth fire by night, for five minutes.
- **People.** Joining a group (kin), visiting a trainer (teacher), healing or blessing someone else (kindness, with a bell).
- **Milestones.** Levels name a strength you showed; new forms and great spells; herbalism and skinning at 75, 150, 225 and 300; now and then a finished quest gets a chime and a moment to savour it.
- **Hard times.** One gentle word when you fall. After three falls in fifteen minutes, one word about rest, then quiet about dying.
- **Time.** Night, dawn and dusk on the server clock; very late at night, and after a long day's road, a word of care.
- **Rituals you choose.** Shadowmeld meditation (the music dips, the night rises, the wind breathes); /sleep in a barrow den (the screen's edges turn green and the Dream plays); /kneel or /pray at night (moonlight at the edges, a bell); the walk back as a wisp, with night crickets.
- **Healing lines.** Inside a ritual you chose, at most once a day, a line about loss or old hurts: always with hope, grounded in research on self-compassion, earned security, compassion-focused therapy, grief and resilience.
- **The look-back.** At your next login, a chime and one sentence recalling your last journey: where you walked, what you gathered, who you helped.
- **Festivals.** Each calendar festival is greeted once a year.
- **Herbs and skinning.** Every herb, rare find and seed has its own lines, the unheard ones first; skinning gets a word of thanks. Each has its own switch in the settings. (This was the Herbalore addon; it is part of Shan'do now.)
- **Real sound.** The soundscapes are real field recordings, with single drops, crackles and knocks laid over them at random gaps, so they never loop the same way twice.
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

Every line is in `Shando/Lines.lua` and `Shando/HerbLines.lua`. If you'd like to be surprised, don't open it.

## Also

**Herbalore**, the herb voices, is now part of Shan'do (switch it off in the settings). Its own repo stays up for anyone who wants herbs alone: [github.com/rainbowpusheenthe3rd/herbalore](https://github.com/rainbowpusheenthe3rd/herbalore)

## Credits

The voice is AI-generated with [VoxCPM2](https://huggingface.co/openbmb/VoxCPM2) (Apache-2.0): designed once from a
description and used for every line, with a soft moonwell reverb. The soundscapes are real field recordings, cut, looped and levelled for the game (changes made); the chime and the kindness bell were generated with [MOSS-SoundEffect](https://github.com/OpenMOSS/MOSS-TTS) (Apache-2.0).

| File | From | Licence of the file |
|---|---|---|
| `sfx/dream.mp3, sfx/dream/ (barrow den)` | [Bourne woods rain 2020-05-10 0757](https://commons.wikimedia.org/wiki/File:Bourne_woods_rain_2020-05-10_0757.mp3) by Robert EA Harvey, CC BY-SA 4.0<br>[Light Rain Distant Thunder July 5th 2016](https://freesound.org/people/kvgarlic/sounds/349454/) by kvgarlic, CC0 | CC BY-SA |
| `sfx/vigil.mp3 (vigil)` | [Nature sounds ambience in a Dordogne pond](https://commons.wikimedia.org/wiki/File:Nature_sounds_ambience_in_a_Dordogne_pond.ogg) by Glaneur de sons, CC BY 3.0 | as its sources |
| `sfx/inn_day.mp3, sfx/inn_day/ (an inn by day)` | [Water on Rocks](https://commons.wikimedia.org/wiki/File:Water_on_Rocks.ogg) by Dsw4, CC BY 3.0<br>[Suikinkutsu recording](https://commons.wikimedia.org/wiki/File:Suikinkutsu_recording.ogg) by Torsodog, from Waterharpsound.ogg by Shizhao, CC BY-SA 3.0<br>[Suikinkutsu-LS100109 and -LS100112](https://commons.wikimedia.org/wiki/File:Suikinkutsu-LS100109.ogg) by Fg2, public domain | CC BY-SA |
| `sfx/swell.mp3 (a place)` | [Suikinkutsu recording](https://commons.wikimedia.org/wiki/File:Suikinkutsu_recording.ogg) by Torsodog, from Waterharpsound.ogg by Shizhao, CC BY-SA 3.0 | CC BY-SA |
| `sfx/inn_night.mp3, sfx/inn_night/ (an inn at night)` | [Campfire sound ambience](https://commons.wikimedia.org/wiki/File:Campfire_sound_ambience.ogg) by Glaneur de sons, CC BY 3.0<br>[Dry grass burning in open fireplace](https://commons.wikimedia.org/wiki/File:Dry_grass_burning_in_open_fireplace.ogg) by ezwa, public domain | as its sources |
| `sfx/meld.mp3 (shadowmeld at night)` | [Summer Night in the Swamp: Authentic Frogs & Crickets Soundscape](https://freesound.org/people/hafijur_rahman/sounds/853607/) by hafijur_rahman, CC0 | as its sources |
| `sfx/meld_day.mp3 (shadowmeld by day)` | [River Stream, Lake of Glacier, Lago del Desierto](https://freesound.org/people/Singular_Estudio/sounds/510232/) by Singular_Estudio, CC0 | as its sources |
| `sfx/windbreath.mp3 (the breathing wind, shaped to a slow breath)` | [Wind, Mistral gusts, dry grass](https://freesound.org/people/silencyo/sounds/81798/) by silencyo, CC0 | as its sources |
| `sfx/wisp.mp3 (the wisp)` | [crickets](https://freesound.org/people/zerrofs/sounds/118419/) by zerrofs, CC0 | as its sources |

The icon and the banner are
drawn in code. Not affiliated with or endorsed by Blizzard Entertainment; World of Warcraft and its names belong to
Blizzard. Code and the voice files are MIT licensed; the sound files keep their sources' licences, in the table above.
