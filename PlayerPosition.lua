-- Create the main frame
local PlayerPositionFrame = CreateFrame("Frame", "PlayerPositionFrame", UIParent)
PlayerPositionFrame:SetWidth(200)
PlayerPositionFrame:SetHeight(80)
PlayerPositionFrame:SetPoint("TOP", UIParent, "TOP", 0, -20)
PlayerPositionFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 16,
    insets = { left = 5, right = 5, top = 5, bottom = 5 }
})
PlayerPositionFrame:SetBackdropColor(0, 0, 0, 0.7)
PlayerPositionFrame:EnableMouse(true)
PlayerPositionFrame:SetMovable(true)
PlayerPositionFrame:RegisterForDrag("LeftButton")
PlayerPositionFrame:SetScript("OnDragStart", function()
    this:StartMoving()
end)
PlayerPositionFrame:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
end)

-- Create title text
local titleText = PlayerPositionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
titleText:SetPoint("TOP", PlayerPositionFrame, "TOP", 0, -8)
titleText:SetText("Player Position")
titleText:SetTextColor(1, 1, 0)

-- Create zone text
local zoneText = PlayerPositionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
zoneText:SetPoint("TOP", titleText, "BOTTOM", 0, -5)
zoneText:SetTextColor(1, 1, 1)

-- Create coordinate text
local coordText = PlayerPositionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
coordText:SetPoint("TOP", zoneText, "BOTTOM", 0, -5)
coordText:SetTextColor(0, 1, 0)

-- Create subzone text
local subzoneText = PlayerPositionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
subzoneText:SetPoint("TOP", coordText, "BOTTOM", 0, -5)
subzoneText:SetTextColor(0.7, 0.7, 0.7)

-- Update function
local function UpdatePosition()
    -- Get player map position
    SetMapToCurrentZone()
    local x, y = GetPlayerMapPosition("player")
    
    -- Convert to percentage format
    local xPercent = x * 100
    local yPercent = y * 100
    
    -- Get zone information
    local zone = GetZoneText()
    local subzone = GetSubZoneText()
    local realZone = GetRealZoneText()
    
    -- Update display
    if zone and zone ~= "" then
        zoneText:SetText(zone)
    else
        zoneText:SetText(realZone or "Unknown")
    end
    
    if x == 0 and y == 0 then
        coordText:SetText("Position: Unavailable")
    else
        coordText:SetText(string.format("Coords: %.1f, %.1f", xPercent, yPercent))
    end
    
    if subzone and subzone ~= "" then
        subzoneText:SetText("(" .. subzone .. ")")
        subzoneText:Show()
    else
        subzoneText:Hide()
    end
end

-- Create update timer
local updateTimer = 0
local UPDATE_INTERVAL = 0.1 -- Update every 0.1 seconds

PlayerPositionFrame:SetScript("OnUpdate", function()
    updateTimer = updateTimer + arg1 -- arg1 is elapsed time in vanilla
    if updateTimer >= UPDATE_INTERVAL then
        UpdatePosition()
        updateTimer = 0
    end
end)

-- Register events
PlayerPositionFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
PlayerPositionFrame:RegisterEvent("ZONE_CHANGED")
PlayerPositionFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
PlayerPositionFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

PlayerPositionFrame:SetScript("OnEvent", function()
    UpdatePosition()
end)

-- Slash commands
SLASH_PLAYERPOS1 = "/playerpos"
SLASH_PLAYERPOS2 = "/ppos"
SlashCmdList["PLAYERPOS"] = function(msg)
    if PlayerPositionFrame:IsShown() then
        PlayerPositionFrame:Hide()
        DEFAULT_CHAT_FRAME:AddMessage("Player Position: Hidden")
    else
        PlayerPositionFrame:Show()
        DEFAULT_CHAT_FRAME:AddMessage("Player Position: Shown")
    end
end

-- Initial update
UpdatePosition()

-- Optional: Add minimap coordinates
local MinimapCoords = CreateFrame("Frame", "MinimapCoords", Minimap)
MinimapCoords:SetWidth(50)
MinimapCoords:SetHeight(15)
MinimapCoords:SetPoint("TOP", Minimap, "BOTTOM", 0, -5)

local MinimapCoordsText = MinimapCoords:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
MinimapCoordsText:SetPoint("CENTER", MinimapCoords, "CENTER", 0, 0)
MinimapCoordsText:SetTextColor(1, 1, 0)

-- Update minimap coordinates
local minimapTimer = 0
MinimapCoords:SetScript("OnUpdate", function()
    minimapTimer = minimapTimer + arg1
    if minimapTimer >= UPDATE_INTERVAL then
        local x, y = GetPlayerMapPosition("player")
        if x ~= 0 or y ~= 0 then
            MinimapCoordsText:SetText(string.format("%.0f, %.0f", x * 100, y * 100))
        else
            MinimapCoordsText:SetText("")
        end
        minimapTimer = 0
    end
end)

DEFAULT_CHAT_FRAME:AddMessage("Player Position Addon Loaded - Type /playerpos to toggle display")