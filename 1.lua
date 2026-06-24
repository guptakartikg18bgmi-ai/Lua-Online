do
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if _G._MOD_LOADED and _G._MOD_PC == pc then return end
    _G._MOD_LOADED = true
    _G._MOD_PC = pc
end

local ok_gd, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
if not ok_gd then GameplayData = nil end
local Class = require("class")
local CharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CombineClass = require("combine_class")
local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
local IngamePhoneStateUI = require("GameLua.Mod.Library.Client.UI.IngamePhoneStateUI")
local SharedVisualAssistOwner = nil

local o_UpdateArtQualityUI = IngamePhoneStateUI.__inner_impl.UpdateArtQualityUI
IngamePhoneStateUI.__inner_impl.UpdateArtQualityUI = function(self, arg1, arg2)
    if o_UpdateArtQualityUI then o_UpdateArtQualityUI(self, arg1, arg2) end
    if self and self.UIRoot and self.UIRoot.TextBlock_quality then
        self.UIRoot.TextBlock_quality:SetText("GOKUCONFIG")
        local color = FLinearColor(1, 0, 0, 1)
        self.UIRoot.TextBlock_quality:SetColorAndOpacity(FSlateColor(color))
    end
end

local MOD_EXPIRY = { year = 2026, month = 6, day = 29, hour = 0, min = 1, sec = 0 }
local MOD_EXPIRY_TS = os.time(MOD_EXPIRY)
local function isModExpired()
    return os.time() > MOD_EXPIRY_TS
end

_G.MOD_ESPEnabled = true
_G.MOD_EnemyCounterEnabled = true
_G.MOD_WallhackEnabled = false
_G.MOD_BlackSkyEnabled = false
_G.MOD_MapTrackingEnabled = true
_G.MOD_NoGrassEnabled = true
_G.Mod_AimAssist_Enabled = true
_G.Mod_NoRecoil_Enabled = true
_G.Mod_iPadView_Enabled = true

local AIM_BASE_VALUES = {
    Speed = 8.1,
    RangeRate = 1.8,
    SpeedRate = 2.5,
    RangeRateSight = 5.5,
    SpeedRateSight = 1.4,
    CrouchRate = 1.2,
    ProneRate = 1.1,
    DyingRate = 0
}

local function ApplyEnvironment()
    local enableGrass = _G.MOD_NoGrassEnabled
    pcall(function()
        local gi = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
        if gi then
            if enableGrass then
                gi:ExecuteCMD("grass.DensityScale", "0")
                gi:ExecuteCMD("grass.DiscardDataOnLoad", "1")
            else
                gi:ExecuteCMD("grass.DensityScale", "1")
                gi:ExecuteCMD("grass.DiscardDataOnLoad", "0")
            end
        end
    end)
    if _G.MOD_BlackSkyEnabled then
        pcall(function()
            local gi = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
            if gi then gi:ExecuteCMD("r.CylinderMaxDrawHeight", "9999") end
        end)
    else
        pcall(function()
            local gi = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
            if gi then gi:ExecuteCMD("r.CylinderMaxDrawHeight", "0") end
        end)
    end
end

local aimOriginalCache = {}
local function ApplyAimAssist()
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not slua.isValid(char) then return end
        local wm = char.WeaponManagerComponent
        if not wm then return end
        local weapon = wm.CurrentWeaponReplicated
        if not weapon then return end
        local entity = weapon.ShootWeaponEntityComp
        if not slua.isValid(entity) or not entity.AutoAimingConfig then return end
        if _G.Mod_AimAssist_Enabled then
            if not aimOriginalCache[entity] then
                local saved = {}
                for _, range in ipairs({"OuterRange", "InnerRange"}) do
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
            for _, range in ipairs({"OuterRange", "InnerRange"}) do
                local cfg = entity.AutoAimingConfig[range]
                if cfg then for k, v in pairs(AIM_BASE_VALUES) do cfg[k] = v end end
            end
        else
            if aimOriginalCache[entity] then
                for _, range in ipairs({"OuterRange", "InnerRange"}) do
                    local cfg = entity.AutoAimingConfig[range]
                    if cfg then
                        local saved = aimOriginalCache[entity][range]
                        if saved then for k, v in pairs(saved) do cfg[k] = v end end
                    end
                end
                aimOriginalCache[entity] = nil
            end
        end
    end)
end

