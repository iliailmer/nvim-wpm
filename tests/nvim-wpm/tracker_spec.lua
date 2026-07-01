local Tracker = require("nvim-wpm.tracker")

describe("tracker", function()
  it("returns 0 wpm for an empty window", function()
    local t = Tracker.new({ window_ms = 10000 })
    assert.are.equal(0, t:wpm(0))
  end)

  it("computes wpm for keystrokes within the window", function()
    local t = Tracker.new({ window_ms = 10000 })
    for _ = 1, 5 do
      t:record(0)
    end
    assert.near(6, t:wpm(5000), 1e-9)
  end)

  it("decays to 0 once keystrokes age out of the window", function()
    local t = Tracker.new({ window_ms = 10000 })
    for _ = 1, 5 do
      t:record(0)
    end
    assert.are.equal(0, t:wpm(10001))
  end)

  it("scales wpm according to a custom window_ms", function()
    local t = Tracker.new({ window_ms = 60000 })
    for _ = 1, 30 do
      t:record(0)
    end
    assert.near(6, t:wpm(0), 1e-9)
  end)
end)
