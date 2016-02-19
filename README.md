# wad

Wad file format library for Nim language

## About the Library and WADs

WAD (Where's All the Data) is a file format used in ID Software games. This
package implements loading data from WAD files for fetching resources for
old ID Games:

 * Doom 1
 * Doom 2

## Installation

```bash
$ nimble install https://github.com/SSPkrolik/wad.git
```

## Usage

### Example #01

Loading WAD directory and data into memory from stream:

```nim
import wad.wadfile

```

### Example #02

Parsing DOOM2 Wad file for loading game data

```nim
import wad.doomdata
```

## Status

Currently supported features that are available for extraction from WAD files:

 * `ENDOOM`  - exit text printed in DOS terminal
 * `PLAYPAL` - Doom 1/2 Color Palettes set
