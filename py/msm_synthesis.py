import random
import time
import json
import msm_toggles
from msm_gamedata import _user_game_settings ,get_gene_instability ,get_monster_id_for_genes ,get_monster_definition ,get_structure_definition ,get_user_game_setting_float
from msm_playerdata import SFSLong ,create_player_properties ,find_island_by_structure ,find_monster ,load_player ,save_player
from msm_structures import _charge_speedup
_FAILURE_DURATION_MS =36000000
_SUCCESS_DURATION_MS ={3 :108000000 ,4 :108000000 ,5 :216000000 }
def _synth_structure_id (params ):
    return params .get ("user_structure_id")or params .get ("structure_id")or 0
def _normalized_genes (params ):
    genes =params .get ("genes")or params .get ("gene")or ""
    return "".join (sorted ((genes or "").strip ().upper ()))
def _synthesis_duration_ms (genes ,succeeded ):
    if not succeeded :
        return _FAILURE_DURATION_MS
    return _SUCCESS_DURATION_MS .get (len (genes or ""),108000000 )
def _setting_list (key ,default ):
    try :
        value =json .loads (_user_game_settings ().get (key )or "")
        return value if isinstance (value ,list )and value else default
    except (TypeError ,ValueError ):
        return default
def _synthesis_success_chance (genes ,structure =None ):
    if not genes :
        return 0.5
    definition =get_structure_definition ((structure or {}).get ("structure",0 ))or {}
    max_instability =float ((definition .get ("extra")or {}).get ("max_instability",15 )or 15 )
    instability =sum (get_gene_instability (g )for g in genes )
    bases =_setting_list ("USER_SYNTHESIZER_BASE_PERCENTAGES",[0.5 ,0.15 ,0.05 ])
    base =float (bases [min (max (len (genes )-3 ,0 ),len (bases )-1 )])
    chance_var =get_user_game_setting_float ("USER_SYNTHESIZER_CHANCE_VAR",1.5 )
    return max (0.0 ,min (1.0 ,base *(chance_var -instability /max_instability )))
def _synthesis_cost (genes ):
    costs =_setting_list ("USER_SYNTHESIZER_GENE_COSTS",[2500 ,5000 ,11111 ])
    return int (costs [min (max (len (genes )-3 ,0 ),len (costs )-1 )])
def _charge_synthesis_cost (player_object ,genes ):
    if not msm_toggles .is_enabled ("functioning_currencies"):
        return
    player_object ["ethereal_currency"]=max (0 ,(player_object .get ("ethereal_currency",0 )or 0 )-_synthesis_cost (genes ))
def _used_monster_genes (island ,used_monster ):
    monster =find_monster (island ,used_monster )if used_monster else None
    definition =get_monster_definition ((monster or {}).get ("monster",0 ))if monster else None
    return "".join (sorted (((definition or {}).get ("genes")or "").strip ().upper ()))
def _used_critters_for_genes (genes ):
    counts ={}
    for g in genes :
        counts [g ]=counts .get (g ,0 )+1
    return [{"gene":g ,"num":n }for g ,n in counts .items ()]
def _consume_critters (island ,genes ):
    bank =island .get ("attuned_critters")
    if not isinstance (bank ,list ):
        return
    for used in _used_critters_for_genes (genes ):
        for entry in bank :
            if entry is None or entry .get ("gene")!=used ["gene"]:
                continue
            have =max (entry .get ("num",0 )or 0 ,entry .get ("count",0 )or 0 ,entry .get ("amount",0 )or 0 )
            entry .clear ()
            entry ["gene"]=used ["gene"]
            entry ["num"]=max (0 ,have -used ["num"])
            break
    island ["attuned_critters"]=[e for e in bank if e is not None and (e .get ("num",0 )or 0 )>0 ]
def _find_synthesis_egg (island ,structure_id ):
    for egg in (island or {}).get ("eggs")or []:
        if egg is not None and egg .get ("structure")==structure_id :
            return egg
    return None
def _find_synthesizing_entry (island ,structure_id ):
    for entry in (island or {}).get ("synthesizing")or []:
        if entry is not None and entry .get ("structure")==structure_id :
            return entry
    return None
def _valid_used_monster_id (island ,used_monster ):
    if not used_monster :
        return 0
    try :
        used_monster =int (used_monster )
    except (TypeError ,ValueError ):
        return 0
    return used_monster if find_monster (island ,used_monster )is not None else 0
def _remove_used_monster (island ,user_monster_id ):
    if island is None or not user_monster_id :
        return
    monsters =island .get ("monsters")or []
    for i in range (len (monsters )-1 ,-1 ,-1 ):
        monster =monsters [i ]
        if monster is not None and monster .get ("user_monster_id")==user_monster_id :
            del monsters [i ]
            island ["num_monsters"]=len (monsters )
            return
def _refund_used_critters (island ,used_critters ):
    bank =island .setdefault ("attuned_critters",[])
    for critter in used_critters or []:
        gene =(critter or {}).get ("gene")
        if not gene :
            continue
        num =(critter or {}).get ("num",1 )or 1
        match =next ((e for e in bank if e is not None and e .get ("gene")==gene ),None )
        if match is None :
            bank .append ({"gene":gene ,"num":num })
        else :
            total =max (match .get ("num",0 )or 0 ,match .get ("count",0 )or 0 ,match .get ("amount",0 )or 0 )+num
            match .clear ()
            match ["gene"]=gene
            match ["num"]=total
    return bank
