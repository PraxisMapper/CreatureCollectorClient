--helper functions for calling PraxisMapper server endpoints.
binaryHeaders = {}
binaryHeaders["Content-Type"] = "application/octet-stream"
binaryHeaders["PraxisAuthKey"] = "testingKey" 
binaryParams = {
    headers = binaryHeaders,
    bodyType = "binary"
}

normalHeaders = {}
normalHeaders["PraxisAuthKey"] = "testingKey"
normalParams = {
    headers = normalHeaders,
}

imageHeaders = {}
imageHeaders["PraxisAuthKey"] = "testingKey" 
imageHeaders["response"]  =  {filename = ".png", baseDirectory = system.CachesDirectory}

function QueueCall(url, verb, handler, params)
    --don't requeue calls that are already in the queue
    for i =1, #networkQueue do
        if networkQueue[i].url == url and networkQueue[i].verb == verb then
            return
        end
    end

    table.insert(networkQueue, { url = url, verb = verb, handlerFunc = handler, params = params})
end