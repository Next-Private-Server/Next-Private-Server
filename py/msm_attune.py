import time
from msm_playerdata import SFSLong ,action_result ,create_player_properties ,find_island_by_structure ,find_monster_with_island ,load_player ,save_player
from msm_structures import _charge_speedup
_ATTUNING_DURATION_MS =18000000
def _attune_structure_id (params ):
    return params .get ("user_structure_id")or params .get ("structure_id")or 0
def _requested_gene (params ,key ="end_gene"):
    gene =params .get (key )or (params .get ("gene")if key =="end_gene"else None )or params .get ("genes")or ""
    return (gene or "").strip ().upper ()[:1 ]
def _find_attuning_entry (island ,structure_id ):
    for entry in (island or {}).get ("attuning")or []:
        if entry is not None and entry .get ("structure")==structure_id :
            return entry
    return None
def _grant_attuned_critter (island ,gene ):
    if island is None or not gene :
        return
    critters =island .setdefault ("attuned_critters",[])
    match =next ((e for e in critters if e is not None and e .get ("gene")==gene ),None )
    if match is None :
        critters .append ({"gene":gene ,"num":1 })
    else :
        num =max (match .get ("num",0 )or 0 ,match .get ("count",0 )or 0 ,match .get ("amount",0 )or 0 )+1
        match .clear ()
        match ["gene"]=gene
        match ["num"]=num
def start_attuning (username ,params ):
    structure_id =_attune_structure_id (params )
    root ,player_object =load_player (username )
    island ,structure =find_island_by_structure (player_object ,structure_id )if structure_id else (None ,None )
    if island is None :
        return action_result (False ,"user_structure_id",structure_id ,with_properties =True )
    now =int (time .time ()*1000 )
    complete_on =now +_ATTUNING_DURATION_MS
    end_gene =_requested_gene (params ,"end_gene")or "G"
    start_gene =_requested_gene (params ,"start_gene")
    attuning_data ={
    "reattuned_monster":0 ,"started_on":SFSLong (now ),"start_gene":start_gene ,
    "complete_on":SFSLong (complete_on ),"end_gene":end_gene ,"structure":SFSLong (structure_id ),
    }
    entries =island .setdefault ("attuning",[])
    island ["attuning"]=[e for e in entries if e is not None and e .get ("structure")!=structure_id ]
    island ["attuning"].append (attuning_data )
    if structure is not None :
        structure .update ({
        "active":True ,"is_active":True ,"in_use":True ,"is_processing":True ,"is_attuning":True ,
        "collectable":False ,"ready":False ,"obj_data":1 ,"obj_end":complete_on ,
        "started_on":now ,"startTime":now ,"complete_on":complete_on ,"building_completed":complete_on ,
        "finishing_time":complete_on ,"finished_at":complete_on ,
        "seconds_remaining":_ATTUNING_DURATION_MS //1000 ,"time_remaining":_ATTUNING_DURATION_MS ,
        "end_gene":end_gene ,"genes":end_gene ,"user_attuning_data":attuning_data ,
        "attuner_gene_granted":False ,
        })
    save_player (username ,root )
    result =action_result (True ,"user_structure_id",structure_id )
    result ["user_attuning_data"]=attuning_data
    result ["properties"]=create_player_properties (player_object )
    return result
def speedup_attuning (username ,params ):
    structure_id =_attune_structure_id (params )
    root ,player_object =load_player (username )
    island ,structure =find_island_by_structure (player_object ,structure_id )if structure_id else (None ,None )
    now =int (time .time ()*1000 )
    result ={"success":True ,"user_structure_id":SFSLong (structure_id )}
    entry =_find_attuning_entry (island ,structure_id )
    if entry is not None :
        started_on =entry .get ("started_on",SFSLong (now ))
        remaining =max (0 ,(entry .get ("complete_on",now )or now )-now )
        _charge_speedup (player_object ,remaining )
        entry ["complete_on"]=SFSLong (now )
        result ["started_on"]=started_on
        if structure is not None :
            structure .update ({
            "complete_on":now ,"obj_end":now ,"building_completed":now ,"finishing_time":now ,"finished_at":now ,
            "seconds_remaining":0 ,"time_remaining":0 ,
            "collectable":True ,"ready":True ,
            })
        save_player (username ,root )
    else :
        result ["started_on"]=SFSLong (now )
    result ["complete_on"]=SFSLong (now )
    result ["properties"]=create_player_properties (player_object )
    return result
