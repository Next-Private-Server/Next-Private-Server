import struct

from msm_gamedata import get_structure_definition
from msm_protocol import SFSFloat ,SFSLong
from msm_store import load_db_json ,load_user_data ,save_user_data

_level_thresholds_cache = None

def _level_thresholds():

    global _level_thresholds_cache
    if _level_thresholds_cache is None:
        data = load_db_json("db_level") or {}
        rows = []
        for entry in data.get("level_data") or []:
            if not isinstance(entry, dict):
                continue
            level = entry.get("level")
            xp = entry.get("xp")
            if isinstance(level, int) and isinstance(xp, (int, float)):
                rows.append((int(xp), level))
        rows.sort(key=lambda pair: pair[0])
        _level_thresholds_cache = rows or [(0, 1)]
    return _level_thresholds_cache

def level_for_xp(xp):
    thresholds = _level_thresholds()
    level = thresholds[0][1]
    for threshold_xp, threshold_level in thresholds:
        if xp >= threshold_xp:
            level = threshold_level
        else:
            break
    return level

def recalculate_level(player_object):
    xp = player_object.get("xp", 0) or 0
    try:
        xp = int(xp)
    except (TypeError, ValueError):
        xp = 0
    computed = level_for_xp(xp)
    current = player_object.get("level", 0) or 0

    if computed != current:
        player_object["level"] = computed

_WIRE_LONG_KEYS ={
"user_structure_id","user_island_id","user_monster_id","user_egg_id","user_breeding_id",
"user_baking_id","user_box_monster_id","underlingUid","underling_id","user_underling_id",
"selectedUnderlingUid","parent_monster","parent_user_monster_id","parent_island",
"parent_user_island_id","active_island","last_user_monster_id","last_user_egg_id",
"last_user_island_id","last_collection","last_collected","last_fed","date_created",
"building_completed","obj_end","finishing_time","complete_on","seconds_remaining",
"time_remaining","started_at","finished_at","user","chief","last_login","hatches_on","laid_on",
}
_WIRE_FLOAT_KEYS ={"scale","volume","warp_speed"}

def _decode_wire_bits (value ):

    if not isinstance (value ,dict )or len (value )!=1 :
        return None
    hex_bits =value .get ("__double_bits")
    if hex_bits is not None :
        try :
            return float (struct .unpack (">d",bytes .fromhex (str (hex_bits ).removeprefix ("0x")))[0 ])
        except (ValueError ,TypeError ,struct .error ):
            return 0.0
    hex_bits =value .get ("__float_bits")
    if hex_bits is not None :
        try :
            return SFSFloat (struct .unpack (">f",bytes .fromhex (str (hex_bits ).removeprefix ("0x"))[-4 :])[0 ])
        except (ValueError ,TypeError ,struct .error ):
            return SFSFloat (0.0 )
    return None

def _is_crucible_dict (value ):
    structure_id =value .get ("structure",value .get ("structure_id"))
    if not structure_id :
        return False
    definition =get_structure_definition (structure_id )or {}
    return (definition .get ("structure_type")or "").lower ()=="crucible"

def coerce_wire_types (value ):
    if isinstance (value ,dict ):
        decoded =_decode_wire_bits (value )
        if decoded is not None :
            return decoded

        crucible =_is_crucible_dict (value )
        coerced ={}
        for key ,sub in value .items ():
            if isinstance (sub ,dict )or isinstance (sub ,list ):
                coerced [key ]=coerce_wire_types (sub )
            elif key in _WIRE_LONG_KEYS and isinstance (sub ,int )and not isinstance (sub ,bool ):
                coerced [key ]=SFSLong (sub )
            elif key =="scale"and crucible and isinstance (sub ,(int ,float ))and not isinstance (sub ,bool ):
                coerced [key ]=float (sub )
            elif key in _WIRE_FLOAT_KEYS and isinstance (sub ,(int ,float ))and not isinstance (sub ,bool ):
                coerced [key ]=float (sub )
            else :
                coerced [key ]=sub
        return coerced
    if isinstance (value ,list ):
        if type (value )is not list :
            return value
        return [coerce_wire_types (item )for item in value ]
    return value

