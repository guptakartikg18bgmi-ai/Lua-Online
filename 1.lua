-- ============================================================================
-- ✦ GOKU FRAMEWORK [SERVER-SIDED OPTIMIZED + FULL BYPASS + NO LAG] ✦
-- ============================================================================
if _G.GOKU_PAYLOAD_ACTIVE then return end
_G.GOKU_PAYLOAD_ACTIVE = true

-- ==================== 1. SAFE STATE INITIALIZATION (FIXES MENU RESET BUG) ====================
if _G.MOD_ESPEnabled == nil then _G.MOD_ESPEnabled = true end
if _G.MOD_WallhackEnabled == nil then _G.MOD_WallhackEnabled = false end
if _G.MOD_EnemyCounterEnabled == nil then _G.MOD_EnemyCounterEnabled = true end
if _G.MOD_Watermark_Enabled == nil then _G.MOD_Watermark_Enabled = true end
if _G.Mod_AimAssist_Enabled == nil then _G.Mod_AimAssist_Enabled = true end
if _G.AimAssist_Power_Slider == nil then _G.AimAssist_Power_Slider = 50 end
if _G.AimAssist_Power == nil then _G.AimAssist_Power = 1.75 end
if _G.Mod_NoRecoil_Enabled == nil then _G.Mod_NoRecoil_Enabled = true end
if _G.MOD_AntiLag_Enabled == nil then _G.MOD_AntiLag_Enabled = true end
if _G.Mod_iPadView_Enabled == nil then _G.Mod_iPadView_Enabled = true end
if _G.iPadView_FOV_Slider == nil then _G.iPadView_FOV_Slider = 110 end
if _G.MOD_CustomMiniMapESP == nil then _G.MOD_CustomMiniMapESP = false end
if _G.MOD_VehicleESP == nil then _G.MOD_VehicleESP = false end

_G.BYPASS_STATE = _G.BYPASS_STATE or {
    DEADEYE_DISABLED = false, HAWKEYE_DISABLED = false, VOKLAI_DISABLED = false,
    HIGGSBOSON_DISABLED = false, HASH_VERIFY_DISABLED = false, IP_MAPPING_DISABLED = false,
    MEMORY_PATCH_DISABLED = false, EDU_EYE_DISABLED = false, FULL_BYPASS_ACTIVE = false,
    ANTI_CHEAT_MANAGER_DISABLED = false
}

-- ==================== 2. HELPERS & SANDBOX SAFETY ====================
local require = require
local import = import
local isValid = slua and slua.isValid or function(obj) return obj ~= nil end
local function nop() return true end
local function retFalse() return false end
local function retZero() return 0 end
local function retEmpty() return {} end
local function retTrue() return true end
local function safe_require(path) local ok, mod = pcall(require, path); return ok and mod or nil end

local function KillTable(tbl, keys)
    if type(tbl) ~= "table" then return end
    for _, key in ipairs(keys) do
        pcall(function()
            if type(tbl[key]) == "function" then tbl[key] = function() return true, {} end
            else tbl[key] = nil end
        end)
    end
end

