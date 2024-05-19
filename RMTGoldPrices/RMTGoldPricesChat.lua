-- Initialize variables specific to chat functionality
local processedMessages = {}

-- Function to handle chat messages
local function OnChatMessage(self, event, msg, author, ...)
    if not RMTGoldPricesDB or not RMTGoldPricesDB.enableChatFeature then
        return
    end

    -- Use the unique ID for each message to avoid duplicates
    local msgId = msg .. author

    -- Check if the message has already been processed
    if processedMessages[msgId] then
        return false
    end

    -- Mark this message as processed
    processedMessages[msgId] = true

    -- Clear old entries in the processedMessages table
    C_Timer.After(1, function()
        processedMessages[msgId] = nil
    end)

    -- Debug: print the original message to the console
    if RMTGoldPricesDB.chatDebugEnabled then
        print("Original message:", msg)
    end

    -- Pattern to find any item link followed by a gold amount
    local itemLinkPattern = "|c%x+|Hitem:.-|h.-|h|r"
    local goldPattern = "(%d+[gGkK])"

    -- Function to append currency to gold amount
    local function appendCurrencyToGoldAmount(goldAmount)
        local number, suffix = goldAmount:match("(%d+)([gGkK])")
        if number and suffix then
            return RMTGoldPrices.AppendCurrency(number, suffix, "")
        end
        return goldAmount
    end

    -- Check each part for item links and gold amounts
    local modified = false
    local newMsg = msg:gsub("(" .. itemLinkPattern .. ")( ?%d+[gGkK])", function(itemLink, goldAmount)
        if goldAmount then
            if RMTGoldPricesDB.chatDebugEnabled then
                print("Detected item link:", itemLink)
                print("Detected gold amount:", goldAmount)
            end
            local modifiedGoldAmount = appendCurrencyToGoldAmount(goldAmount)
            modified = true
            return itemLink .. " " .. modifiedGoldAmount
        end
        return itemLink .. (goldAmount or "")
    end)

    -- If no item link was found, check for gold amounts directly in the message
    if not modified then
        newMsg = msg:gsub(goldPattern, function(goldAmount)
            local pre, number, suffix, post = msg:match("(.-)(%d+)([gGkK])(.*)")
            if pre and number and suffix then
                if pre == "" or pre:match("|c%x+|Hitem:.-|h.-|h|r$") then
                    if RMTGoldPricesDB.chatDebugEnabled then
                        print("Detected gold amount directly:", goldAmount)
                    end
                    modified = true
                    return pre .. appendCurrencyToGoldAmount(goldAmount) .. post
                else
                    return goldAmount
                end
            end
            return goldAmount
        end)
    end

    -- Return the modified message if it was changed
    if modified then
        -- Debug: print the new message to the console
        if RMTGoldPricesDB.chatDebugEnabled then
            print("Modified message:", newMsg)
        end

        return false, newMsg, author, ...
    else
        if RMTGoldPricesDB.chatDebugEnabled then
            print("Pattern not found or no modifications needed.")
        end
    end

    -- Return false to allow other addons to process the message
    return false
end

-- Function to append the equivalent dollar value
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

-- Add the message filter to modify chat messages
ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", OnChatMessage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", OnChatMessage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", OnChatMessage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", OnChatMessage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", OnChatMessage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", OnChatMessage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", OnChatMessage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", OnChatMessage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", OnChatMessage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND", OnChatMessage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND_LEADER", OnChatMessage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", OnChatMessage)
ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", OnChatMessage)
