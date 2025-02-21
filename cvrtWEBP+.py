"""
This Python script converts .webp files into .jpg, .png, or .bmp format.

Key Features:
1. `-i` for converting a single .webp file.
2. `-f` for converting all .webp files in a folder.
3. `-o` to specify the output folder, defaulting to the working directory if not provided.
4. Pipe support for converting a single .webp file passed from a pipe.
5. `-t` for specifying the output format (supports jpg, png, bmp, or ALL for all formats).

Usage Examples:

1. Convert a single .webp file to .jpg:
   python cvrtWEBP+.py -i /path/to/file.webp -t jpg

2. Convert all .webp files in a folder to .png:
   python cvrtWEBP+.py -f /path/to/input_folder -t png -o /path/to/output_folder

3. Convert a .webp file passed through a pipe to .bmp:
   echo "/path/to/file.webp" | python cvrtWEBP+.py -t bmp

4. Convert all .webp files in a folder to all supported formats (.jpg, .png, .bmp):
   python cvrtWEBP+.py -f /path/to/input_folder -t ALL

Author:
   (c) 2024 @drgfragkos    
   
"""

import os
import sys
import argparse
from PIL import Image

SUPPORTED_FORMATS = ["jpg", "png", "bmp"]

def convert_webp_to_image(input_path, output_path, output_format):
    """
    Converts a single .webp image to the specified format and saves it to the output path.

    :param input_path: Path to the .webp file
    :param output_path: Output path for the converted image
    :param output_format: The format to convert to (jpg, png, bmp)
    """
    try:
        image = Image.open(input_path)
        image = image.convert("RGB")  # Convert to RGB for formats like JPG
        image.save(output_path, output_format.upper())
        print(f"Converted: {input_path} -> {output_path}")
    except Exception as e:
        print(f"Error converting {input_path}: {str(e)}")

def convert_file(input_file, output_folder, output_formats):
    """
    Converts a single .webp file to one or more specified formats.

    :param input_file: Path to the .webp file
    :param output_folder: Folder to save the converted files
    :param output_formats: List of format(s) to convert to
    """
    base_name = os.path.splitext(os.path.basename(input_file))[0]
    for fmt in output_formats:
        output_file_name = base_name + "." + fmt
        output_file_path = os.path.join(output_folder, output_file_name)
        convert_webp_to_image(input_file, output_file_path, fmt)

def convert_folder(input_folder, output_folder, output_formats):
    """
    Converts all .webp images in a folder to the specified format(s).

    :param input_folder: Folder containing .webp files
    :param output_folder: Folder to save converted files
    :param output_formats: List of formats to convert to (subset of SUPPORTED_FORMATS)
    """
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    for file_name in os.listdir(input_folder):
        if file_name.endswith(".webp"):
            input_file_path = os.path.join(input_folder, file_name)
            convert_file(input_file_path, output_folder, output_formats)

def main():
    parser = argparse.ArgumentParser(description="Convert .webp files to another format (jpg, png, bmp, or ALL).")
    
    # Options for input file, folder, output format, and output directory
    parser.add_argument("-i", "--input-file", help="Path to a single .webp file for conversion.")
    parser.add_argument("-f", "--input-folder", help="Path to a folder containing .webp files for batch conversion.")
    parser.add_argument("-o", "--output-folder", help="Output folder to save converted images. Defaults to the current working directory.", default=".")
    parser.add_argument("-t", "--type", help="Output format: jpg, png, bmp, or ALL.", required=True)

    # Parse the arguments
    args = parser.parse_args()

    arg_format = args.type.lower()
    if arg_format != "all" and arg_format not in SUPPORTED_FORMATS:
        print("Error: Output format must be 'jpg', 'png', 'bmp', or 'ALL'.")
        sys.exit(1)

    output_formats = SUPPORTED_FORMATS if arg_format == "all" else [arg_format]

    # If an input file is passed
    if args.input_file:
        if not args.input_file.endswith(".webp"):
            print("Error: The input file must be a .webp file.")
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
        if input_data.endswith(".webp") and os.path.isfile(input_data):
            convert_file(input_data, args.output_folder, output_formats)
        else:
            print("Error: Invalid file passed from pipe. Make sure it's a valid .webp file.")
            sys.exit(1)
    else:
        print("Error: No input provided. Use -i for a single file or -f for a folder.")
        sys.exit(1)

if __name__ == "__main__":
    main()
