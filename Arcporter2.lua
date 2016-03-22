
--
-- Arcporter
--   by: James Harless
--

require "math"
require "table"
require "unicode"

require "lib/lib_Callback2"
require "lib/lib_Colors"
require "lib/lib_Debug"
require "lib/lib_PanelManager"
require "lib/lib_RowChoice"
require "lib/lib_RowScroller"
require "lib/lib_Spinner"
require "lib/lib_Tabs"
require "lib/lib_TextFormat"
require "lib/lib_Tooltip"
require "lib/lib_Unlocks"
require "lib/lib_UserKeybinds"
require "lib/lib_WebCache"
require "lib/lib_math"
require "lib/lib_table"

require "./lib/lib_QueueButton"

Debug.EnableLogging(false)


-- ------------------------------------------
-- CONSTANTS
-- ------------------------------------------
local MAIN = Component.GetFrame("main")

local QUEUE_PAGE = Component.GetWidget("queue_page")

local FOSTER_CONTAINER = Component.GetWidget("foster_container")


local DETAILSCREENSHOT = MultiArt.Create(Component.GetWidget("detailscreenshot"))
local DETAILSCROLLER = RowScroller.Create(Component.GetWidget("detail_scroller"))
local DETAILTEXT = Component.GetWidget("detail_text")
local THUMBNAILS = Component.GetWidget("thumbnails")
local THUMBNAIL_CHOICE = RowChoice.Create(THUMBNAILS, 1)

local TABS_GROUP = Component.GetWidget("tabs")
local LABEL_CHOOSE = Component.GetWidget("choose_label")
local LABEL_NO_INSTANCE = Component.GetWidget("no_instance_label")

local QUEUE_DETAIL = Component.GetWidget("queue_detail")
local QUEUE_LABEL = Component.GetWidget("queue_label")
local QUEUE_DAILY = QUEUE_DETAIL:GetChild("daily_completion")
local QUEUE_DAILY_ICON = QUEUE_DAILY:GetChild("icon_grp.icon")
local QUEUE_DAILY_LABEL = QUEUE_DAILY:GetChild("label")
local QUEUE_DAILY_FOCUS = QUEUE_DETAIL:GetChild("daily_focus")

local HARDCORE_BACKGROUND = Component.GetWidget("hardcore_background")

local QUEUE_CONTAINER = Component.GetWidget("queue_container")
local QUEUEBUTTON_GROUP = Component.GetWidget("queue_group")

local DIFF_RADIO_GROUP = Component.GetWidget("diff_radio_group")
local RADIO_NORMAL = Component.GetWidget("radio_normal")
local RADIO_HARD = Component.GetWidget("radio_hard")
local RADIO_CHALLENGE = Component.GetWidget("radio_challenge")

local TRAVEL_CONTAINER = Component.GetWidget("travel_container")
local TRAVEL_BUTTON = Component.GetWidget("travel_group")

local TOOL_TIP

-- Interactable Widgets



local CATEGORY_TABS = Tabs.Create(3, TABS_GROUP)

local CHECK_SELECTALL
local QUEUEBUTTON
local RS_INSTANCES
local w_INSTANCEPLATES = {}
local w_DetailText

local c_FADE_DUR = 0.2

local c_HOST_ASSETS
local c_CACHE_LIFETIME = 30

local MODE_OFF = 0          -- Not in use
local MODE_TERMINAL = 1     -- Player is viewing an terminal gate
local MODE_BROWSER = 2      -- Player looking at all available instances
local MODE_SOCIAL = 3       -- Player has Social Panel up looking at all available instances

local CAT_TERMINAL = 0
local CAT_CAMPAIGN = 1
local CAT_MISSION = 2
local CAT_TRAVEL = 3
local CAT_UNKNOWN = 4

local GAMETYPE_CAMPAIGN = "campaign"        -- Campaign, Mission based Instances
local GAMETYPE_MISSION = "mission"          -- Free to access Instances
local GAMETYPE_RAID = "raid"                -- Raids, only accessable via Terminals
local GAMETYPE_TRAVEL = "travel"            -- Travel, restrictions based on current player zone
local GAMETYPE_NEWBIE = "firstimpression"   -- Newbie Instances
local GAMETYPE_UNKNOWN = "unknown"          -- Gametypes that don't fit any category or are missing

local SOUND_CLICK       = "select_item"
local SOUND_CONFIRM     = "confirm"

local TYPE_TRANSFER             = "TRANSFER"
local TYPE_MATCHMAKER_PVE       = "MATCHMAKER_PVE"
local TYPE_MATCHMAKER_PVP       = "MATCHMAKER_PVP"
local TYPE_ARCFOLDER            = "ARCFOLDER"

local DIFFICULTY_NORMAL         = "INSTANCE_DIFFICULTY_NORMAL"
local DIFFICULTY_HARD           = "INSTANCE_DIFFICULTY_HARD"
local DIFFICULTY_CHALLENGE      = "INSTANCE_DIFFICULTY_CHALLENGE"

local c_TerminalTypeIds = {
    [1698] = CAT_CAMPAIGN,
}

local c_ValidType = {
    [TYPE_TRANSFER]         = CAT_TRAVEL,   -- Zone change
    [TYPE_MATCHMAKER_PVE]   = true,         -- Group PVE
    [TYPE_MATCHMAKER_PVP]   = true,         -- Group PVP
    [TYPE_ARCFOLDER]        = CAT_TRAVEL,   -- Arcporter
}

local c_SquadTypes = {
    ["pvp"] = "HOLMGANG_BATTLEFRAMES",
    ["adventure"] = "SQUAD_BATTLEFRAMES",
    ["platoon"] = "PLATOON_BATTLEFRAMES",
}

local c_GameTypesLookup = {
    [GAMETYPE_CAMPAIGN] = CAT_CAMPAIGN,
    [GAMETYPE_MISSION] = CAT_MISSION,
    [GAMETYPE_RAID] = CAT_MISSION,
    [CAT_TRAVEL] = CAT_TRAVEL,
}

local COLORS_GAMETYPE = {
    [GAMETYPE_CAMPAIGN] = Component.LookupColor("arc_campaign"),
    [GAMETYPE_MISSION]  = Component.LookupColor("arc_mission"),
    [GAMETYPE_RAID]     = Component.LookupColor("arc_raid"),
    [GAMETYPE_TRAVEL]   = Component.LookupColor("arc_area"),
    [GAMETYPE_UNKNOWN]  = Component.LookupColor("red"),
}

local COLOR_TOOLTIP_NAMES = Component.LookupColor("squad")

local REQ_MINLEVEL = 1
local REQ_GROUP_SIZE = 2
local REQ_CERT = 3
local REQ_NO_HARDCORE = 4
local REQ_NO_CHALLENGE = 5

