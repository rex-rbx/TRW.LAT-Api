const axios = require('axios');
class FEARBypass {
    constructor() {
        this.baseURL = 'https://trw.lat/api';
        this.freeKey = null;
        this.cache = new Map();
        this.lastKeyFetch = 0;
        this.keyCacheDuration = 300000;
    }
    async getFreeKey() {
        const now = Date.now();
        if (this.freeKey && (now - this.lastKeyFetch) < this.keyCacheDuration) {
            return this.freeKey;
        }
        try {
            const response = await axios.get(`${this.baseURL}/lvlol/captchaLess`);
            if (response.data && response.data.freeKey) {
                this.freeKey = response.data.freeKey;
                this.lastKeyFetch = now;
                return this.freeKey;
            } else {
                throw new Error('Failed to get free key: Invalid response');
            }
        } catch (error) {
            throw new Error(`Failed to fetch free key: ${error.message}`);
        }
    }
    async pollForResult(taskId, freeKey, maxAttempts = 30, pollInterval = 5000) {
        for (let attempt = 1; attempt <= maxAttempts; attempt++) {
            try {
                const response = await axios.get(`${this.baseURL}/v2/threadcheck`, {
                    params: { id: taskId },
                    headers: {
                        'x-api-key': freeKey,
                        'Content-Type': 'application/json'
                    }
                });
                const data = response.data;
                if (data.status === 'success') {
                    if (data.success) {
                        return data.result;
                    } else {
                        throw new Error(`Thread failed: ${data.result}`);
                    }
                } else if (data.status === 'started' || data.status === 'processing') {
                    await this.sleep(pollInterval);
                } else {
                    throw new Error(`Unknown thread status: ${data.status}`);
                }
            } catch (error) {
                if (attempt < maxAttempts) {
                    console.warn(`[F.E.A.R] Poll attempt ${attempt} failed, retrying...`, error.message);
                    await this.sleep(pollInterval);
                } else {
                    throw new Error(`Polling timed out after ${maxAttempts} attempts: ${error.message}`);
                }
            }
        }
        throw new Error(`Thread timed out after ${maxAttempts * pollInterval}ms`);
    }
    sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
    async Bypass(url, options = {}) {
        const {
            origin = 'NotApplicable',
            maxAttempts = 30,
            pollInterval = 5000,
            refresh = false
        } = options;
        if (!refresh && this.cache.has(url)) {
            const cached = this.cache.get(url);
            if (cached && cached.timestamp && (Date.now() - cached.timestamp) < 3600000) {
                return cached.result;
            }
        }
        const freeKey = await this.getFreeKey();
        if (!freeKey) {
            throw new Error('Failed to get free key');
        }
        const encodedUrl = encodeURIComponent(url);
        const bypassUrl = `${this.baseURL}/bypass`;
        try {
            const response = await axios.get(bypassUrl, {
                params: {
                    url: encodedUrl,
                    mode: 'thread',
                    origin: origin
                },
                headers: {
                    'x-api-key': freeKey,
                    'Content-Type': 'application/json'
                }
            });
            const data = response.data;
            if (data.success && data.status === 'started') {
                const result = await this.pollForResult(data.task_id, freeKey, maxAttempts, pollInterval);
                this.cache.set(url, {
                    result: result,
                    timestamp: Date.now()
                });
                return result;
            } else {
                throw new Error(`Thread start failed: ${JSON.stringify(data)}`);
            }
        } catch (error) {
            if (error.response) {
                throw new Error(`API error: ${error.response.status} - ${error.response.data}`);
            } else {
                throw new Error(`Request failed: ${error.message}`);
            }
        }
    }
    async BypassSync(url, options = {}) {
        const {
            origin = 'NotApplicable',
            timeout = 90000, // 90 seconds
            refresh = false
        } = options;
        if (!refresh && this.cache.has(url)) {
            const cached = this.cache.get(url);
            if (cached && cached.timestamp && (Date.now() - cached.timestamp) < 3600000) {
                return cached.result;
            }
        }
        const freeKey = await this.getFreeKey();
        if (!freeKey) {
            throw new Error('Failed to get free key');
        }
        const encodedUrl = encodeURIComponent(url);
        const bypassUrl = `${this.baseURL}/bypass`;
        try {
            const response = await axios.get(bypassUrl, {
                params: {
                    url: encodedUrl,
                    mode: 'normal',
                    origin: origin
                },
                headers: {
                    'x-api-key': freeKey,
                    'Content-Type': 'application/json'
                },
                timeout: timeout
            });
            const data = response.data;
            if (data.success) {
                this.cache.set(url, {
                    result: data.result,
                    timestamp: Date.now()
                });

                return data.result;
            } else {
                throw new Error(`Bypass failed: ${data.result}`);
            }
        } catch (error) {
            if (error.code === 'ECONNABORTED') {
                throw new Error(`Bypass timed out after ${timeout}ms`);
            } else if (error.response) {
                throw new Error(`API error: ${error.response.status} - ${error.response.data}`);
            } else {
                throw new Error(`Request failed: ${error.message}`);
            }
        }
    }
    clearCache() {
        this.cache.clear();
    }
    getCacheStats() {
        return {
            size: this.cache.size,
            keys: Array.from(this.cache.keys())
        };
    }
}
module.exports = FEARBypass;
