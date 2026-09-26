import json
import logging

from msm_box import boxed_eggs, is_awakened_box_monster, is_box_monster_entity
from msm_gamedata import (
    get_monster_definition,
    get_monster_id_for_entity_id,
    get_structure_definition,
)
from msm_playerdata import (
    create_player_properties,
    find_island,
    island_type_of,
    load_player,
    save_player,
)
from msm_rewards import _add_currency
from msm_store import load_db_json

logger = logging.getLogger("msm.quests")

_cache = {}


def _safe_int(value, default=0):
    try:
        return int(value)
    except (TypeError, ValueError, OverflowError):
        return default


def _catalog():
    if "defs" not in _cache:
        data = load_db_json("db_quests") or {}
        defs = {}
        by_name = {}
        for definition in data.get("quest_definitions") or []:
            if not isinstance(definition, dict) or "id" not in definition:
                continue
            qid = _safe_int(definition["id"])
            defs[qid] = definition
            name = definition.get("name")
            if name:
                by_name[name] = qid
        _cache["defs"] = defs
        _cache["by_name"] = by_name
    return _cache["defs"], _cache["by_name"]


def _prereq_map(defs):

    parents = {}
    for qid, definition in defs.items():
        for nxt in definition.get("next") or []:
            if isinstance(nxt, dict) and nxt.get("quest"):
                parents.setdefault(nxt["quest"], []).append(qid)
    return parents


def _gated_names(parents):
    return set(parents.keys())


def _quest_state(player_object):
    state = player_object.get("quest_state")
    if not isinstance(state, dict):
        state = {}
        player_object["quest_state"] = state
    return state


def _quest_meta(player_object):

    meta = player_object.get("quest_meta")
    if not isinstance(meta, dict):
        meta = {}
        player_object["quest_meta"] = meta
    return meta


def _is_complete(status_str):

    s = (status_str or "").strip()
    if s == "true":
        return True
    if s == "false":
        return False
    try:
        parsed = json.loads(s)
    except (TypeError, ValueError):
        return False
    if isinstance(parsed, list) and parsed:
        return all(bool(v) for v in parsed)
    return bool(parsed)


def _islands_matching(player_object, on_island):
    if on_island is None:
        return list(player_object.get("islands") or [])
    return [
        isl
        for isl in (player_object.get("islands") or [])
        if isl is not None and island_type_of(isl) == _safe_int(on_island)
    ]


def _object_ids(value):
    raw = value if isinstance(value, list) else [value]
    ids = set()
    for v in raw:
        vid = _safe_int(v)
        if vid:
            ids.add(vid)
    return ids


def _monster_entity_ids(monster):
    if not isinstance(monster, dict):
        return set()
    monster_id = _safe_int(monster.get("monster"))
    if not monster_id:
        return set()
    entity_id = (get_monster_definition(monster_id) or {}).get("entity_id")
    if entity_id is None:
        return set()
    return {_safe_int(entity_id)}


def _monster_is_placed_and_ready(monster):
    if not isinstance(monster, dict):
        return False
    from msm_box import is_box_monster_entity, is_awakened_box_monster

    definition = get_monster_definition(_safe_int(monster.get("monster")))
    if is_box_monster_entity(definition) and not is_awakened_box_monster(monster):
        return False
    return True


def _structure_ids(structure):
    if not isinstance(structure, dict):
        return set()
    structure_id = _safe_int(
        structure.get("structure") or structure.get("structure_id")
    )
    if not structure_id:
        return set()
    entity_id = (get_structure_definition(structure_id) or {}).get("entity_id")
    if entity_id is None:
        return set()
    return {_safe_int(entity_id)}


def _goal_threshold(goal, key):
    raw = goal.get(key)
    if isinstance(raw, dict):
        return _safe_int(raw.get(key)), (raw.get("eval") or ">=")
    return _safe_int(raw), (goal.get("eval") or ">=")


def _goal_compare(value, operator, threshold):
    if operator == ">":
        return value > threshold
    if operator == "<":
        return value < threshold
    if operator == "<=":
        return value <= threshold
    if operator == "==":
        return value == threshold
    return value >= threshold


def _titansoul_states(islands):
    states = []
    for isl in islands:
        for monster in isl.get("monsters") or []:
            if monster is None:
                continue
            state = monster.get("titansoul")
            if isinstance(state, dict):
                states.append(state)
    return states


