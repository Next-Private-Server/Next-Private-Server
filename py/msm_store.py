import json
import os
import tempfile
import threading
import time
from pathlib import Path

from msm_protocol import SFSLong

db_dir =None
players_dir =None

_db_cache ={}
_user_file_locks ={}
_user_file_locks_guard =threading .Lock ()
_mod_db_names =set ()

_UNCACHED_DB_NAMES ={"gs_timed_events"}

def clear_db_cache ():

    _db_cache .clear ()
    _mod_db_names .clear ()

def mod_db_names ():
    return sorted (_mod_db_names )

def load_db_json (name ):
    if name in _db_cache :
        return _db_cache [name ]
    if db_dir is None :
        raise RuntimeError ("msm_store.db_dir not configured")
    path =Path (db_dir )/f"{name }.json"
    if not path .exists ():
        if name in _UNCACHED_DB_NAMES :
            return None
        _db_cache [name ]=None
        return None
    with path .open ("r",encoding ="utf-8-sig")as fh :
        data =json .load (fh )
    if name not in _UNCACHED_DB_NAMES :
        _db_cache [name ]=data
    return data

_DB_ARRAY_ID_KEYS = {
    "structures_data": "structure_id",
    "islands_data": "island_type",
    "monsters_data": "monster_id",
}

def _merge_db_value(existing, key, value):
    if isinstance(value, list):
        target_list = existing.setdefault(key, [])
        if not isinstance(target_list, list):
            existing[key] = value
            return len(value)
        id_key = _DB_ARRAY_ID_KEYS.get(key)
        existing_ids = (
            {entry.get(id_key) for entry in target_list if isinstance(entry, dict)}
            if id_key else None
        )
        added = 0
        for entry in value:
            if id_key is not None and isinstance(entry, dict) and entry.get(id_key) in existing_ids:
                continue
            target_list.append(entry)
            if existing_ids is not None and isinstance(entry, dict):
                existing_ids.add(entry.get(id_key))
            added += 1
        return added
    if isinstance(value, dict):
        target_dict = existing.setdefault(key, {})
        if isinstance(target_dict, dict):
            for sub_key, sub_value in value.items():
                _merge_db_value(target_dict, sub_key, sub_value)
        else:
            existing[key] = value
        return 1
    existing[key] = value
    return 1

def apply_mod_db_files(base_dir):

    root = Path(base_dir) / "mod_assets"
    if not root.is_dir():
        return
    import logging
    logger = logging.getLogger("msm.store")
    for mod_dir in sorted(root.iterdir()):
        db_files_dir = mod_dir / "db_files"
        if not db_files_dir.is_dir():
            continue
        for db_file in sorted(db_files_dir.glob("*.json")):
            db_name = db_file.stem
            try:
                with db_file.open("r", encoding="utf-8-sig") as fh:
                    mod_data = json.load(fh)
                if not isinstance(mod_data, dict):
                    logger.warning("db file %s: top-level JSON must be an object", db_file)
                    continue
                existing = load_db_json(db_name)
                if isinstance(existing, dict):
                    added = 0
                    for key, value in mod_data.items():
                        added += _merge_db_value(existing, key, value)
                    logger.info("db file %s: merged into existing %s (%d item(s) added/updated)", db_file, db_name, added)
                else:
                    _db_cache[db_name] = mod_data
                    logger.info("db file %s: registered as new db %s", db_file, db_name)
                if db_name.startswith("db_"):
                    _mod_db_names.add(db_name)
            except Exception:
                logger.exception("failed to apply db file %s", db_file)

def normalize_db_payload (command ,payload ):
    now_ms =SFSLong (int (time .time ()*1000 ))
    payload ["server_time"]=now_ms
    payload .setdefault ("last_updated",now_ms )
    if command .startswith ("gs_"):
        payload .setdefault ("success",True )
    return payload

def _player_file (username ):
    if players_dir is None :
        raise RuntimeError ("msm_store.players_dir not configured")
    return Path (players_dir )/f"{username }.json"

def _lock_for_path (path ):
    key =str (path .resolve ())
    with _user_file_locks_guard :
        lock =_user_file_locks .get (key )
        if lock is None :
            lock =threading .RLock ()
            _user_file_locks [key ]=lock
        return lock

def _atomic_write_json (path ,data ):
    path .parent .mkdir (parents =True ,exist_ok =True )
    fd ,tmp_name =tempfile .mkstemp (prefix =f".{path .name }.",suffix =".tmp",dir =str (path .parent ))
    tmp_path =Path (tmp_name )
    try :
        with os .fdopen (fd ,"w",encoding ="utf-8")as fh :
            json .dump (data ,fh )
        os .replace (tmp_path ,path )
    finally :
        if tmp_path .exists ():
            tmp_path .unlink ()

_FROZEN_CURRENCY_BASE_KEYS =(
"coins","diamonds","food","ethereal_currency","keys","relics",
"egg_wildcards","clubbox_tokens","starpower","medals",
"battle_xp","speed_up_credit","total_starpower_collected",
)

_FROZEN_CURRENCY_KEYS =frozenset (
_FROZEN_CURRENCY_BASE_KEYS +tuple (f"{key }_actual"for key in _FROZEN_CURRENCY_BASE_KEYS )
)

class _FrozenCurrencyDict (dict ):

    def __setitem__ (self ,key ,value ):
        if key in _FROZEN_CURRENCY_KEYS :
            return
        dict .__setitem__ (self ,key ,value )
    def pop (self ,key ,*default ):
        if key in _FROZEN_CURRENCY_KEYS :
            return self .get (key ,*default )
        return dict .pop (self ,key ,*default )
    def setdefault (self ,key ,default =None ):
        if key in _FROZEN_CURRENCY_KEYS :
            return self .get (key ,default )
        return dict .setdefault (self ,key ,default )
    def update (self ,*args ,**kwargs ):
        for k ,v in dict (*args ,**kwargs ).items ():
            self [k ]=v

def load_user_data (username ):
    path =_player_file (username )
    if not path .exists ():
        raise FileNotFoundError (f"no player data for {username!r} at {path}")
    with path .open ("r",encoding ="utf-8-sig")as fh :
        root =json .load (fh )
    po =root .get ("player_object")
    if isinstance (po ,dict ):
        for key in _FROZEN_CURRENCY_BASE_KEYS +("minigame_tokens","sticker_stars"):
            po .setdefault (key ,po .get (f"{key}_actual",0 ))
        best =max (
        po .get ("egg_wildcards",0 )or 0 ,
        po .get ("playerEggWildcards",0 )or 0 ,
        po .get ("wildcards",0 )or 0 ,
        )
        po ["egg_wildcards"]=best
        po ["playerEggWildcards"]=best
        po ["wildcards"]=best
        for key in _FROZEN_CURRENCY_BASE_KEYS +("minigame_tokens","sticker_stars"):
            po [f"{key}_actual"]=po [key ]
    import msm_toggles
    if not msm_toggles .is_enabled ("functioning_currencies")and isinstance (root .get ("player_object"),dict ):
        root ["player_object"]=_FrozenCurrencyDict (root ["player_object"])
    return root

def save_user_data (username ,root ):
    path =_player_file (username )
    with _lock_for_path (path ):
        _atomic_write_json (path ,root )