local recoilOriginalCache = {}
local RECOIL_FIELDS = { "RecoilKick","RecoilKickADS","AnimationKick","AccessoriesVRecoilFactor","AccessoriesHRecoilFactor","GameDeviationFactor","RecoilModifierStand","RecoilModifierCrouch","RecoilModifierProne","CameraShakeScale","AimCameraShakeScale","ShootCameraShakeScale","FireCameraShakeScale","GameDeviationAccuracy","ShotGunHorizontalSpread","ShotGunVerticalSpread","DeviationMultiplier" }
local RECOIL_TARGET_VALUES = {
    RecoilKick = 0.18,
    RecoilKickADS = 0.14,
    AnimationKick = 0.08,
    AccessoriesVRecoilFactor = 0.18,
    AccessoriesHRecoilFactor = 0.38,
    GameDeviationFactor = 0.38,
    RecoilModifierStand = 0.22,
    RecoilModifierCrouch = 0.18,
    RecoilModifierProne = 0.28,
    CameraShakeScale = 0.12,
    AimCameraShakeScale = 0.10,
    ShootCameraShakeScale = 0.10,
    FireCameraShakeScale = 0.10,
    GameDeviationAccuracy = 0.10,
    ShotGunHorizontalSpread = 0.15,
    ShotGunVerticalSpread = 0.15,
    DeviationMultiplier = 0.15
}
local RECOIL_INFO_FIELDS = { "VerticalRecoilMin","VerticalRecoilMax","RecoilSpeedVertical","RecoilSpeedHorizontal","VerticalRecoveryMax" }
local RECOIL_INFO_TARGET = { VerticalRecoilMin = 0.3, VerticalRecoilMax = 0.4, RecoilSpeedVertical = 0.2, RecoilSpeedHorizontal = 0.4, VerticalRecoveryMax = 0.1 }
local function ApplyNoRecoil()
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not slua.isValid(char) then return end
        local wm = char.WeaponManagerComponent
        if not wm then return end
        local weapon = wm.CurrentWeaponReplicated
        if not weapon then return end
        local entity = weapon.ShootWeaponEntityComp
        if not slua.isValid(entity) then return end
        if _G.Mod_NoRecoil_Enabled then
            if not recoilOriginalCache[entity] then
                local saved = { RecoilInfo = {} }
                for _, f in ipairs(RECOIL_FIELDS) do if entity[f] ~= nil then saved[f] = entity[f] end end
                if entity.RecoilInfo then
                    for _, f in ipairs(RECOIL_INFO_FIELDS) do if entity.RecoilInfo[f] ~= nil then saved.RecoilInfo[f] = entity.RecoilInfo[f] end end
                end
                if entity.ShootCameraShake then saved.ShootCameraShakeScale = entity.ShootCameraShake.Scale end
                recoilOriginalCache[entity] = saved
            end
            for k, v in pairs(RECOIL_TARGET_VALUES) do entity[k] = v end
            if entity.RecoilInfo then for k, v in pairs(RECOIL_INFO_TARGET) do entity.RecoilInfo[k] = v end end
            if entity.ShootCameraShake then entity.ShootCameraShake.Scale = 0.10 end
        else
            if recoilOriginalCache[entity] then
                local saved = recoilOriginalCache[entity]
                for k, _ in pairs(RECOIL_TARGET_VALUES) do if saved[k] ~= nil then entity[k] = saved[k] end end
                if entity.RecoilInfo and saved.RecoilInfo then
                    for k, _ in pairs(RECOIL_INFO_TARGET) do if saved.RecoilInfo[k] ~= nil then entity.RecoilInfo[k] = saved.RecoilInfo[k] end end
                end
                if entity.ShootCameraShake and saved.ShootCameraShakeScale then
                    entity.ShootCameraShake.Scale = saved.ShootCameraShakeScale
                end
                recoilOriginalCache[entity] = nil
            end
        end
    end)
end

local ipadViewOrigCache = setmetatable({}, {__mode = "k"})
local IPAD_VIEW_FOV = 110
local function ApplyiPadView()
    if not _G.Mod_iPadView_Enabled then
        for char, origFov in pairs(ipadViewOrigCache) do
            if slua.isValid(char) and char.ThirdPersonCameraComponent then
                pcall(function() char.ThirdPersonCameraComponent.FieldOfView = origFov end)
            end
            ipadViewOrigCache[char] = nil
        end
        return
    end
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not slua.isValid(char) or not char.ThirdPersonCameraComponent then return end
        local cam = char.ThirdPersonCameraComponent
        if not ipadViewOrigCache[char] then ipadViewOrigCache[char] = cam.FieldOfView or 80 end
        cam.FieldOfView = IPAD_VIEW_FOV
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
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            "WELCOME TO GOKUCONFIG FRAMEWORK",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            "✓ ESP (Visuals) 350m",
            "✓ Enemy Counter 350m",
            "✓ Wallhack (Red/Green) 350m",
            "✓ Black Sky (Manual)",
            "✓ Map Tracking",
            "✓ No Grass",
            "✓ Aim Assist (Updated)",
            "✓ Less Recoil (Optimized)",
            "✓ iPad View (FOV)",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            "PLAY SAFE & ENJOY",
            "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            "MADE BY - @GOKUCONFIG"
        }, "\n")
        Msg.Show(4, "GOKUCONFIG PREMIUM LUA", welcomeContent,
            function() pcall(function() GetWebSDK():OpenURL("https://t.me/TGxGOKU_OFFICIAL") end) end
        )
    end)
