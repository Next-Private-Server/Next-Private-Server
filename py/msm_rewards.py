import logging
import msm_toggles
import random
import time
from msm_gamedata import get_scratch_prizes ,get_spin_wheel_prizes ,monster_ids_allowed_on_island ,monster_ids_allowed_on_island
from msm_playerdata import SFSLong ,add_actual_currencies ,create_player_properties ,find_island ,get_active_island_id ,island_type_of ,load_player ,save_player
logger =logging .getLogger ("msm.rewards")
def _weighted_pick (prizes ):
    if not prizes :
        return None
    total =sum (max (0 ,p .get ("probability",0 )or 0 )for p in prizes )
    if total <=0 :
        return random .choice (prizes )
    roll =random .uniform (0 ,total )
    upto =0
    for prize in prizes :
        upto +=max (0 ,prize .get ("probability",0 )or 0 )
        if roll <=upto :
            return prize
    return prizes [-1 ]
def _pick_wheel_prize (prizes ):
    prize =_weighted_pick (prizes )
    if prize is not None and str (prize .get ("prize",""))=="jackpot":
        bonus_pool =[p for p in prizes if p .get ("is_top_prize",0 )==1 and str (p .get ("prize",""))!="jackpot"]
        bonus =_weighted_pick (bonus_pool )
        if bonus is not None :
            return bonus
    return prize
def _ticket_from_prize (prize ,request_type ):
    prize =prize or {}
    return {
    "type":request_type ,
    "is_top_prize":int (prize .get ("is_top_prize",0 )or 0 ),
    "prize":prize .get ("prize","coins"),
    "id":prize .get ("id",0 ),
    "amount":int (prize .get ("amount",0 )or 0 ),
    }
_SCALED_PRIZE_IDS =(2 ,9 ,4 ,6 ,5 ,7 ,3 ,11 )
def _scaled_prizes_payload (prizes ):
    by_id ={p .get ("id",0 ):p for p in prizes if isinstance (p ,dict )}
    rows =[]
    for prize_id in _SCALED_PRIZE_IDS :
        prize =by_id .get (prize_id )
        if prize is not None :
            rows .append ({"id":prize_id ,"scaled_amount":int (prize .get ("amount",0 )or 0 )})
    return {"prizes":rows }
_SCRATCH_COOLDOWN_MS =20 *3600 *1000
def _scratch_time_key (request_type ):
    return "monsterScratchTime"if request_type =="M"else "currencyScratchTime"
def _scratch_flag_key (request_type ):
    return "has_scratch_off_m"if request_type =="M"else "has_scratch_off_s"
def _scratch_available (player_object ,request_type ):
    return True
def _has_pending_scratch_egg (player_object ):

    for island in player_object .get ("islands")or []:
        if island is None :
            continue
        for egg in island .get ("eggs")or []:
            if egg is not None and egg .get ("source")=="scratch_off":
                return True
    return False
def player_has_scratch_off (username ,params ):
    request_type =str (params .get ("type")or "M").upper ()
    return {"success":True ,"type":request_type }
_SCRATCH_PRICE_SETTING ={"M":"USER_MONSTER_SCRATCHOFF_PRICE","S":"USER_SCRATCHOFF_PRICE"}
def play_scratch_off (username ,params ):
    request_type =str (params .get ("type")or "M").upper ()
    root ,player_object =load_player (username )

    is_purchase =params .get ("requestFree")is False
    if is_purchase :
        from msm_gamedata import get_user_game_setting_int
        price =get_user_game_setting_int (_SCRATCH_PRICE_SETTING .get (request_type ,"USER_SCRATCHOFF_PRICE"),0 )
        if price >0 :
            diamonds =_safe_int (player_object .get ("diamonds"))
            if diamonds <price :
                return {"success":False }
            player_object ["diamonds"]=diamonds -price

    prizes =get_spin_wheel_prizes ()if request_type =="S"else get_scratch_prizes (request_type )
    if request_type =="M":
        island =find_island (player_object ,get_active_island_id (player_object ))
        island_type =island_type_of (island )if island is not None else None
        if island_type :
            allowed =set (monster_ids_allowed_on_island (island_type ))
            restricted =[p for p in prizes if p .get ("amount")in allowed ]
            if restricted :
                prizes =restricted
    prize =_pick_wheel_prize (prizes )if request_type =="S"else _weighted_pick (prizes )
    ticket =_ticket_from_prize (prize ,request_type )
    now =SFSLong (int (time .time ()*1000 ))
    player_object [_scratch_flag_key (request_type )]=False
    player_object [_scratch_time_key (request_type )]=now
    player_object [f"_pending_scratch_ticket_{request_type}"]=ticket
    save_player (username ,root )
    result ={"success":True ,"ticket":ticket }
    if request_type !="M":
        result ["scaled_prizes"]=_scaled_prizes_payload (prizes )
    if is_purchase :
        full_properties ={list (p .keys ())[0 ]:p for p in create_player_properties (player_object )}
        diamonds_property =full_properties .get ("diamonds_actual")
        return [
        ("gs_play_scratch_off",result ),
        ("gs_update_properties",{"properties":[diamonds_property ]if diamonds_property else []}),
        ]

    return result
