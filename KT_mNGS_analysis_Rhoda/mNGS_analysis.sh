#!/bin/bash

# Metagenomic NGS Analysis Script
# Version: 1.0 | Author: Rhoda Leung
# Description: Bash script for processing Nanopore raw data to generate Kraken2 and Bracken reports for metagenomic analysis.

# Display banner
echo -e "\033[1;34m====================================\033[0m"
echo -e "\033[1;34m       Metagenomic NGS Analysis      \033[0m"
echo -e "\033[1;34m====================================\033[0m"
echo -e "\033[1mGenerating Kraken2 and Bracken reports from Nanopore raw data\033[0m"
echo -e "\033[1mVersion: 1.0 | Author: Rhoda Leung\033[0m"
echo -e ""

# Source configuration file
CONFIG_FILE="./config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Configuration file $CONFIG_FILE not found"
    exit 1
fi
source "$CONFIG_FILE"

# Function to display help message
display_help() {
    echo "Usage: $0 --start_bc <number> --end_bc <number> --raw_dir <path[,path,...]> [--data_hps <hours>] [--kraken2_db <database>] [--csv <file>] [--filter_seq <length>]"
    echo ""
    echo "Required options:"
    echo "  --start_bc: Starting barcode number (e.g., 05, two digits with leading zero)"
    echo "  --end_bc: Ending barcode number (e.g., 07, two digits with leading zero)"
    echo "  --raw_dir: Comma-separated list of raw data directories"
    echo ""
    echo "Optional parameters:"
    echo "  --data_hps: Data hours post-start (default: $DATA_HPS_DEFAULT)"
    echo "  --kraken2_db: Database choice (ppf+eupath [default], ppf_only, ppf+eupath+silva)"
    echo "  --csv: CSV file with columns: barcode,sample_name"
    echo "  --filter_seq: Minimum read length for sequence filtering (e.g., 1000; if not set, filtering is skipped)"
    exit 0
}

# Initialize log file
LOG_FILE="metagenomics_analysis_$(date +%Y%m%d_%H%M%S).log"
echo "Metagenomics Analysis Log" > "$LOG_FILE"
echo "Started: $(date)" >> "$LOG_FILE"
echo "Command-line invocation: $0 $@" >> "$LOG_FILE"
echo "Options used:" >> "$LOG_FILE"
echo "Configuration: $CONFIG_FILE" >> "$LOG_FILE"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Default parameters
DATA_HPS="$DATA_HPS_DEFAULT"
OUTPUT_DIR="${DATA_HPS}hps"
RAW_DIR=""
CSV_FILE=""
KRAKEN2_DB="ppf+eupath"
FILTER_SEQ=""

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -h|--help) display_help ;;
        --start_bc) start_bc="$2"; log_message "Option --start_bc: $2"; shift 2 ;;
        --end_bc) end_bc="$2"; log_message "Option --end_bc: $2"; shift 2 ;;
        --data_hps) DATA_HPS="$2"; OUTPUT_DIR="${DATA_HPS}hps"; log_message "Option --data_hps: $2"; shift 2 ;;
        --kraken2_db) KRAKEN2_DB="$2"; log_message "Option --kraken2_db: $2"; shift 2 ;;
        --csv) CSV_FILE="$2"; log_message "Option --csv: $2"; shift 2 ;;
        --raw_dir) RAW_DIR="$2"; log_message "Option --raw_dir: $2"; shift 2 ;;
        --filter_seq) FILTER_SEQ="$2"; log_message "Option --filter_seq: $2"; shift 2 ;;
        *) log_message "ERROR: Unknown parameter: $1"; display_help ;;
    esac
done

# Validate required parameters
if [[ -z "$start_bc" || -z "$end_bc" || -z "$RAW_DIR" ]]; then
    log_message "ERROR: --start_bc, --end_bc, and --raw_dir are required"
    display_help
fi

