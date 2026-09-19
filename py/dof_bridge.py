import json
import os
import random
import secrets
import string
import threading
import time
import logging
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs

logger = logging.getLogger("dof.bridge")
logger.setLevel(logging.INFO)
_dof_stdout = logging.StreamHandler(sys.stdout)
_dof_stdout.setFormatter(logging.Formatter("%(asctime)s [DOF] %(message)s"))
logger.addHandler(_dof_stdout)
logger.propagate = False

PORT = 8090

CURRENCY_COINS = 4
CURRENCY_DIAMONDS = 5

_server = None
_active_device_id = None


def _base_dir():
    return Path(os.environ.get("NPS_DOF_BASE_DIR", "."))


def _saves_dir():
    d = _base_dir() / "saves"
    d.mkdir(parents=True, exist_ok=True)
    return d


def _traffic_log():
    return _base_dir() / "traffic.log"


_entity_catalog_cache = None


def _entity_is_monster(entity_id):
    global _entity_catalog_cache
    if _entity_catalog_cache is None:
        path = _base_dir() / "dof_entity_catalog.json"
        try:
            entries = json.loads(path.read_text(encoding="utf-8"))["entities"]
            _entity_catalog_cache = {e["id"]: e.get("isMonster", True) for e in entries}
        except Exception:
            _entity_catalog_cache = {}
    return _entity_catalog_cache.get(entity_id, True)


def _load_static_auth_data():
    path = _base_dir() / "known_responses" / "msm2auth_10.json"
    try:
        capture = json.loads(path.read_text(encoding="utf-8"))
        coupons = next(i["coupon_list"] for i in capture if i.get("type") == 1003)
        server_text = next(i["server_text"] for i in capture if i.get("type") == 1004)
        schedule = next(i["schedule_instances"] for i in capture if i.get("type") == 1005)
        return coupons, server_text, schedule
    except Exception:
        return (
            {"dataFormat": 1, "couponsVersionId": 0, "coupons": []},
            {},
            {"rs": []},
        )


STATIC_COUPON_LIST, STATIC_SERVER_TEXT, STATIC_SCHEDULE_INSTANCES = _load_static_auth_data()


def set_active_device(device_id):
    global _active_device_id
    _active_device_id = device_id or None


def _resolve_device_id(client_supplied):
    return _active_device_id or client_supplied



def _rand_id(n=12, alphabet=string.ascii_lowercase + string.digits):
    return "".join(random.choice(alphabet) for _ in range(n))


