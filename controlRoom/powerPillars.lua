--------------------------------------------------------------------------------
-- UPPER and MIDDLE Panel:              LOWER Panel:
--  ____________                         ____________
-- |LDDDD DDDDL|                        |           |
-- |lDDDD DDDDl|                        | SSSS SSSS |
-- |           |                        | SSSS SSSS |
-- |LDDDD DDDDL|                        |           |
-- |lDDDD DDDDl|                        | SSSS SSSS |
-- |           |                        | SSSS SSSS |
-- |LDDDD DDDDL|                        |           |
-- |lDDDD DDDDl|                        |           |
-- |           |                        |   DDDD ss |
-- |LDDDD DDDDL|                        |   DDDD ss |
-- |lDDDD_DDDDl|                        |___________|
--
-- L: Status light
-- l: Warning light
-- D: Text display
-- S: Switch
-- s: Stop

--------------------------------------------------------------------------------
-- Const and Enums
local LIGHT_X_POS = { 0, 10 }
local LIGHT_Y_POS = { 9, 6, 3, 0 }
local DISPLAY_X_POS = { 1, 6 }
local DISPLAY_Y_POS = { 9, 6, 3, 0 }
local SWITCH_X_POS = { 1, 2, 3, 4, 6, 7, 8, 9 }
local SWITCH_Y_POS = { 8, 5 }

local Panel = { UPPER = 2, CENTER = 1, LOWER = 0 }

--------------------------------------------------------------------------------
-- SwControl class
local SwControl = {}
SwControl.__index = SwControl

setmetatable(SwControl, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function SwControl.new(_name, _light1, _light2, _display, _switch)
    local self = setmetatable({}, SwControl)
    self.name = _name
    self.statusLight = _light1
    self.warningLight = _light2
    self.display = _display
    self.switch = _switch

    self.display.size = 60
    self.display.monospace = true
    self.status = false
    self.display.text = string.format("%s\n", self.name)
    return self
end

function SwControl:reset()
    self.statusLight:setColor(0, 0, 0, 0)
    self.warningLight:setColor(0, 0, 0, 0)
    self.display.text = ""
end

function SwControl:activate()
    self.statusLight:setColor(0, 1, 0, 1)
    self.display.text = string.format("%s\n%s", self.name, "Activating...")
end

function SwControl:deactivate()
    self.statusLight:setColor(1, 0, 0, 1)
    self.display.text = string.format("%s\n%s", self.name, "Deactivating...")
end

--------------------------------------------------------------------------------
-- PpControl class
local PpControl = {}
PpControl.__index = PpControl

setmetatable(PpControl, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function PpControl.new(_name, _uuid)
    local self = setmetatable({}, PpControl)
    self.name = _name
    self.comp = component.proxy(_uuid)
    self.display = self.comp:getModule(3, 1, Panel.LOWER)
    self.stop = self.comp:getModule(8, 1, Panel.LOWER)
    for i = 1, 16 do
        local swName = string.format("%s%02d", self.name, i)
        local light1 = self.comp:getModule(LIGHT_X_POS[math.ceil(i / 8)], LIGHT_Y_POS[(i + 3) % 4 + 1] + 1, 2 - math.ceil(i / 4) % 2)
        local light2 = self.comp:getModule(LIGHT_X_POS[math.ceil(i / 8)], LIGHT_Y_POS[(i + 3) % 4 + 1], 2 - math.ceil(i / 4) % 2)
        local display = self.comp:getModule(DISPLAY_X_POS[math.ceil(i / 8)], DISPLAY_Y_POS[(i + 3) % 4 + 1], 2 - math.ceil(i / 4) % 2)
        local switch = self.comp:getModule(SWITCH_X_POS[(i + 7) % 8 + 1], SWITCH_Y_POS[math.ceil(i / 8)], Panel.LOWER)
        table.insert(self, SwControl(swName, light1, light2, display, switch))
    end

    self.display.size = 100
    self.display.monospace = true
    self.display.text = string.format("   %s\n  ONLINE", self.name)
    return self
end

function PpControl:test()
    for _, v in ipairs(self) do
        v.statusLight:setColor(1, 0, 0, 1)
        v.warningLight:setColor(0, 1, 0, 1)
        v.display.size = 100
        v.display.text = "canial"
    end
end

function PpControl:reset()
    for _, v in ipairs(self) do
        v:reset()
    end
    self.display.text = string.format("   %s\n  OFFLINE", self.name)
end

--------------------------------------------------------------------------------
-- Main
local ppControl = {
    SE = PpControl("SE", component.findComponent("ppSE_Control")[1]),
    SW = PpControl("SW", component.findComponent("ppSW_Control")[1]),
    NE = PpControl("NE", component.findComponent("ppNE_Control")[1]),
    NW = PpControl("NW", component.findComponent("ppNW_Control")[1])
    -- SE = PpControl("SE", "95572F7148E13869061795B26CE32315"),
    -- SW = PpControl("SW", "3CD8DCCF43067253A0C2998312FD70B9"),
    -- NE = PpControl("NE", "D054DD914BFA4A70238B64B7E96E1821"),
    -- NW = PpControl("NW", "DCB4469443AC11295A33CA835D1D6326")
}

for _, v in pairs(ppControl) do
    v:reset()
end

for _, v in pairs(ppControl) do
    v:test()
end
