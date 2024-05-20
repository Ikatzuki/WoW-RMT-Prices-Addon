-- Function to add dollar values to the vendor price line
local function AddDollarValueToVendorPrice(tooltipFrame, vendorPrice, countString)
    if vendorPrice > 0 then
        local goldValue = vendorPrice / 10000
        local tokenDollarValue = (goldValue / GoldtoCashValueDB.wowTokenPrice) * 20

        local dollarText = string.format(" ($%.2f)", tokenDollarValue)

        -- Find the vendor price line and append the dollar value
        for i = 1, tooltipFrame:NumLines() do
            local leftLine = _G[tooltipFrame:GetName() .. "TextLeft" .. i]
            local rightLine = _G[tooltipFrame:GetName() .. "TextRight" .. i]
            if leftLine and rightLine and leftLine:GetText() and leftLine:GetText():find("Vendor") then
                rightLine:SetText(rightLine:GetText() .. dollarText)
                tooltipFrame:Show()
                return
            end
        end
    end
end

-- Function to add dollar values to the auction price line
local function AddDollarValueToAuctionPrice(tooltipFrame, auctionPrice, countString, cannotAuction)
    if auctionPrice and not cannotAuction then
        local goldValue = auctionPrice / 10000
        local tokenDollarValue = (goldValue / GoldtoCashValueDB.wowTokenPrice) * 20

        local dollarText = string.format(" ($%.2f)", tokenDollarValue)

        -- Find the auction price line and append the dollar value
        for i = 1, tooltipFrame:NumLines() do
            local leftLine = _G[tooltipFrame:GetName() .. "TextLeft" .. i]
            local rightLine = _G[tooltipFrame:GetName() .. "TextRight" .. i]
            if leftLine and rightLine and leftLine:GetText() and leftLine:GetText():find("Auction") then
                rightLine:SetText(rightLine:GetText() .. dollarText)
                tooltipFrame:Show()
                return
            end
        end
    end
end

-- Function to modify item tooltips for non-Auctionator case
local function OnTooltipSetItem(tooltip, ...)
    local name, link = tooltip:GetItem()
    if link then
        local _, _, _, _, _, _, _, _, _, _, sellPrice = GetItemInfo(link)
        if sellPrice and sellPrice > 0 then
            local goldValue = sellPrice / 10000
            local tokenDollarValue = (goldValue / GoldtoCashValueDB.wowTokenPrice) * 20

            local dollarText = string.format("|cFFFFFFFFVendor: |cFFFFD700($%.2f)|r", tokenDollarValue)

            -- Add the dollar text below the regular vendor price using AddLine
            tooltip:AddLine(dollarText)
            tooltip:Show()
        end
    end
end

-- Hook into Auctionator's AddVendorTip and AddAuctionTip functions if Auctionator is loaded
if IsAddOnLoaded("Auctionator") then

    local originalAddVendorTip = Auctionator.Tooltip.AddVendorTip
    Auctionator.Tooltip.AddVendorTip = function(tooltipFrame, vendorPrice, countString)
        if not GoldtoCashValueDB.enableTooltipFeature then
            return
        end
        -- Call the original function
        originalAddVendorTip(tooltipFrame, vendorPrice, countString)

        -- Add our custom dollar value to the vendor price
        AddDollarValueToVendorPrice(tooltipFrame, vendorPrice, countString)
    end

    local originalAddAuctionTip = Auctionator.Tooltip.AddAuctionTip
    Auctionator.Tooltip.AddAuctionTip = function(tooltipFrame, auctionPrice, countString, cannotAuction)
        if not GoldtoCashValueDB.enableTooltipFeature then
            return
        end
        -- Call the original function
        originalAddAuctionTip(tooltipFrame, auctionPrice, countString, cannotAuction)

        -- Add our custom dollar value to the auction price
        AddDollarValueToAuctionPrice(tooltipFrame, auctionPrice, countString, cannotAuction)
    end
else

    -- Hook the tooltip to add dollar values for non-Auctionator case
    GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
    ItemRefTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
end
