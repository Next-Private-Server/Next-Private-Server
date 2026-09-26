import logging
import json
import random
import time

logger = logging.getLogger("msm.islands")
import msm_toggles
import msm_composer
from msm_gamedata import (
    get_island_definition,
    get_max_structure_id,
    get_monster_definition,
    get_monster_id_for_entity_id,
    get_structure_definition,
    get_user_game_setting_int,
    island_for_theme,
    is_egg_holder_structure,
    load_db_json,
    resolve_island_type,
)
from msm_playerdata import (
    SFSLong,
    add_actual_currencies,
    create_player_properties,
    find_island,
    get_active_island_id,
    island_type_of,
    load_player,
    save_player,
)

PAIRONORMAL_ISLAND_TYPE = 31
PAIRONORMAL_DEFAULT_STRUCTURES = [
    (1069, 31, 16, 0),
    (1064, 32, 29, 0),
    (1062, 17, 3, 0),
    (1051, 12, 27, 0),
]


def _make_structure(
    user_island_id, island_type, structure_id, pos_x, pos_y, flip, level, now
):
    return {
        "user_structure_id": 10000 + random.randint(0, 989999),
        "user_island_id": user_island_id,
        "island": user_island_id,
        "island_type": island_type,
        "book_value": 100,
        "pos_x": pos_x,
        "pos_y": pos_y,
        "col": pos_x,
        "row": pos_y,
        "flip": flip,
        "flipped": flip,
        "muted": 0,
        "in_warehouse": 0,
        "is_upgrading": 0,
        "is_complete": 1,
        "structure": structure_id,
        "structure_id": structure_id,
        "scale": 1.0,
        "level": level,
        "building_completed": now,
        "date_created": now,
        "last_collection": now,
        "obj_data": 0,
        "obj_end": 0,
    }


AMBER_ISLAND_TYPE = 22
CRUCIBLE_STRUCTURE_ID = 711
CRUCIBLE_POSITION = (21, 3)


def _make_crucible_structure(user_island_id, structure_id, pos_x, pos_y, now):
    return {
        "island": user_island_id,
        "date_created": now,
        "scale": 1.0,
        "last_collection": now,
        "structure": structure_id,
        "pos_y": pos_y,
        "is_upgrading": 0,
        "user_structure_id": 10000 + random.randint(0, 989999),
        "pos_x": pos_x,
        "in_warehouse": 0,
        "is_complete": 1,
        "building_completed": now,
        "muted": 0,
        "flip": 0,
    }


def _is_crucible_structure(structure):
    definition = (
        get_structure_definition(
            structure.get("structure", structure.get("structure_id", 0))
        )
        or {}
    )
    return (definition.get("structure_type") or "").lower() == "crucible"


def repair_crucible_structure(island):
    if island_type_of(island) != AMBER_ISLAND_TYPE:
        return
    structures = island.setdefault("structures", [])
    for s in structures:
        if s is not None and _is_crucible_structure(s):
            return
    now = int(time.time() * 1000)
    structures.append(
        _make_crucible_structure(
            island.get("user_island_id", 0) or 0,
            CRUCIBLE_STRUCTURE_ID,
            CRUCIBLE_POSITION[0],
            CRUCIBLE_POSITION[1],
            now,
        )
    )


def _find_amber_evolve_record_on_island(island, structure_id):
    for r in island.get("amber_evolve") or []:
        if r is not None and r.get("structure_id") == structure_id:
            return r
    return None


_CRUCIBLE_FUEL_RELIC_COSTS_CACHE = None


def crucible_fuel_relic_costs():
    global _CRUCIBLE_FUEL_RELIC_COSTS_CACHE
    if _CRUCIBLE_FUEL_RELIC_COSTS_CACHE is None:
        costs = []
        data = load_db_json("game_settings") or {}
        for entry in data.get("user_game_settings") or []:
            if entry.get("key") == "USER_CRUCIBLE_FUEL_RELIC_COSTS_V3":
                try:
                    costs = json.loads(entry.get("value") or "[]")
                except (ValueError, TypeError):
                    costs = []
                break
        _CRUCIBLE_FUEL_RELIC_COSTS_CACHE = costs or [2, 4, 6, 12]
    return _CRUCIBLE_FUEL_RELIC_COSTS_CACHE


def _crucible_wire_object(island, structure, overrides=None):
    record = _find_amber_evolve_record_on_island(
        island, structure.get("user_structure_id", 0)
    )
    monster_uid = record.get("user_monster_id", 0) or 0 if record else 0
    new_type = 0
    if record is not None:
        for m in island.get("monsters") or []:
            if m is not None and m.get("user_monster_id") == monster_uid:
                definition = get_monster_definition(m.get("monster", 0)) or {}
                evolve_into_entity_id = definition.get("evolve_into", 0) or 0
                if evolve_into_entity_id:
                    new_type = get_monster_id_for_entity_id(evolve_into_entity_id)
                break
    wire = {
        "struct": SFSLong(structure.get("user_structure_id", 0)),
        "monster": SFSLong(monster_uid),
        "new_type": new_type,
        "started_on": SFSLong(record.get("started_on", 0) or 0 if record else 0),
        "complete_on": SFSLong(record.get("finished_on", 0) or 0 if record else 0),
        "e": 1 if record is not None else 0,
        "h": structure.get("crucible_heat_level", 0) or 0,
        "u": structure.get("crucible_unlock_stage", 0) or 0,
    }
    for key, value in (overrides or {}).items():
        if key in ("monster", "started_on", "complete_on"):
            wire[key] = SFSLong(value or 0)
        else:
            wire[key] = value
    return wire


def find_crucible_structure(island):
    if island is None:
        return None
    for s in island.get("structures") or []:
        if s is not None and _is_crucible_structure(s):
            return s
    return None


def crucible_wire_object_for_island(island, overrides=None):
    structure = find_crucible_structure(island)
    if structure is None:
        return None
    return _crucible_wire_object(island, structure, overrides)


