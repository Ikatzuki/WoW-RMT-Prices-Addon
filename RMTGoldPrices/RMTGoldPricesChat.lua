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

    -- Pattern to find any item link
    local itemLinkPattern = "|c%x+|Hitem:.-|h.-|h|r"
    -- Pattern to find gold amounts (with suffixes g/G or k/K)
    local goldPattern = "(%d+[gGkK])"

    -- Function to append currency to gold amount
    local function appendCurrencyToGoldAmount(goldAmount)
        local number, suffix = goldAmount:match("(%d+)([gGkK])")
        if number and suffix then
            return RMTGoldPrices.AppendCurrency(number, suffix, "")
        end
        return goldAmount
    end

    -- Function to handle modification of message segments
    local function modifySegment(segment, hasItemLink)
        local modified = false
        local newSegment

        if hasItemLink then
            -- Allow for either a space or no space before the gold amount if there is an item link
            newSegment = segment:gsub("(" .. itemLinkPattern .. ")(%s?)(%d+[gGkK])",
                function(itemLink, space, goldAmount)
                    if goldAmount then
                        if RMTGoldPricesDB.chatDebugEnabled then
                            print("Detected item link:", itemLink)
                            print("Detected gold amount after item link:", goldAmount)
                        end
                        local modifiedGoldAmount = appendCurrencyToGoldAmount(goldAmount)
                        modified = true
                        return itemLink .. space .. modifiedGoldAmount
                    end
                    return itemLink .. (goldAmount or "")
                end)
        else
            -- Allow spaces before and after the gold amount if there is no item link
            newSegment = segment:gsub("(%s)(%d+[gGkK])(%s?)", function(space, goldAmount, trailingSpace)
                if goldAmount then
                    if RMTGoldPricesDB.chatDebugEnabled then
                        print("Detected standalone gold amount:", space .. goldAmount)
                    end
                    local modifiedGoldAmount = appendCurrencyToGoldAmount(goldAmount)
                    modified = true
                    return space .. modifiedGoldAmount .. trailingSpace
                end
                return space .. goldAmount .. trailingSpace
            end)

            -- Handle cases where gold amount is at the end of the segment without trailing spaces
            if not modified then
                newSegment = segment:gsub("(%d+[gGkK])$", function(goldAmount)
                    if goldAmount then
                        if RMTGoldPricesDB.chatDebugEnabled then
                            print("Detected gold amount at the end of the segment:", goldAmount)
                        end
                        local modifiedGoldAmount = appendCurrencyToGoldAmount(goldAmount)
                        modified = true
                        return modifiedGoldAmount
                    end
                    return goldAmount
                end)
            end
        end

        if RMTGoldPricesDB.chatDebugEnabled and not modified then
            print("No modifications made to segment:", segment)
        end

        return newSegment
    end

    -- Check each part for item links and gold amounts
    local newMsg = ""
    local startIndex = 1
    local hasItemLink = msg:find(itemLinkPattern) ~= nil

    if RMTGoldPricesDB.chatDebugEnabled then
        print("Has item link:", hasItemLink)
    end

    while startIndex <= #msg do
        local segmentStart, segmentEnd, itemLink = msg:find("(" .. itemLinkPattern .. ")", startIndex)
        if not segmentStart then
            local remainingSegment = msg:sub(startIndex)
            if RMTGoldPricesDB.chatDebugEnabled then
                print("Remaining segment before modification:", remainingSegment)
            end
            newMsg = newMsg .. modifySegment(remainingSegment, hasItemLink)
            break
        else
            local segmentBefore = msg:sub(startIndex, segmentStart - 1)
            if RMTGoldPricesDB.chatDebugEnabled then
                print("Segment before item link:", segmentBefore)
                print("Detected item link:", itemLink)
            end
            newMsg = newMsg .. modifySegment(segmentBefore, hasItemLink) .. itemLink

            -- Check for gold amount right after the item link with or without space
            local afterItemLink = msg:sub(segmentEnd + 1)
            local goldAmountWithSpace = afterItemLink:match("^%s(%d+[gGkK])")
            local goldAmountNoSpace = afterItemLink:match("^(%d+[gGkK])")

            if goldAmountWithSpace then
                if RMTGoldPricesDB.chatDebugEnabled then
                    print("Detected gold amount immediately after item link with space:", goldAmountWithSpace)
                end
                local modifiedGoldAmount = appendCurrencyToGoldAmount(goldAmountWithSpace)
                newMsg = newMsg .. " " .. modifiedGoldAmount
                startIndex = segmentEnd + #goldAmountWithSpace + 2
            elseif goldAmountNoSpace then
                if RMTGoldPricesDB.chatDebugEnabled then
                    print("Detected gold amount immediately after item link without space:", goldAmountNoSpace)
                end
                local modifiedGoldAmount = appendCurrencyToGoldAmount(goldAmountNoSpace)
                newMsg = newMsg .. modifiedGoldAmount
                startIndex = segmentEnd + #goldAmountNoSpace + 1
            else
                startIndex = segmentEnd + 1
            end
        end
    end

    -- Return the modified message if it was changed
    if newMsg ~= msg then
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
