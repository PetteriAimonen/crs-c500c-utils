.ifndef ROSMSG_INCLUDED
.define ROSMSG_INCLUDED

func int rosmsg_write_uint16(var string[] outbuf, int offset, int value)
    str_chr_set(outbuf, offset, value & 0xFF)
    str_chr_set(outbuf, offset + 1, (value >> 8) & 0xFF)
    return offset + 2
end func

func int rosmsg_read_uint16(var string[] inbuf, int offset, var int value)
    value  = str_chr_get(inbuf, offset)
    value |= str_chr_get(inbuf, offset + 1) << 8
    return offset + 2
end func

func int rosmsg_write_int32(var string[] outbuf, int offset, int value)
    str_chr_set(outbuf, offset, value & 0xFF)
    str_chr_set(outbuf, offset + 1, (value >> 8) & 0xFF)
    str_chr_set(outbuf, offset + 2, (value >> 16) & 0xFF)
    str_chr_set(outbuf, offset + 3, (value >> 24) & 0xFF)
    return offset + 4
end func

func int rosmsg_read_int32(var string[] inbuf, int offset, var int value)
    value  = str_chr_get(inbuf, offset)
    value |= str_chr_get(inbuf, offset + 1) << 8
    value |= str_chr_get(inbuf, offset + 2) << 16
    value |= str_chr_get(inbuf, offset + 3) << 24
    return offset + 4
end func

func int rosmsg_write_float32(var string[] outbuf, int offset, float value)
    union
        int ival
        float fval
    end union tmp
    tmp.fval = value
    return rosmsg_write_int32(outbuf, offset, tmp.ival)
end func

func int rosmsg_read_float32(var string[] inbuf, int offset, var float value)
    union
        int ival
        float fval
    end union tmp
    offset = rosmsg_read_int32(inbuf, offset, tmp.ival)
    value = tmp.fval
    return offset
end func

func int rosmsg_write_float64(var string[] outbuf, int offset, float value)
    union
        int ival
        float fval
    end union tmp
    tmp.fval = value
    
    int mantissa, exponent
    mantissa = tmp.ival & 0x7FFFFF
    exponent = ((tmp.ival >> 23) & 0xFF) - 127
    
    if exponent == 128 then
        exponent = 1024 ;; Special values NaN, inf etc.
    elseif exponent == -127 then
        if (!mantissa)
            exponent = -1023 ;; Zero
        else
            ;; Denormalized number
            mantissa <<= 1
            while !(mantissa & 0x800000)
                mantissa <<= 1
                exponent -= 1
            end while
            mantissa &= 0x7FFFFF
        end if
    end if
    
    exponent += 1023
    
    str_chr_set(outbuf, offset + 0, 0)
    str_chr_set(outbuf, offset + 1, 0)
    str_chr_set(outbuf, offset + 2, 0)
    str_chr_set(outbuf, offset + 3, (mantissa & 0x07) << 5)
    str_chr_set(outbuf, offset + 4, (mantissa >> 3) & 0xFF)
    str_chr_set(outbuf, offset + 5, (mantissa >> 11) & 0xFF)
    str_chr_set(outbuf, offset + 6, ((mantissa >> 19) & 0x0F) | ((exponent << 4) & 0xF0))
    str_chr_set(outbuf, offset + 7, ((exponent >> 4) & 0x7F) | ((tmp.ival >> 24) & 0x80))
    
    return offset + 8
end func

func int rosmsg_read_float64(var string[] inbuf, int offset, var float value)
    int mantissa, exponent
    
    mantissa = (str_chr_get(inbuf, offset + 3) >> 4) & 0x0F
    mantissa |= str_chr_get(inbuf, offset + 4) << 4
    mantissa |= str_chr_get(inbuf, offset + 5) << 12
    mantissa |= (str_chr_get(inbuf, offset + 6) & 0x0f) << 20
    
    exponent = str_chr_get(inbuf, offset + 6) >> 4
    exponent |= (str_chr_get(inbuf, offset + 7) & 0x7F) << 4
    
    exponent -= 1023
    
    if exponent == 1024 then
        exponent = 128 ;; Special value
    elseif exponent > 127 then
        exponent = 128
        mantissa = 0 ;; Too large for float, convert to inf
    elseif exponent < -150 then
        exponent = 0 ;; Too small or zero
    elseif exponent < -126 then
        mantissa |= 0x1000000
        mantissa >>= (-126 - exponent) ;; Convert to denormalized float
        exponent = 0
    end if
    
    if mantissa != 0xFFFFFF then
        mantissa += 1 ;; Rounding
    end if
    
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

func int rosmsg_write_string(var string[] outbuf, int offset, string[] value)
    int len
    len = str_len(value)
    offset = rosmsg_write_int32(outbuf, offset, len)
    str_edit(outbuf, value, offset, len)
    return offset + len
end func

func int rosmsg_read_string(var string[] inbuf, int offset, var string[] value)
    int len
    offset = rosmsg_read_int32(inbuf, offset, len)
    if len > str_limit(value) then
        len = str_limit(value)
    end if
    str_substr(value, inbuf, offset, len)
    return offset + len
end func

.endif
