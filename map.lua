local addonName = ...
RXP_.mapId = {
["Durotar"] = 1411,
["Mulgore"] = 1412,
["The Barrens"] = 1413,
["Alterac Mountains"] = 1416,
["Arathi Highlands"] = 1417,
["Badlands"] = 1418,
["Blasted Lands"] = 1419,
["Tirisfal Glades"] = 1420,
["Silverpine Forest"] = 1421,
["Western Plaguelands"] = 1422,
["Eastern Plaguelands"] = 1423,
["Hillsbrad Foothills"] = 1424,
["The Hinterlands"] = 1425,
["Dun Morogh"] = 1426,
["Searing Gorge"] = 1427,
["Burning Steppes"] = 1428,
["Elwynn Forest"] = 1429,
["Deadwind Pass"] = 1430,
["Duskwood"] = 1431,
["Loch Modan"] = 1432,
["Redridge Mountains"] = 1433,
["Stranglethorn Vale"] = 1434,
["Swamp of Sorrows"] = 1435,
["Westfall"] = 1436,
["Wetlands"] = 1437,
["Teldrassil"] = 1438,
["Darkshore"] = 1439,
["Ashenvale"] = 1440,
["Thousand Needles"] = 1441,
["Stonetalon Mountains"] = 1442,
["Desolace"] = 1443,
["Feralas"] = 1444,
["Dustwallow Marsh"] = 1445,
["Tanaris"] = 1446,
["Azshara"] = 1447,
["Felwood"] = 1448,
["Un'Goro Crater"] = 1449,
["Moonglade"] = 1450,
["Silithus"] = 1451,
["Winterspring"] = 1452,
["Stormwind City"] = 1453,
["Orgrimmar"] = 1454,
["Ironforge"] = 1455,
["Thunder Bluff"] = 1456,
["Darnassus"] = 1457,
["Undercity"] = 1458,
["Alterac Valley"] = 1459,
["Eversong Woods"] = 1941,
["Ghostlands"] = 1942,
["Azuremyst Isle"] = 1943,
["Hellfire Peninsula"] = 1944,
["Zangarmarsh"] = 1946,
["The Exodar"] = 1947,
["Shadowmoon Valley"] = 1948,
["Blade's Edge Mountains"] = 1949,
["Bloodmyst Isle"] = 1950,
["Nagrand"] = 1951,
["Terokkar Forest"] = 1952,
["Netherstorm"] = 1953,
["Silvermoon City"] = 1954,
["Shattrath City"] = 1955,
["Isle of Quel'Danas"] = 1957,
["Kalimdor"] = 1414,
["Eastern Kingdoms"] = 1415,
["Outland"] = 987,
}

local HBD = LibStub("HereBeDragons-2.0")
local HBDPins = LibStub("HereBeDragons-Pins-2.0")
RXP_.activeWaypoints = {}
RXP_.mapPins = {}
local colors = RXP_.colors

RXP_.arrowFrame = CreateFrame("Frame","RXPG_ARROW",UIParent)
local af = RXP_.arrowFrame
af:SetMovable(true)
af:EnableMouse(1)
af:SetClampedToScreen(true)
af:SetSize(32,32)
af.texture = af:CreateTexture()
af.texture:SetAllPoints()
af.texture:SetTexture("Interface/AddOns/RXPGuides/Textures/rxp_navigation_arrow-1")
--af.texture:SetScale(0.5)
af.text = af:CreateFontString(nil,"OVERLAY")
af.text:SetTextColor(1,1,1,1)
af.text:SetFont(RXP_.font, 9)--,"OUTLINE")
af.text:SetJustifyH("CENTER")
af.text:SetJustifyV("CENTER")
af.text:SetPoint("TOP",af,"BOTTOM",0,-5)
af.orientation = 0
af.distance = 0
af.lowerbound = math.pi/32 --angle in radians
af.upperbound = 2*math.pi-af.lowerbound

af:SetPoint("TOP")
af:Hide()

af:SetScript("OnMouseDown", function(self, button)
    if not RXPData.lockFrames then
        af:StartMoving()
    end
end)
af:SetScript("OnMouseUp", function(self,button)
    af:StopMovingOrSizing()
end)

function RXP_.UpdateArrow(self)

if RXPData.disableArrow or not self then
    return
end


if self.element then
    local x,y,instance = HBD:GetPlayerWorldPosition()
    local angle,dist = HBD:GetWorldVector(instance, x, y, self.element.wx,self.element.wy)
    local facing = GetPlayerFacing()
    if not (dist and facing) then return end
    local orientation = angle-facing
    local diff = math.abs(orientation-self.orientation)
    dist = math.floor(dist)

    if diff > self.lowerbound and diff < self.upperbound then
        self.orientation = orientation
        self.texture:SetRotation(orientation) 
    end

    if dist ~= self.distance then
        self.distance = dist
        self.text:SetText(string.format("Step %d\n(%dyd)",self.element.step.index,dist))
    end
end


end