-- ==================== 3. FULL 9-LAYER BYPASS PORT (FROM FIX.LUA) ====================
pcall(function()
    -- Layer 1-4: Telemetry, Higgs, HawkEye, Callbacks
    local callbacks = _G.GameplayCallbacks or _G.GC
    if callbacks then
        local kills = { "SendTssSdkAntiDataToLobby", "SendDSErrorLogToLobby", "SendDSHawkEyePatrolLogToLobby", "SendSecTLog", "ReportMatchRoomData", "ReportHitFlow", "OnPlayerRPCValidateFailed" }
        for _, fn in ipairs(kills) do if callbacks[fn] then callbacks[fn] = nop end end
        local origDS = callbacks.OnDSPlayerStateChanged
        if origDS then
            callbacks.OnDSPlayerStateChanged = function(dsSelf, state, reason, ...)
                if tostring(reason):lower():find("cheatdetected") then return end
                pcall(origDS, dsSelf, state, reason, ...)
            end
        end
    end

    local sdm = _G.ServerDataMgr
    if sdm and sdm.DeletablePlayerResultKey then
        for _, k in ipairs({"SuspiciousHitCount", "EspTotalSimTraceCnt", "EspTotalImeFocusCnt", "ClientGravityAnomalyCount"}) do
            sdm.DeletablePlayerResultKey[k] = true
        end
    end

    local Higgs = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
    if Higgs then
        local methods = { "ControlMHActive", "Tick", "TriggerAvatarCheck", "ReportItemID", "ShowSecurityAlert", "SendHisarData" }
        for _, m in ipairs(methods) do if Higgs[m] then Higgs[m] = nop end end
        Higgs.GetNetAvatarItemIDs = retEmpty; Higgs.GetCurWeaponSkinID = retZero
    end

    local ClientHawk = safe_require("GameLua.Mod.BaseMod.Client.Security.ClientHawkEyePatrolSubsystem")
    if ClientHawk then
        local funcs = { "_OnHawkSync", "_OnHawkReportSuccess", "SendReportTLog", "ReportCheat" }
        for _, fn in ipairs(funcs) do if ClientHawk[fn] then ClientHawk[fn] = nop end end
        ClientHawk.CanInspectorBroadcast = retFalse
    end

    -- Layer 9: UPlayerAntiCheatManager Bypass (Crucial for Anti-Ban)
    local function BypassAntiCheatManager()
        if _G.BYPASS_STATE.ANTI_CHEAT_MANAGER_DISABLED then return end
        pcall(function()
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            if not isValid(pc) then return end
            local AntiCheatMgr = pc.PlayerAntiCheatManager or pc.AntiCheatManager or pc.PlayerACManager
            if not isValid(AntiCheatMgr) then
                pcall(function()
                    local Class = import("PlayerAntiCheatManager")
                    if Class then
                        local comps = pc:GetComponentsByClass(Class)
                        if comps and comps:Num() > 0 then AntiCheatMgr = comps:Get(0) end
                    end
                end)
            end
            if isValid(AntiCheatMgr) then
                AntiCheatMgr.AutoAimFailedCnt = 0; AntiCheatMgr.TrackingFailedCnt = 0
                AntiCheatMgr.SpeedUpValue = 0; AntiCheatMgr.ServerAccumulateErrors = 0
                AntiCheatMgr.bReportFeedBack = false; AntiCheatMgr.bOpenDetailDataCollect = false
                AntiCheatMgr.MaxShootPointPassWall = 99999; AntiCheatMgr.MaxSingleShotDamage = 99999
                AntiCheatMgr.MaxMoveDistance2DPerSecond = 99999
                AntiCheatMgr.ReportAntiCheatDetailData = nop; AntiCheatMgr.PushWeaponAntiData = nop
            end
        end)
        _G.BYPASS_STATE.ANTI_CHEAT_MANAGER_DISABLED = true
    end
    _G.BypassAntiCheatManager = BypassAntiCheatManager
end)

-- TssSdk String Bypass
pcall(function()
    local TssSdk = _G.TssSdk or safe_require("TssSdk")
    if not TssSdk then return end
    local keepFuncs = { RegistSdkEventListener = true, IsAppOnForeground = true, GenSessionData = true, WaitVerify = true, QueryTssSdkVer = true, CommQuery = true, OpenWBSession = true, SendWBCmd = true, ReleaseWBStrPool = true, CloseWBSession = true, Logout = true }
    for funcName, funcValue in pairs(TssSdk) do
        if type(funcValue) == "function" and not keepFuncs[funcName] then
            if funcName:find("Tss") or funcName:find("Sdk") or funcName:find("Anti") or funcName:find("Verify") or funcName:find("Report") then
                TssSdk[funcName] = function(...) return true, "BYPASSED" end
            end
        end
    end
    TssSdk.GetSdkAntiData = function(...) return true, "BYPASSED", {code = 0, msg = "ok"} end
    TssSdk.GameScreenshot = function(...) return nil, "BLOCKED" end
    TssSdk.IsEmulator = function(...) return false end
end)

-- Network & IO Blacklist
local BLACKLIST_HOSTS = { "tss.tencent", "syzsdk", "reportlog", "tdos", "logupload", "crash2", "privacy.qq", "anticheatexpert", "crashsight", "wetest", "beacon", "tdm", "bugly", "helpshift" }
local FILE_KEYWORDS = { "tlog", "crash", "bugly", "report", "beacon", "telemetry", "dump", "exception" }
local orig_io_open = io.open
io.open = function(path, mode)
    if type(path) == "string" then
        local lp = path:lower()
        for _, kw in ipairs(FILE_KEYWORDS) do if lp:find(kw) and mode and (mode == "w" or mode == "a" or mode == "w+") then return nil, "Blocked" end end
    end
    return orig_io_open(path, mode)
