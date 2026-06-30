-- ==============================================================================
-- [FULL ORIGINAL GAME CLASS + MODS] – EVERYTHING INCLUDED
-- ==============================================================================

local BRPlayerCharacterBase = {
  ServerRPC = {},
  ClientRPC = {},
  MulticastRPC = {}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = {
  Reliable = true,
  Params = {}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Object
  }
}
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Int
  }
}
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Int
  }
}
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Bool
  }
}
local ENetRole = import("ENetRole")
local EPawnState = import("EPawnState")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")

function BRPlayerCharacterBase:ctor()
end

function BRPlayerCharacterBase:_PostConstruct()
  BRPlayerCharacterBase.__super._PostConstruct(self)
  self:InitAddSpecialMoveInfo()
  self.bCanNearDeathGiveup = true
  print(bWriteLog and "BRPlayerCharacterBase:_PostConstruct bCanNearDeathGiveup true")
end

function BRPlayerCharacterBase:ReceiveBeginPlay()
  BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
  self:AddControlEvent(self, "MovementModeChangedDelegate", self.HandleOnMovementModeChangedNew, self)
  if self:HasAuthority() and self:CheckAddCheckFallingDistanceComponent() then
    local CheckFallingDistanceComponent_C = import("CheckFallingDistanceComponent")
    if slua.isValid(CheckFallingDistanceComponent_C) and not slua.isValid(self:GetComponentByClass(CheckFallingDistanceComponent_C)) then
      print(bWriteLog and "BRPlayerCharacterBase:ReceiveBeginPlay Add CheckFallingDistanceComponent")
      Game:AddComponent(CheckFallingDistanceComponent_C, self, "CheckFallingDistanceComponent")
    end
  end
  if slua.isValid(self.STCharacterMovement) then
    self.STCharacterMovement.bPositiveBlowUp = true
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy then
    self:AddControlEvent(self, "OnPawnStateDisabled", self.OnPawnStateChange, self)
    self:AddControlEvent(self, "OnPawnStateEnabled", self.OnPawnStateChange, self)
    self:AddControlEventConditionOnly(self, "OnAttrChangeEventDelegate", {
      AttrName = {
        "bCanSelfRescue"
      }
    }, self.CharacterAttrChangeEvent, self)
  end
  if Client then
    printf(bWriteLog and "BRPlayerCharacterBase:ReceiveBeginPlay, PlayerKey:%u ", self.PlayerKey)
    GameplayData.AddCharacter(self.Object)
    self:AddControlEvent(self, "OnAttachedToVehicle", self.HandleOnAttachedToVehicle, self)
    self:AddControlEvent(self, "OnDetachedFromVehicle", self.HandleOnDetachedFromVehicle, self)
  else
    self:AddCommonEventWithConditions(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, {
      [1] = "FinishedState"
    }, self.HandleFinishedState, self)
  end
end

function BRPlayerCharacterBase:HandleOnAttachedToVehicle(uVehicle)
  if not slua.isValid(uVehicle) then
    return
  end
  print(bWriteLog and string.format("BRPlayerCharacterBase:HandleOnAttachedToVehicle", Game:GetObjName(uVehicle)))
  if self.Role == ENetRole.ROLE_SimulatedProxy then
    self:ClearAttachToVehicleTimer()
    self.nUpdatePlayerAttachToVehicleCount = 0
    self.nUpdatePlayerAttachToVehicleTimer = self:AddGameTimer(5, true, 
function()
      if slua.isValid(self.Object) and slua.isValid(uVehicle) then
        self:UpdatePlayerAttachToVehicle(uVehicle)
      end
    end)
    self.nFixMeshContainerTimer = self:AddGameTimer(3, true, 
function()
      if slua.isValid(self.Object) and slua.isValid(uVehicle) then
        self:FixMeshContainerOffsetIfNeeded(uVehicle)
      end
    end)
  end
end

function BRPlayerCharacterBase:HandleOnDetachedFromVehicle(uLastVehicle)
  if not slua.isValid(uLastVehicle) then
    return
  end
  print(bWriteLog and "BRPlayerCharacterBase:HandleOnDetachedFromVehicle", uLastVehicle)
  if self.Role == ENetRole.ROLE_SimulatedProxy then
    self:ClearAttachToVehicleTimer()
    self.nUpdatePlayerAttachToVehicleCount = 0
  end
end

function BRPlayerCharacterBase:UpdatePlayerAttachToVehicle(uVehicle)
  if not slua.isValid(self.Object) or not slua.isValid(uVehicle) then
    return
  end
  if not slua.isValid(self.CapsuleComponent) or not slua.isValid(self.Mesh) or not slua.isValid(self.MeshContainer) then
    return
  end
  if not slua.isValid(self:GetCurrentVehicle()) then
    return
  end
  if Game:IsDriver(self.Object) then
    return
  end
  if not self.nUpdatePlayerAttachToVehicleCount then
    self.nUpdatePlayerAttachToVehicleCount = 0
  end
  local ESTEPoseState = import("ESTEPoseState")
  local bStand = self.PoseState == ESTEPoseState.Stand
  local uActorRelativeLocation = self.CapsuleComponent:GetRelativeTransform():GetLocation()
  local uMeshRelativeLocation = self.Mesh:GetRelativeTransform():GetLocation()
  local uMeshContainerRelativeLocationZ = self.MeshContainer:GetRelativeTransform():GetLocation().Z
  local nCapsuleRadius = self.CapsuleComponent:GetScaledCapsuleRadius()
  local nCapsuleHalfHeight = self.CapsuleComponent:GetScaledCapsuleHalfHeight()
  local uMeshContainerExpectedZ = -1 * self.StandHalfHeight
  local nExpectedCapsuleRadius = self.StandRadius
  local nExpectedCapsuleHalfHeight = self.StandHalfHeight
  local uMeshExpectedRL = FVector(0, 0, 0)
  local uActorExpectedRL = FVector(0, 0, self.StandHalfHeight)
  local nTolerance = 1.0
  local bCapsuleRLCorrect = uActorRelativeLocation:Equals(uActorExpectedRL, nTolerance)
  local bMeshRLCorrect = uMeshRelativeLocation:Equals(uMeshExpectedRL, nTolerance)
  local bMeshContainerRLCorrect = nTolerance > math.abs(uMeshContainerRelativeLocationZ - uMeshContainerExpectedZ)
  local bCapsuleRadiusCorrect = nTolerance > math.abs(nCapsuleRadius - nExpectedCapsuleRadius)
  local bCapsuleHalfHeightCorrect = nTolerance > math.abs(nCapsuleHalfHeight - nExpectedCapsuleHalfHeight)
  local bAllCorrect = bStand and bCapsuleRLCorrect and bMeshRLCorrect and bMeshContainerRLCorrect and bCapsuleRadiusCorrect and bCapsuleHalfHeightCorrect
  if not bAllCorrect then
    self.nUpdatePlayerAttachToVehicleCount = self.nUpdatePlayerAttachToVehicleCount + 1
  else
    self.nUpdatePlayerAttachToVehicleCount = 0
  end
  print(bWriteLog and string.format("BRPlayerCharacterBase:UpdatePlayerAttachToVehicle PlayerKey:%s. bAllCorrect=%s Check Result:%d %d %d %d %d %d, Count:%d", tostring(self.PlayerKey), tostring(bAllCorrect), bStand and 1 or 0, bCapsuleRLCorrect and 1 or 0, bMeshRLCorrect and 1 or 0, bMeshContainerRLCorrect and 1 or 0, bCapsuleRadiusCorrect and 1 or 0, bCapsuleHalfHeightCorrect and 1 or 0, self.nUpdatePlayerAttachToVehicleCount))
  if self.nUpdatePlayerAttachToVehicleCount >= 3 and not bAllCorrect then
    local GameplayData = require("GameLua.GameCore.Data.GameplayData")
    local uPlayerController = GameplayData.GetPlayerController()
    if uPlayerController.ReportCrashKitFeature and uPlayerController.ReportCrashKitFeature.ReportCharacterAttachedOnVehicleException then
      local sReportInfo = string.format("VehicleShapeType:%s PlayerKey:%s. Check Result:%d %d %d %d %d %d. Capsule.RelativeLoc:%s Capsule.Radius:%s Capsule.HalfHeight:%s Mesh.RelativeLoc:%s MeshContainer.RelativeLocZ:%s", tostring(uVehicle.VehicleShapeType), tostring(self.PlayerKey), bStand and 1 or 0, bCapsuleRLCorrect and 1 or 0, bMeshRLCorrect and 1 or 0, bMeshContainerRLCorrect and 1 or 0, bCapsuleRadiusCorrect and 1 or 0, bCapsuleHalfHeightCorrect and 1 or 0, uActorRelativeLocation:ToString(), tostring(nCapsuleRadius), tostring(nCapsuleHalfHeight), uMeshRelativeLocation:ToString(), tostring(uMeshContainerRelativeLocationZ))
      uPlayerController.ReportCrashKitFeature:ReportCharacterAttachedOnVehicleException(sReportInfo)
    end
    self.nUpdatePlayerAttachToVehicleCount = 0
  end
end

function BRPlayerCharacterBase:FixMeshContainerOffsetIfNeeded(uVehicle)
  if not slua.isValid(self.Object) or not slua.isValid(uVehicle) then
    return
  end
  if not slua.isValid(self.MeshContainer) then
    return
  end
  if not slua.isValid(self:GetCurrentVehicle()) then
    return
  end
  if Game:IsDriver(self.Object) then
    return
  end
  local nTolerance = 1.0
  local uMeshContainerExpectedZ = -1 * self.StandHalfHeight
  local uMeshContainerRelativeLocationZ = self.MeshContainer:GetRelativeTransform():GetLocation().Z
  if nTolerance <= math.abs(uMeshContainerRelativeLocationZ - uMeshContainerExpectedZ) then
    print(bWriteLog and string.format("BRPlayerCharacterBase:FixMeshContainerOffsetIfNeeded PlayerKey:%s. SetMeshContainerOffsetZ from:%s to:%s", tostring(uMeshContainerExpectedZ), tostring(uMeshContainerExpectedZ)))
    self:SetMeshContainerOffsetZ(uMeshContainerExpectedZ)
  end
end

function BRPlayerCharacterBase:ClearAttachToVehicleTimer()
  if self.nUpdatePlayerAttachToVehicleTimer then
    self:RemoveGameTimer(self.nUpdatePlayerAttachToVehicleTimer)
    self.nUpdatePlayerAttachToVehicleTimer = nil
  end
  if self.nFixMeshContainerTimer then
    self:RemoveGameTimer(self.nFixMeshContainerTimer)
    self.nFixMeshContainerTimer = nil
  end
end

function BRPlayerCharacterBase:CharacterAttrChangeEvent(uPawn, AttrName, AttrVal)
  BRPlayerCharacterBase.__super.CharacterAttrChangeEvent(self, uPawn, AttrName, AttrVal)
  if self.Object ~= uPawn then
    return
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy and AttrName == "bCanSelfRescue" then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:BroadcastUIMessage("UIMsg_CanSelfRescue", 0, "", "")
    end
  end
end

function BRPlayerCharacterBase:OnPawnStateChange(PawnState)
  print("BRPlayerCharacterBase:OnPawnStateChange:", PawnState)
  local EPawnState = import("EPawnState")
  if PawnState == EPawnState.SwitchPP then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:BroadcastUIMessage("UIMsg_FPPModeChange", 0, "", "")
    end
  end
end

function BRPlayerCharacterBase:HandleFinishedState()
  print(bWriteLog and "BRPlayerCharacterBase:HandleFinishedState", self.STCharacterMovement)
  if slua.isValid(self.STCharacterMovement) and self.STCharacterMovement.SetDynamicSimpleQueryConfig then
    self.STCharacterMovement:SetDynamicSimpleQueryConfig(false)
  end
end

function BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent()
  if CGameMode and CGameMode.GameModeType and CGameState and CGameState.GameModeID then
    local EGameModeType = import("EGameModeType")
    local MatchModeIds = require("GameLua.Mod.BaseMod.GamePlay.Config.MatchModeIdsConfig")
    local GameModeType = CGameMode.GameModeType
    local GameModeID = tonumber(CGameState.GameModeID)
    local bModeTypeSatisfy = GameModeType == EGameModeType.ETypicalGameMode or GameModeType == EGameModeType.EFourInOneGameMode or GameModeType == EGameModeType.EHeavyWeaponGameMode
    local bModeIDSatisfy = not MatchModeIds[GameModeID]
    print(bWriteLog and bWriteLog and "BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent:", GameModeType, GameModeID, bModeTypeSatisfy, bModeIDSatisfy)
    return bModeTypeSatisfy and bModeIDSatisfy
  end
  return false
end

function BRPlayerCharacterBase:LuaHandleParachuteStateChanged(LastParachuteState, NewParachuteState)
  BRPlayerCharacterBase.__super.LuaHandleParachuteStateChanged(self, LastParachuteState, NewParachuteState)
  local EParachuteState = import("EParachuteState")
  if not Client then
    local uCurrentPlayerControl = self:GetPlayerControllerSafety()
    if slua.isValid(uCurrentPlayerControl) and uCurrentPlayerControl.CheckParachuteOpenFeature then
      if NewParachuteState == EParachuteState.PS_Opening then
        if uCurrentPlayerControl.CheckParachuteOpenFeature.SatrtCheckShowParachuteCloseUI then
          uCurrentPlayerControl.CheckParachuteOpenFeature:SatrtCheckShowParachuteCloseUI()
        end
      elseif NewParachuteState == EParachuteState.PS_None then
        if uCurrentPlayerControl.CheckParachuteOpenFeature.RecoverParachuteOpenParam then
          uCurrentPlayerControl.CheckParachuteOpenFeature:RecoverParachuteOpenParam()
        end
        if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then
          uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState()
        end
      end
    end
  end
end

function BRPlayerCharacterBase:OnLanded()
  printf("BRPlayerCharacterBase:OnLanded PlayerKey:%d", self.PlayerKey)
  if self.HandleOnLanded then
    self:HandleOnLanded(-1)
  end
  if not Client then
    local uCurrentPlayerControl = self:GetPlayerControllerSafety()
    if slua.isValid(uCurrentPlayerControl) and uCurrentPlayerControl.CheckParachuteOpenFeature then
      if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then
        uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState()
      end
      if uCurrentPlayerControl.CheckParachuteOpenFeature.ResetCheckShowUI then
        uCurrentPlayerControl.CheckParachuteOpenFeature:ResetCheckShowUI()
      end
    end
  end
end

function BRPlayerCharacterBase:ReceiveEndPlay(EndPlayReason)
  BRPlayerCharacterBase.__super.ReceiveEndPlay(self, EndPlayReason)
  if Client then
    GameplayData.RemoveCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:IsWarGameMode()
  local GameplayData = require("GameLua.GameCore.Data.GameplayData")
  local uGameState = GameplayData:GetGameState()
  local STExtraGameStateBase = import("STExtraGameStateBase")
  if slua.isValid(uGameState) and Game:IsClassOf(uGameState, STExtraGameStateBase) then
    local EGameModeType = import("EGameModeType")
    return uGameState.GameModeType == EGameModeType.EWarGameMode
  else
    return false
  end
end