def _find_crucible_structure_and_island(player_object, structure_id):
    if structure_id:
        for isl in player_object.get("islands") or []:
            if isl is None:
                continue
            for s in isl.get("structures") or []:
                if s is not None and s.get("user_structure_id") == structure_id:
                    return isl, s
    island = find_island(player_object, get_active_island_id(player_object))
    structure = find_crucible_structure(island)
    if structure is not None:
        return island, structure
    return None, None


def viewed_crucible_unlock(username, params):
    structure_id = params.get("structure_id") or params.get("user_structure_id") or 0
    requested_stage = params.get("unlock_stage", 0) or 0
    root, player_object = load_player(username)
    island, structure = _find_crucible_structure_and_island(player_object, structure_id)
    if structure is None:
        return {"success": False}

    structure["crucible_unlock_stage"] = requested_stage
    save_player(username, root)
    return {
        "success": True,
        "user_crucible": {
            "struct": SFSLong(structure.get("user_structure_id", 0)),
            "u": requested_stage,
        },
    }


def viewed_crucible_monster(username, params):
    return {"success": True, "message": ""}


def collect_crucible_heat(username, params):
    structure_id = params.get("structure_id") or params.get("user_structure_id") or 0
    buy_flags = params.get("buy_flags", 0) or 0
    root, player_object = load_player(username)
    island, structure = _find_crucible_structure_and_island(player_object, structure_id)
    if structure is None:
        return {"success": False}, {}
    costs = crucible_fuel_relic_costs()
    current_heat = structure.get("crucible_heat_level", 0) or 0
    max_heat = len(costs) * 25
    relics_spent = 0
    if current_heat < max_heat:
        next_level = current_heat // 25 + 1
        cost_index = min(next_level - 1, len(costs) - 1)
        cost = costs[cost_index] if costs else 0
        available_relics = player_object.get("relics", 0) or 0
        if available_relics >= cost:
            relics_spent = cost
            player_object["relics"] = available_relics - cost
            player_object["relics_actual"] = player_object["relics"]
            structure["crucible_heat_level"] = min(100, current_heat + 25)
    save_player(username, root)
    record = _find_amber_evolve_record_on_island(
        island, structure.get("user_structure_id", 0)
    )
    user_monster_id = record.get("user_monster_id", 0) or 0 if record else 0
    result = {
        "success": True,
        "user_crucible": _crucible_wire_object(island, structure),
        "collected_relics": relics_spent,
        "user_monster_id": SFSLong(user_monster_id),
        "new_monst": 0,
        "mercy_flag": "",
    }
    add_actual_currencies(result, player_object)
    return result, {}


ETHEREAL_ISLAND_TYPES = (26, 27, 28, 29)
CRYSTAL_ETHEREAL_ISLAND_TYPE = 26
ETHEREAL_ISLAND_TYPES_WITH_EGGCUPS = ETHEREAL_ISLAND_TYPES
ETHEREAL_EGGCUP_STRUCTURE_ID = 1028
ETHEREAL_FREE_QUAD_BY_ISLET = {26: 708, 27: 758, 28: 778, 29: 798}
ETHEREAL_DISH_HARMONIZER_STRUCTURE_ID = 1027
ETHEREAL_HARMONIZER_STRUCTURE_IDS = (1027, 1049)
ETHEREAL_POSITION_REPAIR_VERSION = 3
ETHEREAL_EGGCUP_REPAIR_VERSION = 3

ETHEREAL_HARMONIZER_POSITIONS = {
    26: (5, 22),
    27: (10, 12),
    28: (8, 14),
    29: (31, 15),
}
ETHEREAL_EGGCUP_POSITIONS_BY_TYPE = {
    26: [(4, 22), (4, 24)],
    27: [(8, 12), (8, 10)],
    28: [(6, 12), (5, 12)],
    29: [(35, 17), (35, 19)],
}


def default_island_structures(user_island_id, island_type):
    now = int(time.time() * 1000)
    if island_type == PAIRONORMAL_ISLAND_TYPE:
        return [
            _make_structure(
                user_island_id,
                island_type,
                sid,
                x,
                y,
                flip,
                (get_structure_definition(sid) or {}).get("level", 1) or 1,
                now,
            )
            for sid, x, y, flip in PAIRONORMAL_DEFAULT_STRUCTURES
        ]
    if island_type in ETHEREAL_ISLAND_TYPES:
        harmonizer_pos = ETHEREAL_HARMONIZER_POSITIONS[island_type]
        entries = [
            (
                ETHEREAL_DISH_HARMONIZER_STRUCTURE_ID,
                harmonizer_pos[0],
                harmonizer_pos[1],
                0,
            )
        ]
        if island_type in ETHEREAL_ISLAND_TYPES_WITH_EGGCUPS:
            entries.extend(
                (ETHEREAL_EGGCUP_STRUCTURE_ID, x, y, 0)
                for x, y in ETHEREAL_EGGCUP_POSITIONS_BY_TYPE[island_type]
            )
        return [
            _make_structure(
                user_island_id,
                island_type,
                sid,
                x,
                y,
                flip,
                (get_structure_definition(sid) or {}).get("level", 1) or 1,
                now,
            )
            for sid, x, y, flip in entries
        ]
    structures = []
    special_positions = {
        1: {"castle": (29, 9), "nursery": (11, 10), "breeding": (17, 37)},
        2: {"castle": (29, 9), "nursery": (24, 28), "breeding": (21, 3)},
        9: {"castle": (24, 14)},
        20: {"nursery": (29, 9)},
        25: {"nursery": (33, 22)},
    }
    overrides = special_positions.get(island_type, {})
    placements = [
        ("castle", overrides.get("castle", (29, 9))),
        ("nursery", overrides.get("nursery", (35, 17))),
        ("breeding", overrides.get("breeding", (21, 3))),
    ]
    for structure_type, (pos_x, pos_y) in placements:
        structure_id = get_max_structure_id(island_type, structure_type)
        if not structure_id:
            continue
        definition = get_structure_definition(structure_id) or {}
        level = definition.get("level", 1) or 1
        if level <= 0:
            level = 1
        structures.append(
            _make_structure(
                user_island_id, island_type, structure_id, pos_x, pos_y, 0, level, now
            )
        )
    if island_type == AMBER_ISLAND_TYPE:
        structures.append(
            _make_crucible_structure(
                user_island_id,
                CRUCIBLE_STRUCTURE_ID,
                CRUCIBLE_POSITION[0],
                CRUCIBLE_POSITION[1],
                now,
            )
        )
    return structures