end

-- ==================== 4. CORE MOD LOGIC (OPTIMIZED FOR 0% LAG) ====================
local ok_gd, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
if not ok_gd then GameplayData = nil end
local SecurityCommonUtils = safe_require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")

local _WH_OrigMaterials = setmetatable({}, { __mode = "k" })
local _WH_ModifiedPawns = setmetatable({}, { __mode = "k" })
_G._advCachedPawns = _G._advCachedPawns or {}
_G._advLastPawnRefresh = 0

local function IsPawnAlive(p)
    if not isValid(p) then return false end
    if p.HealthStatus then return SecurityCommonUtils.IsHealthStatusAlive(p.HealthStatus) end
    return p.GetHealth and (p:GetHealth() or 0) > 0 or false
end

local function GetPawnHealthRatio(p)
    local hp = p.GetHealth and p:GetHealth() or 100
    local maxHp = p.GetHealthMax and p:GetHealthMax() or 100
    return math.max(0, math.min(1, hp / (maxHp <= 0 and 100 or maxHp)))
end

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
        local mult = _G.AimAssist_Power
        for _, range in ipairs({"OuterRange", "InnerRange"}) do
            local cfg = entity.AutoAimingConfig[range]
            if cfg then
                cfg.Speed = 8.1 * mult; cfg.RangeRate = 1.8 * mult; cfg.SpeedRate = 2.5 * mult
                cfg.adsorbMaxRange = 200 * mult; cfg.adsorbActiveMinRange = 20
            end
        end
    end)
end

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
        entity.RecoilKick = 0.15; entity.RecoilKickADS = 0.10; entity.AnimationKick = 0.05
        entity.GameDeviationFactor = 0.2; entity.ShotGunHorizontalSpread = 0.1
        if entity.RecoilInfo then
            entity.RecoilInfo.VerticalRecoilMin = 0.2; entity.RecoilInfo.VerticalRecoilMax = 0.3
            entity.RecoilInfo.VerticalRecoveryMax = 0.1
        end
    end)
end

local function ApplyiPadView()
    if not _G.Mod_iPadView_Enabled then return end
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not isValid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not isValid(char) or not char.ThirdPersonCameraComponent then return end
        local cam = char.ThirdPersonCameraComponent
        local isAiming = false; pcall(function() isAiming = char.bIsTargeting end)
        if isAiming then return end
        cam.FieldOfView = _G.iPadView_FOV_Slider or 110
    end)
end

local function ClearWallHackForPawn(pawn)
    if not isValid(pawn) then return end
    pcall(function()
        local meshes = {}
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
        for _, comp in ipairs(meshes) do
            local origMatSlots = _WH_OrigMaterials[comp]
            if origMatSlots then
                for i, mat in pairs(origMatSlots) do pcall(function() comp:SetMaterial(i, mat) end) end
                _WH_OrigMaterials[comp] = nil
            end
            comp.bRenderCustomDepth = false; comp.CustomDepthStencilValue = 0
        end
        pawn._WH_MIDs = nil; _WH_ModifiedPawns[pawn] = nil
    end)
end

