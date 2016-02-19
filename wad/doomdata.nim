import streams
import strutils
import wadfile

# Lump Types
const
    ltExitText = "ENDOOM"    ## DOS Exit text
    ltPalettes = "PLAYPAL"   ## Color Palettes set
    ltDemo     = "DEMO"      ## DEMOXX: Recorded Gameplay Demonstration
    ltMap      = "MAP"       ## MAPXX: Map definition starts
    ltThings   = "THINGS"    ## Monsters on map
    ltLines    = "LINEDEFS"  ##
    ltSides    = "SIDEDEFS"  ##
    ltVertexes = "VERTEXES"  ##

discard """
    DEMO1 (offset: 23468, size: 4834)            ? Later ?
    DEMO2 (offset: 28304, size: 8018)            ? Later ?
    DEMO3 (offset: 36324, size: 17898)           ? Later ?
    MAP01 (offset: 54224, size: 0)                   +
    THINGS (offset: 54224, size: 690)                +
    LINEDEFS (offset: 54916, size: 5180)             +
    SIDEDEFS (offset: 60096, size: 15870)            +
    VERTEXES (offset: 75968, size: 1532)             +
    SEGS (offset: 77500, size: 7212)
    SSECTORS (offset: 84712, size: 776)
    NODES (offset: 85488, size: 5404)
    SECTORS (offset: 90892, size: 1534)
    REJECT (offset: 92428, size: 436)
    BLOCKMAP (offset: 92864, size: 6418)
"""

type
    ColorChar* = int16
        ## Colored DOS terminal character

    ColorText* = array[0 .. 1999, ColorChar]
        ## Colored DOS terminal text

    RGB* = object
        ## Color representation
        red*: byte
        green*: byte
        blue*: byte

    Palette* = array[0 .. 255, RGB]
        ## 8-bit Indexed Color Pallette

    Demo* = string
        ## Doom Gameplay Demonstration

    Thing* = ref object of RootObj
        x*:       int16
        y*:       int16
        angle*:   int16
        kind*:    int16
        options*: int16

    MapLine* = ref object
        ## Map Line Definition
        vertexStart*: int16
        vertexEnd*:   int16
        flags*:       int16
        function*:    int16
        tag*:         int16
        sideRight*:   int16
        sideLeft*:    int16

    MapSide* = ref object
        ## Map Side Definition
        xOffset*:       int16
        yOffset*:       int16
        upperTexture*:  string
        lowerTexture*:  string
        middleTexture*: string
        sectorRef*:     int16

    MapVertex* = ref object
        ## Map Vertex Definition
        x*: int16
        y*: int16

    Map* = ref object
        ## Doom Level Map
        things*: seq[Thing]
        lines*: seq[MapLine]
        sides*: seq[MapSide]
        vertexes*: seq[MapVertex]

    DoomData* = ref object
        ## Doom Game Model Structure
        palettes*: array[0 .. 13, Palette]
        exitText*: ColorText
        demos*: seq[Demo]
        maps*: seq[Map]

proc newMapVertex(x, y: int16): MapVertex =
    result.new
    result.x = x
    result.y = y

proc newMapSide(xOffset, yOffset: int16, upperTexture, lowerTexture, middleTexture: string, sectorRef: int16): MapSide =
    ## Constructor for map side
    result.new
    result.xOffset = xOffset
    result.yOffset = yOffset
    result.upperTexture = upperTexture
    result.lowerTexture = lowerTexture
    result.middleTexture = middleTexture
    result.sectorRef = sectorRef

proc newThing(x, y, angle, kind, options: int16): Thing =
    ## Constructor of thing (monster on map)
    result.new
    result.x = x
    result.y = y
    result.angle = angle
    result.kind = kind
    result.options = options

proc newMapLine(vertexStart, vertexEnd, flags, function, tag, sideRight, sideLeft: int16): MapLine =
    ## Constructor of Line definition (map part)
    result.new
    result.vertexStart = vertexStart
    result.vertexEnd = vertexEnd
    result.flags = flags
    result.function = function
    result.tag = tag
    result.sideRight = sideRight
    result.sideLeft = sideLeft

proc newMap*(): Map =
    ## Empty Map constructor
    result.new
    result.things = @[]
    result.lines = @[]
    result.sides = @[]
    result.vertexes = @[]

proc `$`*(v: MapVertex): string =
    return "Vertex ($#, $#)" % [$v.x, $v.y]

proc `$`*(c: RGB): string =
    return "RGB($#, $#, $#)" % [$c.red, $c.green, $c.blue]

proc `$`*(p: Palette): string =
    result = "Palette ["
    for i in 0 .. 255:
        result = result & $p[i] & ", "
    result[^2] = ']'
    result.setLen(result.len - 1)

proc `$`*(t: Thing): string =
    ## Stringify Thing
    return "Thing ($#, $#)" % [$t.x, $t.y]

