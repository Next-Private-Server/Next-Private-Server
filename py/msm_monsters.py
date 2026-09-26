import json
import random
import struct
import time
import msm_toggles
from msm_box import (
    UNDERLING_ISLAND_TYPES,
    BOX_SIMPLE_ISLAND_TYPES,
    apply_awakened_box_state,
    apply_inactive_box_state,
    apply_underling_box_state,
    build_placeholder_box_monster,
    is_box_monster_entity,
    requires_direct_placement,
)


def _base_build_ms(monster_id):
    return (
        int((get_monster_definition(monster_id) or {}).get("build_time", 0) or 0) * 1000
    )


def _effective_build_ms(monster_id):
    if msm_toggles.is_enabled("instant_timers"):
        return 0
    return _base_build_ms(monster_id)


def _sell_refund(book_value):

    if book_value <= 0:
        return 0
    percentage = (
        msm_toggles.get_int("sell_percentage", 75, minimum=0, maximum=100) / 100.0
    )
    return int(book_value * percentage)


def _charge_speedup(player_object, remaining_ms):

    if not msm_toggles.is_enabled("functioning_currencies"):
        return
    cost = diamond_speedup_cost(remaining_ms)
    player_object["diamonds"] = max(0, (player_object.get("diamonds", 0) or 0) - cost)


def _deduct_egg_purchase_cost(player_object, monster_id):
    definition = get_monster_definition(monster_id) or {}
    entity_id = definition.get("entity_id", 0) or 0
    if consume_inventory_item(player_object, entity_id):
        return
    free_unlocks = player_object.get("free_monster_unlocks")
    if isinstance(free_unlocks, list) and monster_id in free_unlocks:
        free_unlocks.remove(monster_id)
        return
    if not msm_toggles.is_enabled("functioning_currencies"):
        return
    cost_diamonds = definition.get("cost_diamonds", 0) or 0
    cost_relics = definition.get("cost_relics", 0) or 0
    cost_coins = definition.get("cost_coins", 0) or 0
    if cost_diamonds > 0:
        player_object["diamonds"] = max(
            0, (player_object.get("diamonds", 0) or 0) - cost_diamonds
        )
    elif cost_relics > 0:
        player_object["relics"] = max(
            0, (player_object.get("relics", 0) or 0) - cost_relics
        )
    elif cost_coins > 0:
        player_object["coins"] = max(
            0, (player_object.get("coins", 0) or 0) - cost_coins
        )


from msm_gamedata import (
    all_monster_ids,
    build_paironormal_modes,
    choose_breeding_result_monster,
    compute_monster_economy,
    find_paironormal_form_id,
    get_costume_definition,
    get_costume_id_for_monster,
    get_max_monster_level,
    get_monster_definition,
    get_monster_id_for_entity_id,
    get_user_game_setting_int,
    soul_link_coin_costs,
    get_monster_level_definition,
    get_structure_definition,
    is_egg_holder_structure,
    is_nursery_structure,
    is_paironormal_island,
    is_paironormal_multimodal,
    monster_allowed_on_island,
    resolve_paironormal_stored_monster_id,
    normalize_collection_type as _normalize_collection_type,
    resolve_monster_for_island,
)
from msm_playerdata import (
    SFSLong,
    action_result,
    add_actual_currencies,
    create_player_properties,
    diamond_speedup_cost,
    find_island,
    find_island_by_structure,
    find_monster,
    find_monster_with_island,
    find_structure,
    get_active_island_id,
    island_type_of,
    load_player,
    next_daily_reset_timestamp,
    save_player,
    append_inventory_property,
    consume_inventory_item,
)
from msm_protocol import SFSFloat
from msm_store import load_db_json


def _safe_int(value, default=0):
    try:
        return int(value)
    except (TypeError, ValueError, OverflowError):
        return default


def _safe_float(value, default=0.0):
    if isinstance(value, dict):
        hex_bits = value.get("__double_bits")
        if hex_bits is not None:
            try:
                return float(
                    struct.unpack(
                        ">d", bytes.fromhex(str(hex_bits).removeprefix("0x"))
                    )[0]
                )
            except (TypeError, ValueError, struct.error):
                return default
        hex_bits = value.get("__float_bits")
        if hex_bits is not None:
            try:
                return float(
                    struct.unpack(
                        ">f", bytes.fromhex(str(hex_bits).removeprefix("0x"))[-4:]
                    )[0]
                )
            except (TypeError, ValueError, struct.error):
                return default
    try:
        return float(value)
    except (TypeError, ValueError, OverflowError):
        return default


def _nursery_touch_payload(structure, player_object):
    return {
        "user_structure_id": SFSLong(structure.get("user_structure_id", 0)),
        "occupied": 1 if structure.get("occupied") else 0,
        "has_egg": 1 if structure.get("has_egg") else 0,
        "obj_data": structure.get("obj_data", 0) or 0,
        "obj_end": SFSLong(structure.get("obj_end", 0) or 0),
        "finishing_time": SFSLong(
            structure.get("finishing_time", structure.get("obj_end", 0)) or 0
        ),
        "properties": create_player_properties(player_object),
    }


def _structure_type(structure):
    if structure is None:
        return ""
    definition = (
        get_structure_definition(
            structure.get("structure", structure.get("structure_id", 0)) or 0
        )
        or {}
    )
    return definition.get("structure_type") or ""


def _is_synthesizer_structure(structure):
    return _structure_type(structure) == "synthesizer"


def _clear_egg_holder_state(structure):
    if structure is None:
        return None
    if _is_synthesizer_structure(structure):
        structure["occupied"] = False
        structure["has_egg"] = False
        structure["viewed"] = False
        structure["obj_data"] = 0
        structure["obj_end"] = 0
        structure["finishing_time"] = 0
        structure["building_completed"] = 0
        return None
    structure["occupied"] = False
    structure["has_egg"] = False
    structure["obj_data"] = 0
    structure["obj_end"] = 0
    structure["finishing_time"] = 0
    return structure


MAGICAL_NEXUS_ISLAND_TYPE = 25
PAIRONORMAL_ISLAND_TYPE = 31
GOLD_ISLAND_TYPE = 6
BATTLE_ISLAND_TYPE = 20
ISLAND_32_TYPE = 32
TITANSOUL_REWARD_INTERVAL_MS = 15796000
BATTLE_VERSUS_CAMPAIGN_ID = 1000
BATTLE_VERSUS_MAX_ATTEMPTS = 5
BATTLE_TEAM_SIZE = 3
MAGICAL_NEXUS_STRUCTURE_IDS = {925: 1, 922: 2}


def repair_magical_nexus_layout(island):
    if island is None or island_type_of(island) != MAGICAL_NEXUS_ISLAND_TYPE:
        return False
    changed = False
    island_uid = _safe_int(
        island.get("user_island_id") or island.get("island"),
        1000 + MAGICAL_NEXUS_ISLAND_TYPE,
    )
    remapped = {}
    now = int(time.time() * 1000)
    for structure in island.get("structures") or []:
        if structure is None:
            continue
        structure_type = _safe_int(
            structure.get("structure") or structure.get("structure_id")
        )
        default_id = MAGICAL_NEXUS_STRUCTURE_IDS.get(structure_type)
        if default_id is None:
            continue
        old_id = _safe_int(structure.get("user_structure_id"))
        desired_id = old_id if old_id > 0 else default_id
        if old_id and old_id != desired_id:
            remapped[old_id] = desired_id
        if structure.get("user_structure_id") != desired_id:
            structure["user_structure_id"] = desired_id
            changed = True
        if structure.get("structure") != structure_type:
            structure["structure"] = structure_type
            changed = True
        for key, value in (
            ("island", island_uid),
            ("user_island_id", island_uid),
            ("in_warehouse", 0),
            ("is_upgrading", 0),
            ("is_complete", 1),
            ("muted", 0),
            ("flip", 0),
        ):
            if structure.get(key) != value:
                structure[key] = value
                changed = True
        if _safe_int(structure.get("date_created")) <= 0:
            structure["date_created"] = now
            changed = True
        if _safe_int(structure.get("building_completed")) <= 0:
            structure["building_completed"] = _safe_int(
                structure.get("date_created"), now
            )
            changed = True
        if is_nursery_structure(structure_type):
            held_egg = next(
                (
                    e
                    for e in island.get("eggs") or []
                    if e is not None and _safe_int(e.get("structure")) == desired_id
                ),
                None,
            )
            hatches_on = _safe_int(held_egg.get("hatches_on")) if held_egg else 0
            for key, value in (
                ("occupied", held_egg is not None),
                ("has_egg", held_egg is not None),
                ("obj_data", 1 if held_egg is not None else 0),
                ("obj_end", hatches_on),
            ):
                if structure.get(key) != value:
                    structure[key] = value
                    changed = True
            if structure.pop("finishing_time", None) is not None:
                changed = True
            built = _safe_int(structure.get("date_created"), now)
            if _safe_int(structure.get("building_completed")) != built:
                structure["building_completed"] = built
                changed = True
            continue
        for key in ("occupied", "has_egg", "obj_data", "obj_end", "finishing_time"):
            if structure.pop(key, None) is not None:
                changed = True
    for egg in island.get("eggs") or []:
        if egg is None:
            continue
        old_structure = _safe_int(egg.get("structure"))
        new_structure = remapped.get(old_structure, old_structure)
        if new_structure and new_structure != old_structure:
            egg["structure"] = SFSLong(new_structure)
            changed = True
        if _safe_int(egg.get("island")) != island_uid:
            egg["island"] = SFSLong(island_uid)
            changed = True
        for key in ("nursery_id", "user_structure_id", "user_island_id"):
            if key in egg:
                del egg[key]
                changed = True
    return changed


def _default_battle_loadout(player_object):
    team = []
    for island in player_object.get("islands") or []:
        if island is None:
            continue
        for monster in island.get("monsters") or []:
            if len(team) >= BATTLE_TEAM_SIZE:
                break
            if monster is None or not monster.get("monster"):
                continue
            definition = get_monster_definition(monster.get("monster", 0))
            if is_box_monster_entity(definition):
                continue
            entry = {
                "monsterId": monster.get("monster"),
                "level": monster.get("level", 1) or 1,
            }
            costume_id = (monster.get("costume") or {}).get("eq") or 0
            if costume_id:
                entry["costumeId"] = costume_id
            team.append(entry)
        if len(team) >= BATTLE_TEAM_SIZE:
            break
    return team


def backfill_battle_state(player_object):

    loadout = _default_battle_loadout(player_object)
    loadout_json = json.dumps(loadout)
    if not isinstance(player_object.get("battle"), dict):
        player_object["battle"] = {
            "medals": player_object.get("medals", 0) or 0,
            "user_id": player_object.get("bbb_id", 0) or 0,
            "level": 1,
            "max_training_level": 15,
            "xp": 0,
            "loadout": "{}",
            "loadout_versus": loadout_json,
        }
    if not player_object.get("battle_versus"):
        now = int(time.time() * 1000)
        player_object["battle_versus"] = [
            {
                "campaign_id": BATTLE_VERSUS_CAMPAIGN_ID,
                "tier": 1,
                "attempts": BATTLE_VERSUS_MAX_ATTEMPTS,
                "stars": 0,
                "streak": 0,
                "match_score": 1500,
                "champion_score": 0,
                "user_id": player_object.get("bbb_id", 0) or 0,
                "display_name": player_object.get("display_name", "") or "",
                "started_on": now,
                "schedule_started_on": now,
                "refreshes_on": now + 86400000,
                "loadout": loadout_json,
                "last_opponent_loadout": loadout_json,
                "last_seed": 0,
            }
        ]
    else:
        now = int(time.time() * 1000)
        for entry in player_object["battle_versus"]:
            if isinstance(entry, dict) and now >= (entry.get("refreshes_on", 0) or 0):
                entry["attempts"] = BATTLE_VERSUS_MAX_ATTEMPTS
                entry["schedule_started_on"] = now
                entry["refreshes_on"] = now + 86400000
    if "perma_campaigns_viewed" not in player_object:
        player_object["perma_campaigns_viewed"] = []


BATTLE_ISLAND_STRUCTURES = [
    {"user_structure_id": 1, "structure": 535, "pos_x": 35, "pos_y": 17},
    {"user_structure_id": 2, "structure": 546, "pos_x": 29, "pos_y": 9},
    {"user_structure_id": 3, "structure": 533, "pos_x": 21, "pos_y": 3},
    {"user_structure_id": 4, "structure": 549, "pos_x": 28, "pos_y": 22},
    {"user_structure_id": 5, "structure": 614, "pos_x": 14, "pos_y": 11},
]


def _ensure_battle_island_layout(island):
    if island is None or island_type_of(island) != 20:
        return
    now = int(time.time() * 1000)
    island["type"] = 20
    island.setdefault(
        "battle",
        {
            "seed": now,
            "costume_data": {"costumes": []},
            "music_data": {"currently_playing": 0, "muted": False},
            "campaign_data": {"campaigns": []},
        },
    )
    island.setdefault("costume_data", {"costumes": []})
    island.setdefault("costumes_owned", "[]")
    if island.get("structures"):
        return
    island["structures"] = [
        {
            "user_structure_id": entry["user_structure_id"],
            "structure": entry["structure"],
            "pos_x": entry["pos_x"],
            "pos_y": entry["pos_y"],
            "col": entry["pos_x"],
            "row": entry["pos_y"],
            "island": 0,
            "scale": 1.0,
            "is_upgrading": 0,
            "in_warehouse": 0,
            "is_complete": 1,
            "building_completed": island.get("date_created", now) or now,
            "date_created": island.get("date_created", now) or now,
            "last_collection": island.get("date_created", now) or now,
            "muted": 0,
            "flip": 0,
        }
        for entry in BATTLE_ISLAND_STRUCTURES
    ]


def _parse_sold_monsters(island):
    raw = island.get("monsters_sold")
    if isinstance(raw, list):
        return [int(v) for v in raw if isinstance(v, (int, float))]
    if isinstance(raw, str):
        return [
            int(tok)
            for tok in raw.strip("[] ").split(",")
            if tok.strip().lstrip("-").isdigit()
        ]
    return []


def _island_has_monster_type(island, monster_type):
    for m in island.get("monsters") or []:
        if m is not None and m.get("monster") == monster_type:
            return True
    return False


def _mark_monster_sold(island, monster_type):
    if _island_has_monster_type(island, monster_type):
        return None
    sold = _parse_sold_monsters(island)
    if monster_type in sold:
        return None
    for entry in _paironormal_sold_ids(island, monster_type):
        if entry and entry not in sold:
            sold.append(entry)
    island["monsters_sold"] = "[" + ",".join(str(v) for v in sold) + "]"
    return {
        "island_id": SFSLong(island.get("user_island_id", 0)),
        "monsters_sold": island["monsters_sold"],
    }


def _paironormal_sold_ids(island, monster_type):
    ids = [monster_type]
    if island_type_of(island) != PAIRONORMAL_ISLAND_TYPE or not monster_type:
        return ids
    from msm_gamedata import (
        find_paironormal_form_id,
        resolve_paironormal_stored_monster_id,
    )

    parent = resolve_paironormal_stored_monster_id(
        monster_type, PAIRONORMAL_ISLAND_TYPE
    )
    for candidate in (
        parent,
        find_paironormal_form_id(parent, PAIRONORMAL_ISLAND_TYPE, True),
        find_paironormal_form_id(parent, PAIRONORMAL_ISLAND_TYPE, False),
    ):
        if candidate and candidate > 0 and candidate not in ids:
            ids.append(candidate)
    return ids


def _mark_monster_viewed_in_sold(island, monster_type):
    sold = _parse_sold_monsters(island)
    for entry in _paironormal_sold_ids(island, monster_type):
        if entry and entry not in sold:
            sold.append(entry)
    island["monsters_sold"] = "[" + ",".join(str(v) for v in sold) + "]"
    return {
        "island_id": SFSLong(island.get("user_island_id", 0)),
        "monsters_sold": island["monsters_sold"],
    }


def _buyback_monster_id(monster):
    monster_id = monster.get("monster", 0)
    definition = get_monster_definition(monster_id)
    if not definition or not is_paironormal_multimodal(definition):
        return monster_id
    for mode in monster.get("modes") or []:
        if isinstance(mode, dict) and mode.get("a") and mode.get("monster"):
            return mode.get("monster")
    return monster_id


