#/bin/bash

### PACKAGES REQUIRED

# openjdk-8-jre
# unzip

### COMMON VARS (DON'T CHANGE)
continents=("africa" "asia" "australia-oceania" "central-america" "europe" "north-america" "south-america")
declare -A id
id=([africa]=0 [asia]=1 [australia-oceania]=2 [central-america]=3 [europe]=4 [north-america]=5 [south-america]=6)


### SPECIFIC VARS
JAVAOPTS="-Xmx24576m" # adjust to your system
MKGMAP="mkgmap-r4923" # adjust to latest version (see www.mkgmap.org.uk)
SPLITTER="splitter-r654" # adjust to latest version (see www.mkgmap.org.uk)
MKGMAP_OUTPUT_DIR="$(pwd)/out/mkgmap_out"
SPLITTER_OUTPUT_DIR="$(pwd)/out/splitter_out"
DEM_FILE="$(pwd)/data/dem"
DEM_OSM_FILE="$(pwd)/data/dem-osm"
MAPDATE="$(date +'%d%m%Y_%H%M%S')"
CONTINENT="europe"
COUNTRY="switzerland"
COUNTRYNAME_SHORT="CH"
GMAPI_ENABLED=false # Enable if you want to create map for Gamine BaseCamp
CONTOURS_ENABLED=false # Enable if you want to add contours to the map

#STYLE OpenTopoMap
STYLEFILE="$(pwd)/style/opentopomap/"
TYPFILE="$(pwd)/style/typ/opentopomap.typ"

#STYLE Rando
# STYLEFILE="$(pwd)/style/rando/"
# TYPFILE="$(pwd)/style/typ/rando.typ"

#STYLE Contours
STYLEFILE_CONTOURS="$(pwd)/style/contours/"
TYPFILE_CONTOURS="$(pwd)/style/typ/contours.typ"

# Generate a bash function for creating a logger with timestamp that takes input from function parameters
function logger {
    echo "$(date +'%Y-%m-%d %H:%M:%S') :: $1"
}

# This script initializes the environment for generating a Garmin map using OpenTopoMap data.
# The `init` function sets up necessary variables and configurations required for the map generation process.
function init {
    logger "######## Init required files ...."

    mkdir -p $MKGMAP_OUTPUT_DIR
    mkdir -p $SPLITTER_OUTPUT_DIR
    mkdir -p $DEM_FILE
    mkdir -p $DEM_OSM_FILE

    if [ ! -d "$(pwd)/tools/${MKGMAP}" ]; then
        wget "http://www.mkgmap.org.uk/download/${MKGMAP}.zip" -P "$(pwd)/tools/"
        unzip "$(pwd)/tools/${MKGMAP}.zip" -d "$(pwd)/tools/"
    fi
    MKGMAPJAR="$(pwd)/tools/${MKGMAP}/mkgmap.jar"

    if [ ! -d "$(pwd)/tools/${SPLITTER}" ]; then
        wget "http://www.mkgmap.org.uk/download/${SPLITTER}.zip" -P "$(pwd)/tools/"
        unzip "$(pwd)/tools/${SPLITTER}.zip" -d "$(pwd)/tools/"
    fi
    SPLITTERJAR="$(pwd)/tools/${SPLITTER}/splitter.jar"

    if [ -d "$(pwd)/data/bounds/" ]; then
        echo "bounds already downloaded"
    else
        echo "downloading bounds"
        wget "https://www.thkukuk.de/osm/data/bounds-latest.zip" -P "$(pwd)/data/"
        unzip "$(pwd)/data/bounds-latest.zip" -d "$(pwd)/data/bounds"
    fi
    BOUNDS_DIRECTORY="$(pwd)/data/bounds"

    if [ -d "$(pwd)/data/sea/" ]; then
        echo "sea already downloaded"
    else
        echo "downloading sea"
        wget "https://www.thkukuk.de/osm/data/sea-latest.zip" -P "$(pwd)/data/"
        unzip "$(pwd)/data/sea-latest.zip" -d "$(pwd)/data/"
    fi
    SEA_DIRECTORY="$(pwd)/data/sea"

    # rm -f "$(pwd)/data/${CONTINENT}/${COUNTRY}-latest.osm.pbf"
    # wget "https://download.geofabrik.de/${CONTINENT}/${COUNTRY}-latest.osm.pbf" -P "$(pwd)/data/${CONTINENT}"

    logger "######## End of init required files ...."
}

