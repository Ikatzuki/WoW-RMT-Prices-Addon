local function OnAddonLoaded(event, name)
    if name == "RMTGoldPrices" then
        -- Load settings when the addon is loaded
        RMTGoldPrices.LoadSettings()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", OnAddonLoaded)
