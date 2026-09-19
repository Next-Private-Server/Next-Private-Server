import json
import random
import struct
import msm_toggles
import time
import unicodedata
from msm_store import load_db_json
PAIRONORMAL_ISLAND_TYPE =31
AMBER_ISLAND_TYPE =22
def _decode_db_number (value ,default =0 ):
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
    if value is None :
        return default
    return value
_STRUCTURE_DB_NAMES =["db_structures","db_structure","db_structure_2","db_structure_3","db_structure_4",
"db_structure_5","db_structure_6","db_structure_7","db_structure_8","db_structure_9"]
_structure_defs_cache =None
_monster_defs_cache =None
def _structure_array (data ):
    if not data :
        return None
    return data .get ("structures_data")or data .get ("structure_data")
def _build_structure_defs ():
    defs ={}
    for name in _STRUCTURE_DB_NAMES :
        arr =_structure_array (load_db_json (name ))
        if not arr :
            continue
        for entry in arr :
            sid =entry .get ("structure_id")
            if sid is not None and sid not in defs :
                defs [sid ]=entry
    return defs
def get_structure_definition (structure_id ):
    global _structure_defs_cache
    if _structure_defs_cache is None :
        _structure_defs_cache =_build_structure_defs ()
    return _structure_defs_cache .get (structure_id )
_gene_instability_cache =None
def _build_gene_instability ():
    data =load_db_json ("db_attuner_gene")or {}
    entries =data .get ("attuner_gene_data")or []
    result ={}
    for entry in entries :
        gene =(entry .get ("gene")or "").strip ().upper ()
        if gene :
            result [gene ]=entry .get ("instability",3 )or 3
    return result
def get_gene_instability (gene ):
    global _gene_instability_cache
    if _gene_instability_cache is None :
        _gene_instability_cache =_build_gene_instability ()
    return _gene_instability_cache .get ((gene or "").strip ().upper (),3 )
_TUNE_UP_ROTATION_MS =7 *24 *60 *60 *1000
def current_tunable_genes ():
    data =load_db_json ("db_attuner_gene")or {}
    entries =data .get ("attuner_gene_data")or []
    genes =sorted ({(e .get ("gene")or "").strip ().upper ()for e in entries if isinstance (e ,dict )and e .get ("gene")})
    if not genes :
        return [],0 ,0
    now =int (time .time ()*1000 )
    return genes ,now ,_TUNE_UP_ROTATION_MS
def _build_monster_defs ():
    defs ={}
    for data in _load_db_chunk_chain ("db_monster"):
        for entry in data .get ("monsters_data")or []:
            mid =entry .get ("monster_id")
            if mid is not None :
                defs [mid ]=entry
    return defs

def _load_db_chunk_chain (name ):
    data =load_db_json (name )
    if data is not None :
        yield data
    for i in range (2 ,10 ):
        data =load_db_json (f"{name }_{i }")
        if data is None :
            break
        yield data
def get_monster_definition (monster_id ):
    global _monster_defs_cache
    if _monster_defs_cache is None :
        _monster_defs_cache =_build_monster_defs ()
    return _monster_defs_cache .get (monster_id )
_costume_by_monster_cache =None
def get_costume_id_for_monster (monster_id ):
    global _costume_by_monster_cache
    if _costume_by_monster_cache is None :
        _costume_by_monster_cache ={}
        for data in _load_db_chunk_chain ("db_costumes"):
            for entry in data .get ("costume_data")or []:
                mid =entry .get ("monster_id")
                cid =entry .get ("id")
                if mid is not None and cid is not None and mid not in _costume_by_monster_cache :
                    _costume_by_monster_cache [mid ]=cid
    return _costume_by_monster_cache .get (monster_id )
_costume_defs_cache =None
def get_costume_definition (costume_id ):
    global _costume_defs_cache
    if _costume_defs_cache is None :
        _costume_defs_cache ={}
        for data in _load_db_chunk_chain ("db_costumes"):
            for entry in data .get ("costume_data")or []:
                cid =entry .get ("id")
                if cid is not None :
                    _costume_defs_cache [cid ]=entry
    return _costume_defs_cache .get (costume_id )
