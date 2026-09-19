import json
import logging
import time
import traceback
import urllib.request
import msm_attune
import msm_battle
import msm_box
import msm_cardalbum
import msm_composer
import msm_clubbox
import msm_minigames
import msm_gamedata
import msm_islands
from mod_api import event
import msm_monsters
import msm_quests
import msm_rewards
import msm_rewardtracks
import msm_structures
import msm_synthesis
import msm_toggles
import mod_api
import random
from msm_gamedata import get_battle_campaign_definition ,get_monster_definition ,get_user_game_setting_int ,get_structure_definition
from msm_store import mod_db_names
from msm_playerdata import (
add_actual_currencies ,coerce_wire_types ,create_player_properties ,find_island_by_structure ,
find_monster_with_island ,get_client_lang ,load_player ,
next_daily_reset_timestamp ,recalculate_level ,save_player ,set_client_lang ,
append_inventory_property ,grant_inventory_item ,
)
from msm_protocol import SFSFloat ,SFSLong
from msm_store import load_db_json ,load_user_data ,normalize_db_payload ,save_user_data
logger =logging .getLogger ("msm.handlers")
DEFAULT_USERNAME ="Nextstars"

_active_username =DEFAULT_USERNAME
def set_active_username (username ):
    global _active_username
    _active_username =str (username ).strip ()or DEFAULT_USERNAME
    logger .info ("active username set to %s",_active_username )
def get_active_username ():
    return _active_username
def _safe_int (value ,default =0 ):
    try :
        return int (value )
    except (TypeError ,ValueError ,OverflowError ):
        return default

_FORCE_REFETCH_TABLES ={"db_minigames","db_monster","db_island_v2","db_structure"}

def db_precheck (username ,params ):
    event("on_db_precheck")
    requested =params .get ("precheck")or []
    if not isinstance (requested ,list ):
        requested =[]
    need_updates =[]
    for name in list (requested )+list (_FORCE_REFETCH_TABLES )+mod_db_names ():
        if isinstance (name ,str )and name .startswith ("db_")and name not in need_updates :
            need_updates .append (name )
    return {
    "server_time":SFSLong (int (time .time ()*1000 )),
    "last_updated":SFSLong (0 ),
    "need_updates":need_updates ,
    }

def db_minigames (username ,params ):
    event("on_db_minigame")
    data =load_db_json ("db_minigames")or {}
    entries =data .get ("minigames_data")or []
    last_updated =max ([_safe_int (e .get ("last_changed"))for e in entries if isinstance (e ,dict )]or [0 ])
    return {
    "server_time":SFSLong (int (time .time ()*1000 )),
    "last_updated":SFSLong (last_updated ),
    "minigames_data":entries ,
    }

def db_bakery_foods (username ,params ):
    event("on_db_bakery_foods")
    data =load_db_json ("db_bakery_foods")or {}
    if not msm_toggles .is_enabled ("unlock_all_bakery_foods"):
        return dict (data )
    patched =dict (data )
    patched ["bakery_data"]=[
    {**food ,"always_avail":1 }if isinstance (food ,dict )else food
    for food in (data .get ("bakery_data")or [])
    ]
    return patched

def db_island_themes (username ,params ):
    event("on_db_island_themes")
    data =load_db_json ("db_island_themes")or {}
    patched =dict (data )
    patched ["island_theme_data"]=[
    {**theme ,"level":0 }if isinstance (theme ,dict )else theme
    for theme in (data .get ("island_theme_data")or [])
    ]
    return patched

def db_attuner_gene (username ,params ):
    event("on_db_attuner_gene")
    data =load_db_json ("db_attuner_gene")or {}
    entries =data .get ("attuner_gene_data")or []
    active_genes ,window_start ,time_remaining =msm_gamedata .current_tunable_genes ()
    if not active_genes :
        return dict (data )
    rotation_ms =msm_gamedata ._TUNE_UP_ROTATION_MS
    active_set =set (active_genes )
    patched_entries =[]
    for entry in entries :
        if not isinstance (entry ,dict ):
            patched_entries .append (entry )
            continue
        gene =(entry .get ("gene")or "").strip ().upper ()
        patched =dict (entry )
        if gene in active_set :
            patched ["rare_schedule"]={
            "timeRemaining":time_remaining ,
            "startTimes":[{"duration":rotation_ms ,"startTime":window_start }],
            }
        else :
            patched ["rare_schedule"]={
            "timeRemaining":0 ,
            "startTimes":[{"duration":rotation_ms ,"startTime":window_start -rotation_ms }],
            }
        patched_entries .append (patched )
    patched_data =dict (data )
    patched_data ["attuner_gene_data"]=patched_entries
    return patched_data

def _mark_tutorials_complete (player_object ):
    if player_object .get ("tut_stage")is None :
        return
    player_object ["tut_stage"]=max (_safe_int (player_object .get ("tut_stage")),999 )
    player_object .setdefault ("client_tutorial_setup","breedingAddOn")
    player_object .setdefault ("guided_progress_setup","")

    player_object ["clubbox_tutorial_popup"]=True

def _sanitize_client_fragile_player_fields (player_object ):
    if isinstance (player_object .get ("last_timed_theme"),dict ):
        player_object ["last_timed_theme"]=[]
    last_clubbox =player_object .get ("last_clubbox")
    if isinstance (last_clubbox ,int )and last_clubbox not in msm_clubbox ._acts ():
        player_object ["last_clubbox"]=None
    state =player_object .get ("current_encore_state")
    if isinstance (state ,dict )and isinstance (state .get ("total_points"),dict ):
        bits =state .get ("total_points",{}).get ("__double_bits")
        if bits is not None :
            try :
                import struct
                state ["total_points"]=float (struct .unpack (">d",bytes .fromhex (str (bits ).removeprefix ("0x")))[0 ])
            except Exception :
                state ["total_points"]=0.0

def _repair_remapped_egg_holders (player_object ):
    for island in player_object .get ("islands")or []:
        if not isinstance (island ,dict ):
            continue
        structures =island .get ("structures")or []
        broken_ids ={
        _safe_int (structure .get ("user_structure_id"))
        for structure in structures
        if isinstance (structure ,dict )and _safe_int (structure .get ("user_structure_id"))>=2000000
        }
        if not broken_ids :
            continue
        used ={
        _safe_int (structure .get ("user_structure_id"))
        for structure in structures
        if isinstance (structure ,dict )and 0 <_safe_int (structure .get ("user_structure_id"))<2000000
        }
        id_map ={}
        next_id =1
        for structure in structures :
            if not isinstance (structure ,dict ):
                continue
            current =_safe_int (structure .get ("user_structure_id"))
            if current not in broken_ids :
                continue
            while next_id in used :
                next_id +=1
            id_map [current]=next_id
            structure ["user_structure_id"]=next_id
            used .add (next_id )
            next_id +=1
        for key in ("eggs","breeding","baking","fuguing","evolving","attuning","synthesizing"):
            for item in island .get (key )or []:
                if not isinstance (item ,dict ):
                    continue
                for ref_key in ("structure","user_structure_id","breeding_structure_id","nursery_id","egg_structure_id"):
                    old =_safe_int (item .get (ref_key ))
                    if old in id_map :
                        item [ref_key]=id_map [old ]

def _ensure_friend_code (player_object ):
    import nps_online
    if not nps_online .is_configured ():
        code ="NOT LOGGED"
    else :
        code =nps_online .active_friend_code ()or f"{nps_online .active_account_id ():06d}"
    player_object ["friend_code"]=code
    profile =player_object .get ("profile")
    if isinstance (profile ,dict ):
        profile ["friend_code"]=code

_SCALED_DAILY_REWARD =[
{"bonus_entity":-1 ,"amt":0 ,"type":"none"},
{"bonus_entity":-1 ,"amt":3500 ,"type":"coins"},
{"bonus_entity":-1 ,"amt":2 ,"type":"relics"},
{"bonus_entity":-1 ,"amt":3 ,"type":"diamonds"},
{"bonus_entity":-1 ,"amt":4 ,"type":"relics"},
{"bonus_entity":-1 ,"amt":1 ,"type":"keys"},
{"bonus_entity":-1 ,"amt":900 ,"type":"food"},
{"bonus_entity":-1 ,"amt":3500 ,"type":"coins"},
{"bonus_entity":-1 ,"amt":8 ,"type":"relics"},
{"bonus_entity":-1 ,"amt":3 ,"type":"keys"},
{"bonus_entity":-1 ,"amt":25 ,"type":"diamonds"},
]

def _ensure_daily_calendar_structures (player_object ):

    if not isinstance (player_object .get ("daily_cumulative_login"),dict ):

        calendar_id =6
        player_object ["daily_cumulative_login"]={
        "total":0 ,"calendar_id":calendar_id ,
        "next_collect":next_daily_reset_timestamp (),"reward_idx":0 ,
        }
    stale_rewards =player_object .get ("scaled_daily_reward")
    if not stale_rewards or len (stale_rewards )!=len (_SCALED_DAILY_REWARD ):
        player_object ["scaled_daily_reward"]=[dict (entry )for entry in _SCALED_DAILY_REWARD ]
        player_object ["_daily_bonus_fallback_idx"]=_safe_int (player_object .get ("_daily_bonus_fallback_idx"))%len (_SCALED_DAILY_REWARD )
        calendar =player_object .get ("daily_cumulative_login")
        if isinstance (calendar ,dict ):
            calendar ["reward_idx"]=_safe_int (calendar .get ("reward_idx"))%len (_SCALED_DAILY_REWARD )
        if _safe_int (player_object .get ("reward_day"))>_daily_reward_days ():
            player_object ["reward_day"]=0

def _repair_stale_daily_calendar_id (player_object ):

    calendar =player_object .get ("daily_cumulative_login")
    if isinstance (calendar ,dict )and calendar .get ("calendar_id")in (1 ,2 ,3 ,4 ,5 ):
        calendar ["calendar_id"]=6

    if player_object .get ("last_daily_bonus_claimed")and not player_object .get ("nextDailyLogin"):
        player_object ["nextDailyLogin"]=next_daily_reset_timestamp ()

    current_type =player_object .get ("daily_bonus_type")
    if current_type and current_type not in ("none","dailyReward")and not player_object .get ("reward_day"):
        rewards =player_object .get ("scaled_daily_reward")or _SCALED_DAILY_REWARD
        idx =_safe_int (player_object .get ("_daily_bonus_fallback_idx"))
        player_object ["reward_day"]=idx %len (rewards )if rewards else 0

def _backfill_daily_reward_state (player_object ):
    _ensure_daily_calendar_structures (player_object )

    current_bonus_type =player_object .get ("daily_bonus_type")
    has_real_bonus =bool (current_bonus_type )and current_bonus_type not in ("none","dailyReward")
    if not has_real_bonus :
        last_claimed =player_object .get ("last_daily_bonus_claimed")
        if not last_claimed or int (time .time ()*1000 )>=next_daily_reset_timestamp (last_claimed ):
            _advance_fallback_daily_bonus (player_object )

def _daily_reward_days ():
    return max (1 ,len (_SCALED_DAILY_REWARD )-1 )

def _daily_reward_entry (player_object ,day ):
    rewards =player_object .get ("scaled_daily_reward")or _SCALED_DAILY_REWARD
    days =max (1 ,len (rewards )-1 )
    if day <1 or day >days :
        day =1
    return day ,rewards [day ]

def _advance_fallback_daily_bonus (player_object ):
    last_day =_safe_int (player_object .get ("cachedRewardDay"))
    day ,entry =_daily_reward_entry (player_object ,last_day +1 )
    bonus_type =entry .get ("type","coins")
    bonus_amount =_safe_int (entry .get ("amt"))
    player_object ["daily_bonus_type"]=bonus_type
    player_object ["daily_bonus_amount"]=bonus_amount
    player_object ["reward_day"]=day
    player_object ["cachedRewardDay"]=day
    player_object ["_daily_bonus_fallback_idx"]=day
    return bonus_type ,bonus_amount

def _advance_daily_calendar_reward (player_object ):

    calendar =player_object ["daily_cumulative_login"]
    days =_daily_reward_days ()
    reward_idx =_safe_int (calendar .get ("reward_idx"))%days
    day ,entry =_daily_reward_entry (player_object ,reward_idx +1 )
    bonus_type =entry .get ("type","coins")
    bonus_amount =_safe_int (entry .get ("amt"))
    player_object ["daily_bonus_type"]=bonus_type
    player_object ["daily_bonus_amount"]=bonus_amount
    calendar ["reward_idx"]=(reward_idx +1 )%days
    calendar ["total"]=_safe_int (calendar .get ("total"))+1
    calendar ["next_collect"]=next_daily_reset_timestamp ()
    return reward_idx +1 ,bonus_type ,bonus_amount

def _next_daily_calendar_reward (player_object ):
    calendar =player_object ["daily_cumulative_login"]
    reward_idx =_safe_int (calendar .get ("reward_idx"))%_daily_reward_days ()
    day ,entry =_daily_reward_entry (player_object ,reward_idx +1 )
    return day ,entry .get ("type","coins"),_safe_int (entry .get ("amt"))

def _clear_daily_bonus (player_object ,claimed =False ):

    just_collected_day =_safe_int (player_object .get ("reward_day"))
    player_object ["daily_bonus_type"]="none"
    player_object ["daily_bonus_amount"]=0
    player_object ["reward_day"]=0
    player_object ["daily_reward_level"]=max (_safe_int (player_object .get ("daily_reward_level")),_safe_int (player_object .get ("level")))
    if claimed :
        now =int (time .time ()*1000 )
        player_object ["last_daily_bonus_claimed"]=now

        player_object ["nextDailyLogin"]=next_daily_reset_timestamp (now )
        player_object ["cachedRewardDay"]=just_collected_day
        _ensure_daily_calendar_structures (player_object )
        calendar =player_object .get ("daily_cumulative_login")
        if isinstance (calendar ,dict ):
            if _safe_int (calendar .get ("next_collect"))<=now :
                calendar ["reward_idx"]=_safe_int (calendar .get ("reward_idx"))+1
                calendar ["total"]=_safe_int (calendar .get ("total"))+1
            calendar ["next_collect"]=next_daily_reset_timestamp (now )

def _find_island (islands ,user_island_id ):
    for island in islands :
        if isinstance (island ,dict )and island .get ("user_island_id")==user_island_id :
            return island
    return None
def _find_island_by_id_or_type (islands ,island_id ):
    target =_safe_int (island_id )
    if not target :
        return None
    resolved_target =msm_islands .resolve_island_type (target )
    for island in islands :
        if not isinstance (island ,dict ):
            continue
        user_island_id =_safe_int (island .get ("user_island_id"))
        island_type =_safe_int (island .get ("island_type")or island .get ("type")or island .get ("island"))
        resolved_island_type =msm_islands .resolve_island_type (island_type )
        if user_island_id ==target or island_type ==target or resolved_island_type ==resolved_target :
            return island
        if target <1000 and user_island_id ==target +1000 :
            return island
    return None