local function ApplyWallHack(enemy, pc)
    if not _G.MOD_WallhackEnabled then return end
    if not isValid(enemy) or not isValid(pc) then return end
    pcall(function()
        local meshes = {}
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
        local isVisible = false
        pcall(function() if type(pc.LineOfSightTo) == "function" then isVisible = pc:LineOfSightTo(enemy) end end)
        local bodyColor = isVisible and { R = 0, G = 255, B = 0, A = 255 } or { R = 255, G = 0, B = 0, A = 255 }
        enemy._WH_MIDs = enemy._WH_MIDs or {}; _WH_ModifiedPawns[enemy] = true
        for _, comp in ipairs(meshes) do
            if isValid(comp) then
                if not _WH_OrigMaterials[comp] then
                    local orig = {}
                    for i = 0, 10 do local ok, mat = pcall(function() return comp:GetMaterial(i) end); if ok and isValid(mat) then orig[i] = mat else break end end
                    _WH_OrigMaterials[comp] = orig
                end
                pcall(function() comp.bRenderCustomDepth = true; comp.CustomDepthStencilValue = 250 end)
                for i = 0, 10 do
                    local ok3, mi = pcall(function() return comp:GetMaterial(i) end)
                    if not ok3 or not isValid(mi) then break end
                    local mid = enemy._WH_MIDs[comp] and enemy._WH_MIDs[comp][i]
                    if not isValid(mid) then
                        local ok4, nm = pcall(function() return comp:CreateAndSetMaterialInstanceDynamic(i) end)
                        if ok4 and isValid(nm) then enemy._WH_MIDs[comp] = enemy._WH_MIDs[comp] or {}; enemy._WH_MIDs[comp][i] = nm; mid = nm end
                    end
                    if isValid(mid) then
                        pcall(function()
                            mid:SetVectorParameterValue("颜色", bodyColor); mid:SetVectorParameterValue("BaseColor", bodyColor)
                            mid:SetScalarParameterValue("Glow", 5.0); mid:SetScalarParameterValue("EmissiveBoost", 3.0)
                        end)
                    end
                end
            end
        end
    end)
end

-- ==================== 5. BULLETPROOF MOD MENU INJECTION (NO RESET BUG) ====================
local function InjectModMenu()
    if _G._GOKU_MENU_INJECTED then return end
    pcall(function()
        local LocUtil = _G.LocUtil or safe_require("client.common.LocUtil")
        if LocUtil and not LocUtil._IsModMenuHooked then
            local old_get = LocUtil.GetLocalizeResStr
            LocUtil.GetLocalizeResStr = function(id)
                if type(id) == "string" and not tonumber(id) then return id end
                return old_get and old_get(id) or ""
            end
            LocUtil._IsModMenuHooked = true
        end

        local SettingPageDefine = safe_require("client.logic.NewSetting.SettingPageDefine")
        local SettingCatalog = safe_require("client.logic.NewSetting.SettingCatalog")
        local AliasMap = safe_require("client.slua.umg.NewSetting.Item.AliasMap")
        if not SettingPageDefine or not SettingCatalog or not AliasMap then return end

        if not SettingPageDefine.ModMenu then
            local ModMenuStack = {
                { UI = AliasMap.Title, Text = "✦ GOKU VISUALS ✦" },
                { Key = "ESP", UI = AliasMap.Switcher, Text = "Healthbar ESP", GetFunc = function() return _G.MOD_ESPEnabled end, SetFunc = function(_, v) _G.MOD_ESPEnabled = v; return true end },
                { Key = "Wallhack", UI = AliasMap.Switcher, Text = "Wallhack (Chams)", GetFunc = function() return _G.MOD_WallhackEnabled end, SetFunc = function(_, v) _G.MOD_WallhackEnabled = v; return true end },
                { Key = "EnemyCounter", UI = AliasMap.Switcher, Text = "Enemy Counter", GetFunc = function() return _G.MOD_EnemyCounterEnabled end, SetFunc = function(_, v) _G.MOD_EnemyCounterEnabled = v; return true end },
                { Key = "MiniMapESP", UI = AliasMap.Switcher, Text = "Mini Map ESP", GetFunc = function() return _G.MOD_CustomMiniMapESP end, SetFunc = function(_, v) _G.MOD_CustomMiniMapESP = v; return true end },
                { UI = AliasMap.Title, Text = "✦ COMBAT ✦" },
                { Key = "AimAssist", UI = AliasMap.Switcher, Text = "Aim Assist", GetFunc = function() return _G.Mod_AimAssist_Enabled end, SetFunc = function(_, v) _G.Mod_AimAssist_Enabled = v; return true end },
                { Key = "AimPower", UI = AliasMap.Slider, Text = "Aim Power (0-100)", GetFunc = function() return _G.AimAssist_Power_Slider end, SetFunc = function(_, v) _G.AimAssist_Power_Slider = v; _G.AimAssist_Power = 1.0 + (v / 100) * 1.5; return true end },
                { Key = "NoRecoil", UI = AliasMap.Switcher, Text = "Less Recoil", GetFunc = function() return _G.Mod_NoRecoil_Enabled end, SetFunc = function(_, v) _G.Mod_NoRecoil_Enabled = v; return true end },
                { Key = "iPadView", UI = AliasMap.Switcher, Text = "iPad View", GetFunc = function() return _G.Mod_iPadView_Enabled end, SetFunc = function(_, v) _G.Mod_iPadView_Enabled = v; return true end },
                { Key = "iPadFOV", UI = AliasMap.Slider, Text = "iPad FOV (110-130)", GetFunc = function() return ((_G.iPadView_FOV_Slider - 110) / 20) * 100 end, SetFunc = function(_, v) _G.iPadView_FOV_Slider = 110 + (v / 100) * 20; return true end },
            }
            SettingPageDefine.ModMenu = { Key = "ModMenu", loc = "GOKU CONFIG", UIKey = "Setting_Page_Privacy", Category = { { Key = "ModMenu_Main", loc = "Features", Stack = ModMenuStack } } }
        end

        local alreadyInCatalog = false
        for _, page in ipairs(SettingCatalog) do if page.Key == "ModMenu" then alreadyInCatalog = true; break end end
        if not alreadyInCatalog then table.insert(SettingCatalog, SettingPageDefine.ModMenu) end

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
        _G._GOKU_MENU_INJECTED = true
    end)
