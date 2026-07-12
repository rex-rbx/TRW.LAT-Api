const HttpService = cloneref and cloneref(game:GetService("HttpService")) or game:GetService("HttpService") -- fallback to no cloneref if it doesnt exist
const request = request or http_request or (http and http.request) or httprequest or function(...) return HttpService:RequestAsync(...) end -- fallback (again)
const urlData = "https://trw.lat/api/lvlol/captchaLess"
const curFreeKey: string = HttpService:JSONDecode(request({Url = urlData, Method = "GET"}).Body).freeKey
assert(curFreeKey, "Expected freeKey in decoded JSON")
const function Bypass(Url: string)
	assert(typeof(Url) == "string", "Expected string argument 'Url' to Bypass, got " .. typeof(Url))
    const encodedUrl = HttpService:UrlEncode(Url)
    const response = request({
        Url = `https://trw.lat/api/bypass?url={encodedUrl}&origin=Roblox`,
        Method = "GET",
        Headers = {
			["x-api-key"] = curFreeKey,
			["Content-Type"] = "application/json"
		}
    })
    if response and response.Body then
        const data = HttpService:JSONDecode(response.Body)
        if data.success and data.result then
			return data.result
		else
            return error("Error while attempting to bypass", 2)
        end
    end
    return error("Error while attempting to bypass", 2)
end
return Bypass