def handle_gs_change_island (username ,params ):
    event("on_gs_change_island")
    user_island_id =params .get ("user_island_id")
    if user_island_id is None :
        return None
    root =load_user_data (username )
    player_object =root .get ("player_object")
    islands =player_object .get ("islands")or []if player_object is not None else []
    target_island =_find_island_by_id_or_type (islands ,user_island_id )
    if target_island is None :
        return {
        "success":False ,"user_island_id":SFSLong (user_island_id ),
        "message":"Island not found",
        }
    resolved_user_island_id =target_island .get ("user_island_id",user_island_id )
    if player_object is not None :
        player_object ["active_island"]=resolved_user_island_id
        msm_islands .backfill_island_type (target_island )
        msm_islands .repair_ethereal_structure_positions (target_island )
        msm_islands .repair_dish_harmonizer_state (target_island )
        msm_islands .backfill_ethereal_eggcups (target_island )
        save_user_data (username ,root )
    result ={
    "success":True ,"user_island_id":SFSLong (resolved_user_island_id ),
    }
    if params .get ("user_structure_focus")is not None :
        result ["user_structure_focus"]=params .get ("user_structure_focus")
    return result
_NEWSFLASH_MIN_AGE_MS =2 *365 *24 *60 *60 *1000
_NEWSFLASH_ORIGINAL_KEY ="_newsflash_original_date_created"
def _apply_newsflash_toggle (player_object ):
    if _NEWSFLASH_ORIGINAL_KEY in player_object :
        player_object ["date_created"]=player_object .pop (_NEWSFLASH_ORIGINAL_KEY )

def _repair (player_object ,username =None ):
    event("on_repair")
    _sanitize_client_fragile_player_fields (player_object )
    _repair_remapped_egg_holders (player_object )
    _ensure_friend_code (player_object )
    _mark_tutorials_complete (player_object )
    _backfill_daily_reward_state (player_object )
    _repair_stale_daily_calendar_id (player_object )

    if player_object .get ("client_platform")!="android":
        player_object ["client_platform"]="android"
    if player_object .get ("daily_bonus_type")in ("",None ):
        player_object .setdefault ("daily_bonus_type","none")
        player_object .setdefault ("daily_bonus_amount",0 )
    _apply_newsflash_toggle (player_object )
    msm_monsters .backfill_battle_state (player_object )
    msm_battle .repair_campaign_costumes (player_object )
    msm_islands .repair_broken_clubbox_eggs (player_object )
    msm_islands .repair_preset_mirror_island_collisions (player_object )
    msm_islands .repair_duplicate_island_types (player_object )
    msm_islands .repair_low_id_structures (player_object )
    msm_islands .repair_mirror_island_type (player_object )
    msm_islands .repair_island_owner (player_object )
    for island in player_object .get ("islands")or []:
        msm_monsters .backfill_titansoul_state (island )
        msm_islands .backfill_island_type (island )
        msm_islands .repair_ethereal_structure_positions (island )
        msm_islands .repair_ethereal_workshop_state (player_object ,island )
        msm_islands .repair_dish_harmonizer_state (island )
        msm_islands .backfill_ethereal_eggcups (island )
        msm_islands .backfill_nps_test_structure (island )
        msm_monsters .repair_magical_nexus_layout (island )
        msm_box .repair_underling_box_state (island )
        msm_islands .repair_crucible_structure (island )
        msm_islands .repair_structure_build_timestamps (island )
        msm_monsters .recompute_island_happiness (island )
    msm_islands .migrate_legacy_mirror_ids (player_object )
    msm_islands .repair_duplicate_structure_ids (player_object )
    msm_islands .repair_orphaned_process_refs (player_object )
    msm_islands .repair_parked_fuzer_buddies (player_object )
    msm_islands .repair_island_tiles (player_object )
    msm_composer .repair_composer_data (player_object )
    msm_clubbox .backfill_clubbox_unlock (player_object )
    _ensure_mailbox (player_object ,username )
    msm_islands .write_nps_structure_button_config (player_object )

def handle_gs_player (username ,params ):
    root ,player_object =load_player (username )
    _repair (player_object ,username )
    for _island in player_object .get ("islands")or []:
        if isinstance (_island ,dict ):
            for _structure in _island .get ("structures")or []:
                if isinstance (_structure ,dict )and _structure .get ("structure")in msm_islands .ETHEREAL_HARMONIZER_STRUCTURE_IDS :
                    msm_structures .ensure_dish_harmonizer_targets (_island ,_structure )
    recalculate_level (player_object )
    if msm_toggles .is_enabled ("premium_account"):
        player_object ["premium"]=1
        if not _safe_int (player_object .get ("purchases_total")):
            player_object ["purchases_total"]=1
        if not _safe_int (player_object .get ("purchases_amount")):
            player_object ["purchases_amount"]=499
        player_object ["third_party_ads"]=False
        player_object ["third_party_video_ads"]=False
    else :
        player_object ["premium"]=0
        player_object ["purchases_total"]=0
        player_object ["purchases_amount"]=0
        player_object ["third_party_ads"]=True
        player_object ["third_party_video_ads"]=True
    mod_api .fire_event ("player_loaded",username =username ,params =params ,player_object =player_object )
    save_user_data (username ,root )
    msm_box .apply_round2_wire_progress_for_sync (player_object )

    import msm_friends
    friends =msm_friends .friends_wire_list (player_object )
    try :
        import nps_online
        if nps_online .is_configured ():
            friends =friends +msm_friends .real_friends_wire_list ()
            nps_online .push_snapshot (msm_friends .build_own_snapshot (player_object ))
    except Exception as _e :
        logger .warning ("push_snapshot/friends sync failed for %s: %s: %s",username ,_e .__class__ .__name__ ,_e )
    friends_push ={
    "success":True ,"friends":friends ,
    "pending":msm_friends .pending_wire_list (player_object ),

    "requests":msm_friends .pending_wire_list (player_object ),"tribes":[],"top_tribes":[],
    "global_battle_rankings":{"rankTable0":[],"rankTable1":[]},
    }
    wired_player =coerce_wire_types (player_object )
    for source_island ,wired_island in zip (player_object .get ("islands")or [],wired_player .get ("islands")or []):
        if not isinstance (source_island ,dict )or not isinstance (wired_island ,dict ):
            continue
        harmonizer_entries =[]
        for structure in source_island .get ("structures")or []:
            if isinstance (structure ,dict )and structure .get ("structure")in msm_islands .ETHEREAL_HARMONIZER_STRUCTURE_IDS :
                entry =msm_structures .dish_harmonizer_wire_data (player_object ,structure )
                if entry :
                    harmonizer_entries .append (entry )
        if harmonizer_entries :
            wired_island ["dish_harmonizer"]=harmonizer_entries
    wired_player ["songs"]=msm_composer .wire_songs (player_object )
    wired_player ["tracks"]=msm_composer .wire_tracks (player_object )
    wired_player ["card_albums"]=msm_cardalbum .card_albums_wire (player_object )
    wired_player ["sticker_stars"]=player_object .get ("sticker_stars",0 )
    wired_player ["sticker_stars_actual"]=player_object .get ("sticker_stars_actual",0 )
    msm_cardalbum .strip_internal_album_fields (wired_player )
    msm_cardalbum .align_cards_viewed (wired_player )
    _apply_missing_official_fields (wired_player )
    frames =[
    ("gs_player",{"player_object":wired_player }),
    ("gs_get_friends",friends_push ),
    ("gs_update_properties",{
    "silent":True ,
    "properties":create_player_properties (player_object ),
    }),
    ]
    frames +=_crucible_seed_frames (player_object )
    event ("on_gs_player_handled",result =frames )
    return frames
def _crucible_seed_frames (player_object ):
    frames =[]
    for island in player_object .get ("islands")or []:
        if island is None :
            continue
        wire =msm_islands .crucible_wire_object_for_island (island )
        if not wire or not (wire .get ("u")or 0 ):
            continue
        frames .append (("gs_viewed_cruc_unlock",{"success":True ,"user_crucible":wire }))
    return frames
def _simple (fn ):
    def handler (username ,params ):
        return fn (username ,params )
    return handler
def _happy_effects_frames (happy_effects ):

    if not happy_effects :
        return []
    return [("gs_multi_update_monster",{
    "success":True ,
    "island_needs_happiness_update":True ,
    "monster_happy_effects":happy_effects ,
    "update_monster_list":happy_effects ,
    })]
def _move_with_happiness (command ,fn ,structure =True ):
    def handler (username ,params ):
        result ,update =fn (username ,params )
        happy_effects =result .pop ("monster_happy_effects",None )if isinstance (result ,dict )else None
        frames =[(command ,result )]
        if update :
            frames .append (("gs_update_structure"if structure else "gs_update_monster",update ))
        frames +=_happy_effects_frames (happy_effects )
        return frames
    return handler
def _with_happy_effects (command ,fn ):
    def handler (username ,params ):
        result =fn (username ,params )
        happy_effects =result .get ("monster_happy_effects")if isinstance (result ,dict )else None
        frames =[(command ,result )]
        frames +=_happy_effects_frames (happy_effects )
        return frames
    return handler
def _with_structure_update (command ,fn ,always =False ):
    def handler (username ,params ):
        result ,update =fn (username ,params )
        frames =[(command ,result )]
        if isinstance (update ,list ):
            frames .extend (update )
        elif update is not None and (update or always ):
            frames .append (("gs_update_structure",update ))
        return frames
    return handler
def _structure_update_only (fn ):

    def handler (username ,params ):
        update =fn (username ,params )
        if not update :
            return []
        return [("gs_update_structure",update )]
    return handler
def _second_only (fn ):
    def wrapped (username ,params ):
        _first ,second =fn (username ,params )
        return second
    return wrapped
def _with_structure_update_first (command ,fn ,always =False ):
    def handler (username ,params ):
        result ,update =fn (username ,params )
        frames =[]
        if update or always :
            frames .append (("gs_update_structure",update ))
        frames .append ((command ,result ))
        return frames
    return handler
def _with_structure_update_event (event_name ,command ,fn ,always =False ):
    def handler (username ,params ):
        result ,update =fn (username ,params )
        if isinstance (result ,dict )and result .get ("success"):
            root ,player_object =load_player (username )
            commands =mod_api .fire_event (event_name ,username =username ,command =command ,params =params ,
            player_object =player_object ,structure =update or {})
            if commands :
                save_player (username ,root )
        frames =[(command ,result )]
        if update or always :
            frames .append (("gs_update_structure",update ))
        return frames
    return handler
def _discard_structure_update (fn ):
    def handler (username ,params ):
        result ,_update =fn (username ,params )
        return result
    return handler
def _finish_fuguing_handler (username ,params ):

    result ,update ,extra_frames =msm_structures .finish_fuguing (username ,params )
    frames =list (extra_frames or [])
    if update :
        frames .append (("gs_update_structure",update ))
    frames .append (("gs_finish_fuguing",result ))
    return frames
def _with_monster_update (command ,fn ):
    def handler (username ,params ):
        result ,update =fn (username ,params )
        frames =[(command ,result )]
        if update :
            frames .append (("gs_update_monster",update ))
        return frames
    return handler
def _with_monster_update_event (event_name ,command ,fn ):
    def handler (username ,params ):
        result ,update =fn (username ,params )

        if isinstance (result ,dict )and result .get ("success"):
            root ,player_object =load_player (username )
            commands =mod_api .fire_event (event_name ,username =username ,command =command ,params =params ,
            player_object =player_object ,monster =update or {})
            if commands :
                save_player (username ,root )
        frames =[(command ,result )]
        if update :
            frames .append (("gs_update_monster",update ))
        return frames
    return handler
def _with_monster_update_first (command ,fn ):
    def handler (username ,params ):
        result ,update =fn (username ,params )
        frames =[]
        if update :
            frames .append (("gs_update_monster",update ))
        frames .append ((command ,result ))
        return frames
    return handler
def _box_add_handler (command ):
    def handler (username ,params ):
        result =msm_box .box_monster_command (username ,params )
        frames =[(command ,result )]
        if isinstance (result ,dict )and result .get ("success"):
            target_id =(result .get ("user_box_monster_id")or params .get ("user_box_monster_id")
            or result .get ("user_monster_id")or params .get ("user_monster_id")or 0 )
            if target_id :
                try :
                    _root ,player_object =load_player (username )
                    _island ,monster =find_monster_with_island (player_object ,target_id )
                    if monster is not None :
                        if monster .get ("ascend_pending"):
                            update =msm_box ._box_activate_update (monster )
                            update .update (msm_box .round2_wire_progress (monster ))
                            update ["powerup_unlocked"]=monster .get ("powerup_unlocked")or 0
                        else :
                            update =msm_box ._box_progress_update (monster )
                        update ["properties"]=create_player_properties (player_object )
                        frames .append (("gs_update_monster",update ))
                except Exception :
                    logger .exception ("box add update failed")
        return frames
    return handler

def _box_activate_handler (command ,fn ):
    def handler (username ,params ):
        result ,update =fn (username ,params )

        if isinstance (update ,list ):
            return update
        frames =[(command ,result )]
        if update :
            frames .append (("gs_update_monster",update ))
        return frames
    return handler
def _mega_monster_handler (username ,params ):
    logger .info ("gs_mega_monster_message params: %r",params )
    result ,update =msm_monsters .biggify_monster (username ,params )
    logger .info ("gs_mega_monster_message result: %r update: %r",result ,update )
    frames =[]
    if update :
        frames .append (("gs_update_monster",update ))
    frames .append (("gs_mega_monster_message",result ))
    return frames
