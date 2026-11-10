-- Written by tools/shando.py from lines.tsv; edit that, not this.
local _, ns = ...
ns.LINES = {
    ["login"] = {
        { "login1", "Ishnu-alah, thero'shan. Good fortune to you, honoured student. Let's walk gently today." },
        { "login2", "Elune-adore. Elune be with you. Wherever today takes you, I'll be close." },
        { "login3", "Welcome back. The forest kept growing while you were away. Shall we go and see what changed?" },
        { "login4", "Andu-falah-dor. Let balance be restored. Come, the day is young." },
    },
    ["zone"] = {
        { "zone1", "A new place. Before the road pulls you on, perhaps look at it properly, once." },
        { "zone2", "Every land has its own quiet. Hear how this one sounds, if you like." },
        { "zone3", "The trees here have stood a long time. They don't mind waiting while you look around." },
        { "zone4", "New ground. Somewhere in it is a view nobody's shown you yet." },
        { "zone5", "Stand still a moment, if you like. Let this place learn your footsteps before you learn its roads." },
    },
    ["night"] = {
        { "night1", "The White Lady is watching. The kaldorei say she keeps watch over the world while it sleeps." },
        { "night2", "Kaldorei. Children of the stars. Our people took their name from the night sky. It's yours to look at, whenever you like." },
        { "night3", "Night is not the absence of light. It's the time for a gentler one." },
        { "night4", "The White Lady and the Blue Child, crossing the sky together. Even the moons keep each other company." },
        { "night6", "The kaldorei kept their vigil under these same stars. You're keeping it with them now." },
        { "night7", "Moonlight on the leaves. Nothing needs doing. Just look." },
        { "night5b", "The kaldorei believed Elune slept in the waters of the Well by day, and woke with the night. You may rest too. Rest was never something you had to earn." },
    },
    ["breath"] = {
        { "breath1", "You've stopped. Good. Perhaps a slow breath in, and a slower one out. Let your shoulders fall, if they want to." },
        { "breath2", "Nothing to do right now. Only the breath going in, and the breath going out, and the leaves moving." },
        { "breath3", "Three things you can hear, if you listen. Wind, water, something small in the grass. Stay with them a moment." },
        { "breath4", "The druids say you don't have to do anything to be part of the forest. You only have to stay still long enough to notice it." },
        { "breath5", "Feel where you're standing. The ground is holding you up. It always has." },
        { "breath6", "Try letting each breath out last a little longer than the breath in. Once more. The forest is breathing with you." },
        { "breath7", "Let your eyes go soft, if you like. Nothing in particular to look at. Only the light coming in." },
        { "breath8", "If your jaw's tight, let it go. Shoulders too. The world can wait a breath." },
    },
    ["rest"] = {
        { "rest1", "A roof, a hearth, and a little quiet. Sit for a while. Elune-adore." },
        { "rest2", "Rest is part of the path, not a break from it. Even the oaks sleep through winter." },
        { "rest3", "You're safe here. Let the day settle." },
        { "rest4", "Warm hands, a full belly, somewhere to sit. The old druids would call that a good day." },
    },
    ["flight"] = {
        { "flight1", "Let the wind carry you. From up here, the roads you worried over look like threads." },
        { "flight2", "Look down, if you like. Every place you've walked is one small part of a much bigger world." },
        { "flight3", "The hippogryph knows the way. You don't have to steer. Just watch." },
        { "flight4", "Forests, rivers, roads. All of it, still there tomorrow. Enjoy the view." },
    },
    ["water"] = {
        { "water1", "The first kaldorei made their home beside the Well of Eternity. Water has always been where our people gathered." },
        { "water2", "Let the water hold you up. You don't have to swim hard. Float, for a breath." },
        { "water3", "Moonwells hold Elune's light the way a cup holds water. Rest beside one, if you pass it." },
    },
    ["death"] = {
        { "death1", "Shh. It's all right. When a night elf falls, they walk on as a wisp, a little light in the dark. Find your way back slowly." },
        { "death2", "Ande'thoras-ethil. May your troubles be diminished. The path home is long, but it's always there." },
        { "death3", "Falling is part of every journey. Nothing you've learned is lost. Walk back gently." },
        { "death4", "Rest a moment in the quiet. The spirit healer has seen a thousand travellers find their way back." },
    },
    ["level"] = {
        { "level1", "Another ring on the tree. Perhaps take a moment to notice how far the road has come." },
        { "level2", "Another step on the path, thero'shan. I was glad to walk it with you." },
        { "level3", "The oak grows one ring at a time, and never in a hurry." },
        { "level4", "Like a sapling turning to the light, another season of growth. Gently does it." },
        { "level5", "Patience got you here. One step, then another, and no hurry in any of them." },
        { "level6", "You took care on the way, of the land and the people in it. That counts for more than the number." },
        { "level7", "Curiosity is a strength too. You kept stopping to look, and the world kept answering." },
    },
    ["place:Shadowglen"] = {
        { "place1", "Shadowglen. Where so many kaldorei first open their eyes. Everything here is young, and in a way, so are you." },
    },
    ["place:Aldrassil"] = {
        { "place2", "Aldrassil. A tree that holds a whole village in its arms. If you like, rest a hand on the bark as you pass." },
    },
    ["place:Dolanaar"] = {
        { "place3", "Dolanaar. Lanterns, a moonwell, and kaldorei going about their evening. This is what peace looks like when it's ordinary." },
    },
    ["place:Lake Al'Ameth"] = {
        { "place4", "Lake Al'Ameth. Still water, and the sky in it twice. Stay a moment, if you'd like, and let the water do the looking." },
    },
    ["place:Pools of Arlithrien"] = {
        { "place5", "The Pools of Arlithrien. Quiet water under old trees. Some places ask you to lower your voice. This is one." },
    },
    ["place:Oracle Glade"] = {
        { "place6", "Oracle Glade. Old places have long memories. You don't need to understand them to be welcome." },
    },
    ["place:Ban'ethil Barrow Den"] = {
        { "place7", "A barrow den. Druids once slept beneath the earth in places like this, dreaming the world well. Tread softly." },
    },
    ["place:Rut'theran Village"] = {
        { "place8", "Rut'theran. The roots of Teldrassil reach the sea here. Every journey out of the forest begins at its feet." },
    },
    ["place:Darnassus"] = {
        { "place9", "Darnassus. High in the branches of Teldrassil, the World Tree's own city. Lanterns, water, and nobody in a hurry." },
    },
    ["place:Temple of the Moon"] = {
        { "place10", "The Temple of the Moon. The Sisters of Elune keep their vigil here. You don't need to pray. Just listen to the water." },
    },
    ["place:Cenarion Enclave"] = {
        { "place11", "The Cenarion Enclave. Every druid here was once a student who didn't yet know their own shape. You're among kin." },
    },
    ["place:Auberdine"] = {
        { "place12", "Auberdine. Sea wind, and boats waiting at the pier. The wide world is just over that water." },
    },
    ["place:Bashal'Aran"] = {
        { "place13", "Bashal'Aran. The Highborne lived here once, and loved the Well's magic more than anything. Hunger is a hard master. Pity them, if you can." },
    },
    ["place:Ameth'Aran"] = {
        { "place14", "Ameth'Aran. Ruins, and restless spirits. Not everything broken here was wicked. Some of it was only lost." },
    },
    ["place:Grove of the Ancients"] = {
        { "place15", "The Grove of the Ancients. They were old before the first city rose. Under branches like these, a worry looks very short." },
    },
    ["place:Astranaar"] = {
        { "place16", "Astranaar. The Sentinels keep watch so others can sleep. There's a quiet kind of love in that." },
    },
    ["place:Ashenvale"] = {
        { "place17", "Ashenvale. The oldest forest our people know. Look up, if you like. The canopy has been growing for longer than anyone remembers." },
    },
    ["place:Moonglade"] = {
        { "place18", "Moonglade. The druids' sanctuary, open to anyone who comes in peace. Here, nobody needs to be on guard." },
    },
    ["place:Nighthaven"] = {
        { "place19", "Nighthaven. Lantern light on the lake, and nothing at all to hurry for." },
    },
    ["place:Felwood"] = {
        { "place20", "Felwood. This forest is wounded, not wicked. Every tree here would grow green again, given the chance." },
    },
    ["place:Emerald Sanctuary"] = {
        { "place21", "The Emerald Sanctuary. Druids, staying in a wounded forest to heal it, one tree at a time. That's what devotion looks like." },
    },
    ["place:Jaedenar"] = {
        { "place22", "Jaedenar. Something sacred was taken here and turned. It isn't yours to carry. Only to set right, a little, if you choose." },
    },
    ["place:Winterspring"] = {
        { "place23", "Winterspring. Snow under starlight, and air so clean it almost rings. Take a long breath of it, if you like." },
    },
    ["place:Starfall Village"] = {
        { "place24", "Starfall Village. Kaldorei, living in the cold and the quiet. Kin can be found at every edge of the world." },
    },
    ["place:Feathermoon Stronghold"] = {
        { "place25", "Feathermoon Stronghold. The Sentinels' island home. Strength that stands guard, and asks nothing back." },
    },
    ["wounded"] = {
        { "wounded1", "Felwood again. Grief for a place is a kind of love. Let it be what it is." },
        { "wounded2", "The sickness is in the land, not in you. You can walk through it and still be whole." },
        { "wounded3", "Every cleansed moonwell here was someone's patient work. Small mending still counts." },
    },
    ["home"] = {
        { "home1", "Home. The branches hold the moonlight here like a cupped hand." },
        { "home2", "Back among the kaldorei. Belonging doesn't have to be earned, thero'shan. It's simply yours." },
        { "home3", "Darnassus. Somewhere, a Sentinel is trading stories with a priestess. Life goes on, gently, while you're away." },
    },
    ["kin"] = {
        { "kin1", "Ishnu-dal-dieb. Good fortune to your family. Kin can be chosen, and for a while, these ones are yours." },
        { "kin2", "Tyrande raised Shandris as her own, and Shandris grew up to lead the Sentinels. Family is something you make, too." },
        { "kin3", "Companions. Even the Sentinels keep watch in pairs." },
        { "kin4", "Travel well together. The road is kinder with someone beside you." },
    },
    ["teacher"] = {
        { "teacher1", "Every shan'do was once a thero'shan. Learning from someone is an honour, not a lessening." },
        { "teacher2", "A good teacher wants you to need them less. Take what they offer, and make it yours." },
        { "teacher3", "Malfurion himself was Cenarius's student. There's no shame in being early on the path." },
    },
    ["form:Bear Form"] = {
        { "form1", "The bear. Strength that protects, not strength that dominates. Wear it gently." },
    },
    ["form:Aquatic Form"] = {
        { "form2", "The seal's shape. The water was never your enemy. Now it's your road." },
    },
    ["form:Cat Form"] = {
        { "form3", "The cat. Quiet paws, patience, and knowing when to wait. The forest teaches all three." },
    },
    ["form:Travel Form"] = {
        { "form4", "Swift as a stag. Go far, if you like, but there's no prize for arriving first." },
    },
    ["form:Moonkin Form"] = {
        { "form5", "The moonkin. Elune's light, given feathers and a heartbeat." },
    },
    ["form:Rebirth"] = {
        { "form6", "Rebirth. You can call someone back from death now. A gift worth giving freely." },
    },
    ["form:Teleport: Moonglade"] = {
        { "form7", "Moonglade, whenever you need it. A sanctuary is only a thought away now." },
    },
    ["form:Tranquility"] = {
        { "form8", "Tranquility. The rarest thing a druid can give: calm, poured out over everyone near you." },
    },
    ["form:Hurricane"] = {
        { "form9", "The storm is part of nature too. Even fury can be held with care." },
    },
    ["kindness"] = {
        { "kindness1", "A stranger, blessed in passing. Kindness like that travels further than you'll ever see." },
        { "kindness2", "Help for someone who may never know your name. The forest does that every day, too." },
        { "kindness3", "Small mercies, freely given. Whoever receives one tends to pass it on." },
    },
    ["repair"] = {
        { "repair1", "That's been hard. It's all right to feel worn down by it. Perhaps rest a while; the grove will wait." },
        { "repair2", "Setbacks are part of every path. Andu-falah-dor. Balance comes back, a little at a time." },
        { "repair3", "Nothing here is lost that can't be found again. If you like, step back, eat, rest, and then decide." },
    },
    ["linger"] = {
        { "linger1", "Linger on this a moment. Something's finished, and it went well." },
        { "linger2", "Before the next thing, notice this one. A small task, done with care." },
        { "linger3", "There. Let that settle before you move on. The next road will keep." },
        { "linger4", "A good moment. They're easy to walk straight past." },
    },
    ["dawn"] = {
        { "dawn1", "Dawn. The White Lady hands the sky to the sun, and the forest wakes up yawning." },
        { "dawn2", "First light. Night elves rest now, mostly. You may too, if the night's been long." },
    },
    ["dusk"] = {
        { "dusk1", "Dusk. The kaldorei day is beginning. Listen. The forest changes its voice." },
        { "dusk2", "The sun's going down. Our hours are coming. Elune-adore." },
    },
    ["deepnight"] = {
        { "deepnight1", "The night's grown very deep, thero'shan. Even Sentinels hand over the watch. The roads will keep until you've slept." },
        { "deepnight2", "It's late, even by kaldorei reckoning. Tomorrow's walk will be kinder after some rest." },
    },
    ["longroad"] = {
        { "longroad1", "You've walked a long way today. Is there someone you'd like to share the road with? A word to a friend is a kind of shelter." },
        { "longroad2", "A long journey. Perhaps stretch, drink some water, and look at something far away for a moment." },
    },
    ["skill:Herbalism:75"] = {
        { "skill1", "Seventy-five in herbalism. The plants are starting to recognise your hands." },
    },
    ["skill:Herbalism:150"] = {
        { "skill2", "A hundred and fifty. Meadows, hillsides and riverbanks have all passed through your fingers." },
    },
    ["skill:Herbalism:225"] = {
        { "skill3", "Two hundred and twenty-five. You know the herbs by their scent now, and they know you." },
    },
    ["skill:Herbalism:300"] = {
        { "skill4", "Three hundred. An artisan of growing things. And every herb you ever picked grew back." },
    },
    ["skill:Skinning:75"] = {
        { "skill5", "Seventy-five in skinning. Every hide is a life given. You're learning to waste nothing." },
    },
    ["skill:Skinning:150"] = {
        { "skill6", "A hundred and fifty. Careful, respectful work. The beasts deserved that, and got it." },
    },
    ["skill:Skinning:225"] = {
        { "skill7", "Two hundred and twenty-five. A steady knife, and steady thanks." },
    },
    ["skill:Skinning:300"] = {
        { "skill8", "Three hundred. A master's hands, and still a grateful heart." },
    },
    ["meld"] = {
        { "meld1", "Shadowmeld. The forest folds around you, and for a while, nobody needs anything from you." },
        { "meld2", "Hidden in plain sight, as our people always have been. Stay as long as you like." },
        { "meld3", "Still as a Sentinel on watch. Only, just now, there's nothing to watch for. Let the sounds come to you." },
        { "meld4", "Shadowmeld. The kaldorei learned to be still as the forest itself. Let the breath come and go on its own for a while." },
        { "meld5", "In the shadow, nobody's looking. There's nothing to do and no one to be. Only this breath, and the next." },
        { "meld6", "Hidden, and safe. If you like, follow the wind as it rises and falls. The light at the edges will breathe with you." },
    },
    ["dream"] = {
        { "dream1", "The Dream is close here. The druids who slept in these dens walked it for years. A little while is plenty." },
        { "dream2", "Rest, if you'd like. The world is green and slow on the other side of sleep, and nothing there needs fixing." },
        { "dream3", "The Emerald Dream. The world as it might have been, untouched. Wake whenever you're ready." },
    },
    ["vigil"] = {
        { "vigil1", "Elune-adore. She doesn't ask for words. Kneeling under her light is enough." },
        { "vigil2", "The White Lady's light is on your shoulders. Whatever you've carried today, you can set it down here for a while." },
        { "vigil3", "The moon wanes, and comes back whole. Every time. Elune-adore." },
    },
    ["recall"] = {
        { "recall1", "Before the road starts again, a look back at the last one." },
        { "recall2", "Ishnu-alah. Here's what your last walk held, before the new one begins." },
        { "recall3", "The last journey, in a few words. Let it settle before today's begins." },
    },
    ["farewell"] = {
        { "farewell1", "Rest well, thero'shan. The forest will be here." },
        { "farewell2", "Elune-adore. Sleep under her light." },
        { "farewell3", "Ishnu-alah. Until the next road." },
    },
    ["holiday:Lunar Festival"] = {
        { "holiday1", "The Lunar Festival. The druids of Moonglade fill the sky with fireworks, and the Elders are honoured for their wisdom. Look up tonight, if you can." },
        { "holiday2", "The Lunar Festival. Nighthaven's lanterns are lit, and Moonglade is full of guests. Every people's old and wise ones are honoured this week." },
    },
    ["holiday:Harvest Festival"] = {
        { "holiday3", "The Harvest Festival. Tables full, fields gathered in, and the heroes of old remembered. The bread is still warm." },
        { "holiday4", "Harvest time. Every herb you've gathered this year was part of it. Eat well, and share." },
    },
    ["holiday:Feast of Winter Veil"] = {
        { "holiday5", "The Feast of Winter Veil. Snow, lanterns, and gifts left for strangers. Kindness, wrapped in paper." },
    },
    ["holiday:Hallow's End"] = {
        { "holiday6", "Hallow's End. Candles in carved faces, and sweets for anyone brave enough to knock. Even the dark can be played with." },
    },
    ["holiday:Midsummer Fire Festival"] = {
        { "holiday7", "The Midsummer Fire Festival. Bonfires on every hill, and the shortest night of the year. For the kaldorei, that's a small sacrifice." },
    },
    ["holiday:Children's Week"] = {
        { "holiday8", "Children's Week. The cities are full of small adventurers, and anyone can spend a day showing one of them something wonderful. Wonder is easy to share." },
        { "holiday9", "A week for play. Sweets, small adventures, and someone with time to listen. That kind of care can come from anyone, at any age." },
        { "holiday10", "Children's Week. If it stirs something old, that's all right. Whatever wasn't given back then, care can still be given now, by friends, by the forest, and by you, to yourself." },
    },
    ["mend"] = {
        { "mend1", "Some of us grew up without the ones who should have held us. If that's you, you're far from alone, and no less a child of the stars." },
        { "mend2", "The kaldorei say some of their dead stay on as wisps, small lights tending the forest. Whatever we do with grief, love that was given doesn't vanish. It lives on in what it grew." },
        { "mend3", "Shandris wasn't born to Tyrande. She was raised by her, and grew strong in that care. Hearts keep learning what safety feels like, from whoever offers it, at any age." },
        { "mend4", "If an old ache stirs, you might speak to it the way I speak to you. Gently, and without hurry. That voice can become your own." },
        { "mend5", "Grief comes and goes, like the tide at Rut'theran. It's all right to feel it, and all right to set it down for a while and simply walk." },
        { "mend6", "Healing is mostly made of ordinary things. Warm food, a friend's voice, sleep, the forest. They add up, slowly, like rings in a tree." },
        { "mend7", "Ande'thoras-ethil. May your troubles be diminished. Old wounds do soften, given care and time. The forest has seen it happen many times." },
    },
    ["meldend"] = {
        { "meldend1", "There. The breath has done its work. Stay as long as you like, and step out when you're ready." },
        { "meldend2", "Elune-adore. Whatever you brought into the shadow, you can leave a little of it here." },
        { "meldend3", "The forest kept watch while you rested. It always will." },
        { "meldend4", "Slower now, and steadier. Carry a little of this stillness with you." },
    },
    ["moonwell"] = {
        { "moonwell1", "Nothing given in this forest is lost, thero'shan. The leaf falls to feed the root, and the root raises the leaf. What you poured out will return to you, changed, and the same." },
    },
    ["emerald"] = {
        { "emerald01", "Ishnu-alah, thero'shan. Welcome. Let's rest in the Dream together for a while. There's nothing to do well here. You only have to arrive, just as you are." },
        { "emerald02", "Your eyes can close, or soften, and rest on something low and still. Whichever feels kinder. And if anything feels wrong, simply move, and we'll come back. You're always free to." },
        { "emerald03", "Let yourself settle. Let the chair take your weight, and the floor take the chair. You don't have to hold yourself up just now. It's being done for you." },
        { "emerald04", "Listen for the furthest sound you can hear, out beyond your room. No need to name it. Just let it be there." },
        { "emerald05", "And now the nearest sound. Perhaps your own breath. Perhaps nothing at all. Quiet is welcome too." },
        { "emerald06", "Let your shoulders soften, if they'd like to. Your jaw. The small place between your eyebrows. Nothing to force. Only an invitation." },
        { "emerald07", "Now the breath, whenever you're ready. Let it come in on its own, and leave a little more slowly than it came." },
        { "emerald08", "In, as the wind rises. Out, longer and softer, as it falls." },
        { "emerald09", "If your mind wanders, that's alright. Minds wander. Each time you notice and come back, that's the practice, and you're doing it." },
        { "emerald10", "Once, only if you'd like: breathe in, then one more small sip of air on top. And let it all go, slowly, like a long sigh." },
        { "emerald11", "You can let the breath find its own pace now. It knows the way." },
        { "emerald12", "The druids say the Emerald Dream is the world as it would be, left to grow on its own. Picture a clearing there, if you like. Soft moss underfoot. Cool night air. Moonlight through tall trees. A silver moth landing on your hand, gentle and forgiving, like the breeze." },
        { "emerald13", "Tall grass, moving in a gentle wind. Somewhere close, still water, holding the stars. Everything here grows at its own pace, and so can you." },
        { "emerald14", "Nothing grows faster for being pulled. With each breath out, let something in you settle, the way leaves settle on still water." },
        { "emerald15", "Nothing to fix here. Nothing to earn. You're allowed to simply rest." },
        { "emerald16", "If it's welcome, a few words for yourself. Perhaps: may I be at ease. May I be gentle with myself. Or whatever words fit better." },
        { "emerald17", "You've carried a great deal to get here. It's alright to set some of it down, just for now. It will keep." },
        { "emerald18", "And a kind wish for someone else out there today. Someone you know, or someone you'll never meet. May they rest too. Everyone is carrying something." },
        { "emerald19", "Rest here a little longer. I'll keep watch." },
        { "emerald20", "And now, just listen. The water's edge is waking around you. Frogs, singing the day gently closed. Stay with them as long as you like." },
        { "emerald21", "Slowly now, whenever you're ready, come back towards waking. Feel your hands. Perhaps move your fingers, and your shoulders." },
        { "emerald22", "When you'd like to, open your eyes. Look around, and find one thing you can see." },
        { "emerald23", "Andu-falah-dor, thero'shan. Balance restored, a little. That was well done. The Dream will keep. So will I." },
    },
    ["walk"] = {
        { "walk01", "Ishnu-alah, thero'shan. Come, let's walk into the Dream together for a little while. Eight minutes or so. Close your eyes, or let them rest on something low and still. Whichever feels kinder." },
        { "walk02", "If anything feels wrong at any point, simply move, and we'll come back. You're always free to." },
        { "walk03", "Let the waking world go quiet. Listen for the furthest sound in your own room. And then the nearest one." },
        { "walk04", "Notice what's holding you up. The chair, the floor beneath it. You don't have to hold yourself up just now. It's being done for you." },
        { "walk05", "Now the breath, if you like. Nothing to force. Let it come in on its own, and leave a little more slowly than it came." },
        { "walk06", "In, as the wind rises. Out, longer, as it falls. Let the breath out be the longest part." },
        { "walk07", "If your mind wanders, that's what minds do. Noticing is the practice. Come back to the wind, gently, as many times as it takes." },
        { "walk08", "Once, if you'd like: breathe in, then take one more small sip of air on top. And let it all go, slowly." },
        { "walk09", "The druids say the Emerald Dream is the world as it would be, left to grow on its own. Picture a clearing there, if you like. Soft moss underfoot. Cool night air. Moonlight through tall trees. A silver moth landing on your hand, gentle and forgiving, like the breeze." },
        { "walk10", "Nothing grows faster for being pulled. With each breath out, let something in you settle, the way leaves settle on still water." },
        { "walk11", "Nothing to fix here. Nothing to earn. The Dream asks nothing of you, only that you rest in it." },
        { "walk12", "If it's welcome, a wish for yourself. Perhaps: may I rest. May I be at peace. Or whatever words fit better." },
        { "walk13", "And one for someone else out there today. Someone you know, or someone you'll never meet. May they rest too. Everyone is carrying something." },
        { "walk14", "Slowly now, back towards waking. Feel your hands. Perhaps move your fingers, and your shoulders." },
        { "walk15", "When you're ready, open your eyes. Look around, and name one thing you can see." },
        { "walk16", "Andu-falah-dor, thero'shan. Balance restored, a little. The Dream will keep. So will I." },
    },
    ["dreamstop"] = {
        { "dreamstop1", "You moved, so we've come back from the Dream. That's alright. It will be here whenever you'd like to return." },
        { "dreamstop2", "Something needs you. Go carefully. The Dream will keep." },
    },
}
