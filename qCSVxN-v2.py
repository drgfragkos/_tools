import csv
import sys
import argparse
import os
import fcntl
import time
import signal

"""
Title:
Dynamic CSV Query Tool with Flexible Output Delimiters and Advanced Data Handling for Efficiency (qCSVxN-v2.py - Version 2.0)

Description:
This Python script allows users to perform dynamic lookups in a CSV file and retrieve specific columns of data.
Users can specify a search string, the column to search within, and the column value(s) to return. The script
supports both single and multiple column returns and allows flexible input and output delimiters. The output
delimiter is inferred from the user-provided `-mcol` flag. Additionally, the order of the columns specified
in the `-mcol` flag is respected in the output, ensuring the data is returned in the exact sequence specified
by the user.

Special Note on Delimiter:
    By default, the script uses a semicolon (;) as the input CSV delimiter. However, the user can override
    this via the `-d/--delimiter` flag. As a special case, passing `-d "\t"` means that the CSV file is
    tab-delimited. Other single-character delimiters such as commas, pipes, or slashes can also be used
    (e.g., -d ",", -d "|", -d "/").

Usage:
    python script.py -i data.csv -sstr "example.com" -scol 1 -rcol 2                  # default delimiter is ';'
    python script.py -i data.csv -sstr "example.com" -scol 1 -rcol 2 -d ","           # specify comma as input delimiter
    python script.py -i data.csv -sstr "example.com" -scol 1 -rcol 2 -d "\t"          # specify TAB (as a two-character string using "\t") as the input delimiter
    python script.py -i data.csv -sstr "example.com" -scol 1 -mcol "3;2;4"
    python script.py -i data.csv -sstr "example.com" -scol 1 -mcol "3,2,4"
    python script.py -i data.csv -sstr "example.com" -scol 1 -mcol "3.2.4" -d ","

Examples:
    1. Search for "example.com" in column 1 and return the value from column 2:
        python script.py -i data.csv -sstr "example.com" -scol 1 -rcol 2

    2. Search for "example.com" in column 1 and return values from columns 3, 2, and 4,
       with output separated by semicolons:
        python script.py -i data.csv -sstr "example.com" -scol 1 -mcol "3;2;4"

    3. Search for "example.com" in column 1 and return values from columns 3, 2, and 4,
       with output separated by commas:
        python script.py -i data.csv -sstr "example.com" -scol 1 -mcol "3,2,4"

    4. Search for "example.com" in column 1 and return values from columns 3, 2, and 4,
       with output separated by periods:
        python script.py -i data.csv -sstr "example.com" -scol 1 -mcol "3.2.4" -d ","

    5. Search for "example.com" in column 1 and return the value from column 2 in a
       tab-delimited CSV file (the user provides "\t" as the delimiter):
        python script.py -i data_tab.csv -sstr "example.com" -scol 1 -rcol 2 -d "\t"

Author:
    (c) drgfragkos 2024
"""

def parse_arguments():
    parser = argparse.ArgumentParser(description="Dynamic CSV Query Tool")
    parser.add_argument('-i', '--input', required=True, help="Path to the input CSV file.")
    parser.add_argument('-sstr', '--search_string', help="Search string to lookup.")
    parser.add_argument('-scol', '--search_column', type=int, required=True, help="Column number to search (1-indexed).")
    parser.add_argument('-rcol', '--return_column', type=int, default=None, help="Single column number to return (1-indexed).")
    parser.add_argument('-mcol', '--multiple_columns', 
                        help="List of column numbers to return (e.g., '3;2;4' or '3,2,4'). "
                             "The delimiter used in the output is inferred from this argument.")
    parser.add_argument(
        '-d', '--delimiter',
        default=';',
        help=(
            "Delimiter used in the input CSV file (default is ';'). "
            "Use \"\\t\" for tab-delimited files, or any single-character delimiter like ',' or '|'."
        )
    )
    return parser.parse_args()

