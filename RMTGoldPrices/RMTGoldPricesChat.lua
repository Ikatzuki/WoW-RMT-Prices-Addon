-- Initialize variables specific to chat functionality
local processedMessages = {}

-- Function to handle chat messages
local function OnChatMessage(self, event, msg, author, ...)
    if RMTGoldPricesDB.isPaused then
        return false
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

    -- Pattern to find any number followed by "g", "G", "k", or "K" followed by a non-alphanumeric character or end of string,
    -- ensuring no letters before the number
    local pattern = "(%f[%a%d]%d+[gGkK]%f[%A%d])"

    -- Debug: print the original message to the console
    if RMTGoldPricesDB.debugEnabled then
        print("Original message:", msg)
    end

    -- Check if the message contains the pattern
    local containsPattern = msg:find(pattern)

    if containsPattern then
        if RMTGoldPricesDB.debugEnabled then
            print("Pattern '%d+[gGkK]' found in message.")
        end

        -- Replace matches in the message
        local success, newMsg = pcall(function()
            return msg:gsub(pattern, function(numberWithSuffix)
                local pre, number, suffix, post = msg:match("(.-)(%d+)([gGkK])(%f[%A%d])")
                -- Ensure there are no letters immediately before the number + g/k
                if pre and not pre:match("%a$") then
                    return pre .. RMTGoldPrices.AppendCurrency(number, suffix, post)
                else
                    return numberWithSuffix
                end
            end)
        end)

        if success then
            -- Debug: print the new message to the console
            if RMTGoldPricesDB.debugEnabled then
                print("Modified message:", newMsg)
            end

            -- Return the modified message
            return false, newMsg, author, ...
        else
            -- In case of error, return the original message unmodified
            if RMTGoldPricesDB.debugEnabled then
                print("Error processing message:", newMsg)
            end
            return false, msg, author, ...
        end
    else
        if RMTGoldPricesDB.debugEnabled then
            print("Pattern '%d+[gGkK]' not found in message.")
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