local c_REASONS ={
    [REQ_MINLEVEL] = "ARC_REQ_LEVEL",
    [REQ_GROUP_SIZE] = "ARC_REQ_GROUP_SIZE",
    [REQ_CERT] = "ARC_REQ_CERT",
    [REQ_NO_HARDCORE] = "ARC_REQ_NO_HARDCORE",
    [REQ_NO_CHALLENGE] = "ARC_REQ_NO_CHALLENGE",
}

local COLOR_DAILY_AVAIL = "4477CC"
local COLOR_DAILY_COMPLETE = "55AA55"

-- ------------------------------------------
-- VARIABLES
-- ------------------------------------------
-- Panel

local g_Open = false
local g_Fostering = false
local g_WebUrls = {}

local g_Mode = MODE_OFF

local g_ButtonState = BTN_MODE_AVAILABLE

local g_ZoneQueueIdLookupReady = false

local g_ZoneQueueIdLookup
local g_ZoneListing = {
    [CAT_TERMINAL] = {},
    [CAT_CAMPAIGN] = {},
    [CAT_MISSION] = {},
    [CAT_TRAVEL] = {},
    [CAT_UNKNOWN] = {},
}

-- Queueing
local g_SelectedQueues = {} -- Populated with selected zone queue ids

local g_ZoneList = {}

local g_CampaignMissionIds = {} -- Enabled Campaign Missions (Received from Mission Ledger)

local g_WorldTravel = false
local g_SelectedIP

local g_Difficulty = DIFFICULTY_NORMAL

local g_QueueData
local d_QueueRestrictions = {}

-- Player
local g_PlayerName
local g_PlayerLevel
local g_UnlockedCerts
local g_ActiveMissions = {}

-- ------------------------------------------
-- EVENTS
-- ------------------------------------------
function OnComponentLoad()
    Key = UserKeybinds.Create()
    Key:RegisterAction("Arcporter2_Frame", function() ChangeMode(MODE_BROWSER, CAT_TRAVEL) end)
    Key:BindKey("Arcporter2_Frame", "F11")

    MAIN:SetParam("alpha", 0)

    c_HOST_ASSETS = System.GetOperatorSetting("ingame_host")

    QUEUEBUTTON = QueueButton.Create(QUEUEBUTTON_GROUP)
    QUEUEBUTTON:SkipMatchmaking(true)
    --QUEUEBUTTON:AddHandler("OnStatusUpdate", RefreshAll_InstancePlates)
    TRAVEL_BUTTON:BindEvent("OnSubmit", function()
        local success = Game.RequestTransfer(g_SelectedIP.zone_id, 0)
        TRAVEL_BUTTON:Enable(not success)
        System.PlaySound(SOUND_CONFIRM)
        -- Needs proper error handling
        if not success then
            Debug.Error("Failed to transfer to ZoneId: "..tostring(g_SelectedIP.zone_id))
        end
    end)

    InitializeRadioButtons()

    QUEUE_DAILY_FOCUS:BindEvent("OnMouseEnter", function()
        Tooltip.Show(Component.LookupText("DAILY_COMPLETION_DESC"))
    end)
    QUEUE_DAILY_FOCUS:BindEvent("OnMouseLeave", function()
        Tooltip.Show(nil)
    end)

    -- Instances RowScroller
    RS_INSTANCES = RowScroller.Create(Component.GetWidget("listing"))
    RS_INSTANCES:SetSliderMargin(25, 0)
    RS_INSTANCES:SetSpacing(2)
    RS_INSTANCES:UpdateSize()

    -- Detail Text
    w_DetailText = DETAILSCROLLER:AddRow(DETAILTEXT)
    w_DetailText:SetWidget(DETAILTEXT)

    -- Tabs, based off of index. Id is used to determine QueueButton display mode.
    local tab_tints = {}
    for k,v in pairs(COLORS_GAMETYPE) do
        local hsv = Colors.toHSV(v)
        hsv.v = 1
        tab_tints[k] = Colors.Create(hsv)
    end
    CATEGORY_TABS:SetTab(1, {id=GAMETYPE_CAMPAIGN, label_key="CAMPAIGN", texture="icons_arcporter", region="campaign", tint=tab_tints[GAMETYPE_CAMPAIGN]})
    CATEGORY_TABS:SetTab(2, {id=GAMETYPE_MISSION, label_key="ACH_OPERATIONS", texture="icons_arcporter", region="mission", tint=tab_tints[GAMETYPE_MISSION]})
    CATEGORY_TABS:SetTab(3, {id=GAMETYPE_TRAVEL, label_key="TRAVEL", texture="icons_arcporter", region="travel", tint=tab_tints[GAMETYPE_TRAVEL]})

    CATEGORY_TABS:AddHandler("OnTabChanged", function(args)
        g_WorldTravel = ( args.index == CAT_TRAVEL )
        g_SelectedIP = nil
        HARDCORE_BACKGROUND:ParamTo("alpha", 0, 0.2, "smooth")
        TRAVEL_CONTAINER:Show(g_WorldTravel)
        QUEUE_CONTAINER:Show(not g_WorldTravel)
        if g_WorldTravel then
            TRAVEL_BUTTON:Disable()
        end
        if(args.id == "campaign") then
            ClearAll_Instances()
            RefreshInstanceList(args.index)
            RADIO_NORMAL:SetCheck(true)
        else
            local hardmode = g_Difficulty == DIFFICULTY_HARD
            RADIO_NORMAL:SetCheck(true)
            ClearAll_Instances()
            RefreshInstanceList(args.index)
        end
    end)

    -- Thumbnail
    THUMBNAIL_CHOICE:SetChoiceBounds(54, 98)
    THUMBNAIL_CHOICE:BindOnSelect(function(args)
        DETAILSCREENSHOT:SetTexture(args.texture, args.region)
    end)

    Unlocks.Subscribe("certificate")
    Unlocks.OnUpdate("certificate", function(certs)
        g_UnlockedCerts = certs
        RefreshAll_InstancePlates()
    end)

    TOOL_TIP = Component.CreateWidget("req_tooltip", FOSTER_CONTAINER)

    g_WebUrls["zone_list"] = WebCache.MakeUrl("zone_list")
    WebCache.Subscribe(g_WebUrls["zone_list"], OnZoneListResponse, false)

    PanelManager.RegisterFrame(MAIN, ToggleWindow, {show=false})
end

function OnPlayerReady(args)
    g_PlayerName = Player.GetInfo()
    g_PlayerLevel = Player.GetLevel()
    g_QueueData = Game.GetPvPQueue()
    RefreshZoneCache()
    OnSquadQueueEligibility()
end

function OnLevelChanged(args)
    g_PlayerLevel = Player.GetLevel()
    OnSquadQueueEligibility()
end

function OnEnterZone(args)
    RefreshZoneCache()
end