NPS_TEST_STRUCTURE_ID = 9000


def backfill_nps_test_structure(island):

    structures = island.setdefault("structures", [])
    for i in range(len(structures) - 1, -1, -1):
        if (
            structures[i] is not None
            and structures[i].get("structure") == NPS_TEST_STRUCTURE_ID
        ):
            del structures[i]


NPS_STRUCTURE_BUTTON_CATALOG = {
    NPS_TEST_STRUCTURE_ID: ("CRIE", "NPS_STRUCTURE_CLICK"),
}
NPS_STRUCTURE_BUTTON_CONFIG_PATHS = (
    "/sdcard/Download/nps_structure_buttons.properties",
    "/storage/emulated/0/Download/nps_structure_buttons.properties",
)


def write_nps_structure_button_config(player_object):

    lines = []
    for island in player_object.get("islands") or []:
        if not island:
            continue
        for structure in island.get("structures") or []:
            if not structure:
                continue
            catalog_id = structure.get("structure")
            entry = NPS_STRUCTURE_BUTTON_CATALOG.get(catalog_id)
            if not entry:
                continue
            user_structure_id = structure.get("user_structure_id")
            if not user_structure_id:
                continue
            label, command = entry
            lines.append(f"{user_structure_id}={label}|{command}")
    content = "\n".join(lines) + ("\n" if lines else "")
    for path in NPS_STRUCTURE_BUTTON_CONFIG_PATHS:
        try:
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(content)
        except OSError:
            continue


def backfill_island_type(island):
    explicit_type = island.get("type")
    island_type = island.get("island_type")
    if island_type and island_type >= 100 and explicit_type and 0 < explicit_type < 100:
        island["island_type"] = explicit_type
        return
    if island_type and island_type >= 100:
        resolved = resolve_island_type(island_type)
        if 0 < resolved < 100 and resolved != island_type:
            island["type"] = resolved
            island["island_type"] = resolved
            return
    user_island_id = island.get("user_island_id", 0) or 0
    if user_island_id < 1000 or user_island_id >= 100000000:
        return
    catalog_id = island.get("mirror_of_island_id") or (user_island_id - 1000)
    resolved = resolve_island_type(catalog_id)
    island.pop("mirror_of_island_id", None)
    island.pop("island_id", None)

    island["island"] = resolved
    island["type"] = resolved
    island["island_type"] = resolved


def repair_mirror_island_type(player_object):
    if player_object.get("mirror_island_type_repaired"):
        return
    for island in player_object.get("islands") or []:
        if island is None:
            continue
        user_island_id = island.get("user_island_id", 0) or 0
        if user_island_id < 100000000:
            continue
        island_field = island.get("island")
        if island_field is None:
            continue
        if (
            island.get("type") != island_field
            or island.get("island_type") != island_field
        ):
            island["type"] = island_field
            island["island_type"] = island_field
    player_object["mirror_island_type_repaired"] = True


def repair_island_owner(player_object):
    if player_object.get("island_owner_repaired"):
        return
    islands = player_object.get("islands") or []
    counts = {}
    for island in islands:
        if island is None:
            continue
        user_value = island.get("user")
        if not user_value:
            continue
        counts[user_value] = counts.get(user_value, 0) + 1
    if not counts:
        player_object["island_owner_repaired"] = True
        return
    correct_user = max(counts.items(), key=lambda kv: kv[1])[0]
    for island in islands:
        if island is not None and island.get("user") != correct_user:
            island["user"] = correct_user
    player_object["island_owner_repaired"] = True


def repair_ethereal_structure_positions(island):
    island_type = (
        island.get("island_type", island.get("type", island.get("island", 0))) or 0
    )
    if island_type not in ETHEREAL_ISLAND_TYPES:
        return
    if (
        int(island.get("ethereal_positions_repair_version", 0) or 0)
        >= ETHEREAL_POSITION_REPAIR_VERSION
    ):
        return
    structures = island.get("structures") or []
    harmonizer_position = ETHEREAL_HARMONIZER_POSITIONS[island_type]
    eggcup_positions = list(ETHEREAL_EGGCUP_POSITIONS_BY_TYPE[island_type])
    for structure in structures:
        if structure is None:
            continue
        if not structure.get("structure_id"):
            structure["structure_id"] = structure.get("structure")
        pos_x = structure.get("pos_x", 0) or 0
        pos_y = structure.get("pos_y", 0) or 0
        if structure.get("structure") in ETHEREAL_HARMONIZER_STRUCTURE_IDS:
            new_x, new_y = harmonizer_position
        elif structure.get("structure") == ETHEREAL_EGGCUP_STRUCTURE_ID:
            if (pos_x, pos_y) in eggcup_positions:
                eggcup_positions.remove((pos_x, pos_y))
                continue
            if not eggcup_positions:
                continue
            new_x, new_y = eggcup_positions.pop(0)
        else:
            continue
        structure["pos_x"] = new_x
        structure["pos_y"] = new_y
        structure["col"] = new_x
        structure["row"] = new_y
    island["ethereal_positions_repaired"] = True
    island["ethereal_positions_repair_version"] = ETHEREAL_POSITION_REPAIR_VERSION


_STALE_PLAYER_GENE_KEYS = (
    "attuner_genes",
    "attunerGenes",
    "attuner_gene_inventory",
    "attunerGenesData",
    "meebs",
)


