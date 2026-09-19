import json
import struct
import time

from msm_playerdata import create_player_properties ,find_island ,get_active_island_id ,island_type_of ,load_player ,save_player
from msm_protocol import SFSFloat
from msm_store import load_db_json

def _decode_wire_number (value ,default =0.0 ):
    if isinstance (value ,dict ):
        hex_bits =value .get ("__double_bits")
        if hex_bits is not None :
            try :
                return struct .unpack (">d",bytes .fromhex (str (hex_bits ).removeprefix ("0x")))[0 ]
            except (ValueError ,TypeError ,struct .error ):
                return default
        hex_bits =value .get ("__float_bits")
        if hex_bits is not None :
            try :
                return struct .unpack (">f",bytes .fromhex (str (hex_bits ).removeprefix ("0x"))[-4 :])[0 ]
            except (ValueError ,TypeError ,struct .error ):
                return default
        return default
    try :
        return float (value )
    except (TypeError ,ValueError ):
        return default

CURRENCY_LOOT_KEYS ={"coins","diamonds","food","relics","keys","ethereal_currency","starpower","clubbox_tokens",
"egg_wildcards","medals","xp"}

_LOOT_WIRE_TYPES ={
"coins":4 ,"food":7 ,"keys":16 ,"ethereal_currency":5 ,
"diamonds":9 ,"relics":8 ,"starpower":16 ,"clubbox_tokens":16 ,
"card_pack":18 ,"monster":11 ,
}

def _wire_loot_item (item ):
    resource =item .get ("resource")
    amount =item .get ("amount",0 )
    if resource =="card_pack":
        pack_type =item .get ("pack_type",1 )or 1
        return {"amount":amount ,"premium":False ,"scaled":False ,"scale":False ,"id":pack_type ,
        "type":_LOOT_WIRE_TYPES ["card_pack"],"extra":{"pack_type":pack_type }}
    if resource =="monster":
        return {"amount":1 ,"premium":False ,"scaled":False ,"scale":False ,
        "id":amount ,"type":_LOOT_WIRE_TYPES ["monster"]}
    return {"amount":amount ,"premium":False ,"scaled":False ,"scale":False ,
    "id":1 ,
    "type":_LOOT_WIRE_TYPES .get (resource ,1 )}

ENCORE_SECONDS_PER_POINT =900.0
def points_for_duration (seconds ):

    return max (0.0 ,float (seconds or 0 ))/ENCORE_SECONDS_PER_POINT

_cache ={}

def _reward_tracks ():
    if "tracks"not in _cache :
        data =load_db_json ("db_reward_tracks")or {}
        tracks ={}
        for t in data .get ("reward_tracks_data")or []:
            tid =t .get ("id")
            if tid is not None :
                tracks [tid ]=t
        _cache ["tracks"]=tracks
    return _cache ["tracks"]

_ENCORE_EVENT_ID =82688
_ENCORE_TRACK_ID =2
_ENCORE_WINDOW_MS =1036800000

def _encore_window_start ():
    now =int (time .time ()*1000 )
    return now -(now %_ENCORE_WINDOW_MS )

def _encore_window_end ():
    return _encore_window_start ()+_ENCORE_WINDOW_MS

def encore_timed_event_entry ():
    start =_encore_window_start ()
    return {
    "end_date":_encore_window_end (),"last_updated":start ,
    "event_type":"Encore","event_id":34 ,
    "data":[{"rolls_over":True ,"encore_type":0 ,"reward_track_id":_ENCORE_TRACK_ID ,"label":"Encore - Breeding"}],
    "id":_ENCORE_EVENT_ID ,"start_date":start ,
    }

def active_encore_event ():
    return None ,None

def player_encore_state (username ,params ):
    root ,player_object =load_player (username )
    event_id ,track_id =active_encore_event ()
    event_id =event_id or 0
    state =_ensure_encore_state (player_object ,event_id )
    _repair_claimed_gaps (player_object ,_reward_tracks ().get (track_id ))
    save_player (username ,root )
    return {"success":True ,"current_encore_state":state }

