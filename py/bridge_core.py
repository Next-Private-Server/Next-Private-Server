import asyncio
import threading
import base64
import hashlib
import json
import logging
import os
import random
import re
import secrets
import socket
import struct
import sys
import time
import xml .etree .ElementTree as ET
from pathlib import Path
from urllib .parse import parse_qs
import uvicorn
from Crypto .Cipher import AES
from Crypto .Util .Padding import pad ,unpad
from fastapi import FastAPI ,Request ,WebSocket ,WebSocketDisconnect
from fastapi .middleware .cors import CORSMiddleware
from fastapi .responses import FileResponse ,JSONResponse ,Response
import msm_protocol
import msm_store
import msm_gamedata
import msm_handlers
import msm_playerdata

class _AndroidLogWriter :
    def __init__ (self ,tag ):
        self ._buffer =""
        self ._tag =tag
        self ._app_log =None
        try :
            from java import jclass
            self ._app_log =jclass ("com.nextstars.nps.AppLog").INSTANCE
        except Exception as exc :
            self ._app_log =None
            sys .__stderr__ .write (f"[NPS] Python log bridge unavailable: {exc}\n")
    def write (self ,text ):
        if not text :
            return
        self ._buffer +=text
        while "\n"in self ._buffer :
            line ,self ._buffer =self ._buffer .split ("\n",1 )
            if not line :
                continue
            if self ._app_log is not None :
                try :
                    self ._app_log .appendBridge (line )
                    continue
                except Exception :
                    pass
            try :
                sys .__stdout__ .write (line +"\n")
            except Exception :
                pass
    def flush (self ):
        pass
    def isatty (self ):
        return False

try :
    sys .stdout =_AndroidLogWriter ("python.stdout")
    sys .stderr =_AndroidLogWriter ("python.stderr")
except Exception :
    pass

def same_name (path ,name ):
    return path .name .lower ()==name .lower ()

def locate_base ():
    _c =os .environ .get ('NPS_BASE_DIR')
    if _c :
        return Path (_c )
    _a =Path (__file__ ).resolve ().parent
    _e =[_a ,Path .cwd (),*_a .parents ,*Path .cwd ().parents ]
    _f =set ()
    for _d in _e :
        _b =str (_d ).lower ()
        if _b in _f :
            continue
        _f .add (_b )
        if 'assetfinder'in _b or 'chaquopy'in _b :
            continue
        if (_d /'Config.json').exists ()or (_d /'config.json').exists ():
            return _d
    return _a

def locate_child (base ,name ,folder =False ):
    _a =base /name
    if _a .exists ():
        return _a
    for _b in base .iterdir ():
        if same_name (_b ,name )and (_b .is_dir ()if folder else _b .is_file ()):
            return _b
    return _a
BASE_DIR =locate_base ()
CONFIG_PATH =locate_child (BASE_DIR ,'Config.json')
ACCOUNTS_PATH =locate_child (BASE_DIR ,'Accounts.json')
WHITELIST_PATH =locate_child (BASE_DIR ,'Whitelist.json')

_debug_logger =logging .getLogger ('msm')
_debug_logger .setLevel (logging .INFO )
_stdout_handler =logging .StreamHandler (sys .stdout )
_stdout_handler .setFormatter (logging .Formatter ('%(asctime)s %(name)s %(message)s'))
_debug_logger .addHandler (_stdout_handler )
_debug_logger .propagate =False
try :
    _debug_log_path =BASE_DIR /'nps_debug.log'
    _debug_handler =logging .FileHandler (str (_debug_log_path ),encoding ='utf-8')
    _debug_handler .setFormatter (logging .Formatter ('%(asctime)s %(name)s %(message)s'))
    _debug_logger .addHandler (_debug_handler )
except Exception :
    _debug_logger .exception ('Could not open the diagnostic log file; in-app logging remains enabled')

def read_json (path ,fallback ):
    try :
        if path .exists ()and path .stat ().st_size :
            _a =json .loads (path .read_text (encoding ='utf-8'))
            return _a if _a is not None else fallback
    except Exception :
        pass
    return fallback

def save_json (path ,data ):
    path .parent .mkdir (parents =True ,exist_ok =True )
    path .write_text (json .dumps (data ,indent =2 ,ensure_ascii =False ),encoding ='utf-8')

def lan_ip ():

    try :
        _s =socket .socket (socket .AF_INET ,socket .SOCK_DGRAM )
        try :
            _s .connect (('8.8.8.8',80 ))
            return _s .getsockname ()[0 ]
        finally :
            _s .close ()
    except Exception :
        return '127.0.0.1'

def config ():
    _b =read_json (CONFIG_PATH ,{})
    _a =False

    _c ={'host':'127.0.0.1','http_ports':[5050 ,8282 ],'server_ip':'127.0.0.1','game_port':9933 ,'files_folder':'Files','content_url':'','force_empty_manifest':False ,'cors_origins':['*'],'cors_credentials':False ,'token_ttl':900 ,'auth_ttl':1200 ,'login_ttl':7200 ,'log_level':'info'}
    for _d ,_e in _c .items ():
        if _d not in _b :
            _b [_d ]=_e
            _a =True
    if not _b .get ('server_id'):
        _b ['server_id']=random .randint (1000 ,9999 )
        _a =True
    if not _b .get ('token_key'):
        _b ['token_key']=secrets .token_hex (8 )
        _a =True
    if not _b .get ('token_iv'):
        _b ['token_iv']=secrets .token_hex (8 )
        _a =True
    if _b .get ('server_ip')=='auto':
        _b ['resolved_server_ip']=lan_ip ()
    if _a :
        save_json (CONFIG_PATH ,_b )
    return _b
