require("mini.doc").setup {}

local module_name = "excalidraw"
local submodules = {
    "lua/excalidraw/client.lua",
    "lua/excalidraw/scene.lua",
}

local align_right = function(text, width)
    if type(text) ~= "string" then
        return
    end
    local max_width = 80
    text = vim.trim(text)
    width = width or max_width

    local n_shifts = math.max(0, width - #text)

    return (" "):rep(n_shifts) .. text
end

MiniDoc.generate(submodules, "doc/excalidraw_api.txt", {
    hooks = {
        sections = {
            ["@tag"] = function(s)
                for i, _ in ipairs(s) do
                    s[i] = ("*%s.%s*"):format(module_name, s[i])
                    s[i] = align_right(s[i], 78)
                end
            end,
        },
        file = function(_) end
    },
})
