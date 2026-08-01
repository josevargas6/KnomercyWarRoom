local _, KWR = ...

local DoctrineComparisons = {}
KWR.DoctrineComparisons = DoctrineComparisons

local function comparison(id, a, b, preferWhen, preferWhy, avoidWhen, sensors)
    return {
        id = id,
        optionA = a,
        optionB = b,
        preferWhen = preferWhen,
        preferWhy = preferWhy,
        avoidWhen = avoidWhen,
        sensors = sensors or {},
        reviewStatus = "THEORY_REVIEWED",
        evidenceGrade = "C",
        requiresMatchValidation = true,
    }
end

local function response(id, enemyPattern, safestCounter, because, holdIf, abortIf)
    return {
        id = id,
        enemyPattern = enemyPattern,
        safestCounter = safestCounter,
        because = because,
        holdIf = holdIf,
        abortIf = abortIf,
        reviewStatus = "THEORY_REVIEWED",
        evidenceGrade = "C",
        requiresMatchValidation = true,
    }
end

local DATA = {
    ARATHI = {
        comparisons = {
            comparison("AB_HOLD_THREE_VS_CHASE_FOUR",
                "Hold three with reserve intact",
                "Chase a fourth base",
                "Three bases already win the clock and at least one held node is vulnerable.",
                "The winning shell is safer than exposing two nodes for vanity pressure.",
                "A fourth-base route begins before replacements are named.",
                { "score truth", "objective truth", "movement / location truth" }),
            comparison("AB_RETAKE_BS_VS_OUTER_TRADE",
                "Retake Blacksmith",
                "Trade for the weaker outer node",
                "Blacksmith is still live and the outer route will resolve too late.",
                "Center value is worth more only when the retake arrives before stabilization.",
                "The enemy already planted Blacksmith and your regroup wave cannot arrive on time.",
                { "objective truth", "timing / respawn truth", "counter-response safety" }),
            comparison("AB_DEFEND_ANCHOR_VS_FLOAT_CENTER",
                "Reinforce the pressured anchor node",
                "Float everyone back toward center",
                "The anchor break would expose a two-cap collapse faster than any center win.",
                "You protect the score floor first and only then reopen center pressure.",
                "The reinforcement would empty another must-hold node.",
                { "objective truth", "friendly roster truth", "movement / location truth" }),
            comparison("AB_SHOW_BS_VS_FULL_COMMIT",
                "Show pressure at Blacksmith then rotate weak side",
                "Full commit every body to Blacksmith",
                "Enemy reserve can be pulled without surrendering your home shell.",
                "A forced rotation often wins a cleaner node than a long fair brawl.",
                "Both lanes would become unsupported fights at once.",
                { "objective truth", "enemy roster truth", "movement / location truth" }),
        },
        responses = {
            response("AB_RESP_STEALTH_FLOAT",
                "Enemy stealth float threatens isolated sitters.",
                "Pair the weak sitter, keep reveal pressure active, and punish the lane they abandoned.",
                "You deny the sap-cap line before it becomes a free node flip.",
                "Weak node coverage stays paired and the reserve remains free.",
                "Two response players chase the same fake opener."),
            response("AB_RESP_BS_BUNKER",
                "Enemy bunker shell stabilizes Blacksmith.",
                "Spin Blacksmith with minimum bodies and trade into the weaker outer node.",
                "Front-door sustain fights usually waste the whole map while the weak side stays open.",
                "The trade lane is isolated and home remains covered.",
                "The trade lane pairs before control lands."),
            response("AB_RESP_FOUR_CAP_GREED",
                "Enemy overextends toward a four-cap.",
                "Stop the fourth cap first and rebuild a safe three-node shell second.",
                "Preventing the collapse is worth more than racing a low-value countercap.",
                "Your recovery wave can still arrive before the fourth node settles.",
                "The fourth node is already lost and an outer trade wins faster."),
            response("AB_RESP_ROAD_CHASE",
                "Enemy drags the fight into road space away from flags.",
                "Break the chase, replant defenders, and only hit the next node fight.",
                "Road kills do not score unless they open a real cap window.",
                "Held nodes still have enough defenders to freeze.",
                "A live flag is already uncovered."),
        },
    },
    GILNEAS = {
        comparisons = {
            comparison("BFG_HOLD_TWO_VS_FORCE_THREE",
                "Hold two cleanly",
                "Force the third node",
                "Two bases already win the path and one anchor is still under pressure.",
                "Stable two-base clocks beat reckless third-node attempts.",
                "You move the reserve before both anchors are dressed.",
                { "score truth", "objective truth", "movement / location truth" }),
            comparison("BFG_WW_FIGHT_VS_OUTER_TRADE",
                "Continue the Waterworks fight",
                "Trade into the weaker outer node",
                "Waterworks is still contestable and the enemy reserve has not left.",
                "You stay if center is still the best-value live fight.",
                "Waterworks already stabilized for them and the outer node is isolated.",
                { "objective truth", "timing / respawn truth", "enemy roster truth" }),
            comparison("BFG_REINFORCE_WW_VS_SAVE_HOME",
                "Reinforce Waterworks",
                "Preserve home and wait for the next swing",
                "Waterworks flips the score path and home still has a true defender.",
                "Center value matters only if home does not collapse behind it.",
                "Home loses its last safe defender to fund the center push.",
                { "objective truth", "friendly roster truth", "counter-response safety" }),
            comparison("BFG_SHOW_WW_VS_DIRECT_THIRD",
                "Show Waterworks then rotate third",
                "Directly hit the third node",
                "The enemy respects Waterworks enough to over-rotate from the outer lane.",
                "Fake center danger creates a cleaner spin than a telegraphed road hit.",
                "The outer node is already paired or Waterworks is too undermanned to show.",
                { "enemy roster truth", "movement / location truth", "objective truth" }),
        },
        responses = {
            response("BFG_RESP_DOUBLE_SIT",
                "Enemy locks both side anchors and dares a weak center push.",
                "Keep home safe and retake Waterworks with one full wave only if the route arrives live.",
                "You solve the score path instead of donating bodies to every road.",
                "Home remains stable and the wave reaches the flag before resolution.",
                "The center retake lands after a full enemy stabilize."),
            response("BFG_RESP_WW_TRAP",
                "Enemy wants a long Waterworks sustain trap.",
                "Break the neutral grind and punish the lighter side node.",
                "Gilneas throws happen when teams accept endless fair center fights.",
                "Your hold node keeps a true sitter and the strike team stays compact.",
                "The lighter side node no longer offers a control window."),
            response("BFG_RESP_STEALTH_NINJA",
                "Enemy stealth package threatens last-second ninjas.",
                "Pair the vulnerable sitter and keep one response body off the flag circle.",
                "The safest answer is coverage plus reveal, not panic mass rotation.",
                "The second body is planted before vanish windows open.",
                "Both responders leave the same node together."),
            response("BFG_RESP_OUTER_FEINT",
                "Enemy fakes outer pressure to peel your Waterworks bodies away.",
                "Confirm the outer lane with the reserve only and keep the Waterworks core intact.",
                "One fake should not open the real scoring objective.",
                "The reserve can arrive without stripping Waterworks below stable numbers.",
                "Outer pressure becomes a live cap chain before the reserve arrives."),
        },
    },
    DEEPWIND = {
        comparisons = {
            comparison("DWG_MARKET_VS_FLANK",
                "Preserve Market",
                "Over-rotate to a flank fight",
                "Market still anchors the winning shell and flank value is only equal pressure.",
                "Central value usually decides whether the rest of the map stays connected.",
                "Market is already unrecoverable and the flank route is cheaper to swing.",
                { "objective truth", "score truth", "movement / location truth" }),
            comparison("DWG_HOLD_THREE_VS_GHOST_FOURTH",
                "Hold three with reserve",
                "Ghost a fourth node",
                "Three nodes already create the safer clock and the reserve is still busy.",
                "A connected triangle is stronger than a greedy isolated fourth.",
                "A held flank would lose its replacement path during the ghost route.",
                { "score truth", "objective truth", "counter-response safety" }),
            comparison("DWG_RETAKE_MARKET_VS_OUTER_RECLAIM",
                "Retake Market",
                "Reclaim one recoverable outer flank",
                "Market is live enough that taking it restores the whole map shape.",
                "Retaking the heart is best only when it reforms the shell immediately.",
                "The center push lands after the enemy second wave while the flank is free.",
                { "timing / respawn truth", "objective truth", "movement / location truth" }),
            comparison("DWG_SHOW_CENTER_VS_HIT_GHOST",
                "Show center pressure then hit ghost flank",
                "March straight at the flank",
                "Enemy reserve is center-anchored and likely to chase the show.",
                "You create a longer enemy path and a cleaner weak-side take.",
                "The center show would leave the strike lane too slow or too visible.",
                { "enemy roster truth", "movement / location truth", "objective truth" }),
        },
        responses = {
            response("DWG_RESP_GHOST_ROTATION",
                "Enemy ghost-rotates between flanks while you defend center.",
                "Keep Market stable, name the truly weak flank, and punish the abandoned side once revealed.",
                "Mirroring ghost motion everywhere loses more than it saves.",
                "Market and the opposite flank both keep planted coverage.",
                "Two weak flanks become live at once."),
            response("DWG_RESP_MARKET_DEATHBALL",
                "Enemy deathballs Market and dares you to bleed into it.",
                "Stall Market with minimum legal bodies and swing the lighter flank.",
                "If their shell over-stacks center, the map answer is usually outside it.",
                "The flank lane is light enough to cap before the deathball arrives.",
                "The flank strike would land into equal numbers anyway."),
            response("DWG_RESP_SIMULTANEOUS_INC",
                "Enemy threatens simultaneous flank incomings.",
                "Protect the score floor lane first and send one named reserve into the second call.",
                "You solve the lane that actually breaks the shell before chasing full parity.",
                "One flank can survive with planted defenders long enough for reserve arrival.",
                "Both flanks are already uncovered."),
            response("DWG_RESP_MARKET_FAKE",
                "Enemy flashes Market only to pull your floaters off a weak flank.",
                "Answer Market with the minimum spinner line and keep the flank defender paired.",
                "The fake succeeds only if you break the real weak lane yourself.",
                "Market still has live bodies on the node and one reserve path.",
                "Market truly flips into a full collapse instead of a fake."),
        },
    },
    EOTS = {
        comparisons = {
            comparison("EOTS_TOWER_VS_FLAG",
                "Swing a tower",
                "Route the flag",
                "Current tower count makes the flag low value or unstable.",
                "Tower truth decides whether the flag route is even worth taking.",
                "The flag converts directly into a decisive score state now.",
                { "score truth", "objective truth", "timing / respawn truth" }),
            comparison("EOTS_HOLD_TWO_TOWERS_VS_FORCE_MID",
                "Hold two towers and re-enter mid later",
                "Force a mid fight immediately",
                "Mid control does not outvalue your current tower shell yet.",
                "A fake mid obsession often burns the better scoring structure.",
                "Two towers are already breaking and the next flag route becomes decisive.",
                { "score truth", "objective truth", "movement / location truth" }),
            comparison("EOTS_RETAKE_TOWER_VS_CHASE_CARRIER",
                "Retake the cheaper tower",
                "Chase the current carrier",
                "A tower swing repairs more score than a risky kill route.",
                "You fix the long-term path instead of gambling on one body.",
                "The carrier route is isolated and the tower retake is already too late.",
                { "objective truth", "timing / respawn truth", "enemy roster truth" }),
            comparison("EOTS_BAIT_FLAG_VS_DIRECT_NODE",
                "Threaten flag to force tower movement",
                "Directly hit the tower",
                "Enemy tower coverage is rigid enough to bend toward mid first.",
                "Flag bait creates a cleaner tower swing than a full direct hit.",
                "The flag threat is too weak to pull defenders or mid is already lost.",
                { "enemy roster truth", "objective truth", "movement / location truth" }),
        },
        responses = {
            response("EOTS_RESP_BAD_FLAG_TUNNEL",
                "Enemy tunnels the flag while losing tower count.",
                "Keep tower minimum stable and punish the lightly held tower instead of mirroring mid forever.",
                "Low-value flag obsession is best answered by improving tower truth, not joining it.",
                "Your held towers remain dressed during the punish route.",
                "A held tower becomes uncovered before the punish lands."),
            response("EOTS_RESP_DOUBLE_TOWER_ROT",
                "Enemy rotates hard between towers and avoids stable mid fights.",
                "Anchor the cheapest winning tower pair and use mid only when it opens real value.",
                "You deny the merry-go-round by protecting the score path first.",
                "The chosen pair still preserves the current clock edge.",
                "The chosen pair already loses the next decisive tick."),
            response("EOTS_RESP_MID_BUNKER",
                "Enemy bunkers mid and dares repeated flag routes.",
                "Take only the flags that convert immediately; otherwise swing the weaker tower.",
                "Mid bunkers win when you donate endless neutral contact into them.",
                "The tower route lands before a new high-value flag appears.",
                "A current flag would already end or save the game."),
            response("EOTS_RESP_BACKDOOR_TOWER",
                "Enemy stealth team threatens backdoor tower flips.",
                "Pair the weak tower sitter and keep reveal pressure active while mid remains compact.",
                "The safest answer is coverage discipline, not stripping mid blind.",
                "The weak tower gets a real second body before vanish timing.",
                "Mid would fully collapse by pairing the tower."),
        },
    },
    WSG = {
        comparisons = {
            comparison("WSG_PEEL_FC_VS_PRESS_EFC",
                "Peel our carrier",
                "Push the enemy carrier",
                "Our carrier shell is the immediate score lever and the next enemy connect is live.",
                "No return window matters if our own carrier dies first.",
                "Our shell is stable through the whole pressure window.",
                { "objective truth", "friendly roster truth", "local fight truth" }),
            comparison("WSG_RETURN_NOW_VS_RESET",
                "Force the return wave now",
                "Reset and rebuild the hit",
                "Healer control, route denial, and carrier safety all align together.",
                "You commit only when the full return package is real.",
                "One layer of the window breaks before arrival.",
                { "objective truth", "timing / respawn truth", "local fight truth" }),
            comparison("WSG_TUNNEL_PRESSURE_VS_ROUTE_SWAP",
                "Continue tunnel pressure",
                "Swap to the safer route collapse",
                "Tunnel still gives the shortest kill path and enemy peel is already spent.",
                "You stay only while the path remains cleaner than the reset route.",
                "Tunnel becomes the obvious bunker lane and the side route opens.",
                { "enemy roster truth", "movement / location truth", "local fight truth" }),
            comparison("WSG_HOLD_DEFENSE_VS_MID_CHASE",
                "Keep home defense planted",
                "Chase midfield kills",
                "The enemy can still create a grab or reconnect from mid chaos.",
                "Mid kills are worthless if they open the next carrier state.",
                "The enemy flag state is already resolved and grab lanes are fully safe.",
                { "objective truth", "movement / location truth", "score truth" }),
        },
        responses = {
            response("WSG_RESP_TURTLE_BUNKER",
                "Enemy turtles the carrier in a stable bunker.",
                "Protect your own carrier, force healer control, and hit only on one synchronized route denial window.",
                "Trickle pressure into a turtle loses both offense and defense at once.",
                "Your carrier remains safe through the whole return attempt.",
                "Your shell breaks before the control chain starts."),
            response("WSG_RESP_TUNNEL_TRAIN",
                "Enemy offense trains the tunnel lane repeatedly.",
                "Shift peel into the first connector and route your carrier away from the repeat lane.",
                "The safest counter changes the shape before the train fully lands.",
                "Your route swap remains covered by healer line and peel bodies.",
                "The new route is already closed or trapped."),
            response("WSG_RESP_FAKE_RETURN_WINDOW",
                "Enemy shows a tempting EFC hit but your FC is still unstable.",
                "Abort the hit, stabilize the shell, and rebuild the next real return window.",
                "The bad loss is dying on defense while pretending the offense was live.",
                "Carrier safety improves before the next enemy connect.",
                "A guaranteed return-and-cap opens immediately instead."),
            response("WSG_RESP_LAST_GRAB",
                "Enemy wants one last desperation grab in endgame.",
                "Plant the grab-lane defense first and only then escort the decisive return.",
                "Denying the next flag state is often safer than chasing one more mid kill.",
                "Home routes are locked before you leave them.",
                "The current return-and-cap is already unavoidable and immediate."),
        },
    },
    TWINPEAKS = {
        comparisons = {
            comparison("TP_PEEL_OFC_VS_PRESS_EFC",
                "Peel our carrier",
                "Press the enemy carrier",
                "Our carrier route is the first break point in the score path.",
                "If the home shell collapses first, offense cannot cash out.",
                "Our carrier shell survives the whole pressure window safely.",
                { "objective truth", "local fight truth", "friendly roster truth" }),
            comparison("TP_TUNNEL_VS_RAMP_COLLAPSE",
                "Continue tunnel pressure",
                "Collapse ramp or side route",
                "Tunnel remains the shortest live route and enemy bunker layers are spent.",
                "Stay only while it is the actual shortest kill path.",
                "Tunnel becomes the obvious bunker lane and the side route opens cleaner.",
                { "movement / location truth", "enemy roster truth", "local fight truth" }),
            comparison("TP_FORCE_RETURN_VS_RESET",
                "Force the return now",
                "Reset for the next wave",
                "Healer control, intercept coverage, and our carrier safety align together.",
                "One full package is safer than two half-windows.",
                "Any part of the package expires before arrival.",
                { "timing / respawn truth", "objective truth", "local fight truth" }),
            comparison("TP_DEFEND_GRAB_VS_CHASE_MID",
                "Protect grab and ramp routes",
                "Chase midfield damage",
                "Enemy can still create one reset state through a fast pickup lane.",
                "Mid control is secondary when one grab changes everything.",
                "Enemy pickup lanes are already fully sealed and the current cap is locked.",
                { "objective truth", "movement / location truth", "score truth" }),
        },
        responses = {
            response("TP_RESP_RAMP_BUNKER",
                "Enemy bunkers the carrier around ramp and graveyard space.",
                "Keep peel on your own carrier and use one route-denial collapse after their escort commits.",
                "The safe counter is synchronized route control, not endless face-first pressure.",
                "Your own carrier shell remains whole through the hit.",
                "Escort control or route denial breaks before contact."),
            response("TP_RESP_SPLIT_OFFENSE",
                "Enemy offense splits pressure across multiple carrier approaches.",
                "Name the real approach, cover it first, and let the reserve answer only the second live lane.",
                "Twin Peaks throws happen when both defenders chase different guesses.",
                "One route is clearly faster or more dangerous than the other.",
                "Both routes become equally live and uncovered."),
            response("TP_RESP_FAKE_TUNNEL",
                "Enemy flashes tunnel to pull your return team out of position.",
                "Answer tunnel with minimum bodies and keep the real return package aimed at the carrier route.",
                "The fake succeeds only if you break your own timing for it.",
                "Tunnel still has a planted peel answer while pressure stays compact.",
                "Tunnel becomes the true kill lane instead of a fake."),
            response("TP_RESP_LAST_RESET",
                "Enemy seeks a final reset pickup before your cap.",
                "Lock pickup lanes first, then escort the return window home.",
                "Denying the reset is often the cleanest way to finish the map.",
                "Pickup denial bodies are planted before you overextend.",
                "The current return-and-cap is already immediate and unstoppable."),
        },
    },
    TEMPLE = {
        comparisons = {
            comparison("TOK_PROTECT_HIGH_VALUE_VS_CHASE_LOOSE",
                "Protect the highest-value friendly carrier",
                "Chase a loose low-value orb",
                "The protected orb is worth more score than the pickup race you would start.",
                "Saving live value usually beats gambling on replaceable loose value.",
                "The loose orb creates a decisive swing and the carrier is already unrecoverable.",
                { "score truth", "objective truth", "local fight truth" }),
            comparison("TOK_CENTER_HOLD_VS_EDGE_RESET",
                "Hold center space",
                "Reset to safer edge space",
                "Center still supports your carriers without exposing all of them to one collapse.",
                "Center is good only while it remains a supported scoring space.",
                "The enemy collapse angle makes center a kill box for multiple carriers.",
                { "local fight truth", "movement / location truth", "friendly roster truth" }),
            comparison("TOK_KILL_CARRIER_VS_DENY_PICKUP",
                "Kill the exposed carrier",
                "Deny the next pickup lane",
                "The kill turns directly into controlled loose value for your team.",
                "You choose the kill only when the orb will not immediately reset to the enemy.",
                "Pickup denial is easier and the kill orb would land in enemy support.",
                { "objective truth", "movement / location truth", "local fight truth" }),
            comparison("TOK_SPREAD_TWO_VS_GREED_THREE",
                "Stabilize two supported carriers",
                "Greed a third carrier",
                "Two supported carriers already outvalue the risk of a shared collapse.",
                "Temple punishments are brutal when three orbs stack into one bad zone.",
                "The third pickup is free and does not expose the first two carriers.",
                { "score truth", "friendly roster truth", "counter-response safety" }),
        },
        responses = {
            response("TOK_RESP_CENTER_DEATHBALL",
                "Enemy deathballs center and hunts stacked carriers.",
                "Spread carriers, peel the first connect, and only fight center on your terms.",
                "The safest counter is shape control before damage racing.",
                "Support lines stay separated and the first carrier survives the connect.",
                "Two carriers are already trapped in one kill box."),
            response("TOK_RESP_LOOSE_ORB_TRAP",
                "Enemy leaves a loose orb in bad terrain to bait a pickup.",
                "Take it only with escort coverage or deny it until the terrain is safe.",
                "A loose orb is not value if it immediately becomes a feed target.",
                "Escort and peel arrive with the pickup.",
                "The pickup would strand the carrier in open kill space."),
            response("TOK_RESP_HIGH_VALUE_CARRIER",
                "Enemy protects one high-value carrier with full support.",
                "Pressure the support line or next pickup lane before forcing the full carrier kill.",
                "You break the shell first instead of donating bodies to the most protected orb.",
                "The support line or pickup lane is more exposed than the carrier body.",
                "A direct kill window opens cleanly first."),
            response("TOK_RESP_DOUBLE_DROP",
                "Multiple orbs drop at once and the map becomes chaotic.",
                "Reform on the safest next carrier state instead of letting everyone freelance pickups.",
                "Temple recoveries succeed by rebuilding shape before chasing maximum greed.",
                "A clear supported pickup lane exists.",
                "No pickup can be escorted and the best play is pure denial."),
        },
    },
    SILVERSHARD = {
        comparisons = {
            comparison("SSM_LIVE_CART_VS_DEAD_CART",
                "Fight on the live cart",
                "Stay on the dead cart",
                "The live cart still moves score and the dead route no longer changes the race.",
                "Cart truth beats kill comfort every time.",
                "The live cart is already unrecoverable and the next route is the only value.",
                { "score truth", "objective truth", "timing / respawn truth" }),
            comparison("SSM_ESCORT_VS_JUNCTION_SWING",
                "Escort the scoring cart",
                "Send extra bodies to junction early",
                "Your escort would otherwise stall or die before turn value lands.",
                "You keep current score value before gambling on future route value.",
                "Current escort is safe and the junction swing decides the next cart.",
                { "objective truth", "movement / location truth", "timing / respawn truth" }),
            comparison("SSM_SPLIT_TWO_VS_COLLAPSE_ONE",
                "Split to two live responsibilities",
                "Collapse one cart entirely",
                "Both duties remain score-active and each can survive with named coverage.",
                "You split only when both jobs are real and supportable.",
                "One cart is dead or one split side would be purely symbolic.",
                { "objective truth", "friendly roster truth", "counter-response safety" }),
            comparison("SSM_SWITCH_ROUTE_VS_FINISH_FIGHT",
                "Leave for the next route on time",
                "Finish the current fight",
                "The current fight cannot score as much as the next route arrival.",
                "Winning route timing often means abandoning a winnable but dead brawl.",
                "The current fight still directly decides a live scoring cart.",
                { "timing / respawn truth", "score truth", "objective truth" }),
        },
        responses = {
            response("SSM_RESP_JUNCTION_BAIT",
                "Enemy baits a long junction fight while the live cart moves elsewhere.",
                "Leave the bait early and escort the cart that still changes the score.",
                "The safe counter is respecting score truth over fight ego.",
                "The live cart path remains escortable.",
                "The live cart is already fully lost before you can arrive."),
            response("SSM_RESP_SPLIT_DRAG",
                "Enemy drags your team into two equal losing splits.",
                "Name the higher-value cart and concede the dead side first.",
                "Half-losing both carts is worse than fully winning one real route.",
                "One cart clearly has better score or arrival value.",
                "Both routes remain equally score-critical and supportable."),
            response("SSM_RESP_FINAL_TURN_THREAT",
                "Enemy threatens one decisive final turn.",
                "Anchor the turn route first and ignore off-route kills.",
                "The turn path matters more than any road damage around it.",
                "The decisive route can still be contested before completion.",
                "The route is already unrecoverable and the next cart race is live."),
            response("SSM_RESP_ESCORT_COLLAPSE",
                "Enemy collapses hard on one escort cart.",
                "Peel the first connector and send only the minimum second wave the cart needs.",
                "Over-funding one escort often throws the next active route.",
                "The cart survives with that smaller reinforcement.",
                "The cart dies anyway and the next route is the real value."),
        },
    },
    DEEPHAUL = {
        comparisons = {
            comparison("DHR_ESCORT_OURS_VS_HIT_CRYSTAL",
                "Escort our cart",
                "Divert bodies to Crystal",
                "Our cart would lose real distance or safety without the escort bodies.",
                "Crystal is side value unless the cart race stays covered.",
                "Crystal directly flips the cart race and escort is already stable.",
                { "score truth", "objective truth", "friendly roster truth" }),
            comparison("DHR_DELAY_THEIRS_VS_FULL_DEFEND_OURS",
                "Delay their cart",
                "Full defend our own cart",
                "A small delay meaningfully changes checkpoint timing and our escort remains stable.",
                "One legal delay group can swing the race without stripping our score floor.",
                "Our escort would become unsafe from funding the delay.",
                { "objective truth", "timing / respawn truth", "counter-response safety" }),
            comparison("DHR_TURN_THEIR_CART_VS_WIN_OURS",
                "Turn the enemy cart",
                "Secure our own cart distance",
                "The enemy cart reversal changes more score than our next safe checkpoint.",
                "You chase the bigger swing only when your own floor survives it.",
                "Your cart would lose uncontested progress during the turn attempt.",
                { "score truth", "objective truth", "friendly roster truth" }),
            comparison("DHR_RESET_WAVE_VS_TRICKLE_STOP",
                "Reset for one full wave",
                "Trickle players to slow them",
                "Trickle bodies would die before a checkpoint changes.",
                "One complete wave is safer than several fake delays.",
                "A tiny stall truly buys the exact checkpoint you need.",
                { "timing / respawn truth", "objective truth", "local fight truth" }),
        },
        responses = {
            response("DHR_RESP_CRYSTAL_BAIT",
                "Enemy lures bodies to Crystal while cart lanes stay live.",
                "Keep carts covered first and treat Crystal as optional unless it flips the race.",
                "The safe counter is cart truth before secondary temptation.",
                "Escort and delay jobs both remain staffed.",
                "Crystal now directly decides the next checkpoint race."),
            response("DHR_RESP_CHECKPOINT_RUSH",
                "Enemy rushes a near checkpoint with peel layers.",
                "Send the smallest legal delay to the checkpoint and keep escort integrity at home.",
                "Stopping the exact score event is worth more than broad skirmishing.",
                "The delay arrives before the checkpoint resolves.",
                "The delay would land late and your home escort would break."),
            response("DHR_RESP_SPLIT_RACE",
                "Enemy splits pressure across cart and side-resource lanes.",
                "Name the score-active lane first and refuse to mirror the dead side split.",
                "Cart maps punish equal attention to unequal value.",
                "The score-active lane is clearly identified.",
                "Both lanes become truly score-active at once."),
            response("DHR_RESP_LATE_CART_THROW",
                "Enemy wants a late fake fight away from the decisive cart distance.",
                "Anchor the decisive cart route and ignore the vanity engage.",
                "The comeback path is on rails, not in open-road kills.",
                "The decisive cart still has a live contest route.",
                "That route is already gone and the next lane becomes decisive."),
        },
    },
    SEETHING = {
        comparisons = {
            comparison("SHORE_ACTIVE_NODE_VS_NEXT_SPAWN",
                "Protect the active channel",
                "Pre-rotate to the next spawn",
                "The active node still finishes first and next spawn timing is not yet decisive.",
                "Current deposit value remains king until the next race overtakes it.",
                "The active node is dead value and next spawn decides more score.",
                { "score truth", "objective truth", "timing / respawn truth" }),
            comparison("SHORE_GROUP_NODE_VS_SPLIT_TWO",
                "Group one node cleanly",
                "Split across two nodes",
                "A split would leave both channels unsafe or late.",
                "One clean channel beats two fake touches.",
                "Both nodes can be channeled safely with named coverage.",
                { "friendly roster truth", "objective truth", "counter-response safety" }),
            comparison("SHORE_DEFEND_CHANNEL_VS_CHASE_KILLS",
                "Protect the channel",
                "Chase kills away from the extractor",
                "The channel itself is the score event and kills off it add no deposit value.",
                "Resource maps punish drifting off the actual interaction.",
                "The channel is already secure and the next spawn fight starts now.",
                { "objective truth", "score truth", "movement / location truth" }),
            comparison("SHORE_ABANDON_OLD_VS_FINISH_FIGHT",
                "Leave the exhausted node",
                "Finish the old fight",
                "The old node can no longer change the score path before the next public spawn.",
                "Leaving dead value early wins more games than polishing kills late.",
                "The old node still finishes or denies a decisive deposit.",
                { "timing / respawn truth", "score truth", "objective truth" }),
        },
        responses = {
            response("SHORE_RESP_SPAWN_BAIT",
                "Enemy holds you on the dying node while the next spawn opens.",
                "Break the old fight early and win the next real spawn race.",
                "The safe counter is respecting future deposit value before current ego fights.",
                "Your channel on the old node is no longer decisive.",
                "The old node still completes the winning deposit first."),
            response("SHORE_RESP_DOUBLE_NODE_SPLIT",
                "Enemy forces attention on two nodes at once.",
                "Name the higher-value node and concede the dead side first.",
                "Two half-defenses usually lose both channels.",
                "One node clearly offers better deposit or arrival value.",
                "Both nodes remain equally live and channel-safe."),
            response("SHORE_RESP_CHANNEL_FAKE",
                "Enemy fakes a channel to peel you off the real next spawn route.",
                "Answer the fake with minimum denial and keep the main group aimed at the next score event.",
                "The fake only works if you overfund it.",
                "The fake node still has one legal interrupter.",
                "The fake becomes a true deposit threat immediately."),
            response("SHORE_RESP_LAST_DEPOSIT",
                "Enemy seeks one final deposit path in endgame.",
                "Sit the last live channel route first and ignore exhausted ground.",
                "Endgame Shore is won by denying the deposit lane, not by chasing leftovers.",
                "The final route can still be contested before completion.",
                "The final route is already gone and the next spawn race matters more."),
        },
    },
}