RXP_.arrowFrame:SetScript("OnUpdate",RXP_.UpdateArrow)

function RXP_.UpdateGotoSteps()
    if #RXP_.activeWaypoints == 0 then
        af:Hide()
        return
    end
    for i,element in ipairs(RXP_.activeWaypoints) do
        if element.step.active then

            if element.radius and element.arrow and not(element.parent and (element.parent.completed or element.parent.skip) and not element.parent.textOnly) and not element.skip then
                local x,y,instance = HBD:GetPlayerWorldPosition()
                local angle,dist = HBD:GetWorldVector(instance, x, y, element.wx,element.wy)
                if not dist then return end
                if dist <= element.radius then
                    element.skip = true
                    RXP_.updateMap = true
                    RXP_.SetElementComplete(element.frame)
                end
            end
        end
    end
end




local function TooltipHandler(self)
    if not tooltip then
        tooltip = true
    end
    local text
    if self.element.parent then
        text =  self.element.parent.tooltipText
    else
        text = self.element.tooltipText
    end
    text = text or RXP_.MainFrame.Steps.frame[self.step.index].text:GetText()
    if text then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT",0,0)
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Step "..self.step.index,unpack(colors.mapPins))
        GameTooltip:AddLine(text)
        for i,element in pairs(self.connectedPins) do
            local text
            if element.parent then
                text =  element.parent.tooltipText
            elseif not element.hideTooltip then
                text = element.tooltipText
            end
            text = text or RXP_.MainFrame.Steps.frame[element.step.index].text:GetText()
            GameTooltip:AddLine("Step "..element.step.index,unpack(colors.mapPins))
            GameTooltip:AddLine(text)
        end
        GameTooltip:Show()
    end
end



