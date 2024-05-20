-- Function to format and append dollar value to the buyout price
local function AppendDollarValueToBuyoutPrice(buyoutPrice)
    local goldValue = buyoutPrice / 10000
    local tokenDollarValue = (goldValue / GoldtoCashValueDB.wowTokenPrice) * 20

    return string.format(" |cFFFFD700($%.2f)|r", tokenDollarValue)
end

-- Function to update the buyout price display with the dollar value
local function UpdateBuyoutPriceDisplay(buttonIndex)
    if not GoldtoCashValueDB.enableAuctionHouseFeature then
        return
    end

    local button = _G["BrowseButton" .. buttonIndex]
    if button then
        local buyoutPrice = button.buyoutPrice

        if buyoutPrice and buyoutPrice > 0 then
            local dollarText = AppendDollarValueToBuyoutPrice(buyoutPrice)
            local parentFrame

            if IsAddOnLoaded("ElvUI") then
                -- ElvUI is loaded, use AuctionFrame as the parent frame
                parentFrame = AuctionFrame
                if not BrowseBuyoutPriceDollar then
                    BrowseBuyoutPriceDollar = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    BrowseBuyoutPriceDollar:SetPoint("LEFT", BrowseTitle, "RIGHT", 100, 0)
                end
            else
                -- Default UI, use BrowseBuyoutPriceGoldButtonText as the reference
                parentFrame = _G["BrowseBuyoutPriceGoldButtonText"]
                if not BrowseBuyoutPriceDollar then
                    BrowseBuyoutPriceDollar = parentFrame:GetParent():CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    BrowseBuyoutPriceDollar:SetPoint("RIGHT", parentFrame, "LEFT", -2, 0)
                end
            end

            BrowseBuyoutPriceDollar:SetText(dollarText)
        end
    end
end

-- Function to clear the dollar value text
local function ClearBuyoutPriceDisplay()
    if BrowseBuyoutPriceDollar then
        BrowseBuyoutPriceDollar:SetText("")
    end
end

-- Hook into the Auction House frame
local function HookAuctionHouse()
    if not GoldtoCashValueDB.enableAuctionHouseFeature then
        return
    end

    -- Hook into the click event for auction items
    for i = 1, 50 do -- Assuming a maximum of 50 items visible in the auction house window
        local button = _G["BrowseButton" .. i]
        if button and not button.isHooked then
            button:HookScript("OnClick", function()
                C_Timer.After(0.1, function()
                    UpdateBuyoutPriceDisplay(i)
                end)
            end)
            button.isHooked = true -- Mark this button as hooked
        end
    end
end

-- Event handler to wait for Auction House UI to load
local function OnEvent(self, event, ...)
    if event == "AUCTION_HOUSE_SHOW" then
        if not GoldtoCashValueDB.enableAuctionHouseFeature then
            ClearBuyoutPriceDisplay() -- Clear the dollar value text when the Auction House is opened if the feature is disabled
            return
        end

        ClearBuyoutPriceDisplay() -- Clear the dollar value text when the Auction House is opened
        HookAuctionHouse()
    end
end

-- Ensure the database is initialized
if not GoldtoCashValueDB then
    return
end

-- Create a frame to listen for events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
eventFrame:SetScript("OnEvent", OnEvent)
