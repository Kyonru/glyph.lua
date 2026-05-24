package.path = "./?.lua;./?/init.lua;" .. package.path

local CallbackBus = require("glyph.callback_bus")

describe("CallbackBus", function()
  it("rejects unsupported callbacks", function()
    local bus = CallbackBus.new({ "ready" })

    assert.is_true(bus:isSupported("ready"))
    assert.has_error(function()
      bus:register("missing", function() end)
    end)
  end)

  it("dispatches by priority then registration order", function()
    local bus = CallbackBus.new({ "event" })
    local calls = {}

    bus:register("event", function()
      calls[#calls + 1] = "b"
    end)
    bus:register("event", function()
      calls[#calls + 1] = "a"
    end, { priority = -1 })
    bus:register("event", function()
      calls[#calls + 1] = "c"
    end)

    bus:dispatch("event")

    assert.are.same({ "a", "b", "c" }, calls)
  end)

  it("unregisters idempotently", function()
    local bus = CallbackBus.new({ "event" })
    local calls = 0
    local unregister = bus:register("event", function()
      calls = calls + 1
    end)

    assert.is_true(unregister())
    assert.is_false(unregister())

    bus:dispatch("event")
    assert.are.equal(0, calls)
  end)

  it("uses a snapshot during dispatch", function()
    local bus = CallbackBus.new({ "event" })
    local calls = {}
    local unregisterSecond

    bus:register("event", function()
      calls[#calls + 1] = "first"
      unregisterSecond()
    end)
    unregisterSecond = bus:register("event", function()
      calls[#calls + 1] = "second"
    end)

    bus:dispatch("event")

    assert.are.same({ "first" }, calls)
  end)
end)
