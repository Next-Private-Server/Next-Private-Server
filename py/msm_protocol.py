import struct

SFS_TYPE_NULL =0
SFS_TYPE_BOOL =1
SFS_TYPE_BYTE =2
SFS_TYPE_SHORT =3
SFS_TYPE_INT =4
SFS_TYPE_LONG =5
SFS_TYPE_FLOAT =6
SFS_TYPE_DOUBLE =7
SFS_TYPE_UTF_STRING =8
SFS_TYPE_BOOL_ARRAY =9
SFS_TYPE_BYTE_ARRAY =10
SFS_TYPE_SHORT_ARRAY =11
SFS_TYPE_INT_ARRAY =12
SFS_TYPE_LONG_ARRAY =13
SFS_TYPE_FLOAT_ARRAY =14
SFS_TYPE_DOUBLE_ARRAY =15
SFS_TYPE_UTF_STRING_ARRAY =16
SFS_TYPE_SFS_ARRAY =17
SFS_TYPE_SFS_OBJECT =18
SFS_TYPE_CLASS =19
SFS_TYPE_TEXT =20

class SFSByte (int ):
    pass

class SFSShort (int ):
    pass

class SFSLong (int ):
    pass

class SFSFloat (float ):
    pass

class SFSBoolArray (list ):
    pass

class SFSByteArray (list ):
    pass

class SFSShortArray (list ):
    pass

class SFSIntArray (list ):
    pass

class SFSLongArray (list ):
    pass

class SFSFloatArray (list ):
    pass

class SFSDoubleArray (list ):
    pass

class SFSUtfStringArray (list ):
    pass

def _normalize_wire_value (value ):

    if isinstance (value ,dict )and len (value )==1 :
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
    return value

def _infer_type (value ):
    if value is None :
        return SFS_TYPE_NULL
    if isinstance (value ,bool ):
        return SFS_TYPE_BOOL
    if isinstance (value ,SFSByte ):
        return SFS_TYPE_BYTE
    if isinstance (value ,SFSShort ):
        return SFS_TYPE_SHORT
    if isinstance (value ,SFSLong ):
        return SFS_TYPE_LONG
    if isinstance (value ,SFSFloat ):
        return SFS_TYPE_FLOAT
    if isinstance (value ,int ):
        if -2147483648 <=value <=2147483647 :
            return SFS_TYPE_INT
        return SFS_TYPE_LONG
    if isinstance (value ,float ):
        return SFS_TYPE_DOUBLE
    if isinstance (value ,str ):
        return SFS_TYPE_UTF_STRING if len (value .encode ("utf-8"))<=65535 else SFS_TYPE_TEXT
    if isinstance (value ,SFSBoolArray ):
        return SFS_TYPE_BOOL_ARRAY
    if isinstance (value ,SFSByteArray ):
        return SFS_TYPE_BYTE_ARRAY
    if isinstance (value ,SFSShortArray ):
        return SFS_TYPE_SHORT_ARRAY
    if isinstance (value ,SFSIntArray ):
        return SFS_TYPE_INT_ARRAY
    if isinstance (value ,SFSLongArray ):
        return SFS_TYPE_LONG_ARRAY
    if isinstance (value ,SFSFloatArray ):
        return SFS_TYPE_FLOAT_ARRAY
    if isinstance (value ,SFSDoubleArray ):
        return SFS_TYPE_DOUBLE_ARRAY
    if isinstance (value ,SFSUtfStringArray ):
        return SFS_TYPE_UTF_STRING_ARRAY
    if isinstance (value ,dict ):
        return SFS_TYPE_SFS_OBJECT
    if isinstance (value ,(list ,tuple )):
        return SFS_TYPE_SFS_ARRAY
    raise TypeError (f"Cannot infer SFSDataType for {type(value)!r}")

def _encode_utf (value ):
    if not isinstance (value ,str ):
        value =str (value )
    data =value .encode ("utf-8")
    if len (data )>65535 :
        raise ValueError (f"SFS UTF string is too long: {len (data )} bytes")
    return struct .pack (">H",len (data ))+data

