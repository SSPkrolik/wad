import streams
import strutils
import wadfile

# Lump Types
const
    ltExitText*  = "ENDOOM"
    ltPallettes* = "PLAYPAL"

type
    ColorChar* = int16
        ## Colored DOS terminal character

    ColorText* = array[0 .. 1999, ColorChar]
        ## Colored DOS terminal text

    RGB* = object
        red*: byte
        green*: byte
        blue*: byte

    Pallette* = array[0 .. 255, RGB]

    DoomData* = ref object
        ## Doom Game Model Structure
        pallettes*: array[0 .. 13, Pallette]
        exitText*: ColorText

proc `$`*(c: RGB): string =
    return "RGB($#, $#, $#)" % [$c.red, $c.green, $c.blue]

proc `$`*(p: Pallette): string =
    result = "Pallette ["
    for i in 0 .. 255:
        result = result & $p[i] & ", "
    result[^2] = ']'
    result.setLen(result.len - 1)

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

    let wadData = newWad(s)

    for item in wadData.directory:
        case item.name
        of ltExitText:
            ## DOS Exit Text
            let sText = newStringStream(wadData.getLumpData(item))
            for i in 0 ..< 80 * 25:
                result.exitText[i] = sText.readInt16()
        of ltPallettes:
            ## Color Pallettes
            let sText = newStringStream(wadData.getLumpData(item))
            for pi in 0 ..< 14:
                var pal: Pallette
                for ci in 0 ..< 256:
                    pal[ci] = RGB(
                        red  : sText.readInt8().byte,
                        green: sText.readInt8().byte,
                        blue : sText.readInt8().byte
                    )
                result.pallettes[pi] = pal
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
    echo game.exitText
    echo game.pallettes[0]