proc `$`*(ml: MapLine): string =
    ## Stringify Map Line
    return "Line (vertexes: [$#, $#], flags: $#, function, $#, tag: $#, sides: [$#, $#])" % [
        $ml.vertexStart, $ml.vertexEnd,
        $ml.flags, $ml.function, $ml.tag,
        $ml.sideRight, $ml.sideLeft
    ]

proc `$`*(ms: MapSide): string =
    ## Stringify Map Side
    return "Side ($#, $#, [$#/$#/$#])" % [
        $ms.xOffset,
        $ms.yOffset,
        ms.upperTexture,
        ms.middleTexture,
        ms.lowerTexture
    ]

proc `$`*(m: Map): string =
    return "Map (Things: $#)" % [$m.things.len]

proc width*(ct: ColorText): int = 80
    ## Screen width for color text

proc height*(ct: ColorText): int = 25
    ## Screen height for color text

proc blink*(cc: ColorChar): bool =
    ## Defines if the character blinks
    return (cc.int16 and (1.int16 shl 15)) == 1

proc bgColor*(cc: ColorChar): int =
    ## Takes character background color
    return cc.int16 and (8.int16 shl 14)

proc fgColor*(cc: ColorChar): int =
    ## Takes character foreground color
    return cc.int16 and (15.int16 shl 8)

proc newDoomData*(s: Stream): DoomData =
    ## constructor for Doom game model
    result.new
    result.demos = @[]
    result.maps = @[]

    let wadData = newWad(s)

    # Context for Paring
    var mapContext: Map = nil

    for item in wadData.directory:
        # `ENDOOM`: DOS Exit Text
        if item.name == ltExitText:
            let sText = newStringStream(wadData.getLumpData(item))
            for i in 0 ..< 80 * 25:
                result.exitText[i] = sText.readInt16()
        # `PLAYPAL`: Color Palettes
        elif item.name == ltPalettes:
            let sText = newStringStream(wadData.getLumpData(item))
            for pi in 0 ..< 14:
                var pal: Palette
                for ci in 0 ..< 256:
                    pal[ci] = RGB(
                        red  : sText.readInt8().byte,
                        green: sText.readInt8().byte,
                        blue : sText.readInt8().byte
                    )
                result.palettes[pi] = pal
        # `DEMOXX`: GamePlay Demos
        elif item.name.startsWith(ltDemo):
            ## TODO: load Demo
        # `MAPXX`: Game Map Definition
        elif item.name.startsWith(ltMap):
            # Create new map or push already parsed into the Doom Data model
            if mapContext == nil:
                mapContext = newMap()
            else:
                result.maps.add(mapContext)
                mapContext = newMap()
        # Monsters of Map
        elif item.name == ltThings:
            let sText = newStringStream(wadData.getLumpData(item))
            for _ in 0 ..< (item.size / 10).int:
                mapContext.things.add(newThing(
                    sText.readInt16(),
                    sText.readInt16(),
                    sText.readInt16(),
                    sText.readInt16(),
                    sText.readInt16()
                ))
        # Map Lines
        elif item.name == ltLines:
            let sText = newStringStream(wadData.getLumpData(item))
            for _ in 0 ..< (item.size / 14).int:
                mapContext.lines.add(newMapLine(
                    sText.readInt16(),
                    sText.readInt16(),
                    sText.readInt16(),
                    sText.readInt16(),
                    sText.readInt16(),
                    sText.readInt16(),
                    sText.readInt16()
                ))
        # Map sides
        elif item.name == ltSides:
            let sText = newStringStream(wadData.getLumpData(item))
            for _ in 0 ..< (item.size / 30).int:
                mapContext.sides.add(newMapSide(
                    sText.readInt16(),
                    sText.readInt16(),
                    $(sText.readStr(8).cstring),
                    $(sText.readStr(8).cstring),
                    $(sText.readStr(8).cstring),
                    sText.readInt16()
                ))
        elif item.name == ltVertexes:
            let sText = newStringStream(wadData.getLumpData(item))
            for _ in 0 ..< (item.size / 4).int:
                mapContext.vertexes.add(newMapVertex(
                    sText.readInt16(),
                    sText.readInt16()
                ))
        else:
            discard

converter toChar*(cc: ColorChar): char =
    ## Returns character representation of the color char
    return (int16(cc) and int16(255)).byte.chr

converter toString*(ct: ColorText): string =
    result = ""
    for i in 0 ..< 80 * 25:
        result = result & ct[i]
        if (i mod 80 == 0) and i != 0:
            result = result & "\n"

when isMainModule:
    let game = newDoomData(newFileStream("res/Doom2.wad"))
    echo "Doom 2. Hell on Earth:\n"

    echo game.exitText

    echo "Palettes: ", game.palettes[0][..3], "..."
    echo "Things: ", game.maps[0].things[0]
    echo "Lines: ", game.maps[0].lines[0]
    echo "Sides: ", game.maps[0].sides[0]
    echo "Vertexes: ", game.maps[0].vertexes[0]
