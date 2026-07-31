local _, KWR = ...

local ScenarioAdversarialCalibration = {}
KWR.ScenarioAdversarialCalibration = ScenarioAdversarialCalibration

local phaseIndex = nil

local DATA = {
    maps = {
        ARATHI = {
            adversarialCases = 20,
            branchFamilies = {
                bait = 8,
                collapse = 4,
                deny = 12,
                hold = 11,
                late_game_score_protection = 3,
                recover = 5,
                rotate = 13,
                split = 4,
            },
            doctrineComparisons = {
                ARATHI_BAIT_VS_FRONTDOOR = 4,
                ARATHI_COLLAPSE_VS_SPLIT = 4,
                ARATHI_CONVERT_VS_GREED = 7,
                ARATHI_DENY_VS_TRADE = 16,
                ARATHI_HOLD_VS_ROTATE = 8,
                ARATHI_LATE_PROTECT_VS_PRESS = 3,
                ARATHI_RECOVER_VS_TRICKLE = 5,
            },
            doctrineResponses = {
                ARATHI_RESP_BAIT_SHOW = 8,
                ARATHI_RESP_COLLAPSE_CONNECT = 4,
                ARATHI_RESP_DENY_TRADE = 16,
                ARATHI_RESP_ESCORT_SHELL = 4,
                ARATHI_RESP_LATE_GREED = 3,
                ARATHI_RESP_RECOVER_REBAIT = 5,
                ARATHI_RESP_SPLIT_PRESSURE = 4,
            },
            forbiddenCommits = {
                Capacity = 4,
                Count = 1,
                IsFixedSize = false,
                IsReadOnly = false,
                IsSynchronized = false,
                SyncRoot = {},
            },
            mapKey = "ARATHI",
            mapProfile = "ab_standard",
            phaseSummaries = {
                ENDGAME = {
                    adversarialCases = 3,
                    branchFamilies = {
                        deny = 3,
                        hold = 3,
                        late_game_score_protection = 3,
                    },
                    doctrineComparisons = {
                        ARATHI_CONVERT_VS_GREED = 3,
                        ARATHI_DENY_VS_TRADE = 3,
                        ARATHI_LATE_PROTECT_VS_PRESS = 3,
                    },
                    doctrineResponses = {
                        ARATHI_RESP_DENY_TRADE = 3,
                        ARATHI_RESP_LATE_GREED = 3,
                    },
                    forbiddenCommits = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    phase = "ENDGAME",
                    safeCounterPatterns = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    scenarios = 3,
                    truthDisciplinePatterns = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    truthRisk = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    truthStress = {
                        ADVERSARIAL = 3,
                    },
                },
                OPENING = {
                    adversarialCases = 4,
                    branchFamilies = {
                        bait = 4,
                        hold = 4,
                        rotate = 4,
                    },
                    doctrineComparisons = {
                        ARATHI_DENY_VS_TRADE = 4,
                        ARATHI_HOLD_VS_ROTATE = 4,
                    },
                    doctrineResponses = {
                        ARATHI_RESP_BAIT_SHOW = 4,
                        ARATHI_RESP_DENY_TRADE = 4,
                    },
                    forbiddenCommits = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    phase = "OPENING",
                    safeCounterPatterns = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    scenarios = 4,
                    truthDisciplinePatterns = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    truthRisk = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    truthStress = {
                        ADVERSARIAL = 4,
                    },
                },
                PRESSURE = {
                    adversarialCases = 4,
                    branchFamilies = {
                        bait = 4,
                        collapse = 4,
                        split = 4,
                    },
                    doctrineComparisons = {
                        ARATHI_BAIT_VS_FRONTDOOR = 4,
                        ARATHI_COLLAPSE_VS_SPLIT = 4,
                        ARATHI_CONVERT_VS_GREED = 4,
                    },
                    doctrineResponses = {
                        ARATHI_RESP_COLLAPSE_CONNECT = 4,
                        ARATHI_RESP_ESCORT_SHELL = 4,
                        ARATHI_RESP_SPLIT_PRESSURE = 4,
                    },
                    forbiddenCommits = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    phase = "PRESSURE",
                    safeCounterPatterns = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    scenarios = 4,
                    truthDisciplinePatterns = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    truthRisk = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    truthStress = {
                        ADVERSARIAL = 4,
                    },
                },
                RECOVERY = {
                    adversarialCases = 5,
                    branchFamilies = {
                        deny = 5,
                        recover = 5,
                        rotate = 5,
                    },
                    doctrineComparisons = {
                        ARATHI_DENY_VS_TRADE = 5,
                        ARATHI_RECOVER_VS_TRICKLE = 5,
                    },
                    doctrineResponses = {
                        ARATHI_RESP_DENY_TRADE = 5,
                        ARATHI_RESP_RECOVER_REBAIT = 5,
                    },
                    forbiddenCommits = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    phase = "RECOVERY",
                    safeCounterPatterns = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    scenarios = 5,
                    truthDisciplinePatterns = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    truthRisk = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    truthStress = {
                        ADVERSARIAL = 5,
                    },
                },
                STABILIZE = {
                    adversarialCases = 4,
                    branchFamilies = {
                        deny = 4,
                        hold = 4,
                        rotate = 4,
                    },
                    doctrineComparisons = {
                        ARATHI_DENY_VS_TRADE = 4,
                        ARATHI_HOLD_VS_ROTATE = 4,
                    },
                    doctrineResponses = {
                        ARATHI_RESP_BAIT_SHOW = 4,
                        ARATHI_RESP_DENY_TRADE = 4,
                    },
                    forbiddenCommits = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    phase = "STABILIZE",
                    safeCounterPatterns = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    scenarios = 4,
                    truthDisciplinePatterns = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    truthRisk = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    truthStress = {
                        ADVERSARIAL = 4,
                    },
                },
            },
            safeCounterPatterns = {
                Capacity = 4,
                Count = 1,
                IsFixedSize = false,
                IsReadOnly = false,
                IsSynchronized = false,
                SyncRoot = {},
            },
            scenarios = 20,
            truthDisciplinePatterns = {
                Capacity = 4,
                Count = 1,
                IsFixedSize = false,
                IsReadOnly = false,
                IsSynchronized = false,
                SyncRoot = {},
            },
            truthRisk = {
                Capacity = 4,
                Count = 1,
                IsFixedSize = false,
                IsReadOnly = false,
                IsSynchronized = false,
                SyncRoot = {},
            },
            truthStress = {
                ADVERSARIAL = 20,
            },
        },
        DEEPHAUL = {
            adversarialCases = 20,
            branchFamilies = {
                bait = 4,
                collapse = 4,
                deny = 8,
                escort = 11,
                hold = 4,
                late_game_score_protection = 3,
                recover = 5,
                rotate = 17,
                split = 4,
            },
            doctrineComparisons = {
                DEEPHAUL_BAIT_VS_FRONTDOOR = 4,
                DEEPHAUL_COLLAPSE_VS_SPLIT = 4,
                DEEPHAUL_CONVERT_VS_GREED = 7,
                DEEPHAUL_DENY_VS_TRADE = 8,
                DEEPHAUL_ESCORT_VS_CHASE = 13,
                DEEPHAUL_HOLD_VS_ROTATE = 8,
                DEEPHAUL_LATE_PROTECT_VS_PRESS = 3,
                DEEPHAUL_RECOVER_VS_TRICKLE = 5,
            },
            doctrineResponses = {
                DEEPHAUL_RESP_COLLAPSE_CONNECT = 4,
                DEEPHAUL_RESP_DENY_TRADE = 16,
                DEEPHAUL_RESP_ESCORT_SHELL = 17,
                DEEPHAUL_RESP_LATE_GREED = 3,
                DEEPHAUL_RESP_RECOVER_REBAIT = 5,
                DEEPHAUL_RESP_SPLIT_PRESSURE = 4,
            },
            forbiddenCommits = {
                Capacity = 4,
                Count = 1,
                IsFixedSize = false,
                IsReadOnly = false,
                IsSynchronized = false,
                SyncRoot = {},
            },
            mapKey = "DEEPHAUL",
            mapProfile = "dhr_standard",
            phaseSummaries = {
                ENDGAME = {
                    adversarialCases = 3,
                    branchFamilies = {
                        deny = 3,
                        escort = 3,
                        late_game_score_protection = 3,
                    },
                    doctrineComparisons = {
                        DEEPHAUL_CONVERT_VS_GREED = 3,
                        DEEPHAUL_DENY_VS_TRADE = 3,
                        DEEPHAUL_LATE_PROTECT_VS_PRESS = 3,
                    },
                    doctrineResponses = {
                        DEEPHAUL_RESP_DENY_TRADE = 3,
                        DEEPHAUL_RESP_LATE_GREED = 3,
                    },
                    forbiddenCommits = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    phase = "ENDGAME",
                    safeCounterPatterns = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    scenarios = 3,
                    truthDisciplinePatterns = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    truthRisk = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    truthStress = {
                        ADVERSARIAL = 3,
                    },
                },
                OPENING = {
                    adversarialCases = 4,
                    branchFamilies = {
                        escort = 4,
                        rotate = 4,
                        split = 4,
                    },
                    doctrineComparisons = {
                        DEEPHAUL_ESCORT_VS_CHASE = 4,
                        DEEPHAUL_HOLD_VS_ROTATE = 4,
                    },
                    doctrineResponses = {
                        DEEPHAUL_RESP_DENY_TRADE = 4,
                        DEEPHAUL_RESP_ESCORT_SHELL = 4,
                    },
                    forbiddenCommits = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    phase = "OPENING",
                    safeCounterPatterns = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    scenarios = 4,
                    truthDisciplinePatterns = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    truthRisk = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    truthStress = {
                        ADVERSARIAL = 4,
                    },
                },
                PRESSURE = {
                    adversarialCases = 4,
                    branchFamilies = {
                        bait = 4,
                        collapse = 4,
                        rotate = 4,
                    },
                    doctrineComparisons = {
                        DEEPHAUL_BAIT_VS_FRONTDOOR = 4,
                        DEEPHAUL_COLLAPSE_VS_SPLIT = 4,
                        DEEPHAUL_CONVERT_VS_GREED = 4,
                    },
                    doctrineResponses = {
                        DEEPHAUL_RESP_COLLAPSE_CONNECT = 4,
                        DEEPHAUL_RESP_ESCORT_SHELL = 4,
                        DEEPHAUL_RESP_SPLIT_PRESSURE = 4,
                    },
                    forbiddenCommits = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    phase = "PRESSURE",
                    safeCounterPatterns = {
                        Capacity = 4,
                        Count = 1,
                        IsFixedSize = false,
                        IsReadOnly = false,
                        IsSynchronized = false,
                        SyncRoot = {},
                    },
                    scenarios = 4,
                    truthDisciplinePatterns = {
                        Capacity = 4,
                …98243 tokens truncated…_SPLIT = 1,
                WSG_CONVERT_VS_GREED = 1,
            },
            doctrineResponses = {
                WSG_RESP_COLLAPSE_CONNECT = 1,
                WSG_RESP_RETURN_WINDOW = 1,
                WSG_RESP_SPLIT_PRESSURE = 1,
            },
            escalateWhen = "Escalate only when battlefield truth becomes explicit and the scoring path stays covered.",
            forbiddenCommit = "CALL:FULL_COMMIT",
            mapKey = "WSG",
            mapProfile = "wsg_standard",
            mustStay = {
                "our_fc",
            },
            phase = "PRESSURE",
            safeCounterPatterns = {
                "preserve the safer path until battlefield truth improves.",
            },
            safeFallbackAction = "CALL:HOLD",
            safePrimaryAction = "PLAN:CHECK",
            scenarioId = "wsg-pressure-efc-stack",
            truthDisciplinePatterns = {
                "Protect the score floor and refuse full-commit calls from partial truth.",
            },
            truthRisk = "LOW",
            truthStress = {
                ADVERSARIAL = 1,
            },
        },
        ["wsg-pressure-fake-tunnel-swap"] = {
            adversarialCases = 1,
            branchFamilies = {
                bait = 1,
                collapse = 1,
                return_window = 1,
            },
            disciplineRule = "Do not full send from degraded truth; protect the score floor first.",
            doctrineComparisons = {
                WSG_BAIT_VS_FRONTDOOR = 1,
                WSG_COLLAPSE_VS_SPLIT = 1,
                WSG_CONVERT_VS_GREED = 1,
            },
            doctrineResponses = {
                WSG_RESP_COLLAPSE_CONNECT = 1,
                WSG_RESP_RETURN_WINDOW = 1,
                WSG_RESP_SPLIT_PRESSURE = 1,
            },
            escalateWhen = "Escalate only when battlefield truth becomes explicit and the scoring path stays covered.",
            forbiddenCommit = "CALL:FULL_COMMIT",
            mapKey = "WSG",
            mapProfile = "wsg_standard",
            mustStay = {
                "our_fc",
            },
            phase = "PRESSURE",
            safeCounterPatterns = {
                "preserve the safer path until battlefield truth improves.",
            },
            safeFallbackAction = "CALL:HOLD",
            safePrimaryAction = "PLAN:CHECK",
            scenarioId = "wsg-pressure-fake-tunnel-swap",
            truthDisciplinePatterns = {
                "Protect the score floor and refuse full-commit calls from partial truth.",
            },
            truthRisk = "LOW",
            truthStress = {
                ADVERSARIAL = 1,
            },
        },
        ["wsg-pressure-isolate-healer-line"] = {
            adversarialCases = 1,
            branchFamilies = {
                bait = 1,
                collapse = 1,
                return_window = 1,
            },
            disciplineRule = "Do not full send from degraded truth; protect the score floor first.",
            doctrineComparisons = {
                WSG_BAIT_VS_FRONTDOOR = 1,
                WSG_COLLAPSE_VS_SPLIT = 1,
                WSG_CONVERT_VS_GREED = 1,
            },
            doctrineResponses = {
                WSG_RESP_COLLAPSE_CONNECT = 1,
                WSG_RESP_RETURN_WINDOW = 1,
                WSG_RESP_SPLIT_PRESSURE = 1,
            },
            escalateWhen = "Escalate only when battlefield truth becomes explicit and the scoring path stays covered.",
            forbiddenCommit = "CALL:FULL_COMMIT",
            mapKey = "WSG",
            mapProfile = "wsg_standard",
            mustStay = {
                "our_fc",
            },
            phase = "PRESSURE",
            safeCounterPatterns = {
                "preserve the safer path until battlefield truth improves.",
            },
            safeFallbackAction = "CALL:HOLD",
            safePrimaryAction = "PLAN:CHECK",
            scenarioId = "wsg-pressure-isolate-healer-line",
            truthDisciplinePatterns = {
                "Protect the score floor and refuse full-commit calls from partial truth.",
            },
            truthRisk = "LOW",
            truthStress = {
                ADVERSARIAL = 1,
            },
        },
        ["wsg-pressure-route-denial"] = {
            adversarialCases = 1,
            branchFamilies = {
                bait = 1,
                collapse = 1,
                return_window = 1,
            },
            disciplineRule = "Do not full send from degraded truth; protect the score floor first.",
            doctrineComparisons = {
                WSG_BAIT_VS_FRONTDOOR = 1,
                WSG_COLLAPSE_VS_SPLIT = 1,
                WSG_CONVERT_VS_GREED = 1,
            },
            doctrineResponses = {
                WSG_RESP_COLLAPSE_CONNECT = 1,
                WSG_RESP_RETURN_WINDOW = 1,
                WSG_RESP_SPLIT_PRESSURE = 1,
            },
            escalateWhen = "Escalate only when battlefield truth becomes explicit and the scoring path stays covered.",
            forbiddenCommit = "CALL:FULL_COMMIT",
            mapKey = "WSG",
            mapProfile = "wsg_standard",
            mustStay = {
                "our_fc",
            },
            phase = "PRESSURE",
            safeCounterPatterns = {
                "preserve the safer path until battlefield truth improves.",
            },
            safeFallbackAction = "CALL:HOLD",
            safePrimaryAction = "PLAN:CHECK",
            scenarioId = "wsg-pressure-route-denial",
            truthDisciplinePatterns = {
                "Protect the score floor and refuse full-commit calls from partial truth.",
            },
            truthRisk = "LOW",
            truthStress = {
                ADVERSARIAL = 1,
            },
        },
        ["wsg-recovery-after-failed-return"] = {
            adversarialCases = 1,
            branchFamilies = {
                deny = 1,
                escort = 1,
                recover = 1,
            },
            disciplineRule = "Do not full send from degraded truth; protect the score floor first.",
            doctrineComparisons = {
                WSG_DENY_VS_TRADE = 1,
                WSG_ESCORT_VS_CHASE = 1,
                WSG_RECOVER_VS_TRICKLE = 1,
            },
            doctrineResponses = {
                WSG_RESP_DENY_TRADE = 1,
                WSG_RESP_ESCORT_SHELL = 1,
                WSG_RESP_RECOVER_REBAIT = 1,
            },
            escalateWhen = "Escalate only when battlefield truth becomes explicit and the scoring path stays covered.",
            forbiddenCommit = "CALL:FULL_COMMIT",
            mapKey = "WSG",
            mapProfile = "wsg_standard",
            mustStay = {
                "our_fc",
            },
            phase = "RECOVERY",
            safeCounterPatterns = {
                "preserve the safer path until battlefield truth improves.",
            },
            safeFallbackAction = "CALL:HOLD",
            safePrimaryAction = "PLAN:CHECK",
            scenarioId = "wsg-recovery-after-failed-return",
            truthDisciplinePatterns = {
                "Protect the score floor and refuse full-commit calls from partial truth.",
            },
            truthRisk = "LOW",
            truthStress = {
                ADVERSARIAL = 1,
            },
        },
        ["wsg-recovery-post-wipe"] = {
            adversarialCases = 1,
            branchFamilies = {
                deny = 1,
                escort = 1,
                recover = 1,
            },
            disciplineRule = "Do not full send from degraded truth; protect the score floor first.",
            doctrineComparisons = {
                WSG_DENY_VS_TRADE = 1,
                WSG_ESCORT_VS_CHASE = 1,
                WSG_RECOVER_VS_TRICKLE = 1,
            },
            doctrineResponses = {
                WSG_RESP_DENY_TRADE = 1,
                WSG_RESP_ESCORT_SHELL = 1,
                WSG_RESP_RECOVER_REBAIT = 1,
            },
            escalateWhen = "Escalate only when battlefield truth becomes explicit and the scoring path stays covered.",
            forbiddenCommit = "CALL:FULL_COMMIT",
            mapKey = "WSG",
            mapProfile = "wsg_standard",
            mustStay = {
                "our_fc",
            },
            phase = "RECOVERY",
            safeCounterPatterns = {
                "preserve the safer path until battlefield truth improves.",
            },
            safeFallbackAction = "CALL:HOLD",
            safePrimaryAction = "PLAN:CHECK",
            scenarioId = "wsg-recovery-post-wipe",
            truthDisciplinePatterns = {
                "Protect the score floor and refuse full-commit calls from partial truth.",
            },
            truthRisk = "LOW",
            truthStress = {
                ADVERSARIAL = 1,
            },
        },
        ["wsg-recovery-rebuild-peel"] = {
            adversarialCases = 1,
            branchFamilies = {
                deny = 1,
                escort = 1,
                recover = 1,
            },
            disciplineRule = "Do not full send from degraded truth; protect the score floor first.",
            doctrineComparisons = {
                WSG_DENY_VS_TRADE = 1,
                WSG_ESCORT_VS_CHASE = 1,
                WSG_RECOVER_VS_TRICKLE = 1,
            },
            doctrineResponses = {
                WSG_RESP_DENY_TRADE = 1,
                WSG_RESP_ESCORT_SHELL = 1,
                WSG_RESP_RECOVER_REBAIT = 1,
            },
            escalateWhen = "Escalate only when battlefield truth becomes explicit and the scoring path stays covered.",
            forbiddenCommit = "CALL:FULL_COMMIT",
            mapKey = "WSG",
            mapProfile = "wsg_standard",
            mustStay = {
                "our_fc",
            },
            phase = "RECOVERY",
            safeCounterPatterns = {
                "preserve the safer path until battlefield truth improves.",
            },
            safeFallbackAction = "CALL:HOLD",
            safePrimaryAction = "PLAN:CHECK",
            scenarioId = "wsg-recovery-rebuild-peel",
            truthDisciplinePatterns = {
                "Protect the score floor and refuse full-commit calls from partial truth.",
            },
            truthRisk = "LOW",
            truthStress = {
                ADVERSARIAL = 1,
            },
        },
        ["wsg-recovery-score-floor"] = {
            adversarialCases = 1,
            branchFamilies = {
                deny = 1,
                escort = 1,
                recover = 1,
            },
            disciplineRule = "Do not full send from degraded truth; protect the score floor first.",
            doctrineComparisons = {
                WSG_DENY_VS_TRADE = 1,
                WSG_ESCORT_VS_CHASE = 1,
                WSG_RECOVER_VS_TRICKLE = 1,
            },
            doctrineResponses = {
                WSG_RESP_DENY_TRADE = 1,
                WSG_RESP_ESCORT_SHELL = 1,
                WSG_RESP_RECOVER_REBAIT = 1,
            },
            escalateWhen = "Escalate only when battlefield truth becomes explicit and the scoring path stays covered.",
            forbiddenCommit = "CALL:FULL_COMMIT",
            mapKey = "WSG",
            mapProfile = "wsg_standard",
            mustStay = {
                "our_fc",
            },
            phase = "RECOVERY",
            safeCounterPatterns = {
                "preserve the safer path until battlefield truth improves.",
            },
            safeFallbackAction = "CALL:HOLD",
            safePrimaryAction = "PLAN:CHECK",
            scenarioId = "wsg-recovery-score-floor",
            truthDisciplinePatterns = {
                "Protect the score floor and refuse full-commit calls from partial truth.",
            },
            truthRisk = "LOW",
            truthStress = {
                ADVERSARIAL = 1,
            },
        },
        ["wsg-stabilize-escort-shell"] = {
            adversarialCases = 1,
            branchFamilies = {
                deny = 1,
                escort = 1,
                hold = 1,
            },
            disciplineRule = "Do not full send from degraded truth; protect the score floor first.",
            doctrineComparisons = {
                WSG_ESCORT_VS_CHASE = 1,
                WSG_HOLD_VS_ROTATE = 1,
            },
            doctrineResponses = {
                WSG_RESP_DENY_TRADE = 1,
                WSG_RESP_ESCORT_SHELL = 1,
            },
            escalateWhen = "Escalate only when battlefield truth becomes explicit and the scoring path stays covered.",
            forbiddenCommit = "CALL:FULL_COMMIT",
            mapKey = "WSG",
            mapProfile = "wsg_standard",
            mustStay = {
                "our_fc",
            },
            phase = "STABILIZE",
            safeCounterPatterns = {
                "preserve the safer path until battlefield truth improves.",
            },
            safeFallbackAction = "CALL:HOLD",
            safePrimaryAction = "PLAN:CHECK",
            scenarioId = "wsg-stabilize-escort-shell",
            truthDisciplinePatterns = {
                "Protect the score floor and refuse full-commit calls from partial truth.",
            },
            truthRisk = "LOW",
            truthStress = {
                ADVERSARIAL = 1,
            },
        },
        ["wsg-stabilize-reinforce-timing"] = {
            adversarialCases = 1,
            branchFamilies = {
                deny = 1,
                escort = 1,
                hold = 1,
            },
            disciplineRule = "Do not full send from degraded truth; protect the score floor first.",
            doctrineComparisons = {
                WSG_ESCORT_VS_CHASE = 1,
                WSG_HOLD_VS_ROTATE = 1,
            },
            doctrineResponses = {
                WSG_RESP_DENY_TRADE = 1,
                WSG_RESP_ESCORT_SHELL = 1,
            },
            escalateWhen = "Escalate only when battlefield truth becomes explicit and the scoring path stays covered.",
            forbiddenCommit = "CALL:FULL_COMMIT",
            mapKey = "WSG",
            mapProfile = "wsg_standard",
            mustStay = {
                "our_fc",
            },
            phase = "STABILIZE",
            safeCounterPatterns = {
                "preserve the safer path until battlefield truth improves.",
            },
            safeFallbackAction = "CALL:HOLD",
            safePrimaryAction = "PLAN:CHECK",
            scenarioId = "wsg-stabilize-reinforce-timing",
            truthDisciplinePatterns = {
                "Protect the score floor and refuse full-commit calls from partial truth.",
            },
            truthRisk = "LOW",
            truthStress = {
                ADVERSARIAL = 1,
            },
        },
        ["wsg-stabilize-trade-clock"] = {
            adversarialCases = 1,
            branchFamilies = {
                deny = 1,
                escort = 1,
                hold = 1,
            },
            disciplineRule = "Do not full send from degraded truth; protect the score floor first.",
            doctrineComparisons = {
                WSG_ESCORT_VS_CHASE = 1,
                WSG_HOLD_VS_ROTATE = 1,
            },
            doctrineResponses = {
                WSG_RESP_DENY_TRADE = 1,
                WSG_RESP_ESCORT_SHELL = 1,
            },
            escalateWhen = "Escalate only when battlefield truth becomes explicit and the scoring path stays covered.",
            forbiddenCommit = "CALL:FULL_COMMIT",
            mapKey = "WSG",
            mapProfile = "wsg_standard",
            mustStay = {
                "our_fc",
            },
            phase = "STABILIZE",
            safeCounterPatterns = {
                "preserve the safer path until battlefield truth improves.",
            },
            safeFallbackAction = "CALL:HOLD",
            safePrimaryAction = "PLAN:CHECK",
            scenarioId = "wsg-stabilize-trade-clock",
            truthDisciplinePatterns = {
                "Protect the score floor and refuse full-commit calls from partial truth.",
            },
            truthRisk = "LOW",
            truthStress = {
                ADVERSARIAL = 1,
            },
        },
        ["wsg-stabilize-turtle-denial"] = {
            adversarialCases = 1,
            branchFamilies = {
                deny = 1,
                escort = 1,
                hold = 1,
            },
            disciplineRule = "Do not full send from degraded truth; protect the score floor first.",
            doctrineComparisons = {
                WSG_ESCORT_VS_CHASE = 1,
                WSG_HOLD_VS_ROTATE = 1,
            },
            doctrineResponses = {
                WSG_RESP_DENY_TRADE = 1,
                WSG_RESP_ESCORT_SHELL = 1,
            },
            escalateWhen = "Escalate only when battlefield truth becomes explicit and the scoring path stays covered.",
            forbiddenCommit = "CALL:FULL_COMMIT",
            mapKey = "WSG",
            mapProfile = "wsg_standard",
            mustStay = {
                "our_fc",
            },
            phase = "STABILIZE",
            safeCounterPatterns = {
                "preserve the safer path until battlefield truth improves.",
            },
            safeFallbackAction = "CALL:HOLD",
            safePrimaryAction = "PLAN:CHECK",
            scenarioId = "wsg-stabilize-turtle-denial",
            truthDisciplinePatterns = {
                "Protect the score floor and refuse full-commit calls from partial truth.",
            },
            truthRisk = "LOW",
            truthStress = {
                ADVERSARIAL = 1,
            },
        },
    },
    shared = {
        disciplinePrinciples = {
            anchorCoverage = "Keep required defenders or carrier support planted until truth improves.",
            forbiddenCommit = "Do not full-commit from contradictory or incomplete public facts.",
            safeFallback = "Fallback to HOLD or CHECK before expanding from partial truth.",
            safePrimary = "Prefer the smallest legal action that preserves the score path.",
        },
        minimumAdversarialCases = 1,
    },
}

function ScenarioAdversarialCalibration:Count()
    local count = 0
    for _ in pairs(DATA.scenarios or {}) do count = count + 1 end
    return count
end

function ScenarioAdversarialCalibration:Get(scenarioID)
    local row = DATA.scenarios and DATA.scenarios[scenarioID]
    return row and KWR.Util:Copy(row) or nil
end

function ScenarioAdversarialCalibration:GetMapSummary(mapKey)
    mapKey = KWR.Util:Upper(mapKey, nil, 24)
    local row = mapKey and DATA.maps and DATA.maps[mapKey] or nil
    return row and KWR.Util:Copy(row) or nil
end

function ScenarioAdversarialCalibration:GetMapPhaseSummary(mapKey, phase)
    mapKey = KWR.Util:Upper(mapKey, nil, 24)
    phase = KWR.Util:Upper(phase, nil, 24)
    local row = mapKey and phase and DATA.maps and DATA.maps[mapKey]
    row = row and row.phaseSummaries and row.phaseSummaries[phase] or nil
    return row and KWR.Util:Copy(row) or nil
end

function ScenarioAdversarialCalibration:GetByMapAndPhase(mapKey, phase)
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

function ScenarioAdversarialCalibration:Shared()
    return KWR.Util:Copy(DATA.shared or {})
end

KWR:RegisterModule("ScenarioAdversarialCalibration", ScenarioAdversarialCalibration)