_PROFILE_DATA_FIELDS =(
"bg_id","moniker_id","fav_mon_1_id","fav_island_id","total_torches_lit",
"card_id","avatar_id","fav_mon_2_id","fav_mon_3_id","phrase_id","frame_id",
)
def handle_player_save_profile (username ,params ):
    import json as _json
    root ,player_object =load_player (username )
    profile =player_object .setdefault ("profile",{})

    for name_key in ("display_name","player_name","name"):
        if name_key in params :
            new_name =str (params .get (name_key )or "").strip ()
            if new_name :
                player_object ["display_name"]=new_name
            break
    else :
        nested =params .get ("profile")if isinstance (params .get ("profile"),dict )else {}
        data_param =params .get ("data")
        if isinstance (data_param ,str ):
            try :
                parsed_data =_json .loads (data_param or "{}")
            except ValueError :
                parsed_data ={}
        else :
            parsed_data =data_param if isinstance (data_param ,dict )else {}
        found_name =False
        for source in (nested ,parsed_data ):
            for name_key in ("display_name","player_name","name"):
                if name_key in source :
                    new_name =str (source .get (name_key )or "").strip ()
                    if new_name :
                        player_object ["display_name"]=new_name
                        found_name =True
                    break
            if found_name :
                break
    if "data"in params :
        profile ["data"]=params .get ("data")
    else :
        try :
            data =_json .loads (profile .get ("data")or "{}")
        except ValueError :
            data ={}
        for key in _PROFILE_DATA_FIELDS :
            if key in params :
                data [key ]=params [key ]
        data .setdefault ("version",1 )
        profile ["data"]=_json .dumps (data )
    if "discoverable"in params :
        profile ["discoverable"]=bool (params .get ("discoverable"))
    if "follow_permission"in params :
        profile ["follow_permission"]=params .get ("follow_permission")
    if "followback_permission"in params :
        profile ["followback_permission"]=params .get ("followback_permission")
    profile ["level"]=player_object .get ("level",profile .get ("level",0 ))
    profile .setdefault ("friend_code",player_object .get ("friend_code",""))
    save_user_data (username ,root )

    return {
    "success":True ,"profile":profile ,
    "display_name":player_object .get ("display_name",""),
    "player_name":player_object .get ("display_name",""),
    "properties":[
    {"display_name":player_object .get ("display_name","")},
    {"player_name":player_object .get ("display_name","")},
    ],
    }
def _player_save_profile_handler (username ,params ):
    result =handle_player_save_profile (username ,params )
    frames =[("gs_player_save_profile",result )]
    if isinstance (result ,dict )and result .get ("success")and result .get ("properties"):
        frames .append (("gs_update_properties",{
        "success":True ,
        "properties":result .get ("properties")or [],
        }))
    return frames
def _random_visit_handler (username ,params ):
    import msm_friends
    _root ,player_object =load_player (username )
    return msm_friends .random_visit_data (player_object )
def _join_tribe_handler (username ,params ):
    _root ,player_object =load_player (username )
    island =find_island (player_object ,get_active_island_id (player_object ))
    result ={"success":True }
    if island is not None :
        result ["user_island"]=island
        result ["user_island_id"]=SFSLong (island .get ("user_island_id",0 )or 0 )
    return result
def _set_displayname_handler (username ,params ):
    root ,player_object =load_player (username )
    new_name =(
    params .get ("newName")or params .get ("displayName")or params .get ("display_name")
    or params .get ("player_name")or params .get ("name")or params .get ("user_alias")or ""
    )
    new_name =str (new_name or "").strip ()
    if not new_name :
        return [("gs_set_displayname",{"success":False ,"error":"empty display name"})]
    player_object ["display_name"]=new_name
    player_object ["player_name"]=new_name
    player_object ["user_alias"]=new_name
    save_user_data (username ,root )

    return [
    ("gs_set_displayname",{
    "success":True ,
    "displayName":new_name ,
    }),
    ]
def _quest_handler (username ,params ):
    result =msm_quests .gs_quest (username ,params )
    frames =[("gs_quest",result )]
    if isinstance (result ,dict )and result .get ("properties"):
        frames .append (("gs_update_properties",{
        "success":True ,
        "properties":result .get ("properties")or [],
        }))
    return frames
def _quest_read_handler (username ,params ):
    return [("gs_quest",msm_quests .gs_quest_read (username ,params ))]
def _quests_read_handler (username ,params ):
    return [("gs_quest",msm_quests .gs_quests_read (username ,params ))]
def _quest_event_handler (username ,params ):
    return [("gs_quest",msm_quests .gs_quest_event (username ,params ))]
def _quest_collect_handler (username ,params ):
    outcome =msm_quests .gs_quest_collect (username ,params )
    if isinstance (outcome ,tuple ):
        result ,changed_properties =outcome
        frames =[("gs_quest",result )]
        if changed_properties :
            frames .append (("gs_update_properties",{"properties":changed_properties }))
        return frames
    return [("gs_quest",outcome )]
def _echo_success (*keys ):
    def handler (username ,params ):
        result ={"success":True }
        for key in keys :
            if key in params :
                result [key ]=params [key ]
        return result
    return handler
def _set_island_field_handler (field ,param_keys ):
    def handler (username ,params ):
        value =_first_param (params ,param_keys ,None )
        root ,player_object =load_player (username )
        island =find_island (player_object ,get_active_island_id (player_object ))
        if island is not None and value is not None :
            island [field ]=value
            save_player (username ,root )
        result ={"success":True }
        if value is not None :
            result [field ]=value
        return result
    return handler
def _set_player_field_handler (field ,param_keys ):
    def handler (username ,params ):
        value =_first_param (params ,param_keys ,None )
        root ,player_object =load_player (username )
        if value is not None :
            player_object [field ]=value
            save_player (username ,root )
        result ={"success":True }
        if value is not None :
            result [field ]=value
        return result
    return handler
def _generic_success (extra_array_keys =()):
    def handler (username ,params ):
        result ={"success":True }
        for key in extra_array_keys :
            result [key ]=[]
        return result
    return handler
def _update_viewed_campaigns (username ,params ):
    viewed =params .get ("perma_campaigns_viewed")
    if isinstance (viewed ,list ):
        root ,player_object =load_player (username )
        existing =player_object .get ("perma_campaigns_viewed")
        if not isinstance (existing ,list ):
            existing =[]
        merged =sorted (set (existing )|{int (v )for v in viewed if isinstance (v ,(int ,float ))})
        if merged !=existing :
            player_object ["perma_campaigns_viewed"]=merged
            save_user_data (username ,root )
    return {"success":True }
def _currency_conversion_handler (username ,params ):
    amount =max (0 ,_safe_int (params .get ("amt"),0 ))
    from_currency =str (params .get ("from",""))
    to_currency =str (params .get ("to",""))
    root ,player_object =load_player (username )
    if msm_toggles .is_enabled ("functioning_currencies")and amount >0 :
        if from_currency =="diamonds"and to_currency =="relics":
            count =_safe_int (player_object .get ("daily_relic_purchase_count"),0 )
            cost =max (1 ,3 *(count +1 ))*amount
            player_object ["diamonds"]=max (0 ,(player_object .get ("diamonds",0 )or 0 )-cost )
            player_object ["relics"]=(player_object .get ("relics",0 )or 0 )+amount
            player_object ["daily_relic_purchase_count"]=count +amount
            player_object ["relic_diamond_cost"]=3 *(count +amount +1 )
            player_object .setdefault ("next_relic_reset",next_daily_reset_timestamp ())
    properties =create_player_properties (player_object )
    for key in ("daily_relic_purchase_count","relic_diamond_cost","next_relic_reset"):
        if key in player_object :
            properties .append ({key :player_object .get (key )})
    save_player (username ,root )
    return [("gs_update_properties",{"properties":properties })]
def _transfer_code_handler (username ,params ):
    return [("gs_get_code",{
    "success":True ,
    "friend_gift":SFSLong (int (time .time ()*1000 )),
    "key_gift":True ,
    "message":"CODE_TRANSFERRED_TEXT",
    })]
def _first_param (params ,keys ,default =0 ):
    for key in keys :
        value =params .get (key )
        if value is not None :
            return value
    return default
def _light_torch (username ,params ):
    structure_id =_safe_int (_first_param (params ,(
    "user_structure","user_structure_id","userStructure","userStructureId",
    "structure_id","structureId","id"
    ),0 ))
    if structure_id <=0 :
        return {"success":False ,"user_structure":SFSLong (structure_id )}
    root ,player_object =load_player (username )
    now =int (time .time ()*1000 )
    permanent =bool (_first_param (params ,("permalit","permanent","is_permanent","isPermalit"),False ))
    finished_at =0 if permanent else now +86400000
    own_id =_safe_int (player_object .get ("bbb_id")or player_object .get ("user_id")or 0 )
    target_id =_safe_int (_first_param (params ,("user_id","userId","target_user_id"),0 ))

    if target_id and target_id !=own_id :
        import msm_friends
        friend =msm_friends .find_friend (player_object ,target_id )
        if friend is None :
            return {"success":False ,"user_structure":SFSLong (structure_id )}
        for friend_island in friend .get ("islands")or []:
            for friend_structure in friend_island .get ("structures")or []:
                if _safe_int (friend_structure .get ("user_structure_id"))!=structure_id :
                    continue
                friend_structure ["started_at"]=now
                friend_structure ["finished_at"]=finished_at
                friend_structure ["permalit"]=permanent
                friend_structure ["lit"]=not permanent
                friend_structure ["is_lit"]=not permanent
                msm_friends .light_friend_torch (player_object ,target_id )
                if msm_toggles .is_enabled ("functioning_currencies"):
                    cost =get_user_game_setting_int (
                    "USER_DIAMOND_COST_PER_PERMALIT_TORCH"if permanent else "USER_DIAMOND_COST_PER_LIT_TORCH",100 if permanent else 2 ,
                    )
                    if cost >0 :
                        player_object ["diamonds"]=max (0 ,(player_object .get ("diamonds",0 )or 0 )-cost )
                save_player (username ,root )
                return {
                "user_id":SFSLong (target_id ),"success":True ,
                "island_id":SFSLong (friend_island .get ("user_island_id",0 )or 0 ),
                "user_structure":SFSLong (structure_id ),
                "properties":create_player_properties (player_object ),
                }
        return {"success":False ,"user_structure":SFSLong (structure_id )}
    island ,structure =find_island_by_structure (player_object ,structure_id )
    if island is None or structure is None :
        return {"success":False ,"user_structure":SFSLong (structure_id )}

    if msm_toggles .is_enabled ("functioning_currencies"):
        cost =get_user_game_setting_int (
        "USER_DIAMOND_COST_PER_PERMALIT_TORCH"if permanent else "USER_DIAMOND_COST_PER_LIT_TORCH",100 if permanent else 2 ,
        )
        if cost >0 :
            player_object ["diamonds"]=max (0 ,(player_object .get ("diamonds",0 )or 0 )-cost )
    torches =island .setdefault ("torches",[])
    user_torch =None
    for torch in torches :
        if torch is not None and _safe_int (torch .get ("user_structure"))==structure_id :
            user_torch =torch
            break
    if user_torch is None :
        next_torch_id =max ([_safe_int (torch .get ("user_torch_id"))for torch in torches if torch is not None ]+[0 ])+1
        user_torch ={"user_torch_id":next_torch_id ,"user_structure":structure_id }
        torches .append (user_torch )
    user_torch ["started_at"]=now
    user_torch ["finished_at"]=finished_at
    user_torch ["permalit"]=permanent
    structure ["started_at"]=now
    structure ["finished_at"]=finished_at
    structure ["permalit"]=permanent
    structure ["lit"]=not permanent
    structure ["is_lit"]=not permanent
    island ["num_torches"]=max (_safe_int (island .get ("num_torches")),len (torches ))
    player_object ["total_torches_lit"]=_safe_int (player_object .get ("total_torches_lit"))+1
    user_id =_safe_int (player_object .get ("bbb_id")or player_object .get ("user_id")or player_object .get ("user")or 0 )
    save_player (username ,root )
    return {
    "user_id":SFSLong (user_id ),
    "user_torch":coerce_wire_types (user_torch ),
    "success":True ,
    "island_id":SFSLong (island .get ("user_island_id",0 )or 0 ),
    "user_structure":SFSLong (structure_id ),
    "properties":create_player_properties (player_object ),
    }
def _get_friends (username ,params ):
    import msm_friends
    _root ,player_object =load_player (username )
    friends =msm_friends .friends_wire_list (player_object )
    incoming =msm_friends .pending_wire_list (player_object )
    outgoing =[]
    try :
        friends =friends +msm_friends .real_friends_wire_list ()
        incoming =incoming +msm_friends .real_pending_wire_list ()
        outgoing =outgoing +msm_friends .real_outgoing_wire_list ()
    except Exception as _e :
        logger .warning ("real friends list sync failed for %s: %s: %s",username ,_e .__class__ .__name__ ,_e )
    try :
        import nps_online
        if nps_online .is_configured ():
            nps_online .push_snapshot (msm_friends .build_own_snapshot (player_object ))
    except Exception as _e :
        logger .warning ("push_snapshot failed for %s: %s: %s",username ,_e .__class__ .__name__ ,_e )
    return {
    "success":True ,"friends":friends ,
    "pending":outgoing ,

    "requests":incoming ,"tribes":[],"top_tribes":[],
    "global_battle_rankings":{"rankTable0":[],"rankTable1":[]},
    }
def _send_friend_request (username ,params ):
    import msm_friends
    """Send a friend request and always tell the player what happened.

    This used to answer a bare success:false for every failure - unknown code,
    already friends, not signed in - and the client shows nothing at all for
    that, so adding a friend looked like a dead button. Push a
    gs_display_generic_message alongside the ack the way the rest of the
    handlers do.
    """
    import nps_online
    code =str (_first_param (params ,("friend_code","code"),"")or "").strip ()

    def notice (key ,success ):
        return [
        ("gs_friend_request",{"success":success ,"notificationOnFail":False }),
        ("gs_display_generic_message",{
        "force_logout":False ,
        "msg":_generic_message (key ,username ),
        }),
        ]

    if not code :
        return notice ("friend_code_missing",False )
    if not nps_online .is_configured ():
        return notice ("friend_offline",False )

    status =nps_online .send_friend_request (code )
    if status in (251 ,388 ):
        entry =None
        for candidate in msm_friends .real_friends_wire_list ()+msm_friends .real_outgoing_wire_list ():
            if str (candidate .get ("friend_code","")).replace ("-","").lower ()==code .replace ("-","").lower ():
                entry =candidate
                break
        frames =notice ("friend_already"if status ==388 else "friend_request_sent",True )
        frames [0 ]=("gs_friend_request",{
        "success":True ,"type":"follow",
        "request":[entry ]if entry else [],
        })
        return frames
    if status ==917 :
        return notice ("friend_code_unknown",False )
    return notice ("friend_offline",False )
def _friend_discover (username ,params ):
    import msm_friends
    try :
        friends =msm_friends .discover_wire_list ()
    except Exception :
        friends =[]
    return {"success":True ,"friends":friends }

def _remove_friend (username ,params ):
    import msm_friends
    friend_id =_safe_int (_first_param (params ,("friend_id","user_id","userId","bbb_id"),0 ))
    if not friend_id :
        return {"success":False }

    root ,player_object =load_player (username )
    removed =msm_friends .remove_local_friend (player_object ,friend_id )
    if removed :
        save_player (username ,root )
    elif msm_friends .is_real_friend_wire_id (friend_id ):
        import nps_online
        removed =nps_online .remove_friend (friend_id -msm_friends .REAL_FRIEND_ID_OFFSET )

    frames =[("gs_remove_friend",{"friend_id":SFSLong (friend_id ),"success":bool (removed )})]
    if not removed :
        frames .append (("gs_display_generic_message",{
        "force_logout":False ,
        "msg":_generic_message ("friend_remove_failed",username ),
        }))
    return frames

