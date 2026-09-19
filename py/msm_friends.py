import copy
import time

def _friends_list(player_object):
    friends = player_object.get("nps_fake_friends")
    return friends if isinstance(friends, list) else []

def find_friend(player_object, user_id):
    for friend in _friends_list(player_object):
        if friend.get("user_id") == user_id:
            return friend
    return None

def light_friend_torch(player_object, user_id):
    friend = find_friend(player_object, user_id)
    if friend is None:
        return False
    friend["litByMe"] = int(friend.get("litByMe", 0) or 0) + 1
    return True

_VISIT_ONLY_FIELDS = (
    "islands", "clubboxes", "tracks", "active_island",
    "owned_island_themes", "active_island_themes",
    "keys", "starpower", "country", "friend_gift",
)

_NPS_ONLY_FIELDS = ("active",)

def friends_wire_list(player_object):
    out = []
    for friend in _friends_list(player_object):
        if not friend.get("active", True):
            continue
        entry = {k: v for k, v in friend.items() if k not in _VISIT_ONLY_FIELDS and k not in _NPS_ONLY_FIELDS}
        entry.setdefault("is_favorite", False)
        out.append(entry)
    return out

def _ensure_starter_island(player_object, friend):
    if friend.get("islands"):
        return
    import msm_islands
    from msm_protocol import SFSLong
    user_island_id = 1000 + 1
    island = {
        "eggs": [], "warp_speed": 1.0, "island": 1,
        "structures": msm_islands.default_island_structures(user_island_id, 1),
        "monsters": [], "dislikes": 0, "likes": 0, "fuzer": [], "baking": [],
        "costumes_owned": [], "breeding": [], "torches": [], "last_player_level": 1,
        "num_torches": 0, "user_island_id": SFSLong(user_island_id), "user": SFSLong(friend.get("user_id", 0)),
        "type": 1, "island_type": 1,
        "tiles": {}, "monsters_sold": "[]", "costume_data": {"costumes": []},
        "last_baked": [], "last_bred": {}, "light_torch_flag": False,
    }
    friend["islands"] = [island]
    friend["active_island"] = user_island_id

def _apply_island_backfills(island):
    import msm_box
    import msm_islands
    import msm_monsters
    msm_monsters.grant_full_book(island)
    msm_monsters.backfill_titansoul_state(island)
    msm_islands.backfill_island_type(island)
    msm_islands.repair_ethereal_structure_positions(island)
    msm_islands.backfill_ethereal_eggcups(island)
    msm_monsters.repair_magical_nexus_layout(island)
    msm_box.repair_underling_box_state(island)

_REAL_FRIEND_ISLAND_KEYS = {
"attuned_critters","attuning","baking","battle","breeding","buyback","costume_data",
"costumes_owned","date_created","dislikes","eggs","evolving","fuguing","fuzer","island",
"last_baked","last_bred","last_player_level","last_synthesis","light_torch_flag","likes",
"mode","monsters","monsters_sold","name","nucleus","num_torches","reattuning","structures",
"synthesis_attempts","synthesis_five_gene_cooldown","synthesizing","tiles","torches","type",
"user","user_island_id","warp_speed",
}
_REAL_FRIEND_MONSTER_KEYS = {
"book_value","box_requirements","boxed_eggs","collected_coins","collection_type","costume",
"egg_timer_start","flip","gi_child_island","gi_child_monster","happiness","has_evolve_flexeggs",
"has_evolve_reqs","in_hotel","island","last_collection","last_feeding","level","monster",
"muted","name","parent_island","parent_monster","pos_x","pos_y","random_underling_collection_min",
"times_fed","underling_collection_happiness","user_monster_id","volume",
}
_REAL_FRIEND_STRUCTURE_KEYS = {
"book_value","building_completed","date_created","ext","flip","in_warehouse","is_complete",
"is_upgrading","island","last_collection","muted","pos_x","pos_y","scale","structure",
"user_structure_id",
}
_REAL_FRIEND_EGG_KEYS = {"costume","hatches_on","island","laid_on","monster","structure","user_egg_id"}
_REAL_FRIEND_BREEDING_KEYS = {
"complete_on","island","monster_1","monster_2","new_monster","started_on","structure","user_breeding_id",
}

