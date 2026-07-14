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
const function Bypass(Url: string, Origin: string?)
	assert(typeof(Url) == "string", "Expected string argument 'Url' to Bypass, got " .. typeof(Url))
    const encodedUrl = urlencode(Url)
    const response = NetClient.request(`https://trw.lat/api/bypass?url={encodedUrl}&origin={Origin or "Lute"}`, {
        Method = "GET",
        Headers = {
			["x-api-key"] = curFreeKey,
			["Content-Type"] = "application/json"
		}
    })
    if response and response.Body then
        const data = JSON.deserialize(response.Body)
        if data.success then
            return data.result
        else
            return error("Error while attempting to bypass", 2)
        end
    end
    return error("Error while attempting to bypass", 2)
end
return Bypass