def _build_buyback_data(monster):
    if monster is None:
        return {}
    monster_id = _buyback_monster_id(monster)
    definition = get_monster_definition(monster_id) or {}
    entity_id = _safe_int(definition.get("entity_id"))
    if not entity_id:
        return {}
    return {
        "times_fed": _safe_int(monster.get("times_fed")),
        "level": max(1, _safe_int(monster.get("level"), 1)),
        "name": monster.get("name", "") or definition.get("common_name", "") or "",
        "entity_id": entity_id,
        "costume": monster.get("costume") or {"p": [], "eq": 0},
        "coin_cost": _safe_int(monster.get("book_value"))
        or _safe_int(definition.get("cost_coins")),
    }


def purchase_buyback(username, params):
    island_id = params.get("island_id", params.get("user_island_id", 0)) or 0
    x_pos = params.get("x_pos", params.get("pos_x", 0)) or 0
    y_pos = params.get("y_pos", params.get("pos_y", 0)) or 0
    flip = params.get("flip", 0) or 0
    root, player_object = load_player(username)
    if 0 < island_id < 1000:
        island_id += 1000
    island = find_island(player_object, island_id)
    if island is None:
        return {"success": False, "properties": create_player_properties(player_object)}
    slot = island.get("buyback")
    if not slot:
        return {"success": False, "properties": create_player_properties(player_object)}
    monster_type = get_monster_id_for_entity_id(_safe_int(slot.get("entity_id")))
    if not monster_type:
        return {"success": False, "properties": create_player_properties(player_object)}
    island.pop("buyback", None)
    sold_update = _mark_monster_reacquired(island, monster_type)
    user_monster_id = max(
        int(player_object.get("last_user_monster_id", 0) or 0) + 1,
        20000 + random.randint(0, 899999),
    )
    player_object["last_user_monster_id"] = user_monster_id
    now = int(time.time() * 1000)
    monster = {
        "user_monster_id": SFSLong(user_monster_id),
        "island": SFSLong(island_id),
        "monster": monster_type,
        "pos_x": x_pos,
        "pos_y": y_pos,
        "flip": flip,
        "muted": 0,
        "level": slot.get("level", 1),
        "happiness": 0,
        "times_fed": slot.get("times_fed", 0),
        "name": slot.get("name", "")
        or (get_monster_definition(monster_type) or {}).get("common_name", ""),
        "in_hotel": 0,
        "volume": SFSFloat(1.0),
        "last_collection": SFSLong(now),
        "last_feeding": SFSLong(now),
        "costume": slot.get("costume") or {"eq": 0, "p": []},
        "book_value": slot.get("coin_cost", 0),
    }
    island.setdefault("monsters", []).append(monster)
    island["num_monsters"] = len(island["monsters"])
    _mark_monster_collected_in_book(island, monster_type)
    happy_effects = recompute_island_happiness(island)
    save_player(username, root)
    result = {
        "success": True,
        "properties": create_player_properties(player_object),
        "monster": monster,
        "monster_happy_effects": happy_effects,
    }
    return result, sold_update


def _mark_monster_reacquired(island, monster_type):
    sold = _parse_sold_monsters(island)
    if monster_type not in sold:
        return None
    sold = [v for v in sold if v != monster_type]
    island["monsters_sold"] = "[" + ",".join(str(v) for v in sold) + "]"
    return {
        "island_id": SFSLong(island.get("user_island_id", 0)),
        "monsters_sold": island["monsters_sold"],
    }


def _classify_monster_id(monster_id):
    definition = get_monster_definition(monster_id) or {}
    monster_class = (definition.get("monster_class") or "").upper()
    name = (definition.get("name") or "").upper()
    if "EPIC" in monster_class or "EPIC" in name:
        return "epics"
    if "RARE" in monster_class or "RARE" in name:
        return "rares"
    if "SEASON" in monster_class or "SEASON" in name:
        return "seasonals"
    return "commons"


_BOOK_COUNT_FIELDS = {
    "commons": "numUniqueCommonsCollectedOnBookOfMonstersIsland",
    "rares": "numUniqueRaresCollectedOnBookOfMonstersIsland",
    "epics": "numUniqueEpicsCollectedOnBookOfMonstersIsland",
    "seasonals": "numUniqueSeasonalsCollectedOnBookOfMonstersIsland",
}


def _book_eligible_ids(island_type, ids):
    if island_type != PAIRONORMAL_ISLAND_TYPE:
        return set(ids)
    from msm_gamedata import is_paironormal_multimodal

    eligible = set()
    for monster_id in ids:
        if not monster_id or monster_id <= 0:
            continue
        if is_paironormal_multimodal(get_monster_definition(monster_id)):
            continue
        eligible.add(monster_id)
    return eligible


def repair_book_of_monsters_counts(island):
    if island is None:
        return
    island_type = island_type_of(island) or 1
    known_ids = set(island.get("book_monster_ids") or [])
    for m in island.get("monsters") or []:
        if m is None:
            continue
        monster_id = m.get("monster") or m.get("monster_id") or 0
        if monster_id > 0:
            known_ids.add(monster_id)
    known_ids = _book_eligible_ids(island_type, known_ids)
    island["book_monster_ids"] = sorted(known_ids)
    buckets = {"commons": set(), "rares": set(), "epics": set(), "seasonals": set()}
    for monster_id in known_ids:
        if not monster_id or monster_id <= 0:
            continue
        buckets[_classify_monster_id(monster_id)].add(monster_id)
    for bucket, field in _BOOK_COUNT_FIELDS.items():
        if island_type == PAIRONORMAL_ISLAND_TYPE:
            island.pop(field, None)
        else:
            island[field] = max(len(buckets[bucket]), island.get(field, 0) or 0)
    island["num_monsters"] = len(island.get("monsters") or [])


def grant_full_book(island):
    if island is None:
        return
    from msm_gamedata import all_monster_ids, monster_ids_allowed_on_island

    island_type = island_type_of(island) or 1
    known_ids = set(island.get("book_monster_ids") or [])
    if island_type == MAGICAL_NEXUS_ISLAND_TYPE:
        known_ids.update(all_monster_ids())
    else:
        known_ids.update(monster_ids_allowed_on_island(island_type))
    island["book_monster_ids"] = sorted(known_ids)
    repair_book_of_monsters_counts(island)


def _mark_monster_collected_in_book(island, monster_id):
    if island is None or not monster_id or monster_id <= 0:
        return
    collected = island.setdefault("book_monster_ids", [])
    if monster_id not in collected:
        collected.append(monster_id)
    repair_book_of_monsters_counts(island)


def _monster_update(monster, mode="full"):
    monster_id = SFSLong(monster.get("user_monster_id", 0))
    update = {"user_monster_id": monster_id}
    if mode == "move":
        update["pos_x"] = monster.get("pos_x", 0)
        update["pos_y"] = monster.get("pos_y", 0)
        update["volume"] = SFSFloat(monster.get("volume", 1.0) or 1.0)
        update["col"] = monster.get("col", monster.get("pos_x", 0))
        update["row"] = monster.get("row", monster.get("pos_y", 0))
        update["scale"] = SFSFloat(monster.get("scale", 1.0) or 1.0)
    elif mode == "flip":
        update["flip"] = monster.get("flip", 0)
    elif mode == "mute":
        update["muted"] = monster.get("muted", 0)
    elif mode == "biggify":
        update["megamonster"] = monster.get("megamonster", {})
    elif mode == "titansoul":
        update["titansoul"] = monster.get("titansoul") or _default_titansoul_state()
    elif mode == "collect":
        update["happiness"] = monster.get("happiness", 0) or 0
        update["collected_coins"] = monster.get("collected_coins", 0)
        update["collected_ethereal"] = monster.get("collected_ethereal", 0)
        update["collected_relics"] = SFSFloat(
            _safe_float(monster.get("collected_relics"), 0.0)
        )
        update["last_collection"] = SFSLong(monster.get("last_collection", 0) or 0)
    elif mode == "training":

        update["level"] = monster.get("level", 1)
        update["is_training"] = monster.get("is_training", 0)
        update["training_complete_on"] = SFSLong(
            monster.get("training_complete_on", 0) or 0
        )
    return update


def _first_param(params, keys, default=0):
    for key in keys:
        value = params.get(key)
        if value is not None:
            return value
    return default


def _as_enabled(value, default=True):
    if value is None:
        return default
    if isinstance(value, str):
        return value.lower() not in ("0", "false", "no", "off")
    return bool(value)


def move_monster(username, params):
    monster_id = _first_param(
        params, ("user_monster_id", "userMonsterId", "monster_id", "monsterId", "id"), 0
    )
    pos_x = _first_param(params, ("pos_x", "x", "col", "column"), 0)
    pos_y = _first_param(params, ("pos_y", "y", "row"), 0)
    volume = _first_param(params, ("volume", "vol"), 1.0)
    scale = _first_param(params, ("scale", "size"), None)
    root, player_object = load_player(username)
    island_id = _first_param(
        params,
        ("user_island_id", "userIslandId", "island_id", "island"),
        get_active_island_id(player_object),
    )
    island = find_island(player_object, island_id) or find_island(
        player_object, get_active_island_id(player_object)
    )
    monster = find_monster(island, monster_id)
    if monster is None:
        return (
            action_result(False, "user_monster_id", monster_id, with_properties=True),
            {},
        )
    monster["pos_x"] = pos_x
    monster["pos_y"] = pos_y
    monster["col"] = pos_x
    monster["row"] = pos_y
    monster["volume"] = volume
    if scale is not None:
        monster["scale"] = scale
    happy_effects = recompute_island_happiness(island)
    save_player(username, root)
    result = action_result(True, "user_monster_id", monster_id, with_properties=True)
    result["monster_happy_effects"] = happy_effects
    return result, _monster_update(monster, "move")


_MEGA_MONSTER_DURATION_MS = 24 * 60 * 60 * 1000


def biggify_monster(username, params):
    monster_id = _first_param(
        params, ("user_monster_id", "userMonsterId", "monster_id", "monsterId", "id"), 0
    )
    root, player_object = load_player(username)
    island, monster = find_monster_with_island(player_object, monster_id)
    if monster is None:
        return (
            action_result(False, "user_monster_id", monster_id, with_properties=True),
            {},
        )
    existing_mega = monster.get("megamonster") or {}
    permamega = bool(existing_mega.get("permamega", False))
    now = int(time.time() * 1000)
    finished_at = 0
    if "permanent" in params:
        permamega = _as_enabled(params.get("permanent"), False)
        enabled = True
        if not permamega:
            finished_at = now + _MEGA_MONSTER_DURATION_MS
    elif "mega_enable" in params:
        enabled = _as_enabled(params.get("mega_enable"), False)
        if not enabled:
            finished_at = 0
        elif not permamega:
            finished_at = now + _MEGA_MONSTER_DURATION_MS
    else:
        enabled = True

    was_mega = bool(existing_mega.get("currently_mega", False))
    if enabled and not was_mega and msm_toggles.is_enabled("functioning_currencies"):
        cost = get_user_game_setting_int(
            (
                "USER_DIAMOND_COST_PER_PERMALIT_MEGAMONSTER"
                if permamega
                else "USER_DIAMOND_COST_PER_DAILY_MEGAMONSTER"
            ),
            20 if permamega else 2,
        )
        if cost > 0:
            player_object["diamonds"] = max(
                0, (player_object.get("diamonds", 0) or 0) - cost
            )
    mega = {
        "permamega": permamega,
        "currently_mega": enabled,
        "mega_enable": enabled,
        "mega_enabled": enabled,
        "prev_permamega": permamega,
        "started_at": now if enabled else 0,
        "finished_at": finished_at,
        "end_time": finished_at,
        "mega_end_time": finished_at,
        "expires": finished_at,
        "expiration": finished_at,
        "time_remaining": (finished_at - now) if finished_at > now else 0,
        "mega_time_remaining": (finished_at - now) if finished_at > now else 0,
    }
    monster["biggified"] = 1 if enabled else 0
    monster["is_big"] = 1 if enabled else 0
    monster["scale"] = 1.5 if enabled else 1.0
    monster["megamonster"] = mega
    save_player(username, root)
    result = action_result(True, "user_monster_id", monster_id)
    update = {
        "user_monster_id": SFSLong(monster_id),
        "megamonster": mega,
        "properties": create_player_properties(player_object),
    }
    return result, update


def flip_monster(username, params):
    monster_id = params.get("user_monster_id", 0)
    flip = 1 if params.get("flipped") else 0
    root, player_object = load_player(username)
    island = find_island(player_object, get_active_island_id(player_object))
    monster = find_monster(island, monster_id)
    if monster is None:
        return (
            action_result(False, "user_monster_id", monster_id, with_properties=True),
            {},
        )
    monster["flip"] = flip
    save_player(username, root)
    result = action_result(True, "user_monster_id", monster_id, with_properties=True)
    return result, _monster_update(monster, "flip")


def sell_monster(username, params):
    monster_id = params.get("user_monster_id", 0)
    root, player_object = load_player(username)
    island, monster = find_monster_with_island(player_object, monster_id)
    sold_update = None
    if island is not None:
        monsters = island.get("monsters") or []
        monster_type = monster.get("monster", 0) if monster is not None else 0

        if monster is not None and msm_toggles.is_enabled("functioning_currencies"):
            book_value = (
                monster.get("book_value")
                or (get_monster_definition(monster_type) or {}).get("cost_coins", 0)
                or 0
            )
            refund = _sell_refund(book_value)
            if refund > 0:
                player_object["coins"] = (player_object.get("coins", 0) or 0) + refund
        pure_destroy = bool(params.get("pure_destroy"))
        buyback_data = {}
        if monster is not None and not pure_destroy:
            buyback_data = _build_buyback_data(monster)
            if buyback_data:
                island["buyback"] = buyback_data
        for i in range(len(monsters) - 1, -1, -1):
            if (
                monsters[i] is not None
                and monsters[i].get("user_monster_id") == monster_id
            ):
                del monsters[i]
                break
        if monster_type:
            sold_update = _mark_monster_sold(island, monster_type)
        import msm_composer

        msm_composer.forget_monster_track(player_object, island, monster_id)
        happy_effects = recompute_island_happiness(island)
        save_player(username, root)
    else:
        happy_effects = []
        buyback_data = {}
    result = action_result(True, "user_monster_id", monster_id)
    result["properties"] = create_player_properties(player_object)
    result["buyback_properties"] = buyback_data
    result["monster_happy_effects"] = happy_effects
    return result, sold_update


def name_monster(username, params):
    monster_id = params.get("user_monster_id", 0)
    name = params.get("name", "")
    root, player_object = load_player(username)
    island = find_island(player_object, get_active_island_id(player_object))
    monster = find_monster(island, monster_id)
    if monster is not None:
        monster["name"] = name
        save_player(username, root)
    result = action_result(True, "user_monster_id", monster_id)
    result["name"] = name
    return result


def mute_monster(username, params):

    monster_id = params.get("user_monster_id", 0)
    root, player_object = load_player(username)
    island, monster = find_monster_with_island(player_object, monster_id)
    if monster is None:
        return {"success": False}, {}
    muted = 0 if monster.get("muted", 0) else 1
    monster["muted"] = muted
    save_player(username, root)
    return {"success": True}, _monster_update(monster, "mute")


def _monster_rarity(definition):
    cls = (definition.get("class") or "").upper() if definition else ""
    if "EPIC" in cls:
        return "epic"
    if "RARE" in cls:
        return "rare"
    return "common"


def _count_soul_link_rarities(island, soul_links):
    counts = {"common": 0, "rare": 0, "epic": 0}
    for link in soul_links:
        if not isinstance(link, dict):
            continue
        linked = find_monster(island, link.get("id"))
        if linked is None:
            continue
        definition = get_monster_definition(linked.get("monster", 0))
        counts[_monster_rarity(definition)] += 1
    return counts


def _recompute_titansoul_unlocks(island, titansoul):
    soul_links = titansoul.get("soul_links") or []
    titansoul["num_links"] = len(soul_links)
    counts = _count_soul_link_rarities(island, soul_links)
    titansoul["rare_unlocked"] = counts["common"] >= 1
    titansoul["epic_unlocked"] = counts["rare"] >= 1
    was_can_awaken = bool(titansoul.get("can_awaken"))
    can_awaken_now = (
        counts["common"] >= 4 and counts["rare"] >= 4 and counts["epic"] >= 4
    )
    titansoul["can_awaken"] = can_awaken_now
    if can_awaken_now and not was_can_awaken:
        from msm_structures import find_awakener_structure

        awakener = find_awakener_structure(island)
        if awakener is not None:
            awakener.setdefault("ext", {})["awakened_state"] = 1