function OnSquadQueueEligibility(args)
    d_QueueRestrictions = {}
    if IsPlayerInGroup() then
        local squadData = Squad.GetQueueRestrictions()
        local roster = Squad.GetRoster()
        local members = {}
        if roster and roster.members then
            for _,member in ipairs(roster.members) do
                members[tostring(member.chatId)] = member.name
            end
        end
        for _, member in ipairs(squadData) do
            if member.restrictions then
                AddQueueRestrictions(member.restrictions, members[tostring(member.chatId)])
            else
                Debug.Warn("No restrictions for member!")
            end
        end
    else
        local playerData = Player.GetQueueRestrictions()
        if playerData then
            AddQueueRestrictions(playerData, g_PlayerName)
        else
            Debug.Warn("No restrictions received from Player.GetQueueRestrictions()")
        end
    end

    RefreshAll_InstancePlates()
    QUEUEBUTTON:OnEvent(args)
end

function OnMissionStatusUpdate(args)
    if args.status == "engaged" then
        g_ActiveMissions[args.missionId] = true
    else
        g_ActiveMissions[args.missionId] = nil
    end
end

function OnPVPToggle(args)

end

function OnPvPCancel(args)

end

function OnMatchmakerToggle(args)

end

function MatchList_Toggle(args)

end

function OnMyMessageHandler(args)

end

function OnMatchQueueResponse(args)
    QUEUEBUTTON:OnEvent(args)

end

function OnMyHardcoreToggle(args)

end

function OnMatchQueueUpdate(args)
    g_QueueData = Game.GetPvPQueue()
    RefreshAll_InstancePlates()
    QUEUEBUTTON:OnEvent(args)

    if (args.foundMatch) then
        local matchData = Game.GetFoundMatch()

        if (matchData and matchData.state == "Launching") then
            OnClose()
        end
    end
end

function OnMatchForceUnqueue(args)

end

function OnZoneQueueIdResponse(args)
    g_ZoneQueueIdLookup = {}
    for zoneId,queueId in pairs(args) do
        g_ZoneQueueIdLookup[tonumber(zoneId)] = tonumber(queueId)
    end
    GetZoneListing()
    g_ZoneQueueIdLookupReady = true
end

function OnOpen()
    g_Open = true
    PanelManager.OnShow(MAIN)
    Component.SetInputMode("cursor")
    System.PlaySound("panel_open")
end

function OnClose()
    g_Open = false
    ChangeMode(MODE_OFF)
    PanelManager.OnHide(MAIN)
    Component.SetInputMode("game")
    System.PlaySound("panel_close")
end

function OnEscape()
    ChangeMode(MODE_OFF)
    ToggleWindow({show=false})
end

-- ------------------------------------------
-- PANEL FUNCTIONS
-- ------------------------------------------
function ToggleWindow(args)
    local hide
    local visible = MAIN:IsVisible()
    if args.show == true or args.hide == false then
        hide = false
    elseif args.show == false or args.hide == true then
        hide = true
    else
        hide = visible
    end
    if hide and visible then
        Tooltip.Show(nil)
        MAIN:ParamTo("alpha", 0, c_FADE_DUR)
        MAIN:Show(false, c_FADE_DUR)
    elseif not hide and not visible then
        MAIN:Show(true);
        MAIN:ParamTo("alpha", 1, c_FADE_DUR)
    end
end

function ChangeMode(newMode, tab_index)
    local oldMode = g_Mode
    g_Mode = newMode

    -- Always purge between modes
    ClearAll_InstancePlates()
    QUEUEBUTTON:SetSelectedQueues(nil)

    if oldMode == MODE_OFF then
        g_PlayerLevel = Player.GetLevel()
    elseif oldMode == MODE_TERMINAL then
    elseif oldMode == MODE_BROWSER then
    --elseif oldMode == MODE_SOCIAL then
    --  Component.ParentWidget(QUEUE_PAGE, nil)
    end

    if newMode == MODE_OFF then
        Preview_Clearall()
        CATEGORY_TABS:DeselectTab()
    elseif newMode == MODE_TERMINAL then
        ToggleWindow({show=true})
        TABS_GROUP:Show(false)
        LABEL_CHOOSE:Show(true)
        TRAVEL_CONTAINER:Show(false)
        QUEUE_CONTAINER:Show(true)
    elseif newMode == MODE_BROWSER then
        ToggleWindow({show=true})
        CATEGORY_TABS:Select(tab_index or 1)
        TABS_GROUP:Show(true)
        LABEL_CHOOSE:Show(false)
    --elseif newMode == MODE_SOCIAL then
    --  Component.ParentWidget(QUEUE_PAGE, c_SocialFoster, "full")
    end
end

function InstancePlate_Create()
    local GROUP = Component.CreateWidget("instanceplate", FOSTER_CONTAINER)
    local IP = {
        -- Widgets
        GROUP = GROUP,
        TYPEBAR = GROUP:GetChild("typebar"),
        HIGHLIGHT = GROUP:GetChild("highlight"),
        ICON = MultiArt.Create(GROUP:GetChild("thumbnail.icon")),
        CHECK = GROUP:GetChild("thumbnail.check"),
        QUEUED = GROUP:GetChild("thumbnail.queued"),
        INFO = GROUP:GetChild("info"),
        NAME = GROUP:GetChild("info.name"),
        SUBTEXT = GROUP:GetChild("info.subtext"),
        FOCUSBOX = GROUP:GetChild("FocusBox"),

        DETAIL = GROUP:GetChild("info.detail"),
        REQ = GROUP:GetChild("info.detail.req"),
        LEVEL_MIN_GROUP = GROUP:GetChild("info.detail.level_min"),
        LEVEL_MIN = GROUP:GetChild("info.detail.level_min.label"),
        PLAYER_COUNT_GROUP = GROUP:GetChild("info.detail.player_count"),
        PLAYER_COUNT = GROUP:GetChild("info.detail.player_count.label"),

        DAILY_COMPLETE = GROUP:GetChild("info.daily_completion"),

        SOV_DETAIL = GROUP:GetChild("info.sov_detail"),
        SOV = GROUP:GetChild("info.sov_detail.sov"),
        SOV_OWNER_GROUP = GROUP:GetChild("info.sov_detail.sov_owner"),
        SOV_LABEL = GROUP:GetChild("info.sov_detail.sov_owner.label"),






        -- Variables
        data = {},          -- Raw Data
        zone_id = -1,
        queue_id = -1,
        selected = false,
        selected_detail = false,
        enabled = true,
        is_visible = true,
        is_raid = false,
        ignore_difficulty = false,
        hasHardmode = false,
        mi_id = -1,
        mi_unlocked = false,
        mi_completed = false,
        mi_active = false,
        hasCerts = true,
        groupsize = {
            1,
            1,
        },
        screenshots = {},

        certs = {},
        difficulty = {},
        reasons ={
            [REQ_MINLEVEL] = {meetsReq=true, names={}},
            [REQ_GROUP_SIZE] = {meetsReq=true, names={}},
            [REQ_CERT] = {meetsReq=true, names={}},
            [REQ_NO_HARDCORE] = {meetsReq=true},
            [REQ_NO_CHALLENGE] = {meetReq=true},
        },

        -- Functions
        SetInstance = InstancePlate_SetInstance,
        SetDifficulty = InstancePlate_SetDifficulty,
        Refresh = InstancePlate_Refresh,
        Select = InstancePlate_Select,
        Destroy = InstancePlate_Destroy,

    }
    IP.ROW = RS_INSTANCES:AddRow(GROUP)
    IP.ROW:UpdateSize({height=91})

    IP.REQ:SetDims("left:_; top:_; height:_; width:"..IP.REQ:GetTextDims().width+8)
    IP.SOV:SetDims("left:_; top:_; height:_; width:"..IP.SOV:GetTextDims().width+8)

    IP.FOCUSBOX:BindEvent("OnMouseDown", function()
        InstancePlateCheck_OnMouseDown(IP)
    end)

    IP.FOCUSBOX:BindEvent("OnMouseEnter", function()
        local has_reason = false
        for reason_type, reason in ipairs(IP.reasons) do
            if not reason.meetsReq then
                has_reason = true
            end
        end

        if has_reason then
            InstancePlate_ShowReasonToolTip(IP)
        end
    end)

    IP.FOCUSBOX:BindEvent("OnMouseLeave", function()
        Tooltip.Show(nil)
    end)

    table.insert(w_INSTANCEPLATES, IP)

    return IP
