local version = "0.9.3"

--controls all print outputs
local gVerb = true

local turtleComplie = peripheral.find("wand") ~= nil

local github = require("github")

local function vPrint(s)
    if gVerb == true then
        print(s)
    end
end

local function getRunningPath()
    local runningProgram = shell.getRunningProgram()
    local programName = fs.getName(runningProgram)
    return runningProgram:sub(1, #runningProgram - #programName)
end

local hexicon = require("hexicon")

--load symbol-registry.json
local srFile
local srFileName = "symbol-registry.json"
if fs.exists(getRunningPath() .. srFileName) then
    srFile = fs.open(getRunningPath() .. srFileName, "r")
else
    srFile = fs.open("/disk/hexlator/" .. srFileName, "r")
end
if not srFile then
    vPrint("Could not find symbol-registry.json in the current directory")
    return
end
local srRaw = textutils.unserialiseJSON(srFile.readAll())

-- Strips all non-alphanumerics plus underscores
local function stripString(iString)
    local rString, _ = string.gsub(iString, " ", "_")
    rString, _ = string.gsub(rString, "-", "n")
    rString, _ = string.gsub(rString, "+", "p")
    rString, _ = string.gsub(rString, "[^%w_]+", "")
    return rString
end

local function stripWhitespaces(s)
    return string.gsub(s, "%s+", "")
end

--load raw symbol registry translation table
local symbolRegistry = {}
for k, v in pairs(srRaw) do
    local sName = k  --stripString(k)
    symbolRegistry[sName] = {
        ["angles"] = v["pattern"],
        ["startDir"] = v["direction"],
    }
    if turtleComplie then
        symbolRegistry[sName]["iota$serde"] = "hextweaks:pattern"
    end
end
symbolRegistry["{"] = symbolRegistry["Introspection"]
symbolRegistry["}"] = symbolRegistry["Retrospection"]
symbolRegistry[">>"] = symbolRegistry["Flock's Disintegration"]
symbolRegistry["Bookkeeper's Gambit"] = nil
symbolRegistry["Numerical Reflection"] = nil

local strippedRegistry = {}
for k, v in pairs(srRaw) do
    local sName = stripString(k)
    strippedRegistry[sName] = {
        ["angles"] = v["pattern"],
        ["startDir"] = v["direction"],
    }
    if turtleComplie then
        strippedRegistry[sName]["iota$serde"] = "hextweaks:pattern"
    end
end
strippedRegistry["{"] = strippedRegistry["Introspection"]
strippedRegistry["}"] = strippedRegistry["Retrospection"]
strippedRegistry[">>"] = strippedRegistry["Flocks_Disintegration"]
strippedRegistry["Bookkeepers_Gambit"] = nil
strippedRegistry["Numerical_Reflection"] = nil

-- Given a string and start location, returns everything within a balanced set of parentheses, as well
-- as the start and end locations
local function getBalancedParens(s, startLoc)
    local firstC, lastC, str = string.find(s, "(%b())", startLoc)
    return string.sub(str, 2, -2), firstC, lastC
end

local function getColonParens(s, startLoc)
    local firstC, lastC, str = string.find(s, ":%s*([A-Za-z0-9_%-]+)", startLoc)
    return str, firstC, lastC
end

-- Given a string, returns a table of strings with commas as delim
local function splitCommas(str)
    local valTable = {}
    local i = 1
    for k, _ in string.gmatch(str, "([^,]+)") do
        valTable[i] = k
        i = i + 1
    end
    return valTable
end

-- All identifiers and associated functions to correctly grab and format data given the raw string and a token
local identRegistry = {
    ["@null"] = function()
        return { ["null"] = true }
    end,
    ["@garbage"] = function()
        return { ["garbage"] = true }
    end,
    ["@true"] = function()
        return true
    end,
    ["@false"] = function()
        return false
    end,
    ["@iota_type"] = function(s, token)
        local str = getBalancedParens(s, token["start"])
        return { ["iotaType"] = str }
    end,
    ["@entity_type"] = function(s, token)
        local str = getBalancedParens(s, token["start"])
        return { ["entityType"] = str }
    end,
    ["@item_type"] = function(s, token)
        local str = getBalancedParens(s, token["start"])
        local valTable = splitCommas(str)
        local bools = {
            ["true"] = true,
            ["false"] = false
        }
        local returnTable = {
            ["isItem"] = bools[stripWhitespaces(valTable[2])],
            ["itemType"] = stripWhitespaces(valTable[1]),
        }
        return returnTable
    end,
    ["@entity"] = function(s, token)
        local str = getBalancedParens(s, token["start"])
        return { ["uuid"] = str }
    end,
    ["@pattern"] = function(s, token)
        local str = getBalancedParens(s, token["start"])
        local valTable = splitCommas(str)
        local returnTable = {
            ["startDir"] = valTable[1],
            ["angles"] = valTable[2],
        }
        if turtleComplie then
            returnTable["iota$serde"] = "hextweaks:pattern"
        end
        return returnTable
    end,
    ["@gate"] = function(s, token)
        local str = getBalancedParens(s, token["start"])
        return { ["gate"] = str }
    end,
    ["@vec"] = function(s, token)
        local str = getBalancedParens(s, token["start"])
        local valTable = splitCommas(str)
        local returnTable = {
            ["x"] = tonumber(valTable[1]),
            ["y"] = tonumber(valTable[2]),
            ["z"] = tonumber(valTable[3])
        }
        if turtleComplie then
            returnTable["iota$serde"] = "hextweaks:vec3"
        end
        return returnTable
    end,
    ["@matrix"] = function(s, token)
        local str = getBalancedParens(s, token["start"])
        local valTable = splitCommas(str)
        local matrixStr = string.match(str, "%<([%-%d%s,]+)%>")
        local matrix = {}
        for k in string.gmatch(matrixStr, "%-?%d+") do
            table.insert(matrix, tonumber(k))
        end
        local returnTable = {
            ["col"] = tonumber(valTable[1]),
            ["row"] = tonumber(valTable[2]),
            ["matrix"] = matrix
        }
        return returnTable
    end,
    ["@mote"] = function(s, token)
        local str = getBalancedParens(s, token["start"])
        local valTable = splitCommas(str)
        local returnTable = {
            ["moteUuid"] = valTable[1],
            ["itemID"] = valTable[2],
            ["nexusUuid"] = valTable[3]
        }
        return returnTable
    end,
    ["@num"] = function(s, token)
        local str = getBalancedParens(s, token["start"])
        return tonumber(str)
    end,
    ['@str'] = function(s, token)
        local str = getBalancedParens(s, token["start"])
        local input = str  -- your broken string
        local fixed = {}

        local i = 1
        while i <= #input do
            local b = input:byte(i)
            if b == 0xC2 and input:byte(i+1) == 0xA7 then
                -- Skip the "Â" byte, keep only "§"
                table.insert(fixed, string.char(0xA7))
                i = i + 2
            else
                table.insert(fixed, string.char(b))
                i = i + 1
            end
        end

        local result = table.concat(fixed)
        return result
    end,
    ['@hexicon'] = function(s, token)
        local str = getBalancedParens(s, token["start"])

        local returnTable = hexicon.toHexicon(str)
        
        if turtleComplie then
            returnTable["iota$serde"] = "hextweaks:pattern"
        end
        return returnTable
    end,
    ["%["] = true,
    ["%]"] = true,
    ["Numerical Reflection"] = function(s, token)
        local str = getColonParens(s, token["start"])
        local num = tonumber(str)
        local angles
        if num >= 0 then
            angles = "aqaa"
        elseif num < 0 then
            num = num * -1
            angles = "dedd"
        end
        for i = 1, num do
            angles = angles .. "w"
        end
        local returnTable = {
            ["startDir"] = "WEST",
            ["angles"] = angles,
        }
        if turtleComplie then
            returnTable["iota$serde"] = "hextweaks:pattern"
        end
        return returnTable
    end,
    ["Bookkeeper's Gambit"] = function(s, token)
        local combos = {
            ["--"] = "w",
            ["-v"] = "ea",
            ["vv"] = "da",
            ["v-"] = "e"
        }
        local str = getColonParens(s, token["start"])
        local angles = ""
        if str == "v" then
            angles = "a"
        else
            if str:sub(1, 1) == "v" then
                angles = "a"
            end
            for i = 1, #str - 1 do
                local sub = str:sub(i, i + 1)
                angles = angles .. combos[sub]
            end
        end
        local returnTable = {
            ["startDir"] = "EAST",
            ["angles"] = angles,
        }
        if turtleComplie then
            returnTable["iota$serde"] = "hextweaks:pattern"
        end
        return returnTable
    end,
    ["Sekhmet's Gambit"] = function(s, token)
        local str = getColonParens(s, token["start"])
        local num = tonumber(str)
        local angles = "qaqdd"
        for i = 1, num do
            local dir = "q"
            if i % 2 == 0 then
                dir = "e"
            end
            angles = angles .. dir
        end
        local returnTable = {
            ["startDir"] = "WEST",
            ["angles"] = angles,
        }
        if turtleComplie then
            returnTable["iota$serde"] = "hextweaks:pattern"
        end
        return returnTable
    end,
    ["Geb's Gambit"] = function(s, token)
        local str = getColonParens(s, token["start"])
        local num = tonumber(str)
        local angles = "aaeaad"
        for i = 3, num do
            local dir = "w"
            angles = angles .. dir
        end
        local returnTable = {
            ["startDir"] = "WEST",
            ["angles"] = angles,
        }
        if turtleComplie then
            returnTable["iota$serde"] = "hextweaks:pattern"
        end
        return returnTable
    end,
    ["Nut's Gambit"] = function(s, token)
        local str = getColonParens(s, token["start"])
        local num = tonumber(str)
        local angles = "aawdde"
        for i = 3, num do
            local dir = "w"
            angles = angles .. dir
        end
        local returnTable = {
            ["startDir"] = "WEST",
            ["angles"] = angles,
        }
        if turtleComplie then
            returnTable["iota$serde"] = "hextweaks:pattern"
        end
        return returnTable
    end
}

--Index of tokens that process the overall program string, and thus have to occur before other tokenization
local stringProccessRegistry = {
    ["#file"] = function(s, token)
        local filenames = getBalancedParens(s, token["start"])
        --strips spaces and newlines out of filenames
        filenames = string.gsub(filenames, " ", "")
        filenames = string.gsub(filenames, "\n", "")
        local valTable = splitCommas(filenames)
        local insertStr = ""
        for i, fName in ipairs(valTable) do
            vPrint("Inserting " .. fName)
            local file = fs.open(fName, "r")
            local content = file.readAll()
            -- Strip line comments from string before inserting
            content = string.gsub(content, "// .-\n", "")
            file.close()
            insertStr = insertStr .. content
        end
        local firstChar = token["start"]
        local lastChar = token["end"] + #filenames + 2
        local out = s:sub(1, firstChar - 1) .. "\n" .. insertStr .. "\n" .. s:sub(lastChar + 1)

        --local debug = fs.open(getRunningPath().."debug", "w")
        --debug.write(out)
        --debug.close()

        return out
    end,
    ["#wget"] = function(s, token)
        local fileName, _, lastC1 = getBalancedParens(s, token["start"])
        local url, _, lastC2 = getBalancedParens(s, lastC1)
        --strip out newlines
        fileName = string.gsub(fileName, "\n", "")
        url = string.gsub(url, "\n", "")

        local filePath = "/" .. getRunningPath() .. "temp/" .. fileName
        if fs.exists(filePath) then
            vPrint("Deleting " .. filePath .. "...")
            shell.run("delete", filePath)
        end

        vPrint("Downloading " .. url)
        shell.run(string.format("wget %s %s", url, filePath))

        vPrint("Inserting " .. fileName)
        local file = fs.open(filePath, "r")
        local content = file.readAll()
        -- Strip line comments from string before inserting
        content = string.gsub(content, "// .-\n", "")
        file.close()

        local out = s:sub(1, token["start"] - 1) .. "\n" .. content .. "\n" .. s:sub(lastC2 + 1)

        --local debug = fs.open(getRunningPath().."debug", "w")
        --debug.write(out)
        --debug.close()

        return out
    end,
    ["#git"] = function(s, token)
        local fileName = getBalancedParens(s, token["start"])
        --strip out newlines
        fileName = string.gsub(fileName, "\n", "")

        if string.match(fileName, "^/") then
            url = spell_url:match("(.-contents)") or ""
        else
            url = ""
        end

        local file_url = url .. fileName
        vPrint("Downloading " .. file_url)

        local content = github.api_response(file_url).content

        vPrint("Inserting " .. fileName)
        -- local out =  s:sub(1,token["start"]-1).."\n"..content.."\n"..s:sub(lastC2+1)
        local firstChar = token["start"]
        local lastChar = token["end"] + #fileName
        local out = s:sub(1, firstChar - 1) .. "\n" .. content .. "\n" .. s:sub(lastChar + 1)

        --local debug = fs.open(getRunningPath().."debug", "w")
        --debug.write(out)
        --debug.close()

        return out
    end,
    ["#def"] = function(s, token, reg)
        local funcName, _, lastC1 = getBalancedParens(s, token["start"])
        local funcBody, _, lastC2 = getBalancedParens(s, lastC1)
        -- Strip line comments from string before inserting
        funcBody = string.gsub(funcBody, "// .-\n", "")
        local out = s:sub(1, token["start"] - 1) .. s:sub(lastC2 + 1)

        -- add function to the registry
        reg["$" .. funcName] = function(s, token)
            local funcStr = funcBody

            local argCounter = 1
            local lastC = token["start"]
            while argCounter < 10 do
                local i, j = string.find(funcStr, string.format("<%s>", argCounter))
                if i then
                    local arg, _, lastChar = getBalancedParens(s, lastC)
                    lastC = lastChar
                    -- replace parameters with proper values (old version is commented out just in case)
                    -- funcStr = funcStr:sub(1,i-1).." "..arg.." "..funcStr:sub(j+1)
                    funcStr = funcStr:gsub(string.format("<%s>", argCounter), arg)
                    argCounter = argCounter + 1
                else
                    break
                end
            end

            local out2 = s:sub(1, token["start"] - 1) .. "\n" .. funcStr .. "\n" .. s:sub(lastC + 2)
            return out2
        end

        return out
    end
}

-- Runs a function associated with a token's 'content' field from a given reg table
local function runTokenFunc(s, registry, token)
    local tokenFunc = registry[token["content"]]
    if tokenFunc ~= nil and tokenFunc ~= true then
        token["value"] = tokenFunc(s, token, registry)
        return token["value"]
    end
end

-- Gets symbol data associated with a token's 'content' field from a given reg table
local function setSymbolValue(s, registry, token)
    token["value"] = {
        ["startDir"] = registry[token["content"]]["startDir"],
        ["angles"] = registry[token["content"]]["angles"],
    }
    if turtleComplie then
        token["value"]["iota$serde"] = "hextweaks:pattern"
    end
end

-- Walks through a string and checks for presence of tokens from registry and initializes them
local function tokenSearch(s, registry)
    local tokens = {}
    for k, _ in pairs(registry) do
        local i, j = string.find(s, k)
        while i do
            if not tokens[i] or j > tokens[i]["end"] then
                tokens[i] = {
                    ["start"] = i,
                    ["end"] = j,
                    ["content"] = k,
                    ["value"] = nil
                }
            end
            i, j = string.find(s, k, i + 1)
        end
    end
    return tokens
end


-- Sorts a list a tokens to occur in the order of their appearance in the raw string
local function sortTokens(t)
    local keys = {}
    local returnTable = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    table.sort(keys)
    for i, k in ipairs(keys) do
        returnTable[i] = t[k]
    end
    return returnTable
end

-- Accepts a table of tables, returns a table that contains all key/value pairs
local function combineTables(tTable)
    local final = {}
    for _, v in pairs(tTable) do
        for k2, v2 in pairs(v) do
            final[k2] = v2
        end
    end
    return final
end

local myStack = { {} }
local stack = {
    push = function(e)
        table.insert(myStack, e)
    end,
    pop = function()
        return table.remove(myStack)
    end,
    top = function()
        return myStack[#myStack]
    end
}

local function dump_table(t, indent)
    indent = indent or 0
    for key, value in pairs(t) do
        if type(value) == "table" then
            vPrint(string.rep("  ", indent) .. key .. " = {")
            dump_table(value, indent + 1)
            vPrint(string.rep("  ", indent) .. "}")
        else
            vPrint(string.rep("  ", indent) .. key .. " = " .. tostring(value))
        end
    end
end

local function table_to_string(t, indent)
    indent = indent or 0
    local output = ""
    for key, value in pairs(t) do
        if type(value) == "table" then
            output = output .. string.rep("  ", indent) .. key .. " = {\n"
            output = output .. table_to_string(value, indent + 1)
            output = output .. string.rep("  ", indent) .. "}\n"
        else
            output = output .. string.rep("  ", indent) .. key .. " = " .. tostring(value) .. "\n"
        end
    end
    return output
end

local function compileChunk(tokens)
    for k, v in pairs(tokens) do
        if v["content"] == "%[" then
            vPrint("List start...")
            if turtleComplie then
                stack.push({ ["iota$serde"] = "hextweaks:list" })
            else
                stack.push({ ["iota$serde"] = "hextweaks:list" })
            end
        elseif v["content"] == "%]" then
            vPrint("... list end.")
            local j = stack.pop()
            local t = stack.top()
            table.insert(t, j)
        else
            local t = stack.top()
            table.insert(t, v["value"])
            if gVerb == true then
                if type(v.value) == "table" then
                    pretty = require "cc.pretty"
                    v.value = pretty.pretty(v.value)
                end
                print(k, v["start"], v["end"], " ", v["content"], v["value"])
            end
        end
    end
    --dump_table(myStack,0)
    --dump_table(output,1)
    local returnVal = stack.pop()
    stack.push({})
    return returnVal
end


local function stringProcess(s)
    -- Strip line comments from string
    local str = string.gsub(s, "//.-\n", "")
    str = string.gsub(str, "/%*.-%*/", "")

    -- Create temp folder for #wget commands
    shell.execute("mkdir", "/" .. getRunningPath() .. "temp")

    -- Replace string with version of itself with the specified file contents/function inside instead
    vPrint("Parsing string processes...")
    local search = sortTokens(tokenSearch(str, stringProccessRegistry))
    while #search > 0 do
        local single = table.remove(search)
        str = runTokenFunc(str, stringProccessRegistry, single)
        search = sortTokens(tokenSearch(str, stringProccessRegistry))
    end

    -- Delete temp folder for #wget commands
    shell.execute("delete", "/" .. getRunningPath() .. "temp")



    return str
end

local function removeOverlappingTokens(tokens)
    -- Create a deep copy of the input array
    local copyTokens = {}
    for i, token in ipairs(tokens) do
        copyTokens[i] = {
            ["start"] = token["start"],
            ["end"] = token["end"],
            ["content"] = token["content"],
            ["value"] = token["value"]
        }
    end

    local i = 1
    while i < #copyTokens do
        local current = copyTokens[i]
        local next = copyTokens[i + 1]

        -- Check if current token overlaps with the next one
        if current["end"] >= next["start"] then
            -- Determine which token is shorter
            local currentLength = current["end"] - current["start"]
            local nextLength = next["end"] - next["start"]

            if currentLength <= nextLength then
                -- Remove the current (shorter) token
                table.remove(copyTokens, i)
            else
                -- Remove the next (shorter) token
                table.remove(copyTokens, i + 1)
            end
        else
            -- Move to the next token if no overlap
            i = i + 1
        end
    end

    return copyTokens
end

local function compile(str, stripped, verbose, debug_output)
    local rawStr = str
    if verbose ~= nil then
        gVerb = verbose
    end
    vPrint("Compiling...")
    local reg
    if stripped == true then
        reg = strippedRegistry
    else
        reg = symbolRegistry
    end

    -- Process string to remove comments and embed files and functions
    str = stringProcess(str)

    local searches = {}

    vPrint("Parsing identifiers...")
    searches["identifiers"] = tokenSearch(str, identRegistry)
    for _, v in pairs(searches["identifiers"]) do
        runTokenFunc(str, identRegistry, v)
    end

    vPrint("Parsing symbols...")
    searches["symbols"] = tokenSearch(str, reg)
    for _, v in pairs(searches["symbols"]) do
        setSymbolValue(str, reg, v)
    end
    local tokens = removeOverlappingTokens(sortTokens(combineTables(searches)))
    local output = compileChunk(tokens)
    --print(#output)

    if debug_output == true then
        local function label(s)
            return "\n ========= " .. s .. " ========= \n\n"
        end

        local debugData = label("RAW STRING") .. rawStr
        debugData = debugData .. label("PROCESSED STRING") .. str
        debugData = debugData .. label("SEARCHES") .. table_to_string(searches)
        debugData = debugData .. label("TOKENS") .. table_to_string(tokens)
        debugData = debugData .. label("OUTPUT") .. table_to_string(output)

        local f = fs.open(getRunningPath() .. "debug.txt", "w")
        f.write(debugData)
        f.close()
    end

    return output
end

local function writeToFocus(tab)
    local wand = peripheral.find("wand")
    if wand then
        if #tab == 1 then
            tab = tab[1]
        else
            tab["iota$serde"] = "hextweaks:list"
        end
        wand.pushStack(tab)
        wand.runPattern("EAST", "deeeee")
    else
        --dump_table(tab,1)
        local focal_port = peripheral.find("focal_port")
        if not focal_port then
            vPrint("Cannot write! No focal port found.")
        elseif not focal_port.hasFocus() then
            vPrint("Cannot write! No focus found.")
        elseif not focal_port.canWriteIota() then
            vPrint("Cannot write! This won't compile!")
        else
            focal_port.writeIota(tab)
            vPrint("Compiled to focus!")
        end
    end
end

local function test()
    local file = fs.open(getRunningPath() .. "example.hexpattern", "r")
    local contents = file.readAll()
    file.close()
    writeToFocus(compile(contents))
end

return {
    compile = compile,
    stringProcess = stringProcess,
    writeToFocus = writeToFocus,
    symbolRegistry = symbolRegistry,
    identRegistry = identRegistry
}