SETTINGS =config ()
FILES_DIR =locate_child (BASE_DIR ,str (SETTINGS .get ('files_folder')or 'Files'),True )
if not (FILES_DIR /'downloads.xml').is_file ():
    _bundled_files =locate_child (BASE_DIR ,'bridge_files',True )
    if (_bundled_files /'downloads.xml').is_file ():
        FILES_DIR =_bundled_files
FILES_DIR .mkdir (parents =True ,exist_ok =True )
SFS_EXTENSION_DIR =BASE_DIR /'SFS2X'/'extensions'/'MSM'
SFS_DB_DIR =SFS_EXTENSION_DIR /'db_files'
SFS_PLAYERS_DIR =SFS_EXTENSION_DIR /'players'
msm_store .db_dir =SFS_DB_DIR
msm_store .players_dir =SFS_PLAYERS_DIR
logging .basicConfig (level =getattr (logging ,str (SETTINGS .get ('log_level','info')).upper (),logging .INFO ),format ='%(asctime)s [%(levelname)s] %(name)s: %(message)s')
logger =logging .getLogger ('msm.bridge')
import mod_api
MODS_DIR =BASE_DIR /'mods'
mod_api .load_mods (str (MODS_DIR ))
if not ACCOUNTS_PATH .exists ():
    save_json (ACCOUNTS_PATH ,[])
if not WHITELIST_PATH .exists ():
    save_json (WHITELIST_PATH ,[])
msm_store .apply_mod_db_files (BASE_DIR )
app =FastAPI (title ='LiveMSM Bridge',version ='0.3.0')
_UVICORN_SERVERS =[]
_SHUTDOWN_REQUESTED =False
_SHUTDOWN_COMPLETE =threading .Event ()
_SHUTDOWN_COMPLETE .set ()

class _SuppressShutdownCancelledError (logging .Filter ):
    def filter (self ,record ):
        if _SHUTDOWN_REQUESTED and record .exc_info and record .exc_info [0 ]is asyncio .CancelledError :
            return False
        return True

logging .getLogger ('uvicorn.error').addFilter (_SuppressShutdownCancelledError ())
logging .getLogger ('asyncio').addFilter (_SuppressShutdownCancelledError ())

def set_active_username (username ):

    msm_handlers .set_active_username (username )

def set_nps_online_config (server_url ,account_id ,session_token ,device_id ,friend_code ="",cert_hash =""):
    import nps_online
    nps_online .set_nps_online_config (server_url ,account_id ,session_token ,device_id ,friend_code ,cert_hash )

def request_shutdown (wait =True ):
    global _SHUTDOWN_REQUESTED
    _SHUTDOWN_REQUESTED =True
    for server in list (_UVICORN_SERVERS ):
        try :
            server .should_exit =True
        except Exception :
            pass
    if not wait :
        return _SHUTDOWN_COMPLETE .is_set ()
    completed =_SHUTDOWN_COMPLETE .wait (timeout =8.0 )
    if not completed :
        logger .error ('request_shutdown timed out after 8s - server may still be bound')
    return completed

async def _force_exit_watchdog (delay =5.0 ):
    while not _SHUTDOWN_REQUESTED :
        await asyncio .sleep (0.1 )
    await asyncio .sleep (delay )
    for server in list (_UVICORN_SERVERS ):
        try :
            server .force_exit =True
        except Exception :
            pass
app .add_middleware (CORSMiddleware ,allow_origins =list (SETTINGS .get ('cors_origins')or ['*']),allow_credentials =bool (SETTINGS .get ('cors_credentials',False )),allow_methods =['*'],allow_headers =['*'])
DEFAULT_ACCOUNT ={'username':'Next Private Server','email':'Nextstars@gmail.com','password':'PrivateServerStudios','user_id':'00000001AB','user_game_id':'NextPrivateServer','steam_id':'76561198000000001'}
PUBLIC_CONTENT_PREFIX ='/MSM/GameAssets/'
ZONE_NAME ='MySingingMonsters'
_HTTP_PORTS_SETTING =SETTINGS .get ('http_ports')or [5050 ,8282 ]