end

function InstancePlate_Destroy(IP)
    if IP.ROW then
        IP.ROW:Remove()
    end
    IP.ICON:Destroy()
    Component.RemoveWidget(IP.GROUP)

    IP = nil
end

function InstancePlate_SetInstance(IP, instance)
    local zoneInfo = Game.GetZoneInfo(instance.zone_id)
    IP.zone_id = instance.zone_id
    IP.queue_id = instance.id
    IP.category_id = instance.category_id
    IP.name = instance.name
    if instance.description and instance.description ~= "" then
        IP.description = instance.description
    else
        IP.description = zoneInfo.name.." has no Description."
        Debug.Warn(IP.description)
    end
    -- Campaign
    if instance.mission_id and type(instance.mission_id) == "number" then
        local mi_info = Player.GetMissionInfo(instance.mission_id)
        if not mi_info then
            Debug.Warn("No mission info for mission id"..tostring(instance.mission_id))
            IP.mi_id = instance.mission_id
            IP.mi_unlocked = false--(g_PlayerLevel >= mi_info.level_req)
            IP.mi_completed = false--(mi_info.timesCompleted > 0)
            IP.mi_active = false --(mi_info.status == "engaged")
            IP.is_visible = false --(IP.mi_unlocked or IP.mi_completed or IP.mi_active)
        else
            IP.mi_id = instance.mission_id
            IP.mi_unlocked = (g_PlayerLevel >= mi_info.level_req)
            IP.mi_completed = (mi_info.timesCompleted > 0)
            IP.mi_active = (mi_info.status == "engaged")
            IP.is_visible = (IP.mi_unlocked or IP.mi_completed or IP.mi_active)
        end
    end

    -- Difficulty Modes
    if instance.gametype ~= "travel" or instance.difficulty_levels and #instance.difficulty_levels > 0 then
        -- Difficulty Levels
        if instance.difficulty_levels then
            for i, difficulty in ipairs(instance.difficulty_levels) do
                local level = difficulty.ui_string
                if level == DIFFICULTY_NORMAL or level == DIFFICULTY_HARD or level == DIFFICULTY_CHALLENGE then
                    IP.difficulty[level] = difficulty
                else
                    Debug.Warn("Unknown difficulty type: "..level)
                end
            end
        end
        -- Check to ensure we have at least 1 difficulty level, if not. We fake it.
        if not IP.difficulty[DIFFICULTY_NORMAL] and not IP.difficulty[DIFFICULTY_HARD] and not IP.difficulty[DIFFICULTY_CHALLENGE] then
            IP.difficulty[DIFFICULTY_NORMAL] = {
                min_level = 1,
                ui_string = DIFFICULTY_NORMAL,
                zone_setting_id = instance.id,
                id = 0,
            }
        end
        IP.hasHardmode = IP.difficulty[DIFFICULTY_HARD] ~= nil

        -- Certs
        if instance.cert_requirements then
            for k, cert in ipairs(instance.cert_requirements) do
                local hasCert = Unlocks.HasUnlock("certificate", cert.cert_id)
                if ((cert.authorize_position=="first" or cert.authorize_position=="leader") and IsPlayerGroupLeader())
                or cert.authorize_position=="all" or cert.authorize_position=="any" then
                    if not hasCert and cert.presence == "present" then
                        IP.hasCerts = false
                    elseif hasCert and cert.presence == "absent" then
                        IP.hasCerts = false
                    end
                end
            end
        end
    else
        IP.ignore_difficulty = true
        IP.min_level = instance.min_level
    end

    IP.groupsize[1] = instance.min_players_per_team
    IP.groupsize[2] = instance.max_players_per_team
    IP.is_raid = ( instance.min_players_per_team > Squad.GetMaxSquadSize() )

    local bar_tint = COLORS_GAMETYPE[instance.gametype] or COLORS_GAMETYPE[GAMETYPE_UNKNOWN]
    IP.TYPEBAR:SetParam("tint", bar_tint)
    if Component.CheckTextureExists(tostring(instance.zone_id)) then
        IP.ICON:SetTexture(tostring(instance.zone_id))
        IP.ICON:SetRegion("tbn")
        IP.ICON:Show(true)
    else
        IP.ICON:Show(false)
    end
    IP.NAME:SetText(instance.name)
    IP.SUBTEXT:SetText(zoneInfo.sub_title)
    if instance.max_players_per_team == 1 then
        IP.PLAYER_COUNT:SetText(Component.LookupText("ARCPORTER_SIZE_SOLO"))
    else
        IP.PLAYER_COUNT:SetText(Component.LookupText("ARCPORTER_SIZE_GROUP", instance.min_players_per_team, instance.max_players_per_team))
    end

    IP.LEVEL_MIN_GROUP:Show(false)
    IP.PLAYER_COUNT_GROUP:Show(true)
    IP.PLAYER_COUNT_GROUP:SetDims("left:_; top:_; height:_; width:"..IP.PLAYER_COUNT:GetTextDims().width+8)
    IP.DETAIL:Show(instance.category_id ~= CAT_TRAVEL)

    if instance.category_id == CAT_TRAVEL and instance.sovereignty and instance.sovereignty ~= "" then
        IP.SOV_DETAIL:Show()
        IP.SOV_LABEL:SetText(instance.sovereignty)
        IP.SOV_OWNER_GROUP:SetDims("left:_; top:_; height:_; width:"..IP.SOV_LABEL:GetTextDims().width+8)
    end

    IP:Refresh()
    DebugLogPlateValues(IP)
