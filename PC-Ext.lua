--------------------------------------------------------------------------------
-- Helper functions
DEBUG = true

function table.containsType(table, elementType)
    for _, value in pairs(table) do
        if type(value) == elementType then
            return true
        end
    end
    return false
end

--------------------------------------------------------------------------------
-- Switch class

local Switch = {}
Switch.__index = Switch

setmetatable(Switch, {
    __call = function (cls, ...)
    return cls.new(...)
end,
})

function Switch.new(_name, _uuid)
    local self = setmetatable({}, Switch)
    self.name = _name
    self.uuid = _uuid
    self.comp = component.proxy(_uuid)
    self.prevState = self.comp.isSwitchOn
    return self
end

-- Prints Switch status
function Switch:getStatus()
    print(string.format("%s == %s", self.name, tostring(self.comp.isSwitchOn)))
    return self.comp.isSwitchOn
end

function Switch:setStatus(state)
    self.comp.isSwitchOn = state
end

--------------------------------------------------------------------------------
-- PowerPillar class

local PowerPillar = {}
PowerPillar.__index = PowerPillar

setmetatable(PowerPillar, {
    __call = function (cls, ...)
    return cls.new(...)
end,
})

function PowerPillar.new(_name)
    local self = setmetatable({}, PowerPillar)
    self.name = _name
    return self
end

-- Add Switch to the PowerPillar
function PowerPillar:add(_name, _childrenNames, _childrenUuid)
    local tempTable = setmetatable({}, TempTable)

    for i in pairs(_childrenNames) do 
        table.insert(tempTable, Switch(_childrenNames[i], _childrenUuid[i]))
    end

    table.insert(self, tempTable)
end

function Switch:getStatus()
    print(string.format("%s == %s", self.name, tostring(self.comp.isSwitchOn)))
    return self.comp.isSwitchOn
end
--------------------------------------------------------------------------------
-- Init PowerPillars


powerPillar = {
    SE = PowerPillar("SE"),
    SW = PowerPillar("SW"),
    NE = PowerPillar("NE"),
    NW = PowerPillar("NW")
}

--SE

powerPillar.SE:add("SE01", {"SE01-C1", "SE01-C2"}, {"D34428BE4E81604B60655CB20C845B13", "638661B64AFAAFD4A764D4A266DE93C5"})

--------------------------------------------------------------------------------
-- Network Functions

nc = computer.getPCIDevices(findClass("NetworkCard"))[1]
protocolPort = 420
nc:open(protocolPort)
event.listen(nc)
requestCounter = 0

function listenNetwork()
    while true do
        e, s, sender, port, method, pwPil, swNumber, payload = event.pull()

        if e == "NetworkMessage" then
            requestCounter = requestCounter + 1

            print("RequestCounter: " .. requestCounter)
            print("Sender: " .. sender)
            print("Port: " .. port)
            print("Method: " .. (method == nil and "nil" or method))
            print("powerPillar: " .. (pwPil == nil and "nil" or pwPil))
            print("swNumber: " .. (swNumber == nil and "nil" or swNumber))
            print("Payload: " .. tostring(payload == nil and "nil" or payload))
            print("-------------------------------------------------------------")
            
            ----------------------------------------------------------------------
            -- method getIfSyncted

            if method == "getIfSyncted" then
                status = {}
                isSynced = true
                for i in pairs(powerPillar[pwPil][tonumber(swNumber)]) do 
                    status[i] = powerPillar[pwPil][tonumber(swNumber)][i]:getStatus()
                end
                for i in pairs(powerPillar[pwPil][tonumber(swNumber)]) do 
                    if status[1] == not status[i] then
                        isSynced = false
                    end
                end
                nc:send(sender, protocolPort, isSynced, status[1])
            end

            ----------------------------------------------------------------------
            -- method setToAllState

            if method == "setToAllState" then
                for i in pairs(powerPillar[pwPil][tonumber(swNumber)]) do 
                    powerPillar[pwPil][tonumber(swNumber)][i]:setStatus(payload)
                end
                nc:send(sender, protocolPort, status)
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Main

listenNetwork()