BLUEBOX_HTTP_PORT =int (_HTTP_PORTS_SETTING [1 ]if len (_HTTP_PORTS_SETTING )>1 else _HTTP_PORTS_SETTING [0 ])
BLUEBOX_HTTPS_PORT =8543
ACCESS_TOKEN_FALLBACK ='local-private-server-token'
ERROR_MESSAGES =['Username does not exist - re-register','Username does not exist','Invalid password','Invalid account type','Required argument missing','Login failed','Usernames do not match','Passwords do not match','The username is already in use','The email address is invalid','The email address has not been verified','Could not find the game server id based on the hostname provided','Email address not found','Connection error','Exceeded Maximum Accounts. Too Many Accounts Created.','Login info is already bound to another account','A login of this type is already bound to this account','Facebook failed to validate user on the server','These users are already friends.','No account found for that friend code.','An error has occured','The min client version is too low to play this game.','The email address you provided probably has a typo and cannot receive mail. Please contact support to resolve this issue.','Your device has been banned from sending emails. Please contact support to resolve this issue.','Accounts contain same game id.','Google Play authorization failed.','Amazon authorization failed.','Account has no data for this game.','No token was present when required','Invalid permissions','Expected client token, server token used','Expected server token, client token used','Game center authorization failed.','Global Achievement reward not found.','Too many accounts have been created from your IP address.','Game config not found for: ','GDPR consent required','Token Expired','Apple authorization failed.','Refresh Token authorization failed.','Credentials are expired.','Steam authorization failed.','Selected account type disabled.']

class AuthCode :
    BAD_CREDENTIALS =1
    AUTH_FAILED =2
    MISSING_DATA =4
    LOGIN_FAILED =5
    PASSWORD_MISMATCH =6
    PASSWORD_MISMATCH_CONFIRM =7
    ACCOUNT_EXISTS =8
    INVALID_EMAIL =9
    NOT_VERIFIED =10
    CONNECTION_ISSUE =13
    SERVER_MESSAGE =14
    GENERAL_ERROR =20
    CLIENT_TOO_OLD =21

AUTH_ERROR_TEXT ={
1 :'Email address or password not valid',
5 :'Email address or password not valid',
28 :'Email address or password not valid',
6 :'Passwords do not match',
7 :'Passwords do not match',
8 :'An account secured to this login method already exists. Log in instead?',
9 :'The email address is not valid',
10 :'This account has not been verified',
13 :'Connection issues',
21 :'You must update My Singing Monsters to play',
}

def message_for (error_id ):
    if error_id in AUTH_ERROR_TEXT :
        return AUTH_ERROR_TEXT [error_id ]
    _a =0 if error_id ==-1 else error_id
    if isinstance (_a ,int )and 0 <=_a <len (ERROR_MESSAGES ):
        return ERROR_MESSAGES [_a ]
    return ERROR_MESSAGES [AuthCode .GENERAL_ERROR ]

def error (error_id ,message =None ):
    _code =AuthCode .GENERAL_ERROR if error_id is None else int (error_id )
    return {
    'ok':False ,
    'error':_code ,
    'errorCode':_code ,
    'message':message if message is not None else message_for (_code ),
    }

def ok (data =None ):
    _a ={'ok':True }
    if data :
        _a .update (data )
    return _a

def md5 (value ):
    return hashlib .md5 (str (value ).encode ('utf-8')).hexdigest ()

def aes_encrypt (value ):
    _c =str (SETTINGS ['token_key']).encode ('utf-8')
    _b =str (SETTINGS ['token_iv']).encode ('utf-8')
    _a =AES .new (_c ,AES .MODE_CBC ,_b )
    return base64 .b64encode (_a .encrypt (pad (value .encode ('utf-8'),AES .block_size ))).decode ('utf-8')

def aes_decrypt (value ):
    _c =str (SETTINGS ['token_key']).encode ('utf-8')
    _b =str (SETTINGS ['token_iv']).encode ('utf-8')
    _a =AES .new (_c ,AES .MODE_CBC ,_b )
    return unpad (_a .decrypt (base64 .b64decode (value )),AES .block_size ).decode ('utf-8')

def load_accounts ():
    _a =read_json (ACCOUNTS_PATH ,[])
    return _a if isinstance (_a ,list )else []

def forced_account ():
    _b =load_accounts ()
    _a =dict (_b [0 ])if _b else {}
    _c =dict (DEFAULT_ACCOUNT )
    _c .update ({key :value for key ,value in _a .items ()if value not in (None ,'')})
    return _c

def load_whitelist ():
    _a =read_json (WHITELIST_PATH ,[])
    return set ((str (item ).strip ()for item in _a if str (item ).strip ()))if isinstance (_a ,list )else set ()

def account_id (value ,fallback =None ):
    if fallback is None :
        fallback =random .randint (1000000 ,2147483647 )
    _a =str (value or '').strip ()
    if not _a :
        return fallback
    try :
        if _a .lower ().startswith ('0x')or _a .startswith ('0000'):
            return int (_a ,16 )
        return int (_a )
    except Exception :
        return fallback

def password_ok (account ,password ):
    if not password :
        return False
    if account .get ('password')==password :
        return True
    if account .get ('password_sha256')==hashlib .sha256 (password .encode ('utf-8')).hexdigest ():
        return True
    return False

def find_account (username ,password ):
    if not username or not password :
        return None
    for _a in load_accounts ():
        if str (_a .get ('username',''))==str (username )and password_ok (_a ,password ):
            return _a
    return None

def find_account_by_username (username ):
    if not username :
        return None
    for _a in load_accounts ():
        if str (_a .get ('username',''))==str (username ):
            return _a
    return None

def accounts_require_password ():
    return bool (SETTINGS .get ('accounts_require_password',False ))

def resolve_login_account (username ,password ):
    if accounts_require_password ():
        _account =find_account (username ,password )
        if _account is None :
            return None ,error (AuthCode .BAD_CREDENTIALS )
        return _account ,None
    return find_account_by_username (username )or forced_account (),None