local EXPANSION_TERMS = {
    ARATHI = {
        hold = "the three-base shell",
        rotate = "the next outer node",
        collapse = "the live cap lane",
        split = "equal side-road pressure",
        recover = "Blacksmith or the cheapest outer retake",
        bait = "Blacksmith",
        escort = "the current scoring node shell",
        convert = "the clean cap window",
        late = "the winning node count",
        deny = "the enemy last back-cap route",
    },
    GILNEAS = {
        hold = "the two-base clock",
        rotate = "the weak third node",
        collapse = "the isolated flag fight",
        split = "equal road pressure on both sides",
        recover = "Waterworks or the weakest spinner",
        bait = "Waterworks",
        escort = "the active two-base shell",
        convert = "the clean third-node swing",
        late = "the winning two-base hold",
        deny = "the final ninja or backdoor path",
    },
    DEEPWIND = {
        hold = "the Market-centered shell",
        rotate = "the weaker flank",
        collapse = "the recoverable flank",
        split = "two weak outer contacts",
        recover = "Market or the cheapest flank reclaim",
        bait = "Market",
        escort = "the live three-node shape",
        convert = "the clean flank swing",
        late = "the stable three-node triangle",
        deny = "the last ghost-cap route",
    },
    EOTS = {
        hold = "the tower minimum",
        rotate = "the next useful tower swing",
        collapse = "the highest-value tower lane",
        split = "equal low-value mid and tower pressure",
        recover = "the cheapest scoring tower",
        bait = "the flag route",
        escort = "the current tower-value path",
        convert = "the decisive flag or tower event",
        late = "the winning tower count",
        deny = "the enemy last score-changing swing",
    },
    WSG = {
        hold = "our carrier shell",
        rotate = "the next enemy carrier route",
        collapse = "the live return wave",
        split = "multiple half-offense routes",
        recover = "one full reset and rebuild wave",
        bait = "the obvious tunnel lane",
        escort = "our return-and-cap package",
        convert = "the real return window",
        late = "the last safe flag state",
        deny = "the enemy final grab lane",
    },
    TWINPEAKS = {
        hold = "our carrier route shell",
        rotate = "the intercept side",
        collapse = "the live enemy carrier lane",
        split = "multiple half-pressure routes",
        recover = "one full regrouped return wave",
        bait = "the obvious tunnel route",
        escort = "our cap conversion package",
        convert = "the real return-and-cap window",
        late = "the last safe carrier state",
        deny = "the enemy final pickup route",
    },
    TEMPLE = {
        hold = "the supported high-value carrier shell",
        rotate = "the next safe pickup lane",
        collapse = "the exposed carrier lane",
        split = "two unsupported orb skirmishes",
        recover = "the safest next supported carrier state",
        bait = "the exposed loose orb lane",
        escort = "the current scoring carrier path",
        convert = "the carrier kill into controlled pickup",
        late = "the highest-value live orb state",
        deny = "the enemy final pickup lane",
    },
    SILVERSHARD = {
        hold = "the live cart race",
        rotate = "the next scoring route",
        collapse = "the decisive cart lane",
        split = "two underfunded cart fights",
        recover = "the shortest recoverable cart",
        bait = "the dead junction fight",
        escort = "the scoring cart route",
        convert = "the decisive cart turn",
        late = "the final winning cart path",
        deny = "the enemy last turn route",
    },
    DEEPHAUL = {
        hold = "the winning cart distance",
        rotate = "the next race-changing lane",
        collapse = "the score-active cart route",
        split = "cart and side-value pressure at once",
        recover = "one full cart-race rebuild wave",
        bait = "the Crystal temptation lane",
        escort = "the decisive escort-and-delay package",
        convert = "the score-changing checkpoint denial",
        late = "the final winning cart path",
        deny = "the enemy last checkpoint route",
    },
    SEETHING = {
        hold = "the active deposit path",
        rotate = "the next public spawn",
        collapse = "the higher-value extractor race",
        split = "two unsafe channel lanes",
        recover = "the next reachable scoring spawn",
        bait = "the dying node",
        escort = "the live channel protection path",
        convert = "the decisive deposit window",
        late = "the last winning deposit path",
        deny = "the enemy final channel route",
    },
}

