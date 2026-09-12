_G.KWR_SMOKE_BOOTSTRAP_ONLY = true
local bootstrap = assert(loadfile("tests/smoke.lua"))()
_G.KWR_SMOKE_BOOTSTRAP_ONLY = nil
local KWR = bootstrap.KWR
local state = assert(loadfile("tests/fixtures/commander_card.lua"))()(KWR)
assert(loadfile("tests/fixtures/command_followthrough.lua"))()(KWR, state)
assert(loadfile("tests/fixtures/followthrough_learning.lua"))()(KWR)
local geometry = assert(loadfile("tests/fixtures/commander_card_layout.lua"))()(KWR, state)
local function encode(value)
    if type(value) == "string" then
        return '"' .. value:gsub('[%z\1-\31\\"]', function(char)
            if char == '"' then return '\\"' end
            if char == '\\' then return '\\\\' end
            return string.format('\\u%04x', char:byte())
        end) .. '"'
    end
    if type(value) == "number" or type(value) == "boolean" then return tostring(value) end
    if type(value) == "table" then
        local parts = {}
        if #value > 0 then
            for _, item in ipairs(value) do parts[#parts + 1] = encode(item) end
            return "[" .. table.concat(parts, ",") .. "]"
        end
        local keys = {}
        for key in pairs(value) do keys[#keys + 1] = key end
        table.sort(keys)
        for _, key in ipairs(keys) do parts[#parts + 1] = encode(key) .. ":" .. encode(value[key]) end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return "null"
end
if os.getenv("KWR_CARD_GEOMETRY") == "1" then print("KWR_CARD_GEOMETRY " .. encode(geometry)) end
print("KWR_COMMANDER_CARD_PASS")
