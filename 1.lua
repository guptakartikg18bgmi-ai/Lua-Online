-- ============================================================================
-- ✦ GOKU FRAMEWORK CORE [SERVER-BASED PAYLOAD] ✦
-- ✦ FULLY COMPATIBLE WITH ONLINE LOADER ✦
-- ============================================================================
if not _G.GOKU_ONE_TIME_INIT_DONE then
    _G.GOKU_ONE_TIME_INIT_DONE = true

    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
        if not Msg then Msg = require("client.slua.logic.common.logic_common_msg_box") end
        local Web = require("client.slua.logic.url.logic_webview_sdk")
        local function onClick()
            if Web then Web:OpenURL("https://t.me/GOKUCONFIG") end
        end
        if Msg and Msg.Show then
            Msg.Show(4, "✓ GOKU CLOUD FRAMEWORK",
                "\n ◉ Status      : SERVER INJECTED\n" ..
                " ◉ Protection  : HEURISTIC + EXPLICIT\n" ..
                " ◉ Bypass      : Higgs · HawkEye · TSS · TLog\n" ..
                " ◉ Shield      : FULL BYPASS ENABLED\n\n" ..
                " Developer     : @GOKUCONFIG",
                onClick)
        end
    end)

    -- ==================== SHARED HELPERS ====================
    local noop = function() return true end
    local retFalse = function() return false end
    local retZero = function() return 0 end
    local retEmpty = function() return {} end
    local retTrue = function() return true end
    local retDummyHash = function() return "A3F8B9C2E1D40F5" end

    local function KillTable(tbl, keys)
        if type(tbl) ~= "table" then return end
        for _, key in ipairs(keys) do
            pcall(function()
                if type(tbl[key]) == "function" then
                    tbl[key] = function() return true, {} end
                else
                    tbl[key] = nil
                end
            end)
        end
    end

    -- ==================== MODULE PATCHES (STRINGS SANITIZED) ====================
    local modulePatches = {
        ["GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"] = {
            methods = {
                ControlMHActive = noop, Tick = noop, OnTick = noop, ReceiveTick = noop,
                MHActiveLogic = noop, TriggerAvatarCheck = noop, StartAvatarCheck = noop,
                ReportItemID = noop, OnReportItemID = noop, ReceiveAnyDamage = noop,
                OnWeaponHitRecord = noop, ShowSecurityAlert = noop,
                StaticShowSecurityAlertInDev = noop, SendHisarData = noop, OnLogin = noop,
                ValidateSecurityData = noop, CheckMemoryIntegrity = retTrue,
                ReportAbnormalMemory = noop, OnMemoryScanComplete = noop,
                SendDetectionResult = noop, TriggerClientScan = noop,
                SendAntiDataFlow = noop, SendHitFireBtnFlow = noop,
                SkipAlertServer = noop, CheckWeaponIntegrity = retTrue,
                CheckAvatarIntegrity = retTrue, CheckBulletIntegrity = retTrue,
                OnGameModeType = noop,
            },
            fields = { bMHActive = false, mHActive = 0 },
            retvals = { GetNetAvatarItemIDs = retEmpty, GetCurWeaponSkinID = retZero, GetDetectionResult = retEmpty },
            custom = function(m)
                if m.__inner_impl then
                    local i = m.__inner_impl
                    i.SendAntiDataFlow = noop
                    i.SendHitFireBtnFlow = noop
                    i.OnBattleResult = noop
                    i.SendHisarData = noop
                end
                if m.BlackList then
                    for k in pairs(m.BlackList) do m.BlackList[k] = nil end
                end
                if m.SkipAlertServer then pcall(m.SkipAlertServer, m) end
            end,
        },
        ["GameLua.Mod.BaseMod.Common.Security.SafetyDetectionSubsystem"] = {
            methods = { DetectAbnormal = noop, ReportAbnormal = noop, OnDetectionResult = noop, TriggerSafetyScan = noop },
            retvals = { GetScanResults = retEmpty, IsAnomalyDetected = retFalse },
        },
        ["GameLua.Mod.BaseMod.Client.Security.ClientAntiCheatSubsystem"] = {
            methods = { StartScan = noop, SyncData = noop, ReportSuspicious = noop },
            retvals = { GetCheatFlags = retZero, IsEnvironmentSafe = retTrue },
        },
        _G_AvatarCheckCallback = {
            table = "_G.AvatarCheckCallback",
            methods = {
                StartAvatarCheck = noop,
                OnReportItemID = noop,
                PostPlayerControllerLoginInit = function(pc)
                    pcall(function()
                        if pc and pc.HiggsBosonComponent then
                            pc.HiggsBosonComponent:ControlMHActive(0)
                            pc.HiggsBosonComponent.bMHActive = false
                        end
                    end)
                end
            }
        },
        ["GameLua.Mod.BaseMod.Common.Security.PakIntegrityChecker"] = {
            methods = { ShowPakMismatchAlert = noop },
            retvals = { Verify = retFalse, CheckPakFile = retZero, GetPakStatus = retZero }
        },
        ["client.slua.logic.pak.logic_pak_verify"] = {
            retvals = { Verify = retFalse, CheckPakFile = retZero, GetPakStatus = retZero }
        },
        _G_STExtra = {
            table = "_G.STExtraBlueprintFunctionLibrary",
            retvals = { CheckFileIntegrity = retFalse, VerifySignature = retFalse, CheckGameLuaIntegrity = retFalse }
        },
        _G_TssSDK = {
            table = "_G.TssSDK",
            methods = { ReportData = noop, SendToServer = noop, SetUserInfo = noop, Init = noop, Start = noop, Verify = retTrue, CheckIntegrity = retTrue, Check = retTrue },
            retvals = { GetSignature = retDummyHash }
        },
        _G_TssSDKHelper = { table = "_G.TssSDKHelper", methods = { ReportData = noop } },
        _G_Bugly = { table = "_G.Bugly", methods = { ReportException = noop, SetCustomData = noop } },
        _G_Beacon = { table = "_G.Beacon", methods = { Report = noop } },
        _G_CrashSight = { table = "_G.CrashSight", methods = { ReportException = noop, SetCustomData = noop, Log = noop } },
        ["GameLua.Mod.BaseMod.Common.Security.SecurityNotifyPCFeature"] = {
            methods = {
                ClientRPC_SyncBanID = noop, ClientRPC_StrongTips = noop, ClientRPC_NormalTips = noop,
                Notify = noop, ClientRPC_NotifyBan = noop, ClientRPC_NotifyPunish = noop,
                ClientRPC_NotifyIllegalProgram = noop
            },
            custom = function(m)
                if m.__inner_impl then m.__inner_impl.SyncBanInfo = noop end
            end,
        },
        ["client.slua.logic.ban.ClientBanLogic"] = {
            methods = {
                OnSyncBanInfo = noop, OnVoiceBanNotify = noop, OnRealTimeVoiceBanNotify = noop,
                OnVoiceBanSuccess = noop, OnSyncMicSuspicious = noop, OnSyncMicPreFilter = noop,
                OnNotifyWarningTips = noop, ReqBanInfo = noop
            },
        },
        ["client.slua.logic.ban.BanTipsLogic"] = {
            methods = { ShowBanTips = noop, ShowPunishTips = noop, ShowWarningTips = noop, OnReceiveBanNotice = noop }
        },
        _G_ban_util = { table = "_G.ban_util", retvals = { CheckBanStatus = retFalse, GetBanTime = retZero, IsBanForever = retFalse } },
        _G_logic_tt_ban = {
            table = "_G.logic_tt_ban",
            methods = { CheckIfCanCreateRole = noop },
            retvals = { JumpAppealURL = retFalse, GetCarrierInfo = function() return '[{"mcc":"000"}]' end }
        },
        ["GameLua.Mod.BaseMod.Client.Security.ClientHawkEyePatrolSubsystem"] = {
            methods = {
                _OnHawkSync = noop, _OnHawkReportSuccess = noop, _StartExitGameTimer = noop,
                _OnRecvInspectorBroadcastCount = noop, SendReportTLog = noop, ReportCheat = noop,
                _OnHawkFlag = noop, ReportPlayerFlag = noop, RequestFlagPlayer = noop,
                SendFlagReport = noop, RequestImprison = noop, IsDuringHawkEyePatrol = retFalse,
                HasReported = retTrue,
            },
            retvals = { CanInspectorBroadcast = retFalse },
            custom = function(mod)
                if mod.__inner_impl then
                    local i = mod.__inner_impl
                    i._OnHawkSync = noop
                    i._OnHawkReportSuccess = noop
                    i.TryShowReportedTips = noop
                end
            end,
        },
        ["GameLua.Mod.BaseMod.Client.Security.HawkEyeSpectate.ClientHawkEyePatrolSubsystem"] = {
            custom = function(mod)
                if mod.__inner_impl then
                    local i = mod.__inner_impl
                    i._OnHawkSync = noop
                    i._OnHawkReportSuccess = noop
                    i.TryShowReportedTips = noop
                end
            end,
        },
        ["GameLua.Mod.BaseMod.Common.Subsystem.DataLayerSubsystem"] = {
            custom = function(m)
                if m.OnSpectatorReplayChanged then
                    local o = m.OnSpectatorReplayChanged
                    m.OnSpectatorReplayChanged = function(...)
                        _G.IsBeingWatched = true
                        return o(...)
                    end
                end
            end,
        },
        _G_ServerDataMgr = {
            table = "_G.ServerDataMgr",
            custom = function(m)
                if m.DeletablePlayerResultKey then
                    for _, k in ipairs({
                        "SuspiciousHitCount", "EspTotalSimTraceCnt", "EspTotalImeFocusCnt",
                        "ClientGravityAnomalyCount", "FireCount", "SpeedCheatCount", "JumpCount",
                        "VehicleSpeedHackCount", "HeadshotCount", "KillCount", "Accuracy",
                        "FlagCount", "TotalFlags", "IsFlagged", "FlaggedByHawkEye",
                        "FlaggedByInspection", "FlagTimestamp", "FlagLevel", "FlagSeverity",
                    }) do m.DeletablePlayerResultKey[k] = true end
                end
                if m.FlagCount then m.FlagCount = 0 end
                if m.TotalFlags then m.TotalFlags = 0 end
                if m.IsFlagged then m.IsFlagged = false end
                if m.FlaggedByHawkEye then m.FlaggedByHawkEye = false end
                if m.FlaggedByInspection then m.FlaggedByInspection = false end
                if m.FlagTimestamp then m.FlagTimestamp = 0 end
                if m.FlagLevel then m.FlagLevel = 0 end
                if m.FlagSeverity then m.FlagSeverity = 0 end
            end
        },
        ["client.slua.logic.report.ToolReportUtil"] = {
            retvals = { IsReleaseVersion = retFalse, IsWhite = retFalse, GetReportSwitch = retFalse }
        },
        _G_ClientToolsReport = { table = "_G.ClientToolsReport", methods = { SendReport = noop, SendException = noop } },
        _G_ReportPlatformCrashKit = { table = "_G.ReportPlatformCrashKit", methods = { Send = noop, ForceSend = noop } },
        ["GameLua.Mod.BaseMod.Client.Security.ClientGlueHiaSystem"] = {
            methods = {
                CheckHitIntegrity = noop, InitSession = noop, OnBattleEnd = noop,
                LuaFunc1 = retTrue, LuaFunc4 = retFalse, LuaFunc5 = retFalse,
                LuaFunc6 = retFalse, LuaFunc7 = retFalse, LuaFunc8 = retFalse, LuaFunc9 = noop
            }
        },
        ["GameLua.Mod.Escape.Gameplay.Subsystem.BehaviorScoreSubsystem"] = {
            methods = { OnHandleBehaviorScore = noop, AIPerceptionScore = noop, ReportBehavior = noop },
            retvals = { CalcFinalScore = retZero }
        },
        _G_AntiAddictionHandler = { table = "_G.AntiaddctionHandler", methods = { send_anti_addiction_req = noop, send_anti_addiction_notify = noop, on_check_nonage_anti_work = noop } },
        _G_AccessRestrictionHandler = { table = "_G.AccessRestrictionHandler", methods = { send_access_restriction_req = noop, send_access_restriction_notify = noop, on_player_cheat_state_notify = noop } },
        _G_GodzillaBanHandler = { table = "_G.GodzillaBanHandler", methods = { send_godzilla_ban_req = noop, send_godzilla_unban_req = noop } },
        _G_logic_deleteaccount = { table = "_G.logic_deleteaccount", retvals = { ForceDeleteAccount = retFalse }, methods = { OnReceiveDeleteNotify = noop } },
        _G_compliance_util = { table = "_G.compliance_util", methods = { CheckCompliance = noop } },
        ["GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem"] = {
            methods = {
                OnInit = noop, _OnPlayerKilledOtherPlayer = noop, _RecordFatalDamager = noop,
                _OnDeathReplayDataWhenFatalDamaged = noop, _RecordMurdererFromDeathReplayData = noop,
                _RecordTeammatePlayerInfo = noop, _OnBattleResult = noop,
                _OnShowQuickReportMutualExclusiveUI = noop,
                GetFatalDamagerMap = retEmpty, GetCachedTeammateName2InfoMap = retEmpty,
                GetTeammateName2InfoMapDuringBattle = retEmpty,
                GetCurrentNotInTeamHistoricalTeammateMap = retEmpty,
                GetInTeamIndexFromHistoricalTeammateInfo = function() return -1 end,
                ReportSuspiciousPlayer = noop, SubmitReport = noop, ProcessReport = noop,
            },
            custom = function(m)
                if m.__inner_impl then
                    m.__inner_impl._OnSyncFatalDamage = noop
                    m.__inner_impl._OnPlayerKilledOtherPlayer = noop
                    m.__inner_impl._SyncBattleResult = noop
                end
            end,
        },
        ["GameLua.Mod.BaseMod.Common.Security.DSReportPlayerSubsystem"] = {
            methods = {
                OnInit = noop, _OnNearDeathOrRescued = noop, _OnCharacterDied = noop,
                _OnTeammateDamage = noop, _OnPlayerSettlementStart = noop,
                _AddKnockDownerToBattleResult = noop, _AddKillerToBattleResult = noop,
                _AddTeammateMurderToBattleResult = noop, _AddFatalDamagerMapToBattleResult = noop,
                _AddMLKillerUIDToBattleResult = noop, _SaveHistoricalTeammateInfo = noop,
                _RecordFatalDamager = noop, _RecordTeammateMurderer = noop,
                _AddEnemyMapToBattleResult = noop, _AddTeammateMapToBattleResult = noop,
                _SubmitAbnormalData = noop,
            },
        },
        ["GameLua.Mod.BaseMod.Common.Security.ReportPlayerUtils"] = {
            retvals = { GetBotType = retZero, IsCharacterDeliverAI = retFalse },
            methods = { RecordFatalDamager = noop, IsUsingHistoricalTeammateInfo = retFalse },
        },
        ["GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils"] = {
            methods = { ExtractPlayerBasicInfo = retEmpty, LogIf = retFalse },
            custom = function(m)
                if m.EStrategyTypeInReplay then
                    m.EStrategyTypeInReplay.EspTotalSimTraceCnt = 0
                    m.EStrategyTypeInReplay.EspTotalImeFocusCnt = 0
                    m.EStrategyTypeInReplay.ClientGravityAnomalyCount = 0
                    m.EStrategyTypeInReplay.FlyingErrorCnt = 0
                end
            end,
        },
        ["GameLua.Mod.BaseMod.Client.Security.InspectionSystemReportClientLogicSubsystem"] = {
            methods = {
                AskForInspector = noop, ReportEnemy = noop, KickOutOneTeam = noop,
                OnReceiveInspectCmd = noop, ClientReportData = noop,
                SendReportToInspector = noop, SendKickOutOneTeam = noop,
                ClientNotifyInspectorImplementation = noop, RecvNotifyInspector = noop,
            },
        },
        ["GameLua.Mod.BaseMod.DS.Security.InspectionSystemReportDSLogicSubsystem"] = {
            methods = {
                ServerKickOutOneTeamByPlayerImplementation = noop, AddReportedCount = noop,
                AddInspectionRecord = noop, BanPlayerByInspection = noop,
                BroadCastToAllInspector = noop, ServerReportToInspectorImplementation = noop,
                InitPlayerInspectionInfo = noop,
            },
        },
        ["client.slua.logic.CustomerService.LogicSafeStation"] = {
            methods = { UploadVideoEvidence = noop, ReportPlayerBehavior = noop },
        },
        ["client.slua.logic.CustomerService.LogicCustomerService"] = {
            methods = { SendComplaint = noop, SendFeedback = noop },
        },
        _G_logic_chat_voice_report = { table = "_G.logic_chat_voice_report", methods = { ReportVoiceData = noop, ReportVoiceText = noop } },
        _G_logic_chat_voice_doctor = { table = "_G.logic_chat_voice_doctor", methods = { UploadVoiceLog = noop, UploadVoiceException = noop } },
        _G_logic_home_audit_state = { table = "_G.logic_home_audit_state", methods = { SendAuditState = noop, ReportAuditResult = noop } },
        _G_logic_home_report = { table = "_G.logic_home_report", methods = { ReportHomeData = noop, ReportHomeVisitor = noop } },
        ["client.logic.data.profile_report_cfg"] = { methods = { SendReport = noop } },
        _G_EmulatorHandler = { table = "_G.EmulatorHandler", methods = { send_emulator_info = noop } },
        _G_emulator_scanner = { table = "_G.emulator_scanner", methods = { StartScan = noop, ReportScanResult = noop }, retvals = { GetScanResult = retFalse } },
        _G_LoginVerifyHandler = { table = "_G.LoginVerifyHandler", methods = { send_login_verify_req = noop, send_device_verify_req = noop } },
        _G_logic_ds_monitor = { table = "_G.logic_ds_monitor", methods = { OnRecordMsg = noop, OnReportMsg = noop } },
        ["GameLua.Mod.BaseMod.DS.Security.AFKReportorSubsystem"] = {
            methods = {
                HandleEnterFighting = noop, InitializePlayerInputInfo = noop,
                AddOneAFKInfo = noop, SetPlayerAFKState = noop, ResetPlayerInputInfo = noop,
                PlayerHaveAction = noop, ReportAFK = noop,
            },
        },
        _G_TDataMaster = { table = "_G.TDataMaster", methods = { Report = noop, ReportDeviceInfo = noop, SendHardwareHash = noop, CollectTelemetry = noop, SendData = noop, Sync = noop, Flush = noop } },
        _G_DeviceInfo = { table = "_G.DeviceInfo", methods = { GetDeviceID = retDummyHash, GetIMEI = retDummyHash, CollectSysInfo = noop } },
        ["GameLua.Mod.BaseMod.Client.Security.ClientFlagSubsystem"] = {
            methods = { EvaluateFlags = noop, GetFlagLevel = retZero, GetFlagBanDuration = retZero, IsFlagged = retFalse, ReportFlag = noop, SyncFlagStatus = noop, IncreaseFlagCount = noop, ResetFlags = noop },
            retvals = { IsFlagged = retFalse },
            fields = { FlagCount = 0, FlagLevel = 0, FlagSeverity = 0 },
        },
        ["client.slua.logic.ban.logic_flag_ban"] = { methods = { GetFlagBanEndTime = function() return 0 end, IsFlagBanned = retFalse, GetFlagBanDuration = retZero, CheckFlagBan = retFalse } },
        ["GameLua.Mod.BaseMod.Client.Security.DeviceFingerprint"] = { methods = { Collect = noop, Sync = noop, GetHash = retDummyHash } },
        ["GameLua.Mod.BaseMod.DS.Security.DSDeviceCheck"] = { methods = { VerifyClientDevice = retTrue, ReportMismatch = noop } },
        ["GameLua.Mod.BaseMod.Common.Security.IntegrityCheck"] = { methods = { Run = noop, Verify = retTrue } },
        ["GameLua.Mod.BaseMod.Common.Security.APKIntegrity"] = { methods = { CheckSignature = retTrue, CheckInstallSource = retTrue } },
        ["GameLua.Mod.BaseMod.Client.Security.SpectatorAndReplaySubsystem"] = { methods = { SendReport = noop } },
        ["GameLua.Mod.BaseMod.Client.Security.HawkEyeSpectate.HawkEyeDistanceUI"] = { methods = { _RefreshUI = noop, _IsShouldShow = retFalse } },
        ["GameLua.Mod.BaseMod.Client.Security.HawkEyeSpectate.HawkEyeNextPatrolWindow"] = { methods = { OnShow = noop } },
        ["GameLua.Mod.BaseMod.Client.Security.HawkEyeSpectate.HawkEyeReportWindow"] = { methods = { _OnClickSubmit = noop, _RefreshWindow = noop, RegistEvents = noop } },
        ["GameLua.Mod.BaseMod.Client.Ban.ClientBanLogic"] = { methods = { OnVoiceBanNotify = noop, OnRealTimeVoiceBanNotify = noop, OnSyncBanInfo = noop, OnNotifyWarningTips = noop } },
        ["client.slua.logic.ban.logic_ban"] = { methods = { GetBanEndTime = function() return 0 end, IsInBanTime = retFalse, CheckBanStatus = retFalse, GetBanReason = retEmpty, GetBanTime = retZero } },
        ["client.slua.logic.login.logic_login_ban"] = { methods = { CheckCanLogin = retTrue, GetBanInfo = function() return { end_time = 0 } end, IsBanned = retFalse, IsSecurityBan = retFalse } },
        _G_ClientTlogHandler = { table = "_G.ClientTlogHandler", methods = { send_report_lobby_common_tlog = noop } },
        _G_BasicDataTLogReport = { table = "_G.BasicDataTLogReport", methods = { OnSendBatchReqMsg = noop, OnImmediateReqMsg = noop, OnMergeReqMsg = noop, send_report_event_duration_log = noop, SendTlog = noop, ReportEvent = noop }, retvals = { _GetParamData = retEmpty } },
        _G_BasicDataClientReport = { table = "_G.BasicDataClientReport", methods = { ReportImmediate = noop, ReportDelay = noop, OnSendBatchReqMsg = noop, OnImmediateReqMsg = noop, OnMergeReqMsg = noop }, retvals = { _IsCanReport = retFalse } },
        ["GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem"] = { methods = { ReportFightData = noop, ReportPlayerWeapon = noop }, retvals = { GetSimpleFightData = retEmpty } },
        ["GameLua.Mod.BaseMod.DS.Security.DSSecurityTLogSubsystem"] = { methods = { _OnReportServerJumpFlow = noop, _OnReportTeleportFlow = noop, _OnReportSpeedHackFlow = noop } },
        _G_ClientErrorReportHandler = { table = "_G.ClientErrorReportHandler", methods = { send_client_error_report = noop, send_client_crash_report = noop, send_client_tools_batch_report_req = noop } },
        _G_BattleReportHandler = { table = "_G.BattleReportHandler", methods = { send_battle_report = noop, send_battle_result = noop, send_vod_game_report_req = noop, send_batch_get_vod_info_req = noop, send_get_game_report_req = noop, send_batch_get_game_report_req = noop, send_get_game_report_by_uid_req = noop } },
        ["GameLua.Mod.BaseMod.Client.Security.ClientDataStatistcsSubsystem"] = { methods = { StartToCheck = noop, OnReceiveRTT = noop, OnReceiveJitter = noop, ReportAbnormal = noop, ResetData = noop } },
        ["GameLua.Dev.Subsystem.ShootVerifySubSystemClient"] = { methods = { OnShootVerifyFailed = noop, SendVerifyData = noop } },
    }

    local function applyPatchToTable(target, cfg)
        if type(target) ~= "table" or type(cfg) ~= "table" then return end
        pcall(function()
            if cfg.custom then
                cfg.custom(target)
            else
                if cfg.methods then
                    for k, v in pairs(cfg.methods) do
                        if type(target[k]) == "function" then target[k] = v end
                    end
                end
                if cfg.retvals then
                    for k, v in pairs(cfg.retvals) do
                        if type(target[k]) == "function" then target[k] = v end
                    end
                end
                if cfg.fields then
                    for k, v in pairs(cfg.fields) do
                        if target[k] ~= nil then target[k] = v end
                    end
                end
            end
        end)
    end

    local function applyGlobalTablePatches()
        for _, cfg in pairs(modulePatches) do
            if cfg.table and type(cfg.table) == "string" then
                local path = cfg.table
                local target = nil
                local parts = {}
                for part in path:gmatch("[^%.]+") do table.insert(parts, part) end
                if #parts > 0 then
                    if parts[1] == "_G" then
                        target = _G
                        table.remove(parts, 1)
                    else
                        local ok, mod = pcall(require, parts[1])
                        if ok and mod then
                            target = mod
                            table.remove(parts, 1)
                        else
                            target = _G[parts[1]] or nil
                            table.remove(parts, 1)
                        end
                    end
                    for _, p in ipairs(parts) do
                        if type(target) ~= "table" then target = nil; break end
                        target = target[p]
                    end
                end
                if target then applyPatchToTable(target, cfg) end
            end
        end
    end

    -- ==================== NETWORK & IO BLACKLISTS ====================
    local globalSuppress = {
        functions = {
            "ReportTLogEvent", "SendTlog", "ReportHitFlow", "ReportAvatarException",
            "SendComplaintReq", "SubmitReport", "ReportSuspiciousPlayer", "OnSyncBanInfo",
            "OnVoiceBanNotify", "SendSecTLog", "MarkSuspiciousPlayer",
            "ReportPlayerBehaviorData", "CheckCompliance", "ReportIllegalProgram",
            "UploadVoiceLog", "ReportClientAbnormal", "TriggerMemoryScan",
            "SubmitDetectionReport", "is_root", "is_rooted", "detect_emulator",
            "check_system", "SendTssSdkAntiDataToLobby", "SendActivityTLog",
            "SendDSErrorLogToLobby", "SendDSHawkEyePatrolLogToLobby",
            "_OnPlayerKilledOtherPlayer", "_RecordFatalDamager", "_OnBattleResult",
            "_OnCharacterDied", "SendClientMemUsage", "SendClientFPS",
            "OnClientCrashReport", "ReportMatchRoomData", "ShowSecurityAlert",
            "StaticShowSecurityAlertInDev", "CheckGameVersion", "IsNeedUpdate",
            "ForceUpdate", "ShowUpdateDialog", "ReportFlag", "SendFlagInfo",
            "AddFlagCount", "IsAccountFlagged", "GetFlagStatus",
            "SendPlayerStatistics", "ReportPlayerStats", "SendSuspiciousData"
        },
        tables = { "GlobalPlayerCoronaData", "GlobalPlayerCheatTimes" },
    }

    local BLACKLIST_HOSTS = {
        "tss.tencent", "syzsdk", "reportlog", "tdos", "logupload", "feedback.wh",
        "crash2", "privacy.qq", "privacy.tencent", "oth.eve", "mdt.qq",
        "act.tencentyun", "analytics", "report.qq", "anticheatexpert", "crashsight",
        "wetest", "log.tav", "sngd", "tracer", "intlsdk", "igamecj",
        "igame.gcloudcs", "bugly", "beacon", "helpshift", "tdm", "apm",
        "safeguard", "weiyun", "qzone", "tencent-cloud", "myapp", "idqqimg",
        "gtimg", "qqmail", "tcdn", "cloudctrl", "sdkostrace", "103.134.189.146",
        "mbgame", "csoversea", "down.anticheatexpert.com",
        "asia.csoversea.mbgame.anticheatexpert.com", "log.tav.qq", "syzsdk.qq",
        "logiservice.qcloud", "opensdk.tencent", "exp.helpshift",
        "loginsdkapi.zingplay", "flag", "reportflag"
    }

    local BLACKLIST_PORTS = {
        "10334", "11045", "12221", "13331", "8011", "8015", "9001", "20000",
        "20001", "20002", "20003", "20004", "20005", "19700", "1670", "19900",
        "14545", "10213", "8700", "25177", "10685", "10336", "10262", "27000",
        "27040", "27015", "27030", "10706", "10095", "12401", "11008", "10309",
        "11075", "10157", "24798", "10709", "6667", "10087", "31113", "20371",
        "10120", "10664", "13728", "10769", "10761", "5061", "5062", "18081",
        "15692", "9030", "8080", "8086", "8088"
    }

    local FILE_KEYWORDS = {
        "tlog", "crash", "bugly", "report", "beacon", "wetest", "analytics",
        "telemetry", "trace", "dump", "exception", "feedback", "aps_log",
        "mtp_detect", "network_loss", "client_error", "ue4crash", "tdm", "gcloud"
    }

    local function parseHostPort(url)
        if type(url) ~= "string" then return nil, nil end
        local hostport = url:match("^%w+://([^/]+)") or url
        hostport = hostport:lower()
        local host = hostport:match("^[^:]+") or hostport
        local port = hostport:match(":(%d+)")
        if host then host = host:match("([^/]+)") or host end
        return host, port
    end

    local function isBlacklisted(str)
        if type(str) ~= "string" then return false end
        local low = str:lower()
        local host, port = parseHostPort(low)
        if host then
            for _, kw in ipairs(BLACKLIST_HOSTS) do
                if host:find(kw, 1, true) then return true end
            end
        end
        if port then
            for _, p in ipairs(BLACKLIST_PORTS) do
                if port == p then return true end
            end
        end
        return false
    end

    if not _G.GOKU_REQUIRE_ORIGINAL then
        _G.GOKU_REQUIRE_ORIGINAL = require
        require = function(name)
            local ok, mod = pcall(_G.GOKU_REQUIRE_ORIGINAL, name)
            if not ok then
                pcall(function() print(("GOKU: require('%s') failed: %s"):format(tostring(name), tostring(mod))) end)
                return nil
            end

            if modulePatches[name] then
                local cfg = modulePatches[name]
                pcall(function() applyPatchToTable(mod, cfg) end)
            end
            return mod
        end
    end

    pcall(applyGlobalTablePatches)

    local function applyNetworkShield()
        local GC = _G.GameplayCallbacks or _G.GC
        if not GC then return end
        local orig = GC.OnDSPlayerStateChanged
        GC.OnDSPlayerStateChanged = function(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
            local s = tostring(InPlayerState or ""):lower()
            local r = tostring(ParamReason or ""):lower()
            for _, k in ipairs({
                "cheatdetected", "connectionlost", "ban", "kick", "antihack",
                "speedhack", "aimbot", "wallhack", "modifiedfiles", "brutal",
                "security", "flag", "connectionexception", "netdrivererror"
            }) do
                if s:find(k) or r:find(k) then return end
            end
            if orig then pcall(orig, UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason) end
        end
    end

    local function applyFullCRCFaker()
        pcall(function()
            if Client then
                if Client.VerifyPakFile then Client.VerifyPakFile = retTrue end
                if Client.CheckFileCRC then Client.CheckFileCRC = retZero end
                if Client.GetFileHash then Client.GetFileHash = retDummyHash end
                if Client.VerifySignature then Client.VerifySignature = retTrue end
            end
        end)
    end

    local function InitFileIOCrashBlock()
        if not _G.GOKU_IO_HOOKED then
            _G.GOKU_IO_HOOKED = true
            local orig_io_open = io.open
            io.open = function(path, mode)
                if type(path) == "string" then
                    local lp = path:lower()
                    for _, kw in ipairs(FILE_KEYWORDS) do
                        if lp:find(kw, 1, true) then
                            if mode and (mode == "w" or mode == "a" or mode == "w+" or mode == "a+") then
                                return nil, "BlockedByGOKU"
                            end
                        end
                    end
                    if lp:find("tdm", 1, true) or lp:find("gcloud", 1, true) or lp:find("beacon", 1, true) then
                        if mode and (mode == "w" or mode == "a" or mode == "w+") then return nil, "BlockedByGOKU" end
                    end
                end
                return orig_io_open(path, mode)
            end
            if _G.UnrealEngine and _G.UnrealEngine.CrashContext then
                _G.UnrealEngine.CrashContext = {
                    SetCrashContext = noop,
                    ReportCrash = noop,
                    AddCrashData = noop
                }
            end
        end
    end

    local function InitNetworkBlacklist()
        pcall(function()
            if _G.HttpRequest and not _G.GOKU_HTTP_HOOKED then
                _G.GOKU_HTTP_HOOKED = true
                local orig = _G.HttpRequest
                _G.HttpRequest = function(url, ...)
                    if isBlacklisted(url) then return nil end
                    return orig(url, ...)
                end
            end
            if _G.FHttpModule and _G.FHttpModule.CreateRequest and not _G.GOKU_FHTTP_HOOKED then
                _G.GOKU_FHTTP_HOOKED = true
                local orig = _G.FHttpModule.CreateRequest
                _G.FHttpModule.CreateRequest = function(...)
                    local url = select(1, ...)
                    if isBlacklisted(url) then return nil end
                    return orig(...)
                end
            end
        end)
    end

    pcall(function()
        applyNetworkShield()
        for _, f in ipairs(globalSuppress.functions) do
            if type(_G[f]) == "function" then _G[f] = retFalse end
        end
        for _, t in ipairs(globalSuppress.tables) do
            if type(_G[t]) == "table" then
                local mt = getmetatable(_G[t]) or {}
                mt.__newindex = function() end
                setmetatable(_G[t], mt)
            end
        end
        applyFullCRCFaker()
        InitFileIOCrashBlock()
        InitNetworkBlacklist()
    end)
end

-- ==================== CORE MOD LOGIC ====================
local noop = function() return true end
local retFalse = function() return false end
local retZero = function() return 0 end
local retEmpty = function() return {} end
local retTrue = function() return true end
local retDummyHash = function() return "A3F8B9C2E1D40F5" end

local function isValid(obj)
    if type(slua) == "table" and type(slua.isValid) == "function" then
        local ok, res = pcall(slua.isValid, obj)
        return ok and (res == true)
    end
    return obj ~= nil
end

local function safe_require(path)
    local ok, mod = pcall(require, path)
    return ok and mod or nil
end

_G.BypassState = _G.BypassState or {
    DeadEyeDisabled = false, HawkEyeDisabled = false, VoklaiDisabled = false,
    HiggsBosonDisabled = false, HashVerifyDisabled = false, IPMappingDisabled = false,
    MemoryPatchDisabled = false, EduEyeDisabled = false, FullBypassActive = false
}

local function KillTable(tbl, keys)
    if type(tbl) ~= "table" then return end
    for _, key in ipairs(keys) do
        pcall(function()
            if type(tbl[key]) == "function" then tbl[key] = function() return true, {} end
            else tbl[key] = nil end
        end)
    end
end

local function ApplyGokuBypasses()
    if _G.BypassState.FullBypassActive then return end
    pcall(function()
        if _G.GameplayCallbacks then
            KillTable(_G.GameplayCallbacks, {
                "ReportAimFlow", "ReportHitFlow", "ReportAttackFlow",
                "OnAimDetected", "OnHeadshotDetected", "OnPerfectAccuracy",
                "SendDSErrorLogToLobby", "SendDSHawkEyePatrolLogToLobby", "ReportMatchRoomData"
            })
        end

        local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystems then
            local aimTracker = subsystems:Get("ClientAimTrackingSubsystem")
            if aimTracker then
                aimTracker.GetAimData = function() return { accuracy = math.random(45, 65), headshotRate = math.random(15, 35) } end
                aimTracker.IsAimNormal = retTrue
            end
            local hawkEye = subsystems:Get("ClientHawkEyePatrolSubsystem")
            if hawkEye then
                hawkEye.GetPatrolData = retEmpty
                hawkEye.IsBeingWatched = retFalse
                hawkEye.GetSpectatorCount = retZero
            end
            local aiBehavior = subsystems:Get("ClientAIBehaviourSubsystem")
            if aiBehavior then
                aiBehavior.GetBehaviorScore = function() return math.random(10, 30) end
                aiBehavior.IsSuspicious = retFalse
                aiBehavior.GetRiskLevel = retZero
            end
            local speedHack = subsystems:Get("AntiSpeedHackSubsystem") or subsystems:Get("ClientAntiSpeedHackSubsystem")
            if speedHack then
                speedHack.GetSpeed = function() return math.random(300, 600) end
                speedHack.IsSpeedValid = retTrue
            end
        end

        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if isValid(pc) then
            if pc.HiggsBoson then
                pc.HiggsBoson.bMHActive = false
                pc.HiggsBoson.bCallPreReplication = false
            end
            if pc.HiggsBosonComponent then
                pc.HiggsBosonComponent.bMHActive = false
                pc.HiggsBosonComponent:ControlMHActive(0)
            end
        end

        local higgs = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if higgs then
            higgs.GetNetAvatarItemIDs = function() return { 1001, 2002, 3003 } end
            higgs.GetCurWeaponSkinID = function() return 6001 end
            higgs.GetCurItemIDs = function() return { 7001, 8002 } end
        end

        if _G.TssSdk then
            _G.TssSdk.ScanMemory = function() return true, { code = 0, msg = "clean" } end
            _G.TssSdk.VerifyFileHash = retTrue
        end
        _G.BypassState.DeadEyeDisabled = true
        _G.BypassState.HawkEyeDisabled = true
        _G.BypassState.VoklaiDisabled = true
        _G.BypassState.HiggsBosonDisabled = true
        _G.BypassState.HashVerifyDisabled = true
        _G.BypassState.IPMappingDisabled = true
        _G.BypassState.MemoryPatchDisabled = true
        _G.BypassState.EduEyeDisabled = true
        _G.BypassState.FullBypassActive = true
    end)
end

local function bypass_higgs_boson_perplayer(player)
    if not player or not isValid(player) then return end
    pcall(function()
        local Higgs = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if Higgs then
            Higgs.ControlMHActive = noop
            Higgs.TriggerAvatarCheck = noop
            Higgs.StartAvatarCheck = noop
            Higgs.ReportItemID = noop
            Higgs.ReceiveAnyDamage = noop
            Higgs.ShowSecurityAlert = noop
            Higgs.GetNetAvatarItemIDs = retEmpty
            Higgs.GetCurWeaponSkinID = retZero
        end
        if _G.AvatarCheckCallback then
            _G.AvatarCheckCallback.StartAvatarCheck = noop
            _G.AvatarCheckCallback.OnReportItemID = noop
        end
    end)
end

local function hookPerPlayerHiggs()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if pc and isValid(pc) then
        local pawn = pc:GetCurPawn()
        if isValid(pawn) then bypass_higgs_boson_perplayer(pawn) end
    end
end

local function huntAndKillAll()
    pcall(function()
        local subNames = {
            "ClientHawkEyePatrolSubsystem", "DSHawkEyePatrolSubsystem",
            "ClientReportPlayerSubsystem", "DSReportPlayerSubsystem", "ClientGlueHiaSystem"
        }
        local subMgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subMgr and subMgr.Get then
            for _, name in ipairs(subNames) do
                local sub = subMgr:Get(name)
                if sub then
                    for k, v in pairs(sub) do
                        if type(v) == "function" and
                            (k:find("Report") or k:find("Send") or k:find("Tick") or k:find("Log")) then
                            pcall(function() sub[k] = noop end)
                        end
                    end
                end
            end
        end
    end)
end

local function startPersistentTimer()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if pc and isValid(pc) then
        if _G._permHuntTimer then pcall(function() pc:RemoveGameTimer(_G._permHuntTimer) end) end
        _G._permHuntTimer = pc:AddGameTimer(3.0, true, huntAndKillAll)
        return true
    end
    return false
end

local ok_gd, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
if not ok_gd then GameplayData = nil end

local InGameMarkTools = safe_require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
local SecurityCommonUtils = safe_require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
local IngamePhoneStateUI = safe_require("GameLua.Mod.Library.Client.UI.IngamePhoneStateUI")

-- MOD TOGGLES
_G.MOD_ESPEnabled = true
_G.MOD_EnemyCounterEnabled = true
_G.MOD_Watermark_Enabled = true
_G.MOD_WallhackEnabled = false
_G.MOD_VisualCleanupEnabled = false
_G.Mod_AimAssist_Enabled = true
_G.AimAssist_Power_Slider = 0
_G.AimAssist_Power = 1.0
_G.Mod_NoRecoil_Enabled = true
_G.MOD_AntiLag_Enabled = true
_G.Mod_iPadView_Enabled = true
_G.iPadView_FOV_Slider = 110
_G.MOD_AdvancedESP_Box = false
_G.MOD_CustomMiniMapESP = false
_G.MOD_VehicleESP = false
_G.MOD_ZeroTouchDelay = true

local distanceMarkerConfig = {
    UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
    MaxWidgetNum = 99,
    MaxShowDistance = 30000,
    bBindOutScreen = true,
    bBindBlocked = true,
    bIsBindingActor = true,
    BindSocketName = "head",
    bUseLuaWorldSocketName = true,
    WorldPositionOffset = FVector(0, 0, 50),
    bNeedPreLoad = true,
    Priority = 2
}

_G.AK_Active_Marks_Cache = _G.AK_Active_Marks_Cache or setmetatable({}, { __mode = "k" })

local function InitDistanceMarkerSystem()
    pcall(function()
        if InGameMarkTools and InGameMarkTools.ScreenMarkManager and InGameMarkTools.ScreenMarkManager.OnInitMarkGroupData then
            InGameMarkTools.ScreenMarkManager:OnInitMarkGroupData(9999)
        end
        local gameplayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
        local screenMarkConfig = gameplayTools.GetCurrentConfig("ScreenMarkConfig")
        if screenMarkConfig then screenMarkConfig[9999] = distanceMarkerConfig end
    end)
end

local function createDistanceMarker(enemy)
    pcall(function()
        if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
            enemy.NativeDistMark = InGameMarkTools.ClientAddMapMark(9999, FVector(0, 0, 0), 0, "", 4, enemy)
            _G.AK_Active_Marks_Cache[enemy] = { actor = enemy, distMark = enemy.NativeDistMark }
        end
    end)
end

local function removeDistanceMarker(enemy)
    pcall(function()
        if InGameMarkTools then
            if InGameMarkTools.ClientRemoveMapMark then
                InGameMarkTools.ClientRemoveMapMark(enemy.NativeDistMark)
            elseif InGameMarkTools.HideMapMark then
                InGameMarkTools.HideMapMark(enemy.NativeDistMark)
            end
        end
        enemy.NativeDistMark = nil
        _G.AK_Active_Marks_CACHE = _G.AK_Active_Marks_Cache 
        _G.AK_Active_Marks_Cache[enemy] = nil
    end)
end

local function cleanupDeadEnemyMarks()
    for cacheKey, cacheData in pairs(_G.AK_Active_Marks_Cache) do
        local shouldRemove = false
        if not isValid(cacheKey) then
            shouldRemove = true
        else
            pcall(function()
                local actor = cacheData and cacheData.actor or cacheKey
                if actor then
                    if actor.bHidden or (actor.Mesh and actor.Mesh.bHidden) then shouldRemove = true end
                    if type(actor.IsDead) == "function" and actor:IsDead() then
                        shouldRemove = true
                    elseif actor.bIsDead == true or actor.bIsDeadFlag == true then
                        shouldRemove = true
                    end
                else
                    shouldRemove = true
                end
            end)
        end
        if shouldRemove then
            pcall(function()
                if cacheData and InGameMarkTools and InGameMarkTools.ClientRemoveMapMark then
                    pcall(function() InGameMarkTools.ClientRemoveMapMark(cacheData.distMark) end)
                end
            end)
            _G.AK_Active_Marks_Cache[cacheKey] = nil
        end
    end
end

local function processEnemyMapESP(enemy, localPlayer)
    if not _G.MOD_CustomMiniMapESP then return end
    if not isValid(enemy) or enemy == localPlayer or enemy.TeamID == localPlayer.TeamID then return end

    local dist = localPlayer:GetDistanceTo(enemy)
    if dist > 30000 then
        if enemy.bHasAKNativeMapMarker then
            removeDistanceMarker(enemy)
            enemy.bHasAKNativeMapMarker = false
        end
        return
    end

    local isDead = false
    pcall(function()
        if type(enemy.IsDead) == "function" then
            isDead = enemy:IsDead()
        elseif enemy.bIsDead ~= nil then
            isDead = enemy.bIsDead
        elseif enemy.bIsDeadFlag ~= nil then
            isDead = enemy.bIsDeadFlag
        end
        if enemy.bHidden or (enemy.Mesh and enemy.Mesh.bHidden) then isDead = true end
        if not isDead then
            local health = 100
            if type(enemy.GetHealth) == "function" then
                health = enemy:GetHealth()
            elseif enemy.Health ~= nil then
                health = enemy.Health
            end
            if health <= 0 then isDead = true end
        end
    end)

    if not isDead then
        if not enemy.bHasAKNativeMapMarker then
            createDistanceMarker(enemy)
            enemy.bHasAKNativeMapMarker = true
        end
    else
        if enemy.bHasAKNativeMapMarker then
            removeDistanceMarker(enemy)
            enemy.bHasAKNativeMapMarker = false
        end
    end
end

local function VehicleESPLoop()
    if not _G.MOD_VehicleESP then return end
    local pc = slua_GameFrontendHUD:GetPlayerController()
    if not isValid(pc) then return end
    local localPlayer = pc:GetPlayerCharacterSafety()
    if not isValid(localPlayer) then return end
    local myPos = localPlayer:K2_GetActorLocation()
    if not myPos then return end
    local HUD = pc:GetHUD()
    if not isValid(HUD) then return end

    if not _G._VehicleCacheTime or os.clock() - _G._VehicleCacheTime > 1.0 then
        _G._VehicleCacheTime = os.clock()
        _G._VehicleCache = Game:GetAllVehicles() or {}
    end

    for _, vehicle in pairs(_G._VehicleCache) do
        if isValid(vehicle) then
            local vPos = vehicle:K2_GetActorLocation()
            local dx = vPos.X - myPos.X
            local dy = vPos.Y - myPos.Y
            local dz = vPos.Z - myPos.Z
            local distSq = dx * dx + dy * dy + dz * dz
            if distSq < 900000000 then
                local dist = math.sqrt(distSq)
                local distText = string.format("[%.0fm]", dist / 100)
                HUD:AddDebugText("Vehicle " .. distText, vehicle, 0.35,
                    { X = 0, Y = 0, Z = 100 }, { X = 0, Y = 0, Z = 100 },
                    { R = 255, G = 255, B = 0, A = 255 },
                    true, false, true, nil, 1.0, true)
            end
        end
    end
end

local o_UpdateArtQualityUI
if IngamePhoneStateUI and IngamePhoneStateUI.__inner_impl and IngamePhoneStateUI.__inner_impl.UpdateArtQualityUI then
    o_UpdateArtQualityUI = IngamePhoneStateUI.__inner_impl.UpdateArtQualityUI
    IngamePhoneStateUI.__inner_impl.UpdateArtQualityUI = function(self, arg1, arg2)
        if not _G.MOD_Watermark_Enabled and self._GokuUI_Applied then
            pcall(function() self.CacheQuality = nil; self.LastQuality = nil end)
        end
        if o_UpdateArtQualityUI then pcall(o_UpdateArtQualityUI, self, arg1, arg2) end
        if self and self.UIRoot and self.UIRoot.TextBlock_quality then
            if _G.MOD_Watermark_Enabled then
                self.UIRoot.TextBlock_quality:SetText("GOKUCONFIG")
                self.UIRoot.TextBlock_quality:SetColorAndOpacity(FSlateColor(FLinearColor(0, 1, 1, 1)))
                self._GokuUI_Applied = true
            elseif self._GokuUI_Applied then
                self.UIRoot.TextBlock_quality:SetText("20ms")
                self.UIRoot.TextBlock_quality:SetColorAndOpacity(FSlateColor(FLinearColor(0.4, 0.8, 0.4, 1)))
                self._GokuUI_Applied = false
            end
        end
    end
end

local function ApplyEnvironment()
    pcall(function()
        local gi = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
        if not gi then return end

        if _G.MOD_ZeroTouchDelay then
            gi:ExecuteCMD("r.Input.EnableBufferedInput", "0")
        else
            gi:ExecuteCMD("r.Input.EnableBufferedInput", "1")
        end

        gi:ExecuteCMD("r.Touch.EnableVibration", "0")
        gi:ExecuteCMD("r.GTSyncType", "2")
        gi:ExecuteCMD("r.OneFrameThreadLag", "0")

        if _G.MOD_VisualCleanupEnabled then
            gi:ExecuteCMD("grass.DensityScale", "0")
            gi:ExecuteCMD("grass.DiscardDataOnLoad", "1")
            gi:ExecuteCMD("r.Fog", "0")
            gi:ExecuteCMD("r.FogDensity", "0")
            gi:ExecuteCMD("r.FogInscatteringColor", "(R=0,G=0,B=0,A=0)")
            gi:ExecuteCMD("r.VolumetricFog", "0")
            gi:ExecuteCMD("r.ParticleQuality", "0")
            gi:ExecuteCMD("r.ParticleLODBias", "15")
        else
            gi:ExecuteCMD("grass.DensityScale", "1")
            gi:ExecuteCMD("grass.DiscardDataOnLoad", "0")
            gi:ExecuteCMD("r.Fog", "1")
            gi:ExecuteCMD("r.VolumetricFog", "1")
            gi:ExecuteCMD("r.ParticleQuality", "3")
            gi:ExecuteCMD("r.ParticleLODBias", "0")
        end
    end)
end

_G._MatchTimer = 0
local function ThermalGovernorLoop()
    pcall(function()
        _G._MatchTimer = _G._MatchTimer + 1
        if _G._MatchTimer == 300 then
            local gi = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
            if gi then
                gi:ExecuteCMD("r.BloomQuality", "0")
                gi:ExecuteCMD("r.SceneColorFringeQuality", "0")
                gi:ExecuteCMD("r.Tonemapper.Quality", "0")
            end
        end
    end)
end

local _WH_OrigMaterials = setmetatable({}, { __mode = "k" }) 
local _WH_ModifiedPawns = setmetatable({}, { __mode = "k" }) 
local _WH_ModifiedBaseMaterials = setmetatable({}, { __mode = "k" }) 
_G._advCachedPawns = _G._advCachedPawns or {}
_G._advLastPawnRefresh = 0

function _G.ForceCleanupMatch()
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        
        if _G._AdvESPGlobalTimer then
            Game:ClearTimer(_G._AdvESPGlobalTimer)
            _G._AdvESPGlobalTimer = nil
        end
        if _G._AssistTimer and pc then 
            pcall(function() pc:RemoveGameTimer(_G._AssistTimer) end)
            _G._AssistTimer = nil 
        end
        if _G._WallhackTimer and pc then 
            pcall(function() pc:RemoveGameTimer(_G._WallhackTimer) end)
            _G._WallhackTimer = nil 
        end
        if _G._MiniMapTimer and pc then 
            pcall(function() pc:RemoveGameTimer(_G._MiniMapTimer) end)
            _G._MiniMapTimer = nil 
        end
        if _G._VehicleTimer and pc then 
            pcall(function() pc:RemoveGameTimer(_G._VehicleTimer) end)
            _G._VehicleTimer = nil 
        end
        if _G._AutoRAMCleaner and pc then 
            pcall(function() pc:RemoveGameTimer(_G._AutoRAMCleaner) end)
            _G._AutoRAMCleaner = nil 
        end

        if _G.LOCAL_UI_TIMER then _G.LOCAL_UI_TIMER = nil end
        _WH_OrigMaterials = setmetatable({}, { __mode = "k" })
        _WH_ModifiedPawns = setmetatable({}, { __mode = "k" })
        _WH_ModifiedBaseMaterials = setmetatable({}, { __mode = "k" })
        _G.LastAimEntity = nil
        _G.LastAimState = nil
        _G.LastRecoilEntity = nil
        _G.LastRecoilState = nil
        _G._MatchTimer = 0

        _G._advCachedPawns = {}
        _G._advLastPawnRefresh = 0
        _G.AK_Active_Marks_Cache = setmetatable({}, { __mode = "k" })

        if _G.BypassState then
            for k, _ in pairs(_G.BypassState) do _G.BypassState[k] = false end
        end

        collectgarbage("collect")
    end)
