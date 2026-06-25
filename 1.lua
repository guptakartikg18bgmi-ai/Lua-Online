-- ============================================================================
-- ✦ GOKU FRAMEWORK + PVT 18-LAYER BYPASS [MASTER BUILD - OPTIMIZED] ✦
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
Msg.Show(4, "✦ GOKU CORE FRAMEWORK ✦",
 "\n★ Developer : @GOKUCONFIG\n" ..
 "★ Status    : UNDETECTED & ACTIVE\n" ..
 "★ Bypass    : 18-LAYER SHIELD\n" ..
 "★ Engine    : HEURISTIC + ANTI-FLAG\n\n" ..
 "✓ Premium Build Loaded Successfully!",
onClick)
end
end)
end

-- ==================== SHARED HELPERS ====================
local require = require
local import = import
local isValid = slua.isValid
local function nop() return true end
local noop = nop
local function retFalse() return false end
local function retZero() return 0 end
local function retEmpty() return {} end
local function retTrue() return true end
local function retDummyHash() return "A3F8B9C2E1D40F5" end
local function safe_require(path) local ok, mod = pcall(require, path); return ok and mod or nil end
local ok_gd, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
if not ok_gd then GameplayData = nil end

local function KillTable(tbl, keys)
if not tbl then return end
for _, key in ipairs(keys) do
pcall(function()
if type(tbl[key]) == "function" then tbl[key] = function() return true, {} end
else tbl[key] = nil end
end)
end
end

-- ============================================================================
-- 🚀 PVT 18-LAYER BYPASS INJECTION START
-- ============================================================================
do
local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
if _G._MOD_LOADED and _G._MOD_PC == pc then return end
_G._MOD_LOADED = true
_G._MOD_PC = pc
end

if not _G.BYPASS_STATE then
_G.BYPASS_STATE = {
DEADEYE_DISABLED = false, HAWKEYE_DISABLED = false, VOKLAI_DISABLED = false,
HIGGSBOSON_DISABLED = false, HASH_VERIFY_DISABLED = false, IP_MAPPING_DISABLED = false,
MEMORY_PATCH_DISABLED = false, EDU_EYE_DISABLED = false, FULL_BYPASS_ACTIVE = false,
ANTI_CHEAT_MANAGER_DISABLED = false
}
end

pcall(function()
local stExtra = import("STExtraBlueprintFunctionLibrary")
if stExtra and stExtra.IsDevelopment then stExtra.IsDevelopment = nop end
if Client then Client.IsDevelopment = nop; Client.IsShipping = retFalse end
if Server then Server.IsShipping = retFalse end
local ToolReport = package.loaded["client.slua.logic.report.ToolReportUtil"]
if ToolReport then ToolReport.IsReleaseVersion = retFalse; ToolReport.IsWhite = retFalse; ToolReport.GetReportSwitch = retFalse end

local callbacks = _G.GameplayCallbacks or _G.GC
if callbacks then
local kills = {"SendTssSdkAntiDataToLobby", "SendDSErrorLogToLobby", "SendDSHawkEyePatrolLogToLobby", "SendSecTLog", "SendDataMiningTLog", "SendActivityTLog", "SendClientMemUsage", "SendClientFPS", "OnClientCrashReport", "OnNetworkLossDetected", "ReportMatchRoomData", "ReportPlayersPing", "SendClientStats", "SendServerAvgTickDelta", "ReportHitFlow", "OnPlayerActorChannelError", "OnPlayerRPCValidateFailed"}
for _, fn in ipairs(kills) do if callbacks[fn] then callbacks[fn] = nop end end
local origDS = callbacks.OnDSPlayerStateChanged
if origDS then
callbacks.OnDSPlayerStateChanged = function(dsSelf, state, reason, ...)
if tostring(reason):lower():find("cheatdetected") then return end
pcall(origDS, dsSelf, state, reason, ...)
end
end
end
if _G.TApmHelper then _G.TApmHelper.postEvent = nop end
local PC = _G.PacketCallbacks
if PC then PC.player_report_cheat = nop; PC.upload_loots_rsp = nop; PC.watch_player_exit = nop; PC.player_login_report = nop; PC.player_logout_report = nop; PC.server_time_report = nop end
local sdm = _G.ServerDataMgr
if sdm and sdm.DeletablePlayerResultKey then
sdm.DeletablePlayerResultKey["SuspiciousHitCount"] = true; sdm.DeletablePlayerResultKey["EspTotalSimTraceCnt"] = true
sdm.DeletablePlayerResultKey["EspTotalImeFocusCnt"] = true; sdm.DeletablePlayerResultKey["ClientGravityAnomalyCount"] = true
end
local pcNotify = package.loaded["GameLua.Mod.BaseMod.Common.Security.SecurityNotifyPCFeature"]
if pcNotify then pcNotify.ClientRPC_SyncBanID = nop; pcNotify.ClientRPC_StrongTips = nop; pcNotify.ClientRPC_NormalTips = nop; pcNotify.Notify = nop; pcNotify.ClientRPC_NotifyBan = nop; pcNotify.ClientRPC_NotifyPunish = nop; pcNotify.ClientRPC_NotifyIllegalProgram = nop end
local secUtils = package.loaded["GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils"]
if secUtils and secUtils.EStrategyTypeInReplay then secUtils.EStrategyTypeInReplay.EspTotalSimTraceCnt = 0; secUtils.EStrategyTypeInReplay.EspTotalImeFocusCnt = 0; secUtils.EStrategyTypeInReplay.ClientGravityAnomalyCount = 0; secUtils.EStrategyTypeInReplay.FlyingErrorCnt = 0 end
end)

pcall(function()
local Higgs = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
if Higgs then
local methods = {"ControlMHActive", "Tick", "OnTick", "MHActiveLogic", "TriggerAvatarCheck", "StartAvatarCheck", "ReportItemID", "ReceiveAnyDamage", "OnWeaponHitRecord", "ShowSecurityAlert", "ServerReportAvatar", "ClientReportNetAvatar", "SendHisarData", "ValidateSecurityData", "StaticShowSecurityAlertInDev"}
for _, m in ipairs(methods) do if Higgs[m] then Higgs[m] = nop end end
Higgs.GetNetAvatarItemIDs = retEmpty; Higgs.GetCurWeaponSkinID = retZero
end
if _G.DisableHiggsBoson then _G.DisableHiggsBoson = nop end
local hia = safe_require("GameLua.Mod.BaseMod.Client.Security.ClientGlueHiaSystem")
if hia then hia.CheckHitIntegrity = nop; hia.InitSession = nop; hia.OnBattleEnd = nop end
local Behavior = safe_require("GameLua.Mod.Escape.Gameplay.Subsystem.BehaviorScoreSubsystem")
if Behavior then Behavior.OnHandleBehaviorScore = nop; Behavior.AIPerceptionScore = nop; Behavior.ReportBehavior = nop; Behavior.CalcFinalScore = retZero end
end)

local higgs_bypass_attempts = 0
local MAX_HIGGS_BYPASS_ATTEMPTS = 60
local function bypass_higgs_boson_perplayer(player)
if not player or not isValid(player) then return end
if higgs_bypass_attempts >= MAX_HIGGS_BYPASS_ATTEMPTS then return end
pcall(function()
local Higgs = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
if Higgs then Higgs.ControlMHActive = nop; Higgs.TriggerAvatarCheck = nop; Higgs.StartAvatarCheck = nop; Higgs.ReportItemID = nop; Higgs.OnReportItemID = nop; Higgs.ReceiveAnyDamage = nop; Higgs.OnWeaponHitRecord = nop; Higgs.ShowSecurityAlert = nop; Higgs.ServerReportAvatar = nop; Higgs.ClientReportNetAvatar = nop; Higgs.GetNetAvatarItemIDs = retEmpty; Higgs.GetCurWeaponSkinID = retZero end
if _G.AvatarCheckCallback then _G.AvatarCheckCallback.StartAvatarCheck = nop; _G.AvatarCheckCallback.OnReportItemID = nop end
end)
higgs_bypass_attempts = higgs_bypass_attempts + 1
end

local function hookPerPlayerHiggs()
local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
if pc and isValid(pc) then local pawn = pc:GetCurPawn(); if isValid(pawn) then bypass_higgs_boson_perplayer(pawn) end end
end

pcall(function()
local BanLogic = package.loaded["client.slua.logic.ban.ClientBanLogic"]
if BanLogic then BanLogic.OnSyncBanInfo = nop; BanLogic.OnVoiceBanNotify = nop; BanLogic.OnRealTimeVoiceBanNotify = nop; BanLogic.OnVoiceBanSuccess = nop; BanLogic.OnSyncMicSuspicious = nop; BanLogic.OnSyncMicPreFilter = nop; BanLogic.OnNotifyWarningTips = nop; BanLogic.ReqBanInfo = nop end
local BanUtil = package.loaded["client.common.ban_util"] or _G.ban_util
if BanUtil then BanUtil.CheckBanStatus = retFalse; BanUtil.GetBanTime = retZero; BanUtil.IsBanForever = retFalse end
local TTBan = package.loaded["client.logic.login.logic_tt_ban"] or _G.logic_tt_ban
if TTBan then TTBan.CheckIfCanCreateRole = nop; TTBan.GetCarrierInfo = function() return '[{"mcc":"000"}]' end end
local GodzillaBan = package.loaded["client.network.Protocol.GodzillaBanHandler"]
if GodzillaBan then GodzillaBan.send_godzilla_ban_req = nop; GodzillaBan.send_godzilla_unban_req = nop end
local AntiAddiction = package.loaded["client.network.Protocol.AntiaddctionHandler"]
if AntiAddiction then AntiAddiction.send_anti_addiction_req = nop; AntiAddiction.send_anti_addiction_notify = nop end
local AccessRestrict = package.loaded["client.network.Protocol.AccessRestrictionHandler"]
if AccessRestrict then AccessRestrict.send_access_restriction_req = nop; AccessRestrict.send_access_restriction_notify = nop; AccessRestrict.on_player_cheat_state_notify = nop end
local DeleteAccount = package.loaded["client.slua.logic.gdpr.logic_deleteaccount"]
if DeleteAccount then DeleteAccount.ForceDeleteAccount = retFalse; DeleteAccount.OnReceiveDeleteNotify = nop end
local ComplianceUtil = package.loaded["client.slua.logic.gdpr.compliance_util"]
if ComplianceUtil then ComplianceUtil.CheckCompliance = nop end
end)

pcall(function()
local clientReport = package.loaded["GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem"]
if clientReport then local funcs = {"OnInit", "_OnPlayerKilledOtherPlayer", "_RecordFatalDamager", "SendPacket", "ReportSuspiciousPlayer", "SubmitReport", "_OnBattleResult", "_RecordTeammatePlayerInfo", "_OnDeathReplayDataWhenFatalDamaged", "_RecordMurdererFromDeathReplayData"}; for _, fn in ipairs(funcs) do if clientReport[fn] then clientReport[fn] = nop end end end
local dsReport = package.loaded["GameLua.Mod.BaseMod.Common.Security.DSReportPlayerSubsystem"]
if dsReport then local funcs = {"_OnNearDeathOrRescued", "_OnPlayerSettlementStart", "_OnTeammateDamage", "_OnCharacterDied", "_AddEnemyMapToBattleResult", "_AddTeammateMapToBattleResult", "_SubmitAbnormalData"}; for _, fn in ipairs(funcs) do if dsReport[fn] then dsReport[fn] = nop end end end
local reportUtils = package.loaded["GameLua.Mod.BaseMod.Common.Security.ReportPlayerUtils"]
if reportUtils then reportUtils.GetBotType = retZero; reportUtils.IsCharacterDeliverAI = retFalse end
local AvatarSub = package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionSubsystem"]
if AvatarSub then AvatarSub.OnClickReportCheckAvatar = nop; AvatarSub.RegisterTickCheckCharacterAvatar = nop end
if _G.AvatarExceptionPlayerInst then _G.AvatarExceptionPlayerInst.ReportAvatarException = nop; _G.AvatarExceptionPlayerInst.CheckAvatarException = nop; _G.AvatarExceptionPlayerInst.CheckCanBugglyPostException = nop end
local SubsystemMgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
if SubsystemMgr then local hawk = SubsystemMgr:Get("DSHawkEyePatrolSubsystem"); if hawk then hawk.MarkSuspiciousPlayer = nop end end
if _G.DSHawkEyePatrolSubsystem then _G.DSHawkEyePatrolSubsystem._OnHawkReport = nop; _G.DSHawkEyePatrolSubsystem._OnHawkImprison = nop; _G.DSHawkEyePatrolSubsystem.CheckPunishPlayer = nop end
local ClientHawk = package.loaded["GameLua.Mod.BaseMod.Client.Security.ClientHawkEyePatrolSubsystem"]
if ClientHawk then local funcs = {"_OnHawkSync", "_OnHawkReportSuccess", "_StartExitGameTimer", "_OnRecvInspectorBroadcastCount", "SendReportTLog", "ReportCheat"}; for _, fn in ipairs(funcs) do if ClientHawk[fn] then ClientHawk[fn] = nop end end; ClientHawk.CanInspectorBroadcast = retFalse end
local InspectClient = package.loaded["GameLua.Mod.BaseMod.Client.Security.InspectionSystemReportClientLogicSubsystem"]
if InspectClient then local funcs = {"AskForInspector", "ReportEnemy", "KickOutOneTeam", "OnReceiveInspectCmd", "ClientReportData", "SendReportToInspector", "SendKickOutOneTeam", "ClientNotifyInspectorImplementation", "RecvNotifyInspector"}; for _, fn in ipairs(funcs) do if InspectClient[fn] then InspectClient[fn] = nop end end end
local InspectDS = package.loaded["GameLua.Mod.BaseMod.DS.Security.InspectionSystemReportDSLogicSubsystem"]
if InspectDS then local funcs = {"ServerKickOutOneTeamByPlayerImplementation", "AddReportedCount", "AddInspectionRecord", "BanPlayerByInspection", "BroadCastToAllInspector", "ServerReportToInspectorImplementation", "InitPlayerInspectionInfo"}; for _, fn in ipairs(funcs) do if InspectDS[fn] then InspectDS[fn] = nop end end end
end)