local function appendExpandedCoverage(row, mapKey, terms)
    if not row or not terms then return end
    local comparisons = row.comparisons or {}
    local responses = row.responses or {}

    comparisons[#comparisons + 1] = comparison(mapKey .. "_HOLD_VS_ROTATE",
        "Hold " .. terms.hold,
        "Rotate early to " .. terms.rotate,
        terms.hold .. " is the score floor and moving first would expose it.",
        "The safer branch protects the mathematical minimum before opening the next lane.",
        "The rotation begins before a replacement is planted on " .. terms.hold .. ".",
        { "score truth", "objective truth", "movement / location truth" })
    comparisons[#comparisons + 1] = comparison(mapKey .. "_COLLAPSE_VS_SPLIT",
        "Collapse " .. terms.collapse,
        "Split across " .. terms.split,
        "One lane is clearly more reachable and split pressure would become two weak touches.",
        "One real hit is safer than two decorative contacts that score nothing.",
        "Both lanes would be contacted understrength.",
        { "objective truth", "friendly roster truth", "counter-response safety" })
    comparisons[#comparisons + 1] = comparison(mapKey .. "_RECOVER_VS_TRICKLE",
        "Recover with one full wave at " .. terms.recover,
        "Trickle bodies back into the old fight",
        "The regroup wave can still arrive live and contest the score event together.",
        "One complete recovery wave preserves more score than staggered deaths.",
        "The regroup wave lands after resolution anyway.",
        { "timing / respawn truth", "objective truth", "local fight truth" })
    comparisons[#comparisons + 1] = comparison(mapKey .. "_BAIT_VS_FRONTDOOR",
        "Bait defenders off " .. terms.bait .. " then punish the exposed lane",
        "Take the front-door assault immediately",
        "Enemy movement must reveal before the safer objective really opens.",
        "Forced movement creates a cleaner opening than an obvious direct hit.",
        "The bait show would cost the real objective before the punish begins.",
        { "enemy roster truth", "movement / location truth", "objective truth" })
    comparisons[#comparisons + 1] = comparison(mapKey .. "_ESCORT_VS_CHASE",
        "Escort " .. terms.escort,
        "Chase off-objective kills",
        terms.escort .. " is the current score event or preserves the next scoring path.",
        "Score movement beats road damage when both cannot be funded together.",
        "The escort route is already fully safe and the next live score event is elsewhere.",
        { "score truth", "objective truth", "movement / location truth" })
    comparisons[#comparisons + 1] = comparison(mapKey .. "_CONVERT_VS_GREED",
        "Convert " .. terms.convert .. " now",
        "Hold for a prettier but later fight",
        "This window alone changes the score path before the enemy can reset it.",
        "Real conversion is safer than waiting for a bigger fight that may never stay legal.",
        "Coverage for the current window is not planted yet.",
        { "score truth", "objective truth", "counter-response safety" })

    responses[#responses + 1] = response(mapKey .. "_RESP_SPLIT_PRESSURE",
        "Enemy splits pressure across multiple lanes and wants equal reactions.",
        "Name the higher-value lane, hold it first, and collapse the slower enemy branch second.",
        "The safest answer is refusing equal attention to unequal score value.",
        terms.hold .. " stays planted while the reserve answers the slower lane.",
        "Both lanes are already equally live and uncovered.")
    responses[#responses + 1] = response(mapKey .. "_RESP_BAIT_SHOW",
        "Enemy shows pressure on the obvious lane to peel your real defense.",
        "Answer the show with minimum bodies and deny the fake before moving the main package.",
        "The bait only wins if you overfund the first picture they give you.",
        "The fake still has one legal answer without exposing " .. terms.hold .. ".",
        "The show becomes the real score event immediately.")
    responses[#responses + 1] = response(mapKey .. "_RESP_COLLAPSE_CONNECT",
        "Enemy full-collapses one route and tries to win before you stabilize.",
        "Peel the first connector, keep the score floor planted, then counter only if their overextension stays exposed.",
        "The safe counter breaks the first contact before racing a revenge fight.",
        terms.hold .. " remains staffed while the peel line lands.",
        "The peel would empty the real score floor.")
    responses[#responses + 1] = response(mapKey .. "_RESP_ESCORT_SHELL",
        "Enemy protects the score event with a heavy escort shell.",
        "Deny exits or route value first instead of tunneling the most protected body head-on.",
        "Breaking the shell is safer than donating bodies into its strongest point.",
        "The denial route is live and more exposed than the core body.",
        "The route is already closed and only a direct hit remains.")
    responses[#responses + 1] = response(mapKey .. "_RESP_RETURN_WINDOW",
        "Enemy tries to survive one more reset before the score event converts.",
        "Protect your own shell first, then push the real conversion window only with full coverage planted.",
        "The bad loss is breaking your own side while pretending the score window is live.",
        terms.escort .. " stays safe through the conversion attempt.",
        "The current window expires before your shell is ready.")
    responses[#responses + 1] = response(mapKey .. "_RESP_LATE_GREED",
        "Enemy seeks one last desperation score while hoping you greed extra pressure.",
        "Protect " .. terms.late .. " first and deny " .. terms.deny .. " before any optional chase.",
        "Late games are lost more by abandoning the score floor than by failing to overkill.",
        "The denial lane can still be planted before it resolves.",
        "The denial lane is already gone and another decisive score path is now live.")
