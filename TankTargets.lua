-- 1. Initialisation des Variables Sauvegardées
TankList = TankList or {}
TankCount = TankCount or 1
TankTargetsLocked = TankTargetsLocked or false
TankScale = TankScale or 1.0
TankFramePos = TankFramePos or { x = 0, y = 105 }
TankOrientation = TankOrientation or "VERTICAL"
TankOptionsPos = TankOptionsPos or nil

local frames = {}
local timer = 0

local RAID_CLASS_COLORS = {
    ["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43 },
    ["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73 },
    ["ROGUE"]   = { r = 1.00, g = 0.96, b = 0.41 },
    ["MAGE"]    = { r = 0.41, g = 0.80, b = 0.94 },
    ["WARLOCK"] = { r = 0.58, g = 0.51, b = 0.79 },
    ["DRUID"]   = { r = 1.00, g = 0.49, b = 0.04 },
    ["HUNTER"]  = { r = 0.67, g = 0.83, b = 0.45 },
    ["SHAMAN"]  = { r = 0.00, g = 0.44, b = 0.87 },
    ["PRIEST"]  = { r = 1.00, g = 1.00, b = 1.00 },
}

local function Abbrev(name)
    if not name then return "" end
    if string.len(name) > 12 then return string.sub(name, 1, 10)..".." end
    return name
end

function TankTargets_Target(id)
    local targetName = nil
    for name, slot in pairs(TankList) do if slot == id then targetName = name end end
    if targetName then 
        TargetByName(targetName) 
        if UnitExists("target") then TargetUnit("targettarget") end 
    end
end

-- 2. Menu de Sélection des Tanks
local menu = CreateFrame("Frame", "TankMenu", UIParent)
menu:SetWidth(120)
menu:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 1})
menu:SetBackdropColor(0, 0, 0, 0.9) menu:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
menu:Hide()
menu:EnableMouse(true)

local currentSlot = 1
local function FillMenu(slotID)
    currentSlot = slotID
    local players = {}
    local pCount = 1
    players[pCount] = "Vider"
    if GetNumRaidMembers() > 0 then
        for i=1, GetNumRaidMembers() do pCount = pCount + 1; players[pCount] = UnitName("raid"..i) end
    else
        pCount = pCount + 1; players[pCount] = UnitName("player")
        for i=1, GetNumPartyMembers() do pCount = pCount + 1; players[pCount] = UnitName("party"..i) end
    end
    local j = 1
    while getglobal("TankMenuBtn"..j) do getglobal("TankMenuBtn"..j):Hide(); j = j + 1 end
    for i=1, pCount do
        local pName = players[i]
        local b = getglobal("TankMenuBtn"..i) or CreateFrame("Button", "TankMenuBtn"..i, menu)
        b:SetWidth(110) b:SetHeight(16) b:SetPoint("TOPLEFT", 5, -5 - ((i-1)*18))
        
        local bt = b:GetFontString()
        if not bt then
            bt = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            b:SetFontString(bt)
        end
        b:SetText(pName)
        b:Show()
        
        b:SetScript("OnClick", function()
            local n = this:GetText()
            for name, slot in pairs(TankList) do if slot == currentSlot then TankList[name] = nil end end
            if n ~= "Vider" and n ~= nil then TankList[n] = currentSlot end
            menu:Hide()
            -- SYNCHRO SUPPRIMÉE ICI
        end)
    end
    menu:SetHeight(pCount * 18 + 10)
end

