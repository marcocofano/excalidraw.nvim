local Client = require "excalidraw.client"
local Path = require("plenary.path")


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

    it("create_canva: should validate arguments and handle nil values", function()
        -- Missing opts
        assert.has_error(function()
            client:create_canva(nil)
        end, "Client.create_canva error: no opts")

        -- Missing title
        assert.has_error(function()
            client:create_canva({ template = "template.json" })
        end, "Client.create_canva error: missing argument opts.title")

        -- Missing template, and dir (template is optional in this implementation, so no error expected)
        assert.has_no.errors(function()
            local valid_title = "validtitle"
            client:create_canva({ title = valid_title })
        end)
        
        -- Missing only template (template is optional in this implementation, so no error expected)
        assert.has_no.errors(function()
            local valid_title = "validtitle"
            local dir = "directory"
            client:create_canva({ title = valid_title, dir = dir})
        end)
    end)

    -- Test correct creation of a Canva object
    it("create_canva: should create a valid Canva object", function()
        local opts = { title = "validtitle" }
        local canva = client:create_canva(opts)

        -- Verify that the canva object is created correctly
        assert.is_not_nil(canva, "Expected Canva object to be created")
        assert.equals("validtitle", canva.title, "Expected Canva title to match opts.title")
        assert.equals("validtitle.excalidraw", canva.relative_path, "Expected relative path to include .excalidraw")
        assert.equals(vim.fs.joinpath(temp_dir:absolute(), "validtitle.excalidraw"), canva.absolute_path,
            "Expected absolute path to be correct")
    end)


    -- Test edge cases for the title
    it("create_canva: should handle edge cases with invalid titles", function()
        local cases = {
            [""] = "Client.create_canva error: missing argument opts.title",
            -- ["a/b/c"] = "Filename cannot contain directory separators",
            -- [".hiddenfile"] = "Filename cannot start with a dot",
        }

        for title, expected_error in pairs(cases) do
            assert.has_error(function()
                local canva = client:create_canva({ title = title })
                print("test: ", vim.inspect(canva))
            end, expected_error)
        end
    end)
    
    -- Test more edge cases for the title
    it("create_canva: should handle edge cases with non standard titles", function()
        local cases = {
            [""] = "Client.create_canva error: missing argument opts.title",
            -- ["a/b/c"] = "Filename cannot contain directory separators",
            -- [".hiddenfile"] = "Filename cannot start with a dot",
        }

        for title, expected_error in pairs(cases) do
            assert.has_error(function()
                local canva = client:create_canva({ title = title })
                print("test: ", vim.inspect(canva))
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
    --     local canva = client:create_canva(opts)
    --     assert.is_nil(canva, "Expected Canva creation to return nil when file exists")
    -- end)
end)
