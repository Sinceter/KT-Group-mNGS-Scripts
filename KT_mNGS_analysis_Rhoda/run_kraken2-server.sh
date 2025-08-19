#!/bin/bash

# Kraken2 Server Script
# Version: 1.0
# Description: Starts Kraken2 server with specified database and confidence score

# Source configuration file
CONFIG_FILE="./config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Configuration file $CONFIG_FILE not found"
    exit 1
fi
source "$CONFIG_FILE"

# Validate arguments
if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <kraken2_db> <confidence_score>"
    echo "  kraken2_db: ppf, eupath, or silva"
    echo "  confidence_score: e.g., 0.0, 0.1"
    exit 1
fi

kraken2_db="$1"
cs="$2"

echo "======== Starting Kraken2-server ========"
echo "Database: $kraken2_db"
echo "Confidence score: $cs"

case "$kraken2_db" in
    ppf)
        "$KRAKEN2_SERVER_EXC" --db "$K2_PLUSPF_DB" --thread-pool "$NTHREADS" --port 8088 --confidence "$cs" --report-kmer --host-ip localhost --no-stats
        ;;
    eupath)
        "$KRAKEN2_SERVER_EXC" --db "$K2_EUPATH_DB" --thread-pool "$NTHREADS" --port 8088 --confidence "$cs" --report-kmer --host-ip localhost --no-stats
        ;;
    silva)
        "$KRAKEN2_SERVER_EXC" --db "$K2_SILVA_DB" --thread-pool "$NTHREADS" --port 8088 --confidence "$cs" --report-kmer --host-ip localhost --no-stats
        ;;
    *)
        echo "ERROR: Database '$kraken2_db' does not exist! Choose ppf, eupath, or silva."
        exit 1
        ;;
esac
