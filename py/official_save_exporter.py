from __future__ import annotations

import asyncio
import inspect
import json
import os
import secrets
import socket
import ssl
import struct
import urllib.error
import urllib.parse
import urllib.request
from typing import Any

import websockets

from msm_protocol import SFSLong, decode_sfsobject, encode_sfsobject

AUTH_URL = "https://auth.bbbgame.net/auth/api/token"
WS_URL = "wss://msm-mobile-prod-v2.bbbgame.net:443/msm/socket"
CLIENT_VERSION = "5.7.0"
CLIENT_OS = "9"
CLIENT_DEVICE = "V2241A"
DEVICE_VENDOR = "vivo"
PACKAGE_NAME = "com.bigbluebubble.singingmonsters.full"
ZONE = "MySingingMonsters"


def _env_str(name: str, default: str) -> str:
    value = os.environ.get(name)
    return default if value is None else value


def _env_int(name: str, default: int) -> int:
    value = os.environ.get(name)
    if value is None or value.strip() == "":
        return default
    return int(value)


def _server_access_key() -> str:
    return _env_str("NPS_MSM_ACCESS_KEY", "25010558-d92f-4b26-87cd-30aa7751c377")


def _frame(
    request_id: int, command: str, params: dict[str, Any] | None = None
) -> bytes:
    command_bytes = command.encode("ascii")
    payload = encode_sfsobject(params or {})
    return (
        request_id.to_bytes(8, "big", signed=False)
        + len(command_bytes).to_bytes(2, "big")
        + command_bytes
        + payload
    )


def _cbor_write_len(major: int, length: int) -> bytes:
    if length < 0:
        raise ValueError("negative CBOR length")
    prefix = major << 5
    if length < 24:
        return bytes([prefix | length])
    if length <= 0xFF:
        return bytes([prefix | 24, length])
    if length <= 0xFFFF:
        return bytes([prefix | 25]) + length.to_bytes(2, "big")
    if length <= 0xFFFFFFFF:
        return bytes([prefix | 26]) + length.to_bytes(4, "big")
    return bytes([prefix | 27]) + length.to_bytes(8, "big")


def _encode_cbor(value: Any) -> bytes:
    if value is None:
        return b"\xf6"
    if value is False:
        return b"\xf4"
    if value is True:
        return b"\xf5"
    if isinstance(value, int):
        if value >= 0:
            return _cbor_write_len(0, value)
        return _cbor_write_len(1, -1 - value)
    if isinstance(value, str):
        data = value.encode("utf-8")
        return _cbor_write_len(3, len(data)) + data
    if isinstance(value, (list, tuple)):
        return _cbor_write_len(4, len(value)) + b"".join(
            _encode_cbor(child) for child in value
        )
    if isinstance(value, dict):
        items = sorted(value.items(), key=lambda item: str(item[0]))
        out = _cbor_write_len(5, len(items))
        for key, child in items:
            out += _encode_cbor(str(key)) + _encode_cbor(child)
        return out
    raise TypeError(f"Cannot CBOR-encode {type(value)!r}")


class _CborReader:
    def __init__(self, data: bytes) -> None:
        self.data = data
        self.pos = 0

    def read(self, count: int) -> bytes:
        chunk = self.data[self.pos : self.pos + count]
        if len(chunk) != count:
            raise ValueError("truncated CBOR payload")
        self.pos += count
        return chunk

    def read_u8(self) -> int:
        return self.read(1)[0]

    def read_len(self, addl: int) -> int:
        if addl < 24:
            return addl
        if addl == 24:
            return self.read_u8()
        if addl == 25:
            return int.from_bytes(self.read(2), "big")
        if addl == 26:
            return int.from_bytes(self.read(4), "big")
        if addl == 27:
            return int.from_bytes(self.read(8), "big")
        raise ValueError(f"unsupported CBOR additional info {addl}")