def _fresh_save(device_id, bbb_device_id):
    now_ms = int(time.time() * 1000)
    now_s = int(time.time())
    account_id = _rand_id(10)
    user_game_id = _rand_id(10)
    friend_code = "".join(random.choice("ABCDEFGHJKLMNPQRSTUVWXYZ23456789") for _ in range(8))
    player_user = "".join(random.choice(string.ascii_uppercase + string.digits) for _ in range(8))

    starter_island = {
        "id": 1, "grids": [3, 5],
        "monsters": [
            {"databasae_id": 281, "instance_id": 1, "grid_id": 3, "x": 14, "y": 15,
             "muted": False, "volume": 100, "flip": False, "scaleX": 64, "scaleY": 64,
             "specialAcquisition": False, "busy": False, "name": "", "level": 1, "xp": 0,
             "request": 0, "costume": 0, "cave": False, "costume_equipped": False,
             "favorite": False, "player_favourite": False, "favorite_lockout": {},
             "cached_coins": 0, "likes": []},
        ],
        "structures": [
            {"databasae_id": 185, "instance_id": 2, "grid_id": 3, "x": 6, "y": 21,
             "muted": False, "volume": 100, "flip": False, "scaleX": 64, "scaleY": 64,
             "specialAcquisition": False, "busy": False,
             "craft": {"start": 0, "slots": 1, "rng": {"s1": 1, "s2": random.randint(1, 2**31 - 1), "s3": 0, "s4": 0}, "queue": []},
             "level": 1},
        ],
        "decorations": [], "collection": {"contents": [], "timestamps": []},
    }

    return {
        "account_id": account_id,
        "username": _rand_id(12),
        "password": _rand_id(20),
        "user_game_id": user_game_id,
        "friend_code": friend_code,
        "device_id": device_id,
        "bbb_device_id": bbb_device_id,
        "login_index": 0,
        "instance_counter": 3,
        "sync_data": {
            "versionCode": 18343,
            "islands": {"islands": [{"id": 0, "monsters": [], "structures": [], "decorations": [],
                                      "collection": {"contents": [], "timestamps": []}}, starter_island]},
            "quests": {"questCounter": -1,
                       "questRNG": {"s1": random.randint(1, 2**31 - 1), "s2": 0, "s3": 0, "s4": 0},
                       "serverRNG": {"s1": random.randint(1, 2**31 - 1), "s2": 0, "s3": 0, "s4": 0},
                       "orders": [], "active_quests": [], "completed_quests": [],
                       "collected_quests": [], "active_achievements": [], "serverQuestCounter": 0},
            "player_info": {
                "islands": [0, 1], "banned": False, "csr_confirmed": False, "auth_timestamp": 0,
                "suspicious": False, "internal": False, "banned_date": 0,
                "user": player_user, "friend_code": friend_code, "date_created": now_ms,
                "level": 1, "loadedSession": 0, "loadedSequence": 0, "tutorial_complete": False,
                "admin_mail_id": "", "last_login": now_ms, "last_save": 0,
                "static_data_version": 18437, "client_version": 18343, "client_hash": "",
                "airshipShippingTickets": 0, "airshipAssistTickets": 0,
                "shippingMonthlyTickets": 0, "assistMonthlyTickets": 0, "last_batch": 0,
                "user_game_id": user_game_id,
                "session_device": {"bbb_device_id": bbb_device_id, "platform": "android",
                                    "device_identifiers": {"advertising_id": ""}},
                "current_response": "[]", "last_breeding_combos": [],
            },
            "inventory": {
                "myGlobalRNG": {"s1": random.randint(1, 2**31 - 1), "s2": 0, "s3": 0, "s4": 0},
                "instanceCounter": 3,
                "inv_items": {"contents": [[CURRENCY_COINS, 500], [CURRENCY_DIAMONDS, 20],
                                            [779, 0]], "timestamps": []},
                "escrow_items": {"contents": [], "timestamps": []},
                "storage": {"storage": [], "storage2": []},
            },
            "spinners": {"freeSpin": 1, "days": 0, "data": []},
            "tester": {"activeTime": 0, "accountCreation": now_s},
            "ad_segment_data": {"segment_data": []},
            "voterBox": {"voterBox": {"votes": [], "canReset": False, "timestamp": 0, "latestReset": 0}},
            "global_wants": {"global_wants": []},
            "completed_global_wants": {"completed_global_wants": []},
            "market": {"market": {"owner": {"user": player_user, "name": ""}, "size": 5,
                                   "items": [], "boatRequests": [], "modified": 0,
                                   "sales": [], "boatAssists": []}},
            "mail": {"mail": {"mail": [], "last_timestamp": 0, "checkMail": True}},
            "tokenBox": {"tokenBox": {"token": [], "last_timestamp": 0}},
        },
    }


def _save_path(device_id):
    safe = "".join(c if c.isalnum() else "_" for c in device_id)
    return _saves_dir() / f"{safe}.json"


def load_or_create_save(device_id, bbb_device_id):
    path = _save_path(device_id)
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8"))
    save = _fresh_save(device_id, bbb_device_id)
    write_save(save)
    return save


def find_save_by_token(token):
    for path in _saves_dir().glob("*.json"):
        save = json.loads(path.read_text(encoding="utf-8"))
        if save.get("access_token") == token:
            return save
    return None


def write_save(save):
    _save_path(save["device_id"]).write_text(json.dumps(save, indent=2), encoding="utf-8")



def inv_get(save, entity_id):
    for pair in save["sync_data"]["inventory"]["inv_items"]["contents"]:
        if pair[0] == entity_id:
            return pair[1]
    return 0


def inv_add(save, entity_id, delta):
    contents = save["sync_data"]["inventory"]["inv_items"]["contents"]
    for pair in contents:
        if pair[0] == entity_id:
            pair[1] = max(0, pair[1] + delta)
            return pair[1]
    contents.append([entity_id, max(0, delta)])
    return max(0, delta)


def find_entity(save, instance_id):
    for island in save["sync_data"]["islands"]["islands"]:
        for group in ("monsters", "structures"):
            for entity in island.get(group, []):
                if entity.get("instance_id") == instance_id:
                    return entity
    return None


