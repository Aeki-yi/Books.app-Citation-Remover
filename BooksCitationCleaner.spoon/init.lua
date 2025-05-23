-- 【Books.app "Copyright Info Remover" Hammerspoon Script】 ===============================
-- This script is used to optimize copy in Books.app, removing the redundant content about excerption and copyright.
-- The script listens to the ⌘ + C key event, and will automatically intercept the excerption content when Books.app is in the foreground.
booksAppNames = {
    ["Books"] = true,
    ["图书"] = true,
    ["ブック"] = true,
    ["書籍"] = false, -- 設為true啟用繁體中文
    -- 由於Books.app下繁體中文的引號與簡體和其他語言不同，請找到processSelectedText函數並根據說明修改其下的引號變量

    -- If you are using a system language other than listed above
    -- Please add their corresponding app titles here,
    -- and modify the list of <excerptMarkers> accordingly.
}


bookeventtap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
    local flags = event:getFlags()
    local keyCode = event:getKeyCode()
    -- If is ⌘ + C
    if flags.cmd and keyCode == hs.keycodes.map["c"] then
        local frontApp = hs.application.frontmostApplication():name()
        if booksAppNames[frontApp] then
            -- Wait a sec
            hs.timer.doAfter(0.25, function()
                local content = hs.pasteboard.getContents()
                if content and content ~= "" then
                    local result = processSelectedText(content)
                    if result and result ~= content then
                        hs.pasteboard.setContents(result)
                        hs.alert.show("[Copied]\nExcerption Marks Removed!") -- You may comment this line (debugger)
                    end
                end
            end)
        end
    end
    return false
end)
bookeventtap:start()


excerptMarkers = {
    {"Excerpt From","This material may be protected by copyright"},
    {"摘录来自","可能受版权保护"},
    -- {"摘錄自","可能受到著作權的保護"}, -- 繁體中文用戶請uncomment這行
    {"抜粋","この作品は著作権で保護されている可能性があります"},
}
-- Triggers mark removal if the (text) contains any of the excerptMarkers
function containsExcerptMarker(text)
    for _, group in ipairs(excerptMarkers) do
        local allFound = true
        for _, keyword in ipairs(group) do
            if not text:find(keyword, 1, true) then
                allFound = false
                break
            end
        end
        if allFound then
            return true
        end
    end
    return false
end

function processSelectedText(text)
    if not containsExcerptMarker(text) then
        
        -- hs.alert.show("Excerption Marks Not Found!") -- You may comment this line (debugger)
        
        return text
    end
    local lines = {}
    for line in text:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    if #lines == 0 then return nil end

    --【Modify the quote marks according to your language environment】--
    local leftQuote = "“" 
    local rightQuote = "”"
    -- local leftQuote = "「"
    -- local rightQuote = "」"

    -- 如果你使用的是繁體中文，請將上面兩行的引號替換為下面的引號。
    -- 注意：兩組符號系統不能同時運作！必須將其中一組註釋掉！

    local firstLine = lines[1]
    local firstCharEnd = utf8.offset(firstLine, 2)
    if firstCharEnd and (firstLine:sub(1, firstCharEnd - 1) == leftQuote) then 
        lines[1] = firstLine:sub(firstCharEnd)
    end
    

    -- Find the last line that contains the right quote
    local lastQuoteLine = nil
    local lastQuoteIndex = nil
    for i, line in ipairs(lines) do
        local pos = nil
        local searchStart = 1
        while true do
            local found = line:find(rightQuote, searchStart, true)
            if not found then break end
            pos = found
            searchStart = found + 1
        end
        if pos then
            lastQuoteLine = i
            lastQuoteIndex = pos
        end
    end

    if lastQuoteLine then
        local resultLines = {}
        for i = 1, lastQuoteLine - 1 do
            table.insert(resultLines, lines[i])
        end
        table.insert(resultLines, lines[lastQuoteLine]:sub(1, lastQuoteIndex - 1))
        return table.concat(resultLines, "\n")
    else
        return nil
    end
end
-- 【Books.app Excerption Mark Remover】END ===============================