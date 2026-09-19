import importlib .util
import json
import logging
import os
import sys
import time
import traceback
from mod_schema import ModValidationError ,validate_island_entry ,validate_monster_catalog_entry

logger =logging .getLogger ("msm.mods")
BRIDGE_API_VERSION =1

_EVENT_HOOKS ={}
_LAUNCHER_TABS ={}
_LAUNCHER_CALLBACKS ={}
_LOADED_MODS =[]
_LOAD_ERRORS =[]
_JAVA_RUNTIME =None
_MOD_STATE_DIR =None
_PENDING_PROPERTY_UPDATES =set ()
_PENDING_FRAMES ={}
_CLIENT_STAGES ={}
_COMMAND_ALIASES ={}
_LUA_REQUEST_PATHS =[
"/sdcard/Download/nps_lua_requests.jsonl",
"/storage/emulated/0/Download/nps_lua_requests.jsonl",
"/data/local/tmp/nps_lua_requests.jsonl",
]
_LUA_LOG_PATHS =[
"/sdcard/Download/nps_lua.log",
"/storage/emulated/0/Download/nps_lua.log",
"/data/local/tmp/nps_lua.log",
]

_CURRENCY_ACTUAL_KEYS ={
"coins":"coins_actual",
"diamonds":"diamonds_actual",
"food":"food_actual",
"ethereal_currency":"ethereal_currency_actual",
"keys":"keys_actual",
"relics":"relics_actual",
"egg_wildcards":"egg_wildcards_actual",
"clubbox_tokens":"clubbox_tokens_actual",
"starpower":"starpower_actual",
"medals":"medals_actual",
}
_CURRENCY_ALIASES ={
"coin":"coins","diamond":"diamonds",
"shard":"ethereal_currency","shards":"ethereal_currency","ethereal":"ethereal_currency","eth_currency":"ethereal_currency",
"key":"keys","relic":"relics","star":"starpower","stars":"starpower",
"wildcard":"egg_wildcards","wildcards":"egg_wildcards","eggwildcards":"egg_wildcards",
"clubbox_token":"clubbox_tokens","clubbox_tokens":"clubbox_tokens",
}
def normalize_currency (currency ):
    normalized =str (currency or "").strip ().lower ()
    return _CURRENCY_ALIASES .get (normalized ,normalized )

def on_event (event_name ):
    def register (fn ):
        _EVENT_HOOKS .setdefault (event_name ,[]).append (fn )
        return fn
    return register

def _caller_mod_id ():
    frame =sys ._getframe (2 )
    while frame is not None :
        mod_id =frame .f_globals .get ("__mod_id__")
        if mod_id :
            return mod_id
        frame =frame .f_back
    return "unknown"

def _mod_cache_path (mod_id ):
    if not _MOD_STATE_DIR :
        return None
    return os .path .join (_MOD_STATE_DIR ,mod_id ,"cache.json")

def cache_get (key ,default =None ):
    path =_mod_cache_path (_caller_mod_id ())
    if not path or not os .path .isfile (path ):
        return default
    try :
        with open (path ,encoding ="utf-8")as fh :
            store =json .load (fh )
        return store .get (key ,default )if isinstance (store ,dict )else default
    except Exception :
        logger .exception ("mod cache read failed for %s",path )
        return default

def cache_set (key ,value ):
    mod_id =_caller_mod_id ()
    path =_mod_cache_path (mod_id )
    if not path :
        logger .warning ("cache_set(%r) called before mods were loaded, dropped",key )
        return False
    store ={}
    if os .path .isfile (path ):
        try :
            with open (path ,encoding ="utf-8")as fh :
                loaded =json .load (fh )
            if isinstance (loaded ,dict ):
                store =loaded
        except Exception :
            logger .exception ("mod cache read-before-write failed for %s",path )
    store [key ]=value
    try :
        os .makedirs (os .path .dirname (path ),exist_ok =True )
        tmp =path +".tmp"
        with open (tmp ,"w",encoding ="utf-8")as fh :
            json .dump (store ,fh )
        os .replace (tmp ,path )
        return True
    except Exception :
        logger .exception ("mod cache write failed for %s",path )
        return False

def fire_event (event_name ,**kwargs ):
    for fn in _EVENT_HOOKS .get (event_name ,()):
        try :
            fn (**kwargs )
        except Exception :
            logger .exception ("mod hook failed for event %s",event_name )
    return _fire_java_event (event_name ,kwargs )

_EVENT_AUTO_CONTEXT_KEYS =("username","params","player_object","result","root")

def event (event_name ,**extra ):
    caller_locals =sys ._getframe (1 ).f_locals
    context ={
    key :caller_locals [key ]
    for key in _EVENT_AUTO_CONTEXT_KEYS
    if key in caller_locals and caller_locals [key ]is not None
    }
    context .update (extra )
    return fire_event (event_name ,**context )

_HUD_PROMPT_HANDLERS ={}
_HUD_PROMPT_NAME_KEYS =("newName","displayName","display_name","player_name","name","user_alias")

def _hud_prompt_real_name (player_object ,username ):
    return (
    player_object .get ("display_name")
    or player_object .get ("player_name")
    or player_object .get ("user_alias")
    or username
    )

def on_hud_prompt (mod_id ,button_id ,handler =None ):
    prefix ="NPSHUD:%s:%s:"%(mod_id ,button_id )
    if handler is not None :
        _HUD_PROMPT_HANDLERS [prefix ]=handler
        return handler
    def register (fn ):
        _HUD_PROMPT_HANDLERS [prefix ]=fn
        return fn
    return register

