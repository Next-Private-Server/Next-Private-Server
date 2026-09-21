import logging
import msm_toggles
from msm_gamedata import (
get_monster_definition ,get_monster_id_for_entity_id ,get_user_game_setting_int ,monster_ids_allowed_on_island ,
)
from msm_playerdata import (
SFSLong ,add_actual_currencies ,create_player_properties ,find_island ,
find_island_by_structure ,find_monster_with_island ,get_active_island_id ,island_type_of ,load_player ,save_player ,
)
from msm_protocol import SFSFloat
from msm_store import load_db_json

logger =logging .getLogger ("msm.box")

SPECIAL_BOX_PLACEMENT_ISLANDS =(10 ,12 ,22 )
GOLD_ISLAND_TYPE =6

def is_box_monster_entity (definition ):
    return bool (definition )and (definition .get ("entity_type")or "").lower ()=="box_monster"

def is_special_box_placement_island (island_type ):
    return island_type in SPECIAL_BOX_PLACEMENT_ISLANDS 

def is_direct_box_placement_id (requested_id ,island_type ):
    if requested_id <=0 or not is_special_box_placement_island (island_type ):
        return False 
    return is_box_monster_entity (get_monster_definition (requested_id ))

_DIRECT_PLACEMENT_CLASSES =("CLASS_DIPSTER",)
def requires_direct_placement (definition ,island_type ):
    if island_type in (10 ,11 ,12 ,22 ):
        return True 
    if definition and definition .get ("class")in _DIRECT_PLACEMENT_CLASSES :
        return True 

    return False 

def is_amber_no_vessel_island (island_type ):
    return island_type ==22 

def _ints_from_raw (raw ):
    if isinstance (raw ,list ):
        return [int (v )for v in raw if isinstance (v ,(int ,float ))]
    if isinstance (raw ,str ):
        return [int (tok )for tok in raw .strip ("[] ").split (",")if tok .strip ().lstrip ("-").isdigit ()]
    return []

def _is_rare_monster_definition (definition ):
    if not definition :
        return False
    class_name =(definition .get ("class")or "").upper ()
    common_name =(definition .get ("common_name")or "").lower ()
    name =(definition .get ("name")or "").lower ()
    return "CLASS_RARE" in class_name or common_name .startswith ("rare ")or name .endswith ("_rare")

def _gold_island_box_requirements (definition ,island_type ):
    if island_type !=GOLD_ISLAND_TYPE or not is_box_monster_entity (definition ):
        return []
    monster_id =definition .get ("monster_id",0 )or 0
    if monster_id !=82 and _ints_from_raw (definition .get ("box_monster_requirements")):
        return []
    want_rare =monster_id ==82 or _is_rare_monster_definition (definition )
    requirements =[]
    for candidate_id in monster_ids_allowed_on_island (GOLD_ISLAND_TYPE ):
        candidate =get_monster_definition (candidate_id )
        if not candidate or is_box_monster_entity (candidate ):
            continue
        class_name =(candidate .get ("class")or "").upper ()
        if want_rare :
            if "CLASS_RARE_NATURAL" in class_name :
                requirements .append (candidate_id )
        elif class_name =="CLASS_NATURAL":
            requirements .append (candidate_id )
    return sorted (requirements )

def box_requirements (definition ,island_type =0 ):
    if not definition :
        return []
    values =_gold_island_box_requirements (definition ,island_type )
    if values :
        return values
    values =_ints_from_raw (definition .get ("box_monster_requirements"))
    if values :
        return values 

    return _ints_from_raw (definition .get ("evolve_requirements"))

def _ints_to_json_array (values ):
    return "["+",".join (str (v )for v in values )+"]"

def boxed_eggs (monster ):
    raw =monster .get ("boxed_eggs")
    if isinstance (raw ,list ):
        return [int (v )for v in raw if isinstance (v ,(int ,float ))]
    if isinstance (raw ,str ):
        return [int (tok )for tok in raw .strip ("[] ").split (",")if tok .strip ().lstrip ("-").isdigit ()]
    return []

def evolve_boxed_eggs (monster ):
    raw =monster .get ("evolve_boxed_eggs")
    if isinstance (raw ,list ):
        return [int (v )for v in raw if isinstance (v ,(int ,float ))]
    if isinstance (raw ,str ):
        return [int (tok )for tok in raw .strip ("[] ").split (",")if tok .strip ().lstrip ("-").isdigit ()]
    return []

def evolve_flex_boxed_eggs (monster ):
    raw =monster .get ("evolve_flex_boxed_eggs")
    if isinstance (raw ,list ):
        return [int (v )for v in raw if isinstance (v ,(int ,float ))]
    if isinstance (raw ,str ):
        return [int (tok )for tok in raw .strip ("[] ").split (",")if tok .strip ().lstrip ("-").isdigit ()]
    return []

def evolve_exact_boxed_eggs (monster ):
    values =evolve_boxed_eggs (monster )
    for flexegg_id in evolve_flex_boxed_eggs (monster ):
        if flexegg_id in values :
            values .remove (flexegg_id )
    return values

def round2_wire_progress (monster ):
    exact_progress =evolve_exact_boxed_eggs (monster )
    flex_progress =evolve_flex_boxed_eggs (monster )
    if not flex_progress :
        exact_requirements =evolve_exact_requirements (monster )
        flex_requirements =evolve_flex_requirements (monster )
        derived_flex =[]
        remaining =exact_progress [:]
        for flexegg_id in flex_requirements :
            if flexegg_id in remaining and _count (remaining ,flexegg_id )>_count (exact_requirements ,flexegg_id ):
                remaining .remove (flexegg_id )
                derived_flex .append (flexegg_id )
        exact_progress =remaining
        flex_progress =derived_flex
    return {
    "has_evolve_reqs":_ints_to_json_array (exact_progress ),
    "has_evolve_flexeggs":_ints_to_json_array (flex_progress ),
    "evolve_boxed_eggs":monster .get ("evolve_boxed_eggs")or "[]",
    }

def apply_round2_wire_progress_for_sync (player_object ):
    for island in player_object .get ("islands")or []:
        for monster in island .get ("monsters")or []:
            if monster is not None and monster .get ("ascend_pending"):
                monster .update (round2_wire_progress (monster ))