def token (username ,user_game_id ,login_type ,account_id_value ,game_id ,ttl =None ):
    _a =round (time .time ())
    _b ={'account_id':account_id_value ,'user_game_id':user_game_id ,'game':game_id ,'token_version':1 ,'time_created':_a ,'expires_at':_a +int (ttl or SETTINGS .get ('token_ttl',900 )),'username':str (username ).strip (),'login_type':login_type }
    return aes_encrypt (json .dumps (_b ,separators =(',',':')))

def client_ip (request ):
    _a =request .headers .get ('x-forwarded-for')
    if _a :
        return _a .split (',',1 )[0 ].strip ()
    return request .client .host if request .client else ''

def normalize_request_path (path ):
    if not path :
        return '/'
    _a =re .sub ('/+','/',str (path ))
    return _a or '/'

def apply_normalized_path (request ):
    _b =request .scope .get ('path')or '/'
    _a =normalize_request_path (_b )
    if _a !=_b :
        request .scope ['path']=_a
        request .scope ['raw_path']=_a .encode ('ascii','ignore')
    return (_b ,_a )

@app .middleware ('http')
async def gate (request ,call_next ):
    _e ,_d =apply_normalized_path (request )
    _a =load_whitelist ()
    _c =client_ip (request )
    if _a and _c not in _a :
        return JSONResponse ({'ok':False ,'error':'forbidden'},status_code =403 )
    _h =await call_next (request )
    _f =str (request .url .query or '')
    _i =request .headers .get ('user-agent','')
    _g =request .headers .get ('referer','')
    _b ='yes'if request .headers .get ('authorization')else 'no'
    if _e !=_d :
        logger .info ('%s %s -> %s %s ip=%s auth=%s ua=%r referer=%r query=%r',request .method ,_e ,_d ,_h .status_code ,_c ,_b ,_i ,_g ,_f )
    else :
        logger .info ('%s %s %s ip=%s auth=%s ua=%r referer=%r query=%r',request .method ,_d ,_h .status_code ,_c ,_b ,_i ,_g ,_f )
    return _h

async def params (request ):
    _a =dict (request .query_params )
    try :
        _b =await request .form ()
        _a .update (dict (_b ))
    except Exception :
        pass
    if not _a :
        try :
            _d =(await request .body ()).decode ('utf-8','ignore')
            if _d :
                if _d .lstrip ().startswith ('{'):
                    _a .update (json .loads (_d ))
                else :
                    for _c ,_e in parse_qs (_d ,keep_blank_values =True ).items ():
                        _a [_c ]=_e [-1 ]
        except Exception :
            pass
    return _a

def server_ip ():

    _v =SETTINGS .get ('server_ip')
    if _v and _v !='auto':
        return str (_v )
    return str (SETTINGS .get ('resolved_server_ip')or lan_ip ())

def content_port ():
    _b =SETTINGS .get ('content_port')
    if _b :
        return int (_b )
    _a =SETTINGS .get ('http_ports')or [80 ]
    return int (_a [0 ])

def content_root ():
    if SETTINGS .get ('content_url'):
        return str (SETTINGS ['content_url']).rstrip ('/')
    _a =content_port ()
    _b =''if _a ==80 else f':{_a }'
    return f'http://{server_ip ()}{_b }{PUBLIC_CONTENT_PREFIX }'

def sfs_block ():
    _a =server_ip ()
    _b =int (SETTINGS .get ('game_port',9933 ))
    _c =BLUEBOX_HTTP_PORT
    _d =BLUEBOX_HTTPS_PORT
    _e ='/BlueBox/BlueBox.do'
    _f =f'ws://{_a }:{_c }/msm/socket'
    _g =f'http://{_a }:{_c }{_e }'
    _h =f'https://{_a }:{_d }{_e }'
    _i =f'http|websocket|{_a }|{_c }'
    return {'host':_a ,'ip':_a ,'address':_a ,'hostname':_a ,'serverAddress':_a ,'serverId':int (SETTINGS .get ('server_id',1 )),'server_id':int (SETTINGS .get ('server_id',1 )),'serverIp':_i ,'serverIP':_i ,'server_ip':_i ,'serverHost':_a ,'server_host':_a ,'port':_b ,'serverPort':_b ,'server_port':_b ,'socketPort':_b ,'socket_port':_b ,'tcpPort':_b ,'tcp_port':_b ,'tcpPortNumber':_b ,'sfsHost':_a ,'sfs_host':_a ,'sfsIp':_a ,'sfsIP':_a ,'sfs_ip':_a ,'sfsPort':_b ,'sfs_port':_b ,'tcp_host':_a ,'tcp_port':_b ,'zone':ZONE_NAME ,'zoneName':ZONE_NAME ,'zone_name':ZONE_NAME ,'sfs_zone':ZONE_NAME ,'protocol':'websocket','transport':'websocket','connection':'websocket','connectionType':'websocket','connection_type':'websocket','socket':True ,'use_socket':True ,'useSocket':True ,'secure':False ,'ssl':False ,'tls':False ,'use_ssl':False ,'use_tls':False ,'useSSL':False ,'useTLS':False ,'websocket':True ,'webSocket':True ,'use_websocket':True ,'useWebSocket':True ,'websocketHost':_a ,'websocket_host':_a ,'webSocketHost':_a ,'wsHost':_a ,'ws_host':_a ,'websocketPort':_c ,'websocket_port':_c ,'webSocketPort':_c ,'wsPort':_c ,'ws_port':_c ,'websocketPath':'/msm/socket','websocket_path':'/msm/socket','websocketUrl':_f ,'websocket_url':_f ,'webSocketUrl':_f ,'wsUrl':_f ,'ws_url':_f ,'bluebox':False ,'blueBox':False ,'use_bluebox':False ,'useBlueBox':False ,'blueboxHost':_a ,'bluebox_host':_a ,'blueBoxHost':_a ,'blueBoxIpAddress':_a ,'blueboxPort':_c ,'bluebox_port':_c ,'blueBoxPort':_c ,'httpPort':_c ,'http_port':_c ,'httpsPort':_d ,'https_port':_d ,'blueboxUrl':_g ,'bluebox_url':_g ,'blueBoxUrl':_g ,'blueboxSslUrl':_h ,'bluebox_ssl_url':_h ,'blueBoxSslUrl':_h }