def _friend_request_manage (username ,params ):
    import msm_friends
    action =str (params .get ("action")or "").lower ()
    ids =[]
    for key in ("pending","ids","request_ids","user_ids"):
        raw =params .get (key )
        if isinstance (raw ,(list ,tuple )):
            ids .extend (_safe_int (v )for v in raw )
    if not ids :
        single =_safe_int (_first_param (params ,("id","request_id","user_id"),0 ))
        if single :
            ids =[single ]
    ids =[i for i in ids if i ]
    if not ids or action not in ("accept","remove","deny","decline"):
        return {"success":False }

    root ,player_object =load_player (username )
    results =[]
    changed =False
    for request_id in ids :
        local =msm_friends .is_local_request (player_object ,request_id )
        if not local and msm_friends .is_real_friend_wire_id (request_id ):
            import nps_online
            account_id =request_id -msm_friends .REAL_FRIEND_ID_OFFSET
            if action =="accept":
                if nps_online .accept_friend_request (account_id ):
                    friend =next ((e for e in msm_friends .real_friends_wire_list ()
                    if e .get ("user_id")==request_id ),None )
                    results .append ({"success":True ,"id":request_id ,
                    "friends":[friend ]if friend else []})
                else :
                    results .append ({"success":False ,"id":request_id })
            else :
                ok =bool (nps_online .decline_friend_request (account_id ))
                results .append ({"success":ok ,"id":request_id })
            continue
        if action =="accept":
            friend =msm_friends .accept_request (player_object ,request_id )
            if friend is None :
                results .append ({"success":False ,"id":request_id })
            else :
                changed =True
                results .append ({"success":True ,"id":request_id ,"friends":[friend ]})
        else :
            removed =msm_friends .deny_request (player_object ,request_id )
            changed =changed or removed
            results .append ({"success":bool (removed ),"id":request_id })

    if changed :
        save_player (username ,root )
    return {
    "success":any (r .get ("success")for r in results ),
    "action":"accept"if action =="accept"else "remove",
    "results":results ,
    }

def _visit_ratings (friend_object ):
    ratings =[]
    for island in (friend_object .get ("islands")or []):
        if not isinstance (island ,dict ):
            continue
        island_id =island .get ("user_island_id")
        if island_id is None :
            continue
        ratings .append ({"rated":False ,"island":SFSLong (island_id )})
    return ratings

def _visit_torch_gifts (friend_object ):
    gifts =[]
    for island in (friend_object .get ("islands")or []):
        if not isinstance (island ,dict ):
            continue
        island_id =island .get ("user_island_id")
        for structure in (island .get ("structures")or []):
            if not isinstance (structure ,dict ):
                continue
            definition =get_structure_definition (structure .get ("structure"))or {}
            if (definition .get ("structure_type")or "").lower ()=="torch":
                gifts .append ({"island_id":SFSLong (island_id ),
                "user_structure":SFSLong (structure .get ("user_structure_id",0 )or 0 )})
    return gifts

def _visit_island_type (friend_object ):
    islands =friend_object .get ("islands")or []
    active =friend_object .get ("active_island")
    for island in islands :
        if isinstance (island ,dict )and island .get ("user_island_id")==active :
            return int (island .get ("island")or island .get ("type")or 1 )
    for island in islands :
        if isinstance (island ,dict ):
            return int (island .get ("island")or island .get ("type")or 1 )
    return 1

_VISIT_DEBUG_NAME ="visit_debug.json"

_OFFICIAL_PLAYER_DEFAULTS ={
"currency_level_scale":{
"keys_daily_amt":1 ,"shards_daily_amt":9500 ,"relics_daily_amt":3 ,
"coins_daily_amt":9350000 ,"starpower_daily_amt":75 ,
"food_daily_amt":85000 ,"xp_daily_amt":9350000 ,
},
"items":{"items":[]},
"minigame_premium_tokens":0 ,
}

def _apply_missing_official_fields (wired_player ):
    for key ,value in _OFFICIAL_PLAYER_DEFAULTS .items ():
        if key not in wired_player :
            wired_player [key ]=json .loads (json .dumps (value ))
    if "last_minigame_tokens_converted" not in wired_player :
        wired_player ["last_minigame_tokens_converted"]=SFSLong (int (time .time ()*1000 ))
    return wired_player

def _visit_debug ():
    try :
        import os
        import msm_store
        path =os .path .join (os .path .dirname (msm_store .players_dir ),_VISIT_DEBUG_NAME )
        if not os .path .exists (path ):
            return {}
        with open (path ,"r",encoding ="utf-8")as handle :
            data =json .load (handle )
        return data if isinstance (data ,dict )else {}
    except Exception :
        return {}

def _apply_visit_debug (reply ,options ):
    if not options :
        return reply
    friend_object =reply .get ("friend_object")
    if isinstance (friend_object ,dict ):
        islands =friend_object .get ("islands")or []
        if "islands"in options :
            islands =islands [:max (0 ,int (options ["islands"]))]
            friend_object ["islands"]=islands
        for island in islands :
            if not isinstance (island ,dict ):
                continue
            for slot in ("monsters","structures","eggs"):
                if slot in options :
                    island [slot ]=(island .get (slot )or [])[:max (0 ,int (options [slot ]))]
        island_keys =options .get ("island_keys")
        if isinstance (island_keys ,list ):
            for island in islands :
                if isinstance (island ,dict ):
                    for key in list (island .keys ()):
                        if key not in island_keys :
                            island .pop (key ,None )
        only =options .get ("fo_only")
        if isinstance (only ,list ):
            for key in list (friend_object .keys ()):
                if key not in only :
                    friend_object .pop (key ,None )
        for key in (options .get ("fo_drop")or []):
            friend_object .pop (key ,None )
    for key in (options .get ("drop")or []):
        reply .pop (key ,None )
    extra =options .get ("extra")
    if isinstance (extra ,dict ):
        reply .update (extra )
    return reply

def _visit_reply (friend_object ):
    wired =coerce_wire_types (friend_object )
    return {"success":True ,"friend_object":wired ,
    "ratings":_visit_ratings (wired ),
    "torch_gifts":_visit_torch_gifts (wired )}

def _get_friend_visit_data (username ,params ):
    options =_visit_debug ()
    if options .get ("fail"):
        reply ={"success":False }
    else :
        reply =_apply_visit_debug (_get_friend_visit_data_real (username ,params ),options )
    if not reply .get ("success"):
        return [
        ("gs_get_friend_visit_data",reply ),
        ("gs_display_generic_message",{
        "force_logout":False ,
        "msg":_generic_message ("friend_visit_failed",username ),
        }),
        ]
    return reply

def _get_friend_visit_data_real (username ,params ):
    import msm_friends
    target_id =_safe_int (_first_param (params ,("user_id","userId","target_user_id"),0 ))

    root ,player_object =load_player (username )
    if msm_friends .find_friend (player_object ,target_id )is None and msm_friends .is_real_friend_wire_id (target_id ):
        friend_object =msm_friends .real_friend_visit_object (target_id )
        if friend_object is None :
            return {"success":False }
        return _visit_reply (friend_object )

    friend_object =msm_friends .friend_visit_object (player_object ,target_id )
    if friend_object is None :
        return {"success":False }

    save_player (username ,root )
    return _visit_reply (friend_object )

_friends_push_fingerprints ={}

def _friends_fingerprint (player_object ):
    import msm_friends
    online =[]
    try :
        online =[
        msm_friends .real_friends_wire_list (),
        msm_friends .real_pending_wire_list (),
        msm_friends .real_outgoing_wire_list (),
        ]
    except Exception :
        online =[]
    return json .dumps ([
    player_object .get ("nps_fake_friends")or [],
    player_object .get ("nps_fake_requests")or [],
    online ,
    ],sort_keys =True ,default =str )

def _friends_changed_frames (username ,player_object ):
    fingerprint =_friends_fingerprint (player_object )
    known =_friends_push_fingerprints .get (username )
    _friends_push_fingerprints [username ]=fingerprint
    if known is None or known ==fingerprint :
        return []
    return [("gs_get_friends",_get_friends (username ,{}))]

def _get_torchgifts (username ,params ):
    import msm_friends
    _root ,player_object =load_player (username )
    times =player_object .get ("can_gift_torch_times")
    if not isinstance (times ,list ):
        times =[]
    known_ids ={_safe_int (t .get ("recipient_bbbid"))for t in times if isinstance (t ,dict )}
    for friend in msm_friends .friends_wire_list (player_object ):
        bbb_id =_safe_int (friend .get ("bbb_id"))
        if bbb_id and bbb_id not in known_ids :
            times .append ({"time_of_next_gift":0 ,"recipient_bbbid":bbb_id })
    frames =[("gs_get_torchgifts",{"success":False ,"properties":[{"can_gift_torch_times":times }]})]
    return frames +_friends_changed_frames (username ,player_object )

def _collect_torchgift (username ,params ):
    import msm_friends
    target_id =_safe_int (_first_param (params ,("user_id","userId"),0 ))
    root ,player_object =load_player (username )
    if msm_toggles .is_enabled ("functioning_currencies"):
        player_object ["keys"]=(player_object .get ("keys",0 )or 0 )+1
        player_object ["keys_actual"]=player_object ["keys"]
    times =player_object .get ("can_gift_torch_times")
    if isinstance (times ,list ):
        now =int (time .time ()*1000 )
        for entry in times :
            if isinstance (entry ,dict )and _safe_int (entry .get ("recipient_bbbid"))==target_id :
                entry ["time_of_next_gift"]=now +86400000
    save_player (username ,root )
    return {"success":True ,"properties":create_player_properties (player_object )}
def _append_mod_frames (username ,frames ):
    if frames is None :
        frames =[]
    elif not isinstance (frames ,list ):
        frames =[frames ]
    mod_api .consume_lua_logs ()
    try :
        _root ,player_object =load_player (username )
        property_update =mod_api .consume_property_update (player_object ,username )
        if property_update :
            frames .append (("gs_update_properties",property_update ))
    except Exception :
        pass
    frames .extend (mod_api .consume_outgoing_frames (username ))
    if not globals ().get ("_DRAINING_LUA_REQUESTS",False ):
        globals ()["_DRAINING_LUA_REQUESTS"]=True
        try :
            for lua_command ,lua_params in mod_api .consume_lua_requests ():
                logger .info ("lua client request queued: %s params=%r",lua_command ,lua_params )
                try :
                    lua_frames =handle_command (lua_command ,lua_params )
                    if lua_frames :
                        frames .extend (lua_frames )
                except Exception as exc :
                    logger .exception ("lua client request failed for %s",lua_command )
                    frames .extend (_failure_frame (lua_command ,exc ,username ))
        finally :
            globals ()["_DRAINING_LUA_REQUESTS"]=False
    return frames

def _handled_frames (username ,command ,params ,frames ):
    if frames is None :
        frames =[]
    elif not isinstance (frames ,list ):
        frames =[frames ]
    mod_api .fire_event ("command_handled",username =username ,command =command ,
    params =params ,response_frames =[{"command":c ,"payload":p }for c ,p in frames ])
    event (command ,username =username ,params =params ,result =frames )
    return _append_mod_frames (username ,frames )

_BUG_REPORT_URL ="https://nextps.lol/api/bugs"
_BUG_REPORT_COOLDOWN_S =300
_last_bug_report_at ={}

def _auto_report_handler_error (command ,exc ,username ):
    now =time .time ()
    last =_last_bug_report_at .get (command ,0 )
    if now -last <_BUG_REPORT_COOLDOWN_S :
        return False
    _last_bug_report_at [command ]=now
    try :
        payload =json .dumps ({
        "title":f"Handler error: {command }",
        "message":f"command={command } username={username }\n\n{traceback .format_exc ()}",
        "logs":"",
        "source":"launcher-server",
        }).encode ("utf-8")
        request =urllib .request .Request (
        _BUG_REPORT_URL ,data =payload ,method ="POST",
        headers ={"Content-Type":"application/json"},
        )
        urllib .request .urlopen (request ,timeout =10 ).close ()
        return True
    except Exception :
        logger .exception ("auto bug report failed for %s",command )
        return False

def _failure_frame (command ,message ,username =None ):
    sent =_auto_report_handler_error (command ,message ,username )
    return [
    (command ,{
    "success":False ,
    "error":str (message or "handler failed"),
    "notificationOnFail":False ,
    }),
    ("gs_display_generic_message",{
    "force_logout":False ,
    "msg":_generic_message ("handler_error_reported"if sent else "handler_error",username ,command =command ),
    }),
    ]

def _finish_breeding (force_complete ):
    def handler (username ,params ):
        result =msm_monsters .finish_breeding (username ,params ,force_complete )
        if isinstance (result ,dict )and result .get ("success"):
            root ,player_object =load_player (username )
            commands =mod_api .fire_event ("breeding_finished",username =username ,params =params ,
            player_object =player_object ,result =result )
            if commands :
                save_player (username ,root )
        return result
    return handler
_BATTLE_ISLAND_TYPE =20
_ISLAND_32_TYPE =32
_DIRECT_TELEPORT_ISLAND_TYPES =(_BATTLE_ISLAND_TYPE ,_ISLAND_32_TYPE )

def _teleport_destination_type (player_object ,params ):
    for key in ("destination_island","target_island","dest_island","sent_to_island",
    "island_type","to_island_type"):
        value =_safe_int (params .get (key ))
        if value :
            return value
    for key in ("destination_user_island_id","target_user_island_id","dest_island_id",
    "destination_island_id","to_user_island_id"):
        value =_safe_int (params .get (key ))
        if value :
            island =_find_island (player_object .get ("islands")or [],value )
            if island is not None :
                return _safe_int (island .get ("island_type")or island .get ("island"))
    raw =_safe_int (params .get ("island")or params .get ("to_island"))
    if raw and raw <1000 :
        return raw
    if raw >=1000 :
        island =_find_island (player_object .get ("islands")or [],raw )
        if island is not None :
            return _safe_int (island .get ("island_type")or island .get ("island"))
    return 0

def _teleport_monster (send_home ,default_destination =None ):
    def handler (username ,params ):
        root ,player_object =load_player (username )
        destination =_teleport_destination_type (player_object ,params )or default_destination or _BATTLE_ISLAND_TYPE
        if not send_home and destination in _DIRECT_TELEPORT_ISLAND_TYPES :
            _monster_id ,source_island_id ,_monster_type =_teleport_source (username ,params )
            result =msm_monsters .move_battle_monster (username ,params ,send_home )
            if not result .get ("success"):
                return result
            _root ,player_object =load_player (username )
            source_island =_find_island (player_object .get ("islands")or [],source_island_id )
            happy_effects =[]
            if source_island is not None :
                for monster in source_island .get ("monsters")or []:
                    if monster is not None and monster .get ("user_monster_id"):
                        happy_effects .append ({
                        "user_monster_id":SFSLong (monster .get ("user_monster_id",0 )),
                        "happiness":monster .get ("happiness",0 )or 0 ,
                        })
            frames =[
            ("battle_teleport",result ),
            ("gs_multi_update_monster",{"success":True ,"monster_happy_effects":happy_effects }),
            ]
            return frames
        monster_id ,source_island_id ,monster_type =_teleport_source (username ,params )
        if send_home :
            result ,_nursery =msm_monsters .send_monster_to_home_island (username ,params )
        else :
            result ,_nursery =msm_monsters .teleport_monster_to_island (username ,params )
        if not result .get ("success"):
            return result
        return _egg_teleport_frames (username ,
        "gs_send_monster_home"if send_home else "battle_teleport",
        params ,result ,monster_id ,source_island_id ,monster_type )
    return handler