def evolve_requirements_combined (monster ):
    return (_ints_from_raw (monster .get ("has_evolve_reqs"))
    +_ints_from_raw (monster .get ("has_evolve_flexeggs")))

def evolve_exact_requirements (monster ):
    return _ints_from_raw (monster .get ("has_evolve_reqs"))

def evolve_flex_requirements (monster ):
    return _ints_from_raw (monster .get ("has_evolve_flexeggs"))

def _count (values ,wanted ):
    return sum (1 for v in values if v ==wanted )

def _flexegg_definition (flexegg_id ):
    try :
        data =load_db_json ("db_flexeggdefs")or {}
    except Exception :
        return None
    for row in data .get ("flex_egg_def_data")or []:
        if isinstance (row ,dict )and row .get ("id")==flexegg_id :
            return row .get ("def")or {}
    return None

def _monster_rarity (definition ):
    if not definition :
        return "common"
    class_name =(definition .get ("class")or "").upper ()
    common_name =(definition .get ("common_name")or "").lower ()
    if "CLASS_EPIC" in class_name or common_name .startswith ("epic "):
        return "epic"
    if "CLASS_RARE" in class_name or common_name .startswith ("rare "):
        return "rare"
    return "common"

def _monster_genes (definition ):
    genes =definition .get ("genes")if definition else ""
    if isinstance (genes ,str ):
        return [ch .upper ()for ch in genes if ch .strip ()]
    if isinstance (genes ,list ):
        return [str (ch ).upper ()for ch in genes if str (ch ).strip ()]
    return []

def _gene_list (value ):
    if isinstance (value ,str ):
        return [ch .upper ()for ch in value if ch .strip ()]
    if isinstance (value ,list ):
        return [str (ch ).upper ()for ch in value if str (ch ).strip ()]
    return []

def _flexegg_matches_monster (flexegg_id ,monster_id ):
    flex_def =_flexegg_definition (flexegg_id )
    monster_def =get_monster_definition (monster_id )
    if not flex_def or not monster_def :
        return False
    rarity =flex_def .get ("Rarity")
    if rarity and str (rarity ).lower ()!=_monster_rarity (monster_def ):
        return False
    genes =_monster_genes (monster_def )
    gene_set =set (genes )
    exact_num =flex_def .get ("ExactNumGenes")
    if exact_num is not None and len (genes )!=int (exact_num ):
        return False
    min_num =flex_def .get ("MinNumGenes")
    if min_num is not None and len (genes )<int (min_num ):
        return False
    max_num =flex_def .get ("MaxNumGenes")
    if max_num is not None and len (genes )>int (max_num ):
        return False
    exact_genes =_gene_list (flex_def .get ("ExactGenes"))
    if exact_genes and gene_set !=set (exact_genes ):
        return False
    contains_genes =_gene_list (flex_def .get ("ContainsGenes"))
    if contains_genes and not set (contains_genes ).issubset (gene_set ):
        return False
    contains_any =_gene_list (flex_def .get ("ContainsAnyGenes"))
    if contains_any and not gene_set .intersection (contains_any ):
        return False
    return True

def _evolve_requirement_slot_for_monster (monster ,boxed_monster_id ):
    values =evolve_exact_boxed_eggs (monster )
    flex_values =evolve_flex_boxed_eggs (monster )
    exact_requirements =evolve_exact_requirements (monster )
    if _count (values ,boxed_monster_id )<_count (exact_requirements ,boxed_monster_id ):
        return boxed_monster_id ,False
    flex_requirements =evolve_flex_requirements (monster )
    for flexegg_id in flex_requirements :
        if _count (flex_values ,flexegg_id )>=_count (flex_requirements ,flexegg_id ):
            continue
        if _flexegg_matches_monster (flexegg_id ,boxed_monster_id ):
            return flexegg_id ,True
    return None

def append_boxed_egg (monster ,boxed_monster_id ):
    if not boxed_monster_id :
        return
    if monster .get ("ascend_pending"):
        values =evolve_boxed_eggs (monster )
        match =_evolve_requirement_slot_for_monster (monster ,boxed_monster_id )
        if match is not None :
            requirement_slot ,is_flex_slot =match
            values .append (requirement_slot )
            if is_flex_slot :
                flex_values =evolve_flex_boxed_eggs (monster )
                flex_values .append (requirement_slot )
                monster ["evolve_flex_boxed_eggs"]=_ints_to_json_array (flex_values )
        monster ["evolve_boxed_eggs"]=_ints_to_json_array (values )
        return
    values =boxed_eggs (monster )
    if "box_requirements"in monster :
        requirements =_ints_from_raw (monster .get ("box_requirements"))
    else :
        requirements =box_requirements (get_monster_definition (monster .get ("monster",0 )),0 )
    required_count =_count (requirements ,boxed_monster_id )
    current_count =_count (values ,boxed_monster_id )
    if required_count >0 and current_count <required_count :
        values .append (boxed_monster_id )
    monster ["boxed_eggs"]=_ints_to_json_array (values )

UNDERLING_ISLAND_TYPES =(6 ,10 ,12 )
BOX_SIMPLE_ISLAND_TYPES =(6 ,10 ,12 )
def apply_underling_box_state (monster ,definition ,island_type ):
    requirements =box_requirements (definition ,island_type )
    eggs =boxed_eggs (monster )
    monster ["box_requirements"]=_ints_to_json_array (requirements )
    if eggs :
        monster ["boxed_eggs"]=_ints_to_json_array (eggs )
    else :
        monster ["boxed_eggs"]="[]"
    monster ["has_evolve_reqs"]="[]"
    monster ["has_evolve_flexeggs"]="[]"
    for key in (
    "awakened","box_monster","inactive_box_monster","is_box_monster","is_inactive_box_monster",
    "numSoulLinks","num_soul_links","numEggsInInventory","minNumEggsRequiredInUnderling","book_value",
    "evolve_flex_boxed_eggs",
    ):
        monster .pop (key ,None )
