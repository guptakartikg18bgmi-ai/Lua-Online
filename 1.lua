-- 1.lua : central mod/bypass/menu/features file (heavy logic moved here)
if _G._BYPASS_LOADED then return end
_G._BYPASS_LOADED = true

local BYPASS_STATE = _G.BYPASS_STATE or {
    DEADEYE_DISABLED = false, HAWKEYE_DISABLED = false, VOKLAI_DISABLED = false,
    HIGGSBOSON_DISABLED = false, HASH_VERIFY_DISABLED = false, IP_MAPPING_DISABLED = false,
    MEMORY_PATCH_DISABLED = false, EDU_EYE_DISABLED = false, FULL_BYPASS_ACTIVE = false
}
_G.BYPASS_STATE = BYPASS_STATE

local require = require
local import = import
local isValid = slua.isValid
local nop = function() return true end
local retFalse = function() return false end
local retZero = function() return 0 end
local retEmpty = function() return {} end

local function safe_require(path)
    local ok, mod = pcall(require, path)
    return ok and mod or nil
end

-- Initial popup (safe)
pcall(function()
    local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
    if not Msg then Msg = require("client.slua.logic.common.logic_common_msg_box") end
    if Msg and Msg.Show then
        Msg.Show(4, "GOKUCONFIG", "COMPLETE BYPASS ACTIVE\n8-LAYER ANTI-CHEAT BYPASSED\nPlay Safe")
    end
end)

-- MessageBox filter: ONLY block curator notifications, not minor protection popup
pcall(function()
    local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
    if Msg and Msg.Show then
        local oldShow = Msg.Show
        Msg.Show = function(self, tp, title, content, cb, ...)
            local titleLower = title and tostring(title):lower() or ""
            local contentLower = content and tostring(content):lower() or ""
            if titleLower:find("curator") or contentLower:find("curator") then
                return
            end
            return oldShow(self, tp, title, content, cb, ...)
        end
    end
end)

-- UI / Mod menu injection moved here (was originally in BRPlayerCharacterBase)
pcall(function()
    local IngamePhoneStateUI = safe_require("GameLua.Mod.Library.Client.UI.IngamePhoneStateUI") or (package.loaded["GameLua.Mod.Library.Client.UI.IngamePhoneStateUI"] and require("GameLua.Mod.Library.Client.UI.IngamePhoneStateUI"))
    if IngamePhoneStateUI and IngamePhoneStateUI.__inner_impl then
        local o_UpdateArtQualityUI = IngamePhoneStateUI.__inner_impl.UpdateArtQualityUI
        IngamePhoneStateUI.__inner_impl.UpdateArtQualityUI = function(self, p1, p2)
            if o_UpdateArtQualityUI then pcall(o_UpdateArtQualityUI, self, p1, p2) end
            if self and self.UIRoot and self.UIRoot.TextBlock_quality then
                pcall(function()
                    self.UIRoot.TextBlock_quality:SetText("GOKUCONFIG")
                    self.UIRoot.TextBlock_quality:SetColorAndOpacity(FSlateColor(FLinearColor(1, 0, 0, 1)))
                end)
            end
        end
    end
end)

local function InjectModMenu()
    if _G.__ModMenuInjected then return end
    local SettingPageDefine = package.loaded["client.logic.NewSetting.SettingPageDefine"]
    if not SettingPageDefine then
        local hud = slua_GameFrontendHUD
        if hud and hud.AddGameTimer then hud:AddGameTimer(0.5, false, InjectModMenu) end
        return
    end
    _G.__ModMenuInjected = true
    local LocUtil = _G.LocUtil
    if not LocUtil and package.loaded["client.common.LocUtil"] then LocUtil = require("client.common.LocUtil") end
    if LocUtil and not LocUtil._IsModMenuHooked then
        local old_get = LocUtil.GetLocalizeResStr
        LocUtil.GetLocalizeResStr = function(id) if type(id) == "string" and not tonumber(id) then return id end; return old_get(id) end
        LocUtil._IsModMenuHooked = true
    end
    local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")
    local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")
    local ModMenuStack = {
        { UI = AliasMap.Title, Text = "GOKU CONFIG" },
        { Key = "ESP", UI = AliasMap.Switcher, Text = "ESP (Visuals)", GetFunc = function() return _G.MOD_ESPEnabled end, SetFunc = function(_, value) _G.MOD_ESPEnabled = value; pcall(_G.SaveConfig); return true end },
        { Key = "EnemyCounter", UI = AliasMap.Switcher, Text = "ENEMY COUNTER", GetFunc = function() return _G.MOD_EnemyCounterEnabled end, SetFunc = function(_, value) _G.MOD_EnemyCounterEnabled = value; pcall(_G.SaveConfig); return true end },
        { Key = "MapTracking", UI = AliasMap.Switcher, Text = "MAP TRACKING", GetFunc = function() return _G.MOD_MapTrackingEnabled end, SetFunc = function(_, value) _G.MOD_MapTrackingEnabled = value; pcall(_G.SaveConfig); return true end },
        { Key = "NoGrassWaterFog", UI = AliasMap.Switcher, Text = "NO GRASS / WATER / FOG", GetFunc = function() return _G.MOD_NoGrassEnabled end, SetFunc = function(_, value) _G.MOD_NoGrassEnabled = value; pcall(_G.SaveConfig); return true end },
        { Key = "AimAssist", UI = AliasMap.Switcher, Text = "AIM ASSIST", GetFunc = function() return _G.Mod_AimAssist_Enabled end, SetFunc = function(_, value) _G.Mod_AimAssist_Enabled = value; pcall(_G.SaveConfig); return true end },
        { Key = "NoRecoil", UI = AliasMap.Switcher, Text = "LESS RECOIL", GetFunc = function() return _G.Mod_NoRecoil_Enabled end, SetFunc = function(_, value) _G.Mod_NoRecoil_Enabled = value; pcall(_G.SaveConfig); return true end },
        { Key = "FPS165", UI = AliasMap.Switcher, Text = "165 FPS", GetFunc = function() return _G.Mod_FPS165_Enabled end, SetFunc = function(_, value) _G.Mod_FPS165_Enabled = value; pcall(_G.SaveConfig); return true end },
        { Key = "iPadView", UI = AliasMap.Switcher, Text = "IPAD VIEW", GetFunc = function() return _G.Mod_iPadView_Enabled end, SetFunc = function(_, value) _G.Mod_iPadView_Enabled = value; pcall(_G.SaveConfig); return true end },
    }
    SettingPageDefine.ModMenu = {
        Key = "ModMenu", loc = "GOKU CONFIG", UIKey = "Setting_Page_Privacy",
        Category = { { Key = "ModMenu_Main", loc = "Features", Stack = ModMenuStack } }
    }
    -- REMOVED insertion to avoid corrupting global settings save/load.

    local UIManager = _G.UIManager
    if UIManager and not UIManager._IsModMenuHooked then
        local old_ShowUI = UIManager.ShowUI
        UIManager.ShowUI = function(config, ...)
            local args = {...}
            if config and config.keyName and (string.find(string.lower(config.keyName), "setting_main") or string.find(string.lower(config.keyName), "setting")) then
                local catalog = args[1]
                if catalog and (type(catalog) == "table" or type(catalog) == "userdata") then
                    local hasModMenu = false
                    local newCatalog = {}
                    for _, page in ipairs(catalog) do
                        table.insert(newCatalog, page)
                        if page.Key == "ModMenu" then hasModMenu = true end
                    end
                    if not hasModMenu then table.insert(newCatalog, SettingPageDefine.ModMenu); args[1] = newCatalog end
                end
            end
            return old_ShowUI(config, table.unpack(args))
        end
        UIManager._IsModMenuHooked = true
    end
end
pcall(InjectModMenu)

local function KillFunctionsInTable(tbl, pattern)
    if not tbl then return end
    for k, v in pairs(tbl) do
        if type(v) == "function" and k:find(pattern) then
            pcall(function() tbl[k] = nop end)
        end
    end
end

local function killReportFuncs(mod)
    if mod then KillFunctionsInTable(mod, "Report"); KillFunctionsInTable(mod, "Send"); KillFunctionsInTable(mod, "Log") end
end