def _egg_teleport_frames (username ,command ,params ,result ,monster_id ,source_island_id ,monster_type ):
    user_egg =result .pop ("user_egg",None )
    result .pop ("user_island_id",None )
    root ,player_object =load_player (username )
    now =int (time .time ()*1000 )
    frames =[]
    if isinstance (user_egg ,dict ):
        frames .append (("gs_buy_egg",{
        "success":True ,"remove_buyback":False ,"user_egg":user_egg ,
        "properties":create_player_properties (player_object ),
        }))
    frames .append (("gs_collect_monster",{"coins":0 ,"success":True ,"user_monster_id":SFSLong (monster_id )}))
    frames .append (("gs_update_monster",{
    "collected_coins":0 ,"user_monster_id":SFSLong (monster_id ),"last_collection":SFSLong (now ),
    "properties":create_player_properties (player_object ),
    }))
    source_island =_find_island (player_object .get ("islands")or [],source_island_id )if source_island_id else None
    if source_island is not None and monster_type :
        sold_update =msm_monsters ._mark_monster_sold (source_island ,monster_type )
        if sold_update is None :
            sold =msm_monsters ._parse_sold_monsters (source_island )
            sold_update ={"island_id":SFSLong (source_island .get ("user_island_id",0 )),
            "monsters_sold":"["+",".join (str (v )for v in sold )+"]"}
        else :
            save_player (username ,root )
        frames .append (("gs_update_sold_monsters",sold_update ))
    frames .append ((command ,result ))
    return frames
def _teleport_source (username ,params ):
    monster_id =(params .get ("user_monster_id")or params .get ("monster_id")
    or params .get ("source_user_monster_id")or params .get ("id")or 0 )
    root ,player_object =load_player (username )
    for island in player_object .get ("islands")or []:
        if island is None :
            continue
        for candidate in island .get ("monsters")or []:
            if candidate is not None and candidate .get ("user_monster_id")==monster_id :
                return monster_id ,island .get ("user_island_id",0 ),candidate .get ("monster",0 )
    return monster_id ,0 ,0
def _send_to_magical_nexus_handler (username ,params ):
    logger .info ("gs_send_to_magical_nexus params: %r",params )
    monster_id ,source_island_id ,monster_type =_teleport_source (username ,params )
    result ,_nursery =msm_monsters .send_to_magical_nexus (username ,params )
    if not result .get ("success"):
        return result
    return _egg_teleport_frames (username ,"gs_send_to_magical_nexus",params ,result ,monster_id ,source_island_id ,monster_type )
BBLIZARD_ISLAND_TYPE =32
def _request_bblizard_teleport_handler (username ,params ):
    logger .info ("gs_request_bblizard_teleport params: %r",params )
    forwarded =dict (params )
    forwarded ["destination_island"]=BBLIZARD_ISLAND_TYPE
    return _teleport_monster (False )(username ,forwarded )
def _send_to_paironormal_handler (username ,params ):
    logger .info ("gs_send_to_paironormal params: %r",params )
    monster_id ,source_island_id ,monster_type =_teleport_source (username ,params )
    result ,_nursery =msm_monsters .send_to_paironormal (username ,params )
    if not result .get ("success"):
        return result
    return _egg_teleport_frames (username ,"gs_send_to_paironormal",params ,result ,monster_id ,source_island_id ,monster_type )
def _buy_egg_handler (username ,params ):
    logger .info ("gs_buy_egg params: %r",params )
    result ,update =msm_monsters .buy_egg (username ,params )
    if result .get ("success"):
        root ,player_object =load_player (username )
        egg =result .get ("user_egg")or {}
        commands =mod_api .fire_event ("egg_bought",username =username ,params =params ,
        player_object =player_object ,egg =egg )
        if commands :
            save_player (username ,root )
    return result
def _costume_action (command ):
    def handler (username ,params ):
        return msm_monsters .costume_action (username ,params ,command )
    return handler
def _collect_monster (command ,fn =msm_monsters .collect_monster ):
    def handler (username ,params ):
        outcome =fn (username ,params )
        response_command =command
        if command =="gs_collect_monster"and params .get ("user_monster_id")==-1 :
            response_command ="gs_collect_multi_monster"
        if isinstance (outcome ,tuple ):
            root ,player_object =load_player (username )
            commands =mod_api .fire_event ("monster_collected",username =username ,command =response_command ,
            params =params ,player_object =player_object )
            if commands :
                save_player (username ,root )
        if isinstance (outcome ,tuple ):
            result ,update_bundle =outcome
            frames =[(response_command ,result )]
            if response_command !="gs_collect_multi_monster":
                for update in update_bundle .get ("monster_updates",[]):
                    frames .append (("gs_update_monster",update ))
            return frames
        return outcome
    return handler
def _hatch_egg_handler (username ,params ):
    result =msm_monsters .hatch_egg (username ,params )
    if not isinstance (result ,dict ):
        return result
    happy_effects =result .pop ("monster_happy_effects",None )
    nursery_update =result .pop ("nursery_update",None )
    workshop_monster_updates =result .pop ("workshop_monster_updates",None )
    workshop_update_user_monster_id =result .pop ("workshop_update_user_monster_id",None )
    frames =[("gs_hatch_egg",result )]
    if nursery_update :
        frames .append (("gs_update_structure",nursery_update ))
    if workshop_monster_updates :
        update_payload ={
        "success":True ,
        "update_monster_list":workshop_monster_updates ,
        }
        if workshop_update_user_monster_id is not None :
            update_payload ["user_monster_id"]=workshop_update_user_monster_id
        frames .append (("gs_multi_update_monster",update_payload ))
    frames +=_happy_effects_frames (happy_effects )
    player_object =None
    try :
        _root ,player_object =load_player (username )
    except Exception :
        player_object =None
    return _append_mod_frames (username ,frames )
def _viewed_egg_handler (username ,params ):
    result ,sold_update =msm_monsters .viewed_egg (username ,params )
    frames =[]
    if sold_update :
        frames .append (("gs_update_sold_monsters",sold_update ))
    frames .append (("gs_viewed_egg",result ))
    return frames
def _sell_monster_handler (username ,params ):
    result ,sold_update =msm_monsters .sell_monster (username ,params )
    happy_effects =result .pop ("monster_happy_effects",None )if isinstance (result ,dict )else None
    frames =[]
    if sold_update :
        frames .append (("gs_update_sold_monsters",sold_update ))
    frames .append (("gs_sell_monster",result ))
    frames +=_happy_effects_frames (happy_effects )
    return frames
def _purchase_buyback_handler (username ,params ):
    outcome =msm_monsters .purchase_buyback (username ,params )
    if isinstance (outcome ,tuple ):
        result ,sold_update =outcome
    else :
        result ,sold_update =outcome ,None
    happy_effects =result .get ("monster_happy_effects")if isinstance (result ,dict )else None
    frames =[]
    if sold_update :
        frames .append (("gs_update_sold_monsters",sold_update ))
    frames .append (("gs_purchase_buyback",result ))
    frames +=_happy_effects_frames (happy_effects )
    return frames
def _facebook_help_instances_stub (username ,params ):
    return {"success":True ,"egg_results":[],"breeding_results":[],"count":0 }
def _buy_island_handler (username ,params ):
    result =msm_islands .buy_island (username ,params )
    if result .get ("success"):
        root ,player_object =load_player (username )
        commands =mod_api .fire_event ("island_bought",username =username ,params =params ,
        player_object =player_object ,island =result .get ("user_island")or {})
        if commands :
            save_player (username ,root )
    return result
def _buy_structure_handler (username ,params ):
    result =msm_structures .buy_structure (username ,params )
    if result .get ("success"):
        root ,player_object =load_player (username )
        commands =mod_api .fire_event ("structure_bought",username =username ,params =params ,
        player_object =player_object ,structure =result .get ("user_structure")or {})
        if commands :
            save_player (username ,root )
    happy_effects =result .get ("monster_happy_effects")if isinstance (result ,dict )else None
    frames =[("gs_buy_structure",result )]
    frames +=_happy_effects_frames (happy_effects )
    return frames
def _breed_monsters_handler (username ,params ):
    result =msm_monsters .breed_monsters (username ,params )
    if result .get ("success"):
        root ,player_object =load_player (username )
        commands =mod_api .fire_event ("breeding_started",username =username ,params =params ,
        player_object =player_object ,breeding =result .get ("user_breeding")or {})
        if commands :
            save_player (username ,root )
    return result
def _start_fuzing_handler (username ,params ):
    result =msm_monsters .start_fuzing (username ,params )
    if result .get ("success"):
        root ,player_object =load_player (username )
        commands =mod_api .fire_event ("fuzing_started",username =username ,params =params ,
        player_object =player_object ,fuzing =result .get ("user_fuzing")or {})
        if commands :
            save_player (username ,root )
    return result
def _finish_fuzing_handler (username ,params ):
    result =msm_monsters .finish_fuzing (username ,params ,True )
    if not result .get ("success"):
        return result
    root ,player_object =load_player (username )
    commands =mod_api .fire_event ("fuzing_finished",username =username ,params =params ,
    player_object =player_object ,result =result )
    if commands :
        save_player (username ,root )
    return result
def _nps_mod_command (username ,params ):
    root ,player_object =load_player (username )
    mod_api .fire_event ("mod_command",username =username ,command ="nps_mod_command",
    params =params ,player_object =player_object )
    save_player (username ,root )
    return {"success":True ,"handled":True ,"params":params }
_BATTLE_CURRENCY_REWARD_KEYS =("coins","diamonds","food","relics","keys","ethereal_currency","medals")
def _battle_monster_slot (monster_id ,level ,h_flip ):
    definition =get_monster_definition (monster_id )or {}
    return {
    "monsterId":monster_id ,"level":level or 1 ,
    "name":definition .get ("common_name")or definition .get ("name")or "",
    "hFlip":h_flip ,
    }
def _battle_claim_versus_rewards (username ,params ):
    root =load_user_data (username )
    player_object =root .get ("player_object")or {}
    tier =params .get ("tier",1 )or 1
    campaign_id =params .get ("campaign_id",1000 )or 1000
    reward ={"coins":500 *tier ,"food":200 *tier }

    claimed =player_object .setdefault ("versus_rewards_claimed",[])
    claim_key =f"{campaign_id }:{tier }"
    if claim_key not in claimed :
        claimed .append (claim_key )
        for key ,amount in reward .items ():
            new_value =(player_object .get (key ,0 )or 0 )+amount
            player_object [key ]=new_value
            player_object [f"{key }_actual"]=new_value
    now_ms =int (time .time ()*1000 )
    versus_list =player_object .get ("battle_versus")
    if isinstance (versus_list ,list ):
        entry =next ((v for v in versus_list if isinstance (v ,dict )and v .get ("campaign_id")==campaign_id ),None )
        if entry is not None :
            entry ["tier"]=max (entry .get ("tier",1 )or 1 ,tier )
            entry ["attempts"]=msm_monsters .BATTLE_VERSUS_MAX_ATTEMPTS
            entry ["started_on"]=now_ms
            entry ["schedule_started_on"]=now_ms
            entry ["refreshes_on"]=now_ms +86400000
    save_user_data (username ,root )
    result ={
    "success":True ,"tier":tier ,"campaign_id":campaign_id ,
    "claimed_on":SFSLong (int (time .time ()*1000 )),
    "season_rewards":reward ,
    "properties":create_player_properties (player_object ),
    }
    add_actual_currencies (result ,player_object )
    return result
def _battle_set_music (username ,params ):
    root ,player_object =load_player (username )
    battle_state =player_object .setdefault ("battle",{})
    track =params .get ("track",params .get ("currently_playing"))
    muted =params .get ("muted")
    if track is not None :
        battle_state ["currently_playing_music"]=track
    if muted is not None :
        battle_state ["music_muted"]=bool (muted )
    save_player (username ,root )
    return {
    "success":True ,
    "currently_playing":battle_state .get ("currently_playing_music",0 )or 0 ,
    "muted":bool (battle_state .get ("music_muted",False )),
    }
def _client_keep_alive (username ,params ):
    return {}
def _metric_event (username ,params ):
    return {"event":params .get ("event","")}
def _collect_rewards_stub (username ,params ):
    return {"success":False ,"notificationOnFail":False }
def _update_properties (username ,params ):
    root ,player_object =load_player (username )
    changed =False
    currency =params .get ("currency")or params .get ("type")or params .get ("property")
    value =params .get ("value",params .get ("new_value",params .get ("amount")))
    if currency and value is not None :
        mod_api .set_currency (player_object ,str (currency ),value )
        changed =True
    mod_api .fire_event ("update_properties",username =username ,params =params ,player_object =player_object )
    if changed :
        save_player (username ,root )
    return {"success":True ,"properties":create_player_properties (player_object )}
def _collect_daily_reward (username ,params ):
    root ,player_object =load_player (username )
    logger .info ("DAILY_REWARD_DEBUG collect: bonus_type=%r amount=%r last_claimed=%r instant_timers=%r",
    player_object .get ("daily_bonus_type"),player_object .get ("daily_bonus_amount"),
    player_object .get ("last_daily_bonus_claimed"),msm_toggles .is_enabled ("instant_timers"))
    bonus_type =player_object .get ("daily_bonus_type")or "none"
    bonus_amount =_safe_int (player_object .get ("daily_bonus_amount"))
    granted =bonus_type and bonus_type not in ("none","dailyReward","deferred")and bonus_amount >0
    if not granted :
        _backfill_daily_reward_state (player_object )
        bonus_type =player_object .get ("daily_bonus_type")or "none"
        bonus_amount =_safe_int (player_object .get ("daily_bonus_amount"))
        granted =bonus_type and bonus_type not in ("none","dailyReward","deferred")and bonus_amount >0
    logger .info ("DAILY_REWARD_DEBUG granted=%r type=%r amount=%r day=%r",
    granted ,bonus_type ,bonus_amount ,player_object .get ("reward_day"))
    if granted :
        currency_map ={
        "coin":"coins","coins":"coins",
        "diamond":"diamonds","diamonds":"diamonds",
        "food":"food",
        "shard":"ethereal_currency","shards":"ethereal_currency","ethereal":"ethereal_currency",
        "key":"keys","keys":"keys",
        "relic":"relics","relics":"relics",
        "star":"starpower","starpower":"starpower",
        "wildcard":"egg_wildcards","egg_wildcards":"egg_wildcards",
        }
        key =currency_map .get (str (bonus_type ))
        if key :
            player_object [key ]=_safe_int (player_object .get (key ))+bonus_amount
            actual_key =f"{key }_actual"
            if actual_key in player_object :
                player_object [actual_key ]=player_object [key ]
    _clear_daily_bonus (player_object ,claimed =bool (granted ))
    save_player (username ,root )
    properties =create_player_properties (player_object )
    return {"properties":properties }