def repair_ethereal_workshop_state(player_object, island):
    for key in _STALE_PLAYER_GENE_KEYS:
        player_object.pop(key, None)
    if island is None:
        return
    critters = island.get("attuned_critters")
    if not critters:
        return
    cleaned = []
    for entry in critters:
        if not isinstance(entry, dict):
            continue
        gene = entry.get("gene")
        if not gene:
            continue
        best = max(
            entry.get("num", 0) or 0,
            entry.get("count", 0) or 0,
            entry.get("amount", 0) or 0,
        )
        cleaned.append({"gene": gene, "num": best})
    island["attuned_critters"] = cleaned


def repair_dish_harmonizer_state(island):
    if island is None:
        return
    island_type = (
        island.get("island_type", island.get("type", island.get("island", 0))) or 0
    )
    if island_type not in ETHEREAL_ISLAND_TYPES:
        return
    for structure in island.get("structures") or []:
        if (
            not isinstance(structure, dict)
            or structure.get("structure") not in ETHEREAL_HARMONIZER_STRUCTURE_IDS
        ):
            continue
        targets = structure.get("dish_harmonizer_targets") or []
        claimed = set(structure.get("dish_harmonizer_claimed") or [])
        if targets and not structure.get("dish_harmonizer_complete_on"):
            structure["dish_harmonizer_complete_on"] = (
                structure.get("building_completed", 0) or 0
            )
        for key in ("obj_data", "obj_end", "finishing_time", "is_upgrading"):
            if structure.get(key):
                structure[key] = 0
        if bool(targets) and len(claimed) >= len(targets):
            structure.pop("dish_harmonizer_targets", None)
            structure.pop("dish_harmonizer_claimed", None)
            structure.pop("dish_harmonizer_started_on", None)
            structure.pop("dish_harmonizer_complete_on", None)


def backfill_ethereal_eggcups(island):
    island_type = (
        island.get("island_type", island.get("type", island.get("island", 0))) or 0
    )
    if island_type not in ETHEREAL_ISLAND_TYPES_WITH_EGGCUPS:
        return
    structures = island.setdefault("structures", [])
    if any(s is not None and s.get("structure") == 804 for s in structures):
        island["structures"] = [
            s for s in structures if s is None or s.get("structure") != 804
        ]
        structures = island["structures"]
    if (
        int(island.get("eggcup_repair_version", 0) or 0)
        >= ETHEREAL_EGGCUP_REPAIR_VERSION
    ):
        return
    eggcup_positions = ETHEREAL_EGGCUP_POSITIONS_BY_TYPE[island_type]
    occupied = {(s.get("pos_x"), s.get("pos_y")) for s in structures if s is not None}
    eggcup_count = sum(
        1
        for s in structures
        if s is not None and s.get("structure") == ETHEREAL_EGGCUP_STRUCTURE_ID
    )
    if eggcup_count < len(eggcup_positions):
        now = int(time.time() * 1000)
        user_island_id = island.get("user_island_id", 0) or 0
        definition = get_structure_definition(ETHEREAL_EGGCUP_STRUCTURE_ID) or {}
        level = definition.get("level", 1) or 1
        for x, y in eggcup_positions:
            if eggcup_count >= len(eggcup_positions):
                break
            if (x, y) in occupied:
                continue
            structures.append(
                _make_structure(
                    user_island_id,
                    island_type,
                    ETHEREAL_EGGCUP_STRUCTURE_ID,
                    x,
                    y,
                    0,
                    level,
                    now,
                )
            )
            occupied.add((x, y))
            eggcup_count += 1
    island["eggcup_repaired_v2"] = True
    island["eggcup_repaired"] = True
    island["eggcup_repair_version"] = ETHEREAL_EGGCUP_REPAIR_VERSION


_ISLAND_MERGE_LIST_KEYS = (
    "monsters",
    "structures",
    "eggs",
    "breeding",
    "baking",
    "torches",
    "fuzer",
    "fuzer_input_buddies",
    "amber_evolve",
    "costumes_owned",
    "tiles",
    "book_monster_ids",
    "boxed_eggs",
)


def repair_preset_mirror_island_collisions(player_object):
    if player_object.get("preset_mirror_islands_removed"):
        return
    islands = player_object.get("islands") or []
    groups = {}
    for island in islands:
        if island is None:
            continue
        uid = island.get("user_island_id", 0) or 0
        if uid <= 0 or uid >= 100000000:
            continue
        island_type = island.get(
            "island_type", island.get("type", island.get("island"))
        )
        if island_type is None:
            continue
        groups.setdefault(island_type, []).append(island)

    to_remove = []
    for island_type, group in groups.items():
        if len(group) < 2:
            continue
        for island in group:
            if "user" not in island and "user_id" not in island:
                to_remove.append(island)

    for island in to_remove:
        if island in islands:
            islands.remove(island)
    if to_remove:
        player_object["islands"] = islands
    player_object["preset_mirror_islands_removed"] = True


def repair_duplicate_island_types(player_object):
    if player_object.get("duplicate_island_types_repaired"):
        return
    islands = player_object.get("islands") or []
    groups = {}
    for island in islands:
        if island is None:
            continue
        uid = island.get("user_island_id", 0) or 0
        if uid <= 0 or uid >= 100000000:
            continue
        groups.setdefault(uid, []).append(island)
    for uid, group in groups.items():
        if len(group) < 2:
            continue

        primary = max(group, key=lambda isl: len(isl.keys()))
        for other in group:
            if other is primary:
                continue
            for key in _ISLAND_MERGE_LIST_KEYS:
                other_list = other.get(key)
                if not other_list:
                    continue
                primary.setdefault(key, []).extend(other_list)
            other_monsters = other.get("num_monsters", 0) or 0
            if other_monsters:
                primary["num_monsters"] = (
                    primary.get("num_monsters", 0) or 0
                ) + other_monsters
            islands.remove(other)
    player_object["islands"] = islands
    player_object["duplicate_island_types_repaired"] = True


