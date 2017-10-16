local AllOptions = {
    124117, -- 1 Lean Shank
    124121, -- 2 Wildfowl Egg
    124119, -- 3 Big Gamy Ribs
    124118, -- 4 Fatty Bearsteak
    124120, -- 5 Leyblood
    124107, -- 6 Cursed Queenfish
    124108, -- 7 Mossgill Perch
    124109, -- 8 Highmountain Salmon
    124110, -- 9 Stormray
    124111, -- 10 Runescale Koi
    124112, -- 11 Black Barracuda
    133680, -- 12 Slabs of Bacon
    133607, -- 13 Silver Mackerel
}
local previousSuccess = 0

SLASH_RELOADUI1 = "/rl"
SLASH_RELOADUI2 = "/reloadui"
SlashCmdList.RELOADUI = ReloadUI;

SLASH_FRAMESTK1 = "/fs"; -- for quicker access to frame stack
SlashCmdList.FRAMESTK = function()
    LoadAddOn("Blizzard_DebugTools");
    FrameStackTooltip_Toggle();
end

for i = 1, NUM_CHAT_WINDOWS do
    _G["ChatFrame" .. i .. "EditBox"]:SetAltArrowKeyMode(false);
end

local UseBadNomi = 1;
local BadNomiConfig = 0;
local buttonTable = {};