_monster_entity_id_index_cache =None
def get_monster_id_for_entity_id (entity_id ):

    global _monster_entity_id_index_cache
    if _monster_entity_id_index_cache is None :
        _monster_entity_id_index_cache ={
        entry .get ("entity_id"):mid
        for mid ,entry in _all_monster_defs ().items ()
        if entry .get ("entity_id")is not None
        }
    return _monster_entity_id_index_cache .get (entity_id ,0 )
_monster_genes_index_cache =None
def get_monster_id_for_genes (genes ):
    global _monster_genes_index_cache
    if _monster_genes_index_cache is None :
        _monster_genes_index_cache ={}
        for mid ,entry in _all_monster_defs ().items ():
            entry_genes ="".join (sorted ((entry .get ("genes")or "").strip ().upper ()))
            if entry_genes :
                _monster_genes_index_cache .setdefault (entry_genes ,mid )
    normalized ="".join (sorted ((genes or "").strip ().upper ()))
    return _monster_genes_index_cache .get (normalized ,0 )
def _all_monster_defs ():
    global _monster_defs_cache
    if _monster_defs_cache is None :
        _monster_defs_cache =_build_monster_defs ()
    return _monster_defs_cache

def reset_caches (db_name =None ):
    global _structure_defs_cache ,_monster_defs_cache ,_gene_instability_cache
    global _monster_entity_id_index_cache ,_battle_campaign_defs_cache ,_island_book_cache
    global _monster_genes_index_cache

    global _island_catalog_cache ,_scratch_payload_cache ,_ethereal_islet_defs_cache
    global _breeding_data_cache ,_bakery_defs_cache ,_island_theme_defs_cache
    global _user_game_settings_cache ,_paironormal_starpower_rates_cache
    global _costume_by_monster_cache ,_costume_defs_cache
    name =(db_name or "").removesuffix (".json")
    if not name or name .startswith ("db_monster"):
        _monster_defs_cache =None
        _monster_entity_id_index_cache =None
        _monster_genes_index_cache =None
        _island_book_cache =None
    if not name or name .startswith ("db_costume"):
        _costume_by_monster_cache =None
        _costume_defs_cache =None
    if not name or name .startswith ("db_island"):
        _island_book_cache =None
        _island_catalog_cache =None
        _island_theme_defs_cache =None
    if not name or name .startswith ("db_structure"):
        _structure_defs_cache =None
    if not name or name =="db_attuner_gene":
        _gene_instability_cache =None
    if not name or name .startswith ("db_battle"):
        _battle_campaign_defs_cache =None
    if not name or name .startswith ("db_scratch"):
        _scratch_payload_cache =None
    if not name or name .startswith ("db_ethereal"):
        _ethereal_islet_defs_cache =None
    if not name or name .startswith ("db_breeding"):
        _breeding_data_cache =None
    if not name or name .startswith ("db_bakery"):
        _bakery_defs_cache =None
    if not name or name =="game_settings":
        _user_game_settings_cache =None
        _paironormal_starpower_rates_cache =None

def all_monster_ids ():
    return list (_all_monster_defs ().keys ())
_battle_campaign_defs_cache =None
def _build_battle_campaign_defs ():
    defs ={}
    for data in _load_db_chunk_chain ("db_battle"):
        for entry in data .get ("battle_campaign_data")or []:
            cid =entry .get ("id")
            if cid is not None :
                defs [cid ]=entry
    return defs
def get_battle_campaign_definition (campaign_id ):
    global _battle_campaign_defs_cache
    if _battle_campaign_defs_cache is None :
        _battle_campaign_defs_cache =_build_battle_campaign_defs ()
    return _battle_campaign_defs_cache .get (campaign_id )
def is_nursery_structure (structure_id ):
    definition =get_structure_definition (structure_id )
    return bool (definition )and definition .get ("structure_type")=="nursery"
def is_egg_holder_structure (structure_id ):
    definition =get_structure_definition (structure_id )
    return bool (definition )and definition .get ("structure_type")in ("nursery","dish_harmonizer","synthesizer")
_island_book_cache =None
def _build_island_book ():
    book ={}
    data =load_db_json ("db_island_v2")or {}
    for entry in data .get ("islands_data")or []:
        island_type =entry .get ("island_type")
        if island_type is None :
            continue
        ids =book .setdefault (island_type ,set ())
        for m in entry .get ("monsters")or []:
            monster_id =m .get ("monster")
            if monster_id is not None :
                ids .add (monster_id )
    return book
