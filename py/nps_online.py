import json
import logging
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

_SSL_CONTEXT = None


def set_nps_online_config(
    server_url, account_id, session_token, device_id, friend_code="", cert_hash=""
):
    global _SERVER_URL, _ACCOUNT_ID, _SESSION_TOKEN, _DEVICE_ID, _FRIEND_CODE, _CERT_HASH
    _SERVER_URL = (server_url or "").rstrip("/")
    _ACCOUNT_ID = int(account_id or 0)
    _SESSION_TOKEN = session_token or ""
    _DEVICE_ID = device_id or ""
    _FRIEND_CODE = friend_code or ""
    _CERT_HASH = cert_hash or ""


def is_configured():
    return bool(_SERVER_URL and _SESSION_TOKEN and _ACCOUNT_ID)


def active_account_id():
    return _ACCOUNT_ID


def active_friend_code():
    return _FRIEND_CODE


def _sign(method, path_with_query, body_bytes, ts):
    from java import jclass

    native = jclass("com.nextstars.nps.NpsAuthNative")
    return str(
        native.sign(method, path_with_query, _DEVICE_ID, _CERT_HASH, ts, body_bytes)
    )


def _ssl_context():
    global _SSL_CONTEXT
    if _SSL_CONTEXT is None:
        _SSL_CONTEXT = ssl.create_default_context()
    return _SSL_CONTEXT


def _refresh_session():
    global _SESSION_TOKEN
    try:
        from java import jclass

        token = str(jclass("com.nextstars.nps.NpsOnlineSession").refresh() or "")
    except Exception:
        return False
    if not token or token == _SESSION_TOKEN:
        return False
    _SESSION_TOKEN = token
    return True


def _request(method, path, body_obj=None, _retrying=False):
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
        if e.code == 401 and not _retrying and _refresh_session():
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
        (result.get("requests") or result.get("friends") or [])
        if (result and result.get("code") == ok_code)
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