-- 3. Création des Frames Principales
for i=1, 4 do
    local f = CreateFrame("Frame", "TankFrame"..i, UIParent)
    f:SetWidth(144) f:SetHeight(44)
    f:SetMovable(true) f:EnableMouse(true) f:RegisterForDrag("LeftButton")
    f:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 1})
    f:SetBackdropColor(0, 0, 0, 0.6) f:SetBackdropBorderColor(0, 0, 0, 1)
    f:SetScale(TankScale)
    
    if i == 1 then 
        f:SetPoint("TOPLEFT", UIParent, "CENTER", TankFramePos.x, TankFramePos.y)
    else 
        if TankOrientation == "VERTICAL" then f:SetPoint("TOPLEFT", frames[i-1], "BOTTOMLEFT", 0, -6)
        else f:SetPoint("TOPLEFT", frames[i-1], "TOPRIGHT", 6, 0) end
    end

    f:SetScript("OnDragStart", function() 
        if not TankTargetsLocked then 
            TankFrame1:StartMoving() 
            TankOptionsFrame:Hide() 
        end 
    end)
    f:SetScript("OnDragStop", function() 
        TankFrame1:StopMovingOrSizing()
        local _, _, _, x, y = TankFrame1:GetPoint()
        TankFramePos.x, TankFramePos.y = x, y
    end)

    f.btnS = CreateFrame("Button", nil, f)
    f.btnS:SetWidth(16) f.btnS:SetHeight(16) f.btnS:SetPoint("TOPLEFT", 5, -5)
    local tS = f.btnS:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tS:SetAllPoints() tS:SetText("|cff00ccffS|r")
    local slotID = i
    f.btnS:SetScript("OnClick", function() FillMenu(slotID); menu:ClearAllPoints(); menu:SetPoint("LEFT", f, "RIGHT", 5, 0); menu:Show() end)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.title:SetPoint("TOP", f, "TOP", 0, -7)

    if i == 1 then
        f.btnNb = CreateFrame("Button", nil, f)
        f.btnNb:SetWidth(16) f.btnNb:SetHeight(16) f.btnNb:SetPoint("LEFT", f.btnS, "RIGHT", 2, 0)
        f.nbDisplay = f.btnNb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        f.nbDisplay:SetAllPoints()
        f.btnNb:SetScript("OnClick", function() 
            TankCount = (TankCount >= 4) and 1 or TankCount + 1 
            -- SYNCHRO SUPPRIMÉE ICI
        end)
        
        f.btnLock = CreateFrame("Button", nil, f)
        f.btnLock:SetWidth(16) f.btnLock:SetHeight(16) f.btnLock:SetPoint("TOPRIGHT", -5, -5)
        f.lockTxt = f.btnLock:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        f.lockTxt:SetAllPoints()
        f.lockTxt:SetText(TankTargetsLocked and "|cff00ff00L|r" or "|cffff0000U|r")
        f.btnLock:SetScript("OnClick", function() 
            TankTargetsLocked = not TankTargetsLocked 
            f.lockTxt:SetText(TankTargetsLocked and "|cff00ff00L|r" or "|cffff0000U|r")
        end)

        f.btnOpt = CreateFrame("Button", nil, f)
        f.btnOpt:SetWidth(18) f.btnOpt:SetHeight(16) f.btnOpt:SetPoint("RIGHT", f.btnLock, "LEFT", -2, 0)
        local tOpt = f.btnOpt:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        tOpt:SetAllPoints() tOpt:SetText("|cffffff00O|r")
        
        f.btnOpt:SetScript("OnClick", function() 
            if TankOptionsFrame:IsShown() then 
                TankOptionsFrame:Hide() 
            else 
                if not TankOptionsPos then
                    TankOptionsFrame:ClearAllPoints()
                    local scaledWidth = 144 * TankScale
                    TankOptionsFrame:SetPoint("BOTTOM", UIParent, "CENTER", TankFramePos.x + (scaledWidth / 2), TankFramePos.y + 5)
                end
                TankOptionsFrame:Show() 
            end 
        end)
    end

    f.hp = CreateFrame("StatusBar", nil, f)
    f.hp:SetWidth(134) f.hp:SetHeight(14) f.hp:SetPoint("BOTTOM", 0, 5)
    f.hp:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    f.tText = f.hp:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.tText:SetPoint("CENTER", 0, 0)

    f.mana = CreateFrame("StatusBar", nil, f)
    f.mana:SetWidth(134) f.mana:SetHeight(3) f.mana:SetPoint("BOTTOM", f.hp, "TOP", 0, 2)
    f.mana:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

    f.icon = f.hp:CreateTexture(nil, "OVERLAY")
    f.icon:SetWidth(14) f.icon:SetHeight(14) f.icon:SetPoint("RIGHT", f.tText, "LEFT", -2, 0)
    f.icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    f.icon:Hide()

    f:SetScript("OnMouseDown", function() TankTargets_Target(slotID) end)
    frames[i] = f
end

