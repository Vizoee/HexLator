local args = {...}
local branch
if not args[1] then
    branch = "main"
elseif args[1] == "main" or args[1] == "dev" then
    branch = args[1]
else
    print("Usage: install_hexlator [main|dev] [install path]")
    shell.exit()
end
local raw_url = "https://raw.githubusercontent.com/Vizoee/HexLator/main/"

local install_path
if not args[2] then
    install_path = "/programfiles/hexlator/"
else
    install_path = args[2].."/hexlator/"
end

local install_path_symbol
if not args[3] or args[3] == false then
    install_path_symbol = install_path
else
    install_path_symbol = "/programfiles/hexlator/"
end

shell.execute("delete", install_path)
shell.execute("delete", install_path_symbol)

shell.execute("wget", raw_url.."hexlator.lua", install_path.."hexlator.lua")
shell.execute("wget", raw_url.."hexget.lua", install_path.."hexget.lua")
shell.execute("wget", raw_url.."symbol-registry.json", install_path_symbol.."symbol-registry.json")
shell.execute("wget", raw_url.."hexxyedit.lua", install_path.."hexxyedit.lua")
shell.execute("wget", raw_url.."github.lua", install_path.."github.lua")
shell.execute("wget", raw_url.."base64.lua", install_path.."base64.lua")
shell.execute("wget", raw_url.."json.lua", install_path.."json.lua")
shell.execute("wget", raw_url.."config.json", install_path.."config.json")
shell.execute("wget", raw_url.."hexicon.json", install_path.."hexicon.json")

shell.execute("delete", "/startup.lua")
local file = fs.open("startup.lua","w")
file.write(string.format('shell.setAlias("hexget", "%shexget.lua") shell.setAlias("hexxyedit", "%shexxyedit.lua") shell.setAlias("github", "%sgithub.lua")',install_path, install_path, install_path))
file.close()
os.reboot()