def _soul_link_count(state, rarity):
    links = state.get("soul_links")
    if not isinstance(links, list):
        return 0
    total = 0
    for link in links:
        if isinstance(link, dict):
            link_id = _safe_int(
                link.get("monster") or link.get("monster_id") or link.get("id")
            )
        else:
            link_id = _safe_int(link)
        if not link_id:
            continue
        name = (
            (get_monster_definition(link_id) or {}).get("common_name") or ""
        ).upper()
        if rarity == "epic":
            matched = "EPIC" in name
        elif rarity == "rare":
            matched = "RARE" in name
        else:
            matched = "EPIC" not in name and "RARE" not in name
        if matched:
            total += 1
    return total


_titansoul_levels_cache = None


def _titansoul_level_rows():
    global _titansoul_levels_cache
    if _titansoul_levels_cache is None:
        data = load_db_json("db_titansoul_levels") or {}
        rows = [
            r for r in (data.get("titansoul_level_data") or []) if isinstance(r, dict)
        ]
        _titansoul_levels_cache = sorted(
            rows, key=lambda r: _safe_int(r.get("min_links"))
        )
    return _titansoul_levels_cache


def _titansoul_song_parts(state):
    links = state.get("soul_links")
    num_links = (
        len(links) if isinstance(links, list) else _safe_int(state.get("num_links"))
    )
    song_part = 0
    for row in _titansoul_level_rows():
        if num_links >= _safe_int(row.get("min_links")):
            song_part = max(song_part, _safe_int(row.get("song_part")))
    return song_part


def _titansoul_has_reward(state, reward_type):
    rewards = state.get("rewards")
    if not isinstance(rewards, list):
        return False
    for reward in rewards:
        if isinstance(reward, dict):
            name = str(
                reward.get("type") or reward.get("reward") or reward.get("name") or ""
            ).lower()
        else:
            name = str(reward).lower()
        if reward_type in name:
            return True
    return False


def _goal_satisfied(player_object, goal):
    if not isinstance(goal, dict):
        return False

    if "friends" in goal and isinstance(goal.get("friends"), (int, float)):
        threshold = _safe_int(goal.get("friends"))
        count = len(player_object.get("nps_fake_friends") or [])
        return count >= threshold

    if "island" in goal and "on_island" not in goal:
        target = _safe_int(goal.get("island"))
        return any(
            island_type_of(isl) == target
            for isl in (player_object.get("islands") or [])
            if isl is not None
        )

    on_island = goal.get("on_island")
    islands = _islands_matching(player_object, on_island)

    if "object" in goal:
        wanted = _object_ids(goal.get("object"))
        for isl in islands:
            for monster in isl.get("monsters") or []:
                if (
                    monster is not None
                    and _monster_entity_ids(monster) & wanted
                    and _monster_is_placed_and_ready(monster)
                ):
                    return True
            for structure in isl.get("structures") or []:
                if _structure_ids(structure) & wanted:
                    return True
        return False

    if "box_egg" in goal:
        wanted = _safe_int(goal.get("box_egg"))
        for isl in islands:
            for monster in isl.get("monsters") or []:
                if monster is None:
                    continue
                if wanted in boxed_eggs(monster):
                    return True
        return False

    if "activate_box" in goal:
        for isl in islands:
            for monster in isl.get("monsters") or []:
                if monster is None:
                    continue
                definition = get_monster_definition(monster.get("monster", 0))
                if is_box_monster_entity(definition) and is_awakened_box_monster(
                    monster
                ):
                    return True
        return False

    if "monster_left" in goal and "monster_right" in goal:
        left_id = _safe_int(goal.get("monster_left"))
        right_id = _safe_int(goal.get("monster_right"))
        for isl in islands:
            for record in isl.get("breeding") or []:
                if not isinstance(record, dict):
                    continue
                if (
                    _safe_int(record.get("monster_1")) == left_id
                    and _safe_int(record.get("monster_2")) == right_id
                ):
                    return True
        return False

    if "start_clubbox" in goal or "go_to_clubbox" in goal:
        return bool(
            player_object.get("clubboxes")
            or _safe_int(player_object.get("last_clubbox")) > 0
        )

    if "move_object" in goal:
        wanted = _object_ids(goal.get("move_object"))
        for isl in islands:
            for monster in isl.get("monsters") or []:
                if (
                    monster is not None
                    and _monster_entity_ids(monster) & wanted
                    and _monster_is_placed_and_ready(monster)
                ):
                    return True
            for structure in isl.get("structures") or []:
                if _structure_ids(structure) & wanted:
                    return True
        return False

    for rarity in ("common", "rare", "epic"):
        key = f"soul_link_{rarity }"
        if key in goal:
            threshold, operator = _goal_threshold(goal, key)
            for state in _titansoul_states(islands):
                if _goal_compare(_soul_link_count(state, rarity), operator, threshold):
                    return True
            return False

    if "titansoul_song_part" in goal:
        threshold, operator = _goal_threshold(goal, "titansoul_song_part")
        for state in _titansoul_states(islands):
            if _goal_compare(_titansoul_song_parts(state), operator, threshold):
                return True
        return False

    for key in list(goal):
        if not key.startswith("titansoul_reward_"):
            continue
        reward_type = key[len("titansoul_reward_") :]
        for state in _titansoul_states(islands):
            if _titansoul_has_reward(state, reward_type):
                return True
        return False

    if "monster_level" in goal:
        threshold = _safe_int(goal.get("monster_level"))
        eval_op = goal.get("eval", ">=")
        for isl in player_object.get("islands") or []:
            if isl is None:
                continue
            for monster in isl.get("monsters") or []:
                if monster is None:
                    continue
                level = _safe_int(monster.get("level"))
                if eval_op == ">=" and level >= threshold:
                    return True
                if eval_op == "==" and level == threshold:
                    return True
        return False

    return False


