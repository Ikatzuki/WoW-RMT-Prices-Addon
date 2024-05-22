-- Function to convert vendor price to dollar value
local function ConvertToDollarValue(vendorPrice)
    local goldValue = vendorPrice / 10000
    local tokenDollarValue = (goldValue / GoldtoCashValueDB.wowTokenPrice) * 20
    return tokenDollarValue
end

-- Function to create or update the dollar text above the vendor item price
local function UpdateVendorItemDollarText(index, dollarText)
    local itemNameFrame = _G["MerchantItem" .. index .. "Name"]
    if itemNameFrame then
        local moneyFrame = _G["MerchantItem" .. index .. "MoneyFrame"]
        if moneyFrame then
            if not moneyFrame.dollarText then
                moneyFrame.dollarText = moneyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                moneyFrame.dollarText:SetPoint("BOTTOMLEFT", itemNameFrame, "TOPLEFT", 15, -2)
            end
            moneyFrame.dollarText:SetText(dollarText)
            moneyFrame.dollarText:Show()
        end
    end
end

-- Function to clear old dollar texts
local function ClearOldDollarTexts()
    for index = 1, MERCHANT_ITEMS_PER_PAGE do
        local moneyFrame = _G["MerchantItem" .. index .. "MoneyFrame"]
        if moneyFrame and moneyFrame.dollarText then
            moneyFrame.dollarText:Hide()
        end
    end
end

-- Function to handle the merchant frame update event
local function OnMerchantFrameUpdate()
    if not GoldtoCashValueDB.enableVendorFeature then
        ClearOldDollarTexts()
        return
    end
    ClearOldDollarTexts()
    local numItems = GetMerchantNumItems()
    for index = 1, MERCHANT_ITEMS_PER_PAGE do
        local itemPrice = select(3, GetMerchantItemInfo(index + ((MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE)))
        if itemPrice and itemPrice >= 10000 then
            local tokenDollarValue = ConvertToDollarValue(itemPrice)
            local dollarText = string.format("$%.2f", tokenDollarValue)
            UpdateVendorItemDollarText(index, dollarText)
        end
    end
end

-- Function to handle merchant show event
local function OnMerchantShow()
    if not GoldtoCashValueDB.enableVendorFeature then
        ClearOldDollarTexts()
        return
    end
    OnMerchantFrameUpdate()
end

-- Create a frame to periodically check the merchant page and update
local updateFrame = CreateFrame("Frame")
local lastPage = nil
local elapsedSinceLastUpdate = 0
updateFrame:SetScript("OnUpdate", function(self, elapsed)
    elapsedSinceLastUpdate = elapsedSinceLastUpdate + elapsed
    if elapsedSinceLastUpdate >= 0.3 then
        elapsedSinceLastUpdate = 0
        if MerchantFrame:IsVisible() then
            local currentPage = MerchantFrame.page
            if currentPage ~= lastPage then
                lastPage = currentPage
                OnMerchantFrameUpdate()
            end
        end
    end
end)

-- Event handler for merchant frame events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "MERCHANT_SHOW" then
        OnMerchantShow()
        lastPage = MerchantFrame.page
    end
end)