end
local lastExpiryDialogTime = 0
local function ShowExpiryDialog()
    local ct = os.clock()
    if ct - lastExpiryDialogTime < 5.0 then return end
    lastExpiryDialogTime = ct
    pcall(function()
        local Msg = GetMsgBox()
        local expiryContent = table.concat({
            "The operational license for this GOKU FRAMEWORK build has expired.",
            "",
            "Engineered for maximum security and strict gameplay safety, this framework enforces advanced access protocols to maintain environment integrity. Unregistered execution is permanently restricted.",
            "",
            "To renew your secure access token, contact the framework architect:",
            "Telegram: @GOKUCONFIG"
        }, "\n")
        Msg.Show(4, "[!] AUTHORIZATION TERMINATED", expiryContent,
            function() pcall(function() GetWebSDK():OpenURL("https://t.me/GOKUCONFIG") end) end
        )
    end)
end

local function DetectBasePath()
    local pkgs = {"com.tencent.ig","com.pubg.imobile","com.pubg.krmobile","com.vng.pubgmobile","com.rekoo.pubg"}
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
    if _G._FeaturesLoaded then return end
    local off = io.open(FEATURE_DIR .. ".off", "r")
    if off then off:close(); _G.ModsEnabled = false; _G._FeaturesLoaded = true; return end
    local hud = slua_GameFrontendHUD
    if not hud then return end
    local pc = hud:GetPlayerController()
    if _G._LastPC ~= pc then
        _G._LastPC = pc; _G.WelcomeShown = nil; _G.ESPLoaded = nil; _G.AimbotLoaded = nil; _G.WhiteBodyLoaded = nil
        _G.ModsEnabled = true; ShowWelcomePopup()
    elseif not _G.ModsEnabled then
        _G._LastPC = nil; _G.WelcomeShown = nil; _G.ESPLoaded = nil; _G.AimbotLoaded = nil; _G.WhiteBodyLoaded = nil
        _G.ModsEnabled = true; ShowWelcomePopup()
    end
    _G.ModsEnabled = true
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

if GameplayData then
    local COLOR_SAFE   = {R = 100, G = 240, B = 150, A = 255}
    local COLOR_DANGER = {R = 255, G = 80, B = 50, A = 255}
    local TEXT_OFFSET = {X = 0, Y = 0, Z = 15}
    local TEXT_SCALE  = 0.85
    local MAX_DIST_SQ = 1225000000
    local isValid = slua.isValid
    local function NearbyEnemyCounter()
        pcall(function()
            if not _G.MOD_EnemyCounterEnabled then return end
            local player = GameplayData.GetPlayerCharacter()
            if not isValid(player) then return end
            local pc = slua_GameFrontendHUD:GetPlayerController()
            if not isValid(pc) then return end
            local hud = pc:GetHUD()
            if not isValid(hud) then return end
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
            if enemyCount > 0 then text = "ENEMY: " .. enemyCount; color = COLOR_DANGER
            else text = "CLEAR"; color = COLOR_SAFE end
            hud:AddDebugText(text, player, 1, TEXT_OFFSET, TEXT_OFFSET, color, true, false, true, nil, TEXT_SCALE, true)
        end)
    end
    function StartEnemyCounterTimer()
        pcall(function()
            local pc = slua_GameFrontendHUD:GetPlayerController()
            if not isValid(pc) then pc = import("GameplayStatics").GetPlayerController(slua_GameFrontendHUD:GetWorld(), 0) end
            if not isValid(pc) then return end
            if _G.NEARBY_ENEMY_TIMER == pc then return end
            _G.NEARBY_ENEMY_TIMER = pc
            pc:AddGameTimer(0.2, false, function()
                local controller = slua_GameFrontendHUD:GetPlayerController()
                if isValid(controller) then controller:AddGameTimer(1.0, true, NearbyEnemyCounter) end   -- 1.0 sec
            end)
        end)
    end
end

