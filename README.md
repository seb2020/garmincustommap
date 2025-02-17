# README

Update of existing scripts for creating Garmin map.

Currently in testing phase and work fine for Switzerland

## Scripts

```bash
./generate_map.sh
```

## Documentations

### DEM

Hill Shading is rendered by BaseCamp and GPS devices when the map includes a Digital Elevation Model (DEM). Use the following options to add a DEM to the map and control its characteristics. DEM creation requires files containing height information for the area covered by the map, the so called hgt files, which typically cover 1 degree latitude by 1 degree longitude and are named by the coordinates of their bottom left corner (e.g. N53E009). They contain height information in a grid of points. Typical hgt files contain either 1 arc second or 3 arc second data. 3 arc second files have 1201 x 1201 points, which means files contain 2 x 1201 x 1201 = 2,884,802 bytes. 1 arc second files have 3601 x 3601 points, with a file size of 25,934,402 bytes. Other files are supported as long as the formula sqrt(filesize/2) gives an integer value.

--> download https://sonny.4lima.de/

### DEM OSM

Convert HGT file to OSM with https://github.com/FSofTlpz/Hgt2Osm2

```shell
hgt2osm.exe --HgtPath=. --WriteElevationType=false --FakeDistance=-0.5 --MinVerticePoints=3 --MinBoundingbox=0.00016 --DouglasPeucker=0.05 --MinorDistance=10 --OutputOverwrite=true
```

### Links

- https://github.com/der-stefan/OpenTopoMap
- https://gitlab.com/ravenfeld/garmincustommap/-/blob/master/
- https://www.olivierbouillaud.com/osm/
