import json
import random
import time
import msm_toggles

INSTANT_TIMER_FLOOR_MS = 1000
from msm_gamedata import (
    build_paironormal_modes,
    find_paironormal_form_id,
    get_bakery_food,
    get_ethereal_islet_definition,
    get_monster_definition,
    get_monster_level_definition,
    get_structure_definition,
    get_user_game_setting_int,
    resolve_paironormal_stored_monster_id,
    _paironormal_starpower_owed,
)
from msm_playerdata import (
    SFSLong,
    action_result,
    add_actual_currencies,
    create_player_properties,
    diamond_speedup_cost,
    find_island,
    find_island_by_structure,
    find_monster_with_island,
    find_structure,
    get_active_island_id,
    island_type_of,
    load_player,
    save_player,
)
from msm_protocol import SFSFloat


def _is_movable(structure_id):
    definition = get_structure_definition(structure_id)
    return definition is None or definition.get("movable", 1) != 0


def _is_obstacle_definition(definition):
    return (definition or {}).get("structure_type") == "obstacle"


def _charge_obstacle_cost(player_object, definition):
    if not msm_toggles.is_enabled("functioning_currencies"):
        return
    cost_diamonds = definition.get("cost_diamonds", 0) or 0
    cost_coins = definition.get("cost_coins", 0) or 0
    if cost_diamonds > 0:
        player_object["diamonds"] = max(
            0, (player_object.get("diamonds", 0) or 0) - cost_diamonds
        )
    elif cost_coins > 0:
        player_object["coins"] = max(
            0, (player_object.get("coins", 0) or 0) - cost_coins
        )


def _obstacle_user_structure_snapshot(structure):
    return {
        "island": SFSLong(
            structure.get("island", structure.get("user_island_id", 0)) or 0
        ),
        "date_created": SFSLong(structure.get("date_created", 0) or 0),
        "scale": SFSFloat(structure.get("scale", 1.0) or 1.0),
        "structure": structure.get("structure", 0),
        "pos_y": structure.get("pos_y", structure.get("row", 0)),
        "is_upgrading": structure.get("is_upgrading", 0),
        "user_structure_id": SFSLong(structure.get("user_structure_id", 0)),
        "pos_x": structure.get("pos_x", structure.get("col", 0)),
        "in_warehouse": structure.get("in_warehouse", 0),
        "is_complete": structure.get("is_complete", 1),
        "building_completed": SFSLong(structure.get("building_completed", 0) or 0),
        "muted": structure.get("muted", 0),
        "flip": structure.get("flip", structure.get("flipped", 0)),
    }


def _upgrade_target(structure_id):
    definition = get_structure_definition(structure_id)
    if not definition:
        return 0
    return definition.get("upgrades_to", 0) or 0


def _repair_active_magical_nexus_structure_ids(island):
    if island is None or island_type_of(island) != 25:
        return
    for structure in island.get("structures") or []:
        if not isinstance(structure, dict):
            continue
        structure_type = structure.get("structure", 0)
        if structure_type == 925:
            structure["user_structure_id"] = 1
        elif structure_type in (922, 947):
            structure["user_structure_id"] = 2
            structure["muted"] = 0


def _locate(player_object, structure_id):
    island = find_island(player_object, get_active_island_id(player_object))
    _repair_active_magical_nexus_structure_ids(island)
    structure = find_structure(island, structure_id)
    if structure is None:
        island, structure = find_island_by_structure(player_object, structure_id)
    return island, structure