@on_event ("command_received")
def _dispatch_hud_prompt (username ="",command ="",params =None ,**_ ):
    if command !="gs_set_displayname"or not isinstance (params ,dict )or not _HUD_PROMPT_HANDLERS :
        return
    for key in _HUD_PROMPT_NAME_KEYS :
        value =params .get (key )
        if not isinstance (value ,str ):
            continue
        for prefix ,handler in _HUD_PROMPT_HANDLERS .items ():
            if not value .startswith (prefix ):
                continue
            from msm_playerdata import load_player ,save_player
            root ,player_object =load_player (username )
            payload =value [len (prefix ):]
            params [key ]=_hud_prompt_real_name (player_object ,username )
            try :
                message =handler (username =username ,value =payload ,player_object =player_object ,root =root )
            except Exception :
                logger .exception ("hud prompt handler failed for %s",prefix )
                message =None
            save_player (username ,root )
            if message :
                request_property_update (username )
                _PENDING_FRAMES .setdefault (username ,[]).append ((
                "gs_display_generic_message",
                {"force_logout":False ,"msg":str (message )},
                ))
            return

def add_currency (player_object ,currency ,amount ):
    currency =normalize_currency (currency )
    if currency not in _CURRENCY_ACTUAL_KEYS :
        logger .warning ("blocked unknown currency %s",currency )
        return
    player_object [currency ]=_clamp_client_int (int (player_object .get (currency ,0 )or 0 )+_safe_int (amount ,0 ))
    actual_key =_CURRENCY_ACTUAL_KEYS .get (currency )
    if actual_key :
        player_object [actual_key ]=player_object [currency ]
    if currency =="egg_wildcards":
        player_object ["playerEggWildcards"]=player_object [currency ]

def set_currency (player_object ,currency ,value ):
    currency =normalize_currency (currency )
    if currency not in _CURRENCY_ACTUAL_KEYS :
        logger .warning ("blocked unknown currency %s",currency )
        return
    player_object [currency ]=_clamp_client_int (_safe_int (value ,0 ))
    actual_key =_CURRENCY_ACTUAL_KEYS .get (currency )
    if actual_key :
        player_object [actual_key ]=player_object [currency ]
    if currency =="egg_wildcards":
        player_object ["playerEggWildcards"]=player_object [currency ]

_ID_REGISTRY_FLOOR = 9000

def _id_registry_path():
    if _MOD_STATE_DIR is None:
        return None
    return os.path.join(os.path.dirname(_MOD_STATE_DIR), "nps_id_registry.json")

def _load_id_registry():
    path = _id_registry_path()
    if not path or not os.path.isfile(path):
        return {}
    try:
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
        return data if isinstance(data, dict) else {}
    except Exception:
        logger.exception("id registry read failed for %s", path)
        return {}

def _save_id_registry(registry):
    path = _id_registry_path()
    if not path:
        return
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        tmp = path + ".tmp"
        with open(tmp, "w", encoding="utf-8") as fh:
            json.dump(registry, fh)
        os.replace(tmp, path)
    except Exception:
        logger.exception("id registry write failed for %s", path)

def allocate_id(namespace, key):
    registry = _load_id_registry()
    bucket = registry.setdefault(namespace, {})
    full_key = "%s:%s" % (_caller_mod_id(), key)
    if full_key in bucket:
        return bucket[full_key]
    used = set(bucket.values())
    candidate = _ID_REGISTRY_FLOOR
    while candidate in used:
        candidate += 1
    bucket[full_key] = candidate
    _save_id_registry(registry)
    return candidate

def add_new_structure(
    key,
    name,
    description="",
    structure_type="decoration",
    graphic_file=None,
    cost_coins=0,
    cost_diamonds=0,
    size_x=1,
    size_y=1,
    movable=1,
    sellable=0,
    view_in_market=0,
    **overrides
):
    mod_id = _caller_mod_id()
    structure_id = allocate_id("structure", key)
    entry = {
        "structure_id": structure_id,
        "entity_id": structure_id,
        "entity_type": "structure",
        "structure_type": structure_type,
        "name": name,
        "description": description,
        "graphic": {"file": graphic_file} if graphic_file else {},
        "size_x": size_x,
        "size_y": size_y,
        "movable": movable,
        "sellable": sellable,
        "view_in_market": view_in_market,
        "view_in_starmarket": 0,
        "premium": 0,
        "cost_coins": cost_coins,
        "cost_diamonds": cost_diamonds,
        "cost_keys": 0,
        "cost_relics": 0,
        "cost_starpower": 0,
        "cost_medals": 0,
        "cost_eth_currency": 0,
        "cost_sale": 0,
        "build_time": 0,
        "level": 0,
        "xp": 0,
        "upgrades_to": 0,
        "battle_level": 0,
        "show_in_levelup": 0,
        "y_offset": 0,
        "platforms": "",
        "extra": {},
        "requirements": [],
        "keywords": "[]",
        "min_server_version": "1.0",
        "last_changed": int(time.time() * 1000),
    }
    entry.update(overrides)
    if structure_type == "mine" and "upgrades_to" not in overrides:
        entry["upgrades_to"] = structure_id
    _apply_db_patch("db_structure", {"structures_data": [entry]}, "inject", "<%s:add_new_structure:%s>" % (mod_id, key))
    logger.info("%s registered structure '%s' as id %d via add_new_structure", mod_id, key, structure_id)
    return structure_id

_PLANT_ISLAND_TYPE = 1

def _stable_slot_index(text, modulo):
    if modulo <= 0:
        return 0
    value = 0
    for char in text:
        value = (value * 131 + ord(char)) & 0xFFFFFFFF
    return value % modulo

