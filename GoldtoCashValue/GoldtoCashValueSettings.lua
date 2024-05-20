-- Create a global table for the addon
GoldtoCashValue = {}

-- Default values for saved variables
GoldtoCashValue.defaultSettings = {
    wowTokenPrice = 5000,
    enableChatFeature = true,
    enableVendorFeature = true,
    enableTooltipFeature = true,
    enableAuctionHouseFeature = true,
    enableBagsFeature = true
}

-- Function to load saved variables
function GoldtoCashValue.LoadSettings()
    if not GoldtoCashValueDB then
        GoldtoCashValueDB = GoldtoCashValue.defaultSettings
    else
        for k, v in pairs(GoldtoCashValue.defaultSettings) do
            if GoldtoCashValueDB[k] == nil then
                GoldtoCashValueDB[k] = v
            end
        end
    end
end

-- Function to update the token label
local function UpdateTokenLabel(tokenLabel)
    tokenLabel:SetText("WoW Token Price: |cFFFFFFFF" .. tostring(GoldtoCashValueDB.wowTokenPrice) .. "|r gold")
end

-- Function to fetch WoW Token price
function GoldtoCashValue.FetchWowTokenPrice(tokenLabel, triggeredByButton)
    -- Update the market price first
    C_WowTokenPublic.UpdateMarketPrice()

    -- Wait a bit for the market price to update
    C_Timer.After(3, function()
        local tokenPriceInCopper = C_WowTokenPublic.GetCurrentMarketPrice()
        if tokenPriceInCopper then
            -- Convert the token price from copper to gold
            local tokenPriceInGold = tokenPriceInCopper / 10000
            GoldtoCashValueDB.wowTokenPrice = tokenPriceInGold
            -- Update the label after fetching the price
            if tokenLabel then
                UpdateTokenLabel(tokenLabel)
            end
            if triggeredByButton then
                print("GoldtoCashValue: WoW Token price updated to " .. tokenPriceInGold .. " gold.")
            end
        else
            print("GoldtoCashValue: Failed to retrieve the current market price.")
        end
    end)
end

-- Function to handle addon loaded event
local function OnAddonLoaded(event, name)
    if name == "GoldtoCashValue" then
        -- Load settings when the addon is loaded
        GoldtoCashValue.LoadSettings()
    end
end

-- Register event listener for ADDON_LOADED and PLAYER_LOGIN
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" then
        OnAddonLoaded(event, name)
    elseif event == "PLAYER_LOGIN" then
        GoldtoCashValue.FetchWowTokenPrice(nil, false)
    end
end)