def server_id ():
    return int (SETTINGS .get ('server_id')or 1 )

def pregame_response_exact ():

    return {'ok':True ,'serverId':server_id (),'serverIp':sfs_block ()['serverIp'],'contentUrl':content_root ()}

def game_config_response_exact ():

    _login_types =[
    {'type':'email','auto_create':False ,'can_bind_to':True ,'can_create':True },
    ]
    return {'ok':True ,'config':{'login_types':_login_types ,'type':'android','age_gate_consent_required':bool (SETTINGS .get ('age_gate_consent_required',True )),'gdpr_consent_required':bool (SETTINGS .get ('gdpr_consent_required',False ))},'geo':str (SETTINGS .get ('geo','US')),'gag':int (SETTINGS .get ('gag',13 ))}

def token_response_exact (account ,ttl =None ):
    _user_game_id =account .get ('user_game_id')or account .get ('username','Nextstars')
    _access_token =token (account .get ('username',''),_user_game_id ,'email',account_id (account .get ('user_id'),1 ),SETTINGS .get ('game_id','msm'),ttl )
    return {'ok':True ,'user_game_id':[_user_game_id ],'login_types':['email'],'access_token':_access_token ,'token_type':'bearer','expires_at':round (time .time ())+int (ttl or SETTINGS .get ('auth_ttl',1200 )),'device_updated':True }

def short_id (length =10 ):

    _alphabet ='abcdefghijklmnopqrstuvwxyz0123456789'
    return ''.join (secrets .choice (_alphabet )for _ in range (length ))

def email_account_response_exact (username ,password ,account_id_value ,user_game_id_value ,ttl =None ):
    _now =round (time .time ())
    _access_token =token (username ,user_game_id_value ,'email',account_id (account_id_value ,1 ),SETTINGS .get ('game_id','msm'),ttl )
    return {'ok':True ,'username':username ,'password':password ,'account_id':account_id_value ,'user_game_id':user_game_id_value ,'login_type':'email','time_created':_now ,'access_token':_access_token ,'token_type':'bearer','expires_at':_now +int (ttl or SETTINGS .get ('auth_ttl',1200 )),'device_updated':True }

def account_entry (account ):
    return {'type':'email','username':account ['username'],'userName':account ['username'],'email':account ['email'],'can_bind_to':True ,'can_create':True ,'auto_create':False }

@app .api_route ('/',methods =['GET','POST'])
async def index ():
    return ok ({'status':'running'})

async def purchase_order (request :Request ):
    return ok ({'processed_order':False })

async def purchase_dlc (request :Request ):
    return ok ({'processed_dlc':False })

async def auth_handler (request :Request ):
    try :
        _d =await params (request )
        logger .info ('auth_handler path=%s params=%s',request .scope .get ('path'),sorted (_d .keys ()))
        _g =_d .get ('g')or '27'
        try :
            _h =json .loads (_d .get ('l')or '[]')
        except Exception :
            _h =[]
        _e =_h [0 ]if _h else {}
        _i =_e .get ('t','steam')
        _o =_d .get ('username')or _d .get ('u')
        _k =_d .get ('password')or _d .get ('p')
        _b ,_login_err =resolve_login_account (_o ,_k )
        if _login_err is not None :
            return JSONResponse (_login_err ,status_code =200 )
        msm_playerdata .set_client_lang (_b .get ('username'),_d .get ('lang'))
        _c =token_response_exact (_b ,SETTINGS .get ('auth_ttl',1200 ))
        _l =JSONResponse (_c )
        _l .headers ['authorization']=f'Bearer {_c ["access_token"]}'
        _l .headers ['content-type']='application/json; charset=utf-8'
        return _l
    except Exception as _f :
        logger .exception ('auth failed: %s',_f )
        return error (AuthCode .GENERAL_ERROR )