def repair_gold_box_requirements (island ):
    if island is None or island_type_of (island )!=GOLD_ISLAND_TYPE :
        return
    for monster in island .get ("monsters")or []:
        if monster is None or monster .get ("awakened")or monster .get ("ascend_pending"):
            continue
        definition =get_monster_definition (monster .get ("monster",0 ))
        if not is_box_monster_entity (definition )or "box_requirements"not in monster :
            continue
        wanted =box_requirements (definition ,GOLD_ISLAND_TYPE )
        if not wanted or _ints_from_raw (monster .get ("box_requirements"))==wanted :
            continue
        remaining =list (wanted )
        kept =[]
        for egg in boxed_eggs (monster ):
            if egg in remaining :
                remaining .remove (egg )
                kept .append (egg )
        monster ["box_requirements"]=_ints_to_json_array (wanted )
        monster ["boxed_eggs"]=_ints_to_json_array (kept )
def clear_underling_box_state (monster ):
    for key in ("box_requirements","boxed_eggs","has_evolve_reqs","has_evolve_flexeggs","evolve_flex_boxed_eggs"):
        monster .pop (key ,None )
def repair_underling_box_state (island ):
    island_type =island_type_of (island )
    for monster in island .get ("monsters")or []:
        if monster is None :
            continue
        definition =get_monster_definition (monster .get ("monster",0 ))
        has_any_box_field =any (key in monster for key in (
        "awakened","box_monster","inactive_box_monster","is_box_monster","is_inactive_box_monster",
        "box_requirements",
        ))
        if is_box_monster_entity (definition )and not has_any_box_field :
            if island_type in BOX_SIMPLE_ISLAND_TYPES :
                apply_underling_box_state (monster ,definition ,island_type )
            else :
                apply_inactive_box_state (monster ,definition ,island_type )
            continue
        if island_type not in BOX_SIMPLE_ISLAND_TYPES :
            continue
        if not has_any_box_field :
            continue
        if not is_box_monster_entity (definition ):
            for key in (
            "awakened","box_monster","inactive_box_monster","is_box_monster","is_inactive_box_monster",
            ):
                monster .pop (key ,None )
            continue
        if bool (monster .get ("awakened")):
            if island_type in UNDERLING_ISLAND_TYPES and (definition or {}).get ("evolve_into",0 )and not monster .get ("evolve_unlocked"):
                monster ["evolve_unlocked"]=1
            if (island_type in UNDERLING_ISLAND_TYPES and monster .get ("ascend_pending")
            and _ints_from_raw (monster .get ("box_requirements"))):
                monster ["has_evolve_reqs"]=monster .get ("box_requirements")
                monster ["evolve_boxed_eggs"]=monster .get ("boxed_eggs")or "[]"
                monster ["evolve_flex_boxed_eggs"]="[]"
                monster ["box_requirements"]="[]"
                monster ["boxed_eggs"]=""
            if island_type in UNDERLING_ISLAND_TYPES and (definition or {}).get ("evolve_into",0 )and not monster .get ("ascend_pending"):
                evolve_reqs =_ints_from_raw (definition .get ("evolve_requirements"))
                evolve_flexeggs =_ints_from_raw (definition .get ("evolve_req_flexeggs"))
                if evolve_reqs or evolve_flexeggs :
                    monster ["has_evolve_reqs"]=_ints_to_json_array (evolve_reqs )
                    monster ["has_evolve_flexeggs"]=_ints_to_json_array (evolve_flexeggs )
                    monster ["evolve_boxed_eggs"]="[]"
                    monster ["evolve_flex_boxed_eggs"]="[]"
                    monster ["ascend_pending"]=True
            if (island_type in UNDERLING_ISLAND_TYPES and monster .get ("ascend_pending")
            and not _ints_from_raw (monster .get ("has_evolve_flexeggs"))):
                evolve_flexeggs =_ints_from_raw (definition .get ("evolve_req_flexeggs"))
                if evolve_flexeggs :
                    monster ["has_evolve_flexeggs"]=_ints_to_json_array (evolve_flexeggs )
        else :
            apply_underling_box_state (monster ,definition ,island_type )
def is_awakened_box_monster (monster ):
    if "awakened"in monster :
        return bool (monster .get ("awakened"))
    if "box_requirements"not in monster :
        return False
    requirements =monster .get ("box_requirements")
    return not requirements or requirements =="[]"

def ensure_box_progress_fields (monster ,definition ,island_type =0 ):
    requirements =box_requirements (definition ,island_type )
    eggs =boxed_eggs (monster )
    required =len (requirements )or monster .get ("minNumEggsRequiredInUnderling",0 )or 0 
    current =max (len (eggs ),monster .get ("numEggsInInventory",0 )or 0 )
    monster ["box_requirements"]=_ints_to_json_array (requirements )
    monster ["boxed_eggs"]=_ints_to_json_array (eggs )
    monster ["minNumEggsRequiredInUnderling"]=required 
    monster ["numEggsInInventory"]=current 

def apply_inactive_box_state (monster ,definition ,island_type =0 ):
    monster ["happiness"]=0 
    monster ["awakened"]=False 
    monster ["inactive_box_monster"]=True 
    monster ["is_inactive_box_monster"]=True 
    monster ["box_monster"]=True 
    monster ["is_box_monster"]=True 
    monster .setdefault ("book_value",(definition or {}).get ("cost_sale")or 75000000 )
    ensure_box_progress_fields (monster ,definition ,island_type )
    if not boxed_eggs (monster ):
        monster .pop ("egg_timer_start",None )

def normalize_box_state_for_island (monster ,definition ,island_type ):
    if monster .get ("ascend_pending")or not is_box_monster_entity (definition ):
        return
    if island_type in BOX_SIMPLE_ISLAND_TYPES :
        apply_underling_box_state (monster ,definition ,island_type )
    else :
        apply_inactive_box_state (monster ,definition ,island_type )

def start_amber_vessel_timer_if_needed (monster ,island_type ):
    if island_type !=22 or not boxed_eggs (monster )or (monster .get ("egg_timer_start",0 )or 0 )>0 :
        return 
    import time 
    monster ["egg_timer_start"]=int (time .time ()*1000 )