end

local function appendAdvancedCoverage(row, mapKey, terms)
    if not row or not terms then return end
    local comparisons = row.comparisons or {}
    local responses = row.responses or {}

    comparisons[#comparisons + 1] = comparison(mapKey .. "_DENY_VS_TRADE",
        "Deny " .. terms.deny .. " first",
        "Trade for side pressure elsewhere",
        terms.deny .. " is the one enemy branch that still flips the score path.",
        "The safer expert line solves the decisive enemy route before optional pressure.",
        "The denial route is already dead and another score event resolves sooner.",
        { "score truth", "objective truth", "counter-response safety" })
    comparisons[#comparisons + 1] = comparison(mapKey .. "_LATE_PROTECT_VS_PRESS",
        "Protect " .. terms.late .. " exactly",
        "Keep pressing for extra damage",
        terms.late .. " already wins if it remains legal through the next exchange.",
        "Late-game expert play protects the exact win path instead of farming avoidable risk.",
        "The protected path no longer wins without one more real conversion.",
        { "score truth", "objective truth", "timing / respawn truth" })

    responses[#responses + 1] = response(mapKey .. "_RESP_RECOVER_REBAIT",
        "Enemy survives the first contact and tries to bait your chase off the score floor.",
        "Rebuild the planted shell, then re-enter only on the next full recovery wave.",
        "The safest counter refuses second-contact tilt when the first finish already failed.",
        terms.hold .. " is re-planted before the next commit leaves.",
        "The next live score event expires before the regroup finishes.")
    responses[#responses + 1] = response(mapKey .. "_RESP_DENY_TRADE",
        "Enemy offers a side trade while their real winning lane stays live.",
        "Refuse the side bargain, deny " .. terms.deny .. ", and only then reopen optional pressure.",
        "Expert counterplay protects the true score floor before accepting decorative map trades.",
        "The denial lane can still be reached with planted coverage intact.",
        "The denial lane is no longer reachable and a different decisive route has opened.")
