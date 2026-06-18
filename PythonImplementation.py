import requests
import time
from typing import Optional, Dict, Any
from urllib.parse import quote

class FEARBypass:
    def __init__(self):
        self.base_url = "https://trw.lat/api"
        self.free_key = None
        self.cache = {}
        self.last_key_fetch = 0
        self.key_cache_duration = 300000

    def get_free_key(self) -> str:
        now = int(time.time() * 1000)
        
        if self.free_key and (now - self.last_key_fetch) < self.key_cache_duration:
            return self.free_key

        try:
            response = requests.get(f"{self.base_url}/lvlol/captchaLess")
            response.raise_for_status()
            data = response.json()
            
            if data and data.get('freeKey'):
                self.free_key = data['freeKey']
                self.last_key_fetch = now
                return self.free_key
            else:
                raise Exception("Failed to get free key: Invalid response")
        except Exception as e:
            raise Exception(f"Failed to fetch free key: {str(e)}")

    def poll_for_result(self, task_id: str, free_key: str, max_attempts: int = 30, poll_interval: int = 5000) -> str:
        for attempt in range(1, max_attempts + 1):
            try:
                response = requests.get(
                    f"{self.base_url}/v2/threadcheck",
                    params={"id": task_id},
                    headers={
                        "x-api-key": free_key,
                        "Content-Type": "application/json"
                    }
                )
                response.raise_for_status()
                data = response.json()

                if data.get('status') == 'success':
                    if data.get('success'):
                        return data['result']
                    else:
                        raise Exception(f"Thread failed: {data.get('result')}")
                elif data.get('status') in ['started', 'processing']:
                    time.sleep(poll_interval / 1000)
                else:
                    raise Exception(f"Unknown thread status: {data.get('status')}")
            except Exception as e:
                if attempt < max_attempts:
                    time.sleep(poll_interval / 1000)
                else:
                    raise Exception(f"Polling timed out after {max_attempts} attempts: {str(e)}")

        raise Exception(f"Thread timed out after {max_attempts * poll_interval}ms")

    def bypass(self, url: str, origin: str = "NotApplicable", max_attempts: int = 30, poll_interval: int = 5000, refresh: bool = False) -> str:
        if not refresh and url in self.cache:
            cached = self.cache[url]
            if cached and cached.get('timestamp') and (time.time() * 1000 - cached['timestamp']) < 3600000:
                return cached['result']

        free_key = self.get_free_key()
        if not free_key:
            raise Exception("Failed to get free key")

        encoded_url = quote(url)

        try:
            response = requests.get(
                f"{self.base_url}/bypass",
                params={
                    "url": encoded_url,
                    "mode": "thread",
                    "origin": origin
                },
                headers={
                    "x-api-key": free_key,
                    "Content-Type": "application/json"
                }
            )
            response.raise_for_status()
            data = response.json()

            if data.get('success') and data.get('status') == 'started':
                result = self.poll_for_result(data['task_id'], free_key, max_attempts, poll_interval)
                
                self.cache[url] = {
                    'result': result,
                    'timestamp': time.time() * 1000
                }
                
                return result
            else:
                raise Exception(f"Thread start failed: {data}")
        except requests.exceptions.RequestException as e:
            if hasattr(e, 'response') and e.response:
                raise Exception(f"API error: {e.response.status_code} - {e.response.text}")
            else:
                raise Exception(f"Request failed: {str(e)}")

    def bypass_sync(self, url: str, origin: str = "NotApplicable", timeout: int = 90000, refresh: bool = False) -> str:
        if not refresh and url in self.cache:
            cached = self.cache[url]
            if cached and cached.get('timestamp') and (time.time() * 1000 - cached['timestamp']) < 3600000:
                return cached['result']

        free_key = self.get_free_key()
        if not free_key:
            raise Exception("Failed to get free key")

        encoded_url = quote(url)

        try:
            response = requests.get(
                f"{self.base_url}/bypass",
                params={
                    "url": encoded_url,
                    "mode": "normal",
                    "origin": origin
                },
                headers={
                    "x-api-key": free_key,
                    "Content-Type": "application/json"
                },
                timeout=timeout / 1000
            )
            response.raise_for_status()
            data = response.json()

            if data.get('success'):
                self.cache[url] = {
                    'result': data['result'],
                    'timestamp': time.time() * 1000
                }
                return data['result']
            else:
                raise Exception(f"Bypass failed: {data.get('result')}")
        except requests.exceptions.Timeout:
            raise Exception(f"Bypass timed out after {timeout}ms")
        except requests.exceptions.RequestException as e:
            if hasattr(e, 'response') and e.response:
                raise Exception(f"API error: {e.response.status_code} - {e.response.text}")
            else:
                raise Exception(f"Request failed: {str(e)}")

    def clear_cache(self):
        self.cache.clear()

    def get_cache_stats(self) -> Dict[str, Any]:
        return {
            'size': len(self.cache),
            'keys': list(self.cache.keys())
        }

default_bypass = FEARBypass()

def bypass(url: str, origin: str = "NotApplicable", max_attempts: int = 30, poll_interval: int = 5000, refresh: bool = False) -> str:
    return default_bypass.bypass(url, origin, max_attempts, poll_interval, refresh)

def bypass_sync(url: str, origin: str = "NotApplicable", timeout: int = 90000, refresh: bool = False) -> str:
    return default_bypass.bypass_sync(url, origin, timeout, refresh)

def clear_cache():
    default_bypass.clear_cache()

def get_cache_stats() -> Dict[str, Any]:
    return default_bypass.get_cache_stats()