def _island_book ():
    global _island_book_cache
    if _island_book_cache is None :
        _island_book_cache =_build_island_book ()
    return _island_book_cache
def monster_allowed_on_island (definition ,island_type_id ):
    if not definition or not island_type_id :
        return False
    monster_id =definition .get ("monster_id")
    if monster_id is None :
        return False
    return monster_id in _island_book ().get (island_type_id ,())
def monster_ids_allowed_on_island (island_type_id ):
    return sorted (_island_book ().get (island_type_id ,()))
def resolve_monster_for_island (monster_id ,island_type_id ):
    definition =get_monster_definition (monster_id )
    if not definition or not island_type_id :
        return monster_id
    if monster_allowed_on_island (definition ,island_type_id ):
        return monster_id
    name =definition .get ("name")
    if not name :
        return monster_id
    for candidate_id ,candidate in _all_monster_defs ().items ():
        if candidate .get ("name")==name and monster_allowed_on_island (candidate ,island_type_id ):
            return candidate_id
    return monster_id
def is_paironormal_island (island_type_id ):
    return island_type_id ==PAIRONORMAL_ISLAND_TYPE
def is_paironormal_multimodal (definition ):
    if not definition :
        return False
    name =(definition .get ("name")or "")
    common_name =(definition .get ("common_name")or "")
    class_name =(definition .get ("class")or "")
    combined =f"{name } {common_name } {class_name }".lower ()
    if "titansoul"in combined :
        return False
    graphic =definition .get ("graphic")or {}
    if (graphic .get ("file")or "").lower ()=="placeholder_ghost.bin":
        return True
    return "multimodal"in common_name .lower ()

def _paironormal_sibling_ids (definition ):
    if not definition :
        return None ,None ,None
    extra =definition .get ("extra")or {}
    modes =extra .get ("modes")
    if isinstance (modes ,list )and len (modes )>=2 :
        major_id ,minor_id =int (modes [0 ]),int (modes [1 ])
        return None ,major_id ,minor_id
    major_id =extra .get ("major")
    minor_id =extra .get ("minor")
    monster_id =definition .get ("monster_id")
    if major_id :
        return monster_id ,int (major_id ),None
    if minor_id :
        return monster_id ,None ,int (minor_id )
    return None ,None ,None
def resolve_paironormal_stored_monster_id (monster_id ,island_type_id ):
    if not is_paironormal_island (island_type_id )or not monster_id or monster_id <=0 :
        return monster_id
    definition =get_monster_definition (monster_id )
    if not definition :
        return monster_id
    if is_paironormal_multimodal (definition ):
        return monster_id

    for candidate_id ,candidate in _all_monster_defs ().items ():
        if not is_paironormal_multimodal (candidate ):
            continue
        _ ,cand_major ,cand_minor =_paironormal_sibling_ids (candidate )
        if monster_id in (cand_major ,cand_minor ):
            return candidate_id
    return monster_id
def find_paironormal_form_id (monster_id ,island_type_id ,want_major ):
    if not is_paironormal_island (island_type_id )or not monster_id or monster_id <=0 :
        return monster_id
    stored_id =resolve_paironormal_stored_monster_id (monster_id ,island_type_id )
    definition =get_monster_definition (stored_id )
    if not definition :
        return stored_id
    _ ,major_id ,minor_id =_paironormal_sibling_ids (definition )
    if want_major :
        return major_id or stored_id
    return minor_id or stored_id
def resolve_paironormal_renderable_monster_id (monster_id ,island_type_id ,island_mode ):
    if not is_paironormal_island (island_type_id )or not monster_id or monster_id <=0 :
        return monster_id
    stored_id =resolve_paironormal_stored_monster_id (monster_id ,island_type_id )
    definition =get_monster_definition (stored_id )
    if not definition :
        return stored_id
    want_major =island_mode ==0
    if not is_paironormal_multimodal (definition ):

        self_id ,major_id ,minor_id =_paironormal_sibling_ids (definition )
        if want_major :
            return major_id or stored_id
        return minor_id or stored_id
    form_id =find_paironormal_form_id (stored_id ,island_type_id ,want_major )
    return form_id if form_id and form_id !=stored_id else stored_id
