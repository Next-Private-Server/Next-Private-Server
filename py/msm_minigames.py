import base64
import json
import random
import struct
import time
import zlib

from msm_playerdata import (
    append_inventory_property,
    create_player_properties,
    grant_inventory_item,
    load_player,
    save_player,
)
from msm_gamedata import get_monster_id_for_entity_id
from msm_store import load_db_json
import msm_toggles

DEFAULT_MINIGAME_ID = 1

TIMED_EVENT_ID = 82686
TIMED_EVENT_TYPE = "Minigame"

MINIGAME_THEMES = ("anniversary", "")
DEFAULT_MINIGAME_THEME = "anniversary"
MINIGAME_MIN_CLIENT_VER = "5.7.0"


def _minigame_theme():
    try:
        value = msm_toggles.get_toggles().get("minigame_theme")
    except Exception:
        value = None
    if isinstance(value, str) and value in MINIGAME_THEMES:
        return value
    return DEFAULT_MINIGAME_THEME


_CURRENCY_REWARD_KEYS = {
    "COINS": "coins",
    "FOOD": "food",
    "XP": "xp",
    "STARPOWER": "starpower",
    "SHARDS": "ethereal_currency",
}

_BONUS_MODE_TOKENS = {1: 1, 2: 1}
VIDEO_AD_BONUS_MODE = 2

_catalog_cache = {}


def _safe_int(value, default=0):
    try:
        return int(value)
    except (TypeError, ValueError, OverflowError):
        return default


def _minigame_tokens(player_object):
    return max(
        0,
        _safe_int(
            player_object.get(
                "minigame_tokens_actual", player_object.get("minigame_tokens", 0)
            )
        ),
    )


def _set_minigame_tokens(player_object, value):
    value = max(0, _safe_int(value))
    player_object["minigame_tokens"] = value
    player_object["minigame_tokens_actual"] = value
    return value


_levels_cache = {}


def _level_tiers(minigame_id):
    if minigame_id in _levels_cache:
        return _levels_cache[minigame_id]
    tiers = []
    db = load_db_json("db_minigames") or {}
    for entry in db.get("minigames_data") or []:
        if _safe_int(entry.get("id")) != minigame_id:
            continue
        for lv in entry.get("levels") or []:
            try:
                lv_data = json.loads(lv.get("data") or "{}")
            except (TypeError, ValueError):
                lv_data = {}
            tiers.append((_safe_int(lv.get("level"), 1), lv_data))
        break
    tiers.sort(key=lambda item: item[0])
    _levels_cache[minigame_id] = tiers
    return tiers


def _defined_level_keys(minigame_id):
    return sorted(
        {tier_level for tier_level, _ in _level_tiers(minigame_id) if tier_level > 0}
    )


def _safe_defined_level(minigame_id, level):
    defined = _defined_level_keys(minigame_id)
    if not defined:
        return max(1, _safe_int(level, 1) or 1)
    requested = _safe_int(level, defined[0]) or defined[0]
    safe = defined[0]
    for tier_level in defined:
        if tier_level > requested:
            break
        safe = tier_level
    return safe


def _num_states_for_level(minigame_id, level):
    for tier_level, lv in _level_tiers(minigame_id):
        if tier_level == level:
            states = lv.get("states")
            if isinstance(states, list) and states:
                return len(states)
    for _tier_level, lv in _level_tiers(minigame_id):
        states = lv.get("states")
        if isinstance(states, list) and states:
            return len(states)
    return 3


def _grid_dims_for_level(minigame_id, level):
    dims = (5, 5)
    for tier_level, lv_data in _level_tiers(minigame_id):
        if tier_level > level:
            break
        grid = lv_data.get("grid") or {}
        width = _safe_int(grid.get("playWidth"), 0)
        height = _safe_int(grid.get("playHeight"), 0)
        if width > 0 and height > 0:
            dims = (width, height)
    return dims