-- 4. Cadre d'Options
local opt = CreateFrame("Frame", "TankOptionsFrame", UIParent)
opt:SetWidth(150) opt:SetHeight(90)
opt:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 1})
opt:SetBackdropColor(0, 0, 0, 0.9) opt:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

opt:SetMovable(true)
opt:EnableMouse(true)
opt:RegisterForDrag("LeftButton")
opt:SetScript("OnDragStart", function() this:StartMoving() end)
opt:SetScript("OnDragStop", function() 
    this:StopMovingOrSizing() 
    local point, _, relativePoint, x, y = this:GetPoint()
    TankOptionsPos = { p = point, rp = relativePoint, x = x, y = y }
end)

if TankOptionsPos then
    opt:SetPoint(TankOptionsPos.p, UIParent, TankOptionsPos.rp, TankOptionsPos.x, TankOptionsPos.y)
end

opt:Hide()

local ot = opt:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ot:SetPoint("TOP", 0, -6) ot:SetText("Configuration")

-- Le Slider
local sSize = CreateFrame("Slider", "TankScaleSlider", opt, "OptionsSliderTemplate")
sSize:SetWidth(120) 
sSize:SetHeight(16)
sSize:SetPoint("TOP", opt, "TOP", 0, -30)
sSize:SetMinMaxValues(0.5, 2.0)
sSize:SetValueStep(0.1)
sSize:SetValue(TankScale)

getglobal(sSize:GetName() .. "Low"):SetText("0.5")
getglobal(sSize:GetName() .. "High"):SetText("2.0")
getglobal(sSize:GetName() .. "Text"):SetText("Taille: "..string.format("%.1f", TankScale))

sSize:SetScript("OnValueChanged", function()
    local val = math.floor(this:GetValue() * 10 + 0.5) / 10
    TankScale = val
    getglobal(this:GetName() .. "Text"):SetText("Taille: "..string.format("%.1f", TankScale))
    for k=1, 4 do 
        frames[k]:SetScale(TankScale) 
    end
end)

local function CreateDarkButton(name, parent, width, height, anchorPoint, anchorTo, anchorPoint2, x, y)
    local btn = CreateFrame("Button", name, parent)
    btn:SetWidth(width) btn:SetHeight(height) btn:SetPoint(anchorPoint, anchorTo, anchorPoint2, x, y)
    btn:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 1})
    btn:SetBackdropColor(0.2, 0.2, 0.2, 0.9) btn:SetBackdropBorderColor(0, 0, 0, 1)
    
    btn:SetScript("OnEnter", function() this:SetBackdropColor(0.4, 0.4, 0.4, 0.9) end)
    btn:SetScript("OnLeave", function() this:SetBackdropColor(0.2, 0.2, 0.2, 0.9) end)
    
    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn:SetFontString(txt)
    
    return btn
end

local bOrient = CreateDarkButton(nil, opt, 130, 20, "TOP", sSize, "BOTTOM", 0, -10)
local function UpdateOrientText()
    bOrient:SetText("Sens: "..TankOrientation)
end
UpdateOrientText()

bOrient:SetScript("OnClick", function()
    TankOrientation = (TankOrientation == "VERTICAL") and "HORIZONTAL" or "VERTICAL"
    UpdateOrientText()
    for i=2, 4 do
        frames[i]:ClearAllPoints()
        if TankOrientation == "VERTICAL" then frames[i]:SetPoint("TOPLEFT", frames[i-1], "BOTTOMLEFT", 0, -6)
        else frames[i]:SetPoint("TOPLEFT", frames[i-1], "TOPRIGHT", 6, 0) end
    end
end)