def apply_awakened_box_state (monster ,definition ,island_type ):
    monster ["awakened"]=True
    monster ["inactive_box_monster"]=False
    monster ["is_inactive_box_monster"]=False
    monster ["box_monster"]=False
    monster ["is_box_monster"]=False
    monster ["box_requirements"]="[]"
    monster ["boxed_eggs"]=""
    monster ["numEggsInInventory"]=0
    monster ["minNumEggsRequiredInUnderling"]=0
    monster ["numSoulLinks"]=0
    monster ["num_soul_links"]=0
    if (monster .get ("level",0 )or 0 )<=0 :
        monster ["level"]=1
    monster ["happiness"]=max (0 ,monster .get ("happiness",0 )or 0 )
    if not monster .get ("book_value"):
        monster ["book_value"]=(definition or {}).get ("cost_sale",0 )or 75000000
    if island_type ==12 and (definition or {}).get ("evolve_into",0 ):
        monster ["evolve_unlocked"]=1
        evolve_reqs =_ints_from_raw (definition .get ("evolve_requirements"))
        evolve_flexeggs =_ints_from_raw (definition .get ("evolve_req_flexeggs"))
        if evolve_reqs or evolve_flexeggs :
            monster ["has_evolve_reqs"]=_ints_to_json_array (evolve_reqs )
            monster ["has_evolve_flexeggs"]=_ints_to_json_array (evolve_flexeggs )
            monster ["evolve_boxed_eggs"]="[]"
            monster ["evolve_flex_boxed_eggs"]="[]"
            monster ["ascend_pending"]=True

def build_placeholder_box_monster (monster_id ,definition ,island_uid ,user_monster_id ,pos_x ,pos_y ,flip ,now ,island_type =0 ,force_locked =False ,level =1 ):
    monster ={
    "user_monster_id":SFSLong (user_monster_id ),"user_island_id":SFSLong (island_uid ),
    "island":SFSLong (island_uid ),"monster":monster_id ,"monster_id":monster_id ,
    "pos_x":pos_x ,"pos_y":pos_y ,"flip":flip ,"flipped":flip ,"muted":0 ,
    "level":level ,"happiness":0 ,"times_fed":0 ,
    "name":definition .get ("common_name")or definition .get ("name")or "",
    "in_hotel":0 ,"volume":SFSFloat (1.0 ),"last_collection":SFSLong (now ),"last_fed":SFSLong (now ),
    "last_feeding":SFSLong (now ),"date_created":SFSLong (now ),
    "collected_coins":0 ,"costume":{"eq":0 ,"p":[]},"awakened":False ,
    "is_modal":False ,"isModal":False ,
    }
    if not force_locked and (is_amber_no_vessel_island (island_type )or msm_toggles .is_enabled ("wubbox_auto_awaken")):
        apply_awakened_box_state (monster ,definition ,island_type )
    else :
        apply_inactive_box_state (monster ,definition ,island_type )
    return monster

def _find_box_island (player_object ,params ):
    island_id =params .get ("user_island_id")or params .get ("island_id")or params .get ("dest_island_id")or 0 
    if island_id :
        island =find_island (player_object ,island_id if island_id >=1000 else island_id +1000 )
        if island is not None :
            return island 
    for candidate in (_box_monster_id (params ),params .get ("user_monster_id")or 0 ):
        if not candidate :
            continue 
        island ,_monster =find_monster_with_island (player_object ,candidate )
        if island is not None :
            return island 
    return find_island (player_object ,get_active_island_id (player_object ))

def _box_monster_id (params ):
    for key in ("box_monster_id","boxMonsterId","user_box_monster_id","box_user_monster_id",
    "underling_id","user_underling_id"):
        value =params .get (key )
        if value :
            return value 
    return 0 

def _box_progress_update (monster ):
    progress =evolve_boxed_eggs (monster )if monster .get ("ascend_pending")else boxed_eggs (monster )
    return {
    "user_monster_id":SFSLong (monster .get ("user_monster_id",0 )),
    "egg_timer_start":SFSLong (monster .get ("egg_timer_start",-1 )if monster .get ("egg_timer_start")is not None else -1 ),
    "boxed_eggs":_ints_to_json_array (progress ),
    }

def _box_activate_update (monster ,species_changed =False ):
    update ={
    "user_monster_id":SFSLong (monster .get ("user_monster_id",0 )),
    "book_value":monster .get ("book_value",0 )or 0 ,
    "egg_timer_start":-1 ,
    "evolve_unlocked":monster .get ("evolve_unlocked",0 )or 0 ,
    "boxed_eggs":"",
    "last_collection":SFSLong (monster .get ("last_collection",0 )or 0 ),
    }
    if species_changed :
        update ["monster"]=monster .get ("monster",0 )
    return update

def box_add_egg (username ,params ):
    user_egg_id =params .get ("user_egg_id",0 )or 0 
    user_monster_id =params .get ("user_monster_id",0 )or 0 
    root ,player_object =load_player (username )
    result ={"success":False ,"user_egg_id":SFSLong (user_egg_id ),"user_monster_id":SFSLong (user_monster_id )}
    if not user_egg_id or not user_monster_id :
        result ["error"]="zap_target_or_egg_not_found"
        return result 

    target_island ,target_box =find_monster_with_island (player_object ,user_monster_id )
    target_definition =get_monster_definition (target_box .get ("monster",0 ))if target_box is not None else None
    if target_island is None or target_box is None or not (
    is_box_monster_entity (target_definition )or target_box .get ("ascend_pending")
    ):
        result ["error"]="zap_target_or_egg_not_found"
        return result
    if is_awakened_box_monster (target_box )and not target_box .get ("ascend_pending"):
        result ["error"]="zap_target_or_egg_not_found"
        return result

    source_island =None
    egg =None
    for island in player_object .get ("islands")or []:
        if island is None :
            continue
        for candidate in island .get ("eggs")or []:
            if candidate is not None and candidate .get ("user_egg_id")==user_egg_id :
                source_island =island
                egg =candidate
                break
        if egg is not None :
            break

    egg_type =0
    breeding_record =None
    if egg is not None :
        egg_type =egg .get ("monster",0 )
    else :
        import msm_monsters
        breeding_island ,breeding_record =msm_monsters ._find_breeding_record (player_object ,user_egg_id )
        if breeding_record is not None :
            source_island =breeding_island
            egg_type =breeding_record .get ("new_monster")or 0
            if not egg_type :
                egg_type =msm_monsters .choose_breeding_result_monster (
                breeding_record .get ("monster_1",0 ),breeding_record .get ("monster_2",0 ),
                )
    if egg is None and breeding_record is None :
        result ["error"]="zap_target_or_egg_not_found"
        return result

    if not egg_type :
        result ["error"]="zap_monster_type_not_found"
        return result

    island_type =island_type_of (target_island )
    normalize_box_state_for_island (target_box ,target_definition ,island_type )
    if target_box .get ("ascend_pending")and _evolve_requirement_slot_for_monster (target_box ,egg_type )is None :
        result ["error"]="monster_not_required"
        result ["message"]="NOTIFICATION_MONSTER_NOT_REQUIRED"
        return result
    append_boxed_egg (target_box ,egg_type )
    start_amber_vessel_timer_if_needed (target_box ,island_type )
    normalize_box_state_for_island (target_box ,target_definition ,island_type )

    if egg is not None :
        eggs =source_island .get ("eggs")or []
        for i in range (len (eggs )-1 ,-1 ,-1 ):
            if eggs [i ]is egg :
                del eggs [i ]
                break
        nursery_id =egg .get ("structure",0 )
        if nursery_id :
            for structure in source_island .get ("structures")or []:
                if structure is not None and structure .get ("user_structure_id")==nursery_id :
                    structure ["occupied"]=False
                    structure ["has_egg"]=False
                    structure ["obj_data"]=0
                    structure ["obj_end"]=0
                    break
    else :
        breeding_list =source_island .get ("breeding")or []
        if breeding_record in breeding_list :
            breeding_list .remove (breeding_record )
    save_player (username ,root )

    response ={
    "success":True ,"user_egg_id":SFSLong (user_egg_id ),
    "underling":bool (params .get ("underling")),
    "dest_island_id":SFSLong (target_island .get ("user_island_id",0 )),
    "egg_type":egg_type ,"user_monster_id":SFSLong (user_monster_id ),
    }
    if island_type ==10 :
        response ["isWublin"]=True
    return response