def _status_string(flags, completed):
    if completed:
        return "true"
    return json.dumps(flags, separators=(",", ":"))


def _quest_progress(player_object, definition):
    goals = definition.get("goals") or []
    if not goals:
        return [], False
    flags = [_goal_satisfied(player_object, goal) for goal in goals]
    combine = (definition.get("type") or "AND").upper()
    completed = any(flags) if combine == "OR" else all(flags)
    return flags, completed


def advance_quests(username):
    root, player_object = load_player(username)
    defs, _by_name = _catalog()
    if not defs:
        return []
    parents = _prereq_map(defs)
    state = _quest_state(player_object)
    meta = _quest_meta(player_object)
    user_id = player_object.get("user_id") or player_object.get("user") or 0

    changed_results = []
    dirty = False
    for qid_str, entry in list(state.items()):
        if not isinstance(entry, dict):
            continue
        qid = _safe_int(qid_str)
        definition = defs.get(qid)
        if definition is None:
            continue
        if entry.get("completed"):
            if entry.get("collected"):
                continue
            flags, completed = _quest_progress(player_object, definition)
            if not flags:
                continue
            status_str = _status_string(flags, completed)
            if status_str == entry.get("status"):
                continue
            entry["status"] = status_str
            entry["completed"] = completed
            dirty = True
            changed_results.append({"quest_id": qid, "status": status_str})
            continue
        flags, completed = _quest_progress(player_object, definition)
        if not flags:
            continue
        status_str = _status_string(flags, completed)
        if status_str == entry.get("status") and completed == bool(
            entry.get("completed")
        ):
            continue
        entry["status"] = status_str
        entry["completed"] = completed
        dirty = True
        changed_results.append({"quest_id": qid, "status": status_str})
        if completed:
            changed_results.extend(
                _unlocked_children(defs, parents, state, qid, user_id)
            )

    if not dirty:
        return []
    meta["event_id"] = _safe_int(meta.get("event_id")) + 1
    save_player(username, root)
    return [("gs_quest", {"result": changed_results, "event_id": meta["event_id"]})]


def _new_record(definition, qid, seq_id, user_id, entry=None):
    goal_count = len(definition.get("goals") or [])
    entry = entry if isinstance(entry, dict) else {}
    status = entry.get("status")
    if not isinstance(status, str) or not status:
        status = json.dumps([False] * goal_count, separators=(",", ":"))
    return {
        "new": 0 if entry.get("seen") else 1,
        "collected": 1 if entry.get("collected") else 0,
        "quest_id": qid,
        "id": qid,
        "user": user_id,
        "status": status,
    }