end

function InstancePlate_ShowReasonToolTip(IP)
    local width, height = 0
    local vpadding, hpadding = 0
    local dims

    local tool_list = TOOL_TIP:GetChild("reason_list")
    vpadding = tool_list:GetVPadding()
    hpadding = tool_list:GetHPadding()
    local meets_hardcore = IP.reasons[REQ_NO_HARDCORE].meetsReq

    local hardcore_req = tool_list:GetChild("hardcore_req")
    if not meets_hardcore then
        hardcore_req:Show();
        local hardcore_reason = hardcore_req:GetChild("reason")
        dims = hardcore_reason:GetTextDims();
        hardcore_req:SetDims("top:_; left:_; width:"..tostring(dims.width + hpadding).."; height:_")
    else
        hardcore_req:Hide();
    end

    local CHALLENGE_REASON = tool_list:GetChild("challenge_req")
    if not IP.reasons[REQ_NO_CHALLENGE].meetsReq then
        CHALLENGE_REASON:Show()
        local REASON = CHALLENGE_REASON:GetChild("reason")
        dims = REASON:GetTextDims()
        CHALLENGE_REASON:SetDims("top:_; left:_; width:"..tostring(dims.width + hpadding).."; height:_")
    else
        CHALLENGE_REASON:Show(false)
    end

    local group_req = tool_list:GetChild("group_req")
    if not IP.reasons[REQ_GROUP_SIZE].meetsReq and meets_hardcore then
        group_req:Show()
        local group_req_reason = group_req:GetChild("reason")
        group_req_reason:SetText(Component.LookupText(c_REASONS[REQ_GROUP_SIZE], IP.groupsize[1], IP.groupsize[2]))
        dims = group_req_reason:GetTextDims();
        group_req:SetDims("top:_; left:_; width:"..tostring(dims.width + hpadding).."; height:_")
    else
        group_req:Hide()
    end

    local level_req = tool_list:GetChild("level_req")
    if not IP.reasons[REQ_MINLEVEL].meetsReq and meets_hardcore then
        level_req:Show()
        local level_req_reason = level_req:GetChild("reason")
        local difficulty = IP.difficulty[g_Difficulty]
        level_req_reason:SetText(Component.LookupText(c_REASONS[REQ_MINLEVEL], difficulty.min_level))
        dims = level_req_reason:GetTextDims()
        level_req_reason:SetDims("top:_; left:_; width:"..tostring(dims.width + hpadding).."; height:_")

        local level_req_names = level_req:GetChild("names")
        local names= IP.reasons[REQ_MINLEVEL].names
        --[[for i=#names + 1, 20 do
            table.insert(names, "PlayerName")
        end]]
        if #names > 0 then
            level_req_names:Show()
            local TF = TextFormat.Create()
            TF:AppendColor(COLOR_TOOLTIP_NAMES)
            TF:AppendText(names[1])

            for i = 2, #names do
                if (i - 1) % 5 ~= 0 then
                    TF:AppendText(" ")
                else
                    TF:AppendText("\n")
                end
                TF:AppendText(names[i])
            end

            TF:ApplyTo(level_req_names)

            dims = level_req_names:GetTextDims()
            level_req_names:SetDims("top:_; left:_; width:"..tostring(dims.width + hpadding).."; height:"..tostring(dims.height ))

            dims= level_req:GetContentBounds()
            level_req:SetDims("top:_; left:_; width:"..tostring(dims.width).."; height:"..tostring(dims.height))
        else
            level_req_names:Hide()
        end
    else
        level_req:Hide()
    end

    local cert_req = tool_list:GetChild("cert_req")
    if not IP.reasons[REQ_CERT].meetsReq and meets_hardcore then
        cert_req:Show()
        local cert_req_reason = cert_req:GetChild("reason")
        dims = cert_req_reason:GetTextDims()
        cert_req_reason:SetDims("top:_; left:_; width:"..tostring(dims.width + hpadding).."; height:"..tostring(dims.height))

        local cert_req_names = cert_req:GetChild("names")
        local names= IP.reasons[REQ_CERT].names
        --[[for i=#names + 1, 20 do
            table.insert(names, "PlayerName")
        end]]
        if #names > 0 then
            cert_req_names:Show()
            local TF = TextFormat.Create()
            TF:AppendColor(COLOR_TOOLTIP_NAMES)
            TF:AppendText(names[1])

            for i = 2, #names do
                if (i - 1) % 5 ~= 0 then
                    TF:AppendText(" ")
                else
                    TF:AppendText("\n")
                end
                TF:AppendText(names[i])
            end

            TF:ApplyTo(cert_req_names)

            dims = cert_req_names:GetTextDims()
            cert_req_names:SetDims("top:_; left:_; width:"..tostring(dims.width + hpadding).."; height:"..tostring(dims.height))

            dims= cert_req:GetContentBounds()
            cert_req:SetDims("top:_; left:_; width:"..tostring(dims.width).."; height:"..tostring(dims.height))
        else
            cert_req_names:Hide()
        end
    else
        cert_req:Hide()
    end

    local bounds = tool_list:GetContentBounds()

    Tooltip.Show(TOOL_TIP,{width=bounds.width, height=bounds.height})
end

