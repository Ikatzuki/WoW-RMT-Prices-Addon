-- Initialize variables specific to chat functionality
local processedMessages = {}

-- Function to handle chat messages
local function OnChatMessage(self, event, msg, author, ...)
    if not GoldtoCashValueDB or not GoldtoCashValueDB.enableChatFeature then
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

    -- Pattern to find any item link
    local itemLinkPattern = "|c%x+|Hitem:.-|h.-|h|r"
    -- Pattern to find gold amounts (with suffixes g/G or k/K) with boundaries
    local goldPattern = "(%f[%a%d][%d,%.]+[gGkK]%f[%A])"

    -- Function to append currency to gold amount
    local function appendCurrencyToGoldAmount(goldAmount)
        -- Remove commas and dots
        local cleanedGoldAmount = goldAmount:gsub("[,%.]", "")
        local number, suffix = cleanedGoldAmount:match("(%d+)([gGkK])")
        if number and suffix then
            return GoldtoCashValue.AppendCurrency(number, suffix, "")
        end
        return goldAmount
    end

    -- Function to handle modification of message segments
    local function modifySegment(segment)
        local modified = false
        local newSegment = segment:gsub(goldPattern, function(goldAmount)
            if goldAmount then
                local modifiedGoldAmount = appendCurrencyToGoldAmount(goldAmount)
                modified = true
                return modifiedGoldAmount
            end
            return goldAmount
        end)
        return newSegment, modified
    end

    -- Check each part for item links and gold amounts
    local newMsg = ""
    local startIndex = 1
    local hasItemLink = msg:find(itemLinkPattern) ~= nil
    local modified = false

    while startIndex <= #msg do
        local segmentStart, segmentEnd, itemLink = msg:find("(" .. itemLinkPattern .. ")", startIndex)
        if not segmentStart then
            local remainingSegment = msg:sub(startIndex)
            local modifiedSegment, wasModified = modifySegment(remainingSegment)
            newMsg = newMsg .. modifiedSegment
            modified = modified or wasModified
            break
        else
            local segmentBefore = msg:sub(startIndex, segmentStart - 1)
            local modifiedSegment, wasModified = modifySegment(segmentBefore)
            newMsg = newMsg .. modifiedSegment .. itemLink
            modified = modified or wasModified

            -- Continue parsing after the item link
            startIndex = segmentEnd + 1
        end
    end

    -- Return the modified message if it was changed
    if modified then
        return false, newMsg, author, ...
    end

    -- Return false to allow other addons to process the message
    return false
end

-- Function to append the equivalent dollar value
function GoldtoCashValue.AppendCurrency(number, suffix, post)
    local num = tonumber(number)
    local tokenDollarValue

    if suffix == "g" or suffix == "G" then
        tokenDollarValue = (num / GoldtoCashValueDB.wowTokenPrice) * 20
    elseif suffix == "k" or suffix == "K" then
        tokenDollarValue = (num * 1000 / GoldtoCashValueDB.wowTokenPrice) * 20
    end

    return number .. suffix .. string.format(" |cFFFFD700($%.2f)|r", tokenDollarValue) .. post
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