def collect_scratch_off (username ,params ):
    root ,player_object =load_player (username )
    request_type =str (params .get ("type")or "M").upper ()
    ticket =player_object .pop (f"_pending_scratch_ticket_{request_type}",None )
    if ticket is None :
        legacy =player_object .pop ("_pending_scratch_ticket",None )
        if isinstance (legacy ,dict )and str (legacy .get ("type")or "").upper ()==request_type :
            ticket =legacy
    ticket =ticket or {}
    request_type =str (ticket .get ("type")or request_type ).upper ()
    prize_type =ticket .get ("prize","coins")
    amount =int (ticket .get ("amount",0 )or 0 )
    rare =False
    epic =False
    if prize_type !="monster":
        _add_currency (player_object ,prize_type ,amount )
    elif amount >0 :
        from msm_gamedata import get_monster_definition ,monster_allowed_on_island
        from msm_box import requires_direct_placement
        from msm_monsters import place_egg ,_find_nursery
        definition =get_monster_definition (amount )
        won_common_name =str ((definition or {}).get ("common_name","")or "")
        rare =won_common_name .startswith ("Rare ")
        epic =won_common_name .startswith ("Epic ")
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
        user_egg =None
        if island is not None :
            user_egg ,_nursery =place_egg (player_object ,island ,amount ,"scratch_off",ready =True )
            if user_egg is None and requires_direct_placement (definition ,island_type_of (island )):
                island_type =island_type_of (island )or 1
                island_uid =island .get ("user_island_id",1000 +island_type )
                now_ms =int (time .time ()*1000 )
                next_egg_id =int (player_object .get ("last_user_egg_id",0 )or 0 )+1
                player_object ["last_user_egg_id"]=next_egg_id
                user_egg ={
                "monster":amount ,"monster_id":amount ,
                "laid_on":SFSLong (now_ms ),"hatches_on":SFSLong (now_ms ),
                "structure":SFSLong (0 ),"island":SFSLong (island_uid ),
                "user_egg_id":SFSLong (next_egg_id ),"costume":{"eq":0 ,"p":[]},
                "book_value":(definition or {}).get ("cost_coins",0 )or 0 ,
                "source":"scratch_off","ready":True ,
                }
                island .setdefault ("eggs",[]).append (user_egg )
        if user_egg is not None :
            ticket ["user_egg"]=user_egg
        else :
            player_object [f"_pending_scratch_ticket_{request_type }"]=ticket
    save_player (username ,root )
    properties =create_player_properties (player_object )
    now =SFSLong (int (player_object .get (_scratch_time_key (request_type ),0 )or 0 ))
    properties .append ({_scratch_time_key (request_type ):now })
    properties .append ({_scratch_flag_key (request_type ):bool (player_object .get (_scratch_flag_key (request_type ),False ))})
    result ={"success":True ,"rare":rare ,"epic":epic ,"properties":properties }
    won_egg =ticket .get ("user_egg")
    if won_egg is not None :
        result ["user_egg"]=won_egg
    frames =[("gs_collect_scratch_off",result )]
    if won_egg is not None :

        frames .append (("gs_buy_egg",{
        "success":True ,"remove_buyback":False ,
        "properties":properties ,"user_egg":won_egg ,
        }))
    return frames
def _wire_prizes (prizes ):
    rows =[]
    for p in prizes :
        row =dict (p )
        row ["amount"]=int (row .get ("amount",0 )or 0 )
        rows .append (row )
    return rows
def get_prize_wheel (username ,params ):
    prizes =_wire_prizes (get_spin_wheel_prizes ())
    return {
    "success":True ,"available":True ,"spins_remaining":1 ,"type":"S",
    "spin_wheel_prizes":prizes ,"prizes":prizes ,
    }