function InstancePlate_Refresh(IP)
    local enabled = true

    for _,reason in ipairs(IP.reasons) do
        reason.meetsReq = true
        reason.names = {}
    end

    local visible = IP.is_visible and (IP.hasCerts or IP.category_id ~= CAT_CAMPAIGN)

    local queue_id
    if not IP.ignore_difficulty then
        local difficulty = IP.difficulty[g_Difficulty]
        if difficulty and visible then
            queue_id = difficulty.id
            if difficulty.min_level > 0 then
                IP.LEVEL_MIN_GROUP:Show(true)
                IP.LEVEL_MIN:SetText(Component.LookupText("MIN_LEVEL_X", difficulty.min_level))
                IP.LEVEL_MIN_GROUP:SetDims("left:_; top:_; height:_; width:"..IP.LEVEL_MIN:GetTextDims().width+8)
            end
            local min_group_level, names = GetGroupMinLevel(difficulty.min_level)
            if min_group_level < difficulty.min_level then
                IP.reasons[REQ_MINLEVEL].meetsReq = false
                IP.reasons[REQ_MINLEVEL].names = names
                IP.LEVEL_MIN:SetTextColor("red")
                enabled = false
            else
                IP.LEVEL_MIN:SetTextColor("plate")
            end
            if d_QueueRestrictions[tostring(difficulty.zone_setting_id)] and d_QueueRestrictions[tostring(difficulty.zone_setting_id)][tostring(difficulty.id)] then
                enabled = false
                IP.reasons[REQ_CERT].meetsReq = false
                IP.reasons[REQ_CERT].names = d_QueueRestrictions[tostring(difficulty.zone_setting_id)][tostring(difficulty.id)].names
            end



        elseif not visible then
            IP.GROUP:Show(false)
            if IP.ROW then
                IP.ROW:Remove()
                IP.ROW = nil
            end
        end
    else
        queue_id = IP.queue_id

        if IP.min_level then
            IP.DETAIL:Show(true)
            IP.PLAYER_COUNT_GROUP:Show(false)
            IP.LEVEL_MIN_GROUP:Show(true)
            IP.LEVEL_MIN:SetText(Component.LookupText("MIN_LEVEL_X", IP.min_level))
            IP.LEVEL_MIN_GROUP:SetDims("left:_; top:_; height:_; width:"..IP.LEVEL_MIN:GetTextDims().width+8)
            if g_PlayerLevel < IP.min_level then
                IP.LEVEL_MIN:SetTextColor("red")
            else
                IP.LEVEL_MIN:SetTextColor("plate")
            end
        end
    end

    if g_QueueData then
        local alpha = 0
        for i=1, #g_QueueData.queues do
            if tonumber(g_QueueData.queues[i].id) == tonumber(queue_id) then
                alpha = 1
                break
            end
        end
        IP.QUEUED:ParamTo("alpha", alpha, 0.15, "smooth")
    end

    local certs = Game.GetCertIdsAssociatedWithZone(IP.zone_id)
    local hasUnlock = false

    for _, cert in ipairs(certs) do
        hasUnlock = hasUnlock or (Player.GetUnlockInfo("certificate", cert) ~= nil)
    end

    if hasUnlock then
        IP.DAILY_COMPLETE:Show()
    else
        IP.DAILY_COMPLETE:Hide()
    end


    if IP.category_id == CAT_TRAVEL then
        InstancePlate_Enable(IP)
    else
        if not visible or not enabled then
            InstancePlate_Disable(IP)
        elseif not IP.hasHardmode and g_Difficulty == DIFFICULTY_HARD then
            IP.reasons[REQ_NO_HARDCORE].meetsReq = false
            InstancePlate_Disable(IP)
        elseif not IP.difficulty[DIFFICULTY_CHALLENGE] and g_Difficulty == DIFFICULTY_CHALLENGE then
            IP.reasons[REQ_NO_CHALLENGE].meetsReq = false
            InstancePlate_Disable(IP)
        elseif not IP.difficulty[g_Difficulty] then
            InstancePlate_Disable(IP)
        else
            local inqueue = QUEUEBUTTON:IsInQueue()
            local isleader = IsPlayerGroupLeader()
            local isgroupvalid = IsGroupValidSize(unpack(IP.groupsize))
            local israidinvalid = IP.is_raid and not Platoon.IsInPlatoon()
            local atlevel = g_PlayerLevel >= IP.difficulty[g_Difficulty].min_level
            local isenabled = false

            if not atlevel then
                InstancePlate_Disable(IP)
            elseif inqueue then
                InstancePlate_Disable(IP)
                canSkip = true
            elseif isleader and not inqueue and ( israidvalid or isgroupvalid ) then
                InstancePlate_Enable(IP)
            end
        end
        InstancePlate_ValidSquad(IP)
    end
    if IP.selected then
        InstancePlate_Select(IP, true)
    end
end

function InstancePlate_Select(IP, state)
    if not IP then
        return nil
    end
    if state then
        g_SelectedIP = IP
    end
    if g_WorldTravel and state and isequal(unicode.lower(Game.GetZoneInfo(Game.GetZoneId()).zone_type), "openworld") then
        if not TRAVEL_BUTTON:IsEnabled() then
            TRAVEL_BUTTON:Enable()
        end
    end
    IP.selected = state
    InstancePlate_SelectDetail(IP, state)
    if IP.selected then
        if not g_WorldTravel then
            local difficulty = IP.difficulty[g_Difficulty]
            if difficulty then
                Instance_Add(difficulty.zone_setting_id, difficulty.id)
            end
        elseif  IP.min_level  and IP.min_level > g_PlayerLevel then
            HARDCORE_BACKGROUND:ParamTo("alpha", 1, 0.2, "smooth")
        else
            HARDCORE_BACKGROUND:ParamTo("alpha", 0, 0.2, "smooth")
        end
        IP.CHECK:ParamTo("alpha", 1, 0.15)
        IP.CHECK:ParamTo("exposure", 0.3, 0.15)
    else
        Instance_Remove(IP)
        IP.CHECK:ParamTo("alpha", 0, 0.15)
        IP.CHECK:ParamTo("exposure", 0, 0.15)
    end
end

function InstancePlate_SelectDetail(IP, state)
    if state then
        for i=1, #w_INSTANCEPLATES do
            if w_INSTANCEPLATES[i].selected_detail then
                InstancePlate_SelectDetail(w_INSTANCEPLATES[i], false)
                break
            end
        end
        IP.selected_detail = state
        IP.HIGHLIGHT:ParamTo("alpha", 1, 0.15)
        Preview_SetInstance(IP)
    elseif not state then
        IP.selected_detail = state
        IP.HIGHLIGHT:ParamTo("alpha", 0, 0.15)
    end
end

function InstancePlate_Enable(IP)
    if not IP.enabled then
        IP.enabled = true
        IP.TYPEBAR:SetParam("alpha", 1, 0.15)
        IP.ICON:SetParam("saturation", 1, 0.15)
        IP.NAME:SetTextColor("orange")
        IP.INFO:ParamTo("alpha", 1, 0.15)
        IP.LEVEL_MIN:SetTextColor("plate")
        IP.PLAYER_COUNT:SetTextColor("plate")
    end
end

function InstancePlate_Disable(IP)
    if IP.enabled then
        IP.enabled = false
        IP.TYPEBAR:SetParam("alpha", 0.2, 0.15)
        IP.ICON:SetParam("saturation", 0.1, 0.15)
        IP.NAME:SetTextColor("#DDDDDD")
        IP.INFO:ParamTo("alpha", 0.7, 0.15)
    end
end

function InstancePlate_ValidSquad(IP)
    local isvalidgroup = IsGroupValidSize(unpack(IP.groupsize))
    if (IP.is_raid and not Platoon.IsInPlatoon()) or (IP.is_raid and not Platoon.IsInPlatoon() and not isvalidgroup) or not isvalidgroup then
        IP.reasons[REQ_GROUP_SIZE].meetsReq = false
        IP.PLAYER_COUNT:SetTextColor("red")
        InstancePlate_Disable(IP)
    end
end

