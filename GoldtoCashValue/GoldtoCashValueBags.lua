-- Initialize the table for the new module
GoldtoCashValueBags = {}

-- Function to convert gold to dollar value
local function ConvertGoldToDollar(goldAmount)
    local tokenDollarValue = (goldAmount / GoldtoCashValueDB.wowTokenPrice) * 20
    return tokenDollarValue
end

-- Function to update the player's gold display with dollar value
local function UpdateGoldDisplay()
    local playerGold = GetMoney() / 10000 -- Convert from copper to gold
    local dollarValue = ConvertGoldToDollar(playerGold)

    local goldTextFrame
    local dollarText

    if IsAddOnLoaded("ElvUI") and _G["ElvUI_ContainerFrame"] then
        -- ElvUI is loaded and ElvUI_ContainerFrame exists, use ElvUI_ContainerFrame.goldText
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
    elseif IsAddOnLoaded("Bagnon") then
        -- Bagnon is loaded, use Bagnon frame
        goldTextFrame = _G["BagnonMoneyFrame1GoldButtonText"]
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
        if not GoldtoCashValueDB.enableBagsFeature then
            return
        end
        UpdateGoldDisplay()
    elseif event == "PLAYER_LOGIN" then
        -- Delay the update by 5 seconds to ensure WoW Token price is fetched
        C_Timer.After(5, function()
            if not GoldtoCashValueDB.enableBagsFeature then
                return
            end
            UpdateGoldDisplay()
        end)
    end
end

-- Create a frame to register events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_MONEY")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", OnEvent)