PROPERTY_ALIASES =[
("coins","coins_actual"),("diamonds","diamonds_actual"),("food","food_actual"),
("ethereal_currency","ethereal_currency_actual"),("keys","keys_actual"),
("relics","relics_actual"),("egg_wildcards","egg_wildcards_actual"),
("clubbox_tokens","clubbox_tokens_actual"),("minigame_tokens","minigame_tokens_actual"),
("starpower","starpower_actual"),("sticker_stars","sticker_stars_actual"),
]

def diamond_speedup_cost (remaining_ms ):

    if remaining_ms <=0 :
        return 1
    import math
    return max (1 ,math .ceil (remaining_ms /3600000 ))

def _clamp_i32 (value ):
    try :
        number =int (value )
    except (TypeError ,ValueError ,OverflowError ):
        number =0
    return max (-2147483648 ,min (2147483647 ,number ))

def _currency_value (value ):

    try :
        return int (value )
    except (TypeError ,ValueError ,OverflowError ):
        return 0

def load_player (username ):
    root =load_user_data (username )
    return root ,root .get ("player_object")or {}

def save_player (username ,root ):
    save_user_data (username ,root )

def set_client_lang (username ,lang ):
    lang =str (lang or "").strip ()
    if not lang or not username :
        return
    try :
        root =load_user_data (username )
    except FileNotFoundError :
        return
    if root .get ("client_lang")==lang :
        return
    root ["client_lang"]=lang
    save_user_data (username ,root )

def get_client_lang (username ):
    try :
        root =load_user_data (username )
    except FileNotFoundError :
        return "en"
    lang =str (root .get ("client_lang")or "").strip ().lower ()
    return lang [:2 ]if lang else "en"

def get_active_island_id (player_object ):
    return player_object .get ("active_island",0 )

def find_island (player_object ,island_id ):
    for island in player_object .get ("islands")or []:
        if island is not None and island .get ("user_island_id")==island_id :
            return island
    return None

def island_type_of (island ):
    if not island :
        return 0
    return island .get ("island_type",island .get ("type",island .get ("island",0 )))or 0

def find_structure (island ,structure_id ):
    if island is None :
        return None
    for structure in island .get ("structures")or []:
        if structure is not None and structure .get ("user_structure_id")==structure_id :
            return structure
    return None

def find_monster (island ,monster_id ):
    if island is None :
        return None
    for monster in island .get ("monsters")or []:
        if monster is not None and monster .get ("user_monster_id")==monster_id :
            return monster
    return None

def find_island_by_structure (player_object ,structure_id ):
    for island in player_object .get ("islands")or []:
        structure =find_structure (island ,structure_id )
        if structure is not None :
            return island ,structure
    return None ,None

def find_monster_with_island (player_object ,monster_id ,preferred_island =None ):
    if preferred_island is not None :
        monster =find_monster (preferred_island ,monster_id )
        if monster is not None :
            return preferred_island ,monster
    for island in player_object .get ("islands")or []:
        monster =find_monster (island ,monster_id )
        if monster is not None :
            return island ,monster
    return None ,None

_DAILY_RESET_HOUR_UTC =15

