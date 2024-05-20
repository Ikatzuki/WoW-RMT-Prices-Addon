-- Create a global table for the addon
RMTGoldPrices = {}

-- Default values for saved variables
RMTGoldPrices.defaultSettings = {
    wowTokenPrice = 1, -- Default WoW Token price in gold
    enableChatFeature = true, -- Enable Chat feature by default
    enableVendorFeature = true, -- Enable Vendor feature by default
    enableTooltipFeature = true, -- Enable Tooltip feature by default
    enableAuctionHouseFeature = true, -- Enable Auction House feature by default
    enableBagsFeature = true -- Enable Bags feature by default
}

-- Function to load saved variables
function RMTGoldPrices.LoadSettings()
    if not RMTGoldPricesDB then
        RMTGoldPricesDB = RMTGoldPrices.defaultSettings
    else
        for k, v in pairs(RMTGoldPrices.defaultSettings) do
            if RMTGoldPricesDB[k] == nil then
                RMTGoldPricesDB[k] = v
            end
        end
    end
end

-- Function to update the token label
local function UpdateTokenLabel(tokenLabel)
    tokenLabel:SetText("WoW Token Price: |cFFFFFFFF" .. tostring(RMTGoldPricesDB.wowTokenPrice) .. "|r gold")
end

-- Function to fetch WoW Token price
function RMTGoldPrices.FetchWowTokenPrice(tokenLabel, triggeredByButton)
    -- Update the market price first
    C_WowTokenPublic.UpdateMarketPrice()

    -- Wait a bit for the market price to update
    C_Timer.After(3, function()
        local tokenPriceInCopper = C_WowTokenPublic.GetCurrentMarketPrice()
        if tokenPriceInCopper then
            -- Convert the token price from copper to gold
            local tokenPriceInGold = tokenPriceInCopper / 10000
            RMTGoldPricesDB.wowTokenPrice = tokenPriceInGold
            -- Update the label after fetching the price
            if tokenLabel then
                UpdateTokenLabel(tokenLabel)
            end
            if triggeredByButton then
                print("RMTGoldPrices: WoW Token price updated to " .. tokenPriceInGold .. " gold.")
            end
        else
            print("RMTGoldPrices: Failed to retrieve the current market price.")
        end
    end)
end

-- Function to handle addon loaded event
local function OnAddonLoaded(event, name)
    if name == "RMTGoldPrices" then
        -- Load settings when the addon is loaded
        RMTGoldPrices.LoadSettings()
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
        RMTGoldPrices.FetchWowTokenPrice(nil, false) -- Fetch token price on login without printing
    end
end)

-- Create the options window
function RMTGoldPrices.CreateOptionsWindow()
    local optionsFrame = CreateFrame("Frame", "RMTGoldPricesOptionsFrame", UIParent, "BasicFrameTemplateWithInset")
    optionsFrame:SetSize(450, 300) -- Adjusted width to fit credits text
    optionsFrame:SetPoint("CENTER") -- position at the center of the screen
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

    -- Title text
    local title = optionsFrame:CreateFontString(nil, "OVERLAY")
    title:SetFontObject("GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -3)
    title:SetText("RMTGoldPrices Options")

    -- WoW Token Price text
    local tokenLabel = optionsFrame:CreateFontString(nil, "OVERLAY")
    tokenLabel:SetFontObject("GameFontNormal")
    tokenLabel:SetPoint("TOPLEFT", 10, -40)
    UpdateTokenLabel(tokenLabel)

    -- Update WoW Token Price button
    local updateTokenButton = CreateFrame("Button", nil, optionsFrame, "GameMenuButtonTemplate")
    updateTokenButton:SetSize(175, 25) -- width, height
    updateTokenButton:SetPoint("LEFT", tokenLabel, "RIGHT", 10, 0)
    updateTokenButton:SetText("Update WoW Token Price")
    updateTokenButton:SetNormalFontObject("GameFontNormal")
    updateTokenButton:SetHighlightFontObject("GameFontHighlight")

    local canClickUpdate = true
    updateTokenButton:SetScript("OnClick", function()
        if canClickUpdate then
            canClickUpdate = false
            RMTGoldPrices.FetchWowTokenPrice(tokenLabel, true) -- Fetch token price and print
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
        checkbox:SetChecked(RMTGoldPricesDB[settingKey])

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
    saveButton:SetSize(80, 30) -- width, height
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
        local oldBagsFeatureEnabled = RMTGoldPricesDB.enableBagsFeature

        RMTGoldPricesDB.enableChatFeature = newChatFeatureEnabled
        RMTGoldPricesDB.enableVendorFeature = newVendorFeatureEnabled
        RMTGoldPricesDB.enableTooltipFeature = newTooltipFeatureEnabled
        RMTGoldPricesDB.enableAuctionHouseFeature = newAuctionHouseFeatureEnabled
        RMTGoldPricesDB.enableBagsFeature = newBagsFeatureEnabled

        -- Check if the bags feature setting was changed
        if oldBagsFeatureEnabled ~= newBagsFeatureEnabled then
            ReloadUI() -- Reload the UI to apply the changes
        else
            optionsFrame:Hide()
        end
    end)
end

-- Slash command to show options window
SLASH_RGP1 = "/rgp"
SlashCmdList["RGP"] = function()
    if not RMTGoldPricesOptionsFrame then
        RMTGoldPrices.CreateOptionsWindow()
    end
    RMTGoldPricesOptionsFrame:Show()
end

-- Ensure settings are loaded immediately
RMTGoldPrices.LoadSettings()
