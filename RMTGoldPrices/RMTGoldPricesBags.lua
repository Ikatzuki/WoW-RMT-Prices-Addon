-- Initialize the table for the new module
RMTGoldPricesBags = {}

-- Function to convert gold to dollar value
local function ConvertGoldToDollar(goldAmount)
    local tokenDollarValue = (goldAmount / RMTGoldPricesDB.wowTokenPrice) * 20
    return tokenDollarValue
end

-- Function to update the player's gold display with dollar value
local function UpdateGoldDisplay()
    local playerGold = GetMoney() / 10000 -- Convert from copper to gold
    local dollarValue = ConvertGoldToDollar(playerGold)

    local goldTextFrame
    local dollarText

    if IsAddOnLoaded("ElvUI") then
        -- ElvUI is loaded, use ElvUI_ContainerFrame.goldText
        goldTextFrame = _G["ElvUI_ContainerFrame"].goldText
        if not goldTextFrame then
            return
        end

        -- Create or update the dollar text
        if not goldTextFrame.dollarText then
            dollarText = goldTextFrame:GetParent():CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            dollarText:SetPoint("RIGHT", goldTextFrame, "LEFT", -2, 0)
            goldTextFrame.dollarText = dollarText
        else
            dollarText = goldTextFrame.dollarText
        end
    else
        -- Default UI, use ContainerFrame1MoneyFrameGoldButtonText
        goldTextFrame = _G["ContainerFrame1MoneyFrameGoldButtonText"]
        if not goldTextFrame then
            return
        end

        -- Create or update the dollar text
        if not goldTextFrame.dollarText then
            dollarText = goldTextFrame:GetParent():CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            dollarText:SetPoint("RIGHT", goldTextFrame, "LEFT", -2, 0)
            goldTextFrame.dollarText = dollarText
        else
            dollarText = goldTextFrame.dollarText
        end
    end

    if dollarText then
        -- Set the dollar text
        dollarText:SetText(string.format("|cFFFFD700($%.2f)|r", dollarValue))
    end
end

-- Event handler function
local function OnEvent(self, event, ...)
    if event == "PLAYER_MONEY" or event == "PLAYER_ENTERING_WORLD" then
        UpdateGoldDisplay()
    end
end

-- Create a frame to register events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_MONEY")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", OnEvent)