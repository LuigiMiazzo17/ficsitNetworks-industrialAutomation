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
-- L: State light
-- l: Warning light
-- D: Text display
-- S: Switch
-- s: Stop

--------------------------------------------------------------------------------
-- Network functions

local nc = computer.getPCIDevices(findClass("NetworkCard"))[1]
requestNumber = 0

function getRequest(_uuid, _port, _name, _verbose)
    _verbose = _verbose or false
    requestNumber = requestNumber + 1
    if _uuid == "" then return nil end
    local powPil = string.sub(_name, 1, 2)
    local nSw = string.sub(_name, 3)
    nc:send(_uuid, _port, requestNumber, "getState", powPil, tonumber(nSw))
    nc:open(_port)
    event.listen(nc)

    while true do
        local e, _, _, _, ackNumber, gotState = event.pull(0.5)
        if (e == "NetworkMessage") and (ackNumber == requestNumber) then
            if _verbose == true then
                print("State of " .. powPil .. nSw .. ": " .. tostring(gotState))
            end
            nc:close(_port)
            event.ignore(nc)
            return gotState
        elseif e == nil then
            print("Connection timeout on switch: " .. _name)
            nc:open(_port)
            event.listen(nc)
            return nil
        end
    end
end

function postRequest(_uuid, _port, _name, _newState, _verbose)
    _verbose = _verbose or false
    requestNumber = requestNumber + 1
    if _uuid == "" then return nil end
    local powPil = string.sub(_name, 1, 2)
    local nSw = string.sub(_name, 3)
    nc:send(_uuid, _port, requestNumber, "postState", powPil, tonumber(nSw), _newState)
    nc:open(_port)
    event.listen(nc)

    while true do
        local e, _, _, _, ackNumber, gotState = event.pull(0.5)
        if (e == "NetworkMessage") and (ackNumber == requestNumber) then
            if _verbose == true then
                print("Changed state of " .. powPil .. nSw .. " to: " .. tostring(gotState))
            end
            nc:close(_port)
            event.ignore(nc)
            return true

        elseif e == nil then
            print("Connection timeout on switch: " .. _name)
            nc:open(_port)
            event.listen(nc)
            return false
        end
    end
end

--------------------------------------------------------------------------------
-- Const and Enums

local LIGHT_X_POS = { 0, 10 }
local LIGHT_Y_POS = { 9, 6, 3, 0 }
local DISPLAY_X_POS = { 1, 6 }
local DISPLAY_Y_POS = { 9, 6, 3, 0 }
local SWITCH_X_POS = { 1, 2, 3, 4, 6, 7, 8, 9 }
local SWITCH_Y_POS = { 8, 5 }

local SWITCHSERVERUUID = "129FA16E4CA48675504AEDAF6259570A"
local EXTSERVERUUID = "7B4F99D74D13681D02632EBD0B443D9F"
local PORT = 420

local Panel = { UPPER = 2, CENTER = 1, LOWER = 0 }

--------------------------------------------------------------------------------
-- Helper functions

local name = {}

function name.encode(powPil, nSw)
    return powPil .. tostring(nSw)
end

function name.decode(_name)
    local powPil = string.sub(_name, 1, 2)
    local nSw = tonumber(string.sub(_name, 3))
    return powPil, nSw
end

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
    self.stateLight = _light1
    self.warningLight = _light2
    self.display = _display
    self.switch = _switch

    self.display.size = 60
    self.display.monospace = true
    self:setState("ControlPanel")
    event.listen(self.switch)
    return self
end