def _charge_soul_link_cost(player_object, link_index):
    if not msm_toggles.is_enabled("functioning_currencies"):
        return
    costs = soul_link_coin_costs()
    if link_index < len(costs):
        cost_coins = int(costs[link_index] or 0)
        if cost_coins > 0:
            player_object["coins"] = max(
                0, (player_object.get("coins", 0) or 0) - cost_coins
            )
    else:
        increment = get_user_game_setting_int(
            "USER_SOUL_LINK_DIAMOND_INCREMENT_COST", 0
        )
        cost_diamonds = increment * (link_index - len(costs) + 1)
        if cost_diamonds > 0:
            player_object["diamonds"] = max(
                0, (player_object.get("diamonds", 0) or 0) - cost_diamonds
            )


def add_soul_link(username, params):
    titansoul_id = params.get("titansoul_id", 0) or 0
    linked_monster_id = (
        params.get("user_monster_id", params.get("linked_monster_id", 0)) or 0
    )
    root, player_object = load_player(username)
    island, titansoul_monster = find_monster_with_island(player_object, titansoul_id)
    monster_update = None
    if titansoul_monster is not None:
        titansoul = titansoul_monster.setdefault(
            "titansoul", _default_titansoul_state()
        )
        soul_links = titansoul.setdefault("soul_links", [])
        if not any(
            isinstance(link, dict) and link.get("id") == linked_monster_id
            for link in soul_links
        ):
            _charge_soul_link_cost(player_object, len(soul_links))
            soul_links.append({"id": linked_monster_id})
        if titansoul.get("create_reward_time", 0) == 0 and len(soul_links) > 0:
            now = int(time.time() * 1000)
            titansoul["create_reward_time"] = TITANSOUL_REWARD_INTERVAL_MS
            titansoul["next_reward_time"] = now + TITANSOUL_REWARD_INTERVAL_MS
            titansoul["link_reset_time"] = next_daily_reset_timestamp()
        _recompute_titansoul_unlocks(island, titansoul)
        save_player(username, root)
        monster_update = _monster_update(titansoul_monster, "titansoul")
    result = {
        "success": titansoul_monster is not None,
        "titansoul_id": SFSLong(titansoul_id),
        "user_monster_id": SFSLong(linked_monster_id),
        "properties": create_player_properties(player_object),
    }
    return result, monster_update


def remove_soul_link(username, params):
    titansoul_id = params.get("titansoul_id", 0) or 0
    linked_monster_id = (
        params.get("user_monster_id", params.get("linked_monster_id", 0)) or 0
    )
    root, player_object = load_player(username)
    island, titansoul_monster = find_monster_with_island(player_object, titansoul_id)
    result = {
        "success": titansoul_monster is not None,
        "titansoul_id": SFSLong(titansoul_id),
        "user_monster_id": SFSLong(linked_monster_id),
        "properties": create_player_properties(player_object),
    }
    monster_update = None
    if titansoul_monster is not None:
        titansoul = titansoul_monster.setdefault(
            "titansoul", _default_titansoul_state()
        )
        soul_links = titansoul.setdefault("soul_links", [])
        before = len(soul_links)
        soul_links[:] = [
            link
            for link in soul_links
            if not (isinstance(link, dict) and link.get("id") == linked_monster_id)
        ]
        if len(soul_links) < before:
            titansoul["num_unlinks"] = (titansoul.get("num_unlinks", 0) or 0) + 1
        _recompute_titansoul_unlocks(island, titansoul)
        save_player(username, root)
        monster_update = _monster_update(titansoul_monster, "titansoul")
    return result, monster_update


def toggle_titansoul_fx(username, params):
    titansoul_id = params.get("titansoul_id", params.get("user_monster_id", 0)) or 0
    root, player_object = load_player(username)
    island, titansoul_monster = find_monster_with_island(player_object, titansoul_id)
    monster_update = None
    if titansoul_monster is not None:
        titansoul = titansoul_monster.setdefault(
            "titansoul", _default_titansoul_state()
        )
        titansoul["show_fx"] = not titansoul.get("show_fx", True)
        save_player(username, root)
        monster_update = _monster_update(titansoul_monster, "titansoul")
    return {
        "success": titansoul_monster is not None,
        "titansoul_id": SFSLong(titansoul_id),
    }, monster_update


def apply_feed(player_object, monster, user_monster_id, charge_food=True):
    level = max(1, monster.get("level", 1) or 1)
    max_level = get_max_monster_level(monster.get("monster", 0))
    if level >= max_level:
        return None
    level_def = get_monster_level_definition(monster.get("monster", 0), level)
    food_cost = max(1, level_def.get("food", 20)) if level_def else 20
    times_fed = monster.get("times_fed", 0) + 1
    leveled_up = False
    if times_fed >= 4:
        level = min(level + 1, max_level)
        times_fed = 0
        leveled_up = True
    monster["times_fed"] = times_fed
    monster["level"] = level
    monster["last_fed"] = int(time.time() * 1000)
    if charge_food:
        player_object["food"] = max(0, (player_object.get("food", 0) or 0) - food_cost)

    update = {"user_monster_id": SFSLong(user_monster_id), "times_fed": times_fed}
    if leveled_up:
        update["level"] = level
        update["collected_coins"] = 0
        update["collected_ethereal"] = 0
        update["collected_relics"] = SFSFloat(0.0)
        update["last_collection"] = SFSLong(monster.get("last_collection", 0) or 0)
    update["properties"] = create_player_properties(player_object)
    return update


def feed_monster(username, params):
    monster_id = params.get("user_monster_id", 0)
    root, player_object = load_player(username)
    island = find_island(player_object, get_active_island_id(player_object))
    monster = find_monster(island, monster_id)
    if monster is None:
        return (
            action_result(False, "user_monster_id", monster_id, with_properties=True),
            {},
        )
    update = apply_feed(player_object, monster, monster_id)
    if update is None:
        return {"success": True}, {}
    save_player(username, root)
    return {"success": True}, update


_battle_training_cache = {}


def _battle_training_levels(monster_id):
    if "data" not in _battle_training_cache:
        data = load_db_json("db_battle_monster_training") or {}
        _battle_training_cache["data"] = {
            row.get("monster_id"): sorted(
                row.get("levels") or [], key=lambda lv: lv.get("level", 0)
            )
            for row in data.get("battle_monster_training_data") or []
            if row.get("monster_id") is not None
        }
    levels = _battle_training_cache["data"].get(monster_id)
    if levels:
        return levels
    definition = get_monster_definition(monster_id) or {}
    monster_cost = max(1, definition.get("cost_coins", 0) or 0)
    import math

    best = None
    for known_id, known_levels in _battle_training_cache["data"].items():
        known_cost = max(
            1, (get_monster_definition(known_id) or {}).get("cost_coins", 0) or 0
        )
        distance = abs(math.log(known_cost) - math.log(monster_cost))
        if known_levels and (best is None or distance < best[0]):
            best = (distance, known_levels)
    if best is None:
        return []
    return [
        {
            "level": lv.get("level"),
            "training_cost": max(0, int(lv.get("training_cost", 0) or 0)),
            "training_time": max(0, lv.get("training_time", 0) or 0),
        }
        for lv in best[1]
    ]


def battle_start_training(username, params):

    monster_id = params.get("monster_id", params.get("user_monster_id", 0))
    root, player_object = load_player(username)
    island, monster = find_monster_with_island(player_object, monster_id)
    if monster is None:
        return action_result(False, "monster_id", monster_id, with_properties=True), {}

    current_level = max(1, monster.get("level", 1) or 1)
    levels = _battle_training_levels(monster.get("monster", 0))
    next_def = next(
        (lv for lv in levels if lv.get("level", 0) == current_level + 1), None
    )
    if next_def is None:
        result = action_result(False, "monster_id", monster_id)
        result["message"] = "max_battle_level"
        result["properties"] = create_player_properties(player_object)
        return result, {}
    cost = max(0, _safe_int(next_def.get("training_cost")))
    if (player_object.get("coins", 0) or 0) < cost:
        result = action_result(False, "monster_id", monster_id)
        result["message"] = "not_enough_coins"
        result["properties"] = create_player_properties(player_object)
        return result, {}
    now = int(time.time() * 1000)
    training_ms = (
        0
        if msm_toggles.is_enabled("instant_timers")
        else max(0, _safe_int(next_def.get("training_time"))) * 1000
    )
    complete_on = now + training_ms
    player_object["coins"] = (player_object.get("coins", 0) or 0) - cost
    monster["is_training"] = 1
    monster["training_complete_on"] = complete_on
    monster["pending_battle_level"] = current_level + 1
    save_player(username, root)
    result = action_result(True, "monster_id", monster_id)
    result["properties"] = create_player_properties(player_object)
    add_actual_currencies(result, player_object)
    return result, _monster_update(monster, "training")


def battle_finish_training(username, params):

    monster_id = params.get("monster_id", params.get("user_monster_id", 0))
    root, player_object = load_player(username)
    island, monster = find_monster_with_island(player_object, monster_id)
    if monster is None or not monster.get("is_training"):
        return action_result(False, "monster_id", monster_id, with_properties=True), {}

    new_level = monster.get(
        "pending_battle_level", max(1, monster.get("level", 1) or 1) + 1
    )
    monster["level"] = new_level
    monster["is_training"] = 0
    monster["training_complete_on"] = 0
    monster.pop("pending_battle_level", None)
    save_player(username, root)
    result = action_result(True, "monster_id", monster_id)
    result["level"] = new_level
    result["properties"] = create_player_properties(player_object)
    result["is_training"] = 0
    return result, _monster_update(monster, "training")


_COLLECTION_PLAYER_KEY = {
    "ethereal_currency": "ethereal_currency",
    "starpower": "starpower",
    "egg_wildcards": "egg_wildcards",
    "relics": "relics",
}
_COLLECTION_STORED_FIELD = {
    "ethereal_currency": "collected_ethereal",
    "relics": "collected_relics",
}


def _collection_player_key(collection_type):
    return _COLLECTION_PLAYER_KEY.get(
        _normalize_collection_type(collection_type), "coins"
    )


def _collection_stored_field(collection_type):
    return _COLLECTION_STORED_FIELD.get(
        _normalize_collection_type(collection_type), "collected_coins"
    )


def _collection_result_key(collection_type):
    return _collection_player_key(collection_type)


def _collection_result_value(collection_type, amount):
    return amount


def _stored_collection_amount(monster, collection_type):
    stored_field = _collection_stored_field(collection_type)
    if stored_field == "collected_coins":
        return _safe_int(monster.get(stored_field))
    return max(0, int(_safe_float(monster.get(stored_field), 0.0)))