def _filtered(entry, allowed_keys):
    if not isinstance(entry, dict):
        return entry
    return {k: v for k, v in entry.items() if k in allowed_keys}

def _known_monster(monster_id):
    import msm_gamedata
    if monster_id is None:
        return False
    return msm_gamedata.get_monster_definition(monster_id) is not None

def _known_structure(structure_id):
    import msm_gamedata
    if structure_id is None:
        return False
    return msm_gamedata.get_structure_definition(structure_id) is not None

def _known_island_type(island_type_id):
    import msm_gamedata
    if island_type_id is None:
        return False
    return msm_gamedata.get_island_definition(island_type_id) is not None

def _sanitize_friend_island(island):
    island["monsters"] = [
        _filtered(m, _REAL_FRIEND_MONSTER_KEYS)
        for m in (island.get("monsters") or [])
        if m is not None and _known_monster(m.get("monster"))
    ]
    island["structures"] = [
        _filtered(s, _REAL_FRIEND_STRUCTURE_KEYS)
        for s in (island.get("structures") or [])
        if s is not None and _known_structure(s.get("structure"))
    ]
    island["eggs"] = [
        _filtered(e, _REAL_FRIEND_EGG_KEYS)
        for e in (island.get("eggs") or [])
        if e is not None and _known_monster(e.get("monster"))
    ]
    island["breeding"] = [
        _filtered(b, _REAL_FRIEND_BREEDING_KEYS)
        for b in (island.get("breeding") or [])
        if b is not None and _known_monster(b.get("monster_1")) and _known_monster(b.get("monster_2"))
        and (not b.get("new_monster") or _known_monster(b.get("new_monster")))
    ]
    return _filtered(island, _REAL_FRIEND_ISLAND_KEYS)

def friend_visit_object(player_object, user_id):
    friend = find_friend(player_object, user_id)
    if friend is None:
        return None
    _ensure_starter_island(player_object, friend)
    for island in friend.get("islands") or []:
        if island is not None:
            _apply_island_backfills(island)
    sanitized_islands = [
    _sanitize_friend_island(copy.deepcopy(island))
    for island in (friend.get("islands") or [])
    if island is not None and _known_island_type(island.get("island"))
    ]
    return {
        "user_id": friend.get("user_id"), "bbb_id": friend.get("bbb_id"),
        "user": friend.get("user_id"), "display_name": friend.get("display_name", ""),
        "level": friend.get("level", 1),
        "islands": sanitized_islands,
        "clubboxes": friend.get("clubboxes") or [],
        "tracks": friend.get("tracks") or [],
        "songs": friend.get("songs") or [],
        "active_island": friend.get("active_island", 0),
        "owned_island_themes": friend.get("owned_island_themes") or [],
        "active_island_themes": friend.get("active_island_themes") or [],
        "keys": friend.get("keys", 0), "starpower": friend.get("starpower", 0),
        "country": friend.get("country", "US"),
        "friend_gift": friend.get("friend_gift", 0),
        "total_starpower_collected": friend.get("total_starpower_collected", 0),
    }

def build_own_snapshot(player_object):
    islands = []
    for island in (player_object.get("islands") or []):
        if island is None or not _known_island_type(island.get("island")):
            continue
        islands.append(_sanitize_friend_island(copy.deepcopy(island)))
    return {
        "islands": islands,
        "active_island": player_object.get("active_island", 0),
        "clubboxes": player_object.get("clubboxes") or [],
        "tracks": player_object.get("tracks") or [],
        "songs": player_object.get("songs") or [],
        "owned_island_themes": player_object.get("owned_island_themes") or [],
        "active_island_themes": player_object.get("active_island_themes") or [],
    }

REAL_FRIEND_ID_OFFSET = 900000000

