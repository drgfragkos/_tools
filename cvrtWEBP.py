"""
This Python script converts .webp files into .jpg, .png, or .bmp format.

Key Features:
1. `-i` for converting a single .webp file.
2. `-f` for converting all .webp files in a folder.
3. `-o` to specify the output folder, defaulting to the working directory if not provided.
4. Pipe support for converting a single .webp file passed from a pipe.
5. `-t` for specifying the output format (supports jpg, png, and bmp).

Usage Examples:

1. Convert a single .webp file to .jpg:
   python convert_webp.py -i /path/to/file.webp -t jpg

2. Convert all .webp files in a folder to .png:
   python convert_webp.py -f /path/to/input_folder -t png -o /path/to/output_folder

3. Convert a .webp file passed through a pipe to .bmp:
   echo "/path/to/file.webp" | python convert_webp.py -t bmp

4. Convert all .webp files in a folder to .jpg and save in the current working directory:
   python convert_webp.py -f /path/to/input_folder -t jpg
   
Author:
   (c) 2024 @drgfragkos    
   
"""

import os
import sys
import argparse
from PIL import Image

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

def convert_folder(input_folder, output_folder, output_format):
    """
    Converts all .webp images in a folder to the specified format.

    :param input_folder: Folder containing .webp files
    :param output_folder: Folder to save converted files
    :param output_format: The format to convert to (jpg, png, bmp)
    """
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    for file_name in os.listdir(input_folder):
        if file_name.endswith(".webp"):
            input_file_path = os.path.join(input_folder, file_name)
            output_file_name = os.path.splitext(file_name)[0] + "." + output_format
            output_file_path = os.path.join(output_folder, output_file_name)
            convert_webp_to_image(input_file_path, output_file_path, output_format)

def main():
    parser = argparse.ArgumentParser(description="Convert .webp files to another format (jpg, png, bmp).")
    
    # Options for input file, folder, output format, and output directory
    parser.add_argument("-i", "--input-file", help="Path to a single .webp file for conversion.")
    parser.add_argument("-f", "--input-folder", help="Path to a folder containing .webp files for batch conversion.")
    parser.add_argument("-o", "--output-folder", help="Output folder to save converted images. Defaults to the current working directory.", default=".")
    parser.add_argument("-t", "--type", help="Output format: jpg, png, bmp.", required=True)

    # Parse the arguments
    args = parser.parse_args()

    if args.type.lower() not in ["jpg", "png", "bmp"]:
        print("Error: Output format must be 'jpg', 'png', or 'bmp'.")
        sys.exit(1)

    # If an input file is passed
    if args.input_file:
        if not args.input_file.endswith(".webp"):
            print("Error: The input file must be a .webp file.")
            sys.exit(1)

        output_file_name = os.path.splitext(os.path.basename(args.input_file))[0] + "." + args.type
        output_file_path = os.path.join(args.output_folder, output_file_name)
        convert_webp_to_image(args.input_file, output_file_path, args.type)

    # If an input folder is passed
    elif args.input_folder:
        if not os.path.isdir(args.input_folder):
            print("Error: The input folder does not exist.")
            sys.exit(1)

        convert_folder(args.input_folder, args.output_folder, args.type)

    # If no input file or folder but input from pipe
    elif not sys.stdin.isatty():
        # Read from pipe
        input_data = sys.stdin.read().strip()
        if input_data.endswith(".webp") and os.path.isfile(input_data):
            output_file_name = os.path.splitext(os.path.basename(input_data))[0] + "." + args.type
            output_file_path = os.path.join(args.output_folder, output_file_name)
            convert_webp_to_image(input_data, output_file_path, args.type)
        else:
            print("Error: Invalid file passed from pipe. Make sure it's a valid .webp file.")
            sys.exit(1)
    else:
        print("Error: No input provided. Use -i for a single file or -f for a folder.")
        sys.exit(1)

if __name__ == "__main__":
    main()