# Validate barcode format (two digits, numeric, with leading zeros)
if ! [[ "$start_bc" =~ ^[0-9]{2}$ ]] || ! [[ "$end_bc" =~ ^[0-9]{2}$ ]]; then
    log_message "ERROR: --start_bc and --end_bc must be two-digit numbers (e.g., 05, 07)"
    display_help
fi
if [[ "$start_bc" -gt "$end_bc" ]]; then
    log_message "ERROR: --start_bc must be less than or equal to --end_bc"
    display_help
fi
if [[ "$start_bc" -lt 1 || "$end_bc" -gt 99 ]]; then
    log_message "ERROR: --start_bc and --end_bc must be between 01 and 99"
    display_help
fi

# Create output directory
mkdir -p "$OUTPUT_DIR" || { log_message "ERROR: Failed to create output directory $OUTPUT_DIR"; exit 1; }
mv "$LOG_FILE" "$OUTPUT_DIR/" || { log_message "ERROR: Failed to move log file"; exit 1; }
LOG_FILE="$OUTPUT_DIR/$(basename "$LOG_FILE")"

# Convert comma-separated RAW_DIR to array
IFS=',' read -r -a RAW_DIRS <<< "$RAW_DIR"

# Function to get sample name from CSV based on barcode
get_file_prefix() {
    local bc="$1"
    if [[ -n "$CSV_FILE" && -f "$CSV_FILE" ]]; then
        # Extract the numeric part of the barcode, preserving leading zeros
        local bc_num=$(echo "$bc" | sed 's/.*barcode//')
        # Remove carriage returns (\r) from CSV and extract sample name
        cat "$CSV_FILE" | tr -d '\r' | awk -F',' -v b="$bc_num" '$1 == b {print $2}' | head -n 1
    else
        echo ""
    fi
}

