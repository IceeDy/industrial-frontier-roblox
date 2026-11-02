--!strict
local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new(clock)
	return setmetatable({ buckets = {}, clock = clock or os.clock }, RateLimiter)
end

function RateLimiter:allow(userId, action, limit, windowSeconds)
	local now = self.clock()
	local key = tostring(userId) .. ":" .. action
	local bucket = self.buckets[key]
	if not bucket or now - bucket.startedAt >= windowSeconds then
		self.buckets[key] = { startedAt = now, count = 1 }
		return true
	end
	if bucket.count >= limit then return false end
	bucket.count += 1
	return true
end

return RateLimiter
