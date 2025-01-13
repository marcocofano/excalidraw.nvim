local Scene = require('excalidraw.scene') -- Adjust path as needed
local Path = require('plenary.path')
local describe = require("plenary.busted").describe
local before_each = require("plenary.busted").before_each
local after_each = require("plenary.busted").after_each
local it = require('plenary.busted').it
local eq = assert.are.same

local TEST_FILE_PATH = Path:new("test_scene.json")

describe("Scene Class Tests", function()
    after_each(function()
        if TEST_FILE_PATH:exists() then
            TEST_FILE_PATH:rm()
        end
    end)

    it("should create a new Scene with default content", function()
        local scene = Scene.new("Test Title", TEST_FILE_PATH.filename)
        eq(scene.title, "Test Title")
        eq(scene.path, TEST_FILE_PATH.filename)
        eq(scene.content.type, "excalidraw")
        eq(scene.content.version, 2)
        eq(scene.content.source, "https://www.excalidraw.com")
        eq(scene.content.appState.gridSize, 10)
        eq(scene.content.appState.viewBackgroundColor, "#aaaaaa")
        eq(#scene.content.elements, 0)
        eq(#scene.content.files, 0)
    end)

    it("should load content from a table", function()
        local content = {
            elements = { { id = 1, type = "rectangle" } },
            appState = { gridSize = 20 },
            files = { test_file = { size = 123 } }
        }

        local scene = Scene.new("Test Title", TEST_FILE_PATH.filename, content)
        eq(#scene.content.elements, 1)
        eq(scene.content.elements[1].type, "rectangle")
        eq(scene.content.appState.gridSize, 20)
        eq(scene.content.files.test_file.size, 123)
    end)

    it("should overwrite content when specified", function()
        local scene = Scene.new("Test Title", TEST_FILE_PATH.filename)
        local new_content = {
            elements = { { id = 2, type = "circle" } },
            appState = { viewBackgroundColor = "#ffffff" }
        }

        scene:load_content_from_table(new_content, true)
        eq(#scene.content.elements, 1)
        eq(scene.content.elements[1].type, "circle")
        eq(scene.content.appState.viewBackgroundColor, "#ffffff")
        eq(scene.content.appState.gridSize, nil)
    end)

    it("should append content when not overwriting", function()
        local scene = Scene.new("Test Title", TEST_FILE_PATH.filename)
        local new_content = {
            elements = { { id = 2, type = "circle" } },
            appState = { gridSize = 20 }
        }

        scene:load_content_from_table(new_content, false)
        eq(#scene.content.elements, 1)
        eq(scene.content.elements[1].type, "circle")
        eq(scene.content.appState.gridSize, 20)
        eq(scene.content.appState.viewBackgroundColor, "#aaaaaa")
    end)

    it("should save the Scene to a JSON file", function()
        local scene = Scene.new("Test Title", TEST_FILE_PATH.filename)
        scene:save()
        assert(TEST_FILE_PATH:exists())

        local content = TEST_FILE_PATH:read()
        local decoded = vim.fn.json_decode(content)
        eq(decoded.type, "excalidraw")
    end)

    it("should correctly encode to JSON", function()
        local scene = Scene.new("Test Title", TEST_FILE_PATH.filename)
        local json = scene:to_json()
        local decoded = vim.fn.json_decode(json)
        eq(decoded.type, "excalidraw")
    end)

    it("should check if the file exists", function()
        local scene = Scene.new("Test Title", TEST_FILE_PATH.filename)
        eq(scene:exists(), false)

        scene:save()
        eq(scene:exists(), true)
    end)

    it("should return the filename", function()
        local scene = Scene.new("Test Title", TEST_FILE_PATH.filename)
        eq(scene:filename(), "test_scene.json")
    end)
end)
