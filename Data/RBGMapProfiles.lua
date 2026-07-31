local _, KWR = ...

local RBGMapProfiles = {
    shared = {
        doctrineLayers = {
            "map fundamentals",
            "opening plan",
            "stabilize plan",
            "pressure plan",
            "recovery plan",
            "endgame plan",
            "enemy counter patterns",
        },
        sensorFamilies = {
            "score truth",
            "objective truth",
            "friendly roster truth",
            "enemy roster truth",
            "local fight truth",
            "movement / location truth",
            "timing / respawn truth",
            "event transition truth",
        },
        decisionAxes = {
            "objective coverage",
            "rotation cost",
            "kill pressure",
            "healer control",
            "offense posture",
            "defense posture",
            "recovery path",
            "counter-response safety",
        },
        corpusLayers = {
            "replay",
            "golden label",
            "run result",
            "outcome review",
            "adversarial replay",
        },
    },
    maps = {
        ARATHI = {
            mapKey = "ARATHI",
            title = "Arathi Basin",
            short = "AB",
            family = "NODE",
            maxScore = 1500,
            maxObjectives = 5,
            decisionModel = "hold three, deny flips, trade weak outer",
            primaryQuestions = {
                "Which node shell wins the clock?",
                "Which incoming requires reserve first?",
                "When does an outer trade beat a center brawl?",
            },
            benchmarkFocus = {
                "defender sufficiency",
                "reserve timing",
                "cross-cap value",
                "clock discipline",
            },
            corpusMinimum = { replays = 10, goldenLabels = 10, outcomeReviews = 10, adversarialCases = 5 },
        },
        GILNEAS = {
            mapKey = "GILNEAS",
            title = "Battle for Gilneas",
            short = "BFG",
            family = "NODE",
            maxScore = 1500,
            maxObjectives = 3,
            decisionModel = "hold two, rotate early, punish weak third",
            primaryQuestions = {
                "Is Waterworks worth the current trade?",
                "Which held node breaks first if reserve leaves?",
                "When is the third node truly exposed?",
            },
            benchmarkFocus = {
                "two-base shell quality",
                "weak-side punish timing",
                "spinner control",
                "endgame no-chase discipline",
            },
            corpusMinimum = { replays = 10, goldenLabels = 10, outcomeReviews = 10, adversarialCases = 5 },
        },
        DEEPWIND = {
            mapKey = "DEEPWIND",
            title = "Deepwind Gorge",
            short = "DWG",
            family = "NODE",
            maxScore = 1500,
            maxObjectives = 5,
            decisionModel = "hold three, guard Market value, punish ghost lanes",
            primaryQuestions = {
                "Does Market decide the current clock path?",
                "Which flank is cheapest to swing?",
                "How many real defenders are required to keep the shell stable?",
            },
            benchmarkFocus = {
                "market priority",
                "flank swap timing",
                "coverage retention",
                "collapse prevention",
            },
            corpusMinimum = { replays = 10, goldenLabels = 10, outcomeReviews = 10, adversarialCases = 5 },
        },
        EOTS = {
            mapKey = "EOTS",
            title = "Eye of the Storm",
            short = "EOTS",
            family = "HYBRID",
            maxScore = 1500,
            maxObjectives = 4,
            decisionModel = "tower control first, flag only at useful value",
            primaryQuestions = {
                "What is the current flag value at held towers?",
                "Is a tower swing stronger than a flag route now?",
                "Which tower is the cheapest decisive change?",
            },
            benchmarkFocus = {
                "flag value discipline",
                "tower swing timing",
                "mid allocation",
                "bad-flag denial",
            },
            corpusMinimum = { replays = 10, goldenLabels = 10, outcomeReviews = 10, adversarialCases = 5 },
        },
        WSG = {
            mapKey = "WSG",
            title = "Warsong Gulch",
            short = "WSG",
            family = "FLAG",
            maxScore = 3,
            maxObjectives = 2,
            decisionModel = "protect OFC, coordinate EFC kill, convert return windows",
            primaryQuestions = {
                "Does our carrier shell survive the next enemy connect?",
                "Is the next EFC pressure window real or fake?",
                "When does return-and-cap outweigh mid control?",
            },
            benchmarkFocus = {
                "carrier peel quality",
                "return team timing",
                "kill window confirmation",
                "stall versus cap conversion",
            },
            corpusMinimum = { replays = 10, goldenLabels = 10, outcomeReviews = 10, adversarialCases = 5 },
        },
        TWINPEAKS = {
            mapKey = "TWINPEAKS",
            title = "Twin Peaks",
            short = "TP",
            family = "FLAG",
            maxScore = 3,
            maxObjectives = 2,
            decisionModel = "protect OFC, pressure EFC, turn return into cap",
            primaryQuestions = {
                "Is defense or offense the current score lever?",
                "Can the return team reach EFC before reset?",
                "Do we hold shell or trade for the cap window?",
            },
            benchmarkFocus = {
                "carrier route security",
                "pressure collapse timing",
                "reset discipline",
                "final cap conversion",
            },
            corpusMinimum = { replays = 10, goldenLabels = 10, outcomeReviews = 10, adversarialCases = 5 },
        },
        TEMPLE = {
            mapKey = "TEMPLE",
            title = "Temple of Kotmogu",
            short = "TOK",
            family = "ORB",
            maxScore = 1500,
            maxObjectives = 4,
            decisionModel = "hold valuable orbs safely, deny enemy carrier uptime",
            primaryQuestions = {
                "Which carrier is highest value to protect or kill?",
                "Is center hold worth the current exposure?",
                "Which loose orb changes the score fastest?",
            },
            benchmarkFocus = {
                "orb value discipline",
                "center control",
                "carrier replacement timing",
                "kill-confirm on high-value carrier",
            },
            corpusMinimum = { replays = 10, goldenLabels = 10, outcomeReviews = 10, adversarialCases = 5 },
        },
        SILVERSHARD = {
            mapKey = "SILVERSHARD",
            title = "Silvershard Mines",
            short = "SSM",
            family = "CART",
            maxScore = 1500,
            maxObjectives = 3,
            decisionModel = "fight on live cart, rotate before next route locks",
            primaryQuestions = {
                "Which cart is score-active right now?",
                "When must the team leave a dead cart?",
                "Which route switch is still reachable in time?",
            },
            benchmarkFocus = {
                "cart priority correctness",
                "leave-dead-cart discipline",
                "route timing",
                "split punishment",
            },
            corpusMinimum = { replays = 10, goldenLabels = 10, outcomeReviews = 10, adversarialCases = 5 },
        },
        DEEPHAUL = {
            mapKey = "DEEPHAUL",
            title = "Deephaul Ravine",
            short = "DHR",
            family = "CART",
            maxScore = 1500,
            maxObjectives = 2,
            decisionModel = "escort ours, delay theirs, use crystal only for leverage",
            primaryQuestions = {
                "Does our cart remain covered if crystal is contested?",
                "Is the enemy cart stoppable before next checkpoint?",
                "Which team gains more from crystal now?",
            },
            benchmarkFocus = {
                "cart coverage",
                "delay team timing",
                "crystal opportunity cost",
                "checkpoint denial",
            },
            corpusMinimum = { replays = 10, goldenLabels = 10, outcomeReviews = 10, adversarialCases = 5 },
        },
        SEETHING = {
            mapKey = "SEETHING",
            title = "Seething Shore",
            short = "SHORE",
            family = "RESOURCE",
            maxScore = 1500,
            maxObjectives = 1,
            decisionModel = "reach next spawn first, cap cleanly, leave exhausted nodes",
            primaryQuestions = {
                "Where is the next real spawn race?",
                "Can we split without losing the cap channel?",
                "When is the current node already dead value?",
            },
            benchmarkFocus = {
                "spawn race prediction",
                "channel protection",
                "dead-node exit timing",
                "split discipline",
            },
            corpusMinimum = { replays = 10, goldenLabels = 10, outcomeReviews = 10, adversarialCases = 5 },
        },
    },
}

KWR.RBGMapProfiles = RBGMapProfiles

function RBGMapProfiles:Get(mapKey)
    return self.maps[mapKey]
end

function RBGMapProfiles:All()
    return self.maps
end

function RBGMapProfiles:Count()
    local count = 0
    for _ in pairs(self.maps) do
        count = count + 1
    end
    return count
end

function RBGMapProfiles:Summary()
    return {
        maps = self:Count(),
        doctrineLayers = #(self.shared.doctrineLayers or {}),
        sensorFamilies = #(self.shared.sensorFamilies or {}),
        decisionAxes = #(self.shared.decisionAxes or {}),
        corpusLayers = #(self.shared.corpusLayers or {}),
    }
end

KWR:RegisterModule("RBGMapProfiles", RBGMapProfiles)