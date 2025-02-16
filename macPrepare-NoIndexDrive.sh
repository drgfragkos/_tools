#!/bin/bash
# macPrepare-NoIndexDrive.sh
#
# This script helps you prepare an external USB drive on macOS so that Spotlight will not index it.
# It:
#   1) Lists mounted volumes (usually found under /Volumes).
#   2) Lets you select a drive by its enumerated Dev ID.
#   3) Offers to create a hidden file (.metadata_never_index) at the drive’s root.
#   4) Offers to recursively delete any .Spotlight-V100 directories (reporting found, deleted, and skipped).
#   5) Displays the current mdutil (Spotlight indexing) status for the drive and offers to toggle it.
#
# IMPORTANT:
# After the script finishes, please follow these additional instructions:
#   • Open System Settings (or System Preferences) → Spotlight (or Siri & Spotlight) → Privacy
#     and add your drive to the "no indexing" list if desired.
#   • Eject and reconnect the drive to ensure the changes take effect.
#   • You can also use the mdutil option above to enable or disable indexing.
#
# Written for macOS.
echo "========== External Drive Preparation Script =========="

# --- Step 1: Enumerate mounted volumes under /Volumes ---
echo "Enumerating mounted volumes in /Volumes:"
volumes=()
index=0

# List each directory in /Volumes (skip if empty)
for vol in /Volumes/*; do
    if [ -d "$vol" ]; then
        volumes+=("$vol")
        volname=$(basename "$vol")
        # Get disk usage info (skip the header line)
        df_info=$(df -h "$vol" | tail -1)
        echo "[$index] Volume: $volname"
        echo "     Info: $df_info"
        echo ""
        ((index++))
    fi
done

# Check if any volumes were found
if [ ${#volumes[@]} -eq 0 ]; then
    echo "No volumes found in /Volumes. Exiting."
    exit 1
fi

# --- Step 2: Prompt the user to choose a volume by its Dev ID ---
read -p "Enter the Dev ID number of the drive you want to prepare: " choice
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -ge "${#volumes[@]}" ]; then
    echo "Invalid selection. Exiting."
    exit 1
fi

drive="${volumes[$choice]}"
driveName=$(basename "$drive")
echo ""
echo "You selected: $drive (Volume Name: $driveName)"
echo ""

# --- Step 3: Offer to create .metadata_never_index file in the drive root ---
metadataCreated=false
read -p "Do you want to create the .metadata_never_index file in the drive root? (y/n): " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    metaFile="$drive/.metadata_never_index"
    # Check if we can write to the drive root
    if [ -w "$drive" ]; then
        # Create (or overwrite) the file and mark it hidden.
        # On macOS, files starting with a dot are hidden; you can also use 'chflags hidden'
        touch "$metaFile" 2>/dev/null
        if [ $? -eq 0 ]; then
            chflags hidden "$metaFile"
            metadataCreated=true
            echo "Created hidden file: $metaFile"
        else
            echo "Error: Could not create $metaFile"
        fi
    else
        echo "Error: No write access to $drive"
    fi
fi

echo ""

# --- Step 4: Offer to delete .Spotlight-V100 directories/files recursively ---
found_count=0
deleted_count=0
skipped_count=0
read -p "Do you want to remove all .Spotlight-V100 folders/files recursively from $drive? (y/n): " remAnswer
if [[ "$remAnswer" =~ ^[Yy]$ ]]; then
    echo "Searching for .Spotlight-V100 items in $drive ..."
    # Use find to locate directories or files named exactly ".Spotlight-V100"
    # Using IFS to safely iterate over names with spaces.
    IFS=$'\n'
    items=( $(find "$drive" -name ".Spotlight-V100" 2>/dev/null) )
    unset IFS
    found_count=${#items[@]}
    if [ $found_count -gt 0 ]; then
        for item in "${items[@]}"; do
            echo "Deleting: $item"
            rm -rf "$item"
            if [ $? -eq 0 ]; then
                ((deleted_count++))
            else
                echo "Warning: Could not delete $item"
                ((skipped_count++))
            fi
        done
    else
        echo "No .Spotlight-V100 files/folders found on $drive."
    fi
fi

echo ""

# --- Step 5: Show current Spotlight indexing status (using mdutil) and offer to change it ---
echo "Checking current Spotlight indexing status on $drive..."
mdutil_status=$(mdutil -s "$drive" 2>/dev/null)
if [ -z "$mdutil_status" ]; then
    echo "Could not determine indexing status for $drive. (Maybe you need sudo privileges?)"
else
    echo "Current mdutil status for $drive:"
    echo "$mdutil_status"
fi
echo ""

read -p "Would you like to change the Spotlight indexing status for $drive? (E)nable, (D)isable, or leave as is (N): " mdutilChoice
case "$mdutilChoice" in
    [Ee]* )
        echo "Enabling indexing on $drive..."
        sudo mdutil -i on "$drive"
        ;;
    [Dd]* )
        echo "Disabling indexing on $drive..."
        sudo mdutil -i off "$drive"
        ;;
    * )
        echo "Leaving mdutil setting as is."
        ;;
esac

echo ""
echo "Updated mdutil status for $drive:"
mdutil -s "$drive" 2>/dev/null
echo ""

# --- Final Report and Instructions ---
echo "========== FINAL REPORT =========="
if $metadataCreated; then
    echo "Special File .metadata_never_index successfully written in the root of the disk with Dev ID: $choice"
else
    echo "Special File .metadata_never_index was NOT created (Dev ID: $choice)"
fi

if [[ "$remAnswer" =~ ^[Yy]$ ]]; then
    echo "Total Number of .Spotlight-V100 items found : $found_count"
    echo "Number of .Spotlight-V100 items deleted     : $deleted_count"
    echo "Number of .Spotlight-V100 items skipped      : $skipped_count"
fi

echo ""
echo "ADDITIONAL INSTRUCTIONS:"
echo "1. To further prevent macOS from indexing this drive, you can manually add it to the Spotlight Privacy list."
echo "   • On macOS Ventura or later: Open System Settings → Siri & Spotlight → Privacy → Spotlight Privacy, and add the drive."
echo "   • On earlier macOS versions: Open System Preferences → Spotlight → Privacy, and add the drive."
echo ""
echo "2. After this process completes, EJECT the drive and reconnect it to ensure that all changes take effect."
echo "3. The mdutil option above can enable or disable indexing on the drive."
echo ""
echo "Script complete!"