def _daily_login_buyback (username ,params ):

    root ,player_object =load_player (username )
    _ensure_daily_calendar_structures (player_object )

    reward_day ,bonus_type ,bonus_amount =_advance_daily_calendar_reward (player_object )
    save_player (username ,root )
    return {
    "success":True ,
    "properties":[
    {"reward_day":reward_day },
    {"daily_bonus_type":bonus_type },
    {"daily_bonus_amount":bonus_amount },
    {"cachedRewardDay":reward_day },
    ],
    }
_DAILY_CALENDAR_CURRENCY_TYPE_CODES ={
"coins":4 ,"ethereal_currency":5 ,"food":7 ,"relics":8 ,"diamonds":9 ,
}
_DAILY_CALENDAR_GENERIC_CURRENCY_TYPE_CODE =16
_DAILY_CALENDAR_BUFF_TYPE_CODE =14
def _collect_daily_cumulative_login_rewards (username ,params ):

    root ,player_object =load_player (username )
    _ensure_daily_calendar_structures (player_object )
    calendar =player_object ["daily_cumulative_login"]
    _ ,bonus_type ,bonus_amount =_next_daily_calendar_reward (player_object )
    bonus_type =str (bonus_type or "coins")
    if bonus_type !="none"and bonus_amount >0 :
        player_object [bonus_type ]=_safe_int (player_object .get (bonus_type ))+bonus_amount
        actual_key =f"{bonus_type }_actual"
        if actual_key in player_object :
            player_object [actual_key ]=_safe_int (player_object .get (actual_key ))+bonus_amount
    calendar ["reward_idx"]=_safe_int (calendar .get ("reward_idx"))+1
    calendar ["total"]=_safe_int (calendar .get ("total"))+1
    calendar ["next_collect"]=next_daily_reset_timestamp ()
    player_object ["daily_bonus_type"]="deferred"
    player_object ["daily_bonus_amount"]=1
    type_code =_DAILY_CALENDAR_CURRENCY_TYPE_CODES .get (bonus_type ,_DAILY_CALENDAR_GENERIC_CURRENCY_TYPE_CODE )
    loot_entry ={"amount":bonus_amount ,"premium":False ,"id":0 ,"type":type_code }
    total =_safe_int (calendar .get ("total"))
    calendar_id =_safe_int (calendar .get ("calendar_id"),1 )
    next_collect =_safe_int (calendar .get ("next_collect"))
    new_reward_idx =_safe_int (calendar .get ("reward_idx"))
    save_player (username ,root )
    result ={
    "success":True ,
    "total":total ,"calendar_id":calendar_id ,
    "loot":[loot_entry ],
    "next_collect":SFSLong (next_collect ),
    "reward_idx":new_reward_idx ,
    "state":{
    "total":total ,"calendar_id":calendar_id ,
    "next_collect":SFSLong (next_collect ),"reward_idx":new_reward_idx ,
    },
    }
    if type_code ==_DAILY_CALENDAR_BUFF_TYPE_CODE :
        result ["updateTimedEvents"]=True
    return result
def _welcome_mail (now ,username ):
    sender_name =DEFAULT_USERNAME
    title =_generic_message ("welcome_mail_title",username )
    return {
    "id":1 ,"user_mail_id":1 ,"message_id":1 ,
    "title":title ,
    "shortTitle":"Welcome","short_title":"Welcome",
    "message":title ,
    "sender":sender_name ,"from":sender_name ,"from_name":sender_name ,
    "senderName":sender_name ,"sender_name":sender_name ,"author":sender_name ,
    "icon":"mail",
    "received":SFSLong (now ),"received_on":SFSLong (now ),
    "expiry":0 ,"urgent":False ,"read":False ,
    }
def _ensure_mailbox (player_object ,username =None ):
    mailbox =player_object .get ("mailbox")
    if not isinstance (mailbox ,list ):
        mailbox =[]
    if not any ((m or {}).get ("message_id")==1 and (m or {}).get ("user_mail_id")==1 for m in mailbox if isinstance (m ,dict )):
        mailbox .insert (0 ,_welcome_mail (int (time .time ()*1000 ),username ))
    unread =sum (1 for m in mailbox if isinstance (m ,dict )and not m .get ("read",False ))
    player_object ["mailbox"]=mailbox
    player_object ["num_unread_mail"]=unread
    player_object ["unread_mail_count"]=unread
    player_object ["new_mail"]=unread >0
    return mailbox ,unread
def _get_messages (username ,params ):
    root ,player_object =load_player (username )
    mailbox ,unread =_ensure_mailbox (player_object ,username )
    save_player (username ,root )
    return {"success":True ,"messages":mailbox ,"unread_count":unread ,"num_unread":unread ,"delete_ids":[]}
def _delete_mail (username ,params ):
    mail_id =_safe_int (params .get ("id"))
    root ,player_object =load_player (username )
    mailbox ,_unread =_ensure_mailbox (player_object ,username )
    entry =next ((m for m in mailbox if isinstance (m ,dict )and _safe_int (m .get ("id"))==mail_id ),None )
    properties =[]
    if entry is not None :
        monster_id =_safe_int (entry .get ("attachment_monster_id"))
        if monster_id :
            definition =get_monster_definition (monster_id )or {}
            entity_id =_safe_int (definition .get ("entity_id"))
            if entity_id :
                grant_inventory_item (player_object ,entity_id ,1 )
            free_unlocks =player_object .setdefault ("free_monster_unlocks",[])
            if monster_id not in free_unlocks :
                free_unlocks .append (monster_id )
        mailbox [:]=[m for m in mailbox if m is not entry ]
        player_object ["mailbox"]=mailbox
        unread =sum (1 for m in mailbox if isinstance (m ,dict )and not m .get ("read",False ))
        player_object ["num_unread_mail"]=unread
        player_object ["unread_mail_count"]=unread
        player_object ["new_mail"]=unread >0
    save_player (username ,root )
    if entry is not None :
        properties =create_player_properties (player_object )
        append_inventory_property (properties ,player_object )
    return {"success":True ,"properties":properties }
_STATIC_ALIAS_RESPONSES ={
"gs_daily_login_reward_seen":"gs_update_island_tutorials",
"gs_news_seen":"gs_update_island_tutorials",
"gs_generic_success":"gs_update_island_tutorials",
"gs_update_island_tutorials":"gs_update_island_tutorials",
}
def handle_client_version (username ,params ):
    return {"success":True }
