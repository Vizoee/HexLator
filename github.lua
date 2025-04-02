local github = {}

github.cache = {}

function github.convert_url(url)
    url = url
        :gsub("https://github.com/", "https://api.github.com/repos/")
        :gsub("https://raw.githubusercontent.com/", "https://api.github.com/repos/")
        :gsub("blob/.-/", "contents/")
        :gsub("refs/heads/.-/", "contents/")
    return url
end

function github.api_response(url)
    local function getRunningPath()
        local runningProgram = shell.getRunningProgram()
        local programName = fs.getName(runningProgram)
        return runningProgram:sub( 1, #runningProgram - #programName )
    end
    -- Check if the URL is valid
    local ok, err = http.checkURL(url)
    if not ok then
        local config
        if fs.exists(getRunningPath() .. "config.json") then
            config = fs.open(getRunningPath() .. "config.json", "r")
        else if fs.exists("/disk/hexlator/" .. "config.json") then
                config = fs.open("/disk/hexlator/" .. "config.json", "r")
            else
                printError(err or "Invalid URL.")
                return
            end
        end
        local settings = textutils.unserialise(config.readAll())
        config.close()
        if settings["default_repo"] == "" then
            printError(err or "Invalid URL.")
            return
        end
        url = settings["default_repo"].."/blob/"..settings["branch"].."/"..url
        print(url)
        ok, err = http.checkURL(url)
        if not ok then
            printError(err or "Invalid URL.")
            return
        end
    end

    local apiurl = github.convert_url(url)

    if github.cache[apiurl] then
        print("Returned cached")
        return github.cache[apiurl]
    end

    local response = http.get(apiurl).readAll()
    local json = require("json")
    local content = json.get(response, "content"):gsub("\\n", "\n")
    local name = json.get(response, "name"):gsub(" ", "_")
    local base64 = require("base64")
    local data = base64.decode(content)
    local output = {
        name = name,
        content = data,
        response = response
    }
    github.cache[apiurl] = output
    return output
end

function github.api(url, folder)
    folder = folder or "./"
    local response = github.api_response(url)
    local file = fs.open(folder..response.name, "w")
    file.write(response.content)
    file.close()
end

if debug.getinfo(3) then
    return github
else
    if #arg > 0 then
        github.api(arg[1], arg[2])
    else
        print("Usage: github <repository-file>")
    end
end