def finish_attuning (username ,params ):
    structure_id =_attune_structure_id (params )
    root ,player_object =load_player (username )
    island ,structure =find_island_by_structure (player_object ,structure_id )if structure_id else (None ,None )
    end_gene =""
    if island is not None :
        entries =island .setdefault ("attuning",[])
        for i in range (len (entries )-1 ,-1 ,-1 ):
            entry =entries [i ]
            if entry is not None and entry .get ("structure")==structure_id :
                end_gene =(entry .get ("end_gene")or "").strip ().upper ()[:1 ]
                del entries [i ]
                break
        if end_gene :
            _grant_attuned_critter (island ,end_gene )
        if structure is not None :
            structure .update ({
            "active":False ,"is_active":False ,"in_use":False ,"is_processing":False ,"is_attuning":False ,
            "collectable":False ,"ready":False ,
            "obj_data":0 ,"obj_end":0 ,"started_on":0 ,"startTime":0 ,"complete_on":0 ,
            "finishing_time":0 ,"finished_at":0 ,"seconds_remaining":0 ,"time_remaining":0 ,
            "end_gene":end_gene or structure .get ("end_gene","")or "",
            "genes":end_gene or structure .get ("genes","")or "",
            "user_attuning_data":{},
            "attuner_gene_granted":True ,
            })
        save_player (username ,root )
    return {"user_structure_id":SFSLong (structure_id ),"success":True ,"end_gene":end_gene }

RARITY_RARE =1
RARITY_EPIC =2
_REATTUNE_SUCCESS_CHANCE =1.0

def _find_reattuning_entry (island ,structure_id ):
    for entry in (island or {}).get ("reattuning")or []:
        if entry is not None and entry .get ("structure")==structure_id :
            return entry
    return None

def update_reattune_monster (username ,params ):
    structure_id =_attune_structure_id (params )
    user_monster_id =params .get ("user_monster_id",0 )or 0
    rarity =params .get ("rarity",0 )or 0
    root ,player_object =load_player (username )
    island ,structure =find_island_by_structure (player_object ,structure_id )if structure_id else (None ,None )
    if island is None :
        return action_result (False ,"user_structure_id",structure_id ,with_properties =True )
    now =int (time .time ()*1000 )
    complete_on =now +_ATTUNING_DURATION_MS
    reattuning_data ={
    "structure":SFSLong (structure_id ),"user_monster_id":SFSLong (user_monster_id ),
    "rarity":rarity ,"started_on":SFSLong (now ),"complete_on":SFSLong (complete_on ),
    }
    entries =island .setdefault ("reattuning",[])
    island ["reattuning"]=[e for e in entries if e is not None and e .get ("structure")!=structure_id ]
    island ["reattuning"].append (reattuning_data )
    save_player (username ,root )
    result =action_result (True ,"user_structure_id",structure_id )
    result ["user_reattuning_data"]=reattuning_data
    result ["properties"]=create_player_properties (player_object )
    return result

def collect_reattune_monster (username ,params ):
    structure_id =_attune_structure_id (params )
    root ,player_object =load_player (username )
    island ,structure =find_island_by_structure (player_object ,structure_id )if structure_id else (None ,None )
    tuned_up =False
    if island is not None :
        entries =island .setdefault ("reattuning",[])
        entry =None
        for i in range (len (entries )-1 ,-1 ,-1 ):
            if entries [i ]is not None and entries [i ].get ("structure")==structure_id :
                entry =entries .pop (i )
                break
        if entry is not None :
            user_monster_id =entry .get ("user_monster_id",0 )or 0
            rarity =entry .get ("rarity",0 )or 0
            import random
            if random .random ()<_REATTUNE_SUCCESS_CHANCE :
                _ ,monster =find_monster_with_island (player_object ,user_monster_id )
                if monster is not None :
                    tuned_up =_apply_tune_up (monster ,rarity )
        now =int (time .time ()*1000 )
        attuning_data ={
        "reattuned_monster":0 ,"started_on":SFSLong (now ),"start_gene":"",
        "complete_on":SFSLong (now +_ATTUNING_DURATION_MS ),"end_gene":"G",
        "structure":SFSLong (structure_id ),
        }
        attuning_entries =island .setdefault ("attuning",[])
        island ["attuning"]=[e for e in attuning_entries if e is not None and e .get ("structure")!=structure_id ]
        island ["attuning"].append (attuning_data )
        save_player (username ,root )
    return {
    "success":True ,"user_structure_id":SFSLong (structure_id ),"tuned_up":tuned_up ,
    }

def _apply_tune_up (monster ,rarity ):
    import msm_gamedata
    species_id =monster .get ("monster",0 )
    common_id =msm_gamedata .common_id_for_rare (species_id )or species_id
    if rarity ==RARITY_EPIC :
        next_id =msm_gamedata .epic_id_for_common (common_id )
    else :
        next_id =msm_gamedata .rare_id_for_common (common_id )
    if not next_id or next_id ==species_id :
        return False
    next_definition =msm_gamedata .get_monster_definition (next_id )
    if next_definition is None :
        return False
    monster ["monster"]=next_id
    monster ["monster_id"]=next_id
    monster ["name"]=next_definition .get ("common_name")or next_definition .get ("name")or monster .get ("name","")
    return True

def viewed_reattuned_monster (username ,params ):
    return {"success":True }
