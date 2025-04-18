local folder = ".startup"
if not fs.exists(folder) then
    fs.makeDir(folder)
else
    local files = fs.list(folder)
    for _, file in ipairs(files) do
        if string.sub(file, -4) == ".lua" then
            shell.run(folder .. "/" .. file)
        end
    end
end