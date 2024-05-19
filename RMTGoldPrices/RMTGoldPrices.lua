local function InitializeDatabase()
    if not RMTGoldPricesDB then
        RMTGoldPricesDB = {
            wowTokenPrice = 100000, -- Default WoW Token price in gold
            illegalGoldPrice = 20, -- Default illegal gold price per 10k in dollars
            debugEnabled = false -- Default debug option
        }
    end
end

local function OnAddonLoaded(event, name)
    if name == "RMTGoldPrices" then
        InitializeDatabase()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", OnAddonLoaded)
