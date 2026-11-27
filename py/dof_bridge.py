import json
import os
import random
import secrets
import string
import threading
import time
import logging
import sys
import tempfile
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


CLIENT_ERROR_LOG_MAX_BYTES = 2 * 1024 * 1024


def client_error_log_path():
    return _base_dir() / "client_errors.log"


def record_client_error(text):
    text = (text or "").strip()
    if not text:
        return
    path = client_error_log_path()
    try:
        if path.exists() and path.stat().st_size > CLIENT_ERROR_LOG_MAX_BYTES:
            path.unlink()
        with path.open("a", encoding="utf-8") as f:
            f.write("=== " + time.strftime("%Y-%m-%d %H:%M:%S") + "\n" + text + "\n")
    except OSError:
        pass


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
        schedule = next(
            i["schedule_instances"] for i in capture if i.get("type") == 1005
        )
        return coupons, server_text, schedule
    except Exception:
        return (
            {"dataFormat": 1, "couponsVersionId": 0, "coupons": []},
            {},
            {"rs": []},
        )


STATIC_COUPON_LIST, STATIC_SERVER_TEXT, STATIC_SCHEDULE_INSTANCES = (
    _load_static_auth_data()
)


def _static_auth_data():
    global STATIC_COUPON_LIST, STATIC_SERVER_TEXT, STATIC_SCHEDULE_INSTANCES
    if not (STATIC_COUPON_LIST or {}).get("coupons"):
        STATIC_COUPON_LIST, STATIC_SERVER_TEXT, STATIC_SCHEDULE_INSTANCES = (
            _load_static_auth_data()
        )
    return STATIC_COUPON_LIST, STATIC_SERVER_TEXT, STATIC_SCHEDULE_INSTANCES


def _starter_quest_data():
    path = _base_dir() / "known_responses" / "msm2auth_10.json"
    try:
        records = json.loads(path.read_text(encoding="utf-8"))
        for record in records if isinstance(records, list) else []:
            if record.get("type") == 16:
                quests = (record.get("sync_data") or {}).get("quests")
                if isinstance(quests, dict):
                    return json.loads(json.dumps(quests))
    except (OSError, ValueError, TypeError):
        pass
    return None


ALWAYS_ON_YEARS = 10


def _always_on_schedule(schedule):
    schedule = json.loads(json.dumps(schedule or {"rs": []}))
    now_ms = int(time.time() * 1000)
    start = now_ms - 24 * 3600 * 1000
    end = now_ms + ALWAYS_ON_YEARS * 365 * 24 * 3600 * 1000
    for instance in schedule.get("rs") or []:
        if isinstance(instance, dict):
            instance["start_time"] = start
            instance["event_start_times"] = [{"start": start, "end": end}]
    return schedule


ALWAYS_AVAILABLE_COUPON_BASE_ID = 900000
UNCOUPONED_LOCKED_IDS = [
    288,
    347,
    460,
    485,
    518,
    543,
    3489,
    3511,
    3512,
    3513,
    3514,
    3515,
    3516,
    3517,
    3518,
    3519,
    3520,
    3521,
    3522,
    3523,
]
WIDEST_UNLOCK_COMMANDS = (1100, 1307, 1308, 1600, 1601, 1800)


def _always_available_coupons(coupon_list):
    coupon_list = json.loads(json.dumps(coupon_list or {}))
    coupons = coupon_list.get("coupons")
    if not isinstance(coupons, list) or not coupons:
        return coupon_list
    groups = {}
    template = None
    for coupon in coupons:
        if not isinstance(coupon, dict):
            continue
        entities = [e for e in coupon.get("validEntities") or [] if isinstance(e, int)]
        commands = coupon.get("commandList") or []
        if not entities or not commands:
            continue
        if template is None:
            template = coupon
        key = (tuple(sorted(coupon.get("validIslands") or [])), tuple(sorted(commands)))
        groups.setdefault(key, set()).update(entities)
    if template is None:
        return coupon_list
    widest = ((), WIDEST_UNLOCK_COMMANDS)
    groups.setdefault(widest, set()).update(UNCOUPONED_LOCKED_IDS)
    now_ms = int(time.time() * 1000)
    window = {
        "start": now_ms - 24 * 3600 * 1000,
        "end": now_ms + ALWAYS_ON_YEARS * 365 * 24 * 3600 * 1000,
    }
    for index, ((islands, commands), entities) in enumerate(
        sorted(groups.items(), key=lambda kv: kv[0]), start=1
    ):
        coupon = json.loads(json.dumps(template))
        coupon.update(
            {
                "id": ALWAYS_AVAILABLE_COUPON_BASE_ID + index,
                "name": "Always Available",
                "gold": 100,
                "diamond": 100,
                "xp": 100,
                "rare": 100,
                "time": 100,
                "requirements": 100,
                "piggy": 100,
                "canShowToast": False,
                "toastDuration": 0,
                "toastShowOptions": 0,
                "showAlways": False,
                "validTime": dict(window),
                "commandList": list(commands),
                "validStrings": [],
                "validEntities": sorted(entities),
            }
        )
        if islands:
            coupon["validIslands"] = list(islands)
        else:
            coupon.pop("validIslands", None)
        coupons.append(coupon)
    return coupon_list