def box_monster_command (username ,params ):
    if params .get ("user_egg_id")and params .get ("user_monster_id"):
        return box_add_egg (username ,params )
    return box_add_monster (username ,params )

def box_add_monster (username ,params ):
    user_monster_id =params .get ("user_monster_id",0 )or 0 
    requested_box_id =_box_monster_id (params )
    root ,player_object =load_player (username )
    island =_find_box_island (player_object ,params )
    result ={"success":False ,"properties":[]}
    add_actual_currencies (result ,player_object )
    if island is None or not user_monster_id :
        return result 
    monsters =island .get ("monsters")or []

    target_box =None 
    for m in monsters :
        if m is None :
            continue 
        definition =get_monster_definition (m .get ("monster",0 ))
        if not is_box_monster_entity (definition )or is_awakened_box_monster (m ):
            continue 
        if not requested_box_id or m .get ("user_monster_id")==requested_box_id :
            target_box =m 
            requested_box_id =m .get ("user_monster_id")
            break 
    if target_box is None or requested_box_id ==user_monster_id :
        result ["error"]="missing_inactive_box_monster"
        return result 

    boxed_monster_type =0 
    found_index =None 
    for i in range (len (monsters )-1 ,-1 ,-1 ):
        m =monsters [i ]
        if m is not None and m .get ("user_monster_id")==user_monster_id :
            boxed_monster_type =m .get ("monster",0 )
            if is_box_monster_entity (get_monster_definition (boxed_monster_type )):
                result ["error"]="cannot_box_box_monster"
                return result 
            found_index =i 
            break 
    if found_index is None :
        result ["error"]="boxed_monster_not_found"
        return result

    island_type =island_type_of (island )
    box_definition =get_monster_definition (target_box .get ("monster",0 ))
    normalize_box_state_for_island (target_box ,box_definition ,island_type )
    if target_box .get ("ascend_pending"):
        if _evolve_requirement_slot_for_monster (target_box ,boxed_monster_type )is None :
            result ["error"]="monster_not_required"
            result ["message"]="NOTIFICATION_MONSTER_NOT_REQUIRED"
            return result
    elif "box_requirements"in target_box :
        target_requirements =_ints_from_raw (target_box .get ("box_requirements"))
        target_current =boxed_eggs (target_box )
        if _count (target_requirements ,boxed_monster_type )<=_count (target_current ,boxed_monster_type ):
            result ["error"]="monster_not_required"
            result ["message"]="NOTIFICATION_MONSTER_NOT_REQUIRED"
            return result
    else :
        target_requirements =box_requirements (get_monster_definition (target_box .get ("monster",0 )),island_type_of (island ))
        target_current =boxed_eggs (target_box )
        if _count (target_requirements ,boxed_monster_type )<=_count (target_current ,boxed_monster_type ):
            result ["error"]="monster_not_required"
            result ["message"]="NOTIFICATION_MONSTER_NOT_REQUIRED"
            return result

    del monsters [found_index ]

    append_boxed_egg (target_box ,boxed_monster_type )
    start_amber_vessel_timer_if_needed (target_box ,island_type )
    if island_type in BOX_SIMPLE_ISLAND_TYPES :
        apply_underling_box_state (target_box ,box_definition ,island_type )
    else :
        target_box ["numEggsInInventory"]=max (len (boxed_eggs (target_box )),target_box .get ("numEggsInInventory",0 )or 0 )
        target_box ["awakened"]=False
        apply_inactive_box_state (target_box ,box_definition ,island_type )
    save_player (username ,root )

    return {
    "user_box_monster_id":SFSLong (requested_box_id ),"success":True ,
    "user_monster_id":SFSLong (user_monster_id ),"monster_type":boxed_monster_type ,
    }