end

local function AutoRAMCleaner()
    pcall(function()
        if _G.MOD_AntiLag_Enabled then collectgarbage("step", 200) end
    end)
end

local MsgBox, WebSDK
local function GetMsgBox()
    if not MsgBox then MsgBox = require("client.slua.logic.common.logic_common_msg_box") end
    return MsgBox
end

local function GetWebSDK()
    if not WebSDK then WebSDK = require("client.slua.logic.url.logic_webview_sdk") end
    return WebSDK
end

local welcomeShown = false
local function ShowWelcomePopup()
    if welcomeShown then return end
    welcomeShown = true
    pcall(function()
        local Msg = GetMsgBox()
        local welcomeContent = table.concat({
            "▸ VISUALS",
            " ◉ ESP · Wallhack (Red/Green) · 300m",
            " ◉ Head + Distance ESP · iPad View",
            " ◉ No Grass · No Fog · No Smoke",
            "",
            "▸ COMBAT",
            " ◉ Aim Power Control (Custom Slider)",
            " ◉ Less Recoil · Fast Bullet Reg",
            " ◉ Zero Touch Delay",
            "",
            "▸ PERFORMANCE",
            " ◉ Lag Fix · Potato Mode · RAM Cleaner",
            " ◉ Network Optimization · Thermal Sync",
            " ◉ Balanced & Stable Connection",
            "",
            "━━━━━━━━━━━━━━━━━━━━━━━━",
            " PLAY SAFE | @GOKUCONFIG",
            "━━━━━━━━━━━━━━━━━━━━━━━━"
        }, "\n")
        Msg.Show(4, "✓ GOKU FRAMEWORK — PREMIUM", welcomeContent, function()
            pcall(function() GetWebSDK():OpenURL("https://t.me/TGxGOKU_OFFICIAL") end)
        end)
    end)