-- Core security bypasses
pcall(function()
    local stExtra = import("STExtraBlueprintFunctionLibrary")
    if stExtra and stExtra.IsDevelopment then stExtra.IsDevelopment = nop end
    if Client then Client.IsDevelopment = nop; Client.IsShipping = retFalse end
    if Server then Server.IsShipping = retFalse end

    local ToolReport = package.loaded["client.slua.logic.report.ToolReportUtil"]
    if ToolReport then ToolReport.IsReleaseVersion = retFalse; ToolReport.IsWhite = retFalse; ToolReport.GetReportSwitch = retFalse end

    local callbacks = _G.GameplayCallbacks or _G.GC
    if callbacks then
        local kills = { "SendTssSdkAntiDataToLobby","SendDSErrorLogToLobby","SendDSHawkEyePatrolLogToLobby",
            "SendSecTLog","SendDataMiningTLog","SendActivityTLog","SendClientMemUsage","SendClientFPS",
            "OnClientCrashReport","OnNetworkLossDetected","ReportMatchRoomData","ReportPlayersPing",
            "SendClientStats","SendServerAvgTickDelta","ReportHitFlow","OnPlayerActorChannelError","OnPlayerRPCValidateFailed" }
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
    if PC then
        PC.player_report_cheat = nop; PC.upload_loots_rsp = nop; PC.watch_player_exit = nop
        PC.player_login_report = nop; PC.player_logout_report = nop; PC.server_time_report = nop
    end
    local sdm = _G.ServerDataMgr
    if sdm and sdm.DeletablePlayerResultKey then
        sdm.DeletablePlayerResultKey["SuspiciousHitCount"] = true
        sdm.DeletablePlayerResultKey["EspTotalSimTraceCnt"] = true
        sdm.DeletablePlayerResultKey["EspTotalImeFocusCnt"] = true
        sdm.DeletablePlayerResultKey["ClientGravityAnomalyCount"] = true
    end
    local pcNotify = package.loaded["GameLua.Mod.BaseMod.Common.Security.SecurityNotifyPCFeature"]
    if pcNotify then
        pcNotify.ClientRPC_SyncBanID = nop; pcNotify.ClientRPC_StrongTips = nop
        pcNotify.ClientRPC_NormalTips = nop; pcNotify.Notify = nop; pcNotify.ClientRPC_NotifyBan = nop
        pcNotify.ClientRPC_NotifyPunish = nop; pcNotify.ClientRPC_NotifyIllegalProgram = nop
    end
    local secUtils = package.loaded["GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils"]
    if secUtils and secUtils.EStrategyTypeInReplay then
        secUtils.EStrategyTypeInReplay.EspTotalSimTraceCnt = 0
        secUtils.EStrategyTypeInReplay.EspTotalImeFocusCnt = 0
        secUtils.EStrategyTypeInReplay.ClientGravityAnomalyCount = 0
        secUtils.EStrategyTypeInReplay.FlyingErrorCnt = 0
    end
end)

pcall(function()
    local Higgs = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
    if Higgs then
        local methods = {"ControlMHActive","Tick","OnTick","MHActiveLogic","TriggerAvatarCheck","StartAvatarCheck",
            "ReportItemID","ReceiveAnyDamage","OnWeaponHitRecord","ShowSecurityAlert","ServerReportAvatar",
            "ClientReportNetAvatar","SendHisarData","ValidateSecurityData","StaticShowSecurityAlertInDev"}
        for _, m in ipairs(methods) do if Higgs[m] then Higgs[m] = nop end end
        Higgs.GetNetAvatarItemIDs = retEmpty; Higgs.GetCurWeaponSkinID = retZero
    end
    if _G.DisableHiggsBoson then _G.DisableHiggsBoson = nop end
    local hia = safe_require("GameLua.Mod.BaseMod.Client.Security.ClientGlueHiaSystem")
    if hia then hia.CheckHitIntegrity = nop; hia.InitSession = nop; hia.OnBattleEnd = nop end
    local Behavior = safe_require("GameLua.Mod.Escape.Gameplay.Subsystem.BehaviorScoreSubsystem")
    if Behavior then Behavior.OnHandleBehaviorScore = nop; Behavior.AIPerceptionScore = nop;
        Behavior.ReportBehavior = nop; Behavior.CalcFinalScore = retZero end
end)

pcall(function()
    local BanLogic = package.loaded["client.slua.logic.ban.ClientBanLogic"]
    if BanLogic then BanLogic.OnSyncBanInfo = nop; BanLogic.OnVoiceBanNotify = nop;
        BanLogic.OnRealTimeVoiceBanNotify = nop; BanLogic.OnVoiceBanSuccess = nop;
        BanLogic.OnSyncMicSuspicious = nop; BanLogic.OnSyncMicPreFilter = nop;
        BanLogic.OnNotifyWarningTips = nop; BanLogic.ReqBanInfo = nop end
    local BanUtil = package.loaded["client.common.ban_util"] or _G.ban_util
    if BanUtil then BanUtil.CheckBanStatus = retFalse; BanUtil.GetBanTime = retZero; BanUtil.IsBanForever = retFalse end
    local TTBan = package.loaded["client.logic.login.logic_tt_ban"] or _G.logic_tt_ban
    if TTBan then TTBan.CheckIfCanCreateRole = nop;
        TTBan.GetCarrierInfo = function() return "[{\"mcc\":\"000\"}]" end end
    local GodzillaBan = package.loaded["client.network.Protocol.GodzillaBanHandler"]
    if GodzillaBan then GodzillaBan.send_godzilla_ban_req = nop; GodzillaBan.send_godzilla_unban_req = nop end
    local AntiAddiction = package.loaded["client.network.Protocol.AntiaddctionHandler"]
    if AntiAddiction then AntiAddiction.send_anti_addiction_req = nop; AntiAddiction.send_anti_addiction_notify = nop end
    local AccessRestrict = package.loaded["client.network.Protocol.AccessRestrictionHandler"]
    if AccessRestrict then AccessRestrict.send_access_restriction_req = nop;
        AccessRestrict.send_access_restriction_notify = nop; AccessRestrict.on_player_cheat_state_notify = nop end
    local DeleteAccount = package.loaded["client.slua.logic.gdpr.logic_deleteaccount"]
    if DeleteAccount then DeleteAccount.ForceDeleteAccount = retFalse; DeleteAccount.OnReceiveDeleteNotify = nop end
    local ComplianceUtil = package.loaded["client.slua.logic.gdpr.compliance_util"]
    if ComplianceUtil then ComplianceUtil.CheckCompliance = nop end
end)

pcall(function()
    local function killMethods(tbl, names)
        if not tbl then return end
        for _, name in ipairs(names) do if tbl[name] then tbl[name] = nop end end
    end
    local clientReport = package.loaded["GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem"]
    killMethods(clientReport, {"OnInit","_OnPlayerKilledOtherPlayer","_RecordFatalDamager","SendPacket","ReportSuspiciousPlayer","SubmitReport","_OnBattleResult","_RecordTeammatePlayerInfo","_OnDeathReplayDataWhenFatalDamaged","_RecordMurdererFromDeathReplayData"})
    local dsReport = package.loaded["GameLua.Mod.BaseMod.Common.Security.DSReportPlayerSubsystem"]
    killMethods(dsReport, {"_OnNearDeathOrRescued","_OnPlayerSettlementStart","_OnTeammateDamage","_OnCharacterDied","_AddEnemyMapToBattleResult","_AddTeammateMapToBattleResult","_SubmitAbnormalData"})
    local reportUtils = package.loaded["GameLua.Mod.BaseMod.Common.Security.ReportPlayerUtils"]
    if reportUtils then reportUtils.GetBotType = retZero; reportUtils.IsCharacterDeliverAI = retFalse end
    local AvatarSub = package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionSubsystem"]
    killMethods(AvatarSub, {"OnClickReportCheckAvatar","RegisterTickCheckCharacterAvatar"})
    if _G.AvatarExceptionPlayerInst then
        _G.AvatarExceptionPlayerInst.ReportAvatarException = nop
        _G.AvatarExceptionPlayerInst.CheckAvatarException = nop
        _G.AvatarExceptionPlayerInst.CheckCanBugglyPostException = nop
    end
    local SubsystemMgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    if SubsystemMgr then
        local hawk = SubsystemMgr:Get("DSHawkEyePatrolSubsystem")
        if hawk then hawk.MarkSuspiciousPlayer = nop end
    end
    if _G.DSHawkEyePatrolSubsystem then
        _G.DSHawkEyePatrolSubsystem._OnHawkReport = nop
        _G.DSHawkEyePatrolSubsystem._OnHawkImprison = nop
        _G.DSHawkEyePatrolSubsystem.CheckPunishPlayer = nop
    end
    local ClientHawk = package.loaded["GameLua.Mod.BaseMod.Client.Security.ClientHawkEyePatrolSubsystem"]
    killMethods(ClientHawk, {"_OnHawkSync","_OnHawkReportSuccess","_StartExitGameTimer","_OnRecvInspectorBroadcastCount","SendReportTLog","ReportCheat"})
    if ClientHawk then ClientHawk.CanInspectorBroadcast = retFalse end
    local InspectClient = package.loaded["GameLua.Mod.BaseMod.Client.Security.InspectionSystemReportClientLogicSubsystem"]
    killMethods(InspectClient, {"AskForInspector","ReportEnemy","KickOutOneTeam","OnReceiveInspectCmd","ClientReportData","SendReportToInspector","SendKickOutOneTeam","ClientNotifyInspectorImplementation","RecvNotifyInspector"})
    local InspectDS = package.loaded["GameLua.Mod.BaseMod.DS.Security.InspectionSystemReportDSLogicSubsystem"]
    killMethods(InspectDS, {"ServerKickOutOneTeamByPlayerImplementation","AddReportedCount","AddInspectionRecord","BanPlayerByInspection","BroadCastToAllInspector","ServerReportToInspectorImplementation","InitPlayerInspectionInfo"})
end)