def _paironormal_starpower_owed (level ,last_collection ,now ):

    rate_table =_paironormal_starpower_rates ()
    row =rate_table [0 ]if rate_table else [1.0 ]
    multiplier =row [min (len (row )-1 ,max (0 ,level -1 ))]if row else 1.0
    elapsed_seconds =max (0 ,(now -last_collection )//1000 )if last_collection else 0
    return min (9999.0 ,(elapsed_seconds /60.0 )*float (multiplier ))
def _paironormal_mode_entry (form_id ,mode_value ,is_active ,unique_id ,now ,base_monster =None ):

    base =base_monster or {}
    level =max (1 ,base .get ("level",1 )or 1 )
    last_collection =base .get ("last_collection",now )or now
    if not is_active :
        return {"a":0 }
    entry ={
    "a":1 if is_active else 0 ,
    "level":level ,
    "island":base .get ("island",0 )or 0 ,
    "last_feeding":base .get ("last_feeding",now )or now ,
    "in_hotel":0 ,
    "last_collection":last_collection ,
    "monster":form_id ,
    "pos_y":0 ,
    "volume":1.0 ,
    "pos_x":0 ,
    "times_fed":0 ,
    "happiness":base .get ("happiness",0 )or 0 ,
    "name":"",
    "muted":0 ,
    "flip":0 ,
    "costume":{"eq":0 ,"p":[]},
    "user_monster_id":unique_id ,
    }
    if is_active :
        entry ["collected_starpower"]=_paironormal_starpower_owed (level ,last_collection ,now )
    return entry

def _paironormal_mode_unique_ids (monster ):
    base_id =int (monster .get ("user_monster_id",0 )or 0 )
    existing =monster .get ("paironormal_mode_user_ids")
    if not isinstance (existing ,dict ):
        existing ={}
    major_uid =int (existing .get ("major",0 )or 0 )
    minor_uid =int (existing .get ("minor",0 )or 0 )
    if base_id >0 :
        if major_uid <=0 or major_uid ==base_id :
            major_uid =base_id *10 +1
        if minor_uid <=0 or minor_uid in (base_id ,major_uid ):
            minor_uid =base_id *10 +2
    existing ["major"]=major_uid
    existing ["minor"]=minor_uid
    monster ["paironormal_mode_user_ids"]=existing
    return major_uid ,minor_uid

def build_paironormal_modes (monster ,island_type_id ,island_mode ,player_object =None ):

    source_id =monster .get ("monster",0 )
    stored_id =resolve_paironormal_stored_monster_id (source_id ,island_type_id )
    render_id =resolve_paironormal_renderable_monster_id (stored_id ,island_type_id ,island_mode )
    if stored_id <=0 or render_id <=0 :
        return
    stored_definition =get_monster_definition (stored_id )
    if not stored_definition or not is_paironormal_multimodal (stored_definition ):
        return
    major_id =find_paironormal_form_id (stored_id ,island_type_id ,True )
    minor_id =find_paironormal_form_id (stored_id ,island_type_id ,False )
    now =int (time .time ()*1000 )
    base_uid =int (monster .get ("user_monster_id",0 )or 0 )
    existing_modes =monster .get ("modes")
    if isinstance (existing_modes ,list )and existing_modes :

        has_major =any (isinstance (e ,dict )and e .get ("monster")==major_id for e in existing_modes )
        has_minor =any (isinstance (e ,dict )and e .get ("monster")==minor_id for e in existing_modes )
        placeholder_idx =next (
        (i for i ,e in enumerate (existing_modes )if isinstance (e ,dict )and not e .get ("monster")),
        None ,
        )
        if placeholder_idx is not None :
            missing_id =None
            if has_major and not has_minor and minor_id and minor_id >0 :
                missing_id =minor_id
            elif has_minor and not has_major and major_id and major_id >0 :
                missing_id =major_id
            if missing_id :
                if player_object is not None :
                    new_uid =max (int (player_object .get ("last_user_monster_id",0 )or 0 )+1 ,20000 +random .randint (0 ,899999 ))
                    player_object ["last_user_monster_id"]=new_uid
                else :
                    new_uid =base_uid +2 if base_uid >0 else 0
                if new_uid >0 :
                    new_entry =_paironormal_mode_entry (
                    missing_id ,1 if missing_id ==minor_id else 0 ,True ,new_uid ,now ,monster ,
                    )
                    existing_modes [placeholder_idx ]=new_entry
                    monster ["modes"]=existing_modes
                    return new_entry
        return None

    if render_id <=0 :
        return
    monster ["monster"]=stored_id
    known_id =major_id if render_id ==major_id else minor_id
    if not known_id or known_id <=0 or base_uid <=0 :
        return

    slot0_uid =base_uid +1
    if player_object is not None :
        player_object ["last_user_monster_id"]=max (
        int (player_object .get ("last_user_monster_id",0 )or 0 ),slot0_uid ,
        )
    previous_modes =monster .get ("modes")
    minor_owned =bool (isinstance (previous_modes ,list )and len (previous_modes )>1
    and isinstance (previous_modes [1 ],dict )and previous_modes [1 ].get ("a"))
    major_owned =bool (isinstance (previous_modes ,list )and previous_modes
    and isinstance (previous_modes [0 ],dict )and previous_modes [0 ].get ("a"))
    placing_minor =bool (minor_id and render_id ==minor_id )
    if major_id and major_id >0 and minor_id and minor_id >0 :
        major_entry =_paironormal_mode_entry (major_id ,0 ,major_owned or not placing_minor ,slot0_uid ,now ,monster )
        minor_entry =_paironormal_mode_entry (minor_id ,1 ,minor_owned or placing_minor ,slot0_uid +1 ,now ,monster )
        if player_object is not None :
            player_object ["last_user_monster_id"]=max (
            int (player_object .get ("last_user_monster_id",0 )or 0 ),slot0_uid +1 ,
            )
        monster ["modes"]=[major_entry ,minor_entry ]
        return minor_entry if placing_minor else major_entry
    slot0 =_paironormal_mode_entry (known_id ,0 if known_id ==major_id else 1 ,True ,slot0_uid ,now ,monster )
    monster ["modes"]=[slot0 ,{"a":0 }]
    return slot0
def get_monster_level_definition (monster_id ,level ):
    definition =get_monster_definition (monster_id )
    if not definition or not definition .get ("levels"):
        return None
    fallback =None
    for level_def in definition ["levels"]:
        if level_def is None :
            continue
        fallback =level_def
        if level_def .get ("level")==level :
            return level_def
    return fallback
def get_max_monster_level (monster_id ):
    definition =get_monster_definition (monster_id )
    if not definition or not definition .get ("levels"):
        return 20
    max_level =0
    for level_def in definition ["levels"]:
        if level_def is None :
            continue
        max_level =max (max_level ,level_def .get ("level",0 )or 0 )
    return max_level or 20
_COLLECTION_ALIASES ={"shards":"ethereal_currency","eggwildcards":"egg_wildcards","wildcards":"egg_wildcards"}
def normalize_collection_type (collection_type ):
    normalized =(collection_type or "").strip ().lower ()
    if not normalized :
        return "coins"
    return _COLLECTION_ALIASES .get (normalized ,normalized )
def _infer_monster_collection_type (existing_type ,island_type ,level_def ):
    existing =normalize_collection_type (existing_type )
    if existing not in ("coins","none"):
        return existing
    if island_type ==PAIRONORMAL_ISLAND_TYPE :
        return "starpower"
    if island_type ==25 :
        return "egg_wildcards"
    if island_type in (7 ,24 ,26 ,27 ,28 ,29 ):
        return "ethereal_currency"
    max_coins =max (0 ,(level_def or {}).get ("max_coins",0 )or 0 )
    max_ethereal =max (0 ,(level_def or {}).get ("max_ethereal",0 )or 0 )
    max_relics =max (0 ,_decode_db_number ((level_def or {}).get ("max_relics"),0 )or 0 )
    if island_type ==AMBER_ISLAND_TYPE or (max_coins <=0 and max_ethereal <=0 and max_relics >0 ):
        return "relics"
    if max_coins <=0 and max_ethereal >0 :
        return "ethereal_currency"
    return "coins"
def compute_monster_economy (monster ,island_type ):
    monster_id =monster .get ("monster",0 )
    if not monster_id :
        return "coins",225 ,5
    level =max (1 ,monster .get ("level",1 )or 1 )
    level_def =get_monster_level_definition (monster_id ,level )
    max_coins ,income_rate ,max_ethereal ,ethereal_rate =225 ,5 ,0 ,0
    max_relics ,relics_rate =0 ,0
    if level_def :
        max_coins =max (0 ,level_def .get ("max_coins",max_coins )or max_coins )
        income_rate =max (0 ,level_def .get ("coins",income_rate )or income_rate )
        max_ethereal =max (0 ,level_def .get ("max_ethereal",0 )or 0 )
        ethereal_rate =max (0 ,level_def .get ("ethereal_currency",0 )or 0 )
        max_relics =max (0 ,_decode_db_number (level_def .get ("max_relics"),0 )or 0 )
        relics_rate =max (0 ,_decode_db_number (level_def .get ("relics"),0 )or 0 )
    collection_type =_infer_monster_collection_type ("",island_type ,level_def )
    if collection_type =="relics":
        return "relics",max (1 ,int (round (max_relics ))),max (1 ,int (round (relics_rate )))
    if collection_type =="ethereal_currency":
        return "ethereal_currency",max (1 ,max_ethereal ),max (1 ,ethereal_rate )
    if collection_type =="starpower":
        rate_table =_paironormal_starpower_rates ()
        row =rate_table [0 ]if rate_table else [1.0 ]
        multiplier =row [min (len (row )-1 ,max (0 ,level -1 ))]
        starpower_rate =max (1 ,int (round (multiplier )))
        return "starpower",max (1 ,max_coins ),starpower_rate
    return collection_type ,max (1 ,max_coins ),max (1 ,income_rate )
_user_game_settings_cache =None
def _user_game_settings ():
    global _user_game_settings_cache
    if _user_game_settings_cache is None :
        settings ={}
        data =load_db_json ("game_settings")or {}
        for entry in data .get ("user_game_settings")or []:
            key =entry .get ("key")
            if key :
                settings [key ]=entry .get ("value")
        _user_game_settings_cache =settings
    return _user_game_settings_cache
def get_user_game_setting_float (key ,default =0.0 ):
    try :
        return float (_user_game_settings ().get (key ,default ))
    except (TypeError ,ValueError ):
        return default
def get_user_game_setting_int (key ,default =0 ):
    try :
        return int (float (_user_game_settings ().get (key ,default )))
    except (TypeError ,ValueError ):
        return default
_paironormal_starpower_rates_cache =None
def _paironormal_starpower_rates ():
    global _paironormal_starpower_rates_cache
    if _paironormal_starpower_rates_cache is None :
        rates =[]
        data =load_db_json ("game_settings")or {}
        for entry in data .get ("user_game_settings")or []:
            if entry .get ("key")=="USER_PAIRONORMAL_STARPOWER_RATES":
                try :
                    rates =json .loads (entry .get ("value")or "[]")
                except (ValueError ,TypeError ):
                    rates =[]
                break
        _paironormal_starpower_rates_cache =rates
    return _paironormal_starpower_rates_cache
_soul_link_coin_costs_cache =None
def soul_link_coin_costs ():
    global _soul_link_coin_costs_cache
    if _soul_link_coin_costs_cache is None :
        costs =[]
        data =load_db_json ("game_settings")or {}
        for entry in data .get ("user_game_settings")or []:
            if entry .get ("key")=="USER_SOUL_LINK_COIN_COSTS":
                try :
                    costs =json .loads (entry .get ("value")or "[]")
                except (ValueError ,TypeError ):
                    costs =[]
                break
        _soul_link_coin_costs_cache =costs
    return _soul_link_coin_costs_cache
def _parse_allowed_islands (raw ):
    if not raw :
        return set ()
    try :
        return set (int (x )for x in raw .strip ("[] ").split (",")if x .strip ()!="")
    except ValueError :
        return set ()
def _all_structure_defs ():
    global _structure_defs_cache
    if _structure_defs_cache is None :
        _structure_defs_cache =_build_structure_defs ()
    return _structure_defs_cache
_bakery_defs_cache =None
def _build_bakery_defs ():
    data =load_db_json ("db_bakery_foods")
    defs ={}
    if data and data .get ("bakery_data"):
        for entry in data ["bakery_data"]:
            fid =entry .get ("id")
            if fid is not None :
                defs [fid ]=entry
    return defs
def get_bakery_food (food_id ):
    global _bakery_defs_cache
    if _bakery_defs_cache is None :
        _bakery_defs_cache =_build_bakery_defs ()
    return _bakery_defs_cache .get (food_id )
_island_theme_defs_cache =None
def _island_theme_defs ():
    global _island_theme_defs_cache
    if _island_theme_defs_cache is None :
        data =load_db_json ("db_island_themes")or {}
        _island_theme_defs_cache =data .get ("island_theme_data")or []
    return _island_theme_defs_cache
_island_catalog_cache =None
def _island_catalog ():
    global _island_catalog_cache
    if _island_catalog_cache is None :
        data =load_db_json ("db_island_v2")or {}
        catalog ={}
        for entry in data .get ("islands_data")or []:
            island_id =entry .get ("island_id")
            if island_id is not None :
                catalog [island_id ]=entry
        _island_catalog_cache =catalog
    return _island_catalog_cache
def resolve_island_type (island_id ):
    entry =_island_catalog ().get (island_id )
    if entry and entry .get ("island_type")is not None :
        return entry ["island_type"]
    return island_id
def get_island_definition (island_id ):
    return _island_catalog ().get (island_id )
def island_for_theme (theme_id ):
    for theme in _island_theme_defs ():
        if theme .get ("theme_id")==theme_id :
            return theme .get ("island",0 )
    return 0
_scratch_payload_cache =None
def _scratch_payload ():
    global _scratch_payload_cache
    if _scratch_payload_cache is None :
        data =load_db_json ("db_scratch_offs")or {}
        _scratch_payload_cache =data .get ("payload")or data
    return _scratch_payload_cache
def get_scratch_prizes (type_code ):
    prizes =_scratch_payload ().get ("scratch_offs")or []
    return [p for p in prizes if p .get ("type")==type_code ]
def get_spin_wheel_prizes ():
    return _scratch_payload ().get ("spin_wheel_prizes")or []
_ethereal_islet_defs_cache =None
def get_ethereal_islet_definition (island_id ):
    global _ethereal_islet_defs_cache
    if _ethereal_islet_defs_cache is None :
        defs ={}
        data =load_db_json ("db_ethereal_islet")or {}
        for entry in data .get ("ethereal_islet_data")or []:
            iid =entry .get ("island_id")
            if iid is not None :
                defs [iid ]=entry
        _ethereal_islet_defs_cache =defs
    return _ethereal_islet_defs_cache .get (island_id )
_breeding_data_cache =None
def _breeding_data ():
    global _breeding_data_cache
    if _breeding_data_cache is None :
        rows =[]
        for data in _load_db_chunk_chain ("db_breeding"):
            rows .extend (data .get ("breeding_data")or [])
        _breeding_data_cache =rows
    return _breeding_data_cache
def _breeding_boost_multiplier ():
    try :
        now =int (__import__ ("time").time ()*1000 )
        data =load_db_json ("gs_timed_events")or {}
        boost =0
        for event in data .get ("timed_event_list")or []:
            etype =str (event .get ("event_type","")).lower ()
            start =int (event .get ("start_date",0 )or 0 )
            end =int (event .get ("end_date",0 )or 0 )
            if not (start <=now <=end ):
                continue
            if etype =="breedingchanceboost":
                entries =event .get ("data")or []
                first =entries [0 ]if entries else {}
                boost =max (boost ,max (0 ,int (first .get ("multiplier",0 )or 0 )))
            elif etype in ("breedingpromo","breedingpromotion"):
                boost =max (boost ,100 )
    except Exception :
        pass
    return boost

_breedable_rares_cache =None
_epics_cache =None

def _breedable_rare_for_common (common_id ):
    global _breedable_rares_cache
    if _breedable_rares_cache is None :
        data =load_db_json ("gs_rare_monster_data")or {}
        _breedable_rares_cache ={
        entry .get ("common_id"):entry .get ("rare_id")
        for entry in (data .get ("rare_monster_data")or [])
        if entry .get ("can_rarify")and entry .get ("common_id")and entry .get ("rare_id")
        }
    return _breedable_rares_cache .get (common_id )

def _epic_for_common (common_id ):
    global _epics_cache
    if _epics_cache is None :
        data =load_db_json ("gs_epic_monster_data")or {}
        _epics_cache ={
        entry .get ("common_id"):entry .get ("epic_id")
        for entry in (data .get ("epic_monster_data")or [])
        if entry .get ("common_id")and entry .get ("epic_id")
        }
    return _epics_cache .get (common_id )

_common_for_rare_cache =None
def common_id_for_rare (rare_id ):
    global _common_for_rare_cache
    if _common_for_rare_cache is None :
        data =load_db_json ("gs_rare_monster_data")or {}
        _common_for_rare_cache ={
        entry .get ("rare_id"):entry .get ("common_id")
        for entry in (data .get ("rare_monster_data")or [])
        if entry .get ("can_rarify")and entry .get ("common_id")and entry .get ("rare_id")
        }
    return _common_for_rare_cache .get (rare_id )

def rare_id_for_common (common_id ):
    return _breedable_rare_for_common (common_id )

def epic_id_for_common (common_id ):
    return _epic_for_common (common_id )

def _apply_breeding_luck (result_id ):
    if not msm_toggles .is_enabled ("breeding_luck"):
        return result_id
    normal =msm_toggles .get_int ("breeding_rate_normal",100 ,minimum =0 ,maximum =100 )
    rare =msm_toggles .get_int ("breeding_rate_rare",0 ,minimum =0 ,maximum =100 )
    epic =msm_toggles .get_int ("breeding_rate_epic",0 ,minimum =0 ,maximum =100 )
    rare_id =_breedable_rare_for_common (result_id )
    epic_id =_epic_for_common (result_id )
    if rare_id and get_monster_definition (rare_id )is None :
        rare_id =None
    if epic_id and get_monster_definition (epic_id )is None :
        epic_id =None
    choices =[(result_id ,normal )]
    if rare_id :
        choices .append ((rare_id ,rare ))
    if epic_id :
        choices .append ((epic_id ,epic ))
    total =sum (weight for _mid ,weight in choices )
    if total <=0 :
        return result_id
    roll =random .randrange (total )
    for monster_id ,weight in choices :
        if roll <weight :
            return monster_id
        roll -=weight
    return result_id

def _breeding_result_candidates (monster_a ,monster_b ):
    rows =[]
    boost =_breeding_boost_multiplier ()
    boost_factor =1 +(boost /100.0 )*24
    for row in _breeding_data ():
        a ,b =row .get ("a",0 ),row .get ("b",0 )
        if not ((a ==monster_a and b ==monster_b )or (a ==monster_b and b ==monster_a )):
            continue
        result_id =row .get ("c",0 )
        if not result_id or result_id <=0 :
            continue
        if get_monster_definition (result_id )is None :
            continue
        weight =max (1 ,row .get ("d",1 )or 1 )
        if boost >0 and result_id not in (monster_a ,monster_b ):
            weight =max (1 ,round (weight *boost_factor ))
        rows .append ((result_id ,weight ))
    return rows

def _choose_weighted (weighted ):
    total =sum (max (0 ,weight )for _monster_id ,weight in weighted )
    if total <=0 :
        return None
    roll =random .random ()*total
    for monster_id ,weight in weighted :
        weight =max (0 ,weight )
        if roll <weight :
            return monster_id
        roll -=weight
    return weighted [-1 ][0 ]if weighted else None

def choose_breeding_result_monster (monster_a ,monster_b ,island_type =None ):
    if not monster_a or not monster_b :
        return monster_a or monster_b or 3
    base_candidates =_breeding_result_candidates (monster_a ,monster_b )
    if not base_candidates :
        return monster_a
    fallback =_choose_weighted (base_candidates )
    return _apply_breeding_luck (fallback or monster_a )
def get_max_structure_id (island_type ,structure_type ):
    defs =_all_structure_defs ()
    candidates =[
    entry for entry in defs .values ()
    if entry .get ("structure_type")==structure_type
    and island_type in _parse_allowed_islands (entry .get ("allowed_on_island"))
    ]
    if not candidates :
        return None
    candidate_ids ={entry ["structure_id"]for entry in candidates }
    upgrade_targets ={entry .get ("upgrades_to")for entry in candidates if entry .get ("upgrades_to")}
    roots =[entry for entry in candidates if entry ["structure_id"]not in upgrade_targets ]
    current =roots [0 ]if roots else candidates [0 ]
    seen ={current ["structure_id"]}
    while current .get ("upgrades_to"):
        next_def =get_structure_definition (current ["upgrades_to"])
        if not next_def or next_def ["structure_id"]in seen :
            break
        current =next_def
        seen .add (current ["structure_id"])
    return current ["structure_id"]