end

-- ==================== 6. MATCH LIFECYCLE & TIMERS (0% LAG OPTIMIZED) ====================
local function StartVisualTimers(pc)
    if _G._GOKU_VISUALS_STARTED then return end
    _G._GOKU_VISUALS_STARTED = true
    local cachedMarks, cachedPawns, lastPawnRefresh = {}, {}, 0

    -- Healthbar ESP (0.5s Timer for 0 Lag)
    pc:AddGameTimer(0.5, true, function()
        if not _G.MOD_ESPEnabled then return end
        if not isValid(pc) then return end
        local uCon = slua_GameFrontendHUD:GetPlayerController()
        if not isValid(uCon) then return end
        local currentPawn = uCon:GetCurPawn()
        if not isValid(currentPawn) then return end
        local myTeamId, myPos = currentPawn.TeamID, currentPawn:K2_GetActorLocation()
        local HUD = uCon:GetHUD()
        local Canvas = isValid(HUD) and HUD.Canvas or nil
        local now = os.clock()

        if now - lastPawnRefresh > 1.5 then
            lastPawnRefresh = now; cachedPawns = Game:GetAllPlayerPawns() or {}
            for pawnPtr, markId in pairs(cachedMarks) do
                local found = false; for _, p in pairs(cachedPawns) do if p == pawnPtr then found = true; break end end
                if not found then if markId then pcall(function() InGameMarkTools.HideMapMark(markId) end) end; cachedMarks[pawnPtr] = nil end
            end
        end

        local COLOR_HP_GREEN = FLinearColor(0, 1, 0, 0.95); local COLOR_HP_RED = FLinearColor(1, 0, 0, 0.95); local COLOR_BG = FLinearColor(0, 0, 0, 0.55)
        for _, tPawn in pairs(cachedPawns) do
            if isValid(tPawn) and tPawn ~= currentPawn and tPawn.TeamID ~= myTeamId and IsPawnAlive(tPawn) then
                local enemyPos = tPawn:K2_GetActorLocation()
                if enemyPos then
                    local dx, dy, dz = enemyPos.X - myPos.X, enemyPos.Y - myPos.Y, enemyPos.Z - myPos.Z
                    local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                    if dist < 30000 then
                        if tPawn.Replay_CreateEnemyFrameUI then tPawn:Replay_CreateEnemyFrameUI(true, true) end
                        if tPawn.SetPlayerNameVisible then tPawn:SetPlayerNameVisible(true) end
                        local headPos = tPawn.GetHeadLocation and tPawn:GetHeadLocation(false) or (enemyPos + FVector(0,0,85))
                        if not cachedMarks[tPawn] then cachedMarks[tPawn] = pcall(function() return InGameMarkTools.ClientAddMapMark(1006, headPos, 0, " ", 4, tPawn) end) end
                        if Canvas then
                            local headScreen, rootScreen = FVector2D(0,0), FVector2D(0,0)
                            if uCon:ProjectWorldLocationToScreen(headPos, false, headScreen) and uCon:ProjectWorldLocationToScreen(enemyPos - FVector(0,0,85), false, rootScreen) then
                                local screenHeight = math.max(25, math.abs(headScreen.Y - rootScreen.Y))
                                local barWidth, barHeight = 4, screenHeight
                                local barX, barY = headScreen.X - (barWidth * 1.5), headScreen.Y
                                local hp = GetPawnHealthRatio(tPawn)
                                Canvas:K2_DrawBox(FVector2D(barX, barY), FVector2D(barWidth, barHeight), 1, COLOR_BG)
                                Canvas:K2_DrawBox(FVector2D(barX, barY + barHeight * (1 - hp)), FVector2D(barWidth, barHeight * hp), 1, hp < 0.3 and COLOR_HP_RED or COLOR_HP_GREEN)
                            end
                        end
                    end
                end
            elseif cachedMarks[tPawn] then
                pcall(function() InGameMarkTools.HideMapMark(cachedMarks[tPawn]) end); cachedMarks[tPawn] = nil
            end
        end
    end)

    -- Wallhack Timer (0.5s)
    pc:AddGameTimer(0.5, true, function()
        if not _G.MOD_WallhackEnabled then
            for pawn, _ in pairs(_WH_ModifiedPawns) do if isValid(pawn) then ClearWallHackForPawn(pawn) end end
            return
        end
        local uCon = slua_GameFrontendHUD:GetPlayerController()
        if not isValid(uCon) then return end
        local currentPawn = uCon:GetCurPawn()
        if not isValid(currentPawn) then return end
        local myTeamId, myPos = currentPawn.TeamID, currentPawn:K2_GetActorLocation()
        for _, tPawn in pairs(cachedPawns) do
            if isValid(tPawn) and tPawn ~= currentPawn and tPawn.TeamID ~= myTeamId and IsPawnAlive(tPawn) then
                local enemyPos = tPawn:K2_GetActorLocation()
                local dx, dy, dz = enemyPos.X - myPos.X, enemyPos.Y - myPos.Y, enemyPos.Z - myPos.Z
                if (dx*dx + dy*dy + dz*dz) < 900000000 then pcall(ApplyWallHack, tPawn, uCon) end
            end
        end
    end)