function InstancePlateCheck_OnMouseDown(IP)
    if not IP.selected then
        System.PlaySound(SOUND_CLICK)
        InstancePlate_Select(g_SelectedIP, false)
        InstancePlate_Select(IP, true)
    end
end

function Instance_Add(queue_id, difficulty)
    if queue_id then
        g_SelectedQueues = {}
        if difficulty == 0 then difficulty = nil end
        table.insert(g_SelectedQueues, {id=queue_id, difficulty=difficulty})
        QUEUEBUTTON:SetSelectedQueues(g_SelectedQueues)
    end
end

function Instance_Remove(IP)
    local found = false
    for k, difficulty in pairs(IP.difficulty) do
        for i = #g_SelectedQueues, 1, -1 do
            if difficulty.zone_setting_id == g_SelectedQueues[i].id then
                table.remove(g_SelectedQueues, i)
                found = true
            end
        end
    end
    if found then
        QUEUEBUTTON:SetSelectedQueues(g_SelectedQueues)
    end
end

function ClearAll_Instances()
    g_SelectedQueues = {}
    QUEUEBUTTON:SetSelectedQueues(g_SelectedQueues)
end

function InstancePlate_AutoSelect()
    local IP_visable
    local IP_mission
    for _, PLATE in ipairs(w_INSTANCEPLATES) do
        if PLATE.mi_id and g_ActiveMissions[PLATE.mi_id] then
            IP_mission = PLATE
            break
        elseif PLATE.is_visible and not IP_visable then
            IP_visable = PLATE
        end
    end
    local IP
    if IP_mission then
        IP = IP_mission
    else
        IP = IP_visable
    end
    if IP then
        InstancePlate_Select(IP, true)
        return IP
    end
end

function InstancePlates_HasHardmode()
    for k,IP in ipairs(w_INSTANCEPLATES) do
        if IP.difficulty[DIFFICULTY_HARD] then
            return true
        end
    end
end

function RefreshAll_InstancePlates(force_refresh)
    if g_Open or force_refresh then
        local hardmode_enabled = false
        local challenge_enabled = false
        for i=1, #w_INSTANCEPLATES do
            local IP = w_INSTANCEPLATES[i]
            IP:Refresh()
            if not hardmode_enabled and IP.hasHardmode and IP.is_visible then
                hardmode_enabled = true
            end
            if IP.difficulty[DIFFICULTY_CHALLENGE] then
                challenge_enabled = true
            end
        end
        local inqueue = QUEUEBUTTON:IsInQueue()
        local istransfer = QUEUEBUTTON:IsOpenWorld()
        RADIO_HARD:Show(hardmode_enabled)
        RADIO_CHALLENGE:Show(challenge_enabled)
        DIFF_RADIO_GROUP:Show(hardmode_enabled or challenge_enabled)
    end
end

function ClearAll_InstancePlates()
    for i=1, #w_INSTANCEPLATES do
        w_INSTANCEPLATES[i]:Destroy()
    end
    w_INSTANCEPLATES = {}
end

-- ------------------------------------------
-- PREVIEW FUNCTIONS
-- ------------------------------------------

function Preview_SetInstance(IP)
    if QUEUE_DETAIL:GetParam("alpha") ~= 1 then
        QUEUE_DETAIL:ParamTo("alpha", 1, 0.15)
    end
    THUMBNAIL_CHOICE:ClearChoices()
    for i=1, 3 do
        local texture, region
        if Component.CheckTextureExists(tostring(IP.zone_id)) then
            texture = tostring(IP.zone_id)
            region = "0"..tostring(i)
        else
            texture = "icons"
            region = "blank"
        end
        THUMBNAIL_CHOICE:AddChoice({texture=texture, region=region}, {texture=texture, region=region})
    end
    QUEUE_LABEL:SetText(IP.name)
    DETAILTEXT:SetText(IP.description)

    local certs = Game.GetCertIdsAssociatedWithZone(IP.zone_id)
    local hasUnlock = false

    for _, cert in ipairs(certs) do
        hasUnlock = hasUnlock or (Player.GetUnlockInfo("certificate", cert) ~= nil)
    end

    if not g_WorldTravel and hasUnlock then
        QUEUE_DAILY:Show(true)
        QUEUE_DAILY_FOCUS:Show(true)
        UpdateDailyMessage("DAILY_COMPLETED_TODAY", COLOR_DAILY_COMPLETE)
        QUEUE_DAILY_ICON:Show(true)
    elseif not g_WorldTravel and certs and #certs > 0 and g_Difficulty == DIFFICULTY_HARD then
        QUEUE_DAILY:Show(true)
        QUEUE_DAILY_FOCUS:Show(true)
        UpdateDailyMessage("DAILY_COMPLETION_AVAIL", COLOR_DAILY_AVAIL)
        QUEUE_DAILY_ICON:Show(false)
    else
        QUEUE_DAILY:Show(false)
        QUEUE_DAILY_FOCUS:Show(false)
    end

    w_DetailText:UpdateSize({height=DETAILTEXT:GetTextDims().height + 28})
end

function Preview_Clearall()
    QUEUE_DETAIL:ParamTo("alpha", 0, 0.15)
    THUMBNAIL_CHOICE:ClearChoices()
    DETAILSCREENSHOT:SetIcon(0)
    DETAILTEXT:SetText("")
    w_DetailText:UpdateSize({height=DETAILTEXT:GetTextDims().height})
end

-- ------------------------------------------
-- GENERAL FUNCTIONS
-- ------------------------------------------
function RefreshInstanceList(zonetype)
    ClearAll_InstancePlates()

    local sorted = {}
    for i=1, #g_ZoneListing[zonetype] do
        if Game.GetZoneInfo(g_ZoneListing[zonetype][i].zone_id) then
            table.insert(sorted, g_ZoneListing[zonetype][i])
            --Debug.Log(tostring(Game.GetZoneInfo(g_ZoneListing[zonetype][i].zone_id)))
            --Debug.Warn(tostring(g_ZoneListing[zonetype][i]))
        else
            Debug.Warn("Zone Id: "..tostring(g_ZoneListing[zonetype][i].zone_id).." has no zone info!")
        end
    end
    table.sort(sorted, function(a,b)
        if ( a.sort_order and b.sort_order ) and ( a.sort_order ~= b.sort_order ) then
            return a.sort_order < b.sort_order
        else
            return a.name < b.name
        end
    end)

    for i=1, #sorted do
        local IP = InstancePlate_Create()
        IP:SetInstance(sorted[i])
    end
    local IP = InstancePlate_AutoSelect()
    if not IP then
        Preview_Clearall()
    end
    RefreshAll_InstancePlates(true)

    local instance_count = 0
    for _, IP in ipairs(w_INSTANCEPLATES) do
        if IP.is_visible then
            instance_count = instance_count + 1
        end
    end

    if instance_count == 0 and IsPlayerGroupLeader() then
        LABEL_CHOOSE:Hide()
        LABEL_NO_INSTANCE:Show()
    else
        LABEL_NO_INSTANCE:Hide()
    end
