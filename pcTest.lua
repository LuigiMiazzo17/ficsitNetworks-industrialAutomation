nc = computer.getPCIDevices(findClass("NetworkCard"))[1]

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
        else
            print("Timeout")
            nc:close(port)
            event.ignore(nc)
        end
    end
end

function setRequest(uuid, port, powPil, nSw, newState, verbose)
    verbose = verbose or false
    nc:send(uuid, port, "postState", powPil, tonumber(nSw), newState)
    nc:open(port)
    event.listen(nc)

    while true do
        e, s, sender, port, state = event.pull()
        if e == "NetworkMessage" then
            if verbose == true then
                print("Changed state of " .. powPil .. nSw .. " to: " .. tostring(newState))
            end
            nc:close(port)
            event.ignore(nc)
            return state
        else
            print("Timeout")
            nc:close(port)
            event.ignore(nc)
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
        else
            print("Timeout")
            nc:close(port)
            event.ignore(nc)
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
        else
            print("Timeout")
            nc:close(port)
            event.ignore(nc)
        end
    end
end


getIfSynced("567E1248414BEB35F9D1488993259820", 420, "SE", "01", true)

--getRequest("129FA16E4CA48675504AEDAF6259570A", 420, "SE", "01", true)
--setRequest("129FA16E4CA48675504AEDAF6259570A", 420, "SE", "01", true, true)
--getRequest("129FA16E4CA48675504AEDAF6259570A", 420, "SE", "01", true)