async def login_handler (request :Request ):
    try :
        _d =await params (request )
        logger .info ('login_handler path=%s params=%s',request .scope .get ('path'),sorted (_d .keys ()))
        _l =str (_d .get ('username','')).strip ()
        _h =str (_d .get ('password','')).strip ()
        _b ,_login_err =resolve_login_account (_l ,_h )
        if _login_err is not None :
            return JSONResponse (_login_err ,status_code =200 )
        msm_playerdata .set_client_lang (_b .get ('username'),_d .get ('lang'))
        _c =token_response_exact (_b ,SETTINGS .get ('login_ttl',7200 ))
        _i =JSONResponse (_c )
        _i .headers ['authorization']=f'Bearer {_c ["access_token"]}'
        _i .headers ['content-type']='application/json; charset=utf-8'
        return _i
    except Exception as _e :
        logger .exception ('login failed: %s',_e )
        return error (AuthCode .GENERAL_ERROR )

async def email_account_handler (request :Request ):

    try :
        _d =await params (request )
        logger .info ('email_account_handler path=%s params=%s',request .scope .get ('path'),sorted (_d .keys ()))
        _username =str (_d .get ('username')or _d .get ('email')or _d .get ('u')or '').strip ()
        _password =str (_d .get ('password')or _d .get ('p')or '').strip ()
        if not _username or not _password :
            return JSONResponse (error (AuthCode .MISSING_DATA ),status_code =400 )
        if '@'in _username and not re .match (r'^[^@\s]+@[^@\s]+\.[^@\s]+$',_username ):
            return JSONResponse (error (AuthCode .INVALID_EMAIL ),status_code =400 )
        if find_account (_username ,_password )or any ((str (_a .get ('username',''))==_username for _a in load_accounts ())):
            return JSONResponse (error (AuthCode .ACCOUNT_EXISTS ),status_code =409 )
        _account ={'username':_username ,'email':_username ,'password':_password ,'user_id':short_id (),'user_game_id':short_id ()}
        _accounts =load_accounts ()
        _accounts .append (_account )
        save_json (ACCOUNTS_PATH ,_accounts )
        _c =email_account_response_exact (_username ,_password ,_account ['user_id'],_account ['user_game_id'],SETTINGS .get ('auth_ttl',1200 ))
        _r =JSONResponse (_c )
        _r .headers ['authorization']=f'Bearer {_c ["access_token"]}'
        _r .headers ['content-type']='application/json; charset=utf-8'
        return _r
    except Exception as _e :
        logger .exception ('email_account_handler failed: %s',_e )
        return JSONResponse (error (AuthCode .GENERAL_ERROR ),status_code =500 )

async def existing_accounts (request :Request ):
    _c =await params (request )
    try :
        _d =json .loads (_c .get ('l')or '[]')
    except Exception :
        _d =[]
    logger .info ('existing_accounts params=%s requested_logins=%s',dict (_c ),_d )
    _matches =[]
    for _login in _d :
        _u =str (_login .get ('u')or '').strip ()
        _p =str (_login .get ('p')or '').strip ()
        _account =find_account (_u ,_p )if _u else None
        if _account is not None :
            _matches .append (account_entry (_account ))
    return {'ok':True ,'accounts':_matches }

async def find_account_handler (request :Request ):
    _b =await params (request )
    logger .info ('find_account path=%s params=%s',request .scope .get ('path'),sorted (_b .keys ()))
    return JSONResponse ({'ok':True })

async def waf_handler (request :Request ):
    _a =await request .body ()
    logger .info ('waf path=%s method=%s query=%s body=%r',request .scope .get ('path'),request .method ,str (request .url .query ),_a [:500 ])
    return JSONResponse ({
    'ok':True ,
    'success':True ,
    'status':'ok',
    'challenge':{'type':'none','required':False },
    'challengeRequired':False ,
    'captcha':False ,
    'token':ACCESS_TOKEN_FALLBACK ,
    'aws-waf-token':ACCESS_TOKEN_FALLBACK ,
    'wafToken':ACCESS_TOKEN_FALLBACK ,
    })

_NPS_SERVER_CONFIG_PATH =Path ('/storage/emulated/0/Android/data/com.nextstars.nps/files/nps_server.properties')

async def nps_server_config (request :Request ):
    for path in (BASE_DIR /'nps_server.properties',_NPS_SERVER_CONFIG_PATH ):
        try :
            body =path .read_text (encoding ='utf-8')
        except OSError :
            continue
        if 'BBB_AUTH_SERVER='in body and 'BBB_AUTH2_SERVER='in body :
            return Response (body ,media_type ='text/plain')
    return Response ('Server configuration is not ready',status_code =503 ,media_type ='text/plain')

async def game_config (request :Request ):
    _b =await params (request )
    logger .info ('game_config path=%s params=%s',request .scope .get ('path'),sorted (_b .keys ()))
    return game_config_response_exact ()

@app .api_route ('/pregame_setup.php',methods =['GET','POST'])
async def pregame_setup (request :Request ):
    _c =await params (request )
    logger .info ('pregame_setup params=%s',sorted (_c .keys ()))
    return pregame_response_exact ()

def _download_manifest_path ():
    return FILES_DIR /'downloads.xml'

def _download_entries ():
    path =_download_manifest_path ()
    if not path .is_file ():
        return []
    try :
        root =ET .parse (path ).getroot ()
    except Exception :
        logger .exception ('failed to parse bundled downloads.xml')
        return []
    entries =[]
    for node in root .findall ('.//Download'):
        file_name =(node .get ('file')or '').replace ('\\','/').lstrip ('/')
        if not file_name :
            continue
        local_path =(FILES_DIR /file_name ).resolve ()
        try :
            local_path .relative_to (FILES_DIR .resolve ())
        except Exception :
            continue
        if not local_path .is_file ():
            logger .warning ('downloads.xml announces missing asset: %s',file_name )
            continue
        checksum =hashlib .md5 (local_path .read_bytes ()).hexdigest ()
        entries .append ({
        'localName':file_name ,
        'serverName':file_name ,
        'checksum':checksum ,
        })
    return entries

