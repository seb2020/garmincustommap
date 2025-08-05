#/bin/bash

### PACKAGES REQUIRED

# openjdk-8-jre
# unzip

### COMMON VARS (DON'T CHANGE)
continents=("africa" "asia" "australia-oceania" "central-america" "europe" "north-america" "south-america")
declare -A id
id=([africa]=0 [asia]=1 [australia-oceania]=2 [central-america]=3 [europe]=4 [north-america]=5 [south-america]=6)


### SPECIFIC VARS
JAVAOPTS="-Xmx24g" # adjust to your system
MKGMAP="mkgmap-r4923" # adjust to latest version (see www.mkgmap.org.uk)
SPLITTER="splitter-r654" # adjust to latest version (see www.mkgmap.org.uk)
BASEPATH=/mnt/c/Users/sebastien/Downloads/garmincustommap/garmin
MKGMAP_OUTPUT_DIR="$BASEPATH/out/mkgmap_out"
SPLITTER_OUTPUT_DIR="$BASEPATH/out/splitter_out"
DEM_FILE="$BASEPATH/data/hgt"
DEM_PBF_FOLDER="$BASEPATH/data/dem-pbf"
MAPDATE="$(date +'%d%m%Y_%H%M%S')"
MAPDATE_CONTOURS="$(date +'%d%m%Y')"
GMAPI_ENABLED=true # Enable if you want to create map for Gamin BaseCamp
CONTOURS_ENABLED=true # Enable if you want to merge the contour and the map in a single file
GMAPI_CONTOURS_ENABLED=true # Enable if you want to create map for Gamin BaseCamp for the countour map

# Arguments from CLI
CONTINENT=$1
SEEDMAP=$5 # adjust to your system, this is the base ID for the map. Each map must have a unique ID.
COUNTRY=$2
COUNTRY_SUBZONE=$4
COUNTRYNAME_SHORT=$3

#STYLE OpenTopoMap
# STYLEFILE="$BASEPATH/style/opentopomap/"
# TYPFILE="$BASEPATH/style/typ/opentopomap.typ"

#STYLE Rando
STYLEFILE="$BASEPATH/style/rando_v2/"
TYPFILE="$BASEPATH/style/typ/rando_v2.typ"

#STYLE Rando for contours
STYLEFILE_CONTOURS="$BASEPATH/style/rando_v2/"
TYPFILE_CONTOURS="$BASEPATH/style/typ/rando_v2.typ"

# Generate a bash function for creating a logger with timestamp that takes input from function parameters
function logger {
    echo "$(date +'%Y-%m-%d %H:%M:%S') :: $1"
}