GAMEPLAY_HANDLERS ={
"client-version":handle_client_version ,
"nps_mod_command":_nps_mod_command ,
"nps_command":_nps_mod_command ,
"gs_change_island":handle_gs_change_island ,
"gs_player":handle_gs_player ,
"gs_buy_island":_buy_island_handler ,
"update_island_mode":_simple (msm_islands .update_island_mode ),
"gs_save_island_warp_speed":_simple (msm_islands .set_warp_island ),
"gs_mute_island":_simple (msm_islands .mute_island ),
"gs_buy_structure":_buy_structure_handler ,
"gs_move_structure":_move_with_happiness ("gs_move_structure",msm_structures .move_structure ,structure =True ),
"move_structure":_with_structure_update ("move_structure",msm_structures .move_structure ,always =True ),
"gs_update_structure_position":_with_structure_update ("gs_update_structure_position",msm_structures .move_structure ,always =True ),
"gs_sell_structure":_with_happy_effects ("gs_sell_structure",msm_structures .sell_structure ),
"gs_remove_obstacle":_simple (msm_structures .clear_obstacle ),
"gs_clear_obstacle":_simple (msm_structures .clear_obstacle ),
"gs_start_obstacle":_with_structure_update ("gs_start_obstacle",msm_structures .start_obstacle ),
"gs_collect_nucleus_reward":_simple (msm_structures .collect_nucleus_reward ),
"gs_clear_obstacle_speed_up":_with_structure_update ("gs_clear_obstacle_speed_up",msm_structures .clear_obstacle_speed_up ),
"gs_speed_up_clear_obstacle":_with_structure_update ("gs_speed_up_clear_obstacle",msm_structures .clear_obstacle_speed_up ),
"gs_speedup_clear_obstacle":_with_structure_update ("gs_speedup_clear_obstacle",msm_structures .clear_obstacle_speed_up ),
"gs_speed_up_obstacle":_with_structure_update ("gs_speed_up_obstacle",msm_structures .clear_obstacle_speed_up ),
"gs_skip_obstacle":_with_structure_update ("gs_skip_obstacle",msm_structures .clear_obstacle_speed_up ),
"gs_finish_structure":_with_structure_update ("gs_finish_structure",msm_structures .finish_structure ),
"gs_purchase_memory_mini_game":_simple (msm_rewards .purchase_memory_mini_game ),
"gs_collect_memory_mini_game":_simple (msm_rewards .collect_memory_mini_game ),
"gs_buy_remove_obstacle":_simple (msm_structures .clear_obstacle ),
"gs_remove_island_obstacle":_simple (msm_structures .clear_obstacle ),
"gs_flip_structure":_with_structure_update ("gs_flip_structure",msm_structures .flip_structure ,always =True ),
"gs_mute_structure":_structure_update_only (msm_structures .mute_structure ),
"gs_start_upgrade_structure":_structure_update_only (_second_only (msm_structures .start_upgrade_structure )),
"gs_upgrade_structure":_structure_update_only (_second_only (msm_structures .start_upgrade_structure )),
"gs_update_structure":_simple (msm_structures .update_structure ),
"gs_speed_up_structure":_with_structure_update_first ("gs_speed_up_structure",msm_structures .speed_up_structure ),
"gs_finish_upgrade_structure":_with_structure_update ("gs_finish_upgrade_structure",msm_structures .finish_upgrade_structure ),
"gs_speed_up_upgrade_structure":_with_structure_update_first ("gs_speed_up_upgrade_structure",msm_structures .speed_up_upgrade_structure ),
"gs_speedup_upgrade_structure":_with_structure_update_first ("gs_speedup_upgrade_structure",msm_structures .speed_up_upgrade_structure ),
"gs_speed_up_upgrade_structure_video":_with_structure_update_first ("gs_speed_up_upgrade_structure_video",msm_structures .speed_up_upgrade_structure ),
"gs_speedup_upgrade_structure_video":_with_structure_update_first ("gs_speedup_upgrade_structure_video",msm_structures .speed_up_upgrade_structure ),
"gs_start_fuguing":_with_structure_update ("gs_start_fuguing",msm_structures .start_fuguing ),
"gs_finish_fuguing":_finish_fuguing_handler ,
"gs_merge_fugue":_with_structure_update ("gs_merge_fugue",msm_structures .merge_fugue ),
"gs_speed_up_fuguing":_with_structure_update ("gs_speed_up_fuguing",msm_structures .speed_up_fuguing ),
"gs_speedup_fuguing":_with_structure_update ("gs_speedup_fuguing",msm_structures .speed_up_fuguing ),

"gs_viewed_fugued_monster":_simple (msm_structures .viewed_fugued_monster ),
"gs_collect_structure":_with_structure_update_event ("structure_collected","gs_collect_structure",msm_structures .collect_structure ),
"gs_collect_from_mine":_with_structure_update_event ("mine_collected","gs_collect_from_mine",msm_structures .collect_mine ),
"gs_check_in_structure":_simple (msm_structures .store_structure ),
"gs_store_structure":_simple (msm_structures .store_structure ),
"gs_store_decoration":_simple (msm_structures .store_structure ),
"gs_pack_in_structure":_simple (msm_structures .store_structure ),
"gs_pack_in_decoration":_simple (msm_structures .store_structure ),
"gs_move_structure_to_storage":_simple (msm_structures .store_structure ),
"gs_check_out_structure":_simple (msm_structures .unstore_structure ),
"gs_unstore_structure":_simple (msm_structures .unstore_structure ),
"gs_unstore_decoration":_simple (msm_structures .unstore_structure ),
"gs_pack_out_structure":_simple (msm_structures .unstore_structure ),
"gs_pack_out_decoration":_simple (msm_structures .unstore_structure ),
"gs_move_structure_from_storage":_simple (msm_structures .unstore_structure ),
"gs_start_baking":_simple (msm_structures .start_baking ),
"gs_start_rebake":_simple (msm_structures .start_rebake ),
"gs_speed_up_baking":_simple (msm_structures .speed_up_baking ),
"gs_speedup_baking":_simple (msm_structures .speed_up_baking ),
"gs_finish_baking":_simple (msm_structures .finish_baking ),
"gs_move_monster":_move_with_happiness ("gs_move_monster",msm_monsters .move_monster ,structure =False ),
"move_monster":_with_monster_update ("move_monster",msm_monsters .move_monster ),
"gs_update_monster_position":_with_monster_update ("gs_update_monster_position",msm_monsters .move_monster ),
"gs_flip_monster":_with_monster_update ("gs_flip_monster",msm_monsters .flip_monster ),
"gs_mute_monster":_with_monster_update ("gs_mute_monster",msm_monsters .mute_monster ),
"gs_add_soul_link":_with_monster_update_first ("gs_add_soul_link",msm_monsters .add_soul_link ),
"gs_remove_soul_link":_with_monster_update_first ("gs_remove_soul_link",msm_monsters .remove_soul_link ),
"gs_toggle_titansoul_fx":_with_monster_update_first ("gs_toggle_titansoul_fx",msm_monsters .toggle_titansoul_fx ),
"gs_mega_monster_message":_mega_monster_handler ,
"gs_biggify_monster":_mega_monster_handler ,
"gs_bigify_monster":_mega_monster_handler ,
"gs_bigfy_monster":_mega_monster_handler ,
"gs_mega_monster":_mega_monster_handler ,
"gs_feed_monster":_with_monster_update_event ("monster_fed","gs_feed_monster",msm_monsters .feed_monster ),
"gs_sell_monster":_sell_monster_handler ,
"gs_purchase_buyback":_purchase_buyback_handler ,
"gs_name_monster":_simple (msm_monsters .name_monster ),
"gs_collect_monster":_collect_monster ("gs_collect_monster"),
"gs_collect_multi_monster":_collect_monster ("gs_collect_multi_monster",msm_monsters .collect_multi_monster ),
"gs_buy_egg":_buy_egg_handler ,
"gs_hatch_egg":_hatch_egg_handler ,
"gs_sell_egg":_discard_structure_update (msm_monsters .sell_egg ),
"gs_speed_up_hatching":_discard_structure_update (msm_monsters .speed_up_hatching ),
"gs_viewed_egg":_viewed_egg_handler ,
"gs_viwed_egg":_viewed_egg_handler ,
"gs_claim_hatched_egg":_simple (msm_monsters .claim_hatched_egg ),
"gs_breed_monsters":_breed_monsters_handler ,
"gs_finish_breeding":_finish_breeding (True ),
"gs_finish_breed_monsters":_finish_breeding (True ),
"gs_finish_breeding_monsters":_finish_breeding (True ),
"gs_finish_breeding_video":_finish_breeding (True ),
"gs_speed_up_breeding":_with_structure_update ("gs_speed_up_breeding",msm_monsters .speed_up_breeding ),
"gs_speed_up_breeding_video":_with_structure_update ("gs_speed_up_breeding_video",msm_monsters .speed_up_breeding ),
"gs_speedup_breeding":_with_structure_update ("gs_speedup_breeding",msm_monsters .speed_up_breeding ),
"gs_speedup_breeding_video":_with_structure_update ("gs_speedup_breeding_video",msm_monsters .speed_up_breeding ),
"gs_speedup_breed_monsters":_with_structure_update ("gs_speedup_breed_monsters",msm_monsters .speed_up_breeding ),
"gs_speedup_breeding_monsters":_with_structure_update ("gs_speedup_breeding_monsters",msm_monsters .speed_up_breeding ),
"gs_cancel_breeding":_simple (msm_monsters .cancel_breeding ),
"gs_remove_breeding":_simple (msm_monsters .cancel_breeding ),
"gs_start_fuzing":_start_fuzing_handler ,
"gs_speed_up_fuzing":_with_structure_update ("gs_speed_up_fuzing",msm_monsters .speed_up_fuzing ),
"gs_finish_fuzing":_finish_fuzing_handler ,
"gs_store_buddy":_simple (msm_monsters .store_buddy ),
"gs_unstore_buddy":_with_structure_update ("gs_unstore_buddy",msm_monsters .unstore_buddy ),
"gs_start_amber_evolve":_simple (msm_monsters .start_amber_evolve ),
"gs_speedup_amber_evolve":_simple (msm_monsters .speed_up_amber_evolve ),
"gs_speed_up_amber_evolve":_simple (msm_monsters .speed_up_amber_evolve ),
"gs_finish_amber_evolve":_with_monster_update ("gs_finish_amber_evolve",lambda u ,p :msm_monsters .finish_amber_evolve (u ,p ,True )),
"gs_viewed_cruc_unlock":_simple (msm_islands .viewed_crucible_unlock ),
"gs_viewed_cruc_monst":_simple (msm_islands .viewed_crucible_monster ),
"gs_collect_cruc_heat":_with_monster_update ("gs_collect_cruc_heat",msm_islands .collect_crucible_heat ),
"gs_check_in_monster":_simple (msm_monsters .store_monster ),
"gs_store_monster":_simple (msm_monsters .store_monster ),
"gs_move_monster_to_hotel":_simple (msm_monsters .store_monster ),
"gs_unstore_monster":_simple (msm_monsters .unstore_monster ),
"gs_check_out_monster":_simple (msm_monsters .unstore_monster ),
"gs_move_monster_from_hotel":_simple (msm_monsters .unstore_monster ),
"battle_teleport":_teleport_monster (False ,default_destination =_BATTLE_ISLAND_TYPE ),
"gs_request_bblizard_teleport":_request_bblizard_teleport_handler ,
"gs_teleport_monster":_teleport_monster (False ),
"gs_teleport":_teleport_monster (False ),
"gs_transpose_monster":_teleport_monster (False ),
"gs_move_monster_to_island":_teleport_monster (False ),
"gs_send_monster_home":_teleport_monster (True ),
"gs_send_to_magical_nexus":_send_to_magical_nexus_handler ,
"gs_send_to_paironormal":_send_to_paironormal_handler ,
"gs_send_bonus_for_looking_up_friend_id":_generic_success (),
"gs_buy_island_skin":_simple (msm_islands .buy_island_skin ),
"gs_activate_island_theme":_simple (msm_islands .activate_island_theme ),
"gs_set_active_island_theme":_simple (msm_islands .activate_island_theme ),
"gs_equip_island_skin":_simple (msm_islands .activate_island_theme ),
"gs_mute_castle":_simple (msm_islands .mute_castle ),
"gs_get_island_boosts":_simple (msm_islands .get_island_boosts ),
"gs_island_boosts":_simple (msm_islands .get_island_boosts ),
"gs_get_island_boost":_simple (msm_islands .get_island_boosts ),
"gs_save_happiness_warnings_status":_generic_success (),
"gs_collect_daily_reward":_collect_daily_reward ,
"gs_collect_flip_level":_simple (msm_rewards .collect_flip_level ),
"gs_collect_flip_mini_game":_simple (msm_rewards .collect_flip_mini_game ),
"gs_collect_scratch_off":_simple (msm_rewards .collect_scratch_off ),
"db_clubbox_acts":_simple (msm_clubbox .db_clubbox_acts ),
"gs_create_clubbox":_simple (msm_clubbox .create_clubbox ),
"gs_move_clubbox":_simple (msm_clubbox .move_clubbox ),
"gs_set_last_act":_simple (msm_clubbox .set_last_act ),
"gs_timed_events":_simple (msm_minigames .gs_timed_events ),
"minigame_create":_simple (msm_minigames .minigame_create ),
"minigame_verify_session":_simple (msm_minigames .minigame_verify_session ),
"minigame_handle_bonus":_simple (msm_minigames .minigame_handle_bonus ),
"minigame_next_level":_simple (msm_minigames .minigame_next_level ),
"minigame_doorprize":_simple (msm_minigames .minigame_doorprize ),
"minigame_spinprize":_simple (msm_minigames .minigame_spinprize ),
"db_precheck":_simple (db_precheck ),
"db_minigames":_simple (db_minigames ),
"db_bakery_foods":_simple (db_bakery_foods ),
"db_island_themes":_simple (db_island_themes ),
"db_attuner_gene":_simple (db_attuner_gene ),
"gs_daily_login_buyback":_daily_login_buyback ,
"gs_collect_daily_cumulative_login_rewards":_collect_daily_cumulative_login_rewards ,
"collect_daily_cumulative_login_rewards":_collect_daily_cumulative_login_rewards ,
"gs_delete_mail":_delete_mail ,
"gs_quest":_quest_handler ,
"gs_quest_read":_quest_read_handler ,
"gs_quests_read":_quests_read_handler ,
"gs_quest_event":_quest_event_handler ,
"gs_quest_collect":_quest_collect_handler ,
"gs_finish_dish_harmonizing":_with_structure_update ("gs_finish_dish_harmonizing",msm_structures .finish_dish_harmonizing ,always =True ),
"gs_flip_minigame_cost":_simple (msm_rewards .flip_minigame_cost ),
"gs_friend_request_manage":_friend_request_manage ,
"gs_friend_request":_send_friend_request ,
"gs_remove_friend":_remove_friend ,
"gs_friend_remove":_remove_friend ,
"gs_delete_friend":_remove_friend ,
"gs_get_code":_generic_success (),
"gs_transfer_code":_transfer_code_handler ,
"gs_get_friend_visit_data":_get_friend_visit_data ,
"gs_get_friends":_get_friends ,
"gs_get_island_rank":_simple (msm_islands .get_island_rank ),
"gs_get_messages":_get_messages ,
"gs_get_random_tribes":_generic_success (["tribes"]),
"gs_get_ranked_island_data":_generic_success (["islands"]),
"gs_get_top10_island_data":_generic_success (["islands"]),
"gs_get_torchgifts":_get_torchgifts ,
"gs_collect_torchgift":_collect_torchgift ,
"gs_currency_conversion":_currency_conversion_handler ,
"gs_handle_facebook_help_instances":_facebook_help_instances_stub ,
"battle_start":msm_battle .battle_start ,
"battle_finish":msm_battle .battle_finish ,
"battle_claim_versus_rewards":_battle_claim_versus_rewards ,
"battle_set_music":_battle_set_music ,
"battle_start_training":_with_monster_update ("battle_start_training",msm_monsters .battle_start_training ),
"battle_finish_training":_with_monster_update ("battle_finish_training",msm_monsters .battle_finish_training ),
"client_keep_alive":_client_keep_alive ,
"keep_alive":_client_keep_alive ,
"metric_event":_metric_event ,
"gs_get_tribal_island_data":_generic_success (["tribe","members"]),
"gs_hype_game":_simple (msm_clubbox .hype_game ),
"gs_update_dish_harmonizer_target":_with_structure_update ("gs_update_dish_harmonizer_target",msm_structures .update_dish_harmonizer_target ,always =True ),
"gs_incubate_dish_harmonizer_egg":_with_structure_update ("gs_incubate_dish_harmonizer_egg",msm_structures .incubate_dish_harmonizer_egg ,always =True ),
"gs_leave_tribe_request":_generic_success (),
"gs_light_torch":_light_torch ,
"gs_place_on_gold_island":_simple (msm_monsters .place_on_gold_island ),
"gs_play_scratch_off":_simple (msm_rewards .play_scratch_off ),
"gs_purchase_scratch_off":_simple (msm_rewards .play_scratch_off ),
"gs_player_has_scratch_off":_simple (msm_rewards .player_has_scratch_off ),
"gs_get_prize_wheel":_simple (msm_rewards .get_prize_wheel ),
"gs_spin_prize_wheel":_simple (msm_rewards .spin_prize_wheel ),
"gs_collect_prize_wheel":_simple (msm_rewards .collect_prize_wheel ),
"gs_get_memory_game_numbers":_simple (msm_rewards .get_memory_game_numbers ),
"gs_player_save_profile":_player_save_profile_handler ,
"gs_set_displayname":_set_displayname_handler ,
"gs_set_islandname":_set_island_field_handler ("name",("name","island_name","islandName")),
"gs_set_moniker":_set_player_field_handler ("moniker",("moniker","name")),
"gs_set_avatar":_set_player_field_handler ("avatar",("avatar","avatar_id","avatarId")),
"gs_set_tribename":_set_player_field_handler ("tribe_name",("name","tribe_name","tribeName")),
"gs_set_last_card_album":_set_player_field_handler ("last_card_album",("card_album_id","album_id","last_card_album")),
"gs_set_light_torch_flag":_set_island_field_handler ("light_torch_flag",("light_torch_flag","flag","value")),
"gs_set_fav_friend":_echo_success ("friend_id","user_id","is_fav"),
"gs_player_rotate_friend_code":_generic_success (),
"gs_playerprofile_permissions":_generic_success (),
"gs_player_encore_state":_simple (msm_rewardtracks .player_encore_state ),
"gs_process_unclaimed_purchases":_generic_success (),
"gs_delete_account":_generic_success (),
"gs_report_user":_generic_success (),
"gs_referral_request":_generic_success (),
"gs_offer_completed":_generic_success (),
"gs_paywall_updated":_generic_success (),
"gs_update_achievement_status":_echo_success ("achievement_id","status"),
"gs_socialfeed":_generic_success (["items"]),
"gs_sync_friends":_generic_success (["friends"]),
"gs_friend_discover_refresh":_friend_discover ,
"gs_get_random_visit_data":_random_visit_handler ,
"gs_visit_specific_friend_island":_get_friend_visit_data ,
"gs_send_facebook_help":_generic_success (),
"gs_collect_invite_reward":_generic_success (),
"gs_join_tribe":_join_tribe_handler ,
"gs_send_tribe_invite":_generic_success (),
"gs_send_tribe_request":_generic_success (),
"gs_cancel_tribe_request":_generic_success (),
"gs_kick_tribe_request":_generic_success (),
"gs_decline_all_tribal_invites":_generic_success (),
"gs_place_on_tribal":_generic_success (),
"gs_save_composer_template":_simple (msm_composer .save_composer_template ),
"gs_delete_composer_template":_simple (msm_composer .delete_composer_template ),
"save_clubbox_customization":_generic_success (),
"gs_double_encore_reward":_generic_success (),
"gs_memory_minigame_current_cost":_simple (msm_rewards .memory_minigame_current_cost ),

"gs_process_event_cleanup":_generic_success (),
"gs_process_unclaimed_codes":_generic_success (),
"gs_box_add_egg":_box_add_handler ("gs_box_add_egg"),
"gs_box_add_monster":_box_add_handler ("gs_box_add_monster"),
"gs_extract_egg_costumes":_simple (msm_monsters .extract_egg_costumes ),
"gs_box_monster":_box_add_handler ("gs_box_monster"),
"gs_zap_egg":_box_add_handler ("gs_box_add_egg"),
"gs_zap_monster":_box_add_handler ("gs_box_add_monster"),
"gs_zap_to_box":_box_add_handler ("gs_box_add_egg"),
"gs_zap_monster_to_box":_box_add_handler ("gs_box_add_monster"),
"gs_box_purchase_fill":_with_monster_update ("gs_box_purchase_fill",msm_box .box_purchase_fill ),
"gs_box_activate_monster":_box_activate_handler ("gs_box_activate_monster",msm_box .box_activate_monster ),
"gs_activate_box_monster":_box_activate_handler ("gs_activate_box_monster",msm_box .wake_wubbox ),
"gs_wake_wubbox":_box_activate_handler ("gs_wake_wubbox",msm_box .wake_wubbox ),
"gs_attempt_early_box_activate":_box_activate_handler ("gs_attempt_early_box_activate",msm_box .attempt_early_box_activate ),
"gs_purchase_evolve_unlock":_box_activate_handler ("gs_purchase_evolve_unlock",msm_box .purchase_evolve_unlock ),
"gs_purchase_evo_powerup_unlock":_box_activate_handler ("gs_purchase_evo_powerup_unlock",msm_box .purchase_evo_powerup_unlock ),
"gs_purchase_flip_mini_game":_simple (msm_rewards .purchase_flip_mini_game ),
"gs_rate_island":_generic_success (),
"gs_refresh_tribe_requests":_generic_success (["requests"]),
"gs_save_composer_track":_simple (msm_composer .save_composer_track ),
"gs_set_last_timed_theme":_simple (msm_islands .set_last_timed_theme ),
"gs_speedup_dish_harmonizing":_with_structure_update ("gs_speedup_dish_harmonizing",msm_structures .speed_up_dish_harmonizing ,always =True ),
"gs_start_dish_harmonizing":_with_structure_update ("gs_start_dish_harmonizing",msm_structures .start_dish_harmonizing ,always =True ),
"gs_start_attuning":_simple (msm_attune .start_attuning ),
"gs_speedup_attuning":_simple (msm_attune .speedup_attuning ),
"gs_finish_attuning":_simple (msm_attune .finish_attuning ),
"gs_update_reattune_monster":_simple (msm_attune .update_reattune_monster ),
"gs_collect_reattune_monster":_simple (msm_attune .collect_reattune_monster ),
"gs_viewed_reattuned_monster":_simple (msm_attune .viewed_reattuned_monster ),
"gs_start_synthesizing":_simple (msm_synthesis .start_synthesizing ),
"gs_speedup_synthesizing":_simple (msm_synthesis .speedup_synthesizing ),
"gs_collect_synthesizing_success":_simple (msm_synthesis .collect_synthesizing_success ),
"gs_collect_synthesizing_failure":_simple (msm_synthesis .collect_synthesizing_failure ),
"gs_collect_synthesizing":_simple (msm_synthesis .collect_synthesizing ),
"gs_finish_synthesizing":_simple (msm_synthesis .finish_synthesizing ),
"gs_tribal_feed_monster":_generic_success (["rewards"]),
"purchase_costume":_costume_action ("purchase_costume"),
"equip_costume":_costume_action ("equip_costume"),
"gs_update_owned_costumes":_simple (msm_monsters .update_owned_costumes ),
"gs_update_properties":_update_properties ,
"gs_update_sold_monsters":_generic_success (),
"gs_update_titansoul_rewards":_generic_success (["rewards"]),
"update_viewed_campaigns":_update_viewed_campaigns ,
"gs_update_viewed_cards":_generic_success (["viewed_cards","card_ids"]),
"gs_open_card_packs":_simple (msm_cardalbum .open_card_packs ),
"gs_buy_card_album_store_item":_simple (msm_cardalbum .buy_card_album_store_item ),
"gs_buy_tile":_simple (msm_structures .buy_tile ),
"gs_save_paintstate":_simple (msm_structures .save_paintstate ),
"update_awakener":_with_structure_update ("update_awakener",msm_structures .update_awakener ),
"gs_collect_card_album_rewards":_simple (msm_cardalbum .collect_card_album_rewards ),
"gs_collect_card_album_page_rewards":_simple (msm_cardalbum .collect_card_album_page_rewards ),
"card_album_reward_collect":_simple (msm_cardalbum .collect_card_album_rewards ),
"card_album_page_reward_collect":_simple (msm_cardalbum .collect_card_album_page_rewards ),
"gs_collect_rewards":_simple (msm_rewardtracks .collect_rewards ),
"gs_multi_neighbors":_generic_success (["neighbors"]),
}
def handle_login (params ):

    resolved =get_active_username ()
    set_client_lang (resolved ,params .get ("client_lang"))
    try :
        root ,player_object =load_player (resolved )
        msm_quests ._quest_meta (player_object )["catalog_sent"]=False
        save_player (resolved ,root )
    except Exception :
        logger .exception ("failed to reset quest catalog_sent on login for %s",resolved )
    mod_api .fire_event ("player_join",username =resolved ,params =params )
    return _append_mod_frames (resolved ,[("USER_LOGIN",{"data":{},"success":True ,"user":resolved })])
