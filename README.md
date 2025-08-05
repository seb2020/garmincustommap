# README

Update of various existing scripts for creating a map for your Garmin watch from OpenStreetMap.

Currently in testing phase and work fine for Switzerland

|                     | Switzerland  | France |   |   |
|---------------------|--------------|--------|---|---|
| hgtToPBF            |              |        |   |   |
| splitDEMToOSM       | ~2m          |        |   |   |
| generateContours    | ~2m          |        |   |   |
| splitCountry        | ~2m          |        |   |   |
| generateMap         | ~5m          |        |   |   |
| mergeContoursAndMap | ~8m          |        |   |   |
|                     |              |        |   |   |

## Prerequisites

Download in `garmin/hgt` the file from your country (download <https://sonny.4lima.de/>). The folder must contains files in `hgt` extension.

## Scripts

All-in-one :

```bash
./garmin/generate_map.sh "europe" "switzerland" "CH" "" 51000
```

If you enable `GMAPI_ENABLED`, you will have a map for Garmin Basecamp. You can copy `$MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY/GCM_XX_XXX_XXX.gmap` to `C:\ProgramData\Garmin\Maps`.

If you enable `CONTOURS_ENABLED`, a map for countours will be generated. You can do this only 1 times, the map doesn't change regulary (Example : every 6 years for Switzerland)

## View maps

For viewing maps, you can use :

- QMapShack (<https://github.com/Maproom/qmapshack>)
- Garmin BaseCamp (<https://www.garmin.com/fr-CH/software/basecamp/>)

## Documentations

## DEM - Generic infos

Hill Shading is rendered by BaseCamp and GPS devices when the map includes a Digital Elevation Model (DEM). Use the following options to add a DEM to the map and control its characteristics. DEM creation requires files containing height information for the area covered by the map, the so called hgt files, which typically cover 1 degree latitude by 1 degree longitude and are named by the coordinates of their bottom left corner (e.g. N53E009). They contain height information in a grid of points. Typical hgt files contain either 1 arc second or 3 arc second data. 3 arc second files have 1201 x 1201 points, which means files contain 2 x 1201 x 1201 = 2,884,802 bytes. 1 arc second files have 3601 x 3601 points, with a file size of 25,934,402 bytes. Other files are supported as long as the formula sqrt(filesize/2) gives an integer value.

### DEM - Convert to PBF

#### New way with python

Download poly from your country and convert files :

```bash
wget https://download.geofabrik.de/europe/switzerland.poly -P data/europe/
cd ./data/dem-pbf
pyhgtmap ../../data/hgt/*.hgt --polygon=../../data/europe/switzerland.poly --step=10 --pbf --simplifyContoursEpsilon=0.00001 -j16
```

#### Old way with EXE

Convert HGT file to OSM with https://github.com/FSofTlpz/Hgt2Osm2

```bash
hgt2osm.exe --HgtPath=. --WriteElevationType=false --FakeDistance=-0.5 --MinVerticePoints=3 --MinBoundingbox=0.00016 --DouglasPeucker=0.05 --MinorDistance=10 --OutputOverwrite=true
```

## Links

- https://github.com/der-stefan/OpenTopoMap
- https://gitlab.com/ravenfeld/garmincustommap/-/blob/master/
- https://www.olivierbouillaud.com/osm/
- https://github.com/agrenott/pyhgtmap