def _decode_cbor_value(reader: _CborReader) -> Any:
    initial = reader.read_u8()
    major = initial >> 5
    addl = initial & 0x1F
    if major == 0:
        return reader.read_len(addl)
    if major == 1:
        return -1 - reader.read_len(addl)
    if major == 2:
        return reader.read(reader.read_len(addl))
    if major == 3:
        return reader.read(reader.read_len(addl)).decode("utf-8", "replace")
    if major == 4:
        return [_decode_cbor_value(reader) for _ in range(reader.read_len(addl))]
    if major == 5:
        return {
            _decode_cbor_value(reader): _decode_cbor_value(reader)
            for _ in range(reader.read_len(addl))
        }
    if major == 7:
        if addl == 20:
            return False
        if addl == 21:
            return True
        if addl == 22:
            return None
        if addl == 26:
            return struct.unpack(">f", reader.read(4))[0]
        if addl == 27:
            return struct.unpack(">d", reader.read(8))[0]
    raise ValueError(f"unsupported CBOR major={major} addl={addl}")


def _decode_cbor(data: bytes) -> Any:
    reader = _CborReader(data)
    value = _decode_cbor_value(reader)
    if reader.pos != len(data):
        raise ValueError("CBOR payload had trailing bytes")
    return value


def _cbor_frame(order: int, request_id: str, request: dict[str, Any]) -> bytes:
    payload = {
        "order": order,
        "request": request,
        "requestId": request_id,
    }
    return b"CBOR" + _encode_cbor(payload)


def _cbor_support_frame(order: int) -> bytes:
    return _cbor_frame(
        order,
        "CBOR_SUPPORT",
        {
            "commands": [
                "USER_ERROR",
                "USER_LOGIN",
                "USER_LOGOUT",
                "USER_DISCONNECT",
                "ADMIN_MESSAGE",
                "gs_move_monster",
            ],
        },
    )


def _parse_server_frame(data: bytes) -> tuple[str, dict[str, Any]]:
    if data.startswith(b"CBOR"):
        payload = _decode_cbor(data[4:])
        if not isinstance(payload, dict):
            raise ValueError("CBOR server frame was not an object")
        command = str(
            payload.get("requestId")
            or payload.get("responseId")
            or payload.get("command")
            or payload.get("cmd")
            or "CBOR"
        )
        params = payload.get(
            "response", payload.get("request", payload.get("data", payload))
        )
        return command, params if isinstance(params, dict) else {"value": params}
    if len(data) < 2:
        raise ValueError("short server frame")
    name_len = int.from_bytes(data[:2], "big")
    end = 2 + name_len
    if end > len(data):
        raise ValueError("truncated server command")
    command = data[2:end].decode("ascii", "replace")
    payload = decode_sfsobject(data[end:]) if end < len(data) else {}
    return command, payload


def _find_key(value: Any, wanted: str) -> Any:
    wanted_l = wanted.lower().replace("-", "_")
    if isinstance(value, dict):
        for key, child in value.items():
            if key.lower().replace("-", "_") == wanted_l:
                return child
            found = _find_key(child, wanted)
            if found is not None:
                return found
    if isinstance(value, list):
        for child in value:
            found = _find_key(child, wanted)
            if found is not None:
                return found
    return None


def _first_scalar(value: Any) -> Any:
    if isinstance(value, list):
        return _first_scalar(value[0]) if value else None
    return value


def _auth(email: str, password: str, device_id: str) -> dict[str, Any]:
    client_version = _env_str("NPS_MSM_CLIENT_VERSION", CLIENT_VERSION)
    client_os = _env_str("NPS_MSM_CLIENT_OS", CLIENT_OS)
    client_device = _env_str("NPS_MSM_CLIENT_DEVICE", CLIENT_DEVICE)
    client_platform = _env_str("NPS_MSM_CLIENT_PLATFORM", "android")
    device_vendor = _env_str("NPS_MSM_DEVICE_VENDOR", DEVICE_VENDOR)

    body = {
        "g": "1",
        "u": email,
        "p": password,
        "t": "email",
        "advertiser_id": "",
        "auth_version": "2.0.0",
        "client_version": client_version,
        "device_id": device_id,
        "device_model": client_device,
        "device_vendor": device_vendor,
        "lang": "",
        "os_version": client_os,
        "package": PACKAGE_NAME,
        "platform": client_platform,
        "update_device": "1",
    }
    data = urllib.parse.urlencode(body).encode("utf-8")
    request = urllib.request.Request(
        AUTH_URL,
        data=data,
        method="POST",
        headers={
            "content-type": "application/x-www-form-urlencoded",
            "accept": "application/json, text/plain, */*",
            "client-version": client_version,
            "client_version": client_version,
            "user-agent": f"MSM/{client_version} ({client_platform}; {client_os})",
        },
    )
    with urllib.request.urlopen(request, timeout=25) as response:
        doc = json.loads(response.read().decode("utf-8", "replace"))
    if not doc.get("ok"):
        message = doc.get("message") or doc.get("error") or "login failed"
        raise RuntimeError(str(message))
    if not (
        _first_scalar(_find_key(doc, "access_token"))
        and _first_scalar(_find_key(doc, "user_game_id"))
    ):
        raise RuntimeError("auth response did not include token/user")
    return doc


