import json
import logging
import random
import time

from msm_playerdata import create_player_properties ,load_player ,save_player
from msm_protocol import SFSIntArray ,SFSLong
from msm_store import load_db_json
logger =logging .getLogger ("msm.cardalbum")

CARDS_PER_PACK =3
CURRENCY_REWARD_TYPES ={"COINS":"coins","DIAMONDS":"diamonds","FOOD":"food","RELICS":"relics",
"KEYS":"keys","ETHEREAL_CURRENCY":"ethereal_currency","STARPOWER":"starpower",
"EGG_WILDCARDS":"egg_wildcards","MEDALS":"medals","CLUBBOX_TOKENS":"clubbox_tokens","XP":"xp"}

_cache ={}

def _json_list (value ):
    if isinstance (value ,list ):
        return value
    try :
        return json .loads (value )if value else []
    except ValueError :
        return []

def _cards ():
    if "cards"not in _cache :
        data =load_db_json ("db_cards")or {}
        _cache ["cards"]={c ["id"]:c for c in (data .get ("card_data")or [])if "id"in c }
    return _cache ["cards"]

def _albums ():
    if "albums"not in _cache :
        data =load_db_json ("db_card_albums")or {}
        albums ={}
        for album in data .get ("card_album_data")or []:
            pages =[{"id":p .get ("id"),"cards":_json_list (p .get ("cards")),"rewards":_json_list (p .get ("rewards"))}
            for p in album .get ("pages")or []]
            albums [album ["id"]]=pages
        _cache ["albums"]=albums
    return _cache ["albums"]

def _store_items ():
    if "store_items"not in _cache :
        data =load_db_json ("db_card_album_store_items")or {}
        _cache ["store_items"]={
        i ["id"]:{"cost":i .get ("cost",0 )or 0 ,"contents":_json_list (i .get ("contents"))}
        for i in data .get ("card_album_store_item_data")or []if "id"in i
        }
    return _cache ["store_items"]

def _card_album_id (card_id ):
    for album_id ,pages in _albums ().items ():
        for page in pages :
            if card_id in page ["cards"]:
                return album_id
    return 1

def _cards_for_album (album_id ):
    if "cards_by_album"not in _cache :
        _cache ["cards_by_album"]={}
    per_album =_cache ["cards_by_album"]
    if album_id not in per_album :
        wanted_ids ={card_id for page in _albums ().get (album_id ,[])for card_id in page ["cards"]}
        all_cards =_cards ()
        per_album [album_id ]=[all_cards [cid ]for cid in wanted_ids if cid in all_cards ]
    return per_album [album_id ]

def _album_entry (player_object ,album_id ):
    albums =player_object .setdefault ("card_albums",[])
    for entry in albums :
        if entry .get ("card_album_id")==album_id :

            entry .setdefault ("data",{}).setdefault ("currency",0 )
            return entry
    entry ={"card_album_id":album_id ,"data":{"cards":[],"currency":0 }}
    albums .append (entry )
    return entry

def _owned_card_ids (player_object ,album_id ):
    for entry in player_object .get ("card_albums")or []:
        if entry .get ("card_album_id")==album_id :
            cards =entry .get ("data",{}).get ("cards")or []
            return {c ["i"]for c in cards if isinstance (c ,dict )and (c .get ("n",0 )or 0 )>0 }
    return set ()

def _grant_cards (player_object ,card_ids ):
    for card_id in card_ids :
        cards =_album_entry (player_object ,_card_album_id (card_id )).setdefault ("data",{}).setdefault ("cards",[])
        entry =next ((c for c in cards if c ["i"]==card_id ),None )
        if entry is None :
            cards .append ({"i":card_id ,"n":1 })
        else :
            entry ["n"]=entry .get ("n",0 )+1

def _current_album_id ():
    data =load_db_json ("db_card_albums")or {}
    albums =[a for a in (data .get ("card_album_data")or [])if isinstance (a ,dict )]
    if not albums :
        return 1
    newest =max (albums ,key =lambda a :(a .get ("last_changed")or 0 ,a .get ("id")or 0 ))
    return newest .get ("id")or 1

def _target_album_id (player_object ):
    return active_album_id ()or player_object .get ("last_card_album")or _current_album_id ()