def random_visit_data(player_object):
    import random as _random
    friends = _friends_list(player_object) or []
    candidates = [f for f in friends if f is not None and f.get("user_id")]
    if not candidates:
        return {"success": False}
    friend = _random.choice(candidates)
    obj = friend_visit_object(player_object, friend.get("user_id"))
    if obj is None:
        return {"success": False}
    islands = obj.get("islands") or []
    island = islands[0] if islands else {}
    return {
        "success": True,
        "friend_object": obj,
        "user_island": island,
        "island_id": island.get("user_island_id", 0) or island.get("island", 0),
        "island_rated": False,
        "torch_gifts": [],
        "load_overlay": False,
    }

def remove_local_friend(player_object, user_id):
    friends = player_object.get("nps_fake_friends")
    if not isinstance(friends, list):
        return False
    kept = [f for f in friends if isinstance(f, dict) and f.get("user_id") != user_id]
    if len(kept) == len(friends):
        return False
    player_object["nps_fake_friends"] = kept
    return True


def is_real_friend_wire_id(user_id):
    return isinstance(user_id, int) and user_id >= REAL_FRIEND_ID_OFFSET

_DEFAULT_PROFILE_DATA = (
    '{"bg_id": 1, "card_id": 1, "version": 1, "frame_id": 583, "avatar_id": 1, '
    '"phrase_id": 1, "moniker_id": 0, "fav_mon_1_id": 0, "fav_mon_2_id": 0, '
    '"fav_mon_3_id": 0, "fav_island_id": 1, "migration_ran": 3, "total_torches_lit": 0}'
)


def _real_friend_wire_entry(friend):
    account_id = friend.get("account_id")
    if account_id is None:
        return None
    now = int(time.time() * 1000)
    return {
        "user_id": REAL_FRIEND_ID_OFFSET + int(account_id),
        "bbb_id": REAL_FRIEND_ID_OFFSET + int(account_id),
        "display_name": friend.get("display_name", ""),
        "friend_code": friend.get("friend_code", ""),
        "level": int(friend.get("level") or 1),
        "xp": int(friend.get("xp") or 0),
        "data": friend.get("data") or _DEFAULT_PROFILE_DATA,
        "pp_type": 0, "pp_info": "0",
        "is_favorite": False,
        "date_created": now, "last_login": now,
        "total_starpower_collected": 0,
        "litByMe": 0, "litByFriend": 0,
        "has_unlit_torches": False, "has_unlit_highlighted_torches": False,
        "wonBattles": 0, "lostBattles": 0, "canPvp": 0, "battle_level": 1,
        "reciprocal": True, "discoverable": 1,
        "follow_permission": 1, "followback_permission": 2,
        "tier": -1, "rank": 0, "prev_rank": 0, "prev_tier": -1,
    }

def real_friends_wire_list():
    import nps_online
    if not nps_online.is_configured():
        return []
    out = []
    for friend in nps_online.list_friends():
        entry = _real_friend_wire_entry(friend)
        if entry is not None:
            out.append(entry)
    return out

def _real_request_wire_entry(req):
    account_id = req.get("account_id")
    if account_id is None:
        return None
    wire_id = REAL_FRIEND_ID_OFFSET + int(account_id)
    now = int(time.time())
    return {
        "request_id": wire_id, "user_id": wire_id, "bbb_id": wire_id,
        "display_name": req.get("display_name", ""),
        "friend_code": req.get("friend_code", ""),
        "level": 1, "xp": 0,
        "data": "{}",
        "pp_type": 0, "pp_info": "0",
        "date_created": now, "last_login": now,
        "total_starpower_collected": 0,
    }


def discover_wire_list():
    import nps_online
    if not nps_online.is_configured():
        return []
    known = {f.get("user_id") for f in real_friends_wire_list()}
    known |= {f.get("user_id") for f in real_outgoing_wire_list()}
    known |= {f.get("user_id") for f in real_pending_wire_list()}
    out = []
    for candidate in nps_online.list_discoverable():
        entry = _real_friend_wire_entry(candidate)
        if entry is None or entry["user_id"] in known:
            continue
        out.append({k: entry[k] for k in (
            "bbb_id", "data", "date_created", "display_name", "friend_code",
            "last_login", "level", "pp_info", "pp_type",
            "total_starpower_collected", "user_id", "xp")})
    return out


