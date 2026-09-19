import json
import secrets
import urllib.error
import urllib.parse
import urllib.request

AUTH_BASE = "https://auth.bbbgame.net/auth/api/"
GAME_BASE = "https://dof.bbbgame.net/crap-app/"

UA_WEB = ("Mozilla/5.0 (Linux; Android 9; V2241A Build/PQ3A.190605.06171433; wv) "
          "AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/124.0.6367.82 Safari/537.36")
UA_UNITY = "UnityPlayer/6000.3.9f1 (UnityWebRequest/1.0, libcurl/8.10.1-DEV)"


class DofExportError(Exception):
    pass


def _post_form(url, fields, timeout=15):
    body = urllib.parse.urlencode(fields).encode("utf-8")
    req = urllib.request.Request(url, data=body, method="POST")
    req.add_header("Content-Type", "application/x-www-form-urlencoded;charset=UTF-8")
    req.add_header("User-Agent", UA_WEB)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        raise DofExportError(f"HTTP {e.code} from {url}") from e
    except Exception as e:
        raise DofExportError(f"{type(e).__name__}: {e}") from e


def _post_data_json(url, obj, bearer, timeout=15):
    body = urllib.parse.urlencode({"data": json.dumps(obj, separators=(",", ":"))}).encode("utf-8")
    req = urllib.request.Request(url, data=body, method="POST")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    req.add_header("User-Agent", UA_UNITY)
    req.add_header("Bearer", bearer)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        raise DofExportError(f"HTTP {e.code} from {url}") from e
    except Exception as e:
        raise DofExportError(f"{type(e).__name__}: {e}") from e


def export_save_json(email: str, password: str) -> str:
    if not email or not password:
        raise DofExportError("Email and password are required.")

    login = _post_form(AUTH_BASE + "token", {
        "g": "9", "u": email, "p": password, "t": "email", "auth_version": "2.1.0",
        "device_id": secrets.token_hex(8), "device_model": "V2241A", "device_vendor": "vivo",
        "advertiser_id": "UNSUPPORTED", "package": "com.bigbluebubble.msm2",
        "os_version": "9", "platform": "android", "lang": "en", "client_version": "4.1.0",
        "gpg_version": "2",
    })
    if not login.get("ok", True) is True and not login.get("access_token"):
        raise DofExportError("Login failed - check the email and password.")
    access_token = login.get("access_token")
    if not access_token:
        raise DofExportError("Server did not return an access token.")

    bbb_device_id = secrets.token_hex(16)
    login_resp = _post_data_json(GAME_BASE + "msm2auth", {
        "client_version": 18343, "kick": 0, "previous_session": 0,
        "device": {"device_identifiers": {"advertising_id": ""}, "platform": "android",
                   "bbb_device_id": bbb_device_id},
        "request": 10, "static_data_version": 18343, "previous_client_hash": "",
        "previous_sequence": 0, "user": "", "client_hash": secrets.token_hex(16), "language": "en",
    }, bearer=access_token)

    entries = login_resp if isinstance(login_resp, list) else []
    sync_entry = next((e for e in entries if e.get("type") == 16), None)
    if sync_entry is None or "sync_data" not in sync_entry:
        raise DofExportError("Login succeeded but no save data was returned.")

    return json.dumps(sync_entry["sync_data"])