def _add_monster_to_island_book(monster_id, mod_id, key, island_type, genes):
    import msm_store
    islands = msm_store.load_db_json("db_island_v2") or {}
    island = next(
        (isl for isl in islands.get("islands_data", []) if isinstance(isl, dict) and isl.get("island_type") == island_type),
        None,
    )
    if island is None:
        logger.warning("add_new_monster(add_to_island=...): island_type %s not found", island_type)
        return
    monsters = island.get("monsters")
    if not isinstance(monsters, list) or not monsters:
        logger.warning("add_new_monster(add_to_island=...): island_type %s has no book slots", island_type)
        return
    slot_index = _stable_slot_index("%s:%s" % (mod_id, key), len(monsters))
    slot = monsters[slot_index]
    if not isinstance(slot, dict):
        return
    previous_monster = slot.get("monster")
    slot["monster"] = monster_id
    if isinstance(genes, str) and genes:
        slot["instrument"] = "001_%s.bin" % genes
    _invalidate_game_caches("db_island_v2")
    logger.info(
        "%s put monster '%s' (id %d) into island_type %s book slot %d (was monster %s)",
        mod_id, key, monster_id, island_type, slot_index, previous_monster,
    )

def add_new_monster(
    key,
    common_name,
    genes,
    graphic_file,
    add_to_island=False,
    **overrides
):
    mod_id = _caller_mod_id()
    monster_id = allocate_id("monster", key)
    genes_str = genes if isinstance(genes, str) else ""
    entry = {
        "monster_id": monster_id,
        "entity_id": monster_id,
        "entity_type": "monster",
        "common_name": common_name,
        "name": common_name,
        "genes": genes,
        "graphic": {"file": graphic_file},
        "portrait_graphic": "monster_portrait_square_%s" % genes_str.lower(),
        "spore_graphic": "spore_%s" % genes_str,
        "select_sound": "%s-Memory" % genes_str,
        "class": "CLASS_NATURAL",
        "fam": "CLASS_NATURAL",
        "view_in_market": 0,
        "view_in_starmarket": 0,
        "premium": 0,
        "cost_coins": 0,
        "cost_diamonds": 0,
        "cost_keys": 0,
        "cost_relics": 0,
        "cost_starpower": 0,
        "cost_medals": 0,
        "cost_eth_currency": 0,
        "cost_sale": 0,
        "available": 1,
        "always_avail": 1,
        "time_availability": 255,
        "movable": 1,
        "size_x": 1,
        "size_y": 1,
        "beds": 1,
        "build_time": 0,
        "level": 1,
        "xp": 0,
        "requirements": [],
        "happiness": [],
        "levels": [
            {"level": 1, "coins": 1, "max_coins": 10, "food": 5, "ethereal_currency": 0, "max_ethereal": 0},
        ],
        "min_server_version": "1.0",
        "last_changed": int(time.time() * 1000),
    }
    entry.update(overrides)
    _apply_db_patch("db_monster", {"monsters_data": [entry]}, "inject", "<%s:add_new_monster:%s>" % (mod_id, key))
    logger.info("%s registered monster '%s' as id %d via add_new_monster", mod_id, key, monster_id)
    if add_to_island:
        island_type = add_to_island if isinstance(add_to_island, int) and not isinstance(add_to_island, bool) else _PLANT_ISLAND_TYPE
        _add_monster_to_island_book(monster_id, mod_id, key, island_type, entry.get("genes"))
    return monster_id

def sync_structure(username, structure, player_object, *fields):
    from msm_playerdata import create_player_properties
    from msm_protocol import SFSLong
    if not fields:
        fields = ("last_collection",)
    properties = [{name: SFSLong(structure.get(name, 0) or 0)} for name in fields]
    properties.extend(create_player_properties(player_object))
    update = {
        "user_structure_id": SFSLong(structure.get("user_structure_id", 0)),
        "properties": properties,
    }
    _PENDING_FRAMES.setdefault(username, []).append(("gs_update_structure", update))

def _safe_int (value ,fallback =0 ):
    try :
        if isinstance (value ,bool ):
            return int (value )
        if isinstance (value ,int ):
            return value
        if isinstance (value ,float ):
            return int (value )
        if isinstance (value ,str ):
            return int (value .strip ())
    except Exception :
        pass
    logger .warning ("blocked non-integer mod value %r",value )
    return fallback

def _clamp_client_int (value ):

    return max (0 ,int (value ))

def _safe_command_name (value ):
    command =str (value or "").strip ()
    if not command or len (command )>96 :
        return ""
    for char in command :
        if not (char .isalnum ()or char in "_:.-"):
            return ""
    return command

def _java_runtime ():
    global _JAVA_RUNTIME
    if _JAVA_RUNTIME is not None :
        return _JAVA_RUNTIME
    try :
        from java import jclass
        _JAVA_RUNTIME =jclass ("com.nextstars.nps.mods.NpsModRuntime")
    except Exception :
        _JAVA_RUNTIME =False
    return _JAVA_RUNTIME

def _json_safe (value ,depth =0 ):
    if depth >3 :
        return str (value )
    if isinstance (value ,(str ,int ,float ,bool ))or value is None :
        return value
    if isinstance (value ,dict ):
        return {str (k ):_json_safe (v ,depth +1 )for k ,v in value .items ()}
    if isinstance (value ,(list ,tuple )):
        return [_json_safe (v ,depth +1 )for v in value [:50 ]]
    return str (value )

def _first_value (*values ):
    for value in values :
        if value is not None and value !="":
            return value
    return None

def _dict_value (data ,*keys ):
    if not isinstance (data ,dict ):
        return None
    for key in keys :
        if key in data and data .get (key )is not None :
            return data .get (key )
    return None