-- 5. Boucle de Mise à Jour
local updater = CreateFrame("Frame")
updater:SetScript("OnUpdate", function()
    timer = timer + arg1
    if timer > 0.15 then
        local numRaid = GetNumRaidMembers()
        local numParty = GetNumPartyMembers()
        
        if frames[1].nbDisplay then frames[1].nbDisplay:SetText(TankCount) end
        
        for i=1, 4 do
            local f = frames[i]
            if (numRaid > 0 or numParty > 0 or TankTestMode) and i <= TankCount then
                f:Show()
                f.btnS:Show()
                if i == 1 then f.btnNb:Show() end

                local name = nil
                for n, s in pairs(TankList) do if s == i then name = n end end
                
                if name then
                    local u = nil
                    if name == UnitName("player") then u = "player"
                    elseif numRaid > 0 then
                        for r=1, numRaid do if UnitName("raid"..r) == name then u = "raid"..r break end end
                    else
                        for p=1, numParty do if UnitName("party"..p) == name then u = "party"..p break end end
                    end
                    
                    if u and UnitExists(u) then
                        if CheckInteractDistance(u, 4) then f:SetAlpha(1.0) else f:SetAlpha(0.5) end
                        local _, cl = UnitClass(u); local c = RAID_CLASS_COLORS[cl] or {r=1, g=1, b=1}
                        local p = math.floor((UnitHealth(u)/UnitHealthMax(u))*100)
                        f.title:SetTextColor(c.r, c.g, c.b); f.title:SetText(name.." "..p.."%")
                        
                        local pType = UnitPowerType(u)
                        if pType == 0 then f.mana:SetStatusBarColor(0, 0, 1) elseif pType == 1 then f.mana:SetStatusBarColor(1, 0, 0) else f.mana:SetStatusBarColor(1, 1, 0) end
                        f.mana:SetMinMaxValues(0, UnitManaMax(u)); f.mana:SetValue(UnitMana(u))
                        
                        local tid = u.."target"
                        if UnitExists(tid) then
                            local h, m = UnitHealth(tid), UnitHealthMax(tid)
                            f.hp:SetMinMaxValues(0, m); f.hp:SetValue(h)
                            f.tText:SetText(Abbrev(UnitName(tid)).." "..math.floor((h/m)*100).."%")
                            f.hp:SetStatusBarColor(1-(h/m), h/m, 0)
                            
                            local tot = tid.."target"
                            if UnitExists(tot) and not UnitIsUnit(tot, u) then f:SetBackdropBorderColor(1,0,0,1) else f:SetBackdropBorderColor(0,0,0,1) end
                            
                            local idx = GetRaidTargetIndex(tid)
                            if idx then SetRaidTargetIconTexture(f.icon, idx); f.icon:Show() else f.icon:Hide() end
                        else 
                            f.hp:SetValue(0); f.tText:SetText("Aucun"); f.icon:Hide(); f:SetBackdropBorderColor(0,0,0,1) 
                        end
                    else 
                        f:SetAlpha(0.5)
                        f.title:SetText(name.." (OFF)"); f.hp:SetValue(0); f.tText:SetText("-") 
                    end
                else 
                    f:SetAlpha(1.0)
                    f.title:SetText("Vide"); f.hp:SetValue(0); f.tText:SetText("-"); f:SetBackdropBorderColor(0,0,0,1)
                end
            else
                f:Hide()
            end
        end
        timer = 0
    end
end)

-- 6. Events simplifiés (plus d'écoute de synchro)
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")

eventFrame:SetScript("OnEvent", function()
    -- On vide les cibles uniquement si on quitte le groupe/raid
    if (event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE") and GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        TankList = {}
    end
end)

-- 7. Commandes Slash
SLASH_TANKTARGETS1 = "/tt"
SlashCmdList["TANKTARGETS"] = function(msg)
    if msg == "test" then
        TankTestMode = not TankTestMode
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[TankTarget]|r Mode Test : "..(TankTestMode and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    elseif msg == "reset" then
        TankFrame1:ClearAllPoints()
        TankFrame1:SetPoint("TOPLEFT", UIParent, "CENTER", 0, 0)
        TankFramePos = { x = 0, y = 0 }
        
        TankOptionsPos = nil
        TankOptionsFrame:Hide()
        
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[TankTarget]|r Positions réinitialisées.")
    else
        DEFAULT_CHAT_FRAME:AddMessage("/tt test | /tt reset")
    end
end

-- Raccourcis
BINDING_HEADER_TANKTARGETS = "TankTargets"
BINDING_NAME_TANKTARGET1 = "Assister Tank 1"
BINDING_NAME_TANKTARGET2 = "Assister Tank 2"
BINDING_NAME_TANKTARGET3 = "Assister Tank 3"
BINDING_NAME_TANKTARGET4 = "Assister Tank 4"