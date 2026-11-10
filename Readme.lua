-- The in-game readme: Options > AddOns > Shan'do, or /shando help. Describes what she answers to, never her lines.
local _, ns = ...

local TEXT = [[
|cffb8c8ffShan'do|r is a night elf spirit guide. She speaks to you as a teacher (|cffb8c8ffshan'do|r) to a student (|cffb8c8ffthero'shan|r), at quiet moments, and only now and then.

|cffffd100When she speaks|r
  - Sacred and storied places, the first time you arrive, after a soft swell.
  - Standing still outdoors for a while: a breath, then a wind that breathes slowly with you.
  - Resting at an inn: a Japanese garden by day (water on stones, a water-jar's drops, now and then a bamboo knock), a hearth fire by night.
  - Night, dawn and dusk; flights; swimming; coming home to Darnassus.
  - People: joining a group, visiting a trainer, healing or blessing someone else.
  - Milestones: levels, new forms and great spells, profession milestones, now and then a finished quest.
  - Hard times: a gentle word when you fall; after several falls, one word about rest, then quiet.
  - Very late at night, or after a long day's road, a word of care.
  - The festivals of the year, once each.
  - At login, a look back at your last journey.

|cffffd100Rituals you can choose|r
  - |cffb8c8ffShadowmeld|r out of combat: the music softens, the night rises around you, and the wind breathes. Move to return.
  - |cffb8c8ff/emerald dream|r (or /dreamemerald): a guided meditation of about fifteen minutes, into the Emerald Dream, ending with frogs at the water's edge. The world's sounds and music fade while it lasts. Eyes open or closed; move, fight, or type it again to come back. If it ever leaves you feeling worse rather than better, stop: that happens to some people with meditation, and it's fine to leave it.
  - |cffb8c8ff/sleep|r in a barrow den: the edges of the world turn green, and the Dream plays until you stand.
  - |cffb8c8ff/kneel|r or |cffb8c8ff/pray|r outdoors at night, or in the Temple of the Moon: moonlight, a bell, and a word.
  - If you fall and walk back as a wisp, the quiet crickets of a night meadow walk with you.

|cffffd100Herbs and skinning|r
  - Gathering a herb: one of its lines, the ones you haven't heard first. Each line, and each herb, then rests longer every time.
  - Now and then while gathering, a quiet line instead, about slowing down.
  - Skinning: a word of thanks the first time each session, then now and then.
  - Both have their own switch in the settings. (This was the Herbalore addon; it is part of Shan'do now.)

|cffffd100How she speaks|r
She invites, never instructs. She speaks about the world and what you did, not about what you are. She never speaks in combat or in dungeons, and leaves at least 45 seconds between any two words, herbs included. Each line rests longer every time you hear it, so nothing repeats through an evening.

|cffffd100Settings|r
Left-click the moon by the minimap (or |cffb8c8ff/shando options|r): on or off, how often she speaks, the quiet gap between any two lines, how strong the ritual screen edges are, soundscapes on or off, herb voices and skinning on or off, and how often herbs speak. Right-click it to rest her; drag it to move it.

|cffffd100Commands|r
  |cffb8c8ff/shando|r  rest her, or call her back
  |cffb8c8ff/shando quieter|r  /  |cffb8c8ff/shando nearer|r  speak less or more often
  |cffb8c8ff/shando options|r  settings
  |cffb8c8ff/shando voice|r  her voice, your own recordings, or yours with a night-elf treatment, in turn
  |cffb8c8ff/shando listen|r  play your own recordings, one after another
  |cffb8c8ff/shando moonwell|r  mark the moonwell you're standing in, so she knows it
  |cffb8c8ff/shando help|r  this page

|cffffd100Where it comes from|r
Her choices follow research on nature, breathing, savouring, kindness, self-compassion, belonging and grief, kept with its sources in the wow-market repository (docs/spirit/RESEARCH.md). She is company, not therapy.

She keeps a small notebook in your saved variables: where each herb was picked, and anything from a herb node that has no line yet. It never leaves your computer.

The soundscapes are real field recordings (Freesound and Wikimedia Commons, CC0 and CC BY; the credits are in the README).

|cff888888Voice: one designed voice, recorded for each line. Sounds: synthesised for her, no samples.|r

Ishnu-alah.
]]

local panel = CreateFrame("Frame")
panel.name = "Shan'do"
local icon = panel:CreateTexture(nil, "ARTWORK")
icon:SetSize(56, 56)
icon:SetPoint("TOPLEFT", 16, -16)
icon:SetTexture("Interface\\AddOns\\Shando\\icon")
local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
title:SetPoint("LEFT", icon, "RIGHT", 12, 6)
title:SetText("Shan'do")
local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
sub:SetText("A night elf spirit guide. Elune-adore.")

local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -12)
scroll:SetPoint("BOTTOMRIGHT", -32, 16)
local body = CreateFrame("Frame", nil, scroll)
body:SetSize(560, 10)
scroll:SetScrollChild(body)
local text = body:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
text:SetPoint("TOPLEFT")
text:SetJustifyH("LEFT")
text:SetSpacing(3)
text:SetText(TEXT)
scroll:SetScript("OnSizeChanged", function(_, w)
    body:SetWidth(w)
    text:SetWidth(w - 8)
    body:SetHeight(text:GetStringHeight() + 16)
end)

local category
if Settings and Settings.RegisterCanvasLayoutCategory then
    category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
end

function ns.ShowReadme()
    if category and Settings.OpenToCategory then
        Settings.OpenToCategory(category:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel)  -- the old client needs it twice
    end
end
