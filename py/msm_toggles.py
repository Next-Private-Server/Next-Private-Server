import json
import os
import time
from pathlib import Path

_DEFAULTS = {
    "level20_spawns": False,
    "monster_spawn_level": 20,
    "instant_timers": False,
    "wubbox_auto_awaken": False,
    "premium_account": True,
    "unlock_all_bakery_foods": False,
    "unlock_all_celestial_ascension": False,
    "random_monster_names": False,
    "functioning_currencies": False,
    "sell_percentage": 75,
    "breeding_luck": False,
    "breeding_rate_normal": 100,
    "breeding_rate_rare": 0,
    "breeding_rate_epic": 0,
    "minigame_theme": "anniversary",
    "clubbox_enabled": True,
    "clubbox_hours_enabled": False,
    "clubbox_start_hour": 0,
    "clubbox_end_hour": 24,
    "dipster_dig_enabled": True,
    "dipster_dig_hours_enabled": False,
    "dipster_dig_start_hour": 0,
    "dipster_dig_end_hour": 24,
}


def _path():
    base = os.environ.get("NPS_BASE_DIR")
    if not base:
        return None
    return Path(base) / "nps_toggles.json"


def get_toggles():
    path = _path()
    if path is None or not path.exists():
        return dict(_DEFAULTS)
    try:
        with path.open("r", encoding="utf-8") as fh:
            data = json.load(fh)
    except (OSError, ValueError):
        return dict(_DEFAULTS)
    merged = dict(_DEFAULTS)
    if isinstance(data, dict):
        for key in _DEFAULTS:
            if key in data:
                if isinstance(_DEFAULTS[key], bool):
                    merged[key] = bool(data[key])
                elif isinstance(_DEFAULTS[key], str):
                    merged[key] = str(data[key])
                else:
                    try:
                        merged[key] = int(data[key])
                    except (TypeError, ValueError, OverflowError):
                        pass
    return merged


def is_enabled(name):
    return bool(get_toggles().get(name, False))


def get_int(name, default=0, minimum=None, maximum=None):
    try:
        value = int(get_toggles().get(name, default))
    except (TypeError, ValueError, OverflowError):
        value = default
    if minimum is not None:
        value = max(minimum, value)
    if maximum is not None:
        value = min(maximum, value)
    return value


def is_time_window_active(enabled_key, hours_enabled_key, start_hour_key, end_hour_key):
    if not is_enabled(enabled_key):
        return False
    if not is_enabled(hours_enabled_key):
        return True
    start = get_int(start_hour_key, 0, 0, 24)
    end = get_int(end_hour_key, 24, 0, 24)
    if start >= end:
        if start == end:
            return True
        now_hour = time.localtime().tm_hour
        return now_hour >= start or now_hour < end
    now_hour = time.localtime().tm_hour
    return start <= now_hour < end