pcall(function()
local tlogModules = {"client.network.Protocol.ClientTlogHandler", "client.network.Protocol.BattleReportHandler", "client.network.Protocol.ClientErrorReportHandler", "client.network.Protocol.LobbyPingReportHandler", "client.slua.config.tlog.tlog_report_utils", "client.slua.data.BasicData.BasicDataTLogReport", "client.slua.data.BasicData.BasicDataClientReport", "client.slua.data.BasicData.BasicDataReport", "GameLua.Mod.BaseMod.DS.Security.DSCommonTLogSubsystem", "GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem", "GameLua.Mod.BaseMod.DS.Security.DSSecurityTLogSubsystem", "GameLua.Mod.BaseMod.Client.Security.ClientDataStatistcsSubsystem"}
for _, path in ipairs(tlogModules) do local mod = package.loaded[path]; if mod then for k, v in pairs(mod) do if type(v) == "function" and (k:find("Log") or k:find("Report") or k:find("Send") or k:find("Tlog")) then pcall(function() mod[k] = nop end) end end end end
local AmphibiousBoat = safe_require("GameLua.GameCore.Module.Vehicle.VehicleFeatures.TLog.AmphibiousBoatTLogFeature")
if AmphibiousBoat then AmphibiousBoat.RecordMovement = nop; AmphibiousBoat.StartRecordMovement = nop end
local ICTLog = safe_require("GameLua.Mod.BaseMod.DS.Security.ICTLogSubsystem")
if ICTLog then ICTLog.SendICExceptionTLog = nop end
local DSFight = safe_require("GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem")
if DSFight then DSFight.GetSimpleFightData = retEmpty; DSFight.ReportFightData = nop; DSFight.ReportPlayerWeapon = nop end
local DSSec = safe_require("GameLua.Mod.BaseMod.DS.Security.DSSecurityTLogSubsystem")
if DSSec then DSSec._OnReportServerJumpFlow = nop; DSSec._OnReportTeleportFlow = nop; DSSec._OnReportSpeedHackFlow = nop end
local DSCommon = safe_require("GameLua.Mod.BaseMod.DS.Security.DSCommonTLogSubsystem")
if DSCommon then DSCommon.HandleKillTlog = nop end
local PufferTlog = package.loaded["client.slua.logic.download.report.puffer_tlog"]
if PufferTlog then PufferTlog.report_download_tlog = nop end
end)

pcall(function()
local ClientError = package.loaded["client.network.Protocol.ClientErrorReportHandler"]
if ClientError then ClientError.send_client_error_report = nop; ClientError.send_client_crash_report = nop; ClientError.send_client_tools_batch_report_req = nop end
local BattleReport = package.loaded["client.network.Protocol.BattleReportHandler"]
if BattleReport then BattleReport.send_battle_report = nop; BattleReport.send_battle_result = nop; BattleReport.send_vod_game_report_req = nop; BattleReport.send_batch_get_vod_info_req = nop; BattleReport.send_get_game_report_req = nop; BattleReport.send_batch_get_game_report_req = nop; BattleReport.send_get_game_report_by_uid_req = nop end
local BugHandler = package.loaded["client.network.Protocol.BugHandler"]
if BugHandler then BugHandler.send_report_bug_info = nop; BugHandler.send_report_bug_feedback = nop end
local PingReport = package.loaded["client.network.Protocol.LobbyPingReportHandler"]
if PingReport then PingReport.send_lobby_ping_report = nop; PingReport.send_ingame_ping_report = nop end
local WeekReport = package.loaded["client.network.Protocol.WeekRportHandler"]
if WeekReport then WeekReport.send_week_report = nop; WeekReport.send_week_detail = nop end
local LogicComplaint = package.loaded["client.logic.battle.logic_complaint"]
if LogicComplaint then LogicComplaint.SendComplaintReq = nop; LogicComplaint.Submit = nop; LogicComplaint.ReportPlayer = nop; LogicComplaint.ShowComplaint = nop; LogicComplaint.ShowHandle = nop end
local OBResult = package.loaded["GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.EscapeBattleResultShowOBResultLogic"]
if OBResult then OBResult.OnBattleResult = nop; OBResult.OnResultProcessStart = nop end
local NormalOBResult = package.loaded["GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.BattleResultShowOBResultLogic"]
if NormalOBResult then NormalOBResult.OnBattleResult = nop; NormalOBResult.OnResultProcessStart = nop end
local ShowResult = package.loaded["GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.BattleResultShowResultLogic"]
if ShowResult then ShowResult.OnBattleResult = nop; ShowResult.OnResultProcessStart = nop; ShowResult.OnResultProcessContinue = nop; ShowResult.ReceiveData = nop; ShowResult.SendEndFlow = nop; ShowResult.OnReport = nop; ShowResult.ShowResult = nop; ShowResult.ShowResultInternal = nop; ShowResult.StopResultProcess = nop end
end)

pcall(function()
local EmuHandler = package.loaded["client.network.Protocol.EmulatorHandler"]
if EmuHandler then EmuHandler.send_emulator_info = nop end
local EmuScanner = package.loaded["client.logic.login.emulator_scanner"]
if EmuScanner then EmuScanner.StartScan = nop; EmuScanner.GetScanResult = retFalse; EmuScanner.ReportScanResult = nop end
local LoginVerify = package.loaded["client.network.Protocol.LoginVerifyHandler"]
if LoginVerify then LoginVerify.send_login_verify_req = nop; LoginVerify.send_device_verify_req = nop end
local DSMonitor = package.loaded["client.logic.data.logic_ds_monitor"]
if DSMonitor then DSMonitor.OnRecordMsg = nop; DSMonitor.OnReportMsg = nop end
local ClientDataStat = package.loaded["GameLua.Mod.BaseMod.Client.Security.ClientDataStatistcsSubsystem"]
if ClientDataStat then ClientDataStat.StartToCheck = nop; ClientDataStat.OnReceiveRTT = nop; ClientDataStat.OnReceiveJitter = nop; ClientDataStat.ReportAbnormal = nop; ClientDataStat.ResetData = nop end
local shootVerify = safe_require("GameLua.Dev.Subsystem.ShootVerifySubSystemClient")
if shootVerify then shootVerify.OnShootVerifyFailed = nop; shootVerify.SendVerifyData = nop end
local HighlightDS = safe_require("GameLua.Mod.BaseMod.DS.Security.HighlightMomentSubsystem_DSChecker")
if HighlightDS then HighlightDS.CheckFuncUpgradedWeaponKill = nop end
end)

pcall(function()
local ProfileReport = package.loaded["client.logic.data.profile_report_cfg"]
if ProfileReport then ProfileReport.SendReport = nop end
local VoiceReport = package.loaded["client.slua.logic.chat_voice.logic_chat_voice_report"]
if VoiceReport then VoiceReport.ReportVoiceData = nop; VoiceReport.ReportVoiceText = nop end
local VoiceDoctor = package.loaded["client.slua.logic.chat_voice.logic_chat_voice_doctor"]
if VoiceDoctor then VoiceDoctor.UploadVoiceLog = nop; VoiceDoctor.UploadVoiceException = nop end
local HomeAudit = package.loaded["client.slua.logic.home.Audit.logic_home_audit_state"]
if HomeAudit then HomeAudit.SendAuditState = nop; HomeAudit.ReportAuditResult = nop end
local HomeReport = package.loaded["client.slua.logic.home.logic_home_report"]
if HomeReport then HomeReport.ReportHomeData = nop; HomeReport.ReportHomeVisitor = nop end
local GemReport = package.loaded["client.logic.store.gem_report_utils"]
if GemReport then GemReport.ReportGemData = nop; GemReport.ReportGemPurchase = nop end
local SafeStation = package.loaded["client.slua.logic.CustomerService.LogicSafeStation"]
if SafeStation then SafeStation.UploadVideoEvidence = nop; SafeStation.ReportPlayerBehavior = nop end
local CustomerService = package.loaded["client.slua.logic.CustomerService.LogicCustomerService"]
if CustomerService then CustomerService.SendComplaint = nop; CustomerService.SendFeedback = nop end
end)

pcall(function()
local znq6Revive = safe_require("GameLua.Mod.TDEvent.ZNQ6th.DS.ZNQ6thDSReviveSubsystem")
if znq6Revive then znq6Revive.HaveNewItemForRevive = nop end
local znq7Revive = safe_require("GameLua.Mod.TDEvent.ZNQ7th.DS.ZNQ7DSReviveSubsystem")
if znq7Revive then znq7Revive.HaveChanceRevival = nop end
local DataLayer = safe_require("GameLua.Mod.BaseMod.Common.Subsystem.DataLayerSubsystem")
if DataLayer then local orig = DataLayer.OnSpectatorReplayChanged; if orig then DataLayer.OnSpectatorReplayChanged = function(dlSelf) _G.IsBeingWatched = true; orig(dlSelf) end end end
local DSActive = safe_require("GameLua.Mod.PlanBT.Gameplay.Subsystem.DSActiveSubsystem")
if DSActive then DSActive.DelayKickOutPlayer = nop; DSActive.ActiveKickNotify = nop end
local CreativeDev = safe_require("GameLua.Mod.CreativeBase.Gameplay.Subsystem.CreativeDevDebugSubsystem")
if CreativeDev then CreativeDev.IsDebugPanelEnalbedCli = nop end
local CreativeDeath = safe_require("GameLua.Mod.CreativeBase.Gameplay.Subsystem.CreativeModeDeathRecordSubsystem")
if CreativeDeath then CreativeDeath.OnPlayerKilled = nop end
if _G.ClientReplayDataReporter then _G.ClientReplayDataReporter.ReportIntArrayData = nop; _G.ClientReplayDataReporter.ReportFloatArrayData = nop end
local SpectateReplay = safe_require("GameLua.Mod.BaseMod.Common.Subsystem.SpectateAndReplaySubsystem")
if SpectateReplay then SpectateReplay.RequestGotoSpectatingImp = nop; SpectateReplay.RequestGotoSpectating = nop end
local AIReplay = safe_require("GameLua.ExtraModule.MLAI.Client.AIReplaySubsystem")
if AIReplay then AIReplay.ReportAllPlayerInfo = nop; AIReplay.ReportFrameData = nop; AIReplay.ReportPlayerInput = nop; if AIReplay.uCompletePlayBack then AIReplay.uCompletePlayBack.AddRecordMLAIInfo = nop; AIReplay.uCompletePlayBack.StopRecording = nop end end
local AITracking = safe_require("GameLua.Mod.BaseMod.GamePlay.AI.AITrackingLogSubsystem")
if AITracking then AITracking.RealLogoutTimer = nop; AITracking.LogQueue = {}; AITracking.AddToLogQue = nop; AITracking.DoPrint = nop; AITracking.OnAIPawnDied = nop; AITracking.OnAIPawnReceiveDamage = nop; AITracking.OnAIPawnEnemyChange = nop end
local AFKReport = safe_require("GameLua.Mod.BaseMod.DS.Security.AFKReportorSubsystem")
if AFKReport then AFKReport.HandleEnterFighting = nop; AFKReport.InitializePlayerInputInfo = nop; AFKReport.AddOneAFKInfo = nop; AFKReport.SetPlayerAFKState = nop; AFKReport.ResetPlayerInputInfo = nop; AFKReport.PlayerHaveAction = nop end
local TDMAFK = safe_require("GameLua.Mod.TDM.Gameplay.Subsystem.TDMAFKReportorSubsystem")
if TDMAFK then TDMAFK.SendAFKTips = nop; TDMAFK.OnHandleLostConnection = nop end
local DataMgr = package.loaded["client.slua.logic.data.data_mgr"]
if DataMgr then DataMgr.GetWeaponSkinSoundVolumeInfoByGroup = retZero end
local CreditLogic = safe_require("GameLua.Mod.BaseMod.Client.ClientInGameCreditLogic")
if CreditLogic then CreditLogic._SendUserReaction2ExitTeamBeforeBoardingReturnLobbyNotice = nop; CreditLogic.ShowReturnLobbyIfFirstExitTeamBeforeBoarding = retFalse; CreditLogic.OnReceiveCreditScoreChange = nop; CreditLogic._IsFirstExitTeamBeforeBoardingReturnLobbyNoticeEnabled = retFalse; CreditLogic.SetFirstExitTeamBeforeBoardingReturnLobbyNoticeEnabled = nop end
end)

local globalFuncs = {"ReportTLogEvent", "SendTlog", "SendClientStats", "ReportHitFlow", "ReportAvatarException", "SendComplaintReq", "SubmitReport", "ReportSuspiciousPlayer", "SendPacket", "OnSyncBanInfo", "OnVoiceBanNotify", "SendSecTLog", "MarkSuspiciousPlayer", "ReportPlayerBehaviorData", "CheckCompliance", "ReportIllegalProgram", "UploadVoiceLog"}
for _, fn in ipairs(globalFuncs) do if type(_G[fn]) == "function" then _G[fn] = nop end end

local BLACKLIST_HOSTS = {"tss.tencent", "syzsdk", "gcloud.qq", "reportlog", "tdos", "logupload", "feedback.wh", "crash2", "privacy.qq", "privacy.tencent", "oth.eve", "mdt.qq", "act.tencentyun", "analytics", "report.qq", "anticheatexpert", "crashsight", "wetest", "log.tav", "sngd", "tracer", "intlsdk", "igamecj", "cdn.club", "gpubgm", "graph.facebook", "calendarpushsubscription", "googleads", "doubleclick", "firebaselogging", "firebaseremoteconfig", "fonts.googleapis", "abs.twimg", "dl.listdl", "igame.gcloudcs", "bugly", "beacon", "helpshift", "tdm", "apm", "safeguard", "weiyun", "qzone", "tencent-cloud", "myapp", "idqqimg", "gtimg", "qqmail", "tcdn", "cloudctrl", "sdkostrace", "103.134.189.146", "mbgame", "csoversea", "igame", "pubgmobile", "down.anticheatexpert.com", "asia.csoversea.mbgame.anticheatexpert.com", "log.tav.qq", "syzsdk.qq", "logiservice.qcloud", "opensdk.tencent", "exp.helpshift", "loginsdkapi.zingplay", "firebase", "googleapis", "facebook", "gvoice"}
local BLACKLIST_PORTS = {"10334", "11045", "12221", "13331", "8011", "8015", "9001", "20000", "20001", "20002", "20003", "20004", "20005", "19700", "1670", "19900", "14545", "10213", "8700", "25177", "10685", "10336", "10262", "27000", "27040", "27015", "27030", "10706", "10095", "12401", "11008", "10309", "11075", "10157", "24798", "10709", "6667", "10087", "31113", "20371", "10120", "10664", "13728", "10769", "10761", "5061", "5062", "18081", "15692", "9030", "8080", "8086", "8088"}
local FILE_KEYWORDS = {"tlog", "crash", "bugly", "report", "beacon", "wetest", "analytics", "telemetry", "trace", "dump", "exception", "feedback", "aps_log", "mtp_detect", "network_loss", "client_error", "ue4crash", "tdm", "gcloud"}

