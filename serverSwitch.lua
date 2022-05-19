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

    --SEND NETWORK MESSAGE TO CHANGE ALL CHILDREN STATE

    self.prevState = not prevState
    if DEBUG then self:getStatus() end
end

-- Powers OFF a Switch
function Switch:powerOff()
    self.comp.isSwitchOn = false

    if self.prevState == true then

        --SEND NETWORK MESSAGE TO CHANGE ALL CHILDREN STATE

    end

    self.prevState = false
    if DEBUG then self:getStatus() end
end

-- Powers ON a Switch
function Switch:powerOn()
    self.comp.isSwitchOn = true

    if self.prevState == false then

        --SEND NETWORK MESSAGE TO CHANGE ALL CHILDREN STATE

    end

    self.prevState = true
    if DEBUG then self:getStatus() end
end

-- Prints Switch name and uuid
function Switch:print()
    print(string.format("(%s --> \'%s\' = %s)\n", self.name, self.uuid, self.prevState))
end

function Switch:setStatus(state)
    self.comp.isSwitchOn = state

    if self.prevState == not state then

        --SEND NETWORK MESSAGE TO CHANGE ALL CHILDREN STATE

    end

    self.prevState = state
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

--SE

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

--SW

powerPillar.SW:add("SW01", "C0D1C47A49DF591046F708881FC64A8B")
powerPillar.SW:add("SW02", "2721598A48DD4102E019B08CEB6BE59C")
powerPillar.SW:add("SW03", "7F195061460E4B79348CF59A3DAD72B1")
powerPillar.SW:add("SW04", "223C0A0C45EF586FBD372B98374E2E07")

powerPillar.SW:add("SW05", "E9293A41426D78F61E4564AA42B98272")
powerPillar.SW:add("SW06", "80E2A3C741195E5EBF56FC98F3498A49")
powerPillar.SW:add("SW07", "7EC6A985473D9E447855D68B763C39C3")
powerPillar.SW:add("SW08", "B09BB0BE4B62CDFAC2FB7797289628FD")

powerPillar.SW:add("SW09", "8B1023E14378AA101AAE19AC447ACA60")
powerPillar.SW:add("SW10", "2602FCD24C04A8BDBD6B5BA3DED2130C")
powerPillar.SW:add("SW11", "652EB1514A35C2394C057D9527301BF6")
powerPillar.SW:add("SW12", "6A7E286746F5014D7B6277B0B21DA6BA")

powerPillar.SW:add("SW13", "626D538B4DBB2C2C6BCA16AF462CF5FF")
powerPillar.SW:add("SW14", "4E270D21455D5C803A73D28341F91950")
powerPillar.SW:add("SW15", "E557DF364C316F1F778A54A425B0616B")
powerPillar.SW:add("SW16", "FE42D74649B6F9F36BF022A0B9212B38")

--NE

powerPillar.NE:add("NE01", "CB68AEFC4020E57A76E860881FEAE601")
powerPillar.NE:add("NE02", "E84BB11B43892481F1F3E19C314B9136")
powerPillar.NE:add("NE03", "19B6A5E140DEB0C0F457BFBB91DAAAEF")
powerPillar.NE:add("NE04", "04308AA741993267639A34A095DE1801")

powerPillar.NE:add("NE05", "7CCAC9CF488E09ACF4F73C9444186FF3")
powerPillar.NE:add("NE06", "C699ED9342982E341B351A9ECD97A580")
powerPillar.NE:add("NE07", "0DA12BF1479001557A04449D85D2A2CD")
powerPillar.NE:add("NE08", "61FE56C146B7F019888270961034FC21")

powerPillar.NE:add("NE09", "BA5594AF46B93A12BC1F47AD3466E1A0")
powerPillar.NE:add("NE10", "6D4126664837CD619912E8B98454AF6B")
powerPillar.NE:add("NE11", "AE8164B94180C212D5551BAD8A87973E")
powerPillar.NE:add("NE12", "BB5E00044E3444A62269E5B3079385DD")

powerPillar.NE:add("NE13", "3324BD1D491CC7C4207256B17BA8D332")
powerPillar.NE:add("NE14", "973F99DE462915E1B74D0AB7BE140811")
powerPillar.NE:add("NE15", "B622641C44399521BF22848681D95A89")
powerPillar.NE:add("NE16", "3F2C5FC94AF07EF50041C6BDF7F42B7F")

--NW

powerPillar.NW:add("NW01", "6037E036459506B453C18087F30A121E")
powerPillar.NW:add("NW02", "C957DDC74225092204879B8BF48947FB")
powerPillar.NW:add("NW03", "4997108A49F352C9E77708B81750E88B")
powerPillar.NW:add("NW04", "35DD58BB450ABEC8CCA988A86C8797EB")

powerPillar.NW:add("NW05", "142C86FC4BCF1758A72F35BEE56F4342")
powerPillar.NW:add("NW06", "4BBD728D422C432A746ED690626CC9AF")
powerPillar.NW:add("NW07", "4F9560B8458FC5DD23CB528B5DFC6D5D")
powerPillar.NW:add("NW08", "A5F63B764163C16916CDC29CD769F9D0")

powerPillar.NW:add("NW09", "10CB8716457C6538BFA2F38FEFBBC601")
powerPillar.NW:add("NW10", "34436C0843D5B8C128A3ACB3B23CC73F")
powerPillar.NW:add("NW11", "9765E35341376A98051DC3B0DE620A30")
powerPillar.NW:add("NW12", "D2508E4849E1741B970D6B95C684D009")

powerPillar.NW:add("NW13", "65B123AD4F9F390362CB5D9B3C2FB9EC")
powerPillar.NW:add("NW14", "0196E0E246C09D6522588D9583AD36D0")
powerPillar.NW:add("NW15", "4578BC3B4958745AE6DDBAB2C3A667AC")
powerPillar.NW:add("NW16", "97EAF5E540DDF4B43EB2069C430D64BF")

--------------------------------------------------------------------------------
-- Network Functions

nc = computer.getPCIDevices(findClass("NetworkCard"))[1]
protocolPort = 420
nc:open(protocolPort)
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

            ----------------------------------------------------------------------
            -- method getState

            if method == "getState" then
                status = powerPillar[pwPil][tonumber(swNumber)]:getStatus()
                nc:send(sender, protocolPort, status)
            end

            ----------------------------------------------------------------------
            -- method setState

            if method == "setState" then
                powerPillar[pwPil][tonumber(swNumber)]:setStatus(payload)
                nc:send(sender, protocolPort, powerPillar[pwPil][tonumber(swNumber)]:getStatus())
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Main Functions

listenNetwork()