def _ensure_encore_state (player_object ,event_id ):
    state =player_object .get ("current_encore_state")
    if not isinstance (state ,dict )or state .get ("event_id")!=event_id :
        state ={"event_id":event_id ,"total_points":0.0 }
        player_object ["current_encore_state"]=state
    return state

def _level_sort_key (lv ):
    return (lv .get ("level",0 )or 0 ,lv .get ("points",0 )or 0 )

def _current_level_number (track ,claimed ):
    levels =sorted (track .get ("levels")or [],key =_level_sort_key )if track else []
    for lv in levels :
        if lv .get ("id")not in claimed :
            return lv .get ("level",1 )or 1
    return (levels [-1 ].get ("level",1 )or 1 )if levels else 1

def _sync_encore_player_fields (player_object ,track_id ,total_points ,track =None ):
    player_object ["encore_points"]=SFSFloat (total_points )
    if track is None :
        track =_reward_tracks ().get (track_id )
    player_object ["encore_level"]=_current_level_number (track ,_claimed_ids (player_object ))
    player_object ["encore_tutorial"]=(track_id ==1 )

def _next_unclaimed_level (track ,claimed ):
    if not track :
        return None
    levels =sorted (track .get ("levels")or [],key =_level_sort_key )
    for lv in levels :
        if lv .get ("id")not in claimed :
            return lv
    return None

def _repair_claimed_gaps (player_object ,track ):
    if not track :
        return
    levels =sorted (track .get ("levels")or [],key =_level_sort_key )
    if not levels :
        return
    claimed =_claimed_ids (player_object )
    if not claimed :
        return
    last_claimed_rank =-1
    for i ,lv in enumerate (levels ):
        if lv .get ("id")in claimed :
            last_claimed_rank =i
    if last_claimed_rank <0 :
        return
    healed =set (claimed )
    changed =False
    for lv in levels [:last_claimed_rank +1 ]:
        level_id =lv .get ("id")
        if level_id is not None and level_id not in healed :
            healed .add (level_id )
            changed =True
    if changed :
        player_object ["encore_claimed_levels"]=sorted (healed )

def _grant_all_eligible_levels (player_object ,track ,points ):
    _repair_claimed_gaps (player_object ,track )
    all_loot =[]
    while True :
        next_level =_next_unclaimed_level (track ,_claimed_ids (player_object ))
        if next_level is None :
            break
        threshold =next_level .get ("points",0 )or 0
        if threshold <=0 or points <threshold :
            break
        all_loot .extend (_apply_loot (player_object ,next_level .get ("loot")))
        _mark_claimed (player_object ,next_level .get ("id"))
        points =max (0.0 ,points -threshold )
        if _next_unclaimed_level (track ,_claimed_ids (player_object ))is None :

            player_object ["encore_claimed_levels"]=[]
            points =0.0
            break
    return points ,all_loot

def encore_progress (player_object ,track_id ,points ,action_kind =None ):

    if points <=0 :
        return None
    event_id ,active_track_id =active_encore_event ()
    if event_id is None or active_track_id !=track_id :
        return None
    state =_ensure_encore_state (player_object ,event_id )
    before =_decode_wire_number (state .get ("total_points",0.0 ))
    after =before +float (points )
    track =_reward_tracks ().get (track_id )
    after ,all_items =_grant_all_eligible_levels (player_object ,track ,after )
    entry ={}
    entry ["previous_points"]=SFSFloat (before )
    entry ["delay"]=SFSFloat (0.0 )
    if all_items :
        entry ["loot"]=[
        _wire_loot_item (it )
        for it in all_items if it .get ("resource")in _LOOT_WIRE_TYPES
        ]
        if any (it .get ("resource")=="card_pack"for it in all_items ):
            entry ["updateCardAlbum"]=True
    state ["total_points"]=after
    entry ["current_points"]=SFSFloat (after )
    entry ["current_encore_state"]={"event_id":event_id ,"total_points":SFSFloat (after )}
    _sync_encore_player_fields (player_object ,track_id ,after ,track )
    return entry