local function isBlacklisted(str)
if type(str) ~= "string" then return false end
local low = str:lower()
for _, kw in ipairs(BLACKLIST_HOSTS) do if low:find(kw,1,true) then return true end end
for _, port in ipairs(BLACKLIST_PORTS) do if low:find(":"..port) or low:find("/"..port) then return true end end
return false
end

pcall(function()
if _G.HttpRequest then local orig = _G.HttpRequest; _G.HttpRequest = function(url, ...) if isBlacklisted(url) then return nil end return orig(url, ...) end end
if _G.FHttpModule and _G.FHttpModule.CreateRequest then local orig = _G.FHttpModule.CreateRequest; _G.FHttpModule.CreateRequest = function(...) local url = select(1,...); if isBlacklisted(url) then return nil end return orig(...) end end
local netMods = {"client.slua.logic.network.logic_network", "client.slua.logic.download.report.puffer_tlog", "client.slua.data.BasicData.BasicDataClientReport", "GameLua.GameCore.Module.Network.NetworkManager", "client.network.Protocol.ClientTlogHandler", "client.network.Protocol.BattleReportHandler", "client.network.Protocol.ClientErrorReportHandler"}
for _, mp in ipairs(netMods) do local mod = package.loaded[mp]; if mod then for k, v in pairs(mod) do if type(v) == "function" and (k:find("Http") or k:find("Request") or k:find("Send") or k:find("Upload") or k:find("Post") or k:find("Get") or k:find("Report")) then local origf = v; mod[k] = function(...) local args = {...}; for _, arg in ipairs(args) do if type(arg)=="string" and isBlacklisted(arg) then return nil end end return pcall(origf, ...) end end end end end
end)

local orig_io_open = io.open
io.open = function(path, mode)
if type(path) == "string" then
local lp = path:lower()
for _, kw in ipairs(FILE_KEYWORDS) do if lp:find(kw) then if mode and (mode == "w" or mode == "a" or mode == "w+" or mode == "a+") then return nil, "Blocked" end end end
if lp:find("tdm") or lp:find("gcloud") or lp:find("beacon") then if mode and (mode == "w" or mode == "a" or mode == "w+") then return nil end end
end
return orig_io_open(path, mode)
end
if _G.UnrealEngine and _G.UnrealEngine.CrashContext then _G.UnrealEngine.CrashContext = nil; _G.UnrealEngine.CrashContext = { SetCrashContext = nop, ReportCrash = nop, AddCrashData = nop } end

local function TssSdkBypass()
pcall(function()
local TssSdk = _G.TssSdk or package.loaded["TssSdk"] or package.loaded["client.slua.logic.tss_sdk"]
if not TssSdk then local ok, mod = pcall(require, "TssSdk"); if ok then TssSdk = mod end end
if not TssSdk then for k, v in pairs(_G) do if type(v) == "table" and (k:find("Tss") or k:find("Sdk") or k:find("Anti") or k:find("ACE")) then if v.GetSdkAntiData or v.RegistSdkEventListener or v.IsEmulator then TssSdk = v; break end end end end
if not TssSdk then return end
local keepFuncs = {["RegistSdkEventListener"]=true, ["IsAppOnForeground"]=true, ["GenSessionData"]=true, ["WaitVerify"]=true, ["QueryTssSdkVer"]=true, ["CommQuery"]=true, ["OpenWBSession"]=true, ["SendWBCmd"]=true, ["ReleaseWBStrPool"]=true, ["CloseWBSession"]=true, ["Logout"]=true}
for funcName, funcValue in pairs(TssSdk) do
if type(funcValue) == "function" and not keepFuncs[funcName] then
if funcName:find("Tss") or funcName:find("Sdk") or funcName:find("Anti") or funcName:find("Screenshot") or funcName:find("Emulator") or funcName:find("Token") or funcName:find("Session") or funcName:find("Verify") or funcName:find("Query") or funcName:find("Set") or funcName:find("Get") or funcName:find("Push") or funcName:find("Send") or funcName:find("Report") or funcName:find("Data") or funcName:find("Mrpcs") or funcName:find("Libc") or funcName:find("Channel") or funcName:find("Hook") or funcName:find("Thread") or funcName:find("Touch") or funcName:find("Switch") or funcName:find("CDN") or funcName:find("License") or funcName:find("Ioctl") or funcName:find("Call") or funcName:find("Cmd") then
TssSdk[funcName] = function(...) return true, "BYPASSED" end
end
end
end
TssSdk.GetSdkAntiData = function(...) return true, "BYPASSED_ANTI_DATA_" .. os.time(), {code = 0, msg = "ok"} end
TssSdk.GameScreenshot = function(...) return nil, "SCREENSHOT_BLOCKED" end
TssSdk.GameScreenshot2 = function(...) return nil, "SCREENSHOT_BLOCKED" end
TssSdk.IsEmulator = function(...) return false end
TssSdk.QueryOpts = function(...) return {enabled = false, version = "0.0.0", status = "disabled"} end
TssSdk.GetCommLibValueByKey = function(key) return nil end
TssSdk.GetShellDyMagicCode = function(...) return "BYPASSED_MAGIC_" .. string.rep("0", 32) end
TssSdk.AddMTCJTask = function(...) return true end
TssSdk.SetToken = function(token) return true end
TssSdk["Enable DisableItem"] = function(item, enable) return true end
TssSdk.InvokeCrashFromShell = function(...) return false end
TssSdk.ReInitMrpcs = function(...) return true end
TssSdk.GetUserTag = function(...) return {level = 0, credit = 100, status = "clean"} end
TssSdk.QueryTssLibcAddr = function(...) return 0 end
TssSdk.RegistLibcSendListener = function(callback) return true end
TssSdk.RegistLibcRecvListener = function(callback) return true end
TssSdk.RegistLibcConnectListener = function(callback) return true end
TssSdk.RegistLibcCloseListener = function(callback) return true end
TssSdk.GetMrpcsData2Ptr = function(...) return 0 end
TssSdk.GetTPChannelVer = function(...) return "0.0.0" end
TssSdk.SetGameChannelIp = function(ip) return true end
TssSdk.SetValueByKey = function(key, value) return true end
TssSdk.SetChannelHost = function(host) return true end
TssSdk.SetChannelBuiltinIp = function(ip) return true end
TssSdk.RecvSecSignature = function(signature) return true end
TssSdk.PushAntiData3 = function(data) return true end
TssSdk.QueryRemainsAntiDataCount = function(...) return 0 end
TssSdk.GetAntiData3 = function(...) return nil end
TssSdk.DelAntiData3 = function(data) return true end
TssSdk.SetSecToken = function(token) return true end
TssSdk.GetThreadsInfo = function(...) return {} end
TssSdk.AddTouchEvent = function(event) return true end
TssSdk.InitSwitchStr = function(str) return true end
TssSdk.SetCDNHost = function(host) return true end
TssSdk.SetEnabledConnector = function(connector) return true end
TssSdk.QueryHookInfo = function(...) return {} end
TssSdk.SetCSLicense = function(license) return true end
TssSdk.AddAnoTouchEvent = function(event) return true end
TssSdk.GetObjVMFuncAddr = function(obj) return 0 end
if TssSdk.antiDataQueue then TssSdk.antiDataQueue = {}; TssSdk.antiDataQueue.push = function() end; TssSdk.antiDataQueue.pop = function() return nil end; TssSdk.antiDataQueue.size = function() return 0 end; TssSdk.antiDataQueue.clear = function() end end
local reportFuncs = {"ReportAntiData", "SendAntiData", "PushAntiData", "ReportData", "SendReport", "UploadData", "PushData", "ReportTLog", "SendTLog", "ReportSdkData", "SendSdkData"}
for _, funcName in ipairs(reportFuncs) do if TssSdk[funcName] then TssSdk[funcName] = function(...) return true end end end
TssSdk._BYPASSED = true; TssSdk._BYPASS_TIME = os.time(); TssSdk._KEPT_FUNCS = {"RegistSdkEventListener", "IsAppOnForeground", "GenSessionData", "WaitVerify", "QueryTssSdkVer", "CommQuery", "OpenWBSession", "SendWBCmd", "ReleaseWBStrPool", "CloseWBSession", "Logout"}
return true
end)
return false
end
pcall(function() TssSdkBypass() end)
-- [OPTIMIZED TIMER: 1.0s -> 1.5s]
pcall(function() local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController(); if slua.isValid(pc) and pc.AddGameTimer then pc:AddGameTimer(1.5, true, function() pcall(TssSdkBypass) end) end end)

