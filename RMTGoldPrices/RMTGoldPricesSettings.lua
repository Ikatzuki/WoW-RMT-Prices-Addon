-- Create a global table for the addon
RMTGoldPrices = {}

-- Default values for saved variables
RMTGoldPrices.defaultSettings = {
    wowTokenPrice = 6138, -- Default WoW Token price in gold
    illegalGoldPrice = 15, -- Default illegal gold price for $20
    chatDebugEnabled = false, -- Default chat debug state
    ahDebugEnabled = false, -- Default AH debug state
    autoUpdateTokenPrice = true, -- Default auto-update WoW token price state
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

-- Function to handle addon loaded event
local function OnAddonLoaded(event, name)
    if name == "RMTGoldPrices" then
        -- Load settings when the addon is loaded
        RMTGoldPrices.LoadSettings()
    end
end

-- Register event listener for ADDON_LOADED
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", OnAddonLoaded)

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

-- Function to fetch WoW Token price
function RMTGoldPrices.FetchWowTokenPrice()
    local wowTokenButton = _G["AuctionFilterButton13"]
    if wowTokenButton then
        -- Click the WoW Token button to update the price
        wowTokenButton:Click()
        wowTokenButton:Click()

        C_Timer.After(1, function()
            local tokenPriceFrame = BrowseWowTokenResults and BrowseWowTokenResults.BuyoutPrice
            if tokenPriceFrame then
                local tokenPriceText = tokenPriceFrame:GetText()
                if tokenPriceText then
                    local tokenPriceCleanText = tokenPriceText:gsub(",", "")
                    local tokenPrice = tonumber(tokenPriceCleanText:match("%d+"))
                    if tokenPrice then
                        RMTGoldPricesDB.wowTokenPrice = tokenPrice
                        if RMTGoldPricesDB.ahDebugEnabled then
                            print("RMTGoldPrices: WoW Token price updated to " .. tokenPrice .. " gold.")
                        end
                    else
                        if RMTGoldPricesDB.ahDebugEnabled then
                            print("RMTGoldPrices: Failed to extract token price from text.")
                        end
                    end
                else
                    if RMTGoldPricesDB.ahDebugEnabled then
                        print("RMTGoldPrices: Token price text not found.")
                    end
                end
            else
                if RMTGoldPricesDB.ahDebugEnabled then
                    print("RMTGoldPrices: BuyoutPrice frame not found.")
                end
            end
        end)
    else
        if RMTGoldPricesDB.ahDebugEnabled then
            print("RMTGoldPrices: WoW Token button not found.")
        end
    end
end

-- Function to handle Auction House open event
function RMTGoldPrices.OnAuctionHouseShow()
    RMTGoldPrices.FetchWowTokenPrice()
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
    tokenLabel:SetText("WoW Token Price:")

    -- WoW Token Price input box
    local tokenInput = CreateFrame("EditBox", nil, optionsFrame, "InputBoxTemplate")
    tokenInput:SetSize(50, 20) -- width, height
    tokenInput:SetPoint("LEFT", tokenLabel, "RIGHT", 10, 0)
    tokenInput:SetAutoFocus(false)
    tokenInput:SetText(tostring(RMTGoldPricesDB.wowTokenPrice))

    -- Illegal Gold Price text
    local illegalLabel = optionsFrame:CreateFontString(nil, "OVERLAY")
    illegalLabel:SetFontObject("GameFontNormal")
    illegalLabel:SetPoint("TOPLEFT", 10, -70)
    illegalLabel:SetText("Price per 10k Illegal Gold ($):")

    -- Illegal Gold Price input box
    local illegalInput = CreateFrame("EditBox", nil, optionsFrame, "InputBoxTemplate")
    illegalInput:SetSize(50, 20) -- width, height
    illegalInput:SetPoint("LEFT", illegalLabel, "RIGHT", 10, 0)
    illegalInput:SetAutoFocus(false)
    illegalInput:SetText(tostring(RMTGoldPricesDB.illegalGoldPrice))

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

    -- Auto-update WoW Token Price text
    local autoUpdateTokenLabel = optionsFrame:CreateFontString(nil, "OVERLAY")
    autoUpdateTokenLabel:SetFontObject("GameFontNormal")
    autoUpdateTokenLabel:SetPoint("TOPLEFT", 10, -160)
    autoUpdateTokenLabel:SetText("Auto-update WoW Token Price:")

    -- Auto-update WoW Token Price checkbox
    local autoUpdateTokenCheckbox = CreateFrame("CheckButton", nil, optionsFrame, "ChatConfigCheckButtonTemplate")
    autoUpdateTokenCheckbox:SetPoint("LEFT", autoUpdateTokenLabel, "RIGHT", 10, 0)
    autoUpdateTokenCheckbox:SetChecked(RMTGoldPricesDB.autoUpdateTokenPrice)

    -- Enable Chat Feature text
    local chatFeatureLabel = optionsFrame:CreateFontString(nil, "OVERLAY")
    chatFeatureLabel:SetFontObject("GameFontNormal")
    chatFeatureLabel:SetPoint("TOPLEFT", 10, -190)
    chatFeatureLabel:SetText("Enable Chat Feature:")

    -- Enable Chat Feature checkbox
    local chatFeatureCheckbox = CreateFrame("CheckButton", nil, optionsFrame, "ChatConfigCheckButtonTemplate")
    chatFeatureCheckbox:SetPoint("LEFT", chatFeatureLabel, "RIGHT", 10, 0)
    chatFeatureCheckbox:SetChecked(RMTGoldPricesDB.enableChatFeature)

    -- Enable Vendor Feature text
    local vendorFeatureLabel = optionsFrame:CreateFontString(nil, "OVERLAY")
    vendorFeatureLabel:SetFontObject("GameFontNormal")
    vendorFeatureLabel:SetPoint("TOPLEFT", 10, -220)
    vendorFeatureLabel:SetText("Enable Vendor Feature:")

    -- Enable Vendor Feature checkbox
    local vendorFeatureCheckbox = CreateFrame("CheckButton", nil, optionsFrame, "ChatConfigCheckButtonTemplate")
    vendorFeatureCheckbox:SetPoint("LEFT", vendorFeatureLabel, "RIGHT", 10, 0)
    vendorFeatureCheckbox:SetChecked(RMTGoldPricesDB.enableVendorFeature)

    -- Enable Tooltip Feature text
    local tooltipFeatureLabel = optionsFrame:CreateFontString(nil, "OVERLAY")
    tooltipFeatureLabel:SetFontObject("GameFontNormal")
    tooltipFeatureLabel:SetPoint("TOPLEFT", 10, -250)
    tooltipFeatureLabel:SetText("Enable Tooltip Feature:")

    -- Enable Tooltip Feature checkbox
    local tooltipFeatureCheckbox = CreateFrame("CheckButton", nil, optionsFrame, "ChatConfigCheckButtonTemplate")
    tooltipFeatureCheckbox:SetPoint("LEFT", tooltipFeatureLabel, "RIGHT", 10, 0)
    tooltipFeatureCheckbox:SetChecked(RMTGoldPricesDB.enableTooltipFeature)

    -- Enable Auction House Feature text
    local auctionHouseFeatureLabel = optionsFrame:CreateFontString(nil, "OVERLAY")
    auctionHouseFeatureLabel:SetFontObject("GameFontNormal")
    auctionHouseFeatureLabel:SetPoint("TOPLEFT", 10, -280)
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
        local newTokenPrice = tonumber(tokenInput:GetText())
        local newIllegalPrice = tonumber(illegalInput:GetText())
        local newDebugEnabled = debugCheckbox:GetChecked()
        local newAuctionDebugEnabled = auctionDebugCheckbox:GetChecked()
        local newAutoUpdateTokenPrice = autoUpdateTokenCheckbox:GetChecked()
        local newChatFeatureEnabled = chatFeatureCheckbox:GetChecked()
        local newVendorFeatureEnabled = vendorFeatureCheckbox:GetChecked()
        local newTooltipFeatureEnabled = tooltipFeatureCheckbox:GetChecked()
        local newAuctionHouseFeatureEnabled = auctionHouseFeatureCheckbox:GetChecked()

        if newTokenPrice and newIllegalPrice then
            RMTGoldPricesDB.wowTokenPrice = newTokenPrice
            RMTGoldPricesDB.illegalGoldPrice = newIllegalPrice
            RMTGoldPricesDB.chatDebugEnabled = newDebugEnabled
            RMTGoldPricesDB.ahDebugEnabled = newAuctionDebugEnabled
            RMTGoldPricesDB.autoUpdateTokenPrice = newAutoUpdateTokenPrice
            RMTGoldPricesDB.enableChatFeature = newChatFeatureEnabled
            RMTGoldPricesDB.enableVendorFeature = newVendorFeatureEnabled
            RMTGoldPricesDB.enableTooltipFeature = newTooltipFeatureEnabled
            RMTGoldPricesDB.enableAuctionHouseFeature = newAuctionHouseFeatureEnabled

            print("RMTGoldPrices: Settings updated.")
        else
            print("RMTGoldPrices: Invalid input. Please enter valid numbers.")
        end

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