def _slots_for_level(minigame_id, level):
    monsters = 3
    for tier_level, lv_data in _level_tiers(minigame_id):
        if tier_level > level:
            break
        tier_monsters = _safe_int(lv_data.get("max_monsters"), 0)
        if tier_monsters > 0:
            monsters = tier_monsters
    return monsters


def _decode_cell_blob(blob, cell_count):
    if not blob:
        return [0] * cell_count
    try:
        raw = zlib.decompress(base64.b64decode(blob))
    except (TypeError, ValueError, zlib.error):
        return [0] * cell_count
    n = len(raw) // 4
    cells = list(struct.unpack(">%di" % n, raw[: n * 4])) if n else []
    if len(cells) < cell_count:
        cells.extend([0] * (cell_count - len(cells)))
    return cells[:cell_count]


def _encode_cell_blob(cells):
    raw = b"".join(struct.pack(">i", c) for c in cells)
    return base64.b64encode(zlib.compress(raw, 1)).decode("ascii")


def _decode_cell_blob_auto(blob):
    if not blob:
        return []
    try:
        raw = zlib.decompress(base64.b64decode(blob))
    except (TypeError, ValueError, zlib.error):
        return []
    n = len(raw) // 4
    return list(struct.unpack(">%di" % n, raw[: n * 4])) if n else []


def _empty_grid_blob(cell_count):
    return _encode_cell_blob([0] * cell_count)


def _populated_grid_blob(minigame_id, cell_count, slot_count, width=None, height=None):
    catalog = _catalog(minigame_id)
    cells = [0] * cell_count
    corner_indices = set()
    if width and height and width > 0 and height > 0:
        corner_indices = {0, width - 1, (height - 1) * width, height * width - 1}
    available = [i for i in range(cell_count) if i not in corner_indices]
    random.shuffle(available)
    placed = 0
    for idx in available:
        if placed >= slot_count:
            break
        entity_id = _roll_entity(catalog)
        if entity_id is None:
            continue
        cells[idx] = entity_id
        placed += 1
    return _encode_cell_blob(cells)


def _empty_minigame_data(minigame_id):
    width, height = _grid_dims_for_level(minigame_id, 1)
    slots = _slots_for_level(minigame_id, 1)
    loot_blob = _populated_grid_blob(minigame_id, width * height, slots, width, height)
    return json.dumps(
        {
            "gridState": _empty_grid_blob(width * height),
            "lootState": loot_blob,
            "level": 1,
            "version": 1,
            "seed": random.randint(-2147483648, 2147483647),
        }
    )


def _empty_minigame_stats():
    return json.dumps(
        {
            "levels_complete": 0,
            "top_levels_complete": 0,
            "timed_event_id": TIMED_EVENT_ID,
            "bonus_timings": [],
            "entities_obtained": {},
            "celestial_mercy": 0,
            "rare_mercy": 0,
            "epic_mercy": 0,
        }
    )


def _repair_legacy_minigame_entry(entry):
    minigame_id = (
        _safe_int(entry.get("minigame_id"), DEFAULT_MINIGAME_ID) or DEFAULT_MINIGAME_ID
    )
    try:
        data = json.loads(entry.get("data") or "{}")
    except (TypeError, ValueError):
        data = {}
    if (
        not isinstance(data, dict)
        or not data.get("gridState")
        or not data.get("lootState")
    ):
        entry["data"] = _empty_minigame_data(minigame_id)
        data = json.loads(entry["data"])
    elif data.get("gridState") == data.get(
        "lootState"
    ) and -1 not in _decode_cell_blob_auto(data.get("gridState") or ""):
        cell_count = len(zlib.decompress(base64.b64decode(data["lootState"]))) // 4
        data["gridState"] = _empty_grid_blob(cell_count)
        entry["data"] = json.dumps(data)
    if isinstance(data, dict) and data.get("gridState") and data.get("lootState"):
        level = _safe_int(data.get("level"), 1) or 1
        safe_level = _safe_defined_level(minigame_id, level)
        width, height = _grid_dims_for_level(minigame_id, safe_level)
        expected_cells = width * height
        grid_cells = _decode_cell_blob_auto(data.get("gridState") or "")
        loot_cells = _decode_cell_blob_auto(data.get("lootState") or "")
        if (
            level != safe_level
            or len(grid_cells) != expected_cells
            or len(loot_cells) != expected_cells
        ):
            slots = _slots_for_level(minigame_id, safe_level)
            data["level"] = safe_level
            data["gridState"] = _empty_grid_blob(expected_cells)
            data["lootState"] = _populated_grid_blob(
                minigame_id, expected_cells, slots, width, height
            )
            data["seed"] = random.randint(-2147483648, 2147483647)
            entry["data"] = json.dumps(data)
    try:
        stats = json.loads(entry.get("stats") or "{}")
    except (TypeError, ValueError):
        stats = {}
    if not isinstance(stats, dict) or "timed_event_id" not in stats:
        stats = stats if isinstance(stats, dict) else {}
        stats["timed_event_id"] = TIMED_EVENT_ID
        entry["stats"] = json.dumps(stats)


