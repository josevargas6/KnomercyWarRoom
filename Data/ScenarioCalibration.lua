local _, KWR = ...

local ScenarioCalibration = {}
KWR.ScenarioCalibration = ScenarioCalibration

local phaseIndex = nil

local DATA = {
    maps = {
        ARATHI = {
            branchFamilies = {
                bait = 80,
                collapse = 40,
                deny = 120,
                hold = 110,
                late_game_score_protection = 30,
                recover = 50,
                rotate = 130,
                split = 40,
            },
            doctrineComparisons = {
                ARATHI_BAIT_VS_FRONTDOOR = 40,
                ARATHI_COLLAPSE_VS_SPLIT = 40,
                ARATHI_CONVERT_VS_GREED = 70,
                ARATHI_DENY_VS_TRADE = 160,
                ARATHI_HOLD_VS_ROTATE = 80,
                ARATHI_LATE_PROTECT_VS_PRESS = 30,
                ARATHI_RECOVER_VS_TRICKLE = 50,
            },
            doctrineResponses = {
                ARATHI_RESP_BAIT_SHOW = 80,
                ARATHI_RESP_COLLAPSE_CONNECT = 40,
                ARATHI_RESP_DENY_TRADE = 160,
                ARATHI_RESP_ESCORT_SHELL = 40,
                ARATHI_RESP_LATE_GREED = 30,
                ARATHI_RESP_RECOVER_REBAIT = 50,
                ARATHI_RESP_SPLIT_PRESSURE = 40,
            },
            expectedEnemyCounters = {
                Capacity = 4,
                Count = 4,
                IsFixedSize = false,
                IsReadOnly = false,
                IsSynchronized = false,
                SyncRoot = {},
            },
            invalidationSignals = {
                Capacity = 16,
                Count = 10,
                IsFixedSize = false,
                IsReadOnly = false,
                IsSynchronized = false,
                SyncRoot = {},
            },
            legalSignals = {
                Capacity = 16,
                Count = 15,
                IsFixedSize = false,
                IsReadOnly = false,
                IsSynchronized = false,
                SyncRoot = {},
            },
            lessonPatterns = {
                Capacity = 8,
                Count = 5,
                IsFixedSize = false,
                IsReadOnly = false,
                IsSynchronized = false,
                SyncRoot = {},
            },
            losses = 0,
            mapKey = "ARATHI",
            mapProfile = "ab_standard",
            outcomeDrivers = {
                ENEMY_COUNTER_WINDOW = 20,
                EXECUTION_BREAK = 20,
                LATE_GAME_PROTECTION = 3,
                LOW_TRUTH_STATE = 20,
                OPENING_CONTROL = 4,
                REINFORCED_LINE = 20,
                RESET_DISCIPLINE = 5,
                SHELL_DISCIPLINE = 4,
                WINDOW_CONVERSION = 4,
            },
            phaseSummaries = {
                ENDGAME = {
                    branchFamilies = {
                        deny = 30,
                        hold = 30,
                        late_game_score_protection = 30,
                    },
                    doctrineComparisons = {
                        ARATHI_CONVERT_VS_GREED = 30,
                        ARATHI_DENY_VS_TRADE = 30,
                        ARATHI_LATE_PROTECT_VS_PRESS = 30,
                    },
                    doctrineResponses = {
                        ARATHI_RESP_DENY_TRADE = 30,
                        ARATHI_RESP_LATE_GREED = 30,
                    },
                    expectedEnemyCounters = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    invalidationSignals = {
                        Capacity = 4,
                        Count = 2,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    legalSignals = {
                        Capacity = 4,
                        Count = 3,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    lessonPatterns = {
                        Capacity = 8,
                        Count = 5,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    losses = 0,
                    outcomeDrivers = {
                        ENEMY_COUNTER_WINDOW = 3,
                        EXECUTION_BREAK = 3,
                        LATE_GAME_PROTECTION = 3,
                        LOW_TRUTH_STATE = 3,
                        REINFORCED_LINE = 3,
                    },
                    phase = "ENDGAME",
                    reviewedCases = 15,
                    safeCounterPatterns = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    scenarios = 3,
                    topFailures = {
                        EXECUTION_ERROR = 3,
                    },
                    wins = 15,
                },
                OPENING = {
                    branchFamilies = {
                        bait = 40,
                        hold = 40,
                        rotate = 40,
                    },
                    doctrineComparisons = {
                        ARATHI_DENY_VS_TRADE = 40,
                        ARATHI_HOLD_VS_ROTATE = 40,
                    },
                    doctrineResponses = {
                        ARATHI_RESP_BAIT_SHOW = 40,
                        ARATHI_RESP_DENY_TRADE = 40,
                    },
                    expectedEnemyCounters = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    invalidationSignals = {
                        Capacity = 4,
                        Count = 2,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    legalSignals = {
                        Capacity = 4,
                        Count = 3,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    lessonPatterns = {
                        Capacity = 8,
                        Count = 5,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    losses = 0,
                    outcomeDrivers = {
                        ENEMY_COUNTER_WINDOW = 4,
                        EXECUTION_BREAK = 4,
                        LOW_TRUTH_STATE = 4,
                        OPENING_CONTROL = 4,
                        REINFORCED_LINE = 4,
                    },
                    phase = "OPENING",
                    reviewedCases = 20,
                    safeCounterPatterns = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    scenarios = 4,
                    topFailures = {
                        EXECUTION_ERROR = 4,
                    },
                    wins = 20,
                },
                PRESSURE = {
                    branchFamilies = {
                        bait = 40,
                        collapse = 40,
                        split = 40,
                    },
                    doctrineComparisons = {
                        ARATHI_BAIT_VS_FRONTDOOR = 40,
                        ARATHI_COLLAPSE_VS_SPLIT = 40,
                        ARATHI_CONVERT_VS_GREED = 40,
                    },
                    doctrineResponses = {
                        ARATHI_RESP_COLLAPSE_CONNECT = 40,
                        ARATHI_RESP_ESCORT_SHELL = 40,
                        ARATHI_RESP_SPLIT_PRESSURE = 40,
                    },
                    expectedEnemyCounters = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    invalidationSignals = {
                        Capacity = 4,
                        Count = 2,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    legalSignals = {
                        Capacity = 4,
                        Count = 3,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    lessonPatterns = {
                        Capacity = 8,
                        Count = 5,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    losses = 0,
                    outcomeDrivers = {
                        ENEMY_COUNTER_WINDOW = 4,
                        EXECUTION_BREAK = 4,
                        LOW_TRUTH_STATE = 4,
                        REINFORCED_LINE = 4,
                        WINDOW_CONVERSION = 4,
                    },
                    phase = "PRESSURE",
                    reviewedCases = 20,
                    safeCounterPatterns = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    scenarios = 4,
                    topFailures = {
                        EXECUTION_ERROR = 4,
                    },
                    wins = 20,
                },
                RECOVERY = {
                    branchFamilies = {
                        deny = 50,
                        recover = 50,
                        rotate = 50,
                    },
                    doctrineComparisons = {
                        ARATHI_DENY_VS_TRADE = 50,
                        ARATHI_RECOVER_VS_TRICKLE = 50,
                    },
                    doctrineResponses = {
                        ARATHI_RESP_DENY_TRADE = 50,
                        ARATHI_RESP_RECOVER_REBAIT = 50,
                    },
                    expectedEnemyCounters = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    invalidationSignals = {
                        Capacity = 4,
                        Count = 2,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    legalSignals = {
                        Capacity = 4,
                        Count = 3,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    lessonPatterns = {
                        Capacity = 8,
                        Count = 5,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    losses = 0,
                    outcomeDrivers = {
                        ENEMY_COUNTER_WINDOW = 5,
                        EXECUTION_BREAK = 5,
                        LOW_TRUTH_STATE = 5,
                        REINFORCED_LINE = 5,
                        RESET_DISCIPLINE = 5,
                    },
                    phase = "RECOVERY",
                    reviewedCases = 25,
                    safeCounterPatterns = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    scenarios = 5,
                    topFailures = {
                        EXECUTION_ERROR = 5,
                    },
                    wins = 25,
                },
                STABILIZE = {
                    branchFamilies = {
                        deny = 40,
                        hold = 40,
                        rotate = 40,
                    },
                    doctrineComparisons = {
                        ARATHI_DENY_VS_TRADE = 40,
                        ARATHI_HOLD_VS_ROTATE = 40,
                    },
                    doctrineResponses = {
                        ARATHI_RESP_BAIT_SHOW = 40,
                        ARATHI_RESP_DENY_TRADE = 40,
                    },
                    expectedEnemyCounters = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    invalidationSignals = {
                        Capacity = 4,
                        Count = 2,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    legalSignals = {
                        Capacity = 4,
                        Count = 3,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    lessonPatterns = {
                        Capacity = 8,
                        Count = 5,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    losses = 0,
                    outcomeDrivers = {
                        ENEMY_COUNTER_WINDOW = 4,
                        EXECUTION_BREAK = 4,
                        LOW_TRUTH_STATE = 4,
                        REINFORCED_LINE = 4,
                        SHELL_DISCIPLINE = 4,
                    },
                    phase = "STABILIZE",
                    reviewedCases = 20,
                    safeCounterPatterns = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    scenarios = 4,
                    topFailures = {
                        EXECUTION_ERROR = 4,
                    },
                    wins = 20,
                },
            },
            reviewedCases = 100,
            safeCounterPatterns = {
                Capacity = 4,
                Count = 3,
                IsFixedSize = false,
                IsReadOnly = false,
                IsSynchronized = false,
                SyncRoot = {},
            },
            scenarios = 20,
            topFailures = {
                EXECUTION_ERROR = 20,
            },
            wins = 100,
        },
        DEEPHAUL = {
            branchFamilies = {
                bait = 40,
                collapse = 40,
                deny = 80,
                escort = 110,
                hold = 40,
                late_game_score_protection = 30,
                recover = 50,
                rotate = 170,
                split = 40,
            },
            doctrineComparisons = {
                DEEPHAUL_BAIT_VS_FRONTDOOR = 40,
                DEEPHAUL_COLLAPSE_VS_SPLIT = 40,
                DEEPHAUL_CONVERT_VS_GREED = 70,
                DEEPHAUL_DENY_VS_TRADE = 80,
                DEEPHAUL_ESCORT_VS_CHASE = 130,
                DEEPHAUL_HOLD_VS_ROTATE = 80,
                DEEPHAUL_LATE_PROTECT_VS_PRESS = 30,
                DEEPHAUL_RECOVER_VS_TRICKLE = 50,
            },
            doctrineResponses = {
                DEEPHAUL_RESP_COLLAPSE_CONNECT = 40,
                DEEPHAUL_RESP_DENY_TRADE = 160,
                DEEPHAUL_RESP_ESCORT_SHELL = 170,
                DEEPHAUL_RESP_LATE_GREED = 30,
                DEEPHAUL_RESP_RECOVER_REBAIT = 50,
                DEEPHAUL_RESP_SPLIT_PRESSURE = 40,
            },
            expectedEnemyCounters = {
                Capacity = 8,
                Count = 5,
                IsFixedSize = false,
                IsReadOnly = false,
                IsSynchronized = false,
                SyncRoot = {},
            },
            invalidationSignals = {
                Capacity = 16,
                Count = 10,
                IsFixedSize = false,
                IsReadOnly = false,
                IsSynchronized = false,
                SyncRoot = {},
            },
            legalSignals = {
                Capacity = 16,
                Count = 15,
                IsFixedSize = false,
                IsReadOnly = false,
                IsSynchronized = false,
                SyncRoot = {},
            },
            lessonPatterns = {
                Capacity = 8,
                Count = 5,
                IsFixedSize = false,
                IsReadOnly = false,
                IsSynchronized = false,
                SyncRoot = {},
            },
            losses = 0,
            mapKey = "DEEPHAUL",
            mapProfile = "dhr_standard",
            outcomeDrivers = {
                ENEMY_COUNTER_WINDOW = 20,
                EXECUTION_BREAK = 20,
                LATE_GAME_PROTECTION = 3,
                LOW_TRUTH_STATE = 20,
                OPENING_CONTROL = 4,
                REINFORCED_LINE = 20,
                RESET_DISCIPLINE = 5,
                SHELL_DISCIPLINE = 4,
                WINDOW_CONVERSION = 4,
            },
            phaseSummaries = {
                ENDGAME = {
                    branchFamilies = {
                        deny = 30,
                        escort = 30,
                        late_game_score_protection = 30,
                    },
                    doctrineComparisons = {
                        DEEPHAUL_CONVERT_VS_GREED = 30,
                        DEEPHAUL_DENY_VS_TRADE = 30,
                        DEEPHAUL_LATE…184858 tokens truncated…OVER_VS_TRICKLE = 10,
            },
            doctrineResponses = {
                WSG_RESP_DENY_TRADE = 10,
                WSG_RESP_ESCORT_SHELL = 10,
                WSG_RESP_RECOVER_REBAIT = 10,
            },
            expectedEnemyCounters = {
                "Enemy tries to force panic recommits before the regroup lands.",
            },
            goal = "Stop failed trickle offense.",
            invalidationSignals = {
                "the regroup wave arrives too late",
                "the denial lane is already gone",
            },
            legalSignals = {
                "a regroup wave can still arrive before resolution",
                "the enemy winning lane can still be denied",
                "the rebuild does not expose a worse immediate loss",
            },
            lessonPatterns = {
                "Repeat the reviewed line unless live battlefield truth clearly degrades.",
                "The branch was defensible, but the team cannot trickle or miss the timing.",
                "Reinforced lines should be repeated when support arrives on time.",
                "Respect the counter route and avoid equal split pressure into their preferred branch.",
                "Keep the call reversible until objective and movement truth improve.",
            },
            losses = 0,
            mapKey = "WSG",
            mapProfile = "wsg_standard",
            outcomeDrivers = {
                ENEMY_COUNTER_WINDOW = 1,
                EXECUTION_BREAK = 1,
                LOW_TRUTH_STATE = 1,
                REINFORCED_LINE = 1,
                RESET_DISCIPLINE = 1,
            },
            phase = "RECOVERY",
            primaryClassifications = {
                DECISION_ERROR = 0,
                EXECUTION_ERROR = 1,
                MECHANICAL_LOSS = 0,
                OPPONENT_COUNTER = 1,
                SENSOR_ERROR = 0,
                SUCCESS = 2,
                UNRESOLVED = 1,
            },
            reviewConfidence = "HIGH",
            reviewedCases = 5,
            reviewedVariantShapes = {
                late_clock = 2,
                reinforced_line = 2,
                split_pressure = 2,
                uncertain_window = 2,
            },
            safeCounterPatterns = {
                "protect the scoring package while denying the enemy reset.",
            },
            scenarioId = "wsg-recovery-rebuild-peel",
            summary = "Recover by restoring peel before the next push.",
            topFailure = "EXECUTION_ERROR",
            winRate = 100,
            wins = 5,
        },
        ["wsg-recovery-score-floor"] = {
            branchFamilies = {
                deny = 10,
                escort = 10,
                recover = 10,
            },
            disciplineRule = "Do not trickle or split the hit; arrive on one timing.",
            doctrineComparisons = {
                WSG_DENY_VS_TRADE = 10,
                WSG_ESCORT_VS_CHASE = 10,
                WSG_RECOVER_VS_TRICKLE = 10,
            },
            doctrineResponses = {
                WSG_RESP_DENY_TRADE = 10,
                WSG_RESP_ESCORT_SHELL = 10,
                WSG_RESP_RECOVER_REBAIT = 10,
            },
            expectedEnemyCounters = {
                "Enemy tries to force panic recommits before the regroup lands.",
            },
            goal = "Stay alive on win path while rebuilding the real cap window.",
            invalidationSignals = {
                "the regroup wave arrives too late",
                "the denial lane is already gone",
            },
            legalSignals = {
                "a regroup wave can still arrive before resolution",
                "the enemy winning lane can still be denied",
                "the rebuild does not expose a worse immediate loss",
            },
            lessonPatterns = {
                "Repeat the reviewed line unless live battlefield truth clearly degrades.",
                "The branch was defensible, but the team cannot trickle or miss the timing.",
                "Reinforced lines should be repeated when support arrives on time.",
                "Respect the counter route and avoid equal split pressure into their preferred branch.",
                "Keep the call reversible until objective and movement truth improve.",
            },
            losses = 0,
            mapKey = "WSG",
            mapProfile = "wsg_standard",
            outcomeDrivers = {
                ENEMY_COUNTER_WINDOW = 1,
                EXECUTION_BREAK = 1,
                LOW_TRUTH_STATE = 1,
                REINFORCED_LINE = 1,
                RESET_DISCIPLINE = 1,
            },
            phase = "RECOVERY",
            primaryClassifications = {
                DECISION_ERROR = 0,
                EXECUTION_ERROR = 1,
                MECHANICAL_LOSS = 0,
                OPPONENT_COUNTER = 1,
                SENSOR_ERROR = 0,
                SUCCESS = 2,
                UNRESOLVED = 1,
            },
            reviewConfidence = "HIGH",
            reviewedCases = 5,
            reviewedVariantShapes = {
                late_clock = 2,
                reinforced_line = 2,
                split_pressure = 2,
                uncertain_window = 2,
            },
            safeCounterPatterns = {
                "protect the scoring package while denying the enemy reset.",
            },
            scenarioId = "wsg-recovery-score-floor",
            summary = "Protect the score floor first by stopping the next free enemy grab before chasing a fancy return.",
            topFailure = "EXECUTION_ERROR",
            winRate = 100,
            wins = 5,
        },
        ["wsg-stabilize-escort-shell"] = {
            branchFamilies = {
                deny = 10,
                escort = 10,
                hold = 10,
            },
            disciplineRule = "Do not trickle or split the hit; arrive on one timing.",
            doctrineComparisons = {
                WSG_ESCORT_VS_CHASE = 10,
                WSG_HOLD_VS_ROTATE = 10,
            },
            doctrineResponses = {
                WSG_RESP_DENY_TRADE = 10,
                WSG_RESP_ESCORT_SHELL = 10,
            },
            expectedEnemyCounters = {
                "Enemy tries to peel the planted coverage and create a weak-side break.",
            },
            goal = "Keep defense intact.",
            invalidationSignals = {
                "the shell loses its planted defender",
                "the reserve route is consumed by a higher-value emergency",
            },
            legalSignals = {
                "the current shell still wins the score path",
                "reserve timing remains intact",
                "friendly defenders stay planted on the score floor",
            },
            lessonPatterns = {
                "Repeat the reviewed line unless live battlefield truth clearly degrades.",
                "The branch was defensible, but the team cannot trickle or miss the timing.",
                "Reinforced lines should be repeated when support arrives on time.",
                "Respect the counter route and avoid equal split pressure into their preferred branch.",
                "Keep the call reversible until objective and movement truth improve.",
            },
            losses = 0,
            mapKey = "WSG",
            mapProfile = "wsg_standard",
            outcomeDrivers = {
                ENEMY_COUNTER_WINDOW = 1,
                EXECUTION_BREAK = 1,
                LOW_TRUTH_STATE = 1,
                REINFORCED_LINE = 1,
                SHELL_DISCIPLINE = 1,
            },
            phase = "STABILIZE",
            primaryClassifications = {
                DECISION_ERROR = 0,
                EXECUTION_ERROR = 1,
                MECHANICAL_LOSS = 0,
                OPPONENT_COUNTER = 1,
                SENSOR_ERROR = 0,
                SUCCESS = 2,
                UNRESOLVED = 1,
            },
            reviewConfidence = "HIGH",
            reviewedCases = 5,
            reviewedVariantShapes = {
                late_clock = 2,
                reinforced_line = 2,
                split_pressure = 2,
                uncertain_window = 2,
            },
            safeCounterPatterns = {
                "protect the scoring package while denying the enemy reset.",
            },
            scenarioId = "wsg-stabilize-escort-shell",
            summary = "Protect our FC while building one return wave.",
            topFailure = "EXECUTION_ERROR",
            winRate = 100,
            wins = 5,
        },
        ["wsg-stabilize-reinforce-timing"] = {
            branchFamilies = {
                deny = 10,
                escort = 10,
                hold = 10,
            },
            disciplineRule = "Do not trickle or split the hit; arrive on one timing.",
            doctrineComparisons = {
                WSG_ESCORT_VS_CHASE = 10,
                WSG_HOLD_VS_ROTATE = 10,
            },
            doctrineResponses = {
                WSG_RESP_DENY_TRADE = 10,
                WSG_RESP_ESCORT_SHELL = 10,
            },
            expectedEnemyCounters = {
                "Enemy tries to peel the planted coverage and create a weak-side break.",
            },
            goal = "Keep the shell stable without breaking carrier safety.",
            invalidationSignals = {
                "the shell loses its planted defender",
                "the reserve route is consumed by a higher-value emergency",
            },
            legalSignals = {
                "the current shell still wins the score path",
                "reserve timing remains intact",
                "friendly defenders stay planted on the score floor",
            },
            lessonPatterns = {
                "Repeat the reviewed line unless live battlefield truth clearly degrades.",
                "The branch was defensible, but the team cannot trickle or miss the timing.",
                "Reinforced lines should be repeated when support arrives on time.",
                "Respect the counter route and avoid equal split pressure into their preferred branch.",
                "Keep the call reversible until objective and movement truth improve.",
            },
            losses = 0,
            mapKey = "WSG",
            mapProfile = "wsg_standard",
            outcomeDrivers = {
                ENEMY_COUNTER_WINDOW = 1,
                EXECUTION_BREAK = 1,
                LOW_TRUTH_STATE = 1,
                REINFORCED_LINE = 1,
                SHELL_DISCIPLINE = 1,
            },
            phase = "STABILIZE",
            primaryClassifications = {
                DECISION_ERROR = 0,
                EXECUTION_ERROR = 1,
                MECHANICAL_LOSS = 0,
                OPPONENT_COUNTER = 1,
                SENSOR_ERROR = 0,
                SUCCESS = 2,
                UNRESOLVED = 1,
            },
            reviewConfidence = "HIGH",
            reviewedCases = 5,
            reviewedVariantShapes = {
                late_clock = 2,
                reinforced_line = 2,
                split_pressure = 2,
                uncertain_window = 2,
            },
            safeCounterPatterns = {
                "protect the scoring package while denying the enemy reset.",
            },
            scenarioId = "wsg-stabilize-reinforce-timing",
            summary = "Reinforce the live return lane on the timing that still preserves peel on our FC.",
            topFailure = "EXECUTION_ERROR",
            winRate = 100,
            wins = 5,
        },
        ["wsg-stabilize-trade-clock"] = {
            branchFamilies = {
                deny = 10,
                escort = 10,
                hold = 10,
            },
            disciplineRule = "Do not trickle or split the hit; arrive on one timing.",
            doctrineComparisons = {
                WSG_ESCORT_VS_CHASE = 10,
                WSG_HOLD_VS_ROTATE = 10,
            },
            doctrineResponses = {
                WSG_RESP_DENY_TRADE = 10,
                WSG_RESP_ESCORT_SHELL = 10,
            },
            expectedEnemyCounters = {
                "Enemy tries to peel the planted coverage and create a weak-side break.",
            },
            goal = "Protect the lead without overreacting to fake offense.",
            invalidationSignals = {
                "the shell loses its planted defender",
                "the reserve route is consumed by a higher-value emergency",
            },
            legalSignals = {
                "the current shell still wins the score path",
                "reserve timing remains intact",
                "friendly defenders stay planted on the score floor",
            },
            lessonPatterns = {
                "Repeat the reviewed line unless live battlefield truth clearly degrades.",
                "The branch was defensible, but the team cannot trickle or miss the timing.",
                "Reinforced lines should be repeated when support arrives on time.",
                "Respect the counter route and avoid equal split pressure into their preferred branch.",
                "Keep the call reversible until objective and movement truth improve.",
            },
            losses = 0,
            mapKey = "WSG",
            mapProfile = "wsg_standard",
            outcomeDrivers = {
                ENEMY_COUNTER_WINDOW = 1,
                EXECUTION_BREAK = 1,
                LOW_TRUTH_STATE = 1,
                REINFORCED_LINE = 1,
                SHELL_DISCIPLINE = 1,
            },
            phase = "STABILIZE",
            primaryClassifications = {
                DECISION_ERROR = 0,
                EXECUTION_ERROR = 1,
                MECHANICAL_LOSS = 0,
                OPPONENT_COUNTER = 1,
                SENSOR_ERROR = 0,
                SUCCESS = 2,
                UNRESOLVED = 1,
            },
            reviewConfidence = "HIGH",
            reviewedCases = 5,
            reviewedVariantShapes = {
                late_clock = 2,
                reinforced_line = 2,
                split_pressure = 2,
                uncertain_window = 2,
            },
            safeCounterPatterns = {
                "protect the scoring package while denying the enemy reset.",
            },
            scenarioId = "wsg-stabilize-trade-clock",
            summary = "Allow one low-value cross-map trade only when our carrier shell still keeps the winning clock.",
            topFailure = "EXECUTION_ERROR",
            winRate = 100,
            wins = 5,
        },
        ["wsg-stabilize-turtle-denial"] = {
            branchFamilies = {
                deny = 10,
                escort = 10,
                hold = 10,
            },
            disciplineRule = "Do not trickle or split the hit; arrive on one timing.",
            doctrineComparisons = {
                WSG_ESCORT_VS_CHASE = 10,
                WSG_HOLD_VS_ROTATE = 10,
            },
            doctrineResponses = {
                WSG_RESP_DENY_TRADE = 10,
                WSG_RESP_ESCORT_SHELL = 10,
            },
            expectedEnemyCounters = {
                "Enemy tries to peel the planted coverage and create a weak-side break.",
            },
            goal = "Prevent fake offense from breaking our own carrier first.",
            invalidationSignals = {
                "the shell loses its planted defender",
                "the reserve route is consumed by a higher-value emergency",
            },
            legalSignals = {
                "the current shell still wins the score path",
                "reserve timing remains intact",
                "friendly defenders stay planted on the score floor",
            },
            lessonPatterns = {
                "Repeat the reviewed line unless live battlefield truth clearly degrades.",
                "The branch was defensible, but the team cannot trickle or miss the timing.",
                "Reinforced lines should be repeated when support arrives on time.",
                "Respect the counter route and avoid equal split pressure into their preferred branch.",
                "Keep the call reversible until objective and movement truth improve.",
            },
            losses = 0,
            mapKey = "WSG",
            mapProfile = "wsg_standard",
            outcomeDrivers = {
                ENEMY_COUNTER_WINDOW = 1,
                EXECUTION_BREAK = 1,
                LOW_TRUTH_STATE = 1,
                REINFORCED_LINE = 1,
                SHELL_DISCIPLINE = 1,
            },
            phase = "STABILIZE",
            primaryClassifications = {
                DECISION_ERROR = 0,
                EXECUTION_ERROR = 1,
                MECHANICAL_LOSS = 0,
                OPPONENT_COUNTER = 1,
                SENSOR_ERROR = 0,
                SUCCESS = 2,
                UNRESOLVED = 1,
            },
            reviewConfidence = "HIGH",
            reviewedCases = 5,
            reviewedVariantShapes = {
                late_clock = 2,
                reinforced_line = 2,
                split_pressure = 2,
                uncertain_window = 2,
            },
            safeCounterPatterns = {
                "protect the scoring package while denying the enemy reset.",
            },
            scenarioId = "wsg-stabilize-turtle-denial",
            summary = "Refuse endless tunnel pressure and rebuild a real return shell instead.",
            topFailure = "EXECUTION_ERROR",
            winRate = 100,
            wins = 5,
        },
    },
    shared = {
        classificationGuidance = {
            DECISION_ERROR = "Do not chase side value; protect the real score path first.",
            EXECUTION_ERROR = "Do not trickle or split the hit; arrive on one timing.",
            MECHANICAL_LOSS = "Choose the cleaner line and avoid low-margin overreach.",
            OPPONENT_COUNTER = "Expect the counter route and keep the response reserve intact.",
            SENSOR_ERROR = "Re-verify objective truth before a long move or hard commit.",
            SUCCESS = "Stay on the reviewed line unless live battlefield truth clearly breaks it.",
            UNRESOLVED = "Keep the call reversible until clearer battlefield truth arrives.",
        },
        minimumReviewedCases = 5,
    },
}

function ScenarioCalibration:Count()
    local count = 0
    for _ in pairs(DATA.scenarios or {}) do count = count + 1 end
    return count
end

function ScenarioCalibration:Get(scenarioID)
    local row = DATA.scenarios and DATA.scenarios[scenarioID]
    return row and KWR.Util:Copy(row) or nil
end

function ScenarioCalibration:GetMapSummary(mapKey)
    mapKey = KWR.Util:Upper(mapKey, nil, 24)
    local row = mapKey and DATA.maps and DATA.maps[mapKey] or nil
    return row and KWR.Util:Copy(row) or nil
end

function ScenarioCalibration:GetMapPhaseSummary(mapKey, phase)
    mapKey = KWR.Util:Upper(mapKey, nil, 24)
    phase = KWR.Util:Upper(phase, nil, 24)
    local row = mapKey and phase and DATA.maps and DATA.maps[mapKey]
    row = row and row.phaseSummaries and row.phaseSummaries[phase] or nil
    return row and KWR.Util:Copy(row) or nil
end

function ScenarioCalibration:GetByMapAndPhase(mapKey, phase)
    mapKey = KWR.Util:Upper(mapKey, nil, 24)
    phase = KWR.Util:Upper(phase, nil, 24)
    if not mapKey or not phase then
        return nil
    end
    if not phaseIndex then
        phaseIndex = {}
        for _, row in pairs(DATA.scenarios or {}) do
            if row.mapKey and row.phase then
                phaseIndex[row.mapKey] = phaseIndex[row.mapKey] or {}
                phaseIndex[row.mapKey][row.phase] = row
            end
        end
    end
    local row = phaseIndex[mapKey] and phaseIndex[mapKey][phase] or nil
    return row and KWR.Util:Copy(row) or nil
end

function ScenarioCalibration:Shared()
    return KWR.Util:Copy(DATA.shared or {})
end

KWR:RegisterModule("ScenarioCalibration", ScenarioCalibration)