def real_outgoing_wire_list():
    import nps_online
    if not nps_online.is_configured():
        return []
    out = []
    for req in nps_online.list_outgoing_requests():
        entry = _real_request_wire_entry(req)
        if entry is not None:
            out.append(entry)
    return out


def real_pending_wire_list():
    import nps_online
    if not nps_online.is_configured():
        return []
    out = []
    now = int(time.time())
    for req in nps_online.list_friend_requests():
        account_id = req.get("account_id")
        if account_id is None:
            continue
        wire_id = REAL_FRIEND_ID_OFFSET + int(account_id)
        out.append({
            "request_id": wire_id, "user_id": wire_id, "bbb_id": wire_id,
            "display_name": req.get("display_name", ""),
            "friend_code": req.get("friend_code", ""),
            "level": 1, "xp": 0,
            "data": "{}",
            "pp_type": 0, "pp_info": "0",
            "date_created": now, "last_login": now,
            "total_starpower_collected": 0,
        })
    return out

_SNAPSHOT_LISTS = ("attuned_critters", "attuning", "baking", "breeding", "eggs", "evolving",
                   "fuguing", "fuzer", "last_baked", "last_synthesis", "monsters", "nucleus",
                   "reattuning", "structures", "synthesis_attempts", "synthesizing", "torches")
_SNAPSHOT_DICTS = ("battle", "buyback", "costume_data", "last_bred", "tiles")
_SNAPSHOT_STRINGS = ("costumes_owned", "monsters_sold")
_SNAPSHOT_INTS = ("date_created", "dislikes", "island", "last_player_level",
                  "likes", "mode", "num_torches",
                  "synthesis_five_gene_cooldown", "type", "user", "user_island_id")


def _coerce_snapshot_island(island):
    for key in _SNAPSHOT_LISTS:
        if key in island and not isinstance(island[key], list):
            island[key] = []
    for key in _SNAPSHOT_DICTS:
        if key in island and not isinstance(island[key], dict):
            island[key] = {}
    for key in _SNAPSHOT_STRINGS:
        if key not in island:
            continue
        value = island[key]
        if isinstance(value, list):
            island[key] = "[" + ",".join(str(v) for v in value) + "]"
        elif not isinstance(value, str):
            island[key] = "[]"
    for key in _SNAPSHOT_INTS:
        if key not in island:
            continue
        value = island[key]
        if isinstance(value, bool) or not isinstance(value, int):
            try:
                island[key] = int(value)
            except (TypeError, ValueError):
                island[key] = 0
    if "light_torch_flag" in island:
        island["light_torch_flag"] = bool(island["light_torch_flag"])
    if isinstance(island.get("torches"), list):
        island["num_torches"] = len(island["torches"]) or island.get("num_torches", 0)
    return island


def _remap_snapshot_ids(islands, account_id, wire_user_id):
    base = 1000000000 + (int(account_id) % 10000) * 100000
    counters = {"monsters": 1000, "structures": 50000, "eggs": 90000}
    for index, island in enumerate(islands):
        island_id = base + index
        island["user_island_id"] = island_id
        island["user"] = wire_user_id
        for slot in ("monsters", "structures", "eggs"):
            key = {"monsters": "user_monster_id", "structures": "user_structure_id",
                   "eggs": "user_egg_id"}[slot]
            for entry in (island.get(slot) or []):
                entry[key] = base + counters[slot]
                entry["island"] = island_id
                counters[slot] += 1
    return islands