ISLAND_GRIDS = {
    0: [0],
    1: [0, 1, 2, 3, 4, 5, 6, 100],
    2: [0, 99],
    3: [0, 1, 2, 3, 99, 4, 5, 6, 7, 8, 9],
    37: [0, 1],
    70: [5, 6, 4, 3, 1, 2, 0, 99, 7],
    95: [0, 1, 2, 3, 99, 4, 5, 6],
    96: [0, 1, 2, 3, 4, 5, 6, 7, 8],
}


_placeable_cache = None


def _placeable_map():
    global _placeable_cache
    if _placeable_cache is not None:
        return _placeable_cache
    try:
        entries = json.loads(
            (_base_dir() / "dof_entity_catalog.json").read_text(encoding="utf-8")
        )["entities"]
    except Exception:
        return {}
    if not any("placeable" in e for e in entries):
        return {}
    _placeable_cache = {e["id"]: e.get("placeable") for e in entries}
    return _placeable_cache


def repair_islands(save):
    changed = False
    placeable = _placeable_map()
    islands = ((save.get("sync_data") or {}).get("islands") or {}).get("islands") or []
    starter = _starter_island()
    starter_by_kind = {}
    if isinstance(starter, dict) and starter.get("id") == 1:
        for key in ("monsters", "structures"):
            for entity in starter.get(key) or []:
                if isinstance(entity, dict):
                    starter_by_kind.setdefault(key, {}).setdefault(
                        entity.get("databasae_id"), entity
                    )
    required_structures = (216, 226, 286)
    required_monsters = (206, 281)
    for island in islands:
        if not isinstance(island, dict):
            continue
        if not isinstance(island.get("decorations"), list):
            island["decorations"] = []
            changed = True
        if not isinstance(island.get("collection"), dict):
            island["collection"] = {"contents": [], "timestamps": []}
            changed = True
        for key in ("monsters", "structures", "decorations"):
            entities = island.get(key)
            if not isinstance(entities, list) or not placeable:
                continue
            valid_entities = [
                e
                for e in entities
                if not isinstance(e, dict)
                or e.get("databasae_id") not in placeable
                or placeable[e.get("databasae_id")]
            ]
            if len(valid_entities) != len(entities):
                island[key] = valid_entities
                changed = True
        if island.get("id") == 1:
            for kind, required in (
                ("structures", required_structures),
                ("monsters", required_monsters),
            ):
                present = {
                    e.get("databasae_id")
                    for e in island.get(kind) or []
                    if isinstance(e, dict)
                }
                for entity_id in required:
                    if entity_id in present:
                        continue
                    template = starter_by_kind.get(kind, {}).get(entity_id)
                    if template is None and entity_id == CASTLE_ID:
                        instance_id = next_instance_id(save)
                        entity = _castle_entity(instance_id)
                    elif template is None:
                        continue
                    else:
                        instance_id = next_instance_id(save)
                        entity = json.loads(json.dumps(template))
                        entity["instance_id"] = instance_id
                        if kind == "monsters":
                            entity["level"] = max(4, int(entity.get("level") or 1))
                    island.setdefault(kind, []).append(entity)
                    present.add(entity_id)
                    changed = True

            for monster in island.get("monsters") or []:
                if (
                    isinstance(monster, dict)
                    and monster.get("databasae_id") in required_monsters
                ):
                    if int(monster.get("level") or 1) < 4:
                        monster["level"] = 4
                        changed = True
            if (
                isinstance(island.get("grids"), list)
                and CASTLE_GRID not in island["grids"]
            ):
                island["grids"].append(CASTLE_GRID)
                changed = True
        valid = ISLAND_GRIDS.get(island.get("id"))
        if valid is None:
            continue
        if not isinstance(island.get("grids"), list):
            continue
        kept = [g for g in island["grids"] if g in valid]
        if kept != island["grids"]:
            island["grids"] = kept
            changed = True
        fallback = kept[0] if kept else None
        for key in ("monsters", "structures", "decorations"):
            for entity in island.get(key) or []:
                if (
                    isinstance(entity, dict)
                    and "grid_id" in entity
                    and entity["grid_id"] not in kept
                    and fallback is not None
                ):
                    entity["grid_id"] = fallback
                    changed = True
    return changed


def set_active_device(device_id):
    global _active_device_id
    _active_device_id = device_id or None


