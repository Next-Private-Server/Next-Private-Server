import json
import logging
import random
import time

from msm_cardalbum import _grant_packs
import msm_gamedata
import msm_toggles
from msm_gamedata import get_monster_definition ,get_monster_id_for_entity_id ,get_structure_definition
from msm_playerdata import (
append_inventory_property ,create_player_properties ,find_island ,grant_inventory_item ,
island_type_of ,load_player ,save_player ,
)
from msm_protocol import SFSLong ,SFSIntArray
from msm_store import load_db_json ,normalize_db_payload

def _clubbox_open ():
    return msm_toggles .is_time_window_active (
    "clubbox_enabled","clubbox_hours_enabled","clubbox_start_hour","clubbox_end_hour")

logger =logging .getLogger ("msm.clubbox")

DEFAULT_ISLAND_UID =1001
DEFAULT_ACT_ID =4

_ACT_EVENT_WINDOW_MS =1382400000

CELESTIAL_VESSEL_ENTITY_IDS =(550 ,551 ,552 ,553 ,554 ,555 ,556 ,559 ,574 ,575 ,576 ,579 )
_CELESTIAL_ROTATION_WINDOW_SECONDS =60
def _current_celestial_entity_id ():
    slot =int (time .time ()//_CELESTIAL_ROTATION_WINDOW_SECONDS )%len (CELESTIAL_VESSEL_ENTITY_IDS )
    return CELESTIAL_VESSEL_ENTITY_IDS [slot ]
_ALWAYS_OPEN_EVENT_END_DATE =4102444800000

def _current_act_event_start_date ():

    now =int (time .time ()*1000 )
    return now -(now %_ACT_EVENT_WINDOW_MS )

def _current_act_event_end_date ():
    return _current_act_event_start_date ()+_ACT_EVENT_WINDOW_MS

LOOT_TYPE_CODES ={"BUFF":14 ,"CLUBBOX_UNLOCK":17 }

CARD_PACK_TYPE_CODE =18
COSTUME_TYPE_CODE =13
CURRENCY_TYPE_CODE =16
MONSTER_TYPE_CODE =11

CURRENCY_LOOT_KEYS =(
"coins","food","diamonds","relics","keys",
"ethereal_currency","starpower","clubbox_tokens",
)

_cache ={}

def _safe_int (value ,default =0 ):
    try :
        return int (value )
    except (TypeError ,ValueError ,OverflowError ):
        return default

def backfill_clubbox_unlock (player_object ):

    if not player_object .get ("clubbox_unlock"):
        player_object ["clubbox_unlock"]=True
    _ensure_clubboxes (player_object )

    if _safe_int (player_object .get ("last_clubbox"))<=0 :
        player_object ["last_clubbox"]=_current_act_id (player_object )

def _resolve_island_type_uid (player_object ,island_type ):

    candidates =[
    isl for isl in (player_object .get ("islands")or [])
    if isl is not None and _safe_int (island_type_of (isl ))==island_type
    ]
    if not candidates :
        return 1000 +island_type
    primary =[isl for isl in candidates if 1000 <=_safe_int (isl .get ("user_island_id"))<1100 ]
    chosen =primary [0 ]if primary else candidates [0 ]
    return _safe_int (chosen .get ("user_island_id"),1000 +island_type )

def _active_island_uid (player_object ,params ):
    for key in ("island_uid","user_island_id"):
        value =params .get (key )
        if value :
            return _safe_int (value ,DEFAULT_ISLAND_UID )

    island_id =params .get ("island_id")
    if island_id :
        return _resolve_island_type_uid (player_object ,_safe_int (island_id ))
    return _safe_int (player_object .get ("active_island"),DEFAULT_ISLAND_UID )

def _empty_clubbox ():
    return {
    "act":-1 ,
    "clubbox_data":{
    "island":SFSLong (DEFAULT_ISLAND_UID ),
    "top_hype":0 ,
    "hype":0 ,
    "started_at":SFSLong (_current_act_event_start_date ()),
    "top_hype_at_start":0 ,

    "props_active":[],
    },
    }

def _normalize_clubbox_data (data ,act_id ,player_object ,tokens =None ):
    hype =max (0 ,_safe_int (data .get ("hype")))
    top_hype =max (_safe_int (data .get ("top_hype")),hype )
    data ["hype"]=hype
    data ["top_hype"]=top_hype
    data ["top_hype_at_start"]=_safe_int (data .get ("top_hype_at_start"))
    if act_id >0 and _safe_int (data .get ("island"))<1 :
        data ["island"]=SFSLong (_safe_int (player_object .get ("active_island"))or DEFAULT_ISLAND_UID )
    if act_id ==_current_act_id (player_object ):
        data ["started_at"]=SFSLong (_current_act_event_start_date ())
        data ["clubbox_tokens"]=_clubbox_tokens (player_object )if tokens is None else max (0 ,_safe_int (tokens ))
    elif act_id >0 :
        existing_started_at =_safe_int (data .get ("started_at"))
        data ["started_at"]=SFSLong (existing_started_at if existing_started_at >0 else _current_act_event_start_date ())
        if _safe_int (data .get ("island"))<1 :
            data ["island"]=SFSLong (_safe_int (player_object .get ("active_island"))or DEFAULT_ISLAND_UID )
    else :
        data ["island"]=SFSLong (DEFAULT_ISLAND_UID )
        data ["started_at"]=SFSLong (_current_act_event_start_date ())
    if "props_active"in data and not isinstance (data .get ("props_active"),list ):
        data ["props_active"]=[]
    return data

def _ensure_clubboxes (player_object ):
    clubboxes =player_object .get ("clubboxes")
    if not isinstance (clubboxes ,list ):
        clubboxes =[]
    if not any (box .get ("act")==-1 for box in clubboxes if isinstance (box ,dict )):
        clubboxes .insert (0 ,_empty_clubbox ())

    current_act =_current_act_id (player_object )
    for act_id in range (1 ,current_act +1 ):
        if not any (box .get ("act")==act_id for box in clubboxes if isinstance (box ,dict )):
            box =_empty_clubbox ()
            box ["act"]=act_id
            clubboxes .append (box )

    for box in clubboxes :
        if not isinstance (box ,dict ):
            continue
        act_id =_safe_int (box .get ("act"))
        data =box .get ("clubbox_data")
        if not isinstance (data ,dict ):
            data ={}
            box ["clubbox_data"]=data
        _normalize_clubbox_data (data ,act_id ,player_object )

    clubboxes .sort (key =lambda box :box .get ("act",0 )if isinstance (box ,dict )else 0 )
    player_object ["clubboxes"]=clubboxes
    return clubboxes

_KNOWN_CLUBBOX_DATA_KEYS =(
"island","top_hype","hype","started_at","top_hype_at_start",
"props_active","clubbox_tokens",
)

def _sanitize_clubboxes_for_wire (clubboxes ):
    sanitized =[]
    for box in clubboxes :
        if not isinstance (box ,dict ):
            continue
        data =box .get ("clubbox_data")or {}
        clean_data ={k :v for k ,v in data .items ()if k in _KNOWN_CLUBBOX_DATA_KEYS }
        sanitized .append ({"act":box .get ("act"),"clubbox_data":clean_data })
    return sanitized

def _find_act_box (clubboxes ,act ):
    for box in clubboxes :
        if isinstance (box ,dict )and box .get ("act")==act :
            data =box .setdefault ("clubbox_data",{})
            if not isinstance (data ,dict ):
                box ["clubbox_data"]={}
            return box
    return None

def _clubbox_tokens (player_object ):
    return max (0 ,_safe_int (
    player_object .get ("clubbox_tokens_actual",player_object .get ("clubbox_tokens",0 ))
    ))

def _set_clubbox_tokens (player_object ,value ):
    value =max (0 ,_safe_int (value ))
    player_object ["clubbox_tokens"]=value
    player_object ["clubbox_tokens_actual"]=value
    return value

def _hype_game_wheels ():
    if "hype_wheels"not in _cache :
        raw =msm_gamedata ._user_game_settings ().get ("USER_HYPE_GAME_PROBS")
        try :
            wheels =json .loads (raw )if raw else []
        except (TypeError ,ValueError ):
            wheels =[]
        by_id ={w .get ("wheel"):w for w in wheels if isinstance (w ,dict )}
        _cache ["hype_wheels"]=by_id
    return _cache ["hype_wheels"]

def _roll_wheel (wheel_id ,fallback_values ,fallback_probs ):
    wheel =_hype_game_wheels ().get (wheel_id )or {}
    values =wheel .get ("values")or fallback_values
    probs =wheel .get ("probs")or fallback_probs
    return random .choices (values ,weights =probs ,k =1 )[0 ]

def _acts ():
    if "acts"not in _cache :
        data =load_db_json ("db_clubbox_acts")or {}
        _cache ["acts"]={a ["id"]:a for a in (data .get ("clubbox_act_data")or [])if "id"in a }
    return _cache ["acts"]

def _current_act_id (player_object =None ):

    if player_object is not None :
        selected =_safe_int (player_object .get ("last_clubbox"))
        if selected >0 and selected in _acts ():
            return selected
    acts =_acts ()
    if not acts :
        return DEFAULT_ACT_ID
    return max (acts .values (),key =lambda a :_safe_int (a .get ("last_changed"))).get ("id",DEFAULT_ACT_ID )

def db_clubbox_acts (username ,params ):

    data =load_db_json ("db_clubbox_acts")or {}
    data =json .loads (json .dumps (data ))
    for act in data .get ("clubbox_act_data")or []:
        act_data =act .get ("data")if isinstance (act ,dict )else None
        if not isinstance (act_data ,dict ):
            continue
        for level in act_data .get ("zoom_levels")or []:
            if not isinstance (level ,dict ):
                continue
            if isinstance (level .get ("c"),list ):
                level ["c"]=SFSIntArray (level ["c"])

            if "z"in level :
                level ["z"]=float (level ["z"])if not isinstance (level ["z"],dict )else level ["z"]
    return normalize_db_payload ("db_clubbox_acts",data )

def gs_timed_events (username ,params ):
    data =dict (load_db_json ("gs_timed_events")or {})
    events =list (data .get ("timed_event_list")or [])
    _ ,player_object =load_player (username )
    act_id =_current_act_id (player_object )
    events =[
    e for e in events
    if str (e .get ("event_type",""))!="ClubboxAvailability"
    ]

    start_date =_current_act_event_start_date ()
    if _clubbox_open ():
        events .append ({
        "end_date":_current_act_event_end_date (),
        "last_updated":start_date ,
        "event_type":"ClubboxAvailability",
        "event_id":33 ,
        "data":[{"act":act_id ,"min_client_ver":"5.5.0","label":"DEFAULT"}],
        "id":82451 ,
        "start_date":start_date ,
        })

    events =[
    e for e in events
    if str (e .get ("event_type",""))!="EvolveAvailability"
    ]
    for _offset ,_entity_id in enumerate (CELESTIAL_VESSEL_ENTITY_IDS ):
        events .append ({
        "end_date":_ALWAYS_OPEN_EVENT_END_DATE ,
        "last_updated":0 ,
        "event_type":"EvolveAvailability",
        "event_id":17 ,
        "data":[{"from_entity":_entity_id }],
        "id":79483 +_offset ,
        "start_date":0 ,
        })

    from msm_cardalbum import card_album_window
    album_start ,album_end =card_album_window ()
    for e in events :
        if str (e .get ("event_type",""))=="CardAlbum":
            e ["start_date"]=album_start
            e ["end_date"]=album_end
            e ["last_updated"]=album_start
            for row in (e .get ("data")or []):
                if isinstance (row ,dict ):
                    row .setdefault ("min_client_ver","5.4.2")
                    row .setdefault ("label","Sticker Book %s"%row .get ("card_album_id"))

    data ["timed_event_list"]=events
    return normalize_db_payload ("gs_timed_events",data )

_costume_defs_cache =None
def _costume_definition (costume_id ):
    global _costume_defs_cache
    if _costume_defs_cache is None :
        defs ={}
        for db_name in ("db_costumes","db_costumes_2"):
            data =load_db_json (db_name )or {}
            for c in data .get ("costume_data")or []:
                cid =c .get ("id")
                if cid is not None :
                    defs [cid ]=c
        _costume_defs_cache =defs
    return _costume_defs_cache .get (costume_id )

def _reward_track_level_groups (reward_track_id ):
    key =f"groups_{reward_track_id }"
    if key not in _cache :
        data =load_db_json ("db_reward_tracks")or {}
        by_level ={}
        for track in data .get ("reward_tracks_data")or []:
            if track .get ("id")!=reward_track_id :
                continue
            for lv in track .get ("levels")or []:
                level_num =_safe_int (lv .get ("level"))
                by_level .setdefault (level_num ,[]).append (lv )
            break
        for entries in by_level .values ():
            entries .sort (key =lambda lv :_safe_int (lv .get ("points")))
        groups =[(num ,by_level [num ])for num in sorted (by_level .keys ())]
        _cache [key ]=groups
    return _cache [key ]

def _parse_loot_json (raw ):
    if not raw :
        return {}
    if isinstance (raw ,dict ):
        return raw
    try :
        parsed =json .loads (raw )
    except (TypeError ,ValueError ):
        return {}
    return parsed if isinstance (parsed ,dict )else {}

def _reward_thresholds (reward_track_id ):
    key =f"thresholds_{reward_track_id }"
    if key not in _cache :
        cumulative =0
        rows =[]
        for _num ,entries in _reward_track_level_groups (reward_track_id ):
            level_total =0
            for entry in entries :
                points =_safe_int (entry .get ("points"))
                level_total =max (level_total ,points )
                rows .append ((cumulative +points ,entry ))
            cumulative +=level_total
        _cache [key ]=(rows ,cumulative )
    return _cache [key ]

def _rewards_crossed (reward_track_id ,old_hype ,new_hype ):
    rows ,lap_total =_reward_thresholds (reward_track_id )
    if not rows or lap_total <=0 or new_hype <=old_hype :
        return []
    crossed =[]
    first_lap =old_hype //lap_total
    last_lap =new_hype //lap_total
    for lap in range (first_lap ,min (last_lap ,first_lap +50 )+1 ):
        for cumulative ,entry in rows :
            absolute =lap *lap_total +cumulative
            if old_hype <absolute <=new_hype :
                if lap >0 :
                    crossed .append (entry .get ("prestige_loot")or entry .get ("loot"))
                else :
                    crossed .append (entry .get ("loot"))
    return crossed

def _grant_free_monster_inventory (player_object ,entity_id ):
    monster_id =get_monster_id_for_entity_id (entity_id )
    definition =get_monster_definition (monster_id )or {}
    inventory_entity_id =_safe_int (definition .get ("entity_id"))
    if inventory_entity_id <=0 :
        return False
    return grant_inventory_item (player_object ,inventory_entity_id ,1 )

def _clubbox_monster_reward_entry (entity_id ):
    return {
    "amount":1 ,"premium":False ,"scaled":False ,"scale":False ,
    "id":entity_id ,"type":MONSTER_TYPE_CODE ,
    }

def _apply_and_format_loot (player_object ,island ,loot_dict ,granted_card_pack ,granted_costume ,granted_inventory ):
    entries =[]
    for key ,value in loot_dict .items ():
        if key in CURRENCY_LOOT_KEYS :
            amount =_safe_int (value )

            entry_id =1 if key =="clubbox_tokens"else 0
            if key =="clubbox_tokens":
                _set_clubbox_tokens (player_object ,_clubbox_tokens (player_object )+amount )
            else :
                player_object [key ]=_safe_int (player_object .get (key ))+amount
            entries .append ({
            "amount":amount ,"premium":False ,"id":entry_id ,
            "type":CURRENCY_TYPE_CODE ,
            })
        elif key .startswith ("card_pack"):
            if "."in key :
                pack_type =_safe_int (key .split (".",1 )[1 ],1 )or 1
                amount =max (1 ,_safe_int (value ,1 ))
            else :
                pack_type =max (1 ,_safe_int (value ,1 ))
                amount =1
            _grant_packs (player_object ,amount ,pack_type )
            granted_card_pack [0 ]=True
            entries .append ({
            "amount":amount ,"premium":False ,"id":pack_type ,
            "type":CARD_PACK_TYPE_CODE ,"extra":{"pack_type":pack_type },
            })
        elif key =="buff"and isinstance (value ,dict ):
            entry =dict (value )
            entry ["type"]=LOOT_TYPE_CODES .get (str (entry .get ("type","")).upper (),14 )
            entry .setdefault ("amount",1 )
            entry .setdefault ("premium",False )
            entries .append (entry )
        elif key =="clubbox_unlock"and isinstance (value ,dict ):
            unlock_id =value .get ("id")
            unlocks =player_object .setdefault ("clubbox_unlocks",[])
            if unlock_id is not None and unlock_id not in unlocks :
                unlocks .append (unlock_id )
            entries .append ({
            "amount":1 ,"premium":False ,"id":unlock_id ,
            "type":LOOT_TYPE_CODES .get (str (value .get ("type","")).upper (),17 ),
            "extra":value .get ("extra",{}),
            })
        elif key =="costume":

            granted_costume [0 ]=True
            for costume_id in (value if isinstance (value ,list )else [value ]):
                entries .append ({
                "amount":1 ,"premium":False ,"id":_safe_int (costume_id ),
                "type":COSTUME_TYPE_CODE ,"extra":{},
                })
        elif key =="monster":
            entity_id =_safe_int (value )
            if entity_id and _grant_free_monster_inventory (player_object ,entity_id ):
                granted_inventory [0 ]=True
            if entity_id :
                entries .append (_clubbox_monster_reward_entry (entity_id ))
        elif key .startswith ("structure."):

            structure_id =_safe_int (key .split (".",1 )[1 ])
            if structure_id :
                unlocked_structures =player_object .setdefault ("clubbox_unlocked_structures",[])
                if structure_id not in unlocked_structures :
                    unlocked_structures .append (structure_id )
            entries .append ({
            "amount":1 ,"premium":False ,"id":structure_id ,
            "type":COSTUME_TYPE_CODE ,"extra":{},
            })
        elif key =="sfs_object"and isinstance (value ,dict ):

            if str (value .get ("type","")).upper ()=="MONSTER":
                entity_id =_safe_int (value .get ("id"))
                if entity_id :
                    if _grant_free_monster_inventory (player_object ,entity_id ):
                        granted_inventory [0 ]=True
                    entries .append (_clubbox_monster_reward_entry (entity_id ))
    return entries

def set_last_act (username ,params ):
    root ,player_object =load_player (username )
    raw =params .get ("act_id",params .get ("act"))

    resolved =_safe_int (raw )
    act_id =resolved if resolved >0 and resolved in _acts ()else _current_act_id (player_object )
    player_object ["last_clubbox"]=act_id
    player_object ["clubbox_act_override"]=act_id
    clubboxes =_ensure_clubboxes (player_object )
    save_player (username ,root )
    return {
    "success":True ,"act_id":act_id ,
    "properties":[{"clubboxes":_sanitize_clubboxes_for_wire (clubboxes )}]+create_player_properties (player_object ),
    }

def create_clubbox (username ,params ):
    if not _clubbox_open ():
        return {"success":False ,"message":"Clubbox is currently closed."}
    root ,player_object =load_player (username )
    act_id =_current_act_id (player_object )
    island_uid =_active_island_uid (player_object ,params )

    tokens =_clubbox_tokens (player_object )
    _set_clubbox_tokens (player_object ,tokens )
    clubboxes =_ensure_clubboxes (player_object )
    box =_find_act_box (clubboxes ,act_id )
    is_new_box =box is None
    if box is None :
        box ={"act":act_id ,"clubbox_data":{}}
        clubboxes .append (box )

    box ["clubbox_data"].setdefault ("props_active",[])
    box ["clubbox_data"].update ({
    "island":SFSLong (island_uid ),
    "clubbox_tokens":tokens ,
    })
    _normalize_clubbox_data (box ["clubbox_data"],act_id ,player_object ,tokens )
    player_object ["last_clubbox"]=act_id
    player_object ["clubbox_unlock"]=True
    save_player (username ,root )

    result ={
    "success":True ,"act_id":act_id ,"island_uid":island_uid ,
    "properties":[
    {"clubbox_tokens_actual":tokens },
    {"clubboxes":_sanitize_clubboxes_for_wire (clubboxes )},
    ],
    }
    return result

def move_clubbox (username ,params ):
    root ,player_object =load_player (username )
    act_id =_current_act_id (player_object )
    island_uid =_active_island_uid (player_object ,params )
    clubboxes =_ensure_clubboxes (player_object )
    box =_find_act_box (clubboxes ,act_id )
    if box is not None :
        data =box .setdefault ("clubbox_data",{})
        data ["island"]=SFSLong (island_uid )
        _normalize_clubbox_data (data ,act_id ,player_object )
        save_player (username ,root )
    properties =[{"diamonds_actual":_safe_int (player_object .get ("diamonds"))},{"clubboxes":_sanitize_clubboxes_for_wire (clubboxes )}]
    return {
    "success":True ,
    "island_uid":island_uid ,
    "properties":properties ,
    }

def hype_game (username ,params ):
    if not _clubbox_open ():
        return {"success":False ,"message":"Clubbox is currently closed."}
    root ,player_object =load_player (username )
    act_id =_current_act_id (player_object )
    clubboxes =_ensure_clubboxes (player_object )
    box =_find_act_box (clubboxes ,act_id )
    if box is None :
        create_clubbox (username ,params )
        root ,player_object =load_player (username )
        clubboxes =_ensure_clubboxes (player_object )
        box =_find_act_box (clubboxes ,act_id )
    data =box .setdefault ("clubbox_data",{})

    _normalize_clubbox_data (data ,act_id ,player_object )

    available_tokens =_clubbox_tokens (player_object )
    if available_tokens <=0 :

        result ={"success":False ,"message":"Not enough clubbox tokens."}
        result ["properties"]=create_player_properties (player_object )
        return result
    token_amount =max (1 ,_safe_int (params .get ("token_amount"),1 ))
    token_amount =min (token_amount ,available_tokens )
    base_points =_roll_wheel (1 ,[20 ,40 ,80 ],[50 ,37.5 ,12.5 ])
    multiplier =_roll_wheel (2 ,[1 ,3 ,5 ],[50 ,37.5 ,12.5 ])
    points =base_points *token_amount
    hype_delta =points *multiplier
    old_hype =_safe_int (data .get ("hype"))
    hype =old_hype +hype_delta
    top_hype =max (_safe_int (data .get ("top_hype")),hype )
    data ["hype"]=hype
    data ["top_hype"]=top_hype

    tokens =max (0 ,available_tokens -token_amount )
    _set_clubbox_tokens (player_object ,tokens )
    _normalize_clubbox_data (data ,act_id ,player_object ,tokens )

    act =_acts ().get (act_id )or {}
    reward_track_id =(act .get ("data")or {}).get ("reward_track_id")
    loot_entries =[]
    granted_card_pack =[False ]
    granted_costume =[False ]
    granted_inventory =[False ]
    if reward_track_id is not None :
        island =find_island (player_object ,_active_island_uid (player_object ,params ))
        for loot_source in _rewards_crossed (reward_track_id ,old_hype ,hype ):
            loot_entries .extend (
            _apply_and_format_loot (
            player_object ,island ,_parse_loot_json (loot_source ),
            granted_card_pack ,granted_costume ,granted_inventory ,
            )
            )

    save_player (username ,root )

    hype_event ={
    "updateTimedEvents":True ,
    "act":act_id ,
    "points":points ,
    "top_hype":top_hype ,
    "hype":hype ,
    "loot":loot_entries ,
    }
    if granted_card_pack [0 ]:
        hype_event ["updateCardAlbum"]=True
    if granted_costume [0 ]:
        hype_event ["updateCostumes"]=True
        hype_event ["updateCostumesIsland"]=_active_island_uid (player_object ,params )
    if granted_inventory [0 ]:
        hype_event ["updateInventory"]=True
    properties =[
    {"clubbox_tokens_actual":tokens },
    {"hype_event":hype_event },
    {"clubboxes":_sanitize_clubboxes_for_wire (clubboxes )},
    ]
    properties .extend (create_player_properties (player_object ))
    if granted_card_pack [0 ]:
        from msm_cardalbum import _card_albums_properties
        properties .extend (_card_albums_properties (player_object ))
    if granted_inventory [0 ]:
        append_inventory_property (properties ,player_object )
    return {
    "success":True ,
    "multiplier":multiplier ,
    "hype":hype_delta ,
    "tokens":token_amount ,
    "properties":properties ,
    "points":points ,
    }