end

local MOD_EXPIRY = { year = 2026, month = 6, day = 29, hour = 0, min = 1, sec = 0 }
local MOD_EXPIRY_TS = os.time(MOD_EXPIRY)
local function isModExpired() return os.time() > MOD_EXPIRY_TS end

local lastExpiryDialogTime = 0
local function ShowExpiryDialog()
    local ct = os.clock()
    if ct - lastExpiryDialogTime < 5.0 then return end
    lastExpiryDialogTime = ct
    pcall(function()
        local Msg = GetMsgBox()
        local expiryContent = table.concat({
            "GOKU FRAMEWORK license has expired.",
            "This session is permanently locked.",
            "",
            "Developer: @GOKUCONFIG",
            "Tap [Contact] to open Telegram."
        }, "\n")
        Msg.Show(4, "[!] ACCESS REVOKED", expiryContent, function()
            pcall(function() GetWebSDK():OpenURL("https://t.me/GOKUCONFIG") end)
        end, nil, "Contact", "Cancel")
    end)
end

local function DetectBasePath()
    local pkgs = { "com.tencent.ig", "com.pubg.imobile", "com.pubg.krmobile", "com.vng.pubgmobile", "com.rekoo.pubg" }
    for _, pkg in ipairs(pkgs) do
        local p = "/storage/emulated/0/Android/data/" .. pkg .. "/files/config.ini"
        local f = io.open(p, "r")
        if f then f:close(); return "/storage/emulated/0/Android/data/" .. pkg .. "/files/" end
    end
    return "/storage/emulated/0/Android/data/com.pubg.imobile/files/"