def _sync_sticker_star_currency (player_object ,album_id =None ):
    album_id =album_id or _target_album_id (player_object )or active_album_id ()
    if not album_id :
        return 0
    entry =_album_entry (player_object ,album_id )
    data =entry .setdefault ("data",{})
    currency =_safe_int (data .get ("currency"))
    legacy_values =[_safe_int (player_object .get (key ))for key in ("sticker_stars","sticker_stars_actual")
    if key in player_object ]
    for existing in player_object .get ("card_albums")or []:
        if isinstance (existing ,dict ):
            legacy_values .append (_safe_int ((existing .get ("data")or {}).get ("currency")))
    if legacy_values :
        currency =max (currency ,max (legacy_values ))
    data ["currency"]=currency
    player_object ["sticker_stars"]=currency
    player_object ["sticker_stars_actual"]=currency
    return currency

_STICKERS_PER_PACK ={1 :1 ,2 :2 ,3 :3 ,4 :4 ,5 :6 }

def _grant_packs (player_object ,amount ,pack_type =1 ):
    pack_type =max (1 ,min (5 ,_safe_int (pack_type ,1 )))
    album_id =_target_album_id (player_object )
    defs =_cards_for_album (album_id )
    if not defs :
        return
    exponent =1.0 /pack_type
    weights =[1.0 /(max (1 ,c .get ("rarity",1 ))**exponent )for c in defs ]
    sticker_count =_STICKERS_PER_PACK .get (pack_type ,CARDS_PER_PACK )
    entry =_album_entry (player_object ,album_id )
    data =entry .setdefault ("data",{})
    packs =data .setdefault ("packs",[])
    next_id =_safe_int (player_object .get ("last_card_pack_id",0 ))
    for _ in range (max (1 ,amount )):
        picks =random .choices (defs ,weights =weights ,k =sticker_count )
        next_id +=1
        packs .append ({"c":[c ["id"]for c in picks ],"t":pack_type ,"i":next_id })
    player_object ["last_card_pack_id"]=next_id
    return [p ["i"]for p in packs [-max (1 ,amount ):]]

def _open_pending_packs (player_object ,album_id ,pack_ids =None ):
    _sync_sticker_star_currency (player_object ,album_id )
    entry =_album_entry (player_object ,album_id )
    data =entry .setdefault ("data",{})
    all_packs =data .get ("packs",[])
    if not all_packs :
        return
    if pack_ids :
        wanted =set (pack_ids )
        packs =[p for p in all_packs if p .get ("i")in wanted ]
        data ["packs"]=[p for p in all_packs if p .get ("i")not in wanted ]
    else :
        packs =all_packs
        data ["packs"]=[]
    if not packs :
        return
    cards =data .setdefault ("cards",[])
    currency =data .get ("currency",0 )or 0
    defs =_cards ()
    for pack in packs :
        for card_id in pack .get ("c")or []:
            existing =next ((c for c in cards if c ["i"]==card_id ),None )
            if existing is None :
                cards .append ({"i":card_id ,"n":1 })
            else :
                existing ["n"]=existing .get ("n",0 )+1
                rarity =(defs .get (card_id )or {}).get ("rarity",1 )or 1
                currency +=max (1 ,8 -rarity )
    data ["currency"]=currency
    player_object ["sticker_stars"]=currency
    player_object ["sticker_stars_actual"]=currency

_LOOT_WIRE_TYPES ={
"COINS":4 ,"ETHEREAL_CURRENCY":5 ,"FOOD":7 ,"RELICS":8 ,"DIAMONDS":9 ,
"MONSTER":11 ,"COSTUME":13 ,"KEYS":16 ,"STARPOWER":16 ,"CARD_PACK":18 ,
}

def _loot_entry (reward ):
    code =_LOOT_WIRE_TYPES .get (str (reward .get ("type","")).upper ())
    if code is None :
        return None
    entry ={
    "amount":int (reward .get ("amount",1 )or 1 ),
    "premium":False ,
    "id":int (reward .get ("id",0 )or 0 ),
    "type":code ,
    }
    extra =reward .get ("extra")
    if isinstance (extra ,dict )and extra :
        entry ["extra"]=dict (extra )
    return entry