def properties_with_encore (player_object ,track_id ,points ,action_kind =None ):
    entry =encore_progress (player_object ,track_id ,points ,action_kind )
    props =create_player_properties (player_object )
    if entry is not None :
        props =[{"encore_event":entry }]+props
    return props

def _claimed_ids (player_object ):
    return set (player_object .get ("encore_claimed_levels")or [])

def _mark_claimed (player_object ,level_id ):
    ids =_claimed_ids (player_object )
    ids .add (level_id )
    player_object ["encore_claimed_levels"]=sorted (ids )

def _grant_monster_reward (player_object ,monster_id ):
    from msm_gamedata import get_monster_definition ,monster_allowed_on_island
    from msm_box import requires_direct_placement
    from msm_monsters import place_egg ,_find_nursery
    definition =get_monster_definition (monster_id )
    active_island =find_island (player_object ,get_active_island_id (player_object ))
    island =None
    if definition and requires_direct_placement (definition ,island_type_of (active_island )if active_island else 0 ):
        island =active_island
    else :
        candidates =[]
        if active_island is not None :
            candidates .append (active_island )
        for isl in player_object .get ("islands")or []:
            if isl is not None and isl is not active_island :
                candidates .append (isl )
        for isl in candidates :
            itype =island_type_of (isl )
            if definition and not monster_allowed_on_island (definition ,itype ):
                continue
            if _find_nursery (isl ,0 )is not None :
                island =isl
                break
    if island is not None :
        place_egg (player_object ,island ,monster_id ,"reward_track",ready =True )

def _apply_loot (player_object ,loot_json ):
    items =[]
    try :
        loot =json .loads (loot_json )if loot_json else {}
    except ValueError :
        loot ={}
    for key ,amount in loot .items ():
        amount =amount or 0

        if key =="card_pack"or key .startswith ("card_pack."):
            pack_type =1
            if "."in key :
                try :
                    pack_type =int (key .split (".",1 )[1 ])
                except ValueError :
                    pack_type =1
            import msm_cardalbum
            msm_cardalbum ._grant_packs (player_object ,amount ,pack_type )
            items .append ({"amount":amount ,"resource":"card_pack","pack_type":pack_type })
        elif key =="monster":
            monster_id =int (amount )if amount else 0
            if monster_id :
                _grant_monster_reward (player_object ,monster_id )
                items .append ({"amount":monster_id ,"resource":"monster"})
        elif key =="sfs_object"and isinstance (amount ,dict )and str (amount .get ("type",""))=="MONSTER":
            monster_id =int (amount .get ("id")or 0 )
            if monster_id :
                _grant_monster_reward (player_object ,monster_id )
                items .append ({"amount":monster_id ,"resource":"monster"})
        elif key in CURRENCY_LOOT_KEYS :
            player_object [key ]=(player_object .get (key ,0 )or 0 )+amount
            player_object [f"{key }_actual"]=player_object [key ]
            items .append ({"amount":amount ,"resource":key })
        else :
            items .append ({"amount":amount ,"resource":key })
    return items

def collect_rewards (username ,params ):
    event_id ,track_id =active_encore_event ()
    if event_id is None or track_id is None :
        return {"success":False ,"notificationOnFail":False }
    root ,player_object =load_player (username )
    state =_ensure_encore_state (player_object ,event_id )
    points =_decode_wire_number (state .get ("total_points",0.0 ))
    track =_reward_tracks ().get (track_id )
    if track is None :
        return {"success":False ,"notificationOnFail":False }

    points ,raw_items =_grant_all_eligible_levels (player_object ,track ,points )
    if not raw_items :
        return {"success":False ,"notificationOnFail":False }

    items =[
    _wire_loot_item (it )
    for it in raw_items if it .get ("resource")in _LOOT_WIRE_TYPES
    ]
    state ["total_points"]=points
    _sync_encore_player_fields (player_object ,track_id ,points ,track )
    save_player (username ,root )
    return {"success":True ,"items":items ,"properties":create_player_properties (player_object )}