def _error_kind(message: str) -> str:
    lowered = message.lower()
    if "email and password" in lowered:
        return "missing_credentials"
    if "invalid" in lowered and ("password" in lowered or "credential" in lowered):
        return "bad_credentials"
    if "incorrect" in lowered or "unauthorized" in lowered or "forbidden" in lowered:
        return "bad_credentials"
    if "403" in lowered or "blocked" in lowered or "waf" in lowered:
        return "blocked"
    if "timed out" in lowered or "timeout" in lowered:
        return "timeout"
    if "client version" in lowered:
        return "client_version"
    if (
        "did not include token" in lowered
        or "login token" in lowered
        or "user_login failed" in lowered
    ):
        return "login_rejected"
    if "player_object" in lowered or "save json" in lowered:
        return "bad_save"
    if "network" in lowered or "connection" in lowered or "ssl" in lowered:
        return "network"
    return "unknown"


def _public_error(exc: Exception) -> tuple[str, str]:
    if isinstance(exc, urllib.error.HTTPError):
        if exc.code == 403:
            return (
                "blocked",
                "The official auth server blocked the request. Try again later or use a normal network connection.",
            )
        if exc.code in (401, 404):
            return (
                "bad_credentials",
                "Email or password was rejected by the official auth server.",
            )
        return (
            "network",
            f"The official auth server returned HTTP {exc.code}. Try again later.",
        )
    if isinstance(exc, urllib.error.URLError):
        return (
            "network",
            "Could not reach the official auth server. Check your internet connection.",
        )
    if isinstance(exc, (TimeoutError, asyncio.TimeoutError, socket.timeout)):
        return (
            "timeout",
            "The official server took too long to respond. Try again with a stable connection.",
        )
    if isinstance(exc, (ssl.SSLError, ConnectionError, OSError)):
        return (
            "network",
            "The connection to the official server failed. Check your internet connection and try again.",
        )

    message = str(exc).strip() or exc.__class__.__name__
    kind = _error_kind(message)
    if kind == "missing_credentials":
        return kind, "Email and password are required."
    if kind == "bad_credentials":
        return kind, "Email or password was rejected by the official auth server."
    if kind == "blocked":
        return (
            kind,
            "The official auth server blocked the request. Try again later or use a normal network connection.",
        )
    if kind == "timeout":
        return kind, "The official server took too long to respond. Try again."
    if kind == "client_version":
        return (
            kind,
            "The official server rejected this MSM client version. Update NPS and try again.",
        )
    if kind == "login_rejected":
        return (
            kind,
            "The official server accepted auth but refused the game login. Try again.",
        )
    if kind == "bad_save":
        return kind, "The official server responded, but the save data was not valid."
    if kind == "network":
        return (
            kind,
            "The connection to the official server failed. Check your internet connection and try again.",
        )
    return kind, "Import failed. Try again later."


def _normalize_player_json(
    payload: Any, quest_payload: dict[str, Any] | None = None
) -> str:
    player = _find_key(payload, "player_object")
    if not isinstance(player, dict):
        raise RuntimeError("gs_player did not include player_object")
    doc: dict[str, Any] = {"player_object": player}
    if quest_payload is not None:
        doc["gs_quest"] = quest_payload
    return json.dumps(doc, ensure_ascii=False, separators=(",", ":"))


def _websocket_connect(headers: dict[str, str]) -> Any:
    params = inspect.signature(websockets.connect).parameters
    if "extra_headers" in params:
        return websockets.connect(WS_URL, extra_headers=headers)
    return websockets.connect(WS_URL, additional_headers=headers)


