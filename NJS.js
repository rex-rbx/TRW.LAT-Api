module.exports = ((Url, Origin) => {
    if (typeof Url !== 'string') {
        throw new Error(`Expected string argument 'Url' to Bypass, got ${typeof Url}`);
    }
    let curFreeKey = null;
    return fetch('https://trw.lat/api/lvlol/captchaLess')
        .then(function(response) {
            return response.json();
        })
        .then(function(freeKeyData) {
            curFreeKey = freeKeyData.freeKey;
            
            if (!curFreeKey) {
                throw new Error("Expected freeKey in decoded JSON");
            }
            
            const encodedUrl = encodeURIComponent(Url);
            return fetch(`https://trw.lat/api/bypass?url=${encodedUrl}&origin=${Origin || "NotApplicable"}`, {
                headers: {
                    'x-api-key': curFreeKey,
                    'Content-Type': 'application/json'
                }
            });
        })
        .then(function(response) {
            return response.json();
        })
        .then(function(data) {
            if (data.success && data.result) {
                return data.result;
            } else {
                throw new Error("Error while attempting to bypass");
            }
        })
        .catch(function(error) {
            throw new Error(`Error while attempting to bypass: ${error.message}`);
        });
})