def _loot_payload (rewards ):
    loot =[]
    for reward in rewards :
        entry =_loot_entry (reward )
        if entry is not None :
            loot .append (entry )
    has_costume =any (str (r .get ("type","")).upper ()=="COSTUME"for r in rewards )
    return {"updateCostumes":has_costume ,"loot":loot }

def grant_costume (player_object ,costume_id ,amount =1 ):
    costumes =player_object .get ("costumes")
    if not isinstance (costumes ,dict ):
        costumes ={}
        player_object ["costumes"]=costumes
    items =costumes .setdefault ("items",[])
    for entry in items :
        if isinstance (entry ,dict )and entry .get ("k")==costume_id :
            entry ["v"]=(entry .get ("v",0 )or 0 )+amount
            return
    items .append ({"v":amount ,"k":costume_id })

def _grant_currency_rewards (player_object ,rewards ):
    normalized =[]
    for reward in rewards :
        reward =dict (reward )
        reward_type =str (reward .get ("type","")).upper ()
        key =CURRENCY_REWARD_TYPES .get (reward_type )
        if key :
            player_object [key ]=(player_object .get (key ,0 )or 0 )+(reward .get ("amount",0 )or 0 )
            player_object [f"{key }_actual"]=player_object [key ]
        elif reward_type =="PROFILE_ITEM":
            item_id =reward .get ("id")
            if item_id is not None :
                unlocks =player_object .setdefault ("unlocks",{})
                profile_items =unlocks .setdefault ("profile_items",[])
                if item_id not in profile_items :
                    profile_items .append (item_id )
        elif reward_type =="COSTUME":
            costume_id =reward .get ("id")
            if costume_id is not None :
                grant_costume (player_object ,costume_id ,reward .get ("amount",1 )or 1 )
        if "amount"not in reward :
            reward ["amount"]=1
        normalized .append (reward )
    return normalized

def _safe_int (value ,default =0 ):
    try :
        return int (value )
    except (TypeError ,ValueError ):
        return default

def _wire_album (entry ):
    wired =dict (entry )
    data =dict (wired .get ("data")or {})

    album_id =_safe_int (wired .get ("card_album_id"))
    cards =data .get ("cards")
    cards =cards if isinstance (cards ,list )else []
    if not cards :
        first =_first_card_id (album_id )
        if first :
            cards =[{"i":first ,"n":1 }]
    data ["cards"]=cards

    owned ={c ["i"]for c in cards if isinstance (c ,dict )and (c .get ("n",0 )or 0 )>0 }
    collected =data .get ("page_rewards_collected")
    if not isinstance (collected ,list ):
        collected =[]
    collected =[int (v )for v in collected if _page_complete (album_id ,int (v ),owned )]
    data ["page_rewards_collected"]=SFSIntArray (collected )
    data ["currency"]=_safe_int (data .get ("currency"))
    data ["album_reward_collected"]=bool (data .get ("album_reward_collected"))
    data ["prestige_level"]=_safe_int (data .get ("prestige_level"))
    wired ["data"]=data

    start =_safe_int (wired .get ("event_start_time"))
    if not start :
        start =card_album_window ()[0 ]
    wired ["event_start_time"]=SFSLong (start )
    return wired

CARD_ALBUM_WINDOW_MS =8467200000

def card_album_window ():
    now =int (time .time ()*1000 )
    start =now -(now %CARD_ALBUM_WINDOW_MS )
    return start ,start +CARD_ALBUM_WINDOW_MS

def _album_event_start (album_id ):
    return card_album_window ()[0 ]

_INTERNAL_ALBUM_FIELDS =("active_card_album","last_card_album","last_card_album_start_time",
"stickers","sticker_stars","sticker_stars_actual")

def active_album_id ():
    try :
        events =load_db_json ("gs_timed_events")or {}
        for event in (events .get ("timed_event_list")or []):
            if not isinstance (event ,dict )or event .get ("event_type")!="CardAlbum":
                continue
            for row in (event .get ("data")or []):
                if isinstance (row ,dict ):
                    album_id =_safe_int (row .get ("card_album_id"))
                    if album_id :
                        return album_id
    except Exception :
        logger .exception ("could not read the running album event")
    defined =_defined_album_ids ()
    return defined [-1 ]if defined else 0

