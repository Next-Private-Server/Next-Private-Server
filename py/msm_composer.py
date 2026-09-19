import logging

from msm_playerdata import SFSLong ,island_type_of ,load_player ,save_player
from msm_protocol import SFSByteArray

logger =logging .getLogger ("msm.composer")

COMPOSER_ISLAND_TYPE =11

TRACK_FORMAT =2
DEFAULT_TEMPO =120
DEFAULT_TIME_NUMERATOR =4
DEFAULT_TIME_DENOM =4

_FIRST_TRACK_ID =100000000
_MAX_TRACK_ID =2147483000

def is_composer_island (island ):
    return isinstance (island ,dict )and island_type_of (island )==COMPOSER_ISLAND_TYPE

def _songs (player_object ):
    songs =player_object .get ("songs")
    if not isinstance (songs ,list ):
        songs =[]
        player_object ["songs"]=songs
    return songs

def _tracks (player_object ):
    tracks =player_object .get ("tracks")
    if not isinstance (tracks ,list ):
        tracks =[]
        player_object ["tracks"]=tracks
    return tracks

def _owner_id (player_object ):
    for key in ("user_id","bbb_id"):
        value =player_object .get (key )
        if isinstance (value ,int )and value :
            return int (value )
    for island in player_object .get ("islands")or []:
        if isinstance (island ,dict )and island .get ("user"):
            return int (island .get ("user"))
    return 0

def _next_track_id (player_object ):
    highest =int (player_object .get ("last_user_track_id",0 )or 0 )
    for track in _tracks (player_object ):
        if isinstance (track ,dict ):
            highest =max (highest ,int (track .get ("user_track_id",0 )or 0 ))
    for song in _songs (player_object ):
        for entry in (song or {}).get ("tracks")or []:
            if isinstance (entry ,dict ):
                highest =max (highest ,int (entry .get ("track",0 )or 0 ))
    track_id =max (highest ,_FIRST_TRACK_ID )+1
    if track_id >_MAX_TRACK_ID :
        track_id =_FIRST_TRACK_ID +1
    player_object ["last_user_track_id"]=track_id
    return track_id

def find_track (player_object ,track_id ):
    track_id =int (track_id or 0 )
    if not track_id :
        return None
    for track in _tracks (player_object ):
        if isinstance (track ,dict )and int (track .get ("user_track_id",0 )or 0 )==track_id :
            return track
    return None

def find_song (player_object ,island_uid ):
    island_uid =int (island_uid or 0 )
    if not island_uid :
        return None
    for song in _songs (player_object ):
        if isinstance (song ,dict )and int (song .get ("island",0 )or 0 )==island_uid :
            return song
    return None

def ensure_song (player_object ,island ):
    if not is_composer_island (island ):
        return None
    island_uid =int (island .get ("user_island_id",0 )or 0 )
    if not island_uid :
        return None
    song =find_song (player_object ,island_uid )
    if song is None :
        song ={
        "time_denom":DEFAULT_TIME_DENOM ,"time_numerator":DEFAULT_TIME_NUMERATOR ,
        "island":island_uid ,"tempo":DEFAULT_TEMPO ,"key_sig":0 ,
        "user":_owner_id (player_object ),"tracks":[],
        }
        _songs (player_object ).append (song )
    if not isinstance (song .get ("tracks"),list ):
        song ["tracks"]=[]
    return song

def _new_track (player_object ,name =None ,bintrack =None ,track_format =TRACK_FORMAT ):
    track ={
    "format":int (track_format or TRACK_FORMAT ),
    "bintrack":[int (n )&0xFF for n in (bintrack or [])],
    "user":_owner_id (player_object ),
    "user_track_id":_next_track_id (player_object ),
    }
    if name is not None :
        track ["name"]=str (name )
    _tracks (player_object ).append (track )
    return track

def track_for_monster (player_object ,island ,user_monster_id ):
    song =ensure_song (player_object ,island )
    if song is None :
        return None
    user_monster_id =int (user_monster_id or 0 )
    if not user_monster_id :
        return None
    for entry in song ["tracks"]:
        if isinstance (entry ,dict )and int (entry .get ("monster",0 )or 0 )==user_monster_id :
            existing =find_track (player_object ,entry .get ("track"))
            if existing is not None :
                return existing
            song ["tracks"].remove (entry )
            break
    track =_new_track (player_object )
    song ["tracks"].append ({"track":track ["user_track_id"],"monster":user_monster_id })
    return track

def _forget_monster (player_object ,song ,user_monster_id ):
    user_monster_id =int (user_monster_id or 0 )
    kept =[]
    removed =[]
    for entry in song .get ("tracks")or []:
        if isinstance (entry ,dict )and int (entry .get ("monster",0 )or 0 )==user_monster_id :
            removed .append (int (entry .get ("track",0 )or 0 ))
            continue
        kept .append (entry )
    song ["tracks"]=kept
    for track_id in removed :
        track =find_track (player_object ,track_id )
        if track is not None and "name"not in track :
            _tracks (player_object ).remove (track )
    return bool (removed )

def repair_composer_data (player_object ):
    changed =False
    for island in (player_object or {}).get ("islands")or []:
        if not is_composer_island (island ):
            continue
        song =ensure_song (player_object ,island )
        if song is None :
            continue
        monster_ids =[int (m .get ("user_monster_id",0 )or 0 )
        for m in island .get ("monsters")or []
        if isinstance (m ,dict )and m .get ("user_monster_id")]
        known ={int (e .get ("monster",0 )or 0 )for e in song ["tracks"]if isinstance (e ,dict )}
        for user_monster_id in monster_ids :
            if user_monster_id not in known :
                track_for_monster (player_object ,island ,user_monster_id )
                changed =True
        for entry in list (song ["tracks"]):
            if not isinstance (entry ,dict ):
                song ["tracks"].remove (entry )
                changed =True
                continue
            if int (entry .get ("monster",0 )or 0 )not in monster_ids :
                if _forget_monster (player_object ,song ,entry .get ("monster")):
                    changed =True
        for entry in song ["tracks"]:
            if find_track (player_object ,entry .get ("track"))is None :
                track =_new_track (player_object )
                entry ["track"]=track ["user_track_id"]
                changed =True
    return changed