def _find_or_create_minigame(player_object, minigame_id):
    minigame_id = _safe_int(minigame_id, DEFAULT_MINIGAME_ID) or DEFAULT_MINIGAME_ID
    minigames = player_object.get("minigames")
    if not isinstance(minigames, list):
        minigames = []
        player_object["minigames"] = minigames
    for entry in minigames:
        if (
            isinstance(entry, dict)
            and _safe_int(entry.get("minigame_id")) == minigame_id
        ):
            _repair_legacy_minigame_entry(entry)
            return entry
    entry = {
        "minigame_id": minigame_id,
        "data": _empty_minigame_data(minigame_id),
        "stats": _empty_minigame_stats(),
    }
    minigames.append(entry)
    return entry


def _wire_entry(entry):
    return {
        "minigame_id": entry.get("minigame_id"),
        "data": entry.get("data") or "{}",
        "stats": entry.get("stats") or "{}",
    }


def _load_stats(entry):
    try:
        stats = json.loads(entry.get("stats") or "{}")
    except (TypeError, ValueError):
        stats = {}
    return stats if isinstance(stats, dict) else {}


def _load_entry_data(entry):
    try:
        data = json.loads(entry.get("data") or "{}")
    except (TypeError, ValueError):
        data = {}
    return data if isinstance(data, dict) else {}


def _catalog(minigame_id):
    if minigame_id in _catalog_cache:
        return _catalog_cache[minigame_id]
    catalog = {}
    db = load_db_json("db_minigames") or {}
    for entry in db.get("minigames_data") or []:
        if _safe_int(entry.get("id")) != minigame_id:
            continue
        try:
            catalog = json.loads(entry.get("data") or "{}")
        except (TypeError, ValueError):
            catalog = {}
        break
    _catalog_cache[minigame_id] = catalog
    return catalog


def _single_cell_ids(catalog, ids):
    info = catalog.get("entityInfo") or {}
    return [i for i in ids if _safe_int((info.get(str(i)) or {}).get("size"), 1) <= 1]


def _roll_entity(catalog):
    odds = catalog.get("odds") or []
    if not odds:
        return None
    for group in odds[:-1]:
        pct = group.get("pct", 0)
        ids = _single_cell_ids(catalog, group.get("entityIds") or [])
        if ids and random.random() < pct:
            return random.choice(ids)
    ids = _single_cell_ids(catalog, odds[-1].get("entityIds") or [])
    return random.choice(ids) if ids else None


_CURRENCY_TYPE_CODES = {
    "COINS": 4,
    "ETHEREAL_CURRENCY": 5,
    "FOOD": 7,
    "RELICS": 8,
    "DIAMONDS": 9,
    "STARPOWER": 20,
    "XP": 21,
}
_ENTITY_REF_TYPE_CODE = 11
_CARD_PACK_TYPE_CODE = 18


