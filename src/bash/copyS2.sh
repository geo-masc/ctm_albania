#!/bin/bash

# Set source and destination base paths
S3_BASE="/eodata/Sentinel-2/MSI/L1C_N0500"
DEST_BASE="/mnt/mowing/albania/level1/images/sentinel"

# Create destination directory if it doesn't exist
mkdir -p "${DEST_BASE}"

# Read the input file line by line
while IFS= read -r filename; do
    # Skip empty lines
    [ -z "$filename" ] && continue
    
    # Extract date components from filename
    # Format: S2A_MSIL1C_YYYYMMDDTHHMMSS_*
    if [[ $filename =~ ^S2[AB]_MSIL1C_([0-9]{4})([0-9]{2})([0-9]{2})T ]]; then
        YEAR="${BASH_REMATCH[1]}"
        MONTH="${BASH_REMATCH[2]}"
        DAY="${BASH_REMATCH[3]}"
        
        # Construct source path
        S3_PATH="${S3_BASE}/${YEAR}/${MONTH}/${DAY}/${filename}"
        
        # Execute s3cmd sync command
        echo "Syncing ${filename}..."
        rsync "${S3_PATH}" "${DEST_BASE}/"
    fi
done < "/mnt/mowing/albania/level1/images/copy_s2_files.txt"

echo "Sync completed!"