end

local BASE_PATH = DetectBasePath()
local FEATURE_DIR = BASE_PATH .. "GOKUCONFIG/"

function _G.LoadAllFeatures()
    local hud = slua_GameFrontendHUD
    if not hud then return end
    local pc = hud:GetPlayerController()
    if _G._LastPC ~= pc then
        _G._LastPC = pc
        _G.ForceCleanupMatch()
        _G.WelcomeShown = nil
        _G.ModsEnabled = true
        ShowWelcomePopup()
    end
    if _G._FeaturesLoaded then return end
    local off = io.open(FEATURE_DIR .. ".off", "r")
    if off then off:close(); _G.ModsEnabled = false; _G._FeaturesLoaded = true; return end
    for i = 1, 100 do
        local path = FEATURE_DIR .. i .. ".lua"
        local f = io.open(path, "r")
        if not f then break end
        local code = f:read("*all"); f:close()
        local ok, func = pcall(load, code, path)
        if ok and func then pcall(func) end
    end
    _G._FeaturesLoaded = true
end

local aimOriginalCache = setmetatable({}, { __mode = "k" })
local AIM_BASE_VALUES = {
    Speed = 8.1, RangeRate = 1.8, SpeedRate = 2.5, RangeRateSight = 5.5,
    SpeedRateSight = 1.4, CrouchRate = 1.2, ProneRate = 1.1, DyingRate = 0
}