def forget_monster_track (player_object ,island ,user_monster_id ):
    if not is_composer_island (island ):
        return False
    song =find_song (player_object ,island .get ("user_island_id",0 ))
    if song is None :
        return False
    return _forget_monster (player_object ,song ,user_monster_id )

def wire_track (track ):
    if not isinstance (track ,dict ):
        return track
    wired ={
    "format":int (track .get ("format",TRACK_FORMAT )or TRACK_FORMAT ),
    "bintrack":SFSByteArray (int (n )&0xFF for n in track .get ("bintrack")or []),
    "user":SFSLong (int (track .get ("user",0 )or 0 )),
    "user_track_id":SFSLong (int (track .get ("user_track_id",0 )or 0 )),
    }
    if track .get ("name")is not None :
        wired ["name"]=str (track .get ("name"))
    return wired

def wire_song (song ):
    if not isinstance (song ,dict ):
        return song
    return {
    "time_denom":int (song .get ("time_denom",DEFAULT_TIME_DENOM )or DEFAULT_TIME_DENOM ),
    "time_numerator":int (song .get ("time_numerator",DEFAULT_TIME_NUMERATOR )or DEFAULT_TIME_NUMERATOR ),
    "island":SFSLong (int (song .get ("island",0 )or 0 )),
    "tempo":int (song .get ("tempo",DEFAULT_TEMPO )or DEFAULT_TEMPO ),
    "key_sig":int (song .get ("key_sig",0 )or 0 ),
    "user":SFSLong (int (song .get ("user",0 )or 0 )),
    "tracks":[{"track":int ((e or {}).get ("track",0 )or 0 ),
    "monster":int ((e or {}).get ("monster",0 )or 0 )}
    for e in song .get ("tracks")or []if isinstance (e ,dict )],
    }

def wire_songs (player_object ):
    return [wire_song (s )for s in player_object .get ("songs")or []if isinstance (s ,dict )]

def wire_tracks (player_object ):
    return [wire_track (t )for t in player_object .get ("tracks")or []if isinstance (t ,dict )]

def _requested_track_id (params ):
    for key in ("track","user_track_id","id","track_id"):
        value =params .get (key )
        if isinstance (value ,int )and value :
            return int (value )
    return 0

def _requested_bintrack (params ):
    raw =params .get ("bintrack")
    if isinstance (raw ,(list ,tuple ,bytes ,bytearray )):
        return [int (n )&0xFF for n in raw ]
    return []

def _apply_time_signature (song ,params ):
    for key in ("tempo","key_sig","time_numerator","time_denom"):
        value =params .get (key )
        if isinstance (value ,int )and not isinstance (value ,bool ):
            song [key ]=int (value )

def save_composer_track (username ,params ):
    root ,player_object =load_player (username )
    island_uid =int (params .get ("island",0 )or 0 )
    song =find_song (player_object ,island_uid )
    if song is None :
        for island in player_object .get ("islands")or []:
            if is_composer_island (island )and int (island .get ("user_island_id",0 )or 0 )==island_uid :
                song =ensure_song (player_object ,island )
                break
    if song is not None :
        _apply_time_signature (song ,params )

    track_id =_requested_track_id (params )
    track =find_track (player_object ,track_id )
    if track is None :
        track =_new_track (player_object ,bintrack =_requested_bintrack (params ),
        track_format =params .get ("format",TRACK_FORMAT ))
        if song is not None :
            monster =int (params .get ("monster",0 )or 0 )
            if monster :
                song ["tracks"].append ({"track":track ["user_track_id"],"monster":monster })
    else :
        track ["bintrack"]=_requested_bintrack (params )
        track_format =params .get ("format")
        if isinstance (track_format ,int )and not isinstance (track_format ,bool ):
            track ["format"]=int (track_format )
    save_player (username ,root )
    return {"success":True }

def save_composer_template (username ,params ):
    root ,player_object =load_player (username )
    name =params .get ("name")
    template =None
    if name :
        for track in _tracks (player_object ):
            if isinstance (track ,dict )and str (track .get ("name",""))==str (name ):
                template =track
                break
    if template is None :
        template =_new_track (player_object ,name =name if name is not None else "",
        bintrack =_requested_bintrack (params ),
        track_format =params .get ("format",TRACK_FORMAT ))
    else :
        template ["bintrack"]=_requested_bintrack (params )
    save_player (username ,root )
    return {"success":True ,"id":SFSLong (int (template .get ("user_track_id",0 )or 0 ))}

def delete_composer_template (username ,params ):
    root ,player_object =load_player (username )
    track_id =_requested_track_id (params )
    track =find_track (player_object ,track_id )
    if track is None :
        name =params .get ("name")
        if name :
            for candidate in _tracks (player_object ):
                if isinstance (candidate ,dict )and str (candidate .get ("name",""))==str (name ):
                    track =candidate
                    break
    if track is not None :
        _tracks (player_object ).remove (track )
        removed_id =int (track .get ("user_track_id",0 )or 0 )
        for song in _songs (player_object ):
            song ["tracks"]=[e for e in song .get ("tracks")or []
            if not (isinstance (e ,dict )and int (e .get ("track",0 )or 0 )==removed_id )]
        save_player (username ,root )
    return {"success":True }