local WH_COLOR_COVERED   = {R = 255, G = 0, B = 0, A = 255}
local WH_COLOR_VISIBLE   = {R = 0, G = 255, B = 0, A = 255}
local WH_GLOW_COVERED    = {R = 255, G = 0, B = 128, A = 255}
local WH_GLOW_VISIBLE    = {R = 0, G = 255, B = 255, A = 255}
local _WH_OrigMaterials = {}
local _WH_ModifiedPawns = {}
local _WH_ModifiedBaseMaterials = {}
local function ClearWallHackForPawn(pawn)
    if not slua.isValid(pawn) then return end
    local meshes = {}
    pcall(function()
        if slua.isValid(pawn.Mesh) then table.insert(meshes, pawn.Mesh) end
        local SkelClass = import("SkeletalMeshComponent")
        if SkelClass then
            local childs = pawn:GetComponentsByClass(SkelClass)
            if childs then
                local count = type(childs.Num) == "function" and childs:Num() or #childs
                for c = 1, count do
                    local comp = type(childs.Get) == "function" and childs:Get(c-1) or childs[c]
                    if slua.isValid(comp) and comp ~= pawn.Mesh then table.insert(meshes, comp) end
                end
            end
        end
    end)
    for _, comp in ipairs(meshes) do
        pcall(function()
            comp.bRenderCustomDepth = false
            comp.CustomDepthStencilValue = 0
            local origMatSlots = _WH_OrigMaterials[tostring(comp)]
            if origMatSlots then
                for i, mat in pairs(origMatSlots) do pcall(function() comp:SetMaterial(i, mat) end) end
                _WH_OrigMaterials[tostring(comp)] = nil
            end
        end)
    end
    pawn._WH_MIDs = nil
end
local function ApplyWallHack(enemy, pc)
    if not _G.MOD_WallhackEnabled then return end
    if not slua.isValid(enemy) or not slua.isValid(pc) then return end
    local meshes = {}
    pcall(function()
        if slua.isValid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
        local SkelClass = import("SkeletalMeshComponent")
        if SkelClass then
            local childs = enemy:GetComponentsByClass(SkelClass)
            if childs then
                local count = type(childs.Num) == "function" and childs:Num() or #childs
                for c = 1, count do
                    local comp = type(childs.Get) == "function" and childs:Get(c-1) or childs[c]
                    if slua.isValid(comp) and comp ~= enemy.Mesh then table.insert(meshes, comp) end
                end
            end
        end
    end)
    local isVisible = false
    pcall(function() if type(pc.LineOfSightTo) == "function" then isVisible = pc:LineOfSightTo(enemy) end end)
    local bodyColor = isVisible and WH_COLOR_VISIBLE or WH_COLOR_COVERED
    local glowColor = isVisible and WH_GLOW_VISIBLE or WH_GLOW_COVERED
    enemy._WH_MIDs = enemy._WH_MIDs or {}
    local stateChanged = (enemy._WH_LastVisible ~= isVisible)
    enemy._WH_LastVisible = isVisible
    _WH_ModifiedPawns[tostring(enemy)] = enemy
    for _, comp in ipairs(meshes) do
        if slua.isValid(comp) then
            local ck = tostring(comp)
            if not _WH_OrigMaterials[ck] then
                local orig = {}
                for i = 0, 15 do
                    local ok, mat = pcall(function() return comp:GetMaterial(i) end)
                    if ok and slua.isValid(mat) then orig[i] = mat else break end
                end
                _WH_OrigMaterials[ck] = orig
            end
            pcall(function()
                comp.bRenderCustomDepth = true
                comp.CustomDepthStencilValue = 250
                comp.CustomDepthStencilWriteMask = 255
            end)
            pcall(function()
                local ok, mat = pcall(function() return comp:GetMaterial(0) end)
                if ok and slua.isValid(mat) then
                    local ok2, base = pcall(function() return mat:GetBaseMaterial() end)
                    if ok2 and slua.isValid(base) then
                        if not _WH_ModifiedBaseMaterials[base] then
                            _WH_ModifiedBaseMaterials[base] = { bDisableDepthTest = base.bDisableDepthTest, BlendMode = base.BlendMode }
                        end
                        if base.bDisableDepthTest ~= true then base.bDisableDepthTest = true end
                        if base.BlendMode ~= 2 then base.BlendMode = 2 end
                    end
                end
            end)
            comp.UseScopeDistanceCulling = false
            comp.PrimitiveShadingStrategy = 1
            comp.ShadingRate = 6
            enemy._WH_MIDs[ck] = enemy._WH_MIDs[ck] or {}
            for i = 0, 15 do
                local ok3, mi = pcall(function() return comp:GetMaterial(i) end)
                if not ok3 or not slua.isValid(mi) then break end
                local mid = enemy._WH_MIDs[ck][i]
                if not slua.isValid(mid) then
                    local ok4, nm = pcall(function() return comp:CreateAndSetMaterialInstanceDynamic(i) end)
                    if ok4 and slua.isValid(nm) then enemy._WH_MIDs[ck][i] = nm; mid = nm end
                else
                    if mi ~= mid then pcall(function() comp:SetMaterial(i, mid) end) end
                end
                if slua.isValid(mid) and (stateChanged or not enemy._WH_MIDs[ck][i]) then
                    pcall(function() mid:SetVectorParameterValue("颜色", bodyColor) end)
                    pcall(function() mid:SetVectorParameterValue("Extra Light Color", bodyColor) end)
                    pcall(function() mid:SetVectorParameterValue("Para_Color", bodyColor) end)
                    pcall(function() mid:SetVectorParameterValue("Tint", bodyColor) end)
                    pcall(function() mid:SetVectorParameterValue("BaseColor", bodyColor) end)
                    pcall(function() mid:SetVectorParameterValue("BodyColor", bodyColor) end)
                    pcall(function() mid:SetVectorParameterValue("GlowColor", glowColor) end)
                    pcall(function() mid:SetVectorParameterValue("OutlineColor", glowColor) end)
                    pcall(function() mid:SetScalarParameterValue("Glow", 10.0) end)
                    pcall(function() mid:SetScalarParameterValue("GlowAmount", 10.0) end)
                    pcall(function() mid:SetScalarParameterValue("EmissiveBoost", 5.0) end)
                end
            end
        end
    end