# This function splits DEM (Digital Elevation Model) data into OSM (OpenStreetMap) compatible format.
function splitDEMToOSM {

    ### map contours, generate only 1 time because it doesn't change regularly !
    logger "######## Split DEM to OSM ...."

    for file in $DEM_OSM_FILE/*.osm.gz; do
        DATA_DEM_OSM="$DATA_DEM_OSM $file"
    done

    java $JAVAOPTS -jar $SPLITTERJAR $DATA_DEM_OSM \
        --output-dir=$SPLITTER_OUTPUT_DIR/dem_osm \
        --keep-complete=false \
        --mapid=$MAPID_CONTOURS &> $SPLITTER_OUTPUT_DIR/splitter-dem-osm.log

    logger "######## End of split DEM to OSM ...."
}

# This function generates contour lines for the map.
function generateContours {
   
    logger "######## Creation of the map contours ...."

    for file in $SPLITTER_OUTPUT_DIR/dem_osm/*.osm.pbf; do
        DATA_DEM="$DATA_DEM $file"
    done

    OPTIONS="$(pwd)/contours_options"

    java $JAVAOPTS -jar $MKGMAPJAR -c $OPTIONS \
        --output-dir=$MKGMAP_OUTPUT_DIR/$CONTINENT/${COUNTRY}_contours \
        --style-file=$STYLEFILE_CONTOURS \
        $DATA_DEM $TYPFILE_CONTOURS &> $MKGMAP_OUTPUT_DIR/mkgmap-$CONTINENT-$COUNTRY-countours.log

    logger "######## End of the map courbes ...."

}

# This function splits a country map into smaller tiles.
function splitCountry {

    logger "######## Split country ...."

    java $JAVAOPTS -jar $SPLITTERJAR --precomp-sea=$SEA_DIRECTORY "$(pwd)/data/${CONTINENT}/${COUNTRY}-latest.osm.pbf" \
        --output-dir=$SPLITTER_OUTPUT_DIR/$CONTINENT/$COUNTRY \
        --max-threads=8 \
        --output=o5m \
        --description=${COUNTRY} \
        --mapid=$MAPID &> $SPLITTER_OUTPUT_DIR/splitter-$CONTINENT-$COUNTRY.log

    logger "######## End of split country ...."
}

# This function generates a map for Garmin devices.
function generateMap {

    logger "######## Creation of the map $COUNTRY in continent $CONTINENT... with MAPDATE $MAPDATE ...."
 
    for file in $SPLITTER_OUTPUT_DIR/$CONTINENT/$COUNTRY/*.o5m; do
        DATA="$DATA $file"
    done

    OPTIONS="$(pwd)/opentopomap_options"
   
    if [[ "$GMAPI_ENABLED" = true ]]; then
        GMAPI="--gmapi"
    else
        GMAPI=""
    fi

    if [[ "$CONTOURS_ENABLED" = true ]]; then
        CONTOURS="$MKGMAP_OUTPUT_DIR/${CONTINENT}/${COUNTRY}_contours/gmapsupp.img"
    else
        CONTOURS=""
    fi

    java $JAVAOPTS -jar $MKGMAPJAR -c $OPTIONS \
        --style-file=$STYLEFILE \
        --precomp-sea=$SEA_DIRECTORY \
        --output-dir=$MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY \
        --bounds=$BOUNDS_DIRECTORY \
        --description="OpenTopoMap_${COUNTRYNAME_SHORT}_${MAPDATE}" \
        --area-name="OpenTopoMap_${COUNTRYNAME_SHORT}_${MAPDATE}" \
        --overview-mapname="OpenTopoMap_${COUNTRYNAME_SHORT}_${MAPDATE}"  \
        --family-name="OpenTopoMap_${COUNTRYNAME_SHORT}_${MAPDATE}" \
        --family-id="$FAMILY_ID" \
        --series-name="OpenTopoMap_${COUNTRYNAME_SHORT}_${MAPDATE}" \
        $GMAPI \
        --dem=$DEM_FILE \
        $DATA $TYPFILE $CONTOURS &> $MKGMAP_OUTPUT_DIR/mkgmap-$CONTINENT-$COUNTRY.log

    logger "######## End of of the map $COUNTRY in continent $CONTINENT... with MAPDATE $MAPDATE ...."

}

# This function clean files that are not necessary and rename the final map file.
function cleanUp {

    logger "######## Clean up unnecessary files ...."

    rm $MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY/53*.img $MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY/53*.tdb 
    rm $MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY/ovm*.img $MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY/*.typ 
    rm $MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY/OpenTopoMap_${COUNTRYNAME_SHORT}_${MAPDATE}.img 
    rm $MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY/OpenTopoMap_${COUNTRYNAME_SHORT}_${MAPDATE}_mdr.img 
    rm $MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY/OpenTopoMap_${COUNTRYNAME_SHORT}_${MAPDATE}.mdx 
    rm $MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY/OpenTopoMap_${COUNTRYNAME_SHORT}_${MAPDATE}.tdb

    mv $MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY/gmapsupp.img $MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY/OpenTopoMap_${COUNTRYNAME_SHORT}_${MAPDATE}.img

    logger "######## End of clean up unnecessary files ...."
}

#-----------------------------

init

FAMILY_ID=$(( 53000+${id[$CONTINENT]}*100 ))
MAPID=$(( $FAMILY_ID*1000+1 ))
MAPID_CONTOURS=$(( $MAPID+5000 ))

logger "FAMILY_ID is $FAMILY_ID"
logger "MAPID is $MAPID"
logger "MAPID_CONTOURS is $MAPID_CONTOURS"

splitDEMToOSM
# generateContours
# splitCountry
# generateMap
# cleanUp
