"""
This Python script converts .webm files into .mp4, .mov, or .mpeg format using ffmpeg.

Key Features:
1. `-i` for converting a single .webm file.
2. `-f` for converting all .webm files in a folder.
3. `-o` to specify the output folder, defaulting to the working directory if not provided.
4. Pipe support for converting a single .webm file passed from a pipe.
5. `-t` for specifying the output format (supports mp4, mov, mpeg, or ALL for all formats).

Before proceeding, the script checks that ffmpeg is installed. If ffmpeg is not found, it will provide instructions on how to install it depending on your operating system.

Usage Examples:

1. Convert a single .webm file to .mp4:
   python cvrtWEBM.py -i /path/to/file.webm -t mp4

2. Convert all .webm files in a folder to .mov:
   python cvrtWEBM.py -f /path/to/input_folder -t mov -o /path/to/output_folder

3. Convert a .webm file passed through a pipe to .mpeg:
   echo "/path/to/file.webm" | python cvrtWEBM.py -t mpeg

4. Convert all .webm files in a folder to all supported formats (.mp4, .mov, .mpeg):
   python cvrtWEBM.py -f /path/to/input_folder -t ALL

Author:
   (c) 2024 @drgfragkos    
   
"""

import os
import sys
import argparse
import subprocess
import shutil

SUPPORTED_FORMATS = ["mp4", "mov", "mpeg"]

def check_ffmpeg():
    """
    Checks if ffmpeg is installed on the system.
    Returns True if found, otherwise prints installation instructions and exits.
    """
    if shutil.which("ffmpeg") is None:
        print("Error: ffmpeg is not installed or not found in PATH.")
        if sys.platform.startswith("darwin"):
            print("Installation on macOS: brew install ffmpeg")
        elif sys.platform.startswith("linux"):
            print("Installation on Linux: sudo apt-get install ffmpeg  (or use your distro's package manager)")
        elif sys.platform.startswith("win"):
            print("Installation on Windows: Download from https://ffmpeg.org/download.html and add it to PATH.")
        else:
            print("Please install ffmpeg from https://ffmpeg.org/download.html and ensure it's in your system PATH.")
        sys.exit(1)
    return True

def convert_webm_to_video(input_path, output_path):
    """
    Converts a single .webm file to another video format using ffmpeg.
    
    :param input_path: Path to the .webm file.
    :param output_path: Output path for the converted video file.
    """
    command = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", input_path, output_path]
    try:
        subprocess.run(command, check=True)
        print(f"Converted: {input_path} -> {output_path}")
    except subprocess.CalledProcessError as e:
        print(f"Error converting {input_path}: {e}")

def convert_file(input_file, output_folder, output_formats):
    """
    Converts a single .webm file to one or more specified video formats.
    
    :param input_file: Path to the .webm file.
    :param output_folder: Folder to save the converted files.
    :param output_formats: List of format(s) to convert to.
    """
    base_name = os.path.splitext(os.path.basename(input_file))[0]
    for fmt in output_formats:
        output_file_name = base_name + "." + fmt
        output_file_path = os.path.join(output_folder, output_file_name)
        convert_webm_to_video(input_file, output_file_path)

def convert_folder(input_folder, output_folder, output_formats):
    """
    Converts all .webm files in a folder to the specified video format(s).
    
    :param input_folder: Folder containing .webm files.
    :param output_folder: Folder to save converted files.
    :param output_formats: List of formats to convert to (subset of SUPPORTED_FORMATS).
    """
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    for file_name in os.listdir(input_folder):
        if file_name.endswith(".webm"):
            input_file_path = os.path.join(input_folder, file_name)
            convert_file(input_file_path, output_folder, output_formats)

def main():
    check_ffmpeg()

    parser = argparse.ArgumentParser(description="Convert .webm files to another video format (mp4, mov, mpeg, or ALL).")
    
    # Options for input file, folder, output format, and output directory
    parser.add_argument("-i", "--input-file", help="Path to a single .webm file for conversion.")
    parser.add_argument("-f", "--input-folder", help="Path to a folder containing .webm files for batch conversion.")
    parser.add_argument("-o", "--output-folder", help="Output folder to save converted videos. Defaults to the current working directory.", default=".")
    parser.add_argument("-t", "--type", help="Output format: mp4, mov, mpeg, or ALL.", required=True)

    # Parse the arguments
    args = parser.parse_args()

    arg_format = args.type.lower()
    if arg_format != "all" and arg_format not in SUPPORTED_FORMATS:
        print("Error: Output format must be 'mp4', 'mov', 'mpeg', or 'ALL'.")
        sys.exit(1)

    output_formats = SUPPORTED_FORMATS if arg_format == "all" else [arg_format]

    # If an input file is passed
    if args.input_file:
        if not args.input_file.endswith(".webm"):
            print("Error: The input file must be a .webm file.")
            sys.exit(1)
        convert_file(args.input_file, args.output_folder, output_formats)

    # If an input folder is passed
    elif args.input_folder:
        if not os.path.isdir(args.input_folder):
            print("Error: The input folder does not exist.")
            sys.exit(1)
        convert_folder(args.input_folder, args.output_folder, output_formats)

    # If no input file or folder but input from pipe
    elif not sys.stdin.isatty():
        # Read from pipe
        input_data = sys.stdin.read().strip()
        if input_data.endswith(".webm") and os.path.isfile(input_data):
            convert_file(input_data, args.output_folder, output_formats)
        else:
            print("Error: Invalid file passed from pipe. Make sure it's a valid .webm file.")
            sys.exit(1)
    else:
        print("Error: No input provided. Use -i for a single file or -f for a folder.")
        sys.exit(1)

if __name__ == "__main__":
    main()