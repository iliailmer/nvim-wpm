local Tracker = {}
Tracker.__index = Tracker

function Tracker.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Tracker)
  self.window_ms = opts.window_ms or 10000
  self.clock = opts.clock or function()
    return vim.uv.now()
  end
  self.queue = {}
  return self
end

function Tracker:record(timestamp)
  table.insert(self.queue, timestamp or self.clock())
end

function Tracker:prune(now)
  local cutoff = now - self.window_ms
  local i = 1
  while self.queue[i] and self.queue[i] < cutoff do
    i = i + 1
  end
  if i > 1 then
    local pruned = {}
    for j = i, #self.queue do
      pruned[#pruned + 1] = self.queue[j]
    end
    self.queue = pruned
  end
end

function Tracker:wpm(timestamp)
  local now = timestamp or self.clock()
  self:prune(now)
  local count = #self.queue
  if count == 0 then
    return 0
  end
  local words = count / 5
  local minutes = self.window_ms / 60000
  return words / minutes
end

return Tracker