def _manifest_active_device():
    try:
        manifest = json.loads(
            (_base_dir() / "saves_manifest.json").read_text(encoding="utf-8")
        )
    except (OSError, ValueError):
        return None
    active = manifest.get("activeSlotId")
    for slot in manifest.get("slots") or []:
        if slot.get("id") == active and slot.get("occupied") and slot.get("deviceId"):
            return slot["deviceId"]
    return None


def _resolve_device_id(client_supplied):
    return _manifest_active_device() or _active_device_id or client_supplied


def _rand_id(n=12, alphabet=string.ascii_lowercase + string.digits):
    return "".join(random.choice(alphabet) for _ in range(n))


CASTLE_ID = 286
CASTLE_GRID = 5
STARTER_CURRENCY = 1999999999


def _starter_island():
    path = _base_dir() / "known_responses" / "starter_island.json"
    try:
        island = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None
    if island.get("id") != 1 or not island.get("structures"):
        return None
    for entity in island.get("structures", []):
        rng = (entity.get("craft") or {}).get("rng")
        if isinstance(rng, dict):
            rng["s2"] = random.randint(1, 2**31 - 1)
    return island


def _castle_entity(instance_id):
    return {
        "databasae_id": CASTLE_ID,
        "instance_id": instance_id,
        "grid_id": CASTLE_GRID,
        "x": 1,
        "y": 1,
        "muted": False,
        "volume": 100,
        "flip": False,
        "scaleX": 64,
        "scaleY": 64,
        "specialAcquisition": False,
        "busy": False,
        "craft": {
            "start": 0,
            "slots": 1,
            "rng": {"s1": 1, "s2": random.randint(1, 2**31 - 1), "s3": 0, "s4": 0},
            "queue": [],
        },
        "level": 1,
    }


def _max_instance_id(island):
    ids = [
        e.get("instance_id", 0)
        for key in ("monsters", "structures", "decorations")
        for e in island.get(key) or []
        if isinstance(e, dict)
    ]
    return max([i for i in ids if isinstance(i, int)] or [0])