def align_cards_viewed (wired_player ):
    album_id =active_album_id ()
    if not album_id :
        return wired_player
    viewed =wired_player .get ("cards_viewed")
    if not isinstance (viewed ,dict ):
        viewed ={}
    if _safe_int (viewed .get ("card_album_id"))!=album_id :
        viewed ={"card_album_id":album_id ,"cards":[]}
    wired_player ["cards_viewed"]=viewed
    return wired_player

def strip_internal_album_fields (wired_player ):
    for key in _INTERNAL_ALBUM_FIELDS :
        wired_player .pop (key ,None )
    return wired_player

def _album_card_ids (album_id ):
    ids =[]
    try :
        data =load_db_json ("db_card_albums")or {}
        for album in (data .get ("card_album_data")or []):
            if not isinstance (album ,dict )or _safe_int (album .get ("id"))!=album_id :
                continue
            for page in (album .get ("pages")or []):
                cards =page .get ("cards")
                if isinstance (cards ,str ):
                    cards =json .loads (cards )
                for c in (cards or []):
                    cid =_safe_int (c )
                    if cid and cid not in ids :
                        ids .append (cid )
    except Exception :
        logger .exception ("could not read the album card list")
    return ids

def _page_complete (album_id ,page_id ,owned_ids ):
    for page in (_albums ().get (album_id )or []):
        if page .get ("id")==page_id :
            page_cards =page .get ("cards")or []
            return bool (page_cards )and all (c in owned_ids for c in page_cards )
    return False

def _all_page_ids (album_id ):
    return [p ["id"]for p in (_albums ().get (album_id )or [])if p .get ("id")is not None ]

def _fill_album_cards (album_id ,cards ):
    owned ={}
    for c in (cards or []):
        if isinstance (c ,dict ):
            cid =_safe_int (c .get ("i"))
            if cid :
                owned [cid ]=max (1 ,_safe_int (c .get ("n"))or 1 )
    all_ids =_album_card_ids (album_id )
    if not all_ids :
        return cards
    return [{"i":cid ,"n":owned .get (cid ,1 )}for cid in all_ids ]

def _first_card_id (album_id ):
    try :
        data =load_db_json ("db_card_albums")or {}
        for album in (data .get ("card_album_data")or []):
            if not isinstance (album ,dict )or _safe_int (album .get ("id"))!=album_id :
                continue
            for page in (album .get ("pages")or []):
                cards =page .get ("cards")
                if isinstance (cards ,str ):
                    cards =json .loads (cards )
                if cards :
                    return min (_safe_int (c )for c in cards )
    except Exception :
        logger .exception ("could not read the album card list")
    return 0

def _new_album_entry (album_id ):
    entry ={"card_album_id":album_id ,
    "data":{"cards":[],"currency":0 ,"page_rewards_collected":[]}}
    first =_first_card_id (album_id )
    if first :
        entry ["data"]["cards"]=[{"i":first ,"n":1 }]
    return entry

def _defined_album_ids ():
    try :
        data =load_db_json ("db_card_albums")or {}
        ids =[_safe_int (a .get ("id"))for a in (data .get ("card_album_data")or [])
        if isinstance (a ,dict )and _safe_int (a .get ("id"))]
        return sorted (set (ids ))
    except Exception :
        logger .exception ("could not read the album definitions")
        return []

def card_albums_wire (player_object ):
    _sync_sticker_star_currency (player_object )
    existing ={}
    for entry in (player_object .get ("card_albums")or []):
        if isinstance (entry ,dict ):
            existing .setdefault (_safe_int (entry .get ("card_album_id")),entry )

    defined =_defined_album_ids ()
    if not defined :
        return [_wire_album (e )for e in existing .values ()]

    wired =[]
    for album_id in defined :
        entry =existing .get (album_id )
        if entry is None :
            entry =_new_album_entry (album_id )
        wired .append (_wire_album (entry ))
    return wired

def _card_albums_properties (player_object ):
    return [{"card_albums":card_albums_wire (player_object )}]

