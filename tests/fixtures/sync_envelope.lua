-- Shared protocol vectors for independently packaged Commander and Sentinel.
return function(comm)
    local fields = { "v=2", "sid=pvp-123-777", "seq=1", "kind=STATE",
        "ts=100", "ep=epoch", "src=Sentinel-Realm", "body=alive%3D1" }
    local valid = table.concat(fields, "|")
    local tested = 0
    local function reject(payload)
        local ok, decoded = pcall(comm.Decode, comm, payload)
        assert(ok and decoded == nil, "Malformed sync envelope threw or was accepted: " .. tostring(payload))
        tested = tested + 1
    end
    local function replace(index, field)
        local copy = {}
        for position, value in ipairs(fields) do copy[position] = position == index and field or value end
        return table.concat(copy, "|")
    end
    local decoded = assert(comm:Decode(valid), "Valid envelope was rejected")
    assert(decoded.sequence == 1 and decoded.timestamp == 100 and decoded.body == "alive=1")
    assert(comm:Decode(replace(8, "body=")).body == "", "Empty body is a valid envelope field")
    assert(comm:Decode(replace(8, "body=enemy%3DA%25B%3Bspell%3D118")).body == "enemy=A%B;spell=118")
    assert(comm:Decode(replace(8, "body=%2520")).body == "%20", "Percent decoding ran more than once")
    for index = 1, #fields do
        reject(replace(index, "unknown=x"))
        reject(replace(index, ""))
        reject(valid .. "|" .. fields[index])
    end
    reject(nil)
    reject(false)
    reject({})
    reject(123)
    reject("")
    reject(string.rep("x", comm.MAX_BYTES + 1))
    reject("|" .. valid)
    reject(valid .. "|")
    reject(valid:gsub("|", "||", 1))
    for _, index in ipairs({ 3, 5 }) do
        local key = index == 3 and "seq=" or "ts="
        for _, value in ipairs({ "", "-1", "+1", "1.5", "1e3", "nan", "inf",
            "9007199254740992", string.rep("9", 80) }) do
            reject(replace(index, key .. value))
        end
        assert(comm:Decode(replace(index, key .. "9007199254740991")), "Exact numeric bound was rejected")
    end
    reject(replace(3, "seq=0"))
    assert(comm:Decode(replace(5, "ts=0")), "Zero timestamp must remain valid at startup")
    for _, index in ipairs({ 2, 6, 7, 8 }) do
        local key = fields[index]:match("^([^=]+=)")
        for _, value in ipairs({ "%", "%A", "%AZ", "%1G", "x%0", "%20%F" }) do
            reject(replace(index, key .. value))
        end
        if index ~= 8 then reject(replace(index, key)) end
    end
    reject(replace(1, "v=99"))
    reject(replace(4, "kind=UNKNOWN"))
    for _, value in ipairs({ "%00", "%0A", "%1F", "%7F", "%80", "%C0%AF",
        "%E0%80%AF", "%ED%A0%80", "%F0%80%80%80", "%F4%90%80%80", "%F5%80%80%80",
        "%C2", "%E2%82", "%F0%90%80", string.char(0), string.char(255) }) do
        reject(replace(8, "body=" .. value))
    end
    for _, value in ipairs({ "%C2%A9", "%E2%82%AC", "%F0%9F%98%80",
        "%ED%9F%BF", "%F4%8F%BF%BF", string.char(195, 169) }) do
        assert(comm:Decode(replace(8, "body=" .. value)), "Valid UTF-8 body was rejected")
    end
    -- Bounded arbitrary byte inputs exercise the parser's total-function contract.
    for length = 1, 240 do
        local bytes = {}
        for index = 1, length do bytes[index] = string.char((length * 17 + index * 31) % 256) end
        reject(table.concat(bytes))
    end
    return tested
end
