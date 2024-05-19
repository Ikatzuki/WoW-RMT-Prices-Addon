-- Function to format and append dollar value to the buyout price
local function AppendDollarValueToBuyoutPrice(buyoutPrice)
    local goldValue = buyoutPrice / 10000
    local tokenDollarValue = (goldValue / RMTGoldPricesDB.wowTokenPrice) * 20
    local illegalDollarValue = (goldValue / 10000) * RMTGoldPricesDB.illegalGoldPrice

    return string.format(" |cFFFFD700($%.2f / $%.2f)|r", tokenDollarValue, illegalDollarValue)
end

-- Function to update the buyout price display with the dollar value
local function UpdateBuyoutPriceDisplay(buttonIndex)
    local button = _G["BrowseButton" .. buttonIndex]
    if button then
        local buyoutPrice = button.buyoutPrice

        if buyoutPrice and buyoutPrice > 0 then
            local dollarText = AppendDollarValueToBuyoutPrice(buyoutPrice)
            if not BrowseBuyoutPriceDollar then
                -- Use the parent frame of BrowseTitle to create the font string
                BrowseBuyoutPriceDollar = AuctionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                BrowseBuyoutPriceDollar:SetPoint("LEFT", BrowseTitle, "RIGHT", 100, 0)
            end
            BrowseBuyoutPriceDollar:SetText(dollarText)
        end
    end
end

-- Hook into the Auction House frame
local function HookAuctionHouse()
    -- Hook into the click event for auction items
    for i = 1, 50 do -- Assuming a maximum of 50 items visible in the auction house window
        local button = _G["BrowseButton" .. i]
        if button then
            button:HookScript("OnClick", function()
                C_Timer.After(0.1, function()
                    UpdateBuyoutPriceDisplay(i)
                end)
            end)
        end
    end
end

-- Event handler to wait for Auction House UI to load
local function OnEvent(self, event, ...)
    if event == "AUCTION_HOUSE_SHOW" then
        HookAuctionHouse()
    end
end

-- Create a frame to listen for events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
eventFrame:SetScript("OnEvent", OnEvent)

-- Print to confirm the script is loaded
print("RMTGoldPrices Auction House addon loaded.")