local FakeData = {
ping = function() return math.random(20, 45) end,
deviceID = function() local chars = "0123456789ABCDEF"; local id = ""; for i = 1, 32 do id = id .. chars:sub(math.random(1, #chars), math.random(1, #chars)) end return id end,
ipAddress = function() return "192.168." .. math.random(1, 255) .. "." .. math.random(1, 255) end,
macAddress = function() return string.format("%02X:%02X:%02X:%02X:%02X:%02X", math.random(0,255), math.random(0,255), math.random(0,255), math.random(0,255), math.random(0,255), math.random(0,255)) end,
buildFingerprint = function() return "qcom/msmnile/msmnile:" .. math.random(10, 12) .. "/" .. math.random(100000, 999999) .. "/user/release-keys" end,
kernelVersion = function() return "4.19." .. math.random(100, 200) .. "-generic" end,
hashValue = function() return "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6" end
}

local function BypassDeadEye() if _G.BYPASS_STATE.DEADEYE_DISABLED then return end; pcall(function() if _G.GameplayCallbacks then KillTable(_G.GameplayCallbacks, {"ReportAimFlow", "ReportHitFlow", "ReportAttackFlow", "OnAimDetected", "OnHeadshotDetected", "OnPerfectAccuracy"}) end; local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"); if subsystems then local aimTracker = subsystems:Get("ClientAimTrackingSubsystem"); if aimTracker then aimTracker.GetAimData = function() return {accuracy = math.random(45, 65), headshotRate = math.random(15, 35)} end; aimTracker.IsAimNormal = function() return true end end end end); _G.BYPASS_STATE.DEADEYE_DISABLED = true end
local function BypassHawkEye() if _G.BYPASS_STATE.HAWKEYE_DISABLED then return end; pcall(function() local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"); if subsystems then local hawkEye = subsystems:Get("ClientHawkEyePatrolSubsystem"); if hawkEye then hawkEye.GetPatrolData = function() return {} end; hawkEye.IsBeingWatched = function() return false end; hawkEye.GetSpectatorCount = function() return 0 end end end; if _G.GameplayCallbacks then KillTable(_G.GameplayCallbacks, {"SendDSErrorLogToLobby", "SendDSHawkEyePatrolLogToLobby", "ReportMatchRoomData"}) end end); _G.BYPASS_STATE.HAWKEYE_DISABLED = true end
local function BypassVoklai() if _G.BYPASS_STATE.VOKLAI_DISABLED then return end; pcall(function() local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"); if subsystems then local aiBehavior = subsystems:Get("ClientAIBehaviourSubsystem"); if aiBehavior then aiBehavior.GetBehaviorScore = function() return math.random(10, 30) end; aiBehavior.IsSuspicious = function() return false end; aiBehavior.GetRiskLevel = function() return 0 end end; local stepCheck = subsystems:Get("ClientStepCheckSubsystem"); if stepCheck then stepCheck.GetStepDelta = function() return math.random(5, 50) end; stepCheck.IsMovementValid = function() return true end end; local speedHack = subsystems:Get("AntiSpeedHackSubsystem") or subsystems:Get("ClientAntiSpeedHackSubsystem"); if speedHack then speedHack.GetSpeed = function() return math.random(300, 600) end; speedHack.IsSpeedValid = function() return true end end end end); _G.BYPASS_STATE.VOKLAI_DISABLED = true end
local function BypassHiggsBoson() if _G.BYPASS_STATE.HIGGSBOSON_DISABLED then return end; pcall(function() local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController(); if isValid(pc) then if pc.HiggsBoson then pc.HiggsBoson.bMHActive = false; pc.HiggsBoson.bCallPreReplication = false end; if pc.HiggsBosonComponent then pc.HiggsBosonComponent.bMHActive = false; pc.HiggsBosonComponent:ControlMHActive(0) end end; local higgsComponent = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"); if higgsComponent then higgsComponent.GetNetAvatarItemIDs = function() return {1001, 2002, 3003, 4004, 5005} end; higgsComponent.GetCurWeaponSkinID = function() return 6001 end; higgsComponent.GetCurItemIDs = function() return {7001, 8002} end; if higgsComponent.BlackList then higgsComponent.BlackList = {} end end; _G.GlobalPlayerCoronaData = _G.GlobalPlayerCoronaData or {}; local mt = getmetatable(_G.GlobalPlayerCoronaData) or {}; mt.__newindex = function() end; setmetatable(_G.GlobalPlayerCoronaData, mt); _G.BlackList = {} end); _G.BYPASS_STATE.HIGGSBOSON_DISABLED = true end
local function BypassHashVerification() if _G.BYPASS_STATE.HASH_VERIFY_DISABLED then return end; pcall(function() if _G.TssSdk then _G.TssSdk.ScanMemory = function() return true, {code = 0, msg = "clean"} end; _G.TssSdk.ScanSo = function() return true, {code = 0, msg = "clean"} end; _G.TssSdk.ScanFile = function() return true, {code = 0} end; _G.TssSdk.GetRiskFlag = function() return 0 end; _G.TssSdk.VerifyFileHash = function() return true end end; local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"); if subsystems then local integrity = subsystems:Get("ClientIntegrityCheckSubsystem"); if integrity then KillTable(integrity, {"CheckFileHash", "VerifyMemory", "ScanModules"}) end end end); _G.BYPASS_STATE.HASH_VERIFY_DISABLED = true end
local function BypassIPMapping() if _G.BYPASS_STATE.IP_MAPPING_DISABLED then return end; pcall(function() if _G.GameplayCallbacks then KillTable(_G.GameplayCallbacks, {"SendClientDeviceInfo", "ReportDeviceFingerprint", "SendNetworkInfo", "ReportIPAddress", "SendMACAddress", "ReportHardwareID"}) end; local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"); if subsystems then local deviceInfo = subsystems:Get("ClientDeviceInfoSubsystem"); if deviceInfo then deviceInfo.GetDeviceID = function() return FakeData.deviceID() end; deviceInfo.GetIPAddress = function() return FakeData.ipAddress() end; deviceInfo.GetMACAddress = function() return FakeData.macAddress() end end end end); _G.BYPASS_STATE.IP_MAPPING_DISABLED = true end
local function BypassMemoryPatching() if _G.BYPASS_STATE.MEMORY_PATCH_DISABLED then return end; pcall(function() local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"); if subsystems then local kernelCheck = subsystems:Get("ClientKernelCheckSubsystem"); if kernelCheck then kernelCheck.IsKernelClean = function() return true end; kernelCheck.GetKernelVersion = function() return FakeData.kernelVersion() end; kernelCheck.IsBootloaderLocked = function() return true end end; local memoryGuard = subsystems:Get("ClientMemoryGuardSubsystem"); if memoryGuard then memoryGuard.IsMemoryClean = function() return true, {code = 0} end; memoryGuard.ScanResult = function() return "clean" end end end; if _G.TssSdk then _G.TssSdk.CheckKernel = function() return true, {status = "verified", tampered = false} end; _G.TssSdk.VerifyBoot = function() return true, {locked = true, verified = true} end end end); _G.BYPASS_STATE.MEMORY_PATCH_DISABLED = true end
local function BypassEduEye() if _G.BYPASS_STATE.EDU_EYE_DISABLED then return end; pcall(function() local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"); if subsystems then local renderCheck = subsystems:Get("ClientRenderCheckSubsystem"); if renderCheck then renderCheck.IsRenderClean = function() return true end; renderCheck.GetRenderState = function() return "normal" end end; local espDetection = subsystems:Get("ClientESPDetectionSubsystem"); if espDetection then espDetection.HasESP = function() return false end; espDetection.CheckOverlay = function() return "clean" end end; local wallhackDetect = subsystems:Get("ClientWallhackDetectionSubsystem"); if wallhackDetect then wallhackDetect.IsVisionNormal = function() return true end; wallhackDetect.GetVisibilityRate = function() return math.random(60, 85) end end end end); _G.BYPASS_STATE.EDU_EYE_DISABLED = true end

local function BypassAntiCheatManager()
if _G.BYPASS_STATE.ANTI_CHEAT_MANAGER_DISABLED then return end
pcall(function()
local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
if not slua.isValid(pc) then return end
local AntiCheatMgr = pc.PlayerAntiCheatManager or pc.AntiCheatManager or pc.PlayerACManager
if not slua.isValid(AntiCheatMgr) then pcall(function() local PlayerAntiCheatManagerClass = import("PlayerAntiCheatManager"); if PlayerAntiCheatManagerClass then local comps = pc:GetComponentsByClass(PlayerAntiCheatManagerClass); if comps and comps:Num() > 0 then AntiCheatMgr = comps:Get(0) end end end) end
if slua.isValid(AntiCheatMgr) then
AntiCheatMgr.AutoAimFailedCnt = 0; AntiCheatMgr.TrackingFailedCnt = 0; AntiCheatMgr.AreaDamageFailedCnt = 0; AntiCheatMgr.JumpHeightFailedCnt = 0; AntiCheatMgr.JumpFarFailedCnt = 0; AntiCheatMgr.VehicleFlyingFailedCnt = 0; AntiCheatMgr.ShootVerifyTimes = 0; AntiCheatMgr.SpeedUpValue = 0; AntiCheatMgr.ClientTimeTotalAcc = 0; AntiCheatMgr.ServerAccumulateErrors = 0; AntiCheatMgr.ServerAvgErrors = 0; AntiCheatMgr.ServerCorrectTimes = 0; AntiCheatMgr.PlayerBadPingTimes = 0; AntiCheatMgr.VehicleSpeedZDeltaTotal = 0; AntiCheatMgr.VehicleSpeedZDeltaOver10Times = 0; AntiCheatMgr.PVSInCityKillCount = 0; AntiCheatMgr.PVSNotInCityKillCount = 0; AntiCheatMgr.PVSCellHidePercent = 0; AntiCheatMgr.PVSTotalHidePercent = 0; AntiCheatMgr.ServerMoveParameterVerifyCount = 0; AntiCheatMgr.ServerMoveParameterVerifyFailedCount = 0; AntiCheatMgr.StuckGroundPunishCount = 0; AntiCheatMgr.TrialBaseDiffCount = 0; AntiCheatMgr.ContinueMoveBurstCount = 0; AntiCheatMgr.RecordContinueMoveBurstCount = 0; AntiCheatMgr.InclusiveBegin = 0; AntiCheatMgr.InclusiveEnd = 0
AntiCheatMgr.bReportFeedBack = false; AntiCheatMgr.bOpenDetailDataCollect = false; AntiCheatMgr.bOpenBaseDiffCheck = false; AntiCheatMgr.bUploadStuckGroundCount = false; AntiCheatMgr.bStuckGroundCapsule = false; AntiCheatMgr.bImpactOtherAfterBurst = false; AntiCheatMgr.bGiveupPickupWhenBrust = false; AntiCheatMgr.bOpenPickupWhenBrustCheck = false; AntiCheatMgr.bMustStrictContinue = false
AntiCheatMgr.MaxShootPointPassWall = 99999; AntiCheatMgr.MaxMuzzleHeightTime = 99999; AntiCheatMgr.MaxLocusFailTime = 99999; AntiCheatMgr.MaxBulletVictimClientPassWallTimes = 99999; AntiCheatMgr.MaxGunPosErrorTimes = 99999; AntiCheatMgr.MaxAllowVehicleTimeSpeedRawTime = 99999; AntiCheatMgr.MaxAllowVehicleTimeSpeedConvTime = 99999; AntiCheatMgr.MaxAllowVehicleAccTime = 99999; AntiCheatMgr.MaxSingleShotDamage = 99999; AntiCheatMgr.MaxFallingSustainTime = 99999; AntiCheatMgr.MaxCustomMoveModeSustainTime = 99999; AntiCheatMgr.MaxMoveDistance2DPerSecond = 99999; AntiCheatMgr.MaxCharMoveDist2DPerSecond = 99999; AntiCheatMgr.MaxDistanceToGround = 99999; AntiCheatMgr.MaxCatchWeaponAntiDataNLength = 0; AntiCheatMgr.MinBurstToPickupInterval = 0; AntiCheatMgr.MinImpactOtherInterval = 0; AntiCheatMgr.MinContinueMoveBurstXY = 0; AntiCheatMgr.MaxContinueMoveBurstXY = 99999; AntiCheatMgr.ContinueMoveBurstTolerant = 0; AntiCheatMgr.ContinueMoveBurstInterval = 99999; AntiCheatMgr.MaxPlayerDisSquaredForPickup = 0; AntiCheatMgr.BaseDiffRegion = 99999; AntiCheatMgr.BaseDiffVel = 99999; AntiCheatMgr.BaseDiffTime = 99999; AntiCheatMgr.ActorTimeDilation = 1.0; AntiCheatMgr.Werewolf2HumanTime = 0; AntiCheatMgr.StuckGroundPunishType = 0; AntiCheatMgr.StuckTypePunishSet = 0; AntiCheatMgr.MultiStuckGroundScale = 0
AntiCheatMgr.ParachuteStartTime = 0; AntiCheatMgr.ParachuteOpenTime = 0; AntiCheatMgr.ParachuteCloseTime = 0; AntiCheatMgr.ParachuteStartHight = 0; AntiCheatMgr.ParachuteOpenHight = 0; AntiCheatMgr.ParachuteCloseHight = 0
AntiCheatMgr.DSProperty = nil
local verifySwitchFields = {"VsNoHitDetail", "VsMuzzleRangeCircle", "VsMuzzleRangeUp", "VsHitBoneNameNone", "VsHitBoneHitMissMatch", "VsBulletID", "VsVehicleTimeStampError", "VsWatchTimeStampError", "VsShootRpgShootTimeVerify", "VsShootLockShootTimeVerify", "VsShootRpgHitNewVerify", "VsShootTimeConDelta", "VsServerNoOldShoot", "VsClientNotConnectShoot", "VsShootRpgShootIntervalVerify", "VsImpactPointAndBulletDisBig", "VsShootVerifyInvalid", "VsImpactActorPosWithNoHisPos", "VsShootAngleInVaild", "VsMuzzleAndTailPosInVaild", "VsMuzzleAndImpactPassWall", "VsMuzzleAndTailPassWall", "VsImpactActorPosOffsetBig", "VsImpactPointChangeSmall", "VsImpactBulletPosOffsetBig", "VsTotalImactCharacterNum", "VsBoneInfo", "VsJumpMaxHeight", "VsJumpMaxHeight15", "VsJumpMaxHeight2", "SpeedQuickCheck", "BulletDirError", "WalkSpeedFailedCnt", "SwitchMuzzleLocusError", "SwitchMuzzleLocusErrorX", "SwitchMuzzleLocusErrorY", "SwitchMuzzleLocusErrorZ", "Gun2ShooterPosError1", "SwitchHeadLocusError3", "SwitchMuzzleLocusErrorLength", "SwitchShootPosHistoryLocusError3", "SwitchHitComponentUnvalid", "SwitchHitNoRender", "SwitchHitOutCollisionBox", "HeadOverShootPos", "SwitchMuzzleImpactDirSkipPunish1", "SwitchInvalidBulletNumInBarrel", "SwitchShooterMovementError2", "GunTailPosError", "SwitchMuzzleImpactDirSkipPunish2", "SwitchMuzzleImpactDirError1", "SwitchMuzzleImpactDirError2", "ShooterHead2PosBlock", "SwitchShootPosHistoryLocusError2", "Head2GunTailPosError1", "SwitchShootDirExcepation1", "SwitchShootDirExcepation2", "SwitchCamerModeException", "SwitchShootPosHistoryLocusError4", "SwitchMuzzleImpactDirError3", "CharacterMoveException1", "CharacterMoveException2", "CharacterMoveException3", "CharacterMoveException4", "CharacterMoveException5", "CharacterMoveException6", "FarJump", "UndergroundCount", "DSSpeedOver10FailedCnt", "DSSpeedOver15FailedCnt", "DSSpeedOver20FailedCnt", "DSFallingSpeedFailCount", "DSFallingHeightFailCount", "MoveDistance2DPerSecondAnomaly", "CharMoveDist2DPerSecondAnomaly", "CharMoveDist2DPerSecondCount", "DistanceToGroundAnomaly", "SingleShotDamageAnomaly", "PlayerInstantHeightDiff", "Player2SecHeightDiff", "VerifySwitchCameraRotation", "VerifySwitchPeekShootThroughWall", "VerifySwitchCameraLocation", "VerifySwitchAutoAimByLockView", "VerifySwitchControlRotation", "VerifySwitchRecoilFaildCount", "VerifySwitchMarcoPolo", "VerifySwitchMarcoPolo2", "VerifySwitchMarcoPolo3", "VerifySwitchMeshScaleDiff", "VerifySwitchOfflineMove", "VerifySwitchFastAimShootHit", "VerifySwitchNoRecoilOnWeaponShoot", "VerifySwitchLessRecoilOnWeaponShoot", "VerifySwitchNoRecoilOnKickBack", "VerifySwitchLessRecoilOnKickBack", "VerifySwitchDivingBoost", "VerifySwitchRecoilCurveFailed", "PlayerQuickProne", "BaseDiffSample", "VsTeammateRescue", "VsTeammateRescueVictim", "VsTeammateRecall", "VsTeammateRecallVictim", "VsAutoClicker", "VsAbnormalShootingRotation", "VehicleSpeedZDeltaOver10TimesWhenNoXY", "VehicleVelZCheck1", "VehicleVelZCheck2", "VehicleMaxSpeedCheck", "VehicleHitMuzzleCheck", "VehicleHitImpactPointCheck", "VehicleHitBlockWall", "VehicleSidesway1", "VehicleSidesway2", "FarShootInMidAirVehicleExceedThreshold", "FarShootInMidAirVehicleEnemyDistanceTrial", "FarShootInMidAirVehicleEnemyDistanceFurtherTrial", "FarShootInMidAirVehicleHeightTrial", "FarShootInMidAirVehicleHeightFurtherTrial", "FarShootInMidAirPawnExceedThreshold", "FarShootInMidAirPawnEnemyDistanceTrial", "FarShootInMidAirPawnEnemyDistanceFurtherTrial", "FarShootInMidAirPawnHeightTrial", "FarShootInMidAirPawnHeightFurtherTrial", "DSRunning2DSpeedExceededCount", "DSRunning2DSpeedTrial", "DSRunning2DSpeedFurtherTrial", "DSIgnoreNetworkDying2DSpeedExceededCount", "DSDyingMoveSpeedExceedCount", "NonGunADSFarShootCount", "NonGunADSFarShootFromClientBulletDataCount", "NonGunADSFarShootFromClientBulletDataEnemyDistanceTrialCount", "NonGunADSFarShootFromClientBulletDataEnemyDistanceFurtherTrialCount", "ClientUploadFuzzyObjectVerifyFail", "ClientMoveTimeStampResetFrequencyExceedThreshold", "ShootBirdNonGunADSExceedThreshold", "ShootBirdNonGunADSDistanceTrial", "ShootBirdNonGunADSDistanceFurtherTrial", "FarShootInHighTangentMoveSpeedExceedThreshold", "FarShootInHighTangentMoveSpeedEnemyDistanceTrial", "FarShootInHighTangentMoveSpeedEnemyDistanceFurtherTrial", "FarShootInHighTangentMoveSpeedSpeedTrial", "FarShootInHighTangentMoveSpeedSpeedFurtherTrial", "IllegalTeamUpNearbyButNoFireAfterKill", "IllegalTeamUpNearbyButNoFireAfterKillDistanceTrial", "IllegalTeamUpNearbyButNoFireAfterKillTimeTrial", "IllegalTeamUpNearbyButNoFireAfterKillMaxTime", "IllegalTeamUpNearbyButNoFirePickUpItem", "IllegalTeamUpNearbyButNoFirePickUpItemDistanceTrial", "IllegalTeamUpNearbyButNoFirePickUpItemTimeTrial", "IllegalTeamUpNearbyButNoFirePickUpItemMaxTime", "IllegalTeamUpNearbyButNoFireNotKill", "IllegalTeamUpNearbyButNoFireNotKillDistanceTrial", "IllegalTeamUpNearbyButNoFireNotKillTimeTrial", "IllegalTeamUpNearbyButNoFireNotKillMaxTime", "IllegalTeamUpNearbyButNoFireOnVehicle", "IllegalTeamUpNearbyButNoFireOnVehicleDistanceTrial", "IllegalTeamUpNearbyButNoFireOnVehicleTimeTrial", "IllegalTeamUpNearbyButNoFireOnVehicleMaxTime", "IllegalTeamUpNearbyButNoFireSameVehicle", "IllegalTeamUpNearbyButNoFireSameVehicleTimeTrial", "IllegalTeamUpNearbyButNoFireSameVehicleMaxTime", "IllegalTeamUpUseObjectTogether", "IllegalTeamUpGetOnEnemyVehicleCount", "IllegalTeamUpNearbyButNoFireOneSideHasWeaponOnFoot", "IllegalTeamUpNearbyButNoFireOneSideHasWeaponOnFootDistanceTrial", "IllegalTeamUpStayOnEnemyVehicle", "KillBird", "ParachuteLandingSecondsExceedThreshold", "ParachuteObliqueLandingSecondsExceedThreshold", "ShootBird", "ShooterCapsuleCollided", "JumpReviewHighJumpExceed", "JumpReviewFarJumpExceed", "JumpReviewLowerFarJump", "SmallActorTimeDilationCount", "LargeRotateLockShooting", "SmallRotateLockShooting", "OneClipShootCount", "ClientWeaponFastReload", "DSCheckClientTimeMoveDistance2D", "DSCheckClientTimeMoveDistance2DTrial", "DSCheckClientTimeMoveDistance2DFurther", "DSCheckClientTimeMoveDistanceZ", "DSCheckClientTimeMoveDistanceZTrial", "DSCheckClientTimeMoveDistanceZFurther", "ReplayMaxFallingSustainTime", "ReplayMaxCustomMoveModeSustainTime", "ReplayMaxSingleShotDamage", "CharMoveAccumDist2D_DS", "CharMoveAccumDist3D_DS", "CharMoveAccumDist2D_Client", "CharMoveAccumDist3D_Client", "CharMoveAccumDist2D_ClientAll", "CharMoveAccumDist3D_ClientAll", "BandaCount", "MetroEnterRadiationTime", "MetroEnterRadiationTimeTrial", "MetroLeaveBornObstacle", "VsPetJumpHeightLimiter", "VsPetMoveSpeedLimiter", "VsBioVehicleMoveSpeedLimiter", "VsBioVehicleJumpHeightLimiter", "VsPterosaurFlyVehicleSpeed", "VsBioVehicleGravityLimiter", "ServerMoveCacheCountOver", "ServerMoveCacheCountOver3d", "ServerMoveBurst", "ImpactOtherAfterBurst", "KillOtherAfterBurst", "PickupAfterBurst", "ContinueMoveBurst", "ServerMoveTimeStamp", "ServerMoveAccel", "ServerMoveClientLoc", "ServerMoveCompressedMoveFlags", "ServerMoveClientRoll", "ServerMoveView", "ServerMoveClientMovementBase", "ServerMoveClientBaseBoneName", "ServerMoveClientMovementMode", "CheatStateData2TotalCheatTimes", "MoveCheatAntiStrategy3TotalCheatTimes", "ServerMoveCacheCountOver", "ServerMoveCacheCountOver3d", "ServerMoveBurst", "ClientTimeSpeedAcc", "ServerAccumulateErrorReplay"}
for _, fieldName in ipairs(verifySwitchFields) do pcall(function() local vs = AntiCheatMgr[fieldName]; if vs then vs.bActive = false; vs.MaxCount = 99999; vs.CurrentCount = 0; vs.TrialCount = 0; vs.TrialMaxCount = 99999; vs.PunishType = 0 end end) end
local burstFields = {"ServerAccumulateErrorBurst", "DSSpeedOver10BurstCount", "ParachuteSpeedBurst", "ClientTimestampBurst", "ClientTimestampBurstTrial"}
for _, fieldName in ipairs(burstFields) do pcall(function() local bvs = AntiCheatMgr[fieldName]; if bvs then bvs.bActive = false; bvs.MaxCount = 99999; bvs.CurrentCount = 0 end end) end
AntiCheatMgr.ReportAntiCheatDetailData = nop; AntiCheatMgr.PushWeaponAntiData = nop; AntiCheatMgr.OnRecoverOnServer = nop; AntiCheatMgr.OnPreReconnectOnServer = nop; AntiCheatMgr.GetSoftString = function() return 0 end; AntiCheatMgr.GetCheckMoveStr2 = function() return "" end; AntiCheatMgr.GetCheckMoveStr1 = function() return "" end; AntiCheatMgr.GetAACString = function() return "" end; AntiCheatMgr.GetAACCountByID = function() return 0 end; AntiCheatMgr.ExitParachute = nop; AntiCheatMgr.EnterParachute = nop; AntiCheatMgr.EnterJumping = nop; AntiCheatMgr.Cofey = function() return 0 end; AntiCheatMgr.Cofew = nop; AntiCheatMgr.SetTrialRegion = nop
end
end)
_G.BYPASS_STATE.ANTI_CHEAT_MANAGER_DISABLED = true
end

local function ApplyAllBypasses()
if _G.BYPASS_STATE.FULL_BYPASS_ACTIVE then return end
pcall(function()
BypassDeadEye(); BypassHawkEye(); BypassVoklai(); BypassHiggsBoson(); BypassHashVerification(); BypassIPMapping(); BypassMemoryPatching(); BypassEduEye(); BypassAntiCheatManager()
_G.BYPASS_STATE.FULL_BYPASS_ACTIVE = true
end)
end

pcall(function() ApplyAllBypasses() end)
-- [OPTIMIZED TIMER: 2.0s -> 3.0s]
pcall(function() local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController(); if pc and pc.AddGameTimer then pc:AddGameTimer(3.0, true, function() if not _G.BYPASS_STATE.FULL_BYPASS_ACTIVE then pcall(function() ApplyAllBypasses() end) end; _G.BYPASS_STATE.ANTI_CHEAT_MANAGER_DISABLED = false; pcall(BypassAntiCheatManager) end) end end)

local function huntAndKillAll()
pcall(function()
local subNames = {"ClientHawkEyePatrolSubsystem", "DSHawkEyePatrolSubsystem", "ClientReportPlayerSubsystem", "DSReportPlayerSubsystem", "ClientGlueHiaSystem", "ClientDataStatistcsSubsystem", "ICTLogSubsystem", "DSFightTLogSubsystem", "DSSecurityTLogSubsystem", "AFKReportorSubsystem", "BehaviorScoreSubsystem"}
local subMgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
if subMgr and subMgr.Get then for _, name in ipairs(subNames) do local sub = subMgr:Get(name); if sub then for k, v in pairs(sub) do if type(v) == "function" and (k:find("Report") or k:find("Send") or k:find("Tick") or k:find("Log")) then pcall(function() sub[k] = nop end) end end end end end
local tlogPaths = {"client.slua.config.tlog.tlog_report_utils", "client.network.Protocol.ClientTlogHandler", "GameLua.Mod.BaseMod.DS.Security.DSCommonTLogSubsystem"}
for _, path in ipairs(tlogPaths) do local mod = package.loaded[path]; if mod then for k, v in pairs(mod) do if type(v) == "function" and (k:find("Report") or k:find("Send") or k:find("Log")) then pcall(function() mod[k] = nop end) end end end end
local Higgs = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
if Higgs then local methods = {"ControlMHActive", "Tick", "OnTick", "MHActiveLogic", "TriggerAvatarCheck", "StartAvatarCheck", "ReportItemID", "ReceiveAnyDamage", "OnWeaponHitRecord", "ShowSecurityAlert", "ServerReportAvatar", "ClientReportNetAvatar", "SendHisarData", "ValidateSecurityData"}; for _, m in ipairs(methods) do if Higgs[m] then Higgs[m] = nop end end; Higgs.GetNetAvatarItemIDs = retEmpty; Higgs.GetCurWeaponSkinID = retZero end
_G.BYPASS_STATE.ANTI_CHEAT_MANAGER_DISABLED = false; pcall(BypassAntiCheatManager)
end)
end

local function startPersistentTimer()
local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
-- [OPTIMIZED TIMER: 3.0s -> 5.0s]
if pc and isValid(pc) then if _G._permHuntTimer then pcall(function() pc:RemoveGameTimer(_G._permHuntTimer) end) end; _G._permHuntTimer = pc:AddGameTimer(5.0, true, huntAndKillAll); return true end
return false
end

pcall(function()
_G.InitializeLogBlocker = function() pcall(function() local s = import("ScreenshotMaker"); if s then s.MakePicture = nop; s.ReMakePicture = nop; s.HasCaptured = retTrue end; local tl = package.loaded["TLog"] or _G.TLog; if tl then tl.Info = nop; tl.Warning = nop; tl.Error = nop; tl.Debug = nop; tl.Report = nop end; local cs = package.loaded["CrashSight"] or _G.CrashSight; if cs then cs.ReportException = nop; cs.SetCustomData = nop; cs.Log = nop end end) end
_G.InitializeScannerBlocker = function() pcall(function() local mgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"); if mgr then local afk = mgr:Get("AFKReportorSubsystem"); if afk then afk.PlayerHaveAction = nop; afk.ReportAFK = nop end end end) end
_G.InitializeAntiReport = function() pcall(function() local rp = package.loaded["GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem"]; if rp then rp.OnInit = nop; rp._OnPlayerKilledOtherPlayer = nop; rp._RecordFatalDamager = nop end end) end
_G.InitializeAntiCheatHooks = function() pcall(function() local hbc = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"); if hbc and hbc.BlackList then for k in pairs(hbc.BlackList) do hbc.BlackList[k] = nil end end end); _G.BlackList = {} end
_G.InitializeConnectionGuard = function() pcall(function() if not _G.GameplayCallbacks then return end; local GC = _G.GameplayCallbacks; local origDS = GC.OnDSPlayerStateChanged; GC.OnDSPlayerStateChanged = function(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason) local state = InPlayerState and string.lower(tostring(InPlayerState)) or ""; local block = {["cheatdetected"]=true, ["connectionlost"]=true, ["connectiontimeout"]=true, ["connectionexception"]=true, ["netdrivererror"]=true}; if block[state] then return end; if origDS then pcall(origDS, UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason) end end; GC.OnPlayerNetConnectionClosed = nop; GC.OnPlayerActorChannelError = nop end) end
_G.InitializeLogBlocker(); _G.InitializeScannerBlocker(); _G.InitializeAntiReport(); _G.InitializeAntiCheatHooks(); _G.InitializeConnectionGuard()
pcall(function() if NetUtil and NetUtil.SendPacket and not NetUtil.IsBypassed then local origSend = NetUtil.SendPacket; local blocked = {["ReportAttackFlow"]=1, ["ReportSecAttackFlow"]=1, ["ReportHurtFlow"]=1, ["ReportFireArms"]=1, ["ReportVerifyInfoFlow"]=1, ["ReportMrpcsFlow"]=1, ["ReportPlayerBehavior"]=1, ["ReportTeammatHurt"]=1, ["ReportPlayerMoveRoute"]=1, ["ReportPlayerPosition"]=1, ["ReportAimFlow"]=1, ["ReportHitFlow"]=1, ["ReportCircleFlow"]=1, ["ReportJumpFlow"]=1, ["report_players_ping"]=1, ["report_player_ip"]=1, ["tss_sdk_report"]=1, ["report_client_scan_result"]=1, ["report_memory_exception"]=1, ["report_avatar_exception"]=1, ["report_character_state"]=1, ["report_vehicle_exception"]=1, ["report_camera_exception"]=1, ["ReportEquipmentFlow"]=1, ["ReportSecTLog"]=1, ["on_tss_sdk_anti_data"]=1}; NetUtil.SendPacket = function(packetName, ...) if blocked[packetName] then return end; return origSend(packetName, ...) end; NetUtil.IsBypassed = true end end)
end)

-- ============================================================================
-- 🚀 PVT 18-LAYER BYPASS INJECTION END
-- ============================================================================

-- ==================== GOKU CORE MOD LOGIC ====================
_G.BypassState = _G.BYPASS_STATE
_G.MOD_ESPEnabled = true; _G.MOD_EnemyCounterEnabled = true; _G.MOD_Watermark_Enabled = true; _G.MOD_WallhackEnabled = false; _G.MOD_VisualCleanupEnabled = false
_G.Mod_AimAssist_Enabled = true; _G.AimAssist_Power_Slider = 0; _G.AimAssist_Power = 1.0; _G.Mod_NoRecoil_Enabled = true; _G.MOD_AntiLag_Enabled = true; _G.Mod_iPadView_Enabled = true; _G.iPadView_FOV_Slider = 110
_G.MOD_CustomMiniMapESP = false; _G.MOD_VehicleESP = false

local InGameMarkTools = safe_require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
local SecurityCommonUtils = safe_require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
local IngamePhoneStateUI = safe_require("GameLua.Mod.Library.Client.UI.IngamePhoneStateUI")

local distanceMarkerConfig = { UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C", MaxWidgetNum = 99, MaxShowDistance = 30000, bBindOutScreen = true, bBindBlocked = true, bIsBindingActor = true, BindSocketName = "head", bUseLuaWorldSocketName = true, WorldPositionOffset = FVector(0, 0, 50), bNeedPreLoad = true, Priority = 2 }
_G.AK_Active_Marks_Cache = _G.AK_Active_Marks_Cache or setmetatable({}, { __mode = "k" })

local function InitDistanceMarkerSystem()
pcall(function()
if InGameMarkTools and InGameMarkTools.ScreenMarkManager and InGameMarkTools.ScreenMarkManager.OnInitMarkGroupData then InGameMarkTools.ScreenMarkManager:OnInitMarkGroupData(9999) end
local gameplayTools = safe_require("GameLua.Mod.BaseMod.Common.GamePlayTools")
local screenMarkConfig = gameplayTools.GetCurrentConfig("ScreenMarkConfig")
if screenMarkConfig then screenMarkConfig[9999] = distanceMarkerConfig end
end)
end

local function createDistanceMarker(enemy) pcall(function() if InGameMarkTools and InGameMarkTools.ClientAddMapMark then enemy.NativeDistMark = InGameMarkTools.ClientAddMapMark(9999, FVector(0, 0, 0), 0, "", 4, enemy); _G.AK_Active_Marks_Cache[enemy] = { actor = enemy, distMark = enemy.NativeDistMark } end end) end
local function removeDistanceMarker(enemy) pcall(function() if InGameMarkTools then if InGameMarkTools.ClientRemoveMapMark then InGameMarkTools.ClientRemoveMapMark(enemy.NativeDistMark) elseif InGameMarkTools.HideMapMark then InGameMarkTools.HideMapMark(enemy.NativeDistMark) end end; enemy.NativeDistMark = nil; _G.AK_Active_Marks_Cache[enemy] = nil end) end

local function cleanupDeadEnemyMarks()
for cacheKey, cacheData in pairs(_G.AK_Active_Marks_Cache) do
local shouldRemove = false
if not isValid(cacheKey) then shouldRemove = true
else pcall(function() local actor = cacheData and cacheData.actor or cacheKey; if actor then if actor.bHidden or (actor.Mesh and actor.Mesh.bHidden) then shouldRemove = true end; if type(actor.IsDead) == "function" and actor:IsDead() then shouldRemove = true elseif actor.bIsDead == true or actor.bIsDeadFlag == true then shouldRemove = true end else shouldRemove = true end end) end
if shouldRemove then pcall(function() if cacheData and InGameMarkTools and InGameMarkTools.ClientRemoveMapMark then pcall(function() InGameMarkTools.ClientRemoveMapMark(cacheData.distMark) end) end end); _G.AK_Active_Marks_Cache[cacheKey] = nil end
end
end

local function processEnemyMapESP(enemy, localPlayer)
if not _G.MOD_CustomMiniMapESP then return end
if not isValid(enemy) or enemy == localPlayer or enemy.TeamID == localPlayer.TeamID then return end
local dist = localPlayer:GetDistanceTo(enemy)
if dist > 30000 then if enemy.bHasAKNativeMapMarker then removeDistanceMarker(enemy); enemy.bHasAKNativeMapMarker = false end; return end
local isDead = false
pcall(function() if type(enemy.IsDead) == "function" then isDead = enemy:IsDead() elseif enemy.bIsDead ~= nil then isDead = enemy.bIsDead elseif enemy.bIsDeadFlag ~= nil then isDead = enemy.bIsDeadFlag end; if enemy.bHidden or (enemy.Mesh and enemy.Mesh.bHidden) then isDead = true end; if not isDead then local health = 100; if type(enemy.GetHealth) == "function" then health = enemy:GetHealth() elseif enemy.Health ~= nil then health = enemy.Health end; if health <= 0 then isDead = true end end end)
if not isDead then if not enemy.bHasAKNativeMapMarker then createDistanceMarker(enemy); enemy.bHasAKNativeMapMarker = true end else if enemy.bHasAKNativeMapMarker then removeDistanceMarker(enemy); enemy.bHasAKNativeMapMarker = false end end
end

local function VehicleESPLoop()
if not _G.MOD_VehicleESP then return end
local pc = slua_GameFrontendHUD:GetPlayerController(); if not isValid(pc) then return end
local localPlayer = pc:GetPlayerCharacterSafety(); if not isValid(localPlayer) then return end
local myPos = localPlayer:K2_GetActorLocation(); if not myPos then return end
local HUD = pc:GetHUD(); if not isValid(HUD) then return end
if not _G._VehicleCacheTime or os.clock() - _G._VehicleCacheTime > 1.0 then _G._VehicleCacheTime = os.clock(); _G._VehicleCache = Game:GetAllVehicles() or {} end
for _, vehicle in pairs(_G._VehicleCache) do
if isValid(vehicle) then
local vPos = vehicle:K2_GetActorLocation(); local dx = vPos.X - myPos.X; local dy = vPos.Y - myPos.Y; local dz = vPos.Z - myPos.Z; local distSq = dx * dx + dy * dy + dz * dz
if distSq < 900000000 then local dist = math.sqrt(distSq); local distText = string.format("[%.0fm]", dist / 100); HUD:AddDebugText("Vehicle " .. distText, vehicle, 0.35, { X = 0, Y = 0, Z = 100 }, { X = 0, Y = 0, Z = 100 }, { R = 255, G = 255, B = 0, A = 255 }, true, false, true, nil, 1.0, true) end
end
end
end

local o_UpdateArtQualityUI
if IngamePhoneStateUI and IngamePhoneStateUI.__inner_impl and IngamePhoneStateUI.__inner_impl.UpdateArtQualityUI then
o_UpdateArtQualityUI = IngamePhoneStateUI.__inner_impl.UpdateArtQualityUI
IngamePhoneStateUI.__inner_impl.UpdateArtQualityUI = function(self, arg1, arg2)
if not _G.MOD_Watermark_Enabled and self._GokuUI_Applied then pcall(function() self.CacheQuality = nil; self.LastQuality = nil end) end
if o_UpdateArtQualityUI then pcall(o_UpdateArtQualityUI, self, arg1, arg2) end
if self and self.UIRoot and self.UIRoot.TextBlock_quality then
if _G.MOD_Watermark_Enabled then self.UIRoot.TextBlock_quality:SetText("GOKUCONFIG"); self.UIRoot.TextBlock_quality:SetColorAndOpaque(FSlateColor(FLinearColor(0, 1, 1, 1))); self._GokuUI_Applied = true
elseif self._GokuUI_Applied then self.UIRoot.TextBlock_quality:SetText("20ms"); self.UIRoot.TextBlock_quality:SetColorAndOpaque(FSlateColor(FLinearColor(0.4, 0.8, 0.4, 1))); self._GokuUI_Applied = false end
end
end
end

local function ApplyEnvironment()
pcall(function()
local gi = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance(); if not gi then return end
gi:ExecuteCMD("r.Touch.EnableVibration", "0"); gi:ExecuteCMD("r.GTSyncType", "2"); gi:ExecuteCMD("r.OneFrameThreadLag", "0")
if _G.MOD_VisualCleanupEnabled then 
    gi:ExecuteCMD("grass.DensityScale", "0"); gi:ExecuteCMD("grass.DiscardDataOnLoad", "1")
else 
    gi:ExecuteCMD("grass.DensityScale", "1"); gi:ExecuteCMD("grass.DiscardDataOnLoad", "0") 
end
end)
end

_G._MatchTimer = 0
local function ThermalGovernorLoop() pcall(function() _G._MatchTimer = _G._MatchTimer + 1; if _G._MatchTimer == 300 then local gi = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance(); if gi then gi:ExecuteCMD("r.BloomQuality", "0"); gi:ExecuteCMD("r.SceneColorFringeQuality", "0"); gi:ExecuteCMD("r.Tonemapper.Quality", "0") end end end) end

local _WH_OrigMaterials = setmetatable({}, { __mode = "k" })
local _WH_ModifiedPawns = setmetatable({}, { __mode = "k" })
local _WH_ModifiedBaseMaterials = setmetatable({}, { __mode = "k" })

function _G.ForceCleanupMatch()
pcall(function()
if _G.LOCAL_UI_TIMER then _G.LOCAL_UI_TIMER = nil end
_WH_OrigMaterials = setmetatable({}, { __mode = "k" }); _WH_ModifiedPawns = setmetatable({}, { __mode = "k" }); _WH_ModifiedBaseMaterials = setmetatable({}, { __mode = "k" })
_G.LastAimEntity = nil; _G.LastAimState = nil; _G.LastRecoilEntity = nil; _G.LastRecoilState = nil; _G._MatchTimer = 0
_G.AK_Active_Marks_Cache = setmetatable({}, { __mode = "k" })
if _G.BYPASS_STATE then for k, _ in pairs(_G.BYPASS_STATE) do _G.BYPASS_STATE[k] = false end end
collectgarbage("collect")
end)
end

local function AutoRAMCleaner() pcall(function() if _G.MOD_AntiLag_Enabled then collectgarbage("step", 200) end end) end

local MsgBox, WebSDK
local function GetMsgBox() if not MsgBox then MsgBox = safe_require("client.slua.logic.common.logic_common_msg_box") end; return MsgBox end
local function GetWebSDK() if not WebSDK then WebSDK = safe_require("client.slua.logic.url.logic_webview_sdk") end; return WebSDK end

local welcomeShown = false
local function ShowWelcomePopup()
if welcomeShown then return end; welcomeShown = true
pcall(function()
local Msg = GetMsgBox()
local welcomeContent = table.concat({
 "★ Developer: @GOKUCONFIG",
 "━━━━━━━━━━━━━━━━━━━━",
 "▸ VISUALS",
 " ✦ ESP • Wallhack • MiniMap",
 " ✦ iPad View • No Grass",
 "",
 "▸ COMBAT",
 " ✦ Custom Aim Assist • No Recoil",
 "",
 "▸ PERFORMANCE",
 " ✦ Anti-Lag • Thermal Sync",
 "━━━━━━━━━━━━━━━━━━━━",
 "✓ 100% Safe | Enjoy the Game!"}, "\n")
Msg.Show(4, "✦ GOKU PREMIUM LOADED ✦", welcomeContent, function() pcall(function() GetWebSDK():OpenURL("https://t.me/TGxGOKU_OFFICIAL") end) end)
end)
end

local MOD_EXPIRY = { year = 2026, month = 6, day = 29, hour = 0, min = 1, sec = 0 }
local MOD_EXPIRY_TS = os.time(MOD_EXPIRY)
local function isModExpired() return os.time() > MOD_EXPIRY_TS end

local lastExpiryDialogTime = 0
local function ShowExpiryDialog()
local ct = os.clock(); if ct - lastExpiryDialogTime < 5.0 then return end; lastExpiryDialogTime = ct
pcall(function()
local Msg = GetMsgBox()
local expiryContent = table.concat({
 "★ @GOKUCONFIG",
 "━━━━━━━━━━━━━━━━━━━━",
 "✗ LICENSE EXPIRED",
 "Your access has been revoked.",
 "This session is permanently locked.",
 "",
 "▸ Tap [Contact] to renew."}, "\n")
Msg.Show(4, "✗ ACCESS DENIED ✗", expiryContent, function() pcall(function() GetWebSDK():OpenURL("https://t.me/GOKUCONFIG") end) end, nil, "Contact", "Cancel")
end)
end

local aimOriginalCache = setmetatable({}, { __mode = "k" })
local AIM_BASE_VALUES = { Speed = 8.1, RangeRate = 1.8, SpeedRate = 2.5, RangeRateSight = 5.5, SpeedRateSight = 1.4, CrouchRate = 1.2, ProneRate = 1.1, DyingRate = 0 }

local function ApplyAimAssist()
if not _G.Mod_AimAssist_Enabled then return end
pcall(function()
local pc = slua_GameFrontendHUD:GetPlayerController(); if not isValid(pc) then return end
local char = pc:GetPlayerCharacterSafety(); if not isValid(char) then return end
local wm = char.WeaponManagerComponent; if not wm then return end
local weapon = wm.CurrentWeaponReplicated; if not weapon then return end
local entity = weapon.ShootWeaponEntityComp; if not isValid(entity) or not entity.AutoAimingConfig then return end
local currentState = tostring(_G.Mod_AimAssist_Enabled) .. tostring(_G.AimAssist_Power)
if entity == _G.LastAimEntity and currentState == _G.LastAimState then return end
_G.LastAimEntity = entity; _G.LastAimState = currentState
if not aimOriginalCache[entity] then local saved = {}; for _, range in ipairs({"OuterRange", "InnerRange"}) do local cfg = entity.AutoAimingConfig[range]; if cfg then saved[range] = {}; for k, _ in pairs(AIM_BASE_VALUES) do if cfg[k] ~= nil then saved[range][k] = cfg[k] end end end end; aimOriginalCache[entity] = saved end
local mult = _G.AimAssist_Power; for _, range in ipairs({"OuterRange", "InnerRange"}) do local cfg = entity.AutoAimingConfig[range]; if cfg then for k, v in pairs(AIM_BASE_VALUES) do cfg[k] = v * mult end end end
end)
end

local recoilOriginalCache = setmetatable({}, { __mode = "k" })
local RECOIL_FIELDS = {"RecoilKick", "RecoilKickADS", "AnimationKick", "AccessoriesVRecoilFactor", "AccessoriesHRecoilFactor", "GameDeviationFactor", "RecoilModifierStand", "RecoilModifierCrouch", "RecoilModifierProne", "CameraShakeScale", "AimCameraShakeScale", "ShootCameraShakeScale", "FireCameraShakeScale", "GameDeviationAccuracy", "ShotGunHorizontalSpread", "ShotGunVerticalSpread", "DeviationMultiplier"}
local RECOIL_TARGET_VALUES = { RecoilKick = 0.18, RecoilKickADS = 0.14, AnimationKick = 0.08, AccessoriesVRecoilFactor = 0.18, AccessoriesHRecoilFactor = 0.38, GameDeviationFactor = 0.38, RecoilModifierStand = 0.22, RecoilModifierCrouch = 0.18, RecoilModifierProne = 0.28, CameraShakeScale = 0.12, AimCameraShakeScale = 0.10, ShootCameraShakeScale = 0.10, FireCameraShakeScale = 0.10, GameDeviationAccuracy = 0.10, ShotGunHorizontalSpread = 0.15, ShotGunVerticalSpread = 0.15, DeviationMultiplier = 0.15 }
local RECOIL_INFO_FIELDS = {"VerticalRecoilMin", "VerticalRecoilMax", "RecoilSpeedVertical", "RecoilSpeedHorizontal", "VerticalRecoveryMax"}
local RECOIL_INFO_TARGET = { VerticalRecoilMin = 0.3, VerticalRecoilMax = 0.4, RecoilSpeedVertical = 0.2, RecoilSpeedHorizontal = 0.4, VerticalRecoveryMax = 0.1 }

local function ApplyNoRecoil()
if not _G.Mod_NoRecoil_Enabled then return end
pcall(function()
local pc = slua_GameFrontendHUD:GetPlayerController(); if not isValid(pc) then return end
local char = pc:GetPlayerCharacterSafety(); if not isValid(char) then return end
local wm = char.WeaponManagerComponent; if not wm then return end
local weapon = wm.CurrentWeaponReplicated; if not weapon then return end
local entity = weapon.ShootWeaponEntityComp; if not isValid(entity) then return end
if entity == _G.LastRecoilEntity and _G.Mod_NoRecoil_Enabled == _G.LastRecoilState then return end
_G.LastRecoilEntity = entity; _G.LastRecoilState = _G.Mod_NoRecoil_Enabled
if not recoilOriginalCache[entity] then local saved = { RecoilInfo = {} }; for _, f in ipairs(RECOIL_FIELDS) do if entity[f] ~= nil then saved[f] = entity[f] end end; if entity.RecoilInfo then for _, f in ipairs(RECOIL_INFO_FIELDS) do if entity.RecoilInfo[f] ~= nil then saved.RecoilInfo[f] = entity.RecoilInfo[f] end end end; if entity.ShootCameraShake then saved.ShootCameraShakeScale = entity.ShootCameraShake.Scale end; recoilOriginalCache[entity] = saved end
for k, v in pairs(RECOIL_TARGET_VALUES) do entity[k] = v end
if entity.RecoilInfo then for k, v in pairs(RECOIL_INFO_TARGET) do entity.RecoilInfo[k] = v end end
if entity.ShootCameraShake then entity.ShootCameraShake.Scale = 0.10 end
end)
end

local ipadViewOrigCache = setmetatable({}, { __mode = "k" })
local function ApplyiPadView()
if not _G.Mod_iPadView_Enabled then return end
pcall(function()
local pc = slua_GameFrontendHUD:GetPlayerController(); if not isValid(pc) then return end
local char = pc:GetPlayerCharacterSafety(); if not isValid(char) or not char.ThirdPersonCameraComponent then return end
local cam = char.ThirdPersonCameraComponent; if not ipadViewOrigCache[char] then ipadViewOrigCache[char] = cam.FieldOfView or 90 end
local isAiming = false; pcall(function() isAiming = char.bIsTargeting end); if isAiming then return end
local targetFov = _G.iPadView_FOV_Slider or 110; if cam.FieldOfView ~= targetFov then cam.FieldOfView = targetFov end
end)
end

if GameplayData then
local COLOR_SAFE = { R = 0, G = 255, B = 200, A = 255 }; local COLOR_WARN = { R = 255, G = 150, B = 0, A = 255 }; local COLOR_DANGER = { R = 255, G = 20, B = 60, A = 255 }
local TEXT_OFFSET = { X = 0, Y = 0, Z = 35 }; local WATERMARK_OFFSET = { X = 0, Y = 0, Z = -10 }; local TEXT_SCALE = 1.05; local MAX_DIST_SQ = 900000000

function LocalPlayerUILoop()
pcall(function()
if not (_G.MOD_EnemyCounterEnabled or _G.MOD_Watermark_Enabled) then return end
local player = GameplayData.GetPlayerCharacter(); if not isValid(player) then return end
local pc = slua_GameFrontendHUD:GetPlayerController(); if not isValid(pc) then return end
local hud = pc:GetHUD(); if not isValid(hud) then return end
if _G.MOD_Watermark_Enabled then hud:AddDebugText("✦ REAL DEV GOKUCONFIG ✦", player, 1.1, WATERMARK_OFFSET, WATERMARK_OFFSET, { R = 0, G = 255, B = 255, A = 255 }, true, false, true, nil, 0.8, true) end
if _G.MOD_EnemyCounterEnabled then
local myTeamId = player.TeamID or 0; local myPos = player:K2_GetActorLocation(); local enemyCount = 0; local allPawns = Game:GetAllPlayerPawns() or {}
for _, pawn in pairs(allPawns) do if isValid(pawn) and pawn ~= player and (pawn.TeamID or 0) ~= myTeamId then local pos = pawn:K2_GetActorLocation(); local dx = pos.X - myPos.X; local dy = pos.Y - myPos.Y; local dz = pos.Z - myPos.Z; if (dx * dx + dy * dy + dz * dz) <= MAX_DIST_SQ then enemyCount = enemyCount + 1 end end end
local text, color; if enemyCount == 0 then text = "[ AREA SECURE ]"; color = COLOR_SAFE elseif enemyCount == 1 then text = "! WARNING : 1 ENEMY !"; color = COLOR_WARN else text = "[ DANGER : " .. enemyCount .. " ENEMIES ]"; color = COLOR_DANGER end
hud:AddDebugText(text, player, 1.1, TEXT_OFFSET, TEXT_OFFSET, color, true, false, true, nil, TEXT_SCALE, true)
end
end)
end

function StartLocalPlayerUITimers()
pcall(function()
local pc = slua_GameFrontendHUD:GetPlayerController(); if not isValid(pc) then pc = import("GameplayStatics").GetPlayerController(slua_GameFrontendHUD:GetWorld(), 0) end
if not isValid(pc) then return end; if _G.LOCAL_UI_TIMER == pc then return end; _G.LOCAL_UI_TIMER = pc
pc:AddGameTimer(0.2, false, function() local controller = slua_GameFrontendHUD:GetPlayerController(); if isValid(controller) then 
-- [OPTIMIZED TIMER: 1.0s + Guard Clause]
controller:AddGameTimer(1.0, true, function() 
    if not (_G.MOD_EnemyCounterEnabled or _G.MOD_Watermark_Enabled) then return end 
    LocalPlayerUILoop() 
end) 
end end)
end)
end
end

local function IsPawnAlive(p) if not isValid(p) then return false end; if p.HealthStatus then return SecurityCommonUtils.IsHealthStatusAlive(p.HealthStatus) end; if p.IsAlive then return p:IsAlive() end; return p.GetHealth and (p:GetHealth() or 0) > 0 or false end
local function GetPawnHealthRatio(p) local hp = p.GetHealth and p:GetHealth() or 100; local maxHp = p.GetHealthMax and p:GetHealthMax() or 100; return math.max(0, math.min(1, hp / (maxHp <= 0 and 100 or maxHp))) end
local function SetRedFrameUI(p) if not isValid(p) then return end; local COLOR_RED = FLinearColor(1, 0, 0, 1); if p.Replay_SetFrameUIColor then p:Replay_SetFrameUIColor(COLOR_RED) elseif p.SetEnemyFrameColor then p:SetEnemyFrameColor(COLOR_RED) elseif p.SetFrameColor then p:SetFrameColor(COLOR_RED) elseif p.SetOutlineColor then p:SetOutlineColor(COLOR_RED) end end

local function ClearWallHackForPawn(pawn)
if not isValid(pawn) then return end
local meshes = {}
pcall(function() if isValid(pawn.Mesh) then table.insert(meshes, pawn.Mesh) end; local SkelClass = import("SkeletalMeshComponent"); if SkelClass then local childs = pawn:GetComponentsByClass(SkelClass); if childs then local count = type(childs.Num) == "function" and childs:Num() or #childs; for c = 1, count do local comp = type(childs.Get) == "function" and childs:Get(c - 1) or childs[c]; if isValid(comp) and comp ~= pawn.Mesh then table.insert(meshes, comp) end end end end end)
for _, comp in ipairs(meshes) do pcall(function() comp.bRenderCustomDepth = false; comp.CustomDepthStencilValue = 0; local origMatSlots = _WH_OrigMaterials[comp]; if origMatSlots then for i, mat in pairs(origMatSlots) do pcall(function() comp:SetMaterial(i, mat) end) end; _WH_OrigMaterials[comp] = nil end end) end
pawn._WH_MIDs = nil; _WH_ModifiedPawns[pawn] = nil
end

local function ApplyWallHack(enemy, pc)
if not _G.MOD_WallhackEnabled then return end; if not isValid(enemy) or not isValid(pc) then return end
local meshes = {}
pcall(function() if isValid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end; local SkelClass = import("SkeletalMeshComponent"); if SkelClass then local childs = enemy:GetComponentsByClass(SkelClass); if childs then local count = type(childs.Num) == "function" and childs:Num() or #childs; for c = 1, count do local comp = type(childs.Get) == "function" and childs:Get(c - 1) or childs[c]; if isValid(comp) and comp ~= enemy.Mesh then table.insert(meshes, comp) end end end end end)
local isVisible = false; pcall(function() if type(pc.LineOfSightTo) == "function" then isVisible = pc:LineOfSightTo(enemy) end end)
local bodyColor = isVisible and { R = 0, G = 255, B = 0, A = 255 } or { R = 255, G = 0, B = 0, A = 255 }
local glowColor = isVisible and { R = 0, G = 255, B = 255, A = 255 } or { R = 255, G = 0, B = 128, A = 255 }
enemy._WH_MIDs = enemy._WH_MIDs or {}; local stateChanged = (enemy._WH_LastVisible ~= isVisible); enemy._WH_LastVisible = isVisible; _WH_ModifiedPawns[enemy] = true
for _, comp in ipairs(meshes) do
if isValid(comp) then
if not _WH_OrigMaterials[comp] then local orig = {}; for i = 0, 15 do local ok, mat = pcall(function() return comp:GetMaterial(i) end); if ok and isValid(mat) then orig[i] = mat else break end end; _WH_OrigMaterials[comp] = orig end
pcall(function() comp.bRenderCustomDepth = true; comp.CustomDepthStencilValue = 250; comp.CustomDepthStencilWriteMask = 255 end)
pcall(function() local ok, mat = pcall(function() return comp:GetMaterial(0) end); if ok and isValid(mat) then local ok2, base = pcall(function() return mat:GetBaseMaterial() end); if ok2 and isValid(base) then if not _WH_ModifiedBaseMaterials[base] then _WH_ModifiedBaseMaterials[base] = { bDisableDepthTest = base.bDisableDepthTest, BlendMode = base.BlendMode } end; if base.bDisableDepthTest ~= true then base.bDisableDepthTest = true end; if base.BlendMode ~= 2 then base.BlendMode = 2 end end end end)
comp.UseScopeDistanceCulling = false; comp.PrimitiveShadingStrategy = 1; comp.ShadingRate = 6; enemy._WH_MIDs[comp] = enemy._WH_MIDs[comp] or {}
for i = 0, 15 do
local ok3, mi = pcall(function() return comp:GetMaterial(i) end); if not ok3 or not isValid(mi) then break end
local mid = enemy._WH_MIDs[comp][i]
if not isValid(mid) then local ok4, nm = pcall(function() return comp:CreateAndSetMaterialInstanceDynamic(i) end); if ok4 and isValid(nm) then enemy._WH_MIDs[comp][i] = nm; mid = nm end else if mi ~= mid then pcall(function() comp:SetMaterial(i, mid) end) end end
if isValid(mid) and (stateChanged or not enemy._WH_MIDs[comp][i]) then pcall(function() mid:SetVectorParameterValue("颜色", bodyColor); mid:SetVectorParameterValue("Extra Light Color", bodyColor); mid:SetVectorParameterValue("Para_Color", bodyColor); mid:SetVectorParameterValue("Tint", bodyColor); mid:SetVectorParameterValue("BaseColor", bodyColor); mid:SetVectorParameterValue("BodyColor", bodyColor); mid:SetVectorParameterValue("GlowColor", glowColor); mid:SetVectorParameterValue("OutlineColor", glowColor); mid:SetScalarParameterValue("Glow", 10.0); mid:SetScalarParameterValue("GlowAmount", 10.0); mid:SetScalarParameterValue("EmissiveBoost", 5.0) end) end
end
end
end
end

_G._WH_NeedCleanup = false
function OnWallhackToggleChanged() if not _G.MOD_WallhackEnabled then _G._WH_NeedCleanup = true end end

function InjectModMenu()
local LocUtil = _G.LocUtil; if not LocUtil and package.loaded["client.common.LocUtil"] then LocUtil = safe_require("client.common.LocUtil") end
if LocUtil and not LocUtil._IsModMenuHooked then local old_get = LocUtil.GetLocalizeResStr; LocUtil.GetLocalizeResStr = function(id) if type(id) == "string" and not tonumber(id) then return id end; if old_get then return old_get(id) end; return "" end; LocUtil._IsModMenuHooked = true end
local SettingPageDefine = safe_require("client.logic.NewSetting.SettingPageDefine"); local SettingCatalog = safe_require("client.logic.NewSetting.SettingCatalog"); local AliasMap = safe_require("client.slua.umg.NewSetting.Item.AliasMap")
if SettingPageDefine and SettingCatalog and AliasMap and not SettingPageDefine.ModMenu then
local ModMenuStack = {
{ UI = AliasMap.Title, Text = "✦ ESP & VISUALS ✦" },
{ Key = "ESP", UI = AliasMap.Switcher, Text = "ESP (Classic Box + HP)", GetFunc = function() return _G.MOD_ESPEnabled end, SetFunc = function(_, value) _G.MOD_ESPEnabled = value; return true end },
{ Key = "Watermark", UI = AliasMap.Switcher, Text = "Watermark (Float + UI)", GetFunc = function() return _G.MOD_Watermark_Enabled end, SetFunc = function(_, value) _G.MOD_Watermark_Enabled = value; return true end },
{ Key = "CustomMiniMapESP", UI = AliasMap.Switcher, Text = "Custom Mini Map ESP (UI)", GetFunc = function() return _G.MOD_CustomMiniMapESP end, SetFunc = function(_, value) _G.MOD_CustomMiniMapESP = value; return true end },
{ Key = "VehicleESP", UI = AliasMap.Switcher, Text = "Vehicle ESP", GetFunc = function() return _G.MOD_VehicleESP end, SetFunc = function(_, value) _G.MOD_VehicleESP = value; return true end },
{ Key = "Wallhack", UI = AliasMap.Switcher, Text = "Wallhack (Chams)", GetFunc = function() return _G.MOD_WallhackEnabled end, SetFunc = function(_, value) _G.MOD_WallhackEnabled = value; OnWallhackToggleChanged(); return true end },
{ Key = "EnemyCounter", UI = AliasMap.Switcher, Text = "Enemy Counter (300m)", GetFunc = function() return _G.MOD_EnemyCounterEnabled end, SetFunc = function(_, value) _G.MOD_EnemyCounterEnabled = value; return true end },
{ UI = AliasMap.Title, Text = "✦ GRAPHICS & PERFORMANCE ✦" },
{ Key = "VisualCleanup", UI = AliasMap.Switcher, Text = "Visual Cleanup (No Grass)", GetFunc = function() return _G.MOD_VisualCleanupEnabled end, SetFunc = function(_, value) _G.MOD_VisualCleanupEnabled = value; ApplyEnvironment(); return true end },
{ Key = "AntiLag", UI = AliasMap.Switcher, Text = "Anti-Lag (Auto Clear RAM)", GetFunc = function() return _G.MOD_AntiLag_Enabled end, SetFunc = function(_, value) _G.MOD_AntiLag_Enabled = value; return true end },
{ UI = AliasMap.Title, Text = "✦ COMBAT & PERFORMANCE ✦" },
{ Key = "AimAssist", UI = AliasMap.Switcher, Text = "Aim Assist (Master Toggle)", GetFunc = function() return _G.Mod_AimAssist_Enabled end, SetFunc = function(_, value) _G.Mod_AimAssist_Enabled = value; _G.LastAimState = nil; return true end },
{ Key = "AimPower", UI = AliasMap.Slider, Text = "Aim Power (0=Legit, 100=Brutal)", GetFunc = function() return _G.AimAssist_Power_Slider end, SetFunc = function(_, value) local val = tonumber(value) or 0; if val > 100 then val = 100 end; if val < 0 then val = 0 end; _G.AimAssist_Power_Slider = val; _G.AimAssist_Power = 1.0 + (val / 100) * 1.5; _G.LastAimState = nil; return true end },
{ Key = "NoRecoil", UI = AliasMap.Switcher, Text = "Less Recoil", GetFunc = function() return _G.Mod_NoRecoil_Enabled end, SetFunc = function(_, value) _G.Mod_NoRecoil_Enabled = value; return true end },
{ Key = "iPadViewToggle", UI = AliasMap.Switcher, Text = "Enable iPad View", GetFunc = function() return _G.Mod_iPadView_Enabled end, SetFunc = function(_, value) _G.Mod_iPadView_Enabled = value; ApplyiPadView(); return true end },
{ Key = "iPadViewFOV", UI = AliasMap.Slider, Text = "iPad View FOV (110-130)", GetFunc = function() local currentFov = _G.iPadView_FOV_Slider or 110; return ((currentFov - 110) / 20) * 100 end, SetFunc = function(_, value) local val = tonumber(value) or 0; if val > 100 then val = 100 end; if val < 0 then val = 0 end; _G.iPadView_FOV_Slider = 110 + (val / 100) * 20; return true end },
}
SettingPageDefine.ModMenu = { Key = "ModMenu", loc = "GOKU CONFIG", UIKey = "Setting_Page_Privacy", Category = { { Key = "ModMenu_Main", loc = "Features", Stack = ModMenuStack } } }
end
if SettingCatalog and SettingPageDefine and SettingPageDefine.ModMenu then
local alreadyInCatalog = false; for _, page in ipairs(SettingCatalog) do if page.Key == "ModMenu" then alreadyInCatalog = true; break end end
if not alreadyInCatalog then table.insert(SettingCatalog, SettingPageDefine.ModMenu) end
end
local UIManager = _G.UIManager
if UIManager and not UIManager._IsModMenuHooked then
local old_ShowUI = UIManager.ShowUI
UIManager.ShowUI = function(config, ...)
local args = { ... }
if config and config.keyName and (string.find(string.lower(config.keyName), "setting_main") or string.find(string.lower(config.keyName), "setting")) then
local catalog = args[1]
if catalog and (type(catalog) == "table" or type(catalog) == "userdata") then
local hasModMenu = false; local newCatalog = {}
for _, page in ipairs(catalog) do table.insert(newCatalog, page); if page.Key == "ModMenu" then hasModMenu = true end end
if not hasModMenu and SettingPageDefine.ModMenu then table.insert(newCatalog, SettingPageDefine.ModMenu); args[1] = newCatalog end
end
end
return old_ShowUI(config, table.unpack(args))
end
UIManager._IsModMenuHooked = true
end
end

-- ============================================================================
-- 🚀 SERVER-SIDED WATCHDOG INJECTION
-- ============================================================================
local function StartVisualTimers(pc)
if _G._GOKU_VISUALS_STARTED then return end
_G._GOKU_VISUALS_STARTED = true
local cachedMarks = {}; local cachedPawns = {}; local lastPawnRefresh = 0; local cachedMarksTime = {}

-- [OPTIMIZED TIMER: 0.8s + Guard Clause]
pc:AddGameTimer(0.8, true, function()
    if not _G.MOD_ESPEnabled then return end
    if not isValid(pc) then for pawn, markId in pairs(cachedMarks) do if type(markId) ~= "table" and markId then InGameMarkTools.HideMapMark(markId) end end; cachedMarks = {}; cachedMarksTime = {}; return end
    local uCon = slua_GameFrontendHUD:GetPlayerController()
    local ASTExtraPlayerController = import("/Script/ShadowTrackerExtra.STExtraPlayerController")
    if not (isValid(uCon) and Game:IsClassOf(uCon, ASTExtraPlayerController)) then return end
    local currentPawn = uCon:GetCurPawn(); if not isValid(currentPawn) then return end
    local myTeamId, myPos = currentPawn.TeamID, currentPawn:K2_GetActorLocation()
    local HUD = uCon:GetHUD(); local Canvas = isValid(HUD) and HUD.Canvas or nil; local now = os.clock()
    if now - lastPawnRefresh > 1.0 then lastPawnRefresh = now; cachedPawns = Game:GetAllPlayerPawns() or {}; for pawnPtr, markId in pairs(cachedMarks) do local found = false; for _, p in pairs(cachedPawns) do if p == pawnPtr then found = true; break end end; if not found then if markId then InGameMarkTools.HideMapMark(markId) end; cachedMarks[pawnPtr] = nil; cachedMarksTime[pawnPtr] = nil end end end
    local VEC_Z85, VEC_Z90 = FVector(0, 0, 85), FVector(0, 0, 90)
    local COLOR_HP_GREEN = FLinearColor(0, 1, 0, 0.95); local COLOR_HP_YELLOW = FLinearColor(1, 1, 0, 0.95); local COLOR_HP_RED = FLinearColor(1, 0, 0, 0.95); local COLOR_BG = FLinearColor(0, 0, 0, 0.55); local MAX_DIST = 30000
    for _, tPawn in pairs(cachedPawns) do
        if isValid(tPawn) and tPawn ~= currentPawn and tPawn.TeamID ~= myTeamId then
            if IsPawnAlive(tPawn) then
                local enemyPos = tPawn:K2_GetActorLocation()
                if enemyPos then
                    local dx = enemyPos.X - myPos.X; local dy = enemyPos.Y - myPos.Y; local dz = enemyPos.Z - myPos.Z; local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                    if dist < MAX_DIST then
                        if tPawn.Replay_CreateEnemyFrameUI then tPawn:Replay_CreateEnemyFrameUI(true, true) end
                        SetRedFrameUI(tPawn)
                        if tPawn.Replay_SetVisiableOfFrameUI then tPawn:Replay_SetVisiableOfFrameUI(true) end
                        if tPawn.SetPlayerNameVisible then tPawn:SetPlayerNameVisible(true) end
                        local headPos, rootPos
                        if dist > 15000 then headPos, rootPos = enemyPos + VEC_Z85, enemyPos - VEC_Z85
                        else local realHead = tPawn:GetHeadLocation(false); headPos = realHead or (enemyPos + VEC_Z85); rootPos = realHead and (enemyPos - VEC_Z90) or (enemyPos - VEC_Z85) end
                        cachedMarksTime[tPawn] = cachedMarksTime[tPawn] or 0
                        if now - (cachedMarksTime[tPawn] or 0) > 1.5 then
                            cachedMarksTime[tPawn] = now
                            if cachedMarks[tPawn] then InGameMarkTools.UpdateMapMarkLocation(cachedMarks[tPawn], headPos)
                            else cachedMarks[tPawn] = InGameMarkTools.ClientAddMapMark(1006, headPos, 0, "", 4, tPawn) end
                        end
                        if Canvas then
                            local headScreen, rootScreen = FVector2D(0,0), FVector2D(0,0)
                            if uCon:ProjectWorldLocationToScreen(headPos, false, headScreen) and uCon:ProjectWorldLocationToScreen(rootPos, false, rootScreen) then
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
                if cachedMarks[tPawn] then InGameMarkTools.HideMapMark(cachedMarks[tPawn]); cachedMarks[tPawn] = nil; cachedMarksTime[tPawn] = nil end
            end
        end
    end
end)

-- [OPTIMIZED TIMER: 0.25s -> 0.5s + Guard Clause]
pc:AddGameTimer(0.5, true, function()
    if not _G.MOD_WallhackEnabled then
        if _G._WH_NeedCleanup then
            for pawn, _ in pairs(_WH_ModifiedPawns) do if isValid(pawn) then ClearWallHackForPawn(pawn) end end
            _WH_OrigMaterials = setmetatable({}, { __mode = "k" }); _WH_ModifiedPawns = setmetatable({}, { __mode = "k" })
            for base, orig in pairs(_WH_ModifiedBaseMaterials) do pcall(function() if isValid(base) then base.bDisableDepthTest = orig.bDisableDepthTest; base.BlendMode = orig.BlendMode end end) end
            _WH_ModifiedBaseMaterials = setmetatable({}, { __mode = "k" }); _G._WH_NeedCleanup = false
        end
        return
    end
    if not isValid(pc) then return end
    local uCon = slua_GameFrontendHUD:GetPlayerController()
    local ASTExtraPlayerController = import("/Script/ShadowTrackerExtra.STExtraPlayerController")
    if not (isValid(uCon) and Game:IsClassOf(uCon, ASTExtraPlayerController)) then return end
    local currentPawn = uCon:GetCurPawn(); if not isValid(currentPawn) then return end
    local myTeamId, myPos = currentPawn.TeamID, currentPawn:K2_GetActorLocation()
    for _, tPawn in pairs(cachedPawns) do
        if isValid(tPawn) and tPawn ~= currentPawn and tPawn.TeamID ~= myTeamId and IsPawnAlive(tPawn) then
            local enemyPos = tPawn:K2_GetActorLocation(); local dx = enemyPos.X - myPos.X; local dy = enemyPos.Y - myPos.Y; local dz = enemyPos.Z - myPos.Z
            if (dx*dx + dy*dy + dz*dz) < 900000000 then pcall(ApplyWallHack, tPawn, uCon) end
        end
    end
end)

-- [OPTIMIZED TIMER: 1.0s -> 1.5s + Guard Clause]
pc:AddGameTimer(1.5, true, function()
    if not _G.MOD_CustomMiniMapESP then
        for cacheKey, cacheData in pairs(_G.AK_Active_Marks_Cache) do pcall(function() if InGameMarkTools and InGameMarkTools.ClientRemoveMapMark then InGameMarkTools.ClientRemoveMapMark(cacheData.distMark) end end); _G.AK_Active_Marks_Cache[cacheKey] = nil end
        return
    end
    if not isValid(pc) then return end
    local uCon = slua_GameFrontendHUD:GetPlayerController()
    local ASTExtraPlayerController = import("/Script/ShadowTrackerExtra.STExtraPlayerController")
    if not (isValid(uCon) and Game:IsClassOf(uCon, ASTExtraPlayerController)) then return end
    local localPlayer = GameplayData.GetPlayerCharacter(); if not isValid(localPlayer) then return end
    local myTeamId = localPlayer.TeamID or 0; local allPawns = Game:GetAllPlayerPawns() or {}
    for _, tPawn in pairs(allPawns) do if isValid(tPawn) and tPawn ~= localPlayer and tPawn.TeamID ~= myTeamId then processEnemyMapESP(tPawn, localPlayer) end end
    cleanupDeadEnemyMarks()
end)

-- [OPTIMIZED TIMER: 0.35s -> 0.7s + Guard Clause]
pc:AddGameTimer(0.7, true, function()
    if not _G.MOD_VehicleESP then return end
    pcall(VehicleESPLoop)
end)
end

local function StartMatchFeatures(pc, pawn)
pcall(ApplyAllBypasses)
pcall(hookPerPlayerHiggs)
pcall(startPersistentTimer)
pcall(InitDistanceMarkerSystem)
if GameplayData then pcall(StartLocalPlayerUITimers) end
pcall(InjectModMenu)
pcall(ApplyEnvironment)
-- [OPTIMIZED TIMERS WITH GUARD CLAUSES]
pc:AddGameTimer(5.0, true, ApplyEnvironment)
pc:AddGameTimer(0.6, true, function() if not _G.Mod_AimAssist_Enabled then return end; ApplyAimAssist() end)
pc:AddGameTimer(0.6, true, function() if not _G.Mod_NoRecoil_Enabled then return end; ApplyNoRecoil() end)
pc:AddGameTimer(0.4, true, function() if not _G.Mod_iPadView_Enabled then return end; ApplyiPadView() end)
pc:AddGameTimer(1.0, true, ThermalGovernorLoop)
pc:AddGameTimer(30.0, true, AutoRAMCleaner)

StartVisualTimers(pc)

if not isModExpired() then
    pcall(ShowWelcomePopup)
else
    pcall(ShowExpiryDialog)
    pc:AddGameTimer(5.0, true, ShowExpiryDialog)
end
end

local function GokuMatchWatchdog()
local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
local pawn = pc and pc:GetCurPawn()
if isValid(pc) and isValid(pawn) then
    if not _G._GOKU_MATCH_INITIALIZED then
        _G._GOKU_MATCH_INITIALIZED = true
        _G._GOKU_VISUALS_STARTED = false
        pcall(StartMatchFeatures, pc, pawn)
    end
else
    if _G._GOKU_MATCH_INITIALIZED then
        _G._GOKU_MATCH_INITIALIZED = false
        _G._GOKU_VISUALS_STARTED = false
        pcall(_G.ForceCleanupMatch)
    end
end
end

pcall(function()
if Game and Game.SetTimer then
Game:SetTimer(1.0, true, GokuMatchWatchdog)
else
local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
if pc and pc.AddGameTimer then pc:AddGameTimer(1.0, true, GokuMatchWatchdog) end
end
end)
print("[MOD] ✅ GOKU + PVT 18-LAYER MASTER BUILD [OPTIMIZED] LOADED SUCCESSFULLY!")