def real_friend_visit_object(wire_user_id):
    import nps_online
    account_id = wire_user_id - REAL_FRIEND_ID_OFFSET
    snapshot = nps_online.fetch_friend_snapshot(account_id)
    if snapshot is None:
        return None

    islands = []
    for island in (snapshot.get("islands") or []):
        if island is None or not _known_island_type(island.get("island")):
            continue
        _apply_island_backfills(island)
        islands.append(_coerce_snapshot_island(_sanitize_friend_island(copy.deepcopy(island))))

    display_name = ""
    for entry in real_friends_wire_list():
        if entry.get("user_id") == wire_user_id:
            display_name = entry.get("display_name", "")
            break

    account_id = wire_user_id - REAL_FRIEND_ID_OFFSET
    _remap_snapshot_ids(islands, account_id, wire_user_id)
    active_island = islands[0]["user_island_id"] if islands else 0

    return {
        "user_id": wire_user_id, "bbb_id": wire_user_id,
        "user": wire_user_id, "display_name": display_name,
        "level": 1,
        "islands": islands,
        "tracks": snapshot.get("tracks") or [],
        "songs": snapshot.get("songs") or [],
        "active_island": active_island,
        "owned_island_themes": snapshot.get("owned_island_themes") or [],
        "active_island_themes": snapshot.get("active_island_themes") or [],
        "keys": 0, "starpower": 0,
        "friend_gift": 0,
        "total_starpower_collected": 0,
    }

def _requests_list(player_object):
    requests = player_object.get("nps_fake_requests")
    return requests if isinstance(requests, list) else []

def find_request(player_object, request_id):
    for request in _requests_list(player_object):
        if request.get("request_id") == request_id:
            return request
    return None

def pending_wire_list(player_object):
    return [dict(r) for r in _requests_list(player_object)]

def is_local_request(player_object, request_id):
    for request in _requests_list(player_object):
        if request.get("request_id") == request_id or request.get("user_id") == request_id:
            return True
    return False

def is_local_friend(player_object, user_id):
    for friend in _friends_list(player_object):
        if friend.get("user_id") == user_id or friend.get("bbb_id") == user_id:
            return True
    return False

def accept_request(player_object, request_id):
    requests = _requests_list(player_object)
    request = next((r for r in requests
                    if r.get("request_id") == request_id or r.get("user_id") == request_id), None)
    if request is None:
        return None
    requests.remove(request)
    player_object["nps_fake_requests"] = requests
    now = request.get("last_login") or request.get("date_created")
    friend = {
        "user_id": request.get("user_id"), "bbb_id": request.get("bbb_id"),
        "display_name": request.get("display_name", ""), "level": request.get("level", 1),
        "xp": request.get("xp", 0), "friend_code": f"nps{request.get('user_id')}",
        "data": request.get("data", "{}"),
        "reciprocal": True, "discoverable": 1,
        "follow_permission": 1, "followback_permission": 2,
        "litByMe": 0, "litByFriend": 0,
        "has_unlit_torches": False, "has_unlit_highlighted_torches": False,
        "wonBattles": 0, "lostBattles": 0, "canPvp": 0, "battle_level": 1,
        "pp_type": request.get("pp_type", 0), "pp_info": request.get("pp_info", "0"),
        "tier": -1, "rank": 0, "prev_rank": 0, "prev_tier": -1,
        "total_starpower_collected": request.get("total_starpower_collected", 0),
        "date_created": request.get("date_created", now), "last_login": now,
        "keys": 0, "starpower": 0, "country": "US", "friend_gift": 0,
        "islands": [], "clubboxes": [], "tracks": [], "active_island": 0,
        "owned_island_themes": [], "active_island_themes": [],
    }
    friends = player_object.get("nps_fake_friends")
    if not isinstance(friends, list):
        friends = []
        player_object["nps_fake_friends"] = friends
    friends.append(friend)
    return friend

def deny_request(player_object, request_id):
    requests = _requests_list(player_object)
    next_requests = [r for r in requests
                     if r.get("request_id") != request_id and r.get("user_id") != request_id]
    if len(next_requests) == len(requests):
        return False
    player_object["nps_fake_requests"] = next_requests
    return True
