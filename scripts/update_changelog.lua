-- Lua script to update a changelog file

local os = require("os")
local io = require("io")

-- Get the TAG environment variable
local TAG = os.getenv("TAG")
local VERSION = string.sub(TAG, 2)

-- Main function to update the changelog
local function main()
    print(string.format("Preparing changelog for %s", TAG))
    local changelog_path = "CHANGELOG.md"

    -- Read the changelog file
    local changelog_file = io.open(changelog_path, "r")
    if not changelog_file then
        error("Failed to open CHANGELOG.md")
    end

    local lines = {}
    for line in changelog_file:lines() do
        table.insert(lines, line)
    end
    changelog_file:close()

    local insert_index = -1

    for i, line in ipairs(lines) do
        if string.find(line, "^## Unreleased") then
            insert_index = i + 1
        elseif string.find(line, "^## %[v" .. VERSION .. "%]") then
            print("CHANGELOG already up-to-date")
            return
        elseif string.find(line, "^## %[v") then
            break
        end
    end

    if insert_index < 0 then
        error("Couldn't find 'Unreleased' section")
    end

    table.insert(lines, insert_index, "")
    table.insert(
        lines,
        insert_index + 1,
        string.format(
        "## [v%s](https://github.com/marcocofano/excalidraw/excalidraw.nvim/releases/tag/v%s) - %s\n",
            VERSION,
            VERSION,
            os.date("%Y-%m-%d")
        )
    )

    changelog_file = io.open(changelog_path, "w")
    if not changelog_file then
        error("Update to CHANGELOG.md Failed")
    end

    for _, line in ipairs(lines) do
        changelog_file:write(line .. "\n")
    end
    changelog_file:close()
end

-- Run the main function
main()