def _apply_currency_effect(
    player_object, reward, level, resolve_packs_immediately=False
):
    reward_type = str(reward.get("type", "")).upper()
    amount = _safe_int(reward.get("amount"), 0)
    if reward.get("scale"):
        amount *= max(1, level)

    currency_key = _CURRENCY_REWARD_KEYS.get(reward_type)
    if currency_key is not None:
        player_object[currency_key] = (
            _safe_int(player_object.get(currency_key)) + amount
        )
        return reward_type, amount, 0

    if reward_type == "MINIGAME_TOKENS":
        _set_minigame_tokens(player_object, _minigame_tokens(player_object) + amount)
        return reward_type, amount, 0

    if reward_type == "CARD_PACK":
        from msm_cardalbum import _grant_packs

        pack_type = _safe_int(reward.get("id"), 1) or 1
        count = max(1, amount or 1)
        new_pack_ids = _grant_packs(player_object, count, pack_type)
        if resolve_packs_immediately:
            from msm_cardalbum import _open_pending_packs, _target_album_id

            _open_pending_packs(
                player_object, _target_album_id(player_object), new_pack_ids
            )
        return reward_type, count, pack_type

    return None, 0, 0


def _direct_wire_reward(reward_type, amount, wire_id, scale):
    type_code = (
        _CARD_PACK_TYPE_CODE
        if reward_type == "CARD_PACK"
        else _CURRENCY_TYPE_CODES.get(reward_type)
    )
    if type_code is None:
        return None
    return {
        "amount": _safe_int(amount),
        "premium": False,
        "scaled": bool(scale),
        "scale": bool(scale),
        "id": _safe_int(wire_id),
        "type": type_code,
    }


def _entity_ref_wire_reward(entity_id, reward_type, wire_id):
    if reward_type == "CARD_PACK":
        return {
            "amount": 1,
            "premium": False,
            "scaled": False,
            "scale": False,
            "id": _safe_int(wire_id),
            "type": _CARD_PACK_TYPE_CODE,
        }
    return {
        "amount": 1,
        "premium": False,
        "scaled": False,
        "scale": False,
        "id": _safe_int(entity_id),
        "type": _ENTITY_REF_TYPE_CODE,
    }


def _grant_monster_entity_inventory(player_object, entity_id):
    entity_id = _safe_int(entity_id)
    if entity_id <= 0 or get_monster_id_for_entity_id(entity_id) <= 0:
        return False
    return grant_inventory_item(player_object, entity_id, 1)


def _record_obtained_entity(entry, entity_id):
    entity_id = _safe_int(entity_id)
    if entity_id <= 0:
        return
    stats = _load_stats(entry)
    obtained = stats.get("entities_obtained")
    if not isinstance(obtained, dict):
        obtained = {}
    key = str(entity_id)
    obtained[key] = _safe_int(obtained.get(key), 0) + 1
    stats["entities_obtained"] = obtained
    entry["stats"] = json.dumps(stats)


_TIMED_EVENT_WINDOW_MS = 1036800000


def _timed_event_start_date():
    now = int(time.time() * 1000)
    return now - (now % _TIMED_EVENT_WINDOW_MS)


def _timed_event_end_date():
    return _timed_event_start_date() + _TIMED_EVENT_WINDOW_MS


def _minigame_event_data():
    entry = {
        "min_client_ver": MINIGAME_MIN_CLIENT_VER,
        "minigame_id": DEFAULT_MINIGAME_ID,
        "label": "Dipster Digs",
    }
    theme = _minigame_theme()
    if theme:
        entry["theme"] = theme
    return entry


def gs_timed_events(username, params):
    import msm_clubbox

    data = msm_clubbox.gs_timed_events(username, params)
    events = list(data.get("timed_event_list") or [])
    events = [e for e in events if e.get("event_type") != TIMED_EVENT_TYPE]
    start_date = _timed_event_start_date()
    if msm_toggles.is_time_window_active(
        "dipster_dig_enabled",
        "dipster_dig_hours_enabled",
        "dipster_dig_start_hour",
        "dipster_dig_end_hour",
    ):
        events.append(
            {
                "end_date": _timed_event_end_date(),
                "last_updated": start_date,
                "event_type": TIMED_EVENT_TYPE,
                "event_id": 39,
                "data": [_minigame_event_data()],
                "id": TIMED_EVENT_ID,
                "start_date": start_date,
            }
        )

    events = [e for e in events if e.get("event_type") != "Encore"]

    data["timed_event_list"] = events
    return data