-- Create the options window
function GoldtoCashValue.CreateOptionsWindow()
    local optionsFrame = CreateFrame("Frame", "GoldtoCashValueOptionsFrame", UIParent, "BasicFrameTemplateWithInset")
    optionsFrame:SetSize(450, 300)
    optionsFrame:SetPoint("CENTER")
    optionsFrame:SetMovable(true)
    optionsFrame:EnableMouse(true)
    optionsFrame:RegisterForDrag("LeftButton")
    optionsFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    optionsFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    optionsFrame:Hide()

    -- Add the options frame to UISpecialFrames to enable closing with Escape key
    tinsert(UISpecialFrames, "GoldtoCashValueOptionsFrame")

    -- Title text
    local title = optionsFrame:CreateFontString(nil, "OVERLAY")
    title:SetFontObject("GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -3)
    title:SetText("Gold to Cash Value Options")

    -- WoW Token Price text
    local tokenLabel = optionsFrame:CreateFontString(nil, "OVERLAY")
    tokenLabel:SetFontObject("GameFontNormal")
    tokenLabel:SetPoint("TOPLEFT", 10, -40)
    UpdateTokenLabel(tokenLabel)

    -- Update WoW Token Price button
    local updateTokenButton = CreateFrame("Button", nil, optionsFrame, "GameMenuButtonTemplate")
    updateTokenButton:SetSize(175, 25)
    updateTokenButton:SetPoint("LEFT", tokenLabel, "RIGHT", 10, 0)
    updateTokenButton:SetText("Update WoW Token Price")
    updateTokenButton:SetNormalFontObject("GameFontNormal")
    updateTokenButton:SetHighlightFontObject("GameFontHighlight")

    local canClickUpdate = true
    updateTokenButton:SetScript("OnClick", function()
        if canClickUpdate then
            canClickUpdate = false
            GoldtoCashValue.FetchWowTokenPrice(tokenLabel, true)
            C_Timer.After(5, function()
                canClickUpdate = true
            end)
        else
            print("Please wait before clicking the update button again.")
        end
    end)

    -- Function to create a feature option
    local function CreateFeatureOption(labelText, settingKey, anchorFrame)
        local label = optionsFrame:CreateFontString(nil, "OVERLAY")
        label:SetFontObject("GameFontNormal")
        label:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -15)
        label:SetText(labelText)

        local checkbox = CreateFrame("CheckButton", nil, optionsFrame, "ChatConfigCheckButtonTemplate")
        checkbox:SetPoint("LEFT", label, "RIGHT", 10, 0)
        checkbox:SetChecked(GoldtoCashValueDB[settingKey])

        return label, checkbox
    end

    -- Create feature options
    local chatFeatureLabel, chatFeatureCheckbox = CreateFeatureOption("Enable Chat Feature:", "enableChatFeature",
        tokenLabel)
    local vendorFeatureLabel, vendorFeatureCheckbox = CreateFeatureOption("Enable Vendor Feature:",
        "enableVendorFeature", chatFeatureLabel)
    local tooltipFeatureLabel, tooltipFeatureCheckbox = CreateFeatureOption("Enable Tooltip Feature:",
        "enableTooltipFeature", vendorFeatureLabel)
    local auctionHouseFeatureLabel, auctionHouseFeatureCheckbox =
        CreateFeatureOption("Enable Auction House Feature:", "enableAuctionHouseFeature", tooltipFeatureLabel)
    local bagsFeatureLabel, bagsFeatureCheckbox = CreateFeatureOption("Enable Bags Feature (Requires reload):",
        "enableBagsFeature", auctionHouseFeatureLabel)

    -- Credits text
    local CreditsLabel = optionsFrame:CreateFontString(nil, "OVERLAY")
    CreditsLabel:SetFontObject("GameFontNormal")
    CreditsLabel:SetPoint("BOTTOM", 0, 50)
    CreditsLabel:SetText("|cFFFFFFFFMade by Richiep - Mankrik (US) with help from Khaat - Mankrik (US)|r")

    -- Save button
    local saveButton = CreateFrame("Button", nil, optionsFrame, "GameMenuButtonTemplate")
    saveButton:SetSize(80, 30)
    saveButton:SetPoint("BOTTOM", 0, 10)
    saveButton:SetText("Save")
    saveButton:SetNormalFontObject("GameFontNormalLarge")
    saveButton:SetHighlightFontObject("GameFontHighlightLarge")

    saveButton:SetScript("OnClick", function()
        local newChatFeatureEnabled = chatFeatureCheckbox:GetChecked()
        local newVendorFeatureEnabled = vendorFeatureCheckbox:GetChecked()
        local newTooltipFeatureEnabled = tooltipFeatureCheckbox:GetChecked()
        local newAuctionHouseFeatureEnabled = auctionHouseFeatureCheckbox:GetChecked()
        local newBagsFeatureEnabled = bagsFeatureCheckbox:GetChecked()

        -- Save current settings to check against the new settings later
        local oldBagsFeatureEnabled = GoldtoCashValueDB.enableBagsFeature

        GoldtoCashValueDB.enableChatFeature = newChatFeatureEnabled
        GoldtoCashValueDB.enableVendorFeature = newVendorFeatureEnabled
        GoldtoCashValueDB.enableTooltipFeature = newTooltipFeatureEnabled
        GoldtoCashValueDB.enableAuctionHouseFeature = newAuctionHouseFeatureEnabled
        GoldtoCashValueDB.enableBagsFeature = newBagsFeatureEnabled

        -- Check if the bags feature setting was changed
        if oldBagsFeatureEnabled ~= newBagsFeatureEnabled then
            ReloadUI()
        else
            optionsFrame:Hide()
        end
    end)
end

-- Slash command to show options window
SLASH_GTC1 = "/gtc"
SlashCmdList["GTC"] = function()
    if not GoldtoCashValueOptionsFrame then
        GoldtoCashValue.CreateOptionsWindow()
    end
    GoldtoCashValueOptionsFrame:Show()
end

-- Ensure settings are loaded immediately
GoldtoCashValue.LoadSettings()