end


function AddQueueRestrictions(queueIds, name)
    for queue_id, difficulties  in pairs(queueIds) do
        local queueRestriction = d_QueueRestrictions[tostring(queue_id)] or {}
        for _, difficultyId in ipairs(difficulties) do
            local restrictedDifficulty = queueRestriction[tostring(difficultyId)] or {names={}}
            table.insert(restrictedDifficulty.names, name)
            queueRestriction[tostring(difficultyId)] = restrictedDifficulty
        end
        d_QueueRestrictions[tostring(queue_id)] = queueRestriction
    end
end

-- ------------------------------------------
-- SQUAD FUNCTIONS
-- ------------------------------------------
function IsPlayerInGroup()
    return Squad.IsInSquad() or Platoon.IsInPlatoon()
end

function IsPlayerGroupLeader()
    local squad = Squad.GetRoster()
    if not squad then
        return true
    end
    return squad.is_mine
end

function GetGroupSize()
    if IsPlayerInGroup() then
        return #Squad.GetRoster().members
    end
    return 1
end

function GetGroupMinLevel(target)
    local names = {}
    if IsPlayerInGroup() then
        local roster = Squad.GetRoster()
        local min_level = 9999
        for _, member in ipairs(roster.members) do
            min_level = math.min(min_level, member.level)
            if member.level < target then
                table.insert(names, member.name)
            end
        end
        return min_level, names
    else
        if g_PlayerLevel < target then
            table.insert(names, g_PlayerName)
        end
        return g_PlayerLevel, names
    end
end

function IsGroupValidSize(min, max)
    if IsPlayerInGroup() then
        local size = GetGroupSize()
        return ( min <= size and max >= size )
    else
        return min <= 1
    end
end

-- New Zone Management
function RefreshZoneCache()
    WebCache.QuickUpdate(g_WebUrls["zone_list"])
end

function OnZoneListResponse(resp, err)
    for id in pairs(g_ZoneListing) do
        -- release prior data
        g_ZoneListing[id] = {}
    end
    g_ZoneList = resp

    -- Organize zones into tab categories
    if resp then
        for index, info in ipairs(resp) do
            if info.queueing_enabled then
                local category_id = c_GameTypesLookup[info.gametype] or CAT_UNKNOWN
                info.name = Component.LookupText(info.displayed_name)
                info.description = Component.LookupText(info.displayed_desc)
                info.category_id = category_id
                table.insert(g_ZoneListing[category_id], info)
            end
        end
        RefreshAvailableWorldAreas()
    elseif err then
        Debug.Warn(tostring(err))
    else
        Debug.Warn("No Server Response or Error")
    end
end

function RefreshAvailableWorldAreas()
    local locations = Game.GetGlobeViewLocations()

    for k, locInfo in ipairs(locations) do
        local formatted_loc = {
            id = 0,
            zone_id = tonumber(locInfo.zoneId),
            name = locInfo.name,
            description = locInfo.desc,
            sub_title = locInfo.climate,
            sovereignty = locInfo.sovereignty,

            category_id = CAT_TRAVEL,
            gametype = "travel",

            min_players_per_team = 1,
            max_players_per_team = 1,

            difficulty_levels = {},

            min_level = locInfo.level_min,

            -- TEMP
            images = {
                thumbnail = ReturnNonEmptyString(locInfo.thumbnail[1], "/assets/zones/placeholder-tbn.png"),
                screenshot = {
                    ReturnNonEmptyString(locInfo.screenshot[1], "/assets/zones/placeholder-ss.png"),
                    ReturnNonEmptyString(locInfo.screenshot[2], "/assets/zones/placeholder-ss.png"),
                    ReturnNonEmptyString(locInfo.screenshot[3], "/assets/zones/placeholder-ss.png"),
                }
            },
        }
        table.insert(g_ZoneListing[CAT_TRAVEL], formatted_loc)
    end
end

function UpdateDailyMessage(key, color)
    QUEUE_DAILY_LABEL:SetTextKey(key)
    QUEUE_DAILY_LABEL:SetTextColor(color)
    local bounds = QUEUE_DAILY_LABEL:GetTextDims()
    QUEUE_DAILY_LABEL:SetDims("top:_; left:_; height:_; width:"..tostring(bounds.width))

    bound = QUEUE_DAILY:GetContentBounds()
    QUEUE_DAILY:SetDims("top:_; center-x:_; height:_; width:"..tostring(bounds.width))
    QUEUE_DAILY_FOCUS:SetDims("top:_; center-x:_; height:_; width:"..tostring(bounds.width))
end

function ReturnNonEmptyString(str, fallback)
    if str and str ~= "" then
        return str
    else
        return fallback
    end
end

function InitializeRadioButtons()
    RADIO_NORMAL:SetCheck(true)
    RADIO_NORMAL:BindEvent("OnStateChanged", function(args)
        if args.checked then
            SetDifficultyMode(DIFFICULTY_NORMAL)
        end
    end)
    RADIO_HARD:BindEvent("OnStateChanged", function(args)
        if args.checked then
            SetDifficultyMode(DIFFICULTY_HARD)
        end
    end)
    RADIO_CHALLENGE:BindEvent("OnStateChanged", function(args)
        if args.checked then
            SetDifficultyMode(DIFFICULTY_CHALLENGE)
        end
    end)
    ResizeRadioButton(RADIO_NORMAL)
    ResizeRadioButton(RADIO_HARD)
    ResizeRadioButton(RADIO_CHALLENGE)
end

function ResizeRadioButton(RADIO)
    local c_RadioSize = 16
    local c_Padding = 5
    local textSize = RADIO:GetTextDims()
    local width = textSize.width + c_Padding + c_RadioSize
    RADIO:SetDims(unicode.format("top:0; left:0; height:%d; width:%d", c_RadioSize, width))
end

function SetDifficultyMode(difficulty)
    local showDifficultyBanner = difficulty == DIFFICULTY_HARD or difficulty == DIFFICULTY_CHALLENGE
    local alpha = tonumber(showDifficultyBanner)
    HARDCORE_BACKGROUND:ParamTo("alpha", alpha, 0.2, "smooth")
    HARDCORE_BACKGROUND:SetParam("hue",difficulty == DIFFICULTY_CHALLENGE and 0.125 or 1)

    -- Refresh list
    g_Difficulty = difficulty

    for k, IP in ipairs(w_INSTANCEPLATES) do
        IP:Refresh()
    end
    InstancePlate_Select(g_SelectedIP, true)
end


function DebugLogPlateValues(IP)
    Debug.Divider()
    Debug.Log(IP.name)

    for k, v in pairs(IP) do
        if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
            Debug.Log(k .. " = " .. tostring(v))
        end
    end
end
