local Path = require("plenary.path")
local utils = require("excalidraw.utils")

describe("ensure_directory_exists", function()
    local temp_dir = Path:new(vim.fn.tempname())

    after_each(function()
        if temp_dir:exists() then
            temp_dir:rm({ recursive = true })
        end
    end)

    it("should create a directory if it doesn't exist", function()
        assert.is_false(temp_dir:exists(), "Temporary directory should not exist before the test")
        utils.ensure_directory_exists(temp_dir:absolute())
        assert.is_true(temp_dir:is_dir(), "Directory should exist after calling ensure_directory_exists")
    end)

    it("should not throw an error if the directory already exists", function()
        temp_dir:mkdir()
        assert.is_true(temp_dir:is_dir(), "Directory should already exist before the test")
        assert.has_no.errors(function()
            utils.ensure_directory_exists(temp_dir:absolute())
        end)
    end)

    it("should create a nested directory structure if it doesn't exist", function()
        -- Define a nested directory structure
        local nested_path = temp_dir:joinpath("level1", "level2", "level3")

        -- Ensure the nested path doesn't exist before the test
        assert.is_false(nested_path:exists(), "Nested directory should not exist before the test")

        -- Call the function to test
        utils.ensure_directory_exists(nested_path:absolute())

        -- Verify that the nested directory was created
        assert.is_true(nested_path:is_dir(), "Nested directory should exist after calling ensure_directory_exists")
    end)

    it("should not throw an error if the nested directory already exists", function()
        -- Pre-create the nested directory structure
        local nested_path = temp_dir:joinpath("level1", "level2", "level3")
        nested_path:mkdir({ parents = true })

        -- Verify that the nested directory exists
        assert.is_true(nested_path:is_dir(), "Nested directory should exist before the test")

        -- Call the function again and check that it doesn't throw an error
        assert.has_no.errors(function()
            utils.ensure_directory_exists(nested_path:absolute())
        end)
    end)

    local invalid_path = "/invalid_path/nested_folder"

    it("should throw an error when directory creation fails", function()
        -- Use assert.has_error to test that an error is raised
        assert.has_error(function()
            utils.ensure_directory_exists(invalid_path)
        end, "Vim:E739: Cannot create directory /invalid_path: permission denied")
    end)
end)
