-- AutoQuestRun - Navigate to closest quest marker
local AddonName = "AutoQuestRun"
local AQR = CreateFrame("Frame", "AutoQuestRunFrame")
local updateInterval = 1.0
local timeSinceLastUpdate = 0

-- Configuration
local config = {
    enabled = false,
    showArrow = true,
    showDistance = true,
    autoSetWaypoint = true
}

-- Helper function to calculate distance
local function GetDistance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- Get player's current position
local function GetPlayerMapPosition()
    local mapID = GetCurrentMapZone()
    local x, y = GetPlayerMapPosition("player")
    return x, y, mapID
end

-- Find all quest objectives on the current map
local function GetQuestObjectives()
    local objectives = {}
    local numQuests = GetNumQuestLogEntries()
    
    for questIndex = 1, numQuests do
        local questTitle, level, questTag, isHeader, isCollapsed, isComplete = GetQuestLogTitle(questIndex)
        
        if not isHeader and not isComplete then
            SelectQuestLogEntry(questIndex)
            local numObjectives = GetNumQuestLeaderBoards(questIndex)
            
            for objIndex = 1, numObjectives do
                local text, objType, finished = GetQuestLogLeaderBoard(objIndex, questIndex)
                
                if not finished then
                    -- Try to get quest objective coordinates (if available)
                    local mapID, x, y = GetQuestPOIInfo(questIndex, objIndex)
                    
                    if x and y and x > 0 and y > 0 then
                        table.insert(objectives, {
                            questTitle = questTitle,
                            objectiveText = text,
                            x = x,
                            y = y,
                            mapID = mapID,
                            questIndex = questIndex,
                            objIndex = objIndex
                        })
                    end
                end
            end
        end
    end
    
    return objectives
end

-- Find the closest quest objective
local function GetClosestObjective()
    local px, py, pmapID = GetPlayerMapPosition()
    if not px or not py then return nil end
    
    local objectives = GetQuestObjectives()
    local closestObj = nil
    local closestDistance = math.huge
    
    for _, obj in ipairs(objectives) do
        -- Only check objectives on the same map
        if obj.mapID == pmapID or not obj.mapID then
            local distance = GetDistance(px, py, obj.x, obj.y)
            if distance < closestDistance then
                closestDistance = distance
                closestObj = obj
                closestObj.distance = distance
            end
        end
    end
    
    return closestObj
end

-- Create arrow frame for direction indicator
local arrowFrame = CreateFrame("Frame", "AQRArrowFrame", UIParent)
arrowFrame:SetWidth(56)
arrowFrame:SetHeight(56)
arrowFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
arrowFrame:Hide()

local arrowTexture = arrowFrame:CreateTexture(nil, "OVERLAY")
arrowTexture:SetAllPoints()
arrowTexture:SetTexture("Interface\\AddOns\\AutoQuestRun\\Arrow") -- You'll need to add an arrow texture

local distanceText = arrowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
distanceText:SetPoint("TOP", arrowFrame, "BOTTOM", 0, -5)

-- Update arrow direction
local function UpdateArrow(objective)
    if not config.showArrow or not objective then
        arrowFrame:Hide()
        return
    end
    
    local px, py = GetPlayerMapPosition()
    if not px or not py then
        arrowFrame:Hide()
        return
    end
    
    -- Calculate angle to objective
    local angle = math.atan2(objective.y - py, objective.x - px)
    local playerFacing = GetPlayerFacing()
    
    if playerFacing then
        local relativeAngle = angle - playerFacing
        -- Rotate arrow texture based on relative angle
        -- Note: SetRotation might not be available in 1.12, you may need to use different arrow textures
        arrowFrame:Show()
        
        if config.showDistance then
            local distance = GetDistance(px, py, objective.x, objective.y)
            distanceText:SetText(string.format("%.0f yards", distance * 10000)) -- Rough conversion
        end
    end
end

-- Main update function
local function OnUpdate(self, elapsed)
    timeSinceLastUpdate = timeSinceLastUpdate + elapsed
    
    if timeSinceLastUpdate > updateInterval then
        timeSinceLastUpdate = 0
        
        if config.enabled then
            local closest = GetClosestObjective()
            if closest then
                UpdateArrow(closest)
                
                -- Auto-face target direction (optional)
                if IsMouseButtonDown("RightButton") then
                    local px, py = GetPlayerMapPosition()
                    if px and py then
                        local angle = math.atan2(closest.y - py, closest.x - px)
                        -- TurnOrActionStart() -- Turn character
                        -- Note: Direct character control is limited
                    end
                end
            else
                arrowFrame:Hide()
            end
        else
            arrowFrame:Hide()
        end
    end
end

-- Slash commands
SLASH_AUTOQUEST1 = "/aqr"
SLASH_AUTOQUEST2 = "/autoquest"
SlashCmdList["AUTOQUEST"] = function(msg)
    local command = string.lower(msg)
    
    if command == "on" or command == "enable" then
        config.enabled = true
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00AutoQuestRun enabled|r")
    elseif command == "off" or command == "disable" then
        config.enabled = false
        arrowFrame:Hide()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000AutoQuestRun disabled|r")
    elseif command == "arrow" then
        config.showArrow = not config.showArrow
        DEFAULT_CHAT_FRAME:AddMessage("Arrow display: " .. (config.showArrow and "ON" or "OFF"))
    elseif command == "run" then
        -- Attempt to auto-run to closest objective
        local closest = GetClosestObjective()
        if closest then
            DEFAULT_CHAT_FRAME:AddMessage("Closest quest: " .. closest.questTitle)
            DEFAULT_CHAT_FRAME:AddMessage("Objective: " .. closest.objectiveText)
            DEFAULT_CHAT_FRAME:AddMessage(string.format("Distance: %.0f yards", closest.distance * 10000))
            
            -- Start auto-run
            if not IsAutoRepeatAction(1) then
                ToggleAutoRun()
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("No quest objectives found on current map")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00AutoQuestRun Commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("/aqr on - Enable addon")
        DEFAULT_CHAT_FRAME:AddMessage("/aqr off - Disable addon")
        DEFAULT_CHAT_FRAME:AddMessage("/aqr arrow - Toggle arrow display")
        DEFAULT_CHAT_FRAME:AddMessage("/aqr run - Start auto-run to closest quest")
    end
end

-- Register events
AQR:RegisterEvent("ADDON_LOADED")
AQR:RegisterEvent("PLAYER_ENTERING_WORLD")
AQR:RegisterEvent("QUEST_LOG_UPDATE")

AQR:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == AddonName then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00AutoQuestRun loaded. Type /aqr for commands|r")
    end
end)

AQR:SetScript("OnUpdate", OnUpdate)

-- Create a simple macro for quick access
local function CreateAutoRunMacro()
    local macroName = "AQRun"
    local macroIcon = "INV_Misc_QuestionMark"
    local macroBody = "/aqr run"
    
    CreateMacro(macroName, macroIcon, macroBody, nil)
end