def _monster_stored_coins(monster, max_coins, income_rate):
    stored = 0
    now = int(time.time() * 1000)
    last_collection = monster.get("last_collection", 0) or 0
    if last_collection <= 0:
        last_collection = monster.get("date_created", 0) or 0
    if 0 < last_collection < now:
        elapsed_seconds = max(0, (now - last_collection) // 1000)
        per_minute = max(1, income_rate)
        stored += (elapsed_seconds * per_minute) // 60
    stored = max(stored, _safe_int(monster.get("collected_coins")))
    cap = max_coins if max_coins > 0 else 2147483647
    return min(stored, cap)


def _add_collected_currency(player_object, collection_type, amount):
    if amount <= 0:
        return
    player_key = _collection_player_key(collection_type)

    updated = (player_object.get(player_key, 0) or 0) + amount
    player_object[player_key] = updated
    actual_key = f"{player_key }_actual"
    if actual_key in player_object:
        player_object[actual_key] = updated
    if player_key == "egg_wildcards":
        player_object["playerEggWildcards"] = updated

    player_object["xp"] = _safe_int(player_object.get("xp")) + max(1, amount // 100)


def _find_paironormal_mode_owner(player_object, mode_unique_id):
    for island in player_object.get("islands") or []:
        if island is None:
            continue
        for monster in island.get("monsters") or []:
            if monster is None:
                continue
            for mode_index, mode in enumerate(monster.get("modes") or []):
                if (
                    isinstance(mode, dict)
                    and mode.get("user_monster_id") == mode_unique_id
                ):
                    return island, monster, mode, mode_index
    return None, None, None, None


def _paironormal_collectible_mode(monster):
    modes = monster.get("modes") or []
    if modes and isinstance(modes[0], dict):
        return modes[0], 0
    for mode_index, mode in enumerate(modes):
        if isinstance(mode, dict):
            return mode, mode_index
    return None, None


def _paironormal_mode_update(monster, mode, mode_index, player_object=None):
    update = {
        "user_monster_id": SFSLong(monster.get("user_monster_id", 0)),
        "mode": _safe_int(mode.get("mode"), mode_index),
        "collected_starpower": SFSFloat(mode.get("collected_starpower", 0.0) or 0.0),
        "last_collection": SFSLong(mode.get("last_collection", 0) or 0),
    }
    if player_object is not None:
        update["properties"] = create_player_properties(player_object)
    return update


def _collect_paironormal_monster(username, params, monster):
    now = int(time.time() * 1000)
    root, player_object = load_player(username)
    _island, fresh_monster = find_monster_with_island(
        player_object, monster.get("user_monster_id", 0)
    )
    if fresh_monster is None:
        return action_result(
            False,
            "user_monster_id",
            monster.get("user_monster_id", 0),
            with_properties=True,
        )
    mode, mode_index = _paironormal_collectible_mode(fresh_monster)
    monster_id = fresh_monster.get("user_monster_id", 0)
    if mode is None:
        return action_result(False, "user_monster_id", monster_id, with_properties=True)
    owed = float(mode.get("collected_starpower", 0.0) or 0.0)
    payout = max(0, int(owed))
    if owed <= 0:
        result = {
            "star": 0,
            "success": False,
            "message": "Normal monster: nothing to collect",
            "user_monster_id": SFSLong(monster_id),
        }
        return result
    if payout > 0:
        _add_collected_currency(player_object, "starpower", payout)
    mode["collected_starpower"] = max(0.0, owed - payout)
    mode["last_collection"] = now
    save_player(username, root)
    result = {"star": payout, "success": True, "user_monster_id": SFSLong(monster_id)}
    return result, {
        "monster_updates": [
            _paironormal_mode_update(fresh_monster, mode, mode_index, player_object)
        ]
    }


def _paironormal_mode_update_legacy(mode, mode_index):
    return {
        "user_monster_id": SFSLong(mode.get("user_monster_id", 0)),
        "mode": _safe_int(mode.get("mode"), mode_index),
        "collected_starpower": SFSFloat(mode.get("collected_starpower", 0.0) or 0.0),
        "last_collection": SFSLong(mode.get("last_collection", 0) or 0),
    }


def _collect_paironormal_mode(username, params, mode_unique_id):

    now = int(time.time() * 1000)
    root, player_object = load_player(username)
    island, monster, mode, mode_index = _find_paironormal_mode_owner(
        player_object, mode_unique_id
    )
    if mode is None:
        return action_result(
            False, "user_monster_id", mode_unique_id, with_properties=True
        )
    owed = float(mode.get("collected_starpower", 0.0) or 0.0)
    payout = max(0, int(owed))
    if owed <= 0:
        result = {
            "star": 0,
            "success": False,
            "message": "Normal monster: nothing to collect",
            "user_monster_id": SFSLong(mode_unique_id),
        }
        return result
    if payout > 0:
        _add_collected_currency(player_object, "starpower", payout)
    mode["collected_starpower"] = max(0.0, owed - payout)
    mode["last_collection"] = now
    save_player(username, root)
    result = {
        "star": payout,
        "success": True,
        "user_monster_id": SFSLong(mode_unique_id),
    }
    return result, {
        "monster_updates": [_paironormal_mode_update_legacy(mode, mode_index)]
    }


def collect_monster(username, params):
    monster_id = params.get("user_monster_id", 0)
    now = int(time.time() * 1000)
    root, player_object = load_player(username)
    active_island = find_island(player_object, get_active_island_id(player_object))
    if active_island is None:
        return action_result(False, "user_monster_id", monster_id, with_properties=True)
    if find_monster(active_island, monster_id) is None and monster_id != -1:
        _, _owner_monster, mode, _mode_index = _find_paironormal_mode_owner(
            player_object, monster_id
        )
        if mode is not None:
            return _collect_paironormal_mode(username, params, monster_id)

    if monster_id == -1:
        return collect_multi_monster(username, params)

    island, monster = find_monster_with_island(player_object, monster_id, active_island)
    if monster is None:
        return action_result(False, "user_monster_id", monster_id, with_properties=True)
    island_type = island_type_of(island) or 1
    if island_type == PAIRONORMAL_ISLAND_TYPE and monster.get("modes"):
        return _collect_paironormal_monster(username, params, monster)
    collection_type, max_coins, income_rate = compute_monster_economy(
        monster, island_type
    )
    payout = max(
        _monster_stored_coins(monster, max_coins, income_rate),
        _stored_collection_amount(monster, collection_type),
    )
    player_key = _collection_player_key(collection_type)
    result_key = _collection_result_key(collection_type)
    if payout <= 0:
        result = {
            result_key: _collection_result_value(collection_type, 0),
            "success": False,
            "message": "Normal monster: nothing to collect",
            "user_monster_id": SFSLong(monster_id),
        }
        return result, {}
    monster["collected_coins"] = 0
    stored_field = _collection_stored_field(collection_type)
    monster[stored_field] = 0.0 if stored_field == "collected_relics" else 0
    monster["last_collection"] = now
    _add_collected_currency(player_object, collection_type, payout)
    save_player(username, root)
    result = {
        result_key: _collection_result_value(collection_type, payout),
        "success": True,
        "user_monster_id": SFSLong(monster_id),
    }
    update = _monster_update(monster, "collect")
    update["properties"] = create_player_properties(player_object)
    return result, {"monster_updates": [update]}


def collect_multi_monster(username, params):
    now = int(time.time() * 1000)
    root, player_object = load_player(username)
    island = find_island(player_object, get_active_island_id(player_object))
    if island is None:
        return (
            action_result(
                False,
                "user_island_id",
                get_active_island_id(player_object),
                with_properties=True,
            ),
            {},
        )
    island_type = island_type_of(island) or 1
    monster_collections = []
    update_monster_list = []
    for monster in island.get("monsters") or []:
        if monster is None:
            continue
        if island_type == PAIRONORMAL_ISLAND_TYPE and monster.get("modes"):
            mode, mode_index = _paironormal_collectible_mode(monster)
            if mode is None:
                continue
            owed = float(mode.get("collected_starpower", 0.0) or 0.0)
            if owed <= 0:
                continue
            mode_payout = max(0, int(owed))
            if mode_payout > 0:
                _add_collected_currency(player_object, "starpower", mode_payout)
            mode["collected_starpower"] = max(0.0, owed - mode_payout)
            mode["last_collection"] = now
            mid = monster.get("user_monster_id", 0)
            monster_collections.append(
                {"star": mode_payout, "user_monster_id": SFSLong(mid)}
            )
            update_monster_list.append(
                _paironormal_mode_update(monster, mode, mode_index)
            )
            continue
        collection_type, max_coins, income_rate = compute_monster_economy(
            monster, island_type
        )
        payout = max(
            _monster_stored_coins(monster, max_coins, income_rate),
            _stored_collection_amount(monster, collection_type),
        )
        if payout > 0:
            result_key = _collection_result_key(collection_type)
            _add_collected_currency(player_object, collection_type, payout)
            monster["collected_coins"] = 0
            stored_field = _collection_stored_field(collection_type)
            monster[stored_field] = 0.0 if stored_field == "collected_relics" else 0
            monster["last_collection"] = now
            mid = monster.get("user_monster_id", 0)
            monster_collections.append(
                {
                    result_key: _collection_result_value(collection_type, payout),
                    "user_monster_id": SFSLong(mid),
                }
            )
            update_monster_list.append(_monster_update(monster, "collect"))
    island["last_collect_all"] = now
    save_player(username, root)
    result = {
        "success": True,
        "monster_collections": monster_collections,
        "update_monster_list": update_monster_list,
        "island": SFSLong(island.get("user_island_id", 0)),
        "last_collect_all": SFSLong(now),
        "properties": create_player_properties(player_object),
    }
    return result, {"monster_updates": update_monster_list}


def _register_bought_synthesis(island, synthesizer, user_egg):
    structure_id = synthesizer.get("user_structure_id", 0)
    ready_at = SFSLong(int(time.time() * 1000))
    user_egg["hatches_on"] = ready_at
    entry = {
        "used_critters": [],
        "started_on": user_egg.get("laid_on"),
        "success": True,
        "complete_on": ready_at,
        "structure": SFSLong(structure_id),
        "monster": user_egg.get("monster"),
    }
    island["synthesizing"] = [
        e
        for e in island.get("synthesizing") or []
        if e is not None and e.get("structure") != structure_id
    ]
    island["synthesizing"].append(entry)
    return entry


def repair_workshop_evolve_flags(island):
    if island is None:
        return
    for monster in island.get("monsters") or []:
        if (
            monster is None
            or monster.get("evolve_unlocked")
            or monster.get("awakened")
            or monster.get("ascend_pending")
        ):
            continue
        definition = get_monster_definition(monster.get("monster", 0)) or {}
        if is_box_monster_entity(definition):
            continue
        has_reqs = monster.get("has_evolve_reqs")
        if not has_reqs:
            continue
        if not definition.get("evolve_into"):
            if has_reqs == "[]" and monster.get("has_evolve_flexeggs") == "[]":
                monster.pop("has_evolve_reqs", None)
                monster.pop("has_evolve_flexeggs", None)
            continue
        requirements = definition.get("evolve_requirements")
        if requirements and has_reqs == requirements:
            monster["has_evolve_reqs"] = "[]"
            monster["has_evolve_flexeggs"] = "[]"


def repair_synthesizer_eggs(island):
    if island is None:
        return
    structures = island.get("structures") or []
    synthesizers = [
        s for s in structures if s is not None and _is_synthesizer_structure(s)
    ]
    if not synthesizers:
        return
    synth_ids = {s.get("user_structure_id") for s in synthesizers}
    entries = island.setdefault("synthesizing", [])
    covered = {e.get("structure") for e in entries if e is not None}
    for egg in island.get("eggs") or []:
        if (
            egg is None
            or egg.get("structure") not in synth_ids
            or egg.get("structure") in covered
        ):
            continue
        synthesizer = next(
            s
            for s in synthesizers
            if s.get("user_structure_id") == egg.get("structure")
        )
        entries.append(_register_bought_synthesis_entry(synthesizer, egg))
        covered.add(egg.get("structure"))
    for synthesizer in synthesizers:
        if (
            synthesizer.get("occupied")
            or synthesizer.get("has_egg")
            or synthesizer.get("obj_data")
            or synthesizer.get("obj_end")
        ):
            _clear_egg_holder_state(synthesizer)


def _register_bought_synthesis_entry(synthesizer, user_egg):
    return {
        "used_critters": [],
        "started_on": user_egg.get("laid_on"),
        "success": True,
        "complete_on": user_egg.get("hatches_on"),
        "structure": SFSLong(synthesizer.get("user_structure_id", 0)),
        "monster": user_egg.get("monster"),
    }


def _synthesizer_is_free(island, structure, occupied_holder_ids):
    structure_id = structure.get("user_structure_id")
    if (
        structure.get("occupied")
        or structure.get("has_egg")
        or structure_id in occupied_holder_ids
    ):
        return False
    for entry in island.get("synthesizing") or []:
        if entry is not None and entry.get("structure") == structure_id:
            return False
    return True


def _find_nursery(island, requested_structure_id, allow_synthesizer=False):
    structures = island.get("structures") or []
    eggs = island.get("eggs") or []
    occupied_holder_ids = {
        int(e.get("structure", 0) or 0)
        for e in eggs
        if e is not None and int(e.get("structure", 0) or 0) > 0
    }
    if requested_structure_id:
        for structure in structures:
            if (
                structure is None
                or structure.get("user_structure_id") != requested_structure_id
            ):
                continue
            if not is_egg_holder_structure(structure.get("structure", 0)):
                return None
            if _is_synthesizer_structure(structure):
                if allow_synthesizer and _synthesizer_is_free(
                    island, structure, occupied_holder_ids
                ):
                    return structure
                return None
            if (
                structure.get("occupied")
                or structure.get("has_egg")
                or structure.get("user_structure_id") in occupied_holder_ids
            ):
                return None
            return structure
    holders = [
        s
        for s in structures
        if s is not None
        and is_egg_holder_structure(s.get("structure", 0))
        and (allow_synthesizer or not _is_synthesizer_structure(s))
    ]

    def _is_plain_nursery(holder):
        definition = get_structure_definition(holder.get("structure", 0))
        return bool(definition) and definition.get("structure_type") == "nursery"

    holders.sort(key=lambda h: 0 if _is_plain_nursery(h) else 1)
    for holder in holders:
        holder_id = holder.get("user_structure_id", 0)
        if _is_synthesizer_structure(holder):
            if _synthesizer_is_free(island, holder, occupied_holder_ids):
                return holder
            continue
        if (
            not holder.get("occupied")
            and not holder.get("has_egg")
            and holder_id not in occupied_holder_ids
        ):
            return holder
    return None


def place_egg(
    player_object,
    island,
    monster_id,
    source,
    preferred_holder_id=None,
    modes=None,
    previous_name=None,
    ready=False,
    allow_synthesizer=False,
):
    if island is None or not monster_id:
        return None, None
    nursery = _find_nursery(island, preferred_holder_id or 0, allow_synthesizer)
    if nursery is None:
        return None, None
    next_egg_id = int(player_object.get("last_user_egg_id", 0) or 0) + 1
    player_object["last_user_egg_id"] = next_egg_id
    island_type = island_type_of(island) or 1
    island_uid = island.get("user_island_id", 1000 + island_type)
    nursery_sid = nursery.get("user_structure_id", 0)
    now = int(time.time() * 1000)
    build_ms = _effective_build_ms(monster_id)
    hatches_on = now if (ready or build_ms <= 0) else now + build_ms
    user_egg = {
        "monster": monster_id,
        "monster_id": monster_id,
        "laid_on": SFSLong(now),
        "hatches_on": SFSLong(hatches_on),
        "structure": SFSLong(nursery_sid),
        "island": SFSLong(island_uid),
        "user_egg_id": SFSLong(next_egg_id),
        "costume": {"eq": 0, "p": []},
        "book_value": (get_monster_definition(monster_id) or {}).get("cost_coins", 0)
        or 0,
    }
    if previous_name is not None:
        user_egg["previous_name"] = previous_name
    if modes is not None:
        user_egg["modes"] = modes
    if ready or build_ms <= 0:
        user_egg["ready"] = True
    if source:
        user_egg["source"] = source
    island.setdefault("eggs", []).append(user_egg)
    if not _is_synthesizer_structure(nursery):
        nursery["occupied"] = True
        nursery["has_egg"] = True
        nursery["viewed"] = False
        nursery["obj_data"] = 1
        nursery["obj_end"] = hatches_on
        nursery["finishing_time"] = hatches_on
        nursery["building_completed"] = hatches_on
    return user_egg, nursery


def _find_fallback_egg(eggs):
    return eggs[-1] if eggs else None


def _find_egg(island, user_egg_id):
    for egg in island.get("eggs") or []:
        if egg is not None and egg.get("user_egg_id") == user_egg_id:
            return egg
    return None


def _find_island_with_egg(player_object, user_egg_id):
    for island in player_object.get("islands") or []:
        if island is not None and _find_egg(island, user_egg_id) is not None:
            return island
    return None


def _find_egg_record(player_object, user_egg_id, params=None):
    if not user_egg_id:
        return None, None
    preferred_ids = _candidate_island_ids(player_object, params or {})
    for island_id in preferred_ids:
        island = find_island(player_object, island_id)
        egg = _find_egg(island, user_egg_id) if island is not None else None
        if egg is not None:
            return island, egg
    island = _find_island_with_egg(player_object, user_egg_id)
    egg = _find_egg(island, user_egg_id) if island is not None else None
    return island, egg


def extract_egg_costumes(username, params):
    user_egg_id = params.get("egg", 0) or 0
    requested_island_type = params.get("island", 0) or 0
    root, player_object = load_player(username)
    island, egg = _find_egg_record(player_object, user_egg_id, params)
    if egg is None:
        return {"success": False, "egg": SFSLong(user_egg_id)}
    monster_id = egg.get("monster", 0) or 0
    costume_id = get_costume_id_for_monster(monster_id)
    if not costume_id:
        return {"success": False, "egg": SFSLong(user_egg_id)}
    import msm_cardalbum

    msm_cardalbum.grant_costume(player_object, costume_id, 1)
    save_player(username, root)
    return {
        "egg": SFSLong(user_egg_id),
        "success": True,
        "island": requested_island_type or island_type_of(island),
        "rewards": {
            "updateCostumes": True,
            "loot": [
                {
                    "amount": 1,
                    "premium": False,
                    "scaled": False,
                    "scale": False,
                    "id": costume_id,
                    "type": 13,
                }
            ],
            "updateCostumesIsland": 0,
        },
        "properties": [{"costumes": player_object.get("costumes") or {"items": []}}],
    }


def _repair_process_refs_if_needed(player_object):
    import msm_islands

    return msm_islands.repair_orphaned_process_refs(player_object)


def buy_egg(username, params):
    monster_id = (
        params.get("monster_id")
        or params.get("monsterId")
        or params.get("monster")
        or params.get("entity_id")
        or params.get("id")
        or 0
    )
    root, player_object = load_player(username)
    process_refs_repaired = _repair_process_refs_if_needed(player_object)
    island = find_island(player_object, get_active_island_id(player_object))
    if island is None:
        if process_refs_repaired:
            save_player(username, root)
        return {"success": False}, {}
    island_type = island_type_of(island) or 1
    definition = get_monster_definition(monster_id)

    if (
        definition is not None
        and island_type != MAGICAL_NEXUS_ISLAND_TYPE
        and not monster_allowed_on_island(definition, island_type)
    ):
        resolved = resolve_monster_for_island(monster_id, island_type)
        if resolved != monster_id:
            monster_id = resolved
            definition = get_monster_definition(monster_id)
        if not monster_allowed_on_island(definition, island_type):
            home_type = _home_island_type_for(definition)
            if home_type and home_type != island_type:
                for candidate in player_object.get("islands") or []:
                    if candidate is not None and island_type_of(candidate) == home_type:
                        island = candidate
                        island_type = home_type
                        break

    requested_extra = (definition.get("extra") or {}) if definition else {}
    requested_paironormal_mode = None
    if requested_extra.get("minor"):
        requested_paironormal_mode = 0
    elif requested_extra.get("major"):
        requested_paironormal_mode = 1
    else:
        requested_common_name = (
            (definition.get("common_name") or "").lower() if definition else ""
        )
        if "(major)" in requested_common_name:
            requested_paironormal_mode = 0
        elif "(minor)" in requested_common_name:
            requested_paironormal_mode = 1

    if requires_direct_placement(get_monster_definition(monster_id), island_type):
        _deduct_egg_purchase_cost(player_object, monster_id)
        island_uid = island.get("user_island_id", 1000 + island_type)
        now = int(time.time() * 1000)
        build_ms = _effective_build_ms(monster_id)
        hatches_on = now if build_ms <= 0 else now + build_ms
        book_value = (get_monster_definition(monster_id) or {}).get(
            "cost_coins", 0
        ) or 0
        next_egg_id = int(player_object.get("last_user_egg_id", 0) or 0) + 1
        player_object["last_user_egg_id"] = next_egg_id
        user_egg = {
            "monster": monster_id,
            "monster_id": monster_id,
            "laid_on": SFSLong(now),
            "hatches_on": SFSLong(hatches_on),
            "structure": SFSLong(0),
            "island": SFSLong(island_uid),
            "user_egg_id": SFSLong(next_egg_id),
            "costume": {"eq": 0, "p": []},
            "book_value": book_value,
            "source": "direct_placement",
        }
        if requested_paironormal_mode is not None:
            user_egg["requested_paironormal_mode"] = requested_paironormal_mode
        island.setdefault("eggs", []).append(user_egg)
        properties = create_player_properties(player_object)
        append_inventory_property(properties, player_object)
        save_player(username, root)
        result = {
            "success": True,
            "remove_buyback": False,
            "properties": properties,
            "user_egg": user_egg,
        }
        return result, {}

    requested_structure_id = params.get("nursery_id") or params.get("structure_id") or 0
    nursery = _find_nursery(island, requested_structure_id, True)
    if nursery is None:
        if process_refs_repaired:
            save_player(username, root)
        result = {
            "success": False,
            "error": "NO_AVAILABLE_EGG_HOLDER",
            "message": "No egg holder is available.",
        }
        return result, {}
    build_ms = _effective_build_ms(monster_id)

    egg_modes = None
    buy_paironormal_mode = None
    paironormal_parent = (
        resolve_paironormal_stored_monster_id(monster_id, island_type)
        if is_paironormal_island(island_type)
        else monster_id
    )
    if is_paironormal_island(island_type) and is_paironormal_multimodal(
        get_monster_definition(paironormal_parent)
    ):
        if requested_paironormal_mode is not None:
            buy_paironormal_mode = requested_paironormal_mode
        else:
            stored_mode = island.get("mode", island.get("island_mode"))
            if stored_mode is not None:
                buy_paironormal_mode = int(stored_mode)
        minor_bought = buy_paironormal_mode == 1
        egg_modes = [
            {"a": 0 if minor_bought else 1, "level": 1},
            {"a": 1 if minor_bought else 0, "level": 1},
        ]
    user_egg, nursery = place_egg(
        player_object,
        island,
        monster_id,
        "buy_egg",
        requested_structure_id,
        modes=egg_modes,
        allow_synthesizer=True,
    )
    if user_egg is not None and buy_paironormal_mode is not None:
        user_egg["requested_paironormal_mode"] = buy_paironormal_mode
    if user_egg is None or nursery is None:
        if process_refs_repaired:
            save_player(username, root)
        return {"success": False, "error": "NO_AVAILABLE_EGG_HOLDER"}, {}
    synthesis_data = (
        _register_bought_synthesis(island, nursery, user_egg)
        if _is_synthesizer_structure(nursery)
        else None
    )
    _deduct_egg_purchase_cost(player_object, monster_id)
    properties = create_player_properties(player_object)
    append_inventory_property(properties, player_object)
    save_player(username, root)
    result = {
        "success": True,
        "remove_buyback": False,
        "properties": properties,
        "user_egg": user_egg,
    }
    if synthesis_data is not None:
        result["user_synthesizing_data"] = synthesis_data
    nursery_update = _nursery_touch_payload(nursery, player_object)
    return result, nursery_update


def _is_titansoul_definition(definition):
    if not definition:
        return False
    return (
        definition.get("class") or definition.get("fam") or ""
    ).upper() == "CLASS_TITANSOUL"


def backfill_titansoul_state(island):
    for monster in island.get("monsters") or []:
        if monster is None or monster.get("titansoul"):
            continue
        if _is_titansoul_definition(get_monster_definition(monster.get("monster"))):
            monster["titansoul"] = _default_titansoul_state()


def _default_titansoul_state():
    return {
        "create_reward_time": 0,
        "link_reset_time": 0,
        "num_links": 0,
        "soul_links": [],
        "rare_unlocked": False,
        "show_fx": True,
        "epic_unlocked": False,
        "num_unlinks": 0,
        "can_awaken": False,
        "rewards": [],
        "next_reward_time": 0,
        "awakened_state": 0,
    }


def _default_monster_name(definition):
    if msm_toggles.is_enabled("random_monster_names"):
        names = definition.get("names")
        if isinstance(names, list) and names:
            return random.choice(names)
    return definition.get("common_name") or definition.get("name") or ""


def _build_hatched_monster(
    monster_id,
    island,
    island_type,
    user_monster_id,
    pos_x,
    pos_y,
    flip,
    now,
    in_hotel=0,
    island_mode_override=None,
    player_object=None,
    reawakened_name=None,
):
    definition = get_monster_definition(monster_id)
    island_uid = island.get("user_island_id", 1000 + island_type)
    spawn_level = 1
    if msm_toggles.is_enabled("level20_spawns"):
        spawn_level = msm_toggles.get_int("monster_spawn_level", 20, 1, 100)

    if is_box_monster_entity(definition) and island_type in BOX_SIMPLE_ISLAND_TYPES:

        monster = {
            "user_monster_id": SFSLong(user_monster_id),
            "island": SFSLong(island_uid),
            "monster": monster_id,
            "pos_x": pos_x,
            "pos_y": pos_y,
            "flip": flip,
            "muted": 0,
            "level": spawn_level,
            "happiness": 0,
            "times_fed": 0,
            "name": _default_monster_name(definition),
            "in_hotel": in_hotel,
            "volume": SFSFloat(1.0),
            "last_collection": SFSLong(now),
            "last_feeding": SFSLong(now),
            "costume": {"eq": 0, "p": []},
        }
        apply_underling_box_state(monster, definition, island_type)
    elif (
        island_type == AMBER_ISLAND_TYPE
        and not reawakened_name
        and is_box_monster_entity(definition)
    ):
        monster = build_placeholder_box_monster(
            monster_id,
            definition,
            island_uid,
            user_monster_id,
            pos_x,
            pos_y,
            flip,
            now,
            island_type,
            force_locked=True,
            level=spawn_level,
        )
    elif is_box_monster_entity(definition) and not reawakened_name:
        monster = build_placeholder_box_monster(
            monster_id,
            definition,
            island_uid,
            user_monster_id,
            pos_x,
            pos_y,
            flip,
            now,
            island_type,
            level=spawn_level,
        )
    else:
        monster = {
            "user_monster_id": SFSLong(user_monster_id),
            "island": SFSLong(island_uid),
            "monster": monster_id,
            "pos_x": pos_x,
            "pos_y": pos_y,
            "flip": flip,
            "muted": 0,
            "level": spawn_level,
            "happiness": 0,
            "times_fed": 0,
            "name": reawakened_name or _default_monster_name(definition),
            "in_hotel": in_hotel,
            "volume": SFSFloat(1.0),
            "last_collection": SFSLong(now),
            "last_feeding": SFSLong(now),
            "costume": {"eq": 0, "p": []},
            "book_value": definition.get("cost_coins", 0) or 0,
        }

        if (
            definition.get("evolve_into")
            or definition.get("evolve_requirements")
            or definition.get("evolve_req_flexeggs")
        ):
            monster["has_evolve_reqs"] = "[]"
            monster["has_evolve_flexeggs"] = "[]"
        if _is_titansoul_definition(definition):
            monster["titansoul"] = _default_titansoul_state()

        if reawakened_name and is_box_monster_entity(definition):
            apply_awakened_box_state(monster, definition, island_type)

        if island_mode_override is not None:
            island_mode = island_mode_override
        else:
            common_name_lower = (definition.get("common_name") or "").lower()
            if "(major)" in common_name_lower:
                island_mode = 0
            elif "(minor)" in common_name_lower:
                island_mode = 1
            else:

                stored_mode = island.get("mode", island.get("island_mode"))
                island_mode = stored_mode if stored_mode is not None else 0
        build_paironormal_modes(monster, island_type, island_mode, player_object)
    return monster


def _liked_entity_ids(definition):
    return set(_liked_entity_values(definition).keys())


def _liked_entity_values(definition):
    liked = (definition or {}).get("happiness") or []
    values = {}
    for entry in liked:
        if not isinstance(entry, dict) or entry.get("entity") is None:
            continue
        entity_id = _safe_int_or_none(entry.get("entity"))
        if entity_id is None:
            continue
        value = _safe_int_or_none(entry.get("value"))
        values[entity_id] = 1 if value is None else value
    return values


def _safe_int_or_none(value):
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def _entity_rect(record, definition):
    x = _safe_int_or_none(record.get("pos_x")) or 0
    y = _safe_int_or_none(record.get("pos_y")) or 0
    sx = max(1, _safe_int_or_none((definition or {}).get("size_x")) or 1)
    sy = max(1, _safe_int_or_none((definition or {}).get("size_y")) or 1)
    return (x, y, x + sx, y + sy)


def _rects_touch(a, b):
    return not (
        a[2] < b[0] - 1 or b[2] < a[0] - 1 or a[3] < b[1] - 1 or b[3] < a[1] - 1
    )


def _has_happiness_tree(island):
    for s in island.get("structures") or []:
        if s is None:
            continue
        definition = get_structure_definition(s.get("structure", 0))
        if (definition or {}).get("structure_type") == "happiness_tree":
            return True
    return False


def recompute_island_happiness(island):
    if island is None:
        return []
    monsters = [m for m in (island.get("monsters") or []) if m is not None]
    structures = [s for s in (island.get("structures") or []) if s is not None]
    island_wide = _has_happiness_tree(island)

    placed = []
    for m in monsters:
        definition = get_monster_definition(m.get("monster", 0))
        entity_id = _safe_int_or_none((definition or {}).get("entity_id"))
        if entity_id is not None:
            placed.append((entity_id, _entity_rect(m, definition), m))
    for s in structures:
        definition = get_structure_definition(s.get("structure", 0))
        entity_id = _safe_int_or_none((definition or {}).get("entity_id"))
        if entity_id is not None:
            placed.append((entity_id, _entity_rect(s, definition), None))

    changed = []
    for m in monsters:
        definition = get_monster_definition(m.get("monster", 0))
        liked_values = _liked_entity_values(definition)
        if not liked_values:
            continue
        own_entity_id = _safe_int_or_none((definition or {}).get("entity_id"))
        liked_values.pop(own_entity_id, None)
        my_rect = _entity_rect(m, definition)
        satisfied = set()
        for entity_id, rect, source in placed:
            if entity_id not in liked_values or source is m:
                continue
            if island_wide or _rects_touch(my_rect, rect):
                satisfied.add(entity_id)
        new_happiness = min(100, len(satisfied) * 25)
        if new_happiness != (m.get("happiness", 0) or 0):
            m["happiness"] = new_happiness
            changed.append(
                {
                    "user_monster_id": SFSLong(m.get("user_monster_id", 0)),
                    "happiness": new_happiness,
                }
            )
    return changed


def hatch_egg(username, params):
    pos_x = params.get("pos_x", 0)
    pos_y = params.get("pos_y", 0)
    flip = params.get("flip", 0)
    user_egg_id = params.get("user_egg_id", params.get("userEggId", 0)) or 0
    root, player_object = load_player(username)
    island, matched_egg = _find_egg_record(player_object, user_egg_id, params)
    if island is None:
        direct_monster_id = (
            params.get("monster_id")
            or params.get("monsterId")
            or params.get("monster")
            or params.get("entity_id")
            or params.get("id")
            or user_egg_id
        )
        candidate_definition = get_monster_definition(direct_monster_id)
        active_island = find_island(player_object, get_active_island_id(player_object))
        active_island_type = island_type_of(active_island) or 1
        if (
            active_island is not None
            and direct_monster_id > 0
            and (
                requires_direct_placement(candidate_definition, active_island_type)
                or is_box_monster_entity(candidate_definition)
            )
        ):
            island = active_island
        else:
            return {"success": False, "user_egg_id": SFSLong(user_egg_id)}
    eggs = island.setdefault("eggs", [])
    island_type = island_type_of(island) or 1
    nursery = None
    requested_paironormal_mode = None
    reawakened_name = (
        matched_egg.get("previous_name") if matched_egg is not None else None
    )
    if (
        not reawakened_name
        and matched_egg is not None
        and matched_egg.get("source") == "wake_wubbox"
    ):
        reawakened_name = (
            get_monster_definition(matched_egg.get("monster", 0)) or {}
        ).get("common_name") or "?"
    cleared_nursery = None
    synthesizer_id = None
    consumed_egg_id = 0
    if matched_egg is None:
        direct_monster_id = (
            params.get("monster_id")
            or params.get("monsterId")
            or params.get("monster")
            or params.get("entity_id")
            or params.get("id")
            or user_egg_id
        )
        candidate_definition = get_monster_definition(direct_monster_id)
        if direct_monster_id > 0 and (
            requires_direct_placement(candidate_definition, island_type)
            or is_box_monster_entity(candidate_definition)
        ):
            monster_id = direct_monster_id

            for pending_egg in list(eggs):
                if (
                    pending_egg is not None
                    and pending_egg.get("monster") == monster_id
                    and (
                        pending_egg.get("previous_name")
                        or pending_egg.get("source") == "wake_wubbox"
                    )
                ):
                    reawakened_name = (
                        pending_egg.get("previous_name")
                        or (get_monster_definition(monster_id) or {}).get("common_name")
                        or "?"
                    )
                    pending_nursery_id = pending_egg.get("structure", 0)
                    for structure in island.get("structures") or []:
                        if (
                            structure is not None
                            and structure.get("user_structure_id") == pending_nursery_id
                        ):
                            cleared_nursery = _clear_egg_holder_state(structure)
                            nursery = structure
                            break
                    consumed_egg_id = pending_egg.get("user_egg_id", 0) or 0
                    eggs.remove(pending_egg)
                    break
        else:
            return {"success": False, "user_egg_id": SFSLong(user_egg_id)}
    else:
        monster_id = max(1, matched_egg.get("monster", 3) or 3)
        requested_paironormal_mode = matched_egg.get("requested_paironormal_mode")
        nursery_id = matched_egg.get("structure", 0)
        for structure in island.get("structures") or []:
            if (
                structure is not None
                and structure.get("user_structure_id") == nursery_id
            ):
                nursery = structure
                break

        if nursery is not None and is_nursery_structure(
            nursery.get("structure", nursery.get("structure_id", 0))
        ):
            nursery["occupied"] = False
            nursery["has_egg"] = False
            nursery["obj_data"] = 0
            nursery["obj_end"] = 0
            nursery["finishing_time"] = 0
            cleared_nursery = nursery
        elif nursery_id:
            used_synth_monster = 0
            if island.get("synthesizing"):
                for synth in island.get("synthesizing") or []:
                    if synth is not None and synth.get("structure") == nursery_id:
                        used_synth_monster = synth.get("used_monster", 0) or 0
                        break
                island["synthesizing"] = [
                    s
                    for s in island.get("synthesizing") or []
                    if s is None or s.get("structure") != nursery_id
                ]
            if used_synth_monster:
                for i in range(len(island.get("monsters") or []) - 1, -1, -1):
                    source_monster = (island.get("monsters") or [])[i]
                    if (
                        source_monster is not None
                        and source_monster.get("user_monster_id") == used_synth_monster
                    ):
                        del island["monsters"][i]
                        break
            cleared_nursery = _clear_egg_holder_state(nursery)
            if nursery is not None and _is_synthesizer_structure(nursery):
                synthesizer_id = nursery.get("user_structure_id", nursery_id)
        eggs.remove(matched_egg)
    monster_id = resolve_monster_for_island(monster_id, island_type)
    definition = get_monster_definition(monster_id)
    if definition is None:
        result = {
            "success": False,
            "error": "monster_not_available",
            "user_egg_id": SFSLong(user_egg_id),
        }
        return result
    user_monster_id = max(
        int(player_object.get("last_user_monster_id", 0) or 0) + 1,
        20000 + random.randint(0, 899999),
    )
    player_object["last_user_monster_id"] = user_monster_id
    island_uid = island.get("user_island_id", 1000 + island_type)
    now = int(time.time() * 1000)
    monster = _build_hatched_monster(
        monster_id,
        island,
        island_type,
        user_monster_id,
        pos_x,
        pos_y,
        flip,
        now,
        island_mode_override=requested_paironormal_mode,
        player_object=player_object,
        reawakened_name=reawakened_name,
    )
    monsters = island.setdefault("monsters", [])
    monsters.append(monster)
    island_monster_count = len(monsters)
    island["num_monsters"] = island_monster_count
    _mark_monster_collected_in_book(island, monster_id)
    happy_effects = recompute_island_happiness(island)

    import mod_api

    mod_api.fire_event(
        "player_hatch",
        username=username,
        player_object=player_object,
        monster=monster,
        island=island,
    )
    mod_api.fire_event(
        "egg_hatched",
        username=username,
        player_object=player_object,
        monster=monster,
        island=island,
        egg=matched_egg or {"user_egg_id": user_egg_id},
    )
    xp_gain = definition.get("xp", 0) or 0
    if xp_gain > 0:
        player_object["xp"] = (player_object.get("xp", 0) or 0) + xp_gain
    import msm_composer

    composer_track = (
        msm_composer.track_for_monster(player_object, island, user_monster_id)
        if msm_composer.is_composer_island(island)
        else None
    )
    properties = create_player_properties(player_object)
    save_player(username, root)
    result = {
        "success": True,
        "create_in_storage": False,
        "directPlace": nursery is None,
        "user_egg_id": SFSLong(consumed_egg_id or user_egg_id),
        "island": SFSLong(island_uid),
        "properties": properties,
        "monster": monster,
        "monster_happy_effects": happy_effects,
    }
    if composer_track is not None:
        result["track_data"] = msm_composer.wire_track(composer_track)
        composer_song = msm_composer.find_song(player_object, island_uid)
        if composer_song is not None:
            result["song_data"] = msm_composer.wire_song(composer_song)
    if synthesizer_id is not None:
        result["synthesizer_collected"] = SFSLong(synthesizer_id)
    elif cleared_nursery is not None:
        result["nursery_update"] = _nursery_touch_payload(
            cleared_nursery, player_object
        )
    return result


def sell_egg(username, params):
    user_egg_id = params.get("user_egg_id", params.get("userEggId", 0)) or 0
    root, player_object = load_player(username)
    island, matched_egg = _find_egg_record(player_object, user_egg_id, params)
    result = {
        "success": False,
        "user_egg_id": SFSLong(user_egg_id),
        "properties": create_player_properties(player_object),
    }
    if island is None:
        return result, {}
    eggs = island.get("eggs") or []
    if matched_egg is None:
        return result, {}
    nursery_id = matched_egg.get("structure", 0)
    nursery = None
    for structure in island.get("structures") or []:
        if structure is not None and structure.get("user_structure_id") == nursery_id:
            nursery = structure
            break
    cleared_nursery = _clear_egg_holder_state(nursery)

    if msm_toggles.is_enabled("functioning_currencies"):
        egg_monster_id = (
            matched_egg.get("monster") or matched_egg.get("monster_id") or 0
        )
        book_value = (
            matched_egg.get("book_value")
            or (get_monster_definition(egg_monster_id) or {}).get("cost_coins", 0)
            or 0
        )
        refund = _sell_refund(book_value)
        if refund > 0:
            player_object["coins"] = (player_object.get("coins", 0) or 0) + refund
    eggs.remove(matched_egg)
    save_player(username, root)
    result["success"] = True
    result["properties"] = create_player_properties(player_object)
    nursery_update = (
        _nursery_touch_payload(cleared_nursery, player_object)
        if cleared_nursery is not None
        else {}
    )
    return result, nursery_update


def speed_up_hatching(username, params):
    user_egg_id = params.get("user_egg_id", params.get("userEggId", 0)) or 0
    root, player_object = load_player(username)
    result = {"success": False, "properties": create_player_properties(player_object)}
    add_actual_currencies(result, player_object)
    if not user_egg_id:
        return result, {}
    island, egg = _find_egg_record(player_object, user_egg_id, params)
    if island is not None and egg is not None:
        now = int(time.time() * 1000)
        laid_on = egg.get("laid_on", 0) or 0
        _charge_speedup(player_object, (egg.get("hatches_on", now) or now) - now)
        egg["hatches_on"] = SFSLong(laid_on)
        egg["ready"] = True
        nursery_id = egg.get("structure", 0)
        nursery = None
        for structure in island.get("structures") or []:
            if (
                structure is not None
                and structure.get("user_structure_id") == nursery_id
            ):
                nursery = structure
                break
        if nursery is not None and not _is_synthesizer_structure(nursery):
            nursery["occupied"] = True
            nursery["has_egg"] = True
            nursery["obj_data"] = 1
            nursery["obj_end"] = laid_on
        elif nursery is not None:
            _clear_egg_holder_state(nursery)
        save_player(username, root)
        result["success"] = True
        result["user_egg_id"] = SFSLong(user_egg_id)
        result["laid_on"] = SFSLong(laid_on)
        result["hatches_on"] = SFSLong(laid_on)
        result["properties"] = create_player_properties(player_object)
        add_actual_currencies(result, player_object)
        nursery_update = (
            _nursery_touch_payload(nursery, player_object)
            if nursery is not None and not _is_synthesizer_structure(nursery)
            else {}
        )
        return result, nursery_update
    return result, {}


def viewed_egg(username, params):
    user_egg_id = params.get("user_egg_id", params.get("userEggId", 0)) or 0
    root, player_object = load_player(username)
    island, egg = _find_egg_record(player_object, user_egg_id, params)
    sold_update = None
    if egg is not None:
        egg["viewed"] = True
        _mark_monster_collected_in_book(island, egg.get("monster", 0))
        sold_update = _mark_monster_viewed_in_sold(island, egg.get("monster", 0))
        nursery_id = egg.get("structure", 0)
        nursery = None
        for structure in island.get("structures") or []:
            if (
                structure is not None
                and structure.get("user_structure_id") == nursery_id
            ):
                nursery = structure
                break
        if nursery is None:
            nursery = _find_nursery(island, nursery_id)
        if nursery is not None and not _is_synthesizer_structure(nursery):
            nursery["viewed"] = True
            nursery["has_egg"] = True
            nursery["occupied"] = True
        elif nursery is not None:
            _clear_egg_holder_state(nursery)
        save_player(username, root)
    return {"success": True}, sold_update


def claim_hatched_egg(username, params):
    result = {"success": True, "properties": []}
    for key in ("user_egg_id", "user_monster_id", "island", "structure_id"):
        value = params.get(key, 0) or 0
        if value:
            result[key] = SFSLong(value)
    monster = params.get("monster")
    if isinstance(monster, dict):
        result["monster"] = monster
    return result


def store_monster(username, params):
    monster_id = params.get("user_monster_id", 0)
    root, player_object = load_player(username)
    island, monster = find_monster_with_island(player_object, monster_id)
    if monster is not None:
        monster["in_hotel"] = 1
        save_player(username, root)
    return {"success": monster is not None, "user_monster_id": SFSLong(monster_id)}


def unstore_monster(username, params):
    monster_id = params.get("user_monster_id", 0)
    root, player_object = load_player(username)
    island, monster = find_monster_with_island(player_object, monster_id)
    if monster is not None:
        monster["in_hotel"] = 0
        pos_x = params.get("pos_x", monster.get("pos_x", 0))
        pos_y = params.get("pos_y", monster.get("pos_y", 0))
        flip = params.get("flip", monster.get("flip", 0))
        monster["pos_x"] = pos_x
        monster["pos_y"] = pos_y
        monster["col"] = pos_x
        monster["row"] = pos_y
        monster["flip"] = flip
        monster["flipped"] = flip
        save_player(username, root)
    return {"success": monster is not None, "user_monster_id": SFSLong(monster_id)}


def costume_action(username, params, command):
    costume_id = (
        params.get("costume_id") or params.get("costume") or params.get("id") or 0
    )
    monster_id = (
        params.get("monster_id")
        or params.get("user_monster_id")
        or params.get("userMonsterId")
        or 0
    )
    result = {"success": True}
    if monster_id:
        result["monster_id"] = SFSLong(monster_id)
    if costume_id:
        result["costume_id"] = costume_id
    root, player_object = load_player(username)
    dirty = False
    if command == "purchase_costume" and msm_toggles.is_enabled(
        "functioning_currencies"
    ):
        costume_definition = get_costume_definition(costume_id) or {}
        cost_diamonds = costume_definition.get("diamondCost", 0) or 0
        cost_medals = costume_definition.get("medalCost", 0) or 0
        if cost_diamonds > 0:
            player_object["diamonds"] = max(
                0, (player_object.get("diamonds", 0) or 0) - cost_diamonds
            )
            dirty = True
        elif cost_medals > 0:
            player_object["medals"] = max(
                0, (player_object.get("medals", 0) or 0) - cost_medals
            )
            dirty = True
    if monster_id:
        _, monster = find_monster_with_island(player_object, monster_id)
        if monster is not None:
            existing = monster.get("costume") or {}
            monster["costume"] = {"eq": costume_id, "p": existing.get("p", [])}
            dirty = True
    if dirty:
        save_player(username, root)
    if command == "purchase_costume":
        result["properties"] = create_player_properties(player_object)
    return result


def update_owned_costumes(username, params):
    root, player_object = load_player(username)
    island_id = player_object.get("active_island", 1001) or 1001
    return {
        "success": True,
        "costumes_owned": "[" + ",".join(str(i) for i in range(1, 901)) + "]",
        "island_id": SFSLong(island_id),
        "properties": create_player_properties(player_object),
    }


def _candidate_island_ids(player_object, params):
    ids = []
    for key in ("user_island_id", "island_id", "island", "active_island"):
        value = params.get(key) if isinstance(params, dict) else None
        if value and value not in ids:
            ids.append(value)
    active = player_object.get("active_island")
    if active and active not in ids:
        ids.append(active)
    return ids


def _find_breeding_record(player_object, breeding_id, params=None):
    if not breeding_id:
        return None, None
    preferred_ids = _candidate_island_ids(player_object, params or {})
    if preferred_ids:
        for island in player_object.get("islands") or []:
            if island is None or island.get("user_island_id") not in preferred_ids:
                continue
            for record in island.get("breeding") or []:
                if record is not None and record.get("user_breeding_id") == breeding_id:
                    return island, record
    for island in player_object.get("islands") or []:
        if island is None:
            continue
        for record in island.get("breeding") or []:
            if record is not None and record.get("user_breeding_id") == breeding_id:
                return island, record
    return None, None


def _find_breeding_record_by_structure(player_object, structure_id):
    if not structure_id:
        return None, None
    for island in player_object.get("islands") or []:
        if island is None:
            continue
        for record in island.get("breeding") or []:
            if record is not None and record.get("structure") == structure_id:
                return island, record
    return None, None


def _locate_breeding_structure(player_object, structure_id):
    island, structure = (None, None)
    if structure_id:
        island, structure = find_island_by_structure(player_object, structure_id)
    return island, structure


def breed_monsters(username, params):
    structure_id = (
        params.get("structure_id")
        or params.get("user_structure_id")
        or params.get("user_breeding_id")
        or 0
    )
    parent_a_id = params.get("user_monster_1") or params.get("user_monster_id_1") or 0
    parent_b_id = params.get("user_monster_2") or params.get("user_monster_id_2") or 0
    root, player_object = load_player(username)
    process_refs_repaired = _repair_process_refs_if_needed(player_object)
    island, structure = _locate_breeding_structure(player_object, structure_id)
    if island is None:
        island = find_island(player_object, get_active_island_id(player_object))
    if structure is None and structure_id and island is not None:
        structure = find_structure(island, structure_id)
    if island is None or structure is None:
        if process_refs_repaired:
            save_player(username, root)
        return action_result(
            False, "user_structure_id", structure_id, with_properties=True
        )
    parent_a = find_monster(island, parent_a_id)
    parent_b = find_monster(island, parent_b_id)
    if parent_a is None or parent_b is None or parent_a_id == parent_b_id:
        if process_refs_repaired:
            save_player(username, root)
        return action_result(
            False, "user_structure_id", structure_id, with_properties=True
        )
    structure_sid = structure.get("user_structure_id", 0)
    breeding_list = island.setdefault("breeding", [])
    for existing in breeding_list:
        if existing is not None and existing.get("structure") == structure_sid:
            result = action_result(
                False, "user_structure_id", structure_id, with_properties=True
            )
            result["error"] = "BREEDING_STRUCTURE_BUSY"
            if process_refs_repaired:
                save_player(username, root)
            return result
    monster_id = choose_breeding_result_monster(
        parent_a.get("monster", 0),
        parent_b.get("monster", 0),
        island_type_of(island) or 0,
    )
    now = int(time.time() * 1000)
    build_ms = _effective_build_ms(monster_id)
    complete_on = now + build_ms
    next_breeding_id = max(
        int(player_object.get("last_user_breeding_id", 0) or 0) + 1, structure_sid + 1
    )
    player_object["last_user_breeding_id"] = next_breeding_id
    island_uid = island.get("user_island_id", 0)
    record = {
        "started_on": SFSLong(now),
        "island": SFSLong(island_uid),
        "new_monster": monster_id,
        "complete_on": SFSLong(complete_on),
        "user_breeding_id": SFSLong(next_breeding_id),
        "structure": SFSLong(structure_sid),
        "monster_1": parent_a.get("monster", 0),
        "monster_2": parent_b.get("monster", 0),
    }
    breeding_list.append(record)
    import msm_rewardtracks

    points = msm_rewardtracks.points_for_duration(_base_build_ms(monster_id) / 1000)
    properties = msm_rewardtracks.properties_with_encore(
        player_object, 2, points, action_kind="breed"
    )
    save_player(username, root)
    return {
        "success": True,
        "user_structure_id": SFSLong(structure_sid),
        "user_monster_1": SFSLong(parent_a_id),
        "user_monster_2": SFSLong(parent_b_id),
        "user_breeding": record,
        "properties": properties,
    }


def speed_up_breeding(username, params):
    breeding_id = params.get("user_breeding_id") or params.get("breeding_id") or 0
    structure_id = (
        params.get("structure_id")
        or params.get("user_structure_id")
        or params.get("breeding_structure_id")
        or 0
    )
    root, player_object = load_player(username)
    process_refs_repaired = _repair_process_refs_if_needed(player_object)
    island, record = _find_breeding_record(player_object, breeding_id, params)
    if record is None:
        island, record = _find_breeding_record_by_structure(
            player_object, breeding_id or structure_id
        )
    if record is None:
        if process_refs_repaired:
            save_player(username, root)
        result = {
            "success": False,
            "properties": create_player_properties(player_object),
        }
        return result, {}
    now = int(time.time() * 1000)
    remaining = (record.get("complete_on", now) or now) - now
    _charge_speedup(player_object, remaining)
    complete_on = now - 1000
    record["complete_on"] = SFSLong(complete_on)
    save_player(username, root)
    result = {
        "success": True,
        "started_on": record.get("started_on"),
        "complete_on": SFSLong(complete_on),
        "userBreedingId": record.get("user_breeding_id"),
        "properties": create_player_properties(player_object),
    }
    return result, {}


def finish_breeding(username, params, force_complete=False):
    breeding_id = params.get("user_breeding_id") or params.get("breeding_id") or 0
    structure_id = (
        params.get("structure_id")
        or params.get("user_structure_id")
        or params.get("breeding_structure_id")
        or 0
    )
    root, player_object = load_player(username)
    process_refs_repaired = _repair_process_refs_if_needed(player_object)
    island, record = _find_breeding_record(player_object, breeding_id, params)
    if record is None:
        island, record = _find_breeding_record_by_structure(
            player_object, breeding_id or structure_id
        )
    if island is None or record is None:
        if process_refs_repaired:
            save_player(username, root)
        return action_result(
            False, "user_breeding_id", breeding_id, with_properties=True
        )
    now = int(time.time() * 1000)
    complete_on = record.get("complete_on", 0) or 0
    if not force_complete and complete_on > now:
        result = action_result(
            False, "user_breeding_id", breeding_id, with_properties=True
        )
        result["complete_on"] = SFSLong(complete_on)
        if process_refs_repaired:
            save_player(username, root)
        return result
    monster_id = record.get("new_monster") or 0
    if not monster_id:
        parent_a_monster = record.get("monster_1", 0)
        parent_b_monster = record.get("monster_2", 0)
        monster_id = choose_breeding_result_monster(
            parent_a_monster, parent_b_monster, island_type_of(island) or 0
        )
    if not monster_id:
        if process_refs_repaired:
            save_player(username, root)
        return action_result(
            False, "user_breeding_id", breeding_id, with_properties=True
        )
    build_ms = _effective_build_ms(monster_id)
    speedup = bool(
        params.get("speedup") or params.get("speed_up") or params.get("speedUp")
    )
    user_egg, nursery = place_egg(
        player_object, island, monster_id, "finish_breeding", ready=speedup
    )
    if user_egg is None or nursery is None:
        result = action_result(
            False, "user_breeding_id", breeding_id, with_properties=True
        )
        result["error"] = "NO_AVAILABLE_EGG_HOLDER"
        if process_refs_repaired:
            save_player(username, root)
        return result
    nursery_sid = nursery.get("user_structure_id", 0)
    nursery["viewed"] = True
    finished_breeding_id = record.get("user_breeding_id", 0) or breeding_id
    breeding_list = island.get("breeding") or []
    if record in breeding_list:
        breeding_list.remove(record)

    result = {
        "success": True,
        "user_structure_id": SFSLong(nursery_sid),
        "user_egg": user_egg,
        "user_breeding_id": SFSLong(finished_breeding_id),
    }
    if speedup:
        _charge_speedup(player_object, build_ms)
        result["properties"] = create_player_properties(player_object)
        add_actual_currencies(result, player_object)
    save_player(username, root)
    return result


def _resolve_teleport_target_island(
    player_object, requested_island_id, requested_island_type, send_home
):
    if not send_home and not requested_island_id and not requested_island_type:
        requested_island_type = 20
    for island in player_object.get("islands") or []:
        if island is None:
            continue
        user_island_id = island.get("user_island_id", 0)
        island_type = island_type_of(island)
        looks_like_type = 0 < requested_island_id < 1000
        matches_requested = requested_island_id > 0 and (
            user_island_id == requested_island_id
            or (looks_like_type and island_type == requested_island_id)
            or (looks_like_type and user_island_id == requested_island_id + 1000)
        )
        if not send_home:
            if (
                matches_requested
                or (
                    not requested_island_id
                    and requested_island_type
                    and island_type == requested_island_type
                )
                or (
                    not requested_island_id
                    and not requested_island_type
                    and island_type == 20
                )
            ):
                return island
        elif matches_requested or user_island_id == requested_island_id:
            return island
    return None


def move_battle_monster(username, params, send_home):
    monster_id = (
        params.get("user_monster_id")
        or params.get("monster_id")
        or params.get("source_user_monster_id")
        or params.get("id")
        or 0
    )
    requested_island_id = (
        params.get("destination_user_island_id")
        or params.get("target_user_island_id")
        or params.get("dest_island_id")
        or params.get("destination_island_id")
        or params.get("to_user_island_id")
        or 0
    )
    requested_island_type = (
        params.get("destination_island")
        or params.get("target_island")
        or params.get("dest_island")
        or params.get("sent_to_island")
        or params.get("island_type")
        or params.get("to_island_type")
        or 0
    )
    raw_island = params.get("island") or params.get("to_island") or 0
    if raw_island:
        if raw_island >= 1000 and not requested_island_id:
            requested_island_id = raw_island
        if raw_island < 1000 and not requested_island_type:
            requested_island_type = raw_island
    if not monster_id:
        return {"success": False}
    root, player_object = load_player(username)
    source_island, monster = find_monster_with_island(player_object, monster_id)
    if monster is None:
        return {"success": False}
    target_island = _resolve_teleport_target_island(
        player_object, requested_island_id, requested_island_type, send_home
    )
    if target_island is None and send_home:
        home_island_id = monster.get("battle_home_island_id", 0)
        target_island = (
            find_island(player_object, home_island_id) if home_island_id else None
        )
    if target_island is None and send_home:
        definition = get_monster_definition(monster.get("monster", 0)) or {}
        native_type = _safe_int(definition.get("native_island"))
        if native_type:
            for island in player_object.get("islands") or []:
                if island is not None and island_type_of(island) == native_type:
                    target_island = island
                    break
    if target_island is None:
        return {"success": False}
    _ensure_battle_island_layout(target_island)
    nursery = next(
        (
            s
            for s in target_island.get("structures") or []
            if s
            and (get_structure_definition(s.get("structure", 0)) or {}).get(
                "structure_type"
            )
            == "nursery"
        ),
        None,
    )
    if nursery is None or not nursery.get("user_structure_id"):
        return {"success": False, "error": "NO_AVAILABLE_EGG_HOLDER"}
    source_island_id = source_island.get("user_island_id", 0)
    target_type = island_type_of(target_island)
    if source_island is not target_island:
        monster["pos_x"] = 10
        monster["pos_y"] = 10
        target_island.setdefault("monsters", []).append(monster)
        source_island["monsters"] = [
            m for m in (source_island.get("monsters") or []) if m is not monster
        ]
        if not send_home:
            monster["battle_home_island_id"] = source_island_id
            monster["battle_home_island"] = island_type_of(source_island)
    monster["island"] = target_island.get("user_island_id", 0)
    monster["island_type"] = target_type
    monster["user_island_id"] = target_island.get("user_island_id", 0)
    if send_home:
        monster.pop("battle_home_island_id", None)
        monster.pop("battle_home_island", None)
    save_player(username, root)
    return {
        "success": True,
        "user_monster_id": SFSLong(monster_id),
        "sent_to_island": target_type,
        "dest_nursery": SFSLong(nursery["user_structure_id"]),
    }


def send_monster_to_home_island(username, params):
    monster_id = (
        params.get("user_monster_id")
        or params.get("monster_id")
        or params.get("source_user_monster_id")
        or params.get("id")
        or 0
    )
    if not monster_id:
        return {"success": False}, None
    root, player_object = load_player(username)
    _source, monster = find_monster_with_island(player_object, monster_id)
    if monster is None:
        return {"success": False}, None
    definition = get_monster_definition(monster.get("monster", 0)) or {}
    home_id = _safe_int(monster.get("battle_home_island_id"))
    forwarded = dict(params)
    if home_id:
        forwarded["destination_user_island_id"] = home_id
        return teleport_monster_to_island(username, forwarded)

    home_type = _home_island_type_for(definition)
    if island_type_of(_source) in (7, 24):
        islet_types = [
            island_type
            for island_type in (26, 27, 28, 29)
            if monster_allowed_on_island(definition, island_type)
        ]
        if len(islet_types) == 1:
            home_type = islet_types[0]
    if home_type:
        forwarded["destination_island"] = home_type
        return teleport_monster_to_island(username, forwarded)

    current = _safe_int(params.get("user_island_id"))
    if current:
        forwarded["destination_user_island_id"] = current
        return teleport_monster_to_island(username, forwarded)
    return {"success": False}, None


SEASONAL_ISLAND_TYPE = 21
MYTHICAL_ISLAND_TYPE = 23
SHUGABUSH_ISLAND_TYPE = 8
ETHEREAL_ISLAND_TYPE = 7
MAGICAL_SANCTUM_ISLAND_TYPE = 19


def _home_island_type_for(definition):
    family = f"{definition .get ('fam','')} {definition .get ('class','')}".upper()
    levelup_island = str(definition.get("levelup_island") or "").strip().lower()
    if levelup_island == "ethereal":
        return ETHEREAL_ISLAND_TYPE
    if levelup_island == "magical_ethereal":
        return MAGICAL_SANCTUM_ISLAND_TYPE
    if "shugga" in levelup_island or "shugabush" in levelup_island:
        return SHUGABUSH_ISLAND_TYPE
    if "seasonal" in levelup_island:
        return SEASONAL_ISLAND_TYPE
    if levelup_island == "mythical":
        return MYTHICAL_ISLAND_TYPE
    if "CLASS_ETHEREAL" in family:
        return ETHEREAL_ISLAND_TYPE
    if "MAGICAL_ETHEREAL" in family:
        return MAGICAL_SANCTUM_ISLAND_TYPE
    if "SEASON" in family:
        return SEASONAL_ISLAND_TYPE
    if "SHUGA" in family or "SHUGABUSH" in family:
        return SHUGABUSH_ISLAND_TYPE
    if "MYTHICAL" in family:
        return MYTHICAL_ISLAND_TYPE
    return _safe_int(definition.get("native_island"))


def _complete_egg_teleport(
    username, root, source_island, target_island, monster, user_egg, nursery
):
    source_island["monsters"] = [
        m for m in (source_island.get("monsters") or []) if m is not monster
    ]
    island_uid = target_island.get("user_island_id", 0)
    nursery_sid = nursery.get("user_structure_id", 0)
    user_egg["structure"] = SFSLong(nursery_sid)
    user_egg["island"] = SFSLong(island_uid)
    for key in (
        "monster_id",
        "book_value",
        "source",
        "nursery_id",
        "user_structure_id",
        "user_island_id",
    ):
        user_egg.pop(key, None)
    nursery.pop("finishing_time", None)
    nursery["building_completed"] = _safe_int(
        nursery.get("date_created"), int(time.time() * 1000)
    )
    save_player(username, root)
    return {
        "success": True,
        "user_monster_id": SFSLong(monster.get("user_monster_id", 0)),
        "sent_to_island": island_type_of(target_island),
        "dest_nursery": SFSLong(nursery_sid),
        "user_island_id": SFSLong(island_uid),
        "user_egg": user_egg,
    }, nursery


def teleport_monster_to_island(username, params):
    monster_id = (
        params.get("user_monster_id")
        or params.get("monster_id")
        or params.get("source_user_monster_id")
        or params.get("id")
        or 0
    )
    if not monster_id:
        return {"success": False}, None

    requested_island_id = (
        params.get("destination_user_island_id")
        or params.get("target_user_island_id")
        or params.get("dest_island_id")
        or params.get("destination_island_id")
        or params.get("to_user_island_id")
        or 0
    )
    requested_island_type = (
        params.get("destination_island")
        or params.get("target_island")
        or params.get("dest_island")
        or params.get("sent_to_island")
        or params.get("island_type")
        or params.get("to_island_type")
        or 0
    )
    raw_island = params.get("island") or params.get("to_island") or 0
    if raw_island:
        if raw_island >= 1000 and not requested_island_id:
            requested_island_id = raw_island
        if raw_island < 1000 and not requested_island_type:
            requested_island_type = raw_island

    root, player_object = load_player(username)
    source_island, monster = find_monster_with_island(player_object, monster_id)
    if monster is None:
        return {"success": False}, None

    target_island = _resolve_teleport_target_island(
        player_object, requested_island_id, requested_island_type, False
    )
    if target_island is None:
        return {"success": False}, None

    target_type = island_type_of(target_island)
    monster_type = monster.get("monster", 0)

    if target_type == MAGICAL_NEXUS_ISLAND_TYPE:
        return send_to_magical_nexus(username, params)
    if target_type == PAIRONORMAL_ISLAND_TYPE:
        return send_to_paironormal(username, params)

    resolved_type = resolve_monster_for_island(monster_type, target_type)
    definition = get_monster_definition(resolved_type)
    if definition is None or not monster_allowed_on_island(definition, target_type):
        return {"success": False, "error": "MONSTER_NOT_ALLOWED_ON_ISLAND"}, None

    previous_name = monster.get("name")
    user_egg, nursery = place_egg(
        player_object,
        target_island,
        resolved_type,
        "teleport",
        previous_name=previous_name,
    )
    if user_egg is None or nursery is None:
        return {"success": False, "error": "NO_AVAILABLE_EGG_HOLDER"}, None

    return _complete_egg_teleport(
        username, root, source_island, target_island, monster, user_egg, nursery
    )


def send_to_magical_nexus(username, params):
    monster_id = (
        params.get("user_monster_id")
        or params.get("monster_id")
        or params.get("source_user_monster_id")
        or params.get("id")
        or 0
    )
    if not monster_id:
        return {"success": False}, None
    root, player_object = load_player(username)
    source_island, monster = find_monster_with_island(player_object, monster_id)
    if monster is None:
        return {"success": False}, None
    target_island = None
    for island in player_object.get("islands") or []:
        if island is not None and island_type_of(island) == MAGICAL_NEXUS_ISLAND_TYPE:
            target_island = island
            break
    if target_island is None:
        return {"success": False}, None
    repair_magical_nexus_layout(target_island)
    monster_type = monster.get("monster", 0)
    previous_name = monster.get("name")
    user_egg, nursery = place_egg(
        player_object,
        target_island,
        monster_type,
        "magical_nexus",
        previous_name=previous_name,
    )
    if user_egg is None or nursery is None:
        return {"success": False, "error": "NO_AVAILABLE_EGG_HOLDER"}, None
    return _complete_egg_teleport(
        username, root, source_island, target_island, monster, user_egg, nursery
    )


def send_to_paironormal(username, params):
    monster_id = (
        params.get("user_monster_id")
        or params.get("monster_id")
        or params.get("source_user_monster_id")
        or params.get("id")
        or 0
    )
    if not monster_id:
        return {"success": False}, None
    root, player_object = load_player(username)
    source_island, monster = find_monster_with_island(player_object, monster_id)
    if monster is None:
        return {"success": False}, None
    target_island = None
    for island in player_object.get("islands") or []:
        if island is not None and island_type_of(island) == PAIRONORMAL_ISLAND_TYPE:
            target_island = island
            break
    if target_island is None:
        return {"success": False}, None
    monster_type = monster.get("monster", 0)
    arriving_extra = (get_monster_definition(monster_type) or {}).get("extra") or {}
    arriving_mode = None
    if arriving_extra.get("minor"):
        arriving_mode = 0
    elif arriving_extra.get("major"):
        arriving_mode = 1
    egg_modes = None
    if arriving_mode is not None:
        minor_side = arriving_mode == 1
        egg_modes = [
            {"a": 0 if minor_side else 1, "level": 1},
            {"a": 1 if minor_side else 0, "level": 1},
        ]
    user_egg, nursery = place_egg(
        player_object, target_island, monster_type, "paironormal", modes=egg_modes
    )
    if user_egg is None or nursery is None:
        return {"success": False, "error": "NO_AVAILABLE_EGG_HOLDER"}, None
    if arriving_mode is not None:
        user_egg["requested_paironormal_mode"] = arriving_mode
    nursery["viewed"] = True
    return _complete_egg_teleport(
        username, root, source_island, target_island, monster, user_egg, nursery
    )


_GOLD_EPIC_WUBBOX_START_NAME = "Gold Island Epic Wubbox 01"
_gold_epic_wubbox_start_id_cache = None


def _gold_epic_wubbox_start_id():
    global _gold_epic_wubbox_start_id_cache
    if _gold_epic_wubbox_start_id_cache is None:
        _gold_epic_wubbox_start_id_cache = 0
        for mid in all_monster_ids():
            definition = get_monster_definition(mid) or {}
            if (definition.get("common_name") or "") == _GOLD_EPIC_WUBBOX_START_NAME:
                _gold_epic_wubbox_start_id_cache = mid
                break
    return _gold_epic_wubbox_start_id_cache


def _is_source_epic_wubbox(definition):
    name = (definition or {}).get("common_name") or ""
    return name.lower().startswith("epic wubbox")


def place_on_gold_island(username, params):
    monster_id = (
        params.get("user_monster_id")
        or params.get("monster_id")
        or params.get("source_user_monster_id")
        or params.get("id")
        or 0
    )
    pos_x = params.get("pos_x", 20)
    pos_y = params.get("pos_y", 18)
    if not monster_id:
        return {"success": False}
    root, player_object = load_player(username)
    source_island, monster = find_monster_with_island(player_object, monster_id)
    if monster is None:
        return {"success": False}
    gold_island = None
    for island in player_object.get("islands") or []:
        if island is not None and island_type_of(island) == GOLD_ISLAND_TYPE:
            gold_island = island
            break
    if gold_island is None:
        return {"success": False}
    next_id = max(
        int(player_object.get("last_user_monster_id", 0) or 0) + 1,
        20000 + random.randint(0, 899999),
    )
    player_object["last_user_monster_id"] = next_id
    now = int(time.time() * 1000)
    source_monster_id = monster.get("monster", 0)
    source_definition = get_monster_definition(source_monster_id) or {}

    target_monster_id = source_monster_id

    if _is_source_epic_wubbox(source_definition):
        gold_target = _gold_epic_wubbox_start_id()
        if gold_target:
            target_monster_id = gold_target
    target_definition = get_monster_definition(target_monster_id) or {}
    clone = {
        "level": monster.get("level", 1),
        "island": SFSLong(gold_island.get("user_island_id", 0)),
        "last_feeding": SFSLong(now),
        "in_hotel": 0,
        "parent_island": SFSLong(source_island.get("user_island_id", 0)),
        "last_collection": SFSLong(now),
        "monster": target_monster_id,
        "pos_y": pos_y,
        "volume": SFSFloat(1.0),
        "pos_x": pos_x,
        "times_fed": 0,
        "happiness": 0,
        "name": monster.get("name", ""),
        "parent_monster": SFSLong(monster_id),
        "muted": 0,
        "flip": 0,
        "costume": monster.get("costume", {"eq": 0, "p": []}),
        "user_monster_id": SFSLong(next_id),
    }

    if is_box_monster_entity(target_definition):
        apply_inactive_box_state(clone, target_definition)
    gold_island.setdefault("monsters", []).append(clone)
    save_player(username, root)

    wire_monster = {
        key: value
        for key, value in clone.items()
        if key
        not in (
            "awakened",
            "box_monster",
            "inactive_box_monster",
            "is_box_monster",
            "is_inactive_box_monster",
            "numSoulLinks",
            "num_soul_links",
            "numEggsInInventory",
            "minNumEggsRequiredInUnderling",
            "book_value",
        )
    }
    return {
        "success": True,
        "user_monster_id": SFSLong(monster_id),
        "monster": wire_monster,
    }


def cancel_breeding(username, params):
    structure_id = params.get("structure_id") or params.get("user_structure_id") or 0
    root, player_object = load_player(username)
    island, record = _find_breeding_record_by_structure(player_object, structure_id)
    if island is None or record is None:
        return action_result(
            False, "user_structure_id", structure_id, with_properties=True
        )
    breeding_list = island.get("breeding") or []
    if record in breeding_list:
        breeding_list.remove(record)
    save_player(username, root)
    return {"success": True, "user_structure_id": SFSLong(structure_id)}


FUZER_BUDDY_STRUCTURE_ID = 284

_FUZING_DEFAULT_COLOR = 0.7071067690849304


def _find_fuzing_record(player_object, structure_id):
    if not structure_id:
        return None, None
    for island in player_object.get("islands") or []:
        if island is None:
            continue
        for record in island.get("fuzer") or []:
            if record is not None and record.get("structure_id") == structure_id:
                return island, record
    return None, None


def store_buddy(username, params):
    structure_id = params.get("user_structure_id") or params.get("structure_id") or 0
    root, player_object = load_player(username)
    island, structure = find_island_by_structure(player_object, structure_id)
    if structure is None:
        return {"success": False, "user_structure_id": SFSLong(structure_id)}
    definition = get_structure_definition(structure.get("structure", 0) or 0) or {}
    if definition.get("structure_type") != "buddy":
        return {"success": False, "user_structure_id": SFSLong(structure_id)}
    stored = island.setdefault("fuzer_input_buddies", [])
    stored[:] = [
        b
        for b in stored
        if b is not None and b.get("user_structure_id") != structure_id
    ]
    stored.append(
        {
            "user_structure_id": structure_id,
            "colorR": structure.get("colorR", _FUZING_DEFAULT_COLOR),
            "colorY": structure.get("colorY", _FUZING_DEFAULT_COLOR),
            "colorB": structure.get("colorB", 0.0),
            "record": dict(structure),
        }
    )
    del stored[:-2]
    structure["in_fuzer"] = 1
    save_player(username, root)
    return {"success": True, "user_structure_id": SFSLong(structure_id)}


def unstore_buddy(username, params):
    structure_id = params.get("user_structure_id") or params.get("structure_id") or 0
    root, player_object = load_player(username)
    island = find_island(player_object, get_active_island_id(player_object))
    if island is None:
        return {"success": False, "user_structure_id": SFSLong(structure_id)}, {}
    stored = island.get("fuzer_input_buddies") or []
    entry = next(
        (
            b
            for b in stored
            if b is not None and b.get("user_structure_id") == structure_id
        ),
        None,
    )
    if entry is None:
        return {"success": False, "user_structure_id": SFSLong(structure_id)}, {}
    island["fuzer_input_buddies"] = [b for b in stored if b is not entry]
    existing = find_structure(island, structure_id)
    if existing is not None:
        existing["in_fuzer"] = 0
        save_player(username, root)
        result = {
            "success": True,
            "user_structure_id": SFSLong(structure_id),
            "properties": create_player_properties(player_object),
        }
        add_actual_currencies(result, player_object)
        return result, msm_structures_update(existing)
    record = entry.get("record")
    if isinstance(record, dict):
        structure = dict(record)
        for key, value in (
            ("colorR", entry.get("colorR")),
            ("colorY", entry.get("colorY")),
            ("colorB", entry.get("colorB")),
        ):
            if value is not None:
                structure[key] = value
        already = any(
            s is not None and s.get("user_structure_id") == structure_id
            for s in island.get("structures") or []
        )
        if not already:
            island.setdefault("structures", []).append(structure)
    else:
        structure = None
    save_player(username, root)
    result = {
        "success": True,
        "user_structure_id": SFSLong(structure_id),
        "properties": create_player_properties(player_object),
    }
    add_actual_currencies(result, player_object)
    return result, (msm_structures_update(structure) if structure is not None else {})


def msm_structures_update(structure):
    import msm_structures

    return msm_structures._structure_update(structure)


def start_fuzing(username, params):
    structure_id = params.get("structure_id") or params.get("user_structure_id") or 0
    color_r = params.get("colorR", _FUZING_DEFAULT_COLOR)
    color_y = params.get("colorY", _FUZING_DEFAULT_COLOR)
    color_b = params.get("colorB", 0.0)
    create = bool(params.get("create", True))
    root, player_object = load_player(username)
    island, structure = find_island_by_structure(player_object, structure_id)
    if island is None:
        island = find_island(player_object, get_active_island_id(player_object))
        structure = find_structure(island, structure_id) if island else None
    if island is None or structure is None:
        return action_result(False, "structure_id", structure_id, with_properties=True)
    structure_sid = structure.get("user_structure_id", 0)

    if not create and not color_r and not color_y and not color_b:
        fuzer_inputs = island.get("fuzer_input_buddies") or []
        if fuzer_inputs:
            color_r = sum(b.get("colorR", 0.0) or 0.0 for b in fuzer_inputs) / len(
                fuzer_inputs
            )
            color_y = sum(b.get("colorY", 0.0) or 0.0 for b in fuzer_inputs) / len(
                fuzer_inputs
            )
            color_b = sum(b.get("colorB", 0.0) or 0.0 for b in fuzer_inputs) / len(
                fuzer_inputs
            )
    fuzer_list = island.setdefault("fuzer", [])
    for existing in fuzer_list:
        if existing is not None and existing.get("structure_id") == structure_sid:
            fuzer_list.remove(existing)
            break
    now = int(time.time() * 1000)
    build_ms = 0
    if not msm_toggles.is_enabled("instant_timers"):
        build_ms = (
            int(
                (get_structure_definition(FUZER_BUDDY_STRUCTURE_ID) or {}).get(
                    "build_time", 7200
                )
                or 7200
            )
            * 1000
        )
    finished_on = now + build_ms
    record = {
        "structure_id": SFSLong(structure_sid),
        "started_on": SFSLong(now),
        "finished_on": SFSLong(finished_on),
        "create": create,
        "colorR": color_r,
        "colorY": color_y,
        "colorB": color_b,
    }
    fuzer_list.append(record)
    save_player(username, root)
    return {
        "success": True,
        "structure_id": SFSLong(structure_sid),
        "user_fuzing": record,
        "properties": create_player_properties(player_object),
    }


def speed_up_fuzing(username, params):
    structure_id = params.get("structure_id") or params.get("user_structure_id") or 0
    root, player_object = load_player(username)
    island, record = _find_fuzing_record(player_object, structure_id)
    if record is None:
        return {
            "success": False,
            "properties": create_player_properties(player_object),
        }, {}
    now = int(time.time() * 1000)
    remaining = (record.get("finished_on", now) or now) - now
    _charge_speedup(player_object, remaining)
    finished_on = now - 1000
    record["finished_on"] = SFSLong(finished_on)
    save_player(username, root)
    result = {
        "success": True,
        "started_on": record.get("started_on"),
        "finished_on": SFSLong(finished_on),
        "structure_id": SFSLong(structure_id),
        "properties": create_player_properties(player_object),
    }
    return result, {}


def finish_fuzing(username, params, force_complete=False):
    structure_id = params.get("structure_id") or params.get("user_structure_id") or 0
    root, player_object = load_player(username)
    island, record = _find_fuzing_record(player_object, structure_id)
    if island is None or record is None:
        return action_result(False, "structure_id", structure_id, with_properties=True)
    now = int(time.time() * 1000)
    finished_on = record.get("finished_on", 0) or 0
    if not force_complete and finished_on > now:
        result = action_result(
            False, "structure_id", structure_id, with_properties=True
        )
        result["finished_on"] = SFSLong(finished_on)
        return result
    fuzer_list = island.get("fuzer") or []
    if record in fuzer_list:
        fuzer_list.remove(record)

    fuzer_inputs = island.get("fuzer_input_buddies") or []
    if fuzer_inputs and not record.get("create"):
        color_r = sum(b.get("colorR", 0.0) or 0.0 for b in fuzer_inputs) / len(
            fuzer_inputs
        )
        color_y = sum(b.get("colorY", 0.0) or 0.0 for b in fuzer_inputs) / len(
            fuzer_inputs
        )
        color_b = sum(b.get("colorB", 0.0) or 0.0 for b in fuzer_inputs) / len(
            fuzer_inputs
        )
        delete_ids = [
            {"id": SFSLong(b.get("user_structure_id", 0))} for b in fuzer_inputs
        ]
        consumed = {b.get("user_structure_id") for b in fuzer_inputs}
        island["structures"] = [
            s
            for s in island.get("structures") or []
            if s is None or s.get("user_structure_id") not in consumed
        ]
        island["fuzer_input_buddies"] = []
    else:
        color_r = params.get("colorR", record.get("colorR", _FUZING_DEFAULT_COLOR))
        color_y = params.get("colorY", record.get("colorY", _FUZING_DEFAULT_COLOR))
        color_b = params.get("colorB", record.get("colorB", 0.0))
        delete_ids = []
    fuzer_structure = find_structure(island, structure_id)
    new_structure_id = 10000 + random.randint(0, 989999)

    pos_x = params.get("pos_x", (fuzer_structure or {}).get("pos_x", 0))
    pos_y = params.get("pos_y", (fuzer_structure or {}).get("pos_y", 0))
    flip = params.get("flip", 0) or 0
    island_uid = island.get("user_island_id", 0)
    new_structure = {
        "settings": 43690,
        "colorB": color_b,
        "island": SFSLong(island_uid),
        "user_island_id": island_uid,
        "date_created": SFSLong(now),
        "colorY": color_y,
        "scale": 1.0,
        "last_collection": SFSLong(now),
        "structure": FUZER_BUDDY_STRUCTURE_ID,
        "pos_y": pos_y,
        "is_upgrading": 0,
        "user_structure_id": SFSLong(new_structure_id),
        "colorR": color_r,
        "pos_x": pos_x,
        "in_warehouse": 0,
        "is_complete": 1,
        "building_completed": SFSLong(now),
        "muted": 0,
        "flip": flip,
    }
    island.setdefault("structures", []).append(new_structure)
    save_player(username, root)
    response = {
        "success": True,
        "user_structure": new_structure,
        "structure_id": SFSLong(structure_id),
        "properties": create_player_properties(player_object),
    }
    if delete_ids:
        response["delete_ids"] = delete_ids
    return response


AMBER_ISLAND_TYPE = 22


def _find_amber_evolve_record(player_object, structure_id):
    if not structure_id:
        return None, None
    for island in player_object.get("islands") or []:
        if island is None:
            continue
        for record in island.get("amber_evolve") or []:
            if record is not None and record.get("structure_id") == structure_id:
                return island, record
    return None, None


def start_amber_evolve(username, params):
    structure_id = params.get("structure_id") or params.get("user_structure_id") or 0
    user_monster_id = params.get("user_monster_id") or params.get("monster_id") or 0
    root, player_object = load_player(username)
    island, monster = (
        find_monster_with_island(player_object, user_monster_id)
        if user_monster_id
        else (None, None)
    )
    if island is None or monster is None or island_type_of(island) != AMBER_ISLAND_TYPE:
        return {"success": False}
    structure = find_structure(island, structure_id)
    if structure is None:
        return {"success": False}
    now = int(time.time() * 1000)
    definition = get_monster_definition(monster.get("monster", 0)) or {}
    evolve_into_entity_id = definition.get("evolve_into", 0) or 0
    next_monster_id = (
        get_monster_id_for_entity_id(evolve_into_entity_id)
        if evolve_into_entity_id
        else 0
    )
    if next_monster_id <= 0 or next_monster_id == monster.get("monster", 0):
        return {
            "success": False,
            "user_monster_id": SFSLong(user_monster_id),
            "user_structure_id": SFSLong(structure_id),
        }
    build_ms = 0
    if not msm_toggles.is_enabled("instant_timers"):
        build_ms = int(definition.get("build_time", 0) or 0) * 1000
    finished_on = now + build_ms
    evolve_list = island.setdefault("amber_evolve", [])
    evolve_list[:] = [
        r
        for r in evolve_list
        if r is not None and r.get("structure_id") != structure_id
    ]
    evolve_list.append(
        {
            "structure_id": SFSLong(structure_id),
            "user_monster_id": SFSLong(user_monster_id),
            "started_on": SFSLong(now),
            "finished_on": SFSLong(finished_on),
            "from_monster": monster.get("monster", 0) or 0,
            "to_monster": next_monster_id,
        }
    )
    save_player(username, root)
    import msm_islands

    crucible = msm_islands.crucible_wire_object_for_island(island)
    result = {
        "success": True,
        "last_user_monster_id": SFSLong(user_monster_id),
        "last_heat": structure.get("crucible_heat_level", 0) or 0,
    }
    if crucible is not None:
        result["user_crucible"] = crucible
    return result


def speed_up_amber_evolve(username, params):
    structure_id = params.get("structure_id") or params.get("user_structure_id") or 0
    root, player_object = load_player(username)
    island, record = _find_amber_evolve_record(player_object, structure_id)
    if record is None:
        return {"success": False}
    now = int(time.time() * 1000)
    remaining = (record.get("finished_on", now) or now) - now
    _charge_speedup(player_object, remaining)
    record["finished_on"] = SFSLong(now - 1000)
    save_player(username, root)
    import msm_islands

    crucible = msm_islands.crucible_wire_object_for_island(island)
    result = {
        "success": True,
        "user_structure_id": SFSLong(structure_id),
    }
    if crucible is not None:
        result["user_crucible"] = crucible
    return result


def finish_amber_evolve(username, params, force_complete=False):
    structure_id = params.get("structure_id") or params.get("user_structure_id") or 0
    root, player_object = load_player(username)
    island, record = _find_amber_evolve_record(player_object, structure_id)
    import msm_islands

    def _not_ready(user_monster_id=0):
        crucible_island = island
        if crucible_island is None:
            crucible_island = (
                find_island(player_object, get_active_island_id(player_object))
                if user_monster_id
                else None
            )
        crucible = msm_islands.crucible_wire_object_for_island(crucible_island)
        payload = {
            "success": False,
            "verify": False,
            "user_structure_id": SFSLong(structure_id),
            "user_monster_id": SFSLong(user_monster_id),
            "evolve_success": False,
            "new_monst": 0,
            "mercy_flag": "",
        }
        if crucible is not None:
            payload["user_crucible"] = crucible
        return payload, {}

    if island is None or record is None:
        return _not_ready()
    now = int(time.time() * 1000)
    finished_on = record.get("finished_on", 0) or 0
    if not force_complete and finished_on > now:
        return _not_ready(record.get("user_monster_id", 0) or 0)
    user_monster_id = record.get("user_monster_id", 0) or 0
    evolve_list = island.get("amber_evolve") or []
    if record in evolve_list:
        evolve_list.remove(record)
    update = {}
    next_monster_id = 0
    species_changed = False
    _, monster = find_monster_with_island(player_object, user_monster_id)
    if monster is not None:
        definition = get_monster_definition(monster.get("monster", 0)) or {}
        next_monster_id = record.get("to_monster", 0) or 0
        if next_monster_id <= 0:
            evolve_into_entity_id = definition.get("evolve_into", 0) or 0
            next_monster_id = (
                get_monster_id_for_entity_id(evolve_into_entity_id)
                if evolve_into_entity_id
                else 0
            )
        if next_monster_id > 0 and monster.get("monster") != next_monster_id:
            previous_name = (
                definition.get("common_name") or definition.get("name") or ""
            )
            monster["monster"] = next_monster_id
            monster["monster_id"] = next_monster_id
            definition = get_monster_definition(next_monster_id) or {}
            if not monster.get("name") or monster.get("name") == previous_name:
                monster["name"] = (
                    definition.get("common_name") or definition.get("name") or ""
                )
            species_changed = True
        apply_awakened_box_state(monster, definition, AMBER_ISLAND_TYPE)
        import msm_box

        update = msm_box._box_activate_update(monster, species_changed=species_changed)
    save_player(username, root)
    import msm_islands

    evolved = monster is not None and next_monster_id > 0
    crucible = msm_islands.crucible_wire_object_for_island(
        island,
        {
            "monster": user_monster_id,
            "new_type": next_monster_id if evolved else 0,
            "e": 0,
            "started_on": 0,
            "complete_on": 0,
        },
    )
    result = {
        "success": True,
        "verify": False,
        "user_structure_id": SFSLong(structure_id),
        "user_monster_id": SFSLong(user_monster_id),
        "evolve_success": evolved,
        "new_monst": next_monster_id if evolved else 0,
        "mercy_flag": "",
    }
    if crucible is not None:
        result["user_crucible"] = crucible
    if evolved:
        update = {}
    return result, update
