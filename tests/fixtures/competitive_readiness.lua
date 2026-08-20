local maps = {
    { key = "ARATHI", kind = "NODE", score = { 900, 700, 1500 }, objectives = { 3, 2 } },
    { key = "GILNEAS", kind = "NODE", score = { 900, 700, 1500 }, objectives = { 2, 1 } },
    { key = "DEEPWIND", kind = "NODE", score = { 900, 700, 1500 }, objectives = { 3, 2 } },
    { key = "EOTS", kind = "HYBRID", score = { 900, 700, 1500 }, objectives = { 2, 2 } },
    { key = "WSG", kind = "FLAG", score = { 2, 1, 3 }, objectives = { 1, 1 } },
    { key = "TWINPEAKS", kind = "FLAG", score = { 2, 1, 3 }, objectives = { 1, 1 } },
    { key = "TEMPLE", kind = "ORB", score = { 900, 700, 1500 }, objectives = { 2, 1 } },
    { key = "SILVERSHARD", kind = "CART", score = { 900, 700, 1500 }, objectives = { 2, 1 } },
    { key = "DEEPHAUL", kind = "CART", score = { 900, 700, 1500 }, objectives = { 2, 1 } },
    { key = "SEETHING", kind = "RESOURCE", score = { 900, 700, 1500 }, objectives = { 1, 1 } },
}

local fixtures = {}
for _, map in ipairs(maps) do
    for _, variant in ipairs({ "STANDARD", "BLITZ" }) do
        fixtures[#fixtures + 1] = {
            id = map.key .. "_" .. variant,
            mapKey = map.key,
            kind = map.kind,
            variant = variant,
            score = map.score,
            objectives = map.objectives,
        }
    end
end
return fixtures