CLIENT_VERSION ='5.7.1'
CLIENT_BUILD ='508'

def _build_downloads_xml (entries ):
    _major ,_minor ,_micro =(CLIENT_VERSION .split ('.')+['0','0'])[:3 ]
    lines =['<?xml version="1.0"?>',f'<Downloads version="{CLIENT_VERSION }" build="{CLIENT_BUILD }">']
    for entry in entries :
        name =(
        str (entry .get ('serverName')or '')
        .replace ('&','&amp;')
        .replace ('"','&quot;')
        .replace ('<','&lt;')
        .replace ('>','&gt;')
        )
        if not name :
            continue
        lines .append (f'    <Download file="{name }" checksum="{entry ["checksum"]}" major="{_major }" minor="{_minor }" micro="{_micro }" rev="0" />')
    lines .append ('</Downloads>')
    return '\n'.join (lines ).encode ('utf-8')

def manifest ():
    return _download_entries ()

async def files_manifest (request :Request ):
    _a =await params (request )
    entries =manifest ()
    logger .info ('files_manifest path=%s params=%s entries=%d',request .scope .get ('path'),sorted (_a .keys ()),len (entries ))
    raw =json .dumps (entries ,separators =(',',':'),ensure_ascii =False ).encode ('utf-8')
    return Response (raw ,media_type ='application/json')

async def downloads_xml (request :Request ):
    entries =manifest ()
    logger .info ('downloads_xml path=%s entries=%d',request .scope .get ('path'),len (entries ))
    return Response (_build_downloads_xml (entries ),media_type ='application/xml')

async def serve_file (path :str ):
    _a =(FILES_DIR /path ).resolve ()
    try :
        _a .relative_to (FILES_DIR .resolve ())
    except Exception :
        return JSONResponse ({'ok':False ,'error':'bad path'},status_code =400 )
    if not _a .is_file ():
        return JSONResponse ({'ok':False ,'error':'not found'},status_code =404 )
    return FileResponse (_a )

async def catch_all (path :str ,request :Request ):
    _a =await request .body ()
    logger .info ('catch_all path=%s method=%s query=%s body=%r',path ,request .method ,str (request .url .query ),_a [:2000 ])
    return error (AuthCode .GENERAL_ERROR ,message =f'not implemented: {path }')

async def bluebox (request :Request ):
    logger .info ('bluebox probe path=%s method=%s',request .scope .get ('path'),request .method )
    return Response ('<msg t="sys"><body action="apiOK" r="0"><ver v="2.13.0"/></body></msg>\x00',media_type ='text/xml')

async def sfs_websocket (websocket :WebSocket ):
    await websocket .accept ()
    try :
        while True :
            _a =await websocket .receive ()
            _d =_a .get ('bytes')
            if _d is None :
                continue
            try :
                _frame =msm_protocol .parse_raw_frame (_d )
            except Exception as _err :
                logger .info ('bad frame: %s',_err )
                continue
            if _frame is None or _frame .command =='alive':
                continue
            logger .info ('IN %s params=%.500r',_frame .command ,_frame .params )
            try :
                _results =msm_handlers .handle_command (_frame .command ,_frame .params )
            except Exception as _err :
                logger .exception ('%s failed',_frame .command )
                _results =[(_frame .command ,{'success':False ,'error':str (_err ),'notificationOnFail':False })]
            for _resp_cmd ,_resp_payload in _results :
                await websocket .send_bytes (msm_protocol .build_raw_frame (_resp_cmd ,_resp_payload ))
                logger .info ('%s -> %s payload=%.800r',_frame .command ,_resp_cmd ,_resp_payload )
            if _frame .command =='USER_LOGIN':
                for _boot_cmd ,_boot_payload in msm_handlers .login_bootstrap_frames ():
                    await websocket .send_bytes (msm_protocol .build_raw_frame (_boot_cmd ,_boot_payload ))
                    logger .info ('login -> %s',_boot_cmd )
    except WebSocketDisconnect :
        pass
    except Exception as _f :
        logger .exception ('websocket stopped: %s',_f )

for route in ['/purchases/steam/my_singing_monsters/ProcessInitializedPurchases.php']:
    app .add_api_route (route ,purchase_order ,methods =['POST'])
for route in ['/purchases/steam/my_singing_monsters/ProcessDLCPurchases.php']:
    app .add_api_route (route ,purchase_dlc ,methods =['POST'])
for route in ['/auth/api/token','/auth/api/token/','/auth/api/anon_account','/auth/api/anon_account/','/auth/api/steam_account','/auth/api/steam_account/','//auth/api/token','//auth/api/token/','//auth/api/anon_account','//auth/api/anon_account/','//auth/api/steam_account','//auth/api/steam_account/']:
    app .add_api_route (route ,auth_handler ,methods =['GET','POST'])
