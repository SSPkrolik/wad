import math
import sequtils
import streams
import strutils

type
    WadKind* {.pure.} = enum
        IWAD = (('I'.ord.int32) or ('W'.ord.int32 shl 8) or ('A'.ord.int32 shl 16) or ('D'.ord.int32 shl 24)).int32
        PWAD = (('P'.ord.int32) or ('W'.ord.int32 shl 8) or ('A'.ord.int32 shl 16) or ('D'.ord.int32 shl 24)).int32

    WadInfo* = ref object
        kind*  : WadKind
        lumps* : int32
        offset*: int32

    Lump* = ref object
        offset*: int32
        size*: int32
        name*: string

    Wad* = ref object
        header*: WadInfo
        directory*: seq[Lump]
        data*: string

proc newWad*(s: Stream): Wad =
    ## Construct WAD file from stream
    result.new
    result.header.new
    result.directory = @[]

    defer: s.close()

    result.header.kind = WadKind(s.readInt32())
    result.header.lumps = s.readInt32()
    result.header.offset = s.readInt32()

    result.data = s.readStr(result.header.offset - s.getPosition())

    for _ in 0 ..< result.header.lumps:
        let lump = new(Lump)
        lump.offset = s.readInt32()
        lump.size = s.readInt32()
        lump.name = $(s.readStr(8).cstring)
        result.directory.add(lump)

proc getLumpData*(w: Wad, lump: Lump): string =
    ## Get lump data by given Lump object
    return w.data[lump.offset.int - 12 ..< (lump.offset + lump.size).int - 12]

proc `$`*(lump: Lump): string =
    return "$# (offset: $#, size: $#)" % [lump.name, $lump.offset, $lump.size]

proc `$`*(h: WadInfo): string =
    ## Stringify WAD header
    result = "Wad type: $#, lumps: $#, offset: $#" % [$h.kind, $h.lumps, $h.offset]

proc `$`*(w: Wad): string =
    result = $w.header

when isMainModule:
    let w = newWad(newFileStream("res/Doom2.wad"))
    for i, v in w.directory:
        echo v