def _is_tile_structure(structure):
    if not isinstance(structure, dict):
        return False
    from msm_gamedata import get_structure_definition

    definition = get_structure_definition(structure.get("structure", 0)) or {}
    return "tile" in str(definition.get("keywords") or "")


def repair_island_tiles(player_object):
    changed = False
    for island in (player_object or {}).get("islands") or []:
        if not isinstance(island, dict):
            continue
        legacy = island.pop("paint_state", None)
        if isinstance(legacy, dict) and legacy:
            tiles = island.get("tiles")
            if not isinstance(tiles, dict):
                tiles = {}
                island["tiles"] = tiles
            for key, value in legacy.items():
                tiles.setdefault(str(key), value)
            changed = True
        structures = island.get("structures")
        if isinstance(structures, list):
            kept = [s for s in structures if not _is_tile_structure(s)]
            if len(kept) != len(structures):
                island["structures"] = kept
                changed = True
    return changed


def repair_parked_fuzer_buddies(player_object):
    restored = 0
    for island in player_object.get("islands") or []:
        if island is None:
            continue
        parked = island.get("fuzer_input_buddies") or []
        if not parked:
            continue
        structures = island.setdefault("structures", [])
        present = {s.get("user_structure_id") for s in structures if s is not None}
        for entry in parked:
            if not isinstance(entry, dict):
                continue
            structure_id = entry.get("user_structure_id")
            if not structure_id or structure_id in present:
                continue
            record = entry.get("record")
            if not isinstance(record, dict):
                continue
            structure = dict(record)
            for key in ("colorR", "colorY", "colorB"):
                if entry.get(key) is not None:
                    structure[key] = entry[key]
            structure["in_fuzer"] = 1
            structures.append(structure)
            present.add(structure_id)
            restored += 1
    return restored


def repair_duplicate_structure_ids(player_object):
    existing_ids = set()
    for island in player_object.get("islands") or []:
        if island is None:
            continue
        for structure in island.get("structures") or []:
            if structure is not None:
                existing_ids.add(structure.get("user_structure_id"))

    def new_id():
        while True:
            candidate = 10000 + random.randint(0, 989999)
            if candidate not in existing_ids:
                existing_ids.add(candidate)
                return candidate

    seen = set()
    for island in player_object.get("islands") or []:
        if island is None:
            continue
        for structure in island.get("structures") or []:
            if structure is None:
                continue
            sid = structure.get("user_structure_id")
            if sid in seen:
                new_sid = new_id()
                structure["user_structure_id"] = new_sid
                for egg in island.get("eggs") or []:
                    if egg is not None and egg.get("structure") == sid:
                        egg["structure"] = new_sid
                for breeding in island.get("breeding") or []:
                    if breeding is not None and breeding.get("structure") == sid:
                        breeding["structure"] = new_sid
            else:
                seen.add(sid)


def repair_broken_clubbox_eggs(player_object):
    for island in player_object.get("islands") or []:
        if island is None:
            continue
        eggs = island.get("eggs")
        if not eggs:
            continue
        kept = []
        freed_structure_ids = set()
        for egg in eggs:
            if egg is None:
                continue
            monster_id = egg.get("monster_id") or egg.get("monster")
            if not monster_id or get_monster_definition(monster_id) is not None:
                kept.append(egg)
                continue
            real_id = get_monster_id_for_entity_id(monster_id)
            if real_id and get_monster_definition(real_id) is not None:
                egg["monster"] = real_id
                egg["monster_id"] = real_id
                kept.append(egg)
                continue
            freed_structure_ids.add(egg.get("structure"))
        if len(kept) != len(eggs):
            island["eggs"] = kept
            for structure in island.get("structures") or []:
                if (
                    structure is not None
                    and structure.get("user_structure_id") in freed_structure_ids
                ):
                    structure["occupied"] = False
                    structure["has_egg"] = False
                    structure["viewed"] = True
                    structure["obj_data"] = 0


def repair_structure_build_timestamps(island):
    if island is None:
        return
    now = int(time.time() * 1000)
    island_type = island_type_of(island) or 0
    for structure in island.get("structures") or []:
        if structure is None:
            continue
        if not structure.get("date_created"):
            structure["date_created"] = SFSLong(now)
        structure_def = structure.get("structure")
        if (
            isinstance(structure_def, int)
            and structure_def > 0
            and structure.get("structure_id") != structure_def
        ):
            structure["structure_id"] = structure_def
        definition = get_structure_definition(structure_def) or {}
        if definition.get("structure_type") == "obstacle":
            if (structure.get("building_completed") or 0) <= (
                structure.get("date_created") or 0
            ):
                for key in (
                    "date_created",
                    "building_completed",
                    "obj_data",
                    "obj_end",
                    "finishing_time",
                ):
                    structure.pop(key, None)
            continue
        if structure.get("island_type") is None:
            structure["island_type"] = island_type
        if structure.get("is_upgrading"):
            continue
        if not structure.get("is_complete"):
            continue
        if not structure.get("building_completed"):
            structure["building_completed"] = SFSLong(
                structure.get("date_created") or now
            )


def repair_structure_definition_aliases(player_object):
    changed = False
    for island in player_object.get("islands") or []:
        if island is None:
            continue
        for structure in island.get("structures") or []:
            if not isinstance(structure, dict):
                continue
            structure_def = structure.get("structure")
            alias = structure.get("structure_id")
            if (
                isinstance(structure_def, int)
                and structure_def > 0
                and alias != structure_def
            ):
                structure["structure_id"] = structure_def
                changed = True
    if changed:
        player_object["structure_aliases_repaired_v1"] = True
    return changed


