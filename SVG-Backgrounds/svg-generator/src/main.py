import argparse
import sys

from svg_generator import generate_svg
from presets import color_presets, list_presets


def rgb_component(value):
    """argparse type: integer constrained to 0-255."""
    ivalue = int(value)
    if not 0 <= ivalue <= 255:
        raise argparse.ArgumentTypeError(f"{ivalue} is out of range (0-255)")
    return ivalue


def main():
    parser = argparse.ArgumentParser(
        description="Generate an SVG file with a specified background color."
    )
    parser.add_argument('-R', type=rgb_component, help='Red component (0-255)')
    parser.add_argument('-G', type=rgb_component, help='Green component (0-255)')
    parser.add_argument('-B', type=rgb_component, help='Blue component (0-255)')
    parser.add_argument('-c', type=str, choices=color_presets.keys(),
                        metavar='PRESET', help='Color preset name (see -l)')
    parser.add_argument('-l', action='store_true',
                        help='List all available color presets')
    parser.add_argument('-o', type=str, default='output.svg',
                        help='Output filename (default: output.svg)')

    args = parser.parse_args()

    if args.l:
        print("Available color presets:")
        for preset in list_presets():
            print(f"{preset}: {color_presets[preset]}")
        return 0

    rgb_flags = (args.R, args.G, args.B)

    if args.c and any(v is not None for v in rgb_flags):
        print("Error: use either a preset (-c) or RGB values (-R -G -B), not both.",
              file=sys.stderr)
        return 1

    if args.c:
        rgb = color_presets[args.c]
    elif all(v is not None for v in rgb_flags):
        rgb = rgb_flags
    elif any(v is not None for v in rgb_flags):
        print("Error: all three of -R, -G and -B must be provided together.",
              file=sys.stderr)
        return 1
    else:
        parser.print_usage(sys.stderr)
        print("Error: specify either RGB values (-R -G -B) or a color preset (-c).",
              file=sys.stderr)
        return 1

    try:
        svg_content = generate_svg(*rgb)  # unpack the tuple into r, g, b
    except ValueError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1

    try:
        with open(args.o, "w", encoding="utf-8") as f:
            f.write(svg_content)
    except OSError as exc:
        print(f"Error writing file: {exc}", file=sys.stderr)
        return 1

    print(f"SVG file generated: {args.o}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