# Function to rename Kraken2 and Bracken reports
rename_reports() {
    log_message "Renaming Kraken2 and Bracken reports with sample names"
    for bc in $(seq -f "%02g" "$start_bc" "$end_bc"); do
        local barcode="barcode$bc"
        local bc_num="$bc"  # Use the formatted barcode with leading zeros
        local prefix=$(get_file_prefix "$barcode")
        if [[ -z "$prefix" ]]; then
            log_message "WARNING: No sample name found for $barcode in CSV, skipping renaming"
            continue
        fi

        # Rename Kraken2 reports (unfiltered)
        for report in "$OUTPUT_DIR"/kraken2/*/*nohuman_${barcode}*.kraken2_report; do
            [[ -f "$report" ]] || continue
            local report_name=$(basename "$report")
            local new_name="${prefix}_${report_name}"
            mv "$report" "$(dirname "$report")/$new_name" 2>> "$LOG_FILE"
            if [[ $? -eq 0 ]]; then
                log_message "Renamed $report to $(dirname "$report")/$new_name"
            else
                log_message "ERROR: Failed to rename $report"
            fi
        done

        # Rename Kraken2 reports (filtered, if applicable)
        if [[ -n "$FILTER_SEQ" ]]; then
            for report in "$OUTPUT_DIR"/kraken2/*/filtered_${FILTER_SEQ}/*nohuman_${barcode}*.kraken2_report; do
                [[ -f "$report" ]] || continue
                local report_name=$(basename "$report")
                local new_name="${prefix}_${report_name}"
                mv "$report" "$(dirname "$report")/$new_name" 2>> "$LOG_FILE"
                if [[ $? -eq 0 ]]; then
                    log_message "Renamed $report to $(dirname "$report")/$new_name"
                else
                    log_message "ERROR: Failed to rename $report"
                fi
            done
        fi

        # Rename Bracken abundance files (.bracken, unfiltered)
        for report in "$OUTPUT_DIR"/bracken/*/*nohuman_${barcode}*.bracken; do
            [[ -f "$report" ]] || continue
            local report_name=$(basename "$report")
            local new_name="${prefix}_${report_name}"
            mv "$report" "$(dirname "$report")/$new_name" 2>> "$LOG_FILE"
            if [[ $? -eq 0 ]]; then
                log_message "Renamed $report to $(dirname "$report")/$new_name"
            else
                log_message "ERROR: Failed to rename $report"
            fi
        done

        # Rename Bracken report files (_bracken_species.kraken2_report, unfiltered)
        for report in "$OUTPUT_DIR"/bracken/*/*nohuman_${barcode}*_bracken_species.kraken2_report; do
            [[ -f "$report" ]] || continue
            local report_name=$(basename "$report")
            local new_name="${prefix}_${report_name}"
            mv "$report" "$(dirname "$report")/$new_name" 2>> "$LOG_FILE"
            if [[ $? -eq 0 ]]; then
                log_message "Renamed $report to $(dirname "$report")/$new_name"
            else
                log_message "ERROR: Failed to rename $report"
            fi
        done

        # Rename Bracken abundance files (.bracken, filtered, if applicable)
        if [[ -n "$FILTER_SEQ" ]]; then
            for report in "$OUTPUT_DIR"/bracken/*/filtered_${FILTER_SEQ}/*nohuman_${barcode}*.bracken; do
                [[ -f "$report" ]] || continue
                local report_name=$(basename "$report")
                local new_name="${prefix}_${report_name}"
                mv "$report" "$(dirname "$report")/$new_name" 2>> "$LOG_FILE"
                if [[ $? -eq 0 ]]; then
                    log_message "Renamed $report to $(dirname "$report")/$new_name"
                else
                    log_message "ERROR: Failed to rename $report"
                fi
            done
        fi

        # Rename Bracken report files (_bracken_species.kraken2_report, filtered, if applicable)
        if [[ -n "$FILTER_SEQ" ]]; then
            for report in "$OUTPUT_DIR"/bracken/*/filtered_${FILTER_SEQ}/*nohuman_${barcode}*_bracken_species.kraken2_report; do
                [[ -f "$report" ]] || continue
                local report_name=$(basename "$report")
                local new_name="${prefix}_${report_name}"
                mv "$report" "$(dirname "$report")/$new_name" 2>> "$LOG_FILE"
                if [[ $? -eq 0 ]]; then
                    log_message "Renamed $report to $(dirname "$report")/$new_name"
                else
                    log_message "ERROR: Failed to rename $report"
                fi
            done
        fi
    done
}

# Function to remove human reads
remove_human_reads() {
    local barcode="$1"
    local temp_fastq=$(mktemp)
    local found_files=false

    log_message "Processing $barcode for human reads removal"

    # Collect FASTQ files
    for raw_dir in "${RAW_DIRS[@]}"; do
        local input_dir="no_sample_id/$raw_dir/fastq_pass/$barcode"
        if [[ -d "$input_dir" && -n "$(ls "$input_dir"/*.fastq.gz 2>/dev/null)" ]]; then
            zcat "$input_dir"/*.fastq.gz >> "$temp_fastq" 2>> "$LOG_FILE"
            if [[ $? -eq 0 ]]; then
                found_files=true
            else
                log_message "ERROR: Failed to process input files for $barcode in $raw_dir"
            fi
        else
            log_message "WARNING: No fastq.gz files found for $barcode in $input_dir"
        fi
    done

    if [[ "$found_files" = false ]]; then
        rm "$temp_fastq"
        return 1
    fi

    # Compress concatenated FASTQ
    cat "$temp_fastq" | "$PIGZ_EXC" -9 > "$OUTPUT_DIR/$barcode.fastq.gz" 2>> "$LOG_FILE"
    rm "$temp_fastq"
    if [[ $? -ne 0 ]]; then
        log_message "ERROR: Failed to create $OUTPUT_DIR/$barcode.fastq.gz"
        return 1
    fi

    # Remove human reads
    zcat "$OUTPUT_DIR/$barcode.fastq.gz" | "$MINIMAP2_EXC" -t "$NTHREADS" -ax map-ont "$HUMAN_MMI" - | \
        "$SAMTOOLS_EXC" view -bS -f 4 | "$SAMTOOLS_EXC" fastq - | "$PIGZ_EXC" -9 > "$OUTPUT_DIR/nohuman_$barcode.fastq.gz" 2>> "$LOG_FILE"
    if [[ $? -ne 0 ]]; then
        log_message "ERROR: Failed to remove human reads for $barcode"
        return 1
    fi
    return 0
}

# Function for sequence length filtering
filter_sequences() {
    local file="$1"
    local min_length="$2"
    local output_dir="$3"
    local file_name=$(basename "$file" .fastq.gz)
    local output="$output_dir/${file_name}_min${min_length}.fastq.gz"

    log_message "Filtering $file with minimum length $min_length bp"
    "$SEQKIT_EXC" seq -m "$min_length" -g "$file" | "$PIGZ_EXC" -9 > "$output" 2>> "$LOG_FILE"
    if [[ $? -eq 0 ]]; then
        log_message "Created $output with minimum length $min_length bp"
    else
        log_message "ERROR: Failed to filter $file with minimum length $min_length bp"
        return 1
    fi
    return 0
}

# Function for Kraken2 analysis
run_kraken2_analysis() {
    local db_type="$1"
    local cs="$2"
    local db_name="$3"
    local wait_time="$4"
    local db_path

    case "$db_type" in
        ppf) db_path="$K2_PLUSPF_DB" ;;
        eupath) db_path="$K2_EUPATH_DB" ;;
        silva) db_path="$K2_SILVA_DB" ;;
        *) log_message "ERROR: Invalid database type: $db_type"; exit 1 ;;
    esac

    log_message "Starting $db_name analysis with cs=$cs"
    bash run_kraken2-server.sh "$db_type" "$cs" &>> "$LOG_FILE" &
    local server_pid=$!
    sleep "$wait_time"

    # Process unfiltered reads
    mkdir -p "$OUTPUT_DIR/kraken2/$cs" || { log_message "ERROR: Failed to create kraken2 directory"; exit 1; }
    for file in "$OUTPUT_DIR"/nohuman_barcode*.fastq.gz; do
        [[ -f "$file" ]] || continue
        local file_name=$(basename "$file" .fastq.gz)
        local output_name="$file_name"

        log_message "Processing unfiltered $file with $db_name cs=$cs"
        "$KRAKEN2_CLIENT_EXC" --sequence "$file" \
            --report "$OUTPUT_DIR/kraken2/$cs/${output_name}.${db_type}.${cs}.kraken2_report" \
            --port 8088 | "$PIGZ_EXC" -9 > "$OUTPUT_DIR/kraken2/$cs/${output_name}.${db_type}.${cs}.kraken2_output.gz" 2>> "$LOG_FILE"

        grep -v '^%' "$OUTPUT_DIR/kraken2/$cs/${output_name}.${db_type}.${cs}.kraken2_report" > \
            "$OUTPUT_DIR/kraken2/$cs/server_${output_name}.${db_type}.${cs}.kraken2_report" 2>> "$LOG_FILE"
    done

    # Process filtered reads if --filter_seq is specified
    if [[ -n "$FILTER_SEQ" ]]; then
        mkdir -p "$OUTPUT_DIR/kraken2/$cs/filtered_$FILTER_SEQ" || { log_message "ERROR: Failed to create kraken2 filtered_$FILTER_SEQ directory"; exit 1; }
        for file in "$OUTPUT_DIR/filtered_$FILTER_SEQ"/nohuman_barcode*_min${FILTER_SEQ}.fastq.gz; do
            [[ -f "$file" ]] || continue
            local file_name=$(basename "$file" .fastq.gz)
            local output_name="$file_name"

            log_message "Processing filtered $file with $db_name cs=$cs"
            "$KRAKEN2_CLIENT_EXC" --sequence "$file" \
                --report "$OUTPUT_DIR/kraken2/$cs/filtered_$FILTER_SEQ/${output_name}.${db_type}.${cs}.kraken2_report" \
                --port 8088 | "$PIGZ_EXC" -9 > "$OUTPUT_DIR/kraken2/$cs/filtered_$FILTER_SEQ/${output_name}.${db_type}.${cs}.kraken2_output.gz" 2>> "$LOG_FILE"

            grep -v '^%' "$OUTPUT_DIR/kraken2/$cs/filtered_$FILTER_SEQ/${output_name}.${db_type}.${cs}.kraken2_report" > \
                "$OUTPUT_DIR/kraken2/$cs/filtered_$FILTER_SEQ/server_${output_name}.${db_type}.${cs}.kraken2_report" 2>> "$LOG_FILE"
        done
    fi

    kill "$server_pid" 2>> "$LOG_FILE"
    ps aux | grep 'kraken2_server' | awk '{print $2}' | xargs kill -9 2>> "$LOG_FILE"
}

# Function for Bracken analysis
run_bracken_analysis() {
    local db_path="$1"
    local db_name="$2"
    local file_pattern="$3"
    local output_subdir="$4"

    for report in $(find "$OUTPUT_DIR/kraken2" -type f -name "$file_pattern" ${output_subdir:+-path "*/$output_subdir/*"}); do
        local report_name=$(basename "$report" .kraken2_report)
        local cs=$(echo "$report_name" | grep -o '0\.[0-1]')

        log_message "Running Bracken for ${output_subdir:+filtered }${report_name} ($db_name)"
        "$BRACKEN_EXC" -d "$db_path" -i "$report" \
            -o "$OUTPUT_DIR/bracken/$cs/${output_subdir}/${report_name}.bracken" \
            -w "$OUTPUT_DIR/bracken/$cs/${output_subdir}/${report_name}_bracken_species.kraken2_report" \
            -r 100 -l 'S' -t 0 >> "$LOG_FILE" 2>&1
    done
}

# Main pipeline
# Copy Kraken2 server script
log_message "Copying Kraken2 server script"
cp run_kraken2-server.sh "$OUTPUT_DIR/" || { log_message "ERROR: Failed to copy Kraken2 server script"; exit 1; }

# Human reads removal
for bc in $(seq -f "%02g" "$start_bc" "$end_bc"); do
    remove_human_reads "barcode$bc"
done

# Sequence length filtering (optional)
if [[ -n "$FILTER_SEQ" ]]; then
    FILTERED_DIR="$OUTPUT_DIR/filtered_$FILTER_SEQ"
    mkdir -p "$FILTERED_DIR" || { log_message "ERROR: Failed to create filtered_$FILTER_SEQ directory"; exit 1; }
    for file in "$OUTPUT_DIR"/nohuman_barcode*.fastq.gz; do
        [[ -f "$file" ]] || { log_message "No nohuman read files found for filtering"; continue; }
        filter_sequences "$file" "$FILTER_SEQ" "$FILTERED_DIR"
    done
fi

# Activate Conda environment
source "$CONDA_EXC"
conda activate kraken2 >> "$LOG_FILE" 2>&1 || { log_message "ERROR: Failed to activate conda environment"; exit 1; }

# Kraken2 classification
log_message "Starting taxonomic classification with Kraken2 using $KRAKEN2_DB"
#declare -a cs_values=("0.1" "0.2" "0.3" "0.4" "0.5")
declare -a cs_values=("0.1")
case "$KRAKEN2_DB" in
    "ppf_only")
        for cs in "${cs_values[@]}"; do
            run_kraken2_analysis "ppf" "$cs" "PlusPF" 300
        done
        ;;
    "ppf+eupath")
        for cs in "${cs_values[@]}"; do
            run_kraken2_analysis "ppf" "$cs" "PlusPF" 300
            run_kraken2_analysis "eupath" "$cs" "Eupath" 150
        done
        ;;
    "ppf+eupath+silva")
        for cs in "${cs_values[@]}"; do
            run_kraken2_analysis "ppf" "$cs" "PlusPF" 300
            run_kraken2_analysis "eupath" "$cs" "Eupath" 150
            run_kraken2_analysis "silva" "$cs" "Silva" 150
        done
        ;;
    *)
        log_message "ERROR: Invalid kraken2_db option: $KRAKEN2_DB"
        exit 1
        ;;
esac

conda deactivate >> "$LOG_FILE" 2>&1

# Bracken analysis
log_message "Starting Bracken analysis"

mkdir -p "$OUTPUT_DIR/bracken/${cs}" || \
    { log_message "ERROR: Failed to create bracken directories"; exit 1; }

if [[ -n "$FILTER_SEQ" ]]; then
    mkdir -p "$OUTPUT_DIR/bracken/0.0/filtered_$FILTER_SEQ" "$OUTPUT_DIR/bracken/0.1/filtered_$FILTER_SEQ" || \
        { log_message "ERROR: Failed to create filtered bracken directories"; exit 1; }
fi

# Process Bracken reports
run_bracken_analysis "$K2_PLUSPF_DB" "PlusPF" "nohuman_barcode*.ppf.*.kraken2_report" ""
if [[ -n "$FILTER_SEQ" ]]; then
    run_bracken_analysis "$K2_PLUSPF_DB" "PlusPF" "nohuman_barcode*_min${FILTER_SEQ}.ppf.*.kraken2_report" "filtered_$FILTER_SEQ"
fi
run_bracken_analysis "$K2_EUPATH_DB" "Eupath" "nohuman_barcode*.eupath.*.kraken2_report" ""
if [[ -n "$FILTER_SEQ" ]]; then
    run_bracken_analysis "$K2_EUPATH_DB" "Eupath" "nohuman_barcode*_min${FILTER_SEQ}.eupath.*" "filtered_$FILTER_SEQ"
fi
run_bracken_analysis "$K2_SILVA_DB" "Silva" "nohuman_barcode*.silva.*" ""
if [[ -n "$FILTER_SEQ" ]]; then
    run_bracken_analysis "$K2_SILVA_DB" "Silva" "nohuman_barcode*_min${FILTER_SEQ}.*" "filtered_$FILTER_SEQ"
fi

# Rename Kraken2 and Bracken reports with sample names from CSV
if [[ -n "$CSV_FILE" && -f "$CSV_FILE" ]]; then
    rename_reports
else
    log_message "No CSV file provided, skipping report renaming"
fi

# Organize Bracken output
mv "$OUTPUT_DIR/bracken/"*0.1*.bracken "$OUTPUT_DIR/bracken/0.1/" 2>> "$LOG_FILE"
mv "$OUTPUT_DIR/bracken/"*0.1*_bracken_species.kraken2_report "$OUTPUT_DIR/bracken/0.1/" 2>> "$LOG_FILE"
if [[ -n "$FILTER_SEQ" ]]; then
    mv "$OUTPUT_DIR/bracken/0.1/"*min${FILTER_SEQ}*.bracken "$OUTPUT_DIR/bracken/0.1/filtered_$FILTER_SEQ/" 2>> "$LOG_FILE"
    mv "$OUTPUT_DIR/bracken/0.1/"*min${FILTER_SEQ}*_bracken_species.kraken2_report "$OUTPUT_DIR/bracken/0.1/filtered_$FILTER_SEQ/" 2>> "$LOG_FILE"
fi

log_message "Analysis completed successfully"
echo "End: $(date)" >> "$LOG_FILE"