def repair_low_id_structures(player_object):
    if player_object.get("low_id_structures_repaired"):
        return
    islands = player_object.get("islands") or []
    existing_ids = {
        s.get("user_structure_id")
        for isl in islands
        if isl is not None
        for s in (isl.get("structures") or [])
        if s is not None
    }
    for island in islands:
        if island is None:
            continue
        if island_type_of(island) == 25:
            continue
        uid = island.get("user_island_id", 0) or 0
        for structure in island.get("structures") or []:
            if structure is None:
                continue
            old_id = structure.get("user_structure_id")
            if not isinstance(old_id, int) or old_id >= 1000:
                continue
            new_id = uid * 1000 + old_id
            while new_id in existing_ids:
                new_id += 1
            existing_ids.add(new_id)
            structure["user_structure_id"] = new_id
            for egg in island.get("eggs") or []:
                if egg is not None and egg.get("structure") == old_id:
                    egg["structure"] = new_id
            for breeding in island.get("breeding") or []:
                if breeding is not None and breeding.get("structure") == old_id:
                    breeding["structure"] = new_id
    player_object["low_id_structures_repaired"] = True


def _is_direct_placement_egg(egg):
    return isinstance(egg, dict) and egg.get("source") == "direct_placement"


def _is_legacy_direct_placement_egg(egg):
    if not isinstance(egg, dict):
        return False
    return "source" not in egg and "book_value" in egg


def purge_direct_placement_eggs(player_object):
    from msm_box import requires_direct_placement

    purge_legacy = not player_object.get("direct_placement_eggs_purged")
    for island in player_object.get("islands") or []:
        if island is None:
            continue
        island_type = island_type_of(island) or 1
        eggs = island.get("eggs") or []
        kept = []
        for egg in eggs:
            phantom = _is_direct_placement_egg(egg) or (
                purge_legacy and _is_legacy_direct_placement_egg(egg)
            )
            if phantom and not requires_direct_placement(
                get_monster_definition((egg or {}).get("monster", 0)), island_type
            ):
                continue
            kept.append(egg)
        if len(kept) != len(eggs):
            island["eggs"] = kept
    player_object["direct_placement_eggs_purged"] = True


def repair_orphaned_process_refs(player_object):
    changed = False
    now = int(time.time() * 1000)
    purge_direct_placement_eggs(player_object)
    for island in player_object.get("islands") or []:
        if island is None:
            continue
        structures = [s for s in island.get("structures") or [] if s is not None]
        structures_by_uid = {s.get("user_structure_id"): s for s in structures}

        def structure_type(structure):
            definition = (
                get_structure_definition(
                    structure.get("structure", structure.get("structure_id", 0)) or 0
                )
                or {}
            )
            return definition.get("structure_type") or ""

        def first_structure(match_type, used_ids=()):
            used_ids = set(used_ids or ())
            for structure in structures:
                sid = structure.get("user_structure_id", 0)
                if sid in used_ids:
                    continue
                if structure_type(structure) == match_type:
                    return structure
            return None

        def first_egg_holder(used_ids=()):
            used_ids = set(used_ids or ())
            for structure in structures:
                sid = structure.get("user_structure_id", 0)
                if sid in used_ids:
                    continue
                if is_egg_holder_structure(
                    structure.get("structure", structure.get("structure_id", 0)) or 0
                ) and structure_type(structure) not in (
                    "synthesizer",
                    "dish_harmonizer",
                ):
                    return structure
            return None

        eggs = [egg for egg in island.get("eggs") or [] if egg is not None]
        repaired_eggs = []
        used_egg_holders = set()
        for egg in eggs:
            holder_id = egg.get("structure", 0) or 0
            holder = structures_by_uid.get(holder_id)
            if holder is None or not is_egg_holder_structure(
                holder.get("structure", holder.get("structure_id", 0)) or 0
            ):
                holder = first_egg_holder(used_egg_holders)
                if holder is None:
                    changed = True
                    continue
                new_holder_id = holder.get("user_structure_id", 0) or 0
                egg["structure"] = SFSLong(new_holder_id)
                holder_id = new_holder_id
                changed = True
            used_egg_holders.add(holder_id)
            if structure_type(holder) != "synthesizer":
                holder["occupied"] = True
                holder["has_egg"] = True
                holder.setdefault("viewed", bool(egg.get("viewed", False)))
                holder["obj_data"] = 1
                holder["obj_end"] = egg.get(
                    "hatches_on", holder.get("obj_end", now) or now
                )
                holder["finishing_time"] = egg.get(
                    "hatches_on",
                    holder.get("finishing_time", holder["obj_end"])
                    or holder["obj_end"],
                )
            repaired_eggs.append(egg)
        if len(repaired_eggs) != len(island.get("eggs") or []):
            island["eggs"] = repaired_eggs
            changed = True
        valid_egg_holder_ids = {egg.get("structure", 0) for egg in repaired_eggs}
        for structure in structures:
            sid = structure.get("user_structure_id", 0) or 0
            if structure_type(structure) == "synthesizer":
                for key in (
                    "occupied",
                    "has_egg",
                    "viewed",
                    "obj_data",
                    "obj_end",
                    "finishing_time",
                ):
                    if structure.pop(key, None) is not None:
                        changed = True
                continue
            if structure_type(structure) == "dish_harmonizer":
                continue
            if (
                is_egg_holder_structure(
                    structure.get("structure", structure.get("structure_id", 0)) or 0
                )
                and sid not in valid_egg_holder_ids
            ):
                if structure.get("occupied") or structure.get("has_egg"):
                    changed = True
                structure["occupied"] = False
                structure["has_egg"] = False
                structure["viewed"] = False
                structure["obj_data"] = 0
                structure["obj_end"] = 0
                structure["finishing_time"] = 0
        breeding = [
            record for record in island.get("breeding") or [] if record is not None
        ]
        repaired_breeding = []
        used_breeding_structures = set()
        for record in breeding:
            structure_id = record.get("structure", 0) or 0
            structure = structures_by_uid.get(structure_id)
            if structure is None or structure_type(structure) != "breeding":
                structure = first_structure("breeding", used_breeding_structures)
                if structure is None:
                    changed = True
                    continue
                new_structure_id = structure.get("user_structure_id", 0) or 0
                record["structure"] = SFSLong(new_structure_id)
                structure_id = new_structure_id
                changed = True
            used_breeding_structures.add(structure_id)
            repaired_breeding.append(record)
        if len(repaired_breeding) != len(island.get("breeding") or []):
            island["breeding"] = repaired_breeding
            changed = True
    if changed:
        player_object["process_refs_repaired_v1"] = True
    return changed