def _board_is_complete(entry):
    data = _load_entry_data(entry)
    loot = _decode_cell_blob_auto(data.get("lootState") or "")
    grid = _decode_cell_blob_auto(data.get("gridState") or "")
    targets = [i for i, v in enumerate(loot) if v > 0]
    if not targets:
        return False
    return all(i < len(grid) and grid[i] == loot[i] for i in targets)


def minigame_create(username, params):
    minigame_id = params.get("minigame_id", DEFAULT_MINIGAME_ID)
    if minigame_id == DEFAULT_MINIGAME_ID and not msm_toggles.is_time_window_active(
        "dipster_dig_enabled",
        "dipster_dig_hours_enabled",
        "dipster_dig_start_hour",
        "dipster_dig_end_hour",
    ):
        return {"success": False, "message": "Dipster Dig is currently closed."}
    root, player_object = load_player(username)
    entry = _find_or_create_minigame(player_object, minigame_id)
    if entry.pop("nps_pending_next_level", None) or _board_is_complete(entry):
        _advance_minigame_level(minigame_id, entry)
    tokens = _minigame_tokens(player_object)
    save_player(username, root)
    return {
        "success": True,
        "minigame_id": entry.get("minigame_id"),
        "properties": [
            {"minigame_tokens_actual": tokens},
            {"minigames": [_wire_entry(entry)]},
        ],
    }


def _next_defined_level(minigame_id, current_level):
    defined = _defined_level_keys(minigame_id)
    for tier_level in defined:
        if tier_level > current_level:
            return tier_level
    return current_level + 1 if not defined else defined[-1]


def _advance_minigame_level(minigame_id, entry):
    entry_data = _load_entry_data(entry)
    stats = _load_stats(entry)

    level = _safe_int(entry_data.get("level"), 1) or 1
    level = _next_defined_level(minigame_id, level)
    entry_data["level"] = level
    width, height = _grid_dims_for_level(minigame_id, level)
    slots = _slots_for_level(minigame_id, level)
    entry_data["lootState"] = _populated_grid_blob(
        minigame_id, width * height, slots, width, height
    )
    entry_data["gridState"] = _empty_grid_blob(width * height)
    entry_data["seed"] = random.randint(-2147483648, 2147483647)
    entry["data"] = json.dumps(entry_data)

    levels_complete = _safe_int(stats.get("levels_complete"), 0) + 1
    stats["levels_complete"] = levels_complete
    stats["top_levels_complete"] = max(
        _safe_int(stats.get("top_levels_complete"), 0), levels_complete
    )
    entry["stats"] = json.dumps(stats)
    return level


def minigame_next_level(username, params):
    minigame_id = params.get("minigame_id", DEFAULT_MINIGAME_ID)
    root, player_object = load_player(username)
    entry = _find_or_create_minigame(player_object, minigame_id)
    entry.pop("nps_pending_next_level", None)
    level = _advance_minigame_level(minigame_id, entry)

    tokens = _minigame_tokens(player_object)
    save_player(username, root)
    return {
        "success": True,
        "minigame_id": entry.get("minigame_id"),
        "level": level,
        "properties": [
            {"minigame_tokens_actual": tokens},
            {"minigames": [_wire_entry(entry)]},
        ],
    }