pcall(function()
    local tlogModules = {
        "client.network.Protocol.ClientTlogHandler",
        "client.network.Protocol.BattleReportHandler",
        "client.network.Protocol.ClientErrorReportHandler",
        "client.network.Protocol.LobbyPingReportHandler",
        "client.slua.config.tlog.tlog_report_utils",
        "client.slua.data.BasicData.BasicDataTLogReport",
        "client.slua.data.BasicData.BasicDataClientReport",
        "client.slua.data.BasicData.BasicDataReport",
        "GameLua.Mod.BaseMod.DS.Security.DSCommonTLogSubsystem",
        "GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem",
        "GameLua.Mod.BaseMod.DS.Security.DSSecurityTLogSubsystem",
        "GameLua.Mod.BaseMod.Client.Security.ClientDataStatistcsSubsystem"
    }
    for _, path in ipairs(tlogModules) do killReportFuncs(package.loaded[path]) end
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
    if ClientError then ClientError.send_client_error_report = nop; ClientError.send_client_crash_report = nop;
        ClientError.send_client_tools_batch_report_req = nop end
    local BattleReport = package.loaded["client.network.Protocol.BattleReportHandler"]
    if BattleReport then
        BattleReport.send_battle_report = nop; BattleReport.send_battle_result = nop;
        BattleReport.send_vod_game_report_req = nop; BattleReport.send_batch_get_vod_info_req = nop;
        BattleReport.send_get_game_report_req = nop; BattleReport.send_batch_get_game_report_req = nop;
        BattleReport.send_get_game_report_by_uid_req = nop
    end
    local BugHandler = package.loaded["client.network.Protocol.BugHandler"]
    if BugHandler then BugHandler.send_report_bug_info = nop; BugHandler.send_report_bug_feedback = nop end
    local PingReport = package.loaded["client.network.Protocol.LobbyPingReportHandler"]
    if PingReport then PingReport.send_lobby_ping_report = nop; PingReport.send_ingame_ping_report = nop end
    local WeekReport = package.loaded["client.network.Protocol.WeekRportHandler"]
    if WeekReport then WeekReport.send_week_report = nop; WeekReport.send_week_detail = nop end
    local LogicComplaint = package.loaded["client.logic.battle.logic_complaint"]
    if LogicComplaint then LogicComplaint.SendComplaintReq = nop; LogicComplaint.Submit = nop;
        LogicComplaint.ReportPlayer = nop; LogicComplaint.ShowComplaint = nop; LogicComplaint.ShowHandle = nop end
    local OBResult = package.loaded["GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.EscapeBattleResultShowOBResultLogic"]
    if OBResult then OBResult.OnBattleResult = nop; OBResult.OnResultProcessStart = nop end
    local NormalOBResult = package.loaded["GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.BattleResultShowOBResultLogic"]
    if NormalOBResult then NormalOBResult.OnBattleResult = nop; NormalOBResult.OnResultProcessStart = nop end
    local ShowResult = package.loaded["GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.BattleResultShowResultLogic"]
    if ShowResult then
        ShowResult.OnBattleResult = nop; ShowResult.OnResultProcessStart = nop; ShowResult.OnResultProcessContinue = nop;
        ShowResult.ReceiveData = nop; ShowResult.SendEndFlow = nop; ShowResult.OnReport = nop;
        ShowResult.ShowResult = nop; ShowResult.ShowResultInternal = nop; ShowResult.StopResultProcess = nop
    end
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
    if ClientDataStat then ClientDataStat.StartToCheck = nop; ClientDataStat.OnReceiveRTT = nop;
        ClientDataStat.OnReceiveJitter = nop; ClientDataStat.ReportAbnormal = nop; ClientDataStat.ResetData = nop end
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
    if VoiceDoctor then
        local orig = VoiceDoctor.UploadVoiceLog
        VoiceDoctor.UploadVoiceLog = function(self, ...)
            if orig then pcall(orig, self, ...) end
        end
        VoiceDoctor.UploadVoiceException = nop
    end
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
    if DataLayer then
        local orig = DataLayer.OnSpectatorReplayChanged
        if orig then DataLayer.OnSpectatorReplayChanged = function(dlSelf) _G.IsBeingWatched = true; orig(dlSelf) end end
    end
    local DSActive = safe_require("GameLua.Mod.PlanBT.Gameplay.Subsystem.DSActiveSubsystem")
    if DSActive then DSActive.DelayKickOutPlayer = nop; DSActive.ActiveKickNotify = nop end
    local CreativeDev = safe_require("GameLua.Mod.CreativeBase.Gameplay.Subsystem.CreativeDevDebugSubsystem")
    if CreativeDev then CreativeDev.IsDebugPanelEnalbedCli = nop end
    local CreativeDeath = safe_require("GameLua.Mod.CreativeBase.Gameplay.Subsystem.CreativeModeDeathRecordSubsystem")
    if CreativeDeath then CreativeDeath.OnPlayerKilled = nop end
    if _G.ClientReplayDataReporter then
        _G.ClientReplayDataReporter.ReportIntArrayData = nop
        _G.ClientReplayDataReporter.ReportFloatArrayData = nop
    end
    local SpectateReplay = safe_require("GameLua.Mod.BaseMod.Common.Subsystem.SpectateAndReplaySubsystem")
    if SpectateReplay then SpectateReplay.RequestGotoSpectatingImp = nop; SpectateReplay.RequestGotoSpectating = nop end
    local AIReplay = safe_require("GameLua.ExtraModule.MLAI.Client.AIReplaySubsystem")
    if AIReplay then
        AIReplay.ReportAllPlayerInfo = nop; AIReplay.ReportFrameData = nop; AIReplay.ReportPlayerInput = nop
        if AIReplay.uCompletePlayBack then
            AIReplay.uCompletePlayBack.AddRecordMLAIInfo = nop
            AIReplay.uCompletePlayBack.StopRecording = nop
        end
    end
    local AITracking = safe_require("GameLua.Mod.BaseMod.GamePlay.AI.AITrackingLogSubsystem")
    if AITracking then
        AITracking.RealLogoutTimer = nop; AITracking.LogQueue = {}; AITracking.AddToLogQue = nop
        AITracking.DoPrint = nop; AITracking.OnAIPawnDied = nop; AITracking.OnAIPawnReceiveDamage = nop
        AITracking.OnAIPawnEnemyChange = nop
    end
    local DataMgr = package.loaded["client.slua.logic.data.data_mgr"]
    if DataMgr then DataMgr.GetWeaponSkinSoundVolumeInfoByGroup = retZero end
    local CreditLogic = safe_require("GameLua.Mod.BaseMod.Client.ClientInGameCreditLogic")
    if CreditLogic then
        CreditLogic._SendUserReaction2ExitTeamBeforeBoardingReturnLobbyNotice = nop
        CreditLogic.ShowReturnLobbyIfFirstExitTeamBeforeBoarding = retFalse
        CreditLogic.OnReceiveCreditScoreChange = nop
        CreditLogic._IsFirstExitTeamBeforeBoardingReturnLobbyNoticeEnabled = retFalse
        CreditLogic.SetFirstExitTeamBeforeBoardingReturnLobbyNoticeEnabled = nop
    end
end)