def box_purchase_fill (username ,params ):
    user_monster_id =_box_monster_id (params )or params .get ("user_monster_id",0 )or 0 
    root ,player_object =load_player (username )
    island =_find_box_island (player_object ,params )
    result ={"success":False ,"cmd":"gs_box_purchase_fill","properties":[]}
    add_actual_currencies (result ,player_object )
    if island is None or not user_monster_id :
        result ["error"]="missing_box_monster_id"
        return result ,{}

    target_island ,box_monster =find_monster_with_island (player_object ,user_monster_id ,island )
    if box_monster is None :
        result ["error"]="box_monster_not_found"
        return result ,{}
    island =target_island or island
    definition =get_monster_definition (box_monster .get ("monster",0 ))
    can_evolve =((definition or {}).get ("evolve_into",0 )or 0 )>0
    if not is_box_monster_entity (definition )and not box_monster .get ("ascend_pending"):
        if can_evolve :
            _start_evolve_round (box_monster ,definition ,island_type_of (island ))
        else :
            result ["error"]="not_box_monster"
            return result ,{}
    elif is_awakened_box_monster (box_monster )and can_evolve and not box_monster .get ("ascend_pending"):
        _start_evolve_round (box_monster ,definition ,island_type_of (island ))

    if is_awakened_box_monster (box_monster )and not box_monster .get ("ascend_pending"):
        client_result ={
        "success":True ,"cmd":"gs_box_purchase_fill",
        "user_monster_id":SFSLong (user_monster_id ),"properties":create_player_properties (player_object ),
        }
        add_actual_currencies (client_result ,player_object )
        return client_result ,_box_activate_update (box_monster )

    island_type =island_type_of (island )
    normalize_box_state_for_island (box_monster ,definition ,island_type )
    round2 =bool (box_monster .get ("ascend_pending"))
    if round2 :
        exact_requirements =evolve_exact_requirements (box_monster )
        flex_requirements =evolve_flex_requirements (box_monster )
        requirements =exact_requirements +flex_requirements
    elif "box_requirements"in box_monster :
        requirements =_ints_from_raw (box_monster .get ("box_requirements"))
    else :
        requirements =box_requirements (definition ,island_type_of (island ))
    boxed =evolve_boxed_eggs (box_monster )if round2 else boxed_eggs (box_monster )
    exact_boxed =evolve_exact_boxed_eggs (box_monster )if round2 else boxed
    flex_boxed =evolve_flex_boxed_eggs (box_monster )if round2 else []
    before =len (boxed )
    if round2 :
        for i ,wanted in enumerate (exact_requirements ):
            required_through_slot =_count (exact_requirements [:i +1 ],wanted )
            if _count (exact_boxed ,wanted )<required_through_slot :
                boxed .append (wanted )
                exact_boxed .append (wanted )
        for i ,wanted in enumerate (flex_requirements ):
            required_through_slot =_count (flex_requirements [:i +1 ],wanted )
            if _count (flex_boxed ,wanted )<required_through_slot :
                boxed .append (wanted )
                flex_boxed .append (wanted )
    else :
        pool =list (requirements )
        matched =[]
        for egg in boxed :
            if egg in pool :
                pool .remove (egg )
                matched .append (egg )
        boxed [:]=matched
        before =len (boxed )
        for i ,wanted in enumerate (requirements ):
            required_through_slot =_count (requirements [:i +1 ],wanted )
            if _count (boxed ,wanted )<required_through_slot :
                boxed .append (wanted )
    filled =max (0 ,len (boxed )-before )

    pref_wildcards =params .get ("pref_wildcards",True )
    wildcards_spent =0 
    diamonds_spent =0 
    if filled >0 :
        egg_wildcards =max (player_object .get ("egg_wildcards",0 )or 0 ,player_object .get ("playerEggWildcards",0 )or 0 )
        remaining =filled 
        if pref_wildcards and egg_wildcards >0 :
            wildcards_spent =min (remaining ,egg_wildcards )
            if msm_toggles .is_enabled ("functioning_currencies"):
                new_wildcards =max (0 ,egg_wildcards -wildcards_spent )
                player_object ["egg_wildcards"]=new_wildcards 
                player_object ["egg_wildcards_actual"]=new_wildcards 
                player_object ["playerEggWildcards"]=new_wildcards 
            remaining -=wildcards_spent 
        if remaining >0 :
            per_monster_key =(
            "USER_WUBLIN_BOX_INVENTORY_DIAMOND_PRICE_PER_MONSTER"
            if island_type_of (island )in (10 ,12 )
            else "USER_BOX_INVENTORY_DIAMOND_PRICE_PER_MONSTER"
            )
            if island_type_of (island )==GOLD_ISLAND_TYPE :
                class_name =((definition or {}).get ("class")or "").upper ()
                per_monster_key =(
                "USER_GOLD_EPIC_BOX_INVENTORY_DIAMOND_PRICE_PER_MONSTER"if "EPIC"in class_name
                else "USER_GOLD_RARE_BOX_INVENTORY_DIAMOND_PRICE_PER_MONSTER"if "RARE"in class_name
                else "USER_GOLD_BOX_INVENTORY_DIAMOND_PRICE_PER_MONSTER"
                )
            per_monster_cost =get_user_game_setting_int (per_monster_key ,30 )
            diamonds_spent =remaining *per_monster_cost
            diamonds =player_object .get ("diamonds",0 )or 0
            new_diamonds =max (0 ,diamonds -diamonds_spent )
            player_object ["diamonds"]=new_diamonds
            player_object ["diamonds_actual"]=new_diamonds

    if round2 :
        box_monster ["evolve_boxed_eggs"]=_ints_to_json_array (boxed )
        box_monster ["evolve_flex_boxed_eggs"]=_ints_to_json_array (flex_boxed )
    else :
        box_monster ["boxed_eggs"]=_ints_to_json_array (boxed )
    start_amber_vessel_timer_if_needed (box_monster ,island_type )
    if round2 :
        pass
    elif island_type in BOX_SIMPLE_ISLAND_TYPES :
        apply_underling_box_state (box_monster ,definition ,island_type )
    else :
        box_monster ["numEggsInInventory"]=len (boxed )
        box_monster ["minNumEggsRequiredInUnderling"]=len (requirements )
        box_monster ["awakened"]=False
        apply_inactive_box_state (box_monster ,definition ,island_type )
    save_player (username ,root )

    result ={
    "success":True ,"user_monster_id":SFSLong (user_monster_id ),
    "user_box_monster_id":SFSLong (user_monster_id ),"gi_monster_id":SFSLong (user_monster_id ),
    "properties":create_player_properties (player_object ),
    }
    if round2 :
        update =_box_activate_update (box_monster )
        update .update (round2_wire_progress (box_monster ))
        result .update (round2_wire_progress (box_monster ))
        return result ,update
    return result ,_box_progress_update (box_monster )

