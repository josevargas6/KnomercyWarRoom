local _, KWR = ...

local CountdownState = { revision = 0 }
KWR.CountdownState = CountdownState

local function finite(value)
    value = KWR.Util:Number(value, nil)
    if value and value == value and value >= 0 and value < math.huge then return value end
end

local function identity(snapshot, plan)
    local context = snapshot and snapshot.context or {}
    local target = plan and plan.killTarget
    local session = KWR.Util:Text(context.sessionKey, "", 160)
    local guid = KWR.Util:Text(target and target.targetGUID, "", 96)
    if context.inPvP ~= true or context.preview == true or context.matchComplete == true
        or session == "" or guid == "" or not plan or plan.displayEligible ~= true then return nil end
    local targetPresent = false
    for _, enemy in ipairs(snapshot.enemies or {}) do
        if enemy.guid == guid and enemy.dead == false
            and (enemy.localRange == true or enemy.localEngaged == true) then
            targetPresent = true
            break
        end
    end
    if not targetPresent then return nil end
    local rows = { "session:" .. session, "target:" .. guid }
    for _, row in ipairs(plan.assignments or {}) do
        rows[#rows + 1] = table.concat({ "actor", row.actorGUID or row.actor or "",
            row.verb or "", row.targetGUID or row.target or "" }, ":")
    end
    local objectives = snapshot.objectives and (snapshot.objectives.rows or snapshot.objectives) or {}
    for _, row in ipairs(objectives) do
        rows[#rows + 1] = table.concat({ "objective", row.id or row.label or "",
            row.owner or "UNKNOWN", row.state or "UNKNOWN" }, ":")
    end
    table.sort(rows)
    return table.concat(rows, "\031")
end

function CountdownState:Cancel(reason)
    self.active = nil
    self.lastCancelReason = reason or "MANUAL_CANCEL"
end

function CountdownState:Start(snapshot, plan, seconds)
    seconds = finite(seconds)
    if not seconds or seconds < 1 or seconds > 10 or seconds ~= math.floor(seconds) then
        return false, "Countdown requires a whole number from 1 to 10."
    end
    if KWR.Util:OptionalBoolean(KWR.Util:Call(UnitIsGroupLeader, "player")) ~= true then
        return false, "Only the local group leader can start this countdown."
    end
    local key = identity(snapshot, plan)
    if not key then return false, "Countdown needs a live eligible target and match identity." end
    local now = finite(KWR.Util:Now())
    if not now then return false, "Countdown clock is unavailable." end
    self.revision = self.revision + 1
    self.active = { id = "LOCAL_CUE:" .. tostring(self.revision) .. ":" .. tostring(now),
        source = "LOCAL_LEADER", revision = self.revision, identity = key,
        startedAt = now, deadline = now + seconds, duration = seconds }
    self.lastCancelReason = nil
    return true, "Local countdown started."
end

function CountdownState:Project(record)
    local active = self.active
    local now = finite(KWR.Util:Now())
    if active and (not now or now < active.startedAt or now >= active.deadline + 1) then
        self:Cancel("CLOCK_OR_EXPIRY")
        active = nil
    end
    if not active or type(record) ~= "table" or record.id ~= active.id or not now
        or now < active.startedAt or now >= active.deadline + 1 then
        return { seconds = 0, ticks = {}, state = "UNTIMED", text = "ON LEADER CALL" }
    end
    local seconds = math.max(0, math.ceil(active.deadline - now))
    local state = seconds > 0 and "COUNTING" or "GO"
    return { id = active.id, source = active.source, revision = active.revision,
        startedAt = active.startedAt, deadline = active.deadline, duration = active.duration,
        seconds = seconds, ticks = { seconds > 0 and seconds or "GO" }, state = state,
        text = seconds > 0 and ("GO IN " .. tostring(seconds)) or "GO NOW" }
end

function CountdownState:Build(snapshot, plan)
    local active = self.active
    if active and (KWR.Util:OptionalBoolean(KWR.Util:Call(UnitIsGroupLeader, "player")) ~= true
        or type(snapshot) ~= "table" or identity(snapshot, plan) ~= active.identity) then
        self:Cancel("PLAN_CHANGED")
    end
    local projected = self:Project(self.active)
    if self.active and projected.state == "UNTIMED" then self:Cancel("CLOCK_OR_EXPIRY") end
    return projected
end

function CountdownState:Text(record)
    return self:Project(record).text
end

KWR:RegisterModule("CountdownState", CountdownState)