def _roll_entity_rewards(catalog, player_object, level=1, entry=None):
    entity_id = _roll_entity(catalog)
    granted = []
    if entity_id is not None:
        if (
            _grant_monster_entity_inventory(player_object, entity_id)
            and entry is not None
        ):
            _record_obtained_entity(entry, entity_id)
        entity_info = (catalog.get("entityInfo") or {}).get(str(entity_id)) or {}
        for reward in entity_info.get("rewards") or []:
            reward_type, amount, wire_id = _apply_currency_effect(
                player_object, reward, level, resolve_packs_immediately=False
            )
            if reward_type is None:
                continue
            wire = _direct_wire_reward(
                reward_type, amount, wire_id, bool(reward.get("scale"))
            )
            if wire:
                granted.append(wire)
    return granted


def _minigame_prize(username, params):
    minigame_id = params.get("minigame_id", DEFAULT_MINIGAME_ID)
    root, player_object = load_player(username)
    catalog = _catalog(minigame_id)
    granted = _roll_entity_rewards(catalog, player_object)
    save_player(username, root)
    properties = list(create_player_properties(player_object) or [])
    append_inventory_property(properties, player_object)
    return {
        "success": True,
        "rewards": granted,
        "properties": properties,
    }


def minigame_doorprize(username, params):
    return _minigame_prize(username, params)


def minigame_spinprize(username, params):
    return _minigame_prize(username, params)


def _level_complete_rewards(minigame_id, entry, player_object):
    entry_data = _load_entry_data(entry)
    loot_cells = _decode_cell_blob_auto(entry_data.get("lootState") or "")
    grid_cells = _decode_cell_blob_auto(entry_data.get("gridState") or "")
    entity_info = (_catalog(minigame_id) or {}).get("entityInfo") or {}
    granted = []
    seen_loot_vals = set()
    for idx, loot_val in enumerate(loot_cells):
        if loot_val <= 0 or idx >= len(grid_cells) or grid_cells[idx] != loot_val:
            continue
        if loot_val in seen_loot_vals:
            continue
        seen_loot_vals.add(loot_val)
        if _grant_monster_entity_inventory(player_object, loot_val):
            _record_obtained_entity(entry, loot_val)
        info = entity_info.get(str(loot_val)) or {}
        for reward in info.get("rewards") or []:
            reward_type, amount, wire_id = _apply_currency_effect(
                player_object, reward, 1, resolve_packs_immediately=False
            )
            if reward_type is None:
                continue
            wire = _entity_ref_wire_reward(loot_val, reward_type, wire_id)
            if wire:
                granted.append(wire)
    return granted