async def _export(email: str, password: str) -> dict[str, Any]:
    client_version = _env_str("NPS_MSM_CLIENT_VERSION", CLIENT_VERSION)
    client_os = _env_str("NPS_MSM_CLIENT_OS", CLIENT_OS)
    client_device = _env_str("NPS_MSM_CLIENT_DEVICE", CLIENT_DEVICE)
    client_platform = _env_str("NPS_MSM_CLIENT_PLATFORM", "android")
    device_id = _env_str("NPS_MSM_RAW_DEVICE_ID", secrets.token_hex(8))
    last_update_version = _env_str("NPS_MSM_LAST_UPDATE_VERSION", client_version)
    last_updated = _env_int("NPS_MSM_LAST_UPDATED", 0)

    auth_doc = _auth(email, password, device_id)
    token = str(_first_scalar(_find_key(auth_doc, "access_token")))
    user = str(_first_scalar(_find_key(auth_doc, "user_game_id")))
    server_access_key = _server_access_key()

    headers = {
        "client-version": client_version,
        "client_version": client_version,
        "access-key": server_access_key,
        "access_key": server_access_key,
        "user-agent": f"MSM/{client_version} ({client_platform}; {client_os})",
    }
    login_data = {
        "access_key": server_access_key,
        "attempt_recovery": False,
        "client_device": client_device,
        "client_lang": "",
        "client_os": client_os,
        "client_platform": client_platform,
        "client_version": client_version,
        "last_command_id": SFSLong(-1),
        "last_session_id": "",
        "last_update_version": last_update_version,
        "last_updated": SFSLong(last_updated),
        "raw_device_id": device_id,
        "token": token,
    }
    user_login = {
        "data": login_data,
        "password": "",
        "user": user,
        "zone": ZONE,
    }

    quest_payload: dict[str, Any] | None = None

    async with _websocket_connect(headers) as ws:
        await ws.send(_cbor_support_frame(0))
        await ws.send(_frame(1, "USER_LOGIN", user_login))

        initialized = False
        deadline = asyncio.get_running_loop().time() + 45.0
        while asyncio.get_running_loop().time() < deadline:
            msg = await asyncio.wait_for(ws.recv(), timeout=8.0)
            if not isinstance(msg, bytes):
                continue
            command, params = _parse_server_frame(msg)
            if command == "USER_LOGIN" and params.get("success") is False:
                raise RuntimeError("USER_LOGIN failed")
            if command == "gs_client_version_error":
                raise RuntimeError("server rejected this client version")
            if command == "gs_quest" and quest_payload is None:
                quest_payload = params
            if command == "gs_initialized":
                initialized = True
                break
        if not initialized:
            raise RuntimeError("server init timed out")

        await ws.send(_frame(2, "gs_player", {"last_updated": SFSLong(last_updated)}))
        deadline = asyncio.get_running_loop().time() + 60.0
        player_payload: dict[str, Any] | None = None
        while asyncio.get_running_loop().time() < deadline:
            try:
                msg = await asyncio.wait_for(ws.recv(), timeout=10.0)
            except asyncio.TimeoutError:
                if player_payload is not None:
                    break
                raise
            if not isinstance(msg, bytes):
                continue
            command, params = _parse_server_frame(msg)
            if command == "gs_quest" and quest_payload is None:
                quest_payload = params
            if command == "gs_player":
                player_payload = params
                if quest_payload is not None:
                    break
                deadline = min(deadline, asyncio.get_running_loop().time() + 5.0)
            if command == "gs_client_version_error":
                raise RuntimeError("server rejected this client version")
        if player_payload is not None:
            return {
                "ok": True,
                "user": user,
                "save_json": _normalize_player_json(player_payload, quest_payload),
            }
        raise RuntimeError("gs_player timed out")


def export_save_json(email: str, password: str) -> str:
    try:
        email = (email or "").strip()
        if not email or not password:
            raise RuntimeError("email and password are required")
        return json.dumps(asyncio.run(_export(email, password)), ensure_ascii=False)
    except Exception as exc:
        kind, message = _public_error(exc)
        return json.dumps(
            {"ok": False, "error": message, "kind": kind}, ensure_ascii=False
        )