def migrate_legacy_mirror_ids(player_object):

    islands = player_object.get("islands") or []
    for island in islands:
        if island is None:
            continue
        old_uid = island.get("user_island_id", 0) or 0
        if not (1100 <= old_uid < 2000):
            continue
        island.pop("mirror_of_island_id", None)
        island.pop("island_id", None)


def buy_island(username, params):
    island_id = params.get("island_id", 0)
    island_type = resolve_island_type(island_id)
    root, player_object = load_player(username)
    existing_ids = {
        isl.get("user_island_id")
        for isl in player_object.get("islands") or []
        if isl is not None
    }
    if island_id == island_type:
        user_island_id = 1000 + island_id
        if user_island_id in existing_ids:
            return {
                "success": False,
                "cmd": "gs_buy_island",
                "message": "Island already bought!",
            }
    else:
        for isl in player_object.get("islands") or []:
            if isl is not None and isl.get("island") == island_id:
                return {
                    "success": False,
                    "cmd": "gs_buy_island",
                    "message": "Island already bought!",
                }
        user_island_id = random.randint(100000000, 999999999)
        while user_island_id in existing_ids:
            user_island_id = random.randint(100000000, 999999999)

    existing_user = 100000000
    for isl in player_object.get("islands") or []:
        if isl is not None and isl.get("user"):
            existing_user = isl.get("user")
            break
    new_island = {
        "eggs": [],
        "warp_speed": 1.0,
        "island": island_id,
        "structures": default_island_structures(user_island_id, island_type),
        "monsters": [],
        "dislikes": 0,
        "likes": 0,
        "fuzer": [],
        "baking": [],
        "costumes_owned": [],
        "breeding": [],
        "torches": [],
        "last_player_level": 75,
        "num_torches": 0,
        "user_island_id": SFSLong(user_island_id),
        "user": SFSLong(existing_user),
        "type": island_id,
        "island_type": island_id,
    }
    if island_type == 9:
        new_island["tribal_requests"] = []
        new_island["tribal_quests"] = []
        new_island["tribal_island_data"] = {
            "chief_name": "@msm_hacks",
            "name": "@msm_hacks",
            "user_island_id": SFSLong(user_island_id),
            "chief": SFSLong(existing_user),
            "members": 1,
            "monsters": 999,
            "rank": 999999,
        }

    if msm_toggles.is_enabled("functioning_currencies"):
        island_definition = get_island_definition(island_id) or {}
        cost_diamonds = island_definition.get("cost_diamonds", 0) or 0
        cost_coins = island_definition.get("cost_coins", 0) or 0
        if cost_diamonds > 0:
            player_object["diamonds"] = max(
                0, (player_object.get("diamonds", 0) or 0) - cost_diamonds
            )
        elif cost_coins > 0:
            player_object["coins"] = max(
                0, (player_object.get("coins", 0) or 0) - cost_coins
            )
    player_object.setdefault("islands", []).append(new_island)
    if msm_composer.is_composer_island(new_island):
        msm_composer.ensure_song(player_object, new_island)
    free_quad = ETHEREAL_FREE_QUAD_BY_ISLET.get(island_type)
    if free_quad:
        from msm_monsters import place_egg

        place_egg(player_object, new_island, free_quad, "islet_unlock", ready=True)

    repair_duplicate_structure_ids(player_object)
    save_player(username, root)
    result = {
        "success": True,
        "properties": create_player_properties(player_object),
        "tracks": msm_composer.wire_tracks(player_object),
        "songs": msm_composer.wire_songs(player_object),
        "user_island": new_island,
    }
    add_actual_currencies(result, player_object)
    return result


def update_island_mode(username, params):
    user_island_id = params.get("user_island_id", 0)
    if not user_island_id:
        island_field = params.get("island", 0)
        if island_field:
            user_island_id = 1000 + island_field
    mode = params.get("mode", 0)
    root, player_object = load_player(username)
    for island in player_object.get("islands") or []:
        current_id = island.get("user_island_id", 0)
        island_field = island.get("island", 0)
        if (
            user_island_id
            and current_id != user_island_id
            and island_field != (user_island_id - 1000)
        ):
            continue
        island["mode"] = mode
        island["island_mode"] = mode
        if get_active_island_id(player_object) == current_id:
            player_object["active_island_mode"] = mode
        break
    save_player(username, root)
    result = {"success": True, "mode": mode}
    if user_island_id:
        result["user_island_id"] = SFSLong(user_island_id)
    if "island" in params:
        result["island"] = params.get("island", 0)
    return result


def mute_island(username, params):

    user_island_id = (
        params.get("user_island_id", params.get("island_id", params.get("island", 0)))
        or 0
    )
    root, player_object = load_player(username)
    if not user_island_id:
        user_island_id = get_active_island_id(player_object)
    if 0 < user_island_id < 1000:
        user_island_id += 1000
    monster_ids, structure_ids = [], []
    requested_muted = params.get("muted")
    muted = 0
    for island in player_object.get("islands") or []:
        if island.get("user_island_id") != user_island_id:
            continue
        if requested_muted is not None:
            try:
                muted = 1 if int(requested_muted) else 0
            except (TypeError, ValueError):
                muted = 0 if island.get("muted", 0) else 1
        else:
            muted = 0 if island.get("muted", 0) else 1
        island["muted"] = muted
        for monster in island.get("monsters") or []:
            monster["muted"] = muted
            mid = monster.get("user_monster_id")
            if mid:
                monster_ids.append(int(mid))
        for structure in island.get("structures") or []:
            structure_def_id = structure.get(
                "structure", structure.get("structure_id", 0)
            )
            definition = get_structure_definition(structure_def_id)
            if not definition or definition.get("structure_type") != "castle":
                continue
            structure["muted"] = muted
            sid = structure.get("user_structure_id")
            if sid:
                structure_ids.append(int(sid))
        break
    save_player(username, root)
    return {
        "success": True,
        "user_island_id": SFSLong(user_island_id),
        "muted": muted,
        "monsters_muted": json.dumps(monster_ids, separators=(",", ":")),
        "structures_muted": json.dumps(structure_ids, separators=(",", ":")),
    }


