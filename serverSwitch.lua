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

-- Toggles the Switch
function Switch:toggle()
    self.comp.isSwitchOn = not self.comp.isSwitchOn
    if DEBUG then self:getStatus() end
end

-- Powers OFF a Switch
function Switch:powerOff()
    self.comp.isSwitchOn = false
    if DEBUG then self:getStatus() end
end

-- Powers ON a Switch
function Switch:powerOn()
    self.comp.isSwitchOn = true
    if DEBUG then self:getStatus() end
end

-- Prints Switch name and uuid
function Switch:print()
    print(string.format("(%s --> \'%s\' = %s)\n", self.name, self.uuid, self.prevState))
end

function Switch:setStatus(state)
    self.comp.isSwitchOn = state
    if DEBUG then self:getStatus() end
end

-- Prints Switch status
function Switch:getStatus()
    print(string.format("%s == %s", self.name, tostring(self.comp.isSwitchOn)))
    return self.comp.isSwitchOn
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
function PowerPillar:add(_name, _uuid)
    table.insert(self, Switch(_name, _uuid))
end

-- Powers ON all switches in PowerPillar
function PowerPillar:powerOnAll()
    for _, v in ipairs(self) do
        v:powerOn()
    end
end

-- Powers OFF all switches in PowerPillar
function PowerPillar:powerOffAll()
    for _, v in ipairs(self) do
        v:powerOff()
    end
end

-- Toggles all switches in PowerPillar
function PowerPillar:toggleAll()
    for _, v in ipairs(self) do
        v:toggle()
    end
end

-- Prints all switches status in PowerPillar
function PowerPillar:getStatusAll()
    for _, v in ipairs(self) do
        v:getStatus()
    end
end

-- Prints PowerPillar Switches name and id
function PowerPillar:print()
    print(string.format("PowerPillar %s:\n", self.name))
    if not table.containsType(self, "table") then
        print(" - Empty PowerPillar!\n")
    else
        for _, v in ipairs(self) do
            print(" - ")
            v:print()
        end
    end
end

--------------------------------------------------------------------------------
-- Init PowerPillars

powerPillar = {
    SE = PowerPillar("SE"),
    SW = PowerPillar("SW"),
    NE = PowerPillar("NE"),
    NW = PowerPillar("NW")
}

powerPillar.SE:add("SE01", "6DD8B54B4546B877BFB2DBB46170F7C3")
powerPillar.SE:add("SE02", "2B1FEE0444BDACC35AB2E895D8B1D2BD")
powerPillar.SE:add("SE03", "6173426C4712B04987A7498C2F823BFA")
powerPillar.SE:add("SE04", "8D20CD9945FC16A39E0B668794CD100B")

powerPillar.SE:add("SE05", "87CB2D1D4B5FBA48653E3D9FC6849117")
powerPillar.SE:add("SE06", "9CCCD18A45517F4F354C88B9D313327D")
powerPillar.SE:add("SE07", "C56A229D4CB596971CF50289A019DA65")
powerPillar.SE:add("SE08", "409868484E459CDC3015A2BA6A3F1B40")

powerPillar.SE:add("SE09", "8D01574748260F83200436A311A97A61")
powerPillar.SE:add("SE10", "479A78D34BF2D46E559A1FAC0C689E3B")
powerPillar.SE:add("SE11", "472227D8468F5F3B41D52A9803098FBB")
powerPillar.SE:add("SE12", "772B255B44DCFFF5D4D2FCA4C27AB715")

powerPillar.SE:add("SE13", "A5007D044908305C5BF50A9FDC1E382C")
powerPillar.SE:add("SE14", "C70FC6C14861C9D9D9837FAF4DAB86F9")
powerPillar.SE:add("SE15", "C880CA03494F4B2620CCB68683246E9D")
powerPillar.SE:add("SE16", "A6C9E8F94825FC61AFBE37A34CBF581A")

--------------------------------------------------------------------------------
-- Network Functions

nc = computer.getPCIDevices(findClass("NetworkCard"))[1]
nc:open(420)
event.listen(nc)

function listenNetwork()
    while true do
        e, s, sender, port, method, pwPil, swNumber, payload = event.pull()

  if e == "NetworkMessage" then
    print("Sender: " .. sender)
    print("Port: " .. port)
    print("Method: " .. (method == nil and "nil" or method))
    print("powerPillar: " .. (pwPil == nil and "nil" or pwPil))
    print("swNumber: " .. (swNumber == nil and "nil" or swNumber))
    print("Payload: " .. tostring(payload == nil and "nil" or payload))
    if method == "getState" then
      status = powerPillar[pwPil][tonumber(swNumber)]:getStatus()
      nc:send(sender, 420, status)
    end
    if method == "setState" then
      powerPillar[pwPil][tonumber(swNumber)]:setStatus(payload)
      nc:send(sender, 420, status)
    end
  end
end
