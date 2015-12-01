# This file is a part of Julia. License is MIT: http://julialang.org/license

# Conversion/Promotion
Date(dt::TimeType) = convert(Date,dt)
DateTime(dt::TimeType) = convert(DateTime,dt)
Base.convert(::Type{DateTime},dt::Date) = DateTime(UTM(value(dt)*86400000))
Base.convert(::Type{Date},dt::DateTime) = Date(UTD(days(dt)))
Base.convert{R<:Real}(::Type{R},x::DateTime) = convert(R,value(x))
Base.convert{R<:Real}(::Type{R},x::Date)     = convert(R,value(x))

@vectorize_1arg DateTime Date
@vectorize_1arg Date DateTime

### External Conversions
const UNIXEPOCH = value(DateTime(1970)) #Rata Die milliseconds for 1970-01-01T00:00:00
function unix2datetime(x)
    rata = UNIXEPOCH + round(Int64, Int64(1000) * x)
    return DateTime(UTM(rata))
end
# Returns unix seconds since 1970-01-01T00:00:00
datetime2unix(dt::DateTime) = (value(dt) - UNIXEPOCH)/1000.0

const _tzoffset = Ref(0)

doc"""
    Dates.settzoffset() -> Int

Call this function after updating your system's timezone to ensure that ``tzoffset()`` returns correct results
"""
function settzoffset()
    t = floor(time())
    tm = Libc.TmStruct(t)
    dtutc = unix2datetime(t)
    dtlocal = DateTime(tm.year+1900,tm.month+1,tm.mday,tm.hour,tm.min,tm.sec)
    _tzoffset[] = Second(dtlocal - dtutc).value
end

doc"""
    Dates.tzoffset() -> Int

Returns the number of seconds the user's system timezone is ahead of UTC/GMT. Will be negative for system timezones of the prime meridian, positive if east. Note: after changing the system timezone, ``settzoffset()`` needs to be called once to ensure the result of this function reflects the system's timezone.
"""
tzoffset() = _tzoffset[]

function now()
    t = time() + _tzoffset[]
    return unix2datetime(t)
end

today() = Date(now())
now(::Type{UTC}) = unix2datetime(time())

rata2datetime(days) = DateTime(yearmonthday(days)...)
datetime2rata(dt::DateTime) = days(dt)

# Julian conversions
const JULIANEPOCH = value(DateTime(-4713,11,24,12))
function julian2datetime(f)
    rata = JULIANEPOCH + round(Int64, Int64(86400000) * f)
    return DateTime(UTM(rata))
end
# Returns # of julian days since -4713-11-24T12:00:00
datetime2julian(dt::DateTime) = (value(dt) - JULIANEPOCH)/86400000.0

@vectorize_1arg Real unix2datetime
@vectorize_1arg DateTime datetime2unix
@vectorize_1arg Real rata2datetime
@vectorize_1arg DateTime datetime2rata
@vectorize_1arg Real julian2datetime
@vectorize_1arg DateTime datetime2julian