local function ApplyAimAssist()
    if not _G.Mod_AimAssist_Enabled then return end
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not isValid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not isValid(char) then return end
        local wm = char.WeaponManagerComponent
        if not wm then return end
        local weapon = wm.CurrentWeaponReplicated
        if not weapon then return end
        local entity = weapon.ShootWeaponEntityComp
        if not isValid(entity) or not entity.AutoAimingConfig then return end

        local currentState = tostring(_G.Mod_AimAssist_Enabled) .. tostring(_G.AimAssist_Power)
        if entity == _G.LastAimEntity and currentState == _G.LastAimState then return end
        _G.LastAimEntity = entity; _G.LastAimState = currentState

        if not aimOriginalCache[entity] then
            local saved = {}
            for _, range in ipairs({ "OuterRange", "InnerRange" }) do
                local cfg = entity.AutoAimingConfig[range]
                if cfg then
                    saved[range] = {}
                    for k, _ in pairs(AIM_BASE_VALUES) do
                        if cfg[k] ~= nil then saved[range][k] = cfg[k] end
                    end
                end
            end
            aimOriginalCache[entity] = saved
        end

        local mult = _G.AimAssist_Power
        for _, range in ipairs({ "OuterRange", "InnerRange" }) do
            local cfg = entity.AutoAimingConfig[range]
            if cfg then
                for k, v in pairs(AIM_BASE_VALUES) do cfg[k] = v * mult end
            end
        end
    end)