def next_instance_id(save):
    save["instance_counter"] += 1
    save["sync_data"]["inventory"]["instanceCounter"] = save["instance_counter"]
    return save["instance_counter"]



def _cmd_entity_move(save, cmd):
    entity = find_entity(save, cmd.get("entity"))
    if entity:
        entity["x"] = cmd.get("x", entity["x"])
        entity["y"] = cmd.get("y", entity["y"])
        entity["grid_id"] = cmd.get("grid", entity["grid_id"])
        entity["flip"] = cmd.get("flip", entity["flip"])
    return []


def _cmd_entity_rename(save, cmd):
    entity = find_entity(save, cmd.get("entity"))
    if entity and "name" in cmd:
        entity["name"] = cmd["name"]
    return []


def _cmd_entity_mute(save, cmd):
    entity = find_entity(save, cmd.get("entity"))
    if entity and "mute" in cmd:
        entity["muted"] = bool(cmd["mute"])
    return []


def _cmd_entity_favorite(save, cmd):
    entity = find_entity(save, cmd.get("entity"))
    if entity:
        entity["favorite"] = not entity.get("favorite", False)
        entity["player_favourite"] = entity["favorite"]
    return []


def _cmd_entity_favorite_refresh(save, cmd):
    return []


def _cmd_entity_collect(save, cmd):
    entity = find_entity(save, cmd.get("entity"))
    if entity and entity.get("cached_coins"):
        inv_add(save, CURRENCY_COINS, entity["cached_coins"])
        entity["cached_coins"] = 0
    return []


def _cmd_structure_speedup(save, cmd):
    entity = find_entity(save, cmd.get("entity"))
    if entity and "craft" in entity:
        entity["craft"]["start"] = 0
    return []


def _cmd_entity_buy(save, cmd):
    islands = save["sync_data"]["islands"]["islands"]
    island = next((i for i in islands if i.get("id") == cmd.get("island")), islands[-1])
    new_id = next_instance_id(save)
    item_id = cmd.get("item", 0)
    is_monster = _entity_is_monster(item_id)
    entity = {
        "databasae_id": item_id, "instance_id": new_id,
        "grid_id": cmd.get("grid", 3), "x": cmd.get("x", 0), "y": cmd.get("y", 0),
        "muted": False, "volume": 100, "flip": cmd.get("flip", False),
        "scaleX": 64, "scaleY": 64, "specialAcquisition": False, "busy": False,
        "level": 1,
    }
    if is_monster:
        entity.update({
            "name": "", "xp": 0, "request": 0, "costume": 0, "cave": False,
            "costume_equipped": False, "favorite": False, "player_favourite": False,
            "favorite_lockout": {}, "cached_coins": 0, "likes": [],
        })
        island.setdefault("monsters", []).append(entity)
    else:
        entity["craft"] = {
            "start": 0, "slots": 1,
            "rng": {"s1": 1, "s2": random.randint(0, 2**31 - 1), "s3": 0, "s4": 0},
            "queue": [],
        }
        island.setdefault("structures", []).append(entity)
    return []


def _cmd_tokens_collect(save, cmd):
    inv_add(save, 779, 1)
    return []


def _cmd_bonus_new_board(save, cmd):
    now_ms = int(time.time() * 1000)
    return [{
        "command": 1134, "when": now_ms,
        "bonusBoard": {
            "rng": {"s1": random.randint(1, 2**31 - 1), "s2": 0, "s3": 0, "s4": 0},
            "position": 0, "lastCollected": 0, "activeBoard": 880,
            "expiry": now_ms + 216000000,
        },
    }]


COMMAND_HANDLERS = {
    1101: _cmd_entity_move,
    1106: _cmd_entity_rename,
    1103: _cmd_entity_mute,
    1110: _cmd_entity_favorite,
    1111: _cmd_entity_favorite_refresh,
    1113: _cmd_entity_collect,
    1104: _cmd_structure_speedup,
    1100: _cmd_entity_buy,
    322: _cmd_tokens_collect,
    1133: _cmd_bonus_new_board,
}


