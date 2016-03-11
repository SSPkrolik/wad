import sequtils
import streams
import strutils
import tables
import wadfile

# Lump Types
const
    ltExitText   = "ENDOOM"    ## DOS Exit text

    # Map Description

    ltPalettes   = "PLAYPAL"   ## Color Palettes set
    ltDemo       = "DEMO"      ## DEMOXX: Recorded Gameplay Demonstration
    ltMap        = "MAP"       ## MAPXX: Map definition starts
    ltThings     = "THINGS"    ## Monsters on map
    ltLines      = "LINEDEFS"  ##
    ltSides      = "SIDEDEFS"  ##
    ltVertexes   = "VERTEXES"  ##
    ltSegs       = "SEGS"      ##
    ltSubSectors = "SSECTORS"  ##
    ltNodes      = "NODES"     ##
    ltSectors    = "SECTORS"   ##
    ltReject     = "REJECT"    ## TODO
    ltBlockMap   = "BLOCKMAP"  ## Collision-detection support data structure

    # Game-Wide resources

    ltColorMap   = "COLORMAP"  ## TODO
    ltTexture1   = "TEXTURE1"  ## TODO
    ltPNames     = "PNAMES"    ## TODO

    # Sounds and Music

    ltGenMidi    = "GENMIDI"   ## TODO
    ltDmxGusc    = "DMXGUSC"   ## TODO
    ltDPPrefix   = "DP"        ## TODO
    ltDSPrefix   = "DS"        ## TODO
    ltDPrefix    = "D_"        ## TODO

    # Sprites Management

    ltSStart     = "S_START"   ## TODO
    ltSEnd       = "S_END"     ## TODO
    ltPStart     = "P_START"   ## TODO
    ltPEnd       = "P_END"     ## TODO
    ltP1Start    = "P1_START"  ## TODO
    ltP1End      = "P1_END"    ## TODO
    ltP2Start    = "P2_START"  ## TODO
    ltP2End      = "P2_END"    ## TODO
    ltP3Start    = "P3_START"  ## TODO
    ltP3End      = "P3_END"    ## TODO
    ltFStart     = "F_START"   ## TODO
    ltFEnd       = "F_END"     ## TODO
    ltF1Start    = "F1_START"  ## TODO
    ltF1End      = "F1_END"    ## TODO

const
    MapNodeIsSubsector*: uint16 = 0x8000  # For MapNode child attribute value

type
    ColorChar* = int16
        ## Colored DOS terminal character

    ColorText* = array[0 .. 1999, ColorChar]
        ## Colored DOS terminal text

    RGB* = object
        ## Color representation
        red*: uint8
        green*: uint8
        blue*: uint8

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

    MapSeg* = ref object
        ## Map Segment
        vertexStart*: int16
        vertexEnd*:   int16
        bams*:        int16
        lineNum*:     int16
        segSide*:     int16
        segOffset*:   int16

    MapSubSector* = ref object
        ## Map Sub-Sector
        numSegs:  int16
        startSeg: int16

    MapNode* = ref object
        ## Map Node
        x:         int16
        y:         int16
        dx:        int16
        dy:        int16
        boxtop:    int16
        boxbottom: int16
        boxleft:   int16
        boxright:  int16
        child:     uint16

    MapSector* = ref object
        ## Map Sector
        floorHeight:   int16
        ceilingHeight: int16
        floorPic:      string
        ceilingPic:    string
        lightLevel:    int16
        specialSector: int16
        tag:           int16

    MapReject* = ref object # TODO: !!!

    MapBlockmap* = ref object
        xorigin: int16
        yorigin: int16
        xblocks: int16
        yblocks: int16

    Map* = ref object
        ## Doom Level Map
        things*:     seq[Thing]
        lines*:      seq[MapLine]
        sides*:      seq[MapSide]
        vertexes*:   seq[MapVertex]
        segments*:   seq[MapSeg]
        subsectors*: seq[MapSubSector]
        nodes*:      seq[MapNode]
        sectors*:    seq[MapSector]

    PicturePost* = ref object
        row*:    uint8
        length*: uint8
        colors*: seq[uint8]  # 0 and len.seq - 1 indices are not drawn !!!

    PictureColumn* = ref object
        columnPointer: int32
        posts*:         seq[PicturePost]

    Picture* = ref object
        width*:      int16
        height*:     int16
        leftOffset*: int16
        topOffset*:  int16
        columns*:    seq[PictureColumn]

    DoomData* = ref object
        ## Doom Game Model Structure
        palettes*: array[0 .. 13, Palette]
        exitText*: ColorText
        demos*:    seq[Demo]
        maps*:     seq[Map]
        pictures*: TableRef[string, Picture]