end

local recoilOriginalCache = setmetatable({}, { __mode = "k" })
local RECOIL_FIELDS = {
    "RecoilKick", "RecoilKickADS", "AnimationKick", "AccessoriesVRecoilFactor",
    "AccessoriesHRecoilFactor", "GameDeviationFactor", "RecoilModifierStand",
    "RecoilModifierCrouch", "RecoilModifierProne", "CameraShakeScale",
    "AimCameraShakeScale", "ShootCameraShakeScale", "FireCameraShakeScale",
    "GameDeviationAccuracy", "ShotGunHorizontalSpread", "ShotGunVerticalSpread",
    "DeviationMultiplier"
}
local RECOIL_TARGET_VALUES = {
    RecoilKick = 0.18, RecoilKickADS = 0.14, AnimationKick = 0.08,
    AccessoriesVRecoilFactor = 0.18, AccessoriesHRecoilFactor = 0.38,
    GameDeviationFactor = 0.38, RecoilModifierStand = 0.22,
    RecoilModifierCrouch = 0.18, RecoilModifierProne = 0.28,
    CameraShakeScale = 0.12, AimCameraShakeScale = 0.10,
    ShootCameraShakeScale = 0.10, FireCameraShakeScale = 0.10,
    GameDeviationAccuracy = 0.10, ShotGunHorizontalSpread = 0.15,
    ShotGunVerticalSpread = 0.15, DeviationMultiplier = 0.15
}
local RECOIL_INFO_FIELDS = {
    "VerticalRecoilMin", "VerticalRecoilMax", "RecoilSpeedVertical",
    "RecoilSpeedHorizontal", "VerticalRecoveryMax"
}
local RECOIL_INFO_TARGET = {
    VerticalRecoilMin = 0.3, VerticalRecoilMax = 0.4, RecoilSpeedVertical = 0.2,
    RecoilSpeedHorizontal = 0.4, VerticalRecoveryMax = 0.1
}

local function ApplyNoRecoil()
    if not _G.Mod_NoRecoil_Enabled then return end
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not isValid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not isValid(char) then return end
        local wm = char.WeaponManagerComponent
        if not wm then return end
        local weapon = wm.CurrentWeaponReplicated
        if not weapon then return end
        local entity = weapon.ShootWeaponEntityComp
        if not isValid(entity) then return end

        if entity == _G.LastRecoilEntity and _G.Mod_NoRecoil_Enabled == _G.LastRecoilState then return end
        _G.LastRecoilEntity = entity; _G.LastRecoilState = _G.Mod_NoRecoil_Enabled

        if not recoilOriginalCache[entity] then
            local saved = { RecoilInfo = {} }
            for _, f in ipairs(RECOIL_FIELDS) do
                if entity[f] ~= nil then saved[f] = entity[f] end
            end
            if entity.RecoilInfo then
                for _, f in ipairs(RECOIL_INFO_FIELDS) do
                    if entity.RecoilInfo[f] ~= nil then saved.RecoilInfo[f] = entity.RecoilInfo[f] end
                end
            end
            if entity.ShootCameraShake then
                saved.ShootCameraShakeScale = entity.ShootCameraShake.Scale
            end
            recoilOriginalCache[entity] = saved
        end

        for k, v in pairs(RECOIL_TARGET_VALUES) do entity[k] = v end
        if entity.RecoilInfo then
            for k, v in pairs(RECOIL_INFO_TARGET) do entity.RecoilInfo[k] = v end
        end
        if entity.ShootCameraShake then entity.ShootCameraShake.Scale = 0.10 end
    end)
end

local ipadViewOrigCache = setmetatable({}, { __mode = "k" })
local function ApplyiPadView()
    if not _G.Mod_iPadView_Enabled then return end
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not isValid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not isValid(char) or not char.ThirdPersonCameraComponent then return end
        local cam = char.ThirdPersonCameraComponent
        if not ipadViewOrigCache[char] then ipadViewOrigCache[char] = cam.FieldOfView or 90 end
        local isAiming = false
        pcall(function() isAiming = char.bIsTargeting end)
        if isAiming then return end
        local targetFov = _G.iPadView_FOV_Slider or 110
        if cam.FieldOfView ~= targetFov then cam.FieldOfView = targetFov end
    end)
end

if GameplayData then
    local COLOR_SAFE = { R = 0, G = 255, B = 200, A = 255 }
    local COLOR_WARN = { R = 255, G = 150, B = 0, A = 255 }
    local COLOR_DANGER = { R = 255, G = 20, B = 60, A = 255 }
    local TEXT_OFFSET = { X = 0, Y = 0, Z = 35 }
    local WATERMARK_OFFSET = { X = 0, Y = 0, Z = -10 }
    local TEXT_SCALE = 1.05
    local MAX_DIST_SQ = 900000000

    function LocalPlayerUILoop()
        pcall(function()
            if not (_G.MOD_EnemyCounterEnabled or _G.MOD_Watermark_Enabled) then return end
            local player = GameplayData.GetPlayerCharacter()
            if not isValid(player) then return end
            local pc = slua_GameFrontendHUD:GetPlayerController()
            if not isValid(pc) then return end
            local hud = pc:GetHUD()
            if not isValid(hud) then return end

            if _G.MOD_Watermark_Enabled then
                hud:AddDebugText("✦ REAL DEV GOKUCONFIG ✦", player, 1.1,
                    WATERMARK_OFFSET, WATERMARK_OFFSET,
                    { R = 0, G = 255, B = 255, A = 255 },
                    true, false, true, nil, 0.8, true)
            end

            if _G.MOD_EnemyCounterEnabled then
                local myTeamId = player.TeamID or 0
                local myPos = player:K2_GetActorLocation()
                local enemyCount = 0
                local allPawns = Game:GetAllPlayerPawns() or {}
                for _, pawn in pairs(allPawns) do
                    if isValid(pawn) and pawn ~= player and (pawn.TeamID or 0) ~= myTeamId then
                        local pos = pawn:K2_GetActorLocation()
                        local dx = pos.X - myPos.X
                        local dy = pos.Y - myPos.Y
                        local dz = pos.Z - myPos.Z
                        if (dx * dx + dy * dy + dz * dz) <= MAX_DIST_SQ then
                            enemyCount = enemyCount + 1
                        end
                    end
                end
                local text, color
                if enemyCount == 0 then
                    text = "[ AREA SECURE ]"; color = COLOR_SAFE
                elseif enemyCount == 1 then
                    text = "! WARNING : 1 ENEMY !"; color = COLOR_WARN
                else
                    text = "[ DANGER : " .. enemyCount .. " ENEMIES ]"; color = COLOR_DANGER
                end
                hud:AddDebugText(text, player, 1.1, TEXT_OFFSET, TEXT_OFFSET,
                    color, true, false, true, nil, TEXT_SCALE, true)
            end
        end)
    end

    function StartLocalPlayerUITimers()
        pcall(function()
            local pc = slua_GameFrontendHUD:GetPlayerController()
            if not isValid(pc) then
                pc = import("GameplayStatics").GetPlayerController(slua_GameFrontendHUD:GetWorld(), 0)
            end
            if not isValid(pc) then return end
            if _G.LOCAL_UI_TIMER == pc then return end
            _G.LOCAL_UI_TIMER = pc
            pc:AddGameTimer(0.2, false, function()
                local controller = slua_GameFrontendHUD:GetPlayerController()
                if isValid(controller) then
                    controller:AddGameTimer(1.0, true, LocalPlayerUILoop)
                end
            end)
        end)
    end
end

local function IsPawnAlive(p)
    if not isValid(p) then return false end
    if p.HealthStatus then return SecurityCommonUtils and SecurityCommonUtils.IsHealthStatusAlive(p.HealthStatus) end
    if p.IsAlive then return p:IsAlive() end
    return p.GetHealth and (p:GetHealth() or 0) > 0 or false
end

local function GetPawnHealthRatio(p)
    local hp = p.GetHealth and p:GetHealth() or 100
    local maxHp = p.GetHealthMax and p:GetHealthMax() or 100
    return math.max(0, math.min(1, hp / (maxHp <= 0 and 100 or maxHp)))
end

local function SetRedFrameUI(p)
    if not isValid(p) then return end
    local COLOR_RED = FLinearColor(1, 0, 0, 1)
    if p.Replay_SetFrameUIColor then
        p:Replay_SetFrameUIColor(COLOR_RED)
    elseif p.SetEnemyFrameColor then
        p:SetEnemyFrameColor(COLOR_RED)
    elseif p.SetFrameColor then
        p:SetFrameColor(COLOR_RED)
    elseif p.SetOutlineColor then
        p:SetOutlineColor(COLOR_RED)
    end
end

local function ClearWallHackForPawn(pawn)
    if not isValid(pawn) then return end
    local meshes = {}
    pcall(function()
        if isValid(pawn.Mesh) then table.insert(meshes, pawn.Mesh) end
        local SkelClass = import("SkeletalMeshComponent")
        if SkelClass then
            local childs = pawn:GetComponentsByClass(SkelClass)
            if childs then
                local count = type(childs.Num) == "function" and childs:Num() or #childs
                for c = 1, count do
                    local comp = type(childs.Get) == "function" and childs:Get(c - 1) or childs[c]
                    if isValid(comp) and comp ~= pawn.Mesh then table.insert(meshes, comp) end
                end
            end
        end
    end)
    for _, comp in ipairs(meshes) do
        pcall(function()
            comp.bRenderCustomDepth = false
            comp.CustomDepthStencilValue = 0
            local origMatSlots = _WH_OrigMaterials[comp]
            if origMatSlots then
                for i, mat in pairs(origMatSlots) do
                    pcall(function() comp:SetMaterial(i, mat) end)
                end
                _WH_OrigMaterials[comp] = nil
            end
        end)
    end
    pawn._WH_MIDs = nil
    _WH_ModifiedPawns[pawn] = nil
end

