const HttpService = game:GetService("HttpService")
const function request(...)
    return HttpService:RequestAsync(...)
end
const urlData = "https://trw.lat/api/lvlol/captchaLess"
const curFreeKey = HttpService:JSONDecode(request({Url = urlData, Method = "GET"}).Body)
const function pollForResult(taskId, freeKey, maxAttempts, pollInterval)
    maxAttempts = maxAttempts or 30
    pollInterval = pollInterval or 5
    for attempt = 1, maxAttempts do
        const response = request({
            Url = `https://trw.lat/api/v2/threadcheck?id={taskId}`,
            Method = "GET",
            Headers = {
                ["x-api-key"] = curFreeKey,
                ["Content-Type"] = "application/json"
            }
        })
        if response and response.Body then
            const data = HttpService:JSONDecode(response.Body)
            if data.status == "success" then
                if data.success then
                    return data.result
                else
                    return nil
                end
            elseif data.status == "started" or data.status == "processing" then
                task.wait(pollInterval)
            else
                return nil
            end
        else
            task.wait(pollInterval)
        end
    end
    return nil
end
const function Bypass(Url)
    const encodedUrl = HttpService:UrlEncode(Url)
    const response = request({
        Url = `https://trw.lat/api/bypass?url={encodedUrl}&mode=thread&origin=RobloxGameEngine`,
        Method = "GET",
        Headers = {
			["x-api-key"] = curFreeKey,
			["Content-Type"] = "application/json"
		}
    })
    if response and response.Body then
        const data = HttpService:JSONDecode(response.Body)
        if data.success and data.status == "started" then
            return pollForResult(data.taskId, freeKey)
        else
            return nil
        end
    end
    return nil
end
return Bypass
