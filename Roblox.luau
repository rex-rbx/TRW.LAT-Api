local HttpService = cloneref and cloneref(game:GetService("HttpService")) or game:GetService("HttpService") -- fallback to no cloneref if it doesnt exist
local request = request or http_request or (http and http.request) or httprequest or function(...) return HttpService:RequestAsync(...) end -- fallback (again)
local urlData = "https://trw.lat/api/lvlol/captchaLess"
local curFreeKey: string = HttpService:JSONDecode(request({Url = urlData, Method = "GET"}).Body).freeKey
assert(curFreeKey, "Expected freeKey in decoded JSON")
local function PollForResult(taskId: string, maxAttempts: number?, pollInterval: number?)
    assert(typeof(taskId) == "string", "Expected string argument 'taskId' to PollForResult, got " .. typeof(taskId))
	maxAttempts = maxAttempts or 30
    pollInterval = pollInterval or 5
    for attempt = 1, maxAttempts do
        local response = request({
            Url = `https://trw.lat/api/v2/threadcheck?id={taskId}`,
            Method = "GET",
            Headers = {
                ["x-api-key"] = curFreeKey,
                ["Content-Type"] = "application/json"
            }
        })
        if response and response.Body then
            local data = HttpService:JSONDecode(response.Body)
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
local function Bypass(Url: string)
	assert(typeof(Url) == "string", "Expected string argument 'Url' to Bypass, got " .. typeof(Url))
    local encodedUrl = HttpService:UrlEncode(Url)
    local response = request({
        Url = `https://trw.lat/api/bypass?url={encodedUrl}&mode=thread&origin=Roblox`,
        Method = "GET",
        Headers = {
			["x-api-key"] = curFreeKey,
			["Content-Type"] = "application/json"
		}
    })
    if response and response.Body then
        local data = HttpService:JSONDecode(response.Body)
        if data.success and data.status == "started" then
            return PollForResult(data.taskId)
        else
            return error("Error while attempting to bypass", 2)
        end
    end
    return error("Error while attempting to bypass", 2)
end

return Bypass
