require("PraxisMapper")

currentNetStatus = 'down'
netCallCount = 0
networkQueueBusy = false
networkQueue = {}

function PostQueueCall(event)
    if NetCallCheck(event.status) then
        NetUp()
    else
        NetDown()
    end

    if netCallCount <= simultaneousNetCalls then
        NextNetworkQueue()
    end
end


function NetUp()
    currentNetStatus = 'up'
    networkQueueBusy = false
    netCallCount = netCallCount - 1
    if #networkQueue > 0 then
        return
    end
end

function NetDown(event)
    currentNetStatus = 'down'
    netCallCount = netCallCount - 1
    networkQueueBusy = false
    if #networkQueue > 0 then
        return
    end
end

function NetTransfer()
    currentNetStatus = 'open'
    netCallCount = netCallCount + 1
end

function DefaultNetCallHandler(event)
    if NetCallCheck(event.status) then
        NetDown(event)
    else
        NetUp()
    end
end

function NetQueueCheck()
    if #networkQueue > 0 and networkQueueBusy == false then
        NextNetworkQueue()
    end
end

function NextNetworkQueue()
    while netCallCount <= simultaneousNetCalls do
        currentNetStatus = 'open'
        networkQueueBusy = true
        netData = networkQueue[1]
        if netData == nil then return end
        network.request(netData.url, netData.verb, netData.handlerFunc, netData.params)
        table.remove(networkQueue, 1)
        netCallCount = netCallCount + 1
    end
end

function NetCallCheck(status) -- returns true if the call is good, returns false if the network call should be handled like an error.
    if status == 419 or status == -1 then
        print('auth timeout or connection failure, reauthing')
        ReAuth()
        currentNetStatus = 'down'
        return false
    end

    if status < 200 or status > 206 then
        currentNetStatus = 'down'
        return false
    end

    return true
end