local function ApplyWallHack(enemy, pc)
    if not _G.MOD_WallhackEnabled then return end
    if not isValid(enemy) or not isValid(pc) then return end

    local meshes = {}
    pcall(function()
        if isValid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
        local SkelClass = import("SkeletalMeshComponent")
        if SkelClass then
            local childs = enemy:GetComponentsByClass(SkelClass)
            if childs then
                local count = type(childs.Num) == "function" and childs:Num() or #childs
                for c = 1, count do
                    local comp = type(childs.Get) == "function" and childs:Get(c - 1) or childs[c]
                    if isValid(comp) and comp ~= enemy.Mesh then table.insert(meshes, comp) end
                end
            end
        end
    end)

    local isVisible = false
    pcall(function()
        if type(pc.LineOfSightTo) == "function" then isVisible = pc:LineOfSightTo(enemy) end
    end)
    local bodyColor = isVisible and { R = 0, G = 255, B = 0, A = 255 } or { R = 255, G = 0, B = 0, A = 255 }
    local glowColor = isVisible and { R = 0, G = 255, B = 255, A = 255 } or { R = 255, G = 0, B = 128, A = 255 }

    enemy._WH_MIDs = enemy._WH_MIDs or {}
    local stateChanged = (enemy._WH_LastVisible ~= isVisible)
    enemy._WH_LastVisible = isVisible
    _WH_ModifiedPawns[enemy] = true

    for _, comp in ipairs(meshes) do
        if isValid(comp) then
            if not _WH_OrigMaterials[comp] then
                local orig = {}
                for i = 0, 15 do
                    local ok, mat = pcall(function() return comp:GetMaterial(i) end)
                    if ok and isValid(mat) then orig[i] = mat else break end
                end
                _WH_OrigMaterials[comp] = orig
            end
            pcall(function()
                comp.bRenderCustomDepth = true
                comp.CustomDepthStencilValue = 250
                comp.CustomDepthStencilWriteMask = 255
            end)
            pcall(function()
                local ok, mat = pcall(function() return comp:GetMaterial(0) end)
                if ok and isValid(mat) then
                    local ok2, base = pcall(function() return mat:GetBaseMaterial() end)
                    if ok2 and isValid(base) then
                        if not _WH_ModifiedBaseMaterials[base] then
                            _WH_ModifiedBaseMaterials[base] = {
                                bDisableDepthTest = base.bDisableDepthTest,
                                BlendMode = base.BlendMode
                            }
                        end
                        if base.bDisableDepthTest ~= true then base.bDisableDepthTest = true end
                        if base.BlendMode ~= 2 then base.BlendMode = 2 end
                    end
                end
            end)
            comp.UseScopeDistanceCulling = false
            comp.PrimitiveShadingStrategy = 1
            comp.ShadingRate = 6
            enemy._WH_MIDs[comp] = enemy._WH_MIDs[comp] or {}
            for i = 0, 15 do
                local ok3, mi = pcall(function() return comp:GetMaterial(i) end)
                if not ok3 or not isValid(mi) then break end
                local mid = enemy._WH_MIDs[comp][i]
                if not isValid(mid) then
                    local ok4, nm = pcall(function() return comp:CreateAndSetMaterialInstanceDynamic(i) end)
                    if ok4 and isValid(nm) then
                        enemy._WH_MIDs[comp][i] = nm; mid = nm
                    end
                else
                    if mi ~= mid then pcall(function() comp:SetMaterial(i, mid) end) end
                end
                if isValid(mid) and (stateChanged or not enemy._WH_MIDs[comp][i]) then
                    pcall(function()
                        mid:SetVectorParameterValue("颜色", bodyColor)
                        mid:SetVectorParameterValue("Extra Light Color", bodyColor)
                        mid:SetVectorParameterValue("Para_Color", bodyColor)
                        mid:SetVectorParameterValue("Tint", bodyColor)
                        mid:SetVectorParameterValue("BaseColor", bodyColor)
                        mid:SetVectorParameterValue("BodyColor", bodyColor)
                        mid:SetVectorParameterValue("GlowColor", glowColor)
                        mid:SetVectorParameterValue("OutlineColor", glowColor)
                        mid:SetScalarParameterValue("Glow", 10.0)
                        mid:SetScalarParameterValue("GlowAmount", 10.0)
                        mid:SetScalarParameterValue("EmissiveBoost", 5.0)
                    end)
                end
            end
        end
    end
end

_G._WH_NeedCleanup = false
function OnWallhackToggleChanged()
    if not _G.MOD_WallhackEnabled then _G._WH_NeedCleanup = true end
end

local function ESPTickAdv()
    if not _G.MOD_AdvancedESP_Box then return end
    local ASTExtraPlayerController = import("/Script/ShadowTrackerExtra.STExtraPlayerController")
    local uCon = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not (isValid(uCon) and Game:IsClassOf(uCon, ASTExtraPlayerController)) then return end
    local currentPawn = uCon:GetCurPawn()
    if not isValid(currentPawn) then return end

    local myTeamId = 0
    pcall(function()
        local char = uCon:GetPlayerCharacterSafety()
        if isValid(char) and char.TeamID then
            myTeamId = char.TeamID
        elseif currentPawn.TeamID then
            myTeamId = currentPawn.TeamID
        end
    end)

    local myPos = nil
    pcall(function() myPos = currentPawn:K2_GetActorLocation() end)
    if not myPos then return end

    local HUD = uCon:GetHUD()
    local now = os.clock()
    if now - _G._advLastPawnRefresh > 1.0 then
        _G._advLastPawnRefresh = now
        _G._advCachedPawns = Game:GetAllPlayerPawns() or {}
    end

    for _, tPawn in pairs(_G._advCachedPawns) do
        if isValid(tPawn) and tPawn ~= currentPawn and tPawn.TeamID ~= myTeamId and IsPawnAlive(tPawn) then
            local enemyPos = tPawn:K2_GetActorLocation()
            local dx = enemyPos.X - myPos.X
            local dy = enemyPos.Y - myPos.Y
            local dz = enemyPos.Z - myPos.Z
            local distSq = dx * dx + dy * dy + dz * dz
            if distSq < 900000000 and HUD then
                local dist = math.sqrt(distSq)
                local distM = dist / 100
                if _G.MOD_AdvancedESP_Box then
                    local headPos = tPawn.GetHeadLocation and tPawn:GetHeadLocation(false) or enemyPos
                    local hz = headPos.Z - enemyPos.Z + 15
                    local headChar = distM <= 25 and "O" or "●"
                    HUD:AddDebugText(headChar, tPawn, 1.1,
                        { X = 0, Y = 0, Z = hz }, { X = 0, Y = 0, Z = hz },
                        { R = 255, G = 0, B = 0, A = 255 },
                        true, false, true, nil, 1.0, true)
                end
            end
        end
    end
end

function StartAdvancedESPWatchdog()
    pcall(function()
        if _G._AdvESPGlobalTimer then
            Game:ClearTimer(_G._AdvESPGlobalTimer)
            _G._AdvESPGlobalTimer = nil
        end
        if _G.MOD_AdvancedESP_Box then
            _G._AdvESPGlobalTimer = Game:SetTimer(0.3, true, function() pcall(ESPTickAdv) end)
        end
    end)
end

function InjectModMenu()
    local LocUtil = _G.LocUtil
    if not LocUtil and package.loaded["client.common.LocUtil"] then
        LocUtil = require("client.common.LocUtil")
    end
    if LocUtil and not LocUtil._IsModMenuHooked then
        local old_get = LocUtil.GetLocalizeResStr
        LocUtil.GetLocalizeResStr = function(id)
            if type(id) == "string" and not tonumber(id) then return id end
            if old_get then return old_get(id) end
            return ""
        end
        LocUtil._IsModMenuHooked = true
    end

    local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
    local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")
    local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")

    if not SettingPageDefine.ModMenu then
        local ModMenuStack = {
            { UI = AliasMap.Title, Text = "✦ ESP & VISUALS ✦" },
            { Key = "ESP", UI = AliasMap.Switcher, Text = "ESP (Classic Box + HP)",
                GetFunc = function() return _G.MOD_ESPEnabled end,
                SetFunc = function(_, value) _G.MOD_ESPEnabled = value; return true end },
            { Key = "Watermark", UI = AliasMap.Switcher, Text = "Watermark (Float + UI)",
                GetFunc = function() return _G.MOD_Watermark_Enabled end,
                SetFunc = function(_, value) _G.MOD_Watermark_Enabled = value; return true end },
            { Key = "AdvESP_Box", UI = AliasMap.Switcher, Text = "Head Location ESP",
                GetFunc = function() return _G.MOD_AdvancedESP_Box end,
                SetFunc = function(_, value) _G.MOD_AdvancedESP_Box = value; StartAdvancedESPWatchdog(); return true end },
            { Key = "CustomMiniMapESP", UI = AliasMap.Switcher, Text = "Custom Mini Map ESP (UI)",
                GetFunc = function() return _G.MOD_CustomMiniMapESP end,
                SetFunc = function(_, value) _G.MOD_CustomMiniMapESP = value; return true end },
            { Key = "VehicleESP", UI = AliasMap.Switcher, Text = "Vehicle ESP",
                GetFunc = function() return _G.MOD_VehicleESP end,
                SetFunc = function(_, value) _G.MOD_VehicleESP = value; return true end },
            { Key = "Wallhack", UI = AliasMap.Switcher, Text = "Wallhack (Chams)",
                GetFunc = function() return _G.MOD_WallhackEnabled end,
                SetFunc = function(_, value) _G.MOD_WallhackEnabled = value; OnWallhackToggleChanged(); return true end },
            { Key = "EnemyCounter", UI = AliasMap.Switcher, Text = "Enemy Counter (300m)",
                GetFunc = function() return _G.MOD_EnemyCounterEnabled end,
                SetFunc = function(_, value) _G.MOD_EnemyCounterEnabled = value; return true end },

            { UI = AliasMap.Title, Text = "✦ GRAPHICS & PERFORMANCE ✦" },
            { Key = "VisualCleanup", UI = AliasMap.Switcher, Text = "Visual Cleanup (No Grass/Fog/Smoke)",
                GetFunc = function() return _G.MOD_VisualCleanupEnabled end,
                SetFunc = function(_, value) _G.MOD_VisualCleanupEnabled = value; ApplyEnvironment(); return true end },
            { Key = "AntiLag", UI = AliasMap.Switcher, Text = "Anti-Lag (Auto Clear RAM)",
                GetFunc = function() return _G.MOD_AntiLag_Enabled end,
                SetFunc = function(_, value) _G.MOD_AntiLag_Enabled = value; return true end },
            { Key = "ZeroTouchDelay", UI = AliasMap.Switcher, Text = "Zero Touch Delay",
                GetFunc = function() return _G.MOD_ZeroTouchDelay end,
                SetFunc = function(_, value) _G.MOD_ZeroTouchDelay = value; ApplyEnvironment(); return true end },

            { UI = AliasMap.Title, Text = "✦ COMBAT & PERFORMANCE ✦" },
            { Key = "AimAssist", UI = AliasMap.Switcher, Text = "Aim Assist (Master Toggle)",
                GetFunc = function() return _G.Mod_AimAssist_Enabled end,
                SetFunc = function(_, value) _G.Mod_AimAssist_Enabled = value; _G.LastAimState = nil; return true end },
            { Key = "AimPower", UI = AliasMap.Slider, Text = "Aim Power (0=Legit, 100=Brutal)",
                GetFunc = function() return _G.AimAssist_Power_Slider end,
                SetFunc = function(_, value)
                    local val = tonumber(value) or 0
                    if val > 100 then val = 100 end
                    if val < 0 then val = 0 end
                    _G.AimAssist_Power_Slider = val
                    _G.AimAssist_Power = 1.0 + (val / 100) * 1.5
                    _G.LastAimState = nil
                    return true
                end },
            { Key = "NoRecoil", UI = AliasMap.Switcher, Text = "Less Recoil",
                GetFunc = function() return _G.Mod_NoRecoil_Enabled end,
                SetFunc = function(_, value) _G.Mod_NoRecoil_Enabled = value; return true end },
            { Key = "iPadViewToggle", UI = AliasMap.Switcher, Text = "Enable iPad View",
                GetFunc = function() return _G.Mod_iPadView_Enabled end,
                SetFunc = function(_, value) _G.Mod_iPadView_Enabled = value; ApplyiPadView(); return true end },
            { Key = "iPadViewFOV", UI = AliasMap.Slider, Text = "iPad View FOV (110-130)",
                GetFunc = function()
                    local currentFov = _G.iPadView_FOV_Slider or 110
                    return ((currentFov - 110) / 20) * 100
                end,
                SetFunc = function(_, value)
                    local val = tonumber(value) or 0
                    if val > 100 then val = 100 end
                    if val < 0 then val = 0 end
                    _G.iPadView_FOV_Slider = 110 + (val / 100) * 20
                    return true
                end },
        }
        SettingPageDefine.ModMenu = {
            Key = "ModMenu", loc = "GOKU CONFIG", UIKey = "Setting_Page_Privacy",
            Category = { { Key = "ModMenu_Main", loc = "Features", Stack = ModMenuStack } }
        }
    end

    local alreadyInCatalog = false
    for _, page in ipairs(SettingCatalog) do
        if page.Key == "ModMenu" then alreadyInCatalog = true; break end
    end
    if not alreadyInCatalog then table.insert(SettingCatalog, SettingPageDefine.ModMenu) end

    local UIManager = _G.UIManager
    if UIManager and not UIManager._IsModMenuHooked then
        local old_ShowUI = UIManager.ShowUI
        UIManager.ShowUI = function(config, ...)
            local args = { ... }
            if config and config.keyName and
                (string.find(string.lower(config.keyName), "setting_main") or
                    string.find(string.lower(config.keyName), "setting")) then
                local catalog = args[1]
                if catalog and (type(catalog) == "table" or type(catalog) == "userdata") then
                    local hasModMenu = false
                    local newCatalog = {}
                    for _, page in ipairs(catalog) do
                        table.insert(newCatalog, page)
                        if page.Key == "ModMenu" then hasModMenu = true end
                    end
                    if not hasModMenu then
                        table.insert(newCatalog, SettingPageDefine.ModMenu)
                        args[1] = newCatalog
                    end
                end
            end
            return old_ShowUI(config, table.unpack(args))
        end
        UIManager._IsModMenuHooked = true
    end
