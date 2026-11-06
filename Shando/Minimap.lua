-- A small button on the edge of the minimap, at half opacity (full when you point at it).
-- Left-click: the readme. Right-click: rest her or call her back. Drag: move it round the edge (kept per character).
local _, ns = ...
local NAME, COLOUR, ICON = "Shan'do", "|cffb8c8ff", "Interface\\AddOns\\Shando\\icon"
local REST = 0.5

local b = CreateFrame("Button", "ShandoMinimapButton", Minimap)
b:SetSize(24, 24)
b:SetFrameStrata("MEDIUM")
b:SetFrameLevel(Minimap:GetFrameLevel() + 8)
b:SetAlpha(REST)
b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
b:RegisterForDrag("LeftButton")
local tex = b:CreateTexture(nil, "ARTWORK")
tex:SetAllPoints()
tex:SetTexture(ICON)

local function Place(angle)
    local r = Minimap:GetWidth() / 2 + 6
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", r * math.cos(math.rad(angle)), r * math.sin(math.rad(angle)))
end

local function Dim() tex:SetDesaturated(ShandoOff and true or false) end

b:SetScript("OnEnter", function(self)
    self:SetAlpha(1)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine(COLOUR .. NAME .. "|r" .. (ShandoOff and "  (resting)" or ""))
    GameTooltip:AddLine("Left-click: about her", 1, 1, 1)
    GameTooltip:AddLine("Right-click: rest her, or call her back", 1, 1, 1)
    GameTooltip:AddLine("Drag: move this button", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)
b:SetScript("OnLeave", function(self) self:SetAlpha(REST) GameTooltip:Hide() end)
b:SetScript("OnClick", function(_, button)
    if button == "RightButton" then SlashCmdList.SHANDO("") else ns.ShowReadme() end
    Dim()
end)
b:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local s = Minimap:GetEffectiveScale()
        ShandoMap = math.deg(math.atan2(cy / s - my, cx / s - mx))
        Place(ShandoMap)
    end)
end)
b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

b:RegisterEvent("PLAYER_LOGIN")
b:SetScript("OnEvent", function() Place(ShandoMap or 200) Dim() end)