def wake_wubbox (username ,params ):
    logger .info ("wake_wubbox called params=%r",params )
    user_monster_id =params .get ("user_monster_id",0 )or 0
    validate_only =bool (params .get ("validate_only"))
    root ,player_object =load_player (username )
    island =_find_box_island (player_object ,params )
    result ={"success":False ,"properties":[]}
    add_actual_currencies (result ,player_object )
    if island is None :
        return result ,{}

    monster =None
    if user_monster_id :
        found_island ,monster =find_monster_with_island (player_object ,user_monster_id ,island )
        if monster is not None :
            island =found_island
    if monster is None :
        for m in island .get ("monsters")or []:
            if m is not None and not is_awakened_box_monster (m )and is_box_monster_entity (get_monster_definition (m .get ("monster",0 ))):
                monster =m 
                user_monster_id =m .get ("user_monster_id",0 )
                break 
    if monster is None :
        return result ,{}
    logger .info (
    "wake_wubbox resolved monster=%r user_monster_id=%r awakened_field=%r box_requirements=%r is_awakened=%r",
    monster .get ("monster"),user_monster_id ,monster .get ("awakened"),monster .get ("box_requirements"),is_awakened_box_monster (monster ),
    )
    if is_awakened_box_monster (monster ):
        awakened_definition =get_monster_definition (monster .get ("monster",0 ))
        evolve_into_entity_id =(awakened_definition or {}).get ("evolve_into",0 )or 0
        next_monster_id =get_monster_id_for_entity_id (evolve_into_entity_id )if evolve_into_entity_id else 0
        logger .info (
        "wake_wubbox on already-awakened monster=%r evolve_into_entity_id=%r next_monster_id=%r",
        monster .get ("monster"),evolve_into_entity_id ,next_monster_id ,
        )
        if monster .get ("ascend_pending"):
            round2_required =evolve_requirements_combined (monster )
            if round2_required and len (evolve_boxed_eggs (monster ))<len (round2_required ):
                logger .info (
                "wake_wubbox ascend blocked - round2 not filled monster=%r required=%r boxed=%r",
                monster .get ("monster"),round2_required ,evolve_boxed_eggs (monster ),
                )
                return {"success":False ,"user_monster_id":SFSLong (user_monster_id )},{}
        if next_monster_id >0 and monster .get ("monster")!=next_monster_id :
            monster ["monster"]=next_monster_id
            monster ["monster_id"]=next_monster_id
            monster ["evolve_enabled"]=1
            monster ["evolve_unlocked"]=1
            monster ["powerup_unlocked"]=1
            monster .pop ("ascend_pending",None )
            monster .pop ("has_evolve_reqs",None )
            monster .pop ("has_evolve_flexeggs",None )
            monster .pop ("evolve_boxed_eggs",None )
            monster .pop ("evolve_flex_boxed_eggs",None )
            new_definition =get_monster_definition (next_monster_id )
            further_evolve_into =(new_definition or {}).get ("evolve_into",0 )or 0
            if further_evolve_into >0 :
                monster ["evolve_into"]=further_evolve_into
                further_evolve_reqs =_ints_from_raw (new_definition .get ("evolve_requirements"))
                further_evolve_flexeggs =_ints_from_raw (new_definition .get ("evolve_req_flexeggs"))
                monster ["has_evolve_reqs"]=_ints_to_json_array (further_evolve_reqs )
                monster ["has_evolve_flexeggs"]=_ints_to_json_array (further_evolve_flexeggs )
                monster ["evolve_boxed_eggs"]="[]"
                monster ["evolve_flex_boxed_eggs"]="[]"
                monster ["ascend_pending"]=True
            save_player (username ,root )
            client_result ={
            "success":True ,"user_monster_id":SFSLong (user_monster_id ),
            "monster":next_monster_id ,"evolution":True ,
            }
            update =_box_activate_update (monster ,species_changed =True )
            logger .info ("wake_wubbox species swap response client_result=%r update=%r",client_result ,update )
            return client_result ,update
        client_result ={"success":True ,"user_monster_id":SFSLong (user_monster_id ),"evolution":False }
        update =_box_activate_update (monster )
        logger .info ("wake_wubbox no-op (no evolve_into) response client_result=%r update=%r",client_result ,update )
        return client_result ,update

    definition =get_monster_definition (monster .get ("monster",0 ))
    import msm_monsters
    def _predicted_nursery_id ():
        nursery =msm_monsters ._find_nursery (island ,0 )
        return nursery .get ("user_structure_id",2 )if nursery is not None else 2
    if validate_only :
        return {
        "success":False ,"validated":True ,
        "nursery_id":_predicted_nursery_id (),
        "user_monster_id":SFSLong (user_monster_id ),
        },{}

    island_type =island_type_of (island )
    required =box_requirements (definition ,island_type )
    if required and len (boxed_eggs (monster ))<len (required ):
        return {
        "success":False ,"validated":True ,
        "nursery_id":_predicted_nursery_id (),
        "user_monster_id":SFSLong (user_monster_id ),
        },{}

    if island_type ==22 :
        vessel_species =monster .get ("monster",0 )or 0
        vessel_name =monster .get ("name")or ""
        vessel_book_value =monster .get ("book_value",0 )or 0
        island_uid =island .get ("user_island_id",0 )
        monsters =island .get ("monsters")or []
        for i in range (len (monsters )-1 ,-1 ,-1 ):
            if monsters [i ]is not None and monsters [i ].get ("user_monster_id")==user_monster_id :
                del monsters [i ]
                break
        sell_result ={
        "success":True ,"user_monster_id":SFSLong (user_monster_id ),
        "properties":create_player_properties (player_object ),
        }
        add_actual_currencies (sell_result ,player_object )
        import msm_monsters
        user_egg ,nursery =msm_monsters .place_egg (
        player_object ,island ,vessel_species ,"wake_wubbox",previous_name =vessel_name or None ,
        )
        if user_egg is None :
            save_player (username ,root )
            return {"success":False ,"user_monster_id":SFSLong (user_monster_id )},[("gs_sell_monster",sell_result )]
        user_egg ["book_value"]=vessel_book_value
        save_player (username ,root )
        buy_egg_result ={
        "user_egg":user_egg ,"success":True ,
        "properties":create_player_properties (player_object ),
        }
        add_actual_currencies (buy_egg_result ,player_object )
        return {"success":True ,"user_monster_id":SFSLong (user_monster_id )},[
        ("gs_sell_monster",sell_result ),
        ("gs_buy_egg",buy_egg_result ),
        ]

    apply_awakened_box_state (monster ,definition ,island_type )
    save_player (username ,root )

    client_result ={"success":True ,"user_monster_id":SFSLong (user_monster_id ),"evolution":False }
    return client_result ,_box_activate_update (monster )