end

local function InitVisualAssistance(pc)
    if not Client or _G._AssistTimer then return end

    local ASTExtraPlayerController = import("/Script/ShadowTrackerExtra.STExtraPlayerController")
    local cachedMarks, cachedPawns, lastPawnRefresh = {}, {}, 0
    local cachedMarksTime = {}

    -- ============ HEALTHBAR ESP (0.8s timer) ============
    _G._AssistTimer = pc:AddGameTimer(0.8, true, function()
        if not _G.MOD_ESPEnabled then return end
        
        local uCon = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not (isValid(uCon) and Game:IsClassOf(uCon, ASTExtraPlayerController)) then return end
        local currentPawn = uCon:GetCurPawn()
        if not isValid(currentPawn) then return end
        
        local myTeamId, myPos = currentPawn.TeamID, currentPawn:K2_GetActorLocation()
        local HUD = uCon:GetHUD()
        local Canvas = isValid(HUD) and HUD.Canvas or nil
        local now = os.clock()

        if now - lastPawnRefresh > 1.0 then
            lastPawnRefresh = now
            cachedPawns = Game:GetAllPlayerPawns() or {}
            for pawnPtr, markId in pairs(cachedMarks) do
                local found = false
                for _, p in pairs(cachedPawns) do
                    if p == pawnPtr then found = true; break end
                end
                if not found then
                    if markId then InGameMarkTools.HideMapMark(markId) end
                    cachedMarks[pawnPtr] = nil
                    cachedMarksTime[pawnPtr] = nil
                end
            end
        end

        local VEC_Z85, VEC_Z90 = FVector(0, 0, 85), FVector(0, 0, 90)
        local COLOR_HP_GREEN = FLinearColor(0, 1, 0, 0.95)
        local COLOR_HP_YELLOW = FLinearColor(1, 1, 0, 0.95)
        local COLOR_HP_RED = FLinearColor(1, 0, 0, 0.95)
        local COLOR_BG = FLinearColor(0, 0, 0, 0.55)
        local MAX_DIST = 30000

        for _, tPawn in pairs(cachedPawns) do
            if isValid(tPawn) and tPawn ~= currentPawn and tPawn.TeamID ~= myTeamId then
                if IsPawnAlive(tPawn) then
                    local enemyPos = tPawn:K2_GetActorLocation()
                    if enemyPos then
                        local dx = enemyPos.X - myPos.X
                        local dy = enemyPos.Y - myPos.Y
                        local dz = enemyPos.Z - myPos.Z
                        local dist = math.sqrt(dx*dx + dy*dy + dz*dz)

                        if dist < MAX_DIST then
                            if tPawn.Replay_CreateEnemyFrameUI then tPawn:Replay_CreateEnemyFrameUI(true, true) end
                            SetRedFrameUI(tPawn)
                            if tPawn.Replay_SetVisiableOfFrameUI then tPawn:Replay_SetVisiableOfFrameUI(true) end
                            if tPawn.SetPlayerNameVisible then tPawn:SetPlayerNameVisible(true) end

                            local headPos, rootPos
                            if dist > 15000 then
                                headPos, rootPos = enemyPos + VEC_Z85, enemyPos - VEC_Z85
                            else
                                local realHead = tPawn:GetHeadLocation(false)
                                headPos = realHead or (enemyPos + VEC_Z85)
                                rootPos = realHead and (enemyPos - VEC_Z90) or (enemyPos - VEC_Z85)
                            end

                            cachedMarksTime[tPawn] = cachedMarksTime[tPawn] or 0
                            if now - (cachedMarksTime[tPawn] or 0) > 1.5 then
                                cachedMarksTime[tPawn] = now
                                if cachedMarks[tPawn] then
                                    InGameMarkTools.UpdateMapMarkLocation(cachedMarks[tPawn], headPos)
                                else
                                    cachedMarks[tPawn] = InGameMarkTools.ClientAddMapMark(1006, headPos, 0, "", 4, tPawn)
                                end
                            end

                            if Canvas then
                                local headScreen, rootScreen = FVector2D(0,0), FVector2D(0,0)
                                if uCon:ProjectWorldLocationToScreen(headPos, false, headScreen) and
                                   uCon:ProjectWorldLocationToScreen(rootPos, false, rootScreen) then
                                    local screenHeight = math.max(25, math.abs(headScreen.Y - rootScreen.Y))
                                    local scaleFactor = math.max(0.3, math.min(1.5, 15000 / math.max(10000, dist)))
                                    local barWidth, barHeight = 4 * scaleFactor, screenHeight * scaleFactor
                                    local barX, barY = headScreen.X - (barWidth * 1.5), headScreen.Y
                                    local hp = GetPawnHealthRatio(tPawn)
                                    local color = hp < 0.3 and COLOR_HP_RED or (hp < 0.6 and COLOR_HP_YELLOW or COLOR_HP_GREEN)
                                    Canvas:K2_DrawBox(FVector2D(barX, barY), FVector2D(barWidth, barHeight), 1, COLOR_BG)
                                    Canvas:K2_DrawBox(FVector2D(barX, barY + barHeight * (1 - hp)), FVector2D(barWidth, barHeight * hp), 1, color)
                                end
                            end
                        end
                    end
                else
                    if tPawn.Replay_SetVisiableOfFrameUI then tPawn:Replay_SetVisiableOfFrameUI(false) end
                    if cachedMarks[tPawn] then
                        InGameMarkTools.HideMapMark(cachedMarks[tPawn])
                        cachedMarks[tPawn] = nil
                        cachedMarksTime[tPawn] = nil
                    end
                end
            end
        end
    end)

    -- ============ WALLHACK TIMER ============
    _G._WallhackTimer = pc:AddGameTimer(0.25, true, function()
        if not _G.MOD_WallhackEnabled then
            if _G._WH_NeedCleanup then
                for pawn, _ in pairs(_WH_ModifiedPawns) do
                    if isValid(pawn) then ClearWallHackForPawn(pawn) end
                end
                _WH_OrigMaterials = setmetatable({}, { __mode = "k" })
                _WH_ModifiedPawns = setmetatable({}, { __mode = "k" })
                for base, orig in pairs(_WH_ModifiedBaseMaterials) do
                    pcall(function()
                        if isValid(base) then
                            base.bDisableDepthTest = orig.bDisableDepthTest
                            base.BlendMode = orig.BlendMode
                        end
                    end)
                end
                _WH_ModifiedBaseMaterials = setmetatable({}, { __mode = "k" })
                _G._WH_NeedCleanup = false
            end
            return
        end
        local uCon = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not (isValid(uCon) and Game:IsClassOf(uCon, ASTExtraPlayerController)) then return end
        local currentPawn = uCon:GetCurPawn()
        if not isValid(currentPawn) then return end
        local myTeamId, myPos = currentPawn.TeamID, currentPawn:K2_GetActorLocation()
        for _, tPawn in pairs(cachedPawns) do
            if isValid(tPawn) and tPawn ~= currentPawn and tPawn.TeamID ~= myTeamId and IsPawnAlive(tPawn) then
                local enemyPos = tPawn:K2_GetActorLocation()
                local dx = enemyPos.X - myPos.X
                local dy = enemyPos.Y - myPos.Y
                local dz = enemyPos.Z - myPos.Z
                if (dx*dx + dy*dy + dz*dz) < 900000000 then
                    pcall(ApplyWallHack, tPawn, uCon)
                end
            end
        end
    end)

    -- ============ MINIMAP ESP TIMER ============
    _G._MiniMapTimer = pc:AddGameTimer(1.0, true, function()
        if not _G.MOD_CustomMiniMapESP then
            for cacheKey, cacheData in pairs(_G.AK_Active_Marks_Cache) do
                pcall(function()
                    if InGameMarkTools and InGameMarkTools.ClientRemoveMapMark then
                        InGameMarkTools.ClientRemoveMapMark(cacheData.distMark)
                    end
                end)
                _G.AK_Active_Marks_Cache[cacheKey] = nil
            end
            return
        end
        local uCon = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not (isValid(uCon) and Game:IsClassOf(uCon, ASTExtraPlayerController)) then return end
        local localPlayer = GameplayData and GameplayData.GetPlayerCharacter()
        if not isValid(localPlayer) then return end
        local myTeamId = localPlayer.TeamID or 0
        local allPawns = Game:GetAllPlayerPawns() or {}
        for _, tPawn in pairs(allPawns) do
            if isValid(tPawn) and tPawn ~= localPlayer and tPawn.TeamID ~= myTeamId then
                processEnemyMapESP(tPawn, localPlayer)
            end
        end
        cleanupDeadEnemyMarks()
    end)

    -- ============ VEHICLE ESP TIMER ============
    _G._VehicleTimer = pc:AddGameTimer(0.35, true, function()
        if not _G.MOD_VehicleESP then return end
        pcall(VehicleESPLoop)
    end)
end

-- ==================== MATCH INITIALIZATION ====================
local function GokuMatchInit()
    if isModExpired() then
        ShowExpiryDialog()
        return
    end

    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not isValid(pc) then return end

    if _G._GokuModInitialized == pc then return end
    _G._GokuModInitialized = pc

    pcall(_G.ForceCleanupMatch)

    pc:AddGameTimer(1.0, false, function() _G.LoadAllFeatures() end)
    _G._AutoRAMCleaner = pc:AddGameTimer(30.0, true, AutoRAMCleaner)
    
    ApplyGokuBypasses()

    pcall(function()
        if pc.RPC_Client_SetShouldCheckPassWall then
            pc:RPC_Client_SetShouldCheckPassWall(false)
        elseif pc.ClientRPC_RPC_Client_SetShouldCheckPassWall then
            pc:ClientRPC_RPC_Client_SetShouldCheckPassWall(false)
        end
    end)

    InitVisualAssistance(pc)
    
    pc:AddGameTimer(3.0, true, ApplyEnvironment)
    pc:AddGameTimer(0.5, true, ApplyAimAssist)
    pc:AddGameTimer(0.5, true, ApplyNoRecoil)
    pc:AddGameTimer(0.2, true, ApplyiPadView)
    pc:AddGameTimer(1.0, true, ThermalGovernorLoop)

    pcall(InitDistanceMarkerSystem)
    if GameplayData then pcall(StartLocalPlayerUITimers) end
    pcall(StartAdvancedESPWatchdog)
    pcall(InjectModMenu)
    pcall(hookPerPlayerHiggs)
    
    if startPersistentTimer then pcall(startPersistentTimer) end
end

-- ==================== GLOBAL WATCHDOG ====================
if not _G._GokuWatchdogTimer then
    local fb = slua_GameFrontendHUD or Game
    if fb and isValid(fb) then
        _G._GokuWatchdogTimer = fb:AddGameTimer(1.0, true, function()
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            if isValid(pc) then
                GokuMatchInit()
            else
                if _G._GokuModInitialized then
                    pcall(_G.ForceCleanupMatch)
                    _G._GokuModInitialized = nil
                end
            end
        end)
    end
end