def _target_value_for (out_key ,data ):
    if not isinstance (data ,dict ):
        return None
    mappings ={
    "user_island_id":("user_island_id","userIslandId","user_island","island_uid","island_id","islandId","island"),
    "user_monster_id":("user_monster_id","userMonsterId","user_monster","userMonster","user_monster_1","user_monster_id_1","user_monster_id_2","monster_uid"),
    "user_structure_id":("user_structure_id","userStructureId","user_structure","structure_uid","structure_id","structureId","structure"),
    "user_egg_id":("user_egg_id","userEggId","user_egg","egg_uid","egg_id","eggId"),
    "monster_id":("monster","monster_id","monsterId","database_id","databasae_id","entity_id","entity","id"),
    "island_type":("island_type","islandType","island_type_id","islandTypeId","type"),
    "structure_id":("structure","structure_id","structureId","database_id","databasae_id","entity_id","id"),
    }
    value =_dict_value (data ,*mappings .get (out_key ,()))
    if value is not None :
        return value
    for container_key in ("params","payload","data","result"):
        nested =data .get (container_key )
        if isinstance (nested ,dict ):
            value =_target_value_for (out_key ,nested )
            if value is not None :
                return value
    return None

def _is_target_scalar (value ):
    return isinstance (value ,(str ,int ,float ,bool ))or value is None

def _merge_target_fields (payload ,data ):
    if not isinstance (data ,dict ):
        return
    for nested_key in (
    "monster",
    "egg",
    "island",
    "structure",
    "user_monster",
    "user_egg",
    "user_island",
    "user_structure",
    "user_monster_data",
    "user_egg_data",
    "user_island_data",
    "user_structure_data",
    ):
        nested =data .get (nested_key )
        if isinstance (nested ,dict ):
            _merge_target_fields (payload ,nested )
    for out_key in ("user_island_id","user_monster_id","user_structure_id","user_egg_id","monster_id","island_type","structure_id"):
        value =_target_value_for (out_key ,data )
        if value is not None and _is_target_scalar (value )and not payload .get (out_key ):
            payload [out_key ]=value

def _response_summary (response_frames ):
    summary =[]
    if not isinstance (response_frames ,(list ,tuple )):
        return summary
    for frame in response_frames [:20 ]:
        if not isinstance (frame ,dict ):
            continue
        payload =frame .get ("payload")
        item ={"command":frame .get ("command","")}
        if isinstance (payload ,dict ):
            item ["success"]=payload .get ("success")
            _merge_target_fields (item ,payload )
            if "properties"in payload :
                item ["has_properties"]=True
        summary .append (item )
    return summary

def _event_payload (event_name ,kwargs ):
    command =str (kwargs .get ("command")or "")
    username =str (kwargs .get ("username")or "")
    payload ={
    "event":event_name ,
    "id":str (_first_value (kwargs .get ("id"),kwargs .get ("request_id"),command )or ""),
    "username":username ,
    "command":command ,
    "stage":str (kwargs .get ("stage")or client_stage (username )or event_name ),
    "source":"server",
    }
    for key ,value in kwargs .items ():
        if key =="player_object":
            player =value if isinstance (value ,dict )else {}
            payload ["player_level"]=player .get ("level",0 )
            payload ["coins"]=player .get ("coins",0 )
            payload ["diamonds"]=player .get ("diamonds",0 )
            payload ["food"]=player .get ("food",0 )
            payload ["relics"]=player .get ("relics",0 )
            payload ["keys"]=player .get ("keys",0 )
            payload ["active_island"]=player .get ("active_island",0 )
            continue
        if isinstance (value ,dict )and key =="monster":
            _merge_target_fields (payload ,value )
            payload ["monster_name"]=value .get ("name","")
        if isinstance (value ,dict )and key =="island":
            _merge_target_fields (payload ,value )
        if isinstance (value ,dict )and key =="egg":
            _merge_target_fields (payload ,value )
        if isinstance (value ,dict )and key =="structure":
            _merge_target_fields (payload ,value )
        if isinstance (value ,dict )and key in ("breeding","result"):
            _merge_target_fields (payload ,value )
        if key =="command":
            payload ["command"]=str (value )
        if key =="params"and isinstance (value ,dict ):
            _merge_target_fields (payload ,value )
            for param_key ,param_value in value .items ():
                if param_key not in payload and (isinstance (param_value ,(str ,int ,float ,bool ))or param_value is None ):
                    payload [str (param_key )]=param_value
        if key =="response_frames":
            payload ["response_summary"]=_response_summary (value )
            for frame in value if isinstance (value ,(list ,tuple ))else []:
                if isinstance (frame ,dict ):
                    _merge_target_fields (payload ,frame )
                    _merge_target_fields (payload ,frame .get ("payload"))
        payload [key ]=_json_safe (value )
    if isinstance (payload .get ("params"),dict ):
        payload ["details"]={"params":payload .get ("params")}
    else :
        payload ["details"]={}
    if "response_summary"in payload :
        payload ["details"]["response_summary"]=payload ["response_summary"]
    if payload .get ("user_monster_id")and not payload .get ("user_egg_id")and command in ("gs_hatch_egg","gs_finish_breeding"):
        payload ["hatch_target_id"]=payload .get ("user_monster_id")
    return payload

def _fire_java_event (event_name ,kwargs ):
    runtime =_java_runtime ()
    if not runtime :
        return []
    try :
        payload =json .dumps (_event_payload (event_name ,kwargs ),ensure_ascii =False )
        raw_commands =runtime .emit (event_name ,payload )
        commands =json .loads (str (raw_commands or "[]"))
        _apply_commands (kwargs ,commands )
        return commands
    except Exception :
        logger .exception ("java mod event failed for %s",event_name )
        return []

