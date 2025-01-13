local describe = require("plenary.busted").describe
local it = require("plenary.busted").it
local before_each = require("plenary.busted").before_each
local after_each = require("plenary.busted").after_each

local Client = require "excalidraw.client"
local Path = require("plenary.path")
local Scene = require "excalidraw.scene"

local default_content = {
    type = "excalidraw",                   -- TODO: type excalidraw only
    version = 2,                           -- TODO: only version 2 available
    source = "https://www.excalidraw.com", -- TODO: only this source fixed for now
    elements = {},
    appState = {
        gridSize = nil,
        viewBackgroundColor = "#aaaaaa"
    },
    files = {}
}

local template_content = {
    type = "excalidraw",                   -- TODO: type excalidraw only
    version = 2,                           -- TODO: only version 2 available
    source = "https://www.excalidraw.com", -- TODO: only this source fixed for now
    elements = {},
    appState = {
        gridSize = nil,
        viewBackgroundColor = "#bbbbbb"
    },
    files = {}
}


describe("Client module", function()
    local client
    before_each(function()
        temp_dir = Path:new(vim.fn.tempname())
        client = Client.new({ storage_dir = temp_dir.filename })
    end)

    after_each(function()
        if temp_dir:exists() then
            temp_dir:rm({ recursive = true })
        end
    end)

    it("the client can be initialized", function()
        local mock_opts = {
            storage_dir = temp_dir.filename
        }
        -- Verify that the client is not nil
        assert.is_not_nil(client, "Client object should not be nil")

        -- Verify that the client is of the correct class
        assert.is_truthy(getmetatable(client) == require("excalidraw.client"),
            "Client object should have Client as its metatable")

        -- Verify that the client has the correct fields
        assert.is_table(client.opts, "Client should have an opts field")
        assert.equals(mock_opts.storage_dir, client.opts.storage_dir,
            "Client.opts should contain the correct storage_dir value")
    end)

    it("create_scene: should validate arguments and handle nil values", function()
        -- Missing opts
        assert.has_error(function()
            client:create_scene(nil)
        end, "Client.create_scene error: no opts")

        -- Missing title
        assert.has_error(function()
            client:create_scene({ template = "template.json" })
        end, "Client.create_scene error: missing argument opts.title")

        -- Missing template, and dir (template is optional in this implementation, so no error expected)
        assert.has_no.errors(function()
            local valid_title = "validtitle"
            client:create_scene({ title = valid_title })
        end)

        -- Missing only template (template is optional in this implementation, so no error expected)
        assert.has_no.errors(function()
            local valid_title = "validtitle"
            local dir = "directory"
            client:create_scene({ title = valid_title, dir = dir })
        end)
    end)

    -- Test correct creation of a Scene object
    it("create_scene: should create a valid Scene object, with default content", function()
        local expected = Scene.new(
            "validtitle",
            vim.fn.expand(vim.fs.joinpath(temp_dir.filename, "test_dir/validtitle.excalidraw")),
            default_content

        )
        local opts = { title = "validtitle", dir = "test_dir" }
        local scene = client:create_scene(opts)

        -- Verify that the scene object is created correctly
        assert.is_not_nil(scene, "Expected Scene object to be created")
        assert.are.same(expected.title, scene.title, "Expected relative path to include parent dirs and .excalidraw")
        assert.are.same(expected.path, scene.path, "Expected relative path to include parent dirs and .excalidraw")
        assert.are.same(expected.content, scene.content, "Scene content does not equal the default")
    end)
    it("create_scene: should create a valid Scene object, with template", function()
        local template = Scene.new(
            "templatetitle",
            "template_filename.excalidraw",
            template_content
        )
        local expected = Scene.new(
            "validtitle",
            vim.fn.expand(vim.fs.joinpath(temp_dir.filename, "test_dir/validtitle.excalidraw")),
            template_content

        )
        local opts = { title = "validtitle", dir = "test_dir", template = template }
        local scene = client:create_scene(opts)

        -- Verify that the scene object is created correctly
        assert.is_not_nil(scene, "Expected Scene object to be created")
        assert.are.same(expected.title, scene.title, "Expected relative path to include parent dirs and .excalidraw")
        assert.are.same(expected.path, scene.path, "Expected relative path to include .excalidraw")
        assert.are.same(expected.content, scene.content, "Scene content dows not equal the template")
    end)


    -- Test edge cases for the title
    it("create_scene: should handle edge cases with invalid titles", function()
        local cases = {
            [""] = "Client.create_scene error: missing argument opts.title",
            -- ["a/b/c"] = "Filename cannot contain directory separators",
            -- [".hiddenfile"] = "Filename cannot start with a dot",
        }

        for title, expected_error in pairs(cases) do
            assert.has_error(function()
                local scene = client:create_scene({ title = title })
                print("test: ", vim.inspect(scene))
            end, expected_error)
        end
    end)

    -- Test more edge cases for the title
    it("create_scene: should handle edge cases with non standard titles", function()
        local cases = {
            [""] = "Client.create_scene error: missing argument opts.title",
            -- ["a/b/c"] = "Filename cannot contain directory separators",
            -- [".hiddenfile"] = "Filename cannot start with a dot",
        }

        for title, expected_error in pairs(cases) do
            assert.has_error(function()
                local scene = client:create_scene({ title = title })
            end, expected_error)
        end
    end)
    -- -- Test behavior when file already exists
    -- it("should notify and return nil if file already exists", function()
    --     local opts = { title = "ExistingFile" }
    --     local absolute_path = Path:new("/mock/storage/dir/ExistingFile.excalidraw")
    --
    --     -- Mock filereadable to simulate existing file
    --     vim.fn.filereadable = function() return 1 end
    --
    --     local scene = client:create_scene(opts)
    --     assert.is_nil(scene, "Expected Scene creation to return nil when file exists")
    -- end)

    it("default content: get default", function()
        assert.are.same(default_content, client:default_template_content())
    end)
end)