def _encode_value (sfs_type ,value ):
    if sfs_type ==SFS_TYPE_NULL :
        return b""
    if sfs_type ==SFS_TYPE_BOOL :
        return struct .pack (">B",1 if value else 0 )
    if sfs_type ==SFS_TYPE_BYTE :
        return struct .pack (">b",int (value ))
    if sfs_type ==SFS_TYPE_SHORT :
        return struct .pack (">h",int (value ))
    if sfs_type ==SFS_TYPE_INT :
        return struct .pack (">i",int (value ))
    if sfs_type ==SFS_TYPE_LONG :
        return struct .pack (">q",int (value ))
    if sfs_type ==SFS_TYPE_FLOAT :
        return struct .pack (">f",float (value ))
    if sfs_type ==SFS_TYPE_DOUBLE :
        return struct .pack (">d",float (value ))
    if sfs_type ==SFS_TYPE_UTF_STRING :
        return _encode_utf (value )
    if sfs_type ==SFS_TYPE_TEXT :
        data =value .encode ("utf-8")
        return struct .pack (">i",len (data ))+data
    if sfs_type ==SFS_TYPE_BOOL_ARRAY :
        out =struct .pack (">H",len (value ))
        for v in value :
            out +=struct .pack (">B",1 if v else 0 )
        return out
    if sfs_type ==SFS_TYPE_BYTE_ARRAY :
        return struct .pack (">i",len (value ))+bytes (int (v )&0xFF for v in value )
    if sfs_type ==SFS_TYPE_SHORT_ARRAY :
        out =struct .pack (">H",len (value ))
        for v in value :
            out +=struct .pack (">h",int (v ))
        return out
    if sfs_type ==SFS_TYPE_INT_ARRAY :
        out =struct .pack (">H",len (value ))
        for v in value :
            out +=struct .pack (">i",int (v ))
        return out
    if sfs_type ==SFS_TYPE_LONG_ARRAY :
        out =struct .pack (">H",len (value ))
        for v in value :
            out +=struct .pack (">q",int (v ))
        return out
    if sfs_type ==SFS_TYPE_FLOAT_ARRAY :
        out =struct .pack (">H",len (value ))
        for v in value :
            out +=struct .pack (">f",float (v ))
        return out
    if sfs_type ==SFS_TYPE_DOUBLE_ARRAY :
        out =struct .pack (">H",len (value ))
        for v in value :
            out +=struct .pack (">d",float (v ))
        return out
    if sfs_type ==SFS_TYPE_UTF_STRING_ARRAY :
        out =struct .pack (">H",len (value ))
        for v in value :
            out +=_encode_utf (v )
        return out
    if sfs_type ==SFS_TYPE_SFS_ARRAY :
        out =struct .pack (">H",len (value ))
        for v in value :
            v =_normalize_wire_value (v )
            element_type =_infer_type (v )
            out +=struct .pack (">B",element_type )+_encode_value (element_type ,v )
        return out
    if sfs_type ==SFS_TYPE_SFS_OBJECT :
        return _encode_object_body (value )
    raise TypeError (f"Unsupported SFSDataType id {sfs_type }")

def _encode_object_body (data ):
    body =b""
    for key ,value in data .items ():
        value =_normalize_wire_value (value )
        sfs_type =_infer_type (value )
        body +=_encode_utf (key )+struct .pack (">B",sfs_type )+_encode_value (sfs_type ,value )
    return struct .pack (">H",len (data ))+body

def encode_sfsobject (data ):
    return struct .pack (">B",SFS_TYPE_SFS_OBJECT )+_encode_object_body (data )

class _Reader :
    __slots__ =("data","pos")

    def __init__ (self ,data ,pos =0 ):
        self .data =data
        self .pos =pos

    def read (self ,n ):
        chunk =self .data [self .pos :self .pos +n ]
        if len (chunk )!=n :
            raise ValueError (f"expected {n } bytes at offset {self .pos }, got {len (chunk )}")
        self .pos +=n
        return chunk

    def read_u8 (self ):
        return self .read (1 )[0 ]

    def read_u16 (self ):
        return struct .unpack (">H",self .read (2 ))[0 ]

    def read_i32 (self ):
        return struct .unpack (">i",self .read (4 ))[0 ]

    def read_utf (self ):
        return self .read (self .read_u16 ()).decode ("utf-8")