class LauncherTab :
    def __init__ (self ,mod_id ,tab_id ,label ,icon ):
        self .mod_id =mod_id
        self .tab_id =tab_id
        self .label =label
        self .icon =icon
        self .elements =[]
        self ._on_open =None
        self ._next_id =1

    def _new_id (self ):
        eid =f"{self .tab_id }_{self ._next_id }"
        self ._next_id +=1
        return eid

    def _register_callback (self ,fn ):
        if fn is None :
            return None
        cb_id =f"{self .mod_id }:{self ._new_id ()}"
        _LAUNCHER_CALLBACKS [cb_id ]=fn
        return cb_id

    def text (self ,value ):
        self .elements .append ({"type":"text","id":self ._new_id (),"text":str (value )[:2000 ]})

    def button (self ,label ,on_click =None ):
        cb =self ._register_callback (on_click )
        self .elements .append ({"type":"button","id":self ._new_id (),"label":str (label )[:64 ],"callback":cb })

    def text_field (self ,label ,on_change =None ,value =""):
        cb =self ._register_callback (on_change )
        self .elements .append ({"type":"textField","id":self ._new_id (),"label":str (label )[:64 ],"value":str (value )[:2000 ],"callback":cb })

    def image (self ,source ):
        self .elements .append ({"type":"image","id":self ._new_id (),"source":str (source )[:2_000_000 ]})

    def upload_file (self ,label ,on_upload =None ,accept =None ):
        cb =self ._register_callback (on_upload )
        safe_accept =[str (a )for a in accept ]if isinstance (accept ,(list ,tuple ))else []
        self .elements .append ({"type":"fileUpload","id":self ._new_id (),"label":str (label )[:64 ],"callback":cb ,"accept":safe_accept })

    def divider (self ):
        self .elements .append ({"type":"divider","id":self ._new_id ()})

    def clear (self ):
        self .elements =[]

    def on_open (self ,fn ):
        self ._on_open =fn
        return fn

    def to_json (self ):
        return {"modId":self .mod_id ,"id":self .tab_id ,"label":self .label ,"icon":self .icon ,"elements":list (self .elements )}

def launcher_tab (label ,icon ="\U0001F9E9",tab_id =None ):
    mod_id =_caller_mod_id ()
    slug =_safe_command_name (tab_id or str (label ).lower ().replace (" ","_"))
    tid =slug or f"tab_{len (_LAUNCHER_TABS .get (mod_id ,{}))+1 }"
    tab =LauncherTab (mod_id ,tid ,str (label )[:32 ],str (icon )[:8 ])
    _LAUNCHER_TABS .setdefault (mod_id ,{})[tid ]=tab
    logger .info ("mod %s registered launcher tab %s",mod_id ,tid )
    return tab

def list_launcher_tabs_json ():
    out =[]
    for mod_id ,tabs in _LAUNCHER_TABS .items ():
        for tab in tabs .values ():
            out .append ({"modId":mod_id ,"id":tab .tab_id ,"label":tab .label ,"icon":tab .icon })
    return json .dumps (out ,ensure_ascii =False )

def open_launcher_tab_json (mod_id ,tab_id ,username ):
    safe_mod_id =_safe_command_name (mod_id )
    safe_tab_id =_safe_command_name (tab_id )
    tab =_LAUNCHER_TABS .get (safe_mod_id ,{}).get (safe_tab_id )if safe_mod_id and safe_tab_id else None
    if tab is None :
        return json .dumps ({"error":"unknown tab"})
    if tab ._on_open :
        try :
            tab .clear ()
            tab ._on_open (str (username or ""))
        except Exception :
            logger .exception ("launcher tab %s:%s on_open failed",safe_mod_id ,safe_tab_id )
            return json .dumps ({"error":"tab failed to open"})
    return json .dumps (_json_safe (tab .to_json ()),ensure_ascii =False )

def fire_launcher_callback_json (mod_id ,tab_id ,callback_id ,username ,value_json ):
    safe_mod_id =_safe_command_name (mod_id )
    safe_tab_id =_safe_command_name (tab_id )
    tab =_LAUNCHER_TABS .get (safe_mod_id ,{}).get (safe_tab_id )if safe_mod_id and safe_tab_id else None
    if tab is None :
        return json .dumps ({"error":"unknown tab"})
    if not isinstance (callback_id ,str )or not callback_id .startswith (f"{safe_mod_id }:"):
        logger .warning ("blocked cross-mod launcher callback %r for mod %s",callback_id ,safe_mod_id )
        return json .dumps ({"error":"invalid callback"})
    fn =_LAUNCHER_CALLBACKS .get (callback_id )
    if fn is None :
        return json .dumps ({"error":"unknown callback"})
    try :
        value =json .loads (value_json )if value_json else None
    except Exception :
        value =None
    try :
        fn (str (username or ""),value )
    except Exception :
        logger .exception ("launcher callback %s failed",callback_id )
        return json .dumps ({"error":"callback failed"})
    return json .dumps (_json_safe (tab .to_json ()),ensure_ascii =False )

def dispatch_action (action_name ,username ="",params =None ):
    runtime =_java_runtime ()
    safe_name =_safe_command_name (action_name )
    if not safe_name :
        logger .warning ("blocked invalid java mod action %r",action_name )
        return []
    if not runtime :
        logger .info ("java mod runtime unavailable for %s",safe_name )
        return []
    payload ={
    "action":safe_name ,
    "username":str (username or ""),
    "params":params if isinstance (params ,dict )else {},
    }
    try :
        logger .info ("dispatching java mod action %s params=%s",safe_name ,payload ["params"])
        raw_commands =runtime .callAction (safe_name ,json .dumps (payload ,ensure_ascii =False ))
        commands =json .loads (str (raw_commands or "[]"))
        logger .info ("java mod action %s returned %d command(s)",safe_name ,len (commands )if isinstance (commands ,list )else 0 )
        kwargs ={"username":str (username or ""),"command":safe_name ,"params":payload ["params"]}
        _apply_commands (kwargs ,commands )
        return consume_outgoing_frames (username )
    except Exception :
        logger .exception ("java mod action failed for %s",safe_name )
        return []

