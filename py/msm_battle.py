import json
import random
import time

from mod_api import event
from msm_gamedata import get_battle_campaign_definition
from msm_playerdata import create_player_properties, island_type_of
from msm_store import load_db_json, load_user_data, save_user_data

_BATTLE_CURRENCY_REWARD_KEYS = (
    "coins",
    "diamonds",
    "food",
    "relics",
    "keys",
    "ethereal_currency",
    "medals",
)
_battle_level_thresholds_cache = None


def _battle_level_thresholds():
    global _battle_level_thresholds_cache
    if _battle_level_thresholds_cache is None:
        data = load_db_json("db_battle_levels") or {}
        rows = []
        for entry in data.get("battle_level_data") or []:
            if not isinstance(entry, dict):
                continue
            level = entry.get("level")
            xp = entry.get("xp")
            if isinstance(level, int) and isinstance(xp, (int, float)):
                rows.append((int(xp), level))
        rows.sort(key=lambda pair: pair[0])
        _battle_level_thresholds_cache = rows or [(0, 1)]
    return _battle_level_thresholds_cache


def battle_level_for_xp(xp):
    thresholds = _battle_level_thresholds()
    level = thresholds[0][1]
    for threshold_xp, threshold_level in thresholds:
        if xp >= threshold_xp:
            level = threshold_level
        else:
            break
    return level


def _apply_battle_currency_reward(player_object, reward):
    for key in _BATTLE_CURRENCY_REWARD_KEYS:
        if key in reward:
            new_value = (player_object.get(key, 0) or 0) + reward[key]
            player_object[key] = new_value
            player_object[f"{key}_actual"] = new_value


def _colosseum_island(player_object):
    return next(
        (
            i
            for i in player_object.get("islands") or []
            if isinstance(i, dict) and island_type_of(i) == 20
        ),
        None,
    )


def _grant_campaign_costume(player_object, colosseum, costume_id):
    costumes = player_object.get("costumes")
    if not isinstance(costumes, dict):
        costumes = {}
        player_object["costumes"] = costumes
    items = costumes.setdefault("items", [])
    if not any(isinstance(e, dict) and e.get("k") == costume_id for e in items):
        items.append({"v": 1, "k": costume_id})
    if colosseum is None:
        return
    data = colosseum.get("costume_data")
    if not isinstance(data, dict):
        data = {}
        colosseum["costume_data"] = data
    credits = data.setdefault("costumes", [])
    for entry in credits:
        if isinstance(entry, dict) and entry.get("id") == costume_id:
            entry["v"] = (entry.get("v", 0) or 0) + 1
            return
    credits.append({"v": 1, "id": costume_id})


def _campaign_costume_id(campaign):
    reward = campaign.get("reward") or {}
    return reward.get("costumeId") or campaign.get("costumeId") or 0


def _costume_in_use(player_object, costume_id):
    for island in player_object.get("islands") or []:
        if not isinstance(island, dict):
            continue
        for monster in island.get("monsters") or []:
            costume = monster.get("costume") if isinstance(monster, dict) else None
            if isinstance(costume, dict) and (
                costume.get("eq") == costume_id
                or costume_id in (costume.get("p") or [])
            ):
                return True
    return False


def repair_campaign_costumes(player_object):
    colosseum = _colosseum_island(player_object)
    if colosseum is None:
        return
    battle_state = colosseum.get("battle")
    campaigns = (
        ((battle_state or {}).get("campaign_data") or {}).get("campaigns")
        if isinstance(battle_state, dict)
        else None
    )
    if not isinstance(campaigns, list):
        return
    credit_ids = {
        e.get("id")
        for e in ((colosseum.get("costume_data") or {}).get("costumes") or [])
        if isinstance(e, dict)
    }
    for entry in campaigns:
        if not isinstance(entry, dict) or "c" not in entry:
            continue
        costume_id = _campaign_costume_id(
            get_battle_campaign_definition(entry.get("id")) or {}
        )
        if (
            not costume_id
            or costume_id in credit_ids
            or _costume_in_use(player_object, costume_id)
        ):
            continue
        _grant_campaign_costume(player_object, colosseum, costume_id)
        credit_ids.add(costume_id)