def _decode_value (reader ,sfs_type ):
    if sfs_type ==SFS_TYPE_NULL :
        return None
    if sfs_type ==SFS_TYPE_BOOL :
        return reader .read_u8 ()!=0
    if sfs_type ==SFS_TYPE_BYTE :
        return struct .unpack (">b",reader .read (1 ))[0 ]
    if sfs_type ==SFS_TYPE_SHORT :
        return struct .unpack (">h",reader .read (2 ))[0 ]
    if sfs_type ==SFS_TYPE_INT :
        return struct .unpack (">i",reader .read (4 ))[0 ]
    if sfs_type ==SFS_TYPE_LONG :
        return struct .unpack (">q",reader .read (8 ))[0 ]
    if sfs_type ==SFS_TYPE_FLOAT :
        return struct .unpack (">f",reader .read (4 ))[0 ]
    if sfs_type ==SFS_TYPE_DOUBLE :
        return struct .unpack (">d",reader .read (8 ))[0 ]
    if sfs_type ==SFS_TYPE_UTF_STRING :
        return reader .read_utf ()
    if sfs_type ==SFS_TYPE_TEXT :
        return reader .read (reader .read_i32 ()).decode ("utf-8")
    if sfs_type ==SFS_TYPE_BOOL_ARRAY :
        return [reader .read_u8 ()!=0 for _ in range (reader .read_u16 ())]
    if sfs_type ==SFS_TYPE_BYTE_ARRAY :
        return list (reader .read (reader .read_i32 ()))
    if sfs_type ==SFS_TYPE_SHORT_ARRAY :
        return [struct .unpack (">h",reader .read (2 ))[0 ]for _ in range (reader .read_u16 ())]
    if sfs_type ==SFS_TYPE_INT_ARRAY :
        return [struct .unpack (">i",reader .read (4 ))[0 ]for _ in range (reader .read_u16 ())]
    if sfs_type ==SFS_TYPE_LONG_ARRAY :
        return [struct .unpack (">q",reader .read (8 ))[0 ]for _ in range (reader .read_u16 ())]
    if sfs_type ==SFS_TYPE_FLOAT_ARRAY :
        return [struct .unpack (">f",reader .read (4 ))[0 ]for _ in range (reader .read_u16 ())]
    if sfs_type ==SFS_TYPE_DOUBLE_ARRAY :
        return [struct .unpack (">d",reader .read (8 ))[0 ]for _ in range (reader .read_u16 ())]
    if sfs_type ==SFS_TYPE_UTF_STRING_ARRAY :
        return [reader .read_utf ()for _ in range (reader .read_u16 ())]
    if sfs_type ==SFS_TYPE_SFS_ARRAY :
        count =reader .read_u16 ()
        out =[]
        for _ in range (count ):
            element_type =reader .read_u8 ()
            out .append (_decode_value (reader ,element_type ))
        return out
    if sfs_type ==SFS_TYPE_SFS_OBJECT :
        return _decode_object_body (reader )
    raise TypeError (f"Unsupported SFSDataType id {sfs_type }")

def _decode_object_body (reader ):
    count =reader .read_u16 ()
    out ={}
    for _ in range (count ):
        key =reader .read_utf ()
        value_type =reader .read_u8 ()
        out [key ]=_decode_value (reader ,value_type )
    return out

def decode_sfsobject (data ):
    reader =_Reader (data )
    root_type =reader .read_u8 ()
    if root_type !=SFS_TYPE_SFS_OBJECT :
        raise TypeError (f"expected root SFS_OBJECT(18), got {root_type }")
    return _decode_object_body (reader )

class ParsedFrame :
    __slots__ =("command","request_id","params")

    def __init__ (self ,command ,request_id ,params ):
        self .command =command
        self .request_id =request_id
        self .params =params

def parse_raw_frame (data ):
    if data is None or len (data )<10 or data [0 ]!=0 :
        return None
    request_id =struct .unpack (">q",data [1 :9 ])[0 ]
    command_length =data [9 ]
    if command_length <=0 or 10 +command_length >len (data ):
        return None
    command =data [10 :10 +command_length ].decode ("ascii",errors ="replace")
    payload_bytes =data [10 +command_length :]
    if command =="alive"and len (payload_bytes )==0 :
        return ParsedFrame (command ,request_id ,{})
    params =decode_sfsobject (payload_bytes )if payload_bytes else {}
    if isinstance (params ,dict )and isinstance (params .get ("data"),dict ):
        params =params ["data"]
    return ParsedFrame (command ,request_id ,params )

def build_raw_frame (command ,payload ):
    command_bytes =command .encode ("ascii")
    payload_bytes =encode_sfsobject (payload or {})
    return struct .pack (">H",len (command_bytes ))+command_bytes +payload_bytes
