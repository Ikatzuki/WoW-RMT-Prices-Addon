-- Function to convert vendor price to dollar value
local function ConvertToDollarValue(vendorPrice)
    local goldValue = vendorPrice / 10000
    local tokenDollarValue = (goldValue / RMTGoldPricesDB.wowTokenPrice) * 20
    print("ConvertToDollarValue:", vendorPrice, "->", tokenDollarValue) -- Debug
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
                print("Creating dollarText for item:", index) -- Debug
            end
            moneyFrame.dollarText:SetText(dollarText)
            moneyFrame.dollarText:Show()
            print("Updating dollarText for item:", index, dollarText) -- Debug
        else
            print("MoneyFrame not found for item:", index) -- Debug
        end
    else
        print("ItemNameFrame not found for item:", index) -- Debug
    end
end

-- Function to clear old dollar texts
local function ClearOldDollarTexts()
    for index = 1, MERCHANT_ITEMS_PER_PAGE do
        local moneyFrame = _G["MerchantItem" .. index .. "MoneyFrame"]
        if moneyFrame and moneyFrame.dollarText then
            moneyFrame.dollarText:Hide()
            print("Hiding old dollarText for item:", index) -- Debug
        else
            print("No old dollarText to hide for item:", index) -- Debug
        end
    end
end

-- Function to handle the merchant frame update event
local function OnMerchantFrameUpdate()
    ClearOldDollarTexts()
    local numItems = GetMerchantNumItems()
    print("Number of merchant items:", numItems) -- Debug
    for index = 1, MERCHANT_ITEMS_PER_PAGE do
        local itemPrice = select(3, GetMerchantItemInfo(index + ((MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE)))
        if itemPrice and itemPrice > 0 then
            local tokenDollarValue = ConvertToDollarValue(itemPrice)
            local dollarText = string.format("$%.2f", tokenDollarValue)
            UpdateVendorItemDollarText(index, dollarText)
        else
            print("No item price or item price is 0 for item:", index) -- Debug
        end
    end
end

-- Function to handle merchant show event
local function OnMerchantShow()
    if not RMTGoldPricesDB.enableVendorFeature then
        print("Vendor feature disabled.") -- Debug
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
    if elapsedSinceLastUpdate >= 0.3 then -- 300 ms
        elapsedSinceLastUpdate = 0
        if MerchantFrame:IsVisible() then
            local currentPage = MerchantFrame.page
            print("Current Page:" .. currentPage)
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
    print("Event triggered:", event) -- Debug
    if event == "MERCHANT_SHOW" then
        OnMerchantShow()
        lastPage = MerchantFrame.page
    end
end)

-- Debug: Print to confirm the script is loaded
print("RMTGoldPrices: Vendor price script loaded.")