def has_action (action_name ):
    runtime =_java_runtime ()
    safe_name =_safe_command_name (action_name )
    if not runtime or not safe_name :
        return False
    try :
        return bool (runtime .hasAction (safe_name ))
    except Exception :
        logger .exception ("java mod action probe failed for %s",safe_name )
        return False

def _apply_commands (kwargs ,commands ):
    player_object =kwargs .get ("player_object")
    changed_properties =False
    username =str (kwargs .get ("username")or "")
    for command in commands or []:
        if not isinstance (command ,dict ):
            continue
        command_type =command .get ("type")
        if command_type =="send_frame":
            frame_command =_safe_command_name (command .get ("command"))
            payload =command .get ("payload")if isinstance (command .get ("payload"),dict )else {}
            if frame_command :
                _PENDING_FRAMES .setdefault (username ,[]).append ((frame_command ,payload ))
            else :
                logger .warning ("blocked invalid send_frame command %r",command .get ("command"))
            continue
        if command_type =="client_request":
            frame_command =_safe_command_name (command .get ("command"))
            payload =command .get ("params")if isinstance (command .get ("params"),dict )else {}
            if frame_command :
                logger .info ("java client request queued: %s params=%s",frame_command ,payload )
                _PENDING_FRAMES .setdefault (username ,[]).append ((frame_command ,payload ))
            else :
                logger .warning ("blocked invalid client_request command %r",command .get ("command"))
            continue
        if command_type =="run_server_handler":
            frame_command =_safe_command_name (command .get ("command"))
            payload =command .get ("params")if isinstance (command .get ("params"),dict )else {}
            if frame_command :
                try :
                    import msm_handlers
                    logger .info ("java mod requested server handler %s params=%s",frame_command ,payload )
                    _PENDING_FRAMES .setdefault (username ,[]).extend (msm_handlers .handle_command (frame_command ,payload ))
                except Exception :
                    logger .exception ("server handler command failed for %s",frame_command )
            else :
                logger .warning ("blocked invalid run_server_handler command %r",command .get ("command"))
            continue
        if command_type =="set_client_stage":
            stage =str (command .get ("stage")or "").strip ()
            if stage :
                _CLIENT_STAGES [username ]=stage
                logger .info ("java client stage for %s -> %s",username ,stage )
            continue
        if not isinstance (player_object ,dict ):
            continue
        currency =str (command .get ("currency")or "").strip ()
        if not currency :
            continue
        if command_type =="set_currency":
            set_currency (player_object ,currency ,command .get ("value",0 ))
            changed_properties =True
        elif command_type =="add_currency":
            add_currency (player_object ,currency ,command .get ("amount",0 ))
            changed_properties =True
    if changed_properties :
        _PENDING_PROPERTY_UPDATES .add (username )

def request_property_update (username ):
    key =str (username or "")
    if key :
        _PENDING_PROPERTY_UPDATES .add (key )

def consume_property_update (player_object ,username =""):
    key =str (username or "")
    if key not in _PENDING_PROPERTY_UPDATES :
        return None
    _PENDING_PROPERTY_UPDATES .discard (key )
    from msm_playerdata import create_player_properties
    return {"silent":True ,"properties":create_player_properties (player_object )}

def consume_outgoing_frames (username =""):
    return _PENDING_FRAMES .pop (str (username or ""),[])

def consume_lua_requests ():
    requests =[]
    for path in _LUA_REQUEST_PATHS :
        try :
            if not os .path .isfile (path ):
                continue
            with open (path ,"r",encoding ="utf-8")as fh :
                lines =fh .read ().splitlines ()
            try :
                open (path ,"w",encoding ="utf-8").close ()
            except Exception :
                try :
                    os .remove (path )
                except Exception :
                    pass
            for line in lines :
                line =line .strip ()
                if not line :
                    continue
                try :
                    item =json .loads (line )
                except Exception :
                    logger .warning ("blocked malformed lua request line from %s",path )
                    continue
                command =_safe_command_name (item .get ("command")if isinstance (item ,dict )else None )
                params =item .get ("params")if isinstance (item ,dict )and isinstance (item .get ("params"),dict )else {}
                if command :
                    requests .append ((command ,params ))
                else :
                    logger .warning ("blocked invalid lua request command from %s",path )
        except Exception :
            logger .exception ("failed to consume lua request queue %s",path )
    return requests

def consume_lua_logs ():
    for path in _LUA_LOG_PATHS :
        try :
            if not os .path .isfile (path ):
                continue
            with open (path ,"r",encoding ="utf-8")as fh :
                lines =fh .read ().splitlines ()
            try :
                open (path ,"w",encoding ="utf-8").close ()
            except Exception :
                try :
                    os .remove (path )
                except Exception :
                    pass
            for line in lines :
                if line .strip ():
                    logger .info ("lua print: %s",line )
        except Exception :
            logger .exception ("failed to consume lua log %s",path )

def client_stage (username =""):
    return _CLIENT_STAGES .get (str (username or ""),"")

def command_alias (command ):
    return _COMMAND_ALIASES .get (str (command or "").strip (),"")

def register_monster (monster_id ,definition ):
    from msm_gamedata import _all_monster_defs
    import msm_store
    validated =validate_monster_catalog_entry (dict (definition ))
    catalog =_all_monster_defs ()
    if monster_id in catalog :
        raise ModValidationError (f"monster_id {monster_id } already exists in the catalog")
    catalog [monster_id ]=validated

    raw =msm_store .load_db_json ("db_monster")
    if raw is not None :
        wire_entry =dict (validated )
        wire_entry ["monster_id"]=monster_id
        raw .setdefault ("monsters_data",[]).append (wire_entry )

def loaded_mods ():
    return list (_LOADED_MODS )

def get_load_errors_json ():
    return json .dumps (_LOAD_ERRORS )

