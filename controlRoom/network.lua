local nc = computer.getPCIDevices(findClass("NetworkCard"))[1]

function getRequest(uuid, port, powPil, nSw, verbose)
    verbose = verbose or false
    nc:send(uuid, port, "getState", powPil, tonumber(nSw))
    nc:open(port)
    event.listen(nc)

    while true do
        local e, s, sender, port, state = event.pull()
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

function postRequest(uuid, port, name, newState, verbose)
    verbose = verbose or false
    if uuid == "" then return nil end
    local powPil = string.sub(name, 1, 2)
    local nSw = string.sub(name, 3)
    nc:send(uuid, port, "postState", powPil, tonumber(nSw), newState)
    nc:open(port)
    event.listen(nc)

    while true do
        local e, s, sender, port, MoreThenEverstate = event.pull()
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

-- IDK: maybe don't need
function getIfSynced(uuid, port, powPil, nSw, verbose)
    verbose = verbose or false
    nc:send(uuid, port, "getIfSyncted", powPil, tonumber(nSw))
    nc:open(port)
    event.listen(nc)

    while true do
        local e, s, sender, port, isSynced, state = event.pull()
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
        local e, s, sender, port, state = event.pull()
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