end

local function appendExpertDepthCoverage(row, mapKey, terms)
    if not row or not terms then return end
    local comparisons = row.comparisons or {}
    local responses = row.responses or {}

    comparisons[#comparisons + 1] = comparison(mapKey .. "_SCOUT_INFO_VS_BLIND_OPEN",
        "Scout the live opening picture first",
        "Commit the opener blind",
        "The first route read is still incomplete and one wrong split would burn the score path.",
        "Expert openers turn information into the cleaner first commit instead of guessing evenly.",
        "The live opening picture is already confirmed and delay would cost arrival.",
        { "enemy roster truth", "movement / location truth", "objective truth" })
    comparisons[#comparisons + 1] = comparison(mapKey .. "_CROSSMAP_PUNISH_VS_FAIR_FIGHT",
        "Punish the cross-map weak lane",
        "Take the fair front-door fight",
        "Enemy movement left one lane materially softer than the obvious contact point.",
        "You punish the longer enemy path instead of donating bodies into their prepared shell.",
        "The weak lane no longer resolves before the front-door score event.",
        { "enemy roster truth", "timing / respawn truth", "objective truth" })
    comparisons[#comparisons + 1] = comparison(mapKey .. "_TRADE_DISCIPLINE_VS_FULL_MATCH",
        "Allow the low-value trade and keep " .. terms.hold,
        "Match every enemy touch equally",
        "The current hold state still wins the score race without funding every side exchange.",
        "Trade discipline protects the lead by answering only the touches that really matter.",
        "The low-value trade actually flips the score path immediately.",
        { "score truth", "objective truth", "counter-response safety" })
    comparisons[#comparisons + 1] = comparison(mapKey .. "_REINFORCE_TIMING_VS_DOUBLE_ROTATE",
        "Reinforce on the exact live timing",
        "Double-rotate bodies early",
        "One precise reinforcement preserves both the current hold and the next route.",
        "Expert timing solves the live lane without opening a second break behind it.",
        "The reinforcement arrives after the event resolves anyway.",
        { "timing / respawn truth", "friendly roster truth", "movement / location truth" })
    comparisons[#comparisons + 1] = comparison(mapKey .. "_ISOLATE_SUPPORT_VS_FULL_SEND",
        "Isolate the support line first",
        "Full-send into the core shell",
        "The support line is more exposed than the protected body or objective center.",
        "Breaking the support layer first creates a safer real conversion window.",
        "The support line cannot be reached without losing the live score event.",
        { "enemy roster truth", "local fight truth", "counter-response safety" })
    comparisons[#comparisons + 1] = comparison(mapKey .. "_ROUTE_DENIAL_VS_BODY_CHASE",
        "Deny the next route",
        "Chase the current body",
        "Cutting the route stops the next score event more reliably than a damage race does.",
        "Movement denial is often the safer expert branch than overcommitting to a protected body.",
        "The current body is already isolated and route denial lands too late.",
        { "movement / location truth", "objective truth", "timing / respawn truth" })
    comparisons[#comparisons + 1] = comparison(mapKey .. "_POST_WIPE_RESET_VS_INSTANT_RETOUCH",
        "Reset after the wipe and rebuild one full wave",
        "Instantly retouch the same lane",
        "The first post-wipe touch would arrive alone into the enemy second wave.",
        "Expert recoveries rebuild timing before trying to reclaim space.",
        "The instant retouch truly lands before enemy stabilization.",
        { "timing / respawn truth", "friendly roster truth", "objective truth" })
    comparisons[#comparisons + 1] = comparison(mapKey .. "_SCORE_FLOOR_VS_HIGH_VARIANCE",
        "Protect the score floor first",
        "Force the higher-variance swing",
        "Staying alive on score still leaves one full comeback branch while the gamble could end the map.",
        "The safe expert line preserves a live win path before chasing the maximum one.",
        "The score floor is already gone unless the high-variance branch lands now.",
        { "score truth", "objective truth", "counter-response safety" })

    responses[#responses + 1] = response(mapKey .. "_RESP_SCOUT_BAIT",
        "Enemy shows an opening picture meant to bait an early blind commit.",
        "Scout the second lane, confirm the real route, and commit only after the weak side is proven.",
        "The safest counter to opener bait is delayed certainty, not mirrored guessing.",
        "Your first commit still lands on time after the second read.",
        "The second read would cost the only live arrival window.")
    responses[#responses + 1] = response(mapKey .. "_RESP_CROSSMAP_TRADE",
        "Enemy offers a fair fight while quietly exposing a cross-map weak lane.",
        "Keep the score floor planted and punish the softer lane the reserve abandoned.",
        "The safe counter attacks the true movement mistake, not the loudest contact point.",
        "The weak lane resolves before the enemy reserve can reconnect.",
        "The fair fight already decides the score before the punish lands.")
    responses[#responses + 1] = response(mapKey .. "_RESP_REINFORCE_TRAP",
        "Enemy tries to force an early double-rotation and break the next lane behind it.",
        "Send one named reinforcement only and preserve the second answer path.",
        "The safest answer is timing discipline instead of overfunding the first panic call.",
        "One reinforcement truly keeps the live lane stable.",
        "The lane already needs a full collapse instead of one reinforcement.")
    responses[#responses + 1] = response(mapKey .. "_RESP_ISOLATED_SUPPORT",
        "Enemy protects the core shell but leaves the support line briefly exposed.",
        "Break the support layer first and convert only after the shell loses its first peel wave.",
        "The safe counter attacks the weaker support seam before the strongest body.",
        "The support line can be reached without losing " .. terms.hold .. ".",
        "The support seam closes before contact and the core shell becomes the only live path.")
    responses[#responses + 1] = response(mapKey .. "_RESP_ROUTE_CUT",
        "Enemy survives direct contact but remains dependent on one route to finish the score event.",
        "Deny the route, force the longer reconnect, and only then re-enter the body fight.",
        "The safe counter removes the next score event instead of tunneling the current brawl.",
        "The route denial lands before the reconnect completes.",
        "The reconnect is already unavoidable and only direct contact remains.")
    responses[#responses + 1] = response(mapKey .. "_RESP_POST_WIPE_RUSH",
        "Enemy rushes the post-wipe lane before your next full recovery wave is planted.",
        "Reset the first touch, name the score-floor defenders, and contest only with the rebuilt wave.",
        "The safe counter protects recovery timing instead of accepting staggered deaths.",
        terms.hold .. " is re-planted before the next full commit leaves.",
        "The rebuilt wave misses the only live score event unless you touch immediately.")
    responses[#responses + 1] = response(mapKey .. "_RESP_SCORE_FLOOR_BAIT",
        "Enemy tempts a high-variance swing while your score floor is still the real vulnerable branch.",
        "Protect the floor first, then reopen the larger swing only if the map stays live afterward.",
        "The safest counter preserves the surviving win path before chasing maximum greed.",
        "The floor can still be protected without giving up the whole map.",
        "The floor is already gone and the swing is now the only remaining path.")
    responses[#responses + 1] = response(mapKey .. "_RESP_LAST_WINDOW_DENY",
        "Enemy holds one final desperation route that can still flip the game in the last window.",
        "Deny the last live route first and refuse any optional chase that abandons it.",
        "The safe late-game counter is to remove the last enemy score event before anything decorative.",
        terms.deny .. " can still be planted before it resolves.",
        "That final route is already dead and another score event has overtaken it.")