def start_synthesizing (username ,params ):
    structure_id =_synth_structure_id (params )
    genes =_normalized_genes (params )
    used_monster =params .get ("used_monster",0 )or params .get ("user_monster_id",0 )or 0
    root ,player_object =load_player (username )
    island ,structure =find_island_by_structure (player_object ,structure_id )if structure_id else (None ,None )
    if island is None :
        return {"success":False ,"user_structure_id":SFSLong (structure_id ),"properties":[]}
    used_monster =_valid_used_monster_id (island ,used_monster )
    combined =_normalized_genes ({"genes":_used_monster_genes (island ,used_monster )+genes })
    _consume_critters (island ,genes )
    _charge_synthesis_cost (player_object ,combined )
    now =int (time .time ()*1000 )
    monster_id =get_monster_id_for_genes (combined )
    succeeded =random .random ()<_synthesis_success_chance (combined ,structure )
    complete_on =now +_synthesis_duration_ms (combined ,succeeded )
    synthesis ={
    "used_critters":_used_critters_for_genes (genes ),
    "started_on":SFSLong (now ),"success":succeeded ,
    "complete_on":SFSLong (complete_on ),"structure":SFSLong (structure_id ),"monster":monster_id ,
    }
    if used_monster :
        synthesis ["used_monster"]=SFSLong (used_monster )
    entries =island .setdefault ("synthesizing",[])
    island ["synthesizing"]=[e for e in entries if e is not None and e .get ("structure")!=structure_id ]
    island ["synthesizing"].append (synthesis )
    last_synthesis ={"genes":genes ,"structure":SFSLong (structure_id )}
    if used_monster :
        last_synthesis ["used_monster"]=SFSLong (used_monster )
    island ["last_synthesis"]=[last_synthesis ]
    result ={
    "last_synthesis":last_synthesis ,"user_structure_id":SFSLong (structure_id ),"success":True ,
    "user_synthesizing_data":synthesis ,
    }
    if succeeded :
        island_uid =island .get ("user_island_id",0 )
        user_egg ={
        "monster":monster_id ,"laid_on":SFSLong (now ),"hatches_on":SFSLong (complete_on ),
        "island":SFSLong (island_uid ),"user_egg_id":SFSLong (_next_egg_id (player_object )),
        "costume":{"p":[],"eq":0 },"structure":SFSLong (structure_id ),
        }
        island .setdefault ("eggs",[]).append (user_egg )
        result ["user_egg"]=user_egg
    save_player (username ,root )
    result ["properties"]=create_player_properties (player_object )
    return result
def _next_egg_id (player_object ):
    next_id =int (player_object .get ("last_user_egg_id",0 )or 0 )+1
    player_object ["last_user_egg_id"]=next_id
    return next_id
def speedup_synthesizing (username ,params ):
    structure_id =_synth_structure_id (params )
    root ,player_object =load_player (username )
    island ,structure =find_island_by_structure (player_object ,structure_id )if structure_id else (None ,None )
    now =int (time .time ()*1000 )
    result ={"success":True ,"user_structure_id":SFSLong (structure_id )}
    entry =_find_synthesizing_entry (island ,structure_id )
    if entry is not None :
        started_on =entry .get ("started_on",SFSLong (now ))
        remaining =max (0 ,(entry .get ("complete_on",now )or now )-now )
        _charge_speedup (player_object ,remaining )
        entry ["complete_on"]=SFSLong (now )
        result ["started_on"]=started_on
        egg =_find_synthesis_egg (island ,structure_id )
        if egg is not None :
            egg ["hatches_on"]=SFSLong (now )
            result ["user_egg_id"]=egg .get ("user_egg_id")
        save_player (username ,root )
    else :
        result ["started_on"]=SFSLong (now )
    result ["complete_on"]=SFSLong (now )
    result ["properties"]=create_player_properties (player_object )
    return result
def collect_synthesizing_success (username ,params ):
    structure_id =_synth_structure_id (params )
    root ,player_object =load_player (username )
    island ,structure =find_island_by_structure (player_object ,structure_id )if structure_id else (None ,None )
    if island is not None :
        entries =island .setdefault ("synthesizing",[])
        for i in range (len (entries )-1 ,-1 ,-1 ):
            entry =entries [i ]
            if entry is not None and entry .get ("structure")==structure_id :
                used_monster =entry .get ("used_monster",0 )or 0
                del entries [i ]
                if used_monster :
                    _remove_used_monster (island ,used_monster )
                save_player (username ,root )
                break
    return {"structure":SFSLong (structure_id )}
def collect_synthesizing_failure (username ,params ):
    structure_id =_synth_structure_id (params )
    root ,player_object =load_player (username )
    island ,structure =find_island_by_structure (player_object ,structure_id )if structure_id else (None ,None )
    result ={"success":True ,"user_structure_id":SFSLong (structure_id )}
    if island is not None :
        entries =island .setdefault ("synthesizing",[])
        for i in range (len (entries )-1 ,-1 ,-1 ):
            entry =entries [i ]
            if entry is not None and entry .get ("structure")==structure_id :
                returned =list (entry .get ("used_critters")or [])
                _refund_used_critters (island ,returned )
                del entries [i ]
                if returned :
                    result ["reattuned_critters"]=returned
                break
        save_player (username ,root )
    return result
def finish_synthesizing (username ,params ):
    structure_id =_synth_structure_id (params )
    root ,player_object =load_player (username )
    island ,structure =find_island_by_structure (player_object ,structure_id )if structure_id else (None ,None )
    entry =_find_synthesizing_entry (island ,structure_id )
    if entry is not None and not entry .get ("success"):
        return collect_synthesizing_failure (username ,params )
    return collect_synthesizing_success (username ,params )
def collect_synthesizing (username ,params ):
    return finish_synthesizing (username ,params )
