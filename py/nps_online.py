import hashlib
import hmac
import json
import logging
import os
import ssl
import time
import urllib.error
import urllib.request

logger = logging.getLogger("msm.nps_online")
_SERVER_URL = ""
_ACCOUNT_ID = 0
_SESSION_TOKEN = ""
_DEVICE_ID = ""
_FRIEND_CODE = ""
_CERT_HASH = ""
_REFRESH_TOKEN = ""
_SSL_CONTEXT = None
_DESKTOP_CONFIG_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "nps_online.json"
)
_DESKTOP_CONFIG_MTIME = None


def set_nps_online_config(
    server_url,
    account_id,
    session_token,
    device_id,
    friend_code="",
    cert_hash="",
    refresh_token="",
):
    global _SERVER_URL, _ACCOUNT_ID, _SESSION_TOKEN, _DEVICE_ID, _FRIEND_CODE, _CERT_HASH, _REFRESH_TOKEN
    _SERVER_URL = (server_url or "").rstrip("/")
    _ACCOUNT_ID = int(account_id or 0)
    _SESSION_TOKEN = session_token or ""
    _DEVICE_ID = device_id or ""
    _FRIEND_CODE = friend_code or ""
    _CERT_HASH = cert_hash or ""
    _REFRESH_TOKEN = refresh_token or ""
    invalidate_list_cache()


def _load_desktop_config():
    global _DESKTOP_CONFIG_MTIME
    try:
        mtime = os.path.getmtime(_DESKTOP_CONFIG_PATH)
    except OSError:
        if _DESKTOP_CONFIG_MTIME is not None:
            _DESKTOP_CONFIG_MTIME = None
            set_nps_online_config("", 0, "", "")
        return
    if mtime == _DESKTOP_CONFIG_MTIME:
        return
    try:
        with open(_DESKTOP_CONFIG_PATH, "r", encoding="utf-8") as f:
            cfg = json.load(f)
    except Exception as e:
        logger.warning("nps_online: could not read %s: %s", _DESKTOP_CONFIG_PATH, e)
        return
    _DESKTOP_CONFIG_MTIME = mtime
    set_nps_online_config(
        cfg.get("server_url", ""),
        cfg.get("account_id", 0),
        cfg.get("session_token", ""),
        cfg.get("device_id", ""),
        cfg.get("friend_code", ""),
        cfg.get("cert_hash", ""),
        cfg.get("refresh_token", ""),
    )
    if is_configured():
        logger.info("nps_online: desktop online account %s loaded", _ACCOUNT_ID)


def _save_desktop_tokens():
    global _DESKTOP_CONFIG_MTIME
    if _DESKTOP_CONFIG_MTIME is None:
        return
    try:
        with open(_DESKTOP_CONFIG_PATH, "r", encoding="utf-8") as f:
            cfg = json.load(f)
        if int(cfg.get("account_id") or 0) != _ACCOUNT_ID:
            return
        cfg["session_token"] = _SESSION_TOKEN
        cfg["refresh_token"] = _REFRESH_TOKEN
        cfg["bridge_refreshed_at"] = int(time.time())
        tmp = _DESKTOP_CONFIG_PATH + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(cfg, f)
        os.replace(tmp, _DESKTOP_CONFIG_PATH)
        _DESKTOP_CONFIG_MTIME = os.path.getmtime(_DESKTOP_CONFIG_PATH)
    except Exception as e:
        logger.warning("nps_online: could not save renewed tokens: %s", e)


def is_configured():
    _load_desktop_config()
    return bool(_SERVER_URL and _SESSION_TOKEN and _ACCOUNT_ID)


def active_account_id():
    return _ACCOUNT_ID


def active_friend_code():
    return _FRIEND_CODE


_OBF_KEY = bytes(
    (90, 145, 60, 231, 34, 143, 100, 13, 179, 113, 78, 166, 31, 200, 89, 130)
)
_OBF_SECRET = bytes(
    (
        60,
        160,
        12,
        208,
        27,
        238,
        6,
        108,
        139,
        66,
        126,
        150,
        126,
        172,
        108,
        179,
        63,
        161,
        5,
        223,
        65,
        186,
        7,
        53,
        208,
        70,
        119,
        195,
        45,
        248,
        63,
        183,
        59,
        163,
        5,
        212,
        26,
        238,
        5,
        59,
        138,
        70,
        42,
        195,
        123,
        253,
        109,
        228,
        107,
        160,
        94,
        213,
        71,
        186,
        83,
        57,
        133,
        64,
        123,
        196,
        39,
        172,
        96,
        181,
    )
)


def _sign_py(method, path_with_query, body_bytes, ts):
    secret = bytes((b ^ _OBF_KEY[i % len(_OBF_KEY)] for i, b in enumerate(_OBF_SECRET)))
    message = f"{method}|{path_with_query}|{_DEVICE_ID}|{ts}|{_CERT_HASH}|".encode(
        "utf-8"
    ) + (body_bytes or b"")
    return hmac.new(secret, message, hashlib.sha256).hexdigest()


def _sign(method, path_with_query, body_bytes, ts):
    try:
        from java import jclass
    except ImportError:
        return _sign_py(method, path_with_query, body_bytes, ts)
    native = jclass("com.nextstars.nps.NpsAuthNative")
    return str(
        native.sign(method, path_with_query, _DEVICE_ID, _CERT_HASH, ts, body_bytes)
    )