def spin_prize_wheel (username ,params ):
    root ,player_object =load_player (username )
    pending =player_object .get ("_pending_prize_wheel_ticket")
    if isinstance (pending ,dict )and not pending .get ("consumed"):
        return {"success":False ,"available":False ,"spins_remaining":0 ,"ticket":pending }
    raw_prizes =get_spin_wheel_prizes ()
    prize =_pick_wheel_prize (raw_prizes )
    ticket =_ticket_from_prize (prize ,"S")
    ticket ["created_at"]=SFSLong (int (time .time ()*1000 ))
    ticket ["consumed"]=False
    player_object ["_pending_prize_wheel_ticket"]=ticket
    player_object ["prizeWheelTime"]=ticket ["created_at"]
    player_object ["has_prize_wheel"]=False
    save_player (username ,root )
    prizes =_wire_prizes (raw_prizes )
    result ={
    "success":True ,"available":True ,"spins_remaining":0 ,"type":"S",
    "spin_wheel_prizes":prizes ,"prizes":prizes ,
    "ticket":ticket ,
    "scaled_prizes":_scaled_prizes_payload (raw_prizes ),
    "properties":create_player_properties (player_object ),
    }
    add_actual_currencies (result ,player_object )
    return result
def collect_prize_wheel (username ,params ):
    root ,player_object =load_player (username )
    ticket =player_object .get ("_pending_prize_wheel_ticket")
    if not isinstance (ticket ,dict ):
        return {"success":False ,"properties":create_player_properties (player_object )}
    prize_type =ticket .get ("prize","coins")
    amount =int (ticket .get ("amount",0 )or 0 )
    if not ticket .get ("consumed")and prize_type !="monster":
        _add_currency (player_object ,prize_type ,amount )
    ticket ["consumed"]=True
    player_object .pop ("_pending_prize_wheel_ticket",None )
    save_player (username ,root )
    return {"success":True ,"properties":create_player_properties (player_object )}
_FLIP_LEVEL_COUNT =9
_FLIP_SAFE_PRIZE_TYPES =("coins","food","ethereal_currency")
def _flip_prize_pool ():
    prizes =[p for p in get_spin_wheel_prizes ()if p .get ("prize")in _FLIP_SAFE_PRIZE_TYPES ]
    return prizes if prizes else [{"amount":5000 ,"prize":"coins","probability":1 }]
def _add_currency (player_object ,prize_type ,amount ):

    key ={"food":"food","diamonds":"diamonds","keys":"keys","relics":"relics",
    "ethereal_currency":"ethereal_currency","jackpot":"diamonds",
    "starpower":"starpower","medals":"medals","egg_wildcards":"egg_wildcards",
    "clubbox_tokens":"clubbox_tokens","xp":"xp","coins":"coins"}.get (prize_type ,"coins")
    if amount <=0 :
        return key ,0
    player_object [key ]=(player_object .get (key ,0 )or 0 )+amount
    return key ,amount
def _flip_level (player_object ):
    return max (1 ,min (_FLIP_LEVEL_COUNT ,int (player_object .get ("flip_level",1 )or 1 )))
def flip_minigame_cost (username ,params ):
    root ,player_object =load_player (username )
    level =int (params .get ("level")or 0 )or _flip_level (player_object )
    result ={"success":True ,"coin_cost":0 ,"diamond_cost":0 if level <=1 else 2 }
    pools =[]
    for pool_id in (2 ,3 ,4 ):
        prizes =[p for p in _flip_prize_pool ()if p .get ("is_top_prize",0 )==(1 if pool_id ==4 else 0 )]
        if prizes :
            pools .append ({
            "pool":pool_id ,
            "remaining":[{"amt":int (p .get ("amount",0 )or 0 ),"type":p .get ("prize","coins")}for p in prizes ],
            })
    if pools :
        result ["prizes_remaining"]=pools
    return result
def purchase_flip_mini_game (username ,params ):
    root ,player_object =load_player (username )
    level =int (params .get ("level")or 0 )or _flip_level (player_object )
    prize =_weighted_pick (_flip_prize_pool ())or {}
    now =SFSLong (int (time .time ()*1000 ))
    reward ={"pool":1 ,"amt":int (prize .get ("amount",0 )or 0 ),"type":prize .get ("prize","coins")}
    scaled =[{"level":i }for i in range (1 ,_FLIP_LEVEL_COUNT +1 )]

    player_object ["_pending_flip_prize"]=reward
    player_object ["flip_level"]=1
    save_player (username ,root )
    return {
    "success":True ,"ingame_reward":reward ,"level":1 ,"flipGameTime":now ,
    "level_id":1 ,"scaled_endgame_rewards":scaled ,
    }