function BRPlayerCharacterBase:BPOnRecycled()
  print(bWriteLog and string.format("%s BPOnRecycled()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
  end
end

function BRPlayerCharacterBase:BPOnRespawned()
  print(bWriteLog and string.format("%s BPOnRespawned()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
  end
end

function BRPlayerCharacterBase:ReceiveOnRecycle()
  print(bWriteLog and string.format("%s IReusable:ReceiveOnRecycle()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
    GameplayData.RemoveCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:ReceiveOnSpawn()
  print(bWriteLog and string.format("%s IReusable:ReceiveOnSpawn()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
    GameplayData.AddCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:ResetMeshRelativeLocationAndRotation()
  if Game:IsValid(self.Object) and Game:IsValid(self.Mesh) then
    local uDefaultMeshRot = FRotator(0, -90, 0)
    local uDefaultMeshRelativeLoc = FVector(0, 0, 0)
    if self.Mesh.K2_SetRelativeRotation then
      self.Mesh:K2_SetRelativeRotation(uDefaultMeshRot, false, nil, false)
    end
    self:CacheInitialMeshOffset(uDefaultMeshRelativeLoc, uDefaultMeshRot)
    local vRelativeRot = self.Mesh.RelativeRotation
    local vBaseRotationOffset = self.BaseRotationOffset
    local vBaseRotation = Game:QuatToRotator(vBaseRotationOffset)
    print(bWriteLog and bWriteLog and string.format("%s ResetMeshRelativeLocationAndRotation() Mesh.RelativeRotation: %s %s %s   Pawn.BaseRotationOffset:%s %s %s ", Game:GetPlainName(self.Object), tostring(vRelativeRot.Pitch), tostring(vRelativeRot.Yaw), tostring(vRelativeRot.Roll), tostring(vBaseRotation.Pitch), tostring(vBaseRotation.Yaw), tostring(vBaseRotation.Roll)))
  end
end

function BRPlayerCharacterBase:HandleOnMovementModeChangedNew()
  print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged11")
  local EMovementMode = import("EMovementMode")
  if Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Swimming and self:CheckBaseIsMoveable() then
    print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged22")
    self.CharacterMovement:SetBase(nil, "", true)
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy and Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Walking and UIManager.UI_Config_InGame.ParachuteOpenUI then
    print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChangedNew CloseUI")
    UIManager.CloseUI(UIManager.UI_Config_InGame.ParachuteOpenUI)
  end
end

function BRPlayerCharacterBase:BPOnMissPlayerDamageRecord()
end

function BRPlayerCharacterBase:PreAttachedToVehicle()
  local UKismetSystemLibrary = import("KismetSystemLibrary")
  local IsDS = UKismetSystemLibrary.IsDedicatedServer(self)
  if not IsDS then
    return
  end
  local MainPlayerController = self:GetPlayerControllerSafety()
  if not slua.isValid(MainPlayerController) then
    return
  end
  local CharacterAvatarComp2_BP = self.CharacterAvatarComp2_BP
  if not slua.isValid(CharacterAvatarComp2_BP) then
    return
  end
  local CommerAvatarDataUtil = require("GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil")
  local changedVehicleId = CommerAvatarDataUtil:ChangeVehicleSkinByClothes(MainPlayerController, CharacterAvatarComp2_BP)
  local ESTExtraVehicleShapeType = import("ESTExtraVehicleShapeType")
  if changedVehicleId then
    local UAvatarUtils = import("AvatarUtils")
    if UAvatarUtils.GetVehicleShapeBySkinID(changedVehicleId) == ESTExtraVehicleShapeType.VST_Horse then
      local uCurPlayerState = self:GetPlayerStateSafety()
      if slua.isValid(uCurPlayerState) then
        print(bWriteLog and "  BRPlayerCharacterBase:PreAttachedToVehicle. changedVehicleId: " .. tostring(changedVehicleId))
        uCurPlayerState:AddGeneralCount(468, 1, false)
      end
    end
  end
end
BRPlayerCharacterBase.ClientRPC.ClientRPC_TriggerHighlightMoment = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.UInt32,
    UEnums.EPropertyClass.UInt32
  }
}

function BRPlayerCharacterBase:ClientRPC_TriggerHighlightMoment(Type, Param)
  print(bWriteLog and string.format("BRPlayerCharacterBase:ClientRPC_TriggerHighlightMoment Type = %d, Param = %s", Type, Param))
  EventSystem:postEvent(EVENTTYPE_INGAME, EVENTID_INGAME_TRIGGER_HIGHLIGHT_MOMENT, Type, Param)
end

function BRPlayerCharacterBase:ParachuteJump()
  local uPlayerController = self:GetControllerSafety()
  if slua.isValid(uPlayerController) then
    if not self:GetEnsure() then
      local EStateType = import("EStateType")
      if uPlayerController:GetCurrentStateType() ~= EStateType.State_ParachuteJump and uPlayerController:GetCurrentStateType() ~= EStateType.State_ParachuteOpen then
        local ESTEPoseState = import("ESTEPoseState")
        self:SwitchPoseState(ESTEPoseState.Stand, true, true, true, false)
        uPlayerController:ReInitParachuteItem()
        uPlayerController:ServerChangeStatePC(EStateType.State_ParachuteJump)
      end
      print(bWriteLog and "BRPlayerCharacterBase:ParachuteJump over")
    else
      EventSystem:postEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_AI_CALL_PARACHUTE_JUMP, self.Object)
      print(bWriteLog and "BRPlayerCharacterBase:ParachuteJump AI JUMP over, Loc=", tostring(self:K2_GetActorLocation():ToString()))
    end
  end
end

function BRPlayerCharacterBase:OnMovementBaseChangedEvent(uCharacter, uNewMovementBase, uOldMovementBase)
  if uCharacter ~= self.Object then
    return
  end
  print(bWriteLog and string.format("BRPlayerCharacterBase:OnMovementBaseChangedEvent %s, Base: %s -> %s", uCharacter, uOldMovementBase, uNewMovementBase))
  local MedievalCrane = self:GetMedievalCraneFromBase(uNewMovementBase)
  if MedievalCrane and MedievalCrane.AddCharacter then
    MedievalCrane:AddCharacter(self.Object)
  else
    MedievalCrane = self:GetMedievalCraneFromBase(uOldMovementBase)
    if MedievalCrane and MedievalCrane.RemoveCharacter then
      MedievalCrane:RemoveCharacter(self.Object)
    end
  end
end

function BRPlayerCharacterBase:GetMedievalCraneFromBase(Base)
  if not slua.isValid(Base) or not Base.GetOwner then
    return
  end
  local Lifter = Base:GetOwner()
  if not slua.isValid(Lifter) then
    return
  end
  if not Lifter.AddCharacter then
    return
  end
  return Lifter
end

function BRPlayerCharacterBase:CheckForbidFlaregun()
  local uPlayerState = self:GetPlayerStateSafety()
  if not slua.isValid(uPlayerState) then
    return false
  end
  if uPlayerState.CanUseFlaregun == false and self:IsLocallyControlled() then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:DisplayGameTipWithMsgID(48532)
    end
  end
  return not uPlayerState.CanUseFlaregun
end

function BRPlayerCharacterBase:ServerRPC_NearDeathGiveupRescue()
  self:HandleNearDeathGiveupRescue()
end

function BRPlayerCharacterBase:HandleNearDeathGiveupRescue()
  local uNearDeathComp = self.NearDeatchComponent
  if self:IsNearDeath() and slua.isValid(uNearDeathComp) and self.bCanNearDeathGiveup == true then
    local uPlayerState = self:GetPlayerStateSafety()
    if slua.isValid(uPlayerState) then
      uPlayerState:AddGeneralCount(1613, 1, false)
    end
    uNearDeathComp:TriggerGotoDieExplictly(self.Object)
  end
end

function BRPlayerCharacterBase:RPC_Server_GmPlayAction(actionId)
  log(bWriteLog and "  BRPlayerCharacterBase:RPC_Server_GmPlayAction.  actionId: " .. tostring(actionId))
  local USTExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
  if USTExtraBlueprintFunctionLibrary.IsDevelopment() then
    log(bWriteLog and "  BRPlayerCharacterBase:RPC_Server_GmPlayAction. IsDevelopment actionId: " .. tostring(actionId))
    self:MulticastRPC_GmPlayAction(actionId)
  end
end

function BRPlayerCharacterBase:MulticastRPC_GmPlayAction(actionId)
  if not Client then
    return
  end
  log(bWriteLog and "  BRPlayerCharacterBase:MulticastRPC_GmPlayAction.  actionId: " .. tostring(actionId))
  local uPlayEmoteComp = self:GetPlayEmoteComponent()
  if not slua.isValid(uPlayEmoteComp) then
    return
  end
  local LogFilter = require("common.log_filter")
  LogFilter.SetLogTreeEnable(true)
  local animCfg = CDataTable.GetTableData("EmoteBPTable", actionId)
  if not animCfg then
    return
  end
  local handlePath = animCfg.Path
  local EmoteHandleAsset = slua.loadObject(handlePath)
  local assetsArray = slua.Array(UEnums.EPropertyClass.Struct, import("/Script/CoreUObject.SoftObjectPath"))
  local handle = EmoteHandleAsset()
  uPlayEmoteComp:OnLoadEmoteAssetBegin(handle, actionId, assetsArray, "")
  log(bWriteLog and "  BRPlayerCharacterBase:MulticastRPC_GmPlayAction. assetsArray:Num(): " .. tostring(assetsArray:Num()))
  local tb = FuncUtil.LuaArrayToTable(assetsArray)
  local asset_util = require("common.asset_util")
  local loadLater = function()
    uPlayEmoteComp:OnLoadEmoteAssetEnd(handle, actionId, 0)
  end
  asset_util.GetAssetsArrayAsyncParallel(tb, loadLater)
end

function BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall(bServerSyncShouldCheckPassWall)
  print(bWriteLog and "BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall " .. tostring(bServerSyncShouldCheckPassWall))
  if slua.isValid(self.ParachuteComponent) then
    self.ParachuteComponent.bServerSyncShouldCheckPassWall = bServerSyncShouldCheckPassWall
  end
end

function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState()
  self.Super:OnPlayerEnterCarryBoxState()
  local CharName = self:GetPlayerNameSafety()
  print(bWriteLog and string.format("Log BRPlayerCharacterBase:OnPlayerEnterCarryBoxState Role:%s PlayerKey:%s Name:%s", tostring(self.Role), tostring(self.PlayerKey), tostring(CharName)))
  if self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState()
  end
end

function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  self.Super:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  local CharName = self:GetPlayerNameSafety()
  print(bWriteLog and string.format("DeadBoxLog BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState Role:%s PlayerKey:%s Name:%s bInIsInterrupt:%s", tostring(self.Role), tostring(self.PlayerKey), tostring(CharName), tostring(bInIsInterrupt)))
  if self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  end
end

function BRPlayerCharacterBase:ServerRPC_CarryDeadBox(uInDeadBox)
  if slua.isValid(uInDeadBox) and Game:IsClassOf(uInDeadBox, import("/Script/ShadowTrackerExtra.PlayerTombBox")) and self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:CarryDeadBox(uInDeadBox)
  end
end

function BRPlayerCharacterBase:SetAreaID(AreaID)
  self:SetAttrValue("AreaID", AreaID, -1)
end

function BRPlayerCharacterBase:GetAreaID()
  return math.floor(self:GetAttrValue("AreaID") + 0.5)
end

function BRPlayerCharacterBase:CannotChangeIntoPetSpectator()
  print(bWriteLog and "BRPlayerCharacterBase:CannotChangeIntoPetSpectator")
  return self.bCannotChangeIntoPetSpectator
end

function BRPlayerCharacterBase:DoModChangeToBT()
  print(bWriteLog and string.format("BRPlayerCharacterBase:DoModChangeToBT, PlayerKey=%s", tostring(self.PlayerKey)))
  if self:HasState(EPawnState.SpecialSuit) then
    self:TriggerEntrySkillWithID(4301101, true)
    print(bWriteLog and string.format("BRPlayerCharacterBase:DoModChangeToBT, PlayerKey=%s, HasState(EPawnState.SpecialSuit)", tostring(self.PlayerKey)))
  end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteOpening()
  print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteOpening")
  self.Super:SwitchCameraToParachuteOpening()
  if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
    self.ParachuteFormation:OverlayFormationCameraParams()
    print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteOpening - Formation camera overlaid")
  end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteFalling()
  print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteFalling")
  self.Super:SwitchCameraToParachuteFalling()
  if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
    self.ParachuteFormation:OverlayFormationCameraParams()
    print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteFalling - Formation camera overlaid")
  end
end

function BRPlayerCharacterBase:SwitchCameraToNormal()
  print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToNormal")
  self.Super:SwitchCameraToNormal()
  if self.ParachuteFormation and self.ParachuteFormation.OnLandingClearFormationCamera then
    self.ParachuteFormation:OnLandingClearFormationCamera()
  end
end

function BRPlayerCharacterBase:SwitchWeaponCheck(Slot, IgnoreState)
  if self:HasState(EPawnState.AttachToOther) then
    local Weapon = self:GetWeaponBySlot(Slot)
    if slua.isValid(Weapon) then
      local WeaponID = Weapon:GetWeaponID()
      local AttachToOtherConfig = GamePlayTools.GetCurrentConfig("AttachToOtherConfig")
      if AttachToOtherConfig and AttachToOtherConfig.CheckIsWeaponInBlackList and AttachToOtherConfig.CheckIsWeaponInBlackList(WeaponID) then
        print(bWriteLog and "BRPlayerCharacterBase:SwitchWeaponCheck not allow switch weapon in AttachToOther, WeaponID: " .. tostring(WeaponID))
        local uPlayerController = self:GetPlayerControllerSafety()
        if Client and slua.isValid(uPlayerController) and uPlayerController.Role == ENetRole.ROLE_AutonomousProxy then
          uPlayerController:DisplayGameTipWithMsgID(47306)
        end
        return false
      end
    end
  end
  return self.Super:SwitchWeaponCheck(Slot, IgnoreState)
end

-- ==============================================================================
-- ============================ BẮT ĐẦU FULL LOGIC MOD ==========================
-- ==============================================================================

local function Notify(msg) local s = "[GOKUCONFIG] " .. tostring(msg)
pcall(function() if _G.LexusNotify then _G.LexusNotify(s) end end)
pcall(function() local sh = import("ScriptHelperClient") if sh and
sh.AddOnScreenDebugMessage then sh.AddOnScreenDebugMessage(s, -1, 3.0, {R=1,
G=1, B=0, A=1}, {X=1.2, Y=1.2}) end end) print(s) end

local _slua = rawget(_G, "slua")

local function Valid(obj) if not obj then return false end if _slua and
_slua.isValid then local ok, v = pcall(_slua.isValid, obj) if not ok or not v
then return false end end return true end

-- ========================================== 
-- STATIC VARIABLES & GLOBAL CACHE TỐI ƯU HÓA (CHỐNG LAG)
-- ========================================== 
local C_GREEN = {R=0, G=255, B=0, A=255}
local C_RED = {R=255, G=0, B=0, A=255}
local C_CYAN = {R=0, G=255, B=255, A=255}
local C_YELLOW = {R=255, G=255, B=0, A=255}
local C_WHITE = {R=255, G=255, B=255, A=255}
local C_BLUE_TEXT = {R=0, G=200, B=255, A=255}

-- ========================================== 
-- CẤU HÌNH LEXUS CORE + FULL FEATURES VIP 
-- ========================================== 
_G.LexusConfig = _G.LexusConfig or { 
    ModSkin = false,           
    SkinOptionOpen = false,
    ESPEnabled = false,
    WallhackEnabled = false,
    AimAssistEnabled = false,
    AimPower = 50,
    NoRecoilEnabled = false,
    RecoilReduction = 100,
    iPadViewEnabled = false,
    iPadViewFOV = 110,
    VisualCleanupEnabled = false,
    AntiLagEnabled = false,
    WatermarkEnabled = true,
    VehicleESP = false
}

-- CHỨA STATE HỆ THỐNG ĐÃ ĐƯỢC TỐI ƯU HÓA HOÀN TOÀN RAM TRỐNG
_G.LexusState = _G.LexusState or { 
    LoopToken = 0, 
    NativeESPReady = false,
    GraphicsUnlocked = false, 
    MenuStep = 0, 
    LastCmdTime = 0,
    TrackedMarks = {},
    EnemyMarks = {},
    LastAimbotCheckTime = 0, 
    CustomTextData = nil,     
    LastAimEntity = nil,
    LastAimState = nil,
    LastRecoilEntity = nil,
    LastRecoilState = nil,
    MagicUpdateVersion = 1,
    LastMagicConfigHash = "",
    PrevGraphicsState = {},
    MatchStarted = false,
    VisualsStarted = false,
    LastExpiryTime = 0,
    WelcomeShown = false
}

local limitTime = os.time({ year = 2026, month = 7, day = 16, hour = 23, min = 59, sec = 0 })
local currentTime = os.time(os.date("!*t"))
local isExpired = false

pcall(function()
    local fileName = ".sys_time_cache" -- Tên file ẩn
    local paths = {
        "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Gamelet/logs/" .. fileName,
        "//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Gamelet/logs/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Gamelet/logs/" .. fileName,
        "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Gamelet/logs/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Gamelet/logs/" .. fileName,
        "Documents/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "Documents/ShadowTrackerExtra/Saved/Gamelet/logs/" .. fileName,
        "/Documents/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "/Documents/ShadowTrackerExtra/Saved/Gamelet/logs/" .. fileName,
        "ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "ShadowTrackerExtra/Saved/Gamelet/logs/" .. fileName,
        "../../ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "../../ShadowTrackerExtra/Saved/Gamelet/logs/" .. fileName
    }
    if os and os.getenv then
        local homeDir = os.getenv("HOME")
        if homeDir and homeDir ~= "" then
            table.insert(paths, 1, homeDir .. "/Documents/ShadowTrackerExtra/Saved/SaveGames/" .. fileName)
            table.insert(paths, 2, homeDir .. "/Documents/ShadowTrackerExtra/Saved/Gamelet/logs/" .. fileName)
        end
    end
    local tm = package.loaded["client.logic.common.TimeManager"]
    if not tm then 
        local s, r = pcall(require, "client.logic.common.TimeManager")
        if s and r then tm = r end
    end
    if tm and type(tm.GetServerTime) == "function" then
        local serverTime = tm.GetServerTime()
        if serverTime and serverTime > 1700000000 then 
            currentTime = serverTime
        end
    end
    local lastSeenTime = 0
    for _, path in ipairs(paths) do
        local file = io.open(path, "r")
        if file then
            local data = file:read("*a")
            local savedTime = tonumber(data) or 0
            if savedTime > lastSeenTime then
                lastSeenTime = savedTime
            end
            file:close()
        end
    end
    if currentTime < lastSeenTime then
        currentTime = lastSeenTime
    else
        for _, path in ipairs(paths) do
            local file = io.open(path, "w")
            if file then
                file:write(tostring(currentTime))
                file:close()
            end
        end
    end
end)

isExpired = (currentTime > limitTime)

-- ==============================================================================
-- ================== KHỞI TẠO VÀ LOAD BYPASS ĐẦU TIÊN ==========================
-- ==============================================================================

-- ============================================================================
-- ULTIMATE MERGED BYPASS v3.0 - COMPLETE SECURITY DISABLEMENT
-- ============================================================================
local function nop() return true end
local function retFalse() return false end
local function retZero() return 0 end
local function retEmpty() return {} end
local function retNil() return nil end
local function retTrue() return true end
local function retEmptyString() return "" end

local function InitializeSLUABypass()
    pcall(function()
        if slua and slua.getSignature then slua.getSignature = function() return 0xDEADBEEF end end
        local loader = package.loaded["slua.loader"] or rawget(_G, "slua_loader")
        if loader then
            loader.verifyBytecode = retTrue
            loader.checkIntegrity = retTrue
            if loader.disableSignatureCheck then loader.disableSignatureCheck = retTrue end
        end
        local slua_serialize = package.loaded["slua.serialize"]
        if slua_serialize then slua_serialize.check = retTrue; slua_serialize.verify = retTrue end
        if jit and jit.attach then jit.attach(function() end, "bc") end
        if _G.slua_verify then _G.slua_verify = retTrue end
        if _G.check_slua_integrity then _G.check_slua_integrity = retTrue end
    end)
end

local function InitializeMD5Bypass()
    pcall(function()
        local console = import("KismetSystemLibrary")
        if console then
            console.ExecuteConsoleCommand(nil, "pak.DisablePakSignatureCheck 1")
            console.ExecuteConsoleCommand(nil, "pakchunk.EnableSignatureCheck 0")
            console.ExecuteConsoleCommand(nil, "s.VerifyPak 0")
            console.ExecuteConsoleCommand(nil, "sig.Check 0")
            console.ExecuteConsoleCommand(nil, "security.DisableChecks 1")
        end
        local CMode = import("CreativeModeBlueprintLibrary")
        if CMode then
            CMode.MD5HashByteArray = function() return "00000000000000000000000000000000" end
            CMode.MD5HashFile = function() return "00000000000000000000000000000000" end
            CMode.GetContentDiffData = function() return true, "BYPASSED" end
            CMode.VerifyFileIntegrity = retTrue
        end
        if _G.MD5Hash then _G.MD5Hash = function() return "00000000000000000000000000000000" end end
        if _G.CRC32 then _G.CRC32 = function() return 0 end end
        if _G.SHA1 then _G.SHA1 = function() return "BYPASS" end end
        local FileHashChecker = package.loaded["common.file_hash_checker"]
        if FileHashChecker then
            FileHashChecker.CheckFileMD5 = retTrue; FileHashChecker.VerifyAll = retTrue
            FileHashChecker.GetHash = function() return "BYPASS" end
        end
        local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
        if TssSdk then TssSdk.GetFileMD5 = function() return "BYPASS" end; TssSdk.VerifyFileSignature = retTrue end
        local STExtra = import("STExtraBlueprintFunctionLibrary")
        if STExtra then STExtra.CheckMD5 = retTrue; STExtra.GetMD5 = function() return "BYPASS" end; STExtra.VerifyFile = retTrue end
    end)
end
local function InitializeSkinBypass()
    pcall(function()
        local ptlog = package.loaded["client.slua.logic.download.report.puffer_tlog"]
        if ptlog then ptlog.ReportEvent = nop; ptlog.ReportDownloadResult = nop; ptlog.ReportODPTDError = nop; ptlog.ReportSkinError = nop end
        local AvatarUtils = package.loaded["AvatarUtils"]
        if AvatarUtils then AvatarUtils.CheckIsWeaponInBlackList = retFalse; AvatarUtils.IsValidAvatar = retTrue; AvatarUtils.CheckAvatarIntegrity = retTrue; AvatarUtils.ReportInvalidAvatar = nop end
        local sub = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("FileCheckSubsystem")
        if sub then sub.StartCheck = nop; sub.ReportAbnormalFile = nop; sub.StopCheck = nop end
        local eqEx = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
        if eqEx then eqEx.Report = nop; eqEx.SendException = nop end
    end)
end
local function InitializeLogBlocker()
    pcall(function()
        local SMTD = import("ScreenshotMTDer")
        if SMTD then SMTD.MTDePicture = function() return "" end; SMTD.ReMTDePicture = function() return "" end; SMTD.HasCaptured = retTrue; SMTD.TakeScreenshot = nop end
        local TLog = package.loaded["TLog"] or _G.TLog
        if TLog then TLog.Info = nop; TLog.Warning = nop; TLog.Error = nop; TLog.Debug = nop; TLog.Report = nop; TLog.Send = nop; TLog.Flush = nop end
        local CrashSight = package.loaded["CrashSight"] or _G.CrashSight
        if CrashSight then CrashSight.ReportException = nop; CrashSight.SetCustomData = nop; CrashSight.Log = nop; CrashSight.SendCrash = nop; CrashSight.ReportUserException = nop end
        local GRUtils = package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"]
        if GRUtils then GRUtils.BugglyPostExceptionFull = retFalse; GRUtils.CheckCanBugglyPostException = retFalse; GRUtils.ReplayReportData = nop; GRUtils.ReportGameException = nop; GRUtils.PostException = nop end
        local CTR = package.loaded["client.slua.logic.report.ClientToolsReport"]
        if CTR then CTR.SendReport = nop; CTR.SendException = nop; CTR.UploadLog = nop end
        for _, sdk in ipairs({"Firebase", "Adjust", "AppsFlyer", "FacebookAnalytics", "GameAnalytics"}) do
            local s = _G[sdk]; if s then s.logEvent = nop; s.trackEvent = nop; s.setEnabled = retFalse; s.sendEvent = nop; s.report = nop end
        end
    end)
end

local function InitializeScannerBlocker()
    pcall(function()
        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            local subs = {"AFKReportorSubsystem", "ClientDataStatistcsSubsystem", "AvatarExceptionSubsystem", "ShootVerifySubSystemClient", "MemoryCheckSubsystem", "SpeedCheckSubsystem", "WallCheckSubsystem", "FileCheckSubsystem", "BehaviorScoreSubsystem"}
            for _, name in ipairs(subs) do
                local sub = SubMgr:Get(name)
                if sub then
                    for k, v in pairs(sub) do
                        if type(v) == "function" and (k:find("Report") or k:find("Send") or k:find("Upload") or k:find("Verify") or k:find("Check") or k:find("Validate") or k:find("Scan") or k:find("Detect")) then pcall(function() sub[k] = nop end) end
                    end
                    if sub.ReportPingDelayTimer then sub:RemoveGameTimer(sub.ReportPingDelayTimer); sub.ReportPingDelayTimer = nil end; sub.DelayCount = 0
                end
            end
        end
        local AvaEx = package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionPlayerInst"]
        if AvaEx then AvaEx.CheckAvatarException = nop; AvaEx.CheckAvatarExceptionOnce = nop; AvaEx.ReportAvatarException = nop; AvaEx.CheckSlotMeshVisible = retFalse; AvaEx.CheckPawnVisible = retFalse; AvaEx.CheckCanBugglyPostException = retFalse end
        local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
        if TssSdk then
            local origData = TssSdk.OnRecvData
            TssSdk.OnRecvData = function(data) if type(data) == "string" and (data:find("report", 1, true) or data:find("exception", 1, true) or data:find("cheat", 1, true) or data:find("violation", 1, true) or data:find("hack", 1, true) or data:find("verify", 1, true)) then return end; if origData then origData(data) end end
            TssSdk.SendReportInfo = nop; TssSdk.ScanMemory = retTrue; TssSdk.IsEmulator = retFalse; TssSdk.GetTssSdkReportInfo = retEmptyString; TssSdk.CheckEnvironment = retTrue; TssSdk.VerifyProcess = retTrue
        end
    end)
end

local function InitializeReplayTelemetryBlocker()
    pcall(function()
        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            for _, name in ipairs({"GameReportSubsystem", "ReplaySubsystem"}) do
                local sub = SubMgr:Get(name)
                if sub then for k, v in pairs(sub) do if type(v) == "function" and (k:find("Report") or k:find("Trace") or k:find("Replay") or k:find("Record") or k:find("Save")) then pcall(function() sub[k] = nop end) end end end
            end
        end
        local logRep = package.loaded["client.slua.logic.replay.logic_report_replay"]
        if logRep then logRep.ReportReplay = nop; logRep.SendReportReq = nop; logRep.UploadReplay = nop end
    end)
end

local function InitializeReportFlowBlocker()
    pcall(function()
        local flows = {"ReportAimFlow", "ReportHitFlow", "ReportAttackFlow", "ReportSecAttackFlow", "ReportFireArms", "ReportVerifyInfoFlow", "ReportMrpcsFlow", "ReportPlayerBehavior", "ReportTeammatHurt", "ReportMisKillByTeammate", "ReportForbitPick", "ReportPlayerMoveRoute", "ReportPlayerPosition", "ReportVehicleMoveFlow", "ReportSecTgameMovingFlow", "ReportParachuteData", "ReportEquipmentFlow", "ReportPlayersPing", "ReportPlayerIP", "ReportPlayerFramePingRecord", "ReportDSNetSaturation", "ReportNetContinuousSaturate", "ReportDSNetRate", "ReportCircleFlow", "ReportSecMrpcsFlow"}
        for _, f in ipairs(flows) do if _G[f] then _G[f] = nop end; if _G.GameplayCallbacks and _G.GameplayCallbacks[f] then _G.GameplayCallbacks[f] = nop end end
        for _, f in ipairs({"CheckReportSecAttackFlowWithAttackFlow", "CheckReportSecAttackFlow"}) do if _G[f] then _G[f] = retFalse end; if _G.GameplayCallbacks and _G.GameplayCallbacks[f] then _G.GameplayCallbacks[f] = retFalse end end
        for _, f in ipairs({"IsEnableReportMrpcsInCircleFlow", "IsEnableReportMrpcsInPartCircleFlow", "IsEnableReportMrpcsFlow", "IsEnableReportAttackFlow", "IsEnableReportHitFlow", "IsEnableReportCircleFlow"}) do if _G[f] then _G[f] = retFalse end end
    end)
end

local function InitializePlayerSecurityBypass()
    pcall(function()
        for _, c in ipairs({"PlayerSecurityInfoCollector", "PlayerSecurityInfo", "SecurityInfoCollector", "ClientSecurityCollector", "PlayerAntiCheatCollector"}) do
            if _G[c] then for k, v in pairs(_G[c]) do if type(v) == "function" and (k:find("Report") or k:find("Collect") or k:find("Send") or k:find("Upload") or k:find("Record")) then _G[c][k] = nop end end end
        end
        local SecSub = require("GameLua.Mod.BaseMod.Common.Security.PlayerSecurityInfoSubsystem")
        if SecSub then SecSub.ReportData = nop; SecSub.CheckCheat = retFalse; SecSub.ValidatePlayer = retTrue; SecSub.CollectData = nop; SecSub.SendToServer = nop end
    end)
end

local function InitializeClientFlowBypass()
    pcall(function()
        for _, name in ipairs({"ClientSecMrpcsFlow", "MrpcsFlow", "MrpcsData", "ClientCircleFlowSubsystem", "ClientKillFlowSubsystem", "ClientSecPlayerKillFlow"}) do
            local sub = package.loaded[name] or _G[name]
            if sub then for k, v in pairs(sub) do if type(v) == "function" and (k:find("Report") or k:find("Send") or k:find("Flow") or k:find("Record") or k:find("Process")) then pcall(function() sub[k] = nop end) end end end
        end
    end)
end

local function InitializeSwiftHawkBypass()
    pcall(function()
        for _, f in ipairs({"SwiftHawk", "ClientSwiftHawk", "ClientSwiftHawkWithParams", "SendSwiftHawkData"}) do if _G[f] then _G[f] = nop end; if _G.GameplayCallbacks and _G.GameplayCallbacks[f] then _G.GameplayCallbacks[f] = nop end end
        local sub = package.loaded["GameLua.Mod.BaseMod.Client.Security.SwiftHawkSubsystem"]
        if sub then sub.ReportData = nop; sub.SendReport = nop; sub.CollectTelemetry = nop end
    end)
end

local function InitializeCoronaLabBypass()
    pcall(function()
        if _G.CoronaLab then _G.CoronaLab.ReportData = nop; _G.CoronaLab.SendData = nop; _G.CoronaLab.CollectData = nop; _G.CoronaLab.Telemetry = nop end
        local sub = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("CoronaLabSubsystem")
        if sub then sub.ReportData = nop; sub.SendToServer = nop; sub.CollectTelemetry = nop; sub.StopCollection = nop end
    end)
end

local function InitializeModifierExceptionBypass()
    pcall(function()
        if _G.bReportedModifierException then _G.bReportedModifierException = false end
        local sub = require("GameLua.Mod.BaseMod.Common.Security.ModifierExceptionSubsystem")
        if sub then sub.ReportException = nop; sub.CheckModifier = retTrue; sub.ValidateModifier = retTrue; sub.ReportModifierError = nop end
    end)
end

local function InitializeSimulateCharacterLocationBypass()
    pcall(function()
        local sub = require("GameLua.Mod.BaseMod.Gameplay.Simulate.SimulateCharacterSubsystem")
        if sub then sub.ReportLocation = nop; sub.SendLocationData = nop; sub.VerifyLocation = retTrue end
    end)
end

local function InitializeShootVerificationBypass()
    pcall(function()
        local sub = require("GameLua.Dev.Subsystem.ShootVerifySubSystemClient")
        if sub then sub.OnShootVerifyFailed = nop; sub.SendVerifyData = nop; sub.ReportBulletHit = nop; sub.UploadHitInfo = nop; sub.VerifyShot = retTrue end
        if _G.BulletHitInfoUploadData then _G.BulletHitInfoUploadData.Report = nop; _G.BulletHitInfoUploadData.Send = nop; _G.BulletHitInfoUploadData.Upload = nop end
    end)
end

local function InitializeNetworkPacketBlock()
    pcall(function()
        if NetUtil and NetUtil.SendPacket then
            local orig = NetUtil.SendPacket
            local blocked = {
                ["ReportAttackFlow"]=1, ["ReportSecAttackFlow"]=1, ["ReportFireArms"]=1, ["ReportVerifyInfoFlow"]=1, ["ReportMrpcsFlow"]=1,
                ["ReportPlayerBehavior"]=1, ["ReportTeammatHurt"]=1, ["ReportPlayerMoveRoute"]=1, ["ReportPlayerPosition"]=1, ["ReportSecVehicleMoveFlow"]=1,
                ["report_parachute_data"]=1, ["on_tss_sdk_anti_data"]=1, ["ReportAimFlow"]=1, ["ReportHitFlow"]=1, ["ReportCircleFlow"]=1, ["report_players_ping"]=1,
                ["report_player_ip"]=1, ["report_net_saturate"]=1, ["report_speed_hack"]=1, ["report_wall_hack"]=1, ["report_aim_bot"]=1, ["report_esp_usage"]=1,
                ["report_modded_files"]=1, ["detect_cheat"]=1, ["ban_player"]=1, ["client_anti_cheat_report"]=1,
                ["ClientSecMrpcsFlow"]=1, ["MrpcsData"]=1, ["CheckReportSecAttackFlow"]=1, ["CheckReportSecAttackFlowWithAttackFlow"]=1, ["RPC_ClientCoronaLab"]=1,
                ["CoronaLabReport"]=1, ["CoronaLabData"]=1, ["PlayerSecurityInfo"]=1, ["ReportSecurityInfo"]=1, ["SendSecurityData"]=1, ["ClientCircleFlow"]=1,
                ["IsEnableReportMrpcsInCircleFlow"]=1, ["IsEnableReportMrpcsInPartCircleFlow"]=1, ["bReportedModifierException"]=1,
                ["ReportModifierException"]=1, ["RPC_Server_ReportSimulateCharacterLocation"]=1, ["ReportSimulateCharacterLocation"]=1, ["RPC_Client_ShootVertifyRes"]=1,
                ["BulletHitInfoUploadData"]=1, ["ShootVerifyFailed"]=1, ["report_unrealnet_exception"]=1, ["tss_sdk_report"]=1, ["SwiftHawk"]=1, ["ClientSwiftHawk"]=1, ["ClientSwiftHawkWithParams"]=1, ["SwiftHawkReport"]=1, ["SwiftHawkData"]=1,
                ["AntiCheatReport"]=1, ["CheatDetection"]=1, ["ViolationReport"]=1, ["SecurityViolation"]=1, ["IntegrityCheck"]=1, ["SignatureVerify"]=1
            }
            NetUtil.SendPacket = function(packetName, ...) if blocked[packetName] then return nil end; return orig(packetName, ...) end
            NetUtil.IsBypassed = true
        end
        if _G.SendRPC then
            local origRPC = _G.SendRPC
            local blockedRPC = {"RPC_Server_ClientSecMrpcsFlow", "RPC_Server_SwiftHawk", "RPC_Server_ClientSwiftHawkWithParams", "RPC_Server_ReportSimulateCharacterLocation", "RPC_Client_ShootVertifyRes", "RPC_ClientCoronaLab"}
            _G.SendRPC = function(rpcName, ...) for _, b in ipairs(blockedRPC) do if rpcName == b then return nil end end; return origRPC(rpcName, ...) end
        end
    end)
end

local function InitializeHiggsBosonBypass()
    pcall(function()
        local Higgs = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if Higgs then
            for _, m in ipairs({"ControlMHActive", "Tick", "OnTick", "MHActiveLogic", "TriggerAvatarCheck", "StartAvatarCheck", "ReportItemID", "ReceiveAnyDamage", "OnWeaponHitRecord", "ShowSecurityAlert", "ServerReportAvatar", "ClientReportNetAvatar", "SendHisarData", "ValidateSecurityData", "StaticShowSecurityAlertInDev", "RPC_Client_ShootVertifyRes", "RPC_Server_ReportSimulateCharacterLocation", "DisableHiggsBoson", "CheckMHActive", "ReportViolation", "ProcessSecurityEvent", "ValidatePlayer", "CheckIntegrity"}) do
                if Higgs[m] then Higgs[m] = nop end
            end
            Higgs.GetNetAvatarItemIDs = retEmpty; Higgs.GetCurWeaponSkinID = retZero; Higgs.IsMHActive = retFalse; Higgs.bMHActive = false; Higgs.bCallPreReplication = false
            if Higgs.BlackList then for k in pairs(Higgs.BlackList) do Higgs.BlackList[k] = nil end end
        end
        _G.BlackList = {}
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) then
            if pc.HiggsBoson then pc.HiggsBoson.bMHActive = false; pc.HiggsBoson.bCallPreReplication = false; if pc.HiggsBoson.ControlMHActive then pc.HiggsBoson:ControlMHActive(0) end end
            if pc.HiggsBosonComponent then pc.HiggsBosonComponent.bMHActive = false; pc.HiggsBosonComponent.bCallPreReplication = false; pc.HiggsBosonComponent:ControlMHActive(0) end
        end
    end)
end

local function InitializeAntiCheatHooks()
    pcall(function()
        local HBC = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if HBC and HBC.StaticShowSecurityAlertInDev then HBC.StaticShowSecurityAlertInDev = nop end
    end)
    if _G.AvatarCheckCallback then
        _G.AvatarCheckCallback.StartAvatarCheck = nop; _G.AvatarCheckCallback.OnReportItemID = nop
        _G.AvatarCheckCallback.PostPlayerControllerLoginInit = function(PlayerController)
            if slua.isValid(PlayerController) and PlayerController.HiggsBosonComponent then PlayerController.HiggsBosonComponent:ControlMHActive(0); PlayerController.HiggsBosonComponent.bMHActive = false end
        end
    end
end

local function InitializeAntiReport()
    pcall(function()
        for _, path in ipairs({"GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem", "Client.Security.ClientReportPlayerSubsystem", "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem"}) do
            local sub = package.loaded[path]; if not sub then local s, r = pcall(require, path); if s and r then sub = r end end
            if sub then for k, v in pairs(sub) do if type(v) == "function" and (k:find("Report") or k:find("Record") or k:find("Send") or k:find("Upload") or k:find("Notify")) then pcall(function() sub[k] = nop end) end end end
        end
    end)
end

local function InitializeGameplayBypass()
    pcall(function()
        if not _G.GameplayCallbacks then _G.GameplayCallbacks = {} end
        if _G.GameplayCallbacks.IsBypassed then return end
        local GC = _G.GameplayCallbacks
        local reports = {"ReportAttackFlow", "ReportSecAttackFlow", "ReportFireArms", "ReportVerifyInfoFlow", "ReportMrpcsFlow", "ReportPlayerBehavior", "ReportTeammatHurt", "ReportMisKillByTeammate", "ReportForbitPick", "ReportPlayerMoveRoute", "ReportPlayerPosition", "ReportVehicleMoveFlow", "ReportSecTgameMovingFlow", "ReportParachuteData", "SendTssSdkAntiDataToLobby", "ReportEquipmentFlow", "ReportAimFlow", "ReportPlayersPing", "ReportPlayerIP", "ReportPlayerFramePingRecord", "OnDSConnectionSaturated", "ReportDSNetSaturation", "ReportNetContinuousSaturate", "ReportDSNetRate", "SendClientStats", "SendServerAvgTickDelta", "ReportCircleFlow", "ClientSecMrpcsFlow", "SwiftHawk", "ClientSwiftHawk", "ClientSwiftHawkWithParams"}
        for _, f in ipairs(reports) do GC[f] = nop end
        GC.CheckReportSecAttackFlowWithAttackFlow = retFalse; GC.CheckReportSecAttackFlow = retFalse
        local origState = GC.OnDSPlayerStateChanged
        GC.OnDSPlayerStateChanged = function(UID, State, bPure, bSafe, Param)
            local s = State and string.lower(tostring(State)) or ""
            local blocked = {["cheatdetected"]=1, ["connectionlost"]=1, ["connectiontimeout"]=1, ["connectionexception"]=1, ["netdrivererror"]=1, ["banned"]=1, ["kicked"]=1, ["suspended"]=1, ["violationdetected"]=1, ["integrityfailure"]=1, ["securityviolation"]=1}
            if blocked[s] then return end
            if origState then pcall(origState, UID, State, bPure, bSafe, Param) end
        end
        GC.OnPlayerNetConnectionClosed = nop; GC.OnPlayerActorChannelError = nop; GC.OnPlayerRPCValidateFailed = nop; GC.OnPlayerSpectateException = nop; GC.OnShutdownAfterError = nop; GC.IsBypassed = true
    end)
end

local function InitializeKillAllSubsystems()
    pcall(function()
        local subMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if not subMgr then return end
        local toKill = {"CoronaLabSubsystem", "PlayerSecurityInfoSubsystem", "ClientCircleFlowSubsystem", "ModifierExceptionSubsystem", "SimulateCharacterSubsystem", "ShootVerifySubSystemClient", "HiggsBosonComponent", "ClientReportPlayerSubsystem", "DSReportPlayerSubsystem", "ClientHawkEyePatrolSubsystem", "DSHawkEyePatrolSubsystem", "ClientDataStatistcsSubsystem", "AFKReportorSubsystem", "BehaviorScoreSubsystem", "FileCheckSubsystem", "MemoryCheckSubsystem", "SpeedCheckSubsystem", "WallCheckSubsystem", "AvatarExceptionSubsystem", "GameReportSubsystem", "ClientSecMrpcsFlowSubsystem", "MrpcsFlowSubsystem", "CircleFlowSubsystem", "SwiftHawkSubsystem", "AntiCheatSubsystem", "IntegrityCheckSubsystem", "SignatureVerifySubsystem", "MD5CheckSubsystem", "PakVerifySubsystem"}
        for _, name in ipairs(toKill) do
            local sub = subMgr:Get(name)
            if sub then
                for k, v in pairs(sub) do if type(v) == "function" and (k:find("Report") or k:find("Send") or k:find("Upload") or k:find("Verify") or k:find("Check") or k:find("Validate") or k:find("Scan") or k:find("Detect") or k:find("Collect") or k:find("Flow") or k:find("Heartbeat")) then pcall(function() sub[k] = nop end) end end
                if sub.timer then pcall(function() sub:RemoveGameTimer(sub.timer) end) end
                if sub.heartbeatTimer then pcall(function() sub:RemoveGameTimer(sub.heartbeatTimer) end) end
                if sub.reportTimer then pcall(function() sub:RemoveGameTimer(sub.reportTimer) end) end
            end
        end
    end)
end

local function InitializeFinalProtection()
    pcall(function()
        for _, flag in ipairs({"ENABLE_REPORT", "ENABLE_ANTI_CHEAT", "ENABLE_SECURITY", "ENABLE_TELEMETRY", "ENABLE_ANALYTICS", "ENABLE_CRASH_REPORT", "ENABLE_PERFORMANCE_REPORT"}) do if _G[flag] then _G[flag] = false end end
        local origReq = require
        local blocked = {"HiggsBosonComponent", "PlayerSecurityInfoSubsystem", "CoronaLabSubsystem", "ClientCircleFlowSubsystem", "ModifierExceptionSubsystem", "ShootVerifySubSystemClient", "ClientReportPlayerSubsystem", "DSReportPlayerSubsystem"}
        _G.require = function(m) for _, b in ipairs(blocked) do if m:find(b) then return {} end end; return origReq(m) end
    end)
end

_G.StartBypass_VIP_v3 = function()
    pcall(function()
        print("[ULTIMATE BYPASS] Starting initialization...")
        InitializeSLUABypass()
        InitializeMD5Bypass()
        InitializeSkinBypass()
        InitializeLogBlocker()
        InitializeScannerBlocker()
        InitializeReplayTelemetryBlocker()
        InitializeReportFlowBlocker()
        InitializePlayerSecurityBypass()
        InitializeClientFlowBypass()
        InitializeSwiftHawkBypass()
        InitializeCoronaLabBypass()
        InitializeModifierExceptionBypass()
        InitializeSimulateCharacterLocationBypass()
        InitializeShootVerificationBypass()
        InitializeNetworkPacketBlock()
        InitializeHiggsBosonBypass()
        InitializeAntiCheatHooks()
        InitializeAntiReport()
        InitializeGameplayBypass()
        InitializeKillAllSubsystems()
        InitializeFinalProtection()
        print("[ULTIMATE BYPASS] Complete - All Security Systems Disabled")
    end)
end

-- ========================================== 
-- HÀM QUẢN LÝ DỌN RÁC MAP MARK (CHỐNG LAG/HIỂN THỊ ẢO KHI ĐỊCH CHẾT)
-- ========================================== 
local function SafeAddMark(id, pos, z, str, size, actor)
    local mark = nil
    pcall(function()
        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
            mark = InGameMarkTools.ClientAddMapMark(id, pos, z, str, size, actor)
            if mark then _G.LexusState.TrackedMarks[mark] = true end
        end
    end)
    return mark
end

local function SafeRemoveMark(mark)
    if not mark then return end
    pcall(function()
        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        if InGameMarkTools and InGameMarkTools.HideMapMark then
            InGameMarkTools.HideMapMark(mark)
        end
        if InGameMarkTools and InGameMarkTools.RemoveMapMark then
            InGameMarkTools.RemoveMapMark(mark)
        end
    end)
    _G.LexusState.TrackedMarks[mark] = nil
end

-- ========================================== 
-- TẠO ID DUY NHẤT VÀ VĨNH VIỄN CHO MỖI KẺ ĐỊCH (SỬA LỖI GIẬT LAG KHI SLUA TẠO WRAPPER MỚI)
-- ==========================================
local function GetSafeEnemyKey(enemy)
    if Valid(enemy) then
        if enemy.PlayerKey then return tostring(enemy.PlayerKey) end
        if type(enemy.GetUniqueID) == "function" then return tostring(enemy:GetUniqueID()) end
    end
    return tostring(enemy)
end

-- ========================================== 
-- KIỂM TRA PHÂN BIỆT AI (BOT) / REAL PLAYER - OPTIMIZED
-- ==========================================
local function CheckIsAI(pawn, markData)
    if markData.AK_IS_BOT ~= nil then return markData.AK_IS_BOT, true end
    
    local isAI = false
    local hasChecked = false
    pcall(function()
        if pawn.bIsAI == true or pawn.IsAI == true then isAI = true; hasChecked = true end
        if type(pawn.IsBot) == "function" and pawn:IsBot() then isAI = true; hasChecked = true end
        
        local pState = pawn.PlayerState or (type(pawn.GetPlayerState) == "function" and pawn:GetPlayerState())
        if Valid(pState) then
            hasChecked = true
            if pState.bIsABot == true or pState.bIsBot == true then isAI = true end
            if type(pState.IsBot) == "function" and pState:IsBot() then isAI = true end
        end
        
        if not isAI then
            local name = pawn.PlayerName or (type(pawn.GetPlayerName) == "function" and pawn:GetPlayerName()) or ""
            if name ~= "" and (name:find("Cobra") or name:find("Target") or name:find("bot_") or name:find("b_")) then
                isAI = true
                hasChecked = true
            end
        end
    end)
    if hasChecked then markData.AK_IS_BOT = isAI end
    return isAI, hasChecked
end

-- ==============================================================================
-- ================= DATA & LOGIC MOD SKIN ======================================
-- ==============================================================================
_G.VIP_Attachments = {
    [1101004236]={1010042307,1010042306,1010042308,1010042304,1010042300,1010042305,1010042299,1010042298,1010042297,1010042296,1010042295,1010042294,0,1010042314,1010042309,1010042316,1010042317,1010042318,1010042310,1010042315,1010042319,0},
    [1101001116]={1010011106,1010011107,1010011108,0,1010011109,1010011112,1010011105,1010011104,1010011103,0,1010011102,0,0,0,0,0,0,0,0,0,0,0},
    [1101001128]={1010011232,1010011233,1010011234,1010011228,1010011227,1010011229,1010011226,1010011225,1010011224,1010011223,1010011222,0,0,0,0,0,0,0,0,0,0,0},
    [1101001154]={1010011487,1010011488,1010011489,1010011493,1010011490,1010011494,1010011486,1010011485,1010011484,1010011483,1010011482,1010011497,0,0,0,0,0,0,0,0,1010011498,0},
    [1101001174]={1010011667,1010011668,1010011669,1010011673,1010011670,1010011674,1010011666,1010011665,1010011664,1010011663,1010011662,0,0,0,0,0,0,0,0,0,0,0},
    [1101001213]={1010012067,1010012068,1010012069,1010012072,1010012070,1010012073,1010012066,1010012065,1010012064,1010012063,1010012062,0,0,0,0,0,0,0,0,1010012074,0},
    [1101001231]={1010012267,1010012268,1010012269,1010012273,1010012272,1010012274,1010012266,1010012265,1010012264,1010012263,1010012262,1010012075,0,0,0,0,0,0,0,0,1010012275,0},
    [1101001242]={1010012357,1010012358,1010012359,1010012363,1010012362,1010012364,1010012356,1010012355,1010012354,1010012353,1010012352,1010012276,0,0,0,0,0,0,0,0,1010012365,0},
    [1101001249]={1010012437,1010012438,1010012439,1010012443,1010012442,1010012444,1010012436,1010012435,1010012434,1010012433,1010012432,1010012366,0,0,0,0,0,0,0,0,1010012445,0},
    [1101001256]={1010012588,1010012589,1010012590,1010012593,1010012592,1010012594,1010012587,1010012586,1010012585,1010012584,1010012583,1010012582,0,0,0,0,0,0,0,0,1010012595,0},
    [1101001265]={1010012698,1010012699,1010012700,1010012703,1010012702,1010012704,1010012697,1010012696,1010012695,1010012694,1010012693,1010012692,0,0,0,0,0,0,0,0,1010012705,0},
    [1101001276]={1010012698,1010012699,1010012700,1010012703,1010012702,1010012704,1010012697,1010012696,1010012695,1010012694,1010012693,1010012692,0,0,0,0,0,0,0,0,1010012705,0},
    [1101002029]={1010020249,1010020250,1010020255,1010020247,1010020246,1010020248,1010020240,1010020239,1010020238,1010020237,1010020236,1010020235,0,0,0,0,0,0,0,1010020257,1010020256,1010020258},
    [1101002056]={1010020519,0,0,1010020517,1010020516,1010020518,1010020500,1010020509,1010020508,1010020507,1010020506,1010020505,0,0,0,0,0,0,0,0,0,0},
    [1101002081]={1010020768,1010020769,1010020770,1010020766,1010020760,1010020767,1010020759,1010020758,1010020757,1010020756,1010020755,1010020776,0,0,0,0,0,0,0,1010020775,1010020777,1010020778},
    [1101003070]={1010030654,1010030653,1010030655,1010030649,1010030648,1010030650,1010030647,1010030646,1010030645,1010030644,1010030643,1010030642,0,1010030658,1010030656,1010030660,1010030662,1010030659,1010030657,0,1010030663,0},
    [1101003080]={1010030754,1010030753,1010030755,1010030749,1010030748,1010030750,1010030747,1010030746,1010030745,1010030744,1010030743,1010030742,0,1010030758,1010030756,1010030760,1010030762,1010030759,1010030757,0,1010030763,0},
    [1101003099]={1010030943,1010030944,1010030945,1010030939,1010030938,1010030942,1010030937,1010030936,1010030935,1010030934,1010030933,1010030932,0,1010030947,1010030946,1010030948,1010030949,1010030953,1010030952,0,1010030955,0},
    [1101003119]={1010031139,1010031140,1010031142,1010031138,1010031137,1010031146,1010031136,1010031135,1010031134,1010031133,1010031132,0,0,1010031144,1010031143,0,0,0,1010031145,0,0,0},
    [1101003146]={1010031229,1010031230,1010031237,1010031228,1010031227,1010031242,1010031226,1010031225,1010031224,1010031223,1010031222,0,0,1010031239,1010031238,0,0,0,1010031240,0,0,0},
    [1101003167]={1010031609,1010031610,1010031613,1010031608,1010031607,1010031617,1010031606,1010031605,1010031604,1010031603,1010031602,1010031618,0,1010031615,1010031614,1010031620,1010031622,1010031619,1010031616,0,1010031623,0},
    [1101003181]={1010031765,1010031764,1010031766,1010031759,1010031758,1010031763,1010031757,1010031756,1010031755,1010031754,1010031753,1010031752,0,1010031769,1010031767,1010031773,1010031774,1010031772,1010031768,0,1010031775,0},
    [1101003195]={1010031912,1010031911,1010031913,1010031908,1010031907,1010031909,1010031906,1010031905,1010031904,1010031903,1010031902,1010031901,0,1010031916,1010031914,1010031918,1010031919,1010031917,1010031915,0,1010031921,0},
    [1101003208]={1010032034,1010032033,1010032045,1010032029,1010032028,1010032032,1010032027,1010032026,1010032025,1010032024,1010032023,1010032022,0,1010032038,1010032036,1010032042,1010032043,1010032039,1010032037,0,1010032044,0},
    [1101004046]={1010040474,1010040475,1010040476,1010040472,1010040471,1010040473,1010040470,1010040469,1010040468,1010040467,1010040466,1010040481,0,1010040479,1010040477,1010040482,1010040483,1010040484,1010040478,1010040480,1010040485,0},
    [1101004062]={1010040578,1010040577,1010040579,1010040575,1010040570,1010040576,1010040569,1010040568,1010040567,1010040566,1010040565,1010040564,0,1010040585,1010040580,1010040587,1010040588,1010040589,1010040584,1010040586,1010040590,1010040594},
    [1101004098]={1010040924,1010040926,1010040925,0,1010040937,1010040938,1010040935,1010040934,1010040929,1010040928,1010040927,0,0,1010040939,1010040945,0,0,0,1010040944,1010040936,0,0},
    [1101004138]={1010041136,1010041137,1010041138,1010041134,1010041129,1010041135,1010041128,1010041127,1010041126,1010041125,1010041124,0,0,1010041145,1010041139,0,0,0,1010041144,1010041146,0,0},
    [1101004163]={1010041570,1010041574,1010041575,1010041568,1010041567,1010041569,1010041566,1010041565,1010041564,1010041560,1010041554,0,0,1010041578,1010041576,0,0,0,1010041577,1010041579,0,0},
    [1101004201]={1010041956,1010041957,1010041958,1010041950,1010041949,1010041955,1010041948,1010041947,1010041946,1010041945,1010041944,1010041967,0,1010041965,1010041959,0,0,0,1010041960,1010041966,0,0},
    [1101004209]={1010042038,1010042037,1010042039,1010042035,1010042034,1010042036,1010042029,1010042028,1010042027,1010042026,1010042025,1010042024,0,1010042046,1010042044,1010042048,1010042049,1010042054,1010042045,1010042047,1010042055,0},
    [1101004218]={1010042128,1010042127,1010042129,1010042125,1010042124,1010042126,1010042119,1010042118,1010042117,1010042116,1010042115,1010042114,0,1010042136,1010042134,1010042138,1010042139,1010042144,1010042135,1010042137,1010042145,0},
    [1101004226]={1010042238,1010042237,1010042239,1010042235,1010042234,1010042236,1010042233,1010042232,1010042231,1010042219,1010042218,1010042217,0,1010042243,1010042241,1010042245,1010042246,1010042247,1010042242,1010042244,1010042248,0},
    [1101004246]={1010042406,1010042407,1010042408,1010042404,1010042400,1010042405,1010042399,1010042398,1010042397,1010042396,1010042395,1010042394,0,1010042414,1010042409,1010042416,1010042417,1010042418,1010042410,1010042415,1010042419,1010042420},
    [1101005038]={0,0,1010050327,1010050329,1010050328,1010050330,1010050326,1010050325,1010050324,1010050323,1010050322,1010050334,0,0,0,0,0,0,0,0,0,0},
    [1101005052]={0,0,1010050467,1010050469,1010050468,1010050470,1010050466,1010050465,1010050464,1010050463,1010050462,1010050473,0,0,0,0,0,0,0,0,0,0},
    [1101005098]={0,0,1010050928,1010050930,1010050929,1010050932,1010050927,1010050926,1010050925,1010050924,1010050923,1010050922,0,0,0,0,0,0,0,0,0,0},
    [1101006062]={1010060573,1010060572,1010060574,1010060564,1010060563,1010060571,1010060562,1010060561,1010060554,1010060553,1010060552,1010060551,0,1010060583,1010060581,1010060591,1010060592,1010060584,1010060582,0,1010060593,0},
    [1101006075]={1010060702,1010060701,1010060703,1010060698,1010060697,1010060699,1010060696,1010060695,1010060694,1010060693,1010060692,1010060691,0,1010060706,1010060704,1010060708,1010060709,1010060707,1010060705,0,1010060711,0},
    [1101006085]={1010060796,1010060795,1010060797,1010060793,1010060789,1010060794,1010060788,1010060787,1010060786,1010060785,1010060784,1010060783,0,1010060800,1010060798,1010060804,1010060805,1010060803,1010060799,0,1010060806,0},
    [1101007046]={1010070410,1010070413,1010070414,1010070408,1010070407,1010070409,1010070406,1010070405,1010070404,1010070403,1010070402,1010070418,0,1010070417,1010070415,1010070420,1010070422,1010070419,1010070416,0,1010070423,0},
    [1101007062]={1010070579,1010070578,1010070581,1010070576,1010070575,1010070577,1010070574,1010070573,1010070572,1010070571,1010070569,1010070568,0,1010070584,1010070582,1010070585,1010070586,1010070587,1010070583,0,1010070588,0},
    [1101007071]={1010070663,1010070662,1010070664,1010070659,1010070658,1010070660,1010070657,1010070656,1010070655,1010070654,1010070653,1010070652,0,1010070667,1010070665,1010070668,1010070669,1010070670,1010070666,0,1010070672,0},
    [1101008051]={1010080463,1010080464,1010080465,1010080459,1010080458,1010080462,1010080457,1010080456,1010080455,1010080454,1010080453,1010080452,0,1010080467,1010080466,1010080468,1010080469,1010080473,1010080472,0,1010080475,0},
    [1101008061]={1010080563,1010080564,1010080565,1010080559,1010080558,1010080562,1010080557,1010080556,1010080555,1010080554,1010080553,0,0,1010080567,1010080566,0,0,0,1010080572,0,0,0},
    [1101008070]={1010080609,1010080612,1010080613,1010080608,1010080607,1010080617,1010080606,1010080605,1010080604,1010080603,1010080602,0,0,1010080615,1010080614,0,0,0,1010080616,0,0,0},
    [1101008081]={1010080740,1010080743,1010080745,1010080738,1010080737,1010080739,1010080736,1010080735,1010080734,1010080733,1010080732,1010080748,0,1010080747,1010080746,1010080750,1010080752,1010080749,1010080744,0,1010080753,0},
    [1101008104]={1010080980,1010080982,1010080984,1010080978,1010080977,1010080979,1010080976,1010080975,1010080974,1010080973,1010080972,1010080992,0,1010080986,1010080985,1010080989,1010080987,1010080993,1010080983,0,1010080988,0},
    [1101008116]={1010081110,1010081112,1010081114,1010081108,1010081107,1010081109,1010081106,1010081105,1010081104,1010081103,1010081102,0,0,1010081116,1010081115,0,0,0,1010081113,0,0,0},
    [1101008126]={1010081210,1010081225,1010081226,1010081208,1010081207,1010081209,1010081206,1010081205,1010081204,1010081203,1010081202,1010081218,0,1010081217,1010081216,1010081219,1010081220,1010081222,1010081214,1010081228,1010081227,1010081229},
    [1101008136]={1010081314,1010081315,1010081316,1010081312,1010081308,1010081313,1010081307,1010081306,1010081305,1010081304,1010081303,1010081302,0,1010081318,1010081317,1010081322,1010081323,1010081325,1010081324,0,1010081326,0},
    [1101008146]={1010081401,1010081402,1010081403,1010081398,1010081397,1010081399,1010081396,1010081395,1010081394,1010081393,1010081392,1010081391,0,1010081405,1010081404,1010081406,1010081407,1010081409,1010081408,0,1010081411,0},
    [1101008154]={1010081531,1010081532,1010081533,1010081528,1010081527,1010081529,1010081526,1010081525,1010081524,1010081523,1010081522,1010081521,0,1010081541,1010081534,1010081542,1010081543,1010081545,1010081544,0,1010081546,0},
    [1101008163]={1010081582,1010081583,1010081584,1010081579,1010081578,1010081580,1010081577,1010081576,1010081575,1010081574,1010081573,1010081572,0,1010081586,1010081585,1010081587,1010081588,1010081590,1010081589,0,1010081592,0},
    [1101012033]={1010120284,1010120285,1010120286,1010120280,1010120279,1010120283,1010120278,1010120277,1010120276,1010120275,1010120274,1010120273,0,0,0,0,0,0,0,0,1010120287,0},
    [1101100012]={1011000066,1011000067,1011000068,0,0,0,1011000058,1011000057,1011000056,1011000055,1011000054,1011000053,0,0,0,0,0,0,0,0,1011000073,0},
    [1101102007]={1011010025,1011010024,1011010026,1011010020,1011010019,1011010023,1011010018,1011010017,1011010016,1011010015,1011010014,1011010013,0,0,0,0,0,0,0,0,1011010027,0},
    [1101102017]={1011020027,1011020028,1011020029,1011020025,1011020024,1011020026,1011020019,1011020018,1011020017,1011020016,1011020015,1011020014,0,1011020036,1011020034,1011020038,1011020039,1011020044,1011020035,1011020037,1011020045,1011020047},
    [1101102025]={1011020127,1011020128,1011020129,1011020125,1011020124,1011020126,1011020119,1011020118,1011020117,1011020116,1011020115,1011020114,0,1011020136,1011020134,1011020138,1011020139,1011020144,1011020135,1011020137,1011020145,0},
    [1101102041]={1011020214,1011020215,1011020216,1011020212,1011020211,1011020213,1011020209,1011020208,1011020207,1011020206,1011020205,1011020204,0,1011020219,1011020217,1011020222,1011020223,1011020224,1011020218,1011020221,1011020225,1011020229},
    [1101102049]={1011020356,1011020357,1011020358,1011020354,1011020350,1011020355,1011020349,1011020348,1011020347,1011020346,1011020345,1011020344,0,1011020364,1011020359,1011020366,1011020367,1011020368,1011020360,1011020365,1011020369,1011020370},
    [1101101007]={1011020436,1011020437,1011020438,1011020434,1011020430,1011020435,1011020429,1011020428,1011020427,1011020426,1011020425,1011020424,0,1011020444,1011020439,1011020446,1011020447,1011020448,1011020440,1011020445,1011020449,1011020450},
    [1102001120]={1020011137,1020011138,1020011139,1020011135,1020011134,1020011136,1020011133,1020011132,0,0,0,0,0,0,0,0,0,0,0,1020011142,0,0},
    [1102001130]={1020011247,1020011248,1020011249,1020011245,1020011244,1020011246,1020011243,1020011242,0,0,0,0,0,0,0,0,0,0,0,1020011250,0,0},
    [1102002043]={1020020372,1020020374,1020020373,1020020383,1020020380,1020020384,1020020379,1020020378,1020020377,1020020376,1020020375,1020020388,0,1020020385,1020020387,0,0,0,1020020386,0,0,0},
    [1102002061]={1020020552,1020020554,1020020553,1020020563,1020020562,1020020564,1020020559,1020020558,1020020557,1020020556,1020020555,1020020578,0,1020020565,1020020567,1020020573,1020020574,1020020572,1020020566,0,1020020569,0},
    [1102002136]={1020021314,1020021313,1020021315,1020021309,1020021308,1020021312,1020021307,1020021306,1020021305,1020021304,1020021303,1020021302,0,1020021318,1020021316,1020021323,1020021324,1020021322,1020021317,0,1020021325,0},
    [1102002424]={1020024193,1020024192,1020024194,1020024189,1020024188,1020024190,1020024187,1020024186,1020024185,1020024184,1020024183,1020024182,0,1020024197,1020024195,1020024199,1020024200,1020024198,1020024196,0,1020024202,0},
    [1102003080]={1020030755,1020030756,1020030758,0,1020030749,1020030754,1020030748,1020030747,1020030746,1020030745,1020030744,1020030764,0,1020030760,0,1020030759,1020030757,0,0,1020030765,0,0},
    [1102003100]={1020030956,1020030957,1020030958,1020030954,1020030950,1020030955,1020030949,1020030948,1020030947,1020030946,1020030945,1020030944,0,1020030964,0,1020030960,1020030959,1020030965,0,1020030967,1020030966,1020030968},
    [1102005064]={1020050588,1020050589,1020050590,0,0,0,1020050587,1020050586,1020050585,1020050584,1020050583,1020050582,0,0,0,0,0,0,0,0,1020050592,0},
    [1103001101]={1030010954,1030010955,1030010956,0,0,0,0,0,0,0,1030010953,1030010952,1030010951,0,0,0,0,0,0,1030010957,0,1030010958},
    [1103001146]={1030011344,1030011345,1030011346,0,0,0,0,0,0,0,1030011343,1030011342,1030011341,0,0,0,0,0,0,1030011347,0,1030011348},
    [1103001154]={1030011484,1030011485,1030011486,0,0,0,0,0,0,0,1030011483,1030011482,1030011481,0,0,0,0,0,0,1030011487,0,1030011488},
    [1103001179]={1030011738,1030011739,1030011741,0,0,0,1030011737,1030011736,1030011735,1030011734,1030011733,1030011732,1030011731,0,0,0,0,0,0,1030011742,1030011743,1030011744},
    [1103001191]={1030011858,1030011859,1030011861,0,0,0,1030011857,1030011856,1030011855,1030011854,1030011853,1030011852,1030011851,0,0,0,0,0,0,1030011862,1030011863,1030011864},
    [1103001202]={1030011948,1030011949,1030011950,0,0,0,1030011947,1030011946,1030011945,1030011944,1030011943,1030011942,1030011941,0,0,0,0,0,0,1030011951,1030011952,1030011953},
    [1103002030]={1030020245,1030020246,1030020247,1030020252,1030020249,1030020253,1030020258,1030020257,1030020256,1030020255,1030020244,1030020243,1030020242,0,0,0,0,0,0,1030020248,0,0},
    [1103002059]={1030020544,1030020545,1030020546,1030020542,1030020539,1030020543,1030020538,1030020537,1030020536,1030020535,1030020534,1030020533,1030020532,0,0,0,0,0,0,1030020547,1030020548,0},
    [1103002087]={1030020824,1030020825,1030020826,0,0,0,1030020818,1030020817,1030020816,1030020815,1030020814,1030020813,1030020812,0,0,0,0,0,0,1030020827,1030020828,0},
    [1103002106]={1030021009,1030021010,1030021012,1030021015,1030021014,1030021016,1030021008,1030021007,1030021006,1030021005,1030021004,1030021003,1030021002,0,0,0,0,0,0,1030021013,1030021017,0},
    [1103002113]={1030021079,1030021080,1030021082,1030021085,1030021084,1030021086,1030021078,1030021077,1030021076,1030021075,1030021074,1030021073,1030021072,0,0,0,0,0,0,1030021083,1030021087,0},
    [1103003022]={1030030165,1030030166,1030030167,1030030172,1030030169,1030030173,0,0,0,0,1030030164,1030030163,1030030162,0,0,0,0,0,0,0,0,0},
    [1103003030]={1030030256,1030030257,1030030258,1030030254,1030030253,1030030255,1030030248,1030030247,1030030246,1030030245,1030030244,1030030243,1030030242,0,0,0,0,0,0,1030030259,1030030249,0},
    [1103003042]={1030030374,1030030375,1030030376,1030030372,1030030369,1030030373,0,0,0,0,1030030364,1030030363,1030030362,0,0,0,0,0,0,1030030377,0,0},
    [1103003051]={1030030458,1030030459,1030030460,1030030456,1030030455,1030030457,0,0,0,0,1030030454,1030030453,1030030452,0,0,0,0,0,0,1030030463,0,0},
    [1103003062]={1030030568,1030030569,1030030570,1030030566,1030030565,1030030567,0,0,0,0,1030030564,1030030563,1030030562,0,0,0,0,0,0,1030030572,0,0},
    [1103003079]={1030030744,1030030745,1030030746,1030030742,1030030740,1030030743,1030030738,1030030737,1030030736,1030030735,1030030734,1030030733,1030030732,0,0,0,0,0,0,1030030747,1030030739,0},
    [1103003087]={1030030825,1030030826,1030030827,1030030823,1030030824,1030030824,1030030818,1030030817,1030030816,1030030815,1030030814,1030030813,1030030812,0,0,0,0,0,0,1030030828,1030030819,0},
    [1103004037]={1030040315,1030040316,1030040317,1030040325,1030040324,1030040323,0,0,0,0,1030040314,1030040313,1030040312,1030040327,1030040326,0,0,0,1030040328,1030040329,0,0},
    [1103006030]={1030060245,1030060246,1030060247,0,1030060253,1030060252,0,0,0,0,1030060244,1030060243,1030060242,0,0,0,0,0,0,0,0,0},
    [1103007028]={1030070233,1030070234,1030070235,1030070226,1030070225,1030070227,1030070218,1030070217,1030070216,1030070215,1030070214,1030070213,1030070212,0,0,0,0,0,0,1030070236,1030070219,0},
    [1103012010]={0,0,0,0,0,0,1030120038,1030120037,1030120036,1030120035,1030120034,1030120033,1030120032,0,0,0,0,0,0,0,0,0},
    [1103012019]={0,0,0,0,0,0,1030120138,1030120137,1030120136,1030120135,1030120134,1030120133,1030120132,0,0,0,0,0,0,0,0,0},
    [1103012031]={0,0,0,0,0,0,1030120258,1030120257,1030120256,1030120255,1030120254,1030120253,1030120252,0,0,0,0,0,0,0,0,0},
    [1103012039]={0,0,0,0,0,0,1030120339,1030120338,1030120337,1030120336,1030120335,1030120334,1030120333,0,0,0,0,0,0,0,0,0},
    [1103102007]={1031020026,1031020027,1031020028,1031020024,1031020023,1031020025,1031020019,1031020018,1031020017,1031020016,1031020015,1031020014,1031020013,0,0,0,0,0,0,1031020029,0,0},
    [1105001034]={0,0,0,0,1050010287,1050010289,1050010286,1050010285,1050010284,1050010283,1050010282,0,0,0,0,0,0,0,0,1050010292,0,0},
    [1105001048]={0,0,0,1050010429,1050010428,1050010434,1050010427,1050010426,1050010425,1050010424,1050010423,0,0,0,0,0,0,0,0,1050010435,0,1050010436},
    [1105001069]={0,0,0,1050010639,1050010638,1050010640,1050010637,1050010636,1050010635,1050010634,1050010633,1050010645,0,0,0,0,0,0,0,1050010643,1050010646,1050010644},
    [1105002091]={0,0,0,0,0,0,1050020847,1050020846,1050020845,1050020844,1050020843,1050020842,0,0,0,0,0,0,0,0,0,1050020848},
    [1105010019]={0,0,0,0,0,0,1050100144,1050100143,1050100142,1050100141,1050100139,1050100138,0,0,0,0,0,0,0,0,0,0}
}

_G.BaseAttachToIndex = {
    [201010]=1, [201005]=1, [201004]=1, [201009]=2, [201003]=2, [201002]=2, 
    [201011]=3, [201007]=3, [201006]=3, [204012]=4, [204005]=4, [204008]=4, 
    [204011]=5, [204004]=5, [204007]=5, [204013]=6, [204006]=6, [204009]=6, 
    [203001]=7, [203002]=8, [203003]=9, [203014]=10, [203004]=11, [203015]=12, [203005]=13, 
    [202002]=14, [202001]=15, [202004]=16, [202005]=17, [202007]=18, [202006]=19, 
    [205002]=20, [205003]=20, [205001]=20, [203018]=21, [204014]=22 
}

_G.VipAttachToIndex = {}
for skinId, attachList in pairs(_G.VIP_Attachments) do
    for index, attachId in ipairs(attachList) do
        if attachId > 0 then
            _G.VipAttachToIndex[attachId] = index
        end
    end
end

_G.WeaponSkinMap = _G.WeaponSkinMap or {}
_G.VehicleSkinMap = _G.VehicleSkinMap or {}
_G.OutfitMap = _G.OutfitMap or {}
_G.skinIdCache = _G.skinIdCache or {}
_G.skinIdCache2 = _G.skinIdCache2 or {}

_G.OutfitSkins = {
    Suit = {1405628,1407920,1407916,1407895,1405760,1407870,1407856,1407812,1407758,1407789,1407682,1407696,1407695,1407632,1407631,1407667,1407618,1407573,1407572,1407559,1407558,1407550,1407523,1407718,1407512,1407471,1407470,1406985,1407353,1407366,1407330,1407487,1410668,1407276,1407275,1407142,1407141,1407140,1406971,1406897,1406891,1407187,1405802,1405192,1405334,1400687,1405340,1405623,1405132,1405436,1405435,1405434,1405433,1405208,1407916,1407917,1407918,1407921,1407921,1407926,1407901,1407902,1407903,1407904,1407822,1407823,1407824,1407825,1407807,1407808,1407845,1407846,1407847,1407848,1407794,1411037,1407795,1411038,1407796,1411039},
    Pants = {1404002,1404050,1404425,1404495,1400650,1404522,1404441,1404152,1404196,1404134,1404137,1404164,1404191,1404466,1400052,404035,1404181,404084,1404516},
    Hair = {40605010,40605011,40605012,1410480,1410085,1410299,1402834,441400152,1400150,1402582,1410289,1402218,1402223,1402283,1400426},
    Bag = {
        {501001, 501002, 501003}, {1501001174, 1501002174, 1501003174}, {1501001220, 1501002220, 1501003220},
        {1501001051, 1501002051, 1501003051}, {1501001443, 1501002443, 1501003443}, {1501001265, 1501002265, 1501003265},
        {1501001321, 1501002321, 1501003321}, {1501001277, 1501002277, 1501003277}, {1501001550, 1501002550, 1501003550},
        {1501001592, 1501002592, 1501003592}, {1501001608, 1501002608, 1501003608}, {1501001024, 1501002024, 1501003024},
        {1501001019, 1501002019, 1501003019}, {1501001179, 1501002179, 1501003179}, {1501001194, 1501002194, 1501003194},
        {1501001346, 1501002346, 1501003346}
    },
    Helmet = {
        {502001, 502002, 502003}, {1502001014, 1502002014, 1502003014}, {1502001349, 1502002349, 1502003349},
        {1502001012, 1502002012, 1502003012}, {1502001009, 1502002009, 1502003009}, {1502001397, 1502002397, 1502003397},
        {1502001390, 1502002390, 1502003390}, {1502001381, 1502002381, 1502003381}, {1502001358, 1502002358, 1502003358},
        {1502001350, 1502002350, 1502003350}, {1502001342, 1502002342, 1502003342}
    },
    Pet = {50000,50001,50002,50003,50004,50005,50006,50021,50022,50038,50039,50040}
}

_G.skinIdMappings = {
    [101004]={101004, 1101004246,1101004226,1101004236,1101004062,1101004078,1101004086,1101004201,1101004218},
    [101001]={101001,1101001276,1101001089,1101001213,1101001172,1101001127,1101001230,1101001241},                    
    [101003]={101003,1101003227,1103003208,1101003195,1101003187,1101003098,1101003166,1101003218},                    
    [102002]={102002,1102002136,1102002043,1102002061,1102002424},                                          
    [101008]={101008,1101008146,1101008154,1101008079,1101008126,1101008104,1101008146,1101008061,1101008116},                    
    [101006]={101006,1101006085,1101006061,1101006074,1101006043,1101006032,1101006084},
    [102001]={102001, 1102001120}, -- UZI Băng Giá
    [101005]={101005, 1101005098}, -- Groza Godzilla Bốc Lửa
    [104003]={104003, 1104003037}, -- S12K Nguyên Tử
    [104004]={104004, 1104004035, 1104004041}, -- DBS Quái Thú & Sandsinger
    [101101]={101101, 1101101007}, --asm
    [101007]={101007, 1101007071,1101007062,1101007046,1101007078,1101007072},  -- QBZ
    [101012]={101012, 1101012033},  -- Honey Badger
    [101002]={101002, 1101002081,1101002056,1101002029,1101002149},  -- M16A4
    [101102]={101102, 1101102049,1101102025,1101102017,1101102007,1101102032},  -- ACE32
    
    [103001]={103001, 1103001202,1103001191,1103001179,1103001146,1103001101,1103001079,1103001202},  -- Kar98k
    [103002]={103002, 1103002113,1103002098,1103002087,1103002060,1103002059,1103002030},  -- M24
    [103003]={103003, 1103003087,1103003079,1103003069,1103003062,1103003055,1103003051,1103003042,1103003030,1103003022,1103003092},  -- AWM
    
}

_G.VehicleSkins = { 
    [1961001] = { 1961151,1961152,1961153,1961147,1961148,1961149,1961144,1961145,1961137,1961138,1961139,1961066,1961067,1961065,1961062,1961063,1961064,1961054,1961055,1961056,1961057,1961051,1961052,1961053,1961048,1961049,1961050,1961044,1961045,1961046,1961047,1961041,1961042,1961043,1961038,1961039,1961040,1961033,1961034,1961035,1961029,1961030,1961031,1961032,1961007,1961010,1961012,1961013,1961014,1961015,1961140,1961141,1961142,1961143,1991023,1991024 }, --cople rb
    [1903001] = { 1903228,1903220,1903221,1903223,1903218,1903219,1903213,1903212,1903202,1908094,1908095,1903193,1903192,1903191,19030790,19030791,19030800,19030801,1903074,1903075,1903076,1903071,1903072,1903073,1903216,1903217,1991001,1991002,1991003,1991004,1903088,1903089,1903090,1903023 }, --dacia
    [1915004] = { 1915021, 1915022, 1915008, 1915009, 1914011 }, -- Mirado open top        
    [1908001] = { 1908108,1908109,19080951,19081080,1908084,1908085,1908075,1908077,1908078,1908070,1908069,1908066,1908086,1908088,1908089,1908018 },  --uaz 
     [1907002] = { 1907058, 1907054, 1907059, 1907053, 1907063, 1907072, 1907040, 1907041, 1907027, 1907047, 1907021} -- Buggy 
}
_G.CustSlotType = { ClothesEquipemtSlot=5, BackpackEquipemtSlot=8, HelmetEquipemtSlot=9, ParachuteEquipemtSlot=11, GlideEquipemtSlot=15 }

local function DownloadGameItem(id)
    local puffer_manager = require('client.slua.logic.download.puffer.puffer_manager')
    local puffer_const = require('client.slua.logic.download.puffer_const')
    if puffer_manager and puffer_const and puffer_manager.GetState(puffer_const.ENUM_DownloadType.ODPTD, {id}) ~= puffer_const.ENUM_DownloadState.Done then
        puffer_manager.Download(puffer_const.ENUM_DownloadType.ODPTD, {id})
    end
end
_G.download_item = DownloadGameItem

_G.get_skin_id = function(weaponID)
    if not weaponID then return nil end
    local targetSkinId = _G.WeaponSkinMap and _G.WeaponSkinMap[weaponID]
    if targetSkinId and targetSkinId > 0 then
        if not _G.skinIdCache2[targetSkinId] then
            if _G.download_item then pcall(_G.download_item, targetSkinId) end
            _G.skinIdCache2[targetSkinId] = true
        end
        return targetSkinId
    end
    return weaponID
end

_G.equip_character_avatar = function(Character)
    if not Character or not slua.isValid(Character) or not Character.AvatarComponent2 then return end
    local BackpackUtils = import("BackpackUtils")
    local SlotSyncData = Character.AvatarComponent2.NetAvatarData and Character.AvatarComponent2.NetAvatarData.SlotSyncData
    if not SlotSyncData or not slua.isValid(SlotSyncData) or not BackpackUtils then return end
    
    local function EquipAvatar(ApplyDataIdx, mappedSkin, ApplyEquipSlot, isLevelDependent, levelFunc)
        if not mappedSkin or mappedSkin == 0 then return end
        local slotData = SlotSyncData:Get(ApplyDataIdx)
        if slotData and slotData.SlotID == ApplyEquipSlot then
            local applyItemId = mappedSkin
            if isLevelDependent and type(mappedSkin) == "table" then
                local level = levelFunc(slotData.AdditionalItemID) or 1
                if level < 1 then level = 1 end
                if level > 3 then level = 3 end
                applyItemId = mappedSkin[level] or mappedSkin[1]
            end

            if not applyItemId or applyItemId == 0 or slotData.ItemId == applyItemId then return end

            if not _G.skinIdCache[applyItemId] then
                if _G.download_item then pcall(_G.download_item, applyItemId) end
                _G.skinIdCache[applyItemId] = true
            end

            slotData.ItemId = applyItemId
            SlotSyncData:Set(ApplyDataIdx, slotData)
            Character.AvatarComponent2:OnRep_BodySlotStateChanged()
        end
    end

    local hasGliderSlot = false
    for i = 0, SlotSyncData:Num() - 1 do
        local slotData = SlotSyncData:Get(i)
        if slotData and slotData.SlotID == _G.CustSlotType.GlideEquipemtSlot then 
            hasGliderSlot = true
            break 
        end
    end
    if not hasGliderSlot then SlotSyncData:Add({ SlotID = _G.CustSlotType.GlideEquipemtSlot, ItemId = 0 }) end

    for i = 0, SlotSyncData:Num() - 1 do
        EquipAvatar(i, _G.OutfitMap.Suit or 0, _G.CustSlotType.ClothesEquipemtSlot, false)
        EquipAvatar(i, _G.OutfitMap.Pants or 0, 6, false)
        EquipAvatar(i, _G.OutfitMap.Hair or 0, 7, false)
        EquipAvatar(i, _G.OutfitMap.Bag, _G.CustSlotType.BackpackEquipemtSlot, true, BackpackUtils.GetEquipmentBagLevel)
        EquipAvatar(i, _G.OutfitMap.Helmet, _G.CustSlotType.HelmetEquipemtSlot, true, BackpackUtils.GetEquipmentHelmetLevel)
        EquipAvatar(i, _G.OutfitMap.Parachute or 0, _G.CustSlotType.ParachuteEquipemtSlot, false)
    end
end

_G.ApplyWeaponSkins = function(PlayerCharacter)
    pcall(function()
        local WeaponManager = PlayerCharacter:GetWeaponManager()
        if not slua.isValid(WeaponManager) then return end
        
        for slot = 1, 3 do
            local Weapon = WeaponManager:GetInventoryWeaponByPropSlot(slot)
            if slua.isValid(Weapon) and slua.isValid(Weapon.synData) then
                local WeaponID = Weapon:GetWeaponID()
                local SkinID = _G.get_skin_id(WeaponID) or WeaponID
                local isModified = false
                
                local SkinData = Weapon.synData:Get(7) 
                if SkinData and SkinData.defineID and SkinData.defineID.TypeSpecificID ~= SkinID then
                    SkinData.defineID.TypeSpecificID = SkinID
                    Weapon.synData:Set(7, SkinData)
                    if Weapon.SetWeaponAvatarID then pcall(function() Weapon:SetWeaponAvatarID(SkinID) end) end
                    if not _G.skinIdCache[SkinID] then 
                        _G.download_item(SkinID)
                        _G.skinIdCache[SkinID] = true 
                    end
                    isModified = true
                end
                
                if SkinID >= 10000000 and _G.VIP_Attachments and _G.VIP_Attachments[SkinID] then
                    for AttachIdx = 0, 5 do 
                        local attachData = Weapon.synData:Get(AttachIdx)
                        if attachData then
                            local defineIDRef = slua.IndexReference(attachData, "defineID")
                            if defineIDRef then
                                local attachmentId = defineIDRef.TypeSpecificID
                                if attachmentId and attachmentId > 0 then
                                    local mapIndex = _G.BaseAttachToIndex[attachmentId] or _G.VipAttachToIndex[attachmentId]
                                    if mapIndex and _G.VIP_Attachments[SkinID][mapIndex] and _G.VIP_Attachments[SkinID][mapIndex] > 0 then
                                        local targetAttachId = _G.VIP_Attachments[SkinID][mapIndex]
                                        if targetAttachId ~= attachmentId then
                                            attachData.defineID.TypeSpecificID = targetAttachId
                                            Weapon.synData:Set(AttachIdx, attachData)
                                            if not _G.skinIdCache2[targetAttachId] then 
                                                if _G.download_item then pcall(_G.download_item, targetAttachId) end
                                                _G.skinIdCache2[targetAttachId] = true 
                                            end
                                            isModified = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                
                if isModified then
                    if Weapon.DelayHandleAvatarMeshChanged then pcall(function() Weapon:DelayHandleAvatarMeshChanged() end) end
                    if Weapon.OnRep_synData then pcall(function() Weapon:OnRep_synData() end) end
                end
            end
        end
    end)
end

_G.ApplyVehicleSkins = function(PlayerCharacter)
    pcall(function()
        local Vehicle = PlayerCharacter:GetCurrentVehicle()
        if not slua.isValid(Vehicle) then 
            _G.LastVehicleEntity = nil
            return 
        end
        
        -- [FIX TỤT FPS]: Khóa ngay nếu xe này đã được load Skin xong (tránh spam lệnh ChangeItemAvatar làm đơ game)
        if _G.LastVehicleEntity == Vehicle and _G.CurrentEquipVehicleID ~= nil then
            return
        end

        local VehicleAvatar = Vehicle.VehicleAvatar or Vehicle.VehicleAvatarComponent_BP or Vehicle:GetAvatarComponent()
        if not slua.isValid(VehicleAvatar) then return end

        local defId = tostring(VehicleAvatar:GetDefaultAvatarID() or Vehicle.VehicleID or "")
        local currentId = tostring(Vehicle:GetAvatarId() or "")
        local applySkinId = 0
        
        for baseMapId, targetSkin in pairs(_G.VehicleSkinMap) do
            if defId:find(tostring(baseMapId)) or currentId:find(tostring(baseMapId)) then 
                applySkinId = targetSkin
                break 
            end
        end

        if applySkinId and applySkinId > 0 then
            _G.skinIdCache = _G.skinIdCache or {}
            if not _G.skinIdCache[applySkinId] then 
                if _G.download_item then pcall(_G.download_item, applySkinId) end
                _G.skinIdCache[applySkinId] = true 
            end

            VehicleAvatar.curSwitchEffectId = 7303001
            if VehicleAvatar.ChangeItemAvatar then VehicleAvatar:ChangeItemAvatar(applySkinId, true) end
            
            _G.CurrentEquipVehicleID = applySkinId
            _G.LastVehicleEntity = Vehicle
        end
    end)
end

_G.HandlePetLogic = function()
    pcall(function()
        local petSkin = _G.OutfitMap.Pet
        if not petSkin or petSkin == 0 or petSkin == 50000 or petSkin == _G.LastAppliedPet then return end
        
        _G.skinIdCache = _G.skinIdCache or {}
        if not _G.skinIdCache[petSkin] then 
            if _G.download_item then pcall(_G.download_item, petSkin) end
            _G.skinIdCache[petSkin] = true 
        end
        
        local ModuleManager = require("client.module_framework.ModuleManager")
        if ModuleManager then
            local logic_pet = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_pet)
            if logic_pet then
                if logic_pet.SetCurPetID then logic_pet:SetCurPetID(petSkin) end
                if logic_pet.EquipPet then logic_pet:EquipPet(petSkin) end
            end
        end
        _G.LastAppliedPet = petSkin
    end)
end

_G.ForceRefreshSkinMaps = function()
    pcall(function()
        if not _G.LexusState or not _G.LexusState.CustomTextData then return end
        local cData = _G.LexusState.CustomTextData

        if _G.OutfitSkins then
            if cData.SkinSuit and _G.OutfitSkins.Suit[cData.SkinSuit] then _G.OutfitMap.Suit = _G.OutfitSkins.Suit[cData.SkinSuit] end
            if cData.SkinBag and _G.OutfitSkins.Bag[cData.SkinBag] then _G.OutfitMap.Bag = _G.OutfitSkins.Bag[cData.SkinBag] end
            if cData.SkinHelmet and _G.OutfitSkins.Helmet[cData.SkinHelmet] then _G.OutfitMap.Helmet = _G.OutfitSkins.Helmet[cData.SkinHelmet] end
        end

        if _G.skinIdMappings then
            if cData.SkinM416 and _G.skinIdMappings[101004] and _G.skinIdMappings[101004][cData.SkinM416] then _G.WeaponSkinMap[101004] = _G.skinIdMappings[101004][cData.SkinM416] end
            if cData.SkinAKM and _G.skinIdMappings[101001] and _G.skinIdMappings[101001][cData.SkinAKM] then _G.WeaponSkinMap[101001] = _G.skinIdMappings[101001][cData.SkinAKM] end
            if cData.SkinSCAR and _G.skinIdMappings[101003] and _G.skinIdMappings[101003][cData.SkinSCAR] then _G.WeaponSkinMap[101003] = _G.skinIdMappings[101003][cData.SkinSCAR] end
            if cData.SkinM762 and _G.skinIdMappings[101008] and _G.skinIdMappings[101008][cData.SkinM762] then _G.WeaponSkinMap[101008] = _G.skinIdMappings[101008][cData.SkinM762] end
            if cData.SkinAUG and _G.skinIdMappings[101006] and _G.skinIdMappings[101006][cData.SkinAUG] then _G.WeaponSkinMap[101006] = _G.skinIdMappings[101006][cData.SkinAUG] end
            if cData.SkinUMP and _G.skinIdMappings[102002] and _G.skinIdMappings[102002][cData.SkinUMP] then _G.WeaponSkinMap[102002] = _G.skinIdMappings[102002][cData.SkinUMP] end
            
            if cData.SkinUZI and _G.skinIdMappings[102001] and _G.skinIdMappings[102001][cData.SkinUZI] then _G.WeaponSkinMap[102001] = _G.skinIdMappings[102001][cData.SkinUZI] end
            if cData.SkinGroza and _G.skinIdMappings[101005] and _G.skinIdMappings[101005][cData.SkinGroza] then _G.WeaponSkinMap[101005] = _G.skinIdMappings[101005][cData.SkinGroza] end
            if cData.SkinS12K and _G.skinIdMappings[104003] and _G.skinIdMappings[104003][cData.SkinS12K] then _G.WeaponSkinMap[104003] = _G.skinIdMappings[104003][cData.SkinS12K] end
            if cData.SkinDBS and _G.skinIdMappings[104004] and _G.skinIdMappings[104004][cData.SkinDBS] then _G.WeaponSkinMap[104004] = _G.skinIdMappings[104004][cData.SkinDBS] end
            if cData.SkinASM and _G.skinIdMappings[101101] and _G.skinIdMappings[101101][cData.SkinASM] then _G.WeaponSkinMap[101101] = _G.skinIdMappings[101101][cData.SkinASM] end
        end

        if _G.VehicleSkins then
            if cData.SkinDacia and _G.VehicleSkins[1903001] and _G.VehicleSkins[1903001][cData.SkinDacia] then _G.VehicleSkinMap[1903001] = _G.VehicleSkins[1903001][cData.SkinDacia] end
            if cData.SkinUAZ and _G.VehicleSkins[1908001] and _G.VehicleSkins[1908001][cData.SkinUAZ] then _G.VehicleSkinMap[1908001] = _G.VehicleSkins[1908001][cData.SkinUAZ] end
            if cData.SkinCoupe and _G.VehicleSkins[1961001] and _G.VehicleSkins[1961001][cData.SkinCoupe] then _G.VehicleSkinMap[1961001] = _G.VehicleSkins[1961001][cData.SkinCoupe] end
            if cData.SkinBuggy and _G.VehicleSkins[1907002] and _G.VehicleSkins[1907002][cData.SkinBuggy] then _G.VehicleSkinMap[1907002] = _G.VehicleSkins[1907001][cData.SkinBuggy] end
            if cData.SkinMirado and _G.VehicleSkins[1915004] and _G.VehicleSkins[1915001][cData.SkinMirado] then _G.VehicleSkinMap[1915004] = _G.VehicleSkins[1907002][cData.SkinMirado] end
            if cData.SkinQBZ and _G.skinIdMappings[101007] and _G.skinIdMappings[101007][cData.SkinQBZ] then _G.WeaponSkinMap[101007] = _G.skinIdMappings[101007][cData.SkinQBZ] end
if cData.SkinHoney and _G.skinIdMappings[101012] and _G.skinIdMappings[101012][cData.SkinHoney] then _G.WeaponSkinMap[101012] = _G.skinIdMappings[101012][cData.SkinHoney] end
if cData.SkinM16A4 and _G.skinIdMappings[101002] and _G.skinIdMappings[101002][cData.SkinM16A4] then _G.WeaponSkinMap[101002] = _G.skinIdMappings[101002][cData.SkinM16A4] end
if cData.SkinACE32 and _G.skinIdMappings[101102] and _G.skinIdMappings[101102][cData.SkinACE32] then _G.WeaponSkinMap[101102] = _G.skinIdMappings[101102][cData.SkinACE32] end
if cData.SkinKar98k and _G.skinIdMappings[103001] and _G.skinIdMappings[103001][cData.SkinKar98k] then _G.WeaponSkinMap[103001] = _G.skinIdMappings[103001][cData.SkinKar98k] end
if cData.SkinM24 and _G.skinIdMappings[103002] and _G.skinIdMappings[103002][cData.SkinM24] then _G.WeaponSkinMap[103002] = _G.skinIdMappings[103002][cData.SkinM24] end
if cData.SkinAWM and _G.skinIdMappings[103003] and _G.skinIdMappings[103003][cData.SkinAWM] then _G.WeaponSkinMap[103003] = _G.skinIdMappings[103003][cData.SkinAWM] end
        end
    end)
end

local cached_GameplayStatics = nil
local cached_PlayerTombBox = nil
local cached_ActorClass = nil
_G.NeedCheckDeadBoxTimer = 0

_G.DeadBox_TemperRequest = function(PlayerController)
    if _G.NeedCheckDeadBoxTimer <= 0 then return end
    
    -- [FIX LAG]: Giới hạn quét hòm xác 2 giây/lần bằng đồng hồ thực của máy (rất nhẹ CPU)
    local curTime = os.clock()
    if _G.LastCheckDeadBoxTime and (curTime - _G.LastCheckDeadBoxTime) < 2.0 then return end
    _G.LastCheckDeadBoxTime = curTime
    
    _G.NeedCheckDeadBoxTimer = _G.NeedCheckDeadBoxTimer - 1

    local PlayerCharacter = PlayerController:GetPlayerCharacterSafety()
    if not slua.isValid(PlayerCharacter) then return end
    
    if not cached_GameplayStatics then
        cached_GameplayStatics = import("GameplayStatics")
        cached_ActorClass = import("Actor")
        cached_PlayerTombBox = import("PlayerTombBox")
    end
    
    -- [FIX MEMORY LEAK]: Sinh mảng cache 1 lần duy nhất thay vì tạo lại liên tục
    if not _G.CachedActorArray then
        _G.CachedActorArray = slua.Array(UEnums.EPropertyClass.Object, cached_ActorClass)
    end
    
    local UI_Util = require("client.common.ui_util")
    local GameInstance = UI_Util and UI_Util.GetGameInstance()
    if not GameInstance or not cached_GameplayStatics then return end

    local deadBoxes = cached_GameplayStatics.GetAllActorsOfClass(GameInstance, cached_PlayerTombBox, _G.CachedActorArray)
    
    for _, deadBoxActor in pairs(deadBoxes) do
        if slua.isValid(deadBoxActor) and not deadBoxActor.bIsTDSkinApplied then
            local damageCauser = deadBoxActor.DamageCauser
            if damageCauser and damageCauser.PlayerKey == PlayerController.PlayerKey then
                local DeadBoxAvatarComponent = deadBoxActor.DeadBoxAvatarComponent_BP
                if slua.isValid(DeadBoxAvatarComponent) then
                    local currentBoxSkinId = 0
                    if PlayerCharacter.CurrentVehicle and _G.CurrentEquipVehicleID and _G.CurrentEquipVehicleID ~= 0 then
                        currentBoxSkinId = tonumber(tostring(_G.CurrentEquipVehicleID) .. "1") or 0
                    else
                        local currentWeapon = PlayerCharacter:GetCurrentWeapon()
                        if slua.isValid(currentWeapon) and currentWeapon.synData then
                            local weaponSkinData = currentWeapon.synData:Get(7)
                            if weaponSkinData and weaponSkinData.defineID then
                                currentBoxSkinId = weaponSkinData.defineID.TypeSpecificID
                            end
                        end
                    end
                    
                    if currentBoxSkinId ~= 0 then
                        pcall(function()
                            DeadBoxAvatarComponent:ResetItemAvatar()
                            DeadBoxAvatarComponent:PreChangeItemAvatar(currentBoxSkinId)
                            DeadBoxAvatarComponent:SyncChangeItemAvatar(currentBoxSkinId)
                        end)
                    end
                    deadBoxActor.bIsTDSkinApplied = true
                end
            end
        end
    end
end

_G.TDFTDeKillCounts = _G.TDFTDeKillCounts or {}
local CACHED_LinearColor = import("LinearColor")
local CACHED_GoldColor = CACHED_LinearColor and CACHED_LinearColor(1.0, 0.8, 0.0, 1.0) or nil
local CACHED_UI_Manager = nil

_G.ForceEnableKillCounterUI = function()
    pcall(function()
        local KillCounterUISubsystem = package.loaded["GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem"] or require("GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem")
        if KillCounterUISubsystem and KillCounterUISubsystem.__inner_impl and not _G.KCUISystemHacked2 then
            local kcImpl = KillCounterUISubsystem.__inner_impl
            kcImpl.CheckSupportKCUI = function() return true end
            kcImpl.CheckNeedMainKillCounterUI = function(self, PlayerWeapon, PlayerID)
                if slua.isValid(PlayerWeapon) then
                    local WeaponID = PlayerWeapon:GetWeaponID()
                    self:UpdateMainKillCounterUI(true, WeaponID, _G.get_skin_id(WeaponID) or WeaponID)
                else self:UpdateMainKillCounterUI(false) end
            end
            local originalUpdateMainKillCounterUI = kcImpl.UpdateMainKillCounterUI
            kcImpl.UpdateMainKillCounterUI = function(self, bShow, WeaponID, AvatarID)
                if bShow then AvatarID = _G.get_skin_id(WeaponID) or AvatarID end
                if originalUpdateMainKillCounterUI then originalUpdateMainKillCounterUI(self, bShow, WeaponID, AvatarID) end
            end
            _G.KCUISystemHacked2 = true
        end

        local ModuleManager = require("client.module_framework.ModuleManager")
        if ModuleManager and not _G.KCLogicHacked2 then
            local LogicKillCounter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
            if LogicKillCounter then
                LogicKillCounter.CheckSupportKC = function() return true end
                LogicKillCounter.CheckSupportKillCounterAvatar = function() return true end
                LogicKillCounter.CheckHasWeaponKillCounter = function() return true end
                LogicKillCounter.GetBaseKillCounterIdByWeaponId = function() return 2100004 end
                LogicKillCounter.GetEquipedKillCounterId = function() return 2100004 end
                LogicKillCounter.GetMyEquipedKillCounterId = function() return 2100004 end
                LogicKillCounter.GetOneWeaponKillCountInBattle = function(self, uid, weaponId) return _G.TDFTDeKillCounts[weaponId] or 0 end
                LogicKillCounter.GetWeaponKillCountByUid = function(self, uid, weaponId) return _G.TDFTDeKillCounts[weaponId] or 0 end
                _G.KCLogicHacked2 = true
            end
        end

        local killInfoPath = "GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo"
        local KillInfo = package.loaded[killInfoPath] or require(killInfoPath)
        
        if KillInfo and KillInfo.__inner_impl and not _G.KillInfoCounterHacked then
            local originalFileItem = KillInfo.__inner_impl.FileItem
            KillInfo.__inner_impl.FileItem = function(self, DamageRecordData)
                pcall(function()
                    local LocalPlayer = require("GameLua.GameCore.Data.GameplayData").GetPlayerCharacter()
                    if slua.isValid(LocalPlayer) and DamageRecordData.Causer == LocalPlayer:GetPlayerNameSafety() then 
                        local currentWeapon = LocalPlayer:GetCurrentWeapon()
                        if slua.isValid(currentWeapon) then
                            local weaponID = currentWeapon:GetWeaponID()
                            local skinID = _G.get_skin_id(weaponID)
                            if skinID then DamageRecordData.CauserWeaponAvatarID = skinID end
                            if _G.OutfitMap.Suit and _G.OutfitMap.Suit ~= 0 then DamageRecordData.CauserClothAvatarID = _G.OutfitMap.Suit end
                            
                            if CACHED_GoldColor then
                                DamageRecordData.IsUseColor, DamageRecordData.UseColor = true, CACHED_GoldColor
                            end
                            
                            if DamageRecordData.ResultHealthStatus == 2 then
                                _G.TDFTDeKillCounts[weaponID] = (_G.TDFTDeKillCounts[weaponID] or 0) + 1
                                _G.NeedCheckDeadBoxTimer = 50 
                                
                                if not CACHED_UI_Manager then CACHED_UI_Manager = require("client.slua_ui_framework.manager") end
                                local uiMainKillCounter = CACHED_UI_Manager.GetUI(CACHED_UI_Manager.UI_Config_InGame.MainKillCounter)
                                
                                if uiMainKillCounter and uiMainKillCounter.UpdateWeaponID then
                                    local mainAvatarID = skinID or currentWeapon:GetWeaponMainAvatarID()
                                    uiMainKillCounter:UpdateWeaponID(weaponID, mainAvatarID)
                                    local kcModule = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
                                    local kcItemID = kcModule:GetEquipedKillCounterId(0, mainAvatarID)
                                    uiMainKillCounter:SetKillCounterItemShowWithNum(kcItemID, _G.TDFTDeKillCounts[weaponID], mainAvatarID)
                                end
                            end
                        end
                    end
                end)
                if originalFileItem then return originalFileItem(self, DamageRecordData) end
            end
            _G.KillInfoCounterHacked = true
        end

        local SwitchWeaponSlotMode2 = package.loaded["GameLua.Mod.BaseMod.Client.MainControlUI.SwitchWeaponSlotMode2"] or require("GameLua.Mod.BaseMod.Client.MainControlUI.SwitchWeaponSlotMode2")
        if SwitchWeaponSlotMode2 and SwitchWeaponSlotMode2.__inner_impl and not _G.SlotBaseHacked then
            SwitchWeaponSlotMode2.__inner_impl.CheckShowKCIcon = function(self)
                if slua.isValid(self.KillCounterImg) then 
                    self.KillCounterImg:SetVisibility(import("ESlateVisibility").SelfHitTestInvisible) 
                end
            end
            _G.SlotBaseHacked = true
        end
    end)
end

function _G.InitializeSkinModSystem()
    pcall(function()
        local LobbyAvatar = package.loaded["client.logic.avatar.LobbyAvatar"] or require("client.logic.avatar.LobbyAvatar")
        if LobbyAvatar and not _G.LobbyBypassHacked then
            local originalPutonEquipment = LobbyAvatar.PutonEquipment
            LobbyAvatar.PutonEquipment = function(self, itemID, tAvatarCustom, tExtraData)
                local attachIndex = _G.BaseAttachToIndex and _G.BaseAttachToIndex[itemID]
                if attachIndex then
                    local holdingWeaponSkinID = self.GetCurHoldingWeaponSkinID and self:GetCurHoldingWeaponSkinID()
                    if holdingWeaponSkinID and holdingWeaponSkinID >= 10000000 and _G.VIP_Attachments and _G.VIP_Attachments[holdingWeaponSkinID] then
                        local vipAttachID = _G.VIP_Attachments[holdingWeaponSkinID][attachIndex]
                        if vipAttachID and vipAttachID > 0 then
                            if self.HandleDownload then self:HandleDownload(vipAttachID, nil, nil, false) end
                            itemID = vipAttachID
                        end
                    end
                end
                if originalPutonEquipment then return originalPutonEquipment(self, itemID, tAvatarCustom, tExtraData) end
            end

            local originalCharEquipWeaponByResId = LobbyAvatar.CharEquipWeaponByResId
            LobbyAvatar.CharEquipWeaponByResId = function(self, resID, isUse, isAsync, SocketName)
                local retValue = originalCharEquipWeaponByResId and originalCharEquipWeaponByResId(self, resID, isUse, isAsync, SocketName) or nil
                if isUse and self.GetEquipments then
                    local equipments = self:GetEquipments()
                    for _, equip in ipairs(equipments) do
                        if _G.BaseAttachToIndex and _G.BaseAttachToIndex[equip.itemID] then
                            self:PutonEquipment(equip.itemID, equip.CustomInfo, {bIsUse = false})
                        end
                    end
                end
                return retValue
            end
            _G.LobbyBypassHacked = true
        end
    end)
    
    pcall(function()
        local Common_Items_UIBP = package.loaded["client.slua.component.item.ItemChildren.Common_Items_UIBP"] or require("client.slua.component.item.ItemChildren.Common_Items_UIBP")
        if Common_Items_UIBP and not _G.IconBaloHacked then
        local originalInitView = Common_Items_UIBP.InitView
            Common_Items_UIBP.InitView = function(self, nItemId, nCount, nValidTime, tExtraData)
                tExtraData = tExtraData or {}
                local displayResId = nil
                
                if _G.get_skin_id then
                    local skinID = _G.get_skin_id(nItemId)
                    if skinID and skinID ~= nItemId then displayResId = skinID end
                end
                
                local attachIndex = _G.BaseAttachToIndex and _G.BaseAttachToIndex[nItemId]
                if not displayResId and attachIndex then
                    local GameplayData = require("GameLua.GameCore.Data.GameplayData")
                    local LocalPlayer = GameplayData and GameplayData.GetPlayerCharacter()
                    if slua.isValid(LocalPlayer) then
                        local currentWeapon = LocalPlayer:GetCurrentWeapon()
                        if slua.isValid(currentWeapon) then
                            local weaponID = currentWeapon:GetWeaponID()
                            local finalSkinID = _G.get_skin_id(weaponID) or weaponID
                            if finalSkinID >= 10000000 and _G.VIP_Attachments and _G.VIP_Attachments[finalSkinID] then
                                local vipAttachID = _G.VIP_Attachments[finalSkinID][attachIndex]
                                if vipAttachID and vipAttachID > 0 then displayResId = vipAttachID end
                            end
                        end
                    end
                end
                
                if displayResId then
                    tExtraData.displayResId = displayResId
                    if not _G.skinIdCache2[displayResId] then
                        if _G.download_item then pcall(_G.download_item, displayResId) end
                        _G.skinIdCache2[displayResId] = true
                    end
                end
                if originalInitView then return originalInitView(self, nItemId, nCount, nValidTime, tExtraData) end
            end
            _G.IconBaloHacked = true
        end
    end)
end
-- ========================================== 
-- HỆ THỐNG LƯU VÀ TẢI SETTING MENU VIP (TỰ ĐỘNG)
-- ========================================== 
local function GetConfigPaths(fileName)
    local paths = {
        "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "/Documents/ShadowTrackerExtra/Saved/Paks/puffer_temp/" .. fileName,
        "/com.tencent.ig/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "/com.vng.pubgmobile/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "/com.pubg.krmobile/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "/com.rekoo.pubgm/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "/com.pubg.imobile/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "../../ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "../../../ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "../../../../ShadowTrackerExtra/Saved/Paks/" .. fileName,
        fileName
    }
    pcall(function()
        if os and os.getenv then
            local homeDir = os.getenv("HOME")
            if homeDir and homeDir ~= "" then
                table.insert(paths, 1, homeDir .. "/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName)
                table.insert(paths, 2, homeDir .. "/Documents/ShadowTrackerExtra/Saved/Paks/puffer_temp/" .. fileName)
            end
        end
    end)
    return paths
end

local ConfigFileName = "goku_settings.txt"
_G.LastConfigSaveStr = ""

-- HÀM LƯU CONFIG
_G.SaveModSettings = function()
    pcall(function()
        local data = "return {\nLexusConfig = {\n"
        for k, v in pairs(_G.LexusConfig or {}) do
            data = data .. "  [\"" .. tostring(k) .. "\"] = " .. tostring(v) .. ",\n"
        end
        data = data .. "},\nCustomTextData = {\n"
        if _G.LexusState and _G.LexusState.CustomTextData then
            for k, v in pairs(_G.LexusState.CustomTextData) do
                data = data .. "  [\"" .. tostring(k) .. "\"] = " .. tostring(v) .. ",\n"
            end
        end
        data = data .. "}\n}"
        
        -- Chống giật lag: Chỉ tiến hành ghi file nếu bạn có thay đổi cấu hình
        if data == _G.LastConfigSaveStr then return end
        _G.LastConfigSaveStr = data

        local paths = GetConfigPaths(ConfigFileName)
        for _, path in ipairs(paths) do
            local file = io.open(path, "w")
            if file then
                file:write(data)
                file:close()
                break
            end
        end
    end)
end

-- HÀM TẢI (ĐỌC) CONFIG
_G.LoadModSettings = function()
    pcall(function()
        local paths = GetConfigPaths(ConfigFileName)
        local content = nil
        for _, path in ipairs(paths) do
            local file = io.open(path, "r")
            if file then
                content = file:read("*a")
                file:close()
                break
            end
        end

        if content then
            local func = load(content)
            if func then
                local savedData = func()
                if savedData and type(savedData) == "table" then
                    if savedData.LexusConfig then
                        for k, v in pairs(savedData.LexusConfig) do
                            _G.LexusConfig[k] = v
                        end
                    end
                    if savedData.CustomTextData then
                        _G.LexusState.CustomTextData = _G.LexusState.CustomTextData or {}
                        for k, v in pairs(savedData.CustomTextData) do
                            _G.LexusState.CustomTextData[k] = v
                        end
                    end
                end
            end
        end
        -- Ghi nhớ cấu hình vừa tải
        _G.SaveModSettings() 
    end)
end

-- VÒNG LẶP KIỂM TRA ĐỂ LƯU CHẠY NGẦM RẤT NHẸ
local function AutoSaveLoop()
    pcall(function() if _G.SaveModSettings then _G.SaveModSettings() end end)
    pcall(function()
        local okTicker, ticker = pcall(require, "common.time_ticker") 
        if okTicker and ticker and ticker.AddTimerOnce then 
            ticker.AddTimerOnce(3.0, AutoSaveLoop) -- Cứ 3 giây check 1 lần
        end
    end)
end

-- READT
if not _G.ModConfigLoaded then
    _G.LoadModSettings()
    AutoSaveLoop()
    _G.ModConfigLoaded = true
end

-- READ
_G.ReadLiveConfig = function()
    if _G.SaveModSettings then _G.SaveModSettings() end
end

-- ========================================== 
-- WELCOME & EXPIRY (FROM GOKU)
-- ========================================== 
local function ShowWelcomePopup()
    if _G.LexusState.MenuStep ~= 0 then return end
    pcall(function()
        local Msg = require("client.slua.logic.common.logic_common_msg_box")
        if not Msg or not Msg.Show then return end
        local Web = require("client.slua.logic.url.logic_webview_sdk")
        local function onClick()
            if Web then Web:OpenURL("https://t.me/GOKUCONFIG") end
        end
        Msg.Show(4, "✦ DEV ~ GOKUCONFIG ✦",
            "\n★ Developer : @GOKUCONFIG\n" ..
            "★ Status    : UNDETECTED & OPTIMIZED\n" ..
            "★ Bypass    : 7-Layer Deep Shield + All Visuals\n" ..
            "★ New       : Gokuba/TSS + GameReport + FightTLog bypass\n\n" ..
            "✓ Premium Build Loaded Successfully!", onClick)
        _G.LexusState.MenuStep = 99
    end)
end

local function ShowExpiryDialog()
    local ct = os.clock()
    if _G.LexusState.LastExpiryTime and (ct - _G.LexusState.LastExpiryTime) < 5 then return end
    _G.LexusState.LastExpiryTime = ct
    pcall(function()
        local Msg = require("client.slua.logic.common.logic_common_msg_box")
        if not Msg or not Msg.Show then return end
        local Web = require("client.slua.logic.url.logic_webview_sdk")
        Msg.Show(4, "✗ ACCESS DENIED ✗",
            "★ @GOKUCONFIG\n━━━━━━━━━━━━━━━━\n✗ LICENSE EXPIRED\nYour access has been revoked.\n\n▸ Tap [Contact] to renew.",
            function() if Web then Web:OpenURL("https://t.me/GOKUCONFIG") end end, nil, "Contact", "Cancel")
    end)
end

-- ========================================== 
-- 165 FPS UNLOCK – ALWAYS ON, NO TOGGLE (ADDED)
-- ========================================== 
do
    -- Cache globals for performance
    local math_floor = math.floor
    local math_max = math.max
    local math_min = math.min
    local pcall = pcall
    local require = require
    local tostring = tostring
    local print = print or function(...) end
    local slua = slua
    local isValid = (slua and slua.isValid) or function(obj) return obj ~= nil end

    -- Idempotency guard
    if _G.__165FPS_UNLOCK_PATCHED then
        print("[165FPS] Already patched – skipping.")
    else
        -- Safe require helper
        local function safe_require(modname)
            local ok, mod = pcall(require, modname)
            if not ok then
                print("[165FPS] Failed to load module: " .. modname .. " – " .. tostring(mod))
                return nil
            end
            return mod
        end

        -- Load required modules (all inside pcalls)
        local graphics = safe_require("client.slua.logic.setting.logic_setting_graphics")
        local fpsComp = safe_require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
        local fpsFT = safe_require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
        local db = safe_require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")

        -- Helper to get game instance
        local function get_game_instance()
            if not db then return nil end
            local gi = (db.GetGameInstance and db:GetGameInstance())
            return gi
        end

        -- Patch graphics.SetFPS to support level 8
        if graphics and type(graphics.SetFPS) == "function" then
            if not graphics.__original_SetFPS then
                graphics.__original_SetFPS = graphics.SetFPS
            end
            local orig = graphics.__original_SetFPS
            graphics.SetFPS = function(self, level)
                local ok, err = pcall(orig, self, level)
                if not ok then
                    print("[165FPS] original SetFPS error: " .. tostring(err))
                end
                if level == 8 then
                    pcall(function()
                        if self.ExecuteCMD then
                            self:ExecuteCMD("t.MaxFPS", "165")
                            self:ExecuteCMD("r.FrameRateLimit", "165")
                        end
                    end)
                end
            end
        end

        -- Patch FPS selector component (GSC_FPS)
        if fpsComp and fpsComp.__inner_impl then
            local impl = fpsComp.__inner_impl
            if not impl.__165patched then
                impl.GetMaxFPSLevel = function() return 8, 8 end
                impl.InitRealSupportFPS = function(self)
                    local tbl = {}
                    for i = 1, 8 do
                        tbl[i] = {true, true}
                    end
                    if db and db.RealSupportFPS then
                        pcall(function() db:UpdateUIData(db.RealSupportFPS, tbl, false) end)
                    end
                    return tbl
                end
                impl.UpdateSelectedFPSState = function(self, level)
                    local fpsMap = {
                        [2] = 20, [3] = 25, [4] = 30,
                        [5] = 40, [6] = 60, [7] = 90, [8] = 120
                    }
                    local UIRoot = self.UIRoot
                    if not UIRoot then return end
                    for i = 2, 8 do
                        local nodeName = "NodeFps" .. tostring(fpsMap[i] or 120)
                        local node = UIRoot[nodeName]
                        if isValid(node) then
                            node:SetIsEnabled(true)
                            pcall(function() node:SetRenderOpacity(1.0) end)
                            local switcherName = "WidgetSwitcher_" .. i
                            local switcher = UIRoot[switcherName]
                            if isValid(switcher) then
                                switcher:SetActiveWidgetIndex(i == level and 0 or 1)
                            end
                        end
                    end
                end
                impl.__165patched = true
            end
        end

        -- Patch fine-tune slider (GSC_FPSFT)
        if fpsFT and fpsFT.__inner_impl and db then
            local impl = fpsFT.__inner_impl
            if not impl.__165patched then
                local MIN_FPS, MAX_FPS, STEP = 90, 165, 5
                local function clamp(v)
                    return math_max(MIN_FPS, math_min(MAX_FPS, v))
                end

                impl.ShowOrHide = function(self)
                    pcall(function() self:SelfHitTestInvisible() end)
                    if self.InitFPSFTSwitch then
                        pcall(self.InitFPSFTSwitch, self)
                    end
                end

                impl.InitFPSFTSwitch = function(self)
                    if not db then return end
                    local on = db:GetUIData(db.FPSFineTuneSwitch)
                    local UIRoot = self.UIRoot
                    if not UIRoot then return end
                    if UIRoot.Setting_Switch then
                        pcall(function() UIRoot.Setting_Switch:SetSwitcherEnable2(on, true) end)
                    end
                    if UIRoot.CanvasPanel_8 then
                        pcall(function() self:SetWidgetVisible(UIRoot.CanvasPanel_8, on) end)
                    end
                    if UIRoot.WidgetSwitcher_0 then
                        pcall(function() UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(2) end)
                    end
                    if self.InitFPSFTValue165 then
                        pcall(self.InitFPSFTValue165, self)
                    end
                end

                impl.InitFPSFTValue165 = function(self)
                    if not db then return end
                    local UIRoot = self.UIRoot
                    if not UIRoot then return end
                    local on = db:GetUIData(db.FPSFineTuneSwitch)
                    local val = on and (db:GetUIData(db.FPSFineTuneNum) or 165) or 165
                    local slider = UIRoot.Slider_screen3
                    local progress = UIRoot.ProgressBar_screen3
                    local textLabel = UIRoot.Veihclescreen3
                    if not (slider and progress and textLabel) then return end
                    if on then
                        pcall(function() slider:SetLocked(false) end)
                        pcall(function() progress:SetFillColorAndOpacity(FLinearColor(1,1,1,1)) end)
                        pcall(function() slider:SetSliderHandleColor(FLinearColor(1,1,1,1)) end)
                    else
                        pcall(function() slider:SetLocked(true) end)
                        pcall(function() progress:SetFillColorAndOpacity(FLinearColor(1,0.625,0.6,1)) end)
                        pcall(function() slider:SetSliderHandleColor(FLinearColor(1,0.625,0.6,1)) end)
                    end
                    local norm = (val - MIN_FPS) / (MAX_FPS - MIN_FPS)
                    pcall(function() textLabel:SetText(tostring(val)) end)
                    pcall(function() slider:SetValue(norm) end)
                    pcall(function() progress:SetPercent(norm) end)
                end

                impl.OnFPSFTValueChange3 = function(self, val)
                    if not db then return end
                    pcall(function()
                        db:UpdateUIData(db.FPSFineTuneNum, val)
                        if self.InitFPSFTValue165 then
                            pcall(self.InitFPSFTValue165, self)
                        end
                        local parent = self.GetParentUI and self:GetParentUI()
                        if parent and parent.SetDirty then
                            pcall(function() parent:SetDirty(true) end)
                        end
                        local gi = get_game_instance()
                        if gi then
                            gi:ExecuteCMD("t.MaxFPS", tostring(val))
                            gi:ExecuteCMD("r.FrameRateLimit", tostring(val))
                        end
                    end)
                end

                impl.OnFPSFTSliderValueChange3 = function(self, nv)
                    if not db then return end
                    if not db:GetUIData(db.FPSFineTuneSwitch) then return end
                    local raw = math_floor(MIN_FPS + (MAX_FPS - MIN_FPS) * nv)
                    raw = math_floor(raw / STEP) * STEP
                    self:OnFPSFTValueChange3(clamp(raw))
                end

                impl.OnFPSFTAdd3 = function(self)
                    local cur = (db and db:GetUIData(db.FPSFineTuneNum)) or MIN_FPS
                    self:OnFPSFTValueChange3(math_min(MAX_FPS, cur + STEP))
                end

                impl.OnFPSFTMinus3 = function(self)
                    local cur = (db and db:GetUIData(db.FPSFineTuneNum)) or MIN_FPS
                    self:OnFPSFTValueChange3(math_max(MIN_FPS, cur - STEP))
                end

                impl.OnFPSFTAdd = impl.OnFPSFTAdd3
                impl.OnFPSFTMinus = impl.OnFPSFTMinus3
                impl.OnFPSFTSliderValueChange = impl.OnFPSFTSliderValueChange3

                impl.__165patched = true
            end
        end

        -- Immediate console apply
        local function apply_immediate()
            local gi = get_game_instance()
            if not gi then
                local ok, gp = pcall(require, "GameLua.GameCore.Data.GameplayData")
                if ok and gp and gp.GetGameInstance then
                    gi = gp.GetGameInstance()
                end
            end
            if gi then
                pcall(function()
                    gi:ExecuteCMD("t.MaxFPS", "165")
                    gi:ExecuteCMD("r.FrameRateLimit", "165")
                end)
                return true
            end
            return false
        end
        apply_immediate()

        _G.__165FPS_UNLOCK_PATCHED = true
        print("[165FPS] Unlock applied. Select 'Ultra Extreme' or use fine-tune slider (90-165).")
    end
end

-- ========================================== 
-- WALLHACK FUNCTIONS (ADDED FROM GOKU SCRIPT)
-- ========================================== 
local _WH_OrigMaterials = setmetatable({}, { __mode = "k" })
local _WH_ModifiedPawns = setmetatable({}, { __mode = "k" })
local _WH_ModifiedBaseMaterials = setmetatable({}, { __mode = "k" })
_G._WH_NeedCleanup = false

local function ClearWallHackForPawn(pawn)
    if not Valid(pawn) then return end
    local meshes = {}
    pcall(function()
        if Valid(pawn.Mesh) then table.insert(meshes, pawn.Mesh) end
        local SkelClass = import("SkeletalMeshComponent")
        if SkelClass then
            local childs = pawn:GetComponentsByClass(SkelClass)
            if childs then
                local count = type(childs.Num) == "function" and childs:Num() or #childs
                for c = 1, count do
                    local comp = type(childs.Get) == "function" and childs:Get(c - 1) or childs[c]
                    if Valid(comp) and comp ~= pawn.Mesh then table.insert(meshes, comp) end
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
                for i, mat in pairs(origMatSlots) do pcall(function() comp:SetMaterial(i, mat) end) end
                _WH_OrigMaterials[comp] = nil
            end
        end)
    end
    pawn._WH_MIDs = nil
    _WH_ModifiedPawns[pawn] = nil
end

local function ApplyWallHack(enemy, pc)
    if not _G.LexusConfig.WallhackEnabled then return end
    if not Valid(enemy) or not Valid(pc) then return end
    local meshes = {}
    pcall(function()
        if Valid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
        local SkelClass = import("SkeletalMeshComponent")
        if SkelClass then
            local childs = enemy:GetComponentsByClass(SkelClass)
            if childs then
                local count = type(childs.Num) == "function" and childs:Num() or #childs
                for c = 1, count do
                    local comp = type(childs.Get) == "function" and childs:Get(c - 1) or childs[c]
                    if Valid(comp) and comp ~= enemy.Mesh then table.insert(meshes, comp) end
                end
            end
        end
    end)
    local isVisible = false
    pcall(function() if type(pc.LineOfSightTo) == "function" then isVisible = pc:LineOfSightTo(enemy) end end)
    local bodyColor = isVisible and { R = 0, G = 255, B = 0, A = 255 } or { R = 255, G = 0, B = 0, A = 255 }
    local glowColor = isVisible and { R = 0, G = 255, B = 255, A = 255 } or { R = 255, G = 0, B = 128, A = 255 }
    enemy._WH_MIDs = enemy._WH_MIDs or {}
    local stateChanged = (enemy._WH_LastVisible ~= isVisible)
    enemy._WH_LastVisible = isVisible
    _WH_ModifiedPawns[enemy] = true
    for _, comp in ipairs(meshes) do
        if Valid(comp) then
            if not _WH_OrigMaterials[comp] then
                local orig = {}
                for i = 0, 15 do
                    local ok, mat = pcall(function() return comp:GetMaterial(i) end)
                    if ok and Valid(mat) then orig[i] = mat else break end
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
                if ok and Valid(mat) then
                    local ok2, base = pcall(function() return mat:GetBaseMaterial() end)
                    if ok2 and Valid(base) then
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
            enemy._WH_MIDs[comp] = enemy._WH_MIDs[comp] or {}
            for i = 0, 15 do
                local ok3, mi = pcall(function() return comp:GetMaterial(i) end)
                if not ok3 or not Valid(mi) then break end
                local mid = enemy._WH_MIDs[comp][i]
                if not Valid(mid) then
                    local ok4, nm = pcall(function() return comp:CreateAndSetMaterialInstanceDynamic(i) end)
                    if ok4 and Valid(nm) then enemy._WH_MIDs[comp][i] = nm; mid = nm end
                else
                    if mi ~= mid then pcall(function() comp:SetMaterial(i, mid) end) end
                end
                if Valid(mid) and (stateChanged or not enemy._WH_MIDs[comp][i]) then
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

-- ========================================== 
-- GOKU-STYLE FEATURES (ESP, AIM, RECOIL, GRAPHICS)
-- ========================================== 
local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")

-- Helper functions from Goku
local function IsPawnAlive(p)
    if not Valid(p) then return false end
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
    if not Valid(p) then return end
    local COLOR_RED = FLinearColor(1, 0, 0, 1)
    if p.Replay_SetFrameUIColor then p:Replay_SetFrameUIColor(COLOR_RED)
    elseif p.SetEnemyFrameColor then p:SetEnemyFrameColor(COLOR_RED)
    elseif p.SetFrameColor then p:SetFrameColor(COLOR_RED)
    elseif p.SetOutlineColor then p:SetOutlineColor(COLOR_RED) end
end

-- Map marker distance system (300m)
local distanceMarkerConfig = {
    UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
    MaxWidgetNum = 99,
    MaxShowDistance = 999999,
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
            if InGameMarkTools.ClientRemoveMapMark then InGameMarkTools.ClientRemoveMapMark(enemy.NativeDistMark)
            elseif InGameMarkTools.HideMapMark then InGameMarkTools.HideMapMark(enemy.NativeDistMark) end
        end
        enemy.NativeDistMark = nil; _G.AK_Active_Marks_Cache[enemy] = nil
    end)
end

local function cleanupDeadEnemyMarks()
    for cacheKey, cacheData in pairs(_G.AK_Active_Marks_Cache) do
        local shouldRemove = false
        if not Valid(cacheKey) then shouldRemove = true
        else pcall(function()
            local actor = cacheData and cacheData.actor or cacheKey
            if actor then
                if actor.bHidden or (actor.Mesh and actor.Mesh.bHidden) then shouldRemove = true end
                if type(actor.IsDead) == "function" and actor:IsDead() then shouldRemove = true
                elseif actor.bIsDead == true or actor.bIsDeadFlag == true then shouldRemove = true end
            else shouldRemove = true end
        end) end
        if shouldRemove then
            pcall(function() if cacheData and InGameMarkTools and InGameMarkTools.ClientRemoveMapMark then InGameMarkTools.ClientRemoveMapMark(cacheData.distMark) end end)
            _G.AK_Active_Marks_Cache[cacheKey] = nil
        end
    end
end

local function processEnemyMapESP(enemy, localPlayer)
    if not _G.LexusConfig.ESPEnabled then return end
    if not Valid(enemy) or enemy == localPlayer or enemy.TeamID == localPlayer.TeamID then return end

    local dist = localPlayer:GetDistanceTo(enemy)
    if dist > 30000 then -- 300m
        if enemy.bHasAKNativeMapMarker then
            removeDistanceMarker(enemy)
            enemy.bHasAKNativeMapMarker = false
        end
        return
    end

    local isDead = false
    pcall(function()
        if type(enemy.IsDead) == "function" then isDead = enemy:IsDead()
        elseif enemy.bIsDead ~= nil then isDead = enemy.bIsDead
        elseif enemy.bIsDeadFlag ~= nil then isDead = enemy.bIsDeadFlag end
        if enemy.bHidden or (enemy.Mesh and enemy.Mesh.bHidden) then isDead = true end
        if not isDead then local health = 100; if type(enemy.GetHealth) == "function" then health = enemy:GetHealth() elseif enemy.Health ~= nil then health = enemy.Health end; if health <= 0 then isDead = true end end
    end)
    if not isDead then
        if not enemy.bHasAKNativeMapMarker then createDistanceMarker(enemy); enemy.bHasAKNativeMapMarker = true end
    else
        if enemy.bHasAKNativeMapMarker then removeDistanceMarker(enemy); enemy.bHasAKNativeMapMarker = false end
    end
end

-- Enemy Counter UI
local function LocalPlayerUILoop()
    pcall(function()
        if not _G.LexusConfig.ESPEnabled then return end
        local player = GameplayData.GetPlayerCharacter()
        if not Valid(player) then return end
        local pc = GameplayData.GetPlayerController()
        if not Valid(pc) then return end
        local hud = pc:GetHUD()
        if not Valid(hud) then return end
        local myTeamId = player.TeamID or 0
        local myPos = player:K2_GetActorLocation()
        local enemyCount = 0
        local allPawns = Game:GetAllPlayerPawns() or {}
        for _, pawn in pairs(allPawns) do
            if Valid(pawn) and pawn ~= player and (pawn.TeamID or 0) ~= myTeamId then
                local pos = pawn:K2_GetActorLocation()
                local dx = pos.X - myPos.X; local dy = pos.Y - myPos.Y; local dz = pos.Z - myPos.Z
                if (dx * dx + dy * dy + dz * dz) <= 900000000 then enemyCount = enemyCount + 1 end
            end
        end
        local text = ""
        local color = C_GREEN
        if enemyCount == 0 then text = "[ AREA SECURE ]"; color = C_GREEN
        elseif enemyCount == 1 then text = "! WARNING : 1 ENEMY !"; color = C_YELLOW
        else text = "[ DANGER : " .. enemyCount .. " ENEMIES ]"; color = C_RED end
        if _G.LexusConfig.WatermarkEnabled then text = text .. "\n✦ DEV~GOKUCONFIG ✦" end
        if text ~= "" then hud:AddDebugText(text, player, 1.1, { X=0, Y=0, Z=35 }, { X=0, Y=0, Z=35 }, color, true, false, true, nil, 1.05, true) end
    end)
end

-- Main ESP loop (health bar and box) – WITH WALLHACK TIMER ADDED
local function StartVisualTimers(pc)
    if _G.LexusState.VisualsStarted then return end
    _G.LexusState.VisualsStarted = true

    local cachedMarks = {}
    local cachedPawns = {}
    local lastPawnRefresh = 0
    local cachedMarksTime = {}

    -- ESP timer
    pc:AddGameTimer(0.8, true, function()
        if not _G.LexusConfig.ESPEnabled then
            for pawn, markId in pairs(cachedMarks) do if type(markId) ~= "table" and markId then InGameMarkTools.HideMapMark(markId) end end
            cachedMarks = {}; cachedMarksTime = {}; return
        end
        if not Valid(pc) then return end
        local uCon = pc
        local currentPawn = uCon:GetCurPawn()
        if not Valid(currentPawn) then return end
        local myTeamId = currentPawn.TeamID
        local myPos = currentPawn:K2_GetActorLocation()
        local HUD = uCon:GetHUD()
        local Canvas = Valid(HUD) and HUD.Canvas or nil
        local now = os.clock()
        if now - lastPawnRefresh > 1.0 then
            lastPawnRefresh = now
            cachedPawns = Game:GetAllPlayerPawns() or {}
            for pawnPtr, markId in pairs(cachedMarks) do
                local found = false
                for _, p in pairs(cachedPawns) do if p == pawnPtr then found = true; break end end
                if not found then
                    if markId then InGameMarkTools.HideMapMark(markId) end
                    cachedMarks[pawnPtr] = nil; cachedMarksTime[pawnPtr] = nil
                end
            end
        end
        local VEC_Z85 = FVector(0, 0, 85)
        local VEC_Z90 = FVector(0, 0, 90)
        local COLOR_HP_GREEN = FLinearColor(0, 1, 0, 0.95)
        local COLOR_HP_YELLOW = FLinearColor(1, 1, 0, 0.95)
        local COLOR_HP_RED = FLinearColor(1, 0, 0, 0.95)
        local COLOR_BG = FLinearColor(0, 0, 0, 0.55)
        local MAX_DIST = 30000  -- 300m
        for _, tPawn in pairs(cachedPawns) do
            if Valid(tPawn) and tPawn ~= currentPawn and tPawn.TeamID ~= myTeamId then
                if IsPawnAlive(tPawn) then
                    local enemyPos = tPawn:K2_GetActorLocation()
                    if enemyPos then
                        local dist = currentPawn:GetDistanceTo(tPawn)  -- 3D distance
                        if dist < MAX_DIST then
                            if tPawn.Replay_CreateEnemyFrameUI then tPawn:Replay_CreateEnemyFrameUI(true, true) end
                            SetRedFrameUI(tPawn)
                            if tPawn.Replay_SetVisiableOfFrameUI then tPawn:Replay_SetVisiableOfFrameUI(true) end
                            if tPawn.SetPlayerNameVisible then tPawn:SetPlayerNameVisible(true) end
                            local headPos, rootPos
                            if dist > 15000 then headPos, rootPos = enemyPos + VEC_Z85, enemyPos - VEC_Z85
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
                                if uCon:ProjectWorldLocationToScreen(headPos, false, headScreen) and uCon:ProjectWorldLocationToScreen(rootPos, false, rootScreen) then
                                    local screenHeight = math.max(25, math.abs(headScreen.Y - rootScreen.Y))
                                    local scaleFactor = math.max(0.3, math.min(1.5, 15000 / math.max(10000, dist)))
                                    local barWidth, barHeight = 4 * scaleFactor, screenHeight * scaleFactor
                                    local barX, barY = headScreen.X - (barWidth * 1.5), headScreen.Y
                                    local hp = GetPawnHealthRatio(tPawn)
                                    local color = hp < 0.3 and COLOR_HP_RED or (hp < 0.6 and COLOR_HP_YELLOW or COLOR_HP_GREEN)
                                    Canvas:K2_DrawBox(FVector2D(barX, barY), FVector2D(barWidth, barHeight), 1, COLOR_BG)
                                    Canvas:K2_DrawBox(FVector2D(barX, barY + barHeight * (1 - hp)), FVector2D(barWidth, barHeight * hp), 1, color)
                                    -- Text (name, state, distance) only if dist < 250m
                                    if dist < 25000 then
                                        local stateText = ""
                                        local pose = nil
                                        if tPawn.PoseState then pose = tPawn.PoseState
                                        elseif type(tPawn.GetPoseState) == "function" then pose = tPawn:GetPoseState() end
                                        if pose == 0 or pose == "Stand" then stateText = "Standing"
                                        elseif pose == 1 or pose == "Crouch" then stateText = "Crouching"
                                        elseif pose == 2 or pose == "Prone" then stateText = "Prone"
                                        else stateText = "Standing" end
                                        local isBot = CheckIsAI(tPawn, {}) or false
                                        local enemyName = "Enemy"
                                        pcall(function() if tPawn.PlayerName then enemyName = tPawn.PlayerName elseif type(tPawn.GetPlayerName) == "function" then enemyName = tPawn:GetPlayerName() end end)
                                        if enemyName == "" then enemyName = "Enemy" end
                                        local textColor = isBot and C_CYAN or C_YELLOW
                                        local dynamicScale = math.max(0.5, 0.8 - (dist / 40000))
                                        HUD:AddDebugText(enemyName, tPawn, 0.06, {X=0, Y=0, Z=-370}, {X=0, Y=0, Z=-370}, C_WHITE, true, false, true, nil, dynamicScale * 1.1, true)
                                        HUD:AddDebugText(string.format("[%dm]", math.floor(dist/100)), tPawn, 0.06, {X=0, Y=115, Z=20}, {X=0, Y=115, Z=20}, C_BLUE_TEXT, true, false, true, nil, dynamicScale * 1.5, true)
                                        HUD:AddDebugText(stateText, tPawn, 0.06, {X=0, Y=0, Z=100}, {X=0, Y=0, Z=100}, textColor, true, false, true, nil, dynamicScale, true)
                                    end
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

    -- WALLHACK TIMER (0.5s) – independent of ESP
    pc:AddGameTimer(0.5, true, function()
        if not _G.LexusConfig.WallhackEnabled then
            if _G._WH_NeedCleanup then
                for pawn, _ in pairs(_WH_ModifiedPawns) do if Valid(pawn) then ClearWallHackForPawn(pawn) end end
                _WH_OrigMaterials = setmetatable({}, { __mode = "k" })
                _WH_ModifiedPawns = setmetatable({}, { __mode = "k" })
                for base, orig in pairs(_WH_ModifiedBaseMaterials) do
                    pcall(function() if Valid(base) then base.bDisableDepthTest = orig.bDisableDepthTest; base.BlendMode = orig.BlendMode end end)
                end
                _WH_ModifiedBaseMaterials = setmetatable({}, { __mode = "k" })
                _G._WH_NeedCleanup = false
            end
            return
        end
        if not Valid(pc) then return end
        local uCon = pc
        local currentPawn = uCon:GetCurPawn()
        if not Valid(currentPawn) then return end
        local myTeamId = currentPawn.TeamID
        for _, tPawn in pairs(cachedPawns) do
            if Valid(tPawn) and tPawn ~= currentPawn and tPawn.TeamID ~= myTeamId and IsPawnAlive(tPawn) then
                local enemyPos = tPawn:K2_GetActorLocation()
                local dx = enemyPos.X - currentPawn:K2_GetActorLocation().X
                local dy = enemyPos.Y - currentPawn:K2_GetActorLocation().Y
                local dz = enemyPos.Z - currentPawn:K2_GetActorLocation().Z
                if (dx * dx + dy * dy + dz * dz) < 900000000 then
                    pcall(function() ApplyWallHack(tPawn, uCon) end)
                end
            end
        end
    end)

    -- Mini map ESP timer
    pc:AddGameTimer(1.5, true, function()
        if not _G.LexusConfig.ESPEnabled then
            for cacheKey, cacheData in pairs(_G.AK_Active_Marks_Cache) do
                pcall(function() if InGameMarkTools and InGameMarkTools.ClientRemoveMapMark then InGameMarkTools.ClientRemoveMapMark(cacheData.distMark) end end)
                _G.AK_Active_Marks_Cache[cacheKey] = nil
            end
            return
        end
        if not Valid(pc) then return end
        local localPlayer = GameplayData.GetPlayerCharacter()
        if not Valid(localPlayer) then return end
        local myTeamId = localPlayer.TeamID or 0
        local allPawns = Game:GetAllPlayerPawns() or {}
        for _, tPawn in pairs(allPawns) do
            if Valid(tPawn) and tPawn ~= localPlayer and tPawn.TeamID ~= myTeamId then processEnemyMapESP(tPawn, localPlayer) end
        end
        cleanupDeadEnemyMarks()
    end)

    -- Enemy counter timer
    pc:AddGameTimer(1.0, true, function()
        if not _G.LexusConfig.ESPEnabled then return end
        pcall(LocalPlayerUILoop)
    end)
end

-- =====================================================================
-- AIM ASSIST (from new script) – integrated with slider
-- =====================================================================
local aimOriginalCache = setmetatable({}, { __mode = "k" })
local AIM_BASE_VALUES = {
    Speed = 8.1, RangeRate = 1.8, SpeedRate = 2.5, RangeRateSight = 5.5,
    SpeedRateSight = 1.4, CrouchRate = 1.2, ProneRate = 1.1, DyingRate = 0
}

local function ApplyAimAssist()
    if not _G.LexusConfig.AimAssistEnabled then return end
    pcall(function()
        local pc = GameplayData.GetPlayerController()
        if not Valid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not Valid(char) then return end
        local wm = char.WeaponManagerComponent
        if not wm then return end
        local weapon = wm.CurrentWeaponReplicated
        if not weapon then return end
        local entity = weapon.ShootWeaponEntityComp
        if not Valid(entity) or not entity.AutoAimingConfig then return end

        local currentState = tostring(_G.LexusConfig.AimAssistEnabled) .. tostring(_G.LexusConfig.AimPower)
        if entity == _G.LexusState.LastAimEntity and currentState == _G.LexusState.LastAimState then return end
        _G.LexusState.LastAimEntity = entity
        _G.LexusState.LastAimState = currentState

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

        local slider = (_G.LexusConfig.AimPower or 50) / 100  -- 0 to 1
        local mult = 1.0 + slider * 1.5  -- multiplier from 1.0 to 2.5
        for _, range in ipairs({ "OuterRange", "InnerRange" }) do
            local cfg = entity.AutoAimingConfig[range]
            if cfg then
                for k, v in pairs(AIM_BASE_VALUES) do
                    cfg[k] = v * mult
                end
            end
        end
    end)
end

-- =====================================================================
-- NO RECOIL WITH SLIDER (0% = original, 100% = near-zero recoil)
-- =====================================================================
local recoilOriginalCache = setmetatable({}, { __mode = "k" })
local RECOIL_FIELDS = {
    "RecoilKick", "RecoilKickADS", "AnimationKick",
    "GameDeviationFactor", "RecoilModifierStand", "RecoilModifierCrouch", "RecoilModifierProne",
    "CameraShakeScale", "AimCameraShakeScale", "ShootCameraShakeScale", "FireCameraShakeScale",
    "GameDeviationAccuracy", "ShotGunHorizontalSpread", "ShotGunVerticalSpread", "DeviationMultiplier"
}
-- Target values for 100% (near-zero recoil)
local RECOIL_TARGET_VALUES = {
    RecoilKick = 0.01,
    RecoilKickADS = 0.01,
    AnimationKick = 0.01,
    GameDeviationFactor = 0.01,
    RecoilModifierStand = 0.01,
    RecoilModifierCrouch = 0.01,
    RecoilModifierProne = 0.01,
    CameraShakeScale = 0.01,
    AimCameraShakeScale = 0.01,
    ShootCameraShakeScale = 0.01,
    FireCameraShakeScale = 0.01,
    GameDeviationAccuracy = 0.01,
    ShotGunHorizontalSpread = 0.01,
    ShotGunVerticalSpread = 0.01,
    DeviationMultiplier = 0.01
}
local RECOIL_INFO_FIELDS = { "VerticalRecoilMin", "VerticalRecoilMax", "RecoilSpeedVertical", "RecoilSpeedHorizontal", "VerticalRecoveryMax" }
local RECOIL_INFO_TARGET = {
    VerticalRecoilMin = 0.01,
    VerticalRecoilMax = 0.01,
    RecoilSpeedVertical = 0.01,
    RecoilSpeedHorizontal = 0.01,
    VerticalRecoveryMax = 0.01
}

local function ApplyNoRecoil()
    pcall(function()
        local pc = GameplayData.GetPlayerController()
        if not Valid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not Valid(char) then return end
        local wm = char.WeaponManagerComponent
        if not wm then return end
        local weapon = wm.CurrentWeaponReplicated
        if not weapon then return end
        local entity = weapon.ShootWeaponEntityComp
        if not Valid(entity) then return end

        -- If disabled, restore original
        if not _G.LexusConfig.NoRecoilEnabled then
            if recoilOriginalCache[entity] then
                local saved = recoilOriginalCache[entity]
                for k, v in pairs(saved) do
                    if k == "RecoilInfo" then
                        if entity.RecoilInfo then for rk, rv in pairs(v) do entity.RecoilInfo[rk] = rv end end
                    elseif k == "ShootCameraShakeScale" then
                        if entity.ShootCameraShake then entity.ShootCameraShake.Scale = v end
                    else entity[k] = v end
                end
            end
            return
        end

        -- Cache original values once
        if not recoilOriginalCache[entity] then
            local saved = { RecoilInfo = {} }
            for _, f in ipairs(RECOIL_FIELDS) do if entity[f] ~= nil then saved[f] = entity[f] end end
            if entity.RecoilInfo then for _, f in ipairs(RECOIL_INFO_FIELDS) do if entity.RecoilInfo[f] ~= nil then saved.RecoilInfo[f] = entity.RecoilInfo[f] end end end
            if entity.ShootCameraShake then saved.ShootCameraShakeScale = entity.ShootCameraShake.Scale end
            recoilOriginalCache[entity] = saved
        end

        local orig = recoilOriginalCache[entity]
        local slider = (_G.LexusConfig.RecoilReduction or 100) / 100  -- 0 to 1
        if slider > 1 then slider = 1 end
        if slider < 0 then slider = 0 end

        -- Apply blend between original and target
        for _, f in ipairs(RECOIL_FIELDS) do
            if entity[f] ~= nil and orig[f] ~= nil and RECOIL_TARGET_VALUES[f] ~= nil then
                local target = RECOIL_TARGET_VALUES[f]
                entity[f] = orig[f] + (target - orig[f]) * slider
            end
        end

        if entity.RecoilInfo then
            for _, f in ipairs(RECOIL_INFO_FIELDS) do
                if entity.RecoilInfo[f] ~= nil and orig.RecoilInfo[f] ~= nil and RECOIL_INFO_TARGET[f] ~= nil then
                    local target = RECOIL_INFO_TARGET[f]
                    entity.RecoilInfo[f] = orig.RecoilInfo[f] + (target - orig.RecoilInfo[f]) * slider
                end
            end
        end

        if entity.ShootCameraShake then
            local origScale = orig.ShootCameraShakeScale or 1.0
            local targetScale = 0.01
            entity.ShootCameraShake.Scale = origScale + (targetScale - origScale) * slider
        end
    end)
end
-- =====================================================================

-- iPad view
local ipadViewOrigCache = setmetatable({}, { __mode = "k" })
local function ApplyiPadView()
    pcall(function()
        local pc = GameplayData.GetPlayerController()
        if not Valid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not Valid(char) or not char.ThirdPersonCameraComponent then return end
        local cam = char.ThirdPersonCameraComponent
        if not _G.LexusConfig.iPadViewEnabled then
            if ipadViewOrigCache[char] then cam.FieldOfView = ipadViewOrigCache[char] end
            return
        end
        if not ipadViewOrigCache[char] then ipadViewOrigCache[char] = cam.FieldOfView or 90 end
        local isAiming = false
        pcall(function() isAiming = char.bIsTargeting end)
        if isAiming then return end
        local targetFov = _G.LexusConfig.iPadViewFOV or 110
        if cam.FieldOfView ~= targetFov then cam.FieldOfView = targetFov end
    end)
end

-- Graphics tweaks
local function ApplyEnvironment()
    pcall(function()
        local gi = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
        if not gi then return end
        if _G.LexusConfig.VisualCleanupEnabled then
            gi:ExecuteCMD("grass.DensityScale", "0")
            gi:ExecuteCMD("grass.DiscardDataOnLoad", "1")
        else
            gi:ExecuteCMD("grass.DensityScale", "1")
            gi:ExecuteCMD("grass.DiscardDataOnLoad", "0")
        end
    end)
end

local function AutoRAMCleaner()
    pcall(function() if _G.LexusConfig.AntiLagEnabled then collectgarbage("step", 200) end end)
end

-- =====================================================================
-- VEHICLE ESP – FIXED: Using HUD:AddDebugText with cache, no blink
-- =====================================================================
_G._VehicleCacheTime = nil
_G._VehicleCache = nil

local function VehicleESPLoop()
    if not _G.LexusConfig.VehicleESP then return end
    pcall(function()
        local pc = GameplayData.GetPlayerController()
        if not Valid(pc) then return end
        local localPlayer = pc:GetPlayerCharacterSafety()
        if not Valid(localPlayer) then return end
        local myPos = localPlayer:K2_GetActorLocation()
        if not myPos then return end
        local HUD = pc:GetHUD()
        if not Valid(HUD) then return end

        if not _G._VehicleCacheTime or os.clock() - _G._VehicleCacheTime > 1.0 then
            _G._VehicleCacheTime = os.clock()
            _G._VehicleCache = Game:GetAllVehicles() or {}
        end

        for _, vehicle in pairs(_G._VehicleCache) do
            if Valid(vehicle) then
                local vPos = vehicle:K2_GetActorLocation()
                local dx = vPos.X - myPos.X
                local dy = vPos.Y - myPos.Y
                local dz = vPos.Z - myPos.Z
                local distSq = dx * dx + dy * dy + dz * dz
                if distSq < 900000000 then
                    local dist = math.sqrt(distSq)
                    local distText = string.format("[%.0fm]", dist / 100)
                    HUD:AddDebugText("Vehicle " .. distText, vehicle, 1.0,
                        { X = 0, Y = 0, Z = 100 }, { X = 0, Y = 0, Z = 100 },
                        { R = 255, G = 255, B = 0, A = 255 },
                        true, false, true, nil, 1.0, true)
                end
            end
        end
    end)
end

-- Match watchdog to start features
local function StartMatchFeatures(pc, pawn)
    pcall(InitDistanceMarkerSystem)
    pcall(ApplyEnvironment)
    pc:AddGameTimer(5.0, true, ApplyEnvironment)
    pc:AddGameTimer(0.5, true, ApplyAimAssist)
    pc:AddGameTimer(2.0, true, ApplyNoRecoil)
    pc:AddGameTimer(2.0, true, ApplyiPadView)
    pc:AddGameTimer(35.0, true, AutoRAMCleaner)
    pc:AddGameTimer(1.0, true, VehicleESPLoop)    -- FIXED: timer 1.0s
    StartVisualTimers(pc)
    if isExpired then pcall(ShowExpiryDialog); pc:AddGameTimer(5.0, true, ShowExpiryDialog) end
end

local function MatchWatchdog()
    local pc = GameplayData.GetPlayerController()
    local pawn = pc and pc:GetCurPawn()
    if Valid(pc) and Valid(pawn) then
        if not _G.LexusState.MatchStarted then
            _G.LexusState.MatchStarted = true
            _G.LexusState.VisualsStarted = false
            pcall(StartMatchFeatures, pc, pawn)
        end
    else
        if _G.LexusState.MatchStarted then
            _G.LexusState.MatchStarted = false
            _G.LexusState.VisualsStarted = false
            pcall(function()
                if _G.AK_Active_Marks_Cache then
                    for k, v in pairs(_G.AK_Active_Marks_Cache) do _G.AK_Active_Marks_Cache[k] = nil end
                end
                _G.LexusState.LastAimEntity = nil; _G.LexusState.LastAimState = nil
                _G.LexusState.LastRecoilEntity = nil; _G.LexusState.LastRecoilState = nil
                _G._VehicleCache = nil; _G._VehicleCacheTime = nil
                collectgarbage("collect")
            end)
        end
    end
end

-- ========================================== 
-- MENU INIT (CATEGORIES: ESP -> Combat -> Graphics -> Skin)
-- ========================================== 
function _G.InitModMenuTab()
    if _G.ModMenuInitialized then return end
    _G.ModMenuInitialized = true

    _G.LexusState.CustomTextData = _G.LexusState.CustomTextData or {
        SkinSuit = 1, SkinBag = 1, SkinHelmet = 1,
        SkinM416 = 1, SkinAKM = 1, SkinSCAR = 1, SkinM762 = 1, SkinAUG = 1, SkinUMP = 1,
        SkinUZI = 1, SkinGroza = 1, SkinS12K = 1, SkinDBS = 1, SkinASM = 1, SkinQBZ = 1,
        SkinHoney = 1, SkinM16A4 = 1, SkinACE32 = 1, SkinKar98k = 1, SkinM24 = 1, SkinAWM = 1,
        SkinDacia = 1, SkinUAZ = 1, SkinCoupe = 1, SkinBuggy = 1, SkinMirado = 1,
        AimPower = 50,
        iPadViewFOV = 110
    }

    local LocUtil = _G.LocUtil
    if not LocUtil and package.loaded["client.common.LocUtil"] then
        LocUtil = require("client.common.LocUtil")
    end
    
    if LocUtil and not LocUtil._IsModMenuHooked then
        local old_get = LocUtil.GetLocalizeResStr
        LocUtil.GetLocalizeResStr = function(id)
            if type(id) == "string" and not tonumber(id) then
                return id
            end
            return old_get(id)
        end
        LocUtil._IsModMenuHooked = true
    end

    local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
    local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")
    
    if not SettingPageDefine.ModMenu then
        local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")
        
        -- Category 1: ESP & Visuals
        local StackESP = {
            { Key = "ModMenu_ESP", UI = AliasMap.Switcher, Text = "ESP (Health Bar + Box + MiniMap + Enemy Counter)", GetFunc = function() return _G.LexusConfig.ESPEnabled end, SetFunc = function(c,v) _G.LexusConfig.ESPEnabled = v return true end },
            { Key = "ModMenu_Wallhack", UI = AliasMap.Switcher, Text = "Wallhack (Chams)", GetFunc = function() return _G.LexusConfig.WallhackEnabled end, SetFunc = function(c,v) _G.LexusConfig.WallhackEnabled = v; if not v then _G._WH_NeedCleanup = true; end; return true end },
            { Key = "ModMenu_Watermark", UI = AliasMap.Switcher, Text = "Watermark", GetFunc = function() return _G.LexusConfig.WatermarkEnabled end, SetFunc = function(c,v) _G.LexusConfig.WatermarkEnabled = v return true end },
            { Key = "ModMenu_VehicleESP", UI = AliasMap.Switcher, Text = "Vehicle ESP", GetFunc = function() return _G.LexusConfig.VehicleESP end, SetFunc = function(c,v) _G.LexusConfig.VehicleESP = v; if not v then pcall(function() _G._VehicleCache = nil; _G._VehicleCacheTime = nil end) end; return true end },
        }

        -- Category 2: Combat
        local StackCombat = {
            { Key = "ModMenu_AimAssist", UI = AliasMap.Switcher, Text = "Aim Assist (Master Toggle)", GetFunc = function() return _G.LexusConfig.AimAssistEnabled end, SetFunc = function(c,v) _G.LexusConfig.AimAssistEnabled = v; _G.LexusState.LastAimState = nil return true end },
            { Key = "ModMenu_AimPower", UI = AliasMap.Slider, Text = "Aim Power (0=Legit, 100=Max)", MinValue = 0, MaxValue = 100, GetFunc = function() return _G.LexusConfig.AimPower or 50 end, SetFunc = function(c,v) _G.LexusConfig.AimPower = v; _G.LexusState.LastAimState = nil return true end },
            { Key = "ModMenu_NoRecoil", UI = AliasMap.Switcher, Text = "Less Recoil (Master Toggle)", GetFunc = function() return _G.LexusConfig.NoRecoilEnabled end, SetFunc = function(c,v) _G.LexusConfig.NoRecoilEnabled = v return true end },
            { Key = "ModMenu_RecoilReduction", UI = AliasMap.Slider, Text = "Recoil Reduction (0=Off, 100=Max)", GetFunc = function() return _G.LexusConfig.RecoilReduction or 100 end, SetFunc = function(c,v) _G.LexusConfig.RecoilReduction = v; _G.LexusState.LastRecoilState = nil return true end },
        }

        -- Category 3: Graphics Tweaks
        local StackGraphics = {
            { Key = "ModMenu_iPadView", UI = AliasMap.Switcher, Text = "Enable iPad View", GetFunc = function() return _G.LexusConfig.iPadViewEnabled end, SetFunc = function(c,v) _G.LexusConfig.iPadViewEnabled = v; ApplyiPadView() return true end },
            { Key = "ModMenu_iPadFOV", UI = AliasMap.Slider, Text = "iPad View FOV (110-130)", GetFunc = function() local val = _G.LexusConfig.iPadViewFOV or 110; return ((val - 110) / 20) * 100 end, SetFunc = function(c,v) local val = tonumber(v) or 0; if val > 100 then val = 100 end; if val < 0 then val = 0 end; _G.LexusConfig.iPadViewFOV = 110 + (val / 100) * 20; ApplyiPadView() return true end },
            { Key = "ModMenu_NoGrass", UI = AliasMap.Switcher, Text = "Visual Cleanup (No Grass)", GetFunc = function() return _G.LexusConfig.VisualCleanupEnabled end, SetFunc = function(c,v) _G.LexusConfig.VisualCleanupEnabled = v; ApplyEnvironment() return true end },
            { Key = "ModMenu_AntiLag", UI = AliasMap.Switcher, Text = "Anti-Lag (Auto Clear RAM)", GetFunc = function() return _G.LexusConfig.AntiLagEnabled end, SetFunc = function(c,v) _G.LexusConfig.AntiLagEnabled = v return true end },
        }

        -- Category 4: Skin Mods (full)
        local StackSkin = {
            { Key = "ModMenu_ModSkin", UI = AliasMap.TitleSwitcher, Text = "▶ Mod Skin)", ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.ModSkin end, SetFunc = function(c,v) _G.LexusConfig.ModSkin = v return true end },
            
            -- Suit, Bag, Helmet
            { Key = "ModMenu_Skin_Suit", UI = AliasMap.Slider, Text = "   Suit", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 80, GetFunc = function() return _G.LexusState.CustomTextData.SkinSuit or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinSuit = v; if _G.OutfitSkins and _G.OutfitSkins.Suit[v] then _G.OutfitMap.Suit = _G.OutfitSkins.Suit[v] end return true end },           
            { Key = "ModMenu_Skin_Bag", UI = AliasMap.Slider, Text = "   Backpack", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 15, GetFunc = function() return _G.LexusState.CustomTextData.SkinBag or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinBag = v; if _G.OutfitSkins and _G.OutfitSkins.Bag[v] then _G.OutfitMap.Bag = _G.OutfitSkins.Bag[v] end return true end },
            { Key = "ModMenu_Skin_Helmet", UI = AliasMap.Slider, Text = "   Helmet", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 11, GetFunc = function() return _G.LexusState.CustomTextData.SkinHelmet or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinHelmet = v; if _G.OutfitSkins and _G.OutfitSkins.Helmet[v] then _G.OutfitMap.Helmet = _G.OutfitSkins.Helmet[v] end return true end },

            -- Weapons
            { Key = "ModMenu_Skin_M416", UI = AliasMap.Slider, Text = "    M416", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 8, GetFunc = function() return _G.LexusState.CustomTextData.SkinM416 or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinM416 = v; if _G.skinIdMappings[101004] and _G.skinIdMappings[101004][v] then _G.WeaponSkinMap[101004] = _G.skinIdMappings[101004][v] end return true end },
            { Key = "ModMenu_Skin_AKM", UI = AliasMap.Slider, Text = "    AKM", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 8, GetFunc = function() return _G.LexusState.CustomTextData.SkinAKM or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinAKM = v; if _G.skinIdMappings[101001] and _G.skinIdMappings[101001][v] then _G.WeaponSkinMap[101001] = _G.skinIdMappings[101001][v] end return true end },
            { Key = "ModMenu_Skin_SCAR", UI = AliasMap.Slider, Text = "   SCAR-L", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 8, GetFunc = function() return _G.LexusState.CustomTextData.SkinSCAR or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinSCAR = v; if _G.skinIdMappings[101003] and _G.skinIdMappings[101003][v] then _G.WeaponSkinMap[101003] = _G.skinIdMappings[101003][v] end return true end },
            { Key = "ModMenu_Skin_M762", UI = AliasMap.Slider, Text = "   Beryl M762", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 8, GetFunc = function() return _G.LexusState.CustomTextData.SkinM762 or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinM762 = v; if _G.skinIdMappings[101008] and _G.skinIdMappings[101008][v] then _G.WeaponSkinMap[101008] = _G.skinIdMappings[101008][v] end return true end },
            { Key = "ModMenu_Skin_AUG", UI = AliasMap.Slider, Text = "    AUG", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 7, GetFunc = function() return _G.LexusState.CustomTextData.SkinAUG or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinAUG = v; if _G.skinIdMappings[101006] and _G.skinIdMappings[101006][v] then _G.WeaponSkinMap[101006] = _G.skinIdMappings[101006][v] end return true end },
            { Key = "ModMenu_Skin_UMP", UI = AliasMap.Slider, Text = "    UMP45", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 5, GetFunc = function() return _G.LexusState.CustomTextData.SkinUMP or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinUMP = v; if _G.skinIdMappings[102002] and _G.skinIdMappings[102002][v] then _G.WeaponSkinMap[102002] = _G.skinIdMappings[102002][v] end return true end },
            { Key = "ModMenu_Skin_UZI", UI = AliasMap.Slider, Text = "    UZI", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.LexusState.CustomTextData.SkinUZI or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinUZI = v; if _G.skinIdMappings[102001] and _G.skinIdMappings[102001][v] then _G.WeaponSkinMap[102001] = _G.skinIdMappings[102001][v] end return true end },
            { Key = "ModMenu_Skin_Groza", UI = AliasMap.Slider, Text = "   Groza", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.LexusState.CustomTextData.SkinGroza or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinGroza = v; if _G.skinIdMappings[101005] and _G.skinIdMappings[101005][v] then _G.WeaponSkinMap[101005] = _G.skinIdMappings[101005][v] end return true end },
            { Key = "ModMenu_Skin_S12K", UI = AliasMap.Slider, Text = "   S12K", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.LexusState.CustomTextData.SkinS12K or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinS12K = v; if _G.skinIdMappings[104003] and _G.skinIdMappings[104003][v] then _G.WeaponSkinMap[104003] = _G.skinIdMappings[104003][v] end return true end },
            { Key = "ModMenu_Skin_DBS", UI = AliasMap.Slider, Text = "  DBS", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 3, GetFunc = function() return _G.LexusState.CustomTextData.SkinDBS or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinDBS = v; if _G.skinIdMappings[104004] and _G.skinIdMappings[104004][v] then _G.WeaponSkinMap[104004] = _G.skinIdMappings[104004][v] end return true end },
            { Key = "ModMenu_Skin_ASM", UI = AliasMap.Slider, Text = "   ASM", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.LexusState.CustomTextData.SkinASM or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinASM = v; if _G.skinIdMappings[101101] and _G.skinIdMappings[101101][v] then _G.WeaponSkinMap[101101] = _G.skinIdMappings[101101][v] end return true end },
            { Key = "ModMenu_Skin_QBZ", UI = AliasMap.Slider, Text = "   QBZ", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.LexusState.CustomTextData.SkinQBZ or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinQBZ = v; if _G.skinIdMappings[101007] and _G.skinIdMappings[101007][v] then _G.WeaponSkinMap[101007] = _G.skinIdMappings[101007][v] end return true end },
            { Key = "ModMenu_Skin_Honey", UI = AliasMap.Slider, Text = "    Honey Badger", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.LexusState.CustomTextData.SkinHoney or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinHoney = v; if _G.skinIdMappings[101012] and _G.skinIdMappings[101012][v] then _G.WeaponSkinMap[101012] = _G.skinIdMappings[101012][v] end return true end },
            { Key = "ModMenu_Skin_M16A4", UI = AliasMap.Slider, Text = "    M16A4", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.LexusState.CustomTextData.SkinM16A4 or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinM16A4 = v; if _G.skinIdMappings[101002] and _G.skinIdMappings[101002][v] then _G.WeaponSkinMap[101002] = _G.skinIdMappings[101002][v] end return true end },
            { Key = "ModMenu_Skin_ACE32", UI = AliasMap.Slider, Text = "    ACE32", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.LexusState.CustomTextData.SkinACE32 or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinACE32 = v; if _G.skinIdMappings[101102] and _G.skinIdMappings[101102][v] then _G.WeaponSkinMap[101102] = _G.skinIdMappings[101102][v] end return true end },
            { Key = "ModMenu_Skin_Kar98k", UI = AliasMap.Slider, Text = "    Kar98k", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.LexusState.CustomTextData.SkinKar98k or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinKar98k = v; if _G.skinIdMappings[103001] and _G.skinIdMappings[103001][v] then _G.WeaponSkinMap[103001] = _G.skinIdMappings[103001][v] end return true end },
            { Key = "ModMenu_Skin_M24", UI = AliasMap.Slider, Text = "   M24", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.LexusState.CustomTextData.SkinM24 or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinM24 = v; if _G.skinIdMappings[103002] and _G.skinIdMappings[103002][v] then _G.WeaponSkinMap[103002] = _G.skinIdMappings[103002][v] end return true end },
            { Key = "ModMenu_Skin_AWM", UI = AliasMap.Slider, Text = "    AWM", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.LexusState.CustomTextData.SkinAWM or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinAWM = v; if _G.skinIdMappings[103003] and _G.skinIdMappings[103003][v] then _G.WeaponSkinMap[103003] = _G.skinIdMappings[103003][v] end return true end },

            -- Vehicles
            { Key = "ModMenu_Skin_Dacia", UI = AliasMap.Slider, Text = "   Dacia", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 90, GetFunc = function() return _G.LexusState.CustomTextData.SkinDacia or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinDacia = v; if _G.VehicleSkins[1903001] and _G.VehicleSkins[1903001][v] then _G.VehicleSkinMap[1903001] = _G.VehicleSkins[1903001][v] end return true end },
            { Key = "ModMenu_Skin_UAZ", UI = AliasMap.Slider, Text = "   UAZ", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 90, GetFunc = function() return _G.LexusState.CustomTextData.SkinUAZ or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinUAZ = v; if _G.VehicleSkins[1908001] and _G.VehicleSkins[1908001][v] then _G.VehicleSkinMap[1908001] = _G.VehicleSkins[1908001][v] end return true end },
            { Key = "ModMenu_Skin_Coupe", UI = AliasMap.Slider, Text = "   Coupe RB", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 70, GetFunc = function() return _G.LexusState.CustomTextData.SkinCoupe or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinCoupe = v; if _G.VehicleSkins[1961001] and _G.VehicleSkins[1961001][v] then _G.VehicleSkinMap[1961001] = _G.VehicleSkins[1961001][v] end return true end },
            { Key = "ModMenu_Skin_Buggy", UI = AliasMap.Slider, Text = "   Buggy", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 50, GetFunc = function() return _G.LexusState.CustomTextData.SkinBuggy or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinBuggy = v; if _G.VehicleSkins[1907001] and _G.VehicleSkins[1907001][v] then _G.VehicleSkinMap[1907001] = _G.VehicleSkins[1907001][v] end return true end },
            { Key = "ModMenu_Skin_Mirado", UI = AliasMap.Slider, Text = "   Mirado", ExpandHandle = "ModMenu_ModSkin", MinValue = 1, MaxValue = 27, GetFunc = function() return _G.LexusState.CustomTextData.SkinMirado or 1 end, SetFunc = function(c,v) _G.LexusState.CustomTextData.SkinMirado = v; if _G.VehicleSkins[1915001] and _G.VehicleSkins[1915001][v] then _G.VehicleSkinMap[1915001] = _G.VehicleSkins[1915001][v] end return true end }
        }

        SettingPageDefine.ModMenu = {
            Key = "ModMenu",
            loc = "GOKUCONFIG",
            UIKey = "Setting_Page_Privacy", 
            Category = {
                { Key = "Cat_ESP", loc = "ESP & VISUALS", Stack = StackESP },
                { Key = "Cat_Combat", loc = "COMBAT", Stack = StackCombat },
                { Key = "Cat_Graphics", loc = "GRAPHICS TWEAKS", Stack = StackGraphics },
                { Key = "Cat_Skin", loc = "MOD SKIN", Stack = StackSkin }
            }
        }
        
        table.insert(SettingCatalog, SettingPageDefine.ModMenu)
    end

    local UIManager = _G.UIManager
    if UIManager and not UIManager._IsModMenuHooked then
        local old_ShowUI = UIManager.ShowUI
        UIManager.ShowUI = function(config, ...)
            local args = {...}
            local n = select('#', ...) 
            
            if config and config.keyName and (string.find(string.lower(config.keyName), "setting_main") or string.find(string.lower(config.keyName), "setting")) then
                local catalog = args[1]
                if type(catalog) == "table" then
                    local hasModMenu = false
                    for _, page in ipairs(catalog) do
                        if type(page) == "table" and page.Key == "ModMenu" then
                            hasModMenu = true
                            break
                        end
                    end
                    if not hasModMenu then
                        table.insert(catalog, SettingPageDefine.ModMenu)
                    end
                end
            end
            local table_unpack = table.unpack or unpack
            return old_ShowUI(config, table_unpack(args, 1, n))
        end
        UIManager._IsModMenuHooked = true
    end
end

-- ========================================== 
-- MAIN LOOP (skin + Higgs disable + watchdog)
-- ========================================== 
local function MainLoop() 
    if isExpired then return end

    if _G.LexusState.CustomTextData == nil then 
        _G.LexusState.CustomTextData = {
            SkinSuit = 1, SkinBag = 1, SkinHelmet = 1,
            SkinM416 = 1, SkinAKM = 1, SkinSCAR = 1, SkinM762 = 1, SkinAUG = 1, SkinUMP = 1,
            SkinUZI = 1, SkinGroza = 1, SkinS12K = 1, SkinDBS = 1, SkinASM = 1, SkinQBZ = 1,
            SkinHoney = 1, SkinM16A4 = 1, SkinACE32 = 1, SkinKar98k = 1, SkinM24 = 1, SkinAWM = 1,
            SkinDacia = 1, SkinUAZ = 1, SkinCoupe = 1, SkinBuggy = 1, SkinMirado = 1,
            AimPower = 50,
            iPadViewFOV = 110
        }
    end

    local okData, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData") 
    if not okData or not GameplayData then return end 
    local pc = GameplayData.GetPlayerController() 
    local localPlayer = nil
    if Valid(pc) then localPlayer = pc:GetPlayerCharacterSafety() end 

    -- XÓA SẠCH SÀNH SANH RÁC KHỎI RAM KHI BẠN CHẾT, ĐỔI MAP, VÀO SẢNH
    if not Valid(localPlayer) then 
        if _G.LexusState.TrackedMarks then
            for markId, _ in pairs(_G.LexusState.TrackedMarks) do
                SafeRemoveMark(markId)
            end
        end
        _G.LexusState.TrackedMarks = {} 
        _G.LexusState.EnemyMarks = {}
        _G.LexusState.PrevGraphicsState = {}
        return 
    end

    -- Show welcome once
    if not _G.LexusWelcomeShown then
        _G.LexusWelcomeShown = true
        ShowWelcomePopup()
    end

    -- Init menu if not done
    if not _G.ModMenuInitialized then
        _G.InitModMenuTab()
        Notify("ADDED 'VIP MOD MENU' TO GAME SETTINGS!\nOpen Settings (Gear) -> VIP MOD MENU to toggle and adjust sliders during match!")
    end

    -- ========================================================
    -- THỰC THI MOD SKIN ĐƯỢC TÍCH HỢP TRỰC TIẾP VÀO MAIN LOOP (TỐI ƯU TUYỆT ĐỐI)
    -- ========================================================
    if _G.LexusConfig.ModSkin then
        if not _G.TDSkinLoopStarted then
            if _G.InitializeSkinModSystem then _G.InitializeSkinModSystem() end
            if _G.ForceRefreshSkinMaps then _G.ForceRefreshSkinMaps() end
            _G.TDSkinLoopStarted = true
        end
        
        _G.LexusState.SkinWasApplied = true
        local curTime = os.clock()
        
        -- [FIX CHỐNG ĐƠ VÀ DROP FPS]: Chỉ thực thi logic Skin 1.5 giây một lần (nhưng skin vẫn đổi ngay lập tức nhờ Cache)
        if not _G.LastSkinUpdateTime or (curTime - _G.LastSkinUpdateTime) > 1.5 then
            _G.LastSkinUpdateTime = curTime
            
            pcall(function()
                -- Ngắt hoàn toàn Mod Skin khi bạn đã chết hoặc đang hiện TOP 1 (Chống đơ đứng máy cuối trận)
                local isAlive = type(localPlayer.IsAlive) == "function" and localPlayer:IsAlive() or true
                
                if isAlive then
                    if _G.ReadLiveConfig then _G.ReadLiveConfig() end
                    if not _G.KillInfoCounterHacked and _G.ForceEnableKillCounterUI then _G.ForceEnableKillCounterUI() end
                    if _G.equip_character_avatar then _G.equip_character_avatar(localPlayer) end
                    if _G.ApplyWeaponSkins then _G.ApplyWeaponSkins(localPlayer) end
                    if _G.ApplyVehicleSkins then _G.ApplyVehicleSkins(localPlayer) end
                    if _G.HandlePetLogic then _G.HandlePetLogic() end                    
                end
            end)
        end
    else
        -- HOÀN TRẢ LẠI SKIN GỐC KHI TẮT
        if _G.LexusState.SkinWasApplied then
            _G.OutfitMap = {}
            _G.WeaponSkinMap = {}
            _G.VehicleSkinMap = {}
            
            pcall(function()
                local WeaponManager = localPlayer:GetWeaponManager()
                if Valid(WeaponManager) then
                    for slot = 1, 3 do
                        local Weapon = WeaponManager:GetInventoryWeaponByPropSlot(slot)
                        if Valid(Weapon) and Valid(Weapon.synData) then
                            local WeaponID = Weapon:GetWeaponID()
                            local SkinData = Weapon.synData:Get(7)
                            if SkinData and SkinData.defineID then
                                SkinData.defineID.TypeSpecificID = WeaponID
                                Weapon.synData:Set(7, SkinData)
                                if Weapon.SetWeaponAvatarID then pcall(function() Weapon:SetWeaponAvatarID(WeaponID) end) end
                                if Weapon.DelayHandleAvatarMeshChanged then pcall(function() Weapon:DelayHandleAvatarMeshChanged() end) end
                            end
                        end
                    end
                end
                
                local Vehicle = localPlayer:GetCurrentVehicle()
                if Valid(Vehicle) then
                    local VehicleAvatar = Vehicle.VehicleAvatar or Vehicle.VehicleAvatarComponent_BP or Vehicle:GetAvatarComponent()
                    if Valid(VehicleAvatar) and type(VehicleAvatar.GetDefaultAvatarID) == "function" then
                        local defId = VehicleAvatar:GetDefaultAvatarID()
                        if VehicleAvatar.ChangeItemAvatar then VehicleAvatar:ChangeItemAvatar(defId, true) end
                    end
                end
                
                if localPlayer.AvatarComponent2 and type(localPlayer.AvatarComponent2.OnRep_BodySlotStateChanged) == "function" then
                    localPlayer.AvatarComponent2:OnRep_BodySlotStateChanged()
                end
            end)
            
            _G.LexusState.SkinWasApplied = false
        end
        _G.TDSkinLoopStarted = false
    end

    -- CHẶN HIGGSBOSON THEO THỜI GIAN THỰC LÀM AN TOÀN TUYỆT ĐỐI MÀ KHÔNG GÂY VĂNG GAME
    pcall(function()
        if Valid(pc) then
            if pc.HiggsBoson then pc.HiggsBoson.bMHActive = false; pc.HiggsBoson.bCallPreReplication = false end
            if pc.HiggsBosonComponent then pc.HiggsBosonComponent.bMHActive = false; pc.HiggsBosonComponent.bCallPreReplication = false end
        end
    end)

    -- Apply iPad view toggle (immediate)
    ApplyiPadView()

    -- Apply environment (no grass) on toggle
    pcall(ApplyEnvironment)
end

-- ========================================== 
-- FIX: Persistent Watchdog Call Inside FastTick
-- ========================================== 
_G._lastWatchdogTime = 0   -- global throttling timer

_G.LexusState.LoopToken = (_G.LexusState.LoopToken or 0) + 1 
local myToken = _G.LexusState.LoopToken

local function FastTick() 
    if isExpired then 
        if not _G.LexusNotifiedExpire then
            Notify("MOD HAS EXPIRED! PLEASE CONTACT @GOKUCONFIG TO RENEW.")
            _G.LexusNotifiedExpire = true
            ShowExpiryDialog() 
        end
        return 
    end

    if myToken ~= _G.LexusState.LoopToken then return end

    -- Throttled watchdog call (once per second)
    local now = os.clock()
    if now - _G._lastWatchdogTime >= 1.0 then
        _G._lastWatchdogTime = now
        pcall(MatchWatchdog)
    end

    pcall(MainLoop) 
    local okTicker, ticker = pcall(require, "common.time_ticker") 
    if okTicker and ticker and ticker.AddTimerOnce then 
        ticker.AddTimerOnce(0.01, FastTick) 
    end 
end

if not isExpired then
    FastTick() 
    Notify("Welcome to GOKUCONFIG Premium Mod! All features are ready.")
else
    FastTick() 
end

-- ===================================================================================
-- SYSTEM HOOKS TỪ BYPASS MỚI
-- ===================================================================================
local function InitAllModSystems()
    if isExpired then return end 

    pcall(function()
        if _G.StartBypass_VIP_v3 then _G.StartBypass_VIP_v3() end
    end)

    local GameplayData = package.loaded["GameLua.GameCore.Data.GameplayData"] or require("GameLua.GameCore.Data.GameplayData")
    if not GameplayData then return end

    pcall(function()
        local LocalPlayer = GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
        if slua.isValid(LocalPlayer) then
            if LocalPlayer.bHasShownDevNotice == nil then
                LocalPlayer.bHasShownDevNotice = false 
                LocalPlayer.bHasShownExpiredNotice = false 
                LocalPlayer.bIsDeadFlag = false
            end
        end
    end)
    
    -- NOTE: The original timer that added MatchWatchdog has been removed.
    -- The watchdog is now called directly from FastTick.
end

if not isExpired then
    pcall(function() 
        require("common.time_ticker").AddTimerOnce(0.5, InitAllModSystems) 
    end)
end

-- ==============================================================================
-- ================== PHẦN RETURN ĐƯỢC GIỮ NGUYÊN TỪ CODE GỐC ===================
-- ==============================================================================
local class = require("class")
local CCharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CBRPlayerCharacterBase = class(CCharacterBase, nil, BRPlayerCharacterBase)
return require("combine_class").DeclareFeature(CBRPlayerCharacterBase, {
  {
    SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature"
  },
  {
    CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature"
  },
  {
    SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature"
  },
  {
    TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature"
  },
  {
    LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature"
  },
  {
    FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature"
  },
  {
    CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature"
  },
  {
    BuildSkateFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature"
  },
  {
    CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature"
  },
  {
    ParachuteFormation = "GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature"
  }
}, "BRPlayerCharacterBase")