def _unlocked_children(defs, parents, state, completed_qid, user_id):

    extra = []
    completed_def = defs.get(completed_qid)
    if not completed_def:
        return extra
    child_names = {
        nxt["quest"]
        for nxt in (completed_def.get("next") or [])
        if isinstance(nxt, dict) and nxt.get("quest")
    }
    if not child_names:
        return extra
    by_name = {
        definition.get("name"): (qid, definition) for qid, definition in defs.items()
    }
    for child_name in child_names:
        child = by_name.get(child_name)
        if not child:
            continue
        child_qid, child_def = child
        if str(child_qid) in state:
            continue
        entry = state.setdefault(str(child_qid), {"delivered": True})
        seq_id = len(state)
        extra.append(
            {"new": [_new_record(child_def, child_qid, seq_id, user_id), child_def]}
        )
    return extra


_QUEST_REWARD_ACTUAL_KEYS = {
    "coins": "coins_actual",
    "diamonds": "diamonds_actual",
    "relics": "relics_actual",
    "ethereal_currency": "ethereal_currency_actual",
    "food": "food_actual",
    "starpower": "starpower_actual",
    "xp": "xp",
}


def _collect(username, root, player_object, defs, state, quest_id):
    entry = state.get(str(quest_id))
    if entry is None:
        entry = state.setdefault(str(quest_id), {"delivered": True})

    entry["completed"] = True
    if not _is_complete(entry.get("status")):
        entry["status"] = "true"
    changed_keys = set()
    if not entry.get("collected"):
        definition = defs.get(quest_id) or {}
        rewards = definition.get("rewards") or {}
        for prize_type in ("coins", "diamonds", "relics", "ethereal_currency", "food"):
            amount = _safe_int(rewards.get(prize_type))
            if amount:
                _add_currency(player_object, prize_type, amount)
                changed_keys.add(prize_type)
        starpower = _safe_int(rewards.get("starpower"))
        if starpower:
            player_object["starpower"] = (
                _safe_int(player_object.get("starpower")) + starpower
            )
            changed_keys.add("starpower")
        xp = _safe_int(rewards.get("xp"))
        if xp:
            player_object["xp"] = _safe_int(player_object.get("xp")) + xp
            changed_keys.add("xp")
        entry["collected"] = True
        save_player(username, root)

    actual_keys = {_QUEST_REWARD_ACTUAL_KEYS[k] for k in changed_keys}
    full_properties = {
        list(p.keys())[0]: p for p in create_player_properties(player_object)
    }
    changed_properties = [
        full_properties[k] for k in actual_keys if k in full_properties
    ]
    return {"result": [{"collect": quest_id}]}, changed_properties


def _report_status(
    username,
    root,
    player_object,
    defs,
    parents,
    state,
    meta,
    user_id,
    quest_id,
    status_param,
):

    status_str = (
        status_param if isinstance(status_param, str) else json.dumps(status_param)
    )
    entry = state.setdefault(str(quest_id), {"delivered": True})
    entry["status"] = status_str
    completed = _is_complete(status_str)
    entry["completed"] = completed
    result = [{"quest_id": quest_id, "status": status_str}]
    if completed:
        result.extend(_unlocked_children(defs, parents, state, quest_id, user_id))
    meta["event_id"] = _safe_int(meta.get("event_id")) + 1
    save_player(username, root)
    return {"result": result, "event_id": meta["event_id"]}


def _full_catalog(username, root, player_object, defs, parents, state, meta, user_id):
    gated = _gated_names(parents)
    result = []
    seq = 0
    for qid, definition in defs.items():
        name = definition.get("name")
        if name in gated:
            continue
        entry = state.setdefault(str(qid), {})
        if entry.get("collected"):
            entry["delivered"] = True
            continue
        seq += 1
        already_known = bool(entry.get("delivered"))
        entry["delivered"] = True
        record = _new_record(definition, qid, seq, user_id, entry)
        if already_known:
            record["new"] = 0
        result.append({"new": [record, definition]})
    meta["catalog_sent"] = True
    save_player(username, root)
    return {"result": result, "admin_quest_msg": 0}