function CreateWPframe(id,step,element)

    RXP_.mapPins[id] = RXP_.mapPins[id] or CreateFrame("Button", "RXP_MAP_"..tostring(#RXP_.mapPins+1),nil,BackdropTemplateMixin and "BackdropTemplate")
    local f = RXP_.mapPins[id]
    f.element = element
    f.step = step
    f.connectedPins = {}

    --f.text:SetTextColor(0.9,0.1,0.1,1)
    if not f.text then
        f:SetWidth(16)
        f:SetHeight(16)

        --f.text:SetFontObject(GameFontNormal)
         f:SetBackdrop({
            bgFile = "Interface\\Addons\\" .. addonName .. "\\Textures\\white_circle",
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        f:SetBackdropColor(0.0, 0.0, 0.0, RXPData.worldMapPinBackgroundOpacity)
        --f:SetBackdrop(backdrop)
        f.text = f.text or f:CreateFontString(nil,"OVERLAY") 
        f.text:SetTextColor(unpack(colors.mapPins))
        f.text:SetFont(RXP_.font, 14,"OUTLINE")
        f.text:SetJustifyH("LEFT")
        f.text:SetJustifyV("CENTER")

        f:SetScript("OnEnter",TooltipHandler)
        f:SetScript("OnLeave",function(self)
            GameTooltip:Hide()
        end)
        f:SetMouseClickEnabled(false)

        f:Hide()
    end

    --f:ClearAllPoints()

-->>>>
  return f
end













--[[
    f.text:SetText(text)
    local x = tonumber(x) / 100 * WorldMapButton:GetWidth()
    local y = tonumber(y) / 100 * WorldMapButton:GetHeight()
    local t = text
    f.map = map
    f:SetPoint("CENTER", WorldMapButton, "TOPLEFT", f.x, -f.y)
]]
--wp = CreateWPframe()

local function AddMapIcon(...)
    if RXPData.numMapPins == 0 then
        return
    else
        return HBDPins:AddWorldMapIconWorld(...)
    end
end
local function AddMinimapIcon(...)
    if RXPData.numMapPins == 0 then
        return
    else
        return HBDPins:AddMinimapIconWorld(...)
    end
end

--local L = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"


--local W = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}

function RXP_.UpdateMap()

    RXP_.updateMap = false
    if not RXP_.currentGuide then return end
    af.element = nil
    RXP_.activeWaypoints = {}
    HBDPins:RemoveAllMinimapIcons(RXP_)
    HBDPins:RemoveAllWorldMapIcons(RXP_)
    local guide = RXP_.currentGuide
    local n = 0

    local function GeneratePins(step,miniMapPin)
        local subitem = 0
        for j,element in ipairs(step.elements) do
            if element.text and not element.label and not element.textOnly then
                element.label = tostring(step.index)
            end
            if element.zone and (not(element.parent and (element.parent.completed or element.parent.skip)) and not element.skip) then
                n = n +1
                element.mapPin = CreateWPframe(n,step,element)
                element.mapPin:SetBackdropColor(0.0, 0.0, 0.0, RXPData.worldMapPinBackgroundOpacity)
                table.insert(RXP_.activeWaypoints,element)
                if not element.optional then
                    local icon
                    if element.parent then
                        icon = element.parent.icon or RXP_.icons[element.parent.tag]
                    end
                    icon = icon or ""
                    local label
                    if element.parent then
                        label = element.parent.label or tostring(step.index)
                    elseif element.label then
                        label = element.label or tostring(step.index)
                    else
                        label = tostring(step.index)
                        element.label = label
                    end
                    local framelevel
                    element.mapPin:SetAlpha(1)
                    if step.active then
                        framelevel = "PIN_FRAME_LEVEL_SUPER_TRACKED_QUEST"
                    else
                        framelevel = "PIN_FRAME_LEVEL_ACTIVE_QUEST"
                        --element.mapPin:SetAlpha(0.8)
                    end
                    if step.active and icon == "" then
                        element.mapPin.text:SetFont(RXP_.font, 14,"OUTLINE")
                    else
                        element.mapPin.text:SetFont(RXP_.font, 9,"OUTLINE")
                    end
                    element.mapPin.text:SetText(label..icon)
                    AddMapIcon(RXP_, RXP_.mapPins[n], element.instance, element.wx, element.wy, HBD_PINS_WORLDMAP_SHOW_CONTINENT, framelevel)
                    element.mapPin.text:SetPoint("CENTER",0,0)
                    element.mapPin:SetWidth(element.mapPin.text:GetStringWidth()+3)
                    element.mapPin:SetHeight(element.mapPin.text:GetStringHeight()+3)
                    element.mapPin:Show()
                    if miniMapPin and step.active then
                        n = n +1
                        element.miniMapPin = CreateWPframe(n,step,element)
                        element.miniMapPin:SetAlpha(0.8)
                        local miniMapIcon = icon
                        if icon == "" then
                            miniMapIcon = label
                        end
                        element.miniMapPin.text:SetText(miniMapIcon)
                        AddMinimapIcon(RXP_, RXP_.mapPins[n], element.instance, element.wx, element.wy, true,true)
                        element.miniMapPin.text:SetPoint("LEFT",1,0)
                        element.miniMapPin:Show()
                    end
                end
                --print(n,element.zone,element.x,element.y)
                --
            end
        end
    end

    for i,step in ipairs(RXP_.MainFrame.CurrentStepFrame.activeSteps) do
        GeneratePins(step,true)
    end

    --local stepn = RXPCData.currentStep
    local npins = 0
    for stepn = RXPCData.currentStep+1, RXPCData.currentStep+RXPData.numMapPins do
        if stepn > #RXP_.currentGuide.steps then
            break
        end
        local step = RXP_.currentGuide.steps[stepn]
        local nelements = 0
        local ncompleted = 0
        for i,element in ipairs(step.elements) do
            nelements = nelements + 1
            if element.tag then
                element.element = element
                RXP_.functions[element.tag](element)
            end
            if (element.completed or element.skip) or element.textOnly or not element.text then
                ncompleted = ncompleted + 1
            end 
        end
        if nelements == ncompleted and nelements > 0 then
            step.completed = true
        else
            step.completed = nil
            npins = npins + 1
        end
    end

    for i = RXPCData.currentStep+1,RXPCData.currentStep+RXPData.numMapPins do
        if i > #RXP_.currentGuide.steps then
            break
        end
        local step = RXP_.currentGuide.steps[i]
        GeneratePins(step)
    end

    for i,current in ipairs(RXP_.activeWaypoints) do
        for j = 1,i-1 do
            local element = RXP_.activeWaypoints[j]
            if i <= j then break end
            if not element.optional then
                local dist,dx,dy
                local zx, zy = HBD:GetZoneSize(current.zone)
                if current.instance == element.instance then
                    dist,dx,dy = HBD:GetWorldDistance(current.instance, current.wx, current.wy, element.wx, element.wy)
                end
                --print(dist)
                local relativeDist
                if dx and zx then
                    relativeDist = (dx/zx)^2 + (dy/zy)^2
                end

                if (relativeDist and relativeDist < 0.00001) or (dist and dist < 60) then
                    
                    if not element.parent then
                        element.mapPin.text:SetText(element.label.."+")
                        element.mapPin:SetWidth(element.mapPin.text:GetStringWidth()+3)
                        element.mapPin:SetHeight(element.mapPin.text:GetStringHeight()+3)
                        current.mapPin:Hide()
                    else
                        current.mapPin:Show()
                    end
                        current.mapPin:SetAlpha(0.33)
                        current.mapPin:SetBackdropColor(0.0, 0.0, 0.0, 0.0)
                    table.insert(element.mapPin.connectedPins,current)
                    table.insert(current.mapPin.connectedPins,element)
                end
            end
        end
    end

    for i,element in ipairs(RXP_.activeWaypoints) do
        if element.arrow and element.step.active and 
        not(element.parent and (element.parent.completed or element.parent.skip)) and not(element.text and (element.completed or element.skip) and not element.skip) then
            af:SetShown(not RXPData.disableArrow)
            af.dist = 0
            af.orientation = 0
            af.element = element
            return
        end
    end
    af:Hide()
end