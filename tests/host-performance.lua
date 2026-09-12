-- Actual host-clock measurements, never injected costs or client FPS claims.
dofile("tests/smoke.lua")
assert(type(os.clock) == "function", "A real host clock is required.")
local hostClock = os.clock
function debugprofilestop() return hostClock() * 1000 end
KWR.db.profile.preview = true
local samples, total = {}, 0
for index = 1, 35 do
    local started = hostClock()
    assert(KWR.MatchRuntime:ForceRefresh("manual"), "Host benchmark refresh failed.")
    local elapsed = (hostClock() - started) * 1000
    assert(elapsed >= 0 and elapsed < math.huge, "Invalid host duration.")
    if index > 5 then
        samples[#samples + 1] = elapsed
        total = total + elapsed
    end
end
table.sort(samples)
assert(total > 0, "Host clock did not advance.")
local function percentile(percent)
    -- Nearest-rank keeps this small, fixed sample benchmark deterministic and
    -- reports an observed duration rather than interpolating a synthetic one.
    return samples[math.max(1, math.min(#samples, math.ceil(#samples * percent)))]
end

print(string.format("KWR_HOST_BENCHMARK_PASS samples=%d avgMs=%.6f p50Ms=%.6f p95Ms=%.6f p99Ms=%.6f maxMs=%.6f timingSource=os.clock scope=host-mocked-preview warmup=5",
    #samples, total / #samples, percentile(0.50), percentile(0.95),
    percentile(0.99), samples[#samples]))