def read_csv(file_path, delimiter, retries=2, delay=0.3):
    attempt = 0
    while attempt <= retries:
        try:
            with open(file_path, mode='r', encoding='utf-8') as file:
                # Non-blocking file access
                fd = file.fileno()
                fcntl.flock(fd, fcntl.LOCK_SH | fcntl.LOCK_NB)  # Shared lock, non-blocking

                reader = csv.reader(file, delimiter=delimiter)
                headers = next(reader)
                data = list(reader)

                fcntl.flock(fd, fcntl.LOCK_UN)  # Unlock the file
                return headers, data

        except BlockingIOError:
            if attempt < retries:
                time.sleep(delay)  # Wait before retrying
                attempt += 1
            else:
                print("Error: The file is currently being used by another process. Please try again later.")
                sys.exit(1)

def load_data_into_memory(csv_data, search_column):
    csv_dict = {}
    for row in csv_data:
        # Safeguard if a row is shorter than the search_column
        if len(row) < search_column:
            continue
        key = row[search_column - 1]
        csv_dict[key] = row
    return csv_dict

def find_csv_info(csv_dict, search_string, return_column_index=None, multiple_columns=None, output_delimiter=";"):
    row = csv_dict.get(search_string)
    if row:
        if multiple_columns:
            # Handle multiple columns
            columns = [int(col) for col in multiple_columns.split(output_delimiter)]
            try:
                return output_delimiter.join(row[col - 1] for col in columns)
            except IndexError:
                return "null"  # If any column index is out of range, return "null"
        elif return_column_index:
            # Handle single column
            if return_column_index <= len(row):
                return row[return_column_index - 1]  # CSV columns are 1-indexed
            else:
                return "null"  # If the return column index is out of range, return "null"
    return "null"  # Return "null" if the search string is not found

def cleanup_and_exit(csv_dict):
    csv_dict.clear()  # Clear the in-memory data
    sys.exit(0)

def signal_handler(sig, frame):
    cleanup_and_exit(csv_dict)

def main():
    global csv_dict
    args = parse_arguments()

    # Map special case where user types -d "\t" (passed as a literal backslash + t) to the actual tab char.
    if args.delimiter == r'\t':
        input_delimiter = '\t'
    else:
        input_delimiter = args.delimiter

    if args.return_column and args.multiple_columns:
        print("Error: Please specify either -rcol or -mcol, but not both.")
        sys.exit(1)

    headers, csv_data = read_csv(args.input, input_delimiter)

    # Validate column arguments
    if not 1 <= args.search_column <= len(headers):
        print(f"Error: -scol value must be between 1 and {len(headers)}")
        sys.exit(1)

    if args.return_column and (args.return_column < 1 or args.return_column > len(headers)):
        print(f"Error: -rcol value must be between 1 and {len(headers)}")
        sys.exit(1)

    # Infer the output delimiter for multiple columns
    output_delimiter = ";"
    if args.multiple_columns:
        # Check the pattern in the string
        first_char = args.multiple_columns[1]
        # Validate that the user used a consistent separator like ";", ",", "." etc.
        if all(c == first_char for c in args.multiple_columns[1::2]):
            output_delimiter = first_char
        else:
            print("Error: Invalid delimiter in -mcol. Use a consistent delimiter.")
            sys.exit(1)

        # Make sure each column is within range
        columns = [int(col) for col in args.multiple_columns.split(output_delimiter)]
        for col in columns:
            if not 1 <= col <= len(headers):
                print(f"Error: Each column in -mcol must be between 1 and {len(headers)}")
                sys.exit(1)

    csv_dict = load_data_into_memory(csv_data, args.search_column)

    # Set up signal handler for graceful exit on Control+C
    signal.signal(signal.SIGINT, signal_handler)

    # Determine the actual search string
    if not sys.stdin.isatty():  # Data from a pipe
        input_data = sys.stdin.read().strip()
        search_string = input_data
    elif args.search_string:  # -sstr flag
        search_string = args.search_string
    else:
        print("Error: No search string provided.")
        sys.exit(1)

    result = find_csv_info(
        csv_dict, 
        search_string, 
        args.return_column, 
        args.multiple_columns, 
        output_delimiter
    )
    print(result)

    cleanup_and_exit(csv_dict)

if __name__ == "__main__":
    main()
