-- Function to convert vendor price to dollar value
local function ConvertToDollarValue(vendorPrice)
    local goldValue = vendorPrice / 10000
    local tokenDollarValue = (goldValue / RMTGoldPricesDB.wowTokenPrice) * 20
    local illegalDollarValue = (goldValue / 10000) * RMTGoldPricesDB.illegalGoldPrice
    return tokenDollarValue, illegalDollarValue
end

-- Function to create or update the dollar text next to the vendor item price
local function UpdateVendorItemDollarText(index, dollarText)
    local moneyFrame = _G["MerchantItem" .. index .. "MoneyFrame"]
    if moneyFrame then
        local goldButton = _G[moneyFrame:GetName() .. "GoldButton"]
        if goldButton then
            if not moneyFrame.dollarText then
                moneyFrame.dollarText = moneyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                moneyFrame.dollarText:SetPoint("LEFT", goldButton, "RIGHT", 2, 0)
            end
            moneyFrame.dollarText:SetText(dollarText)
            moneyFrame.dollarText:Show()
        end
    end
end

-- Function to handle the merchant frame update event
local function OnMerchantFrameUpdate()
    for index = 1, GetMerchantNumItems() do
        local itemPrice = select(3, GetMerchantItemInfo(index))
        if itemPrice and itemPrice > 0 then
            local tokenDollarValue, illegalDollarValue = ConvertToDollarValue(itemPrice)
            local dollarText = string.format("$%.2f / $%.2f", tokenDollarValue, illegalDollarValue)
            UpdateVendorItemDollarText(index, dollarText)
        end
    end
end

-- Function to handle merchant show event
local function OnMerchantShow()
    OnMerchantFrameUpdate()
end

-- Event handler for merchant frame events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:RegisterEvent("MERCHANT_UPDATE")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "MERCHANT_SHOW" then
        OnMerchantShow()
    elseif event == "MERCHANT_UPDATE" then
        OnMerchantFrameUpdate()
    end
end)

-- Debug: Print to confirm the script is loaded
print("RMTGoldPrices: Vendor price script loaded.")
