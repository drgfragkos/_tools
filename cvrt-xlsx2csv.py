#!/usr/bin/env python3

# ---------------------------------------------------------------
# Title: Convert XLSX to CSV (Cross-Platform)
# Description:
#   A small Python tool to convert a single-sheet Excel (.xlsx)
#   file to CSV. Designed to work on both Linux and Windows 
#   (requires Python + openpyxl installed). 
#
# Dependencies:
#   pip install openpyxl
#
# Usage:
#   cvrt-xlsx2csv.py [OPTIONS]
# 
# Examples:
#   python cvrt-xlsx2csv.py -i myfile.xlsx
#   echo "myfile.xlsx" | python cvrt-xlsx2csv.py
#   python cvrt-xlsx2csv.py -i myfile.xlsx --timestamp
#   python cvrt-xlsx2csv.py -i myfile.xlsx -o output.csv
#   echo "myfile.xlsx" | python cvrt-xlsx2csv.py -o "new file.csv" --timestamp
#
# Author: (c) drgfragkos 2024
# ---------------------------------------------------------------

import sys
import os
import argparse
import datetime
import csv

def check_libraries():
    """
    Check if 'openpyxl' is installed. If not, print instructions and exit.
    """
    try:
        import openpyxl  # Try importing within this function
    except ImportError:
        print("ERROR: The 'openpyxl' library is not installed.\n")
        print("Please install it by running one of the following commands:")
        print("    pip install openpyxl\nor\n    pip3 install openpyxl\n")
        sys.exit(1)

def main():
    # Verify library dependencies
    check_libraries()
    import openpyxl  # Import again inside main after the check

    parser = argparse.ArgumentParser(
        description="Convert a single-sheet .xlsx file to .csv."
    )
    
    parser.add_argument(
        "-i", "--input",
        help="Path to the input .xlsx file."
    )
    parser.add_argument(
        "-o", "--output",
        help="Specify an optional output CSV filename. (If used with --timestamp, timestamp will be appended)."
    )
    parser.add_argument(
        "-t", "--timestamp",
        action="store_true",
        help="Append a timestamp to the output filename (e.g. my-YYYYMMDDHHMMSS.csv)."
    )
    args = parser.parse_args()

    # 1. Determine the input .xlsx filename
    if args.input:
        xlsx_path = args.input.strip()
    else:
        # If no argument was given, try to read from stdin
        # (e.g. echo my.xlsx | python cvrt-xlsx2csv.py)
        if not sys.stdin.isatty():
            xlsx_path = sys.stdin.read().strip()
        else:
            print("Error: No input file provided. Use -i or pipe the filename.")
            sys.exit(1)
    
    # 2. Validate that the file exists
    xlsx_path = os.path.abspath(xlsx_path)
    if not os.path.isfile(xlsx_path):
        print(f"Error: File not found: {xlsx_path}")
        sys.exit(1)
    
    # 3. Determine the output CSV filename
    #    If user provided an --output, use that. Otherwise, default to
    #    "basename.csv" or "basename-timestamp.csv".

    # Prepare timestamp string if needed
    timestamp_str = datetime.datetime.now().strftime("%Y%m%d%H%M%S") if args.timestamp else ""

    if args.output:
        # If user specified an output file:
        outBase, outExt = os.path.splitext(args.output.strip())
        # If no extension was provided, default to .csv
        if not outExt:
            outExt = ".csv"
        
        if args.timestamp:
            csv_path = f"{outBase}-{timestamp_str}{outExt}"
        else:
            csv_path = f"{outBase}{outExt}"
    
    else:
        # No output file specified: use same base name as .xlsx
        base_name, _ext = os.path.splitext(xlsx_path)
        if args.timestamp:
            csv_path = f"{base_name}-{timestamp_str}.csv"
        else:
            csv_path = f"{base_name}.csv"
    
    # 4. Read .xlsx and write to .csv
    try:
        workbook = openpyxl.load_workbook(xlsx_path, read_only=True, data_only=True)
        sheet = workbook.active

        with open(csv_path, mode="w", newline="", encoding="utf-8") as csv_file:
            writer = csv.writer(csv_file)
            for row in sheet.iter_rows(values_only=True):
                writer.writerow(row)
        
        print(f"Successfully converted {xlsx_path} -> {csv_path}")
    except Exception as e:
        print(f"Error converting file: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
