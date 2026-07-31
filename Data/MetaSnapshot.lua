local _, KWR = ...

local MetaSnapshot = {
    source = "https://murlok.io/meta",
    captured = "2026-06-27",
    patch = "12.0.7",
    season = "Midnight Season 1",
    refreshCadence = "8 hours",
}
KWR.MetaSnapshot = MetaSnapshot

local RANKINGS = {
    ["PRIEST:discipline"] = { role = "HEALER", rank = 1, rating = 2155 },
    ["MONK:mistweaver"] = { role = "HEALER", rank = 2, rating = 1980 },
    ["EVOKER:preservation"] = { role = "HEALER", rank = 3, rating = 1945 },
    ["PALADIN:holy"] = { role = "HEALER", rank = 4, rating = 1788 },
    ["PRIEST:holy"] = { role = "HEALER", rank = 5, rating = 1750 },
    ["DRUID:restoration"] = { role = "HEALER", rank = 6, rating = 1709 },
    ["SHAMAN:restoration"] = { role = "HEALER", rank = 7, rating = 1516 },

    ["WARRIOR:protection"] = { role = "TANK", rank = 1, rating = 2222 },
    ["DRUID:guardian"] = { role = "TANK", rank = 2, rating = 1715 },
    ["MONK:brewmaster"] = { role = "TANK", rank = 3, rating = 1704 },
    ["PALADIN:protection"] = { role = "TANK", rank = 4, rating = 0 },
    ["DEMONHUNTER:vengeance"] = { role = "TANK", rank = 5, rating = 0 },
    ["DEATHKNIGHT:blood"] = { role = "TANK", rank = 6, rating = 0 },

    ["ROGUE:subtlety"] = { role = "DAMAGER", rank = 1, rating = 2065 },
    ["DRUID:balance"] = { role = "DAMAGER", rank = 2, rating = 2034 },
    ["HUNTER:marksmanship"] = { role = "DAMAGER", rank = 3, rating = 1923 },
    ["SHAMAN:elemental"] = { role = "DAMAGER", rank = 4, rating = 1864 },
    ["EVOKER:devastation"] = { role = "DAMAGER", rank = 5, rating = 1830 },
    ["MAGE:fire"] = { role = "DAMAGER", rank = 6, rating = 1829 },
    ["HUNTER:beast mastery"] = { role = "DAMAGER", rank = 7, rating = 1827 },
    ["WARLOCK:affliction"] = { role = "DAMAGER", rank = 8, rating = 1803 },
    ["DEATHKNIGHT:unholy"] = { role = "DAMAGER", rank = 9, rating = 1802 },
    ["MAGE:frost"] = { role = "DAMAGER", rank = 10, rating = 1797 },
    ["WARRIOR:fury"] = { role = "DAMAGER", rank = 11, rating = 1792 },
    ["DRUID:feral"] = { role = "DAMAGER", rank = 12, rating = 1791 },
    ["DEMONHUNTER:devourer"] = { role = "DAMAGER", rank = 13, rating = 1790 },
    ["DEMONHUNTER:havoc"] = { role = "DAMAGER", rank = 14, rating = 1786 },
    ["WARRIOR:arms"] = { role = "DAMAGER", rank = 15, rating = 1779 },
    ["SHAMAN:enhancement"] = { role = "DAMAGER", rank = 16, rating = 1746 },
    ["DEATHKNIGHT:frost"] = { role = "DAMAGER", rank = 17, rating = 1723 },
    ["PALADIN:retribution"] = { role = "DAMAGER", rank = 18, rating = 1717 },
    ["MONK:windwalker"] = { role = "DAMAGER", rank = 19, rating = 1716 },
    ["ROGUE:assassination"] = { role = "DAMAGER", rank = 20, rating = 1703 },
    ["PRIEST:shadow"] = { role = "DAMAGER", rank = 21, rating = 1668 },
    ["ROGUE:outlaw"] = { role = "DAMAGER", rank = 22, rating = 1656 },
    ["MAGE:arcane"] = { role = "DAMAGER", rank = 23, rating = 1644 },
    ["WARLOCK:destruction"] = { role = "DAMAGER", rank = 24, rating = 1627 },
    ["HUNTER:survival"] = { role = "DAMAGER", rank = 25, rating = 1589 },
    ["EVOKER:augmentation"] = { role = "DAMAGER", rank = 26, rating = 0 },
    ["WARLOCK:demonology"] = { role = "DAMAGER", rank = 27, rating = 0 },
}

function MetaSnapshot:Lookup(classFile, spec)
    classFile = KWR.Util:Upper(classFile, "", 24)
    spec = KWR.Util:Text(spec, "", 32):lower()
    local row = RANKINGS[classFile .. ":" .. spec]
    if not row then return nil end
    local copy = KWR.Util:Copy(row)
    copy.source = self.source
    copy.captured = self.captured
    copy.patch = self.patch
    return copy
end

function MetaSnapshot:Count()
    local count = 0
    for _ in pairs(RANKINGS) do count = count + 1 end
    return count
end

function MetaSnapshot:All(role)
    local result = {}
    for lookup, row in pairs(RANKINGS) do
        if not role or row.role == role then
            local classFile, spec = lookup:match("^([^:]+):(.+)$")
            local copy = KWR.Util:Copy(row)
            copy.classFile = classFile
            copy.spec = spec
            copy.source = self.source
            copy.captured = self.captured
            result[#result + 1] = copy
        end
    end
    table.sort(result, function(a, b)
        if a.role ~= b.role then return a.role < b.role end
        if a.rank ~= b.rank then return a.rank < b.rank end
        return a.spec < b.spec
    end)
    return result
end

KWR:RegisterModule("MetaSnapshot", MetaSnapshot)