function makeBadNomiFrame()
    -- Measurements
    local BadNomiConfigX = 235;
    local BadNomiConfigY = -90;
    local BadNomiConfigWidth = 170;
    local BadNomiConfigHeight = 50;
    local optionButtonWidth = BadNomiConfigWidth - 14;
    local optionButtonHeight = 18;

    local numOptions = GetNumGossipOptions();
    -- Frame
    if BadNomiConfig == 0 then
        BadNomiConfig = CreateFrame("Frame", "BadNomi_mainFrame", GossipFrameGreetingPanel, "BasicFrameTemplateWithInset");
        BadNomiConfig:SetSize(BadNomiConfigWidth, BadNomiConfigHeight); -- width, height
        BadNomiConfig:SetPoint("TOP", GossipFrameGreetingPanel, "TOP", BadNomiConfigX, BadNomiConfigY);

        -- title
        BadNomiConfig.title = BadNomiConfig:CreateFontString(nil, "OVERLAY");
        BadNomiConfig.title:SetFontObject("GameFontHighlight");
        BadNomiConfig.title:SetPoint("LEFT", BadNomiConfig.TitleBg, "LEFT", 5, 0)
        BadNomiConfig.title:SetText("Bad Nomi Selector");
        -- 		BadNomi_mainFrame:Hide();
        -- Next button
        local button = CreateFrame("Button", "$parentyEntry", BadNomiConfig, "GameMenuButtonTemplate")
        button:SetPoint("BOTTOMRIGHT", GossipFrameGreetingPanel, "BOTTOMRIGHT", -132, 20)
        button:SetText("Next Nomi");
        button:SetSize(80, 22);
        button:SetNormalFontObject("GameFontNormalSmall");
        button:SetHighlightFontObject("GameFontHighlightSmall");
        button:SetScript("PostClick", function()
            NextNomi()
        end)
    end
    BadNomiConfig:SetSize(BadNomiConfigWidth, BadNomiConfigHeight + (numOptions - 2) * optionButtonHeight);
    -- 	BadNomiConfig.title:SetText("Bad Nomi Selector");

    if numOptions == 1 or numQueued == 24 then -- I have no mats or no room to start more
        BadNomi_mainFrame:Hide();
    else
        BadNomi_mainFrame:Show();
    end

    -- Button Text
    numOptions = numOptions - 1;
    local myOptions = { GetGossipOptions() };
    for i = 2, numOptions do
        table.remove(myOptions, i)
    end
    for i = 1, numOptions do
        for a = 1, #AllOptions do
            if a == 12 then --bacon; because blizzard sucks at consistency; slabs~=slice
                local BaconWords = { strsplit(" ", AllOptions[a]) }
                if string.find(myOptions[i], BaconWords[#BaconWords]) then
                    myOptions[i] = AllOptions[a]
                    break
                end
            elseif string.find(myOptions[i], AllOptions[a]) then
                myOptions[i] = AllOptions[a]
                break
            end
        end
    end
    for key in pairs(buttonTable) do
        buttonTable[key]:Hide()
    end

    local MissingButton = {}
    for L = 1, numOptions do
        local labelExist = false
        for key in pairs(buttonTable) do
            if myOptions[L] == buttonTable[key]:GetText() then
                -- 				buttonTable[key]:SetSize(optionButtonWidth, optionButtonHeight);
                buttonTable[key]:SetScript("PostClick", function()
                    UseBadNomi = 1;
                    SelectGossipOption(L, "", true);
                end)
                buttonTable[key]:SetPoint("TOPLEFT", 6, -8 - optionButtonHeight * L)
                buttonTable[key]:Show()
                labelExist = true
                break
            end
        end
        if labelExist == false then
            MissingButton[L] = myOptions[L]
        end
    end

    for key, value in pairs(MissingButton) do
        local button = CreateFrame("Button", "$parentyEntry" .. key, BadNomiConfig, "GameMenuButtonTemplate")
        button:SetPoint("TOPLEFT", 6, -8 - optionButtonHeight * key)
        button:SetText(value);
        button:SetSize(optionButtonWidth, optionButtonHeight);
        button:SetNormalFontObject("GameFontNormalSmall");
        button:SetHighlightFontObject("GameFontHighlightSmall");
        button:SetScript("PostClick", function()
            UseBadNomi = 1;
            SelectGossipOption(key, "", true);
        end)
        table.insert(buttonTable, button)
    end
end

------------------------------------------------------------------------
local Nomiframe = CreateFrame("FRAME");

Nomiframe:RegisterEvent("GOSSIP_SHOW");
Nomiframe:RegisterEvent("SHIPMENT_CRAFTER_INFO");
Nomiframe:RegisterEvent("GARRISON_LANDINGPAGE_SHIPMENTS");
Nomiframe:RegisterEvent("ADDON_LOADED");

local update = false;

function localize(i)
    C_Timer.After(1, function()
        local name, _ = GetItemInfo(AllOptions[i])
        if name == nil then
            localize(i);
        else
            AllOptions[i] = name
        end
    end);
end

for i = 1, #AllOptions do
    local name, _ = GetItemInfo(AllOptions[i])
    if name == nil then
        localize(i);
    else
        AllOptions[i] = name
    end
end

function DispatchEvent(_, event, arg1, arg2)
    if event == "GOSSIP_SHOW" then
        if UnitExists("target") then
            if UnitName("target") == "Nomi" then
                C_Garrison.RequestLandingPageShipmentInfo();
                local _, _, _, _, queued = C_Garrison.GetLandingPageShipmentInfoByContainerID(122);
                if (queued) then
                    numQueued = queued
                end
                makeBadNomiFrame();
                GossipNpcNameFrame:SetScript("OnMouseDown", function()
                    if BadNomi_mainFrame:IsShown() then BadNomi_mainFrame:Hide(); else BadNomi_mainFrame:Show(); end
                end)
                if GossipFrameGreetingPanel:IsVisible() and autoNomi and IsShiftKeyDown() ~= true then
                    if numQueued < 24 then
                        NextNomi();
                        -- 					elseif numQueued()==25 then
                        -- 						BadNomiConfig.title:SetText("Work Orders Loading...");
                        -- 						loadOrders();
                    end
                end

            elseif BadNomi_mainFrame ~= nil then
                BadNomi_mainFrame:Hide();
                GossipNpcNameFrame:SetScript("OnMouseDown", function()
                end)
            end
        end
    end

    if event == "SHIPMENT_CRAFTER_INFO" and arg2 ~= nil and UnitExists("target") and UnitName("target") == "Nomi" and UseBadNomi == 1 then --number of queued work orders
        numQueued = arg2
        if (arg2 < 24) and GarrisonCapacitiveDisplayFrame:IsVisible() then
            C_Garrison.RequestShipmentCreation(1);
            GarrisonCapacitiveDisplayFrameCloseButton:Click();
            UseBadNomi = 0;
            previousSuccess = previousNomi
        elseif update == true and arg2 == 24 then
            previousNomi = previousSuccess
            update = false
        end
    end

    if event == "GARRISON_LANDINGPAGE_SHIPMENTS" then
        -- 		print(numQueued)
        local _, _, _, _, queued = C_Garrison.GetLandingPageShipmentInfoByContainerID(122);
        if (queued) then
            numQueued = queued
            -- 			print(queued)
        end
    end

    if event == "ADDON_LOADED" and arg1 == "BadNomi" then
        if previousNomi == nil then
            previousNomi = -2
        end
        if autoNomi == nil then
            autoNomi = false
        end
        if numQueued == nil then
            numQueued = 0
        end
    end
end

Nomiframe:SetScript("OnEvent", DispatchEvent);

local function NomiLoader(tooltip)
    local _, unit = tooltip:GetUnit()
    if unit == nil then return; end;
    if UnitGUID(unit) == nil then return; end;
    local npcid = string.sub(UnitGUID(unit), -17, -12)
    if npcid == "101846" then
        C_Garrison.RequestLandingPageShipmentInfo();
        local _, _, _, _, queued = C_Garrison.GetLandingPageShipmentInfoByContainerID(122);
        if (queued) then
            numQueued = queued
        end
        local status = "disabled"
        if autoNomi then
            status = "enabled"
        end
        tooltip:AddLine("autoNomi: " .. status, 255 / 255, 106 / 255, 0 / 255, true)
        if previousNomi > 0 then
            tooltip:AddLine("Previous Order: " .. AllOptions[previousNomi])
        end
        if queued ~= nil and queued < 24 and GossipFrameGreetingPanel:IsVisible() then
            BadNomi_mainFrame:Show()
            if autoNomi and IsShiftKeyDown() ~= true then
                NextNomi()
            end
        end
    end
end

GameTooltip:HookScript("OnTooltipSetUnit", NomiLoader)

function NextNomi()
    if UnitExists("target") and UnitName("target") == "Nomi" and GossipFrameGreetingPanel:IsVisible() then
        if previousNomi == 13 or previousNomi < 0 then
            previousNomi = 0
        end
        local index = previousNomi
        while true do
            for key in pairs(buttonTable) do
                if buttonTable[key]:IsShown() and buttonTable[key]:GetText() == AllOptions[index + 1] then
                    update = true
                    buttonTable[key]:Click()
                    previousNomi = index + 1
                    return
                end
            end
            index = index + 1
            if index == 13 then index = 0; end
            if index == previousNomi then
                if previousNomi == 0 then
                    previousNomi = 13
                end
                break
            end
        end
    end
end

SLASH_AUTONOMI1 = "/autonomi"
SlashCmdList.AUTONOMI = function()
    autoNomi = not autoNomi
    local status = "disabled."
    if autoNomi then
        status = "enabled."
    end
    print("BadNomi: autoNomi " .. status)
end

SLASH_NEXTNOMI1 = "/nextnomi"
SlashCmdList.NEXTNOMI = function()
    if autoNomi == true then
        print("BadNomi: autoNomi disabled.");
        autoNomi = false;
    end
    NextNomi();
end