local globalFuncs = {
    "ReportTLogEvent","SendTlog","SendClientStats","ReportHitFlow","ReportAvatarException",
    "SendComplaintReq","SubmitReport","ReportSuspiciousPlayer","SendPacket","OnSyncBanInfo",
    "OnVoiceBanNotify","SendSecTLog","MarkSuspiciousPlayer","ReportPlayerBehaviorData",
    "CheckCompliance","ReportIllegalProgram","UploadVoiceLog"
}
for _, fn in ipairs(globalFuncs) do
    if type(_G[fn]) == "function" then _G[fn] = nop end
end

-- Network / File Filtering (Safe: game servers not blocked)
local BLACKLIST_HOSTS = {
    "tss.tencent", "anticheatexpert", "crashsight", "bugly", "beacon", "helpshift",
    "tdm", "apm", "safeguard", "wetest", "analytics", "telemetry",
    "103.134.189.146", "down.anticheatexpert.com",
    "asia.csoversea.mbgame.anticheatexpert.com", "log.tav.qq",
    "logiservice.qcloud", "exp.helpshift"
}
local BLACKLIST_PORTS = {
    "10334", "11045", "12221", "13331", "8011", "8015", "9001", "20000", "20001", "20002", "20003", "20004",
    "20005", "19700", "1670", "19900", "14545", "10213", "8700", "25177", "10685", "10336", "10262"
}
local FILE_KEYWORDS = {
    "tlog","crash","bugly","report","beacon","wetest","analytics","telemetry","trace","dump",
    "exception","feedback","aps_log","mtp_detect","network_loss","client_error","ue4crash","tdm","gcloud"
}

local function isBlacklisted(str)
    if type(str) ~= "string" then return false end
    local low = str:lower()
    for _, kw in ipairs(BLACKLIST_HOSTS) do if low:find(kw,1,true) then return true end end
    for _, port in ipairs(BLACKLIST_PORTS) do if low:find(":"..port) or low:find("/"..port) then return true end end
    return false
end

pcall(function()
    if _G.HttpRequest then
        local orig = _G.HttpRequest
        _G.HttpRequest = function(url, ...)
            if isBlacklisted(url) then return nil end
            return orig(url, ...)
        end
    end
    if _G.FHttpModule and _G.FHttpModule.CreateRequest then
        local orig = _G.FHttpModule.CreateRequest
        _G.FHttpModule.CreateRequest = function(...)
            local url = select(1,...);
            if isBlacklisted(url) then return nil end
            return orig(...)
        end
    end
    local netMods = {
        "client.slua.logic.network.logic_network","client.slua.logic.download.report.puffer_tlog",
        "client.slua.data.BasicData.BasicDataClientReport","GameLua.GameCore.Module.Network.NetworkManager",
        "client.network.Protocol.ClientTlogHandler","client.network.Protocol.BattleReportHandler",
        "client.network.Protocol.ClientErrorReportHandler"
    }
    for _, mp in ipairs(netMods) do
        local mod = package.loaded[mp]
        if mod then
            for k, v in pairs(mod) do
                if type(v) == "function" and (k:find("Http") or k:find("Request") or k:find("Send") or
                    k:find("Upload") or k:find("Post") or k:find("Get") or k:find("Report")) then
                    local origf = v
                    mod[k] = function(...)
                        local args = {...}
                        for _, arg in ipairs(args) do
                            if type(arg)=="string" and isBlacklisted(arg) then return nil end
                        end
                        return pcall(origf, ...)
                    end
                end
            end
        end
    end
end)

local orig_io_open = io.open
io.open = function(path, mode)
    if type(path) == "string" then
        local lp = path:lower()
        for _, kw in ipairs(FILE_KEYWORDS) do
            if lp:find(kw) then
                if mode and (mode == "w" or mode == "a" or mode == "w+" or mode == "a+") then return nil, "Blocked" end
            end
        end
    end
    return orig_io_open(path, mode)
end

if _G.UnrealEngine and _G.UnrealEngine.CrashContext then
    _G.UnrealEngine.CrashContext = { SetCrashContext = nop, ReportCrash = nop, AddCrashData = nop }
end