end

for mapKey, row in pairs(DATA) do
    appendExpandedCoverage(row, mapKey, EXPANSION_TERMS[mapKey])
    appendAdvancedCoverage(row, mapKey, EXPANSION_TERMS[mapKey])
    appendExpertDepthCoverage(row, mapKey, EXPANSION_TERMS[mapKey])
end

function DoctrineComparisons:Get(mapKey)
    return DATA[mapKey]
end

function DoctrineComparisons:Count(mapKey)
    if mapKey then
        local row = DATA[mapKey]
        return row and #(row.comparisons or {}) or 0
    end
    local count = 0
    for _, row in pairs(DATA) do
        count = count + #(row.comparisons or {})
    end
    return count
end

function DoctrineComparisons:CountResponses(mapKey)
    if mapKey then
        local row = DATA[mapKey]
        return row and #(row.responses or {}) or 0
    end
    local count = 0
    for _, row in pairs(DATA) do
        count = count + #(row.responses or {})
    end
    return count
end

function DoctrineComparisons:GetComparison(mapKey, index)
    local row = DATA[mapKey]
    if not row or not row.comparisons[index] then
        return nil
    end
    return KWR.Util:Copy(row.comparisons[index])
end

function DoctrineComparisons:GetResponse(mapKey, index)
    local row = DATA[mapKey]
    if not row or not row.responses[index] then
        return nil
    end
    return KWR.Util:Copy(row.responses[index])