_GENERIC_MESSAGES ={
"welcome":{
"en":"Welcome to NPS!",
"de":"Willkommen bei NPS!",
"es":"¡Bienvenido a NPS!",
"fr":"Bienvenue sur NPS !",
"pt":"Bem-vindo ao NPS!",
"ru":"Добро пожаловать в NPS!",
},
"welcome_mail_title":{
"en":"Welcome to Next Private Server v12!",
"de":"Willkommen beim Next Private Server v12!",
"es":"¡Bienvenido a Next Private Server v12!",
"fr":"Bienvenue sur Next Private Server v12 !",
"pt":"Bem-vindo ao Next Private Server v12!",
"ru":"Добро пожаловать на Next Private Server v12!",
},
"unhandled_command":{
"en":"Command {command} is unhandled, please wait while we add support for it, for more info, check our site nextps.lol",
"de":"Der Befehl {command} wird noch nicht unterstützt, bitte warte, während wir die Unterstützung dafür hinzufügen. Weitere Infos auf nextps.lol",
"es":"El comando {command} todavía no está soportado, espera mientras agregamos soporte. Más información en nextps.lol",
"fr":"La commande {command} n'est pas encore prise en charge, merci de patienter pendant que nous ajoutons son support. Plus d'infos sur nextps.lol",
"pt":"O comando {command} ainda não é suportado, aguarde enquanto adicionamos suporte para ele. Mais informações em nextps.lol",
"ru":"Команда {command} пока не поддерживается, подождите, пока мы добавим её поддержку. Подробнее на nextps.lol",
},
"friend_removed":{
"en":"Friend removed.",
"de":"Freund entfernt.",
"es":"Amigo eliminado.",
"fr":"Ami supprimé.",
"pt":"Amigo removido.",
"ru":"Друг удалён.",
},
"friend_remove_failed":{
"en":"Could not remove that friend. Check your connection and try again.",
"de":"Der Freund konnte nicht entfernt werden. Prüfe deine Verbindung und versuche es erneut.",
"es":"No se pudo eliminar a ese amigo. Comprueba tu conexión e inténtalo de nuevo.",
"fr":"Impossible de supprimer cet ami. Vérifie ta connexion et réessaie.",
"pt":"Não foi possível remover esse amigo. Verifique sua conexão e tente de novo.",
"ru":"Не удалось удалить друга. Проверьте соединение и попробуйте снова.",
},
"friend_request_sent":{
"en":"Friend request sent!",
"de":"Freundschaftsanfrage gesendet!",
"es":"¡Solicitud de amistad enviada!",
"fr":"Demande d'ami envoyée !",
"pt":"Pedido de amizade enviado!",
"ru":"Запрос в друзья отправлен!",
},
"friend_already":{
"en":"You are already friends with this player.",
"de":"Ihr seid bereits befreundet.",
"es":"Ya sois amigos.",
"fr":"Vous êtes déjà amis.",
"pt":"Vocês já são amigos.",
"ru":"Вы уже друзья.",
},
"friend_code_unknown":{
"en":"No player has that friend code. Check it and try again.",
"de":"Kein Spieler hat diesen Freundescode. Bitte prüfe ihn und versuche es erneut.",
"es":"Ningún jugador tiene ese código de amigo. Compruébalo e inténtalo de nuevo.",
"fr":"Aucun joueur n'a ce code ami. Vérifie-le et réessaie.",
"pt":"Nenhum jogador tem esse código de amigo. Confira e tente de novo.",
"ru":"Игрока с таким кодом друга нет. Проверьте код и попробуйте снова.",
},
"friend_code_missing":{
"en":"Enter a friend code first.",
"de":"Gib zuerst einen Freundescode ein.",
"es":"Introduce primero un código de amigo.",
"fr":"Saisis d'abord un code ami.",
"pt":"Digite um código de amigo primeiro.",
"ru":"Сначала введите код друга.",
},
"friend_offline":{
"en":"Cannot reach the NPS account server. Sign in from the launcher and try again.",
"de":"Der NPS-Kontoserver ist nicht erreichbar. Melde dich im Launcher an und versuche es erneut.",
"es":"No se puede conectar con el servidor de cuentas de NPS. Inicia sesión en el launcher e inténtalo de nuevo.",
"fr":"Impossible de joindre le serveur de comptes NPS. Connecte-toi depuis le launcher et réessaie.",
"pt":"Não foi possível conectar ao servidor de contas do NPS. Entre pelo launcher e tente de novo.",
"ru":"Сервер аккаунтов NPS недоступен. Войдите через лаунчер и попробуйте снова.",
},
"friend_visit_failed":{
"en":"Could not load this friend's island. They may not have played yet, or the NPS account server can't be reached right now.",
"de":"Die Insel dieses Freundes konnte nicht geladen werden. Er hat vielleicht noch nicht gespielt, oder der NPS-Kontoserver ist gerade nicht erreichbar.",
"es":"No se pudo cargar la isla de este amigo. Puede que aún no haya jugado, o el servidor de cuentas de NPS no está disponible ahora mismo.",
"fr":"Impossible de charger l'île de cet ami. Il n'a peut-être pas encore joué, ou le serveur de comptes NPS est actuellement inaccessible.",
"pt":"Não foi possível carregar a ilha desse amigo. Talvez ele ainda não tenha jogado, ou o servidor de contas do NPS está indisponível agora.",
"ru":"Не удалось загрузить остров этого друга. Возможно, он ещё не играл, либо сервер аккаунтов NPS сейчас недоступен.",
},
"monster_not_required":{
"en":"This monster isn't required here. It wasn't added.",
"de":"Dieses Monster wird hier nicht benötigt. Es wurde nicht hinzugefügt.",
"es":"Este monstruo no es necesario aquí. No fue añadido.",
"fr":"Ce monstre n'est pas requis ici. Il n'a pas été ajouté.",
"pt":"Esse monstro não é necessário aqui. Ele não foi adicionado.",
"ru":"Этот монстр здесь не требуется. Он не был добавлен.",
},
"handler_error":{
"en":"Something went wrong processing {command}. If this keeps happening, check nextps.lol",
"de":"Beim Verarbeiten von {command} ist ein Fehler aufgetreten. Falls das weiter passiert, schau auf nextps.lol vorbei",
"es":"Algo salió mal al procesar {command}. Si esto sigue pasando, revisa nextps.lol",
"fr":"Une erreur s'est produite lors du traitement de {command}. Si cela continue, consulte nextps.lol",
"pt":"Algo deu errado ao processar {command}. Se isso continuar acontecendo, veja nextps.lol",
"ru":"При обработке {command} что-то пошло не так. Если это повторяется, загляните на nextps.lol",
},
"handler_error_reported":{
"en":"Something went wrong processing {command}. A bug report was sent automatically.",
"de":"Beim Verarbeiten von {command} ist ein Fehler aufgetreten. Ein Fehlerbericht wurde automatisch gesendet.",
"es":"Algo salió mal al procesar {command}. Se envió un informe de error automáticamente.",
"fr":"Une erreur s'est produite lors du traitement de {command}. Un rapport de bug a été envoyé automatiquement.",
"pt":"Algo deu errado ao processar {command}. Um relatório de bug foi enviado automaticamente.",
"ru":"При обработке {command} что-то пошло не так. Отчёт об ошибке был отправлен автоматически.",
},
}
def _generic_message (key ,username ,**fmt ):
    table =_GENERIC_MESSAGES .get (key )or {}
    lang =get_client_lang (username )if username else "en"
    text =table .get (lang )or table .get ("en")or key
    try :
        return text .format (**fmt )
    except Exception :
        return text

def login_bootstrap_frames ():
    frames =[]
    game_settings =load_db_json ("game_settings")
    if game_settings is not None :
        frames .append (("game_settings",dict (game_settings )))
    gs_initialized =load_db_json ("gs_initialized")
    if gs_initialized is not None :
        frames .append (("gs_initialized",normalize_db_payload ("gs_initialized",dict (gs_initialized ))))
    frames .append (("gs_display_generic_message",{"force_logout":False ,"msg":_generic_message ("welcome",get_active_username ())}))
    return frames
def handle_command (command ,params ):
    active_username =get_active_username ()
    if command =="alive":
        return _append_mod_frames (active_username ,[])
    if command =="USER_LOGOUT":
        return _handled_frames (active_username ,command ,params ,[(command ,{})])
    logger .info ("handling command %s params=%r",command ,params )
    try :
        mod_api .fire_event ("command_received",username =active_username ,command =command ,params =params )
    except Exception :
        logger .exception ("mod command event failed for %s",command )
    if command =="USER_LOGIN":
        logger .info ("command %s handled by login bootstrap",command )
        frames =handle_login (params )
        return _handled_frames (active_username ,command ,params ,frames )
    aliased_command =_STATIC_ALIAS_RESPONSES .get (command )
    if aliased_command is not None :
        logger .info ("command %s handled by static alias %s",command ,aliased_command )
        data =load_db_json (aliased_command )
        if data is None :
            logger .info ("no captured response for %s (via %s)",command ,aliased_command )
            return _handled_frames (active_username ,command ,params ,[])
        payload =normalize_db_payload (aliased_command ,dict (data ))
        return _handled_frames (active_username ,command ,params ,[(command ,payload )])
    handler =GAMEPLAY_HANDLERS .get (command )
    if handler is not None :
        logger .info ("command %s handled by gameplay handler",command )
        try :
            result =handler (active_username ,params )
        except Exception as exc :
            logger .exception ("handler for %s raised",command )
            return _handled_frames (active_username ,command ,params ,_failure_frame (command ,exc ,active_username ))
        if result is None :
            logger .info ("handler for %s had nothing to answer",command )
            return _handled_frames (active_username ,command ,params ,[])
        if isinstance (result ,list ):
            frames =result
        else :
            frames =[(command ,result )]
        if not command .startswith ("gs_quest"):
            try :
                frames =frames +msm_quests .advance_quests (active_username )
            except Exception :
                logger .exception ("quest progress check failed after %s",command )
        return _handled_frames (active_username ,command ,params ,frames )
    if not command .startswith ("db_")and mod_api .has_action (command ):
        logger .info ("command %s handled by registered java mod action before db capture",command )
        mod_frames =mod_api .dispatch_action (command ,active_username ,params )
        if mod_frames :
            logger .info ("command %s java mod action produced %d frame(s)",command ,len (mod_frames ))
            return _handled_frames (active_username ,command ,params ,mod_frames )
        logger .info ("command %s registered java mod action produced no frames",command )
        return _handled_frames (active_username ,command ,params ,[])
    data =load_db_json (command )
    if data is None :
        logger .info ("command %s has no db capture; checking java mod actions",command )
        mod_frames =mod_api .dispatch_action (command ,active_username ,params )
        if mod_frames :
            logger .info ("command %s handled by java mod action with %d frame(s)",command ,len (mod_frames ))
            return _handled_frames (active_username ,command ,params ,mod_frames )
        logger .info ("UNHANDLED command %s params=%r",command ,params )
        if "card"in command .lower ():
            logger .info ("command %s using card fallback success response",command )
            return _handled_frames (active_username ,command ,params ,[(command ,{"success":True })])

        notice ={
        "force_logout":False ,
        "msg":_generic_message ("unhandled_command",active_username ,command =command ),
        }
        return _handled_frames (active_username ,command ,params ,[("gs_display_generic_message",notice )])
    logger .info ("command %s handled by db capture",command )
    payloads =[dict (data )]
    for i in range (2 ,10 ):
        chained =load_db_json (f"{command }_{i }")
        if chained is None :
            break
        payloads .append (dict (chained ))
    if command .startswith ("db_"):
        for payload in payloads :
            if "numChunks"in payload or len (payloads )>1 :
                payload ["numChunks"]=len (payloads )
    frames =[(command ,normalize_db_payload (command ,payload ))for payload in payloads ]
    return _handled_frames (active_username ,command ,params ,frames )
