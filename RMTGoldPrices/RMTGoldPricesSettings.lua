-- Create a global table for the addon
RMTGoldPrices = {}

-- Default values for saved variables
RMTGoldPrices.defaultSettings = {
    wowTokenPrice = 6138, -- Default WoW Token price in gold
    illegalGoldPrice = 15, -- Default illegal gold price for $20
    debugEnabled = false -- Default debug state
}

-- Function to load saved variables
function RMTGoldPrices.LoadSettings()
    if not RMTGoldPricesDB then
        RMTGoldPricesDB = RMTGoldPrices.defaultSettings
    else
        for k, v in pairs(RMTGoldPrices.defaultSettings) do
            if RMTGoldPricesDB[k] == nil then
                RMTGoldPricesDB[k] = v
            end
        end
    end
end

-- Function to append the equivalent dollar values
function RMTGoldPrices.AppendCurrency(number, suffix, post)
    local num = tonumber(number)
    local tokenDollarValue, illegalDollarValue

    if suffix == "g" or suffix == "G" then
        tokenDollarValue = (num / RMTGoldPricesDB.wowTokenPrice) * 20
        illegalDollarValue = (num / 10000) * RMTGoldPricesDB.illegalGoldPrice
    elseif suffix == "k" or suffix == "K" then
        tokenDollarValue = (num * 1000 / RMTGoldPricesDB.wowTokenPrice) * 20
        illegalDollarValue = (num * RMTGoldPricesDB.illegalGoldPrice / 10)
    end

    return number .. suffix .. string.format(" |cFFFFD700($%.2f / $%.2f)|r", tokenDollarValue, illegalDollarValue) ..
               post
end

-- Function to toggle pause state
function RMTGoldPrices.TogglePause()
    RMTGoldPrices.isPaused = not RMTGoldPrices.isPaused
    if RMTGoldPrices.isPaused then
        print("RMTGoldPrices addon paused.")
    else
        print("RMTGoldPrices addon resumed.")
    end
end

-- Function to resume the addon
function RMTGoldPrices.ResumeAddon()
    if RMTGoldPrices.isPaused then
        RMTGoldPrices.isPaused = false
        print("RMTGoldPrices addon resumed.")
    else
        print("RMTGoldPrices addon is already running.")
    end
end

-- Create the options window
function RMTGoldPrices.CreateOptionsWindow()
    local optionsFrame = CreateFrame("Frame", "RMTGoldPricesOptionsFrame", UIParent, "BasicFrameTemplateWithInset")
    optionsFrame:SetSize(300, 170) -- width, height
    optionsFrame:SetPoint("CENTER") -- position at the center of the screen
    optionsFrame:SetMovable(true)
    optionsFrame:EnableMouse(true)
    optionsFrame:RegisterForDrag("LeftButton")
    optionsFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    optionsFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    optionsFrame:Hide()

    -- Title text
    local title = optionsFrame:CreateFontString(nil, "OVERLAY")
    title:SetFontObject("GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("RMTGoldPrices Options")

    -- WoW Token Price text
    local tokenLabel = optionsFrame:CreateFontString(nil, "OVERLAY")
    tokenLabel:SetFontObject("GameFontNormal")
    tokenLabel:SetPoint("TOPLEFT", 10, -40)
    tokenLabel:SetText("WoW Token Price:")

    -- WoW Token Price input box
    local tokenInput = CreateFrame("EditBox", nil, optionsFrame, "InputBoxTemplate")
    tokenInput:SetSize(50, 20) -- width, height
    tokenInput:SetPoint("LEFT", tokenLabel, "RIGHT", 10, 0)
    tokenInput:SetAutoFocus(false)
    tokenInput:SetText(tostring(RMTGoldPricesDB.wowTokenPrice))

    -- Illegal Gold Price text
    local illegalLabel = optionsFrame:CreateFontString(nil, "OVERLAY")
    illegalLabel:SetFontObject("GameFontNormal")
    illegalLabel:SetPoint("TOPLEFT", 10, -70)
    illegalLabel:SetText("Price per 10k Illegal Gold ($):")

    -- Illegal Gold Price input box
    local illegalInput = CreateFrame("EditBox", nil, optionsFrame, "InputBoxTemplate")
    illegalInput:SetSize(50, 20) -- width, height
    illegalInput:SetPoint("LEFT", illegalLabel, "RIGHT", 10, 0)
    illegalInput:SetAutoFocus(false)
    illegalInput:SetText(tostring(RMTGoldPricesDB.illegalGoldPrice))

    -- Debug Enabled text
    local debugLabel = optionsFrame:CreateFontString(nil, "OVERLAY")
    debugLabel:SetFontObject("GameFontNormal")
    debugLabel:SetPoint("TOPLEFT", 10, -100)
    debugLabel:SetText("Enable Debug:")

    -- Debug Enabled checkbox
    local debugCheckbox = CreateFrame("CheckButton", nil, optionsFrame, "ChatConfigCheckButtonTemplate")
    debugCheckbox:SetPoint("LEFT", debugLabel, "RIGHT", 10, 0)
    debugCheckbox:SetChecked(RMTGoldPricesDB.debugEnabled)

    -- Save button
    local saveButton = CreateFrame("Button", nil, optionsFrame, "GameMenuButtonTemplate")
    saveButton:SetSize(80, 30) -- width, height
    saveButton:SetPoint("BOTTOM", 0, 10)
    saveButton:SetText("Save")
    saveButton:SetNormalFontObject("GameFontNormalLarge")
    saveButton:SetHighlightFontObject("GameFontHighlightLarge")

    saveButton:SetScript("OnClick", function()
        local newTokenPrice = tonumber(tokenInput:GetText())
        local newIllegalPrice = tonumber(illegalInput:GetText())
        local newDebugEnabled = debugCheckbox:GetChecked()

        if newTokenPrice and newIllegalPrice then
            RMTGoldPricesDB.wowTokenPrice = newTokenPrice
            RMTGoldPricesDB.illegalGoldPrice = newIllegalPrice
            RMTGoldPricesDB.debugEnabled = newDebugEnabled
            print("RMTGoldPrices: Prices updated.")
            print("WoW Token Price: " .. RMTGoldPricesDB.wowTokenPrice)
            print("Price per 10k Illegal Gold: $" .. RMTGoldPricesDB.illegalGoldPrice)
            print("Debug enabled: " .. tostring(RMTGoldPricesDB.debugEnabled))
        else
            print("RMTGoldPrices: Invalid input. Please enter valid numbers.")
        end

        optionsFrame:Hide()
    end)
end

-- Slash command to show options window, toggle pause state, and resume the addon
SLASH_RGP1 = "/rgp"
SlashCmdList["RGP"] = function(msg)
    if msg == "options" then
        if not RMTGoldPricesOptionsFrame then
            RMTGoldPrices.CreateOptionsWindow()
        end
        RMTGoldPricesOptionsFrame:Show()
    elseif msg == "pause" then
        RMTGoldPrices.TogglePause()
    elseif msg == "resume" then
        RMTGoldPrices.ResumeAddon()
    else
        print(
            "RMTGoldPrices: Unknown command. Use '/rgp options' to open the options window, '/rgp pause' to toggle pause, or '/rgp resume' to resume.")
    end
end

-- Load settings when the addon is loaded
RMTGoldPrices.LoadSettings()