end

function DoctrineComparisons:SelectComparison(mapKey, context)
    local row = DATA[mapKey]
    if not row or not row.comparisons[1] then
        return nil
    end
    context = type(context) == "table" and context or {}
    local flags = context.flags or {}
    local currentState = context.currentState
    local prediction = context.prediction or {}
    local kind = context.kind

    local selectedIndex = 1
    if currentState == "OPENING" and not flags.waveAdvantage then
        selectedIndex = 13
    elseif currentState == "OPENING" and flags.enemyOvercommit and flags.waveAdvantage then
        selectedIndex = 14
    elseif currentState == "STABILIZE" and flags.projectedWin and not flags.objectiveContestable then
        selectedIndex = 15
    elseif currentState == "STABILIZE" and flags.onlyDefenderWouldMove then
        selectedIndex = 16
    elseif currentState == "PRESSURE" and flags.enemyOvercommit and flags.objectiveContestable then
        selectedIndex = 17
    elseif currentState == "PRESSURE" and flags.waveAdvantage and not flags.enemyOvercommit then
        selectedIndex = 18
    elseif currentState == "RECOVERY" and flags.arrivalAfterResolution and flags.projectedLoss then
        selectedIndex = 19
    elseif currentState == "RECOVERY" and flags.projectedLoss and not flags.waveAdvantage then
        selectedIndex = 20
    elseif currentState == "ENDGAME" or (flags.projectedWin and (prediction.urgency or 0) >= 85) then
        selectedIndex = 12
    elseif flags.projectedLoss and flags.enemyOvercommit then
        selectedIndex = 11
    elseif currentState == "RECOVERY" or prediction.status == "LOSE" then
        selectedIndex = 7
    elseif (prediction.urgency or 0) >= 85 or flags.delayWins then
        selectedIndex = 10
    elseif kind == "FLAG" and flags.objectiveContestable then
        selectedIndex = 9
    elseif flags.friendlyWaveSplit then
        selectedIndex = 6
    elseif flags.enemyOvercommit or currentState == "OPENING" then
        selectedIndex = 8
    elseif currentState == "STABILIZE" or prediction.status == "WIN" then
        selectedIndex = 5
    elseif kind == "ORB" or kind == "CART" or kind == "RESOURCE" or kind == "HYBRID" then
        selectedIndex = 9
    end

    return KWR.Util:Copy(row.comparisons[selectedIndex] or row.comparisons[1])