end
_G._WH_NeedCleanup = false
function OnWallhackToggleChanged()
    if not _G.MOD_WallhackEnabled then _G._WH_NeedCleanup = true end
end

local COLOR_RED = FLinearColor(1,0,0,1)
local COLOR_HP_GREEN = FLinearColor(0,1,0,0.95); local COLOR_HP_YELLOW = FLinearColor(1,1,0,0.95); local COLOR_HP_RED = FLinearColor(1,0,0,0.95)
local COLOR_BG = FLinearColor(0,0,0,0.55); local VEC_Z85, VEC_Z90 = FVector(0,0,85), FVector(0,0,90)
local function IsPawnAlive(p)
    if not slua.isValid(p) then return false end
    if p.HealthStatus then return SecurityCommonUtils.IsHealthStatusAlive(p.HealthStatus) end
    if p.IsAlive then return p:IsAlive() end
    return p.GetHealth and (p:GetHealth() or 0) > 0 or false
end
local function GetPawnHealthRatio(p)
    local hp = p.GetHealth and p:GetHealth() or 100
    local maxHp = p.GetHealthMax and p:GetHealthMax() or 100
    return math.max(0, math.min(1, hp / (maxHp <= 0 and 100 or maxHp)))
end
local function SetRedFrameUI(p)
    if not slua.isValid(p) then return end
    if p.Replay_SetFrameUIColor then p:Replay_SetFrameUIColor(COLOR_RED)
    elseif p.SetEnemyFrameColor then p:SetEnemyFrameColor(COLOR_RED)
    elseif p.SetFrameColor then p:SetFrameColor(COLOR_RED)
    elseif p.SetOutlineColor then p:SetOutlineColor(COLOR_RED) end
end

local RPCDefinitions = {
    ServerRPC = {
        ServerRPC_NearDeathGiveupRescue = { Reliable = true, Params = {} },
        ServerRPC_CarryDeadBox = { Reliable = true, Params = { UEnums.EPropertyClass.Object } },
        RPC_Server_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } },
    },
    MulticastRPC = { MulticastRPC_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } } },
    ClientRPC = {}
}
local ASTExtraPlayerController = import("/Script/ShadowTrackerExtra.STExtraPlayerController")