def _fresh_save(device_id, bbb_device_id):
    now_ms = int(time.time() * 1000)
    now_s = int(time.time())
    account_id = _rand_id(10)
    user_game_id = _rand_id(10)
    friend_code = "".join(
        random.choice("ABCDEFGHJKLMNPQRSTUVWXYZ23456789") for _ in range(8)
    )
    player_user = "".join(
        random.choice(string.ascii_uppercase + string.digits) for _ in range(8)
    )

    starter_island = {
        "id": 1,
        "grids": [3, 5],
        "monsters": [
            {
                "databasae_id": 281,
                "instance_id": 1,
                "grid_id": 3,
                "x": 14,
                "y": 15,
                "muted": False,
                "volume": 100,
                "flip": False,
                "scaleX": 64,
                "scaleY": 64,
                "specialAcquisition": False,
                "busy": False,
                "name": "",
                "level": 1,
                "xp": 0,
                "request": 0,
                "costume": 0,
                "cave": False,
                "costume_equipped": False,
                "favorite": False,
                "player_favourite": False,
                "favorite_lockout": {},
                "cached_coins": 0,
                "likes": [],
            },
        ],
        "structures": [
            {
                "databasae_id": 185,
                "instance_id": 2,
                "grid_id": 3,
                "x": 6,
                "y": 21,
                "muted": False,
                "volume": 100,
                "flip": False,
                "scaleX": 64,
                "scaleY": 64,
                "specialAcquisition": False,
                "busy": False,
                "craft": {
                    "start": 0,
                    "slots": 1,
                    "rng": {
                        "s1": 1,
                        "s2": random.randint(1, 2**31 - 1),
                        "s3": 0,
                        "s4": 0,
                    },
                    "queue": [],
                },
                "level": 1,
            },
        ],
        "decorations": [],
        "collection": {"contents": [], "timestamps": []},
    }
    official = _starter_island()
    if official is not None:
        starter_island = official
    elif not any(
        e.get("databasae_id") == CASTLE_ID for e in starter_island["structures"]
    ):
        starter_island["structures"].append(_castle_entity(3))
    counter = max(3, _max_instance_id(starter_island))

    starter_quests = _starter_quest_data()
    return {
        "account_id": account_id,
        "username": _rand_id(12),
        "password": _rand_id(20),
        "user_game_id": user_game_id,
        "friend_code": friend_code,
        "device_id": device_id,
        "bbb_device_id": bbb_device_id,
        "login_index": 0,
        "instance_counter": counter,
        "sync_data": {
            "versionCode": 18343,
            "islands": {
                "islands": [
                    {
                        "id": 0,
                        "monsters": [],
                        "structures": [],
                        "decorations": [],
                        "collection": {"contents": [], "timestamps": []},
                    },
                    starter_island,
                ]
            },
            "quests": starter_quests
            or {
                "questCounter": -1,
                "questRNG": {
                    "s1": random.randint(1, 2**31 - 1),
                    "s2": 0,
                    "s3": 0,
                    "s4": 0,
                },
                "serverRNG": {
                    "s1": random.randint(1, 2**31 - 1),
                    "s2": 0,
                    "s3": 0,
                    "s4": 0,
                },
                "orders": [],
                "active_quests": [],
                "completed_quests": [],
                "collected_quests": [],
                "active_achievements": [],
                "serverQuestCounter": 0,
            },
            "player_info": {
                "islands": [0, 1],
                "banned": False,
                "csr_confirmed": False,
                "auth_timestamp": 0,
                "suspicious": False,
                "internal": False,
                "banned_date": 0,
                "user": player_user,
                "friend_code": friend_code,
                "date_created": now_ms,
                "level": 1,
                "loadedSession": 0,
                "loadedSequence": 0,
                "tutorial_complete": False,
                "admin_mail_id": "",
                "last_login": now_ms,
                "last_save": 0,
                "static_data_version": 18437,
                "client_version": 18343,
                "client_hash": "",
                "airshipShippingTickets": 0,
                "airshipAssistTickets": 0,
                "shippingMonthlyTickets": 0,
                "assistMonthlyTickets": 0,
                "last_batch": 0,
                "user_game_id": user_game_id,
                "session_device": {
                    "bbb_device_id": bbb_device_id,
                    "platform": "android",
                    "device_identifiers": {"advertising_id": ""},
                },
                "current_response": "[]",
                "last_breeding_combos": [],
            },
            "inventory": {
                "myGlobalRNG": {
                    "s1": random.randint(1, 2**31 - 1),
                    "s2": 0,
                    "s3": 0,
                    "s4": 0,
                },
                "instanceCounter": counter,
                "inv_items": {
                    "contents": [
                        [CURRENCY_COINS, STARTER_CURRENCY],
                        [CURRENCY_DIAMONDS, STARTER_CURRENCY],
                        [779, 0],
                    ],
                    "timestamps": [],
                },
                "escrow_items": {"contents": [], "timestamps": []},
                "storage": {"storage": [], "storage2": []},
            },
            "spinners": {"freeSpin": 1, "days": 0, "data": []},
            "tester": {"activeTime": 0, "accountCreation": now_s},
            "ad_segment_data": {"segment_data": []},
            "voterBox": {
                "voterBox": {
                    "votes": [],
                    "canReset": False,
                    "timestamp": 0,
                    "latestReset": 0,
                }
            },
            "global_wants": {"global_wants": []},
            "completed_global_wants": {"completed_global_wants": []},
            "market": {
                "market": {
                    "owner": {"user": player_user, "name": ""},
                    "size": 5,
                    "items": [],
                    "boatRequests": [],
                    "modified": 0,
                    "sales": [],
                    "boatAssists": [],
                }
            },
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


def _iter_saves():
    for path in _saves_dir().glob("*.json"):
        try:
            save = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, ValueError):
            logger.warning("skipping unreadable save %s", path.name)
            continue
        if isinstance(save, dict):
            yield save


def find_save_by_token(token):
    for save in _iter_saves():
        if save.get("access_token") == token:
            return save
    return None


def write_save(save):
    path = _save_path(save["device_id"])
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(save, indent=2)

    with tempfile.NamedTemporaryFile(
        "w",
        encoding="utf-8",
        dir=path.parent,
        prefix=path.name + ".",
        suffix=".tmp",
        delete=False,
    ) as fh:
        temp_path = Path(fh.name)
        fh.write(payload)
        fh.flush()
        os.fsync(fh.fileno())
    os.replace(temp_path, path)


_save_lock = threading.RLock()
_client_known = {}
_session_device = None
_ENTITY_LISTS = ("monsters", "structures", "decorations")


def _same(a, b):
    if isinstance(a, bool) or isinstance(b, bool):
        return type(a) is type(b) and a == b
    if isinstance(a, (int, float)) and isinstance(b, (int, float)):
        return float(a) == float(b)
    if isinstance(a, dict) and isinstance(b, dict):
        return a.keys() == b.keys() and all(_same(a[k], b[k]) for k in a)
    if isinstance(a, list) and isinstance(b, list):
        return len(a) == len(b) and all(_same(x, y) for x, y in zip(a, b))
    return a == b


def _array_key(*arrays):
    items = [item for arr in arrays if isinstance(arr, list) for item in arr]
    if not items:
        return None
    if all(isinstance(i, dict) and "instance_id" in i for i in items):
        return (lambda i: i.get("instance_id") if isinstance(i, dict) else None), True
    if all(isinstance(i, dict) and "id" in i for i in items):
        return (lambda i: i.get("id") if isinstance(i, dict) else None), False
    if all(
        isinstance(i, list)
        and len(i) == 2
        and isinstance(i[0], (int, float))
        and not isinstance(i[0], bool)
        for i in items
    ):
        return (lambda i: i[0] if isinstance(i, list) and i else None), False
    return None


def _merge_array(mine, base, theirs, key, from_game):
    key_of, distinct_new = key
    base_by = {key_of(i): i for i in (base or []) if key_of(i) is not None}
    theirs_by = {key_of(i): i for i in theirs if key_of(i) is not None}
    mine_ids = set()
    result, extra = [], []
    for item in mine:
        item_id = key_of(item)
        if item_id is None:
            result.append(item)
            continue
        mine_ids.add(item_id)
        b = base_by.get(item_id)
        t = theirs_by.get(item_id)
        if t is None:
            if b is None or not _same(item, b):
                result.append(item)
        elif b is None and distinct_new and not _same(item, t):
            result.append(item)
            copy = json.loads(json.dumps(t))
            from_game.append(copy)
            extra.append(copy)
        elif isinstance(item, dict) and isinstance(t, dict):
            _merge_object(item, b if isinstance(b, dict) else None, t, from_game)
            result.append(item)
        elif isinstance(item, list) and isinstance(t, list):
            result.append(json.loads(json.dumps(t)) if _same(item, b) else item)
        else:
            result.append(item)
    for item_id, t in theirs_by.items():
        if item_id not in mine_ids and item_id not in base_by:
            copy = json.loads(json.dumps(t))
            from_game.append(copy)
            result.append(copy)
    result.extend(extra)
    mine[:] = result


def _merge_object(mine, base, theirs, from_game):
    for key, t in theirs.items():
        b = base.get(key) if isinstance(base, dict) else None
        m = mine.get(key)
        if (
            key in ("instance_counter", "instanceCounter")
            and isinstance(m, int)
            and isinstance(t, int)
        ):
            mine[key] = max(m, t)
            continue
        if b is not None and _same(t, b):
            continue
        if key not in mine:
            mine[key] = json.loads(json.dumps(t))
            continue
        if isinstance(m, dict) and isinstance(t, dict):
            _merge_object(m, b if isinstance(b, dict) else None, t, from_game)
            continue
        if isinstance(m, list) and isinstance(t, list):
            key_fn = _array_key(m, t, b if isinstance(b, list) else None)
            if key_fn is not None:
                _merge_array(
                    m, b if isinstance(b, list) else None, t, key_fn, from_game
                )
                continue
        if b is None or _same(m, b):
            mine[key] = json.loads(json.dumps(t))


def _renumber_clashes(save, from_game):
    islands = ((save.get("sync_data") or {}).get("islands") or {}).get("islands") or []
    groups = {}
    for island in islands:
        if not isinstance(island, dict):
            continue
        for list_name in _ENTITY_LISTS:
            for entity in island.get(list_name) or []:
                if isinstance(entity, dict) and isinstance(
                    entity.get("instance_id"), int
                ):
                    groups.setdefault(entity["instance_id"], []).append(entity)
    game_ids = {id(e) for e in from_game}
    clashes = []
    for group in groups.values():
        if len(group) < 2:
            continue
        keep = next((e for e in group if id(e) in game_ids), group[0])
        clashes.extend(e for e in group if e is not keep)
    if not clashes:
        return
    counter = max([save.get("instance_counter") or 0] + list(groups))
    for entity in clashes:
        counter += 1
        entity["instance_id"] = counter
    save["instance_counter"] = counter
    inventory = (save.get("sync_data") or {}).get("inventory")
    if isinstance(inventory, dict):
        inventory["instanceCounter"] = counter


def merge_into_save(save, base_sync, theirs_sync):
    from_game = []
    _merge_object(save["sync_data"], base_sync, theirs_sync, from_game)
    _renumber_clashes(save, from_game)


def _looks_like_sync_data(state, current):
    if not isinstance(state, dict) or not isinstance(current, dict):
        return False
    islands = state.get("islands")
    if not isinstance(islands, dict) or not isinstance(islands.get("islands"), list):
        return False
    if not isinstance(state.get("inventory"), dict):
        return False
    shared = len(set(state) & set(current))
    return shared * 2 >= len(set(state))


def set_session_device(device_id):
    global _session_device
    _session_device = device_id


def remember_client_state(device_id, sync_data):
    _client_known[device_id] = json.loads(json.dumps(sync_data))


def track_server_changes(device_id, before_sync, after_sync):
    known = _client_known.get(device_id)
    if known is not None:
        _merge_object(known, before_sync, after_sync, [])


def apply_client_state(state):
    device_id = _session_device
    if not device_id:
        return "no session"
    with _save_lock:
        path = _save_path(device_id)
        if not path.exists():
            return "no save"
        save = json.loads(path.read_text(encoding="utf-8"))
        if not _looks_like_sync_data(state, save.get("sync_data")):
            logger.warning(
                "client state ignored, unexpected shape: keys=%s",
                sorted(state)[:40] if isinstance(state, dict) else type(state).__name__,
            )
            return "ignored"
        base = _client_known.get(device_id)
        if base is None:
            base = json.loads(json.dumps(save["sync_data"]))
        merge_into_save(save, base, state)
        write_save(save)
        remember_client_state(device_id, state)
        return "merged"


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


def _cmd_entity_sell(save, cmd):
    entity_id = cmd.get("entity", cmd.get("instance_id"))
    for island in save["sync_data"]["islands"]["islands"]:
        if not isinstance(island, dict):
            continue
        for key in ("monsters", "structures", "decorations"):
            entities = island.get(key) or []
            for index, entity in enumerate(entities):
                if isinstance(entity, dict) and entity.get("instance_id") == entity_id:
                    entities.pop(index)

                    inv_add(save, CURRENCY_COINS, int(cmd.get("refund", 0) or 0))
                    return []
    return []


def _cmd_tutorial_complete(save, cmd):
    save["sync_data"].setdefault("player_info", {})["tutorial_complete"] = True
    return []


def _cmd_global_want_reset(save, cmd):
    wants = (
        save["sync_data"].setdefault("global_wants", {}).setdefault("global_wants", [])
    )
    for want in wants:
        if isinstance(want, dict):
            want["count"] = 0
            want["reset"] = True
    return []


def _cmd_global_want_reward(save, cmd):
    completed = (
        save["sync_data"]
        .setdefault("completed_global_wants", {})
        .setdefault("completed_global_wants", [])
    )
    wants = (
        save["sync_data"].setdefault("global_wants", {}).setdefault("global_wants", [])
    )
    index = cmd.get("index", cmd.get("want", 0))
    want = next(
        (
            w
            for w in wants
            if isinstance(w, dict)
            and (w.get("index") == index or w.get("instance") == index)
        ),
        None,
    )
    if want is not None and int(want.get("count") or 0) >= int(
        want.get("required") or 0
    ):
        reward_id = int(want.get("reward_id") or CURRENCY_COINS)
        inv_add(save, reward_id, int(want.get("reward_count") or 0))
        completed.append(json.loads(json.dumps(want)))
        wants.remove(want)
    return []


def _cmd_structure_speedup(save, cmd):
    entity = find_entity(save, cmd.get("entity"))
    if entity and "craft" in entity:
        entity["craft"]["start"] = 0
    return []


TOGGLE_DEFAULTS = {
    "monster_level_enabled": False,
    "monster_level": 10,
    "all_items_available": True,
    "events_always_on": True,
}


def dof_toggles():
    toggles = dict(TOGGLE_DEFAULTS)
    try:
        stored = json.loads(
            (_base_dir() / "dof_toggles.json").read_text(encoding="utf-8")
        )
    except (OSError, ValueError):
        stored = {}
    if isinstance(stored, dict):
        toggles.update({k: stored[k] for k in TOGGLE_DEFAULTS if k in stored})
    return toggles


def _toggle_monster_level():
    toggles = dof_toggles()
    if not toggles.get("monster_level_enabled"):
        return None
    try:
        return max(1, int(toggles.get("monster_level") or 1))
    except (TypeError, ValueError):
        return None


def raise_monster_levels(save):
    target = _toggle_monster_level()
    if target is None:
        return False
    changed = False
    for island in ((save.get("sync_data") or {}).get("islands") or {}).get(
        "islands"
    ) or []:
        for monster in (
            (island.get("monsters") or []) if isinstance(island, dict) else []
        ):
            if isinstance(monster, dict) and (monster.get("level") or 0) < target:
                monster["level"] = target
                changed = True
    return changed


def _cmd_entity_buy(save, cmd):

    islands = save["sync_data"]["islands"]["islands"]
    island = next((i for i in islands if i.get("id") == cmd.get("island")), islands[-1])
    new_id = next_instance_id(save)
    item_id = cmd.get("item", 0)
    is_monster = _entity_is_monster(item_id)
    entity = {
        "databasae_id": item_id,
        "instance_id": new_id,
        "grid_id": cmd.get("grid", 3),
        "x": cmd.get("x", 0),
        "y": cmd.get("y", 0),
        "muted": False,
        "volume": 100,
        "flip": cmd.get("flip", False),
        "scaleX": 64,
        "scaleY": 64,
        "specialAcquisition": False,
        "busy": False,
        "level": 1,
    }
    if is_monster:
        entity["level"] = _toggle_monster_level() or entity["level"]
        entity.update(
            {
                "name": "",
                "xp": 0,
                "request": 0,
                "costume": 0,
                "cave": False,
                "costume_equipped": False,
                "favorite": False,
                "player_favourite": False,
                "favorite_lockout": {},
                "cached_coins": 0,
                "likes": [],
            }
        )
        island.setdefault("monsters", []).append(entity)
    else:
        entity["craft"] = {
            "start": 0,
            "slots": 1,
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
    return [
        {
            "command": 1134,
            "when": now_ms,
            "bonusBoard": {
                "rng": {"s1": random.randint(1, 2**31 - 1), "s2": 0, "s3": 0, "s4": 0},
                "position": 0,
                "lastCollected": 0,
                "activeBoard": 880,
                "expiry": now_ms + 216000000,
            },
        }
    ]


COMMAND_HANDLERS = {
    1101: _cmd_entity_move,
    1106: _cmd_entity_rename,
    1103: _cmd_entity_mute,
    1110: _cmd_entity_favorite,
    1111: _cmd_entity_favorite_refresh,
    1113: _cmd_entity_collect,
    1102: _cmd_entity_sell,
    1104: _cmd_structure_speedup,
    1100: _cmd_entity_buy,
    322: _cmd_tokens_collect,
    1133: _cmd_bonus_new_board,
    605: _cmd_tutorial_complete,
    1413: _cmd_global_want_reset,
    1414: _cmd_global_want_reward,
}


def _housekeeping_ack(save):
    now_ms = int(time.time() * 1000)
    mail = save["sync_data"]["mail"]["mail"]
    token_count = inv_get(save, 779)
    return [
        {
            "command": 320,
            "when": now_ms,
            "data": {
                "mail": mail.get("mail", []),
                "last_timestamp": mail.get("last_timestamp", 0),
                "checkMail": True,
            },
        },
        {
            "command": 9001,
            "when": now_ms,
            "data": {
                "targetQueue": 5,
                "targetDelay": 15,
                "warnQueue": 25,
                "warnDelay": 60,
                "maxQueue": 200,
                "maxDelay": 3600,
                "repeatLimit": 100,
                "readOnly": False,
                "altersPlayer": True,
                "requiresInOrder": True,
                "requireSync": False,
                "requireServer": False,
                "debugSettings": {"DEBUG_PLAYER_RNG": 1, "DEBUG_PLAYER_XP": 1},
            },
        },
        {"command": 1730, "when": now_ms, "nextReset": now_ms},
        {
            "command": 323,
            "when": now_ms,
            "data": {
                "token": [{"time": now_ms, "entity": 779, "count": token_count}],
                "last_timestamp": 0,
            },
        },
    ]


def handle_submit_command(save, batch_item):
    commands = (batch_item.get("data") or {}).get("commands") or []
    extra = []
    before = json.loads(json.dumps(save["sync_data"]))
    for cmd in commands:
        code = cmd.get("command")
        handler = COMMAND_HANDLERS.get(code)
        if handler:
            extra.extend(handler(save, cmd) or [])
    write_save(save)
    track_server_changes(save["device_id"], before, save["sync_data"])
    return [{"type": 101, "commands": {"commands": _housekeeping_ack(save) + extra}}]


def handle_player_sync(save):
    return [{"type": 104, "clock": int(time.time() * 1000)}]


def handle_check_dlc():
    return [
        {
            "type": 1002,
            "address": "https://dlc2.bbbgame.net/monster_babies/dlc/00018437-93908becfd29/android/",
            "version": 18437,
            "minVersion": 18343,
        },
        {"type": 104, "clock": int(time.time() * 1000)},
    ]


def handle_auth_login(device_id, bbb_device_id):
    save = load_or_create_save(device_id, bbb_device_id)
    repair_islands(save)
    raise_monster_levels(save)
    toggles = dof_toggles()
    coupons, server_text, schedule = _static_auth_data()
    if toggles.get("events_always_on"):
        schedule = _always_on_schedule(schedule)
    if toggles.get("all_items_available"):
        coupons = _always_available_coupons(coupons)
    save["login_index"] += 1
    save["sync_data"]["player_info"]["last_login"] = int(time.time() * 1000)
    write_save(save)
    set_session_device(save["device_id"])
    remember_client_state(save["device_id"], save["sync_data"])
    return [
        {
            "type": 16,
            "server": "",
            "id": "",
            "index": save["login_index"],
            "prev_session": 0,
            "prev_sequence": 0,
            "date_created": int(time.time() * 1000),
            "sync_data": save["sync_data"],
        },
        {"type": 1003, "coupon_list": coupons},
        {"type": 1004, "server_text": server_text},
        {
            "type": 1005,
            "last_updated_timestamp": int(time.time()),
            "schedule_instances": schedule,
            "next_schedule_refresh": int(time.time()) + 3600,
        },
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

    def _send_plain(self, text):
        payload = text.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        try:
            self.wfile.write(payload)
        except (BrokenPipeError, ConnectionResetError, ConnectionAbortedError):

            logger.debug("Client disconnected before the plain response was sent")

    def _send(self, body_obj, log_note=""):
        payload = json.dumps(body_obj).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        try:
            self.wfile.write(payload)
        except (BrokenPipeError, ConnectionResetError, ConnectionAbortedError):
            logger.debug("Client disconnected before the JSON response was sent")
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
        if segment == "nps_client_error":
            record_client_error(body_text)
            self._send_plain("ok")
            return
        if segment == "nps_state":
            try:
                outcome = apply_client_state(json.loads(body_text))
            except Exception as exc:
                outcome = f"failed {type(exc).__name__}: {exc}"
            logger.info("STATE push %d bytes: %s", len(body_text), outcome)
            self._send_plain("ok")
            return
        logger.info("REQ %s %s body=%s", self.command, self.path, body_text[:800])
        try:
            with _traffic_log().open("a", encoding="utf-8") as _f:
                _f.write(
                    json.dumps(
                        {
                            "time": time.strftime("%Y-%m-%d %H:%M:%S"),
                            "REQUEST": self.command,
                            "path": self.path,
                            "headers": {k: v for k, v in self.headers.items()},
                            "body": body_text[:2000],
                        }
                    )
                    + "\n"
                )
        except Exception:
            pass

        if segment == "game_config":
            self._send(
                {
                    "ok": True,
                    "config": {
                        "login_types": [
                            {
                                "type": "anon",
                                "auto_create": True,
                                "can_bind_to": False,
                                "can_create": True,
                            },
                            {
                                "type": "gp",
                                "auto_create": False,
                                "can_bind_to": True,
                                "can_create": True,
                            },
                        ],
                        "type": "android",
                        "age_gate_consent_required": False,
                        "gdpr_consent_required": False,
                    },
                    "geo": "BR",
                    "gag": 13,
                }
            )
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
            try:
                save = (
                    json.loads(path.read_text(encoding="utf-8"))
                    if path.exists()
                    else None
                )
            except (OSError, ValueError):
                save = None
            if isinstance(save, dict) and isinstance(requested, list):
                for login in requested:
                    if not isinstance(login, dict):
                        continue
                    u = str(login.get("u") or "")
                    p = str(login.get("p") or "")
                    if (
                        u
                        and p
                        and u == save.get("username")
                        and p == save.get("password")
                    ):
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
            self._send(
                {
                    "ok": True,
                    "username": save["username"],
                    "password": save["password"],
                    "account_id": save["account_id"],
                    "user_game_id": save["user_game_id"],
                    "login_type": "anon",
                    "time_created": int(time.time()),
                    "access_token": token,
                    "token_type": "bearer",
                    "expires_at": int(time.time()) + 1200,
                    "device_updated": True,
                },
                f"account={save['account_id']}",
            )
            return

        if segment == "token":
            q = dict(parse_qs(body_text))
            username = (q.get("u") or [""])[0]
            match = None
            active = _manifest_active_device() or _active_device_id
            if active:
                match = load_or_create_save(active, active)
            else:
                match = next(
                    (
                        save
                        for save in _iter_saves()
                        if save.get("username") == username
                    ),
                    None,
                )
            if match is None:
                self._send({"ok": False}, "unknown user")
                return
            token = secrets.token_urlsafe(64)
            match["access_token"] = token
            write_save(match)
            self._send(
                {
                    "ok": True,
                    "user_game_id": [match["user_game_id"]],
                    "login_types": "[]",
                    "access_token": token,
                    "token_type": "bearer",
                    "expires_at": int(time.time()) + 1200,
                },
                f"account={match['account_id']}",
            )
            return

        if segment == "msm2auth":
            data = self._decoded(body_text)
            if isinstance(data, list):
                data = data[0]
            opcode = data.get("request") if data else None
            bbb_device_id = _resolve_device_id(
                ((data or {}).get("device") or {}).get("bbb_device_id", "")
            )
            if opcode == 8:
                self._send(handle_check_dlc(), "CHECK_DLC")
            elif opcode == 10:
                with _save_lock:
                    resp, save = handle_auth_login(bbb_device_id, bbb_device_id)
                self._send(resp, f"AUTH_LOGIN account={save['account_id']}")
            else:
                self._send([], f"unhandled msm2auth opcode={opcode}")
            return

        if segment == "msm2rh":
            token = self._bearer()
            data = self._decoded(body_text)
            with _save_lock:
                save = find_save_by_token(token)
                if save is None or not isinstance(data, list) or not data:
                    self._send([])
                    return
                set_session_device(save["device_id"])
                item = data[0]
                request_type = item.get("request")
                if request_type == "submitCommand":
                    codes = [
                        c.get("command")
                        for c in (item.get("data") or {}).get("commands", [])
                    ]
                    resp = handle_submit_command(save, item)
                    self._send(resp, f"account={save['account_id']} commands={codes}")
                    return
            if request_type == "playerSync":
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
    server = ThreadingHTTPServer(("127.0.0.1", PORT), DofHandler)
    _server = server
    try:
        server.serve_forever()
    finally:
        server.server_close()
        if _server is server:
            _server = None


def request_shutdown():
    global _server
    server = _server
    if server is not None:
        _server = None
        threading.Thread(target=server.shutdown, daemon=True).start()
        return True
    return False