def _housekeeping_ack(save):
    now_ms = int(time.time() * 1000)
    mail = save["sync_data"]["mail"]["mail"]
    token_count = inv_get(save, 779)
    return [
        {"command": 320, "when": now_ms, "data": {"mail": mail.get("mail", []),
                                                    "last_timestamp": mail.get("last_timestamp", 0),
                                                    "checkMail": True}},
        {"command": 9001, "when": now_ms,
         "data": {"targetQueue": 5, "targetDelay": 15, "warnQueue": 25, "warnDelay": 60,
                   "maxQueue": 200, "maxDelay": 3600, "repeatLimit": 100, "readOnly": False,
                   "altersPlayer": True, "requiresInOrder": True, "requireSync": False,
                   "requireServer": False,
                   "debugSettings": {"DEBUG_PLAYER_RNG": 1, "DEBUG_PLAYER_XP": 1}}},
        {"command": 1730, "when": now_ms, "nextReset": now_ms},
        {"command": 323, "when": now_ms,
         "data": {"token": [{"time": now_ms, "entity": 779, "count": token_count}],
                  "last_timestamp": 0}},
    ]


def handle_submit_command(save, batch_item):
    commands = (batch_item.get("data") or {}).get("commands") or []
    extra = []
    for cmd in commands:
        code = cmd.get("command")
        handler = COMMAND_HANDLERS.get(code)
        if handler:
            extra.extend(handler(save, cmd) or [])
    write_save(save)
    return [{"type": 101, "commands": {"commands": _housekeeping_ack(save) + extra}}]


def handle_player_sync(save):
    return [{"type": 100, "state": save["sync_data"]}]



def handle_check_dlc():
    return [
        {"type": 1002, "address": "https://dlc2.bbbgame.net/monster_babies/dlc/00018437-93908becfd29/android/",
         "version": 18437, "minVersion": 18343},
        {"type": 104, "clock": int(time.time() * 1000)},
    ]


def handle_auth_login(device_id, bbb_device_id):
    save = load_or_create_save(device_id, bbb_device_id)
    save["login_index"] += 1
    save["sync_data"]["player_info"]["last_login"] = int(time.time() * 1000)
    write_save(save)
    return [
        {"type": 16, "server": "", "id": "", "index": save["login_index"],
         "prev_session": 0, "prev_sequence": 0, "date_created": int(time.time() * 1000),
         "sync_data": save["sync_data"]},
        {"type": 1003, "coupon_list": STATIC_COUPON_LIST},
        {"type": 1004, "server_text": STATIC_SERVER_TEXT},
        {"type": 1005, "last_updated_timestamp": int(time.time()), "schedule_instances": STATIC_SCHEDULE_INSTANCES,
         "next_schedule_refresh": int(time.time()) + 3600},
        {"type": 104, "clock": int(time.time() * 1000)},
    ], save



class DofHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _read_body(self):
        length = int(self.headers.get("Content-Length", 0) or 0)
        raw = self.rfile.read(length) if length else b""
        try:
            return raw.decode("utf-8")
        except UnicodeDecodeError:
            return ""

    def _decoded(self, body_text):
        try:
            raw = parse_qs(body_text).get("data", [None])[0]
            return json.loads(raw) if raw is not None else None
        except Exception:
            return None

    def _send(self, body_obj, log_note=""):
        payload = json.dumps(body_obj).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)
        logger.info("RESP %s %s", log_note, json.dumps(body_obj)[:300])
        try:
            record = {
                "time": time.strftime("%Y-%m-%d %H:%M:%S"),
                "method": self.command,
                "path": self.path,
                "note": log_note,
                "response": body_obj,
            }
            with _traffic_log().open("a", encoding="utf-8") as f:
                f.write(json.dumps(record) + "\n")
        except Exception:
            pass

    def _bearer(self):
        return self.headers.get("Bearer", "")

    def route(self):
        segment = self.path.split("?", 1)[0].rstrip("/").rsplit("/", 1)[-1]
        body_text = self._read_body()
        logger.info("REQ %s %s body=%s", self.command, self.path, body_text[:800])
        try:
            with _traffic_log().open("a", encoding="utf-8") as _f:
                _f.write(json.dumps({"time": time.strftime("%Y-%m-%d %H:%M:%S"),
                                     "REQUEST": self.command, "path": self.path,
                                     "headers": {k: v for k, v in self.headers.items()},
                                     "body": body_text[:2000]}) + "\n")
        except Exception:
            pass

        if segment == "game_config":
            self._send({
                "ok": True,
                "config": {"login_types": [
                    {"type": "anon", "auto_create": True, "can_bind_to": False, "can_create": True},
                    {"type": "gp", "auto_create": False, "can_bind_to": True, "can_create": True}],
                    "type": "android", "age_gate_consent_required": False, "gdpr_consent_required": False},
                "geo": "BR", "gag": 13,
            })
            return

        if segment == "existing_accounts":
            q = dict(parse_qs(body_text))
            device_id = _resolve_device_id((q.get("device_id") or [""])[0])
            try:
                requested = json.loads((q.get("l") or ["[]"])[0])
            except (ValueError, json.JSONDecodeError):
                requested = []
            path = _save_path(device_id)
            matches = []
            if path.exists() and isinstance(requested, list):
                save = json.loads(path.read_text(encoding="utf-8"))
                for login in requested:
                    if not isinstance(login, dict):
                        continue
                    u = str(login.get("u") or "")
                    p = str(login.get("p") or "")
                    if u and p and u == save.get("username") and p == save.get("password"):
                        matches.append({"u": save["username"], "t": "anon"})
            self._send({"ok": True, "accounts": json.dumps(matches)})
            return

        if segment == "anon_account":
            q = dict(parse_qs(body_text))
            device_id = _resolve_device_id((q.get("device_id") or [_rand_id(16)])[0])
            save = load_or_create_save(device_id, device_id)
            token = secrets.token_urlsafe(64)
            save["access_token"] = token
            write_save(save)
            self._send({
                "ok": True, "username": save["username"], "password": save["password"],
                "account_id": save["account_id"], "user_game_id": save["user_game_id"],
                "login_type": "anon", "time_created": int(time.time()),
                "access_token": token, "token_type": "bearer",
                "expires_at": int(time.time()) + 1200, "device_updated": True,
            }, f"account={save['account_id']}")
            return

        if segment == "token":
            q = dict(parse_qs(body_text))
            username = (q.get("u") or [""])[0]
            match = None
            for path in _saves_dir().glob("*.json"):
                save = json.loads(path.read_text(encoding="utf-8"))
                if save.get("username") == username:
                    match = save
                    break
            if match is None:
                self._send({"ok": False}, "unknown user")
                return
            token = secrets.token_urlsafe(64)
            match["access_token"] = token
            write_save(match)
            self._send({
                "ok": True, "user_game_id": [match["user_game_id"]], "login_types": "[]",
                "access_token": token, "token_type": "bearer",
                "expires_at": int(time.time()) + 1200,
            }, f"account={match['account_id']}")
            return

        if segment == "msm2auth":
            data = self._decoded(body_text)
            if isinstance(data, list):
                data = data[0]
            opcode = data.get("request") if data else None
            bbb_device_id = _resolve_device_id(((data or {}).get("device") or {}).get("bbb_device_id", ""))
            if opcode == 8:
                self._send(handle_check_dlc(), "CHECK_DLC")
            elif opcode == 10:
                resp, save = handle_auth_login(bbb_device_id, bbb_device_id)
                self._send(resp, f"AUTH_LOGIN account={save['account_id']}")
            else:
                self._send([], f"unhandled msm2auth opcode={opcode}")
            return

        if segment == "msm2rh":
            token = self._bearer()
            save = find_save_by_token(token)
            data = self._decoded(body_text)
            if save is None or not isinstance(data, list):
                self._send([])
                return
            item = data[0]
            request_type = item.get("request")
            if request_type == "submitCommand":
                codes = [c.get("command") for c in (item.get("data") or {}).get("commands", [])]
                resp = handle_submit_command(save, item)
                self._send(resp, f"account={save['account_id']} commands={codes}")
            elif request_type == "playerSync":
                resp = handle_player_sync(save)
                self._send(resp, f"account={save['account_id']} playerSync")
            else:
                self._send([], f"unhandled msm2rh request={request_type}")
            return

        self._send({"ok": True, "success": True}, "unmapped path")

    def do_GET(self):
        self.route()

    def do_POST(self):
        self.route()

    def log_message(self, format, *args):
        pass


def main():
    global _server
    _base_dir().mkdir(parents=True, exist_ok=True)
    _server = ThreadingHTTPServer(("127.0.0.1", PORT), DofHandler)
    try:
        _server.serve_forever()
    finally:
        _server.server_close()


def request_shutdown():
    global _server
    if _server is not None:
        threading.Thread(target=_server.shutdown, daemon=True).start()
        _server = None
        return True
    return False