def collect_flip_level (username ,params ):
    root ,player_object =load_player (username )
    level =int (params .get ("level")or 0 )or _flip_level (player_object )
    pending =player_object .pop ("_pending_flip_prize",None )
    if isinstance (pending ,dict ):
        prize_type =pending .get ("type","coins")
        amount =pending .get ("amt",0 )
    else :
        prize =_weighted_pick (_flip_prize_pool ())or {}
        prize_type =prize .get ("prize","coins")
        amount =prize .get ("amount",0 )
    _add_currency (player_object ,prize_type ,amount )
    next_level =level +1 if level <_FLIP_LEVEL_COUNT else 1
    player_object ["flip_level"]=next_level
    save_player (username ,root )
    reward ={"pool":1 ,"amt":int (amount or 0 ),"type":prize_type }
    result ={"silent":True ,"ingame_reward":reward ,"level":next_level ,"success":True ,"level_id":next_level }
    result ["properties"]=create_player_properties (player_object )
    return result
def collect_flip_mini_game (username ,params ):
    root ,player_object =load_player (username )
    now =SFSLong (int (time .time ()*1000 ))
    result ={"silent":True ,"success":True }
    result ["properties"]=create_player_properties (player_object )
    for prop in result ["properties"]:
        if "flipGameTime"in prop :
            prop ["flipGameTime"]=now
            break
    else :
        result ["properties"].append ({"flipGameTime":now })
    return result
def _safe_int (value ,default =0 ):
    try :
        return int (value )
    except (TypeError ,ValueError ):
        return default

_MEMORY_GAME_COIN_COST =2500
_MEMORY_GAME_DIAMOND_COST =10

def memory_minigame_current_cost (username ,params ):
    root ,player_object =load_player (username )
    plays =_safe_int (player_object .get ("memory_game_plays",0 ))
    return {
    "success":True ,
    "coin_cost":_MEMORY_GAME_COIN_COST *max (1 ,plays +1 ),
    "diamond_cost":_MEMORY_GAME_DIAMOND_COST ,
    }

def purchase_memory_mini_game (username ,params ):
    root ,player_object =load_player (username )
    plays =_safe_int (player_object .get ("memory_game_plays",0 ))
    coin_cost =_MEMORY_GAME_COIN_COST *max (1 ,plays +1 )
    if msm_toggles .is_enabled ("functioning_currencies"):
        player_object ["coins"]=max (0 ,_safe_int (player_object .get ("coins",0 ))-coin_cost )
    player_object ["memory_game_plays"]=plays +1
    save_player (username ,root )
    result ={
    "success":True ,
    "coin_cost":coin_cost ,
    "diamond_cost":_MEMORY_GAME_DIAMOND_COST ,
    "properties":create_player_properties (player_object ),
    }
    add_actual_currencies (result ,player_object )
    return result

def collect_memory_mini_game (username ,params ):
    score =_safe_int (params .get ("score",params .get ("new_score",0 )))
    root ,player_object =load_player (username )
    prev =_safe_int (player_object .get ("memory_game_highscore",0 ))
    new_high =score >prev
    if new_high :
        player_object ["memory_game_highscore"]=score
    coin_reward =max (0 ,score )*1000
    food_reward =max (0 ,score )*25
    if msm_toggles .is_enabled ("functioning_currencies"):
        _add_currency (player_object ,"coins",coin_reward )
        _add_currency (player_object ,"food",food_reward )
    plays =_safe_int (player_object .get ("memory_game_plays",0 ))
    save_player (username ,root )
    result ={
    "success":True ,
    "new_score":score ,
    "new_high_score":new_high ,
    "prev_highscore":prev ,
    "coin_reward":coin_reward ,
    "food_reward":food_reward ,
    "diamond_reward":0 ,
    "coin_replay_cost":_MEMORY_GAME_COIN_COST *max (1 ,plays +1 ),
    "diamond_replay_cost":_MEMORY_GAME_DIAMOND_COST ,
    "properties":create_player_properties (player_object ),
    }
    add_actual_currencies (result ,player_object )
    return result

def get_memory_game_numbers (username ,params ):
    root ,player_object =load_player (username )
    active_id =player_object .get ("active_island",0 )
    numbers =[]
    for island in player_object .get ("islands")or []:
        if island is None or island .get ("user_island_id")!=active_id :
            continue
        for monster in island .get ("monsters")or []:
            if len (numbers )>=12 :
                break
            monster_id =monster .get ("monster",0 )if monster is not None else 0
            if monster_id :
                numbers .append (monster_id )
        break
    for default_id in (3 ,4 ,5 ,6 ,7 ,8 ):
        if len (numbers )>=4 :
            break
        numbers .append (default_id )
    return {
    "success":True ,"numbers":numbers ,"num_cards":len (numbers ),
    "max_time":60 ,"time_limit":60 ,"coin_reward":SFSLong (5000 ),
    }
