-- Create a global table for the addon
RMTGoldPrices = {}

-- Default values for saved variables
RMTGoldPrices.defaultSettings = {
    wowTokenPrice = 1, -- Default WoW Token price in gold
    chatDebugEnabled = false, -- Default chat debug state
    ahDebugEnabled = false, -- Default AH debug state
    enableChatFeature = true, -- Enable Chat feature by default
    enableVendorFeature = true, -- Enable Vendor feature by default
    enableTooltipFeature = true, -- Enable Tooltip feature by default
    enableAuctionHouseFeature = true -- Enable Auction House feature by default
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
function RMTGoldPrices.FetchWowTokenPrice(tokenLabel)
    -- Update the market price first
    C_WowTokenPublic.UpdateMarketPrice()

    -- Wait a bit for the market price to update
    C_Timer.After(1, function()
        local tokenPriceInCopper = C_WowTokenPublic.GetCurrentMarketPrice()
        if tokenPriceInCopper then
            -- Convert the token price from copper to gold
            local tokenPriceInGold = tokenPriceInCopper / 10000
            RMTGoldPricesDB.wowTokenPrice = tokenPriceInGold
            print("RMTGoldPrices: WoW Token price updated to " .. tokenPriceInGold .. " gold.")
            -- Update the label after fetching the price
            if tokenLabel then
                UpdateTokenLabel(tokenLabel)
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
        RMTGoldPrices.FetchWowTokenPrice()
    end
end)

-- Function to toggle pause state
function RMTGoldPrices.TogglePause()
    RMTGoldPrices.isPaused = not RMTGoldPrices.isPaused
    if RMTGoldPrices.isPaused then
        print("RMTGoldPrices addon paused.")
    else
        print("RMTGoldPrices addon resumed.")
    end
end

-- Function to resume the addon
function RMTGoldPrices.ResumeAddon()
    if RMTGoldPrices.isPaused then
        RMTGoldPrices.isPaused = false
        print("RMTGoldPrices addon resumed.")
    else
        print("RMTGoldPrices addon is already running.")
    end
end

-- Create the options window
function RMTGoldPrices.CreateOptionsWindow()
    local optionsFrame = CreateFrame("Frame", "RMTGoldPricesOptionsFrame", UIParent, "BasicFrameTemplateWithInset")
    optionsFrame:SetSize(550, 400) -- Adjusted height to fit new options
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
    title:SetPoint("TOP", 0, -10)
    title:SetText("RMTGoldPrices Options")

    -- WoW Token Price text
    local tokenLabel = optionsFrame:CreateFontString(nil, "OVERLAY")
    tokenLabel:SetFontObject("GameFontNormal")
    tokenLabel:SetPoint("TOPLEFT", 10, -40)
    UpdateTokenLabel(tokenLabel)

    -- Update WoW Token Price button
    local updateTokenButton = CreateFrame("Button", nil, optionsFrame, "GameMenuButtonTemplate")
    updateTokenButton:SetSize(150, 20) -- width, height
    updateTokenButton:SetPoint("LEFT", tokenLabel, "RIGHT", 10, 0)
    updateTokenButton:SetText("Update WoW Token Price")
    updateTokenButton:SetNormalFontObject("GameFontNormal")
    updateTokenButton:SetHighlightFontObject("GameFontHighlight")

    local canClickUpdate = true
    updateTokenButton:SetScript("OnClick", function()
        if canClickUpdate then
            canClickUpdate = false
            RMTGoldPrices.FetchWowTokenPrice(tokenLabel)
            C_Timer.After(5, function()
                canClickUpdate = true
            end)
        else
            print("Please wait before clicking the update button again.")
        end
    end)

    -- Debug Enabled text
    local debugLabel = optionsFrame:CreateFontString(nil, "OVERLAY")
    debugLabel:SetFontObject("GameFontNormal")
    debugLabel:SetPoint("TOPLEFT", 10, -100)
    debugLabel:SetText("Enable Chat Debug Messages:")

    -- Debug Enabled checkbox
    local debugCheckbox = CreateFrame("CheckButton", nil, optionsFrame, "ChatConfigCheckButtonTemplate")
    debugCheckbox:SetPoint("LEFT", debugLabel, "RIGHT", 10, 0)
    debugCheckbox:SetChecked(RMTGoldPricesDB.chatDebugEnabled)

    -- Auction House Debug Enabled text
    local auctionDebugLabel = optionsFrame:CreateFontString(nil, "OVERLAY")
    auctionDebugLabel:SetFontObject("GameFontNormal")
    auctionDebugLabel:SetPoint("TOPLEFT", 10, -130)
    auctionDebugLabel:SetText("Enable AH Debug Messages:")

    -- Auction House Debug Enabled checkbox
    local auctionDebugCheckbox = CreateFrame("CheckButton", nil, optionsFrame, "ChatConfigCheckButtonTemplate")
    auctionDebugCheckbox:SetPoint("LEFT", auctionDebugLabel, "RIGHT", 10, 0)
    auctionDebugCheckbox:SetChecked(RMTGoldPricesDB.ahDebugEnabled)

    -- Enable Chat Feature text
    local chatFeatureLabel = optionsFrame:CreateFontString(nil, "OVERLAY")
    chatFeatureLabel:SetFontObject("GameFontNormal")
    chatFeatureLabel:SetPoint("TOPLEFT", 10, -160)
    chatFeatureLabel:SetText("Enable Chat Feature:")

    -- Enable Chat Feature checkbox
    local chatFeatureCheckbox = CreateFrame("CheckButton", nil, optionsFrame, "ChatConfigCheckButtonTemplate")
    chatFeatureCheckbox:SetPoint("LEFT", chatFeatureLabel, "RIGHT", 10, 0)
    chatFeatureCheckbox:SetChecked(RMTGoldPricesDB.enableChatFeature)

    -- Enable Vendor Feature text
    local vendorFeatureLabel = optionsFrame:CreateFontString(nil, "OVERLAY")
    vendorFeatureLabel:SetFontObject("GameFontNormal")
    vendorFeatureLabel:SetPoint("TOPLEFT", 10, -190)
    vendorFeatureLabel:SetText("Enable Vendor Feature:")

    -- Enable Vendor Feature checkbox
    local vendorFeatureCheckbox = CreateFrame("CheckButton", nil, optionsFrame, "ChatConfigCheckButtonTemplate")
    vendorFeatureCheckbox:SetPoint("LEFT", vendorFeatureLabel, "RIGHT", 10, 0)
    vendorFeatureCheckbox:SetChecked(RMTGoldPricesDB.enableVendorFeature)

    -- Enable Tooltip Feature text
    local tooltipFeatureLabel = optionsFrame:CreateFontString(nil, "OVERLAY")
    tooltipFeatureLabel:SetFontObject("GameFontNormal")
    tooltipFeatureLabel:SetPoint("TOPLEFT", 10, -220)
    tooltipFeatureLabel:SetText("Enable Tooltip Feature:")

    -- Enable Tooltip Feature checkbox
    local tooltipFeatureCheckbox = CreateFrame("CheckButton", nil, optionsFrame, "ChatConfigCheckButtonTemplate")
    tooltipFeatureCheckbox:SetPoint("LEFT", tooltipFeatureLabel, "RIGHT", 10, 0)
    tooltipFeatureCheckbox:SetChecked(RMTGoldPricesDB.enableTooltipFeature)

    -- Enable Auction House Feature text
    local auctionHouseFeatureLabel = optionsFrame:CreateFontString(nil, "OVERLAY")
    auctionHouseFeatureLabel:SetFontObject("GameFontNormal")
    auctionHouseFeatureLabel:SetPoint("TOPLEFT", 10, -250)
    auctionHouseFeatureLabel:SetText("Enable Auction House Feature:")

    -- Enable Auction House Feature checkbox
    local auctionHouseFeatureCheckbox = CreateFrame("CheckButton", nil, optionsFrame, "ChatConfigCheckButtonTemplate")
    auctionHouseFeatureCheckbox:SetPoint("LEFT", auctionHouseFeatureLabel, "RIGHT", 10, 0)
    auctionHouseFeatureCheckbox:SetChecked(RMTGoldPricesDB.enableAuctionHouseFeature)

    -- Save button
    local saveButton = CreateFrame("Button", nil, optionsFrame, "GameMenuButtonTemplate")
    saveButton:SetSize(80, 30) -- width, height
    saveButton:SetPoint("BOTTOM", 0, 10)
    saveButton:SetText("Save")
    saveButton:SetNormalFontObject("GameFontNormalLarge")
    saveButton:SetHighlightFontObject("GameFontHighlightLarge")

    saveButton:SetScript("OnClick", function()
        local newDebugEnabled = debugCheckbox:GetChecked()
        local newAuctionDebugEnabled = auctionDebugCheckbox:GetChecked()
        local newChatFeatureEnabled = chatFeatureCheckbox:GetChecked()
        local newVendorFeatureEnabled = vendorFeatureCheckbox:GetChecked()
        local newTooltipFeatureEnabled = tooltipFeatureCheckbox:GetChecked()
        local newAuctionHouseFeatureEnabled = auctionHouseFeatureCheckbox:GetChecked()

        RMTGoldPricesDB.chatDebugEnabled = newDebugEnabled
        RMTGoldPricesDB.ahDebugEnabled = newAuctionDebugEnabled
        RMTGoldPricesDB.enableChatFeature = newChatFeatureEnabled
        RMTGoldPricesDB.enableVendorFeature = newVendorFeatureEnabled
        RMTGoldPricesDB.enableTooltipFeature = newTooltipFeatureEnabled
        RMTGoldPricesDB.enableAuctionHouseFeature = newAuctionHouseFeatureEnabled

        -- Check if vendor feature setting was changed
        if newVendorFeatureEnabled ~= RMTGoldPricesDB.enableVendorFeature then
            ReloadUI() -- Reload the UI to apply the changes
        else
            optionsFrame:Hide()
        end
    end)
end

-- Slash command to show options window, toggle pause state, and resume the addon
SLASH_RGP1 = "/rgp"
SlashCmdList["RGP"] = function(msg)
    if msg == "options" then
        if not RMTGoldPricesOptionsFrame then
            RMTGoldPrices.CreateOptionsWindow()
        end
        RMTGoldPricesOptionsFrame:Show()
    elseif msg == "pause" then
        RMTGoldPrices.TogglePause()
    elseif msg == "resume" then
        RMTGoldPrices.ResumeAddon()
    else
        print(
            "RMTGoldPrices: Unknown command. Use '/rgp options' to open the options window, '/rgp pause' to toggle pause, or '/rgp resume' to resume.")
    end
end

-- Ensure settings are loaded immediately
RMTGoldPrices.LoadSettings()
