describe("relocatable package imports", function()
  local nestedPrefix = "lib.random.folder.glyph"
  local loaders = package.searchers or package.loaders

  local function clearNested()
    for name in pairs(package.loaded) do
      if name == nestedPrefix or name:sub(1, #nestedPrefix + 1) == nestedPrefix .. "." then
        package.loaded[name] = nil
      end
    end
  end

  it("loads glyph from an arbitrary package prefix", function()
    clearNested()

    local function nestedSearcher(name)
      if name ~= nestedPrefix and name:sub(1, #nestedPrefix + 1) ~= nestedPrefix .. "." then
        return nil
      end

      local suffix = name == nestedPrefix and "init" or name:sub(#nestedPrefix + 2)
      local path = "glyph/" .. suffix:gsub("%.", "/") .. ".lua"
      local loader, err = loadfile(path)
      if loader then
        return loader
      end
      return err
    end

    table.insert(loaders, 1, nestedSearcher)
    local ok, ui = pcall(require, nestedPrefix)
    table.remove(loaders, 1)

    assert.is_true(ok)
    assert.are.equal("function", type(ui.text))
    assert.are.equal("table", type(package.loaded[nestedPrefix .. ".components"]))

    clearNested()
  end)
end)
