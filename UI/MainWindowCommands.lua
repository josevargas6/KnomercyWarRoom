local _, KWR = ...

local MainWindowCommands = {}
KWR.MainWindowCommands = MainWindowCommands

function MainWindowCommands:Register(owner, helpers)
    SLASH_KWR1 = "/kwr"
    SlashCmdList.KWR = function(input)
        local rawInput = KWR.Util:Text(input, "", 160)
        input = rawInput:lower()
        -- Compare the command token, rather than doing a plain-text prefix
        -- search.  Plain matching treats '^' literally and also used to make
        -- an unrelated command such as "overrideable" look like an override.
        local commandWord = input:match("^(%S+)") or ""
        if commandWord == "override" then
            local result = KWR.AssignmentOverrides
                and KWR.AssignmentOverrides:HandleSlash(rawInput, KWR.Store:Get())
            if result and result.title and result.text then
                KWR.CopyDialog:ShowText(result.title, result.text, {
                    note = "Manual copy only. Override text stays local unless you copy it yourself.",
                })
            end
            if result and result.message then
                KWR:Print(result.message, true)
            end
            if result and result.changed then
                KWR.MatchRuntime:ForceRefresh("assignment-override")
            end
        elseif input == "delivered" or input:match("^delivered%s") then
            local state = KWR.Store:Get()
            local command = state and state.command
            local token = rawInput:match("^%S+%s+(%S+)$")
            if not token then
                if command and command.commandId then
                    KWR:Print("After calling this to your team: "
                        .. KWR.Util:Text(command.action, "Current call", 120)
                        .. " - confirm with /kwr delivered " .. command.commandId, true)
                else
                    KWR:Print("No live call is available to confirm.", true)
                end
            else
                local changed, message = KWR.Commander:AttestDelivery(state, token,
                    command and command.commandRevision)
                if changed then KWR.MatchRuntime:ForceRefresh("call-delivery") end
                KWR:Print(message, true)
            end
        elseif input == "countdown cancel" then
            KWR.CountdownState:Cancel("MANUAL_CANCEL")
            KWR.MatchRuntime:ForceRefresh("countdown-cancel")
            KWR:Print("Local countdown canceled.", true)
        elseif input == "countdown" or input:match("^countdown%s") then
            local seconds = tonumber(input:match("^countdown%s+(%d+)$"))
            local state = KWR.Store:Get()
            local snapshot = state and state.snapshot
            local started, message = KWR.CountdownState:Start(snapshot,
                snapshot and snapshot.teamfight, seconds)
            if started then KWR.MatchRuntime:ForceRefresh("countdown-start") end
            KWR:Print(message, true)
        elseif input == "" or input == "open" then owner:Toggle()
        elseif input == "map" or input == "tactical" or input == "command" then owner:Show("TACTICAL")
        elseif input == "battlefield" or input == "battlefield map" then
            if KWR.MainWindowLauncher and KWR.MainWindowLauncher.ToggleBattlefieldMap then
                KWR.MainWindowLauncher:ToggleBattlefieldMap()
            else
                KWR:Print("Blizzard's battlefield map is not available yet.", true)
            end
        elseif input == "reporter" or input == "report" then
            KWR:Print("KWR Support View is retired. Use the launcher's OPEN BATTLEFIELD MAP button or /kwr battlefield.", true)
        elseif input == "roster" or input == "combat" then KWR.CombatRoster:Toggle("BOTH")
        elseif input == "teammini" then KWR.CombatRoster:Toggle("TEAM")
        elseif input == "enemymini" then KWR.CombatRoster:Toggle("ENEMY")
        elseif input == "objectives" then owner:Show("OBJECTIVES")
        elseif input == "team" then owner:Show("TEAM")
        elseif input == "enemies" or input == "enemy" then owner:Show("ENEMIES")
        elseif input == "assignments" then owner:Show("ASSIGNMENTS")
        elseif input == "intel" or input == "history" then owner:Show("INTEL")
        elseif input == "aar" then
            owner:Show("INTEL")
            local latest = KWR.AAR:GetLatest()
            KWR:Print(latest and "Latest local team AAR is ready. Use /kwr aar copy."
                or "No completed team AAR is available.", true)
        elseif input == "aar copy" then
            owner:ShowAARExport()
        elseif input == "aar clear" then
            local cleared, message = KWR.AAR:ClearCompleted()
            KWR:Print(cleared and "Completed AAR evidence cleared."
                or (message or "AAR evidence was not cleared."), true)
        elseif input == "purge" or input == "purge tactical" then
            if InCombatLockdown and InCombatLockdown() then
                KWR:Print("Tactical purge is deferred until combat ends.", true)
            else
                if KWR.EnemyIntel and KWR.EnemyIntel.Reset then KWR.EnemyIntel:Reset(nil) end
                if KWR.Reporter and KWR.Reporter.Reset then KWR.Reporter:Reset(nil) end
                if KWR.ObjectiveIntel and KWR.ObjectiveIntel.Reset then KWR.ObjectiveIntel:Reset(nil) end
                if KWR.CombatIntel and KWR.CombatIntel.Reset then KWR.CombatIntel:Reset() end
                if KWR.Strategist then
                    KWR.Strategist.cache = nil
                    KWR.Strategist.executionCache = nil
                end
                KWR:Print("Nonessential tactical caches purged. AAR and learning history preserved.", true)
            end
        elseif input == "preview reporter" or input == "demo reporter"
            or input == "preview support" or input == "demo support" then
            KWR:Print("KWR Support View is retired. Use the launcher's OPEN BATTLEFIELD MAP button or /kwr battlefield.", true)
        elseif input == "preview roster" or input == "demo roster" then
            if helpers.previewAvailable() then
                local state = KWR.Store:Get()
                if state.snapshot.context.inPvP and not state.snapshot.context.preview then
                    KWR:Print("Preview cannot replace live battleground data.", true)
                else
                    KWR.db.profile.preview = true
                    KWR.MatchRuntime:ForceRefresh("preview-roster")
                    KWR.CombatRoster:Show("BOTH")
                    KWR:Print("Preview combat roster enabled. Data is synthetic and NOT LIVE.", true)
                end
            else
                KWR:Print("Preview is available only in the developer build.", true)
            end
        elseif input == "preview all" or input == "demo all" then
            if helpers.previewAvailable() then
                local state = KWR.Store:Get()
                if state.snapshot.context.inPvP and not state.snapshot.context.preview then
                    KWR:Print("Preview cannot replace live battleground data.", true)
                else
                    KWR.db.profile.preview = true
                    KWR.MatchRuntime:ForceRefresh("preview-all")
                    owner:Show("TACTICAL")
                    KWR:Print("Preview enabled: KWR command and roster surfaces use synthetic data. Use /kwr roster to inspect compact frames.", true)
                end
            else
                KWR:Print("Preview is available only in the developer build.", true)
            end
        elseif input == "preview off" or input == "demo off" then
            if helpers.previewAvailable() then
                KWR.db.profile.preview = false
                KWR.MatchRuntime:ForceRefresh("preview-off")
                KWR:Print("Preview disabled. Live battleground data restored when available.", true)
            end
        elseif input == "preview" or input == "demo" then
            if helpers.previewAvailable() then
                owner:TogglePreview()
            else
                KWR:Print("Preview is available only in the developer build.", true)
            end
        elseif input == "hud" then
            if KWR.HUD and KWR.HUD.Toggle then
                KWR.HUD:Toggle()
            else
                KWR:Print("Command center is unavailable; reload the UI after resolving addon errors.", true)
            end
        elseif input == "reportermini" then
            KWR:Print("KWR Support View is retired. Use the launcher's OPEN BATTLEFIELD MAP button or /kwr battlefield.", true)
        elseif input == "copy" then
            KWR.CopyDialog:ShowText("KWR Command Call",
                helpers.manualCommandText(KWR.Store:Get()), {
                    width = 660,
                    height = 350,
                    note = "Full manual call. Review every line, then select and copy it yourself.",
                })
        elseif input == "alts" or input == "alternatives" then
            owner:ShowAlternatives()
        elseif input == "refresh" then KWR.MatchRuntime:ForceRefresh("slash")
        elseif input == "reassess" then KWR.MatchRuntime:Reassess()
        elseif input == "rescan" or input == "scan" or input == "respec" then
            KWR.MatchRuntime:RescanRoster()
        elseif input == "field" or input == "fieldtest" or input == "ready" then
            owner:ArmFieldTest()
        elseif input == "commander" then
            owner:SetFieldReviewContext("Commander")
        elseif input == "spectator" then
            owner:SetFieldReviewContext("Spectator")
        elseif input == "diagnostic" then
            owner:SetFieldReviewContext("Diagnostic")
        elseif input == "dev on" or input == "development on" then
            local enabled, message = KWR.BuildInfo:SetDevelopmentMode(true)
            if enabled then
                KWR:Print("Development mode ON. Full diagnostics apply to the next match.", true)
            else
                KWR:Print(message or "Developer Tools could not be enabled.", true)
            end
        elseif input == "dev off" or input == "development off" then
            if KWR.BuildInfo and KWR.BuildInfo:SetDevelopmentMode(false) then
                KWR:Print("Development mode OFF. Preview and diagnostic capture are disabled. Loaded tools remain in memory until reload.", true)
            end
        elseif input == "dev" or input == "dev status" then
            KWR:Print("Development mode: "
                .. ((KWR.BuildInfo and KWR.BuildInfo:IsDevelopmentMode()) and "ON" or "OFF"), true)
        elseif input == "season2" or input == "season 2" or input == "watchlist" then
            if KWR.BuildInfo and KWR.BuildInfo:IsDevelopmentMode() then
                owner:ShowSeason2EvidenceRun()
            else
                KWR:Print("Development diagnostics are off. Use /kwr dev on before an evidence run.", true)
            end
        elseif input == "season2 aar" or input == "season 2 aar" then
            local latest = KWR.AAR:GetLatest()
            if latest and KWR.AARWindow then
                KWR.AARWindow:Show(latest.id)
            else
                KWR:Print("No completed AAR is available yet. Finish a real battleground first.", true)
            end
        elseif input == "options" then KWR.Options:Toggle()
        elseif input == "presentation" or input == "bgui" then
            KWR.db.profile.presentation.enabled = KWR.db.profile.presentation.enabled == false
            if KWR.Presentation then KWR.Presentation:RefreshNow() end
            KWR:Print("Battleground auto-show: "
                .. (KWR.db.profile.presentation.enabled == false and "OFF" or "ON"), true)
        elseif input == "cursor" then KWR.CursorRing:Toggle()
        elseif input == "reticle" then KWR.CursorRing:ToggleReticle()
        elseif input == "test" then
            if helpers.diagnosticsAvailable() then
                KWR.Diagnostics:ShowReport()
            else
                KWR:Print("Diagnostics are available only in the developer build.", true)
            end
        elseif input == "explain" or input == "why" then owner:Explain()
        elseif input == "perf" or input == "performance" then
            if KWR.BuildInfo and KWR.BuildInfo:IsDevelopmentMode() then
                owner:ShowPerformance()
            else
                KWR:Print("Development diagnostics are off. Use /kwr dev on before the match to capture performance evidence.", true)
            end
        elseif input == "verify" or input == "capture" then
            if KWR.BuildInfo and KWR.BuildInfo:IsDevelopmentMode()
                and KWR.Verification and KWR.Verification.CurrentReport then
                KWR.CopyDialog:ShowText("KWR Live Verification", KWR.Verification:CurrentReport(), {
                    note = "Summary first, raw details below. Scroll to inspect the full verification report.",
                })
            else
                KWR:Print("Development diagnostics are off. Use /kwr dev on before collecting verification evidence.", true)
            end
        elseif input == "bug" or input == "fieldreport" then
            if KWR.BuildInfo and KWR.BuildInfo:IsDevelopmentMode()
                and KWR.Verification and KWR.Verification.FieldReport then
                KWR.CopyDialog:ShowText("KWR Field Defect Bundle", KWR.Verification:FieldReport(), {
                    note = "Use this local report when packaging a field defect bundle.",
                })
            else
                KWR:Print("Development diagnostics are off. Use /kwr dev on before reproducing a defect.", true)
            end
        elseif input == "evidence" or input == "ledger" then
            if KWR.BuildInfo and KWR.BuildInfo:IsDevelopmentMode()
                and KWR.Verification and KWR.Verification.LedgerReport then
                KWR.CopyDialog:ShowText("KWR Match Evidence Ledger", KWR.Verification:LedgerReport(), {
                    note = "Ledger text is local and scrollable here for manual review or copy.",
                })
            else
                KWR:Print("Development diagnostics are off. Use /kwr dev on before collecting a verification ledger.", true)
            end
        elseif input == "mode" or input == "learnmode" then
            KWR.db.profile.guidanceMode = KWR.db.profile.guidanceMode == "LEARNING" and "COMMAND" or "LEARNING"
            KWR.MatchRuntime:ForceRefresh("guidance-mode")
            KWR:Print("Guidance mode: " .. KWR.db.profile.guidanceMode, true)
        elseif input == "status" then
            local state = KWR.Store:Get()
            local line1, line2 = KWR.CommandView:SummaryLines(state)
            KWR:Print(line1 .. " | " .. line2, true)
        else
            local commands = {
                "/kwr", "field", "commander", "spectator", "diagnostic", "dev [on|off|status]", "bug", "tactical", "battlefield", "reporter", "roster", "teammini", "enemymini",
                "objectives", "team", "enemies", "assignments", "intel", "aar", "aar copy",
                "aar clear", "season2 [aar]", "override", "hud", "copy", "alts", "explain", "perf", "verify", "evidence",
                "mode", "refresh", "reassess", "options", "presentation", "cursor", "reticle",
                "status", "countdown [1..10|cancel]", "delivered [call token]",
            }
            if helpers.previewAvailable() then
                table.insert(commands, 15, "preview [all|roster|off]")
            end
            if helpers.diagnosticsAvailable() then
                table.insert(commands, "test")
            end
            KWR:Print("Commands: " .. table.concat(commands, ", "), true)
        end
    end
end