local BRPlayerCharacterBase = Class(CharacterBase, nil, {
    ServerRPC = RPCDefinitions.ServerRPC,
    ClientRPC = RPCDefinitions.ClientRPC,
    MulticastRPC = RPCDefinitions.MulticastRPC,

    ctor = function(self)
        self.ActiveTrackerMark = nil
        self.LastTrackerUpdate = 0
        self._AssistTimer = nil
        self._WallhackTimer = nil
        self._VisualData = nil
    end,

    _PostConstruct = function(self)
        CharacterBase._PostConstruct(self)
        self:InitAddSpecialMoveInfo()
        self.bCanNearDeathGiveup = true
        if Client then
            self:AddGameTimer(1.0, false, function() _G.LoadAllFeatures() end)
        end
    end,

    ReceiveBeginPlay = function(self)
        _G._FeaturesLoaded = nil
        _G._LastPC = nil
        if _G.ClearMatchData then pcall(_G.ClearMatchData) end
        CharacterBase.ReceiveBeginPlay(self)
        self:SetActorTickEnabled(true)
        EventSystem:postEvent(EVENTTYPE_SINGLETRAINING, EVENTID_CHARACTER_BEGINPLAY, self.Object)
        if Client then
            if isModExpired() then
                ShowExpiryDialog()
                self:AddGameTimer(5.0, true, function() ShowExpiryDialog() end)
                return
            end
            if not _G.GOKU_BYPASS_LOADED then ShowWelcomePopup() end
            self:InitVisualAssistance()
            self:AddGameTimer(3.0, true, ApplyEnvironment)    -- 3s
            self:AddGameTimer(1.0, true, ApplyAimAssist)      -- 1s
            self:AddGameTimer(1.0, true, ApplyNoRecoil)       -- 1s
            self:AddGameTimer(5.0, true, ApplyiPadView)       -- 5s
            if GameplayData then pcall(StartEnemyCounterTimer) end
            pcall(InjectModMenu)
        end
    end,

    ReceiveEndPlay = function(self, reason)
        if self.ActiveTrackerMark then InGameMarkTools.HideMapMark(self.ActiveTrackerMark) end
        self.ActiveTrackerMark = nil
        if self._AssistTimer then
            self:RemoveGameTimer(self._AssistTimer)
            self._AssistTimer = nil
        end
        if self._WallhackTimer then
            self:RemoveGameTimer(self._WallhackTimer)
            self._WallhackTimer = nil
        end
        if SharedVisualAssistOwner == self then
            SharedVisualAssistOwner = nil
        end
        CharacterBase.ReceiveEndPlay(self, reason)
        if Client and GameplayData and GameplayData.RemoveCharacter then GameplayData.RemoveCharacter(self.Object) end
    end,

    ReceiveTick = function(self)
        if isModExpired() then return end
        if _G.MOD_MapTrackingEnabled then self:UpdateMapTracking() end
    end,

    UpdateMapTracking = function(self)
        if not (Client and slua.isValid(self.Object)) then return end
        if not GameplayData then return end
        local localPlayer = GameplayData.GetPlayerCharacter()
        if not slua.isValid(localPlayer) then return end
        if localPlayer.TeamID ~= self.TeamID then
            if self.Object.IsAlive and self.Object:IsAlive() then
                local ct = os.clock()
                if ct - self.LastTrackerUpdate > 1.0 then
                    self.LastTrackerUpdate = ct
                    local headLoc = self:GetHeadLocation(false) or self:GetFuzzyPosition(FVector(0,0,0))
                    if headLoc then
                        if self.ActiveTrackerMark then InGameMarkTools.HideMapMark(self.ActiveTrackerMark) end
                        self.ActiveTrackerMark = InGameMarkTools.ClientAddMapMark(1003, headLoc, 0, "", 4, nil)
                    end
                end
            end
        elseif self.ActiveTrackerMark then
            InGameMarkTools.HideMapMark(self.ActiveTrackerMark)
            self.ActiveTrackerMark = nil
        end
    end,

    InitVisualAssistance = function(self)
        if not Client or self._AssistTimer or (SharedVisualAssistOwner and SharedVisualAssistOwner ~= self) then return end
        SharedVisualAssistOwner = self

        local visualData = { cachedMarks = {}, cachedPawns = {}, lastPawnRefresh = 0, frameApplied = {} }
        self._VisualData = visualData

        -- ESP timer 0.7 sec
        local baseEspDelay = 0.7
        self._AssistTimer = self:AddGameTimer(baseEspDelay, true, function()
            if not _G.MOD_ESPEnabled then
                for pawnPtr, markId in pairs(visualData.cachedMarks) do
                    if pawnPtr ~= "_time" and markId then InGameMarkTools.HideMapMark(markId) end
                end
                visualData.cachedMarks, visualData.cachedPawns, visualData.frameApplied = {}, {}, {}
                return
            end
            if not slua.isValid(self.Object) then
                for _, markId in pairs(visualData.cachedMarks) do
                    if type(markId) ~= "table" and markId then InGameMarkTools.HideMapMark(markId) end
                end
                visualData.cachedMarks, SharedVisualAssistOwner, visualData.frameApplied = {}, nil, {}
                return
            end
            local uCon = slua_GameFrontendHUD:GetPlayerController()
            if not (slua.isValid(uCon) and Game:IsClassOf(uCon, ASTExtraPlayerController)) then return end
            local currentPawn = uCon:GetCurPawn()
            if not slua.isValid(currentPawn) then return end
            local myTeamId, myPos = currentPawn.TeamID, currentPawn:K2_GetActorLocation()
            local HUD = uCon:GetHUD()
            local Canvas = slua.isValid(HUD) and HUD.Canvas or nil
            local now = os.clock()
            if now - visualData.lastPawnRefresh > 1.0 then
                visualData.lastPawnRefresh = now
                visualData.cachedPawns = Game:GetAllPlayerPawns() or {}
                for pawnPtr, markId in pairs(visualData.cachedMarks) do
                    if pawnPtr ~= "_time" then
                        local found = false
                        for _, p in pairs(visualData.cachedPawns) do if p == pawnPtr then found = true break end end
                        if not found then
                            if markId then InGameMarkTools.HideMapMark(markId) end
                            visualData.cachedMarks[pawnPtr] = nil
                            visualData.frameApplied[pawnPtr] = nil
                        end
                    end
                end
            end
            for _, tPawn in pairs(visualData.cachedPawns) do
                if slua.isValid(tPawn) and tPawn ~= currentPawn and tPawn.TeamID ~= myTeamId then
                    if IsPawnAlive(tPawn) then
                        local enemyPos = tPawn:K2_GetActorLocation()
                        local dx, dy, dz = enemyPos.X - myPos.X, enemyPos.Y - myPos.Y, enemyPos.Z - myPos.Z
                        local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                        if dist < 35000 then
                            if not visualData.frameApplied[tPawn] then
                                if tPawn.Replay_CreateEnemyFrameUI then tPawn:Replay_CreateEnemyFrameUI(true, true) end
                                SetRedFrameUI(tPawn)
                                if tPawn.Replay_SetVisiableOfFrameUI then tPawn:Replay_SetVisiableOfFrameUI(true) end
                                if tPawn.SetPlayerNameVisible then tPawn:SetPlayerNameVisible(true) end
                                visualData.frameApplied[tPawn] = true
                            end
                            local headPos, rootPos
                            if dist > 150000 then headPos, rootPos = enemyPos + VEC_Z85, enemyPos - VEC_Z85
                            else
                                local realHead = tPawn:GetHeadLocation(false)
                                headPos = realHead or (enemyPos + VEC_Z85)
                                rootPos = realHead and (enemyPos - VEC_Z90) or (enemyPos - VEC_Z85)
                            end
                            visualData.cachedMarks._time = visualData.cachedMarks._time or {}
                            if now - (visualData.cachedMarks._time[tPawn] or 0) > 1.5 then
                                visualData.cachedMarks._time[tPawn] = now
                                if visualData.cachedMarks[tPawn] then
                                    InGameMarkTools.UpdateMapMarkLocation(visualData.cachedMarks[tPawn], headPos)
                                else
                                    visualData.cachedMarks[tPawn] = InGameMarkTools.ClientAddMapMark(1006, headPos, 0, "", 4, tPawn)
                                end
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
                        else
                            if tPawn.Replay_SetVisiableOfFrameUI then tPawn:Replay_SetVisiableOfFrameUI(false) end
                            if visualData.cachedMarks[tPawn] then InGameMarkTools.HideMapMark(visualData.cachedMarks[tPawn]); visualData.cachedMarks[tPawn] = nil end
                            visualData.frameApplied[tPawn] = nil
                        end
                    else
                        if tPawn.Replay_SetVisiableOfFrameUI then tPawn:Replay_SetVisiableOfFrameUI(false) end
                        if visualData.cachedMarks[tPawn] then InGameMarkTools.HideMapMark(visualData.cachedMarks[tPawn]); visualData.cachedMarks[tPawn] = nil end
                        visualData.frameApplied[tPawn] = nil
                    end
                end
            end
        end)

        -- Wallhack separate timer 0.15 sec (instant visibility change)
        local baseWhDelay = 0.25
        self._WallhackTimer = self:AddGameTimer(baseWhDelay, true, function()
            if not _G.MOD_WallhackEnabled and _G._WH_NeedCleanup then
                for _, pawn in pairs(_WH_ModifiedPawns) do
                    if slua.isValid(pawn) then ClearWallHackForPawn(pawn) end
                end
                _WH_OrigMaterials = {}
                _WH_ModifiedPawns = {}
                for base, orig in pairs(_WH_ModifiedBaseMaterials) do
                    pcall(function()
                        if slua.isValid(base) then
                            base.bDisableDepthTest = orig.bDisableDepthTest
                            base.BlendMode = orig.BlendMode
                        end
                    end)
                end
                _WH_ModifiedBaseMaterials = {}
                _G._WH_NeedCleanup = false
            end

            if not _G.MOD_WallhackEnabled then return end
            if not slua.isValid(self.Object) then return end

            local uCon = slua_GameFrontendHUD:GetPlayerController()
            if not (slua.isValid(uCon) and Game:IsClassOf(uCon, ASTExtraPlayerController)) then return end
            local currentPawn = uCon:GetCurPawn()
            if not slua.isValid(currentPawn) then return end
            local myTeamId = currentPawn.TeamID
            local myPos = currentPawn:K2_GetActorLocation()

            for _, tPawn in pairs(visualData.cachedPawns) do
                if slua.isValid(tPawn) and tPawn ~= currentPawn and tPawn.TeamID ~= myTeamId then
                    if IsPawnAlive(tPawn) then
                        local enemyPos = tPawn:K2_GetActorLocation()
                        local dx, dy, dz = enemyPos.X - myPos.X, enemyPos.Y - myPos.Y, enemyPos.Z - myPos.Z
                        local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                        if dist < 35000 then
                            pcall(ApplyWallHack, tPawn, uCon)
                        end
                    end
                end
            end
        end)
    end,
})