def _structure_update(structure, mode="full"):
    structure_id = SFSLong(structure.get("user_structure_id", 0))
    user_island_id = structure.get("user_island_id", 0)
    island_type = structure.get("island_type", structure.get("island", 0)) or 0
    if (island_type <= 0 or island_type >= 1000) and user_island_id >= 1000:
        island_type = user_island_id - 1000
    raw_island = structure.get(
        "island", user_island_id if user_island_id > 0 else island_type
    )
    if 0 < raw_island < 1000 and user_island_id >= 1000:
        raw_island = user_island_id
    pos_x = structure.get("pos_x", structure.get("col", 0))
    pos_y = structure.get("pos_y", structure.get("row", 0))
    flip = structure.get("flip", structure.get("flipped", 0))
    scale = SFSFloat(structure.get("scale", 1.0) or 1.0)
    update = {
        "user_structure_id": structure_id,
        "user_island_id": SFSLong(user_island_id),
        "island": SFSLong(raw_island),
        "island_type": int(island_type),
    }
    if mode == "move":
        update["pos_x"] = pos_x
        update["pos_y"] = pos_y
        update["scale"] = scale
        update["properties"] = [{"pos_x": pos_x}, {"pos_y": pos_y}, {"scale": scale}]
    elif mode == "flip":
        update["flip"] = flip
    elif mode == "upgrade":
        building_completed = structure.get("building_completed", 0) or 0
        remaining = (
            max(0, (building_completed - int(time.time() * 1000)) // 1000)
            if building_completed
            else 0
        )
        update.update(
            {
                "structure": structure.get("structure", 0),
                "structure_id": structure.get("structure", 0),
                "pos_x": pos_x,
                "pos_y": pos_y,
                "col": pos_x,
                "row": pos_y,
                "scale": scale,
                "flip": flip,
                "flipped": flip,
                "muted": structure.get("muted", 0),
                "in_warehouse": structure.get("in_warehouse", 0),
                "occupied": structure.get("occupied", 0),
                "has_egg": structure.get("has_egg", 0),
                "viewed": structure.get("viewed", 0),
                "book_value": structure.get("book_value", 100),
                "date_created": SFSLong(structure.get("date_created", 0) or 0),
                "last_collection": SFSLong(structure.get("last_collection", 0) or 0),
                "last_collected": SFSLong(
                    structure.get("last_collected", structure.get("last_collection", 0))
                    or 0
                ),
                "level": structure.get("level", 1),
                "is_upgrading": structure.get("is_upgrading", 0),
                "is_complete": structure.get("is_complete", 1),
                "building_completed": SFSLong(building_completed),
                "finishing_time": SFSLong(
                    structure.get("finishing_time", structure.get("obj_end", 0)) or 0
                ),
                "obj_data": structure.get("obj_data", 0),
                "obj_end": SFSLong(structure.get("obj_end", 0) or 0),
                "pending_upgrade_structure": structure.get(
                    "pending_upgrade_structure", 0
                ),
                "complete_on": SFSLong(building_completed),
                "seconds_remaining": SFSLong(remaining),
                "time_remaining": SFSLong(remaining),
            }
        )
    else:
        update.update(
            {
                "structure": structure.get("structure", 0),
                "pos_x": pos_x,
                "pos_y": pos_y,
                "scale": scale,
                "flip": flip,
                "muted": bool(structure.get("muted", 0)),
                "in_warehouse": structure.get("in_warehouse", 0),
                "is_upgrading": structure.get("is_upgrading", 0),
                "is_complete": structure.get("is_complete", 1),
                "building_completed": SFSLong(
                    structure.get("building_completed", 0) or 0
                ),
                "last_collection": SFSLong(structure.get("last_collection", 0) or 0),
                "obj_data": structure.get("obj_data", 0),
                "obj_end": SFSLong(structure.get("obj_end", 0) or 0),
                "level": structure.get("level", 1),
                "occupied": bool(structure.get("occupied", False)),
                "has_egg": bool(structure.get("has_egg", False)),
                "viewed": bool(structure.get("viewed", False)),
            }
        )
    update.setdefault("properties", [])
    return update


def _first_param(params, keys, default=0):
    for key in keys:
        value = params.get(key)
        if value is not None:
            return value
    return default


def move_structure(username, params):
    import msm_monsters

    structure_id = _first_param(
        params,
        ("user_structure_id", "userStructureId", "structure_id", "structureId", "id"),
        0,
    )
    pos_x = _first_param(params, ("pos_x", "x", "col", "column"), 0)
    pos_y = _first_param(params, ("pos_y", "y", "row"), 0)
    scale = _first_param(params, ("scale", "size"), 1.0)
    root, player_object = load_player(username)
    island, structure = _locate(player_object, structure_id)
    if structure is None:
        return (
            action_result(
                False, "user_structure_id", structure_id, with_properties=True
            ),
            {},
        )
    if _is_movable(structure.get("structure", 0)):
        structure["pos_x"] = pos_x
        structure["pos_y"] = pos_y
        structure["col"] = pos_x
        structure["row"] = pos_y
        structure["scale"] = scale
        happy_effects = msm_monsters.recompute_island_happiness(island)
        save_player(username, root)
    else:
        happy_effects = []
    result = action_result(True, "user_structure_id", structure_id)
    result["properties"] = create_player_properties(player_object)
    result["monster_happy_effects"] = happy_effects
    add_actual_currencies(result, player_object)
    return result, _structure_update(structure, "move")


def flip_structure(username, params):
    structure_id = params.get("user_structure_id", 0)
    flipped = params.get("flipped", False)
    root, player_object = load_player(username)
    island = find_island(player_object, get_active_island_id(player_object))
    structure = find_structure(island, structure_id)
    if structure is None:
        return (
            action_result(
                False, "user_structure_id", structure_id, with_properties=True
            ),
            {},
        )
    structure["flip"] = 1 if flipped else 0
    save_player(username, root)
    result = action_result(True, "user_structure_id", structure_id)
    result["properties"] = create_player_properties(player_object)
    return result, _structure_update(structure, "flip")


def sell_structure(username, params):
    structure_id = params.get("user_structure_id", 0)
    root, player_object = load_player(username)
    island = find_island(player_object, get_active_island_id(player_object))
    if island is not None:
        structures = island.get("structures") or []

        if msm_toggles.is_enabled("functioning_currencies"):
            sold_structure = next(
                (
                    s
                    for s in structures
                    if s is not None and s.get("user_structure_id") == structure_id
                ),
                None,
            )
            if sold_structure is not None:
                book_value = sold_structure.get("book_value") or 0

                refund = int(
                    book_value
                    * (
                        msm_toggles.get_int(
                            "sell_percentage", 75, minimum=0, maximum=100
                        )
                        / 100.0
                    )
                )
                if refund > 0:
                    player_object["coins"] = (
                        player_object.get("coins", 0) or 0
                    ) + refund
        for i in range(len(structures) - 1, -1, -1):
            if (
                structures[i] is not None
                and structures[i].get("user_structure_id") == structure_id
            ):
                del structures[i]
                break

        eggs = island.get("eggs")
        if eggs:
            island["eggs"] = [
                e for e in eggs if e is None or e.get("structure") != structure_id
            ]
        breeding = island.get("breeding")
        if breeding:
            island["breeding"] = [
                b for b in breeding if b is None or b.get("structure") != structure_id
            ]
        synthesizing = island.get("synthesizing")
        if synthesizing:
            island["synthesizing"] = [
                s
                for s in synthesizing
                if s is None or s.get("structure") != structure_id
            ]
        import msm_monsters

        happy_effects = msm_monsters.recompute_island_happiness(island)
        save_player(username, root)
    else:
        happy_effects = []
    result = action_result(True, "user_structure_id", structure_id)
    result["properties"] = create_player_properties(player_object)
    result["monster_happy_effects"] = happy_effects
    add_actual_currencies(result, player_object)
    return result


def collect_nucleus_reward(username, params):
    structure_id = (
        params.get("user_structure_id", 0) or params.get("structure_id", 0) or 0
    )
    root, player_object = load_player(username)
    island, structure = _locate(player_object, structure_id)
    if structure is None:
        return action_result(
            False, "user_structure_id", structure_id, with_properties=True
        )
    now = int(time.time() * 1000)
    nucleus = structure.setdefault("nucleus_data", {})
    sets = max(1, int(nucleus.get("highest_num_sets", 1) or 1))
    amount = 1000 * sets * max(1, len(island.get("monsters") or []) // 4 or 1)
    interval = (
        get_user_game_setting_int("USER_NUCLEUS_REWARD_INTERVAL", 70298) * 1000
        or 70298000
    )
    nucleus.update(
        {
            "highest_num_sets": sets,
            "started_on": SFSLong(now),
            "complete_on": SFSLong(now + interval),
            "has_rewards": False,
            "structure": structure.get("user_structure_id", structure_id),
        }
    )
    if msm_toggles.is_enabled("functioning_currencies"):
        player_object["coins"] = (player_object.get("coins", 0) or 0) + amount
    save_player(username, root)
    result = action_result(True, "user_structure_id", structure_id)
    result["nucleus_data"] = nucleus
    result["loot"] = [
        {
            "amount": amount,
            "premium": False,
            "scaled": False,
            "scale": False,
            "id": 0,
            "type": 5,
        }
    ]
    result["properties"] = create_player_properties(player_object)
    add_actual_currencies(result, player_object)
    return result


def start_obstacle(username, params):
    structure_id = params.get("user_structure_id", 0) or 0
    root, player_object = load_player(username)
    island, structure = _locate(player_object, structure_id)
    if structure is None:
        return (
            action_result(
                False, "user_structure_id", structure_id, with_properties=True
            ),
            {},
        )
    definition = get_structure_definition(structure.get("structure", 0)) or {}
    if not _is_obstacle_definition(definition):
        return (
            action_result(
                False, "user_structure_id", structure_id, with_properties=True
            ),
            {},
        )
    build_ms = (
        INSTANT_TIMER_FLOOR_MS
        if msm_toggles.is_enabled("instant_timers")
        else max(0, definition.get("build_time", 0) or 0) * 1000
    )
    now = int(time.time() * 1000)
    complete_on = now + build_ms
    structure["is_upgrading"] = 0
    structure["is_complete"] = 1
    structure["date_created"] = SFSLong(now)
    structure["building_completed"] = SFSLong(complete_on)
    for key in ("obj_data", "obj_end", "finishing_time", "pending_upgrade_structure"):
        structure.pop(key, None)
    _charge_obstacle_cost(player_object, definition)
    save_player(username, root)
    result = action_result(True, "user_structure_id", structure_id)
    result["user_structure"] = _obstacle_user_structure_snapshot(structure)
    result["properties"] = create_player_properties(player_object)
    add_actual_currencies(result, player_object)
    return result, {}


def clear_obstacle_speed_up(username, params):
    structure_id = (
        params.get("user_structure_id", 0)
        or params.get("structure_id", 0)
        or params.get("userStructureId", 0)
        or 0
    )
    root, player_object = load_player(username)
    island, structure = _locate(player_object, structure_id)
    if structure is None:
        return (
            action_result(
                False, "user_structure_id", structure_id, with_properties=True
            ),
            {},
        )
    definition = get_structure_definition(structure.get("structure", 0)) or {}
    if not _is_obstacle_definition(definition):
        return (
            action_result(
                False, "user_structure_id", structure_id, with_properties=True
            ),
            {},
        )
    now = int(time.time() * 1000)
    started_on = structure.get("date_created", 0) or now
    complete_on = structure.get("building_completed", 0) or now
    remaining = complete_on - now
    _charge_speedup(player_object, remaining)
    structure["date_created"] = SFSLong(started_on)
    structure["building_completed"] = SFSLong(now)
    save_player(username, root)
    return {"success": True}, _upgrade_timing_update(structure, player_object)


def finish_structure(username, params):
    structure_id = params.get("user_structure_id", 0) or 0
    root, player_object = load_player(username)
    island, structure = _locate(player_object, structure_id)
    if structure is None:
        return (
            action_result(
                False, "user_structure_id", structure_id, with_properties=True
            ),
            {},
        )
    pending = structure.get("pending_upgrade_structure", 0) or 0
    if pending:
        structure["structure"] = pending
        structure["level"] = (structure.get("level", 0) or 0) + 1
        structure["pending_upgrade_structure"] = 0
    structure["is_upgrading"] = 0
    structure["is_complete"] = 1
    structure["obj_data"] = 0
    structure["obj_end"] = 0
    structure["finishing_time"] = 0
    structure["building_completed"] = 0
    save_player(username, root)
    result = action_result(True, "user_structure_id", structure_id)
    result["properties"] = create_player_properties(player_object)
    add_actual_currencies(result, player_object)
    return result, _structure_update(structure, "upgrade")


def clear_obstacle(username, params):

    structure_id = _first_param(
        params,
        ("user_structure_id", "userStructureId", "structure_id", "structureId", "id"),
        0,
    )
    root, player_object = load_player(username)
    island = find_island(player_object, get_active_island_id(player_object))
    obstacle = None
    if island is not None:
        structures = island.get("structures") or []
        obstacle = next(
            (
                s
                for s in structures
                if s is not None and s.get("user_structure_id") == structure_id
            ),
            None,
        )
    if obstacle is None:
        island, obstacle = find_island_by_structure(player_object, structure_id)
    if island is None or obstacle is None:
        result = action_result(False, "user_structure_id", structure_id)
        result["properties"] = create_player_properties(player_object)
        add_actual_currencies(result, player_object)
        return result
    definition = get_structure_definition(obstacle.get("structure", 0)) or {}
    if not _is_obstacle_definition(definition):
        result = action_result(False, "user_structure_id", structure_id)
        result["properties"] = create_player_properties(player_object)
        add_actual_currencies(result, player_object)
        return result
    xp = definition.get("xp", 0) or 0
    if xp > 0:
        player_object["xp"] = (player_object.get("xp", 0) or 0) + xp
    structures = island.get("structures") or []
    for i in range(len(structures) - 1, -1, -1):
        if (
            structures[i] is not None
            and structures[i].get("user_structure_id") == structure_id
        ):
            del structures[i]
            break
    save_player(username, root)
    result = action_result(True, "user_structure_id", structure_id)
    result["properties"] = create_player_properties(player_object)
    add_actual_currencies(result, player_object)
    return result


def mute_structure(username, params):

    structure_id = params.get("user_structure_id", 0)
    root, player_object = load_player(username)
    island, structure = _locate(player_object, structure_id)
    muted = 0
    update = None
    if structure is not None:
        muted = 0 if structure.get("muted", 0) else 1
        structure["muted"] = muted
        save_player(username, root)
        update = {
            "user_structure_id": SFSLong(structure_id),
            "properties": [{"muted": muted}],
        }
    return update


def _flat_structure_snapshot(structure):
    return {
        "user_structure_id": SFSLong(structure.get("user_structure_id", 0)),
        "island": SFSLong(structure.get("island", 0) or 0),
        "structure": structure.get("structure", 0),
        "pos_x": structure.get("pos_x", 0),
        "pos_y": structure.get("pos_y", 0),
        "scale": SFSFloat(structure.get("scale", 1.0) or 1.0),
        "flip": structure.get("flip", 0),
        "muted": structure.get("muted", 0),
        "in_warehouse": structure.get("in_warehouse", 0),
        "is_upgrading": structure.get("is_upgrading", 0),
        "is_complete": structure.get("is_complete", 1),
        "building_completed": SFSLong(structure.get("building_completed", 0) or 0),
        "last_collection": SFSLong(structure.get("last_collection", 0) or 0),
    }


def _upgrade_properties_update(structure, player_object):
    return {
        "user_structure_id": SFSLong(structure.get("user_structure_id", 0)),
        "properties": [
            {"is_complete": structure.get("is_complete", 1)},
            {"is_upgrading": structure.get("is_upgrading", 0)},
            {"date_created": SFSLong(structure.get("date_created", 0) or 0)},
            {
                "building_completed": SFSLong(
                    structure.get("building_completed", 0) or 0
                )
            },
        ]
        + create_player_properties(player_object),
    }


def _upgrade_timing_update(structure, player_object):
    return {
        "user_structure_id": SFSLong(structure.get("user_structure_id", 0)),
        "properties": [
            {
                "building_completed": SFSLong(
                    structure.get("building_completed", 0) or 0
                )
            },
            {"date_created": SFSLong(structure.get("date_created", 0) or 0)},
        ]
        + create_player_properties(player_object),
    }


_UPDATE_STRUCTURE_UPGRADE_START_KEYS = {
    "is_complete",
    "is_upgrading",
    "building_completed",
    "date_created",
    "finishing_time",
    "obj_end",
}
_UPDATE_STRUCTURE_KEYS = _UPDATE_STRUCTURE_UPGRADE_START_KEYS | {
    "pos_x",
    "pos_y",
    "col",
    "row",
    "scale",
    "flip",
    "flipped",
    "muted",
    "in_warehouse",
    "obj_data",
    "last_collection",
    "last_collected",
    "occupied",
    "has_egg",
    "viewed",
    "level",
}
_LONG_STRUCTURE_KEYS = {
    "building_completed",
    "date_created",
    "finishing_time",
    "obj_end",
    "last_collection",
    "last_collected",
}


def update_structure(username, params):
    structure_id = params.get("user_structure_id", 0) or 0
    properties = params.get("properties") or []
    root, player_object = load_player(username)
    island = find_island(player_object, get_active_island_id(player_object))
    _repair_active_magical_nexus_structure_ids(island)
    structure = find_structure(island, structure_id)
    if structure is None:
        return None
    flat = {}
    for entry in properties:
        if isinstance(entry, dict):
            flat.update(entry)
    structure_properties = []
    changed = False
    for entry in properties:
        if not isinstance(entry, dict):
            continue
        for key, value in entry.items():
            if key not in _UPDATE_STRUCTURE_KEYS:
                continue
            target_key = "flip" if key == "flipped" else key
            if target_key == "col":
                target_key = "pos_x"
            elif target_key == "row":
                target_key = "pos_y"
            structure[target_key] = value
            if target_key == "pos_x":
                structure["col"] = value
            elif target_key == "pos_y":
                structure["row"] = value
            elif target_key == "flip":
                structure["flipped"] = value
            out_value = SFSLong(value) if key in _LONG_STRUCTURE_KEYS else value
            structure_properties.append({key: out_value})
            changed = True
    if flat.get("is_upgrading") == 1 and structure.get("is_complete") == 0:
        structure["obj_data"] = 1
        if "building_completed" in flat:
            structure["obj_end"] = flat["building_completed"]
            structure["finishing_time"] = flat["building_completed"]
        pending = _upgrade_target(structure.get("structure", 0))
        if pending:
            structure["pending_upgrade_structure"] = pending
        changed = True
    if changed:
        save_player(username, root)
    result = {"success": True, "user_structure_id": SFSLong(structure_id)}
    result["properties"] = structure_properties + create_player_properties(
        player_object
    )
    return result


def _charge_speedup(player_object, remaining_ms):

    if not msm_toggles.is_enabled("functioning_currencies"):
        return
    cost = diamond_speedup_cost(remaining_ms)
    player_object["diamonds"] = max(0, (player_object.get("diamonds", 0) or 0) - cost)


def speed_up_structure(username, params):
    structure_id = params.get("user_structure_id", 0) or 0
    root, player_object = load_player(username)
    island, structure = _locate(player_object, structure_id)
    update = {}
    if structure is not None:
        now = int(time.time() * 1000)
        remaining = (structure.get("building_completed", now) or now) - now
        _charge_speedup(player_object, remaining)
        structure["building_completed"] = now
        structure["obj_end"] = now
        structure["finishing_time"] = now
        save_player(username, root)
        update = _upgrade_timing_update(structure, player_object)
    return {"success": True}, update


def _charge_upgrade_cost(player_object, definition):
    if not definition or not msm_toggles.is_enabled("functioning_currencies"):
        return
    cost_diamonds = definition.get("cost_diamonds", 0) or 0
    cost_coins = definition.get("cost_coins", 0) or 0
    cost_relics = definition.get("cost_relics", 0) or 0
    cost_keys = definition.get("cost_keys", 0) or 0
    cost_eth = definition.get("cost_eth_currency", 0) or 0
    if cost_diamonds > 0:
        player_object["diamonds"] = max(
            0, (player_object.get("diamonds", 0) or 0) - cost_diamonds
        )
    elif cost_coins > 0:
        player_object["coins"] = max(
            0, (player_object.get("coins", 0) or 0) - cost_coins
        )
    elif cost_relics > 0:
        player_object["relics"] = max(
            0, (player_object.get("relics", 0) or 0) - cost_relics
        )
    elif cost_keys > 0:
        player_object["keys"] = max(0, (player_object.get("keys", 0) or 0) - cost_keys)
    elif cost_eth > 0:
        player_object["ethereal_currency"] = max(
            0, (player_object.get("ethereal_currency", 0) or 0) - cost_eth
        )


def start_upgrade_structure(username, params):
    structure_id = params.get("user_structure_id", 0)
    root, player_object = load_player(username)
    island, structure = _locate(player_object, structure_id)
    if structure is None:
        return (
            action_result(
                False, "user_structure_id", structure_id, with_properties=True
            ),
            {},
        )
    next_id = _upgrade_target(structure.get("structure", 0))
    success = next_id > 0
    if success:
        now = int(time.time() * 1000)
        definition = get_structure_definition(next_id)
        _charge_upgrade_cost(player_object, definition)
        build_ms = (
            INSTANT_TIMER_FLOOR_MS
            if msm_toggles.is_enabled("instant_timers")
            else max(0, (definition.get("build_time", 0) if definition else 0)) * 1000
        )
        complete_on = now + build_ms
        structure["is_upgrading"] = 1
        structure["is_complete"] = 0
        structure["obj_data"] = 1
        structure["date_created"] = now
        structure["building_completed"] = complete_on
        structure["obj_end"] = complete_on
        structure["finishing_time"] = complete_on
        structure["pending_upgrade_structure"] = next_id
        save_player(username, root)
    result = action_result(success, "user_structure_id", structure_id)
    result["properties"] = create_player_properties(player_object)
    update = {}
    if success:
        result["user_structure"] = _flat_structure_snapshot(structure)
        update = _upgrade_properties_update(structure, player_object)
    return result, update


def speed_up_upgrade_structure(username, params):
    structure_id = params.get("user_structure_id", 0)
    root, player_object = load_player(username)
    island, structure = _locate(player_object, structure_id)
    if structure is None or not structure.get("is_upgrading"):
        return (
            action_result(
                False, "user_structure_id", structure_id, with_properties=True
            ),
            {},
        )
    finished_at = int(time.time() * 1000)
    remaining = (
        structure.get("building_completed", finished_at) or finished_at
    ) - finished_at
    _charge_speedup(player_object, remaining)
    structure["building_completed"] = finished_at
    structure["obj_end"] = finished_at
    structure["finishing_time"] = finished_at
    save_player(username, root)
    result = action_result(True, "user_structure_id", structure_id)
    result["properties"] = create_player_properties(player_object)
    result["building_completed"] = SFSLong(finished_at)
    update = _upgrade_timing_update(structure, player_object)
    return result, update


def finish_upgrade_structure(username, params):
    structure_id = params.get("user_structure_id", 0)
    root, player_object = load_player(username)
    island, structure = _locate(player_object, structure_id)
    if structure is None:
        return (
            action_result(
                False, "user_structure_id", structure_id, with_properties=True
            ),
            {},
        )
    next_id = structure.get("pending_upgrade_structure") or _upgrade_target(
        structure.get("structure", 0)
    )
    success = next_id > 0
    finished_at = int(time.time() * 1000)
    if success:
        structure["structure"] = next_id
        structure["structure_id"] = next_id
        structure["level"] = structure.get("level", 0) + 1
        structure["is_upgrading"] = 0
        structure["is_complete"] = 1
        structure["building_completed"] = finished_at
        structure["obj_end"] = finished_at
        structure["finishing_time"] = finished_at
        structure["pending_upgrade_structure"] = 0
        structure["obj_data"] = 0
        save_player(username, root)
    result = action_result(success, "user_structure_id", structure_id)
    result["properties"] = create_player_properties(player_object)
    if success:
        result["user_structure"] = _flat_structure_snapshot(structure)
        import msm_islands

        if msm_islands._is_crucible_structure(structure):
            result["user_crucible"] = msm_islands._crucible_wire_object(
                island, structure
            )
    return result, {}


def _fugue_target_mode(player_object, monster_id, fallback_island):
    _isl, mon = find_monster_with_island(player_object, monster_id)
    if not mon:
        return 1
    island_type = island_type_of(_isl or fallback_island) or 0
    stored = resolve_paironormal_stored_monster_id(
        mon.get("monster", 0), island_type
    ) or mon.get("monster", 0)
    major_id = find_paironormal_form_id(stored, island_type, True)
    minor_id = find_paironormal_form_id(stored, island_type, False)
    modes = mon.get("modes") or []
    has_major = any(
        isinstance(e, dict) and e.get("monster") == major_id and e.get("a")
        for e in modes
    )
    has_minor = any(
        isinstance(e, dict) and e.get("monster") == minor_id and e.get("a")
        for e in modes
    )
    if has_minor and not has_major:
        return 0
    if has_major and not has_minor:
        return 1
    current = (
        (fallback_island.get("mode", fallback_island.get("island_mode", 0)) or 0)
        if fallback_island
        else 0
    )
    return 1 - current


def start_fuguing(username, params):
    structure_id = params.get("user_structure_id", 0)
    monster_id = params.get("user_monster_id", params.get("monster_id", 0)) or 0
    root, player_object = load_player(username)
    island, structure = _locate(player_object, structure_id)
    if structure is None:
        return (
            action_result(
                False, "user_structure_id", structure_id, with_properties=True
            ),
            {},
        )
    now = int(time.time() * 1000)

    activated_mode = params.get("activated_mode")
    if activated_mode is None:
        activated_mode = _fugue_target_mode(player_object, monster_id, island)
    success = True
    if success:

        island_type = island_type_of(island) or 0
        _fugue_monster_island, fugue_monster = find_monster_with_island(
            player_object, monster_id
        )
        species_id = (fugue_monster or {}).get("monster", 0) or monster_id
        stored_id = (
            resolve_paironormal_stored_monster_id(species_id, island_type) or species_id
        )
        monster_definition = get_monster_definition(stored_id) or {}
        duration_ms = max(0, monster_definition.get("build_time", 0) or 0) * 1000
    else:

        definition = get_structure_definition(structure.get("structure", 0)) or {}
        duration_ms = max(0, definition.get("build_time", 0) or 0) * 1000
        if duration_ms <= 0:

            upgrade_id = definition.get("upgrades_to") or _upgrade_target(
                structure.get("structure", 0)
            )
            upgraded = get_structure_definition(upgrade_id) or {}
            duration_ms = max(0, upgraded.get("build_time", 0) or 0) * 1000
    if msm_toggles.is_enabled("instant_timers"):
        duration_ms = INSTANT_TIMER_FLOOR_MS
    complete_on = now + duration_ms
    structure["is_upgrading"] = 1
    structure["obj_data"] = 1
    structure["obj_end"] = complete_on
    fuguing_entries = [
        e
        for e in (island.get("fuguing") or [])
        if not (isinstance(e, dict) and e.get("structure") == structure_id)
    ]
    fuguing_entries.append(
        {
            "started_on": SFSLong(now),
            "complete_on": SFSLong(complete_on),
            "activated_mode": activated_mode,
            "structure": structure_id,
            "monster": monster_id,
            "success": success,
        }
    )
    island["fuguing"] = fuguing_entries
    save_player(username, root)
    result = {
        "success": True,
        "user_structure_id": SFSLong(structure_id),
        "used_monster": monster_id,
        "user_fuguing_data": {
            "started_on": SFSLong(now),
            "complete_on": SFSLong(complete_on),
            "activated_mode": activated_mode,
            "structure": structure_id,
            "monster": monster_id,
            "success": success,
        },
        "properties": create_player_properties(player_object),
    }
    add_actual_currencies(result, player_object)

    return result, {}


def speed_up_fuguing(username, params):
    structure_id = params.get("user_structure_id", 0)
    root, player_object = load_player(username)
    island, structure = _locate(player_object, structure_id)
    if structure is None:
        return (
            action_result(
                False, "user_structure_id", structure_id, with_properties=True
            ),
            {},
        )
    finished_at = int(time.time() * 1000)
    for entry in island.get("fuguing") or []:
        if isinstance(entry, dict) and entry.get("structure") == structure_id:
            remaining = (
                entry.get("complete_on", finished_at) or finished_at
            ) - finished_at
            _charge_speedup(player_object, remaining)
            break
    structure["obj_end"] = finished_at

    for entry in island.get("fuguing") or []:
        if isinstance(entry, dict) and entry.get("structure") == structure_id:
            entry["complete_on"] = SFSLong(finished_at)
    result = action_result(True, "user_structure_id", structure_id)
    result["obj_end"] = SFSLong(finished_at)
    result["properties"] = create_player_properties(player_object)
    add_actual_currencies(result, player_object)
    save_player(username, root)

    return result, {}


def finish_fuguing(username, params):
    structure_id = params.get("user_structure_id", 0)
    root, player_object = load_player(username)
    island, structure = _locate(player_object, structure_id)
    if structure is None:
        return (
            action_result(
                False, "user_structure_id", structure_id, with_properties=True
            ),
            {},
            [],
        )
    reward = 99
    player_object["starpower"] = (player_object.get("starpower", 0) or 0) + reward
    player_object["starpower_actual"] = player_object["starpower"]
    player_object["total_starpower_collected"] = (
        player_object.get("total_starpower_collected", 0) or 0
    ) + reward

    fuguing_entries = (island.get("fuguing") or []) if island else []
    pending = None
    remaining = []
    for entry in fuguing_entries:
        if (
            pending is None
            and isinstance(entry, dict)
            and entry.get("structure") == structure_id
        ):
            pending = entry
            continue
        remaining.append(entry)
    if island is not None:
        island["fuguing"] = remaining
    extra_frames = []
    if pending is not None and pending.get("success"):

        monster_id = pending.get("monster") or 0
        activated_mode = pending.get("activated_mode", 1)
        if monster_id:
            monster_island, monster = find_monster_with_island(
                player_object, monster_id
            )
            island_type = island_type_of(monster_island or island)
            if monster is not None and island_type:
                new_entry = build_paironormal_modes(
                    monster, island_type, activated_mode, player_object
                )
                base_uid = monster.get("user_monster_id")
                if new_entry and base_uid:
                    now = int(time.time() * 1000)
                    stored_id = resolve_paironormal_stored_monster_id(
                        monster.get("monster", 0), island_type
                    )
                    major_id = find_paironormal_form_id(stored_id, island_type, True)
                    minor_id = find_paironormal_form_id(stored_id, island_type, False)
                    book_value = (
                        (get_monster_definition(major_id) or {}).get("cost_coins", 0)
                        or 0
                    ) + (
                        (get_monster_definition(minor_id) or {}).get("cost_coins", 0)
                        or 0
                    )
                    monster["book_value"] = book_value
                    monster["happiness"] = 100
                    starpower_owed = _paironormal_starpower_owed(
                        monster.get("level", 1) or 1,
                        monster.get("last_collection", now) or now,
                        now,
                    )
                    monster["last_collection"] = now
                    filled_mode = 0 if new_entry.get("monster") == major_id else 1
                    extra_frames.append(
                        (
                            "gs_update_monster",
                            {
                                "mode": filled_mode,
                                "mode_state": new_entry,
                                "user_monster_id": SFSLong(base_uid),
                            },
                        )
                    )
                    extra_frames.append(
                        (
                            "gs_update_monster",
                            {
                                "book_value": book_value,
                                "happiness": 100,
                                "user_monster_id": SFSLong(base_uid),
                            },
                        )
                    )
                    extra_frames.append(
                        (
                            "gs_update_monster",
                            {
                                "mode": 1 - filled_mode,
                                "user_monster_id": SFSLong(base_uid),
                                "last_collection": now,
                                "collected_starpower": SFSFloat(starpower_owed),
                            },
                        )
                    )
    elif pending is not None:

        monster_id = pending.get("monster") or 0
        if monster_id:
            _failed_island, failed_monster = find_monster_with_island(
                player_object, monster_id
            )
            if failed_monster is not None:
                import msm_monsters

                feed_update = msm_monsters.apply_feed(
                    player_object,
                    failed_monster,
                    monster_id,
                    charge_food=False,
                )
                if feed_update:
                    extra_frames.append(("gs_update_monster", feed_update))
    structure["is_upgrading"] = 0
    structure["obj_data"] = 0
    structure["obj_end"] = 0
    save_player(username, root)
    result = {
        "success": True,
        "user_structure_id": SFSLong(structure_id),
        "properties": create_player_properties(player_object),
    }

    add_actual_currencies(result, player_object)
    return result, {}, extra_frames


def viewed_fugued_monster(username, params):

    structure_id = params.get("user_structure_id", 0) or 0
    root, player_object = load_player(username)
    island, structure = (
        _locate(player_object, structure_id) if structure_id else (None, None)
    )
    if structure is not None:
        structure["viewed"] = True
        save_player(username, root)
    result = {"success": True}
    if structure_id:
        result["user_structure_id"] = SFSLong(structure_id)
    return result


def merge_fugue(username, params):

    structure_id = params.get("user_structure_id", 0) or 0
    requested_monster_id = params.get("user_monster_id", 0) or 0
    root, player_object = load_player(username)
    island, structure = (
        _locate(player_object, structure_id) if structure_id else (None, None)
    )
    if island is None and requested_monster_id:
        for candidate_island in player_object.get("islands") or []:
            if candidate_island is None:
                continue
            for entry in candidate_island.get("fuguing") or []:
                if (
                    isinstance(entry, dict)
                    and entry.get("monster") == requested_monster_id
                ):
                    island = candidate_island
                    break
            if island is not None:
                break
    fuguing_entries = (island.get("fuguing") if island else None) or []
    pending = None
    remaining = []
    for entry in fuguing_entries:
        matches = (
            isinstance(entry, dict)
            and pending is None
            and (
                (structure_id and entry.get("structure") == structure_id)
                or (
                    requested_monster_id
                    and entry.get("monster") == requested_monster_id
                )
            )
        )
        if matches:
            pending = entry
            continue
        remaining.append(entry)
    if island is not None:
        island["fuguing"] = remaining
    monster_id = requested_monster_id or (pending or {}).get("monster", 0) or 0
    activated_mode = (pending or {}).get("activated_mode", 1)
    success = bool((pending or {}).get("success"))
    if success and monster_id:
        monster_island, monster = find_monster_with_island(player_object, monster_id)
        island_type = island_type_of(monster_island or island)
        if monster is not None and island_type:
            build_paironormal_modes(monster, island_type, activated_mode, player_object)
    save_player(username, root)
    result = {
        "success": True,
        "activated_mode": activated_mode,
        "user_monster_id": SFSLong(monster_id),
        "destroy_user_monster_id": SFSLong(0),
        "properties": create_player_properties(player_object),
    }
    add_actual_currencies(result, player_object)
    return result, {}


def buy_structure(username, params):
    pos_x = params.get("pos_x", params.get("col", 0)) or 0
    pos_y = params.get("pos_y", params.get("row", 0)) or 0
    scale = params.get("scale", 1.0) or 1.0
    structure_id = (
        params.get("structure_id", params.get("structure", params.get("id", 0))) or 0
    )
    flip = params.get("flip", params.get("flipped", 0)) or 0
    root, player_object = load_player(username)
    island_id = get_active_island_id(player_object)
    island = find_island(player_object, island_id)
    island_type = (
        island.get("island_type", island.get("island", max(1, island_id - 1000)))
        if island
        else max(1, island_id - 1000)
    )
    if island_type >= 1000 and island_id >= 1000:
        island_type = island_id - 1000
    definition = get_structure_definition(structure_id)

    if definition and (definition.get("structure_type") or "").lower() == "crucible":
        result = action_result(False, "user_structure_id", 0, with_properties=True)
        add_actual_currencies(result, player_object)
        return result
    new_structure_id = 10000 + random.randint(0, 989999)
    now = int(time.time() * 1000)
    new_structure = {
        "user_structure_id": new_structure_id,
        "user_island_id": island_id,
        "island": island_id,
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
        "scale": scale,
        "building_completed": now,
        "date_created": now,
        "last_collection": now,
        "obj_data": 0,
        "obj_end": 0,
    }
    if definition:
        new_structure["level"] = definition.get("level", 1) or 1

        new_structure["book_value"] = definition.get("cost_coins", 0) or 0
        cost_diamonds = definition.get("cost_diamonds", 0) or 0
        cost_coins = definition.get("cost_coins", 0) or 0
        cost_relics = definition.get("cost_relics", 0) or 0
        cost_keys = definition.get("cost_keys", 0) or 0
        cost_starpower = definition.get("cost_starpower", 0) or 0
        cost_eth = definition.get("cost_eth_currency", 0) or 0
        if params.get("starpower_purchase") and cost_starpower > 0:
            player_object["starpower"] = max(
                0, (player_object.get("starpower", 0) or 0) - cost_starpower
            )
        elif cost_diamonds > 0:
            player_object["diamonds"] = max(
                0, (player_object.get("diamonds", 0) or 0) - cost_diamonds
            )
        elif cost_coins > 0:
            player_object["coins"] = max(
                0, (player_object.get("coins", 0) or 0) - cost_coins
            )
        elif cost_relics > 0:
            player_object["relics"] = max(
                0, (player_object.get("relics", 0) or 0) - cost_relics
            )
        elif cost_keys > 0:
            player_object["keys"] = max(
                0, (player_object.get("keys", 0) or 0) - cost_keys
            )
        elif cost_eth > 0:
            player_object["ethereal_currency"] = max(
                0, (player_object.get("ethereal_currency", 0) or 0) - cost_eth
            )
    if island is not None:
        island.setdefault("structures", []).append(new_structure)
        save_player(username, root)
    import msm_monsters

    happy_effects = (
        msm_monsters.recompute_island_happiness(island) if island is not None else []
    )
    result = action_result(True, "user_structure_id", new_structure_id)
    result["user_structure"] = _structure_update(new_structure, "full")
    result["monster_happy_effects"] = happy_effects
    result["properties"] = create_player_properties(player_object)
    add_actual_currencies(result, player_object)
    return result


def _properties_with_inventory(player_object):
    properties = create_player_properties(player_object)
    inventory = player_object.get("inventory")
    items = inventory.get("items") if isinstance(inventory, dict) else inventory
    properties.append({"items": items if isinstance(items, list) else []})
    return properties


AWAKENER_STRUCTURES = {
    1: (801, 6, 31),
    2: (814, 9, 30),
    3: (829, 6, 31),
    4: (847, 6, 31),
    5: (855, 6, 31),
}


def backfill_awakener_structures(island):
    catalog_id = island.get("island", 0)
    island_type = island.get("island_type", island.get("type", catalog_id))
    if catalog_id != island_type:
        awakener_ids = {sid for sid, _, _ in AWAKENER_STRUCTURES.values()}
        structures = island.get("structures")
        if structures:
            island["structures"] = [
                s
                for s in structures
                if s is None or s.get("structure") not in awakener_ids
            ]
        return
    entry = AWAKENER_STRUCTURES.get(island_type)
    if not entry:
        return
    structure_id, pos_x, pos_y = entry
    structures = island.setdefault("structures", [])
    for structure in structures:
        if structure is not None and structure.get("structure") == structure_id:
            structure.setdefault("ext", {})
            return
    now = int(time.time() * 1000)
    new_uid = 10000 + random.randint(0, 989999)
    structures.append(
        {
            "user_structure_id": new_uid,
            "structure": structure_id,
            "structure_id": structure_id,
            "pos_x": pos_x,
            "pos_y": pos_y,
            "col": pos_x,
            "row": pos_y,
            "flip": 0,
            "flipped": 0,
            "muted": 0,
            "in_warehouse": 0,
            "is_upgrading": 0,
            "is_complete": 1,
            "scale": 1.0,
            "building_completed": now,
            "date_created": now,
            "last_collection": now,
            "obj_data": 0,
            "obj_end": 0,
            "ext": {"awakened_state": 0},
        }
    )


def find_awakener_structure(island):
    island_type = island.get("island_type", island.get("type", island.get("island", 0)))
    entry = AWAKENER_STRUCTURES.get(island_type)
    if not entry:
        return None
    structure_id = entry[0]
    for structure in island.get("structures") or []:
        if structure is not None and structure.get("structure") == structure_id:
            return structure
    return None


def update_awakener(username, params):
    titansoul_id = params.get("titansoul_id", 0) or 0
    requested_state = 1 if params.get("awakened_state") else 0
    root, player_object = load_player(username)
    island = None
    if titansoul_id:
        island, monster = find_monster_with_island(player_object, titansoul_id)
        if monster is None:
            return {"success": False}, None
        import msm_monsters

        titansoul = monster.setdefault(
            "titansoul", msm_monsters._default_titansoul_state()
        )
        titansoul["awakened_state"] = requested_state
    if island is None:
        island = find_island(player_object, get_active_island_id(player_object))
    update = None
    structure = find_awakener_structure(island) if island is not None else None
    if structure is not None:
        ext = structure.setdefault("ext", {})
        ext["awakened_state"] = requested_state
        update = _structure_update(structure, "full")
        update["ext"] = ext
    save_player(username, root)
    return {
        "success": True,
        "titansoul_id": SFSLong(titansoul_id),
        "awakened_state": requested_state,
    }, update


def _allowed_island_types(definition):
    if not definition:
        return None
    raw = definition.get("allowed_on_island")
    if not raw:
        return None
    try:
        parsed = json.loads(raw) if isinstance(raw, str) else raw
    except (ValueError, TypeError):
        return None
    if not isinstance(parsed, list) or not parsed:
        return None
    return set(parsed)


def buy_tile(username, params):
    pos_x = params.get("pos_x", params.get("col", 0)) or 0
    pos_y = params.get("pos_y", params.get("row", 0)) or 0
    flip = params.get("flip", params.get("flipped", 0)) or 0
    scale = params.get("scale", 1.0) or 1.0
    structure_id = (
        params.get("structure_id", params.get("structure", params.get("id", 0))) or 0
    )
    root, player_object = load_player(username)
    island_id = get_active_island_id(player_object)
    island = find_island(player_object, island_id)
    island_type = (
        island.get("island_type", island.get("island", max(1, island_id - 1000)))
        if island
        else max(1, island_id - 1000)
    )
    if island_type >= 1000 and island_id >= 1000:
        island_type = island_id - 1000
    definition = get_structure_definition(structure_id)
    allowed = _allowed_island_types(definition)
    if allowed and island_type not in allowed:
        for candidate in player_object.get("islands") or []:
            candidate_type = (
                candidate.get(
                    "island_type", candidate.get("type", candidate.get("island"))
                )
                if candidate is not None
                else None
            )
            if candidate_type in allowed:
                island = candidate
                island_id = candidate.get("user_island_id", island_id)
                island_type = candidate_type
                break
        else:
            return {
                "success": False,
                "tile": 0,
                "structure_id": structure_id,
                "properties": _properties_with_inventory(player_object),
            }
    new_tile_id = 10000 + random.randint(0, 989999)
    now = int(time.time() * 1000)
    new_structure = {
        "user_structure_id": new_tile_id,
        "user_island_id": island_id,
        "island": island_id,
        "island_type": island_type,
        "book_value": 0,
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
        "scale": scale,
        "building_completed": now,
        "date_created": now,
        "last_collection": now,
        "obj_data": 0,
        "obj_end": 0,
    }
    if definition:
        new_structure["level"] = definition.get("level", 1) or 1
        cost_coins = definition.get("cost_coins", 0) or 0
        cost_diamonds = definition.get("cost_diamonds", 0) or 0
        cost_relics = definition.get("cost_relics", 0) or 0
        cost_keys = definition.get("cost_keys", 0) or 0
        cost_starpower = definition.get("cost_starpower", 0) or 0
        cost_eth = definition.get("cost_eth_currency", 0) or 0
        if params.get("starpower_purchase") and cost_starpower > 0:
            player_object["starpower"] = max(
                0, (player_object.get("starpower", 0) or 0) - cost_starpower
            )
        elif cost_diamonds > 0:
            player_object["diamonds"] = max(
                0, (player_object.get("diamonds", 0) or 0) - cost_diamonds
            )
        elif cost_coins > 0:
            player_object["coins"] = max(
                0, (player_object.get("coins", 0) or 0) - cost_coins
            )
        elif cost_relics > 0:
            player_object["relics"] = max(
                0, (player_object.get("relics", 0) or 0) - cost_relics
            )
        elif cost_keys > 0:
            player_object["keys"] = max(
                0, (player_object.get("keys", 0) or 0) - cost_keys
            )
        elif cost_eth > 0:
            player_object["ethereal_currency"] = max(
                0, (player_object.get("ethereal_currency", 0) or 0) - cost_eth
            )
    if island is not None:
        save_player(username, root)
    result = {
        "success": True,
        "tile": 1315679,
        "structure_id": structure_id,
        "properties": _properties_with_inventory(player_object),
    }
    return result


def save_paintstate(username, params):

    tiles = params.get("t") or params.get("tiles") or {}
    root, player_object = load_player(username)
    island_id = get_active_island_id(player_object)
    island = find_island(player_object, island_id)
    if island is not None and isinstance(tiles, dict):
        island.pop("paint_state", None)
        stored = {}
        for key, value in tiles.items():
            if value in (None, "", [], {}):
                continue
            stored[str(key)] = value
        island["tiles"] = stored
        save_player(username, root)
    result = {
        "tiles": tiles,
        "success": True,
        "properties": _properties_with_inventory(player_object),
    }
    return result


def _collected_structure_update(structure, player_object):
    properties = [
        {"last_collection": SFSLong(structure.get("last_collection", 0) or 0)}
    ]
    properties.extend(create_player_properties(player_object))
    return {
        "user_structure_id": SFSLong(structure.get("user_structure_id", 0)),
        "properties": properties,
    }


def store_structure(username, params):
    structure_id = params.get("user_structure_id", params.get("structure_id", 0)) or 0
    root, player_object = load_player(username)
    _, structure = (
        find_island_by_structure(player_object, structure_id)
        if structure_id
        else (None, None)
    )
    if structure is not None:
        structure["in_warehouse"] = 1
        structure["occupied"] = False
        save_player(username, root)
    return {
        "success": structure is not None,
        "user_structure_id": SFSLong(structure_id),
    }


def unstore_structure(username, params):
    structure_id = params.get("user_structure_id", params.get("structure_id", 0)) or 0
    root, player_object = load_player(username)
    _, structure = (
        find_island_by_structure(player_object, structure_id)
        if structure_id
        else (None, None)
    )
    if structure is not None:
        structure["in_warehouse"] = 0
        pos_x = params.get("pos_x", structure.get("pos_x", 0))
        pos_y = params.get("pos_y", structure.get("pos_y", 0))
        flip = params.get("flip", structure.get("flip", 0))
        structure["pos_x"] = pos_x
        structure["pos_y"] = pos_y
        structure["col"] = pos_x
        structure["row"] = pos_y
        structure["flip"] = flip
        structure["flipped"] = flip
        save_player(username, root)
    return {
        "success": structure is not None,
        "user_structure_id": SFSLong(structure_id),
    }


def _mine_cooldown_ms(structure):
    definition = get_structure_definition(structure.get("structure", 0)) or {}
    extra = definition.get("extra") or {}
    return max(1, int(extra.get("time", 720) or 720)) * 60000


def _find_collectable_mine(player_object):
    island = find_island(player_object, get_active_island_id(player_object))
    if island is None:
        return None
    now = int(time.time() * 1000)
    fallback = None
    for structure in island.get("structures") or []:
        if structure is None:
            continue
        definition = get_structure_definition(structure.get("structure", 0)) or {}
        if (definition.get("structure_type") or "").lower() != "mine":
            continue
        if fallback is None:
            fallback = structure
        last_collection = structure.get("last_collection", 0) or 0
        if last_collection <= 0 or now >= last_collection + _mine_cooldown_ms(
            structure
        ):
            return structure
    return fallback


def collect_mine(username, params):
    structure_id = params.get("user_structure_id", params.get("structure_id", 0)) or 0
    root, player_object = load_player(username)
    _, structure = (
        find_island_by_structure(player_object, structure_id)
        if structure_id
        else (None, None)
    )
    if structure is None:
        structure = _find_collectable_mine(player_object)
    if structure is None:
        return {"success": False}, None
    now = int(time.time() * 1000)
    definition = get_structure_definition(structure.get("structure", 0)) or {}
    extra = definition.get("extra") or {}
    payout = max(1, int(extra.get("diamonds", 1) or 1))
    cooldown_seconds = max(1, int(extra.get("time", 720) or 720)) * 60
    last_collection = structure.get("last_collection", 0) or 0
    if last_collection > 0 and now < last_collection + cooldown_seconds * 1000:
        return {"success": False, "message": "Mine is not ready yet"}, None
    diamonds = (player_object.get("diamonds", 0) or 0) + payout
    player_object["diamonds"] = diamonds
    player_object["diamonds_actual"] = diamonds
    structure["last_collection"] = now
    save_player(username, root)
    return {"success": True}, _collected_structure_update(structure, player_object)


def collect_structure(username, params):
    structure_id = params.get("user_structure_id", 0) or 0
    root, player_object = load_player(username)
    _, structure = (
        find_island_by_structure(player_object, structure_id)
        if structure_id
        else (None, None)
    )
    if structure is None:
        return {"success": False, "message": "Structure not found"}, None
    payout = structure.get("obj_data", 0) or 0
    if payout > 0:
        if structure.get("structure", 0) == 801:
            player_object["diamonds"] = (player_object.get("diamonds", 0) or 0) + payout
        else:
            player_object["coins"] = (player_object.get("coins", 0) or 0) + payout
    now = int(time.time() * 1000)
    structure["obj_data"] = 0
    structure["last_collection"] = now
    structure["last_collected"] = now
    save_player(username, root)
    result = action_result(True, "user_structure_id", structure_id)
    result["collected_coins"] = payout
    result["coins"] = payout
    result["properties"] = create_player_properties(player_object)
    add_actual_currencies(result, player_object)
    return result, _collected_structure_update(structure, player_object)


def start_baking(username, params):
    structure_id = params.get("user_structure_id", 0)
    food_id = params.get("food_id", params.get("food_option_id", 0))
    root, player_object = load_player(username)
    island, structure = _locate(player_object, structure_id)
    if structure is None:
        return action_result(
            False, "user_structure_id", structure_id, with_properties=True
        )
    food = get_bakery_food(food_id)
    if food is None:
        return action_result(
            False, "user_structure_id", structure_id, with_properties=True
        )
    now = int(time.time() * 1000)
    finish = now + int(food.get("time", 0) or 0) * 1000
    cost = int(food.get("cost", 0) or 0)
    player_object["coins"] = max(0, (player_object.get("coins", 0) or 0) - cost)
    structure["obj_data"] = food_id
    structure["obj_end"] = finish
    structure["num_bakes"] = structure.get("num_bakes", 0) + 1
    structure["building_completed"] = finish
    structure["finishing_time"] = finish
    structure["last_food_option_id"] = food_id
    player_object["last_rebake_structure_id"] = structure_id
    player_object["last_rebake_food_option_id"] = food_id
    properties = create_player_properties(player_object)
    save_player(username, root)
    result = action_result(True, "user_structure_id", structure_id)
    result["food_option_id"] = food_id
    result["user_baking"] = {
        "user_baking_id": SFSLong(structure_id),
        "user_structure": SFSLong(structure_id),
        "island": SFSLong(island.get("user_island_id", 0) if island else 0),
        "food_option_id": food_id,
        "food_count": food.get("food", 0),
        "started_at": SFSLong(now),
        "finished_at": SFSLong(finish),
    }
    result["properties"] = properties
    add_actual_currencies(result, player_object)
    return result


def start_rebake(username, params):
    root, player_object = load_player(username)
    structure_id = (
        params.get("user_structure_id")
        or params.get("user_baking_id")
        or player_object.get("last_rebake_structure_id", 0)
    )
    food_id = (
        params.get("food_id")
        or params.get("food_option_id")
        or player_object.get("last_rebake_food_option_id", 0)
    )
    island = None
    structure = None
    if structure_id:
        island, structure = _locate(player_object, structure_id)
    if structure is None or not food_id:
        for candidate_island in player_object.get("islands") or []:
            for candidate in candidate_island.get("structures") or []:
                candidate_food = candidate.get("last_food_option_id")
                if candidate_food:
                    island = candidate_island
                    structure = candidate
                    structure_id = candidate.get("user_structure_id", 0)
                    food_id = candidate_food
                    break
            if structure is not None:
                break
    if structure is None or not food_id:
        return action_result(
            False, "user_structure_id", structure_id or 0, with_properties=True
        )
    params = dict(params)
    params["user_structure_id"] = structure_id
    params["food_option_id"] = food_id
    result = start_baking(username, params)
    if not isinstance(result, dict) or not result.get("success"):
        return result
    root, player_object = load_player(username)
    _island, structure = _locate(player_object, structure_id)
    frames = [("gs_start_rebake", result), ("gs_start_baking", result)]
    if structure is not None:
        frames.append(("gs_update_structure", _structure_update(structure, "full")))
    return frames


def speed_up_baking(username, params):
    structure_id = params.get("user_structure_id", params.get("user_baking_id", 0))
    root, player_object = load_player(username)
    island, structure = _locate(player_object, structure_id)
    if structure is None:
        return action_result(
            False, "user_baking_id", structure_id, with_properties=True
        )
    finished_at = int(time.time() * 1000)
    remaining = (
        structure.get("dish_harmonizer_complete_on", finished_at) or finished_at
    ) - finished_at
    _charge_speedup(player_object, remaining)
    structure["dish_harmonizer_complete_on"] = finished_at
    save_player(username, root)
    result = action_result(True, "user_baking_id", structure_id)
    result["user_structure_id"] = SFSLong(structure_id)
    result["finished_at"] = SFSLong(finished_at)
    result["finishing_time"] = SFSLong(finished_at)
    result["obj_end"] = SFSLong(finished_at)
    result["building_completed"] = SFSLong(finished_at)
    result["properties"] = create_player_properties(player_object)
    add_actual_currencies(result, player_object)
    return result


ETHEREAL_EGGCUP_STRUCTURE_ID = 1028
_DISH_HARMONIZER_NICKNAMES = [
    "Umo",
    "Uom",
    "Fou",
    "Zeb",
    "Kip",
    "Lom",
    "Naf",
    "Sio",
    "Reo",
    "Taj",
]
DISH_HARMONIZER_RARE_CHANCE = 0.1
_rare_map_cache = None


def _rare_id_for(common_id):
    global _rare_map_cache
    if _rare_map_cache is None:
        from msm_store import load_db_json

        data = load_db_json("gs_rare_monster_data") or {}
        _rare_map_cache = {
            r["common_id"]: r["rare_id"]
            for r in data.get("rare_monster_data") or []
            if r.get("can_rarify")
        }
    return _rare_map_cache.get(common_id)


def _monster_genes(monster_id):
    return str((get_monster_definition(monster_id) or {}).get("genes") or "")


def _grant_num(num_genes):
    if num_genes >= 4:
        return get_user_game_setting_int(
            "USER_DISH_HARMONIZER_TARGET_GRANT_NUM_PRIMORDIAL", 28
        )
    return get_user_game_setting_int(
        f"USER_DISH_HARMONIZER_TARGET_GRANT_NUM_{num_genes }_GENE",
        6 if num_genes == 2 else 9,
    )


def _pool_for(definition, num_genes):
    return [
        m
        for m in definition.get("primordial_requirements") or []
        if len(_monster_genes(m)) == num_genes
    ]


def _target_state(structure):
    state = structure.get("dish_harmonizer_target_state")
    if not isinstance(state, dict):
        state = {}
        structure["dish_harmonizer_target_state"] = state
    return state


def ensure_dish_harmonizer_targets(island, structure):
    definition = (
        get_ethereal_islet_definition(
            island.get("island", 0) if island is not None else 0
        )
        or {}
    )
    state = _target_state(structure)
    for g in (2, 3):
        key = str(g)
        pool = _pool_for(definition, g)
        entry = state.get(key)
        if not pool:
            state.pop(key, None)
            continue
        if not isinstance(entry, dict) or entry.get("t") not in pool:
            state[key] = {"t": random.choice(pool), "c": 0}
    return state


def _target_list(structure):
    state = _target_state(structure)
    return [
        {"c": int(state[str(g)].get("c", 0) or 0), "t": state[str(g)]["t"], "g": g}
        for g in (2, 3)
        if isinstance(state.get(str(g)), dict) and state[str(g)].get("t")
    ]


def _dish_harmonizer_gene_inventory(player_object):
    genes = player_object.get("attuner_genes") or {}
    return [{"g": g, "n": n} for g, n in genes.items() if n]


def _pick_results(definition, structure):
    primary = definition.get("primary_gene", "")
    state = _target_state(structure)
    pool = [
        m
        for m in definition.get("primordial_requirements") or []
        if len(_monster_genes(m)) in (2, 3)
    ]
    if not pool:
        return []
    chosen = []
    for g in (2, 3):
        entry = state.get(str(g))
        if (
            isinstance(entry, dict)
            and int(entry.get("c", 0) or 0) >= _grant_num(g)
            and entry.get("t") not in chosen
        ):
            chosen.append(entry["t"])
    chosen = chosen[:2]
    rest = [m for m in pool if m not in chosen]
    random.shuffle(rest)
    while len(chosen) < 2 and rest:
        chosen.append(rest.pop())
    results = []
    for i, base in enumerate(chosen):
        species = base
        rare = _rare_id_for(base)
        if rare and random.random() < DISH_HARMONIZER_RARE_CHANCE:
            species = rare
        counts = {}
        for ch in _monster_genes(base):
            if ch != primary:
                counts[ch] = counts.get(ch, 0) + 1
        results.append(
            {
                "t": species,
                "_b": base,
                "_c": [{"g": ch, "n": n} for ch, n in counts.items()],
                "_i": i,
                "_n": random.choice(_DISH_HARMONIZER_NICKNAMES),
            }
        )
    return results


def _apply_hits(structure, results):
    state = _target_state(structure)
    hits = []
    for r in results:
        g = len(_monster_genes(r.get("_b", 0)))
        entry = state.get(str(g))
        if isinstance(entry, dict) and entry.get("t") == r.get("_b"):
            entry["c"] = min(_grant_num(g), int(entry.get("c", 0) or 0) + 1)
            hits.append({"c": entry["c"], "g": g})
    return hits


def dish_harmonizer_wire_data(player_object, structure):
    targets = _target_list(structure)
    results = structure.get("dish_harmonizer_targets") or []
    claimed = set(structure.get("dish_harmonizer_claimed") or [])
    pending = [r for r in results if r.get("_i") not in claimed]
    if not targets and not pending:
        return None
    complete_on = int(structure.get("dish_harmonizer_complete_on", 0) or 0)
    started_on = int(structure.get("dish_harmonizer_started_on", 0) or 0)
    data = {
        "genes": _dish_harmonizer_gene_inventory(player_object),
        "started_on": SFSLong(started_on if pending else 0),
        "complete_on": SFSLong(complete_on if pending else 0),
        "time_required": (
            max(0, complete_on - started_on) if pending and started_on else 0
        ),
        "targets": targets,
        "structure": SFSLong(structure.get("user_structure_id", 0)),
    }
    if pending:
        data["target_results"] = list(structure.get("dish_harmonizer_hits") or [])
        monster_results = []
        for r in pending:
            entry = {"t": r.get("t", 0), "i": r.get("_i", 0), "n": r.get("_n", "")}
            if r.get("_c"):
                entry["c"] = r["_c"]
            monster_results.append(entry)
        data["monster_results"] = monster_results
    return data


def _clear_dish_harmonizer_state(structure):
    for key in (
        "dish_harmonizer_targets",
        "dish_harmonizer_claimed",
        "dish_harmonizer_started_on",
        "dish_harmonizer_complete_on",
        "dish_harmonizer_hits",
    ):
        structure.pop(key, None)


def _dish_reply(player_object, structure, structure_id):
    data = dish_harmonizer_wire_data(player_object, structure)
    if data is None:
        data = {
            "genes": _dish_harmonizer_gene_inventory(player_object),
            "started_on": SFSLong(0),
            "complete_on": SFSLong(0),
            "time_required": 0,
            "targets": [],
            "structure": SFSLong(structure_id),
        }
    return data


def start_dish_harmonizing(username, params):
    structure_id = params.get("user_structure_id", 0)
    used_monster_id = params.get("user_monster_id", 0) or 0
    genes = params.get("genes") or []
    root, player_object = load_player(username)
    island, structure = _locate(player_object, structure_id)
    if structure is None:
        return action_result(
            False, "user_structure_id", structure_id, with_properties=True
        )
    used_island = None
    used_monster = None
    if used_monster_id:
        used_island, used_monster = find_monster_with_island(
            player_object, used_monster_id, island
        )
        if used_monster is None:
            return action_result(
                False, "user_structure_id", structure_id, with_properties=True
            )
    used_definition = (
        get_monster_definition(used_monster.get("monster", 0))
        if used_monster is not None
        else None
    )
    used_genes = used_definition.get("genes") if used_definition is not None else ""
    num_genes = (
        len(genes)
        if isinstance(genes, list) and genes
        else len(used_genes) if used_genes else int(params.get("num_genes", 2) or 2)
    )
    num_genes = min(3, max(1, num_genes))
    island_id = island.get("island", 0) if island is not None else 0
    definition = get_ethereal_islet_definition(island_id) or {}
    cost = int(definition.get(f"target_cost_{num_genes }_gene", 0) or 0)
    time_per_gene = int(definition.get("dish_harmonizing_time_per_gene", 0) or 0)
    base_time = int(definition.get("dish_harmonizing_base_time", 0) or 0)
    now = int(time.time() * 1000)
    duration_ms = (base_time + time_per_gene * num_genes) * 1000
    finish = now + duration_ms
    if msm_toggles.is_enabled("functioning_currencies"):
        player_object["ethereal_currency"] = max(
            0, (player_object.get("ethereal_currency", 0) or 0) - cost
        )
    ensure_dish_harmonizer_targets(island, structure)
    results = _pick_results(definition, structure)
    structure["dish_harmonizer_hits"] = _apply_hits(structure, results)
    structure["dish_harmonizer_complete_on"] = finish
    structure["dish_harmonizer_targets"] = results
    structure["dish_harmonizer_claimed"] = []
    structure["dish_harmonizer_started_on"] = now
    if used_monster is not None and used_island is not None:
        monsters = used_island.get("monsters") or []
        for i in range(len(monsters) - 1, -1, -1):
            if monsters[i] is used_monster:
                del monsters[i]
                break
    save_player(username, root)
    result = action_result(True, "user_structure_id", structure_id)
    result["user_dish_harmonizer_data"] = _dish_reply(
        player_object, structure, structure_id
    )
    if used_monster_id:
        result["used_monster"] = SFSLong(used_monster_id)
    result["properties"] = create_player_properties(player_object)
    add_actual_currencies(result, player_object)
    return result, _structure_update(structure, "full")


def update_dish_harmonizer_target(username, params):
    structure_id = (
        params.get("user_structure_id", 0) or params.get("structure_id", 0) or 0
    )
    root, player_object = load_player(username)
    island, structure = _locate(player_object, structure_id)
    if structure is None:
        return (
            action_result(
                False, "user_structure_id", structure_id, with_properties=True
            ),
            {},
        )
    definition = (
        get_ethereal_islet_definition(
            island.get("island", 0) if island is not None else 0
        )
        or {}
    )
    state = ensure_dish_harmonizer_targets(island, structure)
    monster = params.get("monster")
    try:
        num_genes = int(params.get("num_genes", 0) or 0)
    except (TypeError, ValueError):
        num_genes = 0
    if monster and num_genes in (2, 3) and monster in _pool_for(definition, num_genes):
        entry = state.get(str(num_genes))
        if not isinstance(entry, dict) or entry.get("t") != monster:
            state[str(num_genes)] = {"t": monster, "c": 0}
    save_player(username, root)
    result = action_result(True, "user_structure_id", structure_id)
    result["user_dish_harmonizer_data"] = _dish_reply(
        player_object, structure, structure_id
    )
    result["properties"] = create_player_properties(player_object)
    add_actual_currencies(result, player_object)
    return result, _structure_update(structure, "full")


def speed_up_dish_harmonizing(username, params):
    structure_id = params.get("user_structure_id", 0)
    root, player_object = load_player(username)
    island, structure = _locate(player_object, structure_id)
    if structure is None:
        return action_result(
            False, "user_structure_id", structure_id, with_properties=True
        )
    finished_at = int(time.time() * 1000)
    remaining = (
        structure.get("dish_harmonizer_complete_on", finished_at) or finished_at
    ) - finished_at
    _charge_speedup(player_object, remaining)
    structure["dish_harmonizer_complete_on"] = finished_at
    save_player(username, root)
    result = action_result(True, "user_structure_id", structure_id)
    result["finished_at"] = SFSLong(finished_at)
    result["properties"] = create_player_properties(player_object)
    add_actual_currencies(result, player_object)
    return result, _structure_update(structure, "full")


def incubate_dish_harmonizer_egg(username, params):
    structure_id = params.get("user_structure_id", 0)
    egg_structure_id = (
        params.get("egg_structure_id", params.get("structure_id", 0)) or 0
    )
    root, player_object = load_player(username)
    island, structure = _locate(player_object, structure_id)
    if structure is None:
        return {"success": False}
    results = structure.get("dish_harmonizer_targets") or []
    claimed = set(structure.get("dish_harmonizer_claimed") or [])
    monster_result_id = params.get("monster_result_id")
    chosen = None
    if monster_result_id is not None:
        chosen = next(
            (
                t
                for t in results
                if t.get("_i") == monster_result_id and t.get("_i") not in claimed
            ),
            None,
        )
    if chosen is None:
        chosen = next((t for t in results if t.get("_i") not in claimed), None)
    monster_id = 0
    nickname = random.choice(_DISH_HARMONIZER_NICKNAMES)
    if chosen is not None:
        monster_id = chosen.get("t", 0)
        nickname = chosen.get("_n", nickname)
        claimed.add(chosen.get("_i"))
    structure["dish_harmonizer_claimed"] = list(claimed)
    user_egg = None
    if monster_id and island is not None:
        from msm_monsters import place_egg

        user_egg, holder = place_egg(
            player_object,
            island,
            monster_id,
            "dish_harmonizer",
            egg_structure_id,
            previous_name=nickname,
            ready=True,
        )
        if user_egg is None:
            structure["dish_harmonizer_claimed"] = [
                v for v in claimed if chosen is None or v != chosen.get("_i")
            ]
            return {
                "success": False,
                "error": "NO_AVAILABLE_EGG_HOLDER",
            }, _structure_update(structure, "full")
    if chosen is not None and chosen.get("_b"):
        base = chosen["_b"]
        g = len(_monster_genes(base))
        state = _target_state(structure)
        entry = state.get(str(g))
        if isinstance(entry, dict) and entry.get("t") == base:
            definition = (
                get_ethereal_islet_definition(
                    island.get("island", 0) if island is not None else 0
                )
                or {}
            )
            pool = _pool_for(definition, g)
            alternatives = [m for m in pool if m != base] or pool
            state[str(g)] = {
                "t": random.choice(alternatives) if alternatives else base,
                "c": 0,
            }
    if results and len(claimed) >= len(results):
        _clear_dish_harmonizer_state(structure)
    save_player(username, root)
    result = {
        "success": True,
        "user_structure_id": SFSLong(structure_id),
        "user_dish_harmonizer_data": _dish_reply(
            player_object, structure, structure_id
        ),
    }
    if user_egg is not None:
        result["user_egg"] = user_egg
    return result, _structure_update(structure, "full")


def finish_dish_harmonizing(username, params):
    structure_id = params.get("user_structure_id", 0)
    root, player_object = load_player(username)
    island, structure = _locate(player_object, structure_id)
    if structure is None:
        return action_result(
            False, "user_structure_id", structure_id, with_properties=True
        )
    island_id = island.get("island", 0) if island is not None else 0
    definition = get_ethereal_islet_definition(island_id) or {}
    monster_id = int(definition.get("primordial", 0) or 0)
    _clear_dish_harmonizer_state(structure)
    user_egg = None
    if monster_id and island is not None:
        from msm_monsters import place_egg

        user_egg, _holder = place_egg(
            player_object,
            island,
            monster_id,
            "dish_harmonizer_finish",
            structure.get("user_structure_id", 0),
            ready=True,
        )
        if user_egg is None:
            return {
                "success": False,
                "error": "NO_AVAILABLE_EGG_HOLDER",
            }, _structure_update(structure, "full")
    save_player(username, root)
    result = action_result(True, "user_structure_id", structure_id)
    if user_egg is not None:
        result["user_egg"] = user_egg
    result["properties"] = create_player_properties(player_object)
    add_actual_currencies(result, player_object)
    return result, _structure_update(structure, "full")


def finish_baking(username, params):
    structure_id = params.get("user_structure_id", params.get("user_baking_id", 0))
    root, player_object = load_player(username)
    island, structure = _locate(player_object, structure_id)
    if structure is None:
        return action_result(
            False, "user_baking_id", structure_id, with_properties=True
        )
    food_id = structure.get("obj_data", 0)
    food = get_bakery_food(food_id)

    quantity = max(0, (food.get("food", 0) if food else 0) or 0)
    player_object["food"] = (player_object.get("food", 0) or 0) + quantity
    structure["obj_data"] = 0
    structure["obj_end"] = 0
    structure["building_completed"] = 0
    structure["finishing_time"] = 0

    properties = create_player_properties(player_object)
    save_player(username, root)
    result = action_result(True, "user_baking_id", structure_id)
    result["properties"] = properties
    return result