end

function DoctrineComparisons:SelectResponse(mapKey, context)
    local row = DATA[mapKey]
    if not row or not row.responses[1] then
        return nil
    end
    context = type(context) == "table" and context or {}
    local flags = context.flags or {}
    local compThreat = context.compThreat or {}
    local defenseModel = context.defenseModel or {}

    local selectedIndex = 4
    if currentState == "OPENING" and not flags.waveAdvantage then
        selectedIndex = 13
    elseif currentState == "OPENING" and flags.enemyOvercommit and flags.waveAdvantage then
        selectedIndex = 14
    elseif currentState == "STABILIZE" and flags.onlyDefenderWouldMove then
        selectedIndex = 15
    elseif currentState == "PRESSURE"
        and (defenseModel.id == "HEALER_BUNKER"
            or defenseModel.id == "ESCORT_SHELL"
            or compThreat.id == "BUNKER_DEFENSE"
            or compThreat.id == "CARRIER_ESCORT") then
        selectedIndex = 16
    elseif currentState == "PRESSURE" and flags.waveAdvantage and flags.objectiveContestable then
        selectedIndex = 17
    elseif currentState == "RECOVERY" and flags.arrivalAfterResolution and flags.projectedLoss then
        selectedIndex = 18
    elseif flags.projectedLoss and not flags.waveAdvantage then
        selectedIndex = 19
    elseif flags.oneScoringEventRequired and (flags.projectedWin or flags.projectedLoss) then
        selectedIndex = 20
    elseif flags.projectedWin and (context.prediction and (context.prediction.urgency or 0) >= 85) then
        selectedIndex = 12
    elseif flags.projectedLoss and flags.enemyOvercommit then
        selectedIndex = 11
    elseif defenseModel.id == "HEALER_BUNKER"
        or defenseModel.id == "ESCORT_SHELL"
        or compThreat.id == "BUNKER_DEFENSE"
        or compThreat.id == "CARRIER_ESCORT" then
        selectedIndex = 8
    elseif compThreat.id == "DOUBLE_STEALTH_ASSAULT"
        or compThreat.id == "HIGH_MOBILITY_SPLIT"
        or compThreat.id == "OBJECTIVE_TRADE" then
        selectedIndex = 5
    elseif flags.enemyOvercommit then
        selectedIndex = 7
    elseif (context.kind == "FLAG" and flags.objectiveContestable)
        or flags.projectedLoss then
        selectedIndex = 9
    elseif flags.projectedWin and (context.prediction and (context.prediction.urgency or 0) >= 85) then
        selectedIndex = 10
    elseif context.kind == "RESOURCE" then
        selectedIndex = 6
    end

    return KWR.Util:Copy(row.responses[selectedIndex] or row.responses[1])
end

KWR:RegisterModule("DoctrineComparisons", DoctrineComparisons)