def next_daily_reset_timestamp (now_ms =None ):
    import time as _time
    now_ms =now_ms if now_ms is not None else int (_time .time ()*1000 )
    day_ms =86400000
    today_start =(now_ms //day_ms )*day_ms
    reset =today_start +_DAILY_RESET_HOUR_UTC *3600000
    if reset <=now_ms :
        reset +=day_ms
    return reset

def create_player_properties (player_object ):
    recalculate_level (player_object )
    properties =[]
    for source_key ,actual_key in PROPERTY_ALIASES :
        value =_currency_value (player_object .get (source_key ,player_object .get (actual_key ,0 ))or 0 )
        player_object [actual_key ]=value
        properties .append ({actual_key :value })
    properties .append ({"xp":_currency_value (player_object .get ("xp",0 )or 0 )})
    properties .append ({"level":_clamp_i32 (player_object .get ("level",0 )or 0 )})
    properties .append ({"daily_bonus_type":player_object .get ("daily_bonus_type")or "none"})
    properties .append ({"daily_bonus_amount":_clamp_i32 (player_object .get ("daily_bonus_amount",0 )or 0 )})

    properties .append ({"reward_day":_clamp_i32 (player_object .get ("reward_day",0 )or 0 )})
    properties .append ({"has_free_ad_scratch":bool (player_object .get ("has_free_ad_scratch",False ))})
    properties .append ({"daily_relic_purchase_count":_clamp_i32 (player_object .get ("daily_relic_purchase_count",0 )or 0 )})
    properties .append ({"relic_diamond_cost":_clamp_i32 (player_object .get ("relic_diamond_cost",1 )or 1 )})
    properties .append ({"next_relic_reset":SFSLong (next_daily_reset_timestamp ())})
    premium =player_object .get ("premium",0 )or 0
    try :
        import msm_toggles
        premium =1 if msm_toggles .is_enabled ("premium_account")else 0
    except Exception :
        pass
    properties .append ({"premium":_clamp_i32 (premium )})
    properties .append ({"earned_starpower":_currency_value (player_object .get ("total_starpower_collected",0 )or 0 )})
    properties .append ({"speed_up_credit":_currency_value (player_object .get ("speed_up_credit",0 )or 0 )})
    properties .append ({"battle_xp":_currency_value (player_object .get ("battle_xp",0 )or 0 )})
    properties .append ({"battle_level":_clamp_i32 (player_object .get ("battle_level",0 )or 0 )})
    properties .append ({"medals":_currency_value (player_object .get ("medals",0 )or 0 )})
    if isinstance (player_object .get ("currency_level_scale"),dict ):
        properties .append ({"currency_level_scale":player_object .get ("currency_level_scale")})

    if "encore_points"in player_object :
        properties .append ({"encore_points":SFSFloat (player_object .get ("encore_points",0.0 )or 0.0 )})
    if "encore_level"in player_object :
        properties .append ({"encore_level":_clamp_i32 (player_object .get ("encore_level",1 )or 1 )})
    if "encore_tutorial"in player_object :
        properties .append ({"encore_tutorial":bool (player_object .get ("encore_tutorial",False ))})
    return properties

def inventory_items (player_object ):
    inventory =player_object .get ("items")
    if isinstance (inventory ,dict ):
        items =inventory .get ("items")
    elif isinstance (inventory ,list ):
        items =inventory
    else :
        legacy =player_object .get ("inventory")
        if isinstance (legacy ,dict ):
            items =legacy .get ("items")
        elif isinstance (legacy ,list ):
            items =legacy
        else :
            items =[]
        inventory ={"items":items if isinstance (items ,list )else []}
        player_object ["items"]=inventory
    if not isinstance (items ,list ):
        items =[]
        if isinstance (inventory ,dict ):
            inventory ["items"]=items
        else :
            player_object ["items"]={"items":items}
    return items

def inventory_amount (player_object ,entity_id ):
    entity_id =int (entity_id or 0 )
    for item in inventory_items (player_object ):
        if isinstance (item ,dict )and int (item .get ("k",0 )or 0 )==entity_id :
            return int (item .get ("v",0 )or 0 )
    return 0

def grant_inventory_item (player_object ,entity_id ,amount =1 ):
    entity_id =int (entity_id or 0 )
    amount =int (amount or 0 )
    if entity_id <=0 or amount <=0 :
        return False
    items =inventory_items (player_object )
    for item in items :
        if isinstance (item ,dict )and int (item .get ("k",0 )or 0 )==entity_id :
            item ["v"]=int (item .get ("v",0 )or 0 )+amount
            return True
    items .append ({"v":amount ,"k":entity_id })
    return True

def consume_inventory_item (player_object ,entity_id ,amount =1 ):
    entity_id =int (entity_id or 0 )
    amount =int (amount or 0 )
    if entity_id <=0 or amount <=0 :
        return False
    items =inventory_items (player_object )
    for item in list (items ):
        if not isinstance (item ,dict )or int (item .get ("k",0 )or 0 )!=entity_id :
            continue
        current =int (item .get ("v",0 )or 0 )
        if current <amount :
            return False
        remaining =current -amount
        if remaining >0 :
            item ["v"]=remaining
        else :
            items .remove (item )
        return True
    return False

def append_inventory_property (properties ,player_object ):
    properties .append ({"items":inventory_items (player_object )})
    return properties

def add_actual_currencies (result ,player_object ):
    for source_key ,actual_key in PROPERTY_ALIASES :
        value =_currency_value (player_object .get (source_key ,player_object .get (actual_key ,0 ))or 0 )
        player_object [actual_key ]=value
        result [actual_key ]=value

def action_result (success ,id_key ,id_value ,with_properties =False ):
    result ={"success":bool (success ),id_key :SFSLong (id_value )}
    if with_properties :
        result ["properties"]=[]
    return result