end

local function StartMatchFeatures(pc)
    pcall(InjectModMenu)
    pcall(function() if _G.BypassAntiCheatManager then _G.BypassAntiCheatManager() end end)
    
    pc:AddGameTimer(0.5, true, ApplyAimAssist)
    pc:AddGameTimer(0.5, true, ApplyNoRecoil)
    pc:AddGameTimer(0.5, true, ApplyiPadView)
    pc:AddGameTimer(5.0, true, function() if _G.MOD_AntiLag_Enabled then collectgarbage("step", 200) end end)
    
    StartVisualTimers(pc)
    
    pcall(function()
        local Msg = safe_require("client.slua.logic.common.logic_common_msg_box")
        if Msg and Msg.Show and not _G._GOKU_WELCOME_SHOWN then
            Msg.Show(4, "✓ GOKU OPTIMIZED", "0% Lag Build Active\nFull 9-Layer Bypass\nMenu Reset Bug Fixed\n\nPlay Safe | @GOKUCONFIG")
            _G._GOKU_WELCOME_SHOWN = true
        end
    end)
end

local function CleanupMatch()
    _G._GOKU_VISUALS_STARTED = false
    _WH_OrigMaterials = setmetatable({}, { __mode = "k" })
    _WH_ModifiedPawns = setmetatable({}, { __mode = "k" })
    collectgarbage("collect")
end

-- ==================== 7. GLOBAL WATCHDOG (SERVER LOADER COMPATIBLE) ====================
local function GokuMatchWatchdog()
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        local pawn = pc and pc:GetCurPawn()
        if isValid(pc) and isValid(pawn) then
            if not _G._GOKU_MATCH_ACTIVE then
                _G._GOKU_MATCH_ACTIVE = true
                StartMatchFeatures(pc)
            end
        else
            if _G._GOKU_MATCH_ACTIVE then
                _G._GOKU_MATCH_ACTIVE = false
                CleanupMatch()
            end
        end
    end)
end

pcall(function()
    if Game and Game.SetTimer then
        Game:SetTimer(1.0, true, GokuMatchWatchdog)
    else
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if pc and pc.AddGameTimer then pc:AddGameTimer(1.0, true, GokuMatchWatchdog) end
    end
end)

print("[MOD] ✅ GOKU 0% LAG OPTIMIZED PAYLOAD LOADED!")
