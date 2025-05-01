local hexFile
local hexFileName = "hexicon.json"

local function getRunningPath()
    local runningProgram = shell.getRunningProgram()
    local programName = fs.getName(runningProgram)
    return runningProgram:sub(1, #runningProgram - #programName)
end

if fs.exists(getRunningPath() .. hexFileName) then
    hexFile = fs.open(getRunningPath() .. hexFileName, "r")
elseif fs.exists("/programfiles/hexlator/" .. hexFileName) then
    hexFile = fs.open("/programfiles/hexlator/" .. hexFileName, "r")
elseif fs.exists("/disk/hexlator/" .. hexFileName) then
    hexFile = fs.open("/disk/hexlator/" .. hexFileName, "r")
end
if not hexFile then
    printError("Could not find hexicon.json in the current directory")
    return nil
end
local hexicon = textutils.unserialiseJSON(hexFile.readAll())

local function toHexicon(str)
    local firstStrokeFix = {
        ["NORTH_EAST"] = "a",
        ["EAST"] = "q"
    }
    local startToAngle = {
        ["EAST"] = "w",
        ["NORTH_EAST"] = "q"
    }
    local char = string.sub(str, 1, 1)
    local angles = hexicon[char].pattern
    local offset = hexicon[char].offset
    for i = 2, #str do
        char = string.sub(str, i, i)
        local pattern = hexicon[char].pattern
        local start = hexicon[char].start
        local startFix = offset and firstStrokeFix[start] or startToAngle[start]
        angles = angles .. startFix .. pattern
        offset = hexicon[char].offset
    end
    return {
        ["startDir"] = hexicon[str:sub(1, 1)].start,
        ["angles"] = angles,
    }
end

return {toHexicon=toHexicon}