for route in ['/auth/api/login','/auth/api/login/']:
    app .add_api_route (route ,login_handler ,methods =['POST'])
for route in ['/auth/api/existing_accounts','/auth/api/existing_accounts/']:
    app .add_api_route (route ,existing_accounts ,methods =['POST'])
for route in ['/auth/api/find_account','/auth/api/find_account/','//auth/api/find_account','//auth/api/find_account/']:
    app .add_api_route (route ,find_account_handler ,methods =['GET','POST'])
for route in ['/auth/api/game_config','/auth/api/game_config/']:
    app .add_api_route (route ,game_config ,methods =['GET','POST'])
for route in ['/waf','/waf/','/waf/{path:path}','/challenge','/challenge/','/token','/token/']:
    app .add_api_route (route ,waf_handler ,methods =['GET','POST','PUT'])
app .add_api_route (f'/{FILES_DIR .name }/files.json',files_manifest ,methods =['GET','POST'])
app .add_api_route (f'/{FILES_DIR .name }/downloads.xml',downloads_xml ,methods =['GET','POST'])
app .add_api_route (f'/{FILES_DIR .name }/{{path:path}}',serve_file ,methods =['GET'])
app .add_api_route (PUBLIC_CONTENT_PREFIX .rstrip ('/'),files_manifest ,methods =['GET','POST'])
app .add_api_route (PUBLIC_CONTENT_PREFIX ,files_manifest ,methods =['GET','POST'])
app .add_api_route (f'{PUBLIC_CONTENT_PREFIX }files.json',files_manifest ,methods =['GET','POST'])
app .add_api_route (f'{PUBLIC_CONTENT_PREFIX }downloads.xml',downloads_xml ,methods =['GET','POST'])
app .add_api_route ('/content/files.json',files_manifest ,methods =['GET','POST'])
app .add_api_route ('/content/downloads.xml',downloads_xml ,methods =['GET','POST'])
app .add_api_route (f'{PUBLIC_CONTENT_PREFIX }{{path:path}}',serve_file ,methods =['GET'])
app .add_api_route ('/nps_server_config',nps_server_config ,methods =['GET'])
app .add_api_route ('/BlueBox/BlueBox.do',bluebox ,methods =['GET','POST'])
app .add_api_route ('/msm/socket',bluebox ,methods =['GET','POST'])
app .add_api_websocket_route ('/BlueBox/BlueBox.do',sfs_websocket )
app .add_api_websocket_route ('/msm/socket',sfs_websocket )
app .add_api_websocket_route ('/websocket',sfs_websocket )
for route in ['/auth/api/email_account','/auth/api/email_account/']:
    app .add_api_route (route ,email_account_handler ,methods =['GET','POST'])

app .add_api_route ('/{path:path}',catch_all ,methods =['GET','POST','PUT','DELETE'])

async def _serve_with_retry (host ,port ,log_level ,max_attempts =10 ,delay =1.0 ):

    last_exc =None
    for attempt in range (1 ,max_attempts +1 ):
        config =uvicorn .Config (app ,host =host ,port =port ,log_level =log_level )
        server =uvicorn .Server (config )
        _UVICORN_SERVERS .append (server )
        try :
            await server .serve ()
            if server .started :
                return
            last_exc =OSError (f'port {port } failed to bind')
        except asyncio .CancelledError :
            return
        except (OSError ,SystemExit )as e :
            last_exc =e
        finally :
            if server in _UVICORN_SERVERS :
                _UVICORN_SERVERS .remove (server )
        if _SHUTDOWN_REQUESTED or attempt >=max_attempts :
            raise last_exc
        logger .warning ('port %s bind failed (attempt %s/%s): %s; retrying',port ,attempt ,max_attempts ,last_exc )
        await asyncio .sleep (delay )
    if last_exc :
        raise last_exc

async def main ():
    global _SHUTDOWN_REQUESTED
    _SHUTDOWN_REQUESTED =False
    _SHUTDOWN_COMPLETE .clear ()

    SETTINGS .clear ()
    SETTINGS .update (config ())

    import msm_toggles
    logger .info ('Runtime ready: base=%s, players=%s, functioning_currencies=%s',
    BASE_DIR ,msm_store .players_dir ,msm_toggles .is_enabled ('functioning_currencies'))

    msm_store .clear_db_cache ()
    msm_gamedata .reset_caches ()
    mod_api .load_mods (str (MODS_DIR ))
    _tasks =[]
    _UVICORN_SERVERS .clear ()
    host =str (SETTINGS .get ('host','127.0.0.1'))
    log_level =str (SETTINGS .get ('log_level','info')).lower ()
    for _b in SETTINGS .get ('http_ports')or [80 ]:
        _tasks .append (_serve_with_retry (host ,int (_b ),log_level ))
    watchdog =asyncio .ensure_future (_force_exit_watchdog ())
    try :

        results =await asyncio .gather (*_tasks ,return_exceptions =True )
        for _r in results :
            if isinstance (_r ,BaseException )and not isinstance (_r ,asyncio .CancelledError ):
                logger .error ('bridge server task failed permanently: %s',_r )
    finally :
        watchdog .cancel ()
        _UVICORN_SERVERS .clear ()
        _SHUTDOWN_COMPLETE .set ()
if __name__ =='__main__':
    asyncio .run (main ())