local FakeData = {
    ping = function() return math.random(20, 45) end,
    deviceID = function()
        local chars = "0123456789ABCDEF"
        local id = ""
        for _ = 1, 32 do id = id .. chars:sub(math.random(1, #chars), math.random(1, #chars)) end
        return id
    end,
    ipAddress = function() return "192.168." .. math.random(1, 255) .. "." .. math.random(1, 255) end,
    macAddress = function()
        return string.format("%02X:%02X:%02X:%02X:%02X:%02X",
            math.random(0,255), math.random(0,255), math.random(0,255),
            math.random(0,255), math.random(0,255), math.random(0,255))
    end,
}

local function KillTable(tbl, keys)
    if not tbl then return end
    for _, key in ipairs(keys) do
        pcall(function()
            if type(tbl[key]) == "function" then tbl[key] = nop else tbl[key] = nil end
        end)
    end
end

local SubsystemMgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
local function getSub(name)
    if SubsystemMgr then return SubsystemMgr:Get(name) end
end

local function BypassDeadEye()
    if BYPASS_STATE.DEADEYE_DISABLED then return end
    pcall(function()
        if _G.GameplayCallbacks then
            KillTable(_G.GameplayCallbacks, { "ReportAimFlow", "ReportHitFlow", "ReportAttackFlow",
                "OnAimDetected", "OnHeadshotDetected", "OnPerfectAccuracy" })
        end
        local aimTracker = getSub("ClientAimTrackingSubsystem")
        if aimTracker then
            aimTracker.GetAimData = function() return {accuracy = math.random(45, 65), headshotRate = math.random(15, 35)} end
            aimTracker.IsAimNormal = nop
        end
    end)
    BYPASS_STATE.DEADEYE_DISABLED = true
end

local function BypassHawkEye()
    if BYPASS_STATE.HAWKEYE_DISABLED then return end
    pcall(function()
        local hawkEye = getSub("ClientHawkEyePatrolSubsystem")
        if hawkEye then
            hawkEye.GetPatrolData = retEmpty
            hawkEye.IsBeingWatched = retFalse
            hawkEye.GetSpectatorCount = retZero
        end
        if _G.GameplayCallbacks then
            KillTable(_G.GameplayCallbacks, { "SendDSErrorLogToLobby", "SendDSHawkEyePatrolLogToLobby", "ReportMatchRoomData" })
        end
    end)
    BYPASS_STATE.HAWKEYE_DISABLED = true
end

local function BypassVoklai()
    if BYPASS_STATE.VOKLAI_DISABLED then return end
    pcall(function()
        local aiBehavior = getSub("ClientAIBehaviourSubsystem")
        if aiBehavior then
            aiBehavior.GetBehaviorScore = function() return math.random(10, 30) end
            aiBehavior.IsSuspicious = retFalse
            aiBehavior.GetRiskLevel = retZero
        end
        local stepCheck = getSub("ClientStepCheckSubsystem")
        if stepCheck then
            stepCheck.GetStepDelta = function() return math.random(5, 50) end
            stepCheck.IsMovementValid = nop
        end
        local speedHack = getSub("AntiSpeedHackSubsystem") or getSub("ClientAntiSpeedHackSubsystem")
        if speedHack then
            speedHack.GetSpeed = function() return math.random(300, 600) end
            speedHack.IsSpeedValid = nop
        end
    end)
    BYPASS_STATE.VOKLAI_DISABLED = true
end

local function BypassHiggsBoson()
    if BYPASS_STATE.HIGGSBOSON_DISABLED then return end
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if isValid(pc) then
            if pc.HiggsBoson then pc.HiggsBoson.bMHActive = false; pc.HiggsBoson.bCallPreReplication = false end
            if pc.HiggsBosonComponent then pc.HiggsBosonComponent.bMHActive = false; pcall(pc.HiggsBosonComponent.ControlMHActive, pc.HiggsBosonComponent, 0) end
        end
        local Higgs = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if Higgs then
            Higgs.GetNetAvatarItemIDs = function() return {1001, 2002, 3003, 4004, 5005} end
            Higgs.GetCurWeaponSkinID = retZero
            if Higgs.BlackList then Higgs.BlackList = {} end
        end
        _G.GlobalPlayerCoronaData = _G.GlobalPlayerCoronaData or {}
        local mt = getmetatable(_G.GlobalPlayerCoronaData) or {}
        mt.__newindex = function() end
        setmetatable(_G.GlobalPlayerCoronaData, mt)
        _G.BlackList = {}
    end)
    BYPASS_STATE.HIGGSBOSON_DISABLED = true
end

local function BypassHashVerification()
    if BYPASS_STATE.HASH_VERIFY_DISABLED then return end
    pcall(function()
        if _G.TssSdk then
            _G.TssSdk.ScanMemory = function() return true, {code = 0, msg = "clean"} end
            _G.TssSdk.ScanSo = function() return true, {code = 0, msg = "clean"} end
            _G.TssSdk.ScanFile = function() return true, {code = 0} end
            _G.TssSdk.GetRiskFlag = retZero
            _G.TssSdk.VerifyFileHash = nop
        end
        local integrity = getSub("ClientIntegrityCheckSubsystem")
        if integrity then KillTable(integrity, {"CheckFileHash", "VerifyMemory", "ScanModules"}) end
    end)
    BYPASS_STATE.HASH_VERIFY_DISABLED = true
end

local function BypassIPMapping()
    if BYPASS_STATE.IP_MAPPING_DISABLED then return end
    pcall(function()
        if _G.GameplayCallbacks then
            KillTable(_G.GameplayCallbacks, { "SendClientDeviceInfo", "ReportDeviceFingerprint", "SendNetworkInfo",
                "ReportIPAddress", "SendMACAddress", "ReportHardwareID" })
        end
        local deviceInfo = getSub("ClientDeviceInfoSubsystem")
        if deviceInfo then
            deviceInfo.GetDeviceID = FakeData.deviceID
            deviceInfo.GetIPAddress = FakeData.ipAddress
            deviceInfo.GetMACAddress = FakeData.macAddress
        end
    end)
    BYPASS_STATE.IP_MAPPING_DISABLED = true
end

local function BypassMemoryPatching()
    if BYPASS_STATE.MEMORY_PATCH_DISABLED then return end
    pcall(function()
        local kernelCheck = getSub("ClientKernelCheckSubsystem")
        if kernelCheck then
            kernelCheck.IsKernelClean = nop
            kernelCheck.GetKernelVersion = function() return "4.19." .. math.random(100,200) .. "-generic" end
            kernelCheck.IsBootloaderLocked = nop
        end
        local memoryGuard = getSub("ClientMemoryGuardSubsystem")
        if memoryGuard then
            memoryGuard.IsMemoryClean = function() return true, {code = 0} end
            memoryGuard.ScanResult = function() return "clean" end
        end
        if _G.TssSdk then
            _G.TssSdk.CheckKernel = function() return true, {status = "verified", tampered = false} end
            _G.TssSdk.VerifyBoot = function() return true, {locked = true, verified = true} end
        end
    end)
    BYPASS_STATE.MEMORY_PATCH_DISABLED = true
end

local function BypassEduEye()
    if BYPASS_STATE.EDU_EYE_DISABLED then return end
    pcall(function()
        local renderCheck = getSub("ClientRenderCheckSubsystem")
        if renderCheck then renderCheck.IsRenderClean = nop; renderCheck.GetRenderState = function() return "normal" end end
        local espDetection = getSub("ClientESPDetectionSubsystem")
        if espDetection then espDetection.HasESP = retFalse; espDetection.CheckOverlay = function() return "clean" end end
        local wallhackDetect = getSub("ClientWallhackDetectionSubsystem")
        if wallhackDetect then wallhackDetect.IsVisionNormal = nop; wallhackDetect.GetVisibilityRate = function() return math.random(60, 85) end end
    end)
    BYPASS_STATE.EDU_EYE_DISABLED = true
end

local function ApplyAllBypasses()
    if BYPASS_STATE.FULL_BYPASS_ACTIVE then return end
    pcall(function()
        BypassDeadEye(); BypassHawkEye(); BypassVoklai(); BypassHiggsBoson();
        BypassHashVerification(); BypassIPMapping(); BypassMemoryPatching(); BypassEduEye();
        BYPASS_STATE.FULL_BYPASS_ACTIVE = true
    end)
end

_G.GetBypassStatus = function()
    local s = BYPASS_STATE
    return { deadEye=s.DEADEYE_DISABLED, hawkEye=s.HAWKEYE_DISABLED, voklai=s.VOKLAI_DISABLED,
        higgsBoson=s.HIGGSBOSON_DISABLED, hashVerify=s.HASH_VERIFY_DISABLED,
        ipMapping=s.IP_MAPPING_DISABLED, memoryPatch=s.MEMORY_PATCH_DISABLED,
        eduEye=s.EDU_EYE_DISABLED, fullBypass=s.FULL_BYPASS_ACTIVE }
end

_G.ForceReapplyBypass = function()
    BYPASS_STATE.FULL_BYPASS_ACTIVE = false
    BYPASS_STATE.DEADEYE_DISABLED = false; BYPASS_STATE.HAWKEYE_DISABLED = false; BYPASS_STATE.VOKLAI_DISABLED = false
    BYPASS_STATE.HIGGSBOSON_DISABLED = false; BYPASS_STATE.HASH_VERIFY_DISABLED = false; BYPASS_STATE.IP_MAPPING_DISABLED = false
    BYPASS_STATE.MEMORY_PATCH_DISABLED = false; BYPASS_STATE.EDU_EYE_DISABLED = false
    ApplyAllBypasses()
end

pcall(ApplyAllBypasses)

pcall(function()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if pc and pc.AddGameTimer then
        pc:AddGameTimer(30.0, true, function()
            if not BYPASS_STATE.FULL_BYPASS_ACTIVE then pcall(ApplyAllBypasses) end
        end)
    end
end)

local function huntAndKillAll()
    pcall(function()
        local subNames = { "ClientHawkEyePatrolSubsystem","DSHawkEyePatrolSubsystem","ClientReportPlayerSubsystem",
            "DSReportPlayerSubsystem","ClientGlueHiaSystem","ClientDataStatistcsSubsystem",
            "ICTLogSubsystem","DSFightTLogSubsystem","DSSecurityTLogSubsystem","BehaviorScoreSubsystem" }
        if SubsystemMgr then
            for _, name in ipairs(subNames) do
                local sub = SubsystemMgr:Get(name)
                if sub then
                    for k, v in pairs(sub) do
                        if type(v) == "function" and (k:find("Report") or k:find("Send") or k:find("Log")) then
                            pcall(function() sub[k] = nop end)
                        end
                    end
                end
            end
        end
        local Higgs = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if Higgs then
            for _, m in ipairs({"ControlMHActive","TriggerAvatarCheck","StartAvatarCheck",
                "ReportItemID","ReceiveAnyDamage","OnWeaponHitRecord","ShowSecurityAlert","ServerReportAvatar",
                "ClientReportNetAvatar","SendHisarData"}) do
                if Higgs[m] then Higgs[m] = nop end
            end
        end
    end)
end

local function startPersistentTimer()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if pc and isValid(pc) then
        if _G._permHuntTimer then pcall(pc.RemoveGameTimer, pc, _G._permHuntTimer) end
        _G._permHuntTimer = pc:AddGameTimer(30.0, true, huntAndKillAll)
        return true
    end
    return false
end

local function finalStart()
    if startPersistentTimer() then
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if pc and isValid(pc) then
            local pawn = pc:GetCurPawn()
            if isValid(pawn) then
                pcall(function()
                    local Higgs = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
                    if Higgs then Higgs.ControlMHActive = nop; Higgs.TriggerAvatarCheck = nop end
                end)
            end
        end
    else
        local fb = slua_GameFrontendHUD or Game
        if fb and isValid(fb) then fb:AddGameTimer(2.0, false, finalStart) end
    end
end
finalStart()

local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")

local function IsPawnAlive(p)
    if not slua.isValid(p) then return false end
    if p.HealthStatus then return SecurityCommonUtils.IsHealthStatusAlive(p.HealthStatus) end
    if p.IsAlive then return p:IsAlive() end
    return p.GetHealth and (p:GetHealth() or 0) > 0 or false
end
local function GetPawnHealthRatio(p)
    local hp = p.GetHealth and p:GetHealth() or 100; local maxHp = p.GetHealthMax and p:GetHealthMax() or 100
    return math.max(0, math.min(1, hp / (maxHp <= 0 and 100 or maxHp)))
end
local function SetRedFrameUI(p)
    if not slua.isValid(p) then return end
    local COLOR_RED = FLinearColor(1,0,0,1)
    if p.Replay_SetFrameUIColor then p:Replay_SetFrameUIColor(COLOR_RED)
    elseif p.SetEnemyFrameColor then p:SetEnemyFrameColor(COLOR_RED)
    elseif p.SetFrameColor then p:SetFrameColor(COLOR_RED)
    elseif p.SetOutlineColor then p:SetOutlineColor(COLOR_RED) end
end

local MOD_EXPIRY = { year = 2026, month = 6, day = 30, hour = 0, min = 1, sec = 0 }
local function safe_os_time(tbl)
    if os and os.time then return os.time(tbl) end
    return 0
end
local MOD_EXPIRY_TS = safe_os_time(MOD_EXPIRY)
function _G.isModExpired()
    return safe_os_time() > MOD_EXPIRY_TS
end

local FEATURE_DIR = _G._FEATURE_DIR or "/storage/emulated/0/Android/data/com.pubg.imobile/files/GOKUCONFIG/"
local CONFIG_FILE = FEATURE_DIR .. "settings.json"

local function simple_encode(t)
    local parts = {}
    for k, v in pairs(t) do
        table.insert(parts, string.format("%s=%s", k, tostring(v)))
    end
    return table.concat(parts, ";")
end

local function simple_decode(s)
    local t = {}
    for k, v in string.gmatch(s, "([%w_]+)=([%w_]+)") do
        t[k] = v == "true" and true or v == "false" and false or tonumber(v) or v
    end
    return t
end

function _G.SaveConfig()
    local cfg = {
        ESPEnabled = _G.MOD_ESPEnabled,
        EnemyCounterEnabled = _G.MOD_EnemyCounterEnabled,
        MapTrackingEnabled = _G.MOD_MapTrackingEnabled,
        NoGrassEnabled = _G.MOD_NoGrassEnabled,
        AimAssistEnabled = _G.Mod_AimAssist_Enabled,
        NoRecoilEnabled = _G.Mod_NoRecoil_Enabled,
        FPS165Enabled = _G.Mod_FPS165_Enabled,
        iPadViewEnabled = _G.Mod_iPadView_Enabled,
    }
    local f = io.open(CONFIG_FILE, "w")
    if f then
        local ok, json = pcall(require, "json")
        local data = ok and json.encode(cfg) or simple_encode(cfg)
        f:write(data)
        f:close()
    end
end

local function LoadConfig()
    local f = io.open(CONFIG_FILE, "r")
    if not f then return end
    local content = f:read("*all"); f:close()
    if not content or content == "" then return end
    local ok, json = pcall(require, "json")
    local cfg = ok and json.decode(content) or simple_decode(content)
    if type(cfg) ~= "table" then return end
    _G.MOD_ESPEnabled = cfg.ESPEnabled ~= nil and cfg.ESPEnabled or _G.MOD_ESPEnabled
    _G.MOD_EnemyCounterEnabled = cfg.EnemyCounterEnabled ~= nil and cfg.EnemyCounterEnabled or _G.MOD_EnemyCounterEnabled
    _G.MOD_MapTrackingEnabled = cfg.MapTrackingEnabled ~= nil and cfg.MapTrackingEnabled or _G.MOD_MapTrackingEnabled
    _G.MOD_NoGrassEnabled = cfg.NoGrassEnabled ~= nil and cfg.NoGrassEnabled or _G.MOD_NoGrassEnabled
    _G.Mod_AimAssist_Enabled = cfg.AimAssistEnabled ~= nil and cfg.AimAssistEnabled or _G.Mod_AimAssist_Enabled
    _G.Mod_NoRecoil_Enabled = cfg.NoRecoilEnabled ~= nil and cfg.NoRecoilEnabled or _G.Mod_NoRecoil_Enabled
    _G.Mod_FPS165_Enabled = cfg.FPS165Enabled ~= nil and cfg.FPS165Enabled or _G.Mod_FPS165_Enabled
    _G.Mod_iPadView_Enabled = cfg.iPadViewEnabled ~= nil and cfg.iPadViewEnabled or _G.Mod_iPadView_Enabled
end

_G.MOD_ESPEnabled = true
_G.MOD_EnemyCounterEnabled = true
_G.MOD_MapTrackingEnabled = true
_G.MOD_NoGrassEnabled = true
if _G.Mod_AimAssist_Enabled == nil then _G.Mod_AimAssist_Enabled = true end
if _G.Mod_NoRecoil_Enabled == nil then _G.Mod_NoRecoil_Enabled = true end
if _G.Mod_FPS165_Enabled == nil then _G.Mod_FPS165_Enabled = false end
if _G.Mod_iPadView_Enabled == nil then _G.Mod_iPadView_Enabled = false end
LoadConfig()

local function ApplyNoGrass()
    pcall(function()
        local gi = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
        if gi then
            if _G.MOD_NoGrassEnabled then
                gi:ExecuteCMD("grass.DensityScale", "0"); gi:ExecuteCMD("grass.DiscardDataOnLoad", "1")
                gi:ExecuteCMD("r.Water.SingleLayer.Enable", "0"); gi:ExecuteCMD("r.Show.Water", "0"); gi:ExecuteCMD("r.Show.Translucency", "0"); gi:ExecuteCMD("r.DisableWaterRender", "1")
                gi:ExecuteCMD("r.SkyAtmosphere", "0"); gi:ExecuteCMD("r.Atmosphere", "0"); gi:ExecuteCMD("r.Fog", "0"); gi:ExecuteCMD("r.VolumetricFog", "0"); gi:ExecuteCMD("r.DisableSkyRender", "1")
            else
                gi:ExecuteCMD("grass.DensityScale", "1"); gi:ExecuteCMD("grass.DiscardDataOnLoad", "0")
                gi:ExecuteCMD("r.Water.SingleLayer.Enable", "1"); gi:ExecuteCMD("r.Show.Water", "1"); gi:ExecuteCMD("r.Show.Translucency", "1"); gi:ExecuteCMD("r.DisableWaterRender", "0")
                gi:ExecuteCMD("r.SkyAtmosphere", "1"); gi:ExecuteCMD("r.Atmosphere", "1"); gi:ExecuteCMD("r.Fog", "1"); gi:ExecuteCMD("r.VolumetricFog", "1"); gi:ExecuteCMD("r.DisableSkyRender", "0")
            end
        end
    end)
end

local aimOriginalCache = setmetatable({}, {__mode = "k"})
local AIM_BASE_VALUES = { Speed = 5.6, RangeRate = 2, SpeedRate = 1.3, RangeRateSight = 5.6, SpeedRateSight = 1.3, CrouchRate = 1.3, ProneRate = 1.3, DyingRate = 0 }
local function ApplyAimAssist()
    pcall(function()
        if not _G.Mod_AimAssist_Enabled then return end
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not isValid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not isValid(char) then return end
        local wm = char.WeaponManagerComponent; if not wm then return end
        local weapon = wm.CurrentWeaponReplicated; if not weapon then return end
        local entity = weapon.ShootWeaponEntityComp
        if not isValid(entity) or not entity.AutoAimingConfig then return end
        if not aimOriginalCache[entity] then
            local saved = {}
            for _, range in ipairs({"OuterRange", "InnerRange"}) do
                local cfg = entity.AutoAimingConfig[range]
                if cfg then
                    saved[range] = {}
                    for k, _ in pairs(AIM_BASE_VALUES) do if cfg[k] ~= nil then saved[range][k] = cfg[k] end end
                end
            end
            aimOriginalCache[entity] = saved
        end
        for _, range in ipairs({"OuterRange", "InnerRange"}) do
            local cfg = entity.AutoAimingConfig[range]
            if cfg then for k, v in pairs(AIM_BASE_VALUES) do cfg[k] = v end end
        end
    end)
end

local recoilOriginalCache = setmetatable({}, {__mode = "k"})
local RECOIL_FIELDS = { "RecoilKick","RecoilKickADS","AnimationKick","AccessoriesVRecoilFactor","AccessoriesHRecoilFactor","GameDeviationFactor","RecoilModifierStand","RecoilModifierCrouch","RecoilModifierProne","CameraShakeScale","AimCameraShakeScale","ShootCameraShakeScale","FireCameraShakeScale","GameDeviationAccuracy","ShotGunHorizontalSpread","ShotGunVerticalSpread","DeviationMultiplier" }
local RECOIL_TARGET = { RecoilKick=0.15, RecoilKickADS=0.2, AnimationKick=0.1, AccessoriesVRecoilFactor=0.4, AccessoriesHRecoilFactor=0.5, GameDeviationFactor=0.5, RecoilModifierStand=0.3, RecoilModifierCrouch=0.25, RecoilModifierProne=0.35, CameraShakeScale=0.15, AimCameraShakeScale=0.15, ShootCameraShakeScale=0.15, FireCameraShakeScale=0.15, GameDeviationAccuracy=0.2, ShotGunHorizontalSpread=0.2, ShotGunVerticalSpread=0.2, DeviationMultiplier=0.3 }
local RECOIL_INFO_FIELDS = { "VerticalRecoilMin","VerticalRecoilMax","RecoilSpeedVertical","RecoilSpeedHorizontal","VerticalRecoveryMax" }
local RECOIL_INFO_TARGET = { VerticalRecoilMin=0.3, VerticalRecoilMax=0.4, RecoilSpeedVertical=0.2, RecoilSpeedHorizontal=0.4, VerticalRecoveryMax=0.1 }
local function ApplyNoRecoil()
    pcall(function()
        if not _G.Mod_NoRecoil_Enabled then return end
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not isValid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not isValid(char) then return end
        local wm = char.WeaponManagerComponent; if not wm then return end
        local weapon = wm.CurrentWeaponReplicated; if not weapon then return end
        local entity = weapon.ShootWeaponEntityComp
        if not isValid(entity) then return end
        if not recoilOriginalCache[entity] then
            local saved = { RecoilInfo = {} }
            for _, f in ipairs(RECOIL_FIELDS) do if entity[f] ~= nil then saved[f] = entity[f] end end
            if entity.RecoilInfo then
                for _, f in ipairs(RECOIL_INFO_FIELDS) do if entity.RecoilInfo[f] ~= nil then saved.RecoilInfo[f] = entity.RecoilInfo[f] end end
            end
            recoilOriginalCache[entity] = saved
        end
        for k, v in pairs(RECOIL_TARGET) do entity[k] = v end
        if entity.RecoilInfo then for k, v in pairs(RECOIL_INFO_TARGET) do entity.RecoilInfo[k] = v end end
        if entity.ShootCameraShake then entity.ShootCameraShake.Scale = 0.15 end
    end)
end

local _FPS165_Applied = false
local function Apply165FPS()
    if _FPS165_Applied or not _G.Mod_FPS165_Enabled then return end
    _FPS165_Applied = true
    pcall(function()
        local graphics = require("client.slua.logic.setting.logic_setting_graphics")
        local fpsComp = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
        local fpsFT = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
        local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
        if graphics then
            local orig = graphics.SetFPS
            function graphics:SetFPS(lvl)
                if orig then orig(self, lvl) end
                if lvl == 8 then
                    self:ExecuteCMD("t.MaxFPS", "165"); self:ExecuteCMD("r.FrameRateLimit", "165")
                end
            end
        end
        if fpsComp and fpsComp.__inner_impl then
            local impl = fpsComp.__inner_impl
            impl.GetMaxFPSLevel = function() return 8, 8 end
            impl.InitRealSupportFPS = function(self)
                local t = {}; for i=1,8 do t[i] = {true, true} end
                if db then db:UpdateUIData(db.RealSupportFPS, t, false) end
                return t
            end
            impl.UpdateSelectedFPSState = function(self, lvl)
                local fps = {[2]=20,[3]=25,[4]=30,[5]=40,[6]=60,[7]=90,[8]=120}
                for i=2,8 do
                    local node = self.UIRoot["NodeFps"..tostring(fps[i] or 120)]
                    if isValid(node) then
                        node:SetIsEnabled(true); pcall(function() node:SetRenderOpacity(1.0) end)
                        local sw = self.UIRoot["WidgetSwitcher_"..i]
                        if isValid(sw) then sw:SetActiveWidgetIndex(i == lvl and 0 or 1) end
                    end
                end
            end
        end
        if fpsFT and fpsFT.__inner_impl then
            local impl = fpsFT.__inner_impl; local MIN = 90
            impl.ShowOrHide = function(self) self:SelfHitTestInvisible(); if self.InitFPSFTSwitch then self:InitFPSFTSwitch() end end
            impl.InitFPSFTSwitch = function(self)
                local on = db:GetUIData(db.FPSFineTuneSwitch)
                if self.UIRoot.Setting_Switch then self.UIRoot.Setting_Switch:SetSwitcherEnable2(on, true) end
                if self.UIRoot.CanvasPanel_8 then self:SetWidgetVisible(self.UIRoot.CanvasPanel_8, on) end
                if self.UIRoot.WidgetSwitcher_0 then self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(2) end
                if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
            end
            impl.InitFPSFTValue165 = function(self)
                local r = self.UIRoot; local on = db:GetUIData(db.FPSFineTuneSwitch)
                local val = on and (db:GetUIData(db.FPSFineTuneNum) or 165) or 165
                if on then
                    r.Slider_screen3:SetLocked(false); r.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1,1,1,1)); r.Slider_screen3:SetSliderHandleColor(FLinearColor(1,1,1,1))
                else
                    r.Slider_screen3:SetLocked(true); r.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1,0.625,0.6,1)); r.Slider_screen3:SetSliderHandleColor(FLinearColor(1,0.625,0.6,1))
                end
                local norm = (val - MIN) / (165 - MIN)
                r.Veihclescreen3:SetText(tostring(val)); r.Slider_screen3:SetValue(norm); r.ProgressBar_screen3:SetPercent(norm)
            end
            impl.OnFPSFTValueChange3 = function(self, val)
                db:UpdateUIData(db.FPSFineTuneNum, val)
                if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
                local gi = db.GetGameInstance and db.GetGameInstance()
                if gi then gi:ExecuteCMD("t.MaxFPS", tostring(val)); gi:ExecuteCMD("r.FrameRateLimit", tostring(val)) end
            end
            impl.OnFPSFTAdd3 = function(self) local cur = db:GetUIData(db.FPSFineTuneNum) or MIN; self:OnFPSFTValueChange3(math.min(165, cur + 5)) end
            impl.OnFPSFTMinus3 = function(self) local cur = db:GetUIData(db.FPSFineTuneNum) or MIN; self:OnFPSFTValueChange3(math.max(MIN, cur - 5)) end
            impl.OnFPSFTAdd = impl.OnFPSFTAdd3; impl.OnFPSFTMinus = impl.OnFPSFTMinus3
        end
    end)