# This script initializes the environment for generating a Garmin map using OpenTopoMap data.
# The `init` function sets up necessary variables and configurations required for the map generation process.
function init {
    logger "######## Init required files ...."

    mkdir -p $BASEPATH/tools
    mkdir -p $BASEPATH/data
    mkdir -p $MKGMAP_OUTPUT_DIR
    mkdir -p $SPLITTER_OUTPUT_DIR
    mkdir -p $DEM_FILE
    mkdir -p $DEM_PBF_FOLDER/$CONTINENT/$COUNTRY

    if [ ! -d "$BASEPATH/tools/${MKGMAP}" ]; then
        wget "http://www.mkgmap.org.uk/download/${MKGMAP}.zip" -P "$BASEPATH/tools/"
        unzip "$BASEPATH/tools/${MKGMAP}.zip" -d "$BASEPATH/tools/"
    fi
    MKGMAPJAR="$BASEPATH/tools/${MKGMAP}/mkgmap.jar"

    if [ ! -d "$BASEPATH/tools/${SPLITTER}" ]; then
        wget "http://www.mkgmap.org.uk/download/${SPLITTER}.zip" -P "$BASEPATH/tools/"
        unzip "$BASEPATH/tools/${SPLITTER}.zip" -d "$BASEPATH/tools/"
    fi
    SPLITTERJAR="$BASEPATH/tools/${SPLITTER}/splitter.jar"

    if [ -d "$BASEPATH/data/bounds/" ]; then
        echo "bounds already downloaded"
    else
        echo "downloading bounds"
        wget "https://www.thkukuk.de/osm/data/bounds-latest.zip" -P "$BASEPATH/data/"
        unzip "$BASEPATH/data/bounds-latest.zip" -d "$BASEPATH/data/bounds"
    fi
    BOUNDS_DIRECTORY="$BASEPATH/data/bounds"

    if [ -d "$BASEPATH/data/sea/" ]; then
        echo "sea already downloaded"
    else
        echo "downloading sea"
        wget "https://www.thkukuk.de/osm/data/sea-latest.zip" -P "$BASEPATH/data/"
        unzip "$BASEPATH/data/sea-latest.zip" -d "$BASEPATH/data/"
    fi
    SEA_DIRECTORY="$BASEPATH/data/sea"

    rm -f "$BASEPATH/data/${CONTINENT}/${COUNTRY}/${COUNTRY}-latest.osm.pbf"
    wget "https://download.geofabrik.de/${CONTINENT}/${COUNTRY}-latest.osm.pbf" -P "$BASEPATH/data/${CONTINENT}/${COUNTRY}"

    rm -f "$BASEPATH/data/${CONTINENT}/${COUNTRY}/${COUNTRY}.poly"
    wget "https://download.geofabrik.de/${CONTINENT}/${COUNTRY}.poly" -P "$BASEPATH/data/${CONTINENT}/${COUNTRY}"
  
    logger "######## End of init required files ...."
}
function hgtToPBF {

    logger "######## Convert HGT to PBF ...."

    cd $DEM_PBF_FOLDER/$CONTINENT/$COUNTRY
    pyhgtmap $DEM_FILE/*.hgt --polygon=$BASEPATH/data/${CONTINENT}/${COUNTRY}/${COUNTRY}.poly --step=10 --pbf --simplifyContoursEpsilon=0 --no-zero-contour -j16
    cd ../../

    logger "######## End of convert HGT to PBF ...."
}

# This function splits DEM (Digital Elevation Model) data into OSM (OpenStreetMap) compatible format.
function splitDEMToOSM {

    ### map contours, generate only 1 time because it doesn't change regularly !
    logger "######## Split DEM to OSM ...."

    for file in $DEM_PBF_FOLDER/$CONTINENT/$COUNTRY/*.osm.pbf; do
        DATA_DEM_PBF="$DATA_DEM_PBF $file"
    done

    java $JAVAOPTS -jar $SPLITTERJAR $DATA_DEM_PBF \
        --output-dir=$SPLITTER_OUTPUT_DIR/dem_pbf/$CONTINENT/$COUNTRY \
        --keep-complete=false \
        --polygon-file=$BASEPATH/data/${CONTINENT}/${COUNTRY}/${COUNTRY}.poly \
        --description="GCM_${COUNTRYNAME_SHORT}_Contours_${MAPDATE_CONTOURS}" \
        --mapid=$MAPID_CONTOURS &> $SPLITTER_OUTPUT_DIR/splitter-dem-pbf-$CONTINENT-$COUNTRY.log

    logger "######## End of split DEM to OSM ...."
}

# This function generates contour lines for the map.
function generateContours {
   
    logger "######## Creation of the map contours ...."

    for file in $SPLITTER_OUTPUT_DIR/dem_pbf/$CONTINENT/$COUNTRY/*.osm.pbf; do
        DATA_DEM="$DATA_DEM $file"
    done

    OPTIONS="$BASEPATH/contours_options"

    if [[ "$GMAPI_CONTOURS_ENABLED" = true ]]; then
        GMAPI="--gmapi"
    else
        GMAPI=""
    fi

    mkdir -p $MKGMAP_OUTPUT_DIR/$CONTINENT/${COUNTRY}_contours

    cd $MKGMAP_OUTPUT_DIR/$CONTINENT/${COUNTRY}_contours
    java $JAVAOPTS -jar $MKGMAPJAR -c $OPTIONS \
        --output-dir=$MKGMAP_OUTPUT_DIR/$CONTINENT/${COUNTRY}_contours \
        --style-file=$STYLEFILE_CONTOURS \
        --description="GCM_${COUNTRYNAME_SHORT}_Contours_${MAPDATE_CONTOURS}" \
        --area-name="GCM_${COUNTRYNAME_SHORT}_Contours_${MAPDATE_CONTOURS}" \
        --series-name="GCM_${COUNTRYNAME_SHORT}_Contours_${MAPDATE_CONTOURS}" \
        --family-name="GCM_${COUNTRYNAME_SHORT}_Contours_${MAPDATE_CONTOURS}" \
        --family-id="$(( $FAMILY_ID+1 ))" \
        --mapname=$MAPID_CONTOURS  \
        $GMAPI \
        $TYPFILE_CONTOURS \
        -c $SPLITTER_OUTPUT_DIR/dem_pbf/$CONTINENT/$COUNTRY/template.args &> $MKGMAP_OUTPUT_DIR/mkgmap-$CONTINENT-$COUNTRY-countours.log

    mv $MKGMAP_OUTPUT_DIR/$CONTINENT/${COUNTRY}_contours/gmapsupp.img $MKGMAP_OUTPUT_DIR/GCM_Contours_${COUNTRYNAME_SHORT}_${MAPDATE_CONTOURS}.img
    cd $BASEPATH

    logger "######## End of the map courbes ...."

}

# This function splits a country map into smaller tiles.
function splitCountry {

    logger "######## Split country ...."

    java $JAVAOPTS -jar $SPLITTERJAR --precomp-sea=$SEA_DIRECTORY "$BASEPATH/data/${CONTINENT}/${COUNTRY}/${COUNTRY}-latest.osm.pbf" \
        --output-dir=$SPLITTER_OUTPUT_DIR/$CONTINENT/$COUNTRY \
        --output=pbf \
        --polygon-file=$BASEPATH/data/${CONTINENT}/${COUNTRY}/${COUNTRY}.poly \
        --description="GCM_${COUNTRYNAME_SHORT}_${MAPDATE_CONTOURS}" \
        --mapid=$MAPID &> $SPLITTER_OUTPUT_DIR/splitter-$CONTINENT-$COUNTRY.log

    logger "######## End of split country ...."
}

# This function generates a map for Garmin devices.
function generateMap {

    logger "######## Creation of the map $COUNTRY in continent $CONTINENT... with MAPDATE $MAPDATE ...."
 
    for file in $SPLITTER_OUTPUT_DIR/$CONTINENT/$COUNTRY/*.pbf; do
        DATA="$DATA $file"
    done

    OPTIONS="$BASEPATH/map_options"
   
    if [[ "$GMAPI_ENABLED" = true ]]; then
        GMAPI="--gmapi"
    else
        GMAPI=""
    fi

    mkdir -p $MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY

    cd $MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY
    java $JAVAOPTS -jar $MKGMAPJAR -c $OPTIONS \
        --output-dir=$MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY \
        --style-file=$STYLEFILE \
        --description="GCM_${COUNTRYNAME_SHORT}_${MAPDATE}" \
        --area-name="GCM_${COUNTRYNAME_SHORT}_${MAPDATE}" \
        --series-name="GCM_${COUNTRYNAME_SHORT}_${MAPDATE}" \
        --family-name="GCM_${COUNTRYNAME_SHORT}_${MAPDATE}" \
        --family-id="$(( $FAMILY_ID+2 ))" \
        --mapname=$MAPID  \
        --bounds=$BOUNDS_DIRECTORY \
        --precomp-sea=$SEA_DIRECTORY \
        --dem=$DEM_FILE \
        --dem-poly=$BASEPATH/data/${CONTINENT}/${COUNTRY}/${COUNTRY}.poly \
        $GMAPI \
        $TYPFILE \
        -c $SPLITTER_OUTPUT_DIR/$CONTINENT/$COUNTRY/template.args &> $MKGMAP_OUTPUT_DIR/mkgmap-$CONTINENT-$COUNTRY.log
    
    mv $MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY/gmapsupp.img $MKGMAP_OUTPUT_DIR/GCM_Map_${COUNTRYNAME_SHORT}_${MAPDATE}.img
    cd $BASEPATH

    logger "######## End of the map $COUNTRY in continent $CONTINENT... with MAPDATE $MAPDATE ...."

}

# This function merge a map and a contour map for Garmin devices.
function mergeContoursAndMap {

    logger "######## Merge of the map $COUNTRY in continent $CONTINENT with contours... with MAPDATE $MAPDATE ...."
 
    if [[ "$CONTOURS_ENABLED" = true ]]; then

        #for file in $SPLITTER_OUTPUT_DIR/$CONTINENT/$COUNTRY/*.pbf; do
        for file in $MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY/*.img; do
            DATA="$DATA $file"
        done

        OPTIONS="$BASEPATH/map_options"
    
        if [[ "$GMAPI_ENABLED" = true ]]; then
            GMAPI="--gmapi"
        else
            GMAPI=""
        fi

        mkdir -p $MKGMAP_OUTPUT_DIR/$CONTINENT/${COUNTRY}_merge

        CONTOURS="$MKGMAP_OUTPUT_DIR/$CONTINENT/${COUNTRY}_contours/*.img"

        cd $MKGMAP_OUTPUT_DIR/$CONTINENT/${COUNTRY}_merge
        java $JAVAOPTS -jar $MKGMAPJAR -c $OPTIONS \
            --style-file=$STYLEFILE \
            --precomp-sea=$SEA_DIRECTORY \
            --output-dir=$MKGMAP_OUTPUT_DIR/$CONTINENT/${COUNTRY}_merge \
            --bounds=$BOUNDS_DIRECTORY \
            --description="GCM_Full_${COUNTRYNAME_SHORT}_${MAPDATE}" \
            --area-name="${COUNTRYNAME_SHORT}" \
            --mapname="$(( $MAPID-99 ))"  \
            --family-name="GCM_Full_${COUNTRYNAME_SHORT}_${MAPDATE}" \
            --family-id="$(( $FAMILY_ID+4 ))" \
            --series-name="GCM_Full_${COUNTRYNAME_SHORT}_${MAPDATE}" \
            --dem=$DEM_FILE \
            --dem-poly=$BASEPATH/data/${CONTINENT}/${COUNTRY}/${COUNTRY}.poly \
            $GMAPI \
            $TYPFILE \
            -c $SPLITTER_OUTPUT_DIR/dem_pbf/$CONTINENT/$COUNTRY/template.args \
            -c $SPLITTER_OUTPUT_DIR/$CONTINENT/$COUNTRY/template.args &> $MKGMAP_OUTPUT_DIR/mkgmap-$CONTINENT-$COUNTRY-merge.log
        
        mv $MKGMAP_OUTPUT_DIR/$CONTINENT/${COUNTRY}_merge/gmapsupp.img $MKGMAP_OUTPUT_DIR/GCM_Full_${COUNTRYNAME_SHORT}_${MAPDATE}.img
        cd $BASEPATH

        logger "######## End of merge map $COUNTRY in continent $CONTINENT... with MAPDATE $MAPDATE ...."
    fi

}

# This function clean files that are not necessary and rename the final map file.
function cleanUp {

    logger "######## Clean up unnecessary files ...."

    # rm $MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY/53*.img 
    # rm $MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY/53*.tdb 
    # rm $MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY/ovm*.img 
    # rm $MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY/*.typ 
    # rm $MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY/GarminCustomMap_${COUNTRYNAME_SHORT}_${MAPDATE}.img 
    # rm $MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY/GarminCustomMap_${COUNTRYNAME_SHORT}_${MAPDATE}_mdr.img 
    # rm $MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY/GarminCustomMap_${COUNTRYNAME_SHORT}_${MAPDATE}.mdx 
    # rm $MKGMAP_OUTPUT_DIR/$CONTINENT/$COUNTRY/GarminCustomMap_${COUNTRYNAME_SHORT}_${MAPDATE}.tdb

    logger "######## End of clean up unnecessary files ...."
}

#-----------------------------

# if [[ ! -z "$COUNTRY_SUBZONE" ]]; then # if subzone is set
#     COUNTRY+="/$COUNTRY_SUBZONE"
#     logger "COUNTRY is $COUNTRY"
# fi


# Check if all needed arguments are provided
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <continent> <country> <countryname_short> <country_subzone> <mapid>"
    exit 1
fi

init

FAMILY_ID=$(( $SEEDMAP+${id[$CONTINENT]}*100 ))
MAPID=$(( $FAMILY_ID*1000+2 ))
MAPID_CONTOURS=$(( $MAPID+5000 ))

logger "FAMILY_ID is $FAMILY_ID"
logger "MAPID is $MAPID"
logger "MAPID_CONTOURS is $MAPID_CONTOURS"

# Do only 1x or if you change for a new country !
# hgtToPBF
# splitDEMToOSM

# Do every time
generateContours
splitCountry
generateMap
mergeContoursAndMap

# cleanUp