def _ssl_context():
    global _SSL_CONTEXT
    if _SSL_CONTEXT is None:
        _SSL_CONTEXT = ssl.create_default_context()
    return _SSL_CONTEXT


def _refresh_session_py():
    global _SESSION_TOKEN, _REFRESH_TOKEN, _DESKTOP_CONFIG_MTIME
    before = _SESSION_TOKEN
    _load_desktop_config()
    if _SESSION_TOKEN and _SESSION_TOKEN != before:
        return True
    if not _REFRESH_TOKEN:
        return False
    old_token = _SESSION_TOKEN
    _SESSION_TOKEN = ""
    resp = _request(
        "POST", "/api/refresh", {"refresh_token": _REFRESH_TOKEN}, _retrying=True
    )
    token = str((resp or {}).get("session_token") or "")
    if not token:
        _SESSION_TOKEN = old_token
        return False
    _SESSION_TOKEN = token
    _REFRESH_TOKEN = str(resp.get("refresh_token") or _REFRESH_TOKEN)
    _save_desktop_tokens()
    logger.info("nps_online: session renewed")
    return True


def _refresh_session():
    global _SESSION_TOKEN
    try:
        from java import jclass
    except ImportError:
        return _refresh_session_py()
    try:
        token = str(jclass("com.nextstars.nps.NpsOnlineSession").refresh() or "")
    except Exception:
        return False
    if not token or token == _SESSION_TOKEN:
        return False
    _SESSION_TOKEN = token
    return True


def _request(method, path, body_obj=None, _retrying=False):
    _load_desktop_config()
    if not _SERVER_URL:
        return None
    body_bytes = json.dumps(body_obj).encode("utf-8") if body_obj is not None else b""
    ts = int(time.time())
    try:
        signature = _sign(method, path, body_bytes, ts)
    except Exception:
        return None
    headers = {
        "Content-Type": "application/json",
        "X-Nps-Device": _DEVICE_ID,
        "X-Nps-Ts": str(ts),
        "X-Nps-Cert": _CERT_HASH,
        "X-Nps-Sig": signature,
    }
    if _SESSION_TOKEN:
        headers["Authorization"] = "Bearer " + _SESSION_TOKEN
    req = urllib.request.Request(
        _SERVER_URL + path,
        data=body_bytes if body_obj is not None else None,
        headers=headers,
        method=method,
    )
    try:
        with urllib.request.urlopen(req, context=_ssl_context(), timeout=4) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        if e.code == 401 and (not _retrying) and _refresh_session():
            return _request(method, path, body_obj, _retrying=True)
        try:
            body = e.read().decode("utf-8")
        except Exception:
            body = ""
        logger.warning(
            "nps_online %s %s -> HTTP %s: %s", method, path, e.code, body[:300]
        )
        try:
            return json.loads(body)
        except Exception:
            return None
    except Exception as e:
        logger.warning(
            "nps_online %s %s failed: %s: %s", method, path, e.__class__.__name__, e
        )
        return None


_LIST_CACHE = {}
_LIST_CACHE_TTL = 3.0


def invalidate_list_cache():
    _LIST_CACHE.clear()


def _cached_list(name, path, ok_code):
    now = time.time()
    hit = _LIST_CACHE.get(name)
    if hit is not None and now - hit[0] < _LIST_CACHE_TTL:
        return hit[1]
    result = _request("GET", path)
    value = (
        result.get("requests") or result.get("friends") or []
        if result and result.get("code") == ok_code
        else []
    )
    _LIST_CACHE[name] = (now, value)
    return value


def push_snapshot(snapshot):
    if not is_configured():
        return False
    result = _request("POST", "/api/snapshot", {"snapshot": snapshot})
    return bool(result and result.get("code") == 96)


def list_friends():
    if not is_configured():
        return []
    return _cached_list("friends", "/api/friend/list", 73)


def fetch_friend_snapshot(account_id):
    if not is_configured():
        return None
    result = _request("GET", "/api/friend/snapshot?account_id=%d" % int(account_id))
    if not result or result.get("code") != 319:
        return None
    return result.get("snapshot")


def send_friend_request(code):
    if not is_configured() or not code:
        return 0
    invalidate_list_cache()
    result = _request("POST", "/api/friend/request", {"code": code})
    if not result:
        return 0
    return int(result.get("code") or 0)


def list_friend_requests():
    if not is_configured():
        return []
    return _cached_list("requests", "/api/friend/requests", 44)


def list_outgoing_requests():
    if not is_configured():
        return []
    return _cached_list("outgoing", "/api/friend/outgoing", 45)


def list_discoverable():
    if not is_configured():
        return []
    return _cached_list("discover", "/api/friend/discover", 61)


def accept_friend_request(account_id):
    if not is_configured():
        return False
    invalidate_list_cache()
    result = _request("POST", "/api/friend/accept", {"account_id": int(account_id)})
    return bool(result and result.get("code") == 388)


def remove_friend(account_id):
    if not is_configured():
        return False
    invalidate_list_cache()
    result = _request("POST", "/api/friend/remove", {"account_id": int(account_id)})
    return bool(result and result.get("code") in (202, 388))


def decline_friend_request(account_id):
    if not is_configured():
        return False
    invalidate_list_cache()
    result = _request("POST", "/api/friend/decline", {"account_id": int(account_id)})
    return bool(result and result.get("code") == 388)
