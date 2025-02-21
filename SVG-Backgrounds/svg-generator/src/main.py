import argparse
from svg_generator import generate_svg
from presets import color_presets, list_presets

def main():
    parser = argparse.ArgumentParser(description="Generate an SVG file with a specified background color.")
    parser.add_argument('-R', type=int, help='Red component (0-255)')
    parser.add_argument('-G', type=int, help='Green component (0-255)')
    parser.add_argument('-B', type=int, help='Blue component (0-255)')
    parser.add_argument('-c', type=str, choices=color_presets.keys(), help='Color preset name')
    parser.add_argument('-l', action='store_true', help='List all available color presets')

    args = parser.parse_args()

    if args.l:
        presets = list_presets()
        print("Available color presets:")
        for preset in presets:
            print(f"{preset}: {color_presets[preset]}")
        return

    if args.c:
        rgb = color_presets[args.c]
    elif args.R is not None and args.G is not None and args.B is not None:
        rgb = (args.R, args.G, args.B)
    else:
        print("Please specify either RGB values or a color preset.")
        return

    svg_content = generate_svg(rgb)
    with open("output.svg", "w") as f:
        f.write(svg_content)
    print("SVG file generated: output.svg")

if __name__ == "__main__":
    main()