def load_mods (mods_dir ):
    global _MOD_STATE_DIR
    _EVENT_HOOKS .clear ()
    _HUD_PROMPT_HANDLERS .clear ()
    _EVENT_HOOKS .setdefault ("command_received",[]).append (_dispatch_hud_prompt )
    _LAUNCHER_TABS .clear ()
    _LAUNCHER_CALLBACKS .clear ()
    _LOADED_MODS .clear ()
    _LOAD_ERRORS .clear ()
    _COMMAND_ALIASES .clear ()
    _MOD_STATE_DIR =os .path .join (os .path .dirname (mods_dir ),"mod_state")
    if not os .path .isdir (mods_dir ):
        return
    for entry in sorted (os .listdir (mods_dir )):
        mod_path =os .path .join (mods_dir ,entry )
        manifest_path =os .path .join (mod_path ,"mod.json")
        if not os .path .isfile (manifest_path ):
            continue
        manifest =None
        try :
            with open (manifest_path ,encoding ="utf-8")as fh :
                manifest =json .load (fh )
            if manifest .get ("min_bridge_api",1 )>BRIDGE_API_VERSION :
                logger .warning ("skipping %s: needs newer bridge API",entry )
                continue
            for asset_rel in manifest .get ("server",{}).get ("assets",[]):
                _apply_assets_file (os .path .join (mod_path ,asset_rel ))
            for patch_rel in manifest .get ("data_patches",[]):
                _apply_data_patch (os .path .join (mod_path ,patch_rel ))
            entry_rel =manifest .get ("entry")
            if entry_rel :
                _load_entry_script (os .path .join (mod_path ,entry_rel ),manifest ["id"])
            _LOADED_MODS .append (manifest )
            logger .info ("loaded mod %s v%s",manifest ["id"],manifest .get ("version"))
        except Exception :
            logger .exception ("failed to load mod %s",entry )
            mod_id =(manifest or {}).get ("id",entry )
            mod_name =(manifest or {}).get ("name",mod_id )
            _LOAD_ERRORS .append ({
                "modId":mod_id ,
                "modName":mod_name ,
                "detail":traceback .format_exc (),
            })
    _load_staged_assets (os .path .join (os .path .dirname (mods_dir ),"mod_assets"))

def _load_staged_assets (assets_root ):
    if not os .path .isdir (assets_root ):
        return
    for mod_id in sorted (os .listdir (assets_root )):
        mod_dir =os .path .join (assets_root ,mod_id )
        if not os .path .isdir (mod_dir ):
            continue
        _load_staged_server_scripts (mod_id ,mod_dir )
        for entry in sorted (os .listdir (mod_dir )):
            path =os .path .join (mod_dir ,entry )
            if os .path .isfile (path )and entry .lower ().endswith (".json"):
                try :
                    _apply_assets_file (path )
                except Exception :
                    logger .exception ("failed to apply staged asset %s",path )

def _load_staged_server_scripts (mod_id ,mod_dir ):
    python_dir =os .path .join (mod_dir ,"python")
    if os .path .isdir (python_dir ):
        for entry in sorted (os .listdir (python_dir )):
            path =os .path .join (python_dir ,entry )
            if os .path .isfile (path )and entry .lower ().endswith (".py"):
                try :
                    _load_entry_script (path ,mod_id )
                    logger .info ("loaded staged python mod %s from %s",mod_id ,entry )
                except Exception :
                    logger .exception ("failed to load staged python mod %s",path )
    lua_dir =os .path .join (mod_dir ,"lua")
    if os .path .isdir (lua_dir ):
        lua_files =[entry for entry in sorted (os .listdir (lua_dir ))if entry .lower ().endswith (".lua")]
        if lua_files :
            logger .warning ("server lua for %s is staged but not executed: no embedded server lua runtime",mod_id )

def _apply_assets_file (asset_path ):
    with open (asset_path ,encoding ="utf-8")as fh :
        asset =json .load (fh )
    if "monsters"in asset :
        _apply_data_patch (asset_path )
    db_patches =asset .get ("db_files")or asset .get ("db")or {}
    aliases =asset .get ("command_aliases")or {}
    if isinstance (aliases ,dict ):
        for source ,target in aliases .items ():
            safe_source =_safe_command_name (source )
            safe_target =_safe_command_name (target )
            if safe_source and safe_target :
                _COMMAND_ALIASES [safe_source ]=safe_target
                logger .info ("mod asset command alias %s -> %s",safe_source ,safe_target )
            else :
                logger .warning ("asset %s blocked invalid command alias %r -> %r",asset_path ,source ,target )
    strings =asset .get ("strings")or asset .get ("text")or {}
    if isinstance (strings ,dict )and strings :
        _apply_strings (strings ,asset_path )
    localization =asset .get ("localization")or asset .get ("localisation")or {}
    if isinstance (localization ,dict ):
        for locale ,locale_strings in localization .items ():
            if isinstance (locale_strings ,dict ):
                _apply_strings (locale_strings ,asset_path ,str (locale or ""))
    if not isinstance (db_patches ,dict ):
        logger .warning ("asset %s has invalid db_files",asset_path )
        return
    for raw_name ,patch_spec in db_patches .items ():
        db_name =str (raw_name or "").removesuffix (".json")
        if not _safe_command_name (db_name ):
            logger .warning ("asset %s blocked unsafe db name %r",asset_path ,raw_name )
            continue
        if isinstance (patch_spec ,dict )and ("data"in patch_spec or "mode"in patch_spec ):
            mode =str (patch_spec .get ("mode")or "inject").lower ()
            patch_data =patch_spec .get ("data")
        else :
            mode ="inject"
            patch_data =patch_spec
        _apply_db_patch (db_name ,patch_data ,mode ,asset_path )