def open_card_packs (username ,params ):
    logger .info ("gs_open_card_packs params: %r",params )
    root ,player_object =load_player (username )
    album_id =params .get ("card_album_id")or params .get ("album_id")or _target_album_id (player_object )
    pack_ids =params .get ("card_pack_ids")or params .get ("pack_ids")
    _open_pending_packs (player_object ,album_id ,pack_ids )
    save_player (username ,root )
    return [
    ("gs_open_card_packs",{"success":True }),
    ("gs_update_properties",{"properties":_card_albums_properties (player_object )}),
    ]

def buy_card_album_store_item (username ,params ):
    logger .info ("gs_buy_card_album_store_item params: %r",params )
    item =_store_items ().get (params .get ("item_id")or params .get ("id")or params .get ("store_item_id")or 0 )
    if item is None :
        return {"success":False }
    root ,player_object =load_player (username )
    album_id =params .get ("card_album_id")or params .get ("album_id")or _target_album_id (player_object )
    entry =_album_entry (player_object ,album_id )
    data =entry .setdefault ("data",{})
    currency =_sync_sticker_star_currency (player_object ,album_id )

    data ["currency"]=max (0 ,currency -item ["cost"])
    player_object ["sticker_stars"]=data ["currency"]
    player_object ["sticker_stars_actual"]=data ["currency"]
    loot =[]
    for content in item ["contents"]:
        if str (content .get ("type","")).upper ()=="CARD_PACK":
            amount =content .get ("amount",1 )or 1
            tier =content .get ("id",1 )or 1
            _grant_packs (player_object ,amount ,tier )
            loot .append ({"amount":int (amount ),"premium":False ,"scaled":False ,"scale":False ,
            "id":int (tier ),"type":18 })
    save_player (username ,root )
    return [
    ("gs_buy_card_album_store_item",{"success":True ,"rewards":{"updateCardAlbum":True ,"updateCostumes":False ,"loot":loot }}),
    ("gs_update_properties",{"properties":_card_albums_properties (player_object )}),
    ]

def _collect (username ,params ,whole_album ,command ="gs_collect_card_album_page_rewards"):
    root ,player_object =load_player (username )
    album_id =(params .get ("card_album_id")or params .get ("album_id")
    or player_object .get ("last_card_album",0 )or active_album_id ()or 0 )
    pages =_albums ().get (album_id )or []
    if not pages and album_id !=active_album_id ():
        album_id =active_album_id ()
        pages =_albums ().get (album_id )or []
    if not whole_album :
        page_id =params .get ("page_id")or params .get ("page")or 0
        pages =[p for p in pages if p ["id"]==page_id ]
    if not pages :
        return {"success":False }

    entry =_album_entry (player_object ,album_id )
    data =entry .setdefault ("data",{})
    already =bool (data .get ("album_reward_collected"))if whole_album else     (pages [0 ]["id"]in (data .get ("page_rewards_collected")or []))
    data .pop ("collected_pages",None )
    data .pop ("collected_album",None )
    owned =_owned_card_ids (player_object ,album_id )
    complete =all (card_id in owned for page in pages for card_id in page ["cards"])
    if already or not complete :
        save_player (username ,root )
        return [
        (command ,{"success":bool (already ),
        "rewards":{"updateCostumes":False ,"updateCardAlbum":True ,"loot":[]}}),
        ("gs_update_properties",{"properties":_card_albums_properties (player_object )}),
        ]

    if whole_album :
        data ["album_reward_collected"]=True
    else :
        done =data .get ("page_rewards_collected")
        if not isinstance (done ,list ):
            done =[]
        done .append (pages [0 ]["id"])
        data ["page_rewards_collected"]=done
    rewards =_grant_currency_rewards (player_object ,[r for page in pages for r in page ["rewards"]])
    save_player (username ,root )
    loot =_loot_payload (rewards )
    loot ["updateCardAlbum"]=True
    return [
    (command ,{"success":True ,"rewards":loot }),
    ("gs_update_properties",{"properties":_card_albums_properties (player_object )}),
    ]

def collect_card_album_page_rewards (username ,params ):
    return _collect (username ,params ,whole_album =False ,
    command ="gs_collect_card_album_page_rewards")

def collect_card_album_rewards (username ,params ):
    return _collect (username ,params ,whole_album =True ,
    command ="gs_collect_card_album_rewards")