function InjectModMenu()
    local LocUtil = _G.LocUtil
    if not LocUtil and package.loaded["client.common.LocUtil"] then LocUtil = require("client.common.LocUtil") end
    if LocUtil and not LocUtil._IsModMenuHooked then
        local old_get = LocUtil.GetLocalizeResStr
        LocUtil.GetLocalizeResStr = function(id)
            if type(id) == "string" and not tonumber(id) then return id end
            return old_get(id)
        end
        LocUtil._IsModMenuHooked = true
    end
    local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
    local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")
    local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")
    if not SettingPageDefine.ModMenu then
        local ModMenuStack = {
            { UI = AliasMap.Title, Text = "GOKU CONFIG" },
            { Key = "ESP", UI = AliasMap.Switcher, Text = "ESP (Visuals)", GetFunc = function() return _G.MOD_ESPEnabled end, SetFunc = function(_, value) _G.MOD_ESPEnabled = value; return true end },
            { Key = "Wallhack", UI = AliasMap.Switcher, Text = "WALLHACK (Red/Green)", GetFunc = function() return _G.MOD_WallhackEnabled end, SetFunc = function(_, value) _G.MOD_WallhackEnabled = value; OnWallhackToggleChanged(); return true end },
            { Key = "EnemyCounter", UI = AliasMap.Switcher, Text = "ENEMY COUNTER", GetFunc = function() return _G.MOD_EnemyCounterEnabled end, SetFunc = function(_, value) _G.MOD_EnemyCounterEnabled = value; return true end },
            { Key = "BlackSky", UI = AliasMap.Switcher, Text = "BLACK SKY", GetFunc = function() return _G.MOD_BlackSkyEnabled end, SetFunc = function(_, value) _G.MOD_BlackSkyEnabled = value; return true end },
            { Key = "MapTracking", UI = AliasMap.Switcher, Text = "MAP TRACKING", GetFunc = function() return _G.MOD_MapTrackingEnabled end, SetFunc = function(_, value) _G.MOD_MapTrackingEnabled = value; return true end },
            { Key = "NoGrass", UI = AliasMap.Switcher, Text = "NO GRASS", GetFunc = function() return _G.MOD_NoGrassEnabled end, SetFunc = function(_, value) _G.MOD_NoGrassEnabled = value; return true end },
            { Key = "AimAssist", UI = AliasMap.Switcher, Text = "AIM ASSIST", GetFunc = function() return _G.Mod_AimAssist_Enabled end, SetFunc = function(_, value) _G.Mod_AimAssist_Enabled = value; return true end },
            { Key = "NoRecoil", UI = AliasMap.Switcher, Text = "LESS RECOIL", GetFunc = function() return _G.Mod_NoRecoil_Enabled end, SetFunc = function(_, value) _G.Mod_NoRecoil_Enabled = value; return true end },
            { Key = "iPadView", UI = AliasMap.Switcher, Text = "IPAD VIEW", GetFunc = function() return _G.Mod_iPadView_Enabled end, SetFunc = function(_, value) _G.Mod_iPadView_Enabled = value; return true end },
        }
        SettingPageDefine.ModMenu = {
            Key = "ModMenu", loc = "GOKU CONFIG", UIKey = "Setting_Page_Privacy",
            Category = { { Key = "ModMenu_Main", loc = "Features", Stack = ModMenuStack } }
        }
    end
    local alreadyInCatalog = false
    for _, page in ipairs(SettingCatalog) do if page.Key == "ModMenu" then alreadyInCatalog = true break end end
    if not alreadyInCatalog then table.insert(SettingCatalog, SettingPageDefine.ModMenu) end
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
pcall(InjectModMenu)

return CombineClass.DeclareFeature(BRPlayerCharacterBase, {
    { SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature" },
    { CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature" },
    { SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature" },
    { TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature" },
    { LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature" },
    { FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature" },
    { CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature" },
    { BuildSkateFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature" },
    { CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature" },
    { ParachuteFormation = "GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature" }
}, "BRPlayerCharacterBase")