def _poll(username, root, player_object, defs, parents, state, meta, user_id):
    gated = _gated_names(parents)
    if not meta.get("catalog_sent"):
        return _full_catalog(
            username, root, player_object, defs, parents, state, meta, user_id
        )

    result = []
    changed = False
    for qid, definition in defs.items():
        if str(qid) in state:
            continue
        name = definition.get("name")
        if name in gated:
            parent_ids = parents.get(name) or []
            if not any(state.get(str(pid), {}).get("completed") for pid in parent_ids):
                continue
        entry = state.setdefault(str(qid), {"delivered": True})
        seq_id = len(state)
        result.append(
            {"new": [_new_record(definition, qid, seq_id, user_id, entry), definition]}
        )
        changed = True
    if changed:
        meta["event_id"] = _safe_int(meta.get("event_id")) + 1
        save_player(username, root)
        return {"result": result, "event_id": meta["event_id"]}
    return {"result": [], "event_id": _safe_int(meta.get("event_id"))}


def gs_quest(username, params):
    root, player_object = load_player(username)
    defs, _by_name = _catalog()
    parents = _prereq_map(defs)
    state = _quest_state(player_object)
    meta = _quest_meta(player_object)
    user_id = player_object.get("user_id") or player_object.get("user") or 0

    quest_id = params.get("quest_id", params.get("id", params.get("quest_claim_id")))
    status_param = params.get("status")
    if quest_id is not None and status_param is not None:
        return _report_status(
            username,
            root,
            player_object,
            defs,
            parents,
            state,
            meta,
            user_id,
            _safe_int(quest_id),
            status_param,
        )

    for collect_key in (
        "collect",
        "quest_claim_id",
        "quest_id",
        "questId",
        "id",
        "claim",
        "claim_id",
        "quest",
    ):
        if collect_key in params:
            return _collect(
                username,
                root,
                player_object,
                defs,
                state,
                _safe_int(params.get(collect_key)),
            )

    batch = params.get("statuses") or params.get("updates") or params.get("quests")
    if isinstance(batch, list) and batch:
        result = []
        last_response = {}
        for item in batch:
            if not isinstance(item, dict):
                continue
            item_qid = item.get("quest_id", item.get("id"))
            item_status = item.get("status")
            if item_qid is None or item_status is None:
                continue
            last_response = _report_status(
                username,
                root,
                player_object,
                defs,
                parents,
                state,
                meta,
                user_id,
                _safe_int(item_qid),
                item_status,
            )
            result.extend(last_response.get("result") or [])
        if result:
            return {"result": result, "event_id": meta.get("event_id", 0)}

    return _full_catalog(
        username, root, player_object, defs, parents, state, meta, user_id
    )


def gs_quest_read(username, params):
    root, player_object = load_player(username)
    defs, _by_name = _catalog()
    parents = _prereq_map(defs)
    state = _quest_state(player_object)
    meta = _quest_meta(player_object)
    quest_id = params.get("quest_id", params.get("id"))
    ids = params.get("quest_ids") if isinstance(params.get("quest_ids"), list) else None
    targets = (
        ids
        if ids
        else (
            [quest_id]
            if quest_id is not None
            else [k for k in state.keys() if not k.startswith("_")]
        )
    )
    for qid in targets:
        entry = state.get(str(_safe_int(qid)))
        if entry is not None:
            entry["seen"] = True
    save_player(username, root)
    user_id = player_object.get("user_id") or player_object.get("user") or 0
    return _poll(username, root, player_object, defs, parents, state, meta, user_id)


def gs_quests_read(username, params):
    return gs_quest_read(username, params)


def gs_quest_event(username, params):
    logger.info("gs_quest_event params=%r", params)
    root, player_object = load_player(username)
    defs, _by_name = _catalog()
    parents = _prereq_map(defs)
    state = _quest_state(player_object)
    meta = _quest_meta(player_object)
    user_id = player_object.get("user_id") or player_object.get("user") or 0
    quest_id = params.get("quest_id", params.get("id", params.get("quest_claim_id")))
    if quest_id is None:
        return _poll(username, root, player_object, defs, parents, state, meta, user_id)
    status_param = params.get("status", "true")
    return _report_status(
        username,
        root,
        player_object,
        defs,
        parents,
        state,
        meta,
        user_id,
        _safe_int(quest_id),
        status_param,
    )


def gs_quest_collect(username, params):
    root, player_object = load_player(username)
    defs, _by_name = _catalog()
    state = _quest_state(player_object)
    for collect_key in (
        "collect",
        "quest_claim_id",
        "quest_id",
        "questId",
        "id",
        "claim",
        "claim_id",
        "quest",
    ):
        if collect_key in params:
            return _collect(
                username,
                root,
                player_object,
                defs,
                state,
                _safe_int(params.get(collect_key)),
            )
    return {"result": []}
