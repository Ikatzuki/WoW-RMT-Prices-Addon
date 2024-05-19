-- Function to modify item tooltips
local function OnTooltipSetItem(tooltip, ...)
    local name, link = tooltip:GetItem()
    if link then
        local _, _, _, _, _, _, _, _, _, _, sellPrice = GetItemInfo(link)
        if sellPrice and sellPrice > 0 then
            local goldValue = sellPrice / 10000
            local tokenDollarValue = (goldValue / RMTGoldPricesDB.wowTokenPrice) * 20
            local illegalDollarValue = (goldValue / 10000) * RMTGoldPricesDB.illegalGoldPrice

            tooltip:AddLine(string.format("|cFFFFFFFFVendor: |cFFFFD700($%.2f / $%.2f)|r", tokenDollarValue, illegalDollarValue))
            tooltip:Show()
        end
    end
end

-- Hook the tooltip to add dollar values
GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
ItemRefTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