def set_warp_island(username, params):
    user_island_id = params.get("user_island_id", 0)
    warp_speed = params.get("warp_speed", 1.0)
    root, player_object = load_player(username)
    island = find_island(player_object, user_island_id)
    if island is not None:
        island["warp_speed"] = warp_speed
        save_player(username, root)
    return {"success": True}


def _upsert_active_theme(player_object, theme_id, island_type):
    themes = player_object.setdefault("active_island_themes", [])
    already_active = False
    for i in range(len(themes) - 1, -1, -1):
        existing = themes[i]
        if existing is None:
            continue
        existing_island = (
            existing.get("i", existing.get("island", existing.get("island_id", 0))) or 0
        )
        if existing_island >= 1000:
            existing_island -= 1000
        if existing_island == island_type:
            existing_theme = existing.get("t", existing.get("theme_id", 0)) or 0
            if existing_theme == theme_id:
                already_active = True
            del themes[i]

    if not already_active:
        themes.append({"t": theme_id, "i": island_type})
    return themes, already_active


def buy_island_skin(username, params):

    theme_id = None
    for key in (
        "island_theme_id",
        "user_island_theme_id",
        "theme_id",
        "skin_id",
        "skin",
        "theme",
        "id",
        "storeitem_id",
    ):
        value = params.get(key)
        if value is not None:
            theme_id = value
            break
    if theme_id is None:
        theme_id = 1
    requested_island = (
        params.get("island_id")
        or params.get("user_island_id")
        or params.get("island")
        or 0
    )
    island_type = (
        requested_island - 1000 if requested_island >= 1000 else requested_island
    )
    theme_island = island_for_theme(theme_id)
    if theme_island:
        island_type = theme_island
    elif not island_type:
        island_type = 1
    root, player_object = load_player(username)
    owned = player_object.setdefault("owned_island_themes", [])
    if theme_id not in owned:
        owned.append(theme_id)
    themes, disabled = _upsert_active_theme(player_object, theme_id, island_type)
    save_player(username, root)
    reported_theme_id = 0 if disabled else theme_id
    theme = {"t": reported_theme_id, "i": island_type}
    return {
        "success": True,
        "cmd": "gs_buy_island_skin",
        "island_id": SFSLong(1000 + island_type),
        "user_island_id": SFSLong(1000 + island_type),
        "island": island_type,
        "user_island_theme_id": reported_theme_id,
        "theme_id": reported_theme_id,
        "skin_id": reported_theme_id,
        "cost_diamonds": 0,
        "price": 0,
        "currency": "diamonds",
        "active_island_theme": theme,
        "island_theme": theme,
        "properties": create_player_properties(player_object),
        "active_island_themes": themes,
    }


def activate_island_theme(username, params):
    full = dict(buy_island_skin(username, params))
    full["cmd"] = "gs_activate_island_theme"
    full["buy_and_activate_now"] = bool(params.get("buy_and_activate_now", True))
    full["trial"] = bool(params.get("trial"))
    return full


def get_island_rank(username, params):
    requested_island = (
        params.get("island_id")
        or params.get("user_island_id")
        or params.get("island")
        or 0
    )
    island_type = (
        requested_island - 1000 if requested_island >= 1000 else requested_island
    ) or 1
    root, player_object = load_player(username)
    display_name = player_object.get("display_name") or username
    bbb_id = player_object.get("bbb_id", 0) or 0
    theme = {
        "i": island_type,
        "island": island_type,
        "island_id": SFSLong(1000 + island_type),
        "theme_id": 1,
        "skin_id": 1,
        "storeitem_id": 0,
        "cost_diamonds": 2500,
        "price": 2500,
        "currency": "diamonds",
    }
    entry = {
        "rank": 1,
        "island_rank": 1,
        "score": 0,
        "likes": 999,
        "bbb_id": SFSLong(bbb_id),
        "user_id": SFSLong(bbb_id),
        "display_name": display_name,
        "player_name": display_name,
        "island_id": SFSLong(1000 + island_type),
        "user_island_id": SFSLong(1000 + island_type),
        "island": island_type,
        "island_type": island_type,
        "active_island_theme": theme,
        "island_theme": theme,
    }
    return {
        "success": True,
        "cmd": "gs_get_island_rank",
        "island_id": SFSLong(1000 + island_type),
        "user_island_id": SFSLong(1000 + island_type),
        "island": island_type,
        "island_type": island_type,
        "rank": 1,
        "island_rank": 1,
        "total_players": 1,
        "score": 0,
        "likes": 999,
        "rankings": [entry],
        "island_rankings": [entry],
        "islands": [entry],
        "island_data": [entry],
        "players": [entry],
        "active_island_theme": theme,
        "island_theme": theme,
        "theme_id": 1,
        "skin_id": 1,
        "cost_diamonds": 2500,
        "price": 2500,
        "currency": "diamonds",
    }


def set_last_timed_theme(username, params):
    root, player_object = load_player(username)
    player_object["last_timed_theme"] = []
    save_player(username, root)
    return {"success": True}


def mute_castle(username, params):
    return mute_island(username, params)


def get_island_boosts(username, params):
    return {
        "success": True,
        "boosts": [],
        "island_boosts": [],
        "active_boosts": [],
        "modifiers": [],
        "has_boosts": False,
        "properties": [],
    }
