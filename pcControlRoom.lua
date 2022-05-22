local LIGHT_X_POS = { 0, 10 }
local LIGHT_Y_POS = { 9, 6, 3, 0 }
local DISPLAY_X_POS = { 1, 6 }
local DISPLAY_Y_POS = { 9, 6, 3, 0 }
local SWITCH_X_POS = { 1, 2, 3, 4, 6, 7, 8, 9 }
local SWITCH_Y_POS = { 8, 5 }

local Panel = { UPPER = 2, CENTER = 1, LOWER = 0 }

--------------------------------------------------------------------------------
-- Network functions

local nc = computer.getPCIDevices(findClass("NetworkCard"))[1]

function getRequest(uuid, port, powPil, nSw, verbose)
    verbose = verbose or false
    nc:send(uuid, port, "getState", powPil, tonumber(nSw))
    nc:open(port)
    event.listen(nc)

    while true do
        e, s, sender, port, state = event.pull()
        if e == "NetworkMessage" then
            if verbose == true then
                print("State of " .. powPil .. nSw .. ": " .. tostring(state))
            end
            nc:close(port)
            event.ignore(nc)
            return state
        end
    end
end

function setRequest(uuid, port, powPil, nSw, newState, verbose)
    verbose = verbose or false
    nc:send(uuid, port, "postState", powPil, tonumber(nSw), newState)
    nc:open(port)
    event.listen(nc)

    while true do
        e, s, sender, port, MoreThenEverstate = event.pull()
        if e == "NetworkMessage" then
            if verbose == true then
                print("Changed state of " .. powPil .. nSw .. " to: " .. tostring(newState))
            end
            nc:close(port)
            event.ignore(nc)
            return MoreThenEverstate
        end
    end
end

function getIfSynced(uuid, port, powPil, nSw, verbose)
    verbose = verbose or false
    nc:send(uuid, port, "getIfSyncted", powPil, tonumber(nSw))
    nc:open(port)
    event.listen(nc)

    while true do
        e, s, sender, port, isSynced, state = event.pull()
        if e == "NetworkMessage" then
            if verbose == true then
                if isSynced == true then
                    print("Sync of " .. powPil .. nSw .. ": " .. tostring(isSynced) .. " and with state: " .. tostring(state))
                else
                    print("Sync of " .. powPil .. nSw .. ": " .. tostring(isSynced))
                end
            end
            nc:close(port)
            event.ignore(nc)
            return state
        end
    end
end

function setToAllStateRequest(uuid, port, powPil, nSw, newState, verbose)
    verbose = verbose or false
    nc:send(uuid, port, "setToAllState", powPil, tonumber(nSw), newState)
    nc:open(port)
    event.listen(nc)

    while true do
        e, s, sender, port, state = event.pull(5)
        if e == "NetworkMessage" then
            if verbose == true then
                print("Changed state of " .. powPil .. nSw .. " to: " .. tostring(newState))
            end
            nc:close(port)
            event.ignore(nc)
            return state
        end
    end
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
    self.statusLight = _light1
    self.warningLight = _light2
    self.display = _display
    self.switch = _switch
    return self
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
        event.listen(switch)
        table.insert(self, SwControl(swName, light1, light2, display, switch))
    end
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
        v.statusLight:setColor(0, 0, 0, 0)
        v.warningLight:setColor(0, 0, 0, 0)
        v.display.text = ""
    end
end

function PpControl:init()
    for _, v in ipairs(self) do
        
        stringNumber = string.sub(v.name, 3)

        local state = getRequest("129FA16E4CA48675504AEDAF6259570A", 420, self.name, stringNumber)
        
        local syncState = getIfSynced("7B4F99D74D13681D02632EBD0B443D9F", 420, self.name, stringNumber)

        if state == true then
            v.statusLight:setColor(0, 1, 0, 0.01)
            v.switch.state = true
        else
            v.statusLight:setColor(1, 0, 0, 0.01)
            v.switch.state = false
        end

        if syncState == true then
            v.warningLight:setColor(0, 1, 1, 0.01)
        else
            v.warningLight:setColor(1, 1, 0, 0.01)
        end
        
        v.display.text = self.name .. stringNumber
    end
end
--------------------------------------------------------------------------------
-- Main

local ppControl = {
    -- SE = PpControl("SE", component.findComponent("PowerPillarSE_Control")),
    -- SW = PpControl("SW", component.findComponent("PowerPillarSW_Control")),
    -- NE = PpControl("NE", component.findComponent("PowerPillarNE_Control")),
    -- NW = PpControl("NW", component.findComponent("PowerPillarNW_Control"))
    SE = PpControl("SE", "95572F7148E13869061795B26CE32315"),
    SW = PpControl("SW", "3CD8DCCF43067253A0C2998312FD70B9"),
    NE = PpControl("NE", "D054DD914BFA4A70238B64B7E96E1821"),
    NW = PpControl("NW", "DCB4469443AC11295A33CA835D1D6326")

}

for _, v in pairs(ppControl) do
    v:reset()
end

ppControl.SE:init()
ppControl.SW:init()
ppControl.NE:init()
ppControl.NW:init()

event.clear()

function changeState(v, powPil, state)
    
    stringNumber = string.sub(v.name, 3)

    local newState = setRequest("129FA16E4CA48675504AEDAF6259570A", 420, powPil.name, stringNumber, state)
    print("new state for ".. v.name .. " with value = " .. tostring(newState))
    local syncState = setToAllStateRequest("7B4F99D74D13681D02632EBD0B443D9F", 420, powPil.name, stringNumber, state)

    if newState == true then
        v.statusLight:setColor(0, 1, 0, 0.01)
    else
        v.statusLight:setColor(1, 0, 0, 0.01)
    end

    if syncState == true then
        v.warningLight:setColor(0, 1, 1, 0.01)
    else
        v.warningLight:setColor(1, 1, 0, 0.01)
    end

end

while true do
    e, s, state = event.pull()

    if e == "ChangeState" then
        for _, v in pairs(ppControl.SE) do
            if s == v.switch then
                changeState(v, ppControl.SE, state)
            end
        end

        for _, v in pairs(ppControl.SW) do
            if s == v.switch then
                changeState(v, ppControl.SW, state)
            end
        end

        for _, v in pairs(ppControl.NE) do
            if s == v.switch then
                changeState(v, ppControl.NE, state)
            end
        end

        for _, v in pairs(ppControl.NW) do
            if s == v.switch then
                changeState(v, ppControl.NW, state)
            end
        end
    end
end