def box_activate_monster (username ,params ):
    return wake_wubbox (username ,params )

def _start_evolve_round (monster ,definition ,island_type =0 ):
    if not is_awakened_box_monster (monster ):
        apply_awakened_box_state (monster ,definition ,island_type )
    evolve_into =(definition or {}).get ("evolve_into",0 )or 0
    monster ["evolve_unlocked"]=1
    monster ["evolve_enabled"]=1
    monster ["evolve_into"]=evolve_into
    if not monster .get ("ascend_pending"):
        evolve_reqs =_ints_from_raw (definition .get ("evolve_requirements"))
        evolve_flexeggs =_ints_from_raw (definition .get ("evolve_req_flexeggs"))
        monster ["has_evolve_reqs"]=_ints_to_json_array (evolve_reqs )
        monster ["has_evolve_flexeggs"]=_ints_to_json_array (evolve_flexeggs )
        monster ["evolve_boxed_eggs"]="[]"
        monster ["evolve_flex_boxed_eggs"]="[]"
        monster ["ascend_pending"]=True
    elif not _ints_from_raw (monster .get ("has_evolve_flexeggs")):
        evolve_flexeggs =_ints_from_raw (definition .get ("evolve_req_flexeggs"))
        if evolve_flexeggs :
            monster ["has_evolve_flexeggs"]=_ints_to_json_array (evolve_flexeggs )
def purchase_evolve_unlock (username ,params ):
    user_monster_id =params .get ("user_monster_id",0 )or 0
    root ,player_object =load_player (username )
    result ={"success":False ,"user_monster_id":SFSLong (user_monster_id ),"properties":create_player_properties (player_object )}
    if not user_monster_id :
        result ["error"]="evolve_monster_not_found"
        return result ,{}
    _ ,monster =find_monster_with_island (player_object ,user_monster_id )
    if monster is None :
        result ["error"]="evolve_monster_not_found"
        return result ,{}
    definition =get_monster_definition (monster .get ("monster",0 ))
    evolve_into =(definition or {}).get ("evolve_into",0 )or 0
    if evolve_into <=0 :
        result ["error"]="evolve_not_available"
        return result ,{}
    if is_box_monster_entity (definition )and not is_awakened_box_monster (monster ):
        result ["error"]="evolve_monster_not_awakened"
        return result ,{}
    unlock_island ,_unused =find_monster_with_island (player_object ,user_monster_id )
    _start_evolve_round (monster ,definition ,island_type_of (unlock_island )if unlock_island else 0 )
    save_player (username ,root )
    result ={"success":True ,"user_monster_id":SFSLong (user_monster_id ),"properties":create_player_properties (player_object )}
    update =_box_activate_update (monster )
    update .update (round2_wire_progress (monster ))
    update ["evolve_enabled"]=1
    update ["evolve_into"]=evolve_into
    return result ,update

def attempt_early_box_activate (username ,params ):
    user_monster_id =params .get ("user_monster_id",0 )or 0
    root ,player_object =load_player (username )
    result ={
    "success":False ,"attempt_success":False ,
    "user_monster_id":SFSLong (user_monster_id ),
    "num_egg_wildcards":int (player_object .get ("egg_wildcards",0 )or 0 ),
    "wildcard_confetti_popup":False ,
    "properties":create_player_properties (player_object ),
    }
    if not user_monster_id :
        return result ,{}
    island ,monster =find_monster_with_island (player_object ,user_monster_id )
    if monster is None or island is None :
        return result ,{}
    definition =get_monster_definition (monster .get ("monster",0 ))
    if not is_box_monster_entity (definition ):
        return result ,{}
    island_type =island_type_of (island )
    required =_ints_from_raw (monster .get ("box_requirements"))
    if required :
        monster ["boxed_eggs"]=_ints_to_json_array (required )
    apply_awakened_box_state (monster ,definition ,island_type )
    save_player (username ,root )
    result ["success"]=True
    result ["attempt_success"]=True
    result ["properties"]=create_player_properties (player_object )
    add_actual_currencies (result ,player_object )
    return result ,_box_activate_update (monster )

def purchase_evo_powerup_unlock (username ,params ):
    user_monster_id =params .get ("user_monster_id",0 )or 0
    root ,player_object =load_player (username )
    result ={"success":False ,"user_monster_id":SFSLong (user_monster_id ),"properties":create_player_properties (player_object )}
    if not user_monster_id :
        result ["error"]="evolve_monster_not_found"
        return result ,{}
    _ ,monster =find_monster_with_island (player_object ,user_monster_id )
    if monster is None :
        result ["error"]="evolve_monster_not_found"
        return result ,{}
    definition =get_monster_definition (monster .get ("monster",0 ))
    evolve_into =(definition or {}).get ("evolve_into",0 )or 0
    if evolve_into <=0 :
        result ["error"]="evolve_not_available"
        return result ,{}
    monster ["evolve_unlocked"]=1
    monster ["powerup_unlocked"]=1
    if not monster .get ("ascend_pending"):
        evolve_reqs =_ints_from_raw (definition .get ("evolve_requirements"))
        evolve_flexeggs =_ints_from_raw (definition .get ("evolve_req_flexeggs"))
        monster ["has_evolve_reqs"]=_ints_to_json_array (evolve_reqs )
        monster ["has_evolve_flexeggs"]=_ints_to_json_array (evolve_flexeggs )
        monster ["evolve_boxed_eggs"]="[]"
        monster ["evolve_flex_boxed_eggs"]="[]"
        monster ["ascend_pending"]=True
    elif not _ints_from_raw (monster .get ("has_evolve_flexeggs")):
        evolve_flexeggs =_ints_from_raw (definition .get ("evolve_req_flexeggs"))
        if evolve_flexeggs :
            monster ["has_evolve_flexeggs"]=_ints_to_json_array (evolve_flexeggs )
    save_player (username ,root )
    result ={
    "success":True ,"user_monster_id":SFSLong (user_monster_id ),
    "powerup_unlocked":1 ,"properties":create_player_properties (player_object ),
    }
    update =_box_activate_update (monster )
    update .update (round2_wire_progress (monster ))
    update ["powerup_unlocked"]=1
    return result ,update