def battle_start(username, params):
    event("on_battle_start")
    seed = random.randint(10000000000000, 99999999999999)
    slots = {
        key: params[key]
        for key in sorted(
            (
                k
                for k in params
                if isinstance(k, str) and k.startswith("slot") and k[4:].isdigit()
            ),
            key=lambda k: int(k[4:]),
        )
        if params[key] is not None
    }
    battle_id = params.get("battle_id", 0)
    started = int(time.time() * 1000)
    campaign_id = params.get("campaign_id", 0)

    root = load_user_data(username)
    player_object = root.get("player_object") or {}
    battle_state = player_object.setdefault("battle", {})
    battle_state["loadout"] = json.dumps(slots)
    save_user_data(username, root)

    result = {
        "success": True,
        "battle_id": battle_id,
        "started": started,
        "campaign_id": campaign_id,
        "seed": seed,
    }
    result.update(slots)
    return result


def battle_finish(username, params):
    result = params.get("result", 0) or 0
    battle_id = params.get("battle_id", 0) or 0
    campaign_id = params.get("campaign_id", 0) or 0

    root = load_user_data(username)
    player_object = root.get("player_object") or {}

    campaign = get_battle_campaign_definition(campaign_id) or {}
    battles = campaign.get("battles") or []
    battle_def = battles[battle_id] if 0 <= battle_id < len(battles) else {}
    battle_reward = dict(battle_def.get("reward") or {})

    won = result == 1
    if won:
        _apply_battle_currency_reward(player_object, battle_reward)
        xp_gain = battle_reward.get("xp", 0) or 0
        player_object["battle_xp"] = (player_object.get("battle_xp", 0) or 0) + xp_gain
        player_object["battle_level"] = battle_level_for_xp(
            player_object.get("battle_xp", 0) or 0
        )

    next_battle = battle_id + 1 if won else battle_id
    campaign_completed_now = None
    campaign_reward = None
    if won:
        colosseum = _colosseum_island(player_object)
        colosseum_found = colosseum is not None
        if colosseum is None:
            colosseum = {}
        battle_state = colosseum.setdefault("battle", {})
        campaign_data = battle_state.get("campaign_data")
        if not isinstance(campaign_data, dict):
            campaign_data = {}
            battle_state["campaign_data"] = campaign_data
        campaigns = campaign_data.get("campaigns")
        if not isinstance(campaigns, list):
            campaigns = []
            campaign_data["campaigns"] = campaigns
        entry = next(
            (
                c
                for c in campaigns
                if isinstance(c, dict) and c.get("id") == campaign_id
            ),
            None,
        )
        now_ms = int(time.time() * 1000)
        if entry is None:
            entry = {"id": campaign_id, "b": next_battle, "s": now_ms}
            campaigns.append(entry)
        else:
            entry["b"] = max(entry.get("b", 0) or 0, next_battle)
        if entry["b"] >= len(battles) and "c" not in entry:
            entry["c"] = now_ms
            campaign_completed_now = now_ms
            campaign_reward = dict(campaign.get("reward") or {})
            granted_costume = _campaign_costume_id(campaign)
            if granted_costume:
                _grant_campaign_costume(
                    player_object,
                    colosseum if colosseum_found else None,
                    granted_costume,
                )
            all_campaigns = load_db_json("db_battle") or {}
            for other in all_campaigns.get("battle_campaign_data") or []:
                if not isinstance(other, dict) or other.get("depends") != campaign_id:
                    continue
                other_id = other.get("id")
                if other_id is None:
                    continue
                if not any(
                    isinstance(c, dict) and c.get("id") == other_id for c in campaigns
                ):
                    campaigns.append({"id": other_id, "b": 0, "s": now_ms})
    save_user_data(username, root)

    response = {
        "success": True,
        "result": result,
        "battle_id": battle_id,
        "campaign_id": campaign_id,
        "next_battle": next_battle,
        "battle_reward": {
            **battle_reward,
            "player_xp": player_object.get("battle_xp", 0),
            "player_level": player_object.get("battle_level", 0),
        },
        "properties": create_player_properties(player_object),
    }
    if campaign_completed_now is not None:
        response["completed"] = campaign_completed_now
        response["campaign_reward"] = campaign_reward
    event("on_battle_finish", response=response)
    return response
