.ifndef ROSMSG_INCLUDED
.define ROSMSG_INCLUDED

.ifndef ROSMSG_DEFAULT_MAXCOUNT
.define ROSMSG_DEFAULT_MAXCOUNT 8
.endif

.ifndef ROSMSG_DEFAULT_MAXLEN
.define ROSMSG_DEFAULT_MAXLEN 32
.endif

func rosmsg_int_serialize(var string[] outbuf, int offset, int value, int bytes)
    for i = 0 to bytes - 1
        str_chr_set(outbuf, offset + i, value & 0xFF)
        value >>= 8  ;; Note: in RAPL-3, this is logical shift even with signed int
    end for
    return offset + bytes
end func

func rosmsg_int_deserialize(var string[] inbuf, int offset, var int value, int bytes)
    value = str_chr_get(inbuf, offset)
    for i = 1 to bytes - 1
        value |= str_chr_get(inbuf, offset + i) << (8 * i)
    end for
    return offset + bytes
end func

func rosmsg_float32_serialize(var string[] outbuf, int offset, float value)
    union
        int ival
        float fval
    end union tmp
    tmp.fval = value
    return rosmsg_int_serialize(outbuf, offset, tmp.ival, 4)
end func

func rosmsg_float32_deserialize(var string[] inbuf, int offset, var float value)
    union
        int ival
        float fval
    end union tmp
    offset = rosmsg_int_deserialize(inbuf, offset, tmp.ival, 4)
    value = tmp.fval
    return offset
end func

func rosmsg_float64_serialize(var string[] outbuf, int offset, float value)
    union
        int ival
        float fval
    end union tmp
    tmp.fval = value
    
    int mantissa = tmp.ival & 0x7FFFFF
    int exponent = ((tmp.ival >> 23) & 0xFF) - 127
    
    if exponent == 128 then
        exponent = 1024 ;; Special values NaN, inf etc.
    else if exponent == -127 then
        if (!mantissa)
            exponent = -1023 ;; Zero
        else
            ;; Denormalized number
            mantissa <<= 1;
            while !(mantissa & 0x800000)
                mantissa <<= 1
                exponent -= 1
            end while
            mantissa &= 0x7FFFFF
        end if
    end if
    
    exponent += 1023
    
    str_chr_set(outbuf, offset + 0, 0);
    str_chr_set(outbuf, offset + 1, 0);
    str_chr_set(outbuf, offset + 2, 0);
    str_chr_set(outbuf, offset + 3, (mantissa & 0x07) << 5)
    str_chr_set(outbuf, offset + 4, (mantissa >> 3) & 0xFF)
    str_chr_set(outbuf, offset + 5, (mantissa >> 11) & 0xFF)
    str_chr_set(outbuf, offset + 6, ((mantissa >> 19) & 0x0F) | ((exponent << 4) & 0xF0))
    str_chr_set(outbuf, offset + 7, ((exponent >> 4) & 0x7F) | ((tmp.ival >> 24) & 0x80))
    
    return offset + 8
end func

func rosmsg_float64_deserialize(var string[] inbuf, int offset, var float value)
    int mantissa
    int exponent
    
    mantissa = (str_chr_get(inbuf, offset + 3) >> 4) & 0x0F
    mantissa |= str_chr_get(inbuf, offset + 4) << 4
    mantissa |= str_chr_get(inbuf, offset + 5) << 12
    mantissa |= (str_chr_get(inbuf, offset + 6) & 0x0f) << 20
    
    exponent = str_chr_get(inbuf, offset + 6) >> 4
    exponent |= (str_chr_get(inbuf, offset + 7) & 0x7F) << 4
    
    exponent -= 1023
    
    if exponent == 1024 then
        exponent = 128 ;; Special value
    else if exponent > 127 then
        exponent = 128
        mantissa = 0 ;; Too large for float, convert to inf
    else if exponent < -150 then
        exponent = 0 ;; Too small or zero
    else if exponent < -126 then
        mantissa |= 0x1000000
        mantissa >>= (-126 - exponent) ;; Convert to denormalized float
        exponent = 0
    end if
    
    if (mantissa != 0xFFFFFF)
        mantissa += 1 ;; Rounding
    
    mantissa >>= 1
    
    ;; Put mantissa and exponent into place
    union
        int ival
        float fval
    end union tmp
    tmp.ival = mantissa
    tmp.ival |= exponent << 23
    
    ;; Copy sign bit
    tmp.ival |= (str_chr_get(inbuf, offset + 7) & 0x80) << 24
    
    return offset + 8
end func

func rosmsg_string_serialize(var string[] outbuf, int offset, string[] value)
    int len = strlen(value)
    offset = rosmsg_int_serialize(outbuf, offset, len, 4)
    str_edit(outbuf, value, offset, len)
    return offset + len
end func

func rosmsg_string_deserialize(var string[] inbuf, int offset, var string[] value)
    int len
    offset = rosmsg_int_deserialize(inbuf, offset, len, 4)
    if len > str_limit(value) then
        len = str_limit(value)
    end if
    str_substr(value, inbuf, offset, len)
    return offset + len
end func

typedef rosmsg_ros_time struct
    int secs
    int nsecs
end struct

func rosmsg_ros_time_serialize(var string[] outbuf, int offset, var rosmsg_ros_time msg)
  offset = rosmsg_int_serialize(outbuf, offset, msg.secs, 4);
  offset = rosmsg_int_serialize(outbuf, offset, msg.nsecs, 4);
  return offset;
end func

func rosmsg_ros_time_deserialize(var string[] inbuf, int offset, var rosmsg_ros_time msg)
  offset = rosmsg_int_deserialize(inbuf, offset, msg.secs, 4);
  offset = rosmsg_int_deserialize(inbuf, offset, msg.nsecs, 4);
  return offset;
end func

typedef rosmsg_ros_duration struct
    int secs
    int nsecs
end struct

func rosmsg_ros_duration_serialize(var string[] outbuf, int offset, var rosmsg_ros_duration msg)
  offset = rosmsg_int_serialize(outbuf, offset, msg.secs, 4);
  offset = rosmsg_int_serialize(outbuf, offset, msg.nsecs, 4);
  return offset;
end func

func rosmsg_ros_duration_deserialize(var string[] inbuf, int offset, var rosmsg_ros_duration msg)
  offset = rosmsg_int_deserialize(inbuf, offset, msg.secs, 4);
  offset = rosmsg_int_deserialize(inbuf, offset, msg.nsecs, 4);
  return offset;
end func


.endif