def _apply_strings (strings ,asset_path ,locale =""):
    import msm_store
    safe_strings ={
    str (key ):str (value )
    for key ,value in strings .items ()
    if isinstance (key ,str )and key .strip ()and isinstance (value ,(str ,int ,float ,bool ))
    }
    if not safe_strings :
        return
    cache_key ="nps_strings"if not locale else f"nps_strings_{locale }"
    current =msm_store ._db_cache .get (cache_key )
    if not isinstance (current ,dict ):
        current ={}
        msm_store ._db_cache [cache_key ]=current
    current .update (safe_strings )

    injected =False
    for db_name in ("db_strings","db_string","db_text","db_locale","db_localization","db_languages","db_translations"):
        data =msm_store .load_db_json (db_name )
        if not isinstance (data ,dict ):
            continue
        target =None
        for key in ("strings","text","data","translations"):
            if isinstance (data .get (key ),dict ):
                target =data [key ]
                break
        if target is None :
            target =data
        target .update (safe_strings )
        _invalidate_game_caches (db_name )
        injected =True
    logger .info ("mod asset loaded %d string(s)%s from %s%s",
    len (safe_strings ),
    f" for {locale }"if locale else "",
    asset_path ,
    " into text db cache"if injected else " into nps string cache")

def _apply_db_patch (db_name ,patch_data ,mode ,asset_path ):
    import msm_store
    if not isinstance (patch_data ,(dict ,list )):
        logger .warning ("asset %s ignored %s: patch data must be object or array",asset_path ,db_name )
        return
    patch_data =_validate_db_patch (db_name ,patch_data ,asset_path )
    if patch_data is None :
        return
    current =msm_store .load_db_json (db_name )
    if mode =="replace":
        msm_store ._db_cache [db_name ]=patch_data
        _invalidate_game_caches (db_name )
        logger .info ("mod asset replaced %s from %s",db_name ,asset_path )
        return
    if current is None :
        logger .warning ("asset %s cannot inject %s: db file does not exist",asset_path ,db_name )
        return
    if isinstance (current ,dict )and isinstance (patch_data ,dict ):
        _deep_inject (current ,patch_data )
        _invalidate_game_caches (db_name )
        logger .info ("mod asset injected %s from %s",db_name ,asset_path )
    elif isinstance (current ,list )and isinstance (patch_data ,list ):
        _merge_list (current ,patch_data )
        _invalidate_game_caches (db_name )
        logger .info ("mod asset appended %s from %s",db_name ,asset_path )
    else :
        logger .warning ("asset %s cannot inject %s: type mismatch",asset_path ,db_name )

def _deep_inject (target ,patch ):
    for key ,value in patch .items ():
        if key in target and isinstance (target [key ],dict )and isinstance (value ,dict ):
            _deep_inject (target [key ],value )
        elif key in target and isinstance (target [key ],list )and isinstance (value ,list ):
            _merge_list (target [key ],value )
        else :
            target [key ]=value

def _validate_db_patch (db_name ,patch_data ,asset_path ):
    try :
        if db_name .startswith ("db_monster")and isinstance (patch_data ,dict ):
            entries =patch_data .get ("monsters_data")
            if isinstance (entries ,list ):
                import msm_store
                current =msm_store .load_db_json (db_name )or {}
                existing_ids ={
                entry .get ("monster_id")
                for entry in current .get ("monsters_data",[])
                if isinstance (entry ,dict )
                }
                patch_data =dict (patch_data )
                patched =[]
                for entry in entries :
                    if not isinstance (entry ,dict ):
                        continue
                    if entry .get ("monster_id")in existing_ids :
                        patched .append (dict (entry ))
                    else :
                        patched .append (validate_monster_catalog_entry (dict (entry )))
                patch_data ["monsters_data"]=patched
        if db_name =="db_island_v2"and isinstance (patch_data ,dict ):
            entries =patch_data .get ("islands_data")
            if isinstance (entries ,list ):
                import msm_store
                current =msm_store .load_db_json (db_name )or {}
                existing_ids ={
                entry .get ("island_type")
                for entry in current .get ("islands_data",[])
                if isinstance (entry ,dict )
                }
                patch_data =dict (patch_data )
                patched =[]
                for entry in entries :
                    if not isinstance (entry ,dict ):
                        continue
                    if entry .get ("island_type")in existing_ids :
                        patched .append (dict (entry ))
                    else :
                        patched .append (validate_island_entry (dict (entry )))
                patch_data ["islands_data"]=patched
        return patch_data
    except ModValidationError as exc :
        logger .warning ("asset %s rejected %s patch: %s",asset_path ,db_name ,exc )
        return None

_ARRAY_ID_KEYS =("monster_id","island_type","structure_id","entity_id","id","database_id")

def _merge_list (target ,patch ):
    for item in patch :
        if isinstance (item ,dict ):
            key =next ((k for k in _ARRAY_ID_KEYS if item .get (k )is not None ),None )
            if key :
                existing =next ((entry for entry in target if isinstance (entry ,dict )and entry .get (key )==item .get (key )),None )
                if isinstance (existing ,dict ):
                    _deep_inject (existing ,item )
                    continue
        target .append (item )

def _invalidate_game_caches (db_name ):
    try :
        import msm_gamedata
        msm_gamedata .reset_caches (db_name )
    except Exception :
        logger .exception ("failed to reset game caches for %s",db_name )

def _apply_data_patch (patch_path ):
    with open (patch_path ,encoding ="utf-8")as fh :
        patch =json .load (fh )
    for monster_id_str ,definition in patch .get ("monsters",{}).items ():
        register_monster (int (monster_id_str ),definition )

def _load_entry_script (script_path ,mod_id ):
    spec =importlib .util .spec_from_file_location (f"mod_{mod_id }",script_path )
    module =importlib .util .module_from_spec (spec )
    module .__mod_id__ =mod_id
    spec .loader .exec_module (module )
