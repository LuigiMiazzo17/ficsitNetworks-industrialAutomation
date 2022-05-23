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

powerPillar.SE:add("SE01", {"SE01-C1", "SE01-C2"}, {"9A46408746C70DCC5DE2BDB7B60E5F8B", "826B7C1E4B0962103D0D2F864AECE64A"})

--------------------------------------------------------------------------------
-- Network Functions

nc = computer.getPCIDevices(findClass("NetworkCard"))[1]
protocolPort = 420
nc:open(protocolPort)
event.listen(nc)
event.clear()
requestCounter = 0

function listenNetwork()
    while true do
        e, s, sender, port, ackNumber, method, pwPil, swNumber, payload = event.pull()

        if e == "NetworkMessage" then
            requestCounter = requestCounter + 1

            print("Request counter: " .. requestCounter)
            print("Sender: " .. sender)
            print("Port: " .. port)
            print("Ack Number: " .. ackNumber)
            print("Method: " .. (method == nil and "nil" or method))
            print("powerPillar: " .. (pwPil == nil and "nil" or pwPil))
            print("swNumber: " .. (swNumber == nil and "nil" or swNumber))
            print("Payload: " .. tostring(payload == nil and "nil" or payload))

            
            ----------------------------------------------------------------------
            -- method getIfSyncted

            if method == "getState" then
                status = {}
                isSynced = true
                if powerPillar[pwPil][tonumber(swNumber)] ~= nil then 
                    for i in pairs(powerPillar[pwPil][tonumber(swNumber)]) do 
                        status[i] = powerPillar[pwPil][tonumber(swNumber)][i]:getStatus()
                    end
                    for i in pairs(powerPillar[pwPil][tonumber(swNumber)]) do 
                        if status[1] == not status[i] then
                            isSynced = false
                        end
                    end
                end
                nc:send(sender, protocolPort, ackNumber, isSynced)
            end

            ----------------------------------------------------------------------
            -- method setToAllState

            if method == "postState" then
                if powerPillar[pwPil][tonumber(swNumber)] ~= nil then 
                    for i in pairs(powerPillar[pwPil][tonumber(swNumber)]) do 
                        powerPillar[pwPil][tonumber(swNumber)][i]:setStatus(payload)
                    end
                end
                status = {}
                isSynced = true
                if powerPillar[pwPil][tonumber(swNumber)] ~= nil then 
                    for i in pairs(powerPillar[pwPil][tonumber(swNumber)]) do 
                        status[i] = powerPillar[pwPil][tonumber(swNumber)][i]:getStatus()
                    end
                    for i in pairs(powerPillar[pwPil][tonumber(swNumber)]) do 
                        if status[1] == not status[i] then
                            isSynced = false
                        end
                    end
                end
                nc:send(sender, protocolPort, ackNumber, isSynced)
                print("returned: " .. tostring(isSynced))
            end
        end
        print("-------------------------------------------------------------")
    end
end

--------------------------------------------------------------------------------
-- Main

listenNetwork()