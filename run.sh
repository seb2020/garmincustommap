#!/bin/bash

# Check if two arguments are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <continent> <country> <countryname_short>"
    exit 1
fi

continent=$1
country=$2
countryname_short=$3

# Run the generate_map.sh script with the provided arguments
./data/generate_map.sh "$continent" "$country" "$countryname_short"