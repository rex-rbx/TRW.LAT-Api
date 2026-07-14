import requests
import time
from typing import Optional, Dict, Any
from urllib.parse import quote
class FEARBypass:
    def __init__(self):
        self.base_url = "https://trw.lat/api"
        self.free_key = None
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
    def bypass(self, url: str, origin: str = "NotApplicable") -> str:
        free_key = self.get_free_key()
        if not free_key:
            raise Exception("Failed to get free key")
        encoded_url = quote(url)
        try:
            response = requests.get(
                f"{self.base_url}/bypass",
                params={
                    "url": encoded_url,
                    "origin": origin
                },
                headers={
                    "x-api-key": free_key,
                    "Content-Type": "application/json"
                }
            )
            response.raise_for_status()
            data = response.json()
            if data.get('success'):
                return data.get('result')
            else:
                raise Exception(f"Thread start failed: {data}")
        except requests.exceptions.RequestException as e:
            if hasattr(e, 'response') and e.response:
                raise Exception(f"API error: {e.response.status_code} - {e.response.text}")
            else:
                raise Exception(f"Request failed: {str(e)}")
default_bypass = FEARBypass()
def bypass(url: str, origin: str = "NotApplicable") -> str:
    return default_bypass.bypass(url, origin)