end

local ipadViewOrigCache = setmetatable({}, {__mode = "k"})
local IPAD_VIEW_FOV = 110
local function ApplyiPadView()
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not isValid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not isValid(char) or not char.ThirdPersonCameraComponent then return end
        local cam = char.ThirdPersonCameraComponent
        if _G.Mod_iPadView_Enabled then
            if not ipadViewOrigCache[char] then ipadViewOrigCache[char] = cam.FieldOfView or 80 end
            cam.FieldOfView = IPAD_VIEW_FOV
        else
            if ipadViewOrigCache[char] then
                cam.FieldOfView = ipadViewOrigCache[char]
                ipadViewOrigCache[char] = nil
            end
        end
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
function _G.ShowWelcomePopup()
    if welcomeShown then return end
    welcomeShown = true
    pcall(function()
        local Msg = GetMsgBox()
        Msg.Show(4, "GOKUCONFIG PREMIUM LUA", table.concat({
            "WELCOME TO GOKUCONFIG FRAMEWORK", "",
            "✓ ESP (Visuals)", "✓ Enemy Counter", "✓ Map Tracking", "✓ No Grass / Water / FOG",
            "✓ Aim Assist", "✓ Less Recoil", "✓ 165 FPS Unlock", "✓ iPad View (FOV)",
            "", "PLAY SAFE & ENJOY", "", "MADE BY - @GOKUCONFIG"
        }, "\n"), function() pcall(function() GetWebSDK():OpenURL("https://t.me/TGxGOKU_OFFICIAL") end) end)
    end)
