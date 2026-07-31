local _, KWR = ...

local SourceRegistry = {}
KWR.SourceRegistry = SourceRegistry

local SOURCES = {
    BLIZZARD_LIVE = {
        authority = "LIVE",
        name = "Blizzard in-game APIs",
        use = "Authoritative live facts when non-secret and safely sanitized.",
    },
    BLIZZARD_DATA = {
        authority = "REFERENCE",
        name = "Battle.net Game Data and Profile APIs",
        url = "https://community.developer.battle.net/documentation/world-of-warcraft/game-data-apis",
        use = "Build-time spell, specialization, item, season, and public profile reference.",
    },
    BLIZZARD_HOTFIXES = {
        authority = "REFERENCE",
        name = "Official World of Warcraft Hotfixes",
        url = "https://worldofwarcraft.blizzard.com/en-us/news/24276957",
        use = "Build-time PvP tuning and API/mechanics review; live observations remain authoritative.",
    },
    MURLOK = {
        authority = "META",
        name = "Murlok RBG Meta",
        url = "https://murlok.io/meta",
        use = "Expiring aggregate meta cross-check; never individual-player truth.",
    },
    PVP_BASICS = {
        authority = "EDITORIAL",
        name = "PvP Basics",
        url = "https://pvpblog.wordpress.com/",
        use = "Historical and current doctrine hypotheses requiring patch review.",
    },
    WOWHEAD_RBG = {
        authority = "EDITORIAL",
        name = "Wowhead RBG Guide",
        url = "https://www.wowhead.com/guide/rated-battlegrounds-rbg-guide",
        use = "New-leader concepts and historical strategy; patch-specific claims require revalidation.",
    },
    WARCRAFT_WIKI_PVP = {
        authority = "REFERENCE",
        name = "Warcraft Wiki battleground mechanics",
        url = "https://warcraft.wiki.gg/wiki/Battleground",
        use = "Build-time scoring and patch-history cross-check; live Blizzard widgets remain authoritative.",
    },
    WARCRAFT_LOGS = {
        authority = "RESEARCH",
        name = "Warcraft Logs API",
        url = "https://www.warcraftlogs.com/api/docs",
        use = "Optional aggregate research when representative PvP data and permitted use are confirmed.",
    },
    COMMUNITY = {
        authority = "SIGNAL",
        name = "Reddit and Twitch community signals",
        use = "Early-warning hypotheses only; never shipped directly as truth.",
    },
    KWR_CORPUS = {
        authority = "LEARNED",
        name = "KWR reviewed match corpus",
        use = "Anonymized, reviewed plan outcomes and counterplay evidence.",
    },
    KWR_ENCOUNTER = {
        authority = "HISTORICAL",
        name = "KWR local encounter history",
        use = "Current-season likely player specialization and role until contradicted by live evidence.",
    },
}

local SIGNALS = {
    {
        id = "RESPAWN_PROXIMITY",
        source = "PVP_BASICS",
        status = "REVIEWED_PRINCIPLE",
        maps = { "WSG", "TWINPEAKS" },
        principle = "Prefer fights whose resurrection travel favors the friendly team.",
        captured = "2026-06-27",
    },
    {
        id = "TOK_KILL_WINDOW_PICKUP",
        source = "PVP_BASICS",
        status = "HISTORICAL_REVALIDATE",
        maps = { "TEMPLE" },
        principle = "Create a numbers advantage before committing to nearby orb pickups.",
        captured = "2026-06-27",
    },
    {
        id = "TERRAIN_DISPLACEMENT_EDGE",
        source = "COMMUNITY",
        status = "MONITOR_ONLY",
        maps = {},
        principle = "Terrain displacement may create outsized objective or death pressure near map edges.",
        captured = "2026-06-27",
    },
    {
        id = "HEALER_THROUGHPUT_SPIKE",
        source = "COMMUNITY",
        status = "MONITOR_ONLY",
        maps = {},
        principle = "Community reports of exceptional healer throughput should trigger data review, not an automatic counter rule.",
        captured = "2026-06-27",
    },
}

function SourceRegistry:Get(id)
    return SOURCES[id]
end

function SourceRegistry:Signals(status)
    local result = {}
    for _, signal in ipairs(SIGNALS) do
        if not status or signal.status == status then result[#result + 1] = KWR.Util:Copy(signal) end
    end
    return result
end

function SourceRegistry:Count()
    local count = 0
    for _ in pairs(SOURCES) do count = count + 1 end
    return count, #SIGNALS
end

KWR:RegisterModule("SourceRegistry", SourceRegistry)