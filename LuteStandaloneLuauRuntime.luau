const function urlencode(url)
	return url:gsub("\n", "\r\n"):gsub("([^%w _%%%-%.~])", function(c)
		return string.format("%%%02X", string.byte(c))
	end):gsub(" ", "+")
end
const NetClient = require("@lute/net/client")
const JSON = require("@std/json")
const urlData = "https://trw.lat/api/lvlol/captchaLess"
const curFreeKey: string = JSON.deserialize(NetClient.request(urlData, {Method = "GET"}).Body).freeKey
assert(curFreeKey, "Expected freeKey in decoded JSON")
const function PollForResult(taskId: string, maxAttempts: number?, pollInterval: number?)
    assert(typeof(taskId) == "string", "Expected string argument 'taskId' to PollForResult, got " .. typeof(taskId))
	maxAttempts = maxAttempts or 30
    pollInterval = pollInterval or 5
    for attempt = 1, maxAttempts do
        const response = NetClient.request(`https://trw.lat/api/v2/threadcheck?id={taskId}`, {
            Method = "GET",
            Headers = {
                ["x-api-key"] = curFreeKey,
                ["Content-Type"] = "application/json"
            }
        })
        if response and response.Body then
            const data = JSON.deserialize(response.Body)
            if data.status == "success" then
                if data.success then
                    return data.result
                else
                    return error("Error while attempting to bypass", 2)
                end
            elseif data.status == "started" or data.status == "processing" then
                task.wait(pollInterval)
            else
                return error("Error while attempting to bypass", 2)
            end
        else
            task.wait(pollInterval)
        end
    end
    return error("Error while attempting to bypass", 2)
end
const function Bypass(Url: string)
	assert(typeof(Url) == "string", "Expected string argument 'Url' to Bypass, got " .. typeof(Url))
    const encodedUrl = urlencode(Url)
    const response = NetClient.request(`https://trw.lat/api/bypass?url={encodedUrl}&mode=thread&origin=Roblox`, {
        Method = "GET",
        Headers = {
			["x-api-key"] = curFreeKey,
			["Content-Type"] = "application/json"
		}
    })
    if response and response.Body then
        const data = JSON.deserialize(response.Body)
        if data.success and data.status == "started" then
            return PollForResult(data.taskId)
        else
            return error("Error while attempting to bypass", 2)
        end
    end
    return error("Error while attempting to bypass", 2)
end

return Bypass