-- can be called without state if source is "ControlPanel"
function SwControl:setState(source, state)
    if state == nil then
        if source == "ControlPanel" then
            state = self.switch.state
        elseif source == "StopButton" then
            state = false
        else
            return false
        end
    end

    if state then
        self.stateLight:setColor(0, 1, 0, 0.01)
        self.display.text = string.format("%s\n%s", self.name, "ONLINE")
    else
        self.stateLight:setColor(1, 0, 0, 0.01)
        self.display.text = string.format("%s\n%s", self.name, "OFFLINE")
    end

    if source == "ControlPanel" then
        self.warningLight:setColor(0, 1, 1, 0.01)
        local PPState = postRequest(SWITCHSERVERUUID, PORT, self.name, state) -- to PowerPillar
        local outState = postRequest(EXTSERVERUUID, PORT, self.name, state) -- to Offsite
        if (PPState ~= true) then
            self.stateLight:setColor(1, 1, 0, 0.01)
        end
        if (outState ~= true) then
            self.warningLight:setColor(1, 1, 0, 0.01)
        end

    elseif source == "PowerPillar" then
        self.warningLight:setColor(0, 1, 1, 0.01)
        event.ignore(self.switch)
        self.switch.state = state
        event.listen(self.switch)

        local outState = postRequest(EXTSERVERUUID, PORT, self.name, state) -- to Offsite
        if (outState ~= true) then
            self.warningLight:setColor(1, 1, 0, 0.01)
        end

    elseif source == "StopButton" then
        event.ignore(self.switch)
        self.switch.state = state
        event.listen(self.switch)
        self.warningLight:setColor(0, 1, 1, 0.01)
        local PPState = postRequest(SWITCHSERVERUUID, PORT, self.name, state) -- to PowerPillar
        local outState = postRequest(EXTSERVERUUID, PORT, self.name, state) -- to Offsite
        if (PPState ~= true) then
            self.stateLight:setColor(1, 1, 0, 0.01)
        end
        if (outState ~= true) then
            self.warningLight:setColor(1, 1, 0, 0.01)
        end

    else -- source == "Offsite"
        self.warningLight:setColor(1, 0, 1, 0.01)
        self.switch.state = state
        postRequest(SWITCHSERVERUUID, PORT, self.name, state) -- to PowerPillar
    end
    return true
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
    event.listen(self.stop)
    for i = 1, 16 do
        local swName = string.format("%s%02d", self.name, i)
        local light1 = self.comp:getModule(LIGHT_X_POS[math.ceil(i / 8)], LIGHT_Y_POS[(i + 3) % 4 + 1] + 1, 2 - (math.ceil(i / 4) + 1) % 2)
        local light2 = self.comp:getModule(LIGHT_X_POS[math.ceil(i / 8)], LIGHT_Y_POS[(i + 3) % 4 + 1], 2 - (math.ceil(i / 4) + 1) % 2)
        local display = self.comp:getModule(DISPLAY_X_POS[math.ceil(i / 8)], DISPLAY_Y_POS[(i + 3) % 4 + 1], 2 - (math.ceil(i / 4) + 1) % 2)
        local switch = self.comp:getModule(SWITCH_X_POS[(i + 7) % 8 + 1], SWITCH_Y_POS[math.ceil(i / 8)], Panel.LOWER)
        table.insert(self, SwControl(swName, light1, light2, display, switch))
    end

    self.display.size = 100
    self.display.monospace = true
    self.display.text = string.format("   %s\n  ONLINE", self.name)
    return self
end

function PpControl:stopEvent()
    for _, v in ipairs(self) do
        v:setState("StopButton")
    end
end

--------------------------------------------------------------------------------
-- Main

local function main()
    print("Initializing...")
    local ppControl = {
        SE = PpControl("SE", component.findComponent("ppSE_Control")[1]),
        SW = PpControl("SW", component.findComponent("ppSW_Control")[1]),
        NE = PpControl("NE", component.findComponent("ppNE_Control")[1]),
        NW = PpControl("NW", component.findComponent("ppNW_Control")[1])
    }
    event.clear()
    print("Initialized!")

    -- Event loop
    while true do
        local eventData = { event.pull(0.5) }
        local eventType = eventData[1]

        if eventType == "ChangeState" then
            local eventSwitch = eventData[2]
            local eventState = eventData[3]
            for _, pp in pairs(ppControl) do
                for _, sw in ipairs(pp) do
                    if sw.switch == eventSwitch then
                        sw:setState("ControlPanel", eventState)
                    end
                end
            end
        end

        if eventType == "Trigger" then
            local eventButton = eventData[2]
            for _, pp in pairs(ppControl) do
                if eventButton == pp.stop then
                    pp:stopEvent()
                end
            end
            event.clear()
        end
        
        if eventType == nil then
            for _, pp in pairs(ppControl) do
                for _, sw in ipairs(pp) do
                    local eventState = getRequest(SWITCHSERVERUUID, PORT, sw.name)
                    if sw.switch.state ~= eventState then
                        sw:setState("PowerPillar", eventState)
                    end
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
main()