end

local expiryDialogShown = false
function _G.ShowExpiryDialog()
    if expiryDialogShown then return end
    expiryDialogShown = true
    pcall(function()
        local Msg = GetMsgBox()
        Msg.Show(4, "[!] AUTHORIZATION TERMINATED", table.concat({
            "The operational license for this GOKU FRAMEWORK build has expired.",
            "To renew your secure access token, contact the framework architect:",
            "Telegram: @GOKUCONFIG"
        }, "\n"), function() pcall(function() GetWebSDK():OpenURL("https://t.me/GOKUCONFIG") end) end)
    end)
end

local SharedVisualAssistOwner = nil
function _G.InitModFeatures(character)
    if not Client or not character then return end
    if character._AssistTimer then return end
    if SharedVisualAssistOwner and SharedVisualAssistOwner ~= character then return end
    SharedVisualAssistOwner = character

    character._featureTimers = {
        character:AddGameTimer(1.0, true, ApplyNoGrass),
        character:AddGameTimer(0.2, true, ApplyAimAssist),
        character:AddGameTimer(0.2, true, ApplyNoRecoil),
    }
    Apply165FPS()
    character._featureTimers[4] = character:AddGameTimer(0.5, true, ApplyiPadView)

    local cachedMarks = setmetatable({}, {__mode = "k"})
    local frameApplied = {}; local lastPawnRefresh = 0; local cachedPawns = {}
    local baseEspDelay = 0.15
    local ASTExtraPlayerController = import("/Script/ShadowTrackerExtra.STExtraPlayerController")
    character._AssistTimer = character:AddGameTimer(baseEspDelay, true, function()
        if not _G.MOD_ESPEnabled and not _G.MOD_EnemyCounterEnabled then
            for pawnPtr, markId in pairs(cachedMarks) do if markId then InGameMarkTools.HideMapMark(markId) end end
            cachedMarks = setmetatable({}, {__mode = "k"}); frameApplied = {}
            return
        end
        if not slua.isValid(character.Object) then
            for _, markId in pairs(cachedMarks) do if type(markId) ~= "table" and markId then InGameMarkTools.HideMapMark(markId) end end
            SharedVisualAssistOwner = nil; return
        end
        local uCon = slua_GameFrontendHUD:GetPlayerController()
        if not (slua.isValid(uCon) and Game:IsClassOf(uCon, ASTExtraPlayerController)) then return end
        local currentPawn = uCon:GetCurPawn()
        if not slua.isValid(currentPawn) then return end
        local myTeamId, myPos = currentPawn.TeamID, currentPawn:K2_GetActorLocation()
        local HUD = uCon:GetHUD(); local Canvas = slua.isValid(HUD) and HUD.Canvas or nil
        local now = os.clock()
        if now - lastPawnRefresh > 1.5 then
            lastPawnRefresh = now; cachedPawns = Game:GetAllPlayerPawns() or {}
            for pawnPtr, markId in pairs(cachedMarks) do
                local found = false
                for _, p in pairs(cachedPawns) do if p == pawnPtr then found = true break end end
                if not found then
                    if markId then InGameMarkTools.HideMapMark(markId) end
                    cachedMarks[pawnPtr] = nil; frameApplied[pawnPtr] = nil
                end
            end
        end
        local botCount, enemyCount = 0, 0
        for _, tPawn in pairs(cachedPawns) do
            if slua.isValid(tPawn) and tPawn ~= currentPawn and tPawn.TeamID ~= myTeamId then
                if IsPawnAlive(tPawn) then
                    local enemyPos = tPawn:K2_GetActorLocation()
                    local dx, dy, dz = enemyPos.X - myPos.X, enemyPos.Y - myPos.Y, enemyPos.Z - myPos.Z
                    local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                    local isBot = false; pcall(function() isBot = Game:IsAI(tPawn) end)
                    if isBot then botCount = botCount + 1 else enemyCount = enemyCount + 1 end
                    if dist < 30000 then
                        if _G.MOD_ESPEnabled then
                            if not frameApplied[tPawn] then
                                if tPawn.Replay_CreateEnemyFrameUI then tPawn:Replay_CreateEnemyFrameUI(true, true) end
                                SetRedFrameUI(tPawn)
                                if tPawn.Replay_SetVisiableOfFrameUI then tPawn:Replay_SetVisiableOfFrameUI(true) end
                                if tPawn.SetPlayerNameVisible then tPawn:SetPlayerNameVisible(true) end
                                frameApplied[tPawn] = true
                            end
                            local headPos, rootPos
                            if dist > 150000 then headPos = enemyPos + FVector(0,0,85); rootPos = enemyPos - FVector(0,0,85)
                            else
                                local realHead = tPawn:GetHeadLocation(false)
                                headPos = realHead or (enemyPos + FVector(0,0,85))
                                rootPos = realHead and (enemyPos - FVector(0,0,90)) or (enemyPos - FVector(0,0,85))
                            end
                            if not cachedMarks[tPawn] then
                                cachedMarks[tPawn] = InGameMarkTools.ClientAddMapMark(1006, headPos, 0, "", 4, tPawn)
                            else
                                InGameMarkTools.UpdateMapMarkLocation(cachedMarks[tPawn], headPos)
                            end
                            if Canvas then
                                local headScreen, rootScreen = FVector2D(0,0), FVector2D(0,0)
                                if uCon:ProjectWorldLocationToScreen(headPos, false, headScreen) and uCon:ProjectWorldLocationToScreen(rootPos, false, rootScreen) then
                                    local screenHeight = math.max(25, math.abs(headScreen.Y - rootScreen.Y))
                                    local scaleFactor = math.max(0.3, math.min(1.5, 15000 / math.max(10000, dist)))
                                    local barWidth, barHeight = 4 * scaleFactor, screenHeight * scaleFactor
                                    local barX, barY = headScreen.X - (barWidth * 1.5), headScreen.Y
                                    local hp = GetPawnHealthRatio(tPawn)
                                    local COLOR_HP_GREEN = FLinearColor(0,1,0,0.95); local COLOR_HP_YELLOW = FLinearColor(1,1,0,0.95); local COLOR_HP_RED = FLinearColor(1,0,0,0.95); local COLOR_BG = FLinearColor(0,0,0,0.55)
                                    local color = hp < 0.3 and COLOR_HP_RED or (hp < 0.6 and COLOR_HP_YELLOW or COLOR_HP_GREEN)
                                    Canvas:K2_DrawBox(FVector2D(barX, barY), FVector2D(barWidth, barHeight), 1, COLOR_BG)
                                    Canvas:K2_DrawBox(FVector2D(barX, barY + barHeight * (1 - hp)), FVector2D(barWidth, barHeight * hp), 1, color)
                                end
                            end
                        end
                    else
                        if tPawn.Replay_SetVisiableOfFrameUI then tPawn:Replay_SetVisiableOfFrameUI(false) end
                        if cachedMarks[tPawn] then InGameMarkTools.HideMapMark(cachedMarks[tPawn]); cachedMarks[tPawn] = nil end
                        frameApplied[tPawn] = nil
                    end
                else
                    if tPawn.Replay_SetVisiableOfFrameUI then tPawn:Replay_SetVisiableOfFrameUI(false) end
                    if cachedMarks[tPawn] then InGameMarkTools.HideMapMark(cachedMarks[tPawn]); cachedMarks[tPawn] = nil end
                    frameApplied[tPawn] = nil
                end
            end
        end
        if _G.MOD_EnemyCounterEnabled and slua.isValid(HUD) and slua.isValid(currentPawn) then
            HUD:AddDebugText("[ BOTS: "..botCount.." ]  [ ENEMIES: "..enemyCount.." ]", currentPawn, 1, FVector(0,0,170), FVector(0,0,170), {R=255,G=255,B=255,A=255}, true, false, true, nil, 1.0, true)
        end
    end)
end
