#!/usr/bin/env python3
"""
*****************************************************************************
Description:
   This Python script extracts all unique email addresses from a given text file.
   It uses multiple regex patterns (a standard pattern and one for quoted local parts)
   to increase coverage. The emails are normalized to lowercase and the unique
   results are written to an output file.

Usage:
   python3 emails++.py [-v] <InputFile>

Examples:
   python3 emails++.py sample.txt
   python3 emails++.py -v sample.txt

Note:
   The default behavior is silent execution. When the -v flag is specified,
   verbose output is displayed.

Author:
   (c) @drgfragkos 2024
*****************************************************************************
"""

import argparse
import os
import re
from datetime import date
import sys

def extract_emails(file_path, regex_patterns, verbose):
    """Extract unique emails from file using a list of compiled regex patterns.
    
    Reads the file line by line and applies every pattern on each line
    to avoid re-opening the file for each pattern.
    """
    emails = set()

    # Compile each regex
    compiled_patterns = []
    for pattern in regex_patterns:
        if verbose:
            print(f"Compiling regex pattern: {pattern}")
        try:
            compiled_patterns.append(re.compile(pattern, re.IGNORECASE))
        except re.error as e:
            print(f"Error compiling regex pattern {pattern}: {e}", file=sys.stderr)
            continue

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            for line in f:
                for regex in compiled_patterns:
                    matches = regex.findall(line)
                    for match in matches:
                        emails.add(match.lower())
    except Exception as e:
        print(f"Error reading file {file_path}: {e}", file=sys.stderr)
        sys.exit(1)

    return emails

def main():
    parser = argparse.ArgumentParser(
        description="Extract unique email addresses from a text file using multiple regex patterns."
    )
    parser.add_argument("input_file", help="Path to the input file")
    parser.add_argument("-v", "--verbose", action="store_true", help="Enable verbose output")
    args = parser.parse_args()

    if not os.path.isfile(args.input_file):
        print(f"Error: File not found: '{args.input_file}'", file=sys.stderr)
        sys.exit(1)

    # Define regex patterns to capture emails:
    regex_patterns = [
        r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}",  # Standard email pattern
        r'"[^"]+"@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'             # Email addresses with quoted local parts
    ]

    if args.verbose:
        print("Starting email extraction...")

    emails = extract_emails(args.input_file, regex_patterns, args.verbose)

    if emails:
        # Create output filename as YYYY-MM-DD_<input_filename>
        date_stamp = date.today().strftime("%Y-%m-%d")
        basename = os.path.basename(args.input_file)
        output_filename = f"{date_stamp}_{basename}"
        
        try:
            # Write output in append mode (creates new file if it doesn't exist)
            with open(output_filename, 'a', encoding='utf-8') as out_file:
                for email in sorted(emails):
                    out_file.write(email + "\n")
            if args.verbose:
                print("Unique email addresses found:", len(emails))
                print("Results written to:", output_filename)
        except Exception as e:
            print(f"Error writing output to {output_filename}: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        if args.verbose:
            print("-- None Found --")

if __name__ == "__main__":
    main()