proc newMapSubSector(numSegs, startSeg: int16): MapSubSector =
    ## Constructor for map sub-sector
    result.new
    result.numSegs = numSegs
    result.startSeg = startSeg

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
    result.things     = @[]
    result.lines      = @[]
    result.sides      = @[]
    result.vertexes   = @[]
    result.segments   = @[]
    result.subsectors = @[]
    result.nodes      = @[]
    result.sectors    = @[]

proc `$`*(v: MapVertex): string =
    return "Vertex ($#, $#)" % [$v.x, $v.y]

proc `$`*(c: RGB): string =
    when defined(js):
        return "RGB Color"
    else:
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

proc `$`*(seg: MapSeg): string =
    ## Stringify Map Segment
    return "Segment (vertexes: [$#, $#], bams: $#, line: $#, side: $#, offset: $#)" % [
        $seg.vertexStart,
        $seg.vertexEnd,
        $seg.bams,
        $seg.lineNum,
        $seg.segSide,
        $seg.segOffset
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

proc `$`*(subSector: MapSubSector): string =
    ## Stringify map sub-sector
    return "Subsector (num: $#, start: $#)" % [
        $subSector.numSegs,
        $subSector.startSeg
    ]

proc `$`*(node: MapNode): string =
    ## Stringify map node
    when defined(js):
        return "Node"
    else:
        return "Node (x: $#, y: $#, dx: $#, dy: $#, ..., child: $#)" % [
            $node.x,
            $node.x,
            $node.dx,
            $node.dy,
            $node.child,
        ]

proc `$`*(sector: MapSector): string =
    ## Stringify map sector
    return "Sector (floor: $# [$#], ceil: $# [$#], ..., tag: $#)" % [
        $sector.floorHeight,
        sector.floorPic,
        $sector.ceilingHeight,
        sector.ceilingPic,
        $sector.tag
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
    result.pictures = newTable[string, Picture]()

    let wadData = newWad(s)

    # Context for Paring
    var
        mapContext: Map = nil
        flatContext: bool = false

    for item in wadData.directory:
        # `ENDOOM`: DOS Exit Text
        let sText = newStringStream(wadData.getLumpData(item))
        if item.name == ltExitText:
            for i in 0 ..< 80 * 25:
                result.exitText[i] = sText.readInt16()
        # `PLAYPAL`: Color Palettes
        elif item.name == ltPalettes:
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
            for _ in 0 ..< (item.size / 30).int:
                mapContext.sides.add(newMapSide(
                    sText.readInt16(),
                    sText.readInt16(),
                    $(sText.readStr(8).cstring),
                    $(sText.readStr(8).cstring),
                    $(sText.readStr(8).cstring),
                    sText.readInt16()
                ))
        # Map Vertexes
        elif item.name == ltVertexes:
            for _ in 0 ..< (item.size / 4).int:
                let vertex = MapVertex.new
                vertex.x = sText.readInt16()
                vertex.y = sText.readInt16()
                mapContext.vertexes.add(vertex)
        # Map Segments
        elif item.name == ltSegs:
            for _ in 0 ..< (item.size / 12).int:
                let seg = MapSeg.new
                seg.vertexStart = sText.readInt16()
                seg.vertexEnd   = sText.readInt16()
                seg.bams        = sText.readInt16()
                seg.lineNum     = sText.readInt16()
                seg.segSide     = sText.readInt16()
                seg.segOffset   = sText.readInt16()
                mapContext.segments.add(seg)
        # Map subsectors
        elif item.name == ltSubSectors:
            for _ in 0 ..< (item.size / 4).int:
                let ssec = newMapSubSector(sText.readInt16(), sText.readInt16())
                mapContext.subsectors.add(ssec)
        # Map nodes
        elif item.name == ltNodes:
            for _ in 0 ..< (item.size / 18).int:
                let snode = new(MapNode)
                snode.x         = sText.readInt16()
                snode.y         = sText.readInt16()
                snode.dx        = sText.readInt16()
                snode.dy        = sText.readInt16()
                snode.boxtop    = sText.readInt16()
                snode.boxbottom = sText.readInt16()
                snode.boxleft   = sText.readInt16()
                snode.boxright  = sText.readInt16()
                snode.child     = sText.readInt16().uint16
                mapContext.nodes.add(snode)
        # Map Sectors
        elif item.name == ltSectors:
            for _ in 0 ..< (item.size / 28).int:
                let sect = new(MapSector)
                sect.floorHeight   = sText.readInt16()
                sect.ceilingHeight = sText.readInt16()
                sect.floorPic      = $(sText.readStr(8).cstring)
                sect.ceilingPic    = $(sText.readStr(8).cstring)
                sect.lightLevel    = sText.readInt16()
                sect.specialSector = sText.readInt16()
                sect.tag           = sText.readInt16()
                mapContext.sectors.add(sect)
        # Reject
        elif item.name == ltReject:   # TODO
            discard #
        # Colormap
        elif item.name == ltColorMap: # TODO
            discard
        # Blockmap
        elif item.name == ltBlockMap: # TODO
            discard
        # Texture1
        elif item.name == ltTexture1: # TODO
            discard
        # PNames
        elif item.name == ltPNames:   # TODO
            discard
        # GenMidi
        elif item.name == ltGenMidi:  # TODO
            discard
        # DMXGUSC
        elif item.name == ltDmxGusc:  # TODO
            discard
        # PC Speaker effects
        elif item.name.startsWith(ltDPPrefix): # TODO
            discard
        # SoundCard effects
        elif item.name.startsWith(ltDSPrefix): # TODO
            discard
        # Music
        elif item.name.startsWith(ltDPrefix):  # TODO
            discard
        # Sprite start
        elif item.name == ltSStart: # TODO
            discard
        # Sprite end
        elif item.name == ltSEnd:   # TODO
            discard
        # Wall Patch Start
        elif item.name == ltPStart: # TODO
            discard
        # Wall Patch End
        elif item.name == ltPEnd:   # TODO
            discard
        elif item.name == ltP1Start: # TODO
            discard
        elif item.name == ltP1End:   # TODO
            discard
        elif item.name == ltP2Start: # TODO
            discard
        elif item.name == ltP2End:   # TODO
            discard
        elif item.name == ltP3Start: # TODO
            discard
        elif item.name == ltP3End:   # TODO
            discard
        elif item.name == ltFStart: # TODO
            flatContext = true
        elif item.name == ltFEnd:   # TODO
            flatContext = false
        elif item.name == ltF1Start: # TODO
            discard
        elif item.name == ltF1End:   # TODO
            discard
        # Pictures
        else:
            if flatContext: continue # TODO: Rework this
            let pic = new(Picture)
            pic.width      = sText.readInt16()
            pic.height     = sText.readInt16()
            pic.leftOffset = sText.readInt16()
            pic.topOffset  = sText.readInt16()
            pic.columns = @[]
            for cindex in 0 ..< (pic.width).int:
                let column = new(PictureColumn)
                column.columnPointer = sText.readInt32()
                column.posts = @[]
                pic.columns.add(column)
            for col in pic.columns:
                sText.setPosition(col.columnPointer)
                var columnStart = cast[uint8](sText.readInt8())
                while cast[uint8](columnStart) != 0xFF'u8:
                    let post = new(PicturePost)
                    post.row = columnStart
                    post.length = cast[uint8](sText.readInt8())
                    post.colors = @[]
                    for _ in 0 ..< post.length + 2:
                        post.colors.add(cast[uint8](sText.readInt8()))
                    col.posts.add(post)
                    columnStart = cast[uint8](sText.readInt8())
            result.pictures[item.name] = pic

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
    echo "\nDoom 2. Hell on Earth:\n"

    echo game.exitText

    echo "Palettes  : ", game.palettes[0][..3], "..."
    echo "Things    : ", game.maps[0].things[0]
    echo "Lines     : ", game.maps[0].lines[0]
    echo "Sides     : ", game.maps[0].sides[0]
    echo "Vertexes  : ", game.maps[0].vertexes[0]
    echo "Segments  : ", game.maps[0].segments[0]
    echo "Subsectors: ", game.maps[0].subsectors[0]
    echo "Nodes     : ", game.maps[0].nodes[0]
    echo "Sectors   : ", game.maps[0].sectors[0]
    echo "Pictures  : ", game.pictures.len