def minigame_verify_session(username, params):
    minigame_id = params.get("minigame_id", DEFAULT_MINIGAME_ID)
    state = params.get("state") or {}
    tokens_used = max(0, _safe_int(params.get("tokens_used")))
    root, player_object = load_player(username)
    entry = _find_or_create_minigame(player_object, minigame_id)
    try:
        move_state = json.loads(state.get("data") or "{}")
    except (TypeError, ValueError):
        move_state = {}
    level_complete = False
    dig_happened = False
    level_now = _safe_int(_load_entry_data(entry).get("level"), 1) or 1
    if isinstance(move_state, dict) and move_state.get("moves"):
        entry_data = _load_entry_data(entry)
        grid = entry_data.get("gridState")
        loot = entry_data.get("lootState")
        if grid and loot:
            try:
                raw = zlib.decompress(base64.b64decode(move_state["moves"]))
                n = len(raw) // 4
                dug_indices = struct.unpack(">%di" % n, raw[: n * 4]) if n else ()
            except (TypeError, ValueError, zlib.error, struct.error):
                dug_indices = ()
            if dug_indices:
                loot_cells = _decode_cell_blob_auto(loot)
                grid_cells = _decode_cell_blob_auto(grid)
                if len(grid_cells) < len(loot_cells):
                    grid_cells.extend([0] * (len(loot_cells) - len(grid_cells)))
                changed = False
                level_now = _safe_int(entry_data.get("level"), 1) or 1
                num_states = _num_states_for_level(minigame_id, level_now)
                for idx in dug_indices:
                    if not (0 <= idx < len(grid_cells)):
                        continue
                    state = grid_cells[idx]
                    loot_val = loot_cells[idx] if idx < len(loot_cells) else 0
                    if 0 < state < num_states:
                        grid_cells[idx] = state - 1
                        changed = True
                    elif state == 0:
                        grid_cells[idx] = loot_val if loot_val != 0 else -1
                        changed = True
                if changed:
                    entry_data["gridState"] = _encode_cell_blob(grid_cells)
                    entry["data"] = json.dumps(entry_data)
                    dig_happened = True
                loot_entity_indices = [i for i, v in enumerate(loot_cells) if v > 0]
                if loot_entity_indices and all(
                    grid_cells[i] == loot_cells[i] for i in loot_entity_indices
                ):
                    level_complete = True
    requested_next = (params.get("extra") or "") == "next_level"
    level_complete_rewards = []
    if requested_next and not entry.get("nps_pending_next_level"):
        level_complete_rewards = _level_complete_rewards(
            minigame_id, entry, player_object
        )
        entry["nps_pending_next_level"] = True
    mid_level_rewards = []
    if tokens_used > 0 and dig_happened and random.random() < 0.235:
        mid_level_rewards = _roll_entity_rewards(
            _catalog(minigame_id), player_object, level_now, entry
        )
    tokens = _minigame_tokens(player_object)
    if tokens_used > 0 and msm_toggles.is_enabled("functioning_currencies"):
        tokens = _set_minigame_tokens(player_object, tokens - tokens_used)
    save_player(username, root)
    from msm_playerdata import create_player_properties

    props = list(create_player_properties(player_object) or [])
    granted_pack = any(
        r.get("type") == _CARD_PACK_TYPE_CODE
        for r in level_complete_rewards + mid_level_rewards
    )
    if granted_pack:
        from msm_cardalbum import _card_albums_properties

        props.extend(_card_albums_properties(player_object))
    append_inventory_property(props, player_object)
    props.append({"minigame_tokens_actual": tokens})
    props.append({"minigames": [_wire_entry(entry)]})
    response = {
        "refresh_state": False,
        "success": True,
        "extra": params.get("extra") or "",
        "properties": props,
    }
    if granted_pack:
        response["updateCardAlbum"] = True
    if requested_next:
        response["level_complete_rewards"] = level_complete_rewards
    if mid_level_rewards:
        response["mid_level_rewards"] = mid_level_rewards
    frames = [("minigame_verify_session", response)]
    return frames


def minigame_handle_bonus(username, params):
    minigame_id = (
        _safe_int(params.get("minigame_id"), DEFAULT_MINIGAME_ID) or DEFAULT_MINIGAME_ID
    )
    mode = _safe_int(params.get("mode"))
    root, player_object = load_player(username)
    entry = _find_or_create_minigame(player_object, minigame_id)
    stats = _load_stats(entry)
    entry_data = _load_entry_data(entry)
    level = _safe_int(entry_data.get("level"), 1) or 1

    now = int(time.time() * 1000)
    bonus_timings = stats.get("bonus_timings")
    if not isinstance(bonus_timings, list):
        bonus_timings = []
    bonus_timings.append(now)
    stats["bonus_timings"] = bonus_timings[-20:]

    granted = []
    if mode == VIDEO_AD_BONUS_MODE:
        diamonds_gain = random.randint(400, 900)
        player_object["diamonds"] = (
            _safe_int(player_object.get("diamonds")) + diamonds_gain
        )
        granted.append(_direct_wire_reward("DIAMONDS", diamonds_gain, 0, False))

    entry["stats"] = json.dumps(stats)

    tokens_gain = _BONUS_MODE_TOKENS.get(mode, 1)
    tokens = _set_minigame_tokens(
        player_object, _minigame_tokens(player_object) + tokens_gain
    )
    save_player(username, root)

    from msm_playerdata import create_player_properties

    properties = list(create_player_properties(player_object) or [])
    append_inventory_property(properties, player_object)
    properties.append({"minigame_tokens_actual": tokens})
    properties.append({"minigames": [_wire_entry(entry)]})
    return {"success": True, "rewards": granted, "properties": properties}
