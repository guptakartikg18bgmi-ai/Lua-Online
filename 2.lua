-- =====================================================
-- Optimized Standalone 165 FPS Unlock for PUBG/BGMI Lua
-- Idempotent, safe hooks, robust error handling, localized globals
-- =====================================================

-- Performance: cache global functions as locals
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local pcall = pcall
local require = require
local tostring = tostring
local print = print or function(...) end      -- fallback if print is unavailable

-- slua.isValid is used extensively – cache it
local slua = slua
local isValid = (slua and slua.isValid) or function(obj) return obj ~= nil end

-- Idempotency guard: prevent double-hooking if script is injected twice
if _G.__165FPS_UNLOCK_PATCHED then
    print("[165FPS] Already patched – skipping.")
    return "165 FPS unlock already applied."
end

-- Wrapper for safe require + logging
local function safe_require(modname)
    local ok, mod = pcall(require, modname)
    if not ok then
        print("[165FPS] Failed to load module: " .. modname .. " – " .. tostring(mod))
        return nil
    end
    return mod
end

-- Load required game modules (all inside pcalls)
local graphics = safe_require("client.slua.logic.setting.logic_setting_graphics")
local fpsComp  = safe_require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
local fpsFT    = safe_require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
local db       = safe_require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")

-- If no db module, further UI patches can't be applied – but console cmd still works
if not db then
    print("[165FPS] GraphicSettingDB missing – UI patches will be skipped, console FPS cap only.")
end

-- Helper to safely get game instance for console commands
local function get_game_instance()
    if not db then return nil end
    local gi = (db.GetGameInstance and db:GetGameInstance())
    return gi
end

-- ========== 1. Patch graphics.SetFPS to enable 165 FPS level 8 ==========
local function patch_graphics_setFPS()
    if not graphics then return false, "graphics module not available" end
    if type(graphics.SetFPS) ~= "function" then
        return false, "graphics.SetFPS is not a function"
    end

    -- Save original only once (ensures idempotency inside this patch scope)
    if not graphics.__original_SetFPS then
        graphics.__original_SetFPS = graphics.SetFPS
    else
        return true, "already patched"
    end

    local orig = graphics.__original_SetFPS
    graphics.SetFPS = function(self, level)
        -- Call original first
        local ok, err = pcall(orig, self, level)
        if not ok then
            print("[165FPS] original SetFPS error: " .. tostring(err))
        end
        -- Override console commands for level 8
        if level == 8 then
            pcall(function()
                if self.ExecuteCMD then
                    self:ExecuteCMD("t.MaxFPS", "165")
                    self:ExecuteCMD("r.FrameRateLimit", "165")
                end
            end)
        end
    end
    return true, "patched"
end

-- ========== 2. Patch FPS selector component (GSC_FPS) ==========
local function patch_fps_component()
    if not fpsComp then return false, "fpsComp module not available" end
    if not fpsComp.__inner_impl then return false, "fpsComp.__inner_impl missing" end

    local impl = fpsComp.__inner_impl
    if impl.__165patched then return true, "already patched" end

    -- Override GetMaxFPSLevel to allow level 8
    impl.GetMaxFPSLevel = function()
        return 8, 8
    end

    -- Override InitRealSupportFPS to register all tiers
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

    -- Override UpdateSelectedFPSState to enable all UI nodes
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
    return true, "patched"
end

-- ========== 3. Patch fine‑tune slider (GSC_FPSFT) to range 90‑165 ==========
local function patch_fps_fine_tune()
    if not fpsFT then return false, "fpsFT module not available" end
    if not fpsFT.__inner_impl then return false, "fpsFT.__inner_impl missing" end
    if not db then return false, "db required for fine‑tune patching" end

    local impl = fpsFT.__inner_impl
    if impl.__165patched then return true, "already patched" end

    local MIN_FPS, MAX_FPS, STEP = 90, 165, 5

    local function clamp(v)
        return math_max(MIN_FPS, math_min(MAX_FPS, v))
    end

    -- ShowOrHide: always show panel
    impl.ShowOrHide = function(self)
        pcall(function() self:SelfHitTestInvisible() end)
        if self.InitFPSFTSwitch then
            pcall(self.InitFPSFTSwitch, self)
        end
    end

    -- InitFPSFTSwitch: configure switch and slider
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

    -- InitFPSFTValue165: display current fine‑tune value on slider
    impl.InitFPSFTValue165 = function(self)
        if not db then return end
        local UIRoot = self.UIRoot
        if not UIRoot then return end

        local on = db:GetUIData(db.FPSFineTuneSwitch)
        local val = on and (db:GetUIData(db.FPSFineTuneNum) or 165) or 165

        -- Safe node references
        local slider = UIRoot.Slider_screen3
        local progress = UIRoot.ProgressBar_screen3
        local textLabel = UIRoot.Veihclescreen3

        if not (slider and progress and textLabel) then
            return
        end

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

    -- OnFPSFTValueChange3: apply a new value
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

    -- Slider callback: snaps to STEP
    impl.OnFPSFTSliderValueChange3 = function(self, nv)
        if not db then return end
        if not db:GetUIData(db.FPSFineTuneSwitch) then return end
        local raw = math_floor(MIN_FPS + (MAX_FPS - MIN_FPS) * nv)
        raw = math_floor(raw / STEP) * STEP
        self:OnFPSFTValueChange3(clamp(raw))
    end

    -- Increment/decrement buttons
    impl.OnFPSFTAdd3 = function(self)
        local cur = (db and db:GetUIData(db.FPSFineTuneNum)) or MIN_FPS
        self:OnFPSFTValueChange3(math_min(MAX_FPS, cur + STEP))
    end

    impl.OnFPSFTMinus3 = function(self)
        local cur = (db and db:GetUIData(db.FPSFineTuneNum)) or MIN_FPS
        self:OnFPSFTValueChange3(math_max(MIN_FPS, cur - STEP))
    end

    -- Compatibility aliases for older UI event names
    impl.OnFPSFTAdd = impl.OnFPSFTAdd3
    impl.OnFPSFTMinus = impl.OnFPSFTMinus3
    impl.OnFPSFTSliderValueChange = impl.OnFPSFTSliderValueChange3

    impl.__165patched = true
    return true, "patched"
end

-- Apply all patches, collecting results
local results = {
    graphics = {pcall(patch_graphics_setFPS)},
    fpsComponent = {pcall(patch_fps_component)},
    fpsFineTune = {pcall(patch_fps_fine_tune)},
}

-- Log errors if any
for mod, res in pairs(results) do
    local ok, msg = table.unpack(res)
    if not ok then
        print(string.format("[165FPS] Patch %s failed: %s", mod, tostring(msg)))
    else
        print(string.format("[165FPS] Patch %s: %s", mod, tostring(msg)))
    end
end

-- Immediate console apply (works even if UI modules are missing)
local function apply_immediate()
    local gi = get_game_instance()
    if not gi then
        -- fallback: try GameplayData
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

-- Mark as patched
_G.__165FPS_UNLOCK_PATCHED = true

return "165 FPS unlock applied. Select 'Ultra Extreme' or use fine‑tune slider (90‑165)."
